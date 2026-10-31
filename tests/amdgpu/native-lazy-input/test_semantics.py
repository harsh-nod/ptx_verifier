#!/usr/bin/env python3
"""Synthetic FIFO/gzip, full-output and proof-retention refusal controls."""

import gzip
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "lazy_semantics_test", Path(__file__).with_name("semantics.py")
)
sem = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sem)
VEXPR = b'volta-expr 1\nn0 = elem "x" 0\nout "out" 0 n0\n'


def child(fifo, data=VEXPR, *, fail=False):
    program = (
        "import pathlib,sys; pathlib.Path(sys.argv[1]).write_bytes("
        + repr(data)
        + "); sys.exit("
        + str(int(fail))
        + ")"
    )
    return [sys.executable, "-c", program, str(fifo)]


class Controls(unittest.TestCase):
    def test_streams_from_first_byte_into_repeatable_gzip(self):
        with tempfile.TemporaryDirectory() as tmp:
            raw = Path(tmp)
            observations = []
            for name in ("a", "b"):
                result = sem.capture_export(child, raw / name, sem.Budget(2**20))
                self.assertTrue(result["gzip_capture"]["complete"])
                artifact = raw / name / "outputs.vexpr.gz"
                self.assertEqual(gzip.decompress(artifact.read_bytes()), VEXPR)
                self.assertEqual(
                    result["gzip_capture"]["received_decoded_bytes"], len(VEXPR)
                )
                self.assertEqual(
                    result["gzip_capture"]["received_decoded_sha256"],
                    sem.hashlib.sha256(VEXPR).hexdigest(),
                )
                self.assertFalse((raw / name / "outputs.fifo").exists())
                self.assertFalse((raw / name / "outputs.vexpr").exists())
                observations.append(artifact.read_bytes())
            self.assertEqual(observations[0], observations[1])
            self.assertEqual(observations[0][4:8], b"\0\0\0\0")
            self.assertEqual(observations[0][3] & 8, 0)

    def test_nonzero_child_retains_complete_bytes_but_no_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "failed"
            result = sem.capture_export(
                lambda fifo: child(fifo, fail=True), p, sem.Budget(2**20)
            )
            self.assertFalse(result["gzip_capture"]["complete"])
            self.assertEqual(result["returncode"], 1)
            self.assertEqual(
                gzip.decompress((p / "outputs.vexpr.gz").read_bytes()), VEXPR
            )

    def test_child_never_opening_fifo_cannot_hang_or_claim_export(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = sem.capture_export(
                lambda _: [sys.executable, "-c", "pass"],
                Path(tmp) / "empty",
                sem.Budget(2**20),
            )
            self.assertFalse(result["gzip_capture"]["complete"])
            self.assertEqual(result["gzip_capture"]["received_decoded_bytes"], 0)

    def test_timeout_retains_partial_gzip_and_logs(self):
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.object(sem.frozen, "TIMEOUT", 0.1),
        ):
            p = Path(tmp) / "timeout"
            program = "import sys,time; f=open(sys.argv[1],'wb',buffering=0); f.write(b'volta-expr 1\\n'); print('before',flush=True); time.sleep(5)"
            result = sem.capture_export(
                lambda fifo: [sys.executable, "-u", "-c", program, str(fifo)],
                p,
                sem.Budget(2**20),
            )
            self.assertTrue(result["timed_out"])
            self.assertFalse(result["gzip_capture"]["complete"])
            self.assertIn(b"before", (p / "stdout").read_bytes())
            self.assertEqual(
                gzip.decompress((p / "outputs.vexpr.gz").read_bytes()),
                b"volta-expr 1\n",
            )

    def test_shared_compressed_budget_never_exceeds_limit(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)
            budget = sem.Budget(50)
            first = sem.capture_export(child, p / "a", budget)
            self.assertFalse(first["gzip_capture"]["complete"])
            self.assertLessEqual(budget.used, 50)
            self.assertEqual(budget.used, (p / "a/outputs.vexpr.gz").stat().st_size)
            second = sem.capture_export(child, p / "b", budget)
            self.assertFalse(second["gzip_capture"]["complete"])
            self.assertLessEqual(budget.used, 50)
            self.assertEqual(
                budget.used, sum(x.stat().st_size for x in p.glob("*/outputs.vexpr.gz"))
            )

    def test_disk_reserve_refuses_before_writing(self):
        with tempfile.TemporaryDirectory() as tmp:
            raw = io.BytesIO()
            budget = sem.Budget(1000, reserve=100)
            with patch.object(sem.shutil, "disk_usage") as usage:
                usage.return_value.free = 101
                with self.assertRaises(sem.StorageLimit):
                    budget.writer(raw, Path(tmp)).write(b"some bytes")
            self.assertEqual(raw.getvalue(), b"")
            self.assertEqual(budget.used, 0)

    def test_reader_gzip_or_reserve_failure_is_retained_without_child_launch(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)
            with patch.object(
                sem.gzip,
                "GzipFile",
                side_effect=sem.zlib.error("synthetic compressor failure"),
            ):
                result = sem.capture_export(child, p / "compressor", sem.Budget(2**20))
            self.assertIsNone(result["returncode"])
            self.assertFalse(result["gzip_capture"]["complete"])
            self.assertTrue(result["gzip_capture"]["errors"])
            self.assertTrue((p / "compressor/outputs.vexpr.gz").exists())
            with patch.object(sem.shutil, "disk_usage") as usage:
                usage.return_value.free = 1
                result = sem.capture_export(child, p / "reserve", sem.Budget(2**20))
            self.assertIsNone(result["returncode"])
            self.assertFalse(result["gzip_capture"]["complete"])
            self.assertTrue(result["gzip_capture"]["errors"])

    def test_old_proofs_need_all_cases_and_both_arms(self):
        plan = {
            "cases": [
                {
                    "case": {"id": "proved"},
                    "definition": {
                        "expectation": "safe",
                        "previous_complete_equation_proved": True,
                    },
                },
                {
                    "case": {"id": "unproved"},
                    "definition": {
                        "expectation": "safe",
                        "previous_complete_equation_proved": False,
                    },
                },
            ]
        }
        rows = [
            {
                "case": cid,
                "role": role,
                "stage": "verify",
                "qualified": cid == "proved",
                "status": "spec_verified" if cid == "proved" else "timeout",
                "measurement_errors": [],
            }
            for cid in ("proved", "unproved")
            for role in ("baseline", "candidate")
        ]
        self.assertTrue(
            sem.proof_gates(rows, plan)["all_previous_complete_proofs_retained"]
        )
        self.assertEqual(len(sem.proof_gates(rows, plan)["other_equations"]), 2)
        self.assertFalse(
            sem.proof_gates(rows[1:], plan)["all_previous_complete_proofs_retained"]
        )
        rows[0]["status"] = "mathematical_refutation"
        self.assertFalse(
            sem.proof_gates(rows, plan)["all_previous_complete_proofs_retained"]
        )

    def test_unrun_verification_record_keeps_declared_command(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)
            result = sem.retained_failure(
                ["volta", "verify", "module.s", "full.spec", "--sample", "0"],
                p,
                "budget exhausted",
            )
            self.assertIn("verify", result["command"])
            self.assertIsNone(result["returncode"])
            self.assertIn("not_run_reason", result)
            self.assertTrue((p / "stdout").exists())

    def test_actual_scanner_binds_gzip_and_refuses_shifted_or_partial_outputs(self):
        tool_path = Path(__file__).with_name("compare_vexpr_structure_20261031.py")
        self.assertEqual(sem.sha(tool_path), sem.frozen.COMPARATOR_SHA)
        tool = sem.frozen.load_module("lazy_actual_scanner_test", tool_path)
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "export"
            capture = sem.capture_export(child, p, sem.Budget(2**20))["gzip_capture"]
            artifact = p / "outputs.vexpr.gz"
            self.assertEqual(
                sem.validate_expression_capture(tool, artifact, {"out": [0]}, capture)[
                    "output_count"
                ],
                1,
            )
            for expected, altered in [
                ({"out": [1]}, capture),
                ({"out": [0]}, {**capture, "received_decoded_bytes": len(VEXPR) + 1}),
                ({"out": [0]}, {**capture, "artifact_sha256": "0" * 64}),
                ({"out": [0]}, {**capture, "complete": False}),
            ]:
                with self.assertRaises(ValueError):
                    sem.validate_expression_capture(tool, artifact, expected, altered)
            artifact.write_bytes(artifact.read_bytes()[:-3])
            with self.assertRaises(ValueError):
                sem.validate_expression_capture(tool, artifact, {"out": [0]}, capture)

    def test_zero_byte_writer_and_partial_expression_never_get_semantic_credit(self):
        tool_path = Path(__file__).with_name("compare_vexpr_structure_20261031.py")
        tool = sem.frozen.load_module("lazy_partial_scanner_test", tool_path)
        with tempfile.TemporaryDirectory() as tmp:
            for i, data in enumerate((b"", b'volta-expr 1\nn0 = elem "x" 0\n')):
                p = Path(tmp) / str(i)
                capture = sem.capture_export(
                    lambda fifo: child(fifo, data), p, sem.Budget(2**20)
                )["gzip_capture"]
                with self.assertRaises(ValueError):
                    sem.validate_expression_capture(
                        tool, p / "outputs.vexpr.gz", {"out": [0]}, capture
                    )
                self.assertTrue((p / "outputs.vexpr.gz").exists())

    def test_false_finding_in_unproved_verify_fails_the_whole_semantic_gate(self):
        plan = {
            "cases": [
                {
                    "case": {"id": "proved"},
                    "definition": {
                        "expectation": "safe",
                        "previous_complete_equation_proved": True,
                    },
                },
                {
                    "case": {"id": "unproved"},
                    "definition": {
                        "expectation": "safe",
                        "previous_complete_equation_proved": False,
                    },
                },
            ]
        }
        rows = [
            {
                "case": cid,
                "role": role,
                "stage": "verify",
                "qualified": cid == "proved",
                "status": "spec_verified" if cid == "proved" else "timeout",
                "measurement_errors": [],
                "false_positive": False,
                "unsafe_acceptance": False,
                "graph_failure_names": [],
            }
            for cid in ("proved", "unproved")
            for role in ("baseline", "candidate")
        ]
        matches = [{"structural_match": True}]
        self.assertTrue(
            sem.semantic_gates(rows, matches, plan)["all_semantic_controls_pass"]
        )
        rows[-1]["false_positive"] = True
        self.assertFalse(
            sem.semantic_gates(rows, matches, plan)["all_semantic_controls_pass"]
        )
        rows[-1]["false_positive"] = False
        rows[-1]["graph_failure_names"] = ["AMD wait and register readiness"]
        self.assertFalse(
            sem.semantic_gates(rows, matches, plan)["all_semantic_controls_pass"]
        )
        rows[-1]["graph_failure_names"] = []
        rows[-1]["unsafe_acceptance"] = True
        self.assertFalse(
            sem.semantic_gates(rows, matches, plan)["all_semantic_controls_pass"]
        )
        rows[-1]["unsafe_acceptance"] = False
        rows[-1]["status"] = "mathematical_refutation"
        result = sem.semantic_gates(rows, matches, plan)
        self.assertEqual(result["mathematical_refutations"], 1)
        self.assertFalse(result["all_semantic_controls_pass"])


if __name__ == "__main__":
    unittest.main()
