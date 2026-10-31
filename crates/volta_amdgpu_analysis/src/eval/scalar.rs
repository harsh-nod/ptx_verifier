//! Typed scalar mathematics for the gfx950 interpreter.
//!
//! Register/address handling stays in the interpreter: an `ExprId` accepted here
//! must already have the operation's data type. In particular, a symbolic data
//! result never supplies concrete address bits. Concrete integers use the native
//! width and wrap; symbolic add/sub/mullo retain the existing PTX backend's
//! mathematical ring abstraction (no invented truncation or modular solver).
//!
//! Native shifts mask their count; V_BFE masks offset and width to five bits.
//! These are CDNA4 semantics, not PTX's clamped shift/field semantics. Portable
//! programs must implement any required clamp with actual native instructions.
//! Scalar floats reuse ExprArena's exact extended-real model: rounding and signed
//! zero are outside that model, NaN ingestion is rejected, and infinities remain
//! explicit. MFMA has its own stricter finite-operand check.

use volta_expr::{ExprArena, ExprId, ExprNode, Real};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct IntType {
    pub bits: u32,
    pub signed: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum FloatType {
    F32,
    F64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ScalarType {
    Int(IntType),
    Float(FloatType),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum IntBinOp {
    Add,
    Sub,
    MulLo,
    Div,
    And,
    Or,
    Xor,
    Min,
    Max,
    Shl,
    LShr,
    AShr,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum CmpOp {
    Eq,
    Ne,
    Lt,
    Le,
    Gt,
    Ge,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum FloatBinOp {
    Add,
    Mul,
    Min,
    Max,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum FloatUnOp {
    Rcp,
    Sqrt,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Clamp {
    None,
    Relu,
    Sat,
}

fn validate_int(ty: IntType) -> Result<(), String> {
    if matches!(ty.bits, 8 | 16 | 32 | 64) {
        Ok(())
    } else {
        Err(format!("unsupported integer width {}", ty.bits))
    }
}

fn low_bits(value: i64, bits: u32) -> u64 {
    if bits == 64 {
        value as u64
    } else {
        value as u64 & ((1u64 << bits) - 1)
    }
}

/// The 64-bit unsigned case uses an i64 bit-pattern container, as ExprArena and
/// the PTX backend do. Unsigned comparisons restore u64 before comparing.
pub(crate) fn canonical_int(value: i64, ty: IntType) -> Result<i64, String> {
    validate_int(ty)?;
    let bits = low_bits(value, ty.bits);
    Ok(if ty.signed && ty.bits < 64 {
        ((bits << (64 - ty.bits)) as i64) >> (64 - ty.bits)
    } else {
        bits as i64
    })
}

fn integer_operand(arena: &ExprArena, value: ExprId) -> Result<(), String> {
    if matches!(
        arena.node(value),
        ExprNode::RealConst(_) | ExprNode::BoolConst(_)
    ) {
        Err("a floating/boolean constant cannot be an integer data operand".into())
    } else {
        Ok(())
    }
}

/// Concrete operands wrap at the declared width. For symbolic ring operations,
/// supplied constant expressions are retained unchanged: an immediate `-1` must
/// remain `-1` under both signed and unsigned add/sub/mullo.
pub(crate) fn int_binary(
    arena: &mut ExprArena,
    ty: IntType,
    op: IntBinOp,
    a: ExprId,
    b: ExprId,
) -> Result<ExprId, String> {
    validate_int(ty)?;
    integer_operand(arena, a)?;
    integer_operand(arena, b)?;
    if matches!(op, IntBinOp::Shl | IntBinOp::LShr | IntBinOp::AShr) && !matches!(ty.bits, 32 | 64)
    {
        return Err("native scalar shifts in this model require 32 or 64 bits".into());
    }
    if op == IntBinOp::Div
        && arena
            .as_int_const(b)
            .is_some_and(|b| low_bits(b, ty.bits) == 0)
    {
        return Err("integer division by zero".into());
    }
    if let (Some(a), Some(b)) = (arena.as_int_const(a), arena.as_int_const(b)) {
        let ua = low_bits(a, ty.bits);
        let ub = low_bits(b, ty.bits);
        let sa = canonical_int(a, IntType { signed: true, ..ty })?;
        let sb = canonical_int(b, IntType { signed: true, ..ty })?;
        let shift = (b as u32) & (ty.bits - 1);
        let result = match op {
            IntBinOp::Add => ua.wrapping_add(ub),
            IntBinOp::Sub => ua.wrapping_sub(ub),
            IntBinOp::MulLo => ua.wrapping_mul(ub),
            IntBinOp::Div if ty.signed => sa.wrapping_div(sb) as u64,
            IntBinOp::Div => ua / ub,
            IntBinOp::And => ua & ub,
            IntBinOp::Or => ua | ub,
            IntBinOp::Xor => ua ^ ub,
            IntBinOp::Min if ty.signed => sa.min(sb) as u64,
            IntBinOp::Min => ua.min(ub),
            IntBinOp::Max if ty.signed => sa.max(sb) as u64,
            IntBinOp::Max => ua.max(ub),
            IntBinOp::Shl => ua.wrapping_shl(shift),
            IntBinOp::LShr => ua.wrapping_shr(shift),
            IntBinOp::AShr => (sa >> shift) as u64,
        };
        let result = canonical_int(result as i64, ty)?;
        return Ok(arena.int(result));
    }
    if matches!(op, IntBinOp::Add | IntBinOp::Sub | IntBinOp::MulLo) {
        return Ok(match op {
            IntBinOp::Add => arena.add(a, b),
            IntBinOp::Sub => arena.sub(a, b),
            IntBinOp::MulLo => arena.mul(a, b),
            _ => unreachable!(),
        });
    }
    if op == IntBinOp::Div {
        return Err(
            "symbolic integer division truncation cannot be modeled by exact real division".into(),
        );
    }
    let a = canonical_operand(arena, ScalarType::Int(ty), a)?;
    let b = canonical_operand(arena, ScalarType::Int(ty), b)?;
    let result = match op {
        IntBinOp::And => arena.bit_and(a, b),
        IntBinOp::Or => arena.bit_or(a, b),
        IntBinOp::Xor => arena.bit_xor(a, b),
        IntBinOp::Min => return Ok(arena.min(a, b)),
        IntBinOp::Max => return Ok(arena.max(a, b)),
        IntBinOp::Shl | IntBinOp::LShr | IntBinOp::AShr => {
            let count_mask = arena.int((ty.bits - 1) as i64);
            let count = arena.bit_and(b, count_mask);
            if arena.as_int_const(count) == Some(0) {
                return Ok(a);
            }
            let source = word_expression(arena, ty.bits, a);
            match op {
                IntBinOp::Shl => arena.shl(source, count),
                IntBinOp::LShr => arena.lshr(source, count),
                _ => {
                    let source = signed_expression(arena, ty.bits, source);
                    arena.shr(source, count)
                }
            }
        }
        _ => unreachable!(),
    };
    // Existing bit nodes operate on64-bit words. Explicit masks and sign
    // extension retain the native32-bit result width without new AST variants.
    let result = word_expression(arena, ty.bits, result);
    Ok(if ty.signed {
        signed_expression(arena, ty.bits, result)
    } else {
        result
    })
}

fn word_expression(arena: &mut ExprArena, bits: u32, value: ExprId) -> ExprId {
    if bits == 64 {
        return value;
    }
    let mask = arena.int(((1u64 << bits) - 1) as i64);
    arena.bit_and(value, mask)
}
fn signed_expression(arena: &mut ExprArena, bits: u32, value: ExprId) -> ExprId {
    if bits == 64 {
        return value;
    }
    let shift = arena.int((64 - bits) as i64);
    let extended = arena.shl(value, shift);
    arena.shr(extended, shift)
}

fn canonical_operand(
    arena: &mut ExprArena,
    ty: ScalarType,
    value: ExprId,
) -> Result<ExprId, String> {
    match ty {
        ScalarType::Int(ty) => {
            validate_int(ty)?;
            integer_operand(arena, value)?;
            if let Some(value) = arena.as_int_const(value) {
                let value = canonical_int(value, ty)?;
                Ok(arena.int(value))
            } else {
                Ok(value)
            }
        }
        ScalarType::Float(ty) => {
            if let Some(bits) = arena.as_int_const(value) {
                decode_float(arena, ty, bits as u64)
            } else if matches!(arena.node(value), ExprNode::BoolConst(_)) {
                Err("boolean data cannot be a floating operand".into())
            } else {
                Ok(value)
            }
        }
    }
}

/// A native32-bit single-bit predicate has an exact, format-independent
/// representation shared with packed external-word specifications. This only
/// rewrites proven masks/sign tests, never general symbolic integer ordering.
fn bit_nonzero(arena: &mut ExprArena, value: ExprId, bit: u32) -> ExprId {
    let shift = arena.int(bit as i64);
    let shifted = arena.lshr(value, shift);
    let one = arena.int(1);
    let selected = arena.bit_and(shifted, one);
    let zero = arena.int(0);
    arena.ne(selected, zero)
}

fn single_masked_bit(arena: &ExprArena, mut value: ExprId) -> Option<(ExprId, u32)> {
    let mut mask = u32::MAX;
    let mut saw_mask = false;
    while let ExprNode::BitAnd(a, b) = *arena.node(value) {
        if let Some(constant) = arena.as_int_const(a) {
            mask &= constant as u32;
            value = b;
        } else if let Some(constant) = arena.as_int_const(b) {
            mask &= constant as u32;
            value = a;
        } else {
            break;
        }
        saw_mask = true;
    }
    (saw_mask && mask.is_power_of_two()).then_some((value, mask.trailing_zeros()))
}

fn compare_word_bit(
    arena: &mut ExprArena,
    ty: IntType,
    op: CmpOp,
    a: ExprId,
    b: ExprId,
) -> Option<ExprId> {
    if ty.bits != 32 {
        return None;
    }
    if matches!(op, CmpOp::Eq | CmpOp::Ne) {
        let value = if arena.as_int_const(a) == Some(0) {
            b
        } else if arena.as_int_const(b) == Some(0) {
            a
        } else {
            return None;
        };
        if let Some((word, bit)) = single_masked_bit(arena, value) {
            let nonzero = bit_nonzero(arena, word, bit);
            return Some(if op == CmpOp::Eq {
                arena.not(nonzero)
            } else {
                nonzero
            });
        }
    }
    if !ty.signed {
        return None;
    }
    let ac = arena.as_int_const(a);
    let bc = arena.as_int_const(b);
    let (word, negative) = match (op, ac, bc) {
        (CmpOp::Lt, Some(-1), _) | (CmpOp::Le, Some(0), _) => (b, false),
        (CmpOp::Gt, _, Some(-1)) | (CmpOp::Ge, _, Some(0)) => (a, false),
        (CmpOp::Gt, Some(0), _) | (CmpOp::Ge, Some(-1), _) => (b, true),
        (CmpOp::Lt, _, Some(0)) | (CmpOp::Le, _, Some(-1)) => (a, true),
        _ => return None,
    };
    let nonzero = bit_nonzero(arena, word, 31);
    Some(if negative {
        nonzero
    } else {
        arena.not(nonzero)
    })
}

/// Decode encoded-half constants selected by a symbolic predicate. All leaves
/// must be native constant words. Arbitrary integer/input expressions remain
/// opaque: this is a bit-preserving conditional decode, not a numeric bitcast.
pub(crate) fn decode_half_select(
    arena: &mut ExprArena,
    value: ExprId,
    high: bool,
) -> Result<ExprId, String> {
    fn decode(
        arena: &mut ExprArena,
        value: ExprId,
        high: bool,
        depth: u32,
    ) -> Result<ExprId, String> {
        if depth > 64 {
            return Err("encoded-half select nesting exceeds supported depth".into());
        }
        match *arena.node(value) {
            ExprNode::IntConst(word) => {
                let bits = ((word as u32) >> if high { 16 } else { 0 }) as u16;
                let sign = if bits & 0x8000 == 0 { 1.0 } else { -1.0 };
                let exponent = (bits >> 10) & 31;
                let fraction = bits & 1023;
                let decoded = if exponent == 31 {
                    if fraction != 0 {
                        return Err("half NaN outside real arithmetic model".into());
                    }
                    sign * f64::INFINITY
                } else if exponent == 0 {
                    sign * f64::from(fraction) * 2f64.powi(-24)
                } else {
                    sign * (1.0 + f64::from(fraction) / 1024.0)
                        * 2f64.powi(i32::from(exponent) - 15)
                };
                arena.float_from_f64(decoded).map_err(|e| e.to_string())
            }
            ExprNode::Select(mut condition, a, b) => {
                let mut a = decode(arena, a, high, depth + 1)?;
                let mut b = decode(arena, b, high, depth + 1)?;
                // Canonical bit test is nonzero; its native zero-test form
                // selects the opposite arms. Preserve the exact word identity.
                if let ExprNode::Not(inner) = *arena.node(condition) {
                    condition = inner;
                    std::mem::swap(&mut a, &mut b);
                }
                if volta_expr::structurally_equal(arena, a, arena, b) {
                    return Ok(a);
                }
                Ok(arena.select(condition, a, b))
            }
            _ => Err("symbolic half decode requires constant-word select leaves".into()),
        }
    }
    decode(arena, value, high, 0)
}

pub(crate) fn compare(
    arena: &mut ExprArena,
    ty: ScalarType,
    op: CmpOp,
    a: ExprId,
    b: ExprId,
) -> Result<ExprId, String> {
    let a = canonical_operand(arena, ty, a)?;
    let b = canonical_operand(arena, ty, b)?;
    if let ScalarType::Int(ty) = ty
        && let (Some(a), Some(b)) = (arena.as_int_const(a), arena.as_int_const(b))
    {
        let ordering = if ty.signed {
            a.cmp(&b)
        } else {
            low_bits(a, ty.bits).cmp(&low_bits(b, ty.bits))
        };
        let value = match op {
            CmpOp::Eq => ordering.is_eq(),
            CmpOp::Ne => !ordering.is_eq(),
            CmpOp::Lt => ordering.is_lt(),
            CmpOp::Le => !ordering.is_gt(),
            CmpOp::Gt => ordering.is_gt(),
            CmpOp::Ge => !ordering.is_lt(),
        };
        return Ok(arena.bool_val(value));
    }
    if let ScalarType::Int(ty) = ty
        && let Some(predicate) = compare_word_bit(arena, ty, op, a, b)
    {
        return Ok(predicate);
    }
    Ok(match op {
        CmpOp::Eq => arena.eq(a, b),
        CmpOp::Ne => arena.ne(a, b),
        CmpOp::Lt => arena.lt(a, b),
        CmpOp::Le => arena.le(a, b),
        CmpOp::Gt => arena.gt(a, b),
        CmpOp::Ge => arena.ge(a, b),
    })
}

/// Canonicalize concrete arms at the consuming type, independently of the
/// producer's sign convention. Predicates are ExprArena boolean expressions;
/// callers may use these to select data but may not coerce them into EXEC bits.
pub(crate) fn select(
    arena: &mut ExprArena,
    ty: ScalarType,
    condition: ExprId,
    a: ExprId,
    b: ExprId,
) -> Result<ExprId, String> {
    if matches!(
        arena.node(condition),
        ExprNode::IntConst(_) | ExprNode::RealConst(_)
    ) {
        return Err("scalar select requires a boolean condition".into());
    }
    let a = canonical_operand(arena, ty, a)?;
    let b = canonical_operand(arena, ty, b)?;

    Ok(arena.select(condition, a, b))
}

/// Decode one half of an encoded-word select. Preserve the existing generic
/// scalar-select representation; this packed path additionally canonicalizes
/// ordered compare/select to its exact real min/max identity.
pub(crate) fn select_packed_half(
    arena: &mut ExprArena,
    condition: ExprId,
    a: ExprId,
    b: ExprId,
) -> Result<ExprId, String> {
    let result = select(arena, ScalarType::Float(FloatType::F32), condition, a, b)?;
    let ExprNode::Select(_, a, b) = *arena.node(result) else {
        return Ok(result);
    };
    {
        // Ordered compare/select is min/max over the mathematical-real model.
        // Match both exact data arms: a predicate about one packed half must
        // never rewrite the other half merely because they share a word.
        let ordered = match *arena.node(condition) {
            ExprNode::Lt(left, right) | ExprNode::Le(left, right) => Some((left, right, false)),
            ExprNode::Gt(left, right) | ExprNode::Ge(left, right) => Some((left, right, true)),
            _ => None,
        };
        if let Some((left, right, greater)) = ordered {
            let same = |x, y| volta_expr::structurally_equal(arena, x, arena, y);
            let normal = same(a, left) && same(b, right);
            let reversed = same(a, right) && same(b, left);
            if normal || reversed {
                return Ok(if greater == normal {
                    arena.max(left, right)
                } else {
                    arena.min(left, right)
                });
            }
        }
    }
    Ok(result)
}

/// Decode a concrete register bit pattern at its actual format. F64 must use
/// both ordered register words, not an F32 conversion of either half.
pub(crate) fn decode_float(
    arena: &mut ExprArena,
    ty: FloatType,
    bits: u64,
) -> Result<ExprId, String> {
    let value = match ty {
        FloatType::F32 => f32::from_bits(bits as u32) as f64,
        FloatType::F64 => f64::from_bits(bits),
    };
    arena
        .float_from_f64(value)
        .map_err(|error| format!("{ty:?} bit pattern {bits:#x}: {error}"))
}

/// Inputs to these helpers are decoded mathematical data, never raw bits.
pub(crate) fn float_binary(arena: &mut ExprArena, op: FloatBinOp, a: ExprId, b: ExprId) -> ExprId {
    match op {
        FloatBinOp::Add => arena.add(a, b),
        FloatBinOp::Mul => arena.mul(a, b),
        FloatBinOp::Min => arena.min(a, b),
        FloatBinOp::Max => arena.max(a, b),
    }
}

pub(crate) fn float_unary(arena: &mut ExprArena, op: FloatUnOp, a: ExprId) -> ExprId {
    match op {
        FloatUnOp::Rcp => arena.rcp(a),
        FloatUnOp::Sqrt => arena.sqrt(a),
    }
}

pub(crate) fn float_fma(arena: &mut ExprArena, a: ExprId, b: ExprId, c: ExprId) -> ExprId {
    arena.fma(a, b, c)
}

/// PTX's portable operation uses the sign of the first argument and the
/// magnitude of the second. Native instruction/idiom dispatch must supply those
/// explicit roles rather than assuming the C library's operand order.
pub(crate) fn copysign(arena: &mut ExprArena, sign: ExprId, magnitude: ExprId) -> ExprId {
    let zero = arena.real(Real::zero());
    let non_negative = arena.ge(sign, zero);
    let magnitude = arena.abs(magnitude);
    let negative = arena.neg(magnitude);
    arena.select(non_negative, magnitude, negative)
}

pub(crate) fn clamp(arena: &mut ExprArena, mode: Clamp, value: ExprId) -> ExprId {
    if mode == Clamp::None {
        return value;
    }
    let zero = arena.real(Real::zero());
    let lower = arena.max(value, zero);
    if mode == Clamp::Relu {
        return lower;
    }
    let one = arena.real(Real::one());
    arena.min(lower, one)
}

/// CDNA4 §12.11 V_BFE_U32/I32: offset and length use their low five bits;
/// signed extraction first arithmetic-shifts the input, then sign-extends the
/// selected field. In particular, a field crossing bit31 retains sign fill.
pub(crate) fn bfe32(value: u32, offset: u32, width: u32, signed: bool) -> u32 {
    let offset = offset & 31;
    let width = width & 31;
    if width == 0 {
        return 0;
    }
    let shifted = if signed {
        ((value as i32) >> offset) as u32
    } else {
        value >> offset
    };
    let field = shifted & ((1u32 << width) - 1);
    if signed {
        (((field << (32 - width)) as i32) >> (32 - width)) as u32
    } else {
        field
    }
}

/// CDNA4 §12.11 V_BFI_B32: S0 is a mask, S1 supplies inserted bits, S2
/// supplies retained bits. It does not take PTX's offset/length operands.
pub(crate) fn bfi32(mask: u32, insert: u32, base: u32) -> u32 {
    (mask & insert) | (!mask & base)
}

#[cfg(test)]
mod tests {
    use super::*;
    use volta_expr::structurally_equal;

    fn ty(bits: u32, signed: bool) -> IntType {
        IntType { bits, signed }
    }
    fn signed_reference(bits: u32, value: u64) -> i64 {
        // Independent two's-complement interpretation using a wider integer.
        let modulus = 1i128 << bits;
        let value = value as i128 & (modulus - 1);
        (if value & (modulus / 2) != 0 {
            value - modulus
        } else {
            value
        }) as i64
    }

    #[test]
    fn concrete_integer_boundary_arithmetic_matches_wider_reference() {
        let words = [
            0u64,
            1,
            2,
            127,
            128,
            255,
            256,
            0x7fff,
            0x8000,
            0xffff,
            0x7fff_ffff,
            0x8000_0000,
            0xffff_ffff,
            0x7fff_ffff_ffff_ffff,
            0x8000_0000_0000_0000,
            u64::MAX,
        ];
        for bits in [8, 16, 32, 64] {
            for signed in [false, true] {
                let mut arena = ExprArena::new();
                let mask = (1u128 << bits) - 1;
                for a in words {
                    for b in words {
                        let ae = arena.int(a as i64);
                        let be = arena.int(b as i64);
                        for operation in [IntBinOp::Add, IntBinOp::Sub, IntBinOp::MulLo] {
                            let raw = match operation {
                                IntBinOp::Add => (a as u128 & mask) + (b as u128 & mask),
                                IntBinOp::Sub => {
                                    (a as u128 & mask) + (1u128 << bits) - (b as u128 & mask)
                                }
                                _ => (a as u128 & mask) * (b as u128 & mask),
                            } & mask;
                            let expected = if signed {
                                signed_reference(bits, raw as u64)
                            } else {
                                raw as u64 as i64
                            };
                            let result =
                                int_binary(&mut arena, ty(bits, signed), operation, ae, be)
                                    .unwrap();
                            assert_eq!(
                                arena.as_int_const(result),
                                Some(expected),
                                "{bits},signed={signed},{operation:?},a={a:#x},b={b:#x}"
                            );
                        }
                    }
                }
            }
        }
    }

    #[test]
    fn symbolic_ring_preserves_immediates_and_signed_unsigned_identity() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        for (op, constant) in [
            (IntBinOp::Add, -1),
            (IntBinOp::Sub, -7),
            (IntBinOp::MulLo, -3),
            (IntBinOp::Sub, 1),
        ] {
            let c = arena.int(constant);
            let signed = int_binary(&mut arena, ty(32, true), op, x, c).unwrap();
            let unsigned = int_binary(&mut arena, ty(32, false), op, x, c).unwrap();
            assert!(structurally_equal(&arena, signed, &arena, unsigned));
            let expected = match op {
                IntBinOp::Add => ExprNode::Sub(x, arena.int(1)),
                IntBinOp::Sub if constant < 0 => ExprNode::Add(x, arena.int(-constant)),
                IntBinOp::Sub => ExprNode::Sub(x, c),
                _ => ExprNode::Mul(x, c),
            };
            // Eager Add/Sub normalization may change the spelling, but must
            // never turn a negative literal into an unsigned4-billion term.
            let mut saw_unsigned = false;
            for index in [signed, unsigned] {
                arena.node(index).for_each_child(|child| {
                    saw_unsigned |= arena
                        .as_int_const(child)
                        .is_some_and(|v| v > i32::MAX as i64);
                });
            }
            assert!(!saw_unsigned, "{op:?}: {expected:?}");
        }
    }

    #[test]
    fn symbolic_integer_division_and_invalid_types_fail_closed() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        let two = arena.int(2);
        assert!(int_binary(&mut arena, ty(32, false), IntBinOp::Div, x, two).is_err());
        let real = arena.float_from_f64(1.5).unwrap();
        let boolean = arena.bool_val(true);
        assert!(int_binary(&mut arena, ty(32, false), IntBinOp::Add, real, two).is_err());
        assert!(int_binary(&mut arena, ty(32, false), IntBinOp::Add, boolean, two).is_err());
        for bits in [0, 1, 7, 33, 128] {
            assert!(canonical_int(-1, ty(bits, true)).is_err());
        }
        assert!(int_binary(&mut arena, ty(16, false), IntBinOp::Shl, two, two).is_err());
        let zero = arena.int(0);
        assert!(int_binary(&mut arena, ty(32, true), IntBinOp::Div, two, zero).is_err());
    }

    #[test]
    fn comparison_and_select_reinterpret_concrete_boundaries() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("input0");
        let neg = arena.int(-1);
        let zero = arena.int(0);
        let allones = int_binary(&mut arena, ty(32, false), IntBinOp::Xor, neg, zero).unwrap();
        assert_eq!(arena.as_int_const(allones), Some(4294967295));
        let a = compare(&mut arena, ScalarType::Int(ty(32, true)), CmpOp::Eq, x, neg).unwrap();
        let b = compare(
            &mut arena,
            ScalarType::Int(ty(32, true)),
            CmpOp::Eq,
            x,
            allones,
        )
        .unwrap();
        assert!(structurally_equal(&arena, a, &arena, b));
        let selected_a = select(&mut arena, ScalarType::Int(ty(32, false)), a, neg, zero).unwrap();
        let selected_b =
            select(&mut arena, ScalarType::Int(ty(32, false)), b, allones, zero).unwrap();
        assert!(structurally_equal(&arena, selected_a, &arena, selected_b));
        match arena.node(selected_a) {
            ExprNode::Select(_, yes, no) => {
                assert_eq!(arena.as_int_const(*yes), Some(4294967295));
                assert_eq!(arena.as_int_const(*no), Some(0));
            }
            other => panic!("expected symbolic selection,got{other:?}"),
        }
        assert!(
            select(
                &mut arena,
                ScalarType::Int(ty(32, false)),
                neg,
                zero,
                allones
            )
            .is_err()
        );
        for bits in [8, 16, 32, 64] {
            let unsigned = compare(
                &mut arena,
                ScalarType::Int(ty(bits, false)),
                CmpOp::Gt,
                neg,
                zero,
            )
            .unwrap();
            let signed = compare(
                &mut arena,
                ScalarType::Int(ty(bits, true)),
                CmpOp::Lt,
                neg,
                zero,
            )
            .unwrap();
            assert_eq!(arena.as_bool(unsigned), Some(true));
            assert_eq!(arena.as_bool(signed), Some(true));
        }
    }

    #[test]
    fn all_comparison_directions_and_float_bit_canonicalization() {
        let mut arena = ExprArena::new();
        let low = arena.int(4);
        let high = arena.int(7);
        for (op, expected) in [
            (CmpOp::Eq, false),
            (CmpOp::Ne, true),
            (CmpOp::Lt, true),
            (CmpOp::Le, true),
            (CmpOp::Gt, false),
            (CmpOp::Ge, false),
        ] {
            let result =
                compare(&mut arena, ScalarType::Int(ty(32, false)), op, low, high).unwrap();
            assert_eq!(arena.as_bool(result), Some(expected));
        }
        let one_bits = arena.int(0x3f800000);
        let one = arena.float_from_f64(1.0).unwrap();
        let same = compare(
            &mut arena,
            ScalarType::Float(FloatType::F32),
            CmpOp::Eq,
            one_bits,
            one,
        )
        .unwrap();
        assert_eq!(arena.as_bool(same), Some(true));
        let condition = arena.param_symbol("condition");
        let nan = arena.int(0x7fc00000);
        assert!(
            select(
                &mut arena,
                ScalarType::Float(FloatType::F32),
                condition,
                nan,
                one
            )
            .is_err()
        );
    }

    #[test]
    fn native_shift_count_wrap_and_signed_division_edges() {
        let mut arena = ExprArena::new();
        for bits in [32, 64] {
            for amount in [0, 1, 31, 32, 63, 64, 65, u32::MAX] {
                let input = if bits == 32 {
                    0x8000_0001u64
                } else {
                    0x8000_0000_0000_0001
                };
                let a = arena.int(input as i64);
                let b = arena.int(amount as i64);
                let masked = amount % bits;
                for (operation, expected) in [
                    (IntBinOp::Shl, input.wrapping_shl(masked)),
                    (IntBinOp::LShr, input >> masked),
                    (
                        IntBinOp::AShr,
                        (signed_reference(bits, input) >> masked) as u64,
                    ),
                ] {
                    let expected = if bits == 32 {
                        (expected as u32) as i64
                    } else {
                        expected as i64
                    };
                    let output = int_binary(&mut arena, ty(bits, false), operation, a, b).unwrap();
                    assert_eq!(
                        arena.as_int_const(output),
                        Some(expected),
                        "{bits}:{operation:?}:{amount}"
                    );
                }
            }
        }
        for bits in [8, 16, 32, 64] {
            let minimum = 1u64 << (bits - 1);
            let a = arena.int(minimum as i64);
            let minusone = arena.int(-1);
            let result =
                int_binary(&mut arena, ty(bits, true), IntBinOp::Div, a, minusone).unwrap();
            assert_eq!(
                arena.as_int_const(result),
                Some(signed_reference(bits, minimum))
            );
        }
        let a = arena.int(-7);
        let b = arena.int(3);
        let quotient = int_binary(&mut arena, ty(32, true), IntBinOp::Div, a, b).unwrap();
        assert_eq!(arena.as_int_const(quotient), Some(-2));
    }

    #[test]
    fn native_bitfields_match_independent_bit_by_bit_reference() {
        for value in [0u32, 1, u32::MAX, 0x80000000, 0x7fffffff, 0xdeadbeef] {
            for offset in 0..64 {
                for width in 0..64 {
                    for signed in [false, true] {
                        let off = offset % 32;
                        let len = width % 32;
                        let source_bit = |position: u32| {
                            if position < 32 {
                                (value >> position) & 1
                            } else if signed {
                                value >> 31
                            } else {
                                0
                            }
                        };
                        let sign = if signed && len != 0 {
                            source_bit(off + len - 1)
                        } else {
                            0
                        };
                        let mut expected = 0;
                        for bit in 0..32 {
                            let next = if bit < len {
                                source_bit(off + bit)
                            } else {
                                sign
                            };
                            expected |= next << bit;
                        }
                        assert_eq!(
                            bfe32(value, offset, width, signed),
                            expected,
                            "value={value:#x},offset={offset},width={width},signed={signed}"
                        );
                    }
                }
            }
            for mask in [0, u32::MAX, 0x80000000, 0x00ff00ff, 0x55555555] {
                let inserted = 0x12345678;
                let mut expected = 0;
                for bit in 0..32 {
                    let source = if mask & (1 << bit) != 0 {
                        inserted
                    } else {
                        value
                    };
                    expected |= ((source >> bit) & 1) << bit;
                }
                assert_eq!(bfi32(mask, inserted, value), expected);
            }
        }
        assert_eq!(bfe32(0x80000000, 31, 2, true), u32::MAX);
        assert_eq!(bfe32(0x80000000, 31, 2, false), 1);
        assert_eq!(bfe32(u32::MAX, 0, 32, false), 0);
    }

    #[test]
    fn binary64_decode_preserves_low_word_precision_and_rejects_nan() {
        let mut arena = ExprArena::new();
        for (bits, expected) in [
            (0x3ff0000000000001, 1.0000000000000002),
            (0x4008000000000000, 3.0),
            (1, f64::from_bits(1)),
            (0x8000000000000000, 0.0),
            (0x7ff0000000000000, f64::INFINITY),
        ] {
            let value = decode_float(&mut arena, FloatType::F64, bits).unwrap();
            assert_eq!(arena.as_f64(value), Some(expected));
        }
        for bits in [0x7ff8000000000000, 0x7ff0000000000001, 0xfff8000000000000] {
            assert!(decode_float(&mut arena, FloatType::F64, bits).is_err());
        }
        for bits in [0x7fc00000, 0x7f800001] {
            assert!(decode_float(&mut arena, FloatType::F32, bits).is_err());
        }
    }

    #[test]
    fn binary64_math_keeps_exact_rationals_instead_of_host_rounding() {
        let mut arena = ExprArena::new();
        let a = decode_float(&mut arena, FloatType::F64, 0.1f64.to_bits()).unwrap();
        let b = decode_float(&mut arena, FloatType::F64, 0.2f64.to_bits()).unwrap();
        let c = decode_float(&mut arena, FloatType::F64, 0.3f64.to_bits()).unwrap();
        let fma = float_fma(&mut arena, a, b, c);
        let product = float_binary(&mut arena, FloatBinOp::Mul, a, b);
        let separate = float_binary(&mut arena, FloatBinOp::Add, product, c);
        let rounded =
            decode_float(&mut arena, FloatType::F64, (0.1f64 * 0.2 + 0.3).to_bits()).unwrap();
        assert_eq!(arena.node(fma), arena.node(separate));
        assert_ne!(arena.node(fma), arena.node(rounded));
        let minimum = float_binary(&mut arena, FloatBinOp::Min, a, b);
        let maximum = float_binary(&mut arena, FloatBinOp::Max, a, b);
        assert_eq!(arena.node(minimum), arena.node(a));
        assert_eq!(arena.node(maximum), arena.node(b));
    }

    #[test]
    fn copysign_operand_roles_and_clamp_boundary_values() {
        let mut arena = ExprArena::new();
        for (sign, magnitude, expected) in [
            (2.0, 3.0, 3.0),
            (-2.0, 3.0, -3.0),
            (2.0, -3.0, 3.0),
            (-2.0, -3.0, -3.0),
            (0.0, -3.0, 3.0),
        ] {
            let sign = arena.float_from_f64(sign).unwrap();
            let magnitude = arena.float_from_f64(magnitude).unwrap();
            let result = copysign(&mut arena, sign, magnitude);
            assert_eq!(arena.as_f64(result), Some(expected));
        }
        for input in [-2.0f64, 0.0, 0.25, 1.0, 3.0] {
            let expression = arena.float_from_f64(input).unwrap();
            for mode in [Clamp::None, Clamp::Relu, Clamp::Sat] {
                let expected = match mode {
                    Clamp::None => input,
                    Clamp::Relu => input.max(0.0),
                    Clamp::Sat => input.clamp(0.0, 1.0),
                };
                let output = clamp(&mut arena, mode, expression);
                assert_eq!(arena.as_f64(output), Some(expected));
            }
        }
    }

    #[test]
    fn unary_math_builds_shared_nodes_without_ieee_approximation() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        for (operation, expected) in [
            (FloatUnOp::Rcp, ExprNode::Rcp(x)),
            (FloatUnOp::Sqrt, ExprNode::Sqrt(x)),
        ] {
            let output = float_unary(&mut arena, operation, x);
            assert_eq!(arena.node(output), &expected);
        }
    }
}

#[cfg(test)]
mod bit_expression_tests {
    use super::*;
    use volta_expr::structurally_equal;

    fn evaluate_word(
        arena: &ExprArena,
        expression: ExprId,
        x: ExprId,
        xvalue: u64,
        y: ExprId,
        yvalue: u64,
    ) -> u64 {
        if expression == x {
            return xvalue;
        }
        if expression == y {
            return yvalue;
        }
        let eval = |value| evaluate_word(arena, value, x, xvalue, y, yvalue);
        match arena.node(expression) {
            ExprNode::IntConst(value) => *value as u64,
            ExprNode::BitAnd(a, b) => eval(*a) & eval(*b),
            ExprNode::BitOr(a, b) => eval(*a) | eval(*b),
            ExprNode::BitXor(a, b) => eval(*a) ^ eval(*b),
            ExprNode::Shl(a, b) => eval(*a).wrapping_shl(eval(*b) as u32),
            ExprNode::LShr(a, b) => eval(*a).wrapping_shr(eval(*b) as u32),
            ExprNode::Shr(a, b) => (eval(*a) as i64).wrapping_shr(eval(*b) as u32) as u64,
            node => panic!("unexpected node in integer word expression:{node:?}"),
        }
    }

    #[test]
    fn symbolic_native_bit_operations_match_independent_word_execution() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        let y = arena.param_symbol("y");
        for bits in [32, 64] {
            for signed in [false, true] {
                let ty = IntType { bits, signed };
                for op in [
                    IntBinOp::And,
                    IntBinOp::Or,
                    IntBinOp::Xor,
                    IntBinOp::Shl,
                    IntBinOp::LShr,
                    IntBinOp::AShr,
                ] {
                    let expression = int_binary(&mut arena, ty, op, x, y).unwrap();
                    for input in [
                        0u64,
                        1,
                        0x80000001,
                        0xffffffff,
                        0x8000000000000001,
                        u64::MAX,
                    ] {
                        for operand in [0u64, 1, 31, 32, 63, 64, 65, 0xdeadbeef, u64::MAX] {
                            let a = if bits == 32 {
                                input as u32 as u64
                            } else {
                                input
                            };
                            let b = if bits == 32 {
                                operand as u32 as u64
                            } else {
                                operand
                            };
                            let shift = (b as u32) % bits;
                            let value = match op {
                                IntBinOp::And => a & b,
                                IntBinOp::Or => a | b,
                                IntBinOp::Xor => a ^ b,
                                IntBinOp::Shl => a.wrapping_shl(shift),
                                IntBinOp::LShr => a >> shift,
                                _ => {
                                    if bits == 32 {
                                        ((a as i32) >> shift) as i64 as u64
                                    } else {
                                        ((a as i64) >> shift) as u64
                                    }
                                }
                            };
                            let expected = if bits == 32 {
                                if signed {
                                    value as u32 as i32 as i64 as u64
                                } else {
                                    value as u32 as u64
                                }
                            } else {
                                value
                            };
                            assert_eq!(
                                evaluate_word(&arena, expression, x, input, y, operand),
                                expected,
                                "{ty:?}:{op:?}:input={input:#x}:operand={operand:#x}"
                            );
                        }
                    }
                }
            }
        }
    }

    #[test]
    fn sign_bit_xor_is_an_opaque_bit_operation_distinct_from_negation() {
        let mut arena = ExprArena::new();
        let x = arena.param_symbol("x");
        let mask = arena.int(0x80000000);
        let xor = int_binary(
            &mut arena,
            IntType {
                bits: 32,
                signed: false,
            },
            IntBinOp::Xor,
            x,
            mask,
        )
        .unwrap();
        let negation = arena.neg(x);
        assert!(!structurally_equal(&arena, xor, &arena, negation));
        let ignored = arena.param_symbol("unused");
        assert_eq!(evaluate_word(&arena, xor, x, 1, ignored, 0), 0x80000001);
        let minus_one = arena.int(-1);
        let all_ones = arena.int(0xffffffff);
        let a = int_binary(
            &mut arena,
            IntType {
                bits: 32,
                signed: false,
            },
            IntBinOp::And,
            x,
            minus_one,
        )
        .unwrap();
        let b = int_binary(
            &mut arena,
            IntType {
                bits: 32,
                signed: false,
            },
            IntBinOp::And,
            x,
            all_ones,
        )
        .unwrap();
        assert!(structurally_equal(&arena, a, &arena, b));
    }
    #[test]
    fn encoded_half_selects_require_constant_leaves_and_preserve_all_word_bits() {
        fn predicate(arena: &ExprArena, expression: ExprId, input: ExprId, bits: u32) -> bool {
            match *arena.node(expression) {
                ExprNode::Not(inner) => !predicate(arena, inner, input, bits),
                ExprNode::Ne(a, b) => {
                    evaluate_word(arena, a, input, u64::from(bits), input, u64::from(bits))
                        != evaluate_word(arena, b, input, u64::from(bits), input, u64::from(bits))
                }
                ExprNode::BoolConst(value) => value,
                ref node => panic!("unexpected predicate: {node:?}"),
            }
        }
        let mut arena = ExprArena::new();
        let word = arena.param_symbol("word");
        for bit in 0..32 {
            let zero = arena.int(0);
            let condition = if bit == 31 {
                let minus_one = arena.int(-1);
                compare(
                    &mut arena,
                    ScalarType::Int(IntType {
                        bits: 32,
                        signed: true,
                    }),
                    CmpOp::Lt,
                    minus_one,
                    word,
                )
                .unwrap()
            } else {
                let mask = arena.int(1i64 << bit);
                let masked = int_binary(
                    &mut arena,
                    IntType {
                        bits: 32,
                        signed: false,
                    },
                    IntBinOp::And,
                    word,
                    mask,
                )
                .unwrap();
                compare(
                    &mut arena,
                    ScalarType::Int(IntType {
                        bits: 32,
                        signed: false,
                    }),
                    CmpOp::Eq,
                    masked,
                    zero,
                )
                .unwrap()
            };
            let positive = arena.int(0x3c00);
            let negative = arena.int(0xbc00);
            let selected = arena.select(condition, negative, positive);
            let decoded = decode_half_select(&mut arena, selected, false).unwrap();
            let ExprNode::Select(nonzero, a, b) = *arena.node(decoded) else {
                panic!("missing select")
            };
            assert_eq!(arena.as_f64(a), Some(1.));
            assert_eq!(arena.as_f64(b), Some(-1.));
            for value in [
                0,
                1,
                u32::MAX,
                0x80000000,
                0x7fffffff,
                0xdeadbeef,
                1u32 << bit,
            ] {
                assert_eq!(
                    predicate(&arena, nonzero, word, value),
                    value & (1 << bit) != 0
                );
            }
            let upper = decode_half_select(&mut arena, selected, true).unwrap();
            assert_eq!(arena.as_f64(upper), Some(0.));
        }
        assert!(decode_half_select(&mut arena, word, false).is_err());
        let condition = arena.param_symbol("predicate");
        let constant = arena.int(0x3c00);
        let arbitrary = arena.select(condition, word, constant);
        assert!(decode_half_select(&mut arena, arbitrary, false).is_err());
        let nan = arena.int(0x7e00);
        assert!(decode_half_select(&mut arena, nan, false).is_err());
    }
}
