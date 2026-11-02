//! Finite scalar source layouts and canonical immediate encodings.
//!
//! Width belongs to a source position, not the destination or numeric spelling.
//! These five binary operations use Binary64 data and Bits32 shift counts.
use crate::{
    frontend::Operand,
    ir::{AluOpcode, AluOperation},
    target::Architecture,
};

/// Interpretation of a selected scalar source, independent of literal size.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScalarSourceType {
    Binary64,
    Bits32,
}
impl ScalarSourceType {
    pub(crate) fn words(self) -> u16 {
        match self {
            Self::Binary64 => 2,
            Self::Bits32 => 1,
        }
    }
}

// CDNA scalar selector table; selector248 is the exact architectural constant.
const FLOAT_INLINES: [(u32, u64); 9] = [
    (0x3f00_0000, 0x3fe0_0000_0000_0000),
    (0xbf00_0000, 0xbfe0_0000_0000_0000),
    (0x3f80_0000, 0x3ff0_0000_0000_0000),
    (0xbf80_0000, 0xbff0_0000_0000_0000),
    (0x4000_0000, 0x4000_0000_0000_0000),
    (0xc000_0000, 0xc000_0000_0000_0000),
    (0x4080_0000, 0x4010_0000_0000_0000),
    (0xc080_0000, 0xc010_0000_0000_0000),
    (0x3e22_f983, 0x3fc4_5f30_6dc9_c882),
];

/// A validated scalar inline selector; construction is private.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct InlineSelector(u8);
impl InlineSelector {
    pub fn code(self) -> u8 {
        self.0
    }
    fn bits(self, ty: ScalarSourceType) -> Option<u64> {
        let value = match self.0 {
            128..=192 => u64::from(self.0 - 128),
            193..=208 => (-(i64::from(self.0) - 192)) as u64,
            240..=248 => {
                let (single, double) = FLOAT_INLINES[usize::from(self.0 - 240)];
                return Some(match ty {
                    ScalarSourceType::Binary64 => double,
                    ScalarSourceType::Bits32 => u64::from(single),
                });
            }
            _ => return None,
        };
        Some(match ty {
            ScalarSourceType::Binary64 => value,
            ScalarSourceType::Bits32 => u64::from(value as u32),
        })
    }
}

/// A source selector or appended payload, distinct from instruction E32/E64.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImmediateEncoding {
    Inline(InlineSelector),
    Literal32(u32),
    Literal64(u64),
}

/// A target-checked canonical immediate. Its expanded bits cannot be mutated
/// independently from the source interpretation and selector/payload.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EncodedImmediate {
    source_type: ScalarSourceType,
    encoding: ImmediateEncoding,
}
impl EncodedImmediate {
    pub fn source_type(&self) -> ScalarSourceType {
        self.source_type
    }
    pub fn encoding(&self) -> ImmediateEncoding {
        self.encoding
    }
    pub fn bits(&self) -> u64 {
        match self.encoding {
            ImmediateEncoding::Inline(selector) => selector
                .bits(self.source_type)
                .expect("encoded immediate has a checked inline selector"),
            ImmediateEncoding::Literal32(word) => u64::from(word),
            ImmediateEncoding::Literal64(bits) => bits,
        }
    }
    fn checked(
        source_type: ScalarSourceType,
        encoding: ImmediateEncoding,
        architecture: Architecture,
    ) -> Result<Self, String> {
        match encoding {
            ImmediateEncoding::Inline(selector) => {
                if selector.bits(source_type).is_none() {
                    return Err("invalid scalar inline selector".into());
                }
            }
            ImmediateEncoding::Literal32(word) => {
                if source_type == ScalarSourceType::Binary64 && word > i32::MAX as u32 {
                    return Err(if architecture == Architecture::Gfx1250 {
                        "gfx1250 high-bit Binary64 data requires the canonical literal64 encoding"
                    } else {
                        "legacy Binary64 high-bit appended literal has no supported SALU expansion premise"
                    }
                    .into());
                }
                if inline_bits(u64::from(word), source_type).is_some() {
                    return Err("scalar literal requires its canonical inline selector".into());
                }
            }
            ImmediateEncoding::Literal64(bits) => {
                if architecture != Architecture::Gfx1250
                    || source_type != ScalarSourceType::Binary64
                {
                    return Err("literal64 is supported only for gfx1250 Binary64 data".into());
                }
                if bits <= i32::MAX as u64 || inline_bits(bits, source_type).is_some() {
                    return Err(
                        "scalar literal64 is not the canonical encoding for this value".into(),
                    );
                }
            }
        }
        Ok(Self {
            source_type,
            encoding,
        })
    }
}

fn inline_bits(bits: u64, ty: ScalarSourceType) -> Option<InlineSelector> {
    let signed = match ty {
        ScalarSourceType::Binary64 => bits as i64,
        ScalarSourceType::Bits32 => i64::from(bits as u32 as i32),
    };
    if (0..=64).contains(&signed) {
        return Some(InlineSelector(128 + signed as u8));
    }
    if (-16..=-1).contains(&signed) {
        return Some(InlineSelector(192 + (-signed) as u8));
    }
    FLOAT_INLINES
        .iter()
        .position(|&(single, double)| match ty {
            ScalarSourceType::Binary64 => bits == double,
            ScalarSourceType::Bits32 => bits == u64::from(single),
        })
        .map(|index| InlineSelector(240 + index as u8))
}

fn inline_float64(value: f64) -> Option<InlineSelector> {
    if !value.is_finite() {
        return None;
    }
    let bits = value.to_bits();
    // Floating syntax denotes floating bits, never an integer-inline numeric
    // conversion. Positive zero shares the integer zero selector.
    if bits == 0 {
        Some(InlineSelector(128))
    } else {
        FLOAT_INLINES
            .iter()
            .position(|&(_, double)| bits == double)
            .map(|index| InlineSelector(240 + index as u8))
    }
}

/// Exact issue107 helper for unselected wide consumers. Produced mathematical
/// values retain their separate re-encoding and arithmetic-model checks.
pub(crate) fn exact_inline_double(value: f64) -> Option<u64> {
    inline_float64(value).and_then(|selector| selector.bits(ScalarSourceType::Binary64))
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ScalarLayout {
    Move64,
    Binary64,
    Shift64,
}
impl ScalarLayout {
    pub(crate) fn for_operation(operation: AluOperation) -> Option<Self> {
        match operation {
            AluOperation::Opcode(AluOpcode::SMovB64) => Some(Self::Move64),
            AluOperation::Opcode(AluOpcode::SOrB64 | AluOpcode::SXorB64) => Some(Self::Binary64),
            AluOperation::Opcode(AluOpcode::SLshlB64 | AluOpcode::SLshrB64) => Some(Self::Shift64),
            _ => None,
        }
    }
    pub(crate) fn for_mnemonic(stem: &str) -> Option<Self> {
        AluOperation::parse(stem).and_then(Self::for_operation)
    }
    pub(crate) fn arity(self) -> usize {
        if self == Self::Move64 { 2 } else { 3 }
    }
    pub(crate) fn source_type(self, position: usize) -> Option<ScalarSourceType> {
        match (self, position) {
            (_, 1) => Some(ScalarSourceType::Binary64),
            (Self::Binary64, 2) => Some(ScalarSourceType::Binary64),
            (Self::Shift64, 2) => Some(ScalarSourceType::Bits32),
            _ => None,
        }
    }
}

#[derive(Debug)]
pub(crate) struct ResolvedScalarSources {
    immediates: [Option<EncodedImmediate>; 2],
}
impl ResolvedScalarSources {
    pub(crate) fn immediate_at(&self, operand_position: usize) -> Option<EncodedImmediate> {
        operand_position
            .checked_sub(1)
            .and_then(|index| self.immediates.get(index))
            .copied()
            .flatten()
    }
}

fn numeric(
    operand: &Operand,
    ty: ScalarSourceType,
    architecture: Architecture,
) -> Result<EncodedImmediate, String> {
    let encoding = match operand {
        Operand::Float(value) if ty == ScalarSourceType::Bits32 => {
            let single = *value as f32;
            if !value.is_finite() || !single.is_finite() {
                return Err(
                    "Bits32 Float source requires a finite F32 conversion without overflow".into(),
                );
            }
            // LLVM permits ordinary precision loss, but rejects lossy
            // underflow. Exact subnormals retain their actual bits.
            if single.abs() < f32::MIN_POSITIVE && f64::from(single) != *value {
                return Err("Bits32 Float source has an unsupported lossy F32 underflow".into());
            }
            let bits = single.to_bits();
            inline_bits(u64::from(bits), ty).map_or(
                ImmediateEncoding::Literal32(bits),
                ImmediateEncoding::Inline,
            )
        }
        Operand::Float(value) => {
            ImmediateEncoding::Inline(inline_float64(*value).ok_or_else(|| {
                format!("{ty:?} source requires an exact floating inline constant")
            })?)
        }
        Operand::Integer(value) => {
            if ty == ScalarSourceType::Bits32
                && !(i32::MIN as i64..=u32::MAX as i64).contains(value)
            {
                return Err(
                    "Bits32 source requires a 32-bit integer, not a truncated wide literal".into(),
                );
            }
            let bits = match ty {
                ScalarSourceType::Binary64 => *value as u64,
                ScalarSourceType::Bits32 => u64::from(*value as u32),
            };
            if let Some(selector) = inline_bits(bits, ty) {
                ImmediateEncoding::Inline(selector)
            } else if ty == ScalarSourceType::Bits32 || bits <= i32::MAX as u64 {
                ImmediateEncoding::Literal32(bits as u32)
            } else if architecture == Architecture::Gfx1250 {
                ImmediateEncoding::Literal64(bits)
            } else {
                return Err("legacy Binary64 noninline data requires a nonnegative low31-bit literal; high-bit expansion and literal64 are unsupported".into());
            }
        }
        _ => return Err("scalar immediate must be an integer or exact inline Float".into()),
    };
    EncodedImmediate::checked(ty, encoding, architecture)
}

/// Resolve a whole instruction, including the single appended-payload rule.
/// Parsing may defer Symbols until declared constants are substituted; final
/// executable construction forbids that deferred state.
pub(crate) fn resolve(
    mnemonic: &str,
    operands: &[Operand],
    architecture: Architecture,
    defer_symbols: bool,
) -> Result<Option<ResolvedScalarSources>, String> {
    resolve_instruction(mnemonic, operands, architecture, defer_symbols)
        .map_err(|message| format!("scalar source encoding: {message}"))
}

fn resolve_instruction(
    mnemonic: &str,
    operands: &[Operand],
    architecture: Architecture,
    defer_symbols: bool,
) -> Result<Option<ResolvedScalarSources>, String> {
    let stem = mnemonic
        .trim_end_matches("_e32")
        .trim_end_matches("_e64")
        .trim_end_matches("_sdwa");
    let Some(layout) = ScalarLayout::for_mnemonic(stem) else {
        return Ok(None);
    };
    // MC accepts selected _e32 aliases, but this native subset deliberately
    // retains bare SALU forms. Do not discard encoding spelling internally.
    if mnemonic != stem {
        return Err(format!(
            "`{mnemonic}` selected scalar source form requires a bare SOP1/SOP2 mnemonic"
        ));
    }
    if operands.len() != layout.arity() {
        return Err(format!("`{stem}` has an invalid scalar source arity"));
    }
    let mut result = ResolvedScalarSources {
        immediates: [None; 2],
    };
    let mut literal = None;
    for (position, operand) in operands.iter().enumerate().skip(1) {
        let ty = layout
            .source_type(position)
            .ok_or("invalid scalar source position")?;
        let encoded = match operand {
            Operand::Register(register) if register.count == ty.words() => continue,
            Operand::Register(_) => {
                return Err(format!(
                    "`{stem}` source{position} requires {} register word(s)",
                    ty.words()
                ));
            }
            Operand::Symbol(_) if defer_symbols => continue,
            Operand::Integer(_) | Operand::Float(_) => numeric(operand, ty, architecture)
                .map_err(|message| format!("`{stem}` source{position}: {message}"))?,
            _ => {
                return Err(format!(
                    "`{stem}` source{position} is not a supported scalar value"
                ));
            }
        };
        if !matches!(encoded.encoding(), ImmediateEncoding::Inline(_)) {
            if literal.is_some_and(|previous| previous != encoded.encoding()) {
                return Err(format!(
                    "`{stem}` source{position} requires one shared literal payload and width"
                ));
            }
            literal = Some(encoded.encoding());
        }
        result.immediates[position - 1] = Some(encoded);
    }
    Ok(Some(result))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::frontend::{Register, RegisterClass};

    fn register(index: u16, count: u16) -> Operand {
        Operand::Register(Register {
            class: RegisterClass::Scalar,
            index,
            count,
            special: None,
        })
    }

    #[test]
    fn private_constructor_rejects_invalid_selector_type_target_and_noncanonical_payloads() {
        use ImmediateEncoding::*;
        use ScalarSourceType::*;
        for (ty, encoding, target) in [
            (Binary64, Inline(InlineSelector(209)), Architecture::Gfx1250),
            (Binary64, Inline(InlineSelector(249)), Architecture::Gfx950),
            (Bits32, Literal64(0x1_0000_0000), Architecture::Gfx1250),
            (Binary64, Literal64(0x1_0000_0000), Architecture::Gfx950),
            (Binary64, Literal32(0x8000_0000), Architecture::Gfx942),
            (Binary64, Literal32(0x8000_0000), Architecture::Gfx1250),
            (Bits32, Literal32(0x3f80_0000), Architecture::Gfx1250),
            (Binary64, Literal64(0x100), Architecture::Gfx1250),
        ] {
            assert!(
                EncodedImmediate::checked(ty, encoding, target).is_err(),
                "{ty:?} {encoding:?} {target:?}"
            );
        }
    }

    #[test]
    fn whole_instruction_literal_sharing_checks_width_as_well_as_payload() {
        for target in [
            Architecture::Gfx942,
            Architecture::Gfx950,
            Architecture::Gfx1250,
        ] {
            let different = [
                register(0, 2),
                Operand::Integer(0x100),
                Operand::Integer(0x200),
            ];
            assert!(
                resolve("s_xor_b64", &different, target, false)
                    .unwrap_err()
                    .contains("shared literal")
            );
            let shared = [
                register(0, 2),
                Operand::Integer(0x100),
                Operand::Integer(0x100),
            ];
            let resolved = resolve("s_lshl_b64", &shared, target, false)
                .unwrap()
                .unwrap();
            assert_eq!(
                resolved.immediate_at(1).unwrap().source_type(),
                ScalarSourceType::Binary64
            );
            assert_eq!(
                resolved.immediate_at(2).unwrap().source_type(),
                ScalarSourceType::Bits32
            );
            assert_eq!(
                resolved.immediate_at(1).unwrap().encoding(),
                ImmediateEncoding::Literal32(0x100)
            );
            assert_eq!(
                resolved.immediate_at(2).unwrap().encoding(),
                ImmediateEncoding::Literal32(0x100)
            );
        }
        let unlike = [
            register(0, 2),
            Operand::Integer(0x1_0000_0100),
            Operand::Integer(0x100),
        ];
        assert!(
            resolve("s_lshl_b64", &unlike, Architecture::Gfx1250, false)
                .unwrap_err()
                .contains("shared literal payload and width")
        );
    }

    #[test]
    fn deferred_symbols_are_not_executable_immediates() {
        let operands = [register(0, 2), Operand::Symbol("LITERAL".into())];
        let deferred = resolve("s_mov_b64", &operands, Architecture::Gfx950, true)
            .unwrap()
            .unwrap();
        assert!(deferred.immediate_at(1).is_none());
        assert!(resolve("s_mov_b64", &operands, Architecture::Gfx950, false).is_err());
    }

    #[test]
    fn malformed_source_shapes_cannot_be_truncated_or_indexed() {
        for operands in [
            vec![register(0, 2)],
            vec![register(0, 2), register(2, 1), Operand::Integer(1)],
            vec![register(0, 2), register(2, 2), register(4, 2)],
            vec![
                register(0, 2),
                Operand::Integer(1),
                Operand::Integer(0x1_0000_0001),
            ],
        ] {
            assert!(resolve("s_lshr_b64", &operands, Architecture::Gfx1250, false).is_err());
        }
        assert!(
            resolve(
                "s_and_b64",
                &[register(0, 2), Operand::Float(1.0)],
                Architecture::Gfx1250,
                false
            )
            .unwrap()
            .is_none()
        );
        assert!(
            resolve("s_cmp_eq_u64", &[], Architecture::Gfx950, false)
                .unwrap()
                .is_none()
        );
    }

    #[test]
    fn finite_float_counts_share_the_actual_f32_payload() {
        for target in [
            Architecture::Gfx942,
            Architecture::Gfx950,
            Architecture::Gfx1250,
        ] {
            let same = [
                register(0, 2),
                Operand::Integer(0x3fc0_0000),
                Operand::Float(1.5),
            ];
            let resolved = resolve("s_lshl_b64", &same, target, false)
                .unwrap()
                .unwrap();
            let data = resolved.immediate_at(1).unwrap();
            let count = resolved.immediate_at(2).unwrap();
            assert_eq!(data.source_type(), ScalarSourceType::Binary64);
            assert_eq!(count.source_type(), ScalarSourceType::Bits32);
            assert_eq!(data.encoding(), ImmediateEncoding::Literal32(0x3fc0_0000));
            assert_eq!(count.encoding(), ImmediateEncoding::Literal32(0x3fc0_0000));
            let different = [register(0, 2), Operand::Integer(0x100), Operand::Float(1.5)];
            let error = resolve("s_lshr_b64", &different, target, false).unwrap_err();
            assert!(error.contains("source2") && error.contains("shared literal"));
            let data_float = [register(0, 2), Operand::Float(1.5)];
            assert!(
                resolve("s_mov_b64", &data_float, target, false)
                    .unwrap_err()
                    .contains("Binary64 source requires an exact floating inline")
            );
        }
    }

    #[test]
    fn float_count_conversion_cannot_invent_finite_or_underflowed_bits() {
        for value in [f64::INFINITY, f64::NAN, f64::MAX, 1e-40, f64::from_bits(1)] {
            let operands = [register(0, 2), Operand::Integer(1), Operand::Float(value)];
            assert!(resolve("s_lshl_b64", &operands, Architecture::Gfx950, false).is_err());
        }
        let exact_subnormal = [
            register(0, 2),
            Operand::Integer(1),
            Operand::Float(f64::from(f32::from_bits(1))),
        ];
        let resolved = resolve("s_lshl_b64", &exact_subnormal, Architecture::Gfx1250, false)
            .unwrap()
            .unwrap();
        assert_eq!(resolved.immediate_at(2).unwrap().bits(), 1);
        let rounded = [
            register(0, 2),
            Operand::Integer(1),
            Operand::Float(1.0000000001),
        ];
        let resolved = resolve("s_lshl_b64", &rounded, Architecture::Gfx950, false)
            .unwrap()
            .unwrap();
        assert_eq!(
            resolved.immediate_at(2).unwrap().encoding(),
            ImmediateEncoding::Inline(InlineSelector(242))
        );
    }
}
