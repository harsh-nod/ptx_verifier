//! Direct graph oracles; no interpreter establishes expected conflict geometry.
use volta_graph::*;
use volta_graph_check::amdgpu::early_memory_conflicts::{
    MemoryConflictCertificate, MemoryConflictObserver, validate_memory_conflict_prefix,
};
use volta_graph_check::{GraphConclusion, Verdict, check_graph};

const KINDS: [&str; 7] = [
    "LDS",
    "vector memory",
    "wait",
    "s_endpgm",
    "barrier",
    "scalar memory",
    "vector ALU",
];
fn v(index: u16, lanes: u64) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Vector,
        index,
        lanes,
    }
}
struct Trace {
    b: GraphBuilder,
    target: AmdArchitecture,
    threads: u32,
}
impl Trace {
    fn new(target: AmdArchitecture, threads: u32) -> Self {
        let mut assumptions = vec![Assumption::UnclusteredWorkgroup];
        if target == AmdArchitecture::Gfx1250 {
            assumptions.push(Assumption::ConfiguredLdsBytes(128));
        }
        Self {
            b: GraphBuilder::new(Provenance {
                kernel: "local_conflict".into(),
                block_dim: (threads, 1, 1),
                grid_dim: (1, 1, 1),
                workgroup_id: (0, 0, 0),
                targets: vec![
                    match target {
                        AmdArchitecture::Gfx950 => "gfx950",
                        AmdArchitecture::Gfx1250 => "gfx1250",
                        _ => "gfx942",
                    }
                    .into(),
                ],
                assumptions,
                instructions: KINDS
                    .iter()
                    .map(|&kind| InstructionInfo {
                        kind,
                        span: Some((0, 1)),
                    })
                    .collect(),
            }),
            target,
            threads,
        }
    }
    fn width(&self) -> u32 {
        if self.target == AmdArchitecture::Gfx1250 {
            32
        } else {
            64
        }
    }
    fn ins(
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
    fn store(&mut self, space: Space, mask: u64, addresses: &[(u32, u64, u32)]) -> EventId {
        let pc = if space == Space::Shared { 0 } else { 1 };
        let reads = vec![v(0, mask), v(1, mask)];
        self.ins(0, pc, mask, reads.clone(), vec![]);
        let (class, counters) = match (self.target, space) {
            (AmdArchitecture::Gfx1250, Space::Shared) => {
                (AmdMemoryClass::Ds, vec![(AmdCounter::Ds, 1)])
            }
            (AmdArchitecture::Gfx1250, _) => (
                AmdMemoryClass::VectorStore,
                vec![(AmdCounter::Store, 1), (AmdCounter::X, 1)],
            ),
            (_, Space::Shared) => (AmdMemoryClass::Lds, vec![(AmdCounter::Lgkm, 1)]),
            _ => (AmdMemoryClass::VectorMemory, vec![(AmdCounter::Vm, 1)]),
        };
        let held_sources = if self.target == AmdArchitecture::Gfx1250 && space == Space::Global {
            reads
        } else {
            vec![]
        };
        let issue = self.b.amd_event(
            0,
            ProgramPoint(pc),
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations: vec![],
                held_sources,
            },
        );
        for &(lane, addr, width) in addresses {
            let value = self.b.value(StoredValue::Opaque);
            let e = self.b.thread_access(
                ThreadIx(lane),
                ProgramPoint(pc),
                MemAccess {
                    space,
                    mode: AccessMode::Write,
                    ordering: OrderingKind::Ordinary,
                    proxy: Proxy::Generic,
                    footprint: Footprint::Bytes { addr, width },
                    role: OperandRole::Plain,
                    attributed: ThreadIx(lane),
                    value: Some(value),
                },
            );
            self.b.amd_memory_effect(issue, e);
        }
        issue
    }
    fn certificate(&self) -> MemoryConflictCertificate {
        MemoryConflictObserver::new()
            .observe(self.b.graph_so_far())
            .unwrap()
            .expect("candidate")
    }
    fn finish(mut self) -> EventGraph {
        for wave in 0..self.threads.div_ceil(self.width()) {
            let lanes = (self.threads - wave * self.width()).min(self.width());
            let mask = if lanes == 64 {
                u64::MAX
            } else {
                (1u64 << lanes) - 1
            };
            self.ins(wave, 2, mask, vec![], vec![]);
            if self.target == AmdArchitecture::Gfx1250 {
                self.b.amd_event(
                    wave,
                    ProgramPoint(2),
                    AmdEventKind::WaitCounters {
                        thresholds: vec![
                            (AmdCounter::Load, 0),
                            (AmdCounter::Store, 0),
                            (AmdCounter::Ds, 0),
                            (AmdCounter::Km, 0),
                            (AmdCounter::X, 0),
                        ],
                    },
                );
            } else {
                self.b.amd_event(
                    wave,
                    ProgramPoint(2),
                    AmdEventKind::Wait {
                        vmcnt: Some(0),
                        lgkmcnt: Some(0),
                        expcnt: Some(0),
                    },
                );
            }
            self.ins(wave, 3, mask, vec![], vec![]);
            if self.target != AmdArchitecture::Gfx1250 {
                self.b.amd_event(
                    wave,
                    ProgramPoint(3),
                    AmdEventKind::Wait {
                        vmcnt: Some(0),
                        lgkmcnt: Some(0),
                        expcnt: Some(0),
                    },
                );
            }
        }
        for t in 0..self.threads {
            self.b.exit(ThreadIx(t), ProgramPoint(3));
        }
        self.b.finish(Terminal::Completed)
    }
}
#[test]
fn ordinary_same_issue_siblings_match_the_complete_checker_after_future_waits() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        for space in [Space::Global, Space::Shared] {
            let mut t = Trace::new(target, 4);
            t.store(space, 3, &[(0, 0, 4), (1, 2, 4)]);
            let c = t.certificate();
            let witness = validate_memory_conflict_prefix(t.b.graph_so_far(), &c).unwrap();
            assert_eq!(witness.location.addr, 2);
            let full = check_graph(&t.finish());
            assert!(
                full.amd
                    .as_ref()
                    .unwrap()
                    .memory_conflict
                    .violations()
                    .contains(&witness)
            );
            assert!(matches!(
                full.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
        }
    }
}
#[test]
fn unscheduled_waves_remain_a_prefix_not_full_trace_evidence() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        let mut t = Trace::new(target, 128);
        t.store(Space::Shared, 3, &[(0, 0, 2), (1, 0, 2)]);
        let c = t.certificate();
        assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_ok());
        assert_eq!(
            check_graph(t.b.graph_so_far()).amd.unwrap().trace.verdict(),
            Verdict::Unknown
        );
    }
}
#[test]
fn every_certificate_identity_and_pair_component_is_checked() {
    let mut t = Trace::new(AmdArchitecture::Gfx1250, 4);
    t.store(Space::Shared, 3, &[(0, 0, 2), (1, 0, 2)]);
    let c = t.certificate();
    for field in 0..12 {
        let mut f = c.clone();
        match field {
            0 => f.issue = EventId(u32::MAX),
            1 => f.instruction = EventId(u32::MAX),
            2 => f.conflict.earlier = EventId(u32::MAX),
            3 => f.conflict.later = f.conflict.earlier,
            4 => f.earlier_thread = ThreadIx(1),
            5 => f.later_thread = ThreadIx(0),
            6 => f.wave = 1,
            7 => f.conflict.location.addr = 1,
            8 => f.conflict.location.space = Space::Global,
            9 => f.graph_events += 1,
            10 => f.provenance.workgroup_id = (1, 0, 0),
            _ => f.amd_records += 1,
        }
        assert!(
            validate_memory_conflict_prefix(t.b.graph_so_far(), &f).is_err(),
            "field{field}"
        );
    }
}
#[test]
fn one_issue_is_proposed_once_and_generic_unsafe_observer_stops_stay_unknown() {
    let mut t = Trace::new(AmdArchitecture::Gfx950, 64);
    t.store(Space::Shared, 3, &[(0, 0, 2), (1, 0, 2)]);
    let mut o = MemoryConflictObserver::new();
    let c = o.observe(t.b.graph_so_far()).unwrap().unwrap();
    assert!(o.observe(t.b.graph_so_far()).unwrap().is_none());
    let g = t.b.finish(Terminal::Aborted {
        thread: None,
        pc: None,
        cause: AbortCause::Error,
        reason: "execution stopped by instruction observer".into(),
    });
    assert!(validate_memory_conflict_prefix(&g, &c).is_ok());
    assert!(matches!(
        check_graph(&g).conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}
#[test]
fn adjacency_single_thread_and_missing_active_lane_never_propose() {
    for points in [
        vec![(0, 0, 2), (1, 2, 2)],
        vec![(0, 0, 4), (0, 0, 4)],
        vec![(0, 0, 2), (1, 0, 2)],
    ] {
        let mut t = Trace::new(AmdArchitecture::Gfx950, 4);
        let mask = if points.len() == 2 && points[1].0 == 1 && points[1].1 == 0 {
            7
        } else {
            3
        };
        t.store(Space::Shared, mask, &points);
        assert!(
            MemoryConflictObserver::new()
                .observe(t.b.graph_so_far())
                .unwrap()
                .is_none()
        );
    }
}
