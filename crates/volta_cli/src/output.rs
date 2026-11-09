//! Result rendering, exit statuses, and expression output.

use std::fmt::Display;
use std::path::Path;
use std::process::ExitCode;

use crate::source::KernelSide;
use volta_common::run_log;
use volta_equivalence::{EquivCheckReport, EquivOutcome};
use volta_expr::SymbolicOutputs;
use volta_graph::{EventGraph, EventId, ExecContext};
use volta_graph_check::{GraphConclusion, GraphReport};
use volta_pipeline::{Decision, EquivalenceVerdict, Verdict};

pub(crate) fn write_exprs(path: &Path, exprs: &SymbolicOutputs) -> std::io::Result<()> {
    let mut out = std::io::BufWriter::new(std::fs::File::create(path)?);
    volta_expr::text::write_text(&mut out, exprs)?;
    std::io::Write::flush(&mut out)
}

/// Exit status of a verdict: 0 only for ACCEPT (or a verified graph), 1 for REJECT, 2 for
/// UNKNOWN.
pub(crate) fn exit_code(verdict: Verdict) -> ExitCode {
    match verdict {
        Verdict::Accept => ExitCode::SUCCESS,
        Verdict::Reject => ExitCode::FAILURE,
        Verdict::Unknown => ExitCode::from(2),
    }
}

/// Print the graph branch's per-check verdicts for one kernel, with each failed check's
/// witnesses (each event under its finding, with its PTX line in `source`) and the trace
/// generator's deadlock.
pub(crate) fn print_graph_report(
    label: &str,
    graph: &EventGraph,
    report: &GraphReport,
    source: &str,
) {
    println!("{}: graph verification", label);
    if graph.provenance().assumptions.iter().any(|assumption| {
        matches!(
            assumption,
            volta_graph::Assumption::SingleWorkgroupAnalyzed
                | volta_graph::Assumption::SelectedWorkgroupAnalyzed { .. }
        )
    }) {
        let (x, y, z) = graph.provenance().workgroup_id;
        println!(
            "  selected workgroup: ({x}, {y}, {z}); other workgroups and inter-workgroup conflicts are outside this result"
        );
    }
    for s in report.summaries() {
        let check = format!("{} ({})", s.property.name(), s.property.algorithm());
        println!("  {:<55} {}", check, s.verdict.name());
        for f in s.findings.iter().take(3) {
            println!("      {}", f);
            for &e in &f.events {
                println!("        {}", event_source(graph, source, e));
            }
        }
        if s.findings.len() > 3 {
            println!("      ... ({} more)", s.findings.len() - 3);
        }
    }
    if let Some(deadlock) = report.deadlock() {
        println!(
            "  trace: deadlock, {} blocked thread(s)",
            deadlock.blocked.len()
        );
    }
}

/// `e<id> <context>  line <n>: <PTX statement>` for one event of `graph`.
fn event_source(graph: &EventGraph, source: &str, id: EventId) -> String {
    let event = graph.event(id);
    let context = match event.ctx {
        ExecContext::Thread(t) => format!("t{}", t.0),
        ExecContext::Async(op) => format!("async op {}", op.0),
        ExecContext::Generation(g) => format!("generation {}", g.0),
    };
    let span = event
        .pc
        .and_then(|pc| graph.provenance().instructions.get(pc.0 as usize))
        .and_then(|info| info.span);
    let at = match span {
        Some((low, _)) if low <= source.len() => {
            let line = source[..low].matches('\n').count() + 1;
            let text = source[low..].lines().next().unwrap_or("");
            format!("line {}: {}", line, text.trim())
        }
        _ => "no source line".to_string(),
    };
    format!("e{} {:<12} {}", id.0, context, at)
}

pub(crate) fn print_decision(decision: &Decision) -> ExitCode {
    println!("VERDICT: {}", decision.verdict.name());
    for e in &decision.evidence {
        println!("  {}", e);
    }
    if !decision.assumptions.is_empty() {
        println!("  under the assumptions:");
        for a in &decision.assumptions {
            println!("    - {}", a.describe());
        }
    }
    exit_code(decision.verdict)
}

/// Print each output array's element count and up to `limit` of its elements, or why there
/// are none.
pub(crate) fn print_outputs(outputs: &Result<SymbolicOutputs, impl Display>, limit: u64) {
    match outputs {
        Ok(exprs) => {
            for (name, elems) in &exprs.outputs {
                println!("  output '{}': {} element(s) written", name, elems.len());
                for (index, expr) in elems.iter().take(limit as usize) {
                    println!(
                        "    {}[{}] = {}",
                        name,
                        index,
                        exprs.arena.display_expr(*expr)
                    );
                }
                if elems.len() as u64 > limit {
                    println!("    ... ({} more)", elems.len() as u64 - limit);
                }
            }
        }
        Err(why) => println!("  no outputs: {}", why),
    }
}

/// Print the graph branch's conclusion when no equivalence check was requested; returns its
/// verdict and that verdict's name.
pub(crate) fn print_graph_conclusion(report: &GraphReport) -> (Verdict, &'static str) {
    let (verdict, reasons) = match report.conclusion() {
        GraphConclusion::Verified => (Verdict::Accept, Vec::new()),
        GraphConclusion::Rejected { failed, deadlock } => (
            Verdict::Reject,
            deadlock
                .map(|_| "the trace deadlocked".to_string())
                .into_iter()
                .chain(
                    failed
                        .iter()
                        .map(|s| format!("{} failed", s.property.name())),
                )
                .collect(),
        ),
        GraphConclusion::Unknown { reasons } => (Verdict::Unknown, reasons),
    };
    let name = match verdict {
        Verdict::Accept => "VERIFIED",
        Verdict::Reject => "REJECTED",
        Verdict::Unknown => "UNKNOWN",
    };
    println!(
        "GRAPH VERIFICATION: {} (no equivalence check requested)",
        name
    );
    for r in &reasons {
        println!("  {}", r);
    }
    (verdict, name)
}

/// Print the canonical solver's report on a kernel against a spec, or why it did not run, and
/// log it under `command`.
pub(crate) fn print_spec_check(
    command: &str,
    verdict: &EquivalenceVerdict,
    report: Option<&EquivCheckReport>,
    exec_secs: f64,
    vc_secs: f64,
    log: &mut run_log::RunLog,
) {
    let Some(report) = report else {
        if let EquivalenceVerdict::Failed { reason } = verdict {
            eprintln!("error: {}", reason);
            log.record(&format!("{}: FAILED: {}", command, reason));
        }
        return;
    };
    let elems = if report.elements_checked == report.elements_total {
        format!("{}", report.elements_total)
    } else {
        format!("{}/{}", report.elements_checked, report.elements_total)
    };
    println!(
        "VC check: {:.3}s (decision procedure {:.3}s)  elements: {}",
        vc_secs,
        report.check_time().as_secs_f64(),
        elems
    );
    if report.check_iters.len() > 1 {
        let per_iter: Vec<String> = report
            .check_iters
            .iter()
            .map(|d| format!("{:.3}", d.as_secs_f64()))
            .collect();
        println!(
            "  decision procedure iterations (s): [{}]",
            per_iter.join(", ")
        );
    }
    match &report.outcome {
        EquivOutcome::Equivalent => {
            println!("EQUIVALENT (matches spec)");
            log.record(&format!(
                "{}: EQUIVALENT ({} elements, exec {:.3}s, vc {:.3}s)",
                command, elems, exec_secs, vc_secs
            ));
        }
        EquivOutcome::NotEquivalent { mismatches } => {
            println!(
                "NOT EQUIVALENT: {} mismatched element(s) vs spec",
                mismatches.len()
            );
            for m in mismatches.iter().take(10) {
                println!("  {}[{}]", m.array, m.index);
            }
            if mismatches.len() > 10 {
                println!("  ... ({} more)", mismatches.len() - 10);
            }
            log.record(&format!(
                "{}: NOT EQUIVALENT, {} mismatches",
                command,
                mismatches.len()
            ));
        }
    }
}

pub(crate) fn print_certified_rejection(side: &KernelSide, instructions: u64) -> bool {
    print_prefix_certificates(
        side.label,
        instructions,
        side.early_readiness.as_ref(),
        side.early_memory_conflict.as_ref(),
        side.tensor_bounds.as_ref(),
    )
}

pub(crate) fn print_native_certified_rejection(
    label: &str,
    side: &volta_pipeline::NativeRunMetadata,
) -> bool {
    print_prefix_certificates(
        label,
        side.stats.instructions,
        side.early_readiness.as_ref(),
        side.early_memory_conflict.as_ref(),
        side.tensor_bounds.as_ref(),
    )
}

fn print_prefix_certificates(
    label: &str,
    instructions: u64,
    early_readiness: Option<&volta_pipeline::CertifiedScalarReadiness>,
    early_memory_conflict: Option<&volta_pipeline::CertifiedMemoryConflict>,
    tensor_bounds: Option<&volta_pipeline::CertifiedTensorBounds>,
) -> bool {
    if let Some(finding) = tensor_bounds {
        println!("TENSOR_BOUNDS: CERTIFIED_REJECTION");
        println!("  AMD tensor LDS bounds (independently validated attempted access) FAIL");
        println!("  {}: {:?}", label, finding.violation());
        println!(
            "  incomplete aborted prefix; transfer not issued; complete outputs and equivalence unavailable"
        );
        println!("VERDICT: REJECT");
        return true;
    }
    if let Some(finding) = early_memory_conflict {
        let certificate = finding.certificate();
        println!("EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION");
        println!("  AMD memory-conflict freedom (certified prefix) FAIL");
        println!("  {}: {:?}", label, finding.conflict());
        println!(
            "  instruction={:?} issue={:?} wave={} earlier_thread={:?} later_thread={:?}",
            certificate.instruction,
            certificate.issue,
            certificate.wave,
            certificate.earlier_thread,
            certificate.later_thread
        );
        println!(
            "  prefix: instructions={} amd_records={} graph_events={}",
            instructions, certificate.amd_records, certificate.graph_events
        );
        println!(
            "  first finding only; incomplete trace prefix; complete outputs and equivalence unavailable"
        );
        println!("VERDICT: REJECT");
        return true;
    }
    let Some(finding) = early_readiness else {
        return false;
    };
    println!("EARLY_READINESS: CERTIFIED_REJECTION");
    println!("  AMD wait and register readiness (certified prefix) FAIL");
    println!("  {}: {:?}", label, finding.hazard());
    println!(
        "  first finding only; incomplete trace prefix; complete outputs and equivalence unavailable"
    );
    println!("VERDICT: REJECT");
    true
}
