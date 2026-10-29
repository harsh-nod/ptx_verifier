	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	payload_same_value      ; -- Begin function payload_same_value
	.globl	payload_same_value
	.p2align	8
	.type	payload_same_value,@function
payload_same_value:                     ; @payload_same_value
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 2, v0
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_mov_b64 s[6:7], src_shared_base
	s_mov_b32 s6, 0
	s_wait_kmcnt 0x0
	s_add_f32 s0, s0, s0
	s_delay_alu instid0(SALU_CYCLE_3)
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, s0
	flat_store_b32 v1, v2, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_kmcnt 0x0
	s_mov_b32 s0, 0
	s_wait_dscnt 0x0
	; wave barrier
	s_mov_b32 s1, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, s5
	flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB0_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_same_value
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
.Lfunc_end0:
	.size	payload_same_value, .Lfunc_end0-payload_same_value
                                        ; -- End function
	.set payload_same_value.num_vgpr, 3
	.set payload_same_value.num_agpr, 0
	.set payload_same_value.numbered_sgpr, 8
	.set payload_same_value.num_named_barrier, 0
	.set payload_same_value.private_seg_size, 0
	.set payload_same_value.uses_vcc, 0
	.set payload_same_value.uses_flat_scratch, 0
	.set payload_same_value.has_dyn_sized_stack, 0
	.set payload_same_value.has_recursion, 0
	.set payload_same_value.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 156
; TotalNumSgprs: 8
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 8
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
	.protected	payload_different_values ; -- Begin function payload_different_values
	.globl	payload_different_values
	.p2align	8
	.type	payload_different_values,@function
payload_different_values:               ; @payload_different_values
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 2, v0
	s_cbranch_execz .LBB1_2
; %bb.1:
	v_cvt_f32_ubyte0_e32 v1, v0
	v_mov_b32_e32 v2, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	flat_store_b32 v2, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b32 s2, 0
	s_wait_dscnt 0x0
	; wave barrier
	s_mov_b32 s3, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_load_b64 s[0:1], s[0:1], 0x8
	s_mov_b32 s3, s5
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
.LBB1_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_different_values
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
	.size	payload_different_values, .Lfunc_end1-payload_different_values
                                        ; -- End function
	.set payload_different_values.num_vgpr, 3
	.set payload_different_values.num_agpr, 0
	.set payload_different_values.numbered_sgpr, 6
	.set payload_different_values.num_named_barrier, 0
	.set payload_different_values.private_seg_size, 0
	.set payload_different_values.uses_vcc, 0
	.set payload_different_values.uses_flat_scratch, 0
	.set payload_different_values.has_dyn_sized_stack, 0
	.set payload_different_values.has_recursion, 0
	.set payload_different_values.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 128
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
	.protected	payload_shared_writers  ; -- Begin function payload_shared_writers
	.globl	payload_shared_writers
	.p2align	8
	.type	payload_shared_writers,@function
payload_shared_writers:                 ; @payload_shared_writers
; %bb.0:
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 2, v0
	s_cbranch_execz .LBB2_2
; %bb.1:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_store_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_shared_writers
		.amdhsa_group_segment_fixed_size 8
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 0
		.amdhsa_user_sgpr_count 0
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 0
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
.Lfunc_end2:
	.size	payload_shared_writers, .Lfunc_end2-payload_shared_writers
                                        ; -- End function
	.set payload_shared_writers.num_vgpr, 2
	.set payload_shared_writers.num_agpr, 0
	.set payload_shared_writers.numbered_sgpr, 2
	.set payload_shared_writers.num_named_barrier, 0
	.set payload_shared_writers.private_seg_size, 0
	.set payload_shared_writers.uses_vcc, 0
	.set payload_shared_writers.uses_flat_scratch, 0
	.set payload_shared_writers.has_dyn_sized_stack, 0
	.set payload_shared_writers.has_recursion, 0
	.set payload_shared_writers.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 44
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 2
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 0
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	payload_address_alias   ; -- Begin function payload_address_alias
	.globl	payload_address_alias
	.p2align	8
	.type	payload_address_alias,@function
payload_address_alias:                  ; @payload_address_alias
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 2, v0
	s_cbranch_execz .LBB3_2
; %bb.1:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v0, 1, v0
	s_wait_kmcnt 0x0
	global_store_b32 v1, v0, s[0:1] offset:4
.LBB3_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_address_alias
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
		.amdhsa_next_free_sgpr 3
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
	.size	payload_address_alias, .Lfunc_end3-payload_address_alias
                                        ; -- End function
	.set payload_address_alias.num_vgpr, 2
	.set payload_address_alias.num_agpr, 0
	.set payload_address_alias.numbered_sgpr, 3
	.set payload_address_alias.num_named_barrier, 0
	.set payload_address_alias.private_seg_size, 0
	.set payload_address_alias.uses_vcc, 0
	.set payload_address_alias.uses_flat_scratch, 0
	.set payload_address_alias.has_dyn_sized_stack, 0
	.set payload_address_alias.has_recursion, 0
	.set payload_address_alias.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 48
; TotalNumSgprs: 3
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 3
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
	.protected	payload_neighbor_exchange ; -- Begin function payload_neighbor_exchange
	.globl	payload_neighbor_exchange
	.p2align	8
	.type	payload_neighbor_exchange,@function
payload_neighbor_exchange:              ; @payload_neighbor_exchange
; %bb.0:
	s_mov_b32 s2, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB4_2
; %bb.1:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[6:7], src_shared_base
	s_mov_b32 s6, 4
	s_mov_b32 s3, s7
	flat_store_b32 v1, v1, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v1, v1, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_mov_b32 s4, 0
	s_mov_b32 s2, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_lt_i32_e32 31, v0
	s_xor_b32 s2, exec_lo, s2
; %bb.3:
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
	s_and_b32 s4, vcc_lo, exec_lo
; %bb.4:
	s_and_not1_saveexec_b32 s2, s2
; %bb.5:
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_and_not1_b32 s3, s4, exec_lo
	s_and_b32 s4, vcc_lo, exec_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 s4, s3, s4
; %bb.6:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[0:3], s[0:1], 0x0
	v_lshrrev_b32_e32 v2, 3, v0
	s_and_saveexec_b32 s5, s4
	s_cbranch_execz .LBB4_8
; %bb.7:
	s_wait_kmcnt 0x0
	global_load_b32 v1, v2, s[0:1]
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v3, s7
	s_wait_loadcnt 0x0
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s5
	s_wait_kmcnt 0x0
	s_mov_b32 s0, 0
	s_mov_b32 s1, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_lt_i32_e32 31, v0
	s_xor_b32 s1, exec_lo, s1
; %bb.9:
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
                                        ; implicit-def: $vgpr0
	s_and_b32 s0, vcc_lo, exec_lo
; %bb.10:
	s_and_not1_saveexec_b32 s1, s1
; %bb.11:
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_and_not1_b32 s0, s0, exec_lo
	s_and_b32 s4, vcc_lo, exec_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 s0, s0, s4
; %bb.12:
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB4_14
; %bb.13:
	s_mov_b64 s[0:1], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v1, s1 :: v_dual_bitop2_b32 v0, 4, v2 bitop3:0x14
	flat_load_b32 v0, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v2, v0, s[2:3]
.LBB4_14:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_neighbor_exchange
		.amdhsa_group_segment_fixed_size 8
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
.Lfunc_end4:
	.size	payload_neighbor_exchange, .Lfunc_end4-payload_neighbor_exchange
                                        ; -- End function
	.set payload_neighbor_exchange.num_vgpr, 4
	.set payload_neighbor_exchange.num_agpr, 0
	.set payload_neighbor_exchange.numbered_sgpr, 8
	.set payload_neighbor_exchange.num_named_barrier, 0
	.set payload_neighbor_exchange.private_seg_size, 0
	.set payload_neighbor_exchange.uses_vcc, 1
	.set payload_neighbor_exchange.uses_flat_scratch, 0
	.set payload_neighbor_exchange.has_dyn_sized_stack, 0
	.set payload_neighbor_exchange.has_recursion, 0
	.set payload_neighbor_exchange.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 340
; TotalNumSgprs: 10
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.protected	payload_ordered_equal_values ; -- Begin function payload_ordered_equal_values
	.globl	payload_ordered_equal_values
	.p2align	8
	.type	payload_ordered_equal_values,@function
payload_ordered_equal_values:           ; @payload_ordered_equal_values
; %bb.0:
	s_load_b128 s[4:7], s[0:1], 0x0
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_load_b32 s1, s[4:5], 0x0
	s_mov_b64 s[8:9], src_shared_base
	s_wait_kmcnt 0x0
	s_add_f32 s1, s1, s1
	s_delay_alu instid0(SALU_CYCLE_3)
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, s1
	s_mov_b32 s1, s9
	flat_store_b32 v1, v2, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB5_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[4:5]
	s_wait_loadcnt 0x0
	v_add_f32_e32 v1, v1, v1
	flat_store_b32 v0, v1, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB5_6
; %bb.5:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[6:7]
.LBB5_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_ordered_equal_values
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
.Lfunc_end5:
	.size	payload_ordered_equal_values, .Lfunc_end5-payload_ordered_equal_values
                                        ; -- End function
	.set payload_ordered_equal_values.num_vgpr, 3
	.set payload_ordered_equal_values.num_agpr, 0
	.set payload_ordered_equal_values.numbered_sgpr, 10
	.set payload_ordered_equal_values.num_named_barrier, 0
	.set payload_ordered_equal_values.private_seg_size, 0
	.set payload_ordered_equal_values.uses_vcc, 1
	.set payload_ordered_equal_values.uses_flat_scratch, 0
	.set payload_ordered_equal_values.has_dyn_sized_stack, 0
	.set payload_ordered_equal_values.has_recursion, 0
	.set payload_ordered_equal_values.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 248
; TotalNumSgprs: 12
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 12
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
	.protected	payload_publish_42      ; -- Begin function payload_publish_42
	.globl	payload_publish_42
	.p2align	8
	.type	payload_publish_42,@function
payload_publish_42:                     ; @payload_publish_42
; %bb.0:
	s_mov_b32 s2, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB6_2
; %bb.1:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 42
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s7
	flat_store_b32 v1, v2, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB6_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB6_4
; %bb.3:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
.LBB6_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_publish_42
		.amdhsa_group_segment_fixed_size 4
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
.Lfunc_end6:
	.size	payload_publish_42, .Lfunc_end6-payload_publish_42
                                        ; -- End function
	.set payload_publish_42.num_vgpr, 3
	.set payload_publish_42.num_agpr, 0
	.set payload_publish_42.numbered_sgpr, 8
	.set payload_publish_42.num_named_barrier, 0
	.set payload_publish_42.private_seg_size, 0
	.set payload_publish_42.uses_vcc, 0
	.set payload_publish_42.uses_flat_scratch, 0
	.set payload_publish_42.has_dyn_sized_stack, 0
	.set payload_publish_42.has_recursion, 0
	.set payload_publish_42.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 140
; TotalNumSgprs: 8
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 8
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
	.protected	payload_address_broadcast ; -- Begin function payload_address_broadcast
	.globl	payload_address_broadcast
	.p2align	8
	.type	payload_address_broadcast,@function
payload_address_broadcast:              ; @payload_address_broadcast
; %bb.0:
	s_mov_b32 s0, 0
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB7_2
; %bb.1:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 4
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, s5
	flat_store_b32 v1, v2, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB7_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_mov_b32_e32 v1, 0
	s_mov_b32 s0, exec_lo
	ds_bpermute_b32 v2, v1, v0
	v_subrev_nc_u32_e32 v0, 32, v0
	s_wait_dscnt 0x0
	;;#ASMSTART
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 31, v0
	s_cbranch_execz .LBB7_4
; %bb.3:
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	;;#ASMEND
.LBB7_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_address_broadcast
		.amdhsa_group_segment_fixed_size 8
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 0
		.amdhsa_user_sgpr_count 0
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 0
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
	.size	payload_address_broadcast, .Lfunc_end7-payload_address_broadcast
                                        ; -- End function
	.set payload_address_broadcast.num_vgpr, 3
	.set payload_address_broadcast.num_agpr, 0
	.set payload_address_broadcast.numbered_sgpr, 6
	.set payload_address_broadcast.num_named_barrier, 0
	.set payload_address_broadcast.private_seg_size, 0
	.set payload_address_broadcast.uses_vcc, 0
	.set payload_address_broadcast.uses_flat_scratch, 0
	.set payload_address_broadcast.has_dyn_sized_stack, 0
	.set payload_address_broadcast.has_recursion, 0
	.set payload_address_broadcast.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 128
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 3
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 0
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	payload_collective_then_publish ; -- Begin function payload_collective_then_publish
	.globl	payload_collective_then_publish
	.p2align	8
	.type	payload_collective_then_publish,@function
payload_collective_then_publish:        ; @payload_collective_then_publish
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 1, v0
	s_cbranch_execz .LBB8_2
; %bb.1:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 1
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	flat_store_b32 v1, v2, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB8_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_mov_b32_e32 v1, 0
	s_mov_b32 s2, exec_lo
	ds_bpermute_b32 v2, v1, v0
	s_wait_dscnt 0x0
	;;#ASMSTART
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB8_4
; %bb.3:
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	s_load_b64 s[0:1], s[0:1], 0x0
	flat_load_b32 v0, v1, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_u32_e32 v0, v0
	s_wait_kmcnt 0x0
	global_store_b32 v1, v0, s[0:1]
.LBB8_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel payload_collective_then_publish
		.amdhsa_group_segment_fixed_size 4
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
.Lfunc_end8:
	.size	payload_collective_then_publish, .Lfunc_end8-payload_collective_then_publish
                                        ; -- End function
	.set payload_collective_then_publish.num_vgpr, 3
	.set payload_collective_then_publish.num_agpr, 0
	.set payload_collective_then_publish.numbered_sgpr, 6
	.set payload_collective_then_publish.num_named_barrier, 0
	.set payload_collective_then_publish.private_seg_size, 0
	.set payload_collective_then_publish.uses_vcc, 0
	.set payload_collective_then_publish.uses_flat_scratch, 0
	.set payload_collective_then_publish.has_dyn_sized_stack, 0
	.set payload_collective_then_publish.has_recursion, 0
	.set payload_collective_then_publish.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 144
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_83de684ecdaa5ab7,@object ; @__hip_cuid_83de684ecdaa5ab7
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_83de684ecdaa5ab7
__hip_cuid_83de684ecdaa5ab7:
	.byte	0                               ; 0x0
	.size	__hip_cuid_83de684ecdaa5ab7, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_83de684ecdaa5ab7
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           payload_same_value
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         payload_same_value.kd
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
    .max_flat_workgroup_size: 32
    .name:           payload_different_values
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         payload_different_values.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:           []
    .group_segment_fixed_size: 8
    .kernarg_segment_align: 4
    .kernarg_segment_size: 0
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           payload_shared_writers
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         payload_shared_writers.kd
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
    .max_flat_workgroup_size: 32
    .name:           payload_address_alias
    .private_segment_fixed_size: 0
    .sgpr_count:     3
    .sgpr_spill_count: 0
    .symbol:         payload_address_alias.kd
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
    .group_segment_fixed_size: 8
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           payload_neighbor_exchange
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         payload_neighbor_exchange.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           payload_ordered_equal_values
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         payload_ordered_equal_values.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           payload_publish_42
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         payload_publish_42.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:           []
    .group_segment_fixed_size: 8
    .kernarg_segment_align: 4
    .kernarg_segment_size: 0
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           payload_address_broadcast
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         payload_address_broadcast.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           payload_collective_then_publish
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         payload_collective_then_publish.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
