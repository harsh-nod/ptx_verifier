"""Host controls for complete-source extraction and explicit pipeline outcomes."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "external/extraction"))
SPEC = importlib.util.spec_from_file_location("hipkittens_corpus", ROOT / "external/extraction/hipkittens_corpus.py")
CORPUS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CORPUS)


class HipKittensCorpusTests(unittest.TestCase):
    def test_dry_run_selects_exact_source_without_executing_shell_pipeline(self):
        cwd = Path('/source/dir')
        text = '''mkdir -p /never/execute\n/opt/rocm/bin/hipcc other.cpp -DOTHER -o other.o\n/opt/rocm/bin/hipcc kernel.cpp -DKITTENS_CDNA4 --offload-arch=gfx950 \\\n  -DATTN_N=2048 -O3 -o module.so 2>&1 | tee /never/execute/log\n'''
        args = CORPUS.compiler_line(text, cwd / 'kernel.cpp', cwd)
        self.assertNotIn('|', args)
        self.assertNotIn('tee', args)
        self.assertIn('-DATTN_N=2048', args)
        flags, removed = CORPUS.device_flags(args, cwd / 'kernel.cpp', cwd, 'gfx950', 'cdna4')
        self.assertIn('-O3', flags)
        self.assertIn('-DATTN_N=2048', flags)
        self.assertNotIn('kernel.cpp', flags)
        self.assertNotIn('-o', flags)
        self.assertIn('module.so', removed)

    def test_ambiguous_absent_and_retargeted_recipes_are_refused(self):
        cwd = Path('/src')
        for output in ['', 'hipcc k.cpp\nhipcc k.cpp\n']:
            with self.subTest(output=output), self.assertRaisesRegex(ValueError, 'unique'):
                CORPUS.compiler_line(output, cwd / 'k.cpp', cwd)
        for args in [['hipcc', 'k.cpp', '-DKITTENS_CDNA4', '--offload-arch=gfx950'],
                     ['hipcc', 'k.cpp', '-DKITTENS_CDNA5', '--offload-arch=gfx1250', '--offload-arch=gfx950']]:
            with self.subTest(args=args), self.assertRaisesRegex(ValueError, 'retargeting'):
                CORPUS.device_flags(args, cwd / 'k.cpp', cwd, 'gfx1250', 'cdna5')

    def test_target_wave_and_duplicate_emitted_entries_are_checked(self):
        def assembly(target='gfx1250', wave=32, duplicate=False):
            kernel = '  - .name: k\n    .wavefront_size: ' + str(wave) + '\n'
            return ('.amdgcn_target "amdgcn-amd-amdhsa--' + target + '"\n.amdgpu_metadata\n'
                    + 'amdhsa.target: amdgcn-amd-amdhsa--' + target + '\namdhsa.kernels:\n' + kernel
                    + (kernel if duplicate else '') + '.end_amdgpu_metadata\n')
        self.assertEqual(CORPUS.metadata(assembly(), 'gfx1250')[0]['.name'], 'k')
        for text, reason in [(assembly(target='gfx950'), 'target'), (assembly(wave=64), 'wave'),
                             (assembly(duplicate=True), 'duplicate')]:
            with self.subTest(reason=reason), self.assertRaisesRegex(ValueError, reason):
                CORPUS.metadata(text, 'gfx1250')
        self.assertEqual(CORPUS.metadata('.amdgcn_target "amdgcn-amd-amdhsa--gfx950"\n', 'gfx950'), [])

    def test_process_failures_timeout_and_signal_are_not_normal_rejections(self):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            for script, expected in [('import sys;sys.exit(1)', 'rejected'),
                                     ('import os,signal;os.kill(os.getpid(),signal.SIGTERM)', 'process_crash'),
                                     ('import time;time.sleep(2)', 'timeout')]:
                record, _, _ = CORPUS.stage([sys.executable, '-c', script], directory, expected, .1)
                self.assertEqual(record['status'], expected)
                self.assertEqual(json.loads((directory / (expected + '.json')).read_text()), record)
            record, _, _ = CORPUS.stage(['/nonexistent/hipcc'], directory, 'missing', 1)
            self.assertEqual(record['status'], 'process_error')


if __name__ == '__main__':
    unittest.main()
