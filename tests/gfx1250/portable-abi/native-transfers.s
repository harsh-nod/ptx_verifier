	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	abi_shared_words        ; -- Begin function abi_shared_words
	.globl	abi_shared_words
	.p2align	8
	.type	abi_shared_words,@function
abi_shared_words:                       ; @abi_shared_words
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s8, 0
	s_mov_b32 s10, 8
	s_mov_b32 s12, 12
	s_mov_b32 s11, s9
	s_mov_b32 s13, s9
	s_wait_kmcnt 0x0
	s_load_b128 s[4:7], s[0:1], 0x0
	v_mov_b32_e32 v4, 0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 4
	s_mov_b32 s1, s9
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, s4 :: v_dual_mov_b32 v1, s5
	v_dual_mov_b32 v2, s6 :: v_dual_mov_b32 v3, s7
	flat_store_b32 v4, v0, s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v4, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v4, v2, s[10:11] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v4, v3, s[12:13] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b128 v[0:3], v4, s[8:9] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b128 v4, v[0:3], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_shared_words
		.amdhsa_group_segment_fixed_size 16
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
		.amdhsa_next_free_sgpr 14
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
.Lfunc_end0:
	.size	abi_shared_words, .Lfunc_end0-abi_shared_words
                                        ; -- End function
	.set abi_shared_words.num_vgpr, 5
	.set abi_shared_words.num_agpr, 0
	.set abi_shared_words.numbered_sgpr, 14
	.set abi_shared_words.num_named_barrier, 0
	.set abi_shared_words.private_seg_size, 0
	.set abi_shared_words.uses_vcc, 0
	.set abi_shared_words.uses_flat_scratch, 0
	.set abi_shared_words.has_dyn_sized_stack, 0
	.set abi_shared_words.has_recursion, 0
	.set abi_shared_words.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 184
; TotalNumSgprs: 14
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
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
	.protected	abi_half_pair           ; -- Begin function abi_half_pair
	.globl	abi_half_pair
	.p2align	8
	.type	abi_half_pair,@function
abi_half_pair:                          ; @abi_half_pair
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_wait_kmcnt 0x0
	global_load_u16 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	flat_store_b16 v0, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v1, v0, s[0:1] offset:2
	s_wait_xcnt 0x0
	s_mov_b32 s0, 2
	s_mov_b32 s1, s5
	s_wait_loadcnt 0x0
	flat_store_b16 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_u16 v1, v0, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v2, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v1, v2, v1, 0x5040100
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_half_pair
		.amdhsa_group_segment_fixed_size 4
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
		.amdhsa_next_free_sgpr 6
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
.Lfunc_end1:
	.size	abi_half_pair, .Lfunc_end1-abi_half_pair
                                        ; -- End function
	.set abi_half_pair.num_vgpr, 3
	.set abi_half_pair.num_agpr, 0
	.set abi_half_pair.numbered_sgpr, 6
	.set abi_half_pair.num_named_barrier, 0
	.set abi_half_pair.private_seg_size, 0
	.set abi_half_pair.uses_vcc, 0
	.set abi_half_pair.uses_flat_scratch, 0
	.set abi_half_pair.has_dyn_sized_stack, 0
	.set abi_half_pair.has_recursion, 0
	.set abi_half_pair.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 168
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	abi_byte_pair           ; -- Begin function abi_byte_pair
	.globl	abi_byte_pair
	.p2align	8
	.type	abi_byte_pair,@function
abi_byte_pair:                          ; @abi_byte_pair
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_wait_kmcnt 0x0
	global_load_u8 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	flat_store_b8 v0, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u8 v1, v0, s[0:1] offset:1
	s_wait_xcnt 0x0
	s_mov_b32 s0, 1
	s_mov_b32 s1, s5
	s_wait_loadcnt 0x0
	flat_store_b8 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_u8 v1, v0, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u8 v2, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_lshlrev_b16 v2, 8, v2
	s_delay_alu instid0(VALU_DEP_1)
	v_or_b32_e32 v1, v1, v2
	global_store_b16 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_byte_pair
		.amdhsa_group_segment_fixed_size 2
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
		.amdhsa_next_free_sgpr 6
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
	.size	abi_byte_pair, .Lfunc_end2-abi_byte_pair
                                        ; -- End function
	.set abi_byte_pair.num_vgpr, 3
	.set abi_byte_pair.num_agpr, 0
	.set abi_byte_pair.numbered_sgpr, 6
	.set abi_byte_pair.num_named_barrier, 0
	.set abi_byte_pair.private_seg_size, 0
	.set abi_byte_pair.uses_vcc, 0
	.set abi_byte_pair.uses_flat_scratch, 0
	.set abi_byte_pair.has_dyn_sized_stack, 0
	.set abi_byte_pair.has_recursion, 0
	.set abi_byte_pair.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 172
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 2 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	abi_scalar_granule      ; -- Begin function abi_scalar_granule
	.globl	abi_scalar_granule
	.p2align	8
	.type	abi_scalar_granule,@function
abi_scalar_granule:                     ; @abi_scalar_granule
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	flat_store_b32 v0, v0, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_kmcnt 0x0
	global_load_u16 v1, v0, s[0:1]
	s_wait_xcnt 0x0
	s_mov_b32 s0, 2
	s_mov_b32 s1, s5
	s_wait_loadcnt 0x0
	flat_store_b16 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_u16 v1, v0, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v2, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x1
	v_cvt_f32_f16_e32 v1, v1
	s_wait_dscnt 0x0
	v_cvt_f32_f16_e32 v2, v2
	s_delay_alu instid0(VALU_DEP_1)
	v_add_f32_e32 v1, v1, v2
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_scalar_granule
		.amdhsa_group_segment_fixed_size 4
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
		.amdhsa_next_free_sgpr 6
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
.Lfunc_end3:
	.size	abi_scalar_granule, .Lfunc_end3-abi_scalar_granule
                                        ; -- End function
	.set abi_scalar_granule.num_vgpr, 3
	.set abi_scalar_granule.num_agpr, 0
	.set abi_scalar_granule.numbered_sgpr, 6
	.set abi_scalar_granule.num_named_barrier, 0
	.set abi_scalar_granule.private_seg_size, 0
	.set abi_scalar_granule.uses_vcc, 0
	.set abi_scalar_granule.uses_flat_scratch, 0
	.set abi_scalar_granule.has_dyn_sized_stack, 0
	.set abi_scalar_granule.has_recursion, 0
	.set abi_scalar_granule.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 160
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	abi_pair_truncation     ; -- Begin function abi_pair_truncation
	.globl	abi_pair_truncation
	.p2align	8
	.type	abi_pair_truncation,@function
abi_pair_truncation:                    ; @abi_pair_truncation
; %bb.0:
	v_dual_mov_b32 v3, 0 :: v_dual_mov_b32 v0, 1
	v_mov_b32_e32 v1, 2
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	s_mov_b32 s4, 2
	s_mov_b32 s5, s3
	flat_store_b16 v3, v0, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v3, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v0, v3, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_mov_b32 s6, 4
	s_mov_b32 s7, s3
	s_load_b64 s[0:1], s[0:1], 0x0
	s_wait_dscnt 0x0
	flat_store_b16 v3, v0, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_u16 v0, v3, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v1, v3, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v2, v3, s[6:7] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b96 v3, v[0:2], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_pair_truncation
		.amdhsa_group_segment_fixed_size 6
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
		.amdhsa_next_free_sgpr 8
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
.Lfunc_end4:
	.size	abi_pair_truncation, .Lfunc_end4-abi_pair_truncation
                                        ; -- End function
	.set abi_pair_truncation.num_vgpr, 4
	.set abi_pair_truncation.num_agpr, 0
	.set abi_pair_truncation.numbered_sgpr, 8
	.set abi_pair_truncation.num_named_barrier, 0
	.set abi_pair_truncation.private_seg_size, 0
	.set abi_pair_truncation.uses_vcc, 0
	.set abi_pair_truncation.uses_flat_scratch, 0
	.set abi_pair_truncation.has_dyn_sized_stack, 0
	.set abi_pair_truncation.has_recursion, 0
	.set abi_pair_truncation.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 188
; TotalNumSgprs: 8
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 6 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 8
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
	.protected	abi_logical_partitions  ; -- Begin function abi_logical_partitions
	.globl	abi_logical_partitions
	.p2align	8
	.type	abi_logical_partitions,@function
abi_logical_partitions:                 ; @abi_logical_partitions
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s3 :: v_dual_lshlrev_b32 v2, 2, v0
	v_lshrrev_b32_e32 v1, 5, v0
	s_load_b64 s[0:1], s[0:1], 0x0
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b32 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_logical_partitions
		.amdhsa_group_segment_fixed_size 256
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
	.size	abi_logical_partitions, .Lfunc_end5-abi_logical_partitions
                                        ; -- End function
	.set abi_logical_partitions.num_vgpr, 4
	.set abi_logical_partitions.num_agpr, 0
	.set abi_logical_partitions.numbered_sgpr, 4
	.set abi_logical_partitions.num_named_barrier, 0
	.set abi_logical_partitions.private_seg_size, 0
	.set abi_logical_partitions.uses_vcc, 0
	.set abi_logical_partitions.uses_flat_scratch, 0
	.set abi_logical_partitions.has_dyn_sized_stack, 0
	.set abi_logical_partitions.has_recursion, 0
	.set abi_logical_partitions.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 88
; TotalNumSgprs: 4
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 256 bytes/workgroup (compile time only)
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
	.protected	abi_global_vector_last  ; -- Begin function abi_global_vector_last
	.globl	abi_global_vector_last
	.p2align	8
	.type	abi_global_vector_last,@function
abi_global_vector_last:                 ; @abi_global_vector_last
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v4, 0
	s_wait_kmcnt 0x0
	flat_load_b128 v[0:3], v4, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v4, v3, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_global_vector_last
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
	.size	abi_global_vector_last, .Lfunc_end6-abi_global_vector_last
                                        ; -- End function
	.set abi_global_vector_last.num_vgpr, 5
	.set abi_global_vector_last.num_agpr, 0
	.set abi_global_vector_last.numbered_sgpr, 4
	.set abi_global_vector_last.num_named_barrier, 0
	.set abi_global_vector_last.private_seg_size, 0
	.set abi_global_vector_last.uses_vcc, 0
	.set abi_global_vector_last.uses_flat_scratch, 0
	.set abi_global_vector_last.has_dyn_sized_stack, 0
	.set abi_global_vector_last.has_recursion, 0
	.set abi_global_vector_last.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 48
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
	.protected	abi_half_at_two_mod_four ; -- Begin function abi_half_at_two_mod_four
	.globl	abi_half_at_two_mod_four
	.p2align	8
	.type	abi_half_at_two_mod_four,@function
abi_half_at_two_mod_four:               ; @abi_half_at_two_mod_four
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	global_load_u16 v1, v0, s[0:1] offset:2
	s_wait_loadcnt 0x0
	global_store_b16 v0, v1, s[2:3] offset:2
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_half_at_two_mod_four
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
.Lfunc_end7:
	.size	abi_half_at_two_mod_four, .Lfunc_end7-abi_half_at_two_mod_four
                                        ; -- End function
	.set abi_half_at_two_mod_four.num_vgpr, 2
	.set abi_half_at_two_mod_four.num_agpr, 0
	.set abi_half_at_two_mod_four.numbered_sgpr, 4
	.set abi_half_at_two_mod_four.num_named_barrier, 0
	.set abi_half_at_two_mod_four.private_seg_size, 0
	.set abi_half_at_two_mod_four.uses_vcc, 0
	.set abi_half_at_two_mod_four.uses_flat_scratch, 0
	.set abi_half_at_two_mod_four.has_dyn_sized_stack, 0
	.set abi_half_at_two_mod_four.has_recursion, 0
	.set abi_half_at_two_mod_four.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 48
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
	.protected	abi_upper_address       ; -- Begin function abi_upper_address
	.globl	abi_upper_address
	.p2align	8
	.type	abi_upper_address,@function
abi_upper_address:                      ; @abi_upper_address
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x10
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_upper_address
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
.Lfunc_end8:
	.size	abi_upper_address, .Lfunc_end8-abi_upper_address
                                        ; -- End function
	.set abi_upper_address.num_vgpr, 2
	.set abi_upper_address.num_agpr, 0
	.set abi_upper_address.numbered_sgpr, 4
	.set abi_upper_address.num_named_barrier, 0
	.set abi_upper_address.private_seg_size, 0
	.set abi_upper_address.uses_vcc, 0
	.set abi_upper_address.uses_flat_scratch, 0
	.set abi_upper_address.has_dyn_sized_stack, 0
	.set abi_upper_address.has_recursion, 0
	.set abi_upper_address.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 48
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
	.protected	abi_negative_index      ; -- Begin function abi_negative_index
	.globl	abi_negative_index
	.p2align	8
	.type	abi_negative_index,@function
abi_negative_index:                     ; @abi_negative_index
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[0:1], s[0:1], -4
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_negative_index
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
.Lfunc_end9:
	.size	abi_negative_index, .Lfunc_end9-abi_negative_index
                                        ; -- End function
	.set abi_negative_index.num_vgpr, 2
	.set abi_negative_index.num_agpr, 0
	.set abi_negative_index.numbered_sgpr, 4
	.set abi_negative_index.num_named_barrier, 0
	.set abi_negative_index.private_seg_size, 0
	.set abi_negative_index.uses_vcc, 0
	.set abi_negative_index.uses_flat_scratch, 0
	.set abi_negative_index.has_dyn_sized_stack, 0
	.set abi_negative_index.has_recursion, 0
	.set abi_negative_index.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 52
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
	.protected	abi_rank_zero_offsets   ; -- Begin function abi_rank_zero_offsets
	.globl	abi_rank_zero_offsets
	.p2align	8
	.type	abi_rank_zero_offsets,@function
abi_rank_zero_offsets:                  ; @abi_rank_zero_offsets
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 2, v0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_rank_zero_offsets
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
.Lfunc_end10:
	.size	abi_rank_zero_offsets, .Lfunc_end10-abi_rank_zero_offsets
                                        ; -- End function
	.set abi_rank_zero_offsets.num_vgpr, 2
	.set abi_rank_zero_offsets.num_agpr, 0
	.set abi_rank_zero_offsets.numbered_sgpr, 2
	.set abi_rank_zero_offsets.num_named_barrier, 0
	.set abi_rank_zero_offsets.private_seg_size, 0
	.set abi_rank_zero_offsets.uses_vcc, 0
	.set abi_rank_zero_offsets.uses_flat_scratch, 0
	.set abi_rank_zero_offsets.has_dyn_sized_stack, 0
	.set abi_rank_zero_offsets.has_recursion, 0
	.set abi_rank_zero_offsets.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 32
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
	.protected	abi_shared_array_tail   ; -- Begin function abi_shared_array_tail
	.globl	abi_shared_array_tail
	.p2align	8
	.type	abi_shared_array_tail,@function
abi_shared_array_tail:                  ; @abi_shared_array_tail
; %bb.0:
	v_lshlrev_b32_e32 v2, 2, v0
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 48, v0
	s_cbranch_execz .LBB11_2
; %bb.1:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v3, s5
	flat_store_b32 v[2:3], v0 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB11_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_wait_dscnt 0x0
	v_mov_b32_e32 v3, s3
	s_barrier_signal -1
	s_barrier_wait -1
	s_load_b64 s[0:1], s[0:1], 0x0
	flat_load_b32 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_shared_array_tail
		.amdhsa_group_segment_fixed_size 192
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
		.amdhsa_next_free_sgpr 6
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
	.size	abi_shared_array_tail, .Lfunc_end11-abi_shared_array_tail
                                        ; -- End function
	.set abi_shared_array_tail.num_vgpr, 4
	.set abi_shared_array_tail.num_agpr, 0
	.set abi_shared_array_tail.numbered_sgpr, 6
	.set abi_shared_array_tail.num_named_barrier, 0
	.set abi_shared_array_tail.private_seg_size, 0
	.set abi_shared_array_tail.uses_vcc, 0
	.set abi_shared_array_tail.uses_flat_scratch, 0
	.set abi_shared_array_tail.has_dyn_sized_stack, 0
	.set abi_shared_array_tail.has_recursion, 0
	.set abi_shared_array_tail.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 116
; TotalNumSgprs: 6
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 192 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	abi_region_edge         ; -- Begin function abi_region_edge
	.globl	abi_region_edge
	.p2align	8
	.type	abi_region_edge,@function
abi_region_edge:                        ; @abi_region_edge
; %bb.0:
	v_dual_mov_b32 v4, 0 :: v_dual_mov_b32 v0, 1
	v_mov_b32_e32 v1, 2
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 32
	s_mov_b32 s4, 36
	s_mov_b32 s5, s3
	flat_store_b32 v4, v0, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v4, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_dual_mov_b32 v0, 3 :: v_dual_mov_b32 v1, 7
	s_mov_b32 s4, 40
	s_mov_b32 s6, 44
	s_mov_b32 s7, s3
	flat_store_b32 v4, v0, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v4, v1, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b128 v[0:3], v4, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	flat_load_b32 v2, v4, s[6:7] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x0
                                        ; kill: killed $sgpr6 killed $sgpr7
                                        ; kill: killed $sgpr2 killed $sgpr3
	v_mov_b32_e32 v3, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b64 v4, v[2:3], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_region_edge
		.amdhsa_group_segment_fixed_size 48
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
		.amdhsa_next_free_vgpr 5
		.amdhsa_next_free_sgpr 8
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
.Lfunc_end12:
	.size	abi_region_edge, .Lfunc_end12-abi_region_edge
                                        ; -- End function
	.set abi_region_edge.num_vgpr, 5
	.set abi_region_edge.num_agpr, 0
	.set abi_region_edge.numbered_sgpr, 8
	.set abi_region_edge.num_named_barrier, 0
	.set abi_region_edge.private_seg_size, 0
	.set abi_region_edge.uses_vcc, 0
	.set abi_region_edge.uses_flat_scratch, 0
	.set abi_region_edge.has_dyn_sized_stack, 0
	.set abi_region_edge.has_recursion, 0
	.set abi_region_edge.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 196
; TotalNumSgprs: 8
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 48 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 5
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 1
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
	.type	__hip_cuid_581f38407f701162,@object ; @__hip_cuid_581f38407f701162
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_581f38407f701162
__hip_cuid_581f38407f701162:
	.byte	0                               ; 0x0
	.size	__hip_cuid_581f38407f701162, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_581f38407f701162
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
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_shared_words
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         abi_shared_words.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_half_pair
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         abi_half_pair.kd
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
    .group_segment_fixed_size: 2
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_byte_pair
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         abi_byte_pair.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_scalar_granule
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         abi_scalar_granule.kd
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
    .group_segment_fixed_size: 6
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_pair_truncation
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         abi_pair_truncation.kd
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
    .group_segment_fixed_size: 256
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_logical_partitions
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         abi_logical_partitions.kd
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
    .max_flat_workgroup_size: 1024
    .name:           abi_global_vector_last
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         abi_global_vector_last.kd
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
    .max_flat_workgroup_size: 1024
    .name:           abi_half_at_two_mod_four
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         abi_half_at_two_mod_four.kd
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
    .max_flat_workgroup_size: 1024
    .name:           abi_upper_address
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         abi_upper_address.kd
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
    .max_flat_workgroup_size: 1024
    .name:           abi_negative_index
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         abi_negative_index.kd
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
    .max_flat_workgroup_size: 1024
    .name:           abi_rank_zero_offsets
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         abi_rank_zero_offsets.kd
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
    .group_segment_fixed_size: 192
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_shared_array_tail
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         abi_shared_array_tail.kd
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
    .group_segment_fixed_size: 48
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_region_edge
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         abi_region_edge.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     5
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
