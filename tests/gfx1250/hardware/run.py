#!/usr/bin/env python3
"""Build and execute exact positive gfx1250 assembly; never runs mutants.

Run on the GPU host from a checkout or a copied tests/gfx1250 subtree.
Only the host-only C++ driver is compiled. Fixture assembly bytes are unchanged.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
FIXTURES = HERE.parent / "fixtures"
UNITS = (
    "native-copy-add",
    "native-lds-ids",
    "native-wmma",
    "native-gemm-pipeline",
    "native-tensor-roundtrip",
    "native-attention-small",
    "native-transpose-high64",
    "native-wmma-basis",
    "native-wmma-values",
)
# Counts refer to executed kernels and every expected output, never host self-checks.
SUITES = {
    "copy": {
        "launches": 540,
        "output_checks": 40500,
        "blocks": [1, 31, 32, 33, 63, 64, 65, 96, 128, 256],
        "lengths": [1, 31, 32, 33, 63, 64, 65, 129, 257],
        "seeds": 3,
        "atol": 0,
        "rtol": 0,
    },
    "lds": {
        "launches": 51,
        "output_checks": 1530,
        "blocks": {"exchange": [64, 1, 1], "reduce": [64, 1, 1], "ids_3d": [4, 3, 2]},
        "seeds": 17,
        "atol": 0,
        "rtol": 0,
    },
    "wmma_f32": {
        "launches": 17,
        "output_checks": 4352,
        "block": [32, 1, 1],
        "m": 16,
        "n": 16,
        "k": 4,
        "seeds": 17,
        "atol": 0,
        "rtol": 0,
    },
    "wmma_f16": {
        "launches": 17,
        "output_checks": 4352,
        "block": [32, 1, 1],
        "m": 16,
        "n": 16,
        "k": 32,
        "seeds": 17,
        "atol": 0,
        "rtol": 0,
    },
    "wmma_bf16": {
        "launches": 17,
        "output_checks": 4352,
        "block": [32, 1, 1],
        "m": 16,
        "n": 16,
        "k": 32,
        "seeds": 17,
        "atol": 0,
        "rtol": 0,
    },
    "basis": {
        "launches": 2176,
        "output_checks": 557056,
        "block": [32, 1, 1],
        "selected_rows_or_columns": 16,
        "both_operand_sides": True,
        "depths": {"f32": 4, "f16": 32, "bf16": 32},
        "atol": 0,
        "rtol": 0,
    },
    "values": {
        "launches": 51,
        "output_checks": 13056,
        "block": [32, 1, 1],
        "seeds": 17,
        "formats": ["f32", "f16", "bf16"],
        "atol": 0,
        "rtol": 0,
    },
    "gemm": {
        "launches": 17,
        "output_checks": 8704,
        "block": [64, 1, 1],
        "m": 32,
        "n": 16,
        "k": 64,
        "stages": 2,
        "seeds": 17,
        "atol": 0,
        "rtol": 0,
    },
    "tensor": {
        "launches": 17,
        "output_checks": 2176,
        "block": [64, 1, 1],
        "elements": 128,
        "stages": 2,
        "tensor_operations_per_launch": 4,
        "seeds": 17,
        "atol": 0,
        "rtol": 0,
    },
    "attention": {
        "launches": 9,
        "output_checks": 4608,
        "block": [32, 1, 1],
        "q": 16,
        "t": 32,
        "d": 32,
        "seeds": 9,
        "atol": 1e-5,
        "rtol": 1e-4,
    },
    "transpose": {
        "launches": 17,
        "output_checks": 1088,
        "block": [32, 1, 1],
        "rows": 8,
        "columns": 8,
        "seeds": 17,
        "comparison": "bit exact uint16",
    },
    "wide": {
        "launches": 686,
        "output_checks": 2744,
        "block": [1, 1, 1],
        "values_hex": [
            "0",
            "1",
            "ffffffff",
            "100000000",
            "7fffffffffffffff",
            "8000000000000000",
            "ffffffffffffffff",
        ],
        "combinations_per_signedness": 343,
        "signedness": ["unsigned", "signed"],
        "comparison": "bit exact uint64",
    },
}


CASE_KERNELS = {
    "copy": ["copy", "add"],
    "lds": ["exchange", "reduce", "ids_3d"],
    "wmma_f32": ["wmma_f32"],
    "wmma_f16": ["wmma_f16"],
    "wmma_bf16": ["wmma_bf16"],
    "gemm": ["gemm_pipeline_f16"],
    "tensor": ["tensor_roundtrip"],
    "attention": ["attention_small"],
    "transpose": ["transpose_8x8_b16"],
    "wide": ["high64_mul_mad", "high64_signed_mul_mad"],
    "basis": [],
    "values": [],
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def loaded_hip_runtime(linkage: str) -> Path:
    matches = [
        line.split("=>", 1)[1].strip().split(" ", 1)[0]
        for line in linkage.splitlines()
        if line.strip().startswith("libamdhip64.so") and "=>" in line
    ]
    if len(matches) != 1 or not Path(matches[0]).is_absolute():
        raise RuntimeError("ldd did not resolve exactly one absolute HIP runtime")
    return Path(matches[0]).resolve()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rocm", type=Path, default=Path("/opt/rocm"))
    parser.add_argument(
        "--device",
        type=int,
        default=0,
        help="physical GPU selected with HIP_VISIBLE_DEVICES",
    )
    parser.add_argument("--suite", choices=["all", *SUITES], default="all")
    parser.add_argument("--build-dir", type=Path)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument(
        "--source-commit",
        help="Fixture commit; required for copied subtrees without .git",
    )
    args = parser.parse_args()
    receipt = {
        "schema": "ptx-verifier.gfx1250.hardware-core.v1",
        "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "status": "INCOMPLETE",
        "requested_arguments": sys.argv[1:],
        "commands": [],
    }
    # Replace a previous receipt before operational validation. A failed new
    # invocation must never leave an earlier PASS masquerading as its result.
    write_receipt(args.receipt, receipt)
    try:
        return execute(args, parser, receipt)
    except BaseException as error:
        receipt["status"] = "INCOMPLETE"
        receipt["error"] = f"{type(error).__name__}: {error}"
        raise
    finally:
        receipt["finished_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
        write_receipt(args.receipt, receipt)


def write_receipt(path: Path, receipt: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
        temporary = Path(output.name)
        json.dump(receipt, output, indent=2)
        output.write("\n")
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def execute(args, parser, receipt: dict) -> int:
    if args.device < 0:
        parser.error("device must be nonnegative")
    for override in (
        "ROCR_VISIBLE_DEVICES",
        "CUDA_VISIBLE_DEVICES",
        "GPU_DEVICE_ORDINAL",
    ):
        if os.environ.get(override):
            parser.error(
                f"unset {override}: physical device selection must be unambiguous"
            )
    if any(name.startswith("HSA_OVERRIDE_GFX_VERSION") for name in os.environ):
        parser.error(
            "unset every HSA_OVERRIDE_GFX_VERSION override before device attestation"
        )
    if os.environ.get("LD_PRELOAD"):
        parser.error("unset LD_PRELOAD so the HIP runtime cannot be interposed")
    if args.source_commit:
        source_commit = args.source_commit
    else:
        try:
            source_commit = subprocess.check_output(
                ["git", "-C", str(HERE), "rev-parse", "HEAD"], text=True
            ).strip()
        except subprocess.CalledProcessError:
            parser.error("--source-commit is required outside a Git checkout")
    if len(source_commit) != 40 or any(
        ch not in "0123456789abcdef" for ch in source_commit
    ):
        parser.error("source commit must be a full lowercase 40-digit Git SHA")
    build = (
        args.build_dir or Path(tempfile.mkdtemp(prefix="ptx-gfx1250-core-build-"))
    ).resolve()
    build.mkdir(parents=True, exist_ok=True)
    rocm = args.rocm.resolve()
    env = dict(os.environ, HIP_VISIBLE_DEVICES=str(args.device))
    compiler = rocm / "llvm/bin/clang++"
    commands = receipt["commands"]

    def run(command: list[str], timeout: int = 120) -> str:
        started = time.monotonic()
        print("RUN " + json.dumps(command), flush=True)
        try:
            result = subprocess.run(
                command,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as error:

            def decoded(value):
                return (
                    value.decode(errors="replace")
                    if isinstance(value, bytes)
                    else (value or "")
                )

            commands.append(
                {
                    "argv": command,
                    "returncode": None,
                    "timed_out": True,
                    "timeout_seconds": timeout,
                    "elapsed_seconds": round(time.monotonic() - started, 6),
                    "stdout": decoded(error.stdout),
                    "stderr": decoded(error.stderr),
                }
            )
            raise
        record = {
            "argv": command,
            "returncode": result.returncode,
            "elapsed_seconds": round(time.monotonic() - started, 6),
            "stdout": result.stdout,
            "stderr": result.stderr,
        }
        commands.append(record)
        if result.returncode:
            raise RuntimeError(
                f"command failed ({result.returncode}): {command}\n{result.stdout}\n{result.stderr}"
            )
        return result.stdout

    manifest = json.loads((HERE.parent / "cases.json").read_text())
    if manifest["target"] != "gfx1250" or {
        case["kernel"] for case in manifest["cases"]
    } != {kernel for kernels in CASE_KERNELS.values() for kernel in kernels}:
        parser.error(
            "core harness mapping must cover exactly the native 14-case manifest"
        )
    for case in manifest["cases"]:
        if sha256(HERE.parent / case["assembly"]) != case["assembly_sha256"]:
            parser.error(
                "fixture assembly does not match the checked-in cases manifest"
            )
    receipt.update(
        {
            "schema": "ptx-verifier.gfx1250.hardware-core.v1",
            "fixture_source_commit": source_commit,
            "hostname": platform.node(),
            "platform": platform.platform(),
            "physical_device": args.device,
            "environment": {
                "HIP_VISIBLE_DEVICES": str(args.device),
                "LD_LIBRARY_PATH": env.get("LD_LIBRARY_PATH", ""),
            },
            "rocm_root": str(rocm),
            "fixtures_modified": False,
            "case_kernels": CASE_KERNELS,
            "hardware_addresses": "HIP-allocated pointers replace symbolic manifest bases; logical shapes and pitches are preserved.",
            "driver_sha256": sha256(HERE / "core.cpp"),
            "runner_sha256": sha256(Path(__file__)),
            "cases_sha256": sha256(HERE.parent / "cases.json"),
            "assembly": [],
            "commands": commands,
            "suites": [],
            "limitations": [
                "Only safe positive kernels are launched; no racy or deadlocking mutants.",
                "Finite deterministic inputs; no exhaustive IEEE exception or arbitrary descriptor validation.",
                "CPU references use ordinary logical matrices; fragment packing is confined to the ABI.",
                "Attention uses CPU double exp and disclosed absolute/relative tolerance; other outputs are exact.",
            ],
        }
    )
    runtime = rocm / "lib/libamdhip64.so"
    receipt["tools"] = [
        {"path": str(path.resolve()), "sha256": sha256(path.resolve())}
        for path in (
            compiler,
            rocm / "llvm/bin/llvm-mc",
            rocm / "llvm/bin/ld.lld",
            runtime,
        )
    ]
    receipt["compiler_version"] = run([str(compiler), "--version"])
    receipt["assembler_version"] = run([str(rocm / "llvm/bin/llvm-mc"), "--version"])
    try:
        receipt["rocminfo"] = run([str(rocm / "bin/rocminfo")])
    except (OSError, RuntimeError) as error:
        receipt["rocminfo_error"] = str(error)
    run(
        [
            str(compiler),
            "-O2",
            "-std=c++17",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-D__HIP_PLATFORM_AMD__",
            "-I" + str(rocm / "include"),
            str(HERE / "core.cpp"),
            "-L" + str(rocm / "lib"),
            "-Wl,-rpath," + str(rocm / "lib"),
            "-lamdhip64",
            "-o",
            str(build / "core"),
        ]
    )
    receipt["driver_binary_sha256"] = sha256(build / "core")
    linkage = run(["ldd", str(build / "core")])
    receipt["runtime_linkage"] = linkage
    actual_runtime = loaded_hip_runtime(linkage)
    if actual_runtime != runtime.resolve():
        raise RuntimeError(
            f"HIP runtime mismatch: loaded {actual_runtime}, expected {runtime.resolve()}"
        )
    receipt["loaded_hip_runtime"] = {
        "path": str(actual_runtime),
        "sha256": sha256(actual_runtime),
    }
    selftest = run([str(build / "core"), str(build), "selftest"])
    receipt["checker_selftest"] = json.loads(
        next(line[9:] for line in selftest.splitlines() if line.startswith("SELFTEST "))
    )
    if receipt["checker_selftest"] != {
        "status": "PASS",
        "negative_controls": 7,
        "kernel_launches": 0,
    }:
        raise RuntimeError("unexpected host checker self-test result")
    for unit in UNITS:
        source = FIXTURES / (unit + ".s")
        source_hash = sha256(source)
        obj, hsaco = build / (unit + ".o"), build / (unit + ".hsaco")
        run(
            [
                str(rocm / "llvm/bin/llvm-mc"),
                "--triple=amdgcn-amd-amdhsa",
                "--mcpu=gfx1250",
                "-filetype=obj",
                str(source),
                "-o",
                str(obj),
            ]
        )
        run([str(rocm / "llvm/bin/ld.lld"), "-shared", str(obj), "-o", str(hsaco)])
        if sha256(source) != source_hash:
            raise RuntimeError("fixture source changed during build")
        receipt["assembly"].append(
            {
                "source": "tests/gfx1250/fixtures/" + source.name,
                "source_sha256": source_hash,
                "hip_source_sha256": sha256(FIXTURES / (unit + ".hip")),
                "object_sha256": sha256(obj),
                "code_object_sha256": sha256(hsaco),
            }
        )
    selected = list(SUITES) if args.suite == "all" else [args.suite]
    for suite in selected:
        output = run([str(build / "core"), str(build), suite], timeout=240)
        identity = json.loads(
            next(
                line[9:] for line in output.splitlines() if line.startswith("IDENTITY ")
            )
        )
        result = json.loads(
            next(line[7:] for line in output.splitlines() if line.startswith("RESULT "))
        )
        if identity["target"].split(":")[0] != "gfx1250" or identity["wave_size"] != 32:
            raise RuntimeError("unexpected actual device identity")
        for key in ("launches", "output_checks"):
            if result[key] != SUITES[suite][key]:
                raise RuntimeError(
                    f"incomplete suite {suite}: {key}={result[key]}, required {SUITES[suite][key]}"
                )
        if result["output_guard_bytes"] != result["launches"] * 512:
            raise RuntimeError("not every output allocation had both guards checked")
        receipt["identity"] = identity
        result["configuration"] = SUITES[suite]
        result["manifest_cases"] = CASE_KERNELS[suite]
        receipt["suites"].append(result)
        print("PASS " + json.dumps(result), flush=True)
    receipt["totals"] = {
        key: sum(suite[key] for suite in receipt["suites"])
        for key in (
            "launches",
            "output_checks",
            "output_guard_bytes",
            "unchanged_input_bytes_including_guards",
            "host_argument_bytes",
        )
    }
    receipt["status"] = "PASS"
    return 0


if __name__ == "__main__":
    sys.exit(main())
