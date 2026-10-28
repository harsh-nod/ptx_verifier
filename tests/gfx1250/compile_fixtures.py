#!/usr/bin/env python3
"""Compile actual HIP sources and assemble unchanged gfx1250 output with ROCm.

Run on the test host after copying fixtures/*.hip into a unique directory.
No target relabeling or assembly rewriting is performed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import socket
import subprocess


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(argv):
    result = subprocess.run(list(map(str, argv)), text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f"{argv}: {result.stderr}")
    return {"argv": list(map(str, argv)), "exit_code": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    args = parser.parse_args()
    directory = args.directory.resolve()
    sources = sorted(directory.glob("*.hip"))
    if not sources:
        parser.error(f"no HIP fixture sources in {directory}")
    tools = {}
    for name in ("clang++", "llvm-mc", "ld.lld"):
        path = args.llvm / name
        tools[name] = {"path": str(path), "realpath": str(path.resolve()), "sha256": sha(path),
                       "version": run([path, "--version"])["stdout"]}
    fixtures = []
    for source in sources:
        assembly = source.with_suffix(".s")
        obj = source.with_suffix(".o")
        compile_result = run([args.llvm / "clang++", "-x", "hip",
                              "--offload-device-only", "--offload-arch=gfx1250",
                              "--rocm-path=/opt/rocm-7.2.0",
                              "-O2", "-std=c++17", "-S", source, "-o", assembly])
        assemble_result = run([args.llvm / "llvm-mc", "--triple=amdgcn-amd-amdhsa",
                               "--mcpu=gfx1250", "-filetype=obj", assembly,
                               "-o", obj])
        link_result = run([args.llvm / "ld.lld", "-shared", obj,
                           "-o", source.with_suffix(".hsaco")])
        fixtures.append({"source": source.name, "assembly": assembly.name,
                         "source_sha256": sha(source), "assembly_sha256": sha(assembly),
                         "object_sha256": sha(obj),
                         "code_object_sha256": sha(source.with_suffix(".hsaco")),
                         "compile": compile_result, "assemble": assemble_result,
                         "link": link_result})
    result = {"schema_version": 1, "target": "gfx1250", "host": socket.gethostname(),
              "scope": "Genuine native compiler outputs, not edited or retargeted assembly; compilation/assembly alone make no semantic verification claim.",
              "hardware_validation": "not_performed_no_gfx1250_device",
              "tools": tools, "fixtures": fixtures}
    output = directory / "compiler-provenance.json"
    output.write_text(json.dumps(result, indent=2) + "\n")
    inventory = {}
    for fixture in fixtures:
        assembly = directory / fixture["assembly"]
        instructions = []
        for line, raw in enumerate(assembly.read_text().splitlines(), 1):
            text = raw.split(";", 1)[0].strip()
            if re.match(r"(?:s_|v_|global_|flat_|ds_|tensor_|buffer_|scratch_)", text):
                instructions.append({"line": line, "text": text,
                                     "components": text.split(" :: ")})
        inventory[assembly.name] = {"sha256": sha(assembly), "instructions": instructions}
    (directory / "emitted-instructions.json").write_text(json.dumps(inventory, indent=2) + "\n")
    print(json.dumps({"fixtures": len(fixtures), "output": str(output),
                      "sha256": sha(output)}))


if __name__ == "__main__":
    main()
