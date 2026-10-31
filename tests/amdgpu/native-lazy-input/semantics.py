#!/usr/bin/env python3
"""One-off full output and specification controls; never performance samples."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import importlib.util
import os
from pathlib import Path
import select
import shutil
import threading
import zlib

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "native_lazy_comparison", HERE / "comparison.py"
)
comparison = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comparison)
frozen = comparison.frozen
require, sha, write = frozen.require, frozen.sha, frozen.write


class StorageLimit(OSError):
    pass


class Budget:
    def __init__(self, limit, reserve=frozen.RESERVE):
        self.limit, self.reserve, self.used = limit, reserve, 0

    def writer(self, raw, directory):
        budget = self

        class Writer:
            def write(self, data):
                if budget.used + len(data) > budget.limit:
                    raise StorageLimit(
                        "aggregate compressed-output byte budget exhausted"
                    )
                if (
                    shutil.disk_usage(directory).free
                    < budget.reserve + len(data) + 65536
                ):
                    raise StorageLimit("disk reserve reached")
                count = raw.write(data)
                budget.used += count
                if count != len(data):
                    raise OSError("short compressed-output write")
                return count

            def flush(self):
                raw.flush()

        return Writer()


def capture_export(argv_factory, directory, budget, *, log_limit=frozen.LOG_LIMIT):
    """A pre-opened FIFO reader stores gzip from byte one, without a raw file."""
    directory.mkdir(parents=True)
    fifo = directory / "outputs.fifo"
    artifact = directory / "outputs.vexpr.gz"
    os.mkfifo(fifo)
    fd = os.open(fifo, os.O_RDONLY | os.O_NONBLOCK)
    stopped = threading.Event()
    ready = threading.Event()
    state = {
        "received_decoded_bytes": 0,
        "received_decoded_sha256": None,
        "writer_eof": False,
        "errors": [],
    }
    digest = hashlib.sha256()

    def reader():
        try:
            with artifact.open("wb", buffering=0) as raw:
                encoded = gzip.GzipFile(
                    filename="",
                    fileobj=budget.writer(raw, directory),
                    mode="wb",
                    compresslevel=1,
                    mtime=0,
                )
                ready.set()
                try:
                    while True:
                        readable, _, _ = select.select([fd], [], [], 0.05)
                        if not readable and not stopped.is_set():
                            continue
                        try:
                            chunk = os.read(fd, 65536)
                        except BlockingIOError:
                            if stopped.is_set():
                                break
                            continue
                        if not chunk:
                            if state["received_decoded_bytes"] or stopped.is_set():
                                state["writer_eof"] = (
                                    state["received_decoded_bytes"] > 0
                                )
                                break
                            stopped.wait(0.01)
                            continue
                        digest.update(chunk)
                        state["received_decoded_bytes"] += len(chunk)
                        encoded.write(chunk)
                finally:
                    encoded.close()
        except (OSError, ValueError, zlib.error) as error:
            state["errors"].append(type(error).__name__ + ": " + str(error))
        finally:
            state["received_decoded_sha256"] = digest.hexdigest()
            ready.set()
            os.close(fd)  # A failed reader makes any still-writing child fail, too.

    thread = threading.Thread(target=reader, daemon=True)
    thread.start()
    capture_error = None
    try:
        require(
            ready.wait(timeout=5) and not state["errors"],
            "gzip reader failed before child launch",
        )
        result = frozen.capture(argv_factory(fifo), directory, log_limit=log_limit)
    except (OSError, ValueError) as error:
        capture_error = type(error).__name__ + ": " + str(error)
        result = {
            "returncode": None,
            "timed_out": False,
            "seconds": 0,
            "first_marker_seconds": None,
            "usage": {},
            "log_limit_exceeded": False,
            "raw_log_bytes": 0,
            "command": argv_factory(fifo),
        }
    finally:
        stopped.set()
        thread.join(timeout=5)
    require(
        not thread.is_alive(),
        "gzip reader did not terminate; stop collection and retain artifacts",
    )
    # The FIFO is a transport endpoint, not an intermediate raw artifact.
    fifo.unlink()
    if capture_error:
        state["errors"].append(capture_error)
    for name in ("stdout", "stderr"):
        if not (directory / name).exists():
            (directory / name).write_bytes(b"")
    complete = (
        result["returncode"] == 0
        and not result["timed_out"]
        and not result["log_limit_exceeded"]
        and state["writer_eof"]
        and not state["errors"]
    )
    return {
        **result,
        "gzip_capture": {
            **state,
            "complete": bool(complete),
            "artifact_sha256": sha(artifact) if artifact.exists() else None,
            "artifact_bytes": artifact.stat().st_size if artifact.exists() else 0,
            "compression": "gzip-level1-mtime0-empty-filename",
            "limits": "Incomplete captures retain partial bytes; received hashes/counts describe read bytes, not a complete retained expression artifact.",
        },
    }


def retained_failure(argv, directory, reason):
    for name in ("stdout", "stderr"):
        if not (directory / name).exists():
            (directory / name).write_bytes(b"")
    return {
        "command": argv,
        "returncode": None,
        "timed_out": False,
        "log_limit_exceeded": False,
        "seconds": 0,
        "first_marker_seconds": None,
        "raw_log_bytes": sum(
            (directory / n).stat().st_size for n in ("stdout", "stderr")
        ),
        "usage": {},
        "not_run_reason": reason,
    }


def annotate(result, row, directory, reference=None, *, verify=False):
    stdout, stderr = [
        (directory / name).read_text(errors="replace") for name in ("stdout", "stderr")
    ]
    graph = frozen.corpus.harness.parse_cli(stdout)
    return {
        **result,
        **frozen.observe(result, row, stdout, stderr, reference, verify=verify),
        "graph_failure_names": [
            name for name, verdict, _ in graph.checks if verdict == "FAIL"
        ],
        "stdout_sha256": sha(directory / "stdout"),
        "stderr_sha256": sha(directory / "stderr"),
        "resources_sha256": sha(directory / "resources.txt")
        if (directory / "resources.txt").exists()
        else None,
    }


def validate_expression_capture(tool, artifact, expected, capture):
    require(capture["complete"], "incomplete process/export capture")
    observed = tool.scan(artifact, expected)
    require(
        observed["artifact_sha256"] == capture["artifact_sha256"]
        and observed["artifact_bytes"] == capture["artifact_bytes"],
        "stored gzip binding differs",
    )
    require(
        observed["decoded_vexpr_sha256"] == capture["received_decoded_sha256"]
        and observed["decoded_vexpr_bytes"] == capture["received_decoded_bytes"],
        "gzip raw/decoded binding differs",
    )
    return tool.summary(observed)


def proof_gates(rows, plan):
    definitions = {r["case"]["id"]: r["definition"] for r in plan["cases"]}
    previous = [
        cid
        for cid, definition in definitions.items()
        if definition["expectation"] == "safe"
        and definition["previous_complete_equation_proved"]
    ]
    proofs = {(r["case"], r["role"]): r for r in rows if r["stage"] == "verify"}
    preserved = all(
        (cid, role) in proofs
        and proofs[cid, role]["qualified"]
        and proofs[cid, role]["status"] == "spec_verified"
        for cid in previous
        for role in ("baseline", "candidate")
    )
    return {
        "previously_proved_cases": previous,
        "previously_proved_case_count": len(previous),
        "all_previous_complete_proofs_retained": preserved,
        "other_equations": [
            {
                "case": r["case"],
                "role": r["role"],
                "status": r["status"],
                "measurement_errors": r["measurement_errors"],
            }
            for r in rows
            if r["stage"] == "verify" and r["case"] not in previous
        ],
    }


def semantic_gates(results, comparisons, plan):
    proofs = proof_gates(results, plan)
    false_findings = sum(
        bool(r.get("false_positive") or r.get("graph_failure_names")) for r in results
    )
    unsafe = sum(bool(r.get("unsafe_acceptance")) for r in results)
    return {
        "proofs": proofs,
        "false_findings": false_findings,
        "unsafe_acceptances": unsafe,
        "all_semantic_controls_pass": all(r["structural_match"] for r in comparisons)
        and proofs["all_previous_complete_proofs_retained"]
        and false_findings == 0
        and unsafe == 0,
    }


def run_one(binary, row, directory, stage, budget, limit, reference, tool):
    if stage == "export" and limit > 0 and budget.used < budget.limit:
        result = capture_export(
            lambda fifo: frozen.command(binary, row, export=fifo),
            directory,
            budget,
            log_limit=limit,
        )
        result = annotate(result, row, directory, reference)
    else:
        directory.mkdir(parents=True)
        argv = frozen.command(
            binary,
            row,
            verify=stage == "verify",
            export=directory / "outputs.fifo" if stage == "export" else None,
        )
        if stage == "verify" and limit > 0:
            try:
                result = frozen.capture(argv, directory, log_limit=limit)
            except (OSError, ValueError) as error:
                result = retained_failure(argv, directory, str(error))
        else:
            result = retained_failure(
                argv,
                directory,
                "semantic output/log budget exhausted; scheduled observation retained",
            )
        result = annotate(result, row, directory, verify=stage == "verify")
    if stage == "export":
        result["full_output_artifact_valid"] = False
        if result["qualified"] and result.get("gzip_capture", {}).get("complete"):
            try:
                result["expressions"] = validate_expression_capture(
                    tool,
                    directory / "outputs.vexpr.gz",
                    row["case"]["output_indices"],
                    result["gzip_capture"],
                )
                result["full_output_artifact_valid"] = True
            except (OSError, ValueError) as error:
                result["measurement_errors"].append(
                    "complete expression control: " + str(error)
                )
    return result


def controls(args):
    prepared, plan, baseline = comparison.checked(args.plan, args.reviewed_plan_sha256)
    candidate = comparison.candidate_report(
        args.candidate_qualification,
        args.candidate_qualification_sha256,
        plan,
        prepared,
    )
    directory = frozen.fresh(args.plan.parent / "semantics")
    tool = frozen.load_module(
        "native_lazy_structural_comparator",
        Path(prepared["structural_comparator"]["path"]),
    )
    budget = Budget(prepared["budgets"]["gzip_bytes"])
    cases = {r["case"]["id"]: r for r in plan["cases"]}
    refs = {r["case"]: r["signature"] for r in baseline["results"]}
    results, comparisons, used = [], [], 0
    for cid, role, stage in prepared["semantic_schedule"]:
        row = cases[cid]
        binary = Path(
            plan["baseline"]["binary"]
            if role == "baseline"
            else prepared["candidate"]["binary"]
        )
        result = run_one(
            binary,
            row,
            directory / cid / role / stage,
            stage,
            budget,
            comparison.log_budget(prepared, args.plan, used),
            refs[cid],
            tool,
        )
        result.update(case=cid, role=role, stage=stage)
        used += result["raw_log_bytes"]
        results.append(result)
        write(
            directory / "checkpoint.json",
            {"results": results, "compressed_bytes": budget.used},
        )
        print(
            f"Semantic/spec observation {len(results)}/52: {cid} {role} {stage} {result['status']}",
            flush=True,
        )
    for cid in prepared["safe_semantic_cases"]:
        exports = {
            r["role"]: r for r in results if r["case"] == cid and r["stage"] == "export"
        }
        a, b = (exports[role].get("expressions") for role in ("baseline", "candidate"))
        valid = all(
            exports[role]["full_output_artifact_valid"]
            for role in ("baseline", "candidate")
        )
        comparisons.append(
            {
                "case": cid,
                "all_coordinates_valid": valid,
                "structural_match": bool(
                    valid
                    and a["structural_output_map_sha256"]
                    == b["structural_output_map_sha256"]
                    and a["coordinate_map_sha256"] == b["coordinate_map_sha256"]
                ),
                "baseline": a,
                "candidate": b,
            }
        )
    require(
        len(results) == 52
        and [(r["case"], r["role"], r["stage"]) for r in results]
        == [tuple(r) for r in prepared["semantic_schedule"]],
        "semantic observation denominator/order differs",
    )
    require(budget.used <= 2**31, "compressed-output budget exceeded")
    frozen.bench.unchanged(prepared["input_sha256"])
    require(
        sha(args.candidate_qualification) == args.candidate_qualification_sha256,
        "candidate qualification changed during semantic controls",
    )
    gates = semantic_gates(results, comparisons, plan)
    require(
        gates["proofs"]["previously_proved_case_count"] == 11,
        "previous complete-proof denominator differs",
    )
    write(
        directory / "report.json",
        {
            "schema_version": 1,
            "plan_sha256": sha(args.plan),
            "candidate_qualification_sha256": args.candidate_qualification_sha256,
            "process_records": results,
            "output_comparisons": comparisons,
            "functional": comparison.functional(baseline, candidate),
            **gates,
            "compressed_bytes": budget.used,
            "aggregate_raw_log_bytes": used,
            "other_bytes": comparison.other_bytes(prepared, args.plan),
            "limits": [
                "No timing or RSS claim from gzip, parser, specification or audit processes.",
                "Matching exact output structure is not independent mathematical proof.",
                "Previously unproved convolution/attention equations retain every miss/timeout explicitly.",
            ],
        },
    )
    print("Semantic report SHA256 " + sha(directory / "report.json"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ("plan", "candidate-qualification"):
        parser.add_argument("--" + flag, type=Path, required=True)
    for flag in ("reviewed-plan-sha256", "candidate-qualification-sha256"):
        parser.add_argument("--" + flag, required=True)
    controls(parser.parse_args())


if __name__ == "__main__":
    main()
