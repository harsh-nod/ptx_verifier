"""Host inventory refusal controls, not GPU or symbolic execution evidence."""

from pathlib import Path
import tempfile
import unittest

import check_mutants


class MutationInventoryTests(unittest.TestCase):
    def table(self, body):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        path = Path(scratch.name) / "mutations.tsv"
        path.write_text("id\tsource\tkernel\toriginal\toccurrence\treplacement\n" + body)
        return path

    def test_empty_inventory_and_unknown_modules_are_refused(self):
        for body in ["", "a\tmissing.s\tk\told\t0\tnew\n"]:
            with self.assertRaises(ValueError):
                check_mutants.read_mutations(self.table(body))

    def test_malformed_occurrences_and_mixed_sources_are_refused(self):
        row = "a\tnative-tensor-metadata.s\tk\told\t0\tnew\n"
        for body in [row.replace("\t0\t", "\t-1\t"),
                     row + row.replace("native-tensor-metadata.s", "native-tensor-publication.s")]:
            with self.assertRaises(ValueError):
                check_mutants.read_mutations(self.table(body))

    def test_missing_exact_instruction_never_silently_mutates_another_entry(self):
        source = "\nk:\nold\n.Lfunc_end0:\n"
        self.assertIn("\nnew\n", check_mutants.replace_entry(source, "k", "old", 0, "new"))
        for original, occurrence in [("missing", 0), ("old", 1), ("", 0)]:
            with self.assertRaises(ValueError):
                check_mutants.replace_entry(source, "k", original, occurrence, "new")


if __name__ == "__main__":
    unittest.main()
