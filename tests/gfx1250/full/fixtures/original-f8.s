	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	relu_f8                 ; -- Begin function relu_f8
	.globl	relu_f8
	.p2align	8
	.type	relu_f8,@function
relu_f8:                                ; @relu_f8
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
	v_lshl_add_u32 v4, s4, 8, v0
	s_wait_kmcnt 0x0
	global_load_b64 v[0:1], v4, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v2, v0
	v_cvt_f32_fp8_e64 v3, v0 byte_sel:1
	v_cvt_f32_fp8_e64 v5, v0 byte_sel:2
	v_cvt_f32_fp8_e64 v0, v0 byte_sel:3
	v_cvt_f32_fp8_e32 v6, v1
	v_cvt_f32_fp8_e64 v7, v1 byte_sel:1
	v_cvt_f32_fp8_e64 v8, v1 byte_sel:2
	v_cvt_f32_fp8_e64 v1, v1 byte_sel:3
	v_dual_max_num_f32 v2, v2, v2 :: v_dual_max_num_f32 v3, v3, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_max_num_f32 v6, v6, v6 :: v_dual_max_num_f32 v7, v7, v7
	v_dual_max_num_f32 v5, v5, v5 :: v_dual_max_num_f32 v8, v8, v8
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_max_num_f32 v0, v0, v0 :: v_dual_max_num_f32 v1, v1, v1
	v_max_num_f32_e32 v9, 0, v2
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_max_num_f32 v2, 0, v6 :: v_dual_max_num_f32 v6, 0, v7
	v_dual_max_num_f32 v7, 0, v8 :: v_dual_max_num_f32 v1, 0, v1
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_dual_max_num_f32 v0, 0, v0 :: v_dual_max_num_f32 v5, 0, v5
	v_max_num_f32_e32 v8, 0, v3
	v_cvt_pk_f16_f32 v2, v2, v6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_pk_f16_f32 v3, v7, v1
	v_cvt_pk_f16_f32 v1, v5, v0
	s_delay_alu instid0(VALU_DEP_4)
	v_cvt_pk_f16_f32 v0, v9, v8
	v_add_nc_u32_e32 v5, 0x80, v4
	global_store_b128 v4, v[0:3], s[2:3] scale_offset
	global_load_b64 v[0:1], v5, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v2, v0
	v_cvt_f32_fp8_e64 v3, v0 byte_sel:1
	v_cvt_f32_fp8_e64 v4, v0 byte_sel:2
	v_cvt_f32_fp8_e64 v0, v0 byte_sel:3
	v_cvt_f32_fp8_e32 v6, v1
	v_cvt_f32_fp8_e64 v7, v1 byte_sel:1
	v_cvt_f32_fp8_e64 v8, v1 byte_sel:2
	v_cvt_f32_fp8_e64 v1, v1 byte_sel:3
	v_max_num_f32_e32 v2, v2, v2
	v_dual_max_num_f32 v6, v6, v6 :: v_dual_max_num_f32 v3, v3, v3
	v_dual_max_num_f32 v7, v7, v7 :: v_dual_max_num_f32 v4, v4, v4
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_max_num_f32 v8, v8, v8 :: v_dual_max_num_f32 v1, v1, v1
	v_dual_max_num_f32 v0, v0, v0 :: v_dual_max_num_f32 v9, 0, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_max_num_f32 v2, 0, v6 :: v_dual_max_num_f32 v6, 0, v7
	v_dual_max_num_f32 v7, 0, v8 :: v_dual_max_num_f32 v1, 0, v1
	v_dual_max_num_f32 v4, 0, v4 :: v_dual_max_num_f32 v8, 0, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_max_num_f32_e32 v0, 0, v0
	v_cvt_pk_f16_f32 v2, v2, v6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_cvt_pk_f16_f32 v3, v7, v1
	v_cvt_pk_f16_f32 v1, v4, v0
	v_cvt_pk_f16_f32 v0, v9, v8
	global_store_b128 v5, v[0:3], s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel relu_f8
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
		.amdhsa_inst_pref_size 4
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
	.size	relu_f8, .Lfunc_end0-relu_f8
                                        ; -- End function
	.set relu_f8.num_vgpr, 10
	.set relu_f8.num_agpr, 0
	.set relu_f8.numbered_sgpr, 7
	.set relu_f8.num_named_barrier, 0
	.set relu_f8.private_seg_size, 0
	.set relu_f8.uses_vcc, 0
	.set relu_f8.uses_flat_scratch, 0
	.set relu_f8.has_dyn_sized_stack, 0
	.set relu_f8.has_recursion, 0
	.set relu_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 492
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
	.protected	silu_f8                 ; -- Begin function silu_f8
	.globl	silu_f8
	.p2align	8
	.type	silu_f8,@function
silu_f8:                                ; @silu_f8
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
	v_lshl_add_u32 v4, s4, 8, v0
	s_wait_kmcnt 0x0
	global_load_b32 v2, v4, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e64 v0, v2 byte_sel:1
	v_cvt_f32_fp8_e64 v1, v2 byte_sel:2
	v_cvt_f32_fp8_e32 v5, v2
	v_cvt_f32_fp8_e64 v6, v2 byte_sel:3
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mul_f32 v2, 0xbfb8aa3b, v0 :: v_dual_mul_f32 v3, 0xbfb8aa3b, v1
	v_dual_mul_f32 v7, 0xbfb8aa3b, v5 :: v_dual_mul_f32 v8, 0xbfb8aa3b, v6
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v2, v2
	v_exp_f32_e32 v3, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v7, v7
	v_exp_f32_e32 v8, v8
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_dual_add_f32 v2, 1.0, v2 :: v_dual_add_f32 v3, 1.0, v3
	v_dual_add_f32 v7, 1.0, v7 :: v_dual_add_f32 v8, 1.0, v8
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_rcp_f32_e32 v2, v2
	v_rcp_f32_e32 v3, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v7, v7
	v_rcp_f32_e32 v8, v8
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_2)
	v_pk_mul_f32 v[0:1], v[0:1], v[2:3]
	v_fma_mixlo_f16 v2, v5, v7, 0
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_fma_mixlo_f16 v3, v6, v8, 0
	v_cvt_pk_f16_f32 v1, v0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_pack_b32_f16 v0, v2, v1
	v_alignbit_b32 v1, v3, v1, 16
	global_store_b64 v4, v[0:1], s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel silu_f8
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
		.amdhsa_next_free_vgpr 9
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
	.size	silu_f8, .Lfunc_end1-silu_f8
                                        ; -- End function
	.set silu_f8.num_vgpr, 9
	.set silu_f8.num_agpr, 0
	.set silu_f8.numbered_sgpr, 7
	.set silu_f8.num_named_barrier, 0
	.set silu_f8.private_seg_size, 0
	.set silu_f8.uses_vcc, 0
	.set silu_f8.uses_flat_scratch, 0
	.set silu_f8.has_dyn_sized_stack, 0
	.set silu_f8.has_recursion, 0
	.set silu_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 276
; TotalNumSgprs: 7
; NumVgprs: 9
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 7
; NumVGPRsForWavesPerEU: 9
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
	.protected	sigmoid_f8              ; -- Begin function sigmoid_f8
	.globl	sigmoid_f8
	.p2align	8
	.type	sigmoid_f8,@function
sigmoid_f8:                             ; @sigmoid_f8
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
	global_load_b64 v[0:1], v4, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v2, v0
	v_cvt_f32_fp8_e64 v3, v0 byte_sel:1
	v_cvt_f32_fp8_e64 v5, v0 byte_sel:2
	v_cvt_f32_fp8_e64 v0, v0 byte_sel:3
	v_cvt_f32_fp8_e32 v6, v1
	v_cvt_f32_fp8_e64 v7, v1 byte_sel:1
	v_cvt_f32_fp8_e64 v8, v1 byte_sel:2
	v_cvt_f32_fp8_e64 v1, v1 byte_sel:3
	v_dual_mul_f32 v2, 0xbfb8aa3b, v2 :: v_dual_mul_f32 v3, 0xbfb8aa3b, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_mul_f32 v6, 0xbfb8aa3b, v6 :: v_dual_mul_f32 v7, 0xbfb8aa3b, v7
	v_dual_mul_f32 v5, 0xbfb8aa3b, v5 :: v_dual_mul_f32 v8, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_mul_f32 v0, 0xbfb8aa3b, v0 :: v_dual_mul_f32 v1, 0xbfb8aa3b, v1
	v_exp_f32_e32 v2, v2
	s_delay_alu instid0(VALU_DEP_3)
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v3, v3
	v_exp_f32_e32 v7, v7
	v_exp_f32_e32 v5, v5
	v_exp_f32_e32 v8, v8
	v_exp_f32_e32 v0, v0
	v_exp_f32_e32 v1, v1
	v_dual_add_f32 v2, 1.0, v2 :: v_dual_add_f32 v3, 1.0, v3
	v_dual_add_f32 v6, 1.0, v6 :: v_dual_add_f32 v7, 1.0, v7
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_dual_add_f32 v5, 1.0, v5 :: v_dual_add_f32 v8, 1.0, v8
	v_dual_add_f32 v0, 1.0, v0 :: v_dual_add_f32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_rcp_f32_e32 v9, v2
	v_rcp_f32_e32 v2, v6
	v_rcp_f32_e32 v6, v7
	v_rcp_f32_e32 v7, v8
	v_rcp_f32_e32 v1, v1
	v_rcp_f32_e32 v5, v5
	v_rcp_f32_e32 v0, v0
	v_rcp_f32_e32 v8, v3
	v_cvt_pk_f16_f32 v2, v2, v6
	v_cvt_pk_f16_f32 v3, v7, v1
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_cvt_pk_f16_f32 v1, v5, v0
	v_cvt_pk_f16_f32 v0, v9, v8
	global_store_b128 v4, v[0:3], s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel sigmoid_f8
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
.Lfunc_end2:
	.size	sigmoid_f8, .Lfunc_end2-sigmoid_f8
                                        ; -- End function
	.set sigmoid_f8.num_vgpr, 10
	.set sigmoid_f8.num_agpr, 0
	.set sigmoid_f8.numbered_sgpr, 7
	.set sigmoid_f8.num_named_barrier, 0
	.set sigmoid_f8.private_seg_size, 0
	.set sigmoid_f8.uses_vcc, 0
	.set sigmoid_f8.uses_flat_scratch, 0
	.set sigmoid_f8.has_dyn_sized_stack, 0
	.set sigmoid_f8.has_recursion, 0
	.set sigmoid_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 348
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
	.protected	swiglu_f8               ; -- Begin function swiglu_f8
	.globl	swiglu_f8
	.p2align	8
	.type	swiglu_f8,@function
swiglu_f8:                              ; @swiglu_f8
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
	v_lshl_add_u32 v12, s2, 9, v0
	s_wait_kmcnt 0x0
	s_clause 0x1
	global_load_b32 v3, v12, s[4:5] scale_offset
	global_load_b32 v11, v12, s[6:7] scale_offset
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v0, v3
	v_cvt_f32_fp8_e64 v1, v3 byte_sel:1
	v_cvt_f32_fp8_e64 v2, v3 byte_sel:2
	v_cvt_f32_fp8_e64 v3, v3 byte_sel:3
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v11
	v_dual_mul_f32 v4, 0xbfb8aa3b, v0 :: v_dual_mul_f32 v5, 0xbfb8aa3b, v1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_dual_mul_f32 v6, 0xbfb8aa3b, v2 :: v_dual_mul_f32 v7, 0xbfb8aa3b, v3
	v_cvt_f32_fp8_e64 v9, v11 byte_sel:1
	v_exp_f32_e32 v4, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v5, v5
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_cvt_f32_fp8_e64 v10, v11 byte_sel:2
	v_cvt_f32_fp8_e64 v11, v11 byte_sel:3
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_dual_add_f32 v4, 1.0, v4 :: v_dual_add_f32 v5, 1.0, v5
	v_dual_add_f32 v6, 1.0, v6 :: v_dual_add_f32 v7, 1.0, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_rcp_f32_e32 v4, v4
	v_rcp_f32_e32 v5, v5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v6, v6
	v_rcp_f32_e32 v7, v7
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_pk_mul_f32 v[0:1], v[0:1], v[4:5]
	v_pk_mul_f32 v[2:3], v[2:3], v[6:7]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_mul_f32 v[0:1], v[8:9], v[0:1]
	v_pk_mul_f32 v[2:3], v[10:11], v[2:3]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_pk_f16_f32 v0, v0, v1
	v_cvt_pk_f16_f32 v1, v2, v3
	global_store_b64 v12, v[0:1], s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel swiglu_f8
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
		.amdhsa_next_free_vgpr 13
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
.Lfunc_end3:
	.size	swiglu_f8, .Lfunc_end3-swiglu_f8
                                        ; -- End function
	.set swiglu_f8.num_vgpr, 13
	.set swiglu_f8.num_agpr, 0
	.set swiglu_f8.numbered_sgpr, 9
	.set swiglu_f8.num_named_barrier, 0
	.set swiglu_f8.private_seg_size, 0
	.set swiglu_f8.uses_vcc, 0
	.set swiglu_f8.uses_flat_scratch, 0
	.set swiglu_f8.has_dyn_sized_stack, 0
	.set swiglu_f8.has_recursion, 0
	.set swiglu_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 332
; TotalNumSgprs: 9
; NumVgprs: 13
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 13
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
	.protected	rope_f8                 ; -- Begin function rope_f8
	.globl	rope_f8
	.p2align	8
	.type	rope_f8,@function
rope_f8:                                ; @rope_f8
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_load_b256 s[4:11], s[0:1], 0x0
	s_add_co_i32 s2, s2, 1
	s_wait_xcnt 0x0
	s_and_b32 s0, ttmp6, 15
	s_mul_i32 s1, ttmp9, s2
	s_getreg_b32 s2, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s0, s0, s1
	s_cmp_eq_u32 s2, 0
	v_cmp_gt_u32_e32 vcc_lo, 64, v0
	s_cselect_b32 s0, ttmp9, s0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_lshl_add_u32 v1, s0, 7, v0
	s_mov_b32 s0, 0x3e800000
	v_xor_b32_e32 v2, 64, v1
	v_and_b32_e32 v3, 0x7fff, v1
	s_wait_kmcnt 0x0
	global_load_u8 v2, v2, s[4:5]
	global_load_u8 v4, v3, s[8:9]
	global_load_u8 v5, v1, s[4:5]
	global_load_u8 v6, v3, s[6:7]
	s_wait_loadcnt 0x1
	s_wait_xcnt 0x0
	v_cvt_f32_fp8_e32 v3, v5
	v_cvt_f32_fp8_e32 v2, v2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_fma_mixlo_f16 v3, v3, s0, 0
	v_cndmask_b32_e64 v0, v2, -v2, vcc_lo
	v_cvt_f32_fp8_e32 v2, v4
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v4, v6
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_fma_mixlo_f16 v0, v0, s0, 0
	v_cvt_f16_f32_e32 v2, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_f32_e32 v4, v4
	v_mul_f16_e32 v0, v0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f16_e32 v0, v3, v4
	v_mul_f16_e32 v0, 4.0, v0
	global_store_b16 v1, v0, s[10:11] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rope_f8
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
	.size	rope_f8, .Lfunc_end4-rope_f8
                                        ; -- End function
	.set rope_f8.num_vgpr, 7
	.set rope_f8.num_agpr, 0
	.set rope_f8.numbered_sgpr, 12
	.set rope_f8.num_named_barrier, 0
	.set rope_f8.private_seg_size, 0
	.set rope_f8.uses_vcc, 1
	.set rope_f8.uses_flat_scratch, 0
	.set rope_f8.has_dyn_sized_stack, 0
	.set rope_f8.has_recursion, 0
	.set rope_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 240
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
	.protected	rmsnorm_f8              ; -- Begin function rmsnorm_f8
	.globl	rmsnorm_f8
	.p2align	8
	.type	rmsnorm_f8,@function
rmsnorm_f8:                             ; @rmsnorm_f8
; %bb.0:
	s_load_b128 s[4:7], s[0:1], 0x0
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	s_getreg_b32 s8, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s2, ttmp9, s2
	v_mbcnt_lo_u32_b32 v1, -1, 0
	s_add_co_i32 s3, s3, s2
	s_cmp_eq_u32 s8, 0
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x10
	s_cselect_b32 s2, ttmp9, s3
	v_and_b32_e32 v20, 31, v0
	v_lshl_add_u32 v2, s2, 9, v0
	s_wait_kmcnt 0x0
	s_clause 0x1
	global_load_b64 v[14:15], v2, s[4:5] scale_offset
	global_load_b64 v[4:5], v2, s[6:7] scale_offset
	s_mov_b32 s2, exec_lo
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v10, v15
	v_cvt_f32_fp8_e64 v11, v15 byte_sel:1
	v_cvt_f32_fp8_e32 v12, v14
	v_cvt_f32_fp8_e64 v13, v14 byte_sel:1
	v_cvt_f32_fp8_e64 v6, v15 byte_sel:2
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_mul_f32 v3, v10, v10 :: v_dual_mul_f32 v16, v11, v11
	v_cvt_f32_fp8_e64 v8, v14 byte_sel:2
	v_cvt_f32_fp8_e64 v7, v15 byte_sel:3
	v_dual_mul_f32 v15, v6, v6 :: v_dual_fmac_f32 v3, v12, v12
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_fmac_f32_e32 v16, v13, v13
	v_xor_b32_e32 v17, 16, v1
	v_cvt_f32_fp8_e64 v9, v14 byte_sel:3
	v_dual_mul_f32 v14, v7, v7 :: v_dual_fmac_f32 v15, v8, v8
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_gt_i32_e32 vcc_lo, 32, v17
	v_dual_add_f32 v3, v3, v16 :: v_dual_cndmask_b32 v16, v1, v17
	v_dual_fmac_f32 v14, v9, v9 :: v_dual_add_f32 v3, v3, v15
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_lshlrev_b32 v15, 2, v16 :: v_dual_add_f32 v3, v3, v14
	v_xor_b32_e32 v14, 8, v1
	ds_bpermute_b32 v15, v15, v3
	v_cmp_gt_i32_e32 vcc_lo, 32, v14
	s_wait_dscnt 0x0
	v_dual_cndmask_b32 v16, v1, v14 :: v_dual_add_f32 v3, v3, v15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v16, 2, v16
	ds_bpermute_b32 v16, v16, v3
	s_wait_dscnt 0x0
	v_dual_add_f32 v3, v3, v16 :: v_dual_bitop2_b32 v15, 4, v1 bitop3:0x14
	v_cmp_gt_i32_e32 vcc_lo, 32, v15
	v_dual_cndmask_b32 v17, v1, v15, vcc_lo :: v_dual_bitop2_b32 v16, 2, v1 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cmp_gt_i32_e32 vcc_lo, 32, v16
	v_dual_cndmask_b32 v18, v1, v16 :: v_dual_lshlrev_b32 v17, 2, v17
	ds_bpermute_b32 v17, v17, v3
	s_wait_dscnt 0x0
	v_dual_add_f32 v3, v3, v17 :: v_dual_lshlrev_b32 v18, 2, v18
	ds_bpermute_b32 v18, v18, v3
	s_wait_dscnt 0x0
	v_dual_add_f32 v18, v3, v18 :: v_dual_bitop2_b32 v17, 1, v1 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_gt_i32_e32 vcc_lo, 32, v17
	v_cndmask_b32_e32 v19, v1, v17, vcc_lo
	v_lshlrev_b32_e32 v3, 2, v19
	ds_bpermute_b32 v19, v3, v18
	v_mov_b32_e32 v3, 0
	s_wait_xcnt 0x0
	v_cmpx_eq_u32_e32 0, v20
	s_cbranch_execz .LBB5_2
; %bb.1:
	s_wait_dscnt 0x0
	v_dual_lshrrev_b32 v20, 3, v0 :: v_dual_add_f32 v18, v18, v19
	ds_store_b32 v20, v18
.LBB5_2:
	s_or_b32 exec_lo, exec_lo, s2
	v_and_b32_e32 v18, 16, v1
	v_and_b32_e32 v0, 15, v0
	s_wait_loadcnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_add_nc_u32_e32 v18, 16, v18
	s_mov_b32 s2, 0x39800000
	v_cvt_f32_fp8_e64 v19, v4 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_i32_e32 vcc_lo, v14, v18
	v_dual_lshlrev_b32 v0, 2, v0 :: v_dual_cndmask_b32 v14, v1, v14, vcc_lo
	ds_load_b32 v0, v0
	v_cmp_lt_i32_e32 vcc_lo, v15, v18
	v_lshlrev_b32_e32 v14, 2, v14
	s_wait_dscnt 0x0
	ds_bpermute_b32 v14, v14, v0
	v_cndmask_b32_e32 v15, v1, v15, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v16, v18
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_add_f32 v0, v0, v14 :: v_dual_lshlrev_b32 v15, 2, v15
	ds_bpermute_b32 v14, v15, v0
	v_cndmask_b32_e32 v15, v1, v16, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v17, v18
	v_cvt_f32_fp8_e32 v16, v5
	v_cvt_f32_fp8_e64 v18, v4 byte_sel:2
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_dual_cndmask_b32 v1, v1, v17, vcc_lo :: v_dual_lshlrev_b32 v15, 2, v15
	v_cvt_f32_fp8_e64 v17, v5 byte_sel:1
	s_wait_dscnt 0x0
	v_dual_add_f32 v0, v0, v14 :: v_dual_lshlrev_b32 v1, 2, v1
	ds_bpermute_b32 v14, v15, v0
	s_wait_dscnt 0x0
	v_add_f32_e32 v0, v0, v14
	ds_bpermute_b32 v1, v1, v0
	s_wait_dscnt 0x0
	v_add_f32_e32 v0, v0, v1
	v_cvt_f32_fp8_e64 v1, v5 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_fmaak_f32 v14, s2, v0, 0x358637bd
	v_cvt_f32_fp8_e64 v0, v5 byte_sel:2
	v_cvt_f32_fp8_e64 v5, v4 byte_sel:1
	v_cvt_f32_fp8_e32 v4, v4
	v_rsq_f32_e32 v14, v14
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[12:13], v[14:15], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[8:9], v[14:15], v[8:9] op_sel_hi:[0,1]
	v_pk_mul_f32 v[6:7], v[14:15], v[6:7] op_sel_hi:[0,1]
	v_pk_mul_f32 v[4:5], v[4:5], v[12:13]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[10:11], v[16:17], v[10:11]
	v_pk_mul_f32 v[8:9], v[18:19], v[8:9]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[0:1], v[0:1], v[6:7]
	v_cvt_pk_f16_f32 v4, v4, v5
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_pk_f16_f32 v6, v10, v11
	v_cvt_pk_f16_f32 v5, v8, v9
	s_delay_alu instid0(VALU_DEP_4)
	v_cvt_pk_f16_f32 v7, v0, v1
	v_lshl_add_u64 v[0:1], v[2:3], 4, s[0:1]
	global_store_b128 v[0:1], v[4:7], off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rmsnorm_f8
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
		.amdhsa_next_free_vgpr 21
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
.Lfunc_end5:
	.size	rmsnorm_f8, .Lfunc_end5-rmsnorm_f8
                                        ; -- End function
	.set rmsnorm_f8.num_vgpr, 21
	.set rmsnorm_f8.num_agpr, 0
	.set rmsnorm_f8.numbered_sgpr, 9
	.set rmsnorm_f8.num_named_barrier, 0
	.set rmsnorm_f8.private_seg_size, 0
	.set rmsnorm_f8.uses_vcc, 1
	.set rmsnorm_f8.uses_flat_scratch, 0
	.set rmsnorm_f8.has_dyn_sized_stack, 0
	.set rmsnorm_f8.has_recursion, 0
	.set rmsnorm_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 856
; TotalNumSgprs: 11
; NumVgprs: 21
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 64 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 11
; NumVGPRsForWavesPerEU: 21
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
	.protected	matvec_f8               ; -- Begin function matvec_f8
	.globl	matvec_f8
	.p2align	8
	.type	matvec_f8,@function
matvec_f8:                              ; @matvec_f8
; %bb.0:
	v_lshrrev_b32_e32 v1, 7, v0
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_dual_mov_b32 v14, v0 :: v_dual_add_nc_u32 v7, 0x380, v0
	v_dual_mov_b32 v11, 0 :: v_dual_add_nc_u32 v6, 0x300, v0
	v_sub_nc_u32_e32 v13, 32, v1
	v_add_nc_u32_e32 v1, 0x80, v0
	v_add_nc_u32_e32 v5, 0x280, v0
	v_add_nc_u32_e32 v4, 0x200, v0
	v_add_nc_u32_e32 v3, 0x180, v0
	v_and_b32_e32 v12, 56, v13
	v_add_nc_u32_e32 v2, 0x100, v0
	v_mov_b64_e32 v[8:9], v[6:7]
	v_mov_b64_e32 v[6:7], v[4:5]
	s_delay_alu instid0(VALU_DEP_3)
	v_mov_b64_e32 v[4:5], v[2:3]
	v_mov_b64_e32 v[2:3], v[0:1]
	v_mov_b32_e32 v15, v12
	s_wait_xcnt 0x0
	s_mov_b32 s0, 0
.LBB6_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v10, v2 :: v_dual_add_nc_u32 v15, -8, v15
	v_add_nc_u32_e32 v2, 0x400, v2
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[16:17], s[6:7], v[10:11]
	v_dual_mov_b32 v10, v3 :: v_dual_add_nc_u32 v3, 0x400, v3
	v_cmp_eq_u32_e32 vcc_lo, 0, v15
	s_delay_alu instid0(VALU_DEP_2)
	v_add_nc_u64_e32 v[18:19], s[6:7], v[10:11]
	v_mov_b32_e32 v10, v4
	v_add_nc_u32_e32 v4, 0x400, v4
	s_or_b32 s0, vcc_lo, s0
	s_clause 0x1
	global_load_u8 v1, v[16:17], off
	global_load_u8 v30, v[18:19], off
	v_add_nc_u64_e32 v[20:21], s[6:7], v[10:11]
	v_dual_mov_b32 v10, v5 :: v_dual_add_nc_u32 v5, 0x400, v5
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_nc_u64_e32 v[22:23], s[6:7], v[10:11]
	v_mov_b32_e32 v10, v6
	v_add_nc_u32_e32 v6, 0x400, v6
	v_add_nc_u64_e32 v[24:25], s[6:7], v[10:11]
	v_dual_mov_b32 v10, v7 :: v_dual_add_nc_u32 v7, 0x400, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_nc_u64_e32 v[26:27], s[6:7], v[10:11]
	v_mov_b32_e32 v10, v8
	v_add_nc_u32_e32 v8, 0x400, v8
	v_add_nc_u64_e32 v[28:29], s[6:7], v[10:11]
	v_dual_mov_b32 v10, v9 :: v_dual_add_nc_u32 v9, 0x400, v9
	s_wait_xcnt 0x1
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u64_e32 v[16:17], s[6:7], v[10:11]
	s_clause 0x5
	global_load_u8 v10, v[20:21], off
	global_load_u8 v18, v[22:23], off
	global_load_u8 v19, v[24:25], off
	global_load_u8 v31, v[26:27], off
	global_load_u8 v32, v[28:29], off
	global_load_u8 v33, v[16:17], off
	s_wait_loadcnt 0x7
	ds_store_b8 v14, v1
	s_wait_loadcnt 0x6
	ds_store_b8 v14, v30 offset:128
	s_wait_loadcnt 0x5
	ds_store_b8 v14, v10 offset:256
	s_wait_loadcnt 0x4
	ds_store_b8 v14, v18 offset:384
	s_wait_loadcnt 0x3
	ds_store_b8 v14, v19 offset:512
	s_wait_loadcnt 0x2
	ds_store_b8 v14, v31 offset:640
	s_wait_loadcnt 0x1
	ds_store_b8 v14, v32 offset:768
	s_wait_loadcnt 0x0
	ds_store_b8 v14, v33 offset:896
	v_add_nc_u32_e32 v14, 0x400, v14
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s0
	s_cbranch_execnz .LBB6_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s0, exec_lo
	v_cmpx_ne_u32_e64 v13, v12
	s_cbranch_execz .LBB6_5
; %bb.3:
	v_lshl_add_u32 v4, v12, 7, v0
	v_mov_b32_e32 v5, 0
	s_mov_b32 s1, 0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, 0xffffff80, v4
	v_add_nc_u64_e32 v[2:3], s[6:7], v[4:5]
.LBB6_4:                                ; =>This Inner Loop Header: Depth=1
	global_load_u8 v4, v[2:3], off
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 0x80, v[2:3]
	s_wait_loadcnt 0x0
	ds_store_b8 v1, v4 offset:128
	v_add_nc_u32_e32 v1, 0x80, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_cmp_lt_u32_e32 vcc_lo, 0xf7f, v1
	s_or_b32 s1, vcc_lo, s1
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB6_4
.LBB6_5:
	s_or_b32 exec_lo, exec_lo, s0
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_lshrrev_b32_e32 v4, 5, v0
	s_bfe_u32 s0, ttmp6, 0x4000c
	s_and_b32 s1, ttmp6, 15
	s_add_co_i32 s0, s0, 1
	v_xor_b32_e32 v2, 16, v1
	v_xor_b32_e32 v6, 1, v1
	s_mul_i32 s0, ttmp9, s0
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s1, s1, s0
	v_cmp_gt_i32_e32 vcc_lo, 32, v2
	s_cmp_eq_u32 s6, 0
	s_wait_dscnt 0x0
	s_cselect_b32 s0, ttmp9, s1
	s_barrier_signal -1
	v_dual_cndmask_b32 v2, v1, v2, vcc_lo :: v_dual_bitop2_b32 v3, 8, v1 bitop3:0x14
	v_and_b32_e32 v10, 31, v0
	s_lshl_b32 s1, s0, 18
	s_barrier_wait -1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_lshlrev_b32_e32 v5, 2, v2
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_xor_b32_e32 v0, 4, v1
	v_cndmask_b32_e32 v2, v1, v3, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v0
	v_dual_cndmask_b32 v7, v1, v0, vcc_lo :: v_dual_bitop2_b32 v3, 2, v1 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_dual_cndmask_b32 v3, v1, v3 :: v_dual_lshlrev_b32 v0, 12, v4
	v_cmp_gt_i32_e32 vcc_lo, 32, v6
	v_or3_b32 v0, v0, s1, v10
	s_mov_b32 s1, 0
	v_dual_cndmask_b32 v9, v1, v6, vcc_lo :: v_dual_mov_b32 v1, 0
	v_dual_lshlrev_b32 v6, 2, v2 :: v_dual_lshlrev_b32 v7, 2, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshlrev_b32 v8, 2, v3 :: v_dual_lshlrev_b32 v9, 2, v9
	v_add_nc_u64_e32 v[0:1], s[4:5], v[0:1]
	v_cmp_eq_u32_e32 vcc_lo, 0, v10
	v_or_b32_e32 v10, 0xffffffe0, v10
	s_lshl_b32 s4, s0, 6
	s_branch .LBB6_7
.LBB6_6:                                ;   in Loop: Header=BB6_7 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_add_nc_u32_e32 v2, 4, v4
	v_cmp_lt_u32_e64 s0, 59, v4
	v_add_nc_u64_e32 v[0:1], 0x4000, v[0:1]
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_mov_b32_e32 v4, v2
	s_or_b32 s1, s0, s1
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execz .LBB6_11
.LBB6_7:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB6_8 Depth 2
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2)
	v_mov_b64_e32 v[2:3], v[0:1]
	v_dual_mov_b32 v12, v10 :: v_dual_mov_b32 v11, 0
	s_mov_b32 s5, 0
.LBB6_8:                                ;   Parent Loop BB6_7 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u8 v13, v[2:3], off
	ds_load_u8 v14, v12 offset:32
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 32, v[2:3]
	s_wait_dscnt 0x0
	v_cvt_f32_fp8_e32 v14, v14
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v13, v13
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_fmac_f32 v11, v13, v14 :: v_dual_add_nc_u32 v12, 32, v12
	v_cmp_lt_u32_e64 s0, 0xfdf, v12
	s_or_b32 s5, s0, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s5
	s_cbranch_execnz .LBB6_8
; %bb.9:                                ;   in Loop: Header=BB6_7 Depth=1
	s_or_b32 exec_lo, exec_lo, s5
	ds_bpermute_b32 v2, v5, v11
	s_wait_dscnt 0x0
	v_add_f32_e32 v2, v11, v2
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
	s_cbranch_execz .LBB6_6
; %bb.10:                               ;   in Loop: Header=BB6_7 Depth=1
	s_wait_dscnt 0x0
	v_dual_add_f32 v2, v2, v3 :: v_dual_add_nc_u32 v3, s4, v4
	s_delay_alu instid0(VALU_DEP_1)
	v_cvt_f16_f32_e32 v2, v2
	global_store_b16 v3, v2, s[2:3] scale_offset
	s_branch .LBB6_6
.LBB6_11:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matvec_f8
		.amdhsa_group_segment_fixed_size 4096
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
		.amdhsa_next_free_vgpr 34
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
		.amdhsa_inst_pref_size 9
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
	.size	matvec_f8, .Lfunc_end6-matvec_f8
                                        ; -- End function
	.set matvec_f8.num_vgpr, 34
	.set matvec_f8.num_agpr, 0
	.set matvec_f8.numbered_sgpr, 8
	.set matvec_f8.num_named_barrier, 0
	.set matvec_f8.private_seg_size, 0
	.set matvec_f8.uses_vcc, 1
	.set matvec_f8.uses_flat_scratch, 0
	.set matvec_f8.has_dyn_sized_stack, 0
	.set matvec_f8.has_recursion, 0
	.set matvec_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1148
; TotalNumSgprs: 10
; NumVgprs: 34
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 34
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
	.protected	reduction_f8            ; -- Begin function reduction_f8
	.globl	reduction_f8
	.p2align	8
	.type	reduction_f8,@function
reduction_f8:                           ; @reduction_f8
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB7_6
; %bb.1:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_bfe_u32 s5, ttmp6, 0x4000c
	s_bfe_u32 s6, ttmp6, 0x40010
	s_add_co_i32 s5, s5, 1
	s_add_co_i32 s6, s6, 1
	s_and_b32 s4, ttmp6, 15
	s_bfe_u32 s7, ttmp6, 0x40004
	s_mul_i32 s5, ttmp9, s5
	s_mul_i32 s6, ttmp7, s6
	s_getreg_b32 s8, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s5, s4, s5
	s_add_co_i32 s4, s7, s6
	s_cmp_eq_u32 s8, 0
	s_mov_b32 s7, 0
	s_cselect_b32 s4, ttmp7, s4
	s_cselect_b32 s5, ttmp9, s5
	s_lshl_b32 s6, s4, 12
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[0:1], s[0:1], s[6:7]
	s_lshl_b32 s6, s5, 11
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_nc_u64 s[0:1], s[0:1], s[6:7]
	s_clause 0x3
	global_load_b128 v[6:9], v0, s[0:1] scale_offset
	global_load_b128 v[10:13], v0, s[0:1] offset:512 scale_offset
	global_load_b128 v[14:17], v0, s[0:1] offset:1024 scale_offset
	global_load_b128 v[2:5], v0, s[0:1] offset:1536 scale_offset
	s_wait_loadcnt 0x3
	v_cvt_f32_fp8_e32 v1, v6
	v_cvt_f32_fp8_e64 v18, v6 byte_sel:1
	v_cvt_f32_fp8_e64 v19, v6 byte_sel:2
	v_cvt_f32_fp8_e64 v6, v6 byte_sel:3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v1, 0, v1
	v_add_f32_e32 v1, v1, v18
	v_cvt_f32_fp8_e32 v18, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v1, v1, v19
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v7 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v18
	v_cvt_f32_fp8_e64 v18, v7 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v7 byte_sel:3
	v_cvt_f32_fp8_e32 v7, v8
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v1, v1, v18
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v8 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v8 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v8 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v9
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v9 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v9 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v9 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	s_wait_loadcnt 0x2
	v_cvt_f32_fp8_e32 v7, v10
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v10 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v10 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v10 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v11
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v11 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v11 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v11 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v12
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v12 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v12 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v12 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v13
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v13 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v13 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v13 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v7, v14
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v14 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v14 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v14 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v15
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v15 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v15 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v15 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v16
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v16 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v16 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v16 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e32 v7, v17
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v17 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v17 byte_sel:2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v17 byte_sel:3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v7
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v7, v2
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v2 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_add_f32_e32 v1, v1, v7
	v_cvt_f32_fp8_e64 v7, v2 byte_sel:2
	v_cvt_f32_fp8_e64 v2, v2 byte_sel:3
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e32 v6, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v1, v1, v7
	v_add_f32_e32 v1, v1, v2
	v_cvt_f32_fp8_e64 v2, v3 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v3 byte_sel:2
	v_add_f32_e32 v1, v1, v2
	v_cvt_f32_fp8_e64 v2, v3 byte_sel:3
	v_cvt_f32_fp8_e32 v3, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v6
	v_cvt_f32_fp8_e64 v6, v5 byte_sel:2
	v_add_f32_e32 v1, v1, v2
	v_cvt_f32_fp8_e64 v2, v4 byte_sel:1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v3
	v_cvt_f32_fp8_e64 v3, v4 byte_sel:2
	v_add_f32_e32 v1, v1, v2
	v_cvt_f32_fp8_e64 v2, v4 byte_sel:3
	v_cvt_f32_fp8_e64 v4, v5 byte_sel:1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v1, v1, v3
	v_cvt_f32_fp8_e32 v3, v5
	v_add_f32_e32 v1, v1, v2
	v_mbcnt_lo_u32_b32 v2, -1, 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_add_f32 v1, v1, v3 :: v_dual_bitop2_b32 v3, 16, v2 bitop3:0x14
	v_add_f32_e32 v1, v1, v4
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_cvt_f32_fp8_e64 v4, v5 byte_sel:3
	v_dual_add_f32 v1, v1, v6 :: v_dual_cndmask_b32 v3, v2, v3, vcc_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_f32 v1, v1, v4 :: v_dual_lshlrev_b32 v3, 2, v3
	v_xor_b32_e32 v4, 8, v2
	ds_bpermute_b32 v3, v3, v1
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v4, v2, v4, vcc_lo
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_dual_add_f32 v1, v1, v3 :: v_dual_lshlrev_b32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v1
	v_xor_b32_e32 v4, 4, v2
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v4, v2, v4, vcc_lo
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_dual_add_f32 v1, v1, v3 :: v_dual_lshlrev_b32 v4, 2, v4
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
	s_cbranch_execz .LBB7_6
; %bb.2:
	s_wait_dscnt 0x0
	v_add_f32_e32 v0, v1, v2
	s_mov_b32 s1, exec_lo
	s_brev_b32 s0, 1
.LBB7_3:                                ; =>This Inner Loop Header: Depth=1
	s_ctz_i32_b32 s5, s1
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_readlane_b32 s6, v0, s5
	s_lshl_b32 s5, 1, s5
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_not1_b32 s1, s1, s5
	s_cmp_lg_u32 s1, 0
	s_add_f32 s0, s0, s6
	s_cbranch_scc1 .LBB7_3
; %bb.4:
	v_mbcnt_lo_u32_b32 v0, exec_lo, 0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB7_6
; %bb.5:
	v_dual_mov_b32 v0, s4 :: v_dual_mov_b32 v1, s0
	global_atomic_add_f32 v0, v1, s[2:3] scale_offset scope:SCOPE_DEV
.LBB7_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel reduction_f8
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
		.amdhsa_next_free_vgpr 20
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
		.amdhsa_inst_pref_size 11
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
	.size	reduction_f8, .Lfunc_end7-reduction_f8
                                        ; -- End function
	.set reduction_f8.num_vgpr, 20
	.set reduction_f8.num_agpr, 0
	.set reduction_f8.numbered_sgpr, 9
	.set reduction_f8.num_named_barrier, 0
	.set reduction_f8.private_seg_size, 0
	.set reduction_f8.uses_vcc, 1
	.set reduction_f8.uses_flat_scratch, 0
	.set reduction_f8.has_dyn_sized_stack, 0
	.set reduction_f8.has_recursion, 0
	.set reduction_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1328
; TotalNumSgprs: 11
; NumVgprs: 20
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 11
; NumVGPRsForWavesPerEU: 20
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	softmax_f8              ; -- Begin function softmax_f8
	.globl	softmax_f8
	.p2align	8
	.type	softmax_f8,@function
softmax_f8:                             ; @softmax_f8
; %bb.0:
	s_load_b96 s[8:10], s[0:1], 0x10
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	v_bfe_u32 v1, v0, 10, 10
	s_mul_i32 s2, ttmp9, s2
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	s_add_co_i32 s3, s3, s2
	s_getreg_b32 s2, hwreg(HW_REG_IB_STS2, 6, 4)
	s_cmp_eq_u32 s2, 0
	s_cselect_b32 s2, ttmp9, s3
	s_mov_b32 s3, exec_lo
	v_lshl_add_u32 v8, s2, 2, v1
	s_mov_b32 s2, 0
	s_wait_kmcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e64 s10, v8
	s_cbranch_execz .LBB8_3
; %bb.1:
	s_load_b128 s[4:7], s[0:1], 0x0
	v_mbcnt_lo_u32_b32 v6, -1, 0
	v_and_b32_e32 v3, 0x3ff, v0
	v_mov_b32_e32 v1, 0
	s_wait_xcnt 0x0
	s_load_b32 s1, s[0:1], 0x20
	v_mul_lo_u32 v2, s9, v8
	v_xor_b32_e32 v5, 8, v6
	v_dual_lshlrev_b32 v0, 3, v3 :: v_dual_bitop2_b32 v4, 16, v6 bitop3:0x14
	v_xor_b32_e32 v7, 4, v6
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_cndmask_b32_e32 v11, v6, v4, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v5
	v_cndmask_b32_e32 v12, v6, v5, vcc_lo
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[4:5], s[6:7], v[0:1]
	v_lshlrev_b32_e32 v0, 4, v3
	v_cmp_gt_i32_e32 vcc_lo, 32, v7
	v_xor_b32_e32 v9, 2, v6
	s_mul_i32 s3, s1, s9
	s_lshl_b32 s0, s1, 2
	v_cndmask_b32_e32 v13, v6, v7, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_gt_i32_e32 vcc_lo, 32, v9
	v_dual_cndmask_b32 v3, v6, v9, vcc_lo :: v_dual_bitop2_b32 v10, 1, v6 bitop3:0x14
	v_cmp_gt_i32_e32 vcc_lo, 32, v10
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_4) | instid1(VALU_DEP_4)
	v_dual_lshlrev_b32 v9, 2, v11 :: v_dual_lshlrev_b32 v11, 2, v13
	v_cndmask_b32_e32 v14, v6, v10, vcc_lo
	v_add_nc_u64_e32 v[6:7], s[4:5], v[0:1]
	v_mul_lo_u32 v0, s8, v8
	v_dual_lshlrev_b32 v10, 2, v12 :: v_dual_lshlrev_b32 v12, 2, v3
	v_lshlrev_b32_e32 v13, 2, v14
	s_mul_i32 s4, s1, s8
	s_lshl_b32 s1, s3, 2
	s_lshl_b32 s3, s4, 2
.LBB8_2:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_add_nc_u64_e32 v[14:15], v[4:5], v[0:1]
	v_add_nc_u32_e32 v8, s0, v8
	v_add_nc_u32_e32 v0, s3, v0
	v_cmp_le_u32_e32 vcc_lo, s10, v8
	global_load_b64 v[14:15], v[14:15], off
	s_or_b32 s2, vcc_lo, s2
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e64 v3, v14 byte_sel:1
	v_cvt_f32_fp8_e32 v16, v14
	v_cvt_f32_fp8_e64 v19, v14 byte_sel:2
	s_wait_xcnt 0x0
	v_cvt_f32_fp8_e64 v14, v14 byte_sel:3
	v_cvt_f32_fp8_e64 v20, v15 byte_sel:1
	v_dual_max_num_f32 v17, v3, v3 :: v_dual_max_num_f32 v18, v16, v16
	v_cvt_f32_fp8_e64 v21, v15 byte_sel:2
	v_cvt_f32_fp8_e64 v22, v15 byte_sel:3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_max_num_f32_e32 v17, v18, v17
	v_cvt_f32_fp8_e32 v18, v15
	v_max3_num_f32 v17, v17, v19, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max3_num_f32 v15, v17, v18, v20
	v_max3_num_f32 v15, v15, v21, v22
	ds_bpermute_b32 v17, v9, v15
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v17, v17, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v15, v15, v17
	ds_bpermute_b32 v17, v10, v15
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v17, v17, v17
	v_max_num_f32_e32 v15, v15, v17
	ds_bpermute_b32 v17, v11, v15
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v17, v17, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v15, v15, v17
	ds_bpermute_b32 v17, v12, v15
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v17, v17, v17
	v_max_num_f32_e32 v15, v15, v17
	ds_bpermute_b32 v17, v13, v15
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v17, v17, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v23, v15, v17
	v_dual_sub_f32 v15, v16, v23 :: v_dual_sub_f32 v16, v19, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_dual_mul_f32 v16, 0x3fb8aa3b, v16 :: v_dual_sub_f32 v3, v3, v23
	v_dual_sub_f32 v19, v20, v23 :: v_dual_sub_f32 v20, v22, v23
	v_mul_f32_e32 v15, 0x3fb8aa3b, v15
	v_sub_f32_e32 v17, v18, v23
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mul_f32 v3, 0x3fb8aa3b, v3 :: v_dual_mul_f32 v20, 0x3fb8aa3b, v20
	v_exp_f32_e32 v24, v15
	v_nop
	v_sub_f32_e32 v15, v14, v23
	s_delay_alu instid0(VALU_DEP_3)
	v_exp_f32_e32 v14, v3
	v_mul_f32_e32 v17, 0x3fb8aa3b, v17
	s_delay_alu instid0(TRANS32_DEP_2) | instid1(VALU_DEP_2)
	v_dual_add_f32 v3, 0, v24 :: v_dual_mul_f32 v18, 0x3fb8aa3b, v15
	v_exp_f32_e32 v15, v16
	s_delay_alu instid0(VALU_DEP_2)
	v_exp_f32_e32 v17, v17
	s_delay_alu instid0(TRANS32_DEP_3) | instid1(VALU_DEP_1)
	v_add_f32_e32 v3, v3, v14
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_3)
	v_exp_f32_e32 v16, v18
	v_nop
	v_sub_f32_e32 v18, v21, v23
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	v_add_f32_e32 v3, v3, v15
	v_mul_f32_e32 v21, 0x3fb8aa3b, v18
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v18, v19
	v_add_f32_e32 v3, v3, v16
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v19, v21
	v_exp_f32_e32 v21, v20
	v_add_f32_e32 v3, v3, v17
	s_delay_alu instid0(TRANS32_DEP_3) | instid1(VALU_DEP_1)
	v_add_f32_e32 v3, v3, v18
	s_delay_alu instid0(TRANS32_DEP_2) | instid1(VALU_DEP_1)
	v_add_f32_e32 v3, v3, v19
	s_delay_alu instid0(TRANS32_DEP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v3, v3, v21
	ds_bpermute_b32 v20, v9, v3
	s_wait_dscnt 0x0
	v_add_f32_e32 v3, v3, v20
	ds_bpermute_b32 v20, v10, v3
	s_wait_dscnt 0x0
	v_add_f32_e32 v3, v3, v20
	ds_bpermute_b32 v20, v11, v3
	s_wait_dscnt 0x0
	v_add_f32_e32 v3, v3, v20
	ds_bpermute_b32 v20, v12, v3
	s_wait_dscnt 0x0
	v_add_f32_e32 v3, v3, v20
	ds_bpermute_b32 v20, v13, v3
	s_wait_dscnt 0x0
	v_add_f32_e32 v3, v3, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v20, v3
	v_nop
	v_mov_b32_e32 v3, v1
	v_lshl_add_u64 v[22:23], v[2:3], 1, v[6:7]
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[18:19], v[20:21], v[18:19] op_sel_hi:[0,1]
	v_pk_mul_f32 v[14:15], v[20:21], v[14:15] op_sel_hi:[0,1]
	v_pk_mul_f32 v[16:17], v[20:21], v[16:17] op_sel_hi:[0,1]
	v_add_nc_u32_e32 v2, s1, v2
	v_cvt_pk_f16_f32 v3, v18, v19
	v_fma_mixlo_f16 v18, v20, v24, 0
	v_cvt_pk_f16_f32 v15, v14, v15
	v_cvt_pk_f16_f32 v16, v16, v17
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_lshrrev_b32_e32 v17, 16, v3
	v_pack_b32_f16 v14, v18, v15
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_alignbit_b32 v15, v16, v15, 16
	v_alignbit_b32 v16, v3, v16, 16
	v_fma_mixhi_f16 v17, v20, v21, 0
	global_store_b128 v[22:23], v[14:17], off
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB8_2
.LBB8_3:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel softmax_f8
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
		.amdhsa_system_vgpr_workitem_id 1
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
.Lfunc_end8:
	.size	softmax_f8, .Lfunc_end8-softmax_f8
                                        ; -- End function
	.set softmax_f8.num_vgpr, 25
	.set softmax_f8.num_agpr, 0
	.set softmax_f8.numbered_sgpr, 11
	.set softmax_f8.num_named_barrier, 0
	.set softmax_f8.private_seg_size, 0
	.set softmax_f8.uses_vcc, 1
	.set softmax_f8.uses_flat_scratch, 0
	.set softmax_f8.has_dyn_sized_stack, 0
	.set softmax_f8.has_recursion, 0
	.set softmax_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1004
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
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 1
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_b1efe11a353308b4,@object ; @__hip_cuid_b1efe11a353308b4
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_b1efe11a353308b4
__hip_cuid_b1efe11a353308b4:
	.byte	0                               ; 0x0
	.size	__hip_cuid_b1efe11a353308b4, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_b1efe11a353308b4
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
    .name:           relu_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     7
    .sgpr_spill_count: 0
    .symbol:         relu_f8.kd
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
    .name:           silu_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     7
    .sgpr_spill_count: 0
    .symbol:         silu_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     9
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
    .name:           sigmoid_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     7
    .sgpr_spill_count: 0
    .symbol:         sigmoid_f8.kd
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
    .name:           swiglu_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         swiglu_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     13
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
    .name:           rope_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         rope_f8.kd
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
    .name:           rmsnorm_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     11
    .sgpr_spill_count: 0
    .symbol:         rmsnorm_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     21
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
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           matvec_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matvec_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     34
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
    .name:           reduction_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     11
    .sgpr_spill_count: 0
    .symbol:         reduction_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     20
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
    .name:           softmax_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     13
    .sgpr_spill_count: 0
    .symbol:         softmax_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     25
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
