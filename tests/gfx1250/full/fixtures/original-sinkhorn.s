	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	sinkhorn_original       ; -- Begin function sinkhorn_original
	.globl	sinkhorn_original
	.p2align	8
	.type	sinkhorn_original,@function
sinkhorn_original:                      ; @sinkhorn_original
; %bb.0:
	s_load_b512 s[4:19], s[0:1], 0x0
	s_wait_xcnt 0x0
	s_bfe_u32 s0, ttmp6, 0x4000c
	s_and_b32 s1, ttmp6, 15
	s_add_co_i32 s0, s0, 1
	s_getreg_b32 s2, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s0, ttmp9, s0
	v_dual_mov_b32 v5, 0 :: v_dual_lshlrev_b32 v4, 1, v0
	s_add_co_i32 s1, s1, s0
	s_cmp_eq_u32 s2, 0
	v_or_b32_e32 v1, 0xffffff00, v0
	s_cselect_b32 s2, ttmp9, s1
	v_mov_b32_e32 v6, v4
	s_cmp_lt_u32 s2, 32
	s_mov_b32 s3, 0
	s_cselect_b32 s20, -1, 0
	v_mov_b32_e32 v7, v1
	s_and_b32 s0, s20, exec_lo
	s_wait_kmcnt 0x0
	s_cselect_b32 s1, s7, s5
	s_cselect_b32 s0, s6, s4
	s_delay_alu instid0(SALU_CYCLE_1)
	v_add_nc_u64_e32 v[2:3], s[0:1], v[4:5]
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	global_load_u16 v8, v[2:3], off
	v_add_nc_u32_e32 v7, 0x100, v7
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 0x200, v[2:3]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v7
	s_or_b32 s3, vcc_lo, s3
	s_wait_loadcnt 0x0
	ds_store_b16 v6, v8
	v_add_nc_u32_e32 v6, 0x200, v6
	s_and_not1_b32 exec_lo, exec_lo, s3
	s_cbranch_execnz .LBB0_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s3
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_bitop2_b32 v23, 15, v0 bitop3:0x40
	s_lshl_b32 s2, s2, 5
	v_add_nc_u64_e32 v[16:17], s[0:1], v[4:5]
	s_and_b32 s21, s2, 0x3e0
	s_delay_alu instid0(VALU_DEP_2)
	v_and_b32_e32 v22, 0x70, v2
	s_and_b32 s0, s20, exec_lo
	s_cselect_b32 s1, s5, s7
	s_cselect_b32 s0, s4, s6
	v_mbcnt_lo_u32_b32 v24, -1, 0
	v_dual_add_nc_u32 v3, s21, v22 :: v_dual_mov_b32 v9, 0
	v_or_b32_e32 v25, 23, v2
	v_or_b32_e32 v27, 55, v2
	v_add_nc_u64_e32 v[16:17], 0x800, v[16:17]
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v26, 7, v23 :: v_dual_bitop2_b32 v3, v3, v23 bitop3:0x54
	v_dual_mov_b32 v10, v9 :: v_dual_bitop2_b32 v5, 8, v2 bitop3:0x40
	v_dual_mov_b32 v11, v9 :: v_dual_lshlrev_b32 v3, 6, v3
	v_dual_mov_b32 v7, v9 :: v_dual_mov_b32 v35, v9
	v_dual_mov_b32 v34, v9 :: v_dual_mov_b32 v33, v9
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_mov_b32 v32, v9 :: v_dual_bitop2_b32 v18, v27, v3 bitop3:0x54
	v_or_b32_e32 v2, v25, v3
	v_or_b32_e32 v6, v5, v3
	v_dual_mov_b32 v30, v9 :: v_dual_mov_b32 v29, v9
	v_mov_b32_e32 v28, v9
	s_cselect_b32 s3, s15, s13
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v8, 1, v6 :: v_dual_mov_b32 v6, v9
	v_mov_b32_e32 v3, v9
	s_cselect_b32 s2, s14, s12
	s_cselect_b32 s5, s11, s9
	v_add_nc_u64_e32 v[12:13], s[0:1], v[8:9]
	v_dual_lshlrev_b32 v8, 1, v2 :: v_dual_mov_b32 v2, v9
	s_cselect_b32 s4, s10, s8
	s_mov_b32 s6, -1
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_add_nc_u64_e32 v[14:15], s[0:1], v[8:9]
	v_dual_mov_b32 v31, v9 :: v_dual_lshlrev_b32 v8, 1, v18
	s_barrier_signal -1
	v_cmp_gt_u32_e32 vcc_lo, 64, v0
	s_barrier_wait -1
	v_add_nc_u64_e32 v[18:19], s[0:1], v[8:9]
	v_mov_b32_e32 v8, v9
	s_mov_b32 s1, 0
	s_branch .LBB0_4
.LBB0_3:                                ;   in Loop: Header=BB0_4 Depth=1
	s_or_b32 exec_lo, exec_lo, s7
	v_add_nc_u64_e32 v[16:17], 0x800, v[16:17]
	s_add_co_i32 s1, s1, 1
	s_xor_b32 s6, s6, -1
	s_cmp_eq_u32 s1, 64
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_scc1 .LBB0_10
.LBB0_4:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_6 Depth 2
	s_cmp_eq_u32 s1, 63
	s_cbranch_scc1 .LBB0_8
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=1
	v_cndmask_b32_e64 v36, 0, 1, s6
	v_mov_b64_e32 v[20:21], v[16:17]
	v_mov_b32_e32 v37, v1
	s_mov_b32 s7, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v36, v36, 11, v4
.LBB0_6:                                ;   Parent Loop BB0_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v38, v[20:21], off
	v_add_nc_u32_e32 v37, 0x100, v37
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[20:21], 0x200, v[20:21]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e64 s0, 0x2ff, v37
	s_or_b32 s7, s0, s7
	s_wait_loadcnt 0x0
	ds_store_b16 v36, v38
	v_add_nc_u32_e32 v36, 0x200, v36
	s_and_not1_b32 exec_lo, exec_lo, s7
	s_cbranch_execnz .LBB0_6
; %bb.7:                                ;   in Loop: Header=BB0_4 Depth=1
	s_or_b32 exec_lo, exec_lo, s7
.LBB0_8:                                ;   in Loop: Header=BB0_4 Depth=1
	s_and_saveexec_b32 s7, vcc_lo
	s_cbranch_execz .LBB0_3
; %bb.9:                                ;   in Loop: Header=BB0_4 Depth=1
	s_and_b32 s0, s1, 1
	global_load_b128 v[36:39], v[12:13], off
	v_lshl_or_b32 v20, s0, 11, v26
	s_cmp_eq_u32 s1, 0
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v21, v5, 1, v20
	ds_load_b128 v[44:47], v21
	ds_load_b96 v[48:50], v21 offset:32
	ds_load_u16 v51, v21 offset:44
	s_clause 0x2
	global_load_b96 v[40:42], v[12:13], off offset:32
	global_load_u16 v43, v[12:13], off offset:44
	global_load_u16 v52, v[14:15], off
	s_wait_loadcnt 0x0
	v_perm_b32 v43, v52, v43, 0x5040100
	v_lshl_add_u32 v52, v25, 1, v20
	v_lshl_add_u32 v20, v27, 1, v20
	ds_load_u16 v52, v52
	s_wait_dscnt 0x0
	v_perm_b32 v51, v52, v51, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[52:59], v[36:43], v[44:51], 0
	global_load_b128 v[36:39], v[12:13], off offset:64
	ds_load_b128 v[44:47], v21 offset:64
	s_clause 0x1
	global_load_b96 v[40:42], v[12:13], off offset:96
	global_load_u16 v43, v[12:13], off offset:108
	ds_load_b96 v[48:50], v21 offset:96
	ds_load_u16 v21, v21 offset:108
	global_load_u16 v51, v[18:19], off
	ds_load_u16 v20, v20
	s_wait_loadcnt 0x0
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v43, v51, v43, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v51, v20, v21, 0x5040100
	v_lshl_or_b32 v20, s1, 4, v23
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x32_f16 v[52:59], v[36:43], v[44:51], v[52:59]
	s_clause 0x1
	global_load_b32 v21, v20, s[4:5] scale_offset
	global_load_b32 v36, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_and_b32_e32 v20, 16, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v20, 16, v20
	s_wait_loadcnt 0x0
	v_nop
	v_nop
	v_mul_f32_e32 v43, 0x3fb8aa3b, v36
	v_fmac_f32_e32 v43, 0x3fb8aa3b, v21
	v_xor_b32_e32 v21, 8, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cmp_lt_i32_e64 s0, v21, v20
	v_cndmask_b32_e64 v21, v24, v21, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v44, 2, v21 :: v_dual_bitop2_b32 v21, 4, v24 bitop3:0x14
	v_cmp_lt_i32_e64 s0, v21, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e64 v21, v24, v21, s0
	v_dual_lshlrev_b32 v45, 2, v21 :: v_dual_bitop2_b32 v21, 2, v24 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cmp_lt_i32_e64 s0, v21, v20
	v_cndmask_b32_e64 v21, v24, v21, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v46, 2, v21 :: v_dual_bitop2_b32 v21, 1, v24 bitop3:0x14
	v_cmp_lt_i32_e64 s0, v21, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cndmask_b32_e64 v20, v24, v21, s0
	s_cselect_b32 s0, -1, 0
	v_dual_fmamk_f32 v20, v52, 0x4038aa3b, v43 :: v_dual_lshlrev_b32 v47, 2, v20
	ds_bpermute_b32 v21, v44, v20
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v21, v21, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v21, v20, v21
	ds_bpermute_b32 v36, v45, v21
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v36, v36, v36
	v_max_num_f32_e32 v21, v21, v36
	ds_bpermute_b32 v36, v46, v21
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v36, v36, v36
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v21, v21, v36
	ds_bpermute_b32 v36, v47, v21
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v36, v36, v36
	v_dual_max_num_f32 v21, v21, v36 :: v_dual_max_num_f32 v36, v35, v35
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v36, v36, v21
	v_cndmask_b32_e64 v50, v36, v21, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v21, v35, v50
	v_exp_f32_e32 v48, v21
	v_nop
	v_fmamk_f32 v21, v53, 0x4038aa3b, v43
	ds_bpermute_b32 v35, v44, v21
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v35, v35, v35
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v35, v21, v35
	ds_bpermute_b32 v37, v45, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v37, v37, v37
	v_max_num_f32_e32 v35, v35, v37
	ds_bpermute_b32 v37, v46, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v37, v37, v37
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v35, v35, v37
	ds_bpermute_b32 v37, v47, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v37, v37, v37
	v_dual_max_num_f32 v35, v35, v37 :: v_dual_max_num_f32 v37, v34, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v37, v37, v35 :: v_dual_sub_f32 v20, v20, v50
	v_cndmask_b32_e64 v51, v37, v35, s0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v20, v20
	v_sub_f32_e32 v21, v21, v51
	ds_bpermute_b32 v36, v44, v20
	v_exp_f32_e32 v21, v21
	ds_bpermute_b32 v37, v44, v21
	s_wait_dscnt 0x0
	v_nop
	v_pk_add_f32 v[20:21], v[20:21], v[36:37]
	v_fmamk_f32 v36, v54, 0x4038aa3b, v43
	ds_bpermute_b32 v35, v45, v21
	ds_bpermute_b32 v37, v44, v36
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v37, v37, v37 :: v_dual_sub_f32 v34, v34, v51
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_max_num_f32_e32 v37, v36, v37
	v_exp_f32_e32 v49, v34
	ds_bpermute_b32 v34, v45, v20
	ds_bpermute_b32 v38, v45, v37
	s_wait_dscnt 0x1
	v_pk_add_f32 v[20:21], v[20:21], v[34:35]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v38, v38, v38
	ds_bpermute_b32 v34, v46, v20
	ds_bpermute_b32 v35, v46, v21
	v_max_num_f32_e32 v37, v37, v38
	ds_bpermute_b32 v38, v46, v37
	s_wait_dscnt 0x1
	v_pk_add_f32 v[20:21], v[20:21], v[34:35]
	ds_bpermute_b32 v34, v47, v20
	ds_bpermute_b32 v35, v47, v21
	s_wait_dscnt 0x2
	v_max_num_f32_e32 v38, v38, v38
	s_delay_alu instid0(VALU_DEP_1)
	v_max_num_f32_e32 v37, v37, v38
	ds_bpermute_b32 v38, v47, v37
	s_wait_dscnt 0x1
	v_pk_add_f32 v[20:21], v[20:21], v[34:35]
	v_dual_mov_b32 v35, v50 :: v_dual_mov_b32 v34, v51
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v38, v38, v38
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v37, v37, v38
	v_max_num_f32_e32 v38, v33, v33
	v_max_num_f32_e32 v38, v38, v37
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e64 v52, v38, v37, s0
	v_sub_f32_e32 v33, v33, v52
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v53, v33
	v_nop
	v_sub_f32_e32 v33, v36, v52
	v_exp_f32_e32 v36, v33
	v_nop
	v_fmamk_f32 v33, v55, 0x4038aa3b, v43
	ds_bpermute_b32 v37, v44, v33
	ds_bpermute_b32 v38, v44, v36
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v37, v37, v37
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v37, v33, v37
	ds_bpermute_b32 v39, v45, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	v_max_num_f32_e32 v37, v37, v39
	ds_bpermute_b32 v39, v46, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v37, v37, v39
	ds_bpermute_b32 v39, v47, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	v_dual_max_num_f32 v37, v37, v39 :: v_dual_max_num_f32 v39, v32, v32
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v37
	v_cndmask_b32_e64 v54, v39, v37, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v32, v32, v54
	v_exp_f32_e32 v55, v32
	v_nop
	v_sub_f32_e32 v32, v33, v54
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v37, v32
	ds_bpermute_b32 v39, v44, v37
	s_wait_dscnt 0x0
	v_nop
	v_pk_add_f32 v[32:33], v[36:37], v[38:39]
	v_fmamk_f32 v38, v56, 0x4038aa3b, v43
	ds_bpermute_b32 v36, v45, v32
	ds_bpermute_b32 v39, v44, v38
	ds_bpermute_b32 v37, v45, v33
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v39, v39, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[36:37]
	s_delay_alu instid0(VALU_DEP_2)
	v_max_num_f32_e32 v39, v38, v39
	ds_bpermute_b32 v36, v46, v32
	ds_bpermute_b32 v37, v46, v33
	ds_bpermute_b32 v40, v45, v39
	s_wait_dscnt 0x1
	v_pk_add_f32 v[32:33], v[32:33], v[36:37]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v40, v40, v40
	ds_bpermute_b32 v36, v47, v32
	ds_bpermute_b32 v37, v47, v33
	v_max_num_f32_e32 v39, v39, v40
	ds_bpermute_b32 v40, v46, v39
	s_wait_dscnt 0x1
	v_pk_add_f32 v[32:33], v[32:33], v[36:37]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v40, v40, v40
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v40
	ds_bpermute_b32 v40, v47, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v40, v40, v40
	v_max_num_f32_e32 v39, v39, v40
	v_max_num_f32_e32 v40, v31, v31
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v40, v40, v39
	v_cndmask_b32_e64 v56, v40, v39, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v31, v31, v56
	v_exp_f32_e32 v60, v31
	v_nop
	v_sub_f32_e32 v31, v38, v56
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v38, v31
	v_nop
	v_fmamk_f32 v31, v57, 0x4038aa3b, v43
	ds_bpermute_b32 v39, v44, v31
	ds_bpermute_b32 v40, v44, v38
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v39, v39, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v31, v39
	ds_bpermute_b32 v41, v45, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	v_max_num_f32_e32 v39, v39, v41
	ds_bpermute_b32 v41, v46, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v41
	ds_bpermute_b32 v41, v47, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	v_dual_max_num_f32 v39, v39, v41 :: v_dual_max_num_f32 v41, v30, v30
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v41, v41, v39
	v_cndmask_b32_e64 v57, v41, v39, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v30, v30, v57
	v_exp_f32_e32 v61, v30
	v_nop
	v_sub_f32_e32 v30, v31, v57
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v39, v30
	ds_bpermute_b32 v41, v44, v39
	s_wait_dscnt 0x0
	v_nop
	v_pk_add_f32 v[30:31], v[38:39], v[40:41]
	v_dual_fmamk_f32 v40, v58, 0x4038aa3b, v43 :: v_dual_fmac_f32 v43, 0x4038aa3b, v59
	ds_bpermute_b32 v38, v45, v30
	ds_bpermute_b32 v41, v44, v40
	ds_bpermute_b32 v39, v45, v31
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v41, v41, v41
	s_wait_dscnt 0x0
	v_pk_add_f32 v[30:31], v[30:31], v[38:39]
	s_delay_alu instid0(VALU_DEP_2)
	v_max_num_f32_e32 v41, v40, v41
	ds_bpermute_b32 v38, v46, v30
	ds_bpermute_b32 v39, v46, v31
	ds_bpermute_b32 v42, v45, v41
	s_wait_dscnt 0x1
	v_pk_add_f32 v[30:31], v[30:31], v[38:39]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v42, v42, v42
	ds_bpermute_b32 v38, v47, v30
	ds_bpermute_b32 v39, v47, v31
	v_max_num_f32_e32 v41, v41, v42
	ds_bpermute_b32 v42, v46, v41
	s_wait_dscnt 0x1
	v_pk_add_f32 v[30:31], v[30:31], v[38:39]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v42, v42, v42
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v41, v41, v42
	ds_bpermute_b32 v42, v47, v41
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v42, v42, v42
	v_max_num_f32_e32 v41, v41, v42
	v_max_num_f32_e32 v42, v29, v29
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v42, v42, v41
	v_cndmask_b32_e64 v58, v42, v41, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v29, v29, v58
	v_exp_f32_e32 v62, v29
	v_nop
	v_sub_f32_e32 v29, v40, v58
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v40, v29
	ds_bpermute_b32 v29, v44, v43
	ds_bpermute_b32 v42, v44, v40
	s_wait_dscnt 0x1
	v_nop
	v_max_num_f32_e32 v29, v29, v29
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v29, v43, v29
	ds_bpermute_b32 v41, v45, v29
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	v_max_num_f32_e32 v29, v29, v41
	ds_bpermute_b32 v41, v46, v29
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v29, v29, v41
	ds_bpermute_b32 v41, v47, v29
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	v_dual_max_num_f32 v29, v29, v41 :: v_dual_max_num_f32 v41, v28, v28
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v41, v41, v29
	v_cndmask_b32_e64 v59, v41, v29, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v28, v28, v59
	v_exp_f32_e32 v63, v28
	v_nop
	v_sub_f32_e32 v28, v43, v59
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v41, v28
	ds_bpermute_b32 v43, v44, v41
	v_cndmask_b32_e64 v44, v53, 0, s0
	s_wait_dscnt 0x0
	v_pk_add_f32 v[28:29], v[40:41], v[42:43]
	v_cndmask_b32_e64 v43, v49, 0, s0
	v_cndmask_b32_e64 v42, v48, 0, s0
	v_cndmask_b32_e64 v49, v63, 0, s0
	v_cndmask_b32_e64 v48, v62, 0, s0
	ds_bpermute_b32 v40, v45, v28
	ds_bpermute_b32 v41, v45, v29
	v_cndmask_b32_e64 v45, v55, 0, s0
	v_pk_fma_f32 v[8:9], v[8:9], v[42:43], v[20:21]
	s_delay_alu instid0(VALU_DEP_2)
	v_pk_fma_f32 v[10:11], v[10:11], v[44:45], v[32:33]
	v_dual_mov_b32 v33, v52 :: v_dual_mov_b32 v32, v54
	s_wait_dscnt 0x0
	v_pk_add_f32 v[28:29], v[28:29], v[40:41]
	ds_bpermute_b32 v40, v46, v28
	ds_bpermute_b32 v41, v46, v29
	v_cndmask_b32_e64 v46, v60, 0, s0
	s_wait_dscnt 0x0
	v_pk_add_f32 v[28:29], v[28:29], v[40:41]
	ds_bpermute_b32 v40, v47, v28
	ds_bpermute_b32 v41, v47, v29
	v_cndmask_b32_e64 v47, v61, 0, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_pk_fma_f32 v[6:7], v[6:7], v[46:47], v[30:31]
	v_mov_b32_e32 v31, v56
	s_wait_dscnt 0x0
	v_pk_add_f32 v[28:29], v[28:29], v[40:41]
	v_pk_fma_f32 v[2:3], v[2:3], v[48:49], v[28:29]
	v_dual_mov_b32 v29, v58 :: v_dual_mov_b32 v30, v57
	v_mov_b32_e32 v28, v59
	s_branch .LBB0_3
.LBB0_10:
	v_and_b32_e32 v0, 0xcf, v0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_12
; %bb.11:
	v_or3_b32 v0, v22, v5, s21
	s_and_b32 s0, s20, exec_lo
	s_cselect_b32 s1, s9, s11
	s_cselect_b32 s0, s8, s10
	s_cselect_b32 s3, s17, s19
	global_load_b32 v1, v0, s[0:1] scale_offset
	v_max_num_f32_e32 v4, v8, v8
	s_cselect_b32 s2, s16, s18
	v_max_num_f32_e32 v2, v2, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v2, 0x116c2, v2
	v_log_f32_e32 v2, v2
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v29, v2
	s_wait_loadcnt 0x0
	v_dual_mul_f32 v2, 0x3f317218, v2 :: v_dual_mul_f32 v1, 0.5, v1
	v_max_num_f32_e32 v4, 0x116c2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_log_f32_e32 v4, v4
	v_nop
	v_add_f32_e32 v4, v35, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v4, 0x3f317218, v4
	v_dual_fmac_f32 v1, -0.5, v4 :: v_dual_max_num_f32 v4, v9, v9
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] scale_offset
	global_load_b32 v1, v0, s[0:1] offset:4 scale_offset
	v_max_num_f32_e32 v4, 0x116c2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_log_f32_e32 v4, v4
	v_nop
	v_add_f32_e32 v4, v34, v4
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v4, 0x3f317218, v4 :: v_dual_mul_f32 v1, 0.5, v1
	v_dual_fmac_f32 v1, -0.5, v4 :: v_dual_max_num_f32 v4, v10, v10
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:4 scale_offset
	global_load_b32 v1, v0, s[0:1] offset:8 scale_offset
	v_max_num_f32_e32 v4, 0x116c2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_log_f32_e32 v4, v4
	v_nop
	v_add_f32_e32 v4, v33, v4
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v4, 0x3f317218, v4 :: v_dual_mul_f32 v1, 0.5, v1
	v_dual_fmac_f32 v1, -0.5, v4 :: v_dual_max_num_f32 v4, v11, v11
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:8 scale_offset
	global_load_b32 v1, v0, s[0:1] offset:12 scale_offset
	v_max_num_f32_e32 v4, 0x116c2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_log_f32_e32 v4, v4
	v_nop
	v_add_f32_e32 v4, v32, v4
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v4, 0x3f317218, v4 :: v_dual_mul_f32 v1, 0.5, v1
	v_dual_fmac_f32 v1, -0.5, v4 :: v_dual_max_num_f32 v4, v6, v6
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:12 scale_offset
	global_load_b32 v1, v0, s[0:1] offset:16 scale_offset
	v_max_num_f32_e32 v4, 0x116c2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_log_f32_e32 v4, v4
	v_nop
	v_add_f32_e32 v4, v31, v4
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v4, 0x3f317218, v4 :: v_dual_mul_f32 v1, 0.5, v1
	v_dual_fmac_f32 v1, -0.5, v4 :: v_dual_max_num_f32 v4, v7, v7
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:16 scale_offset
	global_load_b32 v1, v0, s[0:1] offset:20 scale_offset
	v_max_num_f32_e32 v4, 0x116c2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_log_f32_e32 v4, v4
	v_nop
	v_add_f32_e32 v4, v30, v4
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v4, 0x3f317218, v4 :: v_dual_mul_f32 v1, 0.5, v1
	v_fmac_f32_e32 v1, -0.5, v4
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:20 scale_offset
	global_load_b32 v1, v0, s[0:1] offset:24 scale_offset
	s_wait_loadcnt 0x0
	v_mul_f32_e32 v1, 0.5, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_dual_fmac_f32 v1, -0.5, v2 :: v_dual_max_num_f32 v2, v3, v3
	s_clause 0x1
	global_store_b32 v0, v1, s[2:3] offset:24 scale_offset
	global_load_b32 v1, v0, s[0:1] offset:28 scale_offset
	v_max_num_f32_e32 v2, 0x116c2, v2
	v_log_f32_e32 v2, v2
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v28, v2
	s_wait_loadcnt 0x0
	v_dual_mul_f32 v2, 0x3f317218, v2 :: v_dual_mul_f32 v1, 0.5, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_fmac_f32_e32 v1, -0.5, v2
	global_store_b32 v0, v1, s[2:3] offset:28 scale_offset
.LBB0_12:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel sinkhorn_original
		.amdhsa_group_segment_fixed_size 4096
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 88
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
		.amdhsa_next_free_vgpr 64
		.amdhsa_next_free_sgpr 22
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 29
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
	.size	sinkhorn_original, .Lfunc_end0-sinkhorn_original
                                        ; -- End function
	.set sinkhorn_original.num_vgpr, 64
	.set sinkhorn_original.num_agpr, 0
	.set sinkhorn_original.numbered_sgpr, 22
	.set sinkhorn_original.num_named_barrier, 0
	.set sinkhorn_original.private_seg_size, 0
	.set sinkhorn_original.uses_vcc, 1
	.set sinkhorn_original.uses_flat_scratch, 0
	.set sinkhorn_original.has_dyn_sized_stack, 0
	.set sinkhorn_original.has_recursion, 0
	.set sinkhorn_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3640
; TotalNumSgprs: 24
; NumVgprs: 64
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 24
; NumVGPRsForWavesPerEU: 64
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
	.type	__hip_cuid_13977ab486e2cad3,@object ; @__hip_cuid_13977ab486e2cad3
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_13977ab486e2cad3
__hip_cuid_13977ab486e2cad3:
	.byte	0                               ; 0x0
	.size	__hip_cuid_13977ab486e2cad3, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_13977ab486e2cad3
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
      - .address_space:  global
        .offset:         64
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         72
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           sinkhorn_original
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         sinkhorn_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     64
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
