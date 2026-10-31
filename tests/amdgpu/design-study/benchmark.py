#!/usr/bin/env python3
"""Measure declared AMD safety controls; keep raw samples outside the repository."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
import os
from pathlib import Path
import random
import re
import selectors
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent / "compiler-corpus"))
import corpus  # noqa: E402


def percentile95(values):
    return sorted(values)[max(0, math.ceil(0.95 * len(values)) - 1)]


def median(values):
    ordered = sorted(values)
    middle = len(ordered) // 2
    return ordered[middle] if len(ordered) % 2 else (ordered[middle - 1] + ordered[middle]) / 2


def load_cases():
    document = json.loads((HERE / "cases.json").read_text())
    cases = document["cases"]
    corpus.require(len(cases) == len({case["id"] for case in cases}), "duplicate case IDs")
    for case in cases:
        for field in ("source", "assembly", "spec"):
            if case.get(field):
                corpus.require(corpus.sha(ROOT / case[field]) == case[field + "_sha256"], "stale case input: " + case["id"])
        corpus.require(case["expectation"] in {"safe", "hazard"}, "unknown semantic expectation")
        if case["expectation"] == "hazard":
            corpus.require(case.get("required_property") and case.get("semantic_reason"), "unjustified hazard expectation")
        if case.get("launch_config"):
            corpus.require(corpus.sha(ROOT / case["launch_config"]) == case["launch_config_sha256"], "stale launch")
        for field in ("expectation_source", "assembly_mutation_manifest"):
            if case.get(field + "_sha256"):
                corpus.require(corpus.sha(ROOT / case[field]) == case[field + "_sha256"], "stale independent expectation source")
        if case.get("expectation_function"):
            text = (ROOT / case["expectation_source"]).read_text()
            match = re.search(r"\bfn\s+" + re.escape(case["expectation_function"]) + r"\s*\(", text)
            corpus.require(match, "missing ground-truth test function")
            following = re.search(r"(?m)^\s*fn\s+\w+\s*\(", text[match.end():])
            region = text[match.start():match.end() + following.start()] if following else text[match.start():]
            corpus.require(case["expectation_anchor"] in region, "missing ground-truth assertion anchor")
    return document


def materialize(case, directory):
    source = (ROOT / case["assembly"]).read_text()
    lines = source.splitlines(keepends=True)
    for edit in case.get("edits", []):
        index = edit["source_line"] - 1
        corpus.require(lines[index].strip() == edit["original"], "mutation anchor changed")
        indentation = lines[index][:len(lines[index]) - len(lines[index].lstrip())]
        lines[index] = indentation + edit["replacement"] + "\n"
    path = directory / (case["id"] + ".s")
    path.write_text("".join(lines))
    if case.get("mutated_source_sha256"):
        corpus.require(corpus.sha(path) == case["mutated_source_sha256"], "mutation byte identity changed")
    return path


def command(binary, case, assembly, expressions, *, verify=False):
    args = [str(binary), "--no-log-file", "verify" if verify else "analyze", str(assembly)]
    if verify:
        args += [str(ROOT / case["spec"]), "--sample", "0"]
        for name, value in case.get("dimensions", {}).items():
            args += ["--dim", f"{name}={value}"]
    else:
        args += ["--print-outputs", "0", "--emit-exprs", str(expressions)]
    if case.get("launch_config"):
        args += ["--backend", "amdgpu", "--target", case["target"], "--no-profile",
                 "--config", str(ROOT / case["launch_config"])]
    else:
        args += corpus.launch(case)
    return args


def execute(command, case, directory, timeout):
    resources = directory / "resources.txt"
    measured = ["/usr/bin/time", "-f", "max_rss_kib=%M\nuser_seconds=%U\nsystem_seconds=%S", "-o", str(resources), *command]
    started = time.perf_counter()
    process = subprocess.Popen(measured, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
    selector = selectors.DefaultSelector()
    streams, pending = {"stdout": [], "stderr": []}, {"stdout": "", "stderr": ""}
    for name, stream in [("stdout", process.stdout), ("stderr", process.stderr)]:
        selector.register(stream, selectors.EVENT_READ, name)
    detection = None
    detection_pattern = re.compile(r"^  " + re.escape(case.get("required_property", "never_a_property")) + r" \([^\n]*\)\s+FAIL\s*$")
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
                    if detection is None and case["expectation"] == "hazard" and detection_pattern.match(line):
                        detection = time.perf_counter() - started
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
    if process.returncode == 0 and graph.verdict == "VERIFIED":
        try:
            corpus.require(corpus.expression_indices(expressions.read_text()) == case["output_indices"], "complete coordinate set differs")
            classification, reason = "verified", "graph verified with complete configured output indices"
        except (ValueError, OSError) as error:
            classification, reason = "inconclusive", str(error)
    # Unsupported, aborted, timed-out and crashed runs never satisfy detection.
    trace_pass = any(name == "AMD trace completeness" and verdict == "PASS" for name, verdict, _ in graph.checks)
    stopped = re.search(r"execution stopped:|trace: (?:aborted|unsupported)|unsupported (?:AMD|gfx\d+) instruction", stdout + stderr, re.I)
    supported_rejection = process.returncode == 1 and graph.verdict == "REJECTED" and trace_pass and not stopped
    detected = classification == "finding" and detection is not None and supported_rejection
    trace = re.search(r"time: ([\d.]+)s\s+instructions: (\d+)", stdout)
    usage = dict(re.findall(r"^(max_rss_kib|user_seconds|system_seconds)=([\d.]+)$", resources.read_text(), re.M)) if resources.is_file() else {}
    return {"classification": classification, "reason": reason,
            "seconds": elapsed, "time_to_detection_seconds": detection if detected else None,
            "detected_expected_hazard": detected, "returncode": process.returncode,
            "timed_out": expired, "command": command,
            "peak_rss_kib": int(usage["max_rss_kib"]) if "max_rss_kib" in usage else None,
            "supported_rejection": bool(supported_rejection),
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
                     "expectation": case["expectation"], "mutation_class": case.get("mutation_class"),
                     "split": case["split"], "classifications": dict(Counter(sample["classification"] for sample in selected)),
                     "first_process_seconds": first["seconds"], "repeated_process_median_seconds": median(times),
                     "repeated_process_p95_seconds": percentile95(times), "expected_detections": len(detected),
                     "measured_repeats": len(repeated), "detection_median_seconds": median(detected) if detected else None,
                     "detection_p95_seconds": percentile95(detected) if detected else None})
        rows[-1]["peak_rss_kib"] = max((sample["peak_rss_kib"] for sample in selected if sample.get("peak_rss_kib") is not None), default=None)
    return rows


def validate_safe_specs(binary, cases, assemblies, output, timeout):
    results = []
    for case in cases:
        if case["expectation"] != "safe":
            continue
        directory = output / "spec-preflight" / case["id"]
        directory.mkdir(parents=True)
        argv = command(binary, case, assemblies[case["id"]], None, verify=True)
        stage, stdout, stderr = corpus.run_stage(argv, directory, "verify", timeout)
        classification, reason = corpus.classify(stage["returncode"], stdout, stderr, timed_out=stage["timed_out"])
        counts = re.findall(r"^VC check:.*  elements: (\d+)\s*$", stdout, re.M)
        if stage["returncode"] == 0 and re.search(r"^VERDICT: ACCEPT$", stdout, re.M) and counts == [str(case["expected_outputs"])]:
            classification, reason = "spec_verified", "every complete specification element proved before timing"
        corpus.require(classification != "finding", "safe-case ground truth contradicts specification: " + case["id"] + ": " + reason)
        results.append({"case": case["id"], "classification": classification, "reason": reason, "stage": stage})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--split", choices=("development", "heldout", "all"), default="development")
    parser.add_argument("--repeats", type=int, default=7)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--seed", type=int, default=20261030)
    parser.add_argument("--case", action="append", default=[])
    args = parser.parse_args()
    corpus.require(args.repeats > 0 and args.timeout > 0, "positive repeats/budget required")
    document = load_cases()
    cases = [case for case in document["cases"] if (args.split == "all" or case["split"] == args.split)
             and (not args.case or case["id"] in args.case)]
    corpus.require(cases and set(args.case) <= {case["id"] for case in cases}, "empty or unknown case selection")
    output, binary = args.output.resolve(), args.binary.resolve(strict=True)
    corpus.require(not output.is_relative_to(ROOT), "raw results must remain outside repository")
    output.mkdir(parents=True, exist_ok=False)
    sources = output / "sources"
    sources.mkdir()
    assemblies = {case["id"]: materialize(case, sources) for case in cases}
    preflight = validate_safe_specs(binary, cases, assemblies, output, args.timeout)
    samples, generator = [], random.Random(args.seed)
    # Each invocation starts a new verifier and fresh graph/solver state.
    for repeat in range(args.repeats + 1):
        order = cases.copy()
        generator.shuffle(order)
        for case in order:
            directory = output / f"repeat-{repeat}" / case["id"]
            directory.mkdir(parents=True)
            argv = command(binary, case, assemblies[case["id"]], directory / "outputs.vexpr")
            sample = execute(argv, case, directory, args.timeout)
            sample.update(case=case["id"], repeat=repeat)
            samples.append(sample)
            (directory / "sample.json").write_text(json.dumps(sample, indent=2) + "\n")
            print(f"{repeat}/{args.repeats} {case['id']} {sample['classification']} detected={sample['detected_expected_hazard']} seconds={sample['seconds']:.6f}", flush=True)
    report = {"binary_revision": args.revision, "binary_sha256": corpus.sha(binary),
              "case_manifest_sha256": corpus.sha(HERE / "cases.json"), "driver_sha256": corpus.sha(__file__),
              "compiler_corpus_driver_sha256": corpus.sha(HERE.parent / "compiler-corpus/corpus.py"),
              "shared_harness_sha256": corpus.sha(ROOT / "ai_compiler_kernels/check_races.py"),
              "seed": args.seed, "timeout_seconds": args.timeout, "repeated_process_samples": args.repeats,
              "cache_policy": "first measured invocation after untimed specification preflight is separate; later invocations reuse OS file caches but no verifier process state; no claim of machine-cold cache",
              "safe_spec_preflight": preflight, "summary": summarize(cases, samples), "samples": samples}
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
