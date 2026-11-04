#!/usr/bin/env python3
"""Replay all W27-W32 outputs, full K4096, arbitrary packed words and padding."""
from original_run import Profile, main


CONTRACT = {
    "gemm_f16_full": (65536, 35651584, 3),
    "gemm_add_silu_f16_full": (65536, 37748736, 4),
    "gemm_f8_full": (65536, 17825792, 3),
    "gemm_add_silu_f8_full": (65536, 18874368, 4),
    "bitdelta_full": (8192, 2621440, 3),
    "bitdelta_batched_full": (32768, 3145728, 3),
}
GAPS = {name: 1966080 for name in CONTRACT if name.startswith("gemm")}
GAPS.update(bitdelta_full=507904, bitdelta_batched_full=983040)
MATRIX = Profile(
    contract=CONTRACT, modules=("matrix",),
    driver="full/hardware/original_matrix.cpp",
    runner="full/hardware/original_matrix_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_matrix_run.py", "full/hardware/original_common.hpp",
           "full/hardware/original_matrix.cpp", "full/fixtures/original-matrix.hip",
           "full/fixtures/original-matrix.s"),
    patterns=6, minimum_patterns=6, maximum_patterns=16, gaps=GAPS,
)


if __name__ == "__main__":
    raise SystemExit(main(MATRIX))
