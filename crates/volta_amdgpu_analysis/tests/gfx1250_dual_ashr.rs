//! Native VOPD arithmetic shifts use one preissue snapshot for both halves.
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

fn run(body: &str, expected: [u32; 2]) {
    let module = frontend::parse(&source(body)).unwrap();
    let mut config = config();
    config.arrays[0].len = 2;
    let result = analyze(&module, Some("k"), config).unwrap();
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(output.outputs.len(), 1);
    assert_eq!(output.outputs[0].1.len(), 2);
    for (index, expected) in expected.into_iter().enumerate() {
        assert_eq!(output.outputs[0].1[index].0, index as u64);
        assert_eq!(
            output.arena.as_int_const(output.outputs[0].1[index].1),
            Some(i64::from(expected))
        );
    }
    result.graph().validate().unwrap();
}

#[test]
fn actual_compiler_dual_signed_shift_preserves_all_32_source_bits() {
    for input in [0u32, 0x7fffffff, 0x80000000, u32::MAX] {
        run(
            &format!(
                "v_mov_b32 v0,{input}\nv_mov_b32 v2,3\nv_dual_add_nc_u32 v2,-11,v2 :: v_dual_ashrrev_i32 v1,31,v0\nv_add_nc_u32 v1,0,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0,v2,s[4:5] offset:4\ns_wait_storecnt 0"
            ),
            [((input as i32) >> 31) as u32, 3u32.wrapping_sub(11)],
        );
    }
}

#[test]
fn dual_arithmetic_shift_observes_the_source_before_its_other_half_overwrites_it() {
    run(
        "v_mov_b32 v0,0x7fffffff\nv_dual_add_nc_u32 v0,1,v0 :: v_dual_ashrrev_i32 v1,31,v0\nv_add_nc_u32 v1,0,v1\nv_mov_b32 v2,v0\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0,v2,s[4:5] offset:4\ns_wait_storecnt 0",
        [0, 0x80000000],
    );
}

#[test]
fn selected_dual_arithmetic_shift_rejects_unmodeled_source_encodings() {
    for bad in [
        "v_dual_add_nc_u32 v2,-11,v2 :: v_dual_ashrrev_i32 v1,128,v0",
        "v_dual_add_nc_u32 v2,-11,v2 :: v_dual_ashrrev_i32 v1,31,s0",
        "v_dual_add_nc_u32 v2,-11,v2 :: v_dual_ashrrev_i32 v1,31,-v0",
        "v_dual_add_nc_u32 v2,-11,v2 :: v_dual_ashrrev_i32 v2,31,v0",
    ] {
        assert!(frontend::parse(&source(bad)).is_err(), "{bad}");
    }
}
