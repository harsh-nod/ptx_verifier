#!/usr/bin/env python3
"""Actual HSA GLOBAL DWORD copies at byte offsets1/2/3/5/7, inside full buffers."""
import original_run

CONTRACT = {f"global_unaligned_{offset}": (4, 16, 2) for offset in (1, 2, 3, 5, 7)}
GLOBAL = original_run.Profile(
    contract=CONTRACT, modules=("unaligned-global",),
    assemblies=("fixtures/native-unaligned-global.s",),
    driver="full/hardware/unaligned_global.cpp", runner="full/hardware/unaligned_global_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/unaligned_global.cpp",
           "full/hardware/unaligned_global_run.py", "fixtures/native-unaligned-global.hip",
           "fixtures/native-unaligned-global.s", "fixtures/unaligned-global-provenance.json"),
    patterns=8, minimum_patterns=8, maximum_patterns=8,
    gaps={name: 12 for name in CONTRACT},
    scope="Five compiler-generated HSA GLOBAL four-byte copies at offsets1/2/3/5/7 within16-byte guarded allocations. Eight raw byte patterns, exact equality, every input/guard/padding byte checked. This physical gate establishes no SMEM/DS/FLAT alignment behavior or symbolic acceptance; those require independent target contracts.",
)

if __name__ == "__main__":
    raise SystemExit(original_run.main(GLOBAL))
