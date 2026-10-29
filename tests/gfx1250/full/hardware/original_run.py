#!/usr/bin/env python3
"""Independently replay W01-W18 from exact original-shape gfx1250 assembly.

This gate covers 18 of the 32 original workload variants. It does not certify
graph safety, mathematical equivalence, or the remaining 14 variants.
"""
from __future__ import annotations

import argparse
import datetime as dt
from dataclasses import dataclass
import hashlib
import json
import math
import os
import re
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


@dataclass(frozen=True)
class Profile:
    contract: dict[str, tuple[int, int, int]]
    modules: tuple[str, ...]
    driver: str
    runner: str
    files: tuple[str, ...]
    patterns: int
    minimum_patterns: int = 1
    maximum_patterns: int = 64
    gaps: dict[str, int] | None = None
    original_outputs: dict[str, int] | None = None


BASIC = Profile(CONTRACT, ("f16", "f8"), "full/hardware/original.cpp",
                "full/hardware/original_run.py", INPUTS, 9)


def validate_result(result: dict, patterns: int, profile: Profile = BASIC) -> None:
    if (result.get("status"), result.get("architecture"), result.get("wave_size"),
            result.get("patterns")) != ("pass", "gfx1250", 32, patterns):
        raise ValueError("driver did not report complete real gfx1250 execution")
    if result.get("reference_controls") != "pass":
        raise ValueError("independent numerical reference controls did not pass")
    rows = result.get("cases")
    if not isinstance(rows, list) or len(rows) != len(profile.contract):
        raise ValueError("all original variants in the selected gate are mandatory")
    if {r.get("kernel") for r in rows} != set(profile.contract):
        raise ValueError("driver omitted or duplicated an original variant")
    for row in rows:
        outputs, inputs, buffers = profile.contract[row["kernel"]]
        accounting = {
            "outputs": outputs * patterns, "launches": patterns,
            "unchanged_input_bytes": inputs * patterns,
            "unchanged_guard_bytes": buffers * 8192 * patterns,
        }
        if profile.gaps is not None:
            accounting["unchanged_gap_bytes"] = profile.gaps[row["kernel"]] * patterns
        if profile.original_outputs is not None:
            accounting["original_outputs"] = profile.original_outputs[row["kernel"]] * patterns
        for key, expected in accounting.items():
            if type(row.get(key)) is not int or row[key] != expected:
                raise ValueError(f"{row['kernel']}: incomplete {key}")
        error = row.get("max_absolute_error")
        if type(error) not in (int, float) or not math.isfinite(error) or error < 0:
            raise ValueError("invalid numerical error metric")


def validate_device_identity(identity: dict) -> None:
    if not isinstance(identity, dict):
        raise ValueError("selected HIP device identity must be an object")
    for name, expected in (
        ("logical_ordinal", 0),
        ("visible_device_count", 1),
        ("wave_size", 32),
    ):
        if type(identity.get(name)) is not int or identity[name] != expected:
            raise ValueError(f"unexpected selected HIP device {name}")
    architecture = identity.get("architecture")
    if not isinstance(architecture, str) or architecture.split(":", 1)[0] != "gfx1250":
        raise ValueError("actual selected HIP device is not gfx1250")
    if not isinstance(identity.get("name"), str) or not identity["name"].strip():
        raise ValueError("actual selected HIP device name is missing")
    pci = identity.get("pci_bus_id")
    if not isinstance(pci, str) or not re.fullmatch(
        r"[0-9a-fA-F]{4,8}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]", pci
    ):
        raise ValueError(
            "actual selected HIP device PCI identity is missing or malformed"
        )
    for name in ("hip_runtime_version", "hip_driver_version"):
        if type(identity.get(name)) is not int or identity[name] <= 0:
            raise ValueError(f"actual HIP {name} is missing")
    status, value, error = (
        identity.get(name) for name in ("uuid_status", "uuid_hex", "uuid_hip_error")
    )
    if type(error) is not int or error < 0:
        raise ValueError("HIP UUID query status is missing")
    if status == "available":
        if (
            error != 0
            or not isinstance(value, str)
            or not re.fullmatch(r"[0-9a-f]{32}", value)
            or int(value, 16) == 0
        ):
            raise ValueError("actual selected HIP device UUID is invalid")
    elif status == "all_zero":
        if error != 0 or value is not None:
            raise ValueError(
                "all-zero UUID must be disclosed without claiming an identifier"
            )
    elif status == "not_supported":
        if error == 0 or value is not None:
            raise ValueError("unsupported UUID query must be disclosed")
    else:
        raise ValueError("HIP UUID availability is missing")


def probe_device_identity(
    tools: dict, rocm: Path, directory: Path, build: Path, env: dict, records: list
) -> tuple[dict, list[Path]]:
    source, probe = build / "device_identity.cpp", build / "device_identity"
    source.write_text("""#define VOLTA_HARDWARE_IDENTITY_ONLY
#include "original_common.hpp"
int main() {
  try {
    std::puts(selected_device_identity_json().c_str());
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "selected device identity failed: %s\\n", error.what());
    return 1;
  }
}
""")
    checked_run(
        [
            str(tools["clang++"]),
            "-std=c++17",
            "-O2",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-D__HIP_PLATFORM_AMD__",
            "-I" + str(rocm / "include"),
            "-I" + str(directory / "full/hardware"),
            str(source),
            "-L" + str(rocm / "lib"),
            "-lamdhip64",
            "-Wl,-rpath," + str(rocm / "lib"),
            "-o",
            str(probe),
        ],
        timeout=120,
        records=records,
    )
    result = checked_run([str(probe)], timeout=30, env=env, records=records)
    identity = json.loads(result.stdout)
    validate_device_identity(identity)
    return identity, [source, probe]


def built_artifact_hashes(
    driver: Path, modules: list[Path], identity_artifacts: list[Path]
) -> dict:
    if not modules or len(set(modules)) != len(modules):
        raise ValueError(
            "each exact assembly module must have an object/codeobject pair"
        )
    objects = [module.with_suffix(".o") for module in modules]
    return {
        path.name: sha256(path)
        for path in [driver, *objects, *modules, *identity_artifacts]
    }


def artifact_hashes(directory: Path, profile: Profile = BASIC) -> dict:
    return {p: sha256(directory / p) for p in profile.files}


def validate_revision(directory: Path, revision: str, profile: Profile = BASIC) -> None:
    repository = Path(checked_run(
        ["git", "rev-parse", "--show-toplevel"], cwd=directory, timeout=10
    ).stdout.strip())
    for relative in profile.files:
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
    for dtype in args.profile.modules:
        obj, module = build / f"{dtype}.o", build / f"{dtype}.hsaco"
        checked_run([str(tools["llvm-mc"]), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                     "--filetype=obj", str(directory / f"full/fixtures/original-{dtype}.s"),
                     "-o", str(obj)], timeout=60, records=records)
        checked_run([str(tools["ld.lld"]), "-shared", str(obj), "-o", str(module)], timeout=60, records=records)
        objects.append(module)
    driver = build / "original_driver"
    checked_run([str(tools["clang++"]), "-std=c++17", "-O2", "-Wall", "-Wextra", "-Werror",
                 "-D__HIP_PLATFORM_AMD__", "-I" + str(rocm / "include"),
                 str(directory / args.profile.driver), "-L" + str(rocm / "lib"),
                 "-lamdhip64", "-Wl,-rpath," + str(rocm / "lib"), "-o", str(driver)],
                timeout=120, records=records)
    linking = checked_run(["ldd", str(driver)], timeout=15, env=env, records=records)
    runtime = [line for line in linking.stdout.splitlines() if "libamdhip64.so" in line]
    if len(runtime) != 1 or "=>" not in runtime[0]:
        raise ValueError("could not identify the resolved HIP runtime")
    library = Path(runtime[0].split("=>", 1)[1].split()[0]).resolve(strict=True)
    receipt["toolchains"]["HIP_runtime_library"] = {"path": str(library), "sha256": sha256(library)}
    identity, identity_artifacts = probe_device_identity(tools, rocm, directory, build, env, records)
    receipt["device_identity"] = identity
    receipt["built_artifacts"] = built_artifact_hashes(driver, objects, identity_artifacts)
    checked_run([str(driver), "--cpu-only"], timeout=15, env=env, records=records)
    completed = checked_run([str(driver), *map(str, objects), str(args.patterns)],
                            timeout=args.timeout, env=env, records=records)
    result = json.loads(completed.stdout)
    validate_result(result, args.patterns, args.profile)
    receipt["validation"] = result


def run_remote(args: argparse.Namespace, directory: Path, receipt: dict) -> None:
    validate_revision(directory, args.revision, args.profile)
    remote = checked_run(["ssh", args.host, "mktemp -d /tmp/ptx-gfx1250-original.XXXXXX"], timeout=45).stdout.strip()
    if not remote.startswith("/tmp/ptx-gfx1250-original.") or any(c.isspace() for c in remote):
        raise ValueError("unexpected remote staging directory")
    parents = sorted({str(Path(p).parent) for p in args.profile.files})
    checked_run(["ssh", args.host, shlex.join(["mkdir", "-p", *[remote + "/" + p for p in parents]])], timeout=45)
    for relative in args.profile.files:
        checked_run(["scp", str(directory / relative), args.host + ":" + remote + "/" + relative], timeout=45)
    command = ["python3", remote + "/" + args.profile.runner, "--local",
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
    validate_result(receipt["validation"], args.patterns, args.profile)


def main(profile: Profile = BASIC) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--host")
    mode.add_argument("--local", action="store_true")
    parser.add_argument("--fixture-directory", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--result", type=Path, required=True)
    parser.add_argument("--device", type=int, required=True)
    parser.add_argument("--patterns", type=int, default=profile.patterns)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--rocm", default="/opt/rocm")
    parser.add_argument("--revision")
    parser.add_argument("--invocation-id", help=argparse.SUPPRESS)
    args = parser.parse_args()
    args.profile = profile
    args.invocation_id = args.invocation_id or str(uuid.uuid4())
    result_path = args.result.resolve()
    directory = args.fixture_directory.resolve()
    if result_path in {directory / p for p in profile.files}:
        parser.error("receipt must not overwrite an input artifact")
    receipt = {"schema_version": 1, "status": "incomplete", "invocation_id": args.invocation_id,
               "timestamp_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "commands": [],
               "scope": "Exact-assembly numerical hardware gate for the enumerated original variants only; graph/equivalence and other workload variants require separate gates."}
    try:
        # Invalidate old success before preflight, SSH, build, or kernel launch.
        write_receipt(result_path, receipt)
        if not profile.minimum_patterns <= args.patterns <= profile.maximum_patterns or args.device < 0 or args.timeout < 1:
            raise ValueError("require the profile's pattern count bounds, nonnegative device, positive timeout")
        if str(uuid.UUID(args.invocation_id)) != args.invocation_id:
            raise ValueError("invocation ID must be a canonical UUID")
        args.revision = args.revision or checked_run(["git", "rev-parse", "HEAD"], cwd=directory, timeout=10).stdout.strip()
        if len(args.revision) != 40 or any(c not in "0123456789abcdef" for c in args.revision):
            raise ValueError("revision must be an exact git object ID")
        receipt.update(source_revision=args.revision, input_artifacts=artifact_hashes(directory, profile),
                       selected_physical_device=args.device, native_validation_contract=profile.contract,
                       original_output_projection=profile.original_outputs)
        if args.local:
            run_local(args, directory, receipt)
        else:
            run_remote(args, directory, receipt)
        if artifact_hashes(directory, profile) != receipt["input_artifacts"]:
            raise ValueError("source artifacts changed during execution")
        receipt["status"] = "pass"
        write_receipt(result_path, receipt)
        print(f"PASS {len(profile.contract)} original variants; receipt: {result_path}")
        return 0
    except Exception as error:
        receipt.update(status="fail", error=str(error))
        write_receipt(result_path, receipt)
        print(f"original workload validation failed: {error}; receipt: {result_path}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
