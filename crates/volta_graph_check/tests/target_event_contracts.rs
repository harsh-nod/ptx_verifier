use volta_graph::{
    AmdEventKind, AmdNamedBarrier, GraphBuilder, InstructionInfo, ProgramPoint, Provenance,
    Terminal, ThreadIx,
};
use volta_graph_check::{GraphConclusion, Property, check_graph};

#[test]
fn cdna_targets_refuse_every_allocated_named_barrier_event() {
    let object = AmdNamedBarrier {
        id: 1,
        incarnation: 0,
    };
    let variants = [
        AmdEventKind::NamedBarrierInit {
            object,
            expected: 1,
        },
        AmdEventKind::NamedBarrierJoin { object, phase: 0 },
        AmdEventKind::NamedBarrierSignal {
            object,
            phase: 0,
            exec_mask: 1,
        },
        AmdEventKind::NamedBarrierWait {
            encoded: 1,
            object,
            phase: 0,
        },
        AmdEventKind::NamedBarrierRelease { object, phase: 0 },
        AmdEventKind::NamedBarrierLeave { object, phase: 0 },
    ];
    for target in ["gfx942", "gfx950"] {
        for variant in variants.clone() {
            let mut builder = GraphBuilder::new(Provenance {
                kernel: "target_event_contract".into(),
                block_dim: (1, 1, 1),
                grid_dim: (1, 1, 1),
                targets: vec![target.into()],
                assumptions: vec![],
                instructions: vec![InstructionInfo {
                    kind: "scalar ALU",
                    span: None,
                }],
            });
            builder.amd_event(
                0,
                ProgramPoint(0),
                AmdEventKind::Instruction {
                    exec_mask: 1,
                    reads: vec![],
                    writes: vec![],
                    scalar_mask_reads: vec![],
                },
            );
            builder.amd_event(0, ProgramPoint(0), variant.clone());
            builder.exit(ThreadIx(0), ProgramPoint(0));
            let graph = builder.finish(Terminal::Completed);
            assert!(graph.validate().is_ok(), "{target}: {variant:?}");
            let report = check_graph(&graph);
            assert!(
                matches!(report.conclusion(), GraphConclusion::Unknown { .. }),
                "{target}: {variant:?} must not use a legacy target contract"
            );
            assert!(
                report
                    .summary(Property::AmdTrace)
                    .findings
                    .iter()
                    .any(|reason| reason.text.contains("GFX12 event")),
                "{target}: {variant:?} needs an explicit target mismatch"
            );
        }
    }
}
