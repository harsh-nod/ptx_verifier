//! The native B32 scalar-base FLAT profile scales only its VGPR index.
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
v_mov_b32 v0,1
v_mov_b32 v2,0
{body}
s_wait_storecnt_dscnt 0
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_group_segment_fixed_size 16
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
fn run(body: &str) -> native_common::Checked {
    let s = source(body);
    let m = frontend::parse(&s).unwrap();
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 3,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 3,
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
fn flat_load_scales_index_but_keeps_immediate_in_bytes() {
    let r = run(
        "flat_load_b32 v1,v0,s[4:5] offset:4 scale_offset scope:SCOPE_SYS\ns_wait_loadcnt_dscnt 0\nv_add_f32 v1,0,v1\nglobal_store_b32 v2,v1,s[6:7]",
    );
    assert_eq!(
        r.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        r.checks
    );
    let o = r.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.outputs[0].1.len(), 1);
    assert_eq!(o.outputs[0].1[0].0, 0);
    assert_eq!(o.arena.display_expr(o.outputs[0].1[0].1), "x[2]");
}
#[test]
fn flat_store_scales_real_destination_without_filling_neighbor_outputs() {
    let r = run("v_add_f32 v1,0,1.25\nflat_store_b32 v0,v1,s[6:7] scale_offset scope:SCOPE_SYS");
    assert_eq!(
        r.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        r.checks
    );
    let o = r.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.outputs[0].1.len(), 1);
    assert_eq!(o.outputs[0].1[0].0, 1);
    assert_eq!(o.arena.as_f64(o.outputs[0].1[0].1), Some(1.25));
}
#[test]
fn scaled_shared_address_preserves_opaque_aperture_and_both_data_waits() {
    let r = run(
        "s_mov_b64 s[8:9],src_shared_base\nv_mov_b32 v0,4\nv_add_f32 v1,0,2.5\nds_store_b32 v0,v1\ns_wait_dscnt 0\nv_mov_b32 v0,1\nflat_load_b32 v1,v0,s[8:9] scale_offset scope:SCOPE_SYS\ns_wait_loadcnt_dscnt 0\nglobal_store_b32 v2,v1,s[6:7]",
    );
    assert_eq!(
        r.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        r.checks
    );
    let o = r.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.outputs[0].1.len(), 1);
    assert_eq!(o.arena.as_f64(o.outputs[0].1[0].1), Some(2.5));
}
#[test]
fn scaled_flat_footprints_do_not_wrap_or_cross_allocation_bounds() {
    for body in [
        "v_mov_b32 v0,3\nflat_load_b32 v1,v0,s[4:5] scale_offset scope:SCOPE_SYS",
        "s_mov_b64 s[8:9],src_shared_base\nv_mov_b32 v0,0xffffffff\nflat_load_b32 v1,v0,s[8:9] scale_offset scope:SCOPE_SYS",
    ] {
        let r = run(body);
        let e = r.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(e.contains("out-of-bounds") || e.contains("aperture"), "{e}");
        assert_ne!(r.checks.conclusion(), GraphConclusion::Verified);
    }
}
#[test]
fn scaled_flat_profile_does_not_widen_encodings_or_older_targets() {
    for op in [
        "flat_load_b64 v[0:1],v2,s[4:5] scale_offset scope:SCOPE_SYS",
        "flat_load_b32 v1,v[2:3] scale_offset scope:SCOPE_SYS",
    ] {
        assert!(frontend::parse(&source(op)).is_err());
    }
    for target in ["gfx942", "gfx950"] {
        assert!(
            frontend::parse(
                &source("flat_load_dword v1,v[2:3] scale_offset").replace("gfx1250", target)
            )
            .is_err()
        );
    }
}

const SHARED_BASE: &str =
    "s_mov_b64 s[8:9],src_shared_base\nv_mov_b64 v[4:5],s[8:9]\nv_mov_b32 v2,1\nv_mov_b32 v3,0";
#[test]
fn wide_shift_add_preserves_exact_opaque_shared_base_under_destination_alias() {
    let result = run(&format!(
        "{SHARED_BASE}\nv_lshl_add_u64 v[4:5],v[2:3],2,v[4:5]\nv_mov_b32 v0,4\nv_add_f32 v1,0,2.5\nds_store_b32 v0,v1\ns_wait_dscnt 0\nflat_load_b32 v1,v[4:5] scope:SCOPE_SYS\ns_wait_loadcnt_dscnt 0\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[6:7]"
    ));
    assert_eq!(
        result.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        result.checks
    );
    let outputs = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(outputs.outputs[0].1[0].0, 0);
    assert_eq!(outputs.arena.as_f64(outputs.outputs[0].1[0].1), Some(2.5));
}
#[test]
fn wide_shared_address_does_not_define_uninitialized_lds_or_numeric_aperture_bits() {
    for (consumer, expected) in [
        ("flat_load_b32 v1,v[4:5] scope:SCOPE_SYS", "uninitialized"),
        ("v_add_nc_u32 v1,0,v5", "opaque shared aperture"),
    ] {
        let result = run(&format!(
            "{SHARED_BASE}\nv_lshl_add_u64 v[4:5],v[2:3],2,v[4:5]\n{consumer}"
        ));
        let error = result.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains(expected), "{error}");
        assert_ne!(result.checks.conclusion(), GraphConclusion::Verified);
    }
}
#[test]
fn wide_shared_address_refuses_carry_and_unknown_or_data_dependent_indices() {
    for (prepare, shift, expected) in [
        ("v_mov_b32 v2,0x40000000", 2, "escapes the shared aperture"),
        ("v_mov_b32 v2,2", 63, "escapes the shared aperture"),
        (
            "v_mov_b32 v0,0\nglobal_load_b64 v[2:3],v0,s[4:5]\ns_wait_loadcnt 0",
            2,
            "symbolic mathematical data",
        ),
        ("v_mov_b32 v2,v12", 2, "uninitialized"),
    ] {
        let result = run(&format!(
            "{SHARED_BASE}\n{prepare}\nv_lshl_add_u64 v[4:5],v[2:3],{shift},v[4:5]"
        ));
        let error = result.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains(expected), "{error}");
        assert_ne!(result.checks.conclusion(), GraphConclusion::Verified);
    }
}
