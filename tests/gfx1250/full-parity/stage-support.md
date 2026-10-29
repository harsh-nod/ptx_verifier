# Selected native gfx1250 stage coverage

This table describes the selected compiler and portable-feature profiles.
It is not an ISA coverage percentage. An opcode name alone does not enable
every encoding, tuple, modifier or operand type. The frontend validates every
instruction in the selected entry, including unreachable and empty-EXEC code;
lowering and execution can impose additional conditions. A parsed instruction
or successful LLVM-MC invocation is not a verified computation.

The unchanged original workload sources and their tool/source/assembly/object
pins are in [`../full/fixtures`](../full/fixtures). The original/native launch,
ABI, dtype and output mappings are in [`gaps.json`](gaps.json) and
[`../full/cases.json`](../full/cases.json). New feature modules have adjacent
compiler-provenance files. Public semantic source revisions are pinned in
[`../fixtures/semantic-references.json`](../fixtures/semantic-references.json).

All test filenames below are relative to `crates/volta_pipeline/tests/`.
“Complete” describes the test's required footprint, rather than a count of
instructions accepted by the parser. Full-workload commands are documented in the
[CPU](../full/cpu/README.md) and [hardware](../full/hardware/README.md) guides.

| Source forms and boundary | Frontend / lowering | Values | Events / checker | Positive and negative controls |
| --- | --- | --- | --- | --- |
| AMDHSA entry, metadata, packed local IDs, hidden grid and argument fields | Exact target, operand tuples, descriptor and argument layout; no invented padding | Only defined argument/runtime bytes initialized; original grid retained for selected workgroup zero | Target, geometry and source spans retained; zero/overflowing geometry rejected | `gfx1250_portable_abi_tests.rs`, `gfx1250_boundary_parity_tests.rs`, `rejected_tests.rs` |
| Concrete scalar/vector integer, carry, high64 multiply/mad and control flow | Selected signed/unsigned widths, literal positions and branch targets checked | Exact concrete integer and bit behavior; symbolic mathematical operations only within their typed profile | Physical low32 EXEC/VCC masks, source reads and destination writes; branch budget and termination | `gfx1250_exact_integer_parity.rs`, `gfx1250_exact_scalar_parity.rs`, `gfx1250_saveexec_tests.rs` |
| F32 arithmetic/conversions, F16/BF16/FP8 storage, packed F32 and lane operations | Selected opcode-specific modifiers and true16/subword tuples; E5M2 is plain-word VOP1 byte0 only | Mathematical reals with disclosed exp/log coefficients; finite raw decoding and exact transport checked separately | Exact partial-register footprints; inactive/uninitialized sources and readiness preserved | `gfx1250_exact_f32_parity.rs`, `gfx1250_packed_data_parity_tests.rs`, `gfx1250_packed_subword_tests.rs`, `gfx1250_float_bit_transport_tests.rs`, `gfx1250_e5m2_tests.rs`, `gfx1250_exact_wave_parity.rs` |
| Ordinary GLOBAL, scalar loads, LDS, atomics and selected FLAT | Transfer widths, address operands, scopes and target modifiers checked; scalar-base FLAT scaling is selected B32 only | Initialized bytes, concrete addresses, symbolic payloads, initial atomic output and raw storage retained | Full-width bounds/subobjects, read/write/RMW conflicts, data completion and independent X replay leases | `gfx1250_global_byte_alignment_tests.rs`, `gfx1250_byte_definedness_tests.rs`, `gfx1250_ds_two_address_tests.rs`, `gfx1250_native_flat_tests.rs`, `gfx1250_flat_scaled_index_tests.rs`, `gfx1250_compiler_tests.rs` |
| Cross-wave global publication | Source profile preserves explicit `scope:SCOPE_SYS` on resolved-global FLAT effects; graph contract also handles appropriately scoped ordinary GLOBAL events | Scope does not change payload values | Both endpoints, completion and happens-before required for write dependencies; completed read-before-write has its own narrow ordering rule; no cross-workgroup proof | `gfx1250_tensor_parity_tests.rs`, direct graph tests in `volta_graph_check::amdgpu` |
| Load/store/DS/KM/X/async/Tensor waits and VGPR-release epilogue | Exact wait class/threshold and epilogue placement; nonzero Tensor thresholds remain inconclusive | Completion never supplies a missing value or initialized byte | Counter attribution, readiness, source leases and full-wave end records; no barrier-created data completion | `gfx1250_async_memory_tests.rs`, `gfx1250_tensor_capture_tests.rs`, `gfx1250_true16_graph_tests.rs`, direct graph tests in `volta_graph_check::amdgpu` |
| Unnamed and selected named shader barriers | Allocated IDs 1–16, M0 selector/count, INIT/JOIN/SIGNAL/WAIT/LEAVE; signal-time bits22:16 set a nonzero expected count, zero leaves it unchanged; no cluster form | Explicit participant/count/phase/incarnation state, signal-time setters1–127 and typed below-arrived rejection; disputed equal-to-arrived boundary remains Unsupported/Unknown; NULL behavior follows the selected operation | Only completed effects publish; initialization/use and noncommuting setters/drops need execution order; equal setters commute only within their validated count preconditions; join/lifetime/incarnation and progress remain independent of issue order | `gfx1250_named_barrier_tests.rs`, `gfx1250_named_consumer_tests.rs`, `gfx1250_named_lifecycle_tests.rs`, `gfx1250_portable_graph_tests.rs`, `gfx1250_signal_count_tests.rs`, `gfx1250_protocol_lifetime_tests.rs` |
| WMMA F32 16×16×4 and F16/BF16 16×16×32 | Full wave32, exact input/output tuples and selected format | Independent dense/basis/raw oracles; fragment copies, seeds, strides and complete logical/padded projections | Matrix input/output readiness and storage lifetime; LDS publication remains a separate obligation | `gfx1250_matrix_layout_parity.rs`, `gfx1250_matrix_numeric_parity.rs`, `gfx1250_matrix_publication.rs`, `gfx1250_upstream_adapters.rs` |
| Plain bounded 2D TDM in both directions | Actual compiler D0–D3 signature and selected descriptor fields; no advanced descriptor padding/multicast/gather/iteration/atomic-barrier modes | Concrete descriptor-derived addresses and full byte payloads; edge zero fill is explicit ordinary native code | Descriptor operands captured at issue; Tensor completion, source/destination memory leases and cross-wave publication tracked | `gfx1250_tensor_parity_tests.rs`, `gfx1250_tensor_capture_tests.rs`, `gfx1250_async_memory_tests.rs` |
| Original32 compiled loops and full output storage | Strict manifest validates exact unchanged source/spec/config and explicit native mappings | All 395,394 original coordinates, plus every native-superset coordinate, required; no sampling or shortened dimensions | Complete original iterations and graph events; unsupported/unknown/resource failures cannot satisfy a positive check | `gfx1250_original_matrix_tests.rs`, CLI/Python original-workload tests, `../full/cpu/prove_cli.py`, `../full/cpu/prove_python.py` |

The [signal-time count source contract](../portable-graph/signal-counts/references.json)
binds the exact same-lifetime count2-to1 positive and complete `[7,7]` payload,
both native count3/two-arrival deadlock orders, zero/NULL and all127-arrival
controls. Its separate exact mixed2/1 boundary is explicitly inconclusive under
the pinned public rules; a different deadlock is never reported as that boundary's
typed failure. The [13-row mechanism lifetime contract](../fixtures/mechanism-lifetime-contract.json)
retains the original zero-matrix projections and complete native supersets,
source/destination reuse, both earlier-store publication directions, and static
count/INIT boundaries with their actual source and typed negative controls.

The implementation stage boundaries are
[`frontend`](../../../crates/volta_amdgpu_analysis/src/frontend),
[`lower`](../../../crates/volta_amdgpu_analysis/src/lower),
[`eval`](../../../crates/volta_amdgpu_analysis/src/eval) and
[`amdgpu` graph checks](../../../crates/volta_graph_check/src/amdgpu.rs).
The reference mappings identify exact NVIDIA-only grammar, descriptor
encodings, TMEM resources and cluster scheduler differences. Those differences
do not exclude portable arithmetic, byte layout, memory lifetime or publication.

Physical floating rounding, exceptional values and whole-device/inter-workgroup
race freedom remain outside the mathematical-real selected-workgroup model.
