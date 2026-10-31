//! Independent VM completion, M0 spacing and full-output math for CDNA4 DMA.
#[path = "../../volta_amdgpu_analysis/tests/support/buffer_lds.rs"]
mod fixture;
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayKind};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, Property, Verdict};

fn run(body: &str, config: AnalysisConfig) -> gfx950_common::Checked {
    gfx950_common::check(
        &fixture::source(body),
        &fixture::module(body),
        Some("k"),
        config,
    )
    .unwrap()
}

fn math(checked: &gfx950_common::Checked, len: u64, wrong: bool) -> EquivOutcome {
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let one = arena.int(1);
    let outputs = (0..len)
        .map(|i| {
            let value = arena.input_element(x, i);
            (i, if wrong { arena.add(value, one) } else { value })
        })
        .collect();
    let reference = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), outputs)],
    };
    check_output_equivalence(
        checked.analysis.symbolic_outputs().unwrap(),
        &reference,
        &["out".into()],
    )
    .unwrap()
}

fn hazard(checked: &gfx950_common::Checked, file: AmdRegisterFile, index: u16) {
    assert_eq!(
        checked.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Fail,
        "{:?}",
        checked.checks
    );
    assert!(
        checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .wait_readiness
            .violations()
            .iter()
            .any(|h| h.register.file == file && h.register.index == index)
    );
}

#[test]
fn completed_dma_preserves_all_outputs_and_refutes_a_different_equation() {
    for bytes in [4, 16] {
        for block in [1, 32, 64] {
            let len = u64::from(block) * bytes / 4;
            let checked = run(
                &fixture::copy(bytes, 4, (len * 4) as u32),
                fixture::config(block, len, 2048),
            );
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
            assert!(matches!(
                math(&checked, len, false),
                EquivOutcome::Equivalent
            ));
            assert!(
                matches!(math(&checked, len, true), EquivOutcome::NotEquivalent { mismatches } if !mismatches.is_empty())
            );
            let issues: Vec<_> = checked
                .analysis
                .graph()
                .amd_events()
                .iter()
                .filter(|event| {
                    matches!(
                        event.kind,
                        AmdEventKind::MemoryIssue {
                            class: AmdMemoryClass::BufferLoadToLds32
                                | AmdMemoryClass::BufferLoadToLds128,
                            ..
                        }
                    )
                })
                .collect();
            assert_eq!(issues.len(), 1);
            let AmdEventKind::MemoryIssue {
                counters,
                destinations,
                held_sources,
                ..
            } = &issues[0].kind
            else {
                unreachable!()
            };
            assert_eq!(counters, &[(AmdCounter::Vm, 1)]);
            assert!(destinations.is_empty() && held_sources.is_empty());
        }
    }
}

#[test]
fn missing_or_unrelated_completion_does_not_publish_dma_to_ds() {
    for bytes in [4, 16] {
        for wait in [
            "",
            "s_waitcnt lgkmcnt(0)",
            "s_waitcnt expcnt(0)",
            "s_waitcnt vmcnt(1)",
        ] {
            let body = fixture::copy(bytes, 0, 128).replacen(
                "s_waitcnt vmcnt(0)\nds_read",
                &format!("{wait}\nds_read"),
                1,
            );
            let checked = run(&body, fixture::config(2, bytes / 2, 1024));
            assert_eq!(
                checked.checks.verdict(Property::AmdTrace),
                Verdict::Pass,
                "{:?}",
                checked.checks
            );
            assert_eq!(
                checked.checks.verdict(Property::AmdMemoryConflict),
                Verdict::Fail,
                "{:?}",
                checked.checks
            );
            assert!(matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
        }
    }
}

#[test]
fn one_independent_m0_state_is_required_even_when_the_payload_is_available() {
    for bytes in [4, 16] {
        let body = fixture::copy(bytes, 0, 128);
        let checked = run(
            &body.replace("s_nop 0\n", ""),
            fixture::config(2, bytes / 2, 1024),
        );
        hazard(&checked, AmdRegisterFile::Scalar, 124);
        assert!(matches!(
            math(&checked, bytes / 2, false),
            EquivOutcome::Equivalent
        ));
    }
}

#[test]
fn descriptor_words_and_vector_address_require_their_real_producers() {
    for wait in ["", "s_waitcnt lgkmcnt(0)\n"] {
        let body = fixture::copy(16, 0, 128).replacen(
            &fixture::quad(0x10000, 128, 0x110000),
            &format!("s_load_dwordx4 s[8:11],s[0:1],0\n{wait}"),
            1,
        );
        let checked = run(&body, fixture::config(2, 8, 1024));
        if wait.is_empty() {
            for index in 8..12 {
                hazard(&checked, AmdRegisterFile::Scalar, index);
            }
        } else {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
        }
    }
    for wait in ["", "s_waitcnt vmcnt(0)\n"] {
        let body = fixture::copy(4, 0, 128).replace("s_mov_b32 m0,0", &format!(
            "s_mov_b64 s[14:15],0x10000\nv_mov_b32 v2,0\nglobal_load_dword v1,v2,s[14:15]\n{wait}s_mov_b32 m0,0"));
        let mut config = fixture::config(1, 1, 1024);
        config.arrays[0].kind = ArrayKind::IndexInput;
        let checked = run(&body, config);
        if wait.is_empty() {
            hazard(&checked, AmdRegisterFile::Vector, 1);
        } else {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
        }
    }
}

#[test]
fn mixed_vm_partial_wait_retains_ordinary_results_in_both_issue_orders() {
    for after in [false, true] {
        for wait in [1, 0] {
            let dma = "buffer_load_dword v1,s[8:11],0 offen lds";
            let load = "global_load_dword v9,v1,s[14:15]";
            let body = fixture::copy(4, 0, 128)
                .replace(
                    "s_mov_b32 m0,0",
                    "s_mov_b64 s[14:15],0x10000\ns_mov_b32 m0,0",
                )
                .replace(
                    dma,
                    &if after {
                        format!("{dma}\n{load}")
                    } else {
                        format!("{load}\n{dma}")
                    },
                )
                .replacen(
                    "s_waitcnt vmcnt(0)\nds_read",
                    &format!("s_waitcnt vmcnt({wait})\nv_mov_b32 v10,v9\nds_read"),
                    1,
                );
            let checked = run(&body, fixture::config(1, 1, 1024));
            if wait == 1 {
                hazard(&checked, AmdRegisterFile::Vector, 9);
            } else {
                assert_eq!(
                    checked.checks.conclusion(),
                    GraphConclusion::Verified,
                    "{:?}",
                    checked.checks
                );
            }
        }
    }
}

#[test]
fn source_reuse_does_not_invent_a_dma_register_destination_or_lease() {
    let mut body = fixture::copy(16, 4, 128);
    body = body.replace("s_mov_b32 m0,4", "v_mov_b32 v3,v1\ns_mov_b32 m0,4");
    body = body.replace(
        "s_waitcnt vmcnt(0)\nds_read",
        "s_mov_b32 s8,0\ns_mov_b32 m0,128\nv_mov_b32 v1,0\ns_waitcnt vmcnt(0)\nds_read",
    );
    body = body.replace("global_store_dwordx4 v1,", "global_store_dwordx4 v3,");
    let checked = run(&body, fixture::config(4, 16, 1024));
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks
    );
    assert!(matches!(
        math(&checked, 16, false),
        EquivOutcome::Equivalent
    ));
    let reads = checked
        .analysis
        .graph()
        .amd_events()
        .iter()
        .find_map(|event| {
            if let AmdEventKind::Instruction { reads, writes, .. } = &event.kind
                && writes.is_empty()
                && reads
                    .iter()
                    .any(|r| r.file == AmdRegisterFile::Scalar && r.index == 124)
            {
                Some(reads)
            } else {
                None
            }
        })
        .unwrap();
    assert_eq!(reads.len(), 6);
    for index in [8, 9, 10, 11, 124] {
        assert!(
            reads.iter().any(|r| r.file == AmdRegisterFile::Scalar
                && r.index == index
                && r.lanes == u64::MAX)
        );
    }
    assert!(
        reads
            .iter()
            .any(|r| r.file == AmdRegisterFile::Vector && r.index == 1 && r.lanes == 15)
    );
}

#[test]
fn wave_local_lane_pitch_and_disjoint_m0_bases_preserve_multiwave_outputs() {
    for bytes in [4, 16] {
        let len = 128 * bytes / 4;
        let body = fixture::copy(bytes, 0, (len * 4) as u32).replace(
            "s_mov_b32 m0,0",
            &format!(
                "v_cmp_le_u32 vcc,64,v0\ns_cbranch_vccnz .Lwave1\ns_mov_b32 m0,0\ns_branch .Lready\n.Lwave1:\ns_mov_b32 m0,{}\n.Lready:",
                bytes * 64
            ),
        );
        let checked = run(&body, fixture::config(128, len, 4096));
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{:?}",
            checked.checks
        );
        assert!(matches!(
            math(&checked, len, false),
            EquivOutcome::Equivalent
        ));
    }
}
