//! Untyped 32-bit register storage, separated from symbolic real-valued data.
use volta_expr::{ExprArena, ExprId};

#[derive(Debug, Clone, Copy, PartialEq)]
pub(super) enum Value {
    Bits(u32),
    /// Integer arithmetic provenance for mathematically typed output extraction.
    Integer(u32),
    SignedInteger(i32),
    Real(ExprId),
    /// One encoded half in bits 15:0, with a zero-filled upper half.
    Half(ExprId),
    Halves(ExprId, ExprId),
    PartialHalves(Option<ExprId>, Option<ExprId>),
    /// Numeric OCP E4M3 input values retained in encoded-byte storage.
    Byte(ExprId),
    Bytes([ExprId; 4]),
}

impl Value {
    pub fn bits(self) -> Result<u32, String> {
        match self {
            Self::Bits(bits) | Self::Integer(bits) => Ok(bits),
            Self::SignedInteger(bits) => Ok(bits as u32),
            _ => Err("symbolic mathematical data used as integer/address bits".into()),
        }
    }

    pub fn real(self, arena: &mut ExprArena) -> Result<ExprId, String> {
        match self {
            Self::Real(expr) => Ok(expr),
            Self::Bits(bits) | Self::Integer(bits) => arena
                .float_from_f64(f32::from_bits(bits) as f64)
                .map_err(|e| e.to_string()),
            Self::SignedInteger(bits) => arena
                .float_from_f64(f32::from_bits(bits as u32) as f64)
                .map_err(|e| e.to_string()),
            Self::Half(..)
            | Self::Halves(..)
            | Self::PartialHalves(..)
            | Self::Byte(..)
            | Self::Bytes(..) => Err("encoded packed data used as one f32 value".into()),
        }
    }
}
