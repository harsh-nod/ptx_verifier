"""Host-only controls for the standalone descriptive p95 postprocessor."""

import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("safe_overhead.py")
spec = importlib.util.spec_from_file_location("safe_overhead", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def report():
    cases = []
    samples = []
    for name, expectation in [("safe", "safe"), ("hazard", "hazard")]:
        cases.append(
            {
                "case": name,
                "expectation": expectation,
                "baseline": {"repeated_process_p95_seconds": 3.0},
                "candidate": {"repeated_process_p95_seconds": 6.0},
                "safe_overhead_gates": {"p95": False},
            }
        )
        for variant, scale in [("baseline", 1), ("candidate", 2)]:
            for repeat in range(4):
                samples.append(
                    {
                        "case": name,
                        "variant": variant,
                        "repeat": repeat,
                        "seconds": scale * (repeat if repeat else 999),
                        "classification": "verified",
                        "timed_out": False,
                        "measurement_errors": [],
                    }
                )
    return {
        "repeated_process_samples": 3,
        "seed": 17,
        "summary": {"cases": cases, "total_configurations": 2},
        "samples": samples,
        "source_comparison": {
            "common_parent": "base",
            "baseline_revision": "base",
            "candidate_revision": "candidate",
        },
        "variants": [
            {"name": name, "binary_revision": revision, "binary_sha256": "0" * 64}
            for name, revision in [("baseline", "base"), ("candidate", "candidate")]
        ],
        **{
            name: "0" * 64
            for name in module.IDENTITY_FIELDS
            if name not in ("source_comparison", "variants")
        },
    }


class SafeOverheadTests(unittest.TestCase):
    def test_counts_are_derived_and_first_sample_excluded(self):
        result = module.intervals(report(), seed=20261031, resamples=20)
        self.assertEqual(result["safe_configurations"], 1)
        self.assertEqual(result["paired_repeated_observations"], 3)
        self.assertEqual(result["cases"][0]["baseline_p95_seconds"], 3)
        self.assertEqual(result["cases"][0]["candidate_p95_seconds"], 6)
        self.assertFalse(result["cases"][0]["fixed_gate_pass"])
        self.assertEqual(result["report_identity"]["variants"], report()["variants"])

    def test_duplicate_and_missing_pairs_refused_even_for_hazard_rows(self):
        for name in ("safe", "hazard"):
            for mutation in ("duplicate", "missing"):
                changed = report()
                index = next(
                    i
                    for i, row in enumerate(changed["samples"])
                    if row["case"] == name and row["repeat"] == 2
                )
                if mutation == "duplicate":
                    changed["samples"].append(copy.deepcopy(changed["samples"][index]))
                else:
                    changed["samples"].pop(index)
                with (
                    self.subTest(case=name, mutation=mutation),
                    self.assertRaisesRegex(ValueError, "pair member"),
                ):
                    module.validate_report(changed)

    def test_bad_repeats_durations_and_stored_summaries_refused(self):
        for value in (0, -1, True):
            changed = report()
            changed["repeated_process_samples"] = value
            with self.subTest(repeats=value), self.assertRaises(ValueError):
                module.validate_report(changed)
        for value in (0, -1, True, float("nan"), float("inf")):
            changed = report()
            changed["samples"][1]["seconds"] = value
            with self.subTest(seconds=value), self.assertRaises(ValueError):
                module.validate_report(changed)
        for field in ("summary_case", "repeat", "variant", "p95", "gate"):
            changed = report()
            if field == "summary_case":
                changed["summary"]["cases"].append(
                    copy.deepcopy(changed["summary"]["cases"][0])
                )
            if field == "repeat":
                changed["samples"][1]["repeat"] = True
            if field == "variant":
                changed["samples"][1]["variant"] = "unexpected"
            if field == "p95":
                changed["summary"]["cases"][0]["baseline"][
                    "repeated_process_p95_seconds"
                ] = 2
            if field == "gate":
                changed["summary"]["cases"][0]["safe_overhead_gates"]["p95"] = True
            with self.subTest(field=field), self.assertRaises(ValueError):
                module.intervals(changed, seed=1, resamples=2)

    def test_cli_refuses_overwrite_and_input_aliases_without_modification(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "report.json"
            original = json.dumps(report())
            source.write_text(original)
            existing = root / "existing.json"
            existing.write_text("preserve me")
            alias = root / "alias.json"
            alias.symlink_to(source)
            hardlink = root / "hardlink.json"
            hardlink.hardlink_to(source)
            for output in (source, existing, alias, hardlink):
                run = subprocess.run(
                    [
                        sys.executable,
                        str(SCRIPT),
                        str(source),
                        "--output",
                        str(output),
                        "--resamples",
                        "2",
                    ],
                    capture_output=True,
                    text=True,
                )
                with self.subTest(output=output):
                    self.assertEqual(run.returncode, 2)
                    self.assertTrue(
                        "already exists" in run.stderr or "aliases input" in run.stderr
                    )
                    self.assertEqual(source.read_text(), original)
                    self.assertEqual(existing.read_text(), "preserve me")

    def test_cli_rejects_invalid_resample_count(self):
        run = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "/nonexistent",
                "--output",
                "/nonexistent",
                "--resamples",
                "0",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(run.returncode, 2)
        self.assertIn("positive integer", run.stderr)


if __name__ == "__main__":
    unittest.main()
