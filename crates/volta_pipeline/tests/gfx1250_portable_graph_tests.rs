//! Exact portable payload/participant controls from genuine gfx1250 compilation.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::Terminal;
use volta_graph_check::{GraphConclusion, Property, PropertyResult, Verdict};

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-barriers.s");

fn run(kernel: &str, block: u32, input: u64, capacity: u64) -> native_common::Checked {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: input,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: capacity,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let module = frontend::parse(SOURCE).expect("unchanged actual compiler assembly");
    native_common::check(SOURCE, &module, Some(kernel), config).unwrap()
}

fn identity(result: &native_common::Checked, indices: &[u64]) {
    let actual = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..indices.len() as u64).collect::<Vec<_>>()
    );
    let mut arena = ExprArena::new();
    let name = arena.intern_string("in");
    let elements = indices
        .iter()
        .enumerate()
        .map(|(out, &input)| (out as u64, arena.input_element(name, input)))
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    };
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn sole_participant_finishes_its_phase_before_the_complete_identity_payload() {
    let result = run("phase_identity", 1, 1, 1);
    assert_eq!(result.checks.conclusion(), GraphConclusion::Verified);
    identity(&result, &[0]);
}

#[test]
fn an_exited_wave_with_no_payload_allows_the_remaining_wave_to_finish() {
    let result = run("remaining_wave_progress", 64, 32, 256);
    assert_eq!(
        result.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.checks
    );
    identity(&result, &(0..32).collect::<Vec<_>>());
}

#[test]
fn an_explicit_arrived_writer_can_exit_after_its_publication_phase() {
    let result = run("arrived_writer_then_exit", 64, 32, 256);
    assert_eq!(
        result.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.checks
    );
    identity(&result, &(0..32).collect::<Vec<_>>());
}

#[test]
fn completed_lds_then_exit_without_arrival_keeps_only_publication_inconclusive() {
    let result = run("exited_writer_no_arrival", 64, 32, 256);
    assert!(
        matches!(result.analysis.graph.terminal(), Terminal::Completed),
        "{:?}",
        result.analysis.graph.terminal()
    );
    identity(&result, &(0..32).collect::<Vec<_>>());
    for property in [
        Property::AmdTrace,
        Property::AmdWaitReadiness,
        Property::AmdBarrier,
    ] {
        assert_eq!(result.checks.verdict(property), Verdict::Pass);
    }
    assert_eq!(
        result.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Unknown,
        "{:?}",
        result.checks
    );
    assert!(
        matches!(result.checks.amd.unwrap().memory_conflict, PropertyResult::Unknown(reasons)
        if reasons.iter().any(|r| r.events.len()==2 && r.reason.contains("implicit barrier drop")))
    );
}

#[test]
fn one_producer_and_two_consumers_preserve_both_generations_and_all_four_markers() {
    let result = run("two_generation_two_consumers", 96, 2, 4);
    assert_eq!(
        result.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.checks
    );
    identity(&result, &[0, 1, 0, 1]);
}
