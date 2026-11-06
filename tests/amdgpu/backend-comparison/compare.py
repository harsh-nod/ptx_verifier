#!/usr/bin/env python3
"""Compare AMD backend revisions with frozen kernels and identical options."""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import platform
import random
import re
import statistics
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = "d88be6827351de697d7f7ae0ded77ac57ef908e1"
REPEATS = 31
SEED = 20261106
TIMEOUT = 60


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


study = module(
    "backend_comparison_safety_corpus", HERE.parent / "design-study/benchmark.py"
)
corpus = study.corpus
require = corpus.require


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def digest(value):
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def write(path, value):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def fresh(path):
    require(
        not path.exists() and not path.resolve().is_relative_to(ROOT),
        "output must be fresh and outside the repository",
    )
    path.mkdir(parents=True)
    return path.resolve()


def selected():
    document = study.load_cases()
    cases = [
        case
        for case in document["cases"]
        if case["split"] == "development" and case.get("backend", "amdgpu") == "amdgpu"
    ]
    require(
        len(cases) == 67
        and Counter(c["expectation"] for c in cases) == {"safe": 43, "hazard": 24},
        "predeclared AMD development denominator changed",
    )
    require(
        Counter(c["target"] for c in cases)
        == {"gfx942": 18, "gfx950": 9, "gfx1250": 40},
        "predeclared target population changed",
    )
    return cases


def inputs():
    paths = {
        Path(__file__),
        Path(study.__file__),
        Path(corpus.__file__),
        study.MANIFEST,
        HERE / "protocol.json",
        ROOT / "ai_compiler_kernels/check_races.py",
    }
    for case in selected():
        paths.update(
            ROOT / case[key]
            for key in ("source", "assembly", "spec", "launch_config")
            if case.get(key)
        )
    return {str(path): sha(path) for path in sorted(paths)}


def unchanged(pins):
    require(
        all(
            Path(path).is_file() and sha(path) == expected
            for path, expected in pins.items()
        ),
        "a frozen input, executable, or measurement helper changed",
    )


def prepare(args):
    out = fresh(args.output)
    cases = selected()
    protocol = json.loads((HERE / "protocol.json").read_text())
    require(
        protocol["baseline_revision"] == BASE
        and protocol["repeats"] == REPEATS
        and protocol["seed"] == SEED
        and protocol["timeout_seconds"] == TIMEOUT,
        "fixed protocol changed",
    )
    rows = []
    for case in cases:
        directory = out / case["id"]
        directory.mkdir()
        assembly = study.materialize(case, directory)
        rows.append(
            {"case": case, "assembly": str(assembly), "assembly_sha256": sha(assembly)}
        )
    plan = {
        "schema": 1,
        "baseline_revision": BASE,
        "protocol": protocol,
        "cases": rows,
        "case_digest": digest(cases),
        "input_sha256": inputs(),
        "heldouts_executed": 0,
    }
    write(out / "plan.json", plan)
    print(
        json.dumps(
            {
                "plan": str(out / "plan.json"),
                "sha256": sha(out / "plan.json"),
                "cases": len(rows),
            }
        )
    )


def plan_at(path, expected):
    require(sha(path) == expected, "plan hash differs from reviewed freeze")
    plan = json.loads(path.read_text())
    require(
        plan["baseline_revision"] == BASE and plan["case_digest"] == digest(selected()),
        "comparison population changed",
    )
    require(
        [row["case"] for row in plan["cases"]] == selected(), "case contracts changed"
    )
    require(
        plan["protocol"] == json.loads((HERE / "protocol.json").read_text()),
        "protocol differs",
    )
    unchanged(plan["input_sha256"])
    unchanged({row["assembly"]: row["assembly_sha256"] for row in plan["cases"]})
    return plan


def plan_pins(path, expected, plan):
    """Include materialized mutations and the plan itself in every freeze."""
    return {
        **plan["input_sha256"],
        str(path.resolve()): expected,
        **{row["assembly"]: row["assembly_sha256"] for row in plan["cases"]},
    }


def build_identity(binary, receipt, revision):
    require(re.fullmatch(r"[0-9a-f]{40}", revision), "source revision must be exact")
    record = json.loads(receipt.read_text())
    require(
        record.get("trust") == "caller_attested" and record.get("source_clean") is True,
        "clean, caller-attested build declaration is required",
    )
    require(
        record.get("revision") == revision
        and record.get("binary_sha256") == sha(binary),
        "binary or source declaration differs",
    )
    require(
        record.get("profile") == "release"
        and record.get("default_features") is True
        and record.get("features") == [],
        "release/default-feature builds required",
    )
    require(
        record.get("source_tree")
        == subprocess.check_output(
            ["git", "-C", str(ROOT), "rev-parse", revision + "^{tree}"], text=True
        ).strip(),
        "declared source tree differs from Git",
    )
    if record.get("comparison_role") == "baseline":
        base_tree = subprocess.check_output(
            ["git", "-C", str(ROOT), "rev-parse", BASE + "^{tree}"], text=True
        ).strip()
        require(
            record["source_tree"] == base_tree,
            "baseline source differs from frozen base",
        )
    else:
        require(
            subprocess.run(
                ["git", "-C", str(ROOT), "merge-base", "--is-ancestor", BASE, revision],
                capture_output=True,
            ).returncode
            == 0,
            "candidate lacks common baseline",
        )
    require(
        record.get("comparison_role") in {"baseline", "candidate"}, "unknown build role"
    )
    require(
        all(
            isinstance(record.get(name), str) and record[name]
            for name in ("rustc", "cargo")
        ),
        "compiler/toolchain declarations are required",
    )
    if record.get("original_build_receipt"):
        require(
            sha(Path(record["original_build_receipt"]))
            == record.get("original_build_receipt_sha256"),
            "original build receipt changed",
        )
    return {
        **record,
        "receipt_sha256": sha(receipt),
        "build_record": str(receipt.resolve()),
        "binary": str(binary.resolve()),
    }


def build_pins(identity):
    pins = {
        identity["binary"]: identity["binary_sha256"],
        identity["build_record"]: identity["receipt_sha256"],
    }
    if identity.get("original_build_receipt"):
        pins[identity["original_build_receipt"]] = identity[
            "original_build_receipt_sha256"
        ]
    return pins


def matching_builds(baseline, candidate):
    for name in ("rustc", "cargo", "profile", "default_features", "features"):
        require(
            name in baseline
            and name in candidate
            and baseline[name] == candidate[name],
            "comparison build/toolchain differs: " + name,
        )


def observations(row, directory, *, verify=False, case=None):
    stdout = (directory / "stdout").read_text()
    stderr = (directory / "stderr").read_text()
    graph = corpus.harness.parse_cli(stdout)
    checks = {name: verdict for name, verdict, _ in graph.checks}
    required = {
        "AMD trace completeness",
        "AMD wait and register readiness",
        "AMD memory-conflict freedom",
        "AMD workgroup barrier generations",
    }
    # Use the exact existing CLI checker set; missing/extra checks cannot accept.
    require_names = {name for name, _, _ in graph.checks}
    invalid = bool(
        re.search(
            r"\bUNKNOWN\b|\bunsupported\b|execution stopped:|trace: (?:aborted|unsupported)",
            stdout + stderr,
            re.I,
        )
    )
    complete = len(graph.checks) == len(checks) == 4 and require_names == required
    passing = complete and all(v == "PASS" for v in checks.values())
    graph_verdicts = re.findall(r"^GRAPH VERIFICATION: (\w+)", stdout, re.M)
    graph_pass = (
        row["returncode"] == 0
        and not row["timed_out"]
        and graph_verdicts == ["VERIFIED"]
        and passing
        and not invalid
        and not re.search(r"^VERDICT:|^EARLY_", stdout, re.M)
    )
    proof_counts = re.findall(r"^VC check:.*  elements: (\d+)\s*$", stdout, re.M)
    proved = (
        verify
        and row["returncode"] == 0
        and not row["timed_out"]
        and passing
        and not invalid
        and re.findall(r"^VERDICT: (\w+)$", stdout, re.M) == ["ACCEPT"]
        and re.findall(r"^EQUIVALENT \(matches spec\)$", stdout, re.M)
        == ["EQUIVALENT (matches spec)"]
        and "NOT EQUIVALENT" not in stdout
        and graph_verdicts in ([], ["VERIFIED"])
        and not re.search(r"^EARLY_", stdout, re.M)
    )
    result = {
        **row,
        "graph_accepted": bool(graph_pass),
        "proof_accepted": bool(proved),
        "proof_counts": proof_counts,
    }
    if case is not None:
        intended = set(
            case.get("valid_detection_properties", [case.get("required_property")])
        )
        failed = {name for name, verdict in checks.items() if verdict == "FAIL"}
        latency, wall = row.get("time_to_detection_seconds"), row.get("seconds")
        valid_time = all(
            type(value) in (int, float) and math.isfinite(value)
            for value in (latency, wall)
        )
        valid_time = valid_time and 0 <= latency <= wall
        detected = (
            case["expectation"] == "hazard"
            and not verify
            and row["returncode"] == 1
            and not row["timed_out"]
            and complete
            and not invalid
            and graph_verdicts == ["REJECTED"]
            and checks["AMD trace completeness"] == "PASS"
            and set(checks.values()) <= {"PASS", "FAIL"}
            and bool(intended & failed)
            and row.get("detected_property") in intended & failed
            and valid_time
            and not re.search(r"^VERDICT:|^EARLY_", stdout, re.M)
        )
        result.update(
            detected_expected_hazard=bool(detected),
            time_to_detection_seconds=latency if detected else None,
            false_positive=case["expectation"] == "safe"
            and row["returncode"] == 1
            and complete
            and not invalid
            and graph_verdicts == ["REJECTED"]
            and checks["AMD trace completeness"] == "PASS"
            and bool(failed),
            false_acceptance=case["expectation"] == "hazard" and bool(graph_pass),
        )
    return result


def resource_observations(directory):
    """Read the retained per-process measurement, refusing ambiguous fields."""
    path = directory / "resources.txt"
    fields = ("max_rss_kib", "user_seconds", "system_seconds")
    pairs = re.findall(
        r"^(max_rss_kib|user_seconds|system_seconds)=([^\n]*)$",
        path.read_text() if path.is_file() else "",
        re.M,
    )
    values, errors = dict(pairs), []
    if Counter(name for name, _ in pairs) != Counter(fields):
        errors.append("missing or duplicate per-process resource observation")
    parsed = {}
    for name, key, convert in (
        ("max_rss_kib", "peak_rss_kib", int),
        ("user_seconds", "user_seconds", float),
        ("system_seconds", "system_seconds", float),
    ):
        try:
            value = convert(values[name])
            require(math.isfinite(value) and value >= 0, "invalid resource value")
        except (KeyError, ValueError, OverflowError):
            value = None
        parsed[key] = value
    if parsed["peak_rss_kib"] is None or parsed["peak_rss_kib"] <= 0:
        errors.append("nonpositive or missing per-process peak RSS")
    if any(parsed[name] is None for name in ("user_seconds", "system_seconds")):
        errors.append("invalid per-process CPU observation")
    return {**parsed, "measurement_errors": errors}


def expected_command(binary, item, directory, *, verify=False, export=False):
    case = item["case"]
    argv = study.command(
        binary, case, Path(item["assembly"]), directory / "outputs.vexpr", verify=verify
    )
    if not export and "--emit-exprs" in argv:
        index = argv.index("--emit-exprs")
        del argv[index : index + 2]
    return argv


def finish_observation(result, item, directory, *, verify=False, export=False):
    case = item["case"]
    stdout, stderr = (
        (directory / "stdout").read_text(),
        (directory / "stderr").read_text(),
    )
    classification, reason = corpus.classify(
        result["returncode"], stdout, stderr, timed_out=result["timed_out"]
    )
    result = {**result, "classification": classification, "reason": reason}
    result = observations(result, directory, verify=verify, case=case)
    if verify:
        result["proved"] = result["proof_accepted"] and result["proof_counts"] == [
            str(case["expected_outputs"])
        ]
    if export and result["graph_accepted"]:
        try:
            require(
                corpus.expression_indices((directory / "outputs.vexpr").read_text())
                == case["output_indices"],
                "full configured output coordinates differ",
            )
            coverage = corpus.harness.array_coverage_error(
                (directory / "stdout").read_text(),
                {
                    name: len(indices)
                    for name, indices in case["output_indices"].items()
                },
            )
            require(coverage is None, coverage)
            result["classification"] = "verified"
            result["reason"] = (
                "complete graph and configured output coordinates verified"
            )
        except (ValueError, OSError) as error:
            result.update(
                graph_accepted=False, classification="contract_error", reason=str(error)
            )
    elif result["graph_accepted"]:
        result["classification"] = "graph_accepted_without_export"
    if verify and result["proved"]:
        result["classification"] = "spec_verified"
    result.update(resource_observations(directory))
    diagnostics = "\n".join(
        line
        for line in stdout.splitlines()
        if not re.match(r"^  time: [\d.]+s\s+instructions:", line)
        and not line.startswith("Wrote output expressions to ")
    )
    result["diagnostics_sha256"] = hashlib.sha256(
        (diagnostics + "\nstderr:\n" + stderr).encode()
    ).hexdigest()
    result["stdout_sha256"], result["stderr_sha256"] = (
        sha(directory / "stdout"),
        sha(directory / "stderr"),
    )
    result["resources_sha256"] = (
        sha(directory / "resources.txt")
        if (directory / "resources.txt").is_file()
        else None
    )
    expressions = directory / "outputs.vexpr"
    result["output_expressions_sha256"] = (
        sha(expressions) if expressions.is_file() else None
    )
    return result


def execute(binary, item, directory, *, verify=False, export=False):
    directory.mkdir()
    argv = expected_command(binary, item, directory, verify=verify, export=export)
    result = study.execute(argv, item["case"], directory, TIMEOUT)
    return finish_observation(result, item, directory, verify=verify, export=export)


def observation_pins(row, directory):
    result = {}
    for name, field in (
        ("stdout", "stdout_sha256"),
        ("stderr", "stderr_sha256"),
        ("resources.txt", "resources_sha256"),
        ("outputs.vexpr", "output_expressions_sha256"),
    ):
        path = directory / name
        if row.get(field) is None:
            require(not path.exists(), "unbound qualification artifact: " + str(path))
        else:
            require(
                path.is_file() and sha(path) == row[field],
                "qualification artifact changed: " + str(path),
            )
            result[str(path)] = row[field]
    return result


def audit_observation(row, binary, item, directory, *, verify=False, export=False):
    require(
        row["command"]
        == expected_command(binary, item, directory, verify=verify, export=export),
        "qualification command differs from complete frozen contract",
    )
    require(
        row.get("early_readiness_enabled") is False
        and row.get("launch_contract")
        == study.launch_contract(row["command"], item["case"]),
        "qualification launch/observer options differ",
    )
    pins = observation_pins(row, directory)
    require(
        type(row.get("seconds")) in (int, float)
        and math.isfinite(row["seconds"])
        and row["seconds"] > 0,
        "qualification process duration is invalid",
    )
    fresh_row = finish_observation(row, item, directory, verify=verify, export=export)
    for name in (
        "graph_accepted",
        "proof_accepted",
        "proof_counts",
        "detected_expected_hazard",
        "false_positive",
        "false_acceptance",
        "time_to_detection_seconds",
        "classification",
        "reason",
        "diagnostics_sha256",
        "measurement_errors",
        "peak_rss_kib",
        "user_seconds",
        "system_seconds",
    ):
        require(
            fresh_row[name] == row[name],
            "qualification observation differs from transcript: " + name,
        )
    if verify:
        require(
            fresh_row["proved"] == row["proved"], "qualification proof count differs"
        )
    return pins


def audit_qualification(path, plan, plan_sha256, role):
    report_hash = sha(path)
    report = json.loads(path.read_text())
    require(
        report.get("status") == "COMPLETE"
        and report.get("role") == role
        and report.get("plan_sha256") == plan_sha256,
        "qualification role, completion, or plan differs",
    )
    declared = report["identity"]
    identity = build_identity(
        Path(declared["binary"]), Path(declared["build_record"]), declared["revision"]
    )
    require(
        identity == declared and identity["comparison_role"] == role,
        "qualification build identity differs",
    )
    require(
        [row["id"] for row in report["results"]]
        == [item["case"]["id"] for item in plan["cases"]],
        "qualification denominator differs",
    )
    artifacts = {}
    for item, row in zip(plan["cases"], report["results"]):
        case = item["case"]
        require(
            row["expectation"] == case["expectation"],
            "qualification expectation differs",
        )
        directory = path.parent / case["id"]
        safe = case["expectation"] == "safe"
        artifacts.update(
            audit_observation(
                row["analysis"],
                Path(identity["binary"]),
                item,
                directory / "analysis",
                export=safe,
            )
        )
        if safe:
            require(
                isinstance(row["proof"], dict),
                "safe qualification lacks its complete proof",
            )
            artifacts.update(
                audit_observation(
                    row["proof"],
                    Path(identity["binary"]),
                    item,
                    directory / "proof",
                    verify=True,
                )
            )
            qualified = row["analysis"]["graph_accepted"] and row["proof"]["proved"]
        else:
            require(
                row["proof"] is None, "hazard qualification has an unexpected proof"
            )
            qualified = row["analysis"]["detected_expected_hazard"]
        require(
            type(row["qualified"]) is bool and row["qualified"] == qualified,
            "qualification eligibility differs from retained evidence",
        )
    require(
        report["eligible"]
        == [row["id"] for row in report["results"] if row["qualified"]],
        "qualification eligibility list differs",
    )
    small = {str(path.resolve()): report_hash, **build_pins(identity)}
    unchanged({**small, **artifacts})
    return report, small, artifacts


def qualify(args):
    plan = plan_at(args.plan, args.plan_sha256)
    binary = args.binary.resolve(strict=True)
    identity = build_identity(binary, args.build_record, args.revision)
    require(identity["comparison_role"] == args.role, "build role differs")
    out = fresh(args.output)
    pins = {**plan_pins(args.plan, args.plan_sha256, plan), **build_pins(identity)}
    rows = []
    for item in plan["cases"]:
        unchanged(pins)
        case = item["case"]
        directory = out / case["id"]
        directory.mkdir()
        analysis = execute(
            binary,
            item,
            directory / "analysis",
            export=case["expectation"] == "safe",
        )
        proof = (
            execute(binary, item, directory / "proof", verify=True)
            if case["expectation"] == "safe"
            else None
        )
        eligible = (
            (analysis["graph_accepted"] and proof["proved"])
            if proof
            else analysis["detected_expected_hazard"]
        )
        rows.append(
            {
                "id": case["id"],
                "expectation": case["expectation"],
                "analysis": analysis,
                "proof": proof,
                "qualified": bool(eligible),
            }
        )
        write(
            out / "report.json",
            {"schema": 1, "status": "INCOMPLETE", "role": args.role, "results": rows},
        )
        print(
            case["id"]
            + ": "
            + ("qualified" if eligible else analysis["classification"]),
            flush=True,
        )
    unchanged(pins)
    result = {
        "schema": 1,
        "status": "COMPLETE",
        "role": args.role,
        "plan_sha256": args.plan_sha256,
        "identity": identity,
        "results": rows,
        "eligible": [row["id"] for row in rows if row["qualified"]],
    }
    write(out / "report.json", result)
    audit_qualification(out / "report.json", plan, args.plan_sha256, args.role)


def audit(args):
    plan = plan_at(args.plan, args.plan_sha256)
    report, _, _ = audit_qualification(
        args.qualification, plan, args.plan_sha256, args.role
    )
    print(
        json.dumps(
            {
                "status": "AUDITED",
                "role": args.role,
                "qualified": len(report["eligible"]),
                "cases": len(report["results"]),
                "report_sha256": sha(args.qualification),
            }
        )
    )


def percentile95(values):
    return sorted(values)[max(0, math.ceil(len(values) * 0.95) - 1)]


def valid_metric(row, key):
    value, wall = row.get(key), row.get("seconds")
    if not all(
        type(v) in (int, float) and math.isfinite(v) and v > 0 for v in (value, wall)
    ):
        return False
    if key == "time_to_detection_seconds" and value > wall:
        return False
    return row.get("measurement_errors") == [] and not row.get("timed_out", True)


def summaries(cases, samples, baseline, candidate):
    result = []
    for item in cases:
        case = item["case"]
        key = (
            "time_to_detection_seconds"
            if case["expectation"] == "hazard"
            else "seconds"
        )
        arms = {}
        for arm in ("baseline", "candidate"):
            records = [
                row for row in samples if row["id"] == case["id"] and row["arm"] == arm
            ]
            repeats = [row for row in records if row["round"] > 0]
            rounds = [row["round"] for row in records]
            complete_rounds = (
                len(rounds) == REPEATS + 1
                and set(rounds) == set(range(REPEATS + 1))
                and all(type(r) is int for r in rounds)
            )
            valid = [
                row[key]
                for row in repeats
                if valid_metric(row, key)
                and (
                    row["detected_expected_hazard"]
                    if case["expectation"] == "hazard"
                    else row["graph_accepted"]
                )
            ]
            arms[arm] = {
                "observations": len(records),
                "repeats": len(repeats),
                "successful_repeats": len(valid),
                "complete_rounds": complete_rounds,
                "median_seconds": statistics.median(valid)
                if complete_rounds and len(valid) == REPEATS
                else None,
                "p95_seconds": percentile95(valid)
                if complete_rounds and len(valid) == REPEATS
                else None,
                "first": next((row for row in records if row["round"] == 0), None),
            }
        left, right = baseline[case["id"]], candidate[case["id"]]
        ratio = None
        if (
            left["qualified"]
            and right["qualified"]
            and all(arms[arm]["median_seconds"] is not None for arm in arms)
        ):
            ratio = (
                arms["candidate"]["median_seconds"] / arms["baseline"]["median_seconds"]
            )
        result.append(
            {
                "id": case["id"],
                "target": case["target"],
                "family": case["family"],
                "expectation": case["expectation"],
                "baseline_qualified": left["qualified"],
                "candidate_qualified": right["qualified"],
                "baseline": arms["baseline"],
                "candidate": arms["candidate"],
                "candidate_over_baseline_median": ratio,
                "baseline_classification": left["analysis"]["classification"],
                "candidate_classification": right["analysis"]["classification"],
                "baseline_detected": left["analysis"]["detected_expected_hazard"],
                "candidate_detected": right["analysis"]["detected_expected_hazard"],
            }
        )
        if case["expectation"] == "safe":
            result[-1]["output_expressions_equal"] = (
                left["analysis"]["output_expressions_sha256"] is not None
                and left["analysis"]["output_expressions_sha256"]
                == right["analysis"]["output_expressions_sha256"]
            )
    return result


def schedule_for(eligible):
    randomizer, schedule = random.Random(SEED), []
    for round_index in range(REPEATS + 1):
        order = list(eligible)
        randomizer.shuffle(order)
        for item in order:
            arms = ["baseline", "candidate"]
            randomizer.shuffle(arms)
            schedule.append(
                {"round": round_index, "id": item["case"]["id"], "arms": arms}
            )
    return schedule


def audited_reports(paths, expected_hashes, plan, plan_hash):
    reports, pins, artifacts = {}, {}, {}
    for arm in ("baseline", "candidate"):
        require(sha(paths[arm]) == expected_hashes[arm], "qualification report changed")
        report, small, large = audit_qualification(paths[arm], plan, plan_hash, arm)
        reports[arm] = report
        pins.update(small)
        artifacts.update(large)
    matching_builds(reports["baseline"]["identity"], reports["candidate"]["identity"])
    return reports, pins, artifacts


def audit_collection(path, plan_path, plan_hash):
    """Recompute every published result from its frozen retained observations."""
    plan = plan_at(plan_path, plan_hash)
    report_hash = sha(path)
    report = json.loads(path.read_text())
    require(
        report.get("status") == "COMPLETE"
        and report.get("plan_sha256") == plan_hash
        and report.get("repeats") == REPEATS
        and report.get("seed") == SEED,
        "collection completion or protocol differs",
    )
    reports, small, artifacts = audited_reports(
        {arm: Path(value) for arm, value in report["qualification_paths"].items()},
        report["qualification_sha256"],
        plan,
        plan_hash,
    )
    rows = {
        arm: {row["id"]: row for row in qualification["results"]}
        for arm, qualification in reports.items()
    }
    require(
        report["identities"]
        == {arm: value["identity"] for arm, value in reports.items()},
        "collection build identities differ",
    )
    eligible = [
        item
        for item in plan["cases"]
        if rows["baseline"][item["case"]["id"]]["qualified"]
    ]
    require(
        report["eligible"] == [item["case"]["id"] for item in eligible],
        "timing denominator differs",
    )
    sample_path, schedule_path = (
        path.parent / "samples.json",
        path.parent / "schedule.json",
    )
    pins = {
        **plan_pins(plan_path, plan_hash, plan),
        **small,
        str(path): report_hash,
        str(sample_path): report["samples_sha256"],
        str(schedule_path): report["schedule_sha256"],
    }
    unchanged(pins)
    samples, schedule = (
        json.loads(sample_path.read_text()),
        json.loads(schedule_path.read_text()),
    )
    require(schedule == schedule_for(eligible), "paired timing schedule differs")
    expected = [
        (pair["round"], pair["id"], arm) for pair in schedule for arm in pair["arms"]
    ]
    require(
        [(row["round"], row["id"], row["arm"]) for row in samples] == expected
        and all(type(row["round"]) is int for row in samples),
        "timing observations are missing, duplicated, or out of order",
    )
    cases = {item["case"]["id"]: item for item in plan["cases"]}
    for row in samples:
        directory = path.parent / (
            str(row["round"]) + "-" + row["id"] + "-" + row["arm"]
        )
        artifacts.update(
            audit_observation(
                row,
                Path(reports[row["arm"]]["identity"]["binary"]),
                cases[row["id"]],
                directory,
            )
        )
    require(
        report["results"]
        == summaries(plan["cases"], samples, rows["baseline"], rows["candidate"]),
        "published metrics differ from retained samples",
    )
    unchanged({**pins, **artifacts})
    return report


def audit_timing(args):
    report = audit_collection(args.report, args.plan, args.plan_sha256)
    print(
        json.dumps(
            {
                "status": "AUDITED",
                "timed_cases": len(report["eligible"]),
                "report_sha256": sha(args.report),
            }
        )
    )


def collect(args):
    plan = plan_at(args.plan, args.plan_sha256)
    reports, frozen, artifacts = {}, plan_pins(args.plan, args.plan_sha256, plan), {}
    for arm in ("baseline", "candidate"):
        report, small, large = audit_qualification(
            getattr(args, arm + "_qualification"), plan, args.plan_sha256, arm
        )
        reports[arm] = report
        frozen.update(small)
        artifacts.update(large)
    matching_builds(reports["baseline"]["identity"], reports["candidate"]["identity"])
    rows = {
        arm: {row["id"]: row for row in report["results"]}
        for arm, report in reports.items()
    }
    # Candidate outcomes never decide timing eligibility or remove a baseline case.
    eligible = [
        item
        for item in plan["cases"]
        if rows["baseline"][item["case"]["id"]]["qualified"]
    ]
    out = fresh(args.output)
    schedule = schedule_for(eligible)
    write(out / "schedule.json", schedule)
    samples = []
    cases = {item["case"]["id"]: item for item in plan["cases"]}
    context = {
        "system": platform.platform(),
        "cpu_count": os.cpu_count(),
        "load_before": os.getloadavg(),
        "cpu_model": next(
            (
                line.split(":", 1)[1].strip()
                for line in Path("/proc/cpuinfo").read_text().splitlines()
                if line.startswith("model name")
            ),
            "unknown",
        ),
        "round_loads": [],
    }
    current_round = None
    for pair in schedule:
        if pair["round"] != current_round:
            current_round = pair["round"]
            context["round_loads"].append(
                {"round": current_round, "load": os.getloadavg()}
            )
            print("round " + str(current_round), flush=True)
        for arm in pair["arms"]:
            unchanged(frozen)
            binary = Path(reports[arm]["identity"]["binary"])
            directory = out / (str(pair["round"]) + "-" + pair["id"] + "-" + arm)
            observation = execute(binary, cases[pair["id"]], directory)
            samples.append(
                {"round": pair["round"], "id": pair["id"], "arm": arm, **observation}
            )
        write(out / "samples.json", samples)
    unchanged(frozen)
    # Large untimed qualification exports are checked at both ends rather than
    # repeatedly reading them between adjacent timed processes.
    unchanged(artifacts)
    summary = summaries(plan["cases"], samples, rows["baseline"], rows["candidate"])
    write(
        out / "report.json",
        {
            "schema": 1,
            "status": "COMPLETE",
            "plan_sha256": args.plan_sha256,
            "context": context,
            "repeats": REPEATS,
            "seed": SEED,
            "eligible": [i["case"]["id"] for i in eligible],
            "qualification_sha256": {
                arm: sha(getattr(args, arm + "_qualification")) for arm in reports
            },
            "qualification_paths": {
                arm: str(getattr(args, arm + "_qualification").resolve())
                for arm in reports
            },
            "identities": {arm: report["identity"] for arm, report in reports.items()},
            "samples_sha256": sha(out / "samples.json"),
            "schedule_sha256": sha(out / "schedule.json"),
            "results": summary,
        },
    )
    audit_collection(out / "report.json", args.plan, args.plan_sha256)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    prep = sub.add_parser("prepare")
    prep.add_argument("--output", type=Path, required=True)
    prep.set_defaults(function=prepare)
    auditing = sub.add_parser("audit")
    auditing.add_argument("--plan", type=Path, required=True)
    auditing.add_argument("--plan-sha256", required=True)
    auditing.add_argument("--qualification", type=Path, required=True)
    auditing.add_argument("--role", choices=("baseline", "candidate"), required=True)
    auditing.set_defaults(function=audit)
    timing_audit = sub.add_parser("audit-collection")
    timing_audit.add_argument("--plan", type=Path, required=True)
    timing_audit.add_argument("--plan-sha256", required=True)
    timing_audit.add_argument("--report", type=Path, required=True)
    timing_audit.set_defaults(function=audit_timing)
    for name, function in (("qualify", qualify), ("collect", collect)):
        command = sub.add_parser(name)
        command.add_argument("--plan", type=Path, required=True)
        command.add_argument("--plan-sha256", required=True)
        command.add_argument("--output", type=Path, required=True)
        if name == "qualify":
            command.add_argument("--binary", type=Path, required=True)
            command.add_argument("--build-record", type=Path, required=True)
            command.add_argument("--revision", required=True)
            command.add_argument(
                "--role", choices=("baseline", "candidate"), required=True
            )
        else:
            for arm in ("baseline", "candidate"):
                command.add_argument(
                    "--" + arm + "-qualification", type=Path, required=True
                )
        command.set_defaults(function=function)
    args = parser.parse_args()
    args.function(args)


if __name__ == "__main__":
    main()
