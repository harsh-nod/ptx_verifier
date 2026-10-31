#!/usr/bin/env python3
"""Prepare and collect the frozen five-pair comparison, without optional exports."""

from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("native_lazy_frozen", HERE / "collect.py")
frozen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(frozen)
require, sha, write = frozen.require, frozen.sha, frozen.write
BASELINE_PLAN_SHA = "9c05c6dbf68410c95255aa049047f8e27e5e38321de452181c464e359a91b4be"
BASELINE_REPORT_SHA = "2b44f922b3108cab60a299e2e28612c9db96744cb0b827193f1327cd5d09e7ea"
OTHER_BUDGET = 256 * 2**20
METADATA_RESERVE = 16 * 2**20


def baseline(plan_path, report_path):
    plan = frozen.checked_plan(plan_path, BASELINE_PLAN_SHA)
    require(
        sha(report_path) == BASELINE_REPORT_SHA, "not the frozen baseline qualification"
    )
    report = json.loads(report_path.read_text())
    ids = [r["case"]["id"] for r in plan["cases"]]
    rows = report["results"]
    require(
        report["role"] == "baseline" and report["plan_sha256"] == BASELINE_PLAN_SHA,
        "baseline role/plan differs",
    )
    require(
        len(rows) == len({r["case"] for r in rows}) == 28
        and {r["case"] for r in rows} == set(ids),
        "baseline denominator differs",
    )
    require(
        report["timing_eligible"] == [r["case"] for r in rows if r["qualified"]]
        and len(report["timing_eligible"]) == 27,
        "baseline-only eligibility differs",
    )
    for row in rows:
        for name in ("stdout", "stderr", "resources"):
            path = (
                report_path.parent
                / row["case"]
                / ("resources.txt" if name == "resources" else name)
            )
            require(
                path.is_file() and sha(path) == row[name + "_sha256"],
                "baseline transcript changed",
            )
    return plan, report


def candidate_report(path, expected_sha, plan, prepared):
    require(sha(path) == expected_sha, "candidate qualification changed")
    result = json.loads(path.read_text())
    ids = {r["case"]["id"] for r in plan["cases"]}
    rows = result["results"]
    require(
        result["role"] == "candidate" and result["plan_sha256"] == BASELINE_PLAN_SHA,
        "candidate qualification role/plan differs",
    )
    require(
        result["build"] == prepared["candidate"]["identity"],
        "candidate qualification executable/build differs",
    )
    require(
        len(rows) == len({r["case"] for r in rows}) == 28
        and {r["case"] for r in rows} == ids,
        "candidate must retain all28 functional outcomes",
    )
    require(
        result["timing_eligible"] == prepared["eligible"],
        "candidate altered baseline-only eligibility",
    )
    case_rows = {r["case"]["id"]: r for r in plan["cases"]}
    frozen_baseline = json.loads(Path(prepared["baseline_report"]).read_text())
    original = {r["case"]: r for r in frozen_baseline["results"]}
    for row in rows:
        case_row = case_rows[row["case"]]
        require(
            row["command"]
            == frozen.command(Path(prepared["candidate"]["binary"]), case_row),
            "candidate qualification invocation changed",
        )
        for name in ("stdout", "stderr", "resources"):
            source = (
                path.parent
                / row["case"]
                / ("resources.txt" if name == "resources" else name)
            )
            require(
                source.is_file() and sha(source) == row[name + "_sha256"],
                "candidate transcript changed",
            )
        stdout = (path.parent / row["case"] / "stdout").read_text(errors="replace")
        stderr = (path.parent / row["case"] / "stderr").read_text(errors="replace")
        reference = (
            original[row["case"]]["signature"]
            if original[row["case"]]["qualified"]
            else case_row["expected_reference"]
            if case_row["case"]["expectation"] == "hazard"
            else None
        )
        replay = frozen.observe(row, case_row, stdout, stderr, reference)
        for key in (
            "status",
            "qualified",
            "signature",
            "measurement_errors",
            "false_positive",
            "unsafe_acceptance",
            "endpoint_seconds",
            "detected",
            "detection_mode",
        ):
            require(
                row[key] == replay[key],
                "candidate classification differs from bound raw transcript",
            )
        require(
            row["raw_log_bytes"]
            == (path.parent / row["case"] / "stdout").stat().st_size
            + (path.parent / row["case"] / "stderr").stat().st_size,
            "candidate raw log byte count differs",
        )
        row.update(
            qualification_graph_diagnostics(stdout, case_row["case"]["expectation"])
        )
    return result


def qualification_graph_diagnostics(stdout, expectation):
    graph = frozen.corpus.harness.parse_cli(stdout)
    return {
        "declared_expectation": expectation,
        "graph_failure_names": [
            name for name, verdict, _ in graph.checks if verdict == "FAIL"
        ],
    }


def schedule_valid(schedule, eligible):
    expected = {
        (cid, repeat, role)
        for cid in eligible
        for repeat in range(1, 6)
        for role in ("baseline", "candidate")
    }
    tuples = [tuple(r) for r in schedule]
    require(
        len(tuples) == len(set(tuples)) and set(tuples) == expected,
        "missing/duplicate/out-of-scope paired observation",
    )
    require(tuples == frozen.paired_order(eligible), "fixed seed/order changed")
    for left, right in zip(tuples[::2], tuples[1::2]):
        require(
            left[:2] == right[:2] and {left[2], right[2]} == {"baseline", "candidate"},
            "non-adjacent arm pair",
        )


def prepare(args):
    plan, report = baseline(args.baseline_plan, args.baseline_report)
    require(
        subprocess.run(
            [
                "git",
                "-C",
                str(frozen.ROOT),
                "merge-base",
                "--is-ancestor",
                frozen.PARENT,
                args.candidate_revision,
            ],
            capture_output=True,
        ).returncode
        == 0,
        "candidate lacks common parent",
    )
    identity = frozen.study.build_records.build_identity(
        args.candidate_build, args.candidate_revision, args.candidate
    )
    patch = frozen.git("diff", "--binary", frozen.PARENT, args.candidate_revision, "--")
    require(
        frozen.study.digest(patch) == args.reviewed_patch_sha256,
        "candidate differs from reviewed patch",
    )
    output = frozen.fresh(args.output)
    (output / "candidate.patch").write_bytes(patch)
    paths = [
        args.baseline_plan,
        args.baseline_report,
        args.candidate,
        args.candidate_build,
        output / "candidate.patch",
        Path(sys.executable),
        *[
            HERE / name
            for name in (
                "comparison.py",
                "semantics.py",
                "test_comparison.py",
                "test_semantics.py",
                "collection.md",
                "compare_vexpr_structure_20261031.py",
                "test_compare_vexpr_structure_20261031.py",
            )
        ],
    ]
    pins = {str(p.resolve()): sha(p) for p in paths}
    pins.update(plan["input_sha256"])
    for row in report["results"]:
        for name in ("stdout", "stderr", "resources.txt"):
            p = args.baseline_report.parent / row["case"] / name
            pins[str(p.resolve())] = sha(p)
    require(
        sha(HERE / "compare_vexpr_structure_20261031.py") == frozen.COMPARATOR_SHA
        and sha(HERE / "test_compare_vexpr_structure_20261031.py")
        == frozen.COMPARATOR_TESTS_SHA,
        "published comparator copy differs from frozen authority",
    )
    eligible = report["timing_eligible"]
    schedule = frozen.paired_order(eligible)
    schedule_valid(schedule, eligible)
    safe = [
        r["case"]["id"]
        for r in plan["cases"]
        if r["case"]["id"] in eligible and r["case"]["expectation"] == "safe"
    ]
    require(
        len(safe) == 13 and len(schedule) == 270,
        "frozen paired/semantic denominator differs",
    )
    qualify = [
        sys.executable,
        str(HERE / "collect.py"),
        "qualify",
        "--role",
        "candidate",
        "--plan",
        str(args.baseline_plan.resolve()),
        "--reviewed-plan-sha256",
        BASELINE_PLAN_SHA,
        "--binary",
        str(args.candidate.resolve()),
        "--build",
        str(args.candidate_build.resolve()),
        "--revision",
        args.candidate_revision,
        "--reviewed-patch-sha256",
        args.reviewed_patch_sha256,
        "--baseline-report",
        str(args.baseline_report.resolve()),
        "--baseline-report-sha256",
        BASELINE_REPORT_SHA,
        "--output",
        str(output / "candidate-qualification"),
    ]
    write(
        output / "plan.json",
        {
            "schema_version": 1,
            "baseline_plan": str(args.baseline_plan.resolve()),
            "baseline_report": str(args.baseline_report.resolve()),
            "baseline_report_sha256": BASELINE_REPORT_SHA,
            "structural_comparator": {
                "path": str(HERE / "compare_vexpr_structure_20261031.py"),
                "sha256": frozen.COMPARATOR_SHA,
                "tests_sha256": frozen.COMPARATOR_TESTS_SHA,
            },
            "candidate": {
                "binary": str(args.candidate.resolve()),
                "build": str(args.candidate_build.resolve()),
                "identity": identity,
                "reviewed_patch_sha256": args.reviewed_patch_sha256,
            },
            "input_sha256": pins,
            "eligible": eligible,
            "schedule": schedule,
            "safe_semantic_cases": safe,
            "candidate_qualification_command": qualify,
            "semantic_schedule": [
                [cid, role, stage]
                for cid in safe
                for role in ("baseline", "candidate")
                for stage in ("export", "verify")
            ],
            "budgets": {
                "timeout_seconds": 60,
                "repeats": 5,
                "seed": 20261031,
                "gzip_bytes": 2**31,
                "reserve_bytes": 2**31,
                "other_bytes": OTHER_BUDGET,
            },
            "limits": [
                "Baseline-only eligibility is immutable; candidate qualification retains all28 outcomes.",
                "Timed processes contain no export/spec command; one-off controls supply no performance claim.",
            ],
        },
    )
    print(
        "Prepared270 paired observations and52 separate semantic/spec processes;0 verifier processes; plan SHA256 "
        + sha(output / "plan.json")
    )


def checked(path, expected_sha):
    require(sha(path) == expected_sha, "reviewed comparison plan differs")
    prepared = json.loads(path.read_text())
    frozen.bench.unchanged(prepared["input_sha256"])
    plan, report = baseline(
        Path(prepared["baseline_plan"]), Path(prepared["baseline_report"])
    )
    require(
        prepared["eligible"] == report["timing_eligible"],
        "comparison eligibility changed",
    )
    schedule_valid(prepared["schedule"], prepared["eligible"])
    expected_safe = [
        r["case"]["id"]
        for r in plan["cases"]
        if r["case"]["id"] in prepared["eligible"]
        and r["case"]["expectation"] == "safe"
    ]
    require(
        prepared["safe_semantic_cases"] == expected_safe
        and prepared["semantic_schedule"]
        == [
            [cid, role, stage]
            for cid in expected_safe
            for role in ("baseline", "candidate")
            for stage in ("export", "verify")
        ],
        "semantic denominator/order changed",
    )
    require(
        prepared["budgets"]
        == {
            "timeout_seconds": 60,
            "repeats": 5,
            "seed": 20261031,
            "gzip_bytes": 2**31,
            "reserve_bytes": 2**31,
            "other_bytes": OTHER_BUDGET,
        },
        "budgets changed",
    )
    return prepared, plan, report


def other_bytes(prepared, plan_path):
    roots = {
        Path(prepared["baseline_plan"]).parent,
        Path(prepared["baseline_report"]).parent,
        plan_path.parent,
    }
    return sum(
        p.stat().st_size
        for root in roots
        for p in root.rglob("*")
        if p.is_file() and p.suffix != ".gz"
    )


def log_budget(prepared, plan_path, used):
    return max(
        0,
        min(
            frozen.LOG_LIMIT,
            frozen.COLLECTION_LOG_LIMIT - used,
            OTHER_BUDGET - METADATA_RESERVE - other_bytes(prepared, plan_path),
        ),
    )


def functional(report, candidate):
    old = {r["case"]: r for r in report["results"]}
    rows = candidate["results"]
    retained = all(r["qualified"] for r in rows if old[r["case"]]["qualified"])
    safe_graph_failures = [
        r
        for r in rows
        if r.get("declared_expectation") == "safe" and r.get("graph_failure_names")
    ]
    return {
        "candidate_cases": len(rows),
        "baseline_qualified": len(report["timing_eligible"]),
        "all_baseline_qualifiers_retained": retained,
        "false_findings": sum(r["false_positive"] for r in rows),
        "safe_graph_failures": [
            {"case": r["case"], "properties": r["graph_failure_names"]}
            for r in safe_graph_failures
        ],
        "unsafe_acceptances": sum(r["unsafe_acceptance"] for r in rows),
        "baseline_unqualified_outcomes": [
            {
                "case": r["case"],
                "status": r["status"],
                "qualified": r["qualified"],
                "measurement_errors": r["measurement_errors"],
            }
            for r in rows
            if not old[r["case"]]["qualified"]
        ],
        "passed": retained
        and not safe_graph_failures
        and not any(r["false_positive"] or r["unsafe_acceptance"] for r in rows),
    }


def execute_pair(binary, row, directory, reference, *, log_limit):
    try:
        return frozen.execute(binary, row, directory, reference, log_limit=log_limit)
    except (OSError, ValueError) as error:
        directory.mkdir(parents=True, exist_ok=True)
        for name in ("stdout", "stderr"):
            if not (directory / name).exists():
                (directory / name).write_bytes(b"")
        stdout, stderr = [
            (directory / name).read_text(errors="replace")
            for name in ("stdout", "stderr")
        ]
        record = {
            "command": frozen.command(binary, row),
            "returncode": None,
            "timed_out": False,
            "log_limit_exceeded": False,
            "seconds": 0,
            "first_marker_seconds": None,
            "usage": {},
            "raw_log_bytes": sum(
                (directory / name).stat().st_size for name in ("stdout", "stderr")
            ),
            "capture_failure": type(error).__name__ + ": " + str(error),
        }
        return {
            **frozen.observe(record, row, stdout, stderr, reference),
            "stdout_sha256": sha(directory / "stdout"),
            "stderr_sha256": sha(directory / "stderr"),
            "resources_sha256": sha(directory / "resources.txt")
            if (directory / "resources.txt").exists()
            else None,
        }


def summarize(plan, prepared, samples):
    actual = [(r["case"], r["repeat"], r["role"]) for r in samples]
    require(
        actual == [tuple(x) for x in prepared["schedule"]],
        "sample schedule/cardinality differs",
    )
    definitions = {r["case"]["id"]: r["definition"] for r in plan["cases"]}
    rows = []
    for cid in prepared["eligible"]:
        groups = {
            role: [r for r in samples if r["case"] == cid and r["role"] == role]
            for role in ("baseline", "candidate")
        }
        rows.append(
            {
                "case": cid,
                "primary": definitions[cid]["primary"],
                **frozen.point_gate(
                    groups["baseline"], groups["candidate"], definitions[cid]["primary"]
                ),
            }
        )
    wins = sum(r["benefit"] for r in rows)
    return {
        "cases": rows,
        "primary_wins": wins,
        "primaries_required": 2,
        "performance_point_gates_pass": wins >= 2
        and all(
            r["valid"] and r["endpoint_nonregression"] and r["rss_nonregression"]
            for r in rows
        ),
        "candidate_acceptance": "pending separate semantic/proof controls and independent audit",
        "limits": [
            "Exactly five observations per arm; descriptive medians/maxima, no p95/CI inference.",
            "Every timeout/failure remains; no substitute latency or RSS ratio.",
        ],
    }


def pairs(args):
    prepared, plan, report = checked(args.plan, args.reviewed_plan_sha256)
    candidate = candidate_report(
        args.candidate_qualification,
        args.candidate_qualification_sha256,
        plan,
        prepared,
    )
    directory = frozen.fresh(args.plan.parent / "paired")
    rows = {r["case"]["id"]: r for r in plan["cases"]}
    refs = {r["case"]: r["signature"] for r in report["results"]}
    samples, used = [], 0
    for cid, repeat, role in prepared["schedule"]:
        binary = Path(
            plan["baseline"]["binary"]
            if role == "baseline"
            else prepared["candidate"]["binary"]
        )
        result = execute_pair(
            binary,
            rows[cid],
            directory / cid / f"{repeat}-{role}",
            refs[cid],
            log_limit=log_budget(prepared, args.plan, used),
        )
        used += result["raw_log_bytes"]
        samples.append({"case": cid, "repeat": repeat, "role": role, **result})
        write(directory / "checkpoint.json", {"samples": samples})
        print(
            f"Paired observation {len(samples)}/270: {cid} {repeat} {role} {result['status']}",
            flush=True,
        )
    frozen.bench.unchanged(prepared["input_sha256"])
    require(
        sha(args.candidate_qualification) == args.candidate_qualification_sha256,
        "candidate qualification changed during comparison",
    )
    write(
        directory / "report.json",
        {
            "schema_version": 1,
            "plan_sha256": sha(args.plan),
            "candidate_qualification_sha256": args.candidate_qualification_sha256,
            "runtime_context": frozen.bench.statistics.runtime_context(),
            "samples": samples,
            "functional": functional(report, candidate),
            "summary": summarize(plan, prepared, samples),
            "aggregate_raw_log_bytes": used,
            "other_bytes": other_bytes(prepared, args.plan),
        },
    )
    print("Paired report SHA256 " + sha(directory / "report.json"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    prep = commands.add_parser("prepare")
    for flag in (
        "baseline-plan",
        "baseline-report",
        "candidate",
        "candidate-build",
        "output",
    ):
        prep.add_argument("--" + flag, type=Path, required=True)
    for flag in ("candidate-revision", "reviewed-patch-sha256"):
        prep.add_argument("--" + flag, required=True)
    prep.set_defaults(function=prepare)
    paired = commands.add_parser("pairs")
    for flag in ("plan", "candidate-qualification"):
        paired.add_argument("--" + flag, type=Path, required=True)
    for flag in ("reviewed-plan-sha256", "candidate-qualification-sha256"):
        paired.add_argument("--" + flag, required=True)
    paired.set_defaults(function=pairs)
    args = parser.parse_args()
    args.function(args)


if __name__ == "__main__":
    main()
