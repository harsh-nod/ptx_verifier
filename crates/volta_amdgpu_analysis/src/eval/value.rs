//! Untyped 32-bit register storage, separated from symbolic real-valued data.
use volta_expr::{ExprArena, ExprId};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(super) enum WideKind {
    Input,
    Float,
    Integer,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub(super) enum Value {
    Bits(u32),
    /// Concrete ABI bytes loaded together with uninitialized padding. Unknown
    /// bits have no numeric value and may only be bypassed by exact selection.
    PartialBits {
        bits: u32,
        defined: u32,
    },
    /// Integer arithmetic provenance for mathematically typed output extraction.
    Integer(u32),
    SignedInteger(i32),
    /// Untyped array data acquires its mathematical type at the consumer.
    Input(ExprId),
    IntExpr(ExprId),
    /// Opaque 32 lane predicates, indexed by a comparison-pool entry and its
    /// source half. Copying a high word into a low destination preserves bits.
    PredicateWord {
        mask: u32,
        high: bool,
    },
    /// Opaque PC anchor, usable only by one validated adjacent rel32 sequence.
    RelocationWord {
        anchor: u32,
        high: bool,
    },
    /// Unknown high32 of the 2^32-aligned LDS aperture. Only FLAT addressing
    /// may consume it, paired with a concrete segment offset in the low word.
    SharedApertureHi,
    NarrowInt {
        expr: ExprId,
        bits: u8,
        signed: bool,
    },
    /// Signed integer in low16 only; the upper half has no modeled value.
    /// Only a selected-low16 consumer may read this tag.
    Low16Integer(ExprId),
    Real(ExprId),
    /// One ordered word of a whole mathematical 64-bit value. These tags are
    /// data, never concrete register/address bits or packed independent f32s.
    WidePart {
        expr: ExprId,
        high: bool,
        kind: WideKind,
    },
    /// One encoded half in bits 15:0, with a zero-filled upper half.
    Half(ExprId),
    Halves(ExprId, ExprId),
    PartialHalves(Option<ExprId>, Option<ExprId>),
    /// Encoded input bytes; the first numeric decoder fixes the array format.
    Byte(ExprId),
    /// Two encoded bytes in low16, with a zero-filled upper half.
    BytePair(ExprId, ExprId),
    Bytes([ExprId; 4]),
}

impl Value {
    pub fn bits(self) -> Result<u32, String> {
        match self {
            Self::Bits(bits) | Self::Integer(bits) => Ok(bits),
            Self::SignedInteger(bits) => Ok(bits as u32),
            Self::PartialBits { .. } => {
                Err("undefined bits in a partially initialized ABI word".into())
            }
            Self::PredicateWord { .. } => {
                Err("symbolic predicate mask used as concrete integer/address bits".into())
            }
            Self::RelocationWord { .. } => {
                Err("opaque PC-relative relocation anchor used as ordinary bits".into())
            }
            Self::SharedApertureHi => {
                Err("opaque shared aperture cannot be used as ordinary bits".into())
            }
            _ => Err("symbolic mathematical data used as integer/address bits".into()),
        }
    }

    pub fn selected_bits(self, offset: u32, width: u32) -> Result<u32, String> {
        if width == 0 || width > 32 || offset > 32 - width {
            return Err("invalid register-bit selection".into());
        }
        let mask = u32::MAX >> (32 - width);
        match self {
            Self::PartialBits { bits, defined } => {
                if (defined >> offset) & mask != mask {
                    return Err("selected undefined bits from ABI padding".into());
                }
                Ok((bits >> offset) & mask)
            }
            value => Ok((value.bits()? >> offset) & mask),
        }
    }

    pub fn real(self, arena: &mut ExprArena) -> Result<ExprId, String> {
        match self {
            Self::Real(expr) => Ok(expr),
            Self::Bits(bits) | Self::Integer(bits) => {
                super::scalar::decode_float(arena, super::scalar::FloatType::F32, bits as u64)
            }
            Self::SignedInteger(bits) => super::scalar::decode_float(
                arena,
                super::scalar::FloatType::F32,
                bits as u32 as u64,
            ),
            Self::PartialBits { .. } => {
                Err("undefined bits in a partially initialized ABI float".into())
            }
            Self::Input(_)
            | Self::IntExpr(_)
            | Self::PredicateWord { .. }
            | Self::RelocationWord { .. }
            | Self::SharedApertureHi
            | Self::NarrowInt { .. }
            | Self::Low16Integer(_)
            | Self::WidePart { .. }
            | Self::Half(..)
            | Self::Halves(..)
            | Self::PartialHalves(..)
            | Self::Byte(..)
            | Self::BytePair(..)
            | Self::Bytes(..) => Err("encoded packed data used as one f32 value".into()),
        }
    }
}
