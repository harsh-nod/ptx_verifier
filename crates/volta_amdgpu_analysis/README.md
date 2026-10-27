# Native gfx950 analysis

This crate mirrors `volta_ptx_analysis`: typed assembly frontend, lowering, one
candidate wave64 execution, then the existing symbolic-output and event-graph
artifacts. It does not depend on the pipeline, equivalence checker, or graph
checker. No rocjitsu code, dependencies, or test oracle are used.

The initial target is LLVM AMDHSA assembly for gfx950, tested with code-object
version 6 and metadata 1.2. Compiler fixtures retain their source and toolchain
provenance in `src/frontend/fixtures/PROVENANCE.txt`. CPU-only tests require no
ROCm installation or GPU.

## Execution model

The analyzer executes workgroup `(0,0,0)` only. Each wave has one PC, SGPR file,
64-bit `EXEC` and `VCC`, `SCC`, and lane-indexed vector storage. It initializes
partial waves and multidimensional local IDs from launch dimensions. Scalar
instructions execute with empty `EXEC`; vector memory issues do not.

Initial user/system register assignments come from kernel descriptor enable bits.
Explicit argument bytes come from AMDHSA argument offsets and sizes. Recognized
hidden launch fields are initialized from configuration. Unknown hidden runtime
facilities remain uninitialized and their consumption stops analysis.
Descriptor/user-SGPR disagreement and argument-count disagreement are errors.
Kernarg preloading and module global bindings remain unsupported.

Integers and addresses use fixed-width wrapping arithmetic and concrete register
bits. Symbolic input data remains separate from address bits. Input identities
use existing expression-arena names and indices. The floating-point abstraction
follows the repository's real-number contract: rounding, denormals, and IEEE NaN
behavior are outside the claim. Encoded halves and packed pairs retain separate
symbolic identities. Arbitrary symbolic reinterpretation is unsupported.

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

The supported native matrix form is `v_mfma_f32_16x16x4_f32`, all 64 lanes active,
default layout modifiers. A/B/C/D mappings derive from CDNA4 ISA section 7.1.4,
pages 47–50. Inputs are snapshotted before overlapping destinations change.
Matrix issue and NOP delay events allow downstream checks to enforce the ten
independent wait states before ordinary result consumption. Partial waves and
nonzero matrix layout modifiers are unsupported. Other shapes, FP8/scaled forms,
direct-to-LDS pipelines, scratch/buffer addressing, DPP, and atomics remain work
in progress. Lane-register moves and explicit M0 writes require additional
software dependency checks before support.

Budgets, unsupported instructions, invalid accesses, and malformed state preserve
a partial event graph and withhold symbolic outputs. Budget exhaustion is
inconclusive, not a synchronization deadlock.

## Focused validation

Run `cargo test -p volta_amdgpu_analysis -j4`.

Execution tests check complete output identities for native copy/add and tails
at block sizes 1, 63, 64, 65, 128, and 256; wide transfers; missing stores;
budget-limited partial graphs; cross-wave LDS exchange; actual compiler reduction
with each input appearing exactly once; packed-f16 ReLU; and all 256 coordinates
of native f32 MFMA against independently enumerated dot products.

Workflow, safety mutation, serialization, and hardware tests live with pipeline
integration. These focused tests are foundation evidence, not full parity.

Primary references:

- [AMD CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
  sections 4, 7.1.4, 7.6, 8.3, 10.2, and 12.12.
- [LLVM AMDGPU ABI](https://llvm.org/docs/AMDGPUUsage.html).
- LLVM GCNHazardRecognizer.cpp, checkMAIVALUHazards and
  GFX940_SMFMA_N_PassWriteVgprVALUMemExpReadWaitStates independently confirm the
  selected eight-pass SGEMM form's ten wait states.
- AMD matrix calculator revision 2ef91896bcdc4d26624f952e5c905c787cd9bc9e
  independently matches this form's CDNA3 mapping. That revision has no CDNA4
  support, so it supplies no gfx950 timing evidence.
