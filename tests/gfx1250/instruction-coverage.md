# gfx1250 instruction coverage

Coverage belongs to an instruction's target, encoding, operand types and
modifiers. Parsing, typed lowering, completed execution, independent semantic
checks and complete workload proofs are separate stages. The
[stage table](full-parity/stage-support.md) maps the broader selected profile to
tests; this inventory identifies the current bounded FP8 conversion increment.
Neither table measures a percentage of the whole ISA.

## Finite FP8 byte conversion

`v_cvt_f32_fp8` decodes OCP E4M3; `v_cvt_f32_bf8` decodes OCP E5M2. Both
select one byte of a raw 32-bit word. VOP1 uses byte zero; the selected VOP3
profile accepts `byte_sel:0..3`, with zero as its default. Sources are plain
one-word registers or integer-encoded raw words. Modifiers that negate, clamp,
rescale or otherwise reinterpret the source remain outside the BF8 profile.

The public pinned LLVM definitions specify the
[byte-selector profile and lowering](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/VOP1Instructions.td#L692-L745)
and [gfx1250 encodings](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/VOP1Instructions.td#L1085-L1088).
The existing [fixture compiler pin](README.md#regenerate-compiler-fixtures)
identifies the same revision. LLVM-MC accepts BF8 VOP3 selectors 0–3 and aliased
VGPR sources; it rejects a VOP1 selector, out-of-range selectors, source negation
and clamp. Assembler acceptance establishes encoding support only.

| Exact form or boundary | Parser | Typed lowering | Execution and independent oracle | Complete real workload proof |
| --- | --- | --- | --- | --- |
| E4M3 `_e64`, each selector 0–3, scalar raw word | Accepted | Accepted | Every 256-byte pattern in every position; unselected bytes contain NaNs | Existing compiler FP8 packing tests retain their original complete outputs |
| E5M2 `_e64`, each selector 0–3, scalar raw word | Accepted | Accepted | Every 256-byte pattern in every position; unselected bytes contain infinities | No new real-workload proof measured for BF8 VOP3 |
| E5M2 bare / `_e32` byte zero and `_e64` default | Accepted | Accepted | Existing exhaustive VOP1 oracle plus explicit default/inline-word controls | Not established by instruction controls |
| E4M3/E5M2 `_e64` VGPR source, distinct or aliased destination | Accepted | Accepted | All 32 lanes or sparse EXEC; every written output index checked against binary exponent formulas | These are complete instruction-control kernels |
| E5M2 pending scalar source | Accepted | Accepted | KM wait succeeds; load, DS, async or X wait alone retains `ReadBeforeReady`, even when numerical output agrees | No numerical result substitutes for readiness |
| Empty EXEC, undefined source | Accepted | Accepted | Source is not observed; SCC and VCC remain unchanged | Instruction controls only |
| Undefined selected TTMP bits or previously decoded floating values | Recognized source form | Accepted | Explicitly unsupported; no numerical output/proof | Unknown |
| Symbolic E5M2 source storage | Recognized source form | Accepted | Explicitly unsupported for every selector; no inferred floating interpretation | Unknown |
| Selected E4M3 NaN or E5M2 NaN/infinity | Accepted raw bits | Accepted | Refused by the mathematical-real model | Unknown |
| BF8 `_e32` with selector, duplicate/missing/out-of-range selector, non-word source, clamp/negation/SDWA | Refused | Caller-built malformed AST also refused | Cannot become executable IR | Unsupported |
| gfx942/gfx950 retargeting of the native VOP3 selector profile | Refused | Caller-built target change also refused | Unsupported by this profile | Unknown |

The exhaustive denominator is **2 formats × 4 byte positions × 256 patterns =
2,048 conversions**: 2,008 finite results and 40 excluded exceptional patterns
(E4M3 has two NaN encodings; E5M2 has eight NaN/infinity encodings per byte).
This is an exhaustive byte-pattern check of those eight source selections, not
of every operand or instruction encoding. Mathematical reals merge signed zeros;
the tests do not establish physical floating rounding, NaN payloads or exceptions.
Wave masks retain the complete 32-element allocation: the sparse control checks
all 16 written indices and does not claim the other 16 were written.

[`gfx1250_fp8_byte_selection.rs`](../../crates/volta_pipeline/tests/gfx1250_fp8_byte_selection.rs)
contains independent binary exponent formulas, aliases, masks, flag preservation,
counter controls and malformed-AST tests.
[`gfx1250_e5m2_tests.rs`](../../crates/volta_pipeline/tests/gfx1250_e5m2_tests.rs)
retains the byte-zero and symbolic-source controls. Both text input and
caller-built frontend ASTs pass `target::validate` during lowering: it requires
at most one selector with a value in range, the correct encoding and a plain word
source. Executable instructions cannot be constructed through that AST directly.

From the repository root:

```sh
cargo test --release -p volta_pipeline --test gfx1250_fp8_byte_selection --test gfx1250_e5m2_tests
cargo test --release -p volta_pipeline --test gfx1250_packed_data_parity_tests --test gfx1250_byte_definedness_tests
```

## Corpus inventory and remaining work

[`fixtures/emitted-instructions.json`](fixtures/emitted-instructions.json) records
the assembly lines and VOPD components for its explicitly listed compiler
fixtures. Its assembly hashes allow a source inventory to be reproduced without
a GPU. It currently contains 10 files, 1,282 source instructions, 1,314 components
and 112 mnemonic spellings. It is a subset: newer fixtures such as
`native-fp8-packing.s` are not in that historical index. Those counts are source
occurrences, with no implied parser, execution, semantic-test or proof coverage.

For an up-to-date list of tracked fixture assembly, including full workloads:

```sh
git ls-files 'tests/gfx1250/**/*.s'
```

An instruction/form absent from the tables has **unmeasured coverage**, rather
than implied support. Remaining priorities are more public compiler-emitted
forms, BF8 VOP3 in unchanged complete workloads, independent matrix/tensor bounds
controls and combinations of partial waits, async transfers and register reuse.
Existing TTMP/ABI, async LDS, separate-counter, matrix and tensor tests are linked
by the [stage table](full-parity/stage-support.md); their selected positive cases
do not establish all possible interactions. Unsupported or incomplete executions
remain Unknown. No bug-finding, performance or hardware gain is measured here.
