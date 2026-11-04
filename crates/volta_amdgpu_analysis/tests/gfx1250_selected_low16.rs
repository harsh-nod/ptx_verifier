//! True16 shifts consume only their selected inputs and never define an upper half.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend};

fn source(body: &str) -> String {
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

fn config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn assert_output(body: &str, expected: f64) {
    let module = frontend::parse(&source(body)).unwrap();
    let result = analyze(&module, Some("k"), config()).unwrap();
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(output.outputs.len(), 1);
    assert_eq!(output.outputs[0].0, "out");
    assert_eq!(output.outputs[0].1.len(), 1);
    assert_eq!(output.outputs[0].1[0].0, 0);
    assert_eq!(
        output.arena.as_f64(output.outputs[0].1[0].1),
        Some(expected)
    );
    result.graph().validate().unwrap();
}

#[test]
fn convolution_mul_shift_mul_prologue_consumes_defined_low16() {
    for lane in [0u32, 1, 15, 31, 63, 127] {
        let product = lane * 29;
        let expected = ((product & 65535) >> 8) * 9;
        assert_output(
            &format!(
                "v_mov_b32 v2,{lane}\nv_mul_lo_u16 v1,v2,29\nv_lshrrev_b16 v1,8,v1\nv_mul_lo_u16 v1,v1,9\nv_and_b32 v1,0xffff,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
            ),
            f64::from(expected),
        );
    }
}

#[test]
fn logical_shifts_use_low16_data_and_only_low4_count_bits() {
    for (opcode, input, shift, expected) in [
        ("v_lshrrev_b16", 0x8001u32, 0u32, 0x8001u32),
        ("v_lshrrev_b16", 0x8001, 1, 0x4000),
        ("v_lshrrev_b16", 0x8001, 15, 1),
        ("v_lshrrev_b16", 0x8001, 17, 0x4000),
        ("v_lshlrev_b16", 0x8001, 0, 0x8001),
        ("v_lshlrev_b16", 0x8001, 1, 2),
        ("v_lshlrev_b16", 0x8001, 15, 0x8000),
        ("v_lshlrev_b16", 0x8001, 17, 2),
    ] {
        assert_output(
            &format!(
                "v_mov_b32 v2,{input}\nv_mul_lo_u16 v2,v2,1\nv_mov_b32 v3,{shift}\nv_mul_lo_u16 v3,v3,1\n{opcode} v1,v3,v2\nv_and_b32 v1,0xffff,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
            ),
            f64::from(expected),
        );
    }
}

#[test]
fn arithmetic_shift_accepts_partial_low16_data_and_count() {
    for (shift, expected) in [
        (0, -32768.),
        (1, -16384.),
        (8, -128.),
        (15, -1.),
        (17, -16384.),
    ] {
        assert_output(
            &format!(
                "v_mov_b32 v2,0x8000\nv_mul_lo_u16 v2,v2,1\nv_mov_b32 v3,{shift}\nv_mul_lo_u16 v3,v3,1\nv_ashrrev_i16 v1,v3,v2\nv_cvt_f16_i16 v1,v1\nv_cvt_f32_f16 v1,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
            ),
            expected,
        );
    }
}

#[test]
fn narrow_shift_results_cannot_escape_through_fullword_consumers() {
    for opcode in ["v_lshrrev_b16", "v_lshlrev_b16", "v_ashrrev_i16"] {
        for consumer in [
            "global_store_b32 v0,v1,s[4:5]",
            "v_add_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[4:5]",
            "v_lshrrev_b32 v1,16,v1\nglobal_store_b32 v0,v1,s[4:5]",
        ] {
            let module = frontend::parse(&source(&format!(
                "v_mov_b32 v2,0x8000\nv_mul_lo_u16 v2,v2,1\n{opcode} v1,8,v2\nv_mov_b32 v0,0\n{consumer}"
            )))
            .unwrap();
            let result = analyze(&module, Some("k"), config()).unwrap();
            assert!(result.symbolic_outputs().is_err(), "{opcode}: {consumer}");
        }
    }
}
