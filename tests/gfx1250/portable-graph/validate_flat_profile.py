#!/usr/bin/env python3
"""Pin actual pre-waitcnt compiler MMOs and MC-valid CPU-only FLAT negatives."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(argv):
    result = subprocess.run([str(x) for x in argv], text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return {"argv": [str(x) for x in argv], "exit_code": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path,
                        default=Path(__file__).resolve().parent.parent / "portable-abi")
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).with_name("flat-profile-evidence.json"))
    args = parser.parse_args()
    hip = args.directory / "native-transfers.hip"
    assembly = args.directory / "native-transfers.s"
    source = assembly.read_text()
    compiler = args.llvm / "clang++"
    assembler = args.llvm / "llvm-mc"
    cases = [
        ("flat_destination_replaced_by_valu", "abi_pair_truncation",
         "flat_load_u16 v1, v0, s[4:5] scope:SCOPE_SYS", "v_mov_b32_e32 v1, 0",
         "SourceReuse: a VALU write cannot inherit the generic FLAT destination translation dependency"),
        ("partial_wait_keeps_both_lds_loads_pending", "abi_scalar_granule",
         "s_wait_loadcnt_dscnt 0x1", "s_wait_loadcnt_dscnt 0x2",
         "ReadBeforeReady: Load0+Ds2 retires neither of two pending LDS data tokens"),
    ]
    receipt = {"schema_version": 1, "target": "gfx1250", "hardware_execution": False,
               "scope": "Compiler/assembler provenance only; semantic negative gates are separate",
               "source": str(hip), "source_sha256": sha(hip),
               "assembly": str(assembly), "assembly_sha256": sha(assembly),
               "compiler": str(compiler), "compiler_sha256": sha(compiler.resolve()),
               "assembler": str(assembler), "assembler_sha256": sha(assembler), "mutations": []}
    with tempfile.TemporaryDirectory(prefix="gfx1250-flat-profile-") as temp:
        temp = Path(temp)
        mir = temp / "native-transfers-before-waits.mir"
        receipt["pre_waitcnt_compile"] = command([
            compiler, "-x", "hip", "--offload-device-only", "--offload-arch=gfx1250",
            "--rocm-path=/opt/rocm-7.2.0", "-O2", "-std=c++17", "-mllvm",
            "-stop-before=si-insert-waitcnts", "-S", hip, "-o", mir])
        receipt["mir_sha256"] = sha(mir)
        text = mir.read_text()
        profiles = []
        for kernel in ["abi_scalar_granule", "abi_pair_truncation"]:
            start = text.index("name:            " + kernel)
            end = text.find("\n...", start)
            lines = [line.strip() for line in text[start:end].splitlines()
                     if "FLAT_LOAD" in line or "GLOBAL_STORE" in line]
            assert lines and all("addrspace 3" not in line for line in lines)
            profiles.append({"kernel": kernel, "memory_operations": lines,
                             "interpretation": "FLAT source MMOs retain generic address space; resolved Shared effect is not a LOCAL compiler MMO"})
        receipt["profiles"] = profiles
        for name, kernel, before, after, obligation in cases:
            start = source.index("\n" + kernel + ":")
            end = source.index(".Lfunc_end", start)
            at = source.index(before, start, end)
            mutated = source[:at] + after + source[at + len(before):]
            path = temp / (name + ".s")
            path.write_text(mutated)
            obj = path.with_suffix(".o")
            result = command([assembler, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                              "-filetype=obj", path, "-o", obj])
            receipt["mutations"].append({"name": name, "kernel": kernel,
                "source_line": source[:at].count("\n") + 1, "original": before,
                "replacement": after, "mutated_sha256": sha(path), "object_sha256": sha(obj),
                "assemble": result, "expected_obligation": obligation,
                "semantic_validation": "pending independent native graph gate; MC success alone is not validation"})
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"receipt": str(args.output), "mir_sha256": receipt["mir_sha256"],
                      "mc_valid_mutations": len(receipt["mutations"])}))


if __name__ == "__main__":
    main()
