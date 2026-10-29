"""Refusal controls for the finite reference ledger; no GPU execution."""

import copy
import json
from pathlib import Path
import unittest

import check_inventory


class CoverageInventoryTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(__file__).resolve().parent
        self.manifest = json.loads((self.directory / "cases.json").read_text())

    def test_current_complete_inventory_is_accepted(self):
        check_inventory.validate(self.manifest, self.directory)

    def test_missing_and_duplicate_reference_rows_are_refused(self):
        for rows in [self.manifest["rows"][:-1],
                     self.manifest["rows"][:-1] + [self.manifest["rows"][0]]]:
            changed = copy.deepcopy(self.manifest)
            changed["rows"] = rows
            with self.assertRaisesRegex(ValueError, "distinct"):
                check_inventory.validate(changed, self.directory)

    def test_changed_current_artifact_hash_is_refused(self):
        changed = copy.deepcopy(self.manifest)
        first = next(iter(changed["artifacts"]))
        changed["artifacts"][first] = "0" * 64
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            check_inventory.validate(changed, self.directory)


if __name__ == "__main__":
    unittest.main()
