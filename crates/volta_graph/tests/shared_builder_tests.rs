//! Shared recording helpers preserve AMD wave PCs, exits and independent wait queues.

use volta_graph::{
    AsyncOpKind, BarrierArrivals, BarrierWait, ContributionKind, EventKind, ExecContext,
    GenerationEvidence, GenerationKind, GraphBuilder, GroupWait, InstructionInfo, ProgramPoint,
    Provenance, SyncObjectKind, Terminal, ThreadIx, ThreadUnit,
};

fn builder(waves: u32) -> GraphBuilder {
    GraphBuilder::new(Provenance {
        kernel: "shared_recording".into(),
        block_dim: (64 * waves, 1, 1),
        unit: ThreadUnit::Wave { lanes: 64 },
        grid_dim: (1, 1, 1),
        workgroup_id: (0, 0, 0),
        targets: vec!["gfx950".into()],
        assumptions: Vec::new(),
        instructions: vec![
            InstructionInfo {
                kind: "test",
                span: None
            };
            10
        ],
    })
}

#[test]
fn repeated_barriers_reuse_exits_and_resume_only_blocked_waves_at_their_pcs() {
    let mut builder = builder(3);
    let exit = builder.exit(ThreadIx(0), ProgramPoint(0));
    let mut generations = Vec::new();
    for round in 0..2 {
        for wave in [2, 1] {
            builder.barrier_arrive(
                ThreadIx(wave),
                ProgramPoint(1 + wave + 3 * round),
                0,
                BarrierArrivals::FullCta,
                BarrierWait::Blocking,
            );
        }
        let forming = builder.forming_barrier(0).unwrap();
        assert_eq!(builder.barrier_fire(0), forming);
        assert_eq!(builder.forming_barrier(0), None);
        generations.push(forming);
    }
    builder.barrier_arrive(
        ThreadIx(1),
        ProgramPoint(7),
        1,
        BarrierArrivals::Count(2),
        BarrierWait::NonBlocking,
    );
    builder.barrier_arrive(
        ThreadIx(2),
        ProgramPoint(8),
        1,
        BarrierArrivals::Count(2),
        BarrierWait::Blocking,
    );
    let counted = builder.barrier_fire(1);
    for wave in [1, 2] {
        builder.exit(ThreadIx(wave), ProgramPoint(9));
    }
    let graph = builder.finish(Terminal::Completed);
    graph.validate().unwrap();
    assert_eq!(graph.objects().len(), 2);
    let object = graph.generation(generations[0]).object;
    for (round, &id) in generations.iter().enumerate() {
        let generation = graph.generation(id);
        assert_eq!(generation.object, object);
        assert_eq!(generation.index, round as u32);
        assert_eq!(generation.evidence, GenerationEvidence::default());
        assert_eq!(generation.contributions.len(), 3);
        let exited: Vec<_> = generation
            .contributions
            .iter()
            .filter(|c| c.kind == ContributionKind::Exited)
            .map(|c| c.event)
            .collect();
        assert_eq!(exited, [exit]);
        let resumes: Vec<_> = generation
            .releases
            .iter()
            .map(|&event| {
                assert!(generation.completion.unwrap() < event);
                let recorded = graph.event(event);
                assert_eq!(recorded.kind, EventKind::Resume(id));
                (recorded.ctx, recorded.pc)
            })
            .collect();
        assert_eq!(
            resumes,
            [
                (
                    ExecContext::Thread(ThreadIx(1)),
                    Some(ProgramPoint(2 + 3 * round as u32))
                ),
                (
                    ExecContext::Thread(ThreadIx(2)),
                    Some(ProgramPoint(3 + 3 * round as u32))
                ),
            ]
        );
    }
    let generation = graph.generation(counted);
    assert_eq!(generation.contributions.len(), 2);
    assert!(
        generation
            .contributions
            .iter()
            .all(|c| c.kind != ContributionKind::Exited)
    );
    assert_eq!(generation.releases.len(), 1);
    let resumed = graph.event(generation.releases[0]);
    assert_eq!(resumed.ctx, ExecContext::Thread(ThreadIx(2)));
    assert_eq!(resumed.pc, Some(ProgramPoint(8)));
}

#[test]
fn group_waits_keep_per_wave_generations_and_empty_waits_record_nothing() {
    let mut builder = builder(2);
    let first = builder.async_issue(ThreadIx(0), ProgramPoint(0), AsyncOpKind::Ds);
    let other = builder.async_issue(ThreadIx(1), ProgramPoint(0), AsyncOpKind::Ds);
    let second = builder.async_issue(ThreadIx(0), ProgramPoint(1), AsyncOpKind::Ds);
    let wait = GroupWait::Async { keep_pending: 1 };
    let position = builder.position();
    assert_eq!(
        builder.group_wait(ThreadIx(0), ProgramPoint(2), wait, &[]),
        None
    );
    assert_eq!(builder.position(), position);
    assert!(builder.graph_so_far().objects().is_empty());
    assert!(builder.graph_so_far().generations().is_empty());
    let left = builder
        .group_wait(ThreadIx(0), ProgramPoint(3), wait, &[second, first])
        .unwrap();
    let right = builder
        .group_wait(ThreadIx(1), ProgramPoint(4), wait, &[other])
        .unwrap();
    let last = builder.async_issue(ThreadIx(0), ProgramPoint(5), AsyncOpKind::Ds);
    let next = builder
        .group_wait(ThreadIx(0), ProgramPoint(6), wait, &[last])
        .unwrap();
    for wave in [0, 1] {
        builder.exit(ThreadIx(wave), ProgramPoint(9));
    }
    let graph = builder.finish(Terminal::Completed);
    graph.validate().unwrap();
    assert_eq!(graph.objects().len(), 2);
    assert_eq!(graph.generations().len(), 3);
    assert_eq!(graph.generation(left).object, graph.generation(next).object);
    assert_ne!(
        graph.generation(left).object,
        graph.generation(right).object
    );
    for (id, wave, index, pc, ops) in [
        (left, 0, 0, 3, vec![second, first]),
        (right, 1, 0, 4, vec![other]),
        (next, 0, 1, 6, vec![last]),
    ] {
        let generation = graph.generation(id);
        assert_eq!(
            graph.object(generation.object).kind,
            SyncObjectKind::AsyncGroupWait {
                thread: ThreadIx(wave)
            }
        );
        assert_eq!(generation.index, index);
        assert_eq!(
            generation.kind,
            GenerationKind::AsyncGroupWait { keep_pending: 1 }
        );
        assert_eq!(generation.evidence, GenerationEvidence::default());
        assert_eq!(generation.contributions.len(), ops.len());
        for (contribution, op) in generation.contributions.iter().zip(ops) {
            assert_eq!(
                contribution.kind,
                ContributionKind::AsyncCompletion { op, tx_bytes: 0 }
            );
            assert_eq!(Some(contribution.event), graph.async_op(op).completion);
            assert_eq!(graph.async_op(op).tracking, [id]);
        }
        assert_eq!(generation.releases.len(), 1);
        let release = generation.releases[0];
        assert!(generation.completion.unwrap() < release);
        assert_eq!(
            graph.event(release).ctx,
            ExecContext::Thread(ThreadIx(wave))
        );
        assert_eq!(graph.event(release).pc, Some(ProgramPoint(pc)));
    }
}
