//! Prefix certificates are checked independently of interpreter output values.
use volta_graph::*;
use volta_graph_check::amdgpu::early_readiness::{
    ScalarReadinessCertificate, ScalarReadinessObserver, validate_scalar_readiness_prefix,
};
use volta_graph_check::amdgpu::{AmdRegisterHazard, AmdRegisterHazardKind};
use volta_graph_check::{GraphConclusion, Verdict, check_graph};

const KINDS: [&str; 7] = [
    "scalar memory",
    "wait",
    "scalar ALU",
    "vector memory",
    "s_endpgm",
    "barrier signal",
    "barrier wait",
];

fn s(index: u16) -> AmdRegister {
    AmdRegister {
        file: AmdRegisterFile::Scalar,
        index,
        lanes: 0,
    }
}

struct Trace {
    builder: GraphBuilder,
    threads: u32,
}

impl Trace {
    fn new(threads: u32) -> Self {
        Self::with_provenance(threads, |_| {})
    }

    fn with_provenance(threads: u32, mutate: impl FnOnce(&mut Provenance)) -> Self {
        let mut provenance = Provenance {
            kernel: "scalar_prefix".into(),
            block_dim: (threads, 1, 1),
            grid_dim: (1, 1, 1),
            workgroup_id: (0, 0, 0),
            targets: vec!["gfx1250".into()],
            assumptions: vec![Assumption::UnclusteredWorkgroup],
            instructions: KINDS
                .iter()
                .enumerate()
                .map(|(index, &kind)| InstructionInfo {
                    kind,
                    span: Some((index * 10, index * 10 + 9)),
                })
                .collect(),
        };
        mutate(&mut provenance);
        Self {
            builder: GraphBuilder::new(provenance),
            threads,
        }
    }

    fn instruction(
        &mut self,
        wave: u32,
        pc: u32,
        mask: u64,
        reads: Vec<AmdRegister>,
        writes: Vec<AmdRegister>,
    ) -> EventId {
        self.builder.amd_event(
            wave,
            ProgramPoint(pc),
            AmdEventKind::Instruction {
                exec_mask: mask,
                reads,
                writes,
                scalar_mask_reads: vec![],
            },
        )
    }

    fn load(&mut self, wave: u32, destination: AmdRegister) -> EventId {
        self.load_custom(
            wave,
            destination,
            vec![(AmdCounter::Km, 1), (AmdCounter::X, 1)],
            true,
        )
    }

    fn load_custom(
        &mut self,
        wave: u32,
        destination: AmdRegister,
        counters: Vec<(AmdCounter, u16)>,
        effect: bool,
    ) -> EventId {
        self.instruction(wave, 0, 1, vec![], vec![destination]);
        let issue = self.builder.amd_event(
            wave,
            ProgramPoint(0),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::ScalarLoad,
                counters,
                destinations: vec![destination],
                held_sources: vec![],
            },
        );
        if effect {
            let access = self.builder.thread_access(
                ThreadIx(wave * 32),
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
                    attributed: ThreadIx(wave * 32),
                    value: None,
                },
            );
            self.builder.amd_memory_effect(issue, access);
        }
        issue
    }

    fn wait(&mut self, wave: u32, thresholds: Vec<(AmdCounter, u16)>) {
        self.instruction(wave, 1, 1, vec![], vec![]);
        self.builder.amd_event(
            wave,
            ProgramPoint(1),
            AmdEventKind::WaitCounters { thresholds },
        );
    }

    fn read(&mut self, wave: u32, register: AmdRegister) -> EventId {
        self.instruction(wave, 2, 1, vec![register], vec![])
    }

    fn certificate(&self) -> ScalarReadinessCertificate {
        ScalarReadinessObserver::new()
            .observe(self.builder.graph_so_far())
            .unwrap()
            .expect("declared candidate")
    }

    fn complete(mut self) -> EventGraph {
        for wave in 0..self.threads.div_ceil(32) {
            self.instruction(wave, 4, 1, vec![], vec![]);
        }
        for thread in 0..self.threads {
            self.builder.exit(ThreadIx(thread), ProgramPoint(4));
        }
        self.builder.finish(Terminal::Completed)
    }
}

#[test]
fn a_scalar_prefix_witness_matches_the_independent_full_checker() {
    let mut trace = Trace::new(32);
    let issue = trace.load(0, s(4));
    let use_event = trace.read(0, s(4));
    let certificate = trace.certificate();
    let hazard =
        validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &certificate).unwrap();
    assert_eq!(hazard.issue, issue);
    assert_eq!(hazard.use_event, use_event);
    assert_eq!(hazard.kind, AmdRegisterHazardKind::ReadBeforeReady);
    let full = check_graph(&trace.complete());
    assert!(matches!(
        full.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    assert!(
        full.amd
            .unwrap()
            .wait_readiness
            .violations()
            .contains(&hazard)
    );
}

#[test]
fn unscheduled_waves_do_not_become_full_trace_completeness_evidence() {
    let mut trace = Trace::new(64);
    trace.load(0, s(4));
    trace.read(0, s(4));
    let certificate = trace.certificate();
    assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &certificate).is_ok());
    let full = check_graph(trace.builder.graph_so_far());
    assert_eq!(full.amd.as_ref().unwrap().trace.verdict(), Verdict::Unknown);
    assert!(!matches!(full.conclusion(), GraphConclusion::Verified));
}

#[test]
fn only_same_wave_zero_km_retires_a_particular_scalar_destination() {
    for (counter, threshold, waiting_wave, safe) in [
        (AmdCounter::Km, 0, 0, true),
        (AmdCounter::Km, 1, 0, false),
        (AmdCounter::Km, 30, 0, false),
        (AmdCounter::Km, 31, 0, false),
        (AmdCounter::X, 0, 0, false),
        (AmdCounter::Load, 0, 0, false),
        (AmdCounter::Ds, 0, 0, false),
        (AmdCounter::Km, 0, 1, false),
    ] {
        let mut trace = Trace::new(64);
        trace.load(0, s(4));
        trace.wait(waiting_wave, vec![(counter, threshold)]);
        trace.read(0, s(4));
        let candidate = ScalarReadinessObserver::new()
            .observe(trace.builder.graph_so_far())
            .unwrap();
        assert_eq!(
            candidate.is_none(),
            safe,
            "{counter:?}/{threshold}/wave{waiting_wave}"
        );
        if let Some(certificate) = candidate {
            assert!(
                validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &certificate)
                    .is_ok()
            );
        }
        let full = check_graph(&trace.complete());
        let hazards = &full.amd.as_ref().unwrap().wait_readiness;
        assert_eq!(hazards.violations().is_empty(), safe);
    }
}

#[test]
fn waits_before_issue_and_after_unsafe_use_cannot_repair_the_use() {
    let mut trace = Trace::new(32);
    trace.wait(0, vec![(AmdCounter::Km, 0)]);
    trace.load(0, s(4));
    trace.read(0, s(4));
    let mut observer = ScalarReadinessObserver::new();
    let first = observer
        .observe(trace.builder.graph_so_far())
        .unwrap()
        .unwrap();
    trace.wait(0, vec![(AmdCounter::Km, 0)]);
    let later = observer
        .observe(trace.builder.graph_so_far())
        .unwrap()
        .unwrap();
    assert_eq!(first.hazard, later.hazard);
    assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &first).is_err());
    assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &later).is_ok());
}

#[test]
fn unordered_scalar_completion_never_promises_a_partial_fifo_prefix() {
    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    trace.load(0, s(8));
    trace.wait(0, vec![(AmdCounter::Km, 1)]);
    trace.read(0, s(4));
    trace.read(0, s(8));
    let certificate = trace.certificate();
    assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &certificate).is_ok());
    let graph = trace.complete();
    let full = check_graph(&graph);
    let hazards = full.amd.unwrap().wait_readiness;
    assert!(hazards.violations().iter().any(|h| h.register == s(4)));
    assert!(hazards.violations().iter().any(|h| h.register == s(8)));
}

#[test]
fn uniform_scalar_reads_still_execute_with_exec_zero_and_unrelated_registers_do_not_alias() {
    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    trace.instruction(0, 2, 0, vec![s(5)], vec![]);
    assert!(
        ScalarReadinessObserver::new()
            .observe(trace.builder.graph_so_far())
            .unwrap()
            .is_none()
    );
    trace.instruction(0, 2, 0, vec![s(4)], vec![]);
    assert!(
        validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &trace.certificate())
            .is_ok()
    );
}

#[test]
fn forged_certificate_identity_and_hazard_fields_are_refused() {
    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    trace.read(0, s(4));
    let certificate = trace.certificate();
    let mut forged = Vec::new();
    let mut changed = certificate.clone();
    changed.amd_records -= 1;
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.graph_events += 1;
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.provenance.kernel.push_str("_other");
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.provenance.instructions[0].span = None;
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.hazard.issue = changed.hazard.use_event;
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.hazard.use_event = changed.hazard.issue;
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.hazard.wave = 1;
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.hazard.register = s(5);
    forged.push(changed);
    let mut changed = certificate.clone();
    changed.hazard.kind = AmdRegisterHazardKind::SourceReuse;
    forged.push(changed);
    for changed in forged {
        assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &changed).is_err());
    }
}

#[test]
fn unknown_target_source_roles_counters_and_missing_effects_cannot_certify_a_candidate() {
    for (counters, effect) in [
        (vec![(AmdCounter::Km, 1)], true),
        (vec![(AmdCounter::Km, 2), (AmdCounter::X, 1)], true),
        (vec![(AmdCounter::Km, 1), (AmdCounter::Km, 1)], true),
        (vec![(AmdCounter::Km, 1), (AmdCounter::X, 1)], false),
    ] {
        let mut trace = Trace::new(32);
        trace.load_custom(0, s(4), counters, effect);
        trace.read(0, s(4));
        assert!(
            validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &trace.certificate())
                .is_err()
        );
    }
    let mut trace = Trace::with_provenance(32, |p| p.instructions[0].kind = "vector memory");
    trace.load(0, s(4));
    trace.read(0, s(4));
    assert!(
        validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &trace.certificate())
            .is_err()
    );
    for target in ["gfx942", "gfx950", "gfx1250:xnack-", "sm_100a"] {
        let trace = Trace::with_provenance(32, |p| p.targets = vec![target.into()]);
        assert!(
            ScalarReadinessObserver::new()
                .observe(trace.builder.graph_so_far())
                .is_err()
        );
    }
}

#[test]
fn incomplete_using_instruction_and_invalid_wait_state_are_refused() {
    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    // This instruction requires its own MemoryIssue/effects before the batch is
    // complete; a tempting early register witness cannot bypass that contract.
    trace.instruction(0, 3, 1, vec![s(4)], vec![]);
    assert!(
        validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &trace.certificate())
            .is_err()
    );
    for thresholds in [
        vec![(AmdCounter::Km, 32)],
        vec![(AmdCounter::Km, 1), (AmdCounter::Km, 1)],
    ] {
        let mut trace = Trace::new(32);
        trace.load(0, s(4));
        trace.wait(0, thresholds);
        trace.read(0, s(4));
        assert!(
            validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &trace.certificate())
                .is_err()
        );
    }
}

#[test]
fn blocked_wave_progress_and_generic_unsupported_abort_are_not_certified_prefixes() {
    let mut trace = Trace::new(64);
    trace.load(0, s(4));
    trace.instruction(0, 6, 1, vec![], vec![]);
    trace.builder.amd_event(
        0,
        ProgramPoint(6),
        AmdEventKind::SplitBarrierWait {
            barrier: -1,
            generation: 0,
        },
    );
    trace.read(0, s(4));
    assert!(
        validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &trace.certificate())
            .is_err()
    );

    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    trace.read(0, s(4));
    let certificate = trace.certificate();
    let graph = trace.builder.finish(Terminal::Aborted {
        thread: None,
        pc: None,
        cause: AbortCause::Unsupported,
        reason: "unsupported AMD instruction".into(),
    });
    assert!(validate_scalar_readiness_prefix(&graph, &certificate).is_err());
}

#[test]
fn a_scalar_zero_wait_protects_full_acceptance_without_any_prefix_certificate() {
    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    trace.wait(0, vec![(AmdCounter::Km, 0)]);
    trace.read(0, s(4));
    assert!(
        ScalarReadinessObserver::new()
            .observe(trace.builder.graph_so_far())
            .unwrap()
            .is_none()
    );
    let graph = trace.complete();
    assert_eq!(check_graph(&graph).conclusion(), GraphConclusion::Verified);
    let fake = ScalarReadinessCertificate {
        provenance: graph.provenance().clone(),
        amd_records: graph.amd_events().len(),
        graph_events: graph.events().len(),
        hazard: AmdRegisterHazard {
            issue: EventId(1),
            use_event: EventId(5),
            wave: 0,
            register: s(4),
            kind: AmdRegisterHazardKind::ReadBeforeReady,
        },
    };
    assert!(validate_scalar_readiness_prefix(&graph, &fake).is_err());
}

#[test]
fn full_mode_retains_distinct_bug_sites_while_the_observer_selects_the_first() {
    let mut trace = Trace::new(32);
    let first_issue = trace.load(0, s(4));
    let second_issue = trace.load(0, s(8));
    let first_use = trace.read(0, s(4));
    let mut observer = ScalarReadinessObserver::new();
    let first = observer
        .observe(trace.builder.graph_so_far())
        .unwrap()
        .unwrap();
    let second_use = trace.read(0, s(8));
    let still_first = observer
        .observe(trace.builder.graph_so_far())
        .unwrap()
        .unwrap();
    assert_eq!(first.hazard, still_first.hazard);
    assert_eq!(first.hazard.issue, first_issue);
    assert_eq!(first.hazard.use_event, first_use);
    assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &still_first).is_ok());
    let full = check_graph(&trace.complete());
    let readiness = full.amd.unwrap().wait_readiness;
    assert_eq!(
        readiness
            .violations()
            .iter()
            .filter(|h| h.kind == AmdRegisterHazardKind::ReadBeforeReady)
            .count(),
        2
    );
    assert!(
        readiness.violations().iter().any(|h| {
            h.issue == second_issue && h.use_event == second_use && h.register == s(8)
        })
    );
}

#[test]
fn only_the_explicit_observer_stop_reason_allows_post_halt_revalidation() {
    for (reason, valid) in [
        ("execution stopped by instruction observer", true),
        ("arithmetic evaluation failed", false),
        ("unsupported AMD instruction", false),
    ] {
        let mut trace = Trace::new(32);
        trace.load(0, s(4));
        trace.read(0, s(4));
        let certificate = trace.certificate();
        let graph = trace.builder.finish(Terminal::Aborted {
            thread: None,
            pc: None,
            cause: AbortCause::Error,
            reason: reason.into(),
        });
        assert_eq!(
            validate_scalar_readiness_prefix(&graph, &certificate).is_ok(),
            valid
        );
    }
}

#[test]
fn generic_late_stop_preserves_diagnostics_but_requires_a_certificate_to_reject() {
    for reason in [
        "execution stopped by instruction observer",
        "ordinary evaluation error",
    ] {
        let mut trace = Trace::new(32);
        trace.load(0, s(4));
        trace.read(0, s(4));
        let certificate = trace.certificate();
        let graph = trace.builder.finish(Terminal::Aborted {
            thread: None,
            pc: None,
            cause: AbortCause::Error,
            reason: reason.into(),
        });
        let report = check_graph(&graph);
        assert_eq!(
            report.amd.as_ref().unwrap().wait_readiness.verdict(),
            Verdict::Fail
        );
        assert_eq!(report.verdict_overall(), Verdict::Fail);
        if reason == "execution stopped by instruction observer" {
            assert!(matches!(
                report.conclusion(),
                GraphConclusion::Unknown { .. }
            ));
            assert!(validate_scalar_readiness_prefix(&graph, &certificate).is_ok());
        } else {
            assert!(matches!(
                report.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
            assert!(validate_scalar_readiness_prefix(&graph, &certificate).is_err());
        }
    }
}

#[test]
fn an_unrelated_unknown_tensor_wait_neither_repairs_nor_is_certified_by_a_scalar_witness() {
    let mut trace = Trace::new(32);
    trace.load(0, s(4));
    // Nonzero TENSOR_CNT has no pinned width contract. This valid wait form
    // cannot change KM destination availability and is not part of its proof.
    trace.wait(0, vec![(AmdCounter::Tensor, 1)]);
    trace.read(0, s(4));
    let certificate = trace.certificate();
    assert!(validate_scalar_readiness_prefix(trace.builder.graph_so_far(), &certificate).is_ok());

    let mut unresolved_only = Trace::new(32);
    unresolved_only.wait(0, vec![(AmdCounter::Tensor, 1)]);
    assert!(
        ScalarReadinessObserver::new()
            .observe(unresolved_only.builder.graph_so_far())
            .unwrap()
            .is_none()
    );
    let report = check_graph(&unresolved_only.complete());
    assert_eq!(
        report.amd.as_ref().unwrap().wait_readiness.verdict(),
        Verdict::Unknown
    );
}
