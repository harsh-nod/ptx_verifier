# gfx950 instruction coverage

This inventory describes the native `volta_amdgpu_analysis` backend. Each row
names a bounded instruction profile; it is not a percentage of the gfx950 ISA.
The first slice covers three sign-bit operations and one F32 comparison relation.
Other encodings, operand classes and interacting instruction families require
their own controls before this inventory can grow.

| Profile | Parse and typed lowering | Execution | Independent semantic controls | Complete compiler kernel |
| --- | --- | --- | --- | --- |
| `v_and_b32` with `0x7fffffff` | E32 literal; E64 register mask | Clear F32 sign or retain exact integer word | Absolute value; raw u32; chained operations; aliases and source orders | `float_ops`, all 1344 writes |
| `v_xor_b32` with `0x80000000` | E32 literal; E64 register mask | Toggle F32 sign or retain exact integer word | Negation; raw u32; chained operations; aliases and source orders | Same unchanged kernel |
| `v_or_b32` with `0x80000000` | E32 literal; E64 register mask | Set F32 sign or retain exact integer word | Negative absolute value; raw u32; chained operations; aliases and source orders | Same unchanged kernel |
| `v_cmp_lg_f32` | Selected non-EXEC comparison forms | Ordered unequal under the existing real model | Equal, less and greater operands; VCC selection; SCC preservation; NaN refusal | Same unchanged kernel |

The sign-bit equations follow the exact u32 operations in the public
[CDNA4 ISA, §12.7 and §12.11](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf).
An executed F32 consumer fixes an input array's floating interpretation. A
sign-bit operation on that input or a typed real result can then use `abs`,
negation or negative `abs` in the real model. An untyped input instead retains
both its raw word expression and a deferred F32 interpretation. A later numeric
consumer selects the interpretation; incompatible integer and floating uses
are refused. Expression shape never establishes a floating format.

The controls also check inactive EXEC lanes with undefined sources, flags,
load readiness, arbitrary masks, modified operands and integer words whose
encodings include high bits or NaN payloads. Raw NaN payloads remain valid
integers, while ingesting them as F32 is refused. Existing real-model limits
remain: IEEE rounding, NaNs and signed zero are not modeled. The existing
extended-real handling of infinities is unchanged. Gfx950 E64 literal masks
remain an encoding refusal; materializing a mask in a register is required.
`v_cmpx_lg_f32` remains unsupported by this slice.

## Complete-kernel check

The [native pipeline test](../crates/volta_pipeline/tests/gfx950_float_sign_transport_tests.rs)
uses the unchanged public [assembly](../tests/gfx950/fixtures/upstream-float-sign/float_ops.s)
and independently transcribes all 21 assignments from the
[OpenCL source](../tests/gfx950/fixtures/upstream-float-sign/float_ops.cl).
Both fixtures entered upstream at
[`abd90436`](https://github.com/francois141/ptx_verifier/commit/abd90436ac8a8e33dde8546fcc3d46f31f08f529)
and are retained byte-for-byte in a [native-owned fixture directory](../tests/gfx950/fixtures/upstream-float-sign/README.md):

| Input | SHA-256 |
| --- | --- |
| `float_ops.s` | `db9d32e5480e499d8741a0ab370b8e2008f9a42190f177660e41258eeb012a62` |
| `float_ops.cl` | `d4f37620712703c6b3510b26d35e3558ef519f47cb572044832809520794bb8f` |

Upstream later changed its experimental backend's live `float_ops` fixtures.
Those files remain separate; this native regression uses the pinned originals
above, including all three sign-bit assignments.

The launch retains all 64 work-items, both 64-element input arrays and the
complete 2048-element output allocation. Each work-item writes columns 0–20 of
its 32-float row: 1344 values and 704 unwritten allocated positions. The test
requires all 44 entry instructions to execute, graph verification, the exact
written footprint and equivalence of every written expression. It does not
execute or trim the uncalled helper retained in the original module.

The source oracle spells `x > y` as `y < x`, and `x >= y` as `y <= x`.
These are exact identities in the declared real model. This keeps predicate
orientation consistent without requiring a new equivalence-checker rule.
Transcendentals retain the backend's explicit real-arithmetic and pinned base-2
conversion assumptions; this is not a hardware IEEE-conformance result.

```sh
cargo test --release -p volta_pipeline --test gfx950_float_sign_transport_tests
```

## Remaining coverage

Full ISA coverage needs a public instruction/form inventory with separate
parser, lowering, execution, independent-value and interaction evidence.
Priorities include mixed VM/LGKM waits, DMA/M0 hazards, LDS and FLAT bounds,
MFMA operand layouts and reachable device-library bodies in complete kernels.
Existing tests cover selected profiles in those areas; this sign-bit slice
does not qualify their remaining forms or close the architecture-wide work.
