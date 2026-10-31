#!/usr/bin/env python3
"""Measure paired safety diagnostics with explicit source and outcome contracts."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import random
import re
import selectors
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MANIFEST = HERE / "cases.json"
EARLY_MARKER = "EARLY_READINESS: CERTIFIED_REJECTION"
READINESS_PROPERTY = "AMD wait and register readiness"
HELDOUT_IDS = frozenset({
    "gfx1250-exchange_wrong_ds_counter", "gfx1250-tensor_wrong_load_counter",
    "gfx1250-tensor_missing_store_completion", "gfx1250-tensor_lds_footprint_out_of_bounds",
    "gfx1250-native-exchange-heldout-relocated", "gfx1250-native-tensor_roundtrip-heldout-relocated",
})
PRIMARY_LATENCY_CASES = frozenset({
    "gfx1250-copy_missing_km_wait", "gfx1250-original-relu_f16-missing-km-wait",
    "gfx1250-original-rmsnorm_f16-missing-km-wait",
})
sys.path.insert(0, str(HERE.parent / "compiler-corpus"))
import corpus  # noqa: E402


def percentile95(values):
    return sorted(values)[max(0, math.ceil(0.95 * len(values)) - 1)]


def median(values):
    ordered = sorted(values)
    middle = len(ordered) // 2
    return ordered[middle] if len(ordered) % 2 else (ordered[middle - 1] + ordered[middle]) / 2


def validate_cases(document, root=ROOT):
    corpus.require(document["schema_version"] == 1, "unsupported measurement schema")
    cases = document["cases"]
    originals = {case["baseline_id"]: case for case in json.loads((root / "tests/gfx1250/full/cases.json").read_text())["cases"]}
    corpus.require(cases and len(cases) == len({case["id"] for case in cases}), "empty or duplicate case IDs")
    corpus.require({case["id"] for case in cases if case["split"] == "heldout"} == HELDOUT_IDS,
                   "predeclared heldout configurations changed")
    for case in cases:
        corpus.require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", case["id"]), "unsafe case ID")
        corpus.require(case.get("backend", "amdgpu") in {"amdgpu", "ptx"}, "unknown backend")
        corpus.require(case["split"] in {"development", "heldout"}, "unknown measurement split")
        role = "observer_target" if case.get("backend", "amdgpu") == "amdgpu" and case["target"] == "gfx1250" else "unchanged_backend_control"
        corpus.require(case["measurement_role"] == role, "observer scope differs from target")
        corpus.require(case["primary_latency_case"] == (case["id"] in PRIMARY_LATENCY_CASES), "primary latency selection changed")
        for field in ("source", "assembly", "spec"):
            if case.get(field):
                path = Path(case[field])
                corpus.require(not path.is_absolute() and ".." not in path.parts, "unsafe case input")
                corpus.require(corpus.sha(root / path) == case[field + "_sha256"], "stale case input: " + case["id"])
        if case.get("backend", "amdgpu") == "amdgpu":
            corpus.require(corpus.harness.native_target_of((root / case["assembly"]).read_text()) == case["target"],
                           "native target relabelled")
        else:
            corpus.require(re.search(r"(?m)^\s*\.target\s+" + re.escape(case["target"]) + r"(?:\s|,|$)",
                                     (root / case["assembly"]).read_text()), "PTX source target differs")
        if case.get("baseline_id"):
            original = originals[case["baseline_id"]]
            for field in ("source", "assembly", "spec", "source_sha256", "assembly_sha256", "spec_sha256",
                          "block", "grid", "workgroup", "arrays", "params", "dimensions", "original_shape",
                          "output_projection", "expected_outputs", "reduced_case", "launch_config", "launch_config_sha256"):
                if field in {"source", "assembly", "spec", "launch_config"}:
                    same = (root / case[field]).resolve() == (root / "tests/gfx1250/full" / original[field]).resolve()
                else:
                    same = case[field] == original[field]
                corpus.require(same, "original workload contract changed: " + field)
        arrays = {array["name"]: array for array in case["arrays"]}
        corpus.require(len(arrays) == len(case["arrays"]), "duplicate arrays")
        outputs = {name: list(range(array["length"])) for name, array in arrays.items()
                   if array["kind"] in {"out", "inout"}}
        corpus.require(case["output_indices"] == outputs, "incomplete configured output contract")
        corpus.require(case["expected_outputs"] == sum(map(len, outputs.values())), "wrong expected output count")
        corpus.require(case["expectation"] in {"safe", "hazard"}, "unknown semantic expectation")
        corpus.require(case.get("expectation_source"), "missing independent expectation source")
        if case["expectation"] == "safe":
            corpus.require(case.get("spec") and case.get("spec_sha256"), "safe control needs its complete specification")
        if case["expectation"] == "hazard":
            corpus.require(case.get("required_property") and case.get("semantic_reason"), "unjustified hazard expectation")
        if case.get("edits"):
            corpus.require(case.get("mutated_source_sha256"), "unbound harmful mutation")
        if case.get("launch_config"):
            corpus.require(corpus.sha(root / case["launch_config"]) == case["launch_config_sha256"], "stale launch")
        for field in ("expectation_source", "assembly_mutation_manifest"):
            if ((field == "assembly_mutation_manifest" and case.get(field))
                    or (field == "expectation_source" and case[field].endswith(".rs"))):
                corpus.require(case.get(field + "_sha256"), "missing independent expectation pin")
            if case.get(field + "_sha256"):
                corpus.require(corpus.sha(root / case[field]) == case[field + "_sha256"], "stale independent expectation source")
        if case["expectation_source"].endswith(".rs"):
            corpus.require(case.get("expectation_function") and case.get("expectation_anchor"), "missing exact ground-truth assertion")
        if case.get("expectation_function"):
            corpus.require(case.get("expectation_source_sha256"), "unbound ground-truth function")
            text = (root / case["expectation_source"]).read_text()
            matches = list(re.finditer(r"\bfn\s+" + re.escape(case["expectation_function"]) + r"\s*\(", text))
            corpus.require(len(matches) == 1, "missing or duplicate ground-truth test function")
            match = matches[0]
            following = re.search(r"(?m)^\s*fn\s+\w+\s*\(", text[match.end():])
            region = text[match.start():match.end() + following.start()] if following else text[match.start():]
            corpus.require(case["expectation_anchor"] in region, "missing ground-truth assertion anchor")
        if case.get("diagnostic_family") == "invalid_access":
            corpus.require(case.get("required_diagnostic"), "missing exact invalid-access diagnostic")
    known = {case["id"]: case for case in cases}
    for case in cases:
        if not case.get("exploratory_family_coverage"):
            continue
        counterpart = known[case["safe_counterpart"]]
        corpus.require(case["split"] == "development" and not case["primary_latency_case"]
                       and counterpart["expectation"] == "safe", "family coverage changed measurement role")
        for field in ("kernel", "target", "source", "assembly", "spec", "source_sha256", "assembly_sha256", "spec_sha256",
                      "block", "grid", "workgroup", "dimensions", "arrays", "params", "expected_outputs", "output_indices"):
            corpus.require(case[field] == counterpart[field], "family mutation changed original contract: " + field)
        lines = (root / case["assembly"]).read_text().splitlines()
        anchors = case["readiness_ground_truth"]
        positions = [anchors[key]["source_line"] for key in ("producer", "removed_completion", "unsafe_use")]
        corpus.require(positions == sorted(set(positions)), "invalid producer/wait/use order")
        for key in ("producer", "removed_completion", "unsafe_use"):
            anchor = anchors[key]
            corpus.require(lines[anchor["source_line"] - 1].strip() == anchor["instruction"], "stale readiness ground truth")
        corpus.require(case["edits"] == [{"source_line": positions[1], "original": anchors["removed_completion"]["instruction"],
                                         "replacement": "s_nop 0"}], "family mutation changed completion edit")
    for control in document.get("mathematical_controls", []):
        corpus.require(control["case"] in known and known[control["case"]]["expectation"] == "safe",
                       "mathematical control needs a registered safe kernel")
        corpus.require(corpus.sha(root / control["spec"]) == control["spec_sha256"], "stale mathematical control")
        corpus.require(control.get("semantic_reason"), "unjustified mathematical mismatch")
    return document


def load_cases(path=MANIFEST, root=ROOT):
    return validate_cases(json.loads(path.read_text()), root)


def materialize(case, directory):
    source = (ROOT / case["assembly"]).read_text()
    lines = source.splitlines(keepends=True)
    for edit in case.get("edits", []):
        index = edit["source_line"] - 1
        corpus.require(lines[index].strip() == edit["original"], "mutation anchor changed")
        indentation = lines[index][:len(lines[index]) - len(lines[index].lstrip())]
        lines[index] = indentation + edit["replacement"] + "\n"
    path = directory / (case["id"] + Path(case["assembly"]).suffix)
    path.write_text("".join(lines))
    if case.get("mutated_source_sha256"):
        corpus.require(corpus.sha(path) == case["mutated_source_sha256"], "mutation byte identity changed")
    return path


def effective_launch_config(case, assembly, early_readiness):
    original = ROOT / case["launch_config"]
    corpus.require(corpus.sha(original) == case["launch_config_sha256"], "stale launch configuration")
    enabled = early_readiness and case.get("backend", "amdgpu") == "amdgpu" and case["target"] == "gfx1250"
    if not enabled:
        return original
    derived = assembly.with_name(case["id"] + ".early-readiness.launch.json")
    corpus.require(not derived.resolve().is_relative_to(ROOT), "derived launches must remain outside repository")
    configuration = json.loads(original.read_text())
    configuration["early_readiness"] = True
    derived.write_text(json.dumps(configuration, indent=2) + "\n")
    return derived


def launch_contract(argv, case):
    if "--config" not in argv:
        return None
    effective = Path(argv[argv.index("--config") + 1])
    original = ROOT / case["launch_config"]
    before, after = json.loads(original.read_text()), json.loads(effective.read_text())
    changes = {key for key in before.keys() | after.keys() if before.get(key) != after.get(key)}
    corpus.require(changes <= {"early_readiness"}, "derived launch changed kernel inputs")
    return {"original_path": case["launch_config"], "original_sha256": corpus.sha(original),
            "effective_path": str(effective), "effective_sha256": corpus.sha(effective),
            "changed_fields": sorted(changes), "early_readiness": after.get("early_readiness", False)}


def command(binary, case, assembly, expressions, *, verify=False, early_readiness=False, export_outputs=False):
    args = [str(binary), "--no-log-file", "verify" if verify else "analyze", str(assembly)]
    if verify:
        args += [str(ROOT / case["spec"]), "--sample", "0"]
        for name, value in case.get("dimensions", {}).items():
            args += ["--dim", f"{name}={value}"]
    else:
        args += ["--print-outputs", "0"]
        if case["expectation"] == "safe" or export_outputs:
            args += ["--emit-exprs", str(expressions)]
    if case.get("launch_config"):
        args += ["--backend", case.get("backend", "amdgpu"), "--target", case["target"], "--no-profile",
                 "--config", str(effective_launch_config(case, assembly, early_readiness))]
    elif case.get("backend", "amdgpu") == "ptx":
        args += ["--backend", "ptx", "--kernel", case["kernel"], "--no-profile",
                 "--block", ",".join(map(str, case["block"])),
                 "--grid", ",".join(map(str, case["grid"]))]
        for array in case["arrays"]:
            args += ["--array", f"{array['name']}:{array['base_address']}:{array['element_size']}:{array['length']}:{array['kind']}"]
        for value in case["params"]:
            args += ["--param", value]
    else:
        args += corpus.launch(case)
    if early_readiness and not case.get("launch_config") and case.get("backend", "amdgpu") == "amdgpu" and case["target"] == "gfx1250":
        args += ["--early-readiness"]
    return args


def execute(command, case, directory, timeout):
    configuration = launch_contract(command, case)
    resources = directory / "resources.txt"
    resources.unlink(missing_ok=True)
    (directory / "outputs.vexpr").unlink(missing_ok=True)
    measured = ["/usr/bin/time", "-f", "max_rss_kib=%M\nuser_seconds=%U\nsystem_seconds=%S", "-o", str(resources), *command]
    started = time.perf_counter()
    process = subprocess.Popen(measured, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
    selector = selectors.DefaultSelector()
    streams, pending = {"stdout": [], "stderr": []}, {"stdout": "", "stderr": ""}
    for name, stream in [("stdout", process.stdout), ("stderr", process.stderr)]:
        selector.register(stream, selectors.EVENT_READ, name)
    detection, detected_property = None, None
    properties = case.get("valid_detection_properties", [case.get("required_property", "never_a_property")])
    detection_pattern = re.compile(r"^  (" + "|".join(map(re.escape, properties)) + r") \([^\n]*\)\s+FAIL\s*$")
    expired = False
    try:
        while selector.get_map():
            remaining = timeout - (time.perf_counter() - started)
            if remaining <= 0:
                expired = True
                os.killpg(process.pid, 9)
                break
            for key, _ in selector.select(min(remaining, 0.1)):
                chunk = os.read(key.fileobj.fileno(), 65536)
                if not chunk:
                    selector.unregister(key.fileobj)
                    continue
                text = chunk.decode(errors="replace")
                streams[key.data].append(text)
                pending[key.data] += text
                lines = pending[key.data].split("\n")
                pending[key.data] = lines.pop()
                for line in lines:
                    match = detection_pattern.match(line)
                    if key.data == "stdout" and detection is None and case["expectation"] == "hazard":
                        if line == EARLY_MARKER and READINESS_PROPERTY in properties:
                            detection = time.perf_counter() - started
                            detected_property = READINESS_PROPERTY
                        elif match:
                            detection = time.perf_counter() - started
                            detected_property = match[1]
        process.wait(timeout=5)
    finally:
        if process.poll() is None:
            os.killpg(process.pid, 9)
            process.wait()
        selector.close()
        process.stdout.close()
        process.stderr.close()
    elapsed = time.perf_counter() - started
    stdout, stderr = "".join(streams["stdout"]), "".join(streams["stderr"])
    for name, text in [("stdout", stdout), ("stderr", stderr)]:
        (directory / name).write_text(text)
    classification, reason = corpus.classify(process.returncode, stdout, stderr, timed_out=expired)
    corpus.require(not (process.returncode == 2 and "Usage:" in stderr), "invalid benchmark CLI configuration: " + stderr)
    graph = corpus.harness.parse_cli(stdout)
    expressions = directory / "outputs.vexpr"
    graph_accepted = (process.returncode == 0 and graph.verdict == "VERIFIED" and classification == "inconclusive"
                      and graph.checks and all(verdict == "PASS" for _, verdict, _ in graph.checks)
                      and not re.search(r"\bUNKNOWN\b", stdout))
    if graph_accepted and (case["expectation"] == "safe" or "--emit-exprs" in command):
        try:
            corpus.require(corpus.expression_indices(expressions.read_text()) == case["output_indices"], "complete coordinate set differs")
            coverage = corpus.harness.array_coverage_error(stdout, {name: len(indices) for name, indices in case["output_indices"].items()})
            corpus.require(coverage is None, coverage)
            classification, reason = "verified", "graph verified with complete configured output indices"
        except (ValueError, OSError) as error:
            classification, reason = "inconclusive", str(error)
    # A typed invalid-access refusal is distinct from a supported, complete run.
    trace_pass = any(name == "AMD trace completeness" and verdict == "PASS" for name, verdict, _ in graph.checks)
    failed = {name for name, verdict, _ in graph.checks if verdict == "FAIL"}
    stopped = re.search(r"execution stopped:|trace: (?:aborted|unsupported)|unsupported (?:AMD|gfx\d+) instruction", stdout + stderr, re.I)
    backend = case.get("backend", "amdgpu")
    supported_rejection = (process.returncode == 1 and graph.verdict == "REJECTED" and not stopped
                           and (trace_pass if backend == "amdgpu" else not graph.deadlock and graph.no_outputs is None))
    invalid_access = (case.get("diagnostic_family") == "invalid_access"
                      and process.returncode == 1 and graph.verdict == "REJECTED"
                      and case.get("required_diagnostic", "never_a_diagnostic") in stdout + stderr)
    certified_prefix = (
        backend == "amdgpu" and case.get("target") == "gfx1250"
        and process.returncode == 1 and stdout.splitlines().count(EARLY_MARKER) == 1
        and re.findall(r"^VERDICT: (\w+)$", stdout, re.M) == ["REJECT"]
        and (READINESS_PROPERTY, "FAIL") in {(name, verdict) for name, verdict, _ in graph.checks}
        and re.search(r"^  kernel: AmdRegisterHazard \{ issue: EventId\(\d+\), use_event: EventId\(\d+\), "
                      r"wave: \d+, register: AmdRegister \{ file: Scalar, index: \d+, lanes: \d+ \}, "
                      r"kind: ReadBeforeReady \}$", stdout, re.M)
        and not re.search(r"\bunsupported\b|\bUNKNOWN\b|certificate[^\n]*(?:invalid|unvalidated|refused)", stdout + stderr, re.I)
    )
    detected = (classification == "finding" and detection is not None
                and detected_property in failed and (supported_rejection or invalid_access or certified_prefix))
    trace = re.search(r"time: ([\d.]+)s\s+instructions: (\d+)", stdout)
    usage = dict(re.findall(r"^(max_rss_kib|user_seconds|system_seconds)=([\d.]+)$", resources.read_text(), re.M)) if resources.is_file() else {}
    measurement_errors = []
    if not {"max_rss_kib", "user_seconds", "system_seconds"} <= usage.keys():
        measurement_errors.append("missing per-process resource observation")
    elif int(usage["max_rss_kib"]) <= 0:
        measurement_errors.append("nonpositive per-process peak RSS")
    # Preserve all rendered property findings and source witnesses. Only the
    # variable elapsed-time line and artifact destination are excluded.
    diagnostics = "\n".join(line for line in stdout.splitlines()
                             if not re.match(r"^  time: [\d.]+s\s+instructions:", line)
                             and not line.startswith("Wrote output expressions to "))
    return {"classification": classification, "reason": reason,
            "seconds": elapsed, "time_to_detection_seconds": detection if detected else None,
            "detected_expected_hazard": detected, "returncode": process.returncode,
            "timed_out": expired, "command": command,
            "early_readiness_enabled": "--early-readiness" in command or bool(configuration and configuration["early_readiness"]),
            "launch_contract": configuration,
            "detected_property": detected_property if detected else None,
            "detection_mode": ("certified_prefix" if certified_prefix else "typed_invalid_access" if invalid_access else "complete_trace") if detected else None,
            "false_positive": case["expectation"] == "safe" and classification == "finding",
            "false_acceptance": case["expectation"] == "hazard" and bool(graph_accepted),
            "failed_properties": sorted(failed), "measurement_errors": measurement_errors,
            "diagnostics_sha256": hashlib.sha256((diagnostics + "\nstderr:\n" + stderr).encode()).hexdigest(),
            "output_expressions_sha256": corpus.sha(expressions) if expressions.is_file() else None,
            "peak_rss_kib": int(usage["max_rss_kib"]) if "max_rss_kib" in usage else None,
            "user_seconds": float(usage["user_seconds"]) if "user_seconds" in usage else None,
            "system_seconds": float(usage["system_seconds"]) if "system_seconds" in usage else None,
            "supported_rejection": bool(supported_rejection),
            "certified_prefix_rejection": bool(certified_prefix),
            "reported_execution_seconds": float(trace[1]) if trace else None,
            "executed_instructions": int(trace[2]) if trace else None}


def summarize(cases, samples):
    rows = []
    for case in cases:
        selected = [sample for sample in samples if sample["case"] == case["id"]]
        first = next(sample for sample in selected if sample["repeat"] == 0)
        repeated = [sample for sample in selected if sample["repeat"] > 0]
        times = [sample["seconds"] for sample in repeated]
        detected = [sample["time_to_detection_seconds"] for sample in repeated if sample["detected_expected_hazard"]]
        rows.append({"case": case["id"], "family": case["family"], "target": case["target"],
                     "backend": case.get("backend", "amdgpu"),
                     "measurement_role": case.get("measurement_role", "unchanged_backend_control"),
                     "diagnostic_family": case.get("diagnostic_family", "readiness_or_conflict"),
                     "expectation": case["expectation"], "mutation_class": case.get("mutation_class"),
                     "split": case["split"], "classifications": dict(Counter(sample["classification"] for sample in selected)),
                     "repeated_classifications": dict(Counter(sample["classification"] for sample in repeated)),
                     "first_process_seconds": first["seconds"], "repeated_process_median_seconds": median(times),
                     "repeated_process_p95_seconds": percentile95(times), "expected_detections": len(detected),
                     "measured_repeats": len(repeated), "detection_median_seconds": median(detected) if detected else None,
                     "detection_p95_seconds": percentile95(detected) if detected else None})
        rows[-1].update({
            "false_positives": sum(sample.get("false_positive", False) for sample in selected),
            "false_acceptances": sum(sample.get("false_acceptance", False) for sample in selected),
            "missed_expected_hazards": sum(not sample["detected_expected_hazard"] for sample in repeated) if case["expectation"] == "hazard" else None,
            "censored_timeouts": sum(sample.get("timed_out", False) for sample in repeated),
            "measurement_errors": sum(bool(sample.get("measurement_errors")) for sample in selected),
            "detected_properties": dict(Counter(sample.get("detected_property") for sample in repeated if sample["detected_expected_hazard"])),
            "detection_modes": dict(Counter(sample.get("detection_mode") for sample in repeated if sample["detected_expected_hazard"])),
            "latency_population": "detected configurations only; misses and censored timeouts retained separately",
        })
        rows[-1]["peak_rss_kib"] = max((sample["peak_rss_kib"] for sample in selected if sample.get("peak_rss_kib") is not None), default=None)
    return rows


def validate_safe_specs(binary, cases, assemblies, output, timeout, *, early_readiness=False):
    results = []
    for case in cases:
        if case["expectation"] != "safe":
            continue
        directory = output / "spec-preflight" / case["id"]
        directory.mkdir(parents=True)
        argv = command(binary, case, assemblies[case["id"]], None, verify=True, early_readiness=early_readiness)
        stage, stdout, stderr = corpus.run_stage(argv, directory, "verify", timeout)
        stage["launch_contract"] = launch_contract(argv, case)
        classification, reason = corpus.classify(stage["returncode"], stdout, stderr, timed_out=stage["timed_out"])
        counts = re.findall(r"^VC check:.*  elements: (\d+)\s*$", stdout, re.M)
        if stage["returncode"] == 0 and re.search(r"^VERDICT: ACCEPT$", stdout, re.M) and counts == [str(case["expected_outputs"])]:
            classification, reason = "spec_verified", "every complete specification element proved before timing"
        corpus.require(classification != "finding", "safe-case ground truth contradicts specification: " + case["id"] + ": " + reason)
        results.append({"case": case["id"], "classification": classification, "reason": reason, "stage": stage})
    return results


def validate_math_controls(binary, cases, controls, assemblies, output, timeout, *, early_readiness=False):
    registered = {case["id"]: case for case in cases}
    results = []
    for control in controls:
        if control["case"] not in registered:
            continue
        case = {**registered[control["case"]], "spec": control["spec"]}
        directory = output / "mathematical-controls" / control["id"]
        directory.mkdir(parents=True)
        argv = command(binary, case, assemblies[case["id"]], None, verify=True, early_readiness=early_readiness)
        stage, stdout, stderr = corpus.run_stage(argv, directory, "verify", timeout)
        stage["launch_contract"] = launch_contract(argv, case)
        count = re.findall(r"^VC check:.*  elements: (\d+)\s*$", stdout, re.M)
        mismatches = re.findall(r"^NOT EQUIVALENT: (\d+) mismatched element\(s\) vs spec$", stdout, re.M)
        graph = corpus.harness.parse_cli(stdout)
        matched = (stage["returncode"] == 1 and not stage["timed_out"]
                   and re.findall(r"^VERDICT: (\w+)$", stdout, re.M) == ["REJECT"]
                   and count == mismatches == [str(case["expected_outputs"])]
                   and graph.checks and all(verdict == "PASS" for _, verdict, _ in graph.checks))
        corpus.require(matched, "mathematical mismatch was not independently refuted: " + control["id"])
        results.append({"id": control["id"], "classification": "mathematical_refutation", "stage": stage})
    return results


def sample_signature(sample):
    """Values whose equality establishes default-mode diagnostic invariance."""
    return {key: sample[key] for key in ("classification", "detected_expected_hazard", "failed_properties",
                                       "diagnostics_sha256", "executed_instructions", "output_expressions_sha256")}


def paired_ratio_interval(pairs, *, seed=20261030, resamples=2000):
    """Paired bootstrap interval for a ratio of per-case medians, not a theorem."""
    if not pairs:
        return None
    generator = random.Random(seed)
    ratios = []
    for _ in range(resamples):
        sample = [pairs[generator.randrange(len(pairs))] for _ in pairs]
        ratios.append(median([right for _, right in sample]) / median([left for left, _ in sample]))
    ratios.sort()
    return {"lower": ratios[max(0, math.ceil(0.025 * resamples) - 1)],
            "upper": ratios[math.ceil(0.975 * resamples) - 1], "resamples": resamples,
            "paired_observations": len(pairs), "level": 0.95}


def comparison_summary(cases, samples, baseline, candidate, candidate_off, preflight=None, baseline_off=None):
    variants = {name: summarize(cases, [s for s in samples if s["variant"] == name])
                for name in (baseline, candidate)}
    rows = []
    for case in cases:
        left = next(row for row in variants[baseline] if row["case"] == case["id"])
        right = next(row for row in variants[candidate] if row["case"] == case["id"])
        by_variant = {name: [s for s in samples if s["case"] == case["id"] and s["variant"] == name]
                      for name in (baseline, candidate)}
        conclusive = all((s["classification"] == "verified" or s["detected_expected_hazard"]) and not s["measurement_errors"]
                         for values in by_variant.values() for s in values)
        def supported_sample(sample):
            if case["expectation"] == "safe":
                return sample["classification"] == "verified"
            return (sample["detected_expected_hazard"]
                    and sample.get("detection_mode") in {"complete_trace", "certified_prefix"})
        supported = conclusive and all(supported_sample(s) for values in by_variant.values() for s in values)
        spec_status = {name: next((row["classification"] for row in (preflight or {}).get(name, [])
                                  if row["case"] == case["id"]), None)
                       for name in (baseline, candidate, "candidate-off")}
        spec_retained = (case["expectation"] != "safe" or spec_status[baseline] != "spec_verified"
                         or all(status == "spec_verified" for status in spec_status.values()))
        full_spec = (case["expectation"] != "safe" or not supported
                     or all(status == "spec_verified" for status in spec_status.values()))
        default = next(s for s in candidate_off if s["case"] == case["id"])
        original = (next(s for s in baseline_off if s["case"] == case["id"]) if baseline_off is not None
                    else next(s for s in by_variant[baseline] if s["repeat"] == 0))
        invariant = sample_signature(original) == sample_signature(default)
        full_properties = set(case.get("full_mode_required_properties", []))
        full_mode = all(full_properties <= set(s["failed_properties"]) for s in (original, default))
        safety = (right["false_positives"] == right["false_acceptances"] == 0
                  and right["expected_detections"] >= left["expected_detections"])
        baseline_supported = all(supported_sample(s) for s in by_variant[baseline])
        candidate_supported = all(supported_sample(s) for s in by_variant[candidate])
        coverage_retained = not baseline_supported or candidate_supported
        safe_retained = (case["expectation"] != "safe" or not all(s["classification"] == "verified" for s in by_variant[baseline])
                         or all(s["classification"] == "verified" for s in by_variant[candidate]))
        measured = all(not s["measurement_errors"] or s["timed_out"] for values in by_variant.values() for s in values)
        budgets = None
        if supported and case["expectation"] == "safe":
            budgets = {
                "median": right["repeated_process_median_seconds"] <= left["repeated_process_median_seconds"] * 1.05 + 0.001,
                "p95": right["repeated_process_p95_seconds"] <= left["repeated_process_p95_seconds"] * 1.10 + 0.001,
                "peak_rss": right["peak_rss_kib"] <= left["peak_rss_kib"] + max(left["peak_rss_kib"] * 0.05, 8192),
            }
        rows.append({"case": case["id"], "backend": case.get("backend", "amdgpu"), "target": case["target"],
                     "family": case["family"], "split": case["split"], "expectation": case["expectation"],
                     "common_supported": supported, "candidate_off_invariant": invariant,
                     "common_conclusive_diagnostic": conclusive,
                     "invalid_access_refusal_samples": sum(s.get("detection_mode") == "typed_invalid_access"
                                                           for values in by_variant.values() for s in values),
                     "safe_specification_statuses": spec_status if case["expectation"] == "safe" else None,
                     "safe_specifications_retained": spec_retained, "common_supported_full_specification": full_spec,
                     "full_mode_required_properties_retained": full_mode, "safety_counts_retained": safety,
                     "supported_coverage_retained": coverage_retained, "safe_outcomes_retained": safe_retained,
                     "measurement_valid": measured,
                     "safe_overhead_gates": budgets, "baseline": left, "candidate": right})
        pairs = [(l["seconds"], r["seconds"]) for l in by_variant[baseline] for r in by_variant[candidate]
                 if l["repeat"] == r["repeat"] > 0 and not l["timed_out"] and not r["timed_out"]]
        rows[-1]["process_median_ratio_interval"] = paired_ratio_interval(pairs) if supported else None
        detection_pairs = [(l["time_to_detection_seconds"], r["time_to_detection_seconds"])
                           for l in by_variant[baseline] for r in by_variant[candidate]
                           if l["repeat"] == r["repeat"] > 0 and l["detected_expected_hazard"] and r["detected_expected_hazard"]]
        rows[-1]["detection_median_ratio_interval"] = paired_ratio_interval(detection_pairs)
    result = {"cases": rows, "variants": variants,
            "common_supported": sum(row["common_supported"] for row in rows),
            "common_conclusive_diagnostic": sum(row["common_conclusive_diagnostic"] for row in rows),
            "invalid_access_configurations": sum(bool(row["invalid_access_refusal_samples"]) for row in rows),
            "total_configurations": len(rows),
            "correctness_and_overhead_gates_pass": all(row["candidate_off_invariant"] and row["full_mode_required_properties_retained"]
                                       and row["safety_counts_retained"]
                                       and row["safe_specifications_retained"] and row["common_supported_full_specification"]
                                       and row["supported_coverage_retained"] and row["safe_outcomes_retained"] and row["measurement_valid"]
                                       and (row["safe_overhead_gates"] is None or all(row["safe_overhead_gates"].values()))
                                       for row in rows)}
    result["primary_latency_reductions"] = [row["case"] for row in rows if row["case"] in PRIMARY_LATENCY_CASES
        and row["common_supported"] and row["safety_counts_retained"]
        and row["baseline"]["expected_detections"] == row["candidate"]["expected_detections"] == row["baseline"]["measured_repeats"]
        and row["detection_median_ratio_interval"] and row["detection_median_ratio_interval"]["upper"] < 1]
    result["adoption_gates_pass"] = result["correctness_and_overhead_gates_pass"] and bool(result["primary_latency_reductions"])
    return result


def source_comparison(parent, baseline, candidate):
    def git(*args):
        return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    revisions = [git("rev-parse", revision + "^{commit}") for revision in (parent, baseline, candidate)]
    corpus.require(revisions[0] == revisions[1], "baseline must be built from the declared common parent")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", revisions[0], revisions[2]], cwd=ROOT)
    corpus.require(result.returncode == 0, "candidate does not descend from common parent")
    diff = subprocess.check_output(["git", "diff", revisions[0], revisions[2]], cwd=ROOT)
    return {"common_parent": revisions[0], "baseline_revision": revisions[1], "candidate_revision": revisions[2],
            "source_diff_sha256": hashlib.sha256(diff).hexdigest(),
            "changed_paths": git("diff", "--name-only", revisions[0], revisions[2]).splitlines()}


def runtime_context():
    cpuinfo = Path("/proc/cpuinfo")
    model = next((line.split(":", 1)[1].strip() for line in cpuinfo.read_text().splitlines()
                  if line.startswith("model name")), None) if cpuinfo.is_file() else None
    return {"python_version": platform.python_version(), "architecture": platform.machine(),
            "kernel_release": platform.release(), "cpu_model": model, "logical_cpus": os.cpu_count(),
            "allowed_logical_cpus": len(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else None,
            "process_schedule": "sequential fresh processes; randomized adjacent baseline/candidate pairs"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--binary", type=Path, help="Exploratory single-binary run")
    modes.add_argument("--baseline", type=Path, help="Controlled paired baseline executable")
    parser.add_argument("--revision")
    parser.add_argument("--baseline-revision")
    parser.add_argument("--candidate", type=Path)
    parser.add_argument("--candidate-revision")
    parser.add_argument("--common-parent")
    parser.add_argument("--frozen-mechanism", help="Exact candidate commit frozen before any heldout execution")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--split", choices=("development", "heldout", "all"), default="development")
    parser.add_argument("--repeats", type=int, default=31)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--seed", type=int, default=20261030)
    parser.add_argument("--case", action="append", default=[])
    args = parser.parse_args()
    corpus.require(args.repeats > 0 and args.timeout > 0, "positive repeats/budget required")
    document = load_cases()
    context = runtime_context()
    load_observations = [{"phase": "before_preflight", "load_average_1_5_15": os.getloadavg()}]
    cases = [case for case in document["cases"] if (args.split == "all" or case["split"] == args.split)
             and (not args.case or case["id"] in args.case)]
    corpus.require(cases and set(args.case) <= {case["id"] for case in cases}, "empty or unknown case selection")
    comparison = None
    if args.baseline:
        corpus.require(all((args.baseline_revision, args.candidate, args.candidate_revision, args.common_parent)),
                       "paired comparison requires both revisions, candidate and common parent")
        comparison = source_comparison(args.common_parent, args.baseline_revision, args.candidate_revision)
        variants = [("baseline", args.baseline.resolve(strict=True), False, comparison["baseline_revision"]),
                    ("candidate", args.candidate.resolve(strict=True), True, comparison["candidate_revision"])]
    else:
        corpus.require(args.revision, "single-binary exploration requires --revision")
        variants = [("exploratory", args.binary.resolve(strict=True), False, args.revision)]
    if any(case["split"] == "heldout" for case in cases):
        corpus.require(comparison and args.frozen_mechanism == comparison["candidate_revision"],
                       "heldout execution requires a declared frozen paired candidate commit")
    identities = {"case_manifest_sha256": (MANIFEST, corpus.sha(MANIFEST)),
                  "driver_sha256": (Path(__file__), corpus.sha(__file__)),
                  "compiler_corpus_driver_sha256": (HERE.parent / "compiler-corpus/corpus.py", corpus.sha(HERE.parent / "compiler-corpus/corpus.py")),
                  "shared_harness_sha256": (ROOT / "ai_compiler_kernels/check_races.py", corpus.sha(ROOT / "ai_compiler_kernels/check_races.py"))}
    binary_hashes = {name: corpus.sha(binary) for name, binary, _, _ in variants}
    output = args.output.resolve()
    corpus.require(not output.is_relative_to(ROOT), "raw results must remain outside repository")
    output.mkdir(parents=True, exist_ok=False)
    sources = output / "sources"
    sources.mkdir()
    assemblies = {case["id"]: materialize(case, sources) for case in cases}
    preflight, math_controls, candidate_off, baseline_off = {}, {}, [], []
    for name, binary, enabled, _ in variants:
        directory = output / name
        directory.mkdir()
        preflight[name] = validate_safe_specs(binary, cases, assemblies, directory, args.timeout, early_readiness=enabled)
        math_controls[name] = validate_math_controls(binary, cases, document.get("mathematical_controls", []), assemblies,
                                                    directory, args.timeout, early_readiness=enabled)
    if comparison:
        name, binary, _, _ = variants[1]
        directory = output / "candidate-off"
        directory.mkdir()
        preflight["candidate-off"] = validate_safe_specs(binary, cases, assemblies, directory, args.timeout)
        math_controls["candidate-off"] = validate_math_controls(binary, cases, document.get("mathematical_controls", []), assemblies,
                                                               directory, args.timeout)
        for label, control_binary, controls in [("baseline-off", variants[0][1], baseline_off),
                                                ("candidate-off", binary, candidate_off)]:
            for case in cases:
                path = output / label / case["id"]
                path.mkdir(parents=True)
                argv = command(control_binary, case, assemblies[case["id"]], path / "outputs.vexpr", export_outputs=True)
                sample = execute(argv, case, path, args.timeout)
                sample.update(case=case["id"], variant=label)
                controls.append(sample)
                (path / "sample.json").write_text(json.dumps(sample, indent=2) + "\n")
    samples, generator = [], random.Random(args.seed)
    # Each invocation starts a new verifier and fresh graph/solver state.
    for repeat in range(args.repeats + 1):
        load_observations.append({"phase": "before_round", "repeat": repeat, "load_average_1_5_15": os.getloadavg()})
        order = cases.copy()
        generator.shuffle(order)
        for case in order:
            pair = variants.copy()
            generator.shuffle(pair)
            for name, binary, enabled, _ in pair:
                directory = output / name / f"repeat-{repeat}" / case["id"]
                directory.mkdir(parents=True)
                argv = command(binary, case, assemblies[case["id"]], directory / "outputs.vexpr", early_readiness=enabled)
                sample = execute(argv, case, directory, args.timeout)
                sample.update(case=case["id"], repeat=repeat, variant=name)
                samples.append(sample)
                (directory / "sample.json").write_text(json.dumps(sample, indent=2) + "\n")
                print(f"{name} {repeat}/{args.repeats} {case['id']} {sample['classification']} detected={sample['detected_expected_hazard']} seconds={sample['seconds']:.6f}", flush=True)
    for name, binary, _, _ in variants:
        corpus.require(corpus.sha(binary) == binary_hashes[name], "executable changed during measurements: " + name)
    for name, (path, digest) in identities.items():
        corpus.require(corpus.sha(path) == digest, "measurement input changed: " + name)
    load_cases()  # Recheck source/config/spec/ground-truth pins after the run.
    report = {"variants": [{"name": name, "binary_revision": revision, "binary_sha256": binary_hashes[name],
                            "early_readiness": enabled, "early_readiness_scope": "gfx1250 only" if enabled else "disabled"}
                           for name, binary, enabled, revision in variants],
              "source_comparison": comparison,
              **{name: digest for name, (_, digest) in identities.items()},
              "runtime_context": context, "load_observations": load_observations + [{"phase": "finished", "load_average_1_5_15": os.getloadavg()}],
              "seed": args.seed, "timeout_seconds": args.timeout, "repeated_process_samples": args.repeats,
              "cache_policy": "first measured invocation after untimed specification preflight is separate; later invocations reuse OS file caches but no verifier process state; no claim of machine-cold cache",
              "safe_spec_preflight": preflight, "mathematical_controls": math_controls,
              "baseline_off": baseline_off, "candidate_off": candidate_off, "samples": samples,
              "summary": comparison_summary(cases, samples, "baseline", "candidate", candidate_off, preflight, baseline_off) if comparison else summarize(cases, samples),
              "measurement_scope": "Parent-observed process/diagnostic wall time; GNU time maximum RSS for each analyze process. Printed execution time has millisecond precision, and RSS is not attributed to internal phases.",
              "sample_order": [{"repeat": sample["repeat"], "case": sample["case"], "variant": sample["variant"]} for sample in samples]}
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
