"""External runners must preserve backend selection, output coverage and failures."""
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

EXTERNAL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("volta_external_races", EXTERNAL / "races.py")
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


class ExternalRaceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name) / "hipkittens"
        self.root.mkdir()
        self.launch = self.root / "tile.copy.wg0.launch.json"
        self.launch.write_text(json.dumps({"arrays": [{"name": "out", "kind": "out", "shape": [16, 16]}]}))

    def tearDown(self):
        self.temporary.cleanup()

    def check(self, stdout="", stderr="", code=0):
        done = subprocess.CompletedProcess([], code, stdout, stderr)
        with patch.object(RUNNER.subprocess, "run", return_value=done) as run:
            result = RUNNER.check(self.launch, self.root, 5, Path("/test/volta"))
        return result, run.call_args.args[0]

    def test_native_backend_and_exact_multidot_source_are_selected(self):
        result, command = self.check("  output 'out': 256 element(s) written\nGRAPH VERIFICATION: VERIFIED\n")
        self.assertIs(result.outcome, RUNNER.Outcome.RACE_FREE)
        self.assertIn(str(self.root / "tile.copy.s"), command)
        self.assertEqual(command[command.index("--backend") + 1], "amdgpu")
        self.assertEqual(command[command.index("--target") + 1], "gfx950")

    def test_declared_coverage_cannot_be_replaced_by_actual_written_count(self):
        result, _ = self.check("  output 'out': 1 element(s) written\nGRAPH VERIFICATION: VERIFIED\n")
        self.assertIs(result.outcome, RUNNER.Outcome.CHECK_FAILED)
        self.assertIn("1/256", result.detail)

    def test_native_unsupported_and_signal_exit_are_distinct(self):
        result, _ = self.check(stderr="error: test.s: 22:2: unsupported gfx950 instruction `v_mad_i64_i32`", code=1)
        self.assertIs(result.outcome, RUNNER.Outcome.UNSUPPORTED)
        result, _ = self.check("GRAPH VERIFICATION: VERIFIED\n", code=-9)
        self.assertIs(result.outcome, RUNNER.Outcome.ERROR)

    def test_success_report_does_not_hide_nonzero_exit(self):
        result, _ = self.check("  output 'out': 256 element(s) written\nGRAPH VERIFICATION: VERIFIED\n", code=1)
        self.assertIs(result.outcome, RUNNER.Outcome.ERROR)

    def test_timeout_and_missing_executable_are_inconclusive_or_error(self):
        for error, outcome in [(subprocess.TimeoutExpired("volta", 5), RUNNER.Outcome.UNKNOWN),
                               (FileNotFoundError("volta"), RUNNER.Outcome.ERROR)]:
            with patch.object(RUNNER.subprocess, "run", side_effect=error):
                result = RUNNER.check(self.launch, self.root, 5)
            self.assertIs(result.outcome, outcome)

    def test_ptx_framework_keeps_ptx_backend(self):
        root = self.root.with_name("thunderkittens")
        root.mkdir()
        launch = root / "level_01.n20.launch.json"
        launch.write_bytes(self.launch.read_bytes())
        done = subprocess.CompletedProcess([], 0, "  output 'out': 256 element(s) written\nGRAPH VERIFICATION: VERIFIED\n", "")
        with patch.object(RUNNER.subprocess, "run", return_value=done) as run:
            self.assertIs(RUNNER.check(launch, root, 5).outcome, RUNNER.Outcome.RACE_FREE)
        self.assertIn(str(root / "level_01.ptx"), run.call_args.args[0])
        self.assertNotIn("--backend", run.call_args.args[0])

    def test_strict_mode_rejects_inconclusive_and_empty_selections(self):
        for launch_paths, outcome in [([self.launch], RUNNER.Outcome.UNSUPPORTED), ([], RUNNER.Outcome.RACE_FREE)]:
            run = RUNNER.Run("control", outcome, 0, "test")
            with patch.object(RUNNER, "EXTERNAL_ROOT", self.root.parent), \
                 patch.object(RUNNER, "OUTPUT_DIR", self.root.parent / "output"), \
                 patch.object(RUNNER.Path, "rglob", return_value=iter(launch_paths)), \
                 patch.object(RUNNER, "check", return_value=run):
                self.assertTrue(RUNNER.check_framework("hipkittens", "", 5, RUNNER.Style(False), strict=True))


if __name__ == "__main__":
    unittest.main()
