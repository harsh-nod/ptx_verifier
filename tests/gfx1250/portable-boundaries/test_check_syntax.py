"""Host refusal controls; these do not count as native instruction executions."""

from pathlib import Path
import tempfile
import unittest

import check_syntax


class SyntaxInventoryTests(unittest.TestCase):
    def table(self, text):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        path = Path(temporary.name) / "cases.tsv"
        path.write_text(text)
        return path

    def test_empty_inventory_is_refused(self):
        with self.assertRaisesRegex(ValueError, "nonempty"):
            check_syntax.load_cases(self.table("id\tkernel\toriginal\treplacement\n"))

    def test_duplicate_or_missing_fields_are_refused(self):
        header = "id\tkernel\toriginal\treplacement\n"
        for body in ["a\tk\told\tnew\na\tk\told\tnew\n", "a\tk\told\t\n"]:
            with self.assertRaises(ValueError):
                check_syntax.load_cases(self.table(header + body))

    def test_mutation_must_match_one_instruction_in_one_entry(self):
        source = "\nk:\nold\n.Lfunc_end0:\n"
        self.assertIn("\nnew\n", check_syntax.replace_entry(source, "k", "old", "new"))
        for original in ["missing", ""]:
            with self.assertRaises(ValueError):
                check_syntax.replace_entry(source, "k", original, "new")
        with self.assertRaises(ValueError):
            check_syntax.replace_entry(source.replace("old", "old\nold"), "k", "old", "new")


if __name__ == "__main__":
    unittest.main()
