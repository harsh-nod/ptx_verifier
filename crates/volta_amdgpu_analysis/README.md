# Native gfx950 analysis

This crate mirrors `volta_ptx_analysis`: typed assembly frontend, lowering, one
candidate wave64 execution, then the existing symbolic-output and event-graph
artifacts. It does not depend on the pipeline, equivalence checker, or graph
checker. Backend dispatch and verification remain in the existing pipeline.

The target is LLVM AMDHSA assembly for gfx950, tested with code-object version 6
and metadata 1.2. Compiler fixtures retain source and toolchain provenance under
`src/frontend/fixtures`. CPU-only tests require no ROCm installation or GPU.

## Execution model

The analyzer executes workgroup `(0,0,0)` only. Each wave has one PC, SGPR file,
64-bit `EXEC` and `VCC`, `SCC`, and lane-indexed vector/accumulator storage. It
initializes partial waves and gfx950 packed multidimensional local IDs from
launch dimensions. Initial VCC halves and SCC remain undefined until written.
Reading an undefined flag stops analysis. Scalar instructions execute with empty
`EXEC`; ordinary vector reads/writes and vector memory issues do not. Comparisons
and carry operations still overwrite their scalar mask destination. Activating
nonexistent lanes in a partial wave is rejected.

Initial user/system register assignments come from kernel descriptor enable bits.
Explicit argument bytes come from AMDHSA argument offsets and sizes. Recognized
hidden launch fields are initialized from configuration. Unknown hidden runtime
facilities remain uninitialized and their consumption stops analysis.
Descriptor/user-SGPR disagreement and argument-count disagreement are errors.
Kernarg preloading and module global bindings remain unsupported. Launch checks
enforce descriptor workgroup limits and required dimensions. Split workgroups
are unsupported. Explicit VGPR/AGPR allocations must not alias in the unified
physical register file.

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
Byte inputs acquire a numeric interpretation at their first decoder. OCP E4M3
and signed/unsigned integer-byte interpretations of the same input array cannot
be mixed. Signed loads and native signed-byte-to-F16 conversions preserve numeric
input identities while packing keeps the original byte positions.
General base2 exponentials/logarithms use the exact reciprocal of rounded f32
log2(e), matching the existing PTX mathematical contract; executing that path
records `CompilerBase2Conversion`. Actual instruction coefficients remain exact.

Memory is byte-addressed with explicit symbolic granules. Global allocations must
be disjoint and accesses must lie inside one declared allocation; LDS is bounded
by static plus dynamic size. Wide transfers preserve each register-sized granule
and its byte footprint. Only completely written output elements are extracted.
Missing stores remain missing for downstream equivalence to diagnose. Concrete
integer ALU results retain integer provenance; ambiguous raw-bit output constants
require a conversion instead of guessing their numeric type.

## Events and synchronization

Every issued instruction records its register reads and writes with 64-bit lane
masks. Memory issues separately identify counter class, destinations, held
operands, and attributed byte effects. Kernarg accesses are also recorded.
Counter waits are observations, not assumed universal completion of every
operation. The graph checker owns readiness and ordering proofs. The interpreter
constructs candidate values at issue.

LDS barriers record wave arrivals and releases by generation. LDS visibility
requires the appropriate memory waits as well as rendezvous. DS permutations
snapshot source lanes before writing destinations and record LGKM readiness;
they do not fabricate LDS accesses for the cross-lane network.

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
| Floating data | Mathematical f32/f64 arithmetic, selected conversions/transcendentals, packed f32/f16 operations, partial-half preservation, OCP E4M3 decoding | No IEEE rounding/NaN claim; ordered whole-value F64 storage only; symbolic BF16/E5M2 storage remains unsupported |
| Global and LDS memory | Byte/short/dword and wide transfers, sign extension, narrow-store truncation, dual-offset LDS, static/dynamic LDS bounds | Equal-offset dual LDS operations, scratch, buffer addressing, direct-to-LDS, and atomics remain unsupported |
| Control and synchronization | Scalar branches, concrete EXEC/VCC/SCC, save/restore EXEC, memory waits, workgroup barriers | One workgroup; symbolic comparisons/selectors remain unsupported; partial graph on abort; early-exit barrier patterns are conservative |
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
a convolution tile with the original 576-term reduction and physical pitches,
and reduced online-softmax attention with QK/PV MFMA and LSE outputs. Reduced
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
