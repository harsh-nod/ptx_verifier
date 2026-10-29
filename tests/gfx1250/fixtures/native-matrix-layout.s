	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	matrix_stride32         ; -- Begin function matrix_stride32
	.globl	matrix_stride32
	.p2align	8
	.type	matrix_stride32,@function
matrix_stride32:                        ; @matrix_stride32
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB0_9
; %bb.1:
	s_wait_kmcnt 0x0
	global_load_u16 v1, v0, s[4:5] scale_offset
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s9 :: v_dual_lshlrev_b32 v2, 1, v0
	v_cmp_gt_u32_e32 vcc_lo, 0xe0, v0
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB0_9
; %bb.2:
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v6, 64, v2 bitop3:0x54
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s9
	s_delay_alu instid0(VALU_DEP_2)
	v_add_nc_u64_e32 v[4:5], s[4:5], v[2:3]
	global_load_u16 v1, v[4:5], off offset:64
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_9
; %bb.3:
	global_load_u16 v1, v[4:5], off offset:128
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v6, 0x80, v2
	v_mov_b32_e32 v7, s5
	s_mov_b32 s1, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xa0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_9
; %bb.4:
	global_load_u16 v1, v[4:5], off offset:192
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v6, 0xc0, v2
	v_mov_b32_e32 v7, s5
	s_mov_b32 s1, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_9
; %bb.5:
	global_load_u16 v1, v[4:5], off offset:256
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v6, 0x100, v2
	v_mov_b32_e32 v7, s5
	s_mov_b32 s1, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x60, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_9
; %bb.6:
	global_load_u16 v1, v[4:5], off offset:320
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v6, 0x140, v2
	v_mov_b32_e32 v7, s5
	s_mov_b32 s1, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_9
; %bb.7:
	global_load_u16 v1, v[4:5], off offset:384
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v6, 0x180, v2
	v_mov_b32_e32 v7, s5
	s_mov_b32 s1, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 32, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_9
; %bb.8:
	global_load_u16 v1, v[4:5], off offset:448
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0x1c0, v2
	v_mov_b32_e32 v3, s5
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_9:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshlrev_b32 v3, 4, v0
	v_mov_b32_e32 v2, 0
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_3)
	v_and_b32_e32 v18, 8, v1
	v_and_b32_e32 v19, 0xf0, v3
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_dual_mov_b32 v9, v2 :: v_dual_mov_b32 v3, v2
	v_dual_mov_b32 v4, v2 :: v_dual_mov_b32 v5, v2
	v_mov_b32_e32 v6, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mov_b64_e32 v[16:17], v[8:9]
	v_mov_b64_e32 v[10:11], v[2:3]
	v_or_b32_e32 v20, v18, v19
	v_mov_b64_e32 v[12:13], v[4:5]
	v_mov_b64_e32 v[14:15], v[6:7]
	; wave barrier
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_11
; %bb.10:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v5, s5 :: v_dual_lshlrev_b32 v4, 1, v20
	v_dual_mov_b32 v11, v2 :: v_dual_bitop2_b32 v3, 1, v18 bitop3:0x54
	v_dual_mov_b32 v23, v2 :: v_dual_mov_b32 v24, v2
	flat_load_u16 v21, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v3, v3
	v_dual_mov_b32 v25, v2 :: v_dual_mov_b32 v26, v2
	v_dual_mov_b32 v27, v2 :: v_dual_mov_b32 v28, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cvt_f16_f32_e32 v3, v3
	v_dual_mov_b32 v29, v2 :: v_dual_mov_b32 v14, v2
	v_dual_mov_b32 v12, v2 :: v_dual_mov_b32 v13, v2
	v_pack_b32_f16 v10, v3, 0
	v_dual_mov_b32 v15, v2 :: v_dual_mov_b32 v16, v2
	v_mov_b32_e32 v17, v2
	s_wait_dscnt 0x0
	v_and_b32_e32 v22, 0xffff, v21
	global_store_b16 v20, v21, s[2:3] scale_offset
	s_wait_xcnt 0x1
	v_mov_b64_e32 v[2:3], v[22:23]
	v_mov_b64_e32 v[4:5], v[24:25]
	v_mov_b64_e32 v[6:7], v[26:27]
	v_mov_b64_e32 v[8:9], v[28:29]
.LBB0_11:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_13
; %bb.12:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v22, v20, 1, 2
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 2, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v10, v22, v10, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v2, v21, v2, 0x5040100
	global_store_b16 v20, v21, s[2:3] offset:2 scale_offset
.LBB0_13:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_15
; %bb.14:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v22, v20, 1, 4
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 3, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v11, 0xffff, v22, v11
	s_wait_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v21, v3
	global_store_b16 v20, v21, s[2:3] offset:4 scale_offset
.LBB0_15:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_17
; %bb.16:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v22, v20, 1, 6
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 4, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v11, v22, v11, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v3, v21, v3, 0x5040100
	global_store_b16 v20, v21, s[2:3] offset:6 scale_offset
.LBB0_17:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_19
; %bb.18:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v22, v20, 1, 8
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 5, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v12, 0xffff, v22, v12
	s_wait_dscnt 0x0
	v_bfi_b32 v4, 0xffff, v21, v4
	global_store_b16 v20, v21, s[2:3] offset:8 scale_offset
.LBB0_19:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_21
; %bb.20:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v22, v20, 1, 10
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 6, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v12, v22, v12, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v4, v21, v4, 0x5040100
	global_store_b16 v20, v21, s[2:3] offset:10 scale_offset
.LBB0_21:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_or_b32_e32 v21, 7, v1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_23
; %bb.22:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v22, v20, 1, 12
	v_mov_b32_e32 v23, s5
	flat_load_u16 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_ubyte0_e32 v23, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v23, v23
	v_bfi_b32 v13, 0xffff, v23, v13
	s_wait_dscnt 0x0
	v_bfi_b32 v5, 0xffff, v22, v5
	global_store_b16 v20, v22, s[2:3] offset:12 scale_offset
.LBB0_23:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_25
; %bb.24:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v23, s5 :: v_dual_bitop2_b32 v19, v21, v19 bitop3:0x54
	v_dual_add_nc_u32 v21, 1, v21 :: v_dual_lshlrev_b32 v22, 1, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v21, v21
	flat_load_u16 v20, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f16_f32_e32 v21, v21
	v_perm_b32 v13, v21, v13, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v5, v20, v5, 0x5040100
	global_store_b16 v19, v20, s[2:3] scale_offset
.LBB0_25:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_lshlrev_b32 v0, 2, v0 :: v_dual_bitop2_b32 v19, 15, v0 bitop3:0x40
	v_lshlrev_b32_e32 v1, 6, v1
	v_wmma_f32_16x16x32_f16 v[20:27], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshlrev_b32_e32 v19, 2, v19
	v_or3_b32 v0, v1, v0, 0x1c0
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v1, v18, 6, v19
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b32 v1, v20, s[6:7]
	global_store_b32 v1, v21, s[6:7] offset:64
	global_store_b32 v1, v22, s[6:7] offset:128
	global_store_b32 v1, v23, s[6:7] offset:192
	global_store_b32 v1, v24, s[6:7] offset:256
	global_store_b32 v1, v25, s[6:7] offset:320
	global_store_b32 v1, v26, s[6:7] offset:384
	global_store_b32 v0, v27, s[6:7]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_stride32
		.amdhsa_group_segment_fixed_size 544
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
		.amdhsa_next_free_vgpr 30
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
		.amdhsa_inst_pref_size 15
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
	.size	matrix_stride32, .Lfunc_end0-matrix_stride32
                                        ; -- End function
	.set matrix_stride32.num_vgpr, 30
	.set matrix_stride32.num_agpr, 0
	.set matrix_stride32.numbered_sgpr, 10
	.set matrix_stride32.num_named_barrier, 0
	.set matrix_stride32.private_seg_size, 0
	.set matrix_stride32.uses_vcc, 1
	.set matrix_stride32.uses_flat_scratch, 0
	.set matrix_stride32.has_dyn_sized_stack, 0
	.set matrix_stride32.has_recursion, 0
	.set matrix_stride32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1856
; TotalNumSgprs: 12
; NumVgprs: 30
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 544 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 12
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
	.protected	matrix_stride48         ; -- Begin function matrix_stride48
	.globl	matrix_stride48
	.p2align	8
	.type	matrix_stride48,@function
matrix_stride48:                        ; @matrix_stride48
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_and_b32_e32 v1, 15, v0
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB1_9
; %bb.1:
	s_wait_kmcnt 0x0
	global_load_u16 v5, v0, s[4:5] scale_offset
	v_dual_lshrrev_b32 v2, 4, v0 :: v_dual_lshlrev_b32 v4, 1, v1
	s_mov_b64 s[8:9], src_shared_base
	v_cmp_gt_u32_e32 vcc_lo, 0xe0, v0
	v_mov_b32_e32 v3, s9
	s_delay_alu instid0(VALU_DEP_3)
	v_mad_u32_u24 v2, v2, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB1_9
; %bb.2:
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v2, 1, v0
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v7, s9 :: v_dual_bitop2_b32 v6, 32, v0 bitop3:0x54
	s_mov_b32 s1, exec_lo
	v_add_nc_u64_e32 v[2:3], s[4:5], v[2:3]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 48, v4
	global_load_u16 v5, v[2:3], off offset:64
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB1_9
; %bb.3:
	global_load_u16 v5, v[2:3], off offset:128
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_bitop2_b32 v6, 64, v0 bitop3:0x54
	s_mov_b32 s1, exec_lo
	v_lshrrev_b32_e32 v6, 4, v6
	s_delay_alu instid0(VALU_DEP_1)
	v_mad_u32_u24 v6, v6, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xa0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB1_9
; %bb.4:
	global_load_u16 v5, v[2:3], off offset:192
	v_or_b32_e32 v6, 0x60, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB1_9
; %bb.5:
	global_load_u16 v5, v[2:3], off offset:256
	v_or_b32_e32 v6, 0x80, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x60, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB1_9
; %bb.6:
	global_load_u16 v5, v[2:3], off offset:320
	v_or_b32_e32 v6, 0xa0, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB1_9
; %bb.7:
	global_load_u16 v5, v[2:3], off offset:384
	v_or_b32_e32 v6, 0xc0, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 32, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB1_9
; %bb.8:
	global_load_u16 v5, v[2:3], off offset:448
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0xe0, v0
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s5 :: v_dual_lshrrev_b32 v2, 4, v2
	s_delay_alu instid0(VALU_DEP_1)
	v_mad_u32_u24 v2, v2, 48, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_9:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_mov_b32 v2, 0 :: v_dual_lshrrev_b32 v18, 1, v0
	v_mul_u32_u24_e32 v21, 48, v1
	v_lshlrev_b32_e32 v20, 4, v1
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_dual_mov_b32 v9, v2 :: v_dual_bitop2_b32 v19, 8, v18 bitop3:0x40
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	v_mov_b64_e32 v[16:17], v[8:9]
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_mov_b64_e32 v[10:11], v[2:3]
	s_wait_dscnt 0x0
	v_mov_b64_e32 v[12:13], v[4:5]
	v_mov_b64_e32 v[14:15], v[6:7]
	; wave barrier
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_11
; %bb.10:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v4, v19, 1, v21
	v_dual_mov_b32 v5, s5 :: v_dual_bitop2_b32 v3, 1, v19 bitop3:0x54
	v_dual_mov_b32 v23, v2 :: v_dual_mov_b32 v24, v2
	v_dual_mov_b32 v25, v2 :: v_dual_mov_b32 v26, v2
	flat_load_u16 v0, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v3, v3
	v_dual_mov_b32 v27, v2 :: v_dual_mov_b32 v28, v2
	v_dual_mov_b32 v29, v2 :: v_dual_mov_b32 v15, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cvt_f16_f32_e32 v3, v3
	v_dual_mov_b32 v11, v2 :: v_dual_mov_b32 v12, v2
	v_dual_mov_b32 v13, v2 :: v_dual_mov_b32 v14, v2
	v_pack_b32_f16 v10, v3, 0
	v_dual_mov_b32 v16, v2 :: v_dual_mov_b32 v17, v2
	v_or_b32_e32 v30, v19, v20
	s_wait_dscnt 0x0
	v_and_b32_e32 v22, 0xffff, v0
	global_store_b16 v30, v0, s[2:3] scale_offset
	s_wait_xcnt 0x1
	v_mov_b64_e32 v[2:3], v[22:23]
	v_mov_b64_e32 v[4:5], v[24:25]
	v_mov_b64_e32 v[6:7], v[26:27]
	v_mov_b64_e32 v[8:9], v[28:29]
.LBB1_11:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_add_nc_u32 v0, v19, v20 :: v_dual_lshlrev_b32 v22, 1, v19
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_13
; %bb.12:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 2
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 2, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v10, v24, v10, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v2, v23, v2, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:2 scale_offset
.LBB1_13:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_15
; %bb.14:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 4
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 3, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v11, 0xffff, v24, v11
	s_wait_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v23, v3
	global_store_b16 v0, v23, s[2:3] offset:4 scale_offset
.LBB1_15:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_17
; %bb.16:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 6
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 4, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v11, v24, v11, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v3, v23, v3, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:6 scale_offset
.LBB1_17:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_19
; %bb.18:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 8
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 5, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v12, 0xffff, v24, v12
	s_wait_dscnt 0x0
	v_bfi_b32 v4, 0xffff, v23, v4
	global_store_b16 v0, v23, s[2:3] offset:8 scale_offset
.LBB1_19:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_21
; %bb.20:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 10
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 6, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v12, v24, v12, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v4, v23, v4, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:10 scale_offset
.LBB1_21:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_or_b32_e32 v23, 7, v18
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_23
; %bb.22:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 12
	v_mov_b32_e32 v25, s5
	flat_load_u16 v22, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_ubyte0_e32 v24, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_bfi_b32 v13, 0xffff, v24, v13
	s_wait_dscnt 0x0
	v_bfi_b32 v5, 0xffff, v22, v5
	global_store_b16 v0, v22, s[2:3] offset:12 scale_offset
.LBB1_23:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_25
; %bb.24:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v24, v23, 1, v21
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v21, 1, v23
	v_or_b32_e32 v20, v23, v20
	flat_load_u16 v0, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v21, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v21, v21
	v_perm_b32 v13, v21, v13, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v5, v0, v5, 0x5040100
	global_store_b16 v20, v0, s[2:3] scale_offset
.LBB1_25:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_lshlrev_b32 v0, 2, v1 :: v_dual_lshlrev_b32 v1, 6, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v26, v19, 6, v0
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	v_or3_b32 v0, v1, v0, 0x1c0
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b32 v26, v18, s[6:7]
	global_store_b32 v26, v19, s[6:7] offset:64
	global_store_b32 v26, v20, s[6:7] offset:128
	global_store_b32 v26, v21, s[6:7] offset:192
	global_store_b32 v26, v22, s[6:7] offset:256
	global_store_b32 v26, v23, s[6:7] offset:320
	global_store_b32 v26, v24, s[6:7] offset:384
	global_store_b32 v0, v25, s[6:7]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_stride48
		.amdhsa_group_segment_fixed_size 800
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
		.amdhsa_next_free_vgpr 31
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
		.amdhsa_inst_pref_size 16
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
	.size	matrix_stride48, .Lfunc_end1-matrix_stride48
                                        ; -- End function
	.set matrix_stride48.num_vgpr, 31
	.set matrix_stride48.num_agpr, 0
	.set matrix_stride48.numbered_sgpr, 10
	.set matrix_stride48.num_named_barrier, 0
	.set matrix_stride48.private_seg_size, 0
	.set matrix_stride48.uses_vcc, 1
	.set matrix_stride48.uses_flat_scratch, 0
	.set matrix_stride48.has_dyn_sized_stack, 0
	.set matrix_stride48.has_recursion, 0
	.set matrix_stride48.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2000
; TotalNumSgprs: 12
; NumVgprs: 31
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 800 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 31
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
	.protected	matrix_stride64         ; -- Begin function matrix_stride64
	.globl	matrix_stride64
	.p2align	8
	.type	matrix_stride64,@function
matrix_stride64:                        ; @matrix_stride64
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_and_b32_e32 v1, 15, v0
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB2_9
; %bb.1:
	s_wait_kmcnt 0x0
	global_load_u16 v5, v0, s[4:5] scale_offset
	v_dual_lshlrev_b32 v2, 2, v0 :: v_dual_lshlrev_b32 v4, 1, v1
	s_mov_b64 s[8:9], src_shared_base
	v_cmp_gt_u32_e32 vcc_lo, 0xe0, v0
	v_mov_b32_e32 v3, s9
	s_delay_alu instid0(VALU_DEP_3)
	v_and_or_b32 v2, v2, 64, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB2_9
; %bb.2:
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v2, 1, v0
	v_lshl_or_b32 v6, v0, 2, 0x80
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s9
	v_add_nc_u64_e32 v[2:3], s[4:5], v[2:3]
	v_and_or_b32 v6, 0xc0, v6, v4
	global_load_u16 v5, v[2:3], off offset:64
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB2_9
; %bb.3:
	global_load_u16 v5, v[2:3], off offset:128
	v_lshl_or_b32 v6, v0, 2, 0x100
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s5
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v6, 0x140, v6, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xa0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB2_9
; %bb.4:
	global_load_u16 v5, v[2:3], off offset:192
	v_lshl_or_b32 v6, v0, 2, 0x180
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s5
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v6, 0x1c0, v6, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB2_9
; %bb.5:
	global_load_u16 v5, v[2:3], off offset:256
	v_lshl_or_b32 v6, v0, 2, 0x200
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s5
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v6, 0x240, v6, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x60, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB2_9
; %bb.6:
	global_load_u16 v5, v[2:3], off offset:320
	v_lshl_or_b32 v6, v0, 2, 0x280
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s5
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v6, 0x2c0, v6, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB2_9
; %bb.7:
	global_load_u16 v5, v[2:3], off offset:384
	v_lshl_or_b32 v6, v0, 2, 0x300
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	v_mov_b32_e32 v7, s5
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v6, 0x340, v6, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 32, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB2_9
; %bb.8:
	global_load_u16 v5, v[2:3], off offset:448
	s_wait_xcnt 0x0
	v_lshl_or_b32 v2, v0, 2, 0x380
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mov_b32_e32 v3, s5
	v_and_or_b32 v2, 0x3c0, v2, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_9:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_mov_b32 v2, 0 :: v_dual_lshrrev_b32 v18, 1, v0
	v_dual_lshlrev_b32 v21, 6, v1 :: v_dual_lshlrev_b32 v20, 4, v1
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_dual_mov_b32 v9, v2 :: v_dual_bitop2_b32 v19, 8, v18 bitop3:0x40
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mov_b64_e32 v[16:17], v[8:9]
	v_mov_b64_e32 v[10:11], v[2:3]
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_3)
	v_mov_b64_e32 v[12:13], v[4:5]
	v_mov_b64_e32 v[14:15], v[6:7]
	; wave barrier
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_11
; %bb.10:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v4, v19, 1, v21
	v_dual_mov_b32 v5, s5 :: v_dual_bitop2_b32 v3, 1, v19 bitop3:0x54
	v_dual_mov_b32 v23, v2 :: v_dual_mov_b32 v24, v2
	v_dual_mov_b32 v25, v2 :: v_dual_mov_b32 v26, v2
	flat_load_u16 v0, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v3, v3
	v_dual_mov_b32 v27, v2 :: v_dual_mov_b32 v28, v2
	v_dual_mov_b32 v29, v2 :: v_dual_mov_b32 v15, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cvt_f16_f32_e32 v3, v3
	v_dual_mov_b32 v11, v2 :: v_dual_mov_b32 v12, v2
	v_dual_mov_b32 v13, v2 :: v_dual_mov_b32 v14, v2
	v_pack_b32_f16 v10, v3, 0
	v_dual_mov_b32 v16, v2 :: v_dual_mov_b32 v17, v2
	v_or_b32_e32 v30, v19, v20
	s_wait_dscnt 0x0
	v_and_b32_e32 v22, 0xffff, v0
	global_store_b16 v30, v0, s[2:3] scale_offset
	s_wait_xcnt 0x1
	v_mov_b64_e32 v[2:3], v[22:23]
	v_mov_b64_e32 v[4:5], v[24:25]
	v_mov_b64_e32 v[6:7], v[26:27]
	v_mov_b64_e32 v[8:9], v[28:29]
.LBB2_11:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_add_nc_u32 v0, v19, v20 :: v_dual_lshlrev_b32 v22, 1, v19
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_13
; %bb.12:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 2
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 2, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v10, v24, v10, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v2, v23, v2, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:2 scale_offset
.LBB2_13:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_15
; %bb.14:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 4
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 3, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v11, 0xffff, v24, v11
	s_wait_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v23, v3
	global_store_b16 v0, v23, s[2:3] offset:4 scale_offset
.LBB2_15:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_17
; %bb.16:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 6
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 4, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v11, v24, v11, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v3, v23, v3, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:6 scale_offset
.LBB2_17:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_19
; %bb.18:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 8
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 5, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v12, 0xffff, v24, v12
	s_wait_dscnt 0x0
	v_bfi_b32 v4, 0xffff, v23, v4
	global_store_b16 v0, v23, s[2:3] offset:8 scale_offset
.LBB2_19:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_21
; %bb.20:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 10
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 6, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v12, v24, v12, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v4, v23, v4, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:10 scale_offset
.LBB2_21:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_or_b32_e32 v23, 7, v18
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_23
; %bb.22:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 12
	v_mov_b32_e32 v25, s5
	flat_load_u16 v22, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_ubyte0_e32 v24, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_bfi_b32 v13, 0xffff, v24, v13
	s_wait_dscnt 0x0
	v_bfi_b32 v5, 0xffff, v22, v5
	global_store_b16 v0, v22, s[2:3] offset:12 scale_offset
.LBB2_23:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_25
; %bb.24:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v24, v23, 1, v21
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v21, 1, v23
	v_or_b32_e32 v20, v23, v20
	flat_load_u16 v0, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v21, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v21, v21
	v_perm_b32 v13, v21, v13, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v5, v0, v5, 0x5040100
	global_store_b16 v20, v0, s[2:3] scale_offset
.LBB2_25:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_lshlrev_b32 v0, 2, v1 :: v_dual_lshlrev_b32 v1, 6, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v26, v19, 6, v0
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	v_or3_b32 v0, v1, v0, 0x1c0
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b32 v26, v18, s[6:7]
	global_store_b32 v26, v19, s[6:7] offset:64
	global_store_b32 v26, v20, s[6:7] offset:128
	global_store_b32 v26, v21, s[6:7] offset:192
	global_store_b32 v26, v22, s[6:7] offset:256
	global_store_b32 v26, v23, s[6:7] offset:320
	global_store_b32 v26, v24, s[6:7] offset:384
	global_store_b32 v0, v25, s[6:7]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_stride64
		.amdhsa_group_segment_fixed_size 1056
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
		.amdhsa_next_free_vgpr 31
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
		.amdhsa_inst_pref_size 16
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
	.size	matrix_stride64, .Lfunc_end2-matrix_stride64
                                        ; -- End function
	.set matrix_stride64.num_vgpr, 31
	.set matrix_stride64.num_agpr, 0
	.set matrix_stride64.numbered_sgpr, 10
	.set matrix_stride64.num_named_barrier, 0
	.set matrix_stride64.private_seg_size, 0
	.set matrix_stride64.uses_vcc, 1
	.set matrix_stride64.uses_flat_scratch, 0
	.set matrix_stride64.has_dyn_sized_stack, 0
	.set matrix_stride64.has_recursion, 0
	.set matrix_stride64.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2020
; TotalNumSgprs: 12
; NumVgprs: 31
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 1056 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 31
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
	.protected	matrix_stride40         ; -- Begin function matrix_stride40
	.globl	matrix_stride40
	.p2align	8
	.type	matrix_stride40,@function
matrix_stride40:                        ; @matrix_stride40
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_and_b32_e32 v1, 15, v0
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB3_9
; %bb.1:
	s_wait_kmcnt 0x0
	global_load_u16 v5, v0, s[4:5] scale_offset
	v_dual_lshrrev_b32 v2, 4, v0 :: v_dual_lshlrev_b32 v4, 1, v1
	s_mov_b64 s[8:9], src_shared_base
	v_cmp_gt_u32_e32 vcc_lo, 0xe0, v0
	v_mov_b32_e32 v3, s9
	s_delay_alu instid0(VALU_DEP_3)
	v_mad_u32_u24 v2, v2, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_9
; %bb.2:
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v2, 1, v0
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v7, s9 :: v_dual_bitop2_b32 v6, 32, v0 bitop3:0x54
	s_mov_b32 s1, exec_lo
	v_add_nc_u64_e32 v[2:3], s[4:5], v[2:3]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 40, v4
	global_load_u16 v5, v[2:3], off offset:64
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB3_9
; %bb.3:
	global_load_u16 v5, v[2:3], off offset:128
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_bitop2_b32 v6, 64, v0 bitop3:0x54
	s_mov_b32 s1, exec_lo
	v_lshrrev_b32_e32 v6, 4, v6
	s_delay_alu instid0(VALU_DEP_1)
	v_mad_u32_u24 v6, v6, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xa0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB3_9
; %bb.4:
	global_load_u16 v5, v[2:3], off offset:192
	v_or_b32_e32 v6, 0x60, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB3_9
; %bb.5:
	global_load_u16 v5, v[2:3], off offset:256
	v_or_b32_e32 v6, 0x80, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x60, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB3_9
; %bb.6:
	global_load_u16 v5, v[2:3], off offset:320
	v_or_b32_e32 v6, 0xa0, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB3_9
; %bb.7:
	global_load_u16 v5, v[2:3], off offset:384
	v_or_b32_e32 v6, 0xc0, v0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v7, s5 :: v_dual_lshrrev_b32 v6, 4, v6
	v_mad_u32_u24 v6, v6, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 32, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB3_9
; %bb.8:
	global_load_u16 v5, v[2:3], off offset:448
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0xe0, v0
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s5 :: v_dual_lshrrev_b32 v2, 4, v2
	s_delay_alu instid0(VALU_DEP_1)
	v_mad_u32_u24 v2, v2, 40, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB3_9:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_mov_b32 v2, 0 :: v_dual_lshrrev_b32 v18, 1, v0
	v_mul_u32_u24_e32 v21, 40, v1
	v_lshlrev_b32_e32 v20, 4, v1
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_dual_mov_b32 v9, v2 :: v_dual_bitop2_b32 v19, 8, v18 bitop3:0x40
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	v_mov_b64_e32 v[16:17], v[8:9]
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_mov_b64_e32 v[10:11], v[2:3]
	s_wait_dscnt 0x0
	v_mov_b64_e32 v[12:13], v[4:5]
	v_mov_b64_e32 v[14:15], v[6:7]
	; wave barrier
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_11
; %bb.10:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v4, v19, 1, v21
	v_dual_mov_b32 v5, s5 :: v_dual_bitop2_b32 v3, 1, v19 bitop3:0x54
	v_dual_mov_b32 v23, v2 :: v_dual_mov_b32 v24, v2
	v_dual_mov_b32 v25, v2 :: v_dual_mov_b32 v26, v2
	flat_load_u16 v0, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v3, v3
	v_dual_mov_b32 v27, v2 :: v_dual_mov_b32 v28, v2
	v_dual_mov_b32 v29, v2 :: v_dual_mov_b32 v15, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cvt_f16_f32_e32 v3, v3
	v_dual_mov_b32 v11, v2 :: v_dual_mov_b32 v12, v2
	v_dual_mov_b32 v13, v2 :: v_dual_mov_b32 v14, v2
	v_pack_b32_f16 v10, v3, 0
	v_dual_mov_b32 v16, v2 :: v_dual_mov_b32 v17, v2
	v_or_b32_e32 v30, v19, v20
	s_wait_dscnt 0x0
	v_and_b32_e32 v22, 0xffff, v0
	global_store_b16 v30, v0, s[2:3] scale_offset
	s_wait_xcnt 0x1
	v_mov_b64_e32 v[2:3], v[22:23]
	v_mov_b64_e32 v[4:5], v[24:25]
	v_mov_b64_e32 v[6:7], v[26:27]
	v_mov_b64_e32 v[8:9], v[28:29]
.LBB3_11:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_add_nc_u32 v0, v19, v20 :: v_dual_lshlrev_b32 v22, 1, v19
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_13
; %bb.12:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 2
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 2, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v10, v24, v10, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v2, v23, v2, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:2 scale_offset
.LBB3_13:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_15
; %bb.14:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 4
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 3, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v11, 0xffff, v24, v11
	s_wait_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v23, v3
	global_store_b16 v0, v23, s[2:3] offset:4 scale_offset
.LBB3_15:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_17
; %bb.16:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 6
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 4, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v11, v24, v11, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v3, v23, v3, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:6 scale_offset
.LBB3_17:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_19
; %bb.18:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 8
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 5, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v12, 0xffff, v24, v12
	s_wait_dscnt 0x0
	v_bfi_b32 v4, 0xffff, v23, v4
	global_store_b16 v0, v23, s[2:3] offset:8 scale_offset
.LBB3_19:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_21
; %bb.20:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 10
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v24, 6, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_ubyte0_e32 v24, v24
	v_cvt_f16_f32_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v12, v24, v12, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v4, v23, v4, 0x5040100
	global_store_b16 v0, v23, s[2:3] offset:10 scale_offset
.LBB3_21:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_or_b32_e32 v23, 7, v18
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_23
; %bb.22:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v21, v22, 12
	v_mov_b32_e32 v25, s5
	flat_load_u16 v22, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_ubyte0_e32 v24, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_bfi_b32 v13, 0xffff, v24, v13
	s_wait_dscnt 0x0
	v_bfi_b32 v5, 0xffff, v22, v5
	global_store_b16 v0, v22, s[2:3] offset:12 scale_offset
.LBB3_23:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_25
; %bb.24:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v24, v23, 1, v21
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v21, 1, v23
	v_or_b32_e32 v20, v23, v20
	flat_load_u16 v0, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_ubyte0_e32 v21, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v21, v21
	v_perm_b32 v13, v21, v13, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v5, v0, v5, 0x5040100
	global_store_b16 v20, v0, s[2:3] scale_offset
.LBB3_25:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_lshlrev_b32 v0, 2, v1 :: v_dual_lshlrev_b32 v1, 6, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v26, v19, 6, v0
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	v_or3_b32 v0, v1, v0, 0x1c0
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b32 v26, v18, s[6:7]
	global_store_b32 v26, v19, s[6:7] offset:64
	global_store_b32 v26, v20, s[6:7] offset:128
	global_store_b32 v26, v21, s[6:7] offset:192
	global_store_b32 v26, v22, s[6:7] offset:256
	global_store_b32 v26, v23, s[6:7] offset:320
	global_store_b32 v26, v24, s[6:7] offset:384
	global_store_b32 v0, v25, s[6:7]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_stride40
		.amdhsa_group_segment_fixed_size 672
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
		.amdhsa_next_free_vgpr 31
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
		.amdhsa_inst_pref_size 16
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
	.size	matrix_stride40, .Lfunc_end3-matrix_stride40
                                        ; -- End function
	.set matrix_stride40.num_vgpr, 31
	.set matrix_stride40.num_agpr, 0
	.set matrix_stride40.numbered_sgpr, 10
	.set matrix_stride40.num_named_barrier, 0
	.set matrix_stride40.private_seg_size, 0
	.set matrix_stride40.uses_vcc, 1
	.set matrix_stride40.uses_flat_scratch, 0
	.set matrix_stride40.has_dyn_sized_stack, 0
	.set matrix_stride40.has_recursion, 0
	.set matrix_stride40.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2000
; TotalNumSgprs: 12
; NumVgprs: 31
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 672 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 31
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
	.protected	matrix_stride16         ; -- Begin function matrix_stride16
	.globl	matrix_stride16
	.p2align	8
	.type	matrix_stride16,@function
matrix_stride16:                        ; @matrix_stride16
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_bitop2_b32 v16, 15, v0 bitop3:0x40
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 0xff, v0
	s_xor_b32 s0, exec_lo, s0
; %bb.1:
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_bitop2_b32 v16, 15, v0 bitop3:0x40
                                        ; implicit-def: $vgpr0
; %bb.2:
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB4_12
; %bb.3:
	s_wait_kmcnt 0x0
	global_load_u16 v4, v0, s[4:5] scale_offset
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v3, s9 :: v_dual_bitop2_b32 v2, 16, v0 bitop3:0x40
	s_mov_b32 s1, exec_lo
	v_lshl_add_u32 v2, v16, 1, v2
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xe0, v0
	s_cbranch_execz .LBB4_11
; %bb.4:
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v2, 1, v0
	v_bitop3_b32 v4, v0, 48, 32 bitop3:0xc8
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mov_b32_e32 v5, s9
	v_add_nc_u64_e32 v[2:3], s[4:5], v[2:3]
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_add_u32 v4, v16, 1, v4
	s_mov_b32 s4, exec_lo
	global_load_u16 v6, v[2:3], off offset:64
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB4_11
; %bb.5:
	global_load_u16 v6, v[2:3], off offset:128
	v_bitop3_b32 v4, v0, 0x50, 64 bitop3:0xc8
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, exec_lo
	v_mov_b32_e32 v5, s5
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_add_u32 v4, v16, 1, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xa0, v0
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB4_11
; %bb.6:
	global_load_u16 v6, v[2:3], off offset:192
	s_mov_b64 s[4:5], src_shared_base
	s_movk_i32 s4, 0x70
	v_mov_b32_e32 v5, s5
	v_bitop3_b32 v4, v0, s4, 0x60 bitop3:0xc8
	s_mov_b32 s4, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v4, v16, 1, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB4_11
; %bb.7:
	global_load_u16 v6, v[2:3], off offset:256
	s_mov_b64 s[4:5], src_shared_base
	s_movk_i32 s4, 0x90
	v_mov_b32_e32 v5, s5
	v_bitop3_b32 v4, v0, s4, 0x80 bitop3:0xc8
	s_mov_b32 s4, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v4, v16, 1, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x60, v0
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB4_11
; %bb.8:
	global_load_u16 v6, v[2:3], off offset:320
	s_mov_b64 s[4:5], src_shared_base
	s_movk_i32 s4, 0xb0
	v_mov_b32_e32 v5, s5
	v_bitop3_b32 v4, v0, s4, 0xa0 bitop3:0xc8
	s_mov_b32 s4, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v4, v16, 1, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB4_11
; %bb.9:
	global_load_u16 v6, v[2:3], off offset:384
	s_mov_b64 s[4:5], src_shared_base
	s_movk_i32 s4, 0xd0
	v_mov_b32_e32 v5, s5
	v_bitop3_b32 v4, v0, s4, 0xc0 bitop3:0xc8
	s_mov_b32 s4, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v4, v16, 1, v4
	s_wait_loadcnt 0x0
	flat_store_b16 v[4:5], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 32, v0
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB4_11
; %bb.10:
	global_load_u16 v4, v[2:3], off offset:448
	s_mov_b64 s[4:5], src_shared_base
	s_movk_i32 s4, 0xf0
	s_wait_xcnt 0x0
	v_mov_b32_e32 v3, s5
	v_bitop3_b32 v0, v0, s4, 0xe0 bitop3:0xc8
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v2, v16, 1, v0
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_11:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
.LBB4_12:
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_mov_b32 v0, 0 :: v_dual_lshlrev_b32 v18, 4, v16
	v_and_b32_e32 v17, 0x1f8, v1
	s_wait_dscnt 0x0
	; wave barrier
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_dual_mov_b32 v7, v0 :: v_dual_mov_b32 v1, v0
	v_dual_mov_b32 v2, v0 :: v_dual_mov_b32 v3, v0
	v_mov_b32_e32 v4, v0
	v_mov_b64_e32 v[14:15], v[6:7]
	s_delay_alu instid0(VALU_DEP_4)
	v_mov_b64_e32 v[8:9], v[0:1]
	v_cmp_gt_u32_e32 vcc_lo, 16, v17
	v_mov_b64_e32 v[10:11], v[2:3]
	v_mov_b64_e32 v[12:13], v[4:5]
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_14
; %bb.13:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v2, v17, 1, v18
	v_dual_mov_b32 v3, s5 :: v_dual_bitop2_b32 v1, 1, v17 bitop3:0x54
	v_dual_mov_b32 v21, v0 :: v_dual_mov_b32 v22, v0
	v_dual_mov_b32 v23, v0 :: v_dual_mov_b32 v24, v0
	flat_load_u16 v19, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_cvt_f32_u32_e32 v1, v1
	v_dual_mov_b32 v25, v0 :: v_dual_mov_b32 v26, v0
	v_dual_mov_b32 v27, v0 :: v_dual_mov_b32 v13, v0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cvt_f16_f32_e32 v1, v1
	v_dual_mov_b32 v9, v0 :: v_dual_mov_b32 v10, v0
	v_dual_mov_b32 v11, v0 :: v_dual_mov_b32 v12, v0
	v_pack_b32_f16 v8, v1, 0
	v_dual_mov_b32 v14, v0 :: v_dual_mov_b32 v15, v0
	v_or_b32_e32 v28, v17, v18
	s_wait_dscnt 0x0
	v_and_b32_e32 v20, 0xffff, v19
	global_store_b16 v28, v19, s[2:3] scale_offset
	s_wait_xcnt 0x1
	v_mov_b64_e32 v[0:1], v[20:21]
	v_mov_b64_e32 v[2:3], v[22:23]
	v_mov_b64_e32 v[4:5], v[24:25]
	v_mov_b64_e32 v[6:7], v[26:27]
.LBB4_14:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_add_nc_u32 v19, v17, v18 :: v_dual_lshlrev_b32 v20, 1, v17
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_16
; %bb.15:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v18, v20, 2
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 2, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v8, v22, v8, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v0, v21, v0, 0x5040100
	global_store_b16 v19, v21, s[2:3] offset:2 scale_offset
.LBB4_16:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_18
; %bb.17:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v18, v20, 4
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 3, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v9, 0xffff, v22, v9
	s_wait_dscnt 0x0
	v_bfi_b32 v1, 0xffff, v21, v1
	global_store_b16 v19, v21, s[2:3] offset:4 scale_offset
.LBB4_18:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_20
; %bb.19:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v18, v20, 6
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 4, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v9, v22, v9, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v1, v21, v1, 0x5040100
	global_store_b16 v19, v21, s[2:3] offset:6 scale_offset
.LBB4_20:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_22
; %bb.21:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v18, v20, 8
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 5, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v10, 0xffff, v22, v10
	s_wait_dscnt 0x0
	v_bfi_b32 v2, 0xffff, v21, v2
	global_store_b16 v19, v21, s[2:3] offset:8 scale_offset
.LBB4_22:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_24
; %bb.23:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v18, v20, 10
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 6, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v10, v22, v10, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v2, v21, v2, 0x5040100
	global_store_b16 v19, v21, s[2:3] offset:10 scale_offset
.LBB4_24:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_26
; %bb.25:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v18, v20, 12
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v22, 7, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v22, v22
	v_cvt_f16_f32_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1)
	v_bfi_b32 v11, 0xffff, v22, v11
	s_wait_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v21, v3
	global_store_b16 v19, v21, s[2:3] offset:12 scale_offset
.LBB4_26:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_28
; %bb.27:
	s_wait_kmcnt 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v18, v20, 14
	v_mov_b32_e32 v21, s5
	flat_load_u16 v18, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v20, 8, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_u32_e32 v20, v20
	v_cvt_f16_f32_e32 v20, v20
	s_delay_alu instid0(VALU_DEP_1)
	v_perm_b32 v11, v20, v11, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v3, v18, v3, 0x5040100
	global_store_b16 v19, v18, s[2:3] offset:14 scale_offset
.LBB4_28:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_wmma_f32_16x16x32_f16 v[18:25], v[0:7], v[8:15], 0
	v_lshl_or_b32 v16, v17, 4, v16
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b32 v16, v18, s[6:7] scale_offset
	global_store_b32 v16, v19, s[6:7] offset:64 scale_offset
	global_store_b32 v16, v20, s[6:7] offset:128 scale_offset
	global_store_b32 v16, v21, s[6:7] offset:192 scale_offset
	global_store_b32 v16, v22, s[6:7] offset:256 scale_offset
	global_store_b32 v16, v23, s[6:7] offset:320 scale_offset
	global_store_b32 v16, v24, s[6:7] offset:384 scale_offset
	global_store_b32 v16, v25, s[6:7] offset:448 scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_stride16
		.amdhsa_group_segment_fixed_size 288
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
		.amdhsa_next_free_vgpr 29
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
		.amdhsa_inst_pref_size 16
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
	.size	matrix_stride16, .Lfunc_end4-matrix_stride16
                                        ; -- End function
	.set matrix_stride16.num_vgpr, 29
	.set matrix_stride16.num_agpr, 0
	.set matrix_stride16.numbered_sgpr, 10
	.set matrix_stride16.num_named_barrier, 0
	.set matrix_stride16.private_seg_size, 0
	.set matrix_stride16.uses_vcc, 1
	.set matrix_stride16.uses_flat_scratch, 0
	.set matrix_stride16.has_dyn_sized_stack, 0
	.set matrix_stride16.has_recursion, 0
	.set matrix_stride16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2012
; TotalNumSgprs: 12
; NumVgprs: 29
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 288 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 29
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
	.protected	matrix_raw_accumulator  ; -- Begin function matrix_raw_accumulator
	.globl	matrix_raw_accumulator
	.p2align	8
	.type	matrix_raw_accumulator,@function
matrix_raw_accumulator:                 ; @matrix_raw_accumulator
; %bb.0:
	;;#ASMSTART
	v_mov_b32 v2, 0x3f800000
	;;#ASMEND
	v_and_b32_e32 v1, 3, v0
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v35, 0 :: v_dual_lshlrev_b32 v10, 3, v0
	s_mov_b32 s4, 0
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	s_mov_b32 s10, s4
	s_mov_b32 s11, s4
	s_mov_b32 s5, s4
	s_mov_b32 s6, s4
	v_cndmask_b32_e32 v2, 0, v2, vcc_lo
	s_mov_b32 s7, s4
	s_mov_b32 s8, s4
	s_mov_b32 s9, s4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v9, v2 :: v_dual_bitop2_b32 v1, 15, v0 bitop3:0x40
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	v_and_or_b32 v1, 0x80, v10, v1
	v_mov_b64_e32 v[16:17], s[10:11]
	v_mov_b64_e32 v[14:15], s[8:9]
	v_mov_b64_e32 v[12:13], s[6:7]
	v_mov_b64_e32 v[10:11], s[4:5]
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_lshlrev_b32_e32 v34, 2, v1
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x32_f16 v[2:9], v[10:17], v[10:17], v[2:9]
	s_wait_kmcnt 0x0
	v_nop
	v_nop
	v_nop
	v_nop
	v_add_nc_u64_e32 v[10:11], s[2:3], v[34:35]
	v_cmp_lt_u32_e32 vcc_lo, 15, v0
	v_mov_b64_e32 v[24:25], s[10:11]
	v_mov_b64_e32 v[32:33], s[10:11]
	v_mov_b64_e32 v[22:23], s[8:9]
	v_mov_b64_e32 v[20:21], s[6:7]
	v_mov_b64_e32 v[18:19], s[4:5]
	v_mov_b64_e32 v[30:31], s[8:9]
	v_mov_b64_e32 v[28:29], s[6:7]
	v_mov_b64_e32 v[26:27], s[4:5]
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	global_store_b32 v1, v2, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB5_2
; %bb.1:
	global_store_b32 v[10:11], v3, off offset:64
.LBB5_2:
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB5_4
; %bb.3:
	global_store_b32 v1, v2, s[0:1] scale_offset
	s_clause 0x1
	global_store_b32 v0, v3, s[2:3] offset:64 scale_offset
	global_store_b32 v0, v3, s[0:1] offset:64 scale_offset
.LBB5_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	global_store_b32 v[10:11], v4, off offset:128
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB5_6
; %bb.5:
	global_store_b32 v[10:11], v5, off offset:192
.LBB5_6:
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB5_8
; %bb.7:
	global_store_b32 v1, v4, s[0:1] offset:128 scale_offset
	s_clause 0x1
	global_store_b32 v0, v5, s[2:3] offset:192 scale_offset
	global_store_b32 v0, v5, s[0:1] offset:192 scale_offset
.LBB5_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	global_store_b32 v[10:11], v6, off offset:256
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB5_10
; %bb.9:
	global_store_b32 v[10:11], v7, off offset:320
.LBB5_10:
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB5_12
; %bb.11:
	global_store_b32 v1, v6, s[0:1] offset:256 scale_offset
	s_clause 0x1
	global_store_b32 v0, v7, s[2:3] offset:320 scale_offset
	global_store_b32 v0, v7, s[0:1] offset:320 scale_offset
.LBB5_12:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	global_store_b32 v[10:11], v8, off offset:384
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execnz .LBB5_15
; %bb.13:
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execnz .LBB5_16
.LBB5_14:
	s_endpgm
.LBB5_15:
	global_store_b32 v[10:11], v9, off offset:448
                                        ; implicit-def: $vgpr1
                                        ; implicit-def: $vgpr2_vgpr3_vgpr4_vgpr5_vgpr6_vgpr7_vgpr8_vgpr9
                                        ; implicit-def: $vgpr0
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB5_14
.LBB5_16:
	global_store_b32 v1, v8, s[0:1] offset:384 scale_offset
	s_clause 0x1
	global_store_b32 v0, v9, s[2:3] offset:448 scale_offset
	global_store_b32 v0, v9, s[0:1] offset:448 scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_raw_accumulator
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
		.amdhsa_next_free_vgpr 36
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
.Lfunc_end5:
	.size	matrix_raw_accumulator, .Lfunc_end5-matrix_raw_accumulator
                                        ; -- End function
	.set matrix_raw_accumulator.num_vgpr, 36
	.set matrix_raw_accumulator.num_agpr, 0
	.set matrix_raw_accumulator.numbered_sgpr, 12
	.set matrix_raw_accumulator.num_named_barrier, 0
	.set matrix_raw_accumulator.private_seg_size, 0
	.set matrix_raw_accumulator.uses_vcc, 1
	.set matrix_raw_accumulator.uses_flat_scratch, 0
	.set matrix_raw_accumulator.has_dyn_sized_stack, 0
	.set matrix_raw_accumulator.has_recursion, 0
	.set matrix_raw_accumulator.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 632
; TotalNumSgprs: 14
; NumVgprs: 36
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 36
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
	.protected	matrix_immediate_accumulator ; -- Begin function matrix_immediate_accumulator
	.globl	matrix_immediate_accumulator
	.p2align	8
	.type	matrix_immediate_accumulator,@function
matrix_immediate_accumulator:           ; @matrix_immediate_accumulator
; %bb.0:
	v_and_b32_e32 v1, 3, v0
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, 0
	v_lshlrev_b32_e32 v10, 3, v0
	s_mov_b32 s10, s4
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	v_and_b32_e32 v1, 15, v0
	s_mov_b32 s11, s4
	s_mov_b32 s5, s4
	s_mov_b32 s6, s4
	v_cndmask_b32_e64 v2, 0, 1.0, vcc_lo
	v_and_or_b32 v1, 0x80, v10, v1
	s_mov_b32 s7, s4
	s_mov_b32 s8, s4
	s_mov_b32 s9, s4
	v_mov_b64_e32 v[16:17], s[10:11]
	v_mov_b64_e32 v[14:15], s[8:9]
	v_mov_b64_e32 v[12:13], s[6:7]
	v_mov_b64_e32 v[10:11], s[4:5]
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_dual_mov_b32 v9, v2 :: v_dual_mov_b32 v35, 0
	v_lshlrev_b32_e32 v34, 2, v1
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x32_f16 v[2:9], v[10:17], v[10:17], v[2:9]
	v_cmp_lt_u32_e32 vcc_lo, 15, v0
	s_wait_kmcnt 0x0
	v_nop
	v_nop
	v_nop
	v_add_nc_u64_e32 v[10:11], s[2:3], v[34:35]
	v_mov_b64_e32 v[24:25], s[10:11]
	v_mov_b64_e32 v[32:33], s[10:11]
	v_mov_b64_e32 v[22:23], s[8:9]
	v_mov_b64_e32 v[20:21], s[6:7]
	v_mov_b64_e32 v[18:19], s[4:5]
	v_mov_b64_e32 v[30:31], s[8:9]
	v_mov_b64_e32 v[28:29], s[6:7]
	v_mov_b64_e32 v[26:27], s[4:5]
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	global_store_b32 v1, v2, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB6_2
; %bb.1:
	global_store_b32 v[10:11], v3, off offset:64
.LBB6_2:
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB6_4
; %bb.3:
	global_store_b32 v1, v2, s[0:1] scale_offset
	s_clause 0x1
	global_store_b32 v0, v3, s[2:3] offset:64 scale_offset
	global_store_b32 v0, v3, s[0:1] offset:64 scale_offset
.LBB6_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	global_store_b32 v[10:11], v4, off offset:128
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB6_6
; %bb.5:
	global_store_b32 v[10:11], v5, off offset:192
.LBB6_6:
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB6_8
; %bb.7:
	global_store_b32 v1, v4, s[0:1] offset:128 scale_offset
	s_clause 0x1
	global_store_b32 v0, v5, s[2:3] offset:192 scale_offset
	global_store_b32 v0, v5, s[0:1] offset:192 scale_offset
.LBB6_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	global_store_b32 v[10:11], v6, off offset:256
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execz .LBB6_10
; %bb.9:
	global_store_b32 v[10:11], v7, off offset:320
.LBB6_10:
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB6_12
; %bb.11:
	global_store_b32 v1, v6, s[0:1] offset:256 scale_offset
	s_clause 0x1
	global_store_b32 v0, v7, s[2:3] offset:320 scale_offset
	global_store_b32 v0, v7, s[0:1] offset:320 scale_offset
.LBB6_12:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	global_store_b32 v[10:11], v8, off offset:384
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execnz .LBB6_15
; %bb.13:
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execnz .LBB6_16
.LBB6_14:
	s_endpgm
.LBB6_15:
	global_store_b32 v[10:11], v9, off offset:448
                                        ; implicit-def: $vgpr1
                                        ; implicit-def: $vgpr2_vgpr3_vgpr4_vgpr5_vgpr6_vgpr7_vgpr8_vgpr9
                                        ; implicit-def: $vgpr0
	s_wait_xcnt 0x0
	s_and_not1_saveexec_b32 s4, s4
	s_cbranch_execz .LBB6_14
.LBB6_16:
	global_store_b32 v1, v8, s[0:1] offset:384 scale_offset
	s_clause 0x1
	global_store_b32 v0, v9, s[2:3] offset:448 scale_offset
	global_store_b32 v0, v9, s[0:1] offset:448 scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_immediate_accumulator
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
		.amdhsa_next_free_vgpr 36
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
.Lfunc_end6:
	.size	matrix_immediate_accumulator, .Lfunc_end6-matrix_immediate_accumulator
                                        ; -- End function
	.set matrix_immediate_accumulator.num_vgpr, 36
	.set matrix_immediate_accumulator.num_agpr, 0
	.set matrix_immediate_accumulator.numbered_sgpr, 12
	.set matrix_immediate_accumulator.num_named_barrier, 0
	.set matrix_immediate_accumulator.private_seg_size, 0
	.set matrix_immediate_accumulator.uses_vcc, 1
	.set matrix_immediate_accumulator.uses_flat_scratch, 0
	.set matrix_immediate_accumulator.has_dyn_sized_stack, 0
	.set matrix_immediate_accumulator.has_recursion, 0
	.set matrix_immediate_accumulator.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 624
; TotalNumSgprs: 14
; NumVgprs: 36
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 36
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
	.protected	matrix_four_fragment_pairs ; -- Begin function matrix_four_fragment_pairs
	.globl	matrix_four_fragment_pairs
	.p2align	8
	.type	matrix_four_fragment_pairs,@function
matrix_four_fragment_pairs:             ; @matrix_four_fragment_pairs
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB7_9
; %bb.1:
	s_wait_kmcnt 0x0
	global_load_u16 v1, v0, s[0:1] scale_offset
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s7 :: v_dual_lshlrev_b32 v2, 1, v0
	v_cmp_gt_u32_e32 vcc_lo, 0xe0, v0
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB7_9
; %bb.2:
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v6, 64, v2 bitop3:0x54
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mov_b32_e32 v7, s7
	v_add_nc_u64_e32 v[4:5], s[0:1], v[2:3]
	s_mov_b32 s0, exec_lo
	global_load_u16 v1, v[4:5], off offset:64
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB7_9
; %bb.3:
	global_load_u16 v1, v[4:5], off offset:128
	s_mov_b64 s[0:1], src_shared_base
	v_or_b32_e32 v6, 0x80, v2
	v_mov_b32_e32 v7, s1
	s_mov_b32 s0, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0xa0, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB7_9
; %bb.4:
	global_load_u16 v1, v[4:5], off offset:192
	s_mov_b64 s[0:1], src_shared_base
	v_or_b32_e32 v6, 0xc0, v2
	v_mov_b32_e32 v7, s1
	s_mov_b32 s0, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB7_9
; %bb.5:
	global_load_u16 v1, v[4:5], off offset:256
	s_mov_b64 s[0:1], src_shared_base
	v_or_b32_e32 v6, 0x100, v2
	v_mov_b32_e32 v7, s1
	s_mov_b32 s0, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x60, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB7_9
; %bb.6:
	global_load_u16 v1, v[4:5], off offset:320
	s_mov_b64 s[0:1], src_shared_base
	v_or_b32_e32 v6, 0x140, v2
	v_mov_b32_e32 v7, s1
	s_mov_b32 s0, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB7_9
; %bb.7:
	global_load_u16 v1, v[4:5], off offset:384
	s_mov_b64 s[0:1], src_shared_base
	v_or_b32_e32 v6, 0x180, v2
	v_mov_b32_e32 v7, s1
	s_mov_b32 s0, exec_lo
	s_wait_loadcnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 32, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB7_9
; %bb.8:
	global_load_u16 v1, v[4:5], off offset:448
	s_mov_b64 s[0:1], src_shared_base
	v_or_b32_e32 v2, 0x1c0, v2
	v_mov_b32_e32 v3, s1
	s_wait_loadcnt 0x0
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB7_9:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_kmcnt 0x0
	s_mov_b64 s[0:1], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v3, s1 :: v_dual_lshlrev_b32 v2, 2, v0
	s_wait_dscnt 0x0
	; wave barrier
	v_dual_lshlrev_b32 v5, 4, v0 :: v_dual_bitop2_b32 v0, 2, v2 bitop3:0x54
	flat_load_u16 v4, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_mov_b32_e32 v1, s1
	s_wait_dscnt 0x0
	global_store_b16 v5, v4, s[2:3]
	flat_load_u16 v4, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v0, 0x80, v2
	s_wait_dscnt 0x0
	global_store_b16 v5, v4, s[2:3] offset:2
	flat_load_u16 v4, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v0, 0x82, v2
	s_wait_dscnt 0x0
	global_store_b16 v5, v4, s[2:3] offset:4
	flat_load_u16 v4, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v0, 0x100, v2
	s_wait_dscnt 0x0
	global_store_b16 v5, v4, s[2:3] offset:6
	flat_load_u16 v4, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v0, 0x102, v2
	s_wait_dscnt 0x0
	global_store_b16 v5, v4, s[2:3] offset:8
	flat_load_u16 v4, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v0, 0x180, v2
	v_or_b32_e32 v2, 0x182, v2
	s_wait_dscnt 0x0
	global_store_b16 v5, v4, s[2:3] offset:10
	flat_load_u16 v0, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b16 v5, v0, s[2:3] offset:12
	flat_load_u16 v0, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b16 v5, v0, s[2:3] offset:14
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_four_fragment_pairs
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
		.amdhsa_next_free_vgpr 8
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
.Lfunc_end7:
	.size	matrix_four_fragment_pairs, .Lfunc_end7-matrix_four_fragment_pairs
                                        ; -- End function
	.set matrix_four_fragment_pairs.num_vgpr, 8
	.set matrix_four_fragment_pairs.num_agpr, 0
	.set matrix_four_fragment_pairs.numbered_sgpr, 8
	.set matrix_four_fragment_pairs.num_named_barrier, 0
	.set matrix_four_fragment_pairs.private_seg_size, 0
	.set matrix_four_fragment_pairs.uses_vcc, 1
	.set matrix_four_fragment_pairs.uses_flat_scratch, 0
	.set matrix_four_fragment_pairs.has_dyn_sized_stack, 0
	.set matrix_four_fragment_pairs.has_recursion, 0
	.set matrix_four_fragment_pairs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 948
; TotalNumSgprs: 10
; NumVgprs: 8
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 512 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 8
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
	.protected	matrix_lane_word_placement ; -- Begin function matrix_lane_word_placement
	.globl	matrix_lane_word_placement
	.p2align	8
	.type	matrix_lane_word_placement,@function
matrix_lane_word_placement:             ; @matrix_lane_word_placement
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	v_add_nc_u32_e32 v1, 0x3e8, v0
	v_dual_mov_b32 v3, s3 :: v_dual_lshlrev_b32 v2, 2, v0
	s_load_b64 s[0:1], s[0:1], 0x0
	s_mov_b32 s2, exec_lo
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	; wave barrier
	s_wait_storecnt_dscnt 0x0
	flat_load_b32 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] offset:4 scale_offset
	s_wait_xcnt 0x0
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB8_2
; %bb.1:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 20
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[0:1]
.LBB8_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_lane_word_placement
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
	.size	matrix_lane_word_placement, .Lfunc_end8-matrix_lane_word_placement
                                        ; -- End function
	.set matrix_lane_word_placement.num_vgpr, 4
	.set matrix_lane_word_placement.num_agpr, 0
	.set matrix_lane_word_placement.numbered_sgpr, 4
	.set matrix_lane_word_placement.num_named_barrier, 0
	.set matrix_lane_word_placement.private_seg_size, 0
	.set matrix_lane_word_placement.uses_vcc, 0
	.set matrix_lane_word_placement.uses_flat_scratch, 0
	.set matrix_lane_word_placement.has_dyn_sized_stack, 0
	.set matrix_lane_word_placement.has_recursion, 0
	.set matrix_lane_word_placement.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 136
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_1adef91fb09170f7,@object ; @__hip_cuid_1adef91fb09170f7
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_1adef91fb09170f7
__hip_cuid_1adef91fb09170f7:
	.byte	0                               ; 0x0
	.size	__hip_cuid_1adef91fb09170f7, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_1adef91fb09170f7
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
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 544
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_stride32
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         matrix_stride32.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     30
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
    .group_segment_fixed_size: 800
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_stride48
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         matrix_stride48.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     31
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
    .group_segment_fixed_size: 1056
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_stride64
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         matrix_stride64.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     31
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
    .group_segment_fixed_size: 672
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_stride40
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         matrix_stride40.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     31
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
    .group_segment_fixed_size: 288
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_stride16
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         matrix_stride16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     29
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
    .max_flat_workgroup_size: 32
    .name:           matrix_raw_accumulator
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         matrix_raw_accumulator.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     36
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
    .max_flat_workgroup_size: 32
    .name:           matrix_immediate_accumulator
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         matrix_immediate_accumulator.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     36
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
    .group_segment_fixed_size: 512
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_four_fragment_pairs
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matrix_four_fragment_pairs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
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
    .max_flat_workgroup_size: 32
    .name:           matrix_lane_word_placement
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         matrix_lane_word_placement.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
