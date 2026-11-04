#!/usr/bin/env python3
"""Full raw binary64 hardware results; distinct from real-valued model proofs."""
import original_run

KERNELS = ("exact_f64_fma", "exact_f64_mul_add", "exact_f64_runtime_sum",
           "exact_f64_prerounded_literal")
F64 = original_run.Profile(
    contract={kernel: (2, 0, 1) for kernel in KERNELS},
    modules=("exact-f64",),
    assemblies=("fixtures/native-exact-f64.s",),
    driver="full/hardware/exact_f64.cpp",
    runner="full/hardware/exact_f64_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/exact_f64.cpp",
           "full/hardware/exact_f64_run.py", "fixtures/native-exact-f64.hip",
           "fixtures/native-exact-f64.s", "fixtures/exact-f64-provenance.json"),
    patterns=1, minimum_patterns=1, maximum_patterns=1,
    original_outputs={kernel: 1 for kernel in KERNELS},
    scope="Four genuine gfx1250 binary64 compiler cases: compare every raw output bit with physical IEEE FMA/multiply/add reference results. This is distinct from Volta's mathematical-real equivalence model and from the original32 workload gate.",
)

if __name__ == "__main__":
    raise SystemExit(original_run.main(F64))
