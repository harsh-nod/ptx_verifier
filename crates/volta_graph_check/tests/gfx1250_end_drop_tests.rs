use volta_graph::*;
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const KINDS: [&str; 8] = [
    "scalar ALU",
    "barrier signal",
    "barrier wait",
    "s_endpgm",
    "named barrier init",
    "named barrier join",
    "named barrier signal",
    "named barrier wait",
];
const OBJECT: AmdNamedBarrier = AmdNamedBarrier {
    id: 1,
    incarnation: 0,
};

struct Trace(GraphBuilder);
impl Trace {
    fn new() -> Self {
        Self(GraphBuilder::new(Provenance {
            kernel: "unnamed_end_drop".into(),
            block_dim: (64, 1, 1),
            grid_dim: (1, 1, 1),
            targets: vec!["gfx1250".into()],
            assumptions: vec![
                Assumption::UnclusteredWorkgroup,
                Assumption::AllocatedNamedBarriers(4),
            ],
            instructions: KINDS
                .iter()
                .map(|&kind| InstructionInfo { kind, span: None })
                .collect(),
        }))
    }
    fn instruction(&mut self, wave: u32, pc: u32, m0_write: bool, m0_read: bool) {
        let m0 = AmdRegister {
            file: AmdRegisterFile::Scalar,
            index: 124,
            lanes: 0,
        };
        self.0.amd_event(
            wave,
            ProgramPoint(pc),
            AmdEventKind::Instruction {
                exec_mask: u32::MAX as u64,
                reads: if m0_read { vec![m0] } else { vec![] },
                writes: if m0_write { vec![m0] } else { vec![] },
                scalar_mask_reads: vec![],
            },
        );
    }
    fn signal(&mut self, wave: u32, generation: u32) {
        self.instruction(wave, 1, false, false);
        self.0.amd_event(
            wave,
            ProgramPoint(1),
            AmdEventKind::SplitBarrierSignal {
                barrier: -1,
                generation,
                exec_mask: u32::MAX as u64,
            },
        );
    }
    fn wait(&mut self, wave: u32, generation: u32) {
        self.instruction(wave, 2, false, false);
        self.0.amd_event(
            wave,
            ProgramPoint(2),
            AmdEventKind::SplitBarrierWait {
                barrier: -1,
                generation,
            },
        );
        self.0.amd_event(
            wave,
            ProgramPoint(2),
            AmdEventKind::SplitBarrierRelease {
                barrier: -1,
                generation,
            },
        );
    }
    fn rendezvous(&mut self, generation: u32) {
        self.signal(0, generation);
        self.signal(1, generation);
        self.wait(0, generation);
        self.wait(1, generation);
    }
    fn end(&mut self, wave: u32) {
        self.instruction(wave, 3, false, false);
        for lane in 0..32 {
            self.0.exit(ThreadIx(wave * 32 + lane), ProgramPoint(3));
        }
    }
    fn check(self, expected: Verdict) {
        let report = check_graph(&self.0.finish(Terminal::Completed));
        assert_eq!(
            report.verdict(Property::AmdTrace),
            Verdict::Pass,
            "{report:?}"
        );
        assert_eq!(
            report.verdict(Property::AmdWaitReadiness),
            Verdict::Pass,
            "{report:?}"
        );
        assert_eq!(report.verdict(Property::AmdBarrier), expected, "{report:?}");
        if expected == Verdict::Pass {
            assert_eq!(report.conclusion(), GraphConclusion::Verified);
        } else {
            assert!(matches!(
                report.conclusion(),
                GraphConclusion::Unknown { .. }
            ));
            assert!(
                report
                    .summary(Property::AmdBarrier)
                    .findings
                    .iter()
                    .any(|s| s.contains("implicit drop"))
            );
        }
    }
}

#[test]
fn end_before_the_other_arrival_cannot_certify_a_participating_drop() {
    let mut t = Trace::new();
    t.signal(1, 0);
    t.end(1);
    t.signal(0, 0);
    t.wait(0, 0);
    t.end(0);
    t.check(Verdict::Unknown);
}

#[test]
fn a_wait_in_another_wave_needs_execution_order_before_end() {
    let mut t = Trace::new();
    t.signal(1, 0);
    t.signal(0, 0);
    t.wait(0, 0);
    t.end(1);
    t.end(0);
    t.check(Verdict::Unknown);
}

#[test]
fn each_wave_waiting_before_end_keeps_the_valid_rendezvous() {
    let mut t = Trace::new();
    t.rendezvous(0);
    t.end(0);
    t.end(1);
    t.check(Verdict::Pass);
}

#[test]
fn arrivals_that_participate_in_no_wait_do_not_invent_a_drop_race() {
    let mut t = Trace::new();
    t.signal(0, 0);
    t.end(0);
    t.signal(1, 0);
    t.end(1);
    t.check(Verdict::Pass);
}

#[test]
fn another_barrier_can_order_a_completed_wait_before_the_signallers_end() {
    let mut t = Trace::new();
    t.instruction(0, 0, true, false);
    t.instruction(0, 4, false, true);
    t.0.amd_event(
        0,
        ProgramPoint(4),
        AmdEventKind::NamedBarrierInit {
            object: OBJECT,
            expected: 1,
        },
    );
    t.rendezvous(0);
    for wave in 0..2 {
        t.instruction(wave, 5, false, false);
        t.0.amd_event(
            wave,
            ProgramPoint(5),
            AmdEventKind::NamedBarrierJoin {
                object: OBJECT,
                phase: 0,
            },
        );
    }
    t.rendezvous(1);
    t.signal(1, 2);
    t.signal(0, 2);
    t.wait(0, 2);
    t.instruction(0, 6, false, false);
    t.0.amd_event(
        0,
        ProgramPoint(6),
        AmdEventKind::NamedBarrierSignal {
            object: OBJECT,
            phase: 0,
            exec_mask: u32::MAX as u64,
        },
    );
    t.instruction(1, 7, false, false);
    t.0.amd_event(
        1,
        ProgramPoint(7),
        AmdEventKind::NamedBarrierWait {
            encoded: 1,
            object: OBJECT,
            phase: 0,
        },
    );
    t.0.amd_event(
        1,
        ProgramPoint(7),
        AmdEventKind::NamedBarrierRelease {
            object: OBJECT,
            phase: 0,
        },
    );
    t.end(1);
    t.end(0);
    t.check(Verdict::Pass);
}
