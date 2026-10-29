# Original-shape gfx1250 parity plan and registration contract

[Issue #21](https://github.com/harsh-nod/ptx_verifier/issues/21) requires the current
Volta portable feature/workflow surface and all original workload shapes and
storage dtypes. This is a finite workload/feature parity effort, not a complete
ISA implementation. Only the coordinator marks acceptance after independent
validation. The completed [issue #13](https://github.com/harsh-nod/ptx_verifier/issues/13)
remains the source-pinned bounded subset; its historical receipts are unchanged.

`gaps.json` records 32 original variants across 20 families at fork `e0511fb` and
upstream `b3a3791`. It includes source/config hashes, actual original array bases,
widths and lengths, argument order, unused dummy parameters, configured block/grid,
logical shapes and strides, sparse output coordinates, existing bounded gfx1250
coverage and gfx950 reference candidates. All 32 **new full-parity** statuses start
pending. The 520 upstream reference-file rows (365 PTX, 137 specs, 18 Rust files)
are a finite review inventory, not already-adjudicated architecture exclusions.
Each needs its actual portable obligation and exact NVIDIA-only residual reviewed.

The original configured footprints contain **395,394 output elements**. Some are
sparse: GEMM/BitDelta retain a 4096-element row pitch, convolution retains a
2916-element channel pitch, and Mamba scan has two separate outputs with a
1024-element row pitch. Declared array lengths and expected written coordinates
are different facts. `contract.output_indices` expands the original coordinate
sets; no total count may substitute one array or coordinate for another.

The original Volta workload harness checks selected CTA0. Its grid can still
carry semantic input: FlashAttention uses grid.x16 to derive T1024. Preserve that
original logical extent. Neither this inventory nor a single-workgroup execution
claims whole-device inter-workgroup race freedom. Native partition changes need
an explicit reviewed mapping that preserves complete original mathematics,
storage conversions, masks, scales and output footprints.

## Registered native source slice

`../full/cases.json` registers W01–W18: the genuine native F16/E4M3 activations,
RoPE, RMSNorm, softmax, matvec and atomic reduction sources from fixture commit
`d3c8d4a596b24adeee4eb055c2818202d4dd9929`. These are **26,466 original configured
outputs**, with original array names/addresses/widths/lengths/kinds, original
blocks/grids and native argument order. The two trailing unused PTX dummy pointers
are explicitly omitted. Both softmax variants retain all six meaningful arguments.
W27–W32 add the six genuine full K4096 GEMM/fused-GEMM/BitDelta entries. Their
native1024/256-thread partitions are explicitly mapped to the original CTA0,
and named output row views retain every original byte address and pitch4096.
W19–W26 remain explicitly unregistered; current registration is not full parity.

Each case has an `original_shape`, explicit dtype labels, source/assembly/spec
hashes, a public `launch_config`, and an `output_projection`. The first slice
preserves the original arrays and launches directly. The validator fails closed
on implicit renaming, launch or ABI changes. The six matrix entries use a narrow
validated mapping for their wave32 workgroup partitions, same-address output
pointer and complete pitched row views; extra arrays, changed input words and
shifted/missing output views fail the registration contract.

The specs describe the existing Volta mathematical-real abstraction on decoded
inputs. Native code retains the original F16/E4M3 storage and conversion points;
physical numeric validation must independently account for those conversions.
For example, the FP8 RoPE quarter-scaled half products and the F16 softmax half
subtraction are not silently removed from the native source. RMSNorm uses the
exact decoded F32 epsilon `9.999999974752427e-7`. Independent original-shape
hardware receipts and symbolic graph/math receipts are separate gates; source
registration or successful compilation is neither of them.

## Check the registration without claiming execution

```bash
python3 tests/gfx1250/full-parity/test_contract.py -v
python3 tests/gfx1250/full-parity/contract.py
```

The second command reports consistent metadata and the number of missing cases;
it explicitly makes no execution/proof claim. The final registration gate is:

```bash
python3 tests/gfx1250/full-parity/contract.py --require-all
```

That command currently fails because W19–W26 are missing. Required Unsupported,
Unknown, timeout/resource errors or smaller decoded-F32 computations do not
satisfy original-shape acceptance. `--require-all` checks registration only; the
coordinator must additionally reproduce every positive graph/math/public-workflow
and hardware gate from issue #21.

## Existing public configuration path

`contract.launch_config` uses the existing strict `LaunchFile` schema. It forwards
array widths/bases/kinds, pointer/int/float/symbol/by-value parameters, globals,
dynamic LDS, instruction budgets and native LDS allocation premises. It does not
invent defined ABI padding or runtime values. JSON launch files now accept the
same optional LDS subobject premises as the CLI and Python:

```json
{
  "block": 64,
  "shared_allocations": [{"name": "tile", "offset": 0, "size": 256}]
}
```

Names/ranges are validated, native execution checks aggregate LDS capacity and
access boundaries, and PTX rejects this native-only premise. Genuine gfx1250 LDS
CLI tests verify all 64 exchange outputs and numeric math, plus omitted-last-word,
over-capacity and PTX rejection controls. This API regression is independent of
full workload completion.

## Public workflow gates

The CLI and Python regression tests check all W01–W18 original cases, **26,466
outputs**, with no sampling. They parse the exact pinned assembly, analyze the
full configured footprint, require verified graphs and compare every result
against its complete mathematical specification with numeric confirmation.
The CLI additionally exports graph/expression artifacts, compares identical
kernels, exports/replays VCs and expressions, and rejects a full-size ReLU versus
sigmoid mismatch. Expression-only replay proves no graph property.

```bash
cargo test --release -p volta_cli --test gfx1250_original_workload_tests
uv run --reinstall-package volta pytest -q crates/volta_py/tests/test_gfx1250_original_workloads.py
```

The separate heavy full32 gate uses the **same original dimensions**, not smaller
parameters. It refuses to start while any registration is missing. Full K4096
matrices can require substantial host memory and runtime; a capacity error or
required Unsupported/Unknown remains a failed gate.

```bash
VOLTA_GFX1250_ORIGINAL_FULL=1 cargo test --release -p volta_cli --test gfx1250_original_workload_tests
VOLTA_GFX1250_ORIGINAL_FULL=1 uv run --reinstall-package volta pytest -q crates/volta_py/tests/test_gfx1250_original_workloads.py
```

`browser.cjs MIXED_HTML EVIDENCE_DIRECTORY` supplements the shared real-Chromium
viewer regression with executed original F16/FP8 atomic reductions and F16/FP8
RoPE conversions. Record the four runs as `original-reduction_f16`,
`original-reduction_f8`, `original-rope_f16`, `original-rope_f8` using
`volta_pipeline`'s `record_viewer_runs` example and the checked-in launch JSON.
Append them to a copied mixed PTX/gfx942/gfx950/gfx1250 store, then run:

```bash
PLAYWRIGHT_MODULE=/path/to/playwright node tests/gfx1250/full-parity/browser.cjs mixed/index.html browser-evidence
```

The browser receipt checks all mixed runs and event/source navigation for these
four actual new traces. It attests rendering only; symbolic/math and independent
physical hardware receipts are separate. The first18 native hardware workload
slice has its own coordinator validation; neither that numeric slice nor these
workflow tests closes the other original families or issue #21.
