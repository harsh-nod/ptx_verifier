//! Eager64-bit multiplication does not establish KM/LOAD source readiness.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::AmdRegisterFile;
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

fn run(role: u32, wait_mode: u32, empty_exec: bool) -> gfx950_common::Checked {
    let (load, first, second, correct, wrong) = match role {
        0 => (
            "s_load_b64 s[36:37],s[0:1],8",
            "s[36:37]",
            "v[10:11]",
            "s_wait_kmcnt 0",
            "s_wait_loadcnt 0",
        ),
        1 => (
            "global_load_b64 v[6:7],v0,s[4:5] offset:8",
            "v[6:7]",
            "v[10:11]",
            "s_wait_loadcnt 0",
            "s_wait_kmcnt 0",
        ),
        _ => (
            "global_load_b64 v[10:11],v0,s[4:5] offset:8",
            "s[36:37]",
            "v[10:11]",
            "s_wait_loadcnt 0",
            "s_wait_kmcnt 0",
        ),
    };
    let wait = match wait_mode {
        0 => correct,
        1 => "",
        _ => wrong,
    };
    let disable = if empty_exec {
        "s_mov_b32 exec_lo,0"
    } else {
        ""
    };
    let text = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_wait_kmcnt 0
v_mov_b32 v0,0
v_mov_b32 v2,0x12345678
v_mov_b32 v3,0x9abcdef0
s_mov_b32 s36,1
s_mov_b32 s37,1
v_mov_b32 v10,1
v_mov_b32 v11,1
v_mov_b32 v14,1
v_mov_b32 v15,2
v_add_nc_u32 v14,0,v14
v_add_nc_u32 v15,0,v15
global_store_b32 v0,v14,s[4:5] offset:8
global_store_b32 v0,v15,s[4:5] offset:12
s_wait_storecnt 0
s_wait_xcnt 0
{load}
// Drain the memory instruction's EXEC/address lease before changing EXEC;
// XCNT alone does not establish LOAD destination readiness.
s_wait_xcnt 0
{wait}
{disable}
v_mul_u64_e32 v[2:3],{first},{second}
s_mov_b32 exec_lo,1
{correct}
v_add_nc_u32 v2,0,v2
v_add_nc_u32 v3,0,v3
global_store_b32 v0,v2,s[4:5]
global_store_b32 v0,v3,s[4:5] offset:4
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
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
      - .name: factor
        .offset: 8
        .size: 8
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
        len: 4,
        kind: ArrayKind::Output,
    });
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Bytes(vec![1, 0, 0, 0, 2, 0, 0, 0]),
    ];
    gfx950_common::check(&text, &module, Some("k"), config).unwrap()
}

#[test]
fn each_word_of_each_factor_needs_its_actual_load_counter_only_when_executed() {
    for role in 0..3 {
        for wait in 0..3 {
            for empty_exec in [false, true] {
                let checked = run(role, wait, empty_exec);
                let outputs = checked.analysis.symbolic_outputs().unwrap();
                let expected = if empty_exec {
                    [0x1234_5678u32, 0x9abc_def0, 1, 2]
                } else {
                    [1, 3, 1, 2]
                };
                assert_eq!(outputs.outputs[0].1.len(), 4);
                for (index, expected) in expected.into_iter().enumerate() {
                    assert_eq!(
                        outputs
                            .arena
                            .as_int_const(outputs.element("out", index as u64).unwrap()),
                        Some(i64::from(expected))
                    );
                }
                if wait == 0 || empty_exec {
                    assert_eq!(
                        checked.checks.conclusion(),
                        GraphConclusion::Verified,
                        "role{role}/wait{wait}/empty{empty_exec} {:?}",
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
                    let (file, indices) = match role {
                        0 => (AmdRegisterFile::Scalar, [36, 37]),
                        1 => (AmdRegisterFile::Vector, [6, 7]),
                        _ => (AmdRegisterFile::Vector, [10, 11]),
                    };
                    for index in indices {
                        assert!(hazards.iter().any(|hazard| hazard.kind
                            == AmdRegisterHazardKind::ReadBeforeReady
                            && hazard.register.file == file
                            && hazard.register.index == index));
                    }
                }
            }
        }
    }
}
