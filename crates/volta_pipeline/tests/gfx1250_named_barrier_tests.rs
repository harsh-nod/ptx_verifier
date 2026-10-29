//! Genuine allocated named-object compiler output, not edited descriptors.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{Assumption, BlockedOn, Space, Terminal};
use volta_graph_check::{GraphConclusion, Property, Verdict};

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-named-barriers.s");
const PHASES: &str = include_str!("../../../tests/gfx1250/portable-graph/native-named-phases.s");
fn config(block: u32, count: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: count,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: count,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}
fn run(source: &str, kernel: &str, block: u32, count: u64) -> native_common::Checked {
    let module = frontend::parse(source).expect("compiler/MC-accepted assembly");
    native_common::check(source, &module, Some(kernel), config(block, count)).unwrap()
}
fn identity(checked: &native_common::Checked, count: u64) {
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
    let mut arena = ExprArena::new();
    let input = arena.intern_string("in");
    let values = (0..count)
        .map(|i| (i, arena.input_element(input, i)))
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..count).collect::<Vec<_>>()
    );
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
fn mutate(kernel: &str, before: &str, after: &str) -> String {
    mutate_module(SOURCE, kernel, before, after)
}
fn mutate_module(source: &str, kernel: &str, before: &str, after: &str) -> String {
    let start = source.find(&format!("\n{kernel}:")).unwrap();
    let end = start + source[start..].find(".Lfunc_end").unwrap();
    let at = start + source[start..end].find(before).unwrap();
    let mut result = source.to_owned();
    result.replace_range(at..at + before.len(), after);
    result
}
#[test]
fn genuine_allocated_named_objects_preserve_complete_payloads_and_lifetimes() {
    let module = frontend::parse(SOURCE).unwrap();
    for kernel in &module.kernels {
        assert_eq!(kernel.descriptor.get("named_barrier_count"), Some(1));
    }
    for (kernel, block, count) in [
        ("named_identity", 64, 1),
        ("named_encoded_wait_uses_last_join", 64, 1),
        ("named_reinitialized_identity", 64, 2),
        ("named_subset_drop", 96, 1),
        ("named_null_unjoin", 64, 1),
        ("named_two_arrivals_one_wave", 1, 1),
    ] {
        let checked = run(SOURCE, kernel, block, count);
        identity(&checked, count);
    }
}

#[test]
fn named_objects_require_real_allocation_and_cannot_bypass_target_validation() {
    identity(&run(SOURCE, "named_identity", 64, 1), 1);
    let unallocated = SOURCE.replace(
        ".amdhsa_named_barrier_count 1",
        ".amdhsa_named_barrier_count 0",
    );
    let checked = run(&unallocated, "named_identity", 64, 1);
    assert_ne!(checked.checks.conclusion(), GraphConclusion::Verified);
    assert!(matches!(
        checked.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
    let oversized = SOURCE.replace(
        ".amdhsa_named_barrier_count 1",
        ".amdhsa_named_barrier_count 5",
    );
    assert!(frontend::parse(&oversized).is_err());
    let mut module = frontend::parse(SOURCE).unwrap();
    module.target = Some("gfx950".into());
    for kernel in &mut module.kernels {
        kernel
            .descriptor
            .fields
            .insert("wavefront_size32".into(), 0);
    }
    assert!(volta_amdgpu_analysis::target::validate(&module).is_err());
    let mut module = frontend::parse(SOURCE).unwrap();
    module.kernels[0]
        .descriptor
        .fields
        .insert("named_barrier_count".into(), 5);
    assert!(volta_amdgpu_analysis::target::validate(&module).is_err());
}

#[test]
fn explicit_m0_does_not_enable_unpinned_nonbarrier_roles() {
    let source = ".amdgcn_target \"amdgcn-amd-amdhsa--gfx1250\"\n.text\n.globl k\nk:\ns_mov_b32 m0, 0\nv_mov_b32 v0, 1\nv_readlane_b32 s0, v0, m0\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_wavefront_size32 1\n.end_amdhsa_kernel\n";
    let module = frontend::parse(source).expect("MC-valid readlane source remains parseable");
    let analysis =
        volta_amdgpu_analysis::analyze(&module, Some("k"), AnalysisConfig::new((32, 1, 1)))
            .unwrap();
    let report = volta_graph_check::check_graph(analysis.graph());
    assert_eq!(report.verdict(Property::AmdTrace), Verdict::Unknown);
    assert_ne!(report.conclusion(), GraphConclusion::Verified);
}
#[test]
fn genuine_named_counter_mismatch_and_missing_signal_are_typed_deadlocks() {
    identity(&run(SOURCE, "named_identity", 64, 1), 1);
    for source in [
        mutate(
            "named_identity",
            "s_mov_b32 m0, 0x20001",
            "s_mov_b32 m0, 0x30001",
        ),
        mutate("named_identity", "s_barrier_signal m0", "s_nop 0"),
    ] {
        let checked = run(&source, "named_identity", 64, 1);
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected {
                deadlock: Some(_),
                ..
            }
        ));
        let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
            panic!("{:?}", checked.analysis.graph.terminal())
        };
        assert_eq!(blocked.len(), 64);
        assert!(
            blocked.iter().all(
                |b| matches!(b.on,BlockedOn::AmdNamedBarrier{object,phase:0,..} if object.id==1)
            )
        );
    }
}
#[test]
fn ending_a_joined_wave_does_not_implicitly_drop_its_named_object() {
    identity(&run(SOURCE, "named_subset_drop", 96, 1), 1);
    let source = mutate("named_subset_drop", "s_barrier_leave", "s_nop 0");
    let checked = run(&source, "named_subset_drop", 96, 1);
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
    let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
        panic!("{:?}", checked.analysis.graph.terminal())
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
}
#[test]
fn named_wait_without_join_fails_its_actual_native_barrier_obligation() {
    identity(&run(SOURCE, "named_identity", 64, 1), 1);
    let source = mutate("named_identity", "s_barrier_join m0", "s_nop 0");
    let checked = run(&source, "named_identity", 64, 1);
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:?}",
        checked.checks
    );
    assert_eq!(checked.checks.verdict(Property::AmdBarrier), Verdict::Fail);
    assert!(
        checked
            .checks
            .amd
            .unwrap()
            .barrier
            .violations()
            .iter()
            .any(|v| v.reason.contains("last joined"))
    );
}

#[test]
fn unbound_null_wait_preserves_the_honest_hardware_state_limit() {
    identity(&run(SOURCE, "named_null_unjoin", 64, 1), 1);
    let source = mutate("named_null_unjoin", "s_barrier_join 0", "s_nop 0");
    let checked = run(&source, "named_null_unjoin", 64, 1);
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Unknown);
    assert_ne!(checked.checks.conclusion(), GraphConclusion::Verified);
    assert!(matches!(
        checked.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
}
#[test]
fn named_arrival_does_not_substitute_for_lds_completion() {
    identity(&run(SOURCE, "named_identity", 64, 1), 1);
    let source = mutate("named_identity", "s_wait_dscnt 0\n", "s_wait_loadcnt 0\n");
    let checked = run(&source, "named_identity", 64, 1);
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:?}",
        checked.checks
    );
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(checked.checks.verdict(Property::AmdBarrier), Verdict::Pass);
    assert_eq!(
        checked.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail
    );
    assert!(
        checked
            .checks
            .amd
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(|v| v.location.space == Space::Shared)
    );
}

#[test]
fn two_named_objects_handshake_between_complete_producer_generations() {
    let checked = run(PHASES, "named_two_object_handshake", 64, 2);
    identity(&checked, 2);
    let arrivals: Vec<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|event| {
            if let volta_graph::AmdEventKind::NamedBarrierSignal { object, phase, .. } = event.kind
            {
                Some((object.id, phase))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(
        arrivals
            .iter()
            .filter(|&&(id, phase)| id == 2 && phase == 0)
            .count(),
        2
    );
    assert_eq!(
        arrivals
            .iter()
            .filter(|&&(id, phase)| id == 2 && phase == 1)
            .count(),
        2
    );
    assert_eq!(
        arrivals
            .iter()
            .filter(|&&(id, phase)| id == 1 && phase == 0)
            .count(),
        2
    );
}

#[test]
fn distinct_named_objects_keep_independent_counts_across_phases() {
    let module = frontend::parse(PHASES).unwrap();
    let checked = native_common::check(
        PHASES,
        &module,
        Some("named_independent_object_counts"),
        AnalysisConfig::new((64, 1, 1)),
    )
    .unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks
    );
    assert!(
        checked
            .analysis
            .symbolic_outputs()
            .unwrap()
            .outputs
            .is_empty()
    );
    let counts: Vec<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|event| {
            if let volta_graph::AmdEventKind::NamedBarrierInit { object, expected } = event.kind {
                Some((object.id, expected))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(counts, [(2, 1), (1, 2)]);
    for (id, expected) in [(2, vec![0, 1]), (1, vec![0, 0])] {
        let phases: Vec<_> = checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter_map(|event| {
                if let volta_graph::AmdEventKind::NamedBarrierSignal { object, phase, .. } =
                    event.kind
                {
                    (object.id == id).then_some(phase)
                } else {
                    None
                }
            })
            .collect();
        assert_eq!(phases, expected);
    }
}

#[test]
fn three_single_participant_arrivals_preserve_the_exact_baseline_expression() {
    let checked = run(PHASES, "named_three_arrivals_expression", 32, 3);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks
    );
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        [0]
    );
    let mut arena = ExprArena::new();
    let input = arena.intern_string("in");
    let a = arena.input_element(input, 0);
    let b = arena.input_element(input, 1);
    let c = arena.input_element(input, 2);
    let sum = arena.add(a, b);
    let product = arena.mul(sum, c);
    let expression = arena.sub(product, a);
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), vec![(0, expression)])],
    };
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    let phases: Vec<_> = checked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|event| {
            if let volta_graph::AmdEventKind::NamedBarrierSignal { phase, .. } = event.kind {
                Some(phase)
            } else {
                None
            }
        })
        .collect();
    assert_eq!(phases, [0, 1, 2]);
}

fn selected_object(flag: i64) -> native_common::Checked {
    let module = frontend::parse(PHASES).unwrap();
    let mut config = config(64, 1);
    config.params.push(ParamValue::Int(flag));
    native_common::check(PHASES, &module, Some("named_selected_object_copy"), config).unwrap()
}

#[test]
fn runtime_named_id_mismatch_blocks_the_exact_native_participants() {
    identity(&selected_object(0), 1);
    let checked = selected_object(1);
    let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
        panic!(
            "{:?}\n{:?}",
            checked.analysis.graph.terminal(),
            checked.checks
        )
    };
    assert_eq!(blocked.len(), 64);
    for wave in 0..2 {
        assert!(blocked.iter().filter(|b| b.thread.0/32==wave).all(|b| matches!(b.on,BlockedOn::AmdNamedBarrier { object,phase:0,expected:2,arrived:1 } if object.id==2-wave as u8)));
    }
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
}

#[test]
fn missing_consumer_handshake_does_not_authorize_reusing_the_payload_buffer() {
    identity(&run(PHASES, "named_two_object_handshake", 64, 2), 2);
    let source = mutate_module(
        PHASES,
        "named_two_object_handshake",
        "s_barrier_wait 2",
        "s_nop 0",
    );
    let checked = run(&source, "named_two_object_handshake", 64, 2);
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

#[test]
fn independent_object_count_mismatch_blocks_both_native_waves() {
    let module = frontend::parse(PHASES).unwrap();
    let positive = native_common::check(
        PHASES,
        &module,
        Some("named_independent_object_counts"),
        AnalysisConfig::new((64, 1, 1)),
    )
    .unwrap();
    assert_eq!(positive.checks.conclusion(), GraphConclusion::Verified);
    let source = mutate_module(
        PHASES,
        "named_independent_object_counts",
        "s_mov_b32 m0, 0x10002",
        "s_mov_b32 m0, 0x20002",
    );
    let module = frontend::parse(&source).unwrap();
    let checked = native_common::check(
        &source,
        &module,
        Some("named_independent_object_counts"),
        AnalysisConfig::new((64, 1, 1)),
    )
    .unwrap();
    let Terminal::Stuck { blocked } = checked.analysis.graph.terminal() else {
        panic!(
            "{:?}\n{:?}",
            checked.analysis.graph.terminal(),
            checked.checks
        )
    };
    assert_eq!(blocked.len(), 64);
    assert!(blocked.iter().all(|b| matches!(
        b.on,
        BlockedOn::AmdNamedBarrier {
            expected: 2,
            arrived: 1,
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
fn a_different_encoded_named_wait_keeps_the_two_object_payload_contract() {
    identity(&run(PHASES, "named_two_object_handshake", 64, 2), 2);
    let source = mutate_module(
        PHASES,
        "named_two_object_handshake",
        "s_barrier_wait 2",
        "s_barrier_wait 1",
    );
    identity(&run(&source, "named_two_object_handshake", 64, 2), 2);
}
