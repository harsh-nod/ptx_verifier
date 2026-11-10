#!/usr/bin/env python3
"""Compare native register-storage revisions on independently frozen configurations."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import random
import re
import statistics
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MANIFEST = HERE / "cases.json"
PROTOCOL = HERE / "protocol.json"


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


legacy = module("native_trace_cost_observations", HERE.parent / "backend-comparison/compare.py")
require, sha, write = legacy.require, legacy.sha, legacy.write


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def checked_path(relative):
    path = Path(relative)
    require(not path.is_absolute() and ".." not in path.parts, "unsafe input path")
    resolved = (ROOT / path).resolve()
    require(resolved.is_relative_to(ROOT), "input escapes repository")
    require(resolved.is_file(), "input is not a file: " + relative)
    return resolved


def fresh(path):
    path = path.resolve()
    require(not path.exists() and not path.is_relative_to(ROOT), "output must be fresh and external")
    path.mkdir(parents=True)
    return path


def contracts():
    document, protocol = json.loads(MANIFEST.read_text()), json.loads(PROTOCOL.read_text())
    cases = document["cases"]
    require(document["schema"] == protocol["schema"] == 1, "unknown schema")
    require(document["baseline_revision"] == protocol["baseline_revision"], "baseline mismatch")
    require(protocol["repeats"] == 31 and protocol["timeout_seconds"] == 60, "protocol changed")
    require(len(cases) == 26 and Counter(c["expectation"] for c in cases) == {"safe": 13, "hazard": 13},
            "predeclared denominator changed")
    require(len({c["id"] for c in cases}) == len(cases), "duplicate case ID")
    known = {c["id"]: c for c in cases}
    for case in cases:
        require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", case["id"]), "unsafe case ID")
        require(case["target"] in {"gfx942", "gfx950", "gfx1250"}, "unknown target")
        for field in ("source", "assembly", "spec", "launch_config", "parent_manifest"):
            if case.get(field):
                require(sha(checked_path(case[field])) == case[field + "_sha256"], "input changed: " + case[field])
        require(legacy.corpus.harness.native_target_of(checked_path(case["assembly"]).read_text()) == case["target"],
                "assembly target differs")
        expected = {a["name"]: list(range(a["length"])) for a in case["arrays"] if a["kind"] in {"out", "inout"}}
        require(case["output_indices"] == expected, "incomplete output coordinates")
        require(case["expected_outputs"] == sum(map(len, expected.values())), "wrong output count")
        require(case.get("expectation_source") and case.get("contract"), "unbound expectation")
        if case["expectation"] == "hazard":
            safe = known[case["safe_counterpart"]]
            require(safe["expectation"] == "safe", "missing safe counterpart")
            for key in ("kernel", "target", "source", "assembly", "spec", "block", "grid", "workgroup",
                        "dimensions", "arrays", "params", "output_indices", "expected_outputs", "launch_config"):
                require(case.get(key) == safe.get(key), "mutation changed complete contract: " + key)
            lines = checked_path(case["assembly"]).read_text().splitlines()
            anchors = case["readiness_ground_truth"]
            positions = [anchors[k]["source_line"] for k in ("producer", "removed_completion", "unsafe_use")]
            require(positions == sorted(set(positions)), "producer/wait/use order differs")
            for key in ("producer", "removed_completion", "unsafe_use"):
                anchor = anchors[key]
                require(lines[anchor["source_line"] - 1].strip() == anchor["instruction"], "ground truth changed")
            require(case["edits"] == [{"source_line": positions[1], "original": anchors["removed_completion"]["instruction"],
                                       "replacement": "s_nop 0"}], "unexpected mutation")
    return document, protocol


def input_pins(document):
    paths = {Path(__file__), MANIFEST, PROTOCOL, Path(legacy.__file__), Path(legacy.study.__file__),
             Path(legacy.corpus.__file__), ROOT / "ai_compiler_kernels/check_races.py"}
    for case in document["cases"]:
        paths.update(checked_path(case[k]) for k in ("source", "assembly", "spec", "launch_config", "parent_manifest") if case.get(k))
    return {str(p): sha(p) for p in sorted(paths)}


def prepare(output):
    document, protocol = contracts()
    output = fresh(output)
    rows = []
    for case in document["cases"]:
        directory = output / case["id"]
        directory.mkdir()
        assembly = legacy.study.materialize(case, directory)
        rows.append({"case": case, "assembly": str(assembly), "assembly_sha256": sha(assembly)})
    plan = {"schema": 1, "protocol": protocol, "cases": rows, "input_sha256": input_pins(document)}
    write(output / "plan.json", plan)
    return {"plan": str(output / "plan.json"), "sha256": sha(output / "plan.json"), "cases": len(rows)}


def plan_at(path, expected):
    require(sha(path) == expected, "plan hash differs")
    plan = json.loads(path.read_text())
    document, protocol = contracts()
    require(plan["protocol"] == protocol and [r["case"] for r in plan["cases"]] == document["cases"], "plan population changed")
    legacy.unchanged(plan["input_sha256"])
    for row in plan["cases"]:
        require(sha(row["assembly"]) == row["assembly_sha256"], "materialized source changed")
    return plan


def identity(binary, declaration, role, protocol):
    require(role in {"baseline", "candidate"}, "unknown build role")
    record = json.loads(declaration.read_text())
    require(record["trust"] == "caller_attested" and record["source_clean"] is True, "clean build declaration required")
    require(record["profile"] == "release" and record["default_features"] is True and record["features"] == [], "build flags differ")
    require(record["binary_sha256"] == sha(binary), "binary hash differs")
    require(record["source_tree"] == git("rev-parse", record["revision"] + "^{tree}"), "source tree differs")
    if role == "baseline":
        require(record["revision"] == protocol["baseline_revision"], "baseline revision differs")
    else:
        require(subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", protocol["baseline_revision"], record["revision"]], capture_output=True).returncode == 0,
                "candidate does not descend from baseline")
    return {**record, "binary": str(binary.resolve()), "declaration": str(declaration.resolve()),
            "declaration_sha256": sha(declaration), "role": role}


def command(binary, item, directory, *, verify=False, export=False, graph=False):
    args = legacy.expected_command(binary, item, directory, verify=verify, export=export)
    if graph:
        args += ["--dump-graph", str(directory / "graph.txt")]
    return args


def derive(row, item, directory, *, verify=False, export=False, graph=False):
    """Derive every semantic/resource decision again from retained process artifacts."""
    row = legacy.finish_observation(row, item, directory, verify=verify, export=export)
    if graph:
        path = directory / "graph.txt"
        row["graph_sha256"] = sha(path) if path.is_file() else None
        row["graph_completed"] = path.is_file() and path.read_text().endswith("terminal completed\n")
    # Artifact destinations vary by arm; all findings and other diagnostics remain exact.
    stdout, stderr = (directory / "stdout").read_text(), (directory / "stderr").read_text()
    def normalized(text):
        return "\n".join(line for line in text.splitlines()
                         if not re.match(r"^  time: [\d.]+s\s+instructions:", line)
                         and not line.startswith(("Wrote output expressions to ", "Wrote event graph to ")))
    row["diagnostics_sha256"] = hashlib.sha256((normalized(stdout) + "\nstderr:\n" + normalized(stderr)).encode()).hexdigest()
    return row


def observe(binary, item, directory, *, verify=False, export=False, graph=False):
    directory.mkdir()
    args = command(binary, item, directory, verify=verify, export=export, graph=graph)
    row = legacy.study.execute(args, item["case"], directory, 60)
    write(directory / "observer.json", row)
    row = derive(row, item, directory, verify=verify, export=export, graph=graph)
    row["observer_sha256"] = sha(directory / "observer.json")
    return row


def audit_observation(row, binary, item, directory, *, verify=False, export=False, graph=False):
    require(row["command"] == command(binary, item, directory, verify=verify, export=export, graph=graph),
            "observation command differs")
    require(row.get("early_readiness_enabled") is False and row.get("launch_contract") == legacy.study.launch_contract(row["command"], item["case"]),
            "observation launch/observer options differ")
    require(type(row.get("seconds")) in (int, float) and math.isfinite(row["seconds"]) and row["seconds"] > 0,
            "invalid observation duration")
    legacy.observation_pins(row, directory)
    observer = directory / "observer.json"
    require(sha(observer) == row["observer_sha256"], "parent observer receipt changed")
    raw = json.loads(observer.read_text())
    require(raw["command"] == row["command"], "parent observer command differs")
    derived = derive(raw, item, directory, verify=verify, export=export, graph=graph)
    for field in derived:
        require(row.get(field) == derived.get(field), "observation differs from artifacts: " + field)


def qualifies(case, analysis, proof=None):
    if analysis.get("measurement_errors") or not analysis.get("graph_completed"):
        return False
    if case["expectation"] == "safe":
        return analysis["graph_accepted"] and analysis.get("classification") == "verified" and proof is not None and proof.get("proved", False) and not proof.get("measurement_errors")
    return analysis["detected_expected_hazard"] and bool(re.search(r"AmdRegisterHazard .*kind: ReadBeforeReady", analysis.get("witnesses", "")))


def qualify(args):
    plan = plan_at(args.plan, args.plan_sha256)
    build = identity(args.binary, args.build, args.role, plan["protocol"])
    output = fresh(args.output)
    report = {"schema": 1, "complete": False, "plan": str(args.plan.resolve()), "plan_sha256": args.plan_sha256,
              "build": build, "role": args.role, "context": legacy.study.runtime_context(), "results": {}}
    write(output / "report.json", report)
    for item in plan["cases"]:
        plan_at(args.plan, args.plan_sha256)
        require(sha(args.build) == build["declaration_sha256"], "build declaration changed")
        require(sha(args.binary) == build["binary_sha256"], "binary changed")
        case = item["case"]
        directory = output / case["id"]
        directory.mkdir()
        analysis = observe(args.binary, item, directory / "analysis", export=case["expectation"] == "safe", graph=True)
        analysis["witnesses"] = (directory / "analysis/stdout").read_text()
        proof = observe(args.binary, item, directory / "proof", verify=True) if case["expectation"] == "safe" else None
        report["results"][case["id"]] = {"qualified": qualifies(case, analysis, proof), "analysis": analysis, "proof": proof}
        write(output / "report.json", report)
        print(case["id"], report["results"][case["id"]]["qualified"], flush=True)
    report["complete"] = True
    plan_at(args.plan, args.plan_sha256)
    write(output / "report.json", report)
    return {"report": str(output / "report.json"), "qualified": sum(r["qualified"] for r in report["results"].values()), "cases": len(plan["cases"])}


def qualification(path, plan, plan_hash):
    report = json.loads(path.read_text())
    require(report["complete"] and report["plan_sha256"] == plan_hash, "qualification incomplete or unbound")
    build = report["build"]
    require(identity(Path(build["binary"]), Path(build["declaration"]), report["role"], plan["protocol"]) == build,
            "qualification identity changed")
    require(set(report["results"]) == {i["case"]["id"] for i in plan["cases"]}, "qualification denominator differs")
    for item in plan["cases"]:
        case = item["case"]
        result = report["results"][case["id"]]
        directory = path.parent / case["id"]
        for stage, verify, export in [("analysis", False, case["expectation"] == "safe"), ("proof", True, False)]:
            row = result[stage]
            if stage == "proof" and case["expectation"] != "safe":
                require(row is None, "hazard cannot qualify by a mathematical proof")
                continue
            location = directory / stage
            audit_observation(row, build["binary"], item, location, verify=verify, export=export, graph=not verify)
            if not verify:
                require(row["witnesses"] == (location / "stdout").read_text(), "witnesses differ")
        require(result["qualified"] == qualifies(case, result["analysis"], result["proof"]), "qualification decision differs")
    return report


def schedule(items, protocol):
    randomizer, result = random.Random(protocol["seed"]), []
    for repeat in range(protocol["repeats"] + 1):
        order = list(items)
        randomizer.shuffle(order)
        for item in order:
            arms = ["baseline", "candidate"]
            randomizer.shuffle(arms)
            result.append({"round": repeat, "id": item["case"]["id"], "arms": arms})
    return result


def sample_directory(report_path, index, arm):
    require(arm in {"baseline", "candidate"}, "invalid sample arm")
    return report_path.resolve().parent / (f"{index // 2:04d}-" + arm)


def paired_interval(pairs, seed):
    randomizer = random.Random(seed)
    values = []
    for _ in range(2000):
        draws = [randomizer.choice(pairs) for _ in pairs]
        values.append(statistics.median(x[1] for x in draws) / statistics.median(x[0] for x in draws))
    values.sort()
    return [values[49], values[1949]]


def summaries(plan, samples, baseline, candidate):
    result = legacy.summaries(plan["cases"], samples, baseline["results"], candidate["results"])
    for row in result:
        key = "seconds" if row["expectation"] == "safe" else "time_to_detection_seconds"
        indexed = {(s["round"], s["arm"]): s for s in samples if s["id"] == row["id"]}
        if row["candidate_over_baseline_median"] is not None:
            pairs = [(indexed[r, "baseline"][key], indexed[r, "candidate"][key]) for r in range(1, 32)]
            row["paired_ratio_interval_95"] = paired_interval(pairs, int(hashlib.sha256(row["id"].encode()).hexdigest()[:8], 16))
        else:
            row["paired_ratio_interval_95"] = None
        for arm in ("baseline", "candidate"):
            values = [s for s in samples if s["id"] == row["id"] and s["arm"] == arm and s["round"] > 0]
            row[arm]["peak_rss_kib"] = max((s["peak_rss_kib"] for s in values if s.get("peak_rss_kib") is not None), default=None)
            row[arm]["misses_or_invalid"] = sum(not legacy.valid_metric(s, key) or not (s["graph_accepted"] if row["expectation"] == "safe" else s["detected_expected_hazard"]) for s in values)
        row["graph_dumps_equal"] = baseline["results"][row["id"]]["analysis"]["graph_sha256"] is not None and baseline["results"][row["id"]]["analysis"]["graph_sha256"] == candidate["results"][row["id"]]["analysis"]["graph_sha256"]
        left, right = baseline["results"][row["id"]], candidate["results"][row["id"]]
        row["diagnostics_equal"] = left["analysis"]["diagnostics_sha256"] == right["analysis"]["diagnostics_sha256"]
        row["proof_diagnostics_equal"] = row["expectation"] != "safe" or left["proof"]["diagnostics_sha256"] == right["proof"]["diagnostics_sha256"]
        row["timed_diagnostics_equal"] = all(s["diagnostics_sha256"] == next(t["diagnostics_sha256"] for t in samples if t["id"] == s["id"] and t["round"] == s["round"] and t["arm"] != s["arm"]) for s in samples if s["id"] == row["id"])
    return result


def adoption(rows):
    """Evaluate the predeclared gates without deleting failures or regressions."""
    failures, improved = [], []
    for row in rows:
        case = row["id"]
        if not row["baseline_qualified"] or not row["candidate_qualified"]:
            failures.append(case + ": incomplete qualification")
            continue
        for key in ("graph_dumps_equal", "diagnostics_equal", "proof_diagnostics_equal", "timed_diagnostics_equal"):
            if not row[key]:
                failures.append(case + ": " + key)
        if row["expectation"] == "safe" and not row["output_expressions_equal"]:
            failures.append(case + ": output expressions differ")
        left, right = row["baseline"], row["candidate"]
        if any(arm["misses_or_invalid"] or not arm["complete_rounds"] for arm in (left, right)):
            failures.append(case + ": timed miss/invalid observation")
        if row["expectation"] == "safe":
            for key, factor in (("median_seconds", 1.05), ("p95_seconds", 1.10)):
                if left[key] is None or right[key] is None or right[key] > left[key] * factor + 0.001:
                    failures.append(case + ": safe " + key + " regression")
        interval = row["paired_ratio_interval_95"]
        if row["expectation"] == "hazard" and interval is not None and interval[1] < 1:
            improved.append(case)
        a, b = left["peak_rss_kib"], right["peak_rss_kib"]
        if a is None or b is None or b - a > max(a * 0.05, 8192):
            failures.append(case + ": peak RSS regression or missing measurement")
    if not improved:
        failures.append("no predeclared hazard has a paired 95% interval wholly below 1")
    return {"accepted": not failures, "failures": failures, "hazards_with_latency_improvement": improved}


def collect(args):
    plan = plan_at(args.plan, args.plan_sha256)
    baseline = qualification(args.baseline, plan, args.plan_sha256)
    candidate = qualification(args.candidate, plan, args.plan_sha256)
    require(baseline["role"] == "baseline" and candidate["role"] == "candidate", "qualification roles differ")
    legacy.matching_builds(baseline["build"], candidate["build"])
    eligible = [i for i in plan["cases"] if baseline["results"][i["case"]["id"]]["qualified"]]
    output = fresh(args.output)
    report = {"schema": 1, "complete": False, "plan": str(args.plan.resolve()), "plan_sha256": args.plan_sha256,
              "baseline": str(args.baseline.resolve()), "baseline_sha256": sha(args.baseline),
              "candidate": str(args.candidate.resolve()), "candidate_sha256": sha(args.candidate),
              "context": legacy.study.runtime_context(), "schedule": schedule(eligible, plan["protocol"]),
              "load_observations": [], "samples": []}
    write(output / "report.json", report)
    indexed = {i["case"]["id"]: i for i in eligible}
    for position, pair in enumerate(report["schedule"]):
        plan_at(args.plan, args.plan_sha256)
        for qualified in (baseline, candidate):
            require(sha(qualified["build"]["declaration"]) == qualified["build"]["declaration_sha256"], "build declaration changed during collection")
        report["load_observations"].append({"position": position, "load_average_1_5_15": os.getloadavg()})
        for arm in pair["arms"]:
            build = (baseline if arm == "baseline" else candidate)["build"]
            require(sha(build["binary"]) == build["binary_sha256"], "binary changed during collection")
            directory = output / (f"{position:04d}-" + arm)
            row = observe(build["binary"], indexed[pair["id"]], directory)
            row.update(id=pair["id"], arm=arm, round=pair["round"], directory=str(directory))
            report["samples"].append(row)
        write(output / "report.json", report)
        print(position, pair["round"], pair["id"], flush=True)
    report["summaries"] = summaries(plan, report["samples"], baseline, candidate)
    report["adoption"] = adoption(report["summaries"])
    report["complete"] = True
    plan_at(args.plan, args.plan_sha256)
    write(output / "report.json", report)
    return {"report": str(output / "report.json"), "samples": len(report["samples"]), "cases": len(plan["cases"])}


def audit(args):
    plan = plan_at(args.plan, args.plan_sha256)
    report = json.loads(args.report.read_text())
    require(report["complete"] and report["plan_sha256"] == args.plan_sha256, "collection incomplete or unbound")
    require(sha(report["baseline"]) == report["baseline_sha256"] and sha(report["candidate"]) == report["candidate_sha256"], "qualification report changed")
    baseline = qualification(Path(report["baseline"]), plan, args.plan_sha256)
    candidate = qualification(Path(report["candidate"]), plan, args.plan_sha256)
    require(baseline["role"] == "baseline" and candidate["role"] == "candidate", "qualification roles differ")
    legacy.matching_builds(baseline["build"], candidate["build"])
    eligible = [i for i in plan["cases"] if baseline["results"][i["case"]["id"]]["qualified"]]
    expected = schedule(eligible, plan["protocol"])
    require(report["schedule"] == expected, "randomized pair schedule differs")
    flat = [(p["round"], p["id"], arm) for p in expected for arm in p["arms"]]
    require([(r["round"], r["id"], r["arm"]) for r in report["samples"]] == flat, "sample order/cardinality differs")
    indexed = {i["case"]["id"]: i for i in eligible}
    for index, row in enumerate(report["samples"]):
        item, directory = indexed[row["id"]], sample_directory(args.report, index, row["arm"])
        require(row["directory"] == str(directory), "sample artifact directory differs")
        build = (baseline if row["arm"] == "baseline" else candidate)["build"]
        audit_observation(row, build["binary"], item, directory)
    require(report["summaries"] == summaries(plan, report["samples"], baseline, candidate), "recomputed statistics differ")
    require(report["adoption"] == adoption(report["summaries"]), "recomputed acceptance gates differ")
    return {"status": "AUDITED", "cases": len(plan["cases"]), "samples": len(report["samples"]), "report_sha256": sha(args.report)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    prepare_parser = sub.add_parser("prepare")
    prepare_parser.add_argument("--output", required=True, type=Path)
    for name in ("qualify", "collect", "audit"):
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
        if name != "audit":
            child.add_argument("--output", required=True, type=Path)
        else:
            child.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(prepare(args.output) if args.mode == "prepare" else globals()[args.mode](args)), flush=True)


if __name__ == "__main__":
    main()
