//! Native AMD values execution.
use super::*;

impl Interpreter<'_> {
    pub(super) fn real(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
    ) -> Result<ExprId, EvalError> {
        if let Operand::Modified {
            value,
            negate,
            absolute,
        } = operand
        {
            let mut expression = self.real(wave, value, lane)?;
            if *absolute {
                expression = self.arena.abs(expression);
            }
            if *negate {
                expression = self.arena.neg(expression);
            }
            return Ok(expression);
        }
        let value = wave.value(operand, lane)?;
        self.real_value(wave, value, lane)
    }
    pub(super) fn real_value(
        &mut self,
        wave: &Wave,
        value: Value,
        lane: u8,
    ) -> Result<ExprId, EvalError> {
        if let Value::Input(expr) = value {
            self.claim_word_format(wave, expr, WordFormat::Float32)?;
            return Ok(expr);
        }
        if let Value::IntExpr(expr) = value
            && let Some(pattern) = self.float_bit_patterns.get(&expr).cloned()
        {
            for input in pattern.input_words {
                self.claim_word_format(wave, input, WordFormat::Float32)?;
            }
            return Ok(pattern.decoded);
        }
        value
            .real(&mut self.arena)
            .map_err(|e| wave.fail(Some(lane), e))
    }
    pub(super) fn claim_word_format(
        &mut self,
        wave: &Wave,
        expr: ExprId,
        format: WordFormat,
    ) -> Result<(), EvalError> {
        if let ExprNode::InputElement { array, .. } = self.arena.node(expr) {
            if let Some(previous) = self.word_formats.get(array) {
                if *previous != format {
                    return Err(EvalError::Unsupported {
                        pc: wave.pc,
                        what: format!(
                            "input array '{}' has conflicting word interpretations {previous:?} and {format:?}",
                            self.arena.string(*array)
                        ),
                    });
                }
            } else {
                self.word_formats.insert(*array, format);
            }
        }
        Ok(())
    }
    pub(super) fn claim_half_format(
        &mut self,
        wave: &Wave,
        expr: ExprId,
        format: WordFormat,
    ) -> Result<(), EvalError> {
        // Only the original configured 16-bit input fixes a raw format.
        // A mathematical F32 value rounded/transported through F16 retains
        // its expression identity in this abstraction, not its input encoding.
        if let ExprNode::InputElement { array, .. } = self.arena.node(expr) {
            let name = self.arena.string(*array);
            if self
                .config
                .arrays
                .iter()
                .any(|a| a.name == name && a.elem_width == 2)
            {
                self.claim_word_format(wave, expr, format)?;
            } else if format == WordFormat::Bfloat16 {
                return Err(EvalError::Unsupported{pc:wave.pc,what:"symbolic BF16 requires original16-bit input storage, not a produced F16 encoding".into()});
            }
        }
        Ok(())
    }
    pub(super) fn integer_expression(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        ty: super::super::scalar::IntType,
    ) -> Result<ExprId, EvalError> {
        if let Operand::Integer(value) = operand {
            return Ok(self.arena.int(*value));
        }
        match wave.value(operand, lane)? {
            Value::Input(expr) => {
                self.claim_word_format(wave, expr, WordFormat::Integer32)?;
                Ok(expr)
            }
            Value::Byte(expr) => {
                // Native UBYTE loads zero-extend; an integer consumer fixes
                // the encoded input's numeric interpretation as unsigned8.
                self.claim_byte_format(wave, expr, ByteFormat::UnsignedU8)?;
                Ok(expr)
            }
            Value::IntExpr(expr) => {
                if let Some(pattern) = self.float_bit_patterns.get(&expr).cloned() {
                    for input in pattern.input_words {
                        self.claim_word_format(wave, input, WordFormat::Integer32)?;
                    }
                }
                Ok(expr)
            }
            Value::WidePart {
                expr,
                high: true,
                kind: WideKind::Integer,
            } => {
                let value = self
                    .arena
                    .as_int_const(expr)
                    .ok_or_else(|| self.unsupported(wave, &self.program.instructions[wave.pc]))?;
                let high = ((value as u64) >> 32) as u32;
                Ok(self.arena.int(if ty.signed {
                    high as i32 as i64
                } else {
                    high as i64
                }))
            }
            Value::NarrowInt { expr, .. } => Ok(expr),
            Value::SignedInteger(value) => Ok(self.arena.int(value as i64)),
            Value::Bits(value) | Value::Integer(value) => Ok(self.arena.int(if ty.signed {
                value as i32 as i64
            } else {
                value as i64
            })),
            Value::SharedApertureHi => Err(wave.fail(
                Some(lane),
                "opaque shared aperture cannot be used as integer data",
            )),
            Value::RelocationWord { .. } | Value::CodeWord { .. } => Err(wave.fail(
                Some(lane),
                "opaque PC relocation cannot be used as integer data",
            )),
            Value::PartialBits { bits, defined } if ty.bits == 16 && defined & 65535 == 65535 => {
                Ok(self.arena.int((bits & 65535) as i64))
            }
            Value::PartialBits { .. } => Err(wave.fail(
                Some(lane),
                "integer arithmetic observes undefined bits from ABI padding",
            )),
            _ => Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "typed floating/packed data cannot be reinterpreted as a symbolic integer"
                    .into(),
            }),
        }
    }
    pub(super) fn integer_result(&self, expr: ExprId, signed: bool) -> Value {
        match self.arena.as_int_const(expr) {
            Some(value) if signed => Value::SignedInteger(value as i32),
            Some(value) => Value::Integer(value as u32),
            None => Value::IntExpr(expr),
        }
    }
    pub(super) fn write_predicates(
        &mut self,
        wave: &mut Wave,
        destination: Option<&Operand>,
        predicates: [ExprId; 64],
    ) -> Result<(), EvalError> {
        let mask_id = u32::try_from(self.predicate_masks.len())
            .map_err(|_| wave.fail(None, "predicate pool exhausted"))?;
        let mut words = [Value::Bits(0); 2];
        let mut symbolic = false;
        for half in 0..2 {
            let mut bits = 0u32;
            let mut concrete = true;
            for bit in 0..32 {
                match self.arena.as_bool(predicates[half * 32 + bit]) {
                    Some(true) => bits |= 1u32 << bit,
                    Some(false) => {}
                    None => concrete = false,
                }
            }
            words[half] = if concrete {
                Value::Bits(bits)
            } else {
                symbolic = true;
                Value::PredicateWord {
                    mask: mask_id,
                    high: half != 0,
                }
            };
        }
        if symbolic {
            self.predicate_masks.push(predicates);
        }
        let register = match destination {
            Some(operand) => wave.destination(operand)?,
            None => Register {
                class: RegisterClass::Special,
                index: 0,
                count: (wave.width / 32) as u16,
                special: Some(SpecialRegister::Vcc),
            },
        };
        wave.put(register, 0, 0, words[0])?;
        if register.count > 1 {
            wave.put(register, 0, 1, words[1])
        } else {
            Ok(())
        }
    }
    pub(super) fn predicate_condition(
        &mut self,
        wave: &Wave,
        operand: Option<&Operand>,
        lane: u8,
    ) -> Result<ExprId, EvalError> {
        let register = match operand {
            Some(operand) => wave.destination(operand)?,
            None => Register {
                class: RegisterClass::Special,
                index: 0,
                count: (wave.width / 32) as u16,
                special: Some(SpecialRegister::Vcc),
            },
        };
        let word = wave.reg(register, 0, (lane / 32) as u16)?;
        match word {
            Value::PredicateWord { mask, high } => self
                .predicate_masks
                .get(mask as usize)
                .map(|predicates| predicates[(lane % 32) as usize + if high { 32 } else { 0 }])
                .ok_or_else(|| wave.fail(Some(lane), "invalid predicate mask identity")),
            value => {
                let bits = value.bits().map_err(|e| wave.fail(Some(lane), e))?;
                Ok(self.arena.bool_val(bits & (1u32 << (lane % 32)) != 0))
            }
        }
    }
    /// Float helper APIs accept raw IntConst bit patterns. Values here have
    /// already been decoded, so keep integral mathematical floats as reals.
    pub(super) fn decoded_float_argument(&mut self, expression: ExprId) -> ExprId {
        if let Some(value) = self.arena.as_int_const(expression) {
            self.arena.real(volta_expr::Real::from_i64(value))
        } else {
            expression
        }
    }
    pub(super) fn select_word(
        &mut self,
        wave: &Wave,
        condition: ExprId,
        when_true: &Operand,
        when_false: &Operand,
        lane: u8,
        force_float: bool,
    ) -> Result<Value, EvalError> {
        use super::super::scalar::{FloatType, IntType, ScalarType, select};
        if let Some(condition) = self.arena.as_bool(condition) {
            return self.modified_value(wave, if condition { when_true } else { when_false }, lane);
        }
        let half_payload = |operand: &Operand| {
            matches!(
                wave.value(operand, lane),
                Ok(Value::Half(_) | Value::Halves(..) | Value::PartialHalves(..))
            )
        };
        if !force_float && (half_payload(when_true) || half_payload(when_false)) {
            // CNDMASK copies a whole encoded word. Preserve both independent
            // half identities under the same condition rather than retyping
            // packed floating data as an integer or selecting only low16.
            let mut components = [None, None];
            for (component, high) in [false, true].into_iter().enumerate() {
                let defined = |operand: &Operand| match wave.value(operand, lane) {
                    Ok(Value::PartialHalves(lo, hi)) => if high { hi } else { lo }.is_some(),
                    _ => true,
                };
                if !defined(when_true) || !defined(when_false) {
                    continue;
                }
                let a = self.half(wave, when_true, lane, high)?;
                let b = self.half(wave, when_false, lane, high)?;
                let a = self.decoded_float_argument(a);
                let b = self.decoded_float_argument(b);
                components[component] = Some(
                    super::super::scalar::select_packed_half(&mut self.arena, condition, a, b)
                        .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?,
                );
            }
            return Ok(match components {
                [Some(lo), Some(hi)] => Value::Halves(lo, hi),
                [lo, hi] => Value::PartialHalves(lo, hi),
            });
        }
        let is_float = |operand: &Operand| {
            if matches!(operand, Operand::Float(_) | Operand::Modified { .. }) {
                return true;
            }
            match wave.value(operand, lane) {
                Ok(Value::Real(_)) => true,
                Ok(Value::Input(expr)) => match self.arena.node(expr) {
                    ExprNode::InputElement { array, .. } => {
                        self.word_formats.get(array) == Some(&WordFormat::Float32)
                    }
                    _ => false,
                },
                _ => false,
            }
        };
        if force_float || is_float(when_true) || is_float(when_false) {
            let a = self.real(wave, when_true, lane)?;
            let b = self.real(wave, when_false, lane)?;
            let a = self.decoded_float_argument(a);
            let b = self.decoded_float_argument(b);
            let result = select(
                &mut self.arena,
                ScalarType::Float(FloatType::F32),
                condition,
                a,
                b,
            )
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
            Ok(Value::Real(result))
        } else {
            let ty = IntType {
                bits: 32,
                signed: false,
            };
            let a = self.integer_expression(wave, when_true, lane, ty)?;
            let b = self.integer_expression(wave, when_false, lane, ty)?;
            let result = select(&mut self.arena, ScalarType::Int(ty), condition, a, b)
                .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
            Ok(self.integer_result(result, false))
        }
    }
    pub(super) fn real64(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
    ) -> Result<ExprId, EvalError> {
        use super::super::scalar::{FloatType, decode_float};
        if let Operand::Modified {
            value,
            negate,
            absolute,
        } = operand
        {
            let mut expr = self.real64(wave, value, lane)?;
            if *absolute {
                expr = self.arena.abs(expr);
            }
            if *negate {
                expr = self.arena.neg(expr);
            }
            return Ok(expr);
        }
        if let Operand::Float(value) = operand {
            let magnitude = value.abs();
            if ![0.0, 0.5, 1.0, 2.0, 4.0].contains(&magnitude) {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "non-inline f64 constants require their actual encoded high-word literal"
                        .into(),
                });
            }
            return self
                .arena
                .float_from_f64(*value)
                .map_err(|e| wave.fail(Some(lane), e.to_string()));
        }
        if let Operand::Integer(value) = operand {
            if *value != 0 && (-16..=64).contains(value) {
                return Err(EvalError::Unsupported{pc:wave.pc,what:"nonzero integer inline constants used as f64 need explicit encoding semantics".into()});
            }
            if *value < i32::MIN as i64 || *value > u32::MAX as i64 {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "f64 literal is one encoded32-bit high word".into(),
                });
            }
            return decode_float(
                &mut self.arena,
                FloatType::F64,
                (*value as u32 as u64) << 32,
            )
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what });
        }
        if let Operand::Register(register) = operand {
            if register.count != 2 {
                return Err(wave.fail(
                    Some(lane),
                    "f64 source must contain two ordered register words",
                ));
            }
            let lo = wave.reg(*register, lane, 0)?;
            let hi = wave.reg(*register, lane, 1)?;
            match (lo, hi) {
                (Value::WidePart { expr: a, high: false, kind: ak },
                 Value::WidePart { expr: b, high: true, kind: bk })
                 if a == b && ak == bk && matches!(ak, WideKind::Input | WideKind::Float) => {
                    if ak==WideKind::Input {self.claim_word_format(wave,a,WordFormat::Float64)?;}
                    return Ok(a);
                 },
                (lo, hi) if lo.bits().is_ok() && hi.bits().is_ok() => {},
                _ => return Err(EvalError::Unsupported { pc: wave.pc, what: "f64 requires matching ordered words of one floating/input value; packed or integer words cannot be reinterpreted".into() }),
            }
        }
        let bits = wave.wide(operand, lane)?;
        decode_float(&mut self.arena, FloatType::F64, bits)
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })
    }
    pub(super) fn put_real64(
        &self,
        wave: &mut Wave,
        operand: &Operand,
        lane: u8,
        expr: ExprId,
    ) -> Result<(), EvalError> {
        let register = wave.destination(operand)?;
        if register.count != 2 {
            return Err(wave.fail(Some(lane), "f64 destination must contain two ordered words"));
        }
        wave.put(
            register,
            lane,
            0,
            Value::WidePart {
                expr,
                high: false,
                kind: WideKind::Float,
            },
        )?;
        wave.put(
            register,
            lane,
            1,
            Value::WidePart {
                expr,
                high: true,
                kind: WideKind::Float,
            },
        )
    }
    pub(super) fn real_component(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        component: u16,
    ) -> Result<ExprId, EvalError> {
        match operand {
            Operand::Register(register) if register.count == 2 => {
                let value = wave.reg(*register, lane, component)?;
                self.real_value(wave, value, lane)
            }
            Operand::Modified {
                value,
                negate,
                absolute,
            } => {
                let mut expr = self.real_component(wave, value, lane, component)?;
                if *absolute {
                    expr = self.arena.abs(expr);
                }
                if *negate {
                    expr = self.arena.neg(expr);
                }
                Ok(expr)
            }
            _ => self.real(wave, operand, lane),
        }
    }
    pub(super) fn selected_bits(
        &self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        instruction: &Instruction,
        index: u8,
    ) -> Result<u32, EvalError> {
        let bits = wave.bits(operand, lane)?;
        let field = if index == 0 { "src0_sel" } else { "src1_sel" };
        Ok(
            match instruction
                .modifiers()
                .iter()
                .find(|modifier| modifier.name == field)
                .and_then(|modifier| modifier.value.as_deref())
                .unwrap_or("DWORD")
            {
                "DWORD" => bits,
                "WORD_0" => bits & 65535,
                "WORD_1" => bits >> 16,
                "BYTE_0" => bits & 255,
                "BYTE_1" => (bits >> 8) & 255,
                "BYTE_2" => (bits >> 16) & 255,
                "BYTE_3" => bits >> 24,
                _ => return Err(self.unsupported(wave, instruction)),
            },
        )
    }
    pub(super) fn modified_value(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
    ) -> Result<Value, EvalError> {
        if matches!(operand, Operand::Modified { .. }) {
            Ok(Value::Real(self.real(wave, operand, lane)?))
        } else {
            wave.value(operand, lane)
        }
    }
    pub(super) fn float_bit_source(
        &mut self,
        value: Value,
    ) -> Result<Option<(ExprId, FloatBitPattern)>, String> {
        if let Some(bits) = super::super::float_bits::exact_word(&self.arena, value) {
            let decoded = super::super::scalar::decode_float(
                &mut self.arena,
                super::super::scalar::FloatType::F32,
                u64::from(bits),
            )?;
            let raw = self.arena.int(i64::from(bits));
            return Ok(Some((
                raw,
                FloatBitPattern {
                    decoded,
                    input_words: Vec::new(),
                },
            )));
        }
        Ok(match value {
            Value::Input(expr) => Some((
                expr,
                FloatBitPattern {
                    decoded: expr,
                    input_words: vec![expr],
                },
            )),
            Value::IntExpr(expr) => self
                .float_bit_patterns
                .get(&expr)
                .cloned()
                .map(|pattern| (expr, pattern)),
            _ => None,
        })
    }
    /// Exact encoded byte transport only. Unknown bytes stay absent; no array
    /// interpretation is claimed until a numeric decoder actually consumes one.
    pub(super) fn encoded_bytes(&mut self, value: Value) -> Option<[Option<ExprId>; 4]> {
        let zero = self.arena.int(0);
        Some(match value {
            Value::Byte(a) => [Some(a), Some(zero), Some(zero), Some(zero)],
            Value::BytePair(a, b) => [Some(a), Some(b), Some(zero), Some(zero)],
            Value::PartialBytePair(a, b) => [Some(a), Some(b), None, None],
            Value::Bytes(bytes) => bytes.map(Some),
            Value::PartialBits { bits, defined } => std::array::from_fn(|i| {
                ((defined >> (i * 8)) & 255 == 255)
                    .then(|| self.arena.int(((bits >> (i * 8)) & 255) as i64))
            }),
            Value::Bits(bits) | Value::Integer(bits) => {
                std::array::from_fn(|i| Some(self.arena.int(((bits >> (i * 8)) & 255) as i64)))
            }
            Value::SignedInteger(bits) => std::array::from_fn(|i| {
                Some(self.arena.int((((bits as u32) >> (i * 8)) & 255) as i64))
            }),
            _ => return None,
        })
    }
    pub(super) fn fp8(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        byte: usize,
    ) -> Result<ExprId, EvalError> {
        if byte > 3 {
            return Err(self.unsupported(wave, &self.program.instructions[wave.pc]));
        }
        let bits = match wave.value(operand, lane)? {
            Value::Bytes(bytes) => {
                self.claim_byte_format(wave, bytes[byte], ByteFormat::OcpE4m3)?;
                return Ok(bytes[byte]);
            }
            Value::PartialBytePair(lo, hi) => {
                if byte >= 2 {
                    return Err(wave.fail(
                        Some(lane),
                        "selected undefined upper byte of true16 packing",
                    ));
                }
                let value = if byte == 0 { lo } else { hi };
                self.claim_byte_format(wave, value, ByteFormat::OcpE4m3)?;
                return Ok(value);
            }
            Value::BytePair(lo, hi) => {
                if byte < 2 {
                    let value = if byte == 0 { lo } else { hi };
                    self.claim_byte_format(wave, value, ByteFormat::OcpE4m3)?;
                    return Ok(value);
                }
                return Ok(self.arena.int(0));
            }
            Value::Byte(expr) => {
                if byte == 0 {
                    self.claim_byte_format(wave, expr, ByteFormat::OcpE4m3)?;
                    return Ok(expr);
                } else {
                    return Ok(self.arena.int(0));
                }
            }
            value @ (Value::Bits(_) | Value::Integer(_) | Value::SignedInteger(_)) => {
                (value.bits().unwrap() >> (8 * byte)) & 255
            }
            _ => {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "non-FP8 storage used by OCP E4M3 decoder".into(),
                });
            }
        };
        let sign = if bits & 128 == 0 { 1.0 } else { -1.0 };
        let exponent = (bits >> 3) & 15;
        let fraction = bits & 7;
        if exponent == 15 && fraction == 7 {
            return Err(wave.fail(Some(lane), "OCP E4M3 NaN is outside the real-number model"));
        }
        let value = if exponent == 0 {
            sign * fraction as f64 * 2f64.powi(-9)
        } else {
            sign * (1.0 + fraction as f64 / 8.0) * 2f64.powi(exponent as i32 - 7)
        };
        self.arena
            .float_from_f64(value)
            .map_err(|e| wave.fail(Some(lane), e.to_string()))
    }
    pub(super) fn claim_byte_format(
        &mut self,
        wave: &Wave,
        expr: ExprId,
        format: ByteFormat,
    ) -> Result<(), EvalError> {
        if let ExprNode::InputElement { array, .. } = self.arena.node(expr) {
            if let Some(previous) = self.byte_formats.get(array) {
                if *previous != format {
                    return Err(EvalError::Unsupported {
                        pc: wave.pc,
                        what: format!(
                            "input array '{}' has conflicting byte interpretations {previous:?} and {format:?}",
                            self.arena.string(*array)
                        ),
                    });
                }
            } else {
                self.byte_formats.insert(*array, format);
            }
        }
        Ok(())
    }
    pub(super) fn signed16_to_half(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        instruction: &Instruction,
    ) -> Result<ExprId, EvalError> {
        let selector = instruction
            .modifiers()
            .iter()
            .find(|modifier| modifier.name == "src0_sel")
            .and_then(|modifier| modifier.value.as_deref())
            .unwrap_or("DWORD");
        let sext = instruction
            .modifiers()
            .iter()
            .any(|modifier| modifier.name == "src0_sext");
        let byte = selector
            .strip_prefix("BYTE_")
            .and_then(|value| value.parse::<usize>().ok());
        let value = wave.value(operand, lane)?;
        let symbolic = match value {
            Value::Byte(expr) if byte == Some(0) || selector == "DWORD" => Some(expr),
            Value::Byte(_) if byte.is_some() => return Ok(self.arena.int(0)),
            Value::Bytes(bytes) if byte.is_some() => Some(bytes[byte.unwrap()]),
            Value::Low16Integer(expr) if selector == "DWORD" => return Ok(expr),
            Value::NarrowInt { expr, bits, signed }
                if selector == "DWORD" && bits <= 16 && signed =>
            {
                return Ok(expr);
            }
            Value::NarrowInt {
                expr,
                bits: 8,
                signed: true,
            } if byte == Some(0) && sext => return Ok(expr),
            _ => None,
        };
        if let Some(expr) = symbolic {
            self.claim_byte_format(
                wave,
                expr,
                if sext {
                    ByteFormat::SignedI8
                } else {
                    ByteFormat::UnsignedU8
                },
            )?;
            return Ok(expr);
        }
        let bits = value.bits().map_err(|_| EvalError::Unsupported {
            pc: wave.pc,
            what: "signed16 conversion requires concrete bits or a typed signed-byte data path"
                .into(),
        })?;
        let selected = match selector {
            "DWORD" => bits,
            "WORD_0" => bits & 65535,
            "WORD_1" => bits >> 16,
            _ => byte
                .map(|index| (bits >> (8 * index)) & 255)
                .ok_or_else(|| self.unsupported(wave, instruction))?,
        };
        let number = if byte.is_some() && sext {
            selected as i8 as i64
        } else {
            selected as i16 as i64
        };
        Ok(self.arena.int(number))
    }
    /// Copy an encoded half without assigning a numeric format. Symbolic
    /// global halfwords remain untyped until F16/BF16 arithmetic consumes them.
    /// Raw nonzero constants retain the existing F16 interpretation and the
    /// BF16 matrix input guard rejects their cross-format reinterpretation.
    pub(super) fn copied_half(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        high: bool,
    ) -> Result<ExprId, EvalError> {
        match wave.value(operand, lane)? {
            Value::Half(expr) => Ok(if high { self.arena.int(0) } else { expr }),
            Value::HighHalf(expr) => Ok(if high { expr } else { self.arena.int(0) }),
            Value::Halves(lo, hi) => Ok(if high { hi } else { lo }),
            Value::PartialHalves(lo, hi) => {
                if high { hi } else { lo }.ok_or_else(|| EvalError::Unsupported {
                    pc: wave.pc,
                    what: "unknown half after partial register write".into(),
                })
            }
            _ => self.half(wave, operand, lane, high),
        }
    }
    pub(super) fn half(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        high: bool,
    ) -> Result<ExprId, EvalError> {
        if let Operand::Float(value) = operand {
            return self
                .arena
                .float_from_f64(*value)
                .map_err(|e| wave.fail(Some(lane), e.to_string()));
        }
        if let Operand::Modified {
            value,
            negate,
            absolute,
        } = operand
        {
            let mut expr = self.half(wave, value, lane, high)?;
            if *absolute {
                expr = self.arena.abs(expr);
            }
            if *negate {
                expr = self.arena.neg(expr);
            }
            return Ok(expr);
        }
        match wave.value(operand, lane)? {
            Value::HighHalf(expr) => {
                if high {
                    self.claim_half_format(wave, expr, WordFormat::Float16)?;
                    Ok(expr)
                } else {
                    Ok(self.arena.int(0))
                }
            }
            Value::Halves(lo, hi) => {
                let expr = if high { hi } else { lo };
                self.claim_half_format(wave, expr, WordFormat::Float16)?;
                Ok(expr)
            }
            Value::PartialHalves(lo, hi) => {
                if high { hi } else { lo }.ok_or_else(|| EvalError::Unsupported {
                    pc: wave.pc,
                    what: "unknown half after partial register write".into(),
                })
            }
            Value::Half(expr) => {
                if high {
                    Ok(self.arena.int(0))
                } else {
                    self.claim_half_format(wave, expr, WordFormat::Float16)?;
                    Ok(expr)
                }
            }
            value @ (Value::Bits(_) | Value::Integer(_) | Value::SignedInteger(_)) => {
                let bits = value.bits().unwrap();
                let bits = if high { bits >> 16 } else { bits & 0xffff };
                let sign = if bits & 0x8000 == 0 { 1.0 } else { -1.0 };
                let exponent = (bits >> 10) & 31;
                let fraction = bits & 1023;
                let value = if exponent == 31 {
                    if fraction != 0 {
                        return Err(wave.fail(Some(lane), "half NaN outside real arithmetic model"));
                    }
                    sign * f64::INFINITY
                } else if exponent == 0 {
                    sign * (fraction as f64) * 2f64.powi(-24)
                } else {
                    sign * (1.0 + fraction as f64 / 1024.0) * 2f64.powi(exponent as i32 - 15)
                };
                self.arena
                    .float_from_f64(value)
                    .map_err(|e| wave.fail(Some(lane), e.to_string()))
            }
            Value::IntExpr(expr) => {
                super::super::scalar::decode_half_select(&mut self.arena, expr, high)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })
            }
            Value::Input(_)
            | Value::PredicateWord { .. }
            | Value::RelocationWord { .. }
            | Value::CodeWord { .. }
            | Value::SharedApertureHi
            | Value::PartialBits { .. }
            | Value::NarrowInt { .. }
            | Value::Low16Integer(_)
            | Value::WidePart { .. }
            | Value::Real(_)
            | Value::Byte(_)
            | Value::Bytes(_)
            | Value::BytePair(..)
            | Value::PartialBytePair(..) => Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "symbolic non-f16 bits reinterpreted as half".into(),
            }),
        }
    }
    pub(super) fn exp2(&mut self, argument: ExprId) -> ExprId {
        if let Some(unscaled) = self.factor_exp2_idiom(argument) {
            self.builder.assume(Assumption::CompilerExp2Idiom);
            return self.arena.exp(unscaled);
        }
        let ln2 = self.ln2_constant();
        let scaled = self.arena.mul(argument, ln2);
        self.arena.exp(scaled)
    }
    pub(super) fn ln2_constant(&mut self) -> ExprId {
        self.builder.assume(Assumption::CompilerBase2Conversion);
        let log2e = volta_expr::Real::from_f64(std::f64::consts::LOG2_E as f32 as f64)
            .expect("the pinned finite LOG2_E_F32 constant is representable");
        self.arena
            .real(log2e.try_recip().expect("LOG2_E_F32 is nonzero"))
    }
    /// Only the exact rounded binary32 constant generated by the pinned compiler
    /// is abstracted as log2(e). Near constants and unfactored additive offsets
    /// deliberately retain their actual exp2 expression.
    pub(super) fn factor_exp2_idiom(&mut self, argument: ExprId) -> Option<ExprId> {
        let constant = std::f64::consts::LOG2_E as f32 as f64;
        let factor = |arena: &ExprArena, id| match arena.node(id) {
            ExprNode::RealConst(value) if value.to_f64().abs() == constant => {
                Some(value.to_f64().is_sign_negative())
            }
            _ => None,
        };
        match self.arena.node(argument).clone() {
            ExprNode::IntConst(0) => Some(argument),
            ExprNode::RealConst(value) if value.to_f64() == 0.0 => Some(argument),
            ExprNode::Mul(a, b) => {
                for (value, other) in [(a, b), (b, a)] {
                    if let Some(negative) = factor(&self.arena, value) {
                        return Some(if negative {
                            self.arena.neg(other)
                        } else {
                            other
                        });
                    }
                }
                None
            }
            ExprNode::Add(a, b) => {
                let a = self.factor_exp2_idiom(a)?;
                let b = self.factor_exp2_idiom(b)?;
                Some(self.arena.add(a, b))
            }
            ExprNode::Sub(a, b) => {
                let a = self.factor_exp2_idiom(a)?;
                let b = self.factor_exp2_idiom(b)?;
                Some(self.arena.sub(a, b))
            }
            ExprNode::Neg(a) => {
                let a = self.factor_exp2_idiom(a)?;
                Some(self.arena.neg(a))
            }
            ExprNode::Fma(a, b, c) => {
                let (other, negative) = if let Some(negative) = factor(&self.arena, a) {
                    (b, negative)
                } else {
                    (a, factor(&self.arena, b)?)
                };
                let product = if negative {
                    self.arena.neg(other)
                } else {
                    other
                };
                let rest = self.factor_exp2_idiom(c)?;
                Some(self.arena.add(product, rest))
            }
            _ => None,
        }
    }
    pub(super) fn concrete_zero(&self, value: ExprId) -> bool {
        match self.arena.node(value) {
            ExprNode::IntConst(0) => true,
            ExprNode::RealConst(value) => value.is_zero(),
            _ => false,
        }
    }
    pub(super) fn concrete_sign(&self, value: ExprId) -> Option<std::cmp::Ordering> {
        match self.arena.node(value) {
            ExprNode::IntConst(value) => Some(value.cmp(&0)),
            ExprNode::RealConst(value) => Some(value.cmp(&volta_expr::Real::from_i64(0))),
            _ => None,
        }
    }
}
