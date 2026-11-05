//! Direct records test the checker independently of native instruction decoding.
use volta_graph::*;
use volta_graph_check::{Verdict, amdgpu};

const KINDS: [&str; 9] = [
    "scratch store",
    "scratch load",
    "wait",
    "s_nop",
    "vector ALU",
    "readlane",
    "writelane",
    "s_endpgm",
    "scalar ALU",
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
    let mut t = Trace::new(64, vec![Assumption::FixedPrivateAllocation(8)]);
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
        let mut t = Trace::new(2, vec![Assumption::FixedPrivateAllocation(8)]);
        t.scratch(true, 1, &offsets);
        t.wait(0, "wait");
        unknown(&t.finish());
    }
}
#[test]
fn private_visibility_and_payload_reuse_require_explicit_source_vm0() {
    for mode in 0..4 {
        let mut t = Trace::new(1, vec![Assumption::FixedPrivateAllocation(8)]);
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
fn real_load_destination_hazards_are_failures_after_admission() {
    let mut t = Trace::new(1, vec![Assumption::FixedPrivateAllocation(8)]);
    t.scratch(true, 1, &[(0, 0)]);
    t.ins(0, "scalar ALU", 1, vec![v(0, 1)], vec![]);
    let r = amdgpu::check_amdgpu(&t.finish());
    assert_eq!(r.trace.verdict(), Verdict::Pass);
    assert_eq!(r.wait_readiness.verdict(), Verdict::Fail);
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
