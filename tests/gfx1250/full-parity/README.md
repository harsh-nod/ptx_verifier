# Full-workload and feature contracts

This directory defines original-to-native workload mappings and the finite
reference inventory used by the gfx1250 tests. It contains metadata validators
and instruction-stage indexes; executable fixtures live in [`../full`](../full).

| File or directory | Purpose |
| --- | --- |
| `gaps.json`, `contract.py` | Original launch, shape, dtype, ABI and output-coordinate contract |
| [`../full/cases.json`](../full/cases.json) | Native source, assembly, specification and launch registrations |
| `reference-contract.json`, `feature_contract.py` | Pinned reference assertions, goldens and portable obligations |
| `feature-mappings-index.json`, `validate_feature_mappings.py` | Complete source/test inventory across native mapping manifests |
| [stage-support.md](stage-support.md) | Parser, lowering, value, event and checker boundaries |
| [stage-profiles.md](stage-profiles.md) | Generated opcode/operand/modifier profiles from the full compiler modules |
| [`../full/cpu`](../full/cpu/README.md) | Full-output CLI/Python proof drivers and strict aggregation |
| [`../full/hardware`](../full/hardware/README.md) | Independent numerical checks using exact assembly |

## Workload geometry and output mappings

The registry covers 32 variants across activation, RoPE, normalization, reduction,
matvec, convolution, attention, Mamba, GEMM and BitDelta workloads. It preserves
original storage widths, array bases/lengths, scalar arguments, logical extents
and configured launch geometry. Its original projection contains 395,394 output
elements. Some footprints are sparse: GEMM/BitDelta use a 4096-element row pitch,
convolution uses a 2916-element channel pitch, and Mamba scan has two outputs
with a 1024-element row pitch.

`contract.output_indices` expands each array's exact written coordinates.
Declared capacity, written coordinates and total count are distinct: a count
cannot substitute one output array or coordinate for another. Native supersets
and changed workgroup partitions have explicit projections and must preserve
all original coordinates, masks, scales and storage conversions.

These original-workload registrations select workgroup `(0,0,0)`. Configured grid dimensions remain ABI
inputs: FlashAttention uses grid.x=16 to retain sequence length 1024. The native
full-grid hardware runner checks all 1024 query/output rows, including the
source's no-op odd CTAs. A selected-workgroup proof does not establish
inter-workgroup race freedom.

The matrix sources retain K4096 and pitched output row views. Convolution
retains K576, original spatial extents and all output channels with explicitly
mapped two-slot LDS staging. Attention/Mamba preserve null ABI arguments,
source pitches, signed-I8 inputs and separate scales where configured. See
[`original-matrix.md`](../full/fixtures/original-matrix.md) for matrix layouts.

Specifications use the project's mathematical-real abstraction on decoded
inputs. The native source retains F16/E4M3 storage and conversion points;
physical conversion and approximation behavior needs independent numerical
checks. A smaller decoded-F32 workload is a separate fixture, not a replacement
for an original shape or storage contract.

## Validate source registrations

```sh
python3 tests/gfx1250/full-parity/contract.py --require-all
python3 tests/gfx1250/full-parity/test_contract.py -v
python3 tests/gfx1250/full-parity/feature_contract.py
python3 tests/gfx1250/full-parity/test_feature_contract.py -v
python3 tests/gfx1250/full-parity/validate_feature_mappings.py
python3 tests/gfx1250/full-parity/validate_native_mappings.py
```

These checks detect stale hashes, missing or duplicate mappings, changed launch
arguments, shifted output views and invalid test references. They validate
metadata; they do not execute a kernel or prove graph safety or equivalence.
When changing a source, update its adjacent provenance and the affected manifest
pins together. The default mapping check compares its generated source inventory
with the checked-in index, including fixtures imported by Rust tests. The index
records the frozen upstream revision separately. Historical references are
always validated from Git at that revision; their current copies are optional
drift inputs, and deleted copies are listed as historical-only sources. Current
native/shared tests and their imported fixtures must still exist. After an
intentional source or mapping change, regenerate the index and review its diff:

```sh
python3 tests/gfx1250/full-parity/validate_feature_mappings.py \
  --output tests/gfx1250/full-parity/feature-mappings-index.json
```

Preserve original reference fixtures and complete goldens.

The reference contract links PTX fixtures, shared specifications and aggregate
Rust tests to exact native controls or narrow target-specific differences.
NVIDIA descriptor encodings, TMEM resources and cluster scheduler operations
remain distinct from native arithmetic, byte layout, storage lifetime and
publication. A target-specific encoding difference does not eliminate those
portable properties. Native mapping details are adjacent to the ABI, scalar,
packed-data, matrix, tensor, memory and graph fixtures.

## Run public workflows

The default CLI/Python tests cover W01–W18 with complete configured outputs:

```sh
cargo test --release -p volta_cli --test gfx1250_original_workload_tests
uv run --reinstall-package volta pytest -q crates/volta_py/tests/test_gfx1250_original_workloads.py
```

Run every original case with:

```sh
VOLTA_GFX1250_ORIGINAL_FULL=1 cargo test --release -p volta_cli --test gfx1250_original_workload_tests
VOLTA_GFX1250_ORIGINAL_FULL=1 uv run --reinstall-package volta pytest -q crates/volta_py/tests/test_gfx1250_original_workloads.py
```

These tests parse the pinned assembly, analyze every output, require verified
graphs and verify the full mathematical specification with numeric confirmation.
The CLI tests also exercise exports, comparison, expression/VC replay and a
full-size refutation. Expression-only replay supplies no graph property.
Use the [CPU drivers](../full/cpu/README.md) to select case groups, cap resources
and aggregate full-output results. Unknown, Unsupported, missing outputs,
resource limits and nonzero exits do not satisfy a positive check.

Launch files use the public strict `LaunchFile` schema, including optional
native LDS subobject premises:

```json
{
  "block": 64,
  "shared_allocations": [{"name": "tile", "offset": 0, "size": 256}]
}
```

Names/ranges, aggregate capacity and access boundaries are validated. These
premises do not define padding or invent runtime ABI values; PTX rejects this
native-only setting.

## Browser checks

`browser.cjs` checks mixed-store rendering and source/event navigation for the
recorded original reduction and RoPE traces. Record the launch JSON files with
`volta_pipeline`'s `record_viewer_runs` example under these names:
`original-reduction_f16`, `original-reduction_f8`, `original-rope_f16`, and
`original-rope_f8`. Build a mixed-store HTML page, then run:

```sh
PLAYWRIGHT_MODULE=/path/to/playwright node tests/gfx1250/full-parity/browser.cjs mixed/index.html /tmp/gfx1250-browser
```

Browser output verifies rendering and navigation. It does not replace graph,
mathematical or numerical device checks.
