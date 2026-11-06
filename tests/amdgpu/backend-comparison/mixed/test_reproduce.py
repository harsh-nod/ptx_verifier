import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import reproduce as study


def finding(kind='ReadBeforeReady', source='global_store_dword v2, v10, s[6:7]', use=20, source_event=20):
    return (f'      AmdRegisterHazard {{ issue: EventId(10), use_event: EventId({use}), wave: 0, register: AmdRegister {{ file: Vector, index: 10, lanes: 1 }}, kind: {kind} }}\n'
            f'        e10 t0           line 14: ds_read_b32 v10, v2\n'
            f'        e{source_event} t0           line 17: {source}\n')


def graph_text(failed=False, witness=''):
    return ('kernel: graph verification\n'
            + ''.join(f'  {prop} (algorithm) {"FAIL" if failed and prop == study.PROPERTIES[1] else "PASS"}\n'
                      + (witness if prop == study.PROPERTIES[1] else '') for prop in study.PROPERTIES)
            + f'GRAPH VERIFICATION: {"REJECTED" if failed else "VERIFIED"} (no equivalence check requested)\n')


class Controls(unittest.TestCase):
    def test_exact_population_and_geometry(self):
        root = Path(__file__).resolve().parents[4]
        def source(target):
            path = f'tests/amdgpu/native-mixed-lgkm/{target}.s'
            fixture = root / path
            return fixture.read_text() if fixture.is_file() else subprocess.check_output(['git', 'show', f'{study.SOURCE_REVISION}:{path}'], cwd=root).decode()
        cases = study.contracts({target: source(target) for target in study.SOURCES})
        self.assertEqual(len(cases), 26)
        self.assertEqual(sum(c['output_count'] for c in cases), 1792)
        self.assertEqual([c['block'] for c in cases if c['role'] == 'safe_partial'], [63, 64, 65, 128] * 2)
        self.assertEqual(sum(c['role'] == 'unsafe' for c in cases), 16)
        self.assertTrue(all(study.launch(c)['early_readiness'] is False and study.launch(c)['early_memory_conflicts'] is False for c in cases))

    def test_same_finding_requires_bound_use_and_correct_section(self):
        source = study.STORE + ', s[6:7]'
        self.assertTrue(study.same_finding(graph_text(True, finding()), 'ReadBeforeReady', source))
        self.assertFalse(study.same_finding(graph_text(True, finding(source_event=21)), 'ReadBeforeReady', source))
        self.assertFalse(study.same_finding(graph_text(True, finding('DestinationReuse') + finding(source='s_mov_b32 s14, s12')), 'ReadBeforeReady', source))
        self.assertFalse(study.same_finding(graph_text(True) + finding(), 'ReadBeforeReady', source))

    def test_complete_identity_refuses_missing_duplicate_swapped_and_extra(self):
        valid = 'volta-expr 1\nn0 = elem "x" 0\nn1 = elem "x" 1\nout "out" 0 n0\nout "out" 1 n1\n'
        self.assertTrue(study.identity(valid, 2))
        for wrong in [valid.replace('out "out" 1 n1\n', ''), valid + 'out "out" 1 n1\n', valid.replace('out "out" 1 n1', 'out "out" 1 n0'), valid + 'out "extra" 0 n0\n', valid.replace('n1 = elem "x" 1', 'n0 = elem "x" 1'), valid.replace('n1 = elem "x" 1', 'n1 = add n0 n0')]:
            self.assertFalse(study.identity(wrong, 2))

    def test_unknown_abort_incomplete_and_multiple_verdicts_cannot_qualify(self):
        case = {'role': 'unsafe', 'output_count': 1, 'expected_hazard_kind': 'ReadBeforeReady', 'expected_hazard_source': study.STORE + ', s[6:7]'}
        analysis = graph_text(True, finding())
        proof = graph_text(True).split('GRAPH VERIFICATION:', 1)[0] + 'VC check: 0.000s elements: 1\nEQUIVALENT (matches spec)\nVERDICT: REJECT\n'
        outputs = 'volta-expr 1\nn0 = elem "x" 0\nout "out" 0 n0\n'
        good = study.inspect(case, 'candidate', analysis, proof, outputs, 'terminal completed\n', 1, 1)
        self.assertTrue(good['expected_behavior_pass'])
        self.assertTrue(good['expected_hazard_rejected'])
        changes = [
            (analysis.replace('FAIL', 'UNKNOWN'), proof, outputs, 'terminal completed\n', 2, 1),
            (analysis, proof, outputs, 'terminal aborted unsupported\n', 1, 1),
            (analysis, proof + 'VERDICT: REJECT\n', outputs, 'terminal completed\n', 1, 1),
            (analysis, proof.replace('elements: 1', 'elements: 0'), outputs, 'terminal completed\n', 1, 1),
            (analysis, proof, '', 'terminal completed\n', 1, 1),
            (analysis + 'GRAPH VERIFICATION: REJECTED extra\n', proof, outputs, 'terminal completed\n', 1, 1),
            ('', '', '', '', None, None),
        ]
        for args in changes:
            row = study.inspect(case, 'candidate', *args)
            self.assertFalse(row['expected_behavior_pass'])
        aborted = study.inspect(case, 'candidate', analysis, proof, outputs, 'terminal aborted unsupported\n', 1, 1)
        self.assertFalse(aborted['expected_hazard_rejected'])
        for keywords in [{'analysis_stderr': 'error: unsupported form'}, {'proof_stderr': 'panic'}, {'analysis_timed_out': True}, {'proof_timed_out': True}, {'proof_stderr': 'NOT EQUIVALENT'}]:
            self.assertFalse(study.inspect(case, 'candidate', analysis, proof, outputs, 'terminal completed\n', 1, 1, **keywords)['expected_behavior_pass'])
        for contradictory_analysis, contradictory_proof in [(analysis + 'VERDICT: ACCEPT\n', proof), (analysis + 'EARLY_READINESS: REJECT\n', proof), (analysis, proof + 'GRAPH VERIFICATION: VERIFIED extra\n')]:
            self.assertFalse(study.inspect(case, 'candidate', contradictory_analysis, contradictory_proof, outputs, 'terminal completed\n', 1, 1)['expected_behavior_pass'])

    def test_published_all_case_counts_and_explicit_public_fields(self):
        data = json.loads(Path(__file__).with_name('results.json').read_text())
        self.assertEqual(len(data['cases']), 26)
        self.assertEqual(sum(c['output_count'] for c in data['cases']), 1792)
        self.assertEqual(data['summary']['baseline']['safe_accepted'], 2)
        self.assertEqual(data['summary']['candidate']['safe_accepted'], 10)
        self.assertEqual(data['summary']['candidate']['safe_false_positives'], 0)
        for arm in ['baseline', 'candidate']:
            self.assertEqual(data['summary'][arm]['expected_hazards_rejected'], 16)
            self.assertEqual(data['summary'][arm]['full_math_proofs'], 26)
            for case in data['cases']:
                row = case['arms'][arm]
                self.assertEqual(row['configured_output_coordinates']['out'], list(range(case['output_count'])))
                self.assertEqual(row['observed_output_count'], case['output_count'])
                self.assertTrue(row['expected_behavior_pass'])
        for case in data['cases']:
            for name in ['full_graph_sha256', 'full_output_sha256']:
                self.assertEqual(case['arms']['baseline'][name], case['arms']['candidate'][name])
        def inspect(value):
            if isinstance(value, dict):
                self.assertFalse({'command', 'stdout', 'stderr', 'hostname', 'raw_diagnostics'} & set(value))
                for item in value.values():
                    inspect(item)
            elif isinstance(value, list):
                for item in value:
                    inspect(item)
            elif isinstance(value, str):
                self.assertFalse(value.startswith('/'))
                self.assertNotIn('AmdRegisterHazard {', value)
        inspect(data)

    def test_launch_error_retained_without_abandoning_population(self):
        with tempfile.TemporaryDirectory() as temporary:
            with patch.object(study.subprocess, 'run', side_effect=OSError('executable unavailable')):
                text, code, stderr, timed_out = study.invoke(['unavailable'], Path(temporary) / 'phase')
            self.assertEqual(text, '')
            self.assertIsNone(code)
            self.assertFalse(timed_out)
            self.assertTrue(stderr)
            self.assertEqual(json.loads((Path(temporary) / 'phase/status.json').read_text()), {'returncode': None, 'timed_out': False})

    def test_freeze_detects_either_binary_input_and_record_mutation(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = {arm: root / arm for arm in ['baseline', 'candidate']}
            for binary in binaries.values():
                binary.write_text('immutable binary')
            (root / 'input').write_text('immutable input')
            freeze = {'helper_sha256': study.file_hash(study.__file__), 'binaries': {arm: study.file_hash(binary) for arm, binary in binaries.items()}, 'inputs': {'input': study.file_hash(root / 'input')}}
            study.write_json(root / 'freeze.json', freeze)
            frozen_hash = study.file_hash(root / 'freeze.json')
            study.check_frozen(root, binaries, freeze, frozen_hash)
            for arm, binary in binaries.items():
                binary.write_text('changed binary')
                with self.assertRaises(ValueError):
                    study.check_frozen(root, binaries, freeze, frozen_hash)
                binary.write_text('immutable binary')
            (root / 'input').write_text('changed input')
            with self.assertRaises(ValueError):
                study.check_frozen(root, binaries, freeze, frozen_hash)
            (root / 'input').write_text('immutable input')
            (root / 'freeze.json').write_text('{}')
            with self.assertRaises(ValueError):
                study.check_frozen(root, binaries, freeze, frozen_hash)

    def test_reproduction_outputs_are_external(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source, helper = root / 'source', root / 'helper'
            study.require_external_output(root / 'results', [source, helper])
            for output in [source, source / 'results', helper / 'results']:
                with self.assertRaises(ValueError):
                    study.require_external_output(output, [source, helper])

    def test_export_paths_are_not_status_markers(self):
        self.assertTrue(study.diagnostics_clean('Wrote event graph to ../unknown-study/graph.txt\n'))
        self.assertTrue(study.diagnostics_clean('Wrote output expressions to ../unsupported-study/out.vexpr\n'))
        self.assertFalse(study.diagnostics_clean('UNKNOWN\n'))
        self.assertFalse(study.diagnostics_clean('error: unsupported operation\n'))


if __name__ == '__main__':
    unittest.main()
