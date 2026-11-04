"""Publication refusal and privacy controls; all measurements are synthetic."""

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "public_results", HERE / "publish_results.py"
)
P = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(P)
SHA = "a" * 64


def sample():
    return {
        "status": "ordinary_rejection",
        "detected": True,
        "detection_mode": "complete_trace",
        "graph_accepted": False,
        "returncode": 1,
        "timed_out": False,
        "enabled": False,
        "seconds": 0.01,
        "time_to_detection_seconds": 0.005,
        "usage": {"max_rss_kib": 10000, "user_seconds": 0.001, "system_seconds": 0.001},
        "measurement_errors": [],
        "executed_instructions": 8,
        "prefix_counts": None,
        "false_positive": False,
        "unsafe_acceptance": False,
        "expressions": None,
        "export": None,
        "launch_configuration": None,
        "command": ["/private/host/volta", "/private/host/kernel.s"],
        "stdout_sha256": SHA,
        "stderr_sha256": SHA,
        "resources_sha256": SHA,
        "diagnostics_sha256": SHA,
    }


class PublicationControls(unittest.TestCase):
    def test_ordinary_witness_is_numeric_and_count_is_only_printed_matches(self):
        path = HERE / "fixtures/ordinary-analyze.stdout"
        result = P.typed_witness(path, P.B.sha(path), "complete_trace")
        self.assertEqual(
            result["printed_write_write_witnesses"],
            len(P.B.study.ORDINARY_WITNESS.findall(path.read_text())),
        )
        self.assertGreater(result["printed_write_write_witnesses"], 0)
        self.assertEqual(result["first"]["kind"], "WriteWrite")
        self.assertIn(result["first"]["space"], {"Shared", "Global"})
        self.assertIsInstance(result["first"]["lowest_overlap_byte"], int)
        self.assertNotEqual(
            result["first"]["earlier_event"], result["first"]["later_event"]
        )
        self.assertNotIn("total_conflicts", result)
        with self.assertRaises(ValueError):
            P.typed_witness(path, "b" * 64, "complete_trace")

    def test_prefix_witness_requires_bound_numeric_identity_and_distinct_threads(self):
        text = "  kernel: MemoryConflict { kind: WriteWrite, location: ByteLocation { space: Shared, addr: 2 }, earlier: EventId(10), later: EventId(11) }\n  instruction=EventId(4) issue=EventId(5) wave=0 earlier_thread=ThreadIx(0) later_thread=ThreadIx(1)\n"
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "stdout"
            path.write_text(text)
            result = P.typed_witness(path, P.B.sha(path), "certified_prefix")
            self.assertEqual(result["printed_write_write_witnesses"], 1)
            self.assertEqual(result["first"]["instruction_event"], 4)
            self.assertEqual(result["first"]["issue_event"], 5)
            self.assertEqual(result["first"]["earlier_physical_thread"], 0)
            self.assertEqual(result["first"]["later_physical_thread"], 1)
            for changed in (
                text.splitlines()[0] + "\n",
                text.replace("later_thread=ThreadIx(1)", "later_thread=ThreadIx(0)"),
                text.replace("later: EventId(11)", "later: EventId(10)"),
                text + text,
            ):
                path.write_text(changed)
                with self.assertRaises(ValueError):
                    P.typed_witness(path, P.B.sha(path), "certified_prefix")

    def test_explicit_sample_whitelist_removes_private_strings_and_keeps_failures(self):
        value = sample()
        value.update(
            hostname="private-host",
            device_id="private-device",
            directory="/private/host/run",
            context={"hostname": "private-host"},
        )
        value["measurement_errors"] = ["invalid export /private/host/run/outputs.vexpr"]
        value["usage"]["hostname"] = "private-host"
        value["launch_configuration"] = {
            "path": "/private/host/config.json",
            "sha256": SHA,
            "value": {"hostname": "private-host"},
        }
        output = P.sample(value, {"out": 2})
        encoded = json.dumps(output)
        for private in (
            "private-host",
            "private-device",
            "/private/",
            "directory",
            '"context"',
        ):
            self.assertNotIn(private, encoded)
        self.assertEqual(output["measurement_error_count"], 1)
        self.assertTrue(output["detected"])
        self.assertEqual(output["returncode"], 1)
        self.assertEqual(
            output["command_sha256"], P.B.study.canonical(value["command"])
        )

    def test_censored_and_missing_metric_observations_are_retained(self):
        value = sample()
        value.update(
            status="timeout",
            detected=False,
            detection_mode=None,
            returncode=-9,
            timed_out=True,
            seconds=60.1,
            time_to_detection_seconds=None,
            executed_instructions=None,
            resources_sha256=None,
        )
        value["usage"] = {}
        value["measurement_errors"] = ["missing resource observation"]
        output = P.sample(value, {})
        self.assertEqual(output["status"], "timeout")
        self.assertIsNone(output["peak_rss_kib"])
        self.assertIsNone(output["first_diagnostic_seconds"])
        self.assertEqual(output["measurement_error_count"], 1)
        self.assertEqual(output["seconds"], 60.1)

    def test_nonfinite_negative_boolean_or_missing_numeric_values_refused(self):
        for value in (float("nan"), float("inf"), -1, True, None, "1"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                P.number(value)
        self.assertEqual(P.number(-9, integer=True, negative=True), -9)
        value = sample()
        del value["seconds"]
        with self.assertRaises(KeyError):
            P.sample(value, {})
        for field, replacement in (
            ("seconds", float("nan")),
            ("status", "/private/host"),
            ("stdout_sha256", "not-a-hash"),
        ):
            changed = {**sample(), field: replacement}
            with self.assertRaises(ValueError):
                P.sample(changed, {})

    def test_complete_retention_cannot_hide_shifted_or_missing_coordinates(self):
        counts = {"out": 2}
        observation = {
            "sha256": SHA,
            "bytes": 100,
            "coordinates_sha256": P.B.study.canonical({"out": [0, 1]}),
            "output_counts": counts,
        }
        complete = {
            "validated_complete": True,
            "observation": observation,
            "path": "/private/reference.vexpr",
        }
        self.assertTrue(P.reference(complete, counts)["validated_complete"])
        for field, replacement in (
            ("output_counts", {"out": 1}),
            ("coordinates_sha256", P.B.study.canonical({"out": [1, 2]})),
        ):
            changed = copy.deepcopy(complete)
            changed["observation"][field] = replacement
            with self.assertRaises(ValueError):
                P.reference(changed, counts)
        incomplete = copy.deepcopy(complete)
        incomplete["validated_complete"] = False
        incomplete["observation"]["output_counts"] = {"out": 1}
        self.assertEqual(
            P.reference(incomplete, counts)["observation"]["output_counts"], {"out": 1}
        )
        incomplete["observation"]["output_counts"] = {"private-label": 1}
        with self.assertRaises(ValueError):
            P.reference(incomplete, counts)

    def test_all_first_and31_samples_kept_and_duplicate_or_missing_pairs_refused(self):
        case = {"id": "synthetic-only", "output_indices": {"out": [0, 1]}}
        records = [
            {**sample(), "case": case["id"], "role": role, "repeat": repeat}
            for repeat in range(32)
            for role in ("baseline", "candidate")
        ]
        result = P.paired_samples({"samples": records}, [case])
        for role in ("baseline", "candidate"):
            self.assertEqual(
                [row["repeat"] for row in result[0]["roles"][role]], list(range(32))
            )
        self.assertEqual(sum(len(rows) for rows in result[0]["roles"].values()), 64)
        for changed in (records[:-1], records + [records[0]]):
            with self.assertRaises(ValueError):
                P.paired_samples({"samples": changed}, [case])

    def test_rss_first_sample_and_overhead_failure_are_not_removed(self):
        case = {"id": "synthetic-only", "expectation": "safe", "primary_latency": False}
        records = []
        for role in ("baseline", "candidate"):
            for repeat in range(32):
                value = {
                    **sample(),
                    "case": case["id"],
                    "role": role,
                    "repeat": repeat,
                    "status": "graph_verified",
                    "detected": False,
                    "time_to_detection_seconds": None,
                }
                value["usage"] = {
                    **value["usage"],
                    "max_rss_kib": 20000
                    if role == "candidate" and repeat == 0
                    else 10000,
                }
                records.append(value)
        functional = {
            "correctness_gates_pass": True,
            "new_coverage_families": [],
            "new_complex_coverage_families": [],
        }
        calculated = P.B.timing_summary(
            [case],
            records,
            functional,
            {
                "safe_overhead_limits": {
                    "median_factor": 1.05,
                    "median_add_seconds": 0.001,
                    "p95_factor": 1.1,
                    "p95_add_seconds": 0.001,
                    "rss_fraction": 0.05,
                    "rss_add_kib": 8192,
                }
            },
        )
        public = P.comparison(calculated)
        self.assertEqual(
            public["cases"][0]["metrics"]["candidate"]["max_rss_kib"], 20000
        )
        self.assertFalse(public["cases"][0]["overhead_gates"]["rss"])
        self.assertFalse(public["overhead_gates_pass"])
        self.assertNotIn("first", public["cases"][0]["metrics"]["candidate"])

    def test_missing_duplicate_or_extra_functional_rows_refused(self):
        rows = [{"case": "a"}, {"case": "b"}]
        self.assertEqual(set(P.exact_rows(rows, {"a", "b"})), {"a", "b"})
        for changed in (rows[:1], rows + [rows[0]], rows + [{"case": "c"}]):
            with self.assertRaises(ValueError):
                P.exact_rows(changed, {"a", "b"})

    def test_mixed_build_or_changed_report_chain_refused_before_rendering(self):
        identity = {"caller": "same"}
        reports = {
            "baseline": {},
            "development_preflight": {
                "phase": "paired_functional_preflight",
                "identity": identity,
                "baseline_report_sha256": P.B.BASELINE_SHA,
            },
            "development_paired": {
                "phase": "paired_development_measurement",
                "identity": identity,
                "preflight_sha256": SHA,
            },
            "heldout_qualification": {"identity": identity},
            "heldout_paired": {
                "phase": "paired_heldout_measurement",
                "identity": identity,
                "qualification_sha256": SHA,
            },
        }
        hashes = {
            "baseline": P.B.BASELINE_SHA,
            "development_preflight": SHA,
            "heldout_qualification": SHA,
        }
        changed = copy.deepcopy(reports)
        changed["heldout_paired"]["identity"] = {"caller": "other"}
        with self.assertRaisesRegex(ValueError, "mixed source/build"):
            P.check_links(changed, hashes, {})
        changed = copy.deepcopy(reports)
        changed["development_paired"]["preflight_sha256"] = "b" * 64
        with self.assertRaisesRegex(ValueError, "report chain hash"):
            P.check_links(changed, hashes, {})

    def test_source_pin_absence_or_drift_refused(self):
        relative = "tests/known.py"
        P.pin({"input_sha256": {"/private/source/" + relative: SHA}}, relative, SHA)
        for pins in (
            {},
            {"/private/source/not-known.py": SHA},
            {"/private/source/" + relative: "b" * 64},
        ):
            with self.assertRaises(ValueError):
                P.pin({"input_sha256": pins}, relative, SHA)

    def test_detected_but_telemetry_unqualified_is_not_new_coverage(self):
        rows = [
            {
                "case": "a",
                "expectation": "hazard",
                "baseline": {"status": "ordinary_rejection"},
                "variants": {"baseline": {"status": "ordinary_rejection"}},
            }
        ]
        new = [
            {
                "case": "a",
                "baseline_status": "ordinary_rejection",
                "baseline_ratio": None,
            }
        ]
        for development in (False, True):
            with self.assertRaises(ValueError):
                P.check_new_coverage(rows, new, development=development)
            P.check_new_coverage(rows, [], development=development)
        rows[0]["baseline"]["status"] = "unsupported"
        new[0]["baseline_status"] = "unsupported"
        P.check_new_coverage(rows, new, development=True)
        new[0]["baseline_ratio"] = 0.0
        with self.assertRaises(ValueError):
            P.check_new_coverage(rows, new, development=True)

    def test_failed_gemm_primary_and_candidate_failed_qualifier_have_no_ratio(self):
        cases = [
            {"id": value, "primary_latency": True}
            for value in sorted(P.B.study.PRIMARIES)
        ]
        rows = [
            {
                "case": case["id"],
                "baseline_timing_eligible": "gemm" not in case["id"],
                "baseline": {
                    "status": "timeout"
                    if "gemm" in case["id"]
                    else "ordinary_rejection"
                },
                "variants": {"candidate": {"status": "certified_rejection"}},
            }
            for case in cases
        ]
        comparisons = {
            "cases": [
                {"case": case["id"], "median_ratio_interval": None}
                for case in cases
                if "gemm" not in case["id"]
            ]
        }
        result = P.primary_outcomes(cases, rows, comparisons)
        self.assertEqual(len(result), 4)
        gemm = next(row for row in result if "gemm" in row["id"])
        self.assertEqual(gemm["baseline_status"], "timeout")
        self.assertFalse(gemm["baseline_timing_eligible"])
        self.assertFalse(gemm["has_baseline_ratio"])
        self.assertTrue(all(not row["has_baseline_ratio"] for row in result))
        with self.assertRaises(ValueError):
            P.primary_outcomes(cases[:-1], rows, comparisons)

    def test_build_whitelist_keeps_attestation_limits_and_refuses_wrong_profile(self):
        receipt = json.loads((HERE / "results/baseline-20261031.json").read_text())
        value = copy.deepcopy(receipt["build_identity"])
        value["hostname"] = "private-host"
        value["build_directory"] = "/private/build"
        result = P.build(value)
        self.assertNotIn("private", json.dumps(result))
        self.assertEqual(result["trust"], "caller_attested")
        value["profile"] = "debug"
        with self.assertRaises(ValueError):
            P.build(value)

    def test_output_alias_existing_file_and_input_drift_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = directory / "input.json"
            source.write_text("original")
            frozen = P.B.snapshots([source])
            for destination in (source, directory / "alias.json"):
                if destination != source:
                    destination.symlink_to(source)
                with self.assertRaises(ValueError):
                    P.write_fresh(destination, {}, frozen)
            source.write_text("drift")
            target = directory / "public.json"
            with self.assertRaises(ValueError):
                P.write_fresh(target, {}, frozen)
            self.assertFalse(target.exists())

    def test_full_precision_and_fresh_output_retained_without_collection(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "public.json"
            value = {
                "seconds": 0.012345678901234567,
                "failed_gate": False,
                "outcome": "timeout",
            }
            P.write_fresh(path, value, {})
            self.assertEqual(json.loads(path.read_text()), value)
            with self.assertRaises(ValueError):
                P.write_fresh(path, value, {})


if __name__ == "__main__":
    unittest.main()
