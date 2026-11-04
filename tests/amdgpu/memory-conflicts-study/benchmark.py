#!/usr/bin/env python3
"""Paired development measurements after the frozen baseline qualification.

No builds, GPU execution, heldouts, expectation changes or adaptive repetitions.
See protocol.md before running either collection command.
"""

from __future__ import annotations

import argparse
from collections import Counter
import importlib.util
import json
import os
from pathlib import Path
import random
import re
import selectors
import signal
import subprocess
import time

HERE = Path(__file__).resolve().parent


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


study = module("memory_conflicts_qualification", HERE / "study.py")
# Reuse only unchanged generic statistics, source ancestry and runtime context.
# The earlier study's commands, classifications and published results are unused.
statistics = module("readiness_statistics", HERE.parent / "design-study/benchmark.py")
ROOT, corpus = study.ROOT, study.corpus
require, sha = corpus.require, corpus.sha
COMMON_PARENT = "0e634bc43536e5e4ac5cb13e8046d8e1edd57250"
BASELINE_SHA = "f139a98f1990d73b599bbd2ae4cd6d5ee81fc813a46d5dc956b6b4a840ef94b8"
MANIFEST_SHA = "f61df7312961ad8540b34de6f41647df9b165e2ae068dc9a2a25672d90f83886"
RECEIPT = HERE / "results/baseline-20261031.json"
TIME = Path("/usr/bin/time")
ROLES = ("baseline", "candidate-off", "candidate")
TIMEOUT = 60


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def fresh(path):
    path = path.resolve()
    require(
        not path.exists() and not path.is_relative_to(ROOT),
        "output must be fresh and outside repository",
    )
    path.mkdir(parents=True)
    return path


def development(document):
    workloads = {row["id"]: row for row in document["workloads"]}
    return [
        study.expanded_case(workloads[c["workload"]], c)
        for c in document["cases"]
        if c["split"] == "development"
    ]


def baseline_report(path, document):
    """Check the immutable report and all original process transcript bindings."""
    require(sha(path) == BASELINE_SHA, "not the frozen baseline report")
    report = json.loads(path.read_text())
    receipt = json.loads(RECEIPT.read_text())
    cases = development(document)
    require(
        sha(study.MANIFEST)
        == MANIFEST_SHA
        == report["input_sha256"]["manifest"]
        == receipt["manifest_sha256"],
        "manifest changed",
    )
    require(
        report["binary_revision"] == receipt["baseline_revision"] == COMMON_PARENT,
        "baseline parent differs",
    )
    require(
        report["heldouts_executed"] == 0 and report["cases"] == 40,
        "baseline scope differs",
    )
    require(receipt["raw_report_sha256"] == BASELINE_SHA, "baseline receipt differs")
    require(
        sha(Path(study.__file__))
        == receipt["collector_sha256"]
        == report["input_sha256"]["driver"],
        "frozen baseline collector changed",
    )
    rows = {row["case"]: row for row in report["results"]}
    require(
        len(rows) == len(report["results"]) == len(cases) == 40
        and set(rows) == {c["id"] for c in cases},
        "baseline case set differs",
    )
    eligible = [row["case"] for row in report["results"] if row["timing_eligible"]]
    require(
        eligible == report["timing_eligible"] == receipt["timing_eligible"]
        and len(eligible) == 28,
        "baseline timing eligibility differs",
    )
    inventory = []
    for row in report["results"]:
        for stage in ("assemble", "analyze", "verify"):
            if stage in row:
                inventory.append(
                    transcript_entry(path.parent, row["case"], stage, row[stage])
                )
        case = next(c for c in cases if c["id"] == row["case"])
        require(
            sha(path.parent / case["id"] / "complete-module.s")
            == case["materialized_assembly_sha256"],
            "baseline module changed",
        )
    for row in report["mathematical_controls"]:
        inventory.append(
            transcript_entry(path.parent, row["id"], "wrong-spec", row["stage"])
        )
    require(
        len(inventory) == receipt["process_records"] == 100
        and study.canonical(inventory) == receipt["transcript_inventory_sha256"],
        "baseline process evidence changed",
    )
    exports = []
    for case in cases:
        expression = path.parent / case["id"] / "outputs.vexpr"
        if case["expectation"] == "safe" and expression.is_file():
            exports.append({"case": case["id"], **expression_observation(expression)})
    require(
        exports == receipt["retained_safe_export_inventory"]
        and study.canonical(exports)
        == receipt["retained_safe_export_inventory_sha256"],
        "retained baseline exports changed",
    )
    require(
        sum(c["expectation"] == "safe" for c in cases if c["id"] in eligible) == 15,
        "baseline safe denominator differs",
    )
    return report


def transcript_entry(directory, name, stage, record):
    return {
        "case": name,
        "stage": stage,
        "process_record_sha256": study.canonical(record),
        "stdout_sha256": sha(directory / name / (stage + ".stdout")),
        "stderr_sha256": sha(directory / name / (stage + ".stderr")),
    }


def snapshots(paths):
    return {str(path): sha(path) for path in sorted(set(paths))}


def unchanged(hashes):
    require(
        all(
            Path(path).is_file() and sha(path) == value
            for path, value in hashes.items()
        ),
        "measurement input changed",
    )


def inputs(document, args):
    paths = [
        Path(__file__),
        HERE / "test_benchmark.py",
        HERE / "test_study.py",
        HERE / "protocol.md",
        RECEIPT,
        Path(study.__file__),
        study.MANIFEST,
        Path(corpus.__file__),
        Path(corpus.harness.__file__),
        Path(study.build_records.__file__),
        Path(statistics.__file__),
        TIME,
    ]
    paths += [
        args.baseline_report,
        args.baseline_binary,
        args.candidate_binary,
        args.baseline_build_record,
        args.candidate_build_record,
    ]
    for row in document["workloads"]:
        paths += [
            ROOT / row[key]
            for key in ("source", "assembly", "spec", "manifest", "launch_config")
            if key in row
        ]
    paths += [ROOT / row["spec"] for row in document["mathematical_controls"]]
    return snapshots(paths)


def identities(args):
    source = statistics.source_comparison(
        COMMON_PARENT, COMMON_PARENT, args.candidate_revision
    )
    require(
        subprocess.run(
            ["git", "merge-base", "--is-ancestor", COMMON_PARENT, "HEAD"],
            cwd=ROOT,
            check=False,
        ).returncode
        == 0,
        "harness does not descend from common parent",
    )
    builds = {
        "baseline": study.build_records.build_identity(
            args.baseline_build_record, COMMON_PARENT, args.baseline_binary
        ),
        "candidate": study.build_records.build_identity(
            args.candidate_build_record,
            source["candidate_revision"],
            args.candidate_binary,
        ),
    }
    require(
        builds["baseline"]["binary_sha256"]
        == json.loads(RECEIPT.read_text())["baseline_binary_sha256"],
        "wrong baseline executable",
    )
    return {
        "sources": source,
        "builds": builds,
        "trust": "Caller-attested source/binary association, not an independent proof of the build; diagnostics trust the validated-certificate code path, not cryptographic authentication.",
    }


def diagnostics(stdout, stderr):
    """Retain findings and counts; remove only elapsed values and export paths."""
    lines = []
    for line in stdout.splitlines():
        if line.startswith("Wrote output expressions to "):
            continue
        line = re.sub(r"^(  time:) [\d.]+s(\s+instructions:)", r"\1 <elapsed>\2", line)
        line = re.sub(r"^(VC check:) [\d.]+s", r"\1 <elapsed>", line)
        lines.append(line)
    return study.digest(("\n".join(lines) + "\nstderr:\n" + stderr).encode())


def expression_observation(path):
    if not path.is_file():
        return None
    indices = corpus.expression_indices(path.read_text())
    return {
        "sha256": sha(path),
        "bytes": path.stat().st_size,
        "coordinates_sha256": study.canonical(indices),
        "output_counts": {key: len(value) for key, value in indices.items()},
    }


def safe_export(path, case, reference=None, *, discard_duplicate=False):
    """Discard only a complete, validated, byte-identical duplicate of a reference."""
    indices = corpus.expression_indices(path.read_text())
    require(
        indices == case["output_indices"],
        "missing, shifted, duplicated or aliased safe output coordinate",
    )
    result = expression_observation(path)
    if reference is not None:
        require(
            Path(reference["path"]).resolve() != path.resolve(),
            "reference aliases temporary export",
        )
        require(
            expression_observation(Path(reference["path"])) == reference["observation"],
            "retained export reference changed",
        )
        require(
            result == reference["observation"],
            "safe expression bytes differ from retained reference",
        )
        if discard_duplicate:
            path.unlink()
    return {
        "path": str(path),
        "observation": result,
        "validated_complete": True,
        "duplicate_removed": bool(reference and discard_duplicate),
        "reference": reference["path"] if reference else None,
    }


def kill_group(process):
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def capture(argv, directory, *, timeout=TIMEOUT):
    """Stream complete raw logs and kill wrapper and verifier as one process group."""
    resources = directory / "resources.txt"
    require(not resources.exists(), "resource artifact already exists")
    wrapped = [
        str(TIME),
        "-f",
        "max_rss_kib=%M\nuser_seconds=%U\nsystem_seconds=%S",
        "-o",
        str(resources),
        *argv,
    ]
    started = time.perf_counter()
    process = subprocess.Popen(
        wrapped, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True
    )
    selector = selectors.DefaultSelector()
    buffers = {"stdout": b"", "stderr": b""}
    candidates = {"complete_trace": None, "certified_prefix": None}
    timed_out = False
    with (
        (directory / "stdout").open("wb") as out,
        (directory / "stderr").open("wb") as err,
    ):
        files = {"stdout": out, "stderr": err}
        for name, stream in (("stdout", process.stdout), ("stderr", process.stderr)):
            selector.register(stream, selectors.EVENT_READ, name)
        try:
            while selector.get_map() or process.poll() is None:
                remaining = timeout - (time.perf_counter() - started)
                if remaining <= 0:
                    timed_out = True
                    kill_group(process)
                    break
                for key, _ in selector.select(min(remaining, 0.1)):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    received = time.perf_counter() - started
                    name = key.data
                    files[name].write(chunk)
                    buffers[name] += chunk
                    lines = buffers[name].split(b"\n")
                    buffers[name] = lines.pop()
                    if name == "stdout":
                        for raw in lines:
                            line = raw.decode(errors="replace")
                            if (
                                line == study.MARKER
                                and candidates["certified_prefix"] is None
                            ):
                                candidates["certified_prefix"] = received
                            if (
                                re.fullmatch(
                                    r"  AMD memory-conflict freedom \([^\n]*\)\s+FAIL\s*",
                                    line,
                                )
                                and candidates["complete_trace"] is None
                            ):
                                candidates["complete_trace"] = received
            # After timeout, drain the pipes only after killing the entire group.
            if timed_out:
                for key in list(selector.get_map().values()):
                    tail = key.fileobj.read()
                    if tail:
                        files[key.data].write(tail)
            process.wait(timeout=5)
        finally:
            # Also remove any surviving descendant after a wrapper exits early.
            kill_group(process)
            if process.poll() is None:
                process.wait()
            selector.close()
            process.stdout.close()
            process.stderr.close()
    seconds = time.perf_counter() - started
    usage = {}
    if resources.exists():
        fields = re.findall(
            r"^(max_rss_kib|user_seconds|system_seconds)=([\d.]+)$",
            resources.read_text(),
            re.M,
        )
        if len(fields) == 3 and len(dict(fields)) == 3:
            usage = {key: float(value) for key, value in fields}
    return {
        "command": argv,
        "wrapped_command": wrapped,
        "returncode": process.returncode,
        "timed_out": timed_out,
        "seconds": seconds,
        "diagnostic_candidates_seconds": candidates,
        "usage": usage,
    }


def execute(
    binary,
    case,
    assembly,
    directory,
    *,
    enabled=False,
    export=False,
    verify=False,
    reference=None,
    discard_duplicate=False,
):
    directory.mkdir(parents=True)
    argv = study.command(
        binary, case, assembly, directory, enabled=enabled, export=export, verify=verify
    )
    configuration = None
    if "--config" in argv:
        path = Path(argv[argv.index("--config") + 1])
        configuration = {
            "path": str(path),
            "sha256": sha(path),
            "value": json.loads(path.read_text()),
        }
        original = json.loads((ROOT / case["launch_config"]).read_text())
        require(
            configuration["value"]
            == ({**original, "early_memory_conflicts": True} if enabled else original),
            "derived launch altered original fields",
        )
    input_hashes = snapshots(
        [binary, assembly] + ([Path(configuration["path"])] if configuration else [])
    )
    stage = capture(argv, directory)
    unchanged(input_hashes)
    stdout, stderr = (
        (directory / "stdout").read_text(),
        (directory / "stderr").read_text(),
    )
    expressions = directory / "outputs.vexpr"
    classification = study.classify(
        stage["returncode"],
        stdout,
        stderr,
        timed_out=stage["timed_out"],
        expected_outputs=case["expected_outputs"] if verify else case["output_indices"],
        expressions=expressions.read_text() if expressions.exists() else None,
        verify=verify,
    )
    if re.search(r"^Usage:|^error:", stdout + "\n" + stderr, re.M):
        classification.update(
            status="contract_error", detected=False, detection_mode=None
        )
    errors = []
    usage = stage["usage"]
    if (
        set(usage) != {"max_rss_kib", "user_seconds", "system_seconds"}
        or usage["max_rss_kib"] <= 0
    ):
        errors.append("missing or nonpositive per-process resource observation")
    export_record = None
    if (
        export
        and case["expectation"] == "safe"
        and classification["status"] == "graph_verified"
    ):
        try:
            export_record = safe_export(
                expressions, case, reference, discard_duplicate=discard_duplicate
            )
        except (OSError, ValueError) as error:
            errors.append(str(error))
    try:
        observation = (
            expression_observation(expressions)
            if export_record is None or not export_record["duplicate_removed"]
            else export_record["observation"]
        )
    except ValueError as error:
        observation = None
        errors.append(str(error))
    mode = classification["detection_mode"]
    detection = (
        stage["diagnostic_candidates_seconds"].get(mode)
        if classification["detected"]
        else None
    )
    if classification["detected"] and detection is None:
        errors.append("validated rejection lacks observed first diagnostic")
    counts = re.findall(r"^  time: [\d.]+s\s+instructions: (\d+)\b", stdout, re.M)
    prefix = re.findall(
        r"^  prefix: instructions=(\d+) amd_records=(\d+) graph_events=(\d+)$",
        stdout,
        re.M,
    )
    if mode == "certified_prefix":
        counts = [prefix[0][0]] if len(prefix) == 1 else []
    if classification["status"] in {
        "graph_verified",
        "ordinary_rejection",
        "certified_rejection",
    } and (len(counts) != 1 or int(counts[0]) <= 0):
        errors.append("missing or ambiguous executed instruction count")
    return {
        **stage,
        **classification,
        "enabled": enabled,
        "launch_configuration": configuration,
        "time_to_detection_seconds": detection,
        "false_positive": case["expectation"] == "safe" and classification["detected"],
        "unsafe_acceptance": case["expectation"] == "hazard"
        and classification["graph_accepted"],
        "measurement_errors": errors,
        "diagnostics_sha256": diagnostics(stdout, stderr),
        "executed_instructions": int(counts[0]) if len(counts) == 1 else None,
        "prefix_counts": list(map(int, prefix[0])) if len(prefix) == 1 else None,
        "expressions": observation,
        "export": export_record,
        "stdout_sha256": sha(directory / "stdout"),
        "stderr_sha256": sha(directory / "stderr"),
        "resources_sha256": sha(directory / "resources.txt")
        if (directory / "resources.txt").exists()
        else None,
        "directory": str(directory),
    }


def qualified(case, row, *, specification=None):
    if row["measurement_errors"]:
        return False
    if case["expectation"] == "hazard":
        return row["detected"] and row["status"] in {
            "ordinary_rejection",
            "certified_rejection",
        }
    return (
        row["status"] == "graph_verified"
        and specification is not None
        and specification["status"] == "spec_verified"
    )


def signature(row):
    return {
        key: row[key]
        for key in (
            "status",
            "detected",
            "diagnostics_sha256",
            "executed_instructions",
            "expressions",
        )
    }


def invariance(left, right):
    if left["timed_out"] or right["timed_out"]:
        return {
            "comparable": False,
            "passed": None,
            "reason": "resource-censored execution; elapsed values/partial timeout transcripts are not equality controls",
        }
    return {
        "comparable": True,
        "passed": signature(left) == signature(right),
        "reason": "exact default-mode diagnostics, instruction count and actual expression bytes/coordinate counts; hazard exports are not a correct-output proof",
    }


def preserved_sample(case, row, directory):
    stdout, stderr = (
        (directory / "analyze.stdout").read_text(),
        (directory / "analyze.stderr").read_text(),
    )
    expressions = directory / "outputs.vexpr"
    return {
        **row["analysis"],
        "timed_out": row["analyze"]["timed_out"],
        "diagnostics_sha256": diagnostics(stdout, stderr),
        "executed_instructions": next(
            (
                int(value)
                for value in re.findall(
                    r"^  time: [\d.]+s\s+instructions: (\d+)\b", stdout, re.M
                )
            ),
            None,
        ),
        "expressions": expression_observation(expressions),
    }


def common_setup(args):
    document = study.load_cases()
    require(sha(study.MANIFEST) == MANIFEST_SHA, "frozen manifest changed")
    original = baseline_report(args.baseline_report, document)
    identity = identities(args)
    frozen = inputs(document, args)
    return document, original, identity, frozen


def snapshot_harness(output, frozen):
    directory = output / "harness"
    directory.mkdir()
    for path in frozen:
        source = Path(path)
        if source.is_relative_to(ROOT) and source.suffix in {".py", ".json", ".md"}:
            destination = directory / source.relative_to(ROOT)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(source.read_bytes())
    write(directory / "input-sha256.json", frozen)


def bind_sample(frozen, sample):
    """Bind retained raw observations before they are consumed by a later phase."""
    if "directory" not in sample:
        return  # Original safe baseline observations have their own pinned inventory.
    directory = Path(sample["directory"])
    for name, field in (
        ("stdout", "stdout_sha256"),
        ("stderr", "stderr_sha256"),
        ("resources.txt", "resources_sha256"),
    ):
        if sample[field] is not None:
            path = directory / name
            require(sha(path) == sample[field], "retained process observation changed")
            frozen[str(path)] = sample[field]
    config = sample["launch_configuration"]
    if config is not None:
        require(
            sha(Path(config["path"])) == config["sha256"], "retained launch changed"
        )
        frozen[config["path"]] = config["sha256"]
    expression = directory / "outputs.vexpr"
    if sample["expressions"] is not None and expression.exists():
        require(
            sha(expression) == sample["expressions"]["sha256"],
            "retained expression changed",
        )
        frozen[str(expression)] = sample["expressions"]["sha256"]


def prepare(args):
    document, original, identity, frozen = common_setup(args)
    output = fresh(args.output)
    snapshot_harness(output, frozen)
    rows = {row["case"]: row for row in original["results"]}
    results = []
    for case in development(document):
        directory = output / case["id"]
        directory.mkdir()
        assembly = directory / "complete-module.s"
        assembly.write_bytes(
            study.changed_source(
                next(w for w in document["workloads"] if w["id"] == case["workload"]),
                case,
            )
        )
        require(
            sha(assembly) == case["materialized_assembly_sha256"],
            "changed materialized module",
        )
        frozen[str(assembly)] = sha(assembly)
        baseline_directory = args.baseline_report.parent / case["id"]
        # Safe originals already have immutable full exports. Hazard exports need
        # separate untimed controls, including unqualified cases where feasible.
        left = (
            preserved_sample(case, rows[case["id"]], baseline_directory)
            if case["expectation"] == "safe"
            else execute(
                args.baseline_binary,
                case,
                assembly,
                directory / "baseline-off-export",
                export=True,
            )
        )
        variants = {
            role: execute(
                args.candidate_binary,
                case,
                assembly,
                directory / role,
                enabled=role == "candidate",
                export=case["expectation"] == "safe" or role == "candidate-off",
            )
            for role in ROLES[1:]
        }
        proofs = {}
        if case["expectation"] == "safe":
            for role in ROLES[1:]:
                proofs[role] = execute(
                    args.candidate_binary,
                    case,
                    assembly,
                    directory / (role + "-specification"),
                    enabled=role == "candidate",
                    verify=True,
                )
        control = invariance(left, variants["candidate-off"])
        baseline_eligible = case["id"] in original["timing_eligible"]
        retained = {
            role: qualified(case, sample, specification=proofs.get(role))
            for role, sample in variants.items()
        }
        references = {}
        if case["expectation"] == "safe":
            for role in ROLES:
                path = (
                    baseline_directory / "outputs.vexpr"
                    if role == "baseline"
                    else directory / role / "outputs.vexpr"
                )
                if path.is_file():
                    try:
                        references[role] = safe_export(path, case)
                        frozen[str(path)] = references[role]["observation"]["sha256"]
                    except ValueError:
                        pass  # Preserve unmatched/nonqualifying files, never delete.
        result = {
            "case": case["id"],
            "family": next(
                w["family"]
                for w in document["workloads"]
                if w["id"] == case["workload"]
            ),
            "category": case["category"],
            "expectation": case["expectation"],
            "baseline": rows[case["id"]],
            "baseline_export_control": left,
            "variants": variants,
            "specifications": proofs,
            "baseline_timing_eligible": baseline_eligible,
            "candidate_retains_baseline_qualification": all(retained.values())
            if baseline_eligible
            else None,
            "default_off_invariance": control,
            "references": references,
            "assembly": str(assembly),
            "assembly_sha256": sha(assembly),
        }
        results.append(result)
        unchanged(frozen)
        print(
            case["id"],
            {role: value["status"] for role, value in variants.items()},
            "baseline-eligible=" + str(baseline_eligible),
            flush=True,
        )
        write(output / "checkpoint.json", {"results": results})
    math_controls = []
    for control in document["mathematical_controls"]:
        case = next(
            c
            for c in development(document)
            if c["workload"] == control["workload"] and c["expectation"] == "safe"
        )
        case["spec"] = control["spec"]
        assembly = output / case["id"] / "complete-module.s"
        for role in ROLES[1:]:
            value = execute(
                args.candidate_binary,
                case,
                assembly,
                output / control["id"] / role,
                enabled=role == "candidate",
                verify=True,
            )
            math_controls.append({"case": control["id"], "role": role, "result": value})
    unchanged(frozen)
    for row in results:
        for sample in (
            [row["baseline_export_control"]]
            + list(row["variants"].values())
            + list(row["specifications"].values())
        ):
            bind_sample(frozen, sample)
    for control in math_controls:
        bind_sample(frozen, control["result"])
    report = {
        "schema_version": 1,
        "phase": "paired_functional_preflight",
        "harness_revision": subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip(),
        "identity": identity,
        "input_sha256": frozen,
        "baseline_report_sha256": BASELINE_SHA,
        "protocol": document["protocol"],
        "heldouts_executed": 0,
        "timing_eligible": original["timing_eligible"],
        "results": results,
        "mathematical_controls": math_controls,
        "functional": functional_summary(results, math_controls),
        "scope": "Functional preflight with descriptive process observations only; not the31-repeat latency comparison. All40 configurations and every miss remain visible.",
    }
    write(output / "report.json", report)


def functional_summary(rows, math_controls):
    """Keep every baseline-fixed obligation; never filter a failing candidate."""
    retained = all(
        row["candidate_retains_baseline_qualification"] is not False for row in rows
    )
    invariant = all(
        row["default_off_invariance"]["passed"] is not False
        and (
            not row["baseline_timing_eligible"]
            or row["default_off_invariance"]["passed"] is True
        )
        for row in rows
    )
    no_false = all(
        not sample["false_positive"] and not sample["unsafe_acceptance"]
        for row in rows
        for sample in row["variants"].values()
    )
    output_invariance = all(
        not row["baseline_timing_eligible"]
        or row["expectation"] != "safe"
        or row["baseline_export_control"]["expressions"]
        == row["variants"]["candidate"]["expressions"]
        for row in rows
    )
    math_ok = len(math_controls) == 4 and all(
        c["result"]["status"] == "mathematical_refutation"
        and not c["result"]["measurement_errors"]
        for c in math_controls
    )
    process_contracts = all(
        sample["status"] not in {"contract_error", "process_error"}
        and (not sample["measurement_errors"] or sample["timed_out"])
        for row in rows
        for sample in list(row["variants"].values())
        + list(row["specifications"].values())
    )
    new = [
        row
        for row in rows
        if row["expectation"] == "hazard"
        and not row["baseline_timing_eligible"]
        and row["variants"]["candidate"]["status"] == "certified_rejection"
        and not row["variants"]["candidate"]["measurement_errors"]
        and row["category"] != "synthetic_unsupported_tail"
    ]
    all_certified = [
        row
        for row in rows
        if row["variants"]["candidate"]["status"] == "certified_rejection"
        and not row["variants"]["candidate"]["measurement_errors"]
        and row["category"] != "synthetic_unsupported_tail"
    ]
    counts = {}
    for role in ROLES[1:]:
        counts[role] = {
            "statuses": dict(Counter(row["variants"][role]["status"] for row in rows)),
            "safe_graphs": sum(
                row["expectation"] == "safe"
                and row["variants"][role]["status"] == "graph_verified"
                for row in rows
            ),
            "safe_complete_proofs": sum(
                row["expectation"] == "safe"
                and qualified(
                    {"expectation": "safe"},
                    row["variants"][role],
                    specification=row["specifications"][role],
                )
                for row in rows
            ),
            "core_detections": sum(
                row["expectation"] == "hazard"
                and row["category"] != "synthetic_unsupported_tail"
                and row["variants"][role]["detected"]
                for row in rows
            ),
            "tail_detections": sum(
                row["category"] == "synthetic_unsupported_tail"
                and row["variants"][role]["detected"]
                for row in rows
            ),
        }
    return {
        "configurations": len(rows),
        "safe_denominator": 18,
        "core_hazard_denominator": 20,
        "synthetic_tail_denominator": 2,
        "counts": counts,
        "baseline_qualifications_retained": retained,
        "default_off_invariance": invariant,
        "safe_enabled_output_invariance": output_invariance,
        "no_false_outcomes": no_false,
        "mathematical_controls": math_ok,
        "process_contracts_valid": process_contracts,
        "correctness_gates_pass": retained
        and invariant
        and output_invariance
        and no_false
        and math_ok
        and process_contracts,
        "new_coverage_families": sorted({row["family"] for row in new}),
        "new_complex_coverage_families": sorted(
            {row["family"] for row in new if row["case"].startswith("memory-wide-")}
        ),
        "certified_families": sorted({row["family"] for row in all_certified}),
        "certified_complex_families": sorted(
            {
                row["family"]
                for row in all_certified
                if row["case"].startswith("memory-wide-")
            }
        ),
        "new_coverage": [
            {
                "case": row["case"],
                "baseline_status": row["baseline"]["status"],
                "candidate_status": row["variants"]["candidate"]["status"],
                "observed_certified_seconds": row["variants"]["candidate"][
                    "time_to_detection_seconds"
                ],
                "baseline_ratio": None,
            }
            for row in new
        ],
    }


def sample_success(case, sample):
    return not sample["measurement_errors"] and (
        sample["status"] == "graph_verified"
        if case["expectation"] == "safe"
        else sample["detected"] and sample["time_to_detection_seconds"] is not None
    )


def timing_summary(cases, samples, functional, protocol):
    expected = {
        (case["id"], role, repeat)
        for case in cases
        for role in ("baseline", "candidate")
        for repeat in range(32)
    }
    actual = [(s["case"], s["role"], s["repeat"]) for s in samples]
    require(
        len(actual) == len(set(actual)) and set(actual) == expected,
        "missing or duplicate paired samples",
    )
    rows = []
    for case in cases:
        selected = {
            role: sorted(
                (s for s in samples if s["case"] == case["id"] and s["role"] == role),
                key=lambda s: s["repeat"],
            )
            for role in ("baseline", "candidate")
        }
        success = all(
            sample_success(case, s) for group in selected.values() for s in group
        )
        metrics = {}
        for role, group in selected.items():
            times = [s["seconds"] for s in group if s["repeat"] > 0]
            detections = [
                s["time_to_detection_seconds"]
                for s in group
                if s["repeat"] > 0
                and s["detected"]
                and s["time_to_detection_seconds"] is not None
            ]
            metrics[role] = {
                "first": group[0],
                "repeats": 31,
                "statuses": dict(Counter(s["status"] for s in group)),
                "process_median_seconds": statistics.median(times),
                "process_p95_seconds": statistics.percentile95(times),
                "detected_repeats": len(detections),
                "detection_median_seconds": statistics.median(detections)
                if detections
                else None,
                "detection_p95_seconds": statistics.percentile95(detections)
                if detections
                else None,
                "max_rss_kib": max(
                    (s["usage"].get("max_rss_kib", 0) for s in group), default=0
                ),
                "timeouts": sum(s["timed_out"] for s in group),
                "measurement_errors": sum(bool(s["measurement_errors"]) for s in group),
            }
        overhead = None
        left, right = metrics["baseline"], metrics["candidate"]
        if case["expectation"] == "safe":
            limits = protocol["safe_overhead_limits"]
            overhead = {
                "median": success
                and right["process_median_seconds"]
                <= left["process_median_seconds"] * limits["median_factor"]
                + limits["median_add_seconds"],
                "p95": success
                and right["process_p95_seconds"]
                <= left["process_p95_seconds"] * limits["p95_factor"]
                + limits["p95_add_seconds"],
                "rss": success
                and right["max_rss_kib"]
                <= left["max_rss_kib"]
                + max(
                    left["max_rss_kib"] * limits["rss_fraction"], limits["rss_add_kib"]
                ),
            }
        endpoint = (
            "seconds" if case["expectation"] == "safe" else "time_to_detection_seconds"
        )
        pairs = [
            (left_sample[endpoint], right_sample[endpoint])
            for left_sample, right_sample in zip(
                selected["baseline"][1:], selected["candidate"][1:]
            )
        ]
        rows.append(
            {
                "case": case["id"],
                "baseline_eligible": True,
                "expectation": case["expectation"],
                "primary": case["primary_latency"],
                "all_samples_qualified": success,
                "metrics": metrics,
                "overhead_gates": overhead,
                "median_ratio_interval": statistics.paired_ratio_interval(
                    pairs, seed=20261031
                )
                if success
                else None,
            }
        )
    correctness = functional["correctness_gates_pass"] and all(
        row["all_samples_qualified"] for row in rows
    )
    overhead_ok = all(
        row["overhead_gates"] is None or all(row["overhead_gates"].values())
        for row in rows
    )
    coverage = (
        len(functional["new_coverage_families"]) >= 4
        and len(functional["new_complex_coverage_families"]) >= 2
    )
    return {
        "baseline_fixed_cases": len(rows),
        "successful_paired_comparisons": sum(
            row["all_samples_qualified"] for row in rows
        ),
        "failed_candidate_or_baseline_qualifiers": [
            row["case"] for row in rows if not row["all_samples_qualified"]
        ],
        "cases": rows,
        "correctness_gates_pass": correctness,
        "overhead_gates_pass": overhead_ok,
        "additional_coverage_gate_pass": coverage,
        "adoption_gates_pass": correctness and overhead_ok and coverage,
        "primary_qualification_failures": sorted(
            study.PRIMARIES - {c["id"] for c in cases}
        ),
    }


def compare(args):
    document, original, identity, frozen = common_setup(args)
    preflight_path = args.preflight.resolve(strict=True)
    require(
        sha(preflight_path) == args.preflight_sha256,
        "preflight report changed from reviewed digest",
    )
    preflight = json.loads(preflight_path.read_text())
    require(
        preflight["phase"] == "paired_functional_preflight"
        and preflight["identity"] == identity,
        "preflight source/build identity differs",
    )
    require(
        preflight["baseline_report_sha256"] == BASELINE_SHA
        and preflight["timing_eligible"] == original["timing_eligible"],
        "preflight eligibility differs",
    )
    require(
        len(preflight["results"]) == 40
        and {r["case"] for r in preflight["results"]}
        == {c["id"] for c in development(document)},
        "preflight case set differs",
    )
    require(
        preflight["functional"]
        == functional_summary(preflight["results"], preflight["mathematical_controls"]),
        "preflight gates differ from recorded outcomes",
    )
    unchanged(preflight["input_sha256"])
    output = fresh(args.output)
    frozen[str(preflight_path)] = sha(preflight_path)
    snapshot_harness(output, frozen)
    selected = [
        c for c in development(document) if c["id"] in original["timing_eligible"]
    ]
    controls = {row["case"]: row for row in preflight["results"]}
    for case in selected:
        control = controls[case["id"]]
        require(
            sha(Path(control["assembly"])) == case["materialized_assembly_sha256"],
            "preflight module changed",
        )
        frozen[control["assembly"]] = control["assembly_sha256"]
        if case["expectation"] == "safe":
            for role in ("baseline", "candidate"):
                reference = control["references"].get(role)
                require(
                    reference is not None
                    and expression_observation(Path(reference["path"]))
                    == reference["observation"],
                    "missing or stale safe preflight reference",
                )
                frozen[reference["path"]] = reference["observation"]["sha256"]
    rng = random.Random(document["protocol"]["seed"])
    samples = []
    before = {
        "context": statistics.runtime_context(),
        "load_average": list(os.getloadavg()),
    }
    for repeat in range(32):
        order = list(selected)
        rng.shuffle(order)
        for case in order:
            roles = ["baseline", "candidate"]
            rng.shuffle(roles)
            for role in roles:
                control = controls[case["id"]]
                reference = control["references"].get(role)
                value = execute(
                    args.baseline_binary
                    if role == "baseline"
                    else args.candidate_binary,
                    case,
                    Path(control["assembly"]),
                    output / case["id"] / f"{repeat:02d}-{role}",
                    enabled=role == "candidate",
                    export=case["expectation"] == "safe",
                    reference=reference,
                    discard_duplicate=True,
                )
                samples.append(
                    {"case": case["id"], "role": role, "repeat": repeat, **value}
                )
                unchanged(
                    {
                        str(args.baseline_binary): identity["builds"]["baseline"][
                            "binary_sha256"
                        ],
                        str(args.candidate_binary): identity["builds"]["candidate"][
                            "binary_sha256"
                        ],
                        str(Path(control["assembly"])): control["assembly_sha256"],
                    }
                )
                print(repeat, case["id"], role, value["status"], flush=True)
                write(output / "checkpoint.json", {"samples": samples})
        unchanged(frozen)
    after = {
        "context": statistics.runtime_context(),
        "load_average": list(os.getloadavg()),
    }
    report = {
        "schema_version": 1,
        "phase": "paired_development_measurement",
        "identity": identity,
        "input_sha256": frozen,
        "preflight_sha256": sha(preflight_path),
        "heldouts_executed": 0,
        "protocol": document["protocol"],
        "runtime_before": before,
        "runtime_after": after,
        "measurement_scope": "Parent-observed whole-process and first validated diagnostic wall time; GNU-time per-process maximum RSS. No internal-stage RSS attribution or asymptotic memory claim. The first process is separate from31 OS-warm repetitions; no cache flushing or CPU-affinity change.",
        "functional": preflight["functional"],
        "samples": samples,
        "comparison": timing_summary(
            selected, samples, preflight["functional"], document["protocol"]
        ),
    }
    unchanged(frozen)
    write(output / "report.json", report)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="mode", required=True)
    checker = commands.add_parser("check")
    checker.add_argument("--baseline-report", type=Path)
    for name in ("prepare", "compare"):
        command = commands.add_parser(name)
        command.add_argument("--baseline-report", type=Path, required=True)
        command.add_argument("--baseline-binary", type=Path, required=True)
        command.add_argument("--baseline-build-record", type=Path, required=True)
        command.add_argument("--candidate-binary", type=Path, required=True)
        command.add_argument("--candidate-build-record", type=Path, required=True)
        command.add_argument("--candidate-revision", required=True)
        command.add_argument("--output", type=Path, required=True)
        if name == "compare":
            command.add_argument("--preflight", type=Path, required=True)
            command.add_argument("--preflight-sha256", required=True)
    args = parser.parse_args()
    try:
        if args.mode == "check":
            document = study.load_cases()
            require(sha(study.MANIFEST) == MANIFEST_SHA, "frozen manifest changed")
            if args.baseline_report:
                baseline_report(args.baseline_report.resolve(strict=True), document)
            print(
                json.dumps(
                    {
                        "development": len(development(document)),
                        "heldouts_executed": 0,
                        "baseline_report_sha256": BASELINE_SHA,
                        "protocol_sha256": sha(HERE / "protocol.md"),
                    },
                    indent=2,
                )
            )
        else:
            for key in (
                "baseline_report",
                "baseline_binary",
                "baseline_build_record",
                "candidate_binary",
                "candidate_build_record",
            ):
                setattr(args, key, getattr(args, key).resolve(strict=True))
            (prepare if args.mode == "prepare" else compare)(args)
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.SubprocessError,
    ) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
