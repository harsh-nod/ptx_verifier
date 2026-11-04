# Public gfx1250 semantic references

[`semantic-references.json`](fixtures/semantic-references.json) pins public
compiler/library source URLs and SHA-256 hashes for the target model. Use the
pinned revision when comparing behavior; current upstream documentation may
describe interfaces that differ from the installed fixture compiler.

| Model area | Public primary source |
| --- | --- |
| Target, ABI, registers and replay | [LLVM AMDGPU usage](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUUsage.md) |
| Completion and asynchronous operations | [LLVM async operations](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUAsyncOperations.md) |
| Barrier objects and execution ordering | [LLVM execution synchronization](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUExecutionSynchronization.md) |
| DMA and tensor interfaces | [LLVM DMA operations](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUDMAOperations.md) |
| WMMA fragments and tensor recipes | [ROCm FlyDSL gfx1250 sources](https://github.com/ROCm/FlyDSL/tree/f37f7a2b98f295902240f9f96612222003578b40/lib/Dialect/FlyROCDL/GFX1250) |
| Fixture compiler | [ROCm compiler revision](https://github.com/ROCm/llvm-project/tree/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU) |

The [model contract](CONTRACT.md) describes the implemented subset. Public
sources define the semantic basis; compiler probes establish concrete encodings,
and executable tests check the implementation. None alone establishes complete
ISA support or physical floating-point behavior.

Keep HIP/LLVM/assembly/specification fixtures, public tool/source hashes,
independent oracles and reproduction drivers in source control. Keep generated
run logs, machine identities and device observations outside the repository.
