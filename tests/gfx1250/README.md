# gfx1250 fixtures and tests

This directory contains compiler-generated gfx1250 assembly, launch manifests,
mathematical specifications, independent oracles and fixture maintenance tools.
CPU analysis and graph checking work without ROCm. Regenerating assembly needs
the pinned ROCm LLVM tools; numerical device checks need a matching GPU.

| Directory or file | Purpose |
| --- | --- |
| `fixtures/`, `cases.json` | Copy, LDS, wave, WMMA, tensor, attention, transpose and exact-wide arithmetic controls |
| `portable-cases.json` | Bounded decoded-F32 workload computations |
| [full-parity/](full-parity/README.md) | Original workload shapes, storage types, output mappings and reference contracts |
| `full/` | Full-size compiler sources, assembly, launch files and specifications |
| [portable-abi/](portable-abi/README.md) | Arguments, globals, dynamic LDS and bounded transfers |
| [portable-boundaries/](portable-boundaries/README.md) | Parser, arithmetic-model and equivalence controls |
| [portable-graph/](portable-graph/README.md) | Completion, publication, named barriers and resource lifetimes |
| [portable-tensor/](portable-tensor/README.md) | Tensor edge tiles, ordinary descriptor storage and copy lifetimes |
| [hardware/](hardware/README.md) | Safe numerical device runners for the smaller fixture corpus |

The [model contract](CONTRACT.md) defines the selected instruction and launch
profile. The [stage table](full-parity/stage-support.md) links parser, lowering,
value, event and checker behavior to tests. [Public sources](PUBLIC_SOURCES.md)
identify the pinned ABI, synchronization, memory and fragment-layout references.

## Run tests

From the repository root:

```sh
cargo test --release -p volta_pipeline --test gfx1250_compiler_tests
cargo test --release -p volta_graph_check --test gfx1250_tests
cargo test --release -p volta_cli --test gfx1250_original_workload_tests
uv run --reinstall-package volta pytest -q crates/volta_py/tests/test_gfx1250_original_workloads.py
python3 -m pytest external/tests -q
```

The original-workload CLI/Python tests normally select W01–W18. Set
`VOLTA_GFX1250_ORIGINAL_FULL=1` to include every original workload; the full-size
matrix and attention cases need substantial host memory and runtime. The
[CPU drivers](full/cpu/README.md) support bounded runs and aggregation without
reducing shapes or sampling outputs.

The common workload harness reads `cases.json` by default. Select
`portable-cases.json` explicitly to run the additional portable fixtures:

```sh
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --binary target/release/volta --color never
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --binary target/release/volta --mutate -k copy --color never
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --manifest tests/gfx1250/portable-cases.json --binary target/release/volta --color never
```

Positive tests compare every configured output. Harmful assembly mutations run
on the CPU and require the intended typed finding; unsupported or incomplete
execution cannot stand in for a successful positive or a detected race.
Expression/VC replay checks equivalence only because those formats do not
contain the native event graph.

## Regenerate compiler fixtures

Use a temporary directory when checking compilation without modifying tracked
provenance:

```sh
fixture_dir="$(mktemp -d /tmp/gfx1250-fixtures.XXXXXX)"
cp tests/gfx1250/fixtures/*.hip "$fixture_dir/"
python3 tests/gfx1250/compile_fixtures.py "$fixture_dir"
python3 tests/gfx1250/oracles.py --output "$fixture_dir/oracle-self-checks.json"
python3 tests/gfx1250/validate_mutations.py --directory "$fixture_dir"
```

The default toolchain is `/opt/rocm-7.2.0/lib/llvm/bin`, AMD LLVM 22 at
`7b800a19466229b8479a78de19143dc33c3ab9b5`. Override it with `--llvm`.
Adjacent `compiler-provenance.json` files record commands and tool/source/
assembly/object hashes. The script rejects an empty source directory.
`emitted-instructions.json` records actual emitted instructions, including both
VOPD components; an inventory entry does not enable every encoding of an opcode.
Subdirectories with LLVM inputs provide their own `check_sources.py` or
`validate_named_profile.py` commands.

`oracles.py` uses dense CPU formulas after decoding the fragment ABI. WMMA
controls check complete tiles, asymmetric inputs and individual A/B basis
coordinates. Exact-wide tests compare integers without f64 coercion. The bounded
attention fixture retains all keys and outputs under the mathematical-real
model; it does not establish physical rounding or approximation-error bounds.

## Record viewer traces

```sh
VOLTA_VIZ_DIR="$PWD/target/gfx1250-viewer" cargo test --release -p volta_pipeline \
  --test gfx1250_compiler_tests -- \
  --skip real_gfx1250_wmma_all_a_and_b_basis_coordinates_run_through_native_interpreter \
  --skip real_gfx1250_wide_product_and_mad_match_exact_unsigned_and_signed_128bit_oracles
cargo run --release -p volta_cli -- --no-log-file viz "$PWD/target/gfx1250-viewer" \
  -o target/gfx1250-viewer.html
```

Use an absolute `VOLTA_VIZ_DIR`; Cargo runs tests from the package directory.
The skipped numeric variations remain part of an unfiltered test run. See the
[browser harness](../../crates/volta_viz/tests/browser/README.md) for Chromium
checks and mixed PTX/AMD stores. Rendering tests, graph checks, mathematical
verification and [device checks](hardware/README.md) exercise different behavior.
Keep generated logs and device receipts outside the repository.
