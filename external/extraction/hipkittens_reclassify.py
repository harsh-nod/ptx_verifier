"""Reclassify a preserved vector run without rerunning or rewriting any analysis."""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re

import hipkittens_vectors as vectors


def reclassify(directory):
    report_path = directory / 'report.json'
    original = json.loads(report_path.read_text())
    rows = original['results']
    vectors.inventory.require(rows and len(rows) == original['cases'] == len({row['id'] for row in rows}),
                              'missing or duplicate preserved vector cases')
    inventory, differences, results = [], [], []

    def classify(row, kind):
        vectors.inventory.require(re.fullmatch(r'[A-Za-z0-9_.-]+', row['id']), 'unsafe preserved case ID')
        base = directory / row['id']
        paths = {name: base / (kind + '.' + suffix) for name, suffix in
                 [('stdout', 'stdout'), ('stderr', 'stderr'), ('stage', 'json')]}
        stdout, stderr = paths['stdout'].read_text(), paths['stderr'].read_text()
        record = json.loads(paths['stage'].read_text())
        vectors.inventory.require(record == row['stage'], 'preserved process record differs from original report')
        inventory.append({'case': row['id'], 'kind': kind,
                          'sha256': {name: vectors.inventory.sha(path.read_bytes()) for name, path in paths.items()}})
        try:
            status = vectors.classify_verify(record, stdout, stderr, row['elements'])
        except ValueError:
            status = 'contract_error'
        full_math = vectors.full_identity_proved(record, stdout, stderr, row['elements'])
        return status, full_math

    for row in rows:
        status, full_math = classify(row, 'verify')
        if status != row['status'] or full_math != row['full_identity_proved']:
            differences.append({'case': row['id'], 'original_status': row['status'], 'new_status': status,
                                'original_full_identity_proved': row['full_identity_proved'],
                                'new_full_identity_proved': full_math})
        results.append({'id': row['id'], 'dtype': row['dtype'], 'status': status, 'full_identity_proved': full_math})
    known = {row['id']: row for row in rows}
    controls = []
    for control in original['mathematical_controls']:
        if control['status'] == 'no_verified_original_case':
            vectors.inventory.require(not any(row['dtype'] == control['dtype'] and row['status'] == 'verified'
                                              for row in results), 'unavailable dtype control has a verified case')
            controls.append({'dtype': control['dtype'], 'status': control['status'], 'passed': False})
            continue
        case = known[control['case']]
        status, _ = classify({**case, 'stage': control['stage']}, 'wrong-spec')
        if status != control['status'] or (status == 'mathematical_mismatch') != control['passed']:
            differences.append({'case': control['case'], 'kind': 'wrong-spec', 'original_status': control['status'],
                                'new_status': status})
        controls.append({'case': control['case'], 'status': status, 'passed': status == 'mathematical_mismatch'})
    serialized = json.dumps(inventory, sort_keys=True, separators=(',', ':')).encode()
    return {'schema_version': 1, 'original_report_sha256': vectors.inventory.sha(report_path.read_bytes()),
            'original_driver_sha256': original['input_sha256']['driver'],
            'current_classifier_sha256': vectors.inventory.sha(Path(vectors.__file__).read_bytes()),
            'current_shared_checks_sha256': vectors.inventory.sha(Path(vectors.corpus.__file__).read_bytes()),
            'reclassification_source_sha256': vectors.inventory.sha(Path(__file__).read_bytes()),
            'binary_sha256': original['input_sha256']['binary'], 'cases': len(results),
            'outcomes': dict(sorted(Counter(row['status'] for row in results).items())),
            'full_identity_proofs': sum(row['full_identity_proved'] for row in results),
            'mathematical_controls': controls, 'differences': differences,
            'transcript_inventory_sha256': vectors.inventory.sha(serialized), 'transcript_inventory': inventory,
            'results': results}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        output = args.output.resolve()
        vectors.inventory.require(not output.exists() and not output.is_relative_to(vectors.corpus.ROOT),
                                  'output must be a fresh file outside the repository')
        document = reclassify(args.run.resolve())
        with output.open('x') as stream:
            stream.write(json.dumps(document, indent=2) + '\n')
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    print(json.dumps({key: document[key] for key in ['cases', 'outcomes', 'full_identity_proofs', 'differences']}, indent=2))
    return bool(document['differences'])


if __name__ == '__main__':
    raise SystemExit(main())
