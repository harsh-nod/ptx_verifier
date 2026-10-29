//! Exact original payloads, with explicit native actor mappings and typed conflicts.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph::{Space, Terminal};
use volta_graph_check::{GraphConclusion, Property, Verdict, domain::ConflictKind};
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-memory-payload.s");

fn config(block: u32, input: u64, output_width: u64, output: u64) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((block, 1, 1));
    for (name, len, width, kind, base) in [
        ("in", input, 4, ArrayKind::Input, 0x10000),
        ("out", output, output_width, ArrayKind::Output, 0x20000),
    ] {
        if len != 0 {
            cfg.arrays.push(ArrayDef {
                name: name.into(),
                base,
                elem_width: width,
                len,
                kind,
            });
            cfg.params.push(ParamValue::ArrayPtr(name.into()));
        }
    }
    cfg
}

fn run(source: &str, kernel: &str, cfg: AnalysisConfig) -> native_common::Checked {
    let module = frontend::parse(source).expect("genuine compiler module parses");
    native_common::check(source, &module, Some(kernel), cfg).unwrap()
}

fn without_publication(kernel: &str, phase: usize) -> String {
    let start = SOURCE.find(&format!("{kernel}:")).unwrap();
    let end = start + SOURCE[start..].find("\n.Lfunc_end").unwrap();
    let mut body = SOURCE[start..end].to_owned();
    for instruction in ["s_barrier_signal -1", "s_barrier_wait -1"] {
        let offset = body.match_indices(instruction).nth(phase).unwrap().0;
        body.replace_range(offset..offset + instruction.len(), "s_nop 0");
    }
    let mut mutant = SOURCE.to_owned();
    mutant.replace_range(start..end, &body);
    mutant
}

fn original(name: &str, cfg: AnalysisConfig) -> SymbolicOutputs {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/ptx")
        .join(format!("{name}.ptx"));
    let source = std::fs::read_to_string(&path).unwrap();
    let module = Parser::new(source.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let actual = volta_ptx_analysis::analyze(&module, Some("k"), cfg).unwrap();
    let outputs = actual
        .symbolic_outputs()
        .expect("complete original candidate")
        .clone();
    if let Ok(golden) = std::fs::read_to_string(path.with_extension("out")) {
        let mut rendered = Vec::new();
        for (name, values) in &outputs.outputs {
            for (index, value) in values {
                rendered.push(format!(
                    "{name}[{index}] = {}",
                    outputs.arena.display_expr(*value)
                ));
            }
        }
        let rendered = rendered.join("\n");
        assert_eq!(rendered.trim(), golden.trim(), "unchanged original golden");
    }
    outputs
}

fn same_outputs(actual: &SymbolicOutputs, expected: &SymbolicOutputs) {
    let indices = |outputs: &SymbolicOutputs| {
        outputs
            .outputs
            .iter()
            .map(|(name, values)| {
                (
                    name.clone(),
                    values.iter().map(|(index, _)| *index).collect::<Vec<_>>(),
                )
            })
            .collect::<Vec<_>>()
    };
    assert_eq!(
        indices(actual),
        indices(expected),
        "complete original array/index set"
    );
    let arrays = expected
        .outputs
        .iter()
        .map(|(name, _)| name.clone())
        .collect::<Vec<_>>();
    if !arrays.is_empty() {
        assert!(matches!(
            check_output_equivalence(actual, expected, &arrays).unwrap(),
            EquivOutcome::Equivalent
        ));
    }
}

fn conflict(
    result: &native_common::Checked,
    kind: ConflictKind,
    space: Space,
    first: u32,
    second: u32,
) {
    assert_eq!(result.analysis.graph.terminal(), &Terminal::Completed);
    result
        .analysis
        .symbolic_outputs()
        .expect("complete harmful candidate");
    for property in [
        Property::AmdTrace,
        Property::AmdWaitReadiness,
        Property::AmdBarrier,
    ] {
        assert_eq!(
            result.checks.verdict(property),
            Verdict::Pass,
            "{property:?}"
        );
    }
    let graph = &result.analysis.graph;
    let witnesses = result
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(|witness| witness.kind == kind
            && witness.location.space == space
            && graph.acting_thread(witness.earlier).unwrap().0 == first
            && graph.acting_thread(witness.later).unwrap().0 == second),
        "{witnesses:?}"
    );
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn equal_shared_values_still_conflict_and_preserve_the_original_twice_input_payload() {
    let cfg = config(2, 1, 4, 1);
    let result = run(SOURCE, "payload_same_value", cfg.clone());
    conflict(&result, ConflictKind::WriteWrite, Space::Shared, 0, 1);
    same_outputs(
        result.analysis.symbolic_outputs().unwrap(),
        &original("execution_error/same_value_store_to_one_address_races", cfg),
    );
}

#[test]
fn differing_shared_values_preserve_original_lane_zero_one_conflict_and_payload() {
    let cfg = config(2, 1, 4, 1);
    let result = run(SOURCE, "payload_different_values", cfg.clone());
    conflict(&result, ConflictKind::WriteWrite, Space::Shared, 0, 1);
    same_outputs(
        result.analysis.symbolic_outputs().unwrap(),
        &original(
            "execution_error/same_value_warp_uniform_store_is_not_a_race_differ",
            cfg,
        ),
    );
}

#[test]
fn no_output_shared_writers_retain_both_original_effects_and_the_complete_candidate() {
    let result = run(SOURCE, "payload_shared_writers", config(2, 0, 4, 0));
    conflict(&result, ConflictKind::WriteWrite, Space::Shared, 0, 1);
    assert!(
        result
            .analysis
            .symbolic_outputs()
            .unwrap()
            .outputs
            .is_empty()
    );
    let writes = result
        .analysis
        .graph
        .accesses()
        .values()
        .filter(|access| {
            access.space == Space::Shared && access.mode == volta_graph::AccessMode::Write
        })
        .collect::<Vec<_>>();
    assert_eq!(writes.len(), 2);
    assert!(writes[0].footprint.overlaps(&writes[1].footprint));
}

#[test]
fn source_folded_address_expression_keeps_the_original_sparse_index_one_conflict() {
    let cfg = config(2, 0, 4, 2);
    let result = run(SOURCE, "payload_address_alias", cfg.clone());
    conflict(&result, ConflictKind::WriteWrite, Space::Global, 0, 1);
    let witnesses = result
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses
            .iter()
            .all(|witness| witness.location.addr == 0x20004)
    );
    same_outputs(
        result.analysis.symbolic_outputs().unwrap(),
        &original("soundness/address_constant_expression_race", cfg),
    );
}

#[test]
fn removing_the_second_writer_keeps_each_same_instruction_control_supported() {
    for (kernel, cfg, expected) in [
        ("payload_same_value", config(1, 1, 4, 1), None),
        (
            "payload_different_values",
            config(1, 1, 4, 1),
            Some((0, "0")),
        ),
        ("payload_shared_writers", config(1, 0, 4, 0), None),
        ("payload_address_alias", config(1, 0, 4, 2), Some((1, "1"))),
    ] {
        let result = run(SOURCE, kernel, cfg);
        assert_eq!(
            result.checks.conclusion(),
            GraphConclusion::Verified,
            "{kernel}"
        );
        let outputs = result.analysis.symbolic_outputs().unwrap();
        if let Some((index, value)) = expected {
            assert_eq!(
                outputs
                    .arena
                    .display_expr(outputs.element("out", index).unwrap()),
                value
            );
        }
    }
}

#[test]
fn two_original_neighbor_outputs_survive_native_crosswave_publication_mapping() {
    let result = run(SOURCE, "payload_neighbor_exchange", config(64, 2, 4, 2));
    assert_eq!(result.checks.conclusion(), GraphConclusion::Verified);
    for baseline in [
        "shared_exchange_with_barrier",
        "bar_warp_sync_neighbor_exchange",
        "barrier_sync_is_bar_sync",
        "barrier_sync_is_bar_sync_cta_aligned",
    ] {
        same_outputs(
            result.analysis.symbolic_outputs().unwrap(),
            &original(&format!("success/{baseline}"), config(2, 2, 4, 2)),
        );
    }
}

#[test]
fn removing_only_neighbor_publication_keeps_initialized_complete_payload_and_typed_conflicts() {
    let mutant = without_publication("payload_neighbor_exchange", 1);
    let result = run(&mutant, "payload_neighbor_exchange", config(64, 2, 4, 2));
    conflict(&result, ConflictKind::WriteRead, Space::Shared, 0, 32);
    let outputs = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        [0, 1]
    );
}

#[test]
fn two_ordered_equal_stores_preserve_the_original_twice_input_positive() {
    let result = run(SOURCE, "payload_ordered_equal_values", config(64, 1, 4, 1));
    assert_eq!(result.checks.conclusion(), GraphConclusion::Verified);
    same_outputs(
        result.analysis.symbolic_outputs().unwrap(),
        &original(
            "success/same_value_stores_separated_by_bar_sync_are_not_a_race",
            config(2, 1, 4, 1),
        ),
    );
    let mutant = without_publication("payload_ordered_equal_values", 0);
    let result = run(&mutant, "payload_ordered_equal_values", config(64, 1, 4, 1));
    conflict(&result, ConflictKind::WriteWrite, Space::Shared, 0, 32);
}

#[test]
fn native_word_42_publication_has_the_original_complete_write_read_negative() {
    let safe = run(SOURCE, "payload_publish_42", config(64, 0, 4, 1));
    assert_eq!(safe.checks.conclusion(), GraphConclusion::Verified);
    let mutant = without_publication("payload_publish_42", 0);
    let unsafe_run = run(&mutant, "payload_publish_42", config(64, 0, 4, 1));
    conflict(&unsafe_run, ConflictKind::WriteRead, Space::Shared, 0, 32);
    for result in [&safe, &unsafe_run] {
        let output = result.analysis.symbolic_outputs().unwrap();
        assert_eq!(output.outputs[0].1.len(), 1);
        assert_eq!(
            output.arena.display_expr(output.element("out", 0).unwrap()),
            "42"
        );
    }
}

#[test]
fn native_lds_address_broadcast_requires_publication_for_all_31_original_readers() {
    let safe = run(SOURCE, "payload_address_broadcast", config(64, 0, 4, 0));
    assert_eq!(safe.checks.conclusion(), GraphConclusion::Verified);
    let mutant = without_publication("payload_address_broadcast", 0);
    let unsafe_run = run(&mutant, "payload_address_broadcast", config(64, 0, 4, 0));
    conflict(&unsafe_run, ConflictKind::WriteRead, Space::Shared, 0, 32);
    let graph = &unsafe_run.analysis.graph;
    let readers = unsafe_run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations()
        .iter()
        .filter(|witness| {
            witness.kind == ConflictKind::WriteRead
                && graph.acting_thread(witness.earlier).unwrap().0 == 0
        })
        .map(|witness| graph.acting_thread(witness.later).unwrap().0)
        .collect::<Vec<_>>();
    assert_eq!(readers, (32..63).collect::<Vec<_>>());
    assert!(
        unsafe_run
            .analysis
            .symbolic_outputs()
            .unwrap()
            .outputs
            .is_empty()
    );
}

#[test]
fn execution_only_collective_does_not_replace_publication_of_original_lane_one_payload() {
    let safe = run(
        SOURCE,
        "payload_collective_then_publish",
        config(64, 0, 4, 1),
    );
    assert_eq!(safe.checks.conclusion(), GraphConclusion::Verified);
    same_outputs(
        safe.analysis.symbolic_outputs().unwrap(),
        &original(
            "success/tcgen05_alloc_lanes_ordered_by_bar_warp_sync_is_accepted",
            config(32, 0, 4, 1),
        ),
    );
    let mutant = without_publication("payload_collective_then_publish", 0);
    let unsafe_run = run(
        &mutant,
        "payload_collective_then_publish",
        config(64, 0, 4, 1),
    );
    conflict(&unsafe_run, ConflictKind::WriteRead, Space::Shared, 1, 32);
    same_outputs(
        unsafe_run.analysis.symbolic_outputs().unwrap(),
        &original(
            "execution_error/tcgen05_alloc_orders_lanes_plain_accesses",
            config(32, 0, 4, 1),
        ),
    );
}

#[test]
fn genuine_packed_transpose_matches_every_original_b16_coordinate_and_unchanged_golden() {
    const TRANSPOSE: &str =
        include_str!("../../../tests/gfx1250/fixtures/native-transpose-high64.s");
    let mut cfg = config(32, 64, 2, 64);
    cfg.arrays[0].elem_width = 2;
    let actual = run(TRANSPOSE, "transpose_8x8_b16", cfg.clone());
    assert_eq!(actual.checks.conclusion(), GraphConclusion::Verified);
    same_outputs(
        actual.analysis.symbolic_outputs().unwrap(),
        &original("success/movmatrix_transpose", cfg),
    );
}
