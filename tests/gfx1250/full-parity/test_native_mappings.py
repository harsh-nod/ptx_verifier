"""Finite source-mapping controls, for source pins, complete projections and native test references."""

import copy
import json
from pathlib import Path
import unittest

import validate_native_mappings as mapping


class MappingControls(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract = json.loads(mapping.DEFAULT.read_text())
        cls.ledger = json.loads(
            Path(mapping.__file__).with_name("reference-contract.json").read_text()
        )

    def test_all24_original_rows_have_exact_source_and_test_mappings(self):
        self.assertEqual(mapping.validate(self.contract, self.ledger), 24)

    def test_all32_matrix_references_have_pinned_properties_and_original_projections(
        self,
    ):
        path = mapping.DEFAULT.with_name("matrix-feature-contract.json")
        document = json.loads(path.read_text())
        self.assertEqual(mapping.validate(document, self.ledger), 32)
        for mutate in (
            lambda d: d["rows"].pop(),
            lambda d: next(
                row for row in d["rows"] if row["kernel"] == "matrix_numeric136"
            ).update(native_outputs={}),
            lambda d: next(
                row for row in d["rows"] if row["kernel"] == "matrix_numeric136"
            )["native_outputs"].update(native=1024),
            lambda d: next(
                row
                for row in d["rows"]
                if row.get("original_output_coordinates", {}).get("out")
            ).update(original_output_coordinates={"out": []}),
        ):
            changed = copy.deepcopy(document)
            mutate(changed)
            with self.assertRaises(ValueError):
                mapping.validate(changed, self.ledger)

    def test_incomplete_duplicate_stale_or_unknown_mappings_fail(self):
        mutations = {
            "missing": lambda d: d["rows"].pop(),
            "duplicate": lambda d: d["rows"].append(d["rows"][0]),
            "stale": lambda d: d["rows"][0].update(native_assembly_sha256="0" * 64),
            "unknown_test": lambda d: d["rows"][0].update(
                test=d["test_source"] + "::missing"
            ),
            "unknown_kind": lambda d: d["rows"][0].update(mapping_kind="unknown"),
            "shifted_output": lambda d: d["rows"][2]["output"].update(
                written_indices=[1, 2]
            ),
        }
        for name, mutate in mutations.items():
            document = copy.deepcopy(self.contract)
            mutate(document)
            with self.subTest(name=name), self.assertRaises(ValueError):
                mapping.validate(document, self.ledger)

    def test_packed_output_contract_cannot_be_deleted_or_blanked(self):
        for comparison in [None, ""]:
            document = copy.deepcopy(self.contract)
            row = next(
                row
                for row in document["rows"]
                if row["mapping_kind"] == "native_assertion"
            )
            if comparison is None:
                row.pop("comparison")
            else:
                row["comparison"] = comparison
            row["reason"] = "Native counterpart"
            row["output"]["written_indices"] = []
            with (
                self.subTest(comparison=comparison),
                self.assertRaisesRegex(ValueError, "contract"),
            ):
                mapping.validate(document, self.ledger)

    def test_property_output_contract_cannot_be_deleted_or_confused(self):
        for name in [
            "matrix-feature-contract.json",
            "mechanism-lifetime-contract.json",
        ]:
            for mutation in ["missing", "ambiguous"]:
                document = json.loads(mapping.DEFAULT.with_name(name).read_text())
                row = next(
                    row
                    for row in document["rows"]
                    if row["mapping_kind"] == "native_assertion"
                )
                if mutation == "missing":
                    row.pop("expected_native_outcome")
                    row["native_outputs"] = {}
                else:
                    row["comparison"] = "Different output schema"
                with (
                    self.subTest(contract=name, mutation=mutation),
                    self.assertRaisesRegex(ValueError, "contract"),
                ):
                    mapping.validate(document, self.ledger)

    def test_remaining13_obligations_preserve_the_pinned_selection_and_original_positives(
        self,
    ):
        path = mapping.DEFAULT.with_name("mechanism-lifetime-contract.json")
        document = json.loads(path.read_text())
        self.assertEqual(mapping.validate(document, self.ledger), 13)
        for mutate in (
            lambda d: d["rows"].pop(),
            lambda d: d["source_selection"].update(sha256="0" * 64),
            lambda d: d["source_selection"].update(reference_paths=[]),
            lambda d: d["source_selection"].update(additional_paths=[]),
        ):
            changed = copy.deepcopy(document)
            mutate(changed)
            with self.assertRaises(ValueError):
                mapping.validate(changed, self.ledger)


if __name__ == "__main__":
    unittest.main()
