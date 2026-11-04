#!/usr/bin/env python3
"""Compare exact SMEM/launch probe assembly with an explicitly selected GPU."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess
import tarfile
import uuid

from probes import TARGETS, prepare, verify


def run(command: list[str], directory: Path, name: str, timeout: int = 120) -> str:
    result = subprocess.run(command, capture_output=True, text=True, timeout=timeout, cwd=directory)
    (directory / f'{name}.log').write_text(result.stdout + result.stderr)
    if result.returncode:
        raise RuntimeError(f'{name} failed (exit {result.returncode}); see {directory / (name + ".log")}')
    return result.stdout


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', choices=TARGETS, required=True)
    parser.add_argument('--host', required=True, help='SSH host with a matching GPU')
    parser.add_argument('--device', type=int, required=True, help='physical HIP device ordinal')
    parser.add_argument('--work-dir', type=Path, required=True)
    parser.add_argument('--volta', type=Path, required=True)
    parser.add_argument('--rocm', type=Path, default=Path('/opt/rocm'), help='local assembler/linker root')
    parser.add_argument('--remote-rocm', default='/opt/rocm', help='remote HIP headers/library root')
    args = parser.parse_args()
    if args.device < 0 or args.host.startswith('-'):
        parser.error('invalid device or host')
    directory = args.work_dir.resolve()
    repo = Path(__file__).resolve().parents[3]
    if directory == repo or repo in directory.parents:
        parser.error('work directory must be outside the repository')
    (directory / 'result.json').unlink(missing_ok=True)
    rows = prepare(directory, args.target)
    checks = verify(directory, args.target, args.volta.resolve(), rows)
    record = {'target': args.target, 'verifier_runs': checks, 'tools': {}, 'modules': {}}
    for tool in ('llvm-mc', 'ld.lld', 'llvm-readelf'):
        path = args.rocm / 'llvm' / 'bin' / tool
        record['tools'][tool] = {
            'version': run([str(path), '--version'], directory, tool + '-version'),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        }
    for row in rows:
        source = directory / (row.name + '.s')
        obj, module = source.with_suffix('.o'), source.with_suffix('.hsaco')
        run([str(args.rocm / 'llvm/bin/llvm-mc'), '--triple=amdgcn-amd-amdhsa',
             '--mcpu=' + args.target, '--filetype=obj', str(source), '-o', str(obj)],
            directory, row.name + '-assemble')
        run([str(args.rocm / 'llvm/bin/ld.lld'), '-shared', str(obj), '-o', str(module)],
            directory, row.name + '-link')
        symbols = run([str(args.rocm / 'llvm/bin/llvm-readelf'), '--symbols', '--wide', str(module)],
                      directory, row.name + '-symbols')
        for name, alignment in ((row.name, 256), (row.name + '.kd', 64)):
            values = re.findall(r'^\s*\d+:\s+([0-9a-fA-F]+)\s+.*\s' + re.escape(name) + r'$', symbols, re.M)
            if not values or any(int(value, 16) % alignment for value in values):
                raise ValueError(f'{name}: missing or misaligned ELF symbol')
        record['modules'][row.name] = {
            'assembly_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
            'module_sha256': hashlib.sha256(module.read_bytes()).hexdigest(),
        }
    archive = directory / 'probes.tar.gz'
    with tarfile.open(archive, 'w:gz') as tar:
        for row in rows:
            tar.add(directory / (row.name + '.hsaco'), arcname=row.name + '.hsaco')
        tar.add(directory / 'probes.hpp', arcname='probes.hpp')
        tar.add(Path(__file__).with_name('probes.cpp'), arcname='probes.cpp')
    remote = '/tmp/volta-amd-probes-' + uuid.uuid4().hex
    ssh = ['ssh', '-T', '-q', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', args.host]
    run(ssh + [shlex.join(['mkdir', '-m', '700', remote])], directory, 'remote-directory')
    run(['scp', '-q', '-o', 'BatchMode=yes', str(archive), args.host + ':' + remote + '/probes.tar.gz'],
        directory, 'copy')
    rocm = args.remote_rocm
    command = (
        shlex.join(['tar', '-xzf', remote + '/probes.tar.gz', '-C', remote]) + ' && '
        + shlex.join([rocm + '/llvm/bin/clang++', '-std=c++17', '-O2', '-Wall', '-Wextra', '-Werror',
                    '-D__HIP_PLATFORM_AMD__', '-I' + rocm + '/include', '-I' + remote,
                    remote + '/probes.cpp', '-L' + rocm + '/lib', '-lamdhip64',
                    '-Wl,-rpath,' + rocm + '/lib', '-o', remote + '/probes']) + ' && '
        + shlex.join(['env', 'HIP_VISIBLE_DEVICES=' + str(args.device), remote + '/probes',
                    args.target, remote]))
    stdout = run(ssh + [command], directory, 'hardware', timeout=180)
    summaries = [json.loads(line) for line in stdout.splitlines() if re.fullmatch(r'\{.*\}', line)]
    expected = {'status': 'pass', 'target': args.target, 'cases': len(rows),
                'outputs': sum(len(row.words()) for row in rows)}
    if summaries != [expected]:
        raise ValueError('hardware result omitted cases or outputs: ' + repr(summaries))
    record.update({'hardware': summaries[0], 'remote_directory': remote,
                   'binary_sha256': hashlib.sha256(args.volta.read_bytes()).hexdigest(),
                   'source_revision': run(['git', '-C', str(repo), 'rev-parse', 'HEAD'], directory, 'revision').strip(),
                   'source_tree_dirty': bool(run(['git', '-C', str(repo), 'status', '--porcelain'], directory, 'source-status').strip()),
                   'driver_sha256': hashlib.sha256(Path(__file__).with_name('probes.cpp').read_bytes()).hexdigest(),
                   'runner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                   'generator_sha256': hashlib.sha256(Path(__file__).with_name('probes.py').read_bytes()).hexdigest()})
    (directory / 'result.json').write_text(json.dumps(record, indent=2) + '\n')
    print(json.dumps(summaries[0]))


if __name__ == '__main__':
    main()
