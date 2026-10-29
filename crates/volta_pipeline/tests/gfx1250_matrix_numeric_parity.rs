//! Original logical M128 matrix payloads with explicit native N16/K32 padding.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::GraphConclusion;
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};
const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-matrix-numeric.s");
fn config(columns: u64) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((256, 1, 1));
    cfg.arrays = [
        ("out", 0x10000, columns),
        ("native", 0x40000, columns.div_ceil(16) * 16),
    ]
    .map(|(name, base, pitch)| ArrayDef {
        name: name.into(),
        base,
        elem_width: 4,
        len: 128 * pitch,
        kind: ArrayKind::Output,
    })
    .to_vec();
    cfg.params = ["out", "native"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .to_vec();
    cfg
}
fn run(kernel: &str, columns: u64) -> SymbolicOutputs {
    let module = frontend::parse(SOURCE).expect("actual compiler module parses");
    let checked = native_common::check(SOURCE, &module, Some(kernel), config(columns)).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn expected(columns: u64, cell00: i64, seed: i64) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let outputs = [("out", columns), ("native", columns.div_ceil(16) * 16)]
        .into_iter()
        .map(|(name, pitch)| {
            let values = (0..128 * pitch)
                .map(|i| {
                    let value = if i == 0 {
                        cell00
                    } else if i % pitch < columns {
                        seed
                    } else {
                        0
                    };
                    (i, arena.int(value))
                })
                .collect();
            (name.into(), values)
        })
        .collect();
    SymbolicOutputs { arena, outputs }
}
fn equal(actual: &SymbolicOutputs, expected: &SymbolicOutputs) {
    assert_eq!(actual.outputs.len(), 2);
    for (name, values) in &expected.outputs {
        let got = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
        assert_eq!(
            got.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            values.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            "complete {name} coordinates"
        );
    }
    let verdict =
        check_output_equivalence(actual, expected, &["out".into(), "native".into()]).unwrap();
    assert!(matches!(verdict, EquivOutcome::Equivalent), "{verdict:?}");
}
fn original_cell(kernel: &str, source: &str, golden: &str, threads: u32) {
    let actual = run(kernel, 8);
    let mut cfg = AnalysisConfig::new((threads, 1, 1));
    cfg.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    }];
    cfg.params = vec![ParamValue::ArrayPtr("out".into())];
    let module = Parser::new(source.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let baseline = volta_ptx_analysis::analyze(&module, Some("k"), cfg).unwrap();
    let expected = baseline.symbolic_outputs().unwrap();
    assert_eq!(expected.outputs.len(), 1);
    assert_eq!(expected.outputs[0].1.len(), 1);
    let (index, value) = expected.outputs[0].1[0];
    assert_eq!(index, 0);
    assert_eq!(
        format!("out[0] = {}", expected.arena.display_expr(value)),
        golden.trim()
    );
    // The native full1024 logical /2048 padded cells are checked separately.
    // This explicit projection reproduces the original single exported cell.
    let mut projection = actual.clone();
    projection.outputs.retain(|(name, _)| name == "out");
    projection.outputs[0].1.retain(|(i, _)| *i == 0);
    assert!(matches!(
        check_output_equivalence(&projection, expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
#[test]
fn native_numeric_projections_retain_all_four_original_single_cell_goldens() {
    for (kernel, source, golden, threads) in [
        (
            "matrix_numeric136",
            include_str!("ptx/success/tcgen05_mma_numeric_correctness.ptx"),
            include_str!("ptx/success/tcgen05_mma_numeric_correctness.out"),
            32,
        ),
        (
            "matrix_numeric136",
            include_str!(
                "ptx/success/tcgen05_mma_without_an_explicit_disable_output_lane_mask.ptx"
            ),
            include_str!(
                "ptx/success/tcgen05_mma_without_an_explicit_disable_output_lane_mask.out"
            ),
            32,
        ),
        (
            "matrix_raw17",
            include_str!("ptx/success/tcgen05_mma_decodes_raw_operand_and_accumulator_bits.ptx"),
            include_str!("ptx/success/tcgen05_mma_decodes_raw_operand_and_accumulator_bits.out"),
            128,
        ),
        (
            "matrix_mixed408",
            include_str!("ptx/success/tcgen05_mma_kind_f8f6f4_numeric_correctness.ptx"),
            include_str!("ptx/success/tcgen05_mma_kind_f8f6f4_numeric_correctness.out"),
            32,
        ),
    ] {
        original_cell(kernel, source, golden, threads);
    }
}
#[test]
fn f16_m128n8k16_retains_136_and_all_original_and_padded_coordinates() {
    equal(
        &run("matrix_numeric136", 8),
        &expected(8, (1..=16).sum(), 0),
    );
}
#[test]
fn raw_half_operand_and_f32_c_seed_retain_17_and_every_logical_c_cell() {
    equal(&run("matrix_raw17", 8), &expected(8, 16 + 1, 1));
}
#[test]
fn explicit_unswizzled_m128n8_zero_payload_completes_all_native_coordinates() {
    equal(&run("matrix_zero_128x8", 8), &expected(8, 0, 0));
}
#[test]
fn real_descriptor_logical_m128n256_shape_keeps_all_32768_zero_outputs() {
    equal(&run("matrix_zero_128x256", 256), &expected(256, 0, 0));
}
#[test]
fn mixed_e4m3_e5m2_m128n8k32_keeps_original_core_gap_and_408() {
    equal(
        &run("matrix_mixed408", 8),
        &expected(8, (1..=16).map(|k| k + 2 * k).sum(), 0),
    );
}
#[test]
fn decoding_the_same_b_bytes_as_e4m3_changes_only_the_actual_408_cell_to_476() {
    let correct = run("matrix_mixed408", 8);
    let wrong = run("matrix_wrong_b476", 8);
    equal(&wrong, &expected(8, 476, 0));
    let EquivOutcome::NotEquivalent { mismatches } =
        check_output_equivalence(&correct, &wrong, &["out".into(), "native".into()]).unwrap()
    else {
        panic!("different physical FP8 format was treated as the same number");
    };
    assert_eq!(
        mismatches
            .iter()
            .map(|m| (m.array.as_str(), m.index))
            .collect::<Vec<_>>(),
        [("out", 0), ("native", 0)]
    );
}
#[test]
fn disabling_the_first_logical_output_cannot_satisfy_the_complete_footprint() {
    let actual = run("matrix_disabled_first_output", 8);
    let out = &actual.outputs.iter().find(|(n, _)| n == "out").unwrap().1;
    assert_eq!(
        out.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
        (1..1024).collect::<Vec<_>>()
    );
    // All padded computations still match; only output0 was suppressed.
    let mut known = expected(8, 136, 0);
    known.outputs[0].1.retain(|(i, _)| *i != 0);
    equal(&actual, &known);
    let complete = expected(8, 136, 0);
    assert!(!matches!(
        check_output_equivalence(&actual, &complete, &["out".into()]),
        Ok(EquivOutcome::Equivalent)
    ));
}
#[test]
fn disabled_lds_producer_leaves_the_exact_consumer_cell_uninitialized() {
    let module = frontend::parse(SOURCE).unwrap();
    let checked =
        native_common::check(SOURCE, &module, Some("matrix_disabled_lds_read"), config(8)).unwrap();
    let error = checked.analysis.symbolic_outputs().unwrap_err();
    assert!(
        matches!(error, OutputsUnavailable::Aborted(EvalError::Invalid {
        wave: 0, lane: Some(0), what, ..
    }) if what == "LDS 0x1000: uninitialized byte at 0x1000"),
        "{error}"
    );
    assert!(!matches!(
        checked.checks.conclusion(),
        GraphConclusion::Verified
    ));
}
#[test]
fn assembler_legal_unmodeled_matrix_b_reuse_never_becomes_a_default_wmma() {
    const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-matrix-unmodeled.s");
    assert!(SOURCE.contains("matrix_b_reuse"));
    let error = frontend::parse(SOURCE)
        .expect_err("unmodeled matrix mode cannot be erased")
        .to_string();
    assert!(
        error.contains("v_wmma_f32_16x16x32_f16") && error.contains("expects 4 operands, got 5"),
        "{error}"
    );
}
