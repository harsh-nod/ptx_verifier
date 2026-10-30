# volta_amdgpu_analysis

Parses, lowers and symbolically executes selected native AMDGPU assembly for
**gfx942, gfx950 and gfx1250**. It produces symbolic outputs and an event graph
for one candidate execution. It does not decide equivalence or graph safety;
[`volta_pipeline`](../volta_pipeline/README.md) sends those artifacts to their
independent checkers. Analyzing checked-in assembly requires a CPU, with no
ROCm installation or GPU.

```text
assembly + launch configuration + selected entry + declared target
                         └─ frontend::Module
                         └─ lower ──► typed IR
                                       └─ analyze ──► symbolic outputs
                                                   + event graph
                                                   + statistics/provenance
```

## Interfaces and module boundaries

- `frontend::parse` / `parse_module`: preserve source spans, target, globals,
  kernel descriptors and argument metadata while validating assembly syntax.
- `lower::lower_module_kernel(&module, name)`: select and lower an entry while
  retaining the module's target and globals. Lowering also validates
  caller-constructed typed modules; changing a target cannot bypass its profile.
- `analyze(&module, name, config)`: lower and execute the selected kernel.
  `AnalysisResult` exposes the graph, arena, statistics and instruction counts;
  `symbolic_outputs()` succeeds only after completed execution and extraction.
  `into_parts()` transfers ownership of those artifacts to a caller.
- `ir`: the contract between lowering and execution. `target` defines
  architecture boundaries; `eval` implements wave state and event recording.

The executable IR is separate from the frontend AST. It has closed ALU
operations, typed comparisons and branches, decoded waits, memory address/data
roles and transfer shapes, matrix operand roles, and recursively lowered VOPD
components. Labels, wait syntax and raw instructions cannot enter value
operands. Lowering preserves one instruction per source PC, its original
mnemonic, encoding, modifiers and span; relocation sequences retain all stages.
Only lowering constructs executable instructions, after shared parser checks
and target validation. The module-less `lower_kernel` uses gfx950 for wave64
and gfx1250 for wave32; explicit gfx942 and module globals require module context.

Scalar/vector helpers use a canonical-name bridge from the closed ALU operation
set. Comparisons consume typed relation, value type and EXEC-update fields.
Encoding-specific dependencies and selected modifier modes retain their existing
checks. A lowered operation can still stop as unsupported during execution;
lowering alone makes no safety or value-semantics claim.

The frontend identifies compiler entry kernels through descriptors and AMDHSA
metadata. It excludes an unrelated helper only when `.type ...,@function` and
matching `.size` declarations bound it unambiguously. Overlapping definitions
and entry fallthrough are rejected. Every entry instruction is checked,
including unreachable instructions. Calls, computed jumps and helper call
analysis are unsupported. Handwritten modules without entry declarations
retain strict parsing of all function bodies.

CLI and Python callers select `backend=amdgpu` and a matching `target`.
Omitting the AMD API target selects gfx950. Direct Rust analysis uses the
module's declared architecture. Code-object versions 4–6 and metadata versions
1.0–1.2 are recognized; individual compiler fixtures determine which
combinations have executable coverage.

## Execution and memory contract

Only workgroup `(0,0,0)` executes. The configured logical grid remains in
provenance and supplies launch-coordinate values; the result makes no claim
about races between workgroups. Each wave has one PC, a scalar register file,
EXEC/VCC/SCC state and lane-indexed vector storage. Addresses, branches and
EXEC changes must be concrete. Symbolic comparisons may select data through
supported masks, but cannot control addresses, branches or carry inputs.
Undefined flags and unavailable ABI fields stop execution.

Kernel descriptors determine user/system register assignments and LDS limits.
AMDHSA argument offsets and sizes determine explicit kernarg layout. By-value
arguments require exact caller-supplied bytes. Partial native loads preserve
undefined padding bits; only consumers that use defined portions may proceed.
Descriptor/configuration mismatches, uninitialized reads and out-of-bounds
accesses are errors. Scratch/private execution and kernarg preloading are
outside the selected profile.

Reading Dispatch ID or Private Segment Size user SGPR inputs is unsupported:
their runtime values are not supplied by the launch configuration. Enabling
unused inputs is allowed and reserves their ABI register slots. Workgroup zero
does not imply dispatch ID zero, and the descriptor's fixed private size does
not determine the dispatch's runtime allocation.

Global allocations are byte-addressed, bounded and disjoint. Wide transfers
retain each register-sized granule and its exact footprint. Optional
`shared_allocations` supply named LDS subobject bounds; a complete DS or
resolved-shared FLAT transfer must fit one object and aggregate LDS. Empty
configuration retains aggregate bounds. Raw descriptors do not infer
source-language LDS objects.

Defined module globals retain exact initialized bytes and bounds.
`global_values` may bind a writable scalar object of one, two, four or eight
bytes. Selected PC-relative relocation sequences resolve object addresses
without inventing linker addresses. Undefined externs, GOT relocations,
arbitrary PC arithmetic and writes to read-only objects are rejected.

Input identities come from launch-config array and parameter names. Floating
arithmetic uses mathematical reals: IEEE rounding, NaNs, exceptions and
subnormal behavior are outside that model. Encoded F16, BF16 and FP8 transport
and decoding have separate profiles; an input array cannot acquire
incompatible numeric interpretations through aliases. Symbolic integers use
the supported ring/bit operations, while concrete integer and address
arithmetic wraps at its native width. Exact compiler exponential idioms and
base2 conversions record their distinct modeling assumptions.

Execution calculates candidate asynchronous data eagerly and separately
records instruction operands, memory issues, register leases, counter charges
and byte effects. Eager calculation is not a readiness or publication proof.
The [graph checker](../volta_graph_check/README.md) independently validates
completion, synchronization and conflicting memory accesses. Budgets and
unsupported instructions leave a partial graph and unavailable outputs.

## Target profiles

| Contract | gfx942 | gfx950 | gfx1250 |
| --- | --- | --- | --- |
| Wave width | 64 | 64 | 32 |
| Aggregate static + dynamic LDS | 65,536 bytes | 163,840 bytes | 327,680 bytes |
| Matrix operations | Selected F32, F16 and BF16 `_1k` MFMA | Selected F32/F16/BF16 MFMA and OCP F8F6F4 forms | F32 16×16×4 and F16/BF16 16×16×32 WMMA with F32 accumulators |
| Floating-byte interpretation | FNUZ FP8/BF8 decoding unsupported | Selected OCP E4M3 symbolic and finite E5M2 profiles | Selected E4M3 transport/conversion and finite concrete E5M2 byte-zero conversion |
| Memory completion | VM/LGKM counters and matrix state delays | VM/LGKM counters and matrix state delays | Separate Load/Store/DS/KM/X/Async/Tensor counters |
| Replay premise | Generic or `xnack-` target records disabled replay; `xnack+` unsupported | Same | X replay-source retention is modeled separately from data completion |

These are instruction-form profiles, not complete ISA coverage. Operand tuples,
formats, immediates, modifiers and register allocations are validated per form.
The target-specific corpus guides below identify concrete sources and tests.

### gfx942 and gfx950

Both use packed local IDs, separate encoded VGPR/AGPR names and a unified
physical register allocation. Explicit names must fit their descriptor
allocation without VGPR/AGPR aliasing. Target-specific MFMA pass counts and
source/result delays are checked downstream. BF16 MFMA requires concrete
encoded BF16 operands; arbitrary symbolic BF16 reinterpretation is unsupported.

Selected ALU, conversion, GLOBAL/scalar/LDS/FLAT memory, cross-lane DS and
workgroup-barrier forms support the compiler corpora. Direct-to-LDS, buffer
addressing, atomics and general DPP/special-register hazard profiles are not
implemented for these targets. The legacy cross-wave GLOBAL publication
certificate additionally requires completed effects, workgroup scope at both
endpoints and the `SingleCuWorkgroup` premise.

### gfx1250

Only bare `gfx1250` is accepted; aliases and target feature suffixes are
rejected. Wave32 uses low-32-bit EXEC/VCC masks and no AGPR namespace.
Logical VGPR allocation may reach 1024, but selected named operands are
v0–v255; higher banked encodings are unsupported. Allocation limits do not
imply that every instruction can access every register tuple.

The profile includes selected scalar/vector ALU and VOPD forms, bounded
GLOBAL/scalar/LDS memory, and resolved-global or opaque-shared-aperture FLAT
accesses. The selected scalar-base scaled FLAT form is B32. A single-lane,
no-return, device-scoped `global_atomic_add_f32` is modeled separately;
returning, multi-lane and general unordered atomic serialization are outside
that profile. Resolved-global FLAT accesses retain explicit `SCOPE_SYS`.
Ordinary GLOBAL source forms do not accept that scope modifier in this profile;
the graph contract also handles appropriately scoped ordinary GLOBAL events.
The annotation does not apply to scalar, LDS, atomic or tensor effects and does
not create a completion or synchronization edge.

Selected WMMA forms retain native lane layouts, operand roles and source
leases. TDM supports bounded plain 2D global-to-LDS and LDS-to-global transfers,
with descriptor capture, completion and publication checked independently.
Cluster, multicast, descriptor padding, gather and atomic-barrier tensor modes
are unsupported; nonzero Tensor wait thresholds remain inconclusive.

Shader named barriers use allocated IDs 1–16 within descriptor capacity,
explicit M0 state, INIT/JOIN/SIGNAL/WAIT/LEAVE, incarnations and phases.
SIGNAL's nonzero M0 bits 22:16 update the expected arrival count before the
arrival; zero preserves the count. NULL operations are no-ops except JOIN,
and NULL WAIT requires an explicit NULL join. END does not drop named objects.
Initialization, count changes and reuse require independently checked execution
order. Equality between an updated expectation and existing arrivals remains
inconclusive because the pinned public descriptions disagree at that boundary.
Non-NULL reserved M0 bits, `_isfirst`, clustered objects and reinitialization
with outstanding joins are outside the profile.

The selected `MSG_DEALLOC_VGPRS` epilogue requires zero scratch and an immediately
following `s_endpgm`; it drains X leases without completing outstanding data.

## Tests and source references

```sh
cargo test -p volta_amdgpu_analysis
cargo test -p volta_pipeline --test amd_frontend_compatibility_tests
```

Compiler sources and provenance are under `src/frontend/fixtures` and the
[gfx942](../../tests/gfx942/README.md),
[gfx950](../../tests/gfx950/README.md) and
[gfx1250](../../tests/gfx1250/README.md) corpora. End-to-end pipeline tests
check complete symbolic outputs and typed safety controls. Exact-assembly
hardware drivers check numerical values separately from symbolic proof.
