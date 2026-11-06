#!/usr/bin/env python3
"""Publish complete, sanitized numerical results after the frozen audit passes."""

from __future__ import annotations

import argparse
from collections import Counter
import csv
import gzip
import hashlib
import importlib.util
import io
import json
import math
from pathlib import Path
import re

ARMS = ("baseline", "candidate")
PROPERTIES = {
    "AMD trace completeness",
    "AMD wait and register readiness",
    "AMD memory-conflict freedom",
    "AMD workgroup barrier generations",
}
CLASSIFICATIONS = {
    "verified",
    "finding",
    "unsupported",
    "inconclusive",
    "timeout",
    "crash",
    "contract_error",
    "graph_accepted_without_export",
    "spec_verified",
}
NUMBERS = (
    "seconds",
    "time_to_detection_seconds",
    "peak_rss_kib",
    "user_seconds",
    "system_seconds",
    "reported_execution_seconds",
    "executed_instructions",
)
FLAGS = (
    "timed_out",
    "graph_accepted",
    "detected_expected_hazard",
    "false_positive",
    "false_acceptance",
)
SAMPLE_COLUMNS = (
    "id",
    "target",
    "family",
    "expectation",
    "arm",
    "round",
    "first_observation",
    "returncode",
    "classification",
    *NUMBERS,
    *FLAGS,
    "detected_property",
    "measurement_error_count",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def hash_value(value, length=64):
    require(
        isinstance(value, str) and re.fullmatch(r"[a-f0-9]{%d}" % length, value),
        "invalid provenance hash",
    )
    return value


def number(value, *, nullable=False, integer=False):
    require(
        nullable
        and value is None
        or type(value) in ((int,) if integer else (int, float))
        and math.isfinite(value),
        "invalid numerical observation",
    )
    return value


def flag(value):
    require(type(value) is bool, "invalid Boolean observation")
    return value


def identifier(value):
    require(
        isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_-]+", value),
        "invalid public identifier",
    )
    return value


def category(value, allowed):
    require(value in allowed, "unrecognized result category")
    return value


def json_bytes(value):
    return (
        json.dumps(value, indent=2, sort_keys=True, allow_nan=False) + "\n"
    ).encode()


def compressed(data):
    stream = io.BytesIO()
    with gzip.GzipFile(
        filename="", mode="wb", fileobj=stream, mtime=0, compresslevel=9
    ) as output:
        output.write(data)
    return stream.getvalue()


def load_harness(path, plan):
    """Import the original checkout: copying compare.py changes its ROOT."""
    path = path.resolve(strict=True)
    expected = plan["input_sha256"].get(str(path))
    require(
        expected is not None and sha(path) == expected,
        "harness is not bound to the frozen plan",
    )
    require(
        all(
            Path(name).is_file() and sha(name) == expected
            for name, expected in plan["input_sha256"].items()
        ),
        "a frozen input changed before importing the harness",
    )
    spec = importlib.util.spec_from_file_location("frozen_amd_comparison_export", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    require(Path(module.__file__).resolve() == path, "unexpected harness source")
    return module


def sample(row, case):
    require(row["id"] == case["id"], "sample case differs")
    result = {name: identifier(case[name]) for name in ("id", "target", "family")}
    result.update(
        expectation=category(case["expectation"], {"safe", "hazard"}),
        arm=category(row["arm"], set(ARMS)),
        round=number(row["round"], integer=True),
        first_observation=row["round"] == 0,
        returncode=number(row["returncode"], integer=True),
        classification=category(row["classification"], CLASSIFICATIONS),
        detected_property=category(row.get("detected_property"), PROPERTIES | {None}),
        measurement_error_count=len(row["measurement_errors"]),
    )
    result.update(
        {
            name: number(
                row.get(name),
                nullable=name != "seconds",
                integer=name in {"peak_rss_kib", "executed_instructions"},
            )
            for name in NUMBERS
        }
    )
    result.update({name: flag(row[name]) for name in FLAGS})
    require(set(result) == set(SAMPLE_COLUMNS), "sample column contract differs")
    return result


def arm_summary(row, observations, expectation):
    """Retain failures alongside latency; no candidate outcome filters cases."""
    repeats = [value for value in observations if not value["first_observation"]]
    first = [value for value in observations if value["first_observation"]]
    require(len(first) <= 1, "duplicate first observation")
    return {
        **{
            name: number(row[name], integer=True)
            for name in ("observations", "repeats", "successful_repeats")
        },
        "complete_rounds": flag(row["complete_rounds"]),
        **{
            name: number(row[name], nullable=True)
            for name in ("median_seconds", "p95_seconds")
        },
        "first": first[0] if first else None,
        "repeated_outcomes": dict(
            sorted(Counter(value["classification"] for value in repeats).items())
        ),
        "repeated_misses": sum(
            not value["detected_expected_hazard"] for value in repeats
        )
        if expectation == "hazard"
        else None,
        "repeated_behavior_failures": sum(
            not value["detected_expected_hazard"]
            if expectation == "hazard"
            else not value["graph_accepted"]
            for value in repeats
        ),
        "repeated_timeouts": sum(value["timed_out"] for value in repeats),
        "repeated_false_positives": sum(value["false_positive"] for value in repeats),
        "repeated_false_acceptances": sum(
            value["false_acceptance"] for value in repeats
        ),
        "repeated_resource_errors": sum(
            value["measurement_error_count"] > 0 for value in repeats
        ),
    }


def qualification(row, case):
    analysis, proof = row["analysis"], row["proof"]
    return {
        "qualified": flag(row["qualified"]),
        "classification": category(analysis["classification"], CLASSIFICATIONS),
        "graph_accepted": flag(analysis["graph_accepted"]),
        "detected_expected_hazard": flag(analysis["detected_expected_hazard"]),
        "false_positive": flag(analysis["false_positive"]),
        "false_acceptance": flag(analysis["false_acceptance"]),
        "proof_complete": flag(proof["proved"]) if proof is not None else None,
        "expected_output_elements": number(case["expected_outputs"], integer=True),
        "proved_output_elements": sum(int(value) for value in proof["proof_counts"])
        if proof is not None
        else None,
        "output_expressions_sha256": hash_value(analysis["output_expressions_sha256"])
        if analysis.get("output_expressions_sha256")
        else None,
    }


def build_identity(row):
    result = {
        "revision": hash_value(row["revision"], 40),
        "source_tree": hash_value(row["source_tree"], 40),
        **{name: hash_value(row[name]) for name in ("binary_sha256", "receipt_sha256")},
        "trust": category(row["trust"], {"caller_attested"}),
        "source_clean": flag(row["source_clean"]),
        "profile": category(row["profile"], {"release"}),
        "default_features": flag(row["default_features"]),
        "features": [identifier(value) for value in row["features"]],
    }
    for name in ("rustc", "cargo"):
        version = re.match(
            r"^" + name + r" (\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?)\b", row[name]
        )
        require(version is not None, "missing compiler version")
        result[name + "_version"] = version[1]
        result[name + "_declaration_sha256"] = hashlib.sha256(
            row[name].encode()
        ).hexdigest()
    if row.get("original_build_receipt_sha256"):
        result["original_build_receipt_sha256"] = hash_value(
            row["original_build_receipt_sha256"]
        )
    return result


def context(row):
    model = row.get("cpu_model", "")
    vendor = (
        "AMD CPU"
        if re.search(r"\bAMD\b", model)
        else "Intel CPU"
        if re.search(r"\bIntel\b", model)
        else "unspecified CPU"
    )

    def load(values):
        require(len(values) == 3, "invalid load observation")
        return [number(value) for value in values]

    return {
        "cpu_model": vendor,
        "cpu_count": number(row["cpu_count"], nullable=True, integer=True),
        "load_before": load(row["load_before"]),
        "round_loads": [
            {"round": number(item["round"], integer=True), "load": load(item["load"])}
            for item in row["round_loads"]
        ],
    }


def publication(plan, report, raw_samples, qualifications, root):
    items = {item["case"]["id"]: item for item in plan["cases"]}
    cases = {name: item["case"] for name, item in items.items()}
    require(
        len(cases) == len(plan["cases"]) == len(report["results"]) == 67,
        "all 67 case outcomes are required",
    )
    require(
        [row["id"] for row in report["results"]] == list(cases),
        "case denominator or order differs",
    )
    require(
        len(raw_samples) == len(report["eligible"]) * 2 * (report["repeats"] + 1),
        "timing sample denominator differs",
    )
    samples = [sample(row, cases[row["id"]]) for row in raw_samples]
    by_case = {(name, arm): [] for name in cases for arm in ARMS}
    for row in samples:
        by_case[(row["id"], row["arm"])].append(row)
    qualified = {
        arm: {row["id"]: row for row in rows["results"]}
        for arm, rows in qualifications.items()
    }
    results = []
    for row in report["results"]:
        case = cases[row["id"]]
        entry = {name: identifier(case[name]) for name in ("id", "target", "family")}
        entry.update(
            expectation=category(case["expectation"], {"safe", "hazard"}),
            qualification={
                arm: qualification(qualified[arm][row["id"]], case) for arm in ARMS
            },
            **{
                arm: arm_summary(
                    row[arm], by_case[(row["id"], arm)], case["expectation"]
                )
                for arm in ARMS
            },
            candidate_over_baseline_median=number(
                row["candidate_over_baseline_median"], nullable=True
            ),
            materialized_assembly_sha256=hash_value(
                items[case["id"]]["assembly_sha256"]
            ),
        )
        ratio = entry["candidate_over_baseline_median"]
        entry["qualification_regression"] = (
            entry["qualification"]["baseline"]["qualified"]
            and not entry["qualification"]["candidate"]["qualified"]
        )
        entry["repeated_behavior_regression"] = (
            entry["candidate"]["repeated_behavior_failures"]
            > entry["baseline"]["repeated_behavior_failures"]
        )
        entry["functional_regression"] = (
            entry["qualification_regression"] or entry["repeated_behavior_regression"]
        )
        entry["candidate_slower_median"] = ratio > 1 if ratio is not None else None
        if case["expectation"] == "safe":
            entry["output_expressions_equal"] = flag(row["output_expressions_equal"])
        results.append(entry)
    public_inputs = {}
    for path, value in plan["input_sha256"].items():
        relative = Path(path).resolve().relative_to(root.resolve())
        require(
            all(re.fullmatch(r"[A-Za-z0-9_.-]+", part) for part in relative.parts),
            "invalid public source path",
        )
        public_inputs[relative.as_posix()] = hash_value(value)
    return {
        "schema": 1,
        "scope": {
            "population": "All 67 frozen AMD development configurations: 43 safe and 24 seeded hazardous; configurations are not distinct algorithms or newly discovered application bugs.",
            "semantics": "Original assembly, launch configurations, selected workgroups, output coordinates and mathematical specifications are preserved. Results cover configured workgroups and mathematical-real arithmetic, not inter-workgroup safety or bit-exact floating point.",
            "validation": "Each safe case requires a complete output export and a specification proof over every configured element; intended hazards require a complete graph rejection. Heldouts are not executed or used for prospective validation or tuning.",
            "timing": "Baseline qualification alone selects timing cases; candidate failures remain. First observations are separate from 31 repeated fresh-process rounds. Hazard latency measures parent-observed intended-diagnostic arrival, validated against the complete final graph; safe timing measures process completion without expression export.",
            "statistics": "Per-case medians and nearest-rank p95; ratios require qualification and all 31 successful measured repeats in both arms. No outlier removal, adaptive retry, cold-cache, CPU-isolation or statistical-significance claim.",
            "provenance": "Build declarations and clock observations are caller attestations. Hashes bind retained files; they do not independently prove reproducible builds or measurements.",
        },
        "denominators": {
            "configurations": len(cases),
            "expectations": dict(
                sorted(Counter(case["expectation"] for case in cases.values()).items())
            ),
            "targets": dict(
                sorted(Counter(case["target"] for case in cases.values()).items())
            ),
            "baseline_qualified": sum(
                flag(row["qualified"]) for row in qualified["baseline"].values()
            ),
            "candidate_qualified": sum(
                flag(row["qualified"]) for row in qualified["candidate"].values()
            ),
            "timed_configurations": len(report["eligible"]),
            "untimed_configurations": [
                name for name in cases if name not in report["eligible"]
            ],
            "first_observations": sum(row["first_observation"] for row in samples),
            "repeated_observations": sum(
                not row["first_observation"] for row in samples
            ),
            "total_observations": len(samples),
            "maximum_observations": len(cases) * 2 * (report["repeats"] + 1),
            "eligible_ratios": sum(
                row["candidate_over_baseline_median"] is not None for row in results
            ),
            "functional_regressions": sum(
                row["functional_regression"] for row in results
            ),
            "slower_candidate_medians": sum(
                row["candidate_slower_median"] is True for row in results
            ),
        },
        "protocol": {
            name: number(report[name], integer=True) for name in ("repeats", "seed")
        },
        "context": context(report["context"]),
        "identities": {arm: build_identity(report["identities"][arm]) for arm in ARMS},
        "frozen_input_sha256": public_inputs,
        "results": results,
    }, samples


def export(args):
    plan_path, report_path = (
        args.plan.resolve(strict=True),
        args.report.resolve(strict=True),
    )
    require(
        sha(plan_path) == args.plan_sha256, "plan hash differs from reviewed freeze"
    )
    plan = json.loads(plan_path.read_text())
    harness = load_harness(args.harness, plan)
    require(
        not args.output.exists()
        and not args.output.resolve().is_relative_to(harness.ROOT)
        and not args.output.resolve().is_relative_to(
            Path(__file__).resolve().parents[3]
        ),
        "output must be fresh and outside both repositories",
    )
    report = harness.audit_collection(report_path, plan_path, args.plan_sha256)
    sample_path, schedule_path = (
        report_path.parent / "samples.json",
        report_path.parent / "schedule.json",
    )
    pins = {
        str(plan_path): args.plan_sha256,
        str(report_path): sha(report_path),
        str(sample_path): report["samples_sha256"],
        str(schedule_path): report["schedule_sha256"],
        str(Path(__file__).resolve()): sha(__file__),
    }
    qualifications = {}
    for arm in ARMS:
        path = Path(report["qualification_paths"][arm])
        pins[str(path)] = report["qualification_sha256"][arm]
        qualifications[arm] = json.loads(path.read_text())
    harness.unchanged(pins)
    document, samples = publication(
        plan, report, json.loads(sample_path.read_text()), qualifications, harness.ROOT
    )
    document["provenance"] = {
        "plan_sha256": hash_value(args.plan_sha256),
        "raw_report_sha256": hash_value(pins[str(report_path)]),
        "raw_samples_sha256": hash_value(report["samples_sha256"]),
        "schedule_sha256": hash_value(report["schedule_sha256"]),
        "qualification_sha256": {
            arm: hash_value(report["qualification_sha256"][arm]) for arm in ARMS
        },
        "case_contract_sha256": hash_value(plan["case_digest"]),
        "harness_sha256": sha(args.harness),
        "exporter_sha256": sha(__file__),
    }
    csv_stream = io.StringIO(newline="")
    writer = csv.writer(csv_stream, lineterminator="\n")
    writer.writerow(SAMPLE_COLUMNS)
    for row in samples:
        writer.writerow(
            ""
            if row[name] is None
            else json.dumps(row[name], allow_nan=False)
            if type(row[name]) is not str
            else row[name]
            for name in SAMPLE_COLUMNS
        )
    payloads = {
        "results.json": json_bytes(document),
        "samples.json.gz": compressed(json_bytes(samples)),
        "samples.csv.gz": compressed(csv_stream.getvalue().encode()),
    }
    # Re-audit after serialization so publication cannot race an altered receipt.
    harness.unchanged(pins)
    require(
        harness.audit_collection(report_path, plan_path, args.plan_sha256) == report,
        "audited collection changed during export",
    )
    harness.unchanged(pins)
    args.output.mkdir(parents=True, exist_ok=False)
    for name, data in payloads.items():
        (args.output / name).write_bytes(data)
    manifest = {
        "schema": 1,
        "status": "AUDITED_EXPORT",
        "denominators": document["denominators"],
        "provenance": document["provenance"],
        "files_sha256": {
            name: hashlib.sha256(data).hexdigest() for name, data in payloads.items()
        },
    }
    (args.output / "manifest.json").write_bytes(json_bytes(manifest))
    print(
        json.dumps(
            {
                "status": "AUDITED_EXPORT",
                "cases": len(document["results"]),
                "samples": len(samples),
                "manifest_sha256": sha(args.output / "manifest.json"),
            }
        )
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("harness", "plan", "report", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--plan-sha256", required=True)
    export(parser.parse_args())


if __name__ == "__main__":
    main()
