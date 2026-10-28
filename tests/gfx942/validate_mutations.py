#!/usr/bin/env python3
"""Assemble exact synchronization/spacing mutations; do not execute unsafe code."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

CASES = [
    ("native-lds-ids.s", "exchange", "s_barrier", "Shared LDS conflict"),
    ("native-pipeline-f16.s", "pipelined_mfma_f16", "s_barrier", "Shared LDS conflict"),
    ("native-lds-ids.s", "exchange", "s_waitcnt lgkmcnt(0)", "SMEM destination/source readiness"),
    ("native-mfma.s", "mfma_f32", "s_nop 9", "MFMA result readiness"),
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    directory = args.directory.resolve()
    assembler = Path("/opt/rocm/llvm/bin/llvm-mc")
    rows = []
    for i, (name, kernel, needle, expected) in enumerate(CASES):
        source = (directory/name).read_text()
        start = source.index("\n"+kernel+":")
        offset = source.index(needle, start)
        mutated = source[:offset]+"s_nop 0"+source[offset+len(needle):]
        path = directory/f"mutation-{i}.s"
        path.write_text(mutated)
        obj = path.with_suffix(".o")
        argv = [str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx942",
                "-filetype=obj", str(path), "-o", str(obj)]
        result = subprocess.run(argv, text=True, capture_output=True)
        if result.returncode:
            raise RuntimeError(result.stderr)
        rows.append({"source": name, "source_sha256": sha(source.encode()),
                     "kernel": kernel, "source_line": source[:offset].count("\n")+1,
                     "original": needle, "replacement": "s_nop 0",
                     "mutated_source_sha256": sha(mutated.encode()),
                     "object_sha256": sha(obj.read_bytes()), "argv": argv,
                     "exit_code": result.returncode, "stderr": result.stderr,
                     "expected_typed_negative": expected})
    out = {"schema_version": 1, "target": "gfx942",
           "scope": "Actual native compiler mutations accepted by LLVM MC; their semantic negative assertions live in gfx942_compiler_tests.rs. Unsafe mutants are not run on hardware.",
           "assembler_sha256": sha(assembler.read_bytes()), "cases": rows}
    (directory/"mutations.json").write_text(json.dumps(out, indent=2)+"\n")
    print(json.dumps({"assembled": len(rows)}))


if __name__ == "__main__":
    main()
