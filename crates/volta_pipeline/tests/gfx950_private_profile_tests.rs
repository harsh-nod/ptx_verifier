//! Private-memory admission failures must not become mathematical refutations.
use std::collections::HashMap;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::EquivCheckOptions;
use volta_graph::{AbortCause, Terminal};
use volta_graph_check::GraphConclusion;
use volta_pipeline::{
    EquivalenceVerdict, KernelEvidence, KernelModule, SourceKernelVerification, Verdict,
    check_equivalence, decide, verify_source_kernel,
};

const SOURCE: &str =
    include_str!("../../volta_amdgpu_analysis/tests/fixtures/device-private/stack-leaf.s");

fn run(source: &str, early: bool) -> SourceKernelVerification {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.early_readiness = early;
    config.early_memory_conflicts = early;
    for (name, base, kind) in [
        ("x", 0x10000, ArrayKind::Input),
        ("out", 0x20000, ArrayKind::Output),
    ] {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: 4,
            len: 64,
            kind,
        });
    }
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::ArrayPtr("x".into()),
    ];
    verify_source_kernel(
        &KernelModule::Amdgpu(frontend::parse(source).unwrap()),
        Some("stack_leaf_copy64"),
        config,
    )
    .unwrap()
}

fn verdict(result: &SourceKernelVerification, increment: u32) -> Verdict {
    let spec = format!("dim N; array x[N]; array out[N]; out[i] = x[i] + {increment};");
    let expected =
        volta_spec::extract_expressions_from_spec(&spec, &HashMap::from([("N".into(), 64)]))
            .unwrap();
    let equivalence = match &result.analysis.outputs {
        Ok(actual) => {
            check_equivalence(
                &expected,
                actual,
                &["out".into()],
                &EquivCheckOptions {
                    sample: 0,
                    verify_numeric: true,
                    ..Default::default()
                },
            )
            .0
        }
        Err(reason) => EquivalenceVerdict::Failed {
            reason: reason.clone(),
        },
    };
    decide(
        &equivalence,
        &[KernelEvidence {
            label: "stack_leaf_copy64",
            graph: &result.graph,
            assumptions: &result.analysis.graph.provenance().assumptions,
        }],
    )
    .verdict
}

#[test]
fn complete_private_call_proves_all_outputs_and_refutes_a_wrong_specification() {
    let result = run(SOURCE, false);
    assert_eq!(result.analysis.graph.terminal(), &Terminal::Completed);
    assert_eq!(result.graph.conclusion(), GraphConclusion::Verified);
    let actual = result.analysis.outputs.as_ref().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..64).collect::<Vec<_>>()
    );
    assert_eq!(verdict(&result, 1), Verdict::Accept);
    assert_eq!(verdict(&result, 9), Verdict::Reject);
}

#[test]
fn missing_or_wrong_private_waits_cannot_refute_even_a_wrong_specification() {
    let wait = "\ts_waitcnt vmcnt(0)";
    for operation in ["scratch_store_dword", "scratch_load_dword"] {
        let access = SOURCE.find(operation).unwrap();
        let split = access + SOURCE[access..].find(wait).unwrap();
        for replacement in [
            "\ts_nop 0",
            "\ts_waitcnt vmcnt(1)",
            "\ts_waitcnt lgkmcnt(0)",
        ] {
            let source = format!(
                "{}{}",
                &SOURCE[..split],
                SOURCE[split..].replacen(wait, replacement, 1)
            );
            for early in [false, true] {
                let result = run(&source, early);
                assert!(
                    matches!(result.analysis.graph.terminal(), Terminal::Aborted { cause: AbortCause::Unsupported, reason, .. }
                    if reason.contains("explicit VM0")),
                    "{operation}: {replacement}, early={early}: {:?}",
                    result.analysis.graph.terminal()
                );
                assert!(result.analysis.outputs.is_err());
                assert!(result.early_readiness.is_none());
                assert!(result.early_memory_conflict.is_none());
                assert!(result.tensor_bounds.is_none());
                assert!(matches!(
                    result.graph.conclusion(),
                    GraphConclusion::Unknown { .. }
                ));
                assert_eq!(
                    verdict(&result, 9),
                    Verdict::Unknown,
                    "{operation}: {replacement}, early={early}"
                );
            }
        }
    }
}
