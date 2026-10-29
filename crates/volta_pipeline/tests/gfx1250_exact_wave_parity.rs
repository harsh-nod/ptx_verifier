//! Exact original wave payloads and explicit native participant/order controls.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_graph_check::{GraphConclusion, Property, Verdict};
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-exact-wave.s");

fn config(block: u32, inputs: u64, outputs: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    if inputs != 0 {
        config.arrays.push(ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: inputs,
            kind: ArrayKind::Input,
        });
        config.params.push(ParamValue::ArrayPtr("in".into()));
    }
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: outputs,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn run(source: &str, kernel: &str, config: AnalysisConfig) -> native_common::Checked {
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), config).unwrap()
}

fn original(kernel: &str, baseline: &str, golden: &str, config: AnalysisConfig) {
    let actual = run(SOURCE, kernel, config.clone());
    assert_eq!(
        actual.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        actual.checks
    );
    let outputs = actual.analysis.symbolic_outputs().unwrap();
    let baseline = Parser::new(baseline.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let reference = volta_ptx_analysis::analyze(&baseline, Some("k"), config).unwrap();
    let expected = reference.symbolic_outputs().unwrap();
    let rendered = expected
        .outputs
        .iter()
        .flat_map(|(name, values)| {
            values.iter().map(move |(index, expr)| {
                format!("{name}[{index}] = {}", expected.arena.display_expr(*expr))
            })
        })
        .collect::<Vec<_>>()
        .join("\n");
    assert_eq!(rendered.trim(), golden.trim(), "unchanged original golden");
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(i, _)| i)
            .collect::<Vec<_>>(),
        expected.outputs[0]
            .1
            .iter()
            .map(|(i, _)| i)
            .collect::<Vec<_>>(),
        "complete original written coordinates, including exited lane0"
    );
    assert!(
        matches!(
            check_output_equivalence(outputs, expected, &["out".into()]).unwrap(),
            EquivOutcome::Equivalent
        ),
        "{kernel}: full original computation"
    );
}

macro_rules! baseline {
    ($test:ident, $kernel:literal, $original:literal, $block:literal, $input:literal, $output:literal) => {
        #[test]
        fn $test() {
            original(
                $kernel,
                include_str!(concat!("ptx/success/", $original, ".ptx")),
                include_str!(concat!("ptx/success/", $original, ".out")),
                config($block, $input, $output),
            );
        }
    };
}

baseline!(
    elect_lowest_active_lane,
    "exact_wave_elect",
    "elect_sync_elects_the_lowest_active_lane",
    32,
    0,
    32
);
baseline!(
    elect_skips_exited_lane,
    "exact_wave_elect_skip",
    "elect_sync_skips_an_already_exited_lane",
    32,
    0,
    32
);
baseline!(
    two_lane_index_exchange,
    "exact_wave_exchange",
    "shfl_sync_idx_exchange",
    2,
    2,
    2
);
baseline!(
    tail_exit_shuffle_reduction,
    "exact_wave_tail_sum",
    "tail_exit_warp_shfl_reduction",
    32,
    16,
    1
);
baseline!(
    tail_exit_sequential_reference,
    "exact_wave_tail_reference",
    "tail_exit_warp_shfl_reduction_reference",
    1,
    16,
    1
);

#[test]
fn divergent_native_exec_selects_two_actual_leaders() {
    let result = run(SOURCE, "exact_wave_divergent_leaders", config(32, 0, 2));
    assert_eq!(
        result.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.checks
    );
    let outputs = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 2);
    for i in 0..2 {
        assert_eq!(
            outputs
                .arena
                .display_expr(outputs.element("out", i).unwrap()),
            (i + 1).to_string()
        );
    }
}

#[test]
fn same_address_divergent_native_stores_keep_the_public_wave_instruction_order() {
    // LLVM AMDGPUUsage.md at 5fd50ec8: consecutive same-address loads/stores
    // within one wavefront are processed in program order. PTX's independent
    // lane PCs are a distinct mechanism; their unsupported negative stays intact.
    let original = "global_store_b32 v0, v1, s[0:1] offset:4";
    assert_eq!(SOURCE.matches(original).count(), 1);
    let alias = SOURCE.replace(original, "global_store_b32 v0, v1, s[0:1]");
    let result = run(&alias, "exact_wave_divergent_leaders", config(32, 0, 1));
    assert_eq!(result.checks.conclusion(), GraphConclusion::Verified);
    let outputs = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(
        outputs
            .arena
            .display_expr(outputs.element("out", 0).unwrap()),
        "1"
    );
}

#[test]
fn same_instruction_logical_leaders_keep_the_original_unordered_writer_conflict() {
    const CONFLICT: &str =
        include_str!("../../../tests/gfx1250/fixtures/native-wave-leader-conflict.s");
    let result = run(CONFLICT, "exact_wave_leader_conflict", config(32, 0, 1));
    let outputs = result
        .analysis
        .symbolic_outputs()
        .expect("complete race candidate");
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(outputs.outputs[0].1[0].0, 0);
    for property in [
        Property::AmdTrace,
        Property::AmdWaitReadiness,
        Property::AmdBarrier,
    ] {
        assert_eq!(result.checks.verdict(property), Verdict::Pass);
    }
    let graph = &result.analysis.graph;
    let witnesses = result
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert_eq!(witnesses.len(), 1, "{witnesses:?}");
    let witness = &witnesses[0];
    assert_eq!(
        witness.kind,
        volta_graph_check::domain::ConflictKind::WriteWrite
    );
    assert_eq!(witness.location.space, volta_graph::Space::Global);
    assert_eq!(witness.location.addr, 0x20000);
    assert_eq!(graph.acting_thread(witness.earlier).unwrap().0, 0);
    assert_eq!(graph.acting_thread(witness.later).unwrap().0, 16);
    assert_eq!(
        graph.event(witness.earlier).pc,
        graph.event(witness.later).pc
    );
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));

    // With only the low half present, the same compiled instruction has one
    // writer; this identifies the second leader as the cause of the conflict.
    let control = run(CONFLICT, "exact_wave_leader_conflict", config(16, 0, 1));
    assert_eq!(control.checks.conclusion(), GraphConclusion::Verified);
    let outputs = control.analysis.symbolic_outputs().unwrap();
    assert_eq!(
        outputs
            .arena
            .display_expr(outputs.element("out", 0).unwrap()),
        "1"
    );
}

#[test]
fn native_crosslane_completion_does_not_publish_payload_between_waves() {
    let result = run(SOURCE, "exact_wave_memory_exchange", config(64, 64, 64));
    assert_eq!(
        result.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.checks
    );
    let outputs = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 64);
    for i in 0..64 {
        assert_eq!(
            outputs
                .arena
                .display_expr(outputs.element("out", i).unwrap()),
            format!("in[{}]", i ^ 32)
        );
    }
    // CPU-only adverse control: the real DS shuffle and all data waits remain.
    // Removing the workgroup signal/wait must leave cross-wave LDS conflicts.
    let adverse = SOURCE.replace("\ts_barrier_signal -1\n\ts_barrier_wait -1\n", "");
    assert_ne!(adverse, SOURCE);
    let result = run(&adverse, "exact_wave_memory_exchange", config(64, 64, 64));
    assert_eq!(result.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        result.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Pass
    );
    assert_eq!(
        result.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:?}",
        result.checks
    );
}
