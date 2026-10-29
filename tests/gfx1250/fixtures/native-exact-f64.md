These four kernels preserve the exact binary64 coefficients, output dtype,
launch size, and complete one-element outputs of the original
`concrete_fma_vs_mul_add{,_2}.ptx` and
`runtime_sum_differs_from_prerounded_literal{,_2}.ptx` assertions.
They are new gfx1250 compilations; no assembly was retargeted.

| Native entry | Original computation |
| --- | --- |
| `exact_f64_fma` | Encoded 0.1 × encoded 0.2 + encoded 0.3, one F64 FMA |
| `exact_f64_mul_add` | The same coefficients, separate F64 multiply and add |
| `exact_f64_runtime_sum` | Encoded 0.1 + encoded 0.2 |
| `exact_f64_prerounded_literal` | The separately encoded binary64 0.30000000000000004 |

Every entry uses block `[1,1,1]`, grid `[1,1,1]`, and one output pointer to
an eight-byte F64 element. Empty inline compiler barriers retain the original
operations in registers rather than allowing constant folding. The literal
entry uses a native floating addition of zero to establish F64 provenance
for an otherwise untyped native store.

The CPU tests compare every exact output expression with both the original
`.out` golden and the original PTX analysis. They retain the original pair
outcomes: FMA and multiply/add are equivalent in Volta's mathematical-real
model; the runtime sum and separately encoded rounded literal differ.
This model preserves the exact input binary64 constants without inserting
IEEE rounding between symbolic arithmetic operations. Physical hardware
rounds its encoded operations, so hardware measurements and their IEEE
reference must be reported separately.

`exact-f64-provenance.json` pins the real default-O2 source/assembly,
compiler, assembler, linked object hashes, and 56 actual target/encoding
observations. The selected new F64 VOPD3 profile accepts aligned X-slot
add/multiply paired with disjoint Y-slot MOV-zero initialization. Other
F64 pair profiles remain explicitly outside this selected frontend profile.
