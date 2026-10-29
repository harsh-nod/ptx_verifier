//! Packed integer inputs retain their symbolic word identity in public specs.
use std::collections::HashMap;

use volta_equivalence::{EquivCheckOptions, EquivOutcome, check_output_equivalence_with};
use volta_expr::{ExprArena, ExprNode, SymbolicOutputs};
use volta_spec::{SpecError, instantiate, parse_spec, unfold};

fn expand(source: &str, n: u64) -> Result<SymbolicOutputs, SpecError> {
    let parsed = parse_spec(source).unwrap();
    let (env, outputs) = instantiate(&parsed, &HashMap::from([("N".into(), n)])).unwrap();
    unfold(&outputs, &env, 0)
}

#[test]
fn concrete_words_use_all_low_32_bits_including_signed_boundaries() {
    for word in [0u32, 1, 2, 0x4000_0000, 0x7fff_ffff, 0x8000_0000, u32::MAX] {
        let source = format!("dim N; array out[N]; out[i] = bit_sign({word}, i);");
        let output = expand(&source, 32).unwrap();
        for &(bit, value) in &output.outputs[0].1 {
            let expected = if word & (1u32 << bit) != 0 { 1 } else { -1 };
            assert_eq!(
                output.arena.as_i64(value),
                Some(expected),
                "{word:#x}, bit{bit}"
            );
        }
    }
}

#[test]
fn arbitrary_packed_words_match_the_independent_logical_shift_definition() {
    let actual = expand(
        "dim N; array words[N]; array out[N]; out[i] = bit_sign(words[i / 32], i % 32);",
        64,
    )
    .unwrap();
    let mut arena = ExprArena::new();
    let words = arena.intern_string("words");
    let mut values = Vec::new();
    for i in 0..64 {
        let word = arena.input_element(words, i / 32);
        let bit = arena.int((i % 32) as i64);
        let shifted = arena.lshr(word, bit);
        let one = arena.int(1);
        let selected = arena.bit_and(shifted, one);
        let zero = arena.int(0);
        let condition = arena.ne(selected, zero);
        let negative = arena.int(-1);
        let value = arena.select(condition, one, negative);
        values.push((i, value));
    }
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    let report = check_output_equivalence_with(
        &actual,
        &expected,
        &["out".into()],
        &EquivCheckOptions::default(),
    )
    .unwrap();
    assert!(matches!(report.outcome, EquivOutcome::Equivalent));
    assert_eq!(report.elements_checked, 64);
    assert!(matches!(
        actual.arena.node(actual.outputs[0].1[31].1),
        ExprNode::Select(_, _, _)
    ));
}

#[test]
fn reduction_memo_keeps_free_variables_used_only_in_bit_positions() {
    let actual = expand(
        "dim N; array out[N]; out[i] = sum(k in 0..2, bit_sign(3, i + k));",
        2,
    )
    .unwrap();
    let values: Vec<_> = actual.outputs[0]
        .1
        .iter()
        .map(|(_, value)| actual.arena.as_i64(*value))
        .collect();
    assert_eq!(values, [Some(2), Some(0)]);
}

#[test]
fn invalid_positions_and_integer_index_arithmetic_fail_without_shifts() {
    for position in ["32", "0 - 1", "31 + i"] {
        let source = format!("dim N; array out[N]; out[i] = bit_sign(1, {position});");
        assert!(matches!(
            expand(&source, 2),
            Err(SpecError::BitIndexOutOfBounds(_))
        ));
    }
    for position in [
        "i % 0",
        "i / 0",
        "9223372036854775807 + i",
        "18446744073709551615 + 1",
    ] {
        let source = format!("dim N; array out[N]; out[i] = bit_sign(1, {position});");
        let error = expand(&source, 2).unwrap_err();
        assert!(matches!(
            error,
            SpecError::IndexArithmetic | SpecError::BitIndexOutOfBounds(_)
        ));
    }
    assert!(
        matches!(expand("dim N; array out[N]; out[i] = bit_sign(1, missing);", 1),
        Err(SpecError::UnboundVar(name)) if name == "missing")
    );
}

#[test]
fn bit_position_is_concrete_index_syntax_not_a_symbolic_value() {
    for position in ["words[i]", "0.5", "exp(i)"] {
        let source = format!(
            "dim N; array words[N]; array out[N]; out[i] = bit_sign(words[i], {position});"
        );
        assert!(parse_spec(&source).is_err());
    }
    for body in ["bit_sign(1)", "bit_sign(1, 0, 1)", "bit_sign()"] {
        assert!(parse_spec(&format!("dim N; array out[N]; out[i] = {body};")).is_err());
    }
}
