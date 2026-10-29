#!/usr/bin/env python3
"""Run all bounded portable cases from exact committed assembly on one gfx1250.

Example (from any checkout):
  python3 tests/gfx1250/hardware/portable_run.py --host mi400 --device 1 \
      --result /tmp/hardware-portable.json

The remote directory is unique and retained for inspection. This script never
compiles HIP source to produce a substitute GPU module, retargets assembly,
runs unsafe mutations, resets a device, or changes repository manifests.
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
import time


EXPECTED_OUTPUTS = {
    "portable_relu": 64,
    "portable_sigmoid": 64,
    "portable_silu": 64,
    "portable_swiglu": 64,
    "portable_rope": 32,
    "portable_reduction": 2,
    "portable_softmax": 64,
    "portable_rmsnorm": 64,
    "portable_matvec": 4,
    "portable_gemm": 32,
    "portable_gemm_add_silu": 32,
    "portable_bitdelta": 8,
    "portable_bitdelta_batched": 16,
    "portable_convolution": 18,
    "portable_mamba_state": 16,
    "portable_mamba_scan": 16,
    "portable_flash_attention": 10,
    "portable_forgetting_attention": 10,
    "portable_sage_attention": 8,
    "portable_sinkhorn": 2,
}
# The CPU oracle implements exactly these shapes and ABIs. Check them before
# launching, rather than allowing a changed manifest to underfill kernarg storage
# or cause a reference bounds failure only after device execution.
EXPECTED_ARRAYS = {
    "portable_relu": (("x", 64, "in", 65536), ("out", 64, "out", 131072)),
    "portable_sigmoid": (("x", 64, "in", 65536), ("out", 64, "out", 131072)),
    "portable_silu": (("x", 64, "in", 65536), ("out", 64, "out", 131072)),
    "portable_swiglu": (
        ("gate", 64, "in", 65536),
        ("value", 64, "in", 131072),
        ("out", 64, "out", 196608),
    ),
    "portable_rope": (
        ("x", 32, "in", 65536),
        ("cosine", 32, "in", 131072),
        ("sine", 32, "in", 196608),
        ("out", 32, "out", 262144),
    ),
    "portable_reduction": (("x", 64, "in", 65536), ("out", 2, "out", 131072)),
    "portable_softmax": (("x", 64, "in", 65536), ("out", 64, "out", 131072)),
    "portable_rmsnorm": (
        ("x", 64, "in", 65536),
        ("weight", 64, "in", 131072),
        ("out", 64, "out", 196608),
    ),
    "portable_matvec": (
        ("a", 128, "in", 65536),
        ("x", 32, "in", 131072),
        ("out", 4, "out", 196608),
    ),
    "portable_gemm": (("a", 64, "in", 65536), ("b", 128, "in", 131072), ("out", 32, "out", 196608)),
    "portable_gemm_add_silu": (
        ("a", 64, "in", 65536),
        ("b", 128, "in", 131072),
        ("addend", 32, "in", 196608),
        ("out", 32, "out", 262144),
    ),
    "portable_bitdelta": (
        ("a", 64, "in", 65536),
        ("packed", 4, "index", 131072),
        ("out00", 2, "out", 196608),
        ("out01", 2, "out", 196616),
        ("out02", 2, "out", 196624),
        ("out03", 2, "out", 196632),
    ),
    "portable_bitdelta_batched": (
        ("a", 128, "in", 65536),
        ("packed", 8, "index", 131072),
        ("out00", 2, "out", 196608),
        ("out01", 2, "out", 196616),
        ("out02", 2, "out", 196624),
        ("out03", 2, "out", 196632),
        ("out10", 2, "out", 196640),
        ("out11", 2, "out", 196648),
        ("out12", 2, "out", 196656),
        ("out13", 2, "out", 196664),
    ),
    "portable_convolution": (
        ("x", 50, "in", 65536),
        ("weight", 36, "in", 131072),
        ("out", 18, "out", 196608),
    ),
    "portable_mamba_state": (
        ("x", 32, "in", 65536),
        ("b", 32, "in", 131072),
        ("dt", 8, "in", 196608),
        ("da", 8, "in", 262144),
        ("states", 16, "out", 327680),
    ),
    "portable_mamba_scan": (
        ("cb", 16, "in", 65536),
        ("x", 32, "in", 131072),
        ("c", 8, "in", 196608),
        ("prev", 16, "in", 262144),
        ("dt", 8, "in", 327680),
        ("da", 8, "in", 393216),
        ("out", 8, "out", 458752),
        ("out_x", 8, "out", 524288),
    ),
    "portable_flash_attention": (
        ("q", 8, "in", 65536),
        ("k", 32, "in", 131072),
        ("v", 32, "in", 196608),
        ("out", 8, "out", 262144),
        ("lse", 2, "out", 327680),
    ),
    "portable_forgetting_attention": (
        ("q", 8, "in", 65536),
        ("k", 32, "in", 131072),
        ("v", 32, "in", 196608),
        ("log_lambda", 8, "in", 262144),
        ("out", 8, "out", 327680),
        ("lse", 2, "out", 393216),
    ),
    "portable_sage_attention": (
        ("q", 8, "in", 65536),
        ("k", 32, "in", 131072),
        ("v", 32, "in", 196608),
        ("q_scale", 1, "in", 262144),
        ("k_scale", 2, "in", 327680),
        ("out", 8, "out", 393216),
    ),
    "portable_sinkhorn": (
        ("x", 8, "in", 65536),
        ("y", 32, "in", 131072),
        ("f_hat", 2, "in", 196608),
        ("g_hat", 8, "in", 262144),
        ("log_b", 8, "in", 327680),
        ("f_out", 2, "out", 393216),
    ),
}
EXPECTED_PARAMS = {
    "portable_relu": ("ptr:x", "ptr:out"),
    "portable_sigmoid": ("ptr:x", "ptr:out"),
    "portable_silu": ("ptr:x", "ptr:out"),
    "portable_swiglu": ("ptr:gate", "ptr:value", "ptr:out"),
    "portable_rope": ("ptr:x", "ptr:cosine", "ptr:sine", "ptr:out"),
    "portable_reduction": ("ptr:x", "ptr:out"),
    "portable_softmax": ("ptr:x", "ptr:out"),
    "portable_rmsnorm": ("ptr:x", "ptr:weight", "ptr:out"),
    "portable_matvec": ("ptr:a", "ptr:x", "ptr:out"),
    "portable_gemm": ("ptr:a", "ptr:b", "ptr:out"),
    "portable_gemm_add_silu": ("ptr:a", "ptr:b", "ptr:addend", "ptr:out"),
    "portable_bitdelta": ("ptr:a", "ptr:packed", "ptr:out00"),
    "portable_bitdelta_batched": ("ptr:a", "ptr:packed", "ptr:out00"),
    "portable_convolution": ("ptr:x", "ptr:weight", "ptr:out"),
    "portable_mamba_state": ("ptr:x", "ptr:b", "ptr:dt", "ptr:da", "ptr:states"),
    "portable_mamba_scan": (
        "ptr:cb",
        "ptr:x",
        "ptr:c",
        "ptr:prev",
        "ptr:dt",
        "ptr:da",
        "ptr:out",
        "ptr:out_x",
    ),
    "portable_flash_attention": ("ptr:q", "ptr:k", "ptr:v", "ptr:out", "ptr:lse"),
    "portable_forgetting_attention": (
        "ptr:q",
        "ptr:k",
        "ptr:v",
        "ptr:log_lambda",
        "ptr:out",
        "ptr:lse",
    ),
    "portable_sage_attention": ("ptr:q", "ptr:k", "ptr:v", "ptr:q_scale", "ptr:k_scale", "ptr:out"),
    "portable_sinkhorn": ("ptr:x", "ptr:y", "ptr:f_hat", "ptr:g_hat", "ptr:log_b", "ptr:f_out"),
}

INPUT_FILES = (
    "portable-cases.json",
    "fixtures/native-portable-workloads.hip",
    "fixtures/native-portable-workloads.s",
    "hardware/portable.cpp",
    "hardware/portable_run.py",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def integer(value: object, label: str, minimum: int = 0) -> int:
    if type(value) is not int or value < minimum:
        raise ValueError(f"{label} must be an integer >= {minimum}")
    return value


def validate_manifest(directory: Path) -> list[dict]:
    data = json.loads((directory / "portable-cases.json").read_text())
    if data.get("schema_version") != 1 or data.get("target") != "gfx1250":
        raise ValueError("expected gfx1250 portable manifest schema 1")
    cases = data.get("cases")
    if not isinstance(cases, list) or len(cases) != len(EXPECTED_OUTPUTS):
        raise ValueError("all 20 portable cases are mandatory")
    names = [case.get("kernel") for case in cases]
    if len(set(names)) != len(names) or set(names) != set(EXPECTED_OUTPUTS):
        raise ValueError("portable case selection must contain each required kernel exactly once")
    for case in cases:
        kernel = case["kernel"]
        if case.get("required") is not True:
            raise ValueError(f"{kernel}: required case cannot be disabled")
        for key in ("block", "grid"):
            dimensions = case.get(key)
            if not isinstance(dimensions, list) or len(dimensions) != 3:
                raise ValueError(f"{kernel}: {key} must have three dimensions")
            for value in dimensions:
                integer(value, f"{kernel}.{key}", 1)
        # These kernels use threadIdx only. Multiple blocks race on the same
        # outputs, and a different block would change the promised coverage.
        expected_block = (
            [64, 1, 1]
            if kernel
            in {
                "portable_relu",
                "portable_sigmoid",
                "portable_silu",
                "portable_swiglu",
                "portable_softmax",
                "portable_rmsnorm",
            }
            else [32, 1, 1]
        )
        if (
            case["block"] != expected_block
            or case["grid"] != [1, 1, 1]
            or case.get("workgroup") != [0, 0, 0]
        ):
            raise ValueError(f"{kernel}: launch differs from the complete pinned footprint")
        arrays = case.get("arrays")
        if not isinstance(arrays, list) or not arrays:
            raise ValueError(f"{kernel}: arrays missing")
        intervals, array_names, outputs = [], set(), 0
        for array in arrays:
            name = array.get("name")
            if not isinstance(name, str) or not name.isidentifier() or name in array_names:
                raise ValueError(f"{kernel}: duplicate or invalid array name")
            array_names.add(name)
            start = integer(array.get("base_address"), f"{kernel}.{name}.base_address")
            length = integer(array.get("length"), f"{kernel}.{name}.length", 1)
            if (
                array.get("element_size") != 4
                or start % 4
                or array.get("kind") not in {"in", "index", "out"}
            ):
                raise ValueError(f"{kernel}.{name}: only aligned F32/u32 arrays are supported")
            intervals.append((start, start + length * 4))
            if array["kind"] == "out":
                outputs += length
        intervals.sort()
        if any(left[1] > right[0] for left, right in zip(intervals, intervals[1:])):
            raise ValueError(f"{kernel}: overlapping declared arrays")
        if intervals[-1][1] - intervals[0][0] > 1 << 20:
            raise ValueError(f"{kernel}: arena exceeds one MiB")
        if outputs != EXPECTED_OUTPUTS[kernel] or case.get("expected_outputs") != outputs:
            raise ValueError(f"{kernel}: incomplete declared output footprint")
        actual_layout = tuple(
            (a["name"], a["length"], a["kind"], a["base_address"]) for a in arrays
        )
        if actual_layout != EXPECTED_ARRAYS[kernel]:
            raise ValueError(f"{kernel}: array layout differs from the CPU oracle contract")
        params = case.get("params")
        if not isinstance(params, list) or not params:
            raise ValueError(f"{kernel}: pointer parameters missing")
        for parameter in params:
            if (
                not isinstance(parameter, str)
                or not parameter.startswith("ptr:")
                or parameter[4:] not in array_names
            ):
                raise ValueError(f"{kernel}: unsupported or unresolved parameter {parameter!r}")
        if tuple(params) != EXPECTED_PARAMS[kernel]:
            raise ValueError(f"{kernel}: parameter length/order differs from the native kernel ABI")
        for field, path in (
            ("source", "fixtures/native-portable-workloads.hip"),
            ("assembly", "fixtures/native-portable-workloads.s"),
        ):
            if case.get(field) != path or case.get(field + "_sha256") != sha256(directory / path):
                raise ValueError(f"{kernel}: {field} differs from the pinned exact artifact")
    return cases


def manifest_header(cases: list[dict]) -> str:
    lines = [
        "// Generated topology only; numerical reference code is handwritten.",
        "static const std::vector<CaseSpec> kCases = {",
    ]
    for case in cases:
        arrays = ",".join(
            "{"
            + ",".join(
                (
                    json.dumps(a["name"]),
                    str(a["base_address"]) + "ULL",
                    str(a["length"]),
                    json.dumps(a["kind"]),
                )
            )
            + "}"
            for a in case["arrays"]
        )
        params = ",".join(json.dumps(p[4:]) for p in case["params"])
        block = ",".join(map(str, case["block"]))
        grid = ",".join(map(str, case["grid"]))
        lines.append(
            "  {"
            + json.dumps(case["kernel"])
            + ",{"
            + block
            + "},{"
            + grid
            + "},{"
            + arrays
            + "},{"
            + params
            + "},"
            + str(case["expected_outputs"])
            + "},"
        )
    return "\n".join(lines + ["};", ""])


def checked_run(
    command: list[str],
    *,
    timeout: int,
    cwd: Path | None = None,
    env: dict | None = None,
    records: list[dict] | None = None,
) -> subprocess.CompletedProcess:
    start = time.monotonic()
    record = {"argv": command, "cwd": str(cwd) if cwd else None, "timeout_seconds": timeout}
    try:
        result = subprocess.run(
            command, cwd=cwd, env=env, capture_output=True, text=True, timeout=timeout
        )
        record.update(exit_code=result.returncode, stdout=result.stdout, stderr=result.stderr)
    except subprocess.TimeoutExpired as error:
        record.update(
            status="timeout", stdout=str(error.stdout or ""), stderr=str(error.stderr or "")
        )
        raise RuntimeError(f"command timed out: {shlex.join(command)}") from error
    finally:
        record["seconds"] = time.monotonic() - start
        if records is not None:
            records.append(record)
    if result.returncode:
        raise RuntimeError(
            f"command exited {result.returncode}: {shlex.join(command)}\n{result.stderr}"
        )
    return result


def validate_driver_result(result: dict, cases: list[dict], patterns: int) -> None:
    if result.get("status") != "pass" or result.get("patterns") != patterns:
        raise ValueError("driver did not report a complete successful execution")
    device = result.get("device", {})
    if device.get("architecture", "").split(":")[0] != "gfx1250" or device.get("wave_size") != 32:
        raise ValueError("driver result is not actual wave32 gfx1250")
    if result.get("reference_closed_form_checks") != 590:
        raise ValueError("CPU reference closed-form controls were incomplete")
    input_checks = (
        sum(a["length"] for case in cases for a in case["arrays"] if a["kind"] == "in") * patterns
    )
    if (
        result.get("input_pattern_checks") != input_checks
        or result.get("signed_alternation_checks") != 3
    ):
        raise ValueError("bounded finite input-pattern controls were incomplete")
    rows = result.get("cases")
    if (
        not isinstance(rows, list)
        or len(rows) != 20
        or {r.get("kernel") for r in rows} != set(EXPECTED_OUTPUTS)
    ):
        raise ValueError("driver omitted or duplicated mandatory cases")
    totals = dict(
        launches=0,
        outputs=0,
        unchanged_input_bytes=0,
        unchanged_gap_bytes=0,
        unchanged_guard_bytes=0,
    )
    by_name = {c["kernel"]: c for c in cases}
    for row in rows:
        case = by_name[row["kernel"]]
        starts = [a["base_address"] for a in case["arrays"]]
        ends = [a["base_address"] + 4 * a["length"] for a in case["arrays"]]
        input_bytes = sum(4 * a["length"] for a in case["arrays"] if a["kind"] != "out")
        array_bytes = sum(4 * a["length"] for a in case["arrays"])
        expected = dict(
            launches=patterns,
            outputs=case["expected_outputs"] * patterns,
            unchanged_input_bytes=input_bytes * patterns,
            unchanged_gap_bytes=(max(ends) - min(starts) - array_bytes) * patterns,
            unchanged_guard_bytes=8192 * patterns,
        )
        exact = {
            "portable_relu",
            "portable_reduction",
            "portable_matvec",
            "portable_gemm",
            "portable_bitdelta",
            "portable_bitdelta_batched",
            "portable_convolution",
        }
        tolerances = (
            (0, 0)
            if row["kernel"] in exact
            else (2e-7, 2e-6)
            if row["kernel"] == "portable_rope"
            else (2e-6, 2e-5)
        )
        if (row.get("atol"), row.get("rtol")) != tolerances:
            raise ValueError(f"{row['kernel']}: comparison tolerance changed")
        for key in ("max_absolute_error", "max_relative_error"):
            error = row.get(key)
            if type(error) not in (int, float) or not math.isfinite(error) or error < 0:
                raise ValueError(f"{row['kernel']}: invalid error metric")
        for key, value in expected.items():
            if type(row.get(key)) is not int or row[key] != value:
                raise ValueError(f"{row['kernel']}: incomplete {key}")
            totals[key] += value
    if result.get("totals") != totals or totals["outputs"] != 590 * patterns:
        raise ValueError("aggregate output/input/gap/guard accounting mismatch")


def run_local(args: argparse.Namespace, directory: Path, result_path: Path) -> None:
    receipt = {
        "schema_version": 1,
        "status": "not_completed",
        "target": "gfx1250",
        "scope": "All 20 bounded F32 portable cases; not original full PTX shapes or dtypes.",
        "source_revision": args.revision,
        "timestamp_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "selected_physical_device": args.device,
        "commands": [],
        "input_artifacts": {p: sha256(directory / p) for p in INPUT_FILES},
    }
    records = receipt["commands"]
    build = Path(tempfile.mkdtemp(prefix="portable-build-", dir=directory))
    receipt["build_directory"] = str(build)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        cases = validate_manifest(directory)
        receipt["case_configurations"] = [
            {
                key: case[key]
                for key in (
                    "kernel",
                    "block",
                    "grid",
                    "workgroup",
                    "dimensions",
                    "arrays",
                    "params",
                    "expected_outputs",
                )
            }
            for case in cases
        ]
        receipt["input_patterns"] = {
            "indices": list(range(args.patterns)),
            "definition": "input_value in the hashed host driver; pattern 0 zeros, pattern 1 signed alternating, remaining bounded asymmetric coordinates; positive dt/scales and separately generated cosine/sine override those defaults",
            "index_arrays": "exact raw u32 i=i, unchanged across patterns",
            "reference": "ordinary CPU double arithmetic on the actual decoded F32 inputs; natural exp/log; exact decoded F32 RMS epsilon",
            "coverage": "every configured output and every non-output byte in every launch",
        }
        # Visibility is set only for the child; conflicting inherited restrictions
        # are rejected rather than accidentally selecting a different physical GPU.
        conflicts = [
            key
            for key in ("ROCR_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL")
            if key in os.environ
        ]
        if conflicts:
            raise ValueError("remove conflicting device selectors: " + ", ".join(conflicts))
        env = dict(os.environ, HIP_VISIBLE_DEVICES=str(args.device))
        receipt["device_environment"] = {"HIP_VISIBLE_DEVICES": str(args.device)}
        receipt["host"] = checked_run(["hostname"], timeout=10, records=records).stdout.strip()
        receipt["uname"] = checked_run(["uname", "-a"], timeout=10, records=records).stdout.strip()
        version_file = Path("/sys/module/amdgpu/version")
        receipt["amdgpu_module_version"] = (
            version_file.read_text().strip() if version_file.exists() else "not_exposed"
        )
        rocm = Path(args.rocm).resolve(strict=True)
        tools = {name: rocm / "llvm/bin" / name for name in ("llvm-mc", "ld.lld", "clang++")}
        receipt["rocm_directory"] = str(rocm)
        receipt["toolchains"] = {}
        for name, tool in tools.items():
            version = checked_run(
                [str(tool), "--version"], timeout=15, records=records
            ).stdout.strip()
            receipt["toolchains"][name] = {
                "path": str(tool.resolve()),
                "sha256": sha256(tool),
                "version": version,
            }
        rocminfo = rocm / "bin/rocminfo"
        info = checked_run([str(rocminfo)], timeout=30, env=env, records=records)
        (build / "rocminfo.txt").write_text(info.stdout)
        header = build / "portable_manifest.hpp"
        header.write_text(manifest_header(cases))
        assembly = directory / "fixtures/native-portable-workloads.s"
        object_file, code_object = build / "portable.o", build / "portable.hsaco"
        driver = build / "portable_driver"
        checked_run(
            [
                str(tools["llvm-mc"]),
                "--triple=amdgcn-amd-amdhsa",
                "--mcpu=gfx1250",
                "--filetype=obj",
                str(assembly),
                "-o",
                str(object_file),
            ],
            timeout=60,
            records=records,
        )
        checked_run(
            [str(tools["ld.lld"]), "-shared", str(object_file), "-o", str(code_object)],
            timeout=60,
            records=records,
        )
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
                "-I" + str(build),
                str(directory / "hardware/portable.cpp"),
                "-L" + str(rocm / "lib"),
                "-lamdhip64",
                "-Wl,-rpath," + str(rocm / "lib"),
                "-o",
                str(driver),
            ],
            timeout=120,
            records=records,
        )
        linking = checked_run(["ldd", str(driver)], timeout=15, env=env, records=records)
        runtime_lines = [line for line in linking.stdout.splitlines() if "libamdhip64.so" in line]
        if len(runtime_lines) != 1 or "=>" not in runtime_lines[0]:
            raise RuntimeError("could not identify the actually resolved HIP runtime library")
        runtime_library = Path(runtime_lines[0].split("=>", 1)[1].split()[0]).resolve(strict=True)
        receipt["toolchains"]["HIP_runtime_library"] = {
            "path": str(runtime_library),
            "sha256": sha256(runtime_library),
        }
        receipt["built_artifacts"] = {
            p.name: sha256(p)
            for p in (header, object_file, code_object, driver, build / "rocminfo.txt")
        }
        completed = checked_run(
            [str(driver), str(code_object), str(args.patterns)],
            timeout=args.timeout,
            env=env,
            records=records,
        )
        (build / "driver.stdout.json").write_text(completed.stdout)
        (build / "driver.stderr.log").write_text(completed.stderr)
        result = json.loads(completed.stdout)
        validate_driver_result(result, cases, args.patterns)
        receipt["validation"] = result
        receipt["status"] = "pass"
        # Recheck every input artifact after execution, including the module source.
        if receipt["input_artifacts"] != {p: sha256(directory / p) for p in INPUT_FILES}:
            raise RuntimeError("a source artifact changed during execution")
    except Exception as error:
        receipt["status"] = "fail"
        receipt["error"] = str(error)
        raise
    finally:
        result_path.write_text(json.dumps(receipt, indent=2) + "\n")


def validate_revision(directory: Path, revision: str) -> None:
    repository = Path(
        checked_run(
            ["git", "rev-parse", "--show-toplevel"], cwd=directory, timeout=10
        ).stdout.strip()
    )
    for relative in INPUT_FILES:
        path = directory / relative
        tracked = path.relative_to(repository).as_posix()
        committed = subprocess.run(
            ["git", "show", f"{revision}:{tracked}"],
            cwd=repository,
            capture_output=True,
            timeout=10,
            check=True,
        ).stdout
        if hashlib.sha256(committed).hexdigest() != sha256(path):
            raise ValueError(f"{tracked}: does not match the stated source revision")


def run_remote(args: argparse.Namespace, directory: Path, result_path: Path) -> None:
    # Validate before uploading or executing anything. Only the five pinned input
    # files are copied. No other checkout, kernel source, or host process is touched.
    validate_manifest(directory)
    validate_revision(directory, args.revision)
    remote = checked_run(
        ["ssh", args.host, "mktemp -d /tmp/ptx-verifier-gfx1250-portable.XXXXXX"], timeout=45
    ).stdout.strip()
    if not remote.startswith("/tmp/ptx-verifier-gfx1250-portable.") or any(
        c.isspace() for c in remote
    ):
        raise RuntimeError("unexpected remote temporary directory")
    checked_run(
        [
            "ssh",
            args.host,
            "mkdir -p "
            + shlex.quote(remote + "/fixtures")
            + " "
            + shlex.quote(remote + "/hardware"),
        ],
        timeout=45,
    )
    for relative in INPUT_FILES:
        checked_run(
            ["scp", str(directory / relative), args.host + ":" + remote + "/" + relative],
            timeout=45,
        )
    remote_result = remote + "/hardware-portable.json"
    command = [
        "python3",
        remote + "/hardware/portable_run.py",
        "--local",
        "--fixture-directory",
        remote,
        "--device",
        str(args.device),
        "--patterns",
        str(args.patterns),
        "--timeout",
        str(args.timeout),
        "--rocm",
        args.rocm,
        "--revision",
        args.revision,
        "--result",
        remote_result,
    ]
    run_error = None
    try:
        checked_run(["ssh", args.host, shlex.join(command)], timeout=args.timeout + 300)
    except Exception as error:
        run_error = error
    result_path.parent.mkdir(parents=True, exist_ok=True)
    checked_run(["scp", args.host + ":" + remote_result, str(result_path)], timeout=45)
    receipt = json.loads(result_path.read_text())
    receipt["remote_execution"] = {
        "ssh_host": args.host,
        "directory": remote,
        "argv": command,
        "source_revision_validated_before_transfer": True,
    }
    result_path.write_text(json.dumps(receipt, indent=2) + "\n")
    if run_error:
        raise run_error
    validate_driver_result(receipt["validation"], validate_manifest(directory), args.patterns)
    if receipt.get("status") != "pass":
        raise RuntimeError("remote receipt is not successful")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--host", help="SSH host with real gfx1250 hardware")
    mode.add_argument("--local", action="store_true", help="execute on this host")
    parser.add_argument(
        "--fixture-directory", type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument(
        "--device",
        type=int,
        required=True,
        help="physical ordinal selected only with HIP_VISIBLE_DEVICES",
    )
    parser.add_argument("--patterns", type=int, default=17)
    parser.add_argument(
        "--timeout", type=int, default=180, help="seconds allowed for the entire driver run"
    )
    parser.add_argument("--rocm", default="/opt/rocm")
    parser.add_argument(
        "--revision", help="pinned source revision; automatically detected for SSH invocation"
    )
    parser.add_argument("--result", type=Path, required=True)
    args = parser.parse_args()
    if not 1 <= args.patterns <= 256 or args.device < 0 or args.timeout < 1:
        parser.error("require patterns 1..256, nonnegative device, positive timeout")
    directory = args.fixture_directory.resolve(strict=True)
    if args.revision is None:
        args.revision = checked_run(
            ["git", "rev-parse", "HEAD"], cwd=directory, timeout=10
        ).stdout.strip()
    if len(args.revision) != 40 or any(c not in "0123456789abcdef" for c in args.revision):
        parser.error("revision must be an exact 40-character git object ID")
    result = args.result.resolve()
    try:
        if args.local:
            run_local(args, directory, result)
        else:
            run_remote(args, directory, result)
        print(f"PASS all 20 portable cases, {590 * args.patterns} outputs; receipt: {result}")
        return 0
    except Exception as error:
        print(f"portable hardware validation failed: {error}; receipt: {result}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
