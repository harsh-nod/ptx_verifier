	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	matrix_input_cross_wave ; -- Begin function matrix_input_cross_wave
	.globl	matrix_input_cross_wave
	.p2align	8
	.type	matrix_input_cross_wave,@function
matrix_input_cross_wave:                ; @matrix_input_cross_wave
; %bb.0:
	v_lshlrev_b32_e32 v1, 1, v0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB0_3
; %bb.1:
	v_or_b32_e32 v4, 0xffffffc0, v0
	v_dual_mov_b32 v5, 0 :: v_dual_mov_b32 v2, v1
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v3, s3 :: v_dual_add_nc_u32 v4, 64, v4
	v_cmp_lt_u32_e32 vcc_lo, 0xbf, v4
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 0x80, v2
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB0_2
.LBB0_3:
	s_or_b32 exec_lo, exec_lo, s4
	s_load_b128 s[0:3], s[0:1], 0x0
	v_and_b32_e32 v2, 31, v0
	s_mov_b32 s4, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_5
; %bb.4:
	s_wait_kmcnt 0x0
	global_load_u16 v3, v2, s[0:1] scale_offset
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v5, s7 :: v_dual_lshlrev_b32 v4, 1, v2
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:64 scale_offset
	v_add_nc_u32_e32 v4, 64, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:128 scale_offset
	v_or_b32_e32 v4, 0x80, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:192 scale_offset
	v_add_nc_u32_e32 v4, 0xc0, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:256 scale_offset
	v_or_b32_e32 v4, 0x100, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:320 scale_offset
	v_add_nc_u32_e32 v4, 0x140, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:384 scale_offset
	v_or_b32_e32 v4, 0x180, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_u16 v3, v0, s[0:1] offset:448 scale_offset
	v_add_nc_u32_e32 v4, 0x1c0, v1
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_5:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB0_7
; %bb.6:
	v_dual_lshrrev_b32 v1, 1, v2 :: v_dual_lshlrev_b32 v16, 5, v0
	s_mov_b64 s[0:1], src_shared_base
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s1 :: v_dual_bitop2_b32 v17, 8, v1 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_and_b32_e32 v14, 0x1e0, v16
	v_dual_mov_b32 v5, s1 :: v_dual_mov_b32 v7, s1
	v_dual_mov_b32 v9, s1 :: v_dual_mov_b32 v11, s1
	v_lshl_or_b32 v2, v17, 1, v14
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_mov_b32 v13, s1 :: v_dual_bitop2_b32 v4, 2, v2 bitop3:0x54
	v_or_b32_e32 v6, 4, v2
	flat_load_u16 v18, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v19, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v20, v[6:7] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x1
	v_dual_mov_b32 v4, 0 :: v_dual_bitop2_b32 v8, 6, v2 bitop3:0x54
	v_or_b32_e32 v1, 7, v1
	v_or_b32_e32 v10, 8, v2
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_mov_b32 v7, v4 :: v_dual_bitop2_b32 v12, 10, v2 bitop3:0x54
	v_dual_mov_b32 v5, v4 :: v_dual_bitop2_b32 v2, 12, v2 bitop3:0x54
	v_mov_b32_e32 v6, v4
	flat_load_u16 v21, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v22, v[10:11] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v23, v[12:13] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v24, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x1
	v_mov_b32_e32 v13, v4
	s_wait_xcnt 0x0
	v_lshl_or_b32 v2, v1, 1, v14
	v_dual_mov_b32 v14, v4 :: v_dual_bitop2_b32 v0, 15, v0 bitop3:0x40
	v_dual_mov_b32 v15, v4 :: v_dual_bitop2_b32 v8, 3, v17 bitop3:0x54
	flat_load_u16 v11, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 1, v17
	v_dual_lshlrev_b32 v27, 2, v0 :: v_dual_bitop2_b32 v3, 2, v17 bitop3:0x54
	v_or_b32_e32 v9, 4, v17
	v_or_b32_e32 v10, 5, v17
	v_or_b32_e32 v17, 6, v17
	v_cvt_f32_ubyte0_e32 v25, v1
	v_add_nc_u32_e32 v1, 1, v1
	v_cvt_f32_ubyte0_e32 v2, v2
	v_cvt_f32_ubyte0_e32 v3, v3
	v_cvt_f32_ubyte0_e32 v8, v8
	v_cvt_f32_ubyte0_e32 v9, v9
	v_cvt_f32_ubyte0_e32 v10, v10
	v_cvt_f32_ubyte0_e32 v17, v17
	v_cvt_f32_ubyte0_e32 v26, v1
	v_mov_b32_e32 v12, v4
	v_cvt_pk_f16_f32 v0, v2, v3
	v_cvt_pk_f16_f32 v1, v8, v9
	v_cvt_pk_f16_f32 v2, v10, v17
	v_cvt_pk_f16_f32 v3, v25, v26
	s_wait_dscnt 0x6
	v_perm_b32 v8, v19, v18, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v9, v21, v20, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v10, v23, v22, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v11, v11, v24, 0x5040100
	v_and_or_b32 v24, 0x200, v16, v27
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x32_f16 v[16:23], v[8:15], v[0:7], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	s_clause 0x7
	global_store_b32 v24, v16, s[2:3]
	global_store_b32 v24, v17, s[2:3] offset:64
	global_store_b32 v24, v18, s[2:3] offset:128
	global_store_b32 v24, v19, s[2:3] offset:192
	global_store_b32 v24, v20, s[2:3] offset:256
	global_store_b32 v24, v21, s[2:3] offset:320
	global_store_b32 v24, v22, s[2:3] offset:384
	global_store_b32 v24, v23, s[2:3] offset:448
.LBB0_7:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_input_cross_wave
		.amdhsa_group_segment_fixed_size 512
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
		.amdhsa_next_free_vgpr 28
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
.Lfunc_end0:
	.size	matrix_input_cross_wave, .Lfunc_end0-matrix_input_cross_wave
                                        ; -- End function
	.set matrix_input_cross_wave.num_vgpr, 28
	.set matrix_input_cross_wave.num_agpr, 0
	.set matrix_input_cross_wave.numbered_sgpr, 8
	.set matrix_input_cross_wave.num_named_barrier, 0
	.set matrix_input_cross_wave.private_seg_size, 0
	.set matrix_input_cross_wave.uses_vcc, 1
	.set matrix_input_cross_wave.uses_flat_scratch, 0
	.set matrix_input_cross_wave.has_dyn_sized_stack, 0
	.set matrix_input_cross_wave.has_recursion, 0
	.set matrix_input_cross_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1136
; TotalNumSgprs: 10
; NumVgprs: 28
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 512 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 10
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
	.protected	matrix_completion_keeps_metadata_separate ; -- Begin function matrix_completion_keeps_metadata_separate
	.globl	matrix_completion_keeps_metadata_separate
	.p2align	8
	.type	matrix_completion_keeps_metadata_separate,@function
matrix_completion_keeps_metadata_separate: ; @matrix_completion_keeps_metadata_separate
; %bb.0:
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 s2, 0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_2
; %bb.1:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s7
	flat_store_b32 v1, v1, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_load_b256 s[4:11], s[0:1], 0x0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_4
; %bb.3:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	s_wait_kmcnt 0x0
	global_load_b32 v2, v1, s[8:9]
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB1_6
; %bb.5:
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshlrev_b32 v2, 4, v0
	v_dual_mov_b32 v14, 0 :: v_dual_lshlrev_b32 v11, 2, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_and_b32_e32 v5, 8, v1
	v_and_b32_e32 v2, 0xf0, v2
	v_dual_lshlrev_b32 v1, 6, v1 :: v_dual_bitop2_b32 v10, 7, v1 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v15, v14 :: v_dual_mov_b32 v16, v14
	v_or_b32_e32 v6, v5, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_or_b32_e32 v7, v10, v2
	v_cvt_f32_ubyte0_e32 v24, v10
	v_dual_mov_b32 v17, v14 :: v_dual_add_nc_u32 v10, 1, v10
	v_dual_mov_b32 v9, v14 :: v_dual_lshlrev_b32 v8, 1, v6
	v_or_b32_e32 v12, 1, v5
	s_wait_kmcnt 0x0
	s_clause 0x2
	global_load_u16 v18, v7, s[4:5] scale_offset
	global_load_u16 v19, v6, s[4:5] offset:12 scale_offset
	global_load_b96 v[2:4], v8, s[4:5]
	v_or_b32_e32 v13, 2, v5
	v_dual_lshlrev_b32 v25, 4, v5 :: v_dual_bitop2_b32 v20, 3, v5 bitop3:0x54
	v_or_b32_e32 v21, 4, v5
	v_or_b32_e32 v22, 5, v5
	v_or_b32_e32 v23, 6, v5
	v_or3_b32 v1, v1, v11, 0x1c0
	v_cvt_f32_ubyte0_e32 v5, v12
	v_cvt_f32_ubyte0_e32 v11, v13
	v_cvt_f32_ubyte0_e32 v12, v20
	v_cvt_f32_ubyte0_e32 v13, v21
	v_cvt_f32_ubyte0_e32 v20, v22
	v_or_b32_e32 v21, v25, v0
	v_cvt_f32_ubyte0_e32 v22, v23
	v_cvt_f32_ubyte0_e32 v23, v10
	s_wait_xcnt 0x1
	v_dual_mov_b32 v6, v14 :: v_dual_mov_b32 v7, v14
	s_wait_xcnt 0x0
	v_mov_b32_e32 v8, v14
	v_cvt_pk_f16_f32 v10, v5, v11
	v_cvt_pk_f16_f32 v11, v12, v13
	v_lshlrev_b32_e32 v21, 2, v21
	v_cvt_pk_f16_f32 v12, v20, v22
	v_cvt_pk_f16_f32 v13, v24, v23
	v_and_or_b32 v26, v0, 15, v25
	s_delay_alu instid0(VALU_DEP_4)
	v_or_b32_e32 v27, 64, v21
	v_or_b32_e32 v28, 0xc0, v21
	v_or_b32_e32 v29, 0x140, v21
	s_wait_loadcnt 0x1
	v_perm_b32 v5, v18, v19, 0x5040100
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	s_clause 0x7
	global_store_b32 v27, v19, s[6:7]
	global_store_b32 v26, v18, s[6:7] scale_offset
	global_store_b32 v26, v20, s[6:7] offset:128 scale_offset
	global_store_b32 v28, v21, s[6:7]
	global_store_b32 v26, v22, s[6:7] offset:256 scale_offset
	global_store_b32 v29, v23, s[6:7]
	global_store_b32 v26, v24, s[6:7] offset:384 scale_offset
	global_store_b32 v1, v25, s[6:7]
.LBB1_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB1_8
; %bb.7:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[10:11]
.LBB1_8:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_completion_keeps_metadata_separate
		.amdhsa_group_segment_fixed_size 4
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
		.amdhsa_next_free_vgpr 30
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
	.size	matrix_completion_keeps_metadata_separate, .Lfunc_end1-matrix_completion_keeps_metadata_separate
                                        ; -- End function
	.set matrix_completion_keeps_metadata_separate.num_vgpr, 30
	.set matrix_completion_keeps_metadata_separate.num_agpr, 0
	.set matrix_completion_keeps_metadata_separate.numbered_sgpr, 12
	.set matrix_completion_keeps_metadata_separate.num_named_barrier, 0
	.set matrix_completion_keeps_metadata_separate.private_seg_size, 0
	.set matrix_completion_keeps_metadata_separate.uses_vcc, 1
	.set matrix_completion_keeps_metadata_separate.uses_flat_scratch, 0
	.set matrix_completion_keeps_metadata_separate.has_dyn_sized_stack, 0
	.set matrix_completion_keeps_metadata_separate.has_recursion, 0
	.set matrix_completion_keeps_metadata_separate.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 672
; TotalNumSgprs: 14
; NumVgprs: 30
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 30
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
	.type	__hip_cuid_856da865187dfac2,@object ; @__hip_cuid_856da865187dfac2
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_856da865187dfac2
__hip_cuid_856da865187dfac2:
	.byte	0                               ; 0x0
	.size	__hip_cuid_856da865187dfac2, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_856da865187dfac2
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
    .group_segment_fixed_size: 512
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           matrix_input_cross_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matrix_input_cross_wave.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           matrix_completion_keeps_metadata_separate
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         matrix_completion_keeps_metadata_separate.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     30
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
