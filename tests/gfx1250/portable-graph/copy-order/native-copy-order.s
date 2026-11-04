	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	copy_scalar_same_wave   ; -- Begin function copy_scalar_same_wave
	.globl	copy_scalar_same_wave
	.p2align	8
	.type	copy_scalar_same_wave,@function
copy_scalar_same_wave:                  ; @copy_scalar_same_wave
; %bb.0:
	s_mov_b32 s2, 0
	s_mov_b32 s3, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_load_b128 s[4:7], s[0:1], 0x0
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s9
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[4:5], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	flat_store_b32 v0, v1, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[6:7]
.LBB0_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel copy_scalar_same_wave
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
		.amdhsa_next_free_sgpr 10
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
	.size	copy_scalar_same_wave, .Lfunc_end0-copy_scalar_same_wave
                                        ; -- End function
	.set copy_scalar_same_wave.num_vgpr, 2
	.set copy_scalar_same_wave.num_agpr, 0
	.set copy_scalar_same_wave.numbered_sgpr, 10
	.set copy_scalar_same_wave.num_named_barrier, 0
	.set copy_scalar_same_wave.private_seg_size, 0
	.set copy_scalar_same_wave.uses_vcc, 0
	.set copy_scalar_same_wave.uses_flat_scratch, 0
	.set copy_scalar_same_wave.has_dyn_sized_stack, 0
	.set copy_scalar_same_wave.has_recursion, 0
	.set copy_scalar_same_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 108
; TotalNumSgprs: 10
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.protected	copy_scalar_cross_wave  ; -- Begin function copy_scalar_cross_wave
	.globl	copy_scalar_cross_wave
	.p2align	8
	.type	copy_scalar_cross_wave,@function
copy_scalar_cross_wave:                 ; @copy_scalar_cross_wave
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, 0
	s_mov_b32 s6, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s5, s9
	s_wait_kmcnt 0x0
	v_mov_b32_e32 v2, s0
	flat_store_b32 v1, v2, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s6
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB1_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB1_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel copy_scalar_cross_wave
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
	.size	copy_scalar_cross_wave, .Lfunc_end1-copy_scalar_cross_wave
                                        ; -- End function
	.set copy_scalar_cross_wave.num_vgpr, 3
	.set copy_scalar_cross_wave.num_agpr, 0
	.set copy_scalar_cross_wave.numbered_sgpr, 10
	.set copy_scalar_cross_wave.num_named_barrier, 0
	.set copy_scalar_cross_wave.private_seg_size, 0
	.set copy_scalar_cross_wave.uses_vcc, 0
	.set copy_scalar_cross_wave.uses_flat_scratch, 0
	.set copy_scalar_cross_wave.has_dyn_sized_stack, 0
	.set copy_scalar_cross_wave.has_recursion, 0
	.set copy_scalar_cross_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 156
; TotalNumSgprs: 10
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.protected	copy_both_regions_before_publication ; -- Begin function copy_both_regions_before_publication
	.globl	copy_both_regions_before_publication
	.p2align	8
	.type	copy_both_regions_before_publication,@function
copy_both_regions_before_publication:   ; @copy_both_regions_before_publication
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, 0
	s_mov_b32 s6, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB2_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_load_b256 s[8:15], s[0:1], 0x0
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[16:17], src_shared_base
	s_mov_b32 s16, 16
	s_mov_b32 s5, s17
	s_wait_kmcnt 0x0
	v_mov_b64_e32 v[2:3], s[8:9]
	v_mov_b64_e32 v[4:5], s[10:11]
	v_mov_b64_e32 v[6:7], s[12:13]
	v_mov_b64_e32 v[8:9], s[14:15]
	flat_store_b128 v1, v[2:5], s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v1, v[6:9], s[16:17] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s6
	v_mov_b32_e32 v1, 0
	s_wait_kmcnt 0x0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 16
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b32 v1, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel copy_both_regions_before_publication
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
		.amdhsa_next_free_vgpr 10
		.amdhsa_next_free_sgpr 18
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
	.size	copy_both_regions_before_publication, .Lfunc_end2-copy_both_regions_before_publication
                                        ; -- End function
	.set copy_both_regions_before_publication.num_vgpr, 10
	.set copy_both_regions_before_publication.num_agpr, 0
	.set copy_both_regions_before_publication.numbered_sgpr, 18
	.set copy_both_regions_before_publication.num_named_barrier, 0
	.set copy_both_regions_before_publication.private_seg_size, 0
	.set copy_both_regions_before_publication.uses_vcc, 0
	.set copy_both_regions_before_publication.uses_flat_scratch, 0
	.set copy_both_regions_before_publication.has_dyn_sized_stack, 0
	.set copy_both_regions_before_publication.has_recursion, 0
	.set copy_both_regions_before_publication.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 172
; TotalNumSgprs: 18
; NumVgprs: 10
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 10
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
	.protected	copy_two_completed_regions ; -- Begin function copy_two_completed_regions
	.globl	copy_two_completed_regions
	.p2align	8
	.type	copy_two_completed_regions,@function
copy_two_completed_regions:             ; @copy_two_completed_regions
; %bb.0:
	s_mov_b32 s2, 0
	s_mov_b32 s3, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB3_2
; %bb.1:
	s_load_b128 s[4:7], s[0:1], 0x0
	v_mov_b32_e32 v4, 0
	s_mov_b64 s[12:13], src_shared_base
	s_mov_b32 s12, 16
	s_mov_b32 s3, s13
	s_wait_kmcnt 0x0
	s_load_b128 s[8:11], s[4:5], 0x0
	s_wait_kmcnt 0x0
	v_mov_b64_e32 v[0:1], s[8:9]
	v_mov_b64_e32 v[2:3], s[10:11]
	flat_store_b128 v4, v[0:3], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	flat_load_b32 v0, v4, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v4, v0, s[6:7]
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	global_load_b128 v[0:3], v4, s[4:5] offset:16
	s_wait_loadcnt 0x0
	flat_store_b128 v4, v[0:3], s[12:13] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	flat_load_b32 v0, v4, s[12:13] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v4, v0, s[6:7] offset:4
.LBB3_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel copy_two_completed_regions
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
.Lfunc_end3:
	.size	copy_two_completed_regions, .Lfunc_end3-copy_two_completed_regions
                                        ; -- End function
	.set copy_two_completed_regions.num_vgpr, 5
	.set copy_two_completed_regions.num_agpr, 0
	.set copy_two_completed_regions.numbered_sgpr, 14
	.set copy_two_completed_regions.num_named_barrier, 0
	.set copy_two_completed_regions.private_seg_size, 0
	.set copy_two_completed_regions.uses_vcc, 0
	.set copy_two_completed_regions.uses_flat_scratch, 0
	.set copy_two_completed_regions.has_dyn_sized_stack, 0
	.set copy_two_completed_regions.has_recursion, 0
	.set copy_two_completed_regions.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 172
; TotalNumSgprs: 14
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
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
	.protected	copy_result_dependency_ids ; -- Begin function copy_result_dependency_ids
	.globl	copy_result_dependency_ids
	.p2align	8
	.type	copy_result_dependency_ids,@function
copy_result_dependency_ids:             ; @copy_result_dependency_ids
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	v_cvt_f32_u32_e32 v1, v0
	v_dual_mov_b32 v3, s3 :: v_dual_lshlrev_b32 v2, 2, v0
	s_load_b64 s[0:1], s[0:1], 0x0
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	flat_load_b32 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel copy_result_dependency_ids
		.amdhsa_group_segment_fixed_size 128
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
.Lfunc_end4:
	.size	copy_result_dependency_ids, .Lfunc_end4-copy_result_dependency_ids
                                        ; -- End function
	.set copy_result_dependency_ids.num_vgpr, 4
	.set copy_result_dependency_ids.num_agpr, 0
	.set copy_result_dependency_ids.numbered_sgpr, 4
	.set copy_result_dependency_ids.num_named_barrier, 0
	.set copy_result_dependency_ids.private_seg_size, 0
	.set copy_result_dependency_ids.uses_vcc, 0
	.set copy_result_dependency_ids.uses_flat_scratch, 0
	.set copy_result_dependency_ids.has_dyn_sized_stack, 0
	.set copy_result_dependency_ids.has_recursion, 0
	.set copy_result_dependency_ids.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 76
; TotalNumSgprs: 4
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
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
	.protected	copy_every_actual_reader_waits ; -- Begin function copy_every_actual_reader_waits
	.globl	copy_every_actual_reader_waits
	.p2align	8
	.type	copy_every_actual_reader_waits,@function
copy_every_actual_reader_waits:         ; @copy_every_actual_reader_waits
; %bb.0:
	s_mov_b32 s2, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB5_2
; %bb.1:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s7
	s_wait_kmcnt 0x0
	s_load_b128 s[8:11], s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_mov_b64_e32 v[2:3], s[8:9]
	v_mov_b64_e32 v[4:5], s[10:11]
	flat_store_b128 v1, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB5_4
; %bb.3:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v0, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
.LBB5_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel copy_every_actual_reader_waits
		.amdhsa_group_segment_fixed_size 16
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
		.amdhsa_next_free_sgpr 12
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
	.size	copy_every_actual_reader_waits, .Lfunc_end5-copy_every_actual_reader_waits
                                        ; -- End function
	.set copy_every_actual_reader_waits.num_vgpr, 6
	.set copy_every_actual_reader_waits.num_agpr, 0
	.set copy_every_actual_reader_waits.numbered_sgpr, 12
	.set copy_every_actual_reader_waits.num_named_barrier, 0
	.set copy_every_actual_reader_waits.private_seg_size, 0
	.set copy_every_actual_reader_waits.uses_vcc, 0
	.set copy_every_actual_reader_waits.uses_flat_scratch, 0
	.set copy_every_actual_reader_waits.has_dyn_sized_stack, 0
	.set copy_every_actual_reader_waits.has_recursion, 0
	.set copy_every_actual_reader_waits.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 144
; TotalNumSgprs: 12
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 12
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_dc6d7d2ba98805ee,@object ; @__hip_cuid_dc6d7d2ba98805ee
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_dc6d7d2ba98805ee
__hip_cuid_dc6d7d2ba98805ee:
	.byte	0                               ; 0x0
	.size	__hip_cuid_dc6d7d2ba98805ee, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_dc6d7d2ba98805ee
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
    .max_flat_workgroup_size: 1024
    .name:           copy_scalar_same_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         copy_scalar_same_wave.kd
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
    .max_flat_workgroup_size: 1024
    .name:           copy_scalar_cross_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         copy_scalar_cross_wave.kd
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
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           copy_both_regions_before_publication
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         copy_both_regions_before_publication.kd
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
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           copy_two_completed_regions
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         copy_two_completed_regions.kd
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
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           copy_result_dependency_ids
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         copy_result_dependency_ids.kd
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
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           copy_every_actual_reader_waits
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         copy_every_actual_reader_waits.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
