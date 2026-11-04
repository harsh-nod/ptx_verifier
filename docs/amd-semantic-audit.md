# Selected AMD instruction contracts

This is a bounded semantic review of the native gfx942, gfx950 and gfx1250
profiles. It checks address formation, encoded operands, EXEC participation,
defined bits and flags, and the separation between execution and graph safety.
It is not an audit of every accepted opcode or complete ISA coverage.

The production path is [frontend validation](../crates/volta_amdgpu_analysis/src/frontend/instr.rs),
[typed lowering](../crates/volta_amdgpu_analysis/src/lower/mod.rs),
[execution](../crates/volta_amdgpu_analysis/src/eval/interp.rs), and the independent
[AMD graph checks](../crates/volta_graph_check/src/amdgpu.rs).
Text and caller-built frontend ASTs share operand validation before executable
instructions are constructed. Execution computes candidate values eagerly;
memory readiness and publication still require graph certificates.

## Public sources

- **C3:** [CDNA3 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
  scalar operands/flags, scalar memory §8.2 and flat/global memory §10.2.
- **C4:** [CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
  scalar operands/flags §5.2–5.4, SMEM §8.2.1.1, memory completion §4.4,
  flat/global memory §10.2, SOPK §12.2 and barriers §12.5.
- **C5:** [CDNA5 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf),
  July 27, 2026 revision: EXEC §3.2.2, initial wave state §3.5.3.1,
  scalar operands/flags §6.2–6.3, SMEM §8.1.1, flat/global addressing §10.2,
  and SOPK §15.2.
- **L:** LLVM commit `5fd50ec8e07abb94e203933017e8d6e40fb51824`:
  [SOPK operand classes and encodings](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SOPInstructions.td),
  [`isS16Imm` / `isU16Imm` operand predicates](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/AsmParser/AMDGPUAsmParser.cpp),
  [`hasSCmpK` target restriction](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/GCNSubtarget.h),
  [`isLegalSMRDEncoded*Offset` and `supportsScaleOffset`](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/Utils/AMDGPUBaseInfo.cpp).
- **S:** The same LLVM commit's
  [execution synchronization contract](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUExecutionSynchronization.md)
  and [gfx125x memory model](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUUsage.md#memory-model-gfx125x).

## Memory address and completion matrix

The rows describe selected ordinary forms. Tensor descriptors, matrix layouts,
buffer addressing and atomics are outside this review. Complete transfer bounds
are checked before individual register-sized effects are recorded.

| Target and forms | Operand, width and address contract | Definedness and completion | Sources and independent controls |
| --- | --- | --- | --- |
| gfx942/gfx950 `s_load_dword{,x2,x4,x8,x16}` | Even SGPR base pair; one 32-bit SGPR offset or nonnegative immediate through `0xfffff`. Each byte component clears its low two bits before addition. Address/footprint overflow is refused; wider loads need DWORD alignment, not alignment to the complete transfer width. | Scalar issue is independent of EXEC. Unknown address words stop execution. Kernarg padding retains defined-bit information. LGKM completion is checked separately. | C3/C4 SMEM, L. [Memory controls](../crates/volta_pipeline/tests/gfx950_memory_control_tests.rs): `smem_discards_each_component_low_bits_before_addition`, `smem_masking_preserves_readiness_bounds_and_exec_independence`, `native_dwordx4_at_a_four_byte_offset_has_exact_full_transfer_bounds`. |
| gfx1250 `s_load_u8`, `s_load_u16`, `s_load_b32/b64/b96/b128/b256/b512` | Immediate through `0x7fffff`, or a 32-bit numbered SGPR. U8 preserves byte bits, U16 clears one bit, larger forms clear two, including SBASE. `scale_offset` multiplies the SGPR index by the complete payload size before masking; the instruction offset stays byte-valued. | Checked arithmetic retains products above 32 bits. KM data completion and X source retention remain separate. Unselected ABI padding does not become initialized. | C5 §8.1.1, L/S. [Byte tests](../crates/volta_pipeline/tests/gfx1250_byte_definedness_tests.rs): `scalar_address_masks_follow_payload_width_and_scale_the_register_index_first`, `scalar_scaling_uses_the_complete_payload_and_retains_products_above_32_bits`. |
| gfx942/gfx950 ordinary GLOBAL loads/stores | A 64-bit VGPR address with `off`, or a scalar base pair plus an unsigned 32-bit VGPR displacement. Signed 13-bit instruction displacement; native address addition wraps at 64 bits, but a transfer cannot wrap or span two configured objects. | Active EXEC lanes issue. Every observed source/address word must be defined. VM readiness and wide-store source reuse have independent checks. | C3/C4 memory and operand contracts. [Offset tests](../crates/volta_amdgpu_analysis/tests/signed_memory_offsets.rs): `cdna_scalar_base_indices_remain_unsigned`, `vector_pair_addresses_keep_all_sixty_four_bits`. [Memory controls](../crates/volta_pipeline/tests/gfx950_memory_control_tests.rs): `global_and_flat_vectors_cannot_straddle_explicit_adjacent_array_objects`. |
| gfx1250 ordinary GLOBAL loads/stores | GV retains the full VGPR-pair address. GVS sign-extends its 32-bit VGPR displacement before optional payload scaling and 64-bit wrapping addition; the instruction displacement is signed 24-bit. `off` plus `scale_offset` is refused because the selected assembler exposes scaling only for GVS. Ordinary B32 has a byte-addressed profile; other selected forms retain their alignment checks. | Active-lane effects retain absolute addresses. Load/Store completion and X source leases are distinct; equal stored values do not remove conflicts. | C5 §10.2, L/S. [Offset tests](../crates/volta_amdgpu_analysis/tests/signed_memory_offsets.rs): `gfx1250_global_and_flat_sign_extend_before_scaling_and_add_at_full_width`, `the_old_zero_extended_alias_cannot_hide_an_out_of_bounds_access`. [Encoding refusal](../crates/volta_amdgpu_analysis/tests/semantic_audit.rs): `gfx1250_scale_offset_requires_global_scalar_base_mode`. |
| Selected CDNA/gfx1250 FLAT loads/stores | CDNA uses a VGPR pair and nonnegative 12-bit instruction offset. gfx1250 adds selected scalar-base/signed-index and signed 24-bit displacement forms. An opaque shared-aperture high word is resolved without inventing a process address. | Complete footprints must fit one declared object or ABI region. FLAT counter obligations remain distinct from ordinary GLOBAL and LDS instructions. | C3/C4/C5 addressing, S. [Address tests](../crates/volta_amdgpu_analysis/src/eval/interp_address_tests.rs), [signed FLAT tests](../crates/volta_amdgpu_analysis/tests/signed_memory_offsets.rs): `a_signed_flat_index_can_move_back_inside_the_opaque_shared_aperture`. |
| Selected ordinary LDS and two-address DS loads/stores | Byte/half/DWORD widths and paired register roles follow the selected form. Address offsets use native 32-bit LDS arithmetic. A configured LDS subobject must contain the entire transfer; equal paired offsets remain unsupported. | Active-lane effects, retained source identities and completion are recorded independently. Cross-wave publication requires a matching workgroup synchronization certificate. | C3/C4/C5 LDS, S. [Memory controls](../crates/volta_pipeline/tests/gfx950_memory_control_tests.rs): `configured_lds_objects_bound_whole_vector_and_dual_offset_transfers`, `crosswave_lds_exchange_requires_waits_and_a_workgroup_barrier`. |

M0 is a recognized SMEM offset encoding, but its initial runtime value is not
supplied by the modeled ABI. CDNA M0 use remains unsupported; gfx1250 explicit
M0 values have their existing narrow profiles. Signed SMEM immediate extensions,
scratch and general buffer addressing are not introduced by these checks.

## Scalar control, defined bits and synchronization matrix

| Target and forms | Operand and state contract | Completion/definedness boundary | Sources and independent controls |
| --- | --- | --- | --- |
| All targets `s_movk_i32`, `s_mulk_i32`, CDNA `s_addk_i32`, gfx1250 `s_addk_co_i32` | A dedicated 16-bit integer immediate, accepting `-32768..65535` spellings; no register or floating operand. The encoded word is sign-extended. MOVK/MULK preserve SCC; ADDK replaces it with signed overflow. | The read-modify-write destination must be initialized. Scalar execution is independent of EXEC. Direct AST calls receive the same encoding checks as text. | C3/C4/C5 SOPK, L. [Scalar audit tests](../crates/volta_amdgpu_analysis/tests/semantic_audit.rs): `sopk_requires_an_encoded_immediate_in_text_and_direct_ast`, `movk_sign_extends_its_word_and_preserves_both_old_scc_values`, `addk_replaces_scc_with_signed_overflow_and_mulk_preserves_it`. |
| gfx942/gfx950 selected `s_cmpk_*_i32/u32` | Signed forms sign-extend their 16-bit field; unsigned forms zero-extend and accept only `0..65535`. Comparisons replace SCC. These encodings are absent on gfx1250 and are refused there. | A later CSELECT/branch cannot reuse an old SCC value instead of the comparison. | C3/C4 SOPK, L `hasSCmpK`. [Scalar audit tests](../crates/volta_amdgpu_analysis/tests/semantic_audit.rs): `cmpk_signed_and_unsigned_fields_have_distinct_extension_rules`, `gfx1250_cannot_inherit_cdna_sopk_compare_encodings`. |
| Selected scalar carry/borrow, BFE/shift/bitwise and CSELECT | Carry consumers require defined SCC. gfx1250 partial-bit BFE/shifts retain exact known-zero bits; partial ADD/SUB conservatively invalidate result/SCC knowledge. MUL's concrete-zero result preserves old SCC. A concrete CSELECT observes only the selected value. | Unknown data cannot become a concrete address, branch decision or output. Selection may discard unknown padding or unclustered TTMP fallback data only when the selected bits/value are known. | C3/C4/C5 operands/flags, C5 initial state. [Runtime ABI tests](../crates/volta_amdgpu_analysis/tests/runtime_abi.rs): `genuine_scalar_add_and_sub_replace_scc_with_their_carry_result`. [Selected-group tests](../crates/volta_amdgpu_analysis/tests/selected_workgroup.rs): `undefined_cluster_fallback_values_can_be_discarded_but_not_observed`. |
| Selected waits, workgroup barriers and END | Wait fields preserve omitted counters and native widths. A wait establishes only its counter obligations; an unrelated counter or ALU delay does not publish memory. CDNA END drains its modeled counters; gfx1250 retains explicit completion and barrier-lifetime obligations. | Barrier membership/phase and memory completion are separate. Empty EXEC does not skip scalar barrier participation. Execution-only or matrix completion cannot publish unrelated LDS stores. | C3/C4 counters/barriers, C5/S. [Memory controls](../crates/volta_pipeline/tests/gfx950_memory_control_tests.rs): `a_wait_on_the_wrong_counter_does_not_make_a_register_ready`, `scalar_barrier_participation_is_independent_of_empty_exec`, `matrix_completion_does_not_publish_an_unrelated_earlier_lds_metadata_store`. [END controls](../crates/volta_pipeline/tests/gfx1250_unnamed_end_tests.rs). |
| gfx1250 named signal/count boundary | Selected M0 count bits, zero/no-change and NULL forms retain separate meanings. Count changes require ordering certificates; the public equal-to-arrived ambiguity remains inconclusive. | Neither eager scheduling nor a numerical marker substitutes for a phase/lifetime certificate. | S. [Signal controls](../crates/volta_pipeline/tests/gfx1250_signal_count_tests.rs): `equal_to_arrived_boundary_remains_explicitly_inconclusive`, `reserved_m0_signal_bits_do_not_become_a_wider_expected_count`. |

## Regression scope and remaining limits

The scalar audit tests use independently expected sign/zero extension and
overflow results. They preserve both prior SCC values for MOVK/MULK, seed the
opposite SCC before ADDK, and check text plus forged frontend ASTs. The GLOBAL
modifier controls retain unscaled GV and valid GVS profiles while refusing the
invalid combination. No assembly, LLVM IR, HIP or specification fixture bytes
are changed for these guards.

The memory and synchronization controls pair complete values/footprints with
missing waits, wrong counters, out-of-bounds accesses or missing publication.
They establish the rows' stated profiles, not arbitrary modifier combinations,
every possible schedule or every target instruction. Matrix arithmetic, TDM
descriptor semantics, special-register hazards and IEEE floating-point behavior
are not newly audited here. Analysis still covers one selected workgroup;
inter-workgroup races remain outside the result.


## Compiler-driven narrow integer forms

The unchanged [compiler corpus](../tests/amdgpu/compiler-corpus/README.md)
contains CDNA `v_lshlrev_b16_e32` and `v_cmp_ne_u16_e32`, plus gfx950
`v_bitop3_b16`, in an unselected softmax entry. Whole-module validation checks
these instructions before any selected entry executes. The bounded extension
retains that validation; it neither extracts entries nor changes fixture bytes.

The public C4 §12.7/§12.11 shift equations use `S0[3:0]` and `S1.u16`;
§12.11 BITOP3 uses truth-table index `{S0[i],S1[i],S2[i]}`; §12.9/§12.11 U16
comparisons observe only the low16 bits. Target encodings are pinned by LLVM
`7b800a19466229b8479a78de19143dc33c3ab9b5`:
[VOP2](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/VOP2Instructions.td),
[VOP3](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/VOP3Instructions.td),
and [VOPC](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/VOPCInstructions.td).

| Selected form | Target and value contract | Conservative boundary and controls |
| --- | --- | --- |
| `v_lshlrev_b16` | gfx942/gfx950 VOP2/VOP3; low16 data, low4 count, low16 result. Active EXEC lanes only. | New CDNA results retain unknown upper16 bits. Low16 masks/comparisons can consume them; a fullword output or address cannot invent the upper bits. Register halves are not preserved implicitly. `legacy_shift_observes_low16_data_and_low4_count` checks counts 0/1/15/16/17/allones and differing high data. |
| `v_bitop3_b16` | gfx950 VOP3; three low16 sources and one explicit 8-bit truth table. gfx942 and `_e32` are refused. | New CDNA results retain unknown upper16. OPSEL, source modifiers and normal output modifiers are outside this profile. `bitop3_truth_table_uses_s0_s1_s2_bit_order` independently checks all 256 tables over all eight input triples. |
| `v_cmp_ne_u16` | gfx942/gfx950 VOPC/VOP3 and the existing gfx1250 profile; both concrete and symbolic source words are masked to 16 bits before comparison. | An undefined observed lowbit refuses. Symbolic predicates can select data but cannot become concrete EXEC/control. `symbolic_u16_comparison_cannot_observe_high_input_bits` substitutes independently chosen 32-bit words, including nonzero high16 with zero low16. This masking also corrects the preexisting gfx1250 symbolic path. |
| `v_cmp_u_f32` | Shared gfx942/gfx950 register-source spelling, using the existing mathematical-real comparison path. | Decoded NaNs still refuse; this is no IEEE exception or NaN-semantics extension. gfx1250 encoding checks remain separate. `shared_unordered_float_comparison_retains_the_finite_real_boundary` checks finite values and NaN refusal. |

The tests in [cdna_integer16.rs](../crates/volta_amdgpu_analysis/tests/cdna_integer16.rs)
also cover inactive-lane destination preservation, empty EXEC, undefined
observations, invalid encodings and direct-AST lowering. CDNA `_e32` retains its
VGPR SRC1 and fixed VCC comparison destination; VOP3 literals and multiple
scalar sources are refused. The existing gfx1250 VOP3-only shift/BITOP3 encoding
rules are unchanged. LLVM describes zero high bits for legacy GFX9 integer16
results, but the selected public ISA assignments only specify the narrow result;
this implementation conservatively does not add that highhalf guarantee.
