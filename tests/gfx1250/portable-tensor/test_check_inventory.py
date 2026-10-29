"""Host reference/shape refusal controls, separate from native semantic tests."""

import copy
import json
from pathlib import Path
import unittest

import check_inventory


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(__file__).resolve().parent
        self.manifest = json.loads((self.directory / "cases.json").read_text())

    def test_complete_current_inventory_is_accepted(self):
        check_inventory.validate(self.manifest, self.directory)

    def test_missing_or_duplicate_baseline_rows_are_refused(self):
        for rows in [self.manifest["rows"][:-1],
                     self.manifest["rows"][:-1] + [self.manifest["rows"][0]]]:
            changed = copy.deepcopy(self.manifest)
            changed["rows"] = rows
            with self.assertRaisesRegex(ValueError, "distinct"):
                check_inventory.validate(changed, self.directory)

    def test_reduced_shape_or_changed_artifact_is_refused(self):
        changed = copy.deepcopy(self.manifest)
        changed["native_edge_configuration"]["input"]["shape"] = [4, 4]
        with self.assertRaisesRegex(ValueError, "reduced"):
            check_inventory.validate(changed, self.directory)
        changed = copy.deepcopy(self.manifest)
        changed["artifacts"][next(iter(changed["artifacts"]))] = "0" * 64
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            check_inventory.validate(changed, self.directory)

    def test_changed_original_golden_cannot_retain_its_mapping(self):
        changed = copy.deepcopy(self.manifest)
        row = next(row for row in changed["rows"] if row.get("baseline_golden"))
        row["baseline_golden"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "golden hash mismatch"):
            check_inventory.validate(changed, self.directory)


if __name__ == "__main__":
    unittest.main()
