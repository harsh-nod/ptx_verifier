//! Direct graph oracles; no interpreter establishes expected conflict geometry.
use volta_graph::*;
use volta_graph_check::amdgpu::early_memory_conflicts::{
    MemoryConflictCertificate, MemoryConflictObserver, validate_memory_conflict_prefix,
};
use volta_graph_check::{GraphConclusion, Verdict, check_graph};

const KINDS: [&str; 9] = [
    "LDS",
    "vector memory",
    "wait",
    "s_endpgm",
    "barrier",
    "scalar memory",
    "vector ALU",
    "barrier signal",
    "barrier wait",
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
        Self::configured(target, threads, |_| {})
    }
    fn configured(
        target: AmdArchitecture,
        threads: u32,
        change: impl FnOnce(&mut Provenance),
    ) -> Self {
        let mut assumptions = vec![Assumption::UnclusteredWorkgroup];
        if target == AmdArchitecture::Gfx1250 {
            assumptions.push(Assumption::ConfiguredLdsBytes(128));
        }
        let mut provenance = Provenance {
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
        };
        change(&mut provenance);
        Self {
            b: GraphBuilder::new(provenance),
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
        self.store_changed(space, mask, addresses, |_| {}, |_| {})
    }
    fn store_changed(
        &mut self,
        space: Space,
        mask: u64,
        addresses: &[(u32, u64, u32)],
        change_issue: impl FnOnce(&mut AmdEventKind),
        mut change_access: impl FnMut(&mut MemAccess),
    ) -> EventId {
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
        let mut kind = AmdEventKind::MemoryIssue {
            class,
            counters,
            destinations: vec![],
            held_sources,
        };
        change_issue(&mut kind);
        let issue = self.b.amd_event(0, ProgramPoint(pc), kind);
        for &(lane, addr, width) in addresses {
            let value = self.b.value(StoredValue::Opaque);
            let mut access = MemAccess {
                space,
                mode: AccessMode::Write,
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes { addr, width },
                role: OperandRole::Plain,
                attributed: ThreadIx(lane),
                value: Some(value),
            };
            change_access(&mut access);
            let e = self
                .b
                .thread_access(ThreadIx(lane), ProgramPoint(pc), access);
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
    for field in 0..15 {
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
            11 => f.amd_records += 1,
            12 => f.conflict.kind = volta_graph_check::domain::ConflictKind::ReadWrite,
            13 => f.provenance.targets = vec!["gfx950".into()],
            _ => f.provenance.instructions[0].span = Some((2, 3)),
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

#[test]
fn finite_byte_geometry_agrees_with_observer_prefix_and_complete_replay() {
    // Independent oracle enumerates concrete bytes, not the observer's interval
    // sweep or the memory checker's frontier/dominance algorithm.
    let overlap = |points: &[(u32, u64, u32)]| {
        points.iter().enumerate().any(|(i, &(lane, addr, width))| {
            points[..i].iter().any(|&(other, start, size)| {
                lane != other
                    && (addr..addr + u64::from(width))
                        .any(|byte| (start..start + u64::from(size)).contains(&byte))
            })
        })
    };
    let mut geometries = Vec::new();
    for a in 0..6 {
        for b in 0..6 {
            for aw in 1..=4 {
                for bw in 1..=4 {
                    geometries.push(vec![(0, a, aw), (1, b, bw)]);
                }
            }
        }
    }
    for a in [0, 2, 4] {
        for b in [0, 2, 4] {
            for c in [0, 2, 4] {
                for aw in [1, 4] {
                    for bw in [1, 4] {
                        for cw in [1, 4] {
                            geometries.push(vec![(0, a, aw), (1, b, bw), (2, c, cw)]);
                        }
                    }
                }
            }
        }
    }
    // A long earlier component can overlap past an adjacent short component
    // from its own lane; the closest interval alone is not an adequate index.
    geometries.push(vec![(0, 0, 8), (0, 1, 1), (1, 6, 1)]);
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        for space in [Space::Global, Space::Shared] {
            for points in &geometries {
                let mut t = Trace::new(target, 4);
                let mask = points
                    .iter()
                    .fold(0, |mask, &(lane, _, _)| mask | (1 << lane));
                t.store(space, mask, points);
                let c = MemoryConflictObserver::new()
                    .observe(t.b.graph_so_far())
                    .unwrap();
                let expected = overlap(points);
                assert_eq!(c.is_some(), expected, "{target:?}/{space:?}: {points:?}");
                let witness = c
                    .as_ref()
                    .map(|c| validate_memory_conflict_prefix(t.b.graph_so_far(), c).unwrap());
                let report = check_graph(&t.finish());
                let memory = &report.amd.as_ref().unwrap().memory_conflict;
                assert_eq!(memory.verdict() == Verdict::Fail, expected);
                if let Some(witness) = witness {
                    assert!(memory.violations().contains(&witness));
                }
            }
        }
    }
}

#[test]
fn physical_high_lanes_and_multiple_components_preserve_exact_pair_identity() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        let mut t = Trace::new(target, 64);
        let last = t.width() - 1;
        let mask = 1 | (1u64 << last);
        t.store(Space::Global, mask, &[(0, 8, 4), (0, 12, 4), (last, 10, 4)]);
        let c = t.certificate();
        assert_eq!(c.later_thread, ThreadIx(last));
        assert_eq!(
            validate_memory_conflict_prefix(t.b.graph_so_far(), &c)
                .unwrap()
                .location
                .addr,
            10
        );
    }
}

#[test]
fn unsupported_effect_roles_classes_and_counter_claims_cannot_certify() {
    let mut original = Trace::new(AmdArchitecture::Gfx1250, 4);
    original.store(Space::Shared, 3, &[(0, 0, 2), (1, 0, 2)]);
    let original = original.certificate();
    for mutation in 0..11 {
        let mut t = Trace::new(AmdArchitecture::Gfx1250, 4);
        t.store_changed(
            Space::Shared,
            3,
            &[(0, 0, 2), (1, 0, 2)],
            |kind| {
                let AmdEventKind::MemoryIssue {
                    class,
                    counters,
                    destinations,
                    held_sources,
                } = kind
                else {
                    unreachable!()
                };
                match mutation {
                    0 => *class = AmdMemoryClass::TensorLoadToLds,
                    1 => *class = AmdMemoryClass::Flat,
                    2 => *counters = vec![(AmdCounter::Km, 1)],
                    3 => counters.push((AmdCounter::Ds, 1)),
                    4 => destinations.push(v(8, 3)),
                    5 => held_sources.push(v(8, 3)),
                    _ => {}
                }
            },
            |access| match mutation {
                6 => access.ordering = OrderingKind::Atomic,
                7 => access.ordering = OrderingKind::Reduction,
                8 => access.proxy = Proxy::Async,
                9 => access.role = OperandRole::Destination,
                10 => access.mode = AccessMode::Read,
                _ => {}
            },
        );
        assert!(
            validate_memory_conflict_prefix(t.b.graph_so_far(), &original).is_err(),
            "mutation {mutation}"
        );
    }
}

#[test]
fn stale_incomplete_malformed_and_wrong_terminal_prefixes_are_refused_without_panics() {
    for mutation in 0..8 {
        let mut t = Trace::new(AmdArchitecture::Gfx1250, 4);
        let issue = t.store(Space::Shared, 3, &[(0, 0, 2), (1, 0, 2)]);
        let c = t.certificate();
        match mutation {
            0 => t.b.amd_memory_effect(issue, EventId(u32::MAX)),
            1 => t.b.amd_memory_effect(EventId(u32::MAX), c.conflict.earlier),
            2 => t.b.amd_memory_effect(issue, c.conflict.earlier),
            3 => {
                t.ins(0, 6, 3, vec![], vec![]);
            }
            _ => {}
        }
        let terminal = match mutation {
            4 => Terminal::Completed,
            5 => Terminal::Aborted {
                thread: None,
                pc: None,
                cause: AbortCause::Unsupported,
                reason: "execution stopped by instruction observer".into(),
            },
            6 => Terminal::Aborted {
                thread: None,
                pc: None,
                cause: AbortCause::Error,
                reason: "unrelated evaluator error".into(),
            },
            _ => Terminal::Aborted {
                thread: None,
                pc: None,
                cause: AbortCause::Error,
                reason: "graph under construction".into(),
            },
        };
        if mutation == 7 {
            // A new incomplete instruction has no issue/effects at the callback
            // boundary; even a matching refreshed identity cannot certify it.
            t.ins(0, 0, 3, vec![v(0, 3), v(1, 3)], vec![]);
        }
        let g = t.b.finish(terminal);
        let mut c = c;
        if mutation == 7 {
            c.graph_events = g.events().len();
            c.amd_records = g.amd_events().len();
        }
        assert!(
            validate_memory_conflict_prefix(&g, &c).is_err(),
            "mutation {mutation}"
        );
    }
}

#[test]
fn recorded_lds_limits_layouts_target_and_selected_workgroup_are_premises() {
    for mutation in 0..8 {
        let mut t = Trace::configured(AmdArchitecture::Gfx1250, 4, |p| match mutation {
            0 => p
                .assumptions
                .retain(|a| !matches!(a, Assumption::ConfiguredLdsBytes(_))),
            1 => p.assumptions.push(Assumption::ConfiguredLdsBytes(64)),
            2 => p
                .assumptions
                .retain(|a| *a != Assumption::UnclusteredWorkgroup),
            3 => p.targets = vec!["gfx942".into()],
            4 => {
                p.grid_dim = (2, 1, 1);
                p.workgroup_id = (1, 0, 0);
            }
            5 => p.instructions[0].kind = "tensor memory",
            _ => {}
        });
        if mutation == 6 {
            t.b.set_shared_allocation_layout(vec![SharedAllocation {
                name: "object".into(),
                offset: 0,
                size: 2,
            }]);
        }
        let points = if mutation == 7 {
            vec![(0, 128, 2), (1, 128, 2)]
        } else {
            vec![(0, 0, 4), (1, 0, 4)]
        };
        t.store(Space::Shared, 3, &points);
        let mut valid = Trace::new(AmdArchitecture::Gfx1250, 4);
        valid.store(Space::Shared, 3, &points);
        let mut c = valid.certificate();
        c.provenance = t.b.graph_so_far().provenance().clone();
        assert!(
            validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_err(),
            "mutation {mutation}"
        );
    }
    // Explicit selection is valid and bound to the certificate. It does not
    // establish ordering against other workgroups.
    let mut t = Trace::configured(AmdArchitecture::Gfx1250, 4, |p| {
        p.grid_dim = (2, 1, 1);
        p.workgroup_id = (1, 0, 0);
        p.assumptions.push(Assumption::SingleWorkgroupAnalyzed);
    });
    t.store(Space::Global, 3, &[(0, 0, 4), (1, 0, 4)]);
    let c = t.certificate();
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_ok());
    // A recorded LDS limit is checked even for an earlier nonselected issue.
    let mut t = Trace::new(AmdArchitecture::Gfx1250, 4);
    t.store(Space::Shared, 3, &[(0, 128, 4), (1, 132, 4)]);
    t.store(Space::Global, 3, &[(0, 0, 4), (1, 0, 4)]);
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &t.certificate()).is_err());
}

#[test]
fn allocation_trust_does_not_invent_c4_or_global_extent_proofs() {
    let mut t = Trace::new(AmdArchitecture::Gfx950, 4);
    t.store(Space::Shared, 3, &[(0, 256, 4), (1, 256, 4)]);
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &t.certificate()).is_ok());
    let mut t = Trace::new(AmdArchitecture::Gfx1250, 4);
    t.store(Space::Global, 3, &[(0, 0x10000, 4), (1, 0x10000, 4)]);
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &t.certificate()).is_ok());
    // In both cases the producer's allocation preflight remains trusted. This
    // test proves conflict geometry only, not independently derived allocation.
}

#[test]
fn refused_issue_is_consumed_but_later_new_issue_can_be_validated() {
    let mut t = Trace::configured(AmdArchitecture::Gfx1250, 4, |p| {
        p.assumptions
            .retain(|a| !matches!(a, Assumption::ConfiguredLdsBytes(_)))
    });
    let mut observer = MemoryConflictObserver::new();
    let first = t.store(Space::Shared, 3, &[(0, 0, 2), (1, 0, 2)]);
    let refused = observer.observe(t.b.graph_so_far()).unwrap().unwrap();
    assert_eq!(refused.issue, first);
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &refused).is_err());
    assert!(observer.observe(t.b.graph_so_far()).unwrap().is_none());
    t.b.assume(Assumption::ConfiguredLdsBytes(128));
    let second = t.store(Space::Shared, 3, &[(0, 8, 2), (1, 8, 2)]);
    let fresh = observer.observe(t.b.graph_so_far()).unwrap().unwrap();
    assert_eq!(fresh.issue, second);
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &fresh).is_ok());
    assert!(observer.observe(t.b.graph_so_far()).unwrap().is_none());
    assert!(
        observer
            .observe(Trace::new(AmdArchitecture::Gfx1250, 4).b.graph_so_far())
            .is_err()
    );
}

#[test]
fn checked_endpoints_never_wrap_or_promote_empty_transfers() {
    for (addr, width) in [(u64::MAX, 1), (u64::MAX - 1, 4), (0, 0)] {
        let mut t = Trace::new(AmdArchitecture::Gfx950, 4);
        t.store(Space::Global, 3, &[(0, addr, width), (1, addr, width)]);
        assert!(
            MemoryConflictObserver::new()
                .observe(t.b.graph_so_far())
                .unwrap()
                .is_none()
        );
    }
}

#[test]
fn pending_destination_or_unknown_readiness_prevents_a_memory_certificate() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        for correct_wait in [false, true] {
            let mut t = Trace::new(target, 4);
            t.ins(0, 1, 3, vec![], vec![v(0, 3)]);
            let modern = target == AmdArchitecture::Gfx1250;
            let issue = t.b.amd_event(
                0,
                ProgramPoint(1),
                AmdEventKind::MemoryIssue {
                    class: if modern {
                        AmdMemoryClass::VectorLoad
                    } else {
                        AmdMemoryClass::VectorMemory
                    },
                    counters: if modern {
                        vec![(AmdCounter::Load, 1), (AmdCounter::X, 1)]
                    } else {
                        vec![(AmdCounter::Vm, 1)]
                    },
                    destinations: vec![v(0, 3)],
                    held_sources: vec![],
                },
            );
            for lane in 0..2 {
                let e = t.b.thread_access(
                    ThreadIx(lane),
                    ProgramPoint(1),
                    MemAccess {
                        space: Space::Global,
                        mode: AccessMode::Read,
                        ordering: OrderingKind::Ordinary,
                        proxy: Proxy::Generic,
                        footprint: Footprint::Bytes {
                            addr: 0x10000 + u64::from(lane) * 4,
                            width: 4,
                        },
                        role: OperandRole::Plain,
                        attributed: ThreadIx(lane),
                        value: None,
                    },
                );
                t.b.amd_memory_effect(issue, e);
            }
            t.ins(0, 2, 3, vec![], vec![]);
            let wait = if modern {
                AmdEventKind::WaitCounters {
                    thresholds: vec![(
                        if correct_wait {
                            AmdCounter::Load
                        } else {
                            AmdCounter::Ds
                        },
                        0,
                    )],
                }
            } else {
                AmdEventKind::Wait {
                    vmcnt: correct_wait.then_some(0),
                    lgkmcnt: (!correct_wait).then_some(0),
                    expcnt: None,
                }
            };
            t.b.amd_event(0, ProgramPoint(2), wait);
            t.store(Space::Shared, 3, &[(0, 0, 4), (1, 0, 4)]);
            let c = t.certificate();
            assert_eq!(
                validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_ok(),
                correct_wait,
                "{target:?}"
            );
        }
    }
    let mut t = Trace::new(AmdArchitecture::Gfx1250, 4);
    t.ins(0, 2, 3, vec![], vec![]);
    t.b.amd_event(
        0,
        ProgramPoint(2),
        AmdEventKind::WaitCounters {
            thresholds: vec![(AmdCounter::Tensor, 1)],
        },
    );
    t.store(Space::Shared, 3, &[(0, 0, 4), (1, 0, 4)]);
    assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &t.certificate()).is_err());
}

#[test]
fn barrier_reachability_is_replayed_before_any_ordinary_collision_rejection() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        for release in [false, true] {
            let mut t = Trace::new(target, 4);
            if target == AmdArchitecture::Gfx1250 {
                t.ins(0, 7, 15, vec![], vec![]);
                t.b.amd_event(
                    0,
                    ProgramPoint(7),
                    AmdEventKind::SplitBarrierSignal {
                        barrier: -1,
                        generation: 0,
                        exec_mask: 15,
                    },
                );
                t.ins(0, 8, 15, vec![], vec![]);
                t.b.amd_event(
                    0,
                    ProgramPoint(8),
                    AmdEventKind::SplitBarrierWait {
                        barrier: -1,
                        generation: 0,
                    },
                );
                if release {
                    t.b.amd_event(
                        0,
                        ProgramPoint(8),
                        AmdEventKind::SplitBarrierRelease {
                            barrier: -1,
                            generation: 0,
                        },
                    );
                }
            } else {
                t.ins(0, 4, 15, vec![], vec![]);
                t.b.amd_event(
                    0,
                    ProgramPoint(4),
                    AmdEventKind::BarrierArrive {
                        generation: 0,
                        exec_mask: 15,
                    },
                );
                if release {
                    t.b.amd_event(
                        0,
                        ProgramPoint(4),
                        AmdEventKind::BarrierRelease { generation: 0 },
                    );
                }
            }
            t.store(Space::Shared, 3, &[(0, 0, 4), (1, 0, 4)]);
            assert_eq!(
                validate_memory_conflict_prefix(t.b.graph_so_far(), &t.certificate()).is_ok(),
                release,
                "{target:?}"
            );
        }
    }
}

#[test]
fn all_queued_issues_are_distinct_and_equal_payloads_do_not_waive_conflicts() {
    let mut t = Trace::new(AmdArchitecture::Gfx950, 4);
    let value = t.b.value(StoredValue::Opaque);
    let first = t.store_changed(
        Space::Shared,
        3,
        &[(0, 0, 4), (1, 0, 4)],
        |_| {},
        |a| a.value = Some(value),
    );
    let second = t.store(Space::Shared, 3, &[(0, 8, 4), (1, 8, 4)]);
    let mut observer = MemoryConflictObserver::new();
    for issue in [first, second] {
        let c = observer.observe(t.b.graph_so_far()).unwrap().unwrap();
        assert_eq!(c.issue, issue);
        assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_ok());
    }
    assert!(observer.observe(t.b.graph_so_far()).unwrap().is_none());
}

#[test]
fn a_valid_pair_outside_the_existing_findings_cap_is_refused() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        let threads = if target == AmdArchitecture::Gfx1250 {
            32
        } else {
            64
        };
        let mut t = Trace::new(target, threads);
        let lanes = t.width();
        let mask = if lanes == 64 {
            u64::MAX
        } else {
            (1u64 << lanes) - 1
        };
        let count = if lanes == 64 { 4 } else { 10 };
        for i in 0..count {
            let points: Vec<_> = (0..lanes).map(|lane| (lane, i * 8, 4)).collect();
            t.store(Space::Shared, mask, &points);
        }
        let mut o = MemoryConflictObserver::new();
        let mut last = None;
        while let Some(c) = o.observe(t.b.graph_so_far()).unwrap() {
            last = Some(c);
        }
        let last = last.unwrap();
        // The last operation still has a real same-issue conflict, but other
        // findings filled the unchanged checker cap. An unrelated retained pair
        // must never stand in for the certificate's exact witness.
        let report = check_graph(t.b.graph_so_far());
        let memory = &report.amd.as_ref().unwrap().memory_conflict;
        assert_eq!(
            memory.violations().len(),
            volta_graph_check::memory_conflict::CONFLICT_CAP
        );
        assert!(!memory.violations().contains(&last.conflict));
        assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &last).is_err());
    }
}

#[test]
fn another_wave_may_run_between_complete_batches_but_not_inside_selected_effects() {
    for target in [AmdArchitecture::Gfx950, AmdArchitecture::Gfx1250] {
        let threads = if target == AmdArchitecture::Gfx1250 {
            64
        } else {
            128
        };
        let mut t = Trace::new(target, threads);
        t.ins(1, 6, 3, vec![], vec![]);
        let issue = t.store(Space::Shared, 3, &[(0, 0, 4), (1, 0, 4)]);
        t.ins(1, 6, 3, vec![], vec![]);
        let mut c = t.certificate();
        assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_ok());
        let value = t.b.value(StoredValue::Opaque);
        let late = t.b.thread_access(
            ThreadIx(0),
            ProgramPoint(0),
            MemAccess {
                space: Space::Shared,
                mode: AccessMode::Write,
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes { addr: 8, width: 4 },
                role: OperandRole::Plain,
                attributed: ThreadIx(0),
                value: Some(value),
            },
        );
        t.b.amd_memory_effect(issue, late);
        c.graph_events = t.b.graph_so_far().events().len();
        // The old graph representation/trace contract alone accepts this link;
        // it is not a successful complete producer instruction batch. Exact
        // effect boundaries are independently checked before prefix promotion.
        assert!(t.b.graph_so_far().validate().is_ok());
        assert_eq!(
            check_graph(t.b.graph_so_far()).amd.unwrap().trace.verdict(),
            Verdict::Pass
        );
        assert!(validate_memory_conflict_prefix(t.b.graph_so_far(), &c).is_err());
    }
}
