import unittest

from generate_stage_profiles import index_instructions


class NativeProfileInventoryTests(unittest.TestCase):
    def setUp(self):
        self.cases = [{"assembly": "native.s", "kernel": "k", "baseline_id": "W01"}]
        self.row = {
            "path": "native.s",
            "kernel": "k",
            "line": 10,
            "mnemonic": "v_mov_b32",
            "family": "VectorAlu",
            "operands": [{"kind": "register", "class": "Vector", "words": 1}],
            "modifiers": [],
        }

    def test_each_original_entry_must_have_actual_typed_profiles(self):
        with self.assertRaisesRegex(ValueError, "no profiles"):
            index_instructions([], self.cases)

    def test_unregistered_entries_cannot_expand_the_original_surface(self):
        row = {**self.row, "kernel": "unregistered"}
        with self.assertRaisesRegex(ValueError, "unregistered"):
            index_instructions([row], self.cases)

    def test_aliased_case_ownership_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "duplicate native entry"):
            index_instructions([self.row], self.cases * 2)

    def test_both_vopd_slots_remain_distinct_even_with_identical_opcodes(self):
        rows = [{**self.row, "component_slot": slot} for slot in ["X", "Y"]]
        profiles, cases = index_instructions(rows, self.cases)
        self.assertEqual(len(profiles), 2)
        self.assertEqual({row["component_slot"] for row in profiles}, {"X", "Y"})
        self.assertEqual(sum(cases["W01"].values()), 2)

    def test_named_modifier_values_and_operand_widths_do_not_collapse(self):
        rows = [
            {**self.row, "modifiers": [{"name": "offset", "value": str(offset)}]}
            for offset in [4, 8]
        ]
        rows.append(
            {
                **self.row,
                "operands": [{"kind": "register", "class": "Vector", "words": 2}],
            }
        )
        profiles, _ = index_instructions(rows, self.cases)
        self.assertEqual(len(profiles), 3)

    def test_unknown_typed_family_cannot_gain_a_semantic_contract(self):
        with self.assertRaises(KeyError):
            index_instructions([{**self.row, "family": "Unmodeled"}], self.cases)


if __name__ == "__main__":
    unittest.main()
