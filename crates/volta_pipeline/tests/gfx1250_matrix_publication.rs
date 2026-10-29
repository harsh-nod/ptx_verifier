//! A native WMMA producer publishes every result through LDS to another wave.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AccessMode, Space};
use volta_graph_check::{GraphConclusion, Property, Verdict, amdgpu::AmdRegisterHazardKind};

const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-matrix-publication.s");

fn execute(source: &str) -> native_common::Checked {
    let module = frontend::parse(source).expect("actual native compiler source parses");
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "input".into(),
            base: 0x10000,
            elem_width: 2,
            len: 256,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 256,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("input".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    native_common::check(
        source,
        &module,
        Some("matrix_cross_wave_publication"),
        config,
    )
    .unwrap()
}

fn check_complete_candidate(checked: &native_common::Checked) {
    let actual = checked
        .analysis
        .symbolic_outputs()
        .expect("complete candidate outputs");
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        (0..256).collect::<Vec<_>>()
    );
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
}

fn check_complete_math(checked: &native_common::Checked) {
    check_complete_candidate(checked);
    let actual = checked.analysis.symbolic_outputs().unwrap();
    let mut arena = ExprArena::new();
    let input = arena.intern_string("input");
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
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    let result = check_output_equivalence(actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}

#[test]
fn completed_wmma_result_is_published_to_the_second_wave_with_all256_outputs() {
    let checked = execute(SOURCE);
    check_complete_math(&checked);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let graph = &checked.analysis.graph;
    let mut writers = std::collections::BTreeSet::new();
    let mut readers = std::collections::BTreeSet::new();
    for access in graph.accesses().values() {
        if access.space == Space::Shared {
            match access.mode {
                AccessMode::Write => {
                    writers.insert(access.attributed.0 / 32);
                }
                AccessMode::Read => {
                    readers.insert(access.attributed.0 / 32);
                }
            }
        }
    }
    // Both waves initialize the prior phase; only wave0 computes the subsequent
    // symbolic WMMA payload, which is consumed exclusively by wave1.
    assert_eq!(writers, [0, 1].into());
    assert_eq!(readers, [1].into());
}

#[test]
fn a_barrier_without_lds_completion_cannot_publish_the_wmma_result() {
    let before_barrier = "s_wait_dscnt 0x0\n\ts_barrier_signal -1";
    let start = SOURCE.rfind(before_barrier).unwrap();
    let mut source = SOURCE.to_owned();
    source.replace_range(
        start..start + before_barrier.len(),
        "s_wait_loadcnt 0x0\n\ts_barrier_signal -1",
    );
    let checked = execute(&source);
    check_complete_math(&checked);
    assert_eq!(
        checked.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
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
            .any(|conflict| conflict.location.space == Space::Shared)
    );
}

#[test]
fn completed_wmma_stores_still_need_cross_wave_publication() {
    let mut source = SOURCE.to_owned();
    for barrier in ["s_barrier_signal -1", "s_barrier_wait -1"] {
        let start = source.rfind(barrier).unwrap();
        source.replace_range(start..start + barrier.len(), "s_nop 0");
    }
    let checked = execute(&source);
    check_complete_candidate(&checked);
    assert_eq!(
        checked.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:#?}",
        checked.checks
    );
}

#[test]
fn wmma_result_read_and_source_reuse_need_their_actual_readiness_window() {
    let wmma = SOURCE
        .lines()
        .find(|line| line.trim_start().starts_with("v_wmma_f32_"))
        .unwrap();
    let operands: Vec<_> = wmma.split_whitespace().skip(1).collect();
    let first_register = |tuple: &str| {
        tuple
            .trim_start_matches("v[")
            .split(':')
            .next()
            .unwrap()
            .parse::<u32>()
            .unwrap()
    };
    for (register, expected) in [
        (
            first_register(operands[0]),
            AmdRegisterHazardKind::MatrixReadBeforeReady,
        ),
        (
            first_register(operands[1]),
            AmdRegisterHazardKind::MatrixSourceReuse,
        ),
    ] {
        let mutation = format!("{wmma}\n\tv_mov_b32_e32 v{register}, v{register}");
        let source = SOURCE.replacen(wmma, &mutation, 1);
        let checked = execute(&source);
        check_complete_math(&checked);
        assert_eq!(
            checked.checks.verdict(Property::AmdWaitReadiness),
            Verdict::Fail,
            "{expected:?}: {:#?}",
            checked.checks
        );
        assert!(
            checked
                .checks
                .amd
                .as_ref()
                .unwrap()
                .wait_readiness
                .violations()
                .iter()
                .any(|hazard| hazard.kind == expected),
            "{expected:?}: {:#?}",
            checked.checks
        );
    }
}
