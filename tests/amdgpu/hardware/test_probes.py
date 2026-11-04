"""Independent reference controls and fail-closed expression receipt checks."""
import tempfile
import subprocess
import sys
from pathlib import Path
import unittest

from probes import Case, constant_outputs, expected_outputs


class ProbeControls(unittest.TestCase):
    def test_address_components_do_not_carry_before_masking(self):
        word = Case('control', 'smem', 4, 3, 3, 3)
        self.assertEqual(word.words(), [0x03020100])
        half = Case('control', 'smem', 2, 3, 3, 3)
        self.assertEqual(half.words(), [0x0706])
        byte = Case('control', 'smem', 1, 3, 3, 3)
        self.assertEqual(byte.words(), [9])

    def test_b96_scale_uses_all_twelve_payload_bytes(self):
        case = Case('control', 'smem', 12, 3, 1, 3, True)
        self.assertEqual(case.words(), [0x0f0e0d0c, 0x13121110, 0x17161514])

    def test_launch_reference_preserves_absolute_group_and_wave_coordinates(self):
        case = Case('control', 'launch', axes=(1, 1, 1))
        words = expected_outputs('gfx1250', case)
        self.assertEqual(len(words), 2 * 3 * 2 * 64 * 4)
        start = ((1 * 3 + 2) * 2 + 1) * 64 * 4
        self.assertEqual(words[start:start + 4], [1, 2, 1, 1 << 30])
        self.assertEqual(words[start + 32 * 4:start + 32 * 4 + 4],
                         [1, 2, 1, (1 << 30) | (1 << 25)])
        self.assertEqual(expected_outputs('gfx942', case)[start:start + 4], [1, 2, 1, 0])

    def test_expression_parser_rejects_missing_unknown_and_duplicate_values(self):
        bad = ['', 'volta-expr 2\n',
               'volta-expr 1\nout "out" 0 n0\n',
               'volta-expr 1\nn0 = undefined\nout "out" 0 n0\n',
               'volta-expr 1\nn0 = int 7\nout "out" 0 n0\nout "out" 0 n0\n',
               'volta-expr 1\nn0 = int 7\nout "extra" 0 n0\n']
        with tempfile.TemporaryDirectory() as name:
            path = Path(name) / 'output.vexpr'
            for text in bad:
                path.write_text(text)
                with self.subTest(text=text), self.assertRaises(ValueError):
                    constant_outputs(path)
            path.write_text('volta-expr 1\nn0 = int 7\nout "out" 256 n0\n')
            self.assertEqual(constant_outputs(path), {256: 7})

    def test_failed_attempt_removes_prior_success_receipt(self):
        here = Path(__file__).resolve().parent
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            for script, receipt in [('probes.py', 'verifier-result.json'), ('run.py', 'result.json')]:
                path = directory / receipt
                path.write_text('{"status":"pass"}\n')
                command = [sys.executable, str(here / script), '--target', 'gfx942',
                           '--work-dir', str(directory), '--volta', str(directory / 'missing-binary')]
                if script == 'run.py':
                    command.extend(('--host', 'unused.invalid', '--device', '0'))
                result = subprocess.run(command, capture_output=True, text=True, timeout=10)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(path.exists(), f'{script} retained a stale success')


if __name__ == '__main__':
    unittest.main()
