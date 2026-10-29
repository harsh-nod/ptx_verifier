# gfx1250 hardware replay

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
python3 -m unittest discover -s tests/gfx1250/hardware -p '*test*.py'
```

## Bounded portable workloads

The second host-only driver, `portable.cpp`, evaluates independent CPU formulas
for all twenty cases in `portable-cases.json`. Its runner pins parameter order,
array shapes, source revision and artifact hashes before launching the exact
`native-portable-workloads.s` module. Run it locally on the GPU host with
`--local`, or use the built-in SSH staging from a clean committed checkout:

```sh
python3 tests/gfx1250/hardware/portable_run.py --host mi400 --device 2 \
  --result /tmp/hardware-portable.json
```

The default seventeen patterns include zeros, signed alternating values and
bounded asymmetric coordinates. Each pattern checks all 590 outputs, every
input byte, inter-array gap and 4-KiB edge guard. The receipt records exact
comparison tolerances and errors per kernel. Nine CPU-only runner controls
reject incomplete manifests, changed sources, wrong ABI/layout, incomplete
results, identity overrides and stale PASS receipts. The common discovery
command above runs these alongside the seven core-runner controls.

## Coordinator acceptance

On `mi400`, four actual gfx1250 devices report wave32 and 256 compute units each.
The core author ran GPU0 and the portable author ran GPU1. The coordinator
reviewed both drivers and repeated both complete suites on GPU2 at source
`97b5df0ab258a3818f41bfc1d2620649185e1384`.

| Independent coordinator replay | Launches | Complete output checks | Receipt |
| --- | ---: | ---: | --- |
| Core mechanisms, all WMMA basis and wide integer boundaries | 3,615 | 644,518 | [Core](../evidence/hardware-core-coordinator.json) |
| Twenty bounded portable families, seventeen patterns each | 340 | 10,030 | [Portable](../evidence/hardware-portable-coordinator.json) |

The core replay checked 1,850,880 output-guard bytes and 1,070,520 input/guard
bytes. Portable replay checked 135,388 input bytes, 61,139,140 gap bytes and
2,785,280 edge-guard bytes. The count totals cover repeated checks across
launches, not unique storage capacity.

These runs use ROCm `10.2.0a20261013+bkc.20261019` and LLVM24 revision
`c7ceccf9a5789b92fda4056b8501450d0b7a75de` to assemble/link the unchanged
LLVM22 fixture output. All hardware comparisons pass. Core attention's maximum
absolute error is `5.89e-8`; the portable maximum is `3.73e-7`, within the
disclosed tolerances. Exact comparisons cover the dyadic and raw integer cases.
Supplemental multi-block copy execution does not expand the verifier's
single-workgroup contract. The author receipts are retained separately as
[core](../evidence/hardware-core-mi400.json) and
[portable](../evidence/hardware-portable-mi400.json).
