#!/usr/bin/env python3
"""Host-only accounting/refusal controls; these are not native proof runs."""

from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "python_proof_driver", HERE / "prove_python.py"
)
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)


class PythonProofControls(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = json.loads((HERE.parent / "cases.json").read_text())
        cls.kernels = [case["kernel"] for case in cls.document["cases"]]

    def xml(self, path, names):
        root = ET.Element("testsuites")
        suite = ET.SubElement(
            root,
            "testsuite",
            tests=str(len(names)),
            failures="0",
            errors="0",
            skipped="0",
        )
        for name in names:
            ET.SubElement(suite, "testcase", name=f"{DRIVER.TEST}[{name}]")
        ET.ElementTree(root).write(path)
        return root, suite

    def test_full_original_set_and_explicit_subset(self):
        self.assertEqual(len(DRIVER.selected_cases(self.document, [])), 32)
        self.assertEqual(
            len(DRIVER.selected_cases(self.document, [self.kernels[0]])), 1
        )
        for selection in [["unknown"], [self.kernels[0], self.kernels[0]]]:
            with self.assertRaises(ValueError):
                DRIVER.selected_cases(self.document, selection)

    def test_missing_duplicate_or_pending_original_is_refused(self):
        for kind in ("missing", "duplicate", "pending"):
            data = deepcopy(self.document)
            if kind == "missing":
                data["cases"].pop()
            elif kind == "duplicate":
                data["cases"][-1] = data["cases"][0]
            else:
                data["pending_baseline_ids"] = ["W32"]
            with self.assertRaises(ValueError):
                DRIVER.selected_cases(data, [])

    def test_complete_junit_is_required(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "junit.xml"
            self.xml(path, self.kernels)
            self.assertEqual(len(DRIVER.check_junit(path, self.kernels)), 32)
            self.xml(path, self.kernels[:-1])
            with self.assertRaises(ValueError):
                DRIVER.check_junit(path, self.kernels)
            self.xml(path, self.kernels[:-1] + [self.kernels[0]])
            with self.assertRaises(ValueError):
                DRIVER.check_junit(path, self.kernels)

    def test_failure_error_skip_and_hidden_child_never_pass(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "junit.xml"
            for tag, field in [
                ("failure", "failures"),
                ("error", "errors"),
                ("skipped", "skipped"),
            ]:
                root, suite = self.xml(path, self.kernels)
                suite.set(field, "1")
                ET.SubElement(suite.find("testcase"), tag)
                ET.ElementTree(root).write(path)
                with self.assertRaises(ValueError):
                    DRIVER.check_junit(path, self.kernels)
                suite.set(field, "0")
                ET.ElementTree(root).write(path)
                with self.assertRaises(ValueError):
                    DRIVER.check_junit(path, self.kernels)

    def test_wrong_native_module_cannot_start_a_proof(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            package = root / "volta"
            package.mkdir()
            (package / "volta.fake.so").write_bytes(b"not the pinned extension")
            result = subprocess.run(
                [
                    sys.executable,
                    str(HERE / "prove_python.py"),
                    "--python",
                    sys.executable,
                    "--site-packages",
                    str(root),
                    "--extension-sha256",
                    "0" * 64,
                    "--source-root",
                    str(HERE.parents[3]),
                    "--source-revision",
                    "host-control",
                    "--output",
                    str(root / "output"),
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )
            self.assertEqual(result.returncode, 1)
            receipt = json.loads((root / "output/receipt.json").read_text())
            self.assertIn("native extension hash mismatch", receipt["error"])
            self.assertNotIn("process", receipt)

    def test_failed_preflight_replaces_stale_pass_receipt(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            output = root / "output"
            output.mkdir()
            (output / "receipt.json").write_text('{"status":"pass"}')
            result = subprocess.run(
                [
                    sys.executable,
                    str(HERE / "prove_python.py"),
                    "--python",
                    sys.executable,
                    "--site-packages",
                    str(root),
                    "--extension-sha256",
                    "0" * 64,
                    "--source-root",
                    str(root / "absent"),
                    "--source-revision",
                    "host-control",
                    "--output",
                    str(output),
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )
            self.assertEqual(result.returncode, 1)
            receipt = json.loads((output / "receipt.json").read_text())
            self.assertEqual(receipt["status"], "fail")
            self.assertIs(receipt["hardware_execution"], False)
            self.assertNotIn("test_names", receipt)


if __name__ == "__main__":
    unittest.main()
