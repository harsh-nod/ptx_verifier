//! Complete native LDS gathers, strided WMMA products and original C fragments.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::GraphConclusion;
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-matrix-layout.s");
fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}
fn config(arrays: Vec<ArrayDef>) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((32, 1, 1));
    cfg.params = arrays
        .iter()
        .map(|a| ParamValue::ArrayPtr(a.name.clone()))
        .collect();
    cfg.arrays = arrays;
    cfg
}
fn execute(kernel: &str, cfg: AnalysisConfig) -> SymbolicOutputs {
    let module = frontend::parse(SOURCE).expect("genuine compiler output parses");
    let checked = native_common::check(SOURCE, &module, Some(kernel), cfg).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn equivalent(actual: &SymbolicOutputs, expected: &SymbolicOutputs) {
    assert_eq!(actual.outputs.len(), expected.outputs.len());
    for (name, values) in &expected.outputs {
        let found = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
        assert_eq!(
            found.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            values.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            "complete {name} coordinates"
        );
    }
    let names = expected
        .outputs
        .iter()
        .map(|(n, _)| n.clone())
        .collect::<Vec<_>>();
    let result = check_output_equivalence(actual, expected, &names).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}
fn strided(kernel: &str) {
    let actual = execute(kernel, stride_config());
    let mut arena = ExprArena::new();
    let input = arena.intern_string("input");
    let fragments = (0..256)
        .map(|i| (i, arena.input_element(input, i)))
        .collect();
    let mut values = Vec::new();
    for row in 0..16 {
        let mut sum = arena.int(0);
        for k in 0..16 {
            let x = arena.input_element(input, row * 16 + k);
            let weight = arena.int(k as i64 + 1);
            let product = arena.mul(x, weight);
            sum = arena.add(sum, product);
        }
        for column in 0..16 {
            values.push((row * 16 + column, sum));
        }
    }
    equivalent(
        &actual,
        &SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), values), ("fragment".into(), fragments)],
        },
    );
}
fn stride_config() -> AnalysisConfig {
    config(vec![
        array("input", 0x10000, 2, 256, ArrayKind::Input),
        array("out", 0x20000, 4, 256, ArrayKind::Output),
        array("fragment", 0x30000, 2, 256, ArrayKind::Output),
    ])
}
#[test]
fn contiguous_32_byte_rows_preserve_all_gathered_halves_and_256_products() {
    strided("matrix_stride32");
}
#[test]
fn skewed_48_byte_rows_preserve_all_gathered_halves_and_256_products() {
    strided("matrix_stride48");
}
#[test]
fn padded_64_byte_rows_preserve_all_gathered_halves_and_256_products() {
    strided("matrix_stride64");
}
#[test]
fn native_40_byte_halfword_pitch_does_not_import_ptx_collective_stride_alignment() {
    strided("matrix_stride40");
}
#[test]
fn overlapping_16_byte_producer_rows_complete_but_report_real_shared_write_conflicts() {
    let module = frontend::parse(SOURCE).unwrap();
    let checked =
        native_common::check(SOURCE, &module, Some("matrix_stride16"), stride_config()).unwrap();
    assert!(
        checked.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        checked.analysis.symbolic_outputs()
    );
    use volta_graph_check::{Property, Verdict};
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        checked.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail
    );
    assert!(
        checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(
                |v| v.kind == volta_graph_check::domain::ConflictKind::WriteWrite
                    && v.location.space == volta_graph::Space::Shared
            )
    );
}
#[test]
fn native_halfword_alignment_is_checked_at_actual_flat_read_and_write() {
    for opcode in ["flat_load_u16", "flat_store_b16"] {
        let begin = SOURCE.find("\nmatrix_stride32:").unwrap();
        let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
        let at = begin + SOURCE[begin..end].find(opcode).unwrap();
        let tail = at + SOURCE[at..].find('\n').unwrap();
        let mut bad = SOURCE.to_owned();
        bad.insert_str(tail, " offset:1");
        let module = frontend::parse(&bad).unwrap();
        let checked =
            native_common::check(&bad, &module, Some("matrix_stride32"), stride_config()).unwrap();
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("misaligned"), "{opcode}: {error}");
        assert!(!matches!(
            checked.checks.conclusion(),
            GraphConclusion::Verified
        ));
    }
}

fn accumulator(kernel: &str, original: &str, golden: &str) {
    let cfg = config(vec![
        array("out", 0x20000, 4, 128, ArrayKind::Output),
        array("native", 0x30000, 4, 256, ArrayKind::Output),
    ]);
    let actual = execute(kernel, cfg.clone());
    let mut arena = ExprArena::new();
    let original_values = (0..128)
        .map(|i| (i, arena.int(i64::from(i % 4 == 0))))
        .collect();
    let native_values = (0..256)
        .map(|i| (i, arena.int(i64::from(i % 4 == 0))))
        .collect();
    equivalent(
        &actual,
        &SymbolicOutputs {
            arena,
            outputs: vec![
                ("out".into(), original_values),
                ("native".into(), native_values),
            ],
        },
    );
    let mut original_cfg = cfg;
    original_cfg.params.pop();
    original_cfg.arrays.pop();
    let module = Parser::new(original.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let baseline = volta_ptx_analysis::analyze(&module, Some("k"), original_cfg).unwrap();
    let expected = baseline.symbolic_outputs().unwrap();
    let rendered = expected.outputs[0]
        .1
        .iter()
        .map(|(i, v)| format!("out[{i}] = {}", expected.arena.display_expr(*v)))
        .collect::<Vec<_>>()
        .join("\n");
    assert_eq!(rendered.trim(), golden.trim());
    assert!(matches!(
        check_output_equivalence(&actual, expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
#[test]
fn raw_accumulator_decodes_f32_bits_and_preserves_all_128_original_fragments() {
    accumulator(
        "matrix_raw_accumulator",
        include_str!("ptx/success/mma_accumulator_register_decodes_raw_bits.ptx"),
        include_str!("ptx/success/mma_accumulator_register_decodes_raw_bits.out"),
    );
}
#[test]
fn materialized_immediate_c_preserves_all_128_original_fragments() {
    accumulator(
        "matrix_immediate_accumulator",
        include_str!("ptx/success/mma_with_immediate_accumulator.ptx"),
        include_str!("ptx/success/mma_with_immediate_accumulator.out"),
    );
}
#[test]
fn four_ldmatrix_fragment_pairs_preserve_every_source_half() {
    let actual = execute(
        "matrix_four_fragment_pairs",
        config(vec![
            array("input", 0x10000, 2, 256, ArrayKind::Input),
            array("out", 0x20000, 2, 256, ArrayKind::Output),
        ]),
    );
    let mut arena = ExprArena::new();
    let input = arena.intern_string("input");
    let values = (0..256)
        .map(|i| {
            (
                i,
                arena.input_element(input, ((i % 8) / 2) * 64 + (i / 8) * 2 + i % 2),
            )
        })
        .collect();
    equivalent(
        &actual,
        &SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), values)],
        },
    );
}
#[test]
fn stmatrix_lane_word_placement_checks_the_original_byte20_and_all_32_words() {
    let actual = execute(
        "matrix_lane_word_placement",
        config(vec![array("out", 0x20000, 4, 33, ArrayKind::Output)]),
    );
    let mut arena = ExprArena::new();
    let values = (0..33)
        .map(|i| (i, arena.int(if i == 0 { 1005 } else { 999 + i as i64 })))
        .collect();
    equivalent(
        &actual,
        &SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), values)],
        },
    );
    let original = include_str!("ptx/success/stmatrix_writes_the_expected_byte_per_lane.ptx");
    let module = Parser::new(original.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let baseline = volta_ptx_analysis::analyze(
        &module,
        Some("k"),
        config(vec![array("out", 0x20000, 4, 1, ArrayKind::Output)]),
    )
    .unwrap();
    let expected = baseline.symbolic_outputs().unwrap();
    assert_eq!(expected.outputs[0].1.len(), 1);
    let value = expected.outputs[0].1[0];
    assert_eq!(
        format!(
            "out[{}] = {}",
            value.0,
            expected.arena.display_expr(value.1)
        ),
        include_str!("ptx/success/stmatrix_writes_the_expected_byte_per_lane.out").trim()
    );
    let mut projection = actual.clone();
    projection.outputs[0].1.retain(|(index, _)| *index == 0);
    equivalent(&projection, expected);
}
