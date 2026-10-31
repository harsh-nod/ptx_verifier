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
compilation alone makes no verification claim. Compiler crashes, unexpected
process errors, and 60-second stage timeouts have distinct statuses.
The explicit `-cuid` uses the target and source hash, so changing an output
directory does not change HIP's compilation-unit symbol or the assembly hash.

For each configured case, the runner first requires every graph check to pass
and compares exported expression coordinates with the exact original output
contract. It then checks every specification element, without sampling.
Missing outputs, unknown verdicts, unsupported instructions, timeouts and process
crashes cannot become `verified`. The wall-clock limit applies separately to
analysis and specification checking. This inventory is not a latency benchmark.

## Verification coverage

Every registered case verifies with the selected CDNA integer16 extension:

| Family | gfx942 | gfx950 | gfx1250 |
| --- | --- | --- | --- |
| Elementwise | verified | verified | verified |
| Reduction | verified | verified | verified |
| Normalization | verified | verified | verified |
| Transpose | verified | verified | verified |
| GEMM | verified | verified | verified |
| Attention | verified | verified | verified |

These 18 configurations retain all 708 output elements. Verification includes
independent graph checks, the exact output coordinates and every original
specification element. Use the run command above to regenerate the result for
a particular executable; the report binds its hash and the unchanged manifest.

The earlier source baseline `45bf80b3fdf35d818d9dbbc2ecf4c01e935cf9ed`
verified eight configurations and refused ten during whole-module parsing:
`v_lshlrev_b16_e32` at line 709, in the unselected `portable_softmax` entry.
Further required forms were `v_cmp_ne_u16_e32` and gfx950 `v_bitop3_b16`.
The extension validates and models selected legal forms without extracting
entries or rewriting assembly. The shared register-source `v_cmp_u_f32`
spelling also receives its CDNA target profile. This improves module acceptance;
it does not establish a full softmax verification result.

The [selected instruction contracts](../../../docs/amd-semantic-audit.md#compiler-driven-narrow-integer-forms)
describe low16 data, low4 shift counts, truth-table ordering, EXEC behavior,
operand encodings and symbolic U16 comparison masking. New narrow shift/BITOP3
results leave upper16 bits unknown conservatively; an observed unknown bit
cannot become a value, address or control decision. The gfx1250 encoding and
undefined-bit rules remain separate. These forms do not introduce scratch,
general buffer addressing or new synchronization support.

The complete modules remain unchanged. A successful selected entry does not
establish execution support for every other entry in its module.

The reusable source modules also contain kernels outside these registrations.
Those kernels have no verification claim from this corpus. Preserve each row's
shape, dtype, complete output set and specification when comparing extensions.
