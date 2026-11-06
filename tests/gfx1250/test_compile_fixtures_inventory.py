"""Source inventory controls run without a compiler, GPU, or fixture rewrite."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("compile_fixtures", Path(__file__).with_name("compile_fixtures.py"))
compiler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compiler)


class InstructionInventoryTests(unittest.TestCase):
    def test_labels_directives_and_comments_are_not_instruction_spellings(self):
        source = """tensor_load_probe: ; @tensor_load_probe
s_function_label:
v_function_label:
.Llocal:
.text
.amdhsa_kernel k
; s_nop 0
    s_nop 0 ; an actual scalar instruction
    tensor_load_to_lds v1, v2, v3, s[0:3]
"""
        self.assertEqual(compiler.instruction_rows(source), [
            {"line": 8, "text": "s_nop 0", "components": ["s_nop 0"]},
            {"line": 9, "text": "tensor_load_to_lds v1, v2, v3, s[0:3]", "components": ["tensor_load_to_lds v1, v2, v3, s[0:3]"]},
        ])

    def test_vopd_retains_one_source_instruction_and_both_components(self):
        source = "v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 1 ; comment"
        rows = compiler.instruction_rows(source)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["components"], ["v_dual_mov_b32 v0, 0", "v_dual_mov_b32 v1, 1"])


if __name__ == "__main__":
    unittest.main()
