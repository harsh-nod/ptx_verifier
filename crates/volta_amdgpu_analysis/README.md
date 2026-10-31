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
and target validation. It normalizes a cloned frontend AST, including implicit
sources and FP64 inline constants, and checks register/descriptor constraints
without modifying the caller's syntax. The module-less `lower_kernel` uses gfx950
for wave64
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

The pipeline can supply a checker-backed complete-instruction observer when
`early_readiness` or `early_memory_conflicts` is enabled. Direct `analyze`
rejects those options without an explicit observer; a generic callback stop
provides no certified rejection. See [early memory conflicts](../../docs/early-memory-conflicts.md)
for the selected targets and graph/provenance trust boundary.

## Execution and memory contract

`AnalysisConfig.workgroup_id` selects one native workgroup and defaults to
`(0,0,0)`. Coordinates must be inside `grid_dim`; this result covers no other
workgroups or inter-workgroup conflicts. Written output indices stay absolute,
and full-array specification checks still require the full expected footprint.
CLI launch JSON uses `"workgroup_id": [x,y,z]`; the CLI flag is
`--workgroup-id x,y,z`, and Python uses the keyword `workgroup_id=(x,y,z)`.

Gfx942/gfx950 initialize only enabled workgroup-ID SGPRs in packed ABI order.
Gfx1250 uses TTMP9 for X and TTMP7 for 16-bit Y/Z fields. TTMP7 is initialized
when either Y/Z descriptor enable is present; disabled Z receives zero. The
unclustered TTMP6 and TTMP8's runtime dispatch index remain undefined. Exact
scalar selections and discarded compiler fallback calculations can carry unknown
bits; observing them as concrete output, addresses or control fails. TTMP8's
DebugMark, GridYZvalid and local wave-ID fields remain defined. These rules follow
the public [CDNA5 ISA, section 3.5.3.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
and the pinned [LLVM architected ABI lowering](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SIISelLowering.cpp#L2772-L2858).

The selected workgroup executes with its configured coordinates; the default is
`(0,0,0)`. Dispatch grid dimensions retain their original meaning. Each wave has
one PC, a scalar register file,
EXEC/VCC/SCC state and lane-indexed vector storage. Addresses, branches and
EXEC changes must be concrete. Symbolic comparisons may select data through
supported masks, but cannot control addresses, branches or carry inputs.
Observing undefined flags or unavailable ABI fields stops execution.

Kernel descriptors determine user/system register assignments and LDS limits.
AMDHSA argument offsets and sizes determine explicit kernarg layout. By-value
arguments require exact caller-supplied bytes. Partial native loads preserve
undefined padding bits; only consumers that use defined portions may proceed.
Descriptor/configuration mismatches, uninitialized reads and out-of-bounds
accesses are errors. Scratch/private execution and kernarg preloading are
outside the selected profile.

PTX structured fields and host tensor maps are rejected by this backend; see the
[parameter guide](../../docs/launch-parameters.md) for the public argument forms.

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

Scalar loads discard low address bits in **each component before addition**:
DWORD and wider loads clear two bits; gfx1250 U16 clears one and U8 preserves
all bits. With `scale_offset`, the SGPR index is multiplied by the complete
load width before alignment; the instruction offset remains byte-valued.
The executable profile accepts nonnegative encoded immediate offsets through
`0xfffff` on gfx942/gfx950 and `0x7fffff` on gfx1250. Signed offsets remain
unsupported. Masking preserves allocation bounds, defined-byte checks and
independent counter/readiness obligations.

These rules follow AMD's
[CDNA3 ISA §8.2.1.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
[CDNA4 ISA §8.2.1.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
[CDNA5 ISA §8.1.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
and LLVM's pinned
[SMEM encoding limits](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/Utils/AMDGPUBaseInfo.cpp#L3038).

Defined module globals retain exact initialized bytes and bounds.
`global_values` may bind a writable scalar object of one, two, four or eight
bytes. Selected PC-relative relocation sequences resolve object addresses
without inventing linker addresses. Undefined externs, GOT relocations,
arbitrary PC arithmetic and writes to read-only objects are rejected.

Selected CDNA integer16 forms include `v_lshlrev_b16`, `v_cmp_ne_u16`
and gfx950 `v_bitop3_b16`. Shifts observe low4 count bits and low16 data;
U16 comparisons mask concrete and symbolic words alike. New narrow shift and
BITOP3 results retain unknown upper16 bits conservatively. Native encoding,
EXEC and undefined-bit controls are documented in the
[selected instruction contracts](../../docs/amd-semantic-audit.md#compiler-driven-narrow-integer-forms).

The selected gfx950 `v_mad_i64_i32` profile multiplies signed 32-bit factors
and adds a signed 64-bit value. It writes the low 64 bits to a VGPR pair and
bit 64 to each active lane's SGPR-pair/VCC mask bit; inactive vector data is
preserved and inactive mask bits are cleared. This follows
[CDNA4 ISA §12.11](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
and LLVM's pinned
[VOP3B operand profile](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/VOP3Instructions.td).
Bare and `_e64` encodings support unmodified data registers and integer inline
constants from −16 through 64, with at most one distinct scalar data source.
Observed source words must be concrete and defined. Source modifiers, E32,
clamp and other targets remain outside this profile. The
[numerical controls](tests/gfx950_signed_mad.rs) distinguish bit 64 from signed
overflow, while [pipeline controls](../volta_pipeline/tests/gfx950_signed_mad_tests.rs)
check source readiness independently. This form occurs in HipKittens address
calculations; complete application support also depends on later instructions.

The selected `s_bfe_i64` profile is common to gfx942, gfx950 and gfx1250:
a plain SGPR destination pair, SGPR data pair or integer inline constant, and
a 32-bit SGPR or integer control. Control bits 5:0 select the offset and
22:16 select the width; widths 0 through 64 are modeled, while larger widths
remain unsupported. Signed shift padding and field sign extension preserve
unknown source bits, including ABI padding; SCC is known only when the result
is provably zero or nonzero. Scalar execution is independent of EXEC, and
source readiness remains subject to the target's scalar-load counter.
The contract follows
[CDNA3 ISA §12.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
[CDNA4 ISA §12.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
[CDNA5 ISA §15.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
and LLVM's pinned
[SOP2 operand profile](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SOPInstructions.td).
[Value controls](tests/cdna_bfe64.rs) cover signed fields and definedness;
[pipeline controls](../volta_pipeline/tests/cdna_bfe64_tests.rs) distinguish
correct, absent and unrelated waits for both the data and control registers.

The selected gfx1250 `v_mul_u64` bare/E32 profile multiplies two defined
64-bit register values modulo 2^64 without changing scalar flags. The
source0 pair may be SGPR or VGPR; source1 and destination are VGPR pairs in
the E32 register range. Both inputs are read before aliased outputs are
written. Inactive lanes preserve their destination, and empty EXEC observes
no data operands. E64, inline/literal or special sources and modifiers remain
outside this profile. See
[CDNA5 ISA §15.7](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf),
LLVM's pinned
[gfx1250 encoding controls](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/test/MC/AMDGPU/gfx1250_asm_vop2.s),
[numerical controls](tests/gfx1250_mul_u64.rs) and
[source-readiness controls](../volta_pipeline/tests/gfx1250_mul_u64_tests.rs).

The selected gfx1250 raw-buffer profile accepts `buffer_load_b128` into four
VGPRs and `buffer_store_b64` from two VGPRs, each with a VGPR byte offset,
plain four-SGPR resource, `null` scalar offset and `offen`. Optional immediate
offsets are nonnegative 23-bit values. IDXEN, nondefault cache/scope flags,
implicit LDS, swizzle, nonzero OOB_SELECT, other resource types and unbound
or bounds-disabled resources remain unsupported. Each active transfer must
fit both the resource and a configured allocation; resource-OOB zero-fill or
suppression needs a separate graph contract. Register results use LOADcnt,
stores use STOREcnt, and descriptor/address/EXEC/data leases use XCNT.

Resources retain their raw
[CDNA5 §9.4/§9.6 fields](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf):
57-bit base and 45-bit byte count, with stride ignored in this IDXEN=0,
OOB_SELECT=0 linear profile. A host aggregate shaped as
`{pointer64, range32, config32}` is not a target-neutral descriptor: for a
pointer below 2^57 and config 0x20000, these raw words encode `range * 128`
bytes and stride 32. The evaluator never replaces that hardware count with
the host field's name or intent. Configured allocation bounds remain
independent of a wider resource bound. See LLVM's pinned
[encoding controls](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/test/MC/AMDGPU/gfx1250_asm_vbuffer_mubuf.s),
[value/profile controls](tests/gfx1250_raw_buffer.rs) and
[readiness/lease controls](../volta_pipeline/tests/gfx1250_raw_buffer_tests.rs).

The selected gfx950 raw-buffer profile supports four-operand
`buffer_load_dword` / `buffer_store_dword` and their `dwordx2` forms with plain
VGPR data (one word or an aligned pair), an SGPR-quad resource, scalar offset
`0`, `offen`, and an optional unsigned 12-bit byte offset. CDNA4 resources retain their 48-bit base and 32-bit byte bound;
stride is ignored without indexing. The finite profile requires linear
resources with word3 `0x20000`, nonzero DWORD-aligned bounds and aligned
addresses. Resource suppression, other policies and wider DWORDX3/X4 forms
remain unsupported. Resource checks and configured allocation checks are separate.
All active addresses are captured before issuing VM memory effects.
Descriptor/address sources have ordinary readiness obligations, with no
CDNA5 X lease: the descriptor may be reused immediately after issuance.
See [CDNA4 §§4.4, 9.1.5–9.1.8 and Table48](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
[value controls](tests/gfx950_raw_buffer.rs),
[readiness and full-output math controls](../volta_pipeline/tests/gfx950_raw_buffer_tests.rs),
and the [original N32 source/ABI identity](tests/fixtures/gfx950-raw-buffer-n32.json).
The source identity describes the complete emitted module and its original
launch contract; it does not establish verification of other specializations.

The two-word form transfers the low register at the byte address and the high
register at address + 4, following CDNA4 §12.13 opcodes 21/29. Final DWORD
alignment is sufficient; no extra 8-byte alignment is assumed. The complete
4/8-byte transfer, every active lane and every store-data word pass preflight
before any issue/effect is recorded. DWORDX2 still charges one VM operation,
with readiness for both destination words and no EXP or X source lease.
See [pair value/endianness controls](tests/gfx950_raw_buffer_x2.rs),
[pair readiness and full-output math controls](../volta_pipeline/tests/gfx950_raw_buffer_x2_tests.rs),
and the [unchanged original N96 source/ABI identities](tests/fixtures/gfx950-raw-buffer-x2.json).

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
| Replay premise | Generic or `xnack-` records disabled replay; explicit `xnack+` checks SMEM clause aliases and refuses vector-memory replay | Same | X replay-source retention is modeled separately from data completion |

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
workgroup-barrier forms support the compiler corpora. The selected gfx950 raw
DWORD buffer profile is described above; gfx942 buffer addressing and buffer
forms outside that profile remain unsupported. Direct-to-LDS, atomics and
general DPP/special-register hazard profiles are not implemented for these
targets. The legacy cross-wave GLOBAL publication
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

## Extending instruction semantics

When extending native semantics, validate each separate contract:

- Check the public target-specific encoding, signed field widths and supported modifiers.
- Track which operand bits are defined; unknown bits must not become concrete data or control.
- Apply address component masking and scaling in architectural order, check overflow,
  and validate the complete transfer footprint against allocation bounds.
- Preserve EXEC participation and local lane/wave identities, including empty and partial waves.
- Record issue/wait completion, retained sources and flag dependencies independently of data calculation.

Use positive cases with independently expected values and absolute output indices,
alongside malformed, unsupported, undefined-input and missing-synchronization controls.
A refusal test establishes a boundary; it does not replace the positive semantics check.

The [selected instruction audit](../../docs/amd-semantic-audit.md) records bounded
operand, address, definedness and completion contracts with public sources and
independent regression controls.
