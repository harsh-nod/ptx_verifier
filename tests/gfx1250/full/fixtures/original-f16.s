	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	relu_f16                ; -- Begin function relu_f16
	.globl	relu_f16
	.p2align	8
	.type	relu_f16,@function
relu_f16:                               ; @relu_f16
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_bfe_u32 s4, ttmp6, 0x4000c
	s_and_b32 s5, ttmp6, 15
	s_add_co_i32 s4, s4, 1
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s4, ttmp9, s4
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_add_co_i32 s5, s5, s4
	s_cmp_eq_u32 s6, 0
	s_cselect_b32 s4, ttmp9, s5
	v_lshl_add_u32 v4, s4, 7, v0
	s_wait_kmcnt 0x0
	global_load_b128 v[0:3], v4, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_cmp_lt_f16_e32 vcc_lo, 0, v0
	v_lshrrev_b32_e32 v5, 16, v0
	v_pk_max_num_f16 v1, v1, v1
	v_pk_max_num_f16 v2, v2, v2
	v_pk_max_num_f16 v3, v3, v3
	v_cndmask_b32_e32 v0, 0, v0, vcc_lo
	v_cmp_lt_f16_e32 vcc_lo, 0, v5
	v_pk_max_num_f16 v1, v1, 0
	v_pk_max_num_f16 v2, v2, 0
	v_pk_max_num_f16 v3, v3, 0
	v_cndmask_b32_e32 v5, 0, v5, vcc_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v0, v5, v0, 0x5040100
	global_store_b128 v4, v[0:3], s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel relu_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 6
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
	.size	relu_f16, .Lfunc_end0-relu_f16
                                        ; -- End function
	.set relu_f16.num_vgpr, 6
	.set relu_f16.num_agpr, 0
	.set relu_f16.numbered_sgpr, 7
	.set relu_f16.num_named_barrier, 0
	.set relu_f16.private_seg_size, 0
	.set relu_f16.uses_vcc, 1
	.set relu_f16.uses_flat_scratch, 0
	.set relu_f16.has_dyn_sized_stack, 0
	.set relu_f16.has_recursion, 0
	.set relu_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 176
; TotalNumSgprs: 9
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 6
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
	.protected	silu_f16                ; -- Begin function silu_f16
	.globl	silu_f16
	.p2align	8
	.type	silu_f16,@function
silu_f16:                               ; @silu_f16
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_bfe_u32 s4, ttmp6, 0x4000c
	s_and_b32 s5, ttmp6, 15
	s_add_co_i32 s4, s4, 1
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s4, ttmp9, s4
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_add_co_i32 s5, s5, s4
	s_cmp_eq_u32 s6, 0
	s_cselect_b32 s4, ttmp9, s5
	v_lshl_add_u32 v8, s4, 7, v0
	s_wait_kmcnt 0x0
	global_load_b64 v[0:1], v8, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_dual_lshrrev_b32 v3, 16, v0 :: v_dual_lshrrev_b32 v4, 16, v1
	v_cvt_f32_f16_e32 v0, v0
	v_cvt_f32_f16_e32 v2, v1
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f32_f16_e32 v1, v3
	v_cvt_f32_f16_e32 v3, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mul_f32 v4, 0xbfb8aa3b, v0 :: v_dual_mul_f32 v5, 0xbfb8aa3b, v2
	v_dual_mul_f32 v6, 0xbfb8aa3b, v1 :: v_dual_mul_f32 v7, 0xbfb8aa3b, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v5, v5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_dual_add_f32 v4, 1.0, v4 :: v_dual_add_f32 v5, 1.0, v5
	v_dual_add_f32 v9, 1.0, v6 :: v_dual_add_f32 v7, 1.0, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_rcp_f32_e32 v4, v4
	v_rcp_f32_e32 v6, v5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v5, v9
	v_rcp_f32_e32 v7, v7
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_pk_mul_f32 v[0:1], v[4:5], v[0:1]
	v_pk_mul_f32 v[2:3], v[6:7], v[2:3]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_pk_f16_f32 v0, v0, v1
	v_cvt_pk_f16_f32 v1, v2, v3
	global_store_b64 v8, v[0:1], s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel silu_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 10
		.amdhsa_next_free_sgpr 7
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 3
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
	.size	silu_f16, .Lfunc_end1-silu_f16
                                        ; -- End function
	.set silu_f16.num_vgpr, 10
	.set silu_f16.num_agpr, 0
	.set silu_f16.numbered_sgpr, 7
	.set silu_f16.num_named_barrier, 0
	.set silu_f16.private_seg_size, 0
	.set silu_f16.uses_vcc, 0
	.set silu_f16.uses_flat_scratch, 0
	.set silu_f16.has_dyn_sized_stack, 0
	.set silu_f16.has_recursion, 0
	.set silu_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 264
; TotalNumSgprs: 7
; NumVgprs: 10
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 7
; NumVGPRsForWavesPerEU: 10
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
	.protected	sigmoid_f16             ; -- Begin function sigmoid_f16
	.globl	sigmoid_f16
	.p2align	8
	.type	sigmoid_f16,@function
sigmoid_f16:                            ; @sigmoid_f16
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_bfe_u32 s4, ttmp6, 0x4000c
	s_and_b32 s5, ttmp6, 15
	s_add_co_i32 s4, s4, 1
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s4, ttmp9, s4
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_add_co_i32 s5, s5, s4
	s_cmp_eq_u32 s6, 0
	s_cselect_b32 s4, ttmp9, s5
	v_lshl_add_u32 v2, s4, 8, v0
	s_wait_kmcnt 0x0
	global_load_b64 v[0:1], v2, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_dual_lshrrev_b32 v3, 16, v1 :: v_dual_lshrrev_b32 v4, 16, v0
	v_cvt_f32_f16_e32 v0, v0
	v_cvt_f32_f16_e32 v1, v1
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f32_f16_e32 v3, v3
	v_cvt_f32_f16_e32 v4, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mul_f32 v0, 0xbfb8aa3b, v0 :: v_dual_mul_f32 v1, 0xbfb8aa3b, v1
	v_dual_mul_f32 v3, 0xbfb8aa3b, v3 :: v_dual_mul_f32 v4, 0xbfb8aa3b, v4
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v0, v0
	v_exp_f32_e32 v1, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v3, v3
	v_exp_f32_e32 v4, v4
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_dual_add_f32 v0, 1.0, v0 :: v_dual_add_f32 v1, 1.0, v1
	v_dual_add_f32 v3, 1.0, v3 :: v_dual_add_f32 v4, 1.0, v4
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_rcp_f32_e32 v0, v0
	v_rcp_f32_e32 v1, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v3, v3
	v_rcp_f32_e32 v4, v4
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_cvt_pk_f16_f32 v1, v1, v3
	v_cvt_pk_f16_f32 v0, v0, v4
	global_store_b64 v2, v[0:1], s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel sigmoid_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 5
		.amdhsa_next_free_sgpr 7
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
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
.Lfunc_end2:
	.size	sigmoid_f16, .Lfunc_end2-sigmoid_f16
                                        ; -- End function
	.set sigmoid_f16.num_vgpr, 5
	.set sigmoid_f16.num_agpr, 0
	.set sigmoid_f16.numbered_sgpr, 7
	.set sigmoid_f16.num_named_barrier, 0
	.set sigmoid_f16.private_seg_size, 0
	.set sigmoid_f16.uses_vcc, 0
	.set sigmoid_f16.uses_flat_scratch, 0
	.set sigmoid_f16.has_dyn_sized_stack, 0
	.set sigmoid_f16.has_recursion, 0
	.set sigmoid_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 240
; TotalNumSgprs: 7
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 7
; NumVGPRsForWavesPerEU: 5
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
	.protected	swiglu_f16              ; -- Begin function swiglu_f16
	.globl	swiglu_f16
	.p2align	8
	.type	swiglu_f16,@function
swiglu_f16:                             ; @swiglu_f16
; %bb.0:
	s_load_b128 s[4:7], s[0:1], 0x0
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	s_getreg_b32 s8, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s2, ttmp9, s2
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x10
	s_add_co_i32 s3, s3, s2
	s_cmp_eq_u32 s8, 0
	s_cselect_b32 s2, ttmp9, s3
	s_delay_alu instid0(SALU_CYCLE_1)
	v_lshl_add_u32 v24, s2, 7, v0
	s_wait_kmcnt 0x0
	s_clause 0x1
	global_load_b128 v[0:3], v24, s[4:5] scale_offset
	global_load_b128 v[4:7], v24, s[6:7] scale_offset
	s_wait_loadcnt 0x1
	v_dual_lshrrev_b32 v9, 16, v0 :: v_dual_lshrrev_b32 v13, 16, v1
	v_cvt_f32_f16_e32 v12, v2
	v_lshrrev_b32_e32 v16, 16, v2
	v_cvt_f32_f16_e32 v8, v0
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v4
	v_dual_lshrrev_b32 v11, 16, v4 :: v_dual_lshrrev_b32 v15, 16, v5
	v_cvt_f32_f16_e32 v4, v1
	v_cvt_f32_f16_e32 v2, v6
	v_dual_lshrrev_b32 v25, 16, v6 :: v_dual_lshrrev_b32 v26, 16, v7
	v_cvt_f32_f16_e32 v6, v3
	v_lshrrev_b32_e32 v3, 16, v3
	v_cvt_f32_f16_e32 v10, v5
	v_cvt_f32_f16_e32 v5, v13
	v_cvt_f32_f16_e32 v13, v16
	v_mul_f32_e32 v16, 0xbfb8aa3b, v12
	v_cvt_f32_f16_e32 v14, v7
	v_cvt_f32_f16_e32 v9, v9
	v_mul_f32_e32 v17, 0xbfb8aa3b, v8
	v_cvt_f32_f16_e32 v1, v11
	v_dual_mul_f32 v11, 0xbfb8aa3b, v4 :: v_dual_mul_f32 v20, 0xbfb8aa3b, v13
	v_cvt_f32_f16_e32 v7, v3
	v_mul_f32_e32 v3, 0xbfb8aa3b, v6
	v_exp_f32_e32 v16, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v9
	v_exp_f32_e32 v17, v17
	v_exp_f32_e32 v11, v11
	v_mul_f32_e32 v19, 0xbfb8aa3b, v5
	v_mul_f32_e32 v21, 0xbfb8aa3b, v7
	v_exp_f32_e32 v3, v3
	v_exp_f32_e32 v18, v18
	v_exp_f32_e32 v22, v20
	v_nop
	v_add_f32_e32 v20, 1.0, v16
	v_exp_f32_e32 v19, v19
	v_exp_f32_e32 v21, v21
	v_dual_add_f32 v17, 1.0, v17 :: v_dual_add_f32 v11, 1.0, v11
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_add_f32 v3, 1.0, v3 :: v_dual_add_f32 v23, 1.0, v22
	v_rcp_f32_e32 v20, v20
	v_rcp_f32_e32 v16, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v18
	v_rcp_f32_e32 v18, v11
	v_dual_add_f32 v11, 1.0, v19 :: v_dual_add_f32 v27, 1.0, v21
	v_rcp_f32_e32 v22, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_rcp_f32_e32 v21, v23
	v_rcp_f32_e32 v19, v11
	v_rcp_f32_e32 v23, v27
	v_cvt_f32_f16_e32 v11, v15
	v_cvt_f32_f16_e32 v3, v25
	v_cvt_f32_f16_e32 v15, v26
	v_pk_mul_f32 v[8:9], v[16:17], v[8:9]
	v_pk_mul_f32 v[12:13], v[20:21], v[12:13]
	v_pk_mul_f32 v[4:5], v[18:19], v[4:5]
	v_pk_mul_f32 v[6:7], v[22:23], v[6:7]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[0:1], v[8:9], v[0:1]
	v_pk_mul_f32 v[2:3], v[12:13], v[2:3]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[4:5], v[4:5], v[10:11]
	v_pk_mul_f32 v[6:7], v[6:7], v[14:15]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_pk_f16_f32 v0, v0, v1
	v_cvt_pk_f16_f32 v2, v2, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_pk_f16_f32 v1, v4, v5
	v_cvt_pk_f16_f32 v3, v6, v7
	global_store_b128 v24, v[0:3], s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel swiglu_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
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
		.amdhsa_next_free_vgpr 28
		.amdhsa_next_free_sgpr 9
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 5
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
.Lfunc_end3:
	.size	swiglu_f16, .Lfunc_end3-swiglu_f16
                                        ; -- End function
	.set swiglu_f16.num_vgpr, 28
	.set swiglu_f16.num_agpr, 0
	.set swiglu_f16.numbered_sgpr, 9
	.set swiglu_f16.num_named_barrier, 0
	.set swiglu_f16.private_seg_size, 0
	.set swiglu_f16.uses_vcc, 0
	.set swiglu_f16.uses_flat_scratch, 0
	.set swiglu_f16.has_dyn_sized_stack, 0
	.set swiglu_f16.has_recursion, 0
	.set swiglu_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 528
; TotalNumSgprs: 9
; NumVgprs: 28
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 28
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
	.protected	rope_f16                ; -- Begin function rope_f16
	.globl	rope_f16
	.p2align	8
	.type	rope_f16,@function
rope_f16:                               ; @rope_f16
; %bb.0:
	s_load_b256 s[4:11], s[0:1], 0x0
	s_wait_xcnt 0x0
	s_bfe_u32 s0, ttmp6, 0x4000c
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_bitop2_b32 v0, 1, v0 bitop3:0x40
	s_add_co_i32 s0, s0, 1
	s_and_b32 s1, ttmp6, 15
	s_mul_i32 s0, ttmp9, s0
	s_getreg_b32 s2, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s1, s1, s0
	v_lshl_or_b32 v1, v0, 6, v1
	s_cmp_eq_u32 s2, 0
	s_cselect_b32 s0, ttmp9, s1
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_lshl_add_u32 v1, s0, 7, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_and_b32_e32 v3, 0x7fff, v1
	s_wait_kmcnt 0x0
	global_load_u16 v2, v1, s[4:5] scale_offset
	s_clause 0x1
	global_load_u16 v4, v3, s[8:9] scale_offset
	global_load_u16 v5, v3, s[6:7] scale_offset
	s_wait_xcnt 0x0
	v_mbcnt_lo_u32_b32 v3, -1, 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_xor_b32_e32 v6, 1, v3
	v_cmp_gt_i32_e32 vcc_lo, 32, v6
	v_cndmask_b32_e32 v3, v3, v6, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v3, 2, v3
	s_wait_loadcnt 0x2
	v_cvt_f32_f16_e32 v6, v2
	ds_bpermute_b32 v3, v3, v6
	s_wait_dscnt 0x0
	v_cndmask_b32_e64 v0, v3, -v3, vcc_lo
	s_wait_loadcnt 0x1
	v_cvt_f32_f16_e32 v3, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v0, v0, v3
	s_wait_loadcnt 0x0
	v_fma_mixlo_f16 v0, v2, v5, v0 op_sel_hi:[1,1,0]
	global_store_b16 v1, v0, s[10:11] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rope_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
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
		.amdhsa_next_free_vgpr 7
		.amdhsa_next_free_sgpr 12
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
.Lfunc_end4:
	.size	rope_f16, .Lfunc_end4-rope_f16
                                        ; -- End function
	.set rope_f16.num_vgpr, 7
	.set rope_f16.num_agpr, 0
	.set rope_f16.numbered_sgpr, 12
	.set rope_f16.num_named_barrier, 0
	.set rope_f16.private_seg_size, 0
	.set rope_f16.uses_vcc, 1
	.set rope_f16.uses_flat_scratch, 0
	.set rope_f16.has_dyn_sized_stack, 0
	.set rope_f16.has_recursion, 0
	.set rope_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 248
; TotalNumSgprs: 14
; NumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 7
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
	.protected	reduction_f16           ; -- Begin function reduction_f16
	.globl	reduction_f16
	.p2align	8
	.type	reduction_f16,@function
reduction_f16:                          ; @reduction_f16
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB5_6
; %bb.1:
	s_bfe_u32 s4, ttmp6, 0x4000c
	s_load_b128 s[0:3], s[0:1], 0x0
	s_add_co_i32 s4, s4, 1
	s_bfe_u32 s6, ttmp6, 0x40010
	s_and_b32 s5, ttmp6, 15
	s_mul_i32 s4, ttmp9, s4
	s_add_co_i32 s6, s6, 1
	s_add_co_i32 s5, s5, s4
	s_mul_i32 s4, ttmp7, s6
	s_bfe_u32 s6, ttmp6, 0x40004
	s_getreg_b32 s7, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s6, s6, s4
	s_cmp_eq_u32 s7, 0
	s_cselect_b32 s4, ttmp7, s6
	s_cselect_b32 s5, ttmp9, s5
	s_lshl_b32 s6, s4, 9
	s_lshl_b32 s5, s5, 5
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_add_co_i32 s6, s6, s5
	v_or_b32_e32 v1, s6, v0
	s_wait_kmcnt 0x0
	global_load_b128 v[2:5], v1, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v1, v2
	v_lshrrev_b32_e32 v2, 16, v2
	v_cvt_f32_f16_e32 v6, v3
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v3, 16, v3 :: v_dual_add_f32 v1, 0, v1
	v_cvt_f32_f16_e32 v2, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_f32_e32 v1, v1, v2
	v_cvt_f32_f16_e32 v2, v3
	v_cvt_f32_f16_e32 v3, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_add_f32 v1, v1, v6 :: v_dual_lshrrev_b32 v4, 16, v4
	v_cvt_f32_f16_e32 v6, v5
	v_lshrrev_b32_e32 v5, 16, v5
	v_cvt_f32_f16_e32 v4, v4
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v1, v1, v2
	v_mbcnt_lo_u32_b32 v2, -1, 0
	v_dual_add_f32 v1, v1, v3 :: v_dual_bitop2_b32 v3, 16, v2 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_dual_cndmask_b32 v3, v2, v3, vcc_lo :: v_dual_add_f32 v1, v1, v4
	v_cvt_f32_f16_e32 v4, v5
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v3, 2, v3 :: v_dual_add_f32 v1, v1, v6
	v_dual_add_f32 v1, v1, v4 :: v_dual_bitop2_b32 v4, 8, v2 bitop3:0x14
	ds_bpermute_b32 v3, v3, v1
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v4, v2, v4, vcc_lo
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_dual_add_f32 v1, v1, v3 :: v_dual_lshlrev_b32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v1
	s_wait_dscnt 0x0
	v_dual_add_f32 v1, v1, v3 :: v_dual_bitop2_b32 v4, 4, v2 bitop3:0x14
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v4, v2, v4, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v1
	v_xor_b32_e32 v4, 2, v2
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v4, v2, v4, vcc_lo
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_dual_add_f32 v1, v1, v3 :: v_dual_lshlrev_b32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v1
	v_xor_b32_e32 v4, 1, v2
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v2, v2, v4, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_add_f32 v1, v1, v3 :: v_dual_lshlrev_b32 v2, 2, v2
	ds_bpermute_b32 v2, v2, v1
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB5_6
; %bb.2:
	s_wait_dscnt 0x0
	v_add_f32_e32 v0, v1, v2
	s_mov_b32 s1, exec_lo
	s_brev_b32 s0, 1
.LBB5_3:                                ; =>This Inner Loop Header: Depth=1
	s_ctz_i32_b32 s5, s1
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_readlane_b32 s6, v0, s5
	s_lshl_b32 s5, 1, s5
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_not1_b32 s1, s1, s5
	s_cmp_lg_u32 s1, 0
	s_add_f32 s0, s0, s6
	s_cbranch_scc1 .LBB5_3
; %bb.4:
	v_mbcnt_lo_u32_b32 v0, exec_lo, 0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB5_6
; %bb.5:
	v_dual_mov_b32 v0, s4 :: v_dual_mov_b32 v1, s0
	global_atomic_add_f32 v0, v1, s[2:3] scale_offset scope:SCOPE_DEV
.LBB5_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel reduction_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 7
		.amdhsa_next_free_sgpr 8
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 5
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
.Lfunc_end5:
	.size	reduction_f16, .Lfunc_end5-reduction_f16
                                        ; -- End function
	.set reduction_f16.num_vgpr, 7
	.set reduction_f16.num_agpr, 0
	.set reduction_f16.numbered_sgpr, 8
	.set reduction_f16.num_named_barrier, 0
	.set reduction_f16.private_seg_size, 0
	.set reduction_f16.uses_vcc, 1
	.set reduction_f16.uses_flat_scratch, 0
	.set reduction_f16.has_dyn_sized_stack, 0
	.set reduction_f16.has_recursion, 0
	.set reduction_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 552
; TotalNumSgprs: 10
; NumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 7
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	softmax_f16             ; -- Begin function softmax_f16
	.globl	softmax_f16
	.p2align	8
	.type	softmax_f16,@function
softmax_f16:                            ; @softmax_f16
; %bb.0:
	s_load_b96 s[8:10], s[0:1], 0x10
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	s_getreg_b32 s4, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s2, ttmp9, s2
	v_lshrrev_b32_e32 v1, 5, v0
	s_add_co_i32 s3, s3, s2
	s_cmp_eq_u32 s4, 0
	s_cselect_b32 s2, ttmp9, s3
	s_mov_b32 s3, exec_lo
	v_lshl_add_u32 v8, s2, 2, v1
	s_mov_b32 s2, 0
	s_wait_kmcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e64 s10, v8
	s_cbranch_execz .LBB6_3
; %bb.1:
	v_mbcnt_lo_u32_b32 v4, -1, 0
	s_load_b128 s[4:7], s[0:1], 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_lshlrev_b32 v0, 4, v0
	s_wait_xcnt 0x0
	s_load_b32 s1, s[0:1], 0x20
	v_xor_b32_e32 v3, 8, v4
	v_xor_b32_e32 v2, 16, v4
	v_xor_b32_e32 v6, 2, v4
	v_xor_b32_e32 v5, 4, v4
	v_and_b32_e32 v0, 0x1f0, v0
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_cmp_gt_i32_e32 vcc_lo, 32, v2
	v_cndmask_b32_e32 v2, v4, v2, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_dual_lshlrev_b32 v9, 2, v2 :: v_dual_bitop2_b32 v7, 1, v4 bitop3:0x14
	v_cndmask_b32_e32 v10, v4, v3, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v5
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[2:3], s[6:7], v[0:1]
	s_mul_i32 s3, s1, s9
	s_lshl_b32 s0, s1, 2
	v_dual_cndmask_b32 v11, v4, v5 :: v_dual_lshlrev_b32 v10, 2, v10
	v_cmp_gt_i32_e32 vcc_lo, 32, v6
	v_cndmask_b32_e32 v12, v4, v6, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v7
	v_mul_lo_u32 v6, s9, v8
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_lshlrev_b32 v11, 2, v11 :: v_dual_lshlrev_b32 v12, 2, v12
	v_cndmask_b32_e32 v7, v4, v7, vcc_lo
	v_add_nc_u64_e32 v[4:5], s[4:5], v[0:1]
	v_mul_lo_u32 v0, s8, v8
	s_mul_i32 s4, s1, s8
	s_lshl_b32 s1, s3, 2
	v_lshlrev_b32_e32 v13, 2, v7
	s_lshl_b32 s3, s4, 2
.LBB6_2:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_add_u64 v[14:15], v[0:1], 1, v[2:3]
	v_add_nc_u32_e32 v0, s3, v0
	global_load_b128 v[14:17], v[14:15], off
	s_wait_loadcnt 0x0
	v_dual_lshrrev_b32 v7, 16, v14 :: v_dual_lshrrev_b32 v20, 16, v15
	v_max_num_f16_e32 v18, v14, v14
	v_lshrrev_b32_e32 v21, 16, v17
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f16_e32 v19, v7, v7
	v_max_num_f16_e32 v18, v18, v19
	v_lshrrev_b32_e32 v19, 16, v16
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max3_num_f16 v18, v18, v15, v20
	v_max3_num_f16 v18, v18, v16, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max3_num_f16 v18, v18, v17, v21
	v_cvt_f32_f16_e32 v18, v18
	ds_bpermute_b32 v22, v9, v18
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v22, v22, v22
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v18, v18, v22
	ds_bpermute_b32 v22, v10, v18
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v22, v22, v22
	v_max_num_f32_e32 v18, v18, v22
	ds_bpermute_b32 v22, v11, v18
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v22, v22, v22
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v18, v18, v22
	ds_bpermute_b32 v22, v12, v18
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v22, v22, v22
	v_max_num_f32_e32 v18, v18, v22
	ds_bpermute_b32 v22, v13, v18
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v22, v22, v22
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v18, v18, v22
	v_cvt_f16_f32_e32 v18, v18
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_sub_f16_e32 v14, v14, v18
	v_sub_f16_e32 v7, v7, v18
	v_sub_f16_e32 v15, v15, v18
	v_sub_f16_e32 v20, v20, v18
	v_sub_f16_e32 v16, v16, v18
	v_cvt_f32_f16_e32 v14, v14
	v_cvt_f32_f16_e32 v7, v7
	v_cvt_f32_f16_e32 v15, v15
	v_cvt_f32_f16_e32 v20, v20
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_mul_f32 v14, 0x3fb8aa3b, v14 :: v_dual_mul_f32 v7, 0x3fb8aa3b, v7
	v_mul_f32_e32 v15, 0x3fb8aa3b, v15
	v_sub_f16_e32 v17, v17, v18
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_exp_f32_e32 v24, v14
	v_exp_f32_e32 v14, v7
	v_nop
	v_sub_f16_e32 v7, v19, v18
	v_exp_f32_e32 v15, v15
	v_sub_f16_e32 v18, v21, v18
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_cvt_f32_f16_e32 v7, v7
	v_add_f32_e32 v19, 0, v24
	v_mul_f32_e32 v20, 0x3fb8aa3b, v20
	v_cvt_f32_f16_e32 v21, v18
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_add_f32_e32 v19, v19, v14
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mul_f32_e32 v21, 0x3fb8aa3b, v21
	v_exp_f32_e32 v18, v7
	v_mul_f32_e32 v22, 0x3fb8aa3b, v16
	v_exp_f32_e32 v16, v20
	v_add_f32_e32 v19, v19, v15
	v_cvt_f32_f16_e32 v20, v17
	v_exp_f32_e32 v21, v21
	v_exp_f32_e32 v17, v22
	s_delay_alu instid0(TRANS32_DEP_3) | instid1(VALU_DEP_2)
	v_add_f32_e32 v19, v19, v16
	s_delay_alu instid0(TRANS32_DEP_1) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v20, 0x3fb8aa3b, v20 :: v_dual_add_f32 v7, v19, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v19, v20
	v_add_f32_e32 v7, v7, v18
	s_delay_alu instid0(TRANS32_DEP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v7, v7, v19
	s_delay_alu instid0(VALU_DEP_1)
	v_add_f32_e32 v7, v7, v21
	ds_bpermute_b32 v20, v9, v7
	s_wait_dscnt 0x0
	v_add_f32_e32 v7, v7, v20
	ds_bpermute_b32 v20, v10, v7
	s_wait_dscnt 0x0
	v_add_f32_e32 v7, v7, v20
	ds_bpermute_b32 v20, v11, v7
	s_wait_dscnt 0x0
	v_add_f32_e32 v7, v7, v20
	ds_bpermute_b32 v20, v12, v7
	s_wait_dscnt 0x0
	v_add_f32_e32 v7, v7, v20
	ds_bpermute_b32 v20, v13, v7
	s_wait_dscnt 0x0
	v_add_f32_e32 v7, v7, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v20, v7
	v_nop
	v_mov_b32_e32 v7, v1
	v_lshl_add_u64 v[22:23], v[6:7], 1, v[4:5]
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[18:19], v[20:21], v[18:19] op_sel_hi:[0,1]
	v_pk_mul_f32 v[14:15], v[20:21], v[14:15] op_sel_hi:[0,1]
	v_pk_mul_f32 v[16:17], v[20:21], v[16:17] op_sel_hi:[0,1]
	v_add_nc_u32_e32 v6, s1, v6
	v_cvt_pk_f16_f32 v7, v18, v19
	v_add_nc_u32_e32 v8, s0, v8
	v_fma_mixlo_f16 v18, v20, v24, 0
	v_cvt_pk_f16_f32 v15, v14, v15
	v_cvt_pk_f16_f32 v16, v16, v17
	v_lshrrev_b32_e32 v17, 16, v7
	v_cmp_le_u32_e32 vcc_lo, s10, v8
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pack_b32_f16 v14, v18, v15
	v_alignbit_b32 v15, v16, v15, 16
	v_alignbit_b32 v16, v7, v16, 16
	v_fma_mixhi_f16 v17, v20, v21, 0
	s_or_b32 s2, vcc_lo, s2
	global_store_b128 v[22:23], v[14:17], off
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB6_2
.LBB6_3:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel softmax_f16
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 288
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
		.amdhsa_next_free_vgpr 25
		.amdhsa_next_free_sgpr 11
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
.Lfunc_end6:
	.size	softmax_f16, .Lfunc_end6-softmax_f16
                                        ; -- End function
	.set softmax_f16.num_vgpr, 25
	.set softmax_f16.num_agpr, 0
	.set softmax_f16.numbered_sgpr, 11
	.set softmax_f16.num_named_barrier, 0
	.set softmax_f16.private_seg_size, 0
	.set softmax_f16.uses_vcc, 1
	.set softmax_f16.uses_flat_scratch, 0
	.set softmax_f16.has_dyn_sized_stack, 0
	.set softmax_f16.has_recursion, 0
	.set softmax_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 980
; TotalNumSgprs: 13
; NumVgprs: 25
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 13
; NumVGPRsForWavesPerEU: 25
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
	.protected	rmsnorm_f16             ; -- Begin function rmsnorm_f16
	.globl	rmsnorm_f16
	.p2align	8
	.type	rmsnorm_f16,@function
rmsnorm_f16:                            ; @rmsnorm_f16
; %bb.0:
	s_load_b128 s[4:7], s[0:1], 0x0
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	s_getreg_b32 s8, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s2, ttmp9, s2
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x10
	s_add_co_i32 s3, s3, s2
	s_cmp_eq_u32 s8, 0
	v_and_b32_e32 v22, 31, v0
	s_cselect_b32 s2, ttmp9, s3
	s_delay_alu instid0(SALU_CYCLE_1)
	v_lshl_add_u32 v6, s2, 9, v0
	s_wait_kmcnt 0x0
	s_clause 0x1
	global_load_b128 v[12:15], v6, s[4:5] scale_offset
	global_load_b128 v[2:5], v6, s[6:7] scale_offset
	s_mov_b32 s2, exec_lo
	s_wait_loadcnt 0x1
	v_dual_lshrrev_b32 v1, 16, v12 :: v_dual_lshrrev_b32 v7, 16, v13
	v_cvt_f32_f16_e32 v8, v12
	v_cvt_f32_f16_e32 v10, v13
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f32_f16_e32 v9, v1
	v_cvt_f32_f16_e32 v11, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_pk_mul_f32 v[12:13], v[8:9], v[8:9]
	v_lshrrev_b32_e32 v1, 16, v14
	v_pk_mul_f32 v[16:17], v[10:11], v[10:11]
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_add_f32_e32 v7, v12, v13
	v_cvt_f32_f16_e32 v12, v14
	v_cvt_f32_f16_e32 v13, v1
	v_cvt_f32_f16_e32 v14, v15
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_add_f32 v1, v7, v16 :: v_dual_lshrrev_b32 v7, 16, v15
	v_pk_mul_f32 v[18:19], v[12:13], v[12:13]
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_add_f32_e32 v16, v1, v17
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_cvt_f32_f16_e32 v15, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_add_f32 v7, v16, v18 :: v_dual_bitop2_b32 v18, 16, v1 bitop3:0x14
	v_pk_mul_f32 v[16:17], v[14:15], v[14:15]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_f32_e32 v7, v7, v19
	v_cmp_gt_i32_e32 vcc_lo, 32, v18
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_add_f32 v7, v7, v16 :: v_dual_cndmask_b32 v18, v1, v18
	v_dual_add_f32 v7, v7, v17 :: v_dual_lshlrev_b32 v16, 2, v18
	ds_bpermute_b32 v17, v16, v7
	v_xor_b32_e32 v16, 8, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_cmp_gt_i32_e32 vcc_lo, 32, v16
	s_wait_dscnt 0x0
	v_dual_cndmask_b32 v18, v1, v16 :: v_dual_add_f32 v7, v7, v17
	v_dual_lshlrev_b32 v18, 2, v18 :: v_dual_bitop2_b32 v17, 4, v1 bitop3:0x14
	ds_bpermute_b32 v18, v18, v7
	v_cmp_gt_i32_e32 vcc_lo, 32, v17
	s_wait_dscnt 0x0
	v_dual_cndmask_b32 v19, v1, v17, vcc_lo :: v_dual_add_f32 v7, v7, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v19, 2, v19 :: v_dual_bitop2_b32 v18, 2, v1 bitop3:0x14
	ds_bpermute_b32 v19, v19, v7
	v_cmp_gt_i32_e32 vcc_lo, 32, v18
	s_wait_dscnt 0x0
	v_dual_cndmask_b32 v20, v1, v18 :: v_dual_add_f32 v7, v7, v19
	v_lshlrev_b32_e32 v20, 2, v20
	ds_bpermute_b32 v20, v20, v7
	s_wait_dscnt 0x0
	v_dual_add_f32 v20, v7, v20 :: v_dual_bitop2_b32 v19, 1, v1 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_gt_i32_e32 vcc_lo, 32, v19
	v_cndmask_b32_e32 v21, v1, v19, vcc_lo
	v_lshlrev_b32_e32 v7, 2, v21
	ds_bpermute_b32 v21, v7, v20
	v_mov_b32_e32 v7, 0
	s_wait_xcnt 0x0
	v_cmpx_eq_u32_e32 0, v22
	s_cbranch_execz .LBB7_2
; %bb.1:
	s_wait_dscnt 0x0
	v_dual_lshrrev_b32 v22, 3, v0 :: v_dual_add_f32 v20, v20, v21
	ds_store_b32 v22, v20
.LBB7_2:
	s_or_b32 exec_lo, exec_lo, s2
	v_and_b32_e32 v20, 16, v1
	s_wait_loadcnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v20, 16, v20
	s_mov_b32 s2, 0x39800000
	v_lshrrev_b32_e32 v21, 16, v5
	v_cmp_lt_i32_e32 vcc_lo, v16, v20
	v_cndmask_b32_e32 v16, v1, v16, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v17, v20
	v_and_b32_e32 v0, 15, v0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_cndmask_b32 v17, v1, v17 :: v_dual_lshlrev_b32 v16, 2, v16
	v_lshlrev_b32_e32 v0, 2, v0
	v_cmp_lt_i32_e32 vcc_lo, v18, v20
	s_delay_alu instid0(VALU_DEP_3)
	v_lshlrev_b32_e32 v17, 2, v17
	ds_load_b32 v0, v0
	s_wait_dscnt 0x0
	ds_bpermute_b32 v16, v16, v0
	s_wait_dscnt 0x0
	v_add_f32_e32 v0, v0, v16
	ds_bpermute_b32 v16, v17, v0
	v_cndmask_b32_e32 v17, v1, v18, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v19, v20
	v_cvt_f32_f16_e32 v18, v5
	v_lshrrev_b32_e32 v20, 16, v4
	v_cvt_f32_f16_e32 v4, v4
	v_dual_lshlrev_b32 v17, 2, v17 :: v_dual_cndmask_b32 v1, v1, v19, vcc_lo
	v_lshrrev_b32_e32 v19, 16, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_cvt_f32_f16_e32 v5, v20
	s_wait_dscnt 0x0
	v_dual_add_f32 v0, v0, v16 :: v_dual_lshlrev_b32 v1, 2, v1
	ds_bpermute_b32 v16, v17, v0
	s_wait_dscnt 0x0
	v_dual_add_f32 v0, v0, v16 :: v_dual_lshrrev_b32 v17, 16, v2
	ds_bpermute_b32 v1, v1, v0
	s_wait_dscnt 0x0
	v_add_f32_e32 v1, v0, v1
	v_cvt_f32_f16_e32 v0, v2
	v_cvt_f32_f16_e32 v2, v3
	v_cvt_f32_f16_e32 v3, v19
	v_cvt_f32_f16_e32 v19, v21
	v_fmaak_f32 v1, s2, v1, 0x358637bd
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(TRANS32_DEP_1)
	v_rsq_f32_e32 v16, v1
	v_nop
	v_cvt_f32_f16_e32 v1, v17
	v_pk_mul_f32 v[8:9], v[16:17], v[8:9] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[16:17], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[12:13], v[16:17], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[14:15], v[16:17], v[14:15] op_sel_hi:[0,1]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[0:1], v[8:9], v[0:1]
	v_pk_mul_f32 v[2:3], v[10:11], v[2:3]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[4:5], v[12:13], v[4:5]
	v_pk_mul_f32 v[8:9], v[14:15], v[18:19]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_pk_f16_f32 v0, v0, v1
	v_cvt_pk_f16_f32 v1, v2, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_pk_f16_f32 v2, v4, v5
	v_cvt_pk_f16_f32 v3, v8, v9
	v_lshl_add_u64 v[4:5], v[6:7], 4, s[0:1]
	global_store_b128 v[4:5], v[0:3], off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rmsnorm_f16
		.amdhsa_group_segment_fixed_size 64
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
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
		.amdhsa_next_free_vgpr 23
		.amdhsa_next_free_sgpr 9
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 7
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
.Lfunc_end7:
	.size	rmsnorm_f16, .Lfunc_end7-rmsnorm_f16
                                        ; -- End function
	.set rmsnorm_f16.num_vgpr, 23
	.set rmsnorm_f16.num_agpr, 0
	.set rmsnorm_f16.numbered_sgpr, 9
	.set rmsnorm_f16.num_named_barrier, 0
	.set rmsnorm_f16.private_seg_size, 0
	.set rmsnorm_f16.uses_vcc, 1
	.set rmsnorm_f16.uses_flat_scratch, 0
	.set rmsnorm_f16.has_dyn_sized_stack, 0
	.set rmsnorm_f16.has_recursion, 0
	.set rmsnorm_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 880
; TotalNumSgprs: 11
; NumVgprs: 23
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 64 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 11
; NumVGPRsForWavesPerEU: 23
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
	.protected	matvec_f16              ; -- Begin function matvec_f16
	.globl	matvec_f16
	.p2align	8
	.type	matvec_f16,@function
matvec_f16:                             ; @matvec_f16
; %bb.0:
	v_lshrrev_b32_e32 v9, 7, v0
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_dual_mov_b32 v7, 0 :: v_dual_add_nc_u32 v2, 0x100, v0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 0
	v_dual_sub_nc_u32 v1, 28, v9 :: v_dual_lshlrev_b32 v8, 1, v0
	v_add_nc_u32_e32 v3, 0x180, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v10, v8 :: v_dual_lshrrev_b32 v1, 2, v1
	v_add_nc_u32_e32 v11, 1, v1
	v_add_nc_u32_e32 v1, 0x80, v0
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mov_b64_e32 v[4:5], v[2:3]
	v_and_b32_e32 v12, 12, v11
	s_delay_alu instid0(VALU_DEP_3)
	v_mov_b64_e32 v[2:3], v[0:1]
.LBB8_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v6, v2 :: v_dual_mov_b32 v19, v7
	v_dual_mov_b32 v25, v7 :: v_dual_add_nc_u32 v18, 0x200, v3
	v_dual_mov_b32 v31, v7 :: v_dual_add_nc_u32 v24, 0x400, v3
	s_wait_kmcnt 0x0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_add_u64 v[32:33], v[6:7], 1, s[6:7]
	v_dual_mov_b32 v6, v3 :: v_dual_add_nc_u32 v12, -4, v12
	v_add_nc_u32_e32 v30, 0x600, v3
	v_add_nc_u32_e32 v3, 0x800, v3
	global_load_u16 v1, v[32:33], off
	v_lshl_add_u64 v[34:35], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v4
	v_dual_mov_b32 v17, v7 :: v_dual_add_nc_u32 v14, 0x200, v5
	v_dual_mov_b32 v23, v7 :: v_dual_add_nc_u32 v20, 0x400, v5
	global_load_u16 v13, v[34:35], off
	s_wait_xcnt 0x1
	v_lshl_add_u64 v[32:33], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v5
	v_dual_mov_b32 v29, v7 :: v_dual_add_nc_u32 v26, 0x600, v5
	v_add_nc_u32_e32 v5, 0x800, v5
	global_load_u16 v36, v[32:33], off
	s_wait_xcnt 0x1
	v_lshl_add_u64 v[34:35], v[6:7], 1, s[6:7]
	v_add_nc_u32_e32 v6, 0x200, v2
	v_dual_mov_b32 v15, v7 :: v_dual_add_nc_u32 v16, 0x200, v4
	v_dual_mov_b32 v21, v7 :: v_dual_add_nc_u32 v22, 0x400, v4
	global_load_u16 v37, v[34:35], off
	s_wait_xcnt 0x1
	v_lshl_add_u64 v[32:33], v[6:7], 1, s[6:7]
	v_add_nc_u32_e32 v6, 0x400, v2
	v_dual_mov_b32 v27, v7 :: v_dual_add_nc_u32 v28, 0x600, v4
	v_lshl_add_u64 v[18:19], v[18:19], 1, s[6:7]
	v_lshl_add_u64 v[16:17], v[16:17], 1, s[6:7]
	s_wait_xcnt 0x0
	v_lshl_add_u64 v[34:35], v[6:7], 1, s[6:7]
	v_add_nc_u32_e32 v6, 0x600, v2
	v_lshl_add_u64 v[24:25], v[24:25], 1, s[6:7]
	v_lshl_add_u64 v[14:15], v[14:15], 1, s[6:7]
	v_lshl_add_u64 v[22:23], v[22:23], 1, s[6:7]
	v_lshl_add_u64 v[20:21], v[20:21], 1, s[6:7]
	s_clause 0x3
	global_load_u16 v38, v[32:33], off
	global_load_u16 v39, v[18:19], off
	global_load_u16 v40, v[16:17], off
	global_load_u16 v41, v[14:15], off
	s_wait_xcnt 0x0
	v_lshl_add_u64 v[14:15], v[6:7], 1, s[6:7]
	v_lshl_add_u64 v[30:31], v[30:31], 1, s[6:7]
	v_lshl_add_u64 v[28:29], v[28:29], 1, s[6:7]
	v_lshl_add_u64 v[26:27], v[26:27], 1, s[6:7]
	s_clause 0x7
	global_load_u16 v6, v[34:35], off
	global_load_u16 v16, v[24:25], off
	global_load_u16 v17, v[22:23], off
	global_load_u16 v18, v[20:21], off
	global_load_u16 v19, v[14:15], off
	global_load_u16 v32, v[30:31], off
	global_load_u16 v33, v[28:29], off
	global_load_u16 v42, v[26:27], off
	v_cmp_eq_u32_e32 vcc_lo, 0, v12
	v_add_nc_u32_e32 v4, 0x800, v4
	v_add_nc_u32_e32 v2, 0x800, v2
	s_wait_loadcnt 0xf
	ds_store_b16 v10, v1
	s_wait_loadcnt 0xe
	ds_store_b16 v10, v13 offset:256
	s_wait_loadcnt 0xd
	ds_store_b16 v10, v36 offset:512
	s_wait_loadcnt 0xc
	ds_store_b16 v10, v37 offset:768
	s_wait_loadcnt 0xb
	ds_store_b16 v10, v38 offset:1024
	s_wait_loadcnt 0xa
	ds_store_b16 v10, v39 offset:1280
	s_wait_loadcnt 0x9
	ds_store_b16 v10, v40 offset:1536
	s_wait_loadcnt 0x8
	ds_store_b16 v10, v41 offset:1792
	s_wait_loadcnt 0x7
	ds_store_b16 v10, v6 offset:2048
	s_wait_loadcnt 0x6
	ds_store_b16 v10, v16 offset:2304
	s_wait_loadcnt 0x5
	ds_store_b16 v10, v17 offset:2560
	s_wait_loadcnt 0x4
	ds_store_b16 v10, v18 offset:2816
	s_wait_loadcnt 0x3
	ds_store_b16 v10, v19 offset:3072
	s_wait_loadcnt 0x2
	ds_store_b16 v10, v32 offset:3328
	s_wait_loadcnt 0x1
	ds_store_b16 v10, v33 offset:3584
	s_wait_loadcnt 0x0
	ds_store_b16 v10, v42 offset:3840
	v_add_nc_u32_e32 v10, 0x1000, v10
	s_or_b32 s0, vcc_lo, s0
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s0
	s_cbranch_execnz .LBB8_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s0
	v_and_b32_e32 v1, 3, v11
	s_mov_b32 s1, 0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_ne_u32_e32 0, v1
	s_cbranch_execz .LBB8_5
; %bb.3:
	v_mov_b32_e32 v7, 0
.LBB8_4:                                ; =>This Inner Loop Header: Depth=1
	v_dual_mov_b32 v6, v2 :: v_dual_add_nc_u32 v1, -1, v1
	v_add_nc_u32_e32 v2, 0x200, v2
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_lshl_add_u64 v[12:13], v[6:7], 1, s[6:7]
	v_dual_mov_b32 v6, v3 :: v_dual_add_nc_u32 v3, 0x200, v3
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[14:15], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v4
	v_add_nc_u32_e32 v4, 0x200, v4
	s_or_b32 s1, vcc_lo, s1
	v_lshl_add_u64 v[16:17], v[6:7], 1, s[6:7]
	v_dual_mov_b32 v6, v5 :: v_dual_add_nc_u32 v5, 0x200, v5
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[18:19], v[6:7], 1, s[6:7]
	s_clause 0x3
	global_load_u16 v6, v[12:13], off
	global_load_u16 v11, v[14:15], off
	global_load_u16 v20, v[16:17], off
	global_load_u16 v21, v[18:19], off
	s_wait_loadcnt 0x3
	ds_store_b16 v10, v6
	s_wait_loadcnt 0x2
	ds_store_b16 v10, v11 offset:256
	s_wait_loadcnt 0x1
	ds_store_b16 v10, v20 offset:512
	s_wait_loadcnt 0x0
	ds_store_b16 v10, v21 offset:768
	v_add_nc_u32_e32 v10, 0x400, v10
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB8_4
.LBB8_5:
	s_or_b32 exec_lo, exec_lo, s0
	v_sub_nc_u32_e32 v1, 32, v9
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v2, 60, v1
	v_cmpx_ne_u32_e64 v1, v2
	s_cbranch_execz .LBB8_8
; %bb.6:
	v_lshl_add_u32 v4, v2, 7, v0
	v_lshlrev_b32_e32 v1, 8, v1
	s_mov_b32 s1, 0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshlrev_b32_e32 v2, 1, v4
	v_and_b32_e32 v5, 0x3c00, v1
	v_mov_b32_e32 v3, 0
	v_add_nc_u32_e32 v1, 0xffffff80, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_nc_u32_e32 v4, v5, v8
	v_add_nc_u64_e32 v[2:3], s[6:7], v[2:3]
.LBB8_7:                                ; =>This Inner Loop Header: Depth=1
	global_load_u16 v5, v[2:3], off
	v_add_nc_u32_e32 v1, 0x80, v1
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 0x100, v[2:3]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xf7f, v1
	s_or_b32 s1, vcc_lo, s1
	s_wait_loadcnt 0x0
	ds_store_b16 v4, v5
	v_add_nc_u32_e32 v4, 0x100, v4
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB8_7
.LBB8_8:
	s_or_b32 exec_lo, exec_lo, s0
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_lshrrev_b32_e32 v4, 5, v0
	s_bfe_u32 s0, ttmp6, 0x4000c
	s_and_b32 s1, ttmp6, 15
	s_add_co_i32 s0, s0, 1
	v_xor_b32_e32 v2, 16, v1
	s_mul_i32 s0, ttmp9, s0
	s_wait_dscnt 0x0
	s_add_co_i32 s1, s1, s0
	s_getreg_b32 s0, hwreg(HW_REG_IB_STS2, 6, 4)
	v_cmp_gt_i32_e32 vcc_lo, 32, v2
	v_xor_b32_e32 v3, 8, v1
	v_and_b32_e32 v11, 31, v0
	s_cmp_eq_u32 s0, 0
	s_barrier_signal -1
	v_cndmask_b32_e32 v0, v1, v2, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	s_cselect_b32 s0, ttmp9, s1
	s_barrier_wait -1
	s_lshl_b32 s1, s0, 17
	v_dual_cndmask_b32 v2, v1, v3 :: v_dual_lshlrev_b32 v5, 2, v0
	v_xor_b32_e32 v3, 4, v1
	v_xor_b32_e32 v0, 2, v1
	v_or_b32_e32 v10, 0xffffffe0, v11
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_lshlrev_b32_e32 v6, 2, v2
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_dual_cndmask_b32 v3, v1, v3, vcc_lo :: v_dual_bitop2_b32 v2, 1, v1 bitop3:0x14
	v_cmp_gt_i32_e32 vcc_lo, 32, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_dual_lshlrev_b32 v9, 12, v4 :: v_dual_lshlrev_b32 v7, 2, v3
	v_cndmask_b32_e32 v0, v1, v0, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v2
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_dual_cndmask_b32 v2, v1, v2, vcc_lo :: v_dual_lshlrev_b32 v8, 2, v0
	v_mov_b32_e32 v1, 0
	v_or3_b32 v0, v9, s1, v11
	v_cmp_eq_u32_e32 vcc_lo, 0, v11
	v_dual_lshlrev_b32 v9, 2, v2 :: v_dual_lshlrev_b32 v11, 1, v11
	s_mov_b32 s1, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[4:5]
	s_lshl_b32 s4, s0, 5
	s_branch .LBB8_10
.LBB8_9:                                ;   in Loop: Header=BB8_10 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_add_nc_u32_e32 v2, 4, v4
	v_cmp_lt_u32_e64 s0, 27, v4
	v_add_nc_u64_e32 v[0:1], 0x8000, v[0:1]
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_mov_b32_e32 v4, v2
	s_or_b32 s1, s0, s1
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execz .LBB8_14
.LBB8_10:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB8_11 Depth 2
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[2:3], v[0:1]
	v_dual_mov_b32 v13, v11 :: v_dual_mov_b32 v14, v10
	v_mov_b32_e32 v12, 0
	s_mov_b32 s5, 0
.LBB8_11:                               ;   Parent Loop BB8_10 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v15, v[2:3], off
	ds_load_u16 v16, v13
	v_dual_add_nc_u32 v14, 32, v14 :: v_dual_add_nc_u32 v13, 64, v13
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 64, v[2:3]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e64 s0, 0xfdf, v14
	s_or_b32 s5, s0, s5
	s_wait_loadcnt_dscnt 0x0
	v_fma_mix_f32 v12, v15, v16, v12 op_sel_hi:[1,1,0]
	s_and_not1_b32 exec_lo, exec_lo, s5
	s_cbranch_execnz .LBB8_11
; %bb.12:                               ;   in Loop: Header=BB8_10 Depth=1
	s_or_b32 exec_lo, exec_lo, s5
	ds_bpermute_b32 v2, v5, v12
	s_wait_dscnt 0x0
	v_add_f32_e32 v2, v12, v2
	ds_bpermute_b32 v3, v6, v2
	s_wait_dscnt 0x0
	v_add_f32_e32 v2, v2, v3
	ds_bpermute_b32 v3, v7, v2
	s_wait_dscnt 0x0
	v_add_f32_e32 v2, v2, v3
	ds_bpermute_b32 v3, v8, v2
	s_wait_dscnt 0x0
	v_add_f32_e32 v2, v2, v3
	ds_bpermute_b32 v3, v9, v2
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB8_9
; %bb.13:                               ;   in Loop: Header=BB8_10 Depth=1
	s_wait_dscnt 0x0
	v_dual_add_f32 v2, v2, v3 :: v_dual_add_nc_u32 v3, s4, v4
	s_delay_alu instid0(VALU_DEP_1)
	v_cvt_f16_f32_e32 v2, v2
	global_store_b16 v3, v2, s[2:3] scale_offset
	s_branch .LBB8_9
.LBB8_14:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matvec_f16
		.amdhsa_group_segment_fixed_size 8192
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
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
		.amdhsa_next_free_vgpr 43
		.amdhsa_next_free_sgpr 8
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 15
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
.Lfunc_end8:
	.size	matvec_f16, .Lfunc_end8-matvec_f16
                                        ; -- End function
	.set matvec_f16.num_vgpr, 43
	.set matvec_f16.num_agpr, 0
	.set matvec_f16.numbered_sgpr, 8
	.set matvec_f16.num_named_barrier, 0
	.set matvec_f16.private_seg_size, 0
	.set matvec_f16.uses_vcc, 1
	.set matvec_f16.uses_flat_scratch, 0
	.set matvec_f16.has_dyn_sized_stack, 0
	.set matvec_f16.has_recursion, 0
	.set matvec_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1808
; TotalNumSgprs: 10
; NumVgprs: 43
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8192 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 43
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
	.type	__hip_cuid_d2feff06edddaa55,@object ; @__hip_cuid_d2feff06edddaa55
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_d2feff06edddaa55
__hip_cuid_d2feff06edddaa55:
	.byte	0                               ; 0x0
	.size	__hip_cuid_d2feff06edddaa55, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_d2feff06edddaa55
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           relu_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         relu_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           silu_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     7
    .sgpr_spill_count: 0
    .symbol:         silu_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     10
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           sigmoid_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     7
    .sgpr_spill_count: 0
    .symbol:         sigmoid_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     5
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           swiglu_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         swiglu_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     28
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           rope_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         rope_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           reduction_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         reduction_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .offset:         16
        .size:           4
        .value_kind:     by_value
      - .offset:         20
        .size:           4
        .value_kind:     by_value
      - .offset:         24
        .size:           4
        .value_kind:     by_value
      - .offset:         28
        .size:           4
        .value_kind:     by_value
      - .offset:         32
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         36
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         40
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         44
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         46
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         48
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         50
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         52
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         54
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         80
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         88
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         96
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 288
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           softmax_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     13
    .sgpr_spill_count: 0
    .symbol:         softmax_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     25
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 64
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           rmsnorm_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     11
    .sgpr_spill_count: 0
    .symbol:         rmsnorm_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     23
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 8192
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           matvec_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matvec_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     43
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
