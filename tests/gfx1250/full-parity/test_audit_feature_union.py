import unittest

from audit_feature_union import audit


class ReferenceUnionTests(unittest.TestCase):
    def setUp(self):
        self.positive = "tests/success/positive.ptx"
        self.negative = "tests/failing/negative.ptx"
        self.ledger = {"rows": [{"path": path, "group": "G", "upstream_sha256": path} for path in [self.positive, self.negative]]}

    def row(self, path, proposal="native_assertion_candidate"):
        return {"path": path, "group": "G", "upstream_sha256": path, "proposal": proposal, "completion": "coordinator_review_required"}

    def test_exact_partition_keeps_both_candidate_and_negative_distinctions(self):
        result = audit(self.ledger, [("positive", {"rows": [self.row(self.positive)]}), ("negative", {"rows": [self.row(self.negative, "model_domain_refusal")]})])
        self.assertTrue(result["ownership_complete"])
        self.assertEqual(result["candidate_status_counts"]["intentional_negative_model_control"], 1)
        self.assertTrue(all(row["completion"] == "coordinator_review_required" for row in result["rows"]))

    def test_dropped_reference_remains_missing(self):
        result = audit(self.ledger, [("partial", {"rows": [self.row(self.positive)]})])
        self.assertFalse(result["ownership_complete"])
        self.assertEqual(result["missing_rows"], [{"path": self.negative, "group": "G"}])

    def test_overlap_duplicate_and_extra_are_reported_without_silent_deduplication(self):
        result = audit(self.ledger, [("a", {"rows": [self.row(self.positive), self.row(self.positive), self.row("extra")]}), ("b", {"rows": [self.row(self.positive), self.row(self.negative)]})])
        self.assertFalse(result["ownership_complete"])
        self.assertEqual(result["overlapping_rows"][0]["path"], self.positive)
        self.assertEqual(result["duplicate_rows_within_manifest"][0]["source"], "a")
        self.assertEqual(result["unexpected_rows"][0]["path"], "extra")

    def test_required_positive_cannot_be_satisfied_by_model_refusal(self):
        result = audit(self.ledger, [("bad", {"rows": [self.row(self.positive, "model_domain_refusal"), self.row(self.negative)]})])
        self.assertFalse(result["ownership_complete"])
        self.assertIn("required positive", result["policy_violations"][0]["reason"])

    def test_owned_portable_gap_does_not_become_an_implemented_native_case(self):
        missing = self.row(self.positive, "portable_native_gap")
        missing["remaining_gate"] = "Add actual native source"
        result = audit(self.ledger, [("owned", {"rows": [missing, self.row(self.negative)]})])
        self.assertTrue(result["ownership_complete"])
        self.assertEqual(len(result["explicit_portable_native_gaps"]), 1)
        self.assertEqual(result["explicit_portable_native_gaps"][0]["remaining_gate"], "Add actual native source")

    def test_unknown_disposition_cannot_be_silently_counted_as_native_implementation(self):
        result = audit(self.ledger, [("unknown", {"rows": [self.row(self.positive, "typo"), self.row(self.negative)]})])
        self.assertFalse(result["ownership_complete"])
        self.assertEqual(result["policy_violations"][0]["reason"], "unknown candidate disposition")

    def test_wrong_historical_source_and_self_acceptance_are_rejected(self):
        row = self.row(self.positive)
        row["upstream_sha256"] = "current-source-is-not-historical-source"
        row["coordinator_acceptance"] = "accepted"
        result = audit(self.ledger, [("bad", {"rows": [row, self.row(self.negative)]})])
        self.assertFalse(result["ownership_complete"])
        self.assertEqual(len(result["policy_violations"]), 2)


if __name__ == "__main__":
    unittest.main()
