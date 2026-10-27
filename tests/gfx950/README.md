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

The strict completeness check intentionally fails while work remains. The
native workload manifest initially includes infrastructure copy/add cases;
that is not coverage of all 20 baseline workload families. Compiler fixtures,+sources, provenance, emitted-instruction inventory, and portable-workload specs
live under `crates/volta_amdgpu_analysis/src/frontend/fixtures/`.

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
