//! HSA gfx1250 GLOBAL B32 uses byte addresses; other native profiles stay separate.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::AmdEventKind;
use volta_graph_check::GraphConclusion;

fn source(target: &str, body: &str) -> String {
    let (load, wait, wave32) = if target == "gfx1250" {
        ("s_load_b128", "s_wait_kmcnt 0", 1)
    } else {
        ("s_load_dwordx4", "s_waitcnt lgkmcnt(0)", 0)
    };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.p2align 8
.globl k
.type k,@function
k:
{load} s[4:7],s[0:1],0
{wait}
v_mov_b32 v0,0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 {wave32}
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
      - .name: input
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

fn run(target: &str, body: &str, bytes: u64) -> native_common::Checked {
    let source = source(target, body);
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "input".into(),
            base: 0x10000,
            elem_width: 1,
            len: bytes,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 1,
            len: bytes,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("input".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    native_common::check(&source, &module, Some("k"), config).unwrap()
}

#[test]
fn ordinary_global_b32_preserves_all_four_bytes_at_offsets_one_two_and_three() {
    for offset in 1..=3 {
        let checked = run(
            "gfx1250",
            &format!(
                "global_load_b32 v1,v0,s[4:5] offset:{offset}\ns_wait_loadcnt 0\nglobal_store_b32 v0,v1,s[6:7] offset:{offset}"
            ),
            8,
        );
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
        let out = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs[0].1.len(), 4);
        for (position, &(index, value)) in out.outputs[0].1.iter().enumerate() {
            assert_eq!(index, offset + position as u64);
            assert_eq!(out.arena.display_expr(value), format!("input[{index}]"));
        }
    }
}

#[test]
fn byte_alignment_keeps_complete_four_byte_bounds_and_no_partial_effects() {
    // Exactly the Half[3] boundary that genuine O2 code vectorizes: [2,6).
    let exact = run(
        "gfx1250",
        "global_load_b32 v1,v0,s[4:5] offset:2\ns_wait_loadcnt 0\nglobal_store_b32 v0,v1,s[6:7] offset:2",
        6,
    );
    assert_eq!(exact.checks.conclusion(), GraphConclusion::Verified);
    assert_eq!(
        exact.analysis.symbolic_outputs().unwrap().outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        vec![2, 3, 4, 5]
    );
    for body in [
        "global_load_b32 v1,v0,s[4:5] offset:3",
        "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\nglobal_store_b32 v0,v1,s[6:7] offset:3",
    ] {
        let checked = run("gfx1250", body, 6);
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("footprint crosses allocation boundaries"),
            "{error}"
        );
        let graph = checked.analysis.graph();
        let issue = graph
            .amd_events()
            .iter()
            .rev()
            .find(|event| matches!(event.kind, AmdEventKind::MemoryIssue { .. }))
            .unwrap();
        assert!(
            graph
                .amd_memory_effects()
                .iter()
                .all(|association| association.issue != issue.event),
            "a failing complete transfer cannot emit a valid prefix"
        );
    }
}

#[test]
fn wider_global_flat_ds_smem_and_legacy_alignment_profiles_are_not_relaxed() {
    for (body, diagnostic) in [
        ("global_load_b64 v[2:3],v0,s[4:5] offset:2", "misaligned"),
        (
            "flat_load_b32 v1,v0,s[4:5] offset:2 scope:SCOPE_SYS",
            "misaligned",
        ),
        ("ds_store_b32 v0,v0 offset:2", "misaligned"),
        ("s_load_b32 s8,s[4:5],2", "SMEM"),
    ] {
        let checked = run("gfx1250", body, 16);
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains(diagnostic), "{body}: {error}");
    }
    for target in ["gfx942", "gfx950"] {
        let checked = run(target, "global_load_dword v1,v0,s[4:5] offset:2", 16);
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("misaligned"), "{target}: {error}");
    }
}
