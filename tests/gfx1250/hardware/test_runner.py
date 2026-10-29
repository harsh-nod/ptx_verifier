"""CPU-only failure-provenance tests; these never initialize HIP or run a kernel."""

from contextlib import redirect_stderr, redirect_stdout
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("gfx1250_core_runner", HERE / "run.py")
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)
COMMIT = "821d0ebea7448f7e6cf81d36517b6d48cb3b2094"


class RunnerFailures(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.receipt = self.root / "receipt.json"
        self.receipt.write_text('{"status":"PASS","old_result":true}\n')
        self.base_arguments = [
            str(HERE / "run.py"),
            "--receipt",
            str(self.receipt),
            "--source-commit",
            COMMIT,
        ]
        self.environment = patch.dict(os.environ, {}, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def invoke(self, arguments=None):
        with (
            patch.object(sys, "argv", arguments or self.base_arguments),
            redirect_stderr(io.StringIO()),
            redirect_stdout(io.StringIO()),
        ):
            return runner.main()

    def failed_receipt(self):
        receipt = json.loads(self.receipt.read_text())
        self.assertEqual(receipt["status"], "INCOMPLETE")
        self.assertNotIn("old_result", receipt)
        self.assertIn("finished_utc", receipt)
        self.assertIn("error", receipt)
        return receipt

    def copied_fixture_tree(self):
        hardware = self.root / "gfx1250/hardware"
        hardware.mkdir(parents=True)
        shutil.copy(HERE / "core.cpp", hardware / "core.cpp")
        shutil.copy(HERE.parent / "cases.json", hardware.parent / "cases.json")
        (hardware.parent / "fixtures").mkdir()
        for unit in runner.UNITS:
            shutil.copy(
                HERE.parent / "fixtures" / (unit + ".s"),
                hardware.parent / "fixtures" / (unit + ".s"),
            )
        return hardware

    def fake_toolchain(self):
        rocm, build = self.root / "rocm", self.root / "build"
        for relative in (
            "llvm/bin/clang++",
            "llvm/bin/llvm-mc",
            "llvm/bin/ld.lld",
            "lib/libamdhip64.so",
        ):
            path = rocm / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("never executed dummy tool\n")
        build.mkdir()
        (build / "core").write_text("never executed dummy host driver\n")
        self.base_arguments += ["--rocm", str(rocm), "--build-dir", str(build)]
        return rocm, build

    def test_invalid_source_commit_replaces_stale_pass(self):
        with self.assertRaises(SystemExit):
            self.invoke([*self.base_arguments[:-1], "invalid"])
        self.failed_receipt()

    def test_changed_assembly_replaces_stale_pass(self):
        hardware = self.copied_fixture_tree()
        assembly = hardware.parent / "fixtures/native-copy-add.s"
        assembly.write_text(
            assembly.read_text() + "\n// deliberately altered host-test input\n"
        )
        with patch.object(runner, "HERE", hardware), self.assertRaises(SystemExit):
            self.invoke()
        self.failed_receipt()

    def test_timeout_preserves_command_and_partial_output(self):
        hardware = self.copied_fixture_tree()
        self.fake_toolchain()
        error = subprocess.TimeoutExpired(
            ["fake-compiler"], 120, output=b"partial stdout", stderr=b"partial stderr"
        )
        with (
            patch.object(runner, "HERE", hardware),
            patch.object(runner.subprocess, "run", side_effect=error),
            self.assertRaises(subprocess.TimeoutExpired),
        ):
            self.invoke()
        command = self.failed_receipt()["commands"][-1]
        self.assertTrue(command["timed_out"])
        self.assertEqual(command["stdout"], "partial stdout")
        self.assertEqual(command["stderr"], "partial stderr")
        self.assertEqual(command["timeout_seconds"], 120)
        self.assertIn("clang++", command["argv"][0])

    def test_different_loaded_runtime_stops_before_any_kernel(self):
        hardware = self.copied_fixture_tree()
        self.fake_toolchain()
        other_runtime = self.root / "other/libamdhip64.so"
        other_runtime.parent.mkdir()
        other_runtime.write_text("wrong runtime\n")

        def fake_process(command, **kwargs):
            output = (
                f"libamdhip64.so.7 => {other_runtime} (0x1234)\n"
                if command[0] == "ldd"
                else "fake tool version\n"
            )
            return subprocess.CompletedProcess(command, 0, output, "")

        with (
            patch.object(runner, "HERE", hardware),
            patch.object(runner.subprocess, "run", side_effect=fake_process),
            self.assertRaisesRegex(RuntimeError, "HIP runtime mismatch"),
        ):
            self.invoke()
        receipt = self.failed_receipt()
        self.assertEqual(receipt["suites"], [])
        self.assertEqual(receipt["commands"][-1]["argv"][0], "ldd")

    def test_architecture_overrides_normal_empty_and_per_node_stop_early(self):
        for name, value in [
            ("HSA_OVERRIDE_GFX_VERSION", "12.5.0"),
            ("HSA_OVERRIDE_GFX_VERSION", ""),
            ("HSA_OVERRIDE_GFX_VERSION_0", "12.5.0"),
        ]:
            with (
                self.subTest(name=name, value=value),
                patch.dict(os.environ, {name: value}),
                self.assertRaises(SystemExit),
            ):
                self.invoke()
            self.assertEqual(self.failed_receipt()["commands"], [])

    def test_conflicting_ordinal_stops_early(self):
        with (
            patch.dict(os.environ, {"GPU_DEVICE_ORDINAL": "1"}),
            self.assertRaises(SystemExit),
        ):
            self.invoke()
        self.assertEqual(self.failed_receipt()["commands"], [])

    def test_linkage_requires_one_absolute_runtime(self):
        for linkage in (
            "libamdhip64.so.7 => not found\n",
            "",
            "libamdhip64.so.7 => /one (0x1)\nlibamdhip64.so.7 => /two (0x2)\n",
        ):
            with self.subTest(linkage=linkage), self.assertRaises(RuntimeError):
                runner.loaded_hip_runtime(linkage)


if __name__ == "__main__":
    unittest.main()
