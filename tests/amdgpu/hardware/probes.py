#!/usr/bin/env python3
"""Generate safe integer SMEM/launch probes and compare complete verifier outputs.

Generated assembly, code objects, receipts, and device observations belong in
an external work directory. The same assembly is consumed by the verifier and
the HIP module loader; no compiler-generated replacement kernel is used.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import re
import subprocess


TARGETS = ("gfx942", "gfx950", "gfx1250")


@dataclass(frozen=True)
class Case:
    name: str
    kind: str
    width: int = 4
    base: int = 0
    displacement: int = 0
    immediate: int = 0
    scale: bool = False
    axes: tuple[int, int, int] = (0, 0, 0)

    @property
    def grid(self) -> tuple[int, int, int]:
        return tuple(n if enabled else 1 for n, enabled in zip((2, 3, 2), self.axes))

    def words(self) -> list[int]:
        if self.kind == "smem":
            # The CPU reference masks each byte-address component independently.
            alignment = min(self.width, 4) - 1
            offset = ((self.base & ~alignment)
                      + ((self.displacement * (self.width if self.scale else 1)) & ~alignment)
                      + (self.immediate & ~alignment))
            payload = bytes(range(128))[offset:offset + self.width]
            assert len(payload) == self.width
            return [int.from_bytes(payload[i:i + 4], "little")
                    for i in range(0, self.width, 4)]
        nx, ny, nz = self.grid
        result = []
        for z in range(nz):
            for y in range(ny):
                for x in range(nx):
                    for local in range(64):
                        # TTMP8 exposes local wave ID, GridYZvalid, and DebugMark.
                        flags = ((int(bool(self.axes[1] or self.axes[2])) << 30)
                                 | ((local // 32) << 25))
                        result.extend((x, y, z, flags))
        return result


def cases(target: str) -> list[Case]:
    widths = (1, 2, 4, 8, 12, 16) if target == "gfx1250" else (4, 8, 16)
    result = []
    for width in widths:
        for base, displacement, immediate in ((3, 3, 3), (1, 5, 7), (2, 3, 3), (3, 2, 1)):
            result.append(Case(f"smem_{width}_{base}_{displacement}_{immediate}",
                               "smem", width, base, displacement, immediate))
        if target == "gfx1250":
            result.append(Case(f"smem_{width}_scaled", "smem", width, 3, 1, 3, True))
    for axes in ((1, 0, 0), (0, 1, 1), (1, 1, 1), (0, 0, 0)):
        result.append(Case("launch_" + "".join(map(str, axes)), "launch", axes=axes))
    return result


def assembly(target: str, case: Case) -> str:
    wave32 = target == "gfx1250"
    add = "s_add_co_u32" if wave32 else "s_add_u32"
    wait = "s_wait_kmcnt 0" if wave32 else "s_waitcnt lgkmcnt(0)"
    store = "global_store_b32" if wave32 else "global_store_dword"
    loadptr = "s_load_b128" if wave32 else "s_load_dwordx4"
    finish = "s_wait_storecnt 0\ns_wait_xcnt 0\ns_endpgm" if wave32 else "s_endpgm"
    if case.kind == "smem":
        load = (f"s_load_{'u' + str(case.width * 8) if case.width < 4 else 'b' + str(case.width * 8)}"
                if wave32 else "s_load_dword" + (f"x{case.width // 4}" if case.width > 4 else ""))
        count = max(1, case.width // 4)
        dest = "s12" if count == 1 else f"s[12:{11 + count}]"
        body = [f"{loadptr} s[4:7], s[0:1], 0", wait,
                f"{add} s4, s4, {case.base}",
                f"s_mov_b32 s8, {case.displacement}",
                f"{load} {dest}, s[4:5], s8 offset:{case.immediate}"
                + (" scale_offset" if case.scale else ""), wait]
        for i in range(count):
            body.extend((f"{add} s{12 + i}, s{12 + i}, 0",
                         f"v_mov_b32 v{1 + 2 * i}, {4 * i}",
                         f"v_mov_b32 v{2 + 2 * i}, s{12 + i}",
                         f"{store} v{1 + 2 * i}, v{2 + 2 * i}, s[6:7]"))
        args = ("input", "out")
    else:
        ptrload = "s_load_b64" if wave32 else "s_load_dwordx2"
        body = [f"{ptrload} s[8:9], s[0:1], 0", wait]
        if wave32:
            body.extend((f"s_mov_b32 s12, {'ttmp9' if case.axes[0] else '0'}",))
            if case.axes[1] or case.axes[2]:
                body.extend(("s_bfe_u32 s13, ttmp7, 0x100000",
                             "s_bfe_u32 s14, ttmp7, 0x100010"))
            else:
                body.extend(("s_mov_b32 s13, 0", "s_mov_b32 s14, 0"))
            body.append("s_and_b32 s15, ttmp8, 0xfe000000")
        else:
            next_sgpr = 2
            for axis, enabled in enumerate(case.axes):
                body.append(f"s_mov_b32 s{12 + axis}, " + (f"s{next_sgpr}" if enabled else "0"))
                next_sgpr += enabled
            # There is no TTMP8 contract in the CDNA3/4 ABI being exercised.
            body.append("s_mov_b32 s15, 0")
        nx, ny, _ = case.grid
        body.extend((f"s_mul_i32 s16, s14, {ny}", f"{add} s16, s16, s13",
                     f"s_mul_i32 s16, s16, {nx}", f"{add} s16, s16, s12",
                     "s_mul_i32 s16, s16, 64",
                     f"{'v_add_nc_u32' if wave32 else 'v_add_u32'} v2, s16, v0",
                     "v_lshlrev_b32 v2, 4, v2"))
        for i in range(4):
            body.extend((f"v_mov_b32 v{3 + i}, s{12 + i}",
                         f"{store} v2, v{3 + i}, s[8:9] offset:{4 * i}"))
        args = ("out",)
    body.append(finish)
    descriptor = f"""
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel {case.name}
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size {8 * len(args)}
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_sgpr_workgroup_id_x {case.axes[0]}
.amdhsa_system_sgpr_workgroup_id_y {case.axes[1]}
.amdhsa_system_sgpr_workgroup_id_z {case.axes[2]}
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 32
.amdhsa_next_free_vgpr 16
{'.amdhsa_wavefront_size32 1' if wave32 else '.amdhsa_accum_offset 16'}
.end_amdhsa_kernel
"""
    metadata_args = "\n".join(
        f"      - .name: {name}\n        .offset: {i * 8}\n        .size: 8\n"
        "        .value_kind: global_buffer\n        .address_space: global\n        .value_type: u32"
        for i, name in enumerate(args))
    return f""".amdgcn_target "amdgcn-amd-amdhsa--{target}"
.amdhsa_code_object_version 6
.text
.globl {case.name}
.type {case.name},@function
.p2align 8
{case.name}:
{chr(10).join(body)}
.Lend:
.size {case.name}, .Lend-{case.name}
{descriptor}
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: {case.name}
    .symbol: {case.name}.kd
    .kernarg_segment_size: {8 * len(args)}
    .kernarg_segment_align: 8
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .sgpr_count: 32
    .vgpr_count: 16
    .wavefront_size: {32 if wave32 else 64}
    .max_flat_workgroup_size: 1024
    .args:
{metadata_args}
...
.end_amdgpu_metadata
"""


def constant_outputs(path: Path) -> dict[int, int]:
    lines = path.read_text().splitlines()
    if not lines or lines[0] != "volta-expr 1":
        raise ValueError("missing expression export")
    constants, outputs = {}, {}
    for line in lines[1:]:
        if match := re.fullmatch(r"n(\d+) = int (-?\d+)", line):
            constants[int(match[1])] = int(match[2])
        elif match := re.fullmatch(r'out "out" (\d+) n(\d+)', line):
            index, node = map(int, match.groups())
            if index in outputs or node not in constants:
                raise ValueError("duplicate, missing, or nonconstant output")
            outputs[index] = constants[node]
        elif line.startswith("out "):
            raise ValueError("unexpected output array")
    return outputs


def expected_outputs(target: str, case: Case) -> list[int]:
    words = case.words()
    if case.kind == "launch" and target != "gfx1250":
        words[3::4] = [0] * (len(words) // 4)
    return words


def prepare(directory: Path, target: str) -> list[Case]:
    directory.mkdir(parents=True, exist_ok=True)
    rows = cases(target)
    for row in rows:
        (directory / f"{row.name}.s").write_text(assembly(target, row))
    (directory / "cases.json").write_text(json.dumps({
        "target": target,
        "cases": [dict(asdict(c), grid=c.grid, expected=expected_outputs(target, c)) for c in rows],
    }, indent=2) + "\n")
    # A plain generated header keeps the native driver dependency-free.
    header = ['struct Probe { const char *name; unsigned nx, ny, nz; bool scalar; std::vector<uint32_t> expected; };',
              'static const Probe probes[] = {']
    for c in rows:
        header.append('{"' + c.name + '",' + ','.join(map(str, c.grid)) + ','
                      + ('true' if c.kind == 'smem' else 'false') + ',{'
                      + ','.join(str(v) + 'u' for v in expected_outputs(target, c)) + '}},')
    header.append('};')
    (directory / "probes.hpp").write_text('\n'.join(header) + '\n')
    return rows


def verify(directory: Path, target: str, binary: Path, rows: list[Case]) -> list[dict]:
    results = []
    for row in rows:
        expected = expected_outputs(target, row)
        coordinates = [(0, 0, 0)]
        last = tuple(v - 1 for v in row.grid)
        if last != coordinates[0]:
            coordinates.append(last)
        for coords in coordinates:
            expression = directory / (row.name + '-' + ''.join(map(str, coords)) + '.vexpr')
            expression.unlink(missing_ok=True)
            command = [str(binary), 'analyze', str(directory / (row.name + '.s')),
                       '--backend', 'amdgpu', '--target', target, '--kernel', row.name,
                       '--block', '1' if row.kind == 'smem' else '64',
                       '--grid', ','.join(map(str, row.grid)),
                       '--workgroup-id', ','.join(map(str, coords)),
                       '--array', f'out:0x30000:4:{len(expected)}:out']
            if row.kind == 'smem':
                command.extend(('--array', 'input:0x10000:1:128:index', '--param', 'ptr:input'))
            command.extend(('--param', 'ptr:out', '--emit-exprs', str(expression), '--print-outputs', '0'))
            run = subprocess.run(command, capture_output=True, text=True, timeout=60, cwd=directory)
            (directory / (expression.stem + '.log')).write_text(run.stdout + run.stderr)
            if run.returncode != 0:
                raise RuntimeError(f'{row.name}: verifier failed; see {expression.stem}.log')
            actual = constant_outputs(expression)
            if row.kind == 'smem':
                required = dict(enumerate(expected))
            else:
                x, y, z = coords
                nx, ny, _ = row.grid
                start = ((z * ny + y) * nx + x) * 64 * 4
                required = {i: expected[i] for i in range(start, start + 64 * 4)}
            if actual != required:
                raise ValueError(f'{row.name}: complete absolute index/value mismatch at {coords}')
            results.append({'case': row.name, 'workgroup_id': coords, 'outputs': len(actual)})
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', choices=TARGETS, required=True)
    parser.add_argument('--work-dir', type=Path, required=True)
    parser.add_argument('--volta', type=Path)
    args = parser.parse_args()
    directory = args.work_dir.resolve()
    repo = Path(__file__).resolve().parents[3]
    if directory == repo or repo in directory.parents:
        parser.error('work directory must be outside the repository')
    (directory / 'verifier-result.json').unlink(missing_ok=True)
    rows = prepare(directory, args.target)
    result = {'target': args.target, 'cases': len(rows), 'assembly_sha256': {
        c.name: hashlib.sha256((directory / (c.name + '.s')).read_bytes()).hexdigest()
        for c in rows}}
    if args.volta:
        result['verifier'] = verify(directory, args.target, args.volta.resolve(), rows)
    (directory / 'verifier-result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'target': args.target, 'cases': len(rows),
                      'verifier_runs': len(result.get('verifier', []))}))


if __name__ == '__main__':
    main()
