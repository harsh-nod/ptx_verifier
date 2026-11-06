#!/usr/bin/env python3
"""Export only explicit public fields from the original external frozen study."""

import argparse
import json
from pathlib import Path
import re

import reproduce as study


def hex_value(value, length):
    study.require(isinstance(value, str) and re.fullmatch('[0-9a-f]{' + str(length) + '}', value), 'invalid provenance hash')
    return value


def export(root):
    frozen = json.loads((root / 'freeze.json').read_text())
    study.require(all(study.file_hash(root / path) == expected for path, expected in frozen['files'].items()), 'original frozen input changed')
    plan = json.loads((root / 'plan.json').read_text())
    study.require(plan['candidate_revision'] == study.SOURCE_REVISION, 'unregistered candidate revision')
    audit = json.loads((root / 'independent-audit.json').read_text())
    study.require(audit['all_passed'] is True and audit['plan_sha256'] == study.file_hash(root / 'plan.json') and audit['freeze_sha256'] == study.file_hash(root / 'freeze.json'), 'missing independent audit binding')
    cases = study.contracts({target: (root / 'source' / f'{target}.s').read_text() for target in study.SOURCES})
    study.require([c['id'] for c in cases] == [c['id'] for c in plan['cases']], 'case population changed')
    provenance, hashes, reports = {}, {}, {}
    for arm in ['baseline', 'candidate']:
        report_path = root / 'outcomes' / arm / 'report.json'
        report = json.loads(report_path.read_text())
        reports[arm] = report
        receipt_path = report_path.parent / 'build-receipt.json'
        receipt = json.loads(receipt_path.read_text())
        study.require(len(report['cases']) == 26 and [c['id'] for c in report['cases']] == [c['id'] for c in cases], 'report population changed')
        study.require(report['plan_sha256'] == study.file_hash(root / 'plan.json') and report['freeze_sha256'] == study.file_hash(root / 'freeze.json'), 'report/freeze mismatch')
        study.require(report['binary_sha256'] == receipt['binary_sha256'] and report['build_receipt_sha256'] == study.file_hash(receipt_path), 'receipt binding changed')
        study.require(receipt['source_clean'] is True, 'unclean source build attestation')
        study.require(audit[f'{arm}_report_sha256'] == study.file_hash(report_path), 'audit/report mismatch')
        provenance[arm] = {'comparison_revision': hex_value(plan[f'{arm}_revision'], 40),
                           'binary_build_revision': hex_value(receipt['revision'], 40),
                           'source_tree': hex_value(receipt['source_tree'], 40),
                           'binary_sha256': hex_value(receipt['binary_sha256'], 64),
                           'build_provenance': 'Caller-attested build receipt; hashes are not a reproducible-build proof.'}
        hashes[f'{arm}_build_receipt_sha256'] = study.file_hash(receipt_path)
        hashes[f'{arm}_report_sha256'] = study.file_hash(report_path)
    rows = []
    for case, original in zip(cases, plan['cases']):
        directory = root / original['directory']
        study.require((directory / 'kernel.s').read_text() == case['assembly'], 'mutation differs from reproduction contract')
        study.require(json.loads((directory / 'launch.json').read_text()) == study.launch(case), 'launch contract changed')
        study.require((directory / 'identity.spec').read_text() == study.SPEC, 'specification changed')
        arms = {}
        for arm in ['baseline', 'candidate']:
            raw = root / 'outcomes' / arm / case['id']
            recorded = json.loads((raw / 'result.json').read_text())
            study.require(recorded == next(row for row in reports[arm]['cases'] if row['id'] == case['id']), 'detached result row')
            binary = str(root.parent / arm / 'volta')
            shared = [binary, '--no-log-file', '--backend', 'amdgpu', '--target', case['target']]
            expected_analysis = shared + ['analyze', str(directory / 'kernel.s'), '--config', str(directory / 'launch.json'), '--no-profile', '--print-outputs', '0', '--emit-exprs', str(raw / 'actual.vexpr'), '--dump-graph', str(raw / 'graph.txt')]
            expected_proof = shared + ['verify', str(directory / 'kernel.s'), str(directory / 'identity.spec'), '--config', str(directory / 'launch.json'), '--no-profile', '--dim', f'N={case["block"]}', '--sample', '0']
            study.require(json.loads((raw / 'analysis/command.json').read_text()) == expected_analysis, 'analysis command changed')
            study.require(json.loads((raw / 'proof/command.json').read_text()) == expected_proof, 'proof command changed')
            for phase in ['analysis', 'proof']:
                for stream in ['stdout', 'stderr']:
                    study.require(study.file_hash(raw / phase / stream) == recorded[phase][f'{stream}_sha256'], 'raw log changed')
            study.require(study.file_hash(raw / 'graph.txt') == recorded['graph_sha256'], 'raw graph changed')
            study.require(study.file_hash(raw / 'actual.vexpr') == recorded['independent_identity_check']['sha256'], 'raw output changed')
            arms[arm] = study.inspect(case, arm, (raw / 'analysis/stdout').read_text(),
                                      (raw / 'proof/stdout').read_text(), (raw / 'actual.vexpr').read_text(),
                                      (raw / 'graph.txt').read_text(), recorded['analysis']['returncode'], recorded['proof']['returncode'],
                                      analysis_stderr=(raw / 'analysis/stderr').read_text(), proof_stderr=(raw / 'proof/stderr').read_text(),
                                      analysis_timed_out=recorded['analysis']['timed_out'], proof_timed_out=recorded['proof']['timed_out'])
            study.require(arms[arm]['expected_behavior_pass'], 'raw observation fails declared functional gate')
        names = ['kernel.s', 'launch.json', 'identity.spec', 'expected.json', 'expected.vexpr']
        study.require(set(original['files']) == set(names), 'unregistered input artifact')
        rows.append(study.public_case(case, arms, {name: hex_value(original['files'][name], 64) for name in names}))
    source_paths = ['crates/volta_pipeline/tests/cdna_mixed_lgkm_tests.rs'] + [f'tests/amdgpu/native-mixed-lgkm/{target}.s' for target in study.SOURCES]
    study.require(set(plan['sources']) == set(source_paths), 'unregistered source artifact')
    provenance['sources'] = {path: hex_value(plan['sources'][path]['sha256'], 64) for path in source_paths}
    provenance['binary_source_note'] = 'Baseline build and comparison commits have identical source trees; candidate commit is the frozen integration source.'
    hashes.update({'plan_sha256': study.file_hash(root / 'plan.json'), 'freeze_sha256': study.file_hash(root / 'freeze.json'),
                   'original_prepare_helper_sha256': hex_value(frozen['files']['prepare.py'], 64),
                   'original_execution_helper_sha256': hex_value(frozen['files']['run.py'], 64),
                   'independent_audit_sha256': study.file_hash(root / 'independent-audit.json'),
                   'independent_audit_helper_sha256': study.file_hash(root / 'audit.py'),
                   'original_helper_validation_sha256': study.file_hash(root / 'helper-validation.json'),
                   'portable_reproduction_helper_sha256': study.file_hash(study.__file__),
                   'public_export_helper_sha256': study.file_hash(__file__)})
    return study.public_report(rows, provenance, hashes)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--recorded-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    study.require(not args.output.exists(), 'refuse to overwrite an existing public artifact')
    report = export(args.recorded_root)
    study.write_json(args.output, report)
    print(json.dumps(report['summary'], indent=2))


if __name__ == '__main__':
    main()
