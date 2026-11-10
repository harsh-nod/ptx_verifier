#!/usr/bin/env python3
"""Check unchanged original workload contracts on additional AMD configurations."""
from __future__ import annotations

import argparse
import copy
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MANIFEST = HERE / "cases.json"


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    sys.modules[name] = result
    spec.loader.exec_module(result)
    return result


PROOF = module("qualification_original_cli", ROOT / "tests/gfx1250/full/cpu/prove_cli.py")
CORPUS = module("qualification_compiler_corpus", ROOT / "tests/amdgpu/compiler-corpus/corpus.py")
require, sha = PROOF.require, PROOF.sha


def checked_path(root, name):
    return root / PROOF.relative_path(name)


def validate_launch(case, actual, expected):
    normalized = copy.deepcopy(actual)
    require(type(case["allocation_relocation"]) is bool, "invalid relocation flag")
    if case["allocation_relocation"]:
        require(case["target"] == "gfx1250", "only the registered Sinkhorn allocation is relocated")
        require(case["reference_kernel"] == "sinkhorn_original", "unregistered relocated computation")
        require(len(actual["arrays"]) == len(expected["arrays"]), "original allocation omitted")
        ranges = []
        for array, reference in zip(normalized["arrays"], expected["arrays"]):
            base = array["base"]
            require(type(base) is int and base > 0xffffffff and base % 256 == 0,
                    "relocated bases must be aligned above 4GiB")
            ranges.append((base, base + array["elem_width"] * array["len"]))
            array["base"] = reference["base"]
        require(all(a[1] <= b[0] for a, b in zip(sorted(ranges), sorted(ranges)[1:])), "overlapping allocations")
    require(normalized == expected, "original shape/dtype/launch/ABI changed")


def load_manifest(path=MANIFEST, root=ROOT):
    document = json.loads(path.read_text())
    require(document["schema_version"] == 1, "unsupported qualification schema")
    registry = checked_path(root, document["reference_registry"])
    require(sha(registry) == document["reference_registry_sha256"], "original registry changed")
    contract, _ = PROOF.RUNTIME.load_contract(registry.parent)
    inventory = json.loads((registry.parent.parent / "full-parity/gaps.json").read_text())
    rows = contract.validate_inventory(inventory, root=root)
    reference_document = json.loads(registry.read_text())
    contract.validate_registry(reference_document, rows, registry.parent, require_all=True)
    references = {case["kernel"]: case for case in reference_document["cases"]}
    cases = document["cases"]
    require(cases and len({c["id"] for c in cases}) == len(cases), "empty/duplicate cases")
    checked = []
    for case in cases:
        require(case["target"] in {"gfx942", "gfx1250"}, "unregistered target")
        original = references[case["reference_kernel"]]
        require(case["expected_outputs"] == original["expected_outputs"], "original output count changed")
        assembly, config = (checked_path(root, case[key]) for key in ("assembly", "launch_config"))
        for key, source in (("assembly", assembly), ("launch_config", config)):
            require(sha(source) == case[key + "_sha256"], f"stale {key}")
        require(CORPUS.harness.native_target_of(assembly.read_text()) == case["target"], "assembly target mismatch")
        expected = json.loads((registry.parent / original["launch_config"]).read_text())
        actual = json.loads(config.read_text())
        validate_launch(case, actual, expected)
        outputs = {}
        for view in original["output_projection"]:
            outputs.setdefault(view["native_array"], []).extend(
                range(view["native_start"], view["native_start"] + view["length"]))
        require(all(len(indices) == len(set(indices)) for indices in outputs.values()), "duplicate output projection")
        checked.append((case, original, {name: sorted(indices) for name, indices in outputs.items()}))
    return document, checked


def validate_analysis(result, stdout, expressions, expected):
    require(result["exit_code"] == 0 and result["termination"] is None, "incomplete analysis process")
    report = CORPUS.harness.parse_cli(stdout)
    require(report.verdict == "VERIFIED", "graph was not verified")
    require(len(report.checks) == 4 and {name: status for name, status, _ in report.checks}
            == {name: "PASS" for name in PROOF.RUNTIME.PROPERTIES},
            "every native graph check must pass")
    require(CORPUS.expression_indices(expressions) == expected, "exact output coordinates differ")
    error = CORPUS.harness.array_coverage_error(stdout, {name: len(values) for name, values in expected.items()})
    require(error is None, error)


def run(binary, revision, output, selected=None, wall=300):
    require(re.fullmatch(r"[0-9a-f]{40}", revision) is not None, "exact binary source label required")
    require(type(wall) is int and wall > 0, "positive wall limit required")
    document, cases = load_manifest()
    require(not output.exists(), "a fresh external result directory is required")
    require(not output.resolve().is_relative_to(ROOT), "keep raw receipts outside the source tree")
    if selected:
        require(set(selected) <= {case["id"] for case, _, _ in cases}, "unknown case selection")
        cases = [row for row in cases if row[0]["id"] in selected]
    output.mkdir(parents=True)
    receipt = {"schema_version": 1, "status": "incomplete", "sampling": False,
               "hardware_execution": False, "binary_source_label": revision,
               "binary_sha256": sha(binary), "manifest_sha256": sha(MANIFEST), "results": []}
    PROOF.atomic_json(output / "receipt.json", receipt)
    snapshot = output / "snapshot"
    snapshot.mkdir()
    frozen_binary = snapshot / "volta"
    shutil.copy2(binary.resolve(strict=True), frozen_binary)
    frozen_binary.chmod(0o555)
    require(sha(frozen_binary) == receipt["binary_sha256"], "binary changed during snapshot")
    env = dict(os.environ)
    require(not any(name in env for name in ("LD_PRELOAD", "LD_AUDIT")), "loader injection")
    for name in ("VOLTA_VIZ_DIR", "RUST_LOG"):
        env.pop(name, None)
    env.update(HIP_VISIBLE_DEVICES="", ROCR_VISIBLE_DEVICES="", CUDA_VISIBLE_DEVICES="")
    _, receipt["runtime_libraries"] = PROOF.runtime_probe(frozen_binary, env)
    limits = {"wall_seconds": wall, "cpu_seconds": wall, "rss_bytes": 16 * 2**30,
              "address_space_bytes": 32 * 2**30}
    receipt["limits"] = limits
    receipt["input_pins"] = {}
    helpers = (MANIFEST, Path(__file__), Path(PROOF.__file__), Path(PROOF.RUNTIME.__file__),
               Path(CORPUS.__file__), ROOT / "ai_compiler_kernels/check_races.py",
               ROOT / document["reference_registry"],
               ROOT / "tests/gfx1250/full-parity/contract.py",
               ROOT / "tests/gfx1250/full-parity/gaps.json")
    for source in helpers:
        digest = sha(source)
        PROOF.RUNTIME.snapshot_input(source, snapshot / source.relative_to(ROOT), digest)
        receipt["input_pins"][str(source.relative_to(ROOT))] = digest
    for case, original, expected in cases:
        directory = output / case["id"]
        directory.mkdir()
        paths = {"assembly": checked_path(ROOT, case["assembly"]),
                 "config": checked_path(ROOT, case["launch_config"]),
                 "source": ROOT / "tests/gfx1250/full" / original["source"],
                 "spec": ROOT / "tests/gfx1250/full" / original["spec"]}
        for name, source in paths.items():
            target = snapshot / source.relative_to(ROOT)
            digest = sha(source)
            if not target.exists():
                PROOF.RUNTIME.snapshot_input(source, target, digest)
            require(sha(target) == digest, "snapshot input changed")
            receipt["input_pins"][str(source.relative_to(ROOT))] = digest
            paths[name] = target
        common = [str(frozen_binary), "--no-log-file", "--backend", "amdgpu", "--target", case["target"]]
        expressions = directory / "outputs.vexpr"
        analyze = common + ["analyze", str(paths["assembly"]), "--config", str(paths["config"]),
                            "--print-outputs", "0", "--emit-exprs", str(expressions)]
        row = {"id": case["id"], "status": "incomplete", "expected_outputs": case["expected_outputs"]}
        receipt["results"].append(row)
        PROOF.atomic_json(output / "receipt.json", receipt)
        try:
            stage = directory / "analysis"
            stage.mkdir()
            row["analysis"] = PROOF.RUNTIME.bounded(analyze, stage, env, limits)
            validate_analysis(row["analysis"], (stage / "stdout.txt").read_text(),
                              expressions.read_text() if expressions.exists() else "", expected)
            verify = common + ["verify", str(paths["assembly"]), str(paths["spec"]),
                               "--config", str(paths["config"]), "--sample", "0", "--verify-numeric"]
            for name, value in original["dimensions"].items():
                verify += ["--dim", f"{name}={value}"]
            stage = directory / "proof"
            stage.mkdir()
            row["proof"] = PROOF.RUNTIME.bounded(verify, stage, env, limits)
            PROOF.check_process(row["proof"], (stage / "stdout.txt").read_text(), case["expected_outputs"])
            row["status"] = "verified"
        except (ValueError, OSError) as error:
            row.update(status="incomplete", reason=str(error))
        PROOF.atomic_json(output / "receipt.json", receipt)
    for name, digest in receipt["input_pins"].items():
        require(sha(ROOT / name) == digest and sha(snapshot / name) == digest, "input changed during execution")
    require(sha(binary) == receipt["binary_sha256"] == sha(frozen_binary), "binary changed during execution")
    require(all(sha(Path(name)) == digest for name, digest in receipt["runtime_libraries"].items()),
            "dynamic runtime changed during execution")
    receipt["status"] = ("partial" if selected else "verified") if all(row["status"] == "verified" for row in receipt["results"]) else "incomplete"
    receipt["finished_unix"] = time.time()
    PROOF.atomic_json(output / "receipt.json", receipt)
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    commands.add_parser("check")
    execute = commands.add_parser("run")
    execute.add_argument("--binary", required=True, type=Path)
    execute.add_argument("--binary-revision", required=True)
    execute.add_argument("--output", required=True, type=Path)
    execute.add_argument("--case", action="append")
    execute.add_argument("--wall-seconds", type=int, default=300)
    args = parser.parse_args()
    if args.action == "check":
        _, cases = load_manifest()
        print(f"PASS {len(cases)} complete original-workload registrations")
        return 0
    receipt = run(args.binary, args.binary_revision, args.output, args.case, args.wall_seconds)
    print(json.dumps({"status": receipt["status"], "cases": len(receipt["results"])}))
    return int(receipt["status"] == "incomplete")


if __name__ == "__main__":
    raise SystemExit(main())
