#!/usr/bin/env python3
"""Account for all32 unchanged Python tests across strictly disjoint pinned groups."""

import argparse
import importlib.util
import json
from pathlib import Path
import re
import time

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("python_proof_driver", HERE / "prove_python.py")
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)
require, sha, atomic_json = DRIVER.require, DRIVER.sha, DRIVER.atomic_json

IDENTITY_KEYS = (
    "revision_supplied_by_builder",
    "driver_sha256",
    "bounded_driver_sha256",
    "python",
    "python_sha256",
    "extension",
    "extension_sha256",
    "package_init_sha256",
    "python_identity",
    "runtime_sha256",
    "input_sha256",
    "host",
    "platform",
)


def required_input_pins(registry):
    full = registry.parent
    root = full.parents[2]
    contract, contract_path = DRIVER.ADVANCED.load_contract(full)
    inventory_path = full.parent / "full-parity/gaps.json"
    inventory = contract.validate_inventory(json.loads(inventory_path.read_text()))
    document = json.loads(registry.read_text())
    contract.validate_registry(document, inventory, full, require_all=True)
    paths = [root / "crates/volta_py/tests/test_gfx1250_original_workloads.py",
             contract_path, inventory_path, registry]
    for row in inventory.values():
        paths += [root / row["baseline_path"], root / row["baseline_config_path"]]
    for case in document["cases"]:
        paths += [full / case[key] for key in ("source", "assembly", "spec", "launch_config")]
    return {str(path): sha(path) for path in paths}


def aggregate(registry, receipt_paths):
    """Inspect the actual JUnit/logs and pinned inputs, not just status strings."""
    registry = registry.resolve(strict=True)
    document = json.loads(registry.read_text())
    cases = DRIVER.selected_cases(document, [])
    expected_inputs = required_input_pins(registry)
    require(sum(case["expected_outputs"] for case in cases) == 395394,
            "complete395394-output registry required")
    by_name = {case["kernel"]: case for case in cases}
    require(receipt_paths, "at least one completed group receipt required")
    receipt_paths = [path.resolve(strict=True) for path in receipt_paths]
    require(len(set(receipt_paths)) == len(receipt_paths), "duplicate receipt path")
    identity, seen, groups = None, set(), []
    for path in receipt_paths:
        record = json.loads(path.read_text())
        require(record.get("status") in ("partial", "pass"), "group is incomplete or unsuccessful")
        require(record.get("hardware_execution") is False, "CPU-only Python receipt required")
        require(record.get("gate") ==
                "existing full original Python analyze/index/verify/numeric regression",
                "unchanged full Python gate required")
        current = {key: record[key] for key in IDENTITY_KEYS}
        require(re.fullmatch(r"[0-9a-f]{40}", current["revision_supplied_by_builder"]),
                "exact builder revision required")
        require(current["runtime_sha256"] and current["input_sha256"], "empty source/runtime pins")
        require(current["input_sha256"] == expected_inputs,
                "missing, changed or extra original source/config/spec/baseline pins")
        require(current["driver_sha256"] == sha(HERE / "prove_python.py") and
                current["bounded_driver_sha256"] == sha(HERE / "prove_advanced.py"),
                "different Python gate or bounded runner")
        require(identity is None or current == identity,
                "mixed source, extension, interpreter, ABI, runtime or input pins")
        identity = current
        names = record["selected_kernels"]
        require(names and len(names) == len(set(names)), "empty or duplicate selected cases")
        require(not set(names) - by_name.keys(), "unexpected original case")
        require(not seen.intersection(names), "overlapping Python case groups")
        expected = sum(by_name[name]["expected_outputs"] for name in names)
        require(record["expected_outputs"] == expected, "partial or incorrect output footprint")
        require(record.get("finished_unix", 0) >= record.get("started_unix", 0) > 0,
                "unfinished group receipt")
        process = record["process"]
        require(process["exit_code"] == 0 and process["termination"] is None and
                process["elapsed_seconds"] > 0, "unsuccessful or unexecuted Python group")
        junit = path.parent / "junit.xml"
        require(sha(junit) == record["junit_sha256"], "JUnit artifact changed")
        actual_names = DRIVER.check_junit(junit, names)
        require(record["test_names"] == actual_names, "testcase receipt differs from actual JUnit")
        inputs = current["input_sha256"]
        test_paths = [source for source in inputs if source.endswith(
            "/crates/volta_py/tests/test_gfx1250_original_workloads.py")]
        require(len(test_paths) == 1, "one pinned unchanged original Python test source required")
        registry_paths = [source for source in inputs if source.endswith(
            "/tests/gfx1250/full/cases.json")]
        require(len(registry_paths) == 1 and inputs[registry_paths[0]] == sha(registry),
                "registry differs from executed groups")
        command = [current["python"], "-m", "pytest", "-vv", "-s", "-p", "no:cacheprovider"]
        command += [f"{test_paths[0]}::{DRIVER.TEST}[{name}]" for name in names]
        command += ["--junitxml", str(junit)]
        require(process["argv"] == command, "different, filtered or sampled Python invocation")
        artifacts = {"receipt": sha(path), "junit": sha(junit)}
        for stream in ("stdout", "stderr"):
            actual = sha(path.parent / (stream + ".txt"))
            require(actual == process[stream + "_sha256"], f"{stream} artifact changed")
            artifacts[stream] = actual
        groups.append({"receipt": str(path), "selected_kernels": names,
                       "expected_outputs": expected, "artifact_sha256": artifacts})
        seen.update(names)
    require(seen == by_name.keys(), "missing original Python cases")
    # Every group hashes the entire32-case input corpus, even when its selected
    # testcase subset is smaller. Revalidate those bytes and imported runtimes.
    for pinned in (identity["input_sha256"], identity["runtime_sha256"]):
        require(all(sha(path) == digest for path, digest in pinned.items()),
                "source or runtime changed after groups completed")
    require(sha(identity["python"]) == identity["python_sha256"], "interpreter changed")
    require(sha(identity["extension"]) == identity["extension_sha256"], "extension changed")
    require(sha(Path(identity["extension"]).parent / "__init__.py") ==
            identity["package_init_sha256"], "package initializer changed")
    return {"identity": identity, "groups": groups, "case_count": len(seen),
            "expected_outputs": 395394, "registry_sha256": sha(registry)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", required=True, type=Path)
    parser.add_argument("--receipt", action="append", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.resolve() in {path.resolve() for path in args.receipt}:
        parser.error("aggregate output must not overwrite an individual group receipt")
    # Invalidate any previous PASS before loading an input or performing an
    # operational preflight. Individual subset receipts remain unchanged.
    receipt = {"status": "incomplete", "gate": "complete original32 Python groups",
               "hardware_execution": False, "sampling": False,
               "started_unix": time.time(), "driver_sha256": sha(__file__)}
    atomic_json(args.output, receipt)
    try:
        receipt.update(aggregate(args.registry, args.receipt), status="pass")
    except (ValueError, OSError, KeyError, TypeError, DRIVER.ET.ParseError) as error:
        receipt.update(status="fail", error=f"{type(error).__name__}: {error}")
    finally:
        receipt["finished_unix"] = time.time()
        atomic_json(args.output, receipt)
        print(json.dumps({key: receipt.get(key) for key in
                          ("status", "case_count", "expected_outputs", "error")}))
    return 0 if receipt["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
