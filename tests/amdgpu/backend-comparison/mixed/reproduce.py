#!/usr/bin/env python3
"""Reproduce the 26 prospective handwritten mixed-LGKM functional controls.

No compiler, GPU or timing endpoint is used. Supply two existing CLI binaries.
Inputs, source hashes and binary hashes are frozen before either arm executes.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

SOURCE_REVISION = '2bdedfdec2335e06b9ab3bff3a3a9eb3686ac488'
SOURCES = {
    'gfx942': 'dbd8859c3b9270fce8370a81e5f208a2eb415a9c8786f0d8736a99f8d9354e0e',
    'gfx950': '4da2ecf6fa2eb1ce847a83ef7a4928463b8a31183118ce7f6c41715ceeb4f743',
}
PROPERTIES = [
    'AMD trace completeness', 'AMD wait and register readiness',
    'AMD workgroup barrier generations', 'AMD memory-conflict freedom',
]
PARTIAL = 's_waitcnt lgkmcnt(1)'
STORE = 'global_store_dword v2, v10'
MUTATIONS = [
    ('wrong-vm-counter', PARTIAL, 's_waitcnt vmcnt(0)', 'ReadBeforeReady', STORE + ', s[6:7]'),
    ('missing-wait', PARTIAL, '', 'ReadBeforeReady', STORE + ', s[6:7]'),
    ('maximal-noop-lgkm', PARTIAL, 's_waitcnt lgkmcnt(15)', 'ReadBeforeReady', STORE + ', s[6:7]'),
    ('newest-lds-result', STORE, 'global_store_dword v2, v11', 'ReadBeforeReady', 'global_store_dword v2, v11, s[6:7]'),
    ('unordered-scalar-read', STORE, 's_mov_b32 s14, s12\n    ' + STORE, 'ReadBeforeReady', 's_mov_b32 s14, s12'),
    ('unordered-scalar-destination-reuse', STORE, 's_mov_b32 s12, 0\n    ' + STORE, 'DestinationReuse', 's_mov_b32 s12, 0'),
    ('newest-lds-destination-reuse', STORE, 'v_mov_b32 v11, 0\n    ' + STORE, 'DestinationReuse', 'v_mov_b32 v11, 0'),
    ('inactive-second-lds', 'ds_read_b32 v11, v2', 's_mov_b64 exec, 0\n    ds_read_b32 v11, v2\n    s_mov_b64 exec, -1', 'ReadBeforeReady', STORE + ', s[6:7]'),
]
SPEC = 'dim N;\narray x[N];\narray out[N];\nout[i] = x[i];\n'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_hash(path):
    return digest(Path(path).read_bytes())


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def replace_once(text, old, new):
    require(text.count(old) == 1, 'mutation anchor is not unique')
    return text.replace(old, new)


def contracts(sources):
    """Keep every safe geometry and every exact committed-test mutation."""
    cases = []
    for target in SOURCES:
        source = sources[target]
        require(digest(source.encode()) == SOURCES[target], 'source fixture hash changed')
        variants = [('partial-safe', source, block, 'safe_partial', None, None)
                    for block in [63, 64, 65, 128]]
        variants.append(('drain-safe', replace_once(source, PARTIAL, 's_waitcnt lgkmcnt(0)'), 64, 'safe_drain', None, None))
        variants.extend((name, replace_once(source, old, new), 64, 'unsafe', kind, use)
                        for name, old, new, kind, use in MUTATIONS)
        for mutation, assembly, block, role, kind, use in variants:
            cases.append({'id': f'{target}-{mutation}-b{block}', 'target': target,
                          'block': block, 'role': role, 'mutation': mutation,
                          'assembly': assembly, 'expected_hazard_kind': kind,
                          'expected_hazard_source': use, 'output_count': block})
    require(len(cases) == 26 and sum(c['output_count'] for c in cases) == 1792,
            'the frozen population changed')
    return cases


def launch(case):
    return {'kernel': 'mixed_lgkm_copy', 'block': [case['block'], 1, 1],
            'grid': [1, 1, 1], 'workgroup_id': [0, 0, 0],
            'early_readiness': False, 'early_memory_conflicts': False,
            'arrays': [{'name': 'x', 'base': '0x10000', 'elem_width': 4,
                        'len': case['block'], 'kind': 'in'},
                       {'name': 'out', 'base': '0x20000', 'elem_width': 4,
                        'len': case['block'], 'kind': 'out'}],
            'params': [{'ptr': 'x'}, {'ptr': 'out'}]}


def identity(text, count):
    """Check complete symbolic coordinates independently of the CLI prover."""
    lines = text.splitlines()
    if not lines or lines[0] != 'volta-expr 1':
        return False
    nodes, outputs = {}, {}
    for line in lines[1:]:
        node = re.fullmatch(r'n(\d+) = elem "([^"]+)" (\d+)', line)
        out = re.fullmatch(r'out "([^"]+)" (\d+) n(\d+)', line)
        if node:
            name, array, index = node.groups()
            if name in nodes:
                return False
            nodes[name] = (array, int(index))
        elif out:
            array, index, name = out.groups()
            key = (array, int(index))
            if key in outputs or name not in nodes:
                return False
            outputs[key] = nodes[name]
        else:
            return False
    return outputs == {('out', i): ('x', i) for i in range(count)}


def properties(text):
    rows = re.findall(r'^  (AMD [^\n]+?) \([^\n]*\) +(PASS|FAIL|UNKNOWN)$', text, re.M)
    require(len(rows) == 4 and [p for p, _ in rows] == PROPERTIES,
            'missing, duplicate or reordered native properties')
    return dict(rows)


def same_finding(text, kind, source):
    """Bind the kind AND intended source to one finding's use_event."""
    heading = re.search(r'^  AMD wait and register readiness \([^\n]*\) +(PASS|FAIL|UNKNOWN)\n(?P<body>.*?)(?=^  AMD |^GRAPH VERIFICATION:|\Z)', text, re.M | re.S)
    if not heading:
        return False
    blocks = re.findall(r'^      AmdRegisterHazard[^\n]*\n(?:^        [^\n]*\n)+', heading['body'], re.M)
    for block in blocks:
        use = re.search(r'use_event: EventId\((\d+)\)', block)
        if use and re.search(r'kind: ' + re.escape(kind) + r' \}', block):
            pattern = r'^        e' + use[1] + r' \w+ +line \d+: ' + re.escape(source) + '$'
            if re.search(pattern, block, re.M):
                return True
    return False


def diagnostics_clean(text):
    # Successful export messages contain caller-selected paths, not verdicts.
    lines = [line for line in text.splitlines()
             if not line.startswith(('Wrote output expressions to ', 'Wrote event graph to '))]
    return re.search(r'unknown|unsupported|aborted|panic|analysis failed|error:|not equivalent|counterexample|certified.*reject|early[_ -]', '\n'.join(lines), re.I) is None


def inspect(case, arm, analysis, proof, expressions, graph, analysis_code, proof_code,
            *, analysis_stderr='', proof_stderr='', analysis_timed_out=False, proof_timed_out=False):
    """Return explicit public observations; aborts and missing outputs cannot qualify."""
    try:
        observed = properties(analysis)
    except ValueError:
        observed = {}
    try:
        proof_properties = properties(proof)
    except ValueError:
        proof_properties = {}
    complete = not analysis_timed_out and analysis_code in [0, 1] and re.findall(r'^terminal (.+)$', graph, re.M) == ['completed']
    analysis_clean = (not analysis_timed_out and analysis_code in [0, 1] and diagnostics_clean(analysis + '\n' + analysis_stderr)
                      and re.search(r'^VERDICT:', analysis, re.M) is None)
    proof_clean = (not proof_timed_out and proof_code in [0, 1] and diagnostics_clean(proof + '\n' + proof_stderr)
                  and re.search(r'^GRAPH VERIFICATION:', proof, re.M) is None)
    output_identity = identity(expressions, case['output_count'])
    checked = re.findall(r'^VC check: [^\n]* elements: (\d+)$', proof, re.M)
    math_proved = proof_clean and proof_code in [0, 1] and checked == [str(case['output_count'])] and re.findall(r'^EQUIVALENT \(matches spec\)$', proof, re.M) == ['EQUIVALENT (matches spec)']
    all_pass = dict.fromkeys(PROPERTIES, 'PASS')
    hazard_properties = {**all_pass, PROPERTIES[1]: 'FAIL'}
    accepted = complete and analysis_clean and observed == all_pass and re.findall(r'^GRAPH VERIFICATION: (\w+) ', analysis, re.M) == ['VERIFIED'] and analysis_code == 0
    rejected = complete and analysis_clean and len(observed) == 4 and 'UNKNOWN' not in observed.values() and re.findall(r'^GRAPH VERIFICATION: (\w+) ', analysis, re.M) == ['REJECTED'] and analysis_code == 1
    unsafe = case['role'] == 'unsafe'
    matched = same_finding(analysis, case['expected_hazard_kind'], case['expected_hazard_source']) if unsafe else None
    false_positive = not unsafe and rejected and observed == hazard_properties
    expect_reject = unsafe or (arm == 'baseline' and case['role'] == 'safe_partial')
    expected = dict.fromkeys(PROPERTIES, 'PASS')
    if expect_reject:
        expected[PROPERTIES[1]] = 'FAIL'
    verdict = re.findall(r'^VERDICT: (\w+)$', proof, re.M)
    passed = (complete and analysis_clean and proof_clean and output_identity and math_proved and observed == expected
              and proof_properties == expected and (rejected if expect_reject else accepted)
              and verdict == ['REJECT' if expect_reject else 'ACCEPT']
              and proof_code == int(expect_reject) and (matched if unsafe else True))
    return {'execution_completed': complete, 'graph_properties': observed,
            'accepted': accepted, 'expected_hazard_rejected': unsafe and rejected and matched and observed == hazard_properties,
            'safe_false_positive': false_positive, 'unsafe_false_acceptance': unsafe and accepted,
            'same_finding_typed_source_match': matched, 'full_coordinate_identity': output_identity,
            'diagnostic_controls_pass': analysis_clean and proof_clean,
            'analysis_timed_out': analysis_timed_out, 'proof_timed_out': proof_timed_out,
            'proof_graph_properties': proof_properties,
            'configured_output_coordinates': {'out': list(range(case['output_count']))},
            'observed_output_count': len(re.findall(r'^out ', expressions, re.M)),
            'full_math_proof': {'equivalent': math_proved, 'checked_elements': int(checked[0]) if len(checked) == 1 else None, 'sample': 0},
            'expected_behavior_pass': passed, 'full_graph_sha256': digest(graph.encode()),
            'full_output_sha256': digest(expressions.encode())}


def public_case(case, arms, hashes):
    return {'id': case['id'], 'target': case['target'], 'mutation': case['mutation'],
            'block': [case['block'], 1, 1], 'grid': [1, 1, 1],
            'workgroup': [0, 0, 0], 'role': case['role'],
            'output_count': case['output_count'], 'expected_hazard_kind': case['expected_hazard_kind'],
            'expected_source_instruction': case['expected_hazard_source'],
            'input_hashes': hashes, 'arms': arms}


def public_report(cases, provenance, hashes):
    require(len(cases) == 26 and len({c['id'] for c in cases}) == 26, 'all26 cases required')
    summary = {}
    for arm in ['baseline', 'candidate']:
        rows = [case['arms'][arm] for case in cases]
        summary[arm] = {'configurations': len(rows), 'safe_configurations': 10,
                        'seeded_hazard_configurations': 16, 'configured_coordinates': 1792,
                        'completed': sum(r['execution_completed'] for r in rows),
                        'safe_accepted': sum(r['accepted'] and c['role'] != 'unsafe' for c, r in zip(cases, rows)),
                        'safe_false_positives': sum(r['safe_false_positive'] for r in rows),
                        'expected_hazards_rejected': sum(r['expected_hazard_rejected'] for r in rows),
                        'unsafe_false_acceptances': sum(r['unsafe_false_acceptance'] for r in rows),
                        'full_coordinate_identity': sum(r['full_coordinate_identity'] for r in rows),
                        'full_math_proofs': sum(r['full_math_proof']['equivalent'] for r in rows),
                        'expected_behavior_pass': sum(r['expected_behavior_pass'] for r in rows)}
    return {'schema': 1, 'study': 'prospective_handwritten_mixed_lgkm_controls',
            'scope': '26 prospective handwritten configurations, separate from the 67 wide-kernel study. This functional study checks mixed-LGKM acceptance and seeded-hazard retention. No new application bugs, hardware results or performance gains are claimed.',
            'models': {'execution': 'Eager data with independently checked readiness graph',
                       'outputs': 'Symbolic mathematical input elements copied as exact words; all configured coordinates',
                       'math_proof': 'Full identity specification; sample 0; independent coordinate/identity parser',
                       'numerical_sampling': False, 'hardware_execution': False, 'timing_measurement': False},
            'provenance': provenance, 'hashes': hashes, 'summary': summary, 'cases': cases}


def invoke(command, directory):
    directory.mkdir()
    write_json(directory / 'command.json', command)
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60, check=False)
        stdout, stderr, code = result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired as error:
        stdout, stderr, code = error.stdout or b'', error.stderr or b'', None
        timed_out = True
    except OSError as error:
        stdout, stderr, code = b'', str(error).encode(), None
        timed_out = False
    else:
        timed_out = False
    (directory / 'stdout').write_bytes(stdout)
    (directory / 'stderr').write_bytes(stderr)
    write_json(directory / 'status.json', {'returncode': code, 'timed_out': timed_out})
    return stdout.decode(errors='replace'), code, stderr.decode(errors='replace'), timed_out


def check_frozen(output, binaries, freeze, record_hash):
    require(file_hash(output / 'freeze.json') == record_hash, 'frozen protocol record changed')
    require(file_hash(__file__) == freeze['helper_sha256'], 'helper changed after freeze')
    require(all(file_hash(binary) == freeze['binaries'][arm] for arm, binary in binaries.items()), 'binary changed after freeze')
    require(all(file_hash(output / path) == expected for path, expected in freeze['inputs'].items()), 'input changed after freeze')


def require_external_output(output, roots):
    require(all(not output.resolve().is_relative_to(root.resolve()) for root in roots),
            'reproduction output must be outside the source and helper repositories')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--source-revision', default=SOURCE_REVISION)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    binaries = {arm: getattr(args, arm).resolve() for arm in ['baseline', 'candidate']}
    source_root = Path(subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], cwd=args.source_root).decode().strip())
    helper = subprocess.run(['git', 'rev-parse', '--show-toplevel'], cwd=Path(__file__).resolve().parent, capture_output=True, check=False)
    helper_root = Path(helper.stdout.decode().strip()) if helper.returncode == 0 else Path(__file__).resolve().parent
    require_external_output(args.output, [source_root, helper_root])
    args.output.mkdir(parents=True, exist_ok=False)
    revision = subprocess.check_output(['git', 'rev-parse', '--verify', '--end-of-options', f'{args.source_revision}^{{commit}}'], cwd=args.source_root).decode().strip()
    require(re.fullmatch('[0-9a-f]{40}', revision), 'source commit is not an exact 40-hex revision')
    sources = {target: subprocess.check_output(['git', 'show', f'{revision}:tests/amdgpu/native-mixed-lgkm/{target}.s'], cwd=args.source_root).decode() for target in SOURCES}
    cases = contracts(sources)
    for case in cases:
        directory = args.output / 'inputs' / case['id']
        directory.mkdir(parents=True)
        (directory / 'kernel.s').write_text(case['assembly'])
        (directory / 'identity.spec').write_text(SPEC)
        write_json(directory / 'launch.json', launch(case))
        write_json(directory / 'expected.json', {'out': [{'index': i, 'input': 'x', 'input_index': i} for i in range(case['output_count'])]})
    files = {str(p.relative_to(args.output)): file_hash(p) for p in sorted((args.output / 'inputs').rglob('*')) if p.is_file()}
    freeze = {'schema': 1, 'source_revision': revision,
              'source_tree': subprocess.check_output(['git', 'rev-parse', f'{revision}^{{tree}}'], cwd=args.source_root).decode().strip(),
              'sources': SOURCES, 'helper_sha256': file_hash(__file__),
              'binaries': {arm: file_hash(binary) for arm, binary in binaries.items()},
              'inputs': files, 'configurations': 26, 'coordinates_per_arm': 1792,
              'protocol': 'One complete analyze+graph+output export and full identity-spec proof per arm; no early options, retries, filtering or timing endpoint.'}
    write_json(args.output / 'freeze.json', freeze)  # Always before either binary is invoked.
    record_hash = file_hash(args.output / 'freeze.json')
    rows = []
    for case in cases:
        directory = args.output / 'inputs' / case['id']
        arms = {}
        for arm, binary in binaries.items():
            check_frozen(args.output, binaries, freeze, record_hash)
            out = args.output / 'raw' / arm / case['id']
            out.mkdir(parents=True)
            shared = [str(binary), '--no-log-file', '--backend', 'amdgpu', '--target', case['target']]
            analyzed, acode, aerr, atimeout = invoke(shared + ['analyze', str(directory / 'kernel.s'), '--config', str(directory / 'launch.json'), '--no-profile', '--print-outputs', '0', '--emit-exprs', str(out / 'actual.vexpr'), '--dump-graph', str(out / 'graph.txt')], out / 'analysis')
            check_frozen(args.output, binaries, freeze, record_hash)
            proof, pcode, perr, ptimeout = invoke(shared + ['verify', str(directory / 'kernel.s'), str(directory / 'identity.spec'), '--config', str(directory / 'launch.json'), '--no-profile', '--dim', f'N={case["block"]}', '--sample', '0'], out / 'proof')
            check_frozen(args.output, binaries, freeze, record_hash)
            read = lambda name: (out / name).read_text() if (out / name).is_file() else ''
            # Failed/aborted runs still produce a row and remain in the denominator.
            arms[arm] = inspect(case, arm, analyzed, proof, read('actual.vexpr'), read('graph.txt'), acode, pcode, analysis_stderr=aerr, proof_stderr=perr, analysis_timed_out=atimeout, proof_timed_out=ptimeout)
        rows.append(public_case(case, arms, {p.name: file_hash(p) for p in sorted(directory.iterdir())}))
    check_frozen(args.output, binaries, freeze, record_hash)
    # Binary revisions require a separate build attestation; a binary hash alone cannot establish them.
    provenance = {'source_revision': freeze['source_revision'], 'source_tree': freeze['source_tree'],
                  'source_fixture_sha256': SOURCES, 'binary_sha256': freeze['binaries'],
                  'binary_source_attestation': 'Not supplied; identify/build the two revisions separately.'}
    report = public_report(rows, provenance, {'freeze_sha256': file_hash(args.output / 'freeze.json'), 'reproduction_helper_sha256': file_hash(__file__)})
    write_json(args.output / 'results.json', report)
    print(json.dumps(report['summary'], indent=2))
    raise SystemExit(0 if all(row['arms'][arm]['expected_behavior_pass'] for row in rows for arm in binaries) else 1)


if __name__ == '__main__':
    main()
