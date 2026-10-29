# gfx950 integration and parity evidence

Local validation run artifacts are not retained. Source fixtures and reproduction workflows remain available; removed observations do not establish current acceptance.

This directory tracks AMD implementation evidence against upstream commit
`e8f819919e5d4628b68aa735deacaaa48d46cf23`. The authoritative scope and workstreams
are in [issue 1](https://github.com/harsh-nod/ptx_verifier/issues/1).
This is a frozen baseline inventory, not a claim of complete coverage of later
upstream additions or other AMD targets. See the [upstream functionality audit](../gfx1250/UPSTREAM_AUDIT.md)
for the subsequent rebase and its documented native counterparts.

`parity.json` inventories 359 integration fixtures, 136 mathematical specs, and
32 workload artifacts. A pending row is unfinished work. Compiled fixtures,
successful parser tests, and inconclusive safety results do not close a row.
Only the coordinator records validated completion after integration testing.

After removal of run records, the inventory has **316 validated entries,
two explained PTX-only contracts, one baseline limitation and 208 pending entries**.
Rows whose sole validation records were removed preserve their old disposition
under `historical_validation`. Those observations do not satisfy current
acceptance, so `--require-complete` correctly fails until they are revalidated.

```sh
python3 scripts/gfx950_parity.py check
python3 scripts/gfx950_parity.py summary --require-complete
python3 ai_compiler_kernels/check_races.py --backend amdgpu --list
python3 ai_compiler_kernels/check_races.py --backend amdgpu
python3 ai_compiler_kernels/check_races.py --backend amdgpu --mutate copy
```

For a reproducible parallel replay, build the revision first and pass its binary
to `replay_workloads.py`. The driver calls the existing workload harness, checks
complete output footprints and every configured mathematical spec, retains commands and resource logs,
and keeps supplemental reduced cases explicitly labeled. It never builds or
substitutes a binary. Large full-shape proofs require substantial host memory.

```sh
cargo build --release -p volta_cli --features logging
python3 tests/gfx950/replay_workloads.py --binary target/release/volta \
  --output /tmp/gfx950-replay --revision "$(git rev-parse HEAD)" --jobs 3
```

`baseline.json` records 1059 passing Rust tests, one existing Rust false-positive
regression (`test_aligned_bar_sync_reached_on_different_iterations`), and 15
passing Python tests before AMD implementation. The baseline failure is kept
visible and must not be suppressed to manufacture a successful full-suite run.

## Exact native assembly hardware check

`hardware/native_copy_add.cpp` runs code objects assembled from the same `.s`
files consumed by the symbolic interpreter. With the pinned ROCm tools:

```sh
# Run from the repository root; adjust the ROCm installation path as needed.
rocm_llvm=/opt/rocm-7.2.0/lib/llvm/bin
gfx950_fixtures=crates/volta_amdgpu_analysis/src/frontend/fixtures
"$rocm_llvm/llvm-mc" --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj \
  "$gfx950_fixtures/clang22-copy-add.s" -o /tmp/gfx950-copy.o
"$rocm_llvm/ld.lld" -shared /tmp/gfx950-copy.o -o /tmp/gfx950-copy.hsaco
"$rocm_llvm/llvm-mc" --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj \
  "$gfx950_fixtures/clang22-mfma-f32.s" -o /tmp/gfx950-mfma.o
"$rocm_llvm/ld.lld" -shared /tmp/gfx950-mfma.o -o /tmp/gfx950-mfma.hsaco
hipcc -O2 tests/gfx950/hardware/native_copy_add.cpp -o /tmp/gfx950-native-check
/tmp/gfx950-native-check /tmp/gfx950-copy.hsaco /tmp/gfx950-mfma.hsaco
```

The check covers copy/add tail and wave-boundary configurations and optional
MFMA coordinate/basis cases with an independent numeric reference. It requires
an actual gfx950 device. Numerical agreement provides additional validation;
it does not prove race freedom or bit-exact equivalence of the real-number
symbolic model. Hardware evidence must identify fixture hashes, tools, device,
tested revision, and observed results.

The additional hardware runners consume code objects assembled in the same way:

```sh
hipcc -O2 native_portable_f16.cpp -o native-f16
./native-f16 portable-f16.hsaco
hipcc -O2 native_portable_f8.cpp -o native-f8
./native-f8 portable-f8.hsaco
hipcc -O2 native_pipeline.cpp -o native-pipeline
./native-pipeline clang22-ids-3d.hsaco \
  clang22-pipelined-mfma-f32.hsaco clang22-pipelined-mfma-f16.hsaco
hipcc -O2 native_mfma_types.cpp -o native-matrix-types
./native-matrix-types cdna4-mfma-types.hsaco
```

## Artifact scale measurements

The public native-analysis example reports candidate graph events, memory
accesses, expression nodes, output counts, and separate parse/analysis times:

```sh
cargo build --release -p volta_amdgpu_analysis --example artifact_stats
/usr/bin/time -v target/release/examples/artifact_stats \
  crates/volta_amdgpu_analysis/src/frontend/fixtures/full-gemm-cases.json \
  gemm_f16_full
```
