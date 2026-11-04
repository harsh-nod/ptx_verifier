//! Certified rejection never turns an incomplete prefix into acceptance evidence.
use std::ops::ControlFlow;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::{AbortCause, Terminal};
use volta_graph_check::amdgpu::early_memory_conflicts::validate_memory_conflict_prefix;
use volta_graph_check::domain::ConflictKind;
use volta_graph_check::{GraphConclusion, check_graph};
use volta_pipeline::{KernelModule, SourceKernelVerification, verify_source_kernel};

fn source(target: &str, body: &str) -> String {
    let (load, wait, tail, wave) = if target == "gfx1250" {
        (
            "s_load_b64",
            "s_wait_kmcnt 0",
            "s_wait_storecnt 0\ns_wait_xcnt 0\ns_wait_dscnt 0",
            ".amdhsa_wavefront_size32 1",
        )
    } else {
        (
            "s_load_dwordx2",
            "s_waitcnt lgkmcnt(0)",
            "s_waitcnt vmcnt(0) lgkmcnt(0)",
            "",
        )
    };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
{load} s[4:5],s[0:1],0
{wait}
v_add_f32 v1,1.0,0.0
{body}
{tail}
s_endpgm
.size k,.-k
.amdhsa_kernel k
{wave}
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_group_segment_fixed_size 512
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
fn config(early: bool, block: u32) -> AnalysisConfig {
    let mut c = AnalysisConfig::new((block, 1, 1));
    c.early_memory_conflicts = early;
    c.arrays.push(ArrayDef {
        name: "out".into(),
        base: 131072,
        elem_width: 4,
        len: u64::from(block),
        kind: ArrayKind::Output,
    });
    c.params.push(ParamValue::ArrayPtr("out".into()));
    c
}
fn store(target: &str) -> &'static str {
    if target == "gfx1250" {
        "global_store_b32 v2,v1,s[4:5]"
    } else {
        "global_store_dword v2,v1,s[4:5]"
    }
}
fn run(target: &str, body: &str, c: AnalysisConfig) -> SourceKernelVerification {
    let module = KernelModule::Amdgpu(frontend::parse(&source(target, body)).unwrap());
    verify_source_kernel(&module, Some("k"), c).unwrap()
}

#[test]
fn global_and_direct_lds_certificates_replay_exact_final_prefix_without_outputs() {
    for target in ["gfx950", "gfx1250"] {
        for op in [store(target), "ds_write_b32 v2,v1"] {
            let result = run(target, &format!("v_mov_b32 v2,0\n{op}"), config(true, 2));
            let finding = result
                .early_memory_conflict
                .as_ref()
                .expect("same-issued distinct-lane writes");
            assert_eq!(finding.conflict().kind, ConflictKind::WriteWrite);
            assert_eq!(
                validate_memory_conflict_prefix(&result.analysis.graph, finding.certificate())
                    .unwrap(),
                *finding.conflict()
            );
            assert!(result.analysis.outputs.is_err());
            assert!(
                matches!(result.analysis.graph.terminal(), Terminal::Aborted { cause: AbortCause::Error, reason, .. } if reason == volta_amdgpu_analysis::OBSERVER_STOP_REASON)
            );
            assert!(matches!(
                result.graph.conclusion(),
                GraphConclusion::Unknown { .. }
            ));
            assert_eq!(
                finding.certificate().amd_records,
                result.analysis.graph.amd_events().len()
            );
            assert_ne!(
                finding.certificate().earlier_thread,
                finding.certificate().later_thread
            );
        }
    }
}

#[test]
fn supported_raw_buffer_writes_qualify_but_bad_or_undefined_descriptors_never_issue() {
    use volta_graph::{AmdEventKind, AmdMemoryClass};
    for target in ["gfx950", "gfx1250"] {
        let (descriptor, store, invalid_flags, class) = if target == "gfx1250" {
            // CDNA5: raw base 0x20000, 16 byte resource, zero flags.
            (
                "s_mov_b32 s8,0x20000\ns_mov_b32 s9,0x20000000\ns_mov_b32 s10,0\ns_mov_b32 s11,0",
                "v_add_f32 v2,1.0,0.0\nv_add_f32 v3,2.0,0.0\nv_mov_b32 v4,0\nbuffer_store_b64 v[2:3],v4,s[8:11],null offen",
                "s_mov_b32 s11,0x10000000",
                AmdMemoryClass::VectorStore,
            )
        } else {
            // CDNA4: raw base 0x20000, 8 byte resource, selected DWORD flags.
            (
                "s_mov_b32 s8,0x20000\ns_mov_b32 s9,0\ns_mov_b32 s10,8\ns_mov_b32 s11,0x20000",
                "v_mov_b32 v2,0\nbuffer_store_dword v1,v2,s[8:11],0 offen",
                "s_mov_b32 s11,0x20001",
                AmdMemoryClass::VectorMemory,
            )
        };
        let body = format!("{descriptor}\n{store}");
        let result = run(target, &body, config(true, 2));
        let finding = result
            .early_memory_conflict
            .as_ref()
            .expect("ordinary raw-buffer GLOBAL write");
        assert_eq!(finding.conflict().location.addr, 131072);
        assert!(
            validate_memory_conflict_prefix(&result.analysis.graph, finding.certificate()).is_ok()
        );
        assert!(result.analysis.outputs.is_err());
        for rejected in [
            format!("{descriptor}\n{invalid_flags}\n{store}"),
            format!(
                "{}\n{store}",
                descriptor
                    .lines()
                    .filter(|line| !line.starts_with("s_mov_b32 s10,"))
                    .collect::<Vec<_>>()
                    .join("\n")
            ),
        ] {
            let result = run(target, &rejected, config(true, 2));
            assert!(result.early_memory_conflict.is_none() && result.analysis.outputs.is_err());
            assert!(!result.analysis.graph.amd_events().iter().any(|record| matches!(record.kind, AmdEventKind::MemoryIssue { class: actual, .. } if actual == class)), "invalid/opaque descriptor aborted before issue");
        }
    }
}

#[test]
fn default_retains_multiple_conflicts_and_safe_enabled_artifacts_are_identical() {
    assert!(!AnalysisConfig::new((2, 1, 1)).early_memory_conflicts);
    for target in ["gfx950", "gfx1250"] {
        let bad = format!("v_mov_b32 v2,0\n{}\n{}", store(target), store(target));
        let ordinary = run(target, &bad, config(false, 2));
        assert!(ordinary.early_memory_conflict.is_none());
        assert_eq!(ordinary.analysis.graph.terminal(), &Terminal::Completed);
        let full = volta_graph_check::amdgpu::check_amdgpu(&ordinary.analysis.graph);
        assert!(full.memory_conflict.violations().len() >= 2);
        let early = run(target, &bad, config(true, 2));
        assert!(early.early_memory_conflict.is_some());
        assert!(early.analysis.stats.instructions < ordinary.analysis.stats.instructions);
        let safe = format!("v_lshlrev_b32 v2,2,v0\n{}", store(target));
        let ordinary = run(target, &safe, config(false, 2));
        let enabled = run(target, &safe, config(true, 2));
        assert!(enabled.early_memory_conflict.is_none());
        assert_eq!(enabled.graph.conclusion(), GraphConclusion::Verified);
        assert_eq!(
            ordinary.analysis.graph.dump(),
            enabled.analysis.graph.dump()
        );
        let mut ordinary_text = Vec::new();
        let mut enabled_text = Vec::new();
        volta_expr::text::write_text(&mut ordinary_text, &ordinary.analysis.outputs.unwrap())
            .unwrap();
        volta_expr::text::write_text(&mut enabled_text, &enabled.analysis.outputs.unwrap())
            .unwrap();
        assert_eq!(ordinary_text, enabled_text);
    }
}

#[test]
fn inactive_lanes_and_unstarted_waves_do_not_invent_conflicts_or_completion() {
    for target in ["gfx950", "gfx1250"] {
        let exec = if target == "gfx1250" {
            "s_mov_b32 exec_lo,1"
        } else {
            "s_mov_b64 exec,1"
        };
        let result = run(
            target,
            &format!("v_mov_b32 v2,0\n{exec}\n{}", store(target)),
            config(true, 2),
        );
        assert!(result.early_memory_conflict.is_none());
        assert_eq!(result.graph.conclusion(), GraphConclusion::Verified);
        let result = run(
            target,
            &format!("v_mov_b32 v2,0\n{}", store(target)),
            config(true, 128),
        );
        assert!(result.early_memory_conflict.is_some());
        assert!(result.analysis.outputs.is_err());
        assert!(matches!(
            result.graph.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
}

#[test]
fn arbitrary_callback_after_real_collision_is_unknown_without_private_certificate() {
    for target in ["gfx950", "gfx1250"] {
        let text = source(target, &format!("v_mov_b32 v2,0\n{}", store(target)));
        let module = frontend::parse(&text).unwrap();
        let mut hook = |graph: &volta_graph::EventGraph| {
            if graph
                .accesses()
                .values()
                .filter(|access| access.mode == volta_graph::AccessMode::Write)
                .count()
                >= 2
            {
                ControlFlow::Break(())
            } else {
                ControlFlow::Continue(())
            }
        };
        let result = volta_amdgpu_analysis::analyze_with_observer(
            &module,
            Some("k"),
            config(true, 2),
            &mut hook,
        )
        .unwrap();
        assert!(result.symbolic_outputs().is_err());
        assert!(matches!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Unknown { .. }
        ));
        assert!(
            !volta_graph_check::amdgpu::check_amdgpu(result.graph())
                .memory_conflict
                .violations()
                .is_empty()
        );
    }
}

#[test]
fn refusals_budget_and_unready_values_cannot_authorize_a_memory_certificate() {
    for target in ["gfx950", "gfx1250"] {
        let bad = format!("v_mov_b32 v2,0\n{}", store(target));
        let mut limited = config(true, 2);
        limited.max_instructions = 2;
        let result = run(target, &bad, limited);
        assert!(result.early_memory_conflict.is_none() && result.analysis.outputs.is_err());
        let unknown = run(
            target,
            &format!(
                "{} v3,v20,s[4:5]\n{bad}",
                if target == "gfx1250" {
                    "global_load_b32"
                } else {
                    "global_load_dword"
                }
            ),
            config(true, 2),
        );
        assert!(unknown.early_memory_conflict.is_none() && unknown.analysis.outputs.is_err());
        let text = source(target, &bad).replace(
            if target == "gfx1250" {
                "s_wait_kmcnt 0\n"
            } else {
                "s_waitcnt lgkmcnt(0)\n"
            },
            "s_nop 0\n",
        );
        let module = KernelModule::Amdgpu(frontend::parse(&text).unwrap());
        let result = verify_source_kernel(&module, Some("k"), config(true, 2)).unwrap();
        assert!(
            result.early_memory_conflict.is_none(),
            "unknown/unready address premise"
        );
    }
}

#[test]
fn composed_modes_prioritize_km_and_independently_continue_when_inapplicable() {
    let target = "gfx1250";
    let mut c = config(true, 2);
    c.early_readiness = true;
    // The unsafe scalar source use is before any write issue.
    let bad = format!(
        "s_load_b32 s6,s[4:5],0\ns_mov_b32 s7,s6\nv_mov_b32 v2,0\n{}",
        store(target)
    );
    // Treat the one output cell as input/output to permit the scalar read.
    c.arrays[0].kind = ArrayKind::InputOutput;
    let result = run(target, &bad, c.clone());
    assert!(result.early_readiness.is_some() && result.early_memory_conflict.is_none());
    let result = run(target, &format!("v_mov_b32 v2,0\n{}", store(target)), c);
    assert!(result.early_readiness.is_none() && result.early_memory_conflict.is_some());
}

#[test]
fn unsupported_target_and_direct_native_api_cannot_ignore_opt_in() {
    let module = frontend::parse(&source("gfx950", "")).unwrap();
    assert!(volta_amdgpu_analysis::analyze(&module, Some("k"), config(true, 2)).is_err());
    let mut hook = |_: &volta_graph::EventGraph| ControlFlow::Continue(());
    assert!(
        volta_amdgpu_analysis::analyze_with_observer(
            &module,
            Some("k"),
            config(false, 2),
            &mut hook
        )
        .is_err()
    );
    let legacy = source("gfx950", "").replace("gfx950", "gfx942");
    let module = KernelModule::Amdgpu(frontend::parse(&legacy).unwrap());
    assert!(
        verify_source_kernel(&module, Some("k"), config(true, 2))
            .err()
            .unwrap()
            .contains("early_memory_conflicts")
    );
}
