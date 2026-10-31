//! First-finding mode preserves ordinary complete-trace checking by default.
use std::ops::ControlFlow;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::{AbortCause, AmdEventKind, Terminal};
use volta_graph_check::{
    GraphConclusion, amdgpu::early_readiness::validate_scalar_readiness_prefix, check_graph,
};
use volta_pipeline::{KernelModule, SourceKernelVerification, verify_source_kernel};

fn source(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_wait_kmcnt 0
{body}
s_wait_kmcnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}
fn config(early: bool) -> AnalysisConfig {
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.early_readiness = early;
    c.arrays.push(ArrayDef {
        name: "x".into(),
        base: 65536,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::IndexInput,
    });
    c.params.push(ParamValue::ArrayPtr("x".into()));
    c
}
fn run(body: &str, early: bool) -> SourceKernelVerification {
    let module = KernelModule::Amdgpu(frontend::parse(&source(body)).unwrap());
    verify_source_kernel(&module, Some("k"), config(early)).unwrap()
}
const BAD: &str = "s_load_b32 s6,s[4:5],0\ns_mov_b32 s7,s6\ns_mov_b32 s8,s6";

#[test]
fn certified_first_finding_replays_without_end_or_outputs() {
    let result = run(BAD, true);
    let finding = result
        .early_readiness
        .as_ref()
        .expect("certified first read");
    assert!(result.analysis.outputs.is_err());
    assert_eq!(result.analysis.stats.instructions, 4);
    assert!(
        matches!(result.analysis.graph.terminal(),Terminal::Aborted{cause:AbortCause::Error,reason,..} if reason==volta_amdgpu_analysis::OBSERVER_STOP_REASON)
    );
    assert_eq!(
        validate_scalar_readiness_prefix(&result.analysis.graph, finding.certificate()).unwrap(),
        *finding.hazard()
    );
    assert_eq!(
        finding.certificate().amd_records,
        result.analysis.graph.amd_events().len()
    );
    assert!(!result.analysis.graph.amd_events().iter().any(|e| {
        matches!(e.kind, AmdEventKind::Instruction { .. })
            && result
                .analysis
                .graph
                .event(e.event)
                .pc
                .is_some_and(|pc| pc.0 == 7)
    }));
    assert_ne!(result.graph.conclusion(), GraphConclusion::Verified);
}

#[test]
fn default_mode_keeps_both_bad_sites_and_the_complete_original_trace() {
    assert!(!AnalysisConfig::new((1, 1, 1)).early_readiness);
    let ordinary = run(BAD, false);
    assert!(ordinary.early_readiness.is_none());
    assert_eq!(ordinary.analysis.graph.terminal(), &Terminal::Completed);
    assert!(ordinary.analysis.outputs.is_ok());
    let report = volta_graph_check::amdgpu::check_amdgpu(&ordinary.analysis.graph);
    assert_eq!(report.wait_readiness.violations().len(), 2);
    let again = run(BAD, false);
    assert_eq!(ordinary.analysis.graph.dump(), again.analysis.graph.dump());
    assert_eq!(ordinary.analysis.stats.instructions, 8);
    assert!(matches!(
        ordinary.graph.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn correct_km_waits_complete_while_x_and_nonzero_km_do_not() {
    for wait in ["s_wait_xcnt 0", "s_wait_kmcnt 1", ""] {
        let result = run(
            &format!("s_load_b32 s6,s[4:5],0\n{wait}\ns_mov_b32 s7,s6"),
            true,
        );
        assert!(result.early_readiness.is_some(), "{wait}");
    }
    let safe = "s_load_b32 s6,s[4:5],0\ns_wait_kmcnt 0\ns_mov_b32 s7,s6";
    let enabled = run(safe, true);
    let ordinary = run(safe, false);
    assert!(enabled.early_readiness.is_none());
    assert_eq!(enabled.graph.conclusion(), GraphConclusion::Verified);
    assert_eq!(
        enabled.analysis.graph.dump(),
        ordinary.analysis.graph.dump()
    );
    assert_eq!(
        enabled.analysis.stats.instructions,
        ordinary.analysis.stats.instructions
    );
}

#[test]
fn generic_callback_break_is_only_an_aborted_unknown_prefix() {
    let module = frontend::parse(&source(BAD)).unwrap();
    for stop_at in [1, 4] {
        let mut batches = 0;
        let mut hook = |graph: &volta_graph::EventGraph| {
            batches += 1;
            if batches == 1 {
                assert_eq!(
                    graph.amd_memory_effects().len(),
                    2,
                    "all B64 effects precede hook"
                );
            }
            if batches == stop_at {
                ControlFlow::Break(())
            } else {
                ControlFlow::Continue(())
            }
        };
        let result = volta_amdgpu_analysis::analyze_with_observer(
            &module,
            Some("k"),
            config(true),
            &mut hook,
        )
        .unwrap();
        assert_eq!(batches, stop_at);
        assert!(result.symbolic_outputs().is_err());
        assert!(
            matches!(
                check_graph(result.graph()).conclusion(),
                GraphConclusion::Unknown { .. }
            ),
            "stop at {stop_at}"
        );
    }
}

#[test]
fn unsupported_execution_and_other_properties_do_not_get_scalar_certificates() {
    let unsupported = run("s_getreg_b32 s6,hwreg(HW_REG_MODE,0,32)", true);
    assert!(unsupported.early_readiness.is_none());
    assert!(unsupported.analysis.outputs.is_err());
    let module = KernelModule::Amdgpu(frontend::parse(&source(BAD)).unwrap());
    let mut limited = config(true);
    limited.max_instructions = 2;
    let budget = verify_source_kernel(&module, Some("k"), limited).unwrap();
    assert!(budget.early_readiness.is_none() && budget.analysis.outputs.is_err());
    let destination = run("s_load_b32 s6,s[4:5],0\ns_mov_b32 s6,7", true);
    assert!(destination.early_readiness.is_none());
    assert!(matches!(
        destination.graph.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

#[test]
fn native_option_requires_a_managed_observer_and_supported_target() {
    let module = frontend::parse(&source(BAD)).unwrap();
    assert!(volta_amdgpu_analysis::analyze(&module, Some("k"), config(true)).is_err());
    let mut hook = |_: &volta_graph::EventGraph| ControlFlow::Continue(());
    assert!(
        volta_amdgpu_analysis::analyze_with_observer(&module, Some("k"), config(false), &mut hook)
            .is_err()
    );
    let legacy = source("")
        .replace("gfx1250", "gfx950")
        .replace("s_load_b64", "s_load_dwordx2")
        .replace("s_wait_kmcnt 0", "s_waitcnt lgkmcnt(0)")
        .replace("s_wait_xcnt 0", "")
        .replace(".amdhsa_wavefront_size32 1", "");
    let module = KernelModule::Amdgpu(frontend::parse(&legacy).unwrap());
    assert!(
        verify_source_kernel(&module, Some("k"), config(true))
            .err()
            .unwrap()
            .contains("only gfx1250")
    );
}
