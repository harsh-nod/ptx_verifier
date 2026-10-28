#!/usr/bin/env python3
"""Record actual gfx1250 assembler boundaries; no target execution occurs."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

LLVM = Path("/opt/rocm-7.2.0/lib/llvm/bin")


def main():
    cases = []
    for encoding in ("", "_e32", "_e64", "_e96"):
        for index in (0, 255, 256, 511, 512, 1023, 1024):
            cases.append((f"vgpr{index}{encoding}", f"v_mov_b32{encoding} v{index}, v0", None))
    for index in (0, 103, 104, 105, 106, 127):
        cases.append((f"sgpr{index}", f"s_mov_b32 s{index}, 0", None))
    for instruction in ("v_accvgpr_write_b32 a0, v0", "v_mov_b32 a0, v0",
                        "s_mov_b32 exec_lo, -1", "s_mov_b32 exec_hi, 0",
                        "s_mov_b32 vcc_lo, 0", "s_mov_b32 vcc_hi, 0",
                        "s_mov_b32 s0, ttmp6", "s_mov_b32 s0, ttmp9"):
        cases.append((instruction, instruction, None))
    descriptor = '\n.section .rodata,"a",@progbits\n.amdhsa_kernel k\n.amdhsa_next_free_vgpr {vgpr}\n.amdhsa_next_free_sgpr {sgpr}\n.amdhsa_wavefront_size32 {wave}\n.amdhsa_group_segment_fixed_size {lds}\n.end_amdhsa_kernel\n'
    for vgpr in (0, 1, 256, 512, 1024, 1025):
        cases.append((f"allocation_vgpr{vgpr}", "s_endpgm", descriptor.format(vgpr=vgpr, sgpr=8, wave=1, lds=0)))
    for lds in (0, 65536, 163840, 327680, 327681):
        cases.append((f"allocation_lds{lds}", "s_endpgm", descriptor.format(vgpr=8, sgpr=8, wave=1, lds=lds)))
    cases.append(("wave64_descriptor", "s_endpgm", descriptor.format(vgpr=8,sgpr=8,wave=0,lds=0)))
    for feature in ("", ":xnack+", ":xnack-", ":sramecc+", ":sramecc-"):
        cases.append(("target"+feature, "s_endpgm", f'.amdgcn_target "amdgcn-amd-amdhsa--gfx1250{feature}"\n'))
    rows = []
    with tempfile.TemporaryDirectory(prefix="ptx-verifier-gfx1250-boundary-") as tmp:
        directory = Path(tmp)
        for index, (name, instruction, extra) in enumerate(cases):
            assembly = ".text\n.globl k\nk:\n"+instruction+"\n"
            if extra and extra.startswith(".amdgcn_target"):
                assembly = extra+assembly
            elif extra:
                assembly += extra
            path = directory/f"case{index}.s"
            path.write_text(assembly)
            argv = [str(LLVM/"llvm-mc"), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250", "-filetype=obj", str(path), "-o", str(path.with_suffix(".o"))]
            result = subprocess.run(argv, text=True, capture_output=True)
            rows.append({"name": name, "assembly": assembly, "argv": argv,
                         "exit_code": result.returncode, "stdout": result.stdout,
                         "stderr": result.stderr})
    output = Path(__file__).parent/"fixtures/boundary-assembler.json"
    output.write_text(json.dumps({"schema_version":1,"target":"gfx1250",
        "scope":"Installed toolchain encoding/metadata acceptance only. Rejection by this older compiler does not prove a hardware limit; semantic bounds must also follow pinned primary documentation.",
        "assembler":str(LLVM/"llvm-mc"),"assembler_sha256":hashlib.sha256((LLVM/"llvm-mc").read_bytes()).hexdigest(),
        "cases":rows},indent=2)+"\n")
    print(json.dumps({"cases":len(rows),"accepted":sum(r['exit_code']==0 for r in rows),"output":str(output)}))


if __name__ == "__main__":
    main()
