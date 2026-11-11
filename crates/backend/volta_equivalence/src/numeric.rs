//! f64 evaluation of expression DAGs at seeded pseudo-random symbol values in [-1, 1): the
//! decision procedure's oracle (Schwartz-Zippel: agreement implies equality almost surely).
//! A differing seed refutes EQUIV / confirms DIFF; all-agree leaves DIFF unconfirmed.
//! Finite arithmetic disagreements are independently replayed over exact rationals
//! before they can refute equality through binary64 cancellation alone.

use std::collections::HashMap;

use volta_expr::{ExprArena, ExprId, ExprNode, RealRepr, SymbolRef};

/// Numeric evaluation failure.
#[derive(Debug, Clone, PartialEq)]
pub enum NumericError {
    /// An `Undefined`/`Discarded` value was reached.
    Undefined,
}

impl std::fmt::Display for NumericError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Undefined => write!(f, "numeric evaluation reached an undefined value"),
        }
    }
}

impl std::error::Error for NumericError {}

/// Deterministic value in [-1, 1) for a symbol under a seed: FNV-1a over the [`SymbolRef`]
/// identity and seed, domain-separated per namespace, with a fixed-width element index
/// prefix (so `("x", 12)` cannot alias `("x1", 2)`).
fn symbol_value(sym: SymbolRef<'_>, seed: u64) -> f64 {
    let mut h: u64 = 0xcbf29ce484222325 ^ seed.wrapping_mul(0x9e3779b97f4a7c15);
    let mut feed = |b: u8| {
        h ^= b as u64;
        h = h.wrapping_mul(0x100000001b3);
    };
    match sym {
        SymbolRef::Param(name) => {
            feed(b'p');
            name.bytes().for_each(feed);
        }
        SymbolRef::Element { array, index } => {
            feed(b'e');
            index.to_le_bytes().into_iter().for_each(&mut feed);
            array.bytes().for_each(&mut feed);
        }
        SymbolRef::Machine(id) => {
            feed(b'm');
            id.0.to_le_bytes().into_iter().for_each(feed);
        }
    }
    // splitmix-style finalize for good low-bit behavior
    h ^= h >> 30;
    h = h.wrapping_mul(0xbf58476d1ce4e5b9);
    h ^= h >> 27;
    (h >> 11) as f64 / (1u64 << 53) as f64 * 2.0 - 1.0
}

/// Evaluate `id` under the symbol assignment defined by `seed`.
pub fn eval_f64(arena: &ExprArena, id: ExprId, seed: u64) -> Result<f64, NumericError> {
    let mut memo: HashMap<ExprId, f64> = HashMap::new();
    eval_memo(arena, id, seed, &mut memo)
}

fn eval_memo(
    arena: &ExprArena,
    id: ExprId,
    seed: u64,
    memo: &mut HashMap<ExprId, f64>,
) -> Result<f64, NumericError> {
    if let Some(&v) = memo.get(&id) {
        return Ok(v);
    }
    let v = stacker::maybe_grow(64 * 1024, 8 * 1024 * 1024, || {
        eval_inner(arena, id, seed, memo)
    })?;
    memo.insert(id, v);
    Ok(v)
}

fn eval_inner(
    arena: &ExprArena,
    id: ExprId,
    seed: u64,
    memo: &mut HashMap<ExprId, f64>,
) -> Result<f64, NumericError> {
    let ev = |e: ExprId, memo: &mut HashMap<ExprId, f64>| eval_memo(arena, e, seed, memo);
    let v = match arena.node(id) {
        ExprNode::IntConst(v) => *v as f64,
        // Rounding conversion: the oracle is approximate by nature.
        ExprNode::RealConst(v) => v.to_f64(),
        ExprNode::BoolConst(b) => *b as i64 as f64,
        ExprNode::ParamSymbol(_) | ExprNode::InputElement { .. } | ExprNode::Symbol(_) => {
            let sym = arena
                .node(id)
                .symbol_ref(arena)
                .expect("symbolic atom must have a symbol_ref");
            symbol_value(sym, seed)
        }

        ExprNode::Add(a, b) => ev(*a, memo)? + ev(*b, memo)?,
        ExprNode::Sub(a, b) => ev(*a, memo)? - ev(*b, memo)?,
        ExprNode::Mul(a, b) => ev(*a, memo)? * ev(*b, memo)?,
        ExprNode::Div(a, b) => ev(*a, memo)? / ev(*b, memo)?,
        ExprNode::Rem(a, b) => {
            let (x, y) = (ev(*a, memo)?, ev(*b, memo)?);
            (x as i64).wrapping_rem((y as i64).max(1)) as f64
        }
        ExprNode::Neg(a) => -ev(*a, memo)?,
        ExprNode::Fma(a, b, c) => ev(*a, memo)? * ev(*b, memo)? + ev(*c, memo)?,

        ExprNode::Exp(a) => ev(*a, memo)?.exp(),
        ExprNode::Log(a) => ev(*a, memo)?.ln(),
        ExprNode::Sqrt(a) => ev(*a, memo)?.sqrt(),
        ExprNode::Rcp(a) => 1.0 / ev(*a, memo)?,

        ExprNode::Max(a, b) => ev(*a, memo)?.max(ev(*b, memo)?),
        ExprNode::Min(a, b) => ev(*a, memo)?.min(ev(*b, memo)?),
        ExprNode::Abs(a) => ev(*a, memo)?.abs(),
        ExprNode::Sign(a) => {
            let v = ev(*a, memo)?;
            if v == 0.0 { 0.0 } else { v.signum() }
        }

        ExprNode::BitAnd(a, b) => ((ev(*a, memo)? as i64) & (ev(*b, memo)? as i64)) as f64,
        ExprNode::BitOr(a, b) => ((ev(*a, memo)? as i64) | (ev(*b, memo)? as i64)) as f64,
        ExprNode::BitXor(a, b) => ((ev(*a, memo)? as i64) ^ (ev(*b, memo)? as i64)) as f64,
        ExprNode::BitNot(a) => !(ev(*a, memo)? as i64) as f64,
        ExprNode::Shl(a, b) => ((ev(*a, memo)? as i64).wrapping_shl(ev(*b, memo)? as u32)) as f64,
        ExprNode::Shr(a, b) => ((ev(*a, memo)? as i64).wrapping_shr(ev(*b, memo)? as u32)) as f64,
        ExprNode::LShr(a, b) => ((ev(*a, memo)? as u64).wrapping_shr(ev(*b, memo)? as u32)) as f64,

        ExprNode::Eq(a, b) => (ev(*a, memo)? == ev(*b, memo)?) as i64 as f64,
        ExprNode::Ne(a, b) => (ev(*a, memo)? != ev(*b, memo)?) as i64 as f64,
        ExprNode::Lt(a, b) => (ev(*a, memo)? < ev(*b, memo)?) as i64 as f64,
        ExprNode::Le(a, b) => (ev(*a, memo)? <= ev(*b, memo)?) as i64 as f64,
        ExprNode::Gt(a, b) => (ev(*a, memo)? > ev(*b, memo)?) as i64 as f64,
        ExprNode::Ge(a, b) => (ev(*a, memo)? >= ev(*b, memo)?) as i64 as f64,
        ExprNode::And(a, b) => ((ev(*a, memo)? != 0.0) && (ev(*b, memo)? != 0.0)) as i64 as f64,
        ExprNode::Or(a, b) => ((ev(*a, memo)? != 0.0) || (ev(*b, memo)? != 0.0)) as i64 as f64,
        ExprNode::Not(a) => (ev(*a, memo)? == 0.0) as i64 as f64,

        ExprNode::Select(c, t, f) => {
            if ev(*c, memo)? != 0.0 {
                ev(*t, memo)?
            } else {
                ev(*f, memo)?
            }
        }

        ExprNode::ToFloat(a) => ev(*a, memo)?,

        ExprNode::SymbolicRead { array, index } => {
            // Same identity as the materialized `InputElement`: negative indices wrap
            // into u64 like `symbolic_read`'s eager resolution (no in-bounds collision).
            let i = ev(*index, memo)?;
            symbol_value(
                SymbolRef::Element {
                    array: arena.string(*array),
                    index: i as i64 as u64,
                },
                seed,
            )
        }

        ExprNode::Discarded | ExprNode::Undefined => return Err(NumericError::Undefined),
    };
    Ok(v)
}

/// Default seeds for spot checks.
pub const DEFAULT_SEEDS: [u64; 4] = [1, 42, 0xdeadbeef, 0x5eed];

/// Independently replay the arithmetic subset at the exact same seeded values.
/// This evaluates the original DAG; it does not consult the canonicalizer or
/// change the oracle's tolerance. Unsupported and non-finite operations stay
/// inconclusive rather than being approximated or treated as equal.
fn eval_rational(
    arena: &ExprArena,
    id: ExprId,
    seed: u64,
    memo: &mut HashMap<ExprId, Option<rug::Rational>>,
) -> Option<rug::Rational> {
    if let Some(value) = memo.get(&id) {
        return value.clone();
    }
    // Fail closed on oversized arithmetic instead of turning a numeric probe
    // into an unbounded big-integer computation. Inserting before descent also
    // bounds long dependency chains, not just the number of completed nodes.
    if memo.len() >= 100_000 {
        return None;
    }
    memo.insert(id, None);
    let value = stacker::maybe_grow(64 * 1024, 8 * 1024 * 1024, || {
        let ev = |id, memo: &mut HashMap<_, _>| eval_rational(arena, id, seed, memo);
        Some(match arena.node(id) {
            ExprNode::IntConst(value) => rug::Rational::from(*value),
            ExprNode::RealConst(value) => match value.repr() {
                RealRepr::Rational(value)
                    if value.numer().significant_bits() <= 16_384
                        && value.denom().significant_bits() <= 16_384 =>
                {
                    value.clone()
                }
                _ => return None,
            },
            ExprNode::ParamSymbol(_) | ExprNode::InputElement { .. } | ExprNode::Symbol(_) => {
                let symbol = arena.node(id).symbol_ref(arena)?;
                rug::Rational::from_f64(symbol_value(symbol, seed))?
            }
            ExprNode::Add(a, b) => ev(*a, memo)? + ev(*b, memo)?,
            ExprNode::Sub(a, b) => ev(*a, memo)? - ev(*b, memo)?,
            ExprNode::Mul(a, b) => ev(*a, memo)? * ev(*b, memo)?,
            ExprNode::Div(a, b) => {
                let denominator = ev(*b, memo)?;
                if denominator == 0 {
                    return None;
                }
                ev(*a, memo)? / denominator
            }
            ExprNode::Rcp(a) => {
                let denominator = ev(*a, memo)?;
                if denominator == 0 {
                    return None;
                }
                denominator.recip()
            }
            ExprNode::Neg(a) => -ev(*a, memo)?,
            ExprNode::Fma(a, b, c) => ev(*a, memo)? * ev(*b, memo)? + ev(*c, memo)?,
            ExprNode::ToFloat(a) => ev(*a, memo)?,
            _ => return None,
        })
    });
    let value = value.filter(|value| {
        value.numer().significant_bits() <= 16_384 && value.denom().significant_bits() <= 16_384
    });
    memo.insert(id, value.clone());
    value
}

/// Relative-error agreement at one seed, with exact arithmetic replay on finite disagreements.
pub fn agree_at(
    arena_a: &ExprArena,
    a: ExprId,
    arena_b: &ExprArena,
    b: ExprId,
    seed: u64,
    rel_tol: f64,
) -> Result<bool, NumericError> {
    let va = eval_f64(arena_a, a, seed)?;
    let vb = eval_f64(arena_b, b, seed)?;
    let scale = va.abs().max(vb.abs()).max(1e-30);
    if ((va - vb) / scale).abs() <= rel_tol {
        return Ok(true);
    }
    // Reassociated long sums can cancel to a tiny result: a relative-only
    // binary64 comparison can then refute a true real-arithmetic equality.
    // A fallback accepts only exact equality at the same assignment. It never
    // widens the numeric threshold or replaces a non-finite/domain failure.
    if va.is_finite() && vb.is_finite() && rel_tol >= 0.0 {
        let a = eval_rational(arena_a, a, seed, &mut HashMap::new());
        let b = eval_rational(arena_b, b, seed, &mut HashMap::new());
        if let (Some(a), Some(b)) = (a, b) {
            return Ok(a == b);
        }
    }
    Ok(false)
}

/// Check a claimed verdict against the oracle at several seeds: EQUIV is Ok iff the sides
/// agree at *every* seed; DIFF is Ok iff they differ at *some* seed, else unconfirmed (canon
/// is incomplete over uninterpreted atoms, so it may be a false DIFF).
pub fn verify_verdict(
    arena_a: &ExprArena,
    a: ExprId,
    arena_b: &ExprArena,
    b: ExprId,
    claimed_equal: bool,
) -> Result<(), String> {
    const REL_TOL: f64 = 1e-9;
    for &seed in &DEFAULT_SEEDS {
        let agree = agree_at(arena_a, a, arena_b, b, seed, REL_TOL)
            .map_err(|e| format!("numeric oracle failed: {}", e))?;
        match (claimed_equal, agree) {
            (true, false) => {
                return Err(format!(
                    "claimed EQUIV but values differ at seed {:#x}",
                    seed
                ));
            }
            (false, true) => continue, // keep looking for a separating seed
            _ => {
                if !claimed_equal {
                    return Ok(()); // separating seed found: DIFF confirmed
                }
            }
        }
    }
    if claimed_equal {
        Ok(())
    } else {
        Err(
            "claimed DIFF but values agree at every probe seed (possibly a false negative \
             from uninterpreted operations)"
                .to_string(),
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deterministic_and_seed_sensitive() {
        let mut ar = ExprArena::new();
        let a = ar.param_symbol("a");
        let v1 = eval_f64(&ar, a, 1).unwrap();
        let v2 = eval_f64(&ar, a, 1).unwrap();
        let v3 = eval_f64(&ar, a, 2).unwrap();
        assert_eq!(v1, v2);
        assert_ne!(v1, v3);
        assert!((-1.0..1.0).contains(&v1));
    }

    /// Regression: machine `Symbol(N)` and a symbol *named* `"s{N}"` must get distinct
    /// values, else the oracle is blind to canon conflating them.
    #[test]
    fn named_and_machine_symbols_get_independent_values() {
        use volta_expr::ExprNode;

        let mut ar = ExprArena::new();
        let machine = ar.symbol();
        let ExprNode::Symbol(sym) = *ar.node(machine) else {
            panic!("arena.symbol() must produce ExprNode::Symbol");
        };
        let named = ar.param_symbol(sym.to_string());
        for seed in 0..4 {
            assert_ne!(
                eval_f64(&ar, machine, seed).unwrap(),
                eval_f64(&ar, named, seed).unwrap(),
                "seed {}: Symbol({}) and NamedSymbol(\"{}\") must differ",
                seed,
                sym.0,
                sym
            );
        }
    }

    #[test]
    fn test_same_name_same_value_across_arenas() {
        let mut ar1 = ExprArena::new();
        let mut ar2 = ExprArena::new();
        let a1 = ar1.param_symbol("x[3]");
        let a2 = ar2.param_symbol("x[3]");
        assert_eq!(
            eval_f64(&ar1, a1, 7).unwrap(),
            eval_f64(&ar2, a2, 7).unwrap()
        );
    }

    #[test]
    fn test_verify_verdicts() {
        let mut ar = ExprArena::new();
        let (a, b) = (ar.param_symbol("a"), ar.param_symbol("b"));
        let ab = ar.add(a, b);
        let ba = ar.add(b, a);
        verify_verdict(&ar, ab, &ar, ba, true).unwrap();
        verify_verdict(&ar, a, &ar, b, false).unwrap();
        assert!(verify_verdict(&ar, a, &ar, b, true).is_err());
        assert!(verify_verdict(&ar, ab, &ar, ba, false).is_err());
    }

    #[test]
    fn test_softmax_agreement() {
        // The softmax normalization identity agrees numerically.
        let mut ar = ExprArena::new();
        let (a, b) = (ar.param_symbol("a"), ar.param_symbol("b"));
        let m = ar.max(a, b);
        let ea = ar.exp(a);
        let eb = ar.exp(b);
        let d1 = ar.add(ea, eb);
        let e1 = ar.div(ea, d1);
        let am = ar.sub(a, m);
        let bm = ar.sub(b, m);
        let eam = ar.exp(am);
        let ebm = ar.exp(bm);
        let d2 = ar.add(eam, ebm);
        let e2 = ar.div(eam, d2);
        verify_verdict(&ar, e1, &ar, e2, true).unwrap();
    }

    #[test]
    fn cancellation_replays_seeded_arithmetic_exactly_without_relaxing_tolerance() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        let large = arena.int(1 << 60);
        let sum = arena.add(x, large);
        let cancelled = arena.sub(sum, large);
        for seed in DEFAULT_SEEDS {
            assert_ne!(
                eval_f64(&arena, cancelled, seed).unwrap(),
                eval_f64(&arena, x, seed).unwrap()
            );
            assert!(agree_at(&arena, cancelled, &arena, x, seed, 0.0).unwrap());
        }
        verify_verdict(&arena, cancelled, &arena, x, true).unwrap();
        // A real one-unit error remains a counterexample after the same lossy
        // binary64 computation: exact replay cannot borrow canon's verdict.
        let one = arena.int(1);
        let wrong = arena.add(x, one);
        assert!(verify_verdict(&arena, cancelled, &arena, wrong, true).is_err());
        verify_verdict(&arena, cancelled, &arena, wrong, false).unwrap();
    }

    #[test]
    fn exact_fallback_handles_rational_operations_but_refuses_zero_divisors() {
        let mut arena = ExprArena::new();
        let input = arena.intern_string("input");
        let x = arena.input_element(input, 77);
        let large = arena.int(1 << 60);
        let sum = arena.add(x, large);
        let cancelled = arena.sub(sum, large);
        let three = arena.int(3);
        let a = arena.div(cancelled, three);
        let reciprocal = arena.rcp(three);
        let b = arena.mul(x, reciprocal);
        assert!(agree_at(&arena, a, &arena, b, 0xdeadbeef, 0.0).unwrap());
        let zero = arena.int(0);
        let singular = arena.div(x, zero);
        assert!(eval_rational(&arena, singular, 1, &mut HashMap::new()).is_none());
        assert!(!agree_at(&arena, singular, &arena, singular, 1, 1e-9).unwrap());
    }

    #[test]
    fn unsupported_transcendentals_and_undefined_values_keep_their_numeric_failures() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        let exponential = arena.exp(x);
        let large = arena.int(1 << 60);
        let sum = arena.add(exponential, large);
        let cancelled = arena.sub(sum, large);
        assert!(eval_rational(&arena, cancelled, 1, &mut HashMap::new()).is_none());
        assert!(verify_verdict(&arena, cancelled, &arena, exponential, true).is_err());
        let undefined = arena.undefined();
        assert_eq!(
            agree_at(&arena, undefined, &arena, x, 1, 1e-9),
            Err(NumericError::Undefined)
        );
    }

    #[test]
    fn explosive_arithmetic_refuses_exact_replay_without_constructing_huge_integers() {
        let mut arena = ExprArena::new();
        let mut expression = arena.param_symbol("x");
        for _ in 0..30 {
            expression = arena.mul(expression, expression);
        }
        assert!(eval_rational(&arena, expression, 1, &mut HashMap::new()).is_none());
    }
}
