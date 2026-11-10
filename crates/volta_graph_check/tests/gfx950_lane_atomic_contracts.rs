//! Adversarial records independently test the producer's new CDNA4 profiles.
use volta_graph::*;
use volta_graph_check::{Verdict, amdgpu::check_amdgpu};

fn s(index: u16) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Scalar,
        index,
        lanes: u64::MAX,
    }
}
fn v(index: u16, lanes: u64) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Vector,
        index,
        lanes,
    }
}
fn builder(target: &str, kind: &'static str) -> GraphBuilder {
    GraphBuilder::new(Provenance {
        kernel: "contract".into(),
        block_dim: (64, 1, 1),
        unit: ThreadUnit::CtaThread,
        grid_dim: (1, 1, 1),
        workgroup_id: (0, 0, 0),
        targets: vec![target.into()],
        assumptions: vec![],
        instructions: vec![
            InstructionInfo { kind, span: None },
            InstructionInfo {
                kind: "wait",
                span: None,
            },
        ],
    })
}
fn ins(
    b: &mut GraphBuilder,
    pc: ProgramPoint,
    exec_mask: u64,
    reads: Vec<AmdRegister>,
    writes: Vec<AmdRegister>,
) {
    b.amd_event(
        0,
        pc,
        AmdEventKind::Instruction {
            exec_mask,
            reads,
            writes,
            scalar_mask_reads: vec![],
        },
    );
}
fn finish(mut b: GraphBuilder) -> EventGraph {
    for thread in 0..64 {
        b.exit(ThreadIx(thread), ProgramPoint(1));
    }
    b.finish(Terminal::Completed)
}

#[test]
fn selected_lane_markers_require_the_selector_role_even_under_empty_exec() {
    for read in [true, false] {
        for bad in 0..=9 {
            let kind = match (read, bad == 1) {
                (true, false) => "readlane scalar",
                (false, false) => "writelane scalar",
                (true, true) => "readlane",
                (false, true) => "writelane",
            };
            let mut b = builder("gfx950", kind);
            let pc = ProgramPoint(if bad == 7 { 999 } else { 0 });
            let mut reads = if read {
                vec![v(0, 1 << 5), s(5)]
            } else {
                vec![s(5), s(5)]
            };
            let writes = if read { vec![s(6)] } else { vec![v(0, 1 << 5)] };
            match bad {
                2 => {
                    reads.pop();
                }
                3 => reads[1] = v(5, 1 << 5),
                4 => reads[1] = s(124),
                5 => reads.push(s(6)),
                9 => {
                    if read {
                        reads[1] = s(124);
                    } else {
                        reads[0] = s(4);
                    }
                }
                _ => {}
            }
            ins(&mut b, pc, 0, reads, writes);
            if bad != 6 {
                b.amd_event(
                    0,
                    pc,
                    if read {
                        AmdEventKind::LaneRead {
                            lane: if bad == 8 { 6 } else { 5 },
                        }
                    } else {
                        AmdEventKind::LaneWrite {
                            lane: if bad == 8 { 6 } else { 5 },
                        }
                    },
                );
            }
            assert_eq!(
                check_amdgpu(&finish(b)).trace.verdict(),
                if bad == 0 {
                    Verdict::Pass
                } else {
                    Verdict::Unknown
                },
                "read={read}, bad={bad}"
            );
        }
    }
}

fn atomic(bad: u8) -> EventGraph {
    let mut b = builder(
        if bad == 18 { "gfx942" } else { "gfx950" },
        if bad == 17 {
            "vector memory"
        } else {
            "atomic f32 add no return"
        },
    );
    let pc = ProgramPoint(if bad == 15 { 999 } else { 0 });
    // Duplicate v0 roles are deliberate: address and data may alias.
    let mut reads = vec![v(0, 1), v(0, 1), s(4), s(5)];
    if bad == 3 {
        reads.pop();
    }
    if bad == 16 {
        reads[2] = s(5);
        reads[3] = s(6);
    }
    let mut held = reads.clone();
    if bad == 2 {
        held.pop();
    }
    let writes = if bad == 4 { vec![v(3, 1)] } else { vec![] };
    ins(
        &mut b,
        pc,
        if bad == 5 {
            0
        } else if bad == 6 {
            3
        } else {
            1
        },
        reads,
        writes.clone(),
    );
    let issue = b.amd_event(
        0,
        pc,
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::GlobalAtomicAddF32NoReturn,
            counters: vec![(
                if bad == 1 {
                    AmdCounter::Lgkm
                } else {
                    AmdCounter::Vm
                },
                1,
            )],
            destinations: writes,
            held_sources: held,
        },
    );
    let mut modes = vec![AccessMode::Read, AccessMode::Write];
    if bad == 11 {
        modes.reverse();
    }
    if bad == 13 {
        modes.pop();
    }
    if bad == 14 {
        modes.push(AccessMode::Write);
    }
    for mode in modes {
        let thread = ThreadIx(u32::from(bad == 7));
        let value = (mode == AccessMode::Write).then(|| b.value(StoredValue::Opaque));
        let effect = b.thread_access(
            thread,
            pc,
            MemAccess {
                space: Space::Global,
                mode,
                ordering: if bad == 12 {
                    OrderingKind::Ordinary
                } else {
                    OrderingKind::Atomic
                },
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes {
                    addr: 0x10000
                        + if bad == 9 {
                            2
                        } else if bad == 10 && mode == AccessMode::Write {
                            4
                        } else {
                            0
                        },
                    width: if bad == 8 { 8 } else { 4 },
                },
                role: OperandRole::Plain,
                attributed: thread,
                value,
            },
        );
        b.amd_memory_effect(issue, effect);
    }
    ins(&mut b, ProgramPoint(1), 1, vec![], vec![]);
    b.amd_event(
        0,
        ProgramPoint(1),
        AmdEventKind::Wait {
            vmcnt: Some(0),
            lgkmcnt: Some(0),
            expcnt: Some(0),
        },
    );
    finish(b)
}

#[test]
fn atomic_contract_rejects_malformed_roles_counters_and_rmw_pairs() {
    for bad in 0..=18 {
        let checked = check_amdgpu(&atomic(bad));
        assert_eq!(
            checked.trace.verdict(),
            if bad == 0 {
                Verdict::Pass
            } else {
                Verdict::Unknown
            },
            "bad={bad}: {:?}",
            checked.trace
        );
        if bad == 0 {
            assert_eq!(checked.wait_readiness.verdict(), Verdict::Pass);
            assert_eq!(checked.memory_conflict.verdict(), Verdict::Pass);
        }
    }
}

#[test]
fn salu_redefinition_keeps_the_prior_valu_selector_dependency() {
    for read in [true, false] {
        for states in 0..=4 {
            let prototype = builder(
                "gfx950",
                if read {
                    "readlane scalar"
                } else {
                    "writelane scalar"
                },
            );
            let mut provenance = prototype.finish(Terminal::Completed).provenance().clone();
            provenance.instructions.extend([
                InstructionInfo {
                    kind: "vector ALU",
                    span: None,
                },
                InstructionInfo {
                    kind: "scalar ALU",
                    span: None,
                },
                InstructionInfo {
                    kind: "s_nop",
                    span: None,
                },
            ]);
            let mut b = GraphBuilder::new(provenance);
            // Generic VALU SGPR producer, followed by a SALU write to the same
            // physical word. The explicit selector rule retains its history.
            ins(&mut b, ProgramPoint(2), u64::MAX, vec![], vec![s(5)]);
            ins(&mut b, ProgramPoint(3), u64::MAX, vec![], vec![s(5)]);
            if states != 0 {
                ins(&mut b, ProgramPoint(4), u64::MAX, vec![], vec![]);
                b.amd_event(0, ProgramPoint(4), AmdEventKind::Delay { cycles: states });
            }
            ins(
                &mut b,
                ProgramPoint(0),
                0,
                if read {
                    vec![v(0, 1), s(5)]
                } else {
                    vec![s(5), s(5)]
                },
                if read { vec![s(6)] } else { vec![v(0, 1)] },
            );
            b.amd_event(
                0,
                ProgramPoint(0),
                if read {
                    AmdEventKind::LaneRead { lane: 0 }
                } else {
                    AmdEventKind::LaneWrite { lane: 0 }
                },
            );
            let checked = check_amdgpu(&finish(b));
            assert_eq!(checked.trace.verdict(), Verdict::Pass);
            assert_eq!(
                checked.wait_readiness.violations().iter().any(|h| h.kind
                    == volta_graph_check::amdgpu::AmdRegisterHazardKind::ValuScalarReadBeforeReady
                    && h.register.index == 5),
                states + 1 < 4,
                "read={read}, states={states}"
            );
        }
    }
}
