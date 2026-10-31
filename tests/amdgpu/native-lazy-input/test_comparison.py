#!/usr/bin/env python3
"""Host-only schedule, denominator and point-decision controls."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "lazy_comparison_test", Path(__file__).with_name("comparison.py")
)
comparison = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(comparison)


class Controls(unittest.TestCase):
    def test_unqualified_safe_readiness_failure_with_unknown_is_not_waived(self):
        stdout = """  time: 0.001s  instructions: 5  block syncs: 0  warp syncs: 0
kernel: graph verification
  AMD trace completeness (native AMD graph contract) PASS
  AMD wait and register readiness (target-selected counters and register dependencies) FAIL
  AMD workgroup barrier generations (target-selected AMD barrier objects and phases) PASS
  AMD memory-conflict freedom (AMD completed-effect happens-before) PASS
GRAPH VERIFICATION: UNKNOWN (trace generator aborted)
"""
        diagnostics = comparison.qualification_graph_diagnostics(stdout, "safe")
        self.assertEqual(
            diagnostics["graph_failure_names"], ["AMD wait and register readiness"]
        )
        baseline = {
            "timing_eligible": ["retained"],
            "results": [
                {"case": "retained", "qualified": True},
                {"case": "unqualified-safe", "qualified": False},
            ],
        }
        candidate = {
            "results": [
                {
                    "case": "retained",
                    "qualified": True,
                    "false_positive": False,
                    "unsafe_acceptance": False,
                },
                {
                    "case": "unqualified-safe",
                    "qualified": False,
                    "status": "inconclusive",
                    "measurement_errors": [],
                    "false_positive": False,
                    "unsafe_acceptance": False,
                    **diagnostics,
                },
            ]
        }
        result = comparison.functional(baseline, candidate)
        self.assertFalse(result["passed"])
        self.assertEqual(result["safe_graph_failures"][0]["case"], "unqualified-safe")

    def test_pair_capture_errors_are_retained_without_changing_schedule(self):
        row = {
            "case": {
                "expectation": "safe",
                "expected_outputs": 1,
                "output_indices": {"out": [0]},
                "target": "gfx950",
            },
            "assembly": "/module.s",
            "configuration": "/config.json",
        }
        with tempfile.TemporaryDirectory() as tmp:
            for index, failure in enumerate(
                (
                    ValueError("disk reserve insufficient"),
                    OSError("synthetic launch failure"),
                )
            ):
                with patch.object(comparison.frozen, "execute", side_effect=failure):
                    record = comparison.execute_pair(
                        Path("/volta"),
                        row,
                        Path(tmp) / str(index),
                        None,
                        log_limit=1024,
                    )
                self.assertFalse(record["qualified"])
                self.assertIn("capture_failure", record)
                self.assertIsNone(record["endpoint_seconds"])
                self.assertIsNone(record["returncode"])
                self.assertTrue((Path(tmp) / str(index) / "stdout").exists())

    def test_exact_five_adjacent_counterbalanced_pairs(self):
        ids = [f"case-{i}" for i in range(27)]
        schedule = comparison.frozen.paired_order(ids)
        comparison.schedule_valid(schedule, ids)
        self.assertEqual(len(schedule), 270)
        for cid in ids:
            starts = [
                schedule[i][2]
                for i in range(0, len(schedule), 2)
                if schedule[i][0] == cid
            ]
            self.assertIn(starts.count("baseline"), (2, 3))

    def test_dropped_duplicate_reordered_or_extra_samples_refuse(self):
        ids = ["a", "b"]
        schedule = comparison.frozen.paired_order(ids)
        for changed in [
            schedule[:-1],
            schedule + [schedule[0]],
            schedule[::-1],
            [["extra", 1, "baseline"], *schedule[1:]],
        ]:
            with self.assertRaises(ValueError):
                comparison.schedule_valid(changed, ids)

    def test_candidate_failures_never_change_baseline_denominator(self):
        baseline = {
            "timing_eligible": ["a"],
            "results": [
                {"case": "a", "qualified": True},
                {"case": "b", "qualified": False},
            ],
        }
        candidate = {
            "results": [
                {
                    "case": "a",
                    "qualified": False,
                    "false_positive": False,
                    "unsafe_acceptance": False,
                },
                {
                    "case": "b",
                    "qualified": True,
                    "status": "graph_accepted_without_output_proof",
                    "measurement_errors": [],
                    "false_positive": False,
                    "unsafe_acceptance": False,
                },
            ]
        }
        result = comparison.functional(baseline, candidate)
        self.assertFalse(result["passed"])
        self.assertEqual(result["candidate_cases"], 2)
        self.assertEqual(result["baseline_qualified"], 1)
        self.assertEqual(result["baseline_unqualified_outcomes"][0]["case"], "b")

    def test_false_positive_in_a_baseline_unqualified_case_still_fails(self):
        baseline = {
            "timing_eligible": [],
            "results": [{"case": "b", "qualified": False}],
        }
        candidate = {
            "results": [
                {
                    "case": "b",
                    "qualified": False,
                    "status": "certified_rejection",
                    "measurement_errors": [],
                    "false_positive": True,
                    "unsafe_acceptance": False,
                }
            ]
        }
        self.assertFalse(comparison.functional(baseline, candidate)["passed"])
        self.assertEqual(
            comparison.functional(baseline, candidate)["false_findings"], 1
        )

    def test_summary_includes_first_observation_and_every_failure(self):
        ids = ["p1", "p2", "other"]
        plan = {
            "cases": [
                {"case": {"id": cid}, "definition": {"primary": cid != "other"}}
                for cid in ids
            ]
        }
        prepared = {"eligible": ids, "schedule": comparison.frozen.paired_order(ids)}
        samples = [
            {
                "case": cid,
                "repeat": repeat,
                "role": role,
                "qualified": True,
                "endpoint_seconds": 0.1 if role == "baseline" else 0.075,
                "usage": {"max_rss_kib": 100000 if repeat != 1 else 108000},
            }
            for cid, repeat, role in prepared["schedule"]
        ]
        result = comparison.summarize(plan, prepared, samples)
        self.assertTrue(result["performance_point_gates_pass"])
        self.assertEqual(result["primary_wins"], 2)
        self.assertTrue(
            all(r["candidate_max_rss_kib"] == 108000 for r in result["cases"])
        )
        samples[0]["qualified"] = False
        self.assertFalse(
            comparison.summarize(plan, prepared, samples)[
                "performance_point_gates_pass"
            ]
        )
        with self.assertRaises(ValueError):
            comparison.summarize(plan, prepared, samples[1:])

    def test_other_storage_accounting_excludes_only_gzip_payload(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for folder in ["plan", "baseline", "candidate"]:
                (root / folder).mkdir()
                (root / folder / "log").write_bytes(b"123")
                (root / folder / "outputs.vexpr.gz").write_bytes(b"not-a-real-export")
            prepared = {
                "baseline_plan": str(root / "baseline/plan.json"),
                "baseline_report": str(root / "candidate/report.json"),
            }
            self.assertEqual(
                comparison.other_bytes(prepared, root / "plan/plan.json"), 9
            )

    def test_candidate_qualification_requires_all28(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "qualification.json"
            comparison.write(
                p,
                {
                    "role": "candidate",
                    "plan_sha256": comparison.BASELINE_PLAN_SHA,
                    "build": {"binary_sha256": "x"},
                    "results": [{"case": "only-one"}],
                    "timing_eligible": [],
                },
            )
            with self.assertRaises(ValueError):
                comparison.candidate_report(
                    p,
                    comparison.sha(p),
                    {"cases": [{"case": {"id": "only-one"}}]},
                    {"candidate": {"identity": {"binary_sha256": "x"}}, "eligible": []},
                )


if __name__ == "__main__":
    unittest.main()
