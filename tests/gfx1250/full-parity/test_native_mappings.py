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
