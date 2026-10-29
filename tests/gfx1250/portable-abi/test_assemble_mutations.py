import importlib.util
import pathlib
import shutil
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("abi_mutations", ROOT / "assemble_mutations.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class MutationRefusalTests(unittest.TestCase):
    def fixture(self):
        directory = tempfile.TemporaryDirectory(prefix="ptx-gfx1250-abi-control-")
        self.addCleanup(directory.cleanup)
        root = pathlib.Path(directory.name)
        for source in ["compiler-provenance.json", "mutations.tsv",
                       "native-dynamic-lds.s", "native-transfers.s", "native-arguments.s"]:
            shutil.copy2(ROOT / source, root / source)
        return root

    def test_complete_table_has_all_six_distinct_assembly_mutations(self):
        result = MODULE.mutations()
        self.assertEqual({row["id"] for row, _ in result}, MODULE.REQUIRED)
        self.assertEqual(len({MODULE.sha256(source.encode()) for _, source in result}), 6)

    def test_missing_or_duplicate_control_cannot_pass(self):
        for duplicate in [False, True]:
            root = self.fixture()
            path = root / "mutations.tsv"
            lines = path.read_text().splitlines()
            path.write_text("\n".join(lines[:-1] + ([lines[1]] if duplicate else [])) + "\n")
            with self.assertRaisesRegex(ValueError, "every required unique"):
                MODULE.mutations(root)

    def test_source_hash_change_cannot_reuse_old_provenance(self):
        root = self.fixture()
        path = root / "native-arguments.s"
        path.write_text(path.read_text() + "\n; changed source\n")
        with self.assertRaisesRegex(ValueError, "differs from the compiler receipt"):
            MODULE.mutations(root)

    def test_unknown_kernel_and_missing_old_instruction_are_rejected(self):
        for old, new, message in [
            ("abi_mixed_byvalue", "no_such_kernel", "one actual native entry"),
            ("v_cvt_f32_ubyte2_e32 v2, s6", "v_cvt_f32_ubyte2_e32 v3, s6", "exactly one"),
        ]:
            root = self.fixture()
            path = root / "mutations.tsv"
            path.write_text(path.read_text().replace(old, new))
            with self.assertRaisesRegex(ValueError, message):
                MODULE.mutations(root)


if __name__ == "__main__":
    unittest.main()
