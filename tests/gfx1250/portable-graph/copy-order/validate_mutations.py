#!/usr/bin/env python3
"""Assemble CPU-only counter/publication mutations of unchanged compiler output."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    assembly = directory / "native-copy-order.s"
    source = assembly.read_text()
    provenance = json.loads((directory / "compiler-provenance.json").read_text())
    assert provenance["fixtures"][0]["assembly_sha256"] == sha(assembly)
    assembler = args.llvm / "llvm-mc"
    cases = [
        ("wrong_scalar_counter", "copy_scalar_same_wave", [
            ("s_load_b32 s0, s[4:5], 0x0\n\ts_wait_kmcnt 0x0",
             "s_load_b32 s0, s[4:5], 0x0\n\ts_wait_loadcnt 0")],
         "a_load_wait_cannot_complete_the_actual_scalar_input_counter"),
        ("wrong_shared_return_counter", "copy_scalar_same_wave", [
            ("s_wait_loadcnt_dscnt 0x0", "s_wait_storecnt 0")],
         "store_completion_does_not_make_the_returned_shared_value_ready"),
        ("missing_crosswave_publication", "copy_scalar_cross_wave", [
            ("s_barrier_signal -1\n\ts_barrier_wait -1", "s_nop 0\n\ts_nop 0"),
            ("flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS",
             "s_nop 0\n\t" * 64 + "flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS")],
         "completing_lds_is_distinct_from_publishing_it_to_another_wave"),
    ]
    receipt = {"schema_version": 1, "target": "gfx1250", "hardware_execution": False,
        "scope": "MC provenance only; exact typed CPU gates are named separately",
        "assembly_sha256": sha(assembly), "assembler": str(assembler),
        "assembler_sha256": sha(assembler), "mutations": []}
    with tempfile.TemporaryDirectory(prefix="gfx1250-copy-order-") as temp:
        for name, kernel, edits, gate in cases:
            begin = source.index("\n" + kernel + ":")
            end = source.index(".Lfunc_end", begin)
            body = source[begin:end]
            details = []
            for before, after in edits:
                at = body.index(before)
                details.append({"line_before_edit": source[:begin].count("\n") + body[:at].count("\n") + 1,
                                "original": before, "replacement": after})
                body = body[:at] + after + body[at + len(before):]
            path = Path(temp) / (name + ".s")
            path.write_text(source[:begin] + body + source[end:])
            obj = path.with_suffix(".o")
            argv = list(map(str, [assembler, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                                 "-filetype=obj", path, "-o", obj]))
            result = subprocess.run(argv, text=True, capture_output=True, timeout=120, check=True)
            receipt["mutations"].append({"name": name, "kernel": kernel, "edits": details,
                "assembly_sha256": sha(path), "object_sha256": sha(obj),
                "assemble": {"argv": argv, "exit_code": result.returncode,
                             "stdout": result.stdout, "stderr": result.stderr},
                "cpu_gate": "crates/volta_pipeline/tests/gfx1250_portable_copy_tests.rs::" + gate})
    output = directory / "mutations.json"
    output.write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"receipt": str(output), "mc_valid_mutations": len(cases)}))


if __name__ == "__main__":
    main()
