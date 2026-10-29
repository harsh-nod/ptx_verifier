#!/usr/bin/env python3
"""Reproduce allocated named barriers and MC-valid CPU-only negative controls."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(argv):
    result = subprocess.run([str(x) for x in argv], text=True, capture_output=True,
                            timeout=120, check=True)
    return {"argv": [str(x) for x in argv], "exit_code": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).with_name("named-profile-evidence.json"))
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    source = directory / "native-named-barriers.ll"
    assembly = source.with_suffix(".s")
    llc, mc, linker = [args.llvm / name for name in ("llc", "llvm-mc", "ld.lld")]
    receipt = {"schema_version": 1, "target": "gfx1250", "hardware_execution": False,
               "scope": "Compiler/MC/link provenance; Rust graph and payload gates are separate",
               "input": str(source), "input_sha256": sha(source),
               "assembly": str(assembly), "assembly_sha256": sha(assembly),
               "tools": {name: {"path": str(path), "sha256": sha(path.resolve()),
                                "version": command([path, "--version"])}
                         for name, path in (("llc", llc), ("llvm-mc", mc), ("ld.lld", linker))},
               "mutations": []}
    mutations = [
        ("wrong_expected_count", "named_identity", "s_mov_b32 m0, 0x20001",
         "s_mov_b32 m0, 0x30001", "named deadlock: expected 3, arrived 2"),
        ("missing_signal", "named_identity", "s_barrier_signal m0", "s_nop 0",
         "named deadlock: no named arrival"),
        ("end_does_not_drop_named", "named_subset_drop", "s_barrier_leave", "s_nop 0",
         "named deadlock: ended wave contributes no drop"),
        ("missing_join", "named_identity", "s_barrier_join m0", "s_nop 0",
         "barrier failure: wait has no last joined named object"),
        ("wrong_completion_class", "named_identity", "s_wait_dscnt 0\n",
         "s_wait_loadcnt 0\n", "Shared memory conflict: named arrival does not complete DS"),
    ]
    with tempfile.TemporaryDirectory(prefix="gfx1250-named-profile-") as temp:
        temp = Path(temp)
        regenerated = temp / assembly.name
        receipt["compile"] = command([llc, "-mtriple=amdgcn-amd-amdhsa", "-mcpu=gfx1250",
                                      "-O2", source, "-o", regenerated])
        if regenerated.read_bytes() != assembly.read_bytes():
            raise RuntimeError("compiler output differs from the frozen assembly")
        text = assembly.read_text()
        if text.count(".amdhsa_named_barrier_count 1") != 6:
            raise RuntimeError("each genuine kernel must allocate four named objects")
        obj, code = temp / "native.o", temp / "native.hsaco"
        receipt["assemble"] = command([mc, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                                       "-filetype=obj", assembly, "-o", obj])
        receipt["link"] = command([linker, "-shared", obj, "-o", code])
        receipt["object_sha256"], receipt["code_object_sha256"] = sha(obj), sha(code)
        for name, kernel, before, after, obligation in mutations:
            start = text.index("\n" + kernel + ":")
            end = text.index(".Lfunc_end", start)
            at = text.index(before, start, end)
            mutated = temp / (name + ".s")
            mutated.write_text(text[:at] + after + text[at + len(before):])
            mutant_obj = mutated.with_suffix(".o")
            result = command([mc, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                              "-filetype=obj", mutated, "-o", mutant_obj])
            receipt["mutations"].append({"name": name, "kernel": kernel,
                "source_line": text[:at].count("\n") + 1, "original": before,
                "replacement": after, "assembly_sha256": sha(mutated),
                "object_sha256": sha(mutant_obj), "assemble": result,
                "expected_obligation": obligation, "hardware_execution": False})
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"receipt": str(args.output), "mc_valid_mutations": len(mutations),
                      "assembly_sha256": receipt["assembly_sha256"]}))


if __name__ == "__main__":
    main()
