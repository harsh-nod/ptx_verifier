//! Native AMD vector alu execution.
use super::*;

impl Interpreter<'_> {
    pub(super) fn vector(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        operation: AluOperation,
    ) -> Result<(), EvalError> {
        if self.architecture == AmdArchitecture::Gfx950
            && matches!(
                operation,
                AluOperation::VReadlaneB32 | AluOperation::VWritelaneB32
            )
        {
            return self.private_lane(wave, instruction);
        }
        if matches!(
            operation,
            AluOperation::VReadlaneB32
                | AluOperation::VReadfirstlaneB32
                | AluOperation::VWritelaneB32
        ) && !(matches!(
            operation,
            AluOperation::VReadlaneB32 | AluOperation::VReadfirstlaneB32
        ) && self.architecture == AmdArchitecture::Gfx1250)
        {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "lane/accumulator register moves need Table 11 software dependency checks"
                    .into(),
            });
        }
        let o = instruction.operands();
        if operation == AluOperation::VSExpF32 {
            fn scalar_source(operand: &Operand) -> bool {
                match operand {
                    Operand::Register(r) => {
                        r.count == 1
                            && matches!(
                                r.class,
                                RegisterClass::Scalar
                                    | RegisterClass::Temporary
                                    | RegisterClass::Special
                            )
                    }
                    Operand::Modified { value, .. } => scalar_source(value),
                    Operand::Integer(_) | Operand::Float(_) => true,
                    _ => false,
                }
            }
            if !scalar_source(&o[1]) {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what:
                        "v_s_exp_f32 requires a scalar source; vector-lane broadcast is not modeled"
                            .into(),
                });
            }
            if !instruction.modifiers().is_empty() || wave.exec == 0 {
                return Err(self.unsupported(wave, instruction));
            }
            let a = self.real(wave, &o[1], 0)?;
            let value = self.exp2(a);
            return wave.put_value(&o[0], 0, Value::Real(value));
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && (operation == AluOperation::VAshrrevI16 || operation == AluOperation::VBfeI32)
        {
            if !instruction.modifiers().is_empty()
                || o.iter()
                    .any(|operand| matches!(operand, Operand::Modified { .. }))
            {
                return Err(self.unsupported(wave, instruction));
            }
            let uniform_bits = |operand: &Operand| {
                if matches!(operand, Operand::Register(register) if matches!(register.class, RegisterClass::Vector | RegisterClass::Accumulator))
                {
                    None
                } else {
                    wave.bits(operand, 0).ok()
                }
            };
            let (operand, byte) =
                if operation == AluOperation::VAshrrevI16 && uniform_bits(&o[1]) == Some(8) {
                    (&o[2], Some(1))
                } else if operation == AluOperation::VBfeI32 && uniform_bits(&o[3]) == Some(8) {
                    let offset = uniform_bits(&o[2]);
                    (
                        &o[1],
                        offset
                            .filter(|offset| *offset < 32 && *offset % 8 == 0)
                            .map(|offset| offset / 8),
                    )
                } else {
                    (&o[1], None)
                };
            if let Some(byte) = byte {
                let lanes = wave.active().collect::<Vec<_>>();
                let mut decoded = Vec::new();
                for lane in &lanes {
                    let value = wave.value(operand, *lane)?;
                    let zero = self.arena.int(0);
                    let expr = match value {
                        Value::Bytes(values) => Some(values[byte as usize]),
                        Value::Byte(expr) => Some(if byte == 0 { expr } else { zero }),
                        Value::BytePair(a, b) => Some(match byte {
                            0 => a,
                            1 => b,
                            _ => zero,
                        }),
                        _ => None,
                    };
                    if let Some(expr) = expr {
                        self.claim_byte_format(wave, expr, ByteFormat::SignedI8)?;
                        decoded.push((*lane, expr));
                    } else {
                        break;
                    }
                }
                if decoded.len() == lanes.len() {
                    for (lane, expr) in decoded {
                        wave.put_value(
                            &o[0],
                            lane,
                            if operation == AluOperation::VAshrrevI16 {
                                Value::Low16Integer(expr)
                            } else {
                                Value::NarrowInt {
                                    expr,
                                    bits: 8,
                                    signed: true,
                                }
                            },
                        )?;
                    }
                    return Ok(());
                }
            }
            if operation == AluOperation::VAshrrevI16 {
                if !instruction.modifiers().is_empty() {
                    return Err(self.unsupported(wave, instruction));
                }
                for lane in wave.active().collect::<Vec<_>>() {
                    let shift = wave
                        .value(&o[1], lane)?
                        .selected_bits(0, 4)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let source = wave
                        .value(&o[2], lane)?
                        .selected_bits(0, 16)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let result = self.arena.int(((source as i16) >> shift) as i64);
                    wave.put_value(&o[0], lane, Value::Low16Integer(result))?;
                }
                return Ok(());
            }
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && matches!(
                operation,
                AluOperation::VPkMulLoU16 | AluOperation::VPkSubI16
            )
        {
            if !instruction
                .modifiers()
                .iter()
                .all(|m| matches!(m.name.as_str(), "op_sel" | "op_sel_hi"))
            {
                return Err(self.unsupported(wave, instruction));
            }
            let low = selectors(instruction, "op_sel", 2, 0)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let high = selectors(instruction, "op_sel_hi", 2, 1)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            for lane in wave.active().collect::<Vec<_>>() {
                let mut result = 0u32;
                for (half, selection) in [low.as_slice(), high.as_slice()].into_iter().enumerate() {
                    let a = wave
                        .value(&o[1], lane)?
                        .selected_bits(u32::from(selection[0]) * 16, 16)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let b = wave
                        .value(&o[2], lane)?
                        .selected_bits(u32::from(selection[1]) * 16, 16)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let bits = if operation == AluOperation::VPkMulLoU16 {
                        a.wrapping_mul(b)
                    } else {
                        a.wrapping_sub(b)
                    };
                    result |= (bits & 65535) << (half * 16);
                }
                wave.put_value(&o[0], lane, Value::Integer(result))?;
            }
            return Ok(());
        }
        if (self.architecture == AmdArchitecture::Gfx1250
            && matches!(
                operation,
                AluOperation::VLshlrevB16
                    | AluOperation::VLshrrevB16
                    | AluOperation::VSubU16
                    | AluOperation::VMulLoU16
                    | AluOperation::VBitop3B16
            ))
            || matches!(
                operation,
                AluOperation::VLshlrevB16 | AluOperation::VBitop3B16
            )
        {
            // The selected equations observe low16 data and low4 shift bits.
            // Upper destination bits are not inferred from a narrow ISA
            // assignment, including the newly selected CDNA forms.
            if (operation != AluOperation::VBitop3B16 && !instruction.modifiers().is_empty())
                || (operation == AluOperation::VBitop3B16
                    && (instruction.modifiers().len() != 1
                        || instruction.modifiers()[0].name != "bitop3"))
            {
                return Err(self.unsupported(wave, instruction));
            }
            for lane in wave.active().collect::<Vec<_>>() {
                let a = wave
                    .value(&o[1], lane)?
                    .selected_bits(
                        0,
                        if matches!(
                            operation,
                            AluOperation::VLshlrevB16 | AluOperation::VLshrrevB16
                        ) {
                            4
                        } else {
                            16
                        },
                    )
                    .map_err(|e| wave.fail(Some(lane), e))?;
                if matches!(
                    operation,
                    AluOperation::VLshlrevB16 | AluOperation::VLshrrevB16
                ) && matches!(a, 0 | 8)
                {
                    let source = wave.value(&o[2], lane)?;
                    if matches!(
                        source,
                        Value::Byte(_)
                            | Value::BytePair(..)
                            | Value::PartialBytePair(..)
                            | Value::Bytes(_)
                    ) {
                        let bytes = self.encoded_bytes(source).expect("encoded byte tag");
                        let zero = self.arena.int(0);
                        let (lo, hi) = match (operation, a) {
                            (_, 0) => (bytes[0], bytes[1]),
                            (AluOperation::VLshlrevB16, 8) => (Some(zero), bytes[0]),
                            _ => (bytes[1], Some(zero)),
                        };
                        if let (Some(lo), Some(hi)) = (lo, hi) {
                            wave.put_value(&o[0], lane, Value::PartialBytePair(lo, hi))?;
                            continue;
                        }
                    }
                }
                let b = wave
                    .value(&o[2], lane)?
                    .selected_bits(0, 16)
                    .map_err(|e| wave.fail(Some(lane), e))?;
                let value = match operation {
                    AluOperation::VLshlrevB16 => b.wrapping_shl(a & 15),
                    AluOperation::VLshrrevB16 => b >> a,
                    AluOperation::VSubU16 => a.wrapping_sub(b),
                    AluOperation::VMulLoU16 => a.wrapping_mul(b),
                    _ => {
                        let c = wave
                            .value(&o[3], lane)?
                            .selected_bits(0, 16)
                            .map_err(|e| wave.fail(Some(lane), e))?;
                        let table = instruction.modifiers()[0]
                            .value
                            .as_deref()
                            .and_then(parse_u64)
                            .ok_or_else(|| self.unsupported(wave, instruction))?;
                        let mut result = 0;
                        for index in 0..8 {
                            if table & (1 << index) != 0 {
                                result |= (if index & 4 != 0 { a } else { !a })
                                    & (if index & 2 != 0 { b } else { !b })
                                    & (if index & 1 != 0 { c } else { !c });
                            }
                        }
                        result
                    }
                };
                wave.put_value(
                    &o[0],
                    lane,
                    Value::PartialBits {
                        bits: value & 65535,
                        defined: 65535,
                    },
                )?;
            }
            return Ok(());
        }
        let packed = matches!(
            operation,
            AluOperation::VPkAddF16
                | AluOperation::VPkAddF32
                | AluOperation::VPkFmaF16
                | AluOperation::VPkFmaF32
                | AluOperation::VPkMaxF16
                | AluOperation::VPkMinF16
                | AluOperation::VPkMulF16
                | AluOperation::VPkMulF32
                | AluOperation::VPkMulLoU16
                | AluOperation::VPkSubI16
        );
        let mix = matches!(
            operation,
            AluOperation::VFmaMixloF16 | AluOperation::VFmaMixhiF16 | AluOperation::VFmaMixF32
        );
        let half_select_high = instruction.modifiers().iter().any(|modifier| {
            modifier.name == "src0_sel" && modifier.value.as_deref() == Some("WORD_1")
        });
        let half_select_high1 = instruction.modifiers().iter().any(|modifier| {
            modifier.name == "src1_sel" && modifier.value.as_deref() == Some("WORD_1")
        });
        let half_op = matches!(
            operation,
            AluOperation::VCvtF32F16
                | AluOperation::VAddF16
                | AluOperation::VSubF16
                | AluOperation::VMulF16
                | AluOperation::VMaxF16
                | AluOperation::VMinF16
        );
        let integer_sdwa = matches!(
            operation,
            AluOperation::VAddU32 | AluOperation::VMulLoU16 | AluOperation::VMulU32U24
        );
        let clamp_f32 = matches!(
            operation,
            AluOperation::VAddF32
                | AluOperation::VSubF32
                | AluOperation::VSubrevF32
                | AluOperation::VMulF32
                | AluOperation::VMinF32
                | AluOperation::VMaxF32
                | AluOperation::VFmaF32
                | AluOperation::VFmacF32
                | AluOperation::VRcpF32
                | AluOperation::VSqrtF32
                | AluOperation::VRsqF32
                | AluOperation::VExpF32
                | AluOperation::VLogF32
                | AluOperation::VMovB32
                | AluOperation::VCndmaskB32
        );
        let saturate = instruction
            .modifiers()
            .iter()
            .any(|modifier| modifier.name == "clamp");
        if saturate
            && (matches!(
                instruction.source().encoding,
                Encoding::E32 | Encoding::Sdwa
            ))
        {
            return Err(self.unsupported(wave, instruction));
        }
        let native_packed_f32 = self.architecture == AmdArchitecture::Gfx1250
            && matches!(
                operation,
                AluOperation::VPkMulF32 | AluOperation::VPkAddF32 | AluOperation::VPkFmaF32
            );
        let valid_modifiers = if native_packed_f32 {
            instruction.modifiers().iter().all(|modifier| {
                matches!(
                    modifier.name.as_str(),
                    "op_sel" | "op_sel_hi" | "neg_lo" | "neg_hi"
                )
            })
        } else if packed || mix {
            instruction
                .modifiers()
                .iter()
                .all(|modifier| matches!(modifier.name.as_str(), "op_sel" | "op_sel_hi"))
        } else if operation == AluOperation::VCvtF16I16 {
            instruction.modifiers().iter().all(|modifier| {
                matches!(
                    (modifier.name.as_str(), modifier.value.as_deref()),
                    ("src0_sext", None)
                        | (
                            "src0_sel",
                            Some(
                                "DWORD"
                                    | "WORD_0"
                                    | "WORD_1"
                                    | "BYTE_0"
                                    | "BYTE_1"
                                    | "BYTE_2"
                                    | "BYTE_3"
                            )
                        )
                        | ("dst_sel", Some("DWORD"))
                        | ("dst_unused", Some("UNUSED_PAD"))
                )
            })
        } else if operation == AluOperation::VBitop3B32 {
            instruction.modifiers().len() == 1
                && instruction.modifiers()[0].name == "bitop3"
                && instruction.modifiers()[0]
                    .value
                    .as_deref()
                    .and_then(parse_u64)
                    .is_some_and(|value| value <= 255)
        } else if operation == AluOperation::VCvtF32Bf8 {
            self.architecture == AmdArchitecture::Gfx1250
                && instruction.modifiers().iter().all(|modifier| {
                    modifier.name == "byte_sel"
                        && modifier
                            .value
                            .as_deref()
                            .and_then(parse_u64)
                            .is_some_and(|byte| byte <= 3)
                })
        } else if operation == AluOperation::VCvtF32Fp8 {
            instruction.modifiers().iter().all(|modifier| {
                (self.architecture == AmdArchitecture::Gfx1250
                    && modifier.name == "byte_sel"
                    && modifier
                        .value
                        .as_deref()
                        .and_then(parse_u64)
                        .is_some_and(|byte| byte <= 3))
                    || matches!(
                        (modifier.name.as_str(), modifier.value.as_deref()),
                        ("src0_sel", Some("BYTE_0" | "BYTE_1" | "BYTE_2" | "BYTE_3"))
                            | ("dst_sel", Some("DWORD"))
                            | ("dst_unused", Some("UNUSED_PAD"))
                    )
            })
        } else if half_op {
            instruction.modifiers().iter().all(|modifier| {
                matches!(
                    (modifier.name.as_str(), modifier.value.as_deref()),
                    ("src0_sel" | "src1_sel", Some("DWORD" | "WORD_0" | "WORD_1"))
                        | ("dst_sel", Some("DWORD"))
                        | ("dst_unused", Some("UNUSED_PAD"))
                )
            })
        } else if integer_sdwa {
            instruction.modifiers().iter().all(|modifier| {
                matches!(
                    (modifier.name.as_str(), modifier.value.as_deref()),
                    (
                        "src0_sel" | "src1_sel",
                        Some(
                            "DWORD"
                                | "WORD_0"
                                | "WORD_1"
                                | "BYTE_0"
                                | "BYTE_1"
                                | "BYTE_2"
                                | "BYTE_3"
                        )
                    ) | ("dst_sel", Some("DWORD"))
                        | ("dst_unused", Some("UNUSED_PAD"))
                )
            })
        } else if clamp_f32 {
            instruction
                .modifiers()
                .iter()
                .all(|modifier| modifier.name == "clamp" && modifier.value.is_none())
        } else {
            instruction.modifiers().is_empty()
        };
        if !valid_modifiers {
            return Err(self.unsupported(wave, instruction));
        }
        let low_select = selectors(instruction, "op_sel", o.len() - 1, 0)
            .ok_or_else(|| self.unsupported(wave, instruction))?;
        let high_select = selectors(
            instruction,
            "op_sel_hi",
            o.len() - 1,
            if mix { 0 } else { 1 },
        )
        .ok_or_else(|| self.unsupported(wave, instruction))?;
        let lanes: Vec<_> = wave.active().collect();
        if matches!(
            operation,
            AluOperation::VAddF64
                | AluOperation::VMulF64
                | AluOperation::VMinF64
                | AluOperation::VMaxF64
                | AluOperation::VFmaF64
                | AluOperation::VFmacF64
                | AluOperation::VRcpF64
                | AluOperation::VSqrtF64
                | AluOperation::VCvtF64F32
                | AluOperation::VCvtF32F64
        ) {
            use super::super::scalar::{
                FloatBinOp, FloatUnOp, float_binary, float_fma, float_unary,
            };
            for lane in lanes {
                let a = if operation == AluOperation::VCvtF64F32 {
                    self.real(wave, &o[1], lane)?
                } else {
                    self.real64(wave, &o[1], lane)?
                };
                let result = match operation {
                    AluOperation::VCvtF32F64 => {
                        wave.put_value(&o[0], lane, Value::Real(a))?;
                        continue;
                    }
                    AluOperation::VCvtF64F32 => a,
                    AluOperation::VRcpF64 => {
                        if self.concrete_zero(a) {
                            return Err(EvalError::Unsupported{pc:wave.pc,what:"concrete zero reciprocal is undefined under the real-arithmetic contract".into()});
                        }
                        float_unary(&mut self.arena, FloatUnOp::Rcp, a)
                    }
                    AluOperation::VSqrtF64 => {
                        if self.concrete_sign(a) == Some(std::cmp::Ordering::Less) {
                            return Err(EvalError::Unsupported{pc:wave.pc,what:"negative concrete square root is undefined under the real-arithmetic contract".into()});
                        }
                        float_unary(&mut self.arena, FloatUnOp::Sqrt, a)
                    }
                    _ => {
                        let b = self.real64(wave, &o[2], lane)?;
                        match operation {
                            AluOperation::VFmaF64 | AluOperation::VFmacF64 => {
                                let c = self.real64(
                                    wave,
                                    &o[if operation == AluOperation::VFmacF64 {
                                        0
                                    } else {
                                        3
                                    }],
                                    lane,
                                )?;
                                float_fma(&mut self.arena, a, b, c)
                            }
                            _ => float_binary(
                                &mut self.arena,
                                match operation {
                                    AluOperation::VAddF64 => FloatBinOp::Add,
                                    AluOperation::VMulF64 => FloatBinOp::Mul,
                                    AluOperation::VMinF64 => FloatBinOp::Min,
                                    _ => FloatBinOp::Max,
                                },
                                a,
                                b,
                            ),
                        }
                    }
                };
                self.put_real64(wave, &o[0], lane, result)?;
            }
            return Ok(());
        }
        if (integer_sdwa
            && (operation != AluOperation::VAddU32 || !instruction.modifiers().is_empty()))
            || matches!(
                operation,
                AluOperation::VAddU16 | AluOperation::VSubU16 | AluOperation::VLshrrevB16
            )
        {
            for lane in lanes {
                let a = self.selected_bits(wave, &o[1], lane, instruction, 0)?;
                let b = self.selected_bits(wave, &o[2], lane, instruction, 1)?;
                let result = match operation {
                    AluOperation::VAddU16 => (a & 65535).wrapping_add(b & 65535) & 65535,
                    AluOperation::VSubU16 => (a & 65535).wrapping_sub(b & 65535) & 65535,
                    AluOperation::VMulLoU16 => (a & 65535).wrapping_mul(b & 65535) & 65535,
                    AluOperation::VLshrrevB16 => (b & 65535) >> (a & 15),
                    AluOperation::VAddU32 => a.wrapping_add(b),
                    _ => (a & 0xffffff).wrapping_mul(b & 0xffffff),
                };
                wave.put_value(&o[0], lane, Value::Integer(result))?;
            }
            return Ok(());
        }
        if let AluOperation::Packed {
            kind: kind @ (PackedKind::Mul | PackedKind::Add | PackedKind::Fma),
            ty: PackedType::F32,
        } = operation
        {
            if ["neg_lo", "neg_hi"].iter().any(|modifier_name| {
                instruction
                    .modifiers()
                    .iter()
                    .filter(|modifier| modifier.name == *modifier_name)
                    .count()
                    > 1
            }) {
                return Err(self.unsupported(wave, instruction));
            }
            let low_neg = selectors(instruction, "neg_lo", o.len() - 1, 0)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let high_neg = selectors(instruction, "neg_hi", o.len() - 1, 0)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let destination = wave.destination(&o[0])?;
            if destination.count != 2 {
                return Err(self.unsupported(wave, instruction));
            }
            for lane in lanes {
                let mut results = Vec::with_capacity(2);
                for component in 0..2 {
                    let select = if component == 0 {
                        &low_select
                    } else {
                        &high_select
                    };
                    let negate = if component == 0 { &low_neg } else { &high_neg };
                    let mut a = self.real_component(wave, &o[1], lane, select[0])?;
                    let mut b = self.real_component(wave, &o[2], lane, select[1])?;
                    if negate[0] == 1 {
                        a = self.arena.neg(a);
                    }
                    if negate[1] == 1 {
                        b = self.arena.neg(b);
                    }
                    results.push(match kind {
                        PackedKind::Mul => self.arena.mul(a, b),
                        PackedKind::Add => self.arena.add(a, b),
                        PackedKind::Fma => {
                            let mut c = self.real_component(wave, &o[3], lane, select[2])?;
                            if negate[2] == 1 {
                                c = self.arena.neg(c);
                            }
                            self.arena.fma(a, b, c)
                        }
                        _ => unreachable!("selected packed single arithmetic family"),
                    });
                }
                for (component, result) in results.into_iter().enumerate() {
                    wave.put(destination, lane, component as u16, Value::Real(result))?;
                }
            }
            return Ok(());
        }
        if matches!(operation, AluOperation::VAddNcU64 | AluOperation::VMulU64) {
            for lane in lanes {
                // Read both complete factors before either destination word,
                // including the compiler's in-place destination/src1 pair.
                let a = wave.wide(&o[1], lane)?;
                let b = wave.wide(&o[2], lane)?;
                let result = if operation == AluOperation::VMulU64 {
                    a.wrapping_mul(b)
                } else {
                    a.wrapping_add(b)
                };
                wave.put_wide(&o[0], lane, result)?;
            }
            return Ok(());
        }
        if matches!(
            operation,
            AluOperation::VMadI64I32 | AluOperation::VMadU64U32
        ) {
            let mut mask = 0;
            for lane in lanes {
                let a = wave.bits(&o[2], lane)?;
                let b = wave.bits(&o[3], lane)?;
                let addend = wave.wide(&o[4], lane)?;
                // Public CDNA4 ISA 12.11 defines {D1,D0} as the 65-bit
                // multiply-add result. For signed MAD D1 is bit64, which is
                // distinct from a signed64 overflow predicate.
                let result = if operation == AluOperation::VMadI64I32 {
                    i128::from(a as i32) * i128::from(b as i32) + i128::from(addend as i64)
                } else {
                    i128::from(a) * i128::from(b) + i128::from(addend)
                };
                wave.put_wide(&o[0], lane, result as u64)?;
                if (result >> 64) & 1 != 0 {
                    mask |= 1u64 << lane;
                }
            }
            return wave.put_wide(&o[1], 0, mask);
        }
        if let AluOperation::Compare(comparison) = operation {
            use super::super::scalar::{CmpOp, FloatType, IntType, ScalarType};
            let cmpx = comparison.writes_exec;
            let kind = comparison.ty;
            if !matches!(
                kind,
                CompareType::F32 | CompareType::I32 | CompareType::U32 | CompareType::U16
            ) && !(kind == CompareType::F16 && self.architecture == AmdArchitecture::Gfx1250)
            {
                return Err(self.unsupported(wave, instruction));
            }
            let start = if cmpx && wave.width == 32 {
                0
            } else if matches!(o.first(),Some(Operand::Register(reg)) if reg.class==RegisterClass::Special || reg.class==RegisterClass::Scalar)
            {
                1
            } else {
                0
            };
            if comparison.relation == Relation::Unordered && kind == CompareType::F32 {
                for lane in lanes {
                    self.real(wave, &o[start], lane)?;
                    self.real(wave, &o[start + 1], lane)?;
                }
                return wave.put_wide(
                    if start == 1 {
                        &o[0]
                    } else {
                        return Err(self.unsupported(wave, instruction));
                    },
                    0,
                    0,
                );
            }
            let operation = match comparison.relation {
                Relation::Eq => CmpOp::Eq,
                Relation::Ne | Relation::NotEq => CmpOp::Ne,
                Relation::Lg
                    if kind == CompareType::F32
                        && self.architecture == AmdArchitecture::Gfx950
                        && !cmpx =>
                {
                    CmpOp::Ne
                }
                Relation::Lt => CmpOp::Lt,
                Relation::Le => CmpOp::Le,
                Relation::Gt => CmpOp::Gt,
                Relation::Ge => CmpOp::Ge,
                _ => return Err(self.unsupported(wave, instruction)),
            };
            let inactive = self.arena.bool_val(false);
            let mut predicates = [inactive; 64];
            let mut concrete_mask = Some(0u64);
            for lane in lanes {
                let (ty, a, b) = if matches!(kind, CompareType::F32 | CompareType::F16) {
                    let (a, b) = if kind == CompareType::F16 {
                        (
                            self.half(wave, &o[start], lane, false)?,
                            self.half(wave, &o[start + 1], lane, false)?,
                        )
                    } else {
                        (
                            self.real(wave, &o[start], lane)?,
                            self.real(wave, &o[start + 1], lane)?,
                        )
                    };
                    (
                        ScalarType::Float(FloatType::F32),
                        self.decoded_float_argument(a),
                        self.decoded_float_argument(b),
                    )
                } else {
                    let ty = IntType {
                        bits: if kind == CompareType::U16 { 16 } else { 32 },
                        signed: kind == CompareType::I32
                            || (self.architecture == AmdArchitecture::Gfx1250
                                && kind == CompareType::U32
                                && matches!(operation, CmpOp::Eq | CmpOp::Ne)),
                    };
                    let mut a = self.integer_expression(wave, &o[start], lane, ty)?;
                    let mut b = self.integer_expression(wave, &o[start + 1], lane, ty)?;
                    if kind == CompareType::U16 {
                        // The comparison width applies to symbolic words too;
                        // high16 input bits cannot change a U16 predicate.
                        let mask = self.arena.int(65535);
                        a = self.arena.bit_and(a, mask);
                        b = self.arena.bit_and(b, mask);
                    }
                    (ScalarType::Int(ty), a, b)
                };
                let predicate = super::super::scalar::compare(&mut self.arena, ty, operation, a, b)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                predicates[lane as usize] = predicate;
                match self.arena.as_bool(predicate) {
                    Some(true) => {
                        if let Some(mask) = &mut concrete_mask {
                            *mask |= 1u64 << lane;
                        }
                    }
                    Some(false) => {}
                    None => concrete_mask = None,
                }
            }
            if cmpx {
                let mask = concrete_mask.ok_or_else(|| EvalError::Unsupported {
                    pc: wave.pc,
                    what: "symbolic comparison cannot drive EXEC or data-dependent control".into(),
                })?;
                wave.exec &= mask;
            }
            if cmpx && wave.width == 32 {
                return Ok(());
            }
            self.write_predicates(
                wave,
                if start == 1 { Some(&o[0]) } else { None },
                predicates,
            )?;
            return Ok(());
        }
        if operation == AluOperation::VReadfirstlaneB32 {
            let lane = wave.exec.trailing_zeros();
            if lane >= wave.width {
                return Err(wave.fail(None, "readfirstlane with empty EXEC"));
            }
            let value = wave.value(&o[1], lane as u8)?;
            return wave.put_value(&o[0], 0, value);
        }
        if operation == AluOperation::VReadlaneB32 {
            let lane = wave.bits(&o[2], 0)?;
            if lane >= wave.width {
                return Err(wave.fail(None, "readlane index out of range"));
            }
            let value = wave.value(&o[1], lane as u8)?;
            return wave.put_value(&o[0], 0, value);
        }
        if operation == AluOperation::VWritelaneB32 {
            let lane = wave.bits(&o[2], 0)?;
            if lane >= wave.width {
                return Err(wave.fail(None, "writelane index out of range"));
            }
            let value = wave.value(&o[1], 0)?;
            return wave.put_value(&o[0], lane as u8, value);
        }
        if matches!(
            operation,
            AluOperation::VAddCoU32
                | AluOperation::VAddcCoU32
                | AluOperation::VSubCoU32
                | AluOperation::VSubbCoU32
                | AluOperation::VSubrevCoU32
                | AluOperation::VSubbrevCoU32
        ) {
            let incoming = if o.len() > 4 && wave.exec != 0 {
                wave.wide(&o[4], 0)?
            } else {
                0
            };
            let mut mask = 0;
            for lane in lanes {
                let a = wave.bits(&o[2], lane)?;
                let b = wave.bits(&o[3], lane)?;
                let carry = ((incoming >> lane) & 1) as u32;
                let (value, bit) = match operation {
                    AluOperation::VAddCoU32 => a.overflowing_add(b),
                    AluOperation::VAddcCoU32 => {
                        let (v, c) = a.overflowing_add(b);
                        let (v, d) = v.overflowing_add(carry);
                        (v, c || d)
                    }
                    AluOperation::VSubCoU32 => a.overflowing_sub(b),
                    AluOperation::VSubrevCoU32 => b.overflowing_sub(a),
                    AluOperation::VSubbCoU32 => {
                        let (v, c) = a.overflowing_sub(b);
                        let (v, d) = v.overflowing_sub(carry);
                        (v, c || d)
                    }
                    _ => {
                        let (v, c) = b.overflowing_sub(a);
                        let (v, d) = v.overflowing_sub(carry);
                        (v, c || d)
                    }
                };
                wave.put_value(&o[0], lane, Value::Integer(value))?;
                if bit {
                    mask |= 1u64 << lane;
                }
            }
            return wave.put_wide(&o[1], 0, mask);
        }
        for lane in lanes {
            if matches!(operation, AluOperation::VAndB32 | AluOperation::VOrB32)
                && let Some(value) =
                    self.packed_half_bit_logic(wave, instruction, operation, lane)?
            {
                wave.put_value(&o[0], lane, value)?;
                continue;
            }
            if matches!(
                operation,
                AluOperation::VAndB32
                    | AluOperation::VOrB32
                    | AluOperation::VXorB32
                    | AluOperation::VBfiB32
            ) && let Some(value) = self.float_bit_logic(wave, instruction, operation, lane)?
            {
                wave.put_value(&o[0], lane, value)?;
                continue;
            }
            let value = match operation {
                AluOperation::VPermB32 => {
                    let selector = wave.bits(&o[3], lane)?;
                    let a = wave.value(&o[1], lane)?;
                    let b = wave.value(&o[2], lane)?;
                    if let (Ok(a), Ok(b)) = (a.bits(), b.bits()) {
                        let source = (a as u64) << 32 | b as u64;
                        let mut output = 0;
                        for byte in 0..4 {
                            let select = (selector >> (8 * byte)) & 255;
                            let value = match select {
                                0..=7 => (source >> (8 * select)) as u8,
                                8..=11 => {
                                    if source & (1u64 << (8 * (2 * (select - 8) + 1) + 7)) != 0 {
                                        255
                                    } else {
                                        0
                                    }
                                }
                                12 => 0,
                                _ => 255,
                            };
                            output |= (value as u32) << (8 * byte);
                        }
                        Value::Bits(output)
                    } else {
                        let mut halves = Vec::new();
                        for half in 0..2 {
                            let lo = (selector >> (16 * half)) & 255;
                            let hi = (selector >> (16 * half + 8)) & 255;
                            if lo == 12 && hi == 12 {
                                halves.push(self.arena.int(0));
                            } else {
                                if lo >= 8 || lo % 2 != 0 || hi != lo + 1 {
                                    return Err(self.unsupported(wave, instruction));
                                }
                                let source = if lo < 4 { &o[2] } else { &o[1] };
                                halves.push(self.copied_half(wave, source, lane, lo % 4 == 2)?);
                            }
                        }
                        Value::Halves(halves[0], halves[1])
                    }
                }
                AluOperation::VBfiB32
                    if self.architecture == AmdArchitecture::Gfx1250
                        && matches!(wave.bits(&o[1], lane)?, 0xffff | 0xffff0000)
                        && [&o[2], &o[3]].iter().any(|operand| {
                            matches!(
                                wave.value(operand, lane),
                                Ok(Value::Half(_) | Value::Halves(..) | Value::PartialHalves(..))
                            )
                        }) =>
                {
                    if !instruction.modifiers().is_empty()
                        || o.iter()
                            .any(|operand| matches!(operand, Operand::Modified { .. }))
                    {
                        return Err(self.unsupported(wave, instruction));
                    }
                    let mask = wave.bits(&o[1], lane)?;
                    let zero = self.arena.int(0);
                    // BFI copies encoded halves. Do not decode an untyped BF16
                    // input as IEEE F16 while transporting it into a fragment.
                    let component = |value: Option<Value>, high: bool| match value {
                        Some(Value::Half(expr)) => Some(if high { zero } else { expr }),
                        Some(Value::Halves(lo, hi)) => Some(if high { hi } else { lo }),
                        Some(Value::PartialHalves(lo, hi)) => {
                            if high {
                                hi
                            } else {
                                lo
                            }
                        }
                        Some(Value::Bits(bits) | Value::Integer(bits))
                            if ((bits >> if high { 16 } else { 0 }) & 65535) == 0 =>
                        {
                            Some(zero)
                        }
                        _ => None,
                    };
                    let insert = wave.value(&o[2], lane).ok();
                    let base = wave.value(&o[3], lane).ok();
                    let lo = component(if mask == 0xffff { insert } else { base }, false);
                    let hi = component(if mask == 0xffff { base } else { insert }, true);
                    match (lo, hi) {
                        (Some(lo), Some(hi)) => Value::Halves(lo, hi),
                        (lo, hi) => Value::PartialHalves(lo, hi),
                    }
                }
                AluOperation::VFmaF16 => {
                    let a = self.half(wave, &o[1], lane, false)?;
                    let b = self.half(wave, &o[2], lane, false)?;
                    let c = self.half(wave, &o[3], lane, false)?;
                    Value::Half(self.arena.fma(a, b, c))
                }
                AluOperation::VAlignbitB32 => {
                    let shift = wave.bits(&o[3], lane)? & 31;
                    if shift == 0 {
                        wave.value(&o[2], lane)?
                    } else if shift == 16 {
                        Value::Halves(
                            self.half(wave, &o[2], lane, true)?,
                            self.half(wave, &o[1], lane, false)?,
                        )
                    } else {
                        let a = wave.bits(&o[1], lane)? as u64;
                        let b = wave.bits(&o[2], lane)? as u64;
                        Value::Bits((((a << 32) | b) >> shift) as u32)
                    }
                }
                AluOperation::VAndB32
                    if matches!(wave.value(&o[1], lane)?, Value::PartialBits { .. })
                        || matches!(wave.value(&o[2], lane)?, Value::PartialBits { .. }) =>
                {
                    let (partial, mask) =
                        if matches!(wave.value(&o[1], lane)?, Value::PartialBits { .. }) {
                            (wave.value(&o[1], lane)?, wave.bits(&o[2], lane)?)
                        } else {
                            (wave.value(&o[2], lane)?, wave.bits(&o[1], lane)?)
                        };
                    let Value::PartialBits { bits, defined } = partial else {
                        unreachable!()
                    };
                    if mask & !defined != 0 {
                        return Err(
                            wave.fail(Some(lane), "AND observes undefined narrow result bits")
                        );
                    }
                    Value::Integer(bits & mask)
                }
                AluOperation::VLshrrevB32 | AluOperation::VLshlrevB32 => {
                    if matches!(
                        wave.value(&o[2], lane)?,
                        Value::Input(_) | Value::IntExpr(_)
                    ) {
                        let ty = super::super::scalar::IntType {
                            bits: 32,
                            signed: false,
                        };
                        let a = self.integer_expression(wave, &o[2], lane, ty)?;
                        let b = self.integer_expression(wave, &o[1], lane, ty)?;
                        let operation = if operation == AluOperation::VLshrrevB32 {
                            super::super::scalar::IntBinOp::LShr
                        } else {
                            super::super::scalar::IntBinOp::Shl
                        };
                        let expr =
                            super::super::scalar::int_binary(&mut self.arena, ty, operation, a, b)
                                .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                        wave.put_value(&o[0], lane, self.integer_result(expr, false))?;
                        continue;
                    }
                    let shift = wave.bits(&o[1], lane)? & 31;
                    let value = wave.value(&o[2], lane)?;
                    if shift == 0 {
                        value
                    } else if shift % 8 == 0
                        && matches!(
                            value,
                            Value::Byte(_) | Value::BytePair(..) | Value::Bytes(_)
                        )
                    {
                        let zero = self.arena.int(0);
                        let bytes = match value {
                            Value::Byte(expr) => [expr, zero, zero, zero],
                            Value::BytePair(lo, hi) => [lo, hi, zero, zero],
                            Value::Bytes(bytes) => bytes,
                            _ => unreachable!(),
                        };
                        let mut output = [zero; 4];
                        let count = (shift / 8) as usize;
                        if operation == AluOperation::VLshrrevB32 {
                            output[..4 - count].copy_from_slice(&bytes[count..]);
                        } else {
                            output[count..].copy_from_slice(&bytes[..4 - count]);
                        }
                        Value::Bytes(output)
                    } else if shift == 16
                        && matches!(
                            value,
                            Value::Half(_) | Value::Halves(..) | Value::PartialHalves(..)
                        )
                    {
                        if operation == AluOperation::VLshrrevB32 {
                            Value::Half(self.half(wave, &o[2], lane, true)?)
                        } else {
                            let zero = self.arena.int(0);
                            Value::Halves(zero, self.half(wave, &o[2], lane, false)?)
                        }
                    } else {
                        let bits = value.bits().map_err(|e| wave.fail(Some(lane), e))?;
                        Value::Integer(if operation == AluOperation::VLshrrevB32 {
                            bits >> shift
                        } else {
                            bits.wrapping_shl(shift)
                        })
                    }
                }
                AluOperation::VCvtPkF32Fp8 => {
                    // Default encoding uses source bytes0/1. Both inputs are
                    // snapshotted before either destination register changes.
                    let low = self.fp8(wave, &o[1], lane, 0)?;
                    let high = self.fp8(wave, &o[1], lane, 1)?;
                    let destination = wave.destination(&o[0])?;
                    wave.put(destination, lane, 0, Value::Real(low))?;
                    wave.put(destination, lane, 1, Value::Real(high))?;
                    continue;
                }
                AluOperation::VCvtF32Bf8 => {
                    // No symbolic E5M2 storage interpretation is inferred.
                    if self.architecture != AmdArchitecture::Gfx1250
                        || !matches!(
                            instruction.source().encoding,
                            Encoding::Default | Encoding::E32 | Encoding::E64
                        )
                    {
                        return Err(self.unsupported(wave, instruction));
                    }
                    let byte = instruction
                        .modifiers()
                        .iter()
                        .find(|modifier| modifier.name == "byte_sel")
                        .and_then(|modifier| modifier.value.as_deref())
                        .and_then(parse_u64)
                        .unwrap_or(0) as u32;
                    let bits = wave
                        .value(&o[1], lane)?
                        .selected_bits(byte * 8, 8)
                        .map_err(|_| EvalError::Unsupported {
                            pc: wave.pc,
                            what: "symbolic E5M2 decoding is not modeled".into(),
                        })?;
                    let decoded = super::super::matrix::decode_bits(
                        super::super::matrix::InputKind::Fp8E5m2,
                        bits,
                    )
                    .map_err(|_| {
                        wave.fail(
                            Some(lane),
                            "OCP E5M2 NaN or infinity is outside the real-number model",
                        )
                    })?;
                    Value::Real(
                        self.arena
                            .float_from_f64(decoded)
                            .expect("finite E5M2 value"),
                    )
                }
                AluOperation::VCvtF32Fp8 => {
                    let byte = instruction
                        .modifiers()
                        .iter()
                        .find(|modifier| modifier.name == "src0_sel")
                        .and_then(|modifier| modifier.value.as_deref())
                        .and_then(|value| value.strip_prefix("BYTE_"))
                        .and_then(|value| value.parse::<usize>().ok())
                        .or_else(|| {
                            instruction
                                .modifiers()
                                .iter()
                                .find(|modifier| modifier.name == "byte_sel")
                                .and_then(|modifier| modifier.value.as_deref())
                                .and_then(parse_u64)
                                .and_then(|byte| usize::try_from(byte).ok())
                        })
                        .unwrap_or(0);
                    Value::Real(self.fp8(wave, &o[1], lane, byte)?)
                }
                AluOperation::VFmaMixloF16
                | AluOperation::VFmaMixhiF16
                | AluOperation::VFmaMixF32 => {
                    let mut arguments = Vec::with_capacity(3);
                    for index in 0..3 {
                        arguments.push(if high_select[index] != 0 {
                            self.half(wave, &o[index + 1], lane, low_select[index] != 0)?
                        } else {
                            self.real(wave, &o[index + 1], lane)?
                        });
                    }
                    let result = self.arena.fma(arguments[0], arguments[1], arguments[2]);
                    if operation == AluOperation::VFmaMixF32 {
                        wave.put_value(&o[0], lane, Value::Real(result))?;
                        continue;
                    }
                    let old = wave.value(&o[0], lane).ok();
                    let old_half = |high| match old {
                        Some(Value::Halves(lo, hi)) => Some(if high { hi } else { lo }),
                        Some(Value::Half(expr)) if !high => Some(expr),
                        Some(Value::PartialHalves(lo, hi)) => {
                            if high {
                                hi
                            } else {
                                lo
                            }
                        }
                        _ => None,
                    };
                    let (lo, hi) = if operation == AluOperation::VFmaMixloF16 {
                        (Some(result), old_half(true))
                    } else {
                        (old_half(false), Some(result))
                    };
                    if let (Some(lo), Some(hi)) = (lo, hi) {
                        Value::Halves(lo, hi)
                    } else {
                        Value::PartialHalves(lo, hi)
                    }
                }
                AluOperation::VMovB64 => {
                    let destination = wave.destination(&o[0])?;
                    if let Operand::Register(source) = o[1] {
                        if source.count != 2 {
                            return Err(self.unsupported(wave, instruction));
                        }
                        let lo = wave.reg(source, lane, 0)?;
                        let hi = wave.reg(source, lane, 1)?;
                        wave.put(destination, lane, 0, lo)?;
                        wave.put(destination, lane, 1, hi)?;
                    } else {
                        let value = wave.wide(&o[1], lane)?;
                        wave.put_wide(&o[0], lane, value)?;
                    }
                    continue;
                }
                AluOperation::VCvtF16I16 => {
                    Value::Half(self.signed16_to_half(wave, &o[1], lane, instruction)?)
                }
                AluOperation::VCvtF32F16 => {
                    Value::Real(self.half(wave, &o[1], lane, half_select_high)?)
                }
                AluOperation::VCvtF16F32 => Value::Half(self.real(wave, &o[1], lane)?),
                AluOperation::VCvtPkrtzF16F32 | AluOperation::VCvtPkF16F32 => {
                    Value::Halves(self.real(wave, &o[1], lane)?, self.real(wave, &o[2], lane)?)
                }
                AluOperation::VPackB32F16 => Value::Halves(
                    self.copied_half(wave, &o[1], lane, false)?,
                    self.copied_half(wave, &o[2], lane, false)?,
                ),
                AluOperation::Float {
                    domain: AluDomain::Vector,
                    kind:
                        kind @ (FloatKind::Add
                        | FloatKind::Sub
                        | FloatKind::Mul
                        | FloatKind::Max
                        | FloatKind::Min),
                    ty: FloatType::F16,
                } => {
                    let a = self.half(wave, &o[1], lane, half_select_high)?;
                    let b = self.half(wave, &o[2], lane, half_select_high1)?;
                    Value::Half(self.vector_float_binary(kind, a, b))
                }
                AluOperation::VFmacF16 => {
                    let a = self.half(wave, &o[1], lane, false)?;
                    let b = self.half(wave, &o[2], lane, false)?;
                    let c = self.half(wave, &o[0], lane, false)?;
                    Value::Half(self.arena.fma(a, b, c))
                }
                AluOperation::VMax3F16 => {
                    let a = self.half(wave, &o[1], lane, false)?;
                    let b = self.half(wave, &o[2], lane, false)?;
                    let c = self.half(wave, &o[3], lane, false)?;
                    let partial = self.arena.max(a, b);
                    Value::Half(self.arena.max(partial, c))
                }
                AluOperation::Packed {
                    kind:
                        kind @ (PackedKind::Add
                        | PackedKind::Mul
                        | PackedKind::Max
                        | PackedKind::Min
                        | PackedKind::Fma),
                    ty: PackedType::F16,
                } => {
                    let mut pair = Vec::with_capacity(2);
                    for high in [false, true] {
                        let select = if high { &high_select } else { &low_select };
                        let a = self.half(wave, &o[1], lane, select[0] != 0)?;
                        let b = self.half(wave, &o[2], lane, select[1] != 0)?;
                        pair.push(match kind {
                            PackedKind::Add => self.arena.add(a, b),
                            PackedKind::Mul => self.arena.mul(a, b),
                            PackedKind::Max => self.arena.max(a, b),
                            PackedKind::Min => self.arena.min(a, b),
                            PackedKind::Fma => {
                                let c = self.half(wave, &o[3], lane, select[2] != 0)?;
                                self.arena.fma(a, b, c)
                            }
                            _ => unreachable!("selected packed half arithmetic family"),
                        });
                    }
                    Value::Halves(pair[0], pair[1])
                }
                AluOperation::VMovB32
                | AluOperation::VAccvgprReadB32
                | AluOperation::VAccvgprWriteB32
                | AluOperation::VAccvgprMovB32 => self.modified_value(wave, &o[1], lane)?,
                AluOperation::VCndmaskB32 => {
                    let condition = self.predicate_condition(wave, o.get(3), lane)?;
                    self.select_word(wave, condition, &o[2], &o[1], lane, saturate)?
                }
                AluOperation::VLshlrevB64
                | AluOperation::VLshrrevB64
                | AluOperation::VAshrrevI64 => {
                    let shift = wave.bits(&o[1], lane)? & 63;
                    let destination = wave.destination(&o[0])?;
                    if operation == AluOperation::VAshrrevI64 {
                        // CDNA4 V_ASHRREV_I64: D0.i64 = S1.i64 >> S0[5:0].
                        // The signed consumer fixes the output interpretation;
                        // store width alone never supplies signedness.
                        let value = (wave.wide(&o[2], lane)? as i64) >> shift;
                        let expr = self.arena.int(value);
                        wave.put(
                            destination,
                            lane,
                            0,
                            Value::WidePart {
                                expr,
                                high: false,
                                kind: WideKind::Integer,
                            },
                        )?;
                        wave.put(
                            destination,
                            lane,
                            1,
                            Value::WidePart {
                                expr,
                                high: true,
                                kind: WideKind::Integer,
                            },
                        )?;
                        continue;
                    }
                    if let Ok(bits) = wave.wide(&o[2], lane) {
                        let result = if operation == AluOperation::VLshlrevB64 {
                            bits.wrapping_shl(shift)
                        } else {
                            bits >> shift
                        };
                        wave.put(destination, lane, 0, Value::Integer(result as u32))?;
                        wave.put(destination, lane, 1, Value::Integer((result >> 32) as u32))?;
                    } else if matches!(shift, 0 | 32) {
                        let source = wave.destination(&o[2])?;
                        let low = wave.reg(source, lane, 0)?;
                        let high = wave.reg(source, lane, 1)?;
                        let (low, high) = if shift == 0 {
                            (low, high)
                        } else if operation == AluOperation::VLshlrevB64 {
                            (Value::Bits(0), low)
                        } else {
                            (high, Value::Bits(0))
                        };
                        wave.put(destination, lane, 0, low)?;
                        wave.put(destination, lane, 1, high)?;
                    } else {
                        return Err(wave.fail(
                            Some(lane),
                            "non-word symbolic64-bit shift requires exact encoded data bits",
                        ));
                    }
                    continue;
                }
                AluOperation::VLshlAddU64 => {
                    if matches!(
                        self.architecture,
                        AmdArchitecture::Gfx942 | AmdArchitecture::Gfx950
                    ) && instruction.source().encoding == Encoding::Default
                        && instruction.modifiers().is_empty()
                        && let [
                            Operand::Register(destination),
                            Operand::Register(base),
                            Operand::Integer(0),
                            Operand::Register(addend),
                        ] = o
                        && destination.class == RegisterClass::Vector
                        && base.class == RegisterClass::Scalar
                        && addend.class == RegisterClass::Vector
                        && [destination, base, addend]
                            .iter()
                            .all(|register| register.count == 2 && register.special.is_none())
                        && wave.reg(*base, lane, 1)? == Value::SharedApertureHi
                    {
                        let bits = |register, component| {
                            wave.reg(register, lane, component)?
                                .bits()
                                .map_err(|error| wave.fail(Some(lane), error))
                        };
                        // Snapshot both addend words before an aliased write.
                        // With exact shift zero and no low32 carry, adding
                        // (offset, 0) leaves every possible aperture high word
                        // unchanged. The tag never acquires numeric bits.
                        let low = bits(*base, 0)?;
                        let addend_low = bits(*addend, 0)?;
                        let addend_high = bits(*addend, 1)?;
                        if addend_high != 0 {
                            return Err(wave.fail(
                                Some(lane),
                                "legacy shared-aperture addend requires a zero high word",
                            ));
                        }
                        let offset = low.checked_add(addend_low).ok_or_else(|| {
                            wave.fail(Some(lane), "legacy shared-aperture offset overflows low32")
                        })?;
                        wave.put(*destination, lane, 0, Value::Bits(offset))?;
                        wave.put(*destination, lane, 1, Value::SharedApertureHi)?;
                        continue;
                    }
                    let base = wave.wide(&o[1], lane)?;
                    let shift = wave.bits(&o[2], lane)? & 63;
                    if self.architecture == AmdArchitecture::Gfx1250
                        && let Operand::Register(addend) = &o[3]
                        && addend.count == 2
                        && wave.reg(*addend, lane, 1)? == Value::SharedApertureHi
                    {
                        let low = wave
                            .reg(*addend, lane, 0)?
                            .bits()
                            .map_err(|error| wave.fail(Some(lane), error))?;
                        // Preserve the opaque aperture, rather than assigning
                        // it numeric bits. Only a provably non-wrapping low32
                        // offset is supported by this exact address idiom.
                        let offset = base
                            .checked_mul(1u64 << shift)
                            .and_then(|index| index.checked_add(u64::from(low)))
                            .filter(|offset| *offset <= u64::from(u32::MAX))
                            .ok_or_else(|| {
                                wave.fail(Some(lane), "scaled offset escapes the shared aperture")
                            })?;
                        let destination = wave.destination(&o[0])?;
                        wave.put(destination, lane, 0, Value::Bits(offset as u32))?;
                        wave.put(destination, lane, 1, Value::SharedApertureHi)?;
                        continue;
                    }
                    let addend = wave.wide(&o[3], lane)?;
                    wave.put_wide(&o[0], lane, base.wrapping_shl(shift).wrapping_add(addend))?;
                    continue;
                }
                AluOperation::Float {
                    domain: AluDomain::Vector,
                    kind:
                        kind @ (FloatKind::Add
                        | FloatKind::Sub
                        | FloatKind::SubReverse
                        | FloatKind::Mul
                        | FloatKind::Max
                        | FloatKind::Min),
                    ty: FloatType::F32,
                } => {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    Value::Real(self.vector_float_binary(kind, a, b))
                }
                AluOperation::VMax3NumF32 => {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    let c = self.real(wave, &o[3], lane)?;
                    let ab = self.arena.max(a, b);
                    Value::Real(self.arena.max(ab, c))
                }
                AluOperation::Fused {
                    kind:
                        kind @ (FusedKind::Fma
                        | FusedKind::MultiplyAdd
                        | FusedKind::Accumulate
                        | FusedKind::LiteralAdd
                        | FusedKind::LiteralMultiply),
                    ty: FloatType::F32,
                } => {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    let c = self.real(
                        wave,
                        &o[if kind == FusedKind::Accumulate { 0 } else { 3 }],
                        lane,
                    )?;
                    Value::Real(self.arena.fma(a, b, c))
                }
                AluOperation::VRcpF32
                | AluOperation::VSqrtF32
                | AluOperation::VRsqF32
                | AluOperation::VExpF32
                | AluOperation::VLogF32 => {
                    let a = self.real(wave, &o[1], lane)?;
                    if matches!(operation, AluOperation::VRcpF32 | AluOperation::VRsqF32)
                        && self.concrete_zero(a)
                    {
                        return Err(EvalError::Unsupported{pc:wave.pc,what:"concrete zero reciprocal/rsqrt is undefined under the real-arithmetic contract".into()});
                    }
                    let sign = self.concrete_sign(a);
                    if (matches!(operation, AluOperation::VSqrtF32 | AluOperation::VRsqF32)
                        && sign == Some(std::cmp::Ordering::Less))
                        || (operation == AluOperation::VLogF32
                            && matches!(
                                sign,
                                Some(std::cmp::Ordering::Less | std::cmp::Ordering::Equal)
                            ))
                    {
                        return Err(EvalError::Unsupported {
                            pc: wave.pc,
                            what: format!(
                                "concrete operand outside {} domain is undefined under the real-arithmetic contract",
                                operation.name()
                            ),
                        });
                    }
                    let result = match operation {
                        AluOperation::VRcpF32 => self.arena.rcp(a),
                        AluOperation::VSqrtF32 => self.arena.sqrt(a),
                        AluOperation::VRsqF32 => {
                            let root = self.arena.sqrt(a);
                            self.arena.rcp(root)
                        }
                        AluOperation::VExpF32 => self.exp2(a),
                        _ => {
                            let ln2 = self.ln2_constant();
                            let log = self.arena.log(a);
                            self.arena.div(log, ln2)
                        }
                    };
                    Value::Real(result)
                }
                AluOperation::VCvtF32Ubyte0
                | AluOperation::VCvtF32Ubyte2
                | AluOperation::VCvtF32Ubyte3 => {
                    let byte = match operation {
                        AluOperation::VCvtF32Ubyte0 => 0,
                        AluOperation::VCvtF32Ubyte2 => 2,
                        _ => 3,
                    };
                    let value = wave.value(&o[1], lane)?;
                    let expr = if let Some(bytes) = self.encoded_bytes(value) {
                        let selected = bytes[byte].ok_or_else(|| {
                            wave.fail(
                                Some(lane),
                                "selected undefined upper byte from true16 result",
                            )
                        })?;
                        self.claim_byte_format(wave, selected, ByteFormat::UnsignedU8)?;
                        selected
                    } else {
                        let byte = value
                            .selected_bits(byte as u32 * 8, 8)
                            .map_err(|error| wave.fail(Some(lane), error))?;
                        self.arena.int(byte as i64)
                    };
                    Value::Real(expr)
                }
                AluOperation::VCvtF32U32 | AluOperation::VCvtF32I32 => {
                    if operation == AluOperation::VCvtF32U32
                        && matches!(
                            wave.value(&o[1], lane)?,
                            Value::NarrowInt { signed: true, .. }
                        )
                    {
                        return Err(EvalError::Unsupported{pc:wave.pc,what:"signed narrow data reinterpreted as unsigned32 before float conversion".into()});
                    }
                    let ty = super::super::scalar::IntType {
                        bits: 32,
                        signed: operation == AluOperation::VCvtF32I32,
                    };
                    let expr = self.integer_expression(wave, &o[1], lane, ty)?;
                    Value::Real(if let Some(value) = self.arena.as_int_const(expr) {
                        let value = super::super::scalar::canonical_int(value, ty)
                            .map_err(|e| wave.fail(Some(lane), e))?;
                        self.arena.int(value)
                    } else {
                        expr
                    })
                }
                _ => {
                    if operation == AluOperation::VOrB32 {
                        let a = wave.value(&o[1], lane)?;
                        let b = wave.value(&o[2], lane)?;
                        if matches!(
                            a,
                            Value::Byte(_)
                                | Value::BytePair(..)
                                | Value::PartialBytePair(..)
                                | Value::Bytes(_)
                        ) || matches!(
                            b,
                            Value::Byte(_)
                                | Value::BytePair(..)
                                | Value::PartialBytePair(..)
                                | Value::Bytes(_)
                        ) {
                            if let (Some(a), Some(b)) =
                                (self.encoded_bytes(a), self.encoded_bytes(b))
                            {
                                let mut bytes = [None; 4];
                                for i in 0..4 {
                                    bytes[i] = match (a[i], b[i]) {
                                        (Some(x), other)
                                            if self.arena.as_int_const(x) == Some(0) =>
                                        {
                                            other
                                        }
                                        (other, Some(y))
                                            if self.arena.as_int_const(y) == Some(0) =>
                                        {
                                            other
                                        }
                                        (Some(x), Some(y)) if x == y => Some(x),
                                        (Some(x), Some(y)) => match (
                                            self.arena.as_int_const(x),
                                            self.arena.as_int_const(y),
                                        ) {
                                            (Some(x), Some(y)) => {
                                                Some(self.arena.int((x | y) & 255))
                                            }
                                            _ => None,
                                        },
                                        _ => None,
                                    };
                                }
                                if let [Some(lo), Some(hi), upper0, upper1] = bytes {
                                    let value = if let (Some(c), Some(d)) = (upper0, upper1) {
                                        Value::Bytes([lo, hi, c, d])
                                    } else {
                                        Value::PartialBytePair(lo, hi)
                                    };
                                    wave.put_value(&o[0], lane, value)?;
                                    continue;
                                }
                            }
                            return Err(self.unsupported(wave, instruction));
                        }
                        let transport = |value: Value| {
                            matches!(
                                value,
                                Value::Input(_)
                                    | Value::Real(_)
                                    | Value::IntExpr(_)
                                    | Value::WidePart { .. }
                                    | Value::Half(_)
                                    | Value::Halves(..)
                                    | Value::PartialHalves(..)
                                    | Value::Byte(_)
                                    | Value::BytePair(..)
                                    | Value::Bytes(_)
                                    | Value::NarrowInt { .. }
                            )
                        };
                        let moved = if b.bits() == Ok(0) && transport(a) {
                            Some(a)
                        } else if a.bits() == Ok(0) && transport(b) {
                            Some(b)
                        } else {
                            None
                        };
                        if let Some(value) = moved {
                            wave.put_value(&o[0], lane, value)?;
                            continue;
                        }
                    }
                    if let Some((ty, integer_operation, reverse)) = vector_integer_binary(operation)
                    {
                        let a = self.integer_expression(
                            wave,
                            &o[if reverse { 2 } else { 1 }],
                            lane,
                            ty,
                        )?;
                        let b = self.integer_expression(
                            wave,
                            &o[if reverse { 1 } else { 2 }],
                            lane,
                            ty,
                        )?;
                        let result = super::super::scalar::int_binary(
                            &mut self.arena,
                            ty,
                            integer_operation,
                            a,
                            b,
                        )
                        .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                        let mut value = self.integer_result(result, ty.signed);
                        // A concrete ASHR31 into the adjacent odd word is an
                        // exact signed-widening witness. Keep its low source
                        // unchanged; extraction rechecks that word so later
                        // clobbers cannot resurrect the old mathematical value.
                        if self.architecture == AmdArchitecture::Gfx1250
                            && operation == AluOperation::VAshrrevI32
                            && wave.bits(&o[1], lane).is_ok_and(|count| count & 31 == 31)
                            && let (Operand::Register(dest), Operand::Register(source)) =
                                (&o[0], &o[2])
                            && dest.class == RegisterClass::Vector
                            && source.class == RegisterClass::Vector
                            && dest.count == 1
                            && source.count == 1
                            && dest.index % 2 == 1
                            && source.index + 1 == dest.index
                            && let Ok(bits) = wave.bits(&o[2], lane)
                        {
                            value = Value::WidePart {
                                expr: self.arena.int(bits as i32 as i64),
                                high: true,
                                kind: WideKind::Integer,
                            };
                        }
                        wave.put_value(&o[0], lane, value)?;
                        continue;
                    }
                    let a = wave.bits(&o[1], lane)?;
                    let b = if o.len() > 2 {
                        wave.bits(&o[2], lane)?
                    } else {
                        0
                    };
                    let value = match operation {
                        AluOperation::VAddU32 => a.wrapping_add(b),
                        AluOperation::VSubU32 => a.wrapping_sub(b),
                        AluOperation::VSubrevU32 => b.wrapping_sub(a),
                        AluOperation::VMulLoU32 | AluOperation::VMulLoI32 => a.wrapping_mul(b),
                        AluOperation::VMulHiU32 => ((a as u64 * b as u64) >> 32) as u32,
                        AluOperation::VMulU32U24 => (a & 0xffffff).wrapping_mul(b & 0xffffff),
                        AluOperation::VAndB32 => a & b,
                        AluOperation::VOrB32 => a | b,
                        AluOperation::VXorB32 => a ^ b,
                        AluOperation::VNotB32 => !a,
                        AluOperation::VBfrevB32 => a.reverse_bits(),
                        AluOperation::VLshlrevB32 => b.wrapping_shl(a & 31),
                        AluOperation::VLshrrevB32 => b.wrapping_shr(a & 31),
                        AluOperation::VAshrrevI32 => ((b as i32) >> (a & 31)) as u32,
                        AluOperation::VMinU32 => a.min(b),
                        AluOperation::VMaxU32 => a.max(b),
                        AluOperation::VMinI32 => (a as i32).min(b as i32) as u32,
                        AluOperation::VMaxI32 => (a as i32).max(b as i32) as u32,
                        AluOperation::VMadU32 => {
                            a.wrapping_mul(b).wrapping_add(wave.bits(&o[3], lane)?)
                        }
                        AluOperation::VMadU32U24 => (a & 0xffffff)
                            .wrapping_mul(b & 0xffffff)
                            .wrapping_add(wave.bits(&o[3], lane)?),
                        AluOperation::VLshlAddU32 => {
                            a.wrapping_shl(b & 31).wrapping_add(wave.bits(&o[3], lane)?)
                        }
                        AluOperation::VAddLshlU32 => {
                            a.wrapping_add(b).wrapping_shl(wave.bits(&o[3], lane)? & 31)
                        }
                        AluOperation::VLshlOrB32 => {
                            a.wrapping_shl(b & 31) | wave.bits(&o[3], lane)?
                        }
                        AluOperation::VOr3B32 => a | b | wave.bits(&o[3], lane)?,
                        AluOperation::VAndOrB32 => (a & b) | wave.bits(&o[3], lane)?,
                        AluOperation::VAdd3U32 => {
                            a.wrapping_add(b).wrapping_add(wave.bits(&o[3], lane)?)
                        }
                        AluOperation::VXadU32 => (a ^ b).wrapping_add(wave.bits(&o[3], lane)?),
                        AluOperation::VBfeU32 | AluOperation::VBfeI32 => {
                            super::super::scalar::bfe32(
                                a,
                                b,
                                wave.bits(&o[3], lane)?,
                                operation == AluOperation::VBfeI32,
                            )
                        }
                        AluOperation::VBfiB32 => {
                            super::super::scalar::bfi32(a, b, wave.bits(&o[3], lane)?)
                        }
                        AluOperation::VBitop3B32 => {
                            let c = wave.bits(&o[3], lane)?;
                            let table = instruction.modifiers()[0]
                                .value
                                .as_deref()
                                .and_then(parse_u64)
                                .unwrap() as u8;
                            let mut result = 0;
                            for index in 0..8 {
                                if table & (1 << index) != 0 {
                                    result |= (if index & 4 != 0 { a } else { !a })
                                        & (if index & 2 != 0 { b } else { !b })
                                        & (if index & 1 != 0 { c } else { !c });
                                }
                            }
                            result
                        }
                        AluOperation::VMbcntLoU32B32 => {
                            let below = if lane >= 32 {
                                u32::MAX
                            } else if lane == 0 {
                                0
                            } else {
                                (1u32 << lane) - 1
                            };
                            (a & below).count_ones().wrapping_add(b)
                        }
                        AluOperation::VMbcntHiU32B32 => {
                            let below = if lane <= 32 {
                                0
                            } else {
                                (1u32 << (lane - 32)) - 1
                            };
                            (a & below).count_ones().wrapping_add(b)
                        }
                        _ => return Err(self.unsupported(wave, instruction)),
                    };
                    if matches!(
                        operation,
                        AluOperation::VMulLoI32
                            | AluOperation::VMinI32
                            | AluOperation::VMaxI32
                            | AluOperation::VAshrrevI32
                            | AluOperation::VBfeI32
                    ) {
                        Value::SignedInteger(value as i32)
                    } else {
                        Value::Integer(value)
                    }
                }
            };
            let value = if saturate {
                let decoded = self.real_value(wave, value, lane)?;
                Value::Real(super::super::scalar::clamp(
                    &mut self.arena,
                    super::super::scalar::Clamp::Sat,
                    decoded,
                ))
            } else {
                value
            };
            let value = if self.architecture == AmdArchitecture::Gfx1250
                && matches!(
                    operation,
                    AluOperation::VAddF16
                        | AluOperation::VSubF16
                        | AluOperation::VMulF16
                        | AluOperation::VMaxF16
                        | AluOperation::VMinF16
                        | AluOperation::VCvtF16F32
                        | AluOperation::VFmacF16
                ) {
                let Value::Half(low) = value else {
                    return Err(self.unsupported(wave, instruction));
                };
                // The hardware preserves the old upper half. If that payload
                // is not representable by the selected packed-data model,
                // retain it as undefined rather than inventing zero bits.
                let high = self.half(wave, &o[0], lane, true).ok();
                Value::PartialHalves(Some(low), high)
            } else {
                value
            };
            wave.put_value(&o[0], lane, value)?;
        }
        Ok(())
    }
    fn vector_float_binary(&mut self, kind: FloatKind, a: ExprId, b: ExprId) -> ExprId {
        match kind {
            FloatKind::Add => self.arena.add(a, b),
            FloatKind::Sub => self.arena.sub(a, b),
            FloatKind::SubReverse => self.arena.sub(b, a),
            FloatKind::Mul => self.arena.mul(a, b),
            FloatKind::Max => self.arena.max(a, b),
            FloatKind::Min => self.arena.min(a, b),
            _ => unreachable!("selected vector binary float family"),
        }
    }

    pub(super) fn packed_half_bit_logic(
        &mut self,
        wave: &Wave,
        instruction: &Instruction,
        operation: AluOperation,
        lane: u8,
    ) -> Result<Option<Value>, EvalError> {
        if !instruction.modifiers().is_empty()
            || instruction
                .operands()
                .iter()
                .any(|op| matches!(op, Operand::Modified { .. }))
        {
            return Ok(None);
        }
        let o = instruction.operands();
        let a = wave.value(&o[1], lane)?;
        let b = wave.value(&o[2], lane)?;
        let result = if operation == AluOperation::VAndB32 {
            let (mask, source) = if let Ok(mask) = a.bits() {
                (mask, b)
            } else if let Ok(mask) = b.bits() {
                (mask, a)
            } else {
                return Ok(None);
            };
            match mask {
                0xffff => source.mask_low16(),
                0xffff0000 => source.mask_high16(),
                _ => return Ok(None),
            }
        } else {
            a.or_disjoint_halves(b)
        };
        result.map_err(|error| wave.fail(Some(lane), error))
    }
    pub(super) fn float_bit_logic(
        &mut self,
        wave: &Wave,
        instruction: &Instruction,
        operation: AluOperation,
        lane: u8,
    ) -> Result<Option<Value>, EvalError> {
        if !matches!(
            self.architecture,
            AmdArchitecture::Gfx950 | AmdArchitecture::Gfx1250
        ) || !instruction.modifiers().is_empty()
            || instruction
                .operands()
                .iter()
                .any(|op| matches!(op, Operand::Modified { .. }))
        {
            return Ok(None);
        }
        let o = instruction.operands();
        if matches!(
            operation,
            AluOperation::VAndB32 | AluOperation::VOrB32 | AluOperation::VXorB32
        ) {
            let mask = if operation == AluOperation::VAndB32 {
                0x7fff_ffff
            } else {
                0x8000_0000
            };
            let a = wave.value(&o[1], lane)?;
            let b = wave.value(&o[2], lane)?;
            let source = if super::super::float_bits::exact_word(&self.arena, a) == Some(mask) {
                b
            } else if super::super::float_bits::exact_word(&self.arena, b) == Some(mask) {
                a
            } else {
                return Ok(None);
            };
            let transform = |arena: &mut ExprArena, decoded| match operation {
                AluOperation::VAndB32 => arena.abs(decoded),
                AluOperation::VOrB32 => {
                    let magnitude = arena.abs(decoded);
                    arena.neg(magnitude)
                }
                _ => arena.neg(decoded),
            };
            let is_float_input = |expr| match self.arena.node(expr) {
                ExprNode::InputElement { array, .. } => {
                    self.word_formats.get(array) == Some(&WordFormat::Float32)
                }
                _ => false,
            };
            let decoded = match source {
                Value::Real(expr) => Some(expr),
                Value::Input(expr) if is_float_input(expr) => Some(expr),
                Value::IntExpr(expr) => self.float_bit_patterns.get(&expr).and_then(|pattern| {
                    (!pattern.input_words.is_empty()
                        && pattern.input_words.iter().copied().all(is_float_input))
                    .then_some(pattern.decoded)
                }),
                _ => None,
            };
            if let Some(decoded) = decoded {
                return Ok(Some(Value::Real(transform(&mut self.arena, decoded))));
            }
            // Untyped inputs retain raw words until a numeric consumer fixes
            // their format. Concrete integer sources keep the integer path.
            if !matches!(source, Value::Input(_) | Value::IntExpr(_)) {
                return Ok(None);
            }
            if let Some((source, mut pattern)) = self
                .float_bit_source(source)
                .map_err(|e| wave.fail(Some(lane), e))?
            {
                let mask = self.arena.int(i64::from(mask));
                let raw = match operation {
                    AluOperation::VAndB32 => self.arena.bit_and(source, mask),
                    AluOperation::VOrB32 => self.arena.bit_or(source, mask),
                    _ => self.arena.bit_xor(source, mask),
                };
                pattern.decoded = transform(&mut self.arena, pattern.decoded);
                self.float_bit_patterns.insert(raw, pattern);
                return Ok(Some(Value::IntExpr(raw)));
            }
        }
        if operation == AluOperation::VBfiB32 && self.architecture == AmdArchitecture::Gfx1250 {
            // Halfword copies have their own tagged path, which preserves an
            // unavailable unselected half. Do not eagerly demand both sources
            // merely to decide whether this is an F32 sign/magnitude idiom.
            if wave
                .value(&o[1], lane)?
                .bits()
                .is_ok_and(|mask| matches!(mask, 0xffff | 0xffff0000))
            {
                return Ok(None);
            }
            let values = [
                wave.value(&o[1], lane)?,
                wave.value(&o[2], lane)?,
                wave.value(&o[3], lane)?,
            ];
            let words = values.map(|v| super::super::float_bits::exact_word(&self.arena, v));
            if let [Some(mask), Some(insert), Some(base)] = words {
                return Ok(Some(Value::Bits(super::super::scalar::bfi32(
                    mask, insert, base,
                ))));
            }
            if let Some(mask @ (0x7fff_ffff | 0x8000_0000)) = words[0] {
                let insert = self
                    .float_bit_source(values[1])
                    .map_err(|e| wave.fail(Some(lane), e))?;
                let base = self
                    .float_bit_source(values[2])
                    .map_err(|e| wave.fail(Some(lane), e))?;
                if let (Some((insert, mut insert_pattern)), Some((base, base_pattern))) =
                    (insert, base)
                {
                    let constant = self.arena.int(i64::from(mask));
                    let inverted = self.arena.int(i64::from(!mask));
                    let left = self.arena.bit_and(insert, constant);
                    let right = self.arena.bit_and(base, inverted);
                    let raw = self.arena.bit_or(left, right);
                    let (sign, magnitude) = if mask == 0x7fff_ffff {
                        (base_pattern.decoded, insert_pattern.decoded)
                    } else {
                        (insert_pattern.decoded, base_pattern.decoded)
                    };
                    insert_pattern.decoded =
                        super::super::scalar::copysign(&mut self.arena, sign, magnitude);
                    insert_pattern.input_words.extend(base_pattern.input_words);
                    self.float_bit_patterns.insert(raw, insert_pattern);
                    return Ok(Some(Value::IntExpr(raw)));
                }
            }
        }
        Ok(None)
    }
}

/// Select only the existing symbolic word operations; narrower, carry-producing,
/// and other native forms retain their individual readiness and encoded-bit paths.
fn vector_integer_binary(
    operation: AluOperation,
) -> Option<(
    super::super::scalar::IntType,
    super::super::scalar::IntBinOp,
    bool,
)> {
    use super::super::scalar::{IntBinOp, IntType};
    let (operation, signed, reverse) = match operation {
        AluOperation::Integer {
            domain: AluDomain::Vector,
            kind,
            ty:
                IntegerType {
                    width: BitWidth::B32,
                    signed,
                },
            source_bits: 32,
            form,
        } => {
            let operation = match (kind, form, signed) {
                (IntegerKind::Add, IntegerForm::Plain, false) => IntBinOp::Add,
                (IntegerKind::Sub, IntegerForm::Plain | IntegerForm::Reverse, false) => {
                    IntBinOp::Sub
                }
                (IntegerKind::Mul, IntegerForm::Plain, _) => IntBinOp::MulLo,
                (IntegerKind::Min, IntegerForm::Plain, _) => IntBinOp::Min,
                (IntegerKind::Max, IntegerForm::Plain, _) => IntBinOp::Max,
                _ => return None,
            };
            (operation, signed, form == IntegerForm::Reverse)
        }
        AluOperation::Bitwise {
            domain: AluDomain::Vector,
            kind: kind @ (BitwiseKind::And | BitwiseKind::Or | BitwiseKind::Xor),
            width: BitWidth::B32,
            save_exec: false,
        } => (
            match kind {
                BitwiseKind::And => IntBinOp::And,
                BitwiseKind::Or => IntBinOp::Or,
                BitwiseKind::Xor => IntBinOp::Xor,
                _ => unreachable!("selected vector binary bitwise family"),
            },
            false,
            false,
        ),
        AluOperation::Shift {
            domain: AluDomain::Vector,
            kind: ShiftKind::ArithmeticRight,
            width: BitWidth::B32,
            reverse: true,
        } => (IntBinOp::AShr, true, true),
        _ => return None,
    };
    Some((IntType { bits: 32, signed }, operation, reverse))
}
