#!/usr/bin/env python3
"""Compute descriptive paired p95-margin intervals without changing overhead gates."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import random

VARIANTS = ("baseline", "candidate")
IDENTITY_FIELDS = (
    "source_comparison", "variants", "case_manifest_sha256", "driver_sha256",
    "compiler_corpus_driver_sha256", "shared_harness_sha256",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def positive_integer(value):
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return parsed


def seconds(value):
    require(isinstance(value, (int, float)) and not isinstance(value, bool)
            and math.isfinite(value) and value > 0, "process durations must be positive finite numbers")
    return value


def q95(values):
    return sorted(values)[math.ceil(.95 * len(values)) - 1]


def validate_report(report):
    """Index complete unique pairs before resampling; do not collapse duplicates."""
    repeats = report["repeated_process_samples"]
    require(isinstance(repeats, int) and not isinstance(repeats, bool) and repeats > 0,
            "report must declare a positive repetition count")
    cases = report["summary"]["cases"]
    require(isinstance(cases, list) and cases, "paired report needs nonempty case summaries")
    names = [case["case"] for case in cases]
    require(all(isinstance(name, str) and name for name in names) and len(set(names)) == len(names),
            "empty or duplicate summary case IDs")
    require(report["summary"]["total_configurations"] == len(cases), "summary configuration count differs")
    require(all(case["expectation"] in {"safe", "hazard"} for case in cases), "unknown case expectation")
    safe = [case for case in cases if case["expectation"] == "safe"]
    require(safe, "report has no safe configurations")

    identity = {field: report[field] for field in IDENTITY_FIELDS}
    variants = identity["variants"]
    require(isinstance(variants, list) and len(variants) == 2
            and {variant["name"] for variant in variants} == set(VARIANTS), "expected exactly baseline and candidate")
    comparison = identity["source_comparison"]
    require(comparison["common_parent"] == comparison["baseline_revision"], "baseline differs from common parent")
    for variant in variants:
        require(variant["binary_revision"] == comparison[variant["name"] + "_revision"], "binary/source revision differs")
        digest = variant["binary_sha256"]
        require(isinstance(digest, str) and len(digest) == 64
                and all(char in "0123456789abcdef" for char in digest), "invalid executable hash")

    expected_names = set(names)
    samples = {name: {variant: {} for variant in VARIANTS} for name in names}
    for sample in report["samples"]:
        name, variant, repeat = sample["case"], sample["variant"], sample["repeat"]
        require(name in expected_names and variant in VARIANTS, "unknown sample case or variant")
        require(isinstance(repeat, int) and not isinstance(repeat, bool) and 0 <= repeat <= repeats,
                "sample repeat outside declared range")
        indexed = samples[name][variant]
        require(repeat not in indexed, f"duplicate pair member: {name}/{variant}/{repeat}")
        seconds(sample["seconds"])
        indexed[repeat] = sample
    expected_repeats = set(range(repeats + 1))
    for name in names:
        for variant in VARIANTS:
            require(set(samples[name][variant]) == expected_repeats, f"missing pair member: {name}/{variant}")
    return repeats, safe, samples, identity


def intervals(report, *, seed, resamples):
    repeats, safe, indexed, identity = validate_report(report)
    rows = []
    for case in safe:
        samples = indexed[case["case"]]
        require(all(sample["classification"] == "verified" and not sample["timed_out"]
                    and not sample["measurement_errors"] for variant in VARIANTS
                    for repeat, sample in samples[variant].items() if repeat > 0),
                "safe repeated samples must be verified, uncensored and resource-complete: " + case["case"])
        pairs = [(samples["baseline"][repeat]["seconds"], samples["candidate"][repeat]["seconds"])
                 for repeat in range(1, repeats + 1)]
        left = q95([pair[0] for pair in pairs])
        right = q95([pair[1] for pair in pairs])
        require(all(seconds(case[variant]["repeated_process_p95_seconds"]) == value
                    for variant, value in zip(VARIANTS, (left, right))), "stored p95 differs from raw pairs")
        gate = case["safe_overhead_gates"]["p95"]
        require(isinstance(gate, bool) and gate == (right <= left * 1.10 + .001), "stored p95 gate differs")
        generator = random.Random(seed)
        margins = []
        for _ in range(resamples):
            resampled = [pairs[generator.randrange(repeats)] for _ in pairs]
            margins.append(q95([pair[1] for pair in resampled]) - 1.10 * q95([pair[0] for pair in resampled]) - .001)
        margins.sort()
        lower = margins[math.ceil(.025 * resamples) - 1]
        upper = margins[math.ceil(.975 * resamples) - 1]
        rows.append({"case": case["case"], "baseline_p95_seconds": left, "candidate_p95_seconds": right,
                     "fixed_limit_seconds": left * 1.10 + .001, "point_margin_seconds": right - left * 1.10 - .001,
                     "fixed_gate_pass": gate,
                     "descriptive_interval_seconds": {"lower": lower, "upper": upper, "level": .95},
                     "interval_position": "above_zero" if lower > 0 else "below_zero" if upper < 0 else "includes_zero"})
    return {"report_identity": identity, "measurement_seed": report["seed"],
            "seed_per_case": seed, "resamples_per_case": resamples, "paired_repeated_observations": repeats,
            "margin": "p95(candidate) - 1.10*p95(baseline) - 0.001 seconds",
            "method": "paired resampling by repeat; nearest-rank p95; percentile 95% interval",
            "scope": "descriptive per-case intervals, no simultaneous-coverage claim; not a replacement gate",
            "safe_configurations": len(rows), "cases": rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path, help="Completed paired benchmark report JSON")
    parser.add_argument("--output", type=Path, required=True, help="New output JSON; existing paths are refused")
    parser.add_argument("--resamples", type=positive_integer, default=2000)
    parser.add_argument("--seed", type=int, default=20261031)
    args = parser.parse_args()
    try:
        source = args.report.resolve(strict=True)
        require(args.output.resolve() != source, "output aliases input report")
        require(not args.output.exists() and not args.output.is_symlink(), "output already exists")
        raw = source.read_bytes()
        result = intervals(json.loads(raw), seed=args.seed, resamples=args.resamples)
        result.update(input_report_sha256=hashlib.sha256(raw).hexdigest(),
                      postprocessor_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
        text = json.dumps(result, indent=2, allow_nan=False) + "\n"
        with args.output.open("x") as output:
            output.write(text)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    print(json.dumps({"output": str(args.output), "safe_configurations": result["safe_configurations"],
                      "fixed_p95_gate_failures": [row["case"] for row in result["cases"] if not row["fixed_gate_pass"]],
                      "interval_positions": {kind: sum(row["interval_position"] == kind for row in result["cases"])
                                             for kind in ("above_zero", "includes_zero", "below_zero")}}, indent=2))


if __name__ == "__main__":
    main()
