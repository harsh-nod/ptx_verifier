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
A barrier records each wave's arrival and release without draining its memory counters.
The event graph checks cross-wave LDS ordering: a conflicting read or write left incomplete
before a barrier is rejected with a concrete pair of access events. Single-wave issue order
is preserved. Payloads are evaluated at issue, so symbolic outputs alone are not a safety
proof; clients must also check the returned graph.
Overlapping DWORD writes by distinct lanes of one DS instruction return
`EvalError::LdsRace`, even when the stored values agree. The event graph's wave abstraction
retains this separate lane-level check.
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

The six ordered F32 comparisons and their negated forms use the existing NaN-free real
model. VCC and SGPR comparison masks retain per-lane predicates; a scalar write or load
replaces only the affected word. Reading a symbolic mask as an integer or address is rejected.
E64 selects accept VGPRs and supported inline constants; their mask consumes gfx950's one
scalar-bus source, so SGPR data sources are rejected. Floating-point NEG and ABS preserve
the sign-bit operation on concrete words, including zero and NaN payloads, and operate on
symbolic reals when those are already known. Symbolic selection between distinct raw words
remains unsupported because the words do not establish a floating-point interpretation.

F32 FMA, three-source arithmetic and e64 comparisons support floating-point ABS and NEG.
Packed f32 add, multiply and FMA select source words independently and compute both results
before writing either destination, including aliased pairs. Inline arithmetic constants
broadcast to both results; register-pair selectors choose their actual low or high words.
Packed moves preserve words and symbolic expressions unchanged; their inline source must use
the low selector because its high word is not established. Gfx950's prohibited low-word
selector combinations, duplicate modifiers and malformed groups are rejected.
An f64 register pair holds one real expression or two concrete words that encode one.
Reading one symbolic f64 half as a word, or a pair whose halves no longer match, is rejected;
conversions preserve the exact real. F64 arithmetic, comparisons and conversions share one
source reader and input modifiers. VOP3 lowering validates supported inline-float payloads
supplied through the public AST. Operand groups require balanced brackets, and labels cannot
absorb bracketed whitespace.

`ArrayDef` marks each global-memory array `Input` or `Output(OutputType)`. Output
stores decode `F32` constants into mathematical reals and preserve existing real
expressions; `U32` outputs require concrete 32-bit words. Invalid values abort at
the store. Outputs cannot be loaded. On completion, `AnalysisResult.symbolic_outputs`
holds the interpreted values that execution wrote; an aborted run has none.

The returned graph records LDS accesses as asynchronous DS operations, LGKM completion,
barrier generations and wave exits. Each graph thread represents one 64-lane wave. Its
`SharedMemoryOnly` assumption limits any graph proof to LDS; global-memory accesses and
vector-memory completion are not recorded. The CLI/Python native backend uses
`volta_amdgpu_analysis` and its separate event model.

Supported operand forms follow the [CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
(§6.2, §6.7, §12.6, §12.7, §12.10–12.12); scalar addressing and completion follow §8.2–8.3. Operand checks
also follow LLVM 21.1.8's
[operand validation](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/AsmParser/AMDGPUAsmParser.cpp)
and [counter widths](https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Target/AMDGPU/Utils/AMDGPUBaseInfo.cpp).
Launch-register placement follows the
[AMDHSA initial execution state](https://releases.llvm.org/21.1.0/docs/AMDGPUUsage.html#initial-kernel-execution-state).
Packed f32 low-word selectors also follow LLVM's later
[gfx950 validation fix](https://github.com/llvm/llvm-project/commit/cac3cc2836765f5b039bcb213cda99db2818c11e).
Inline constants follow its [packed-to-scalar regression](https://github.com/llvm/llvm-project/blob/1b2bf711eb920b78c24e31a6c958751d0bdd0007/llvm/test/CodeGen/AMDGPU/unpack-non-coissue-insts-post-ra-scheduler.mir).

The `.amdgcn_target` directive requires exactly one quoted string. Unquoted,
unbalanced and extra-quoted arguments are rejected.

## Tests

Unit tests cover parser refusals, typed lowering, target features, local branch
labels and instruction operand bounds. Kernel tests in `tests/kernels.rs` parse,
lower and execute compiled assembly fixtures, then compare their symbolic outputs
with the corresponding `.out` files.
The `scalar_ops` fixture checks signed arithmetic, 64-bit comparisons and uniform loop branches.
The `vector_int_ops` fixture checks multiplication, bit counts, 64-bit and packed moves,
and signed 64-bit comparisons against a literal bound. `compare64_ops` checks every 64-bit integer comparison
in both encodings, and `scalar_alu_ops` the scalar ALU, comparison and branch families.
The `packed_float_ops` fixture checks paired arithmetic, selectors, negation and destination
overlap against independently derived expressions.
The `f64_ops` fixture checks f64 arithmetic, modifiers, constants, conversions, comparisons and
moves.
Rejection fixtures instead require a specific lowering or execution error.
LDS controls in `tests/kernels.rs` retain complete two-wave write/read and read/overwrite
fixtures, require graph rejection for missing completion, and verify their safe controls with
all outputs. They also cover mixed DS partial waits, maximum-counter sentinels and unchanged
scalar-memory refusals.
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

`tests/lgkm_wait.rs` checks maximal LGKM and VM fields below and above their
field limits, pending-register reads and overwrites, actual zero/partial waits,
combined counters and END completion. `lgkmcnt(15)` and `vmcnt(63)` complete no
operation; maximal LGKM also creates no graph completion generation. Other
fields of a combined wait retain their normal behavior.
