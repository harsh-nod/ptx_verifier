//! Native gfx1250 two-address LDS loads retain both real locations and data waits.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph_check::GraphConclusion;
fn source(read: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_b64 s[4:5],s[0:1],0
s_wait_kmcnt 0
v_mov_b32 v0,0
v_mov_b32 v1,1.25
v_mov_b32 v2,2.5
ds_store_b32 v0,v1
ds_store_b32 v0,v2 offset:16
s_wait_dscnt 0
{read}
v_add_f32 v2,0,v2
v_add_f32 v3,0,v3
global_store_b64 v0,v[2:3],s[4:5]
s_wait_storecnt 0
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_group_segment_fixed_size 20
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
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
fn run(source: &str) -> native_common::Checked {
    let module = frontend::parse(source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    }];
    config.params = vec![ParamValue::ArrayPtr("out".into())];
    native_common::check(source, &module, Some("k"), config).unwrap()
}
#[test]
fn two_address_load_keeps_original_locations_and_destination_order() {
    for (offsets, expected) in [
        ("offset1:4", [1.25, 2.5]),
        ("offset0:4 offset1:0", [2.5, 1.25]),
    ] {
        let result = run(&source(&format!(
            "ds_load_2addr_b32 v[2:3],v0 {offsets}\ns_wait_dscnt 0"
        )));
        assert_eq!(
            result.checks.conclusion(),
            GraphConclusion::Verified,
            "{:?}",
            result.checks
        );
        let out = result.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs[0].1.len(), 2);
        for (index, value) in expected.iter().enumerate() {
            assert_eq!(out.outputs[0].1[index].0, index as u64);
            assert_eq!(out.arena.as_f64(out.outputs[0].1[index].1), Some(*value));
        }
    }
}
#[test]
fn two_address_load_needs_its_data_wait_even_with_complete_candidate_outputs() {
    let result = run(&source("ds_load_2addr_b32 v[2:3],v0 offset1:4"));
    assert!(result.analysis.symbolic_outputs().is_ok());
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    assert!(format!("{:?}", result.checks).contains("ReadBeforeReady"));
}
#[test]
fn two_address_load_validates_both_footprints_and_native_offset_field() {
    for (offset, error) in [(5, "out-of-bounds"), (0, "equal-offset")] {
        let result = run(&source(&format!(
            "ds_load_2addr_b32 v[2:3],v0 offset1:{offset}\ns_wait_dscnt 0"
        )));
        let message = result.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(message.contains(error), "{message}");
        assert_ne!(result.checks.conclusion(), GraphConclusion::Verified);
    }
}
#[test]
fn two_address_load_uses_one_address_vgpr_and_exact_destination_pair() {
    assert!(frontend::parse(&source("ds_load_2addr_b32 v[2:3],v0 offset1:256")).is_err());
    for instruction in [
        "ds_load_2addr_b32 v1,v0 offset1:4",
        "ds_load_2addr_b32 v[2:3],v[0:1] offset1:4",
    ] {
        assert!(
            frontend::parse(&source(instruction)).is_err(),
            "{instruction}"
        );
    }
    for target in ["gfx942", "gfx950"] {
        let text = source("ds_load_2addr_b32 v[2:3],v0 offset1:4").replace("gfx1250", target);
        assert!(frontend::parse(&text).is_err());
    }
}
