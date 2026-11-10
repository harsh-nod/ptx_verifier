"""Integrity controls for coverage replay and candidate-only observations."""
import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("qualification_replay", Path(__file__).with_name("run.py"))
run = importlib.util.module_from_spec(spec)
spec.loader.exec_module(run)


def observation(**changes):
    return {"seconds": 0.02, "time_to_detection_seconds": 0.01,
            "measurement_errors": [], "timed_out": False,
            "graph_accepted": True, "detected_expected_hazard": True, **changes}


def summary():
    arm = {"first": observation(), "misses_or_invalid": 0, "complete_rounds": True,
           "median_seconds": 0.02, "p95_seconds": 0.03, "peak_rss_kib": 10000}
    return {"id": "case", "expectation": "safe", "baseline_qualified": True,
            "candidate_qualified": True, "output_expressions_equal": True,
            "diagnostics_equal": True, "proof_diagnostics_equal": True,
            "timed_diagnostics_equal": True,
            "baseline": copy.deepcopy(arm), "candidate": copy.deepcopy(arm)}


class ReplayTests(unittest.TestCase):
    def test_selection_preserves_full_outputs_and_ground_truth(self):
        document, _ = run.engine.contracts()
        self.assertEqual(len(document["cases"]), 26)
        copies = [case for case in document["cases"] if case["kernel"] in ("copy", "add")]
        self.assertEqual(len(copies), 8)
        for case in copies:
            self.assertEqual(case["block"], [259, 1, 1])
            self.assertEqual(case["output_indices"]["out"], list(range(259)))
            self.assertTrue(all(array["base_address"] > 1 << 33 for array in case["arrays"]))

    def test_only_clock_values_are_removed_from_proof_diagnostics(self):
        text = "Exec: 0.002s  instructions: 38\nVC check: 0.002s (decision procedure 0.002s)  elements: 65\nVERDICT: ACCEPT"
        changed_clocks = text.replace("0.002s", "12.345s")
        self.assertEqual(run.semantic_text(text), run.semantic_text(changed_clocks))
        for modified in (text.replace("38", "39"), text.replace("65", "64"),
                         text.replace("ACCEPT", "REJECT"), text + "\nUNKNOWN"):
            self.assertNotEqual(run.semantic_text(text), run.semantic_text(modified))

    def test_first_observation_cannot_hide_a_miss_or_bad_measurement(self):
        self.assertTrue(run.coverage_gate([summary()])["accepted"])
        for first in (None, observation(graph_accepted=False), observation(timed_out=True),
                      observation(measurement_errors=["missing resources"]), observation(seconds=float("nan"))):
            row = summary()
            row["candidate"]["first"] = first
            self.assertFalse(run.coverage_gate([row])["accepted"])

    def test_retained_coverage_and_resource_regressions_fail(self):
        for field, value in (("candidate_qualified", False), ("output_expressions_equal", False),
                             ("diagnostics_equal", False), ("proof_diagnostics_equal", False)):
            self.assertFalse(run.coverage_gate([{**summary(), field: value}])["accepted"])
        for field, value in (("median_seconds", 0.024), ("p95_seconds", 0.04),
                             ("peak_rss_kib", 20000), ("complete_rounds", False), ("misses_or_invalid", 1)):
            row = summary()
            row["candidate"][field] = value
            self.assertFalse(run.coverage_gate([row])["accepted"])

    def test_new_qualification_has_no_baseline_latency_ratio(self):
        plan = {"protocol": {"seed": 7, "repeats": 31},
                "cases": [{"case": {"id": "new", "expectation": "hazard"}}]}
        baseline = {"results": {"new": {"qualified": False}}}
        candidate = {"results": {"new": {"qualified": True}}}
        schedule = run.added_schedule(plan, baseline, candidate)
        self.assertEqual(schedule, [{"id": "new", "round": i} for i in range(32)])
        samples = [observation(id="new", round=i) for i in range(32)]
        result = run.added_summaries(plan, samples)[0]
        self.assertTrue(result["all_valid"])
        self.assertIsNone(result["baseline_ratio"])
        self.assertEqual(result["median_seconds"], 0.01)
        self.assertEqual(run.added_schedule(plan, candidate, candidate), [])

    def test_new_case_missing_duplicate_or_failed_first_is_invalid(self):
        plan = {"cases": [{"case": {"id": "new", "expectation": "hazard"}}]}
        samples = [observation(id="new", round=i) for i in range(32)]
        bad_first = [observation(id="new", round=0, detected_expected_hazard=False), *samples[1:]]
        for rows in (samples[1:], [samples[1], *samples[1:]], bad_first):
            self.assertFalse(run.added_summaries(plan, rows)[0]["all_valid"])


if __name__ == "__main__":
    unittest.main()
