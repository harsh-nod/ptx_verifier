# Upstream functionality audit

The fork was rebased with merge history preserved onto upstream/master
`308b0ef388b75f9bab6759438012c1a7e961ba13`, rechecked on 2026-10-28.
All five commits since `d5067a0` are included. The rebase itself introduced no
conflicts. The full Rust workspace and rebuilt Python bindings were checked
before the gfx1250 changes, separating inherited failures from new regressions.

| Upstream change | AMD equivalent or boundary |
| --- | --- |
| `385f103` packed 16-bit 8x8 matrix transpose | Genuine compiler `transpose_8x8_b16` fixture checks all 64 moved elements. Uses native address/data movement, not a PTX instruction alias. |
| `5ff91f8` BF16 mma.sync m16n8k16 | Separate native WMMA BF16 16x16x32 lane/packing rules, complete symbolic outputs, finite encoded values and A/B basis controls. Shapes differ explicitly. |
| `ffd42b4` exact signed/unsigned 64-bit high multiply and mad | Genuine scalar multiply/carry compiler forms; 343 unsigned plus 343 signed boundary launches, four exact outputs each, using independent 128-bit integer oracles. |
| `e2e6eb8` BF16 tcgen05 operands under kind::f16 | Native BF16 WMMA uses its own typed operands and decoding; NVIDIA tensor-memory/resource semantics remain PTX-specific. F16 and BF16 raw encoding controls cannot be interchanged. |
| `308b0ef` barrier-wait loop with exit label | Upstream PTX lowering remains intact. AMD native split signal/wait phases and blocked progress use their own graph contract; no PTX idiom certificate is imported. |

The audit required transpose and exact-wide native cases beyond the first copy,
LDS and WMMA fixtures. The hardware-specific PTX instructions do not become AMD
mnemonics. Bounded workload-family ports exercise the same mathematical operations
through genuine gfx1250 assembly while retaining explicit shape/dtype limits.

The preexisting `test_aligned_bar_sync_reached_on_different_iterations` PTX
failure remains visible and unchanged. No unrelated assertion or golden output
was weakened. Hardware was pending at that audit; the subsequent exact-assembly
gfx1250 replay is recorded in the [hardware guide](hardware/README.md).

## AMD frontend integration at `103c082`

The next upstream merge adds `eedab43` (AMD stage layout), `7824998` (compiled
gfx950 copy parsing), `ce1dca8` (typed syntax operands), and `85495ca` (public
PTX IR execution), merged by `103c082bf88d2e538bb89f7c4f2e795c408d2339`.
These changes add no AMD execution semantics. The experimental
`volta_amd_analysis` parser and the implemented `volta_amdgpu_analysis` backend
remain distinct workspace members.

The unchanged upstream copy assembly includes an unrelated OpenCL helper using
`s_setpc_b64`. Native parsing must distinguish descriptor-backed kernel entries
from non-entry functions while continuing to reject unsupported instructions
inside an entry and all unmodeled calls or inter-function branches. Stripping
helper code from a fixture is only a diagnostic control, not acceptance evidence.

`amd_frontend_compatibility_tests.rs` compares target, descriptor values, exact
mnemonics and supported typed operands across the two frontends. It also checks
the unchanged copy kernel's entire output at wave64 boundaries and rejects
missing memory waits through native graph readiness. This provides a common
regression contract for incremental upstream convergence without replacing
target-specific AMD execution with the PTX interpreter's semantics.

The public PTX `analyze_lowered` entry point receives the same native-LDS-layout
configuration rejection as parsed PTX execution. Its callers still own IR
well-formedness, provenance and preservation of the source semantics; exporting
the entry point does not validate a translation or alter the native AMD model.
