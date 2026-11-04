# volta_trainium_analysis

AWS Trainium kernel analysis for Volta, parallel to `volta_ptx_analysis` and
`volta_amd_analysis`. Its input is an NKI kernel: a Python function decorated
with `@nki.jit` that moves tiles between device memory (HBM) and the on-chip
buffers (SBUF, PSUM) and computes on them with `nki.isa` instructions.

The directories mirror the other analyses' stages:

- `src/frontend/`: NKI source parsing.
- `src/ir/`: the instruction representation used by execution.
- `src/lower/`: conversion from parsed kernels to that representation.
- `src/eval/`: symbolic execution.

The frontend is public; the other stages are private.

## Fixtures

`tests/fixtures/add.py` adds two 16 x 16 tensors elementwise: it copies `a`
and `b` from HBM into SBUF tiles (`nisa.dma_copy`), adds the tiles
(`nisa.tensor_tensor` with `op=nl.add`), and copies the sum back to `out` in
HBM.

The supported fixtures are `add`, `sigmoid`, `transpose` and `matmul`. Each
compares parsed AST, lowered IR and symbolic output with checked-in goldens,
then checks the output against a separate `.expected` mathematical reference.
`VOLTA_BLESS=1` can update stage goldens but never rewrites that independent
reference.

Three prospective examples retain their complete source and mathematical
references, but are explicit refusal regressions:

| Example | Current boundary |
| --- | --- |
| `gemm_relu` | Its AST parses; lowering refuses `nki.language.relu`. |
| `rms_norm` | Parsing refuses the decimal literal `0.125`. |
| `tiled_copy` | Parsing refuses the `for` loop. |

These examples have no execution/output proof. Passing their refusal tests
does not establish support for their remaining instructions, loops or slices.
