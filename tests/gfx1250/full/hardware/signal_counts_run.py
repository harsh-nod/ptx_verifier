#!/usr/bin/env python3
"""Replay only four safe native count-update positives from exact assembly."""
from original_run import Profile, main

KERNELS = (
    "named_phase_count_update7",
    "named_zero_update_marker7",
    "named_null_update_marker7",
    "named_max_signal_count7",
)
SIGNAL_COUNTS = Profile(
    contract={name: (2 if index == 0 else 1, 0, 1) for index, name in enumerate(KERNELS)},
    modules=("signal-counts",),
    assemblies=("portable-graph/signal-counts/native-signal-counts.s",),
    driver="full/hardware/signal_counts.cpp",
    runner="full/hardware/signal_counts_run.py",
    files=(
        "hardware/portable_run.py", "full/hardware/original_run.py",
        "full/hardware/original_common.hpp", "full/hardware/signal_counts.cpp",
        "full/hardware/signal_counts_run.py",
        "portable-graph/signal-counts/native-signal-counts.ll",
        "portable-graph/signal-counts/native-signal-counts.s",
        "portable-graph/signal-counts/compiler-provenance.json",
        "portable-graph/signal-counts/references.json",
    ),
    patterns=8, minimum_patterns=8, maximum_patterns=8,
    gaps={name: 4 for name in KERNELS},
    scope="Four source-verified safe named signal-count positives only: expected count 2 to 1 within one initialization lifetime, zero/no-change, NULL no-op and all 127 arrivals at the 7-bit maximum. Eight repetitions check all 40 constant F32 outputs exactly, 128 untouched tail bytes and 262144 allocation-guard bytes, with zero input bytes. No ambiguous equality, reserved-bit, invalid or deadlock source is launched. Software proof uses separate graph and mathematical checks.",
)

if __name__ == "__main__":
    raise SystemExit(main(SIGNAL_COUNTS))
