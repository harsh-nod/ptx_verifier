"""Static heldout contracts and collection guards; never run a heldout kernel."""

import copy
import importlib.util
import math
from pathlib import Path
import struct
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "heldout_measurement", HERE / "heldout.py"
)
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)


class HeldoutControls(unittest.TestCase):
    def setUp(self):
        self.document = H.B.study.load_cases()
        self.cases = H.heldouts(self.document)
        self.revision = "a" * 40
        self.identity = {
            "sources": {"candidate_revision": self.revision},
            "builds": {"candidate": {"revision": self.revision}},
        }

    def rows(self):
        rows = []
        for case in self.cases:
            safe = case["expectation"] == "safe"
            sample = {
                "status": "graph_verified" if safe else "ordinary_rejection",
                "detected": not safe,
                "false_positive": False,
                "unsafe_acceptance": False,
                "measurement_errors": [],
                "timed_out": False,
                "expressions": {"sha256": "same actual expression bytes"},
                "time_to_detection_seconds": None if safe else 0.01,
            }
            rows.append(
                {
                    "case": case["id"],
                    "family": next(
                        w["family"]
                        for w in self.document["workloads"]
                        if w["id"] == case["workload"]
                    ),
                    "expectation": case["expectation"],
                    "category": case["category"],
                    "assembly_sha256": case["materialized_assembly_sha256"],
                    "assemble": {"returncode": 0, "timed_out": False},
                    "baseline_timing_eligible": True,
                    "default_off_invariance": {"passed": True},
                    "variants": {role: copy.deepcopy(sample) for role in H.B.ROLES},
                    "specifications": {
                        role: {
                            "status": "spec_verified",
                            "measurement_errors": [],
                            "timed_out": False,
                        }
                        for role in H.B.ROLES
                    }
                    if safe
                    else {},
                }
            )
        return rows

    def test_exact_six_three_safe_and_matched_original_contracts(self):
        self.assertEqual(len(self.cases), 6)
        self.assertEqual({case["id"] for case in self.cases}, H.B.study.HELDOUTS)
        self.assertEqual(sum(case["expectation"] == "safe" for case in self.cases), 3)
        for case in self.cases:
            self.assertEqual(
                case["expected_outputs"], sum(map(len, case["output_indices"].values()))
            )
            self.assertEqual(case["split"], "heldout")
        relocated = next(
            case
            for case in self.cases
            if case["id"] == "memory-gfx950-transpose-heldout-safe"
        )
        self.assertEqual(
            {a["name"]: a["base_address"] for a in relocated["arrays"]},
            {"x": 196608, "out": 327680},
        )
        for mutation in (
            lambda d: d["cases"].pop(),
            lambda d: d["cases"].append(copy.deepcopy(d["cases"][-1])),
        ):
            document = copy.deepcopy(self.document)
            mutation(document)
            with self.assertRaises(ValueError):
                H.heldouts(document)

    def test_requires_full_exact_frozen_source_and_build_revision(self):
        H.validate_freeze(self.revision, self.identity)
        for value in ("HEAD", "a" * 7, "b" * 40, self.revision.upper()):
            with self.assertRaises(ValueError):
                H.validate_freeze(value, self.identity)
        identity = copy.deepcopy(self.identity)
        identity["builds"]["candidate"]["revision"] = "b" * 40
        with self.assertRaises(ValueError):
            H.validate_freeze(self.revision, identity)

    def test_finite_overlap_valuations_compare_actual_intersecting_bytes(self):
        transpose = next(
            case
            for case in self.cases
            if case["id"] == "memory-gfx950-transpose-heldout-partial-overlap"
        )
        lane0 = struct.pack("<HH", 0, 1)
        lane1 = struct.pack("<HH", 2, 3)
        self.assertEqual(
            [lane0[2:4].hex(), lane1[0:2].hex()],
            transpose["ground_truth"]["distinct_overlap_bytes_hex"],
        )
        self.assertNotEqual(lane0[2:4], lane1[0:2])
        silu0 = struct.pack("<e", 0.0)
        silu1 = struct.pack("<e", 1 / (1 + math.exp(-1)))
        self.assertNotEqual(silu0 * 4, silu1 * 4)
        denominator = 248 + 8 * math.e
        low, high = (
            struct.pack("<e", 1 / denominator),
            struct.pack("<e", math.e / denominator),
        )
        self.assertNotEqual(low * 8, high * 8)
        self.assertEqual(len(low * 8), 16)
        # These are source-derived possibility witnesses, not executed results.

    def test_baseline_only_qualification_and_candidate_failure_retention(self):
        rows = self.rows()
        case = next(case for case in self.cases if case["expectation"] == "hazard")
        row = next(row for row in rows if row["case"] == case["id"])
        self.assertTrue(H.baseline_eligible(case, row["variants"]["baseline"], None))
        row["variants"]["candidate"].update(status="inconclusive", detected=False)
        result = H.summary(rows)
        self.assertEqual(len(result["baseline_timing_eligible"]), 6)
        self.assertFalse(result["baseline_qualifications_retained"])
        self.assertFalse(result["correctness_gates_pass"])
        row["variants"]["baseline"].update(status="inconclusive", detected=False)
        row["baseline_timing_eligible"] = H.baseline_eligible(
            case, row["variants"]["baseline"], None
        )
        row["variants"]["candidate"].update(status="certified_rejection", detected=True)
        result = H.summary(rows)
        self.assertEqual(len(result["baseline_timing_eligible"]), 5)
        self.assertEqual(result["new_coverage"][0]["baseline_ratio"], None)
        self.assertFalse(result["development_family_adoption_gate_evaluated"])

    def test_safe_full_proof_required_and_unknown_remains_a_miss(self):
        rows = self.rows()
        case = next(case for case in self.cases if case["expectation"] == "safe")
        row = next(row for row in rows if row["case"] == case["id"])
        self.assertTrue(
            H.baseline_eligible(
                case, row["variants"]["baseline"], row["specifications"]["baseline"]
            )
        )
        self.assertFalse(
            H.baseline_eligible(
                case, row["variants"]["baseline"], {"status": "timeout"}
            )
        )
        row["specifications"]["candidate"] = {
            "status": "inconclusive",
            "measurement_errors": [],
            "timed_out": False,
        }
        self.assertFalse(H.summary(rows)["correctness_gates_pass"])
        rows = self.rows()
        for row in rows:
            if row["expectation"] == "hazard":
                row["baseline_timing_eligible"] = False
                for sample in row["variants"].values():
                    sample.update(status="inconclusive", detected=False)
        result = H.summary(rows)
        self.assertEqual(result["counts"]["candidate"]["hazards_detected"], 0)
        self.assertEqual(result["hazard_denominator"], 3)
        self.assertEqual(result["new_coverage"], [])

    def test_existing_finding_with_invalid_telemetry_is_not_new_coverage(self):
        rows = self.rows()
        row = next(row for row in rows if row["expectation"] == "hazard")
        case = next(case for case in self.cases if case["id"] == row["case"])
        row["variants"]["baseline"]["measurement_errors"] = ["missing RSS"]
        row["baseline_timing_eligible"] = H.baseline_eligible(
            case, row["variants"]["baseline"], None
        )
        row["variants"]["candidate"].update(status="certified_rejection", detected=True)
        result = H.summary(rows)
        self.assertFalse(row["baseline_timing_eligible"])
        self.assertEqual(result["counts"]["baseline"]["hazards_detected"], 3)
        self.assertEqual(result["new_coverage"], [])
        self.assertEqual(result["new_coverage_families"], [])
        self.assertFalse(result["correctness_gates_pass"])
        for status in ("inconclusive", "unsupported", "timeout"):
            row["variants"]["baseline"].update(status=status, detected=False)
            result = H.summary(rows)
            self.assertEqual(len(result["new_coverage"]), 1)
            self.assertEqual(result["new_coverage"][0]["baseline_status"], status)

    def test_checked_qualification_cannot_drop_rows_or_change_baseline_eligibility(
        self,
    ):
        report = {
            "phase": "heldout_functional_qualification",
            "frozen_mechanism": self.revision,
            "identity": self.identity,
            "results": self.rows(),
        }
        report["functional"] = H.summary(report["results"])
        H.validate_qualification(report, self.document, self.identity, self.revision)
        for mutate in (
            lambda r: r["results"].pop(),
            lambda r: r["results"].append(copy.deepcopy(r["results"][0])),
            lambda r: r["results"][0].update(baseline_timing_eligible=False),
            lambda r: r["functional"].update(correctness_gates_pass=False),
        ):
            changed = copy.deepcopy(report)
            mutate(changed)
            with self.assertRaises(ValueError):
                H.validate_qualification(
                    changed, self.document, self.identity, self.revision
                )


if __name__ == "__main__":
    unittest.main()
