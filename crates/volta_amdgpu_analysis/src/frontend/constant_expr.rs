//! Bounded absolute integer expressions emitted by LLVM's AMDGPU resource pass.
//!
//! `max` is signed and `or` is bitwise, both variadic with at least one argument:
//! llvm/llvm-project@5fd50ec8e07abb94e203933017e8d6e40fb51824,
//! AMDGPUMCExpr.cpp:50–58,119–128,278–288. Arithmetic is checked; relocation,
//! reassignable symbols and other assembler functions are outside this profile.
use std::collections::{BTreeMap, BTreeSet};

const MAX_DEPTH: usize = 128;
const MAX_EXPRESSION_BYTES: usize = 16 * 1024;

#[derive(Clone, Debug)]
pub(super) enum Expr {
    Value(i64),
    Symbol(String),
    Neg(Box<Expr>),
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Max(Vec<Expr>),
    Or(Vec<Expr>),
}

struct Parser<'a> {
    text: &'a str,
    position: usize,
    terms: usize,
}

impl Parser<'_> {
    fn whitespace(&mut self) {
        while self
            .text
            .as_bytes()
            .get(self.position)
            .is_some_and(u8::is_ascii_whitespace)
        {
            self.position += 1;
        }
    }

    fn take(&mut self, byte: u8) -> bool {
        self.whitespace();
        if self.text.as_bytes().get(self.position) == Some(&byte) {
            self.position += 1;
            true
        } else {
            false
        }
    }

    fn expression(&mut self, depth: usize) -> Result<Expr, String> {
        let mut result = self.primary(depth + 1)?;
        loop {
            if self.take(b'+') {
                result = Expr::Add(Box::new(result), Box::new(self.primary(depth + 1)?));
            } else if self.take(b'-') {
                result = Expr::Sub(Box::new(result), Box::new(self.primary(depth + 1)?));
            } else {
                return Ok(result);
            }
        }
    }

    fn primary(&mut self, depth: usize) -> Result<Expr, String> {
        self.terms += 1;
        if depth > MAX_DEPTH || self.terms > 256 {
            return Err("assembly constant expression nesting exceeds supported bound".into());
        }
        self.whitespace();
        let negative = self.take(b'-');
        let positive = !negative && self.take(b'+');
        self.whitespace();
        let start = self.position;
        if self
            .text
            .as_bytes()
            .get(start)
            .is_some_and(u8::is_ascii_digit)
        {
            while self
                .text
                .as_bytes()
                .get(self.position)
                .is_some_and(u8::is_ascii_alphanumeric)
            {
                self.position += 1;
            }
            let token = &self.text[start..self.position];
            let signed = if negative {
                format!("-{token}")
            } else {
                token.to_owned()
            };
            return super::instr::integer(&signed)
                .map(Expr::Value)
                .ok_or_else(|| "invalid or out-of-range assembly integer".into());
        }
        if negative || positive {
            let value = self.primary(depth + 1)?;
            return Ok(if negative {
                Expr::Neg(Box::new(value))
            } else {
                value
            });
        }
        if self.take(b'(') {
            let result = self.expression(depth + 1)?;
            if !self.take(b')') {
                return Err("unclosed assembly constant expression".into());
            }
            return Ok(result);
        }
        while self
            .text
            .as_bytes()
            .get(self.position)
            .is_some_and(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'.' | b'$'))
        {
            self.position += 1;
        }
        let name = &self.text[start..self.position];
        if name.is_empty() || name == "." {
            return Err("expected absolute assembly constant term".into());
        }
        if self.take(b'(') {
            if !matches!(name, "max" | "or") {
                return Err(format!("unsupported assembly constant function `{name}`"));
            }
            let mut args = vec![self.expression(depth + 1)?];
            while self.take(b',') {
                args.push(self.expression(depth + 1)?);
            }
            if !self.take(b')') {
                return Err("malformed assembly constant function arguments".into());
            }
            Ok(if name == "max" {
                Expr::Max(args)
            } else {
                Expr::Or(args)
            })
        } else {
            Ok(Expr::Symbol(name.into()))
        }
    }
}

pub(super) fn parse(text: &str) -> Result<Expr, String> {
    if text.len() > MAX_EXPRESSION_BYTES {
        return Err("assembly constant expression exceeds supported size".into());
    }
    let mut parser = Parser {
        text,
        position: 0,
        terms: 0,
    };
    let result = parser.expression(0)?;
    parser.whitespace();
    if parser.position != text.len() {
        return Err("unsupported trailing assembly constant expression syntax".into());
    }
    Ok(result)
}

impl Expr {
    fn evaluate(
        &self,
        depth: usize,
        lookup: &mut impl FnMut(&str, usize) -> Result<i64, String>,
    ) -> Result<i64, String> {
        if depth > MAX_DEPTH {
            return Err(
                "assembly constant dependency/expression depth exceeds supported bound".into(),
            );
        }
        let overflow = || "assembly constant arithmetic overflow".to_owned();
        match self {
            Self::Value(value) => Ok(*value),
            Self::Symbol(name) => lookup(name, depth + 1),
            Self::Neg(value) => value
                .evaluate(depth + 1, lookup)?
                .checked_neg()
                .ok_or_else(overflow),
            Self::Add(left, right) => left
                .evaluate(depth + 1, lookup)?
                .checked_add(right.evaluate(depth + 1, lookup)?)
                .ok_or_else(overflow),
            Self::Sub(left, right) => left
                .evaluate(depth + 1, lookup)?
                .checked_sub(right.evaluate(depth + 1, lookup)?)
                .ok_or_else(overflow),
            Self::Max(args) | Self::Or(args) => {
                let mut values = args.iter();
                let mut result = values
                    .next()
                    .ok_or("empty assembly constant function")?
                    .evaluate(depth + 1, lookup)?;
                for argument in values {
                    let value = argument.evaluate(depth + 1, lookup)?;
                    result = if matches!(self, Self::Max(_)) {
                        result.max(value)
                    } else {
                        result | value
                    };
                }
                Ok(result)
            }
        }
    }

    pub(super) fn known_value(&self, values: &BTreeMap<String, i64>) -> Result<i64, String> {
        self.evaluate(0, &mut |name, _| {
            values
                .get(name)
                .copied()
                .ok_or_else(|| format!("unresolved assembly constant `{name}`"))
        })
    }
}

fn resolve(
    name: &str,
    depth: usize,
    definitions: &BTreeMap<String, Expr>,
    values: &mut BTreeMap<String, i64>,
    visiting: &mut BTreeSet<String>,
) -> Result<i64, String> {
    if depth > MAX_DEPTH {
        return Err("assembly constant dependency depth exceeds supported bound".into());
    }
    if let Some(value) = values.get(name) {
        return Ok(*value);
    }
    let expression = definitions
        .get(name)
        .ok_or_else(|| format!("unresolved assembly constant `{name}`"))?;
    if !visiting.insert(name.into()) {
        return Err(format!("cyclic assembly constant `{name}`"));
    }
    let result = expression.evaluate(depth, &mut |dependency, next_depth| {
        resolve(dependency, next_depth, definitions, values, visiting)
    })?;
    visiting.remove(name);
    values.insert(name.into(), result);
    Ok(result)
}

pub(super) fn resolve_all(
    definitions: &BTreeMap<String, Expr>,
) -> Result<BTreeMap<String, i64>, (String, String)> {
    let mut values = BTreeMap::new();
    let mut visiting = BTreeSet::new();
    for name in definitions.keys() {
        resolve(name, 0, definitions, &mut values, &mut visiting)
            .map_err(|message| (name.clone(), message))?;
    }
    Ok(values)
}
