#!/usr/bin/env python3
"""Host-only refusal, fixed-population and point-gate controls; no verifier."""

import copy
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "native_lazy_collect", Path(__file__).with_name("collect.py")
)
collect = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(collect)


def row(expectation="hazard"):
    return {
        "case": {
            "target": "gfx950",
            "block": [64, 1, 1],
            "expectation": expectation,
            "expected_outputs": 1,
            "output_indices": {"out": [0]},
        }
    }


def record():
    return {
        "returncode": 1,
        "timed_out": False,
        "log_limit_exceeded": False,
        "seconds": 0.03,
        "first_marker_seconds": 0.02,
        "usage": {"max_rss_kib": 1024, "user_seconds": 0.01, "system_seconds": 0.00},
    }


HAZARD = """EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION
  AMD memory-conflict freedom (certified prefix) FAIL
  instruction=EventId(2) issue=EventId(3) wave=0 earlier_thread=ThreadIx(0) later_thread=ThreadIx(1)
  prefix: instructions=5 amd_records=9 graph_events=20
  kernel: MemoryConflict { kind: WriteWrite, location: ByteLocation { space: Global, addr: 65536 }, earlier: EventId(10), later: EventId(11) }
VERDICT: REJECT
"""
SAFE = """  time: 0.001s  instructions: 5  block syncs: 0  warp syncs: 0
  output 'out': 1 element(s) written
kernel: graph verification
  AMD trace completeness (native AMD graph contract) PASS
  AMD wait and register readiness (target-selected counters and register dependencies) PASS
  AMD workgroup barrier generations (target-selected AMD barrier objects and phases) PASS
  AMD memory-conflict freedom (AMD completed-effect happens-before) PASS
GRAPH VERIFICATION: VERIFIED (no equivalence check requested)
"""


class Controls(unittest.TestCase):
    def test_fixed_28_population_counts(self):
        selected = collect.selection()
        self.assertEqual(
            sum(
                c["input_elements"] for c in selected["cases"] if c.get("new_contract")
            ),
            67108864,
        )
        self.assertEqual(
            [c["input_elements"] for c in selected["cases"] if c["primary"]],
            [135168, 274432, 139264],
        )

    def test_new_full_gemm_preserves_every_other_field(self):
        case = {
            "id": "old",
            "kernel": "gemm_f16_full",
            "grid": [1, 1, 1],
            "block": [1024, 1, 1],
            "workgroup": [0, 0, 0],
            "arrays": [
                {"name": "a", "base_address": 1, "length": 1048576, "element_size": 2},
                {"name": "b", "base_address": 2, "length": 16777216, "element_size": 2},
                *[
                    {
                        "name": f"out{n:03}",
                        "base_address": 3 + n * 8192,
                        "length": 256,
                        "element_size": 2,
                    }
                    for n in range(256)
                ],
            ],
            "params": ["ptr:a", "ptr:b", "ptr:out000"],
            "dimensions": {"M": 4096, "N": 4096, "K": 4096, "TILE": 256},
            "launch_config": "historical.json",
        }
        before = copy.deepcopy(case)
        got = collect.full_gemm(case, {"id": "new", "primary": False})
        self.assertEqual(case, before)
        self.assertEqual(got["grid"], [16, 16, 1])
        self.assertFalse(got["primary_latency"])
        self.assertNotIn("source_ground_truth_first_collision", got)
        self.assertNotIn("launch_config_sha256", got)
        self.assertEqual(
            [x["base_address"] for x in got["arrays"][:2]], [0x10000000, 0x20000000]
        )
        self.assertEqual([x["length"] for x in got["arrays"][:2]], [4096**2] * 2)
        self.assertEqual(got["arrays"][-1]["base_address"], 0x30000000 + 255 * 8192)
        for key in ["params", "dimensions", "block", "workgroup"]:
            self.assertEqual(got[key], before[key])
        intervals = sorted(
            (a["base_address"], a["base_address"] + a["length"] * a["element_size"])
            for a in got["arrays"]
        )
        self.assertTrue(all(a[1] <= b[0] for a, b in zip(intervals, intervals[1:])))

    def test_pairing_is_deterministic_adjacent_counterbalanced(self):
        ids = ["a", "b", "c"]
        order = collect.paired_order(ids)
        self.assertEqual(order, collect.paired_order(ids))
        self.assertEqual(len(order), 30)
        for i in range(0, len(order), 2):
            left, right = order[i : i + 2]
            self.assertEqual(left[:2], right[:2])
            self.assertEqual({left[2], right[2]}, {"baseline", "candidate"})
        for cid in ids:
            self.assertIn(
                sum(
                    order[i][2] == "baseline"
                    for i in range(0, len(order), 2)
                    if order[i][0] == cid
                ),
                [2, 3],
            )

    def test_authenticated_hazard_has_first_endpoint(self):
        got = collect.observe(record(), row(), HAZARD, "")
        self.assertTrue(got["qualified"])
        self.assertEqual(got["endpoint_seconds"], 0.02)
        self.assertEqual(
            got["signature"]["first_typed_witness"], [["Global", "65536", "10", "11"]]
        )

    def test_timeout_marker_is_not_detection(self):
        r = record()
        r["timed_out"] = True
        got = collect.observe(r, row(), HAZARD, "")
        self.assertFalse(got["qualified"])
        self.assertIsNone(got["endpoint_seconds"])

    def test_marker_without_witness_or_reject_refuses(self):
        for text in [
            collect.study.MARKER,
            HAZARD.replace("VERDICT: REJECT", "VERDICT: UNKNOWN"),
            HAZARD.replace("EventId(11)", "EventId(10)"),
        ]:
            with self.subTest(text=text):
                self.assertFalse(
                    collect.observe(record(), row(), text, "")["qualified"]
                )

    def test_missing_marker_time_resource_and_log_overflow_refuse(self):
        for field, value in [
            ("first_marker_seconds", None),
            ("usage", {}),
            ("log_limit_exceeded", True),
        ]:
            r = record()
            r[field] = value
            self.assertFalse(collect.observe(r, row(), HAZARD, "")["qualified"])

    def test_safe_parent_endpoint_requires_all_array_counts(self):
        r = record()
        r["returncode"] = 0
        got = collect.observe(r, row("safe"), SAFE, "")
        self.assertTrue(got["qualified"])
        self.assertEqual(got["endpoint_seconds"], r["seconds"])
        self.assertFalse(
            collect.observe(r, row("safe"), SAFE.replace("1 element", "0 element"), "")[
                "qualified"
            ]
        )

    def test_exact_first_witness_and_prefix_must_match(self):
        r = record()
        expected = collect.observe(r, row(), HAZARD, "")["signature"]
        for changed in [
            HAZARD.replace("65536", "65540"),
            HAZARD.replace("instructions=5", "instructions=6"),
            HAZARD.replace("EventId(11)", "EventId(12)"),
        ]:
            self.assertFalse(
                collect.observe(r, row(), changed, "", expected)["qualified"]
            )

    def test_false_positive_and_unsafe_accept_remain_in_denominator(self):
        self.assertTrue(
            collect.observe(record(), row("safe"), HAZARD, "")["false_positive"]
        )
        r = record()
        r["returncode"] = 0
        self.assertTrue(collect.observe(r, row(), SAFE, "")["unsafe_acceptance"])

    def test_point_gate_exact_thresholds(self):
        def observations(t, rss):
            return [
                {
                    "qualified": True,
                    "endpoint_seconds": t,
                    "usage": {"max_rss_kib": rss},
                }
                for _ in range(5)
            ]

        base = observations(0.1, 100000)
        got = collect.point_gate(base, observations(0.08, 108192), True)
        self.assertTrue(got["benefit"])
        self.assertTrue(got["rss_nonregression"])
        self.assertFalse(
            collect.point_gate(base, observations(0.080001, 108193), True)["benefit"]
        )
        self.assertFalse(
            collect.point_gate(base, observations(0.08, 108193), True)[
                "rss_nonregression"
            ]
        )
        self.assertTrue(
            collect.point_gate(base, observations(0.112, 100000))[
                "endpoint_nonregression"
            ]
        )
        self.assertFalse(
            collect.point_gate(base, observations(0.112001, 100000))[
                "endpoint_nonregression"
            ]
        )

    def test_absolute_benefit_and_allfive_are_required(self):
        base = [
            {
                "qualified": True,
                "endpoint_seconds": 0.02,
                "usage": {"max_rss_kib": 1024},
            }
            for _ in range(5)
        ]
        small = [{**x, "endpoint_seconds": 0.016} for x in base]
        self.assertFalse(collect.point_gate(base, small, True)["benefit"])
        small[0]["qualified"] = False
        self.assertFalse(collect.point_gate(base, small)["valid"])
        with self.assertRaises(ValueError):
            collect.point_gate(base[:4], small)

    def test_command_preserves_config_no_timed_exports(self):
        r = {
            "case": {"target": "gfx1250"},
            "assembly": "/module.s",
            "configuration": "/config.json",
        }
        argv = collect.command(Path("/volta"), r)
        self.assertNotIn("--emit-exprs", argv)
        self.assertNotIn("--early-memory-conflicts", argv)
        self.assertEqual(argv[argv.index("--config") + 1], "/config.json")

    def test_synthetic_capture_keeps_raw_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)
            got = collect.capture(
                [
                    sys.executable,
                    "-c",
                    "import sys;print('hello');sys.stderr.write('error\\n')",
                ],
                p,
            )
            self.assertEqual(got["returncode"], 0)
            self.assertFalse(got["timed_out"])
            self.assertEqual((p / "stdout").read_bytes(), b"hello\n")
            self.assertEqual((p / "stderr").read_bytes(), b"error\n")
            self.assertGreater(got["usage"]["max_rss_kib"], 0)

    def test_synthetic_timeout_retains_partial_logs(self):
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.object(collect, "TIMEOUT", 0.05),
        ):
            p = Path(tmp)
            got = collect.capture(
                [
                    sys.executable,
                    "-u",
                    "-c",
                    "import time; print('before'); time.sleep(5)",
                ],
                p,
            )
            self.assertTrue(got["timed_out"])
            self.assertIn(b"before", (p / "stdout").read_bytes())

    def test_synthetic_output_overflow_is_retained_failure(self):
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.object(collect, "LOG_LIMIT", 1024),
        ):
            p = Path(tmp)
            got = collect.capture(
                [sys.executable, "-u", "-c", "import os; os.write(1,b'x'*65536)"],
                p,
                log_limit=1024,
            )
            self.assertTrue(got["log_limit_exceeded"])
            self.assertGreater((p / "stdout").stat().st_size, 1024)

    def test_new_gemm_has_strict_source_ground_truth_and_no_automatic_coverage(self):
        r = row()
        r["case"].update(
            new_contract=True,
            ground_truth={"space": "Shared", "constant_address": {"value": 0}},
            source_ground_truth_first_collision={
                "space": "Shared",
                "byte_address": 0,
                "wave": 0,
                "physical_threads": [0, 1],
                "executed_instructions": 4225,
            },
        )
        good = (
            HAZARD.replace("space: Global, addr: 65536", "space: Shared, addr: 0")
            .replace("instructions=5", "instructions=4225")
            .replace(
                "amd_records=9 graph_events=20", "amd_records=5000 graph_events=6000"
            )
        )
        observed = collect.observe(record(), r, good, "")
        self.assertTrue(observed["qualified"])
        self.assertTrue(observed["new_contract_witness_audit_required"])
        self.assertFalse(observed["new_coverage_credited"])
        self.assertFalse(collect.observe(record(), r, HAZARD, "")["qualified"])
        self.assertFalse(
            collect.observe(record(), r, good.replace("addr: 0", "addr: 2"), "")[
                "qualified"
            ]
        )
        self.assertFalse(
            collect.observe(
                record(), r, good.replace("instructions=4225", "instructions=4226"), ""
            )["qualified"]
        )
        self.assertFalse(
            collect.observe(
                record(), r, good.replace("EventId(11)", "EventId(6000)"), ""
            )["qualified"]
        )

    def test_complete_spec_accept_is_distinct_from_graph_accept(self):
        r = record()
        r["returncode"] = 0
        proof = SAFE.replace(
            "GRAPH VERIFICATION: VERIFIED (no equivalence check requested)",
            "VC check: 0.001s  elements: 1\nEQUIVALENT (matches spec)\nVERDICT: ACCEPT",
        )
        got = collect.observe(r, row("safe"), proof, "", verify=True)
        self.assertEqual(got["status"], "spec_verified")
        self.assertTrue(got["qualified"])
        self.assertFalse(
            collect.observe(
                r,
                row("safe"),
                proof.replace("elements: 1", "elements: 0"),
                "",
                verify=True,
            )["qualified"]
        )

    def test_exhausted_aggregate_budget_keeps_an_explicit_unrun_record(self):
        with tempfile.TemporaryDirectory() as tmp:
            r = {
                "case": {
                    "expectation": "safe",
                    "expected_outputs": 1,
                    "output_indices": {"out": [0]},
                    "target": "gfx1250",
                },
                "assembly": "/module.s",
                "configuration": "/config.json",
            }
            got = collect.execute(
                Path("/nonexistent-verifier"), r, Path(tmp) / "retained", log_limit=0
            )
            self.assertFalse(got["qualified"])
            self.assertEqual(
                got["not_run_reason"], "aggregate raw log budget exhausted"
            )
            self.assertEqual(got["raw_log_bytes"], 0)
            self.assertIsNone(got["returncode"])

    def test_new_gemm_refuses_missing_duplicate_or_forged_frame(self):
        r = row()
        r["case"].update(
            new_contract=True,
            ground_truth={"space": "Shared", "constant_address": {"value": 0}},
            source_ground_truth_first_collision={
                "space": "Shared",
                "byte_address": 0,
                "wave": 0,
                "physical_threads": [0, 1],
                "executed_instructions": 4225,
            },
        )
        good = (
            HAZARD.replace("space: Global, addr: 65536", "space: Shared, addr: 0")
            .replace("instructions=5", "instructions=4225")
            .replace(
                "amd_records=9 graph_events=20", "amd_records=5000 graph_events=6000"
            )
        )
        frame = "  instruction=EventId(2) issue=EventId(3) wave=0 earlier_thread=ThreadIx(0) later_thread=ThreadIx(1)"
        forged = [
            good.replace(frame + "\n", ""),
            good.replace(frame, frame + "\n" + frame),
            good.replace("wave=0", "wave=1"),
            good.replace("ThreadIx(0)", "ThreadIx(2)"),
            good.replace("ThreadIx(1)", "ThreadIx(0)"),
            good.replace("instruction=EventId(2)", "instruction=EventId(3)"),
            good.replace("issue=EventId(3)", "issue=EventId(10)"),
            good.replace("amd_records=5000", "amd_records=4224"),
            good.replace("amd_records=5000", "amd_records=6001"),
        ]
        for text in forged:
            with self.subTest(text=text):
                self.assertFalse(collect.observe(record(), r, text, "")["qualified"])

    def test_invalid_completion_or_marker_telemetry_refuses(self):
        for field, value in [
            ("seconds", 0),
            ("seconds", float("nan")),
            ("seconds", float("inf")),
            ("first_marker_seconds", 0),
            ("first_marker_seconds", -1),
            ("first_marker_seconds", 0.04),
            ("first_marker_seconds", float("nan")),
            ("first_marker_seconds", float("inf")),
        ]:
            r = record()
            r[field] = value
            self.assertFalse(collect.observe(r, row(), HAZARD, "")["qualified"])

    def test_every_certified_case_requires_real_same_wave_physical_geometry(self):
        frame = "  instruction=EventId(2) issue=EventId(3) wave=0 earlier_thread=ThreadIx(0) later_thread=ThreadIx(1)"
        forged = [
            HAZARD.replace(frame + "\n", ""),
            HAZARD.replace(frame, frame + "\n" + frame),
            HAZARD.replace("wave=0", "wave=1"),
            HAZARD.replace("ThreadIx(1)", "ThreadIx(64)"),
            HAZARD.replace("ThreadIx(1)", "ThreadIx(0)"),
            HAZARD.replace("issue=EventId(3)", "issue=EventId(10)"),
        ]
        for text in forged:
            self.assertFalse(collect.observe(record(), row(), text, "")["qualified"])
        r = row()
        r["case"].update(target="gfx1250", block=[64, 1, 1])
        self.assertFalse(
            collect.observe(
                record(), r, HAZARD.replace("ThreadIx(1)", "ThreadIx(32)"), ""
            )["qualified"]
        )

    def test_certified_prefix_cannot_claim_output_or_complete_success(self):
        for appended in [
            "  output 'out': 1 element(s) written",
            "Wrote output expressions to expressions.vexpr",
            "VC check: 0.001s  elements: 1",
            "EQUIVALENT (matches spec)",
            "GRAPH VERIFICATION: VERIFIED",
            "volta-expr 1",
            'out "out" 0 n0',
        ]:
            result = collect.observe(record(), row(), HAZARD + appended + "\n", "")
            self.assertFalse(result["qualified"])
            self.assertFalse(result["detected"])
            self.assertIsNone(result["detection_mode"])
            self.assertEqual(result["status"], "contract_error")


if __name__ == "__main__":
    unittest.main()
