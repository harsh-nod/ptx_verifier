# HipKittens race checks on gfx950

This follows the existing ThunderKittens extraction and external-race workflow.
The source submodule is the official
[HazyResearch/HipKittens](https://github.com/HazyResearch/HipKittens), pinned to
`8cde3dd146bd1c4be78023b582c1f4375c48489f`. The extractor compiles the original
CDNA4 softmax, rotary and BF16 GEMM translation units without source rewrites.
It also builds `vector_copy.cpp`, an explicitly local control using HipKittens'
global/register vector load and store functions.

```bash
git submodule update --init external/sources/HipKittens
just extract-hipkittens               # ROCm clang++, Python deps supplied by uv
just hipkittens                      # build CLI, analyze all four launches
just hipkittens --strict -k vector_copy
```

Compilation needs ROCm with gfx950 support but no GPU, PyTorch or AITER. Analysis
of the generated `.s` files requires only the CPU CLI. The extraction script also
assembles each output with `llvm-mc`, checks the compiler's AMDHSA target and
argument sizes, and emits source/compiler/assembly provenance in adjacent JSON.
Generated assembly, metadata and CSVs are ignored, as in the PTX workflow;
the source submodule and `.launch.json` configurations are tracked. Use
`--compiler`, `--assembler` and `--out` to select tool/output paths. Existing
launch files are preserved; `--write-launches` explicitly regenerates them.

Each application launch retains the original tensor descriptor strides and
declares only the memory footprint reachable by workgroup zero. GEMM uses a full
256×256 output tile and both K=128 pipeline stages. These configurations do not
establish properties of the full grid. Kernel instructions and loops are not
rewritten to shrink the application.

HipKittens passes tensor descriptors in by-value structs. The launch format now
accepts `{"bytes": [0, 1, ...]}` as a native parameter and Python exposes
`volta.Param.bytes([...])`. The byte count must exactly match a `by_value`
argument in AMDHSA metadata. Every byte, including pointer values and padding,
is caller supplied; PTX rejects this form. The extractor checks descriptor field
offsets against the compiler and constructs little-endian launch payloads with
explicit array bases. Its `launches()` function is the readable ABI recipe.

Observed results with ROCm 7.2 / clang 22 (`7b800a19466229b8479a78de19143dc33c3ab9b5`):

| Source | Result | Current boundary |
| --- | --- | --- |
| Original softmax | `UNSUPPORTED` | `v_mad_i64_i32` |
| Original rotary | `UNSUPPORTED` | `v_mad_i64_i32` |
| Original BF16 GEMM | `UNSUPPORTED` | `v_rcp_iflag_f32_e32` |
| Local vector-copy control | `RACE-FREE` | 256/256 outputs; identity spec also `ACCEPT` |

An unsupported result is inconclusive. The three application rows are not
claims of race freedom, and resolving their first unsupported instruction may
expose further unsupported operations. `--strict` fails on unsupported or
unknown results. Missing inputs, process crashes, inconsistent exits, incomplete
output coverage and empty selections fail rather than silently passing.

The control's output expressions were checked against `out[i] = x[i]` for all
256 elements. Removing its five VM wait instructions produced a typed
`ReadBeforeReady` register hazard. The exact generated control assembly was also
assembled and linked, then run on `mi350-2` for 257 input patterns and 65,792
numeric output checks. This hardware check tests values, not the absence of races.

```bash
volta --no-log-file --backend amdgpu --target gfx950 verify \
  external/hipkittens/cdna4/vector_copy.s \
  'dim N; array x[N]; array out[N]; out[i] = x[i];' \
  --config external/hipkittens/cdna4/vector_copy.wg0.launch.json --dim N=256

/opt/rocm/llvm/bin/llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 \
  -filetype=obj external/hipkittens/cdna4/vector_copy.s -o /tmp/vector_copy.o
/opt/rocm/llvm/bin/ld.lld -shared /tmp/vector_copy.o -o /tmp/vector_copy.hsaco
hipcc --offload-arch=gfx950 -O2 external/hipkittens/check_vector_copy.cpp -o /tmp/check_vector_copy
/tmp/check_vector_copy /tmp/vector_copy.hsaco

python3 -m unittest discover -s external/tests -v
```

Recorded control assembly SHA-256:
`a31f9cf90a7253277c54b5215756daa988ef41739e4466f775065bcf721cae5c`.
The hardware-tested code object SHA-256 was
`1304dade7a822693c16d5ee4b9a4dce98068290fb1faac1acac968fc7bb3fd7f`.
Regeneration can change file/CUID symbols; inspect the newly emitted provenance
instead of assuming that rebuilt artifacts have these hashes.
