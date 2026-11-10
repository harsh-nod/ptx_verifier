//! Bounded CDNA4 no-return GLOBAL F32 add RMW record contract.
//!
//! The producer supplies mathematical-real addition. This checker binds the
//! single issuing lane, all scalar/address/data dependencies and the exact
//! aligned read-then-write pair. VM completion remains an independent check;
//! the distinct unordered class never borrows an ordinary VM FIFO frontier.
use std::collections::HashMap;

use volta_graph::{
    AccessMode, AmdArchitecture, AmdEventKind, AmdMemoryClass, AmdMemoryScope, AmdRegisterFile,
    EventGraph, EventKind, Footprint, OrderingKind, Proxy, Space,
};

use crate::Unresolved;

pub(super) fn validate(graph: &EventGraph, architecture: AmdArchitecture) -> Vec<Unresolved> {
    let mut errors = Vec::new();
    let mut instructions = HashMap::new();
    for record in graph.amd_events() {
        match &record.kind {
            AmdEventKind::Instruction { .. } => {
                instructions.insert(record.wave, record);
            }
            AmdEventKind::MemoryIssue {
                class,
                destinations,
                held_sources,
                ..
            } if *class == AmdMemoryClass::GlobalAtomicAddF32NoReturn => {
                let instruction = instructions.get(&record.wave).copied();
                let valid = architecture == AmdArchitecture::Gfx950
                    && instruction.is_some_and(|instruction| {
                        let AmdEventKind::Instruction {
                            exec_mask,
                            reads,
                            writes,
                            scalar_mask_reads,
                        } = &instruction.kind
                        else {
                            unreachable!()
                        };
                        graph.event(instruction.event).pc == graph.event(record.event).pc
                            && graph
                                .event(instruction.event)
                                .pc
                                .and_then(|pc| graph.provenance().instructions.get(pc.0 as usize))
                                .is_some_and(|info| info.kind == "atomic f32 add no return")
                            && exec_mask.count_ones() == 1
                            && writes.is_empty()
                            && destinations.is_empty()
                            && scalar_mask_reads.is_empty()
                            && held_sources == reads
                            && reads.len() == 4
                            && reads[..2].iter().all(|r| {
                                r.file == AmdRegisterFile::Vector
                                    && r.index < 256
                                    && r.lanes == *exec_mask
                            })
                            && reads[2..].iter().all(|r| {
                                r.file == AmdRegisterFile::Scalar
                                    && r.index <= 101
                                    && r.lanes == u64::MAX
                            })
                            && reads[2].index % 2 == 0
                            && reads[2].index + 1 == reads[3].index
                    });
                if !valid {
                    errors.push(Unresolved::at(record.event,
                        "CDNA4 atomic requires one active lane, two VGPR sources and its exact scalar-base pair"));
                    continue;
                }
                let instruction = instruction.unwrap();
                let AmdEventKind::Instruction { exec_mask, .. } = instruction.kind else {
                    unreachable!()
                };
                let thread = record.wave * 64 + exec_mask.trailing_zeros();
                let mut pair = Vec::new();
                for link in graph
                    .amd_memory_effects()
                    .iter()
                    .filter(|link| link.issue == record.event)
                {
                    let event = graph.event(link.effect);
                    let EventKind::Access(access) = event.kind else {
                        continue;
                    };
                    let access = graph.access(access);
                    let address = match access.footprint {
                        Footprint::Bytes { addr, width: 4 } if addr % 4 == 0 => Some(addr),
                        _ => None,
                    };
                    if access.attributed.0 != thread
                        || access.space != Space::Global
                        || access.ordering != OrderingKind::Atomic
                        || access.proxy != Proxy::Generic
                        || link.scope != AmdMemoryScope::Unspecified
                        || address.is_none()
                    {
                        errors.push(Unresolved::at(link.effect,
                            "CDNA4 atomic requires an aligned global F32 effect from its sole active lane"));
                    }
                    pair.push((link.effect, access.mode, address));
                }
                if !matches!(pair.as_slice(), [(read, AccessMode::Read, Some(a)), (write, AccessMode::Write, Some(b))]
                    if read < write && a == b)
                {
                    errors.push(Unresolved::at(
                        record.event,
                        "CDNA4 atomic must read then write exactly the same four-byte location",
                    ));
                }
            }
            _ => {}
        }
    }
    errors
}
