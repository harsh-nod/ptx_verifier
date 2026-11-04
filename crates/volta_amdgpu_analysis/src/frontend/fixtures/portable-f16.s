	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	relu_f16                ; -- Begin function relu_f16
	.globl	relu_f16
	.p2align	8
	.type	relu_f16,@function
relu_f16:                               ; @relu_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	v_lshl_add_u32 v0, s2, 7, v0
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[4:5], 4, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[4:5]
	global_load_dwordx4 v[0:3], v[0:1], off
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[4:5]
	s_waitcnt vmcnt(0)
	v_pk_max_f16 v3, v3, 0
	v_pk_max_f16 v2, v2, 0
	v_pk_max_f16 v1, v1, 0
	v_pk_max_f16 v0, v0, 0
	global_store_dwordx4 v[4:5], v[0:3], off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set relu_f16.numbered_sgpr, 8
	.set relu_f16.num_named_barrier, 0
	.set relu_f16.private_seg_size, 0
	.set relu_f16.uses_vcc, 0
	.set relu_f16.uses_flat_scratch, 0
	.set relu_f16.has_dyn_sized_stack, 0
	.set relu_f16.has_recursion, 0
	.set relu_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 104
; TotalNumSgprs: 14
; NumVgprs: 6
; NumAgprs: 0
; TotalNumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 6
; AccumOffset: 8
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 1
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	silu_f16                ; -- Begin function silu_f16
	.globl	silu_f16
	.p2align	8
	.type	silu_f16,@function
silu_f16:                               ; @silu_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	v_lshl_add_u32 v0, s2, 7, v0
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[0:1], 3, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
	global_load_dwordx2 v[2:3], v[2:3], off
	v_lshl_add_u64 v[0:1], s[6:7], 0, v[0:1]
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v4, v2
	v_cvt_f32_f16_sdwa v5, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v2, v3
	v_cvt_f32_f16_sdwa v3, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_mul_f32_e32 v6, 0xbfb8aa3b, v4
	v_mul_f32_e32 v7, 0xbfb8aa3b, v5
	v_mul_f32_e32 v8, 0xbfb8aa3b, v2
	v_mul_f32_e32 v9, 0xbfb8aa3b, v3
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_exp_f32_e32 v8, v8
	v_exp_f32_e32 v9, v9
	v_add_f32_e32 v6, 1.0, v6
	v_add_f32_e32 v7, 1.0, v7
	v_add_f32_e32 v8, 1.0, v8
	v_add_f32_e32 v9, 1.0, v9
	v_rcp_f32_e32 v6, v6
	v_rcp_f32_e32 v7, v7
	v_rcp_f32_e32 v8, v8
	v_rcp_f32_e32 v9, v9
	v_pk_mul_f32 v[4:5], v[6:7], v[4:5]
	s_nop 0
	v_cvt_pk_f16_f32 v4, v4, v5
	v_pk_mul_f32 v[2:3], v[8:9], v[2:3]
	s_nop 0
	v_cvt_pk_f16_f32 v5, v2, v3
	global_store_dwordx2 v[0:1], v[4:5], off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 10
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 12
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set silu_f16.numbered_sgpr, 8
	.set silu_f16.num_named_barrier, 0
	.set silu_f16.private_seg_size, 0
	.set silu_f16.uses_vcc, 0
	.set silu_f16.uses_flat_scratch, 0
	.set silu_f16.has_dyn_sized_stack, 0
	.set silu_f16.has_recursion, 0
	.set silu_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 216
; TotalNumSgprs: 14
; NumVgprs: 10
; NumAgprs: 0
; TotalNumVgprs: 10
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 10
; AccumOffset: 12
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 2
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	sigmoid_f16             ; -- Begin function sigmoid_f16
	.globl	sigmoid_f16
	.p2align	8
	.type	sigmoid_f16,@function
sigmoid_f16:                            ; @sigmoid_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	v_lshl_add_u32 v0, s2, 8, v0
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[0:1], 3, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
	global_load_dwordx2 v[2:3], v[2:3], off
	v_lshl_add_u64 v[0:1], s[6:7], 0, v[0:1]
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v4, v2
	v_cvt_f32_f16_sdwa v2, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v5, v3
	v_cvt_f32_f16_sdwa v3, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_mul_f32_e32 v4, 0xbfb8aa3b, v4
	v_mul_f32_e32 v2, 0xbfb8aa3b, v2
	v_mul_f32_e32 v5, 0xbfb8aa3b, v5
	v_mul_f32_e32 v3, 0xbfb8aa3b, v3
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v2, v2
	v_exp_f32_e32 v5, v5
	v_exp_f32_e32 v3, v3
	v_add_f32_e32 v4, 1.0, v4
	v_add_f32_e32 v2, 1.0, v2
	v_add_f32_e32 v5, 1.0, v5
	v_add_f32_e32 v3, 1.0, v3
	v_rcp_f32_e32 v4, v4
	v_rcp_f32_e32 v5, v5
	v_rcp_f32_e32 v3, v3
	v_rcp_f32_e32 v2, v2
	v_cvt_pk_f16_f32 v3, v5, v3
	v_cvt_pk_f16_f32 v2, v4, v2
	global_store_dwordx2 v[0:1], v[2:3], off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set sigmoid_f16.num_vgpr, 6
	.set sigmoid_f16.num_agpr, 0
	.set sigmoid_f16.numbered_sgpr, 8
	.set sigmoid_f16.num_named_barrier, 0
	.set sigmoid_f16.private_seg_size, 0
	.set sigmoid_f16.uses_vcc, 0
	.set sigmoid_f16.uses_flat_scratch, 0
	.set sigmoid_f16.has_dyn_sized_stack, 0
	.set sigmoid_f16.has_recursion, 0
	.set sigmoid_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 192
; TotalNumSgprs: 14
; NumVgprs: 6
; NumAgprs: 0
; TotalNumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 6
; AccumOffset: 8
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 1
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	swiglu_f16              ; -- Begin function swiglu_f16
	.globl	swiglu_f16
	.p2align	8
	.type	swiglu_f16,@function
swiglu_f16:                             ; @swiglu_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_load_dwordx2 s[4:5], s[0:1], 0x10
	v_lshl_add_u32 v0, s2, 7, v0
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[0:1], 4, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[8:9], 0, v[0:1]
	v_lshl_add_u64 v[6:7], s[10:11], 0, v[0:1]
	global_load_dwordx4 v[2:5], v[2:3], off
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[0:1]
	global_load_dwordx4 v[6:9], v[6:7], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v10, v2
	v_cvt_f32_f16_sdwa v11, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v12, v6
	v_cvt_f32_f16_sdwa v13, v6 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v2, v3
	v_cvt_f32_f16_sdwa v3, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v6, v7
	v_cvt_f32_f16_sdwa v7, v7 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v14, v4
	v_cvt_f32_f16_sdwa v15, v4 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v16, v8
	v_cvt_f32_f16_sdwa v17, v8 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v4, v5
	v_cvt_f32_f16_sdwa v5, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v8, v9
	v_cvt_f32_f16_sdwa v9, v9 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_mul_f32_e32 v18, 0xbfb8aa3b, v10
	v_mul_f32_e32 v19, 0xbfb8aa3b, v11
	v_pk_mul_f32 v[10:11], v[12:13], v[10:11]
	v_mul_f32_e32 v12, 0xbfb8aa3b, v2
	v_mul_f32_e32 v13, 0xbfb8aa3b, v3
	v_pk_mul_f32 v[2:3], v[6:7], v[2:3]
	v_mul_f32_e32 v20, 0xbfb8aa3b, v14
	v_mul_f32_e32 v21, 0xbfb8aa3b, v15
	v_pk_mul_f32 v[6:7], v[16:17], v[14:15]
	v_mul_f32_e32 v14, 0xbfb8aa3b, v4
	v_mul_f32_e32 v15, 0xbfb8aa3b, v5
	v_pk_mul_f32 v[4:5], v[8:9], v[4:5]
	v_exp_f32_e32 v8, v18
	v_exp_f32_e32 v9, v19
	v_exp_f32_e32 v12, v12
	v_exp_f32_e32 v13, v13
	v_exp_f32_e32 v16, v20
	v_exp_f32_e32 v17, v21
	v_exp_f32_e32 v14, v14
	v_exp_f32_e32 v15, v15
	v_add_f32_e32 v8, 1.0, v8
	v_add_f32_e32 v9, 1.0, v9
	v_add_f32_e32 v12, 1.0, v12
	v_add_f32_e32 v13, 1.0, v13
	v_add_f32_e32 v16, 1.0, v16
	v_add_f32_e32 v17, 1.0, v17
	v_add_f32_e32 v18, 1.0, v14
	v_add_f32_e32 v19, 1.0, v15
	v_rcp_f32_e32 v8, v8
	v_rcp_f32_e32 v9, v9
	v_rcp_f32_e32 v12, v12
	v_rcp_f32_e32 v13, v13
	v_rcp_f32_e32 v14, v16
	v_rcp_f32_e32 v15, v17
	v_rcp_f32_e32 v16, v18
	v_rcp_f32_e32 v17, v19
	v_pk_mul_f32 v[8:9], v[10:11], v[8:9]
	v_pk_mul_f32 v[10:11], v[2:3], v[12:13]
	v_pk_mul_f32 v[6:7], v[6:7], v[14:15]
	v_pk_mul_f32 v[12:13], v[4:5], v[16:17]
	v_cvt_pk_f16_f32 v2, v8, v9
	v_cvt_pk_f16_f32 v3, v10, v11
	v_cvt_pk_f16_f32 v4, v6, v7
	v_cvt_pk_f16_f32 v5, v12, v13
	global_store_dwordx4 v[0:1], v[2:5], off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 22
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 24
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set swiglu_f16.num_vgpr, 22
	.set swiglu_f16.num_agpr, 0
	.set swiglu_f16.numbered_sgpr, 12
	.set swiglu_f16.num_named_barrier, 0
	.set swiglu_f16.private_seg_size, 0
	.set swiglu_f16.uses_vcc, 0
	.set swiglu_f16.uses_flat_scratch, 0
	.set swiglu_f16.has_dyn_sized_stack, 0
	.set swiglu_f16.has_recursion, 0
	.set swiglu_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 452
; TotalNumSgprs: 18
; NumVgprs: 22
; NumAgprs: 0
; TotalNumVgprs: 22
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 22
; AccumOffset: 24
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 5
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	rope_f16                ; -- Begin function rope_f16
	.globl	rope_f16
	.p2align	8
	.type	rope_f16,@function
rope_f16:                               ; @rope_f16
; %bb.0:                                ; %entry
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	v_lshrrev_b32_e32 v1, 1, v0
	v_and_b32_e32 v6, 1, v0
	v_lshl_or_b32 v0, v6, 6, v1
	v_lshl_add_u32 v0, s2, 7, v0
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[2:3], 1, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	global_load_ushort v1, v[4:5], off
	v_and_b32_e32 v0, 0x7fff, v0
	v_lshlrev_b32_e32 v0, 1, v0
	global_load_ushort v4, v0, s[6:7]
	global_load_ushort v5, v0, s[8:9]
	v_mbcnt_lo_u32_b32 v0, -1, 0
	v_mbcnt_hi_u32_b32 v0, -1, v0
	v_and_b32_e32 v8, 64, v0
	v_xor_b32_e32 v7, 1, v0
	v_add_u32_e32 v8, 64, v8
	v_cmp_lt_i32_e32 vcc, v7, v8
	s_waitcnt vmcnt(2)
	v_cvt_f32_f16_e32 v1, v1
	v_cndmask_b32_e32 v0, v0, v7, vcc
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v4, v4
	ds_bpermute_b32 v0, v0, v1
	v_cmp_eq_u32_e32 vcc, 0, v6
	v_mul_f32_e32 v1, v4, v1
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e64 v0, v0, -v0, vcc
	s_waitcnt vmcnt(0)
	v_fma_mixlo_f16 v4, v0, v5, v1 op_sel_hi:[0,1,0]
	v_lshl_add_u64 v[0:1], s[10:11], 0, v[2:3]
	global_store_short v[0:1], v4, off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 9
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 12
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set rope_f16.num_vgpr, 9
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
; codeLenInByte = 208
; TotalNumSgprs: 18
; NumVgprs: 9
; NumAgprs: 0
; TotalNumVgprs: 9
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 9
; AccumOffset: 12
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 2
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	reduction_f16           ; -- Begin function reduction_f16
	.globl	reduction_f16
	.p2align	8
	.type	reduction_f16,@function
reduction_f16:                          ; @reduction_f16
; %bb.0:                                ; %entry
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB5_6
; %bb.1:                                ; %if.end
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_lshl_b32 s0, s3, 9
	s_lshl_b32 s1, s2, 5
	s_add_i32 s0, s0, s1
	v_or_b32_e32 v4, s0, v0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v2, s4
	v_mov_b32_e32 v3, s5
	v_mov_b32_e32 v5, 0
	v_lshl_add_u64 v[2:3], v[4:5], 4, v[2:3]
	global_load_dwordx4 v[2:5], v[2:3], off
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_mbcnt_hi_u32_b32 v1, -1, v1
	v_and_b32_e32 v6, 0x60, v1
	v_xor_b32_e32 v7, 16, v1
	v_add_u32_e32 v6, 32, v6
	v_cmp_lt_i32_e32 vcc, v7, v6
	s_mov_b32 s8, s3
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v8, v2
	v_cvt_f32_f16_sdwa v2, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v9, v3
	v_cvt_f32_f16_sdwa v3, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v10, v4
	v_cvt_f32_f16_sdwa v4, v4 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_add_f32_e32 v2, v8, v2
	v_cvt_f32_f16_e32 v11, v5
	v_add_f32_e32 v2, v2, v9
	v_cvt_f32_f16_sdwa v5, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_add_f32_e32 v2, v2, v3
	v_add_f32_e32 v2, v2, v10
	v_add_f32_e32 v2, v2, v4
	v_cndmask_b32_e32 v7, v1, v7, vcc
	v_add_f32_e32 v2, v2, v11
	v_lshlrev_b32_e32 v7, 2, v7
	v_add_f32_e32 v2, v2, v5
	ds_bpermute_b32 v3, v7, v2
	v_xor_b32_e32 v4, 8, v1
	v_cmp_lt_i32_e32 vcc, v4, v6
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v2, v3
	v_cndmask_b32_e32 v4, v1, v4, vcc
	v_lshlrev_b32_e32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v2
	v_xor_b32_e32 v4, 4, v1
	v_cmp_lt_i32_e32 vcc, v4, v6
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v2, v3
	v_cndmask_b32_e32 v4, v1, v4, vcc
	v_lshlrev_b32_e32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v2
	v_xor_b32_e32 v4, 2, v1
	v_cmp_lt_i32_e32 vcc, v4, v6
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v2, v3
	v_cndmask_b32_e32 v4, v1, v4, vcc
	v_lshlrev_b32_e32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v2
	v_xor_b32_e32 v4, 1, v1
	v_cmp_lt_i32_e32 vcc, v4, v6
	s_nop 1
	v_cndmask_b32_e32 v4, v1, v4, vcc
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v2, v3
	v_lshlrev_b32_e32 v2, 2, v4
	ds_bpermute_b32 v2, v2, v1
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB5_6
; %bb.2:                                ; %if.then11
	s_mov_b64 s[0:1], exec
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	v_bfrev_b32_e32 v0, 1
.LBB5_3:                                ; %ComputeLoop
                                        ; =>This Inner Loop Header: Depth=1
	s_ff1_i32_b64 s2, s[0:1]
	v_readlane_b32 s4, v1, s2
	s_lshl_b64 s[2:3], 1, s2
	s_andn2_b64 s[0:1], s[0:1], s[2:3]
	s_cmp_lg_u64 s[0:1], 0
	v_add_f32_e32 v0, s4, v0
	s_cbranch_scc1 .LBB5_3
; %bb.4:                                ; %ComputeEnd
	v_mbcnt_lo_u32_b32 v1, exec_lo, 0
	v_mbcnt_hi_u32_b32 v1, exec_hi, v1
	s_mov_b32 s9, 0
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[0:1], vcc
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB5_6
; %bb.5:
	s_lshl_b64 s[0:1], s[8:9], 2
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s7, s1
	v_mov_b32_e32 v1, 0
	global_atomic_add_f32 v1, v0, s[0:1]
.LBB5_6:                                ; %cleanup
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 10
		.amdhsa_accum_offset 12
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set reduction_f16.num_vgpr, 12
	.set reduction_f16.num_agpr, 0
	.set reduction_f16.numbered_sgpr, 10
	.set reduction_f16.num_named_barrier, 0
	.set reduction_f16.private_seg_size, 0
	.set reduction_f16.uses_vcc, 1
	.set reduction_f16.uses_flat_scratch, 0
	.set reduction_f16.has_dyn_sized_stack, 0
	.set reduction_f16.has_recursion, 0
	.set reduction_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 460
; TotalNumSgprs: 16
; NumVgprs: 12
; NumAgprs: 0
; TotalNumVgprs: 12
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 16
; NumVGPRsForWavesPerEU: 12
; AccumOffset: 12
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 2
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	softmax_f16             ; -- Begin function softmax_f16
	.globl	softmax_f16
	.p2align	8
	.type	softmax_f16,@function
softmax_f16:                            ; @softmax_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x10
	v_lshrrev_b32_e32 v1, 5, v0
	v_lshl_add_u32 v12, s2, 2, v1
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_u32_e32 vcc, s6, v12
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB6_3
; %bb.1:                                ; %for.body.lr.ph
	v_lshlrev_b32_e32 v0, 4, v0
	v_and_b32_e32 v4, 0x1f0, v0
	v_mbcnt_lo_u32_b32 v0, -1, 0
	v_mbcnt_hi_u32_b32 v0, -1, v0
	v_and_b32_e32 v1, 0x60, v0
	v_add_u32_e32 v1, 32, v1
	v_xor_b32_e32 v2, 16, v0
	v_cmp_lt_i32_e32 vcc, v2, v1
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	v_mov_b32_e32 v5, 0
	v_cndmask_b32_e32 v2, v0, v2, vcc
	v_lshlrev_b32_e32 v13, 2, v2
	v_xor_b32_e32 v2, 8, v0
	v_cmp_lt_i32_e32 vcc, v2, v1
	s_load_dword s0, s[0:1], 0x20
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[6:7], s[10:11], 0, v[4:5]
	v_cndmask_b32_e32 v2, v0, v2, vcc
	v_lshlrev_b32_e32 v14, 2, v2
	v_xor_b32_e32 v2, 4, v0
	v_cmp_lt_i32_e32 vcc, v2, v1
	s_lshl_b32 s2, s0, 2
	s_mul_i32 s1, s0, s5
	v_cndmask_b32_e32 v2, v0, v2, vcc
	v_lshlrev_b32_e32 v15, 2, v2
	v_xor_b32_e32 v2, 2, v0
	v_cmp_lt_i32_e32 vcc, v2, v1
	s_mul_i32 s0, s0, s4
	v_lshl_add_u64 v[8:9], s[8:9], 0, v[4:5]
	v_cndmask_b32_e32 v2, v0, v2, vcc
	v_lshlrev_b32_e32 v16, 2, v2
	v_xor_b32_e32 v2, 1, v0
	v_cmp_lt_i32_e32 vcc, v2, v1
	v_mul_lo_u32 v10, s5, v12
	s_lshl_b32 s3, s1, 2
	v_cndmask_b32_e32 v0, v0, v2, vcc
	v_lshlrev_b32_e32 v17, 2, v0
	v_mul_lo_u32 v4, s4, v12
	s_lshl_b32 s4, s0, 2
	s_mov_b64 s[0:1], 0
.LBB6_2:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[0:1], v[4:5], 1, v[6:7]
	global_load_dwordx4 v[0:3], v[0:1], off
	v_mov_b32_e32 v11, v5
	v_lshl_add_u64 v[18:19], v[10:11], 1, v[8:9]
	v_add_u32_e32 v12, s2, v12
	v_cmp_le_u32_e32 vcc, s6, v12
	v_add_u32_e32 v4, s4, v4
	v_add_u32_e32 v10, s3, v10
	s_or_b64 s[0:1], vcc, s[0:1]
	s_waitcnt vmcnt(0)
	v_max_f16_sdwa v11, v0, v0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_1
	v_lshrrev_b32_e32 v20, 16, v1
	v_lshrrev_b32_e32 v21, 16, v2
	v_max3_f16 v11, v11, v1, v20
	v_lshrrev_b32_e32 v22, 16, v3
	v_max3_f16 v11, v11, v2, v21
	v_max3_f16 v11, v11, v3, v22
	v_cvt_f32_f16_e32 v11, v11
	ds_bpermute_b32 v23, v13, v11
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v11, v11, v23
	ds_bpermute_b32 v23, v14, v11
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v11, v11, v23
	ds_bpermute_b32 v23, v15, v11
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v11, v11, v23
	ds_bpermute_b32 v23, v16, v11
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v11, v11, v23
	ds_bpermute_b32 v23, v17, v11
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v11, v11, v23
	v_cvt_f16_f32_e32 v11, v11
	v_sub_f16_e32 v23, v0, v11
	v_sub_f16_sdwa v0, v0, v11 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1 src1_sel:DWORD
	v_sub_f16_e32 v1, v1, v11
	v_sub_f16_e32 v20, v20, v11
	v_sub_f16_e32 v2, v2, v11
	v_sub_f16_e32 v21, v21, v11
	v_sub_f16_e32 v3, v3, v11
	v_sub_f16_e32 v11, v22, v11
	v_cvt_f32_f16_e32 v22, v23
	v_cvt_f32_f16_e32 v0, v0
	v_cvt_f32_f16_e32 v1, v1
	v_cvt_f32_f16_e32 v20, v20
	v_cvt_f32_f16_e32 v2, v2
	v_cvt_f32_f16_e32 v21, v21
	v_cvt_f32_f16_e32 v3, v3
	v_mul_f32_e32 v22, 0x3fb8aa3b, v22
	v_mul_f32_e32 v0, 0x3fb8aa3b, v0
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_exp_f32_e32 v25, v22
	v_exp_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v11, v11
	v_mul_f32_e32 v20, 0x3fb8aa3b, v20
	v_exp_f32_e32 v1, v1
	v_mul_f32_e32 v23, 0x3fb8aa3b, v2
	v_exp_f32_e32 v2, v20
	v_mul_f32_e32 v21, 0x3fb8aa3b, v21
	v_mul_f32_e32 v24, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v23
	v_exp_f32_e32 v20, v21
	v_add_f32_e32 v22, v0, v25
	v_mul_f32_e32 v11, 0x3fb8aa3b, v11
	v_exp_f32_e32 v21, v24
	v_add_f32_e32 v22, v1, v22
	v_exp_f32_e32 v11, v11
	v_add_f32_e32 v22, v2, v22
	v_add_f32_e32 v22, v3, v22
	v_add_f32_e32 v22, v20, v22
	v_add_f32_e32 v22, v21, v22
	v_add_f32_e32 v22, v11, v22
	ds_bpermute_b32 v23, v13, v22
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v22, v22, v23
	ds_bpermute_b32 v23, v14, v22
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v22, v22, v23
	ds_bpermute_b32 v23, v15, v22
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v22, v22, v23
	ds_bpermute_b32 v23, v16, v22
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v22, v22, v23
	ds_bpermute_b32 v23, v17, v22
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v22, v22, v23
	v_rcp_f32_e32 v22, v22
	s_nop 0
	v_fma_mixlo_f16 v23, v25, v22, 0
	v_pk_mul_f32 v[0:1], v[0:1], v[22:23] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[22:23] op_sel_hi:[1,0]
	v_pk_mul_f32 v[20:21], v[20:21], v[22:23] op_sel_hi:[1,0]
	v_cvt_pk_f16_f32 v1, v0, v1
	v_cvt_pk_f16_f32 v2, v2, v3
	v_cvt_pk_f16_f32 v3, v20, v21
	v_pack_b32_f16 v0, v23, v1
	v_alignbit_b32 v1, v2, v1, 16
	v_alignbit_b32 v2, v3, v2, 16
	v_lshrrev_b32_e32 v3, 16, v3
	v_fma_mixhi_f16 v3, v11, v22, 0
	global_store_dwordx4 v[18:19], v[0:3], off
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB6_2
.LBB6_3:                                ; %Flow127
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 26
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 28
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set softmax_f16.num_vgpr, 26
	.set softmax_f16.num_agpr, 0
	.set softmax_f16.numbered_sgpr, 12
	.set softmax_f16.num_named_barrier, 0
	.set softmax_f16.private_seg_size, 0
	.set softmax_f16.uses_vcc, 1
	.set softmax_f16.uses_flat_scratch, 0
	.set softmax_f16.has_dyn_sized_stack, 0
	.set softmax_f16.has_recursion, 0
	.set softmax_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 812
; TotalNumSgprs: 18
; NumVgprs: 26
; NumAgprs: 0
; TotalNumVgprs: 26
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 26
; AccumOffset: 28
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 6
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	rmsnorm_f16             ; -- Begin function rmsnorm_f16
	.globl	rmsnorm_f16
	.p2align	8
	.type	rmsnorm_f16,@function
rmsnorm_f16:                            ; @rmsnorm_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_load_dwordx2 s[4:5], s[0:1], 0x10
	v_lshl_add_u32 v6, s2, 9, v0
	v_mov_b32_e32 v7, 0
	v_lshlrev_b64 v[2:3], 4, v[6:7]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[8:9], 0, v[2:3]
	global_load_dwordx4 v[16:19], v[4:5], off
	v_lshl_add_u64 v[2:3], s[10:11], 0, v[2:3]
	global_load_dwordx4 v[2:5], v[2:3], off
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_mbcnt_hi_u32_b32 v1, -1, v1
	v_and_b32_e32 v8, 64, v1
	v_xor_b32_e32 v9, 32, v1
	v_add_u32_e32 v24, 64, v8
	v_cmp_lt_i32_e32 vcc, v9, v24
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v14, v16
	v_cvt_f32_f16_sdwa v15, v16 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v12, v17
	v_cvt_f32_f16_sdwa v13, v17 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v10, v18
	v_cvt_f32_f16_sdwa v11, v18 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cndmask_b32_e32 v8, v1, v9, vcc
	v_pk_mul_f32 v[16:17], v[14:15], v[14:15]
	v_lshlrev_b32_e32 v25, 2, v8
	v_cvt_f32_f16_e32 v8, v19
	v_cvt_f32_f16_sdwa v9, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_pk_mul_f32 v[18:19], v[12:13], v[12:13]
	v_add_f32_e32 v16, v17, v16
	v_add_f32_e32 v16, v18, v16
	v_pk_mul_f32 v[20:21], v[10:11], v[10:11]
	v_add_f32_e32 v16, v19, v16
	v_add_f32_e32 v16, v20, v16
	v_pk_mul_f32 v[22:23], v[8:9], v[8:9]
	v_add_f32_e32 v16, v21, v16
	v_add_f32_e32 v16, v22, v16
	v_add_f32_e32 v16, v23, v16
	ds_bpermute_b32 v17, v25, v16
	v_xor_b32_e32 v18, 16, v1
	v_cmp_lt_i32_e32 vcc, v18, v24
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v16, v16, v17
	v_cndmask_b32_e32 v18, v1, v18, vcc
	v_lshlrev_b32_e32 v18, 2, v18
	ds_bpermute_b32 v17, v18, v16
	v_xor_b32_e32 v18, 8, v1
	v_cmp_lt_i32_e32 vcc, v18, v24
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v17, v16, v17
	v_cndmask_b32_e32 v18, v1, v18, vcc
	v_lshlrev_b32_e32 v18, 2, v18
	ds_bpermute_b32 v18, v18, v17
	v_xor_b32_e32 v16, 4, v1
	v_cmp_lt_i32_e32 vcc, v16, v24
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v18, v17, v18
	v_cndmask_b32_e32 v19, v1, v16, vcc
	v_lshlrev_b32_e32 v19, 2, v19
	ds_bpermute_b32 v19, v19, v18
	v_xor_b32_e32 v17, 2, v1
	v_cmp_lt_i32_e32 vcc, v17, v24
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v19, v18, v19
	v_cndmask_b32_e32 v20, v1, v17, vcc
	v_lshlrev_b32_e32 v20, 2, v20
	ds_bpermute_b32 v20, v20, v19
	v_xor_b32_e32 v18, 1, v1
	v_cmp_lt_i32_e32 vcc, v18, v24
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v19, v19, v20
	v_cndmask_b32_e32 v21, v1, v18, vcc
	v_lshlrev_b32_e32 v20, 2, v21
	ds_bpermute_b32 v20, v20, v19
	v_and_b32_e32 v21, 63, v0
	v_cmp_eq_u32_e32 vcc, 0, v21
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB7_2
; %bb.1:                                ; %if.then
	v_lshrrev_b32_e32 v21, 4, v0
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v19, v19, v20
	ds_write_b32 v21, v19
.LBB7_2:                                ; %if.end
	s_or_b64 exec, exec, s[0:1]
	v_and_b32_e32 v0, 7, v0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v0, v0
	v_and_b32_e32 v19, 0x78, v1
	v_add_u32_e32 v19, 8, v19
	v_cmp_lt_i32_e32 vcc, v16, v19
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_sdwa v21, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v20, v3
	v_cndmask_b32_e32 v16, v1, v16, vcc
	v_lshlrev_b32_e32 v16, 2, v16
	s_waitcnt lgkmcnt(0)
	ds_bpermute_b32 v16, v16, v0
	v_cmp_lt_i32_e32 vcc, v17, v19
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v16
	v_cndmask_b32_e32 v16, v1, v17, vcc
	v_lshlrev_b32_e32 v16, 2, v16
	ds_bpermute_b32 v16, v16, v0
	v_cmp_lt_i32_e32 vcc, v18, v19
	v_mov_b32_e32 v17, 0x358637bd
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v16
	v_cndmask_b32_e32 v1, v1, v18, vcc
	v_lshlrev_b32_e32 v1, 2, v1
	ds_bpermute_b32 v1, v1, v0
	v_mov_b32_e32 v16, s4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v1
	v_fmac_f32_e32 v17, 0x39800000, v0
	v_rsq_f32_e32 v18, v17
	v_cvt_f32_f16_sdwa v1, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v0, v2
	v_mov_b32_e32 v17, s5
	v_pk_mul_f32 v[14:15], v[18:19], v[14:15] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[18:19], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[0:1], v[14:15], v[0:1]
	v_pk_mul_f32 v[2:3], v[2:3], v[20:21]
	v_cvt_pk_f16_f32 v0, v0, v1
	v_cvt_pk_f16_f32 v1, v2, v3
	v_cvt_f32_f16_sdwa v3, v4 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v2, v4
	v_cvt_f32_f16_sdwa v13, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1
	v_cvt_f32_f16_e32 v12, v5
	v_pk_mul_f32 v[10:11], v[18:19], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[4:5], v[18:19], v[8:9] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[10:11], v[2:3]
	v_pk_mul_f32 v[4:5], v[4:5], v[12:13]
	v_cvt_pk_f16_f32 v2, v2, v3
	v_cvt_pk_f16_f32 v3, v4, v5
	v_lshl_add_u64 v[4:5], v[6:7], 4, v[16:17]
	global_store_dwordx4 v[4:5], v[0:3], off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rmsnorm_f16
		.amdhsa_group_segment_fixed_size 32
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 26
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 28
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set rmsnorm_f16.num_vgpr, 26
	.set rmsnorm_f16.num_agpr, 0
	.set rmsnorm_f16.numbered_sgpr, 12
	.set rmsnorm_f16.num_named_barrier, 0
	.set rmsnorm_f16.private_seg_size, 0
	.set rmsnorm_f16.uses_vcc, 1
	.set rmsnorm_f16.uses_flat_scratch, 0
	.set rmsnorm_f16.has_dyn_sized_stack, 0
	.set rmsnorm_f16.has_recursion, 0
	.set rmsnorm_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 752
; TotalNumSgprs: 18
; NumVgprs: 26
; NumAgprs: 0
; TotalNumVgprs: 26
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 26
; AccumOffset: 28
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 6
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	matvec_f16              ; -- Begin function matvec_f16
	.globl	matvec_f16
	.p2align	8
	.type	matvec_f16,@function
matvec_f16:                             ; @matvec_f16
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	v_lshrrev_b32_e32 v9, 7, v0
	v_sub_u32_e32 v1, 28, v9
	v_lshrrev_b32_e32 v1, 2, v1
	v_add_u32_e32 v3, 0x180, v0
	v_add_u32_e32 v2, 0x100, v0
	v_add_u32_e32 v11, 1, v1
	v_add_u32_e32 v1, 0x80, v0
	v_lshlrev_b32_e32 v8, 1, v0
	v_mov_b64_e32 v[4:5], v[2:3]
	v_and_b32_e32 v12, 12, v11
	s_mov_b64 s[0:1], 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v10, v8
	v_mov_b64_e32 v[2:3], v[0:1]
.LBB8_1:                                ; %vector.body
                                        ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v6, v2
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[32:33], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v3
	v_lshl_add_u64 v[34:35], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v4
	global_load_ushort v1, v[32:33], off
	global_load_ushort v13, v[34:35], off
	v_lshl_add_u64 v[32:33], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v5
	v_add_u32_e32 v14, 0x200, v5
	v_mov_b32_e32 v15, v7
	v_lshl_add_u64 v[34:35], v[6:7], 1, s[6:7]
	v_add_u32_e32 v6, 0x200, v2
	v_add_u32_e32 v16, 0x200, v4
	v_add_u32_e32 v18, 0x200, v3
	v_mov_b32_e32 v19, v7
	v_mov_b32_e32 v17, v7
	v_lshl_add_u64 v[14:15], v[14:15], 1, s[6:7]
	global_load_ushort v36, v[32:33], off
	v_lshl_add_u64 v[32:33], v[6:7], 1, s[6:7]
	v_add_u32_e32 v6, 0x400, v2
	v_add_u32_e32 v20, 0x400, v5
	v_add_u32_e32 v22, 0x400, v4
	v_add_u32_e32 v24, 0x400, v3
	v_mov_b32_e32 v25, v7
	v_mov_b32_e32 v23, v7
	v_mov_b32_e32 v21, v7
	v_add_u32_e32 v26, 0x600, v5
	v_add_u32_e32 v28, 0x600, v4
	v_add_u32_e32 v30, 0x600, v3
	v_mov_b32_e32 v31, v7
	v_mov_b32_e32 v29, v7
	v_mov_b32_e32 v27, v7
	v_lshl_add_u64 v[18:19], v[18:19], 1, s[6:7]
	v_lshl_add_u64 v[16:17], v[16:17], 1, s[6:7]
	global_load_ushort v37, v[34:35], off
	global_load_ushort v38, v[32:33], off
	global_load_ushort v39, v[18:19], off
	global_load_ushort v40, v[16:17], off
	global_load_ushort v41, v[14:15], off
	v_lshl_add_u64 v[14:15], v[6:7], 1, s[6:7]
	v_add_u32_e32 v6, 0x600, v2
	v_lshl_add_u64 v[24:25], v[24:25], 1, s[6:7]
	v_lshl_add_u64 v[22:23], v[22:23], 1, s[6:7]
	v_lshl_add_u64 v[20:21], v[20:21], 1, s[6:7]
	v_lshl_add_u64 v[30:31], v[30:31], 1, s[6:7]
	v_lshl_add_u64 v[28:29], v[28:29], 1, s[6:7]
	v_lshl_add_u64 v[26:27], v[26:27], 1, s[6:7]
	v_lshl_add_u64 v[16:17], v[6:7], 1, s[6:7]
	global_load_ushort v6, v[14:15], off
	global_load_ushort v18, v[24:25], off
	global_load_ushort v19, v[22:23], off
	global_load_ushort v32, v[20:21], off
	global_load_ushort v33, v[16:17], off
	global_load_ushort v34, v[30:31], off
	global_load_ushort v35, v[28:29], off
	global_load_ushort v42, v[26:27], off
	v_add_u32_e32 v12, -4, v12
	v_cmp_eq_u32_e32 vcc, 0, v12
	v_add_u32_e32 v3, 0x800, v3
	v_add_u32_e32 v4, 0x800, v4
	s_or_b64 s[0:1], vcc, s[0:1]
	v_add_u32_e32 v5, 0x800, v5
	v_add_u32_e32 v2, 0x800, v2
	s_waitcnt vmcnt(15)
	ds_write_b16 v10, v1
	s_waitcnt vmcnt(14)
	ds_write_b16 v10, v13 offset:256
	s_waitcnt vmcnt(13)
	ds_write_b16 v10, v36 offset:512
	s_waitcnt vmcnt(12)
	ds_write_b16 v10, v37 offset:768
	s_waitcnt vmcnt(11)
	ds_write_b16 v10, v38 offset:1024
	s_waitcnt vmcnt(10)
	ds_write_b16 v10, v39 offset:1280
	s_waitcnt vmcnt(9)
	ds_write_b16 v10, v40 offset:1536
	s_waitcnt vmcnt(8)
	ds_write_b16 v10, v41 offset:1792
	s_waitcnt vmcnt(7)
	ds_write_b16 v10, v6 offset:2048
	s_waitcnt vmcnt(6)
	ds_write_b16 v10, v18 offset:2304
	s_waitcnt vmcnt(5)
	ds_write_b16 v10, v19 offset:2560
	s_waitcnt vmcnt(4)
	ds_write_b16 v10, v32 offset:2816
	s_waitcnt vmcnt(3)
	ds_write_b16 v10, v33 offset:3072
	s_waitcnt vmcnt(2)
	ds_write_b16 v10, v34 offset:3328
	s_waitcnt vmcnt(1)
	ds_write_b16 v10, v35 offset:3584
	s_waitcnt vmcnt(0)
	ds_write_b16 v10, v42 offset:3840
	v_add_u32_e32 v10, 0x1000, v10
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB8_1
; %bb.2:                                ; %middle.block.unr-lcssa
	s_or_b64 exec, exec, s[0:1]
	v_and_b32_e32 v1, 3, v11
	v_cmp_ne_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB8_5
; %bb.3:                                ; %vector.body.epil.preheader
	s_mov_b64 s[10:11], 0
	v_mov_b32_e32 v7, 0
.LBB8_4:                                ; %vector.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v6, v2
	v_lshl_add_u64 v[12:13], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v3
	v_lshl_add_u64 v[14:15], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v4
	global_load_ushort v11, v[12:13], off
	global_load_ushort v16, v[14:15], off
	v_lshl_add_u64 v[12:13], v[6:7], 1, s[6:7]
	v_mov_b32_e32 v6, v5
	v_lshl_add_u64 v[14:15], v[6:7], 1, s[6:7]
	global_load_ushort v6, v[12:13], off
	global_load_ushort v17, v[14:15], off
	v_add_u32_e32 v1, -1, v1
	v_cmp_eq_u32_e32 vcc, 0, v1
	v_add_u32_e32 v2, 0x200, v2
	v_add_u32_e32 v3, 0x200, v3
	v_add_u32_e32 v4, 0x200, v4
	s_or_b64 s[10:11], vcc, s[10:11]
	v_add_u32_e32 v5, 0x200, v5
	s_waitcnt vmcnt(3)
	ds_write_b16 v10, v11
	s_waitcnt vmcnt(2)
	ds_write_b16 v10, v16 offset:256
	s_waitcnt vmcnt(1)
	ds_write_b16 v10, v6 offset:512
	s_waitcnt vmcnt(0)
	ds_write_b16 v10, v17 offset:768
	v_add_u32_e32 v10, 0x400, v10
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB8_4
.LBB8_5:                                ; %Flow201
	s_or_b64 exec, exec, s[0:1]
	v_sub_u32_e32 v4, 32, v9
	v_and_b32_e32 v1, 60, v4
	v_cmp_ne_u32_e32 vcc, v4, v1
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB8_8
; %bb.6:                                ; %for.body.preheader
	v_lshl_add_u32 v2, v1, 7, v0
	v_lshlrev_b32_e32 v4, 8, v4
	v_add_u32_e32 v1, 0xffffff80, v2
	v_lshlrev_b32_e32 v2, 1, v2
	v_mov_b32_e32 v3, 0
	v_and_b32_e32 v4, 0x3c00, v4
	v_lshl_add_u64 v[2:3], s[6:7], 0, v[2:3]
	v_add_u32_e32 v4, v4, v8
	s_mov_b64 s[6:7], 0
	s_mov_b64 s[10:11], 0x100
	s_movk_i32 s3, 0xf7f
.LBB8_7:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	global_load_ushort v5, v[2:3], off
	v_add_u32_e32 v1, 0x80, v1
	v_cmp_lt_u32_e32 vcc, s3, v1
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[10:11]
	s_or_b64 s[6:7], vcc, s[6:7]
	s_waitcnt vmcnt(0)
	ds_write_b16 v4, v5
	v_add_u32_e32 v4, 0x100, v4
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB8_7
.LBB8_8:                                ; %Flow199
	s_or_b64 exec, exec, s[0:1]
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_mbcnt_hi_u32_b32 v2, -1, v1
	v_and_b32_e32 v1, 64, v2
	v_add_u32_e32 v3, 64, v1
	v_xor_b32_e32 v1, 32, v2
	v_cmp_lt_i32_e32 vcc, v1, v3
	v_xor_b32_e32 v4, 16, v2
	v_lshrrev_b32_e32 v113, 6, v0
	v_cndmask_b32_e32 v1, v2, v1, vcc
	v_cmp_lt_i32_e32 vcc, v4, v3
	v_and_b32_e32 v0, 63, v0
	v_lshlrev_b32_e32 v58, 1, v0
	v_cndmask_b32_e32 v66, v2, v4, vcc
	v_xor_b32_e32 v4, 8, v2
	v_cmp_lt_i32_e32 vcc, v4, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_cndmask_b32_e32 v67, v2, v4, vcc
	v_xor_b32_e32 v4, 4, v2
	v_cmp_lt_i32_e32 vcc, v4, v3
	v_lshlrev_b32_e32 v118, 2, v1
	s_nop 0
	v_cndmask_b32_e32 v68, v2, v4, vcc
	v_xor_b32_e32 v4, 2, v2
	v_cmp_lt_i32_e32 vcc, v4, v3
	v_lshlrev_b32_e32 v1, 12, v113
	v_lshlrev_b32_e32 v119, 2, v66
	v_cndmask_b32_e32 v69, v2, v4, vcc
	v_xor_b32_e32 v4, 1, v2
	v_cmp_lt_i32_e32 vcc, v4, v3
	v_lshlrev_b32_e32 v120, 2, v67
	v_lshlrev_b32_e32 v121, 2, v68
	v_cndmask_b32_e32 v70, v2, v4, vcc
	ds_read_u16 v2, v58
	ds_read_u16 v3, v58 offset:128
	ds_read_u16 v4, v58 offset:256
	ds_read_u16 v5, v58 offset:384
	ds_read_u16 v6, v58 offset:512
	ds_read_u16 v7, v58 offset:640
	ds_read_u16 v8, v58 offset:768
	ds_read_u16 v9, v58 offset:896
	ds_read_u16 v10, v58 offset:1024
	ds_read_u16 v11, v58 offset:1152
	ds_read_u16 v12, v58 offset:1280
	ds_read_u16 v13, v58 offset:1408
	ds_read_u16 v14, v58 offset:1536
	ds_read_u16 v15, v58 offset:1664
	ds_read_u16 v16, v58 offset:1792
	ds_read_u16 v17, v58 offset:1920
	ds_read_u16 v18, v58 offset:2048
	ds_read_u16 v19, v58 offset:2176
	ds_read_u16 v20, v58 offset:2304
	ds_read_u16 v21, v58 offset:2432
	ds_read_u16 v22, v58 offset:2560
	ds_read_u16 v23, v58 offset:2688
	ds_read_u16 v24, v58 offset:2816
	ds_read_u16 v25, v58 offset:2944
	ds_read_u16 v26, v58 offset:3072
	ds_read_u16 v27, v58 offset:3200
	ds_read_u16 v28, v58 offset:3328
	ds_read_u16 v29, v58 offset:3456
	ds_read_u16 v30, v58 offset:3584
	ds_read_u16 v31, v58 offset:3712
	ds_read_u16 v32, v58 offset:3840
	ds_read_u16 v33, v58 offset:3968
	ds_read_u16 v34, v58 offset:4096
	ds_read_u16 v35, v58 offset:4224
	ds_read_u16 v36, v58 offset:4352
	ds_read_u16 v37, v58 offset:4480
	ds_read_u16 v38, v58 offset:4608
	ds_read_u16 v39, v58 offset:4736
	ds_read_u16 v40, v58 offset:4864
	ds_read_u16 v41, v58 offset:4992
	ds_read_u16 v42, v58 offset:5120
	ds_read_u16 v43, v58 offset:5248
	ds_read_u16 v44, v58 offset:5376
	ds_read_u16 v45, v58 offset:5504
	ds_read_u16 v46, v58 offset:5632
	ds_read_u16 v47, v58 offset:5760
	ds_read_u16 v48, v58 offset:5888
	ds_read_u16 v49, v58 offset:6016
	ds_read_u16 v50, v58 offset:6144
	ds_read_u16 v51, v58 offset:6272
	ds_read_u16 v52, v58 offset:6400
	ds_read_u16 v53, v58 offset:6528
	ds_read_u16 v54, v58 offset:6656
	ds_read_u16 v55, v58 offset:6784
	ds_read_u16 v56, v58 offset:6912
	ds_read_u16 v57, v58 offset:7040
	ds_read_u16 v60, v58 offset:7168
	ds_read_u16 v59, v58 offset:7296
	ds_read_u16 v62, v58 offset:7424
	ds_read_u16 v61, v58 offset:7552
	ds_read_u16 v64, v58 offset:7680
	ds_read_u16 v63, v58 offset:7808
	ds_read_u16 v71, v58 offset:7936
	ds_read_u16 v65, v58 offset:8064
	s_waitcnt lgkmcnt(14)
	v_cvt_f32_f16_e32 v3, v3
	v_cvt_f32_f16_e32 v2, v2
	v_cvt_f32_f16_e32 v5, v5
	v_cvt_f32_f16_e32 v4, v4
	v_cvt_f32_f16_e32 v7, v7
	v_cvt_f32_f16_e32 v6, v6
	v_cvt_f32_f16_e32 v9, v9
	v_cvt_f32_f16_e32 v8, v8
	v_cvt_f32_f16_e32 v11, v11
	v_cvt_f32_f16_e32 v10, v10
	v_cvt_f32_f16_e32 v13, v13
	v_cvt_f32_f16_e32 v12, v12
	v_cvt_f32_f16_e32 v15, v15
	v_cvt_f32_f16_e32 v14, v14
	v_cvt_f32_f16_e32 v17, v17
	v_cvt_f32_f16_e32 v16, v16
	v_cvt_f32_f16_e32 v19, v19
	v_cvt_f32_f16_e32 v18, v18
	v_cvt_f32_f16_e32 v21, v21
	v_cvt_f32_f16_e32 v20, v20
	v_cvt_f32_f16_e32 v23, v23
	v_cvt_f32_f16_e32 v22, v22
	v_cvt_f32_f16_e32 v25, v25
	v_cvt_f32_f16_e32 v24, v24
	v_cvt_f32_f16_e32 v27, v27
	v_cvt_f32_f16_e32 v26, v26
	v_cvt_f32_f16_e32 v29, v29
	v_cvt_f32_f16_e32 v28, v28
	v_cvt_f32_f16_e32 v31, v31
	v_cvt_f32_f16_e32 v30, v30
	v_cvt_f32_f16_e32 v33, v33
	v_cvt_f32_f16_e32 v32, v32
	v_cvt_f32_f16_e32 v35, v35
	v_cvt_f32_f16_e32 v34, v34
	v_cvt_f32_f16_e32 v37, v37
	v_cvt_f32_f16_e32 v36, v36
	v_cvt_f32_f16_e32 v39, v39
	v_cvt_f32_f16_e32 v38, v38
	v_cvt_f32_f16_e32 v41, v41
	v_cvt_f32_f16_e32 v40, v40
	v_cvt_f32_f16_e32 v43, v43
	v_cvt_f32_f16_e32 v42, v42
	v_cvt_f32_f16_e32 v45, v45
	v_cvt_f32_f16_e32 v44, v44
	v_cvt_f32_f16_e32 v47, v47
	v_cvt_f32_f16_e32 v46, v46
	v_cvt_f32_f16_e32 v49, v49
	v_cvt_f32_f16_e32 v48, v48
	v_cvt_f32_f16_e32 v51, v51
	v_cvt_f32_f16_e32 v50, v50
	s_waitcnt lgkmcnt(12)
	v_cvt_f32_f16_e32 v53, v53
	v_cvt_f32_f16_e32 v52, v52
	s_waitcnt lgkmcnt(10)
	v_cvt_f32_f16_e32 v55, v55
	v_cvt_f32_f16_e32 v54, v54
	s_waitcnt lgkmcnt(8)
	v_cvt_f32_f16_e32 v57, v57
	v_cvt_f32_f16_e32 v56, v56
	s_waitcnt lgkmcnt(6)
	v_cvt_f32_f16_e32 v59, v59
	v_cvt_f32_f16_e32 v58, v60
	s_waitcnt lgkmcnt(4)
	v_cvt_f32_f16_e32 v61, v61
	v_cvt_f32_f16_e32 v60, v62
	s_waitcnt lgkmcnt(2)
	v_cvt_f32_f16_e32 v63, v63
	v_cvt_f32_f16_e32 v62, v64
	s_waitcnt lgkmcnt(0)
	v_cvt_f32_f16_e32 v65, v65
	v_cvt_f32_f16_e32 v64, v71
	v_lshlrev_b32_e32 v122, 2, v69
	v_lshlrev_b32_e32 v123, 2, v70
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_lshl_b32 s6, s2, 5
	v_lshl_or_b32 v124, s2, 17, v1
	s_mov_b64 s[2:3], 0
	v_or_b32_e32 v1, 0x440, v0
	v_or_b32_e32 v66, 0x400, v0
	v_or_b32_e32 v67, 0x4c0, v0
	v_or_b32_e32 v68, 0x480, v0
	v_or_b32_e32 v69, 0x540, v0
	v_or_b32_e32 v70, 0x500, v0
	v_or_b32_e32 v71, 0x5c0, v0
	v_or_b32_e32 v72, 0x580, v0
	v_or_b32_e32 v73, 0x640, v0
	v_or_b32_e32 v74, 0x600, v0
	v_or_b32_e32 v75, 0x6c0, v0
	v_or_b32_e32 v76, 0x680, v0
	v_or_b32_e32 v77, 0x740, v0
	v_or_b32_e32 v78, 0x700, v0
	v_or_b32_e32 v79, 0x7c0, v0
	v_or_b32_e32 v80, 0x780, v0
	v_or_b32_e32 v81, 0x840, v0
	v_or_b32_e32 v82, 0x800, v0
	v_or_b32_e32 v83, 0x8c0, v0
	v_or_b32_e32 v84, 0x880, v0
	v_or_b32_e32 v85, 0x940, v0
	v_or_b32_e32 v86, 0x900, v0
	v_or_b32_e32 v87, 0x9c0, v0
	v_or_b32_e32 v88, 0x980, v0
	v_or_b32_e32 v89, 0xa40, v0
	v_or_b32_e32 v90, 0xa00, v0
	v_or_b32_e32 v91, 0xac0, v0
	v_or_b32_e32 v92, 0xa80, v0
	v_or_b32_e32 v93, 0xb40, v0
	v_or_b32_e32 v94, 0xb00, v0
	v_or_b32_e32 v95, 0xbc0, v0
	v_or_b32_e32 v96, 0xb80, v0
	v_or_b32_e32 v97, 0xc40, v0
	v_or_b32_e32 v98, 0xc00, v0
	v_or_b32_e32 v99, 0xcc0, v0
	v_or_b32_e32 v100, 0xc80, v0
	v_or_b32_e32 v101, 0xd40, v0
	v_or_b32_e32 v102, 0xd00, v0
	v_or_b32_e32 v103, 0xdc0, v0
	v_or_b32_e32 v104, 0xd80, v0
	v_or_b32_e32 v105, 0xe40, v0
	v_or_b32_e32 v106, 0xe00, v0
	v_or_b32_e32 v107, 0xec0, v0
	v_or_b32_e32 v108, 0xe80, v0
	v_or_b32_e32 v109, 0xf40, v0
	v_or_b32_e32 v110, 0xf00, v0
	v_or_b32_e32 v111, 0xfc0, v0
	v_or_b32_e32 v112, 0xf80, v0
	v_mov_b32_e32 v115, 0
	s_branch .LBB8_10
.LBB8_9:                                ; %if.end
                                        ;   in Loop: Header=BB8_10 Depth=1
	s_or_b64 exec, exec, s[0:1]
	v_add_u32_e32 v114, 2, v113
	v_cmp_lt_u32_e64 s[0:1], 29, v113
	v_add_u32_e32 v124, 0x2000, v124
	s_or_b64 s[2:3], s[0:1], s[2:3]
	v_mov_b32_e32 v113, v114
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execz .LBB8_12
.LBB8_10:                               ; %vector.ph63
                                        ; =>This Inner Loop Header: Depth=1
	v_or_b32_e32 v114, v0, v124
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[116:117], v[114:115], 1, s[4:5]
	global_load_ushort v125, v[116:117], off
	v_or_b32_e32 v117, 64, v0
	v_or_b32_e32 v116, v117, v124
	v_mov_b32_e32 v117, v115
	v_lshl_add_u64 v[116:117], v[116:117], 1, s[4:5]
	global_load_ushort v126, v[116:117], off
	v_or_b32_e32 v117, 0xc0, v0
	v_or_b32_e32 v116, v117, v124
	v_mov_b32_e32 v117, v115
	v_or_b32_e32 v114, 0x80, v0
	v_lshl_add_u64 v[116:117], v[116:117], 1, s[4:5]
	v_or_b32_e32 v114, v114, v124
	global_load_ushort v127, v[116:117], off
	v_lshl_add_u64 v[116:117], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[116:117], off
	s_waitcnt vmcnt(3)
	v_cvt_f32_f16_e32 v116, v125
	v_or_b32_e32 v125, 0x140, v0
	s_waitcnt vmcnt(2)
	v_cvt_f32_f16_e32 v117, v126
	v_pk_mul_f32 v[116:117], v[2:3], v[116:117]
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v127
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, 0x100, v0
	v_or_b32_e32 v114, v114, v124
	v_pk_fma_f32 v[116:117], v[4:5], v[126:127], v[116:117]
	v_or_b32_e32 v126, v125, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	v_or_b32_e32 v125, 0x1c0, v0
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, 0x180, v0
	v_or_b32_e32 v114, v114, v124
	v_pk_fma_f32 v[116:117], v[6:7], v[126:127], v[116:117]
	v_or_b32_e32 v126, v125, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	v_or_b32_e32 v125, 0x240, v0
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, 0x200, v0
	v_or_b32_e32 v114, v114, v124
	v_pk_fma_f32 v[116:117], v[8:9], v[126:127], v[116:117]
	v_or_b32_e32 v126, v125, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	v_or_b32_e32 v125, 0x2c0, v0
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, 0x280, v0
	v_or_b32_e32 v114, v114, v124
	v_pk_fma_f32 v[116:117], v[10:11], v[126:127], v[116:117]
	v_or_b32_e32 v126, v125, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	v_or_b32_e32 v125, 0x340, v0
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, 0x300, v0
	v_or_b32_e32 v114, v114, v124
	v_pk_fma_f32 v[116:117], v[12:13], v[126:127], v[116:117]
	v_or_b32_e32 v126, v125, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	v_or_b32_e32 v125, 0x3c0, v0
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, 0x380, v0
	v_or_b32_e32 v114, v114, v124
	v_pk_fma_f32 v[116:117], v[14:15], v[126:127], v[116:117]
	v_or_b32_e32 v126, v125, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v66, v124
	v_pk_fma_f32 v[116:117], v[16:17], v[126:127], v[116:117]
	v_or_b32_e32 v126, v1, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v68, v124
	v_pk_fma_f32 v[116:117], v[18:19], v[126:127], v[116:117]
	v_or_b32_e32 v126, v67, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v70, v124
	v_pk_fma_f32 v[116:117], v[20:21], v[126:127], v[116:117]
	v_or_b32_e32 v126, v69, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v72, v124
	v_pk_fma_f32 v[116:117], v[22:23], v[126:127], v[116:117]
	v_or_b32_e32 v126, v71, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v74, v124
	v_pk_fma_f32 v[116:117], v[24:25], v[126:127], v[116:117]
	v_or_b32_e32 v126, v73, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v76, v124
	v_pk_fma_f32 v[116:117], v[26:27], v[126:127], v[116:117]
	v_or_b32_e32 v126, v75, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v78, v124
	v_pk_fma_f32 v[116:117], v[28:29], v[126:127], v[116:117]
	v_or_b32_e32 v126, v77, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v80, v124
	v_pk_fma_f32 v[116:117], v[30:31], v[126:127], v[116:117]
	v_or_b32_e32 v126, v79, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v82, v124
	v_pk_fma_f32 v[116:117], v[32:33], v[126:127], v[116:117]
	v_or_b32_e32 v126, v81, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v84, v124
	v_pk_fma_f32 v[116:117], v[34:35], v[126:127], v[116:117]
	v_or_b32_e32 v126, v83, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v86, v124
	v_pk_fma_f32 v[116:117], v[36:37], v[126:127], v[116:117]
	v_or_b32_e32 v126, v85, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v88, v124
	v_pk_fma_f32 v[116:117], v[38:39], v[126:127], v[116:117]
	v_or_b32_e32 v126, v87, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v90, v124
	v_pk_fma_f32 v[116:117], v[40:41], v[126:127], v[116:117]
	v_or_b32_e32 v126, v89, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v92, v124
	v_pk_fma_f32 v[116:117], v[42:43], v[126:127], v[116:117]
	v_or_b32_e32 v126, v91, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v94, v124
	v_pk_fma_f32 v[116:117], v[44:45], v[126:127], v[116:117]
	v_or_b32_e32 v126, v93, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v96, v124
	v_pk_fma_f32 v[116:117], v[46:47], v[126:127], v[116:117]
	v_or_b32_e32 v126, v95, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v98, v124
	v_pk_fma_f32 v[116:117], v[48:49], v[126:127], v[116:117]
	v_or_b32_e32 v126, v97, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v100, v124
	v_pk_fma_f32 v[116:117], v[50:51], v[126:127], v[116:117]
	v_or_b32_e32 v126, v99, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v102, v124
	v_pk_fma_f32 v[116:117], v[52:53], v[126:127], v[116:117]
	v_or_b32_e32 v126, v101, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v104, v124
	v_pk_fma_f32 v[116:117], v[54:55], v[126:127], v[116:117]
	v_or_b32_e32 v126, v103, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v106, v124
	v_pk_fma_f32 v[116:117], v[56:57], v[126:127], v[116:117]
	v_or_b32_e32 v126, v105, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v108, v124
	v_pk_fma_f32 v[116:117], v[58:59], v[126:127], v[116:117]
	v_or_b32_e32 v126, v107, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v110, v124
	v_pk_fma_f32 v[116:117], v[60:61], v[126:127], v[116:117]
	v_or_b32_e32 v126, v109, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_or_b32_e32 v114, v112, v124
	v_pk_fma_f32 v[116:117], v[62:63], v[126:127], v[116:117]
	v_or_b32_e32 v126, v111, v124
	v_mov_b32_e32 v127, v115
	v_lshl_add_u64 v[126:127], v[126:127], 1, s[4:5]
	global_load_ushort v125, v[126:127], off
	v_lshl_add_u64 v[126:127], v[114:115], 1, s[4:5]
	global_load_ushort v114, v[126:127], off
	s_waitcnt vmcnt(1)
	v_cvt_f32_f16_e32 v127, v125
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v126, v114
	v_pk_fma_f32 v[116:117], v[64:65], v[126:127], v[116:117]
	s_nop 0
	v_add_f32_e32 v114, v116, v117
	ds_bpermute_b32 v116, v118, v114
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v114, v114, v116
	ds_bpermute_b32 v116, v119, v114
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v114, v114, v116
	ds_bpermute_b32 v116, v120, v114
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v114, v114, v116
	ds_bpermute_b32 v116, v121, v114
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v114, v114, v116
	ds_bpermute_b32 v116, v122, v114
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v114, v114, v116
	ds_bpermute_b32 v116, v123, v114
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB8_9
; %bb.11:                               ; %if.then
                                        ;   in Loop: Header=BB8_10 Depth=1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v114, v114, v116
	v_cvt_f16_f32_e32 v125, v114
	v_add_u32_e32 v114, s6, v113
	v_lshl_add_u64 v[116:117], v[114:115], 1, s[8:9]
	global_store_short v[116:117], v125, off
	s_branch .LBB8_9
.LBB8_12:                               ; %for.cond.cleanup8
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 128
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 128
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
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
	.set matvec_f16.num_vgpr, 128
	.set matvec_f16.num_agpr, 0
	.set matvec_f16.numbered_sgpr, 12
	.set matvec_f16.num_named_barrier, 0
	.set matvec_f16.private_seg_size, 0
	.set matvec_f16.uses_vcc, 1
	.set matvec_f16.uses_flat_scratch, 0
	.set matvec_f16.has_dyn_sized_stack, 0
	.set matvec_f16.has_recursion, 0
	.set matvec_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4952
; TotalNumSgprs: 18
; NumVgprs: 128
; NumAgprs: 0
; TotalNumVgprs: 128
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8192 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 15
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 128
; AccumOffset: 128
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 31
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_b130bab35f55692d,@object ; @__hip_cuid_b130bab35f55692d
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_b130bab35f55692d
__hip_cuid_b130bab35f55692d:
	.byte	0                               ; 0x0
	.size	__hip_cuid_b130bab35f55692d, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_b130bab35f55692d
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         relu_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         silu_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     10
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         sigmoid_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           gate.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           value.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         swiglu_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     22
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           cosine.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           sine.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         rope_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     9
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     16
    .sgpr_spill_count: 0
    .symbol:         reduction_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     12
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           out.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           x.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .name:           input_row_stride
        .offset:         16
        .size:           4
        .value_kind:     by_value
      - .name:           output_row_stride
        .offset:         20
        .size:           4
        .value_kind:     by_value
      - .name:           n_rows
        .offset:         24
        .size:           4
        .value_kind:     by_value
      - .name:           n_cols
        .offset:         28
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
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         softmax_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     26
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           weight.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           rmsnorm_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         rmsnorm_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     26
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           a.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           x.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         matvec_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     128
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
