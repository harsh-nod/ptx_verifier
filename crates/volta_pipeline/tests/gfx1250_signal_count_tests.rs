//! Genuine named signal-time count changes and conservative public boundaries.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph::{AbortCause, AmdEventKind, BlockedOn, Terminal};
use volta_graph_check::{GraphConclusion, Property, Verdict};

const SOURCE: &str =
    include_str!("../../../tests/gfx1250/portable-graph/signal-counts/native-signal-counts.s");

fn run(source: &str, kernel: &str, block: u32) -> native_common::Checked {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), config).unwrap()
}

fn sevens(checked: &native_common::Checked, count: u64) {
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}\n{:?}",
        checked.analysis.graph.terminal(),
        checked.checks
    );
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), count as usize);
    let mut expected = SymbolicOutputs::default();
    let seven = expected.arena.int(7);
    expected
        .outputs
        .push(("out".into(), (0..count).map(|i| (i, seven)).collect()));
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn actual_signal_updates_change_count_between_phases_without_reinitialization() {
    let checked = run(SOURCE, "named_phase_count_update7", 64);
    sevens(&checked, 2);
    let events = checked.analysis.graph.amd_events();
    let updates: Vec<_> = events
        .iter()
        .filter_map(|e| match e.kind {
            AmdEventKind::NamedBarrierSignalWithCount {
                object,
                phase,
                expected,
                ..
            } => Some((object.incarnation, phase, expected)),
            _ => None,
        })
        .collect();
    assert_eq!(updates, [(0, 0, 2), (0, 0, 2), (0, 1, 1)]);
    assert_eq!(
        events
            .iter()
            .filter(|e| matches!(e.kind, AmdEventKind::NamedBarrierInit { .. }))
            .count(),
        1
    );
}

#[test]
fn an_actual_count_update_cannot_release_two_arrivals_when_it_requires_three() {
    for kernel in [
        "named_signal_count_deadlock7",
        "named_signal_count_deadlock7_reverse",
    ] {
        let checked = run(SOURCE, kernel, 64);
        let arrivals: Vec<_> = checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter_map(|e| {
                matches!(
                    e.kind,
                    AmdEventKind::NamedBarrierSignalWithCount { expected: 3, .. }
                )
                .then_some(e.wave)
            })
            .collect();
        assert_eq!(
            arrivals,
            if kernel.ends_with("reverse") {
                vec![1, 0]
            } else {
                vec![0, 1]
            }
        );
        let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
            panic!("{:?}", checked.analysis.graph.terminal())
        };
        assert_eq!(blocked.len(), 64);
        assert!(blocked.iter().all(|b| matches!(
            b.on,
            BlockedOn::AmdNamedBarrier {
                phase: 0,
                expected: 3,
                arrived: 2,
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
        assert!(checked.analysis.symbolic_outputs().is_err());
    }
}

#[test]
fn a_decrease_below_existing_arrivals_has_a_typed_protocol_violation() {
    let checked = run(SOURCE, "named_decrease_below_arrived7", 64);
    assert!(
        matches!(checked.analysis.graph.terminal(), Terminal::Aborted { cause: AbortCause::Error, reason, .. } if reason.contains("less than the current arrival count")),
        "{:?}",
        checked.analysis.graph.terminal()
    );
    assert_eq!(
        checked.checks.verdict(Property::AmdBarrier),
        Verdict::Fail,
        "{:?}",
        checked.checks
    );
    assert!(checked.analysis.symbolic_outputs().is_err());
}

#[test]
fn equal_to_arrived_boundary_remains_explicitly_inconclusive() {
    let checked = run(SOURCE, "named_equal_arrived_boundary7", 64);
    assert!(
        matches!(checked.analysis.graph.terminal(), Terminal::Aborted { cause: AbortCause::Unsupported, reason, .. } if reason.contains("boundary rules differ")),
        "{:?}",
        checked.analysis.graph.terminal()
    );
    assert_eq!(
        checked.checks.verdict(Property::AmdBarrier),
        Verdict::Unknown,
        "{:?}",
        checked.checks
    );
    assert!(checked.analysis.symbolic_outputs().is_err());
}

#[test]
fn zero_updates_and_null_signals_preserve_their_original_no_change_semantics() {
    for kernel in ["named_zero_update_marker7", "named_null_update_marker7"] {
        let checked = run(SOURCE, kernel, 1);
        sevens(&checked, 1);
        assert!(
            !checked
                .analysis
                .graph
                .amd_events()
                .iter()
                .any(|e| matches!(e.kind, AmdEventKind::NamedBarrierSignalWithCount { .. }))
        );
    }
    let begin = SOURCE.find("\nnamed_null_update_marker7:").unwrap();
    let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
    let region = &SOURCE[begin..end];
    assert_eq!(region.matches("s_mov_b32 m0, 0x7f0000").count(), 1);
    let mutated = format!(
        "{}{}{}",
        &SOURCE[..begin],
        region.replace("s_mov_b32 m0, 0x7f0000", "s_mov_b32 m0, 0xff000000"),
        &SOURCE[end..]
    );
    let null = run(&mutated, "named_null_update_marker7", 1);
    sevens(&null, 1);
    assert!(
        !null
            .analysis
            .graph
            .amd_events()
            .iter()
            .any(|e| matches!(e.kind, AmdEventKind::NamedBarrierSignalWithCount { .. }))
    );
}

#[test]
fn the_actual_seven_bit_update_maximum_preserves_all_127_arrivals() {
    let checked = run(SOURCE, "named_max_signal_count7", 1);
    sevens(&checked, 1);
    assert_eq!(
        checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter(|e| matches!(
                e.kind,
                AmdEventKind::NamedBarrierSignalWithCount { expected: 127, .. }
            ))
            .count(),
        127
    );
}

#[test]
fn reserved_m0_signal_bits_do_not_become_a_wider_expected_count() {
    let begin = SOURCE.find("\nnamed_phase_count_update7:").unwrap();
    let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
    let region = &SOURCE[begin..end];
    let sequence = "s_mov_b32 m0, 0x20001";
    assert_eq!(region.matches(sequence).count(), 2);
    let at = region.rfind(sequence).unwrap();
    let mut changed = region.to_owned();
    changed.replace_range(at..at + sequence.len(), "s_mov_b32 m0, 0x800001");
    let mutated = format!("{}{}{}", &SOURCE[..begin], changed, &SOURCE[end..]);
    let checked = run(&mutated, "named_phase_count_update7", 64);
    assert!(
        matches!(checked.analysis.graph.terminal(), Terminal::Aborted { cause: AbortCause::Unsupported, reason, .. } if reason.contains("reserved M0 bits")),
        "{:?}",
        checked.analysis.graph.terminal()
    );
    assert!(checked.analysis.symbolic_outputs().is_err());
    assert_ne!(checked.checks.conclusion(), GraphConclusion::Verified);
}
