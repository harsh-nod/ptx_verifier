#!/usr/bin/env python3
"""Independently replay W01-W18 from exact original-shape gfx1250 assembly.

This gate covers 18 of the 32 original workload variants. It does not certify
graph safety, mathematical equivalence, or the remaining 14 variants.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "hardware"))
from portable_run import checked_run, device_environment, sha256, write_receipt

# Independent original shape/storage contract: (outputs, input bytes, buffers).
CONTRACT = {
    "relu_f16": (1024, 2048, 2), "relu_f8": (2048, 2048, 2),
    "sigmoid_f16": (1024, 2048, 2), "sigmoid_f8": (1024, 1024, 2),
    "silu_f16": (512, 1024, 2), "silu_f8": (1024, 1024, 2),
    "swiglu_f16": (1024, 4096, 3), "swiglu_f8": (2048, 4096, 3),
    "rope_f16": (128, 768, 4), "rope_f8": (128, 384, 4),
    "rmsnorm_f16": (4096, 16384, 3), "rmsnorm_f8": (4096, 8192, 3),
    "softmax_f16": (4096, 8192, 2), "softmax_f8": (4096, 4096, 2),
    "matvec_f16": (32, 270336, 3), "matvec_f8": (64, 266240, 3),
    "reduction_f16": (1, 512, 2), "reduction_f8": (1, 2048, 2),
}
INPUTS = (
    "hardware/portable_run.py", "full/hardware/original_run.py",
    "full/hardware/original.cpp", "full/hardware/original_common.hpp", "full/fixtures/original-f16.hip",
    "full/fixtures/original-f16.s", "full/fixtures/original-f8.hip",
    "full/fixtures/original-f8.s",
)


def validate_result(result: dict, patterns: int) -> None:
    if (result.get("status"), result.get("architecture"), result.get("wave_size"),
            result.get("patterns")) != ("pass", "gfx1250", 32, patterns):
        raise ValueError("driver did not report complete real gfx1250 execution")
    if result.get("reference_controls") != "pass":
        raise ValueError("independent numerical reference controls did not pass")
    rows = result.get("cases")
    if not isinstance(rows, list) or len(rows) != 18:
        raise ValueError("all 18 original variants are mandatory")
    if {r.get("kernel") for r in rows} != set(CONTRACT):
        raise ValueError("driver omitted or duplicated an original variant")
    for row in rows:
        outputs, inputs, buffers = CONTRACT[row["kernel"]]
        for key, expected in {
            "outputs": outputs * patterns, "launches": patterns,
            "unchanged_input_bytes": inputs * patterns,
            "unchanged_guard_bytes": buffers * 8192 * patterns,
        }.items():
            if type(row.get(key)) is not int or row[key] != expected:
                raise ValueError(f"{row['kernel']}: incomplete {key}")
        error = row.get("max_absolute_error")
        if type(error) not in (int, float) or not math.isfinite(error) or error < 0:
            raise ValueError("invalid numerical error metric")


def artifact_hashes(directory: Path) -> dict:
    return {p: sha256(directory / p) for p in INPUTS}


def validate_revision(directory: Path, revision: str) -> None:
    repository = Path(checked_run(
        ["git", "rev-parse", "--show-toplevel"], cwd=directory, timeout=10
    ).stdout.strip())
    for relative in INPUTS:
        path = directory / relative
        content = subprocess.run(
            ["git", "show", f"{revision}:{path.relative_to(repository).as_posix()}"],
            cwd=repository, capture_output=True, check=True, timeout=10,
        ).stdout
        if hashlib.sha256(content).hexdigest() != sha256(path):
            raise ValueError(f"{relative}: differs from stated source revision")


def run_local(args: argparse.Namespace, directory: Path, receipt: dict) -> None:
    env = device_environment(args.device, dict(os.environ))
    records = receipt["commands"]
    rocm = Path(args.rocm).resolve(strict=True)
    build = Path(tempfile.mkdtemp(prefix="original-build-", dir=directory))
    receipt.update(build_directory=str(build), rocm_directory=str(rocm),
                   device_environment={"HIP_VISIBLE_DEVICES": str(args.device)},
                   host=checked_run(["hostname"], timeout=10, records=records).stdout.strip())
    tools = {name: rocm / "llvm/bin" / name for name in ("llvm-mc", "ld.lld", "clang++")}
    receipt["toolchains"] = {}
    for name, tool in tools.items():
        receipt["toolchains"][name] = {
            "path": str(tool.resolve()), "sha256": sha256(tool),
            "version": checked_run([str(tool), "--version"], timeout=15, records=records).stdout,
        }
    objects = []
    for dtype in ("f16", "f8"):
        obj, module = build / f"{dtype}.o", build / f"{dtype}.hsaco"
        checked_run([str(tools["llvm-mc"]), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                     "--filetype=obj", str(directory / f"full/fixtures/original-{dtype}.s"),
                     "-o", str(obj)], timeout=60, records=records)
        checked_run([str(tools["ld.lld"]), "-shared", str(obj), "-o", str(module)], timeout=60, records=records)
        objects.append(module)
    driver = build / "original_driver"
    checked_run([str(tools["clang++"]), "-std=c++17", "-O2", "-Wall", "-Wextra", "-Werror",
                 "-D__HIP_PLATFORM_AMD__", "-I" + str(rocm / "include"),
                 str(directory / "full/hardware/original.cpp"), "-L" + str(rocm / "lib"),
                 "-lamdhip64", "-Wl,-rpath," + str(rocm / "lib"), "-o", str(driver)],
                timeout=120, records=records)
    linking = checked_run(["ldd", str(driver)], timeout=15, env=env, records=records)
    runtime = [line for line in linking.stdout.splitlines() if "libamdhip64.so" in line]
    if len(runtime) != 1 or "=>" not in runtime[0]:
        raise ValueError("could not identify the resolved HIP runtime")
    library = Path(runtime[0].split("=>", 1)[1].split()[0]).resolve(strict=True)
    receipt["toolchains"]["HIP_runtime_library"] = {"path": str(library), "sha256": sha256(library)}
    receipt["built_artifacts"] = {p.name: sha256(p) for p in [driver, *objects]}
    checked_run([str(driver), "--cpu-only"], timeout=15, env=env, records=records)
    completed = checked_run([str(driver), *map(str, objects), str(args.patterns)],
                            timeout=args.timeout, env=env, records=records)
    result = json.loads(completed.stdout)
    validate_result(result, args.patterns)
    receipt["validation"] = result


def run_remote(args: argparse.Namespace, directory: Path, receipt: dict) -> None:
    validate_revision(directory, args.revision)
    remote = checked_run(["ssh", args.host, "mktemp -d /tmp/ptx-gfx1250-original.XXXXXX"], timeout=45).stdout.strip()
    if not remote.startswith("/tmp/ptx-gfx1250-original.") or any(c.isspace() for c in remote):
        raise ValueError("unexpected remote staging directory")
    parents = sorted({str(Path(p).parent) for p in INPUTS})
    checked_run(["ssh", args.host, shlex.join(["mkdir", "-p", *[remote + "/" + p for p in parents]])], timeout=45)
    for relative in INPUTS:
        checked_run(["scp", str(directory / relative), args.host + ":" + remote + "/" + relative], timeout=45)
    command = ["python3", remote + "/full/hardware/original_run.py", "--local",
               "--fixture-directory", remote, "--device", str(args.device), "--patterns", str(args.patterns),
               "--timeout", str(args.timeout), "--rocm", args.rocm, "--revision", args.revision,
               "--result", remote + "/result.json", "--invocation-id", args.invocation_id]
    error = None
    try:
        checked_run(["ssh", args.host, shlex.join(command)], timeout=args.timeout + 300)
    except Exception as caught:
        error = caught
    with tempfile.TemporaryDirectory(prefix="gfx1250-original-receipt-") as download:
        path = Path(download) / "result.json"
        checked_run(["scp", args.host + ":" + remote + "/result.json", str(path)], timeout=45)
        result = json.loads(path.read_text())
    if (result.get("invocation_id"), result.get("source_revision"), result.get("input_artifacts")) != (
            args.invocation_id, args.revision, receipt["input_artifacts"]):
        raise ValueError("remote receipt has different invocation, revision, or artifacts")
    receipt.update(result)
    receipt["remote_execution"] = {"ssh_host": args.host, "directory": remote, "argv": command}
    if error:
        raise error
    if receipt.get("status") != "pass":
        raise ValueError("remote execution failed")
    validate_result(receipt["validation"], args.patterns)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--host")
    mode.add_argument("--local", action="store_true")
    parser.add_argument("--fixture-directory", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--result", type=Path, required=True)
    parser.add_argument("--device", type=int, required=True)
    parser.add_argument("--patterns", type=int, default=9)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--rocm", default="/opt/rocm")
    parser.add_argument("--revision")
    parser.add_argument("--invocation-id", help=argparse.SUPPRESS)
    args = parser.parse_args()
    args.invocation_id = args.invocation_id or str(uuid.uuid4())
    result_path = args.result.resolve()
    directory = args.fixture_directory.resolve()
    if result_path in {directory / p for p in INPUTS}:
        parser.error("receipt must not overwrite an input artifact")
    receipt = {"schema_version": 1, "status": "incomplete", "invocation_id": args.invocation_id,
               "timestamp_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "commands": [],
               "scope": "Exact-assembly hardware numerics W01-W18 only; graph/equivalence and W19-W32 remain separate gates."}
    try:
        # Invalidate old success before preflight, SSH, build, or kernel launch.
        write_receipt(result_path, receipt)
        if not 1 <= args.patterns <= 64 or args.device < 0 or args.timeout < 1:
            raise ValueError("require patterns 1..64, nonnegative device, positive timeout")
        if str(uuid.UUID(args.invocation_id)) != args.invocation_id:
            raise ValueError("invocation ID must be a canonical UUID")
        args.revision = args.revision or checked_run(["git", "rev-parse", "HEAD"], cwd=directory, timeout=10).stdout.strip()
        if len(args.revision) != 40 or any(c not in "0123456789abcdef" for c in args.revision):
            raise ValueError("revision must be an exact git object ID")
        receipt.update(source_revision=args.revision, input_artifacts=artifact_hashes(directory),
                       selected_physical_device=args.device, original_contract=CONTRACT)
        if args.local:
            run_local(args, directory, receipt)
        else:
            run_remote(args, directory, receipt)
        if artifact_hashes(directory) != receipt["input_artifacts"]:
            raise ValueError("source artifacts changed during execution")
        receipt["status"] = "pass"
        write_receipt(result_path, receipt)
        print(f"PASS 18 original variants; receipt: {result_path}")
        return 0
    except Exception as error:
        receipt.update(status="fail", error=str(error))
        write_receipt(result_path, receipt)
        print(f"original workload validation failed: {error}; receipt: {result_path}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
