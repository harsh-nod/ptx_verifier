#!/usr/bin/env python3
"""Replay the existing complete original32 Python API gate on a pinned CPU host."""

import argparse
import importlib.util
import json
import os
from pathlib import Path
import platform
import re
import socket
import subprocess
import time
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "advanced_proof_driver", HERE / "prove_advanced.py"
)
ADVANCED = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ADVANCED)
require = ADVANCED.require
sha = ADVANCED.sha
atomic_json = ADVANCED.atomic_json
TEST = "test_registered_original_case_analyzes_every_index_and_matches_full_spec"


def selected_cases(document, selected):
    cases = document["cases"]
    require(
        len(cases) == 32 and not document["missing_baseline_ids"],
        "full32 registry required",
    )
    names = {case["kernel"]: case for case in cases}
    require(len(names) == 32, "duplicate kernel registration")
    require(
        {case["baseline_id"] for case in cases} == {f"W{i:02}" for i in range(1, 33)},
        "original32 identities required",
    )
    require(len(selected) == len(set(selected)), "duplicate selected kernel")
    require(not set(selected) - names.keys(), "unknown selected kernel")
    return [names[name] for name in selected] if selected else cases


def check_junit(path, kernels):
    tree = ET.parse(path)
    suites = list(tree.getroot().iter("testsuite"))
    require(suites, "missing pytest suite")
    require(
        sum(int(suite.attrib.get("tests", 0)) for suite in suites) == len(kernels),
        "missing or extra Python API tests",
    )
    require(
        all(
            int(suite.attrib.get(field, 0)) == 0
            for suite in suites
            for field in ("failures", "errors", "skipped")
        ),
        "Python API test failed/errored/skipped",
    )
    cases = list(tree.getroot().iter("testcase"))
    require(len(cases) == len(kernels), "incomplete Python testcase accounting")
    names = [case.attrib["name"] for case in cases]
    require(
        len(names) == len(set(names))
        and set(names) == {f"{TEST}[{kernel}]" for kernel in kernels},
        "wrong or duplicate Python kernel tests",
    )
    require(
        all(
            not list(case.iter(tag))
            for case in cases
            for tag in ("failure", "error", "skipped")
        ),
        "hidden unsuccessful Python testcase",
    )
    return names


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--python", required=True, type=Path)
    parser.add_argument("--site-packages", required=True, type=Path)
    parser.add_argument("--extension-sha256", required=True)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--kernel", action="append", default=[])
    parser.add_argument("--wall-seconds", type=int, default=28800)
    parser.add_argument("--cpu-seconds", type=int, default=28200)
    parser.add_argument("--rss-gib", type=int, default=128)
    parser.add_argument("--address-space-gib", type=int, default=256)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    destination = output / "receipt.json"
    receipt = {
        "status": "incomplete",
        "gate": "existing full original Python analyze/index/verify/numeric regression",
        "hardware_execution": False,
        "sampling": False,
        "started_unix": time.time(),
        "host": socket.gethostname(),
        "platform": platform.platform(),
        "revision_supplied_by_builder": args.source_revision,
        "driver_sha256": sha(__file__),
        "bounded_driver_sha256": sha(HERE / "prove_advanced.py"),
    }
    atomic_json(destination, receipt)
    try:
        require(
            all(
                limit > 0
                for limit in (
                    args.wall_seconds,
                    args.cpu_seconds,
                    args.rss_gib,
                    args.address_space_gib,
                )
            )
            and args.address_space_gib >= args.rss_gib,
            "invalid resource limits",
        )
        root = args.source_root.resolve(strict=True)
        full = root / "tests/gfx1250/full"
        contract, contract_path = ADVANCED.load_contract(full)
        inventory_path = full.parent / "full-parity/gaps.json"
        inventory = contract.validate_inventory(json.loads(inventory_path.read_text()))
        document = json.loads((full / "cases.json").read_text())
        contract.validate_registry(document, inventory, full, require_all=True)
        cases = selected_cases(document, args.kernel)
        require(
            sum(case["expected_outputs"] for case in document["cases"]) == 395394,
            "complete original395394-output registration required",
        )
        kernels = [case["kernel"] for case in cases]
        test = root / "crates/volta_py/tests/test_gfx1250_original_workloads.py"
        python = args.python.resolve(strict=True)
        packages = args.site_packages.resolve(strict=True)
        extensions = list((packages / "volta").glob("volta*.so"))
        require(len(extensions) == 1, "one exact native extension required")
        extension = extensions[0].resolve(strict=True)
        require(
            sha(extension) == args.extension_sha256, "native extension hash mismatch"
        )
        inputs = [test, contract_path, inventory_path, full / "cases.json"]
        for row in inventory.values():
            inputs += [root / row["baseline_path"], root / row["baseline_config_path"]]
        for case in document["cases"]:
            for key in ("source", "assembly", "spec", "launch_config"):
                path = full / case[key]
                require(
                    sha(path) == case[key + "_sha256"], "registered input hash mismatch"
                )
                inputs.append(path)
        inputs = {str(path): sha(path) for path in inputs}
        receipt.update(
            python=str(python),
            python_sha256=sha(python),
            extension=str(extension),
            extension_sha256=sha(extension),
            package_init_sha256=sha(packages / "volta/__init__.py"),
            selected_kernels=kernels,
            expected_outputs=sum(case["expected_outputs"] for case in cases),
            input_sha256=inputs,
        )
        env = dict(os.environ)
        require(
            not any(name in env for name in ("LD_PRELOAD", "LD_AUDIT")),
            "loader injection",
        )
        for name in ("VOLTA_VIZ_DIR", "RUST_LOG", "PYTHONHOME", "PYTHONSTARTUP"):
            env.pop(name, None)
        env.update(
            HIP_VISIBLE_DEVICES="",
            ROCR_VISIBLE_DEVICES="",
            CUDA_VISIBLE_DEVICES="",
            PYTHONPATH=str(packages),
            PYTHONNOUSERSITE="1",
            PYTHONDONTWRITEBYTECODE="1",
            PYTHONUNBUFFERED="1",
            PYTEST_DISABLE_PLUGIN_AUTOLOAD="1",
            VOLTA_GFX1250_ORIGINAL_FULL="1",
        )
        probe_script = (
            "import importlib,json,pathlib,sys,sysconfig;"
            "m=importlib.import_module('volta.volta');"
            "print(json.dumps({'version':sys.version,'soabi':sysconfig.get_config_var('SOABI'),"
            "'extension':str(pathlib.Path(m.__file__).resolve()),'pytest':__import__('pytest').__version__}))"
        )
        probe = subprocess.run(
            [str(python), "-c", probe_script],
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )
        require(probe.returncode == 0, f"Python ABI/import failure: {probe.stderr}")
        identity = json.loads(probe.stdout)
        require(
            Path(identity["extension"]) == extension,
            "a different native module was imported",
        )
        receipt["python_identity"] = identity
        libraries = subprocess.run(
            ["ldd", str(extension)], env=env, capture_output=True, text=True, timeout=30
        )
        require(
            libraries.returncode == 0 and "not found" not in libraries.stdout,
            "runtime mismatch",
        )
        interpreter_libraries = subprocess.run(
            ["ldd", str(python)], env=env, capture_output=True, text=True, timeout=30
        )
        require(
            interpreter_libraries.returncode == 0
            and "not found" not in interpreter_libraries.stdout,
            "Python interpreter runtime mismatch",
        )
        receipt["runtime_libraries"] = libraries.stdout
        receipt["interpreter_runtime_libraries"] = interpreter_libraries.stdout
        receipt["runtime_sha256"] = {
            str(Path(path).resolve(strict=True)): sha(path)
            for path in re.findall(
                r"(?:=>\s+)?(/[^\s]+)\s+\(",
                libraries.stdout + interpreter_libraries.stdout,
            )
        }
        limits = {
            "wall_seconds": args.wall_seconds,
            "cpu_seconds": args.cpu_seconds,
            "rss_bytes": args.rss_gib * 1024**3,
            "address_space_bytes": args.address_space_gib * 1024**3,
        }
        receipt["limits"] = limits
        atomic_json(destination, receipt)
        junit = output / "junit.xml"
        junit.unlink(missing_ok=True)
        command = [str(python), "-m", "pytest", "-vv", "-s", "-p", "no:cacheprovider"]
        command += [f"{test}::{TEST}[{kernel}]" for kernel in kernels]
        command += ["--junitxml", str(junit)]
        result = ADVANCED.bounded(command, output, env, limits)
        receipt["process"] = result
        require(
            result["exit_code"] == 0 and result["termination"] is None,
            "Python gate failed",
        )
        receipt["test_names"] = check_junit(junit, kernels)
        require(
            all(sha(path) == value for path, value in inputs.items()),
            "source inputs mutated",
        )
        require(sha(extension) == args.extension_sha256, "native extension mutated")
        require(
            sha(packages / "volta/__init__.py") == receipt["package_init_sha256"],
            "native package initializer mutated",
        )
        require(sha(python) == receipt["python_sha256"], "Python interpreter mutated")
        receipt["junit_sha256"] = sha(junit)
        receipt["status"] = "partial" if args.kernel else "pass"
    except (
        ValueError,
        OSError,
        KeyError,
        subprocess.SubprocessError,
        ET.ParseError,
    ) as error:
        receipt["status"] = "fail"
        receipt["error"] = f"{type(error).__name__}: {error}"
    finally:
        receipt["finished_unix"] = time.time()
        atomic_json(destination, receipt)
        print(
            json.dumps(
                {
                    key: receipt.get(key)
                    for key in ("status", "error", "selected_kernels")
                }
            )
        )
    return 0 if receipt["status"] in ("pass", "partial") else 1


if __name__ == "__main__":
    raise SystemExit(main())
