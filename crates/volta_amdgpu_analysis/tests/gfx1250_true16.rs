//! gfx1250 true16 destination preservation; hardware probes are recorded separately.
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

#[test]
fn native_true16_arithmetic_preserves_initialized_upper_half() {
    for encoding in ["e32", "e64"] {
        for (operation, expected) in [
            ("fmac", 7.),
            ("add", 5.),
            ("mul", 6.),
            ("sub", -1.),
            ("max_num", 3.),
        ] {
            let source = native(&format!(
                "v_mov_b32 v1, 0x35553c00\nv_mov_b32 v2, 0x2aaa4000\nv_mov_b32 v3, 0x2aaa4200\nv_{operation}_f16_{encoding} v1, v2, v3\nv_cvt_f32_f16 v4, v1\nv_lshrrev_b32 v1, 16, v1\nv_cvt_f32_f16 v1, v1\nv_mov_b32 v0, 0\nglobal_store_b32 v0, v4, s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0, v1, s[4:5] offset:4\ns_wait_xcnt 0\ns_wait_storecnt 0"
            ));
            let module = frontend::parse(&source).unwrap();
            let mut config = AnalysisConfig::new((1, 1, 1));
            config.arrays.push(ArrayDef {
                name: "out".into(),
                base: 65536,
                elem_width: 4,
                len: 2,
                kind: ArrayKind::Output,
            });
            config
                .params
                .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
            let analysis = analyze(&module, Some("k"), config).unwrap();
            let output = analysis.symbolic_outputs().unwrap();
            assert_eq!(output.outputs[0].1.len(), 2);
            assert_eq!(
                output.arena.as_f64(output.outputs[0].1[0].1),
                Some(expected)
            );
            assert_eq!(
                output.arena.as_f64(output.outputs[0].1[1].1),
                Some(0.333251953125)
            );
        }
    }
}

#[test]
fn native_true16_arithmetic_does_not_fabricate_uninitialized_upper_half() {
    let source = native(
        "v_mov_b32 v2, 0x4000\nv_mov_b32 v3, 0x4200\nv_add_f16_e64 v1,v2,v3\nv_lshrrev_b32 v1,16,v1\nv_cvt_f32_f16 v1,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]",
    );
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    });
    config
        .params
        .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
    let analysis = analyze(&module, Some("k"), config).unwrap();
    assert!(format!("{:?}", analysis.symbolic_outputs().unwrap_err()).contains("unknown half"));
}

#[test]
fn native_true16_conversion_preserves_initialized_upper_half() {
    for encoding in ["e32", "e64"] {
        let source = native(&format!(
            "v_mov_b32 v1,0x35553c00\nv_mov_b32 v2,0x40000000\nv_cvt_f16_f32_{encoding} v1,v2\nv_lshrrev_b32 v1,16,v1\nv_cvt_f32_f16 v1,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
        ));
        let module = frontend::parse(&source).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 65536,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        config
            .params
            .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
        let analysis = analyze(&module, Some("k"), config).unwrap();
        let output = analysis.symbolic_outputs().unwrap();
        assert_eq!(
            output.arena.as_f64(output.outputs[0].1[0].1),
            Some(0.333251953125)
        );
    }
}
