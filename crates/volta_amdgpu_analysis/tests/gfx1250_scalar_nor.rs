//! Scalar NOR preserves exact bit definedness and derives SCC only from known bits.
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
        len: 2,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn assert_output(body: &str, expected: [u32; 2]) {
    let module = frontend::parse(&source(body)).unwrap();
    let result = analyze(&module, Some("k"), config()).unwrap();
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(output.outputs.len(), 1);
    assert_eq!(output.outputs[0].0, "out");
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
fn scalar_nor_complements_both_sources_and_sets_scc_from_nonzero_result() {
    for (a, b) in [
        (0u32, 0u32),
        (u32::MAX, 0),
        (0xaaaaaaaa, 0x55555555),
        (0x8000, 1),
        (u32::MAX, u32::MAX),
    ] {
        let value = !(a | b);
        assert_output(
            &format!(
                "s_mov_b32 s6,{a}\ns_mov_b32 s7,{b}\ns_nor_b32 s6,s6,s7\ns_cselect_b32 s7,1,0\nv_mov_b32 v0,0\nv_mov_b32 v1,s6\nv_mov_b32 v2,s7\nv_add_nc_u32 v2,0,v2\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0,v2,s[4:5] offset:4\ns_wait_storecnt 0"
            ),
            [value, u32::from(value != 0)],
        );
    }
}

#[test]
fn scalar_nor_all_ones_masks_unknown_source_and_proves_zero_scc() {
    assert_output(
        "s_nor_b32 s6,s8,-1\ns_cselect_b32 s7,1,0\nv_mov_b32 v0,0\nv_mov_b32 v1,s6\nv_mov_b32 v2,s7\nv_add_nc_u32 v2,0,v2\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0,v2,s[4:5] offset:4\ns_wait_storecnt 0",
        [0, 0],
    );
}

#[test]
fn scalar_nor_can_prove_nonzero_scc_without_inventing_other_result_bits() {
    // AND forces only bit0 of the unknown word to zero. NOR then makes bit0
    // definitely one, which suffices for SCC=1; all other bits stay unknown.
    assert_output(
        "s_and_b32 s6,s8,-2\ns_nor_b32 s6,s6,0\ns_cselect_b32 s7,1,0\nv_mov_b32 v0,0\nv_mov_b32 v1,s7\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\nglobal_store_b32 v0,v1,s[4:5] offset:4\ns_wait_storecnt 0",
        [1, 1],
    );
}

#[test]
fn scalar_nor_unknown_bits_and_unknown_scc_cannot_escape() {
    for consumer in ["s_cselect_b32 s7,1,0\nv_mov_b32 v1,s7", "v_mov_b32 v1,s6"] {
        let module = frontend::parse(&source(&format!(
            "s_nor_b32 s6,s8,0\n{consumer}\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]"
        )))
        .unwrap();
        let result = analyze(&module, Some("k"), config()).unwrap();
        let error = result.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("undefined") || error.contains("uninitialized SCC"),
            "{consumer}: {error}"
        );
    }
}
