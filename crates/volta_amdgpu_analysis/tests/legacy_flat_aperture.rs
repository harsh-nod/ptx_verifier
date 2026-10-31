//! Exact legacy aperture transport preserves complete LDS values and dependencies.
#[path = "support/legacy_flat.rs"]
mod fixture;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayKind, SharedAllocation, analyze, frontend};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile, EventKind, Space};
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const LEGACY: [&str; 2] = ["gfx942", "gfx950"];

fn run(target: &str, body: &str, config: AnalysisConfig) -> volta_amdgpu_analysis::AnalysisResult {
    let module = frontend::parse(&fixture::source(target, body)).unwrap();
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn exact_outputs(result: &volta_amdgpu_analysis::AnalysisResult, block: u32) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    assert_eq!(outputs.outputs[0].1.len(), block as usize);
    for index in 0..u64::from(block) {
        let expression = outputs.element("out", index).unwrap();
        assert_eq!(
            outputs.arena.display_expr(expression),
            format!("x[{index}]")
        );
    }
}

fn refused(target: &str, body: &str, config: AnalysisConfig, expected: &str) {
    let result = run(target, body, config);
    let error = result.symbolic_outputs().unwrap_err().to_string();
    assert!(error.contains(expected), "{target}: {error}");
    assert!(matches!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

#[test]
fn complete_lds_identity_keeps_all_outputs_and_flat_dual_counter_effects() {
    for target in LEGACY {
        for block in [1, 32, 64] {
            for alias in [false, true] {
                let result = run(target, &fixture::copy(alias), fixture::config(block));
                exact_outputs(&result, block);
                assert_eq!(
                    check_graph(result.graph()).conclusion(),
                    GraphConclusion::Verified,
                    "{target}: {:?}",
                    check_graph(result.graph())
                );
                let issues: Vec<_> = result
                    .graph()
                    .amd_events()
                    .iter()
                    .filter_map(|event| {
                        if let AmdEventKind::MemoryIssue {
                            class, counters, ..
                        } = &event.kind
                            && *class == AmdMemoryClass::Flat
                        {
                            Some((event.event, counters))
                        } else {
                            None
                        }
                    })
                    .collect();
                assert_eq!(issues.len(), 1);
                assert_eq!(issues[0].1, &[(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)]);
                let effects: Vec<_> = result
                    .graph()
                    .amd_memory_effects()
                    .iter()
                    .filter(|effect| effect.issue == issues[0].0)
                    .collect();
                assert_eq!(effects.len(), block as usize);
                for effect in effects {
                    let EventKind::Access(access) = result.graph().event(effect.effect).kind else {
                        panic!("ordinary FLAT effect must be a memory access");
                    };
                    assert_eq!(result.graph().access(access).space, Space::Shared);
                }
            }
        }
    }
}

#[test]
fn both_legacy_flat_waits_are_required_and_either_full_wait_order_works() {
    for target in LEGACY {
        for wait in [
            "",
            "s_waitcnt vmcnt(0)",
            "s_waitcnt lgkmcnt(0)",
            "s_waitcnt vmcnt(0) lgkmcnt(0)",
            "s_waitcnt vmcnt(0)\ns_waitcnt lgkmcnt(0)",
            "s_waitcnt lgkmcnt(0)\ns_waitcnt vmcnt(0)",
        ] {
            let body = fixture::copy(false).replacen(
                "s_waitcnt vmcnt(0) lgkmcnt(0)\nv_add_f32 v5",
                &format!("{wait}\nv_add_f32 v5"),
                1,
            );
            let result = run(target, &body, fixture::config(1));
            exact_outputs(&result, 1);
            let checks = check_graph(result.graph());
            assert_eq!(checks.verdict(Property::AmdTrace), Verdict::Pass);
            let completed = wait.contains("vmcnt") && wait.contains("lgkmcnt");
            assert_eq!(
                checks.verdict(Property::AmdWaitReadiness),
                if completed {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                },
                "{target}: {wait}\n{checks:#?}"
            );
            if completed {
                assert_eq!(checks.conclusion(), GraphConclusion::Verified);
            } else {
                assert!(
                    checks
                        .amd
                        .as_ref()
                        .unwrap()
                        .wait_readiness
                        .violations()
                        .iter()
                        .any(|hazard| hazard.register.file == AmdRegisterFile::Vector
                            && hazard.register.index == 5)
                );
                assert!(matches!(
                    checks.conclusion(),
                    GraphConclusion::Rejected { .. }
                ));
            }
        }
    }
}

#[test]
fn known_zero_address_words_still_need_their_own_load_completion() {
    for target in LEGACY {
        for (load, register, index, correct_wait, wrong_wait) in [
            (
                "s_load_dword s8,s[0:1],16",
                AmdRegisterFile::Scalar,
                8,
                "s_waitcnt lgkmcnt(0)",
                "s_waitcnt vmcnt(0)",
            ),
            (
                "global_load_dword v0,v7,s[4:5]",
                AmdRegisterFile::Vector,
                0,
                "s_waitcnt vmcnt(0)",
                "s_waitcnt lgkmcnt(0)",
            ),
            (
                "global_load_dword v1,v7,s[4:5]",
                AmdRegisterFile::Vector,
                1,
                "s_waitcnt vmcnt(0)",
                "s_waitcnt lgkmcnt(0)",
            ),
        ] {
            for wait in ["", wrong_wait, correct_wait] {
                let body = fixture::copy(false)
                    .replace("offset:8", "")
                    .replace("s_mov_b32 s8,8", "s_mov_b32 s8,0")
                    .replace(
                        "v_lshl_add_u64 v[2:3]",
                        &format!("v_mov_b32 v7,0\n{load}\n{wait}\nv_lshl_add_u64 v[2:3]"),
                    );
                let mut config = fixture::config(1);
                // The first concrete IndexInput element is zero, so these
                // pending words change no address semantics or tag identity.
                config.arrays[0].kind = ArrayKind::IndexInput;
                let result = run(target, &body, config);
                result.symbolic_outputs().unwrap();
                let checks = check_graph(result.graph());
                assert_eq!(checks.verdict(Property::AmdTrace), Verdict::Pass);
                if wait == correct_wait {
                    assert_eq!(
                        checks.conclusion(),
                        GraphConclusion::Verified,
                        "{checks:#?}"
                    );
                } else {
                    assert_eq!(checks.verdict(Property::AmdWaitReadiness), Verdict::Fail);
                    assert!(
                        checks
                            .amd
                            .as_ref()
                            .unwrap()
                            .wait_readiness
                            .violations()
                            .iter()
                            .any(|hazard| hazard.register.file == register
                                && hazard.register.index == index)
                    );
                }
            }
        }
    }
}

#[test]
fn aperture_transport_cannot_supply_numeric_bits_initialization_or_lds_bounds() {
    for target in LEGACY {
        let body = fixture::copy(false);
        for (body, expected) in [
            (
                body.replace("s_mov_b32 s8,8", "s_mov_b32 s8,7"),
                "misaligned",
            ),
            (
                body.replace("s_mov_b32 s8,8", "s_mov_b32 s8,12"),
                "out-of-bounds",
            ),
            (
                body.replace("ds_write_b32 v0,v4 offset:8", ""),
                "uninitialized",
            ),
            (
                body.replace("flat_load_dword v5,v[2:3]", "v_add_u32 v5,0,v3"),
                "opaque shared aperture",
            ),
        ] {
            refused(target, &body, fixture::config(1), expected);
        }
        let mut config = fixture::config(1);
        config.dynamic_shared_bytes = 16;
        config.shared_allocations = vec![
            SharedAllocation {
                name: "a".into(),
                offset: 8,
                size: 4,
            },
            SharedAllocation {
                name: "b".into(),
                offset: 12,
                size: 4,
            },
        ];
        refused(
            target,
            &body.replace("flat_load_dword v5", "flat_load_dwordx2 v[12:13]"),
            config,
            "footprint crosses configured allocation boundaries",
        );
    }
}

#[test]
fn a_fully_numeric_global_pair_is_not_reclassified_as_shared() {
    for target in LEGACY {
        let body = fixture::copy(false).replace(
            "s_mov_b64 s[8:9],src_shared_base\ns_mov_b32 s8,8",
            "s_mov_b64 s[8:9],0x10000",
        );
        let result = run(target, &body, fixture::config(1));
        exact_outputs(&result, 1);
        assert_eq!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        );
        let flat = result
            .graph()
            .amd_events()
            .iter()
            .find(|event| {
                matches!(
                    event.kind,
                    AmdEventKind::MemoryIssue {
                        class: AmdMemoryClass::Flat,
                        ..
                    }
                )
            })
            .unwrap()
            .event;
        assert!(result.graph().amd_memory_effects().iter().any(|effect| {
            effect.issue == flat
                && matches!(result.graph().event(effect.effect).kind, EventKind::Access(access)
                    if result.graph().access(access).space == Space::Global)
        }));
    }
}
