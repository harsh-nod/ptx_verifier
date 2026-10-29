from copy import deepcopy
from pathlib import Path
import tempfile
import unittest

from coordinator_features import prepare, validate_inventory


class CoordinatorFeatureReviewTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "native.rs").write_text("#[test]\nfn actual_control() {}\n")
        self.positive = "tests/success/positive.ptx"
        self.negative = "tests/failing/negative.ptx"
        for path in [self.positive, self.negative]:
            (self.root / path).parent.mkdir(parents=True, exist_ok=True)
            (self.root / path).write_text("pinned original source\n")
        self.ledger = {
            "rows": [
                {
                    "path": path,
                    "group": "G",
                    "upstream_sha256": path,
                    "proposed_disposition": "historical_pending",
                }
                for path in [self.positive, self.negative]
            ]
        }
        self.manifests = [
            (
                "manifest.json",
                {
                    "rows": [
                        {
                            "path": path,
                            "group": "G",
                            "upstream_sha256": path,
                            "proposal": "native_assertion_candidate",
                            "completion": "coordinator_review_required",
                            "native_candidates": [
                                {"path": "native.rs", "function": "actual_control"}
                            ],
                        }
                        for path in [self.positive, self.negative]
                    ]
                },
            )
        ]

    def candidate(self, reviews=None, decisions=None, mechanism_reviews=None):
        return prepare(
            self.ledger,
            self.manifests,
            reviews or {"rows": []},
            decisions,
            root=self.root,
            mechanism_reviews=mechanism_reviews,
        )

    def decisions(self):
        rows = self.candidate()["rows"]
        return {
            "authority": "coordinator",
            "rows": [
                {
                    "path": row["path"],
                    "proof_identity_sha256": row["proof_identity_sha256"],
                    "status": "reviewed",
                    "portable_obligation_satisfied": True,
                    "note": "Exact native assertion independently replayed",
                    "validation_commands": ["cargo test --test actual_controls"],
                }
                for row in rows
            ],
        }

    def test_preparation_never_promotes_candidates_or_rewrites_historical_statuses(
        self,
    ):
        original = deepcopy(self.ledger)
        result = self.candidate()
        self.assertEqual(result["reviewed_reference_count"], 0)
        self.assertEqual(result["pending_reference_count"], 2)
        self.assertEqual(self.ledger, original)

    def test_exact_explicit_coordinator_decisions_review_each_reference(self):
        result = self.candidate(decisions=self.decisions())
        self.assertTrue(result["all_references_coordinator_reviewed"])
        self.assertTrue(result["historical_planning_unchanged"])

    def test_changed_current_control_source_invalidates_the_previous_decision(self):
        decisions = self.decisions()
        (self.root / "native.rs").write_text(
            "#[test]\nfn actual_control() { panic!(); }\n"
        )
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(decisions=decisions)

    def test_changed_included_reference_source_invalidates_the_previous_decision(self):
        decisions = self.decisions()
        (self.root / self.positive).write_text("changed original source\n")
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(decisions=decisions)

    def test_changed_literal_included_assembly_invalidates_the_previous_decision(self):
        (self.root / "native.rs").write_text(
            'const SOURCE: &str = include_str!("native.s");\n#[test]\nfn actual_control() {}\n'
        )
        (self.root / "native.s").write_text("original native instruction\n")
        decisions = self.decisions()
        (self.root / "native.s").write_text("changed native instruction\n")
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(decisions=decisions)

    def test_recursive_helper_module_and_byte_includes_are_bound(self):
        (self.root / "native.rs").write_text(
            '#[path = "helper.rs"]\nmod helper;\n#[test]\nfn actual_control() {}\n'
        )
        (self.root / "helper.rs").write_text(
            'const DATA: &[u8] = include_bytes!(r#"native.bin"#);\n'
        )
        (self.root / "native.bin").write_bytes(b"original")
        decisions = self.decisions()
        (self.root / "native.bin").write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(decisions=decisions)

    def test_packed_positive_keeps_its_pinned_assertion_and_typed_golden_contract(self):
        assertion = {
            "path": "baseline.rs",
            "function": "packed_original",
            "source_sha256": "historical-original-source",
        }
        self.ledger["rows"][0]["baseline_assertions"] = [assertion]
        (self.root / "baseline.rs").write_text("fn packed_original() {}\n")
        (self.root / "original.out").write_text("out[0] = 1\n")
        self.manifests[0][1]["rows"][0].update(
            {
                "comparison": "every original index and no additional indices",
                "reason": "",
                "kernel": "packed_halves",
                "output": {
                    "element_width": 2,
                    "elements": 2,
                    "written_indices": [0, 1],
                },
                "golden_path": "original.out",
                "golden_sha256": "pinned-golden",
            }
        )
        row = next(
            row for row in self.candidate()["rows"] if row["path"] == self.positive
        )
        self.assertEqual(row["baseline_assertions"], [assertion])
        for detail in [
            self.positive,
            "packed_original",
            "packed_halves",
            '"element_width": 2',
            "original.out",
            "pinned-golden",
        ]:
            self.assertIn(detail, row["portable_obligation"])
        self.assertEqual(row["coordinator_status"], "pending")

    def test_baseline_assertion_and_golden_sources_are_bound(self):
        (self.root / "baseline.rs").write_text("fn original_assertion() {}\n")
        (self.root / "golden.out").write_text("out[0] = 1\n")
        self.ledger["rows"][0]["baseline_assertions"] = [
            {"path": "baseline.rs", "function": "original_assertion"}
        ]
        self.manifests[0][1]["rows"][0]["golden_path"] = "golden.out"
        decisions = self.decisions()
        (self.root / "golden.out").write_text("out[0] = 2\n")
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(decisions=decisions)
        decisions = self.decisions()
        (self.root / "baseline.rs").write_text(
            "fn original_assertion() { panic!(); }\n"
        )
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(decisions=decisions)

    def test_changed_current_adjudication_invalidates_the_previous_decision(self):
        reviews = {
            "rows": [
                {
                    "path": self.positive,
                    "upstream_sha256": self.positive,
                    "status": "resolved_candidate",
                    "native_evidence": [
                        {"path": "native.rs", "function": "actual_control"}
                    ],
                    "completion": "coordinator_review_required",
                    "current_observation": "Actual typed negative and complete positive",
                }
            ]
        }
        result = self.candidate(reviews=reviews)
        decisions = self.decisions()
        for decision in decisions["rows"]:
            row = next(row for row in result["rows"] if row["path"] == decision["path"])
            decision["proof_identity_sha256"] = row["proof_identity_sha256"]
        self.candidate(reviews=reviews, decisions=decisions)
        reviews["rows"][0]["current_observation"] = "Different boundary reasoning"
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(reviews=reviews, decisions=decisions)

    def test_mechanism_adjudication_binds_its_exact_reasoning_and_source(self):
        reviews = {
            "rows": [
                {
                    "path": self.positive,
                    "upstream_sha256": self.positive,
                    "current_adjudication": "Exact operand grammar with actual native negative",
                    "native_evidence": [
                        {"path": "native.rs", "function": "actual_control"}
                    ],
                }
            ]
        }
        result = self.candidate(mechanism_reviews=reviews)
        row = next(row for row in result["rows"] if row["path"] == self.positive)
        self.assertEqual(
            row["current_review_overlays"]["mechanism_adjudication"]["row"],
            reviews["rows"][0],
        )
        decisions = self.decisions()
        for decision in decisions["rows"]:
            row = next(row for row in result["rows"] if row["path"] == decision["path"])
            decision["proof_identity_sha256"] = row["proof_identity_sha256"]
        self.candidate(mechanism_reviews=reviews, decisions=decisions)
        reviews["rows"][0]["current_adjudication"] = "Changed exact residual"
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(mechanism_reviews=reviews, decisions=decisions)

    def test_current_overlay_native_source_changes_invalidate_the_previous_decision(
        self,
    ):
        (self.root / "native.ll").write_text("original LLVM source\n")
        reviews = {
            "rows": [
                {
                    "path": self.positive,
                    "upstream_sha256": self.positive,
                    "native_sources": ["native.ll"],
                }
            ]
        }
        result = self.candidate(mechanism_reviews=reviews)
        decisions = self.decisions()
        for decision in decisions["rows"]:
            row = next(row for row in result["rows"] if row["path"] == decision["path"])
            decision["proof_identity_sha256"] = row["proof_identity_sha256"]
        (self.root / "native.ll").write_text("changed LLVM source\n")
        with self.assertRaisesRegex(ValueError, "stale coordinator"):
            self.candidate(mechanism_reviews=reviews, decisions=decisions)

    def test_known_portable_gap_cannot_be_overridden_by_candidate_ownership(self):
        reviews = {
            "rows": [
                {
                    "path": self.positive,
                    "upstream_sha256": self.positive,
                    "status": "pending",
                    "completion": "coordinator_review_required",
                }
            ]
        }
        result = self.candidate(reviews=reviews)
        decisions = self.decisions()
        for decision in decisions["rows"]:
            row = next(row for row in result["rows"] if row["path"] == decision["path"])
            decision["proof_identity_sha256"] = row["proof_identity_sha256"]
        with self.assertRaisesRegex(ValueError, "unresolved portable obligation"):
            self.candidate(reviews=reviews, decisions=decisions)

    def test_authority_and_duplicate_decisions_are_checked(self):
        decisions = self.decisions()
        decisions["authority"] = "candidate-agent"
        with self.assertRaisesRegex(ValueError, "authority"):
            self.candidate(decisions=decisions)
        decisions = self.decisions()
        decisions["rows"].append(decisions["rows"][0])
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.candidate(decisions=decisions)

    def test_review_needs_actual_portable_adjudication_and_reproduction_commands(self):
        decisions = self.decisions()
        decisions["rows"][0]["portable_obligation_satisfied"] = False
        with self.assertRaisesRegex(ValueError, "portable-obligation"):
            self.candidate(decisions=decisions)
        decisions = self.decisions()
        decisions["rows"][0]["validation_commands"] = []
        with self.assertRaisesRegex(ValueError, "reproduction"):
            self.candidate(decisions=decisions)

    def test_missing_actual_named_control_never_becomes_a_proof(self):
        (self.root / "native.rs").write_text("// actual_control was removed\n")
        with self.assertRaisesRegex(ValueError, "missing actual named"):
            self.candidate()

    def test_changed_native_assembly_cannot_keep_the_declared_pin(self):
        (self.root / "native.s").write_text("actual compiler source\n")
        self.manifests[0][1]["rows"][0].update(
            {"native_assembly": "native.s", "native_assembly_sha256": "stale"}
        )
        with self.assertRaisesRegex(ValueError, "native source pin changed"):
            self.candidate()

    def test_coordinated_row_deletion_cannot_shrink_the_finite_original_inventory(self):
        ledger = {**self.ledger, "upstream_commit": "original"}
        inventory = {
            "upstream_commit": "original",
            "upstream_feature_reference_rows": [
                {
                    "path": row["path"],
                    "upstream_sha256": row["upstream_sha256"],
                    "review_group": row["group"],
                }
                for row in ledger["rows"]
            ],
        }
        validate_inventory(ledger, inventory, expected_count=2)
        ledger["rows"] = ledger["rows"][:1]
        with self.assertRaisesRegex(ValueError, "incomplete"):
            validate_inventory(ledger, inventory, expected_count=2)

    def test_historical_source_hash_cannot_be_replaced_with_a_current_native_hash(self):
        ledger = {**deepcopy(self.ledger), "upstream_commit": "original"}
        inventory = {
            "upstream_commit": "original",
            "upstream_feature_reference_rows": [
                {
                    "path": row["path"],
                    "upstream_sha256": row["upstream_sha256"],
                    "review_group": row["group"],
                }
                for row in ledger["rows"]
            ],
        }
        ledger["rows"][0]["upstream_sha256"] = "new-native-source"
        with self.assertRaisesRegex(ValueError, "historical reference identity"):
            validate_inventory(ledger, inventory, expected_count=2)


if __name__ == "__main__":
    unittest.main()
