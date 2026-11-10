//! Full unchanged registered reduction launch and mathematical output contract.
use std::collections::HashMap;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::EquivCheckOptions;
use volta_graph::{AmdEventKind, AmdMemoryClass, Terminal};
use volta_graph_check::GraphConclusion;
use volta_pipeline::{EquivalenceVerdict, KernelModule, check_equivalence, verify_source_kernel};

const SOURCE: &str =
    include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/portable-f16.s");
const SPEC: &str =
    include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/specs/reduction.spec");

#[test]
fn unchanged_reduction_f16_proves_its_complete_registered_workgroup_output() {
    let mut config = AnalysisConfig::new((128, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 2,
            len: 4096,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x100000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::InputOutput,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let result = verify_source_kernel(
        &KernelModule::Amdgpu(frontend::parse(SOURCE).unwrap()),
        Some("reduction_f16"),
        config,
    )
    .unwrap();
    assert_eq!(result.analysis.graph.terminal(), &Terminal::Completed);
    assert_eq!(
        result.graph.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.graph
    );
    let outputs = result.analysis.outputs.as_ref().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(outputs.outputs[0].1[0].0, 0);
    let expected = volta_spec::extract_expressions_from_spec(
        SPEC,
        &HashMap::from([("R".into(), 1), ("N".into(), 4096), ("TILE".into(), 256)]),
    )
    .unwrap();
    let (equiv, _) = check_equivalence(
        &expected,
        outputs,
        &["out".into()],
        &EquivCheckOptions {
            sample: 0,
            verify_numeric: true,
            ..Default::default()
        },
    );
    assert!(
        matches!(
            equiv,
            EquivalenceVerdict::Equivalent {
                checked: 1,
                total: 1
            }
        ),
        "{equiv:?}"
    );
    let wrong_tile = volta_spec::extract_expressions_from_spec(
        SPEC,
        &HashMap::from([("R".into(), 1), ("N".into(), 4096), ("TILE".into(), 255)]),
    )
    .unwrap();
    let (wrong_equiv, _) = check_equivalence(
        &wrong_tile,
        outputs,
        &["out".into()],
        &EquivCheckOptions {
            sample: 0,
            verify_numeric: true,
            ..Default::default()
        },
    );
    assert!(
        matches!(wrong_equiv, EquivalenceVerdict::Refuted { .. }),
        "{wrong_equiv:?}"
    );
    assert!(
        result
            .analysis
            .graph
            .amd_events()
            .iter()
            .any(|r| matches!(r.kind, AmdEventKind::LaneRead { .. }))
    );
    assert_eq!(
        result
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter(|r| matches!(
                r.kind,
                AmdEventKind::MemoryIssue {
                    class: AmdMemoryClass::GlobalAtomicAddF32NoReturn,
                    ..
                }
            ))
            .count(),
        1
    );
}
