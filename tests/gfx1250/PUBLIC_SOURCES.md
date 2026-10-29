# Public gfx1250 sources and artifact retention

The target model uses publicly accessible compiler and library sources. The
12 pinned entries in [semantic-references.json](fixtures/semantic-references.json)
were downloaded without authentication on 2026-10-29; every recorded SHA-256
matched. The recorded ROCm compiler revision is publicly accessible as well.

| Model area | Public primary source |
| --- | --- |
| Target, ABI, registers and replay | [LLVM AMDGPU usage](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUUsage.md) |
| Completion and asynchronous operations | [LLVM async operations](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUAsyncOperations.md) |
| Barrier objects and execution ordering | [LLVM execution synchronization](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUExecutionSynchronization.md) |
| DMA and tensor interfaces | [LLVM DMA operations](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUDMAOperations.md) |
| WMMA fragments and tensor recipes | [ROCm FlyDSL gfx1250 sources](https://github.com/ROCm/FlyDSL/tree/f37f7a2b98f295902240f9f96612222003578b40/lib/Dialect/FlyROCDL/GFX1250) |
| Compiler target implementation | [Recorded ROCm compiler revision](https://github.com/ROCm/llvm-project/tree/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU) |

These sources document interfaces and compiler behavior. They do not establish
that every modeled instruction or software test is correct on a physical device.
The [contract](CONTRACT.md) describes the implemented subset and its limitations.

Architecture validation run directories and the inline device-probe receipts
have been removed. Machine identities, unreleased runtime identifiers and local
device observations are not retained. Original HIP/LLVM/assembly/specification
fixtures, compiler provenance from public toolchains, mathematical oracles and
reproduction drivers remain available. Missing run records do not count as
current acceptance; historical dispositions remain separate observations.

This cleanup changes the current tree and editable issue/PR narratives. Git
history, old branches, GitHub edit history, caches and third-party copies may
still contain earlier versions; no history rewrite is performed here.
