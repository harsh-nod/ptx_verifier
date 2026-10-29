# Native gfx942, gfx950 and gfx1250 analysis

This crate mirrors `volta_ptx_analysis`: typed assembly frontend, lowering, one
candidate execution with target-selected wave geometry, then the existing symbolic-output and event-graph
artifacts. It does not depend on the pipeline, equivalence checker, or graph
checker. Backend dispatch and verification remain in the existing pipeline.

The targets are LLVM AMDHSA assembly for gfx942, gfx950 and gfx1250, tested with
code-object version 6 and metadata 1.2. The frontend recognizes code-object 4–6
and metadata 1.0–1.2; those broader version ranges are not independently validated
gfx1250 toolchain profiles. Legacy compiler fixtures retain source and provenance
under `src/frontend/fixtures`; gfx1250 fixtures live under
[`tests/gfx1250`](../../tests/gfx1250). CPU analysis of checked-in assembly
requires no ROCm installation or GPU.

`frontend::parse` and `parse_module` preserve the original source, instruction
spans, globals, descriptors and argument metadata. Descriptors and AMDHSA metadata
identify the entry kernels in compiler modules. Unrelated functions are excluded
only when declared with `.type ...,@function` and closed by a matching `.size`;
overlapping function definitions and entry fallthrough are rejected when excluding
helpers. Module directives, metadata and global objects are still validated.
Every entry instruction is checked, including unreachable instructions. Calls and
computed jumps remain unsupported; lowering rejects branches outside the entry
body. Descriptor-free, metadata-free handwritten modules retain strict parsing of
all functions. This frontend does not analyze helper call graphs or synthesize
returns. Select an entry through `lower::lower_module_kernel(&module, name)` after
parsing, so target information and module globals remain available.

Select gfx942 explicitly with CLI `--backend amdgpu --target gfx942` or Python
`Config(..., backend="amdgpu", target="gfx942")`. The source target must match
that selection; omitted API targets retain gfx950 as the default. Direct Rust
analysis uses the module's declared architecture. Target feature suffixes remain
in graph provenance and survive serialization.

| Architecture boundary | gfx942 (CDNA3 / MI300) | gfx950 (CDNA4 / MI350) |
| --- | --- | --- |
| Wavefront and local-ID ABI | Wave64, packed x/y/z in v0 | Same |
| Aggregate static plus dynamic LDS | 65,536 bytes | 163,840 bytes |
| Selected native MFMA | F32 16x16x4/32x32x2, F16 16x16x16/32x32x8, BF16 `_1k` counterparts | Existing selected forms, including doubled-K and F8F6F4 forms |
| XDL ordinary-result wait | Target-specific CDNA3 pass count plus three | CDNA4 pass count plus four |
| FP8/BF8 numeric decoding | Unsupported: FNUZ is distinct from the existing OCP abstraction | Existing OCP support |
| `v_cvt_pk_f16_f32`, bitop3, native BF16 conversion | Rejected | Existing supported subset |

This is a selected instruction model. Unimplemented CDNA3 FP8 MFMA, atomics,
replay-enabled vector clauses, and other existing unsupported instruction families
remain unsupported. On gfx942/gfx950, BF16 MFMA arithmetic currently requires
concrete encoded BF16 operands; gfx1250 WMMA has a separate original-16-bit-input
profile described below. Arbitrary symbolic BF16 reinterpretation is unsupported.
Native gfx942 compiler sources, hardware drivers and receipts live under
[`tests/gfx942`](../../tests/gfx942). The architecture gate is applied both during
parsing and lowering of caller-built modules, so changing a target string cannot
make a CDNA4-only instruction execute as CDNA3.

Architecture references: [AMD CDNA3 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
[LLVM AMDGPU ABI and processor tables](https://llvm.org/docs/AMDGPUUsage.html),
and [LLVM processor features](https://github.com/llvm/llvm-project/blob/main/llvm/lib/Target/AMDGPU/AMDGPU.td).
The [`core-assembler-profiles.json`](../../tests/gfx942/evidence/core-assembler-profiles.json) receipt compares the same 725 observed
instruction profiles with LLVM's gfx942 and gfx950 assemblers; assembly
acceptance is separate from the mathematical and graph checks.

## gfx942/gfx950 execution model

The analyzer executes workgroup `(0,0,0)` only. Each wave has one PC, SGPR file,
64-bit `EXEC` and `VCC`, `SCC`, and lane-indexed vector/accumulator storage. It
initializes partial waves and packed multidimensional local IDs from
launch dimensions. Initial VCC halves and SCC remain undefined until written.
Reading an undefined flag stops analysis. Scalar instructions execute with empty
`EXEC`; ordinary vector reads/writes and vector memory issues do not. Comparisons
and carry operations still overwrite their scalar mask destination. Activating
nonexistent lanes in a partial wave is rejected.

Initial user/system register assignments come from kernel descriptor enable bits.
Explicit argument bytes come from AMDHSA argument offsets and sizes. Recognized
hidden launch fields are initialized from configuration. Unknown hidden runtime
facilities remain uninitialized and their consumption stops analysis.
Concrete partial kernarg words retain a bit-definedness mask when native loads
include padding. Exact low16 sign extension and byte2-to-f32 conversion can
consume their defined portions; copying a word preserves unknown bits. Whole-word
arithmetic, floating decoding, and stores that observe padding stop analysis.
Padding is never initialized to a numeric value, and ordinary global/LDS reads
retain their existing uninitialized-memory checks.
Descriptor/user-SGPR disagreement and argument-count disagreement are errors.
Kernarg preloading remains unsupported. Launch checks
enforce descriptor workgroup limits and required dimensions. Split workgroups
are unsupported. Explicit VGPR/AGPR allocations must not alias in the unified
physical register file.
Both targets have separately encoded v0..v255/a0..a255 operands and numbered
s0..s101 operands. The unified VGPR/AGPR descriptor allocation can reach512
words; the accumulator offset is a multiple of four in4..256. Every explicit
register must fit its allocation, and overlapping VGPR/AGPR names are rejected.

Defined module globals have bounded, aligned storage with their exact initialized
bytes. `global_values` can override a writable scalar object of one, two, four,
or eight bytes. Read-only objects cannot be rebound or written. The native
contiguous `s_getpc_b64` / `s_add_u32 symbol@rel32@lo+4` /
`s_addc_u32 symbol@rel32@hi+12` relocation sequence resolves an object address.
gfx1250 additionally has a two-instruction `s_get_pc_i64 s[p:p+1]` /
`s_add_nc_u64 s[p:p+1], s[p:p+1], symbol@rel64+4` profile. Both retain their
original instructions and reject branches into the middle of the sequence.
Intermediate PC words remain opaque. The split REL32 profile leaves SCC
undefined; the no-carry REL64 profile preserves SCC. The analyzer does not
invent linker addresses or carry flags. Undefined externs,
GOT relocations, arbitrary PC arithmetic, and overlapping storage are rejected.

Concrete integers and addresses use native-width wrapping arithmetic. Symbolic
integer add/sub/mullo follows the existing mathematical ring contract; native
bit operations retain explicit width operations. Symbolic input data remains
separate from address bits. Input identities
use existing expression-arena names and indices. The floating-point abstraction
follows the repository's real-number contract: rounding, denormals, and IEEE NaN
behavior are outside the claim. Encoded halves, packed pairs, and OCP E4M3 input
bytes retain separate symbolic identities. Arbitrary symbolic reinterpretation
is unsupported. Untyped word inputs acquire their numeric interpretation at the
first arithmetic consumer; an array cannot be treated as both integer and
floating-point storage through different aliases. Recognizing the exact compiler multiply-by-rounded-log2(e)/exp2
idiom adds a separate `CompilerExp2Idiom` assumption; nearby constants do not
trigger that fold.
Native comparisons can retain lane predicates in opaque VCC or SGPR mask words.
`v_cndmask_b32` selects symbolic integer or typed f32 data; concrete b32 arms are
canonicalized as unsigned32 words. Mask-word copies preserve their original bit
positions, including separate VCC low/high writes. Symbolic masks cannot drive
branches, EXEC, carry inputs, addresses, or raw data stores.
Byte inputs acquire a numeric interpretation at their first decoder. OCP E4M3
and signed/unsigned integer-byte interpretations of the same input array cannot
be mixed. Signed loads and native signed-byte-to-F16 conversions preserve numeric
input identities while packing keeps the original byte positions.
Two-byte encoded byte pairs retain both identities through native 16-bit memory
transfers. Exact 32-bit word transport via b64 shifts by zero or 32 and OR with a
concrete zero preserves symbolic data tags; other symbolic b64 shifts require
encoded bits. Concrete `v_ashrrev_i64` retains signed whole-value integer
provenance; its count uses the low six bits. Symbolic signed64 arithmetic remains unsupported.
An integer consumer of a symbolic UBYTE input records its unsigned-byte numeric
interpretation, which cannot be combined with FP8 decoding of the same array.
Concrete logical b64 shifts retain unsigned integer provenance for numeric
64-bit output extraction while remaining usable as native address bits.
General base2 exponentials/logarithms use the exact reciprocal of rounded f32
log2(e), matching the existing PTX mathematical contract; executing that path
records `CompilerBase2Conversion`. Actual instruction coefficients remain exact.

Memory is byte-addressed with explicit symbolic granules. Global allocations must
be disjoint and accesses must lie inside one declared allocation; LDS is bounded
by static plus dynamic size. Wide transfers preserve each register-sized granule
and its byte footprint. Only completely written output elements are extracted.
Optional named `shared_allocations` preserve configured LDS subobject bounds:
the entire DS or shared-aperture FLAT transfer, including dual offsets, must fit
one supplied region. Each region must fit aggregate LDS capacity. The exact
layout is exported with `ConfiguredSharedAllocationLayout`; empty configuration
keeps aggregate bounds. Source-level objects are not inferred from raw metadata.
An exact native `s_mov_b64 ..., src_shared_base` produces an opaque shared-aperture
high word and a zero low word. Copies preserve that token. A FLAT address pair
with this high word and a concrete low offset accesses the same LDS bytes as DS
instructions; its encoded displacement cannot carry out of the aperture.
The gfx1250 scalar-base FLAT profile adds a concrete vector DWORD offset to
an SGPR address pair. An opaque shared high word retains the LDS interpretation;
a concrete address pair retains the global interpretation. Signed displacements
cannot escape the shared aperture, and the complete transfer still obeys its
configured allocation and aggregate bounds.
The token cannot become data bits, participate in arithmetic, or form a GLOBAL
address. Other generic-pointer apertures remain unsupported.
Generic `gfx942`/`gfx950` assembly and explicit `xnack-` targets model execution with
XNACK replay disabled, matching the test devices; provenance records the
`XnackReplayDisabled` assumption. Target feature suffixes remain in provenance.
Explicit `xnack+` targets enforce conservative scalar-memory replay checks:
contiguous SMEM clauses cannot overwrite their address-source SGPRs, except for
the native isolated single-DWORD exception. Vector GLOBAL/FLAT memory execution
with replay enabled remains unsupported until vector clause/source retention is
modeled. Unaligned SMEM address component masking remains outside the supported
scope.
Missing stores remain missing for downstream equivalence to diagnose. Concrete
integer ALU results retain integer provenance; ambiguous raw-bit output constants
require a conversion instead of guessing their numeric type.
Known zero reciprocal, nonpositive reciprocal-square-root/logarithm, and negative
square-root operands stop execution before undefined real expressions can
disappear through later multiplication. Nonzero reciprocals and unrelated encoded
infinities retain the upstream model.

## gfx942/gfx950 events and synchronization

Every issued instruction records its register reads and writes with 64-bit lane
masks. Memory issues separately identify counter class, destinations, held
operands, and attributed byte effects. Kernarg accesses are also recorded.
Counter waits are observations, not assumed universal completion of every
operation. The graph checker owns readiness and ordering proofs. The interpreter
constructs candidate values at issue.

Unsplit workgroups record the `SingleCuWorkgroup` premise. Only native GLOBAL
loads/stores with `sc0` and without `sc1` annotate workgroup visibility; these
cache controls add no synchronization edges. Cross-wave GLOBAL publication also
requires the graph checker's supported completion-and-barrier protocol. Other
GLOBAL scope combinations, SMEM, and FLAT accesses do not acquire this visibility
annotation.

LDS barriers record wave arrivals and releases by generation. LDS visibility
requires the appropriate memory waits as well as rendezvous. DS permutations
snapshot source lanes before writing destinations and record LGKM readiness;
they do not fabricate LDS accesses for the cross-lane network.
`s_endpgm` records its implicit full memory-counter drain before all valid lanes
exit. Terminated waves cease participating in later barriers; each surviving
wave still arrives and releases in every generation, including a partial wave.
Exit completion alone does not publish LDS data to another wave without its
required barrier.

Every matrix operation requires a full active wave64. A/B/C/D mappings derive
from CDNA4 ISA sections 7.1.4–7.1.5; FP8 uses separate sixteen-K interleaving.
Inputs are snapshotted before overlapping destinations change. Matrix issue,
instruction, and NOP delay events allow downstream checks to enforce form-specific
result, operand, and accumulator dependencies. Default layout controls are
required, except explicitly supported FP8 format and unit-scale selectors.

## Current support

| Area | Supported behavior | Limits |
| --- | --- | --- |
| Integer/address ALU | Concrete fixed-width arithmetic, carry masks, bitfields, address packing; symbolic32 add/sub/mullo, bit operations, native shifts, min/max | Symbolic integer division/control and general64-bit integer data remain unsupported; data expressions cannot become address bits |
| Floating data | Mathematical f32/f64 arithmetic, selected conversions/transcendentals, packed f32/f16 operations, partial-half preservation, OCP E4M3 decoding; f32 clamp for arithmetic, trans, mov and cndmask VOP3 forms | No IEEE rounding/NaN claim; ordered whole-value F64 storage only; symbolic BF16/E5M2 storage remains unsupported; clamp with explicit e32/SDWA, integer/compare/conversion clamp meanings and output scaling remain unsupported |
| Global and LDS memory | Byte/short/dword and wide transfers, sign extension, narrow-store truncation, dual-offset LDS, static/dynamic LDS bounds, exact opaque shared-aperture FLAT accesses, bounded module globals and scalar bindings | Equal-offset dual LDS operations, scratch/private apertures, arbitrary PC/GOT relocations, buffer addressing, direct-to-LDS, and atomics remain unsupported |
| Control and synchronization | Scalar branches, concrete EXEC/VCC/SCC, symbolic lane comparison masks and cndmask data selection, save/restore EXEC, memory waits, surviving-wave barriers after whole-wave termination | One workgroup; symbolic control/EXEC/carry/address masks remain unsupported; live-wave loops remain inconclusive on budget exhaustion; partial graph on abort |
| Cross-lane | DS permute/bpermute with source snapshots and LGKM readiness | DPP and ordinary readlane/readfirstlane/writelane require further software hazard checks |
| Accumulator registers | Disjoint physical allocation, MFMA accumulation, native AGPR read/write/move and direct stores | Aliasing VGPR/AGPR allocations are rejected |
| F32 MFMA | 16×16×4 and 32×32×2 | Full active wave64 and default layouts |
| F16 MFMA | 16×16×16, 16×16×32, 32×32×8, 32×32×16 | Typed symbolic F16 and finite concrete operands |
| BF16 MFMA | 16×16×16, 16×16×32, 32×32×8, 32×32×16 | Finite concrete decoding; ordinary symbolic two-byte arrays are F16, so symbolic BF16 is rejected |
| OCP FP8 MFMA | F8F6F4 16×16×128 and 32×32×64, with E4M3/E5M2 format controls | Symbolic storage currently E4M3 only; finite concrete E5M2 supported; F6/F4 rejected |
| Scaled FP8 MFMA | Same FP8 shapes with selected E8M0 scale bytes equal to 127 | Nonunit scale bytes are rejected |

M0 initialization and explicit writes, special mask registers consumed as
ordinary vector data, and instruction families with unmodeled software
dependencies stop analysis. Unsupported behavior never receives fabricated values
or a positive verification result.

Budgets, unsupported instructions, invalid accesses, and malformed state preserve
a partial event graph and withhold symbolic outputs. Budget exhaustion is
inconclusive, not a synchronization deadlock.

## Focused validation

Run `cargo test -p volta_amdgpu_analysis -j4`.

Execution tests check complete output identities for native copy/add and tails
at block sizes 1, 63, 64, 65, 128, and 256; three-dimensional packed IDs; wide and
narrow transfers; missing stores; budget-limited partial graphs; cross-wave LDS
exchange; wave reductions; F16/FP8 activation and RoPE packing; undefined flag and
empty-EXEC safety; native symbolic integer/F64 data; and complete MFMA dot products against independently enumerated
coordinates. Native compiler fixtures also exercise two-wave LDS/MFMA pipelines,
module-global relocations and bindings, static LDS padding with genuine external
dynamic LDS, multidimensional grid/group/block output,
a convolution tile with the original 576-term reduction and physical pitches,
full-shape GEMM/convolution, attention-family and Mamba workloads, and supplemental reduced online-softmax/MFMA controls. Full/reduced scopes and revision-pinned receipts are listed in tests/gfx950/. Reduced
fixtures do not establish full original-launch capacity or baseline parity.

Workflow, safety mutation, serialization, and hardware tests live with pipeline
integration. These focused tests do not establish full parity.

Primary references:

- [AMD CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
  sections 4, 7.1.4–7.1.5, 7.6, 8.3, 10.2, and 12.12.
- [LLVM AMDGPU ABI](https://llvm.org/docs/AMDGPUUsage.html).
- LLVM GCNHazardRecognizer.cpp and SIInstrInfo.cpp provide independent instruction
  classification and software dependency checks; gfx950-specific timing remains
  pinned by matrix form in the graph checker.

## gfx1250 wave32 profile

`gfx1250` is a separate target, not a gfx950 alias. Direct Rust analysis selects
its declared target; CLI/Python require explicit matching target selection.
The validated toolchain emits code-object 6 and metadata 1.2. Target features
are deliberately limited to bare `gfx1250`; `gfx1250-strict`, `gfx1251` and
feature suffixes are rejected. The default AMD API target remains gfx950.

The profile uses wave32, low32 EXEC/VCC masks, s0..s105, architected TTMP
registers, and 327,680-byte aggregate LDS capacity. Logical VGPR allocation
reaches 1024; supported named operands are v0..v255, with higher banked
encodings explicitly unsupported. No AGPR namespace is available.
A register spelling being encodable does not mean every instruction can access
all banks: allocation, tuple and instruction constraints are checked separately.
Packed local IDs and the architected workgroup-zero ABI replace the older
system-SGPR workgroup-ID path. Only defined ABI bits are initialized.

The graph checker requires one unclustered workgroup, full native trace evidence
and an end instruction for every participating wave. Hardwired XNACK is not
treated as replay-disabled: X-count replay-source leases are tracked separately
from load/store/DS/KM/async/tensor completion. Signals publish only completed
effects; issue order and execution synchronization do not invent data waits.
Legacy CDNA cache-scope annotations cannot certify gfx1250 publication.

The compiler epilogue `s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)` (immediate3)
is supported only with zero scratch and an immediately following `s_endpgm`.
It drains X replay leases, without inventing load/store completion. Other
messages and any instruction after release before `s_endpgm` are rejected.
This follows LLVM's pinned [X-drain classification](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SIInstrInfo.cpp).

Selected WMMA forms cover F32 16x16x4 and F16/BF16 16x16x32 with F32
accumulators, full-wave legality, separately derived lane layouts and dependency
rules. TDM covers bounded plain 2D global-to-LDS and LDS-to-global transfers,
both directions, two-stage reuse and unnamed shader split barriers. Named,
cluster, multicast, padding, gather and atomic-barrier tensor modes are outside
this profile; nonzero tensor wait thresholds remain inconclusive.

The existing mathematical-real abstraction applies, including disclosed native
base2 conversion coefficients. It does not establish IEEE rounding, NaNs or
denormal behavior. Raw finite F16/BF16 controls test decoding separately from
symbolic mathematical input identities. See the [detailed contract](../../tests/gfx1250/CONTRACT.md)
and [reproducible corpus](../../tests/gfx1250/README.md).
The exact checked-in positive assembly has passed independent execution on real
gfx1250 hardware, including dense and basis WMMA layouts, staged tensor reuse,
wave boundaries and all twenty bounded portable families. Reproduction and
source-pinned receipts are in [the hardware guide](../../tests/gfx1250/hardware/README.md).
This does not expand the selected instruction or mathematical-model contract.
