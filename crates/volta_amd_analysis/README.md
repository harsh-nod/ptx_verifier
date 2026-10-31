# volta_amd_analysis

Experimental gfx950 parsing, typed lowering and symbolic execution for
Volta. The CLI and Python native backend is
[`volta_amdgpu_analysis`](../volta_amdgpu_analysis/README.md).

`frontend::parse::parse_kernel(source, name)` parses a selected Clang assembly
entry and its descriptor. `lower_kernel(&kernel)` validates the supported gfx950
instruction forms and returns a `LoweredKernel` with physical register identities,
explicit waits and launch metadata. The lowering API and IR types are exported
from the crate root. Instructions use an `IdVec<InstrId, LoweredInstr>` so
execution positions cannot be mixed with register indices.

Parsing rejects malformed target quoting, duplicate selected kernel definitions,
repeated descriptor settings and missing operands. An optional ordinary trailing
comma and either wait-counter separator are accepted. Lowering validates target
feature suffixes, retaining valid XNACK/SRAM-ECC selections and rejecting unknown,
duplicate or conflicting features. Descriptor settings are retained; lowering
alone does not validate a complete launch or register-allocation contract.

`analyze` initializes descriptor-selected registers for full wave64
launches in 1D, 2D or 3D workgroups. They support an optional kernarg pointer and
enabled workgroup IDs, with X advancing fastest and local coordinates packed
into `v0`. Scalar loads read concrete kernarg bytes and keep their destinations
unavailable until `s_waitcnt lgkmcnt(0)` under an XNACK-disabled premise. The
evaluator supports scalar argument pairs/quads, lane shifts, real-valued F32
addition, and global dword loads/stores. Unsupported instruction forms,
launch layouts, uninitialized reads and pending-load uses return `EvalError`.

`ArrayDef` assigns each concrete global range an input or output role. Completed
runs expose written `SymbolicOutputs`; aborted runs expose none. Copy and add
fixtures compare every output against checked-in expressions. The returned graph
currently carries launch/target provenance and a terminal state without access
events. It supplies no native AMD safety proof and is not used by the CLI/Python
pipeline, which records and checks events through `volta_amdgpu_analysis`.

Operand and scalar-memory rules follow the
[CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
(§6.2, §8.2–8.3, §12.6–12.7), LLVM 21.1.8's
[operand validation](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/AsmParser/AMDGPUAsmParser.cpp)
and [counter widths](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/Utils/AMDGPUBaseInfo.cpp).
Launch-register placement follows the
[AMDHSA initial execution state](https://releases.llvm.org/21.1.0/docs/AMDGPUUsage.html#initial-kernel-execution-state).

## Tests

Unit tests cover parser refusals, typed lowering, target features and instruction
operand bounds. Compiled-copy and add integration tests exercise symbolic
execution and complete output expressions. Run:

```sh
cargo test -p volta_amd_analysis
```

### Regenerating the copy fixture

`tests/fixtures/copy.cl` copies one element per work-item. `copy.s` was produced
with Homebrew LLVM clang 21.1.8 for gfx950; Apple's clang lacks the AMDGPU target.
From `tests/fixtures/`, run:

```sh
clang -x cl -cl-std=CL1.2 --target=amdgcn-amd-amdhsa -mcpu=gfx950 -nogpulib \
  -O2 -g0 -fno-verbose-asm -Xclang -target-feature -Xclang -xnack \
  -S copy.cl -o copy.s
```
