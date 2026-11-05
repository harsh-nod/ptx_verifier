//! Fixed gfx950 private DWORD records and literal-lane operand contracts.
//! Concrete scratch decoding, exact word transport and dispatch backing remain
//! producer/caller premises. Conservative VM0 admission failures are Unknown,
//! never evidence of a hardware register or memory hazard.

use std::collections::{HashMap, HashSet};

use volta_graph::{
    AccessMode, AmdArchitecture, AmdEvent, AmdEventKind, AmdMemoryClass, AmdRegister,
    AmdRegisterFile, Assumption, EventGraph, EventId, ThreadIx,
};

use crate::Unresolved;

pub(super) fn scratch(class: AmdMemoryClass) -> bool {
    matches!(
        class,
        AmdMemoryClass::ScratchLoad32 | AmdMemoryClass::ScratchStore32
    )
}

pub(super) fn valu(kind: &str) -> bool {
    matches!(
        kind,
        "vector ALU" | "trans ALU" | "shifted ALU" | "readlane" | "writelane"
    )
}

fn kind<'a>(graph: &'a EventGraph, record: &AmdEvent) -> Option<&'a str> {
    graph
        .events()
        .get(record.event)
        .and_then(|e| e.pc)
        .and_then(|pc| graph.provenance().instructions.get(pc.0 as usize))
        .map(|i| i.kind)
}

pub(super) fn present(graph: &EventGraph) -> bool {
    graph
        .provenance()
        .assumptions
        .iter()
        .any(|a| matches!(a, Assumption::FixedPrivateAllocation(_)))
        || graph.amd_events().iter().any(|r| {
            matches!(
                r.kind,
                AmdEventKind::PrivateMemoryAccess { .. }
                    | AmdEventKind::LaneRead { .. }
                    | AmdEventKind::LaneWrite { .. }
            ) || matches!(r.kind, AmdEventKind::MemoryIssue { class, .. } if scratch(class))
                || matches!(
                    kind(graph, r),
                    Some("scratch load" | "scratch store" | "readlane" | "writelane")
                )
        })
}

struct Transfer {
    instruction: EventId,
    wave: u32,
    mask: u64,
    mode: AccessMode,
    lanes: HashSet<ThreadIx>,
    offset: Option<u64>,
}

fn scalar(r: &AmdRegister) -> bool {
    r.file == AmdRegisterFile::Scalar && r.index <= 101 && r.lanes == u64::MAX
}

fn vector(r: &AmdRegister, mask: u64) -> bool {
    r.file == AmdRegisterFile::Vector && r.index < 256 && r.lanes == mask
}

/// Called only after structural graph validation. This is separate from the
/// general pending-counter replay: it admits only explicit-source-VM0 private
/// sequences, without deriving any hardware hazard from that restriction.
pub(super) fn validate(graph: &EventGraph, architecture: AmdArchitecture) -> Vec<Unresolved> {
    let mut errors = Vec::new();
    if !present(graph) {
        return errors;
    }
    if architecture != AmdArchitecture::Gfx950 {
        errors.push(Unresolved::global(
            "fixed private DWORD and literal-lane records require gfx950",
        ));
        return errors;
    }
    let limits: Vec<_> = graph
        .provenance()
        .assumptions
        .iter()
        .filter_map(|a| {
            if let Assumption::FixedPrivateAllocation(n) = a {
                Some(u64::from(*n))
            } else {
                None
            }
        })
        .collect();
    if limits.len() > 1 {
        errors.push(Unresolved::global(
            "fixed private allocation premise is duplicated",
        ));
    }
    let limit = (limits.len() == 1).then(|| limits[0]);
    let mut instructions = HashMap::<u32, &AmdEvent>::new();
    let mut claimed = HashSet::new();
    let mut transfers = HashMap::<EventId, Transfer>::new();
    let mut held = HashMap::<u32, Vec<AmdRegister>>::new();
    let mut loaded = HashMap::<u32, Vec<AmdRegister>>::new();
    let mut uses_scratch = false;
    for record in graph.amd_events() {
        match &record.kind {
            AmdEventKind::Instruction {
                exec_mask,
                reads,
                writes,
                ..
            } => {
                if let Some(previous) = instructions.insert(record.wave, record) {
                    require_semantic(graph, previous, &claimed, &mut errors);
                }
                if held.get(&record.wave).is_some_and(|sources| {
                    writes
                        .iter()
                        .any(|w| sources.iter().any(|s| w.overlaps(*s)))
                }) {
                    errors.push(Unresolved::at(record.event,
                        "private VM0 profile does not admit store-data overwrite before an explicit VM0"));
                }
                if loaded.get(&record.wave).is_some_and(|destinations| {
                    reads
                        .iter()
                        .chain(writes)
                        .any(|r| destinations.iter().any(|d| r.overlaps(*d)))
                }) {
                    errors.push(Unresolved::at(record.event,
                        "private VM0 profile does not admit load-destination read or overwrite before an explicit VM0"));
                }
                match kind(graph, record) {
                    Some("scratch load" | "scratch store") => {
                        uses_scratch = true;
                        if *exec_mask == 0 && (!reads.is_empty() || !writes.is_empty()) {
                            errors.push(Unresolved::at(record.event, "inactive scratch instruction must not observe address/data registers or write destinations"));
                        }
                        if kind(graph, record) == Some("scratch load")
                            && held.get(&record.wave).is_some_and(|s| !s.is_empty())
                            && *exec_mask != 0
                        {
                            errors.push(Unresolved::at(record.event,
                                "private VM0 profile requires an explicit VM0 between a private store and a later private load"));
                        }
                    }
                    Some("s_endpgm")
                        if held.get(&record.wave).is_some_and(|s| !s.is_empty())
                            || loaded.get(&record.wave).is_some_and(|s| !s.is_empty()) =>
                    {
                        errors.push(Unresolved::at(record.event,
                            "private VM0 profile requires a source VM0 before ending with pending private accesses"));
                    }
                    _ => {}
                }
            }
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations,
                held_sources,
            } if scratch(*class) => {
                uses_scratch = true;
                let Some(instruction) = associated(graph, record, &instructions, &mut errors)
                else {
                    continue;
                };
                let AmdEventKind::Instruction {
                    exec_mask,
                    reads,
                    writes,
                    scalar_mask_reads,
                } = &instruction.kind
                else {
                    unreachable!()
                };
                let load = *class == AmdMemoryClass::ScratchLoad32;
                let expected_kind = if load {
                    "scratch load"
                } else {
                    "scratch store"
                };
                let address = reads.iter().filter(|r| scalar(r)).count() == 1;
                let roles = if load {
                    reads.len() == 1
                        && address
                        && writes.len() == 1
                        && vector(&writes[0], *exec_mask)
                        && held_sources.is_empty()
                } else {
                    reads.len() == 2
                        && address
                        && writes.is_empty()
                        && reads.iter().filter(|r| vector(r, *exec_mask)).count() == 1
                        && held_sources.len() == 1
                        && vector(&held_sources[0], *exec_mask)
                        && reads.contains(&held_sources[0])
                };
                if kind(graph, instruction) != Some(expected_kind)
                    || *exec_mask == 0
                    || counters.as_slice() != [(volta_graph::AmdCounter::Vm, 1)]
                    || destinations != writes
                    || !scalar_mask_reads.is_empty()
                    || !roles
                    || !claimed.insert(instruction.event)
                {
                    errors.push(Unresolved::at(record.event, "scratch DWORD issue does not match its exact gfx950 source/operand/counter profile"));
                }
                if load {
                    loaded.entry(record.wave).or_default().extend(destinations);
                } else {
                    held.entry(record.wave).or_default().extend(held_sources);
                }
                if transfers
                    .insert(
                        record.event,
                        Transfer {
                            instruction: instruction.event,
                            wave: record.wave,
                            mask: *exec_mask,
                            mode: if load {
                                AccessMode::Read
                            } else {
                                AccessMode::Write
                            },
                            lanes: HashSet::new(),
                            offset: None,
                        },
                    )
                    .is_some()
                {
                    errors.push(Unresolved::at(
                        record.event,
                        "duplicate private memory issue",
                    ));
                }
            }
            AmdEventKind::PrivateMemoryAccess {
                issue,
                thread,
                offset,
                width,
                kind: access_kind,
            } => {
                uses_scratch = true;
                let Some(t) = transfers.get_mut(issue) else {
                    errors.push(Unresolved::at(
                        record.event,
                        "private access lacks a preceding selected scratch issue",
                    ));
                    continue;
                };
                let current = instructions.get(&record.wave).map(|r| r.event);
                let uniform = t.offset.is_none_or(|first| first == *offset);
                t.offset.get_or_insert(*offset);
                if record.wave != t.wave
                    || current != Some(t.instruction)
                    || graph.event(*issue).pc != graph.event(record.event).pc
                    || issue.0 >= record.event.0
                    || thread.0 >= graph.threads()
                    || thread.0 / 64 != t.wave
                    || t.mask & (1u64 << (thread.0 % 64)) == 0
                    || !uniform
                    || *width != 4
                    || *access_kind != t.mode
                    || !offset.is_multiple_of(4)
                    || !offset
                        .checked_add(4)
                        .zip(limit)
                        .is_some_and(|(end, bound)| end <= bound)
                    || !t.lanes.insert(*thread)
                {
                    errors.push(Unresolved::at(record.event, "private DWORD access has invalid membership, width, extent or source association"));
                }
            }
            AmdEventKind::Wait { vmcnt: Some(0), .. } => {
                if let Some(instruction) = instructions.get(&record.wave)
                    && kind(graph, instruction) == Some("wait")
                    && graph.event(instruction.event).pc == graph.event(record.event).pc
                {
                    held.remove(&record.wave);
                    loaded.remove(&record.wave);
                }
            }
            AmdEventKind::LaneRead { lane } | AmdEventKind::LaneWrite { lane } => {
                let Some(instruction) = associated(graph, record, &instructions, &mut errors)
                else {
                    continue;
                };
                let AmdEventKind::Instruction {
                    reads,
                    writes,
                    scalar_mask_reads,
                    ..
                } = &instruction.kind
                else {
                    unreachable!()
                };
                let read = matches!(record.kind, AmdEventKind::LaneRead { .. });
                let valid_lane = *lane < 64
                    && record
                        .wave
                        .checked_mul(64)
                        .and_then(|n| n.checked_add(u32::from(*lane)))
                        .is_some_and(|n| n < graph.threads());
                let mask = 1u64.checked_shl(u32::from(*lane)).unwrap_or(0);
                let roles = reads.len() == 1
                    && writes.len() == 1
                    && if read {
                        vector(&reads[0], mask) && scalar(&writes[0])
                    } else {
                        scalar(&reads[0]) && vector(&writes[0], mask)
                    };
                if !valid_lane
                    || !roles
                    || !scalar_mask_reads.is_empty()
                    || kind(graph, instruction) != Some(if read { "readlane" } else { "writelane" })
                    || !claimed.insert(instruction.event)
                {
                    errors.push(Unresolved::at(record.event, "literal-lane marker does not match its exact launched-lane operand contract"));
                }
            }
            _ => {}
        }
    }
    for instruction in instructions.values() {
        require_semantic(graph, instruction, &claimed, &mut errors);
    }
    if matches!(graph.terminal(), volta_graph::Terminal::Completed)
        && (held.values().any(|sources| !sources.is_empty())
            || loaded.values().any(|destinations| !destinations.is_empty()))
    {
        errors.push(Unresolved::global(
            "completed private execution retains an access without an explicit source VM0",
        ));
    }
    if uses_scratch
        && (!graph.provenance().assumes(Assumption::XnackReplayDisabled)
            || graph
                .provenance()
                .targets
                .iter()
                .any(|t| t.split(':').any(|feature| feature == "xnack+")))
    {
        errors.push(Unresolved::global("selected scratch profile requires XNACK replay disabled without a contradictory target feature"));
    }
    if uses_scratch && limit.is_none_or(|bytes| bytes == 0) {
        errors.push(Unresolved::global("scratch execution requires exactly one positive fixed-private valid-dispatch allocation premise"));
    }
    for (issue, t) in transfers {
        let expected: HashSet<_> = (0..64)
            .filter(|&lane| t.mask & (1u64 << lane) != 0)
            .map(|lane| ThreadIx(t.wave.saturating_mul(64).saturating_add(lane)))
            .collect();
        if t.lanes != expected || graph.amd_memory_effects().iter().any(|e| e.issue == issue) {
            errors.push(Unresolved::at(issue, "scratch issue requires exactly one private access per active physical lane and no Global/Shared effects"));
        }
    }
    errors
}

fn associated<'a>(
    graph: &EventGraph,
    record: &AmdEvent,
    instructions: &HashMap<u32, &'a AmdEvent>,
    errors: &mut Vec<Unresolved>,
) -> Option<&'a AmdEvent> {
    let instruction = instructions.get(&record.wave).copied();
    if !instruction.is_some_and(|i| {
        i.event.0 < record.event.0 && graph.event(i.event).pc == graph.event(record.event).pc
    }) {
        errors.push(Unresolved::at(
            record.event,
            "private/lane semantic record lacks its preceding same-wave instruction",
        ));
        return None;
    }
    instruction
}

fn require_semantic(
    graph: &EventGraph,
    instruction: &AmdEvent,
    claimed: &HashSet<EventId>,
    errors: &mut Vec<Unresolved>,
) {
    let AmdEventKind::Instruction { exec_mask, .. } = instruction.kind else {
        return;
    };
    let required = match kind(graph, instruction) {
        Some("readlane" | "writelane") => true,
        Some("scratch load" | "scratch store") => exec_mask != 0,
        _ => false,
    };
    if required && !claimed.contains(&instruction.event) {
        errors.push(Unresolved::at(
            instruction.event,
            "selected private/lane instruction lacks its mandatory semantic record",
        ));
    }
}
