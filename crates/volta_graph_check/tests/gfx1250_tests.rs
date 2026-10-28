//! Independent event graphs. No interpreter is used to establish checker results.
use volta_graph::*;
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const KINDS: [&str; 14] = [
    "vector ALU",
    "vector memory",
    "scalar memory",
    "LDS",
    "wait",
    "barrier signal",
    "barrier wait",
    "s_endpgm",
    "WMMA",
    "async memory",
    "tensor memory",
    "s_nop",
    "s_delay_alu",
    "branch",
];
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
        lanes: 0,
    }
}
struct Trace {
    b: GraphBuilder,
    threads: u32,
}
impl Trace {
    fn new(threads: u32) -> Self {
        Self::with_assumptions(threads, vec![Assumption::UnclusteredWorkgroup])
    }
    fn with_assumptions(threads: u32, assumptions: Vec<Assumption>) -> Self {
        Self {
            threads,
            b: GraphBuilder::new(Provenance {
                kernel: "independent_gfx1250_graph".into(),
                block_dim: (threads, 1, 1),
                grid_dim: (1, 1, 1),
                targets: vec!["gfx1250".into()],
                assumptions,
                instructions: KINDS
                    .iter()
                    .map(|&kind| InstructionInfo { kind, span: None })
                    .collect(),
            }),
        }
    }
    fn mask(&self, wave: u32) -> u64 {
        (1u64 << (self.threads - wave * 32).min(32)) - 1
    }
    fn ins(
        &mut self,
        wave: u32,
        pc: u32,
        reads: Vec<AmdRegister>,
        writes: Vec<AmdRegister>,
    ) -> EventId {
        self.ins_mask(wave, pc, self.mask(wave), reads, writes)
    }
    fn ins_mask(
        &mut self,
        wave: u32,
        pc: u32,
        mask: u64,
        reads: Vec<AmdRegister>,
        writes: Vec<AmdRegister>,
    ) -> EventId {
        self.b.amd_event(
            wave,
            ProgramPoint(pc),
            AmdEventKind::Instruction {
                exec_mask: mask,
                reads,
                writes,
                scalar_mask_reads: vec![],
            },
        )
    }
    fn issue(
        &mut self,
        wave: u32,
        class: AmdMemoryClass,
        destinations: Vec<AmdRegister>,
        held_sources: Vec<AmdRegister>,
        addr: u64,
    ) -> EventId {
        let (pc, counters, space, write) = match class {
            AmdMemoryClass::VectorLoad => (
                1,
                vec![(AmdCounter::Load, 1), (AmdCounter::X, 1)],
                Space::Global,
                false,
            ),
            AmdMemoryClass::VectorStore => (
                1,
                vec![(AmdCounter::Store, 1), (AmdCounter::X, 1)],
                Space::Global,
                true,
            ),
            AmdMemoryClass::ScalarLoad => (
                2,
                vec![(AmdCounter::Km, 1), (AmdCounter::X, 1)],
                Space::Global,
                false,
            ),
            AmdMemoryClass::Ds | AmdMemoryClass::CrossLane => (
                3,
                vec![(AmdCounter::Ds, 1)],
                Space::Shared,
                destinations.is_empty(),
            ),
            AmdMemoryClass::TensorLoadToLds | AmdMemoryClass::TensorStoreFromLds => (
                10,
                vec![(AmdCounter::Tensor, 1)],
                Space::Global,
                class == AmdMemoryClass::TensorStoreFromLds,
            ),
            _ => panic!("test class needs a native profile"),
        };
        self.ins(wave, pc, held_sources.clone(), destinations.clone());
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
        if class != AmdMemoryClass::CrossLane {
            let scalar = matches!(
                class,
                AmdMemoryClass::ScalarLoad
                    | AmdMemoryClass::TensorLoadToLds
                    | AmdMemoryClass::TensorStoreFromLds
            );
            let count = if scalar {
                1
            } else {
                self.mask(wave).count_ones()
            };
            for lane in 0..count {
                self.effect(
                    issue,
                    wave * 32 + lane,
                    pc,
                    space,
                    write,
                    addr + lane as u64 * 4,
                );
            }
            if matches!(
                class,
                AmdMemoryClass::TensorLoadToLds | AmdMemoryClass::TensorStoreFromLds
            ) {
                self.effect(issue, wave * 32, pc, Space::Shared, !write, 0);
            }
        }
        issue
    }
    fn effect(
        &mut self,
        issue: EventId,
        thread: u32,
        pc: u32,
        space: Space,
        write: bool,
        addr: u64,
    ) {
        let value = write.then(|| self.b.value(StoredValue::Opaque));
        let effect = self.b.thread_access(
            ThreadIx(thread),
            ProgramPoint(pc),
            MemAccess {
                space,
                mode: if write {
                    AccessMode::Write
                } else {
                    AccessMode::Read
                },
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes { addr, width: 4 },
                role: OperandRole::Plain,
                attributed: ThreadIx(thread),
                value,
            },
        );
        self.b.amd_memory_effect(issue, effect);
    }
    fn wait(&mut self, wave: u32, counter: AmdCounter, threshold: u16) {
        self.ins(wave, 4, vec![], vec![]);
        self.b.amd_event(
            wave,
            ProgramPoint(4),
            AmdEventKind::WaitCounters {
                thresholds: vec![(counter, threshold)],
            },
        );
    }
    fn signal(&mut self, wave: u32, generation: u32) {
        self.ins(wave, 5, vec![], vec![]);
        self.b.amd_event(
            wave,
            ProgramPoint(5),
            AmdEventKind::SplitBarrierSignal {
                barrier: -1,
                generation,
                exec_mask: self.mask(wave),
            },
        );
    }
    fn barrier_wait(&mut self, wave: u32, generation: u32, release: bool) {
        self.ins(wave, 6, vec![], vec![]);
        self.b.amd_event(
            wave,
            ProgramPoint(6),
            AmdEventKind::SplitBarrierWait {
                barrier: -1,
                generation,
            },
        );
        if release {
            self.b.amd_event(
                wave,
                ProgramPoint(6),
                AmdEventKind::SplitBarrierRelease {
                    barrier: -1,
                    generation,
                },
            );
        }
    }
    fn finish(mut self) -> EventGraph {
        for t in 0..self.threads {
            self.b.exit(ThreadIx(t), ProgramPoint(7));
        }
        self.b.finish(Terminal::Completed)
    }
}

#[test]
fn wave32_geometry_covers_all_tail_sizes_without_wave64_aliasing() {
    for threads in [1, 31, 32, 33, 63, 64, 65, 96] {
        let mut t = Trace::new(threads);
        for wave in 0..threads.div_ceil(32) {
            t.ins(wave, 0, vec![], vec![]);
        }
        assert!(
            matches!(
                check_graph(&t.finish()).conclusion(),
                GraphConclusion::Verified
            ),
            "{threads}"
        );
    }
}
#[test]
fn separate_data_counters_and_thresholds_control_register_readiness() {
    for (class, counter, wrong, reg) in [
        (
            AmdMemoryClass::VectorLoad,
            AmdCounter::Load,
            AmdCounter::Store,
            v(900, 1),
        ),
        (
            AmdMemoryClass::ScalarLoad,
            AmdCounter::Km,
            AmdCounter::Ds,
            s(80),
        ),
        (
            AmdMemoryClass::Ds,
            AmdCounter::Ds,
            AmdCounter::Km,
            v(901, 1),
        ),
        (
            AmdMemoryClass::CrossLane,
            AmdCounter::Ds,
            AmdCounter::Load,
            v(902, 1),
        ),
    ] {
        for (wait, threshold, expected) in [
            (None, 0, Verdict::Fail),
            (Some(wrong), 0, Verdict::Fail),
            (Some(counter), 1, Verdict::Fail),
            (Some(counter), 0, Verdict::Pass),
            (Some(AmdCounter::X), 0, Verdict::Fail),
        ] {
            let mut t = Trace::new(1);
            t.issue(0, class, vec![reg], vec![], 0);
            if let Some(wait) = wait {
                t.wait(0, wait, threshold);
            }
            t.ins(0, 0, vec![reg], vec![]);
            let r = check_graph(&t.finish());
            assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{class:?}");
            assert_eq!(
                r.verdict(Property::AmdWaitReadiness),
                expected,
                "{class:?} {wait:?} {threshold}"
            );
        }
    }
}
#[test]
fn partial_fifo_wait_retires_only_the_guaranteed_prefix_and_scalar_is_unordered() {
    for class in [
        AmdMemoryClass::VectorLoad,
        AmdMemoryClass::Ds,
        AmdMemoryClass::ScalarLoad,
    ] {
        for read_first in [true, false] {
            let mut t = Trace::new(1);
            let scalar = class == AmdMemoryClass::ScalarLoad;
            let reg = |index| if scalar { s(index) } else { v(index, 1) };
            t.issue(0, class, vec![reg(10)], vec![], 0);
            t.issue(0, class, vec![reg(11)], vec![], 4);
            t.wait(
                0,
                if scalar {
                    AmdCounter::Km
                } else if class == AmdMemoryClass::Ds {
                    AmdCounter::Ds
                } else {
                    AmdCounter::Load
                },
                1,
            );
            t.ins(0, 0, vec![reg(if read_first { 10 } else { 11 })], vec![]);
            assert_eq!(
                check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
                if read_first && !scalar {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                }
            );
        }
    }
}
#[test]
fn replay_lease_blocks_source_overwrite_but_xcnt_wait_does_not_complete_data() {
    for counter in [None, Some(AmdCounter::X), Some(AmdCounter::Load)] {
        let mut t = Trace::new(1);
        t.issue(
            0,
            AmdMemoryClass::VectorLoad,
            vec![v(1, 1)],
            vec![s(2), s(3), s(126)],
            0,
        );
        if let Some(counter) = counter {
            t.wait(0, counter, 0);
        }
        t.ins(0, 0, vec![], vec![s(2)]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            if counter.is_some() {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}
#[test]
fn replay_implicit_drain_and_group_switch_do_not_fabricate_data_completion() {
    for pc in [13, 7] {
        let mut t = Trace::new(1);
        t.issue(0, AmdMemoryClass::VectorLoad, vec![v(1, 1)], vec![s(2)], 0);
        t.ins(0, pc, vec![], vec![]);
        t.ins(0, 0, vec![v(1, 1)], vec![s(2)]);
        let r = check_graph(&t.finish());
        let hazards = match r.amd.as_ref().unwrap().wait_readiness {
            ref result => format!("{result:?}"),
        };
        assert_eq!(r.verdict(Property::AmdWaitReadiness), Verdict::Fail);
        assert!(!hazards.contains("SourceReuse"));
    }
}
#[test]
fn split_barrier_publishes_only_completed_effects_and_needs_all_live_waves() {
    for completed in [false, true] {
        for signalled in [false, true] {
            let mut t = Trace::new(33);
            t.issue(0, AmdMemoryClass::Ds, vec![], vec![], 0);
            if completed {
                t.wait(0, AmdCounter::Ds, 0);
            }
            if signalled {
                t.signal(0, 0);
            }
            t.signal(1, 0);
            t.barrier_wait(1, 0, true);
            t.issue(1, AmdMemoryClass::Ds, vec![v(2, 1)], vec![], 0);
            let r = check_graph(&t.finish());
            assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass);
            assert_eq!(
                r.verdict(Property::AmdBarrier),
                if signalled {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                }
            );
            if signalled {
                assert_eq!(
                    r.verdict(Property::AmdMemoryConflict),
                    if completed {
                        Verdict::Pass
                    } else {
                        Verdict::Fail
                    },
                    "{r:?}"
                );
            }
        }
    }
}
#[test]
fn split_signal_is_nonblocking_and_wait_is_blocking() {
    let mut valid = Trace::new(1);
    valid.signal(0, 0);
    valid.ins(0, 0, vec![], vec![]);
    valid.barrier_wait(0, 0, true);
    valid.signal(0, 1);
    valid.barrier_wait(0, 1, true);
    assert!(matches!(
        check_graph(&valid.finish()).conclusion(),
        GraphConclusion::Verified
    ));
    let mut blocked = Trace::new(1);
    blocked.signal(0, 0);
    blocked.barrier_wait(0, 0, false);
    blocked.ins(0, 0, vec![], vec![]);
    assert_eq!(
        check_graph(&blocked.finish()).verdict(Property::AmdBarrier),
        Verdict::Fail
    );
}
#[test]
fn tensor_buffer_borrow_and_completion_are_separate_from_other_wait_classes() {
    for counter in [AmdCounter::Tensor, AmdCounter::Load, AmdCounter::Ds] {
        let mut t = Trace::new(1);
        t.issue(
            0,
            AmdMemoryClass::TensorStoreFromLds,
            vec![],
            vec![s(4)],
            64,
        );
        t.wait(0, counter, 0);
        t.ins(0, 0, vec![], vec![s(4)]);
        t.issue(0, AmdMemoryClass::Ds, vec![], vec![], 0);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass);
        assert_eq!(
            r.verdict(Property::AmdWaitReadiness),
            if counter == AmdCounter::Tensor {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        assert_eq!(
            r.verdict(Property::AmdMemoryConflict),
            if counter == AmdCounter::Tensor {
                Verdict::Pass
            } else {
                Verdict::Fail
            },
            "{r:?}"
        );
    }
}
#[test]
fn empty_incomplete_and_replay_disabled_envelopes_never_accept() {
    let empty = Trace::new(32).finish();
    assert_eq!(
        check_graph(&empty).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
    for assumptions in [
        vec![],
        vec![
            Assumption::UnclusteredWorkgroup,
            Assumption::XnackReplayDisabled,
        ],
    ] {
        let mut t = Trace::with_assumptions(1, assumptions);
        t.ins(0, 0, vec![], vec![]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown
        );
    }
    let mut t = Trace::new(33);
    t.ins(0, 0, vec![], vec![]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}
#[test]
fn invalid_masks_register_namespaces_and_missing_semantic_records_fail_closed() {
    for (mask, reg, pc) in [
        (1u64 << 32, v(0, 1), 0),
        (1, v(1024, 1), 0),
        (1, v(0, 2), 0),
        (1, s(107), 0),
        (
            1,
            AmdRegister {
                file: AmdRegisterFile::Accumulator,
                index: 0,
                lanes: 1,
            },
            0,
        ),
        (1, v(0, 1), 1),
        (1, v(0, 1), 10),
    ] {
        let mut t = Trace::new(1);
        t.ins_mask(0, pc, mask, vec![reg], vec![]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "{mask} {reg:?} {pc}"
        );
    }
}
#[test]
fn semantic_records_cannot_borrow_an_alu_pc_or_wrong_memory_class() {
    for pc in [0, 2] {
        let mut t = Trace::new(1);
        t.ins(0, pc, vec![], vec![v(0, 1)]);
        let issue = t.b.amd_event(
            0,
            ProgramPoint(pc),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::VectorLoad,
                counters: vec![(AmdCounter::Load, 1), (AmdCounter::X, 1)],
                destinations: vec![v(0, 1)],
                held_sources: vec![],
            },
        );
        t.effect(issue, 0, pc, Space::Global, false, 0);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown
        );
    }
}
#[test]
fn malformed_thresholds_and_unknown_tensor_width_do_not_establish_acceptance() {
    for (counter, threshold, expected) in [
        (AmdCounter::Vm, 0, Verdict::Unknown),
        (AmdCounter::Load, 64, Verdict::Unknown),
        (AmdCounter::Km, 32, Verdict::Unknown),
        (AmdCounter::Tensor, 1, Verdict::Pass),
    ] {
        let mut t = Trace::new(1);
        t.wait(0, counter, threshold);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), expected);
        assert_eq!(r.verdict(Property::AmdWaitReadiness), Verdict::Unknown);
    }
}
