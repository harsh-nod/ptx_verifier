#!/usr/bin/env python3
"""Host-only refusal/accounting controls for portable_run.py."""

import copy
import contextlib
import io
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import subprocess
import sys
import unittest
from unittest import mock

SCRIPT = Path(__file__).with_name("portable_run.py")
SPEC = importlib.util.spec_from_file_location("portable_run", SCRIPT)
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)
FIXTURES = SCRIPT.parent.parent


class PortableHardwareControls(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        (self.directory / "fixtures").mkdir()
        for relative in (
            "portable-cases.json",
            "fixtures/native-portable-workloads.s",
            "fixtures/native-portable-workloads.hip",
        ):
            shutil.copyfile(FIXTURES / relative, self.directory / relative)
        self.manifest = json.loads((self.directory / "portable-cases.json").read_text())

    def write_manifest(self):
        (self.directory / "portable-cases.json").write_text(json.dumps(self.manifest))

    def test_pinned_complete_manifest_has_twenty_cases_and_590_values(self):
        cases = RUNNER.validate_manifest(self.directory)
        self.assertEqual(20, len(cases))
        self.assertEqual(590, sum(case["expected_outputs"] for case in cases))

    def test_empty_partial_duplicate_and_disabled_corpora_are_rejected(self):
        original = copy.deepcopy(self.manifest)
        for mutation in (
            [],
            original["cases"][:-1],
            original["cases"][:-1] + [original["cases"][0]],
        ):
            with self.subTest(case_count=len(mutation)):
                self.manifest = dict(original, cases=mutation)
                self.write_manifest()
                with self.assertRaises(ValueError):
                    RUNNER.validate_manifest(self.directory)
        self.manifest = copy.deepcopy(original)
        self.manifest["cases"][0]["required"] = False
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, "cannot be disabled"):
            RUNNER.validate_manifest(self.directory)

    def test_changed_exact_assembly_is_rejected_before_execution(self):
        path = self.directory / "fixtures/native-portable-workloads.s"
        path.write_bytes(path.read_bytes() + b"\n// altered\n")
        with self.assertRaisesRegex(ValueError, "assembly differs"):
            RUNNER.validate_manifest(self.directory)

    def test_wrong_workgroup_partial_outputs_overlap_and_abi_are_rejected(self):
        original = copy.deepcopy(self.manifest)
        mutations = (
            lambda c: c.update(block=[32, 1, 1]),
            lambda c: c.update(grid=[2, 1, 1]),
            lambda c: c.update(workgroup=[1, 0, 0]),
            lambda c: c.update(expected_outputs=1),
            lambda c: c["arrays"][1].update(base_address=c["arrays"][0]["base_address"]),
            lambda c: c.update(params=["int:0"]),
            lambda c: c.update(params=["ptr:x"]),
            lambda c: c.update(params=["ptr:out", "ptr:x"]),
            lambda c: c["arrays"][0].update(length=63),
        )
        for index, mutate in enumerate(mutations):
            with self.subTest(mutation=index):
                self.manifest = copy.deepcopy(original)
                mutate(self.manifest["cases"][0])
                self.write_manifest()
                with self.assertRaises(ValueError):
                    RUNNER.validate_manifest(self.directory)

    def test_inherited_visibility_and_architecture_overrides_are_rejected(self):
        self.assertEqual({"HIP_VISIBLE_DEVICES": "1"}, RUNNER.device_environment(1, {}))
        for key in (
            "HIP_VISIBLE_DEVICES",
            "ROCR_VISIBLE_DEVICES",
            "CUDA_VISIBLE_DEVICES",
            "GPU_DEVICE_ORDINAL",
            "HSA_OVERRIDE_GFX_VERSION",
            "HSA_OVERRIDE_GFX_VERSION_0",
            "HSA_OVERRIDE_GFX_VERSION_1",
        ):
            for value in ("", "12.5.0"):
                with self.subTest(key=key, value=value):
                    with self.assertRaisesRegex(ValueError, "overrides"):
                        RUNNER.device_environment(1, {key: value})

    def test_stale_pass_is_replaced_when_manifest_preflight_or_ssh_fails(self):
        result = self.directory / "receipt.json"
        arguments = [
            str(SCRIPT),
            "--host",
            "unused.invalid",
            "--device",
            "1",
            "--revision",
            "a" * 40,
            "--fixture-directory",
            str(self.directory),
            "--result",
            str(result),
        ]
        for failure in ("manifest", "ssh"):
            with self.subTest(failure=failure):
                result.write_text(json.dumps({"status": "pass", "invocation_id": "stale"}))
                if failure == "manifest":
                    self.manifest["cases"] = []
                    self.write_manifest()
                else:
                    shutil.copyfile(
                        FIXTURES / "portable-cases.json", self.directory / "portable-cases.json"
                    )
                with (
                    mock.patch.object(sys, "argv", arguments),
                    mock.patch.object(RUNNER, "validate_revision"),
                    mock.patch.object(
                        RUNNER, "checked_run", side_effect=RuntimeError("SSH refused")
                    ) as commands,
                    contextlib.redirect_stderr(io.StringIO()),
                ):
                    self.assertEqual(1, RUNNER.main())
                receipt = json.loads(result.read_text())
                self.assertEqual("fail", receipt["status"])
                self.assertNotEqual("stale", receipt["invocation_id"])
                self.assertIn("timestamp_utc", receipt)
                self.assertIn("error", receipt)
                if failure == "ssh":
                    self.assertEqual("SSH refused", receipt["error"])
                    self.assertEqual("ssh", commands.call_args.args[0][0])
                else:
                    self.assertIn("all 20 portable cases", receipt["error"])
                    commands.assert_not_called()

    def test_nonzero_process_and_timeout_cannot_produce_success(self):
        records = []
        with self.assertRaisesRegex(RuntimeError, "exited 9"):
            RUNNER.checked_run(
                [sys.executable, "-c", "import sys; print('PASS'); sys.exit(9)"],
                timeout=5,
                records=records,
            )
        self.assertEqual(9, records[0]["exit_code"])
        self.assertIn("PASS", records[0]["stdout"])
        with mock.patch.object(
            subprocess, "run", side_effect=subprocess.TimeoutExpired(["probe"], 1)
        ):
            with self.assertRaisesRegex(RuntimeError, "timed out"):
                RUNNER.checked_run(["probe"], timeout=1, records=records)
        self.assertEqual("timeout", records[1]["status"])

    def complete_result(self):
        rows = []
        for case in self.manifest["cases"]:
            arrays = case["arrays"]
            low = min(a["base_address"] for a in arrays)
            high = max(a["base_address"] + 4 * a["length"] for a in arrays)
            exact = {
                "portable_relu",
                "portable_reduction",
                "portable_matvec",
                "portable_gemm",
                "portable_bitdelta",
                "portable_bitdelta_batched",
                "portable_convolution",
            }
            atol, rtol = (
                (0, 0)
                if case["kernel"] in exact
                else (2e-7, 2e-6)
                if case["kernel"] == "portable_rope"
                else (2e-6, 2e-5)
            )
            rows.append(
                dict(
                    kernel=case["kernel"],
                    launches=1,
                    outputs=case["expected_outputs"],
                    atol=atol,
                    rtol=rtol,
                    max_absolute_error=0,
                    max_relative_error=0,
                    unchanged_input_bytes=sum(
                        4 * a["length"] for a in arrays if a["kind"] != "out"
                    ),
                    unchanged_gap_bytes=high - low - sum(4 * a["length"] for a in arrays),
                    unchanged_guard_bytes=8192,
                )
            )
        keys = (
            "launches",
            "outputs",
            "unchanged_input_bytes",
            "unchanged_gap_bytes",
            "unchanged_guard_bytes",
        )
        return dict(
            status="pass",
            patterns=1,
            reference_closed_form_checks=590,
            signed_alternation_checks=3,
            input_pattern_checks=sum(
                a["length"]
                for c in self.manifest["cases"]
                for a in c["arrays"]
                if a["kind"] == "in"
            ),
            device=dict(architecture="gfx1250:xnack+", wave_size=32),
            cases=rows,
            totals={key: sum(row[key] for row in rows) for key in keys},
        )

    def test_all_output_and_unchanged_byte_counts_are_mandatory(self):
        cases = RUNNER.validate_manifest(self.directory)
        result = self.complete_result()
        RUNNER.validate_driver_result(result, cases, 1)
        for key in (
            "launches",
            "outputs",
            "unchanged_input_bytes",
            "unchanged_gap_bytes",
            "unchanged_guard_bytes",
        ):
            with self.subTest(omitted_property=key):
                mutation = copy.deepcopy(result)
                mutation["cases"][0][key] -= 1
                with self.assertRaisesRegex(ValueError, "incomplete"):
                    RUNNER.validate_driver_result(mutation, cases, 1)

    def test_missing_cases_unknown_status_and_other_hardware_cannot_pass(self):
        cases = RUNNER.validate_manifest(self.directory)
        result = self.complete_result()
        mutations = (
            lambda r: r.update(cases=r["cases"][:-1]),
            lambda r: r.update(status="unknown"),
            lambda r: r.update(reference_closed_form_checks=589),
            lambda r: r.update(input_pattern_checks=0),
            lambda r: r.update(signed_alternation_checks=0),
            lambda r: r["cases"][0].update(atol=1),
            lambda r: r["cases"][0].update(max_absolute_error=float("nan")),
            lambda r: r["device"].update(architecture="gfx950"),
            lambda r: r["device"].update(wave_size=64),
        )
        for index, mutate in enumerate(mutations):
            with self.subTest(mutation=index):
                mutation = copy.deepcopy(result)
                mutate(mutation)
                with self.assertRaises(ValueError):
                    RUNNER.validate_driver_result(mutation, cases, 1)


if __name__ == "__main__":
    unittest.main()
