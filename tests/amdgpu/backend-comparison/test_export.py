"""Synthetic metadata controls for publication; none are measured GPU results."""

import argparse
import contextlib
import csv
import gzip
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock


def module(name, filename):
    spec = importlib.util.spec_from_file_location(
        name, Path(__file__).with_name(filename)
    )
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


publisher = module("amd_result_export", "export.py")
comparison = module("amd_publication_summary", "compare.py")


class ExportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="secret-user-host-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repository = self.root / "original"
        self.harness = self.repository / "tests/amdgpu/backend-comparison/compare.py"
        self.harness.parent.mkdir(parents=True)
        # This dependency stub stands for a successful frozen collection audit.
        # The real audit's graph/command/round controls have separate tests.
        self.harness.write_text("""from pathlib import Path
import hashlib, json
ROOT = Path(__file__).resolve().parents[3]
def unchanged(pins):
    for path, expected in pins.items():
        if hashlib.sha256(Path(path).read_bytes()).hexdigest() != expected:
            raise ValueError("synthetic artifact changed")
def audit_collection(path, plan, expected):
    result = json.loads(path.read_text())
    if result["status"] != "COMPLETE" or not result["audit_valid"] or result["plan_sha256"] != expected:
        raise ValueError("synthetic audit refused")
    unchanged({str(path.parent / "samples.json"): result["samples_sha256"],
               str(path.parent / "schedule.json"): result["schedule_sha256"],
               **{value: result["qualification_sha256"][arm] for arm, value in result["qualification_paths"].items()}})
    return result
""")
        self.plan_path, self.report_path = (
            self.root / "plan.json",
            self.root / "report.json",
        )
        self.case_list = []
        for index in range(67):
            self.case_list.append(
                {
                    "id": f"synthetic-{index}",
                    "target": "gfx942"
                    if index < 18
                    else "gfx950"
                    if index < 27
                    else "gfx1250",
                    "family": "synthetic",
                    "expectation": "safe" if index < 43 else "hazard",
                    "expected_outputs": 2,
                }
            )
        self.plan = {
            "cases": [
                {"case": case, "assembly_sha256": "1" * 64} for case in self.case_list
            ],
            "input_sha256": {str(self.harness): publisher.sha(self.harness)},
            "case_digest": "a" * 64,
        }
        self.write(self.plan_path, self.plan)
        self.plan_hash = publisher.sha(self.plan_path)
        self.qualifications, identities = {}, {}
        for arm in publisher.ARMS:
            identities[arm] = {
                "revision": ("a" if arm == "baseline" else "b") * 40,
                "source_tree": "c" * 40,
                "binary_sha256": "d" * 64,
                "receipt_sha256": "e" * 64,
                "trust": "caller_attested",
                "source_clean": True,
                "profile": "release",
                "default_features": True,
                "features": [],
                "rustc": "rustc 1.97.1 (8bab26f4f 2026-07-14)",
                "cargo": "cargo 1.97.1 (c980f4866 2026-06-30)",
                "binary": "/home/secret-user-host/bin/volta",
                "build_record": "/home/secret-user-host/build.json",
                "command": ["ssh", "secret-host", "secret-build-command"],
                "machine_uuid": "GPU-secret-uuid",
            }
            rows = []
            for case in self.case_list:
                safe = case["expectation"] == "safe"
                rows.append(
                    {
                        "id": case["id"],
                        "qualified": not (
                            arm == "candidate" and case["id"] == "synthetic-66"
                        ),
                        "analysis": {
                            "classification": "verified" if safe else "finding",
                            "graph_accepted": safe,
                            "detected_expected_hazard": not safe,
                            "false_positive": False,
                            "false_acceptance": False,
                            "output_expressions_sha256": "f" * 64 if safe else None,
                            "reason": "secret-host 0000:01:00.0 GPU-secret-uuid /home/secret-user-host",
                        },
                        "proof": {"proved": True, "proof_counts": ["2"]}
                        if safe
                        else None,
                    }
                )
            self.qualifications[arm] = {"results": rows}
            self.write(self.root / (arm + ".json"), self.qualifications[arm])
        self.samples = []
        precision = float.fromhex("0x1.0000000000001p-20")
        for index in range(32):
            for case in self.case_list:
                for arm in publisher.ARMS:
                    safe = case["expectation"] == "safe"
                    missed = (
                        arm == "candidate"
                        and index == 31
                        and case["id"] == "synthetic-66"
                    )
                    value = precision * (2 if arm == "candidate" else 1)
                    self.samples.append(
                        {
                            "id": case["id"],
                            "arm": arm,
                            "round": index,
                            "classification": "unsupported"
                            if missed
                            else "graph_accepted_without_export"
                            if safe
                            else "finding",
                            "returncode": 2 if missed else 0 if safe else 1,
                            "timed_out": False,
                            "seconds": 100.0 if index == 0 else value,
                            "time_to_detection_seconds": None
                            if safe or missed
                            else precision / 2,
                            "peak_rss_kib": 9007199254740993,
                            "user_seconds": float.fromhex("0x0.0000000000001p-1022"),
                            "system_seconds": 0.0,
                            "reported_execution_seconds": None,
                            "executed_instructions": 123,
                            "graph_accepted": safe,
                            "detected_expected_hazard": not safe and not missed,
                            "false_positive": False,
                            "false_acceptance": False,
                            "detected_property": "AMD wait and register readiness"
                            if not safe and not missed
                            else None,
                            "measurement_errors": ["secret-machine-resource-error"]
                            if missed
                            else [],
                            "command": [
                                "ssh",
                                "secret-host",
                                "/home/secret-user-host/volta",
                            ],
                            "launch_contract": {
                                "effective_path": "/home/secret-user-host/private.json"
                            },
                        }
                    )
        self.write(self.root / "samples.json", self.samples)
        self.write(self.root / "schedule.json", {"synthetic": True})
        qualified = {
            arm: {row["id"]: row for row in data["results"]}
            for arm, data in self.qualifications.items()
        }
        self.report = {
            "status": "COMPLETE",
            "audit_valid": True,
            "plan_sha256": self.plan_hash,
            "repeats": 31,
            "seed": 20261106,
            "eligible": [case["id"] for case in self.case_list],
            "identities": identities,
            "qualification_paths": {
                arm: str(self.root / (arm + ".json")) for arm in publisher.ARMS
            },
            "qualification_sha256": {
                arm: publisher.sha(self.root / (arm + ".json"))
                for arm in publisher.ARMS
            },
            "samples_sha256": publisher.sha(self.root / "samples.json"),
            "schedule_sha256": publisher.sha(self.root / "schedule.json"),
            "context": {
                "system": "secret-host /home/secret-user-host",
                "cpu_model": "AMD secret-host CPU",
                "cpu_count": 64,
                "load_before": [1.0, 2.0, 3.0],
                "round_loads": [
                    {"round": i, "load": [0.0, 0.0, 0.0]} for i in range(32)
                ],
                "uuid": "GPU-secret-uuid",
            },
            "results": comparison.summaries(
                self.plan["cases"],
                self.samples,
                qualified["baseline"],
                qualified["candidate"],
            ),
        }
        self.write(self.report_path, self.report)

    @staticmethod
    def write(path, value):
        path.write_bytes(publisher.json_bytes(value))

    def run_export(self, name="publication"):
        output = self.root / name
        with contextlib.redirect_stdout(io.StringIO()):
            publisher.export(
                argparse.Namespace(
                    harness=self.harness,
                    plan=self.plan_path,
                    plan_sha256=self.plan_hash,
                    report=self.report_path,
                    output=output,
                )
            )
        return output

    def test_full_population_failures_first_observations_and_precision_survive(self):
        output = self.run_export()
        document = json.loads((output / "results.json").read_text())
        samples = json.loads(gzip.decompress((output / "samples.json.gz").read_bytes()))
        csv_rows = list(
            csv.DictReader(
                io.StringIO(
                    gzip.decompress((output / "samples.csv.gz").read_bytes()).decode()
                )
            )
        )
        self.assertEqual(len(document["results"]), 67)
        self.assertEqual(len(samples), 4288)
        self.assertEqual(len(csv_rows), 4288)
        self.assertEqual(document["denominators"]["first_observations"], 134)
        self.assertEqual(document["denominators"]["repeated_observations"], 4154)
        self.assertEqual(document["denominators"]["functional_regressions"], 1)
        self.assertEqual(document["denominators"]["eligible_ratios"], 66)
        self.assertEqual(document["context"]["cpu_model"], "AMD CPU")
        row = document["results"][-1]
        self.assertIsNone(row["candidate_over_baseline_median"])
        self.assertEqual(row["candidate"]["repeated_misses"], 1)
        self.assertEqual(row["candidate"]["repeated_resource_errors"], 1)
        self.assertEqual(document["results"][0]["baseline"]["first"]["seconds"], 100.0)
        self.assertEqual(
            document["results"][0]["baseline"]["median_seconds"],
            self.samples[134]["seconds"],
        )
        for original, decoded, csv_row in zip(self.samples, samples, csv_rows):
            for key in publisher.NUMBERS:
                self.assertEqual(original[key], decoded[key])
                self.assertEqual(
                    original[key], json.loads(csv_row[key]) if csv_row[key] else None
                )
            self.assertEqual(original["round"], decoded["round"])

    def test_output_contains_no_private_strings_paths_or_commands(self):
        output = self.run_export()
        for path in output.iterdir():
            contents = (
                gzip.decompress(path.read_bytes())
                if path.suffix == ".gz"
                else path.read_bytes()
            )
            for forbidden in (
                b"secret-user-host",
                b"secret-host",
                b"GPU-secret-uuid",
                b"0000:01:00.0",
                b"secret-build-command",
                b'"command"',
                str(self.root).encode(),
            ):
                self.assertNotIn(forbidden, contents, str(path))
        document = json.loads((output / "results.json").read_text())
        self.assertEqual(
            document["frozen_input_sha256"],
            {"tests/amdgpu/backend-comparison/compare.py": publisher.sha(self.harness)},
        )
        self.assertEqual(
            document["identities"]["baseline"]["binary_sha256"],
            self.report["identities"]["baseline"]["binary_sha256"],
        )
        self.assertEqual(
            document["provenance"]["raw_report_sha256"], publisher.sha(self.report_path)
        )

    def test_export_is_byte_deterministic_and_manifest_binds_every_file(self):
        left, right = self.run_export("one"), self.run_export("two")
        manifest = json.loads((left / "manifest.json").read_text())
        for path in left.iterdir():
            self.assertEqual(path.read_bytes(), (right / path.name).read_bytes())
            if path.suffix == ".gz":
                self.assertEqual(path.read_bytes()[4:8], b"\0\0\0\0")
        for name, value in manifest["files_sha256"].items():
            self.assertEqual(publisher.sha(left / name), value)

    def test_refused_audit_and_tampered_bound_inputs_produce_no_export(self):
        for change in ("plan", "harness", "samples", "qualification", "audit refusal"):
            with self.subTest(change=change):
                paths = (
                    self.plan_path,
                    self.harness,
                    self.root / "samples.json",
                    self.root / "baseline.json",
                    self.report_path,
                )
                original = {path: path.read_bytes() for path in paths}
                if change == "audit refusal":
                    self.report["audit_valid"] = False
                    self.write(self.report_path, self.report)
                else:
                    path = paths[
                        ("plan", "harness", "samples", "qualification").index(change)
                    ]
                    path.write_bytes(path.read_bytes() + b"\n")
                with self.assertRaises(ValueError):
                    self.run_export()
                self.assertFalse((self.root / "publication").exists())
                for path, data in original.items():
                    path.write_bytes(data)

    def test_metadata_mutation_during_export_is_refused(self):
        real = publisher.publication

        def changed(*args):
            result = real(*args)
            self.report_path.write_bytes(self.report_path.read_bytes() + b"\n")
            return result

        with (
            mock.patch.object(publisher, "publication", side_effect=changed),
            self.assertRaises(ValueError),
        ):
            self.run_export()
        self.assertFalse((self.root / "publication").exists())

    def test_changed_dependency_is_refused_before_import(self):
        dependency = self.repository / "support.py"
        dependency.write_text("synthetic support helper\n")
        plan = {
            **self.plan,
            "input_sha256": {
                **self.plan["input_sha256"],
                str(dependency): publisher.sha(dependency),
            },
        }
        dependency.write_text("changed helper\n")
        with (
            mock.patch.object(
                publisher.importlib.util, "spec_from_file_location"
            ) as importing,
            self.assertRaises(ValueError),
        ):
            publisher.load_harness(self.harness, plan)
        importing.assert_not_called()

    def test_existing_or_repository_output_is_refused(self):
        (self.root / "existing").mkdir()
        for name in ("existing", "original/published"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.run_export(name)

    def test_nonfinite_numbers_and_missing_case_or_sample_are_refused(self):
        for value in (float("nan"), float("inf")):
            with self.assertRaises(ValueError):
                publisher.number(value)
        for changed in (self.samples[:-1], self.samples):
            plan = (
                {**self.plan, "cases": self.plan["cases"][:-1]}
                if len(changed) == len(self.samples)
                else self.plan
            )
            with self.assertRaises(ValueError):
                publisher.publication(
                    plan, self.report, changed, self.qualifications, self.repository
                )


if __name__ == "__main__":
    unittest.main()
