//! Exact concrete register encodings; mathematical results are never rounded
//! merely to make an integer bit operation executable.
use super::value::Value;
use volta_expr::{ExprArena, ExprNode, RealRepr};

/// Native floating inline selectors use the source operand's width, even for
/// integer/bitwise instructions (CDNA5 ISA section 4.1). Match exact FP64 bits:
/// neither an FP32 roundtrip nor a nearby decimal is an encoding certificate.
/// The inverse-two-pi selector is the ISA constant, not a computed reciprocal.
pub(super) fn inline_double(value: f64) -> Option<u64> {
    let bits = value.to_bits();
    match bits {
        0
        | 0x3fe0_0000_0000_0000
        | 0xbfe0_0000_0000_0000
        | 0x3ff0_0000_0000_0000
        | 0xbff0_0000_0000_0000
        | 0x4000_0000_0000_0000
        | 0xc000_0000_0000_0000
        | 0x4010_0000_0000_0000
        | 0xc010_0000_0000_0000
        | 0x3fc4_5f30_6dc9_c882 => Some(bits),
        _ => None,
    }
}

pub(super) fn exact_word(arena: &ExprArena, value: Value) -> Option<u32> {
    if let Ok(word) = value.bits() {
        return Some(word);
    }
    let Value::Real(expr) = value else {
        return None;
    };
    let rational = match arena.node(expr) {
        ExprNode::IntConst(value) => rug::Rational::from(*value),
        ExprNode::RealConst(value) => match value.repr() {
            RealRepr::NegInf => return Some(f32::NEG_INFINITY.to_bits()),
            RealRepr::PosInf => return Some(f32::INFINITY.to_bits()),
            RealRepr::Rational(value) => value.clone(),
        },
        _ => return None,
    };
    let value = rational.to_f64() as f32;
    let roundtrip = rug::Rational::from_f64(f64::from(value))?;
    (roundtrip == rational).then_some(value.to_bits())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn only_exact_binary32_constants_can_be_reencoded() {
        let mut arena = ExprArena::new();
        for value in [-5.0f32, 0.0, 2.0, f32::INFINITY, f32::NEG_INFINITY] {
            let expr = arena.float_from_f64(f64::from(value)).unwrap();
            assert_eq!(exact_word(&arena, Value::Real(expr)), Some(value.to_bits()));
        }
        let third = arena.real(volta_expr::Real::from_rational(rug::Rational::from((1, 3))));
        assert_eq!(exact_word(&arena, Value::Real(third)), None);
        let symbol = arena.param_symbol("x");
        assert_eq!(exact_word(&arena, Value::Real(symbol)), None);
    }
}
