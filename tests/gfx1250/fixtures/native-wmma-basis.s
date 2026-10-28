	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	wmma_f32_basis          ; -- Begin function wmma_f32_basis
	.globl	wmma_f32_basis
	.p2align	8
	.type	wmma_f32_basis,@function
wmma_f32_basis:                         ; @wmma_f32_basis
; %bb.0:
	s_load_b96 s[4:6], s[0:1], 0x8
	v_dual_lshrrev_b32 v1, 3, v0 :: v_dual_bitop2_b32 v2, 15, v0 bitop3:0x40
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_lshlrev_b32 v0, 5, v0 :: v_dual_bitop2_b32 v3, 2, v1 bitop3:0x40
	v_or_b32_e32 v1, 1, v1
	s_wait_kmcnt 0x0
	v_cmp_eq_u32_e32 vcc_lo, s4, v2
	s_cmp_lg_u32 s6, 0
	v_cmp_eq_u32_e64 s2, s5, v3
	s_cselect_b32 s3, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 s4, vcc_lo, s3
	s_cmp_eq_u32 s6, 0
	v_cmp_eq_u32_e64 s3, s5, v1
	s_cselect_b32 s5, -1, 0
	s_and_b32 s6, s4, s2
	s_or_b32 s5, vcc_lo, s5
	v_cndmask_b32_e64 v10, 0, 1.0, s6
	s_and_b32 s2, s5, s2
	s_and_b32 s4, s4, s3
	v_cndmask_b32_e64 v12, 0, 1.0, s2
	s_and_b32 s2, s5, s3
	v_cndmask_b32_e64 v11, 0, 1.0, s4
	v_cndmask_b32_e64 v13, 0, 1.0, s2
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x4_f32 v[2:9], v[10:11], v[12:13], 0
	s_clause 0x1
	global_store_b128 v0, v[6:9], s[0:1] offset:16
	global_store_b128 v0, v[2:5], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel wmma_f32_basis
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 20
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 7
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 2
		.amdhsa_round_robin_scheduling 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size	wmma_f32_basis, .Lfunc_end0-wmma_f32_basis
                                        ; -- End function
	.set wmma_f32_basis.num_vgpr, 14
	.set wmma_f32_basis.num_agpr, 0
	.set wmma_f32_basis.numbered_sgpr, 7
	.set wmma_f32_basis.num_named_barrier, 0
	.set wmma_f32_basis.private_seg_size, 0
	.set wmma_f32_basis.uses_vcc, 1
	.set wmma_f32_basis.uses_flat_scratch, 0
	.set wmma_f32_basis.has_dyn_sized_stack, 0
	.set wmma_f32_basis.has_recursion, 0
	.set wmma_f32_basis.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 196
; TotalNumSgprs: 9
; NumVgprs: 14
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 14
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	wmma_f16_basis          ; -- Begin function wmma_f16_basis
	.globl	wmma_f16_basis
	.p2align	8
	.type	wmma_f16_basis,@function
wmma_f16_basis:                         ; @wmma_f16_basis
; %bb.0:
	s_clause 0x1
	s_load_b96 s[4:6], s[0:1], 0x8
	s_load_b64 s[8:9], s[0:1], 0x0
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_bitop2_b32 v3, 15, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v0, 5, v0 :: v_dual_bitop2_b32 v2, 8, v1 bitop3:0x40
	v_or_b32_e32 v1, 7, v1
	v_or_b32_e32 v4, 1, v2
	v_or_b32_e32 v5, 2, v2
	v_or_b32_e32 v6, 3, v2
	v_or_b32_e32 v7, 4, v2
	v_or_b32_e32 v8, 22, v2
	s_wait_kmcnt 0x0
	v_cmp_eq_u32_e32 vcc_lo, s4, v3
	s_cmp_lg_u32 s6, 0
	v_cmp_eq_u32_e64 s0, s5, v2
	s_cselect_b32 s3, -1, 0
	v_cmp_eq_u32_e64 s1, s5, v4
	s_or_b32 s4, vcc_lo, s3
	s_cmp_eq_u32 s6, 0
	v_cmp_eq_u32_e64 s2, s5, v5
	s_cselect_b32 s6, -1, 0
	s_and_b32 s7, s4, s0
	s_or_b32 s6, vcc_lo, s6
	v_cmp_eq_u32_e64 s3, s5, v6
	s_and_b32 s0, s6, s0
	v_cmp_eq_u32_e32 vcc_lo, s5, v7
	v_cndmask_b32_e64 v18, 0, 0x3c00, s0
	s_and_b32 s0, s6, s1
	v_or_b32_e32 v4, 5, v2
	v_cndmask_b32_e64 v19, 0, 0x3c00, s0
	s_and_b32 s0, s6, s2
	v_or_b32_e32 v5, 6, v2
	v_cndmask_b32_e64 v20, 0, 0x3c00, s0
	s_and_b32 s0, s4, s3
	v_cndmask_b32_e64 v10, 0, 0x3c00, s7
	v_cndmask_b32_e64 v12, 0, 0x3c00, s0
	s_and_b32 s0, s6, s3
	s_and_b32 s7, s4, s1
	v_cndmask_b32_e64 v21, 0, 0x3c00, s0
	s_and_b32 s0, s4, vcc_lo
	s_and_b32 s1, s6, vcc_lo
	v_cndmask_b32_e64 v13, 0, 0x3c00, s0
	v_cmp_eq_u32_e64 s0, s5, v4
	v_cmp_eq_u32_e32 vcc_lo, s5, v5
	v_or_b32_e32 v5, 16, v2
	v_cndmask_b32_e64 v22, 0, 0x3c00, s1
	v_or_b32_e32 v6, 18, v2
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v4, 0, 0x3c00, s1
	v_cndmask_b32_e64 v23, 0, 0x3c00, s0
	v_cmp_eq_u32_e64 s0, s5, v1
	s_and_b32 s1, s4, vcc_lo
	v_or_b32_e32 v7, 20, v2
	v_cndmask_b32_e64 v1, 0, 0x3c00, s1
	s_and_b32 s1, s6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, s5, v5
	v_or_b32_e32 v5, 17, v2
	v_cndmask_b32_e64 v24, 0, 0x3c00, s1
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v14, 0, 0x3c00, s1
	v_cndmask_b32_e64 v25, 0, 0x3c00, s0
	s_and_b32 s0, s4, vcc_lo
	s_and_b32 s1, s6, vcc_lo
	v_cndmask_b32_e64 v15, 0, 0x3c00, s0
	v_cmp_eq_u32_e64 s0, s5, v5
	v_cmp_eq_u32_e32 vcc_lo, s5, v6
	v_or_b32_e32 v5, 19, v2
	v_cndmask_b32_e64 v26, 0, 0x3c00, s1
	v_cndmask_b32_e64 v11, 0, 0x3c00, s7
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v6, 0, 0x3c00, s1
	v_cndmask_b32_e64 v27, 0, 0x3c00, s0
	v_cmp_eq_u32_e64 s0, s5, v5
	s_and_b32 s1, s4, vcc_lo
	s_and_b32 s7, s4, s2
	v_cndmask_b32_e64 v5, 0, 0x3c00, s1
	s_and_b32 s1, s6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, s5, v7
	v_or_b32_e32 v7, 21, v2
	v_cndmask_b32_e64 v28, 0, 0x3c00, s1
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_or_b32_e32 v2, 23, v2
	v_cndmask_b32_e64 v29, 0, 0x3c00, s0
	s_and_b32 s0, s4, vcc_lo
	v_cndmask_b32_e64 v16, 0, 0x3c00, s1
	v_cndmask_b32_e64 v17, 0, 0x3c00, s0
	v_cmp_eq_u32_e64 s0, s5, v7
	v_cmp_eq_u32_e64 s1, s5, v8
	s_and_b32 s2, s6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, s5, v2
	v_cndmask_b32_e64 v30, 0, 0x3c00, s2
	s_and_b32 s2, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v2, 0, 0x3c00, s2
	s_and_b32 s2, s4, s1
	v_cndmask_b32_e64 v31, 0, 0x3c00, s0
	s_and_b32 s0, s6, s1
	v_cndmask_b32_e64 v7, 0, 0x3c00, s2
	s_and_b32 s2, s4, vcc_lo
	v_cndmask_b32_e64 v32, 0, 0x3c00, s0
	s_and_b32 s0, s6, vcc_lo
	v_cndmask_b32_e64 v3, 0, 0x3c00, s7
	v_cndmask_b32_e64 v8, 0, 0x3c00, s2
	v_pack_b32_f16 v6, v15, v6
	v_cndmask_b32_e64 v15, 0, 0x3c00, s0
	v_pack_b32_f16 v4, v13, v4
	v_pack_b32_f16 v3, v3, v12
	v_pack_b32_f16 v9, v7, v8
	v_pack_b32_f16 v8, v17, v2
	v_pack_b32_f16 v7, v5, v16
	v_pack_b32_f16 v5, v1, v14
	v_pack_b32_f16 v2, v10, v11
	v_pack_b32_f16 v17, v32, v15
	v_pack_b32_f16 v16, v30, v31
	v_pack_b32_f16 v15, v28, v29
	v_pack_b32_f16 v14, v26, v27
	v_pack_b32_f16 v13, v24, v25
	v_pack_b32_f16 v12, v22, v23
	v_pack_b32_f16 v11, v20, v21
	v_pack_b32_f16 v10, v18, v19
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	s_clause 0x1
	global_store_b128 v0, v[22:25], s[8:9] offset:16
	global_store_b128 v0, v[18:21], s[8:9]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel wmma_f16_basis
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 20
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_next_free_sgpr 10
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 8
		.amdhsa_round_robin_scheduling 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end1:
	.size	wmma_f16_basis, .Lfunc_end1-wmma_f16_basis
                                        ; -- End function
	.set wmma_f16_basis.num_vgpr, 33
	.set wmma_f16_basis.num_agpr, 0
	.set wmma_f16_basis.numbered_sgpr, 10
	.set wmma_f16_basis.num_named_barrier, 0
	.set wmma_f16_basis.private_seg_size, 0
	.set wmma_f16_basis.uses_vcc, 1
	.set wmma_f16_basis.uses_flat_scratch, 0
	.set wmma_f16_basis.has_dyn_sized_stack, 0
	.set wmma_f16_basis.has_recursion, 0
	.set wmma_f16_basis.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 928
; TotalNumSgprs: 12
; NumVgprs: 33
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 33
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	wmma_bf16_basis         ; -- Begin function wmma_bf16_basis
	.globl	wmma_bf16_basis
	.p2align	8
	.type	wmma_bf16_basis,@function
wmma_bf16_basis:                        ; @wmma_bf16_basis
; %bb.0:
	s_clause 0x1
	s_load_b96 s[4:6], s[0:1], 0x8
	s_load_b64 s[8:9], s[0:1], 0x0
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_bitop2_b32 v3, 15, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v0, 5, v0 :: v_dual_bitop2_b32 v2, 8, v1 bitop3:0x40
	v_or_b32_e32 v1, 7, v1
	v_or_b32_e32 v4, 1, v2
	v_or_b32_e32 v5, 2, v2
	v_or_b32_e32 v6, 3, v2
	v_or_b32_e32 v7, 4, v2
	v_or_b32_e32 v8, 22, v2
	s_wait_kmcnt 0x0
	v_cmp_eq_u32_e32 vcc_lo, s4, v3
	s_cmp_lg_u32 s6, 0
	v_cmp_eq_u32_e64 s0, s5, v2
	s_cselect_b32 s3, -1, 0
	v_cmp_eq_u32_e64 s1, s5, v4
	s_or_b32 s4, vcc_lo, s3
	s_cmp_eq_u32 s6, 0
	v_cmp_eq_u32_e64 s2, s5, v5
	s_cselect_b32 s6, -1, 0
	s_and_b32 s7, s4, s0
	s_or_b32 s6, vcc_lo, s6
	v_cmp_eq_u32_e64 s3, s5, v6
	s_and_b32 s0, s6, s0
	v_cmp_eq_u32_e32 vcc_lo, s5, v7
	v_cndmask_b32_e64 v18, 0, 0x3f80, s0
	s_and_b32 s0, s6, s1
	v_or_b32_e32 v4, 5, v2
	v_cndmask_b32_e64 v19, 0, 0x3f80, s0
	s_and_b32 s0, s6, s2
	v_or_b32_e32 v5, 6, v2
	v_cndmask_b32_e64 v20, 0, 0x3f80, s0
	s_and_b32 s0, s4, s3
	v_cndmask_b32_e64 v10, 0, 0x3f80, s7
	v_cndmask_b32_e64 v12, 0, 0x3f80, s0
	s_and_b32 s0, s6, s3
	s_and_b32 s7, s4, s1
	v_cndmask_b32_e64 v21, 0, 0x3f80, s0
	s_and_b32 s0, s4, vcc_lo
	s_and_b32 s1, s6, vcc_lo
	v_cndmask_b32_e64 v13, 0, 0x3f80, s0
	v_cmp_eq_u32_e64 s0, s5, v4
	v_cmp_eq_u32_e32 vcc_lo, s5, v5
	v_or_b32_e32 v5, 16, v2
	v_cndmask_b32_e64 v22, 0, 0x3f80, s1
	v_or_b32_e32 v6, 18, v2
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v4, 0, 0x3f80, s1
	v_cndmask_b32_e64 v23, 0, 0x3f80, s0
	v_cmp_eq_u32_e64 s0, s5, v1
	s_and_b32 s1, s4, vcc_lo
	v_or_b32_e32 v7, 20, v2
	v_cndmask_b32_e64 v1, 0, 0x3f80, s1
	s_and_b32 s1, s6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, s5, v5
	v_or_b32_e32 v5, 17, v2
	v_cndmask_b32_e64 v24, 0, 0x3f80, s1
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v14, 0, 0x3f80, s1
	v_cndmask_b32_e64 v25, 0, 0x3f80, s0
	s_and_b32 s0, s4, vcc_lo
	s_and_b32 s1, s6, vcc_lo
	v_cndmask_b32_e64 v15, 0, 0x3f80, s0
	v_cmp_eq_u32_e64 s0, s5, v5
	v_cmp_eq_u32_e32 vcc_lo, s5, v6
	v_or_b32_e32 v5, 19, v2
	v_cndmask_b32_e64 v26, 0, 0x3f80, s1
	v_cndmask_b32_e64 v11, 0, 0x3f80, s7
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v6, 0, 0x3f80, s1
	v_cndmask_b32_e64 v27, 0, 0x3f80, s0
	v_cmp_eq_u32_e64 s0, s5, v5
	s_and_b32 s1, s4, vcc_lo
	s_and_b32 s7, s4, s2
	v_cndmask_b32_e64 v5, 0, 0x3f80, s1
	s_and_b32 s1, s6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, s5, v7
	v_or_b32_e32 v7, 21, v2
	v_cndmask_b32_e64 v28, 0, 0x3f80, s1
	s_and_b32 s1, s4, s0
	s_and_b32 s0, s6, s0
	v_or_b32_e32 v2, 23, v2
	v_cndmask_b32_e64 v29, 0, 0x3f80, s0
	s_and_b32 s0, s4, vcc_lo
	v_cndmask_b32_e64 v16, 0, 0x3f80, s1
	v_cndmask_b32_e64 v17, 0, 0x3f80, s0
	v_cmp_eq_u32_e64 s0, s5, v7
	v_cmp_eq_u32_e64 s1, s5, v8
	s_and_b32 s2, s6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, s5, v2
	v_cndmask_b32_e64 v30, 0, 0x3f80, s2
	s_and_b32 s2, s4, s0
	s_and_b32 s0, s6, s0
	v_cndmask_b32_e64 v2, 0, 0x3f80, s2
	s_and_b32 s2, s4, s1
	v_cndmask_b32_e64 v31, 0, 0x3f80, s0
	s_and_b32 s0, s6, s1
	v_cndmask_b32_e64 v7, 0, 0x3f80, s2
	s_and_b32 s2, s4, vcc_lo
	v_cndmask_b32_e64 v32, 0, 0x3f80, s0
	s_and_b32 s0, s6, vcc_lo
	v_cndmask_b32_e64 v3, 0, 0x3f80, s7
	v_cndmask_b32_e64 v8, 0, 0x3f80, s2
	v_perm_b32 v6, v6, v15, 0x5040100
	v_cndmask_b32_e64 v15, 0, 0x3f80, s0
	v_perm_b32 v4, v4, v13, 0x5040100
	v_perm_b32 v3, v12, v3, 0x5040100
	v_perm_b32 v9, v8, v7, 0x5040100
	v_perm_b32 v8, v2, v17, 0x5040100
	v_perm_b32 v7, v16, v5, 0x5040100
	v_perm_b32 v5, v14, v1, 0x5040100
	v_perm_b32 v2, v11, v10, 0x5040100
	v_perm_b32 v17, v15, v32, 0x5040100
	v_perm_b32 v16, v31, v30, 0x5040100
	v_perm_b32 v15, v29, v28, 0x5040100
	v_perm_b32 v14, v27, v26, 0x5040100
	v_perm_b32 v13, v25, v24, 0x5040100
	v_perm_b32 v12, v23, v22, 0x5040100
	v_perm_b32 v11, v21, v20, 0x5040100
	v_perm_b32 v10, v19, v18, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_bf16 v[18:25], v[2:9], v[10:17], 0
	s_clause 0x1
	global_store_b128 v0, v[22:25], s[8:9] offset:16
	global_store_b128 v0, v[18:21], s[8:9]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel wmma_bf16_basis
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 20
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_next_free_sgpr 10
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 8
		.amdhsa_round_robin_scheduling 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end2:
	.size	wmma_bf16_basis, .Lfunc_end2-wmma_bf16_basis
                                        ; -- End function
	.set wmma_bf16_basis.num_vgpr, 33
	.set wmma_bf16_basis.num_agpr, 0
	.set wmma_bf16_basis.numbered_sgpr, 10
	.set wmma_bf16_basis.num_named_barrier, 0
	.set wmma_bf16_basis.private_seg_size, 0
	.set wmma_bf16_basis.uses_vcc, 1
	.set wmma_bf16_basis.uses_flat_scratch, 0
	.set wmma_bf16_basis.has_dyn_sized_stack, 0
	.set wmma_bf16_basis.has_recursion, 0
	.set wmma_bf16_basis.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 992
; TotalNumSgprs: 12
; NumVgprs: 33
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 33
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_52d0de6a6b8a6d2e,@object ; @__hip_cuid_52d0de6a6b8a6d2e
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_52d0de6a6b8a6d2e
__hip_cuid_52d0de6a6b8a6d2e:
	.byte	0                               ; 0x0
	.size	__hip_cuid_52d0de6a6b8a6d2e, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_52d0de6a6b8a6d2e
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         12
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           wmma_f32_basis
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         wmma_f32_basis.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         12
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           wmma_f16_basis
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         wmma_f16_basis.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     33
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         12
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           wmma_bf16_basis
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         wmma_bf16_basis.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     33
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
