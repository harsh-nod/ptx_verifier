//! GFX12.5 completion and execution synchronization. The u64 mask storage is
//! shared with old graphs; only its low 32 bits describe this target's waves.
//!
//! Semantic references: LLVM 5fd50ec8e07abb94e203933017e8d6e40fb51824,
//! AMDGPUHWEvents.cpp, SIInsertWaitcnts.cpp and
//! AMDGPUExecutionSynchronization.md. X_CNT protects address-translation replay
//! operands, independently of memory completion. Signals publish only already
//! completed effects. Neither trace order nor a signal fabricates a data wait.

use super::*;
use volta_graph::{AccessMode, AmdWmmaKind, Assumption, ThreadIx};

const WAVE: usize = 32;

fn flat_profile(class: AmdMemoryClass) -> Option<(Space, AccessMode)> {
    Some(match class {
        AmdMemoryClass::FlatGlobalLoad => (Space::Global, AccessMode::Read),
        AmdMemoryClass::FlatGlobalStore => (Space::Global, AccessMode::Write),
        _ => return None,
    })
}

fn maximum(counter: AmdCounter) -> Option<u16> {
    match counter {
        AmdCounter::Load
        | AmdCounter::Store
        | AmdCounter::Ds
        | AmdCounter::X
        | AmdCounter::Async => Some(63),
        AmdCounter::Km => Some(31),
        // The pinned LLVM hardware-limits helper does not specify TENSOR_CNT's
        // hardware limit. Zero is supported; nonzero waits remain inconclusive.
        AmdCounter::Tensor => Some(u16::MAX),
        _ => None,
    }
}

fn charges(class: AmdMemoryClass) -> Option<Vec<(AmdCounter, u16)>> {
    use AmdCounter::*;
    Some(match class {
        AmdMemoryClass::VectorLoad => vec![(Load, 1), (X, 1)],
        AmdMemoryClass::VectorStore => vec![(Store, 1), (X, 1)],
        AmdMemoryClass::GlobalAtomicAddF32NoReturn => vec![(Store, 1), (X, 1)],
        AmdMemoryClass::FlatGlobalLoad => {
            vec![(Load, 1), (Ds, 1), (X, 1)]
        }
        AmdMemoryClass::FlatGlobalStore => {
            vec![(Store, 1), (Ds, 1), (X, 1)]
        }
        AmdMemoryClass::ScalarLoad => vec![(Km, 1), (X, 1)],
        AmdMemoryClass::Ds | AmdMemoryClass::CrossLane => vec![(Ds, 1)],
        AmdMemoryClass::AsyncLoadToLds => vec![(Load, 1), (X, 1), (Async, 1)],
        AmdMemoryClass::AsyncStoreFromLds => vec![(Store, 1), (X, 1), (Async, 1)],
        AmdMemoryClass::TensorLoadToLds | AmdMemoryClass::TensorStoreFromLds => vec![(Tensor, 1)],
        _ => return None,
    })
}

fn replay_group(class: AmdMemoryClass) -> Option<bool> {
    match class {
        AmdMemoryClass::ScalarLoad => Some(false),
        AmdMemoryClass::VectorLoad
        | AmdMemoryClass::VectorStore
        | AmdMemoryClass::GlobalAtomicAddF32NoReturn
        | AmdMemoryClass::AsyncLoadToLds
        | AmdMemoryClass::AsyncStoreFromLds
        | AmdMemoryClass::FlatGlobalLoad
        | AmdMemoryClass::FlatGlobalStore => Some(true),
        _ => None,
    }
}

fn expected(kind: &str, mask: u64) -> Option<Option<&'static str>> {
    Some(match kind {
        "scalar memory" => Some("memory"),
        "vector memory"
        | "LDS"
        | "async memory"
        | "tensor memory"
        | "atomic f32 add no return"
        | "flat memory"
            if mask != 0 =>
        {
            Some("memory")
        }
        "wait" => Some("wait"),
        "s_nop" => Some("delay"),
        "s_delay_alu" => Some("delay alu"),
        "barrier signal" => Some("signal"),
        "barrier wait" => Some("barrier wait"),
        "WMMA" => Some("wmma"),
        "scalar ALU"
        | "vector ALU"
        | "trans ALU"
        | "shifted ALU"
        | "branch"
        | "control"
        | "xcnt drain"
        | "s_endpgm"
        | "vector memory"
        | "LDS"
        | "async memory"
        | "tensor memory"
        | "flat memory"
        | "atomic f32 add no return" => None,
        _ => return None,
    })
}

fn registers(regs: &[AmdRegister], mask: u64, event: EventId, unresolved: &mut Vec<Unresolved>) {
    for reg in regs {
        let valid = match reg.file {
            AmdRegisterFile::Scalar => reg.index <= 106 || reg.index == 126,
            AmdRegisterFile::Temporary => reg.index < 16,
            AmdRegisterFile::Vector => reg.index < 1024 && reg.lanes != 0 && reg.lanes & !mask == 0,
            AmdRegisterFile::Accumulator => false,
        };
        if !valid {
            unresolved.push(Unresolved::at(
                event,
                "invalid gfx1250 register namespace, index or physical lane mask",
            ));
        }
    }
}

fn claim<'a>(
    graph: &EventGraph,
    record: &volta_graph::AmdEvent,
    instructions: &'a mut HashMap<u32, InstructionRecord>,
    kind: &str,
    unresolved: &mut Vec<Unresolved>,
) -> Option<&'a InstructionRecord> {
    // A semantic record cannot turn an ordinary ALU or masked-out memory
    // instruction into a different operation merely by borrowing its PC.
    if instructions
        .get(&record.wave)
        .is_some_and(|i| i.expected != Some(kind))
    {
        unresolved.push(Unresolved::at(
            record.event,
            "gfx1250 semantic event disagrees with its instruction provenance",
        ));
        return None;
    }
    claim_instruction(graph, record, instructions, kind, unresolved)
}

fn vector_tuple(registers: &[AmdRegister], count: usize) -> bool {
    registers.len() == count
        && registers.first().is_some_and(|first| {
            registers.iter().enumerate().all(|(offset, register)| {
                register.file == AmdRegisterFile::Vector
                    && register.index as usize == first.index as usize + offset
                    && register.lanes == u32::MAX as u64
            })
        })
}

fn contract(graph: &EventGraph) -> AmdTraceResult {
    if let Err(defects) = graph.validate() {
        return PropertyResult::Unknown(
            defects
                .into_iter()
                .map(|d| Unresolved {
                    events: d
                        .event
                        .filter(|e| graph.events().get(*e).is_some())
                        .into_iter()
                        .collect(),
                    reason: d.message,
                })
                .collect(),
        );
    }
    let mut unresolved = Vec::new();
    let mut atomic_pairs =
        HashMap::<(EventId, ThreadIx), (Option<(EventId, u64)>, Option<(EventId, u64)>)>::new();
    if graph.provenance().assumes(Assumption::XnackReplayDisabled) {
        unresolved.push(Unresolved::global(
            "gfx1250 XNACK is hardwired on; a replay-disabled premise is invalid",
        ));
    }
    if !graph.provenance().assumes(Assumption::UnclusteredWorkgroup) {
        unresolved.push(Unresolved::global(
            "gfx1250 requires the explicit unclustered-workgroup execution envelope",
        ));
    }
    if graph
        .provenance()
        .assumes(Assumption::ConfiguredSharedAllocationLayout)
        != !graph.shared_allocation_layout().is_empty()
    {
        unresolved.push(Unresolved::global(
            "configured LDS layout and its provenance premise disagree",
        ));
    }
    if graph.provenance().grid_dim != (1, 1, 1) {
        unresolved.push(Unresolved::global(
            "gfx1250 graph contract analyzes exactly one workgroup",
        ));
    }
    let waves = (graph.threads() as usize).div_ceil(WAVE);
    let mut seen = vec![false; waves];
    let mut instructions = HashMap::<u32, InstructionRecord>::new();
    let mut issues = HashMap::new();
    let mut instruction_count = 0;
    let mut ended = HashSet::new();
    for record in graph.amd_events() {
        let valid = (graph.threads() as usize - record.wave as usize * WAVE).min(WAVE);
        let physical_mask = (1u64 << valid) - 1;
        if ended.contains(&record.wave) {
            unresolved.push(Unresolved::at(
                record.event,
                "gfx1250 wave recorded an instruction after S_ENDPGM",
            ));
        }
        match &record.kind {
            AmdEventKind::Instruction {
                exec_mask,
                reads,
                writes,
                scalar_mask_reads,
            } => {
                instruction_count += 1;
                seen[record.wave as usize] = true;
                if exec_mask & !physical_mask != 0 {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "gfx1250 EXEC contains a nonexistent lane or a wave64 high bit",
                    ));
                }
                registers(reads, physical_mask, record.event, &mut unresolved);
                registers(writes, physical_mask, record.event, &mut unresolved);
                if scalar_mask_reads.iter().any(|r| {
                    r.file != AmdRegisterFile::Scalar || r.index == 126 || !reads.contains(r)
                }) {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "invalid carry/condition role in gfx1250 register signature",
                    ));
                }
                if let Some(previous) = instructions.get(&record.wave) {
                    check_missing_semantic(previous, &mut unresolved);
                }
                let pc = graph.event(record.event).pc;
                let kind = pc.map(|p| graph.provenance().instructions[p.0 as usize].kind);
                let required = kind.and_then(|k| expected(k, *exec_mask));
                if kind == Some("s_endpgm") {
                    ended.insert(record.wave);
                }
                if required.is_none() {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "unrecognized gfx1250 instruction provenance kind",
                    ));
                }
                instructions.insert(
                    record.wave,
                    InstructionRecord {
                        event: record.event,
                        pc,
                        exec_mask: *exec_mask,
                        reads: reads.clone(),
                        writes: writes.clone(),
                        expected: required.flatten(),
                        semantic: false,
                    },
                );
            }
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations,
                held_sources,
            } => {
                if matches!(
                    class,
                    AmdMemoryClass::FlatLdsLoad | AmdMemoryClass::FlatLdsStore
                ) {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "gfx1250 FLAT LDS-aperture counter and replay-source profile is not pinned",
                    ));
                }
                let instruction =
                    claim(graph, record, &mut instructions, "memory", &mut unresolved);
                registers(destinations, physical_mask, record.event, &mut unresolved);
                registers(held_sources, physical_mask, record.event, &mut unresolved);
                let correct_destinations = match class {
                    AmdMemoryClass::ScalarLoad => {
                        !destinations.is_empty() && destinations.iter().all(|r| r.is_uniform())
                    }
                    AmdMemoryClass::VectorLoad
                    | AmdMemoryClass::FlatGlobalLoad
                    | AmdMemoryClass::FlatLdsLoad
                    | AmdMemoryClass::CrossLane => {
                        !destinations.is_empty()
                            && destinations
                                .iter()
                                .all(|r| r.file == AmdRegisterFile::Vector)
                    }
                    AmdMemoryClass::Ds => destinations
                        .iter()
                        .all(|r| r.file == AmdRegisterFile::Vector),
                    AmdMemoryClass::VectorStore
                    | AmdMemoryClass::FlatGlobalStore
                    | AmdMemoryClass::FlatLdsStore
                    | AmdMemoryClass::GlobalAtomicAddF32NoReturn
                    | AmdMemoryClass::AsyncLoadToLds
                    | AmdMemoryClass::AsyncStoreFromLds
                    | AmdMemoryClass::TensorLoadToLds
                    | AmdMemoryClass::TensorStoreFromLds => destinations.is_empty(),
                    _ => false,
                };
                if !correct_destinations {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "gfx1250 memory class has invalid destination register roles",
                    ));
                }
                if let Some(instruction) = instruction {
                    let source_kind =
                        graph.provenance().instructions[instruction.pc.unwrap().0 as usize].kind;
                    let correct_kind = match class {
                        AmdMemoryClass::ScalarLoad => source_kind == "scalar memory",
                        AmdMemoryClass::VectorLoad | AmdMemoryClass::VectorStore => {
                            source_kind == "vector memory"
                        }
                        AmdMemoryClass::FlatGlobalLoad
                        | AmdMemoryClass::FlatGlobalStore
                        | AmdMemoryClass::FlatLdsLoad
                        | AmdMemoryClass::FlatLdsStore => source_kind == "flat memory",
                        AmdMemoryClass::GlobalAtomicAddF32NoReturn => {
                            source_kind == "atomic f32 add no return"
                        }
                        AmdMemoryClass::Ds | AmdMemoryClass::CrossLane => source_kind == "LDS",
                        AmdMemoryClass::AsyncLoadToLds | AmdMemoryClass::AsyncStoreFromLds => {
                            source_kind == "async memory"
                        }
                        AmdMemoryClass::TensorLoadToLds | AmdMemoryClass::TensorStoreFromLds => {
                            source_kind == "tensor memory"
                        }
                        _ => false,
                    };
                    if !correct_kind {
                        unresolved.push(Unresolved::at(
                            record.event,
                            "gfx1250 operation class disagrees with its instruction provenance",
                        ));
                    }
                    if destinations.len() != instruction.writes.len()
                        || !destinations.iter().all(|r| instruction.writes.contains(r))
                    {
                        unresolved.push(Unresolved::at(
                            record.event,
                            "memory destinations differ from the instruction's writes",
                        ));
                    }
                    if replay_group(*class).is_some()
                        && (held_sources.len() != instruction.reads.len()
                            || !instruction.reads.iter().all(|r| held_sources.contains(r)))
                    {
                        unresolved.push(Unresolved::at(
                            record.event,
                            "replay-sensitive memory issue must retain every instruction source",
                        ));
                    }
                    if !held_sources.iter().all(|r| instruction.reads.contains(r)) {
                        unresolved.push(Unresolved::at(
                            record.event,
                            "memory held source is missing from its instruction",
                        ));
                    }
                    if flat_profile(*class).is_some()
                        && !instruction
                            .reads
                            .iter()
                            .any(|r| r.file == AmdRegisterFile::Scalar && r.index == 126)
                    {
                        unresolved.push(Unresolved::at(
                            record.event,
                            "gfx1250 FLAT requires its implicit EXEC replay source",
                        ));
                    }
                    if *class == AmdMemoryClass::GlobalAtomicAddF32NoReturn
                        && (instruction.exec_mask.count_ones() != 1
                            || !held_sources
                                .iter()
                                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == 126))
                    {
                        unresolved.push(Unresolved::at(record.event,
                            "selected atomic RMW requires one active lane and its implicit EXEC source"));
                    }
                }
                if !charges(*class).is_some_and(|expected| {
                    expected.len() == counters.len()
                        && expected.iter().all(|c| counters.contains(c))
                }) {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "gfx1250 counter charges do not match the native operation class",
                    ));
                }
                issues.insert(
                    record.event,
                    (record, instruction.map_or(0, |i| i.exec_mask)),
                );
            }
            AmdEventKind::WaitCounters { thresholds } => {
                claim(graph, record, &mut instructions, "wait", &mut unresolved);
                let mut distinct = HashSet::new();
                if thresholds.is_empty()
                    || thresholds.iter().any(|(counter, value)| {
                        !distinct.insert(*counter)
                            || maximum(*counter).is_none_or(|max| *value > max)
                    })
                {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "empty, duplicate, legacy or out-of-range gfx1250 wait threshold",
                    ));
                }
            }
            AmdEventKind::SplitBarrierSignal {
                barrier, exec_mask, ..
            } => {
                let instruction =
                    claim(graph, record, &mut instructions, "signal", &mut unresolved);
                if instruction.is_some_and(|i| i.exec_mask != *exec_mask) {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "split-barrier EXEC differs from its instruction record",
                    ));
                }
                if *barrier != -1 || exec_mask & !physical_mask != 0 {
                    unresolved.push(Unresolved::at(record.event, "only the shader workgroup barrier -1 is implemented; invalid EXEC or privileged/named/cluster barrier"));
                }
            }
            AmdEventKind::SplitBarrierWait { barrier, .. } => {
                claim(
                    graph,
                    record,
                    &mut instructions,
                    "barrier wait",
                    &mut unresolved,
                );
                if *barrier != -1 {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "unsupported gfx1250 barrier object",
                    ));
                }
            }
            AmdEventKind::SplitBarrierRelease { barrier, .. } => {
                if *barrier != -1 {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "unsupported gfx1250 barrier release object",
                    ));
                }
            }
            AmdEventKind::Delay { cycles } => {
                claim(graph, record, &mut instructions, "delay", &mut unresolved);
                if !(1..=16).contains(cycles) {
                    unresolved.push(Unresolved::at(record.event, "invalid S_NOP duration"));
                }
            }
            AmdEventKind::DelayAlu {
                instid0,
                instskip,
                instid1,
            } => {
                claim(
                    graph,
                    record,
                    &mut instructions,
                    "delay alu",
                    &mut unresolved,
                );
                if instid0.encoding().is_none()
                    || instid1.is_some_and(|d| d.encoding().is_none())
                    || *instskip > 5
                {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "unsupported S_DELAY_ALU selector or skip encoding",
                    ));
                }
            }
            AmdEventKind::WmmaIssue {
                destinations,
                sources_ab,
                accumulator,
                kind,
            } => {
                let instruction = claim(graph, record, &mut instructions, "wmma", &mut unresolved);
                for regs in [destinations, sources_ab, accumulator] {
                    registers(regs, physical_mask, record.event, &mut unresolved);
                }
                let inputs = kind.input_registers();
                if physical_mask != u32::MAX as u64
                    || instruction.is_none_or(|i| i.exec_mask != u32::MAX as u64)
                    || !vector_tuple(destinations, kind.destination_registers())
                    || sources_ab.len() != 2 * inputs
                    || !vector_tuple(&sources_ab[..sources_ab.len().min(inputs)], inputs)
                    || !vector_tuple(&sources_ab[sources_ab.len().min(inputs)..], inputs)
                    || (!accumulator.is_empty()
                        && !vector_tuple(accumulator, kind.destination_registers()))
                {
                    unresolved.push(Unresolved::at(
                        record.event,
                        "WMMA requires a full physical wave32 and exact contiguous operand tuples",
                    ));
                }
                if instruction.is_some_and(|i| {
                    i.writes != *destinations
                        || !sources_ab
                            .iter()
                            .chain(accumulator)
                            .all(|r| i.reads.contains(r))
                        || !i
                            .reads
                            .iter()
                            .any(|r| r.file == AmdRegisterFile::Scalar && r.index == 126)
                        || i.reads.iter().any(|r| {
                            !sources_ab.contains(r)
                                && !accumulator.contains(r)
                                && !(r.file == AmdRegisterFile::Scalar && r.index == 126)
                        })
                }) {
                    unresolved.push(Unresolved::at(record.event, "WMMA operand roles or implicit EXEC do not match instruction register signatures"));
                }
            }
            _ => unresolved.push(Unresolved::at(
                record.event,
                "legacy CDNA semantic event cannot describe gfx1250",
            )),
        }
    }
    for instruction in instructions.values() {
        check_missing_semantic(instruction, &mut unresolved);
    }
    if matches!(graph.terminal(), Terminal::Completed) && ended.len() != waves {
        unresolved.push(Unresolved::global(
            "completed gfx1250 trace requires an S_ENDPGM instruction for every wave",
        ));
    }
    if waves == 0 || seen.iter().any(|seen| !seen) {
        unresolved.push(Unresolved::global(
            "every launched gfx1250 wave requires instruction/register records",
        ));
    }
    let mut associations = HashMap::new();
    let mut represented = HashMap::<EventId, HashSet<u32>>::new();
    let mut transferred = HashMap::<EventId, HashMap<ThreadIx, (u64, u64)>>::new();
    let mut footprints = HashMap::<(EventId, ThreadIx), (u64, u64)>::new();
    let mut last_record = HashMap::new();
    for link in graph.amd_memory_effects() {
        associations.insert(link.effect, link);
    }
    for (event_id, event) in graph.events().iter() {
        match event.kind {
            EventKind::Amd(index) => {
                last_record.insert(graph.amd_event(index).unwrap().wave, event_id);
            }
            EventKind::Access(access_id) => {
                let access = graph.access(access_id);
                let Some(link) = associations.get(&event_id) else {
                    unresolved.push(Unresolved::at(
                        event_id,
                        "memory effect is missing its gfx1250 issue association",
                    ));
                    continue;
                };
                let Some(&(issue, _)) = issues.get(&link.issue) else {
                    unresolved.push(Unresolved::at(
                        event_id,
                        "effect names an unsupported or absent memory issue",
                    ));
                    continue;
                };
                let AmdEventKind::MemoryIssue {
                    class,
                    destinations,
                    ..
                } = &issue.kind
                else {
                    unreachable!()
                };
                let wave = access.attributed.0 / WAVE as u32;
                if wave != issue.wave
                    || last_record.get(&wave) != Some(&link.issue)
                    || graph.event(link.issue).pc != event.pc
                {
                    unresolved.push(Unresolved::at(
                        event_id,
                        "effect has wrong wave, source point, or issuing instruction order",
                    ));
                }
                represented
                    .entry(link.issue)
                    .or_default()
                    .insert(access.attributed.0 % WAVE as u32);
                let mask = issues[&link.issue].1;
                if matches!(
                    class,
                    AmdMemoryClass::VectorLoad
                        | AmdMemoryClass::VectorStore
                        | AmdMemoryClass::FlatGlobalLoad
                        | AmdMemoryClass::FlatGlobalStore
                        | AmdMemoryClass::FlatLdsLoad
                        | AmdMemoryClass::FlatLdsStore
                        | AmdMemoryClass::GlobalAtomicAddF32NoReturn
                        | AmdMemoryClass::Ds
                        | AmdMemoryClass::AsyncLoadToLds
                        | AmdMemoryClass::AsyncStoreFromLds
                        | AmdMemoryClass::TensorLoadToLds
                        | AmdMemoryClass::TensorStoreFromLds
                ) && mask & (1u64 << (access.attributed.0 % 32)) == 0
                {
                    unresolved.push(Unresolved::at(
                        event_id,
                        "memory effect belongs to an inactive EXEC lane",
                    ));
                }
                let read = access.mode == AccessMode::Read;
                let valid = match class {
                    AmdMemoryClass::VectorLoad | AmdMemoryClass::ScalarLoad => {
                        access.space == Space::Global && read
                    }
                    AmdMemoryClass::VectorStore => access.space == Space::Global && !read,
                    AmdMemoryClass::GlobalAtomicAddF32NoReturn => access.space == Space::Global,
                    AmdMemoryClass::Ds => {
                        access.space == Space::Shared && (read != destinations.is_empty())
                    }
                    AmdMemoryClass::AsyncLoadToLds | AmdMemoryClass::TensorLoadToLds => matches!(
                        (access.space, read),
                        (Space::Global, true) | (Space::Shared, false)
                    ),
                    AmdMemoryClass::AsyncStoreFromLds | AmdMemoryClass::TensorStoreFromLds => {
                        matches!(
                            (access.space, read),
                            (Space::Shared, true) | (Space::Global, false)
                        )
                    }
                    _ => flat_profile(*class)
                        .is_some_and(|(space, mode)| access.space == space && access.mode == mode),
                };
                let atomic = *class == AmdMemoryClass::GlobalAtomicAddF32NoReturn;
                if !valid
                    || access.ordering
                        != if atomic {
                            OrderingKind::Atomic
                        } else {
                            OrderingKind::Ordinary
                        }
                    || access.proxy != Proxy::Generic
                {
                    unresolved.push(Unresolved::at(
                        event_id,
                        "gfx1250 memory class/effect space, direction or ordering disagree",
                    ));
                }
                // The old scope tag certifies CDNA SC0/SC1 encodings. GFX12
                // uses a distinct SCOPE field, whose cache/publication protocol
                // must not be invented from a legacy tag on an external graph.
                if link.scope != AmdMemoryScope::Unspecified {
                    unresolved.push(Unresolved::at(event_id,
                        "legacy CDNA workgroup visibility does not certify gfx1250 SCOPE/cache publication"));
                }
                if let Footprint::Bytes { addr, width } = access.footprint {
                    if atomic {
                        let pair = atomic_pairs
                            .entry((link.issue, access.attributed))
                            .or_default();
                        let part = if read { &mut pair.0 } else { &mut pair.1 };
                        if width != 4 || addr % 4 != 0 || part.replace((event_id, addr)).is_some() {
                            unresolved.push(Unresolved::at(event_id,
                                "atomic F32 RMW requires exactly one aligned 4-byte read and write per active lane"));
                        }
                    }
                    let count = transferred
                        .entry(link.issue)
                        .or_default()
                        .entry(access.attributed)
                        .or_default();
                    if read {
                        count.0 += width as u64;
                    } else {
                        count.1 += width as u64;
                    }
                    if let Some(end) = addr.checked_add(width as u64) {
                        if access.space == Space::Shared {
                            if end > AmdArchitecture::Gfx1250.lds_capacity() {
                                unresolved.push(Unresolved::at(
                                    event_id,
                                    "LDS effect exceeds gfx1250 capacity",
                                ));
                            }
                            footprints
                                .entry((link.issue, access.attributed))
                                .and_modify(|span| {
                                    span.0 = span.0.min(addr);
                                    span.1 = span.1.max(end);
                                })
                                .or_insert((addr, end));
                        }
                    } else {
                        unresolved.push(Unresolved::at(
                            event_id,
                            "memory footprint overflows concrete address space",
                        ));
                    }
                } else {
                    unresolved.push(Unresolved::at(
                        event_id,
                        "PTX tensor-memory footprints are not gfx1250 LDS",
                    ));
                }
            }
            EventKind::Exit => {}
            _ => unresolved.push(Unresolved::at(
                event_id,
                "PTX synchronization/async certificate is not a gfx1250 event",
            )),
        }
    }
    for (&id, &(record, mask)) in &issues {
        let AmdEventKind::MemoryIssue {
            class,
            destinations,
            ..
        } = &record.kind
        else {
            unreachable!()
        };
        let lanes = represented.get(&id);
        if *class == AmdMemoryClass::CrossLane {
            if lanes.is_some() || destinations.is_empty() {
                unresolved.push(Unresolved::at(
                    id,
                    "cross-lane operation must have destinations and no fabricated LDS effects",
                ));
            }
        } else if lanes.is_none() {
            unresolved.push(Unresolved::at(
                id,
                "memory instruction has no memory effects",
            ));
        } else if matches!(
            class,
            AmdMemoryClass::VectorLoad
                | AmdMemoryClass::VectorStore
                | AmdMemoryClass::FlatGlobalLoad
                | AmdMemoryClass::FlatGlobalStore
                | AmdMemoryClass::FlatLdsLoad
                | AmdMemoryClass::FlatLdsStore
                | AmdMemoryClass::GlobalAtomicAddF32NoReturn
                | AmdMemoryClass::Ds
                | AmdMemoryClass::AsyncLoadToLds
                | AmdMemoryClass::AsyncStoreFromLds
        ) && (0..32)
            .any(|lane| mask & (1u64 << lane) != 0 && !lanes.unwrap().contains(&lane))
        {
            unresolved.push(Unresolved::at(
                id,
                "memory instruction omits an active lane's effects",
            ));
        }
        if *class == AmdMemoryClass::GlobalAtomicAddF32NoReturn
            && atomic_pairs.iter().filter(|((issue, _), _)| *issue == id).any(|(_, (read, write))| {
                !matches!((read, write), (Some((r, a)), Some((w, b))) if r < w && a == b)
            })
        {
            unresolved.push(Unresolved::at(id,
                "atomic RMW effects must read then write the same 4-byte location"));
        }
        if matches!(
            class,
            AmdMemoryClass::AsyncLoadToLds
                | AmdMemoryClass::AsyncStoreFromLds
                | AmdMemoryClass::TensorLoadToLds
                | AmdMemoryClass::TensorStoreFromLds
        ) && transferred.get(&id).is_none_or(|lanes| {
            lanes
                .values()
                .any(|&(read, write)| read == 0 || read != write)
        }) {
            unresolved.push(Unresolved::at(id, "DMA instruction requires paired source/destination footprints of equal byte size for each attributed lane"));
        }
    }
    if !graph.shared_allocation_layout().is_empty() {
        for ((issue, _), (start, end)) in footprints {
            if !graph.shared_allocation_layout().iter().any(|allocation| {
                start >= allocation.offset
                    && allocation
                        .offset
                        .checked_add(allocation.size)
                        .is_some_and(|limit| end <= limit)
            }) {
                unresolved.push(Unresolved::at(
                    issue,
                    "full LDS instruction footprint crosses configured allocation boundaries",
                ));
            }
        }
    }
    PropertyResult::from_findings(
        AmdTraceEvidence {
            waves,
            instructions: instruction_count,
            issues: issues.len(),
            effects: associations.len(),
        },
        Vec::new(),
        unresolved,
    )
}

fn complete(op: &Operation) -> bool {
    op.remaining.is_empty()
}
fn has(op: &Operation, counter: AmdCounter) -> bool {
    op.remaining.iter().any(|&(c, _)| c == counter)
}

fn wait(counter: AmdCounter, threshold: u16, pending: &[usize], operations: &mut [Operation]) {
    if Some(threshold) == maximum(counter) || counter == AmdCounter::Tensor && threshold != 0 {
        return;
    }
    let selected: Vec<_> = pending
        .iter()
        .copied()
        .filter(|&i| has(&operations[i], counter))
        .collect();
    // SMEM completion/translation may return out of order. A partial count does
    // not establish which scalar destination or replay source has retired.
    if threshold != 0
        && (counter == AmdCounter::Km
            || counter == AmdCounter::X
                && selected
                    .iter()
                    .any(|&i| operations[i].class == AmdMemoryClass::ScalarLoad))
    {
        return;
    }
    let count = selected.len().saturating_sub(threshold as usize);
    for index in selected.into_iter().take(count) {
        let op = &mut operations[index];
        op.remaining.retain(|&(c, _)| c != counter);
        // Data cannot complete before its own address translation. This does
        // not drain translations of unrelated operations or other counters.
        if matches!(
            counter,
            AmdCounter::Load | AmdCounter::Store | AmdCounter::Km
        ) {
            op.remaining.retain(|&(c, _)| c != AmdCounter::X);
        }
    }
}

#[derive(Clone)]
struct WmmaOperation {
    event: EventId,
    ordinal: u64,
    kind: AmdWmmaKind,
    destinations: Vec<AmdRegister>,
    sources: Vec<AmdRegister>,
}
impl WmmaOperation {
    fn is_xdl(&self) -> bool {
        self.kind != AmdWmmaKind::F32_16x16x4
    }
    fn valu_wait(&self) -> u64 {
        match self.kind {
            AmdWmmaKind::F16_16x16x32 | AmdWmmaKind::Bf16_16x16x32 => 4,
            AmdWmmaKind::F32_16x16x4 => 0,
            _ => 1,
        }
    }
}

pub(super) fn check(graph: &EventGraph) -> AmdReport {
    let trace = contract(graph);
    if trace.verdict() != Verdict::Pass {
        return AmdReport {
            trace,
            wait_readiness: unknown("gfx1250 trace contract did not pass"),
            barrier: unknown("gfx1250 trace contract did not pass"),
            memory_conflict: unknown("gfx1250 trace contract did not pass"),
        };
    }
    let waves = (graph.threads() as usize).div_ceil(WAVE);
    let mut clocks = vec![vec![0; waves * CLASSES]; waves];
    let mut sequences = vec![0; waves * CLASSES];
    let mut pending = vec![Vec::<usize>::new(); waves];
    let mut operations = Vec::<Operation>::new();
    let mut issue_index = HashMap::new();
    let mut hazards = Vec::new();
    let mut unresolved = Vec::new();
    let mut barriers = HashMap::<(i16, u32), HashMap<usize, Vec<u32>>>::new();
    let mut signals = vec![None; waves];
    let mut blocked = vec![None; waves];
    let mut released = HashSet::new();
    let mut barrier_violations = Vec::new();
    let mut arrivals = 0;
    let mut waits = 0;
    let mut next_generation = vec![0; waves];
    let mut groups = HashMap::new();
    let mut instruction_at = HashMap::new();
    let mut wmma_at = HashMap::new();
    let mut valu_ordinal = vec![0u64; waves];
    let mut matrices = vec![Vec::<WmmaOperation>::new(); waves];
    for record in graph.amd_events() {
        match record.kind {
            AmdEventKind::Instruction { .. } => {
                instruction_at.insert(record.wave, record.event);
            }
            AmdEventKind::MemoryIssue { class, .. } => {
                if let Some(group) = replay_group(class) {
                    groups.insert(instruction_at[&record.wave], group);
                }
            }
            AmdEventKind::WmmaIssue {
                ref sources_ab,
                kind,
                ..
            } => {
                wmma_at.insert(instruction_at[&record.wave], (kind, sources_ab));
            }
            _ => {}
        }
    }
    for record in graph.amd_events() {
        let wave = record.wave as usize;
        if let Some((object, phase, _)) = blocked[wave] {
            if !matches!(record.kind, AmdEventKind::SplitBarrierRelease { barrier, generation } if (barrier, generation) == (object, phase))
            {
                barrier_violations.push(AmdBarrierViolation {
                    generation: phase,
                    event: record.event,
                    wave: record.wave,
                    reason: "wave progressed while blocked at its split-barrier wait".into(),
                });
            }
        }
        match &record.kind {
            AmdEventKind::Instruction { reads, writes, .. } => {
                let kind = graph
                    .event(record.event)
                    .pc
                    .map(|pc| graph.provenance().instructions[pc.0 as usize].kind)
                    .unwrap();
                let is_valu = matches!(kind, "vector ALU" | "trans ALU" | "shifted ALU" | "WMMA");
                let next_wmma = wmma_at.get(&record.event);
                if is_valu {
                    let ordinal = valu_ordinal[wave];
                    matrices[wave].retain(|m| ordinal.saturating_sub(m.ordinal + 1) < 5);
                    for operation in &matrices[wave] {
                        let independent = ordinal.saturating_sub(operation.ordinal + 1);
                        if let Some((next_kind, ab)) = next_wmma {
                            // GFX12 SrcC forwarding is interlocked, including
                            // overlapping tuples. A/B consumes need explicit
                            // intervening VALU instructions. F32 is non-XDL.
                            let required =
                                if operation.is_xdl() && *next_kind != AmdWmmaKind::F32_16x16x4 {
                                    operation.valu_wait() + 1
                                } else {
                                    1
                                };
                            if independent < required {
                                for &register in ab.iter().filter(|r| {
                                    operation.destinations.iter().any(|d| d.overlaps(**r))
                                }) {
                                    hazards.push(AmdRegisterHazard {
                                        issue: operation.event,
                                        use_event: record.event,
                                        wave: record.wave,
                                        register,
                                        kind: AmdRegisterHazardKind::MatrixReadBeforeReady,
                                    });
                                }
                            }
                        } else if operation.is_xdl() && independent < operation.valu_wait() {
                            for &register in reads
                                .iter()
                                .filter(|r| operation.destinations.iter().any(|d| d.overlaps(**r)))
                            {
                                hazards.push(AmdRegisterHazard {
                                    issue: operation.event,
                                    use_event: record.event,
                                    wave: record.wave,
                                    register,
                                    kind: AmdRegisterHazardKind::MatrixReadBeforeReady,
                                });
                            }
                            for &register in writes {
                                let hazard = if operation
                                    .destinations
                                    .iter()
                                    .any(|d| d.overlaps(register))
                                {
                                    Some(AmdRegisterHazardKind::MatrixDestinationReuse)
                                } else if operation.sources.iter().any(|r| r.overlaps(register)) {
                                    Some(AmdRegisterHazardKind::MatrixSourceReuse)
                                } else {
                                    None
                                };
                                if let Some(kind) = hazard {
                                    hazards.push(AmdRegisterHazard {
                                        issue: operation.event,
                                        use_event: record.event,
                                        wave: record.wave,
                                        register,
                                        kind,
                                    });
                                }
                            }
                        }
                    }
                    valu_ordinal[wave] += 1;
                }
                if matches!(
                    kind,
                    "branch" | "s_endpgm" | "xcnt drain" | "barrier signal" | "barrier wait"
                ) {
                    wait(AmdCounter::X, 0, &pending[wave], &mut operations);
                }
                if let Some(group) = groups.get(&record.event) {
                    for &index in &pending[wave] {
                        let op = &mut operations[index];
                        if replay_group(op.class).is_some_and(|old| old != *group) {
                            op.remaining.retain(|&(c, _)| c != AmdCounter::X);
                        }
                    }
                }
                if groups.get(&record.event) == Some(&true) {
                    // VMEM translations issue in order. LLVM applies the X
                    // dependency when a later VMEM destination aliases an
                    // older source; neither operation's data completes here.
                    let through = pending[wave]
                        .iter()
                        .copied()
                        .filter(|&index| {
                            let op = &operations[index];
                            replay_group(op.class) == Some(true)
                                && has(op, AmdCounter::X)
                                && writes
                                    .iter()
                                    .any(|r| op.held_sources.iter().any(|s| s.overlaps(*r)))
                        })
                        .max();
                    if let Some(through) = through {
                        for &index in pending[wave].iter().take_while(|&&i| i <= through) {
                            if replay_group(operations[index].class) == Some(true) {
                                operations[index]
                                    .remaining
                                    .retain(|&(c, _)| c != AmdCounter::X);
                            }
                        }
                    }
                }
                for &index in &pending[wave] {
                    let op = &operations[index];
                    if complete(op) {
                        continue;
                    }
                    for reg in reads {
                        if op.destinations.iter().any(|d| d.overlaps(*reg)) {
                            hazards.push(AmdRegisterHazard {
                                issue: op.event,
                                use_event: record.event,
                                wave: record.wave,
                                register: *reg,
                                kind: AmdRegisterHazardKind::ReadBeforeReady,
                            });
                        }
                    }
                    for reg in writes {
                        if op.destinations.iter().any(|d| d.overlaps(*reg)) {
                            hazards.push(AmdRegisterHazard {
                                issue: op.event,
                                use_event: record.event,
                                wave: record.wave,
                                register: *reg,
                                kind: AmdRegisterHazardKind::DestinationReuse,
                            });
                        }
                        let held = if replay_group(op.class).is_some() {
                            has(op, AmdCounter::X)
                        } else {
                            true
                        };
                        if held && op.held_sources.iter().any(|s| s.overlaps(*reg)) {
                            hazards.push(AmdRegisterHazard {
                                issue: op.event,
                                use_event: record.event,
                                wave: record.wave,
                                register: *reg,
                                kind: AmdRegisterHazardKind::SourceReuse,
                            });
                        }
                    }
                }
            }
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations,
                held_sources,
            } => {
                // Interleaved scalar/vector groups implicitly drain the older
                // group's X_CNT, not its independent data completion counter.
                if let Some(group) = replay_group(*class) {
                    for &index in &pending[wave] {
                        let op = &mut operations[index];
                        if replay_group(op.class).is_some_and(|old| old != group) {
                            op.remaining.retain(|&(c, _)| c != AmdCounter::X);
                        }
                    }
                }
                if *class == AmdMemoryClass::GlobalAtomicAddF32NoReturn {
                    for &index in &pending[wave] {
                        let old = &operations[index];
                        if has(old, AmdCounter::X)
                            && old.class != AmdMemoryClass::GlobalAtomicAddF32NoReturn
                        {
                            hazards.push(AmdRegisterHazard {
                                issue: old.event,
                                use_event: record.event,
                                wave: record.wave,
                                register: AmdRegister {
                                    file: AmdRegisterFile::Scalar,
                                    index: 126,
                                    lanes: 0,
                                },
                                kind: AmdRegisterHazardKind::AtomicReplayBeforeReady,
                            });
                        }
                    }
                }
                let slot = wave * CLASSES + class_index(*class);
                sequences[slot] += 1;
                let mut clock = clocks[wave].clone();
                // Effect order is within the resolved segment. A GLOBAL prefix
                // must never publish an incomplete LDS operation, or vice versa.
                let streams: &[AmdMemoryClass] = match class {
                    AmdMemoryClass::VectorLoad
                    | AmdMemoryClass::VectorStore
                    | AmdMemoryClass::FlatGlobalLoad
                    | AmdMemoryClass::FlatGlobalStore => &[
                        AmdMemoryClass::VectorLoad,
                        AmdMemoryClass::VectorStore,
                        AmdMemoryClass::FlatGlobalLoad,
                        AmdMemoryClass::FlatGlobalStore,
                    ],
                    AmdMemoryClass::Ds
                    | AmdMemoryClass::FlatLdsLoad
                    | AmdMemoryClass::FlatLdsStore => &[
                        AmdMemoryClass::Ds,
                        AmdMemoryClass::FlatLdsLoad,
                        AmdMemoryClass::FlatLdsStore,
                    ],
                    _ => &[],
                };
                for &stream in streams {
                    let source = wave * CLASSES + class_index(stream);
                    clock[source] = sequences[source] - u32::from(source == slot);
                }
                issue_index.insert(record.event, operations.len());
                pending[wave].push(operations.len());
                operations.push(Operation {
                    event: record.event,
                    wave: record.wave,
                    class: *class,
                    sequence: sequences[slot],
                    issued_tick: 0,
                    remaining: counters.clone(),
                    destinations: destinations.clone(),
                    held_sources: held_sources.clone(),
                    clock,
                });
            }
            AmdEventKind::WaitCounters { thresholds } => {
                waits += 1;
                for &(counter, threshold) in thresholds {
                    if threshold != 0
                        && Some(threshold) != maximum(counter)
                        && matches!(
                            counter,
                            AmdCounter::Load | AmdCounter::Store | AmdCounter::Ds
                        )
                        && pending[wave].iter().any(|&index| {
                            flat_profile(operations[index].class).is_some()
                                && has(&operations[index], counter)
                        })
                    {
                        unresolved.push(Unresolved::at(record.event,
                            "nonzero wait with pending FLAT requires a pinned mixed-segment completion prefix"));
                        continue;
                    }
                    if counter == AmdCounter::Tensor && threshold != 0 {
                        unresolved.push(Unresolved::at(record.event, "nonzero TENSOR_CNT wait requires a pinned hardware counter-width contract"));
                    }
                    wait(counter, threshold, &pending[wave], &mut operations);
                }
            }
            AmdEventKind::SplitBarrierSignal {
                barrier,
                generation,
                ..
            } => {
                arrivals += 1;
                if *generation != next_generation[wave] || signals[wave].is_some() {
                    barrier_violations.push(AmdBarrierViolation {
                        generation: *generation,
                        event: record.event,
                        wave: record.wave,
                        reason: "duplicate or unexpected split-barrier phase signal".into(),
                    });
                }
                barriers
                    .entry((*barrier, *generation))
                    .or_default()
                    .insert(wave, clocks[wave].clone());
                signals[wave] = Some((*barrier, *generation));
            }
            AmdEventKind::SplitBarrierWait {
                barrier,
                generation,
            } => {
                if signals[wave] != Some((*barrier, *generation)) || blocked[wave].is_some() {
                    barrier_violations.push(AmdBarrierViolation {
                        generation: *generation,
                        event: record.event,
                        wave: record.wave,
                        reason: "wait lacks its own signal or repeats a blocked phase".into(),
                    });
                }
                blocked[wave] = Some((*barrier, *generation, graph.event(record.event).pc));
            }
            AmdEventKind::SplitBarrierRelease {
                barrier,
                generation,
            } => {
                let phase = barriers.get(&(*barrier, *generation));
                let exited = |w: usize| {
                    (w * WAVE..((w + 1) * WAVE).min(graph.threads() as usize)).all(|t| {
                        graph
                            .program_order(ThreadIx(t as u32))
                            .last()
                            .is_some_and(|&event| {
                                event < record.event && graph.event(event).kind == EventKind::Exit
                            })
                    })
                };
                let missing =
                    (0..waves).any(|w| !exited(w) && phase.is_none_or(|p| !p.contains_key(&w)));
                if missing
                    || blocked[wave] != Some((*barrier, *generation, graph.event(record.event).pc))
                    || !released.insert((*barrier, *generation, wave))
                {
                    barrier_violations.push(AmdBarrierViolation { generation: *generation, event: record.event, wave: record.wave, reason: "split-barrier release lacks matching wait, source point or live-wave arrivals".into() });
                } else {
                    for clock in phase.unwrap().values() {
                        join(&mut clocks[wave], clock);
                    }
                    for w in 0..waves {
                        if exited(w) {
                            let frontier = clocks[w].clone();
                            join(&mut clocks[wave], &frontier);
                        }
                    }
                    blocked[wave] = None;
                    signals[wave] = None;
                    next_generation[wave] += 1;
                }
            }
            AmdEventKind::WmmaIssue {
                kind,
                destinations,
                sources_ab,
                accumulator,
            } => {
                matrices[wave].push(WmmaOperation {
                    event: record.event,
                    ordinal: valu_ordinal[wave] - 1,
                    kind: *kind,
                    destinations: destinations.clone(),
                    sources: sources_ab.iter().chain(accumulator).copied().collect(),
                });
            }
            // Default scheduling interlocks ordinary ALU dependencies. LLVM's
            // AMDGPUInsertDelayAlu pass inserts S_DELAY_ALU to avoid stalls, not
            // to turn outstanding memory into completed data. Expert mode is
            // outside this execution envelope.
            AmdEventKind::DelayAlu { .. } | AmdEventKind::Delay { .. } => {}
            _ => unreachable!("trace contract rejected legacy target events"),
        }
        pending[wave].retain(|&index| {
            if complete(&operations[index]) {
                let op = &operations[index];
                // Scalar completions only occur at KM0, so no out-of-order
                // completion is promoted into a false scalar FIFO prefix.
                let slot = wave * CLASSES + class_index(op.class);
                clocks[wave][slot] = clocks[wave][slot].max(op.sequence);
                false
            } else {
                true
            }
        });
    }
    if matches!(graph.terminal(), Terminal::Completed) {
        for (wave, phase) in blocked.iter().enumerate() {
            if let Some((_, generation, _)) = phase {
                barrier_violations.push(AmdBarrierViolation {
                    generation: *generation,
                    event: graph.amd_events().last().unwrap().event,
                    wave: wave as u32,
                    reason: "completed trace leaves a split-barrier wait blocked".into(),
                });
            }
        }
    }
    let wait_readiness = PropertyResult::from_findings(
        AmdWaitEvidence {
            issues: operations.len(),
            waits,
        },
        hazards,
        unresolved,
    );
    let barrier = PropertyResult::from_findings(
        AmdBarrierEvidence {
            generations: barriers.len(),
            arrivals,
            releases: released.len(),
        },
        barrier_violations,
        Vec::new(),
    );
    let memory_conflict =
        if barrier.verdict() == Verdict::Pass && wait_readiness.verdict() != Verdict::Unknown {
            memory_conflicts(graph, &operations, &issue_index)
        } else {
            unknown("gfx1250 barrier or completion contract is inconclusive")
        };
    AmdReport {
        trace,
        wait_readiness,
        barrier,
        memory_conflict,
    }
}
