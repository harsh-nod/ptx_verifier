# Native gfx942/gfx950 graph contracts

The separate [gfx1250 contract](../tests/gfx1250/CONTRACT.md) covers wave32,
WMMA, replay counters and split barriers; it does not inherit these CDNA cache
or MFMA rules.

Graph checks select `gfx942` (CDNA3) or `gfx950` (CDNA4) from the actual
`Provenance.targets`, including recognized nonconflicting `xnack`/`sramecc`
features. Multiple architectures, unknown features and unrecognized targets
remain inconclusive. Recognizing a target does not enable every ISA instruction.
The interpreter separately rejects unsupported instructions and execution modes.

Both contracts use wave64, VM/LGKM/EXP counter fields of 6/4/3 bits, native
completed-memory frontiers, and wave-level `S_BARRIER` generations. A barrier does
not complete outstanding memory. Scoped cross-wave GLOBAL publication still
requires completed accesses, both endpoints at workgroup scope and the explicit
single-CU workgroup premise. This is not device/system or whole-grid verification.
LLVM's [AMDGPU backend guide](https://llvm.org/docs/AMDGPUUsage.html) explicitly
groups gfx942/gfx950 together in its GLOBAL load/store scope tables.

The selected gfx942 matrix forms are F32 16x16x4/32x32x2, F16
16x16x16/32x32x8, and BF16 16x16x16/32x32x8. The graph contract rejects CDNA4's
doubled-K and f8f6f4/scaled forms on gfx942. This does not claim support for
CDNA3 FP8/FNUZ conversions or all native matrix forms.

For these forms, the software dependency rules differ:

| Producer | Consumer | gfx942 | gfx950 |
| --- | --- | --- | --- |
| Legacy F32 MFMA | ordinary result read or overwrite | passes + 2 | passes + 2 |
| XDL MFMA | ordinary result read or overwrite | passes + 3 | passes + 4 |
| XDL MFMA | partially overlapping / different-pass MFMA accumulator | passes + 1 | passes + 2 |
| MFMA | full same-pass accumulator forwarding | 0 | 0 |

The selected XDL forms have four or eight passes. Wait states exclude the
producer instruction. The independently pinned implementation reference is
[LLVM 22.1.0 `GCNHazardRecognizer.cpp`](https://github.com/llvm/llvm-project/blob/4434dabb69916856b824f68a64b029c67175e532/llvm/lib/Target/AMDGPU/GCNHazardRecognizer.cpp),
functions `GFX940_XDL_N_PassWriteVgprVALUMemExpReadWaitStates`,
`GFX940_XDL_N_PassWriteVgprVALUWawWaitStates`, and
`GFX940_XDL_N_PassWritesVGPROverlapped*SrcCWaitStates`.

[`amdgpu_tests.rs`](../crates/volta_graph_check/tests/amdgpu_tests.rs) contains paired short-delay/valid-delay
controls for all six selected forms, accumulator forwarding, unrecognized target
selection and forged CDNA4 records. Existing PTX checks remain separate.
