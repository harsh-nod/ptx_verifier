//! Target-specific immediate encoding; configured allocation bounds still apply.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, analyze, frontend};

fn native(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
k:
s_load_b64 s[4:5], s[0:1], 0
s_wait_kmcnt 0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}

fn output_config(width: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x2000000,
        elem_width: width,
        len: 1,
        kind: ArrayKind::Output,
    });
    config
        .params
        .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
    config
}

#[test]
fn signed24_global_offsets_reach_the_exact_same_byte_with_or_without_index_scaling() {
    for offset in [-8_388_608i64, -4097, 4096, 8192, 8_388_607] {
        for modifier in ["", " scale_offset"] {
            let base = 0x2000000i64 - offset;
            let source = native(&format!(
                "s_mov_b32 s4,{base}\ns_mov_b32 s5,0\nv_mov_b32 v0,0\nv_add_u32 v1,7,0\nglobal_store_b8 v0,v1,s[4:5] offset:{offset}{modifier}\ns_wait_storecnt 0\ns_wait_xcnt 0"
            ));
            let module = frontend::parse(&source).unwrap();
            let analysis = analyze(&module, Some("k"), output_config(1)).unwrap();
            let output = analysis.symbolic_outputs().unwrap();
            assert_eq!(output.outputs[0].1.len(), 1);
            assert_eq!(output.arena.as_int_const(output.outputs[0].1[0].1), Some(7));
            analysis.graph().validate().unwrap();
        }
    }
}

#[test]
fn signed24_global_load_offsets_keep_symbolic_input_identity() {
    for offset in [-8_388_608i64, 8_388_607] {
        let base = 0x3000000i64 - offset;
        let source = native(&format!(
            "s_mov_b32 s6,{base}\ns_mov_b32 s7,0\nv_mov_b32 v0,0\nglobal_load_u8 v1,v0,s[6:7] offset:{offset}\ns_wait_loadcnt 0\nglobal_store_b8 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
        ));
        let module = frontend::parse(&source).unwrap();
        let mut config = output_config(1);
        config.arrays.push(ArrayDef {
            name: "input".into(),
            base: 0x3000000,
            elem_width: 1,
            len: 1,
            kind: ArrayKind::Input,
        });
        let analysis = analyze(&module, Some("k"), config).unwrap();
        let output = analysis.symbolic_outputs().unwrap();
        assert_eq!(output.outputs[0].1.len(), 1);
        let volta_expr::ExprNode::InputElement { array, index } =
            output.arena.node(output.outputs[0].1[0].1)
        else {
            panic!("input identity lost")
        };
        assert_eq!(output.arena.string(*array), "input");
        assert_eq!(*index, 0);
    }
}

#[test]
fn scaling_changes_only_the_vector_index_not_the_global_byte_immediate() {
    let source = native(
        "s_mov_b32 s4,33546232\ns_mov_b32 s5,0\nv_mov_b32 v0,2\nv_add_u32 v1,7,0\nglobal_store_b32 v0,v1,s[4:5] offset:8192 scale_offset\ns_wait_storecnt 0\ns_wait_xcnt 0",
    );
    let module = frontend::parse(&source).unwrap();
    let analysis = analyze(&module, Some("k"), output_config(4)).unwrap();
    let output = analysis.symbolic_outputs().unwrap();
    assert_eq!(output.arena.as_int_const(output.outputs[0].1[0].1), Some(7));
}

#[test]
fn offsets_outside_signed24_or_outside_named_allocation_still_fail_closed() {
    for offset in [-8_388_609i64, 8_388_608] {
        let source = native(&format!(
            "v_mov_b32 v0,0\nv_add_u32 v1,7,0\nglobal_store_b8 v0,v1,s[4:5] offset:{offset}"
        ));
        let module = frontend::parse(&source).unwrap();
        let analysis = analyze(&module, Some("k"), output_config(1)).unwrap();
        assert!(
            format!("{:?}", analysis.symbolic_outputs().unwrap_err())
                .contains("native encoded range")
        );
    }
    let source =
        native("v_mov_b32 v0,0\nv_add_u32 v1,7,0\nglobal_store_b8 v0,v1,s[4:5] offset:8192");
    let module = frontend::parse(&source).unwrap();
    let analysis = analyze(&module, Some("k"), output_config(1)).unwrap();
    assert!(format!("{:?}", analysis.symbolic_outputs().unwrap_err()).contains("out-of-bounds"));
}

#[test]
fn cdna_offsets_keep_their_signed13_boundary() {
    for (offset, valid) in [
        (-4096i64, true),
        (4095, true),
        (-4097, false),
        (4096, false),
    ] {
        let base = 0x2000000i64 - offset;
        let source=native(&format!("s_mov_b32 s4,{base}\ns_mov_b32 s5,0\nv_mov_b32 v0,0\nv_add_u32 v1,7,0\nglobal_store_byte v0,v1,s[4:5] offset:{offset}")).replace("gfx1250","gfx950").replace(".amdhsa_wavefront_size32 1",".amdhsa_wavefront_size32 0").replace("s_load_b64","s_load_dwordx2").replace("s_wait_kmcnt 0","s_waitcnt lgkmcnt(0)");
        let module = frontend::parse(&source).unwrap();
        let analysis = analyze(&module, Some("k"), output_config(1)).unwrap();
        if valid {
            let output = analysis.symbolic_outputs().unwrap();
            assert_eq!(output.arena.as_int_const(output.outputs[0].1[0].1), Some(7));
        } else {
            assert!(
                format!("{:?}", analysis.symbolic_outputs().unwrap_err())
                    .contains("native encoded range")
            );
        }
    }
}
