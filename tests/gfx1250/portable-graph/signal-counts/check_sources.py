#!/usr/bin/env python3
"""Reproduce genuine named count-update assembly and MC-valid CPU controls."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(argv):
    result = subprocess.run([str(x) for x in argv], text=True, capture_output=True,
                            timeout=120, check=True)
    return {"argv": [str(x) for x in argv], "exit_code": result.returncode}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    root = directory.parents[3]
    references = json.loads((directory / "references.json").read_text())
    for filename, expected in references["artifacts"].items():
        assert digest(root / filename) == expected, filename
    for row in references["rows"]:
        assert digest(root / row["path"]) == row["upstream_sha256"], row["path"]
    source = directory / "native-signal-counts.ll"
    assembly = source.with_suffix(".s")
    receipt = {"hardware_execution": False, "source_sha256": digest(source),
               "assembly_sha256": digest(assembly), "controls": []}
    with tempfile.TemporaryDirectory(prefix="gfx1250-signal-counts-") as temporary:
        temporary = Path(temporary)
        regenerated = temporary / assembly.name
        receipt["compile"] = command([args.llvm / "llc", "-mtriple=amdgcn-amd-amdhsa",
                                      "-mcpu=gfx1250", "-O2", source, "-o", regenerated])
        assert assembly.read_bytes() == regenerated.read_bytes()
        text = assembly.read_text()
        begin = text.index("\nnamed_phase_count_update7:")
        end = text.index(".Lfunc_end", begin)
        region = text[begin:end]
        sequence = "s_mov_b32 m0, 0x20001"
        assert region.count(sequence) == 2
        at = begin + region.rindex(sequence)
        mutated = text[:at] + "s_mov_b32 m0, 0x800001" + text[at + len(sequence):]
        null_begin = text.index("\nnamed_null_update_marker7:")
        null_end = text.index(".Lfunc_end", null_begin)
        null_region = text[null_begin:null_end]
        assert null_region.count("s_mov_b32 m0, 0x7f0000") == 1
        null_reserved = text[:null_begin] + null_region.replace("s_mov_b32 m0, 0x7f0000", "s_mov_b32 m0, 0xff000000") + text[null_end:]
        for name, code in [("original", text), ("reserved_m0_bit", mutated),
                           ("null_ignores_reserved_bits", null_reserved)]:
            path = temporary / (name + ".s")
            path.write_text(code)
            obj = path.with_suffix(".o")
            assembled = command([args.llvm / "llvm-mc", "--triple=amdgcn-amd-amdhsa",
                                 "--mcpu=gfx1250", "-filetype=obj", path, "-o", obj])
            linked = command([args.llvm / "ld.lld", "-shared", obj,
                              "-o", path.with_suffix(".hsaco")])
            receipt["controls"].append({"name": name, "assembly_sha256": digest(path),
                                        "assemble": assembled, "link": linked})
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print("PASS: exact compiler regeneration; original/two reserved-bit controls assemble/link")


if __name__ == "__main__":
    main()
