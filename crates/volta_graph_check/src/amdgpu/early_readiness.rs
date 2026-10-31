//! Checker-owned, wave-local gfx1250 scalar-load readiness.
//!
//! The ordinary full-graph checker and an optional producer observer use these
//! same transitions. Observing a candidate is not a proof: only
//! [`validate_scalar_readiness_prefix`] can validate its rejected-prefix witness.
//! Nothing in this module certifies acceptance, memory publication, another
//! target, or completion of a partial execution.
//!
//! Public semantic basis: LLVM 5fd50ec8e07abb94e203933017e8d6e40fb51824,
//! `AMDGPUHWEvents.cpp` and `SIInsertWaitcnts.cpp`. Scalar loads charge KM_CNT;
//! they may complete out of order, so only KM_CNT=0 establishes availability
//! of a particular scalar destination. X_CNT retirement and barriers do not
//! manufacture data completion. Later waits cannot repair an earlier use.

use std::collections::HashMap;

use volta_graph::{
    AbortCause, AmdArchitecture, AmdEvent, AmdEventKind, AmdMemoryClass, AmdRegister, EventGraph,
    EventId, Provenance, Terminal,
};

use super::{AmdCounter, AmdRegisterHazard, AmdRegisterHazardKind, gfx1250};
use crate::{Unresolved, Verdict};

pub(crate) const INSTRUCTION_OBSERVER_STOP_REASON: &str =
    "execution stopped by instruction observer";

/// Scalar completion is unordered: a nonzero count gives no per-load readiness
/// certificate. The full memory-effect replay also uses this predicate.
pub(super) fn km_wait_completes(threshold: u16) -> bool {
    threshold == 0
}

#[derive(Debug, Default)]
pub(super) struct ScalarReadinessState {
    pending: HashMap<u32, Vec<(EventId, Vec<AmdRegister>)>>,
}

impl ScalarReadinessState {
    /// Used only after the full contract, or speculatively by the observer.
    /// The independent prefix validator rechecks all speculative inputs.
    pub(super) fn observe(&mut self, record: &AmdEvent) -> Vec<AmdRegisterHazard> {
        match &record.kind {
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::ScalarLoad,
                destinations,
                ..
            } => {
                self.pending
                    .entry(record.wave)
                    .or_default()
                    .push((record.event, destinations.clone()));
            }
            AmdEventKind::WaitCounters { thresholds }
                if thresholds.iter().any(|&(counter, threshold)| {
                    counter == AmdCounter::Km && km_wait_completes(threshold)
                }) =>
            {
                self.pending.remove(&record.wave);
            }
            AmdEventKind::Instruction { reads, .. } => {
                return self
                    .pending
                    .get(&record.wave)
                    .into_iter()
                    .flatten()
                    .flat_map(|(issue, destinations)| {
                        reads
                            .iter()
                            .filter(|register| destinations.iter().any(|d| d.overlaps(**register)))
                            .map(|&register| AmdRegisterHazard {
                                issue: *issue,
                                use_event: record.event,
                                wave: record.wave,
                                register,
                                kind: AmdRegisterHazardKind::ReadBeforeReady,
                            })
                    })
                    .collect();
            }
            _ => {}
        }
        Vec::new()
    }
}

/// An untrusted candidate identifying one exact observed prefix and scalar use.
/// This type deliberately carries no `Pass`, terminal-completeness or acceptance
/// evidence. Provenance binds launch/target/instruction identities as represented
/// by the graph; source spans are identities, not an independent ISA decoder.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScalarReadinessCertificate {
    pub provenance: Provenance,
    pub amd_records: usize,
    pub graph_events: usize,
    pub hazard: AmdRegisterHazard,
}

/// Incremental candidate discovery. Call only after complete instruction batches
/// (instruction, semantic event and all memory effects) have been appended.
/// A result still requires independent validation against that exact prefix.
#[derive(Debug, Default)]
pub struct ScalarReadinessObserver {
    state: ScalarReadinessState,
    observed: usize,
    first: Option<AmdRegisterHazard>,
}

fn target(graph: &EventGraph) -> Result<(), Vec<Unresolved>> {
    if AmdArchitecture::from_targets(&graph.provenance().targets) != Some(AmdArchitecture::Gfx1250)
    {
        return Err(vec![Unresolved::global(
            "early scalar readiness requires exactly the supported gfx1250 target",
        )]);
    }
    Ok(())
}

impl ScalarReadinessObserver {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn observe(
        &mut self,
        graph: &EventGraph,
    ) -> Result<Option<ScalarReadinessCertificate>, Vec<Unresolved>> {
        target(graph)?;
        let Some(records) = graph.amd_events().get(self.observed..) else {
            return Err(vec![Unresolved::global(
                "early scalar readiness observer cannot rewind a prefix",
            )]);
        };
        for record in records {
            let hazards = self.state.observe(record);
            if self.first.is_none() {
                self.first = hazards.into_iter().next();
            }
        }
        self.observed = graph.amd_events().len();
        Ok(self.first.clone().map(|hazard| ScalarReadinessCertificate {
            provenance: graph.provenance().clone(),
            amd_records: graph.amd_events().len(),
            graph_events: graph.events().len(),
            hazard,
        }))
    }
}

/// Independently check an untrusted candidate against the exact graph prefix.
/// Structural, instruction/effect, target, counter and barrier prerequisites
/// must pass. Unscheduled other waves are allowed because KM readiness is
/// wave-local; no END or complete-execution claim is synthesized for them.
/// Generic unsupported/error/deadlocked prefixes cannot be promoted into a
/// certificate. Unresolved readiness outside the scalar witness's dependency
/// premises does not repair that witness and is not certified by this result.
pub fn validate_scalar_readiness_prefix(
    graph: &EventGraph,
    certificate: &ScalarReadinessCertificate,
) -> Result<AmdRegisterHazard, Vec<Unresolved>> {
    target(graph)?;
    if graph.provenance() != &certificate.provenance
        || graph.amd_events().len() != certificate.amd_records
        || graph.events().len() != certificate.graph_events
    {
        return Err(vec![Unresolved::global(
            "scalar readiness certificate does not identify this exact prefix",
        )]);
    }
    if !matches!(
        graph.terminal(),
        Terminal::Aborted {
            cause: AbortCause::Error,
            reason,
            ..
        } if reason == "graph under construction" || reason == INSTRUCTION_OBSERVER_STOP_REASON
    ) {
        return Err(vec![Unresolved::global(
            "scalar readiness certificates require a live graph-construction prefix",
        )]);
    }
    let report = gfx1250::check_prefix(graph);
    if report.trace.verdict() != Verdict::Pass {
        return Err(report.trace.unresolved().to_vec());
    }
    if report.barrier.verdict() != Verdict::Pass {
        let mut reasons = report.barrier.unresolved().to_vec();
        reasons.extend(
            report
                .barrier
                .violations()
                .iter()
                .map(|violation| Unresolved::at(violation.event, violation.reason.clone())),
        );
        return Err(reasons);
    }
    if certificate.hazard.kind != AmdRegisterHazardKind::ReadBeforeReady
        || !report
            .wait_readiness
            .violations()
            .contains(&certificate.hazard)
        || !graph.amd_events().iter().any(|record| {
            record.event == certificate.hazard.issue
                && matches!(
                    record.kind,
                    AmdEventKind::MemoryIssue {
                        class: AmdMemoryClass::ScalarLoad,
                        ..
                    }
                )
        })
    {
        return Err(vec![Unresolved::global(
            "scalar readiness certificate has no matching independently replayed hazard",
        )]);
    }
    Ok(certificate.hazard.clone())
}
