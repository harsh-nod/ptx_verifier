"""Host-only paired-driver refusal controls; no verifier, assembler or GPU."""

import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("memory_pairs", HERE / "benchmark.py")
B = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(B)


def ordinary():
    return (HERE / "fixtures/ordinary-analyze.stdout").read_text()


def certified():
    return (
        B.study.MARKER + "\n"
        "  AMD memory-conflict freedom (certified prefix) FAIL\n"
        "  kernel: MemoryConflict { kind: WriteWrite, location: ByteLocation { space: Shared, addr: 0 }, earlier: EventId(1), later: EventId(2) }\n"
        "  prefix: instructions=4 amd_records=8 graph_events=32\n"
        "VERDICT: REJECT\n"
    )


def sample(*, safe=False, good=True):
    return {
        "status": "graph_verified"
        if safe
        else "ordinary_rejection"
        if good
        else "inconclusive",
        "detected": not safe and good,
        "time_to_detection_seconds": 0.005 if not safe and good else None,
        "seconds": 0.01,
        "usage": {"max_rss_kib": 10000, "user_seconds": 0, "system_seconds": 0},
        "measurement_errors": [],
        "timed_out": False,
        "diagnostics_sha256": "unchanged",
        "executed_instructions": 8,
        "expressions": None,
    }


class DriverControls(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.document = B.study.load_cases()
        self.case = next(
            c for c in B.development(self.document) if c["expectation"] == "hazard"
        )
        self.safe = next(
            c for c in B.development(self.document) if c["expectation"] == "safe"
        )

    def tearDown(self):
        self.temporary.cleanup()

    def expression(self, path, indices=(0, 1), node="n0"):
        path.write_text(
            "volta-expr 1\n"
            + "\n".join(f'out "out" {i} {node}' for i in indices)
            + "\n"
        )
        return path

    def functional_rows(self):
        receipt = json.loads(B.RECEIPT.read_text())
        historical = {row["id"]: row for row in receipt["results"]}
        rows = []
        for case in B.development(self.document):
            original = historical[case["id"]]
            value = {
                **sample(safe=case["expectation"] == "safe"),
                "status": original["analysis_status"],
                "false_positive": False,
                "unsafe_acceptance": False,
            }
            value["detected"] = original["analysis_status"] == "ordinary_rejection"
            rows.append(
                {
                    "case": case["id"],
                    "category": case["category"],
                    "expectation": case["expectation"],
                    "family": next(
                        w["family"]
                        for w in self.document["workloads"]
                        if w["id"] == case["workload"]
                    ),
                    "baseline_timing_eligible": original["timing_eligible"],
                    "candidate_retains_baseline_qualification": True
                    if original["timing_eligible"]
                    else None,
                    "default_off_invariance": {"passed": True},
                    "baseline_export_control": {"expressions": None},
                    "variants": {
                        "candidate-off": copy.deepcopy(value),
                        "candidate": copy.deepcopy(value),
                    },
                    "specifications": {
                        role: {
                            "status": original["specification_status"],
                            "measurement_errors": [],
                            "timed_out": original["specification_status"] == "timeout",
                        }
                        for role in ("candidate-off", "candidate")
                    }
                    if case["expectation"] == "safe"
                    else {},
                    "baseline": {"status": original["analysis_status"]},
                }
            )
        return rows, [
            {"result": {"status": "mathematical_refutation", "measurement_errors": []}}
            for _ in range(4)
        ]

    def run_output(self, text, *, code=1, stderr="", export=False):
        assembly = self.directory / "kernel.s"
        assembly.write_text("host-only command substitution\n")
        command = [
            sys.executable,
            "-c",
            "import sys;sys.stdout.write(sys.argv[1]);sys.stderr.write(sys.argv[2]);sys.exit(int(sys.argv[3]))",
            text,
            stderr,
            str(code),
        ]
        destination = self.directory / (
            "run-" + str(len(list(self.directory.glob("run-*"))))
        )
        with patch.object(B.study, "command", return_value=command):
            return B.execute(
                Path(sys.executable), self.case, assembly, destination, export=export
            )

    def test_fixed_denominators_and_immutable_source(self):
        receipt = json.loads(B.RECEIPT.read_text())
        self.assertEqual(receipt["safe"]["configured"], 18)
        self.assertEqual(
            receipt["safe"]["complete_graph_footprint_and_specification"], 15
        )
        self.assertEqual(receipt["hazards"]["core_seed_configurations"], 20)
        self.assertEqual(receipt["hazards"]["core_seed_detections"], 13)
        self.assertEqual(len(receipt["timing_eligible"]), 28)
        self.assertEqual(B.sha(HERE / "cases.json"), B.MANIFEST_SHA)
        self.assertEqual(B.sha(HERE / "study.py"), receipt["collector_sha256"])
        self.assertEqual(len(receipt["retained_safe_export_inventory"]), 17)

    def test_actual_ordinary_format_has_observed_detection(self):
        result = self.run_output(ordinary())
        self.assertEqual(result["status"], "ordinary_rejection")
        self.assertIsNotNone(result["time_to_detection_seconds"])
        self.assertGreater(result["usage"]["max_rss_kib"], 0)
        self.assertEqual(result["measurement_errors"], [])

    def test_fail_followed_by_unknown_is_not_detection(self):
        text = ordinary().replace(
            "GRAPH VERIFICATION: REJECTED", "GRAPH VERIFICATION: UNKNOWN"
        )
        result = self.run_output(text, code=2)
        self.assertFalse(result["detected"])
        self.assertIsNone(result["time_to_detection_seconds"])
        self.assertIsNotNone(result["diagnostic_candidates_seconds"]["complete_trace"])

    def test_certified_requires_typed_pair_and_no_contradiction(self):
        result = self.run_output(certified())
        self.assertEqual(result["status"], "certified_rejection")
        self.assertEqual(result["executed_instructions"], 4)
        self.assertEqual(result["prefix_counts"], [4, 8, 32])
        for text, error in [
            (B.study.MARKER + "\nVERDICT: REJECT\n", ""),
            (certified().replace("later: EventId(2)", "later: EventId(1)"), ""),
            (certified() + "GRAPH VERIFICATION: UNKNOWN\n", ""),
            (certified(), "unsupported AMD instruction\n"),
            (certified() + "VC check: 0.001s  elements: 1\n", ""),
        ]:
            with self.subTest(text=text, error=error):
                refused = self.run_output(text, stderr=error)
                self.assertFalse(refused["detected"])
                self.assertIsNone(refused["time_to_detection_seconds"])

    def test_missing_prefix_count_fails_measurement(self):
        result = self.run_output(
            certified().replace(
                "  prefix: instructions=4 amd_records=8 graph_events=32\n", ""
            )
        )
        self.assertTrue(result["measurement_errors"])
        self.assertFalse(B.sample_success(self.case, result))

    def test_missing_resource_and_retained_transcript_drift_refused(self):
        capture = B.capture

        def missing_resource(*args, **kwargs):
            record = capture(*args, **kwargs)
            record["usage"] = {}
            return record

        with patch.object(B, "capture", side_effect=missing_resource):
            result = self.run_output(ordinary())
        self.assertFalse(B.sample_success(self.case, result))
        self.assertTrue(result["measurement_errors"])
        B.bind_sample({}, result)
        (Path(result["directory"]) / "stdout").write_text("replaced transcript")
        with self.assertRaises(ValueError):
            B.bind_sample({}, result)

    def test_invalid_launch_and_midrun_input_swap_are_refused(self):
        result = self.run_output(
            "",
            code=2,
            stderr="error: incompatible launch flags\nUsage: volta analyze\n",
        )
        self.assertEqual(result["status"], "contract_error")
        self.assertFalse(result["detected"])
        assembly = self.directory / "swap.s"
        assembly.write_text("original")
        command = [
            sys.executable,
            "-c",
            "from pathlib import Path;import sys;Path(sys.argv[1]).write_text('changed')",
            str(assembly),
        ]
        with patch.object(B.study, "command", return_value=command):
            with self.assertRaisesRegex(ValueError, "measurement input changed"):
                B.execute(
                    Path(sys.executable),
                    self.case,
                    assembly,
                    self.directory / "input-swap",
                )

    def test_no_export_cannot_hide_unsafe_acceptance(self):
        text = (
            "\n".join(
                "  " + name + " (native contract) PASS"
                for name in sorted(B.study.PROPERTIES)
            )
            + "\nGRAPH VERIFICATION: VERIFIED (no equivalence check requested)\n"
        )
        result = self.run_output(text, code=0)
        self.assertTrue(result["unsafe_acceptance"])
        self.assertFalse(result["detected"])

    def test_timed_hazard_omits_export_both_arms(self):
        assembly = self.directory / "a.s"
        for enabled in (False, True):
            command = B.study.command(
                Path("volta"), self.case, assembly, self.directory, enabled=enabled
            )
            self.assertNotIn("--emit-exprs", command)
            self.assertEqual(command[command.index("--print-outputs") + 1], "0")

    def test_config_enabled_changes_only_one_boolean(self):
        case = next(c for c in B.development(self.document) if c.get("launch_config"))
        command = B.study.command(
            Path("volta"), case, self.directory / "a.s", self.directory, enabled=True
        )
        self.assertNotIn("--early-memory-conflicts", command)
        generated = Path(command[command.index("--config") + 1])
        original = json.loads((B.ROOT / case["launch_config"]).read_text())
        self.assertEqual(
            json.loads(generated.read_text()),
            {**original, "early_memory_conflicts": True},
        )

    def test_complete_duplicate_export_only_is_deleted(self):
        case = {"output_indices": {"out": [0, 1]}}
        reference_path = self.expression(self.directory / "reference.vexpr")
        reference = B.safe_export(reference_path, case)
        duplicate = self.expression(self.directory / "duplicate.vexpr")
        observation = B.safe_export(duplicate, case, reference, discard_duplicate=True)
        self.assertTrue(observation["duplicate_removed"])
        self.assertFalse(duplicate.exists())
        self.assertTrue(reference_path.exists())
        for indices in [(0,), (1, 2), (0, 0), (0, 1, 2)]:
            path = self.expression(self.directory / "bad.vexpr", indices)
            with self.assertRaises(ValueError):
                B.safe_export(path, case, reference, discard_duplicate=True)
            self.assertTrue(path.exists())
        path = self.expression(self.directory / "different.vexpr", node="n1")
        with self.assertRaises(ValueError):
            B.safe_export(path, case, reference, discard_duplicate=True)
        self.assertTrue(path.exists())

    def test_reference_alias_and_drift_refused_without_deletion(self):
        case = {"output_indices": {"out": [0, 1]}}
        path = self.expression(self.directory / "reference.vexpr")
        reference = B.safe_export(path, case)
        with self.assertRaises(ValueError):
            B.safe_export(path, case, reference, discard_duplicate=True)
        alias = self.directory / "alias.vexpr"
        alias.symlink_to(path)
        with self.assertRaises(ValueError):
            B.safe_export(alias, case, reference, discard_duplicate=True)
        duplicate = self.expression(self.directory / "duplicate.vexpr")
        self.expression(path, node="n1")
        with self.assertRaises(ValueError):
            B.safe_export(duplicate, case, reference, discard_duplicate=True)
        self.assertTrue(duplicate.exists())

    def test_default_off_invariance_keeps_findings_and_real_counts(self):
        left = sample()
        self.assertTrue(B.invariance(left, copy.deepcopy(left))["passed"])
        for field, value in [
            ("diagnostics_sha256", "other finding"),
            ("executed_instructions", 9),
            ("expressions", {"sha256": "different"}),
        ]:
            right = {**left, field: value}
            self.assertFalse(B.invariance(left, right)["passed"])
        self.assertFalse(B.invariance(left, {**left, "timed_out": True})["comparable"])
        # An actual incomplete hazard export is still compared, not replaced by
        # the safe output contract or misrepresented as a complete proof.
        left["expressions"] = {"output_counts": {"out": 1}, "sha256": "same-fault"}
        self.assertTrue(B.invariance(left, copy.deepcopy(left))["passed"])

    def test_fixed_pairs_missing_duplicate_or_failed_candidate_never_filtered(self):
        case = {"id": "fixed-hazard", "expectation": "hazard", "primary_latency": True}
        values = [
            {**sample(), "case": case["id"], "role": role, "repeat": repeat}
            for repeat in range(32)
            for role in ("baseline", "candidate")
        ]
        functional = {
            "correctness_gates_pass": True,
            "new_coverage_families": ["a", "b", "c", "d"],
            "new_complex_coverage_families": ["c", "d"],
        }
        summary = B.timing_summary(
            [case], values, functional, self.document["protocol"]
        )
        self.assertTrue(summary["adoption_gates_pass"])
        for changed in (values[:-1], values + [values[0]]):
            with self.assertRaises(ValueError):
                B.timing_summary([case], changed, functional, self.document["protocol"])
        failed = copy.deepcopy(values)
        failed[1].update(
            status="inconclusive", detected=False, time_to_detection_seconds=None
        )
        summary = B.timing_summary(
            [case], failed, functional, self.document["protocol"]
        )
        self.assertEqual(summary["baseline_fixed_cases"], 1)
        self.assertEqual(summary["successful_paired_comparisons"], 0)
        self.assertEqual(
            summary["failed_candidate_or_baseline_qualifiers"], [case["id"]]
        )
        self.assertFalse(summary["adoption_gates_pass"])
        self.assertIsNone(summary["cases"][0]["median_ratio_interval"])

    def test_existing_detections_and_tails_are_not_additional_algorithm_coverage(self):
        rows, controls = self.functional_rows()
        for row in rows:
            if row["expectation"] == "hazard" and (
                row["baseline_timing_eligible"]
                or row["category"] == "synthetic_unsupported_tail"
            ):
                row["variants"]["candidate"].update(
                    status="certified_rejection", detected=True
                )
        result = B.functional_summary(rows, controls)
        self.assertTrue(result["correctness_gates_pass"])
        self.assertGreater(len(result["certified_families"]), 0)
        self.assertEqual(result["new_coverage_families"], [])
        for row in rows:
            if row["expectation"] == "hazard" and not row["baseline_timing_eligible"]:
                row["variants"]["candidate"].update(
                    status="certified_rejection", detected=True
                )
        result = B.functional_summary(rows, controls)
        self.assertEqual(len(result["new_coverage_families"]), 5)
        self.assertEqual(len(result["new_complex_coverage_families"]), 4)
        self.assertTrue(
            all(r["baseline_ratio"] is None for r in result["new_coverage"])
        )

    def test_missing_proof_changed_safe_output_and_unsafe_acceptance_fail_gates(self):
        rows, controls = self.functional_rows()
        self.assertTrue(B.functional_summary(rows, controls)["correctness_gates_pass"])
        self.assertFalse(
            B.functional_summary(rows, controls[:-1])["correctness_gates_pass"]
        )
        changed = copy.deepcopy(rows)
        safe = next(
            r
            for r in changed
            if r["expectation"] == "safe" and r["baseline_timing_eligible"]
        )
        safe["candidate_retains_baseline_qualification"] = False
        self.assertFalse(
            B.functional_summary(changed, controls)["correctness_gates_pass"]
        )
        safe["candidate_retains_baseline_qualification"] = True
        safe["variants"]["candidate"]["expressions"] = {"sha256": "different"}
        self.assertFalse(
            B.functional_summary(changed, controls)["correctness_gates_pass"]
        )
        changed = copy.deepcopy(rows)
        changed[-1]["variants"]["candidate"]["unsafe_acceptance"] = True
        self.assertFalse(
            B.functional_summary(changed, controls)["correctness_gates_pass"]
        )

    def test_safe_overhead_limit_cannot_be_ignored(self):
        case = {"id": "fixed-safe", "expectation": "safe", "primary_latency": False}
        values = [
            {**sample(safe=True), "case": case["id"], "role": role, "repeat": repeat}
            for repeat in range(32)
            for role in ("baseline", "candidate")
        ]
        for row in values:
            if row["role"] == "candidate":
                row["seconds"] = 0.013
        functional = {
            "correctness_gates_pass": True,
            "new_coverage_families": ["a", "b", "c", "d"],
            "new_complex_coverage_families": ["c", "d"],
        }
        summary = B.timing_summary(
            [case], values, functional, self.document["protocol"]
        )
        self.assertFalse(summary["overhead_gates_pass"])
        self.assertFalse(summary["adoption_gates_pass"])

    def test_timeout_kills_wrapper_and_verifier_descendant(self):
        marker = self.directory / "child.pid"
        code = "import subprocess,sys,time; p=subprocess.Popen([sys.executable,'-c','import time;time.sleep(30)']);open(sys.argv[1],'w').write(str(p.pid));print('child started',flush=True);time.sleep(30)"
        record = B.capture(
            [sys.executable, "-c", code, str(marker)], self.directory, timeout=0.25
        )
        self.assertTrue(record["timed_out"])
        self.assertLess(record["seconds"], 5)
        self.assertTrue(marker.exists())
        pid = int(marker.read_text())
        for _ in range(20):
            state = Path(f"/proc/{pid}/stat")
            if not state.exists() or state.read_text().split()[2] == "Z":
                break
            time.sleep(0.01)
        else:
            self.fail("timed-out verifier descendant survived")
        self.assertIn("child started", (self.directory / "stdout").read_text())

    def test_source_drift_refused_and_fresh_output_protected(self):
        path = self.directory / "input"
        path.write_text("original")
        frozen = B.snapshots([path])
        path.write_text("changed")
        with self.assertRaises(ValueError):
            B.unchanged(frozen)
        with self.assertRaises(ValueError):
            B.fresh(self.directory)
        with self.assertRaises(ValueError):
            B.fresh(B.HERE / "must-not-create-output")
        self.assertFalse((B.HERE / "must-not-create-output").exists())


if __name__ == "__main__":
    unittest.main()
