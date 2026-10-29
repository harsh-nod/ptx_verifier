	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	mamba_state_original    ; -- Begin function mamba_state_original
	.globl	mamba_state_original
	.p2align	8
	.type	mamba_state_original,@function
mamba_state_original:                   ; @mamba_state_original
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x40014
	s_lshr_b32 s4, ttmp7, 16
	s_add_co_i32 s2, s2, 1
	s_bfe_u32 s5, ttmp6, 0x40010
	s_mul_i32 s2, s4, s2
	s_bfe_u32 s3, ttmp6, 0x40008
	s_and_b32 s6, ttmp7, 0xffff
	s_add_co_i32 s5, s5, 1
	s_add_co_i32 s7, s3, s2
	s_mul_i32 s2, s6, s5
	s_bfe_u32 s3, ttmp6, 0x40004
	s_getreg_b32 s5, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s8, s3, s2
	s_load_b64 s[2:3], s[0:1], 0x20
	s_cmp_eq_u32 s5, 0
	s_mov_b32 s15, 0
	s_cselect_b32 s4, s4, s7
	s_cselect_b32 s12, s6, s8
	s_lshl_b32 s13, s4, 9
	s_bfe_u32 s18, s12, 0x30003
	s_add_co_i32 s13, s13, s12
	s_lshl_b32 s22, s18, 17
	s_lshr_b32 s17, s13, 6
	s_and_b32 s16, s12, 7
	s_lshl_b32 s21, s17, 20
	s_load_b256 s[4:11], s[0:1], 0x0
	s_or_b32 s24, s21, s22
	s_lshl_b32 s23, s16, 6
	s_wait_xcnt 0x0
	s_lshl_b32 s0, s17, 14
	s_lshl_b32 s1, s18, 8
	s_or_b32 s14, s24, s23
	s_or_b32 s12, s0, s1
	s_lshl_b32 s13, s16, 11
	s_lshl_b64 s[0:1], s[14:15], 1
	s_or_b32 s14, s12, s13
	v_dual_lshlrev_b32 v153, 1, v0 :: v_dual_bitop2_b32 v152, 31, v0 bitop3:0x40
	s_wait_kmcnt 0x0
	s_load_b32 s19, s[2:3], s14 offset:0x3fc scale_offset
	v_or_b32_e32 v3, 0xc0, v0
	v_or_b32_e32 v2, 0x80, v0
	v_dual_lshlrev_b32 v6, 9, v152 :: v_dual_mov_b32 v12, 32
	v_or_b32_e32 v1, 64, v0
	v_or_b32_e32 v154, 0x4000, v153
	s_lshl_b64 s[12:13], s[14:15], 2
	s_delay_alu instid0(VALU_DEP_3)
	v_mov_b32_e32 v5, v6
	v_mov_b64_e32 v[10:11], v[2:3]
	v_mov_b64_e32 v[8:9], v[0:1]
	v_dual_mov_b32 v4, v6 :: v_dual_mov_b32 v7, v6
	v_mov_b32_e32 v13, v154
	s_add_nc_u64 s[0:1], s[4:5], s[0:1]
	s_wait_xcnt 0x0
	s_add_nc_u64 s[2:3], s[2:3], s[12:13]
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_lshrrev_b32 v14, 5, v8 :: v_dual_lshrrev_b32 v15, 5, v9
	v_dual_lshrrev_b32 v16, 5, v10 :: v_dual_lshrrev_b32 v17, 5, v11
	v_dual_add_nc_u32 v12, -4, v12 :: v_dual_add_nc_u32 v14, v14, v6
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_add_nc_u32 v15, v15, v5 :: v_dual_add_nc_u32 v16, v16, v4
	v_add_nc_u32_e32 v17, v17, v7
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_eq_u32_e32 vcc_lo, 0, v12
	s_clause 0x3
	global_load_u16 v18, v14, s[0:1] scale_offset
	global_load_u16 v19, v15, s[0:1] scale_offset
	global_load_u16 v20, v16, s[0:1] scale_offset
	global_load_u16 v21, v17, s[0:1] scale_offset
	v_add_nc_u32_e32 v11, 0x100, v11
	v_add_nc_u32_e32 v10, 0x100, v10
	v_add_nc_u32_e32 v9, 0x100, v9
	v_add_nc_u32_e32 v8, 0x100, v8
	s_or_b32 s15, vcc_lo, s15
	s_wait_loadcnt 0x3
	ds_store_b16 v13, v18
	s_wait_loadcnt 0x2
	ds_store_b16 v13, v19 offset:128
	s_wait_loadcnt 0x1
	ds_store_b16 v13, v20 offset:256
	s_wait_loadcnt 0x0
	ds_store_b16 v13, v21 offset:384
	v_add_nc_u32_e32 v13, 0x200, v13
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s15
	s_cbranch_execnz .LBB0_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s15
	v_lshl_or_b32 v10, 32, 6, v0
	v_cmp_ne_u32_e64 s20, 32, 32
	s_delay_alu instid0(VALU_DEP_2)
	v_subrev_nc_u32_e32 v155, 64, v10
	v_lshrrev_b32_e32 v16, 5, v10
	s_and_saveexec_b32 s25, s20
	s_cbranch_execz .LBB0_5
; %bb.3:
	s_add_co_i32 s14, s21, s22
	s_mov_b32 s15, 0
	s_add_co_i32 s14, s14, s23
	v_add_lshl_u32 v8, v16, v6, 1
	v_mov_b32_e32 v9, 0
	s_lshl_b64 s[26:27], s[14:15], 1
	s_movk_i32 s14, 0x4000
	s_add_nc_u64 s[26:27], s[4:5], s[26:27]
	v_or3_b32 v11, 0x1000, v153, s14
	v_add_nc_u64_e32 v[8:9], s[26:27], v[8:9]
	v_subrev_nc_u32_e32 v10, 64, v10
.LBB0_4:                                ; =>This Inner Loop Header: Depth=1
	global_load_u16 v12, v[8:9], off
	v_add_nc_u32_e32 v10, 64, v10
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[8:9], 4, v[8:9]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0x7bf, v10
	s_or_b32 s15, vcc_lo, s15
	s_wait_loadcnt 0x0
	ds_store_b16 v11, v12
	v_add_nc_u32_e32 v11, 0x80, v11
	s_and_not1_b32 exec_lo, exec_lo, s15
	s_cbranch_execnz .LBB0_4
.LBB0_5:
	s_or_b32 exec_lo, exec_lo, s25
	global_load_b32 v8, v152, s[2:3] scale_offset
	s_add_nc_u64 s[14:15], s[10:11], s[12:13]
	s_and_b32 s13, s23, 0x180
	global_load_b32 v10, v152, s[14:15] scale_offset
	s_mov_b32 s11, 0
	s_or_b32 s10, s24, s13
	v_dual_mov_b32 v9, 0 :: v_dual_mov_b32 v17, 64
	s_wait_loadcnt 0x1
	s_wait_kmcnt 0x0
	v_sub_f32_e32 v8, s19, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_min_num_f32_e32 v8, 0, v8
	v_mul_f32_e32 v8, 0x3fb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v11, v8
	s_wait_loadcnt 0x0
	v_nop
	v_dual_lshlrev_b32 v8, 2, v152 :: v_dual_mul_f32 v12, v10, v11
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u64_e32 v[140:141], s[2:3], v[8:9]
	v_add_nc_u64_e32 v[142:143], s[14:15], v[8:9]
	v_mov_b64_e32 v[10:11], v[2:3]
	v_mov_b64_e32 v[8:9], v[0:1]
	v_dual_mov_b32 v18, v153 :: v_dual_mov_b32 v14, v12
	v_dual_mov_b32 v13, v12 :: v_dual_mov_b32 v15, v12
	s_lshl_b64 s[2:3], s[10:11], 1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_nc_u64 s[2:3], s[6:7], s[2:3]
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v19, 5, v9 :: v_dual_lshrrev_b32 v20, 5, v8
	v_dual_lshrrev_b32 v21, 5, v11 :: v_dual_lshrrev_b32 v22, 5, v10
	v_add_nc_u32_e32 v17, -4, v17
	v_dual_add_nc_u32 v19, v19, v5 :: v_dual_add_nc_u32 v20, v20, v6
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_add_nc_u32 v21, v21, v7 :: v_dual_add_nc_u32 v22, v22, v4
	v_cmp_eq_u32_e32 vcc_lo, 0, v17
	s_clause 0x3
	global_load_u16 v23, v19, s[2:3] scale_offset
	global_load_u16 v24, v20, s[2:3] scale_offset
	global_load_u16 v25, v21, s[2:3] scale_offset
	global_load_u16 v26, v22, s[2:3] scale_offset
	v_add_nc_u32_e32 v11, 0x100, v11
	v_add_nc_u32_e32 v10, 0x100, v10
	v_add_nc_u32_e32 v9, 0x100, v9
	v_add_nc_u32_e32 v8, 0x100, v8
	s_or_b32 s11, vcc_lo, s11
	s_wait_loadcnt 0x3
	s_wait_xcnt 0x1
	v_cvt_f32_f16_e32 v21, v23
	s_wait_loadcnt 0x2
	v_cvt_f32_f16_e32 v20, v24
	s_wait_loadcnt 0x1
	v_cvt_f32_f16_e32 v23, v25
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_f16_e32 v22, v26
	v_pk_mul_f32 v[20:21], v[12:13], v[20:21]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_mul_f32 v[22:23], v[14:15], v[22:23]
	v_cvt_pk_f16_f32 v19, v20, v21
	s_delay_alu instid0(VALU_DEP_2)
	v_cvt_pk_f16_f32 v20, v22, v23
	ds_store_b16 v18, v19
	ds_store_b16_d16_hi v18, v19 offset:128
	ds_store_b16 v18, v20 offset:256
	ds_store_b16_d16_hi v18, v20 offset:384
	v_add_nc_u32_e32 v18, 0x200, v18
	s_and_not1_b32 exec_lo, exec_lo, s11
	s_cbranch_execnz .LBB0_6
; %bb.7:
	s_or_b32 exec_lo, exec_lo, s11
	v_lshl_or_b32 v9, 64, 6, v0
	v_cmp_ne_u32_e64 s12, 64, 64
	s_delay_alu instid0(VALU_DEP_2)
	v_subrev_nc_u32_e32 v156, 64, v9
	v_lshrrev_b32_e32 v7, 5, v9
	s_and_saveexec_b32 s14, s12
	s_cbranch_execz .LBB0_10
; %bb.8:
	s_add_co_i32 s10, s21, s22
	s_mov_b32 s11, 0
	s_add_co_i32 s10, s10, s13
	v_add_lshl_u32 v4, v7, v6, 1
	v_mov_b32_e32 v5, 0
	s_lshl_b64 s[24:25], s[10:11], 1
	s_movk_i32 s10, 0x3e00
	s_add_nc_u64 s[24:25], s[6:7], s[24:25]
	v_and_or_b32 v8, 0x2000, s10, v153
	v_add_nc_u64_e32 v[4:5], s[24:25], v[4:5]
	v_subrev_nc_u32_e32 v9, 64, v9
.LBB0_9:                                ; =>This Inner Loop Header: Depth=1
	global_load_u16 v10, v[4:5], off
	v_add_nc_u32_e32 v9, 64, v9
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[4:5], 4, v[4:5]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xfbf, v9
	s_or_b32 s11, vcc_lo, s11
	s_wait_loadcnt 0x0
	v_fma_mixlo_f16 v10, v12, v10, 0 op_sel_hi:[0,1,0]
	ds_store_b16 v8, v10
	v_add_nc_u32_e32 v8, 0x80, v8
	s_and_not1_b32 exec_lo, exec_lo, s11
	s_cbranch_execnz .LBB0_9
.LBB0_10:
	s_or_b32 exec_lo, exec_lo, s14
	s_add_co_i32 s21, s21, s22
	s_mov_b32 s11, 0
	s_add_co_i32 s10, s21, s23
	v_dual_lshrrev_b32 v8, 1, v0 :: v_dual_lshlrev_b32 v10, 6, v0
	v_add_lshl_u32 v4, v16, v6, 1
	v_mov_b32_e32 v5, 0
	s_lshl_b64 s[14:15], s[10:11], 1
	s_add_co_i32 s10, s21, s13
	s_add_nc_u64 s[4:5], s[4:5], s[14:15]
	v_and_b32_e32 v157, 8, v8
	v_add_nc_u64_e32 v[8:9], s[4:5], v[4:5]
	v_add_lshl_u32 v4, v7, v6, 1
	s_lshl_b64 s[4:5], s[10:11], 1
	v_and_b32_e32 v11, 0xbc0, v10
	s_add_nc_u64 s[4:5], s[6:7], s[4:5]
	v_dual_mov_b32 v13, 0x1000 :: v_dual_lshlrev_b32 v12, 1, v157
	v_add_nc_u64_e32 v[6:7], s[4:5], v[4:5]
	v_add_nc_u64_e32 v[144:145], 0x8000, v[8:9]
	s_movk_i32 s4, 0x3e00
	s_delay_alu instid0(VALU_DEP_3)
	v_or3_b32 v158, v11, v12, 0x4000
	v_and_or_b32 v159, 0x3c0, v10, v12
	v_or3_b32 v160, v13, v153, 0x4000
	v_mov_b32_e32 v4, v5
	v_add_nc_u64_e32 v[146:147], 0x8000, v[6:7]
	v_dual_mov_b32 v6, v5 :: v_dual_mov_b32 v7, v5
	v_dual_mov_b32 v8, v5 :: v_dual_mov_b32 v9, v5
	v_dual_mov_b32 v10, v5 :: v_dual_mov_b32 v11, v5
	v_dual_mov_b32 v12, v5 :: v_dual_mov_b32 v13, v5
	v_dual_mov_b32 v14, v5 :: v_dual_mov_b32 v15, v5
	v_dual_mov_b32 v16, v5 :: v_dual_mov_b32 v17, v5
	v_dual_mov_b32 v18, v5 :: v_dual_mov_b32 v19, v5
	v_dual_mov_b32 v20, v5 :: v_dual_mov_b32 v21, v5
	v_dual_mov_b32 v22, v5 :: v_dual_mov_b32 v23, v5
	v_dual_mov_b32 v24, v5 :: v_dual_mov_b32 v25, v5
	v_dual_mov_b32 v26, v5 :: v_dual_mov_b32 v27, v5
	v_dual_mov_b32 v28, v5 :: v_dual_mov_b32 v29, v5
	v_dual_mov_b32 v30, v5 :: v_dual_mov_b32 v31, v5
	v_dual_mov_b32 v32, v5 :: v_dual_mov_b32 v33, v5
	v_dual_mov_b32 v34, v5 :: v_dual_mov_b32 v35, v5
	v_dual_mov_b32 v36, v5 :: v_dual_mov_b32 v37, v5
	v_dual_mov_b32 v38, v5 :: v_dual_mov_b32 v39, v5
	v_dual_mov_b32 v40, v5 :: v_dual_mov_b32 v41, v5
	v_dual_mov_b32 v42, v5 :: v_dual_mov_b32 v43, v5
	v_dual_mov_b32 v44, v5 :: v_dual_mov_b32 v45, v5
	v_dual_mov_b32 v46, v5 :: v_dual_mov_b32 v47, v5
	v_dual_mov_b32 v48, v5 :: v_dual_mov_b32 v49, v5
	v_dual_mov_b32 v50, v5 :: v_dual_mov_b32 v51, v5
	v_dual_mov_b32 v52, v5 :: v_dual_mov_b32 v53, v5
	v_dual_mov_b32 v54, v5 :: v_dual_mov_b32 v55, v5
	v_dual_mov_b32 v56, v5 :: v_dual_mov_b32 v57, v5
	v_dual_mov_b32 v58, v5 :: v_dual_mov_b32 v59, v5
	v_dual_mov_b32 v60, v5 :: v_dual_mov_b32 v61, v5
	v_dual_mov_b32 v62, v5 :: v_dual_mov_b32 v63, v5
	v_dual_mov_b32 v64, v5 :: v_dual_mov_b32 v65, v5
	v_dual_mov_b32 v66, v5 :: v_dual_mov_b32 v67, v5
	v_dual_mov_b32 v68, v5 :: v_dual_mov_b32 v69, v5
	v_dual_mov_b32 v70, v5 :: v_dual_mov_b32 v71, v5
	v_dual_mov_b32 v72, v5 :: v_dual_mov_b32 v73, v5
	v_dual_mov_b32 v74, v5 :: v_dual_mov_b32 v75, v5
	v_dual_mov_b32 v76, v5 :: v_dual_mov_b32 v77, v5
	v_dual_mov_b32 v78, v5 :: v_dual_mov_b32 v79, v5
	v_dual_mov_b32 v80, v5 :: v_dual_mov_b32 v81, v5
	v_dual_mov_b32 v82, v5 :: v_dual_mov_b32 v83, v5
	v_dual_mov_b32 v84, v5 :: v_dual_mov_b32 v85, v5
	v_dual_mov_b32 v86, v5 :: v_dual_mov_b32 v87, v5
	v_dual_mov_b32 v88, v5 :: v_dual_mov_b32 v89, v5
	v_dual_mov_b32 v90, v5 :: v_dual_mov_b32 v91, v5
	v_dual_mov_b32 v92, v5 :: v_dual_mov_b32 v93, v5
	v_dual_mov_b32 v94, v5 :: v_dual_mov_b32 v95, v5
	v_dual_mov_b32 v96, v5 :: v_dual_mov_b32 v97, v5
	v_dual_mov_b32 v98, v5 :: v_dual_mov_b32 v99, v5
	v_dual_mov_b32 v100, v5 :: v_dual_mov_b32 v101, v5
	v_dual_mov_b32 v102, v5 :: v_dual_mov_b32 v103, v5
	v_dual_mov_b32 v104, v5 :: v_dual_mov_b32 v105, v5
	v_dual_mov_b32 v106, v5 :: v_dual_mov_b32 v107, v5
	v_dual_mov_b32 v108, v5 :: v_dual_mov_b32 v109, v5
	v_dual_mov_b32 v110, v5 :: v_dual_mov_b32 v111, v5
	v_dual_mov_b32 v112, v5 :: v_dual_mov_b32 v113, v5
	v_dual_mov_b32 v114, v5 :: v_dual_mov_b32 v115, v5
	v_dual_mov_b32 v116, v5 :: v_dual_mov_b32 v117, v5
	v_dual_mov_b32 v118, v5 :: v_dual_mov_b32 v119, v5
	v_dual_mov_b32 v120, v5 :: v_dual_mov_b32 v121, v5
	v_dual_mov_b32 v122, v5 :: v_dual_mov_b32 v123, v5
	v_dual_mov_b32 v124, v5 :: v_dual_mov_b32 v125, v5
	v_dual_mov_b32 v126, v5 :: v_dual_mov_b32 v127, v5
	v_dual_mov_b32 v128, v5 :: v_dual_mov_b32 v129, v5
	v_dual_mov_b32 v130, v5 :: v_dual_mov_b32 v131, v5
	v_and_or_b32 v161, 0x2000, s4, v153
	s_mov_b32 s4, -1
	s_mov_b32 s10, s11
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB0_13
.LBB0_11:                               ;   in Loop: Header=BB0_13 Depth=1
	s_or_b32 exec_lo, exec_lo, s7
.LBB0_12:                               ;   in Loop: Header=BB0_13 Depth=1
	s_bfe_u32 s7, s10, 0x10005
	v_add_nc_u64_e32 v[144:145], 0x8000, v[144:145]
	v_lshl_add_u32 v148, s7, 12, v158
	v_lshl_or_b32 v149, s7, 13, v159
	v_add_nc_u64_e32 v[146:147], 0x8000, v[146:147]
	s_xor_b32 s4, s4, -1
	s_and_b32 vcc_lo, exec_lo, s6
	ds_load_b128 v[132:135], v148
	ds_load_b128 v[136:139], v148 offset:32
	ds_load_b128 v[162:165], v149
	ds_load_b128 v[166:169], v149 offset:32
	s_mov_b32 s10, s5
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[124:131], v[132:139], v[162:169], v[124:131]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:1024
	ds_load_b128 v[166:169], v149 offset:1056
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[116:123], v[132:139], v[162:169], v[116:123]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:2048
	ds_load_b128 v[166:169], v149 offset:2080
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[108:115], v[132:139], v[162:169], v[108:115]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:3072
	ds_load_b128 v[166:169], v149 offset:3104
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[100:107], v[132:139], v[162:169], v[100:107]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:4096
	ds_load_b128 v[166:169], v149 offset:4128
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[92:99], v[132:139], v[162:169], v[92:99]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:5120
	ds_load_b128 v[166:169], v149 offset:5152
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[84:91], v[132:139], v[162:169], v[84:91]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:6144
	ds_load_b128 v[166:169], v149 offset:6176
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[76:83], v[132:139], v[162:169], v[76:83]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:7168
	ds_load_b128 v[166:169], v149 offset:7200
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[68:75], v[132:139], v[162:169], v[68:75]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[132:135], v148 offset:1024
	ds_load_b128 v[136:139], v148 offset:1056
	ds_load_b128 v[162:165], v149
	ds_load_b128 v[166:169], v149 offset:32
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[60:67], v[132:139], v[162:169], v[60:67]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:1024
	ds_load_b128 v[166:169], v149 offset:1056
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[52:59], v[132:139], v[162:169], v[52:59]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:2048
	ds_load_b128 v[166:169], v149 offset:2080
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[44:51], v[132:139], v[162:169], v[44:51]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:3072
	ds_load_b128 v[166:169], v149 offset:3104
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[36:43], v[132:139], v[162:169], v[36:43]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:4096
	ds_load_b128 v[166:169], v149 offset:4128
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[28:35], v[132:139], v[162:169], v[28:35]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:5120
	ds_load_b128 v[166:169], v149 offset:5152
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[20:27], v[132:139], v[162:169], v[20:27]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:6144
	ds_load_b128 v[166:169], v149 offset:6176
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[12:19], v[132:139], v[162:169], v[12:19]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[162:165], v149 offset:7168
	ds_load_b128 v[166:169], v149 offset:7200
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[4:11], v[132:139], v[162:169], v[4:11]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccnz .LBB0_24
.LBB0_13:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_15 Depth 2
                                        ;     Child Loop BB0_18 Depth 2
                                        ;     Child Loop BB0_20 Depth 2
                                        ;     Child Loop BB0_23 Depth 2
	s_add_co_i32 s5, s10, 32
	s_cmp_gt_u32 s10, 0xdf
	s_cselect_b32 s6, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 vcc_lo, exec_lo, s6
	s_cbranch_vccnz .LBB0_12
; %bb.14:                               ;   in Loop: Header=BB0_13 Depth=1
	v_cndmask_b32_e64 v148, 0, 1, s4
	v_dual_mov_b32 v150, 32 :: v_dual_bitop2_b32 v132, s5, v152 bitop3:0x54
	v_nop
	v_nop
	v_mov_b64_e32 v[138:139], v[2:3]
	v_mov_b64_e32 v[136:137], v[0:1]
	s_mov_b32 s7, 0
	v_lshlrev_b32_e32 v132, 9, v132
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v149, 12, v148 :: v_dual_mov_b32 v133, v132
	v_dual_mov_b32 v134, v132 :: v_dual_add_nc_u32 v151, v154, v149
	v_mov_b32_e32 v135, v132
.LBB0_15:                               ;   Parent Loop BB0_13 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_dual_lshrrev_b32 v162, 5, v136 :: v_dual_lshrrev_b32 v163, 5, v137
	v_dual_lshrrev_b32 v164, 5, v138 :: v_dual_lshrrev_b32 v165, 5, v139
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_add_nc_u32 v150, -4, v150 :: v_dual_add_nc_u32 v162, v162, v132
	v_dual_add_nc_u32 v163, v163, v133 :: v_dual_add_nc_u32 v164, v164, v134
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_nc_u32_e32 v165, v165, v135
	v_cmp_eq_u32_e32 vcc_lo, 0, v150
	s_clause 0x3
	global_load_u16 v166, v162, s[0:1] scale_offset
	global_load_u16 v167, v163, s[0:1] scale_offset
	global_load_u16 v168, v164, s[0:1] scale_offset
	global_load_u16 v169, v165, s[0:1] scale_offset
	v_add_nc_u32_e32 v139, 0x100, v139
	v_add_nc_u32_e32 v138, 0x100, v138
	v_add_nc_u32_e32 v137, 0x100, v137
	v_add_nc_u32_e32 v136, 0x100, v136
	s_or_b32 s7, vcc_lo, s7
	s_wait_loadcnt 0x3
	ds_store_b16 v151, v166
	s_wait_loadcnt 0x2
	ds_store_b16 v151, v167 offset:128
	s_wait_loadcnt 0x1
	ds_store_b16 v151, v168 offset:256
	s_wait_loadcnt 0x0
	ds_store_b16 v151, v169 offset:384
	v_add_nc_u32_e32 v151, 0x200, v151
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s7
	s_cbranch_execnz .LBB0_15
; %bb.16:                               ;   in Loop: Header=BB0_13 Depth=1
	s_or_b32 exec_lo, exec_lo, s7
	s_and_saveexec_b32 s7, s20
	s_cbranch_execz .LBB0_19
; %bb.17:                               ;   in Loop: Header=BB0_13 Depth=1
	v_mov_b64_e32 v[136:137], v[144:145]
	v_dual_mov_b32 v139, v155 :: v_dual_add_nc_u32 v138, v160, v149
	s_mov_b32 s13, 0
.LBB0_18:                               ;   Parent Loop BB0_13 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v149, v[136:137], off
	v_add_nc_u32_e32 v139, 64, v139
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[136:137], 4, v[136:137]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0x7bf, v139
	s_or_b32 s13, vcc_lo, s13
	s_wait_loadcnt 0x0
	ds_store_b16 v138, v149
	v_add_nc_u32_e32 v138, 0x80, v138
	s_and_not1_b32 exec_lo, exec_lo, s13
	s_cbranch_execnz .LBB0_18
.LBB0_19:                               ;   in Loop: Header=BB0_13 Depth=1
	s_or_b32 exec_lo, exec_lo, s7
	s_lshl_b64 s[14:15], s[10:11], 2
	s_mov_b32 s7, 0
	v_add_nc_u64_e32 v[136:137], s[14:15], v[140:141]
	v_dual_mov_b32 v163, 64 :: v_dual_lshlrev_b32 v162, 13, v148
	s_delay_alu instid0(VALU_DEP_1)
	v_or_b32_e32 v164, v153, v162
	global_load_b32 v138, v[136:137], off offset:128
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[136:137], s[14:15], v[142:143]
	global_load_b32 v136, v[136:137], off offset:128
	s_wait_loadcnt 0x1
	s_wait_xcnt 0x0
	v_sub_f32_e32 v137, s19, v138
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_min_num_f32_e32 v137, 0, v137
	v_mul_f32_e32 v137, 0x3fb8aa3b, v137
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v137, v137
	s_wait_loadcnt 0x0
	v_nop
	v_mul_f32_e32 v148, v136, v137
	v_mov_b64_e32 v[138:139], v[2:3]
	v_mov_b64_e32 v[136:137], v[0:1]
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_mov_b32 v149, v148 :: v_dual_mov_b32 v151, v148
	v_mov_b32_e32 v150, v148
.LBB0_20:                               ;   Parent Loop BB0_13 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_lshrrev_b32 v165, 5, v137 :: v_dual_lshrrev_b32 v166, 5, v136
	v_dual_lshrrev_b32 v167, 5, v139 :: v_dual_lshrrev_b32 v168, 5, v138
	v_dual_add_nc_u32 v163, -4, v163 :: v_dual_add_nc_u32 v165, v165, v133
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_add_nc_u32 v166, v166, v132 :: v_dual_add_nc_u32 v167, v167, v135
	v_add_nc_u32_e32 v168, v168, v134
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_eq_u32_e32 vcc_lo, 0, v163
	s_clause 0x3
	global_load_u16 v169, v165, s[2:3] scale_offset
	global_load_u16 v170, v166, s[2:3] scale_offset
	global_load_u16 v171, v167, s[2:3] scale_offset
	global_load_u16 v172, v168, s[2:3] scale_offset
	v_add_nc_u32_e32 v139, 0x100, v139
	v_add_nc_u32_e32 v138, 0x100, v138
	v_add_nc_u32_e32 v137, 0x100, v137
	v_add_nc_u32_e32 v136, 0x100, v136
	s_or_b32 s7, vcc_lo, s7
	s_wait_loadcnt 0x3
	s_wait_xcnt 0x1
	v_cvt_f32_f16_e64 v167, v169
	s_wait_loadcnt 0x2
	v_cvt_f32_f16_e64 v166, v170
	s_wait_loadcnt 0x1
	v_cvt_f32_f16_e64 v169, v171
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_f16_e64 v168, v172
	v_pk_mul_f32 v[166:167], v[148:149], v[166:167]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_mul_f32 v[168:169], v[150:151], v[168:169]
	v_cvt_pk_f16_f32 v165, v166, v167
	s_delay_alu instid0(VALU_DEP_2)
	v_cvt_pk_f16_f32 v166, v168, v169
	ds_store_b16 v164, v165
	ds_store_b16_d16_hi v164, v165 offset:128
	ds_store_b16 v164, v166 offset:256
	ds_store_b16_d16_hi v164, v166 offset:384
	v_add_nc_u32_e32 v164, 0x200, v164
	s_and_not1_b32 exec_lo, exec_lo, s7
	s_cbranch_execnz .LBB0_20
; %bb.21:                               ;   in Loop: Header=BB0_13 Depth=1
	s_or_b32 exec_lo, exec_lo, s7
	s_and_saveexec_b32 s7, s12
	s_cbranch_execz .LBB0_11
; %bb.22:                               ;   in Loop: Header=BB0_13 Depth=1
	v_mov_b64_e32 v[132:133], v[146:147]
	v_dual_mov_b32 v135, v156 :: v_dual_add_nc_u32 v134, v161, v162
	s_mov_b32 s13, 0
.LBB0_23:                               ;   Parent Loop BB0_13 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v136, v[132:133], off
	v_add_nc_u32_e32 v135, 64, v135
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[132:133], 4, v[132:133]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xfbf, v135
	s_or_b32 s13, vcc_lo, s13
	s_wait_loadcnt 0x0
	v_fma_mixlo_f16 v136, v148, v136, 0 op_sel_hi:[0,1,0]
	ds_store_b16 v134, v136
	v_add_nc_u32_e32 v134, 0x80, v134
	s_and_not1_b32 exec_lo, exec_lo, s13
	s_cbranch_execnz .LBB0_23
	s_branch .LBB0_11
.LBB0_24:
	v_and_b32_e32 v1, 15, v0
	v_and_or_b32 v0, v0, 32, v157
	s_lshl_b32 s0, s17, 19
	s_lshl_b32 s1, s18, 16
	s_lshl_b32 s2, s16, 13
	v_lshlrev_b32_e32 v1, 2, v1
	s_or_b32 s0, s0, s1
	s_mov_b32 s1, 0
	s_or_b32 s0, s0, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_lshl_b64 s[0:1], s[0:1], 2
	v_lshl_or_b32 v0, v0, 9, v1
	s_add_nc_u64 s[0:1], s[8:9], s[0:1]
	s_clause 0x8
	global_store_b32 v0, v124, s[0:1]
	global_store_b32 v0, v125, s[0:1] offset:512
	global_store_b32 v0, v126, s[0:1] offset:1024
	global_store_b32 v0, v127, s[0:1] offset:1536
	global_store_b32 v0, v128, s[0:1] offset:2048
	global_store_b32 v0, v129, s[0:1] offset:2560
	global_store_b32 v0, v130, s[0:1] offset:3072
	global_store_b32 v0, v116, s[0:1] offset:64
	global_store_b32 v0, v131, s[0:1] offset:3584
	v_or_b32_e32 v1, 64, v0
	v_or_b32_e32 v2, 0x80, v0
	v_or_b32_e32 v3, 0xc0, v0
	s_clause 0xf
	global_store_b32 v1, v117, s[0:1] offset:512
	global_store_b32 v1, v118, s[0:1] offset:1024
	global_store_b32 v1, v119, s[0:1] offset:1536
	global_store_b32 v1, v120, s[0:1] offset:2048
	global_store_b32 v1, v121, s[0:1] offset:2560
	global_store_b32 v1, v122, s[0:1] offset:3072
	global_store_b32 v1, v123, s[0:1] offset:3584
	global_store_b32 v0, v108, s[0:1] offset:128
	global_store_b32 v2, v109, s[0:1] offset:512
	global_store_b32 v2, v110, s[0:1] offset:1024
	global_store_b32 v2, v111, s[0:1] offset:1536
	global_store_b32 v2, v112, s[0:1] offset:2048
	global_store_b32 v2, v113, s[0:1] offset:2560
	global_store_b32 v2, v114, s[0:1] offset:3072
	global_store_b32 v2, v115, s[0:1] offset:3584
	global_store_b32 v0, v100, s[0:1] offset:192
	s_wait_xcnt 0x0
	v_or_b32_e32 v100, 0x100, v0
	s_clause 0x7
	global_store_b32 v3, v101, s[0:1] offset:512
	global_store_b32 v3, v102, s[0:1] offset:1024
	global_store_b32 v3, v103, s[0:1] offset:1536
	global_store_b32 v3, v104, s[0:1] offset:2048
	global_store_b32 v3, v105, s[0:1] offset:2560
	global_store_b32 v3, v106, s[0:1] offset:3072
	global_store_b32 v3, v107, s[0:1] offset:3584
	global_store_b32 v0, v92, s[0:1] offset:256
	s_wait_xcnt 0x0
	v_or_b32_e32 v92, 0x140, v0
	s_clause 0x7
	global_store_b32 v100, v93, s[0:1] offset:512
	global_store_b32 v100, v94, s[0:1] offset:1024
	global_store_b32 v100, v95, s[0:1] offset:1536
	global_store_b32 v100, v96, s[0:1] offset:2048
	global_store_b32 v100, v97, s[0:1] offset:2560
	global_store_b32 v100, v98, s[0:1] offset:3072
	global_store_b32 v100, v99, s[0:1] offset:3584
	global_store_b32 v0, v84, s[0:1] offset:320
	s_wait_xcnt 0x0
	v_or_b32_e32 v84, 0x180, v0
	s_clause 0x7
	global_store_b32 v92, v85, s[0:1] offset:512
	global_store_b32 v92, v86, s[0:1] offset:1024
	global_store_b32 v92, v87, s[0:1] offset:1536
	global_store_b32 v92, v88, s[0:1] offset:2048
	global_store_b32 v92, v89, s[0:1] offset:2560
	global_store_b32 v92, v90, s[0:1] offset:3072
	global_store_b32 v92, v91, s[0:1] offset:3584
	global_store_b32 v0, v76, s[0:1] offset:384
	s_wait_xcnt 0x0
	v_or_b32_e32 v76, 0x1c0, v0
	s_clause 0x3e
	global_store_b32 v84, v77, s[0:1] offset:512
	global_store_b32 v84, v78, s[0:1] offset:1024
	global_store_b32 v84, v79, s[0:1] offset:1536
	global_store_b32 v84, v80, s[0:1] offset:2048
	global_store_b32 v84, v81, s[0:1] offset:2560
	global_store_b32 v84, v82, s[0:1] offset:3072
	global_store_b32 v84, v83, s[0:1] offset:3584
	global_store_b32 v0, v68, s[0:1] offset:448
	global_store_b32 v76, v69, s[0:1] offset:512
	global_store_b32 v76, v70, s[0:1] offset:1024
	global_store_b32 v76, v71, s[0:1] offset:1536
	global_store_b32 v76, v72, s[0:1] offset:2048
	global_store_b32 v76, v73, s[0:1] offset:2560
	global_store_b32 v76, v74, s[0:1] offset:3072
	global_store_b32 v76, v75, s[0:1] offset:3584
	global_store_b32 v0, v60, s[0:1] offset:8192
	global_store_b32 v0, v61, s[0:1] offset:8704
	global_store_b32 v0, v62, s[0:1] offset:9216
	global_store_b32 v0, v63, s[0:1] offset:9728
	global_store_b32 v0, v64, s[0:1] offset:10240
	global_store_b32 v0, v65, s[0:1] offset:10752
	global_store_b32 v0, v66, s[0:1] offset:11264
	global_store_b32 v0, v67, s[0:1] offset:11776
	global_store_b32 v1, v52, s[0:1] offset:8192
	global_store_b32 v1, v53, s[0:1] offset:8704
	global_store_b32 v1, v54, s[0:1] offset:9216
	global_store_b32 v1, v55, s[0:1] offset:9728
	global_store_b32 v1, v56, s[0:1] offset:10240
	global_store_b32 v1, v57, s[0:1] offset:10752
	global_store_b32 v1, v58, s[0:1] offset:11264
	global_store_b32 v1, v59, s[0:1] offset:11776
	global_store_b32 v2, v44, s[0:1] offset:8192
	global_store_b32 v2, v45, s[0:1] offset:8704
	global_store_b32 v2, v46, s[0:1] offset:9216
	global_store_b32 v2, v47, s[0:1] offset:9728
	global_store_b32 v2, v48, s[0:1] offset:10240
	global_store_b32 v2, v49, s[0:1] offset:10752
	global_store_b32 v2, v50, s[0:1] offset:11264
	global_store_b32 v2, v51, s[0:1] offset:11776
	global_store_b32 v3, v36, s[0:1] offset:8192
	global_store_b32 v3, v37, s[0:1] offset:8704
	global_store_b32 v3, v38, s[0:1] offset:9216
	global_store_b32 v3, v39, s[0:1] offset:9728
	global_store_b32 v3, v40, s[0:1] offset:10240
	global_store_b32 v3, v41, s[0:1] offset:10752
	global_store_b32 v3, v42, s[0:1] offset:11264
	global_store_b32 v3, v43, s[0:1] offset:11776
	global_store_b32 v100, v28, s[0:1] offset:8192
	global_store_b32 v100, v29, s[0:1] offset:8704
	global_store_b32 v100, v30, s[0:1] offset:9216
	global_store_b32 v100, v31, s[0:1] offset:9728
	global_store_b32 v100, v32, s[0:1] offset:10240
	global_store_b32 v100, v33, s[0:1] offset:10752
	global_store_b32 v100, v34, s[0:1] offset:11264
	global_store_b32 v100, v35, s[0:1] offset:11776
	global_store_b32 v92, v20, s[0:1] offset:8192
	global_store_b32 v92, v21, s[0:1] offset:8704
	global_store_b32 v92, v22, s[0:1] offset:9216
	global_store_b32 v92, v23, s[0:1] offset:9728
	global_store_b32 v92, v24, s[0:1] offset:10240
	global_store_b32 v92, v25, s[0:1] offset:10752
	global_store_b32 v92, v26, s[0:1] offset:11264
	global_store_b32 v92, v27, s[0:1] offset:11776
	s_clause 0xf
	global_store_b32 v84, v12, s[0:1] offset:8192
	global_store_b32 v84, v13, s[0:1] offset:8704
	global_store_b32 v84, v14, s[0:1] offset:9216
	global_store_b32 v84, v15, s[0:1] offset:9728
	global_store_b32 v84, v16, s[0:1] offset:10240
	global_store_b32 v84, v17, s[0:1] offset:10752
	global_store_b32 v84, v18, s[0:1] offset:11264
	global_store_b32 v84, v19, s[0:1] offset:11776
	global_store_b32 v76, v4, s[0:1] offset:8192
	global_store_b32 v76, v5, s[0:1] offset:8704
	global_store_b32 v76, v6, s[0:1] offset:9216
	global_store_b32 v76, v7, s[0:1] offset:9728
	global_store_b32 v76, v8, s[0:1] offset:10240
	global_store_b32 v76, v9, s[0:1] offset:10752
	global_store_b32 v76, v10, s[0:1] offset:11264
	global_store_b32 v76, v11, s[0:1] offset:11776
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mamba_state_original
		.amdhsa_group_segment_fixed_size 24576
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 173
		.amdhsa_next_free_sgpr 28
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 41
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
	.size	mamba_state_original, .Lfunc_end0-mamba_state_original
                                        ; -- End function
	.set mamba_state_original.num_vgpr, 173
	.set mamba_state_original.num_agpr, 0
	.set mamba_state_original.numbered_sgpr, 28
	.set mamba_state_original.num_named_barrier, 0
	.set mamba_state_original.private_seg_size, 0
	.set mamba_state_original.uses_vcc, 1
	.set mamba_state_original.uses_flat_scratch, 0
	.set mamba_state_original.has_dyn_sized_stack, 0
	.set mamba_state_original.has_recursion, 0
	.set mamba_state_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5212
; TotalNumSgprs: 30
; NumVgprs: 173
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 24576 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 10
; NumSGPRsForWavesPerEU: 30
; NumVGPRsForWavesPerEU: 173
; NamedBarCnt: 0
; Occupancy: 5
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	mamba_scan_original     ; -- Begin function mamba_scan_original
	.globl	mamba_scan_original
	.p2align	8
	.type	mamba_scan_original,@function
mamba_scan_original:                    ; @mamba_scan_original
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x40010
	s_and_b32 s3, ttmp7, 0xffff
	s_add_co_i32 s2, s2, 1
	s_bfe_u32 s5, ttmp6, 0x4000c
	s_mul_i32 s2, s3, s2
	s_bfe_u32 s4, ttmp6, 0x40004
	s_add_co_i32 s5, s5, 1
	s_add_co_i32 s4, s4, s2
	s_and_b32 s2, ttmp6, 15
	s_mul_i32 s5, ttmp9, s5
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s2, s2, s5
	s_cmp_eq_u32 s6, 0
	v_dual_lshlrev_b32 v156, 1, v0 :: v_dual_bitop2_b32 v158, 31, v0 bitop3:0x40
	s_cselect_b32 s14, ttmp9, s2
	s_cselect_b32 s2, s3, s4
	s_bfe_u32 s3, ttmp6, 0x40014
	s_lshr_b32 s8, ttmp7, 16
	s_add_co_i32 s3, s3, 1
	s_bfe_u32 s4, ttmp6, 0x40008
	s_mul_i32 s3, s8, s3
	v_or_b32_e32 v157, 0xffffffc0, v0
	s_add_co_i32 s3, s4, s3
	s_cmp_eq_u32 s6, 0
	s_load_b128 s[4:7], s[0:1], 0x40
	s_cselect_b32 s16, s8, s3
	s_lshr_b32 s17, s2, 2
	s_and_b32 s15, s2, 3
	s_lshl_b32 s2, s17, 13
	s_lshl_b32 s3, s14, 11
	s_lshr_b32 s12, s16, 2
	s_lshl_b32 s8, s15, 17
	s_add_co_i32 s2, s2, s3
	s_lshl_b32 s9, s12, 5
	s_add_co_i32 s2, s2, s8
	s_mov_b32 s3, 0
	s_add_co_i32 s2, s2, s9
	v_dual_mov_b32 v1, v156 :: v_dual_mov_b32 v2, v157
	s_lshl_b64 s[8:9], s[2:3], 1
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[4:5], s[4:5], s[8:9]
.LBB1_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x7c0, v1, v158
	v_add_nc_u32_e32 v2, 64, v2
	global_load_u16 v3, v3, s[4:5] scale_offset
	v_cmp_lt_u32_e32 vcc_lo, 0x3bf, v2
	s_or_b32 s3, vcc_lo, s3
	s_wait_loadcnt 0x0
	ds_store_b16 v1, v3 offset:16384
	v_add_nc_u32_e32 v1, 0x80, v1
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s3
	s_cbranch_execnz .LBB1_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s3
	v_dual_mov_b32 v6, 64 :: v_dual_bitop2_b32 v1, 64, v0 bitop3:0x54
	s_lshl_b32 s18, s15, 19
	s_lshl_b32 s2, s17, 15
	s_lshl_b32 s3, s16, 12
	s_add_co_i32 s18, s18, s2
	v_mov_b64_e32 v[4:5], v[0:1]
	s_add_co_i32 s2, s18, s3
	s_mov_b32 s3, 0
	v_dual_mov_b32 v3, 0 :: v_dual_mov_b32 v7, v156
	s_lshl_b64 s[4:5], s[2:3], 2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_nc_u64 s[4:5], s[6:7], s[4:5]
.LBB1_3:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v2, v4 :: v_dual_add_nc_u32 v6, -2, v6
	v_add_nc_u32_e32 v4, 0x80, v4
	v_lshl_add_u64 v[8:9], v[2:3], 2, s[4:5]
	v_dual_mov_b32 v2, v5 :: v_dual_add_nc_u32 v5, 0x80, v5
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cmp_eq_u32_e32 vcc_lo, 0, v6
	v_lshl_add_u64 v[10:11], v[2:3], 2, s[4:5]
	s_clause 0x1
	global_load_b32 v2, v[8:9], off
	global_load_b32 v12, v[10:11], off
	s_or_b32 s3, vcc_lo, s3
	s_wait_loadcnt 0x0
	v_cvt_pk_f16_f32 v2, v2, v12
	ds_store_b16 v7, v2
	ds_store_b16_d16_hi v7, v2 offset:128
	v_add_nc_u32_e32 v7, 0x100, v7
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s3
	s_cbranch_execnz .LBB1_3
; %bb.4:
	s_or_b32 exec_lo, exec_lo, s3
	v_lshl_or_b32 v70, 64, 6, v0
	s_mov_b32 s2, exec_lo
	v_cmpx_ne_u32_e64 64, 64
	s_cbranch_execz .LBB1_7
; %bb.5:
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v2, 2, v70
	s_movk_i32 s3, 0x3f00
	v_subrev_nc_u32_e32 v4, 64, v70
	v_and_or_b32 v5, 0x2000, s3, v156
	s_mov_b32 s3, 0
	v_add_nc_u64_e32 v[2:3], s[4:5], v[2:3]
.LBB1_6:                                ; =>This Inner Loop Header: Depth=1
	global_load_b32 v6, v[2:3], off
	v_add_nc_u32_e32 v4, 64, v4
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 0x100, v[2:3]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xfbf, v4
	s_or_b32 s3, vcc_lo, s3
	s_wait_loadcnt 0x0
	v_cvt_f16_f32_e32 v6, v6
	ds_store_b16 v5, v6
	v_add_nc_u32_e32 v5, 0x80, v5
	s_and_not1_b32 exec_lo, exec_lo, s3
	s_cbranch_execnz .LBB1_6
.LBB1_7:
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_bitop2_b32 v159, 15, v0 bitop3:0x40
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v4, 6, v0 :: v_dual_bitop2_b32 v161, 8, v2 bitop3:0x40
	v_and_b32_e32 v160, 16, v2
	s_load_b256 s[4:11], s[0:1], 0x18
	v_lshlrev_b32_e32 v3, 1, v161
	s_lshl_b32 s3, s17, 7
	s_delay_alu instid0(VALU_DEP_2)
	v_or_b32_e32 v2, v160, v159
	s_lshl_b32 s20, s16, 11
	s_mov_b32 s13, 0
	v_and_or_b32 v162, 0x3c0, v4, v3
	s_lshl_b32 s2, s15, 14
	v_lshl_or_b32 v71, v2, 6, v3
	s_add_co_i32 s20, s3, s20
	s_lshl_b32 s19, s14, 5
	ds_load_b128 v[72:75], v71 offset:16384
	ds_load_b128 v[76:79], v71 offset:16416
	ds_load_b128 v[2:5], v162
	ds_load_b128 v[6:9], v162 offset:32
	s_mov_b32 s3, s13
	s_add_co_i32 s2, s20, s2
	s_lshl_b32 s12, s12, 14
	s_lshl_b64 s[2:3], s[2:3], 2
	s_lshl_b32 s20, s14, 12
	v_or_b32_e32 v164, 0x4000, v156
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[10:11], s[10:11], s[2:3]
	s_add_nc_u64 s[8:9], s[8:9], s[2:3]
	s_load_b128 s[0:3], s[0:1], 0x0
	s_add_co_i32 s12, s12, s20
	v_or_b32_e32 v165, 0x4000, v71
	s_add_co_i32 s12, s12, s18
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[60:67], v[72:79], v[2:9], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[2:5], v162 offset:1024
	ds_load_b128 v[6:9], v162 offset:1056
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[52:59], v[72:79], v[2:9], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[2:5], v162 offset:2048
	ds_load_b128 v[6:9], v162 offset:2080
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[44:51], v[72:79], v[2:9], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[2:5], v162 offset:3072
	ds_load_b128 v[6:9], v162 offset:3104
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[36:43], v[72:79], v[2:9], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[2:5], v162 offset:4096
	ds_load_b128 v[6:9], v162 offset:4128
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[28:35], v[72:79], v[2:9], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[2:5], v162 offset:5120
	ds_load_b128 v[6:9], v162 offset:5152
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[20:27], v[72:79], v[2:9], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[12:15], v162 offset:6144
	ds_load_b128 v[16:19], v162 offset:6176
	v_nop
	v_nop
	v_nop
	v_nop
	v_mov_b32_e32 v3, 0
	v_or3_b32 v2, v161, s19, v160
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[88:89], v[2:3], 2, s[10:11]
	v_lshlrev_b32_e32 v2, 2, v158
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[4:11], v[72:79], v[12:19], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[80:83], v162 offset:7168
	ds_load_b128 v[84:87], v162 offset:7200
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[12:19], v[72:79], v[80:87], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	s_clause 0x3
	global_load_b128 v[132:135], v[88:89], off offset:16
	global_load_b128 v[136:139], v[88:89], off
	global_load_b32 v68, v158, s[10:11] scale_offset
	global_load_b32 v69, v158, s[8:9] scale_offset
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshrrev_b32_e32 v72, 5, v0
	v_add_nc_u64_e32 v[148:149], s[10:11], v[2:3]
	v_add_nc_u64_e32 v[150:151], s[8:9], v[2:3]
	s_wait_xcnt 0x0
	s_lshl_b64 s[8:9], s[12:13], 2
	v_mov_b32_e32 v73, v157
	v_lshl_or_b32 v2, v72, 9, v2
	v_dual_mov_b32 v72, v164 :: v_dual_bitop2_b32 v163, s19, v72 bitop3:0x54
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[8:9], s[0:1], s[8:9]
	s_delay_alu instid0(VALU_DEP_2) | instid1(SALU_CYCLE_1)
	v_add_nc_u64_e32 v[2:3], s[8:9], v[2:3]
	s_delay_alu instid0(VALU_DEP_2)
	v_mov_b32_e32 v71, v163
.LBB1_8:                                ; =>This Inner Loop Header: Depth=1
	global_load_b32 v74, v71, s[10:11] scale_offset
	global_load_b32 v75, v[2:3], off
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[2:3], 0x400, v[2:3]
	v_dual_add_nc_u32 v73, 64, v73 :: v_dual_add_nc_u32 v71, 2, v71
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 0x3bf, v73
	s_or_b32 s13, vcc_lo, s13
	s_wait_loadcnt 0x1
	v_sub_f32_e32 v74, v74, v68
	v_min_num_f32_e32 v74, 0, v74
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v74, 0x3fb8aa3b, v74
	v_exp_f32_e32 v74, v74
	s_wait_loadcnt 0x0
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v74, v75, v74
	v_fma_mixlo_f16 v74, v69, v74, 0
	ds_store_b16 v72, v74
	v_add_nc_u32_e32 v72, 0x80, v72
	s_and_not1_b32 exec_lo, exec_lo, s13
	s_cbranch_execnz .LBB1_8
; %bb.9:
	s_or_b32 exec_lo, exec_lo, s13
	v_or_b32_e32 v3, 0xc0, v0
	v_or_b32_e32 v2, 0x80, v0
	s_lshl_b32 s0, s17, 17
	s_lshl_b32 s1, s16, 7
	v_dual_mov_b32 v77, 64 :: v_dual_lshlrev_b32 v76, 10, v158
	s_lshl_b32 s12, s15, 21
	s_add_co_i32 s0, s0, s1
	v_mov_b64_e32 v[74:75], v[2:3]
	v_mov_b64_e32 v[72:73], v[0:1]
	s_add_co_i32 s0, s0, s12
	s_mov_b32 s1, 0
	v_dual_mov_b32 v69, v76 :: v_dual_mov_b32 v68, v76
	v_dual_mov_b32 v71, v76 :: v_dual_mov_b32 v78, v156
	s_lshl_b64 s[12:13], s[0:1], 1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_nc_u64 s[2:3], s[2:3], s[12:13]
.LBB1_10:                               ; =>This Inner Loop Header: Depth=1
	v_dual_lshrrev_b32 v79, 5, v72 :: v_dual_lshrrev_b32 v80, 5, v73
	v_dual_lshrrev_b32 v81, 5, v74 :: v_dual_lshrrev_b32 v82, 5, v75
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_add_nc_u32 v77, -4, v77 :: v_dual_add_nc_u32 v79, v79, v76
	v_dual_add_nc_u32 v80, v80, v69 :: v_dual_add_nc_u32 v81, v81, v68
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_nc_u32_e32 v82, v82, v71
	v_cmp_eq_u32_e32 vcc_lo, 0, v77
	s_clause 0x3
	global_load_u16 v83, v79, s[2:3] scale_offset
	global_load_u16 v84, v80, s[2:3] scale_offset
	global_load_u16 v85, v81, s[2:3] scale_offset
	global_load_u16 v86, v82, s[2:3] scale_offset
	v_add_nc_u32_e32 v75, 0x100, v75
	v_add_nc_u32_e32 v74, 0x100, v74
	v_add_nc_u32_e32 v73, 0x100, v73
	v_add_nc_u32_e32 v72, 0x100, v72
	s_or_b32 s1, vcc_lo, s1
	s_wait_loadcnt 0x3
	ds_store_b16 v78, v83
	s_wait_loadcnt 0x2
	ds_store_b16 v78, v84 offset:128
	s_wait_loadcnt 0x1
	ds_store_b16 v78, v85 offset:256
	s_wait_loadcnt 0x0
	ds_store_b16 v78, v86 offset:384
	v_add_nc_u32_e32 v78, 0x200, v78
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB1_10
; %bb.11:
	s_or_b32 exec_lo, exec_lo, s1
	v_cmp_ne_u32_e64 s1, 64, 64
	v_subrev_nc_u32_e32 v166, 64, v70
	v_lshrrev_b32_e32 v75, 5, v70
	s_and_saveexec_b32 s12, s1
	s_cbranch_execz .LBB1_14
; %bb.12:
	s_delay_alu instid0(VALU_DEP_1)
	v_add_lshl_u32 v68, v75, v76, 1
	v_mov_b32_e32 v69, 0
	s_movk_i32 s13, 0x3e00
	v_subrev_nc_u32_e32 v70, 64, v70
	v_and_or_b32 v71, 0x2000, s13, v156
	s_mov_b32 s13, 0
	v_add_nc_u64_e32 v[68:69], s[2:3], v[68:69]
.LBB1_13:                               ; =>This Inner Loop Header: Depth=1
	global_load_u16 v72, v[68:69], off
	v_add_nc_u32_e32 v70, 64, v70
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[68:69], 4, v[68:69]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xfbf, v70
	s_or_b32 s13, vcc_lo, s13
	s_wait_loadcnt 0x0
	ds_store_b16 v71, v72
	v_add_nc_u32_e32 v71, 0x80, v71
	s_and_not1_b32 exec_lo, exec_lo, s13
	s_cbranch_execnz .LBB1_13
.LBB1_14:
	s_or_b32 exec_lo, exec_lo, s12
	v_dual_mov_b32 v69, 0 :: v_dual_lshlrev_b32 v68, 2, v0
	s_movk_i32 s12, 0x3e00
	s_wait_dscnt 0x0
	v_and_or_b32 v167, 0x2000, s12, v156
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_and_or_b32 v68, 0x80, v68, v158
	v_dual_mov_b32 v70, v69 :: v_dual_mov_b32 v71, v69
	v_dual_mov_b32 v72, v69 :: v_dual_mov_b32 v73, v69
	v_dual_mov_b32 v74, v69 :: v_dual_lshlrev_b32 v68, 2, v68
	v_dual_mov_b32 v77, v69 :: v_dual_mov_b32 v78, v69
	v_dual_mov_b32 v79, v69 :: v_dual_mov_b32 v80, v69
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_add_nc_u64_e32 v[84:85], s[8:9], v[68:69]
	v_add_lshl_u32 v68, v75, v76, 1
	v_dual_mov_b32 v75, v69 :: v_dual_mov_b32 v76, v69
	v_dual_mov_b32 v81, v69 :: v_dual_mov_b32 v82, v69
	v_add_nc_u64_e32 v[86:87], s[2:3], v[68:69]
	v_add_nc_u64_e32 v[152:153], 0x80, v[84:85]
	v_dual_mov_b32 v68, v69 :: v_dual_mov_b32 v83, v69
	v_dual_mov_b32 v84, v69 :: v_dual_mov_b32 v85, v69
	v_dual_mov_b32 v88, v69 :: v_dual_mov_b32 v89, v69
	v_add_nc_u64_e32 v[154:155], 0x10000, v[86:87]
	v_dual_mov_b32 v86, v69 :: v_dual_mov_b32 v87, v69
	v_dual_mov_b32 v90, v69 :: v_dual_mov_b32 v91, v69
	v_dual_mov_b32 v92, v69 :: v_dual_mov_b32 v93, v69
	v_dual_mov_b32 v94, v69 :: v_dual_mov_b32 v95, v69
	v_dual_mov_b32 v96, v69 :: v_dual_mov_b32 v97, v69
	v_dual_mov_b32 v98, v69 :: v_dual_mov_b32 v99, v69
	v_dual_mov_b32 v100, v69 :: v_dual_mov_b32 v101, v69
	v_dual_mov_b32 v102, v69 :: v_dual_mov_b32 v103, v69
	v_dual_mov_b32 v104, v69 :: v_dual_mov_b32 v105, v69
	v_dual_mov_b32 v106, v69 :: v_dual_mov_b32 v107, v69
	v_dual_mov_b32 v108, v69 :: v_dual_mov_b32 v109, v69
	v_dual_mov_b32 v110, v69 :: v_dual_mov_b32 v111, v69
	v_dual_mov_b32 v112, v69 :: v_dual_mov_b32 v113, v69
	v_dual_mov_b32 v114, v69 :: v_dual_mov_b32 v115, v69
	v_dual_mov_b32 v116, v69 :: v_dual_mov_b32 v117, v69
	v_dual_mov_b32 v118, v69 :: v_dual_mov_b32 v119, v69
	v_dual_mov_b32 v120, v69 :: v_dual_mov_b32 v121, v69
	v_dual_mov_b32 v122, v69 :: v_dual_mov_b32 v123, v69
	v_dual_mov_b32 v124, v69 :: v_dual_mov_b32 v125, v69
	v_dual_mov_b32 v126, v69 :: v_dual_mov_b32 v127, v69
	v_dual_mov_b32 v128, v69 :: v_dual_mov_b32 v129, v69
	v_dual_mov_b32 v130, v69 :: v_dual_mov_b32 v131, v69
	s_mov_b32 s9, 0
	s_mov_b32 s12, -1
	s_mov_b32 s8, s9
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB1_17
.LBB1_15:                               ;   in Loop: Header=BB1_17 Depth=1
	s_or_b32 exec_lo, exec_lo, s16
.LBB1_16:                               ;   in Loop: Header=BB1_17 Depth=1
	s_bfe_u32 s8, s8, 0x10005
	v_add_nc_u64_e32 v[152:153], 0x80, v[152:153]
	v_nop
	v_nop
	v_nop
	v_lshl_add_u32 v144, s8, 11, v165
	v_lshl_or_b32 v176, s8, 13, v162
	v_add_nc_u64_e32 v[154:155], 0x10000, v[154:155]
	s_xor_b32 s12, s12, -1
	s_and_not1_b32 vcc_lo, exec_lo, s15
	ds_load_b128 v[140:143], v144
	ds_load_b128 v[144:147], v144 offset:32
	ds_load_b128 v[168:171], v176
	ds_load_b128 v[172:175], v176 offset:32
	s_mov_b32 s8, s13
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[124:131], v[140:147], v[168:175], v[124:131]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:1024
	ds_load_b128 v[172:175], v176 offset:1056
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[116:123], v[140:147], v[168:175], v[116:123]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:2048
	ds_load_b128 v[172:175], v176 offset:2080
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[108:115], v[140:147], v[168:175], v[108:115]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:3072
	ds_load_b128 v[172:175], v176 offset:3104
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[100:107], v[140:147], v[168:175], v[100:107]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:4096
	ds_load_b128 v[172:175], v176 offset:4128
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[92:99], v[140:147], v[168:175], v[92:99]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:5120
	ds_load_b128 v[172:175], v176 offset:5152
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[84:91], v[140:147], v[168:175], v[84:91]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:6144
	ds_load_b128 v[172:175], v176 offset:6176
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[76:83], v[140:147], v[168:175], v[76:83]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_b128 v[168:171], v176 offset:7168
	ds_load_b128 v[172:175], v176 offset:7200
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[68:75], v[140:147], v[168:175], v[68:75]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccz .LBB1_25
.LBB1_17:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_19 Depth 2
                                        ;     Child Loop BB1_21 Depth 2
                                        ;     Child Loop BB1_24 Depth 2
	s_add_co_i32 s13, s8, 32
	s_cmp_gt_u32 s8, 0x5f
	s_cselect_b32 s15, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 vcc_lo, exec_lo, s15
	s_cbranch_vccnz .LBB1_16
; %bb.18:                               ;   in Loop: Header=BB1_17 Depth=1
	s_lshl_b64 s[16:17], s[8:9], 2
	v_nop
	v_nop
	v_nop
	v_nop
	v_cndmask_b32_e64 v143, 0, 1, s12
	v_add_nc_u64_e32 v[140:141], s[16:17], v[148:149]
	v_add_nc_u64_e32 v[146:147], s[16:17], v[150:151]
	s_mov_b32 s16, 0
	global_load_b32 v142, v[140:141], off offset:128
	global_load_b32 v144, v[146:147], off offset:128
	s_wait_xcnt 0x1
	v_mov_b64_e32 v[140:141], v[152:153]
	v_lshl_add_u32 v145, v143, 11, v164
	s_wait_xcnt 0x0
	v_dual_mov_b32 v146, v163 :: v_dual_mov_b32 v147, v157
.LBB1_19:                               ;   Parent Loop BB1_17 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_b32 v168, v146, s[10:11] scale_offset
	global_load_b32 v169, v[140:141], off
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[140:141], 0x400, v[140:141]
	v_dual_add_nc_u32 v147, 64, v147 :: v_dual_add_nc_u32 v146, 2, v146
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 0x3bf, v147
	s_or_b32 s16, vcc_lo, s16
	s_wait_loadcnt 0x1
	v_sub_f32_e32 v168, v168, v142
	v_min_num_f32_e32 v168, 0, v168
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v168, 0x3fb8aa3b, v168
	v_exp_f32_e32 v168, v168
	s_wait_loadcnt 0x0
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v168, v169, v168
	v_fma_mixlo_f16 v168, v144, v168, 0
	ds_store_b16 v145, v168
	v_add_nc_u32_e32 v145, 0x80, v145
	s_and_not1_b32 exec_lo, exec_lo, s16
	s_cbranch_execnz .LBB1_19
; %bb.20:                               ;   in Loop: Header=BB1_17 Depth=1
	s_or_b32 exec_lo, exec_lo, s16
	v_dual_lshlrev_b32 v168, 13, v143 :: v_dual_bitop2_b32 v140, s13, v158 bitop3:0x54
	v_mov_b64_e32 v[146:147], v[2:3]
	v_mov_b64_e32 v[144:145], v[0:1]
	s_mov_b32 s16, 0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v169, 64 :: v_dual_lshlrev_b32 v140, 10, v140
	v_or_b32_e32 v170, v156, v168
	v_dual_mov_b32 v141, v140 :: v_dual_mov_b32 v142, v140
	v_mov_b32_e32 v143, v140
.LBB1_21:                               ;   Parent Loop BB1_17 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_dual_lshrrev_b32 v171, 5, v144 :: v_dual_lshrrev_b32 v172, 5, v145
	v_dual_lshrrev_b32 v173, 5, v146 :: v_dual_lshrrev_b32 v174, 5, v147
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_add_nc_u32 v169, -4, v169 :: v_dual_add_nc_u32 v171, v171, v140
	v_dual_add_nc_u32 v172, v172, v141 :: v_dual_add_nc_u32 v173, v173, v142
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_nc_u32_e32 v174, v174, v143
	v_cmp_eq_u32_e32 vcc_lo, 0, v169
	s_clause 0x3
	global_load_u16 v175, v171, s[2:3] scale_offset
	global_load_u16 v176, v172, s[2:3] scale_offset
	global_load_u16 v177, v173, s[2:3] scale_offset
	global_load_u16 v178, v174, s[2:3] scale_offset
	v_add_nc_u32_e32 v147, 0x100, v147
	v_add_nc_u32_e32 v146, 0x100, v146
	v_add_nc_u32_e32 v145, 0x100, v145
	v_add_nc_u32_e32 v144, 0x100, v144
	s_or_b32 s16, vcc_lo, s16
	s_wait_loadcnt 0x3
	ds_store_b16 v170, v175
	s_wait_loadcnt 0x2
	ds_store_b16 v170, v176 offset:128
	s_wait_loadcnt 0x1
	ds_store_b16 v170, v177 offset:256
	s_wait_loadcnt 0x0
	ds_store_b16 v170, v178 offset:384
	v_add_nc_u32_e32 v170, 0x200, v170
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s16
	s_cbranch_execnz .LBB1_21
; %bb.22:                               ;   in Loop: Header=BB1_17 Depth=1
	s_or_b32 exec_lo, exec_lo, s16
	s_and_saveexec_b32 s16, s1
	s_cbranch_execz .LBB1_15
; %bb.23:                               ;   in Loop: Header=BB1_17 Depth=1
	v_mov_b64_e32 v[140:141], v[154:155]
	v_dual_mov_b32 v143, v166 :: v_dual_add_nc_u32 v142, v167, v168
	s_mov_b32 s17, 0
.LBB1_24:                               ;   Parent Loop BB1_17 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v144, v[140:141], off
	v_add_nc_u32_e32 v143, 64, v143
	s_wait_xcnt 0x0
	v_add_nc_u64_e32 v[140:141], 4, v[140:141]
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xfbf, v143
	s_or_b32 s17, vcc_lo, s17
	s_wait_loadcnt 0x0
	ds_store_b16 v142, v144
	v_add_nc_u32_e32 v142, 0x80, v142
	s_and_not1_b32 exec_lo, exec_lo, s17
	s_cbranch_execnz .LBB1_24
	s_branch .LBB1_15
.LBB1_25:
	v_dual_mul_f32 v0, 0x3fb8aa3b, v135 :: v_dual_mul_f32 v1, 0x3fb8aa3b, v136
	v_dual_mul_f32 v2, 0x3fb8aa3b, v137 :: v_dual_mul_f32 v3, 0x3fb8aa3b, v138
	v_dual_mul_f32 v135, 0x3fb8aa3b, v139 :: v_dual_mul_f32 v132, 0x3fb8aa3b, v132
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v1, v1
	v_exp_f32_e32 v2, v2
	v_dual_lshlrev_b32 v137, 1, v159 :: v_dual_bitop2_b32 v136, v160, v161 bitop3:0x54
	s_lshl_b32 s2, s14, 15
	v_exp_f32_e32 v3, v3
	v_exp_f32_e32 v135, v135
	v_dual_mul_f32 v133, 0x3fb8aa3b, v133 :: v_dual_mul_f32 v134, 0x3fb8aa3b, v134
	s_mov_b32 s1, 0
	s_add_co_i32 s0, s0, s2
	v_fma_mixlo_f16 v60, v60, v1, v124
	v_lshl_or_b32 v124, v136, 11, v137
	v_mov_b32_e32 v136, 0
	v_fma_mixlo_f16 v61, v61, v2, v125
	s_lshl_b64 s[2:3], s[0:1], 1
	v_exp_f32_e32 v132, v132
	s_add_nc_u64 s[0:1], s[4:5], s[2:3]
	v_exp_f32_e32 v133, v133
	s_add_nc_u64 s[2:3], s[6:7], s[2:3]
	global_store_b16 v124, v60, s[0:1]
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v60, v62, v3, v126
	s_clause 0x1
	global_store_b16 v124, v136, s[2:3]
	global_store_b16 v124, v61, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v61, v63, v135, v127
	v_exp_f32_e32 v0, v0
	v_exp_f32_e32 v134, v134
	s_clause 0x1
	global_store_b16 v124, v136, s[2:3] offset:2048
	global_store_b16 v124, v60, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v60, v64, v132, v128
	s_clause 0x1
	global_store_b16 v124, v136, s[2:3] offset:4096
	global_store_b16 v124, v61, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v61, v65, v133, v129
	s_clause 0x1
	global_store_b16 v124, v136, s[2:3] offset:6144
	global_store_b16 v124, v60, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v60, v66, v134, v130
	s_clause 0x1
	global_store_b16 v124, v136, s[2:3] offset:8192
	global_store_b16 v124, v61, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v61, v67, v0, v131
	v_fma_mixlo_f16 v52, v52, v1, v116
	v_fma_mixlo_f16 v53, v53, v2, v117
	s_clause 0x2
	global_store_b16 v124, v136, s[2:3] offset:10240
	global_store_b16 v124, v60, s[0:1] offset:12288
	global_store_b16 v124, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v60, 32, v124
	s_clause 0x2
	global_store_b16 v124, v61, s[0:1] offset:14336
	global_store_b16 v124, v136, s[2:3] offset:14336
	global_store_b16 v124, v52, s[0:1] offset:32
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v52, v54, v3, v118
	global_store_b16 v124, v136, s[2:3] offset:32
	global_store_b16 v60, v53, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v53, v55, v135, v119
	s_clause 0x1
	global_store_b16 v60, v136, s[2:3] offset:2048
	global_store_b16 v60, v52, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v52, v56, v132, v120
	s_clause 0x1
	global_store_b16 v60, v136, s[2:3] offset:4096
	global_store_b16 v60, v53, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v53, v57, v133, v121
	s_clause 0x1
	global_store_b16 v60, v136, s[2:3] offset:6144
	global_store_b16 v60, v52, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v52, v58, v134, v122
	s_clause 0x1
	global_store_b16 v60, v136, s[2:3] offset:8192
	global_store_b16 v60, v53, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v53, v59, v0, v123
	v_fma_mixlo_f16 v44, v44, v1, v108
	v_fma_mixlo_f16 v45, v45, v2, v109
	s_clause 0x2
	global_store_b16 v60, v136, s[2:3] offset:10240
	global_store_b16 v60, v52, s[0:1] offset:12288
	global_store_b16 v60, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v52, 64, v124
	s_clause 0x1
	global_store_b16 v60, v53, s[0:1] offset:14336
	global_store_b16 v60, v136, s[2:3] offset:14336
	global_store_b16 v124, v44, s[0:1] offset:64
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v44, v46, v3, v110
	global_store_b16 v124, v136, s[2:3] offset:64
	global_store_b16 v52, v45, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v45, v47, v135, v111
	s_clause 0x1
	global_store_b16 v52, v136, s[2:3] offset:2048
	global_store_b16 v52, v44, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v44, v48, v132, v112
	s_clause 0x1
	global_store_b16 v52, v136, s[2:3] offset:4096
	global_store_b16 v52, v45, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v45, v49, v133, v113
	s_clause 0x1
	global_store_b16 v52, v136, s[2:3] offset:6144
	global_store_b16 v52, v44, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v44, v50, v134, v114
	s_clause 0x1
	global_store_b16 v52, v136, s[2:3] offset:8192
	global_store_b16 v52, v45, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v45, v51, v0, v115
	v_fma_mixlo_f16 v36, v36, v1, v100
	v_fma_mixlo_f16 v37, v37, v2, v101
	s_clause 0x2
	global_store_b16 v52, v136, s[2:3] offset:10240
	global_store_b16 v52, v44, s[0:1] offset:12288
	global_store_b16 v52, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v44, 0x60, v124
	s_clause 0x1
	global_store_b16 v52, v45, s[0:1] offset:14336
	global_store_b16 v52, v136, s[2:3] offset:14336
	global_store_b16 v124, v36, s[0:1] offset:96
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v36, v38, v3, v102
	global_store_b16 v124, v136, s[2:3] offset:96
	global_store_b16 v44, v37, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v37, v39, v135, v103
	s_clause 0x1
	global_store_b16 v44, v136, s[2:3] offset:2048
	global_store_b16 v44, v36, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v36, v40, v132, v104
	s_clause 0x1
	global_store_b16 v44, v136, s[2:3] offset:4096
	global_store_b16 v44, v37, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v37, v41, v133, v105
	s_clause 0x1
	global_store_b16 v44, v136, s[2:3] offset:6144
	global_store_b16 v44, v36, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v36, v42, v134, v106
	s_clause 0x1
	global_store_b16 v44, v136, s[2:3] offset:8192
	global_store_b16 v44, v37, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v37, v43, v0, v107
	v_fma_mixlo_f16 v28, v28, v1, v92
	v_fma_mixlo_f16 v29, v29, v2, v93
	s_clause 0x2
	global_store_b16 v44, v136, s[2:3] offset:10240
	global_store_b16 v44, v36, s[0:1] offset:12288
	global_store_b16 v44, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v36, 0x80, v124
	s_clause 0x1
	global_store_b16 v44, v37, s[0:1] offset:14336
	global_store_b16 v44, v136, s[2:3] offset:14336
	global_store_b16 v124, v28, s[0:1] offset:128
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v28, v30, v3, v94
	global_store_b16 v124, v136, s[2:3] offset:128
	global_store_b16 v36, v29, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v29, v31, v135, v95
	s_clause 0x1
	global_store_b16 v36, v136, s[2:3] offset:2048
	global_store_b16 v36, v28, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v28, v32, v132, v96
	s_clause 0x1
	global_store_b16 v36, v136, s[2:3] offset:4096
	global_store_b16 v36, v29, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v29, v33, v133, v97
	s_clause 0x1
	global_store_b16 v36, v136, s[2:3] offset:6144
	global_store_b16 v36, v28, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v28, v34, v134, v98
	s_clause 0x1
	global_store_b16 v36, v136, s[2:3] offset:8192
	global_store_b16 v36, v29, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v29, v35, v0, v99
	v_fma_mixlo_f16 v20, v20, v1, v84
	v_fma_mixlo_f16 v21, v21, v2, v85
	s_clause 0x2
	global_store_b16 v36, v136, s[2:3] offset:10240
	global_store_b16 v36, v28, s[0:1] offset:12288
	global_store_b16 v36, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v28, 0xa0, v124
	s_clause 0x1
	global_store_b16 v36, v29, s[0:1] offset:14336
	global_store_b16 v36, v136, s[2:3] offset:14336
	global_store_b16 v124, v20, s[0:1] offset:160
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v20, v22, v3, v86
	global_store_b16 v124, v136, s[2:3] offset:160
	global_store_b16 v28, v21, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v21, v23, v135, v87
	s_clause 0x1
	global_store_b16 v28, v136, s[2:3] offset:2048
	global_store_b16 v28, v20, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v20, v24, v132, v88
	s_clause 0x1
	global_store_b16 v28, v136, s[2:3] offset:4096
	global_store_b16 v28, v21, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v21, v25, v133, v89
	s_clause 0x1
	global_store_b16 v28, v136, s[2:3] offset:6144
	global_store_b16 v28, v20, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v20, v26, v134, v90
	s_clause 0x1
	global_store_b16 v28, v136, s[2:3] offset:8192
	global_store_b16 v28, v21, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v21, v27, v0, v91
	v_fma_mixlo_f16 v4, v4, v1, v76
	v_fma_mixlo_f16 v5, v5, v2, v77
	s_clause 0x2
	global_store_b16 v28, v136, s[2:3] offset:10240
	global_store_b16 v28, v20, s[0:1] offset:12288
	global_store_b16 v28, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v20, 0xc0, v124
	s_clause 0x1
	global_store_b16 v28, v21, s[0:1] offset:14336
	global_store_b16 v28, v136, s[2:3] offset:14336
	global_store_b16 v124, v4, s[0:1] offset:192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v6, v3, v78
	global_store_b16 v124, v136, s[2:3] offset:192
	global_store_b16 v20, v5, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v5, v7, v135, v79
	s_clause 0x1
	global_store_b16 v20, v136, s[2:3] offset:2048
	global_store_b16 v20, v4, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v8, v132, v80
	s_clause 0x1
	global_store_b16 v20, v136, s[2:3] offset:4096
	global_store_b16 v20, v5, s[0:1] offset:6144
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v5, v9, v133, v81
	s_clause 0x1
	global_store_b16 v20, v136, s[2:3] offset:6144
	global_store_b16 v20, v4, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v10, v134, v82
	s_clause 0x1
	global_store_b16 v20, v136, s[2:3] offset:8192
	global_store_b16 v20, v5, s[0:1] offset:10240
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v5, v11, v0, v83
	v_fma_mixlo_f16 v1, v12, v1, v68
	v_fma_mixlo_f16 v2, v13, v2, v69
	s_clause 0x2
	global_store_b16 v20, v136, s[2:3] offset:10240
	global_store_b16 v20, v4, s[0:1] offset:12288
	global_store_b16 v20, v136, s[2:3] offset:12288
	s_wait_xcnt 0x1
	v_or_b32_e32 v4, 0xe0, v124
	s_clause 0x1
	global_store_b16 v20, v5, s[0:1] offset:14336
	global_store_b16 v20, v136, s[2:3] offset:14336
	global_store_b16 v124, v1, s[0:1] offset:224
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v1, v14, v3, v70
	global_store_b16 v124, v136, s[2:3] offset:224
	global_store_b16 v4, v2, s[0:1] offset:2048
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v2, v15, v135, v71
	s_clause 0x1
	global_store_b16 v4, v136, s[2:3] offset:2048
	global_store_b16 v4, v1, s[0:1] offset:4096
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v1, v16, v132, v72
	s_clause 0x2
	global_store_b16 v4, v136, s[2:3] offset:4096
	global_store_b16 v4, v2, s[0:1] offset:6144
	global_store_b16 v4, v136, s[2:3] offset:6144
	s_wait_xcnt 0x1
	v_fma_mixlo_f16 v2, v17, v133, v73
	v_fma_mixlo_f16 v0, v19, v0, v75
	global_store_b16 v4, v1, s[0:1] offset:8192
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v1, v18, v134, v74
	s_clause 0x6
	global_store_b16 v4, v136, s[2:3] offset:8192
	global_store_b16 v4, v2, s[0:1] offset:10240
	global_store_b16 v4, v136, s[2:3] offset:10240
	global_store_b16 v4, v1, s[0:1] offset:12288
	global_store_b16 v4, v136, s[2:3] offset:12288
	global_store_b16 v4, v0, s[0:1] offset:14336
	global_store_b16 v4, v136, s[2:3] offset:14336
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mamba_scan_original
		.amdhsa_group_segment_fixed_size 20480
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 179
		.amdhsa_next_free_sgpr 21
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 46
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
	.size	mamba_scan_original, .Lfunc_end1-mamba_scan_original
                                        ; -- End function
	.set mamba_scan_original.num_vgpr, 179
	.set mamba_scan_original.num_agpr, 0
	.set mamba_scan_original.numbered_sgpr, 21
	.set mamba_scan_original.num_named_barrier, 0
	.set mamba_scan_original.private_seg_size, 0
	.set mamba_scan_original.uses_vcc, 1
	.set mamba_scan_original.uses_flat_scratch, 0
	.set mamba_scan_original.has_dyn_sized_stack, 0
	.set mamba_scan_original.has_recursion, 0
	.set mamba_scan_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5788
; TotalNumSgprs: 23
; NumVgprs: 179
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 20480 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 11
; NumSGPRsForWavesPerEU: 23
; NumVGPRsForWavesPerEU: 179
; NamedBarCnt: 0
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_e892aea9fbd63569,@object ; @__hip_cuid_e892aea9fbd63569
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_e892aea9fbd63569
__hip_cuid_e892aea9fbd63569:
	.byte	0                               ; 0x0
	.size	__hip_cuid_e892aea9fbd63569, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_e892aea9fbd63569
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
    .group_segment_fixed_size: 24576
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           mamba_state_original
    .private_segment_fixed_size: 0
    .sgpr_count:     30
    .sgpr_spill_count: 0
    .symbol:         mamba_state_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     173
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
    .group_segment_fixed_size: 20480
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           mamba_scan_original
    .private_segment_fixed_size: 0
    .sgpr_count:     23
    .sgpr_spill_count: 0
    .symbol:         mamba_scan_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     179
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
