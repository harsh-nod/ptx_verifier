"""Original host-shape, physical-output, ABI and refusal controls; no GPU."""
import copy
import importlib.util
import json
import re
import struct
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "external/extraction"))
SPEC = importlib.util.spec_from_file_location("hipkittens_complex", ROOT / "external/extraction/hipkittens_complex.py")
COMPLEX = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COMPLEX)


def kernel(name):
    profile = COMPLEX.PROFILES[name]
    size = profile["globals_bytes"]
    return {".name": profile["symbol"], ".wavefront_size": profile["wave"],
            ".max_flat_workgroup_size": profile["block"], ".group_segment_fixed_size": 0,
            ".private_segment_fixed_size": 0,
            ".args": [{".offset": 0, ".size": size, ".value_kind": "by_value"}]
            + [{".offset": size + 4 * i, ".size": 4, ".value_kind": "by_value"} for i in range(3)]}


class ComplexContractTests(unittest.TestCase):
    def test_exact_original_host_shapes_keep_all_large_and_nonsquare_cases(self):
        self.assertEqual(COMPLEX.PROFILES["gfx1250-gemm00"]["shapes"],
                         ((8192, 8192, 8192), (4096, 8192, 2048), (8192, 4096, 2048), (2048, 1024, 1024)))
        self.assertEqual(len(COMPLEX.make_cases("gfx950-bf16-gemm")), 7)
        self.assertEqual({tuple(case["shape"]) for case in COMPLEX.make_cases("gfx950-bf16-gemm")},
                         {(8192, 8192, 8192), (4096, 8192, 2048), (8192, 4096, 2048),
                          (8192, 2048, 4096), (512, 1024, 1024), (512, 1024, 2048), (2048, 1024, 512)})
        self.assertEqual(COMPLEX.literal_shapes("SHAPES = [(2048,1024,1024)] # no module execution\n", "SHAPES"),
                         ((2048, 1024, 1024),))
        for text in ["SHAPES=[]\nSHAPES=[]", "other=[]", "SHAPES=arbitrary()"]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                COMPLEX.literal_shapes(text, "SHAPES")

    def test_full_original_allocations_and_packed_byvalue_fields(self):
        for name, profile in COMPLEX.PROFILES.items():
            for case in COMPLEX.make_cases(name):
                with self.subTest(case=case["id"]):
                    config = COMPLEX.launch(case)
                    m, n, k = case["shape"]
                    self.assertEqual(config["arrays"][0]["shape"], [m, k])
                    self.assertEqual(config["arrays"][1]["shape"], [n, k])
                    self.assertEqual(case["original_allocations"]["C"],
                                     {"base": COMPLEX.BASES["C"], "shape": [m, n], "bytes": 2 * m * n})
                    payload = bytes(config["params"][0]["bytes"])
                    self.assertEqual(len(payload), profile["globals_bytes"])
                    for i, (array, rows, cols) in enumerate((("A", m, k), ("B", n, k), ("C", m, n))):
                        offset = i * profile["descriptor_bytes"]
                        self.assertEqual(struct.unpack_from("<5Q", payload, offset),
                                         (COMPLEX.BASES[array], 1, 1, rows, cols))
                        if name == "gfx950-bf16-gemm":
                            self.assertEqual(payload[offset + 40:offset + 48], bytes(8))
                    self.assertEqual(config["params"][1:], [{"int": m}, {"int": n}, {"int": k}])
                    if name == "gfx950-bf16-gemm":
                        self.assertEqual(payload[144:152], bytes(8))
                        self.assertEqual(struct.unpack_from("<3i", payload, 152), (m, n, k))
                        self.assertEqual(config["grid"], [(m // 256) * (n // 256), 1, 1])
                        self.assertEqual((config["block"], config["dynamic_shared_bytes"]), ([512, 1, 1], 160000))
                    else:
                        self.assertEqual(config["grid"], [m // 64, n // 64, 1])
                        self.assertEqual((config["block"], config["dynamic_shared_bytes"]), ([128, 1, 1], 8704))

    def test_sparse_output_views_preserve_each_original_absolute_element(self):
        for name in COMPLEX.PROFILES:
            case = COMPLEX.make_cases(name)[-1]
            config = COMPLEX.launch(case)
            m, n, _ = case["shape"]
            outputs = [array for array in config["arrays"] if array["kind"] == "out"]
            actual = {array["base"] + 2 * i for array in outputs for i in range(array["shape"][0])}
            tile = 64 if name == "gfx1250-gemm00" else 256
            expected = {COMPLEX.BASES["C"] + 2 * (col * m + row if tile == 64 else row * n + col)
                        for row in range(tile) for col in range(tile)}
            self.assertEqual(actual, expected)
            self.assertEqual(len(actual), case["required_output_elements"])
            self.assertLess(max(actual), COMPLEX.BASES["C"] + 2 * m * n)
            self.assertGreater(max(actual), COMPLEX.BASES["C"] + 2 * tile * tile)

    def test_missing_shifted_compacted_aliased_or_wrong_dtype_views_refused(self):
        case = COMPLEX.make_cases("gfx1250-gemm00")[-1]
        original = COMPLEX.launch(case)
        mutations = [lambda c: c["arrays"].pop(),
                     lambda c: c["arrays"][3].update(base=c["arrays"][2]["base"] + 128),
                     lambda c: c["arrays"][2].update(shape=[63]),
                     lambda c: c["arrays"][2].update(name="C1"),
                     lambda c: c["arrays"][0].update(shape=[64, 1024]),
                     lambda c: c["arrays"][0].update(dtype="f16")]
        for mutate in mutations:
            changed = copy.deepcopy(original)
            mutate(changed)
            with self.assertRaises(ValueError):
                COMPLEX.validate_views(changed, case)

    def test_reduced_shapes_or_different_group_are_not_original_cases(self):
        original = COMPLEX.make_cases("gfx1250-gemm00")[-1]
        for change in ({"shape": [64, 64, 32]}, {"workgroup_id": [1, 0, 0]},
                       {"profile": "gfx1250-cluster"}, {"required_output_elements": 64}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                COMPLEX.launch({**original, **change})

    def test_complete_math_has_correct_orientation_for_both_physical_layouts(self):
        for name in COMPLEX.PROFILES:
            profile = COMPLEX.PROFILES[name]
            spec = COMPLEX.specification(name)
            self.assertIn("array A[M, K]; array B[N, K];", spec)
            equations = re.findall(r"C(\d+)\[i\] = sum\(k in 0\.\.K, A\[(i|\d+), k\] \* B\[(i|\d+), k\]\);", spec)
            self.assertEqual(len(equations), profile["tile"])
            self.assertEqual({int(index) for index, _, _ in equations}, set(range(profile["tile"])))
            # Independent nonsymmetric integer valuation distinguishes AB^T
            # from transposed/row-swapped output, without relying on a verdict.
            for column_or_row, a_row, b_row in equations[:3]:
                i = 7
                row, col = ((i, int(column_or_row)) if profile["layout"] == "column-major" else (int(column_or_row), i))
                ar = i if a_row == "i" else int(a_row)
                br = i if b_row == "i" else int(b_row)
                expected = sum((2 * row + k) * (3 * col - k) for k in range(11))
                actual = sum((2 * ar + k) * (3 * br - k) for k in range(11))
                self.assertEqual(actual, expected)
            wrong = COMPLEX.specification(name, wrong=True)
            self.assertNotEqual(spec, wrong)
            self.assertEqual(wrong.count(") + 1;"), 1)

    def test_entrypoint_abi_and_resource_drift_refused(self):
        for name in COMPLEX.PROFILES:
            original = kernel(name)
            COMPLEX.validate_metadata([original], name)
            for rows in ([], [original, original]):
                with self.assertRaisesRegex(ValueError, "missing or duplicate"):
                    COMPLEX.validate_metadata(rows, name)
            for mutate in [lambda k: k.update({".wavefront_size": 16}),
                           lambda k: k.update({".private_segment_fixed_size": 8}),
                           lambda k: k.update({".max_flat_workgroup_size": 32}),
                           lambda k: k[".args"][1].update({".offset": 8}),
                           lambda k: k[".args"][0].update({".size": 16}),
                           lambda k: k[".args"][0].update({".value_kind": "global_buffer"})]:
                changed = copy.deepcopy(original)
                mutate(changed)
                with self.assertRaises(ValueError):
                    COMPLEX.validate_metadata([changed], name)

    def test_whole_module_parse_refusal_cannot_become_math_or_graph_proof(self):
        rejected = {"status": "rejected", "returncode": 1}
        self.assertEqual(COMPLEX.classify(rejected, "", "error: original.s: 294:2: expects 4 operands, got 5", 4096, rejected),
                         "parse_rejected")
        checks = "\n".join(f"  {name} (target algorithm) PASS" for name in sorted(COMPLEX.corpus.NATIVE_PROPERTIES))
        stdout = checks + "\nVC check: 0.1s  elements: 4096\nEQUIVALENT (matches spec)\nVERDICT: ACCEPT\n"
        with self.assertRaisesRegex(ValueError, "contradicts"):
            COMPLEX.classify({"status": "succeeded", "returncode": 0}, stdout, "", 4096, rejected)
        # Neither no result nor a parser refusal passes the wrong-equation gate.
        with self.assertRaisesRegex(ValueError, "complete verification"):
            COMPLEX.classify({"status": "succeeded", "returncode": 0}, "", "", 4096, {"status": "succeeded"})

    def test_commands_bind_all_full_dimensions_and_disable_sampling(self):
        case = COMPLEX.make_cases("gfx1250-gemm00")[-1]
        command = COMPLEX.verification_command(Path("volta"), Path("original.s"), Path("gemm.spec"), Path("launch.json"), case)
        self.assertEqual([command[i + 1] for i, arg in enumerate(command) if arg == "--dim"],
                         ["M=2048", "N=1024", "K=1024"])
        self.assertEqual(command[command.index("--sample") + 1], "0")
        self.assertEqual(command[command.index("--target") + 1], "gfx1250")
        self.assertNotIn("--early-memory-conflicts", command)

    def test_stale_module_artifacts_and_generated_inputs_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "kernel.s"
            config = root / "launch.json"
            source.write_bytes(b"complete original module")
            config.write_bytes(b"original launch")
            hashes = {"assembly": COMPLEX.inventory.sha(source.read_bytes())}
            generated = {config: config.read_bytes()}
            COMPLEX.require_stable({"assembly": source}, hashes, generated)
            source.write_bytes(b"changed module")
            with self.assertRaisesRegex(ValueError, "run input changed"):
                COMPLEX.require_stable({"assembly": source}, hashes, generated)
            source.write_bytes(b"complete original module")
            config.write_bytes(b"reduced launch")
            with self.assertRaisesRegex(ValueError, "generated contract input changed"):
                COMPLEX.require_stable({"assembly": source}, hashes, generated)

    def test_checked_in_contract_retains_every_output_and_no_proof_state(self):
        document = json.loads(COMPLEX.DEFAULT_CONTRACT.read_text())
        cases = [case for profile in document["profiles"].values() for case in profile["cases"]]
        self.assertEqual(len(cases), 11)
        self.assertEqual(len({case["id"] for case in cases}), 11)
        self.assertEqual({case["profile"]: case["required_output_elements"] for case in cases},
                         {"gfx1250-gemm00": 4096, "gfx950-bf16-gemm": 65536})
        self.assertNotIn("all_original_cases_verified", document)
        self.assertIn("not a full-matrix", document["output_allocation_limit"])


if __name__ == "__main__":
    unittest.main()
