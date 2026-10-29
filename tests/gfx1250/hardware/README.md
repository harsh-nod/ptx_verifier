# gfx1250 core hardware replay

`run.py` compiles the host-only HIP module driver, assembles the **unchanged**
checked-in native `.s` files, links code objects, and runs safe positive kernels.
It does not compile the fixture HIP sources or run mutants. A real `gfx1250`
wave32 device is required. No reset or runtime service changes are performed.

Run from a checkout on the GPU host:

```sh
python3 tests/gfx1250/hardware/run.py \
  --rocm /opt/rocm --device 0 \
  --build-dir /tmp/ptx-gfx1250-core-build \
  --receipt /tmp/hardware-core.json
```

A copied `tests/gfx1250` subtree also works; supply `--source-commit` with the
full fixture commit SHA because `.git` is absent. `--suite` selects a bounded
safe group. Each process sets `HIP_VISIBLE_DEVICES` to the requested physical
ordinal; unset `ROCR_VISIBLE_DEVICES` and `CUDA_VISIBLE_DEVICES` first. Coordinate
GPU ordinals with other users. The runner rejects architecture overrides and
preload interposition, and verifies `ldd` resolves the HIP runtime to the exact
requested ROCm library before launching a kernel. Each launched kernel has a 10-second completion
deadline and each subprocess has a bounded timeout. An asynchronous error or
kernel timeout terminates the process without attempting a device reset.

The 14 manifest cases are covered by copy/add wave boundaries and tails,
cross-wave LDS exchange, wave32 reduction and XYZ IDs, F32/F16/BF16 WMMA,
two-wave two-stage GEMM, two-stage tensor load/store with reused LDS, attention,
raw 16-bit transpose, and signed/unsigned high64 multiply/add. Extra cases cover
all 2,176 A/B WMMA basis coordinates and raw by-value vector encodings. Every
launch compares every output. Inputs and 256-byte edge guards are checked byte
for byte. Float outputs begin as NaN; integer outputs begin as complements of
their expected values so missing writes cannot pass. No sampled comparisons are
used. The seven host checker negative controls launch no GPU kernels and are
reported separately.

CPU references use ordinary logical matrix dot products, double `exp` and
normalization for attention, and host `__int128` arithmetic for the emitted GPU
32-bit limb sequences. Only native WMMA buffer packing/unpacking follows the
fragment ABI. Deterministic dyadic matrix inputs keep all exact-reference sums
representable in F32. Attention permits `atol=1e-5, rtol=1e-4` against CPU double;
all other comparisons are exact. This bounded corpus does not establish all
IEEE exceptional behavior or arbitrary tensor descriptor support.

The JSON receipt contains actual device identity, tool/runtime hashes, fixture
commit and source hashes, exact object/code-object hashes, commands and timeout
output, suite geometry/seeds/tolerances, and counts of executed launches,
outputs, guards and unchanged input bytes. Driver and runner hashes identify
local changes independently of the fixture commit. An operational failure atomically replaces any previous result with an
`INCOMPLETE` receipt and stops; it never converts a failure into a passing case.

CPU-only failure-provenance regression tests (no ROCm or GPU required):

```sh
python3 -m unittest discover -s tests/gfx1250/hardware -p test_runner.py
```
