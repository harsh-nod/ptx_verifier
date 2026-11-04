#!/usr/bin/env python3
"""Replay W19-W20 at original K576, NCHW pitches and selected output extents."""
from original_run import Profile, main


CONVOLUTION = Profile(
    contract={"convolution_f16_original": (16384, 548864, 3),
              "convolution_f8_original": (8192, 274432, 3)},
    modules=("convolution",), driver="full/hardware/original_convolution.cpp",
    runner="full/hardware/original_convolution_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_convolution_run.py", "full/hardware/original_common.hpp",
           "full/hardware/original_convolution.cpp", "full/fixtures/original-convolution.hip",
           "full/fixtures/original-convolution.s"),
    patterns=5, minimum_patterns=5, maximum_patterns=16,
    gaps={"convolution_f16_original": 713728, "convolution_f8_original": 730112},
)


if __name__ == "__main__":
    raise SystemExit(main(CONVOLUTION))
