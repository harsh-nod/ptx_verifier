#!/usr/bin/env python3
"""Run source-pinned original32 CLI graph/spec/numeric proofs on CPU only.

A selected subset produces PARTIAL, never full32 acceptance. The separate
aggregator inspects the actual logs, commands and immutable snapshots.
"""

import argparse
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import platform
import re
import shutil
import socket
import subprocess
import tempfile
import time

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "original_cli_runtime", HERE / "prove_advanced.py"
)
RUNTIME = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNTIME)
require, sha = RUNTIME.require, RUNTIME.sha
GATE = "original32 CLI graph/spec/numeric"
TIME_FORMAT = "user=%U system=%S peak_rss_kib=%M wall=%e exit=%x"
TOTAL_OUTPUTS = 395394
INPUT_KEYS = ("source", "assembly", "spec", "launch_config")


def atomic_json(path, value):
    """Publish a fresh receipt without following a pre-existing temporary link."""
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=path.parent, prefix=".proof-", delete=False
        ) as stream:
            temporary = Path(stream.name)
            stream.write(json.dumps(value, indent=2) + "\n")
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def json_sha(value):
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def relative_path(value):
    path = Path(value)
    require(
        not path.is_absolute() and ".." not in path.parts, "input path must be relative"
    )
    return path


def load_registry(registry):
    """Use the exact shared shape/dtype/ABI/index contract for every family."""
    registry = registry.resolve(strict=True)
    full, root = registry.parent, registry.parents[3]
    contract, contract_path = RUNTIME.load_contract(full)
    inventory_path = full.parent / "full-parity/gaps.json"
    inventory = json.loads(inventory_path.read_text())
    rows = contract.validate_inventory(inventory, root=root)
    document = json.loads(registry.read_text())
    contract.validate_registry(document, rows, full, require_all=True)
    cases = document["cases"]
    require(
        len(cases) == len({case["kernel"] for case in cases}) == 32,
        "all32 unique kernel registrations required",
    )
    require(
        sum(case["expected_outputs"] for case in cases) == TOTAL_OUTPUTS,
        "complete395394-output registry required",
    )
    inputs = {registry, contract_path, inventory_path}
    workload_source = root / relative_path(inventory["workload_source"])
    require(
        sha(workload_source) == inventory["workload_source_sha256"],
        "original workload configuration source changed",
    )
    inputs.add(workload_source)
    for row in rows.values():
        inputs.update(
            root / relative_path(row[key])
            for key in ("baseline_path", "baseline_config_path")
        )
    for case in cases:
        for key in INPUT_KEYS:
            source = full / relative_path(case[key])
            require(
                sha(source) == case[key + "_sha256"], "registered input hash mismatch"
            )
            inputs.add(source)
    pins = {str(path.relative_to(root)): sha(path) for path in sorted(inputs)}
    outputs = {
        case["kernel"]: output_contract(case, rows[case["baseline_id"]], contract)
        for case in cases
    }
    return root, cases, pins, outputs


def output_contract(case, row, contract):
    def index_contract(arrays):
        return {
            name: {
                "elements": len(indices),
                "indices_sha256": json_sha(sorted(indices)),
            }
            for name, indices in sorted(arrays.items())
        }

    native = {}
    for view in case["output_projection"]:
        indices = native.setdefault(view["native_array"], set())
        values = set(range(view["native_start"], view["native_start"] + view["length"]))
        require(not indices.intersection(values), "duplicate native output projection")
        indices.update(values)
    baseline = contract.output_indices(row)
    require(
        sum(map(len, baseline.values()))
        == sum(map(len, native.values()))
        == case["expected_outputs"],
        "complete per-array output contract required",
    )
    return {
        "baseline": index_contract(baseline),
        "native": index_contract(native),
        "projection_sha256": json_sha(case["output_projection"]),
    }


def selected_cases(cases, selected):
    names = {case["kernel"]: case for case in cases}
    require(len(selected) == len(set(selected)), "duplicate selected kernel")
    require(not set(selected) - names.keys(), "unknown selected kernel")
    return [names[name] for name in selected] if selected else cases


def command(binary, snapshot, case, mode, log_level):
    full = snapshot / "tests/gfx1250/full"
    argv = [str(binary), "--no-log-file", "--backend", "amdgpu", "--target", "gfx1250"]
    if mode == "logging":
        argv += ["--log-level", log_level]
    argv += [
        "verify",
        str(full / case["assembly"]),
        str(full / case["spec"]),
        "--kernel",
        case["kernel"],
        "--config",
        str(full / case["launch_config"]),
        "--sample",
        "0",
        "--verify-numeric",
    ]
    for name, value in sorted(case["dimensions"].items()):
        argv += ["--dim", f"{name}={value}"]
    return argv


def check_process(result, stdout, expected):
    require(
        result["exit_code"] == 0 and result["termination"] is None,
        "proof process did not exit successfully",
    )
    require(
        math.isfinite(result["elapsed_seconds"]) and result["elapsed_seconds"] > 0,
        "unexecuted proof process",
    )
    RUNTIME.check_stdout(stdout, expected)


def failed_outcome(result, stdout, stderr):
    if result.get("termination") == "wall_timeout":
        return "timeout"
    if result.get("termination") == "rss_limit":
        return "resource_limit"
    text = stdout + "\n" + stderr
    if result.get("exit_code", 0) < 0:
        return "crash"
    if re.search(r"\bUnsupported\b|unsupported instruction", text, re.I):
        return "unsupported"
    if re.search(r"^VERDICT: UNKNOWN\s*$", stdout, re.M):
        return "unknown"
    if re.search(r"unwritten|index.?set mismatch|missing output", text, re.I):
        return "missing_output"
    if re.search(r"^VERDICT: (?:REJECT|REFUTED)\s*$", stdout, re.M):
        return "refuted"
    return "process_error" if result.get("exit_code") != 0 else "invalid_output"


def refuse_alias(output, protected):
    """Do not invalidate a receipt by overwriting one of its retained inputs."""
    output = output.resolve()
    for path in protected:
        path = Path(path)
        same = output == path.resolve()
        if not same and output.exists() and path.exists():
            same = output.samefile(path)
        require(not same, f"output aliases retained input artifact: {path}")


def retained_inputs(registry):
    """Enumerate known inputs before writing even an unsuccessful receipt."""
    registry = registry.resolve()
    protected = {registry, Path(__file__), HERE / "prove_advanced.py"}
    if len(registry.parents) < 4:
        return protected
    full, root = registry.parent, registry.parents[3]
    inventory = full.parent / "full-parity/gaps.json"
    protected.update((inventory, inventory.with_name("contract.py")))
    for manifest, field, keys, base in (
        (registry, "cases", INPUT_KEYS, full),
        (inventory, "workloads", ("baseline_path", "baseline_config_path"), root),
    ):
        try:
            document = json.loads(manifest.read_text())
        except (OSError, ValueError):
            continue
        if not isinstance(document, dict):
            continue
        if manifest == inventory and isinstance(document.get("workload_source"), str):
            protected.add(root / document["workload_source"])
        rows = document.get(field)
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, dict):
                    protected.update(
                        base / row[key] for key in keys if isinstance(row.get(key), str)
                    )
    return protected


def runtime_probe(binary, env):
    probe = subprocess.run(
        ["ldd", str(binary)], capture_output=True, text=True, timeout=30, env=env
    )
    require(
        probe.returncode == 0 and "not found" not in probe.stdout + probe.stderr,
        "binary runtime mismatch",
    )
    paths = re.findall(r"(?:=>\s+)?(/[^\s]+)\s+\(", probe.stdout)
    require(paths, "resolved dynamic runtime pins required")
    return (
        {"exit_code": probe.returncode, "stdout": probe.stdout, "stderr": probe.stderr},
        {str(Path(path).resolve(strict=True)): sha(path) for path in paths},
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--binary-revision", required=True)
    parser.add_argument("--registry", required=True, type=Path)
    parser.add_argument("--fixture-revision", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--kernel", action="append", default=[])
    parser.add_argument("--mode", choices=("default", "logging"), default="default")
    parser.add_argument("--log-level", choices=("info", "debug"), default="info")
    parser.add_argument("--wall-seconds", type=int, default=28800)
    parser.add_argument("--cpu-seconds", type=int, default=28200)
    parser.add_argument("--rss-gib", type=int, default=384)
    parser.add_argument("--address-space-gib", type=int, default=512)
    args = parser.parse_args()
    output = args.output.resolve()
    destination = output / "receipt.json"
    try:
        refuse_alias(destination, retained_inputs(args.registry) | {args.binary})
    except (ValueError, OSError) as error:
        parser.error(str(error))
    output.mkdir(parents=True, exist_ok=True)
    receipt = {
        "schema_version": 1,
        "gate": GATE,
        "status": "incomplete",
        "hardware_execution": False,
        "sampling": False,
        "results": [],
        "started_unix": time.time(),
        "host": socket.gethostname(),
        "platform": platform.platform(),
        "driver_sha256": sha(__file__),
        "bounded_driver_sha256": sha(HERE / "prove_advanced.py"),
        "binary_revision_supplied_by_builder": args.binary_revision,
        "fixture_revision_supplied_by_builder": args.fixture_revision,
        "mode": args.mode,
        "log_level": args.log_level,
    }
    atomic_json(destination, receipt)
    try:
        require(
            all(
                re.fullmatch(r"[0-9a-f]{40}", revision)
                for revision in (args.binary_revision, args.fixture_revision)
            ),
            "exact builder/fixture revisions required",
        )
        require(
            all(
                value > 0
                for value in (
                    args.wall_seconds,
                    args.cpu_seconds,
                    args.rss_gib,
                    args.address_space_gib,
                )
            )
            and args.address_space_gib >= args.rss_gib,
            "invalid resource limits",
        )
        root, cases, pins, outputs = load_registry(args.registry)
        cases = selected_cases(cases, args.kernel)
        protected = [root / path for path in pins] + [
            args.binary,
            Path(__file__),
            HERE / "prove_advanced.py",
        ]
        for path in [destination] + [
            output / case["kernel"] / name
            for case in cases
            for name in ("stdout.txt", "stderr.txt", "resources.txt")
        ]:
            refuse_alias(path, protected)
        snapshot = output / f"snapshot-{time.time_ns()}"
        snapshot.mkdir()
        corpus, binary = snapshot / "corpus", snapshot / "volta"
        shutil.copy2(args.binary.resolve(strict=True), binary)
        binary.chmod(0o555)
        for path, digest in pins.items():
            RUNTIME.snapshot_input(root / path, corpus / path, digest)
        env = dict(os.environ)
        require(
            not any(name in env for name in ("LD_PRELOAD", "LD_AUDIT")),
            "loader injection",
        )
        for name in ("VOLTA_VIZ_DIR", "RUST_LOG"):
            env.pop(name, None)
        env.update(
            HIP_VISIBLE_DEVICES="", ROCR_VISIBLE_DEVICES="", CUDA_VISIBLE_DEVICES=""
        )
        ldd, runtimes = runtime_probe(binary, env)
        for case in cases:
            for name in ("stdout.txt", "stderr.txt", "resources.txt"):
                refuse_alias(output / case["kernel"] / name, runtimes)
        help_run = subprocess.run(
            [str(binary), "--help"], capture_output=True, text=True, timeout=30, env=env
        )
        require(help_run.returncode == 0, "binary capability probe failed")
        require(
            args.mode != "logging" or "--log-level" in help_run.stdout,
            "logging build required",
        )
        limits = {
            "wall_seconds": args.wall_seconds,
            "cpu_seconds": args.cpu_seconds,
            "rss_bytes": args.rss_gib * 1024**3,
            "address_space_bytes": args.address_space_gib * 1024**3,
        }
        receipt.update(
            binary_sha256=sha(binary),
            input_sha256=pins,
            output_contracts=outputs,
            runtime_sha256=runtimes,
            ldd=ldd,
            snapshot=str(snapshot),
            selected_kernels=[case["kernel"] for case in cases],
            limits=limits,
            capability_probe={
                "argv": [str(binary), "--help"],
                "exit_code": help_run.returncode,
                "stdout_sha256": hashlib.sha256(help_run.stdout.encode()).hexdigest(),
            },
        )
        atomic_json(destination, receipt)
        for case in cases:
            name = case["kernel"]
            directory = output / name
            directory.mkdir(exist_ok=True)
            result = {
                "kernel": name,
                "baseline_id": case["baseline_id"],
                "expected_outputs": case["expected_outputs"],
                "output_contract": outputs[name],
                "passed": False,
                "outcome": "incomplete",
            }
            receipt["results"].append(result)
            atomic_json(destination, receipt)
            try:
                result.update(
                    RUNTIME.bounded(
                        command(binary, corpus, case, args.mode, args.log_level),
                        directory,
                        env,
                        limits,
                    )
                )
                stdout, stderr = [
                    (directory / (stream + ".txt")).read_text(errors="replace")
                    for stream in ("stdout", "stderr")
                ]
                result["outcome"] = failed_outcome(result, stdout, stderr)
                check_process(result, stdout, case["expected_outputs"])
                result.update(passed=True, outcome="passed")
            except (ValueError, OSError, subprocess.SubprocessError) as error:
                result["error"] = f"{type(error).__name__}: {error}"
            require(sha(binary) == receipt["binary_sha256"], "binary mutated")
            require(
                all(sha(corpus / path) == digest for path, digest in pins.items()),
                "snapshot mutated",
            )
            require(
                all(sha(path) == digest for path, digest in runtimes.items()),
                "runtime mutated",
            )
            atomic_json(destination, receipt)
            print(
                json.dumps(
                    {
                        key: result.get(key)
                        for key in (
                            "kernel",
                            "passed",
                            "outcome",
                            "elapsed_seconds",
                            "monitored_peak_rss_bytes",
                            "error",
                        )
                    }
                ),
                flush=True,
            )
        complete = len(cases) == 32
        success = all(result["passed"] for result in receipt["results"])
        receipt.update(
            all_required_complete=complete,
            expected_outputs=sum(case["expected_outputs"] for case in cases),
            status=("pass" if complete else "partial") if success else "failed",
        )
        return 0 if success else 1
    except (
        ValueError,
        OSError,
        KeyError,
        TypeError,
        subprocess.SubprocessError,
    ) as error:
        receipt.update(status="incomplete", error=f"{type(error).__name__}: {error}")
        return 1
    finally:
        receipt["finished_unix"] = time.time()
        atomic_json(destination, receipt)


if __name__ == "__main__":
    raise SystemExit(main())
