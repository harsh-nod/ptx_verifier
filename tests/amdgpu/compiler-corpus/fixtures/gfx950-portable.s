	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	portable_relu           ; -- Begin function portable_relu
	.globl	portable_relu
	.p2align	8
	.type	portable_relu,@function
portable_relu:                          ; @portable_relu
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v1, v1, v1
	v_max_f32_e32 v1, 0, v1
	global_store_dword v0, v1, s[2:3]
.LBB0_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_relu
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_accum_offset 4
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
.Lfunc_end0:
	.size	portable_relu, .Lfunc_end0-portable_relu
                                        ; -- End function
	.set portable_relu.num_vgpr, 2
	.set portable_relu.num_agpr, 0
	.set portable_relu.numbered_sgpr, 4
	.set portable_relu.num_named_barrier, 0
	.set portable_relu.private_seg_size, 0
	.set portable_relu.uses_vcc, 1
	.set portable_relu.uses_flat_scratch, 0
	.set portable_relu.has_dyn_sized_stack, 0
	.set portable_relu.has_recursion, 0
	.set portable_relu.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 10
; NumVgprs: 2
; NumAgprs: 0
; TotalNumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 2
; AccumOffset: 4
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 0
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_sigmoid        ; -- Begin function portable_sigmoid
	.globl	portable_sigmoid
	.p2align	8
	.type	portable_sigmoid,@function
portable_sigmoid:                       ; @portable_sigmoid
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB1_2
; %bb.1:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, 0xbfb8aa3b, v1
	v_exp_f32_e32 v1, v1
	s_nop 0
	v_add_f32_e32 v1, 1.0, v1
	v_rcp_f32_e32 v1, v1
	global_store_dword v0, v1, s[2:3]
.LBB1_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_sigmoid
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_accum_offset 4
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
.Lfunc_end1:
	.size	portable_sigmoid, .Lfunc_end1-portable_sigmoid
                                        ; -- End function
	.set portable_sigmoid.num_vgpr, 2
	.set portable_sigmoid.num_agpr, 0
	.set portable_sigmoid.numbered_sgpr, 4
	.set portable_sigmoid.num_named_barrier, 0
	.set portable_sigmoid.private_seg_size, 0
	.set portable_sigmoid.uses_vcc, 1
	.set portable_sigmoid.uses_flat_scratch, 0
	.set portable_sigmoid.has_dyn_sized_stack, 0
	.set portable_sigmoid.has_recursion, 0
	.set portable_sigmoid.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 76
; TotalNumSgprs: 10
; NumVgprs: 2
; NumAgprs: 0
; TotalNumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 2
; AccumOffset: 4
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 0
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_silu           ; -- Begin function portable_silu
	.globl	portable_silu
	.p2align	8
	.type	portable_silu,@function
portable_silu:                          ; @portable_silu
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB2_2
; %bb.1:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, 0xbfb8aa3b, v1
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v2, v2
	s_nop 0
	v_mul_f32_e32 v1, v1, v2
	global_store_dword v0, v1, s[2:3]
.LBB2_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_silu
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 4
		.amdhsa_accum_offset 4
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
.Lfunc_end2:
	.size	portable_silu, .Lfunc_end2-portable_silu
                                        ; -- End function
	.set portable_silu.num_vgpr, 3
	.set portable_silu.num_agpr, 0
	.set portable_silu.numbered_sgpr, 4
	.set portable_silu.num_named_barrier, 0
	.set portable_silu.private_seg_size, 0
	.set portable_silu.uses_vcc, 1
	.set portable_silu.uses_flat_scratch, 0
	.set portable_silu.has_dyn_sized_stack, 0
	.set portable_silu.has_recursion, 0
	.set portable_silu.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 84
; TotalNumSgprs: 10
; NumVgprs: 3
; NumAgprs: 0
; TotalNumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 3
; AccumOffset: 4
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 0
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_swiglu         ; -- Begin function portable_swiglu
	.globl	portable_swiglu
	.p2align	8
	.type	portable_swiglu,@function
portable_swiglu:                        ; @portable_swiglu
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB3_2
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[4:5]
	global_load_dword v2, v0, s[6:7]
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v3, 0xbfb8aa3b, v1
	v_exp_f32_e32 v3, v3
	s_nop 0
	v_add_f32_e32 v3, 1.0, v3
	v_rcp_f32_e32 v3, v3
	s_nop 0
	v_mul_f32_e32 v1, v1, v3
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, v2, v1
	global_store_dword v0, v1, s[2:3]
.LBB3_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_swiglu
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 4
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
.Lfunc_end3:
	.size	portable_swiglu, .Lfunc_end3-portable_swiglu
                                        ; -- End function
	.set portable_swiglu.num_vgpr, 4
	.set portable_swiglu.num_agpr, 0
	.set portable_swiglu.numbered_sgpr, 8
	.set portable_swiglu.num_named_barrier, 0
	.set portable_swiglu.private_seg_size, 0
	.set portable_swiglu.uses_vcc, 1
	.set portable_swiglu.uses_flat_scratch, 0
	.set portable_swiglu.has_dyn_sized_stack, 0
	.set portable_swiglu.has_recursion, 0
	.set portable_swiglu.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 108
; TotalNumSgprs: 14
; NumVgprs: 4
; NumAgprs: 0
; TotalNumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 4
; AccumOffset: 4
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 0
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_rope           ; -- Begin function portable_rope
	.globl	portable_rope
	.p2align	8
	.type	portable_rope,@function
portable_rope:                          ; @portable_rope
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB4_2
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	v_xor_b32_e32 v1, 16, v0
	v_lshlrev_b32_e32 v1, 2, v1
	v_lshlrev_b32_e32 v6, 2, v0
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v3, v1, s[4:5]
	global_load_dword v2, v6, s[4:5]
	global_load_dword v4, v6, s[6:7]
	global_load_dword v5, v6, s[8:9]
	s_waitcnt vmcnt(3)
	v_cndmask_b32_e64 v3, v3, -v3, vcc
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[0:1], v[2:3], v[4:5]
	s_nop 0
	v_add_f32_e32 v0, v0, v1
	global_store_dword v6, v0, s[10:11]
.LBB4_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_rope
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
		.amdhsa_next_free_vgpr 7
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 8
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
	.size	portable_rope, .Lfunc_end4-portable_rope
                                        ; -- End function
	.set portable_rope.num_vgpr, 7
	.set portable_rope.num_agpr, 0
	.set portable_rope.numbered_sgpr, 12
	.set portable_rope.num_named_barrier, 0
	.set portable_rope.private_seg_size, 0
	.set portable_rope.uses_vcc, 1
	.set portable_rope.uses_flat_scratch, 0
	.set portable_rope.has_dyn_sized_stack, 0
	.set portable_rope.has_recursion, 0
	.set portable_rope.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 116
; TotalNumSgprs: 18
; NumVgprs: 7
; NumAgprs: 0
; TotalNumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 7
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
	.protected	portable_reduction      ; -- Begin function portable_reduction
	.globl	portable_reduction
	.p2align	8
	.type	portable_reduction,@function
portable_reduction:                     ; @portable_reduction
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB5_4
; %bb.1:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v3, 0
	v_lshlrev_b32_e32 v2, 7, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[2:3]
	s_mov_b64 s[0:1], 0
.LBB5_2:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[4:5], 0, s[0:1]
	global_load_dword v1, v[6:7], off
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmpk_eq_i32 s0, 0x80
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v3, v3, v1
	s_cbranch_scc0 .LBB5_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB5_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_reduction
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
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 4
		.amdhsa_accum_offset 8
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
	.size	portable_reduction, .Lfunc_end5-portable_reduction
                                        ; -- End function
	.set portable_reduction.num_vgpr, 8
	.set portable_reduction.num_agpr, 0
	.set portable_reduction.numbered_sgpr, 4
	.set portable_reduction.num_named_barrier, 0
	.set portable_reduction.private_seg_size, 0
	.set portable_reduction.uses_vcc, 1
	.set portable_reduction.uses_flat_scratch, 0
	.set portable_reduction.has_dyn_sized_stack, 0
	.set portable_reduction.has_recursion, 0
	.set portable_reduction.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 100
; TotalNumSgprs: 10
; NumVgprs: 8
; NumAgprs: 0
; TotalNumVgprs: 8
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 8
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
	.protected	portable_softmax        ; -- Begin function portable_softmax
	.globl	portable_softmax
	.p2align	8
	.type	portable_softmax,@function
portable_softmax:                       ; @portable_softmax
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB6_8
; %bb.1:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_and_b32_e32 v5, 32, v0
	v_lshlrev_b32_e32 v1, 2, v5
	v_lshlrev_b32_e32 v4, 2, v0
	v_and_b32_e32 v0, 0x80, v4
	s_waitcnt lgkmcnt(0)
	global_load_dword v8, v1, s[0:1]
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[0:1]
	v_lshl_add_u64 v[2:3], v[0:1], 0, 4
	s_mov_b32 s8, -2
	s_mov_b64 s[6:7], 0
                                        ; implicit-def: $sgpr4_sgpr5
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v9, v8
.LBB6_2:                                ; =>This Inner Loop Header: Depth=1
	global_load_dwordx2 v[12:13], v[2:3], off
	v_mov_b32_e32 v6, v8
	v_mov_b32_e32 v7, v9
	v_max_f32_e32 v8, v7, v7
	v_max_f32_e32 v11, v6, v6
	s_cmp_eq_u32 s8, 26
	s_cselect_b64 s[10:11], -1, 0
	s_add_i32 s8, s8, 2
	v_lshl_add_u64 v[2:3], v[2:3], 0, 8
	v_mov_b32_e32 v10, s8
	s_waitcnt vmcnt(0)
	v_cmp_u_f32_e32 vcc, v13, v13
	v_max_f32_e32 v9, v13, v13
	v_max_f32_e32 v14, v12, v12
	v_cndmask_b32_e64 v13, 0, 1, vcc
	v_cmp_u_f32_e32 vcc, v12, v12
	v_max_f32_e32 v9, v8, v9
	v_max_f32_e32 v8, v11, v14
	v_cndmask_b32_e64 v12, 0, 1, vcc
	v_lshlrev_b16_e32 v11, 1, v13
	v_bitop3_b16 v11, v12, 3, v11 bitop3:0xc8
	v_cmp_ne_u16_e32 vcc, 0, v11
	s_or_b64 s[10:11], vcc, s[10:11]
	s_and_b64 s[10:11], exec, s[10:11]
	s_or_b64 s[6:7], s[10:11], s[6:7]
	s_andn2_b64 s[4:5], s[4:5], exec
	s_and_b64 s[10:11], vcc, exec
	s_or_b64 s[4:5], s[4:5], s[10:11]
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB6_2
; %bb.3:
	s_or_b64 exec, exec, s[6:7]
	v_or_b32_e32 v2, 1, v10
	v_cndmask_b32_e64 v10, 31, v2, s[4:5]
	v_cndmask_b32_e64 v2, v8, v6, s[4:5]
	v_cndmask_b32_e64 v3, v9, v7, s[4:5]
	v_max_f32_e32 v3, v3, v3
	v_max_f32_e32 v2, v2, v2
	v_max_f32_e32 v6, v2, v3
	s_mov_b64 s[4:5], 0
	v_mov_b32_e32 v3, 0
.LBB6_4:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v2, v5, v10
	v_lshl_add_u64 v[8:9], v[2:3], 2, s[0:1]
	global_load_dword v2, v[8:9], off
	v_add_u32_e32 v10, 1, v10
	v_max_f32_e32 v6, v6, v6
	v_cmp_eq_u32_e32 vcc, 32, v10
	s_or_b64 s[4:5], vcc, s[4:5]
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v2, v2, v2
	v_max_f32_e32 v6, v6, v2
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execnz .LBB6_4
; %bb.5:
	s_or_b64 exec, exec, s[4:5]
	v_mov_b32_e32 v2, 0
	s_mov_b64 s[4:5], 0
.LBB6_6:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[8:9], v[0:1], 0, s[4:5]
	global_load_dword v3, v[8:9], off
	s_add_u32 s4, s4, 4
	s_addc_u32 s5, s5, 0
	s_cmpk_eq_i32 s4, 0x80
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v3, v3, v6
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v3
	s_nop 0
	v_add_f32_e32 v2, v2, v3
	s_cbranch_scc0 .LBB6_6
; %bb.7:
	global_load_dword v0, v4, s[0:1]
	v_rcp_f32_e32 v1, v2
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v0, v0, v6
	v_mul_f32_e32 v0, 0x3fb8aa3b, v0
	v_exp_f32_e32 v0, v0
	s_nop 0
	v_mul_f32_e32 v0, v1, v0
	global_store_dword v4, v0, s[2:3]
.LBB6_8:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_softmax
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
		.amdhsa_next_free_vgpr 15
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 16
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
	.size	portable_softmax, .Lfunc_end6-portable_softmax
                                        ; -- End function
	.set portable_softmax.num_vgpr, 15
	.set portable_softmax.num_agpr, 0
	.set portable_softmax.numbered_sgpr, 12
	.set portable_softmax.num_named_barrier, 0
	.set portable_softmax.private_seg_size, 0
	.set portable_softmax.uses_vcc, 1
	.set portable_softmax.uses_flat_scratch, 0
	.set portable_softmax.has_dyn_sized_stack, 0
	.set portable_softmax.has_recursion, 0
	.set portable_softmax.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 460
; TotalNumSgprs: 18
; NumVgprs: 15
; NumAgprs: 0
; TotalNumVgprs: 15
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 15
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_rmsnorm        ; -- Begin function portable_rmsnorm
	.globl	portable_rmsnorm
	.p2align	8
	.type	portable_rmsnorm,@function
portable_rmsnorm:                       ; @portable_rmsnorm
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB7_4
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v4, 2, v0
	v_mov_b32_e32 v1, 0
	v_and_b32_e32 v0, 0x80, v4
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
	s_mov_b64 s[0:1], 0
.LBB7_2:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[2:3], 0, s[0:1]
	global_load_dword v0, v[6:7], off
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmpk_eq_i32 s0, 0x80
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, v0, v0
	s_cbranch_scc0 .LBB7_2
; %bb.3:
	global_load_dword v0, v4, s[4:5]
	global_load_dword v2, v4, s[6:7]
	v_mov_b32_e32 v3, 0x358637bd
	v_fmac_f32_e32 v3, 0x3d000000, v1
	v_rsq_f32_e32 v1, v3
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v0, v0, v2
	v_mul_f32_e32 v0, v1, v0
	global_store_dword v4, v0, s[2:3]
.LBB7_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_rmsnorm
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
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
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
	.size	portable_rmsnorm, .Lfunc_end7-portable_rmsnorm
                                        ; -- End function
	.set portable_rmsnorm.num_vgpr, 8
	.set portable_rmsnorm.num_agpr, 0
	.set portable_rmsnorm.numbered_sgpr, 8
	.set portable_rmsnorm.num_named_barrier, 0
	.set portable_rmsnorm.private_seg_size, 0
	.set portable_rmsnorm.uses_vcc, 1
	.set portable_rmsnorm.uses_flat_scratch, 0
	.set portable_rmsnorm.has_dyn_sized_stack, 0
	.set portable_rmsnorm.has_recursion, 0
	.set portable_rmsnorm.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 160
; TotalNumSgprs: 14
; NumVgprs: 8
; NumAgprs: 0
; TotalNumVgprs: 8
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 8
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
	.protected	portable_matvec         ; -- Begin function portable_matvec
	.globl	portable_matvec
	.p2align	8
	.type	portable_matvec,@function
portable_matvec:                        ; @portable_matvec
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB8_4
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_mov_b32_e32 v3, 0
	v_lshlrev_b32_e32 v2, 7, v0
	s_mov_b64 s[0:1], 0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
.LBB8_2:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[4:5], 0, s[0:1]
	global_load_dword v1, v[6:7], off
	s_add_u32 s4, s6, s0
	s_addc_u32 s5, s7, s1
	s_load_dword s4, s[4:5], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmpk_eq_i32 s0, 0x80
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v3, s4, v1
	s_cbranch_scc0 .LBB8_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB8_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_matvec
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
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
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
	.size	portable_matvec, .Lfunc_end8-portable_matvec
                                        ; -- End function
	.set portable_matvec.num_vgpr, 8
	.set portable_matvec.num_agpr, 0
	.set portable_matvec.numbered_sgpr, 8
	.set portable_matvec.num_named_barrier, 0
	.set portable_matvec.private_seg_size, 0
	.set portable_matvec.uses_vcc, 1
	.set portable_matvec.uses_flat_scratch, 0
	.set portable_matvec.has_dyn_sized_stack, 0
	.set portable_matvec.has_recursion, 0
	.set portable_matvec.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 124
; TotalNumSgprs: 14
; NumVgprs: 8
; NumAgprs: 0
; TotalNumVgprs: 8
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 8
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
	.protected	portable_gemm           ; -- Begin function portable_gemm
	.globl	portable_gemm
	.p2align	8
	.type	portable_gemm,@function
portable_gemm:                          ; @portable_gemm
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB9_4
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v1, 3, v0
	v_mov_b32_e32 v3, 0
	v_and_b32_e32 v2, 0xc0, v1
	v_and_b32_e32 v1, 7, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	v_lshlrev_b32_e32 v2, 2, v1
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[2:3]
	s_mov_b64 s[0:1], 0
.LBB9_2:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[8:9], v[4:5], 0, s[0:1]
	global_load_dword v1, v[6:7], off
	global_load_dword v2, v[8:9], off
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	v_lshl_add_u64 v[6:7], v[6:7], 0, 32
	s_cmp_eq_u32 s0, 64
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v3, v2, v1
	s_cbranch_scc0 .LBB9_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB9_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_gemm
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
		.amdhsa_next_free_vgpr 10
		.amdhsa_next_free_sgpr 8
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
.Lfunc_end9:
	.size	portable_gemm, .Lfunc_end9-portable_gemm
                                        ; -- End function
	.set portable_gemm.num_vgpr, 10
	.set portable_gemm.num_agpr, 0
	.set portable_gemm.numbered_sgpr, 8
	.set portable_gemm.num_named_barrier, 0
	.set portable_gemm.private_seg_size, 0
	.set portable_gemm.uses_vcc, 1
	.set portable_gemm.uses_flat_scratch, 0
	.set portable_gemm.has_dyn_sized_stack, 0
	.set portable_gemm.has_recursion, 0
	.set portable_gemm.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 148
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
	.protected	portable_gemm_add_silu  ; -- Begin function portable_gemm_add_silu
	.globl	portable_gemm_add_silu
	.p2align	8
	.type	portable_gemm_add_silu,@function
portable_gemm_add_silu:                 ; @portable_gemm_add_silu
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB10_4
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 3, v0
	v_mov_b32_e32 v3, 0
	v_and_b32_e32 v6, 7, v0
	v_and_b32_e32 v2, 0xc0, v1
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	v_lshlrev_b32_e32 v2, 2, v6
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[2:3]
	s_mov_b64 s[0:1], 0
.LBB10_2:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[8:9], v[4:5], 0, s[0:1]
	global_load_dword v1, v[6:7], off
	global_load_dword v2, v[8:9], off
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	v_lshl_add_u64 v[6:7], v[6:7], 0, 32
	s_cmp_eq_u32 s0, 64
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v3, v2, v1
	s_cbranch_scc0 .LBB10_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_load_dword v1, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v1, v3, v1
	v_mul_f32_e32 v2, 0xbfb8aa3b, v1
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v2, v2
	s_nop 0
	v_mul_f32_e32 v1, v1, v2
	global_store_dword v0, v1, s[10:11]
.LBB10_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_gemm_add_silu
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
		.amdhsa_next_free_vgpr 10
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
.Lfunc_end10:
	.size	portable_gemm_add_silu, .Lfunc_end10-portable_gemm_add_silu
                                        ; -- End function
	.set portable_gemm_add_silu.num_vgpr, 10
	.set portable_gemm_add_silu.num_agpr, 0
	.set portable_gemm_add_silu.numbered_sgpr, 12
	.set portable_gemm_add_silu.num_named_barrier, 0
	.set portable_gemm_add_silu.private_seg_size, 0
	.set portable_gemm_add_silu.uses_vcc, 1
	.set portable_gemm_add_silu.uses_flat_scratch, 0
	.set portable_gemm_add_silu.has_dyn_sized_stack, 0
	.set portable_gemm_add_silu.has_recursion, 0
	.set portable_gemm_add_silu.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 188
; TotalNumSgprs: 18
; NumVgprs: 10
; NumAgprs: 0
; TotalNumVgprs: 10
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 18
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
	.protected	portable_bitdelta       ; -- Begin function portable_bitdelta
	.globl	portable_bitdelta
	.p2align	8
	.type	portable_bitdelta,@function
portable_bitdelta:                      ; @portable_bitdelta
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB11_4
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v1, 1, v0
	v_and_b32_e32 v1, 0x7fc, v1
	v_and_b32_e32 v2, 1, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v1, s[6:7]
	v_lshlrev_b32_e32 v2, 7, v2
	v_mov_b32_e32 v3, 0
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	s_mov_b32 s0, 0
.LBB11_2:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v2, v[4:5], off
	s_waitcnt vmcnt(1)
	v_bfe_u32 v6, v1, s0, 1
	v_cmp_eq_u32_e32 vcc, 0, v6
	s_add_i32 s0, s0, 1
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	s_cmp_eq_u32 s0, 32
	s_waitcnt vmcnt(0)
	v_cndmask_b32_e64 v2, v2, -v2, vcc
	v_add_f32_e32 v3, v3, v2
	s_cbranch_scc0 .LBB11_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB11_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_bitdelta
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
		.amdhsa_next_free_vgpr 7
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
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
.Lfunc_end11:
	.size	portable_bitdelta, .Lfunc_end11-portable_bitdelta
                                        ; -- End function
	.set portable_bitdelta.num_vgpr, 7
	.set portable_bitdelta.num_agpr, 0
	.set portable_bitdelta.numbered_sgpr, 8
	.set portable_bitdelta.num_named_barrier, 0
	.set portable_bitdelta.private_seg_size, 0
	.set portable_bitdelta.uses_vcc, 1
	.set portable_bitdelta.uses_flat_scratch, 0
	.set portable_bitdelta.has_dyn_sized_stack, 0
	.set portable_bitdelta.has_recursion, 0
	.set portable_bitdelta.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 152
; TotalNumSgprs: 14
; NumVgprs: 7
; NumAgprs: 0
; TotalNumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 7
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
	.protected	portable_bitdelta_batched ; -- Begin function portable_bitdelta_batched
	.globl	portable_bitdelta_batched
	.p2align	8
	.type	portable_bitdelta_batched,@function
portable_bitdelta_batched:              ; @portable_bitdelta_batched
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB12_4
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v1, 1, v0
	v_lshrrev_b32_e32 v2, 3, v0
	v_and_b32_e32 v1, 12, v1
	v_lshl_or_b32 v1, v2, 4, v1
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v1, s[6:7]
	v_lshlrev_b32_e32 v3, 7, v0
	v_and_b32_e32 v3, 0x80, v3
	v_lshl_or_b32 v2, v2, 8, v3
	v_mov_b32_e32 v3, 0
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	s_mov_b32 s0, 0
.LBB12_2:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v2, v[4:5], off
	s_waitcnt vmcnt(1)
	v_bfe_u32 v6, v1, s0, 1
	v_cmp_eq_u32_e32 vcc, 0, v6
	s_add_i32 s0, s0, 1
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	s_cmp_eq_u32 s0, 32
	s_waitcnt vmcnt(0)
	v_cndmask_b32_e64 v2, v2, -v2, vcc
	v_add_f32_e32 v3, v3, v2
	s_cbranch_scc0 .LBB12_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB12_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_bitdelta_batched
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
		.amdhsa_next_free_vgpr 7
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
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
.Lfunc_end12:
	.size	portable_bitdelta_batched, .Lfunc_end12-portable_bitdelta_batched
                                        ; -- End function
	.set portable_bitdelta_batched.num_vgpr, 7
	.set portable_bitdelta_batched.num_agpr, 0
	.set portable_bitdelta_batched.numbered_sgpr, 8
	.set portable_bitdelta_batched.num_named_barrier, 0
	.set portable_bitdelta_batched.private_seg_size, 0
	.set portable_bitdelta_batched.uses_vcc, 1
	.set portable_bitdelta_batched.uses_flat_scratch, 0
	.set portable_bitdelta_batched.has_dyn_sized_stack, 0
	.set portable_bitdelta_batched.has_recursion, 0
	.set portable_bitdelta_batched.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 172
; TotalNumSgprs: 14
; NumVgprs: 7
; NumAgprs: 0
; TotalNumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 7
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
	.protected	portable_convolution    ; -- Begin function portable_convolution
	.globl	portable_convolution
	.p2align	8
	.type	portable_convolution,@function
portable_convolution:                   ; @portable_convolution
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 18, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB13_8
; %bb.1:
	v_mul_u32_u24_e32 v1, 0x5556, v0
	v_mov_b32_e32 v2, 3
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_mul_lo_u16_sdwa v1, v1, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_1 src1_sel:DWORD
	s_mov_b32 s0, 0x55555556
	v_sub_u16_e32 v2, v0, v1
	v_mul_hi_u32 v3, v0, s0
	s_mov_b32 s0, 0x1c71c71d
	v_mad_u32_u24 v2, v3, 5, v2
	v_mul_hi_u32 v3, v0, s0
	v_cmp_lt_u32_e32 vcc, 8, v0
	v_mul_u32_u24_e32 v3, 15, v3
	s_mov_b32 s10, 0
	v_cndmask_b32_e64 v1, 0, 2, vcc
	v_sub_u32_e32 v2, v2, v3
	v_mov_b32_e32 v5, 0
	s_mov_b64 s[8:9], -1
	v_mov_b32_e32 v3, 0
.LBB13_2:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB13_3 Depth 2
                                        ;       Child Loop BB13_4 Depth 3
	v_or_b32_e32 v4, s10, v1
	v_mul_u32_u24_e32 v4, 3, v4
	s_xor_b64 s[0:1], s[8:9], -1
	v_mul_lo_u32 v4, v4, 12
	v_mad_u64_u32 v[8:9], s[8:9], s10, 25, v[2:3]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[4:5]
	v_mov_b32_e32 v4, v8
	s_mov_b32 s10, 0
.LBB13_3:                               ;   Parent Loop BB13_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB13_4 Depth 3
	v_lshl_add_u64 v[8:9], v[4:5], 2, s[4:5]
	s_mov_b64 s[8:9], 0
.LBB13_4:                               ;   Parent Loop BB13_2 Depth=1
                                        ;     Parent Loop BB13_3 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	v_lshl_add_u64 v[10:11], v[8:9], 0, s[8:9]
	v_lshl_add_u64 v[12:13], v[6:7], 0, s[8:9]
	global_load_dword v14, v[10:11], off
	global_load_dword v15, v[12:13], off
	s_add_u32 s8, s8, 4
	s_addc_u32 s9, s9, 0
	s_cmp_eq_u32 s8, 12
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v3, v14, v15
	s_cbranch_scc0 .LBB13_4
; %bb.5:                                ;   in Loop: Header=BB13_3 Depth=2
	s_add_i32 s10, s10, 1
	v_lshl_add_u64 v[6:7], v[6:7], 0, 12
	s_cmp_eq_u32 s10, 3
	v_add_u32_e32 v4, 5, v4
	s_cbranch_scc0 .LBB13_3
; %bb.6:                                ;   in Loop: Header=BB13_2 Depth=1
	s_mov_b32 s10, 1
	s_mov_b64 s[8:9], 0
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB13_2
; %bb.7:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB13_8:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_convolution
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
		.amdhsa_next_free_vgpr 16
		.amdhsa_next_free_sgpr 11
		.amdhsa_accum_offset 16
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
.Lfunc_end13:
	.size	portable_convolution, .Lfunc_end13-portable_convolution
                                        ; -- End function
	.set portable_convolution.num_vgpr, 16
	.set portable_convolution.num_agpr, 0
	.set portable_convolution.numbered_sgpr, 11
	.set portable_convolution.num_named_barrier, 0
	.set portable_convolution.private_seg_size, 0
	.set portable_convolution.uses_vcc, 1
	.set portable_convolution.uses_flat_scratch, 0
	.set portable_convolution.has_dyn_sized_stack, 0
	.set portable_convolution.has_recursion, 0
	.set portable_convolution.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 300
; TotalNumSgprs: 17
; NumVgprs: 16
; NumAgprs: 0
; TotalNumVgprs: 16
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 17
; NumVGPRsForWavesPerEU: 16
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_mamba_state    ; -- Begin function portable_mamba_state
	.globl	portable_mamba_state
	.p2align	8
	.type	portable_mamba_state,@function
portable_mamba_state:                   ; @portable_mamba_state
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB14_4
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x20
	v_and_b32_e32 v1, 3, v0
	v_lshlrev_b32_e32 v2, 2, v1
	v_mov_b32_e32 v3, 0
	s_waitcnt lgkmcnt(0)
	s_load_dword s12, s[10:11], 0x1c
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[2:3]
	v_and_b32_e32 v2, 0x3fc, v0
	v_lshl_add_u64 v[6:7], s[4:5], 0, v[2:3]
	s_mov_b64 s[0:1], 0
.LBB14_2:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v1, v[6:7], off
	global_load_dword v2, v[4:5], off
	s_add_u32 s4, s8, s0
	s_addc_u32 s5, s9, s1
	s_add_u32 s6, s10, s0
	s_addc_u32 s7, s11, s1
	s_load_dword s6, s[6:7], 0x0
	s_add_u32 s0, s0, 4
	s_load_dword s4, s[4:5], 0x0
	s_addc_u32 s1, s1, 0
	v_lshl_add_u64 v[4:5], v[4:5], 0, 16
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v8, s6
	v_sub_f32_e32 v8, s12, v8
	v_min_f32_e32 v8, 0, v8
	v_mul_f32_e32 v8, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v8
	v_lshl_add_u64 v[6:7], v[6:7], 0, 16
	s_cmp_eq_u32 s0, 32
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, v1, v2
	v_mul_f32_e32 v1, s4, v1
	v_fmac_f32_e32 v3, v1, v8
	s_cbranch_scc0 .LBB14_2
; %bb.3:
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v0, v3, s[2:3]
.LBB14_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_mamba_state
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
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
		.amdhsa_next_free_sgpr 13
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
.Lfunc_end14:
	.size	portable_mamba_state, .Lfunc_end14-portable_mamba_state
                                        ; -- End function
	.set portable_mamba_state.num_vgpr, 9
	.set portable_mamba_state.num_agpr, 0
	.set portable_mamba_state.numbered_sgpr, 13
	.set portable_mamba_state.num_named_barrier, 0
	.set portable_mamba_state.private_seg_size, 0
	.set portable_mamba_state.uses_vcc, 1
	.set portable_mamba_state.uses_flat_scratch, 0
	.set portable_mamba_state.has_dyn_sized_stack, 0
	.set portable_mamba_state.has_recursion, 0
	.set portable_mamba_state.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 220
; TotalNumSgprs: 19
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
; NumSGPRsForWavesPerEU: 19
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
	.protected	portable_mamba_scan     ; -- Begin function portable_mamba_scan
	.globl	portable_mamba_scan
	.p2align	8
	.type	portable_mamba_scan,@function
portable_mamba_scan:                    ; @portable_mamba_scan
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB15_6
; %bb.1:
	s_load_dwordx16 s[4:19], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 2, v0
	v_mov_b32_e32 v3, 0
	v_and_b32_e32 v4, 3, v0
	v_and_b32_e32 v2, 16, v1
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[6:7], s[8:9], 0, v[2:3]
	v_lshlrev_b32_e32 v2, 4, v4
	v_lshl_add_u64 v[8:9], s[10:11], 0, v[2:3]
	s_mov_b64 s[0:1], 0
.LBB15_2:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[10:11], v[6:7], 0, s[0:1]
	v_lshl_add_u64 v[12:13], v[8:9], 0, s[0:1]
	global_load_dword v1, v[10:11], off
	global_load_dword v2, v[12:13], off
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_eq_u32 s0, 16
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v3, v1, v2
	s_cbranch_scc0 .LBB15_2
; %bb.3:
	v_and_b32_e32 v1, 0x3fc, v0
	global_load_dword v1, v1, s[14:15]
	v_lshlrev_b32_e32 v4, 2, v4
	v_mov_b32_e32 v5, 0
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[4:5]
	v_and_b32_e32 v4, 0x1fe0, v2
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[4:5]
	s_mov_b64 s[0:1], 0
.LBB15_4:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[10:11], v[8:9], 0, s[0:1]
	global_load_dword v2, v[10:11], off
	global_load_dword v4, v[6:7], off
	s_add_u32 s2, s14, s0
	s_addc_u32 s3, s15, s1
	s_load_dword s4, s[2:3], 0x0
	s_add_u32 s2, s12, s0
	s_addc_u32 s3, s13, s1
	s_load_dword s2, s[2:3], 0x0
	s_add_u32 s0, s0, 4
	s_waitcnt vmcnt(2) lgkmcnt(0)
	v_subrev_f32_e32 v10, s4, v1
	v_min_f32_e32 v10, 0, v10
	v_mul_f32_e32 v10, 0x3fb8aa3b, v10
	v_exp_f32_e32 v10, v10
	s_addc_u32 s1, s1, 0
	v_lshl_add_u64 v[6:7], v[6:7], 0, 16
	s_cmp_eq_u32 s0, 32
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v2, v2, v10
	v_mul_f32_e32 v2, s2, v2
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v5, v4, v2
	s_cbranch_scc0 .LBB15_4
; %bb.5:
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v1
	v_lshlrev_b32_e32 v0, 2, v0
	v_mov_b32_e32 v2, 0
	v_fmac_f32_e32 v5, v3, v1
	global_store_dword v0, v5, s[16:17]
	global_store_dword v0, v2, s[18:19]
.LBB15_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_mamba_scan
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
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
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 20
		.amdhsa_accum_offset 16
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
.Lfunc_end15:
	.size	portable_mamba_scan, .Lfunc_end15-portable_mamba_scan
                                        ; -- End function
	.set portable_mamba_scan.num_vgpr, 14
	.set portable_mamba_scan.num_agpr, 0
	.set portable_mamba_scan.numbered_sgpr, 20
	.set portable_mamba_scan.num_named_barrier, 0
	.set portable_mamba_scan.private_seg_size, 0
	.set portable_mamba_scan.uses_vcc, 1
	.set portable_mamba_scan.uses_flat_scratch, 0
	.set portable_mamba_scan.has_dyn_sized_stack, 0
	.set portable_mamba_scan.has_recursion, 0
	.set portable_mamba_scan.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 344
; TotalNumSgprs: 26
; NumVgprs: 14
; NumAgprs: 0
; TotalNumVgprs: 14
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 14
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_flash_attention ; -- Begin function portable_flash_attention
	.globl	portable_flash_attention
	.p2align	8
	.type	portable_flash_attention,@function
portable_flash_attention:               ; @portable_flash_attention
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB16_13
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x20
	v_lshlrev_b32_e32 v1, 2, v0
	v_mov_b32_e32 v5, 0
	v_and_b32_e32 v4, 16, v1
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[4:5]
	s_mov_b64 s[0:1], 0
.LBB16_2:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[2:3], 0, s[0:1]
	global_load_dword v4, v[6:7], off
	s_add_u32 s4, s6, s0
	s_addc_u32 s5, s7, s1
	s_load_dword s4, s[4:5], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v5, s4, v4
	s_cbranch_scc1 .LBB16_2
; %bb.3:
	s_add_u32 s4, s6, 16
	v_mul_f32_e32 v8, 0x3e000000, v5
	s_addc_u32 s5, s7, 0
	s_mov_b32 s12, 1
.LBB16_4:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_5 Depth 2
	v_mov_b32_e32 v4, 0
	s_mov_b64 s[0:1], 0
.LBB16_5:                               ;   Parent Loop BB16_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_lshl_add_u64 v[6:7], v[2:3], 0, s[0:1]
	global_load_dword v5, v[6:7], off
	s_add_u32 s14, s4, s0
	s_addc_u32 s15, s5, s1
	s_load_dword s13, s[14:15], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v4, s13, v5
	s_cbranch_scc1 .LBB16_5
; %bb.6:                                ;   in Loop: Header=BB16_4 Depth=1
	s_add_i32 s12, s12, 1
	s_add_u32 s4, s4, 16
	v_mul_f32_e32 v4, 0x3e000000, v4
	v_max_f32_e32 v5, v8, v8
	s_addc_u32 s5, s5, 0
	s_cmp_lg_u32 s12, 8
	v_max_f32_e32 v8, v5, v4
	s_cbranch_scc1 .LBB16_4
; %bb.7:
	v_mov_b32_e32 v7, 0
	v_and_b32_e32 v9, 3, v0
	s_mov_b32 s4, 0
	s_mov_b32 s5, 0x3e000000
	v_mov_b32_e32 v4, v7
	v_mov_b32_e32 v5, v7
.LBB16_8:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_9 Depth 2
	s_mov_b64 s[0:1], 0
	v_mov_b32_e32 v10, 0
.LBB16_9:                               ;   Parent Loop BB16_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_lshl_add_u64 v[12:13], v[2:3], 0, s[0:1]
	global_load_dword v6, v[12:13], off
	s_add_u32 s12, s6, s0
	s_addc_u32 s13, s7, s1
	s_load_dword s12, s[12:13], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v10, s12, v6
	s_cbranch_scc1 .LBB16_9
; %bb.10:                               ;   in Loop: Header=BB16_8 Depth=1
	v_lshl_or_b32 v6, s4, 2, v9
	v_lshl_add_u64 v[12:13], v[6:7], 2, s[8:9]
	global_load_dword v6, v[12:13], off
	v_fma_f32 v10, v10, s5, -v8
	v_mul_f32_e32 v10, 0x3fb8aa3b, v10
	v_exp_f32_e32 v11, v10
	s_add_i32 s4, s4, 1
	s_add_u32 s6, s6, 16
	s_addc_u32 s7, s7, 0
	s_cmp_eq_u32 s4, 8
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v10, v11, v6
	v_pk_add_f32 v[4:5], v[4:5], v[10:11]
	s_cbranch_scc0 .LBB16_8
; %bb.11:
	v_rcp_f32_e32 v2, v5
	v_cmp_eq_u32_e32 vcc, 0, v9
	v_mul_f32_e32 v2, v2, v4
	global_store_dword v1, v2, s[10:11]
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB16_13
; %bb.12:
	v_log_f32_e32 v1, v5
	v_and_b32_e32 v0, 0x3fc, v0
	v_fmamk_f32 v1, v1, 0x3f317218, v8
	v_add_f32_e32 v1, 0, v1
	global_store_dword v0, v1, s[2:3]
.LBB16_13:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_flash_attention
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
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
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 16
		.amdhsa_accum_offset 16
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
.Lfunc_end16:
	.size	portable_flash_attention, .Lfunc_end16-portable_flash_attention
                                        ; -- End function
	.set portable_flash_attention.num_vgpr, 14
	.set portable_flash_attention.num_agpr, 0
	.set portable_flash_attention.numbered_sgpr, 16
	.set portable_flash_attention.num_named_barrier, 0
	.set portable_flash_attention.private_seg_size, 0
	.set portable_flash_attention.uses_vcc, 1
	.set portable_flash_attention.uses_flat_scratch, 0
	.set portable_flash_attention.has_dyn_sized_stack, 0
	.set portable_flash_attention.has_recursion, 0
	.set portable_flash_attention.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 468
; TotalNumSgprs: 22
; NumVgprs: 14
; NumAgprs: 0
; TotalNumVgprs: 14
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 14
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_forgetting_attention ; -- Begin function portable_forgetting_attention
	.globl	portable_forgetting_attention
	.p2align	8
	.type	portable_forgetting_attention,@function
portable_forgetting_attention:          ; @portable_forgetting_attention
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB17_13
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx4 s[12:15], s[0:1], 0x20
	v_lshlrev_b32_e32 v1, 2, v0
	v_mov_b32_e32 v5, 0
	v_and_b32_e32 v4, 16, v1
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[4:5]
	s_mov_b64 s[0:1], 0
.LBB17_2:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[2:3], 0, s[0:1]
	global_load_dword v4, v[6:7], off
	s_add_u32 s2, s6, s0
	s_addc_u32 s3, s7, s1
	s_load_dword s2, s[2:3], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v5, s2, v4
	s_cbranch_scc1 .LBB17_2
; %bb.3:
	s_load_dword s1, s[10:11], 0x0
	s_mov_b32 s4, 0x3e000000
	s_add_u32 s5, s6, 16
	s_mov_b32 s0, 1
	s_addc_u32 s16, s7, 0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v4, s1
	v_fma_f32 v8, v5, s4, -v4
	s_mov_b32 s1, 0
.LBB17_4:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_5 Depth 2
	v_mov_b32_e32 v4, 0
	s_mov_b64 s[2:3], 0
.LBB17_5:                               ;   Parent Loop BB17_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_lshl_add_u64 v[6:7], v[2:3], 0, s[2:3]
	global_load_dword v5, v[6:7], off
	s_add_u32 s18, s5, s2
	s_addc_u32 s19, s16, s3
	s_load_dword s17, s[18:19], 0x0
	s_add_u32 s2, s2, 4
	s_addc_u32 s3, s3, 0
	s_cmp_lg_u32 s2, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v4, s17, v5
	s_cbranch_scc1 .LBB17_5
; %bb.6:                                ;   in Loop: Header=BB17_4 Depth=1
	s_lshl_b64 s[2:3], s[0:1], 2
	s_add_u32 s2, s10, s2
	s_addc_u32 s3, s11, s3
	s_load_dword s2, s[2:3], 0x0
	s_add_i32 s0, s0, 1
	s_add_u32 s5, s5, 16
	v_max_f32_e32 v5, v8, v8
	s_addc_u32 s16, s16, 0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v6, s2
	v_fma_f32 v4, v4, s4, -v6
	s_cmp_lg_u32 s0, 8
	v_max_f32_e32 v8, v5, v4
	s_cbranch_scc1 .LBB17_4
; %bb.7:
	v_mov_b32_e32 v7, 0
	v_and_b32_e32 v9, 3, v0
	s_mov_b32 s0, 0
	s_mov_b32 s1, 0
	s_mov_b32 s4, 0x3e000000
	v_mov_b32_e32 v4, v7
	v_mov_b32_e32 v5, v7
.LBB17_8:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_9 Depth 2
	s_mov_b64 s[2:3], 0
	v_mov_b32_e32 v10, 0
.LBB17_9:                               ;   Parent Loop BB17_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_lshl_add_u64 v[12:13], v[2:3], 0, s[2:3]
	global_load_dword v6, v[12:13], off
	s_add_u32 s16, s6, s2
	s_addc_u32 s17, s7, s3
	s_load_dword s5, s[16:17], 0x0
	s_add_u32 s2, s2, 4
	s_addc_u32 s3, s3, 0
	s_cmp_lg_u32 s2, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v10, s5, v6
	s_cbranch_scc1 .LBB17_9
; %bb.10:                               ;   in Loop: Header=BB17_8 Depth=1
	v_lshl_or_b32 v6, s0, 2, v9
	v_lshl_add_u64 v[12:13], v[6:7], 2, s[8:9]
	global_load_dword v6, v[12:13], off
	s_lshl_b64 s[2:3], s[0:1], 2
	s_add_u32 s2, s10, s2
	s_addc_u32 s3, s11, s3
	s_load_dword s2, s[2:3], 0x0
	s_add_i32 s0, s0, 1
	s_add_u32 s6, s6, 16
	s_addc_u32 s7, s7, 0
	s_cmp_eq_u32 s0, 8
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v11, s2
	v_fma_f32 v10, v10, s4, -v11
	v_sub_f32_e32 v10, v10, v8
	v_mul_f32_e32 v10, 0x3fb8aa3b, v10
	v_exp_f32_e32 v11, v10
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v10, v6, v11
	v_pk_add_f32 v[4:5], v[4:5], v[10:11]
	s_cbranch_scc0 .LBB17_8
; %bb.11:
	v_rcp_f32_e32 v2, v5
	v_cmp_eq_u32_e32 vcc, 0, v9
	v_mul_f32_e32 v2, v4, v2
	global_store_dword v1, v2, s[12:13]
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB17_13
; %bb.12:
	v_and_b32_e32 v0, 0x3fc, v0
	global_load_dword v1, v0, s[10:11]
	v_log_f32_e32 v2, v5
	s_nop 0
	v_fmamk_f32 v2, v2, 0x3f317218, v8
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v1, v2, v1
	global_store_dword v0, v1, s[14:15]
.LBB17_13:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_forgetting_attention
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
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
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 20
		.amdhsa_accum_offset 16
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
.Lfunc_end17:
	.size	portable_forgetting_attention, .Lfunc_end17-portable_forgetting_attention
                                        ; -- End function
	.set portable_forgetting_attention.num_vgpr, 14
	.set portable_forgetting_attention.num_agpr, 0
	.set portable_forgetting_attention.numbered_sgpr, 20
	.set portable_forgetting_attention.num_named_barrier, 0
	.set portable_forgetting_attention.private_seg_size, 0
	.set portable_forgetting_attention.uses_vcc, 1
	.set portable_forgetting_attention.uses_flat_scratch, 0
	.set portable_forgetting_attention.has_dyn_sized_stack, 0
	.set portable_forgetting_attention.has_recursion, 0
	.set portable_forgetting_attention.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 576
; TotalNumSgprs: 26
; NumVgprs: 14
; NumAgprs: 0
; TotalNumVgprs: 14
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 14
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	portable_sage_attention ; -- Begin function portable_sage_attention
	.globl	portable_sage_attention
	.p2align	8
	.type	portable_sage_attention,@function
portable_sage_attention:                ; @portable_sage_attention
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB18_12
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx4 s[12:15], s[0:1], 0x20
	v_lshlrev_b32_e32 v6, 2, v0
	v_mov_b32_e32 v5, 0
	v_and_b32_e32 v4, 16, v6
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[4:5]
	s_mov_b64 s[0:1], 0
.LBB18_2:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[8:9], v[2:3], 0, s[0:1]
	global_load_dword v1, v[8:9], off
	s_add_u32 s2, s6, s0
	s_addc_u32 s3, s7, s1
	s_load_dword s2, s[2:3], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v5, s2, v1
	s_cbranch_scc1 .LBB18_2
; %bb.3:
	s_load_dword s2, s[10:11], 0x0
	s_load_dword s0, s[12:13], 0x0
	s_add_u32 s3, s6, 16
	s_addc_u32 s4, s7, 0
	s_mov_b32 s5, 1
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v1, s2, v5
	v_mul_f32_e32 v7, s0, v1
.LBB18_4:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB18_5 Depth 2
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[0:1], 0
.LBB18_5:                               ;   Parent Loop BB18_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_lshl_add_u64 v[4:5], v[2:3], 0, s[0:1]
	global_load_dword v4, v[4:5], off
	s_add_u32 s10, s3, s0
	s_addc_u32 s11, s4, s1
	s_load_dword s10, s[10:11], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v1, s10, v4
	s_cbranch_scc1 .LBB18_5
; %bb.6:                                ;   in Loop: Header=BB18_4 Depth=1
	s_and_b32 s0, s5, -4
	s_load_dword s0, s[12:13], s0 offset:0x0
	s_add_i32 s5, s5, 1
	v_mul_f32_e32 v1, s2, v1
	s_add_u32 s3, s3, 16
	v_max_f32_e32 v4, v7, v7
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v1, s0, v1
	s_addc_u32 s4, s4, 0
	s_cmp_lg_u32 s5, 8
	v_max_f32_e32 v7, v4, v1
	s_cbranch_scc1 .LBB18_4
; %bb.7:
	v_mov_b32_e32 v5, 0
	v_and_b32_e32 v8, 3, v0
	s_mov_b32 s3, 0
	v_mov_b32_e32 v0, v5
	v_mov_b32_e32 v1, v5
.LBB18_8:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB18_9 Depth 2
	s_mov_b64 s[0:1], 0
	v_mov_b32_e32 v9, 0
.LBB18_9:                               ;   Parent Loop BB18_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_lshl_add_u64 v[10:11], v[2:3], 0, s[0:1]
	global_load_dword v4, v[10:11], off
	s_add_u32 s4, s6, s0
	s_addc_u32 s5, s7, s1
	s_load_dword s4, s[4:5], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v9, s4, v4
	s_cbranch_scc1 .LBB18_9
; %bb.10:                               ;   in Loop: Header=BB18_8 Depth=1
	v_lshl_or_b32 v4, s3, 2, v8
	v_lshl_add_u64 v[10:11], v[4:5], 2, s[8:9]
	global_load_dword v4, v[10:11], off
	s_and_b32 s0, s3, -4
	s_load_dword s0, s[12:13], s0 offset:0x0
	v_mul_f32_e32 v9, s2, v9
	s_add_i32 s3, s3, 1
	s_add_u32 s6, s6, 16
	s_addc_u32 s7, s7, 0
	s_waitcnt lgkmcnt(0)
	v_fma_f32 v9, v9, s0, -v7
	v_mul_f32_e32 v9, 0x3fb8aa3b, v9
	v_exp_f32_e32 v11, v9
	s_cmp_eq_u32 s3, 8
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v10, v4, v11
	v_pk_add_f32 v[0:1], v[0:1], v[10:11]
	s_cbranch_scc0 .LBB18_8
; %bb.11:
	v_rcp_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v0, v0, v1
	global_store_dword v6, v0, s[14:15]
.LBB18_12:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_sage_attention
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
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
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 16
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
.Lfunc_end18:
	.size	portable_sage_attention, .Lfunc_end18-portable_sage_attention
                                        ; -- End function
	.set portable_sage_attention.num_vgpr, 12
	.set portable_sage_attention.num_agpr, 0
	.set portable_sage_attention.numbered_sgpr, 16
	.set portable_sage_attention.num_named_barrier, 0
	.set portable_sage_attention.private_seg_size, 0
	.set portable_sage_attention.uses_vcc, 1
	.set portable_sage_attention.uses_flat_scratch, 0
	.set portable_sage_attention.has_dyn_sized_stack, 0
	.set portable_sage_attention.has_recursion, 0
	.set portable_sage_attention.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 476
; TotalNumSgprs: 22
; NumVgprs: 12
; NumAgprs: 0
; TotalNumVgprs: 12
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 12
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
	.protected	portable_sinkhorn       ; -- Begin function portable_sinkhorn
	.globl	portable_sinkhorn
	.p2align	8
	.type	portable_sinkhorn,@function
portable_sinkhorn:                      ; @portable_sinkhorn
; %bb.0:
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB19_18
; %bb.1:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx4 s[12:15], s[0:1], 0x20
	v_mov_b32_e32 v3, 0
	v_lshlrev_b32_e32 v2, 4, v0
	s_mov_b64 s[0:1], 0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
.LBB19_2:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[4:5], 0, s[0:1]
	global_load_dword v1, v[6:7], off
	s_add_u32 s2, s6, s0
	s_addc_u32 s3, s7, s1
	s_load_dword s2, s[2:3], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_eq_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v3, s2, v1
	s_cbranch_scc0 .LBB19_2
; %bb.3:
	s_load_dword s2, s[10:11], 0x0
	s_load_dword s3, s[12:13], 0x0
	s_add_u32 s4, s6, 16
	s_addc_u32 s5, s7, 0
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[0:1], 0
.LBB19_4:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[4:5], 0, s[0:1]
	global_load_dword v2, v[6:7], off
	s_add_u32 s16, s4, s0
	s_addc_u32 s17, s5, s1
	s_load_dword s16, s[16:17], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v1, s16, v2
	s_cbranch_scc1 .LBB19_4
; %bb.5:
	s_load_dword s5, s[10:11], 0x4
	s_load_dword s4, s[12:13], 0x4
	s_add_u32 s16, s6, 32
	s_addc_u32 s17, s7, 0
	v_mov_b32_e32 v2, 0
	s_mov_b64 s[0:1], 0
.LBB19_6:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[6:7], v[4:5], 0, s[0:1]
	global_load_dword v6, v[6:7], off
	s_add_u32 s18, s16, s0
	s_addc_u32 s19, s17, s1
	s_load_dword s18, s[18:19], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v2, s18, v6
	s_cbranch_scc1 .LBB19_6
; %bb.7:
	s_load_dword s16, s[10:11], 0x8
	s_load_dword s17, s[12:13], 0x8
	s_add_u32 s18, s6, 48
	s_addc_u32 s19, s7, 0
	v_mov_b32_e32 v6, 0
	s_mov_b64 s[0:1], 0
.LBB19_8:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[8:9], v[4:5], 0, s[0:1]
	global_load_dword v7, v[8:9], off
	s_add_u32 s20, s18, s0
	s_addc_u32 s21, s19, s1
	s_load_dword s20, s[20:21], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v6, s20, v7
	s_cbranch_scc1 .LBB19_8
; %bb.9:
	s_load_dword s18, s[10:11], 0xc
	s_load_dword s19, s[12:13], 0xc
	s_add_u32 s20, s6, 64
	s_addc_u32 s21, s7, 0
	v_mov_b32_e32 v7, 0
	s_mov_b64 s[0:1], 0
.LBB19_10:                              ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[8:9], v[4:5], 0, s[0:1]
	global_load_dword v8, v[8:9], off
	s_add_u32 s22, s20, s0
	s_addc_u32 s23, s21, s1
	s_load_dword s22, s[22:23], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v7, s22, v8
	s_cbranch_scc1 .LBB19_10
; %bb.11:
	s_load_dword s20, s[10:11], 0x10
	s_load_dword s21, s[12:13], 0x10
	s_add_u32 s22, s6, 0x50
	s_addc_u32 s23, s7, 0
	v_mov_b32_e32 v8, 0
	s_mov_b64 s[0:1], 0
.LBB19_12:                              ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[10:11], v[4:5], 0, s[0:1]
	global_load_dword v9, v[10:11], off
	s_add_u32 s24, s22, s0
	s_addc_u32 s25, s23, s1
	s_load_dword s24, s[24:25], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v8, s24, v9
	s_cbranch_scc1 .LBB19_12
; %bb.13:
	s_load_dword s22, s[10:11], 0x14
	s_load_dword s23, s[12:13], 0x14
	s_add_u32 s24, s6, 0x60
	s_addc_u32 s25, s7, 0
	v_mov_b32_e32 v9, 0
	s_mov_b64 s[0:1], 0
.LBB19_14:                              ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[10:11], v[4:5], 0, s[0:1]
	global_load_dword v10, v[10:11], off
	s_add_u32 s26, s24, s0
	s_addc_u32 s27, s25, s1
	s_load_dword s26, s[26:27], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v9, s26, v10
	s_cbranch_scc1 .LBB19_14
; %bb.15:
	s_load_dword s24, s[10:11], 0x18
	s_load_dword s25, s[12:13], 0x18
	s_add_u32 s6, s6, 0x70
	s_addc_u32 s7, s7, 0
	v_mov_b32_e32 v10, 0
	s_mov_b64 s[0:1], 0
.LBB19_16:                              ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[12:13], v[4:5], 0, s[0:1]
	global_load_dword v11, v[12:13], off
	s_add_u32 s26, s6, s0
	s_addc_u32 s27, s7, s1
	s_load_dword s26, s[26:27], 0x0
	s_add_u32 s0, s0, 4
	s_addc_u32 s1, s1, 0
	s_cmp_lg_u32 s0, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v10, s26, v11
	s_cbranch_scc1 .LBB19_16
; %bb.17:
	v_lshlrev_b32_e32 v4, 2, v0
	global_load_dword v0, v4, s[8:9]
	s_load_dword s0, s[10:11], 0x1c
	s_load_dword s1, s[12:13], 0x1c
	v_fma_f32 v1, v1, 2.0, s5
	v_fma_f32 v3, v3, 2.0, s2
	v_fma_f32 v6, v6, 2.0, s18
	v_fma_f32 v2, v2, 2.0, s16
	v_add_f32_e32 v1, s4, v1
	v_add_f32_e32 v3, s3, v3
	v_fma_f32 v5, v9, 2.0, s24
	v_fma_f32 v8, v8, 2.0, s22
	v_fma_f32 v7, v7, 2.0, s20
	v_add_f32_e32 v6, s19, v6
	v_add_f32_e32 v2, s17, v2
	s_waitcnt lgkmcnt(0)
	v_fma_f32 v9, v10, 2.0, s0
	v_max_f32_e32 v10, v3, v1
	v_add_f32_e32 v8, s23, v8
	v_add_f32_e32 v7, s21, v7
	v_max3_f32 v10, v10, v2, v6
	v_add_f32_e32 v5, s25, v5
	v_add_f32_e32 v9, s1, v9
	v_max3_f32 v10, v10, v7, v8
	v_max3_f32 v10, v10, v5, v9
	v_sub_f32_e32 v3, v3, v10
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_sub_f32_e32 v1, v1, v10
	v_exp_f32_e32 v3, v3
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_sub_f32_e32 v2, v2, v10
	v_exp_f32_e32 v1, v1
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_exp_f32_e32 v2, v2
	v_sub_f32_e32 v6, v6, v10
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_add_f32_e32 v3, 0, v3
	v_exp_f32_e32 v6, v6
	v_add_f32_e32 v1, v3, v1
	v_add_f32_e32 v1, v1, v2
	v_sub_f32_e32 v2, v7, v10
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_sub_f32_e32 v3, v8, v10
	v_exp_f32_e32 v2, v2
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_sub_f32_e32 v5, v5, v10
	v_add_f32_e32 v1, v1, v6
	v_exp_f32_e32 v3, v3
	v_mul_f32_e32 v5, 0x3fb8aa3b, v5
	v_sub_f32_e32 v6, v9, v10
	v_exp_f32_e32 v5, v5
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_exp_f32_e32 v6, v6
	v_add_f32_e32 v1, v1, v2
	v_add_f32_e32 v1, v1, v3
	v_add_f32_e32 v1, v1, v5
	v_add_f32_e32 v1, v1, v6
	v_log_f32_e32 v1, v1
	s_nop 0
	v_fmamk_f32 v1, v1, 0x3f317218, v10
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[0:1], v[0:1], 0.5 op_sel_hi:[1,0]
	s_nop 0
	v_sub_f32_e32 v0, v0, v1
	global_store_dword v4, v0, s[14:15]
.LBB19_18:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel portable_sinkhorn
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
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
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 28
		.amdhsa_accum_offset 16
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
.Lfunc_end19:
	.size	portable_sinkhorn, .Lfunc_end19-portable_sinkhorn
                                        ; -- End function
	.set portable_sinkhorn.num_vgpr, 14
	.set portable_sinkhorn.num_agpr, 0
	.set portable_sinkhorn.numbered_sgpr, 28
	.set portable_sinkhorn.num_named_barrier, 0
	.set portable_sinkhorn.private_seg_size, 0
	.set portable_sinkhorn.uses_vcc, 1
	.set portable_sinkhorn.uses_flat_scratch, 0
	.set portable_sinkhorn.has_dyn_sized_stack, 0
	.set portable_sinkhorn.has_recursion, 0
	.set portable_sinkhorn.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1100
; TotalNumSgprs: 34
; NumVgprs: 14
; NumAgprs: 0
; TotalNumVgprs: 14
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 4
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 34
; NumVGPRsForWavesPerEU: 14
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_3f8f5d511d0d9248,@object ; @__hip_cuid_3f8f5d511d0d9248
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_3f8f5d511d0d9248
__hip_cuid_3f8f5d511d0d9248:
	.byte	0                               ; 0x0
	.size	__hip_cuid_3f8f5d511d0d9248, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_3f8f5d511d0d9248
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
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
    .name:           portable_relu
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         portable_relu.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_sigmoid
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         portable_sigmoid.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_silu
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         portable_silu.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_swiglu
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         portable_swiglu.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_rope
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         portable_rope.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_reduction
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         portable_reduction.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_softmax
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         portable_softmax.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     15
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_rmsnorm
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         portable_rmsnorm.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_matvec
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         portable_matvec.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_gemm
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         portable_gemm.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     10
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_gemm_add_silu
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         portable_gemm_add_silu.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     10
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_bitdelta
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         portable_bitdelta.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_bitdelta_batched
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         portable_bitdelta_batched.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
    .name:           portable_convolution
    .private_segment_fixed_size: 0
    .sgpr_count:     17
    .sgpr_spill_count: 0
    .symbol:         portable_convolution.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     16
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           portable_mamba_state
    .private_segment_fixed_size: 0
    .sgpr_count:     19
    .sgpr_spill_count: 0
    .symbol:         portable_mamba_state.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     9
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           portable_mamba_scan
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         portable_mamba_scan.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           portable_flash_attention
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         portable_flash_attention.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           portable_forgetting_attention
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         portable_forgetting_attention.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           portable_sage_attention
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         portable_sage_attention.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     12
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           portable_sinkhorn
    .private_segment_fixed_size: 0
    .sgpr_count:     34
    .sgpr_spill_count: 0
    .symbol:         portable_sinkhorn.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
