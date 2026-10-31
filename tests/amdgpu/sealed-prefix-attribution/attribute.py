#!/usr/bin/env python3
"""Prepare or collect the fixed instrumentation-only prefix replay attribution."""

import argparse
import importlib.util
import json
import math
import os
from pathlib import Path
import random
import statistics
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


bench = module(
    "attribution_frozen_benchmark", HERE.parent / "memory-conflicts-study/benchmark.py"
)
study = bench.study
identity = module(
    "attribution_build_identity", ROOT / "tests/gfx1250/measure_tensor_bounds.py"
)
require, sha = bench.require, bench.sha
PHASES = {
    "discovery",
    "live_prefix_validation",
    "final_prefix_validation",
    "final_ordinary_graph",
    "remaining_execution_output",
}


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def selection():
    value = json.loads((HERE / "selection.json").read_text())
    groups = [value[k] for k in ["late_hazards", "early_primaries", "safe_controls"]]
    require(
        list(map(len, groups)) == [10, 3, 13] and len(set(sum(groups, []))) == 26,
        "changed fixed attribution population",
    )
    require(
        value["repeats"] == 5
        and value["seed"] == 20261031
        and value["timeout_seconds"] == 60,
        "changed fixed observation budget",
    )
    require(
        len(value["gate_cases"]) == len(set(value["gate_cases"])) == 5
        and set(value["gate_cases"]) <= set(value["late_hazards"]),
        "changed gate subset",
    )
    require(
        value["gate"]["minimum_final_validation_ns"] == 1000000
        and value["gate"]["minimum_median_per_sample_share"] == 0.15
        and value["gate"]["minimum_qualifying_cases"] == 3,
        "changed gate thresholds",
    )
    return value


def signature(sample, stdout):
    """Compare exact functional fields, not measured elapsed values or paths."""
    return {
        k: sample[k]
        for k in [
            "status",
            "returncode",
            "detected",
            "detection_mode",
            "graph_accepted",
            "executed_instructions",
            "prefix_counts",
            "diagnostics_sha256",
            "expressions",
        ]
    } | {"first_typed_witness": [list(w) for w in study.WITNESS.findall(stdout)[:1]]}


def prepare(args):
    selected = selection()
    require(
        not args.output.exists() and not args.output.resolve().is_relative_to(ROOT),
        "preparation requires a fresh outside-repository directory",
    )
    require(
        sha(study.MANIFEST) == selected["manifest_sha256"], "original manifest changed"
    )
    require(
        sha(args.preflight) == selected["preflight_sha256"]
        and sha(args.paired_report) == selected["paired_report_sha256"],
        "archived authority changed",
    )
    document = study.load_cases()
    workloads = {w["id"]: w for w in document["workloads"]}
    cases = {c["id"]: c for c in document["cases"]}
    preflight = json.loads(args.preflight.read_text())
    paired = json.loads(args.paired_report.read_text())
    require(
        sha(args.current_on_binary) == selected["current_on_binary_sha256"],
        "current ON must be the immutable57d executable",
    )
    current = identity.build_identity(
        args.current_on_build, selected["source_parent"], args.current_on_binary
    )
    revision = git("rev-parse", "HEAD").decode().strip()
    require(
        not git("status", "--porcelain"),
        "instrumentation source must be committed and clean",
    )
    require(
        git("merge-base", selected["source_parent"], revision).decode().strip()
        == selected["source_parent"],
        "instrumentation does not descend from exact approved parent",
    )
    instrumented = identity.build_identity(
        args.instrumented_build, revision, args.instrumented_binary
    )
    require(
        args.instrumented_binary.stat().st_mode & 0o222 == 0,
        "instrumented executable must be read-only",
    )
    intervals = {
        r["case"]: r["median_ratio_interval"] for r in paired["comparison"]["cases"]
    }
    require(
        {name for name in selected["late_hazards"] if intervals[name]["lower"] > 1}
        == set(selected["gate_cases"]),
        "five historical slower-case selection differs from archived intervals",
    )
    rows = {r["case"]: r for r in preflight["results"]}
    frozen = bench.snapshots(
        [
            args.preflight,
            args.paired_report,
            args.current_on_binary,
            args.current_on_build,
            args.instrumented_binary,
            args.instrumented_build,
            Path(__file__),
            HERE / "selection.json",
            HERE / "protocol.md",
            ROOT / "crates/volta_pipeline/src/attribution.rs",
            ROOT / "crates/volta_pipeline/src/backend.rs",
            ROOT / "crates/volta_pipeline/src/lib.rs",
            study.MANIFEST,
        ]
    )
    # Existing reviewed authority binds the complete original source/helper set.
    bench.unchanged(preflight["input_sha256"])
    frozen.update(preflight["input_sha256"])
    frozen_cases = []
    for case_id in sum(
        [selected[k] for k in ["late_hazards", "early_primaries", "safe_controls"]], []
    ):
        case = cases[case_id]
        row = rows[case_id]
        reference = row["variants"]["candidate"]
        directory = Path(reference["directory"])
        stdout, stderr = directory / "stdout", directory / "stderr"
        require(
            sha(stdout) == reference["stdout_sha256"]
            and sha(stderr) == reference["stderr_sha256"],
            "archived ON transcript changed",
        )
        require(
            not reference["measurement_errors"] and reference["enabled"] is True,
            "archived ON process is not a qualified functional reference",
        )
        require(
            sha(reference["command"][0]) == selected["current_on_binary_sha256"],
            "archived command executable changed",
        )
        expanded = study.expanded_case(workloads[case["workload"]], case)
        assembly = Path(row["assembly"])
        require(
            sha(assembly)
            == row["assembly_sha256"]
            == case["materialized_assembly_sha256"],
            "whole original/mutated module identity changed",
        )
        require(
            "analyze" in reference["command"]
            and "--print-outputs" in reference["command"],
            "unexpected archived invocation",
        )
        if case["expectation"] == "safe":
            require(
                reference["graph_accepted"]
                and reference["export"]["validated_complete"],
                "safe authority lacks its complete actual export",
            )
            observation = bench.safe_export(directory / "outputs.vexpr", expanded)[
                "observation"
            ]
            require(
                observation == reference["expressions"],
                "archived complete output coordinates/bytes changed",
            )
            frozen[str(directory / "outputs.vexpr")] = sha(directory / "outputs.vexpr")
        else:
            require(
                reference["status"] == "certified_rejection"
                and reference["detected"]
                and reference["detection_mode"] == "certified_prefix",
                "hazard authority lacks a certificate",
            )
        frozen.update(bench.snapshots([stdout, stderr, assembly]))
        if reference["launch_configuration"]:
            path = Path(reference["launch_configuration"]["path"])
            require(
                sha(path) == reference["launch_configuration"]["sha256"],
                "archived full configuration changed",
            )
            frozen[str(path)] = sha(path)
        frozen_cases.append(
            {
                "case": expanded,
                "assembly": str(assembly),
                "expected": signature(reference, stdout.read_text()),
                "reference_command": reference["command"],
                "reference_configuration": reference["launch_configuration"],
                "safe_complete_equation_previously_proved": row["specifications"]
                .get("candidate", {})
                .get("status")
                == "spec_verified",
                "historical_ratio_interval": intervals.get(case_id),
            }
        )
    args.output.mkdir()
    patch = git("diff", "--binary", selected["source_parent"], revision, "--")
    (args.output / "instrumentation.patch").write_bytes(patch)
    plan = {
        "schema_version": 1,
        "selection": selected,
        "selection_sha256": sha(HERE / "selection.json"),
        "protocol_sha256": sha(HERE / "protocol.md"),
        "source_parent": selected["source_parent"],
        "instrumented_revision": revision,
        "instrumentation_patch_sha256": study.digest(patch),
        "builds": {"current_on": current, "instrumented": instrumented},
        "binaries": {
            "current_on": str(args.current_on_binary.resolve()),
            "instrumented": str(args.instrumented_binary.resolve()),
        },
        "input_sha256": frozen,
        "cases": frozen_cases,
        "scope": "Prepared only; no attribution processes have been executed.",
    }
    write(args.output / "plan.json", plan)
    print(
        "Prepared26 cases,0 verifier processes; plan SHA256 "
        + sha(args.output / "plan.json")
    )


def validate_phases(value, prediagnostic_ns, hazard):
    require(
        value["schema_version"] == 1
        and value["valid"] is True
        and set(value["phases"]) == PHASES,
        "missing/invalid exclusive phase observations",
    )
    require(
        type(value["root_ns"]) is int and value["root_ns"] > 0,
        "invalid pipeline root span",
    )
    for phase in value["phases"].values():
        require(
            set(phase) == {"exclusive_ns", "calls"}
            and all(type(v) is int and v >= 0 for v in phase.values()),
            "invalid phase count/duration",
        )
    require(
        sum(p["exclusive_ns"] for p in value["phases"].values()) == value["root_ns"],
        "nested phase double-count/gap",
    )
    require(
        value["phases"]["remaining_execution_output"]["calls"] == 1
        and value["phases"]["final_ordinary_graph"]["calls"] == 1,
        "missing ordinary final graph/root call",
    )
    require(
        value["phases"]["final_prefix_validation"]["calls"] == int(hazard),
        "unexpected final replay count",
    )
    require(
        value["phases"]["discovery"]["calls"] > 0, "observer discovery was not measured"
    )
    require(
        value["root_ns"] <= prediagnostic_ns, "pipeline span exceeds parent endpoint"
    )


def phase_observation(phases, endpoint_ns, hazard):
    """Malformed metrics remain failed observations, never partial arithmetic."""
    errors = []
    remainder = None
    try:
        require(
            type(endpoint_ns) in (int, float)
            and math.isfinite(endpoint_ns)
            and endpoint_ns > 0,
            "missing/invalid parent endpoint",
        )
        validate_phases(phases, endpoint_ns, hazard)
        remainder = endpoint_ns - phases["root_ns"]
    except (ValueError, KeyError, TypeError, AttributeError) as error:
        errors.append("phase measurement error: " + str(error))
    return {
        "phases": phases,
        "parent_prediagnostic_wall_ns": endpoint_ns,
        "attribution_errors": errors,
        "unassigned_parent_remainder_ns": remainder,
    }


def summarize(samples, selected):
    rows = []
    for case_id in sum(
        [selected[k] for k in ["late_hazards", "early_primaries", "safe_controls"]], []
    ):
        values = [s for s in samples if s["case"] == case_id]
        complete = len(values) == 5 and {s["repeat"] for s in values} == set(
            range(1, 6)
        )
        valid = complete and all(not s["attribution_errors"] for s in values)
        final = (
            [
                s["phases"]["phases"]["final_prefix_validation"]["exclusive_ns"]
                for s in values
            ]
            if valid
            else []
        )
        shares = (
            [f / s["parent_prediagnostic_wall_ns"] for f, s in zip(final, values)]
            if valid
            else []
        )
        rows.append(
            {
                "case": case_id,
                "all_five_valid": valid,
                "gate_case": case_id in selected["gate_cases"],
                "median_final_prefix_validation_ns": statistics.median(final)
                if valid
                else None,
                "median_per_sample_final_share": statistics.median(shares)
                if valid
                else None,
                "meets_cost_gate": bool(
                    valid
                    and case_id in selected["gate_cases"]
                    and statistics.median(final) >= 1000000
                    and statistics.median(shares) >= 0.15
                ),
            }
        )
    qualified = sum(r["meets_cost_gate"] for r in rows)
    return {
        "cases": rows,
        "qualifying_gate_cases": qualified,
        "all130_samples_valid": len(samples) == 130
        and all(r["all_five_valid"] for r in rows),
        "gate_pass": qualified >= 3
        and len(samples) == 130
        and all(r["all_five_valid"] for r in rows),
    }


def collect(args):
    require(
        sha(args.plan) == args.reviewed_plan_sha256,
        "plan differs from reviewed preparation",
    )
    plan = json.loads(args.plan.read_text())
    require(plan["selection"] == selection(), "selection changed after preparation")
    require(
        not args.output.exists() and not args.output.resolve().is_relative_to(ROOT),
        "collection requires a fresh outside-repository directory",
    )
    require(
        not git("status", "--porcelain")
        and git("rev-parse", "HEAD").decode().strip() == plan["instrumented_revision"],
        "instrumented source changed",
    )
    bench.unchanged(plan["input_sha256"])
    args.output.mkdir()
    rng = random.Random(plan["selection"]["seed"])
    samples = []
    for repeat in range(1, 6):
        order = list(plan["cases"])
        rng.shuffle(order)
        for row in order:
            case = row["case"]
            directory = args.output / case["id"] / str(repeat)
            metrics = directory / "phases.json"
            previous_env = os.environ.get("VOLTA_STAGE_A_PHASES")
            errors = []
            sample = None
            try:
                os.environ["VOLTA_STAGE_A_PHASES"] = str(metrics.resolve())
                sample = bench.execute(
                    Path(plan["binaries"]["instrumented"]),
                    case,
                    Path(row["assembly"]),
                    directory,
                    enabled=True,
                    export=case["expectation"] == "safe",
                )
            except (OSError, ValueError, KeyError, TypeError) as error:
                errors.append("process/contract error: " + str(error))
            finally:
                if previous_env is None:
                    os.environ.pop("VOLTA_STAGE_A_PHASES", None)
                else:
                    os.environ["VOLTA_STAGE_A_PHASES"] = previous_env
            phases, endpoint_ns = None, None
            if sample is not None:
                stdout = (directory / "stdout").read_text()
                if signature(sample, stdout) != row["expected"]:
                    errors.append(
                        "functional outcome, exact first witness, counts, diagnostics or output bytes changed"
                    )
                errors.extend(sample["measurement_errors"])
                if (
                    sample["launch_configuration"]
                    and sample["launch_configuration"]["value"]
                    != row["reference_configuration"]["value"]
                ):
                    errors.append("full original launch configuration changed")
                endpoint = (
                    sample["time_to_detection_seconds"]
                    if case["expectation"] == "hazard"
                    else sample["seconds"]
                )
                endpoint_ns = endpoint * 1_000_000_000 if endpoint is not None else None
                try:
                    phases = json.loads(metrics.read_text())
                except (OSError, ValueError, KeyError, TypeError) as error:
                    errors.append("phase measurement error: " + str(error))
            measured = phase_observation(
                phases, endpoint_ns, case["expectation"] == "hazard"
            )
            observation = {
                "case": case["id"],
                "repeat": repeat,
                "process": sample,
                **measured,
                "attribution_errors": errors + measured["attribution_errors"],
                "safe_complete_equation_previously_proved": row[
                    "safe_complete_equation_previously_proved"
                ],
            }
            samples.append(observation)
            write(args.output / "checkpoint.json", {"samples": samples})
    bench.unchanged(plan["input_sha256"])
    report = {
        "schema_version": 1,
        "reviewed_plan_sha256": args.reviewed_plan_sha256,
        "samples": samples,
        "summary": summarize(samples, plan["selection"]),
        "scope": "Instrumented phase attribution only; no replacement uninstrumented latency or CPU-attribution claim.",
    }
    write(args.output / "report.json", report)
    print(json.dumps(report["summary"], indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    prep = commands.add_parser(
        "prepare", help="Validate and freeze artifacts without launching a verifier"
    )
    for name in [
        "current-on-binary",
        "current-on-build",
        "instrumented-binary",
        "instrumented-build",
        "preflight",
        "paired-report",
        "output",
    ]:
        prep.add_argument("--" + name, type=Path, required=True)
    run = commands.add_parser(
        "collect",
        help="Execute only after code/protocol review and explicit idle clearance",
    )
    run.add_argument("--plan", type=Path, required=True)
    run.add_argument("--reviewed-plan-sha256", required=True)
    run.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    (prepare if args.action == "prepare" else collect)(args)


if __name__ == "__main__":
    main()
