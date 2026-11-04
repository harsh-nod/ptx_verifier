#!/usr/bin/env python3
"""Assemble the exact native asynchronous-memory controls without GPU execution."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mutations():
    for kernel in ("async_copy4_same_actor", "async_copy16_same_actor",
                   "async_copy4_cross_wave", "async_copy16_cross_wave"):
        yield kernel, "missing_completion", "s_nop 0"
        yield kernel, "unrelated_completion", "s_wait_loadcnt 0\n\ts_wait_dscnt 0"
    for kernel in ("async_copy4_destination_reuse_same_actor",
                   "async_copy4_destination_reuse_cross_wave", "async_copy16_source_reuse",
                   "async_two_16byte_regions", "async_no_output128_reuse",
                   "async_copy4_global_source_reuse"):
        yield kernel, "missing_completion", "s_nop 0"
    yield "async_copy4_global_source_reuse", "missing_publication", None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembler", type=Path,
                        default=Path("/opt/rocm-7.2.0/lib/llvm/bin/llvm-mc"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    source = directory / "native-async-memory.s"
    provenance = json.loads((directory / "compiler-provenance.json").read_text())
    assert provenance["fixtures"][0]["assembly_sha256"] == digest(source)
    text = source.read_text()
    receipt = {"hardware_execution": False, "assembly_sha256": digest(source),
               "assembler_sha256": digest(args.assembler), "controls": []}
    with tempfile.TemporaryDirectory(prefix="gfx1250-async-controls-") as temp:
        temp = Path(temp)
        variants = [("original", text)]
        for kernel, name, replacement in mutations():
            begin = text.index("\n" + kernel + ":")
            end = text.index(".Lfunc_end", begin)
            region = text[begin:end]
            if replacement is None:
                assert region.count("s_barrier_signal -1") == region.count("s_barrier_wait -1") == 1
                changed = region.replace("s_barrier_signal -1", "\n\t".join(["s_nop 0"] * 128)).replace("s_barrier_wait -1", "s_nop 0")
            else:
                assert 1 <= region.count("s_wait_tensorcnt 0x0") <= 2
                changed = region.replace("s_wait_tensorcnt 0x0", replacement)
            changed = text[:begin] + changed + text[end:]
            variants.append((kernel + "-" + name, changed))
        for name, assembly in variants:
            path = temp / (name + ".s")
            path.write_text(assembly)
            result = subprocess.run([str(args.assembler), "--triple=amdgcn-amd-amdhsa",
                                     "--mcpu=gfx1250", "-filetype=obj", str(path),
                                     "-o", str(path.with_suffix(".o"))],
                                    text=True, capture_output=True, timeout=30)
            if result.returncode:
                raise RuntimeError(f"{name}: {result.stderr}")
            receipt["controls"].append({"name": name, "assembly_sha256": digest(path),
                                         "exit_code": result.returncode})
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"PASS: unchanged original and {len(variants)-1} CPU-only mutants assemble")


if __name__ == "__main__":
    main()
