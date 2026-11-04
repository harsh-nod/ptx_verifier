//! Genuine public compiler tensor kernel; harmful assembly changes are CPU-only.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::{AccessMode, AmdEventKind, Terminal};
use volta_graph_check::GraphConclusion;
use volta_pipeline::{KernelModule, verify_source_kernel};

const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-tensor-roundtrip.s");
const LOAD: &str = "tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]";
const STORE: &str = "tensor_store_from_lds s[16:19], s[8:15], s[20:23], s[20:23]";
fn config() -> AnalysisConfig {
    let mut c = AnalysisConfig::new((64, 1, 1));
    c.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 128,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 128,
            kind: ArrayKind::Output,
        },
    ];
    c.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    c
}
fn run(source: &str) -> volta_pipeline::SourceKernelVerification {
    verify_source_kernel(
        &KernelModule::Amdgpu(frontend::parse(source).unwrap()),
        Some("tensor_roundtrip"),
        config(),
    )
    .unwrap()
}

#[test]
fn original_exact_boundary_tensor_retains_all_128_outputs_and_no_fault() {
    let v = run(SOURCE);
    assert_eq!(v.graph.conclusion(), GraphConclusion::Verified);
    assert!(v.tensor_bounds.is_none());
    let outputs = v.analysis.outputs.unwrap();
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..128).collect::<Vec<_>>()
    );
}

#[test]
fn compiler_load_and_store_outside_declared_lds_get_only_private_certified_rejections() {
    for (op, lds, mode) in [(LOAD, 5, AccessMode::Write), (STORE, 17, AccessMode::Read)] {
        assert!(SOURCE.contains(op));
        let mutant = SOURCE.replacen(op, &format!("s_mov_b32 s{lds}, 256\n\t{op}"), 1);
        let native = volta_amdgpu_analysis::analyze(
            &frontend::parse(&mutant).unwrap(),
            Some("tensor_roundtrip"),
            config(),
        )
        .unwrap();
        assert!(matches!(
            native.symbolic_outputs(),
            Err(volta_amdgpu_analysis::OutputsUnavailable::Aborted(
                volta_amdgpu_analysis::EvalError::TensorBounds { what, .. }
            )) if *what == volta_graph::TENSOR_BOUNDS_ABORT_REASON
        ));
        let v = run(&mutant);
        let candidate =
            volta_graph_check::amdgpu::tensor_bounds::tensor_bounds_candidate(&v.analysis.graph)
                .unwrap_or_else(|| {
                    panic!(
                        "{op}: outputs={:?}, terminal={:?}, last={:?}",
                        v.analysis.outputs.as_ref().err(),
                        v.analysis.graph.terminal(),
                        v.analysis.graph.amd_events().last()
                    )
                });
        let replay = volta_graph_check::amdgpu::tensor_bounds::validate_tensor_bounds_prefix(
            &v.analysis.graph,
            &candidate,
        );
        assert!(
            replay.is_ok(),
            "{op}: {replay:?}; {:?}",
            v.analysis.graph.amd_events().last()
        );
        let violation = v
            .tensor_bounds
            .as_ref()
            .expect("independent bounds replay")
            .violation();
        assert_eq!(
            (
                violation.address,
                violation.bytes,
                violation.configured_lds_bytes
            ),
            (256, 256, 256)
        );
        assert_eq!(violation.access, mode);
        assert!(v.analysis.outputs.is_err());
        assert!(matches!(
            v.analysis.graph.terminal(),
            Terminal::Aborted { .. }
        ));
        assert!(matches!(
            v.graph.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
        assert!(matches!(
            v.analysis.graph.amd_events().last().unwrap().kind,
            AmdEventKind::TensorAccessFault { .. }
        ));
    }
}

#[test]
fn unrelated_abort_and_unsupported_descriptor_remain_unclassified() {
    let bad = SOURCE.replacen(LOAD, &format!("s_mov_b32 s20, 1\n\t{LOAD}"), 1);
    let v = run(&bad);
    assert!(v.tensor_bounds.is_none());
    assert!(v.analysis.outputs.is_err());
    assert!(matches!(
        v.graph.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

#[test]
fn pending_descriptor_load_or_exec_zero_never_promotes_a_tensor_fault() {
    let bad = SOURCE.replacen(LOAD, &format!("s_mov_b32 s5, 256\n\t{LOAD}"), 1);
    assert!(bad.contains("s_wait_kmcnt 0x0"));
    let pending = run(&bad.replacen("s_wait_kmcnt 0x0", "s_nop 0", 1));
    assert!(pending.tensor_bounds.is_none());
    assert!(pending.analysis.outputs.is_err());
    let masked = run(&SOURCE.replacen(
        LOAD,
        &format!("s_mov_b32 s5, 256\n\ts_mov_b32 exec_lo, 0\n\t{LOAD}\n\ts_mov_b32 exec_lo, 1"),
        1,
    ));
    assert!(masked.tensor_bounds.is_none());
    assert!(
        !masked
            .analysis
            .graph
            .amd_events()
            .iter()
            .any(|e| matches!(e.kind, AmdEventKind::TensorAccessFault { .. }))
    );
}
