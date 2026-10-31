//! SOP2 data/control readiness remains distinct from eager bitfield evaluation.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::AmdRegisterFile;
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

fn run(
    target: &str,
    control_load: bool,
    wait_mode: u32,
    empty_exec: bool,
) -> gfx950_common::Checked {
    let (load, prepare, control) = if control_load {
        (
            "s_load_dword s10,s[0:1],16",
            "s_mov_b32 s12,0x80000000\ns_mov_b32 s13,-1",
            "s10",
        )
    } else {
        ("s_load_dwordx2 s[12:13],s[0:1],8", "", "0x200000")
    };
    let (wait, finish) = match (target, wait_mode) {
        ("gfx1250", 0) => ("s_wait_kmcnt 0", "s_wait_storecnt 0\ns_wait_xcnt 0"),
        ("gfx1250", 1) => ("", "s_wait_storecnt 0\ns_wait_xcnt 0"),
        ("gfx1250", _) => ("s_wait_xcnt 0", "s_wait_storecnt 0\ns_wait_xcnt 0"),
        (_, 0) => ("s_waitcnt lgkmcnt(0)", "s_waitcnt vmcnt(0)"),
        (_, 1) => ("", "s_waitcnt vmcnt(0)"),
        (_, _) => ("s_waitcnt vmcnt(0)", "s_waitcnt vmcnt(0)"),
    };
    let disable = if empty_exec {
        "s_mov_b32 exec_lo,0"
    } else {
        ""
    };
    let mut text = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
s_load_dwordx2 s[4:5],s[0:1],0
s_waitcnt lgkmcnt(0)
{disable}
{prepare}
{load}
{wait}
s_bfe_i64 s[8:9],s[12:13],{control}
s_cselect_b32 s16,1,0
s_mov_b32 exec_lo,1
v_mov_b32 v0,0
v_mov_b32 v2,s8
v_mov_b32 v3,s9
v_mov_b32 v14,s16
v_add_u32 v2,0,v2
v_add_u32 v3,0,v3
v_add_u32 v14,0,v14
global_store_dword v0,v2,s[4:5]
global_store_dword v0,v3,s[4:5] offset:4
global_store_dword v0,v14,s[4:5] offset:8
{finish}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 24
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
      - .name: data
        .offset: 8
        .size: 8
        .value_kind: by_value
      - .name: control
        .offset: 16
        .size: 4
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    );
    if target == "gfx1250" {
        text = text
            .replace("s_load_dwordx2", "s_load_b64")
            .replace("s_load_dword", "s_load_b32")
            .replace("s_waitcnt lgkmcnt(0)", "s_wait_kmcnt 0")
            .replace("global_store_dword", "global_store_b32")
            .replace("v_add_u32", "v_add_nc_u32")
            .replace(
                ".amdhsa_kernel k",
                ".amdhsa_kernel k\n.amdhsa_wavefront_size32 1",
            );
    }
    let module = frontend::parse(&text).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: 3,
        kind: ArrayKind::Output,
    });
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Bytes(vec![0, 0, 0, 128, 255, 255, 255, 255]),
        ParamValue::Int(0x200000),
    ];
    gfx950_common::check(&text, &module, Some("k"), config).unwrap()
}

#[test]
fn data_and_control_use_target_specific_counters_even_under_empty_exec() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for control in [false, true] {
            for empty_exec in [false, true] {
                for wait in 0..3 {
                    let checked = run(target, control, wait, empty_exec);
                    let outputs = checked.analysis.symbolic_outputs().unwrap();
                    assert_eq!(outputs.outputs[0].1.len(), 3);
                    for (index, expected) in [0x8000_0000u32, u32::MAX, 1].into_iter().enumerate() {
                        assert_eq!(
                            outputs
                                .arena
                                .as_int_const(outputs.element("out", index as u64).unwrap()),
                            Some(i64::from(expected))
                        );
                    }
                    if wait == 0 {
                        assert_eq!(
                            checked.checks.conclusion(),
                            GraphConclusion::Verified,
                            "{target} {:?}",
                            checked.checks.amd
                        );
                    } else {
                        assert!(
                            matches!(
                                checked.checks.conclusion(),
                                GraphConclusion::Rejected { .. }
                            ),
                            "{target}"
                        );
                        let PropertyResult::Fail(hazards) =
                            &checked.checks.amd.as_ref().unwrap().wait_readiness
                        else {
                            panic!("readiness failure")
                        };
                        for register in if control { &[10][..] } else { &[12, 13][..] } {
                            assert!(hazards.iter().any(|hazard| hazard.kind
                                == AmdRegisterHazardKind::ReadBeforeReady
                                && hazard.register.file == AmdRegisterFile::Scalar
                                && hazard.register.index == *register));
                        }
                    }
                }
            }
        }
    }
}
