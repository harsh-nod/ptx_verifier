# Native gfx942 compiler and hardware controls

Local validation run artifacts are not retained. Source fixtures and reproduction workflows remain available; removed observations do not establish current acceptance.

These four HIP translation units were compiled for `gfx942` on an actual
MI300X host. Their `.s` files are unchanged compiler output, assembled with
`llvm-mc --mcpu=gfx942` and loaded through the HIP module API. This is bounded
CDNA3 coverage. It does not establish complete gfx942 instruction support or
parity with every gfx950 workload and integration fixture.

`cases.json` contains eight kernel configurations and independent mathematical
specifications. `fixtures/compiler-provenance.json` pins HIP, assembly, object
and code-object hashes, exact commands and the ROCm LLVM toolchain. The
instruction inventory records actual source lines; parsing/counts alone do not
establish value semantics or safety.

| Native behavior | Checked footprint |
| --- | --- |
| Copy and add | Symbolic tails at blocks 1, 63, 64, 65, 128 and 256; hardware also covers complete grids with lengths 1, 65 and 257, three input patterns |
| Cross-wave LDS exchange | All 128 outputs equal the opposite wave's inputs; removing the actual publication barrier produces a typed Shared conflict |
| Wave reduction | Two outputs, each containing its own 64 input values exactly once |
| Packed local IDs | All 24 coordinates of block 4×3×2 |
| F32 MFMA 16×16×4 | All 256 dot products; every A/B basis coordinate plus 17 asymmetric dense hardware patterns |
| F16 MFMA 16×16×16 | All 256 dot products; every A/B basis coordinate plus 17 asymmetric dense hardware patterns |
| Two-wave F16 pipeline | All 512 outputs of a row-major 32×16×32 product, cross-wave LDS producers and two staged K tiles |

The Rust tests use the existing native analysis, independent graph checker and
output-equivalence engine. They also use the same optional viewer recorder:

```sh
cargo test --release -p volta_pipeline --test gfx942_compiler_tests
VOLTA_VIZ_DIR=/tmp/gfx942-runs \
  cargo test --release -p volta_pipeline --test gfx942_compiler_tests
```

For example, the genuine compiler copy kernel can be checked through the CLI:

```sh
volta verify tests/gfx942/fixtures/native-copy-add.s tests/gfx942/specs/copy.spec \
  --backend amdgpu --target gfx942 --kernel copy --block 65 --dim N=65 \
  --array x:0x10000:4:65:in --array out:0x30000:4:65:out \
  --param ptr:x --param ptr:out --param int:65
```

To reproduce physical validation, copy the four `fixtures/native-*.hip` files,
`compile_fixtures.py`, `hardware/native.cpp`, `hardware/run.py` and
`validate_mutations.py` into a new directory on an MI300X machine, then run:

```sh
python3 compile_fixtures.py "$fixture_dir"
python3 run.py "$fixture_dir"
python3 validate_mutations.py "$fixture_dir"
```

`fixtures/mutations.json` records successful assembly of four exact native
barrier/wait/spacing mutations. The Rust tests require negative graph results.
Unsafe mutants are not executed on hardware. The target-legality receipt
compares 18 focused forms under the same assembler's gfx942/gfx950 profiles;
it is an encoding probe, not execution support evidence. In particular,
identical FP8 instruction spellings do not establish equivalent CDNA3 FNUZ and
CDNA4 OCP value semantics. No FP8 support is claimed by this fixture set.

The symbolic tests retain the existing mathematical-real contract, excluding
IEEE rounding/NaN/denormal equivalence. They analyze workgroup zero. Complete
physical copy/add grids and guarded numeric tests do not extend that proof
scope. Existing gfx950 corpus and historical evidence remain unchanged.
