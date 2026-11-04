//! Signed MAD computes eagerly; each native source still needs LGKM readiness.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::AmdRegisterFile;
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

fn run(load: &str, mad: &str, params: &[i64], wait: bool) -> gfx950_common::Checked {
    let wait = if wait { "s_waitcnt lgkmcnt(0)" } else { "" };
    let text = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.type k,@function
k:
s_load_dwordx2 s[4:5],s[0:1],0
s_waitcnt lgkmcnt(0)
{load}
{wait}
v_mov_b32 v6,-2
v_mov_b32 v7,3
v_mov_b64 v[14:15],5
{mad}
v_mov_b32 v12,0
v_cndmask_b32_e64 v16,0,1,s[8:9]
v_add_u32 v2,0,v2
v_add_u32 v3,0,v3
v_add_u32 v16,0,v16
global_store_dword v12,v2,s[4:5]
global_store_dword v12,v3,s[4:5] offset:4
global_store_dword v12,v16,s[4:5] offset:8
s_waitcnt vmcnt(0)
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 16
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
      - .name: a
        .offset: 8
        .size: 4
        .value_kind: by_value
      - .name: b
        .offset: 12
        .size: 4
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    );
    let module = frontend::parse(&text).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: 3,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
        .params
        .extend(params.iter().copied().map(ParamValue::Int));
    gfx950_common::check(&text, &module, Some("k"), config).unwrap()
}

#[test]
fn both_factors_and_both_addend_words_need_independent_readiness() {
    for (load, mad, params, required) in [
        (
            "s_load_dword s10,s[0:1],8",
            "v_mad_i64_i32 v[2:3],s[8:9],s10,v7,v[14:15]",
            [-2, 0],
            vec![10],
        ),
        (
            "s_load_dword s10,s[0:1],8",
            "v_mad_i64_i32 v[2:3],s[8:9],v7,s10,v[14:15]",
            [-2, 0],
            vec![10],
        ),
        (
            "s_load_dwordx2 s[12:13],s[0:1],8",
            "v_mad_i64_i32 v[2:3],s[8:9],v6,v7,s[12:13]",
            [5, 0],
            vec![12, 13],
        ),
    ] {
        for wait in [true, false] {
            let checked = run(load, mad, &params, wait);
            let outputs = checked.analysis.symbolic_outputs().unwrap();
            assert_eq!(outputs.outputs[0].1.len(), 3);
            for (index, expected) in [u32::MAX, u32::MAX, 1].into_iter().enumerate() {
                assert_eq!(
                    outputs
                        .arena
                        .as_int_const(outputs.element("out", index as u64).unwrap()),
                    Some(i64::from(expected))
                );
            }
            if wait {
                assert_eq!(
                    checked.checks.conclusion(),
                    GraphConclusion::Verified,
                    "{:?}",
                    checked.checks.amd
                );
            } else {
                assert!(matches!(
                    checked.checks.conclusion(),
                    GraphConclusion::Rejected { .. }
                ));
                let PropertyResult::Fail(hazards) =
                    &checked.checks.amd.as_ref().unwrap().wait_readiness
                else {
                    panic!("readiness failure")
                };
                for index in &required {
                    assert!(hazards.iter().any(|hazard| hazard.kind
                        == AmdRegisterHazardKind::ReadBeforeReady
                        && hazard.register.file == AmdRegisterFile::Scalar
                        && hazard.register.index == *index));
                }
            }
        }
    }
}
