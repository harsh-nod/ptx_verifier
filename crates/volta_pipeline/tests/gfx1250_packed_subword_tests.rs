//! Exact selected packed operands do not observe or fabricate discarded bits.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph_check::GraphConclusion;
fn source(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_b128 s[4:7],s[0:1],0
s_wait_kmcnt 0
v_mov_b32 v0,0
{body}
s_wait_storecnt_dscnt 0
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 16
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
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}
fn run(
    body: &str,
    input_width: u64,
    input_len: u64,
    output_width: u64,
    output_len: u64,
) -> native_common::Checked {
    let s = source(body);
    let m = frontend::parse(&s).unwrap();
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: input_width,
            len: input_len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: output_width,
            len: output_len,
            kind: ArrayKind::Output,
        },
    ];
    c.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    native_common::check(&s, &m, Some("k"), c).unwrap()
}
#[test]
fn low_half_mask_preserves_encoded_payload_and_clears_unknown_discarded_high() {
    for prepare in [
        "global_load_u16 v1,v0,s[4:5]\ns_wait_loadcnt 0",
        "global_load_b32 v2,v0,s[4:5]\ns_wait_loadcnt 0\nv_cvt_f16_f32 v1,v2",
    ] {
        let width = if prepare.contains("cvt") { 4 } else { 2 };
        let r = run(
            &format!(
                "{prepare}\nv_and_b32 v1,0xffff,v1\nv_cvt_f32_f16 v2,v1\nglobal_store_b32 v0,v2,s[6:7]"
            ),
            width,
            1,
            4,
            1,
        );
        assert_eq!(
            r.checks.conclusion(),
            GraphConclusion::Verified,
            "{:?}",
            r.checks
        );
        let o = r.analysis.symbolic_outputs().unwrap();
        assert_eq!(o.outputs[0].1.len(), 1);
        assert_eq!(o.arena.display_expr(o.outputs[0].1[0].1), "x[0]");
    }
}
#[test]
fn high_half_flat_store_selects_the_second_symbolic_payload_instead_of_decoding_low() {
    let r = run(
        "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\nflat_store_d16_hi_b16 v0,v1,s[6:7] scope:SCOPE_SYS",
        2,
        2,
        2,
        1,
    );
    assert_eq!(
        r.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        r.checks
    );
    let o = r.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.outputs[0].1.len(), 1);
    assert_eq!(o.arena.display_expr(o.outputs[0].1[0].1), "x[1]");
}
#[test]
fn selected_high_store_refuses_undefined_high_and_masks_refuse_undefined_low() {
    for (body, width, len) in [
        (
            "global_load_b32 v2,v0,s[4:5]\ns_wait_loadcnt 0\nv_cvt_f16_f32 v1,v2\nflat_store_d16_hi_b16 v0,v1,s[6:7] scope:SCOPE_SYS",
            4,
            1,
        ),
        (
            "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\nv_bfi_b32 v3,0xffff0000,v1,v3\nv_and_b32 v3,0xffff,v3\nglobal_store_b16 v0,v3,s[6:7]",
            2,
            2,
        ),
    ] {
        let result = run(body, width, len, 2, 1);
        let error = result.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("undefined"), "{error}");
        if width == 2 {
            assert!(
                error.contains("undefined low"),
                "failure must occur when the masked low half is consumed: {error}"
            );
        }
        assert_ne!(result.checks.conclusion(), GraphConclusion::Verified);
    }
}

#[test]
fn selected_mask_and_high_store_still_read_the_actual_async_source_register() {
    for consumer in [
        "v_and_b32 v1,0xffff,v1\nglobal_store_b16 v0,v1,s[6:7]",
        "flat_store_d16_hi_b16 v0,v1,s[6:7] scope:SCOPE_SYS",
    ] {
        let r = run(
            &format!("global_load_b32 v1,v0,s[4:5]\n{consumer}"),
            2,
            2,
            2,
            1,
        );
        assert!(r.analysis.symbolic_outputs().is_ok());
        assert!(matches!(
            r.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ));
        assert!(format!("{:?}", r.checks).contains("ReadBeforeReady"));
    }
}
const VALUES: &str = "v_mov_b32 v2,1.0\nv_mov_b32 v3,2.0\nv_mov_b32 v4,4.0\nv_mov_b32 v5,0x41000000\nv_mov_b32 v6,0x41800000\nv_mov_b32 v7,0x42000000";
#[test]
fn native_packed_negation_applies_independently_to_each_output_and_operand() {
    for (op, flags, expected) in [
        (
            "v_pk_add_f32 v[8:9],v[2:3],v[4:5]",
            "neg_lo:[1,0] neg_hi:[0,1]",
            [3.0, -6.0],
        ),
        (
            "v_pk_mul_f32 v[8:9],v[2:3],v[4:5]",
            "neg_lo:[1,0] neg_hi:[0,1]",
            [-4.0, -16.0],
        ),
        (
            "v_pk_fma_f32 v[8:9],v[2:3],v[4:5],v[6:7]",
            "neg_lo:[1,0,1] neg_hi:[0,1,0]",
            [-20.0, 16.0],
        ),
    ] {
        let r = run(
            &format!("{VALUES}\n{op} {flags}\nglobal_store_b64 v0,v[8:9],s[6:7]"),
            4,
            1,
            4,
            2,
        );
        assert_eq!(
            r.checks.conclusion(),
            GraphConclusion::Verified,
            "{:?}",
            r.checks
        );
        let o = r.analysis.symbolic_outputs().unwrap();
        assert_eq!(o.outputs[0].1.len(), 2);
        for (index, value) in expected.iter().enumerate() {
            assert_eq!(o.outputs[0].1[index].0, index as u64);
            assert_eq!(o.arena.as_f64(o.outputs[0].1[index].1), Some(*value));
        }
    }
}
#[test]
fn malformed_negate_arrays_never_get_partial_or_default_semantics() {
    for flags in ["neg_lo:[1]", "neg_lo:[0,2]", "neg_lo:[0,1] neg_lo:[1,0]"] {
        let s = source(&format!(
            "{VALUES}\nv_pk_add_f32 v[8:9],v[2:3],v[4:5] {flags}\nglobal_store_b64 v0,v[8:9],s[6:7]"
        ));
        match frontend::parse(&s) {
            Err(_) => (),
            Ok(m) => {
                let mut c = AnalysisConfig::new((1, 1, 1));
                c.arrays = vec![
                    ArrayDef {
                        name: "x".into(),
                        base: 0x10000,
                        elem_width: 4,
                        len: 1,
                        kind: ArrayKind::Input,
                    },
                    ArrayDef {
                        name: "out".into(),
                        base: 0x20000,
                        elem_width: 4,
                        len: 2,
                        kind: ArrayKind::Output,
                    },
                ];
                c.params = vec![
                    ParamValue::ArrayPtr("x".into()),
                    ParamValue::ArrayPtr("out".into()),
                ];
                let r = native_common::check(&s, &m, Some("k"), c).unwrap();
                assert!(r.analysis.symbolic_outputs().is_err());
                assert_ne!(r.checks.conclusion(), GraphConclusion::Verified);
            }
        }
    }
}
