//! Bounded, rejection-only ordinary write conflicts within one AMD memory issue.
//!
//! Discovery observes successful complete producer batches; it is not authority.
//! Validation replays the existing target-selected trace/readiness/barrier and
//! memory checkers. Two different active lanes' overlapping ordinary writes in
//! the same issue are siblings: its completed frontier excludes its own sequence.
//! A future wait cannot repair that pair. This does not establish full execution,
//! raw-ISA attestation, equivalence or an AMD hardware soundness theorem.

use std::collections::{HashMap, VecDeque};

use volta_graph::{
    AbortCause, AccessMode, AmdArchitecture, AmdEventKind, AmdMemoryClass, EventGraph, EventId,
    EventKind, ExecContext, Footprint, OperandRole, OrderingKind, Provenance, Proxy, Space,
    Terminal, ThreadIx,
};

use crate::domain::{ByteLocation, ConflictKind};
use crate::memory_conflict::MemoryConflict;
use crate::{Unresolved, Verdict};

/// Untrusted identity and witness; no trusted artifact/serialization marker.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MemoryConflictCertificate {
    pub provenance: Provenance,
    pub amd_records: usize,
    pub graph_events: usize,
    pub instruction: EventId,
    pub issue: EventId,
    pub wave: u32,
    pub earlier_thread: ThreadIx,
    pub later_thread: ThreadIx,
    pub conflict: MemoryConflict,
}

#[derive(Debug, Clone, Copy)]
struct Instruction {
    event: EventId,
    mask: u64,
}

#[derive(Debug, Clone, Copy)]
struct Issue {
    event: EventId,
    instruction: Instruction,
    wave: u32,
    space: Space,
}

#[derive(Debug, Clone, Copy)]
struct Effect {
    event: EventId,
    thread: ThreadIx,
    start: u64,
    end: u64,
}

#[derive(Debug, Clone, Copy)]
struct Candidate {
    issue: Issue,
    earlier: Effect,
    later: Effect,
}

/// Incremental discovery only. Call after a successful complete instruction batch.
/// Each issue's first proposed pair is returned once, including after a refusal.
#[derive(Debug, Default)]
pub struct MemoryConflictObserver {
    records: usize,
    effects: usize,
    events: usize,
    instructions: HashMap<u32, Instruction>,
    candidates: VecDeque<Candidate>,
}

fn refusal(reason: &str) -> Vec<Unresolved> {
    vec![Unresolved::global(reason)]
}

fn architecture(graph: &EventGraph) -> Result<AmdArchitecture, Vec<Unresolved>> {
    match AmdArchitecture::from_targets(&graph.provenance().targets) {
        Some(target @ (AmdArchitecture::Gfx950 | AmdArchitecture::Gfx1250)) => Ok(target),
        _ => Err(refusal(
            "local write certificates require exactly gfx950 or gfx1250",
        )),
    }
}

fn store_space(target: AmdArchitecture, kind: &AmdEventKind) -> Option<Space> {
    let AmdEventKind::MemoryIssue {
        class,
        destinations,
        ..
    } = kind
    else {
        return None;
    };
    if !destinations.is_empty() {
        return None;
    }
    match (target, class) {
        (
            AmdArchitecture::Gfx950,
            AmdMemoryClass::VectorMemory | AmdMemoryClass::VectorStoreWide,
        )
        | (AmdArchitecture::Gfx1250, AmdMemoryClass::VectorStore) => Some(Space::Global),
        (AmdArchitecture::Gfx950, AmdMemoryClass::Lds)
        | (AmdArchitecture::Gfx1250, AmdMemoryClass::Ds) => Some(Space::Shared),
        _ => None,
    }
}

fn issue_effects(
    graph: &EventGraph,
    target: AmdArchitecture,
    issue: Issue,
    ids: &[EventId],
) -> Option<Vec<Effect>> {
    let instruction = graph.events().get(issue.instruction.event)?;
    let recorded = graph.events().get(issue.event)?;
    if instruction.pc != recorded.pc || issue.instruction.event >= issue.event {
        return None;
    }
    let kind = graph
        .provenance()
        .instructions
        .get(instruction.pc?.0 as usize)?
        .kind;
    if kind
        != if issue.space == Space::Global {
            "vector memory"
        } else {
            "LDS"
        }
    {
        return None;
    }
    let width = if target == AmdArchitecture::Gfx1250 {
        32
    } else {
        64
    };
    let mut represented = 0u64;
    let mut effects = Vec::with_capacity(ids.len());
    for &id in ids {
        let event = graph.events().get(id)?;
        let EventKind::Access(access_id) = event.kind else {
            return None;
        };
        let access = graph.accesses().get(access_id)?;
        let thread = access.attributed;
        let lane = thread.0 % width;
        if thread.0 >= graph.threads()
            || thread.0 / width != issue.wave
            || event.ctx != ExecContext::Thread(thread)
            || event.pc != instruction.pc
            || id <= issue.event
            || issue.instruction.mask & (1u64 << lane) == 0
            || access.space != issue.space
            || access.mode != AccessMode::Write
            || access.ordering != OrderingKind::Ordinary
            || access.proxy != Proxy::Generic
            || access.role != OperandRole::Plain
        {
            return None;
        }
        let Footprint::Bytes { addr, width } = access.footprint else {
            return None;
        };
        let end = addr.checked_add(u64::from(width))?;
        if width == 0 {
            return None;
        }
        represented |= 1u64 << lane;
        effects.push(Effect {
            event: id,
            thread,
            start: addr,
            end,
        });
    }
    if represented != issue.instruction.mask || represented.count_ones() < 2 {
        return None;
    }
    effects.sort_unstable_by_key(|e| (e.start, e.event));
    Some(effects)
}

/// Two farthest endpoints from distinct threads suffice to discover an overlap
/// with a different thread. Keeping only adjacent intervals would be incorrect.
fn candidate(issue: Issue, effects: &[Effect]) -> Option<Candidate> {
    let mut farthest: Vec<Effect> = Vec::with_capacity(2);
    for &effect in effects {
        if let Some(other) = farthest
            .iter()
            .filter(|e| e.thread != effect.thread && e.end > effect.start)
            .min_by_key(|e| (e.event.max(effect.event), e.event.min(effect.event)))
        {
            let (earlier, later) = if other.event < effect.event {
                (*other, effect)
            } else {
                (effect, *other)
            };
            return Some(Candidate {
                issue,
                earlier,
                later,
            });
        }
        if let Some(old) = farthest.iter_mut().find(|e| e.thread == effect.thread) {
            if (effect.end, std::cmp::Reverse(effect.event))
                > (old.end, std::cmp::Reverse(old.event))
            {
                *old = effect;
            }
        } else {
            farthest.push(effect);
        }
        farthest.sort_unstable_by_key(|e| (std::cmp::Reverse(e.end), e.event));
        farthest.truncate(2);
    }
    None
}

impl MemoryConflictObserver {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn observe(
        &mut self,
        graph: &EventGraph,
    ) -> Result<Option<MemoryConflictCertificate>, Vec<Unresolved>> {
        let target = architecture(graph)?;
        if graph.amd_events().len() < self.records
            || graph.amd_memory_effects().len() < self.effects
            || graph.events().len() < self.events
        {
            return Err(refusal("memory-conflict observer cannot rewind a prefix"));
        }
        let mut issues = HashMap::new();
        for record in &graph.amd_events()[self.records..] {
            if let AmdEventKind::Instruction { exec_mask, .. } = record.kind {
                self.instructions.insert(
                    record.wave,
                    Instruction {
                        event: record.event,
                        mask: exec_mask,
                    },
                );
            } else if let Some(space) = store_space(target, &record.kind)
                && let Some(&instruction) = self.instructions.get(&record.wave)
            {
                issues.insert(
                    record.event,
                    Issue {
                        event: record.event,
                        instruction,
                        wave: record.wave,
                        space,
                    },
                );
            }
        }
        let mut links: HashMap<EventId, Vec<EventId>> = HashMap::new();
        for link in &graph.amd_memory_effects()[self.effects..] {
            if issues.contains_key(&link.issue) {
                links.entry(link.issue).or_default().push(link.effect);
            }
        }
        let mut found = Vec::new();
        for (id, issue) in issues {
            if let Some(effects) = links
                .get(&id)
                .and_then(|ids| issue_effects(graph, target, issue, ids))
                && let Some(found_candidate) = candidate(issue, &effects)
            {
                found.push(found_candidate);
            }
        }
        found.sort_unstable_by_key(|c| (c.later.event, c.earlier.event));
        self.candidates.extend(found);
        self.records = graph.amd_events().len();
        self.effects = graph.amd_memory_effects().len();
        self.events = graph.events().len();
        Ok(self
            .candidates
            .pop_front()
            .map(|c| MemoryConflictCertificate {
                provenance: graph.provenance().clone(),
                amd_records: self.records,
                graph_events: self.events,
                instruction: c.issue.instruction.event,
                issue: c.issue.event,
                wave: c.issue.wave,
                earlier_thread: c.earlier.thread,
                later_thread: c.later.thread,
                conflict: MemoryConflict {
                    kind: ConflictKind::WriteWrite,
                    location: ByteLocation {
                        space: c.issue.space,
                        addr: c.earlier.start.max(c.later.start),
                    },
                    earlier: c.earlier.event,
                    later: c.later.event,
                },
            }))
    }
}

/// Independently replay a bounded counterexample; never proves trace completion.
/// Exact untruncated checker pair membership is required, including CONFLICT_CAP.
/// The successful whole-batch callback is a trusted producer boundary: the graph
/// records roles/lane membership, not every machine-ISA component cardinality.
pub fn validate_memory_conflict_prefix(
    graph: &EventGraph,
    certificate: &MemoryConflictCertificate,
) -> Result<MemoryConflict, Vec<Unresolved>> {
    let target = architecture(graph)?;
    // Structural IDs MUST be checked before indexing any graph record/event.
    graph.validate().map_err(|defects| {
        defects
            .into_iter()
            .map(|d| Unresolved::global(d.message))
            .collect::<Vec<_>>()
    })?;
    if graph.provenance() != &certificate.provenance
        || graph.amd_events().len() != certificate.amd_records
        || graph.events().len() != certificate.graph_events
    {
        return Err(refusal(
            "memory-conflict certificate does not identify this prefix",
        ));
    }
    if !matches!(graph.terminal(), Terminal::Aborted { cause: AbortCause::Error, reason, .. } if reason == "graph under construction" || reason == super::early_readiness::INSTRUCTION_OBSERVER_STOP_REASON)
    {
        return Err(refusal(
            "memory-conflict certificates require a live construction or observer-stopped prefix",
        ));
    }
    let mut instruction = None;
    let mut matched = None;
    for record in graph
        .amd_events()
        .iter()
        .filter(|r| r.wave == certificate.wave)
    {
        if let AmdEventKind::Instruction { exec_mask, .. } = record.kind {
            instruction = Some(Instruction {
                event: record.event,
                mask: exec_mask,
            });
        }
        if record.event == certificate.issue {
            matched = store_space(target, &record.kind).and_then(|space| {
                instruction.map(|instruction| Issue {
                    event: record.event,
                    instruction,
                    wave: record.wave,
                    space,
                })
            });
            break;
        }
    }
    let issue =
        matched.ok_or_else(|| refusal("certificate has no supported ordinary store issue"))?;
    if issue.instruction.event != certificate.instruction {
        return Err(refusal("certificate instruction differs from its issuer"));
    }
    let ids: Vec<_> = graph
        .amd_memory_effects()
        .iter()
        .filter(|l| l.issue == issue.event)
        .map(|l| l.effect)
        .collect();
    let effects = issue_effects(graph, target, issue, &ids)
        .ok_or_else(|| refusal("ordinary store effect/active-lane membership did not pass"))?;
    let earlier = effects
        .iter()
        .find(|e| e.event == certificate.conflict.earlier)
        .ok_or_else(|| refusal("missing earlier witness effect"))?;
    let later = effects
        .iter()
        .find(|e| e.event == certificate.conflict.later)
        .ok_or_else(|| refusal("missing later witness effect"))?;
    if earlier.event >= later.event
        || earlier.thread == later.thread
        || earlier.thread != certificate.earlier_thread
        || later.thread != certificate.later_thread
        || earlier.start.max(later.start) >= earlier.end.min(later.end)
        || certificate.conflict.kind != ConflictKind::WriteWrite
        || certificate.conflict.location
            != (ByteLocation {
                space: issue.space,
                addr: earlier.start.max(later.start),
            })
    {
        return Err(refusal(
            "certificate is not the exact distinct-lane write overlap",
        ));
    }
    if issue.space == Space::Shared {
        let limits: Vec<_> = graph
            .provenance()
            .assumptions
            .iter()
            .filter_map(|a| {
                if let volta_graph::Assumption::ConfiguredLdsBytes(limit) = a {
                    Some(*limit)
                } else {
                    None
                }
            })
            .collect();
        if (target == AmdArchitecture::Gfx1250 && limits.len() != 1)
            || limits.len() > 1
            || limits
                .first()
                .is_some_and(|&limit| effects.iter().any(|e| e.end > limit))
        {
            return Err(refusal(
                "store effects exceed or lack their configured LDS premise",
            ));
        }
    }
    let report = super::check_prefix(graph);
    if report.trace.verdict() != Verdict::Pass
        || report.wait_readiness.verdict() != Verdict::Pass
        || report.barrier.verdict() != Verdict::Pass
    {
        return Err(refusal(
            "memory-conflict prefix trace, readiness or barrier premises did not pass",
        ));
    }
    if !report
        .memory_conflict
        .violations()
        .contains(&certificate.conflict)
    {
        return Err(refusal(
            "exact memory-conflict pair is absent from independent retained findings",
        ));
    }
    Ok(certificate.conflict)
}
