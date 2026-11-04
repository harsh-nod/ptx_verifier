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

Parsing recognizes bare, quoted and spaced entry labels, rejects duplicate selected
definitions (including inline forms), and requires the selected entry to occupy
its own line. It rejects malformed target quoting,
repeated descriptor settings and missing operands. An optional ordinary trailing
comma and either wait-counter separator are accepted. Lowering validates target
feature suffixes, retaining valid XNACK/SRAM-ECC selections and rejecting unknown,
duplicate or conflicting features. Descriptor settings are retained; lowering
alone does not validate a complete launch or register-allocation contract.

The IR represents AMD instructions for symbolic execution. It preserves
physical register identities, explicit waits, and launch metadata. The evaluator
initializes registers from the descriptor and launch inputs, tracks symbolic
register values, and executes scalar instructions once per wave and vector instructions
for individual lanes. Scalar loads read the concrete kernel argument buffer or symbolic
global inputs and keep their destinations unavailable until `s_waitcnt lgkmcnt(0)`.
Scalar execution requires XNACK to be disabled; partial LGKM waits with pending scalar
loads are rejected. `ds_bpermute_b32` exchanges register values across a wave without
accessing LDS memory; its results remain pending until an LGKM wait completes them.
Ordinary LDS reads, writes and lane exchanges share an issue-ordered LGKM queue;
each DS instruction counts once, including multiword or dual-offset transfers.
Partial waits release only the guaranteed prefix; the maximum LGKM field (15)
provides no completion evidence for an overfull logical issue history.
An arriving wave with pending LDS operations aborts at `s_barrier` with
`EvalError::PendingLdsAtBarrier` and no symbolic outputs. This deliberately
conservative profile requires completion even when the remaining accesses do
not overlap. It follows the [CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
§4.4 and §12.5: `s_barrier` does not itself drain memory counters.
Payloads are still evaluated at issue. This check does not add a race graph,
cover cross-wave conflicts without a barrier, or change vector-memory/DMA semantics.
Launch initialization supports full waves in 1D, 2D, and 3D workgroups, matching
[AMD's X/Y/Z launch interface](https://releases.llvm.org/21.1.0/docs/AMDGPUUsage.html#initial-kernel-execution-state),
with an optional kernarg pointer and enabled workgroup IDs. Work-items are ordered
with X advancing first, then Y, then Z, following
[AMD's execution model](https://rocm.docs.amd.com/projects/HIP/en/latest/understand/programming_model.html#hierarchical-thread-model).
Unsupported instructions and launch layouts return `EvalError`.

All lanes of a wave stay active; instructions that change EXEC are rejected.
Integer and bitwise operations require concrete words: symbolic values are floats and
represent the math, not bit patterns. This rejects integer arithmetic on symbolic values and
sign-mask tricks for negation and absolute value; floating-point arithmetic and transfers,
including lane exchanges, remain supported. A select between two different constant words
under a symbolic condition is rejected, since the words could encode floats or integers.

`v_cmp_lt_f32_e64` can store symbolic comparison bits in an SGPR pair for
`v_cndmask_b32_e64`. Each scalar word retains its own mask bits; a scalar write
or load replaces them. Reading such a mask as an ordinary integer or address
is rejected. The select's data sources are VGPRs or supported inline constants;
the mask already occupies gfx950's one scalar-bus source, so scalar data sources
are rejected. The e64 select also supports a single-VGPR floating-point NEG
modifier: concrete words keep their bits with the sign bit flipped, while symbolic
reals are negated. Other instruction forms do not inherit this modifier.
`v_pk_add_f32` supports aligned VGPR source/destination pairs and inline constants
in either source. The low result uses each source's first word; explicit
`op_sel_hi` selects each high-result word independently. The supported inline
profile uses its low-word selector and broadcasts to both results. Other modifiers
are rejected. Both results are read and validated before either destination is
written, including when a source aliases the destination. VOP3 lowering validates
the supported inline-float payloads supplied through the public AST. Operand
groups must have balanced brackets; labels cannot absorb bracketed whitespace.

`ArrayDef` marks each global-memory array `Input` or `Output(OutputType)`. Output
stores decode `F32` constants into mathematical reals and preserve existing real
expressions; `U32` outputs require concrete 32-bit words. Invalid values abort at
the store. Outputs cannot be loaded. On completion, `AnalysisResult.symbolic_outputs`
holds the interpreted values that execution wrote; an aborted run has none.

The returned graph carries launch/target provenance and a terminal state without
access events. It supplies no native AMD safety proof. The CLI/Python native
backend records and checks events through `volta_amdgpu_analysis`.

Supported operand forms follow the [CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
(§6.2, §6.7, §12.6, §12.7, §12.10–12.12); scalar addressing and completion follow §8.2–8.3. Operand checks
also follow LLVM 21.1.8's
[operand validation](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/AsmParser/AMDGPUAsmParser.cpp)
and [counter widths](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/Utils/AMDGPUBaseInfo.cpp).
Launch-register placement follows the
[AMDHSA initial execution state](https://releases.llvm.org/21.1.0/docs/AMDGPUUsage.html#initial-kernel-execution-state).

## Tests

Unit tests cover parser refusals, typed lowering, target features, local branch
labels and instruction operand bounds. Kernel tests in `tests/kernels.rs` parse,
lower and execute compiled assembly fixtures, then compare their symbolic outputs
with the corresponding `.out` files.
The `scalar_ops` fixture checks signed arithmetic, 64-bit comparisons and uniform loop branches.
Rejection fixtures instead require a specific lowering or execution error.
LDS completion controls in `tests/kernels.rs` check complete two-wave write/read and read/overwrite
barrier controls, mixed LDS partial waits and unchanged scalar-memory refusals.
Specification comparisons live in `volta_pipeline/tests/amd_equivalence_tests.rs`.
Run the crate tests from the repository root:

```sh
cargo test -p volta_amd_analysis
```

`just amd` runs only the compiled kernel tests.

The CK GEMM and fused-Sigmoid fixtures use the same complete 8 × 8 × 8 problem,
128 work-items and all 64 output equations. The fused golden records the
compiler's piecewise exponential rescaling, including its rounded f32 constant;
it does not establish exact equality to ideal real-valued Sigmoid.

`tests/lean_tests.rs` states the sigmoid fixture's outputs against
`tests/fixtures/sigmoid.spec` (`1 / (1 + exp(-a[i]))`) as a Lean challenge and writes it to
`target/lean/sigmoid.lean` (`just extract-lean`). Each element is claimed within
`1/1000`, not equal: above `a > 87.34` the kernel rescales by the f32 constant nearest
`e^-64`, so over the reals the exact equality is false there.

The cooperative `softmax` fixture uses lane exchanges for row maxima and sums,
as in CK's [FMHA reductions](https://github.com/ROCm/composable_kernel/blob/d80f11f70b1ab154a56b4bb7b4e28062007ccc65/include/ck_tile/ops/fmha/pipeline/block_fmha_pipeline_qr_ks_vs.hpp).
Its XOR reduction follows CK's [block reduction](https://github.com/ROCm/composable_kernel/blob/d80f11f70b1ab154a56b4bb7b4e28062007ccc65/include/ck_tile/ops/reduce/block/block_reduce.hpp),
using the same `ds_bpermute` [shuffle builtin](https://github.com/ROCm/composable_kernel/blob/d80f11f70b1ab154a56b4bb7b4e28062007ccc65/include/ck_tile/core/arch/utility.hpp).

### Regenerating the copy fixture

`tests/fixtures/copy.cl` copies one element per work-item. `copy.s` was produced
with Homebrew LLVM clang 21.1.8 for gfx950; Apple's clang lacks the AMDGPU target.
From `tests/fixtures/`, run:

```sh
clang -x cl -cl-std=CL1.2 --target=amdgcn-amd-amdhsa -mcpu=gfx950 -nogpulib \
  -O2 -g0 -fno-verbose-asm -Xclang -target-feature -Xclang -xnack \
  -S copy.cl -o copy.s
```

### Compiling the CK attention fixture

`tests/fixtures/ck_fmha.hip` instantiates CK Tile's fp32 forward-attention device entry at
revision [`fc2862d712`](https://github.com/ROCm/composable_kernel/blob/fc2862d712/example/ck_tile/01_fmha/codegen/ops/fmha_fwd.py):
a 64 x 64 query/key tile, head dimension 64, row-major V and 256 work-items,
without masking, padding, bias, dropout or auxiliary outputs.
Sequence lengths and the attention scale are kernel arguments.

Use Clang 21.1.8, that CK checkout (`CK_ROOT`), and the [HIP 7.0.2 headers](https://repo.radeon.com/rocm/apt/7.0.2/pool/main/h/hip-dev/hip-dev_7.0.51831.70002-56~24.04_amd64.deb) (`HIP_ROOT`,
containing `include/` and `share/hip/version`). On macOS, change the host-only
`std::min(rotating_count, max_rotating_count)` in CK's `host/rotating_buffers.hpp`
to `std::min<uint64_t>(rotating_count, max_rotating_count)` to reconcile Darwin's integer types.
Compile from the repository root:

```sh
clang++ -x hip -std=c++20 -fbracket-depth=1024 \
  --offload-arch=gfx950:xnack- --offload-device-only -nogpulib \
  --hip-path="$HIP_ROOT" -DNDEBUG -Wno-unknown-warning-option \
  -O3 -g0 -fno-verbose-asm -fgpu-flush-denormals-to-zero \
  -fno-hip-fp32-correctly-rounded-divide-sqrt \
  -I "$CK_ROOT/include" -I "$CK_ROOT/example/ck_tile/01_fmha" \
  -S crates/volta_amd_analysis/tests/fixtures/ck_fmha.hip \
  -o crates/volta_amd_analysis/tests/fixtures/ck_fmha.s
```

The source supplies OCKL helpers as in `ck_gemm.hip`; `NDEBUG` matches CK's Release build.
Fast exp2 and the denormal flag follow CK's [forward-attention build](https://github.com/ROCm/composable_kernel/blob/fc2862d712/example/ck_tile/01_fmha/CMakeLists.txt);
the division flag permits reciprocal-based normalization.
