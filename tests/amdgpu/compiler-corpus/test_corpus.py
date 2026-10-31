"""Controls for classification and complete corpus output contracts."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from corpus import classify, expression_indices, load_manifest, MANIFEST, ROOT


class CorpusTests(unittest.TestCase):
    def test_compiler_success_or_unqualified_accept_is_not_verification(self):
        for stdout in ["", "assembly succeeded", "VERDICT: ACCEPT\n"]:
            self.assertEqual(classify(0, stdout, "")[0], "inconclusive")

    def test_unknown_unsupported_findings_timeouts_and_crashes_stay_distinct(self):
        cases = [
            ((2, "VERDICT: UNKNOWN\n", ""), "inconclusive"),
            ((1, "", "unsupported AMD instruction `new_opcode`"), "unsupported"),
            ((1, "  AMD memory-conflict freedom (native) FAIL\n", ""), "finding"),
            ((1, "VERDICT: REJECT\n", ""), "finding"),
            ((101, "", "panicked"), "crash"),
            ((-11, "", ""), "crash"),
        ]
        for args, expected in cases:
            with self.subTest(expected=expected):
                self.assertEqual(classify(*args)[0], expected)
        self.assertEqual(classify(-9, "VERDICT: ACCEPT\n", "", timed_out=True)[0], "timeout")

    def test_expression_contract_preserves_array_names_and_sparse_absolute_indices(self):
        self.assertEqual(
            expression_indices('volta-expr 1\nn0 int 7\nout "out" 65 n0\nout "other" 2 n0\nout "out" 64 n0\n'),
            {"out": [64, 65], "other": [2]},
        )
        for text in ["", 'volta-expr 1\nout "out" 0 n0\nout "out" 0 n0\n']:
            with self.assertRaises(ValueError):
                expression_indices(text)

    def test_unsupported_execution_cannot_count_a_partial_trace_failure_as_a_finding(self):
        stdout = '  AMD memory-conflict freedom (native) FAIL\nVERDICT: REJECT\n'
        for code in (0, 1, 2):
            self.assertEqual(classify(code, stdout, 'unsupported AMD instruction `new_opcode`')[0],
                             'unsupported')

    def test_real_manifest_rejects_dropped_coordinates_even_with_changed_count(self):
        document = json.loads(MANIFEST.read_text())
        altered = copy.deepcopy(document)
        case = altered["cases"][0]
        case["output_indices"]["out"].pop()
        case["expected_outputs"] -= 1
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text(json.dumps(altered))
            with self.assertRaisesRegex(ValueError, "original output contract"):
                load_manifest(path, ROOT)

    def test_real_manifest_rejects_relabelled_target_and_stale_assembly(self):
        document = json.loads(MANIFEST.read_text())
        for field, value in [("target", "gfx950"), ("assembly_sha256", "0" * 64)]:
            altered = copy.deepcopy(document)
            altered["cases"][0][field] = value
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "manifest.json"
                path.write_text(json.dumps(altered))
                with self.assertRaises(ValueError):
                    load_manifest(path, ROOT)


if __name__ == "__main__":
    unittest.main()
