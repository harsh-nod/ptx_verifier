//! Bare CDNA4 no-return F32 atomic: values, VM completion and bounded refusal.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, analyze, frontend,
};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, Terminal};
use volta_graph_check::{
    GraphConclusion, Verdict,
    amdgpu::{AmdRegisterHazardKind, check_amdgpu},
    check_graph,
};

fn run(body: &str, base: u64) -> AnalysisResult {
    run_block(body, base, 64)
}
fn run_block(body: &str, base: u64, block: u32) -> AnalysisResult {
    let text = format!(
        ".amdgcn_target \"gfx950\"\n.text\n.globl k\nk:\n{body}\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    );
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::InputOutput,
    });
    analyze(&frontend::parse(&text).unwrap(), Some("k"), config).unwrap()
}
fn initialized(base: u64) -> String {
    format!(
        "s_mov_b32 s4,{}\ns_mov_b32 s5,{}\ns_mov_b64 exec,1\nv_mov_b32 v0,0\nv_mov_b32 v1,0x3fc00000\nv_add_f32 v1,v1,0\nglobal_store_dword v0,v1,s[4:5]\nv_mov_b32 v1,0x41100000\nv_add_f32 v1,v1,0\nglobal_store_dword v0,v1,s[4:5] offset:4\ns_waitcnt vmcnt(0)\nv_mov_b32 v2,0x40200000\n",
        base as u32,
        base >> 32
    )
}
fn values(result: &AnalysisResult, first: f64) {
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        check_amdgpu(result.graph())
    );
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 2);
    for (index, value) in [(0, first), (1, 9.)] {
        assert_eq!(
            outputs.arena.as_f64(outputs.element("out", index).unwrap()),
            Some(value)
        );
    }
}

#[test]
fn full_width_global_base_updates_one_word_and_endpgm_drains_the_vm_only_atomic() {
    for base in [0x100000, 0x1_00100000] {
        for completion in ["", "s_waitcnt vmcnt(0)\n"] {
            let result = run(
                &(initialized(base) + "global_atomic_add_f32 v0,v2,s[4:5]\n" + completion),
                base,
            );
            values(&result, 4.);
            let (destinations, held_sources, counters) = result
                .graph()
                .amd_events()
                .iter()
                .find_map(|event| match &event.kind {
                    AmdEventKind::MemoryIssue {
                        class: AmdMemoryClass::GlobalAtomicAddF32NoReturn,
                        destinations,
                        held_sources,
                        counters,
                    } => Some((destinations, held_sources, counters)),
                    _ => None,
                })
                .unwrap();
            assert!(destinations.is_empty());
            assert_eq!(held_sources.len(), 4);
            assert_eq!(counters, &[(AmdCounter::Vm, 1)]);
        }
    }
}

#[test]
fn vm_zero_is_required_before_any_address_data_or_scalar_source_overwrite() {
    for overwrite in [
        "v_mov_b32 v0,0",
        "v_mov_b32 v2,0",
        "s_mov_b32 s4,0",
        "s_mov_b32 s5,0",
    ] {
        for wait in [
            "",
            "s_waitcnt lgkmcnt(0)\n",
            "s_waitcnt vmcnt(63)\n",
            "s_waitcnt vmcnt(0)\n",
        ] {
            let result = run(
                &(initialized(0x100000)
                    + "global_atomic_add_f32 v0,v2,s[4:5]\n"
                    + wait
                    + overwrite),
                0x100000,
            );
            let checked = check_amdgpu(result.graph());
            assert_eq!(checked.trace.verdict(), Verdict::Pass);
            let hazard = checked
                .wait_readiness
                .violations()
                .iter()
                .any(|hazard| hazard.kind == AmdRegisterHazardKind::SourceReuse);
            assert_eq!(
                hazard,
                wait != "s_waitcnt vmcnt(0)\n",
                "{overwrite} after {wait:?}"
            );
        }
    }
}

#[test]
fn address_data_aliases_preserve_both_roles_and_unsigned_vgpr_offsets() {
    let base = 0x1_00100000;
    let scalar = base - 0x3f800000;
    let result = run(
        &(initialized(base)
            + &format!(
                "s_mov_b32 s4,{}\ns_mov_b32 s5,{}\nv_mov_b32 v0,0x3f800000\nglobal_atomic_add_f32 v0,v0,s[4:5]",
                scalar as u32,
                scalar >> 32
            )),
        base,
    );
    values(&result, 2.5);
    let result = run(
        &(initialized(base)
            + &format!(
                "s_mov_b32 s4,{}\ns_mov_b32 s5,{}\nv_mov_b32 v0,0xfffffffc\nglobal_atomic_add_f32 v0,v2,s[4:5]",
                (base - 0xfffffffc) as u32,
                (base - 0xfffffffc) >> 32
            )),
        base,
    );
    values(&result, 4.);
}

#[test]
fn empty_exec_has_no_atomic_effect_and_outside_profiles_never_publish_outputs() {
    let result = run(
        &(initialized(0x100000) + "s_mov_b64 exec,0\nglobal_atomic_add_f32 v8,v9,s[10:11]"),
        0x100000,
    );
    values(&result, 1.5);
    assert!(!result.graph().amd_events().iter().any(|event| matches!(
        event.kind,
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::GlobalAtomicAddF32NoReturn,
            ..
        }
    )));
    for body in [
        "s_mov_b64 exec,3\nglobal_atomic_add_f32 v0,v2,s[4:5]",
        "global_atomic_add_f32 v0,v2,s[4:5] sc0",
        "s_mov_b64 exec,0\nglobal_atomic_add_f32 v0,v2,s[4:5] sc1",
        "v_mov_b32 v0,2\nglobal_atomic_add_f32 v0,v2,s[4:5]",
        "v_mov_b32 v0,8\nglobal_atomic_add_f32 v0,v2,s[4:5]",
    ] {
        let result = run(&(initialized(0x100000) + body), 0x100000);
        assert!(
            matches!(result.graph().terminal(), Terminal::Aborted { .. }),
            "{body}"
        );
        assert!(result.symbolic_outputs().is_err());
        assert!(!matches!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        ));
        assert!(!result.graph().amd_events().iter().any(|event| matches!(
            event.kind,
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::GlobalAtomicAddF32NoReturn,
                ..
            }
        )));
    }
}

#[test]
fn later_memory_observation_requires_actual_vm_completion_of_the_atomic() {
    for wait in ["", "s_waitcnt lgkmcnt(0)\n", "s_waitcnt vmcnt(0)\n"] {
        let result = run(
            &(initialized(0x100000)
                + "global_atomic_add_f32 v0,v2,s[4:5]\n"
                + wait
                + "global_load_dword v3,v0,s[4:5]\ns_waitcnt vmcnt(0)"),
            0x100000,
        );
        let checked = check_amdgpu(result.graph());
        assert_eq!(checked.trace.verdict(), Verdict::Pass);
        assert_eq!(
            checked.memory_conflict.verdict(),
            if wait == "s_waitcnt vmcnt(0)\n" {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}

#[test]
fn mixed_vm_classes_and_partial_waits_do_not_release_atomic_sources() {
    for wait in [
        "s_waitcnt vmcnt(1)",
        "s_waitcnt vmcnt(63)",
        "s_waitcnt lgkmcnt(0)",
        "s_waitcnt vmcnt(0)",
    ] {
        let body = initialized(0x100000)
            + "global_atomic_add_f32 v0,v2,s[4:5]\nglobal_load_dword v3,v0,s[4:5] offset:4\n"
            + wait
            + "\nv_mov_b32 v2,0\ns_waitcnt vmcnt(0)";
        let result = run(&body, 0x100000);
        let checked = check_amdgpu(result.graph());
        assert_eq!(checked.trace.verdict(), Verdict::Pass);
        assert_eq!(
            checked
                .wait_readiness
                .violations()
                .iter()
                .any(|h| h.kind == AmdRegisterHazardKind::SourceReuse),
            wait != "s_waitcnt vmcnt(0)"
        );
    }
}

#[test]
fn valu_produced_atomic_scalar_addresses_require_five_independent_states() {
    for states in 0..=5 {
        let wait = if states == 0 {
            String::new()
        } else {
            format!("s_nop {}\n", states - 1)
        };
        let body = initialized(0x100000)
            + "v_mov_b32 v1,0x100000\ns_nop 0\nv_readlane_b32 s4,v1,0\n"
            + &wait
            + "global_atomic_add_f32 v0,v2,s[4:5]";
        let result = run(&body, 0x100000);
        let checked = check_amdgpu(result.graph());
        assert_eq!(checked.trace.verdict(), Verdict::Pass);
        assert_eq!(
            checked.wait_readiness.violations().iter().any(|h| h.kind
                == AmdRegisterHazardKind::ValuScalarReadBeforeReady
                && h.register.index == 4),
            states < 5
        );
    }
}

#[test]
fn concurrent_two_wave_atomic_serialization_remains_unknown() {
    let result = run_block(
        "s_mov_b32 s4,0x100000\ns_mov_b32 s5,0\ns_mov_b64 exec,1\nv_mov_b32 v0,0\nv_mov_b32 v2,0x3f800000\nglobal_atomic_add_f32 v0,v2,s[4:5]",
        0x100000,
        128,
    );
    assert_eq!(result.graph().terminal(), &Terminal::Completed);
    let checked = check_amdgpu(result.graph());
    assert_eq!(checked.trace.verdict(), Verdict::Pass);
    assert_eq!(checked.memory_conflict.verdict(), Verdict::Unknown);
    assert!(!matches!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    ));
}
