"""Measurement controls: verdicts, scope, timing summaries and launch validity."""
from pathlib import Path
import tempfile
import unittest

import benchmark


class BenchmarkTests(unittest.TestCase):
    def test_launches_have_no_duplicate_options_or_config_flag_conflicts(self):
        for case in benchmark.load_cases()["cases"]:
            with self.subTest(case=case["id"]):
                args = benchmark.command(Path("/verifier"), case, Path("/source.s"), Path("/expressions"))
                options = [value for value in args if value.startswith("--") and value not in ("--array", "--param")]
                self.assertEqual(len(options), len(set(options)))
                if "--config" in options:
                    self.assertFalse({"--kernel", "--block", "--grid", "--array", "--param"} & set(options))

    def test_first_process_is_excluded_and_p95_uses_declared_nearest_rank(self):
        case = {"id": "sample", "family": "memory", "target": "gfx950", "expectation": "hazard", "split": "development"}
        samples = [{"case": "sample", "repeat": i, "seconds": value, "classification": "finding",
                    "time_to_detection_seconds": value / 2, "detected_expected_hazard": True}
                   for i, value in enumerate([100, 1, 2, 3, 4, 5])]
        summary = benchmark.summarize([case], samples)[0]
        self.assertEqual(summary["first_process_seconds"], 100)
        self.assertEqual(summary["repeated_process_median_seconds"], 3)
        self.assertEqual(summary["repeated_process_p95_seconds"], 5)
        self.assertEqual(summary["detection_median_seconds"], 1.5)

    def fake_process(self, output, returncode, expected_property):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            script = directory / "verifier.py"
            script.write_text("import sys\nprint(" + repr(output) + ", flush=True)\nsys.exit(" + str(returncode) + ")\n")
            import sys
            return benchmark.execute([sys.executable, str(script)],
                                     {"expectation": "hazard", "required_property": expected_property}, directory, 5)

    def test_unknown_and_unrelated_findings_never_count_as_expected_detection(self):
        prop = "AMD wait and register readiness"
        for output, code in [("VERDICT: UNKNOWN", 2), ("unsupported AMD instruction", 1),
                             ("  AMD memory-conflict freedom (native) FAIL", 1)]:
            result = self.fake_process(output, code, prop)
            self.assertFalse(result["detected_expected_hazard"])
            self.assertIsNone(result["time_to_detection_seconds"])
        supported = "  AMD trace completeness (native) PASS\n  " + prop + " (native) FAIL\nGRAPH VERIFICATION: REJECTED"
        result = self.fake_process(supported, 1, prop)
        self.assertTrue(result["detected_expected_hazard"])
        self.assertGreater(result["time_to_detection_seconds"], 0)
        result = self.fake_process(supported + "\nexecution stopped: unsupported AMD instruction `foo`", 2, prop)
        self.assertFalse(result["detected_expected_hazard"])

    def test_heldout_mutation_classes_do_not_enter_development(self):
        for case in benchmark.load_cases()["cases"]:
            if case.get("mutation_class") in {"wrong_counter", "tensor_source_lifetime", "tensor_bounds"}:
                self.assertEqual(case["split"], "heldout")


if __name__ == "__main__":
    unittest.main()
