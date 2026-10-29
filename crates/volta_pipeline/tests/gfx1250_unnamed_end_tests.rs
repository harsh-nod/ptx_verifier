//! Unnamed-barrier END/drop controls; harmful protocols run only on the CPU.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AmdEventKind, EventKind, Terminal, ThreadIx};
use volta_graph_check::{GraphConclusion, Property, Verdict};

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-barriers.s");

fn run(source: &str) -> native_common::Checked {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: 32,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 32,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let module = frontend::parse(source).unwrap();
    let result =
        native_common::check(source, &module, Some("arrived_writer_then_exit"), config).unwrap();
    assert_eq!(result.analysis.graph.terminal(), &Terminal::Completed);
    let actual = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..32).collect::<Vec<_>>()
    );
    let mut arena = ExprArena::new();
    let input = arena.intern_string("in");
    let outputs = (0..32)
        .map(|i| (i, arena.input_element(input, i)))
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), outputs)],
    };
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    result
}

#[test]
fn arrived_writer_waits_before_ending_and_preserves_all_reader_outputs() {
    assert_eq!(run(SOURCE).checks.conclusion(), GraphConclusion::Verified);
}

#[test]
fn completed_writer_signal_then_end_does_not_certify_a_later_wait() {
    let start = SOURCE.find("arrived_writer_then_exit:").unwrap();
    let end = start + SOURCE[start..].find(".Lfunc_end3:").unwrap();
    let old = "\ts_barrier_signal -1\n\ts_barrier_wait -1";
    let replacement = format!(
        "\ts_cmp_eq_u32 s0, 0\n\ts_cbranch_scc0 .Lend_drop_signal\n{}.Lend_drop_signal:\n\ts_barrier_signal -1\n\ts_cmp_eq_u32 s0, 0\n\ts_cbranch_scc0 .Lend_drop_skip_wait\n\ts_barrier_wait -1\n.Lend_drop_skip_wait:",
        "\ts_nop 0\n".repeat(128)
    );
    assert_eq!(SOURCE[start..end].matches(old).count(), 1);
    let source = format!(
        "{}{}{}",
        &SOURCE[..start],
        SOURCE[start..end].replace(old, &replacement),
        &SOURCE[end..]
    );
    let result = run(&source);
    let graph = &result.analysis.graph;
    let signal = |wave| {
        graph
            .amd_events()
            .iter()
            .find_map(|r| {
                matches!(r.kind, AmdEventKind::SplitBarrierSignal { .. })
                    .then_some(r)
                    .filter(|r| r.wave == wave)
                    .map(|r| r.event)
            })
            .unwrap()
    };
    let writer_exit = *graph.program_order(ThreadIx(32)).last().unwrap();
    assert_eq!(graph.event(writer_exit).kind, EventKind::Exit);
    assert!(signal(1) < writer_exit && writer_exit < signal(0));
    for property in [Property::AmdTrace, Property::AmdWaitReadiness] {
        assert_eq!(result.checks.verdict(property), Verdict::Pass);
    }
    for property in [Property::AmdBarrier, Property::AmdMemoryConflict] {
        assert_eq!(result.checks.verdict(property), Verdict::Unknown);
    }
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    assert!(
        result
            .checks
            .summary(Property::AmdBarrier)
            .findings
            .iter()
            .any(|s| s.contains("implicit drop"))
    );
}
