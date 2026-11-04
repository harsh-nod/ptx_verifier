//! Actual 4/16-byte asynchronous memory transfers retain their buffer borrows.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use std::collections::BTreeSet;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph::{AccessMode, AmdEventKind, AmdMemoryClass, Footprint, Space};
use volta_graph_check::{GraphConclusion, Property, Verdict, domain::ConflictKind};

const SOURCE: &str =
    include_str!("../../../tests/gfx1250/portable-graph/async-memory/native-async-memory.s");
const CASES: [(&str, u32, u64, u64); 10] = [
    ("async_copy4_same_actor", 1, 1, 1),
    ("async_copy16_same_actor", 1, 4, 4),
    ("async_copy4_cross_wave", 64, 1, 1),
    ("async_copy16_cross_wave", 64, 4, 4),
    ("async_copy4_destination_reuse_same_actor", 1, 2, 1),
    ("async_copy4_destination_reuse_cross_wave", 64, 2, 1),
    ("async_copy16_source_reuse", 64, 5, 5),
    ("async_two_16byte_regions", 64, 8, 64),
    ("async_no_output128_reuse", 64, 64, 1),
    ("async_copy4_global_source_reuse", 64, 2, 1),
];

fn run(source: &str, kernel: &str) -> native_common::Checked {
    let &(_, threads, input_len, output_len) = CASES.iter().find(|c| c.0 == kernel).unwrap();
    let mut config = AnalysisConfig::new((threads, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "input".into(),
            base: 0x10000,
            elem_width: 4,
            len: input_len,
            kind: if kernel == "async_copy4_global_source_reuse" {
                ArrayKind::InputOutput
            } else {
                ArrayKind::Input
            },
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: output_len,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("input".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), config).unwrap()
}

fn expected(kernel: &str) -> SymbolicOutputs {
    let &(_, _, _, output_len) = CASES.iter().find(|c| c.0 == kernel).unwrap();
    let mut result = SymbolicOutputs::default();
    let roots = (0..output_len)
        .map(|i| {
            let index = if kernel == "async_two_16byte_regions" {
                4
            } else if kernel.contains("destination_reuse") {
                1
            } else {
                i
            };
            let index = result.arena.int(index as i64);
            (i, result.arena.symbolic_read("input", index))
        })
        .collect();
    result.outputs = vec![("out".into(), roots)];
    result
}

fn assert_payload(checked: &native_common::Checked, kernel: &str) {
    let output = checked.analysis.symbolic_outputs().unwrap();
    let expected = expected(kernel);
    assert_eq!(output.outputs[0].1.len(), expected.outputs[0].1.len());
    assert!(matches!(
        check_output_equivalence(output, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

fn mutate(kernel: &str, replacement: &str) -> String {
    let begin = SOURCE.find(&format!("\n{kernel}:")).unwrap();
    let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
    let region = &SOURCE[begin..end];
    assert!((1..=2).contains(&region.matches("s_wait_tensorcnt 0x0").count()));
    format!(
        "{}{}{}",
        &SOURCE[..begin],
        region.replace("s_wait_tensorcnt 0x0", replacement),
        &SOURCE[end..]
    )
}

fn without_publication(kernel: &str) -> String {
    let begin = SOURCE.find(&format!("\n{kernel}:")).unwrap();
    let end = begin + SOURCE[begin..].find(".Lfunc_end").unwrap();
    let region = &SOURCE[begin..end];
    assert!(region.contains("s_barrier_signal -1") && region.contains("s_barrier_wait -1"));
    format!(
        "{}{}{}",
        &SOURCE[..begin],
        region
            .replace(
                "s_barrier_signal -1",
                &std::iter::repeat_n("s_nop 0", 128)
                    .collect::<Vec<_>>()
                    .join("\n\t")
            )
            .replace("s_barrier_wait -1", "s_nop 0"),
        &SOURCE[end..]
    )
}

fn tensor_bytes(checked: &native_common::Checked, space: Space, mode: AccessMode) -> BTreeSet<u64> {
    let graph = &checked.analysis.graph;
    let issues = graph
        .amd_events()
        .iter()
        .filter_map(|event| match event.kind {
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::TensorLoadToLds | AmdMemoryClass::TensorStoreFromLds,
                ..
            } => Some(event.event),
            _ => None,
        })
        .collect::<BTreeSet<_>>();
    graph
        .amd_memory_effects()
        .iter()
        .filter(|link| issues.contains(&link.issue))
        .map(|link| {
            graph.access(match graph.event(link.effect).kind {
                volta_graph::EventKind::Access(id) => id,
                _ => panic!("memory effect"),
            })
        })
        .filter(|access| access.space == space && access.mode == mode)
        .flat_map(|access| match access.footprint {
            Footprint::Bytes { addr, width } => addr..addr + u64::from(width),
            _ => panic!("byte transfer"),
        })
        .collect()
}

#[test]
fn actual_asynchronous_four_and_sixteen_byte_copies_preserve_complete_payloads() {
    for &(kernel, _, _, count) in &CASES[..4] {
        let checked = run(SOURCE, kernel);
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{kernel}: {:?}",
            checked.checks
        );
        assert_payload(&checked, kernel);
        assert_eq!(
            tensor_bytes(&checked, Space::Global, AccessMode::Read),
            (0x10000..0x10000 + count * 4).collect()
        );
        assert_eq!(
            tensor_bytes(&checked, Space::Shared, AccessMode::Write).len(),
            count as usize * 4
        );
    }
}

#[test]
fn same_actor_and_cross_wave_reads_require_actual_copy_completion() {
    for &(kernel, _, _, _) in &CASES[..4] {
        let positive = run(SOURCE, kernel);
        assert_eq!(positive.checks.conclusion(), GraphConclusion::Verified);
        for replacement in ["s_nop 0", "s_wait_loadcnt 0\n\ts_wait_dscnt 0"] {
            let negative = run(&mutate(kernel, replacement), kernel);
            assert_payload(&negative, kernel);
            assert_eq!(
                negative.checks.verdict(Property::AmdMemoryConflict),
                Verdict::Fail,
                "{kernel}: {:?}",
                negative.checks
            );
            assert!(negative.checks.amd.as_ref().unwrap().memory_conflict.violations().iter().any(|w|
                w.kind == ConflictKind::WriteRead && w.location.space == Space::Shared));
        }
    }
}

#[test]
fn destination_reuse_and_source_reuse_wait_for_their_actual_memory_borrows() {
    for &(kernel, _, _, _) in &CASES[4..7] {
        let positive = run(SOURCE, kernel);
        assert_eq!(
            positive.checks.conclusion(),
            GraphConclusion::Verified,
            "{kernel}: {:?}",
            positive.checks
        );
        assert_payload(&positive, kernel);
        let negative = run(&mutate(kernel, "s_nop 0"), kernel);
        assert_payload(&negative, kernel);
        let kind = if kernel.contains("source_reuse") {
            ConflictKind::ReadWrite
        } else {
            ConflictKind::WriteWrite
        };
        assert_eq!(
            negative.checks.verdict(Property::AmdMemoryConflict),
            Verdict::Fail,
            "{kernel}: {:?}",
            negative.checks
        );
        assert!(
            negative
                .checks
                .amd
                .as_ref()
                .unwrap()
                .memory_conflict
                .violations()
                .iter()
                .any(|w| w.kind == kind && w.location.space == Space::Shared),
            "{kernel}: {:?}",
            negative.checks
        );
    }
}

#[test]
fn both_sixteen_byte_transfers_complete_before_all_sixty_four_consumers() {
    let kernel = "async_two_16byte_regions";
    let positive = run(SOURCE, kernel);
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        positive.checks
    );
    assert_payload(&positive, kernel);
    assert_eq!(
        tensor_bytes(&positive, Space::Global, AccessMode::Read),
        (0x10000..0x10020).collect()
    );
    assert_eq!(
        tensor_bytes(&positive, Space::Shared, AccessMode::Write),
        (0..32).collect()
    );
    let negative = run(&mutate(kernel, "s_wait_loadcnt 0"), kernel);
    assert_payload(&negative, kernel);
    assert_eq!(
        negative.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail
    );
    assert!(
        negative
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(|w| w.kind == ConflictKind::WriteRead
                && w.location.space == Space::Shared
                && w.location.addr == 16)
    );
}

#[test]
fn no_output_does_not_remove_the_full_128_byte_destination_lifetime() {
    let kernel = "async_no_output128_reuse";
    let positive = run(SOURCE, kernel);
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        positive.checks
    );
    assert_eq!(
        tensor_bytes(&positive, Space::Shared, AccessMode::Write),
        (0..128).collect()
    );
    assert!(
        !positive
            .analysis
            .graph
            .accesses()
            .values()
            .any(|access| access.space == Space::Global && access.mode == AccessMode::Write)
    );
    let negative = run(&mutate(kernel, "s_nop 0"), kernel);
    assert_eq!(
        negative.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:?}",
        negative.checks
    );
    assert!(
        negative
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(|w| w.kind == ConflictKind::WriteWrite && w.location.space == Space::Shared)
    );
}

#[test]
fn completed_global_source_read_precedes_later_cross_wave_overwrite() {
    let kernel = "async_copy4_global_source_reuse";
    let positive = run(SOURCE, kernel);
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        positive.checks
    );
    let mut expected = SymbolicOutputs::default();
    let zero = expected.arena.int(0);
    let one = expected.arena.int(1);
    let before = expected.arena.symbolic_read("input", zero);
    let after = expected.arena.symbolic_read("input", one);
    expected.outputs = vec![
        ("input".into(), vec![(0, after)]),
        ("out".into(), vec![(0, before)]),
    ];
    assert!(matches!(
        check_output_equivalence(
            positive.analysis.symbolic_outputs().unwrap(),
            &expected,
            &["input".into(), "out".into()]
        )
        .unwrap(),
        EquivOutcome::Equivalent
    ));
    for source in [mutate(kernel, "s_nop 0"), without_publication(kernel)] {
        let negative = run(&source, kernel);
        assert!(matches!(
            check_output_equivalence(
                negative.analysis.symbolic_outputs().unwrap(),
                &expected,
                &["input".into(), "out".into()]
            )
            .unwrap(),
            EquivOutcome::Equivalent
        ));
        assert_eq!(
            negative.checks.verdict(Property::AmdMemoryConflict),
            Verdict::Fail
        );
        assert!(
            negative
                .checks
                .amd
                .as_ref()
                .unwrap()
                .memory_conflict
                .violations()
                .iter()
                .any(|w| w.kind == ConflictKind::ReadWrite
                    && w.location.space == Space::Global
                    && w.location.addr == 0x10000)
        );
    }
}
