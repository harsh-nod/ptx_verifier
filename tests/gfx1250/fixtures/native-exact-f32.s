	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	exact_add_sat           ; -- Begin function exact_add_sat
	.globl	exact_add_sat
	.p2align	8
	.type	exact_add_sat,@function
exact_add_sat:                          ; @exact_add_sat
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v1, 0x3f400000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v2, 0xbf400000 :: v_dual_add_f32 v1, v1, v1
	v_mov_b32_e32 v3, 0x3e800000
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_add_f32 v1, 0, v1 clamp
	;;#ASMEND
	v_add_f32_e32 v2, v2, v3
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v2 clamp
	;;#ASMEND
	global_store_b32 v0, v1, s[0:1] offset:4
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_add_sat
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_add_sat, .Lfunc_end0-exact_add_sat
                                        ; -- End function
	.set exact_add_sat.num_vgpr, 4
	.set exact_add_sat.num_agpr, 0
	.set exact_add_sat.numbered_sgpr, 2
	.set exact_add_sat.num_named_barrier, 0
	.set exact_add_sat.private_seg_size, 0
	.set exact_add_sat.uses_vcc, 0
	.set exact_add_sat.uses_flat_scratch, 0
	.set exact_add_sat.has_dyn_sized_stack, 0
	.set exact_add_sat.has_recursion, 0
	.set exact_add_sat.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 84
; TotalNumSgprs: 2
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_copysign          ; -- Begin function exact_copysign
	.globl	exact_copysign
	.p2align	8
	.type	exact_copysign,@function
exact_copysign:                         ; @exact_copysign
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v0, 2.0 :: v_dual_mov_b32 v1, 0x40400000
	v_dual_mov_b32 v2, -2.0 :: v_dual_mov_b32 v3, 0xc0400000
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_bfi_b32 v4, 0x7fffffff, v1, v0
	v_bfi_b32 v1, 0x7fffffff, v1, v2
	v_bfi_b32 v5, 0x7fffffff, v3, v0
	v_bfi_b32 v3, 0x7fffffff, v3, v2
	;;#ASMSTART
	v_add_f32 v0, 0, v4
	;;#ASMEND
	;;#ASMSTART
	v_add_f32 v2, 0, v5
	;;#ASMEND
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	;;#ASMSTART
	v_add_f32 v3, 0, v3
	;;#ASMEND
	v_pk_add_f32 v[0:1], v[0:1], v[2:3]
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_mov_b32 v2, 0 :: v_dual_add_f32 v0, v0, v1
	s_wait_kmcnt 0x0
	global_store_b32 v2, v0, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_copysign
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_copysign, .Lfunc_end1-exact_copysign
                                        ; -- End function
	.set exact_copysign.num_vgpr, 6
	.set exact_copysign.num_agpr, 0
	.set exact_copysign.numbered_sgpr, 2
	.set exact_copysign.num_named_barrier, 0
	.set exact_copysign.private_seg_size, 0
	.set exact_copysign.uses_vcc, 0
	.set exact_copysign.uses_flat_scratch, 0
	.set exact_copysign.has_dyn_sized_stack, 0
	.set exact_copysign.has_recursion, 0
	.set exact_copysign.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 124
; TotalNumSgprs: 2
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_source_integer_format ; -- Begin function exact_source_integer_format
	.globl	exact_source_integer_format
	.p2align	8
	.type	exact_source_integer_format,@function
exact_source_integer_format:            ; @exact_source_integer_format
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v0, -5 :: v_dual_mov_b32 v2, 3
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v0, -4, v0 bitop3:0x40
	v_dual_add_nc_u32 v2, -11, v2 :: v_dual_ashrrev_i32 v1, 31, v0
	s_wait_kmcnt 0x0
	global_store_b128 v3, v[0:3], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_source_integer_format
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_source_integer_format, .Lfunc_end2-exact_source_integer_format
                                        ; -- End function
	.set exact_source_integer_format.num_vgpr, 4
	.set exact_source_integer_format.num_agpr, 0
	.set exact_source_integer_format.numbered_sgpr, 2
	.set exact_source_integer_format.num_named_barrier, 0
	.set exact_source_integer_format.private_seg_size, 0
	.set exact_source_integer_format.uses_vcc, 0
	.set exact_source_integer_format.uses_flat_scratch, 0
	.set exact_source_integer_format.has_dyn_sized_stack, 0
	.set exact_source_integer_format.has_recursion, 0
	.set exact_source_integer_format.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 68
; TotalNumSgprs: 2
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_div768            ; -- Begin function exact_div768
	.globl	exact_div768
	.p2align	8
	.type	exact_div768,@function
exact_div768:                           ; @exact_div768
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 0x44400000 :: v_dual_mov_b32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_rcp_f32 v1, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	v_mul_f32_e32 v1, s0, v1
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_div768
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_div768, .Lfunc_end3-exact_div768
                                        ; -- End function
	.set exact_div768.num_vgpr, 2
	.set exact_div768.num_agpr, 0
	.set exact_div768.numbered_sgpr, 4
	.set exact_div768.num_named_barrier, 0
	.set exact_div768.private_seg_size, 0
	.set exact_div768.uses_vcc, 0
	.set exact_div768.uses_flat_scratch, 0
	.set exact_div768.has_dyn_sized_stack, 0
	.set exact_div768.has_recursion, 0
	.set exact_div768.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 2
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
	.protected	exact_mul_recip768      ; -- Begin function exact_mul_recip768
	.globl	exact_mul_recip768
	.p2align	8
	.type	exact_mul_recip768,@function
exact_mul_recip768:                     ; @exact_mul_recip768
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 0x44400000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_rcp_f32 v2, v1
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	v_mul_f32_e32 v1, v2, v1
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_mul_recip768
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_mul_recip768, .Lfunc_end4-exact_mul_recip768
                                        ; -- End function
	.set exact_mul_recip768.num_vgpr, 3
	.set exact_mul_recip768.num_agpr, 0
	.set exact_mul_recip768.numbered_sgpr, 4
	.set exact_mul_recip768.num_named_barrier, 0
	.set exact_mul_recip768.private_seg_size, 0
	.set exact_mul_recip768.uses_vcc, 0
	.set exact_mul_recip768.uses_flat_scratch, 0
	.set exact_mul_recip768.has_dyn_sized_stack, 0
	.set exact_mul_recip768.has_recursion, 0
	.set exact_mul_recip768.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 4
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 3
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
	.protected	exact_div_recip3        ; -- Begin function exact_div_recip3
	.globl	exact_div_recip3
	.p2align	8
	.type	exact_div_recip3,@function
exact_div_recip3:                       ; @exact_div_recip3
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 0x40400000 :: v_dual_mov_b32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_rcp_f32 v1, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	v_mul_f32_e32 v1, s0, v1
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_div_recip3
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_div_recip3, .Lfunc_end5-exact_div_recip3
                                        ; -- End function
	.set exact_div_recip3.num_vgpr, 2
	.set exact_div_recip3.num_agpr, 0
	.set exact_div_recip3.numbered_sgpr, 4
	.set exact_div_recip3.num_named_barrier, 0
	.set exact_div_recip3.private_seg_size, 0
	.set exact_div_recip3.uses_vcc, 0
	.set exact_div_recip3.uses_flat_scratch, 0
	.set exact_div_recip3.has_dyn_sized_stack, 0
	.set exact_div_recip3.has_recursion, 0
	.set exact_div_recip3.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 2
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
	.protected	exact_rcp3              ; -- Begin function exact_rcp3
	.globl	exact_rcp3
	.p2align	8
	.type	exact_rcp3,@function
exact_rcp3:                             ; @exact_rcp3
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 0x40400000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_rcp_f32 v2, v1
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	v_mul_f32_e32 v1, v2, v1
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_rcp3
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_rcp3, .Lfunc_end6-exact_rcp3
                                        ; -- End function
	.set exact_rcp3.num_vgpr, 3
	.set exact_rcp3.num_agpr, 0
	.set exact_rcp3.numbered_sgpr, 4
	.set exact_rcp3.num_named_barrier, 0
	.set exact_rcp3.private_seg_size, 0
	.set exact_rcp3.uses_vcc, 0
	.set exact_rcp3.uses_flat_scratch, 0
	.set exact_rcp3.has_dyn_sized_stack, 0
	.set exact_rcp3.has_recursion, 0
	.set exact_rcp3.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 4
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 3
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
	.protected	exact_abs_bits          ; -- Begin function exact_abs_bits
	.globl	exact_abs_bits
	.p2align	8
	.type	exact_abs_bits,@function
exact_abs_bits:                         ; @exact_abs_bits
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0xc0a00000
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_and_b32_e32 v1, 0x7fffffff, v0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v2, 0xff800000
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
	;;#ASMSTART
	;;#ASMEND
	s_wait_xcnt 0x0
	v_and_b32_e32 v1, 0x7fffffff, v2
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:4
	global_load_b32 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	v_and_b32_e32 v1, 0x7fffffff, v1
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:8
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_abs_bits
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	exact_abs_bits, .Lfunc_end7-exact_abs_bits
                                        ; -- End function
	.set exact_abs_bits.num_vgpr, 3
	.set exact_abs_bits.num_agpr, 0
	.set exact_abs_bits.numbered_sgpr, 4
	.set exact_abs_bits.num_named_barrier, 0
	.set exact_abs_bits.private_seg_size, 0
	.set exact_abs_bits.uses_vcc, 0
	.set exact_abs_bits.uses_flat_scratch, 0
	.set exact_abs_bits.has_dyn_sized_stack, 0
	.set exact_abs_bits.has_recursion, 0
	.set exact_abs_bits.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 124
; TotalNumSgprs: 4
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 3
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
	.protected	exact_raw_math          ; -- Begin function exact_raw_math
	.globl	exact_raw_math
	.p2align	8
	.type	exact_raw_math,@function
exact_raw_math:                         ; @exact_raw_math
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 1.0 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_fmac_f32 v1, v1, v1 :: v_dual_mov_b32 v4, 0x3c00
	v_dual_mov_b32 v2, 4.0 :: v_dual_mov_b32 v3, -1.0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_rcp_f32 v1, v2
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:4
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_sqrt_f32 v1, v2
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:8
	;;#ASMSTART
	;;#ASMEND
	s_wait_xcnt 0x0
	v_cvt_f32_f16_e32 v1, v4
	v_bfi_b32 v2, 0x7fffffff, v2, v3
	global_store_b32 v0, v1, s[2:3] offset:12
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v2
	;;#ASMEND
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:16
	global_load_b32 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	v_bfi_b32 v1, 0x7fffffff, v1, v3
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:20
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_raw_math
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
		.amdhsa_next_free_sgpr 4
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
.Lfunc_end8:
	.size	exact_raw_math, .Lfunc_end8-exact_raw_math
                                        ; -- End function
	.set exact_raw_math.num_vgpr, 5
	.set exact_raw_math.num_agpr, 0
	.set exact_raw_math.numbered_sgpr, 4
	.set exact_raw_math.num_named_barrier, 0
	.set exact_raw_math.private_seg_size, 0
	.set exact_raw_math.uses_vcc, 0
	.set exact_raw_math.uses_flat_scratch, 0
	.set exact_raw_math.has_dyn_sized_stack, 0
	.set exact_raw_math.has_recursion, 0
	.set exact_raw_math.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 184
; TotalNumSgprs: 4
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_mixed_fma         ; -- Begin function exact_mixed_fma
	.globl	exact_mixed_fma
	.p2align	8
	.type	exact_mixed_fma,@function
exact_mixed_fma:                        ; @exact_mixed_fma
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_dual_mov_b32 v1, 0x3c00 :: v_dual_mov_b32 v0, 0
	v_dual_mov_b32 v2, 0x4000 :: v_dual_mov_b32 v3, 1.0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_fma_mix_f32 v1, v1, v2, v3 op_sel_hi:[1,1,0]
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_mixed_fma
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end9:
	.size	exact_mixed_fma, .Lfunc_end9-exact_mixed_fma
                                        ; -- End function
	.set exact_mixed_fma.num_vgpr, 4
	.set exact_mixed_fma.num_agpr, 0
	.set exact_mixed_fma.numbered_sgpr, 2
	.set exact_mixed_fma.num_named_barrier, 0
	.set exact_mixed_fma.private_seg_size, 0
	.set exact_mixed_fma.uses_vcc, 0
	.set exact_mixed_fma.uses_flat_scratch, 0
	.set exact_mixed_fma.has_dyn_sized_stack, 0
	.set exact_mixed_fma.has_recursion, 0
	.set exact_mixed_fma.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 64
; TotalNumSgprs: 2
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_neg_bits          ; -- Begin function exact_neg_bits
	.globl	exact_neg_bits
	.p2align	8
	.type	exact_neg_bits,@function
exact_neg_bits:                         ; @exact_neg_bits
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v0, -5 :: v_dual_mov_b32 v2, 0
	v_bfrev_b32_e32 v1, 1
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_sub_nc_u32 v1, 0, v1 :: v_dual_sub_nc_u32 v0, 0, v0
	v_mov_b32_e32 v3, 0xc0a00000
	s_wait_kmcnt 0x0
	global_store_b64 v2, v[0:1], s[2:3]
	;;#ASMSTART
	;;#ASMEND
	s_wait_xcnt 0x0
	v_xor_b32_e32 v0, 0x80000000, v3
	v_mov_b32_e32 v1, 0xff800000
	;;#ASMSTART
	v_add_f32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v2, v0, s[2:3] offset:8
	;;#ASMSTART
	;;#ASMEND
	s_wait_xcnt 0x0
	v_xor_b32_e32 v0, 0x80000000, v1
	;;#ASMSTART
	v_add_f32 v0, 0, v0
	;;#ASMEND
	s_clause 0x1
	global_store_b32 v2, v0, s[2:3] offset:12
	global_load_b32 v0, v2, s[0:1]
	s_wait_loadcnt 0x0
	v_xor_b32_e32 v0, 0x80000000, v0
	;;#ASMSTART
	v_add_f32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v2, v0, s[2:3] offset:16
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_neg_bits
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 4
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
.Lfunc_end10:
	.size	exact_neg_bits, .Lfunc_end10-exact_neg_bits
                                        ; -- End function
	.set exact_neg_bits.num_vgpr, 4
	.set exact_neg_bits.num_agpr, 0
	.set exact_neg_bits.numbered_sgpr, 4
	.set exact_neg_bits.num_named_barrier, 0
	.set exact_neg_bits.private_seg_size, 0
	.set exact_neg_bits.uses_vcc, 0
	.set exact_neg_bits.uses_flat_scratch, 0
	.set exact_neg_bits.has_dyn_sized_stack, 0
	.set exact_neg_bits.has_recursion, 0
	.set exact_neg_bits.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 164
; TotalNumSgprs: 4
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_relu_explicit     ; -- Begin function exact_relu_explicit
	.globl	exact_relu_explicit
	.p2align	8
	.type	exact_relu_explicit,@function
exact_relu_explicit:                    ; @exact_relu_explicit
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_max_num_f32_e32 v1, v1, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v1, 0, v1
	v_cvt_f16_f32_e32 v1, v1
	global_store_b16 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_relu_explicit
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end11:
	.size	exact_relu_explicit, .Lfunc_end11-exact_relu_explicit
                                        ; -- End function
	.set exact_relu_explicit.num_vgpr, 2
	.set exact_relu_explicit.num_agpr, 0
	.set exact_relu_explicit.numbered_sgpr, 4
	.set exact_relu_explicit.num_named_barrier, 0
	.set exact_relu_explicit.private_seg_size, 0
	.set exact_relu_explicit.uses_vcc, 0
	.set exact_relu_explicit.uses_flat_scratch, 0
	.set exact_relu_explicit.has_dyn_sized_stack, 0
	.set exact_relu_explicit.has_recursion, 0
	.set exact_relu_explicit.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 2
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
	.protected	exact_relu_fused        ; -- Begin function exact_relu_fused
	.globl	exact_relu_fused
	.p2align	8
	.type	exact_relu_fused,@function
exact_relu_fused:                       ; @exact_relu_fused
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_max_num_f32_e32 v1, v1, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v1, 0, v1
	v_cvt_f16_f32_e32 v1, v1
	global_store_b16 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_relu_fused
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end12:
	.size	exact_relu_fused, .Lfunc_end12-exact_relu_fused
                                        ; -- End function
	.set exact_relu_fused.num_vgpr, 2
	.set exact_relu_fused.num_agpr, 0
	.set exact_relu_fused.numbered_sgpr, 4
	.set exact_relu_fused.num_named_barrier, 0
	.set exact_relu_fused.private_seg_size, 0
	.set exact_relu_fused.uses_vcc, 0
	.set exact_relu_fused.uses_flat_scratch, 0
	.set exact_relu_fused.has_dyn_sized_stack, 0
	.set exact_relu_fused.has_recursion, 0
	.set exact_relu_fused.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 2
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
	.protected	exact_exp               ; -- Begin function exact_exp
	.globl	exact_exp
	.p2align	8
	.type	exact_exp,@function
exact_exp:                              ; @exact_exp
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0x3fb8aa3b
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	v_dual_mul_f32 v1, s0, v0 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_exp_f32 v1, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_exp
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end13:
	.size	exact_exp, .Lfunc_end13-exact_exp
                                        ; -- End function
	.set exact_exp.num_vgpr, 2
	.set exact_exp.num_agpr, 0
	.set exact_exp.numbered_sgpr, 4
	.set exact_exp.num_named_barrier, 0
	.set exact_exp.private_seg_size, 0
	.set exact_exp.uses_vcc, 0
	.set exact_exp.uses_flat_scratch, 0
	.set exact_exp.has_dyn_sized_stack, 0
	.set exact_exp.has_recursion, 0
	.set exact_exp.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 2
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
	.protected	exact_tanh              ; -- Begin function exact_tanh
	.globl	exact_tanh
	.p2align	8
	.type	exact_tanh,@function
exact_tanh:                             ; @exact_tanh
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v0, 0x3fb8aa3b :: v_dual_mov_b32 v1, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_add_f32 s0, s0, s0
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v0, s0, v0
	;;#ASMSTART
	v_exp_f32 v0, v0
	;;#ASMEND
	v_dual_add_f32 v2, 1.0, v0 :: v_dual_add_f32 v0, -1.0, v0
	;;#ASMSTART
	v_rcp_f32 v2, v2
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_mul_f32_e32 v0, v0, v2
	global_store_b32 v1, v0, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_tanh
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end14:
	.size	exact_tanh, .Lfunc_end14-exact_tanh
                                        ; -- End function
	.set exact_tanh.num_vgpr, 3
	.set exact_tanh.num_agpr, 0
	.set exact_tanh.numbered_sgpr, 4
	.set exact_tanh.num_named_barrier, 0
	.set exact_tanh.private_seg_size, 0
	.set exact_tanh.uses_vcc, 0
	.set exact_tanh.uses_flat_scratch, 0
	.set exact_tanh.has_dyn_sized_stack, 0
	.set exact_tanh.has_recursion, 0
	.set exact_tanh.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 84
; TotalNumSgprs: 4
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 3
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
	.protected	exact_tanh_zero         ; -- Begin function exact_tanh_zero
	.globl	exact_tanh_zero
	.p2align	8
	.type	exact_tanh_zero,@function
exact_tanh_zero:                        ; @exact_tanh_zero
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 0x3fb8aa3b
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_dual_add_f32 v0, v0, v0 :: v_dual_mov_b32 v2, 0
	;;#ASMSTART
	;;#ASMEND
	v_mul_f32_e32 v0, v0, v1
	;;#ASMSTART
	v_exp_f32 v0, v0
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_dual_add_f32 v1, 1.0, v0 :: v_dual_add_f32 v0, -1.0, v0
	;;#ASMSTART
	v_rcp_f32 v1, v1
	;;#ASMEND
	v_mul_f32_e32 v0, v0, v1
	s_wait_kmcnt 0x0
	global_store_b32 v2, v0, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_tanh_zero
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end15:
	.size	exact_tanh_zero, .Lfunc_end15-exact_tanh_zero
                                        ; -- End function
	.set exact_tanh_zero.num_vgpr, 3
	.set exact_tanh_zero.num_agpr, 0
	.set exact_tanh_zero.numbered_sgpr, 2
	.set exact_tanh_zero.num_named_barrier, 0
	.set exact_tanh_zero.private_seg_size, 0
	.set exact_tanh_zero.uses_vcc, 0
	.set exact_tanh_zero.uses_flat_scratch, 0
	.set exact_tanh_zero.has_dyn_sized_stack, 0
	.set exact_tanh_zero.has_recursion, 0
	.set exact_tanh_zero.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 76
; TotalNumSgprs: 2
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 3
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
	.protected	exact_zero              ; -- Begin function exact_zero
	.globl	exact_zero
	.p2align	8
	.type	exact_zero,@function
exact_zero:                             ; @exact_zero
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_add_f32 v0, 0, v0
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v1, v0, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_zero
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end16:
	.size	exact_zero, .Lfunc_end16-exact_zero
                                        ; -- End function
	.set exact_zero.num_vgpr, 2
	.set exact_zero.num_agpr, 0
	.set exact_zero.numbered_sgpr, 2
	.set exact_zero.num_named_barrier, 0
	.set exact_zero.private_seg_size, 0
	.set exact_zero.uses_vcc, 0
	.set exact_zero.uses_flat_scratch, 0
	.set exact_zero.has_dyn_sized_stack, 0
	.set exact_zero.has_recursion, 0
	.set exact_zero.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 36
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 2
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
	.protected	exact_fence_identity    ; -- Begin function exact_fence_identity
	.globl	exact_fence_identity
	.p2align	8
	.type	exact_fence_identity,@function
exact_fence_identity:                   ; @exact_fence_identity
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v1, 1.0 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_fence_identity
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 2
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
.Lfunc_end17:
	.size	exact_fence_identity, .Lfunc_end17-exact_fence_identity
                                        ; -- End function
	.set exact_fence_identity.num_vgpr, 2
	.set exact_fence_identity.num_agpr, 0
	.set exact_fence_identity.numbered_sgpr, 2
	.set exact_fence_identity.num_named_barrier, 0
	.set exact_fence_identity.private_seg_size, 0
	.set exact_fence_identity.uses_vcc, 0
	.set exact_fence_identity.uses_flat_scratch, 0
	.set exact_fence_identity.has_dyn_sized_stack, 0
	.set exact_fence_identity.has_recursion, 0
	.set exact_fence_identity.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 36
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 2
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
	.type	__hip_cuid_47eb06d90f4ef451,@object ; @__hip_cuid_47eb06d90f4ef451
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_47eb06d90f4ef451
__hip_cuid_47eb06d90f4ef451:
	.byte	0                               ; 0x0
	.size	__hip_cuid_47eb06d90f4ef451, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_47eb06d90f4ef451
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_add_sat
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_add_sat.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_copysign
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_copysign.kd
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_source_integer_format
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_source_integer_format.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .max_flat_workgroup_size: 1
    .name:           exact_div768
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_div768.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
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
    .max_flat_workgroup_size: 1
    .name:           exact_mul_recip768
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_mul_recip768.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .max_flat_workgroup_size: 1
    .name:           exact_div_recip3
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_div_recip3.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
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
    .max_flat_workgroup_size: 1
    .name:           exact_rcp3
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_rcp3.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .max_flat_workgroup_size: 1
    .name:           exact_abs_bits
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_abs_bits.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .max_flat_workgroup_size: 1
    .name:           exact_raw_math
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_raw_math.kd
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_mixed_fma
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_mixed_fma.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .max_flat_workgroup_size: 1
    .name:           exact_neg_bits
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_neg_bits.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .max_flat_workgroup_size: 2
    .name:           exact_relu_explicit
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_relu_explicit.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
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
    .max_flat_workgroup_size: 2
    .name:           exact_relu_fused
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_relu_fused.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
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
    .max_flat_workgroup_size: 1
    .name:           exact_exp
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_exp.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
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
    .max_flat_workgroup_size: 1
    .name:           exact_tanh
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_tanh.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_tanh_zero
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_tanh_zero.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_zero
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_zero.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_fence_identity
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_fence_identity.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
