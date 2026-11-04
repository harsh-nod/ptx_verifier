"""Controls for pinned source/assertion/golden regression contracts."""

from copy import deepcopy
import json
from pathlib import Path
import unittest
import feature_contract as contract

HERE = Path(__file__).resolve().parent


class FeatureContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.references = json.loads((HERE / "reference-contract.json").read_text())
        cls.inventory = json.loads((HERE / "gaps.json").read_text())

    def test_all_source_assertion_and_golden_pins_match(self):
        self.assertEqual(
            contract.validate(self.references, self.inventory),
            {"references": 520, "groups": 35},
        )

    def test_missing_or_duplicate_reference_is_rejected(self):
        for mutation in [
            lambda d: d["rows"].pop(),
            lambda d: d["rows"].append(d["rows"][0]),
        ]:
            data = deepcopy(self.references)
            mutation(data)
            with self.assertRaises(ValueError):
                contract.validate(data, self.inventory, check_sources=False)

    def test_duplicate_original_inventory_row_is_rejected(self):
        inventory = deepcopy(self.inventory)
        inventory["upstream_feature_reference_rows"].append(
            deepcopy(inventory["upstream_feature_reference_rows"][0])
        )
        with self.assertRaisesRegex(ValueError, "duplicate source references"):
            contract.validate(self.references, inventory, check_sources=False)

    def test_source_hash_and_group_associations_cannot_drift(self):
        data = deepcopy(self.references)
        data["rows"][0]["upstream_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "hash"):
            contract.validate(data, self.inventory, check_sources=False)
        inventory = deepcopy(self.inventory)
        inventory["upstream_feature_reference_rows"][0]["group"] = "SPEC-SHARED"
        with self.assertRaisesRegex(ValueError, "group"):
            contract.validate(self.references, inventory, check_sources=False)

    def test_missing_assertion_and_golden_changes_are_rejected(self):
        data = deepcopy(self.references)
        next(row for row in data["rows"] if row.get("baseline_assertions"))[
            "baseline_assertions"
        ][0]["function"] = "missing_assertion"
        with self.assertRaisesRegex(ValueError, "assertion"):
            contract.validate(data, self.inventory)
        data = deepcopy(self.references)
        next(row for row in data["rows"] if row.get("baseline_golden"))[
            "baseline_golden"
        ]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "golden"):
            contract.validate(data, self.inventory)

    def test_group_counts_and_aggregate_source_kinds_are_checked(self):
        data = deepcopy(self.references)
        data["groups"][0]["reference_count"] += 1
        with self.assertRaisesRegex(ValueError, "count"):
            contract.validate(data, self.inventory, check_sources=False)
        data = deepcopy(self.references)
        next(row for row in data["rows"] if row["path"].endswith(".rs"))[
            "reference_kind"
        ] = "kernel"
        with self.assertRaisesRegex(ValueError, "aggregate"):
            contract.validate(data, self.inventory, check_sources=False)


if __name__ == "__main__":
    unittest.main()
