//! Native assembly through analysis and the graph suite, with exact independent
//! instruction spacing controls for CDNA4 software dependencies.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph_check::amdgpu::AmdRegisterHazardKind;
use volta_graph_check::{GraphConclusion, PropertyResult};
use volta_pipeline::{KernelModule, SourceKernelVerification, verify_source_kernel};

fn verify(body: &str) -> SourceKernelVerification {
    let source = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl k
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v2, 2, v0
{body}
v_add_u32 v5, 0, 0
global_store_dword v2, v5, s[6:7]
s_endpgm
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .kernarg_segment_size: 16
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    );
    let module = KernelModule::Amdgpu(frontend::parse(&source).unwrap());
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 64,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 64,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let result = verify_source_kernel(&module, Some("k"), config).unwrap();
    assert_eq!(
        result.analysis.outputs.as_ref().unwrap().outputs[0].1.len(),
        64
    );
    assert!(result.analysis.graph.validate().is_ok());
    assert!(matches!(
        &result.graph.amd.as_ref().unwrap().trace,
        PropertyResult::Pass(_)
    ));
    result
}

fn assert_hazard(result: &SourceKernelVerification, expected: AmdRegisterHazardKind) {
    assert!(matches!(
        result.graph.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let hazards = result
        .graph
        .amd
        .as_ref()
        .unwrap()
        .wait_readiness
        .violations();
    assert!(
        hazards.iter().any(|hazard| hazard.kind == expected),
        "{hazards:?}"
    );
}

#[test]
fn valu_scalar_data_requires_two_independent_states() {
    for (delay, safe) in [("", false), ("s_nop 0", false), ("s_nop 1", true)] {
        let result = verify(&format!(
            "v_cmp_lt_u32 s[8:9], v0, 0\n{delay}\nv_mov_b32 v8, s8"
        ));
        if safe {
            assert_eq!(result.graph.conclusion(), GraphConclusion::Verified)
        } else {
            assert_hazard(&result, AmdRegisterHazardKind::ValuScalarReadBeforeReady)
        }
    }
}

#[test]
fn valu_scalar_vmem_address_requires_five_independent_states() {
    // Exactly lane16 compares true: the produced scalar mask is the valid input
    // pointer0x10000, independent of whether enough dependency spacing exists.
    for (delay, safe) in [("", false), ("s_nop 3", false), ("s_nop 4", true)] {
        let result = verify(&format!(
            "v_cmp_eq_u32 s[8:9], v0, 16\n{delay}\nglobal_load_dword v8, v2, s[8:9]\ns_waitcnt vmcnt(0)"
        ));
        if safe {
            assert_eq!(result.graph.conclusion(), GraphConclusion::Verified)
        } else {
            assert_hazard(&result, AmdRegisterHazardKind::ValuScalarReadBeforeReady)
        }
    }
}

#[test]
fn carry_and_condition_roles_are_exempt_but_dual_use_is_not() {
    for mask in ["s[8:9]", "vcc"] {
        let result = verify(&format!(
            "v_cmp_lt_u32 {mask}, v0, 0\nv_cndmask_b32 v8, v0, v0, {mask}\nv_addc_co_u32 v9, {mask}, v0, v0, {mask}"
        ));
        assert_eq!(
            result.graph.conclusion(),
            GraphConclusion::Verified,
            "{mask}: {:#?}",
            result.graph
        );
    }
    let result = verify("v_cmp_eq_u32 s[8:9], v0, v0\nv_cndmask_b32 v8, s8, v0, s[8:9]");
    assert_hazard(&result, AmdRegisterHazardKind::ValuScalarReadBeforeReady);
    let repaired = verify("v_cmp_eq_u32 s[8:9], v0, v0\ns_nop 1\nv_cndmask_b32 v8, s8, v0, s[8:9]");
    assert_eq!(repaired.graph.conclusion(), GraphConclusion::Verified);
}

#[test]
fn empty_exec_scalar_mask_write_still_conflicts_with_pending_smem() {
    for (wait, safe) in [("", false), ("s_waitcnt lgkmcnt(0)", true)] {
        let result = verify(&format!(
            "s_load_dwordx2 s[8:9], s[0:1], 0\ns_mov_b64 s[10:11], exec\ns_mov_b64 exec, 0\n{wait}\nv_cmp_eq_u32 s[8:9], v0, v0\ns_mov_b64 exec, s[10:11]\ns_waitcnt lgkmcnt(0)"
        ));
        if safe {
            assert_eq!(result.graph.conclusion(), GraphConclusion::Verified)
        } else {
            assert_hazard(&result, AmdRegisterHazardKind::DestinationReuse)
        }
    }
}

#[test]
fn valu_exec_update_requires_four_states_before_matrix_even_for_unchanged_mask() {
    for (delay, safe) in [("", false), ("s_nop 2", false), ("s_nop 3", true)] {
        let result = verify(&format!(
            "v_cmpx_eq_u32 vcc, v0, v0\n{delay}\nv_mfma_f32_16x16x4_f32 v[12:15], v0, v0, 0"
        ));
        if safe {
            assert_eq!(result.graph.conclusion(), GraphConclusion::Verified)
        } else {
            assert_hazard(&result, AmdRegisterHazardKind::ValuScalarReadBeforeReady)
        }
    }
}
