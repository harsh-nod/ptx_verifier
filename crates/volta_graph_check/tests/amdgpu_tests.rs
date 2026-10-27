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
            AmdMemoryClass::VectorMemory => vec![(AmdCounter::Vm, 1)],
            AmdMemoryClass::Flat => vec![(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)],
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
