# gfx950 integration and parity evidence

This directory tracks AMD implementation evidence against upstream commit
`e8f819919e5d4628b68aa735deacaaa48d46cf23`. The authoritative scope and workstreams
are in [issue 1](https://github.com/harsh-nod/ptx_verifier/issues/1).

`parity.json` inventories 359 integration fixtures, 136 mathematical specs, and
32 workload artifacts. A pending row is unfinished work. Compiled fixtures,
successful parser tests, and inconclusive safety results do not close a row.
Only the coordinator records validated completion after integration testing.

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

The strict completeness check intentionally fails while work remains. The
native workload manifest includes copy/add, portable FP16/FP8, full-size GEMM,
convolution and attention-family cases, alongside matrix/ID and ABI controls.
Reduced cases are explicitly labeled and do not replace full baseline shapes.
Complete baseline coverage requires reviewed dispositions in `parity.json`.
Compiler fixtures,
sources, provenance, emitted-instruction inventory, and portable-workload specs
live under `crates/volta_amdgpu_analysis/src/frontend/fixtures/`.
The [instruction coverage table](instruction-coverage.md) separates parsing,
lowering, value semantics, events and checks, with positive/negative controls
and explicit limits. Regenerate or check it with
`python3 tests/gfx950/generate_instruction_coverage.py --check`.

`baseline.json` records 1059 passing Rust tests, one existing Rust false-positive
regression (`test_aligned_bar_sync_reached_on_different_iterations`), and 15
passing Python tests before AMD implementation. The baseline failure is kept
visible and must not be suppressed to manufacture a successful full-suite run.

## Exact native assembly hardware check

`hardware/native_copy_add.cpp` runs code objects assembled from the same `.s`
files consumed by the symbolic interpreter. With the pinned ROCm tools:

```sh
llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj \
  clang22-copy-add.s -o copy.o
ld.lld -shared copy.o -o copy.hsaco
llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj \
  clang22-mfma-f32.s -o mfma.o
ld.lld -shared mfma.o -o mfma.hsaco
hipcc -O2 native_copy_add.cpp -o native-check
./native-check copy.hsaco mfma.hsaco
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

The portable FP8 runner independently decodes OCP E4M3 inputs and compares the
native results to CPU formulas. Matrix checks cover individual A/B basis inputs
and asymmetric dense patterns; pipeline references use ordinary row-major
matrix multiplication. Output buffers start from a sentinel before execution.
`evidence/hardware-2026-10-27-initial-corpus.json` records the exact source and
code-object hashes, toolchain, patterns, tolerances, and observed results.

`evidence/baseline-workloads.json` records all 32 original PTX workload outcomes
under an 8 GiB per-process address-space cap. The four original full-K4096 GEMM
cases pass when rerun with a larger memory envelope, as recorded separately in
`evidence/baseline-workloads-large-memory.json`. These are required positive
parity cases. Their earlier resource failures are not an unsupported-feature
exception.
