#!/usr/bin/env python3
"""Freeze and collect the declared native input-materialization comparison.

Host preparation is separate from qualification and paired collection. See
protocol.md: neither a successful process nor a matching graph proves equations.
"""

from __future__ import annotations

import argparse
import copy
import importlib.util
import json
import math
import os
from pathlib import Path
import random
import re
import selectors
import shutil
import statistics
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PARENT = "c256801df19928b3c24cbb62ebc40a4c8f9f4dc1"
BASELINE_SHA = "a774984789ee54e93797906fe5b51d37faf0c18f019aeece5323fdff1a932f76"
TIME = Path("/usr/bin/time")
TIMEOUT = 60
COMPARATOR_SHA = "38fbcbd397bbd95bb2fe3240c08d1b81e222db4f8bdb2ffcb0c086394b769b71"
COMPARATOR_TESTS_SHA = (
    "416616e004ad06871cb0bea1d1c029bf0b3fc82f384c736043d6d7a74862ed18"
)
RESERVE = 2**31
LOG_LIMIT = 8 * 2**20
COLLECTION_LOG_LIMIT = 128 * 2**20
FRAME = re.compile(
    r"^  instruction=EventId\((\d+)\) issue=EventId\((\d+)\) wave=(\d+) "
    r"earlier_thread=ThreadIx\((\d+)\) later_thread=ThreadIx\((\d+)\)$",
    re.M,
)


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


bench = load_module(
    "lazy_input_generic_capture", HERE.parent / "memory-conflicts-study/benchmark.py"
)
study, corpus = bench.study, bench.study.corpus
require, sha = corpus.require, corpus.sha


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def fresh(path):
    require(
        not path.exists() and not path.resolve().is_relative_to(ROOT),
        "output must be fresh and outside repository",
    )
    path.mkdir(parents=True)
    return path.resolve()


def selection():
    value = json.loads((HERE / "selection.json").read_text())
    rows = value["cases"]
    require(
        value["source_parent"] == PARENT
        and value["baseline_binary_sha256"] == BASELINE_SHA,
        "baseline identity changed",
    )
    require(
        value["seed"] == 20261031
        and value["repeats"] == 5
        and value["timeout_seconds"] == TIMEOUT,
        "fixed budget changed",
    )
    require(
        len(rows) == len({r["id"] for r in rows}) == 28
        and sum(r["expectation"] == "safe" for r in rows) == 14
        and sum(r["primary"] for r in rows) == 3,
        "population changed",
    )
    return value


def full_gemm(case, definition):
    """New derived allocation contract; original instructions and spec stay intact."""
    case = copy.deepcopy(case)
    case["id"] = definition["id"]
    case["grid"] = [16, 16, 1]
    for array in case["arrays"]:
        if array["name"] in {"a", "b"}:
            array["length"] = 4096 * 4096
            array["base_address"] = {"a": 0x10000000, "b": 0x20000000}[array["name"]]
        else:
            require(
                re.fullmatch(r"out\d{3}", array["name"]) is not None,
                "unexpected GEMM output",
            )
            array["base_address"] = 0x30000000 + int(array["name"][3:]) * 8192
    case.pop("launch_config", None)
    case.pop("launch_config_sha256", None)
    case["primary_latency"] = definition["primary"]
    case["new_contract"] = True
    case["contract_kind"] = "gemm_full_inputs"
    collision = {
        "source_batch": 133,
        "executed_instructions": 4225,
        "wave": 0,
        "physical_threads": [0, 1],
        "space": "Shared",
        "byte_address": 0,
    }
    if case.get("expectation") == "hazard":
        case["safe_counterpart"] = (
            definition["id"].removesuffix("-inserted-collision") + "-safe"
        )
        case["source_ground_truth_first_collision"] = collision
    return case


def full_attention(case, definition):
    """Full physical query inputs, unchanged selected-workgroup equations."""
    case = copy.deepcopy(case)
    selected = selection()["new_attention"]
    original_spec = ROOT / selected["template_spec"]
    original_launch = ROOT / selected["template_launch"]
    spec, launch = ROOT / selected["spec"], ROOT / selected["launch"]
    text = original_spec.read_bytes()
    require(text.count(b"array q[Q,D];") == 1, "attention spec template changed")
    require(
        spec.read_bytes() == text.replace(b"array q[Q,D];", b"array q[T,D];"),
        "attention equations changed",
    )
    require(
        sha(spec) == selected["spec_sha256"]
        and sha(launch) == selected["launch_sha256"],
        "derived attention input changed",
    )
    expected = json.loads(original_launch.read_text())
    observed = json.loads(launch.read_text())
    for array in expected["arrays"]:
        array["base"] = selected["array_bases"][array["name"]]
        if array["name"] == "q":
            array["len"] = 65536
    expected["description"] = observed["description"]
    require(
        expected == observed, "attention launch changed beyond declared allocations"
    )
    case.update(
        id=definition["id"],
        primary_latency=definition["primary"],
        new_contract=True,
        contract_kind="attention_full_query",
        spec_template=selected["template_spec"],
        spec_template_sha256=sha(original_spec),
        launch_template=selected["template_launch"],
        launch_template_sha256=sha(original_launch),
        spec=selected["spec"],
        spec_sha256=sha(spec),
        launch_config=selected["launch"],
        launch_config_sha256=sha(launch),
    )
    case["original_shape"].update(query_rows=1024, selected_query_rows=128)
    case["logical_full_grid_output_elements"] = selected[
        "logical_full_grid_output_elements"
    ]
    case["configured_selected_output_elements"] = selected[
        "configured_selected_output_elements"
    ]
    for array in case["arrays"]:
        array["base_address"] = selected["array_bases"][array["name"]]
        if array["name"] == "q":
            array["length"] = 65536
    if case["expectation"] == "hazard":
        case["safe_counterpart"] = (
            definition["id"].removesuffix("-inserted-collision") + "-safe"
        )
        case["source_ground_truth_first_collision"] = {
            "source_batch": 82,
            "executed_instructions": 325,
            "wave": 0,
            "physical_threads": [0, 1],
            "space": "Shared",
            "byte_address": 0,
        }
    return case


def configuration(case):
    if case.get("launch_config"):
        result = json.loads((ROOT / case["launch_config"]).read_text())
    else:
        result = {
            "kernel": case["kernel"],
            "block": case["block"],
            "grid": case["grid"],
            "workgroup_id": case["workgroup"],
            "dynamic_shared_bytes": case.get("dynamic_shared_bytes", 0),
            "arrays": [
                {
                    "name": a["name"],
                    "base": a["base_address"],
                    "elem_width": a["element_size"],
                    "len": a["length"],
                    "kind": a["kind"],
                }
                for a in case["arrays"]
            ],
            "params": [
                {
                    v.split(":", 1)[0]: int(v.split(":", 1)[1], 0)
                    if v.startswith("int:")
                    else v.split(":", 1)[1]
                }
                for v in case["params"]
            ],
            "max_instructions": 2_000_000_000,
        }
    result["early_memory_conflicts"] = True
    return result


def prepare(args):
    selected = selection()
    require(
        sha(args.comparator) == COMPARATOR_SHA
        and sha(args.comparator_tests) == COMPARATOR_TESTS_SHA,
        "structural comparison authority changed",
    )
    require(
        not git("diff", PARENT, "--", "crates", "Cargo.toml", "Cargo.lock", ".cargo"),
        "host-study worktree changed production baseline",
    )
    identity = study.build_records.build_identity(
        args.baseline_build, PARENT, args.baseline
    )
    require(sha(args.baseline) == BASELINE_SHA, "not the frozen baseline executable")
    document = study.load_cases()
    require(
        sha(study.MANIFEST) == selected["original_study_manifest_sha256"],
        "original study manifest changed",
    )
    workloads = {w["id"]: w for w in document["workloads"]}
    cases = {c["id"]: c for c in document["cases"]}
    archived = json.loads(args.archived_plan.read_text())
    require(
        sha(args.archived_plan)
        == "42abaf77f355f0e909e4100abf8fc18192ead98b961c857ad6d4c171018732e2",
        "not the frozen archived reference plan",
    )
    old = {row["case"]["id"]: row for row in archived["cases"]}
    output = fresh(args.output)
    frozen, rows = {}, []
    for definition in selected["cases"]:
        source_case = cases[definition.get("template_case", definition["id"])]
        workload = workloads[source_case["workload"]]
        case = study.expanded_case(workload, source_case)
        if definition.get("contract_kind") == "attention_full_query":
            case = full_attention(case, definition)
        elif definition.get("contract_kind") == "gemm_full_inputs":
            case = full_gemm(case, definition)
        else:
            require(
                not definition.get("new_contract")
                and definition.get("contract_kind") is None,
                "unknown derived contract",
            )
            require(
                case == old[case["id"]]["case"], "existing selected contract changed"
            )
        inputs = [a for a in case["arrays"] if a["kind"] in {"in", "inout", "index"}]
        require(
            sum(a["length"] for a in inputs) == definition["input_elements"]
            and sum(a["length"] * a["element_size"] for a in inputs)
            == definition["input_bytes"],
            "input allocation mismatch",
        )
        directory = output / case["id"]
        directory.mkdir()
        assembly = directory / "complete-module.s"
        data = study.changed_source(workload, source_case)
        require(
            study.digest(data) == source_case["materialized_assembly_sha256"],
            "whole module mutation changed",
        )
        assembly.write_bytes(data)
        config = directory / "enabled.launch.json"
        write(config, configuration(case))
        for path in [
            assembly,
            config,
            *(ROOT / case[k] for k in ("source", "assembly", "spec")),
        ]:
            frozen[str(path)] = sha(path)
        if case.get("launch_config"):
            path = ROOT / case["launch_config"]
            frozen[str(path)] = sha(path)
        for key in ("spec_template", "launch_template"):
            if key in case:
                path = ROOT / case[key]
                frozen[str(path)] = sha(path)
        template_id = definition.get("template_case", case["id"])
        expected_reference = (
            copy.deepcopy(old[template_id]["expected"]) if template_id in old else None
        )
        if (
            definition.get("contract_kind") == "attention_full_query"
            and case["expectation"] == "hazard"
        ):
            old_stdout = (
                Path(old[template_id]["reference_configuration"]["path"]).parent
                / "stdout"
            )
            require(
                sha(old_stdout) == archived["input_sha256"][str(old_stdout)],
                "archived attention stdout changed",
            )
            archived_frames = [
                list(map(int, frame)) for frame in FRAME.findall(old_stdout.read_text())
            ]
            require(
                archived_frames == [[804, 805, 0, 0, 1]],
                "archived attention physical frame changed",
            )
            expected_reference["certificate_frame"] = archived_frames[0]
            frozen[str(old_stdout)] = sha(old_stdout)
        rows.append(
            {
                "definition": definition,
                "case": case,
                "assembly": str(assembly),
                "configuration": str(config),
                "expected_reference": expected_reference,
            }
        )
    for path in [
        Path(__file__),
        HERE / "test_collect.py",
        HERE / "selection.json",
        HERE / "protocol.md",
        Path(bench.__file__),
        Path(study.__file__),
        Path(corpus.__file__),
        Path(bench.statistics.__file__),
        ROOT / "ai_compiler_kernels/check_races.py",
        ROOT / "tests/gfx1250/measure_tensor_bounds.py",
        args.archived_plan,
        args.comparator,
        args.comparator_tests,
        args.baseline,
        args.baseline_build,
        TIME,
    ]:
        frozen[str(path.resolve())] = sha(path)
    write(
        output / "plan.json",
        {
            "schema_version": 1,
            "selection": selected,
            "selection_sha256": sha(HERE / "selection.json"),
            "protocol_sha256": sha(HERE / "protocol.md"),
            "structural_comparator": {
                "path": str(args.comparator.resolve()),
                "sha256": COMPARATOR_SHA,
                "tests_sha256": COMPARATOR_TESTS_SHA,
            },
            "baseline": {
                "binary": str(args.baseline.resolve()),
                "build": str(args.baseline_build.resolve()),
                "identity": identity,
            },
            "input_sha256": frozen,
            "cases": rows,
        },
    )
    print(
        "Prepared28 configurations;0 verifier processes; plan SHA256 "
        + sha(output / "plan.json")
    )


def checked_plan(path, expected):
    require(sha(path) == expected, "reviewed plan changed")
    plan = json.loads(path.read_text())
    require(plan["selection"] == selection(), "selection changed")
    bench.unchanged(plan["input_sha256"])
    return plan


def command(binary, row, *, verify=False, export=None):
    case = row["case"]
    argv = [
        str(binary),
        "--no-log-file",
        "verify" if verify else "analyze",
        row["assembly"],
    ]
    if verify:
        argv += [str(ROOT / case["spec"]), "--sample", "0"]
        for key, value in case["dimensions"].items():
            argv += ["--dim", f"{key}={value}"]
    else:
        argv += ["--print-outputs", "0"]
        if export:
            argv += ["--emit-exprs", str(export)]
    return argv + [
        "--backend",
        "amdgpu",
        "--target",
        case["target"],
        "--no-profile",
        "--config",
        row["configuration"],
    ]


def capture(argv, directory, *, log_limit=LOG_LIMIT):
    """Bounded raw logs; parent clocks both first marker and complete process."""
    require(
        shutil.disk_usage(directory).free >= RESERVE + log_limit,
        "disk reserve insufficient",
    )
    resources = directory / "resources.txt"
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
    for name, stream in (("stdout", process.stdout), ("stderr", process.stderr)):
        selector.register(stream, selectors.EVENT_READ, name)
    timed_out, overflow, count, first = False, False, 0, None
    pending = b""
    with (
        (directory / "stdout").open("wb") as out,
        (directory / "stderr").open("wb") as err,
    ):
        files = {"stdout": out, "stderr": err}
        try:
            while selector.get_map() or process.poll() is None:
                if not selector.get_map():
                    try:
                        process.wait(
                            timeout=max(
                                0.001, TIMEOUT - (time.perf_counter() - started)
                            )
                        )
                    except subprocess.TimeoutExpired:
                        timed_out = True
                        bench.kill_group(process)
                    break
                remaining = TIMEOUT - (time.perf_counter() - started)
                if remaining <= 0:
                    timed_out = True
                    bench.kill_group(process)
                    break
                for key, _ in selector.select(min(remaining, 0.1)):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    received = time.perf_counter() - started
                    files[key.data].write(chunk)
                    count += len(chunk)
                    if key.data == "stdout":
                        pending += chunk
                        lines = pending.split(b"\n")
                        pending = lines.pop()
                        if first is None and study.MARKER.encode() in lines:
                            first = received
                    if count > log_limit:
                        overflow = True
                        bench.kill_group(process)
                        break
                if overflow:
                    break
            if timed_out or overflow:
                for key in list(selector.get_map().values()):
                    tail = key.fileobj.read()
                    if tail:
                        files[key.data].write(tail)
                        count += len(tail)
            process.wait(timeout=5)
            completed_seconds = time.perf_counter() - started
        finally:
            bench.kill_group(process)
            if process.poll() is None:
                process.wait()
            selector.close()
            process.stdout.close()
            process.stderr.close()
    usage = {}
    if resources.exists():
        pairs = re.findall(
            r"^(max_rss_kib|user_seconds|system_seconds)=([\d.]+)$",
            resources.read_text(),
            re.M,
        )
        if len(pairs) == 3 and len(dict(pairs)) == 3:
            usage = {k: float(v) for k, v in pairs}
    return {
        "command": argv,
        "returncode": process.returncode,
        "timed_out": timed_out,
        "log_limit_exceeded": overflow,
        "seconds": completed_seconds,
        "raw_log_bytes": count,
        "first_marker_seconds": first,
        "usage": usage,
    }


def observe(record, row, stdout, stderr, reference=None, *, verify=False):
    case = row["case"]
    classification = study.classify(
        record["returncode"],
        stdout,
        stderr,
        timed_out=record["timed_out"],
        expected_outputs=case["expected_outputs"] if verify else case["output_indices"],
        verify=verify,
    )
    errors = []
    seconds = record["seconds"]
    if type(seconds) not in (int, float) or not math.isfinite(seconds) or seconds <= 0:
        errors.append("invalid parent completion time")
    marker = record["first_marker_seconds"]
    if marker is not None and not (
        type(marker) in (int, float)
        and math.isfinite(marker)
        and type(seconds) in (int, float)
        and math.isfinite(seconds)
        and 0 < marker <= seconds
    ):
        errors.append("invalid parent marker time")
    if record["log_limit_exceeded"]:
        errors.append("raw log limit exceeded")
    usage = record["usage"]
    if (
        set(usage) != {"max_rss_kib", "user_seconds", "system_seconds"}
        or any(not math.isfinite(x) or x < 0 for x in usage.values())
        or usage.get("max_rss_kib", 0) <= 0
    ):
        errors.append("missing or invalid resources")
    witness = [list(x) for x in study.WITNESS.findall(stdout)]
    frames = [list(map(int, x)) for x in FRAME.findall(stdout)]
    count_header = r"^Exec: " if verify else r"^  time: "
    counts = re.findall(count_header + r"[\d.]+s\s+instructions: (\d+)\b", stdout, re.M)
    prefixes = re.findall(
        r"^  prefix: instructions=(\d+) amd_records=(\d+) graph_events=(\d+)$",
        stdout,
        re.M,
    )
    if classification["detection_mode"] == "certified_prefix":
        if re.search(
            r'^  output |^Wrote output expressions |^VC check:|^EQUIVALENT|^NOT EQUIVALENT|^Output|^GRAPH VERIFICATION: VERIFIED|^VERDICT: ACCEPT|^volta-expr |^out "',
            stdout,
            re.M,
        ):
            errors.append(
                "certified prefix claims unavailable outputs or complete success"
            )
        counts = [prefixes[0][0]] if len(prefixes) == 1 else []
        if record["first_marker_seconds"] is None:
            errors.append("authenticated rejection lacks parent marker time")
        if len(frames) != 1 or len(witness) != 1 or len(prefixes) != 1:
            errors.append("missing or ambiguous certificate frame")
        else:
            instruction, issue, wave, earlier_thread, later_thread = frames[0]
            earlier, later = map(int, witness[0][2:])
            instructions, records, events = map(int, prefixes[0])
            wave_size = {"gfx950": 64, "gfx1250": 32}.get(case["target"], 0)
            threads = math.prod(case["block"])
            if not (
                wave_size > 0
                and 0 <= earlier_thread < threads
                and 0 <= later_thread < threads
                and earlier_thread // wave_size == later_thread // wave_size == wave
            ):
                errors.append("certificate physical lanes/wave differ from launch")
            if not (
                0 < instructions <= records <= events
                and instruction < issue < earlier < later < events
                and earlier_thread != later_thread
            ):
                errors.append("certificate frame order/counts are inconsistent")
    elif case["expectation"] == "hazard" and classification["detected"]:
        errors.append("expected certified rejection, not ordinary finding")
    if classification["graph_accepted"]:
        coverage = corpus.harness.array_coverage_error(
            stdout, {k: len(v) for k, v in case["output_indices"].items()}
        )
        if coverage:
            errors.append(coverage)
    good = (
        (
            classification["status"] == "spec_verified"
            if verify
            else classification["graph_accepted"]
        )
        if case["expectation"] == "safe"
        else classification["status"] == "certified_rejection"
    )
    if good and (len(counts) != 1 or int(counts[0]) <= 0):
        errors.append("missing or ambiguous instruction count")
    signature = {
        "status": classification["status"],
        "returncode": record["returncode"],
        "first_typed_witness": witness,
        "executed_instructions": int(counts[0]) if len(counts) == 1 else None,
        "prefix_counts": list(map(int, prefixes[0])) if len(prefixes) == 1 else None,
        "diagnostics_sha256": bench.diagnostics(stdout, stderr),
        "certificate_frame": frames[0] if len(frames) == 1 else None,
    }
    new_witness_audit = bool(
        case.get("new_contract")
        and case["expectation"] == "hazard"
        and classification["detected"]
    )
    if new_witness_audit:
        truth = case["ground_truth"]
        first = case["source_ground_truth_first_collision"]
        if not (
            truth["space"] == "Shared"
            and truth["constant_address"]["value"] == 0
            and len(witness) == 1
            and witness[0][:2] == [first["space"], str(first["byte_address"])]
            and len(frames) == 1
            and frames[0][2:] == [first["wave"], *first["physical_threads"]]
            and signature["executed_instructions"] == first["executed_instructions"]
            and signature["prefix_counts"] is not None
            and signature["prefix_counts"][0] == first["executed_instructions"]
            and all(0 <= int(e) < signature["prefix_counts"][2] for e in witness[0][2:])
        ):
            errors.append(
                "new contract witness differs from frozen source-ground-truth address/batch/frame"
            )
    if reference:
        keys = ["first_typed_witness", "executed_instructions", "prefix_counts"]
        if "certificate_frame" in reference:
            keys.append("certificate_frame")
        if any(signature[k] != reference[k] for k in keys):
            errors.append("first witness or execution contract differs from reference")
    if classification["detection_mode"] == "certified_prefix" and errors:
        classification.update(
            status="contract_error", detected=False, detection_mode=None
        )
        signature["status"] = "contract_error"
        good = False
    return {
        **record,
        **classification,
        "signature": signature,
        "new_contract_witness_audit_required": new_witness_audit,
        "new_coverage_credited": False,
        "measurement_errors": errors,
        "qualified": bool(good and not errors and not record["timed_out"]),
        "false_positive": case["expectation"] == "safe" and classification["detected"],
        "unsafe_acceptance": case["expectation"] == "hazard"
        and classification["graph_accepted"],
        "endpoint_seconds": (
            record["seconds"]
            if case["expectation"] == "safe"
            else record["first_marker_seconds"]
        )
        if good and not errors
        else None,
    }


def execute(binary, row, directory, reference=None, *, log_limit=LOG_LIMIT):
    directory.mkdir(parents=True)
    if log_limit <= 0:
        for name in ("stdout", "stderr"):
            (directory / name).write_bytes(b"")
        result = {
            "command": command(binary, row),
            "returncode": None,
            "timed_out": False,
            "log_limit_exceeded": True,
            "seconds": 0,
            "first_marker_seconds": None,
            "raw_log_bytes": 0,
            "usage": {},
            "not_run_reason": "aggregate raw log budget exhausted",
        }
    else:
        result = capture(command(binary, row), directory, log_limit=log_limit)
    stdout, stderr = [
        (directory / name).read_text(errors="replace") for name in ("stdout", "stderr")
    ]
    return {
        **observe(result, row, stdout, stderr, reference),
        "stdout_sha256": sha(directory / "stdout"),
        "stderr_sha256": sha(directory / "stderr"),
        "resources_sha256": sha(directory / "resources.txt")
        if (directory / "resources.txt").exists()
        else None,
    }


def qualify(args):
    plan = checked_plan(args.plan, args.reviewed_plan_sha256)
    if args.role == "baseline":
        require(
            args.binary.resolve() == Path(plan["baseline"]["binary"]),
            "baseline executable differs",
        )
        identity = plan["baseline"]["identity"]
        baseline = None
    else:
        require(
            all(
                value is not None
                for value in (
                    args.build,
                    args.revision,
                    args.reviewed_patch_sha256,
                    args.baseline_report,
                    args.baseline_report_sha256,
                )
            ),
            "candidate qualification requires build/revision/reviewed patch and frozen baseline report",
        )
        identity = study.build_records.build_identity(
            args.build, args.revision, args.binary
        )
        require(
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(ROOT),
                    "merge-base",
                    "--is-ancestor",
                    PARENT,
                    args.revision,
                ],
                capture_output=True,
            ).returncode
            == 0,
            "candidate lacks common parent",
        )
        patch = git("diff", "--binary", PARENT, args.revision, "--")
        require(
            study.digest(patch) == args.reviewed_patch_sha256,
            "candidate differs from reviewed patch",
        )
        baseline = json.loads(args.baseline_report.read_text())
        require(
            sha(args.baseline_report) == args.baseline_report_sha256
            and len(baseline["results"]) == 28
            and baseline["role"] == "baseline"
            and baseline["plan_sha256"] == sha(args.plan),
            "baseline qualification differs",
        )
    output = fresh(args.output)
    order = list(range(28))
    random.Random(20261031).shuffle(order)
    results = []
    raw_log_bytes = 0
    for index in order:
        row = plan["cases"][index]
        reference = (
            row["expected_reference"]
            if row["case"]["expectation"] == "hazard"
            else None
        )
        if baseline:
            old = next(x for x in baseline["results"] if x["case"] == row["case"]["id"])
            if old["qualified"]:
                reference = old["signature"]
        result = execute(
            args.binary,
            row,
            output / row["case"]["id"],
            reference,
            log_limit=min(LOG_LIMIT, max(0, COLLECTION_LOG_LIMIT - raw_log_bytes)),
        )
        raw_log_bytes += result["raw_log_bytes"]
        results.append({"case": row["case"]["id"], **result})
        write(output / "checkpoint.json", {"results": results})
        print(
            f"{args.role} qualification {len(results)}/28: {row['case']['id']} {result['status']}",
            flush=True,
        )
    bench.unchanged(plan["input_sha256"])
    require(sha(args.binary) == identity["binary_sha256"], "executable changed")
    report = {
        "schema_version": 1,
        "role": args.role,
        "plan_sha256": sha(args.plan),
        "build": identity,
        "runtime_context": bench.statistics.runtime_context(),
        "order": [plan["cases"][i]["case"]["id"] for i in order],
        "results": results,
        "aggregate_raw_log_bytes": raw_log_bytes,
        "aggregate_log_budget_exceeded": raw_log_bytes > COLLECTION_LOG_LIMIT,
        "timing_eligible": [row["case"] for row in results if row["qualified"]]
        if args.role == "baseline"
        else baseline["timing_eligible"],
        "scope": "One functional qualification per declared case; no repeated comparison or proof claim.",
    }
    write(output / "report.json", report)
    print("Report SHA256 " + sha(output / "report.json"))


def paired_order(ids):
    rng = random.Random(20261031)
    starts = {cid: rng.randrange(2) for cid in ids}
    order = []
    for repeat in range(1, 6):
        shuffled = list(ids)
        rng.shuffle(shuffled)
        for cid in shuffled:
            roles = (
                ("baseline", "candidate")
                if (starts[cid] + repeat) % 2
                else ("candidate", "baseline")
            )
            order.extend((cid, repeat, role) for role in roles)
    return order


def point_gate(base, candidate, primary=False):
    require(len(base) == len(candidate) == 5, "point gate needs all five observations")
    valid = all(x["qualified"] for x in base + candidate)
    if not valid:
        return {
            "valid": False,
            "benefit": False,
            "endpoint_nonregression": False,
            "rss_nonregression": False,
        }
    b = statistics.median(x["endpoint_seconds"] for x in base)
    c = statistics.median(x["endpoint_seconds"] for x in candidate)
    bm = max(x["usage"]["max_rss_kib"] for x in base)
    cm = max(x["usage"]["max_rss_kib"] for x in candidate)
    return {
        "valid": True,
        "baseline_median_seconds": b,
        "candidate_median_seconds": c,
        "baseline_max_rss_kib": bm,
        "candidate_max_rss_kib": cm,
        "benefit": bool(primary and c <= b * 0.8 and b - c >= 0.005),
        "endpoint_nonregression": c <= b * 1.10 + 0.002,
        "rss_nonregression": cm <= bm + max(bm * 0.05, 8192),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    prep = commands.add_parser("prepare")
    for flag in (
        "baseline",
        "baseline-build",
        "archived-plan",
        "comparator",
        "comparator-tests",
        "output",
    ):
        prep.add_argument("--" + flag, type=Path, required=True)
    prep.set_defaults(function=prepare)
    q = commands.add_parser("qualify")
    for flag in ("plan", "binary", "output"):
        q.add_argument("--" + flag, type=Path, required=True)
    q.add_argument("--role", choices=("baseline", "candidate"), required=True)
    q.add_argument("--reviewed-plan-sha256", required=True)
    for flag in ("build", "baseline-report"):
        q.add_argument("--" + flag, type=Path)
    for flag in ("revision", "reviewed-patch-sha256", "baseline-report-sha256"):
        q.add_argument("--" + flag)
    q.set_defaults(function=qualify)
    args = parser.parse_args()
    args.function(args)


if __name__ == "__main__":
    main()
