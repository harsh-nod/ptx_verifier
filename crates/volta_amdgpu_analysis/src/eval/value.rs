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
    NarrowInt {
        expr: ExprId,
        bits: u8,
        signed: bool,
    },
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
    Bytes([ExprId; 4]),
}

impl Value {
    pub fn bits(self) -> Result<u32, String> {
        match self {
            Self::Bits(bits) | Self::Integer(bits) => Ok(bits),
            Self::SignedInteger(bits) => Ok(bits as u32),
            Self::PredicateWord { .. } => {
                Err("symbolic predicate mask used as concrete integer/address bits".into())
            }
            _ => Err("symbolic mathematical data used as integer/address bits".into()),
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
            Self::Input(_)
            | Self::IntExpr(_)
            | Self::PredicateWord { .. }
            | Self::NarrowInt { .. }
            | Self::WidePart { .. }
            | Self::Half(..)
            | Self::Halves(..)
            | Self::PartialHalves(..)
            | Self::Byte(..)
            | Self::Bytes(..) => Err("encoded packed data used as one f32 value".into()),
        }
    }
}
