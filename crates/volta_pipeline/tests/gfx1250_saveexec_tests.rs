//! SAVEEXEC's explicit source is operand0; the implicit EXEC mask is operand1.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_expr::{ExprNode, Real};
use volta_graph_check::GraphConclusion;

fn native(wave32: bool, old: u64, input: Option<u64>) -> (String, AnalysisConfig) {
    let (target, width, load, wait, operation, exec) = if wave32 {
        (
            "gfx1250",
            32,
            "s_load_b64",
            "s_wait_kmcnt 0",
            "s_and_not1_saveexec_b32",
            "exec_lo",
        )
    } else {
        (
            "gfx950",
            64,
            "s_load_dwordx2",
            "s_waitcnt lgkmcnt(0)",
            "s_andn2_saveexec_b64",
            "exec",
        )
    };
    let body = if wave32 {
        format!(
            "s_mov_b32 {exec},{old}\n{}\n{operation} s6,s6\ns_cselect_b32 s8,1,0\ns_mov_b32 s7,{exec}\ns_mov_b32 {exec},1\nv_mov_b32 v0,0\nv_add_u32 v1,0,s6\nv_add_u32 v2,0,s7\nv_add_u32 v3,0,s8\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0,v2,s[4:5] offset:4\ns_wait_xcnt 0\nglobal_store_b32 v0,v3,s[4:5] offset:8\ns_wait_storecnt 0",
            input
                .map(|v| format!("s_mov_b32 s6,{v}"))
                .unwrap_or_default()
        )
    } else {
        format!(
            "s_mov_b32 exec_lo,{}\ns_mov_b32 exec_hi,{}\n{}\n{operation} s[6:7],s[6:7]\ns_cselect_b32 s10,1,0\ns_mov_b64 s[8:9],{exec}\ns_mov_b64 {exec},1\nv_mov_b32 v0,0\nv_add_u32 v2,0,s6\nv_add_u32 v3,0,s7\nv_add_u32 v4,0,s8\nv_add_u32 v5,0,s9\nv_add_u32 v6,0,s10\nv_add_u32 v7,0,0\nglobal_store_dwordx2 v0,v[2:3],s[4:5]\ns_waitcnt vmcnt(0)\nglobal_store_dwordx2 v0,v[4:5],s[4:5] offset:8\ns_waitcnt vmcnt(0)\nglobal_store_dwordx2 v0,v[6:7],s[4:5] offset:16\ns_waitcnt vmcnt(0)",
            old as u32,
            (old >> 32) as u32,
            input
                .map(|v| format!(
                    "s_mov_b32 s6,{}\ns_mov_b32 s7,{}",
                    v as u32,
                    (v >> 32) as u32
                ))
                .unwrap_or_default()
        )
    };
    let wave_directive = if wave32 {
        ".amdhsa_wavefront_size32 1"
    } else {
        ".amdhsa_accum_offset 8"
    };
    let source = format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--{target}"
.amdhsa_code_object_version 6
.text
.globl k
.p2align 8
.type k,@function
k:
{load} s[4:5],s[0:1],0
{wait}
{body}
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
{wave_directive}
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.amdhsa_next_free_vgpr 8
.amdhsa_next_free_sgpr 12
.amdhsa_reserve_vcc 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 8
    .kernarg_segment_align: 8
    .wavefront_size: {width}
    .sgpr_count: 14
    .vgpr_count: 8
    .max_flat_workgroup_size: {width}
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    );
    let mut config = AnalysisConfig::new((width, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: if wave32 { 4 } else { 8 },
        len: 3,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    (source, config)
}

#[test]
fn asymmetric_saveexec_masks_preserve_old_mask_new_mask_and_scc_on_both_targets() {
    for wave32 in [true, false] {
        let mask = if wave32 { u32::MAX as u64 } else { u64::MAX };
        for (old, input) in [
            (1, 3),
            (3, 1),
            (0, 4),
            (0x5555555555555555 & mask, 0xaaaaaaaaaaaaaaaa & mask),
            (mask, mask),
        ] {
            let (source, config) = native(wave32, old, Some(input));
            let module = frontend::parse(&source).unwrap();
            let checked = native_common::check(&source, &module, Some("k"), config).unwrap();
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:#?}",
                checked.checks
            );
            let actual = checked.analysis.symbolic_outputs().unwrap();
            assert_eq!(actual.outputs.len(), 1);
            assert_eq!(actual.outputs[0].1.len(), 3);
            let new = input & !old & mask;
            for (index, expected) in [old, new, u64::from(new != 0)].into_iter().enumerate() {
                let (found_index, value) = actual.outputs[0].1[index];
                assert_eq!(found_index, index as u64);
                let found = match actual.arena.node(value) {
                    ExprNode::IntConst(value) => Real::from_i64(*value),
                    ExprNode::RealConst(value) => value.clone(),
                    other => panic!("nonconstant mask {other:?}"),
                };
                assert_eq!(
                    found,
                    Real::from_rational(expected.into()),
                    "wave32={wave32}, old={old:#x}, source={input:#x}, output={index}"
                );
            }
        }
    }
}

#[test]
fn undefined_saveexec_source_masks_remain_unobservable() {
    for wave32 in [true, false] {
        let (source, config) = native(wave32, 1, None);
        let module = frontend::parse(&source).unwrap();
        let checked = native_common::check(&source, &module, Some("k"), config).unwrap();
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("uninitialized"), "{error}");
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
}
