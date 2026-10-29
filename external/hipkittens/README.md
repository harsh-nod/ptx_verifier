# HipKittens extraction and race checks

The extractor builds selected CDNA4 kernels from the
[HipKittens](https://github.com/HazyResearch/HipKittens) submodule into native
**gfx950** assembly. It compiles the original softmax, rotary and BF16 GEMM
translation units without source rewrites. `vector_copy.cpp` is a local
control that exercises HipKittens global/register vector loads and stores.
The extractor requires the clean submodule revision selected by the repository.

```sh
git submodule update --init external/sources/HipKittens
just extract-hipkittens
just hipkittens
just hipkittens --strict -k vector_copy
```

Compilation needs ROCm with gfx950 support, but no GPU, PyTorch or AITER.
Analysis of the generated assembly uses the CPU CLI. Use `--compiler`,
`--assembler` and `--out` to select tool and output paths. The extractor checks
AMDHSA target/argument sizes, assembles outputs with `llvm-mc`, and writes
source/compiler/assembly provenance beside the generated files. Existing
launch configurations are preserved unless `--write-launches` is supplied.
Generated assembly, metadata and CSV results are ignored; the source submodule
and launch configurations are tracked.

## Launch and result contracts

Launches retain the original tensor descriptor strides and declare the memory
footprint reachable by workgroup zero. GEMM uses a 256×256 output tile and both
K=128 pipeline stages. These launches cover that workgroup, not the full grid.
Kernel instructions and loops are not rewritten to shrink the applications.

HipKittens passes tensor descriptors in by-value structs. Native launch JSON
accepts `{"bytes": [0, 1, ...]}` and Python exposes `volta.Param.bytes(...)`.
The payload must exactly match the AMDHSA `by_value` argument size. The caller
supplies every byte, including pointers and padding; PTX rejects this form.
The extractor's `launches()` function defines descriptor offsets, little-endian
encoding and explicit array bases.

The race adapter reports `RACE-FREE`, failed checks, `UNSUPPORTED`, `UNKNOWN`
and process errors separately. `--strict` fails on unsupported or inconclusive
results. Missing inputs, crashes, inconsistent exits, incomplete output coverage
and empty selections also fail. An unsupported application is inconclusive;
resolving one unsupported instruction may expose another boundary.

The local vector-copy control has an independent identity specification and a
numerical hardware driver. The driver checks values; it does not prove race
freedom. To analyze and run the exact extracted assembly:

```sh
volta --no-log-file --backend amdgpu --target gfx950 verify \
  external/hipkittens/cdna4/vector_copy.s \
  'dim N; array x[N]; array out[N]; out[i] = x[i];' \
  --config external/hipkittens/cdna4/vector_copy.wg0.launch.json --dim N=256

/opt/rocm/llvm/bin/llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 \
  -filetype=obj external/hipkittens/cdna4/vector_copy.s -o /tmp/vector_copy.o
/opt/rocm/llvm/bin/ld.lld -shared /tmp/vector_copy.o -o /tmp/vector_copy.hsaco
hipcc --offload-arch=gfx950 -O2 external/hipkittens/check_vector_copy.cpp -o /tmp/check_vector_copy
/tmp/check_vector_copy /tmp/vector_copy.hsaco
```

Fresh extraction can change compiler symbols and artifact hashes. Use the
adjacent provenance to identify what was compiled and run.

## Other targets and adapter tests

The configured HipKittens extraction profile is gfx950. Requesting gfx1250
returns an actionable `UNSUPPORTED` diagnostic; CDNA4 macros and wave64 launch
contracts cannot be retargeted by changing a target string. For independent
native gfx1250 adapter controls, see the [gfx1250 guide](../gfx1250/README.md).

```sh
python3 -m unittest discover -s external/tests -v
```
