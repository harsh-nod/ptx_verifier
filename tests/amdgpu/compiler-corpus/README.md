# Compiler corpus

This corpus registers six bounded computations for gfx942, gfx950 and gfx1250:
ReLU, row reduction, RMS normalization, unsigned-16 transpose, GEMM and attention.
The HIP implementations and specifications are reused unchanged from the existing
portable fixtures. Each target has independently compiled, unmodified assembly.
These cases do not replace the original-shape/dtype full-workload contracts.

`cases.json` pins public source and compiler revisions, compilation flags,
source/assembly/specification hashes, shapes, element widths, row-major layouts,
launch geometry, arguments and every selected-workgroup output coordinate.
F32 cases use the existing mathematical-real abstraction and decoded finite
inputs. The transpose transports unsigned 16-bit elements. Neither abstraction
establishes bit-exact floating-point behavior or inter-workgroup safety.

## Reproduce

From the repository root:

```sh
python3 tests/amdgpu/compiler-corpus/corpus.py check
python3 tests/amdgpu/compiler-corpus/test_corpus.py -v
python3 tests/amdgpu/compiler-corpus/corpus.py extract \
  --llvm /opt/rocm-7.2.0/llvm/bin --rocm-path /opt/rocm-7.2.0 \
  --output /tmp/amd-compiler-extraction
python3 tests/amdgpu/compiler-corpus/corpus.py run \
  --binary target/release/volta --binary-revision "$(git rev-parse HEAD)" \
  --output /tmp/amd-compiler-results --jobs 3 --timeout 60
```

The runner never builds or relabels assembly. Use a binary built from the supplied
revision; the revision argument is a caller-provided label, while the report also
records the executable hash. Choose a fresh results directory. Raw output,
expressions and software run records stay outside the repository.

Extraction requires the pinned LLVM revision. It invokes Clang separately for
each target, then checks every module with `llvm-mc`. Compiler/assembler rejection
is reported as `compiler_unsupported`, separately from verifier gaps. Successful
compilation alone makes no verification claim.
The explicit `-cuid` uses the target and source hash, so changing an output
directory does not change HIP's compilation-unit symbol or the assembly hash.

For each configured case, the runner first requires every graph check to pass
and compares exported expression coordinates with the exact original output
contract. It then checks every specification element, without sampling.
Missing outputs, unknown verdicts, unsupported instructions, timeouts and process
crashes cannot become `verified`. The wall-clock limit applies separately to
analysis and specification checking. This inventory is not a latency benchmark.

## Baseline and blockers

On source revision `45bf80b3fdf35d818d9dbbc2ecf4c01e935cf9ed`, using the
recorded compiler revision and unchanged modules:

| Family | gfx942 | gfx950 | gfx1250 |
| --- | --- | --- | --- |
| Elementwise | unsupported | unsupported | verified |
| Reduction | unsupported | unsupported | verified |
| Normalization | unsupported | unsupported | verified |
| Transpose | verified | verified | verified |
| GEMM | unsupported | unsupported | verified |
| Attention | unsupported | unsupported | verified |

The leading blocker is **whole-module parsing of a CDNA instruction form**:
`v_lshlrev_b16_e32` at line 709 of each CDNA portable module. The containing
entry is `portable_softmax`, which is not one of the selected cases. The parser
rejects that module before selected-entry execution. Thus this result establishes
ten blocked configurations, not ten selected kernels requiring that instruction.
Any ISA extension must first isolate the relevant computation and establish
target-specific semantics; adding one spelling may expose additional blockers.

The complete modules are retained intentionally so this extraction boundary is
visible. The successful transpose modules are separate and do not contain the
blocking entry. Address forms, private spills, synchronization and capacity did
not produce the first rejection in this bounded set; that observation does not
establish support for their broader forms. No compiler rejection, semantic
finding, inconclusive verdict, timeout or crash occurred in this baseline run.

The reusable source modules also contain kernels outside these registrations.
Those kernels have no verification claim from this corpus. Preserve each row's
shape, dtype, complete output set and specification when comparing extensions.
