#!/usr/bin/env python3
"""Reproduce and classify bounded compiler kernels without changing their assembly."""
from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MANIFEST = HERE / "cases.json"
sys.path.insert(0, str(ROOT / "ai_compiler_kernels"))
import check_races as harness  # noqa: E402

TARGETS = {"gfx942", "gfx950", "gfx1250"}
CLASSES = {"verified", "finding", "unsupported", "inconclusive", "timeout", "crash"}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load_manifest(path=MANIFEST, root=ROOT):
    document = json.loads(path.read_text())
    require(document["schema_version"] == 1, "unsupported corpus schema")
    cases = document["cases"]
    require(cases and len(cases) == len({c["id"] for c in cases}), "duplicate/empty cases")
    for case in cases:
        require(case["target"] in TARGETS, "unknown target")
        for key in ("source", "assembly", "spec"):
            relative = Path(case[key])
            require(not relative.is_absolute() and ".." not in relative.parts, "unsafe input path")
            require(sha(root / relative) == case[key + "_sha256"], f"stale {key}: {case['id']}")
        require(harness.native_target_of((root / case["assembly"]).read_text()) == case["target"],
                "assembly target mismatch")
        arrays = {a["name"]: a for a in case["arrays"]}
        require(len(arrays) == len(case["arrays"]), "duplicate arrays")
        outputs = {name: list(range(a["length"])) for name, a in arrays.items() if a["kind"] == "out"}
        require(case["output_indices"] == outputs, "incomplete original output contract")
        require(case["expected_outputs"] == sum(map(len, outputs.values())), "output count mismatch")
        require(case["workgroup"] == [0, 0, 0], "this corpus registers complete workgroup-zero computations")
    return document


def expression_indices(text):
    require(text.startswith("volta-expr 1\n"), "missing expression artifact")
    result = {}
    for line in text.splitlines():
        if not line.startswith("out "):
            continue
        match = re.fullmatch(r'out ("(?:[^"\\]|\\.)*") (\d+) n\d+', line)
        require(match is not None, "malformed output coordinate")
        name, index = json.loads(match[1]), int(match[2])
        values = result.setdefault(name, [])
        require(index not in values, "duplicate output coordinate")
        values.append(index)
    return {name: sorted(values) for name, values in result.items()}


def classify(returncode, stdout, stderr, *, timed_out=False):
    if timed_out:
        return "timeout", "wall-clock stage budget exhausted"
    if returncode < 0 or returncode not in (0, 1, 2):
        return "crash", f"process exit {returncode}"
    text = stdout + "\n" + stderr
    unsupported = next((line.strip() for line in text.splitlines() if "unsupported" in line.lower()), None)
    if unsupported:
        return "unsupported", unsupported
    if re.search(r"^VERDICT: (REJECT|REFUTED)$", stdout, re.M) or re.search(r"^  .*\sFAIL$", stdout, re.M):
        return "finding", next((line.strip() for line in text.splitlines() if "FAIL" in line or "REJECT" in line), "verification rejected")
    if returncode != 0 or re.search(r"\bUNKNOWN\b", stdout):
        return "inconclusive", next((line.strip() for line in text.splitlines() if line.strip()), "no conclusive verdict")
    return "inconclusive", "successful process alone is not verification"


def launch(case):
    args = ["--backend", "amdgpu", "--target", case["target"], "--kernel", case["kernel"],
            "--block", ",".join(map(str, case["block"])), "--grid", ",".join(map(str, case["grid"])),
            "--workgroup-id", ",".join(map(str, case["workgroup"])), "--no-profile"]
    for array in case["arrays"]:
        args += ["--array", f"{array['name']}:{array['base_address']}:{array['element_size']}:{array['length']}:{array['kind']}"]
    for value in case["params"]:
        args += ["--param", value]
    return args


def run_stage(command, directory, name, timeout):
    start = time.monotonic()
    try:
        process = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
        stdout, stderr, code, expired = process.stdout, process.stderr, process.returncode, False
    except subprocess.TimeoutExpired as error:
        def decode(value):
            return value.decode(errors="replace") if isinstance(value, bytes) else value or ""
        stdout, stderr, code, expired = decode(error.stdout), decode(error.stderr), -1, True
    (directory / (name + ".stdout")).write_text(stdout)
    (directory / (name + ".stderr")).write_text(stderr)
    return {"command": command, "returncode": code, "timed_out": expired,
            "seconds": time.monotonic() - start}, stdout, stderr


def run_case(binary, case, output, timeout):
    directory = output / case["id"]
    directory.mkdir(parents=True, exist_ok=False)
    expressions = directory / "outputs.vexpr"
    assembly = ROOT / case["assembly"]
    common = launch(case)
    command = [str(binary), "--no-log-file", "analyze", str(assembly), *common,
               "--print-outputs", "0", "--emit-exprs", str(expressions)]
    stage, stdout, stderr = run_stage(command, directory, "analyze", timeout)
    stages = [stage]
    outcome, reason = classify(stage["returncode"], stdout, stderr, timed_out=stage["timed_out"])
    parsed = harness.parse_cli(stdout)
    complete = stage["returncode"] == 0 and parsed.verdict == "VERIFIED"
    if complete:
        try:
            require(expressions.is_file(), "missing complete output artifact")
            require(expression_indices(expressions.read_text()) == case["output_indices"], "complete output index set differs")
            error = harness.array_coverage_error(stdout, {name: len(indices) for name, indices in case["output_indices"].items()})
            require(error is None, error)
        except ValueError as error:
            complete, outcome, reason = False, "finding", str(error)
    if complete:
        command = [str(binary), "--no-log-file", "verify", str(assembly), str(ROOT / case["spec"]), *common, "--sample", "0"]
        for name, value in case["dimensions"].items():
            command += ["--dim", f"{name}={value}"]
        stage, stdout, stderr = run_stage(command, directory, "verify", timeout)
        stages.append(stage)
        outcome, reason = classify(stage["returncode"], stdout, stderr, timed_out=stage["timed_out"])
        count = re.search(r"equivalence: all (\d+) compared elements proved equivalent", stdout)
        if stage["returncode"] == 0 and re.search(r"^VERDICT: ACCEPT$", stdout, re.M) and count and int(count[1]) == case["expected_outputs"]:
            outcome, reason = "verified", "graph verified; exact output indices retained; every specification element proved"
    result = {"id": case["id"], "classification": outcome, "reason": reason, "stages": stages}
    (directory / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def extract(document, llvm, rocm, output):
    version = subprocess.run([str(llvm / "clang++"), "--version"], capture_output=True, text=True, check=True).stdout
    require(document["compiler"]["revision"] in version, "compiler revision differs from pinned extraction")
    output.mkdir(parents=True, exist_ok=True)
    results = []
    for target, source in sorted({(c["target"], c["source"]) for c in document["cases"]}):
        row = next(c for c in document["cases"] if c["target"] == target and c["source"] == source)
        assembly = output / Path(row["assembly"]).name
        command = [str(llvm / "clang++"), "-x", "hip", "--offload-device-only", "--offload-arch=" + target,
                   "--rocm-path=" + str(rocm), "-cuid=amd_corpus_" + target + "_" + row["source_sha256"][:16],
                   "-O2", "-std=c++17", "-S", source, "-o", str(assembly)]
        run = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        status, diagnostic = "compiled", run.stderr
        if run.returncode:
            status = "compiler_unsupported"
        else:
            check = subprocess.run([str(llvm / "llvm-mc"), "--triple=amdgcn-amd-amdhsa", "--mcpu=" + target,
                                    "-filetype=obj", str(assembly), "-o", str(assembly.with_suffix(".o"))], capture_output=True, text=True)
            if check.returncode:
                status, diagnostic = "compiler_unsupported", check.stderr
            else:
                require(sha(assembly) == row["assembly_sha256"], "regenerated assembly differs; review source/compiler/flags")
        results.append({"target": target, "source": source, "extraction": status, "diagnostic": diagnostic})
    print(json.dumps(results, indent=2))
    return int(any(r["extraction"] != "compiled" for r in results))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    commands.add_parser("check")
    compile_args = commands.add_parser("extract")
    compile_args.add_argument("--llvm", required=True, type=Path)
    compile_args.add_argument("--rocm-path", required=True, type=Path)
    compile_args.add_argument("--output", required=True, type=Path)
    execute = commands.add_parser("run")
    execute.add_argument("--binary", required=True, type=Path)
    execute.add_argument("--binary-revision", required=True)
    execute.add_argument("--output", required=True, type=Path)
    execute.add_argument("--case", action="append", default=[])
    execute.add_argument("--jobs", type=int, default=1)
    execute.add_argument("--timeout", type=float, default=60)
    args = parser.parse_args()
    document = load_manifest()
    if args.action == "check":
        print(f"{len(document['cases'])} pinned compiler cases; complete output contracts checked")
        return 0
    if args.action == "extract":
        return extract(document, args.llvm.resolve(), args.rocm_path.resolve(), args.output.resolve())
    require(args.jobs > 0 and args.timeout > 0, "positive resource budgets required")
    output = args.output.resolve()
    require(not output.is_relative_to(ROOT), "run logs must stay outside the repository")
    output.mkdir(parents=True, exist_ok=False)
    binary = args.binary.resolve(strict=True)
    known = {case["id"] for case in document["cases"]}
    require(set(args.case) <= known, "unknown case selection")
    selected = [case for case in document["cases"] if not args.case or case["id"] in args.case]
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        results = list(pool.map(lambda case: run_case(binary, case, output, args.timeout), selected))
    report = {"binary_revision": args.binary_revision, "binary_sha256": sha(binary),
              "manifest_sha256": sha(MANIFEST), "driver_sha256": sha(__file__),
              "shared_harness_sha256": sha(ROOT / "ai_compiler_kernels/check_races.py"),
              "timeout_seconds_per_stage": args.timeout, "jobs": args.jobs,
              "selected_cases": len(selected), "counts": dict(Counter(r["classification"] for r in results)), "results": results}
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    for result in results:
        print(result["id"], result["classification"], result["reason"])
    return int(any(r["classification"] != "verified" for r in results))


if __name__ == "__main__":
    sys.exit(main())
