//! File-based AMD graph evidence gates extraction as well as native dispatch.
use std::collections::HashMap;

use volta_graph::{Assumption, ThreadUnit};
use volta_graph_check::GraphConclusion;
use volta_pipeline::{GraphEvidence, Isa, LeanExtractionError, Spec};
use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

const SOURCE: &str = include_str!("../../volta_amd_analysis/tests/fixtures/lds_sync.s");

fn run(kernel: &str) -> volta_pipeline::KernelRun {
    let mut config = AnalysisConfig::new((128, 1, 1));
    for (name, base, kind) in [
        ("input", 0x10000, ArrayKind::Input),
        ("output", 0x20000, ArrayKind::Output),
    ] {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: 4,
            len: 128,
            kind,
        });
        config.params.push(ParamValue::ArrayPtr(name.into()));
    }
    Isa::Amd
        .frontend()
        .analyze(SOURCE, Some(kernel), config)
        .unwrap()
}

#[test]
fn experimental_frontend_retains_wave_graph_scope_and_complete_outputs() {
    for kernel in ["exchange", "two_rounds"] {
        let run = run(kernel);
        assert!(run.native.is_none());
        let GraphEvidence::Checked { graph, report } = &run.graph else {
            panic!("experimental AMD graph missing");
        };
        assert_eq!(graph.provenance().unit, ThreadUnit::Wave { lanes: 64 });
        assert_eq!(graph.threads(), 2);
        assert!(
            graph
                .provenance()
                .assumptions
                .contains(&Assumption::SharedMemoryOnly)
        );
        assert!(graph.amd_events().is_empty());
        assert_eq!(report.conclusion(), GraphConclusion::Verified, "{kernel}");
        assert_eq!(run.outputs.as_ref().unwrap().outputs[0].1.len(), 128);
    }
}

#[test]
fn experimental_lds_conflicts_block_lean_before_any_propositions() {
    let spec = Spec::new(
        &volta_spec::parse_spec("dim N; array input[N]; array output[N]; output[i]=input[i];")
            .unwrap(),
        &HashMap::from([("N".into(), 128)]),
    )
    .unwrap();
    for kernel in [
        "no_barrier",
        "barrier_without_wait",
        "overwrite_without_barrier",
    ] {
        let run = run(kernel);
        let GraphEvidence::Checked { report, .. } = &run.graph else {
            panic!("experimental AMD graph missing");
        };
        assert!(
            matches!(report.conclusion(), GraphConclusion::Rejected { .. }),
            "{kernel}"
        );
        assert!(!report.memory_conflict.violations().is_empty(), "{kernel}");
        assert!(
            matches!(
                run.extract_lean(&spec, None),
                Err(LeanExtractionError::Rejected { .. })
            ),
            "{kernel}"
        );
    }
}
