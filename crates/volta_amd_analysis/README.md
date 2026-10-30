# volta_amd_analysis

Experimental gfx950 parsing, typed lowering and internal execution helpers for
Volta. The CLI and Python native backend is
[`volta_amdgpu_analysis`](../volta_amdgpu_analysis/README.md).

`frontend::parse::parse_kernel(source, name)` parses a selected Clang assembly
entry and its descriptor. `lower_kernel(&kernel)` validates the supported gfx950
instruction forms and returns a `LoweredKernel` with physical register identities,
explicit waits and launch metadata. The lowering API and IR types are exported
from the crate root; execution helpers remain internal.

Parsing rejects malformed target quoting, duplicate selected kernel definitions,
repeated descriptor settings and missing operands. An optional ordinary trailing
comma and either wait-counter separator are accepted. Lowering validates target
feature suffixes, retaining valid XNACK/SRAM-ECC selections and rejecting unknown,
duplicate or conflicting features. Descriptor settings are retained; lowering
alone does not validate a complete launch or register-allocation contract.

The execution helpers initialize descriptor-selected registers for full wave64
launches in 1D, 2D or 3D workgroups. They support an optional kernarg pointer and
enabled workgroup IDs, with X advancing fastest and local coordinates packed
into `v0`. Scalar loads read concrete kernarg bytes and keep their destinations
unavailable until `s_waitcnt lgkmcnt(0)` under an XNACK-disabled premise. The
vector helper handles a lane's `v_lshlrev_b32_e32`. Unsupported instruction forms,
launch layouts, uninitialized reads and pending-load uses return `EvalError`.
These helpers do not yet execute the full copy kernel or produce verifier graphs.

Operand and scalar-memory rules follow the
[CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
(§6.2, §8.2–8.3, §12.6–12.7), LLVM 21.1.8's
[operand validation](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/AsmParser/AMDGPUAsmParser.cpp)
and [counter widths](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/Utils/AMDGPUBaseInfo.cpp).
Launch-register placement follows the
[AMDHSA initial execution state](https://releases.llvm.org/21.1.0/docs/AMDGPUUsage.html#initial-kernel-execution-state).

## Tests

Unit tests cover parser refusals, typed lowering, target features, launch-register
placement, local-coordinate packing, scalar-load completion and lane shifts.
Compiled-copy tests exercise parsing and lowering and supply the launch and scalar
fixtures. Run:

```sh
cargo test -p volta_amd_analysis --lib
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
