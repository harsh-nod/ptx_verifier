#!/usr/bin/env python3
"""Measure AMD coverage changes using the retained observation and audit tools."""
from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import random
import re
import statistics

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("qualification_observer", HERE.parent / "trace-cost-study/study.py")
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
engine.MANIFEST, engine.PROTOCOL = HERE / "cases.json", HERE / "protocol.json"
original_pins, original_derive = engine.input_pins, engine.derive


def input_pins(document):
    return {**original_pins(document), str(Path(__file__).resolve()): engine.sha(Path(__file__))}


def semantic_text(text):
    """Remove only clock measurements and artifact destinations, retaining counts."""
    lines = []
    for line in text.splitlines():
        if line.startswith(("Wrote output expressions to ", "Wrote event graph to ")):
            continue
        line = re.sub(r"^(Exec: )\d+(?:\.\d+)?s", r"\1<time>", line)
        line = re.sub(r"^(VC check: )\d+(?:\.\d+)?s", r"\1<time>", line)
        line = re.sub(r"(decision procedure )\d+(?:\.\d+)?s", r"\1<time>", line)
        if re.match(r"^  time: [\d.]+s\s+instructions:", line):
            line = re.sub(r"^(  time: )[\d.]+s", r"\1<time>", line)
        lines.append(line)
    return "\n".join(lines)


def derive(row, item, directory, **options):
    result = original_derive(row, item, directory, **options)
    diagnostic = semantic_text((directory / "stdout").read_text()) + "\nstderr:\n" + semantic_text((directory / "stderr").read_text())
    result["diagnostics_sha256"] = hashlib.sha256(diagnostic.encode()).hexdigest()
    return result


def valid_observation(row, expectation):
    metric = "seconds" if expectation == "safe" else "time_to_detection_seconds"
    verdict = "graph_accepted" if expectation == "safe" else "detected_expected_hazard"
    return row is not None and engine.legacy.valid_metric(row, metric) and bool(row.get(verdict))


def coverage_gate(rows):
    """Evaluate the frozen coverage/resource gates, including first observations."""
    failures = []
    for row in rows:
        name = row["id"]
        if not row["candidate_qualified"]:
            failures.append(name + ": candidate not qualified")
        if not row["baseline_qualified"]:
            continue
        if row["expectation"] == "safe" and not row["output_expressions_equal"]:
            failures.append(name + ": output expressions differ")
        for field in ("diagnostics_equal", "proof_diagnostics_equal", "timed_diagnostics_equal"):
            if not row[field]:
                failures.append(name + ": " + field)
        for arm in ("baseline", "candidate"):
            data = row[arm]
            if data["misses_or_invalid"] or not data["complete_rounds"] or not valid_observation(data["first"], row["expectation"]):
                failures.append(name + ": " + arm + " invalid observation")
        left, right = row["baseline"], row["candidate"]
        if row["expectation"] == "safe":
            for field, factor in (("median_seconds", 1.05), ("p95_seconds", 1.10)):
                if left[field] is None or right[field] is None or right[field] > left[field] * factor + 0.001:
                    failures.append(name + ": " + field + " regression")
        a, b = left["peak_rss_kib"], right["peak_rss_kib"]
        if a is None or b is None or b - a > max(a * 0.05, 8192):
            failures.append(name + ": peak RSS regression")
    return {"accepted": not failures, "failures": failures}


engine.input_pins, engine.derive, engine.adoption = input_pins, derive, coverage_gate


def added_schedule(plan, baseline, candidate):
    ids = [item["case"]["id"] for item in plan["cases"]
           if not baseline["results"][item["case"]["id"]]["qualified"]
           and candidate["results"][item["case"]["id"]]["qualified"]]
    randomizer, result = random.Random(plan["protocol"]["seed"] + 1), []
    for repeat in range(plan["protocol"]["repeats"] + 1):
        order = ids.copy()
        randomizer.shuffle(order)
        result.extend({"id": name, "round": repeat} for name in order)
    return result


def added_summaries(plan, samples):
    result = []
    for item in plan["cases"]:
        case = item["case"]
        rows = [row for row in samples if row["id"] == case["id"]]
        if not rows:
            continue
        valid = all(valid_observation(row, case["expectation"]) for row in rows)
        complete = [row["round"] for row in rows] == list(range(32))
        key = "seconds" if case["expectation"] == "safe" else "time_to_detection_seconds"
        values = [row[key] for row in rows if row["round"] > 0] if valid else []
        result.append({"id": case["id"], "expectation": case["expectation"], "observations": len(rows),
                       "all_valid": valid and complete,
                       "median_seconds": statistics.median(values) if valid and complete else None,
                       "p95_seconds": engine.legacy.percentile95(values) if valid and complete else None,
                       "baseline_ratio": None})
    return result


def final_gate(report):
    gate = copy.deepcopy(report["adoption"])
    gate["failures"] += [row["id"] + ": invalid candidate-only observation"
                         for row in report["added_summaries"] if not row["all_valid"]]
    gate["accepted"] = not gate["failures"]
    return gate


def collect(args):
    engine.collect(args)
    path = args.output.resolve() / "report.json"
    report = json.loads(path.read_text())
    report["complete"] = False
    plan = engine.plan_at(args.plan, args.plan_sha256)
    baseline = engine.qualification(args.baseline, plan, args.plan_sha256)
    candidate = engine.qualification(args.candidate, plan, args.plan_sha256)
    report["added_schedule"], report["added_samples"] = added_schedule(plan, baseline, candidate), []
    indexed = {item["case"]["id"]: item for item in plan["cases"]}
    build = candidate["build"]
    engine.write(path, report)
    for position, entry in enumerate(report["added_schedule"]):
        engine.plan_at(args.plan, args.plan_sha256)
        engine.require(engine.sha(build["binary"]) == build["binary_sha256"], "candidate binary changed")
        directory = path.parent / ("added-%04d" % position)
        row = engine.observe(build["binary"], indexed[entry["id"]], directory)
        row.update(**entry, arm="candidate", directory=str(directory), load_average_1_5_15=os.getloadavg())
        report["added_samples"].append(row)
        engine.write(path, report)
    report["added_summaries"] = added_summaries(plan, report["added_samples"])
    report["coverage_resource_gate"] = final_gate(report)
    report["complete"] = True
    engine.write(path, report)
    return {"report": str(path), "paired_samples": len(report["samples"]), "candidate_only_samples": len(report["added_samples"])}


def audit(args):
    result = engine.audit(args)
    plan = engine.plan_at(args.plan, args.plan_sha256)
    report = json.loads(args.report.read_text())
    baseline = engine.qualification(Path(report["baseline"]), plan, args.plan_sha256)
    candidate = engine.qualification(Path(report["candidate"]), plan, args.plan_sha256)
    schedule = added_schedule(plan, baseline, candidate)
    engine.require(report["added_schedule"] == schedule, "candidate-only schedule changed")
    engine.require([(row["id"], row["round"]) for row in report["added_samples"]] == [(row["id"], row["round"]) for row in schedule], "candidate-only observations changed")
    indexed = {item["case"]["id"]: item for item in plan["cases"]}
    for position, row in enumerate(report["added_samples"]):
        directory = args.report.resolve().parent / ("added-%04d" % position)
        engine.require(row["arm"] == "candidate" and row["directory"] == str(directory), "candidate-only artifact identity changed")
        engine.audit_observation(row, candidate["build"]["binary"], indexed[row["id"]], directory)
    engine.require(report["added_summaries"] == added_summaries(plan, report["added_samples"]), "candidate-only statistics differ")
    engine.require(report["coverage_resource_gate"] == final_gate(report), "coverage/resource gate differs")
    return {**result, "candidate_only_samples": len(report["added_samples"])}


SAMPLE_FIELDS = ("id", "arm", "round", "classification", "seconds", "time_to_detection_seconds", "returncode",
                 "timed_out", "detected_expected_hazard", "false_positive", "false_acceptance", "graph_accepted",
                 "peak_rss_kib", "user_seconds", "system_seconds", "executed_instructions", "diagnostics_sha256")


def publish(args):
    checked = audit(args)
    independent = json.loads(args.independent_audit.read_text())
    engine.require(independent.get("status") == "AUDITED" and independent.get("report_sha256") == checked["report_sha256"]
                   and independent.get("independent_statistics_recomputed") is True, "independent audit required")
    report = json.loads(args.report.read_text())
    rows = copy.deepcopy(report["summaries"])
    project = lambda row: {key: row[key] for key in SAMPLE_FIELDS if key in row}
    for row in rows:
        for arm in ("baseline", "candidate"):
            first = row[arm]["first"]
            row[arm]["first"] = project(first) if first else None
    gate = final_gate(report)
    builds, qualifications = {}, {}
    for arm in ("baseline", "candidate"):
        qualification = json.loads(Path(report[arm]).read_text())
        builds[arm] = {key: qualification["build"][key] for key in ("revision", "source_tree", "binary_sha256", "rustc", "cargo", "profile", "default_features", "features", "trust")}
        qualifications[arm] = {name: {"qualified": value["qualified"], "classification": value["analysis"]["classification"],
                                     "graph_completed": value["analysis"]["graph_completed"], "proved": bool(value["proof"] and value["proof"]["proved"])}
                               for name, value in qualification["results"].items()}
    payload = {"schema": 1, "scope": "Development replay with complete original obligations; seeded readiness hazards, no new application-bug claim.",
               "builds": builds, "qualification": qualifications, "rows": rows, "added_summaries": report["added_summaries"],
               "coverage_resource_gate": gate, "paired_samples": len(report["samples"]), "candidate_only_samples": len(report["added_samples"]),
               "audit": {**checked, "independent_audit_sha256": engine.sha(args.independent_audit), "manifest_sha256": engine.sha(engine.MANIFEST),
                         "protocol_sha256": engine.sha(engine.PROTOCOL), "runner_sha256": engine.sha(Path(__file__))}}
    engine.require(not args.output.exists(), "publication destination already exists")
    args.output.mkdir(parents=True)
    engine.write(args.output / "results.json", payload)
    all_samples = [project(row) for row in report["samples"] + report["added_samples"]]
    (args.output / "samples.json.gz").write_bytes(gzip.compress((json.dumps(all_samples, separators=(",", ":")) + "\n").encode(), mtime=0))
    return {"published": str(args.output), "samples": len(all_samples), "gate": gate}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    prepare = sub.add_parser("prepare")
    prepare.add_argument("--output", required=True, type=Path)
    for name in ("qualify", "collect", "audit", "publish"):
        child = sub.add_parser(name)
        child.add_argument("--plan", required=True, type=Path)
        child.add_argument("--plan-sha256", required=True)
        if name == "qualify":
            child.add_argument("--role", required=True, choices=("baseline", "candidate"))
            child.add_argument("--binary", required=True, type=Path)
            child.add_argument("--build", required=True, type=Path)
        if name == "collect":
            child.add_argument("--baseline", required=True, type=Path)
            child.add_argument("--candidate", required=True, type=Path)
        if name in ("prepare", "qualify", "collect", "publish"):
            child.add_argument("--output", required=True, type=Path)
        if name in ("audit", "publish"):
            child.add_argument("--report", required=True, type=Path)
        if name == "publish":
            child.add_argument("--independent-audit", required=True, type=Path)
    args = parser.parse_args()
    result = engine.prepare(args.output) if args.mode == "prepare" else engine.qualify(args) if args.mode == "qualify" else globals()[args.mode](args)
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
