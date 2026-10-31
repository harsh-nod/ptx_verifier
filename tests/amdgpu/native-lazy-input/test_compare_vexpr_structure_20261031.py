"""Synthetic independent ground truth; no real workload exports or verifier runs."""
import itertools
import gzip
import hashlib
import json
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest
import compare_vexpr_structure_20261031 as v

LEFT = '''volta-expr 1
n0 = elem "x" 7
n1 = int -2
n2 = param "scale"
n3 = mul n0 n2
n4 = sub n3 n1
out "out" 3 n4
'''
RIGHT = '''volta-expr 1
n0 = param "scale"
n1 = int -2
n2 = elem "x" 7
n3 = mul n2 n0
n4 = sub n3 n1
out "out" 3 n4
'''

class StructuralComparison(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.contract = {'out': [3]}
    def tearDown(self):
        self.tmp.cleanup()
    def put(self, name, text):
        p = self.root / name
        p.write_text(text)
        return p
    def compare(self, a, b, expected=None):
        return v.compare(self.put('a.vexpr', a), self.put('b.vexpr', b), expected or self.contract)
    def refuses(self, text, expected=None, **budgets):
        with self.assertRaises(v.FormatError):
            v.scan(self.put('bad.vexpr', text), expected or self.contract, **budgets)
    def test_independent_topological_permutation_preserves_ordered_tree(self):
        result = self.compare(LEFT, RIGHT)
        self.assertTrue(result['match'])
        self.assertNotEqual(result['left']['decoded_vexpr_sha256'], result['right']['decoded_vexpr_sha256'])
        self.assertEqual(result['left']['node_table_payload_bytes'], 5 * 33)
    def test_all_six_leaf_orders_and_two_child_orders(self):
        # Construction permutation is allowed; mathematical commutativity is not.
        leaves = ['elem "x" 7', 'int -2', 'param "scale"']
        for order in itertools.permutations(range(3)):
            node = {old: new for new, old in enumerate(order)}
            text = 'volta-expr 1\n' + ''.join(f'n{i} = {leaves[old]}\n' for i, old in enumerate(order))
            good = text + f'n3 = mul n{node[0]} n{node[2]}\nn4 = sub n3 n{node[1]}\nout "out" 3 n4\n'
            swapped = good.replace(f'mul n{node[0]} n{node[2]}', f'mul n{node[2]} n{node[0]}')
            self.assertTrue(self.compare(LEFT, good)['match'])
            self.assertFalse(self.compare(LEFT, swapped)['match'])
    def test_changed_input_name_index_parameter_operator_child_order_constant(self):
        for old, new in [('"x" 7', '"y" 7'), ('"x" 7', '"x" 8'), ('"scale"', '"other"'),
                         ('mul n0 n2', 'add n0 n2'), ('sub n3 n1', 'sub n1 n3'), ('int -2', 'int -3')]:
            with self.subTest(new=new):
                self.assertFalse(self.compare(LEFT, LEFT.replace(old, new))['match'])
    def test_coordinate_change_missing_extra_duplicate_or_reorder_refuses(self):
        for mutated in [LEFT.replace('out "out" 3', 'out "out" 4'), LEFT.replace('out "out" 3 n4\n', ''),
                        LEFT + 'out "out" 3 n4\n', LEFT + 'out "extra" 0 n4\n']:
            self.refuses(mutated)
        self.refuses(LEFT + 'out "out" 2 n4\n', {'out': [2, 3]})
        with self.assertRaises(v.FormatError):
            v.validate_contract({'out': [3, 3]})
    def test_unchanged_but_incomplete_both_sides_cannot_pass(self):
        with self.assertRaises(v.FormatError):
            self.compare(LEFT, RIGHT, {'out': [3, 4]})
    def test_int_real_bool_and_symbol_identity_are_typed(self):
        template = 'volta-expr 1\nn0 = {}\nout "out" 3 n0\n'
        for a, b in [('int 1', 'real 1'), ('int 1', 'bool true'), ('sym 1', 'sym 2'),
                     ('real 1/3', 'real 1/2'), ('real inf', 'real -inf')]:
            self.assertFalse(self.compare(template.format(a), template.format(b))['match'])
    def test_fma_is_not_mul_add_or_reordered_fma(self):
        base = 'volta-expr 1\nn0 = elem "x" 0\nn1 = int 2\nn2 = int 3\n'
        a = base + 'n3 = fma n0 n1 n2\nout "out" 3 n3\n'
        b = base + 'n3 = mul n0 n1\nn4 = add n3 n2\nout "out" 3 n4\n'
        self.assertFalse(self.compare(a, b)['match'])
        self.assertFalse(self.compare(a, a.replace('fma n0 n1 n2', 'fma n0 n2 n1'))['match'])
    def test_sharing_and_unreachable_valid_nodes_do_not_change_roots(self):
        a = 'volta-expr 1\nn0 = elem "x" 1\nn1 = add n0 n0\nout "out" 3 n1\n'
        b = 'volta-expr 1\nn0 = elem "x" 1\nn1 = elem "x" 1\nn2 = undefined\nn3 = add n0 n1\nout "out" 3 n3\n'
        self.assertTrue(self.compare(a, b)['match'])
    def test_quoted_unicode_names_and_escaping_are_exact(self):
        a = 'volta-expr 1\nn0 = param "λ \\\"q\\\" \\\\ name"\nout "out" 3 n0\n'
        self.assertTrue(self.compare(a, a)['match'])
        self.assertFalse(self.compare(a, a.replace('λ', 'μ'))['match'])
    def test_symbolic_read_preserves_array_and_index_child(self):
        a = 'volta-expr 1\nn0 = int 2\nn1 = read "x" n0\nout "out" 3 n1\n'
        for b in [a.replace('"x"', '"y"'), a.replace('int 2', 'int 3')]:
            self.assertFalse(self.compare(a, b)['match'])
    def test_unknown_ops_wrong_arities_bad_literals_and_refs_refuse(self):
        for node in ['frobnicate n0', 'add n0', 'neg n0 n0', 'int 1 2', 'param n0', 'elem "x" n0',
                     'read "x" 0', 'bool 1', 'int 9223372036854775808', 'sym -1', 'real nan',
                     'real 1/0', 'real 2/4', 'real -0', 'real 0/2', 'real 1/-2', 'real 1/1']:
            self.refuses('volta-expr 1\nn0 = int 0\nn1 = ' + node + '\nout "out" 3 n1\n')
        for text in ['volta-expr 1\nn0 = add n0 n0\nout "out" 3 n0\n',
                     'volta-expr 1\nn0 = int 0\nn0 = int 1\nout "out" 3 n0\n',
                     'volta-expr 1\nn1 = int 0\nout "out" 3 n1\n',
                     'volta-expr 1\nn0 = int 0\nout "out" 3 n9\n',
                     LEFT + 'n5 = int 1\n']:
            self.refuses(text)
    def test_reachable_undefined_or_discarded_cannot_certify_complete_outputs(self):
        for op in ['undefined', 'discarded']:
            self.refuses(f'volta-expr 1\nn0 = {op}\nn1 = neg n0\nout "out" 3 n1\n')
    def test_truncation_encoding_header_name_and_budget_errors(self):
        for text in ['', 'volta-expr 2\n', LEFT.rstrip('\n'), LEFT.replace('param "scale"', 'param "open'),
                     LEFT + 'garbage\n']:
            self.refuses(text)
        self.refuses(LEFT, max_nodes=4)
        self.refuses(LEFT, max_line_bytes=10)
        p = self.root / 'utf8';p.write_bytes(b'volta-expr 1\nn0 = param "\xff"\n')
        with self.assertRaises(v.FormatError):v.scan(p, self.contract)
    def test_every_supported_operation_has_strict_arity_and_no_folding(self):
        base = 'volta-expr 1\nn0 = int 2\nn1 = real 1/3\nn2 = bool true\n'
        for ops, args in [(v.UNARY, 'n0'), (v.BINARY, 'n0 n1'), (v.TERNARY, 'n2 n0 n1')]:
            for op in ops:
                text = base + f'n3 = {op} {args}\nout "out" 3 n3\n'
                self.assertTrue(self.compare(text, text)['match'])
        self.assertFalse(self.compare(base + 'n3 = add n0 n0\nout "out" 3 n3\n',
                                      'volta-expr 1\nn0 = int 4\nout "out" 3 n0\n')['match'])
    def test_output_map_order_and_utf8_name_framing(self):
        a = 'volta-expr 1\nn0 = int 1\nn1 = int 2\nout "ab" 0 n0\nout "a" 12 n1\n'
        b = 'volta-expr 1\nn0 = int 2\nn1 = int 1\nout "a" 12 n0\nout "ab" 0 n1\n'
        self.assertTrue(self.compare(a, b, {'ab': [0], 'a': [12]})['match'])
        self.assertFalse(self.compare(a, b.replace('out "ab" 0 n1', 'out "ab" 0 n0'), {'ab': [0], 'a': [12]})['match'])
    def test_duplicate_contract_keys_and_missing_contract_refuse(self):
        path = self.put('contract.json', '{"out":[3],"out":[3]}')
        with self.assertRaises(v.FormatError):v.read_contract(path)
        for contract in [{}, {'out': []}, {'out': [True]}, {'out': [4, 3]}, {'out': [-1]}]:
            with self.assertRaises(v.FormatError):v.validate_contract(contract)
    def test_cli_match_mismatch_and_invalid_are_distinct(self):
        contract = self.put('outputs.json', json.dumps(self.contract))
        left = self.put('left.vexpr', LEFT)
        right = self.put('right.vexpr', RIGHT)
        output = self.root / 'audit.json'
        command = [sys.executable, v.__file__, str(left), str(right),
                   '--expected-coordinates', str(contract), '--output', str(output)]
        p = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0)
        self.assertTrue(json.loads(output.read_text())['match'])
        right.write_text(RIGHT.replace('int -2', 'int -3'))
        p = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(p.returncode, 1)
        self.assertEqual(json.loads(output.read_text())['different_outputs'], 1)
        right.write_text(RIGHT.rstrip('\n'))
        p = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)
        self.assertIn('invalid', json.loads(output.read_text()))
        self.assertFalse(p.stderr)
    def test_linear_coordinate_check_on_large_sparse_contract(self):
        # A sparse coordinate contract guards exact flat indices, not only counts.
        coordinates = list(range(0, 4000, 2))
        text = 'volta-expr 1\nn0 = elem "x" 4\n' + ''.join(
            f'out "out" {i} n0\n' for i in coordinates)
        expected = {'out': coordinates}
        result = self.compare(text, text, expected)
        self.assertTrue(result['match'])
        self.assertEqual(result['left']['output_count'], 2000)
        self.refuses(text.replace('out "out" 2000 n0\n', ''), expected)
    def test_gzip_and_plain_share_decoded_structure_with_distinct_artifact_bindings(self):
        left = self.put('plain.vexpr', LEFT)
        right = self.root / 'compressed.vexpr.gz'
        packed = gzip.compress(RIGHT.encode(), mtime=0)
        right.write_bytes(packed)
        result = v.compare(left, right, self.contract)
        self.assertTrue(result['match'])
        self.assertEqual(result['left']['compression'], 'none')
        self.assertEqual(result['left']['artifact_sha256'], hashlib.sha256(LEFT.encode()).hexdigest())
        self.assertEqual(result['right']['compression'], 'gzip')
        self.assertEqual(result['right']['artifact_sha256'], hashlib.sha256(packed).hexdigest())
        self.assertEqual(result['right']['artifact_bytes'], len(packed))
        self.assertEqual(result['right']['decoded_vexpr_sha256'], hashlib.sha256(RIGHT.encode()).hexdigest())
        self.assertEqual(result['right']['decoded_vexpr_bytes'], len(RIGHT.encode()))
        # Magic detection is independent of the filename suffix.
        other = self.root / 'compressed-no-suffix'
        other.write_bytes(packed)
        self.assertTrue(v.compare(left, other, self.contract)['match'])
    def test_corrupt_truncated_and_wrong_gzip_fail_closed(self):
        packed = gzip.compress(LEFT.encode(), mtime=0)
        crc = bytearray(packed)
        crc[-8] ^= 1
        size = bytearray(packed)
        size[-1] ^= 1
        for bad in [bytes(crc), bytes(size), packed[:-1], packed[:-8], packed[:10],
                    b'not a gzip file', LEFT.encode(), b'\x1f\x8bgarbage',
                    gzip.compress(b'wrong format\n', mtime=0), packed + b'garbage']:
            with self.subTest(length=len(bad)):
                p = self.root / 'broken.vexpr.gz'
                p.write_bytes(bad)
                with self.assertRaises(v.FormatError):
                    v.scan(p, self.contract)
    def test_gzip_member_boundary_does_not_hide_missing_coordinates(self):
        one = gzip.compress(b'volta-expr 1\nn0 = int 1\n', mtime=0)
        two = gzip.compress(b'out "out" 3 n0\n', mtime=0)
        p = self.root / 'members.vexpr.gz'
        p.write_bytes(one + two)
        self.assertEqual(v.scan(p, self.contract)['output_count'], 1)
        p.write_bytes(one)
        with self.assertRaises(v.FormatError):
            v.scan(p, self.contract)
    def test_maximum_integer_and_index_boundaries(self):
        a = 'volta-expr 1\nn0 = int -9223372036854775808\nn1 = elem "x" 18446744073709551615\nn2 = sub n0 n1\nout "out" 3 n2\n'
        self.assertTrue(self.compare(a, a)['match'])
        self.refuses(a.replace('18446744073709551615', '18446744073709551616'))

if __name__ == '__main__':
    unittest.main()
