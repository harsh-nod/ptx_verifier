# /// script
# requires-python = ">=3.10"
# dependencies = ["pybind11>=2.13,<4", "pyyaml>=6,<7"]
# ///
"""Compile complete pinned HipKittens translation units; retain every pipeline outcome.

No kernel is run on a GPU. Original Makefiles supply semantic flags and template
selectors; only device-only assembly/output/link settings are adapted. Missing
recipes, dependencies, tool failures and missing launch contracts remain explicit.
"""
from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shlex
import signal
import subprocess
import sys
import sysconfig
import time

import hipkittens_inventory as inventory
import hipkittens as legacy

EXTERNAL = inventory.EXTERNAL
ROOT = EXTERNAL.parent
LAUNCHES = {
    "kernels/cdna4/softmax/kernel.cpp": "softmax",
    "kernels/cdna4/rotary/kernel.cpp": "rotary",
    "kernels/cdna4/gemm/bf16fp32/256_256_64_32_with16x32.cpp": "gemm_bf16",
}


def stage(command, directory, name, timeout, *, cwd=None):
    started = time.monotonic()
    record = {"command": [str(arg) for arg in command], "cwd": str(cwd) if cwd else None}
    try:
        process = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   start_new_session=True)
    except OSError as error:
        record.update(status="process_error", error=str(error), returncode=None, seconds=time.monotonic() - started)
        (directory / (name + ".json")).write_text(json.dumps(record, indent=2) + "\n")
        return record, "", str(error)
    timed_out = False
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
    status = ("timeout" if timed_out else "succeeded" if process.returncode == 0 else
              "rejected" if process.returncode in (1, 2) else "process_crash")
    record.update(status=status, returncode=process.returncode, seconds=time.monotonic() - started)
    (directory / (name + ".stdout")).write_bytes(stdout)
    (directory / (name + ".stderr")).write_bytes(stderr)
    (directory / (name + ".json")).write_text(json.dumps(record, indent=2) + "\n")
    return record, stdout.decode(errors="replace"), stderr.decode(errors="replace")


def compiler_line(output, source, cwd):
    """Select the exact source's printed compiler command, never execute shell text."""
    candidates = []
    for line in output.replace("\\\n", " ").splitlines():
        args = shlex.split(line)
        if not args or Path(args[0]).name not in {"hipcc", "clang++", "amdclang++"}:
            continue
        for token in ("|", "2>&1", ">", "&&", ";"):
            if token in args:
                args = args[:args.index(token)]
        if any((cwd / arg).resolve() == source for arg in args[1:] if not arg.startswith("-")):
            candidates.append(args)
    inventory.require(len(candidates) == 1, "upstream build has no unique compiler recipe for this source")
    return candidates[0]


def device_flags(command, source, cwd, target, architecture):
    """Keep optimization/defines/math flags; remove only host linking/artifact roles."""
    flags = []
    skipped = []
    index = 1
    while index < len(command):
        arg = command[index]
        if arg in {"-o", "-L", "-l"}:
            skipped.extend(command[index:index + 2])
            index += 2
            continue
        if arg in {"-c", "-shared", "--save-temps", "-save-temps"} or arg.startswith(("-L", "-l", "-Wl,", "-Rpass")):
            skipped.append(arg)
        elif not arg.startswith("-") and (cwd / arg).resolve() == source:
            pass
        else:
            inventory.require(arg.startswith("-") or (index > 1 and command[index - 1] in {"-I", "-include", "-isystem", "-x", "-Xclang"}),
                              "unrecognized positional input in upstream recipe: " + arg)
            flags.append(arg)
        index += 1
    targets = [arg.split("=", 1)[1] for arg in flags if arg.startswith("--offload-arch=")]
    macros = [arg for arg in flags if arg.startswith("-DKITTENS_CDNA")]
    inventory.require(set(targets) == {target} and set(macros) == {"-DKITTENS_" + architecture.upper()},
                      "upstream recipe target/macro differs; refusing silent retargeting")
    return flags, skipped


def metadata(assembly, target):
    import yaml
    markers = re.findall(r'(?m)^\s*\.amdgcn_target\s+"([^"]+)"', assembly)
    inventory.require(markers == ["amdgcn-amd-amdhsa--" + target], "compiler output target differs")
    match = re.search(r"\.amdgpu_metadata\s*\n(.*?)\n\s*\.end_amdgpu_metadata", assembly, re.S)
    if not match:
        return []
    document = yaml.safe_load(match[1])
    inventory.require(document["amdhsa.target"] == "amdgcn-amd-amdhsa--" + target, "metadata target differs")
    kernels = document.get("amdhsa.kernels", [])
    inventory.require(len(kernels) == len({row[".name"] for row in kernels}), "duplicate emitted entrypoints")
    expected_wave = 32 if target == "gfx1250" else 64
    inventory.require(all(row.get(".wavefront_size") == expected_wave for row in kernels),
                      "emitted wave size differs from the original native profile")
    return kernels


def analyze_launch(binary, assembly, config, target, directory, timeout):
    payload = json.loads(config.read_text())
    expected = {}
    for array in payload["arrays"]:
        if array["kind"] not in {"out", "inout"}:
            continue
        shape = array.get("shape", [array.get("len")])
        inventory.require(shape and all(type(size) is int and size >= 0 for size in shape), "invalid output shape")
        inventory.require(array["name"] not in expected, "duplicate launch output array")
        expected[array["name"]] = math.prod(shape)
    args = [str(binary), "--no-log-file", "--backend", "amdgpu", "--target", target, "analyze", str(assembly),
            "--config", str(config), "--print-outputs", "0", "--no-profile"]
    run, stdout, stderr = stage(args, directory, "analyze", timeout)
    if run["status"] in {"timeout", "process_error", "process_crash"}:
        return {"status": run["status"], "stage": run}
    sys.path.insert(0, str(ROOT / "ai_compiler_kernels"))
    import check_races
    report = check_races.parse_cli(stdout)
    try:
        outcome, detail = check_races.classify(report, stderr, sum(expected.values()))
    except check_races.VoltaFailure as error:
        return {"status": "analysis_error", "detail": str(error), "stage": run}
    if outcome in {check_races.Outcome.RACE_FREE, check_races.Outcome.REDUCED_RACE_FREE}:
        inventory.require(run["returncode"] == 0, "successful graph report has nonzero process exit")
        inventory.require(report.checks and all(verdict == "PASS" for _, verdict, _ in report.checks),
                          "successful graph report has missing or nonpassing properties")
        error = check_races.array_coverage_error(stdout, expected)
        inventory.require(error is None, error)
    return {"status": outcome.value, "detail": detail, "stage": run, "expected_by_array": expected,
            "launch_sha256": inventory.sha(config.read_bytes())}


def process_unit(unit, profile, options, source_root, output):
    source = (source_root / unit["source"]).resolve()
    identifier = profile["target"] + "-" + inventory.sha(unit["source"].encode())[:16]
    directory = output / identifier
    directory.mkdir()
    result = {"id": identifier, "source": unit["source"], "scope": unit["scope"], "profile": profile,
              "source_sha256": inventory.sha(source.read_bytes()), "analysis": {"status": "not_reached"}}
    try:
        build = source_root / unit["build_file"] if unit["build_file"] else None
        if unit["source"].startswith("tests/unit/"):
            build = source_root / "tests/unit" / profile["architecture"] / "Makefile"
        if not build or not build.is_file():
            result.update(status="recipe_unavailable", error="no upstream Makefile for translation unit")
            return result
        cwd = build.parent
        includes = "-I" + str(options.pybind11_include) + " -I" + sysconfig.get_path("include")
        recipe = ["make", "-B", "-n", "--no-print-directory", "-C", str(cwd), "all",
                  "SRC=" + source.name, "KERNEL=" + source.stem, "GPU_TARGET=" + profile["architecture"].upper(),
                  "THUNDERKITTENS_ROOT=" + str(source_root), "ROCM_PATH=" + str(options.rocm),
                  "ROCM_INSTALL_DIR=" + str(options.rocm), "PY_INCLUDES=" + includes, "PY_LDFLAGS=", "PY_EXT_SUFFIX=.so"]
        if unit["source"].startswith("tests/unit/"):
            recipe += ["TEST_DEFINES=-DTEST_ALL", "TEST_INTENSITY=2"]
        run, stdout, _ = stage(recipe, directory, "recipe", options.timeout)
        if run["status"] != "succeeded":
            result["status"] = "recipe_" + run["status"]
            return result
        try:
            original = compiler_line(stdout, source, cwd)
            flags, adapted = device_flags(original, source, cwd, profile["target"], profile["architecture"])
        except ValueError as error:
            result.update(status="recipe_refused", error=str(error))
            return result
        result["recipe"] = {"build_file": str(build.relative_to(source_root)), "original_command": original,
                            "removed_host_artifact_flags": adapted}
        assembly = directory / "kernel.s"
        args = [str(options.compiler), "-x", "hip", "--cuda-device-only", "-S", *flags,
                "-I" + str(source_root / "include"), "-I" + str(source_root / "prototype"),
                "-I" + str(options.pybind11_include), "-I" + sysconfig.get_path("include"), str(source), "-o", str(assembly)]
        run, _, stderr = stage(args, directory, "compile", options.timeout, cwd=cwd)
        if run["status"] != "succeeded":
            result["status"] = "compile_" + run["status"]
            result["first_diagnostic"] = next(iter(stderr.strip().splitlines()), "")
            return result
        inventory.require(assembly.is_file() and assembly.stat().st_size, "compiler produced no assembly")
        result["assembly_sha256"] = inventory.sha(assembly.read_bytes())
        kernels = metadata(assembly.read_text(), profile["target"])
        result["emitted_kernels"] = kernels
        if not kernels:
            result["status"] = "compiled_no_entrypoints"
            result["analysis"] = {"status": "no_emitted_entrypoints"}
            return result
        obj = directory / "kernel.o"
        run, _, _ = stage([str(options.assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=" + profile["target"],
                           "-filetype=obj", str(assembly), "-o", str(obj)], directory, "assemble", options.timeout)
        if run["status"] != "succeeded":
            result["status"] = "assemble_" + run["status"]
            return result
        result["object_sha256"] = inventory.sha(obj.read_bytes())
        run, _, stderr = stage([str(options.binary), "--no-log-file", "--backend", "amdgpu", "--target", profile["target"],
                                "parse", str(assembly)], directory, "parse", options.timeout)
        if run["status"] != "succeeded":
            result["status"] = ("parse_unsupported" if run["status"] == "rejected" and re.search(r"unsupported .*instruction", stderr, re.I)
                                else "parse_" + run["status"])
            result["first_diagnostic"] = next(iter(stderr.strip().splitlines()), "")
            result["analysis"] = {"status": "blocked_by_parse"}
            return result
        result["status"] = "parsed"
        result["analysis"] = {"status": "launch_contract_required"}
        launch = LAUNCHES.get(unit["source"])
        if launch:
            config = EXTERNAL / "hipkittens/cdna4" / (launch + ".wg0.launch.json")
            payload = json.loads(config.read_text())
            inventory.require(payload["kernel"] in {kernel[".name"] for kernel in kernels}, "launch symbol missing from current compiler metadata")
            legacy.validate_launch(payload, {"amdhsa.kernels": kernels})
            result["analysis"] = analyze_launch(options.binary, assembly, config, profile["target"], directory, options.timeout)
        return result
    except (OSError, ValueError, KeyError, TypeError) as error:
        result.update(status="contract_error", error=str(error))
        return result
    finally:
        (directory / "result.json").write_text(json.dumps(result, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=inventory.DEFAULT_SOURCE)
    parser.add_argument("--inventory", type=Path, default=inventory.DEFAULT_OUTPUT)
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--binary-revision", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--compiler", type=Path, default=Path("/opt/rocm/llvm/bin/clang++"))
    parser.add_argument("--assembler", type=Path, default=Path("/opt/rocm/llvm/bin/llvm-mc"))
    parser.add_argument("--rocm", type=Path, default=Path("/opt/rocm"))
    parser.add_argument("--pybind11-include", type=Path)
    parser.add_argument("--jobs", type=int, choices=(1, 2), default=2)
    parser.add_argument("--timeout", type=float, default=180)
    parser.add_argument("--source", action="append", default=[], help="Exact inventoried translation unit; repeatable")
    parser.add_argument("--target", choices=("gfx942", "gfx950", "gfx1250"), action="append", default=[])
    options = parser.parse_args()
    try:
        inventory.require(options.timeout > 0, "positive per-stage timeout required")
        source_root = options.source_root.resolve()
        document = inventory.build_inventory(source_root)
        inventory.require(document == json.loads(options.inventory.read_text()), "checked source inventory drifted")
        if options.pybind11_include is None:
            import pybind11
            options.pybind11_include = Path(pybind11.get_include())
        inventory.require((options.pybind11_include / "pybind11/pybind11.h").is_file(), "missing pybind11 headers")
        options.binary = options.binary.resolve(strict=True)
        selected = [(unit, profile) for unit in document["compilation_units"] if unit["standalone_translation_unit"]
                    and (not options.source or unit["source"] in options.source) for profile in unit["profiles"]
                    if not options.target or profile["target"] in options.target]
        inventory.require(selected and set(options.source) <= {unit["source"] for unit, _ in selected}, "empty or unknown source selection")
        output = options.output.resolve()
        inventory.require(not output.is_relative_to(ROOT) and not output.is_relative_to(source_root),
                          "raw campaign data must remain outside repository and upstream source")
        output.mkdir(parents=True, exist_ok=False)
        driver_inputs = {"campaign": Path(__file__), "inventory": Path(inventory.__file__), "launch_validation": Path(legacy.__file__),
                         "outcome_validation": ROOT / "ai_compiler_kernels/check_races.py"}
        driver_hashes = {name: inventory.sha(path.read_bytes()) for name, path in driver_inputs.items()}
        for name, path in driver_inputs.items():
            (output / (name + "-source.py")).write_bytes(path.read_bytes())
        identity = {"schema_version": 1, "source_revision": inventory.REVISION,
                    "inventory_sha256": inventory.sha(options.inventory.read_bytes()), "binary_revision": options.binary_revision,
                    "binary_sha256": inventory.sha(options.binary.read_bytes()), "driver_sha256": inventory.sha(Path(__file__).read_bytes()),
                    "compiler_sha256": inventory.sha(options.compiler.read_bytes()), "assembler_sha256": inventory.sha(options.assembler.read_bytes()),
                    "driver_source_sha256": driver_hashes,
                    "jobs": options.jobs, "timeout_seconds": options.timeout, "selected_translation_unit_profiles": len(selected)}
        (output / "identity.json").write_text(json.dumps(identity, indent=2) + "\n")
        results = []
        with ThreadPoolExecutor(max_workers=options.jobs) as executor:
            pending = [executor.submit(process_unit, unit, profile, options, source_root, output) for unit, profile in selected]
            for future in as_completed(pending):
                result = future.result()
                results.append(result)
                print(result["profile"]["target"], result["source"], result["status"], result.get("first_diagnostic", ""), flush=True)
        inventory.require(inventory.build_inventory(source_root) == document, "source changed during campaign")
        inventory.require(inventory.sha(options.binary.read_bytes()) == identity["binary_sha256"], "analysis binary changed during campaign")
        inventory.require(all(inventory.sha(path.read_bytes()) == driver_hashes[name] for name, path in driver_inputs.items()),
                          "campaign or validation source changed during run")
        inventory.require(len(results) == len(selected) == len({row["id"] for row in results}), "missing or duplicate campaign result")
        report = {**identity, "outcomes": dict(sorted(Counter(row["status"] for row in results).items())),
                  "analysis_outcomes": dict(sorted(Counter(row["analysis"]["status"] for row in results).items())),
                  "results": sorted(results, key=lambda row: row["id"])}
        (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    except (OSError, ValueError, subprocess.CalledProcessError, ImportError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
