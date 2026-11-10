# Additional original-kernel configurations

These cases reuse the unchanged HIP sources, specifications, launch geometry,
storage widths and complete output contracts from the
[original workload registry](../../gfx1250/full/cases.json). They add the
following configurations without changing the historical registries or studies:

| Target | Kernel | Original computation | Complete outputs |
| --- | --- | --- | ---: |
| gfx942 | `relu_f16` | 128 threads × eight F16 elements | 1,024 |
| gfx942 | `silu_f16` | 128 threads × four F16 elements | 512 |
| gfx942 | `rope_f16` | 128 F16 elements, exact opposite-half permutation and coefficient identities | 128 |
| gfx1250 | `sinkhorn_original` | 32 rows × 1,024 keys × 64 features, F16 data and F32 potentials | 32 |

The gfx942 assembly is a whole-module re-emission of
[`original-f16.hip`](../../gfx1250/full/fixtures/original-f16.hip) with the pinned
public ROCm LLVM compiler. All nine emitted entries remain in the file. The
three selected entries establish new target configurations; they do not prove
execution of the six unselected entries. The source hash, compiler revision,
compiler/assembler hashes, flags and emitted assembly/object hashes are in
[`cases.json`](cases.json).

The required new execution form is the gfx942 VOPC comparison
`v_cmp_lt_f16_e32 vcc, 0, vN`, also accepted without an encoding suffix.
It compares inline zero with the low F16 half of one VGPR, leaves that VGPR
unchanged and writes the wave64 predicate mask under EXEC. The existing
decoded finite-real arithmetic model applies. Independent controls distinguish
positive/negative halves, signed zero, subnormals, irrelevant upper bits and
lane predicates under full/sparse EXEC. NaN, undefined data, other encodings,
relations, operands and mutable-AST variants cannot silently extend this
profile. Existing graph dependencies still require loaded values to be ready.
The public [CDNA3 ISA reference](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf)
and [LLVM encoding syntax](https://releases.llvm.org/18.1.6/docs/AMDGPUUsage.html#instruction-syntax)
define the hardware form; this finite-real profile does not claim general IEEE
F16 comparison support.

The gfx1250 Sinkhorn case retains the existing assembly and full original
mathematical problem. Its only launch-file change is moving all six disjoint
allocations to aligned bases above 4 GiB. This is new address-configuration
evidence for an existing algorithm. It requires no new gfx1250 instruction
semantics and supplies no new application-bug discovery claim.

## CPU graph and mathematical checks

```sh
python3 tests/amdgpu/original-kernel-qualification/qualify.py check
python3 tests/amdgpu/original-kernel-qualification/test_qualify.py -v
cargo test --release -p volta_amdgpu_analysis --test gfx942_f16_zero_compare
python3 tests/amdgpu/original-kernel-qualification/qualify.py run \
  --binary target/release/volta --binary-revision "$(git rev-parse HEAD)" \
  --output /tmp/original-kernel-qualification
```

Build the supplied binary from the stated revision; the revision is a builder
label, while the receipt separately hashes the bytes actually executed. The
runner snapshots the binary, selected unchanged inputs and validation helpers,
pins dynamic libraries, checks every graph property and exact output coordinate,
then uses `--sample 0 --verify-numeric` on every original specification element.
It validates the original shape/dtype/ABI contract before applying the one
explicit allocation relocation. The default per-stage limits are 300 wall/CPU
seconds, 16 GiB RSS and 32 GiB address space. Limits, nonzero exits, unknown
verdicts, missing coordinates or incomplete VCs remain incomplete. Keep the
fresh snapshot, logs and receipt outside the source tree. These are correctness
checks, not a latency benchmark.

This runner uses the shared original inventory/registration validators directly.
Historical replay tools retain their separate pinned-harness requirements; a
successful new qualification does not relabel or revalidate an older receipt.

The graph and full-output mathematical checks succeed for all four registered
configurations. Arithmetic remains the project's mathematical-real abstraction;
selected-workgroup proofs do not establish inter-workgroup safety or bit-exact
floating-point behavior. No tensor or reduction dimension is shortened.

## Exact-assembly numerical checks

The [common hardware catalog](../hardware/README.md) includes one new
`original_qualification` group on each target. It assembles the exact registered
module and runs ten complete dense/zero/basis patterns with independent CPU
references, unchanged input bytes and guarded allocations:

| Target | Launches | Compared outputs | Checked input bytes | Checked guard bytes |
| --- | ---: | ---: | ---: | ---: |
| gfx942 | 30 | 16,640 | 38,400 | 655,360 |
| gfx1250 | 10 | 320 | 1,434,880 | 491,520 |

The gfx1250 driver requires every real allocation address to have a nonzero
upper32 word. Physical addresses are allocator-selected and need not equal the
symbolic bases. Numerical device receipts provide separate evidence from the
CPU graph and mathematical checks. GPU execution is positive-only; seeded
unsafe controls are never launched.
