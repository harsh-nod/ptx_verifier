"""Refusal controls for original-shape registration, not kernel proof tests."""

import copy
import json
import unittest

import contract


class OriginalShapeContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = json.loads(contract.INVENTORY.read_text())
        cls.registry = json.loads(contract.REGISTRY.read_text())
        cls.rows = contract.validate_inventory(cls.inventory)

    def validate(self, registry, **options):
        return contract.validate_registry(
            registry, self.rows, contract.REGISTRY.parent, **options
        )

    def test_all_original_variants_dtypes_and_sparse_outputs_are_recorded(self):
        self.assertEqual(32, len(self.rows))
        self.assertEqual(
            395394, sum(r["original"]["expected_outputs"] for r in self.rows.values())
        )
        gemm = contract.output_indices(self.rows["W27"])["c"]
        self.assertEqual(65536, len(gemm))
        self.assertIn(255 * 4096 + 255, gemm)
        self.assertNotIn(256, gemm)
        self.assertNotIn(4095, gemm)
        scan = contract.output_indices(self.rows["W26"])
        self.assertEqual({"out", "out_x"}, set(scan))
        self.assertEqual(4096, len(scan["out"]))
        self.assertNotIn(128, scan["out"])  # untouched head/row gap

    def test_registrations_keep_exact_missing_rows_and_original_total(self):
        missing = self.validate(self.registry)
        expected = set(self.rows) - {c["baseline_id"] for c in self.registry["cases"]}
        self.assertEqual(sorted(expected), missing)
        self.assertEqual(
            sum(
                self.rows[c["baseline_id"]]["original"]["expected_outputs"]
                for c in self.registry["cases"]
            ),
            self.registry["registered_original_outputs"],
        )
        if missing:
            with self.assertRaisesRegex(ValueError, "incomplete"):
                self.validate(self.registry, require_all=True)
        else:
            self.assertEqual([], self.validate(self.registry, require_all=True))

    def test_empty_partial_duplicate_or_hidden_cases_cannot_satisfy_the_gate(self):
        for mutate in (
            lambda r: r.update(cases=[]),
            lambda r: r["cases"].pop(),
            lambda r: r["cases"].append(copy.deepcopy(r["cases"][0])),
            lambda r: r.update(required_baseline_ids=r["required_baseline_ids"][:-1]),
            lambda r: r.update(missing_baseline_ids=["W01"]),
        ):
            data = copy.deepcopy(self.registry)
            mutate(data)
            with self.assertRaises(ValueError):
                self.validate(data)

    def test_reduced_shape_dtype_loop_count_or_abi_cannot_replace_original(self):
        mutations = (
            lambda c: c.update(reduced_case=True),
            lambda c: c.update(required=False),
            lambda c: c.update(expected_outputs=1),
            lambda c: c["dimensions"].update(N=1),
            lambda c: c["arrays"][0].update(element_size=4, dtype="f32"),
            lambda c: c["arrays"][0].update(length=64),
            lambda c: c["arrays"][0].update(base_address=0),
            lambda c: c.update(params=c["params"][:-1]),
            lambda c: c.update(params=list(reversed(c["params"]))),
            lambda c: c.update(block=[32, 1, 1]),
            lambda c: c.update(workgroup=[1, 0, 0]),
            lambda c: c["original_shape"].update(elements=64),
        )
        for index, mutate in enumerate(mutations):
            with self.subTest(mutation=index):
                data = copy.deepcopy(self.registry)
                mutate(data["cases"][0])
                with self.assertRaises(ValueError):
                    self.validate(data)
        for family, key, value in (
            ("MatrixVectorMultiplicationKernel", "K", 64),
            ("RMSNormKernel", "N", 128),
            ("SoftmaxKernel", "R", 2),
        ):
            data = copy.deepcopy(self.registry)
            case = next(c for c in data["cases"] if c["family"] == family)
            case["dimensions"][key] = value
            with self.assertRaisesRegex(ValueError, "dimensions"):
                self.validate(data)

    def test_missing_overlapping_or_incorrect_output_projection_is_rejected(self):
        for mutate in (
            lambda c: c["output_projection"][0].update(length=63),
            lambda c: c["output_projection"][0].update(baseline_start=1),
            lambda c: c["output_projection"].append(dict(c["output_projection"][0])),
            lambda c: c.update(output_projection=[]),
        ):
            data = copy.deepcopy(self.registry)
            mutate(data["cases"][0])
            with self.assertRaisesRegex(ValueError, "project"):
                self.validate(data)

    def test_reusing_a_native_half_for_both_original_halves_is_rejected(self):
        data = copy.deepcopy(self.registry)
        case = data["cases"][0]
        original = case["output_projection"][0]
        case["output_projection"] = [
            dict(original, length=512),
            dict(original, baseline_start=512, native_start=0, length=512),
        ]
        with self.assertRaisesRegex(
            ValueError, "projected native bytes|duplicate native"
        ):
            self.validate(data)

    def test_changed_source_spec_or_launch_hashes_are_rejected(self):
        for field in ("source", "assembly", "spec", "launch_config"):
            data = copy.deepcopy(self.registry)
            data["cases"][0][field + "_sha256"] = "0" * 64
            with self.assertRaisesRegex(ValueError, "changed/missing"):
                self.validate(data)

    def test_matrix_views_launch_mapping_and_arbitrary_packed_dtype_are_required(self):
        for identifier, mutate in (
            ("W27", lambda c: c.pop("launch_mapping")),
            ("W27", lambda c: c.update(block=[256, 1, 1])),
            ("W27", lambda c: c["dimensions"].update(K=32)),
            ("W27", lambda c: c["arrays"][-1].update(base_address=0)),
            ("W27", lambda c: c["arrays"][-1].update(length=128)),
            ("W27", lambda c: c["parameter_mapping"].update({"ptr:c": "ptr:out001"})),
            ("W31", lambda c: c["arrays"][1].update(kind="index")),
            ("W31", lambda c: c["arrays"][1].update(dtype="f32")),
        ):
            data = copy.deepcopy(self.registry)
            case = next(c for c in data["cases"] if c["baseline_id"] == identifier)
            mutate(case)
            with self.subTest(identifier=identifier), self.assertRaises(ValueError):
                self.validate(data)

    def test_convolution_keeps_full_pitches_dtype_and_native_fixed_lds(self):
        for identifier, mutate in (
            ("W19", lambda c: c["dimensions"].update(C=16)),
            ("W19", lambda c: c.update(dynamic_shared_bytes=232448)),
            ("W19", lambda c: c["shared_memory_mapping"].update(native_fixed=16384)),
            ("W20", lambda c: c["arrays"][0].update(element_size=2, dtype="f16")),
            ("W20", lambda c: c["output_projection"][0].update(length=128)),
        ):
            data = copy.deepcopy(self.registry)
            case = next(c for c in data["cases"] if c["baseline_id"] == identifier)
            mutate(case)
            with self.subTest(identifier=identifier), self.assertRaises(ValueError):
                self.validate(data)

    def test_advanced_cases_keep_grid_scales_signed_bytes_and_both_scan_outputs(self):
        for identifier, mutate in (
            ("W21", lambda c: c["dimensions"].update(T=32)),
            ("W22", lambda c: c["params"].pop(3)),
            ("W23", lambda c: c.update(grid=[1, 1, 1])),
            (
                "W23",
                lambda c: c["physical_grid_mapping"].update(physical_query_rows=128),
            ),
            ("W24", lambda c: c["arrays"][0].update(dtype="e4m3")),
            ("W24", lambda c: c["arrays"][4].update(length=1)),
            ("W25", lambda c: c["dimensions"].update(T=32)),
            ("W26", lambda c: c["array_view_mappings"].pop()),
            ("W26", lambda c: c["output_projection"].pop()),
            (
                "W26",
                lambda c: c["parameter_mapping"].update({"ptr:out_x": "ptr:out000"}),
            ),
        ):
            data = copy.deepcopy(self.registry)
            case = next(c for c in data["cases"] if c["baseline_id"] == identifier)
            mutate(case)
            with self.subTest(identifier=identifier), self.assertRaises(ValueError):
                self.validate(data)

    def test_existing_public_launch_fields_are_forwarded_without_zero_fill(self):
        case = copy.deepcopy(self.registry["cases"][0])
        case.update(
            max_instructions=1234,
            dynamic_shared=512,
            global_values={"weight": 7},
            shared_allocations=[{"name": "tile", "offset": 8, "size": 64}],
            params=[
                {"bytes": [1, 2, 255]},
                "float:0.25",
                "sym:alpha",
                "int:-3",
                "ptr:x",
            ],
        )
        actual = contract.launch_config(case)
        self.assertEqual(1234, actual["max_instructions"])
        self.assertEqual(512, actual["dynamic_shared_bytes"])
        self.assertEqual({"weight": 7}, actual["globals"])
        self.assertEqual(case["shared_allocations"], actual["shared_allocations"])
        self.assertEqual(
            [
                {"bytes": [1, 2, 255]},
                {"float": 0.25},
                {"sym": "alpha"},
                {"int": -3},
                {"ptr": "x"},
            ],
            actual["params"],
        )
        case["params"] = [{"bytes": [1], "ptr": "x"}]
        with self.assertRaisesRegex(ValueError, "parameter"):
            contract.launch_config(case)


if __name__ == "__main__":
    unittest.main()
