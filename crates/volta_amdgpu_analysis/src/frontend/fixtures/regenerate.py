#!/usr/bin/env python3
"""Regenerate native compiler fixtures using the recorded pinned ROCm compiler.

Run this script on an authorized gfx950 compiler host. It invokes tools with
argument lists, preserves source bytes, checks the pinned compiler commit, and
assembles every output. The checked-in .s files are never silently rewritten.
Choose --output-dir then review regenerated files and their hashes explicitly.
"""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", default="/opt/rocm/llvm/bin/clang++")
    parser.add_argument("--assembler", default="/opt/rocm/llvm/bin/llvm-mc")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    evidence = json.loads((root / "compiler-provenance.json").read_text())
    version = subprocess.check_output([args.compiler, "--version"], text=True)
    if evidence["compiler_commit"] not in version:
        raise SystemExit("Compiler commit differs from the pinned fixture toolchain")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    for fixture in evidence["fixtures"]:
        # Retain the original input basename; absolute path/working directory
        # can still change the HIP CUID object symbol. Record full output hashes.
        original = Path(fixture["compiler_argv"][-3]).name
        source = args.output_dir / original
        shutil.copyfile(root / fixture["source"], source)
        assembly = args.output_dir / fixture["assembly"]
        obj = assembly.with_suffix(".o")
        flags = fixture["compiler_argv"][1:-3]
        subprocess.run([args.compiler, *flags, str(source), "-o", str(assembly)], check=True)
        subprocess.run([args.assembler, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx950",
                        "-filetype=obj", str(assembly), "-o", str(obj)], check=True)
        rows.append({"assembly": assembly.name,
                     "assembly_sha256": hashlib.sha256(assembly.read_bytes()).hexdigest(),
                     "object_sha256": hashlib.sha256(obj.read_bytes()).hexdigest()})
    (args.output_dir / "regenerated-hashes.json").write_text(json.dumps(rows, indent=2) + "\n")


if __name__ == "__main__":
    main()
