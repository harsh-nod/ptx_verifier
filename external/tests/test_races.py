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
        (self.root / "tile.copy.s").write_text('.amdgcn_target "amdgcn-amd-amdhsa--gfx950"\n.text\nk:\ns_endpgm\n')

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
        for target in ("AMD", "gfx942", "gfx950", "gfx1250"):
            result, _ = self.check(stderr=f"error: test.s: 22:2: unsupported {target} instruction `v_mad_i64_i32`", code=1)
            self.assertIs(result.outcome, RUNNER.Outcome.UNSUPPORTED)
        result, _ = self.check(stderr="error: invalid AMD configuration: byte payload size mismatch", code=1)
        self.assertIs(result.outcome, RUNNER.Outcome.ERROR)
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
        (root / "level_01.ptx").write_text('.version 8.0\n.target sm_100a\n')
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

    def test_explicit_native_targets_are_forwarded_without_relabeling(self):
        for target in ("gfx942", "gfx1250"):
            (self.root / "tile.copy.s").write_text(f'.amdgcn_target "amdgcn-amd-amdhsa--{target}"\n')
            done = subprocess.CompletedProcess([], 0, "  output 'out': 256 element(s) written\nGRAPH VERIFICATION: VERIFIED\n", "")
            with patch.object(RUNNER.subprocess, "run", return_value=done) as call:
                result = RUNNER.check(self.launch, self.root, 5, target=target)
            self.assertIs(result.outcome, RUNNER.Outcome.RACE_FREE)
            command = call.call_args.args[0]
            self.assertEqual(command[command.index("--target") + 1], target)
        with patch.object(RUNNER.subprocess, "run") as call:
            mismatch = RUNNER.check(self.launch, self.root, 5, target="gfx950")
        self.assertIs(mismatch.outcome, RUNNER.Outcome.ERROR)
        self.assertIn("source target differs", mismatch.detail)
        call.assert_not_called()

    def test_full_aggregate_count_cannot_hide_a_missing_output_array(self):
        self.launch.write_text(json.dumps({"arrays": [{"name": "a", "kind": "out", "len": 128},
                                                       {"name": "b", "kind": "out", "len": 128}]}))
        for stdout in ["  output 'a': 256 element(s) written\n", "  output 'a': 128 element(s) written\n" * 2]:
            result, _ = self.check(stdout + "GRAPH VERIFICATION: VERIFIED\n")
            self.assertIs(result.outcome, RUNNER.Outcome.CHECK_FAILED)

    def test_missing_source_unknown_and_invalid_launch_are_not_successes(self):
        result, _ = self.check("GRAPH VERIFICATION: UNKNOWN\n")
        self.assertIs(result.outcome, RUNNER.Outcome.UNKNOWN)
        self.launch.write_text('{"arrays":[{"name":"out","kind":"out","shape":[true,256]}]}')
        with patch.object(RUNNER.subprocess, "run") as call:
            self.assertIs(RUNNER.check(self.launch, self.root, 5).outcome, RUNNER.Outcome.ERROR)
        call.assert_not_called()
        self.launch.write_text('{"arrays":[]}')
        (self.root / "tile.copy.s").unlink()
        with patch.object(RUNNER.subprocess, "run") as call:
            self.assertIs(RUNNER.check(self.launch, self.root, 5).outcome, RUNNER.Outcome.ERROR)
        call.assert_not_called()


if __name__ == "__main__":
    unittest.main()
