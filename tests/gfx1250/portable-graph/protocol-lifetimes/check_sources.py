#!/usr/bin/env python3
"""Reproduce compiler outputs and assemble CPU-only lifetime controls."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(argv):
    result = subprocess.run([str(x) for x in argv], capture_output=True, text=True,
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
        assert row["completion"] == "coordinator_review_required"
    receipt = {"hardware_execution": False, "compiler_outputs": [], "controls": []}
    with tempfile.TemporaryDirectory(prefix="gfx1250-protocol-sources-") as temporary:
        temporary = Path(temporary)
        for filename in ("native-protocol-lifetimes.hip", "native-protocol-named.ll"):
            source = directory / filename
            retained = source.with_suffix(".s")
            regenerated = temporary / retained.name
            if source.suffix == ".hip":
                argv = [args.llvm / "clang++", "-x", "hip", "--offload-device-only",
                        "--offload-arch=gfx1250", "--rocm-path=/opt/rocm-7.2.0",
                        "-O2", "-std=c++17", "-cuid=ptx_verifier_protocol_lifetimes",
                        "-S", source, "-o", regenerated]
            else:
                argv = [args.llvm / "llc", "-mtriple=amdgcn-amd-amdhsa", "-mcpu=gfx1250",
                        "-O2", source, "-o", regenerated]
            result = command(argv)
            assert regenerated.read_bytes() == retained.read_bytes(), filename
            receipt["compiler_outputs"].append({"source": filename,
                "source_sha256": digest(source), "assembly_sha256": digest(retained),
                "compile": result})
            variants = [(retained.stem, retained.read_text())]
            if source.suffix == ".ll":
                text = retained.read_text()
                begin = text.index("\nnamed_initialization_42:")
                end = text.index(".Lfunc_end", begin)
                sequence = "s_barrier_signal -1\n\ts_barrier_wait -1"
                region = text[begin:end]
                assert region.count(sequence) == 2
                delay = "\n\t".join(["s_nop 0"] * 128)
                changed = text[:begin] + region.replace(sequence, delay, 1) + text[end:]
                variants.append(("unordered_initialization", changed))
            for name, text in variants:
                assembly = temporary / (name + "-mc.s")
                assembly.write_text(text)
                obj = assembly.with_suffix(".o")
                assembled = command([args.llvm / "llvm-mc", "--triple=amdgcn-amd-amdhsa",
                                     "--mcpu=gfx1250", "-filetype=obj", assembly, "-o", obj])
                linked = command([args.llvm / "ld.lld", "-shared", obj,
                                  "-o", assembly.with_suffix(".hsaco")])
                receipt["controls"].append({"name": name,
                    "assembly_sha256": digest(assembly), "assemble": assembled, "link": linked})
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print("PASS: two unchanged compiler outputs and the unordered-init mutation assemble/link")


if __name__ == "__main__":
    main()
