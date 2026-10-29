//! Native named-object payload markers, participant counts and distinct phases.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use std::collections::BTreeSet;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AccessMode, AmdEventKind, Assumption, BlockedOn, Footprint, Space, Terminal};
use volta_graph_check::{GraphConclusion, Property, Verdict};

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-named-lifecycle.s");

fn run(
    source: &str,
    kernel: &str,
    block: u32,
    input: u64,
    output: u64,
    skip: Option<i64>,
) -> native_common::Checked {
    let mut config = AnalysisConfig::new((block, 1, 1));
    if input != 0 {
        config.arrays.push(ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: input,
            kind: ArrayKind::Input,
        });
        config.params.push(ParamValue::ArrayPtr("in".into()));
    }
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: output,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    if let Some(skip) = skip {
        config.params.push(ParamValue::Int(skip));
    }
    let module = frontend::parse(source).expect("genuine compiler output or MC-valid mutation");
    native_common::check(source, &module, Some(kernel), config).unwrap()
}
fn payload(checked: &native_common::Checked, values: &[(u64, i64)]) {
    let mut arena = ExprArena::new();
    let expected = values
        .iter()
        .map(|&(i, value)| (i, arena.int(value)))
        .collect();
    equivalent(
        checked,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), expected)],
        },
    );
}
fn equivalent(checked: &native_common::Checked, expected: SymbolicOutputs) {
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}\n{:?}",
        checked.analysis.graph.terminal(),
        checked.checks
    );
    assert!(
        checked
            .analysis
            .graph
            .provenance()
            .assumes(Assumption::AllocatedNamedBarriers(4))
    );
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        expected.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>()
    );
    let written: BTreeSet<_> = expected.outputs[0]
        .1
        .iter()
        .flat_map(|(index, _)| 0x20000 + index * 4..0x20000 + index * 4 + 4)
        .collect();
    assert_eq!(bytes(checked, Space::Global, AccessMode::Write), written);
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
fn mutate(kernel: &str, before: &str, after: &str) -> String {
    let begin = SOURCE.find(&format!("\n{kernel}:")).unwrap();
    let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
    let at = begin + SOURCE[begin..end].find(before).unwrap();
    let mut source = SOURCE.to_owned();
    source.replace_range(at..at + before.len(), after);
    source
}
fn bytes(checked: &native_common::Checked, space: Space, mode: AccessMode) -> BTreeSet<u64> {
    checked
        .analysis
        .graph
        .accesses()
        .values()
        .filter(|a| a.space == space && a.mode == mode)
        .flat_map(|a| match a.footprint {
            Footprint::Bytes { addr, width } => addr..addr + u64::from(width),
            _ => panic!("requires byte accesses"),
        })
        .collect()
}

#[test]
fn only_the_consumer_waits_and_writes_the_original_index_one_marker_42() {
    let checked = run(SOURCE, "named_wait_only_consumer_42", 64, 0, 2, None);
    payload(&checked, &[(1, 42)]);
    assert_eq!(
        bytes(&checked, Space::Shared, AccessMode::Read),
        (0..4).collect()
    );
    assert_eq!(
        bytes(&checked, Space::Shared, AccessMode::Write),
        (0..4).collect()
    );
    let arrivals: Vec<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|e| {
            matches!(e.kind, AmdEventKind::NamedBarrierSignal { phase: 0, .. }).then_some(e.wave)
        })
        .collect();
    let waiters: Vec<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|e| {
            matches!(e.kind, AmdEventKind::NamedBarrierWait { phase: 0, .. }).then_some(e.wave)
        })
        .collect();
    assert_eq!(arrivals, [0]);
    assert_eq!(waiters, [1]);
}

#[test]
fn another_participant_arrival_releases_both_original_marker_ones() {
    payload(
        &run(SOURCE, "named_two_marker_ones", 64, 0, 2, Some(0)),
        &[(0, 1), (1, 1)],
    );
}

#[test]
fn a_live_wait_with_expected_two_and_one_arrival_records_every_blocked_thread() {
    payload(
        &run(SOURCE, "named_two_marker_ones", 64, 0, 2, Some(0)),
        &[(0, 1), (1, 1)],
    );
    let checked = run(SOURCE, "named_two_marker_ones", 64, 0, 2, Some(1));
    let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
        panic!(
            "{:?}\n{:?}",
            checked.analysis.graph.terminal(),
            checked.checks
        );
    };
    assert_eq!(blocked.len(), 64);
    assert_eq!(
        blocked.iter().map(|b| b.thread.0).collect::<BTreeSet<_>>(),
        (0..64).collect()
    );
    assert!(blocked.iter().all(|b| matches!(b.on, BlockedOn::AmdNamedBarrier { object, phase:0, expected:2, arrived:1 } if object.id == 1)));
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
}

#[test]
fn completed_single_arrival_preserves_the_only_marker_one() {
    let checked = run(SOURCE, "named_one_arrival_marker", 1, 0, 1, None);
    payload(&checked, &[(0, 1)]);
    assert!(
        checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .any(|e| matches!(e.kind, AmdEventKind::NamedBarrierRelease { phase: 0, .. }))
    );
    assert!(bytes(&checked, Space::Shared, AccessMode::Read).is_empty());
    assert!(bytes(&checked, Space::Shared, AccessMode::Write).is_empty());
}

#[test]
fn actual_wait_then_exit_path_copies_the_complete_single_input() {
    let checked = run(SOURCE, "named_wait_then_copy_exit", 1, 1, 1, None);
    let mut arena = ExprArena::new();
    let name = arena.intern_string("in");
    let value = arena.input_element(name, 0);
    equivalent(
        &checked,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), vec![(0, value)])],
        },
    );
    assert!(
        checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .any(|e| matches!(e.kind, AmdEventKind::NamedBarrierRelease { phase: 0, .. }))
    );
}

#[test]
fn observing_copy_phase_zero_precedes_the_distinct_metadata_phase_one_marker_seven() {
    let checked = run(SOURCE, "named_copy_then_metadata_phase_7", 64, 8, 8, None);
    payload(&checked, &[(0, 7)]);
    assert_eq!(
        bytes(&checked, Space::Shared, AccessMode::Write),
        (0..20).collect()
    );
    assert_eq!(
        bytes(&checked, Space::Shared, AccessMode::Read),
        (16..20).collect()
    );
    let input: BTreeSet<_> = bytes(&checked, Space::Global, AccessMode::Read)
        .into_iter()
        .filter(|&addr| (0x10000..0x20000).contains(&addr))
        .collect();
    assert_eq!(input, (0x10000..0x10010).collect());
    let phases: Vec<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|e| {
            if let AmdEventKind::NamedBarrierRelease { phase, .. } = e.kind {
                Some((e.wave, phase))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(phases, [(1, 0), (1, 1)]);
}

#[test]
fn consumer_only_wait_cannot_replace_actual_lds_completion() {
    payload(
        &run(SOURCE, "named_wait_only_consumer_42", 64, 0, 2, None),
        &[(1, 42)],
    );
    let source = mutate(
        "named_wait_only_consumer_42",
        "s_wait_dscnt 0\n",
        "s_wait_loadcnt 0\n",
    );
    let checked = run(&source, "named_wait_only_consumer_42", 64, 0, 2, None);
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(checked.checks.verdict(Property::AmdBarrier), Verdict::Pass);
    assert_eq!(
        checked.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn a_completed_earlier_phase_cannot_satisfy_the_later_metadata_wait() {
    payload(
        &run(SOURCE, "named_copy_then_metadata_phase_7", 64, 8, 8, None),
        &[(0, 7)],
    );
    let source = mutate(
        "named_copy_then_metadata_phase_7",
        "s_barrier_signal m0 \n\ts_endpgm",
        "s_nop 0\n\ts_endpgm",
    );
    let checked = run(&source, "named_copy_then_metadata_phase_7", 64, 8, 8, None);
    let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
        panic!("{:?}", checked.analysis.graph.terminal());
    };
    assert_eq!(blocked.len(), 32);
    assert!(blocked.iter().all(|b| b.thread.0 >= 32
        && matches!(
            b.on,
            BlockedOn::AmdNamedBarrier {
                phase: 1,
                expected: 1,
                arrived: 0,
                ..
            }
        )));
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
}

#[test]
fn marker_one_requires_the_named_completion_instead_of_falling_through() {
    payload(
        &run(SOURCE, "named_one_arrival_marker", 1, 0, 1, None),
        &[(0, 1)],
    );
    let source = mutate("named_one_arrival_marker", "s_barrier_signal m0", "s_nop 0");
    let checked = run(&source, "named_one_arrival_marker", 1, 0, 1, None);
    let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
        panic!("{:?}", checked.analysis.graph.terminal());
    };
    assert_eq!(blocked.len(), 1);
    assert!(matches!(
        blocked[0].on,
        BlockedOn::AmdNamedBarrier {
            phase: 0,
            expected: 1,
            arrived: 0,
            ..
        }
    ));
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
}

fn first_free_buffer_identity(checked: &native_common::Checked) {
    let mut arena = ExprArena::new();
    let name = arena.intern_string("in");
    let values = (0..2).map(|i| (i, arena.input_element(name, i))).collect();
    equivalent(
        checked,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), values)],
        },
    );
}

#[test]
fn producer_starts_with_a_free_buffer_then_observes_the_actual_consumer_release() {
    let checked = run(
        SOURCE,
        "named_producer_first_buffer_is_free",
        64,
        2,
        2,
        None,
    );
    first_free_buffer_identity(&checked);
    assert_eq!(
        bytes(&checked, Space::Shared, AccessMode::Read),
        (0..4).collect()
    );
    assert_eq!(
        bytes(&checked, Space::Shared, AccessMode::Write),
        (0..4).collect()
    );
    let waits: BTreeSet<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|e| {
            if let AmdEventKind::NamedBarrierWait { object, phase, .. } = e.kind {
                Some((e.wave, object.id, phase))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(
        waits,
        [(0, 1, 0), (1, 2, 0), (1, 2, 1)].into_iter().collect()
    );
    let arrivals: BTreeSet<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|e| {
            if let AmdEventKind::NamedBarrierSignal { object, phase, .. } = e.kind {
                Some((e.wave, object.id, phase))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(
        arrivals,
        [(0, 2, 0), (0, 2, 1), (1, 1, 0)].into_iter().collect()
    );
    assert!(
        checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter_map(
                |e| if let AmdEventKind::NamedBarrierInit { expected, .. } = e.kind {
                    Some(expected)
                } else {
                    None
                }
            )
            .all(|expected| expected == 1)
    );
}

#[test]
fn initially_free_buffer_does_not_remove_the_later_consumer_handshake() {
    first_free_buffer_identity(&run(
        SOURCE,
        "named_producer_first_buffer_is_free",
        64,
        2,
        2,
        None,
    ));
    let source = mutate(
        "named_producer_first_buffer_is_free",
        "s_barrier_wait 1",
        "s_nop 0",
    );
    let checked = run(
        &source,
        "named_producer_first_buffer_is_free",
        64,
        2,
        2,
        None,
    );
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        checked.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:?}",
        checked.checks
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}
