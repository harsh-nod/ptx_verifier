//! Independent contracts for selected raw CDNA4 buffer-to-LDS DMA.
use volta_graph::*;
use volta_graph_check::amdgpu::AmdRegisterHazardKind;
use volta_graph_check::domain::ConflictKind;
use volta_graph_check::{Property, Verdict, check_graph};

fn scalar(index: u16) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Scalar,
        index,
        lanes: u64::MAX,
    }
}
fn vector(index: u16, lanes: u64) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Vector,
        index,
        lanes,
    }
}
fn width(class: AmdMemoryClass) -> u64 {
    match class {
        AmdMemoryClass::BufferLoadToLds32 => 4,
        AmdMemoryClass::BufferLoadToLds128 => 16,
        _ => panic!("DMA width"),
    }
}
fn pc(kind: &'static str) -> ProgramPoint {
    ProgramPoint(match kind {
        "scalar ALU" => 0,
        "vector memory" => 1,
        "wait" => 2,
        "s_nop" => 3,
        "LDS" => 4,
        "scalar memory" => 5,
        "vector ALU" => 6,
        "barrier" => 7,
        _ => panic!("test provenance"),
    })
}
#[derive(Clone)]
struct Effect {
    thread: ThreadIx,
    space: Space,
    mode: AccessMode,
    addr: u64,
    bytes: u32,
    scope: AmdMemoryScope,
    role: OperandRole,
}
struct Dma {
    class: AmdMemoryClass,
    mask: u64,
    reads: Vec<AmdRegister>,
    writes: Vec<AmdRegister>,
    destinations: Vec<AmdRegister>,
    held_sources: Vec<AmdRegister>,
    counters: Vec<(AmdCounter, u16)>,
    effects: Vec<Effect>,
}
impl Dma {
    fn new(wave: u32, class: AmdMemoryClass, mask: u64, m0: u64) -> Self {
        let bytes = width(class);
        let mut reads = (4..8).map(scalar).collect::<Vec<_>>();
        reads.extend([vector(8, mask), scalar(124)]);
        let mut effects = Vec::new();
        for lane in 0..64 {
            if mask & (1u64 << lane) == 0 {
                continue;
            }
            for component in 0..bytes / 4 {
                for (space, mode, addr) in [
                    (
                        Space::Global,
                        AccessMode::Read,
                        0x10000 + u64::from(lane) * bytes + component * 4,
                    ),
                    (
                        Space::Shared,
                        AccessMode::Write,
                        m0 + u64::from(lane) * bytes + component * 4,
                    ),
                ] {
                    effects.push(Effect {
                        thread: ThreadIx(wave * 64 + lane),
                        space,
                        mode,
                        addr,
                        bytes: 4,
                        scope: AmdMemoryScope::Unspecified,
                        role: OperandRole::Plain,
                    });
                }
            }
        }
        Self {
            class,
            mask,
            reads,
            writes: vec![],
            destinations: vec![],
            held_sources: vec![],
            counters: vec![(AmdCounter::Vm, 1)],
            effects,
        }
    }
}
struct Trace {
    b: GraphBuilder,
    threads: u32,
}
impl Trace {
    fn new(threads: u32) -> Self {
        Self::target(threads, "gfx950", Some(163840))
    }
    fn target(threads: u32, target: &str, limit: Option<u64>) -> Self {
        let mut assumptions = vec![];
        if let Some(limit) = limit {
            assumptions.push(Assumption::ConfiguredLdsBytes(limit));
        }
        Self {
            threads,
            b: GraphBuilder::new(Provenance {
                kernel: "dma_contract".into(),
                block_dim: (threads, 1, 1),
                grid_dim: (1, 1, 1),
                workgroup_id: (0, 0, 0),
                targets: vec![target.into()],
                assumptions,
                instructions: [
                    "scalar ALU",
                    "vector memory",
                    "wait",
                    "s_nop",
                    "LDS",
                    "scalar memory",
                    "vector ALU",
                    "barrier",
                ]
                .map(|kind| InstructionInfo { kind, span: None })
                .to_vec(),
            }),
        }
    }
    fn ins(
        &mut self,
        wave: u32,
        kind: &'static str,
        mask: u64,
        reads: Vec<AmdRegister>,
        writes: Vec<AmdRegister>,
    ) -> EventId {
        self.b.amd_event(
            wave,
            pc(kind),
            AmdEventKind::Instruction {
                exec_mask: mask,
                reads,
                writes,
                scalar_mask_reads: vec![],
            },
        )
    }
    fn nop(&mut self, wave: u32) {
        self.ins(wave, "s_nop", 1, vec![], vec![]);
        self.b
            .amd_event(wave, pc("s_nop"), AmdEventKind::Delay { cycles: 1 });
    }
    fn init(&mut self, wave: u32, padding: bool) -> EventId {
        let event = self.ins(wave, "scalar ALU", 1, vec![], vec![scalar(124)]);
        if padding {
            self.nop(wave);
        }
        event
    }
    fn effect(&mut self, issue: EventId, kind: &'static str, effect: Effect) {
        let value = if effect.mode == AccessMode::Write {
            Some(self.b.value(StoredValue::Opaque))
        } else {
            None
        };
        let event = self.b.thread_access(
            effect.thread,
            pc(kind),
            MemAccess {
                space: effect.space,
                mode: effect.mode,
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes {
                    addr: effect.addr,
                    width: effect.bytes,
                },
                role: effect.role,
                attributed: effect.thread,
                value,
            },
        );
        self.b.amd_memory_effect_scoped(issue, event, effect.scope);
    }
    fn dma(&mut self, wave: u32, dma: Dma) -> (EventId, EventId) {
        let instruction = self.ins(wave, "vector memory", dma.mask, dma.reads, dma.writes);
        let issue = self.b.amd_event(
            wave,
            pc("vector memory"),
            AmdEventKind::MemoryIssue {
                class: dma.class,
                counters: dma.counters,
                destinations: dma.destinations,
                held_sources: dma.held_sources,
            },
        );
        for effect in dma.effects {
            self.effect(issue, "vector memory", effect);
        }
        (instruction, issue)
    }
    fn load(&mut self, class: AmdMemoryClass, destination: AmdRegister) -> EventId {
        let kind = if class == AmdMemoryClass::ScalarMemory {
            "scalar memory"
        } else {
            "vector memory"
        };
        self.ins(0, kind, 1, vec![], vec![destination]);
        let counters = match class {
            AmdMemoryClass::Flat => vec![(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)],
            AmdMemoryClass::ScalarMemory => vec![(AmdCounter::Lgkm, 1)],
            _ => vec![(AmdCounter::Vm, 1)],
        };
        let issue = self.b.amd_event(
            0,
            pc(kind),
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations: vec![destination],
                held_sources: vec![],
            },
        );
        self.effect(
            issue,
            kind,
            Effect {
                thread: ThreadIx(0),
                space: Space::Global,
                mode: AccessMode::Read,
                addr: 0x30000,
                bytes: 4,
                scope: AmdMemoryScope::Unspecified,
                role: OperandRole::Plain,
            },
        );
        issue
    }
    fn wait(&mut self, wave: u32, vmcnt: Option<u16>, lgkmcnt: Option<u16>, expcnt: Option<u16>) {
        self.ins(wave, "wait", 1, vec![], vec![]);
        self.b.amd_event(
            wave,
            pc("wait"),
            AmdEventKind::Wait {
                vmcnt,
                lgkmcnt,
                expcnt,
            },
        );
    }
    fn read(&mut self, wave: u32, addr: u64) -> EventId {
        self.ins(wave, "LDS", 1, vec![], vec![vector(20, 1)]);
        let issue = self.b.amd_event(
            wave,
            pc("LDS"),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::Lds,
                counters: vec![(AmdCounter::Lgkm, 1)],
                destinations: vec![vector(20, 1)],
                held_sources: vec![],
            },
        );
        self.effect(
            issue,
            "LDS",
            Effect {
                thread: ThreadIx(wave * 64),
                space: Space::Shared,
                mode: AccessMode::Read,
                addr,
                bytes: 4,
                scope: AmdMemoryScope::Unspecified,
                role: OperandRole::Plain,
            },
        );
        issue
    }
    fn rendezvous(&mut self) {
        for wave in 0..2 {
            self.ins(wave, "barrier", u64::MAX, vec![], vec![]);
            self.b.amd_event(
                wave,
                pc("barrier"),
                AmdEventKind::BarrierArrive {
                    generation: 0,
                    exec_mask: u64::MAX,
                },
            );
        }
        for wave in 0..2 {
            self.b.amd_event(
                wave,
                pc("barrier"),
                AmdEventKind::BarrierRelease { generation: 0 },
            );
        }
    }
    fn finish(mut self) -> EventGraph {
        for lane in 0..self.threads {
            self.b.exit(ThreadIx(lane), pc("scalar ALU"));
        }
        self.b.finish(Terminal::Completed)
    }
}
const DMA32: AmdMemoryClass = AmdMemoryClass::BufferLoadToLds32;
const DMA128: AmdMemoryClass = AmdMemoryClass::BufferLoadToLds128;

#[test]
fn complete_both_widths_sparse_physical_lanes_and_large_lds_offsets_are_valid() {
    for class in [DMA32, DMA128] {
        for mask in [1, 3, 1u64 << 63, u64::MAX] {
            let mut t = Trace::new(128);
            for wave in 0..2 {
                t.init(wave, true);
                t.dma(
                    wave,
                    Dma::new(wave, class, mask, if wave == 0 { 65532 } else { 32768 }),
                );
                t.wait(wave, Some(0), None, None);
            }
            let r = check_graph(&t.finish());
            assert_eq!(
                r.verdict(Property::AmdTrace),
                Verdict::Pass,
                "{class:?}/{mask:x}: {r:#?}"
            );
            assert_eq!(r.verdict(Property::AmdWaitReadiness), Verdict::Pass);
        }
    }
    assert_eq!(AmdMemoryClass::FlatLdsStore as usize, 20);
    assert_eq!(DMA32 as usize, 21);
    assert_eq!(DMA128 as usize, 22);
}

#[test]
fn forged_target_counter_destination_and_register_roles_refuse() {
    for target in ["gfx942", "gfx1250"] {
        let mut t = Trace::target(64, target, Some(163840));
        t.init(0, true);
        t.dma(0, Dma::new(0, DMA32, 1, 0));
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown
        );
    }
    for fault in 0..12 {
        let mut t = Trace::new(64);
        t.init(0, true);
        let mut d = Dma::new(0, DMA128, 3, 0);
        match fault {
            0 => {
                d.counters = vec![(AmdCounter::Lgkm, 1)];
            }
            1 => {
                d.counters.push((AmdCounter::Vm, 1));
            }
            2 => {
                d.destinations.push(vector(10, 3));
                d.writes.push(vector(10, 3));
            }
            3 => {
                d.held_sources.push(d.reads[0]);
            }
            4 => {
                d.reads.pop();
            }
            5 => {
                d.reads[0] = scalar(5);
            }
            6 => {
                d.reads[4] = vector(8, 1);
            }
            7 => {
                d.reads[5].lanes = 1;
            }
            8 => {
                d.reads.push(scalar(9));
            }
            9 => {
                d.reads[4].file = AmdRegisterFile::Accumulator;
            }
            10 => {
                d.mask = 0;
            }
            11 => {
                d.class = AmdMemoryClass::VectorMemory;
            }
            _ => unreachable!(),
        }
        t.dma(0, d);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "fault {fault}"
        );
    }
    let mut t = Trace::new(64);
    t.dma(0, Dma::new(0, DMA32, 1, 0));
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdTrace),
        Verdict::Unknown
    );
}

#[test]
fn every_active_lane_component_direction_and_payload_pair_is_required() {
    for fault in 0..14 {
        let mut t = Trace::new(128);
        t.init(0, true);
        t.init(1, true);
        let mut d = Dma::new(0, DMA128, 3, 0);
        match fault {
            0 => {
                d.effects.pop();
            }
            1 => {
                d.effects[2] = d.effects[0].clone();
            }
            2 => {
                d.effects[0].mode = AccessMode::Write;
            }
            3 => {
                d.effects[1].space = Space::Global;
            }
            4 => {
                d.effects[0].bytes = 8;
            }
            5 => {
                d.effects[1].thread = ThreadIx(2);
            }
            6 => {
                d.effects[1].thread = ThreadIx(64);
            }
            7 => {
                d.effects[0].scope = AmdMemoryScope::Workgroup;
            }
            8 => {
                d.effects[1].addr = 2;
            }
            9 => {
                d.effects[1].addr = 4;
            }
            10 => {
                d.effects[9].addr += 4;
            }
            11 => {
                d.effects[0].addr = (1u64 << 48) - 4;
            }
            12 => {
                d.effects[0].role = OperandRole::Accumulator;
            }
            13 => {
                for effect in &mut d.effects {
                    if effect.thread == ThreadIx(1) && effect.space == Space::Shared {
                        effect.addr += 4;
                    }
                }
            }
            _ => unreachable!(),
        }
        t.dma(0, d);
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "fault {fault}"
        );
    }
}

#[test]
fn whole_dma_transfer_requires_declared_lds_extent_and_a_single_subobject() {
    for limit in [None, Some(0), Some(15), Some(163841)] {
        let mut t = Trace::target(64, "gfx950", limit);
        t.init(0, true);
        t.dma(0, Dma::new(0, DMA128, 1, 0));
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown,
            "{limit:?}"
        );
    }
    for base in [65536, 2] {
        let mut t = Trace::new(64);
        t.init(0, true);
        t.dma(0, Dma::new(0, DMA32, 1, base));
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            Verdict::Unknown
        );
    }
    for split in [12, 16] {
        let mut t = Trace::new(64);
        t.b.set_shared_allocation_layout(vec![
            SharedAllocation {
                name: "a".into(),
                offset: 0,
                size: split,
            },
            SharedAllocation {
                name: "b".into(),
                offset: split,
                size: 32,
            },
        ]);
        t.init(0, true);
        t.dma(0, Dma::new(0, DMA128, 1, 0));
        assert_eq!(
            check_graph(&t.finish()).verdict(Property::AmdTrace),
            if split == 16 {
                Verdict::Pass
            } else {
                Verdict::Unknown
            }
        );
    }
}

#[test]
fn salu_m0_producer_requires_one_independent_state_even_at_empty_exec() {
    for padding in [false, true] {
        let mut t = Trace::new(64);
        let producer = t.ins(0, "scalar ALU", 0, vec![], vec![scalar(124)]);
        if padding {
            t.nop(0);
        }
        let (instruction, _) = t.dma(0, Dma::new(0, DMA32, 1, 0));
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        let hazards = amd.wait_readiness.violations();
        assert_eq!(hazards.len(), usize::from(!padding));
        if !padding {
            assert_eq!(hazards[0].issue, producer);
            assert_eq!(hazards[0].use_event, instruction);
            assert_eq!(
                hazards[0].kind,
                AmdRegisterHazardKind::SaluM0ReadBeforeReady
            );
        }
    }
}

#[test]
fn mixed_vm_partial_wait_keeps_actual_ordinary_destination_in_both_orders() {
    for dma_first in [false, true] {
        let mut t = Trace::new(64);
        t.init(0, true);
        if dma_first {
            t.dma(0, Dma::new(0, DMA32, 1, 0));
        }
        let ordinary = t.load(AmdMemoryClass::VectorMemory, vector(10, 1));
        if !dma_first {
            t.dma(0, Dma::new(0, DMA32, 1, 0));
        }
        t.wait(0, Some(1), None, None);
        let use_event = t.ins(0, "vector ALU", 1, vec![vector(10, 1)], vec![]);
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        let hazards = amd.wait_readiness.violations();
        assert!(hazards.iter().any(|h| h.issue == ordinary
            && h.use_event == use_event
            && h.register == vector(10, 1)
            && h.kind == AmdRegisterHazardKind::ReadBeforeReady));
    }
    let mut t = Trace::new(64);
    t.init(0, true);
    let a = t.load(AmdMemoryClass::VectorMemory, vector(10, 1));
    let b = t.load(AmdMemoryClass::VectorMemory, vector(11, 1));
    t.dma(0, Dma::new(0, DMA128, 1, 0));
    t.wait(0, Some(2), None, None);
    let use_event = t.ins(
        0,
        "vector ALU",
        1,
        vec![vector(10, 1), vector(11, 1)],
        vec![],
    );
    let r = check_graph(&t.finish());
    let amd = r.amd.unwrap();
    assert_eq!(amd.trace.verdict(), Verdict::Pass);
    for issue in [a, b] {
        assert!(
            amd.wait_readiness
                .violations()
                .iter()
                .any(|h| h.issue == issue && h.use_event == use_event)
        );
    }
}

#[test]
fn ordinary_only_vm_fifo_is_retained_and_zero_wait_drains_dma_mixtures() {
    for dma in [false, true] {
        let mut t = Trace::new(64);
        t.init(0, true);
        t.load(AmdMemoryClass::VectorMemory, vector(10, 1));
        let last = t.load(AmdMemoryClass::VectorMemory, vector(11, 1));
        if dma {
            t.dma(0, Dma::new(0, DMA32, 1, 0));
        }
        t.wait(0, Some(if dma { 0 } else { 1 }), None, None);
        let use_event = t.ins(
            0,
            "vector ALU",
            1,
            vec![vector(10, 1), vector(11, 1)],
            vec![],
        );
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        assert_eq!(amd.wait_readiness.violations().len(), usize::from(!dma));
        if !dma {
            assert_eq!(amd.wait_readiness.violations()[0].issue, last);
            assert_eq!(amd.wait_readiness.violations()[0].use_event, use_event);
        }
    }
}

#[test]
fn partial_dma_width_mixture_and_wrong_counters_cannot_publish_lds() {
    for wait in [0, 1, 2, 3] {
        let mut t = Trace::new(64);
        t.init(0, true);
        t.dma(0, Dma::new(0, DMA32, 1, 0));
        t.dma(0, Dma::new(0, DMA128, 1, 1024));
        match wait {
            0 => t.wait(0, Some(0), None, None),
            1 => t.wait(0, Some(1), None, None),
            2 => t.wait(0, None, Some(0), None),
            3 => t.wait(0, None, None, Some(0)),
            _ => unreachable!(),
        }
        t.read(0, 0);
        t.wait(0, None, Some(0), None);
        t.read(0, 1024);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass);
        assert_eq!(
            r.verdict(Property::AmdMemoryConflict),
            if wait == 0 {
                Verdict::Pass
            } else {
                Verdict::Fail
            },
            "wait {wait}: {r:#?}"
        );
        if wait != 0 {
            let conflicts = r.amd.as_ref().unwrap().memory_conflict.violations();
            for addr in [0, 1024] {
                assert!(conflicts.iter().any(|c| c.kind == ConflictKind::WriteRead
                    && c.location.space == Space::Shared
                    && c.location.addr == addr));
            }
        }
    }
}

#[test]
fn flat_remaining_charges_participate_in_the_same_vm_inventory() {
    for order in 0..3 {
        let mut t = Trace::new(64);
        t.init(0, true);
        t.dma(0, Dma::new(0, DMA32, 1, 0));
        let flat = t.load(AmdMemoryClass::Flat, vector(10, 1));
        match order {
            0 => {
                t.wait(0, None, Some(0), None);
                t.wait(0, Some(1), None, None);
            }
            1 => t.wait(0, Some(0), None, None),
            2 => {
                t.wait(0, Some(0), None, None);
                t.wait(0, None, Some(0), None);
            }
            _ => unreachable!(),
        }
        let use_event = t.ins(0, "vector ALU", 1, vec![vector(10, 1)], vec![]);
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        assert_eq!(
            amd.wait_readiness.verdict(),
            if order == 2 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if order != 2 {
            assert!(
                amd.wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.issue == flat && h.use_event == use_event)
            );
        }
    }
}

#[test]
fn all_ones_wait_does_not_complete_overfull_mixed_history() {
    for threshold in [63, 62, 0] {
        let mut t = Trace::new(64);
        t.init(0, true);
        let first = t.load(AmdMemoryClass::VectorMemory, vector(10, 1));
        for index in 11..75 {
            t.load(AmdMemoryClass::VectorMemory, vector(index, 1));
        }
        t.dma(0, Dma::new(0, DMA32, 1, 0));
        t.wait(0, Some(threshold), None, None);
        let use_event = t.ins(0, "vector ALU", 1, vec![vector(10, 1)], vec![]);
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        assert_eq!(
            amd.wait_readiness.verdict(),
            if threshold == 0 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if threshold != 0 {
            assert!(
                amd.wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.issue == first && h.use_event == use_event)
            );
        }
    }
}

#[test]
fn crosswave_barrier_only_publishes_completed_dma_memory() {
    for vm in [0, 1] {
        let mut t = Trace::new(128);
        t.init(0, true);
        t.init(1, true);
        t.load(AmdMemoryClass::VectorMemory, vector(10, 1));
        t.dma(0, Dma::new(0, DMA128, 1, 0));
        t.wait(0, Some(vm), None, None);
        t.rendezvous();
        t.read(1, 0);
        let r = check_graph(&t.finish());
        assert_eq!(r.verdict(Property::AmdTrace), Verdict::Pass);
        assert_eq!(r.verdict(Property::AmdBarrier), Verdict::Pass);
        assert_eq!(
            r.verdict(Property::AmdMemoryConflict),
            if vm == 0 {
                Verdict::Pass
            } else {
                Verdict::Fail
            },
            "{r:#?}"
        );
        if vm != 0 {
            assert!(
                r.amd
                    .as_ref()
                    .unwrap()
                    .memory_conflict
                    .violations()
                    .iter()
                    .any(|c| c.kind == ConflictKind::WriteRead
                        && c.location.space == Space::Shared
                        && c.location.addr == 0)
            );
        }
    }
}

#[test]
fn captured_sources_have_no_dma_completion_lease_but_pending_producers_are_checked() {
    let mut t = Trace::new(64);
    t.init(0, true);
    t.dma(0, Dma::new(0, DMA32, 1, 0));
    t.ins(
        0,
        "scalar ALU",
        1,
        vec![],
        vec![scalar(124), scalar(4), scalar(5), scalar(6), scalar(7)],
    );
    t.ins(0, "vector ALU", 1, vec![], vec![vector(8, 1)]);
    assert_eq!(
        check_graph(&t.finish()).verdict(Property::AmdWaitReadiness),
        Verdict::Pass
    );
    for destination in [scalar(4), vector(8, 1)] {
        let mut t = Trace::new(64);
        t.init(0, true);
        let class = if destination.file == AmdRegisterFile::Scalar {
            AmdMemoryClass::ScalarMemory
        } else {
            AmdMemoryClass::VectorMemory
        };
        let producer = t.load(class, destination);
        let (instruction, _) = t.dma(0, Dma::new(0, DMA32, 1, 0));
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        assert!(
            amd.wait_readiness
                .violations()
                .iter()
                .any(|h| h.issue == producer
                    && h.use_event == instruction
                    && h.register == destination)
        );
    }
    for padding in [4, 5] {
        let mut t = Trace::new(64);
        t.init(0, true);
        let producer = t.ins(0, "vector ALU", 1, vec![], vec![scalar(4)]);
        for _ in 0..padding {
            t.nop(0);
        }
        let (instruction, _) = t.dma(0, Dma::new(0, DMA32, 1, 0));
        let r = check_graph(&t.finish());
        let amd = r.amd.unwrap();
        assert_eq!(amd.trace.verdict(), Verdict::Pass);
        assert_eq!(
            amd.wait_readiness.verdict(),
            if padding == 5 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if padding == 4 {
            assert!(
                amd.wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.issue == producer
                        && h.use_event == instruction
                        && h.kind == AmdRegisterHazardKind::ValuScalarReadBeforeReady)
            );
        }
    }
}
