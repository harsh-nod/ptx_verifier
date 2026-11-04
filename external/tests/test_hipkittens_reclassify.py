"""Reclassification binds unchanged process records and refuses missing inputs."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'external/extraction'))
SPEC = importlib.util.spec_from_file_location('hipkittens_reclassify', ROOT/'external/extraction/hipkittens_reclassify.py')
RECLASSIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RECLASSIFY)


def fixture(root):
    directory = root/'original-case'
    directory.mkdir()
    stdout = '\n'.join(f'  {name} (target algorithm) PASS' for name in sorted(RECLASSIFY.vectors.EXPECTED_PROPERTIES))
    stdout += '\nVC check: 0.001s (decision procedure 0.001s)  elements: 32\nEQUIVALENT (matches spec)\nVERDICT: ACCEPT\n'
    stage = {'status': 'succeeded', 'returncode': 0}
    for suffix, data in [('stdout', stdout), ('stderr', ''), ('json', json.dumps(stage))]:
        (directory/('verify.'+suffix)).write_text(data)
    report = {'cases': 1, 'results': [{'id': 'original-case', 'dtype': 'f32', 'elements': 32, 'stage': stage,
                                      'status': 'verified', 'full_identity_proved': True}],
              'input_sha256': {'driver': 'original-driver', 'binary': 'original-binary'}, 'mathematical_controls': []}
    (root/'report.json').write_text(json.dumps(report))
    return directory, report


class HipKittensReclassificationTests(unittest.TestCase):
    def test_add_one_math_refutation_retains_graph_rejection_without_identity_claim(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            directory, report = fixture(root)
            output = (directory/'verify.stdout').read_text().replace(
                'AMD memory-conflict freedom (target algorithm) PASS',
                'AMD memory-conflict freedom (target algorithm) FAIL').replace('VERDICT: ACCEPT', 'VERDICT: REJECT')
            stage = {'status': 'rejected', 'returncode': 1}
            (directory/'verify.stdout').write_text(output)
            (directory/'verify.json').write_text(json.dumps(stage))
            report['profile'] = 'vec-add1'
            row = report['results'][0]
            row.pop('full_identity_proved')
            row.update(status='graph_rejected', full_specification_proved=True, stage=stage)
            wrong = output.replace('EQUIVALENT (matches spec)', 'NOT EQUIVALENT: 32 mismatched element(s) vs spec')
            for suffix, data in [('stdout', wrong), ('stderr', ''), ('json', json.dumps(stage))]:
                (directory/('wrong-spec.'+suffix)).write_text(data)
            report['mathematical_controls'] = [RECLASSIFY.vectors.math_control(
                row, stage, wrong, '', RECLASSIFY.vectors.ADD1)]
            (root/'report.json').write_text(json.dumps(report))
            result = RECLASSIFY.reclassify(root)
            self.assertEqual(result['outcomes'], {'graph_rejected': 1})
            self.assertEqual(result['full_specification_proofs'], 1)
            self.assertNotIn('full_identity_proofs', result)
            self.assertEqual(result['differences'], [])
            control = result['mathematical_controls'][0]
            self.assertTrue(control['math_refuted'])
            self.assertFalse(control['graph_verified'])
            self.assertNotIn('passed', control)
            (directory/'wrong-spec.stdout').write_text(wrong.replace('elements: 32', 'elements: 1/32'))
            changed = RECLASSIFY.reclassify(root)
            self.assertFalse(changed['mathematical_controls'][0]['math_refuted'])
            self.assertEqual(len(changed['differences']), 1)

    def test_existing_result_is_recomputed_and_transcript_drift_is_explicit(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            directory, _ = fixture(root)
            result = RECLASSIFY.reclassify(root)
            self.assertEqual(result['outcomes'], {'verified': 1})
            self.assertEqual(result['full_identity_proofs'], 1)
            self.assertEqual(result['differences'], [])
            (directory/'verify.stderr').write_text('execution stopped: unsupported AMD instruction `foo`')
            changed = RECLASSIFY.reclassify(root)
            self.assertEqual(changed['outcomes'], {'contract_error': 1})
            self.assertEqual(changed['full_identity_proofs'], 0)
            self.assertEqual(len(changed['differences']), 1)
            self.assertNotEqual(changed['transcript_inventory_sha256'], result['transcript_inventory_sha256'])

    def test_duplicate_missing_or_changed_process_records_are_refused(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            directory, report = fixture(root)
            report['cases'] = 2
            report['results'] *= 2
            (root/'report.json').write_text(json.dumps(report))
            with self.assertRaisesRegex(ValueError, 'duplicate'):
                RECLASSIFY.reclassify(root)
            report['cases'] = 1
            report['results'] = report['results'][:1]
            (root/'report.json').write_text(json.dumps(report))
            (directory/'verify.json').write_text(json.dumps({'status': 'rejected', 'returncode': 1}))
            with self.assertRaisesRegex(ValueError, 'process record'):
                RECLASSIFY.reclassify(root)
            (directory/'verify.stdout').unlink()
            with self.assertRaises(OSError):
                RECLASSIFY.reclassify(root)

    def test_cli_refuses_aliasing_or_overwriting_original_report(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            fixture(root)
            report = root/'report.json'
            original = report.read_bytes()
            with patch.object(sys, 'argv', ['hipkittens_reclassify', str(root), '--output', str(report)]):
                with self.assertRaises(SystemExit) as error:
                    RECLASSIFY.main()
            self.assertEqual(error.exception.code, 2)
            self.assertEqual(report.read_bytes(), original)


if __name__ == '__main__':
    unittest.main()
