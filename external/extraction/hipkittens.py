# /// script
# requires-python = ">=3.10"
# dependencies = ["pybind11>=2.13,<4", "pyyaml>=6,<7"]
# ///
"""Compile pinned HipKittens CDNA4 kernels to native gfx950 assembly.

    uv run external/extraction/hipkittens.py
    uv run external/extraction/hipkittens.py vector_copy --out /tmp/hk

Uses ROCm clang++ locally; compilation requires no GPU, PyTorch, or AITER.
Upstream application sources are compiled unchanged. vector_copy is an explicitly
local control that exercises HipKittens' load/store primitives. Existing launch
files are preserved unless --write-launches is supplied.
"""

import argparse
import hashlib
import json
import re
import shutil
import struct
import subprocess
import sys
import sysconfig
import tempfile
from pathlib import Path

EXTERNAL_ROOT = Path(__file__).resolve().parent.parent
HK_ROOT = EXTERNAL_ROOT / "sources" / "HipKittens"
PINNED_REVISION = "8cde3dd146bd1c4be78023b582c1f4375c48489f"
DEFAULT_OUT = EXTERNAL_ROOT / "hipkittens" / "cdna4"
SOURCES = {
    "softmax": "kernels/cdna4/softmax/kernel.cpp",
    "rotary": "kernels/cdna4/rotary/kernel.cpp",
    "gemm_bf16": "kernels/cdna4/gemm/bf16fp32/256_256_64_32_with16x32.cpp",
    "vector_copy": "../../hipkittens/vector_copy.cpp",
}

# Assert the descriptor layout actually used by the pinned headers/compiler.
# All five fields are 64-bit; the final eight bytes include the empty descriptor
# dictionary and padding. This header adds no executable code to the sources.
LAYOUT_CHECK = '''#include "kittens.cuh"
#include <cstddef>
using VoltaGL = kittens::gl<kittens::bf16, -1, -1, -1, -1>;
static_assert(sizeof(VoltaGL) == 48 && alignof(VoltaGL) == 8);
static_assert(offsetof(VoltaGL, raw_ptr) == 0);
static_assert(offsetof(VoltaGL, batch_internal) == 8);
static_assert(offsetof(VoltaGL, depth_internal) == 16);
static_assert(offsetof(VoltaGL, rows_internal) == 24);
static_assert(offsetof(VoltaGL, cols_internal) == 32);
'''


def descriptor(base: int, shape: tuple[int, int, int, int]) -> bytes:
    return struct.pack("<5Q8x", base, *shape)


def launches() -> dict[str, dict]:
    """WG0 footprints retain the application launch's actual descriptor strides."""
    def array(name, base, shape, dtype="bf16", kind="in"):
        return {"name": name, "base": base, "dtype": dtype, "shape": shape, "kind": kind}

    def payload(value):
        return {"bytes": list(value)}

    return {
        "softmax": {
            "description": "Unchanged upstream softmax: full D=128; WG0 writes 128 rows. Descriptor retains B=64,N=8192; only WG0 memory is declared.",
            "kernel": "_Z10softmax_tkILi128EEv15softmax_globalsIXT_EE",
            "block": 256, "grid": [64, 64, 1],
            "arrays": [array("x", 0x10000, [128, 128]), array("out", 0x20000, [128, 128], kind="out")],
            "params": [payload(descriptor(0x10000, (1, 64, 8192, 128)) + descriptor(0x20000, (1, 64, 8192, 128)))],
        },
        "rotary": {
            "description": "Unchanged upstream rotary: full D=128; WG0 writes 32 rows. Original B=16,H=16,N=2048 strides; only WG0 memory is declared.",
            "kernel": "_Z15tk_fused_rotaryILi128EEv14rotary_globalsIXT_EE",
            "block": 64, "grid": [16, 16, 64],
            "arrays": [array("x", 0x10000, [32, 128]), array("out", 0x20000, [32, 128], kind="out"),
                       array("sin", 0x30000, [32, 64]), array("cos", 0x40000, [32, 64])],
            "params": [payload(descriptor(0x10000, (16, 16, 2048, 128)) + descriptor(0x20000, (16, 16, 2048, 128))
                               + descriptor(0x30000, (1, 1, 2048, 64)) + descriptor(0x40000, (1, 1, 2048, 64)) + bytes(8))],
        },
        "gemm_bf16": {
            "description": "Unchanged upstream 8-wave BF16 GEMM: M=N=256,K=128, one complete 256x256 output tile and both K stages. C=A@B.T; original dynamic LDS request.",
            "kernel": "_Z8micro_tk13micro_globalsiii",
            "block": 512, "grid": 1, "dynamic_shared_bytes": 160000,
            "arrays": [array("A", 0x10000, [256, 128]), array("B", 0x20000, [256, 128]),
                       array("C", 0x30000, [256, 256], kind="out")],
            "params": [payload(descriptor(0x10000, (1, 1, 256, 128)) + descriptor(0x20000, (1, 1, 256, 128))
                               + descriptor(0x30000, (1, 1, 256, 256)) + bytes(8) + struct.pack("<3i4x", 256, 256, 128)),
                       {"int": 256}, {"int": 256}, {"int": 128}],
        },
        "vector_copy": {
            "description": "Local HipKittens primitive control, not an upstream application: one full 256-element f32 register vector copied by one wave.",
            "kernel": "hk_vector_copy", "block": 64,
            "arrays": [array("x", 0x10000, [1, 256], "f32"), array("out", 0x20000, [1, 256], "f32", "out")],
            "params": [payload(descriptor(0x10000, (1, 1, 1, 256))), payload(descriptor(0x20000, (1, 1, 1, 256)))],
        },
    }


def metadata(assembly: str) -> dict:
    import yaml
    match = re.search(r"\.amdgpu_metadata\s*\n(.*?)\n\s*\.end_amdgpu_metadata", assembly, re.S)
    if not match:
        raise ValueError("compiler output has no AMDHSA metadata")
    result = yaml.safe_load(match[1])
    if result.get("amdhsa.target") != "amdgcn-amd-amdhsa--gfx950":
        raise ValueError("compiler output target is not gfx950")
    return result


def validate_launch(launch: dict, info: dict) -> None:
    kernel = next(k for k in info["amdhsa.kernels"] if k[".name"] == launch["kernel"])
    args = [arg for arg in kernel.get(".args", []) if not arg[".value_kind"].startswith("hidden_")]
    if len(args) != len(launch["params"]):
        raise ValueError("launch parameter count differs from compiler metadata")
    for arg, param in zip(args, launch["params"]):
        if "bytes" in param and (arg[".value_kind"] != "by_value" or arg[".size"] != len(param["bytes"])):
            raise ValueError("native by-value byte payload size differs from compiler metadata")


def main() -> None:
    import pybind11
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("kernels", nargs="*", help="softmax, rotary, gemm_bf16, vector_copy (default: all)")
    parser.add_argument("--compiler", default=shutil.which("clang++", path="/opt/rocm/llvm/bin") or "clang++")
    parser.add_argument("--assembler", default="/opt/rocm/llvm/bin/llvm-mc")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--write-launches", action="store_true", help="explicitly regenerate existing launch files")
    options = parser.parse_args()
    selected = options.kernels or list(SOURCES)
    if unknown := sorted(set(selected) - SOURCES.keys()):
        parser.error(f"unknown kernels: {', '.join(unknown)}")
    if not (HK_ROOT / "include/kittens.cuh").is_file():
        parser.error("initialize sources: git submodule update --init external/sources/HipKittens")
    revision = subprocess.check_output(["git", "-C", str(HK_ROOT), "rev-parse", "HEAD"], text=True).strip()
    if revision != PINNED_REVISION:
        parser.error("HipKittens revision differs from the pinned extraction recipe")
    if subprocess.check_output(["git", "-C", str(HK_ROOT), "status", "--porcelain", "--untracked-files=no"], text=True):
        parser.error("HipKittens source has local modifications; use the pinned clean submodule")
    version = subprocess.check_output([options.compiler, "--version"], text=True).strip()
    options.out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="volta-hk-layout-") as staging:
        layout = Path(staging) / "layout.cuh"
        layout.write_text(LAYOUT_CHECK)
        for name in selected:
            source = (HK_ROOT / SOURCES[name]).resolve()
            assembly = options.out / f"{name}.s"
            command = [options.compiler, "-x", "hip", "--offload-arch=gfx950", "--cuda-device-only", "-S", "-O3",
                       "-std=c++20", "-w", "-DKITTENS_CDNA4", "-DHIP_ENABLE_WARP_SYNC_BUILTINS", "-ffast-math",
                       "-I" + str(HK_ROOT / "include"), "-I" + str(HK_ROOT / "prototype"),
                       "-I" + pybind11.get_include(), "-I" + sysconfig.get_path("include"),
                       "-include", str(layout), str(source), "-o", str(assembly)]
            subprocess.run(command, check=True)
            with tempfile.TemporaryDirectory(prefix="volta-hk-assemble-") as objdir:
                subprocess.run([options.assembler, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx950", "-filetype=obj",
                                str(assembly), "-o", str(Path(objdir) / "kernel.o")], check=True)
            info = metadata(assembly.read_text())
            launch_path = options.out / f"{name}.wg0.launch.json"
            if not launch_path.exists() or options.write_launches:
                launch_path.write_text(json.dumps(launches()[name], indent=2) + "\n")
            validate_launch(json.loads(launch_path.read_text()), info)
            summary = {"source": str(source.relative_to(EXTERNAL_ROOT)), "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                       "hipkittens_revision": revision, "local_primitive_control": name == "vector_copy", "compiler": version,
                       "compiler_argv": command, "layout_check": LAYOUT_CHECK,
                       "assembly_sha256": hashlib.sha256(assembly.read_bytes()).hexdigest(), "metadata": info}
            assembly.with_suffix(".json").write_text(json.dumps(summary, indent=2) + "\n")
            print(f"{name}: compiled and assembled -> {assembly}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
