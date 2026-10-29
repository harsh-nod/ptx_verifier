#!/usr/bin/env python3
"""Exact BF16 fragment/padding and integer division hardware counterparts."""
import original_run

ADAPTERS = original_run.Profile(
    contract={"bf16_m16n8k16_fragment_adapter": (260, 768, 4),
              "high64_division_projection": (1, 0, 1)},
    modules=("upstream-adapters",),
    assemblies=("fixtures/native-upstream-adapters.s",),
    driver="full/hardware/upstream_adapters.cpp",
    runner="full/hardware/upstream_adapters_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/upstream_adapters.cpp",
           "full/hardware/upstream_adapters_run.py", "fixtures/native-upstream-adapters.hip",
           "fixtures/native-upstream-adapters.s", "fixtures/upstream-adapters-provenance.json"),
    patterns=34, minimum_patterns=34, maximum_patterns=34,
    original_outputs={"bf16_m16n8k16_fragment_adapter": 4,
                      "high64_division_projection": 1},
    scope="Exact upstream BF16 fragment/padding and high64 division hardware counterparts. Original logical projections and complete native supersets are checked separately. This does not certify original32 workload or graph/equivalence acceptance.",
)

if __name__ == "__main__":
    raise SystemExit(original_run.main(ADAPTERS))
