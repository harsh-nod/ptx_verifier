use volta_graph::*;
use volta_graph_check::amdgpu::tensor_bounds::{
    tensor_bounds_candidate, validate_tensor_bounds_prefix,
};
use volta_graph_check::{GraphConclusion, check_graph};

fn scalar(index: u16) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Scalar,
        index,
        lanes: 0,
    }
}
fn descriptor() -> AmdTensorDescriptor {
    AmdTensorDescriptor {
        d0: [1, 256, 0x10000, 0x80000000],
        d1: [2 << 16, 64 << 16, 1 << 16, 64 << 16, 1, 64, 0, 0],
        d2: [0; 4],
        d3: [0; 4],
    }
}
fn graph(
    mut change: impl FnMut(&mut Provenance, &mut AmdTensorDescriptor, &mut [u16; 4], &mut u64),
    load: bool,
    pending: bool,
    terminal: Option<Terminal>,
) -> EventGraph {
    let mut provenance = Provenance {
        kernel: "tensor_fault".into(),
        block_dim: (64, 1, 1),
        grid_dim: (1, 1, 1),
        workgroup_id: (0, 0, 0),
        targets: vec!["gfx1250".into()],
        assumptions: vec![
            Assumption::UnclusteredWorkgroup,
            Assumption::ConfiguredLdsBytes(256),
        ],
        instructions: vec![
            InstructionInfo {
                kind: "scalar memory",
                span: Some((0, 10)),
            },
            InstructionInfo {
                kind: "tensor memory",
                span: Some((11, 40)),
            },
        ],
    };
    let mut descriptor = descriptor();
    let mut sources = [4, 12, 20, 20];
    let mut mask = 1;
    change(&mut provenance, &mut descriptor, &mut sources, &mut mask);
    let mut b = GraphBuilder::new(provenance);
    if pending {
        b.amd_event(
            0,
            ProgramPoint(0),
            AmdEventKind::Instruction {
                exec_mask: 1,
                reads: vec![],
                writes: vec![scalar(4)],
                scalar_mask_reads: vec![],
            },
        );
        let issue = b.amd_event(
            0,
            ProgramPoint(0),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::ScalarLoad,
                counters: vec![(AmdCounter::Km, 1), (AmdCounter::X, 1)],
                destinations: vec![scalar(4)],
                held_sources: vec![],
            },
        );
        let effect = b.thread_access(
            ThreadIx(0),
            ProgramPoint(0),
            MemAccess {
                space: Space::Global,
                mode: AccessMode::Read,
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Generic,
                footprint: Footprint::Bytes {
                    addr: 0x10000,
                    width: 4,
                },
                role: OperandRole::Plain,
                attributed: ThreadIx(0),
                value: None,
            },
        );
        b.amd_memory_effect(issue, effect);
    }
    b.amd_event(
        0,
        ProgramPoint(1),
        AmdEventKind::Instruction {
            exec_mask: mask,
            reads: (4..8).chain(12..24).map(scalar).collect(),
            writes: vec![],
            scalar_mask_reads: vec![],
        },
    );
    b.amd_event(
        0,
        ProgramPoint(1),
        AmdEventKind::TensorAccessFault {
            load,
            descriptor,
            sources,
        },
    );
    b.finish(terminal.unwrap_or(Terminal::Aborted {
        thread: Some(ThreadIx(0)),
        pc: Some(ProgramPoint(1)),
        cause: AbortCause::Error,
        reason: TENSOR_BOUNDS_ABORT_REASON.into(),
    }))
}

#[test]
fn attempted_load_and_store_have_typed_bounds_but_no_full_graph_rejection() {
    for load in [true, false] {
        let g = graph(|_, _, _, _| {}, load, false, None);
        let cert = tensor_bounds_candidate(&g).unwrap();
        let fault = validate_tensor_bounds_prefix(&g, &cert).unwrap();
        assert_eq!(
            (fault.address, fault.bytes, fault.configured_lds_bytes),
            (256, 256, 256)
        );
        assert_eq!(
            fault.access,
            if load {
                AccessMode::Write
            } else {
                AccessMode::Read
            }
        );
        assert!(matches!(
            check_graph(&g).conclusion(),
            GraphConclusion::Unknown { .. }
        ));
        assert!(g.accesses().is_empty());
    }
}

#[test]
fn exact_prefix_identity_refuses_stale_or_forged_certificates() {
    let g = graph(|_, _, _, _| {}, true, false, None);
    let cert = tensor_bounds_candidate(&g).unwrap();
    for field in 0..8 {
        let mut c = cert.clone();
        match field {
            0 => c.amd_records += 1,
            1 => c.graph_events += 1,
            2 => c.event = EventId(0),
            3 => c.provenance.workgroup_id = (1, 0, 0),
            4 => c.provenance.targets = vec!["gfx950".into()],
            5 => c
                .provenance
                .assumptions
                .push(Assumption::ConfiguredLdsBytes(512)),
            6 => {
                if let AmdEventKind::TensorAccessFault { descriptor, .. } = &mut c.fault_record.kind
                {
                    descriptor.d0[1] += 4;
                }
            }
            _ => {
                c.event = EventId(u32::MAX);
                c.fault_record.event = EventId(u32::MAX);
            }
        }
        assert!(
            validate_tensor_bounds_prefix(&g, &c).is_err(),
            "field{field}"
        );
    }
}

#[test]
fn malformed_instruction_source_pc_is_refused_before_prefix_replay() {
    let g = graph(|p, _, _, _| p.instructions.clear(), true, false, None);
    let certificate = tensor_bounds_candidate(&g).unwrap();
    let errors = validate_tensor_bounds_prefix(&g, &certificate).unwrap_err();
    assert!(
        errors
            .iter()
            .any(|error| error.reason.contains("program point")),
        "{errors:?}"
    );
}

#[test]
fn disabled_safe_unsupported_or_bad_source_and_geometry_records_never_certify() {
    for field in 0..12 {
        let g = graph(
            |p, d, s, m| match field {
                0 => d.d0[1] = 0, // exact boundary, fits 256 bytes
                1 => d.d0[0] = 0,
                2 => d.d2[0] = 1,
                3 => d.d1[0] |= 1,
                4 => s[0] = 40,
                5 => *m = 0,
                6 => p.targets = vec!["gfx950".into()],
                7 => p.workgroup_id = (1, 0, 0),
                8 => p
                    .assumptions
                    .retain(|a| !matches!(a, Assumption::ConfiguredLdsBytes(_))),
                9 => p.assumptions.push(Assumption::ConfiguredLdsBytes(128)),
                10 => {
                    p.assumptions = vec![
                        Assumption::UnclusteredWorkgroup,
                        Assumption::ConfiguredLdsBytes(1 << 32),
                    ]
                }
                _ => p.instructions[1].kind = "scalar ALU",
            },
            true,
            false,
            None,
        );
        assert!(
            validate_tensor_bounds_prefix(&g, &tensor_bounds_candidate(&g).unwrap()).is_err(),
            "field{field}"
        );
    }
}

#[test]
fn unresolved_descriptor_load_and_generic_or_completed_terminals_are_refused() {
    let pending = graph(|_, _, _, _| {}, true, true, None);
    assert!(
        validate_tensor_bounds_prefix(&pending, &tensor_bounds_candidate(&pending).unwrap())
            .is_err()
    );
    for t in [
        Terminal::Completed,
        Terminal::Aborted {
            thread: Some(ThreadIx(0)),
            pc: Some(ProgramPoint(1)),
            cause: AbortCause::Error,
            reason: "unrelated error".into(),
        },
    ] {
        let g = graph(|_, _, _, _| {}, true, false, Some(t));
        assert!(validate_tensor_bounds_prefix(&g, &tensor_bounds_candidate(&g).unwrap()).is_err());
    }
}

#[test]
fn fabricated_effects_and_unreleased_barrier_reachability_cannot_certify() {
    let original = graph(|_, _, _, _| {}, true, false, None);
    for blocked in [false, true] {
        let mut provenance = original.provenance().clone();
        provenance.instructions.push(InstructionInfo {
            kind: "barrier wait",
            span: Some((41, 50)),
        });
        let mut b = GraphBuilder::new(provenance);
        if blocked {
            b.amd_event(
                0,
                ProgramPoint(2),
                AmdEventKind::Instruction {
                    exec_mask: 1,
                    reads: vec![],
                    writes: vec![],
                    scalar_mask_reads: vec![],
                },
            );
            b.amd_event(
                0,
                ProgramPoint(2),
                AmdEventKind::SplitBarrierWait {
                    barrier: -1,
                    generation: 0,
                },
            );
        }
        let mut fault = EventId(0);
        for record in original.amd_events() {
            fault = b.amd_event(
                record.wave,
                original.event(record.event).pc.unwrap(),
                record.kind.clone(),
            );
        }
        if !blocked {
            let effect = b.thread_access(
                ThreadIx(0),
                ProgramPoint(1),
                MemAccess {
                    space: Space::Shared,
                    mode: AccessMode::Write,
                    ordering: OrderingKind::Ordinary,
                    proxy: Proxy::Generic,
                    footprint: Footprint::Bytes {
                        addr: 256,
                        width: 4,
                    },
                    role: OperandRole::Plain,
                    attributed: ThreadIx(0),
                    value: None,
                },
            );
            b.amd_memory_effect(fault, effect);
        }
        let g = b.finish(original.terminal().clone());
        let candidate = tensor_bounds_candidate(&g).unwrap();
        assert!(validate_tensor_bounds_prefix(&g, &candidate).is_err());
    }
}
