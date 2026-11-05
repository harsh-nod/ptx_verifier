//! AMD wave-unit graph ordering stays separate from physical-work-item graphs.

use volta_expr::ExprArena;
use volta_graph::{
    AccessMode, AmdEventKind, Assumption, AsyncOpKind, EventGraph, GraphBuilder, InstructionInfo,
    MemAccess, OperandRole, OrderingKind, ProgramPoint, Provenance, Proxy, Space, StoredValue,
    Terminal, ThreadIx, ThreadUnit,
};
use volta_graph_check::memory_conflict::check_memory_conflicts;
use volta_graph_check::relation::ValidatedGraph;
use volta_graph_check::{GraphConclusion, Verdict, check_graph};

const PC: ProgramPoint = ProgramPoint(0);

fn builder(unit: ThreadUnit) -> GraphBuilder {
    GraphBuilder::new(Provenance {
        kernel: "amd_wave_unit".into(),
        block_dim: (128, 1, 1),
        unit,
        grid_dim: (1, 1, 1),
        workgroup_id: (0, 0, 0),
        targets: vec!["gfx950".into()],
        assumptions: vec![],
        instructions: vec![InstructionInfo {
            kind: "ds",
            span: None,
        }],
    })
}

fn access(b: &mut GraphBuilder, thread: u32, space: Space, mode: AccessMode) -> MemAccess {
    let value =
        (mode == AccessMode::Write).then(|| b.value(StoredValue::Scalar(ExprArena::new().int(7))));
    MemAccess {
        space,
        mode,
        ordering: OrderingKind::Ordinary,
        proxy: Proxy::Generic,
        footprint: volta_graph::Footprint::Bytes { addr: 0, width: 4 },
        role: OperandRole::Plain,
        attributed: ThreadIx(thread),
        value,
    }
}

fn finish(mut b: GraphBuilder) -> EventGraph {
    for thread in 0..b.graph_so_far().threads() {
        b.exit(ThreadIx(thread), PC);
    }
    b.finish(Terminal::Completed)
}

fn verdict(graph: &EventGraph) -> Verdict {
    let h = ValidatedGraph::assuming_epochs(graph).expect("well-formed AMD graph");
    check_memory_conflicts(&h).0.verdict()
}

fn separate_ops(
    unit: ThreadUnit,
    second_issuer: u32,
    kind: AsyncOpKind,
    space: Space,
) -> EventGraph {
    let mut b = builder(unit);
    for issuer in [0, second_issuer] {
        let op = b.async_issue(ThreadIx(issuer), PC, kind);
        let a = access(&mut b, issuer, space, AccessMode::Write);
        b.async_effect(op, a);
    }
    finish(b)
}

#[test]
fn distinct_ds_instructions_of_one_wave_are_lds_ordered() {
    let graph = separate_ops(
        ThreadUnit::Wave { lanes: 64 },
        0,
        AsyncOpKind::Ds,
        Space::Shared,
    );
    assert_eq!(verdict(&graph), Verdict::Pass);
}

#[test]
fn a_physical_work_item_issuer_does_not_imply_wave_ds_ordering() {
    let graph = separate_ops(ThreadUnit::CtaThread, 0, AsyncOpKind::Ds, Space::Shared);
    assert_eq!(verdict(&graph), Verdict::Fail);
}

#[test]
fn ds_instructions_of_different_waves_still_conflict() {
    let graph = separate_ops(
        ThreadUnit::Wave { lanes: 64 },
        1,
        AsyncOpKind::Ds,
        Space::Shared,
    );
    assert_eq!(verdict(&graph), Verdict::Fail);
}

#[test]
fn overlapping_writers_of_one_ds_instruction_still_conflict() {
    let mut b = builder(ThreadUnit::Wave { lanes: 64 });
    let op = b.async_issue(ThreadIx(0), PC, AsyncOpKind::Ds);
    for _ in 0..2 {
        let a = access(&mut b, 0, Space::Shared, AccessMode::Write);
        b.async_effect(op, a);
    }
    assert_eq!(verdict(&finish(b)), Verdict::Fail);
}

#[test]
fn wave_ds_ordering_does_not_exempt_global_effects() {
    let graph = separate_ops(
        ThreadUnit::Wave { lanes: 64 },
        0,
        AsyncOpKind::Ds,
        Space::Global,
    );
    assert_eq!(verdict(&graph), Verdict::Fail);
}

#[test]
fn wave_units_do_not_order_other_async_instruction_kinds() {
    let graph = separate_ops(
        ThreadUnit::Wave { lanes: 64 },
        0,
        AsyncOpKind::CpAsync,
        Space::Shared,
    );
    assert_eq!(verdict(&graph), Verdict::Fail);
}

#[test]
fn wave_ds_issue_order_does_not_complete_memory_before_a_thread_access() {
    let mut b = builder(ThreadUnit::Wave { lanes: 64 });
    let op = b.async_issue(ThreadIx(0), PC, AsyncOpKind::Ds);
    let write = access(&mut b, 0, Space::Shared, AccessMode::Write);
    b.async_effect(op, write);
    let read = access(&mut b, 0, Space::Shared, AccessMode::Read);
    b.thread_access(ThreadIx(0), PC, read);
    assert_eq!(verdict(&finish(b)), Verdict::Fail);
}

fn empty_profile(
    unit: ThreadUnit,
    targets: Vec<String>,
    shared_only: bool,
    native_record: bool,
) -> EventGraph {
    let mut p = builder(unit).graph_so_far().provenance().clone();
    p.targets = targets;
    if shared_only {
        p.assumptions.push(Assumption::SharedMemoryOnly);
    }
    let mut b = GraphBuilder::new(p);
    if native_record {
        b.amd_event(0, PC, AmdEventKind::Delay { cycles: 1 });
    }
    finish(b)
}

#[test]
fn explicit_experimental_wave_profiles_use_the_shared_graph_suite() {
    for target in [
        "amdgcn-amd-amdhsa--gfx950",
        "amdgcn-amd-amdhsa--gfx950:xnack-",
        "amdgcn-amd-amdhsa--gfx950:sramecc+:xnack-",
    ] {
        let graph = empty_profile(
            ThreadUnit::Wave { lanes: 64 },
            vec![target.into()],
            true,
            false,
        );
        let report = check_graph(&graph);
        assert!(report.amd.is_none());
        assert_eq!(report.conclusion(), GraphConclusion::Verified, "{target}");
    }
}

#[test]
fn a_wave_profile_cannot_bypass_native_or_unsupported_target_contracts() {
    for target in [
        "gfx950",
        "amdgcn-amd-amdhsa--gfx942",
        "amdgcn-amd-amdhsa--gfx1250",
        "amdgcn-amd-amdhsa--gfx950:unknown+",
        "amdgcn-amd-amdhsa--gfx950:xnack-:xnack-",
        "unrecognized",
    ] {
        let graph = empty_profile(
            ThreadUnit::Wave { lanes: 64 },
            vec![target.into()],
            true,
            false,
        );
        assert!(
            matches!(
                check_graph(&graph).conclusion(),
                GraphConclusion::Unknown { .. }
            ),
            "{target}"
        );
    }
    for (unit, shared_only, native_record) in [
        (ThreadUnit::CtaThread, true, false),
        (ThreadUnit::Wave { lanes: 32 }, true, false),
        (ThreadUnit::Wave { lanes: 64 }, false, false),
        (ThreadUnit::Wave { lanes: 64 }, true, true),
    ] {
        let graph = empty_profile(
            unit,
            vec!["amdgcn-amd-amdhsa--gfx950:xnack-".into()],
            shared_only,
            native_record,
        );
        assert!(
            matches!(
                check_graph(&graph).conclusion(),
                GraphConclusion::Unknown { .. }
            ),
            "{unit:?}, shared={shared_only}, native={native_record}"
        );
    }
    let graph = empty_profile(
        ThreadUnit::Wave { lanes: 64 },
        vec!["amdgcn-amd-amdhsa--gfx950".into(), "gfx950".into()],
        true,
        false,
    );
    assert!(matches!(
        check_graph(&graph).conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}
