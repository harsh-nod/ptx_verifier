"""Refusal and audit controls for the independently frozen trace-cost study."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location("trace_cost_study", Path(__file__).with_name("study.py"))
study = importlib.util.module_from_spec(spec)
spec.loader.exec_module(study)

PASS = """  AMD trace completeness (native) PASS
  AMD wait and register readiness (native) PASS
  AMD memory-conflict freedom (native) PASS
  AMD workgroup barrier generations (native) PASS
GRAPH VERIFICATION: VERIFIED
"""


class StudyTests(unittest.TestCase):
    def retained(self, directory, *, graph=True):
        directory.mkdir(parents=True)
        item = {"assembly": "/assembly.s", "case": {"id": "safe", "kernel": "copy", "target": "gfx942", "backend": "amdgpu",
                "expectation": "safe", "block": [1, 1, 1], "grid": [1, 1, 1], "workgroup": [0, 0, 0],
                "arrays": [], "params": [], "dimensions": {}, "output_indices": {}, "expected_outputs": 0}}
        (directory / "stdout").write_text(PASS)
        (directory / "stderr").write_text("Wrote event graph to " + str(directory / "graph.txt") + "\n")
        (directory / "resources.txt").write_text("max_rss_kib=1024\nuser_seconds=0.01\nsystem_seconds=0.00\n")
        (directory / "graph.txt").write_text("volta-graph 1\nterminal completed\n")
        args = study.command("/volta", item, directory, graph=graph)
        raw = {"command": args, "seconds": 0.02, "returncode": 0, "timed_out": False,
               "early_readiness_enabled": False, "launch_contract": study.legacy.study.launch_contract(args, item["case"]),
               "time_to_detection_seconds": None, "detected_property": None}
        study.write(directory / "observer.json", raw)
        row = study.derive(raw, item, directory, graph=graph)
        row["observer_sha256"] = study.sha(directory / "observer.json")
        return item, row

    def test_population_and_mutations_remain_bound_to_original_sources(self):
        document, protocol = study.contracts()
        self.assertEqual(len(document["cases"]), 26)
        with tempfile.TemporaryDirectory() as temporary:
            manifest = Path(temporary) / "cases.json"
            mutant = next(c for c in document["cases"] if c["expectation"] == "hazard")
            mutant["block"][0] += 1
            study.write(manifest, document)
            with mock.patch.object(study, "MANIFEST", manifest):
                with self.assertRaisesRegex(ValueError, "complete contract"):
                    study.contracts()

    def test_artifact_destinations_are_normalized_in_both_streams(self):
        with tempfile.TemporaryDirectory() as temporary:
            _, left = self.retained(Path(temporary) / "baseline")
            _, right = self.retained(Path(temporary) / "candidate")
            self.assertEqual(left["diagnostics_sha256"], right["diagnostics_sha256"])

    def test_audit_rejects_changed_classification_resource_errors_and_observer_time(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary) / "run"
            item, row = self.retained(directory)
            study.audit_observation(row, "/volta", item, directory, graph=True)
            for key, value in (("classification", "finding"), ("seconds", 0.001), ("measurement_errors", ["forged"]),
                               ("diagnostics_sha256", "0" * 64), ("proof_counts", ["999"])):
                altered = {**row, key: value}
                with self.subTest(key=key), self.assertRaisesRegex(ValueError, "differs from artifacts"):
                    study.audit_observation(altered, "/volta", item, directory, graph=True)
            (directory / "resources.txt").write_text("max_rss_kib=1024\nmax_rss_kib=1024\nuser_seconds=0.01\nsystem_seconds=0.00\n")
            altered = {**row, "resources_sha256": study.sha(directory / "resources.txt")}
            with self.assertRaisesRegex(ValueError, "measurement_errors"):
                study.audit_observation(altered, "/volta", item, directory, graph=True)

    def test_incomplete_trace_and_wrong_typed_witness_do_not_qualify(self):
        case = {"expectation": "hazard"}
        row = {"measurement_errors": [], "graph_completed": True, "detected_expected_hazard": True,
               "witnesses": "AmdRegisterHazard { kind: ReadBeforeReady }"}
        self.assertTrue(study.qualifies(case, row))
        for key, value in (("graph_completed", False), ("measurement_errors", ["missing"]),
                           ("witnesses", "AmdRegisterHazard { kind: WriteBeforeReady }")):
            self.assertFalse(study.qualifies(case, {**row, key: value}))

    def test_role_and_build_identity_are_reconstructed(self):
        plan = {"protocol": {}, "cases": []}
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "report.json"
            build = {"binary": "/volta", "declaration": "/build.json", "revision": "forged"}
            study.write(path, {"complete": True, "plan_sha256": "pin", "build": build, "role": "baseline", "results": {}})
            with mock.patch.object(study, "identity", return_value={**build, "revision": "real"}):
                with self.assertRaisesRegex(ValueError, "identity changed"):
                    study.qualification(path, plan, "pin")

    def test_adoption_rejects_diagnostic_loss_even_with_faster_detection(self):
        arm = {"misses_or_invalid": 0, "complete_rounds": True, "peak_rss_kib": 1024}
        row = {"id": "hazard", "expectation": "hazard", "baseline_qualified": True, "candidate_qualified": True,
               "baseline": arm, "candidate": arm, "graph_dumps_equal": True, "diagnostics_equal": True,
               "proof_diagnostics_equal": True, "timed_diagnostics_equal": True, "paired_ratio_interval_95": [0.7, 0.9]}
        self.assertTrue(study.adoption([row])["accepted"])
        for key in ("diagnostics_equal", "graph_dumps_equal", "candidate_qualified"):
            self.assertFalse(study.adoption([{**row, key: False}])["accepted"])
        self.assertFalse(study.adoption([{**row, "candidate": {**arm, "misses_or_invalid": 1}}])["accepted"])

    def test_randomized_pairs_are_reproducible_and_keep_first_round_separate(self):
        items = [{"case": {"id": c}} for c in ("a", "b", "c")]
        protocol = {"seed": 20261110, "repeats": 31}
        left = study.schedule(items, protocol)
        self.assertEqual(left, study.schedule(items, protocol))
        self.assertEqual(len(left), 96)
        for index in range(32):
            self.assertEqual({p["id"] for p in left if p["round"] == index}, {"a", "b", "c"})
        self.assertEqual(study.paired_interval([(1, 0.5)] * 31, 1), [0.5, 0.5])

    def test_each_pair_owns_distinct_artifact_directories(self):
        path = Path("/retained/report.json")
        directories = [study.sample_directory(path, index, arm)
                       for index, arm in enumerate(["candidate", "baseline", "baseline", "candidate"])]
        self.assertEqual(len(set(directories)), 4)
        self.assertEqual(directories[2], Path("/retained/0001-baseline"))


if __name__ == "__main__":
    unittest.main()
