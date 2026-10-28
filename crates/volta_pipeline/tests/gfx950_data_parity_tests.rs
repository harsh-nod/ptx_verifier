//! Explicit native data properties mapped to the original Rust assertions.
//! See portable-data/cases.json for source and target-specific differences.
mod gfx950_common;
use std::path::Path;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph::Space;
use volta_graph_check::GraphConclusion;
use volta_graph_check::domain::ConflictKind;

fn source(name: &str) -> String {
    std::fs::read_to_string(
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../../tests/gfx950")
            .join(name),
    )
    .unwrap()
}
fn config(input_width: u64, input_len: u64, output_width: u64, output_len: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: input_width,
            len: input_len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: output_width,
            len: output_len,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}
fn check(name: &str, cfg: AnalysisConfig) -> gfx950_common::Checked {
    let text = source(name);
    let module = frontend::parse(&text).unwrap();
    gfx950_common::check(&text, &module, Some("k"), cfg).unwrap()
}
fn complete(name: &str, cfg: AnalysisConfig) -> SymbolicOutputs {
    let checked = check(name, cfg);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{name}: {:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn expected(
    count: u64,
    mut element: impl FnMut(&mut ExprArena, ExprId, u64) -> ExprId,
) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let elements = (0..count)
        .map(|index| {
            let input = arena.input_element(x, index);
            (index, element(&mut arena, input, index))
        })
        .collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    }
}
fn equivalent(actual: &SymbolicOutputs, expected: &SymbolicOutputs) {
    assert_eq!(actual.outputs[0].1.len(), expected.outputs[0].1.len());
    let result = check_output_equivalence(actual, expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}
fn rejected(name: &str, cfg: AnalysisConfig, fragment: &str) {
    let checked = check(name, cfg);
    let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(error.contains(fragment), "{name}: {error}");
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

#[test]
fn all_seven_symbolic_integer_ring_rows_preserve_signed_immediates() {
    for (name, operation, value) in [
        ("ring_add_s32_neg1", 0, -1),
        ("ring_add_u32_neg1", 0, -1),
        ("ring_sub_s32_neg7", 1, -7),
        ("ring_sub_u32_neg7", 1, -7),
        ("ring_sub_u32_1", 1, 1),
        ("ring_mul_lo_s32_neg3", 2, -3),
        ("ring_mul_lo_u32_neg3", 2, -3),
    ] {
        let actual = complete(&format!("portable-data/{name}.s"), config(4, 1, 4, 1));
        let reference = expected(1, |arena, x, _| {
            let value = arena.int(value);
            match operation {
                0 => arena.add(x, value),
                1 => arena.sub(x, value),
                _ => arena.mul(x, value),
            }
        });
        equivalent(&actual, &reference);
    }
}

#[test]
fn both_symbolic_setp_selp_rows_canonicalize_signed_minus_one_and_complement() {
    let reference = expected(1, |arena, x, _| {
        let minus_one = arena.int(-1);
        let condition = arena.eq(x, minus_one);
        let ones = arena.int(u32::MAX as i64);
        let zero = arena.int(0);
        arena.select(condition, ones, zero)
    });
    for name in ["select_signed_minus_one", "select_computed_complement"] {
        equivalent(
            &complete(&format!("portable-data/{name}.s"), config(4, 1, 4, 1)),
            &reference,
        );
    }
}

#[test]
fn native_half_packing_order_and_relu_have_independent_typed_references() {
    let actual = complete("portable-data/pack_halves_order.s", config(4, 1, 2, 2));
    equivalent(
        &actual,
        &expected(2, |arena, _, index| {
            arena.float_from_f64([2.5, 1.5][index as usize]).unwrap()
        }),
    );
    let actual = complete("portable-data/relu_half_identity.s", config(4, 1, 2, 1));
    equivalent(
        &actual,
        &expected(1, |arena, x, _| {
            let zero = arena.int(0);
            arena.max(x, zero)
        }),
    );
}

#[test]
fn concrete_fp8_pairs_decode_low_high_and_relu_independently() {
    for (name, values) in [
        ("e4m3_concrete_pair", [1, -1]),
        ("e4m3_concrete_pair_relu", [1, 0]),
    ] {
        let actual = complete(&format!("portable-matrix/{name}.s"), config(4, 1, 4, 2));
        equivalent(
            &actual,
            &expected(2, |arena, _, index| arena.int(values[index as usize])),
        );
    }
    rejected("portable-data/fp8_nan_pair.s", config(4, 1, 4, 2), "NaN");
}

#[test]
fn symbolic_fp8_bytes_survive_vector_pair_and_native_low16_truncation() {
    let actual = complete("portable-matrix/e4m3_vector_bytes.s", config(1, 8, 4, 4));
    equivalent(&actual, &expected(4, |_, x, _| x));
    let mut cfg = config(1, 4, 4, 2);
    cfg.dynamic_shared_bytes = 8;
    let actual = complete("portable-data/fp8_truncate_quad.s", cfg);
    equivalent(
        &actual,
        &expected(2, |arena, _, index| {
            let name = arena.intern_string("x");
            arena.input_element(name, index * 2)
        }),
    );
    let actual = complete("portable-data/fp8_scalar_byte.s", config(1, 1, 4, 1));
    equivalent(&actual, &expected(1, |_, x, _| x));
    let mut cfg = config(1, 2, 4, 2);
    cfg.dynamic_shared_bytes = 16;
    let actual = complete(
        "portable-scalar/byte_pair_round_trips_through_shared_memory_at_native_16_bit_width.s",
        cfg,
    );
    equivalent(&actual, &expected(2, |_, x, _| x));
}

#[test]
fn nonreal_literals_raw_bits_parameters_and_zero_division_have_no_positive_result() {
    for name in ["f32_nan_bits", "f32_nan_literal"] {
        rejected(
            &format!("portable-data/{name}.s"),
            config(4, 1, 4, 1),
            "NaN",
        );
    }
    rejected(
        "portable-data/zero_rcp_f32.s",
        config(4, 1, 4, 1),
        "undefined",
    );
    let text =
        source("../../crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-mixed-byvalue.s");
    let module = frontend::parse(&text).unwrap();
    let mut cfg = config(4, 1, 4, 4);
    cfg.arrays.remove(0);
    cfg.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Float(f64::NAN),
        ParamValue::Float(0.5),
        ParamValue::Int(4),
        ParamValue::Int(-3),
        ParamValue::Int(250),
    ];
    let error = gfx950_common::check(&text, &module, Some("mixed_byvalue"), cfg)
        .err()
        .expect("NaN parameter is invalid");
    assert!(error.to_string().contains("NaN"), "{error}");
}

#[test]
fn symbolic_branches_and_observable_narrow_scalar_bitcasts_remain_closed() {
    rejected(
        "portable-data/symbolic_branch.s",
        config(4, 1, 4, 1),
        "symbolic",
    );
    rejected(
        "portable-data/symbolic_narrow_store.s",
        config(4, 1, 1, 1),
        "symbolic",
    );
}

#[test]
fn native_sign_extended_byte_load_is_numeric_and_cannot_be_reinterpreted_as_fp8() {
    let actual = complete("portable-data/signed_byte_extension.s", config(1, 1, 4, 1));
    equivalent(&actual, &expected(1, |_, x, _| x));
    let text = source("portable-data/signed_byte_extension.s")
        .replace("v_cvt_f32_i32 v8,v4", "v_cvt_f32_fp8 v8,v4");
    let module = frontend::parse(&text).unwrap();
    let checked = gfx950_common::check(&text, &module, Some("k"), config(1, 1, 4, 1)).unwrap();
    assert!(
        checked
            .analysis
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("non-FP8")
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

#[test]
fn native_integer_floor_does_not_become_rational_division_or_roundtrip_identity() {
    let actual = complete("portable-data/integer_floor_doubled.s", config(4, 1, 4, 1));
    let identity = expected(1, |_, x, _| x);
    assert!(!matches!(
        check_output_equivalence(&actual, &identity, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    let mut cfg = config(4, 8, 4, 8);
    cfg.block_dim = (8, 1, 1);
    cfg.arrays[0].kind = ArrayKind::IndexInput;
    let actual = complete("portable-data/integer_floor_doubled.s", cfg);
    equivalent(
        &actual,
        &expected(8, |arena, _, index| arena.int((index / 2 * 2) as i64)),
    );
    let actual = complete(
        "portable-data/concrete_integer_division.s",
        config(4, 1, 4, 1),
    );
    equivalent(&actual, &expected(1, |arena, _, _| arena.int(3)));
}

#[test]
fn native_predicate_permute_idiom_retains_the_same_value_shared_write_race() {
    let mut cfg = config(4, 1, 4, 1);
    cfg.block_dim = (128, 1, 1);
    cfg.dynamic_shared_bytes = 4;
    let checked = check("portable-data/predicate_permute_side_effect_race.s", cfg);
    checked.analysis.symbolic_outputs().unwrap();
    let violations = checked
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        violations
            .iter()
            .any(|w| w.kind == ConflictKind::WriteWrite && w.location.space == Space::Shared),
        "{violations:?}"
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}
