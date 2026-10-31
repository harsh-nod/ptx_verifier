"""Measurement controls: verdicts, scope, timing summaries and launch validity."""
from pathlib import Path
import copy
import sys
import tempfile
import unittest

import benchmark


class BenchmarkTests(unittest.TestCase):
    def run_fake(self, case, stdout, code, *, stderr="", expressions=None, stale=False, delay=0, timeout=5):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            output = directory / "outputs.vexpr"
            if stale:
                output.write_text('volta-expr 1\nn0 = int 7\nout "out" 0 n0\n')
            body = "import sys,time\nfrom pathlib import Path\n"
            if expressions is not None:
                body += "Path(" + repr(str(output)) + ").write_text(" + repr(expressions) + ")\n"
            body += "print(" + repr(stdout) + ", flush=True)\n"
            body += "print(" + repr(stderr) + ", file=sys.stderr, flush=True)\n"
            body += "time.sleep(" + repr(delay) + ")\nsys.exit(" + repr(code) + ")\n"
            script = directory / "verifier.py"
            script.write_text(body)
            return benchmark.execute([sys.executable, str(script)], case, directory, timeout)

    def test_source_ground_truth_and_mutation_pins_cannot_be_deleted_or_changed(self):
        original = benchmark.load_cases()
        row = next(i for i, case in enumerate(original["cases"]) if case.get("expectation_function"))
        for field, value in [("expectation_source_sha256", "0" * 64), ("expectation_function", "missing_function"),
                             ("expectation_anchor", "assertion_that_does_not_exist"), ("assembly_sha256", "0" * 64)]:
            changed = copy.deepcopy(original)
            changed["cases"][row][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                benchmark.validate_cases(changed)
        for field in ("expectation_function", "expectation_source_sha256", "expectation_anchor"):
            changed = copy.deepcopy(original)
            del changed["cases"][row][field]
            with self.subTest(deleted=field), self.assertRaises(ValueError):
                benchmark.validate_cases(changed)

    def test_original_shapes_and_complete_coordinates_are_not_replaceable_by_smaller_contracts(self):
        original = benchmark.load_cases()
        for field in ("dimensions", "expected_outputs", "output_projection", "arrays"):
            changed = copy.deepcopy(original)
            case = next(case for case in changed["cases"] if case.get("baseline_id"))
            case[field] = {} if field == "dimensions" else 0 if field == "expected_outputs" else []
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "original workload contract"):
                benchmark.validate_cases(changed)
        changed = copy.deepcopy(original)
        case = changed["cases"][0]
        case["output_indices"]["out"] = [i + 1 for i in case["output_indices"]["out"]]
        with self.assertRaisesRegex(ValueError, "output contract"):
            benchmark.validate_cases(changed)

    def test_reserved_safe_or_hazard_holdouts_cannot_move_into_development(self):
        original = benchmark.load_cases()
        for expected in ("safe", "hazard"):
            changed = copy.deepcopy(original)
            case = next(case for case in changed["cases"] if case["split"] == "heldout" and case["expectation"] == expected)
            case["split"] = "development"
            with self.assertRaisesRegex(ValueError, "heldout"):
                benchmark.validate_cases(changed)

    def test_launches_have_no_duplicate_options_or_config_flag_conflicts(self):
        for case in benchmark.load_cases()["cases"]:
            with self.subTest(case=case["id"]):
                args = benchmark.command(Path("/verifier"), case, Path("/source.s"), Path("/expressions"))
                options = [value for value in args if value.startswith("--") and value not in ("--array", "--param")]
                self.assertEqual(len(options), len(set(options)))
                if "--config" in options:
                    self.assertFalse({"--kernel", "--block", "--grid", "--array", "--param"} & set(options))
                enabled = benchmark.command(Path("/verifier"), case, Path("/source.s"), Path("/expressions"), early_readiness=True)
                expected = case.get("backend", "amdgpu") == "amdgpu" and case["target"] == "gfx1250"
                self.assertEqual("--early-readiness" in enabled, expected)

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

    def test_certified_prefix_requires_exact_marker_verdict_property_and_process_status(self):
        prop = benchmark.READINESS_PROPERTY
        case = {"expectation": "hazard", "required_property": prop, "target": "gfx1250"}
        certified = benchmark.EARLY_MARKER + "\n  " + prop + " (certified prefix) FAIL\nVERDICT: REJECT"
        result = self.run_fake(case, certified, 1)
        self.assertTrue(result["detected_expected_hazard"])
        self.assertEqual(result["detection_mode"], "certified_prefix")
        invalid = [(certified, 2), (certified.replace(benchmark.EARLY_MARKER + "\n", ""), 1),
                   (certified.replace("FAIL", "UNKNOWN"), 1), (certified.replace("REJECT", "UNKNOWN"), 1),
                   (certified + "\nunsupported AMD instruction", 1),
                   (certified + "\ncertificate invalid", 1), (certified + "\n" + benchmark.EARLY_MARKER, 1)]
        for stdout, code in invalid:
            with self.subTest(stdout=stdout, code=code):
                self.assertFalse(self.run_fake(case, stdout, code)["detected_expected_hazard"])

    def test_generic_stopped_prefix_and_stderr_failure_are_never_certified_detections(self):
        prop = benchmark.READINESS_PROPERTY
        case = {"expectation": "hazard", "required_property": prop, "target": "gfx1250"}
        partial = "  AMD trace completeness (native) PASS\n  " + prop + " (native) FAIL\nGRAPH VERIFICATION: UNKNOWN"
        self.assertFalse(self.run_fake(case, partial, 2)["detected_expected_hazard"])
        self.assertFalse(self.run_fake(case, partial.replace("UNKNOWN", "REJECTED"), 2)["detected_expected_hazard"])
        self.assertFalse(self.run_fake(case, "VERDICT: REJECT", 1, stderr="  " + prop + " (native) FAIL")["detected_expected_hazard"])

    def test_invalid_access_is_separate_and_needs_its_exact_source_justified_diagnostic(self):
        case = {"expectation": "hazard", "required_property": "AMD trace completeness", "target": "gfx1250",
                "diagnostic_family": "invalid_access", "required_diagnostic": "tensor footprint exceeds LDS capacity"}
        text = "  AMD trace completeness (native) FAIL\nGRAPH VERIFICATION: REJECTED\nexecution stopped: tensor footprint exceeds LDS capacity"
        result = self.run_fake(case, text, 1)
        self.assertTrue(result["detected_expected_hazard"])
        self.assertEqual(result["detection_mode"], "typed_invalid_access")
        self.assertFalse(self.run_fake(case, text.replace(case["required_diagnostic"], "uninitialized register"), 1)["detected_expected_hazard"])

    def test_stale_missing_shifted_or_contradictory_safe_outputs_never_verify(self):
        case = {"expectation": "safe", "output_indices": {"out": [0]}}
        text = "  output 'out': 1 element(s) written\n  AMD trace completeness (native) PASS\nGRAPH VERIFICATION: VERIFIED"
        self.assertNotEqual(self.run_fake(case, text, 0, stale=True)["classification"], "verified")
        for expression in ['volta-expr 1\nn0 = int 7\nout "out" 1 n0\n',
                           'volta-expr 1\nn0 = int 7\nout "out" 0 n0\nout "out" 0 n0\n']:
            self.assertNotEqual(self.run_fake(case, text, 0, expressions=expression)["classification"], "verified")
        expression = 'volta-expr 1\nn0 = int 7\nout "out" 0 n0\n'
        result = self.run_fake(case, text, 0, expressions=expression)
        self.assertEqual(result["classification"], "verified")
        self.assertGreater(result["peak_rss_kib"], 0)
        self.assertNotEqual(self.run_fake(case, text, 0, expressions=expression, stderr="unsupported AMD instruction")["classification"], "verified")

    def test_timeout_never_becomes_a_detection_even_after_a_property_failure(self):
        prop = benchmark.READINESS_PROPERTY
        case = {"expectation": "hazard", "required_property": prop}
        result = self.run_fake(case, "  " + prop + " (native) FAIL", 1, delay=1, timeout=0.05)
        self.assertTrue(result["timed_out"])
        self.assertEqual(result["classification"], "timeout")
        self.assertFalse(result["detected_expected_hazard"])
        self.assertIsNone(result["time_to_detection_seconds"])

    def test_paired_bootstrap_does_not_invent_variability_for_constant_ratios(self):
        interval = benchmark.paired_ratio_interval([(1, 2), (1, 2), (1, 2)], resamples=100)
        self.assertEqual((interval["lower"], interval["upper"]), (2, 2))

    def sample(self, case, variant, repeat, *, detected=False, classification="verified", seconds=0.002, errors=None):
        return {"case": case["id"], "variant": variant, "repeat": repeat, "seconds": seconds,
                "classification": classification, "time_to_detection_seconds": seconds / 2 if detected else None,
                "detected_expected_hazard": detected, "false_positive": case["expectation"] == "safe" and classification == "finding",
                "false_acceptance": case["expectation"] == "hazard" and classification == "verified", "timed_out": False,
                "failed_properties": [benchmark.READINESS_PROPERTY] if detected else [],
                "measurement_errors": errors or [], "peak_rss_kib": 1000}

    def test_paired_summary_cannot_hide_coverage_loss_or_missing_resources_as_speed(self):
        case = {"id": "safe", "expectation": "safe", "split": "development", "target": "gfx950", "family": "copy"}
        for classification, errors in [("unsupported", []), ("verified", ["missing RSS"])]:
            samples = [self.sample(case, name, repeat, classification=classification if name == "candidate" else "verified",
                                   seconds=0.0001 if name == "candidate" else 0.01, errors=errors if name == "candidate" else [])
                       for name in ["baseline", "candidate"] for repeat in range(3)]
            off = [self.sample(case, "candidate-off", 0)]
            report = benchmark.comparison_summary([case], samples, "baseline", "candidate", off)
            self.assertFalse(report["correctness_and_overhead_gates_pass"])
            self.assertFalse(report["adoption_gates_pass"])
            self.assertFalse(report["cases"][0]["common_supported"])

    def test_paired_detection_misses_keep_their_denominator(self):
        case = {"id": "hazard", "expectation": "hazard", "split": "development", "target": "gfx1250", "family": "copy"}
        samples = [self.sample(case, name, repeat, classification="finding", detected=name == "baseline" or repeat == 0)
                   for name in ["baseline", "candidate"] for repeat in range(3)]
        report = benchmark.comparison_summary([case], samples, "baseline", "candidate", [self.sample(case, "candidate-off", 0, classification="finding", detected=True)])
        row = report["cases"][0]
        self.assertEqual(row["candidate"]["missed_expected_hazards"], 2)
        self.assertEqual(row["candidate"]["measured_repeats"], 2)
        self.assertFalse(row["safety_counts_retained"])
        self.assertIsNone(row["detection_median_ratio_interval"])


if __name__ == "__main__":
    unittest.main()
