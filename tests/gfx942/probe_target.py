#!/usr/bin/env python3
"""Pin focused instruction availability against the same gfx942/gfx950 MC."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

FORMS = [
    "v_lshl_add_u64 v[6:7], s[4:5], 0, v[2:3]",
    "v_pk_fma_f32 v[8:9], v[6:7], v[6:7], v[6:7]",
    "v_pk_mul_f32 v[8:9], v[6:7], v[6:7]",
    "v_bitop3_b32 v5, v8, v9, v10 bitop3:232",
    "v_mov_b64_e32 v[2:3], v[4:5]",
    "v_mov_b64 v[2:3], v[4:5]",
    "v_add_u16 v2, v3, v4",
    "v_mul_lo_u16 v2, v3, v4",
    "v_add_f32_e32 v2, 3.0, v4",
    "v_add_f32_e32 v2, v4, 3.0",
    "v_max_f32 v2, v4, 3.0",
    "v_fma_f32 v2, v4, 3.0, v4",
    "v_cvt_f32_fp8 v2, v3",
    "v_cvt_pk_f32_fp8 v[2:3], v4",
    "v_mfma_f32_16x16x16_f16 a[0:3], v[0:1], v[2:3], 0",
    "v_mfma_f32_16x16x32_f16 a[0:3], v[0:3], v[4:7], 0",
    "v_mfma_f32_32x32x16_f16 a[0:15], v[0:3], v[4:7], 0",
    "s_waitcnt vmcnt(0) lgkmcnt(0)",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    directory = args.directory.resolve()
    assembler = Path("/opt/rocm/llvm/bin/llvm-mc")
    cases = []
    for index, instruction in enumerate(FORMS):
        source = directory/f"probe-{index}.s"
        source.write_text(".text\nk:\n"+instruction+"\ns_endpgm\n")
        targets = {}
        for target in ("gfx942", "gfx950"):
            argv = [str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu="+target,
                    "-filetype=obj", str(source), "-o", str(source.with_suffix("."+target+".o"))]
            result = subprocess.run(argv, text=True, capture_output=True)
            targets[target] = {"argv": argv, "exit_code": result.returncode,
                               "stdout": result.stdout, "stderr": result.stderr}
        cases.append({"instruction": instruction, "assembly": source.read_text(), "targets": targets})
    result = {"schema_version": 1, "assembler": str(assembler),
              "assembler_sha256": hashlib.sha256(assembler.read_bytes()).hexdigest(),
              "version": subprocess.check_output([str(assembler), "--version"], text=True),
              "scope": "Encoding availability only; especially identical FP8 opcode spellings do not establish matching CDNA3FNUZ/CDNA4OCP numerical semantics.",
              "cases": cases}
    output = directory/"target-legality.json"
    output.write_text(json.dumps(result, indent=2)+"\n")
    for case in cases:
        print({"instruction": case["instruction"],
               "available": [t for t,r in case["targets"].items() if r["exit_code"] == 0]})


if __name__ == "__main__":
    main()
