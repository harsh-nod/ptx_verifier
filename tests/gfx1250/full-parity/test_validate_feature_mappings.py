"""Refusal controls for complete native regression mappings."""

import copy
import json
from pathlib import Path
import tempfile
import unittest
from validate_feature_mappings import check_index, validate


class FeatureMappingsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "native.rs").write_text(
            'const ASM: &str = include_str!("native.s");\nfn native_positive() {}\n'
        )
        (self.root / "native.s").write_text("compiler fixture\n")
        self.positive = "tests/success/positive.ptx"
        self.negative = "tests/failing/negative.ptx"
        for name in [self.positive, self.negative]:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("original reference source\n")
        self.ledger = {
            "upstream_commit": "fixture-baseline",
            "rows": [
                {"path": path, "group": "G", "upstream_sha256": path}
                for path in [self.positive, self.negative]
            ],
        }
        self.rows = [
            {
                "path": path,
                "group": "G",
                "upstream_sha256": path,
                "mapping_kind": "native_assertion",
                "native_candidates": [
                    {"path": "native.rs", "function": "native_positive"}
                ],
            }
            for path in [self.positive, self.negative]
        ]

    def check(self, rows=None):
        return validate(
            self.ledger,
            [("native.json", {"rows": self.rows if rows is None else rows})],
            root=self.root,
        )

    def test_exact_mapping_retains_source_dependencies(self):
        result = self.check()
        self.assertEqual(result["reference_count"], 2)
        self.assertEqual(
            {r["path"] for r in result["source_inventory"]},
            {"native.rs", "native.s", self.positive, self.negative},
        )

    def test_stored_index_rejects_drift_in_unpinned_included_assembly(self):
        index = self.root / "index.json"
        index.write_text(json.dumps(self.check()))
        check_index(self.check(), index)
        (self.root / "native.s").write_text("changed compiler fixture\n")
        with self.assertRaisesRegex(
            ValueError, "stale source/mapping index.*regenerate"
        ):
            check_index(self.check(), index)
        index.write_text(json.dumps(self.check()))
        check_index(self.check(), index)

    def test_current_references_assertions_and_goldens_are_indexed(self):
        golden = self.root / "original.out"
        golden.write_text("out[0] = 7\n")
        adjacent = (self.root / self.negative).with_suffix(".out")
        adjacent.write_text("out[0] = 1\n")
        assertion = self.root / "baseline.rs"
        assertion.write_text("fn original_assertion() {}\n")
        self.ledger["rows"][0].update(
            baseline_assertions=[
                {
                    "path": "baseline.rs",
                    "function": "original_assertion",
                    "source_sha256": "baseline-assertion",
                }
            ],
            baseline_golden={"path": "original.out", "sha256": "baseline-golden"},
        )
        index = self.root / "index.json"
        for source in [self.root / self.positive, golden, adjacent, assertion]:
            index.write_text(json.dumps(self.check()))
            with source.open("a") as stream:
                stream.write("changed current source\n")
            with (
                self.subTest(source=source.name),
                self.assertRaisesRegex(ValueError, "stale source/mapping index"),
            ):
                check_index(self.check(), index)

    def test_removed_historical_copies_retain_the_frozen_revision_and_identity(self):
        (self.root / self.negative).unlink()
        self.ledger["rows"][0]["baseline_golden"] = {
            "path": "removed.out",
            "sha256": "frozen-golden",
        }
        result = self.check()
        self.assertEqual(result["upstream_commit"], "fixture-baseline")
        self.assertEqual(
            result["historical_only_sources"],
            [
                {"path": "removed.out", "sha256": "frozen-golden"},
                {"path": self.negative, "sha256": self.negative},
            ],
        )
        self.assertIn("native.s", {row["path"] for row in result["source_inventory"]})

    def test_missing_stored_index_requires_explicit_generation(self):
        with self.assertRaisesRegex(
            ValueError, "missing source/mapping index.*regenerate"
        ):
            check_index(self.check(), self.root / "missing.json")

    def test_missing_duplicate_and_extra_mappings_fail(self):
        for rows in [
            self.rows[:1],
            self.rows + [self.rows[0]],
            self.rows + [{**self.rows[0], "path": "extra"}],
        ]:
            with self.assertRaises(ValueError):
                self.check(rows)

    def test_wrong_hash_group_and_kind_fail(self):
        for field, value in [
            ("upstream_sha256", "wrong"),
            ("group", "wrong"),
            ("mapping_kind", "wrong"),
        ]:
            rows = copy.deepcopy(self.rows)
            rows[0][field] = value
            with self.assertRaises(ValueError):
                self.check(rows)

    def test_positive_cannot_become_model_refusal_or_syntax_boundary(self):
        rows = copy.deepcopy(self.rows)
        rows[0]["mapping_kind"] = "model_refusal"
        with self.assertRaisesRegex(ValueError, "positive"):
            self.check(rows)
        (self.root / "original.out").write_text("out[0] = 7\n")
        self.ledger["rows"][0]["baseline_golden"] = {
            "path": "original.out",
            "sha256": "baseline-golden",
            "output_coordinates": {"out": [0]},
        }
        rows[0]["mapping_kind"] = "target_boundary"
        with self.assertRaisesRegex(ValueError, "computation"):
            self.check(rows)

    def test_missing_actual_test_or_fixture_fail(self):
        rows = copy.deepcopy(self.rows)
        rows[0]["native_candidates"][0]["function"] = "missing"
        with self.assertRaisesRegex(ValueError, "actual test"):
            self.check(rows)
        (self.root / "native.s").unlink()
        with self.assertRaises(FileNotFoundError):
            self.check()

    def test_stale_test_and_native_source_pins_fail(self):
        rows = copy.deepcopy(self.rows)
        rows[0]["native_candidates"][0]["source_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "test source pin"):
            self.check(rows)
        rows = copy.deepcopy(self.rows)
        rows[0].update(native_assembly="native.s", native_assembly_sha256="0" * 64)
        with self.assertRaisesRegex(ValueError, "native source pin"):
            self.check(rows)


if __name__ == "__main__":
    unittest.main()
