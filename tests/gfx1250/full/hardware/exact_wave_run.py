#!/usr/bin/env python3
"""Full original wave payloads and separate native leader/memory controls."""
import original_run

CONTRACT = {
    "exact_wave_elect": (32, 0, 1), "exact_wave_elect_skip": (31, 0, 1),
    "exact_wave_exchange": (2, 8, 2), "exact_wave_tail_sum": (1, 64, 2),
    "exact_wave_tail_reference": (1, 64, 2),
    "exact_wave_divergent_leaders": (2, 0, 1),
    "exact_wave_memory_exchange": (64, 256, 2),
}
WAVE = original_run.Profile(
    contract=CONTRACT, modules=("exact-wave",),
    assemblies=("fixtures/native-exact-wave.s",),
    driver="full/hardware/exact_wave.cpp", runner="full/hardware/exact_wave_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/exact_wave.cpp",
           "full/hardware/exact_wave_run.py", "fixtures/native-exact-wave.hip",
           "fixtures/native-exact-wave.s", "fixtures/exact-wave-provenance.json"),
    patterns=8, minimum_patterns=8, maximum_patterns=8,
    original_outputs={name: values[0] if name not in
                      ("exact_wave_divergent_leaders", "exact_wave_memory_exchange") else 0
                      for name, values in CONTRACT.items()},
    gaps={name: 4 if name == "exact_wave_elect_skip" else 0 for name in CONTRACT},
    scope="Five original wave payloads at all67 original coordinates per pattern, plus two separate native participant/memory controls. Eight exact binary-fraction patterns cover every output; exited lane0 remains untouched. Only safe positive assembly is executed; CPU graph mutations are never sent to a GPU. Native leader/cross-wave controls do not assert identical PTX divergence or shuffle memory semantics.",
)

if __name__ == "__main__":
    raise SystemExit(original_run.main(WAVE))
