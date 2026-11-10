# Native AMD instruction coverage audit

Instruction coverage is tracked at five separate stages: parsing, typed
lowering, execution, independent semantic checks and complete-kernel proof.
A static opcode count establishes none of the later stages by itself.

| Target | Reproducible source inventory | Execution and semantic evidence | Full-kernel scope |
| --- | --- | --- | --- |
| gfx942 | [Four original modules, 228 instructions, 55 spellings, 72 operand/modifier profiles](../tests/gfx942/instruction-coverage.json); generator parses and lowers all eight entries | Independent scalar-width/address/alias controls and target-specific matrix/readiness checks | Original launch/spec mappings in [cases.json](../tests/gfx942/cases.json), including all 512 two-wave F16 outputs |
| gfx950 | [182 sources, 14,830 instructions, 238 spellings, 725 profiles](../tests/gfx950/instruction-coverage.json); parser/lowerer profiles and bounded positive/negative references remain separate | [Value profiles](../tests/gfx950/instruction-coverage.md) cover specific operand, modifier, target and readiness envelopes; helper links resolve the actual family modules | [Sign-transport compiler proof](gfx950-instruction-coverage.md) retains all 1,344 writes and row holes; other corpus entries retain their own proof boundaries |
| gfx1250 | [Original ten-file index](../tests/gfx1250/fixtures/emitted-instructions.json): 1,279 instructions, 1,311 VOPD components, 109 spellings; newer fixtures are outside this index | [Stage table](../tests/gfx1250/full-parity/stage-support.md) and [FP8 selection controls](../tests/gfx1250/instruction-coverage.md) identify execution and independent-value boundaries | Original workload mappings and full output requirements remain in their manifests; instruction rows alone make no proof claim |

The gfx1250 counts exclude three tensor function labels that an earlier index
mistook for instructions. The correction changes no fixture bytes, workload
population or recorded hardware/study results. Parser acceptance and public
LLVM-MC legality checks remain distinct from semantic or hardware execution.

## Bounded improvement

[Mixed CDNA wait precision](cdna-mixed-waits.md) now proves only the ordered LDS
prefix justified by `lgkmcnt(n)`, even when scalar work is pending. Scalar/FLAT
completion and source lifetimes remain independent. The new full-output controls
use handwritten kernels; unchanged compiler kernels supply separate regression
evidence. Gfx1250 counter semantics are unchanged.

The [common raw-buffer controls](../crates/volta_pipeline/tests/cdna_raw_buffer_wide_tests.rs)
add selected gfx942 linear DWORD/DWORDX2/DWORDX4 execution and gfx950 register
DWORDX4 execution. They retain CDNA3/CDNA4 descriptor fields, full-transfer
preflight and independent VM readiness. The final address is checked after
adding every component, including mixed low bits and carry across bit32.
DWORDX4 store events name the four data registers for the existing two-state
overwrite check. These controls are outside the historical source inventories;
their complete outputs do not establish a new unchanged application proof.

The exact gfx950 scratch disabled-SADDR `off` spelling now enters the existing
fixed-private model with a zero scalar address component. Its distinct trace
kind preserves the ordinary SGPR-read requirement for register-addressed
scratch. This removes one whole-module parser blocker seen in fresh upstream
tile-copy extraction; a complete unchanged tile-kernel proof is not established.

The unchanged gfx950 `reduction_f16` entry now proves its complete registered
selected-workgroup specification after adding bounded scalar lane selectors,
EXEC-word lane counts and no-return F32 atomic addition. The original launch
retains 128 threads, all 4,096 declared half inputs and its initial/output float;
the selected tile adds the first 256 inputs. This does not establish a whole-grid
4,096-element reduction. See the [exact contract and controls](cdna-lane-atomics.md).
Historical source manifests and benchmark outcomes remain unchanged.

The [additional original-kernel configurations](../tests/amdgpu/original-kernel-qualification/README.md)
prove all 1,024 ReLU, 512 SiLU and 128 RoPE outputs from a whole-module gfx942
re-emission of unchanged original F16 source. The bounded low-half zero comparison
needed by ReLU has independent value, mask and malformed-operand controls.
An unchanged gfx1250 Sinkhorn configuration retains all 32 outputs and its full
32-row, 1,024-key, 64-feature problem with six allocations above 4 GiB. This
adds address-configuration evidence for an existing algorithm. These records
remain separate from the historical source inventories above.

## Reproduce the audit

The first two commands repeat native parsing/lowering and detect stale inventory
content. The stage audit checks all three inventories' source hashes, actual
code/test references, original gfx1250 instruction lines and stage-table tests.
It does not execute kernels or imply per-PC execution coverage.

```sh
python3 tests/gfx942/generate_instruction_coverage.py --check
python3 tests/gfx950/generate_instruction_coverage.py --check
python3 tests/amdgpu/audit_instruction_stages.py
python3 tests/gfx1250/test_compile_fixtures_inventory.py
```

Remaining gaps include gfx942 forms absent from its small compiler corpus,
profile-specific gfx950 private/FLAT/ABI interactions and broader complete-kernel
proofs, and gfx1250 instruction forms outside its historical source index or
selected stage tests. Unmodeled mixed async/Tensor completion, symbolic E5M2/BF16
storage and broader matrix formats require their own public-source contracts.
Absence from an inventory means unmeasured coverage. Unsupported or incomplete
execution cannot satisfy a positive proof. No new hardware or bug-finding speed
advantage is established by this source audit.
