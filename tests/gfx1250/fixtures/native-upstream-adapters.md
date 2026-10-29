These kernels preserve the computations in the upstream
[`mma_bf16.ptx`](../../../crates/volta_pipeline/tests/ptx/success/mma_bf16.ptx)
and [`mul_hi_u64_concrete.ptx`](../../../crates/volta_pipeline/tests/ptx/success/mul_hi_u64_concrete.ptx)
fixtures. The source and assembly are new gfx1250 compilations; the original
fixture assertions remain unchanged.

`bf16_m16n8k16_fragment_adapter(a, b, native_full, original_four)` launches one
32-thread workgroup. Its BF16 input buffers contain the original 256 A and
128 B halfwords in PTX lane-fragment order. The kernel reconstructs logical
A[16,16] and B[16,8], pads K to32 and N to16 with encoded zero, and invokes
native BF16 WMMA. It writes all256 row-major F32 native results, including
all128 padded zero-column results. A separate four-element F32 output
preserves the exact original lane0 result: (0,0), (0,1), (8,0), (8,1).
These four cells are compared directly with the original PTX analysis as
well as with an independent inverse-fragment, full-matrix oracle. Four tied
`v_nop` instructions preserve the native WMMA software hazard contract.

`high64_division_projection(dividend, reciprocal, out)` launches one thread.
Both U64 operands remain external so the compiler emits the exact limb
multiply/high64/shift/U32 truncation sequence. Binding10 and
12297829382473034411 (0xaaaaaaaaaaaaaaab) yields the original U32 result3.
The CPU tests also cover zero, U64_MAX, and the sign-bit boundary with an
independent unsigned128-bit host reference.

`upstream-adapters-provenance.json` records the default-O2 compiler commands,
compiler/assembler/linker hashes, unchanged assembly and object hashes, and
explicit launch/layout/type mappings. Compilation and CPU graph/equivalence
checks are separate from hardware execution evidence.
