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
fn native_target_provenance_selects_geometry_even_before_the_first_event() {
    for (target, wave_size, last_lane) in [
        ("gfx942:sramecc+:xnack-", 64, "w0:l63"),
        ("gfx950:xnack-", 64, "w0:l63"),
        ("gfx1250", 32, "w1:l31"),
    ] {
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
        assert!(text.contains(&format!("\"wave_size\":{wave_size}")));
        for expected in [
            "\"wave_kind\":\"wave\"",
            "\"source_language\":\"amdgpu\"",
            last_lane,
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
fn gfx1250_waits_and_split_barriers_keep_their_objects_and_wave32() {
    let mut p = provenance(65);
    p.targets = vec!["gfx1250".into()];
    let mut b = GraphBuilder::new(p);
    b.amd_event(
        0,
        ProgramPoint(0),
        AmdEventKind::DelayAlu {
            instid0: AmdAluDependency::Valu(1),
            instskip: 4,
            instid1: Some(AmdAluDependency::SaluCycles(1)),
        },
    );
    b.amd_event(
        1,
        ProgramPoint(0),
        AmdEventKind::WaitCounters {
            thresholds: vec![(AmdCounter::X, 0), (AmdCounter::Tensor, 0)],
        },
    );
    b.amd_event(
        1,
        ProgramPoint(0),
        AmdEventKind::SplitBarrierSignal {
            barrier: -1,
            generation: 2,
            exec_mask: 0,
        },
    );
    b.amd_event(
        1,
        ProgramPoint(0),
        AmdEventKind::SplitBarrierWait {
            barrier: -1,
            generation: 2,
        },
    );
    b.amd_event(
        1,
        ProgramPoint(0),
        AmdEventKind::SplitBarrierRelease {
            barrier: -1,
            generation: 2,
        },
    );
    let graph = b.finish(Terminal::Aborted {
        thread: None,
        pc: None,
        cause: AbortCause::Unsupported,
        reason: "schema preview: no execution proof".into(),
    });
    let text = exported("gfx1250_events", &graph);
    for expected in [
        "\"wave_size\":32",
        "\"wave_kind\":\"wave\"",
        "w2:l0",
        "s_delay_alu",
        "native wait",
        "Tensor",
        "s_barrier_signal -1 phase 2",
        "s_barrier_wait -1 phase 2",
        "barrier -1 phase 2 released",
        "amd-barrier",
    ] {
        assert!(text.contains(expected), "missing {expected}");
    }
    assert!(!text.contains("\"status\":\"race-free\""));
}

#[test]
fn named_object_incarnations_wait_selectors_and_deadlocks_are_visible() {
    let mut p = provenance(1);
    p.targets = vec!["gfx1250".into()];
    p.kernel = "gfx1250_named_schema_preview".into();
    let mut b = GraphBuilder::new(p);
    for incarnation in 0..2 {
        let object = AmdNamedBarrier { id: 1, incarnation };
        for kind in [
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
                encoded: 16,
                object,
                phase: 0,
            },
            AmdEventKind::NamedBarrierRelease { object, phase: 0 },
            AmdEventKind::NamedBarrierLeave { object, phase: 1 },
        ] {
            b.amd_event(0, ProgramPoint(0), kind);
        }
    }
    let graph = b.finish(Terminal::Stuck {
        blocked: vec![BlockedThread {
            thread: ThreadIx(0),
            pc: ProgramPoint(0),
            on: BlockedOn::AmdNamedBarrier {
                object: AmdNamedBarrier {
                    id: 1,
                    incarnation: 1,
                },
                phase: 1,
                expected: 3,
                arrived: 2,
            },
        }],
    });
    let text = exported("named_schema_preview", &graph);
    for expected in [
        "1 incarnation 0",
        "1 incarnation 1",
        "encoded WAIT selector",
        "16",
        "expected arrivals",
        "phase 1: 2/3 arrivals",
        "\"amd-barrier\":[2,4,3,4,8,10,9,10]",
    ] {
        assert!(text.contains(expected), "missing {expected}: {text}");
    }
    assert!(!text.contains("\"status\":\"race-free\""));
}

#[test]
fn a_signal_time_count_update_is_one_visible_arrival_with_its_new_count() {
    let mut p = provenance(1);
    p.targets = vec!["gfx1250".into()];
    let mut b = GraphBuilder::new(p);
    let object = AmdNamedBarrier {
        id: 1,
        incarnation: 0,
    };
    for kind in [
        AmdEventKind::NamedBarrierSignalWithCount {
            object,
            phase: 2,
            exec_mask: 1,
            expected: 3,
        },
        AmdEventKind::NamedBarrierWait {
            object,
            phase: 2,
            encoded: 1,
        },
        AmdEventKind::NamedBarrierRelease { object, phase: 2 },
    ] {
        b.amd_event(0, ProgramPoint(0), kind);
    }
    let graph = b.finish(Terminal::Aborted {
        thread: None,
        pc: None,
        cause: AbortCause::Unsupported,
        reason: "schema preview only".into(),
    });
    let text = exported("count_update_preview", &graph);
    for expected in [
        "updated expected arrivals",
        "named signal 1",
        "\"amd-barrier\":[0,2,1,2]",
    ] {
        assert!(text.contains(expected), "missing {expected}: {text}");
    }
    assert!(!text.contains("\"status\":\"race-free\""));
}

#[test]
fn null_barrier_noops_do_not_export_candidate_arrival_edges() {
    let mut p = provenance(1);
    p.targets = vec!["gfx1250".into()];
    p.kernel = "gfx1250_null_schema_preview".into();
    let mut b = GraphBuilder::new(p);
    let object = AmdNamedBarrier {
        id: 0,
        incarnation: 0,
    };
    for kind in [
        AmdEventKind::NamedBarrierSignal {
            object,
            phase: 0,
            exec_mask: 1,
        },
        AmdEventKind::NamedBarrierLeave { object, phase: 0 },
        AmdEventKind::NamedBarrierWait {
            encoded: 1,
            object,
            phase: 0,
        },
        AmdEventKind::NamedBarrierRelease { object, phase: 0 },
    ] {
        b.amd_event(0, ProgramPoint(0), kind);
    }
    let graph = b.finish(Terminal::Aborted {
        thread: None,
        pc: None,
        cause: AbortCause::Unsupported,
        reason: "schema preview: no execution proof".into(),
    });
    let text = exported("null_schema_preview", &graph);
    assert!(text.contains("\"amd-barrier\":[2,3]"), "{text}");
    assert!(!text.contains("\"status\":\"race-free\""));
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

#[test]
fn eventless_gfx1250_declares_wave32_and_conflicting_source_targets_remain_unresolved() {
    for (name, source, declared) in [
        (
            "gfx1250_unsupported",
            ".amdgcn_target \"amdgcn-amd-amdhsa--gfx1250\"\ns_barrier_init 1\n",
            true,
        ),
        (
            "conflicting_targets",
            ".amdgcn_target \"amdgcn-amd-amdhsa--gfx1250\"\n.amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n",
            false,
        ),
    ] {
        let id = RunId {
            suite: "native".into(),
            test: name.into(),
            ordinal: NonZeroU32::new(1).unwrap(),
        };
        let dir = std::env::temp_dir().join(format!(
            "gfx1250-declared-viz-{}-{name}",
            std::process::id()
        ));
        write_run(
            &dir,
            &Run {
                id: &id,
                ptx_file: Some("unsupported-native.s"),
                source,
                outcome: Outcome::NotStarted {
                    cause: AbortCause::Unsupported,
                    error: "unimplemented barrier object".into(),
                },
            },
        )
        .unwrap();
        let text = std::fs::read_to_string(dir.join(format!("{}.json", id.key()))).unwrap();
        assert!(text.contains("\"source_language\":\"amdgpu\""));
        assert!(text.contains("\"status\":\"unsupported\""));
        assert_eq!(text.contains("\"source_target\":\"gfx1250\""), declared);
        assert_eq!(text.contains("\"source_wave_size\":32"), declared);
        assert_eq!(text.contains("\"source_wave_kind\":\"wave\""), declared);
        assert!(!text.contains("\"launch\""));
        assert!(!text.contains("\"events\":["));
    }
}

#[test]
fn gfx1250_exec_masks_use_eight_hex_digits_and_native_check_labels() {
    let mut p = provenance(32);
    p.targets = vec!["gfx1250".into()];
    p.assumptions.push(Assumption::UnclusteredWorkgroup);
    p.instructions[3].kind = "s_endpgm";
    let mut b = GraphBuilder::new(p);
    for pc in [2, 3] {
        b.amd_event(
            0,
            ProgramPoint(pc),
            AmdEventKind::Instruction {
                exec_mask: u32::MAX as u64,
                reads: vec![],
                writes: vec![],
                scalar_mask_reads: vec![],
            },
        );
    }
    for thread in 0..32 {
        b.exit(ThreadIx(thread), ProgramPoint(3));
    }
    let text = exported("gfx1250_mask_format", &b.finish(Terminal::Completed));
    assert!(text.contains("0xffffffff"));
    assert!(!text.contains("0x00000000ffffffff"));
    assert!(!text.contains("CDNA counters"));
    assert!(!text.contains("CDNA S_BARRIER"));
    assert!(text.contains("\"status\":\"race-free\""));
}
