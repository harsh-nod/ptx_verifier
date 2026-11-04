	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	convolution_f16         ; -- Begin function convolution_f16
	.globl	convolution_f16
	.p2align	8
	.type	convolution_f16,@function
convolution_f16:                        ; @convolution_f16
; %bb.0:                                ; %entry
	v_lshrrev_b32_e32 v1, 6, v0
	v_xor_b32_e32 v8, 1, v1
	s_lshl_b32 s2, s2, 5
	v_lshlrev_b32_e32 v2, 4, v8
	v_bfe_u32 v9, v0, 2, 4
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	v_or3_b32 v2, v2, s2, v9
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v3, v2, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_u32_u24_e32 v4, 0xb64, v3
	v_sub_u32_e32 v2, v2, v4
	v_lshrrev_b16_e32 v4, 1, v2
	v_lshlrev_b32_e32 v12, 2, v0
	v_mul_u32_u24_e32 v4, 0x97b5, v4
	v_and_b32_e32 v10, 12, v12
	v_lshrrev_b32_e32 v13, 20, v4
	v_mul_lo_u16_e32 v4, 54, v13
	v_cmp_lt_u32_e32 vcc, 8, v10
	v_sub_u16_e32 v14, v2, v4
	v_lshlrev_b32_e32 v15, 6, v3
	v_cndmask_b32_e64 v2, 0, 1, vcc
	v_add_u16_e32 v3, -9, v10
	v_cmp_gt_u32_e32 vcc, 9, v10
	s_movk_i32 s0, 0xab
	v_or_b32_e32 v2, v15, v2
	v_cndmask_b32_e32 v3, v3, v10, vcc
	v_mul_lo_u16_sdwa v5, v3, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v5, 9, v5
	v_add_u32_e32 v6, v13, v5
	v_mul_lo_u16_e32 v5, 3, v5
	v_sub_u16_e32 v3, v3, v5
	s_movk_i32 s11, 0xc40
	v_mul_lo_u32 v2, v2, s11
	v_mul_u32_u24_e32 v5, 56, v6
	v_add_u32_sdwa v3, v14, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	s_lshl_b32 s10, s3, 4
	v_add3_u32 v6, v3, v2, v5
	v_mov_b32_e32 v7, 0
	v_or_b32_e32 v4, s10, v10
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[4:5]
	s_movk_i32 s1, 0x240
	global_load_ushort v11, v[2:3], off
	v_mul_lo_u32 v2, v4, s1
	v_or_b32_e32 v6, v2, v9
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[6:7]
	global_load_ushort v17, v[2:3], off
	v_or_b32_e32 v2, 1, v10
	v_cmp_lt_u32_e32 vcc, 7, v10
	v_add_u16_e32 v4, -9, v2
	s_mov_b32 s12, 0x5040100
	v_cndmask_b32_e64 v3, 0, 1, vcc
	v_cmp_gt_u32_e32 vcc, 9, v2
	v_or_b32_e32 v3, v15, v3
	v_mul_lo_u32 v3, v3, s11
	v_cndmask_b32_e32 v2, v4, v2, vcc
	v_mul_lo_u16_sdwa v4, v2, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v4, 9, v4
	v_add_u32_e32 v5, v13, v4
	v_mul_lo_u16_e32 v4, 3, v4
	v_sub_u16_e32 v2, v2, v4
	v_and_b32_e32 v2, 0xff, v2
	v_mul_u32_u24_e32 v4, 56, v5
	v_or_b32_e32 v5, v3, v14
	v_add3_u32 v2, v5, v2, v4
	v_or_b32_e32 v4, 2, v10
	v_add_u16_e32 v16, -9, v4
	v_cmp_gt_u32_e32 vcc, 9, v4
	v_mov_b32_e32 v3, v7
	v_lshl_add_u64 v[2:3], v[2:3], 1, s[4:5]
	v_cndmask_b32_e32 v4, v16, v4, vcc
	v_mul_lo_u16_sdwa v16, v4, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v16, 9, v16
	v_add_u32_e32 v19, v13, v16
	v_mul_lo_u16_e32 v16, 3, v16
	v_sub_u16_e32 v4, v4, v16
	v_and_b32_e32 v4, 0xff, v4
	v_mul_u32_u24_e32 v16, 56, v19
	v_add3_u32 v4, v5, v4, v16
	v_mov_b32_e32 v5, v7
	v_lshl_add_u64 v[4:5], v[4:5], 1, s[4:5]
	global_load_ushort v18, v[2:3], off
	global_load_ushort v19, v[4:5], off
	v_add_u32_e32 v4, 0x480, v6
	v_mov_b32_e32 v5, v7
	v_lshl_add_u64 v[4:5], v[4:5], 1, s[6:7]
	global_load_ushort v20, v[4:5], off
	v_or_b32_e32 v4, 3, v10
	v_cmp_lt_u32_e32 vcc, 8, v4
	v_add_u16_e32 v16, -9, v4
	v_add_u32_e32 v2, 0x240, v6
	v_cndmask_b32_e64 v5, 0, 1, vcc
	v_cmp_gt_u32_e32 vcc, 9, v4
	v_or_b32_e32 v5, v15, v5
	v_mul_lo_u32 v5, v5, s11
	v_cndmask_b32_e32 v4, v16, v4, vcc
	v_mul_lo_u16_sdwa v16, v4, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v16, 9, v16
	v_add_u32_e32 v21, v13, v16
	v_mul_lo_u16_e32 v16, 3, v16
	v_sub_u16_e32 v4, v4, v16
	v_mul_u32_u24_e32 v16, 56, v21
	v_add_u32_sdwa v4, v14, v4 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v4, v4, v5, v16
	v_mov_b32_e32 v5, v7
	v_lshl_add_u64 v[4:5], v[4:5], 1, s[4:5]
	v_add_u32_e32 v6, 0x6c0, v6
	v_mov_b32_e32 v3, v7
	global_load_ushort v21, v[4:5], off
	v_lshl_add_u64 v[4:5], v[6:7], 1, s[6:7]
	v_lshl_add_u64 v[2:3], v[2:3], 1, s[6:7]
	global_load_ushort v6, v[4:5], off
	global_load_ushort v22, v[2:3], off
	v_lshlrev_b32_e32 v16, 3, v0
	s_movk_i32 s0, 0x800
	s_mulk_i32 s3, 0x2400
	v_accvgpr_write_b32 a3, 0
	v_accvgpr_write_b32 a2, 0
	v_accvgpr_write_b32 a1, 0
	v_accvgpr_write_b32 a0, 0
	s_mov_b32 s13, 0xe38f
	s_mov_b32 s14, 0
	s_waitcnt vmcnt(5)
	v_perm_b32 v2, v18, v11, s12
	s_waitcnt vmcnt(2)
	v_perm_b32 v3, v21, v19, s12
	v_or_b32_e32 v21, 16, v10
	s_waitcnt vmcnt(1)
	v_perm_b32 v5, v6, v20, s12
	s_waitcnt vmcnt(0)
	v_perm_b32 v4, v22, v17, s12
	ds_write2st64_b64 v16, v[2:3], v[4:5] offset1:4
	v_and_b32_e32 v17, 15, v0
	v_bfe_u32 v2, v0, 4, 2
	v_lshlrev_b32_e32 v3, 5, v17
	v_lshlrev_b32_e32 v4, 3, v2
	v_lshlrev_b32_e32 v5, 9, v8
	v_or3_b32 v18, v3, v4, v5
	v_lshl_or_b32 v2, v2, 7, v5
	v_lshlrev_b32_e32 v3, 1, v17
	v_or3_b32 v19, v2, v3, s0
	v_or_b32_e32 v2, s3, v9
	v_and_b32_e32 v3, 3, v0
	s_movk_i32 s0, 0x900
	v_mad_u32_u24 v20, v3, s0, v2
	s_mov_b32 s3, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
                                        ; implicit-def: $vgpr8
                                        ; implicit-def: $vgpr10
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end122.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_addk_i32 s14, 0x200
	s_add_i32 s3, s3, 16
	s_cmpk_lg_i32 s3, 0x240
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc0 .LBB0_6
.LBB0_2:                                ; %for.body28.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lg_i32 s3, 0x230
	s_cselect_b64 s[0:1], -1, 0
	s_cmpk_eq_i32 s3, 0x230
	s_cbranch_scc1 .LBB0_4
; %bb.3:                                ; %for.cond32.preheader.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_add_u32_e32 v4, s3, v21
	v_mul_u32_u24_sdwa v2, v4, s13 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v2, 19, v2
	v_mul_lo_u16_e32 v3, 9, v2
	v_sub_u16_e32 v3, v4, v3
	v_mul_lo_u16_e32 v5, 0xab, v3
	v_lshrrev_b16_e32 v5, 9, v5
	v_add_u32_e32 v6, v5, v13
	v_mul_lo_u16_e32 v5, 3, v5
	v_sub_u16_e32 v3, v3, v5
	v_add_u32_e32 v2, v15, v2
	v_mul_lo_u32 v2, v2, s11
	v_mul_u32_u24_e32 v5, 56, v6
	v_add_u32_sdwa v3, v3, v14 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v6, v3, v2, v5
	v_add_u32_e32 v5, s3, v20
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[4:5]
	v_add_u32_e32 v6, 16, v5
	global_load_ushort v8, v[2:3], off
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[6:7]
	global_load_ushort v9, v[2:3], off
	v_or_b32_e32 v2, 1, v4
	v_mul_u32_u24_sdwa v3, v2, s13 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v3, 19, v3
	v_mul_lo_u16_e32 v6, 9, v3
	v_sub_u16_e32 v2, v2, v6
	v_mul_lo_u16_e32 v6, 0xab, v2
	v_lshrrev_b16_e32 v6, 9, v6
	v_add_u32_e32 v10, v6, v13
	v_mul_lo_u16_e32 v6, 3, v6
	v_sub_u16_e32 v2, v2, v6
	v_add_u32_e32 v3, v15, v3
	v_mul_lo_u32 v3, v3, s11
	v_mul_u32_u24_e32 v6, 56, v10
	v_add_u32_sdwa v2, v2, v14 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v6, v2, v3, v6
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[4:5]
	v_add_u32_e32 v6, 0x250, v5
	global_load_ushort v10, v[2:3], off
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[6:7]
	global_load_ushort v11, v[2:3], off
	v_or_b32_e32 v2, 2, v4
	v_mul_u32_u24_sdwa v3, v2, s13 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v3, 19, v3
	v_mul_lo_u16_e32 v6, 9, v3
	v_sub_u16_e32 v2, v2, v6
	v_mul_lo_u16_e32 v6, 0xab, v2
	v_lshrrev_b16_e32 v6, 9, v6
	v_add_u32_e32 v22, v6, v13
	v_mul_lo_u16_e32 v6, 3, v6
	v_sub_u16_e32 v2, v2, v6
	v_add_u32_e32 v3, v15, v3
	v_mul_lo_u32 v3, v3, s11
	v_mul_u32_u24_e32 v6, 56, v22
	v_add_u32_sdwa v2, v2, v14 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v6, v2, v3, v6
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[4:5]
	v_add_u32_e32 v6, 0x490, v5
	global_load_ushort v22, v[2:3], off
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[6:7]
	global_load_ushort v23, v[2:3], off
	v_or_b32_e32 v2, 3, v4
	v_mul_u32_u24_sdwa v3, v2, s13 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v3, 19, v3
	v_mul_lo_u16_e32 v4, 9, v3
	v_sub_u16_e32 v2, v2, v4
	v_mul_lo_u16_e32 v4, 0xab, v2
	v_lshrrev_b16_e32 v4, 9, v4
	v_add_u32_e32 v6, v4, v13
	v_mul_lo_u16_e32 v4, 3, v4
	v_sub_u16_e32 v2, v2, v4
	v_add_u32_e32 v3, v15, v3
	v_mul_lo_u32 v3, v3, s11
	v_mul_u32_u24_e32 v4, 56, v6
	v_add_u32_sdwa v2, v2, v14 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v6, v2, v3, v4
	v_lshl_add_u64 v[2:3], v[6:7], 1, s[4:5]
	v_add_u32_e32 v6, 0x6d0, v5
	v_lshl_add_u64 v[4:5], v[6:7], 1, s[6:7]
	global_load_ushort v6, v[4:5], off
	global_load_ushort v24, v[2:3], off
	s_waitcnt vmcnt(5)
	v_perm_b32 v8, v10, v8, s12
	s_waitcnt vmcnt(4)
	v_perm_b32 v10, v11, v9, s12
	s_waitcnt vmcnt(1)
	v_perm_b32 v11, v6, v23, s12
	s_waitcnt vmcnt(0)
	v_perm_b32 v9, v24, v22, s12
.LBB0_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_lshl_b32 s15, s14, 1
	s_and_b32 s15, s15, 0x400
	v_or_b32_e32 v2, s15, v18
	v_add_u32_e32 v4, s15, v19
	ds_read_b64 v[2:3], v2
	ds_read_u16 v6, v4
	ds_read_u16 v5, v4 offset:64
	ds_read_u16 v22, v4 offset:96
	ds_read_u16 v4, v4 offset:32
	s_andn2_b64 vcc, exec, s[0:1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_perm_b32 v5, v22, v5, s12
	v_perm_b32 v4, v4, v6, s12
	s_nop 1
	v_mfma_f32_16x16x16_f16 a[0:3], v[2:3], v[4:5], a[0:3]
	s_cbranch_vccnz .LBB0_1
; %bb.5:                                ; %if.then99.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s0, s14, 0x200
	s_and_b32 s0, s0, 0x200
	v_or_b32_e32 v2, s0, v12
	v_lshl_or_b32 v3, s0, 1, v16
	v_lshlrev_b32_e32 v2, 1, v2
	ds_write_b64 v3, v[8:9]
	ds_write_b64 v2, v[10:11] offset:2048
	s_branch .LBB0_1
.LBB0_6:                                ; %_Z11convolutionILb0EEvPKvS1_PDF16_S2_S2_.exit
	v_lshl_add_u32 v1, v1, 4, s2
	v_lshrrev_b32_e32 v0, 2, v0
	v_and_or_b32 v8, v0, 12, v1
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v1, v8, s0
	v_accvgpr_read_b32 v5, a3
	v_or_b32_e32 v0, s10, v17
	v_lshrrev_b32_e32 v1, 10, v1
	v_accvgpr_read_b32 v2, a0
	v_lshl_add_u32 v0, v1, 7, v0
	s_movk_i32 s1, 0xb64
	v_mul_lo_u32 v9, v0, s1
	v_cvt_f16_f32_e32 v2, v2
	v_mul_u32_u24_e32 v0, 0xb64, v1
	v_sub_u32_e32 v0, v8, v0
	v_add_u32_e32 v0, v9, v0
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[6:7], v[0:1], 1, s[8:9]
	v_or_b32_e32 v0, 1, v8
	global_store_short v[6:7], v2, off
	v_mul_hi_u32 v2, v0, s0
	v_accvgpr_read_b32 v3, a1
	v_lshrrev_b32_e32 v2, 10, v2
	v_cvt_f16_f32_e32 v6, v3
	v_mul_u32_u24_e32 v2, 0xb64, v2
	v_sub_u32_e32 v0, v0, v2
	v_add_u32_e32 v0, v9, v0
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_or_b32_e32 v0, 2, v8
	global_store_short v[2:3], v6, off
	v_mul_hi_u32 v2, v0, s0
	v_accvgpr_read_b32 v4, a2
	v_lshrrev_b32_e32 v2, 10, v2
	v_cvt_f16_f32_e32 v4, v4
	v_mul_u32_u24_e32 v2, 0xb64, v2
	v_sub_u32_e32 v0, v0, v2
	v_add_u32_e32 v0, v9, v0
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_or_b32_e32 v0, 3, v8
	global_store_short v[2:3], v4, off
	v_mul_hi_u32 v3, v0, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_cvt_f16_f32_e32 v2, v5
	v_mul_u32_u24_e32 v3, 0xb64, v3
	v_sub_u32_e32 v0, v0, v3
	v_add_u32_e32 v0, v9, v0
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[8:9]
	global_store_short v[0:1], v2, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel convolution_f16
		.amdhsa_group_segment_fixed_size 4096
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 32
		.amdhsa_next_free_sgpr 16
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
.Lfunc_end0:
	.size	convolution_f16, .Lfunc_end0-convolution_f16
                                        ; -- End function
	.set convolution_f16.num_vgpr, 25
	.set convolution_f16.num_agpr, 4
	.set convolution_f16.numbered_sgpr, 16
	.set convolution_f16.num_named_barrier, 0
	.set convolution_f16.private_seg_size, 0
	.set convolution_f16.uses_vcc, 1
	.set convolution_f16.uses_flat_scratch, 0
	.set convolution_f16.has_dyn_sized_stack, 0
	.set convolution_f16.has_recursion, 0
	.set convolution_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1872
; TotalNumSgprs: 22
; NumVgprs: 25
; NumAgprs: 4
; TotalNumVgprs: 32
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 32
; AccumOffset: 28
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 6
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	convolution_f8          ; -- Begin function convolution_f8
	.globl	convolution_f8
	.p2align	8
	.type	convolution_f8,@function
convolution_f8:                         ; @convolution_f8
; %bb.0:                                ; %entry
	v_lshrrev_b32_e32 v1, 6, v0
	v_xor_b32_e32 v6, 1, v1
	s_lshl_b32 s2, s2, 5
	v_lshlrev_b32_e32 v2, 4, v6
	v_bfe_u32 v7, v0, 2, 4
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	v_or3_b32 v2, v2, s2, v7
	v_lshlrev_b32_e32 v3, 2, v0
	s_mov_b32 s0, 0x59e60383
	v_and_b32_e32 v8, 12, v3
	v_mul_hi_u32 v3, v2, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_u32_u24_e32 v4, 0xb64, v3
	v_sub_u32_e32 v2, v2, v4
	v_lshrrev_b16_e32 v4, 1, v2
	v_mul_u32_u24_e32 v4, 0x97b5, v4
	v_lshrrev_b32_e32 v10, 20, v4
	v_mul_lo_u16_e32 v4, 54, v10
	v_cmp_lt_u32_e32 vcc, 8, v8
	v_sub_u16_e32 v11, v2, v4
	v_lshlrev_b32_e32 v12, 6, v3
	v_cndmask_b32_e64 v3, 0, 1, vcc
	v_add_u16_e32 v4, -9, v8
	v_cmp_gt_u32_e32 vcc, 9, v8
	s_movk_i32 s0, 0xab
	v_or_b32_e32 v3, v12, v3
	v_cndmask_b32_e32 v4, v4, v8, vcc
	v_mul_lo_u16_sdwa v5, v4, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v5, 9, v5
	v_add_u32_e32 v9, v10, v5
	v_mul_lo_u16_e32 v5, 3, v5
	v_sub_u16_e32 v4, v4, v5
	s_movk_i32 s11, 0xc40
	v_mul_lo_u32 v3, v3, s11
	v_mul_u32_u24_e32 v5, 56, v9
	v_add_u32_sdwa v4, v11, v4 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v3, v4, v3, v5
	v_or_b32_e32 v5, 1, v8
	v_cmp_lt_u32_e32 vcc, 7, v8
	v_add_u16_e32 v13, -9, v5
	s_lshl_b32 s10, s3, 4
	v_cndmask_b32_e64 v9, 0, 1, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_or_b32_e32 v2, s10, v8
	s_movk_i32 s1, 0x240
	v_cndmask_b32_e32 v5, v13, v5, vcc
	v_mul_lo_u16_sdwa v13, v5, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v13, 9, v13
	v_add_u32_e32 v14, v10, v13
	v_mul_lo_u16_e32 v13, 3, v13
	v_sub_u16_e32 v5, v5, v13
	v_mul_u32_u24_e32 v13, 56, v14
	v_or_b32_e32 v14, 2, v8
	v_add_u16_e32 v15, -9, v14
	v_cmp_gt_u32_e32 vcc, 9, v14
	v_or_b32_e32 v9, v12, v9
	v_mul_lo_u32 v2, v2, s1
	v_cndmask_b32_e32 v14, v15, v14, vcc
	v_mul_lo_u16_sdwa v15, v14, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v15, 9, v15
	v_add_u32_e32 v16, v10, v15
	v_mul_lo_u16_e32 v15, 3, v15
	v_mul_lo_u32 v9, v9, s11
	v_sub_u16_e32 v14, v14, v15
	v_or_b32_e32 v2, v2, v7
	v_and_b32_e32 v5, 0xff, v5
	v_or_b32_e32 v9, v9, v11
	v_and_b32_e32 v14, 0xff, v14
	v_mul_u32_u24_e32 v15, 56, v16
	v_add3_u32 v5, v9, v5, v13
	v_add3_u32 v9, v9, v14, v15
	v_add_u32_e32 v14, 0x480, v2
	s_waitcnt lgkmcnt(0)
	global_load_ubyte v15, v14, s[6:7]
	v_or_b32_e32 v14, 3, v8
	v_cmp_lt_u32_e32 vcc, 8, v14
	v_add_u16_e32 v17, -9, v14
	global_load_ubyte v4, v2, s[6:7]
	v_cndmask_b32_e64 v16, 0, 1, vcc
	v_cmp_gt_u32_e32 vcc, 9, v14
	v_or_b32_e32 v16, v12, v16
	v_mul_lo_u32 v16, v16, s11
	v_cndmask_b32_e32 v14, v17, v14, vcc
	v_mul_lo_u16_sdwa v17, v14, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v17, 9, v17
	v_add_u32_e32 v18, v10, v17
	v_mul_lo_u16_e32 v17, 3, v17
	v_sub_u16_e32 v14, v14, v17
	v_mul_u32_u24_e32 v17, 56, v18
	v_add_u32_sdwa v14, v11, v14 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add_u32_e32 v13, 0x240, v2
	v_add3_u32 v14, v14, v16, v17
	v_add_u32_e32 v2, 0x6c0, v2
	global_load_ubyte v3, v3, s[4:5]
	s_movk_i32 s0, 0x800
	global_load_ubyte v5, v5, s[4:5]
	s_mulk_i32 s3, 0x2400
	global_load_ubyte v9, v9, s[4:5]
	v_or_b32_e32 v19, 16, v8
	global_load_ubyte v16, v14, s[4:5]
	global_load_ubyte v17, v2, s[6:7]
	global_load_ubyte v18, v13, s[6:7]
	v_lshlrev_b32_e32 v13, 3, v0
	v_or_b32_e32 v14, 0x800, v13
	v_accvgpr_write_b32 a3, 0
	v_accvgpr_write_b32 a2, 0
	v_accvgpr_write_b32 a1, 0
	v_accvgpr_write_b32 a0, 0
	s_mov_b32 s12, 0xe38f
	s_mov_b32 s13, 0x5040100
	s_mov_b32 s14, 0
	s_waitcnt vmcnt(7)
	v_cvt_f32_fp8_e32 v15, v15
	s_waitcnt vmcnt(6)
	v_cvt_f32_fp8_e32 v4, v4
	s_waitcnt vmcnt(5)
	v_cvt_f32_fp8_e32 v2, v3
	s_waitcnt vmcnt(4)
	v_cvt_f32_fp8_e32 v5, v5
	s_waitcnt vmcnt(3)
	v_cvt_f32_fp8_e32 v3, v9
	s_waitcnt vmcnt(2)
	v_cvt_f32_fp8_e32 v9, v16
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v16, v17
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v17, v18
	v_cvt_pk_f16_f32 v2, v2, v5
	v_cvt_pk_f16_f32 v3, v3, v9
	v_cvt_pk_f16_f32 v5, v15, v16
	v_cvt_pk_f16_f32 v4, v4, v17
	ds_write2st64_b64 v13, v[2:3], v[4:5] offset1:4
	v_and_b32_e32 v15, 15, v0
	v_bfe_u32 v2, v0, 4, 2
	v_lshlrev_b32_e32 v3, 5, v15
	v_lshlrev_b32_e32 v4, 3, v2
	v_lshlrev_b32_e32 v5, 9, v6
	v_or3_b32 v16, v3, v4, v5
	v_lshl_or_b32 v2, v2, 7, v5
	v_lshlrev_b32_e32 v3, 1, v15
	v_or3_b32 v17, v2, v3, s0
	v_or_b32_e32 v2, s3, v7
	v_and_b32_e32 v3, 3, v0
	s_movk_i32 s0, 0x900
	v_mad_u32_u24 v18, v3, s0, v2
	s_mov_b32 s3, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
                                        ; implicit-def: $vgpr8
                                        ; implicit-def: $vgpr6
	s_branch .LBB1_2
.LBB1_1:                                ; %if.end122.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_addk_i32 s14, 0x200
	s_add_i32 s3, s3, 16
	s_cmpk_lg_i32 s3, 0x240
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc0 .LBB1_6
.LBB1_2:                                ; %for.body28.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lg_i32 s3, 0x230
	s_cselect_b64 s[0:1], -1, 0
	s_cmpk_eq_i32 s3, 0x230
	s_cbranch_scc1 .LBB1_4
; %bb.3:                                ; %for.cond32.preheader.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	v_add_u32_e32 v2, s3, v19
	v_mul_u32_u24_sdwa v3, v2, s12 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v3, 19, v3
	v_mul_lo_u16_e32 v4, 9, v3
	v_sub_u16_e32 v4, v2, v4
	v_mul_lo_u16_e32 v5, 0xab, v4
	v_lshrrev_b16_e32 v5, 9, v5
	v_add_u32_e32 v6, v5, v10
	v_mul_lo_u16_e32 v5, 3, v5
	v_sub_u16_e32 v4, v4, v5
	v_mul_u32_u24_e32 v5, 56, v6
	v_or_b32_e32 v6, 1, v2
	v_mul_u32_u24_sdwa v7, v6, s12 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v7, 19, v7
	v_mul_lo_u16_e32 v8, 9, v7
	v_sub_u16_e32 v6, v6, v8
	v_mul_lo_u16_e32 v8, 0xab, v6
	v_lshrrev_b16_e32 v8, 9, v8
	v_add_u32_e32 v9, v8, v10
	v_mul_lo_u16_e32 v8, 3, v8
	v_sub_u16_e32 v6, v6, v8
	v_add_u32_e32 v7, v12, v7
	v_mul_lo_u32 v7, v7, s11
	v_mul_u32_u24_e32 v8, 56, v9
	v_add_u32_sdwa v6, v6, v11 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v6, v6, v7, v8
	v_or_b32_e32 v8, 2, v2
	v_mul_u32_u24_sdwa v9, v8, s12 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v9, 19, v9
	v_mul_lo_u16_e32 v20, 9, v9
	v_sub_u16_e32 v8, v8, v20
	v_mul_lo_u16_e32 v20, 0xab, v8
	v_lshrrev_b16_e32 v20, 9, v20
	v_add_u32_e32 v21, v20, v10
	v_mul_lo_u16_e32 v20, 3, v20
	v_sub_u16_e32 v8, v8, v20
	v_add_u32_e32 v9, v12, v9
	v_mul_lo_u32 v9, v9, s11
	v_mul_u32_u24_e32 v20, 56, v21
	v_add_u32_sdwa v8, v8, v11 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_or_b32_e32 v2, 3, v2
	v_add3_u32 v8, v8, v9, v20
	v_mul_u32_u24_sdwa v20, v2, s12 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v20, 19, v20
	v_mul_lo_u16_e32 v21, 9, v20
	v_sub_u16_e32 v2, v2, v21
	v_mul_lo_u16_e32 v21, 0xab, v2
	v_lshrrev_b16_e32 v21, 9, v21
	v_add_u32_e32 v3, v12, v3
	v_add_u32_e32 v22, v21, v10
	v_mul_lo_u16_e32 v21, 3, v21
	v_mul_lo_u32 v3, v3, s11
	v_add_u32_sdwa v4, v4, v11 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_sub_u16_e32 v2, v2, v21
	v_add_u32_e32 v20, v12, v20
	v_add3_u32 v3, v4, v3, v5
	v_add_u32_e32 v4, s3, v18
	v_mul_lo_u32 v20, v20, s11
	v_mul_u32_u24_e32 v21, 56, v22
	v_add_u32_sdwa v2, v2, v11 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add_u32_e32 v5, 16, v4
	v_add_u32_e32 v7, 0x250, v4
	v_add_u32_e32 v9, 0x490, v4
	v_add_u32_e32 v4, 0x6d0, v4
	v_add3_u32 v2, v2, v20, v21
	global_load_ubyte v3, v3, s[4:5]
	s_nop 0
	global_load_ubyte v2, v2, s[4:5]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v3, v3
	global_load_ubyte v5, v5, s[6:7]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v2, v2
	global_load_ubyte v6, v6, s[4:5]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v20, v6
	global_load_ubyte v7, v7, s[6:7]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v7, v7
	global_load_ubyte v8, v8, s[4:5]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v21, v8
	global_load_ubyte v9, v9, s[6:7]
	v_cvt_pk_f16_f32 v8, v3, v20
	global_load_ubyte v4, v4, s[6:7]
	v_cvt_f32_fp8_e32 v5, v5
	v_cvt_pk_f16_f32 v6, v5, v7
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v9, v9
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v4, v4
	v_cvt_pk_f16_f32 v7, v9, v4
	v_cvt_pk_f16_f32 v9, v21, v2
.LBB1_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_lshl_b32 s15, s14, 1
	s_and_b32 s15, s15, 0x400
	v_or_b32_e32 v2, s15, v16
	v_add_u32_e32 v4, s15, v17
	ds_read_b64 v[2:3], v2
	ds_read_u16 v20, v4
	ds_read_u16 v5, v4 offset:64
	ds_read_u16 v21, v4 offset:96
	ds_read_u16 v4, v4 offset:32
	s_andn2_b64 vcc, exec, s[0:1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_perm_b32 v5, v21, v5, s13
	v_perm_b32 v4, v4, v20, s13
	s_nop 1
	v_mfma_f32_16x16x16_f16 a[0:3], v[2:3], v[4:5], a[0:3]
	s_cbranch_vccnz .LBB1_1
; %bb.5:                                ; %if.then99.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_add_i32 s0, s14, 0x200
	s_and_b32 s0, s0, 0x200
	s_lshl_b32 s0, s0, 1
	v_or_b32_e32 v2, s0, v13
	v_add_u32_e32 v3, s0, v14
	ds_write_b64 v2, v[8:9]
	ds_write_b64 v3, v[6:7]
	s_branch .LBB1_1
.LBB1_6:                                ; %_Z11convolutionILb1EEvPKvS1_PDF16_S2_S2_.exit
	v_lshl_add_u32 v1, v1, 4, s2
	v_lshrrev_b32_e32 v0, 2, v0
	v_and_or_b32 v8, v0, 12, v1
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v1, v8, s0
	v_accvgpr_read_b32 v5, a3
	v_or_b32_e32 v0, s10, v15
	v_lshrrev_b32_e32 v1, 10, v1
	v_accvgpr_read_b32 v2, a0
	v_lshl_add_u32 v0, v1, 7, v0
	s_movk_i32 s1, 0xb64
	v_mul_lo_u32 v9, v0, s1
	v_cvt_f16_f32_e32 v2, v2
	v_mul_u32_u24_e32 v0, 0xb64, v1
	v_sub_u32_e32 v0, v8, v0
	v_add_u32_e32 v0, v9, v0
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[6:7], v[0:1], 1, s[8:9]
	v_or_b32_e32 v0, 1, v8
	global_store_short v[6:7], v2, off
	v_mul_hi_u32 v2, v0, s0
	v_accvgpr_read_b32 v3, a1
	v_lshrrev_b32_e32 v2, 10, v2
	v_cvt_f16_f32_e32 v6, v3
	v_mul_u32_u24_e32 v2, 0xb64, v2
	v_sub_u32_e32 v0, v0, v2
	v_add_u32_e32 v0, v9, v0
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_or_b32_e32 v0, 2, v8
	global_store_short v[2:3], v6, off
	v_mul_hi_u32 v2, v0, s0
	v_accvgpr_read_b32 v4, a2
	v_lshrrev_b32_e32 v2, 10, v2
	v_cvt_f16_f32_e32 v4, v4
	v_mul_u32_u24_e32 v2, 0xb64, v2
	v_sub_u32_e32 v0, v0, v2
	v_add_u32_e32 v0, v9, v0
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_or_b32_e32 v0, 3, v8
	global_store_short v[2:3], v4, off
	v_mul_hi_u32 v3, v0, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_cvt_f16_f32_e32 v2, v5
	v_mul_u32_u24_e32 v3, 0xb64, v3
	v_sub_u32_e32 v0, v0, v3
	v_add_u32_e32 v0, v9, v0
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[8:9]
	global_store_short v[0:1], v2, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel convolution_f8
		.amdhsa_group_segment_fixed_size 4096
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 28
		.amdhsa_next_free_sgpr 16
		.amdhsa_accum_offset 24
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
	.size	convolution_f8, .Lfunc_end1-convolution_f8
                                        ; -- End function
	.set convolution_f8.num_vgpr, 23
	.set convolution_f8.num_agpr, 4
	.set convolution_f8.numbered_sgpr, 16
	.set convolution_f8.num_named_barrier, 0
	.set convolution_f8.private_seg_size, 0
	.set convolution_f8.uses_vcc, 1
	.set convolution_f8.uses_flat_scratch, 0
	.set convolution_f8.has_dyn_sized_stack, 0
	.set convolution_f8.has_recursion, 0
	.set convolution_f8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1820
; TotalNumSgprs: 22
; NumVgprs: 23
; NumAgprs: 4
; TotalNumVgprs: 28
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 28
; AccumOffset: 24
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 5
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_1e03e22f7cd00c3c,@object ; @__hip_cuid_1e03e22f7cd00c3c
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_1e03e22f7cd00c3c
__hip_cuid_1e03e22f7cd00c3c:
	.byte	0                               ; 0x0
	.size	__hip_cuid_1e03e22f7cd00c3c, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_1e03e22f7cd00c3c
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     4
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
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           convolution_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         convolution_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     32
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     4
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
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           convolution_f8
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         convolution_f8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     28
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
