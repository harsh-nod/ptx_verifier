//! Bounded genuine CDNA3 compiler coverage; this is not full gfx942 parity.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph::Space;
use volta_graph_check::GraphConclusion;

const COPY: &str = include_str!("../../../tests/gfx942/fixtures/native-copy-add.s");
const LDS: &str = include_str!("../../../tests/gfx942/fixtures/native-lds-ids.s");
const MATRIX: &str = include_str!("../../../tests/gfx942/fixtures/native-mfma.s");
const PIPELINE: &str = include_str!("../../../tests/gfx942/fixtures/native-pipeline-f16.s");

fn array(name: &str, base: u64, width: u64, length: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len: length,
        kind,
    }
}
fn copy_config(block: u32, n: u64, add: bool) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![array("x", 0x10000, 4, n, ArrayKind::Input)];
    config.params = vec![ParamValue::ArrayPtr("x".into())];
    if add {
        config
            .arrays
            .push(array("y", 0x20000, 4, n, ArrayKind::Input));
        config.params.push(ParamValue::ArrayPtr("y".into()));
    }
    config
        .arrays
        .push(array("out", 0x30000, 4, n, ArrayKind::Output));
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config.params.push(ParamValue::Int(n as i64));
    config
}
fn check(source: &str, kernel: &str, config: AnalysisConfig) -> native_common::Checked {
    let module = frontend::parse(source).expect("actual compiler assembly parses");
    let checked = native_common::check(source, &module, Some(kernel), config).unwrap();
    assert_eq!(checked.analysis.graph.provenance().targets, ["gfx942"]);
    checked
}
fn verified(source: &str, kernel: &str, config: AnalysisConfig) -> SymbolicOutputs {
    let checked = check(source, kernel, config);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn input(arena: &mut ExprArena, name: &str, i: u64) -> ExprId {
    let name = arena.intern_string(name);
    arena.input_element(name, i)
}
fn equivalent(actual: &SymbolicOutputs, expected: SymbolicOutputs) {
    assert_eq!(actual.outputs.len(), expected.outputs.len());
    for (name, elements) in &expected.outputs {
        let actual = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
        assert_eq!(
            actual.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            elements.iter().map(|(i, _)| *i).collect::<Vec<_>>()
        );
    }
    let names = expected
        .outputs
        .iter()
        .map(|(name, _)| name.clone())
        .collect::<Vec<_>>();
    let outcome = check_output_equivalence(actual, &expected, &names).unwrap();
    assert!(matches!(outcome, EquivOutcome::Equivalent), "{outcome:?}");
}
fn expected(arena: ExprArena, elements: Vec<(u64, ExprId)>) -> SymbolicOutputs {
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    }
}

#[test]
fn real_gfx942_copy_and_add_preserve_every_tail_and_wave_boundary_element() {
    for block in [1_u32, 63, 64, 65, 128, 256] {
        let mut tails = vec![1, block.saturating_sub(1).max(1), block];
        tails.sort();
        tails.dedup();
        for n in tails {
            for add in [false, true] {
                let actual = verified(
                    COPY,
                    if add { "add" } else { "copy" },
                    copy_config(block, n as u64, add),
                );
                let mut arena = ExprArena::new();
                let values = (0..n as u64)
                    .map(|i| {
                        let x = input(&mut arena, "x", i);
                        let value = if add {
                            let y = input(&mut arena, "y", i);
                            arena.add(x, y)
                        } else {
                            x
                        };
                        (i, value)
                    })
                    .collect();
                equivalent(&actual, expected(arena, values));
            }
        }
    }
}

fn lds_config(outputs: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((128, 1, 1));
    config.arrays = vec![
        array("x", 0x10000, 4, 128, ArrayKind::Input),
        array("out", 0x20000, 4, outputs, ArrayKind::Output),
    ];
    config.params = ["x", "out"].map(|n| ParamValue::ArrayPtr(n.into())).into();
    config
}
#[test]
fn real_gfx942_crosswave_lds_exchange_and_complete_wave64_reduction() {
    let actual = verified(LDS, "exchange", lds_config(128));
    let mut arena = ExprArena::new();
    let elements = (0..128)
        .map(|i| (i, input(&mut arena, "x", i ^ 64)))
        .collect();
    equivalent(&actual, expected(arena, elements));
    let actual = verified(LDS, "reduce", lds_config(2));
    let mut arena = ExprArena::new();
    let elements = (0..2)
        .map(|wave| {
            let mut sum = arena.int(0);
            for lane in 0..64 {
                let x = input(&mut arena, "x", wave * 64 + lane);
                sum = arena.add(sum, x);
            }
            (wave, sum)
        })
        .collect();
    equivalent(&actual, expected(arena, elements));
}

#[test]
fn real_gfx942_three_dimensional_ids_match_all_24_coordinates() {
    let mut config = AnalysisConfig::new((4, 3, 2));
    config.arrays = vec![array("out", 0x10000, 4, 24, ArrayKind::Output)];
    config.params = vec![ParamValue::ArrayPtr("out".into())];
    let actual = verified(LDS, "ids_3d", config);
    let mut arena = ExprArena::new();
    let mut elements = Vec::new();
    for z in 0..2 {
        for y in 0..3 {
            for x in 0..4 {
                elements.push((
                    x + 4 * (y + 3 * z),
                    arena.int((x + 10 * y + 100 * z) as i64),
                ));
            }
        }
    }
    equivalent(&actual, expected(arena, elements));
}

fn matrix_config(width: u64, inputs: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("a", 0x10000, width, inputs, ArrayKind::Input),
        array("b", 0x20000, width, inputs, ArrayKind::Input),
        array("out", 0x30000, 4, 256, ArrayKind::Output),
    ];
    config.params = ["a", "b", "out"]
        .map(|n| ParamValue::ArrayPtr(n.into()))
        .into();
    config
}
#[test]
fn real_gfx942_f32_and_f16_mfma_match_all_independent_dot_products() {
    for (kernel, width, depth) in [("mfma_f32", 4, 4), ("mfma_f16", 2, 16)] {
        let actual = verified(MATRIX, kernel, matrix_config(width, 16 * depth));
        let items = depth / 4;
        let mut arena = ExprArena::new();
        let mut elements = Vec::new();
        for row in 0..16 {
            for column in 0..16 {
                let mut sum = arena.int(0);
                for k in 0..depth {
                    let a = input(
                        &mut arena,
                        "a",
                        (row + 16 * (k / items)) * items + k % items,
                    );
                    let b = input(
                        &mut arena,
                        "b",
                        (column + 16 * (k / items)) * items + k % items,
                    );
                    let product = arena.mul(a, b);
                    sum = arena.add(sum, product);
                }
                elements.push((4 * (16 * (row / 4) + column) + row % 4, sum));
            }
        }
        elements.sort_by_key(|(i, _)| *i);
        equivalent(&actual, expected(arena, elements));
    }
}

fn pipeline_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((128, 1, 1));
    config.arrays = vec![
        array("a", 0x10000, 2, 32 * 32, ArrayKind::Input),
        array("b", 0x20000, 2, 32 * 16, ArrayKind::Input),
        array("out", 0x30000, 2, 32 * 16, ArrayKind::Output),
    ];
    config.params = ["a", "b", "out"]
        .map(|n| ParamValue::ArrayPtr(n.into()))
        .into();
    config
}
#[test]
fn real_gfx942_two_wave_lds_mfma_pipeline_computes_all_512_outputs() {
    let actual = verified(PIPELINE, "pipelined_mfma_f16", pipeline_config());
    let mut arena = ExprArena::new();
    let mut elements = Vec::new();
    for row in 0..32 {
        for column in 0..16 {
            let mut sum = arena.int(0);
            for k in 0..32 {
                let a = input(&mut arena, "a", row * 32 + k);
                let b = input(&mut arena, "b", k * 16 + column);
                let product = arena.mul(a, b);
                sum = arena.add(sum, product);
            }
            elements.push((row * 16 + column, sum));
        }
    }
    equivalent(&actual, expected(arena, elements));
}

fn mutate(source: &str, kernel: &str, needle: &str) -> String {
    let start = source.find(&format!("\n{kernel}:")).unwrap();
    let offset = source[start..].find(needle).unwrap() + start;
    let mut text = source.to_string();
    text.replace_range(offset..offset + needle.len(), "s_nop 0");
    text
}
#[test]
fn removing_real_gfx942_lds_publication_barriers_exposes_typed_shared_conflicts() {
    for (source, kernel, config) in [
        (LDS, "exchange", lds_config(128)),
        (PIPELINE, "pipelined_mfma_f16", pipeline_config()),
    ] {
        let mutant = mutate(source, kernel, "s_barrier");
        let checked = check(&mutant, kernel, config);
        assert!(checked.analysis.symbolic_outputs().is_ok());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "{:#?}",
            checked.checks
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
                .any(|w| w.location.space == Space::Shared),
            "{:#?}",
            checked.checks
        );
    }
}
#[test]
fn removing_real_gfx942_load_waits_or_matrix_result_spacing_cannot_verify() {
    for (source, kernel, needle, config) in [
        (LDS, "exchange", "s_waitcnt lgkmcnt(0)", lds_config(128)),
        (MATRIX, "mfma_f32", "s_nop 9", matrix_config(4, 64)),
    ] {
        let mutant = mutate(source, kernel, needle);
        let checked = check(&mutant, kernel, config);
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "{:#?}",
            checked.checks
        );
    }
}
