	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	tensor_metadata_ordered ; -- Begin function tensor_metadata_ordered
	.globl	tensor_metadata_ordered
	.p2align	8
	.type	tensor_metadata_ordered,@function
tensor_metadata_ordered:                ; @tensor_metadata_ordered
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2 offset:96
.LBB0_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_mov_b32 s2, 0
	s_wait_xcnt 0x0
	s_mov_b32 s1, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[4:5], s[4:5], 0x6c
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v4, s4
	s_and_b32 s0, s5, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0x80
	s_bitset1_b32 s0, 31
	v_dual_mov_b32 v6, 2 :: v_dual_mov_b32 v5, s0
	v_dual_mov_b32 v7, 8 :: v_dual_mov_b32 v9, v8
	v_mov_b32_e32 v11, 0x20000
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s8, 32
	s_mov_b32 s3, s9
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v8, v[6:9], s[8:9] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v6, v8
	v_dual_mov_b32 v10, 0x10000 :: v_dual_mov_b32 v13, v11
	v_dual_mov_b32 v12, v11 :: v_dual_mov_b32 v7, v8
	flat_store_b128 v8, v[10:13], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s8, 64
	flat_store_b128 v8, v[6:9], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_mov_b32 s2, 32
	s_mov_b32 s1, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB0_6
; %bb.5:
	v_mov_b32_e32 v14, 0
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_mov_b32 s3, s5
	flat_load_b128 v[2:5], v14, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s4, 64
	flat_load_b128 v[6:9], v14, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[10:13], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[14:17], v14, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x3
	v_readfirstlane_b32 s16, v2
	v_readfirstlane_b32 s17, v3
	v_readfirstlane_b32 s18, v4
	v_readfirstlane_b32 s19, v5
	s_wait_dscnt 0x1
	v_readfirstlane_b32 s8, v10
	v_readfirstlane_b32 s9, v11
	v_readfirstlane_b32 s10, v12
	v_readfirstlane_b32 s11, v13
	v_readfirstlane_b32 s12, v6
	v_readfirstlane_b32 s13, v7
	v_readfirstlane_b32 s14, v8
	s_wait_dscnt 0x0
	v_readfirstlane_b32 s20, v14
	v_readfirstlane_b32 s21, v15
	v_readfirstlane_b32 s22, v16
	v_readfirstlane_b32 s23, v17
	v_readfirstlane_b32 s15, v9
	s_delay_alu instid0(VALU_DEP_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB0_6:
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB0_8
; %bb.7:
	ds_load_u16 v2, v1 offset:128
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2 offset:96
.LBB0_8:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_10
; %bb.9:
	ds_load_u16 v1, v1 offset:96
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[6:7] scale_offset
.LBB0_10:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_metadata_ordered
		.amdhsa_group_segment_fixed_size 160
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
		.amdhsa_next_free_vgpr 18
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end0:
	.size	tensor_metadata_ordered, .Lfunc_end0-tensor_metadata_ordered
                                        ; -- End function
	.set tensor_metadata_ordered.num_vgpr, 18
	.set tensor_metadata_ordered.num_agpr, 0
	.set tensor_metadata_ordered.numbered_sgpr, 24
	.set tensor_metadata_ordered.num_named_barrier, 0
	.set tensor_metadata_ordered.private_seg_size, 0
	.set tensor_metadata_ordered.uses_vcc, 1
	.set tensor_metadata_ordered.uses_flat_scratch, 0
	.set tensor_metadata_ordered.has_dyn_sized_stack, 0
	.set tensor_metadata_ordered.has_recursion, 0
	.set tensor_metadata_ordered.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 604
; TotalNumSgprs: 26
; NumVgprs: 18
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 160 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 18
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
	.protected	tensor_metadata_field_race ; -- Begin function tensor_metadata_field_race
	.globl	tensor_metadata_field_race
	.p2align	8
	.type	tensor_metadata_field_race,@function
tensor_metadata_field_race:             ; @tensor_metadata_field_race
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB1_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2 offset:96
.LBB1_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_mov_b32 s2, 0
	s_wait_xcnt 0x0
	s_mov_b32 s1, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[10:11], s[4:5], 0x6c
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v4, s10
	s_and_b32 s0, s11, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0x80
	s_bitset1_b32 s0, 31
	v_dual_mov_b32 v6, 2 :: v_dual_mov_b32 v5, s0
	v_dual_mov_b32 v7, 8 :: v_dual_mov_b32 v9, v8
	v_mov_b32_e32 v11, 0x20000
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s8, 32
	s_mov_b32 s3, s9
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v8, v[6:9], s[8:9] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v6, v8
	v_dual_mov_b32 v10, 0x10000 :: v_dual_mov_b32 v13, v11
	v_dual_mov_b32 v12, v11 :: v_dual_mov_b32 v7, v8
	flat_store_b128 v8, v[10:13], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s8, 64
	flat_store_b128 v8, v[6:9], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	v_cmp_eq_u32_e64 s0, 32, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB1_6
; %bb.5:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[4:5], s[4:5], 0x6a
	s_mov_b64 s[2:3], src_shared_base
	s_and_b32 s2, s5, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0x80
	s_bitset1_b32 s2, 31
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v4, s4 :: v_dual_mov_b32 v5, s2
	v_mov_b32_e32 v6, 0
	s_mov_b32 s2, 0
	flat_store_b128 v6, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB1_8
; %bb.7:
	v_mov_b32_e32 v14, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	flat_load_b128 v[2:5], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 32
	flat_load_b128 v[6:9], v14, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[10:13], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 64
	flat_load_b128 v[14:17], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x3
	v_readfirstlane_b32 s16, v2
	v_readfirstlane_b32 s17, v3
	v_readfirstlane_b32 s18, v4
	v_readfirstlane_b32 s19, v5
	s_wait_dscnt 0x1
	v_readfirstlane_b32 s8, v10
	v_readfirstlane_b32 s9, v11
	v_readfirstlane_b32 s10, v12
	v_readfirstlane_b32 s11, v13
	v_readfirstlane_b32 s12, v6
	v_readfirstlane_b32 s13, v7
	v_readfirstlane_b32 s14, v8
	s_wait_dscnt 0x0
	v_readfirstlane_b32 s20, v14
	v_readfirstlane_b32 s21, v15
	v_readfirstlane_b32 s22, v16
	v_readfirstlane_b32 s23, v17
	v_readfirstlane_b32 s15, v9
	s_delay_alu instid0(VALU_DEP_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB1_8:
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB1_10
; %bb.9:
	ds_load_u16 v2, v1 offset:128
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2 offset:96
.LBB1_10:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_12
; %bb.11:
	ds_load_u16 v1, v1 offset:96
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[6:7] scale_offset
.LBB1_12:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_metadata_field_race
		.amdhsa_group_segment_fixed_size 160
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
		.amdhsa_next_free_vgpr 18
		.amdhsa_next_free_sgpr 24
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 6
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
	.size	tensor_metadata_field_race, .Lfunc_end1-tensor_metadata_field_race
                                        ; -- End function
	.set tensor_metadata_field_race.num_vgpr, 18
	.set tensor_metadata_field_race.num_agpr, 0
	.set tensor_metadata_field_race.numbered_sgpr, 24
	.set tensor_metadata_field_race.num_named_barrier, 0
	.set tensor_metadata_field_race.private_seg_size, 0
	.set tensor_metadata_field_race.uses_vcc, 1
	.set tensor_metadata_field_race.uses_flat_scratch, 0
	.set tensor_metadata_field_race.has_dyn_sized_stack, 0
	.set tensor_metadata_field_race.has_recursion, 0
	.set tensor_metadata_field_race.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 696
; TotalNumSgprs: 26
; NumVgprs: 18
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 160 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 18
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
	.protected	tensor_metadata_rewrite_after_capture ; -- Begin function tensor_metadata_rewrite_after_capture
	.globl	tensor_metadata_rewrite_after_capture
	.p2align	8
	.type	tensor_metadata_rewrite_after_capture,@function
tensor_metadata_rewrite_after_capture:  ; @tensor_metadata_rewrite_after_capture
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB2_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2 offset:96
.LBB2_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_mov_b32 s2, 0
	s_wait_xcnt 0x0
	s_mov_b32 s1, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB2_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[10:11], s[4:5], 0x6c
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v4, s10
	s_and_b32 s0, s11, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0x80
	s_bitset1_b32 s0, 31
	v_dual_mov_b32 v6, 2 :: v_dual_mov_b32 v5, s0
	v_dual_mov_b32 v7, 8 :: v_dual_mov_b32 v9, v8
	v_mov_b32_e32 v11, 0x20000
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s8, 32
	s_mov_b32 s3, s9
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v8, v[6:9], s[8:9] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v6, v8
	v_dual_mov_b32 v10, 0x10000 :: v_dual_mov_b32 v13, v11
	v_dual_mov_b32 v12, v11 :: v_dual_mov_b32 v7, v8
	flat_store_b128 v8, v[10:13], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s8, 64
	flat_store_b128 v8, v[6:9], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_mov_b32 s2, 32
	s_mov_b32 s1, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB2_6
; %bb.5:
	s_wait_kmcnt 0x0
	s_add_co_i32 s0, s4, 0x6a
	v_mov_b32_e32 v18, 0
	s_mov_b64 s[24:25], src_shared_base
	s_mov_b32 s24, 0
	s_mov_b32 s3, s25
	s_mov_b32 s8, 64
	flat_load_b128 v[2:5], v18, s[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_mov_b32 s9, s25
	flat_load_b128 v[6:9], v18, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[10:13], v18, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[14:17], v18, s[8:9] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x2
	v_readfirstlane_b32 s12, v6
	v_readfirstlane_b32 s16, v2
	v_readfirstlane_b32 s17, v3
	v_readfirstlane_b32 s18, v4
	v_readfirstlane_b32 s19, v5
	s_wait_dscnt 0x0
	v_readfirstlane_b32 s20, v14
	v_readfirstlane_b32 s21, v15
	v_readfirstlane_b32 s22, v16
	v_readfirstlane_b32 s23, v17
	v_readfirstlane_b32 s8, v10
	v_readfirstlane_b32 s9, v11
	v_readfirstlane_b32 s10, v12
	v_readfirstlane_b32 s11, v13
	v_readfirstlane_b32 s13, v7
	v_readfirstlane_b32 s14, v8
	v_readfirstlane_b32 s15, v9
	s_delay_alu instid0(VALU_DEP_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
	flat_load_b128 v[2:5], v18, s[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_mov_b32_e32 v4, s0
	flat_store_b128 v18, v[2:5], s[24:25] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB2_8
; %bb.7:
	ds_load_u16 v2, v1 offset:128
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2 offset:96
.LBB2_8:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_10
; %bb.9:
	ds_load_u16 v1, v1 offset:96
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[6:7] scale_offset
.LBB2_10:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_metadata_rewrite_after_capture
		.amdhsa_group_segment_fixed_size 160
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
		.amdhsa_next_free_vgpr 19
		.amdhsa_next_free_sgpr 26
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 6
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
	.size	tensor_metadata_rewrite_after_capture, .Lfunc_end2-tensor_metadata_rewrite_after_capture
                                        ; -- End function
	.set tensor_metadata_rewrite_after_capture.num_vgpr, 19
	.set tensor_metadata_rewrite_after_capture.num_agpr, 0
	.set tensor_metadata_rewrite_after_capture.numbered_sgpr, 26
	.set tensor_metadata_rewrite_after_capture.num_named_barrier, 0
	.set tensor_metadata_rewrite_after_capture.private_seg_size, 0
	.set tensor_metadata_rewrite_after_capture.uses_vcc, 1
	.set tensor_metadata_rewrite_after_capture.uses_flat_scratch, 0
	.set tensor_metadata_rewrite_after_capture.has_dyn_sized_stack, 0
	.set tensor_metadata_rewrite_after_capture.has_recursion, 0
	.set tensor_metadata_rewrite_after_capture.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 652
; TotalNumSgprs: 28
; NumVgprs: 19
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 160 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 28
; NumVGPRsForWavesPerEU: 19
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
	.protected	tensor_metadata_wrong_object ; -- Begin function tensor_metadata_wrong_object
	.globl	tensor_metadata_wrong_object
	.p2align	8
	.type	tensor_metadata_wrong_object,@function
tensor_metadata_wrong_object:           ; @tensor_metadata_wrong_object
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB3_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2 offset:96
.LBB3_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_mov_b32 s2, 0
	s_wait_xcnt 0x0
	s_mov_b32 s1, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB3_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[4:5], s[4:5], 0x6a
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v4, s4
	s_and_b32 s0, s5, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0x80
	s_bitset1_b32 s0, 31
	v_dual_mov_b32 v6, 2 :: v_dual_mov_b32 v5, s0
	v_dual_mov_b32 v7, 8 :: v_dual_mov_b32 v9, v8
	v_mov_b32_e32 v11, 0x20000
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s8, 32
	s_mov_b32 s3, s9
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v8, v[6:9], s[8:9] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v6, v8
	v_dual_mov_b32 v10, 0x10000 :: v_dual_mov_b32 v13, v11
	v_dual_mov_b32 v12, v11 :: v_dual_mov_b32 v7, v8
	flat_store_b128 v8, v[10:13], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s8, 64
	flat_store_b128 v8, v[6:9], s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB3_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_mov_b32 s2, 32
	s_mov_b32 s1, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB3_6
; %bb.5:
	v_mov_b32_e32 v14, 0
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_mov_b32 s3, s5
	flat_load_b128 v[2:5], v14, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s4, 64
	flat_load_b128 v[6:9], v14, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[10:13], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[14:17], v14, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x3
	v_readfirstlane_b32 s16, v2
	v_readfirstlane_b32 s17, v3
	v_readfirstlane_b32 s18, v4
	v_readfirstlane_b32 s19, v5
	s_wait_dscnt 0x1
	v_readfirstlane_b32 s8, v10
	v_readfirstlane_b32 s9, v11
	v_readfirstlane_b32 s10, v12
	v_readfirstlane_b32 s11, v13
	v_readfirstlane_b32 s12, v6
	v_readfirstlane_b32 s13, v7
	v_readfirstlane_b32 s14, v8
	s_wait_dscnt 0x0
	v_readfirstlane_b32 s20, v14
	v_readfirstlane_b32 s21, v15
	v_readfirstlane_b32 s22, v16
	v_readfirstlane_b32 s23, v17
	v_readfirstlane_b32 s15, v9
	s_delay_alu instid0(VALU_DEP_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB3_6:
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB3_8
; %bb.7:
	ds_load_u16 v2, v1 offset:128
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2 offset:96
.LBB3_8:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_10
; %bb.9:
	ds_load_u16 v1, v1 offset:96
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[6:7] scale_offset
.LBB3_10:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_metadata_wrong_object
		.amdhsa_group_segment_fixed_size 160
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
		.amdhsa_next_free_vgpr 18
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end3:
	.size	tensor_metadata_wrong_object, .Lfunc_end3-tensor_metadata_wrong_object
                                        ; -- End function
	.set tensor_metadata_wrong_object.num_vgpr, 18
	.set tensor_metadata_wrong_object.num_agpr, 0
	.set tensor_metadata_wrong_object.numbered_sgpr, 24
	.set tensor_metadata_wrong_object.num_named_barrier, 0
	.set tensor_metadata_wrong_object.private_seg_size, 0
	.set tensor_metadata_wrong_object.uses_vcc, 1
	.set tensor_metadata_wrong_object.uses_flat_scratch, 0
	.set tensor_metadata_wrong_object.has_dyn_sized_stack, 0
	.set tensor_metadata_wrong_object.has_recursion, 0
	.set tensor_metadata_wrong_object.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 604
; TotalNumSgprs: 26
; NumVgprs: 18
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 160 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 18
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
	.protected	tensor_metadata_copied  ; -- Begin function tensor_metadata_copied
	.globl	tensor_metadata_copied
	.p2align	8
	.type	tensor_metadata_copied,@function
tensor_metadata_copied:                 ; @tensor_metadata_copied
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2 offset:192
.LBB4_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_wait_xcnt 0x0
	v_cmp_eq_u32_e64 s0, 0, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB4_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[4:5], s[4:5], 0x6c
	s_mov_b64 s[2:3], src_shared_base
	s_and_b32 s2, s5, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0xe0
	s_bitset1_b32 s2, 31
	v_dual_mov_b32 v4, s4 :: v_dual_mov_b32 v8, 0
	v_dual_mov_b32 v5, s2 :: v_dual_mov_b32 v6, 2
	s_movk_i32 s2, 0x60
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_mov_b32 v7, 8 :: v_dual_mov_b32 v9, v8
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v3, 0x20000
	s_movk_i32 s2, 0x80
	flat_store_b128 v8, v[6:9], s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v6, v8
	v_dual_mov_b32 v2, 0x10000 :: v_dual_mov_b32 v5, v3
	v_dual_mov_b32 v4, v3 :: v_dual_mov_b32 v7, v8
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s2, 0xa0
	flat_store_b128 v8, v[6:9], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB4_6
; %bb.5:
	v_mov_b32_e32 v10, 0
	s_mov_b64 s[2:3], src_shared_base
	s_movk_i32 s2, 0x60
	flat_load_b128 v[2:5], v10, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 0
	s_wait_dscnt 0x0
	flat_store_b128 v10, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s2, 0x80
	flat_load_b128 v[2:5], v10, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[6:9], v10, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 32
	s_wait_dscnt 0x0
	flat_store_b128 v10, v[6:9], s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v10, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s2, 0xa0
	flat_load_b128 v[2:5], v10, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 64
	s_wait_dscnt 0x0
	flat_store_b128 v10, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_mov_b32 s2, 32
	s_mov_b32 s1, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB4_8
; %bb.7:
	v_mov_b32_e32 v14, 0
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	s_mov_b32 s3, s5
	flat_load_b128 v[2:5], v14, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s4, 64
	flat_load_b128 v[6:9], v14, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[10:13], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[14:17], v14, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x3
	v_readfirstlane_b32 s16, v2
	v_readfirstlane_b32 s17, v3
	v_readfirstlane_b32 s18, v4
	v_readfirstlane_b32 s19, v5
	s_wait_dscnt 0x1
	v_readfirstlane_b32 s8, v10
	v_readfirstlane_b32 s9, v11
	v_readfirstlane_b32 s10, v12
	v_readfirstlane_b32 s11, v13
	v_readfirstlane_b32 s12, v6
	v_readfirstlane_b32 s13, v7
	v_readfirstlane_b32 s14, v8
	s_wait_dscnt 0x0
	v_readfirstlane_b32 s20, v14
	v_readfirstlane_b32 s21, v15
	v_readfirstlane_b32 s22, v16
	v_readfirstlane_b32 s23, v17
	v_readfirstlane_b32 s15, v9
	s_delay_alu instid0(VALU_DEP_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB4_8:
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB4_10
; %bb.9:
	ds_load_u16 v2, v1 offset:224
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2 offset:192
.LBB4_10:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_12
; %bb.11:
	ds_load_u16 v1, v1 offset:192
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[6:7] scale_offset
.LBB4_12:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_metadata_copied
		.amdhsa_group_segment_fixed_size 256
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
		.amdhsa_next_free_vgpr 18
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end4:
	.size	tensor_metadata_copied, .Lfunc_end4-tensor_metadata_copied
                                        ; -- End function
	.set tensor_metadata_copied.num_vgpr, 18
	.set tensor_metadata_copied.num_agpr, 0
	.set tensor_metadata_copied.numbered_sgpr, 24
	.set tensor_metadata_copied.num_named_barrier, 0
	.set tensor_metadata_copied.private_seg_size, 0
	.set tensor_metadata_copied.uses_vcc, 1
	.set tensor_metadata_copied.uses_flat_scratch, 0
	.set tensor_metadata_copied.has_dyn_sized_stack, 0
	.set tensor_metadata_copied.has_recursion, 0
	.set tensor_metadata_copied.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 828
; TotalNumSgprs: 26
; NumVgprs: 18
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 256 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 18
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
	.protected	tensor_metadata_copy_replace_race ; -- Begin function tensor_metadata_copy_replace_race
	.globl	tensor_metadata_copy_replace_race
	.p2align	8
	.type	tensor_metadata_copy_replace_race,@function
tensor_metadata_copy_replace_race:      ; @tensor_metadata_copy_replace_race
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2 offset:192
.LBB5_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_wait_xcnt 0x0
	v_cmp_eq_u32_e64 s0, 0, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB5_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[8:9], s[4:5], 0x6c
	s_mov_b64 s[2:3], src_shared_base
	s_and_b32 s2, s9, 0x1ffffff
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0xe0
	s_bitset1_b32 s2, 31
	v_dual_mov_b32 v4, s8 :: v_dual_mov_b32 v8, 0
	v_dual_mov_b32 v5, s2 :: v_dual_mov_b32 v6, 2
	s_movk_i32 s2, 0x60
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_mov_b32 v7, 8 :: v_dual_mov_b32 v9, v8
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v3, 0x20000
	s_movk_i32 s2, 0x80
	flat_store_b128 v8, v[6:9], s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v6, v8
	v_dual_mov_b32 v2, 0x10000 :: v_dual_mov_b32 v5, v3
	v_dual_mov_b32 v4, v3 :: v_dual_mov_b32 v7, v8
	flat_store_b128 v8, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s2, 0xa0
	flat_store_b128 v8, v[6:9], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB5_6
; %bb.5:
	v_mov_b32_e32 v10, 0
	s_mov_b64 s[2:3], src_shared_base
	s_movk_i32 s2, 0x60
	flat_load_b128 v[2:5], v10, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 0
	s_wait_dscnt 0x0
	flat_store_b128 v10, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s2, 0x80
	flat_load_b128 v[2:5], v10, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[6:9], v10, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 32
	s_wait_dscnt 0x0
	flat_store_b128 v10, v[6:9], s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b128 v10, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s2, 0xa0
	flat_load_b128 v[2:5], v10, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 64
	s_wait_dscnt 0x0
	flat_store_b128 v10, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	v_cmp_eq_u32_e64 s0, 32, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB5_8
; %bb.7:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[10:11], s[4:5], 0x6a
	s_mov_b64 s[2:3], src_shared_base
	s_and_b32 s2, s11, 0x1ffffff
	s_movk_i32 s9, 0xe0
	s_mov_b32 s8, 1
	s_or_b32 s11, s2, 0x80000000
	v_mov_b64_e32 v[2:3], s[8:9]
	v_mov_b64_e32 v[4:5], s[10:11]
	v_mov_b32_e32 v6, 0
	s_movk_i32 s2, 0x60
	flat_store_b128 v6, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 0
	flat_store_b128 v6, v[2:5], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB5_10
; %bb.9:
	v_mov_b32_e32 v14, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	flat_load_b128 v[2:5], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 32
	flat_load_b128 v[6:9], v14, s[2:3] offset:16 scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_b128 v[10:13], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s2, 64
	flat_load_b128 v[14:17], v14, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x3
	v_readfirstlane_b32 s16, v2
	v_readfirstlane_b32 s17, v3
	v_readfirstlane_b32 s18, v4
	v_readfirstlane_b32 s19, v5
	s_wait_dscnt 0x1
	v_readfirstlane_b32 s8, v10
	v_readfirstlane_b32 s9, v11
	v_readfirstlane_b32 s10, v12
	v_readfirstlane_b32 s11, v13
	v_readfirstlane_b32 s12, v6
	v_readfirstlane_b32 s13, v7
	v_readfirstlane_b32 s14, v8
	s_wait_dscnt 0x0
	v_readfirstlane_b32 s20, v14
	v_readfirstlane_b32 s21, v15
	v_readfirstlane_b32 s22, v16
	v_readfirstlane_b32 s23, v17
	v_readfirstlane_b32 s15, v9
	s_delay_alu instid0(VALU_DEP_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB5_10:
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB5_12
; %bb.11:
	ds_load_u16 v2, v1 offset:224
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2 offset:192
.LBB5_12:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB5_14
; %bb.13:
	ds_load_u16 v1, v1 offset:192
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[6:7] scale_offset
.LBB5_14:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_metadata_copy_replace_race
		.amdhsa_group_segment_fixed_size 256
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
		.amdhsa_next_free_vgpr 18
		.amdhsa_next_free_sgpr 24
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
.Lfunc_end5:
	.size	tensor_metadata_copy_replace_race, .Lfunc_end5-tensor_metadata_copy_replace_race
                                        ; -- End function
	.set tensor_metadata_copy_replace_race.num_vgpr, 18
	.set tensor_metadata_copy_replace_race.num_agpr, 0
	.set tensor_metadata_copy_replace_race.numbered_sgpr, 24
	.set tensor_metadata_copy_replace_race.num_named_barrier, 0
	.set tensor_metadata_copy_replace_race.private_seg_size, 0
	.set tensor_metadata_copy_replace_race.uses_vcc, 1
	.set tensor_metadata_copy_replace_race.uses_flat_scratch, 0
	.set tensor_metadata_copy_replace_race.has_dyn_sized_stack, 0
	.set tensor_metadata_copy_replace_race.has_recursion, 0
	.set tensor_metadata_copy_replace_race.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 940
; TotalNumSgprs: 26
; NumVgprs: 18
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 256 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 18
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
	.type	__hip_cuid_7304bd18f0f4adcd,@object ; @__hip_cuid_7304bd18f0f4adcd
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_7304bd18f0f4adcd
__hip_cuid_7304bd18f0f4adcd:
	.byte	0                               ; 0x0
	.size	__hip_cuid_7304bd18f0f4adcd, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_7304bd18f0f4adcd
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
    .group_segment_fixed_size: 160
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_metadata_ordered
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_metadata_ordered.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     18
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
    .group_segment_fixed_size: 160
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_metadata_field_race
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_metadata_field_race.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     18
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
    .group_segment_fixed_size: 160
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_metadata_rewrite_after_capture
    .private_segment_fixed_size: 0
    .sgpr_count:     28
    .sgpr_spill_count: 0
    .symbol:         tensor_metadata_rewrite_after_capture.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     19
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
    .group_segment_fixed_size: 160
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_metadata_wrong_object
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_metadata_wrong_object.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     18
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
    .group_segment_fixed_size: 256
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_metadata_copied
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_metadata_copied.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     18
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
    .group_segment_fixed_size: 256
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_metadata_copy_replace_race
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_metadata_copy_replace_race.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     18
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
