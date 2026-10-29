# Exact integer fixtures

`exact-integer-provenance.json` maps the `INTEGER-BITS` reference assertions to
native entries. It pins PTX/golden hashes, launch dimensions, storage widths,
sparse written coordinates, compiler commands and encoding probes.

`gfx1250_exact_integer_parity.rs` compares every printed value/expression and
written coordinate, checks native graph properties and independently analyzes
the PTX for full-output equivalence. Additional controls reject symbolic SCC
used for branches, carry, EXEC or addresses; preserve SCC across multiplication;
and check lowest-active-lane selection and pending-load hazards.

The C++ source retains runtime operations with register constraints. Explicit
U32/F32 identity consumers establish the interpretation of untyped stores.
Clipping/saturation logic implements PTX field/shift behavior where native
instructions differ. Byte scratch kernels retain a two-element output
allocation while writing only the specified coordinate.

The cancellation fixture checks all 64 doubled elements under a never-steal
premise. It does not implement NVIDIA cluster cancellation or work stealing.
Physical numerical behavior needs a separate device check.
