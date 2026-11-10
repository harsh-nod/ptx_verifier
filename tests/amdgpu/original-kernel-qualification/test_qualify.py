"""Refuse smaller problems, substituted outputs and incomplete successful-looking runs."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("original_qualification", HERE / "qualify.py")
QUALIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(QUALIFY)


class ContractTests(unittest.TestCase):
    def test_real_contract_retains_four_full_computations(self):
        _, cases = QUALIFY.load_manifest()
        self.assertEqual({case["id"]: case["expected_outputs"] for case, _, _ in cases}, {
            "gfx942-relu_f16": 1024, "gfx942-silu_f16": 512,
            "gfx942-rope_f16": 128, "gfx1250-sinkhorn_original": 32,
        })
        for case, _, outputs in cases:
            self.assertEqual(sum(map(len, outputs.values())), case["expected_outputs"])

    def test_rehashed_manifest_cannot_lower_reference_output_count(self):
        document = json.loads(QUALIFY.MANIFEST.read_text())
        document["cases"][0]["expected_outputs"] -= 1
        with tempfile.TemporaryDirectory() as name:
            path = Path(name) / "manifest.json"
            path.write_text(json.dumps(document))
            with self.assertRaisesRegex(ValueError, "original output count"):
                QUALIFY.load_manifest(path)

    def test_changed_assembly_and_original_registry_pins_fail(self):
        for field in ("assembly_sha256", "reference_registry_sha256"):
            document = json.loads(QUALIFY.MANIFEST.read_text())
            target = document if field.startswith("reference") else document["cases"][0]
            target[field] = "0" * 64
            with tempfile.TemporaryDirectory() as name:
                path = Path(name) / "manifest.json"
                path.write_text(json.dumps(document))
                with self.assertRaises(ValueError):
                    QUALIFY.load_manifest(path)

    def test_smaller_launch_storage_or_changed_null_abi_never_becomes_original(self):
        _, cases = QUALIFY.load_manifest()
        case, original, _ = cases[-1]
        expected = json.loads((QUALIFY.ROOT / "tests/gfx1250/full" / original["launch_config"]).read_text())
        actual = json.loads((QUALIFY.ROOT / case["launch_config"]).read_text())
        for field in ("block", "grid", "length", "width", "null", "count"):
            changed = copy.deepcopy(actual)
            if field in ("block", "grid"):
                changed[field][0] += 1
            elif field == "length":
                changed["arrays"][1]["len"] //= 2
            elif field == "width":
                changed["arrays"][0]["elem_width"] = 4
            elif field == "null":
                changed["params"][4]["int"] = 8
            else:
                changed["arrays"].pop()
            with self.subTest(field=field), self.assertRaises(ValueError):
                QUALIFY.validate_launch(case, changed, expected)

    def test_low_unaligned_and_overlapping_relocations_fail(self):
        _, cases = QUALIFY.load_manifest()
        case, original, _ = cases[-1]
        expected = json.loads((QUALIFY.ROOT / "tests/gfx1250/full" / original["launch_config"]).read_text())
        actual = json.loads((QUALIFY.ROOT / case["launch_config"]).read_text())
        for base in (0xffff0000, 0x100000001, actual["arrays"][1]["base"]):
            changed = copy.deepcopy(actual)
            changed["arrays"][0]["base"] = base
            with self.subTest(base=base), self.assertRaises(ValueError):
                QUALIFY.validate_launch(case, changed, expected)


class AcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.result = {"exit_code": 0, "termination": None}
        self.stdout = "\n".join(
            f"  {name} (native contract) PASS" for name in QUALIFY.PROOF.RUNTIME.PROPERTIES
        ) + "\n  output 'out': 2 element(s) written\nGRAPH VERIFICATION: VERIFIED\n"
        self.expressions = 'volta-expr 1\nout "out" 0 n0\nout "out" 1 n1\n'
        self.expected = {"out": [0, 1]}

    def check(self, result=None, stdout=None, expressions=None):
        QUALIFY.validate_analysis(result or self.result, self.stdout if stdout is None else stdout,
                                  self.expressions if expressions is None else expressions, self.expected)

    def test_control_is_complete(self):
        self.check()

    def test_printed_pass_cannot_hide_nonzero_exit_or_resource_limit(self):
        for result in ({"exit_code": 1, "termination": None},
                       {"exit_code": 0, "termination": "wall_timeout"},
                       {"exit_code": -9, "termination": "rss_limit"}):
            with self.subTest(result=result), self.assertRaises(ValueError):
                self.check(result=result)

    def test_graph_prefix_unknown_failed_or_missing_properties_fail(self):
        for stdout in (self.stdout.replace("VERIFIED", "UNKNOWN"),
                       self.stdout.replace(" PASS", " FAIL", 1),
                       "\n".join(self.stdout.splitlines()[1:])):
            with self.subTest(stdout=stdout), self.assertRaises(ValueError):
                self.check(stdout=stdout)

    def test_same_count_shifted_or_substituted_coordinates_fail(self):
        for text in (self.expressions.replace('"out"', '"other"'),
                     self.expressions.replace(' 0 n0', ' 2 n0'),
                     self.expressions.replace(' 1 n1', ' 0 n1'),
                     self.expressions.replace('out "out" 1 n1\n', '')):
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.check(expressions=text)

    def test_total_count_cannot_substitute_an_output_array(self):
        with self.assertRaises(ValueError):
            self.check(stdout=self.stdout.replace("output 'out'", "output 'other'"))


if __name__ == "__main__":
    unittest.main()
