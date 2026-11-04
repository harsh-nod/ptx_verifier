# Packed data and byte-format fixtures

These compiler sources preserve the reference assertions in
`PACKED-F32-TYPING` and `FP8-BYTES-PACKING`: 15 packed-F32 rows and 9 FP8 rows.
`packed-data-contract.json` pins each original assertion, source/golden, native
entry and exact output view. Compilation provenance records source and
encoding hashes; graph/equivalence tests check complete payloads separately.

The 22 positive payloads compare every original coordinate against both the
original PTX execution and its checked-in golden. They retain independent packed
F32 components, shift/or/zero-extension paths, sparse pointer stores, raw halves,
integer recombination, OCP E4M3 bytes and F16 pack/unpack/conversion outputs.
An additional square-only mutation must report exactly `out[0..4]` mismatches;
an assemble-valid missing-load-wait mutation completes all four output expressions
but fails the typed native readiness property with `ReadBeforeReady`.

The two remaining rows have precise model/storage contracts. Concrete OCP NaN
stays outside the real-number model. Native `GLOBAL_LOAD_U8` zero-extends its
register, so its high byte is independently checked as zero; the original PTX
scalar-register undefined-high-byte rule is retained as an explicit storage
residual. Neither rule substitutes an unsupported result for a required positive.

```sh
python3 tests/gfx1250/full-parity/validate_native_mappings.py
python3 -m unittest discover -s tests/gfx1250/full-parity -p test_native_mappings.py
cargo test --release -p volta_pipeline --test gfx1250_packed_data_parity_tests
```

`packed-positive-cases.json` describes safe positive source/ABI layouts for a
separate hardware runner. Kernel argument order is optional input pointer then
output pointer, with the declared element widths and written index sets.
NaN/refusal and intentionally missing synchronization controls stay on CPU.
