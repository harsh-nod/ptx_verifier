"""Host refusal/resource controls; these are not native proof or hardware evidence."""

import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import prove_advanced as driver

FULL = Path(__file__).resolve().parents[1]


def accepted(count=8192):
    return (
        "\n".join(f"  {name} (algorithm) PASS" for name in driver.PROPERTIES)
        + f"\nVC check: 1.0s (decision procedure 1.0s)  elements: {count}\n"
        + "EQUIVALENT (matches spec)\nVERDICT: ACCEPT\n"
    )


class Controls(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = json.loads((FULL / "cases.json").read_text())
        cls.contract, _ = driver.load_contract(FULL)
        inventory = json.loads((FULL.parent / "full-parity/gaps.json").read_text())
        cls.rows = cls.contract.validate_inventory(inventory)

    def test_exact_eight_or_explicit_unique_subset(self):
        self.assertEqual(8, len(driver.checked_cases(self.document, [])))
        self.assertEqual(
            65824,
            sum(c["expected_outputs"] for c in driver.checked_cases(self.document, [])),
        )
        self.assertEqual(
            1, len(driver.checked_cases(self.document, ["mamba_scan_original"]))
        )
        for selection in [["unknown"], ["mamba_scan_original"] * 2]:
            with self.assertRaises(ValueError):
                driver.checked_cases(self.document, selection)
        for candidates in [[], self.document["cases"] * 2, self.document["cases"][:18]]:
            with self.assertRaises(ValueError):
                driver.checked_cases({"cases": candidates}, [])

    def test_reduced_original_shapes_missing_output_arrays_and_changed_dtype_reject(
        self,
    ):
        mutations = [
            ("W19", lambda c: c["dimensions"].update(C=16)),
            ("W20", lambda c: c["arrays"][0].update(dtype="f32", element_size=4)),
            ("W23", lambda c: c.update(grid=[1, 1, 1])),
            ("W24", lambda c: c["arrays"][4].update(length=1)),
            ("W25", lambda c: c["dimensions"].update(T=32)),
            ("W26", lambda c: c["output_projection"].pop()),
        ]
        for identity, mutate in mutations:
            document = copy.deepcopy(self.document)
            case = next(c for c in document["cases"] if c["baseline_id"] == identity)
            mutate(case)
            with self.subTest(identity=identity), self.assertRaises(ValueError):
                self.contract.validate_registry(
                    document, self.rows, FULL, require_all=True
                )

    def test_all_four_graph_properties_full_count_and_final_accept_are_mandatory(self):
        driver.check_stdout(accepted(), 8192)
        variants = [
            accepted().replace("elements: 8192", "elements: 16/8192"),
            accepted().replace("elements: 8192", "elements: 4096"),
            accepted().replace("VERDICT: ACCEPT", "VERDICT: UNKNOWN"),
            accepted().replace("VERDICT: ACCEPT", "VERDICT: REJECT"),
            accepted().replace("EQUIVALENT (matches spec)", ""),
            accepted() + "VERDICT: ACCEPT\n",
            accepted() + f"  {driver.PROPERTIES[0]} (algorithm) UNKNOWN\n",
        ]
        variants += [
            accepted().replace(
                name + " (algorithm) PASS", name + " (algorithm) UNKNOWN"
            )
            for name in driver.PROPERTIES
        ]
        for output in variants:
            with self.assertRaises(ValueError):
                driver.check_stdout(output, 8192)

    def test_preflight_failure_cannot_leave_stale_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)
            (output / "receipt.json").write_text('{"status":"pass"}')
            result = subprocess.run(
                [
                    sys.executable,
                    driver.__file__,
                    "--binary",
                    "/missing",
                    "--binary-revision",
                    "host-control",
                    "--fixture-root",
                    "/missing",
                    "--fixture-revision",
                    "host-control",
                    "--output",
                    str(output),
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )
            self.assertEqual(1, result.returncode)
            receipt = json.loads((output / "receipt.json").read_text())
            self.assertEqual("incomplete", receipt["status"])
            self.assertFalse(receipt["hardware_execution"])
            self.assertEqual([], receipt["results"])

    def test_timeout_and_nonzero_child_exit_remain_failures(self):
        limits = {
            "wall_seconds": 1,
            "cpu_seconds": 5,
            "rss_bytes": 64 * 1024**2,
            "address_space_bytes": 256 * 1024**2,
        }
        with tempfile.TemporaryDirectory() as tmp:
            result = driver.bounded(
                [sys.executable, "-c", "import time; time.sleep(30)"],
                Path(tmp),
                dict(os.environ),
                limits,
            )
            self.assertEqual("wall_timeout", result["termination"])
            self.assertNotEqual(0, result["exit_code"])
            result = driver.bounded(
                [sys.executable, "-c", "raise SystemExit(2)"],
                Path(tmp),
                dict(os.environ),
                limits,
            )
            self.assertIsNone(result["termination"])
            self.assertEqual(2, result["exit_code"])
            with self.assertRaises(ValueError):
                driver.check_stdout((Path(tmp) / "stdout.txt").read_text(), 8192)


if __name__ == "__main__":
    unittest.main()
