"""Host controls for full-proof selection, verdicts, receipts and timeouts."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

import prove_matrix as driver


def manifest():
    cases = []
    for name, (identity, rows, columns) in driver.REQUIRED.items():
        cases.append({
            "kernel": name, "baseline_id": identity, "required": True,
            "reduced_case": False, "dimensions": {"M": 4096, "N": 4096, "K": 4096},
            "expected_outputs": rows * columns,
            "block": [1024 if name.startswith("gemm") else 256, 1, 1],
            "grid": [1, 1, 1], "workgroup": [0, 0, 0],
            "output_projection": [{"baseline_array": "c", "baseline_start": r * 4096,
                                   "native_array": f"out{r:03}", "native_start": 0,
                                   "length": columns} for r in range(rows)],
        })
    return {"cases": cases}


def accepted():
    return ("\n".join(f"  {name} (algorithm) PASS" for name in driver.PROPERTIES)
            + "\nVC check: 1.0s (decision procedure 1.0s)  elements: 65536\n"
            + "EQUIVALENT (matches spec)\nVERDICT: ACCEPT\n")


class Controls(unittest.TestCase):
    def test_shared_readonly_fixture_is_verified_once_without_recopied_writes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, target = root / "source", root / "snapshot/input"
            source.write_text("same assembly for six entries")
            digest = driver.sha(source)
            driver.snapshot_file(source, target, digest)
            with mock.patch.object(driver.shutil, "copy2", side_effect=AssertionError("duplicate copy")):
                driver.snapshot_file(source, target, digest)
            self.assertEqual(target.stat().st_mode & 0o222, 0)
            source.write_text("changed assembly")
            with self.assertRaises(ValueError):
                driver.snapshot_file(source, target, driver.sha(source))

    def test_full_and_explicit_nonempty_selection(self):
        self.assertEqual(len(driver.checked_cases(manifest(), [])), 6)
        self.assertEqual(len(driver.checked_cases(manifest(), ["gemm_f16_full"])), 1)
        for bad in [[], manifest()["cases"] * 2]:
            with self.assertRaises(ValueError):
                driver.checked_cases({"cases": bad}, [])
        for bad in [["unknown"], ["gemm_f16_full"] * 2]:
            with self.assertRaises(ValueError):
                driver.checked_cases(manifest(), bad)

    def test_reduced_k_missing_rows_and_changed_physical_pitch_reject(self):
        for field in ["K", "projection", "pitch", "count", "reduced"]:
            document = copy.deepcopy(manifest())
            case = document["cases"][0]
            if field == "K": case["dimensions"]["K"] = 32
            if field == "projection": case["output_projection"].pop()
            if field == "pitch": case["output_projection"][1]["baseline_start"] = 256
            if field == "count": case["expected_outputs"] = 16
            if field == "reduced": case["reduced_case"] = True
            with self.assertRaises(ValueError, msg=field):
                driver.checked_cases(document, [])

    def test_acceptance_requires_every_property_and_full_vc_count(self):
        driver.check_stdout(accepted(), 65536)
        variants = [accepted().replace("elements: 65536", "elements: 16/65536"),
                    accepted().replace("elements: 65536", "elements: 16"),
                    accepted().replace("VERDICT: ACCEPT", "VERDICT: UNKNOWN"),
                    accepted().replace("EQUIVALENT (matches spec)", ""),
                    accepted() + "VERDICT: ACCEPT\n"]
        variants += [accepted().replace(name + " (algorithm) PASS", name + " (algorithm) UNKNOWN")
                     for name in driver.PROPERTIES]
        for text in variants:
            with self.assertRaises(ValueError):
                driver.check_stdout(text, 65536)

    def test_preflight_failure_overwrites_a_prior_success_receipt(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "receipt.json").write_text('{"status":"pass"}')
            result = subprocess.run([sys.executable, driver.__file__, "--binary", "/missing",
                                     "--fixture-root", "/missing", "--revision", "test",
                                     "--output", str(root)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            receipt = json.loads((root / "receipt.json").read_text())
            self.assertEqual(receipt["status"], "incomplete")
            self.assertFalse(receipt["hardware_execution"])
            self.assertEqual(receipt["results"], [])

    def test_wall_timeout_is_a_failed_bounded_process(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = driver.bounded([sys.executable, "-c", "import time; time.sleep(30)"],
                                    Path(tmp), dict(__import__("os").environ),
                                    {"wall_seconds": 1, "cpu_seconds": 5,
                                     "rss_bytes": 64 * 1024**2,
                                     "address_space_bytes": 256 * 1024**2})
            self.assertEqual(result["termination"], "wall_timeout")
            self.assertNotEqual(result["exit_code"], 0)


if __name__ == "__main__":
    unittest.main()
