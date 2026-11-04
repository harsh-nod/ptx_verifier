//! Exact portable memory footprints and complete payloads from real compilation.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use std::collections::BTreeSet;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AccessMode, EventGraph, Footprint, Space};
use volta_graph_check::{GraphConclusion, Property, Verdict};

const SOURCE: &str =
    include_str!("../../../tests/gfx1250/portable-graph/copy-order/native-copy-order.s");
fn run(source: &str, kernel: &str, block: u32, input: u64, output: u64) -> native_common::Checked {
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
    let module =
        frontend::parse(source).expect("unchanged real compiler output or MC-valid mutation");
    native_common::check(source, &module, Some(kernel), config).unwrap()
}
fn equivalent(checked: &native_common::Checked, expected: SymbolicOutputs, count: usize) {
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
        (0..count as u64).collect::<Vec<_>>()
    );
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
fn identity(checked: &native_common::Checked, inputs: &[u64]) {
    let mut arena = ExprArena::new();
    let name = arena.intern_string("in");
    let values = inputs
        .iter()
        .enumerate()
        .map(|(out, &input)| (out as u64, arena.input_element(name, input)))
        .collect();
    equivalent(
        checked,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), values)],
        },
        inputs.len(),
    );
}
fn locations(graph: &EventGraph, space: Space, mode: AccessMode) -> BTreeSet<u64> {
    graph
        .accesses()
        .values()
        .filter(|a| a.space == space && a.mode == mode)
        .flat_map(|a| match a.footprint {
            Footprint::Bytes { addr, width } => addr..addr + u64::from(width),
            _ => panic!("copy controls must have byte footprints"),
        })
        .collect()
}
fn footprint(
    checked: &native_common::Checked,
    input_bytes: u64,
    shared_written: std::ops::Range<u64>,
    shared_read: impl IntoIterator<Item = std::ops::Range<u64>>,
) {
    let graph = &checked.analysis.graph;
    assert_eq!(
        locations(graph, Space::Shared, AccessMode::Write),
        shared_written.collect()
    );
    assert_eq!(
        locations(graph, Space::Shared, AccessMode::Read),
        shared_read.into_iter().flatten().collect()
    );
    let input: BTreeSet<_> = locations(graph, Space::Global, AccessMode::Read)
        .into_iter()
        .filter(|&addr| (0x10000..0x20000).contains(&addr))
        .collect();
    assert_eq!(input, (0x10000..0x10000 + input_bytes).collect());
    assert!(
        locations(graph, Space::Global, AccessMode::Write)
            .iter()
            .all(|&addr| addr >= 0x20000)
    );
}
fn mutate(kernel: &str, before: &str, after: &str, last: bool) -> String {
    let begin = SOURCE.find(&format!("\n{kernel}:")).unwrap();
    let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
    let body = &SOURCE[begin..end];
    let at = begin
        + if last {
            body.rfind(before).unwrap()
        } else {
            body.find(before).unwrap()
        };
    let mut source = SOURCE.to_owned();
    source.replace_range(at..at + before.len(), after);
    source
}

#[test]
fn four_byte_copies_preserve_both_single_wave_and_crosswave_payloads() {
    for (kernel, block) in [("copy_scalar_same_wave", 1), ("copy_scalar_cross_wave", 64)] {
        let checked = run(SOURCE, kernel, block, 1, 1);
        identity(&checked, &[0]);
        footprint(&checked, 4, 0..4, std::iter::once(0..4));
    }
}

#[test]
fn both_sixteen_byte_regions_complete_before_all_64_consumers_publish() {
    let checked = run(SOURCE, "copy_both_regions_before_publication", 64, 8, 64);
    identity(&checked, &[4; 64]);
    footprint(&checked, 32, 0..32, std::iter::once(16..20));
}

#[test]
fn later_copy_issues_after_the_previous_region_has_been_observed() {
    let checked = run(SOURCE, "copy_two_completed_regions", 1, 8, 2);
    identity(&checked, &[0, 4]);
    footprint(&checked, 32, 0..32, [0..4, 16..20]);
}

#[test]
fn all_32_lane_ids_return_through_the_real_lds_dependency_and_no_tail_is_written() {
    let checked = run(SOURCE, "copy_result_dependency_ids", 32, 0, 256);
    let mut arena = ExprArena::new();
    let values = (0..32).map(|i| (i, arena.int(i as i64))).collect();
    equivalent(
        &checked,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), values)],
        },
        32,
    );
    footprint(&checked, 0, 0..128, std::iter::once(0..128));
}

#[test]
fn every_actual_reader_observes_the_complete_sixteen_byte_copy() {
    let module = frontend::parse(SOURCE).unwrap();
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays.push(ArrayDef {
        name: "in".into(),
        base: 0x10000,
        elem_width: 4,
        len: 4,
        kind: ArrayKind::Input,
    });
    config.params.push(ParamValue::ArrayPtr("in".into()));
    let checked = native_common::check(
        SOURCE,
        &module,
        Some("copy_every_actual_reader_waits"),
        config,
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
    footprint(&checked, 16, 0..16, std::iter::once(0..4));
    let readers: BTreeSet<_> = checked
        .analysis
        .graph
        .accesses()
        .values()
        .filter(|a| a.space == Space::Shared && a.mode == AccessMode::Read)
        .map(|a| a.attributed.0)
        .collect();
    assert_eq!(readers, (32..64).collect());
}

#[test]
fn a_load_wait_cannot_complete_the_actual_scalar_input_counter() {
    identity(&run(SOURCE, "copy_scalar_same_wave", 1, 1, 1), &[0]);
    let source = mutate(
        "copy_scalar_same_wave",
        "s_load_b32 s0, s[4:5], 0x0\n\ts_wait_kmcnt 0x0",
        "s_load_b32 s0, s[4:5], 0x0\n\ts_wait_loadcnt 0",
        false,
    );
    let checked = run(&source, "copy_scalar_same_wave", 1, 1, 1);
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        checked.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Fail
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn store_completion_does_not_make_the_returned_shared_value_ready() {
    identity(&run(SOURCE, "copy_scalar_same_wave", 1, 1, 1), &[0]);
    let source = mutate(
        "copy_scalar_same_wave",
        "s_wait_loadcnt_dscnt 0x0",
        "s_wait_storecnt 0",
        false,
    );
    let checked = run(&source, "copy_scalar_same_wave", 1, 1, 1);
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        checked.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Fail
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn completing_lds_is_distinct_from_publishing_it_to_another_wave() {
    identity(&run(SOURCE, "copy_scalar_cross_wave", 64, 1, 1), &[0]);
    let source = mutate(
        "copy_scalar_cross_wave",
        "s_barrier_signal -1\n\ts_barrier_wait -1",
        "s_nop 0\n\ts_nop 0",
        false,
    );
    let old = "flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS";
    let spacing = "s_nop 0\n\t".repeat(64) + old;
    let begin = source.find("\ncopy_scalar_cross_wave:").unwrap();
    let end = begin + source[begin..].find(".Lfunc_end").unwrap();
    let at = begin + source[begin..end].find(old).unwrap();
    let source = source[..at].to_owned() + &spacing + &source[at + old.len()..];
    let checked = run(&source, "copy_scalar_cross_wave", 64, 1, 1);
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(checked.checks.verdict(Property::AmdBarrier), Verdict::Pass);
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
