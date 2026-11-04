#!/usr/bin/env python3
"""Assemble reproducible gfx1250 safety mutations without executing unsafe code.

These MC receipts establish encoding validity only. Each expected semantic
failure remains pending until the independent graph/value gate checks it.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


# (name, source, kernel, [(instruction substring, occurrence, replacement)], property)
SCHEDULING_PADDING = "\n\t".join(["s_nop 0"] * 64)
CASES = [
    ("copy_missing_km_wait", "native-copy-add.s", "copy", [("s_wait_kmcnt 0x0", 0, "s_nop 0")], "Scalar kernarg destination readiness"),
    ("copy_missing_load_wait", "native-copy-add.s", "copy", [("s_wait_loadcnt 0x0", 0, "s_nop 0")], "Global-load destination readiness"),
    ("exchange_missing_publication", "native-lds-ids.s", "exchange", [("s_barrier_signal -1", 0, "s_nop 0"), ("s_barrier_wait -1", 0, "s_nop 0")], "Cross-wave producer/consumer LDS publication"),
    ("exchange_wrong_ds_counter", "native-lds-ids.s", "exchange", [("s_wait_dscnt 0x0", 0, "s_wait_loadcnt 0")], "Waiting a different counter cannot complete LDS stores"),
    ("wmma_missing_operand_load_wait", "native-wmma.s", "wmma_f32", [("s_wait_loadcnt 0x0", 0, "s_nop 0")], "WMMA input-register readiness"),
    ("gemm_missing_initial_publication", "native-gemm-pipeline.s", "gemm_pipeline_f16", [("s_barrier_signal -1", 0, "s_nop 0"), ("s_barrier_wait -1", 0, "s_nop 0")], "First multi-wave LDS matrix-tile publication"),
    ("gemm_missing_next_tile_publication", "native-gemm-pipeline.s", "gemm_pipeline_f16", [("s_barrier_signal -1", 1, "s_nop 0"), ("s_barrier_wait -1", 1, "s_nop 0")], "Second staged multi-wave LDS matrix-tile publication"),
    ("gemm_missing_matrix_ds_wait", "native-gemm-pipeline.s", "gemm_pipeline_f16", [("s_wait_dscnt 0x0", 2, "s_nop 0")], "Second WMMA operand destination readiness"),
    ("tensor_missing_load_completion", "native-tensor-roundtrip.s", "tensor_roundtrip", [("s_wait_tensorcnt 0x0", 0, "s_nop 0")], "Tensor global-to-LDS completion before consumers"),
    ("tensor_wrong_load_counter", "native-tensor-roundtrip.s", "tensor_roundtrip", [("s_wait_tensorcnt 0x0", 0, "s_wait_loadcnt 0")], "Ordinary global-load counter does not complete tensor DMA"),
    ("tensor_missing_crosswave_publication", "native-tensor-roundtrip.s", "tensor_roundtrip", [("s_barrier_signal -1", 0, SCHEDULING_PADDING), ("s_barrier_wait -1", 0, "s_nop 0")], "Independent NOPs let descriptor issue occur before a scheduled consumer; NOPs add no HB/completion and issuing-wave tensor wait cannot publish to another wave without rendezvous"),
    ("tensor_missing_store_producers", "native-tensor-roundtrip.s", "tensor_roundtrip", [("s_barrier_signal -1", 1, "s_nop 0"), ("s_barrier_wait -1", 1, "s_nop 0")], "All producer waves must publish LDS before tensor store borrows it"),
    ("tensor_missing_store_completion", "native-tensor-roundtrip.s", "tensor_roundtrip", [("s_wait_tensorcnt 0x0", 1, "s_nop 0")], "Borrowed LDS source cannot be overwritten by next-stage tensor load before store completion"),
    ("tensor_lds_footprint_out_of_bounds", "native-tensor-roundtrip.s", "tensor_roundtrip", [("tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]", 0, "s_mov_b32 s5, 256\n\ttensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]")], "Canonical 64-float tensor shape at LDS base256 has footprint[256,512), exceeding the 256-byte LDS allocation"),
    ("transpose_missing_ds_completion", "native-transpose-high64.s", "transpose_8x8_b16", [("s_wait_dscnt 0x0", 1, "s_nop 0")], "Full packed16 transpose destination readiness"),
]


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def mutate(source, kernel, edits):
    start = source.index("\n" + kernel + ":")
    end = source.index(".Lfunc_end", start)
    selected = []
    # Resolve every edit against the original text, then apply from the end.
    for needle, occurrence, replacement in edits:
        offset = start
        for _ in range(occurrence + 1):
            offset = source.index(needle, offset, end)
            next_offset = offset + len(needle)
            if _ != occurrence:
                offset = next_offset
        selected.append((offset, needle, replacement))
    result = source
    for offset, needle, replacement in sorted(selected, reverse=True):
        result = result[:offset] + replacement + result[offset + len(needle):]
    return result, [{"source_line": source[:offset].count("\n") + 1,
                     "original": needle, "replacement": replacement}
                    for offset, needle, replacement in selected]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path(__file__).parent / "fixtures")
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    args = parser.parse_args()
    assembler = args.llvm / "llvm-mc"
    rows = []
    with tempfile.TemporaryDirectory(prefix="ptx-verifier-gfx1250-mutations-") as tmp:
        for name, filename, kernel, edits, property in CASES:
            original = (args.directory / filename).read_text()
            mutated, controls = mutate(original, kernel, edits)
            path = Path(tmp) / (name + ".s")
            path.write_text(mutated)
            obj = path.with_suffix(".o")
            argv = [str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250", "-filetype=obj", str(path), "-o", str(obj)]
            result = subprocess.run(argv, text=True, capture_output=True)
            if result.returncode:
                raise RuntimeError(f"{name}: {result.stderr}")
            rows.append({"name": name, "source": filename, "kernel": kernel,
                         "source_sha256": sha(original.encode()), "edits": controls,
                         "mutated_source_sha256": sha(mutated.encode()),
                         "object_sha256": sha(obj.read_bytes()), "assemble_argv": argv,
                         "assembler_exit_code": result.returncode,
                         "stderr": result.stderr, "expected_property": property,
                         "semantic_validation": "pending; MC success is not semantic validation"})
    output = args.directory / "mutations.json"
    output.write_text(json.dumps({"schema_version": 1, "target": "gfx1250",
        "scope": "Assemble-valid native safety mutations; never run on substitute hardware",
        "assembler": str(assembler), "assembler_sha256": sha(assembler.read_bytes()),
        "cases": rows}, indent=2) + "\n")
    print(json.dumps({"assembled": len(rows), "receipt": str(output)}))


if __name__ == "__main__":
    main()
