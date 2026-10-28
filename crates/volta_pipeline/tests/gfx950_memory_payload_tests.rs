//! Exact portable payloads for TCGEN and persistent-loop source fixtures.
//! Native LDS, waits and full-wave MFMA execution retain their own contracts;
//! portable-memory/cases.json pins the original goldens and the scope changes.
mod gfx950_common;

use gfx950_common::Checked;
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph::{AccessMode, AmdEventKind, Footprint, Space, Terminal};
use volta_graph_check::{GraphConclusion, amdgpu::AmdRegisterHazardKind};

const LANE_IDS: &str = include_str!("../../../tests/gfx950/portable-memory/logical_lane_ids.s");
const PARTITIONS: &str = include_str!("../../../tests/gfx950/portable-memory/logical_partitions.s");
const MASKED_MATRIX: &str =
    include_str!("../../../tests/gfx950/portable-memory/masked_matrix_publication.s");
const ONE_PASS: &str =
    include_str!("../../../tests/gfx950/portable-memory/declined_cancel_one_pass.s");
const LANE_TRANSFER: &str =
    include_str!("../../../tests/gfx950/portable-memory/ordered_lane_transfer.s");
const CONCRETE_PAIR: &str =
    include_str!("../../../tests/gfx950/portable-memory/concrete_pair_low16_store.s");

fn config(block: u32, input_len: u64, output_capacity: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: input_len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: output_capacity,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}

fn run(source: &str, config: AnalysisConfig) -> Checked {
    let module = frontend::parse(source).expect("legal native assembly");
    let checked = gfx950_common::check(source, &module, Some("k"), config).unwrap();
    assert!(checked.analysis.graph.validate().is_ok());
    checked
}

fn reference(count: u64, mut value: impl FnMut(&mut ExprArena, u64) -> ExprId) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let values = (0..count)
        .map(|index| (index, value(&mut arena, index)))
        .collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    }
}

fn compare(checked: &Checked, expected: &SymbolicOutputs) -> EquivOutcome {
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        expected.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        "the entire sparse footprint must match, including unwritten capacity"
    );
    check_output_equivalence(actual, expected, &["out".into()]).unwrap()
}

fn equivalent(checked: &Checked, expected: &SymbolicOutputs) {
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let outcome = compare(checked, expected);
    assert!(matches!(outcome, EquivOutcome::Equivalent), "{outcome:?}");
}

fn read_before_ready(checked: &Checked) {
    checked.analysis.symbolic_outputs().unwrap();
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let witnesses = checked
        .checks
        .amd
        .as_ref()
        .unwrap()
        .wait_readiness
        .violations();
    assert!(witnesses.iter().any(|witness| {
        witness.kind == AmdRegisterHazardKind::ReadBeforeReady && witness.issue != witness.use_event
    }));
}

#[test]
fn native_completion_and_register_dependency_preserve_all_32_logical_lane_ids() {
    let expected = reference(32, |arena, index| arena.int(index as i64));
    // Both original TCGEN fixtures allocate output capacity256 but write only32
    // entries. Their implicit pipeline is replaced by actual native LGKM waits.
    let result = run(LANE_IDS, config(32, 1, 256));
    equivalent(&result, &expected);

    let missing_read_wait = LANE_IDS.replace(
        "ds_read_b32 v8,v2\ns_waitcnt lgkmcnt(0)",
        "ds_read_b32 v8,v2",
    );
    let pending = run(&missing_read_wait, config(32, 1, 256));
    assert!(matches!(
        compare(&pending, &expected),
        EquivOutcome::Equivalent
    ));
    read_before_ready(&pending);
}

#[test]
fn two_disjoint_logical_32_lane_partitions_retain_their_distinct_payloads() {
    let expected = reference(64, |arena, index| arena.int((index / 32) as i64));
    equivalent(&run(PARTITIONS, config(64, 1, 64)), &expected);

    // Same complete footprint, different region identity: reading the other
    //128-byte partition must yield a real mismatch, not an unsupported result.
    let swapped = PARTITIONS.replace(
        "ds_read_b32 v8,v2",
        "v_xor_b32 v10,128,v2\nds_read_b32 v8,v10",
    );
    let swapped = run(&swapped, config(64, 1, 64));
    assert_eq!(swapped.checks.conclusion(), GraphConclusion::Verified);
    assert!(matches!(
        compare(&swapped, &expected),
        EquivOutcome::NotEquivalent { .. }
    ));
}

#[test]
fn full_wave_matrix_then_masked_publication_leaves_only_d00_uninitialized() {
    let masked = run(MASKED_MATRIX, config(128, 1, 256));
    match masked.analysis.symbolic_outputs() {
        Err(OutputsUnavailable::Aborted(EvalError::Invalid { pc, what, .. })) => {
            assert!(what.contains("uninitialized byte at 0x0"), "{what}");
            let module = frontend::parse(MASKED_MATRIX).unwrap();
            assert_eq!(module.kernels[0].instructions[*pc].mnemonic, "ds_read_b128");
        }
        other => panic!("expected an actual LDS D[0][0] uninitialized read: {other:?}"),
    }
    assert!(matches!(
        masked.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
    assert!(matches!(
        masked.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    let writes: std::collections::BTreeSet<_> = masked
        .analysis
        .graph
        .accesses()
        .iter()
        .filter_map(|(_, access)| match access.footprint {
            Footprint::Bytes { addr, width: 4 }
                if access.space == Space::Shared && access.mode == AccessMode::Write =>
            {
                Some(addr)
            }
            _ => None,
        })
        .collect();
    assert_eq!(writes, (1..256).map(|index| 4 * index).collect());
    let matrices: Vec<_> = masked
        .analysis
        .graph
        .amd_events()
        .iter()
        .filter_map(|event| match &event.kind {
            AmdEventKind::MatrixIssue { destinations, .. } => Some(destinations),
            _ => None,
        })
        .collect();
    assert_eq!(matrices.len(), 1);
    assert!(
        matrices[0]
            .iter()
            .all(|register| register.lanes == u64::MAX)
    );

    // Restore just D00 publication; all256 outputs equal K*1*2+3=11.
    let unmasked = MASKED_MATRIX.replace("v_cmp_ne_u32 vcc,v0,0", "v_cmp_ge_u32 vcc,v0,0");
    equivalent(
        &run(&unmasked, config(128, 1, 256)),
        &reference(256, |arena, _| arena.int(4 * 1 * 2 + 3)),
    );
}

#[test]
fn declined_cancel_one_pass_preserves_every_doubled_input() {
    // This specializes the original explicit never-steal premise to a declined
    // branch. There is no native scheduler request/response object to emulate.
    let result = run(ONE_PASS, config(64, 64, 64));
    equivalent(
        &result,
        &reference(64, |arena, index| {
            let input = arena.intern_string("in");
            let value = arena.input_element(input, index);
            let two = arena.int(2);
            arena.mul(value, two)
        }),
    );
    let writes = result
        .analysis
        .graph
        .accesses()
        .iter()
        .filter(|(_, access)| access.space == Space::Global && access.mode == AccessMode::Write)
        .count();
    assert_eq!(writes, 64, "the declined branch exits after one tile pass");
}

#[test]
fn ordered_logical_lane_one_to_two_handoff_preserves_the_only_output() {
    let expected = reference(1, |arena, _| arena.int(1));
    let ordered = run(LANE_TRANSFER, config(32, 1, 1));
    equivalent(&ordered, &expected);
    let actors: Vec<_> = ordered
        .analysis
        .graph
        .accesses()
        .iter()
        .filter(|(_, access)| access.space == Space::Shared)
        .map(|(_, access)| {
            assert_eq!(access.footprint, Footprint::Bytes { addr: 0, width: 4 });
            (access.mode, access.attributed.0)
        })
        .collect();
    assert_eq!(actors, vec![(AccessMode::Write, 1), (AccessMode::Read, 2)]);
    let pending = LANE_TRANSFER.replace(
        "ds_read_b32 v8,v2\ns_waitcnt lgkmcnt(0)",
        "ds_read_b32 v8,v2",
    );
    let pending = run(&pending, config(32, 1, 1));
    assert!(matches!(
        compare(&pending, &expected),
        EquivOutcome::Equivalent
    ));
    read_before_ready(&pending);
}

#[test]
fn native_concrete_pair_low16_store_preserves_neighbors_and_exact_bounds() {
    let expected = reference(3, |arena, index| arena.int([1, 2, 1][index as usize]));
    equivalent(&run(CONCRETE_PAIR, config(1, 1, 3)), &expected);

    // Native truncation remains legal, while the full transfer still has to
    // fit the descriptor's exact6-byte region. No PTX Pair rejection is copied.
    let beyond =
        CONCRETE_PAIR.replace("ds_write_b16 v2,v8 offset:4", "ds_write_b16 v2,v8 offset:6");
    let beyond = run(&beyond, config(1, 1, 3));
    match beyond.analysis.symbolic_outputs() {
        Err(OutputsUnavailable::Aborted(EvalError::Invalid { what, .. })) => {
            assert!(what.contains("out-of-bounds LDS access [0x6,+2)"), "{what}");
        }
        other => panic!("expected an exact-capacity native LDS error: {other:?}"),
    }
    assert!(matches!(
        beyond.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
    assert!(matches!(
        beyond.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}
