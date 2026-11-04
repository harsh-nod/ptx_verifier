//! LLVM GCNSubtarget.h pins hasSignedGVSOffset to gfx1250. Address selection
//! sign-extends the i32 vector index before multiplying by the transfer size:
//! llvm/lib/Target/AMDGPU/{GCNSubtarget.h,AMDGPUISelDAGToDAG.cpp} at
//! 5fd50ec8e07abb94e203933017e8d6e40fb51824.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend,
};

fn source(target: &str, body: &str) -> String {
    let wave32 = target == "gfx1250";
    let wave_descriptor = if wave32 {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    let load = if wave32 {
        "s_load_b64"
    } else {
        "s_load_dwordx2"
    };
    let wait = if wave32 {
        "s_wait_kmcnt 0"
    } else {
        "s_waitcnt lgkmcnt(0)"
    };
    let finish = if wave32 {
        "s_wait_loadcnt 0\ns_wait_storecnt 0\ns_wait_dscnt 0\ns_wait_xcnt 0\ns_endpgm"
    } else {
        "s_waitcnt vmcnt(0)\ns_endpgm"
    };
    let accum = if wave32 { "" } else { ".amdhsa_accum_offset 4" };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.amdhsa_code_object_version 6
.text
.globl address_probe
.type address_probe,@function
.p2align 8
address_probe:
{load} s[4:5], s[0:1], 0
{wait}
{body}
{finish}
.Lend:
.size address_probe, .Lend-address_probe
.amdhsa_kernel address_probe
.amdhsa_user_sgpr_kernarg_segment_ptr 1
{wave_descriptor}
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 8
.amdhsa_next_free_vgpr 4
{accum}
.amdhsa_group_segment_fixed_size 0
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: address_probe
    .symbol: address_probe.kd
    .kernarg_segment_size: 8
    .kernarg_segment_align: 8
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .sgpr_count: 8
    .vgpr_count: 4
    .wavefront_size: {wave_size}
    .max_flat_workgroup_size: 1024
    .args:
      - .name: base
        .offset: 0
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .value_type: f32
...
.end_amdgpu_metadata
"#,
        wave_size = if wave32 { 32 } else { 64 },
    )
}

fn run(target: &str, body: &str, base: u64, output: u64, kind: ArrayKind) -> AnalysisResult {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: output,
        elem_width: 4,
        len: 1,
        kind,
    });
    config.params.push(ParamValue::Int(base as i64));
    let module = frontend::parse(&source(target, body)).unwrap();
    analyze(&module, Some("address_probe"), config).unwrap()
}

fn assert_seven(result: &AnalysisResult) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(
        outputs.arena.as_i64(outputs.element("out", 0).unwrap()),
        Some(7)
    );
    result.graph.validate().unwrap();
}

#[test]
fn gfx1250_global_and_flat_sign_extend_before_scaling_and_add_at_full_width() {
    for memory in ["global", "flat"] {
        for scale in [1i64, 4] {
            for index in [i32::MIN, -4, -1, 0, 1, i32::MAX] {
                for immediate in [-8_388_608i64, -1, 0, 1, 8_388_607] {
                    let output = 0x20000u64;
                    let base = output
                        .wrapping_sub_signed(i64::from(index) * scale)
                        .wrapping_sub_signed(immediate);
                    let modifier = if scale == 4 { " scale_offset" } else { "" };
                    let body = format!(
                        "v_mov_b32 v0, {:#x}\nv_add_u32 v1, 7, 0\n{memory}_store_b32 v0, v1, s[4:5] offset:{immediate}{modifier}",
                        index as u32,
                    );
                    assert_seven(&run("gfx1250", &body, base, output, ArrayKind::Output));
                }
            }
        }
    }
}

#[test]
fn gfx1250_signed_loads_preserve_the_input_at_the_actual_address() {
    for memory in ["global", "flat"] {
        for (index, scale) in [(-4i32, 1u64), (-1, 4)] {
            let modifier = if scale == 4 { " scale_offset" } else { "" };
            let body = format!(
                "v_mov_b32 v0, {:#x}\n{memory}_load_b32 v1, v0, s[4:5]{modifier}\ns_wait_loadcnt 0\ns_wait_dscnt 0\nv_mov_b32 v0, 0\nglobal_store_b32 v0, v1, s[4:5] offset:-4",
                index as u32,
            );
            let result = run("gfx1250", &body, 0x20004, 0x20000, ArrayKind::InputOutput);
            let outputs = result.symbolic_outputs().unwrap();
            assert_eq!(outputs.outputs[0].1.len(), 1);
            assert!(matches!(
                outputs.arena.node(outputs.element("out", 0).unwrap()),
                volta_expr::ExprNode::InputElement { index: 0, .. }
            ));
        }
    }
}

#[test]
fn the_old_zero_extended_alias_cannot_hide_an_out_of_bounds_access() {
    // LLVM-MC accepts this scalar-base GVS profile. Previously all graph
    // checks passed and out[0]=7 was accepted at the zero-extended alias.
    // Its actual address is 0x20000, outside the sole configured output.
    for memory in ["global", "flat"] {
        for (index, scale) in [(-4i32, 1u64), (-1, 4)] {
            let modifier = if scale == 4 { " scale_offset" } else { "" };
            let body = format!(
                "v_mov_b32 v0, {:#x}\nv_add_u32 v1, 7, 0\n{memory}_store_b32 v0, v1, s[4:5]{modifier}",
                index as u32,
            );
            let old_alias = 0x20004 + u64::from(index as u32) * scale;
            let result = run("gfx1250", &body, 0x20004, old_alias, ArrayKind::Output);
            assert!(
                result
                    .symbolic_outputs()
                    .unwrap_err()
                    .to_string()
                    .contains("out-of-bounds")
            );
        }
    }
}

#[test]
fn cdna_scalar_base_indices_remain_unsigned() {
    for target in ["gfx942", "gfx950"] {
        for index in [0u32, 4, 0x8000_0000, 0xffff_fffc] {
            let body = format!(
                "v_mov_b32 v0, {index:#x}\nv_add_u32 v1, 7, 0\nglobal_store_dword v0, v1, s[4:5]",
            );
            assert_seven(&run(
                target,
                &body,
                0x20004,
                0x20004 + u64::from(index),
                ArrayKind::Output,
            ));
        }
    }
}

#[test]
fn vector_pair_addresses_keep_all_sixty_four_bits() {
    for memory in ["global", "flat"] {
        let address = 0x8000_0000_0002_0000u64;
        let off = if memory == "global" { ", off" } else { "" };
        let body = format!(
            "v_mov_b32 v0, {:#x}\nv_mov_b32 v1, {:#x}\nv_add_u32 v2, 7, 0\n{memory}_store_b32 v[0:1], v2{off}",
            address as u32,
            address >> 32,
        );
        assert_seven(&run("gfx1250", &body, 0, address, ArrayKind::Output));
    }
}

#[test]
fn a_signed_flat_index_can_move_back_inside_the_opaque_shared_aperture() {
    for (index, scale) in [(-4i32, 1u64), (-1, 4)] {
        let modifier = if scale == 4 { " scale_offset" } else { "" };
        let body = format!(
            "s_mov_b64 s[6:7], src_shared_base\ns_add_co_u32 s6, s6, 16\nv_mov_b32 v0, {:#x}\nv_add_u32 v1, 7, 0\nflat_store_b32 v0, v1, s[6:7]{modifier}\ns_wait_storecnt 0\ns_wait_dscnt 0\ns_wait_xcnt 0\nv_mov_b32 v0, 12\nds_load_b32 v2, v0\ns_wait_dscnt 0\nv_mov_b32 v0, 0\nglobal_store_b32 v0, v2, s[4:5]",
            index as u32,
        );
        let source = source("gfx1250", &body)
            .replace(
                ".amdhsa_group_segment_fixed_size 0",
                ".amdhsa_group_segment_fixed_size 32",
            )
            .replace(
                ".group_segment_fixed_size: 0",
                ".group_segment_fixed_size: 32",
            );
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        config.params.push(ParamValue::ArrayPtr("out".into()));
        let module = frontend::parse(&source).unwrap();
        let result = analyze(&module, Some("address_probe"), config).unwrap();
        assert_seven(&result);
    }
}

#[test]
fn the_selected_atomic_profile_uses_the_same_signed_scalar_base_address() {
    for (index, scale) in [(-4i32, 1u64), (-1, 4)] {
        let modifier = if scale == 4 { " scale_offset" } else { "" };
        let body = format!(
            "v_mov_b32 v0, {:#x}\nv_mov_b32 v1, 0x40e00000\nglobal_atomic_add_f32 v0, v1, s[4:5] scope:SCOPE_DEV{modifier}",
            index as u32,
        );
        let result = run("gfx1250", &body, 0x20004, 0x20000, ArrayKind::InputOutput);
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 1);
        let volta_expr::ExprNode::Add(a, b) =
            outputs.arena.node(outputs.element("out", 0).unwrap())
        else {
            panic!("atomic add did not retain the original output and addend")
        };
        assert!(matches!(
            outputs.arena.node(*a),
            volta_expr::ExprNode::InputElement { index: 0, .. }
        ));
        assert_eq!(outputs.arena.as_f64(*b), Some(7.0));
        result.graph.validate().unwrap();
    }
}
