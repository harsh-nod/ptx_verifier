# Implemented gfx1250 contract

This is the selected software model for issue13. Hardware validation is pending;
no target device was available. CPU analysis is usable without ROCm once built.
Compiler encodings, independent semantic checks and device execution are separate
evidence classes.

| Boundary | Implemented envelope |
| --- | --- |
| Target | Bare `gfx1250`; no strict/neighbor alias or feature-suffix fallback |
| Compiler | ROCm7.2 AMD LLVM22, revision `7b800a19466229b8479a78de19143dc33c3ab9b5` |
| Object/metadata | Tested AMDHSA code-object6, metadata1.2 |
| Launch | One unclustered workgroup `(0,0,0)`, grid `(1,1,1)`, 1..1024 workitems |
| Geometry | Wave32; only low32 bits of stored EXEC/VCC masks are physical lanes |
| Registers | s0..s105, logical VGPR allocation1024, encoded operands v0..v255, TTMP0..15; no AGPR namespace |
| LDS | Aggregate static plus dynamic capacity up to327,680 bytes; explicit subobjects optional |
| Inputs | Concrete addresses/control, symbolic mathematical data, exact by-value metadata bytes |
| Replay | Hardwired XNACK; independent X-count address-source leases and data completion |
| Completion | Load/store/DS/KM/X/async/tensor classes; tensor threshold0 only |
| Barriers | Unnamed shader split signal/wait/release with objects/phases and completed-effect publication |
| Matrices | WMMA F32 16x16x4, F16/BF16 16x16x32; F32 accumulation, complete wave32 |
| Tensor | Plain bounded 2D global/LDS transfers in both directions; staged buffer reuse |
| Arithmetic | Existing mathematical reals; exact concrete signed/unsigned64 products and mad |

Register bounds are assembler/ABI probes rather than blanket access guarantees.
Higher banked VGPR encodings are explicitly unsupported; their logical allocation limit is not confused with the supported operand spelling.
Initial ABI state includes only defined architected TTMP fields, descriptor
user-SGPR inputs, packed local IDs and recognized hidden launch values. Runtime
facilities and padding remain undefined unless metadata/configuration defines
them. Argument count/layout, required dimensions, descriptor resources and
static/dynamic LDS bounds are checked before acceptance.

Unsupported or inconclusive modes include clusters/multiple workgroups,
`tg_split`, expert scheduling, general named/privileged barriers, arbitrary raw symbolic format
reinterpretation, legacy CDNA cache visibility certificates, advanced tensor
padding/multicast/gather/iteration/atomic-barrier modes and nonzero tensor waits.
They are not projected into a weaker workgroup-zero safety claim. A required
positive becoming unsupported fails acceptance; deliberate unsupported controls
remain a distinct corpus category.

Each instruction records target-selected source spans, physical masks and
register accesses. Semantic records identify exact counter charges, memory
footprints, sources, destinations and instruction associations. Complete traces
must end each wave. Missing/forged records cannot turn an empty check suite into
acceptance. Waits can establish completion; a barrier or ordinary trace order
cannot fabricate it. Only completed memory effects participate in split-barrier
publication, and replay-source retention is a separate readiness obligation.

The source pins in `fixtures/semantic-references.json` provide reachable public
LLVM ABI, counter, execution, memory and DMA contracts plus independent FlyDSL
layout formulas. Local compiler-source snapshots are secondary comparisons.
Compiler probes in `fixtures/boundary-assembler.json` do not certify semantic
execution. Full native tests use independent dense/basis formulas and typed
assemble-valid harmful mutations. Exact integers are compared without f64
coercion. All positive tests require every configured output, not a sample.

The twenty portable workload ports use bounded complete computations on decoded
F32 mathematical inputs. Their dimensions and dtype/shape exclusions are explicit
in `portable-cases.json`; BitDelta uses concrete index-generated packed words.
These ports are family coverage, not original PTX binary/shape/dtype equivalence.
WMMA raw finite F16/BF16 encodings have separate native tests. No physical IEEE
rounding, NaN, denormal, approximation-error or whole-device execution claim is
made. Required hardware evidence stays open in G1250-09.
