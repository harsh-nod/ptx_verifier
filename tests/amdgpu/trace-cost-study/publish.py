#!/usr/bin/env python3
"""Publish machine-neutral observations after the raw comparison is audited."""
from __future__ import annotations

import argparse
import copy
import gzip
import json
from pathlib import Path

import study

SAMPLE_FIELDS = (
    "id", "arm", "round", "classification", "seconds", "time_to_detection_seconds",
    "returncode", "timed_out", "detected_expected_hazard", "detected_property",
    "detection_mode", "false_positive", "false_acceptance", "failed_properties",
    "measurement_errors", "graph_accepted", "peak_rss_kib", "user_seconds",
    "system_seconds", "reported_execution_seconds", "executed_instructions",
    "diagnostics_sha256",
)


def sample(row):
    return {key: row[key] for key in SAMPLE_FIELDS if key in row}


def projection(report):
    rows = []
    for original in report["summaries"]:
        row = dict(original)
        for arm in ("baseline", "candidate"):
            row[arm] = {**row[arm], "first": sample(row[arm]["first"]) if row[arm]["first"] else None}
        rows.append(row)
    return rows, [sample(row) for row in report["samples"]]


def publication_gate(report):
    """First observations are excluded from statistics, but cannot hide failures."""
    gate = copy.deepcopy(report["adoption"])
    for row in report["summaries"]:
        if not row["baseline_qualified"]:
            continue
        metric = "seconds" if row["expectation"] == "safe" else "time_to_detection_seconds"
        verdict = "graph_accepted" if row["expectation"] == "safe" else "detected_expected_hazard"
        for arm in ("baseline", "candidate"):
            first = row[arm]["first"]
            if first is None or not study.legacy.valid_metric(first, metric) or not first.get(verdict):
                gate["failures"].append(row["id"] + ": " + arm + " first observation failed")
    gate["accepted"] = not gate["failures"]
    return gate


def publish(args):
    audit = study.audit(args)
    independent = json.loads(args.independent_audit.read_text())
    study.require(independent.get("report_sha256") == audit["report_sha256"]
                  and independent.get("status") == "AUDITED"
                  and independent.get("independent_statistics_recomputed") is True,
                  "separate numerical audit required")
    report = json.loads(args.report.read_text())
    plan = study.plan_at(args.plan, args.plan_sha256)
    rows, samples = projection(report)
    gate = publication_gate(report)
    builds = {arm: json.loads(Path(report[arm]).read_text())["build"] for arm in ("baseline", "candidate")}
    results = {
        "schema": 1,
        "scope": "Prospective configurations of existing compiler programs; seeded scalar-readiness hazards, not newly discovered application bugs or unseen algorithms.",
        "builds": {arm: {key: build[key] for key in ("revision", "source_tree", "binary_sha256", "profile", "default_features", "features", "rustc", "cargo", "trust")} for arm, build in builds.items()},
        "population": len(plan["cases"]),
        "qualification": {arm: {key: {"qualified": value["qualified"], "classification": value["analysis"]["classification"], "graph_completed": value["analysis"]["graph_completed"], "detected": value["analysis"]["detected_expected_hazard"], "proved": bool(value["proof"] and value["proof"]["proved"])} for key, value in json.loads(Path(report[arm]).read_text())["results"].items()} for arm in ("baseline", "candidate")},
        "timed_cases": len({row["id"] for row in samples}),
        "samples": len(samples),
        "repeats": plan["protocol"]["repeats"],
        "seed": plan["protocol"]["seed"],
        "adoption": gate,
        "recorded_repeated_observation_gate": report["adoption"],
        "implementation_status": "eligible_for_review" if gate["accepted"] else "experimental_only",
        "rows": rows,
        "audit": {"raw_report_sha256": audit["report_sha256"], "independent_audit_sha256": study.sha(args.independent_audit),
                  "manifest_sha256": study.sha(study.MANIFEST), "protocol_sha256": study.sha(study.PROTOCOL),
                  "measurement_helper_sha256": study.sha(Path(study.__file__)), "publisher_sha256": study.sha(Path(__file__))},
        "limitations": [
            "Single shared virtualized CPU host; unrelated background work remained visible. Physical host isolation and fixed frequency were not attested.",
            "Randomized adjacent pairs reduce order effects; they do not remove all environmental confounding.",
            "Intervals are pointwise paired-bootstrap 95% intervals with no multiple-comparison correction.",
            "The unchanged gfx950 reduction and its mutation both stop at a register-selected lane operation; they remain in the denominator without a timing ratio.",
            "Performance applies to the named storage-only candidate revision, release toolchain and configured launches, not every kernel or later combined source tree.",
            "Safe proofs use the existing mathematical model; they do not establish exhaustive hardware floating-point equivalence.",
        ],
    }
    independent_summary = independent["summary"]
    results["independent_validation"] = {key: independent_summary[key] for key in (
        "checks", "checked_artifacts", "timed_misses_or_invalid", "first_timeouts_or_errors",
        "safe_proof_diagnostic_gate_failures", "semantic_proof_stdout_differences_after_separately_removing_only_timing_numbers")}
    if independent_summary["semantic_proof_stdout_differences_after_separately_removing_only_timing_numbers"] == 0:
        count = independent_summary["safe_proof_diagnostic_gate_failures"]
        results["limitations"].append(f"The independent audit identifies {count} proof-diagnostic flags caused only by retained Exec/VC timing numbers; the recorded gate failures remain unchanged.")
    output = args.output.resolve()
    study.require(output.is_relative_to(study.HERE.resolve()) and not output.exists(), "publication needs a fresh study subdirectory")
    output.mkdir(parents=True)
    study.write(output / "results.json", results)
    with (output / "samples.json.gz").open("wb") as stream:
        with gzip.GzipFile(filename="", fileobj=stream, mode="wb", mtime=0) as compressed:
            compressed.write((json.dumps(samples, sort_keys=True, separators=(",", ":")) + "\n").encode())
    def milliseconds(value):
        return "—" if value is None else f"{value * 1000:.3f}"
    def ratio(value):
        return "—" if value is None else f"{value:.3f}"
    lines = ["# Native register-storage measurements", "", results["scope"], "",
             f"Baseline `{builds['baseline']['revision']}`; candidate `{builds['candidate']['revision']}`.", "",
             f"{results['population']} configurations; {results['timed_cases']} baseline-qualified configurations timed with {results['samples']} observations. First observations are retained separately from the 31 repeated pairs.", "",
             "Hazard rows measure the parent's first observation of the intended finding; safe rows measure process completion. Ratio is candidate / baseline; smaller values are faster. Peak RSS is the maximum over repeated observations.", "",
             "| Case | Baseline / candidate median (ms) | Baseline / candidate p95 (ms) | Ratio [pointwise 95% interval] | Baseline / candidate peak RSS (KiB) |",
             "| --- | ---: | ---: | ---: | ---: |"]
    for row in rows:
        left, right = row["baseline"], row["candidate"]
        interval = row["paired_ratio_interval_95"]
        interval_text = "—" if interval is None else f"[{ratio(interval[0])}, {ratio(interval[1])}]"
        lines.append(f"| {row['id']} | {milliseconds(left['median_seconds'])} / {milliseconds(right['median_seconds'])} | {milliseconds(left['p95_seconds'])} / {milliseconds(right['p95_seconds'])} | {ratio(row['candidate_over_baseline_median'])} {interval_text} | {left['peak_rss_kib'] or '—'} / {right['peak_rss_kib'] or '—'} |")
    lines += ["", "The full qualification outcomes, diagnostic/output invariants, misses, adoption gates and every numerical observation are retained in [results.json](results.json) and [samples.json.gz](samples.json.gz). The two unsupported reduction configurations are retained above with no ratio. Raw process artifacts and host details remain outside Git.", "",
              "Predeclared adoption gates: " + ("PASS." if gate["accepted"] else "FAIL; the storage candidate remains experimental. See every reason in results.json."), "",
              "Limitations:", ""]
    lines += ["- " + item for item in results["limitations"]]
    lines += ["", "Reproduce with the [protocol and commands](../README.md).", ""]
    (output / "README.md").write_text("\n".join(lines))
    return {"status": "PUBLISHED", "cases": len(rows), "samples": len(samples)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", required=True, type=Path)
    parser.add_argument("--plan-sha256", required=True)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--independent-audit", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    print(json.dumps(publish(parser.parse_args())))
