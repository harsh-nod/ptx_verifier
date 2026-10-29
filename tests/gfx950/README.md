# gfx950 fixtures and workflows

This directory contains source mappings, native assembly controls and workload
replay tools for the CDNA4 backend. The target uses wave64. Its instruction,
format and visibility contracts are separate from gfx1250's wave32 model.

| Path | Purpose |
| --- | --- |
| [instruction-coverage.md](instruction-coverage.md) | Generated exact operand/modifier profiles and stage/test references |
| [portable-scalar/](portable-scalar/README.md) | Scalar, packed data, address and ABI mappings |
| [portable-matrix/](portable-matrix/README.md) | LDS layouts, matrix fragments, storage formats and complete tile outputs |
| [portable-workload/](portable-workload/README.md) | Full matvec/scan publication controls |
| `parity.json` | Pinned source/reference inventory used by `scripts/gfx950_parity.py` |
| `hardware/` | Host drivers for exact native code objects |
| `replay_workloads.py` | Bounded parallel replay with an already-built CLI |

## Run checks

```sh
cargo test --release -p volta_pipeline --test gfx950_portable_scalar_tests
cargo test --release -p volta_pipeline --test gfx950_matrix_parity_tests
python3 scripts/gfx950_parity.py check
python3 ai_compiler_kernels/check_races.py --backend amdgpu --list
python3 ai_compiler_kernels/check_races.py --backend amdgpu
python3 ai_compiler_kernels/check_races.py --backend amdgpu --mutate copy
```

Metadata checks detect source/mapping inconsistencies; they do not execute a
kernel. Pipeline tests parse and lower native assembly, execute the configured
workgroup, check graph properties and compare complete written output sets.
Symbolic floating arithmetic follows the mathematical-real model rather than
IEEE rounding/NaN/denormal behavior. Use the generated stage table to find the
exact supported form and its positive/negative controls.

For parallel full-workload replay, build the revision first and pass its binary:

```sh
cargo build --release -p volta_cli --features logging
python3 tests/gfx950/replay_workloads.py --binary target/release/volta \
  --output /tmp/gfx950-replay --revision "$(git rev-parse HEAD)" --jobs 3
```

The driver retains commands and resource logs, checks full configured footprints
and specifications, and labels supplemental reduced cases separately. It never
builds or substitutes the binary. Full-size proofs can need substantial host
memory; a process/resource failure is not a completed positive result.

## Check exact assembly on a device

Assemble the same `.s` files consumed by the interpreter, then load the code
objects through the HIP module API on a matching gfx950 device:

```sh
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

Additional drivers in `hardware/` cover F16/FP8 portable computations, staged
pipelines and matrix formats. They consume code objects assembled for gfx950;
see each driver's argument checks for its module list. Keep generated receipts
outside the repository. Numerical agreement does not replace race checking or
establish bit-exact equivalence of symbolic real arithmetic.

## Measure analysis size

```sh
cargo build --release -p volta_amdgpu_analysis --example artifact_stats
/usr/bin/time -v target/release/examples/artifact_stats \
  crates/volta_amdgpu_analysis/src/frontend/fixtures/full-gemm-cases.json \
  gemm_f16_full
```

The example reports graph events, memory accesses, expression nodes, output
counts and separate parse/analysis times.
