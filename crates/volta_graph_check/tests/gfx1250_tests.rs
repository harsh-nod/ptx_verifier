//! Independent event graphs. No interpreter is used to establish checker results.
use volta_graph::*;
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const KINDS: [&str; 15] = [
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
    "xcnt drain",
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
        for wave in 0..self.threads.div_ceil(32) {
            self.ins(wave, 7, vec![], vec![]);
        }
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
    for pc in [13, 14] {
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
    let mut empty_trace = Trace::new(32);
    for thread in 0..32 {
        empty_trace.b.exit(ThreadIx(thread), ProgramPoint(7));
    }
    let empty = empty_trace.b.finish(Terminal::Completed);
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
    for thread in 0..33 {
        t.b.exit(ThreadIx(thread), ProgramPoint(7));
    }
    assert_eq!(
        check_graph(&t.b.finish(Terminal::Completed)).verdict(Property::AmdTrace),
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

fn tuple(start: u16, count: usize) -> Vec<AmdRegister> {
    (0..count)
        .map(|i| v(start + i as u16, u32::MAX as u64))
        .collect()
}
impl Trace {
    fn wmma(&mut self, wave: u32, kind: AmdWmmaKind, dst: u16, ab: u16, acc: Option<u16>) {
        let destinations = tuple(dst, kind.destination_registers());
        let sources_ab = tuple(ab, 2 * kind.input_registers());
        let accumulator = acc
            .map(|a| tuple(a, kind.destination_registers()))
            .unwrap_or_default();
        let reads = sources_ab
            .iter()
            .chain(&accumulator)
            .copied()
            .chain([s(126)])
            .collect();
        self.ins(wave, 8, reads, destinations.clone());
        self.b.amd_event(
            wave,
            ProgramPoint(8),
            AmdEventKind::WmmaIssue {
                kind,
                destinations,
                sources_ab,
                accumulator,
            },
        );
    }
}
#[test]
fn wmma_coexecution_counts_intervening_valu_instructions_with_target_specific_windows() {
    for (kind, window) in [
        (AmdWmmaKind::F16_16x16x32, 4),
        (AmdWmmaKind::Bf16_16x16x32, 4),
        (AmdWmmaKind::Fp8Fp8_16x16x64, 1),
        (AmdWmmaKind::Fp8Bf8_16x16x64, 1),
        (AmdWmmaKind::Bf8Fp8_16x16x64, 1),
        (AmdWmmaKind::Bf8Bf8_16x16x64, 1),
    ] {
        for independent in [window - 1, window] {
            for (read, write) in [
                (Some(64), None),
                (None, Some(64)),
                (None, Some(0)),
                (None, Some(32)),
            ] {
                let mut t = Trace::new(32);
                t.wmma(0, kind, 64, 0, Some(32));
                for _ in 0..independent {
                    t.ins(0, 0, vec![], vec![]);
                }
                t.ins(
                    0,
                    0,
                    read.map(|r| vec![v(r, 1)]).unwrap_or_default(),
                    write.map(|r| vec![v(r, 1)]).unwrap_or_default(),
                );
                let r = check_graph(&t.finish());
                assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass, "{r:?}");
                assert_eq!(
                    r.verdict(Property::AmdWaitReadiness),
                    if independent == window {
                        Verdict::Pass
                    } else {
                        Verdict::Fail
                    },
                    "{kind:?} {independent} {read:?} {write:?}"
                );
            }
        }
    }
}
#[test]
fn scalar_nop_data_wait_and_delay_alu_do_not_replace_wmma_valu_spacing() {
    for pc in [11, 12, 4] {
        let mut t = Trace::new(32);
        t.wmma(0, AmdWmmaKind::F16_16x16x32, 64, 0, None);
        for _ in 0..8 {
            t.ins(0, pc, vec![], vec![]);
            t.b.amd_event(
                0,
                ProgramPoint(pc),
                match pc {
                    11 => AmdEventKind::Delay { cycles: 16 },
                    12 => AmdEventKind::DelayAlu {
                        instid0: AmdAluDependency::Valu(4),
                        instskip: 0,
                        instid1: None,
                    },
                    _ => AmdEventKind::WaitCounters {
                        thresholds: vec![(AmdCounter::Load, 0)],
                    },
                },
            );
        }
        t.ins(0, 0, vec![v(64, 1)], vec![]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            Verdict::Fail
        );
    }
}
#[test]
fn wmma_ab_hazards_and_accumulator_forwarding_use_different_rules() {
    for (kind, window) in [
        (AmdWmmaKind::F32_16x16x4, 1),
        (AmdWmmaKind::F16_16x16x32, 5),
        (AmdWmmaKind::Fp8Fp8_16x16x64, 2),
    ] {
        for independent in [window - 1, window] {
            let mut t = Trace::new(32);
            t.wmma(0, kind, 64, 0, None);
            for _ in 0..independent {
                t.ins(0, 0, vec![], vec![]);
            }
            t.wmma(0, kind, 128, 64, None);
            assert_eq!(
                check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
                if independent == window {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                },
                "{kind:?} {independent}"
            );
        }
        let mut t = Trace::new(32);
        t.wmma(0, kind, 64, 0, None);
        t.wmma(0, kind, 96, 0, Some(64));
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            Verdict::Pass,
            "{kind:?}"
        );
    }
}
#[test]
fn wmma_results_can_feed_vector_stores_without_importing_old_mfma_wait_states() {
    for kind in [
        AmdWmmaKind::F32_16x16x4,
        AmdWmmaKind::F16_16x16x32,
        AmdWmmaKind::Fp8Fp8_16x16x64,
    ] {
        let mut t = Trace::new(32);
        t.wmma(0, kind, 64, 0, None);
        t.issue(
            0,
            AmdMemoryClass::VectorStore,
            vec![],
            vec![v(64, u32::MAX as u64)],
            4096,
        );
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
            Verdict::Pass,
            "{kind:?}"
        );
    }
}
#[test]
fn malformed_wmma_roles_partial_waves_and_missing_implicit_exec_stay_unknown() {
    for bad in 0..5 {
        let mut t = Trace::new(if bad == 0 { 31 } else { 32 });
        let kind = AmdWmmaKind::F16_16x16x32;
        let mut destinations = tuple(64, 8);
        let sources_ab = tuple(0, 16);
        if bad == 1 {
            destinations[1] = destinations[0];
        }
        if bad == 2 {
            destinations[0].lanes = 1;
        }
        let reads = sources_ab
            .iter()
            .copied()
            .chain(if bad == 3 { None } else { Some(s(126)) })
            .collect();
        t.ins(0, 8, reads, destinations.clone());
        t.b.amd_event(
            0,
            ProgramPoint(8),
            AmdEventKind::WmmaIssue {
                kind,
                destinations,
                sources_ab,
                accumulator: if bad == 4 { tuple(32, 4) } else { vec![] },
            },
        );
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "bad {bad}"
        );
    }
}

#[test]
fn missing_effects_wrong_wave_and_progress_after_issue_cannot_forge_trace_completeness() {
    for mutation in 0..5 {
        let mut t = Trace::new(33);
        t.ins(0, 1, vec![], vec![v(10, u32::MAX as u64)]);
        let issue = t.b.amd_event(
            0,
            ProgramPoint(1),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::VectorLoad,
                counters: vec![(AmdCounter::Load, 1), (AmdCounter::X, 1)],
                destinations: vec![v(10, u32::MAX as u64)],
                held_sources: vec![],
            },
        );
        if mutation == 2 {
            t.ins(0, 0, vec![], vec![]);
        }
        let count = if mutation == 0 { 31 } else { 32 };
        for lane in 0..count {
            t.effect(
                issue,
                if mutation == 1 && lane == 0 { 32 } else { lane },
                if mutation == 3 { 0 } else { 1 },
                if mutation == 4 {
                    Space::Shared
                } else {
                    Space::Global
                },
                false,
                lane as u64 * 4,
            );
        }
        t.ins(1, 0, vec![], vec![]);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "mutation {mutation}"
        );
    }
}
#[test]
fn missing_issue_association_and_forged_counter_charge_cannot_accept() {
    for mutation in 0..3 {
        let mut t = Trace::new(1);
        t.ins(0, 1, vec![], vec![v(10, 1)]);
        let issue = t.b.amd_event(
            0,
            ProgramPoint(1),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::VectorLoad,
                counters: if mutation == 1 {
                    vec![(AmdCounter::Vm, 1)]
                } else {
                    vec![(AmdCounter::Load, 1), (AmdCounter::X, 1)]
                },
                destinations: if mutation == 2 {
                    vec![]
                } else {
                    vec![v(10, 1)]
                },
                held_sources: vec![],
            },
        );
        if mutation == 0 {
            t.b.thread_access(
                ThreadIx(0),
                ProgramPoint(1),
                MemAccess {
                    space: Space::Global,
                    mode: AccessMode::Read,
                    ordering: OrderingKind::Ordinary,
                    proxy: Proxy::Generic,
                    footprint: Footprint::Bytes { addr: 0, width: 4 },
                    role: OperandRole::Plain,
                    attributed: ThreadIx(0),
                    value: None,
                },
            );
        } else {
            t.effect(issue, 0, 1, Space::Global, false, 0);
        }
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "mutation {mutation}"
        );
    }
}
#[test]
fn split_barrier_mismatched_object_duplicate_phase_and_release_source_are_not_accepted() {
    for mutation in 0..4 {
        let mut t = Trace::new(1);
        t.signal(0, 0);
        if mutation == 0 {
            t.signal(0, 0);
        }
        t.ins(0, 6, vec![], vec![]);
        let barrier = if mutation == 1 { 2 } else { -1 };
        t.b.amd_event(
            0,
            ProgramPoint(6),
            AmdEventKind::SplitBarrierWait {
                barrier,
                generation: if mutation == 2 { 1 } else { 0 },
            },
        );
        t.b.amd_event(
            0,
            ProgramPoint(if mutation == 3 { 5 } else { 6 }),
            AmdEventKind::SplitBarrierRelease {
                barrier,
                generation: 0,
            },
        );
        let r = check_graph(&t.finish());
        assert!(
            !matches!(r.conclusion(), GraphConclusion::Verified),
            "{mutation} {r:?}"
        );
        assert_eq!(
            r.verdict(if mutation == 1 {
                Property::AmdTrace
            } else {
                Property::AmdBarrier
            }),
            if mutation == 1 {
                Verdict::Unknown
            } else {
                Verdict::Fail
            }
        );
    }
}
#[test]
fn divergent_split_barrier_wait_is_a_typed_deadlock() {
    let mut t = Trace::new(33);
    t.signal(0, 0);
    t.barrier_wait(0, 0, false);
    t.ins(1, 0, vec![], vec![]);
    t.b.exit(ThreadIx(32), ProgramPoint(7));
    let blocked = (0..32)
        .map(|thread| BlockedThread {
            thread: ThreadIx(thread),
            pc: ProgramPoint(6),
            on: BlockedOn::AmdBarrier {
                generation: 0,
                missing_waves: vec![1],
            },
        })
        .collect();
    let r = check_graph(&t.b.finish(Terminal::Stuck { blocked }));
    assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass);
    assert!(matches!(
        r.conclusion(),
        GraphConclusion::Rejected {
            deadlock: Some(_),
            ..
        }
    ));
}
#[test]
fn maximal_wait_threshold_never_retires_a_logically_overfull_stream() {
    let mut t = Trace::new(1);
    t.issue(0, AmdMemoryClass::VectorLoad, vec![v(0, 1)], vec![], 0);
    for index in 1..70 {
        t.issue(
            0,
            AmdMemoryClass::VectorLoad,
            vec![v(index, 1)],
            vec![],
            index as u64 * 4,
        );
    }
    t.wait(0, AmdCounter::Load, 63);
    t.ins(0, 0, vec![v(0, 1)], vec![]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
        Verdict::Fail
    );
}

#[test]
fn completed_prefix_and_progress_after_endpgm_cannot_claim_a_complete_native_trace() {
    for after_end in [false, true] {
        let mut t = Trace::new(1);
        if after_end {
            t.ins(0, 7, vec![], vec![]);
        }
        t.ins(0, 0, vec![], vec![]);
        t.b.exit(ThreadIx(0), ProgramPoint(7));
        assert_eq!(
            check_graph(&t.b.finish(Terminal::Completed)).verdict(Property::AmdTrace),
            Verdict::Unknown
        );
    }
}
