# Original-shape GEMM contracts

`hipkittens_complex.py` builds finite launch and mathematical contracts from
the complete public HipKittens sources at
[`8cde3dd`](https://github.com/HazyResearch/HipKittens/tree/8cde3dd146bd1c4be78023b582c1f4375c48489f).
It reuses unchanged, compiler-emitted, MC-accepted modules from an extraction
campaign. It does not compile a smaller substitute kernel or execute a GPU.

| Profile | Original host cases | Threads | Original output tile | Layout of original C |
|---|---:|---:|---:|---|
| `gfx1250-gemm00` | All four `utils.SHAPES` cases for `00_gemm_naive.cpp` | 128 (four wave32 waves) | 64 × 64 | Column-major |
| `gfx950-bf16-gemm` | All seven `test.test_shapes` cases for `256_256_64_32_with16x32.cpp` | 512 (eight wave64 waves) | 256 × 256 | Row-major |

[contracts.json](contracts.json) pins the host lists, source/header/build inputs,
entrypoint symbols, source layouts, complete original allocations, and both
mathematical equations. Large and nonsquare cases are retained. The smallest
gfx1250 case remains `M=2048,N=1024,K=1024`; the gfx950 cases are the original
host tests, rather than the earlier extractor's separate `256×256×128` launch.
Only the noncluster rung 00 is included. This profile does not establish support
for the other ladder rungs, cluster launches, or unrelated HipKittens kernels.

## Launch and output scope

Each result concerns workgroup `(0,0,0)` under the original full grid. All
original A and B allocation extents, full K loops, descriptor dimensions and
strides are retained. The gfx1250 grid is `(M/64,N/64,1)`, with 8,704 dynamic LDS
bytes. The gfx950 grid is `((M/256)*(N/256),1,1)`, with the original 160,000-byte
dynamic LDS request. Its chiplet and tile swizzles both map workgroup zero to
tile zero for these host shapes.

The original C allocation base, dimensions and byte extent are recorded for
every case. The native launch interface forbids overlapping arrays and cannot
declare a full C allocation over separately named output views. Consequently,
the launch declares disjoint contiguous views of every element written by the
selected workgroup:

- gfx1250: `Cj[i]` occupies original matrix index `j*M+i`, for all `0≤i,j<64`;
- gfx950: `Ci[j]` occupies original matrix index `i*N+j`, for all `0≤i,j<256`.

The views retain absolute physical addresses and the original leading dimension.
They cover all 4,096 or 65,536 required tile elements. They do not compact C or
assert that other workgroups ran. The rest of C is an allocation premise in the
metadata, rather than an overlapping launch array. Access outside the declared
views can therefore cause a conservative allocation refusal even when it falls
inside the original full C allocation. A result is a selected-workgroup result,
not a full-matrix or whole-application proof.

The specification declares complete `A[M,K]` and `B[N,K]` inputs and defines
every output view by `sum(k in 0..K,A[row,k]*B[col,k])`. Sampling is disabled.
This is the verifier's abstract mathematical computation, not an IEEE rounding
simulation or the upstream Torch tolerance comparison. The separately generated
wrong equation adds one to the first entire output view. It is a passing
negative control only if a complete, graph-verified original first exists and
the verifier refutes that equation; parser refusals do not pass it.

## By-value ABI

The layout check includes the complete original source and adds only
non-executable compiler `static_assert`s. It uses the original compilation
flags with syntax-only output. It checks every descriptor field offset,
aggregate size, member offset, thread geometry and LDS-size premise.

| Target | GL descriptor | First parameter | Following visible parameters |
|---|---:|---:|---|
| gfx1250 | 40 bytes: pointer and four 64-bit dimensions | 120-byte `gemm_globals` containing A, B and C descriptors | M, N and K at bytes 120, 124 and 128 |
| gfx950 | 48 bytes: pointer and four 64-bit dimensions, plus eight padding/dictionary bytes | 168-byte `micro_globals`, including stream and cached dimensions | M, N and K at bytes 168, 172 and 176 |

The gfx950 stream field is zero in the device argument payload; device code does
not read it. The cached M/N/K and the separate scalar parameters agree with the
host shape. Compiler-emitted AMDHSA metadata independently checks visible argument
roles/offsets/sizes, wave size, workgroup limits and absence of private scratch.

## Run or validate

```sh
git submodule update --init external/sources/HipKittens
uv run external/extraction/hipkittens_complex.py --check
python3 -m unittest discover -s external/tests -p test_hipkittens_complex.py -v

uv run external/extraction/hipkittens_complex.py \
  --campaign /tmp/hipkittens-complete-source-campaign \
  --binary /absolute/path/to/volta --binary-revision FULL_SOURCE_COMMIT \
  --build-record /absolute/path/to/build.json \
  --output /tmp/hipkittens-original-complex-gemms --timeout 60
```

`--profile` selects one finite profile; the default retains both. `--source-root`
selects a clean checkout of the exact public source revision. `--write-contract`
explicitly regenerates the source/shape contract after reviewing changes.
Normal execution refuses contract drift, modified source, stale assembly/object
hashes, changed emitted metadata or an inconsistent by-value ABI.

The build record uses the caller-attested schema described by
[`measure_tensor_bounds.py`](../../../tests/gfx1250/measure_tensor_bounds.py).
It binds a clean source revision, executable hash, tracked Rust-workspace
fingerprint, release profile, default features, build command and tool versions.
It does not cryptographically prove that those sources produced the executable.
The installed ROCm/Python/include dependencies are not a hermetic toolchain image.

Raw output must be a new directory outside the repositories. It retains the
layout checks, MC and parse logs, every original-shape verification command,
launch/specification bytes and source/build/helper hashes. Source, tools,
executable, build record and generated inputs are checked again before the
final report. Failed, unsupported and timed-out cases remain in that report.
Do not silently reduce allocations or K when a later supported execution exceeds
the fixed budget.

## Recorded functional boundary

[functional-20261031.json](functional-20261031.json) records one CPU-only pass
using source `f0ee44285286aa1ea92f3e99aed6574ad89f3c82` and executable SHA-256
`57d555dbafee093f804b2c0744c477c4a5e567726aece81017f828647bdbc167`.
Both complete modules passed fresh MC assembly and the source-derived layout
assertions. All four gfx1250 launches stopped in the frontend at line 294:
`matrix_a_reuse` is a bare modifier after four WMMA operands, while that parser
profile reports five operands. All seven gfx950 launches stopped at line 75:
`v_rcp_iflag_f32_e32` is unsupported. No graph execution or mathematical proof
was reached; both wrong-equation controls were unavailable. The receipt is a
source-bound launch-contract and refusal record, not a kernel-support claim or
latency comparison.
