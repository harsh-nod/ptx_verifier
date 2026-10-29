#!/usr/bin/env python3
"""Refusal controls for the metadata-only feature reference contract."""

from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "feature_contract", HERE / "feature_contract.py"
)
CONTRACT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONTRACT)


class FeatureContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ledger = json.loads((HERE / "feature-review.json").read_text())
        cls.inventory = json.loads((HERE / "gaps.json").read_text())

    def refused(self, ledger=None, inventory=None):
        with self.assertRaises(ValueError):
            CONTRACT.validate(
                ledger or self.ledger,
                inventory or self.inventory,
                check_sources=False,
            )

    def test_all_references_are_decomposed_without_an_acceptance_claim(self):
        result = CONTRACT.validate(self.ledger, self.inventory)
        self.assertEqual(result["references"], 520)
        self.assertNotIn("validated", result["dispositions"])

    def test_missing_or_duplicate_reference_cannot_hide_an_obligation(self):
        data = deepcopy(self.ledger)
        data["rows"].pop()
        self.refused(data)
        data = deepcopy(self.ledger)
        data["rows"][-1] = data["rows"][0]
        self.refused(data)

    def test_mismatched_baseline_hash_and_group_association_refuse(self):
        data = deepcopy(self.ledger)
        data["rows"][0]["upstream_sha256"] = "0" * 64
        self.refused(data)
        data = deepcopy(self.inventory)
        data["upstream_feature_reference_rows"][0]["review_group"] = "SPEC-SHARED"
        self.refused(inventory=data)

    def test_nonexistent_native_test_cannot_be_used_as_evidence(self):
        data = deepcopy(self.ledger)
        group = next(group for group in data["groups"] if group["native_candidates"])
        group["native_candidates"][0]["function"] = "imaginary_native_test"
        self.refused(data)

    def test_no_automatic_completion_or_target_only_portable_row(self):
        data = deepcopy(self.ledger)
        data["groups"][0]["completion"] = "validated"
        self.refused(data)
        data = deepcopy(self.ledger)
        data["rows"][0]["proposed_disposition"] = "target_mechanism_residual_candidate"
        inventory = deepcopy(self.inventory)
        inventory["upstream_feature_reference_rows"][0]["gfx1250_review"] = (
            "target_mechanism_residual_candidate"
        )
        self.refused(data, inventory)

    def test_a_target_residual_cannot_swallow_an_asserted_data_output(self):
        data = deepcopy(self.ledger)
        row = next(
            row
            for row in data["rows"]
            if row["proposed_disposition"] == "target_mechanism_residual_candidate"
        )
        row["baseline_golden"] = {"output_coordinates": {"out": [0]}}
        self.refused(data)


if __name__ == "__main__":
    unittest.main()
