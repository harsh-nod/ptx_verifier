"""Native adapters preserve target, ABI, mutation scope and failure accounting."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("volta_native_workload_adapter", ROOT / "ai_compiler_kernels/check_races.py")
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


class NativeAdapterTests(unittest.TestCase):
    def test_explicit_native_targets_load_genuine_cases_and_preserve_byte_configs(self):
        for target in ("gfx942", "gfx1250"):
            families = RUNNER.load_amdgpu_variants(target)
            variants = [v for group in families.values() for v in group]
            self.assertTrue(variants)
            for v in variants:
                self.assertEqual(v.target, target)
                self.assertEqual(RUNNER.native_target_of(v.path.read_text()), target)
                args = RUNNER.launch_args(v, v.path.read_text())
                self.assertEqual(args[args.index("--target") + 1], target)
                if v.launch_config:
                    self.assertIn("--config", args)
                    config = json.loads(v.launch_config.read_text())
                    self.assertTrue(any("bytes" in p for p in config["params"]))
                    self.assertNotIn("--param", args)
        self.assertEqual(RUNNER.load_amdgpu_variants()["copy"][0].target, "gfx950")

    def test_target_markers_must_be_present_and_consistent(self):
        for source in [".text\nk:\ns_endpgm\n", '.amdgcn_target "amdgcn-amd-amdhsa--gfx950"\namdhsa.target: amdgcn-amd-amdhsa--gfx1250\n']:
            with self.assertRaises(ValueError):
                RUNNER.native_target_of(source)
        v = RUNNER.load_amdgpu_variants("gfx1250")["copy"][0]
        with self.assertRaisesRegex(ValueError, "source target differs"):
            RUNNER.launch_args(v, '.amdgcn_target "amdgcn-amd-amdhsa--gfx950"\n')

    def test_native_manifest_does_not_silently_drop_operational_launch_fields(self):
        row = json.loads((ROOT / "tests/gfx1250/cases.json").read_text())["cases"][0]
        row["assembly"] = str(ROOT / "tests/gfx1250" / row["assembly"])
        row.pop("spec", None)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "cases.json"
            for field, value in [("workgroup", [1, 0, 0]), ("max_instructions", 1),
                                 ("shared_allocations", [{"offset": 0, "size": 16}]),
                                 ("params", [{"bytes": [0] * 8}])]:
                path.write_text(json.dumps({"schema_version": 1, "target": "gfx1250", "cases": [dict(row, **{field: value})]}))
                with self.assertRaises(ValueError):
                    RUNNER.load_native_case_variants(path, "gfx1250")
            path.write_text(json.dumps({"schema_version": 1, "target": "gfx1250", "cases": [dict(row, global_values=[["gain", 7]])]}))
            variant = RUNNER.load_native_case_variants(path, "gfx1250")["copy"][0]
            args = RUNNER.launch_args(variant, variant.path.read_text())
            self.assertIn("gain=7", args)

    def test_new_native_wait_and_split_barrier_sites_keep_original_spans(self):
        path = ROOT / "tests/gfx1250/fixtures/native-copy-add.s"
        source = path.read_text()
        sites = RUNNER.mutation_sites(source, "amdgpu", "copy")
        self.assertTrue({"s_wait_kmcnt", "s_wait_loadcnt"}.issubset({s.instr for s in sites}))
        for site in sites:
            mutant = RUNNER.remove_statement(source, site, "amdgpu", "copy")
            self.assertEqual(len(mutant), len(source))
            self.assertEqual(mutant.count("\n"), source.count("\n"))
            self.assertEqual(mutant[source.index("\nadd:"):], source[source.index("\nadd:"):])
        tensor = (ROOT / "tests/gfx1250/fixtures/native-tensor-roundtrip.s").read_text()
        sites = RUNNER.mutation_sites(tensor, "amdgpu", "tensor_roundtrip")
        self.assertTrue({"s_wait_tensorcnt", "s_barrier_signal", "s_barrier_wait", "s_wait_dscnt"}.issubset({s.instr for s in sites}))
        self.assertEqual(sum(s.instr == "s_wait_tensorcnt" for s in sites), 4)

    def test_real_subprocess_signals_and_inconsistent_success_are_errors(self):
        scripts = [
            "import os,signal;print('GRAPH VERIFICATION: VERIFIED',flush=True);os.kill(os.getpid(),signal.SIGKILL)",
            "import sys;print('GRAPH VERIFICATION: VERIFIED');sys.exit(1)",
        ]
        for source in scripts:
            with self.assertRaises(RUNNER.VoltaFailure):
                RUNNER.run_volta([sys.executable, "-c", source, "analyze"], None)
        stdout, _ = RUNNER.run_volta([sys.executable, "-c", "import sys;print('GRAPH VERIFICATION: REJECTED');sys.exit(1)", "analyze"], None)
        self.assertIn("REJECTED", stdout)

    def test_inconclusive_mutants_and_missing_sites_cannot_satisfy_negative_run(self):
        variant = RUNNER.load_amdgpu_variants("gfx1250")["copy"][0]
        baseline = RUNNER.Report(variant, RUNNER.Outcome.RACE_FREE, "full control", 0)
        for outcome in (RUNNER.Outcome.UNSUPPORTED, RUNNER.Outcome.UNKNOWN, RUNNER.Outcome.ERROR):
            with patch.object(RUNNER, "check", return_value=baseline), \
                 patch.object(RUNNER, "analyze_variant", return_value=(outcome, "inconclusive")), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(RUNNER.run_mutations([("copy", variant)], True, None, RUNNER.Style(False), []), 1)
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(RUNNER.run_mutations([("copy", variant)], True, None, RUNNER.Style(False), [999999]), 1)
        with patch.object(RUNNER, "check", return_value=RUNNER.Report(variant, RUNNER.Outcome.UNSUPPORTED, "no baseline proof", 0)), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(RUNNER.run_mutations([("copy", variant)], True, None, RUNNER.Style(False), []), 1)

    def test_gfx1250_execution_and_parse_unsupported_are_preserved(self):
        for stdout, stderr in [
            ("  no outputs: execution stopped: unsupported gfx1250 instruction at pc7: test\nGRAPH VERIFICATION: UNKNOWN\n", ""),
            ("", "error: native.s:7:1: unsupported gfx1250 instruction `v_unknown`"),
        ]:
            self.assertIs(RUNNER.classify(RUNNER.parse_cli(stdout), stderr, 65)[0], RUNNER.Outcome.UNSUPPORTED)

    def test_legacy_cdna4_recipe_refuses_silent_retargeting(self):
        script = ROOT / "external/extraction/hipkittens.py"
        result = subprocess.run([sys.executable, str(script), "--target", "gfx1250"], text=True, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("UNSUPPORTED", result.stderr)
        self.assertIn("compile_fixtures.py", result.stderr)
        self.assertIn("must not be silently retargeted", result.stderr)
        self.assertIn("separate CDNA3 and CDNA5 sources", result.stderr)
        self.assertIn("hipkittens_inventory.py", result.stderr)
        self.assertNotIn("No module named", result.stderr)


if __name__ == "__main__":
    unittest.main()
