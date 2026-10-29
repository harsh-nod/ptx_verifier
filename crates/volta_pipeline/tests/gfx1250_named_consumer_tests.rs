//! Count-1 full and count-2 empty preserve genuinely independent consumer roles.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use std::collections::BTreeSet;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AccessMode, AmdEventKind, BlockedOn, Footprint, Space, Terminal};
use volta_graph_check::GraphConclusion;

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-named-consumers.s");
fn run(skip: i64) -> native_common::Checked {
    let module = frontend::parse(SOURCE).unwrap();
    let mut config = AnalysisConfig::new((96, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: 2,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Int(skip),
    ];
    native_common::check(SOURCE, &module, Some("named_independent_consumers"), config).unwrap()
}
fn positive() -> native_common::Checked {
    let checked = run(0);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}\n{:?}",
        checked.analysis.graph.terminal(),
        checked.checks
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
        [0, 1, 2, 3]
    );
    let mut arena = ExprArena::new();
    let name = arena.intern_string("in");
    let values = (0..4)
        .map(|i| (i, arena.input_element(name, i % 2)))
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    checked
}

#[test]
fn both_consumers_observe_both_values_with_separate_counted_release_operations() {
    let checked = positive();
    let bytes = |space, mode| -> BTreeSet<_> {
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
    };
    assert_eq!(bytes(Space::Shared, AccessMode::Read), (0..4).collect());
    assert_eq!(bytes(Space::Shared, AccessMode::Write), (0..4).collect());
    assert_eq!(
        bytes(Space::Global, AccessMode::Write),
        (0x20000..0x20010).collect()
    );
    let input: BTreeSet<_> = bytes(Space::Global, AccessMode::Read)
        .into_iter()
        .filter(|&a| (0x10000..0x20000).contains(&a))
        .collect();
    assert_eq!(input, (0x10000..0x10008).collect());
    let readers: BTreeSet<_> = checked
        .analysis
        .graph
        .accesses()
        .values()
        .filter(|a| a.space == Space::Shared && a.mode == AccessMode::Read)
        .map(|a| a.attributed.0)
        .collect();
    assert_eq!(readers, [32, 64].into_iter().collect());
    let events = checked.analysis.graph.amd_events();
    let counts: BTreeSet<_> = events
        .iter()
        .filter_map(|e| {
            if let AmdEventKind::NamedBarrierInit { object, expected } = e.kind {
                Some((object.id, expected))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(counts, [(1, 2), (2, 1)].into_iter().collect());
    let waits: BTreeSet<_> = events
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
        [(0, 1, 0), (1, 2, 0), (1, 2, 1), (2, 2, 0), (2, 2, 1)]
            .into_iter()
            .collect()
    );
    let arrivals: BTreeSet<_> = events
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
        [(0, 2, 0), (0, 2, 1), (1, 1, 0), (2, 1, 0)]
            .into_iter()
            .collect()
    );
    // Only the two initialization/join rendezvous are automatic; no later
    // workgroup synchronization joins the consumers' payload operations.
    let automatic: Vec<_> = events
        .iter()
        .filter_map(|e| {
            if let AmdEventKind::SplitBarrierRelease { generation, .. } = e.kind {
                Some(generation)
            } else {
                None
            }
        })
        .collect();
    assert_eq!(automatic.len(), 6);
    assert!(automatic.iter().all(|&generation| generation < 2));
}

#[test]
fn either_missing_consumer_release_blocks_the_producer_and_both_next_phase_waiters() {
    positive();
    for skip in [1, 2] {
        let checked = run(skip);
        let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
            panic!(
                "{:?}\n{:?}",
                checked.analysis.graph.terminal(),
                checked.checks
            );
        };
        assert_eq!(blocked.len(), 96);
        assert_eq!(
            blocked.iter().map(|b| b.thread.0).collect::<BTreeSet<_>>(),
            (0..96).collect()
        );
        for b in blocked {
            assert!(
                matches!(b.on,BlockedOn::AmdNamedBarrier { object,phase:0,expected:2,arrived:1 } if b.thread.0<32 && object.id==1)
                    || matches!(b.on,BlockedOn::AmdNamedBarrier { object,phase:1,expected:1,arrived:0 } if b.thread.0>=32 && object.id==2)
            );
        }
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected {
                deadlock: Some(_),
                ..
            }
        ));
    }
}
