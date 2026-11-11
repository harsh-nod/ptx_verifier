"""Frozen controls retain their exact bytes after upstream fixture relocation."""
import copy
from pathlib import Path
import tempfile
import unittest

import benchmark


class LayoutCompatibilityTests(unittest.TestCase):
    def test_relocated_controls_keep_original_manifest_pins_and_selection(self):
        document = benchmark.load_cases()
        controls = [case for case in document["cases"]
                    if case.get("backend") == "ptx" and "/execution_error/" in case["assembly"]]
        self.assertEqual(len(controls), 2)
        for case in controls:
            current = benchmark.study_input(case["assembly"])
            self.assertIn("/check_failure/", str(current))
            self.assertEqual(benchmark.corpus.sha(current), case["assembly_sha256"])
            changed = copy.deepcopy(document)
            next(row for row in changed["cases"] if row["id"] == case["id"])["assembly_sha256"] = "0" * 64
            with self.subTest(case=case["id"]), self.assertRaisesRegex(ValueError, "stale case input"):
                benchmark.validate_cases(changed)

    def test_original_location_takes_precedence_and_unlisted_paths_do_not_relocate(self):
        relative = "crates/volta_pipeline/tests/ptx/execution_error/shared_write_write_race.ptx"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / relative
            moved = root / relative.replace("execution_error", "check_failure")
            moved.parent.mkdir(parents=True)
            moved.write_text("moved bytes")
            self.assertEqual(benchmark.study_input(relative, root), moved)
            old.parent.mkdir(parents=True)
            old.write_text("different original bytes")
            self.assertEqual(benchmark.study_input(relative, root), old)
            unknown = relative.replace("shared_write_write_race", "unlisted")
            self.assertEqual(benchmark.study_input(unknown, root), root / unknown)
