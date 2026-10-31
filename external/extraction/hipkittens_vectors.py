# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6,<7"]
# ///
"""Verify every original CDNA4 register-vector copy specialization, without a GPU.

The complete upstream module is reused unchanged. Launches follow wrapper_1d
and reg_vec_load_store in the exact pinned source, including its original full
length, one-wave launch, dynamic LDS request, dtype and register layout.
"""
from __future__ import annotations

import argparse
from collections import Counter
import itertools
import json
from pathlib import Path
import re
import struct

import hipkittens_corpus as corpus
import hipkittens_inventory as inventory

SOURCE = "tests/unit/cdna4/warp/memory/vec/global_to_register.cu"
SOURCE_INPUTS = (
    SOURCE,
    "tests/unit/common/testing_commons/testing_commons.cuh",
    "tests/unit/common/testing_commons/testing_flags.cuh",
    "include/cdna4/common/util.cuh",
    "include/cdna4/types/global/gl.cuh",
    "include/cdna4/types/global/util.cuh",
)
SHAPES = {(16, 32, 8), (32, 16, 8), (16, 16, 4), (32, 32, 4),
          (32, 32, 8), (16, 32, 4), (32, 16, 4)}
DTYPES = {"f": "f32", "14__hip_bfloat16": "bf16", "6__half": "f16"}
LAYOUTS = {"naive", "ortho", "align"}
EXPECTED_PROPERTIES = {
    "AMD trace completeness", "AMD wait and register readiness",
    "AMD workgroup barrier generations", "AMD memory-conflict freedom",
}
SPEC = "dim N; array x[N]; array out[N]; out[i] = x[i];\n"
WRONG_SPEC = "dim N; array x[N]; array out[N]; out[i] = x[i] + 1;\n"
SYMBOL = re.compile(
    r"_ZL17global_wrapper_1dI18reg_vec_load_storeI(?P<dtype>f|14__hip_bfloat16|6__half)E"
    r"N7kittens5ducks8rt_shape8rt_shapeILi(?P<rows>\d+)ELi(?P<cols>\d+)ELi(?P<packing>\d+)EEE"
    r"NS(?P<ns>[34])_8st_shape8st_16x16E(?P<value>f|S1_)Li(?P<size>\d+)ELi(?P<workers>\d+)E"
    r"TkNS(?P=ns)_2gl3allENS(?P<gl>[23])_2glI(?P=value)Li1ELi1ELi1ELi(?P<elements>\d+)EJEEE"
    r"JNS(?P=ns)_9rv_layout5(?P<layout>naive|ortho|align)EEEvT5_S(?P<end>[EF])_"
)


def decode_kernel(kernel):
    """Decode this source's finite emitted family; refuse any unfamiliar symbol."""
    match = SYMBOL.fullmatch(kernel[".name"])
    inventory.require(match is not None, "unrecognized original vector specialization")
    values = match.groupdict()
    dtype = DTYPES[values["dtype"]]
    substitution = ("3", "2", "f", "E") if dtype == "f32" else ("4", "3", "S1_", "F")
    inventory.require(tuple(values[key] for key in ("ns", "gl", "value", "end")) == substitution,
                      "inconsistent specialization type substitutions")
    shape = tuple(int(values[key]) for key in ("rows", "cols", "packing"))
    size, workers, elements = (int(values[key]) for key in ("size", "workers", "elements"))
    inventory.require(shape in SHAPES and 1 <= size <= 4 and workers == 1,
                      "specialization differs from original TEST_INTENSITY=2 sweep")
    inventory.require(elements == size * shape[1], "specialization disagrees with host SIZE=S*RT_SHAPE::cols")
    inventory.require(kernel.get(".wavefront_size") == 64, "original CDNA4 vector wave size changed")
    inventory.require(kernel.get(".group_segment_fixed_size") == 0 and kernel.get(".kernarg_segment_size") == 32,
                      "original vector segment ABI changed")
    args = kernel.get(".args", [])
    inventory.require(len(args) == 2 and all(
        arg.get(".value_kind") == "by_value" and arg.get(".offset") == offset and arg.get(".size") == 16
        for arg, offset in zip(args, (0, 16))), "original vector GL by-value ABI changed")
    identifier = f"{dtype}-rt{shape[0]}x{shape[1]}x{shape[2]}-s{size}-{values['layout']}"
    return {"id": identifier, "kernel": kernel[".name"], "dtype": dtype, "rt_shape": list(shape),
            "size_multiplier": size, "workers": workers, "layout": values["layout"], "elements": elements}


def make_cases(kernels):
    cases = [decode_kernel(kernel) for kernel in kernels]
    keys = [(row["dtype"], tuple(row["rt_shape"]), row["size_multiplier"], row["layout"]) for row in cases]
    expected = set(itertools.product(DTYPES.values(), SHAPES, range(1, 5), LAYOUTS))
    inventory.require(len(keys) == len(set(keys)) == len(expected) and set(keys) == expected,
                      "missing, duplicate or extra original vector specializations")
    return sorted(cases, key=lambda row: row["id"])


def launch(case):
    def array(name, base, kind):
        return {"name": name, "base": base, "dtype": case["dtype"], "shape": [case["elements"]], "kind": kind}

    return {"kernel": case["kernel"], "block": [64, 1, 1], "grid": [1, 1, 1],
            "workgroup_id": [0, 0, 0], "dynamic_shared_bytes": 80000,
            "arrays": [array("x", 0x10000, "in"), array("out", 0x20000, "out")],
            "params": [{"bytes": list(struct.pack("<Q8x", base))} for base in (0x10000, 0x20000)]}


def layout_check_source(cases):
    """Check every instantiated GL layout with the same native compiler target."""
    lines = ['#include "kittens.cuh"', '#include <cstddef>']
    types = {"f32": "float", "bf16": "kittens::bf16", "f16": "kittens::half"}
    for index, (dtype, count) in enumerate(sorted({(row["dtype"], row["elements"]) for row in cases})):
        name = "OriginalGL" + str(index)
        lines += [f"using {name} = kittens::gl<{types[dtype]}, 1, 1, 1, {count}>;",
                  f"static_assert(sizeof({name}) == 16 && alignof({name}) == 8);",
                  f"static_assert(offsetof({name}, raw_ptr) == 0);"]
    return "\n".join(lines) + "\n"


def classify_verify(record, stdout, stderr, elements):
    if record["status"] != "succeeded" and record["status"] != "rejected":
        return record["status"]
    checks = re.findall(r"(?m)^  (\S.*?) \([^\n)]*\)\s+(PASS|FAIL|UNKNOWN)$", stdout)
    names = [name for name, _ in checks]
    counts = re.findall(r"(?m)^VC check: [^\n]*  elements: (\d+)(?:/(\d+))?$", stdout)
    verdicts = re.findall(r"(?m)^VERDICT: (ACCEPT|REJECT|UNKNOWN)$", stdout)
    complete_checks = (len(names) == len(set(names)) and EXPECTED_PROPERTIES <= set(names)
                       and all(verdict == "PASS" for _, verdict in checks))
    if "ACCEPT" in verdicts:
        inventory.require(record["returncode"] == 0 and verdicts == ["ACCEPT"], "inconsistent mathematical acceptance")
        inventory.require(complete_checks, "incomplete or failing graph checks")
        inventory.require(counts == [(str(elements), "")], "incomplete or shifted full specification count")
        inventory.require("EQUIVALENT (matches spec)" in stdout, "missing mathematical equivalence proof")
        inventory.require("NOT EQUIVALENT" not in stdout, "contradictory mathematical outcomes")
        return "verified"
    if record["returncode"] == 0:
        raise ValueError("successful process lacks a complete verification result")
    if ("NOT EQUIVALENT" in stdout and verdicts == ["REJECT"] and complete_checks
            and counts == [(str(elements), "")]):
        return "mathematical_mismatch"
    if re.search(r"unsupported (?:AMD|gfx950) instruction", stdout + stderr, re.I):
        return "unsupported"
    if verdicts == ["REJECT"] and any(value == "FAIL" for _, value in checks):
        return "graph_rejected"
    if verdicts == ["UNKNOWN"] or any(value == "UNKNOWN" for _, value in checks):
        return "inconclusive"
    return "execution_or_driver_error"


def load_module(campaign, source_document):
    report_path = campaign / "report.json"
    report = json.loads(report_path.read_text())
    inventory.require(report["source_revision"] == inventory.REVISION, "campaign source revision changed")
    rows = [row for row in report["results"] if row["source"] == SOURCE and row["profile"]["target"] == "gfx950"]
    inventory.require(len(rows) == 1, "missing or duplicate original vector module")
    row = rows[0]
    inventory.require(row["source_sha256"] == source_document["source_sha256"][SOURCE], "campaign vector source changed")
    directory = campaign / row["id"]
    assembly, obj = directory / "kernel.s", directory / "kernel.o"
    inventory.require(inventory.sha(assembly.read_bytes()) == row["assembly_sha256"]
                      and inventory.sha(obj.read_bytes()) == row["object_sha256"], "stale original module artifacts")
    compile_record = json.loads((directory / "compile.json").read_text())
    assemble_record = json.loads((directory / "assemble.json").read_text())
    inventory.require(all(item["status"] == "succeeded" and item["returncode"] == 0
                          for item in (compile_record, assemble_record)), "original module compile/MC did not succeed")
    inventory.require("-DTEST_ALL" in compile_record["command"] and "-DTEST_INTENSITY=2" in compile_record["command"],
                      "original template sweep changed")
    kernels = corpus.metadata(assembly.read_text(), "gfx950")
    inventory.require(kernels == row["emitted_kernels"], "stored metadata differs from complete original assembly")
    return assembly, obj, make_cases(kernels), report_path, compile_record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=inventory.DEFAULT_SOURCE)
    parser.add_argument("--campaign", type=Path, required=True, help="Complete-source campaign containing the original vector module")
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--binary-revision", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--compiler", type=Path, default=Path('/opt/rocm/llvm/bin/clang++'))
    parser.add_argument("--timeout", type=float, default=60)
    args = parser.parse_args()
    try:
        inventory.require(args.timeout > 0, "positive timeout required")
        source_root = args.source_root.resolve()
        document = inventory.build_inventory(source_root)
        inventory.require(document == json.loads(inventory.DEFAULT_OUTPUT.read_text()), "source inventory drifted")
        assembly, obj, cases, source_report, compile_record = load_module(args.campaign.resolve(), document)
        output = args.output.resolve()
        inventory.require(not output.is_relative_to(corpus.ROOT) and not output.is_relative_to(source_root), "raw output must remain outside source repositories")
        output.mkdir(parents=True, exist_ok=False)
        binary = args.binary.resolve(strict=True)
        input_paths = {"driver": Path(__file__), "inventory": Path(inventory.__file__), "corpus": Path(corpus.__file__),
                       "legacy_import": Path(corpus.legacy.__file__),
                       "source_inventory": inventory.DEFAULT_OUTPUT, "assembly": assembly, "object": obj,
                       "source_report": source_report, "binary": binary, "compiler": args.compiler}
        hashes = {name: inventory.sha(path.read_bytes()) for name, path in input_paths.items()}
        inventory.require(hashes['compiler'] == json.loads(source_report.read_text())['compiler_sha256'],
                          "layout compiler differs from the original module compiler")
        identity = {"schema_version": 1, "source_revision": inventory.REVISION, "target": "gfx950", "wave_size": 64,
                    "source": SOURCE, "source_sha256": {path: document["source_sha256"][path] for path in SOURCE_INPUTS},
                    "binary_revision": args.binary_revision, "input_sha256": hashes, "timeout_seconds": args.timeout,
                    "spec_sha256": inventory.sha(SPEC.encode()), "wrong_spec_sha256": inventory.sha(WRONG_SPEC.encode()),
                    "cases": len(cases), "selection": "Every original TEST_ALL/TEST_INTENSITY=2 reg_vec_load_store specialization, full length, one original wave/workgroup."}
        (output / "identity.json").write_text(json.dumps(identity, indent=2) + "\n")
        (output / "cases.json").write_text(json.dumps(cases, indent=2) + "\n")
        layout_source = output / "layout-check.cpp"
        layout_source.write_text(layout_check_source(cases))
        # Reuse the exact original native compile flags and compiler, substituting
        # only a non-executable static-assert source and syntax-only output.
        command = compile_record["command"]
        source_arg = str(source_root / SOURCE)
        inventory.require(command.count(source_arg) == 1 and '-o' in command, "ambiguous original compiler source/output")
        flags = command[1:command.index('-o')]
        flags = [arg for arg in flags if arg != source_arg and arg != '-S']
        layout, _, _ = corpus.stage([str(args.compiler), *flags, '-fsyntax-only', str(layout_source)], output,
                                    "layout-check", args.timeout, cwd=Path(compile_record["cwd"]))
        inventory.require(layout["status"] == "succeeded", "compiler refused original static GL layout proof")
        spec, wrong_spec = output / "copy.spec", output / "wrong-copy.spec"
        spec.write_text(SPEC)
        wrong_spec.write_text(WRONG_SPEC)
        results, controls = [], []
        for case in cases:
            directory = output / case["id"]
            directory.mkdir()
            config = directory / "launch.json"
            config.write_text(json.dumps(launch(case), indent=2) + "\n")
            command = [str(binary), '--no-log-file', '--backend', 'amdgpu', '--target', 'gfx950', 'verify',
                       str(assembly), str(spec), '--config', str(config), '--sample', '0', '--dim', f'N={case["elements"]}', '--no-profile']
            record, stdout, stderr = corpus.stage(command, directory, 'verify', args.timeout)
            try:
                status = classify_verify(record, stdout, stderr, case["elements"])
            except ValueError as error:
                status = "contract_error"
                stderr = str(error)
            result = {**case, "status": status, "launch_sha256": inventory.sha(config.read_bytes()), "stage": record}
            result['full_identity_proved'] = (re.findall(r"(?m)^VC check: [^\n]*  elements: (\d+)(?:/(\d+))?$", stdout)
                                              == [(str(case['elements']), '')]
                                              and 'EQUIVALENT (matches spec)' in stdout and 'NOT EQUIVALENT' not in stdout)
            if status != 'verified':
                diagnostics = (stderr + '\n' + stdout).strip().splitlines()
                result['detail'] = next((line.strip() for line in diagnostics if re.search(
                    r'unsupported .*instruction|execution stopped|MemoryConflict|error:|NOT EQUIVALENT', line)),
                    diagnostics[-1] if diagnostics else '')
            results.append(result)
            print(case['id'], status, flush=True)
        # A complete identity proof must reject a different equation. One full
        # original specialization per dtype is sufficient for this driver guard.
        for dtype in sorted(DTYPES.values()):
            case = next((row for row in results if row['dtype'] == dtype and row['status'] == 'verified'), None)
            if case is None:
                controls.append({'dtype': dtype, 'status': 'no_verified_original_case', 'passed': False})
                continue
            directory = output / case['id']
            command = [str(binary), '--no-log-file', '--backend', 'amdgpu', '--target', 'gfx950', 'verify',
                       str(assembly), str(wrong_spec), '--config', str(directory/'launch.json'), '--sample', '0',
                       '--dim', f'N={case["elements"]}', '--no-profile']
            record, stdout, stderr = corpus.stage(command, directory, 'wrong-spec', args.timeout)
            try:
                status = classify_verify(record, stdout, stderr, case['elements'])
            except ValueError:
                status = "contract_error"
            controls.append({'case': case['id'], 'status': status, 'passed': status == 'mathematical_mismatch', 'stage': record})
        inventory.require(inventory.build_inventory(source_root) == document, "source changed during vector run")
        inventory.require(all(inventory.sha(path.read_bytes()) == hashes[name] for name, path in input_paths.items()), "run input changed")
        report = {**identity, "outcomes": dict(sorted(Counter(row['status'] for row in results).items())),
                  "mathematical_controls": controls, "all_original_cases_verified": all(row['status'] == 'verified' for row in results)
                  and all(row['passed'] for row in controls), "results": results}
        (output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))


if __name__ == '__main__':
    main()
