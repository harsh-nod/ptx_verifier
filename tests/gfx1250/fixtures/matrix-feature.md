`matrix-feature-contract.json` maps all 32 original references across matrix LDS
layout (8), strided layout (4), raw accumulators (2), numeric layout (8) and
publication (10). Each row pins its original assertion/source/golden, genuine
native source and test, complete native output views and target-specific
residual. All entries remain candidates for coordinator acceptance.

The layout sources expose every gathered half at 32-, 48-, 64- and native-legal
40-byte row pitches, all 256 weighted matrix outputs, all 128 original raw or
immediate C fragments plus the 256-cell native tile, four gathered fragment pairs,
and every lane word. The original stmatrix byte20 result is checked against its
PTX execution and golden independently of the extra 32 native words.

The numeric source preserves logical M128/N8 and M128/N256 geometry. It checks the
original 136/17/408 outputs and every additional padded native coordinate, raw
F32 C seeds, exact E4M3/E5M2 format differences and the original gap between packed
FP8 cores. Disabled output0 and a precise uninitialized LDS consumer are separate
CPU controls. The latter keeps global stores and LDS publication in distinct loops
so the source reaches its intended definedness property. An assemble-valid
unmodeled native WMMA mode is explicitly rejected rather than silently erased.

The new publication source uses two wave32 groups. Wave0 computes a full 16×16
weighted WMMA tile; wave1 reads all 256 results through LDS after completion and
a workgroup barrier. A completed prior zero phase lets the missing-publication
mutation produce a complete candidate trace. Four actual assembler-valid CPU
mutations separately test LDS completion, cross-wave publication, early result
reads and source-register leases. Every candidate retains all 256 output
coordinates and an intended typed finding; none passes through an aborted or
resource-limited trace. PTX TMEM/commit/fence encodings retain precise residuals;
the native 64-thread partition does not claim an identical TMEM/CTA footprint.

```sh
cargo test --release -p volta_pipeline \
  --test gfx1250_matrix_layout_parity \
  --test gfx1250_matrix_numeric_parity \
  --test gfx1250_matrix_publication
python3 tests/gfx1250/full-parity/validate_native_mappings.py \
  --contract tests/gfx1250/fixtures/matrix-feature-contract.json
```

`matrix-positive-cases.json` lists all 15 safe positive entries, exact argument
order, storage widths, shapes and independent numerical/raw-word formulas.
Compilation provenance pins actual unchanged assembly, MC objects and linked code
objects. This inventory contains no hardware observations or execution receipts.
Overlapping producers, missing synchronization, disabled producers and unmodeled
modes stay on CPU. Symbolic expressions use the repository's mathematical-real
model; physical numeric validation is a separate gate.
