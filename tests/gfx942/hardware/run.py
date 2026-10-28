#!/usr/bin/env python3
"""Record exact-code-object MI300X numeric validation, independent of verifier."""
import argparse
import hashlib
import json
from pathlib import Path
import socket
import subprocess


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(argv):
    p = subprocess.run(list(map(str, argv)), text=True, capture_output=True, timeout=180)
    row = {"argv": list(map(str, argv)), "exit_code": p.returncode,
           "stdout": p.stdout, "stderr": p.stderr}
    if p.returncode:
        raise RuntimeError(json.dumps(row))
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    directory = args.directory.resolve()
    compiler = Path("/opt/rocm/llvm/bin/clang++")
    compile_result = run([compiler, "-O2", "-std=c++17", "-Wall", "-Wextra",
                          "-D__HIP_PLATFORM_AMD__", "-I/opt/rocm/include",
                          directory/"native.cpp", "-L/opt/rocm/lib",
                          "-Wl,-rpath,/opt/rocm/lib", "-lamdhip64",
                          "-o", directory/"native"])
    observed = run([directory/"native", directory])
    assert "SUMMARY PASS" in observed["stdout"]
    names = ["native.cpp", "native", "compiler-provenance.json"]
    for suffix in ("hip", "s", "o", "hsaco"):
        names += [p.name for p in sorted(directory.glob("*."+suffix))]
    result = {"schema_version": 1, "target": "gfx942", "host": socket.gethostname(),
              "validated_by": "fixture agent; coordinator independent review/replay required",
              "scope": "Exact genuinely compiled assembly loaded through HIP. All output elements, output guards and unchanged inputs checked. Independent ordinary CPU references; no symbolic safety/equivalence claim or whole-target parity claim.",
              "commands": [compile_result, observed],
              "sha256": {name: sha(directory/name) for name in names},
              "tolerance": {"absolute": 0, "relative": 0},
              "references": {"copy_add": "full-grid elementwise identity/add, six block sizes and three lengths/patterns",
                             "lds": "out[i]=x[i xor64], two ordinary64-term sums",
                             "ids": "out[x+4*(y+3*z)]=x+10*y+100*z, all24coordinates",
                             "mfma": "ordinary16x16 matrix products, everyA/Bbasis plus17dense patterns; fragment packing only at ABI edges",
                             "pipeline": "ordinary row-major32x16x32 product with finalF16 cast,17dense patterns"},
              "unsafe_mutants_run_on_hardware": False}
    output = directory/"hardware-receipt.json"
    output.write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps({"output": str(output), "sha256": sha(output)}))


if __name__ == "__main__":
    main()
