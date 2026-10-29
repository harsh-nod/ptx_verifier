"""Finite source-mapping controls, independent of native runtime acceptance."""

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
            Path(mapping.__file__).with_name("feature-review.json").read_text()
        )

    def test_all24_original_rows_have_exact_source_and_test_candidates(self):
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

    def test_incomplete_duplicate_stale_or_unreviewed_mappings_fail(self):
        mutations = {
            "missing": lambda d: d["rows"].pop(),
            "duplicate": lambda d: d["rows"].append(d["rows"][0]),
            "stale": lambda d: d["rows"][0].update(native_assembly_sha256="0" * 64),
            "unknown_test": lambda d: d["rows"][0].update(
                test=d["test_source"] + "::missing"
            ),
            "accepted": lambda d: d["rows"][0].update(
                coordinator_acceptance="complete"
            ),
            "blanket_exclusion": lambda d: d["rows"][0].update(
                candidate_kind="ptx_only"
            ),
            "shifted_output": lambda d: d["rows"][2]["output"].update(
                written_indices=[1, 2]
            ),
        }
        for name, mutate in mutations.items():
            document = copy.deepcopy(self.contract)
            mutate(document)
            with self.subTest(name=name), self.assertRaises(ValueError):
                mapping.validate(document, self.ledger)


if __name__ == "__main__":
    unittest.main()
