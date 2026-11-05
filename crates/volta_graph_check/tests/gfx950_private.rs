//! Direct records test the checker independently of native instruction decoding.
use volta_graph::*;
use volta_graph_check::{Verdict, amdgpu};

const KINDS: [&str; 11] = [
    "scratch store",
    "scratch load",
    "wait",
    "s_nop",
    "vector ALU",
    "readlane",
    "writelane",
    "s_endpgm",
    "scalar ALU",
    "vector memory",
    "scalar memory",
];
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
fn pc(kind: &str) -> ProgramPoint {
    ProgramPoint(KINDS.iter().position(|k| *k == kind).unwrap() as u32)
}
struct Trace {
    b: GraphBuilder,
    threads: u32,
}
impl Trace {
    fn new(threads: u32, assumptions: Vec<Assumption>) -> Self {
        Self {
            threads,
            b: GraphBuilder::new(Provenance {
                kernel: "private_contract".into(),
                block_dim: (threads, 1, 1),
                grid_dim: (1, 1, 1),
                workgroup_id: (0, 0, 0),
                targets: vec!["gfx950".into()],
                assumptions,
                instructions: KINDS
                    .map(|kind| InstructionInfo { kind, span: None })
                    .to_vec(),
            }),
        }
    }
    fn ins(
        &mut self,
        wave: u32,
        kind: &str,
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
    fn scratch(&mut self, load: bool, mask: u64, offsets: &[(u32, u64)]) -> EventId {
        let kind = if load {
            "scratch load"
        } else {
            "scratch store"
        };
        let data = v(0, mask);
        self.ins(
            0,
            kind,
            mask,
            if load { vec![s(32)] } else { vec![s(32), data] },
            if load { vec![data] } else { vec![] },
        );
        let issue = self.b.amd_event(
            0,
            pc(kind),
            AmdEventKind::MemoryIssue {
                class: if load {
                    AmdMemoryClass::ScratchLoad32
                } else {
                    AmdMemoryClass::ScratchStore32
                },
                counters: vec![(AmdCounter::Vm, 1)],
                destinations: if load { vec![data] } else { vec![] },
                held_sources: if load { vec![] } else { vec![data] },
            },
        );
        for &(thread, offset) in offsets {
            self.b.amd_event(
                0,
                pc(kind),
                AmdEventKind::PrivateMemoryAccess {
                    issue,
                    thread: ThreadIx(thread),
                    offset,
                    width: 4,
                    kind: if load {
                        AccessMode::Read
                    } else {
                        AccessMode::Write
                    },
                },
            );
        }
        issue
    }
    fn wait(&mut self, vm: u16, kind: &str) {
        self.ins(0, kind, 1, vec![], vec![]);
        self.b.amd_event(
            0,
            pc(kind),
            AmdEventKind::Wait {
                vmcnt: Some(vm),
                lgkmcnt: Some(0),
                expcnt: Some(0),
            },
        );
    }
    fn nop(&mut self, wave: u32, cycles: u16) {
        self.ins(wave, "s_nop", 0, vec![], vec![]);
        self.b
            .amd_event(wave, pc("s_nop"), AmdEventKind::Delay { cycles });
    }
    fn lane(&mut self, read: bool, lane: u8, exec: u64, marker: bool) {
        let kind = if read { "readlane" } else { "writelane" };
        let mask = 1u64 << lane;
        self.ins(
            0,
            kind,
            exec,
            if read { vec![v(0, mask)] } else { vec![s(8)] },
            if read { vec![s(8)] } else { vec![v(0, mask)] },
        );
        if marker {
            self.b.amd_event(
                0,
                pc(kind),
                if read {
                    AmdEventKind::LaneRead { lane }
                } else {
                    AmdEventKind::LaneWrite { lane }
                },
            );
        }
    }
    fn finish(mut self) -> EventGraph {
        for thread in 0..self.threads {
            self.b.exit(ThreadIx(thread), pc("scalar ALU"));
        }
        self.b.finish(Terminal::Completed)
    }
}
fn unknown(g: &EventGraph) {
    let r = amdgpu::check_amdgpu(g);
    assert_eq!(r.trace.verdict(), Verdict::Unknown);
    assert_eq!(r.wait_readiness.verdict(), Verdict::Unknown);
    assert_eq!(r.memory_conflict.verdict(), Verdict::Unknown);
    assert_eq!(r.barrier.verdict(), Verdict::Unknown);
}
fn pass(g: &EventGraph) {
    let r = amdgpu::check_amdgpu(g);
    assert_eq!(r.trace.verdict(), Verdict::Pass, "{:?}", r.trace);
    assert_eq!(
        r.wait_readiness.verdict(),
        Verdict::Pass,
        "{:?}",
        r.wait_readiness
    );
}
#[test]
fn same_offset_is_private_to_each_physical_thread() {
    let mut t = Trace::new(
        64,
        vec![
            Assumption::FixedPrivateAllocation(8),
            Assumption::XnackReplayDisabled,
        ],
    );
    let offsets: Vec<_> = (0..64).map(|i| (i, 4)).collect();
    t.scratch(false, u64::MAX, &offsets);
    t.wait(0, "wait");
    t.scratch(true, u64::MAX, &offsets);
    t.wait(0, "wait");
    pass(&t.finish());
}
#[test]
fn missing_duplicate_and_zero_allocation_do_not_prove_a_transfer() {
    for premises in [
        vec![],
        vec![Assumption::FixedPrivateAllocation(8); 2],
        vec![Assumption::FixedPrivateAllocation(0)],
    ] {
        let mut t = Trace::new(1, premises);
        t.scratch(true, 1, &[(0, 0)]);
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn membership_and_checked_complete_dword_bounds_are_required() {
    for offsets in [
        vec![],
        vec![(0, 0), (0, 0)],
        vec![(1, 0)],
        vec![(0, 2)],
        vec![(0, 8)],
        vec![(0, u64::MAX - 3)],
    ] {
        let mut t = Trace::new(
            2,
            vec![
                Assumption::FixedPrivateAllocation(8),
                Assumption::XnackReplayDisabled,
            ],
        );
        t.scratch(true, 1, &offsets);
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn private_visibility_and_payload_reuse_require_explicit_source_vm0() {
    for mode in 0..4 {
        let mut t = Trace::new(
            1,
            vec![
                Assumption::FixedPrivateAllocation(8),
                Assumption::XnackReplayDisabled,
            ],
        );
        t.scratch(false, 1, &[(0, 0)]);
        match mode {
            0 => {
                t.scratch(true, 1, &[(0, 0)]);
            }
            1 => {
                t.ins(0, "vector ALU", 1, vec![], vec![v(0, 1)]);
            }
            2 => t.wait(1, "wait"),
            _ => t.wait(0, "s_endpgm"),
        }
        if mode == 2 {
            t.scratch(true, 1, &[(0, 0)]);
        }
        unknown(&t.finish());
    }
}
#[test]
fn private_load_destination_consumption_before_vm0_is_unknown() {
    let mut t = Trace::new(
        1,
        vec![
            Assumption::FixedPrivateAllocation(8),
            Assumption::XnackReplayDisabled,
        ],
    );
    t.scratch(true, 1, &[(0, 0)]);
    t.ins(0, "scalar ALU", 1, vec![v(0, 1)], vec![]);
    let r = amdgpu::check_amdgpu(&t.finish());
    assert_eq!(r.trace.verdict(), Verdict::Unknown);
    assert_eq!(r.wait_readiness.verdict(), Verdict::Unknown);
}
#[test]
fn lane_operations_ignore_exec_but_require_launched_lane_and_marker() {
    let mut t = Trace::new(2, vec![]);
    t.lane(true, 1, 0, true);
    t.nop(0, 2);
    t.lane(false, 1, 0, true);
    pass(&t.finish());
    for (lane, marker) in [(2, true), (1, false)] {
        let mut t = Trace::new(2, vec![]);
        t.lane(true, lane, 0, marker);
        unknown(&t.finish());
    }
}
#[test]
fn readlane_requires_one_independent_valu_state_and_other_wave_does_not_supply_it() {
    for padding in 0..3 {
        let mut t = Trace::new(128, vec![]);
        t.ins(1, "scalar ALU", 0, vec![], vec![]);
        t.ins(0, "vector ALU", 1, vec![], vec![v(0, 1)]);
        if padding == 1 {
            t.nop(0, 1);
        } else if padding == 2 {
            t.nop(1, 1);
        }
        t.lane(true, 0, 0, true);
        let r = amdgpu::check_amdgpu(&t.finish());
        assert_eq!(r.trace.verdict(), Verdict::Pass);
        assert_eq!(
            r.wait_readiness.verdict(),
            if padding == 1 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}
#[test]
fn lane_data_and_exec_delays_use_separate_public_requirements() {
    for (register, required, read) in [(s(8), 2, false), (s(126), 4, true), (s(127), 4, false)] {
        for padding in [required - 1, required] {
            let mut t = Trace::new(1, vec![]);
            t.ins(0, "vector ALU", 1, vec![], vec![register]);
            t.nop(0, padding);
            t.lane(read, 0, 0, true);
            let r = amdgpu::check_amdgpu(&t.finish());
            assert_eq!(r.trace.verdict(), Verdict::Pass);
            assert_eq!(
                r.wait_readiness.verdict(),
                if padding == required {
                    Verdict::Pass
                } else {
                    Verdict::Fail
                }
            );
        }
    }
}

#[test]
fn salu_exec_restore_does_not_cancel_the_prior_valu_lane_delay() {
    for (read, padding) in [(true, 0), (false, 0), (true, 2), (false, 3)] {
        let mut t = Trace::new(1, vec![]);
        let producer = t.ins(
            0,
            "vector ALU",
            1,
            vec![],
            vec![s(106), s(107), s(126), s(127)],
        );
        t.ins(0, "scalar ALU", 1, vec![], vec![s(126), s(127)]);
        if padding > 0 {
            t.nop(0, padding);
        }
        t.lane(read, 0, 0, true);
        let r = amdgpu::check_amdgpu(&t.finish());
        assert_eq!(r.trace.verdict(), Verdict::Pass);
        assert_eq!(
            r.wait_readiness.verdict(),
            if padding >= 3 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
        if padding < 3 {
            assert!(
                r.wait_readiness
                    .violations()
                    .iter()
                    .any(|h| h.issue == producer
                        && h.kind == amdgpu::AmdRegisterHazardKind::ValuLaneExecBeforeReady)
            );
        }
    }
}

#[test]
fn salu_data_restore_does_not_cancel_readlane_to_writelane_delay() {
    for padding in [0, 1] {
        let mut t = Trace::new(2, vec![]);
        t.lane(true, 0, 0, true);
        t.ins(0, "scalar ALU", 0, vec![], vec![s(8)]);
        if padding > 0 {
            t.nop(0, padding);
        }
        t.lane(false, 1, 0, true);
        let r = amdgpu::check_amdgpu(&t.finish());
        assert_eq!(r.trace.verdict(), Verdict::Pass);
        assert_eq!(
            r.wait_readiness.verdict(),
            if padding == 1 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}

#[test]
fn scratch_address_needs_five_states_after_lane_sgpr_even_after_salu_restore() {
    for padding in [3, 4] {
        let mut t = Trace::new(
            1,
            vec![
                Assumption::FixedPrivateAllocation(8),
                Assumption::XnackReplayDisabled,
            ],
        );
        t.ins(0, "readlane", 0, vec![v(0, 1)], vec![s(32)]);
        t.b.amd_event(0, pc("readlane"), AmdEventKind::LaneRead { lane: 0 });
        t.ins(0, "scalar ALU", 0, vec![], vec![s(32)]);
        t.nop(0, padding);
        t.scratch(true, 1, &[(0, 0)]);
        t.wait(0, "wait");
        let r = amdgpu::check_amdgpu(&t.finish());
        assert_eq!(r.trace.verdict(), Verdict::Pass);
        assert_eq!(
            r.wait_readiness.verdict(),
            if padding == 4 {
                Verdict::Pass
            } else {
                Verdict::Fail
            }
        );
    }
}

#[test]
fn scratch_xnack_profile_is_explicit_and_not_contradicted_by_target() {
    for (target, premise, valid) in [
        ("gfx950", true, true),
        ("gfx950:xnack-", true, true),
        ("gfx950", false, false),
        ("gfx950:xnack+", true, false),
    ] {
        let mut assumptions = vec![Assumption::FixedPrivateAllocation(8)];
        if premise {
            assumptions.push(Assumption::XnackReplayDisabled);
        }
        let mut t = Trace::new(1, assumptions);
        // Change only target through a fresh builder; all records stay identical.
        let mut provenance = t.b.graph_so_far().provenance().clone();
        provenance.targets = vec![target.into()];
        t.b = GraphBuilder::new(provenance);
        t.scratch(true, 1, &[(0, 0)]);
        t.wait(0, "wait");
        let graph = t.finish();
        if valid { pass(&graph) } else { unknown(&graph) }
    }
}

fn private_premises() -> Vec<Assumption> {
    vec![
        Assumption::FixedPrivateAllocation(8),
        Assumption::XnackReplayDisabled,
    ]
}
struct LoadProfile {
    wave: u32,
    mask: u64,
    source: &'static str,
    class: AmdMemoryClass,
    reads: Vec<AmdRegister>,
    writes: Vec<AmdRegister>,
    counters: Vec<(AmdCounter, u16)>,
    destinations: Vec<AmdRegister>,
    held: Vec<AmdRegister>,
}
impl LoadProfile {
    fn new() -> Self {
        Self {
            wave: 0,
            mask: 1,
            source: "scratch load",
            class: AmdMemoryClass::ScratchLoad32,
            reads: vec![s(32)],
            writes: vec![v(0, 1)],
            counters: vec![(AmdCounter::Vm, 1)],
            destinations: vec![v(0, 1)],
            held: vec![],
        }
    }
    fn issue(&self, t: &mut Trace) -> EventId {
        t.ins(
            self.wave,
            self.source,
            self.mask,
            self.reads.clone(),
            self.writes.clone(),
        );
        t.b.amd_event(
            self.wave,
            pc(self.source),
            AmdEventKind::MemoryIssue {
                class: self.class,
                counters: self.counters.clone(),
                destinations: self.destinations.clone(),
                held_sources: self.held.clone(),
            },
        )
    }
    fn access(&self, t: &mut Trace, issue: EventId, access: AmdEventKind) {
        assert!(matches!(access,AmdEventKind::PrivateMemoryAccess {issue:i,..} if i==issue));
        t.b.amd_event(self.wave, pc(self.source), access);
    }
}
fn access(issue: EventId, thread: u32, offset: u64) -> AmdEventKind {
    AmdEventKind::PrivateMemoryAccess {
        issue,
        thread: ThreadIx(thread),
        offset,
        width: 4,
        kind: AccessMode::Read,
    }
}
#[test]
fn forged_scratch_classes_roles_countercharges_and_holds_refuse() {
    for fault in 0..10 {
        let mut t = Trace::new(2, private_premises());
        let mut p = LoadProfile::new();
        match fault {
            0 => p.source = "vector memory",
            1 => p.class = AmdMemoryClass::VectorMemory,
            2 => p.counters = vec![(AmdCounter::Vm, 2)],
            3 => p.counters = vec![(AmdCounter::Lgkm, 1)],
            4 => p.reads = vec![s(106)],
            5 => p.reads.push(s(33)),
            6 => p.writes = vec![v(0, 2)],
            7 => p.destinations = vec![v(1, 1)],
            8 => p.held = vec![s(32)],
            9 => p.mask = 0,
            _ => unreachable!(),
        }
        let issue = p.issue(&mut t);
        p.access(&mut t, issue, access(issue, 0, 0));
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn private_width_mode_uniform_offset_and_semantic_boundary_are_checked() {
    for fault in 0..5 {
        let mut t = Trace::new(if fault == 4 { 128 } else { 2 }, private_premises());
        if fault == 4 {
            t.ins(1, "scalar ALU", 0, vec![], vec![]);
        }
        let mut p = LoadProfile::new();
        p.mask = 3;
        p.writes = vec![v(0, 3)];
        p.destinations = p.writes.clone();
        let issue = p.issue(&mut t);
        p.access(&mut t, issue, access(issue, 0, 0));
        match fault {
            0 => p.access(
                &mut t,
                issue,
                AmdEventKind::PrivateMemoryAccess {
                    issue,
                    thread: ThreadIx(1),
                    offset: 0,
                    width: 8,
                    kind: AccessMode::Read,
                },
            ),
            1 => p.access(
                &mut t,
                issue,
                AmdEventKind::PrivateMemoryAccess {
                    issue,
                    thread: ThreadIx(1),
                    offset: 0,
                    width: 4,
                    kind: AccessMode::Write,
                },
            ),
            2 => p.access(&mut t, issue, access(issue, 1, 4)),
            3 => {
                t.ins(0, "scalar ALU", 0, vec![], vec![]);
                p.access(&mut t, issue, access(issue, 1, 0));
            }
            4 => {
                t.b.amd_event(1, pc("scratch load"), access(issue, 1, 0));
            }
            _ => unreachable!(),
        }
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn empty_scratch_exec_has_no_register_observations_or_semantic_issue() {
    let mut t = Trace::new(1, private_premises());
    t.ins(0, "scratch load", 0, vec![], vec![]);
    pass(&t.finish());
    let mut zero = Trace::new(
        1,
        vec![
            Assumption::FixedPrivateAllocation(0),
            Assumption::XnackReplayDisabled,
        ],
    );
    zero.ins(0, "scratch load", 0, vec![], vec![]);
    unknown(&zero.finish());
    for fault in 0..2 {
        let mut t = Trace::new(1, private_premises());
        t.ins(
            0,
            "scratch load",
            0,
            if fault == 0 { vec![s(32)] } else { vec![] },
            if fault == 1 { vec![v(0, 1)] } else { vec![] },
        );
        unknown(&t.finish());
    }
}
#[test]
fn inactive_exec_lane_read_and_write_still_enforce_pending_private_load_admission() {
    for read in [true, false] {
        let mut t = Trace::new(1, private_premises());
        t.scratch(true, 1, &[(0, 0)]);
        t.lane(read, 0, 0, true);
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn private_load_overwrite_and_completed_or_synthetic_end_are_inconclusive() {
    for fault in 0..3 {
        let mut t = Trace::new(1, private_premises());
        t.scratch(true, 1, &[(0, 0)]);
        match fault {
            0 => {
                t.ins(0, "vector ALU", 1, vec![], vec![v(0, 1)]);
            }
            1 => t.wait(0, "s_endpgm"),
            _ => {}
        }
        unknown(&t.finish());
    }
}
fn ordinary_load(t: &mut Trace, class: AmdMemoryClass, destination: AmdRegister) -> EventId {
    let kind = if class == AmdMemoryClass::ScalarMemory {
        "scalar memory"
    } else {
        "vector memory"
    };
    t.ins(0, kind, 1, vec![], vec![destination]);
    let counters = match class {
        AmdMemoryClass::ScalarMemory => vec![(AmdCounter::Lgkm, 1)],
        AmdMemoryClass::Flat => vec![(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)],
        _ => vec![(AmdCounter::Vm, 1)],
    };
    let issue = t.b.amd_event(
        0,
        pc(kind),
        AmdEventKind::MemoryIssue {
            class,
            counters,
            destinations: vec![destination],
            held_sources: vec![],
        },
    );
    let effect = t.b.thread_access(
        ThreadIx(0),
        pc(kind),
        MemAccess {
            space: Space::Global,
            mode: AccessMode::Read,
            ordering: OrderingKind::Ordinary,
            proxy: Proxy::Generic,
            footprint: Footprint::Bytes {
                addr: 0x10000,
                width: 4,
            },
            role: OperandRole::Plain,
            attributed: ThreadIx(0),
            value: None,
        },
    );
    t.b.amd_memory_effect(issue, effect);
    issue
}
#[test]
fn private_and_ordinary_vm_partial_waits_in_either_order_do_not_guess_completion() {
    for private_first in [true, false] {
        let mut t = Trace::new(1, private_premises());
        if private_first {
            t.scratch(true, 1, &[(0, 0)]);
        }
        ordinary_load(&mut t, AmdMemoryClass::VectorMemory, v(20, 1));
        if !private_first {
            t.scratch(true, 1, &[(0, 0)]);
        }
        t.wait(1, "wait");
        t.ins(0, "scalar ALU", 0, vec![v(0, 1)], vec![]);
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn ordinary_and_flat_counters_keep_their_own_remaining_obligations() {
    for class in [AmdMemoryClass::VectorMemory, AmdMemoryClass::Flat] {
        for private_first in [true, false] {
            let mut t = Trace::new(1, private_premises());
            if private_first {
                t.scratch(true, 1, &[(0, 0)]);
            }
            ordinary_load(&mut t, class, v(20, 1));
            if !private_first {
                t.scratch(true, 1, &[(0, 0)]);
            }
            // VM0 clears private admission, but cannot discharge FLAT's LGKM.
            t.ins(0, "wait", 0, vec![], vec![]);
            t.b.amd_event(
                0,
                pc("wait"),
                AmdEventKind::Wait {
                    vmcnt: Some(0),
                    lgkmcnt: None,
                    expcnt: None,
                },
            );
            t.ins(0, "scalar ALU", 0, vec![v(0, 1), v(20, 1)], vec![]);
            let r = amdgpu::check_amdgpu(&t.finish());
            assert_eq!(r.trace.verdict(), Verdict::Pass);
            assert_eq!(
                r.wait_readiness.verdict(),
                if class == AmdMemoryClass::Flat {
                    Verdict::Fail
                } else {
                    Verdict::Pass
                }
            );
        }
    }
}
#[test]
fn smem_address_readiness_remains_a_proven_hazard_not_private_policy() {
    let mut t = Trace::new(1, private_premises());
    let issue = ordinary_load(&mut t, AmdMemoryClass::ScalarMemory, s(32));
    t.scratch(true, 1, &[(0, 0)]);
    t.wait(0, "wait");
    let r = amdgpu::check_amdgpu(&t.finish());
    assert_eq!(r.trace.verdict(), Verdict::Pass);
    assert_eq!(r.wait_readiness.verdict(), Verdict::Fail);
    assert!(
        r.wait_readiness
            .violations()
            .iter()
            .any(|h| h.issue == issue
                && h.register == s(32)
                && h.kind == amdgpu::AmdRegisterHazardKind::ReadBeforeReady)
    );
}
#[test]
fn new_private_and_lane_records_cannot_change_other_target_contracts() {
    for target in ["gfx942", "gfx1250"] {
        for private in [true, false] {
            let mut t = Trace::new(1, if private { private_premises() } else { vec![] });
            let mut provenance = t.b.graph_so_far().provenance().clone();
            provenance.targets = vec![target.into()];
            t.b = GraphBuilder::new(provenance);
            if private {
                t.scratch(true, 1, &[(0, 0)]);
                t.wait(0, "wait");
            } else {
                t.lane(true, 0, 0, true);
            }
            unknown(&t.finish());
        }
    }
}
