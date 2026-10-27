use volta_graph::*;
use volta_graph_check::amdgpu::AmdRegisterHazardKind;
use volta_graph_check::{GraphConclusion, Property, PropertyResult, Verdict, check_graph};

fn v(index: u16, lanes: u64) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Vector,
        index,
        lanes,
    }
}
fn s(index: u16) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Scalar,
        index,
        lanes: u64::MAX,
    }
}
struct Trace {
    b: GraphBuilder,
    threads: u32,
}
impl Trace {
    fn new(threads: u32) -> Self {
        Self::with_kind(threads, "amd")
    }
    fn with_kind(threads: u32, kind: &'static str) -> Self {
        Self {
            threads,
            b: GraphBuilder::new(Provenance {
                kernel: "amd_test".into(),
                block_dim: (threads, 1, 1),
                grid_dim: (1, 1, 1),
                targets: vec!["gfx950".into()],
                assumptions: vec![],
                instructions: (0..100)
                    .map(|_| InstructionInfo { kind, span: None })
                    .collect(),
            }),
        }
    }
    fn ins(
        &mut self,
        wave: u32,
        pc: u32,
        reads: Vec<AmdRegister>,
        writes: Vec<AmdRegister>,
    ) -> EventId {
        let n = (self.threads - wave * 64).min(64);
        let mask = if n == 64 { u64::MAX } else { (1u64 << n) - 1 };
        self.b.amd_event(
            wave,
            ProgramPoint(pc),
            AmdEventKind::Instruction {
                scalar_mask_reads: vec![],
                exec_mask: mask,
                reads,
                writes,
            },
        )
    }
    fn issue(
        &mut self,
        wave: u32,
        pc: u32,
        class: AmdMemoryClass,
        destinations: Vec<AmdRegister>,
        held_sources: Vec<AmdRegister>,
        addr: u64,
        write: bool,
    ) -> EventId {
        self.ins(wave, pc, held_sources.clone(), destinations.clone());
        let counters = match class {
            AmdMemoryClass::VectorMemory | AmdMemoryClass::VectorStoreWide => {
                vec![(AmdCounter::Vm, 1)]
            }
            AmdMemoryClass::Flat | AmdMemoryClass::FlatStoreWide => {
                vec![(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)]
            }
            _ => vec![(AmdCounter::Lgkm, 1)],
        };
        let issue = self.b.amd_event(
            wave,
            ProgramPoint(pc),
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations,
                held_sources,
            },
        );
        let value = write.then(|| self.b.value(StoredValue::Opaque));
        let effect = self.b.thread_access(
            ThreadIx(wave * 64),
            ProgramPoint(pc),
            MemAccess {
                space: if class == AmdMemoryClass::Lds {
                    Space::Shared
                } else {
                    Space::Global
                },
                mode: if write {
                    AccessMode::Write
                } else {
                    AccessMode::Read
                },
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes { addr, width: 4 },
                role: OperandRole::Plain,
                attributed: ThreadIx(wave * 64),
                value,
            },
        );
        self.b.amd_memory_effect(issue, effect);
        issue
    }
    fn wait(&mut self, wave: u32, pc: u32, vmcnt: Option<u16>, lgkmcnt: Option<u16>) {
        self.ins(wave, pc, vec![], vec![]);
        self.b.amd_event(
            wave,
            ProgramPoint(pc),
            AmdEventKind::Wait {
                vmcnt,
                lgkmcnt,
                expcnt: None,
            },
        );
    }
    fn arrive(&mut self, wave: u32, generation: u32) {
        self.ins(wave, 90, vec![], vec![]);
        let n = (self.threads - wave * 64).min(64);
        let mask = if n == 64 { u64::MAX } else { (1u64 << n) - 1 };
        self.b.amd_event(
            wave,
            ProgramPoint(90),
            AmdEventKind::BarrierArrive {
                generation,
                exec_mask: mask,
            },
        );
    }
    fn release(&mut self, wave: u32, generation: u32) {
        self.b.amd_event(
            wave,
            ProgramPoint(90),
            AmdEventKind::BarrierRelease { generation },
        );
    }
    fn finish(mut self) -> EventGraph {
        for t in 0..self.threads {
            self.b.exit(ThreadIx(t), ProgramPoint(99));
        }
        self.b.finish(Terminal::Completed)
    }
}

#[test]
fn target_selects_amd_checks_and_empty_graph_cannot_verify() {
    let g = Trace::new(64).finish();
    let r = check_graph(&g);
    assert_eq!(r.applicable_properties(), &Property::AMD);
    assert_eq!(r.verdict(Property::AmdTrace), Verdict::Unknown);
    assert_eq!(r.verdict(Property::MemoryConflict), Verdict::Unknown);
    assert!(matches!(r.conclusion(), GraphConclusion::Unknown { .. }));
}

#[test]
fn recognized_target_features_select_amd_checks_and_conflicts_remain_unknown() {
    for (target, supported) in [
        ("gfx950", true),
        ("gfx950:xnack-", true),
        ("gfx950:xnack+", true),
        ("gfx950:sramecc+:xnack-", true),
        ("gfx950:xnack+:sramecc-", true),
        ("gfx950:xnack-:xnack+", false),
        ("gfx950:xnack-:xnack-", false),
        ("gfx950:sramecc+:sramecc-", false),
        ("gfx950:wave32", false),
        ("gfx950:", false),
        ("gfx942:xnack-", false),
    ] {
        let mut builder = GraphBuilder::new(Provenance {
            kernel: "target_features".into(),
            block_dim: (64, 1, 1),
            grid_dim: (1, 1, 1),
            targets: vec![target.into()],
            assumptions: vec![],
            instructions: vec![InstructionInfo {
                kind: "vector ALU",
                span: None,
            }],
        });
        builder.amd_event(
            0,
            ProgramPoint(0),
            AmdEventKind::Instruction {
                exec_mask: u64::MAX,
                reads: vec![],
                writes: vec![],
                scalar_mask_reads: vec![],
            },
        );
        for thread in 0..64 {
            builder.exit(ThreadIx(thread), ProgramPoint(0));
        }
        let checks = check_graph(&builder.finish(Terminal::Completed));
        assert_eq!(checks.applicable_properties(), &Property::AMD, "{target}");
        if supported {
            assert_eq!(
                checks.conclusion(),
                GraphConclusion::Verified,
                "{target}: {checks:?}"
            );
        } else {
            assert!(
                matches!(checks.conclusion(), GraphConclusion::Unknown { .. }),
                "{target}"
            );
        }
    }
}

#[test]
fn missing_wait_has_typed_read_hazard_and_zero_wait_repairs_it() {
    for correct in [false, true] {
        let mut t = Trace::new(64);
        let issue = t.issue(
            0,
            0,
            AmdMemoryClass::VectorMemory,
            vec![v(1, 1)],
            vec![],
            0,
            false,
        );
        if correct {
            t.wait(0, 1, Some(0), None);
        }
        let use_event = t.ins(0, 2, vec![v(1, 1)], vec![]);
        let r = check_graph(&t.finish());
        if correct {
            assert_eq!(r.conclusion(), GraphConclusion::Verified);
        } else {
            let hazards = r.amd.unwrap().wait_readiness;
            assert!(hazards.violations().iter().any(|h| h.issue == issue
                && h.use_event == use_event
                && h.kind == AmdRegisterHazardKind::ReadBeforeReady));
        }
    }
}

#[test]
fn partial_fifo_wait_retires_only_oldest_vector_memory() {
    let mut t = Trace::new(64);
    t.issue(
        0,
        0,
        AmdMemoryClass::VectorMemory,
        vec![v(1, 1)],
        vec![],
        0,
        false,
    );
    let second = t.issue(
        0,
        1,
        AmdMemoryClass::VectorMemory,
        vec![v(2, 1)],
        vec![],
        4,
        false,
    );
    t.wait(0, 2, Some(1), None);
    let use_event = t.ins(0, 3, vec![v(1, 1), v(2, 1)], vec![]);
    let r = check_graph(&t.finish());
    let hazards = r.amd.unwrap().wait_readiness;
    assert_eq!(hazards.violations().len(), 1);
    assert_eq!(hazards.violations()[0].issue, second);
    assert_eq!(hazards.violations()[0].use_event, use_event);
}

#[test]
fn scalar_and_mixed_lgkm_nonzero_waits_do_not_assume_fifo() {
    for mixed in [false, true] {
        let mut t = Trace::new(64);
        t.issue(
            0,
            0,
            AmdMemoryClass::ScalarMemory,
            vec![s(2)],
            vec![],
            0,
            false,
        );
        t.issue(
            0,
            1,
            if mixed {
                AmdMemoryClass::Lds
            } else {
                AmdMemoryClass::ScalarMemory
            },
            vec![if mixed { v(2, 1) } else { s(3) }],
            vec![],
            4,
            false,
        );
        t.wait(0, 2, None, Some(1));
        t.ins(0, 3, vec![s(2)], vec![]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            Verdict::Fail
        );
    }
}

#[test]
fn flat_needs_both_counters() {
    for both in [false, true] {
        let mut t = Trace::new(64);
        t.issue(0, 0, AmdMemoryClass::Flat, vec![v(1, 1)], vec![], 0, false);
        t.wait(0, 1, Some(0), both.then_some(0));
        t.ins(0, 2, vec![v(1, 1)], vec![]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            if both { Verdict::Pass } else { Verdict::Fail }
        );
    }
}

#[test]
fn register_readiness_respects_slices_and_held_store_sources() {
    let mut t = Trace::new(64);
    t.issue(
        0,
        0,
        AmdMemoryClass::VectorMemory,
        vec![v(1, 1)],
        vec![],
        0,
        false,
    );
    t.ins(0, 1, vec![v(1, 2)], vec![v(1, 2)]);
    t.issue(
        0,
        2,
        AmdMemoryClass::VectorMemory,
        vec![],
        vec![v(4, 1)],
        4,
        true,
    );
    t.ins(0, 3, vec![], vec![v(4, 1)]);
    t.ins(0, 4, vec![], vec![v(1, 1)]);
    let r = check_graph(&t.finish());
    let result = r.amd.unwrap().wait_readiness;
    assert_eq!(result.violations().len(), 2);
    assert!(
        result
            .violations()
            .iter()
            .any(|h| h.kind == AmdRegisterHazardKind::SourceReuse)
    );
    assert!(
        result
            .violations()
            .iter()
            .any(|h| h.kind == AmdRegisterHazardKind::DestinationReuse)
    );
}

#[test]
fn cross_wave_lds_needs_completed_writes_and_a_barrier() {
    for wait in [false, true] {
        for barrier in [false, true] {
            let mut t = Trace::new(65);
            t.issue(0, 0, AmdMemoryClass::Lds, vec![], vec![], 0, true);
            t.ins(1, 0, vec![], vec![]);
            if wait {
                t.wait(0, 1, None, Some(0));
            }
            if barrier {
                t.arrive(0, 0);
                t.arrive(1, 0);
                t.release(0, 0);
                t.release(1, 0);
            }
            t.issue(1, 2, AmdMemoryClass::Lds, vec![v(1, 1)], vec![], 0, false);
            t.wait(1, 3, None, Some(0));
            t.ins(1, 4, vec![v(1, 1)], vec![]);
            let r = check_graph(&t.finish());
            assert_eq!(
                r.verdict(Property::AmdMemoryConflict),
                if wait && barrier {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                },
                "wait={wait}, barrier={barrier}, {r:?}"
            );
        }
    }
}

#[test]
fn repeated_barriers_and_partial_waves_have_distinct_generations() {
    let mut t = Trace::new(65);
    t.ins(0, 0, vec![], vec![]);
    t.ins(1, 0, vec![], vec![]);
    for generation in 0..3 {
        t.arrive(0, generation);
        t.arrive(1, generation);
        t.release(0, generation);
        t.release(1, generation);
    }
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn barrier_release_before_all_waves_arrive_is_a_typed_failure() {
    let mut t = Trace::new(128);
    t.ins(0, 0, vec![], vec![]);
    t.ins(1, 0, vec![], vec![]);
    t.arrive(0, 0);
    t.release(0, 0);
    let r = check_graph(&t.finish());
    assert_eq!(r.verdict(Property::AmdBarrier), Verdict::Fail);
    assert!(
        r.amd.unwrap().barrier.violations()[0]
            .reason
            .contains("missing waves")
    );
}

#[test]
fn incomplete_and_foreign_events_never_verify() {
    let mut t = Trace::new(64);
    t.ins(0, 0, vec![], vec![]);
    let g = t.b.finish(Terminal::Aborted {
        thread: None,
        pc: None,
        cause: AbortCause::Unsupported,
        reason: "budget".into(),
    });
    assert!(matches!(
        check_graph(&g).conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    let mut t = Trace::new(64);
    t.ins(0, 0, vec![], vec![]);
    t.b.fence(
        ThreadIx(0),
        ProgramPoint(1),
        FenceKind::ProxyAsync { space: None },
    );
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn missing_memory_associations_cannot_silently_pass() {
    let mut t = Trace::new(64);
    t.ins(0, 0, vec![], vec![v(1, 1)]);
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::VectorMemory,
            counters: vec![(AmdCounter::Vm, 1)],
            destinations: vec![v(1, 1)],
            held_sources: vec![],
        },
    );
    let r = check_graph(&t.finish());
    assert!(matches!(r.amd.unwrap().trace, PropertyResult::Unknown(_)));
}

#[test]
fn missing_and_duplicate_instruction_records_are_unknown() {
    let mut t = Trace::new(64);
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::Wait {
            vmcnt: Some(0),
            lgkmcnt: None,
            expcnt: None,
        },
    );
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
    let mut t = Trace::new(64);
    t.wait(0, 0, Some(0), None);
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::Wait {
            vmcnt: Some(0),
            lgkmcnt: None,
            expcnt: None,
        },
    );
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn known_memory_instruction_without_issue_is_unknown() {
    let mut t = Trace::with_kind(64, "vector memory");
    t.ins(0, 0, vec![], vec![v(2, 1)]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn malformed_source_point_and_nonphysical_exec_mask_are_unknown_without_panics() {
    let mut t = Trace::new(1);
    t.ins(0, 999, vec![], vec![]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
    let mut t = Trace::new(1);
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::Instruction {
            scalar_mask_reads: vec![],
            exec_mask: 1u64 << 63,
            reads: vec![],
            writes: vec![],
        },
    );
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn omitted_pending_destination_cannot_bypass_readiness() {
    let mut t = Trace::new(64);
    t.ins(0, 0, vec![], vec![v(1, 1)]);
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::CrossLane,
            counters: vec![(AmdCounter::Lgkm, 1)],
            destinations: vec![],
            held_sources: vec![],
        },
    );
    t.ins(0, 1, vec![v(1, 1)], vec![]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn instruction_execution_between_barrier_arrival_and_release_fails() {
    let mut t = Trace::new(128);
    t.ins(0, 0, vec![], vec![]);
    t.ins(1, 0, vec![], vec![]);
    t.arrive(0, 0);
    t.ins(0, 1, vec![], vec![]);
    t.arrive(1, 0);
    t.release(0, 0);
    t.release(1, 0);
    let r = check_graph(&t.finish());
    assert!(
        r.amd
            .unwrap()
            .barrier
            .violations()
            .iter()
            .any(|v| v.reason.contains("progressed before"))
    );
}

#[test]
fn cross_lane_operations_have_pending_registers_without_fake_lds_effects() {
    for correct in [false, true] {
        let mut t = Trace::new(64);
        t.ins(0, 0, vec![v(1, u64::MAX)], vec![v(2, u64::MAX)]);
        t.b.amd_event(
            0,
            ProgramPoint(0),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::CrossLane,
                counters: vec![(AmdCounter::Lgkm, 1)],
                destinations: vec![v(2, u64::MAX)],
                held_sources: vec![],
            },
        );
        if correct {
            t.wait(0, 1, None, Some(0));
        }
        t.ins(0, 2, vec![v(2, u64::MAX)], vec![]);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass);
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if correct {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}

fn matrix(t: &mut Trace, pc: u32, accumulate: bool) {
    let destinations = (2..6).map(|r| v(r, u64::MAX)).collect::<Vec<_>>();
    let sources_ab = vec![v(0, u64::MAX), v(1, u64::MAX)];
    let accumulator = if accumulate {
        destinations.clone()
    } else {
        vec![]
    };
    let mut reads = sources_ab.clone();
    reads.extend(accumulator.clone());
    reads.extend([s(126), s(127)]);
    t.ins(0, pc, reads, destinations.clone());
    t.b.amd_event(
        0,
        ProgramPoint(pc),
        AmdEventKind::MatrixIssue {
            kind: AmdMatrixKind::F32_16x16x4,
            destinations,
            sources_ab,
            accumulator,
        },
    );
}
fn delay(t: &mut Trace, pc: u32, cycles: u16) {
    t.ins(0, pc, vec![], vec![]);
    t.b.amd_event(0, ProgramPoint(pc), AmdEventKind::Delay { cycles });
}

#[test]
fn mfma_requires_ten_independent_states_and_waitcnt_does_not_substitute() {
    for nops in [0u16, 9, 10] {
        // Every instruction has a known static source class; only pc1 is S_NOP.
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[1].kind = "s_nop";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        matrix(&mut t, 0, false);
        if nops != 0 {
            delay(&mut t, 1, nops);
        }
        let read = t.ins(0, 2, vec![v(2, u64::MAX)], vec![]);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if nops == 10 {
                Verdict::Pass
            } else {
                Verdict::Fail
            },
            "nops={nops}: {r:?}"
        );
        if nops != 10 {
            assert!(
                r.amd
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.use_event == read
                        && h.kind == AmdRegisterHazardKind::MatrixReadBeforeReady)
            );
        }
    }
    let mut t = Trace::new(64);
    matrix(&mut t, 0, false);
    t.wait(0, 1, Some(0), Some(0));
    t.ins(0, 2, vec![v(2, u64::MAX)], vec![]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
        Verdict::Fail
    );
}

#[test]
fn same_form_exact_accumulator_forwarding_is_legal() {
    let mut t = Trace::new(64);
    matrix(&mut t, 0, false);
    matrix(&mut t, 1, true);
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn valu_producer_needs_two_independent_states_before_mfma() {
    for independent in [0u16, 1, 2] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[0].kind = "vector ALU";
        p.instructions[1].kind = "s_nop";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        t.ins(0, 0, vec![], vec![v(0, u64::MAX)]);
        if independent != 0 {
            delay(&mut t, 1, independent);
        }
        matrix(&mut t, 2, false);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            if independent == 2 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}

#[test]
fn unpinned_delay_cannot_forge_matrix_readiness() {
    let mut t = Trace::new(64);
    matrix(&mut t, 0, false);
    delay(&mut t, 1, 10);
    t.ins(0, 2, vec![v(2, u64::MAX)], vec![]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn structural_bad_associations_return_unknown_before_indexing() {
    let mut t = Trace::new(64);
    t.ins(0, 0, vec![], vec![]);
    t.b.amd_memory_effect(EventId(u32::MAX), EventId(u32::MAX));
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn cross_wave_global_visibility_is_not_proved_by_a_barrier() {
    let mut t = Trace::new(128);
    t.issue(0, 0, AmdMemoryClass::VectorMemory, vec![], vec![], 0, true);
    t.ins(1, 0, vec![], vec![]);
    t.wait(0, 1, Some(0), None);
    t.arrive(0, 0);
    t.arrive(1, 0);
    t.release(0, 0);
    t.release(1, 0);
    t.issue(
        1,
        2,
        AmdMemoryClass::VectorMemory,
        vec![v(1, 1)],
        vec![],
        0,
        false,
    );
    t.wait(1, 3, Some(0), None);
    let r = check_graph(&t.finish());
    assert_eq!(r.verdict(Property::AmdMemoryConflict), Verdict::Unknown);
    assert!(
        r.amd.unwrap().memory_conflict.unresolved()[0]
            .reason
            .contains("cache visibility")
    );
}

#[test]
fn wide_store_source_overwrite_needs_two_states_for_valu_but_not_a_full_wait() {
    for independent in [0, 1, 2] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[90].kind = "vector ALU";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        t.issue(
            0,
            0,
            AmdMemoryClass::VectorStoreWide,
            vec![],
            vec![v(4, 1), v(5, 1), v(6, 1)],
            0,
            true,
        );
        for pc in 1..=independent {
            t.ins(0, pc, vec![], vec![]);
        }
        t.ins(0, 90, vec![], vec![v(4, 1)]);
        let r = check_graph(&t.finish());
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if independent == 2 {
                Verdict::Pass
            } else {
                Verdict::Fail
            },
            "{r:?}"
        );
    }
}

#[test]
fn trans_alu_result_needs_one_independent_state_before_nontrans_alu() {
    for independent in [false, true] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[0].kind = "trans ALU";
        p.instructions[2].kind = "vector ALU";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        t.ins(0, 0, vec![v(0, 1)], vec![v(1, 1)]);
        if independent {
            t.ins(0, 1, vec![], vec![]);
        }
        t.ins(0, 2, vec![v(1, 1)], vec![v(2, 1)]);
        let r = check_graph(&t.finish());
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if independent {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if !independent {
            assert!(
                r.amd
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.kind == AmdRegisterHazardKind::ValuReadBeforeReady)
            );
        }
    }
}

#[test]
fn shifted_result_needs_one_independent_state_even_for_trans_valu_consumer() {
    for independent in [false, true] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[0].kind = "shifted ALU";
        p.instructions[2].kind = "trans ALU";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        t.ins(0, 0, vec![v(0, 1)], vec![v(1, 1)]);
        if independent {
            t.ins(0, 1, vec![], vec![]);
        }
        t.ins(0, 2, vec![v(1, 1)], vec![v(2, 1)]);
        let r = check_graph(&t.finish());
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if independent {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}

#[test]
fn exact_accumulator_forwarding_does_not_require_reusing_the_output_registers() {
    let mut t = Trace::new(64);
    matrix(&mut t, 0, false);
    let destinations = (6..10).map(|r| v(r, u64::MAX)).collect::<Vec<_>>();
    let sources_ab = vec![v(0, u64::MAX), v(1, u64::MAX)];
    let accumulator = (2..6).map(|r| v(r, u64::MAX)).collect::<Vec<_>>();
    let mut reads = sources_ab.clone();
    reads.extend(accumulator.clone());
    reads.extend([s(126), s(127)]);
    t.ins(0, 1, reads, destinations.clone());
    t.b.amd_event(
        0,
        ProgramPoint(1),
        AmdEventKind::MatrixIssue {
            kind: AmdMatrixKind::F32_16x16x4,
            destinations,
            sources_ab,
            accumulator,
        },
    );
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

fn matrix_form(t: &mut Trace, pc: u32, kind: AmdMatrixKind, c_start: Option<u16>) {
    let destinations = (32..32 + kind.destination_registers() as u16)
        .map(|r| v(r, u64::MAX))
        .collect::<Vec<_>>();
    let mut sources_ab = (0..kind.input_registers() as u16)
        .chain(16..16 + kind.input_registers() as u16)
        .map(|r| v(r, u64::MAX))
        .collect::<Vec<_>>();
    sources_ab.extend((0..kind.scale_registers()).map(|_| v(24, u64::MAX)));
    let accumulator = c_start
        .map(|start| {
            (start..start + kind.destination_registers() as u16)
                .map(|r| v(r, u64::MAX))
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();
    let mut reads = sources_ab.clone();
    reads.extend(accumulator.clone());
    reads.extend([s(126), s(127)]);
    t.ins(0, pc, reads, destinations.clone());
    t.b.amd_event(
        0,
        ProgramPoint(pc),
        AmdEventKind::MatrixIssue {
            kind,
            destinations,
            sources_ab,
            accumulator,
        },
    );
}

#[test]
fn selected_mfma_forms_have_distinct_documented_result_waits() {
    for (kind, required) in [
        (AmdMatrixKind::F32_32x32x2, 18),
        (AmdMatrixKind::F16_16x16x16, 8),
        (AmdMatrixKind::F16_16x16x32, 8),
        (AmdMatrixKind::Bf16_32x32x16, 12),
        (AmdMatrixKind::Fp8_16x16x128, 12),
        (AmdMatrixKind::Fp8Scale_16x16x128, 12),
        (AmdMatrixKind::Fp8Scale_32x32x64, 20),
    ] {
        for independent in [required - 1, required] {
            let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
            p.instructions[1].kind = "s_nop";
            p.instructions[2].kind = "s_nop";
            let mut t = Trace {
                b: GraphBuilder::new(p),
                threads: 64,
            };
            matrix_form(&mut t, 0, kind, None);
            // S_NOP max16; split longer delays without inventing encoding.
            delay(&mut t, 1, independent.min(16));
            if independent > 16 {
                delay(&mut t, 2, independent - 16);
            }
            t.ins(0, 3, vec![v(32, u64::MAX)], vec![]);
            let r = check_graph(&t.finish());
            assert_eq!(
                r.verdict(Property::AmdTrace),
                Verdict::Pass,
                "{kind:?}: {r:?}"
            );
            assert_eq!(
                r.verdict(Property::AmdWaitReadiness),
                if independent == required {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                },
                "{kind:?} needs{required} independent states, supplied{independent}: {r:?}"
            );
        }
    }
}

#[test]
fn xdl_src_c_war_needs_three_states_and_exact_forwarding_needs_none() {
    for independent in [0, 2, 3] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[1].kind = "s_nop";
        p.instructions[2].kind = "vector ALU";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        matrix_form(&mut t, 0, AmdMatrixKind::F16_16x16x16, Some(64));
        if independent != 0 {
            delay(&mut t, 1, independent);
        }
        let overwrite = t.ins(0, 2, vec![], vec![v(64, u64::MAX)]);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if independent == 3 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if independent != 3 {
            assert!(
                r.amd
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.use_event == overwrite
                        && h.kind == AmdRegisterHazardKind::MatrixSourceReuse)
            );
        }
    }
    let mut t = Trace::new(64);
    matrix_form(&mut t, 0, AmdMatrixKind::F16_16x16x16, None);
    matrix_form(&mut t, 1, AmdMatrixKind::F16_16x16x16, Some(32));
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn wide_store_followed_by_async_load_destination_does_not_invent_a_valu_overwrite() {
    let mut t = Trace::new(64);
    t.issue(
        0,
        0,
        AmdMemoryClass::VectorStoreWide,
        vec![],
        vec![
            v(0, u64::MAX),
            v(1, u64::MAX),
            v(2, u64::MAX),
            v(3, u64::MAX),
        ],
        100,
        true,
    );
    t.issue(
        0,
        1,
        AmdMemoryClass::VectorMemory,
        vec![v(0, u64::MAX)],
        vec![],
        200,
        false,
    );
    t.wait(0, 2, Some(0), None);
    t.ins(0, 3, vec![v(0, u64::MAX)], vec![]);
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn exact_src_c_does_not_forward_between_different_matrix_pass_counts() {
    // Table38 requires the same number of passes for exact XDL SrcC forwarding.
    // F16(4passes) -> FP8(8passes), and XDL F16 -> SGEMM(8passes), must each
    // take the six-state overlapping-C path despite equal four-register ranges.
    for consumer in [AmdMatrixKind::Fp8_16x16x128, AmdMatrixKind::F32_16x16x4] {
        for independent in [0, 5, 6] {
            let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
            p.instructions[1].kind = "s_nop";
            let mut t = Trace {
                b: GraphBuilder::new(p),
                threads: 64,
            };
            matrix_form(&mut t, 0, AmdMatrixKind::F16_16x16x16, None);
            if independent != 0 {
                delay(&mut t, 1, independent);
            }
            matrix_form(&mut t, 2, consumer, Some(32));
            let r = check_graph(&t.finish());
            assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
            assert_eq!(
                r.verdict(Property::AmdWaitReadiness),
                if independent == 6 {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                },
                "{consumer:?}, independent={independent}: {r:?}"
            );
        }
    }
    // The separately documented SGEMM -> XDL overlapping-C path needs zero.
    let mut t = Trace::new(64);
    matrix_form(&mut t, 0, AmdMatrixKind::F32_16x16x4, None);
    matrix_form(&mut t, 1, AmdMatrixKind::F16_16x16x16, Some(32));
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

fn cross_lane_issue(t: &mut Trace, pc: u32, destination: u16) {
    let destinations = vec![v(destination, u64::MAX)];
    t.ins(0, pc, vec![v(0, u64::MAX)], destinations.clone());
    t.b.amd_event(
        0,
        ProgramPoint(pc),
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::CrossLane,
            counters: vec![(AmdCounter::Lgkm, 1)],
            destinations,
            held_sources: vec![],
        },
    );
}

#[test]
fn partial_cross_lane_wait_retires_only_guaranteed_ds_fifo_prefix() {
    for (threshold, read, expected) in [
        (3, 20, Verdict::Pass),
        (3, 21, Verdict::Fail),
        (4, 20, Verdict::Fail),
    ] {
        let mut t = Trace::new(64);
        for index in 0..4 {
            cross_lane_issue(&mut t, index, 20 + index as u16);
        }
        t.wait(0, 4, None, Some(threshold));
        t.ins(0, 5, vec![v(read, u64::MAX)], vec![]);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            expected,
            "threshold={threshold},read=v{read}: {r:?}"
        );
    }
}

#[test]
fn lds_memory_and_permutation_share_ds_fifo_but_smem_remains_unordered() {
    let mut t = Trace::new(64);
    t.issue(
        0,
        0,
        AmdMemoryClass::Lds,
        vec![v(10, u64::MAX)],
        vec![],
        0,
        false,
    );
    cross_lane_issue(&mut t, 1, 20);
    cross_lane_issue(&mut t, 2, 21);
    t.wait(0, 3, None, Some(2));
    t.ins(0, 4, vec![v(10, u64::MAX)], vec![]);
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
    for zero in [false, true] {
        let mut t = Trace::new(64);
        cross_lane_issue(&mut t, 0, 20);
        t.issue(
            0,
            1,
            AmdMemoryClass::ScalarMemory,
            vec![s(4)],
            vec![],
            100,
            false,
        );
        cross_lane_issue(&mut t, 2, 21);
        t.wait(0, 3, None, Some(if zero { 0 } else { 2 }));
        t.ins(0, 4, vec![v(20, u64::MAX)], vec![]);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if zero { Verdict::Pass } else { Verdict::Fail }
        );
    }
}

#[test]
fn valu_generated_scalar_data_requires_two_valu_or_five_vmem_states() {
    for (memory, required) in [(false, 2u16), (true, 5u16)] {
        for independent in [0, required - 1, required] {
            let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
            p.instructions[0].kind = "vector ALU";
            p.instructions[1].kind = "s_nop";
            p.instructions[2].kind = if memory {
                "vector memory"
            } else {
                "vector ALU"
            };
            let mut t = Trace {
                b: GraphBuilder::new(p),
                threads: 64,
            };
            t.ins(0, 0, vec![], vec![s(4)]);
            if independent != 0 {
                delay(&mut t, 1, independent);
            }
            let consumer = if memory {
                t.issue(
                    0,
                    2,
                    AmdMemoryClass::VectorMemory,
                    vec![v(3, u64::MAX)],
                    vec![s(4)],
                    100,
                    false,
                )
            } else {
                t.ins(0, 2, vec![s(4)], vec![v(3, u64::MAX)])
            };
            let r = check_graph(&t.finish());
            assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
            assert_eq!(
                r.verdict(Property::AmdWaitReadiness),
                if independent == required {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                },
                "memory={memory},independent={independent}: {r:?}"
            );
            if independent != required {
                assert!(
                    r.amd
                        .unwrap()
                        .wait_readiness
                        .violations()
                        .iter()
                        .any(
                            |h| h.kind == AmdRegisterHazardKind::ValuScalarReadBeforeReady
                                && h.register == s(4)
                                && (h.use_event == consumer || memory)
                        )
                );
            }
        }
    }
}

#[test]
fn vcc_masks_are_visible_but_carry_selector_roles_need_no_software_bubble() {
    for index in [106, 107] {
        for mask in [false, true] {
            let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
            p.instructions[0].kind = "vector ALU";
            p.instructions[1].kind = "vector ALU";
            let mut t = Trace {
                b: GraphBuilder::new(p),
                threads: 64,
            };
            t.ins(0, 0, vec![], vec![s(index)]);
            t.b.amd_event(
                0,
                ProgramPoint(1),
                AmdEventKind::Instruction {
                    exec_mask: u64::MAX,
                    reads: vec![s(index)],
                    writes: vec![v(0, u64::MAX)],
                    scalar_mask_reads: if mask { vec![s(index)] } else { vec![] },
                },
            );
            let r = check_graph(&t.finish());
            assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
            assert_eq!(
                r.verdict(Property::AmdWaitReadiness),
                if mask { Verdict::Pass } else { Verdict::Fail }
            );
        }
    }
    let mut t = Trace::new(64);
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::Instruction {
            exec_mask: u64::MAX,
            reads: vec![s(4)],
            writes: vec![],
            scalar_mask_reads: vec![s(5)],
        },
    );
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn later_salu_write_replaces_the_pending_valu_scalar_producer() {
    let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
    p.instructions[0].kind = "vector ALU";
    p.instructions[1].kind = "scalar ALU";
    p.instructions[2].kind = "vector ALU";
    let mut t = Trace {
        b: GraphBuilder::new(p),
        threads: 64,
    };
    t.ins(0, 0, vec![], vec![s(4)]);
    t.ins(0, 1, vec![], vec![s(4)]);
    t.ins(0, 2, vec![s(4)], vec![v(0, u64::MAX)]);
    assert_eq!(
        check_graph(&t.finish()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn valu_exec_write_requires_four_states_before_mfma_even_when_mask_stays_full() {
    for independent in [0, 3, 4] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[0].kind = "vector ALU";
        p.instructions[1].kind = "s_nop";
        p.instructions[2].kind = "MFMA";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        // The concrete EXEC mask remains all ones; its VALU write still needs
        // a software bubble because hardware does not forward EXEC to MFMA.
        t.ins(0, 0, vec![], vec![s(126), s(127)]);
        if independent != 0 {
            delay(&mut t, 1, independent);
        }
        matrix(&mut t, 2, false);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if independent == 4 {
                Verdict::Pass
            } else {
                Verdict::Fail
            },
            "{r:?}"
        );
        if independent != 4 {
            assert!(
                r.amd
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(
                        |h| h.kind == AmdRegisterHazardKind::ValuScalarReadBeforeReady
                            && h.register.index == 126
                    )
            );
        }
    }
}

#[test]
fn shifted_result_overwrite_requires_one_state_for_destination_forwarding() {
    for independent in [false, true] {
        let mut p = Trace::new(64).b.graph_so_far().provenance().clone();
        p.instructions[0].kind = "shifted ALU";
        p.instructions[2].kind = "vector ALU";
        let mut t = Trace {
            b: GraphBuilder::new(p),
            threads: 64,
        };
        t.ins(0, 0, vec![v(0, 1)], vec![v(1, 1)]);
        if independent {
            t.ins(0, 1, vec![], vec![]);
        }
        let overwrite = t.ins(0, 2, vec![], vec![v(1, 1)]);
        let r = check_graph(&t.finish());
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if independent {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if !independent {
            assert!(
                r.amd
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.use_event == overwrite
                        && h.kind == AmdRegisterHazardKind::ValuDestinationBeforeReady)
            );
        }
    }
}

#[test]
fn mfma_missing_implicit_exec_reads_is_incomplete_instrumentation() {
    let mut t = Trace::new(64);
    let destinations = (2..6).map(|r| v(r, u64::MAX)).collect::<Vec<_>>();
    let sources_ab = vec![v(0, u64::MAX), v(1, u64::MAX)];
    t.ins(0, 0, sources_ab.clone(), destinations.clone());
    t.b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::MatrixIssue {
            kind: AmdMatrixKind::F32_16x16x4,
            destinations,
            sources_ab,
            accumulator: vec![],
        },
    );
    let r = check_graph(&t.finish());
    assert_eq!(r.verdict(Property::AmdTrace), Verdict::Unknown);
    assert!(
        r.amd
            .unwrap()
            .trace
            .unresolved()
            .iter()
            .any(|u| u.reason.contains("implicit EXEC"))
    );
}
