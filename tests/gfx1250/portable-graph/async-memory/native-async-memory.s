	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	async_copy4_same_actor  ; -- Begin function async_copy4_same_actor
	.globl	async_copy4_same_actor
	.p2align	8
	.type	async_copy4_same_actor,@function
async_copy4_same_actor:                 ; @async_copy4_same_actor
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_ne_u32_e32 0, v0
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execnz .LBB0_3
; %bb.1:
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execnz .LBB0_4
.LBB0_2:
	s_endpgm
.LBB0_3:
	s_wait_tensorcnt 0x0
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB0_2
.LBB0_4:
	s_load_b128 s[8:11], s[0:1], 0x0
	s_mov_b64 s[20:21], src_shared_base
	s_mov_b32 s12, 1
	s_wait_xcnt 0x0
	s_mov_b32 s1, 0x10000
	s_mov_b32 s20, 0
	s_mov_b32 s0, 0x20000
	s_mov_b32 s2, s1
	s_mov_b32 s3, s1
	s_mov_b32 s4, s12
	s_mov_b32 s5, s12
	s_mov_b32 s13, s20
	s_mov_b32 s6, s20
	s_mov_b32 s7, s20
	s_mov_b32 s16, s20
	s_mov_b32 s17, s20
	s_mov_b32 s18, s20
	s_mov_b32 s19, s20
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_and_b32 s9, s9, 0x1ffffff
	s_mov_b32 s14, s8
	s_or_b32 s15, s9, 0x80000000
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[12:15], s[0:7], s[16:19], s[16:19]
	s_wait_tensorcnt 0x0
	flat_load_b32 v1, v0, s[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[10:11]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy4_same_actor
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 22
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
	.size	async_copy4_same_actor, .Lfunc_end0-async_copy4_same_actor
                                        ; -- End function
	.set async_copy4_same_actor.num_vgpr, 2
	.set async_copy4_same_actor.num_agpr, 0
	.set async_copy4_same_actor.numbered_sgpr, 22
	.set async_copy4_same_actor.num_named_barrier, 0
	.set async_copy4_same_actor.private_seg_size, 0
	.set async_copy4_same_actor.uses_vcc, 0
	.set async_copy4_same_actor.uses_flat_scratch, 0
	.set async_copy4_same_actor.has_dyn_sized_stack, 0
	.set async_copy4_same_actor.has_recursion, 0
	.set async_copy4_same_actor.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 204
; TotalNumSgprs: 22
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 22
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
	.protected	async_copy16_same_actor ; -- Begin function async_copy16_same_actor
	.globl	async_copy16_same_actor
	.p2align	8
	.type	async_copy16_same_actor,@function
async_copy16_same_actor:                ; @async_copy16_same_actor
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_ne_u32_e32 0, v0
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execnz .LBB1_3
; %bb.1:
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execnz .LBB1_4
.LBB1_2:
	s_endpgm
.LBB1_3:
	s_wait_tensorcnt 0x0
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB1_2
.LBB1_4:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b64 s[20:21], src_shared_base
	s_mov_b32 s12, 1
	s_mov_b32 s5, 0x40000
	s_mov_b32 s20, 0
	s_mov_b32 s9, 4
	s_mov_b32 s6, 0x10000
	s_mov_b32 s4, 0x20000
	s_mov_b32 s7, s5
	s_mov_b32 s8, s12
	s_mov_b32 s13, s20
	s_mov_b32 s10, s20
	s_mov_b32 s11, s20
	s_mov_b32 s16, s20
	s_mov_b32 s17, s20
	s_mov_b32 s18, s20
	s_mov_b32 s19, s20
	v_mov_b32_e32 v4, 0
	s_wait_kmcnt 0x0
	s_and_b32 s1, s1, 0x1ffffff
	s_mov_b32 s14, s0
	s_or_b32 s15, s1, 0x80000000
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[12:15], s[4:11], s[16:19], s[16:19]
	s_wait_tensorcnt 0x0
	flat_load_b32 v0, v4, s[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s20, s9
	flat_load_b32 v1, v4, s[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s20, 8
	flat_load_b32 v2, v4, s[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s20, 12
	flat_load_b32 v3, v4, s[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b128 v4, v[0:3], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy16_same_actor
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
		.amdhsa_next_free_sgpr 22
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
	.size	async_copy16_same_actor, .Lfunc_end1-async_copy16_same_actor
                                        ; -- End function
	.set async_copy16_same_actor.num_vgpr, 5
	.set async_copy16_same_actor.num_agpr, 0
	.set async_copy16_same_actor.numbered_sgpr, 22
	.set async_copy16_same_actor.num_named_barrier, 0
	.set async_copy16_same_actor.private_seg_size, 0
	.set async_copy16_same_actor.uses_vcc, 0
	.set async_copy16_same_actor.uses_flat_scratch, 0
	.set async_copy16_same_actor.has_dyn_sized_stack, 0
	.set async_copy16_same_actor.has_recursion, 0
	.set async_copy16_same_actor.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 276
; TotalNumSgprs: 22
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 22
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
	.protected	async_copy4_cross_wave  ; -- Begin function async_copy4_cross_wave
	.globl	async_copy4_cross_wave
	.p2align	8
	.type	async_copy4_cross_wave,@function
async_copy4_cross_wave:                 ; @async_copy4_cross_wave
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s5, 0
	s_mov_b32 s8, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB2_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s1, s1, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x10000
	s_or_b32 s7, s1, 0x80000000
	s_mov_b32 s6, s0
	s_mov_b32 s12, 0x20000
	s_mov_b32 s14, s13
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s17, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB2_2:
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB2_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB2_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy4_cross_wave
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 24
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
	.size	async_copy4_cross_wave, .Lfunc_end2-async_copy4_cross_wave
                                        ; -- End function
	.set async_copy4_cross_wave.num_vgpr, 2
	.set async_copy4_cross_wave.num_agpr, 0
	.set async_copy4_cross_wave.numbered_sgpr, 24
	.set async_copy4_cross_wave.num_named_barrier, 0
	.set async_copy4_cross_wave.private_seg_size, 0
	.set async_copy4_cross_wave.uses_vcc, 0
	.set async_copy4_cross_wave.uses_flat_scratch, 0
	.set async_copy4_cross_wave.has_dyn_sized_stack, 0
	.set async_copy4_cross_wave.has_recursion, 0
	.set async_copy4_cross_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 200
; TotalNumSgprs: 24
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
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
	.protected	async_copy16_cross_wave ; -- Begin function async_copy16_cross_wave
	.globl	async_copy16_cross_wave
	.p2align	8
	.type	async_copy16_cross_wave,@function
async_copy16_cross_wave:                ; @async_copy16_cross_wave
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s5, 0
	s_mov_b32 s8, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB3_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s1, s1, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x40000
	s_or_b32 s7, s1, 0x80000000
	s_mov_b32 s6, s0
	s_mov_b32 s17, 4
	s_mov_b32 s14, 0x10000
	s_mov_b32 s12, 0x20000
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB3_2:
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB3_4
; %bb.3:
	v_mov_b32_e32 v4, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v0, v4, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 4
	flat_load_b32 v1, v4, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 8
	flat_load_b32 v2, v4, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 12
	flat_load_b32 v3, v4, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b128 v4, v[0:3], s[2:3]
.LBB3_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy16_cross_wave
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
		.amdhsa_next_free_sgpr 24
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
	.size	async_copy16_cross_wave, .Lfunc_end3-async_copy16_cross_wave
                                        ; -- End function
	.set async_copy16_cross_wave.num_vgpr, 5
	.set async_copy16_cross_wave.num_agpr, 0
	.set async_copy16_cross_wave.numbered_sgpr, 24
	.set async_copy16_cross_wave.num_named_barrier, 0
	.set async_copy16_cross_wave.private_seg_size, 0
	.set async_copy16_cross_wave.uses_vcc, 0
	.set async_copy16_cross_wave.uses_flat_scratch, 0
	.set async_copy16_cross_wave.has_dyn_sized_stack, 0
	.set async_copy16_cross_wave.has_recursion, 0
	.set async_copy16_cross_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 276
; TotalNumSgprs: 24
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
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
	.protected	async_copy4_destination_reuse_same_actor ; -- Begin function async_copy4_destination_reuse_same_actor
	.globl	async_copy4_destination_reuse_same_actor
	.p2align	8
	.type	async_copy4_destination_reuse_same_actor,@function
async_copy4_destination_reuse_same_actor: ; @async_copy4_destination_reuse_same_actor
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_ne_u32_e32 0, v0
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execnz .LBB4_3
; %bb.1:
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execnz .LBB4_4
.LBB4_2:
	s_endpgm
.LBB4_3:
	s_wait_tensorcnt 0x0
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB4_2
.LBB4_4:
	s_load_b128 s[8:11], s[0:1], 0x0
	s_mov_b64 s[20:21], src_shared_base
	s_mov_b32 s12, 1
	s_wait_xcnt 0x0
	s_mov_b32 s1, 0x10000
	s_mov_b32 s20, 0
	s_mov_b32 s0, 0x20000
	s_mov_b32 s2, s1
	s_mov_b32 s3, s1
	s_mov_b32 s4, s12
	s_mov_b32 s5, s12
	s_mov_b32 s13, s20
	s_mov_b32 s6, s20
	s_mov_b32 s7, s20
	s_mov_b32 s16, s20
	s_mov_b32 s17, s20
	s_mov_b32 s18, s20
	s_mov_b32 s19, s20
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_and_b32 s15, s9, 0x1ffffff
	s_mov_b32 s14, s8
	s_bitset1_b32 s15, 31
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[12:15], s[0:7], s[16:19], s[16:19]
	s_wait_tensorcnt 0x0
	s_load_b32 s0, s[8:9], 0x4
	s_wait_kmcnt 0x0
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v0, v1, s[20:21] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v1, v0, s[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[10:11]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy4_destination_reuse_same_actor
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 22
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
	.size	async_copy4_destination_reuse_same_actor, .Lfunc_end4-async_copy4_destination_reuse_same_actor
                                        ; -- End function
	.set async_copy4_destination_reuse_same_actor.num_vgpr, 2
	.set async_copy4_destination_reuse_same_actor.num_agpr, 0
	.set async_copy4_destination_reuse_same_actor.numbered_sgpr, 22
	.set async_copy4_destination_reuse_same_actor.num_named_barrier, 0
	.set async_copy4_destination_reuse_same_actor.private_seg_size, 0
	.set async_copy4_destination_reuse_same_actor.uses_vcc, 0
	.set async_copy4_destination_reuse_same_actor.uses_flat_scratch, 0
	.set async_copy4_destination_reuse_same_actor.has_dyn_sized_stack, 0
	.set async_copy4_destination_reuse_same_actor.has_recursion, 0
	.set async_copy4_destination_reuse_same_actor.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 22
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 22
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
	.protected	async_copy4_destination_reuse_cross_wave ; -- Begin function async_copy4_destination_reuse_cross_wave
	.globl	async_copy4_destination_reuse_cross_wave
	.p2align	8
	.type	async_copy4_destination_reuse_cross_wave,@function
async_copy4_destination_reuse_cross_wave: ; @async_copy4_destination_reuse_cross_wave
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s5, 0
	s_mov_b32 s8, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB5_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s6, s1, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x10000
	s_or_b32 s7, s6, 0x80000000
	s_mov_b32 s6, s0
	s_mov_b32 s12, 0x20000
	s_mov_b32 s14, s13
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s17, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB5_2:
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB5_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x4
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v0, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v1, v0, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
.LBB5_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy4_destination_reuse_cross_wave
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end5:
	.size	async_copy4_destination_reuse_cross_wave, .Lfunc_end5-async_copy4_destination_reuse_cross_wave
                                        ; -- End function
	.set async_copy4_destination_reuse_cross_wave.num_vgpr, 2
	.set async_copy4_destination_reuse_cross_wave.num_agpr, 0
	.set async_copy4_destination_reuse_cross_wave.numbered_sgpr, 24
	.set async_copy4_destination_reuse_cross_wave.num_named_barrier, 0
	.set async_copy4_destination_reuse_cross_wave.private_seg_size, 0
	.set async_copy4_destination_reuse_cross_wave.uses_vcc, 0
	.set async_copy4_destination_reuse_cross_wave.uses_flat_scratch, 0
	.set async_copy4_destination_reuse_cross_wave.has_dyn_sized_stack, 0
	.set async_copy4_destination_reuse_cross_wave.has_recursion, 0
	.set async_copy4_destination_reuse_cross_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 24
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
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
	.protected	async_copy16_source_reuse ; -- Begin function async_copy16_source_reuse
	.globl	async_copy16_source_reuse
	.p2align	8
	.type	async_copy16_source_reuse,@function
async_copy16_source_reuse:              ; @async_copy16_source_reuse
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB6_2
; %bb.1:
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s7 :: v_dual_lshlrev_b32 v2, 2, v0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB6_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_mov_b32 s5, 0
	s_mov_b32 s8, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB6_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_and_b32 s6, s3, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x40000
	s_or_b32 s7, s6, 0x80000000
	s_mov_b32 s6, s2
	s_mov_b32 s17, 4
	s_mov_b32 s14, 0x10000
	s_mov_b32 s12, 0x20000
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_store_from_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB6_4:
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB6_6
; %bb.5:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] offset:16
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v0, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v1, v0, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:16
.LBB6_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy16_source_reuse
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end6:
	.size	async_copy16_source_reuse, .Lfunc_end6-async_copy16_source_reuse
                                        ; -- End function
	.set async_copy16_source_reuse.num_vgpr, 4
	.set async_copy16_source_reuse.num_agpr, 0
	.set async_copy16_source_reuse.numbered_sgpr, 24
	.set async_copy16_source_reuse.num_named_barrier, 0
	.set async_copy16_source_reuse.private_seg_size, 0
	.set async_copy16_source_reuse.uses_vcc, 0
	.set async_copy16_source_reuse.uses_flat_scratch, 0
	.set async_copy16_source_reuse.has_dyn_sized_stack, 0
	.set async_copy16_source_reuse.has_recursion, 0
	.set async_copy16_source_reuse.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 320
; TotalNumSgprs: 24
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
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
	.protected	async_two_16byte_regions ; -- Begin function async_two_16byte_regions
	.globl	async_two_16byte_regions
	.p2align	8
	.type	async_two_16byte_regions,@function
async_two_16byte_regions:               ; @async_two_16byte_regions
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s5, 0
	s_mov_b32 s8, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB7_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s6, s1, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x40000
	s_or_b32 s7, s6, 0x80000000
	s_mov_b32 s6, s0
	s_mov_b32 s17, 4
	s_mov_b32 s14, 0x10000
	s_mov_b32 s12, 0x20000
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
	s_add_nc_u64 s[6:7], s[0:1], 16
	s_mov_b32 s5, 16
	s_and_b32 s0, s7, 0x1ffffff
	s_or_b32 s7, s0, 0x80000000
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB7_2:
	s_or_b32 exec_lo, exec_lo, s8
	v_mov_b32_e32 v1, 0
	s_wait_kmcnt 0x0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 16
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b32 v1, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_two_16byte_regions
		.amdhsa_group_segment_fixed_size 32
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
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end7:
	.size	async_two_16byte_regions, .Lfunc_end7-async_two_16byte_regions
                                        ; -- End function
	.set async_two_16byte_regions.num_vgpr, 2
	.set async_two_16byte_regions.num_agpr, 0
	.set async_two_16byte_regions.numbered_sgpr, 24
	.set async_two_16byte_regions.num_named_barrier, 0
	.set async_two_16byte_regions.private_seg_size, 0
	.set async_two_16byte_regions.uses_vcc, 0
	.set async_two_16byte_regions.uses_flat_scratch, 0
	.set async_two_16byte_regions.has_dyn_sized_stack, 0
	.set async_two_16byte_regions.has_recursion, 0
	.set async_two_16byte_regions.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 24
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
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
	.protected	async_no_output128_reuse ; -- Begin function async_no_output128_reuse
	.globl	async_no_output128_reuse
	.p2align	8
	.type	async_no_output128_reuse,@function
async_no_output128_reuse:               ; @async_no_output128_reuse
; %bb.0:
	s_load_b64 s[4:5], s[0:1], 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s1, 0
	s_mov_b32 s6, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB8_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s2, s5, 0x1ffffff
	s_mov_b32 s0, 1
	s_mov_b32 s9, 0x200000
	s_or_b32 s3, s2, 0x80000000
	s_mov_b32 s2, s4
	s_mov_b32 s13, 32
	s_mov_b32 s10, 0x10000
	s_mov_b32 s8, 0x20000
	s_mov_b32 s11, s9
	s_mov_b32 s12, s0
	s_mov_b32 s14, s1
	s_mov_b32 s15, s1
	s_mov_b32 s16, s1
	s_mov_b32 s17, s1
	s_mov_b32 s18, s1
	s_mov_b32 s19, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[0:3], s[8:15], s[16:19], s[16:19]
.LBB8_2:
	s_or_b32 exec_lo, exec_lo, s6
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB8_4
; %bb.3:
	s_mov_b64 s[0:1], src_shared_base
	s_wait_kmcnt 0x0
	global_load_b32 v2, v0, s[4:5] scale_offset
	s_wait_xcnt 0x0
	v_lshl_add_u32 v0, v0, 2, 0xffffff80
	v_mov_b32_e32 v1, s1
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_f32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v[0:1], v2 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB8_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_no_output128_reuse
		.amdhsa_group_segment_fixed_size 128
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
		.amdhsa_next_free_sgpr 20
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
	.size	async_no_output128_reuse, .Lfunc_end8-async_no_output128_reuse
                                        ; -- End function
	.set async_no_output128_reuse.num_vgpr, 3
	.set async_no_output128_reuse.num_agpr, 0
	.set async_no_output128_reuse.numbered_sgpr, 20
	.set async_no_output128_reuse.num_named_barrier, 0
	.set async_no_output128_reuse.private_seg_size, 0
	.set async_no_output128_reuse.uses_vcc, 0
	.set async_no_output128_reuse.uses_flat_scratch, 0
	.set async_no_output128_reuse.has_dyn_sized_stack, 0
	.set async_no_output128_reuse.has_recursion, 0
	.set async_no_output128_reuse.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 224
; TotalNumSgprs: 20
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 20
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
	.protected	async_copy4_global_source_reuse ; -- Begin function async_copy4_global_source_reuse
	.globl	async_copy4_global_source_reuse
	.p2align	8
	.type	async_copy4_global_source_reuse,@function
async_copy4_global_source_reuse:        ; @async_copy4_global_source_reuse
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s5, 0
	s_mov_b32 s8, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB9_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s6, s1, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x10000
	s_or_b32 s7, s6, 0x80000000
	s_mov_b32 s6, s0
	s_mov_b32 s12, 0x20000
	s_mov_b32 s14, s13
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s17, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB9_2:
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB9_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_wait_kmcnt 0x0
	flat_load_b32 v1, v0, s[0:1] offset:4 scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	flat_store_b32 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v1, v0, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB9_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel async_copy4_global_source_reuse
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end9:
	.size	async_copy4_global_source_reuse, .Lfunc_end9-async_copy4_global_source_reuse
                                        ; -- End function
	.set async_copy4_global_source_reuse.num_vgpr, 2
	.set async_copy4_global_source_reuse.num_agpr, 0
	.set async_copy4_global_source_reuse.numbered_sgpr, 24
	.set async_copy4_global_source_reuse.num_named_barrier, 0
	.set async_copy4_global_source_reuse.private_seg_size, 0
	.set async_copy4_global_source_reuse.uses_vcc, 0
	.set async_copy4_global_source_reuse.uses_flat_scratch, 0
	.set async_copy4_global_source_reuse.has_dyn_sized_stack, 0
	.set async_copy4_global_source_reuse.has_recursion, 0
	.set async_copy4_global_source_reuse.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 24
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
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
	.type	__hip_cuid_36e945cd30c2def7,@object ; @__hip_cuid_36e945cd30c2def7
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_36e945cd30c2def7
__hip_cuid_36e945cd30c2def7:
	.byte	0                               ; 0x0
	.size	__hip_cuid_36e945cd30c2def7, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_36e945cd30c2def7
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
    .max_flat_workgroup_size: 64
    .name:           async_copy4_same_actor
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         async_copy4_same_actor.kd
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
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           async_copy16_same_actor
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         async_copy16_same_actor.kd
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
    .max_flat_workgroup_size: 64
    .name:           async_copy4_cross_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         async_copy4_cross_wave.kd
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
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           async_copy16_cross_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         async_copy16_cross_wave.kd
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
    .max_flat_workgroup_size: 64
    .name:           async_copy4_destination_reuse_same_actor
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         async_copy4_destination_reuse_same_actor.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           async_copy4_destination_reuse_cross_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         async_copy4_destination_reuse_cross_wave.kd
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
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           async_copy16_source_reuse
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         async_copy16_source_reuse.kd
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
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           async_two_16byte_regions
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         async_two_16byte_regions.kd
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
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           async_no_output128_reuse
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         async_no_output128_reuse.kd
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
    .max_flat_workgroup_size: 64
    .name:           async_copy4_global_source_reuse
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         async_copy4_global_source_reuse.kd
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
