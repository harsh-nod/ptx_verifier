#!/usr/bin/env python3
"""Six allocated named-object positives; exact original compiler code objects."""
import original_run

KERNELS = ("named_identity", "named_encoded_wait_uses_last_join",
           "named_reinitialized_identity", "named_subset_drop", "named_null_unjoin",
           "named_two_arrivals_one_wave")
NAMED = original_run.Profile(
    contract={name: (2, 8, 2) if name == "named_reinitialized_identity" else (1, 4, 2)
              for name in KERNELS},
    modules=("named-barriers",),
    assemblies=("portable-graph/native-named-barriers.s",),
    driver="full/hardware/named_barrier.cpp", runner="full/hardware/named_barrier_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/named_barrier.cpp",
           "full/hardware/named_barrier_run.py", "portable-graph/native-named-barriers.ll",
           "portable-graph/native-named-barriers.s", "portable-graph/named-profile-evidence.json"),
    patterns=8, minimum_patterns=8, maximum_patterns=8,
    scope="Six safe genuine allocated named-barrier compiler kernels: two-wave identity, last-joined WAIT selection, two initialization lifetimes, explicit subset leave, NULL unjoin and two arrivals from one wave. Eight asymmetric binary-fraction patterns, every output and all inputs/guards checked exactly. No CPU-only mutants are executed on hardware; this does not complete all portable barrier/async/lifetime obligations.",
)

if __name__ == "__main__":
    raise SystemExit(original_run.main(NAMED))
