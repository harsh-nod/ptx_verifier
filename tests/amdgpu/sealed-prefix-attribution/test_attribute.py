"""Synthetic host controls; no verifier, profiling or real clock observations."""

import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "attribution", Path(__file__).with_name("attribute.py")
)
a = importlib.util.module_from_spec(spec)
spec.loader.exec_module(a)


def phases(final=1_000_000):
    values = {p: {"exclusive_ns": 0, "calls": 0} for p in a.PHASES}
    values["remaining_execution_output"] = {"exclusive_ns": 2_000_000, "calls": 1}
    values["discovery"] = {"exclusive_ns": 100_000, "calls": 4}
    values["live_prefix_validation"] = {"exclusive_ns": 2_000_000, "calls": 1}
    values["final_prefix_validation"] = {"exclusive_ns": final, "calls": 1}
    values["final_ordinary_graph"] = {"exclusive_ns": 500_000, "calls": 1}
    return {
        "schema_version": 1,
        "valid": True,
        "root_ns": sum(v["exclusive_ns"] for v in values.values()),
        "phases": values,
    }


def samples():
    selected = a.selection()
    values = []
    for case in sum(
        [selected[k] for k in ["late_hazards", "early_primaries", "safe_controls"]], []
    ):
        for repeat in range(1, 6):
            values.append(
                {
                    "case": case,
                    "repeat": repeat,
                    "attribution_errors": [],
                    "phases": phases(),
                    "parent_prediagnostic_wall_ns": 6_000_000,
                }
            )
    return values


class Controls(unittest.TestCase):
    def test_fixed26_and130_observations(self):
        self.assertEqual(len(samples()), 130)
        self.assertEqual(len(a.selection()["gate_cases"]), 5)

    def test_valid_exclusive_accounting(self):
        a.validate_phases(phases(), 6_000_000, True)

    def test_double_count_is_refused(self):
        value = phases()
        value["root_ns"] += 1
        with self.assertRaisesRegex(ValueError, "double-count"):
            a.validate_phases(value, 6_000_000, True)

    def test_parent_endpoint_cannot_be_smaller_than_pipeline(self):
        with self.assertRaisesRegex(ValueError, "exceeds"):
            a.validate_phases(phases(), 1, True)

    def test_final_replay_is_absent_on_safe_controls(self):
        with self.assertRaisesRegex(ValueError, "replay count"):
            a.validate_phases(phases(), 6_000_000, False)

    def test_bad_measurement_is_not_zero_cost(self):
        value = phases()
        value["valid"] = False
        with self.assertRaises(ValueError):
            a.validate_phases(value, 6_000_000, True)

    def test_gate_passes_only_fixed_quorum(self):
        self.assertEqual(
            a.summarize(samples(), a.selection())["qualifying_gate_cases"], 5
        )
        self.assertTrue(a.summarize(samples(), a.selection())["gate_pass"])

    def test_time_threshold_is_separate_from_share(self):
        values = samples()
        for s in values:
            s["phases"]["phases"]["final_prefix_validation"]["exclusive_ns"] = 999_999
        self.assertFalse(a.summarize(values, a.selection())["gate_pass"])

    def test_share_threshold_is_separate_from_time(self):
        values = samples()
        for s in values:
            s["parent_prediagnostic_wall_ns"] = 10_000_000
        self.assertFalse(a.summarize(values, a.selection())["gate_pass"])

    def test_missing_repeat_is_not_filtered(self):
        self.assertFalse(a.summarize(samples()[1:], a.selection())["gate_pass"])

    def test_duplicate_repeat_is_not_a_complete_case(self):
        values = samples()
        values[0]["repeat"] = 2
        self.assertFalse(a.summarize(values, a.selection())["gate_pass"])

    def test_one_outlier_does_not_turn_median_into_mean(self):
        values = samples()
        for s in values:
            if s["repeat"] == 1:
                s["phases"]["phases"]["final_prefix_validation"]["exclusive_ns"] = 0
        self.assertTrue(a.summarize(values, a.selection())["gate_pass"])

    def test_any_functional_change_remains_failure(self):
        values = samples()
        values[-1]["attribution_errors"] = ["changed witness"]
        self.assertFalse(a.summarize(values, a.selection())["gate_pass"])

    def test_missing_or_invalid_metrics_are_retained_and_fail_the_gate(self):
        for metrics in [{}, {"root_ns": "bad"}, [], None]:
            with self.subTest(metrics=metrics):
                values = samples()
                observation = a.phase_observation(metrics, 6_000_000, True)
                self.assertIs(observation["phases"], metrics)
                self.assertIsNone(observation["unassigned_parent_remainder_ns"])
                self.assertTrue(observation["attribution_errors"])
                values[0].update(observation)
                summary = a.summarize(values, a.selection())
                self.assertEqual(len(values), 130)
                self.assertFalse(summary["all130_samples_valid"])
                self.assertFalse(summary["gate_pass"])


if __name__ == "__main__":
    unittest.main()
