"""Synthetic host accounting controls; no interpreter/GPU proof is performed."""

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("aggregate_python", HERE / "aggregate_python.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AggregateControls(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.registry = (HERE.parent / "cases.json").resolve()
        cls.cases = json.loads(cls.registry.read_text())["cases"]
        cls.inputs = MODULE.required_input_pins(cls.registry)

    def fixture(self):
        temp = tempfile.TemporaryDirectory(prefix="ptx-python-aggregate-control-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        python = root / "python-control"
        python.write_bytes(b"host schema control, not a real Python execution")
        package = root / "volta"
        package.mkdir()
        (package / "__init__.py").write_bytes(b"# host schema control")
        extension = package / "volta.control.so"
        extension.write_bytes(b"host schema control, not a native extension")
        runtime = root / "runtime-control"
        runtime.write_bytes(b"host schema control")
        identity = {
            "revision_supplied_by_builder": "1" * 40,
            "driver_sha256": MODULE.sha(HERE / "prove_python.py"),
            "bounded_driver_sha256": MODULE.sha(HERE / "prove_advanced.py"),
            "python": str(python), "python_sha256": MODULE.sha(python),
            "extension": str(extension), "extension_sha256": MODULE.sha(extension),
            "package_init_sha256": MODULE.sha(package / "__init__.py"),
            "python_identity": {"version": "host control", "soabi": "host control"},
            "runtime_sha256": {str(runtime): MODULE.sha(runtime)},
            "input_sha256": self.inputs,
            "host": "synthetic-host-control", "platform": "synthetic-host-control",
        }
        paths = []
        test = next(path for path in self.inputs if path.endswith("test_gfx1250_original_workloads.py"))
        for index in range(4):
            directory = root / f"group{index}"
            directory.mkdir()
            cases = self.cases[index * 8:(index + 1) * 8]
            names = [case["kernel"] for case in cases]
            junit = directory / "junit.xml"
            tree = ET.Element("testsuites")
            suite = ET.SubElement(tree, "testsuite", tests="8", failures="0", errors="0", skipped="0")
            for name in names:
                ET.SubElement(suite, "testcase", name=f"{MODULE.DRIVER.TEST}[{name}]")
            ET.ElementTree(tree).write(junit)
            for stream in ("stdout", "stderr"):
                (directory / (stream + ".txt")).write_bytes(b"synthetic host accounting control")
            argv = [str(python), "-m", "pytest", "-vv", "-s", "-p", "no:cacheprovider"]
            argv += [f"{test}::{MODULE.DRIVER.TEST}[{name}]" for name in names]
            argv += ["--junitxml", str(junit)]
            record = {
                **identity, "status": "partial", "hardware_execution": False,
                "gate": "existing full original Python analyze/index/verify/numeric regression",
                "selected_kernels": names,
                "expected_outputs": sum(case["expected_outputs"] for case in cases),
                "started_unix": 1, "finished_unix": 2,
                "test_names": [f"{MODULE.DRIVER.TEST}[{name}]" for name in names],
                "junit_sha256": MODULE.sha(junit),
                "process": {
                    "exit_code": 0, "termination": None, "elapsed_seconds": 1,
                    "argv": argv,
                    "stdout_sha256": MODULE.sha(directory / "stdout.txt"),
                    "stderr_sha256": MODULE.sha(directory / "stderr.txt"),
                },
            }
            path = directory / "receipt.json"
            path.write_text(json.dumps(record))
            paths.append(path)
        return root, paths

    def change(self, path, key, value):
        record = json.loads(path.read_text())
        record[key] = value
        path.write_text(json.dumps(record))

    def test_disjoint_all32_accounting_has_exact_complete_footprint(self):
        _, paths = self.fixture()
        result = MODULE.aggregate(self.registry, paths)
        self.assertEqual((result["case_count"], result["expected_outputs"]), (32, 395394))

    def test_missing_duplicate_and_overlapping_groups_are_refused(self):
        for mutation in ("missing", "same_path", "overlap"):
            _, paths = self.fixture()
            if mutation == "missing":
                paths.pop()
            elif mutation == "same_path":
                paths[-1] = paths[0]
            else:
                record = json.loads(paths[0].read_text())
                target = json.loads(paths[1].read_text())
                target["selected_kernels"] = record["selected_kernels"]
                paths[1].write_text(json.dumps(target))
            with self.assertRaises(ValueError):
                MODULE.aggregate(self.registry, paths)

    def test_failed_incomplete_zero_output_and_skipped_group_are_refused(self):
        for key, value in [("status", "incomplete"), ("status", "fail"),
                           ("expected_outputs", 0), ("test_names", [])]:
            _, paths = self.fixture()
            self.change(paths[1], key, value)
            with self.assertRaises(ValueError):
                MODULE.aggregate(self.registry, paths)
        _, paths = self.fixture()
        junit = paths[0].parent / "junit.xml"
        tree = ET.parse(junit)
        ET.SubElement(next(tree.iter("testcase")), "skipped")
        tree.write(junit)
        self.change(paths[0], "junit_sha256", MODULE.sha(junit))
        with self.assertRaisesRegex(ValueError, "hidden unsuccessful"):
            MODULE.aggregate(self.registry, paths)

    def test_mixed_source_runtime_extension_interpreter_or_abi_cannot_pass(self):
        for key in MODULE.IDENTITY_KEYS:
            _, paths = self.fixture()
            record = json.loads(paths[1].read_text())
            value = record[key]
            record[key] = {**value, "changed": "control"} if isinstance(value, dict) else value + "changed"
            paths[1].write_text(json.dumps(record))
            with self.assertRaises((ValueError, OSError)):
                MODULE.aggregate(self.registry, paths)

    def test_missing_source_pin_changed_artifact_and_filtered_argv_are_refused(self):
        for mutation in ("input", "stdout", "argv"):
            _, paths = self.fixture()
            record = json.loads(paths[0].read_text())
            if mutation == "input":
                record["input_sha256"].pop(next(iter(record["input_sha256"])))
            elif mutation == "stdout":
                (paths[0].parent / "stdout.txt").write_bytes(b"changed")
            else:
                record["process"]["argv"] += ["-k", "partial"]
            paths[0].write_text(json.dumps(record))
            with self.assertRaises(ValueError):
                MODULE.aggregate(self.registry, paths)

    def test_operational_preflight_replaces_a_stale_pass(self):
        root, _ = self.fixture()
        output = root / "aggregate.json"
        output.write_text('{"status":"pass"}')
        run = subprocess.run([
            sys.executable, str(HERE / "aggregate_python.py"),
            "--registry", str(self.registry), "--receipt", str(root / "missing.json"),
            "--output", str(output),
        ], capture_output=True, text=True, timeout=30)
        self.assertEqual(run.returncode, 1)
        result = json.loads(output.read_text())
        self.assertEqual(result["status"], "fail")
        self.assertIs(result["sampling"], False)
        self.assertNotIn("case_count", result)

    def test_registry_junit_extension_and_hardlink_outputs_preserve_all_inputs(self):
        for kind in ("registry", "junit", "extension", "hardlink"):
            root, paths = self.fixture()
            registry = root / "registry.json"
            registry.write_bytes(self.registry.read_bytes())
            record = json.loads(paths[0].read_text())
            source = {"registry": registry, "junit": paths[0].parent / "junit.xml",
                      "extension": Path(record["extension"]),
                      "hardlink": Path(record["extension"])}[kind]
            output = source
            if kind == "hardlink":
                output = root / "extension-alias.json"
                output.hardlink_to(source)
            before = source.read_bytes()
            run = subprocess.run([
                sys.executable, str(HERE / "aggregate_python.py"),
                "--registry", str(registry), "--receipt", str(paths[0]),
                "--output", str(output),
            ], capture_output=True, text=True, timeout=30)
            self.assertEqual(run.returncode, 2)
            self.assertIn("aliases retained input artifact", run.stderr)
            self.assertEqual(source.read_bytes(), before)
            self.assertEqual(output.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
