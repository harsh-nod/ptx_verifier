//! Source-backed lifetime, ordinary metadata and uninitialized-lane controls.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use std::collections::BTreeSet;
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph::{AbortCause, AccessMode, AmdEventKind, BlockedOn, Footprint, Space, Terminal};
use volta_graph_check::{GraphConclusion, Property, Verdict, domain::ConflictKind};

const SOURCE: &str = include_str!(
    "../../../tests/gfx1250/portable-graph/protocol-lifetimes/native-protocol-lifetimes.s"
);
const NAMED: &str = include_str!(
    "../../../tests/gfx1250/portable-graph/protocol-lifetimes/native-protocol-named.s"
);

fn run(kernel: &str, control: i64) -> native_common::Checked {
    let shuffle = kernel == "undefined_shuffle_source";
    let mut config = AnalysisConfig::new((if shuffle { 32 } else { 64 }, 1, 1));
    if shuffle {
        config.arrays.push(ArrayDef {
            name: "input".into(),
            base: 0x10000,
            elem_width: 4,
            len: 32,
            kind: ArrayKind::Input,
        });
        config.params.push(ParamValue::ArrayPtr("input".into()));
    }
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: if shuffle { 16 } else { 2 },
        kind: ArrayKind::Output,
    });
    config
        .params
        .extend([ParamValue::ArrayPtr("out".into()), ParamValue::Int(control)]);
    let module = frontend::parse(SOURCE).unwrap();
    native_common::check(SOURCE, &module, Some(kernel), config).unwrap()
}

fn payload(checked: &native_common::Checked, values: &[i64]) {
    let mut expected = SymbolicOutputs::default();
    let roots = values
        .iter()
        .enumerate()
        .map(|(i, &value)| (i as u64, expected.arena.int(value)))
        .collect();
    expected.outputs.push(("out".into(), roots));
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), values.len());
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn ended_reader_cannot_publish_its_read_to_a_surviving_wave_write() {
    for control in [1, 0] {
        let checked = run("ended_reader", control);
        assert!(matches!(
            checked.analysis.graph.terminal(),
            Terminal::Completed
        ));
        if control == 1 {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
        }
        assert!(
            checked
                .analysis
                .symbolic_outputs()
                .unwrap()
                .outputs
                .iter()
                .all(|(_, roots)| roots.is_empty())
        );
        if control == 0 {
            assert_eq!(
                checked.checks.verdict(Property::AmdMemoryConflict),
                Verdict::Fail,
                "{:?}",
                checked.checks
            );
            conflict(&checked, ConflictKind::ReadWrite);
        }
    }
}

fn conflict(checked: &native_common::Checked, kind: ConflictKind) {
    assert!(
        checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(|w| w.kind == kind && w.location.space == Space::Shared),
        "{:?}",
        checked.checks
    );
}

fn named(source: &str, kernel: &str, control: i64) -> native_common::Checked {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    });
    config
        .params
        .extend([ParamValue::ArrayPtr("out".into()), ParamValue::Int(control)]);
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), config).unwrap()
}

fn named_marker(checked: &native_common::Checked) {
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks
    );
    named_marker_payload(checked);
}

fn named_marker_payload(checked: &native_common::Checked) {
    let mut expected = SymbolicOutputs::default();
    let value = expected.arena.int(42);
    expected.outputs.push(("out".into(), vec![(1, value)]));
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), 1);
    assert_eq!(actual.outputs[0].1[0].0, 1);
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn allocated_object_initialization_precedes_every_other_wave_use() {
    named_marker(&named(NAMED, "named_initialization_42", 0));
    let absent = named(NAMED, "named_initialization_42", 1);
    assert!(matches!(
        absent.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
    assert_ne!(absent.checks.conclusion(), GraphConclusion::Verified);
    let begin = NAMED.find("\nnamed_initialization_42:").unwrap();
    let end = begin + NAMED[begin..].find(".Lfunc_end").unwrap();
    let region = &NAMED[begin..end];
    let sequence = "s_barrier_signal -1\n\ts_barrier_wait -1";
    assert_eq!(region.matches(sequence).count(), 2);
    let delay = std::iter::repeat_n("s_nop 0", 128)
        .collect::<Vec<_>>()
        .join("\n\t");
    let source = format!(
        "{}{}{}",
        &NAMED[..begin],
        region.replacen(sequence, &delay, 1),
        &NAMED[end..]
    );
    let unordered = named(&source, "named_initialization_42", 0);
    assert!(matches!(
        unordered.analysis.graph.terminal(),
        Terminal::Completed
    ));
    named_marker_payload(&unordered);
    assert_eq!(
        unordered.checks.verdict(Property::AmdBarrier),
        Verdict::Fail,
        "{:?}\n{:?}",
        unordered.analysis.graph.terminal(),
        unordered.checks
    );
}

#[test]
fn reinitializing_an_object_with_live_joins_stays_explicitly_unsupported() {
    named_marker(&named(NAMED, "named_live_reinitialization_42", 0));
    let live = named(NAMED, "named_live_reinitialization_42", 1);
    assert!(
        matches!(live.analysis.graph.terminal(), Terminal::Aborted { cause: AbortCause::Unsupported, reason, .. } if reason.contains("outstanding named joins")),
        "{:?}",
        live.analysis.graph.terminal()
    );
    assert_ne!(live.checks.conclusion(), GraphConclusion::Verified);
    assert!(live.analysis.symbolic_outputs().is_err());
}

#[test]
fn native_count_changes_require_a_released_ordered_new_initialization_lifetime() {
    let safe = named(NAMED, "named_new_lifetime_count_change", 1);
    assert_eq!(
        safe.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}\n{:?}",
        safe.analysis.graph.terminal(),
        safe.checks
    );
    payload(&safe, &[7, 7]);
    let initialized: Vec<_> = safe
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|e| match e.kind {
            AmdEventKind::NamedBarrierInit { object, expected } => {
                Some((object.incarnation, expected))
            }
            _ => None,
        })
        .collect();
    assert_eq!(initialized, [(0, 2), (1, 1)]);
    let unordered = named(NAMED, "named_new_lifetime_count_change", 0);
    payload(&unordered, &[7, 7]);
    assert!(matches!(
        unordered.analysis.graph.terminal(),
        Terminal::Completed
    ));
    assert_eq!(
        unordered.checks.verdict(Property::AmdBarrier),
        Verdict::Fail,
        "{:?}",
        unordered.checks
    );
    assert!(
        unordered
            .checks
            .amd
            .as_ref()
            .unwrap()
            .barrier
            .violations()
            .iter()
            .any(|v| v.reason.contains("reinitialization is not ordered"))
    );
    let mismatch = named(NAMED, "named_count_mismatch_7", 0);
    assert!(
        matches!(mismatch.analysis.graph.terminal(), Terminal::Stuck { .. }),
        "{:?}",
        mismatch.analysis.graph.terminal()
    );
    assert!(matches!(
        mismatch.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
    let Terminal::Stuck { blocked } = mismatch.analysis.graph.terminal() else {
        unreachable!()
    };
    assert_eq!(blocked.len(), 64);
    assert!(blocked.iter().all(|b| matches!(
        b.on,
        BlockedOn::AmdNamedBarrier {
            expected: 3,
            arrived: 2,
            ..
        }
    )));
    assert!(mismatch.analysis.symbolic_outputs().is_err());
}

#[test]
fn a_new_named_object_has_no_implicitly_completed_preinitialization_phase() {
    let waiting = named(NAMED, "named_wait_without_first_arrival", 0);
    let Terminal::Stuck { blocked } = waiting.analysis.graph.terminal() else {
        panic!("{:?}", waiting.analysis.graph.terminal());
    };
    assert_eq!(blocked.len(), 64);
    assert!(blocked.iter().all(|b| matches!(
        b.on,
        BlockedOn::AmdNamedBarrier {
            phase: 0,
            expected: 1,
            arrived: 0,
            ..
        }
    )));
    assert!(matches!(
        waiting.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
    assert!(waiting.analysis.symbolic_outputs().is_err());
}

#[test]
fn ended_writer_marker_requires_explicit_publication_before_exit() {
    let safe = run("ended_writer", 1);
    assert_eq!(
        safe.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        safe.checks
    );
    payload(&safe, &[42]);
    let unsafe_ = run("ended_writer", 0);
    assert!(matches!(
        unsafe_.analysis.graph.terminal(),
        Terminal::Completed
    ));
    assert_eq!(
        unsafe_.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:?}",
        unsafe_.checks
    );
    conflict(&unsafe_, ConflictKind::WriteRead);
}

#[test]
fn ordinary_eight_byte_metadata_initialization_cannot_race_scratch_store_load() {
    let safe = run("metadata_eight_bytes", 1);
    assert_eq!(
        safe.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        safe.checks
    );
    payload(&safe, &[42, 0]);
    for checked in [&safe, &run("metadata_eight_bytes", 0)] {
        for mode in [AccessMode::Read, AccessMode::Write] {
            let bytes: BTreeSet<_> = checked
                .analysis
                .graph
                .accesses()
                .values()
                .filter(|a| a.space == Space::Shared && a.mode == mode)
                .flat_map(|a| match a.footprint {
                    Footprint::Bytes { addr, width } => addr..addr + u64::from(width),
                    _ => panic!("bytes"),
                })
                .collect();
            assert_eq!(bytes.len(), 8);
        }
    }
    let unsafe_ = run("metadata_eight_bytes", 0);
    assert!(matches!(
        unsafe_.analysis.graph.terminal(),
        Terminal::Completed
    ));
    assert_eq!(
        unsafe_.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:?}",
        unsafe_.checks
    );
    conflict(&unsafe_, ConflictKind::WriteWrite);
}

#[test]
fn uninitialized_source_lane_does_not_become_a_defined_shuffle_output() {
    let safe = run("undefined_shuffle_source", 1);
    assert_eq!(
        safe.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        safe.checks
    );
    let mut expected = SymbolicOutputs::default();
    let roots = (0..16)
        .map(|i| {
            let index = expected.arena.int(i + 8);
            (i as u64, expected.arena.symbolic_read("input", index))
        })
        .collect();
    expected.outputs.push(("out".into(), roots));
    let actual = safe.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), 16);
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    let undefined = run("undefined_shuffle_source", 0);
    assert!(
        matches!(
            undefined.analysis.graph.terminal(),
            Terminal::Aborted { cause: AbortCause::Error, reason, .. } if reason.contains("undefined") || reason.contains("uninitialized")
        ),
        "{:?}",
        undefined.analysis.graph.terminal()
    );
    assert!(undefined.analysis.symbolic_outputs().is_err());
    assert!(
        matches!(undefined.analysis.symbolic_outputs(), Err(OutputsUnavailable::Aborted(EvalError::Invalid { wave: 0, lane: Some(16), what, .. })) if what.contains("register 20")),
        "{:?}",
        undefined.analysis.symbolic_outputs()
    );
    assert_ne!(undefined.checks.conclusion(), GraphConclusion::Verified);
}
