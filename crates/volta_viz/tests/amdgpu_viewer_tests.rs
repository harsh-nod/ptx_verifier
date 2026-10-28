//! AMD documents use the same v1 run-store format; old PTX stores keep their defaults.
use std::num::NonZeroU32;
use volta_expr::ExprArena;
use volta_graph::*;
use volta_graph_check::check_graph;
use volta_viz::{Outcome, Run, RunId, write_page, write_run};

const SOURCE: &str =
    "ds_bpermute_b32 v2, v0, v1\ns_waitcnt lgkmcnt(0)\nv_mov_b32 v3, v2\ns_endpgm\n";
fn provenance(threads: u32) -> Provenance {
    Provenance {
        kernel: "gfx950_view".into(),
        block_dim: (threads, 1, 1),
        grid_dim: (1, 1, 1),
        targets: vec!["gfx950".into()],
        assumptions: vec![
            Assumption::SingleWorkgroupAnalyzed,
            Assumption::MathematicalRealArithmetic,
        ],
        instructions: vec![
            InstructionInfo {
                kind: "LDS",
                span: Some((0, 26)),
            },
            InstructionInfo {
                kind: "wait",
                span: Some((27, 49)),
            },
            InstructionInfo {
                kind: "vector ALU",
                span: Some((50, 69)),
            },
            InstructionInfo {
                kind: "control",
                span: Some((70, 79)),
            },
        ],
    }
}
fn instruction(
    b: &mut GraphBuilder,
    wave: u32,
    pc: u32,
    reads: Vec<AmdRegister>,
    writes: Vec<AmdRegister>,
) {
    b.amd_event(
        wave,
        ProgramPoint(pc),
        AmdEventKind::Instruction {
            scalar_mask_reads: vec![],
            exec_mask: u64::MAX,
            reads,
            writes,
        },
    );
}
fn v(index: u16) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Vector,
        index,
        lanes: u64::MAX,
    }
}
fn register_graph(wait: bool, terminal: Terminal) -> EventGraph {
    register_graph_with_layout(wait, terminal, vec![])
}
fn register_graph_with_layout(
    wait: bool,
    terminal: Terminal,
    layout: Vec<SharedAllocation>,
) -> EventGraph {
    register_graph_for_target(wait, terminal, layout, "gfx950")
}
fn register_graph_for_target(
    wait: bool,
    terminal: Terminal,
    layout: Vec<SharedAllocation>,
    target: &str,
) -> EventGraph {
    let mut p = provenance(64);
    p.targets = vec![target.into()];
    p.kernel = format!("{}_view", target.split(':').next().unwrap());
    let mut b = GraphBuilder::new(p);
    b.set_shared_allocation_layout(layout);
    instruction(&mut b, 0, 0, vec![v(0), v(1)], vec![v(2)]);
    b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::CrossLane,
            counters: vec![(AmdCounter::Lgkm, 1)],
            destinations: vec![v(2)],
            held_sources: vec![],
        },
    );
    if wait {
        instruction(&mut b, 0, 1, vec![], vec![]);
        b.amd_event(
            0,
            ProgramPoint(1),
            AmdEventKind::Wait {
                vmcnt: None,
                lgkmcnt: Some(0),
                expcnt: None,
            },
        );
    }
    instruction(&mut b, 0, 2, vec![v(2)], vec![v(3)]);
    if terminal == Terminal::Completed {
        for t in 0..64 {
            b.exit(ThreadIx(t), ProgramPoint(3));
        }
    }
    b.finish(terminal)
}
fn exported(name: &str, graph: &EventGraph) -> String {
    let dir = std::env::temp_dir().join(format!("gfx950-viz-{}-{name}", std::process::id()));
    let arena = ExprArena::new();
    let report = check_graph(graph);
    let id = RunId {
        suite: "amdgpu_viewer".into(),
        test: name.into(),
        ordinal: NonZeroU32::new(1).unwrap(),
    };
    write_run(
        &dir,
        &Run {
            id: &id,
            ptx_file: Some("native.s"),
            source: SOURCE,
            outcome: Outcome::Executed {
                graph,
                arena: &arena,
                report: Some(&report),
            },
        },
    )
    .unwrap();
    write_page(&dir, &dir.join("index.html")).unwrap();
    std::fs::read_to_string(dir.join(format!("{}.json", id.key()))).unwrap()
}

#[test]
fn wave64_waits_registers_and_source_locations_export_in_existing_store() {
    let text = exported("wait_success", &register_graph(true, Terminal::Completed));
    for expected in [
        "volta-viz 1",
        "\"wave_size\":64",
        "\"source_language\":\"amdgpu\"",
        "w0:l63",
        "0xffffffffffffffff",
        "pending destinations",
        "lgkmcnt",
        "AMD wait and register readiness",
        "\"status\":\"race-free\"",
        "\"line\":2",
    ] {
        assert!(text.contains(expected), "missing {expected}: {text}");
    }
    assert!(!text.contains("mbarrier epochs"));
}

#[test]
fn configured_shared_object_names_and_boundaries_remain_visible_in_provenance() {
    let graph = register_graph_with_layout(
        true,
        Terminal::Completed,
        vec![
            SharedAllocation {
                name: "A".into(),
                offset: 0,
                size: 40,
            },
            SharedAllocation {
                name: "B".into(),
                offset: 40,
                size: 64,
            },
        ],
    );
    let text = exported("configured_layout", &graph);
    assert!(text.contains("caller-supplied premises"));
    assert!(text.contains("\"shared_allocations\":[{\"name\":\"A\",\"offset\":0,\"size\":40},{\"name\":\"B\",\"offset\":40,\"size\":64}]"));
    assert!(
        graph
            .dump()
            .contains("shared-allocation \"B\" offset=0x28 size=64")
    );
    assert!(
        !exported(
            "no_configured_layout",
            &register_graph(true, Terminal::Completed)
        )
        .contains("shared_allocations")
    );
}

#[test]
fn pending_register_hazard_exports_typed_issue_and_use_witness() {
    let text = exported("wait_hazard", &register_graph(false, Terminal::Completed));
    assert!(text.contains("ReadBeforeReady"));
    assert!(text.contains("is pending from e"));
    assert!(text.contains("\"status\":\"race-condition\""));
}

#[test]
fn scoped_global_effects_and_single_cu_premise_export_additively() {
    let mut p = provenance(64);
    p.assumptions.push(Assumption::SingleCuWorkgroup);
    let mut b = GraphBuilder::new(p);
    instruction(&mut b, 0, 0, vec![v(0)], vec![]);
    let issue = b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::VectorMemory,
            counters: vec![(AmdCounter::Vm, 1)],
            destinations: vec![],
            held_sources: vec![],
        },
    );
    let value = b.value(StoredValue::Opaque);
    let effect = b.thread_access(
        ThreadIx(0),
        ProgramPoint(0),
        MemAccess {
            space: Space::Global,
            mode: AccessMode::Write,
            ordering: OrderingKind::Ordinary,
            proxy: Proxy::Generic,
            footprint: Footprint::Bytes {
                addr: 0x10000,
                width: 4,
            },
            role: OperandRole::Plain,
            attributed: ThreadIx(0),
            value: Some(value),
        },
    );
    b.amd_memory_effect_scoped(issue, effect, AmdMemoryScope::Workgroup);
    for thread in 0..64 {
        b.exit(ThreadIx(thread), ProgramPoint(3));
    }
    let graph = b.finish(Terminal::Completed);
    let text = exported("workgroup_scope", &graph);
    assert!(text.contains("AMD memory scope"));
    assert!(text.contains("Workgroup"));
    assert!(text.contains("all waves of the analyzed AMD workgroup share one CU"));
    assert!(text.contains("\"format\":\"volta-viz 1\""));
    let mut dump = String::new();
    graph.write_dump(&mut dump).unwrap();
    assert!(dump.contains("scope=Workgroup"));
}

#[test]
fn aborted_unknown_and_unsupported_are_never_rendered_race_free() {
    for (name, cause, reason, status) in [
        (
            "unknown",
            AbortCause::Error,
            "analysis budget exhausted",
            "error",
        ),
        (
            "unsupported",
            AbortCause::Unsupported,
            "unimplemented form",
            "unsupported",
        ),
    ] {
        let text = exported(
            name,
            &register_graph(
                true,
                Terminal::Aborted {
                    thread: Some(ThreadIx(0)),
                    pc: Some(ProgramPoint(3)),
                    cause,
                    reason: reason.into(),
                },
            ),
        );
        assert!(text.contains(&format!("\"status\":\"{status}\"")));
        assert!(text.contains(reason));
        assert!(!text.contains("\"status\":\"race-free\""));
    }
}

#[test]
fn amd_deadlock_mentions_wave_barrier_without_ptx_object() {
    let mut b = GraphBuilder::new(provenance(64));
    instruction(&mut b, 0, 3, vec![], vec![]);
    b.amd_event(
        0,
        ProgramPoint(3),
        AmdEventKind::BarrierArrive {
            generation: 0,
            exec_mask: u64::MAX,
        },
    );
    let blocked = (0..64)
        .map(|thread| BlockedThread {
            thread: ThreadIx(thread),
            pc: ProgramPoint(3),
            on: BlockedOn::AmdBarrier {
                generation: 0,
                missing_waves: vec![1],
            },
        })
        .collect();
    let text = exported("deadlock", &b.finish(Terminal::Stuck { blocked }));
    assert!(text.contains("\"status\":\"deadlock\""));
    assert!(text.contains("AMD barrier #0 for waves [1]"));
}

#[test]
fn gfx942_and_gfx950_provenance_select_wave64_even_before_the_first_event() {
    for target in ["gfx942:sramecc+:xnack-", "gfx950:xnack-"] {
        let mut p = provenance(64);
        p.targets = vec![target.into()];
        p.kernel = format!("{}_view", target.split(':').next().unwrap());
        let graph = GraphBuilder::new(p).finish(Terminal::Aborted {
            thread: None,
            pc: None,
            cause: AbortCause::Unsupported,
            reason: "unsupported native instruction before first event".into(),
        });
        let text = exported(&format!("eventless_{target}"), &graph);
        for expected in [
            "\"wave_size\":64",
            "\"source_language\":\"amdgpu\"",
            "w0:l63",
            target,
            "\"status\":\"unsupported\"",
        ] {
            assert!(text.contains(expected), "{target}: missing{expected}");
        }
        assert!(!text.contains("gfx950 graph contract"));
        assert!(!text.contains("CDNA4 counters"));
    }
}

#[test]
fn cdna3_success_and_failure_keep_their_actual_target_and_check_names() {
    for wait in [true, false] {
        let graph = register_graph_for_target(wait, Terminal::Completed, vec![], "gfx942:xnack-");
        let text = exported(
            if wait {
                "gfx942_success"
            } else {
                "gfx942_wait_hazard"
            },
            &graph,
        );
        assert!(text.contains("gfx942:xnack-"));
        assert!(!text.contains("gfx950 graph contract"));
        assert!(text.contains(if wait {
            "\"status\":\"race-free\""
        } else {
            "ReadBeforeReady"
        }));
    }
}

#[test]
fn never_started_native_source_retains_syntax_family_without_fabricating_launch() {
    for (ordinal, separator) in [" ", "\t", "   \t"].into_iter().enumerate() {
        let id = RunId {
            suite: "native".into(),
            test: "parse_error".into(),
            ordinal: NonZeroU32::new(ordinal as u32 + 1).unwrap(),
        };
        let source =
            format!("  .amdgcn_target{separator}\"amdgcn-amd-amdhsa--gfx942\"\ns_waitcnt\n");
        let run = Run {
            id: &id,
            ptx_file: Some("invalid-native.s"),
            source: &source,
            outcome: Outcome::NotStarted {
                cause: AbortCause::Error,
                error: "missing wait operand".into(),
            },
        };
        let dir =
            std::env::temp_dir().join(format!("native-not-started-viz-{}", std::process::id()));
        write_run(&dir, &run).unwrap();
        let text = std::fs::read_to_string(dir.join(format!("{}.json", id.key()))).unwrap();
        assert!(text.contains("\"source_language\":\"amdgpu\""));
        assert!(!text.contains("\"launch\""));
        assert!(!text.contains("\"wave_size\""));
    }
}
