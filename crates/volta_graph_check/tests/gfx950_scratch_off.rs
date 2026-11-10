//! The disabled-SADDR marker cannot erase a numbered-SGPR dependency.
use volta_graph::*;
use volta_graph_check::{GraphConclusion, check_graph};

fn graph(immediate: bool, reads_scalar: bool, store: bool) -> EventGraph {
    let kind = match (immediate, store) {
        (true, true) => "scratch store immediate",
        (true, false) => "scratch load immediate",
        (false, true) => "scratch store",
        (false, false) => "scratch load",
    };
    let mut builder = GraphBuilder::new(Provenance {
        kernel: "off_contract".into(),
        block_dim: (1, 1, 1),
        unit: ThreadUnit::CtaThread,
        grid_dim: (1, 1, 1),
        workgroup_id: (0, 0, 0),
        targets: vec!["gfx950".into()],
        assumptions: vec![
            Assumption::FixedPrivateAllocation(4),
            Assumption::XnackReplayDisabled,
        ],
        instructions: [kind, "wait", "s_endpgm"]
            .map(|kind| InstructionInfo { kind, span: None })
            .to_vec(),
    });
    let data = AmdRegister {
        file: AmdRegisterFile::Vector,
        index: 0,
        lanes: 1,
    };
    let scalar = AmdRegister {
        file: AmdRegisterFile::Scalar,
        index: 20,
        lanes: u64::MAX,
    };
    let mut reads = Vec::new();
    if reads_scalar {
        reads.push(scalar);
    }
    if store {
        reads.push(data);
    }
    builder.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::Instruction {
            exec_mask: 1,
            reads,
            writes: if store { vec![] } else { vec![data] },
            scalar_mask_reads: vec![],
        },
    );
    let issue = builder.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::MemoryIssue {
            class: if store {
                AmdMemoryClass::ScratchStore32
            } else {
                AmdMemoryClass::ScratchLoad32
            },
            counters: vec![(AmdCounter::Vm, 1)],
            destinations: if store { vec![] } else { vec![data] },
            held_sources: if store { vec![data] } else { vec![] },
        },
    );
    builder.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::PrivateMemoryAccess {
            issue,
            thread: ThreadIx(0),
            offset: 0,
            width: 4,
            kind: if store {
                AccessMode::Write
            } else {
                AccessMode::Read
            },
        },
    );
    for (pc, end) in [(1, false), (2, true)] {
        builder.amd_event(
            0,
            ProgramPoint(pc),
            AmdEventKind::Instruction {
                exec_mask: if end { 1 } else { 0 },
                reads: vec![],
                writes: vec![],
                scalar_mask_reads: vec![],
            },
        );
        builder.amd_event(
            0,
            ProgramPoint(pc),
            AmdEventKind::Wait {
                vmcnt: Some(0),
                lgkmcnt: if end { Some(0) } else { None },
                expcnt: if end { Some(0) } else { None },
            },
        );
    }
    builder.exit(ThreadIx(0), ProgramPoint(2));
    builder.finish(Terminal::Completed)
}

#[test]
fn only_the_matching_scratch_source_kind_can_have_zero_scalar_reads() {
    for store in [false, true] {
        for (immediate, reads_scalar) in
            [(true, false), (false, true), (true, true), (false, false)]
        {
            let graph = graph(immediate, reads_scalar, store);
            graph.validate().unwrap();
            let report = check_graph(&graph);
            if immediate != reads_scalar {
                assert_eq!(report.conclusion(), GraphConclusion::Verified, "{report:?}");
            } else {
                assert!(
                    matches!(report.conclusion(), GraphConclusion::Unknown { .. }),
                    "{report:?}"
                );
            }
        }
    }
}
