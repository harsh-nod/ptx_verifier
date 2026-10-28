# Upstream functionality audit

The fork was rebased with merge history preserved onto upstream/master
`308b0ef388b75f9bab6759438012c1a7e961ba13`, rechecked on2026-10-28.
All five commits since `d5067a0` are included. The rebase itself introduced no
conflicts. The full Rust workspace and rebuilt Python bindings were checked
before the gfx1250 changes, separating inherited failures from new regressions.

| Upstream change | AMD equivalent or boundary |
| --- | --- |
| `385f103` packed16 8x8 matrix transpose | Genuine compiler `transpose_8x8_b16` fixture checks all64 moved elements. Uses native address/data movement, not a PTX instruction alias. |
| `5ff91f8` BF16 mma.sync m16n8k16 | Separate native WMMA BF16 16x16x32 lane/packing rules, complete symbolic outputs, finite encoded values and A/B basis controls. Shapes differ explicitly. |
| `ffd42b4` exact signed/unsigned64 high multiply and mad | Genuine scalar multiply/carry compiler forms;343 unsigned plus343 signed boundary launches, four exact outputs each, using independent128-bit integer oracles. |
| `e2e6eb8` BF16 tcgen05 operands under kind::f16 | Native BF16 WMMA uses its own typed operands and decoding; NVIDIA tensor-memory/resource semantics remain PTX-specific. F16 and BF16 raw encoding controls cannot be interchanged. |
| `308b0ef` barrier-wait loop with exit label | Upstream PTX lowering remains intact. AMD native split signal/wait phases and blocked progress use their own graph contract; no PTX idiom certificate is imported. |

The audit required transpose and exact-wide native cases beyond the first copy,
LDS and WMMA fixtures. The hardware-specific PTX instructions do not become AMD
mnemonics. Bounded workload-family ports exercise the same mathematical operations
through genuine gfx1250 assembly while retaining explicit shape/dtype limits.

The preexisting `test_aligned_bar_sync_reached_on_different_iterations` PTX
failure remains visible and unchanged. No unrelated assertion or golden output
was weakened. gfx1250 hardware validation remains pending.
