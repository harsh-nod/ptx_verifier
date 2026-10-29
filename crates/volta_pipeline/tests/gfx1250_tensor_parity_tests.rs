//! Exact tensor-edge payloads and ordinary native metadata publication.
#![allow(unused_macros)]
#[macro_use]
mod common;
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph_check::GraphConclusion;

const EDGE: &str = include_str!("../../../tests/gfx1250/portable-tensor/native-tensor-edge.s");
const PUBLICATION: &str =
    include_str!("../../../tests/gfx1250/portable-tensor/native-tensor-publication.s");
const METADATA: &str =
    include_str!("../../../tests/gfx1250/portable-tensor/native-tensor-metadata.s");

fn config(threads: u32, output_len: u64) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((threads, 1, 1));
    cfg.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 2,
            len: 64,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 2,
            len: output_len,
            kind: ArrayKind::Output,
        },
    ];
    cfg.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    cfg
}

fn check(source: &str, kernel: &str) -> gfx950_common::Checked {
    let module = frontend::parse(source).expect("genuine native module parses");
    gfx950_common::check(source, &module, Some(kernel), config(64, 16)).unwrap()
}

fn equivalent(a: &SymbolicOutputs, b: &SymbolicOutputs) {
    assert!(
        matches!(
            check_output_equivalence(a, b, &["out".into()]).unwrap(),
            EquivOutcome::Equivalent
        ),
        "native payload differs: {} versus {}",
        volta_expr::text::to_text(a),
        volta_expr::text::to_text(b)
    );
}

fn expected() -> SymbolicOutputs {
    let mut outputs = SymbolicOutputs::default();
    let roots = (0..16)
        .map(|i| {
            let row = i / 4;
            let col = i % 4;
            let value = if row < 2 && col < 2 {
                let index = outputs.arena.int(54 + row * 8 + col);
                outputs.arena.symbolic_read("in", index)
            } else {
                outputs.arena.int(0)
            };
            (i as u64, value)
        })
        .collect();
    outputs.outputs.push(("out".into(), roots));
    outputs
}

fn check_all_payloads(source: &str, kernel: &str) -> SymbolicOutputs {
    let run = check(source, kernel);
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        run.checks
    );
    let outputs = run
        .analysis
        .into_parts()
        .outputs
        .expect("complete tensor payload");
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..16).collect::<Vec<_>>()
    );
    equivalent(&expected(), &outputs);
    outputs
}

#[test]
fn genuine_tdm_crop_and_explicit_padding_preserve_every_4x4_half_coordinate() {
    let outputs = check_all_payloads(EDGE, "tensor_edge_4x4");
    let mut projection = outputs.clone();
    projection.outputs[0].1 = vec![
        (0, outputs.element("out", 0).unwrap()),
        (1, outputs.element("out", 15).unwrap()),
    ];
    for (name, threads) in [
        (
            "cp_async_bulk_tensor_cta_and_cluster_destinations_copy_in_bounds",
            32,
        ),
        (
            "cp_async_bulk_tensor_cta_and_cluster_destinations_copy_in_bounds_cta",
            32,
        ),
        (
            "cp_async_bulk_tensor_without_fence_proxy_async_is_clean",
            32,
        ),
        ("tensormap_replace_after_tma_completes_is_accepted", 32),
        (
            "tma_tensormap_built_by_other_thread_ordered_by_bar_sync_is_accepted",
            64,
        ),
        (
            "tma_uses_another_warps_cp_fenceproxy_copy_ordered_by_bar_sync_is_accepted",
            64,
        ),
    ] {
        let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests/ptx/success")
            .join(format!("{name}.ptx"));
        let source = std::fs::read_to_string(path).unwrap();
        let module = common::parse_named(name, &source);
        let run = common::verify(&module, None, config(threads, 2)).unwrap();
        assert_eq!(run.graph.conclusion(), GraphConclusion::Verified);
        equivalent(&run.analysis.into_parts().outputs.unwrap(), &projection);
    }
}

#[test]
fn crosswave_shared_descriptor_publication_retains_the_complete_tensor_payload() {
    check_all_payloads(METADATA, "tensor_metadata_ordered");
}

#[test]
fn old_metadata_memory_can_be_rewritten_after_its_descriptor_words_are_captured() {
    check_all_payloads(METADATA, "tensor_metadata_rewrite_after_capture");
}

#[test]
fn conflicting_descriptor_field_writes_are_not_hidden_by_a_later_barrier() {
    let run = check(METADATA, "tensor_metadata_field_race");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "race candidate must complete: {:?}",
        run.analysis.symbolic_outputs()
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteWrite
                && w.location.space == volta_graph::Space::Shared
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn selecting_a_different_descriptor_changes_exactly_the_four_live_edge_cells() {
    let run = check(METADATA, "tensor_metadata_wrong_object");
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let outputs = run.analysis.into_parts().outputs.unwrap();
    let EquivOutcome::NotEquivalent { mismatches } =
        check_output_equivalence(&expected(), &outputs, &["out".into()]).unwrap()
    else {
        panic!("wrong tensor source metadata became equivalent");
    };
    assert_eq!(
        mismatches
            .iter()
            .map(|m| (m.array.as_str(), m.index))
            .collect::<Vec<_>>(),
        vec![("out", 0), ("out", 1), ("out", 4), ("out", 5)]
    );
}

fn publication_config() -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((64, 1, 1));
    cfg.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "scale".into(),
            base: 0x20000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x30000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        },
    ];
    cfg.params = ["in", "scale", "out"]
        .into_iter()
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .collect();
    cfg
}

fn publication_check(source: &str) -> gfx950_common::Checked {
    let module = frontend::parse(source).expect("known native tensor-publication source");
    gfx950_common::check(
        source,
        &module,
        Some("tensor_completion_publication"),
        publication_config(),
    )
    .unwrap()
}

#[test]
fn tensor_completion_with_a_cta_barrier_publishes_the_distinct_ordinary_metadata_store() {
    let run = publication_check(PUBLICATION);
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let outputs = run.analysis.into_parts().outputs.unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 1);
    let mut expected = SymbolicOutputs::default();
    let zero = expected.arena.int(0);
    let input = expected.arena.symbolic_read("in", zero);
    let scale = expected.arena.symbolic_read("scale", zero);
    let sum = expected.arena.add(input, scale);
    expected.outputs.push(("out".into(), vec![(0, sum)]));
    equivalent(&expected, &outputs);
}

fn mutate_nth(
    source: &str,
    kernel: &str,
    instruction: &str,
    occurrence: usize,
    replacement: &str,
) -> String {
    let start = source.find(&format!("\n{kernel}:")).unwrap();
    let end = start + source[start..].find(".Lfunc_end").unwrap();
    let body = &source[start..end];
    let offset = body
        .match_indices(instruction)
        .nth(occurrence)
        .expect("precise frozen instruction")
        .0;
    format!(
        "{}{}{}{}{}",
        &source[..start],
        &body[..offset],
        replacement,
        &body[offset + instruction.len()..],
        &source[end..]
    )
}

fn mutant(id: &str) -> String {
    let table = include_str!("../../../tests/gfx1250/portable-tensor/mutations.tsv");
    let rows = table
        .lines()
        .skip(1)
        .map(|line| {
            let fields = line.split('\t').collect::<Vec<_>>();
            assert_eq!(fields.len(), 6);
            fields
        })
        .filter(|fields| fields[0] == id)
        .collect::<Vec<_>>();
    assert!(!rows.is_empty(), "known nonempty CPU-only mutation");
    let mut source = match rows[0][1] {
        "native-tensor-metadata.s" => METADATA.to_string(),
        "native-tensor-publication.s" => PUBLICATION.to_string(),
        "native-tensor-descriptor-bytes.s" => DESCRIPTOR_BYTES.to_string(),
        other => panic!("unregistered native module: {other}"),
    };
    for row in &rows {
        assert_eq!(row[1], rows[0][1]);
        assert_eq!(row[2], rows[0][2]);
        let decode = |value: &str| value.replace("\\n", "\n").replace("\\t", "\t");
        let original = decode(row[3]);
        let replacement = match row[5] {
            "$NOP128" => ["s_nop 0"; 128].join("\n\t"),
            "$NOP512" => ["s_nop 0"; 512].join("\n\t"),
            _ => decode(row[5]),
        };
        source = mutate_nth(
            &source,
            row[2],
            &original,
            row[4].parse().unwrap(),
            &replacement,
        );
    }
    source
}

#[test]
fn a_missing_crosswave_metadata_publication_retains_a_typed_shared_read_write_conflict() {
    let source = mutant("metadata_publication");
    let run = check(&source, "tensor_metadata_ordered");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "complete harmful candidate: {:?}",
        run.analysis.symbolic_outputs()
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteRead
                && w.location.space == volta_graph::Space::Shared
                && w.location.addr < 80
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn missing_descriptor_bytes_are_not_filled_with_defaults() {
    use volta_amdgpu_analysis::{EvalError, OutputsUnavailable};
    let source = mutant("metadata_incomplete");
    let run = check(&source, "tensor_metadata_ordered");
    assert!(
        matches!(run.analysis.symbolic_outputs(),Err(OutputsUnavailable::Aborted(EvalError::Invalid{what,..})) if what.contains("uninitialized byte at 0x40")),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

#[test]
fn descriptor_register_consumption_requires_the_correct_data_completion() {
    let source = mutant("metadata_data_wait");
    let run = check(&source, "tensor_metadata_ordered");
    assert!(run.analysis.symbolic_outputs().is_ok());
    let witnesses = run.checks.amd.as_ref().unwrap().wait_readiness.violations();
    assert!(
        witnesses
            .iter()
            .any(|w| w.kind == volta_graph_check::amdgpu::AmdRegisterHazardKind::ReadBeforeReady),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn tensor_completion_alone_does_not_publish_an_unrelated_ordinary_lds_store() {
    let source = mutant("unrelated_publication");
    let run = publication_check(&source);
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteRead
                && w.location.space == volta_graph::Space::Shared
                && w.location.addr == 16
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn a_shared_metadata_object_copy_preserves_all_edge_payload_cells() {
    check_all_payloads(METADATA, "tensor_metadata_copied");
}

#[test]
fn a_metadata_copy_racing_source_and_destination_replacements_has_both_witnesses() {
    let run = check(METADATA, "tensor_metadata_copy_replace_race");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::ReadWrite
                && w.location.space == volta_graph::Space::Shared
        ),
        "{witnesses:?}"
    );
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteWrite
                && w.location.space == volta_graph::Space::Shared
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn copying_metadata_does_not_implicitly_publish_it_to_the_second_wave() {
    let source = mutant("copied_publication");
    let run = check(&source, "tensor_metadata_copied");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteRead
                && w.location.space == volta_graph::Space::Shared
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn a_cta_barrier_without_tensor_completion_does_not_publish_the_cropped_tile() {
    let source = mutant("tensor_completion");
    let run = check(&source, "tensor_metadata_ordered");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteRead
                && w.location.space == volta_graph::Space::Shared
                && w.location.addr == 128
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

const DESCRIPTOR_BYTES: &str =
    include_str!("../../../tests/gfx1250/portable-tensor/native-tensor-descriptor-bytes.s");

fn descriptor_bytes_check(kernel: &str) -> gfx950_common::Checked {
    descriptor_bytes_source_check(DESCRIPTOR_BYTES, kernel)
}

fn descriptor_bytes_source_check(source: &str, kernel: &str) -> gfx950_common::Checked {
    let mut cfg = AnalysisConfig::new((64, 1, 1));
    cfg.arrays = vec![
        ArrayDef {
            name: "seed".into(),
            base: 0x10000,
            elem_width: 4,
            len: 34,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "destination".into(),
            base: 0x20000,
            elem_width: 4,
            len: 32,
            kind: ArrayKind::Output,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x30000,
            elem_width: 4,
            len: 32,
            kind: ArrayKind::Output,
        },
    ];
    cfg.params = ["seed", "destination", "out"]
        .into_iter()
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .collect();
    let module = frontend::parse(source).expect("known full128-byte descriptor-copy source");
    gfx950_common::check(source, &module, Some(kernel), cfg).unwrap()
}

fn assert_complete_descriptor_bytes(outputs: &SymbolicOutputs) {
    assert_eq!(outputs.outputs.len(), 2);
    for name in ["destination", "out"] {
        let roots = &outputs
            .outputs
            .iter()
            .find(|(array, _)| array == name)
            .expect("both complete output arrays")
            .1;
        assert_eq!(
            roots.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            (0..32).collect::<Vec<_>>()
        );
    }
}

#[test]
fn ordinary_native_descriptor_copy_preserves_all_128_bytes_in_both_outputs() {
    let run = descriptor_bytes_check("tensor_descriptor_bytes_ordered");
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let actual = run.analysis.into_parts().outputs.unwrap();
    let mut expected = SymbolicOutputs::default();
    let elements = (0..32)
        .map(|i| {
            let index = expected.arena.int(i);
            (i as u64, expected.arena.symbolic_read("seed", index))
        })
        .collect::<Vec<_>>();
    expected.outputs = vec![
        ("destination".into(), elements.clone()),
        ("out".into(), elements),
    ];
    assert_complete_descriptor_bytes(&actual);
    assert!(matches!(
        check_output_equivalence(&expected, &actual, &["destination".into(), "out".into()])
            .unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn the_full_metadata_copy_read_and_write_race_the_same_word_replacements() {
    let run = descriptor_bytes_check("tensor_descriptor_bytes_replace_race");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    assert_complete_descriptor_bytes(run.analysis.symbolic_outputs().unwrap());
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(|w| matches!(
            w.kind,
            volta_graph_check::domain::ConflictKind::ReadWrite
                | volta_graph_check::domain::ConflictKind::WriteRead
        ) && w.location.space == volta_graph::Space::Shared
            && w.location.addr == 0),
        "{witnesses:?}"
    );
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteWrite
                && w.location.space == volta_graph::Space::Global
                && w.location.addr == 0x20000
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn a_complete_global_descriptor_copy_needs_publication_before_second_wave_readback() {
    let source = mutant("descriptor_bytes_publication");
    let run = descriptor_bytes_source_check(&source, "tensor_descriptor_bytes_ordered");
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "the complete harmful candidate must reach its actual global read: {:?}",
        run.analysis.symbolic_outputs()
    );
    assert_complete_descriptor_bytes(run.analysis.symbolic_outputs().unwrap());
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(
            |w| w.kind == volta_graph_check::domain::ConflictKind::WriteRead
                && w.location.space == volta_graph::Space::Global
                && w.location.addr == 0x20000
        ),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}
