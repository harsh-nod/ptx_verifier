	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	convolution_f16_original ; -- Begin function convolution_f16_original
	.globl	convolution_f16_original
	.p2align	8
	.type	convolution_f16_original,@function
convolution_f16_original:               ; @convolution_f16_original
; %bb.0:
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_bitop2_b32 v93, 31, v0 bitop3:0x40
	s_bfe_u32 s3, ttmp6, 0x4000c
	s_bfe_u32 s4, ttmp6, 0x40010
	s_add_co_i32 s3, s3, 1
	s_delay_alu instid0(VALU_DEP_1)
	v_mul_lo_u16 v1, v93, 29
	s_add_co_i32 s4, s4, 1
	s_and_b32 s2, ttmp6, 15
	s_bfe_u32 s5, ttmp6, 0x40004
	s_mul_i32 s3, ttmp9, s3
	s_mul_i32 s4, ttmp7, s4
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	v_lshrrev_b16 v1, 8, v1
	s_add_co_i32 s2, s2, s3
	s_add_co_i32 s5, s5, s4
	s_cmp_eq_u32 s6, 0
	v_dual_lshlrev_b32 v3, 6, v0 :: v_dual_bitop2_b32 v2, 8, v2 bitop3:0x40
	v_and_b32_e32 v5, 0x60, v0
	s_cselect_b32 s2, ttmp9, s2
	v_mul_lo_u16 v4, v1, 9
	s_cselect_b32 s10, ttmp7, s5
	s_lshl_b32 s9, s2, 7
	v_and_b32_e32 v100, 15, v0
	v_or3_b32 v5, s9, v5, v2
	v_sub_nc_u16 v4, v93, v4
	v_lshlrev_b32_e32 v2, 1, v2
	v_and_b32_e32 v68, 0xffff, v1
	v_and_b32_e32 v7, 0x3c0, v3
	v_mul_hi_u32 v8, 0x59e60383, v5
	v_and_b32_e32 v6, 0xff, v4
	v_or_b32_e32 v9, 1, v5
	v_and_or_b32 v101, 0x1bc0, v3, v2
	v_or3_b32 v102, v7, v2, 0x4000
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_mul_lo_u16 v6, 0xab, v6
	s_wait_xcnt 0x0
	s_lshl_b32 s1, s10, 7
	v_cmp_lt_u32_e64 s0, 0x7f, v0
	v_mul_u32_u24_e64 v135, 0x900, 15
	v_or_b32_e32 v136, 0xf80, v0
	v_dual_lshrrev_b32 v8, 10, v8 :: v_dual_bitop2_b32 v1, 2, v5 bitop3:0x54
	v_lshrrev_b16 v6, 9, v6
	v_mul_hi_u32 v3, 0x59e60383, v9
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_lshlrev_b32 v103, 7, v8 :: v_dual_bitop2_b32 v10, 3, v5 bitop3:0x54
	v_mul_hi_u32 v11, 0x59e60383, v1
	s_delay_alu instid0(VALU_DEP_4)
	v_mul_lo_u16 v12, v6, 3
	v_or_b32_e32 v2, 4, v5
	v_mul_u32_u24_e32 v8, 0xb64, v8
	v_and_b32_e32 v70, 0xffff, v6
	v_or_b32_e32 v139, 0xffffff80, v0
	v_sub_nc_u16 v4, v4, v12
	v_dual_mov_b32 v73, v68 :: v_dual_mov_b32 v76, v68
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_hi_u32 v7, 0x59e60383, v10
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_4) | instid1(VALU_DEP_4)
	v_and_b32_e32 v72, 0xff, v4
	v_lshrrev_b32_e32 v6, 10, v11
	v_mul_hi_u32 v4, 0x59e60383, v2
	v_dual_sub_nc_u32 v104, v5, v8 :: v_dual_bitop2_b32 v8, 5, v5 bitop3:0x54
	v_mul_u32_u24_e32 v3, 0xb64, v3
	v_mul_u32_u24_e32 v6, 0xb64, v6
	v_or_b32_e32 v13, 7, v5
	v_or_b32_e32 v11, 6, v5
	v_mul_hi_u32 v12, 0x59e60383, v8
	v_dual_mov_b32 v74, v70 :: v_dual_lshrrev_b32 v7, 10, v7
	v_dual_mov_b32 v71, v70 :: v_dual_lshrrev_b32 v4, 10, v4
	v_sub_nc_u32_e32 v105, v9, v3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v7, 0xb64, v7
	v_dual_sub_nc_u32 v106, v1, v6 :: v_dual_bitop2_b32 v6, 16, v5 bitop3:0x54
	v_mul_u32_u24_e32 v3, 0xb64, v4
	v_lshlrev_b32_e32 v108, 7, v4
	v_lshrrev_b32_e32 v4, 10, v12
	v_mul_hi_u32 v14, 0x59e60383, v11
	v_mul_hi_u32 v1, 0x59e60383, v13
	v_mul_hi_u32 v9, 0x59e60383, v6
	v_dual_sub_nc_u32 v109, v2, v3 :: v_dual_bitop2_b32 v2, 17, v5 bitop3:0x54
	v_sub_nc_u32_e32 v107, v10, v7
	v_mul_u32_u24_e32 v7, 0xb64, v4
	v_dual_mov_b32 v75, v68 :: v_dual_lshlrev_b32 v110, 7, v4
	v_mov_b32_e32 v77, v72
	v_mul_hi_u32 v10, 0x59e60383, v2
	v_dual_lshrrev_b32 v3, 10, v14 :: v_dual_lshrrev_b32 v1, 10, v1
	v_dual_lshrrev_b32 v4, 10, v9 :: v_dual_sub_nc_u32 v111, v8, v7
	v_dual_mov_b32 v78, v72 :: v_dual_mov_b32 v79, v72
	s_delay_alu instid0(VALU_DEP_3)
	v_mul_u32_u24_e32 v12, 0xb64, v3
	v_lshlrev_b32_e32 v112, 7, v3
	v_mul_u32_u24_e32 v3, 0xb64, v1
	v_lshlrev_b32_e32 v114, 7, v1
	v_or_b32_e32 v1, 18, v5
	v_mul_u32_u24_e32 v9, 0xb64, v4
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_dual_sub_nc_u32 v113, v11, v12 :: v_dual_sub_nc_u32 v115, v13, v3
	v_lshrrev_b32_e32 v3, 10, v10
	v_mul_hi_u32 v8, 0x59e60383, v1
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_sub_nc_u32_e32 v117, v6, v9
	v_dual_lshlrev_b32 v116, 7, v4 :: v_dual_bitop2_b32 v7, 19, v5 bitop3:0x54
	v_mul_u32_u24_e32 v4, 0xb64, v3
	v_dual_lshlrev_b32 v118, 7, v3 :: v_dual_bitop2_b32 v11, 20, v5 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mul_hi_u32 v10, 0x59e60383, v7
	v_dual_sub_nc_u32 v119, v2, v4 :: v_dual_bitop2_b32 v3, 21, v5 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_mul_hi_u32 v2, 0x59e60383, v11
	v_dual_lshrrev_b32 v4, 10, v8 :: v_dual_bitop2_b32 v6, 22, v5 bitop3:0x54
	v_mul_hi_u32 v8, 0x59e60383, v3
	v_or_b32_e32 v5, 23, v5
	s_mov_b32 s8, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshlrev_b32_e32 v120, 7, v4
	v_mul_hi_u32 v12, 0x59e60383, v6
	v_lshrrev_b32_e32 v9, 10, v10
	v_mul_u32_u24_e32 v10, 0xb64, v4
	v_mul_hi_u32 v4, 0x59e60383, v5
	v_lshrrev_b32_e32 v2, 10, v2
	s_mov_b32 s10, s9
	v_mul_u32_u24_e32 v13, 0xb64, v9
	v_dual_sub_nc_u32 v121, v1, v10 :: v_dual_lshlrev_b32 v122, 7, v9
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v1, 10, v8 :: v_dual_lshlrev_b32 v124, 7, v2
	v_sub_nc_u32_e32 v123, v7, v13
	v_mul_u32_u24_e32 v7, 0xb64, v2
	v_lshrrev_b32_e32 v2, 10, v12
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v8, 0xb64, v1
	v_dual_lshrrev_b32 v4, 10, v4 :: v_dual_lshlrev_b32 v126, 7, v1
	v_sub_nc_u32_e32 v125, v11, v7
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v1, 0xb64, v2
	v_sub_nc_u32_e32 v127, v3, v8
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v3, 0xb64, v4
	v_dual_lshrrev_b32 v7, 5, v0 :: v_dual_lshlrev_b32 v128, 7, v2
	v_dual_sub_nc_u32 v129, v6, v1 :: v_dual_lshlrev_b32 v130, 7, v4
	v_or_b32_e32 v4, 0x1000, v0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_dual_lshlrev_b32 v134, 1, v0 :: v_dual_bitop2_b32 v132, s1, v7 bitop3:0x54
	v_dual_sub_nc_u32 v131, v5, v3 :: v_dual_bitop2_b32 v133, 32, v93 bitop3:0x54
	v_dual_mov_b32 v99, 0 :: v_dual_lshrrev_b32 v4, 5, v4
	v_or_b32_e32 v3, 0x180, v0
	v_or_b32_e32 v2, 0x100, v0
	v_or_b32_e32 v1, 0x80, v0
	v_or_b32_e32 v137, 0x2000, v134
	v_dual_mov_b32 v69, v70 :: v_dual_add_nc_u32 v138, s9, v4
	v_or_b32_e32 v140, 0x4000, v134
	s_mov_b32 s11, s9
	s_mov_b32 s12, s9
	s_mov_b32 s15, -1
	s_mov_b32 s14, 0
	s_branch .LBB0_2
.LBB0_1:                                ;   in Loop: Header=BB0_2 Depth=1
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v80, s14, v100
	v_cvt_f16_f32_e32 v60, v60
	v_cvt_f16_f32_e32 v52, v52
	v_cvt_f16_f32_e32 v44, v44
	v_cvt_f16_f32_e32 v36, v36
	v_add_nc_u32_e32 v81, v80, v103
	v_cvt_f16_f32_e32 v28, v28
	v_cvt_f16_f32_e32 v20, v20
	v_cvt_f16_f32_e32 v12, v12
	v_cvt_f16_f32_e32 v4, v4
	v_mul_lo_u32 v81, 0xb64, v81
	s_mov_b32 s14, 64
	s_mov_b32 s15, 0
	s_and_b32 vcc_lo, exec_lo, s13
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v82, v81, v104
	global_store_b16 v82, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v60, v61
	v_add_nc_u32_e32 v61, v81, v105
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v60, v62
	v_add_nc_u32_e32 v61, v81, v106
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v60, v63
	v_add_nc_u32_e32 v61, v81, v107
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v61, v80, v108
	v_cvt_f16_f32_e32 v60, v64
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v61, 0xb64, v61, v109
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v61, v80, v110
	v_cvt_f16_f32_e32 v60, v65
	v_mad_u32 v61, 0xb64, v61, v111
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v61, v80, v112
	v_cvt_f16_f32_e32 v60, v66
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v61, 0xb64, v61, v113
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v61, v80, v114
	v_cvt_f16_f32_e32 v60, v67
	v_mad_u32 v61, 0xb64, v61, v115
	global_store_b16 v61, v60, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_or_b32_e32 v60, 16, v80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v61, v60, v103
	v_mul_lo_u32 v61, 0xb64, v61
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v62, v61, v104
	global_store_b16 v62, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v52, v53
	v_add_nc_u32_e32 v53, v61, v105
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v52, v54
	v_add_nc_u32_e32 v53, v61, v106
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v52, v55
	v_add_nc_u32_e32 v53, v61, v107
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v53, v60, v108
	v_cvt_f16_f32_e32 v52, v56
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v53, 0xb64, v53, v109
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v53, v60, v110
	v_cvt_f16_f32_e32 v52, v57
	v_mad_u32 v53, 0xb64, v53, v111
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v53, v60, v112
	v_cvt_f16_f32_e32 v52, v58
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v53, 0xb64, v53, v113
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v53, v60, v114
	v_cvt_f16_f32_e32 v52, v59
	v_mad_u32 v53, 0xb64, v53, v115
	global_store_b16 v53, v52, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_or_b32_e32 v52, 32, v80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v53, v52, v103
	v_mul_lo_u32 v53, 0xb64, v53
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v54, v53, v104
	global_store_b16 v54, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v44, v45
	v_add_nc_u32_e32 v45, v53, v105
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v44, v46
	v_add_nc_u32_e32 v45, v53, v106
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v44, v47
	v_add_nc_u32_e32 v45, v53, v107
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v45, v52, v108
	v_cvt_f16_f32_e32 v44, v48
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v45, 0xb64, v45, v109
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v45, v52, v110
	v_cvt_f16_f32_e32 v44, v49
	v_mad_u32 v45, 0xb64, v45, v111
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v45, v52, v112
	v_cvt_f16_f32_e32 v44, v50
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v45, 0xb64, v45, v113
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v45, v52, v114
	v_cvt_f16_f32_e32 v44, v51
	v_mad_u32 v45, 0xb64, v45, v115
	global_store_b16 v45, v44, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_or_b32_e32 v44, 48, v80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v45, v44, v103
	v_mul_lo_u32 v45, 0xb64, v45
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v46, v45, v104
	global_store_b16 v46, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v36, v37
	v_add_nc_u32_e32 v37, v45, v105
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v36, v38
	v_add_nc_u32_e32 v37, v45, v106
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v36, v39
	v_add_nc_u32_e32 v37, v45, v107
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v37, v44, v108
	v_cvt_f16_f32_e32 v36, v40
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v37, 0xb64, v37, v109
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v37, v44, v110
	v_cvt_f16_f32_e32 v36, v41
	v_mad_u32 v37, 0xb64, v37, v111
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v37, v44, v112
	v_cvt_f16_f32_e32 v36, v42
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v37, 0xb64, v37, v113
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v37, v44, v114
	v_cvt_f16_f32_e32 v36, v43
	v_mad_u32 v37, 0xb64, v37, v115
	global_store_b16 v37, v36, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v36, v80, v116
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_mad_u32 v36, 0xb64, v36, v117
	global_store_b16 v36, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v28, v29
	v_add_nc_u32_e32 v29, v80, v118
	v_mad_u32 v29, 0xb64, v29, v119
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v29, v80, v120
	v_cvt_f16_f32_e32 v28, v30
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v29, 0xb64, v29, v121
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v29, v80, v122
	v_cvt_f16_f32_e32 v28, v31
	v_mad_u32 v29, 0xb64, v29, v123
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v29, v80, v124
	v_cvt_f16_f32_e32 v28, v32
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v29, 0xb64, v29, v125
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v29, v80, v126
	v_cvt_f16_f32_e32 v28, v33
	v_mad_u32 v29, 0xb64, v29, v127
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v29, v80, v128
	v_cvt_f16_f32_e32 v28, v34
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v29, 0xb64, v29, v129
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v29, v80, v130
	v_cvt_f16_f32_e32 v28, v35
	v_mad_u32 v29, 0xb64, v29, v131
	global_store_b16 v29, v28, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v28, v60, v116
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_mad_u32 v28, 0xb64, v28, v117
	global_store_b16 v28, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v20, v21
	v_add_nc_u32_e32 v21, v60, v118
	v_mad_u32 v21, 0xb64, v21, v119
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v21, v60, v120
	v_cvt_f16_f32_e32 v20, v22
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v21, 0xb64, v21, v121
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v21, v60, v122
	v_cvt_f16_f32_e32 v20, v23
	v_mad_u32 v21, 0xb64, v21, v123
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v21, v60, v124
	v_cvt_f16_f32_e32 v20, v24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v21, 0xb64, v21, v125
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v21, v60, v126
	v_cvt_f16_f32_e32 v20, v25
	v_mad_u32 v21, 0xb64, v21, v127
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v21, v60, v128
	v_cvt_f16_f32_e32 v20, v26
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v21, 0xb64, v21, v129
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v21, v60, v130
	v_cvt_f16_f32_e32 v20, v27
	v_mad_u32 v21, 0xb64, v21, v131
	global_store_b16 v21, v20, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v20, v52, v116
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_mad_u32 v20, 0xb64, v20, v117
	global_store_b16 v20, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v12, v13
	v_add_nc_u32_e32 v13, v52, v118
	v_mad_u32 v13, 0xb64, v13, v119
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v13, v52, v120
	v_cvt_f16_f32_e32 v12, v14
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v13, 0xb64, v13, v121
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v13, v52, v122
	v_cvt_f16_f32_e32 v12, v15
	v_mad_u32 v13, 0xb64, v13, v123
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v13, v52, v124
	v_cvt_f16_f32_e32 v12, v16
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v13, 0xb64, v13, v125
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v13, v52, v126
	v_cvt_f16_f32_e32 v12, v17
	v_mad_u32 v13, 0xb64, v13, v127
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v13, v52, v128
	v_cvt_f16_f32_e32 v12, v18
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v13, 0xb64, v13, v129
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v13, v52, v130
	v_cvt_f16_f32_e32 v12, v19
	v_mad_u32 v13, 0xb64, v13, v131
	global_store_b16 v13, v12, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v12, v44, v116
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_mad_u32 v12, 0xb64, v12, v117
	global_store_b16 v12, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v4, v5
	v_add_nc_u32_e32 v5, v44, v118
	v_mad_u32 v5, 0xb64, v5, v119
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v5, v44, v120
	v_cvt_f16_f32_e32 v4, v6
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v5, 0xb64, v5, v121
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v5, v44, v122
	v_cvt_f16_f32_e32 v4, v7
	v_mad_u32 v5, 0xb64, v5, v123
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v5, v44, v124
	v_cvt_f16_f32_e32 v4, v8
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v5, 0xb64, v5, v125
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v5, v44, v126
	v_cvt_f16_f32_e32 v4, v9
	v_mad_u32 v5, 0xb64, v5, v127
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v5, v44, v128
	v_cvt_f16_f32_e32 v4, v10
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_mad_u32 v5, 0xb64, v5, v129
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v5, v44, v130
	v_cvt_f16_f32_e32 v4, v11
	v_mad_u32 v5, 0xb64, v5, v131
	global_store_b16 v5, v4, s[2:3] scale_offset
	s_wait_storecnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccnz .LBB0_26
.LBB0_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_3 Depth 2
                                        ;     Child Loop BB0_6 Depth 2
                                        ;     Child Loop BB0_8 Depth 2
                                        ;     Child Loop BB0_12 Depth 2
                                        ;       Child Loop BB0_14 Depth 3
                                        ;       Child Loop BB0_17 Depth 3
                                        ;       Child Loop BB0_20 Depth 3
                                        ;       Child Loop BB0_24 Depth 3
	s_wait_xcnt 0x0
	v_mov_b64_e32 v[6:7], v[2:3]
	v_mov_b64_e32 v[4:5], v[0:1]
	v_dual_mov_b32 v8, 32 :: v_dual_mov_b32 v9, v134
	s_xor_b32 s13, s15, -1
	s_mov_b32 s15, 0
.LBB0_3:                                ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_lshrrev_b32 v10, 5, v4 :: v_dual_lshrrev_b32 v12, 5, v5
	v_dual_mov_b32 v15, v99 :: v_dual_lshrrev_b32 v14, 5, v6
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v16, 5, v7 :: v_dual_add_nc_u32 v10, s9, v10
	v_dual_mov_b32 v11, v99 :: v_dual_add_nc_u32 v12, s10, v12
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v13, v99 :: v_dual_add_nc_u32 v14, s11, v14
	v_mul_hi_u32 v17, 0x59e60383, v10
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_add_nc_u32_e32 v16, s12, v16
	v_mul_hi_u32 v18, 0x59e60383, v12
	v_add_nc_u32_e32 v8, -4, v8
	v_mul_hi_u32 v19, 0x59e60383, v14
	v_add_nc_u32_e32 v7, 0x200, v7
	v_add_nc_u32_e32 v6, 0x200, v6
	v_add_nc_u32_e32 v5, 0x200, v5
	v_cmp_eq_u32_e32 vcc_lo, 0, v8
	v_add_nc_u32_e32 v4, 0x200, v4
	v_lshrrev_b32_e32 v17, 10, v17
	v_mul_hi_u32 v20, 0x59e60383, v16
	v_lshrrev_b32_e32 v18, 10, v18
	s_or_b32 s15, vcc_lo, s15
	v_lshrrev_b32_e32 v19, 10, v19
	v_mul_u32_u24_e32 v21, 0xb64, v17
	v_lshl_or_b32 v17, v17, 6, v68
	v_mul_u32_u24_e32 v22, 0xb64, v18
	v_lshl_or_b32 v18, v18, 6, v73
	v_mul_u32_u24_e32 v23, 0xb64, v19
	v_lshl_or_b32 v19, v19, 6, v76
	v_dual_sub_nc_u32 v10, v10, v21 :: v_dual_lshrrev_b32 v20, 10, v20
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_dual_sub_nc_u32 v12, v12, v22 :: v_dual_sub_nc_u32 v14, v14, v23
	v_mul_lo_u32 v17, 0xc40, v17
	v_lshrrev_b16 v21, 1, v10
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v24, 0xb64, v20
	v_lshrrev_b16 v22, 1, v12
	v_perm_b32 v10, v12, v10, 0x5040100
	v_lshl_or_b32 v20, v20, 6, v75
	v_mul_lo_u32 v18, 0xc40, v18
	v_sub_nc_u32_e32 v16, v16, v24
	v_lshrrev_b16 v24, 1, v14
	v_and_b32_e32 v22, 0xffff, v22
	v_mul_lo_u32 v19, 0xc40, v19
	v_mul_lo_u32 v20, 0xc40, v20
	v_perm_b32 v12, v16, v14, 0x5040100
	v_and_b32_e32 v14, 0xffff, v21
	v_and_b32_e32 v21, 0xffff, v24
	v_mul_u32_u24_e32 v22, 0x97b5, v22
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mul_u32_u24_e32 v14, 0x97b5, v14
	v_mul_u32_u24_e32 v21, 0x97b5, v21
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_lshrrev_b32_e32 v14, 20, v14
	v_lshrrev_b16 v23, 1, v16
	v_lshrrev_b32_e32 v21, 20, v21
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v16, 0xffff, v23
	v_mul_u32_u24_e32 v16, 0x97b5, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshrrev_b32 v16, 20, v16 :: v_dual_lshrrev_b32 v22, 20, v22
	v_add_nc_u32_e32 v23, v71, v16
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_perm_b32 v24, v22, v14, 0x5040100
	v_perm_b32 v16, v16, v21, 0x5040100
	v_dual_add_nc_u32 v22, v69, v22 :: v_dual_add_nc_u32 v21, v74, v21
	v_mul_u32_u24_e32 v23, 56, v23
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_lo_u16 v24, v24, 54 op_sel_hi:[1,0]
	v_pk_mul_lo_u16 v16, v16, 54 op_sel_hi:[1,0]
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v22, 56, v22
	v_mul_u32_u24_e32 v21, 56, v21
	v_pk_sub_i16 v10, v10, v24
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_pk_sub_i16 v12, v12, v16
	v_add_nc_u32_e32 v14, v70, v14
	v_and_b32_e32 v16, 0xffff, v10
	v_lshrrev_b32_e32 v10, 16, v10
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_and_b32_e32 v24, 0xffff, v12
	v_lshrrev_b32_e32 v12, 16, v12
	v_mul_u32_u24_e32 v14, 56, v14
	v_dual_add_nc_u32 v16, v72, v16 :: v_dual_add_nc_u32 v10, v77, v10
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_add_nc_u32_e32 v24, v78, v24
	v_add_nc_u32_e32 v25, v79, v12
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_add3_u32 v98, v16, v17, v14
	v_add3_u32 v10, v10, v18, v22
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_add3_u32 v12, v24, v19, v21
	v_add3_u32 v14, v25, v20, v23
	s_wait_kmcnt 0x0
	v_lshl_add_u64 v[16:17], v[98:99], 1, s[4:5]
	v_lshl_add_u64 v[10:11], v[10:11], 1, s[4:5]
	v_lshl_add_u64 v[12:13], v[12:13], 1, s[4:5]
	v_lshl_add_u64 v[14:15], v[14:15], 1, s[4:5]
	s_clause 0x3
	global_load_u16 v18, v[16:17], off
	global_load_u16 v19, v[10:11], off
	global_load_u16 v20, v[12:13], off
	global_load_u16 v21, v[14:15], off
	s_wait_loadcnt 0x3
	ds_store_b16 v9, v18
	s_wait_loadcnt 0x2
	ds_store_b16 v9, v19 offset:256
	s_wait_loadcnt 0x1
	ds_store_b16 v9, v20 offset:512
	s_wait_loadcnt 0x0
	ds_store_b16 v9, v21 offset:768
	v_add_nc_u32_e32 v9, 0x400, v9
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s15
	s_cbranch_execnz .LBB0_3
; %bb.4:                                ;   in Loop: Header=BB0_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s15
	s_and_saveexec_b32 s15, s8
	s_cbranch_execz .LBB0_7
; %bb.5:                                ;   in Loop: Header=BB0_2 Depth=1
	v_dual_mov_b32 v4, v138 :: v_dual_mov_b32 v5, v137
	v_mov_b32_e32 v6, v136
	s_mov_b32 s16, 0
.LBB0_6:                                ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_hi_u32 v7, 0x59e60383, v4
	v_add_nc_u32_e32 v6, 0x80, v6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0xf7f, v6
	s_or_b32 s16, vcc_lo, s16
	v_lshrrev_b32_e32 v7, 10, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v8, 0xb64, v7
	v_sub_nc_u32_e32 v8, v4, v8
	v_lshl_or_b32 v7, v7, 6, v68
	v_add_nc_u32_e32 v4, 4, v4
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_lshrrev_b16 v9, 1, v8
	v_mul_lo_u32 v7, 0xc40, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v9, 0xffff, v9
	v_mul_u32_u24_e32 v9, 0x97b5, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v9, 20, v9
	v_mul_lo_u16 v10, v9, 54
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_nc_u16 v8, v8, v10
	v_and_b32_e32 v8, 0xffff, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_add_nc_u32 v8, v8, v72 :: v_dual_add_nc_u32 v9, v9, v70
	v_mul_u32_u24_e32 v9, 56, v9
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v7, v8, v7, v9
	global_load_u16 v7, v7, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v5, v7
	v_add_nc_u32_e32 v5, 0x100, v5
	s_and_not1_b32 exec_lo, exec_lo, s16
	s_cbranch_execnz .LBB0_6
.LBB0_7:                                ;   in Loop: Header=BB0_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s15
	v_add_nc_u32_e32 v4, s14, v132
	s_mov_b32 s15, 0
	v_mov_b32_e32 v7, v139
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_lo_u32 v5, 0x240, v4
	v_dual_mov_b32 v4, v140 :: v_dual_bitop2_b32 v6, v93, v5 bitop3:0x54
.LBB0_8:                                ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v8, v6, s[6:7] scale_offset
	v_add_nc_u32_e32 v7, 0x80, v7
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v6, 0x900, v6
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0x77f, v7
	s_or_b32 s15, vcc_lo, s15
	s_wait_loadcnt 0x0
	ds_store_b16 v4, v8
	v_add_nc_u32_e32 v4, 0x100, v4
	s_and_not1_b32 exec_lo, exec_lo, s15
	s_cbranch_execnz .LBB0_8
; %bb.9:                                ;   in Loop: Header=BB0_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s15
	v_dual_mov_b32 v4, 0 :: v_dual_bitop2_b32 v6, s14, v132 bitop3:0x54
	v_add_nc_u32_e32 v141, v133, v5
	s_or_b32 s14, s14, s1
	s_mov_b32 s20, 0
	s_delay_alu instid0(VALU_DEP_2)
	v_mul_lo_u32 v11, 0x240, v6
	v_dual_mov_b32 v5, v4 :: v_dual_mov_b32 v6, v4
	v_dual_mov_b32 v7, v4 :: v_dual_mov_b32 v8, v4
	v_dual_mov_b32 v9, v4 :: v_dual_mov_b32 v10, v4
	v_dual_mov_b32 v13, v4 :: v_dual_mov_b32 v14, v4
	v_dual_mov_b32 v15, v4 :: v_dual_mov_b32 v16, v4
	v_dual_mov_b32 v11, v4 :: v_dual_bitop2_b32 v142, v11, v133 bitop3:0x54
	v_dual_mov_b32 v12, v4 :: v_dual_mov_b32 v17, v4
	v_dual_mov_b32 v18, v4 :: v_dual_mov_b32 v19, v4
	v_dual_mov_b32 v20, v4 :: v_dual_mov_b32 v21, v4
	v_dual_mov_b32 v22, v4 :: v_dual_mov_b32 v23, v4
	v_dual_mov_b32 v24, v4 :: v_dual_mov_b32 v25, v4
	v_dual_mov_b32 v26, v4 :: v_dual_mov_b32 v27, v4
	v_dual_mov_b32 v28, v4 :: v_dual_mov_b32 v29, v4
	v_dual_mov_b32 v30, v4 :: v_dual_mov_b32 v31, v4
	v_dual_mov_b32 v32, v4 :: v_dual_mov_b32 v33, v4
	v_dual_mov_b32 v34, v4 :: v_dual_mov_b32 v35, v4
	v_dual_mov_b32 v36, v4 :: v_dual_mov_b32 v37, v4
	v_dual_mov_b32 v38, v4 :: v_dual_mov_b32 v39, v4
	v_dual_mov_b32 v40, v4 :: v_dual_mov_b32 v41, v4
	v_dual_mov_b32 v42, v4 :: v_dual_mov_b32 v43, v4
	v_dual_mov_b32 v44, v4 :: v_dual_mov_b32 v45, v4
	v_dual_mov_b32 v46, v4 :: v_dual_mov_b32 v47, v4
	v_dual_mov_b32 v48, v4 :: v_dual_mov_b32 v49, v4
	v_dual_mov_b32 v50, v4 :: v_dual_mov_b32 v51, v4
	v_dual_mov_b32 v52, v4 :: v_dual_mov_b32 v53, v4
	v_dual_mov_b32 v54, v4 :: v_dual_mov_b32 v55, v4
	v_dual_mov_b32 v56, v4 :: v_dual_mov_b32 v57, v4
	v_dual_mov_b32 v58, v4 :: v_dual_mov_b32 v59, v4
	v_dual_mov_b32 v60, v4 :: v_dual_mov_b32 v61, v4
	v_dual_mov_b32 v62, v4 :: v_dual_mov_b32 v63, v4
	v_dual_mov_b32 v64, v4 :: v_dual_mov_b32 v65, v4
	v_dual_mov_b32 v66, v4 :: v_dual_mov_b32 v67, v4
	s_mov_b32 s15, s14
	s_mov_b32 s16, s14
	s_mov_b32 s17, s14
	s_mov_b32 s18, -1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB0_12
.LBB0_10:                               ;   in Loop: Header=BB0_12 Depth=2
	s_or_b32 exec_lo, exec_lo, s21
.LBB0_11:                               ;   in Loop: Header=BB0_12 Depth=2
	s_and_b32 s20, s20, 1
	v_add_nc_u32_e32 v141, 32, v141
	v_lshl_or_b32 v88, s20, 13, v101
	v_lshl_add_u32 v89, s20, 12, v102
	s_xor_b32 s18, s18, -1
	s_cmp_eq_u32 s19, 18
	s_mov_b32 s20, s19
	ds_load_b128 v[80:83], v88
	ds_load_b128 v[84:87], v88 offset:32
	ds_load_b128 v[144:147], v89
	ds_load_b128 v[148:151], v89 offset:32
	ds_load_b128 v[152:155], v89 offset:1024
	ds_load_b128 v[156:159], v89 offset:1056
	ds_load_b128 v[160:163], v89 offset:2048
	ds_load_b128 v[164:167], v89 offset:2080
	ds_load_b128 v[168:171], v89 offset:3072
	ds_load_b128 v[172:175], v89 offset:3104
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[60:67], v[80:87], v[144:151], v[60:67]
	s_wait_dscnt 0x4
	v_wmma_f32_16x16x32_f16 v[52:59], v[80:87], v[152:159], v[52:59]
	s_wait_dscnt 0x2
	v_wmma_f32_16x16x32_f16 v[44:51], v[80:87], v[160:167], v[44:51]
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[36:43], v[80:87], v[168:175], v[36:43]
	ds_load_b128 v[80:83], v88 offset:1024
	ds_load_b128 v[84:87], v88 offset:1056
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[28:35], v[80:87], v[144:151], v[28:35]
	v_wmma_f32_16x16x32_f16 v[20:27], v[80:87], v[152:159], v[20:27]
	v_wmma_f32_16x16x32_f16 v[12:19], v[80:87], v[160:167], v[12:19]
	v_wmma_f32_16x16x32_f16 v[4:11], v[80:87], v[168:175], v[4:11]
	s_cbranch_scc1 .LBB0_1
.LBB0_12:                               ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_14 Depth 3
                                        ;       Child Loop BB0_17 Depth 3
                                        ;       Child Loop BB0_20 Depth 3
                                        ;       Child Loop BB0_24 Depth 3
	s_add_co_i32 s19, s20, 1
	s_cmp_eq_u32 s20, 17
	s_cbranch_scc1 .LBB0_11
; %bb.13:                               ;   in Loop: Header=BB0_12 Depth=2
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v80, s19, 5, v93
	v_cndmask_b32_e64 v143, 0, 1, s18
	v_mov_b64_e32 v[96:97], v[2:3]
	v_mov_b64_e32 v[94:95], v[0:1]
	s_mov_b32 s21, 0
	v_and_b32_e32 v81, 0xffff, v80
	v_dual_mov_b32 v145, 32 :: v_dual_lshlrev_b32 v144, 13, v143
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v81, 0xe38f, v81
	v_dual_lshrrev_b32 v82, 19, v81 :: v_dual_bitop2_b32 v146, v134, v144 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_mul_lo_u16 v81, v82, 9
	v_mov_b32_e32 v88, v82
	v_sub_nc_u16 v81, v80, v81
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_lo_u16 v83, 0xab, v81
	v_lshrrev_b16 v83, 9, v83
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_lo_u16 v84, v83, 3
	v_sub_nc_u16 v85, v81, v84
	v_and_b32_e32 v84, 0xffff, v83
	v_dual_mov_b32 v81, v82 :: v_dual_mov_b32 v83, v82
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_and_b32_e32 v86, 0xff, v85
	v_dual_mov_b32 v85, v84 :: v_dual_mov_b32 v90, v84
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_mov_b32 v87, v84 :: v_dual_mov_b32 v89, v86
	v_dual_mov_b32 v92, v86 :: v_dual_mov_b32 v91, v86
.LBB0_14:                               ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_12 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	v_dual_lshrrev_b32 v98, 5, v94 :: v_dual_lshrrev_b32 v147, 5, v95
	v_dual_mov_b32 v153, v99 :: v_dual_lshrrev_b32 v148, 5, v96
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v150, 5, v97 :: v_dual_add_nc_u32 v98, s9, v98
	v_dual_add_nc_u32 v147, s10, v147 :: v_dual_mov_b32 v149, v99
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v151, v99 :: v_dual_add_nc_u32 v148, s11, v148
	v_mul_hi_u32 v152, 0x59e60383, v98
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_add_nc_u32_e32 v150, s12, v150
	v_mul_hi_u32 v154, 0x59e60383, v147
	v_add_nc_u32_e32 v97, 0x200, v97
	v_mul_hi_u32 v155, 0x59e60383, v148
	v_add_nc_u32_e32 v96, 0x200, v96
	v_add_nc_u32_e32 v95, 0x200, v95
	v_add_nc_u32_e32 v94, 0x200, v94
	v_dual_add_nc_u32 v145, -4, v145 :: v_dual_lshrrev_b32 v152, 10, v152
	v_mul_hi_u32 v156, 0x59e60383, v150
	v_lshrrev_b32_e32 v154, 10, v154
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_eq_u32_e32 vcc_lo, 0, v145
	v_lshrrev_b32_e32 v155, 10, v155
	v_mul_u32_u24_e32 v157, 0xb64, v152
	v_lshl_add_u32 v152, v152, 6, v82
	v_mul_u32_u24_e32 v158, 0xb64, v154
	v_lshl_add_u32 v154, v154, 6, v81
	v_mul_u32_u24_e32 v159, 0xb64, v155
	v_sub_nc_u32_e32 v98, v98, v157
	v_lshl_add_u32 v155, v155, 6, v88
	v_dual_lshrrev_b32 v156, 10, v156 :: v_dual_sub_nc_u32 v147, v147, v158
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_sub_nc_u32_e32 v148, v148, v159
	v_lshrrev_b16 v157, 1, v98
	v_mul_lo_u32 v152, 0xc40, v152
	s_delay_alu instid0(VALU_DEP_4)
	v_mul_u32_u24_e32 v160, 0xb64, v156
	v_lshrrev_b16 v158, 1, v147
	v_perm_b32 v98, v147, v98, 0x5040100
	v_lshl_add_u32 v156, v156, 6, v83
	v_mul_lo_u32 v154, 0xc40, v154
	v_sub_nc_u32_e32 v150, v150, v160
	v_lshrrev_b16 v160, 1, v148
	v_and_b32_e32 v158, 0xffff, v158
	v_mul_lo_u32 v155, 0xc40, v155
	v_mul_lo_u32 v156, 0xc40, v156
	v_perm_b32 v147, v150, v148, 0x5040100
	v_and_b32_e32 v148, 0xffff, v157
	v_and_b32_e32 v157, 0xffff, v160
	v_mul_u32_u24_e32 v158, 0x97b5, v158
	s_or_b32 s21, vcc_lo, s21
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mul_u32_u24_e32 v148, 0x97b5, v148
	v_mul_u32_u24_e32 v157, 0x97b5, v157
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v157, 20, v157
	v_lshrrev_b16 v159, 1, v150
	v_and_b32_e32 v150, 0xffff, v159
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v150, 0x97b5, v150
	v_dual_lshrrev_b32 v148, 20, v148 :: v_dual_lshrrev_b32 v150, 20, v150
	v_lshrrev_b32_e32 v158, 20, v158
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v159, v87, v150
	v_perm_b32 v160, v158, v148, 0x5040100
	v_perm_b32 v150, v150, v157, 0x5040100
	v_dual_add_nc_u32 v148, v84, v148 :: v_dual_add_nc_u32 v157, v90, v157
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mul_u32_u24_e32 v159, 56, v159
	v_pk_mul_lo_u16 v160, v160, 54 op_sel_hi:[1,0]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_lo_u16 v150, v150, 54 op_sel_hi:[1,0]
	v_mul_u32_u24_e32 v148, 56, v148
	v_mul_u32_u24_e32 v157, 56, v157
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_sub_i16 v98, v98, v160
	v_pk_sub_i16 v147, v147, v150
	v_add_nc_u32_e32 v158, v85, v158
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_and_b32_e32 v150, 0xffff, v98
	v_and_b32_e32 v160, 0xffff, v147
	v_dual_lshrrev_b32 v98, 16, v98 :: v_dual_lshrrev_b32 v147, 16, v147
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_mul_u32_u24_e32 v158, 56, v158
	v_dual_add_nc_u32 v150, v86, v150 :: v_dual_add_nc_u32 v160, v92, v160
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_add_nc_u32 v161, v89, v98 :: v_dual_add_nc_u32 v147, v91, v147
	v_add3_u32 v98, v150, v152, v148
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add3_u32 v150, v160, v155, v157
	v_add3_u32 v148, v161, v154, v158
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_add3_u32 v152, v147, v156, v159
	v_lshl_add_u64 v[154:155], v[98:99], 1, s[4:5]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_lshl_add_u64 v[150:151], v[150:151], 1, s[4:5]
	v_lshl_add_u64 v[148:149], v[148:149], 1, s[4:5]
	s_delay_alu instid0(VALU_DEP_4)
	v_lshl_add_u64 v[152:153], v[152:153], 1, s[4:5]
	s_clause 0x3
	global_load_u16 v98, v[154:155], off
	global_load_u16 v147, v[148:149], off
	global_load_u16 v156, v[150:151], off
	global_load_u16 v157, v[152:153], off
	s_wait_loadcnt 0x3
	ds_store_b16 v146, v98
	s_wait_loadcnt 0x2
	ds_store_b16 v146, v147 offset:256
	s_wait_loadcnt 0x1
	ds_store_b16 v146, v156 offset:512
	s_wait_loadcnt 0x0
	ds_store_b16 v146, v157 offset:768
	v_add_nc_u32_e32 v146, 0x400, v146
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s21
	s_cbranch_execnz .LBB0_14
; %bb.15:                               ;   in Loop: Header=BB0_12 Depth=2
	s_or_b32 exec_lo, exec_lo, s21
	s_and_saveexec_b32 s21, s8
	s_cbranch_execz .LBB0_18
; %bb.16:                               ;   in Loop: Header=BB0_12 Depth=2
	v_dual_add_nc_u32 v81, v137, v144 :: v_dual_mov_b32 v83, v138
	v_mov_b32_e32 v85, v136
	s_mov_b32 s22, 0
.LBB0_17:                               ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_12 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_hi_u32 v87, 0x59e60383, v83
	v_add_nc_u32_e32 v85, 0x80, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0xf7f, v85
	s_or_b32 s22, vcc_lo, s22
	v_lshrrev_b32_e32 v87, 10, v87
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v88, 0xb64, v87
	v_sub_nc_u32_e32 v88, v83, v88
	v_lshl_add_u32 v87, v87, 6, v82
	v_add_nc_u32_e32 v83, 4, v83
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_lshrrev_b16 v89, 1, v88
	v_mul_lo_u32 v87, 0xc40, v87
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v89, 0xffff, v89
	v_mul_u32_u24_e32 v89, 0x97b5, v89
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v89, 20, v89
	v_mul_lo_u16 v90, v89, 54
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_nc_u16 v88, v88, v90
	v_and_b32_e32 v88, 0xffff, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_add_nc_u32 v88, v88, v86 :: v_dual_add_nc_u32 v89, v89, v84
	v_mul_u32_u24_e32 v89, 56, v89
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v87, v88, v87, v89
	global_load_u16 v87, v87, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v81, v87
	v_add_nc_u32_e32 v81, 0x100, v81
	s_and_not1_b32 exec_lo, exec_lo, s22
	s_cbranch_execnz .LBB0_17
.LBB0_18:                               ;   in Loop: Header=BB0_12 Depth=2
	s_or_b32 exec_lo, exec_lo, s21
	v_lshl_add_u32 v81, s20, 5, v142
	v_lshl_add_u32 v88, v143, 12, v140
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_add_co_u32 v81, s21, v81, v135
	s_nor_b32 s21, s0, s21
	s_and_saveexec_b32 s22, s21
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s21, exec_lo, s22
	s_cbranch_execz .LBB0_22
; %bb.19:                               ;   in Loop: Header=BB0_12 Depth=2
	v_mov_b64_e32 v[86:87], v[2:3]
	v_mov_b64_e32 v[84:85], v[0:1]
	v_dual_mov_b32 v81, v80 :: v_dual_mov_b32 v82, v80
	v_dual_mov_b32 v83, v80 :: v_dual_mov_b32 v89, -16
	s_mov_b32 s22, 0
.LBB0_20:                               ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_12 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v90, 5, v84 :: v_dual_lshrrev_b32 v91, 5, v85
	v_dual_lshrrev_b32 v92, 5, v86 :: v_dual_lshrrev_b32 v94, 5, v87
	v_dual_mov_b32 v97, v99 :: v_dual_add_nc_u32 v89, 4, v89
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_add_nc_u32 v90, s14, v90 :: v_dual_add_nc_u32 v91, s15, v91
	v_dual_add_nc_u32 v92, s16, v92 :: v_dual_add_nc_u32 v95, s17, v94
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_cmp_eq_u32_e32 vcc_lo, 0, v89
	v_mad_u32 v98, 0x240, v90, v80
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mad_u32 v90, 0x240, v91, v81
	v_mad_u32 v94, 0x240, v92, v82
	v_mad_u32 v96, 0x240, v95, v83
	v_dual_mov_b32 v91, v99 :: v_dual_mov_b32 v95, v99
	v_add_nc_u32_e32 v87, 0x200, v87
	v_add_nc_u32_e32 v86, 0x200, v86
	v_add_nc_u32_e32 v85, 0x200, v85
	v_add_nc_u32_e32 v84, 0x200, v84
	s_or_b32 s22, vcc_lo, s22
	v_lshl_add_u64 v[144:145], v[98:99], 1, s[6:7]
	v_lshl_add_u64 v[90:91], v[90:91], 1, s[6:7]
	v_lshl_add_u64 v[94:95], v[94:95], 1, s[6:7]
	v_lshl_add_u64 v[96:97], v[96:97], 1, s[6:7]
	s_clause 0x3
	global_load_u16 v92, v[144:145], off
	global_load_u16 v98, v[90:91], off
	global_load_u16 v143, v[94:95], off
	global_load_u16 v146, v[96:97], off
	s_wait_loadcnt 0x3
	ds_store_b16 v88, v92
	s_wait_loadcnt 0x2
	ds_store_b16 v88, v98 offset:256
	s_wait_loadcnt 0x1
	ds_store_b16 v88, v143 offset:512
	s_wait_loadcnt 0x0
	ds_store_b16 v88, v146 offset:768
	v_add_nc_u32_e32 v88, 0x400, v88
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s22
	s_cbranch_execnz .LBB0_20
; %bb.21:                               ;   in Loop: Header=BB0_12 Depth=2
	s_or_b32 exec_lo, exec_lo, s22
                                        ; implicit-def: $vgpr88
.LBB0_22:                               ;   in Loop: Header=BB0_12 Depth=2
	s_and_not1_saveexec_b32 s21, s21
	s_cbranch_execz .LBB0_10
; %bb.23:                               ;   in Loop: Header=BB0_12 Depth=2
	v_dual_mov_b32 v80, v141 :: v_dual_mov_b32 v81, v139
	s_mov_b32 s22, 0
.LBB0_24:                               ;   Parent Loop BB0_2 Depth=1
                                        ;     Parent Loop BB0_12 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	global_load_u16 v82, v80, s[6:7] scale_offset
	v_add_nc_u32_e32 v81, 0x80, v81
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v80, 0x900, v80
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0x77f, v81
	s_or_b32 s22, vcc_lo, s22
	s_wait_loadcnt 0x0
	ds_store_b16 v88, v82
	v_add_nc_u32_e32 v88, 0x100, v88
	s_and_not1_b32 exec_lo, exec_lo, s22
	s_cbranch_execnz .LBB0_24
; %bb.25:                               ;   in Loop: Header=BB0_12 Depth=2
	s_or_b32 exec_lo, exec_lo, s22
	s_branch .LBB0_10
.LBB0_26:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel convolution_f16_original
		.amdhsa_group_segment_fixed_size 24576
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 176
		.amdhsa_next_free_sgpr 23
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 57
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
	.size	convolution_f16_original, .Lfunc_end0-convolution_f16_original
                                        ; -- End function
	.set convolution_f16_original.num_vgpr, 176
	.set convolution_f16_original.num_agpr, 0
	.set convolution_f16_original.numbered_sgpr, 23
	.set convolution_f16_original.num_named_barrier, 0
	.set convolution_f16_original.private_seg_size, 0
	.set convolution_f16_original.uses_vcc, 1
	.set convolution_f16_original.uses_flat_scratch, 0
	.set convolution_f16_original.has_dyn_sized_stack, 0
	.set convolution_f16_original.has_recursion, 0
	.set convolution_f16_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 7172
; TotalNumSgprs: 25
; NumVgprs: 176
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 24576 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 10
; NumSGPRsForWavesPerEU: 25
; NumVGPRsForWavesPerEU: 176
; NamedBarCnt: 0
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	convolution_f8_original ; -- Begin function convolution_f8_original
	.globl	convolution_f8_original
	.p2align	8
	.type	convolution_f8_original,@function
convolution_f8_original:                ; @convolution_f8_original
; %bb.0:
	v_dual_lshrrev_b32 v2, 5, v0 :: v_dual_bitop2_b32 v32, 31, v0 bitop3:0x40
	s_bfe_u32 s3, ttmp6, 0x4000c
	s_bfe_u32 s4, ttmp6, 0x40010
	s_add_co_i32 s3, s3, 1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_mul_lo_u16 v1, v32, 29
	s_add_co_i32 s4, s4, 1
	v_dual_lshrrev_b32 v3, 1, v0 :: v_dual_lshlrev_b32 v4, 6, v0
	s_and_b32 s2, ttmp6, 15
	v_lshrrev_b16 v1, 8, v1
	s_bfe_u32 s5, ttmp6, 0x40004
	s_mul_i32 s3, ttmp9, s3
	s_mul_i32 s4, ttmp7, s4
	s_getreg_b32 s6, hwreg(HW_REG_IB_STS2, 6, 4)
	v_mul_lo_u16 v5, v1, 9
	s_add_co_i32 s2, s2, s3
	s_add_co_i32 s5, s5, s4
	s_cmp_eq_u32 s6, 0
	v_dual_lshlrev_b32 v6, 4, v2 :: v_dual_bitop2_b32 v3, 8, v3 bitop3:0x40
	s_cselect_b32 s2, ttmp9, s2
	v_sub_nc_u16 v5, v32, v5
	s_cselect_b32 s8, ttmp7, s5
	s_lshl_b32 s9, s2, 6
	v_lshlrev_b32_e32 v8, 10, v2
	v_or3_b32 v6, v6, s9, v3
	v_and_b32_e32 v7, 0xff, v5
	v_and_b32_e32 v4, 0x3c0, v4
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_b32_e32 v34, 0xffff, v1
	v_mul_hi_u32 v9, 0x59e60383, v6
	v_mul_lo_u16 v7, 0xab, v7
	v_and_b32_e32 v33, 15, v0
	v_or3_b32 v35, v8, v4, v3
	v_or3_b32 v36, v4, v3, 0x2000
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_lshrrev_b16 v1, 9, v7
	v_dual_lshlrev_b32 v50, 1, v0 :: v_dual_bitop2_b32 v54, s9, v2 bitop3:0x54
	s_wait_xcnt 0x0
	s_lshl_b32 s0, s8, 7
	v_or_b32_e32 v53, 0xffffff80, v0
	v_mul_lo_u16 v8, v1, 3
	v_dual_lshrrev_b32 v9, 10, v9 :: v_dual_bitop2_b32 v3, 1, v6 bitop3:0x54
	v_and_b32_e32 v38, 0xffff, v1
	v_or_b32_e32 v55, 0x2000, v50
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_sub_nc_u16 v5, v5, v8
	v_mul_u32_u24_e32 v8, 0xb64, v9
	v_dual_lshlrev_b32 v37, 7, v9 :: v_dual_bitop2_b32 v4, 2, v6 bitop3:0x54
	v_mul_hi_u32 v10, 0x59e60383, v3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_and_b32_e32 v39, 0xff, v5
	v_sub_nc_u32_e32 v40, v6, v8
	s_delay_alu instid0(VALU_DEP_4)
	v_mul_hi_u32 v12, 0x59e60383, v4
	v_or_b32_e32 v7, 3, v6
	v_or_b32_e32 v57, 32, v32
	s_mov_b32 s8, 0
	s_mov_b32 s1, -1
	v_or_b32_e32 v56, s0, v2
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v5, 10, v10 :: v_dual_lshrrev_b32 v10, 10, v12
	v_mul_hi_u32 v13, 0x59e60383, v7
	v_or_b32_e32 v11, 4, v6
	v_mul_u32_u24_e32 v10, 0xb64, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_4)
	v_sub_nc_u32_e32 v42, v4, v10
	v_mul_u32_u24_e32 v5, 0xb64, v5
	v_lshrrev_b32_e32 v13, 10, v13
	v_mul_hi_u32 v8, 0x59e60383, v11
	v_or_b32_e32 v1, 5, v6
	v_dual_sub_nc_u32 v41, v3, v5 :: v_dual_bitop2_b32 v9, 6, v6 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_u32_u24_e32 v13, 0xb64, v13
	v_mul_hi_u32 v14, 0x59e60383, v9
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_sub_nc_u32 v43, v7, v13 :: v_dual_lshrrev_b32 v8, 10, v8
	v_mul_hi_u32 v12, 0x59e60383, v1
	v_or_b32_e32 v6, 7, v6
	v_mul_u32_u24_e32 v4, 0xb64, v8
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v5, 10, v14 :: v_dual_lshrrev_b32 v3, 10, v12
	v_mul_hi_u32 v15, 0x59e60383, v6
	v_lshlrev_b32_e32 v44, 7, v8
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_sub_nc_u32_e32 v45, v11, v4
	v_mul_u32_u24_e32 v4, 0xb64, v5
	v_mul_u32_u24_e32 v7, 0xb64, v3
	v_dual_lshlrev_b32 v46, 7, v3 :: v_dual_lshlrev_b32 v48, 7, v5
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_sub_nc_u32_e32 v47, v1, v7
	v_lshrrev_b32_e32 v8, 10, v15
	v_mul_u32_u24_e32 v1, 0xb64, v8
	v_sub_nc_u32_e32 v49, v9, v4
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_lshlrev_b32 v51, 7, v8 :: v_dual_sub_nc_u32 v52, v6, v1
	s_branch .LBB1_2
.LBB1_1:                                ;   in Loop: Header=BB1_2 Depth=1
	v_or3_b32 v58, s8, s0, v33
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f16_f32_e32 v25, v25
	v_cvt_f16_f32_e32 v26, v26
	v_cvt_f16_f32_e32 v27, v27
	v_dual_add_nc_u32 v59, v58, v37 :: v_dual_bitop2_b32 v60, 16, v58 bitop3:0x54
	v_add_nc_u32_e32 v63, v58, v48
	v_dual_add_nc_u32 v61, v58, v44 :: v_dual_add_nc_u32 v62, v58, v46
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mul_lo_u32 v59, 0xb64, v59
	v_dual_add_nc_u32 v64, v60, v37 :: v_dual_add_nc_u32 v65, v58, v51
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mad_u32 v61, 0xb64, v61, v45
	v_mad_u32 v62, 0xb64, v62, v47
	v_mad_u32 v63, 0xb64, v63, v49
	s_delay_alu instid0(VALU_DEP_4)
	v_mul_lo_u32 v64, 0xb64, v64
	v_cvt_f16_f32_e32 v28, v28
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f16_f32_e32 v18, v18
	v_cvt_f16_f32_e32 v19, v19
	v_dual_add_nc_u32 v66, v59, v40 :: v_dual_add_nc_u32 v67, v59, v41
	v_add_nc_u32_e32 v68, v59, v42
	v_mad_u32 v65, 0xb64, v65, v52
	v_add_nc_u32_e32 v59, v59, v43
	s_clause 0x3
	global_store_b16 v66, v24, s[2:3] scale_offset
	global_store_b16 v67, v25, s[2:3] scale_offset
	global_store_b16 v68, v26, s[2:3] scale_offset
	global_store_b16 v59, v27, s[2:3] scale_offset
	s_wait_xcnt 0x3
	v_cvt_f16_f32_e32 v24, v29
	s_wait_xcnt 0x2
	v_cvt_f16_f32_e32 v25, v30
	s_wait_xcnt 0x1
	v_cvt_f16_f32_e32 v26, v31
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v27, v64, v40
	s_clause 0x4
	global_store_b16 v61, v28, s[2:3] scale_offset
	global_store_b16 v62, v24, s[2:3] scale_offset
	global_store_b16 v63, v25, s[2:3] scale_offset
	global_store_b16 v65, v26, s[2:3] scale_offset
	global_store_b16 v27, v16, s[2:3] scale_offset
	s_wait_xcnt 0x1
	v_dual_add_nc_u32 v26, v64, v43 :: v_dual_bitop2_b32 v25, 32, v58 bitop3:0x54
	v_add_nc_u32_e32 v30, v60, v48
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v27, v60, v44 :: v_dual_add_nc_u32 v28, v60, v46
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_add_nc_u32_e32 v29, v25, v37
	v_cvt_f16_f32_e32 v16, v17
	v_dual_add_nc_u32 v17, v64, v41 :: v_dual_add_nc_u32 v24, v64, v42
	v_mad_u32 v27, 0xb64, v27, v45
	s_delay_alu instid0(VALU_DEP_4)
	v_mul_lo_u32 v29, 0xb64, v29
	v_add_nc_u32_e32 v31, v60, v51
	v_mad_u32 v28, 0xb64, v28, v47
	v_mad_u32 v30, 0xb64, v30, v49
	s_clause 0x2
	global_store_b16 v17, v16, s[2:3] scale_offset
	global_store_b16 v24, v18, s[2:3] scale_offset
	global_store_b16 v26, v19, s[2:3] scale_offset
	s_wait_xcnt 0x2
	v_cvt_f16_f32_e32 v16, v20
	v_cvt_f16_f32_e32 v17, v21
	s_wait_xcnt 0x1
	v_cvt_f16_f32_e32 v18, v22
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v19, v23
	v_cvt_f16_f32_e32 v8, v8
	v_dual_add_nc_u32 v22, v25, v48 :: v_dual_add_nc_u32 v23, v25, v51
	v_add_nc_u32_e32 v20, v29, v40
	v_mad_u32 v31, 0xb64, v31, v52
	v_cvt_f16_f32_e32 v10, v10
	s_delay_alu instid0(VALU_DEP_4)
	v_mad_u32 v22, 0xb64, v22, v49
	s_clause 0x4
	global_store_b16 v27, v16, s[2:3] scale_offset
	global_store_b16 v28, v17, s[2:3] scale_offset
	global_store_b16 v30, v18, s[2:3] scale_offset
	global_store_b16 v31, v19, s[2:3] scale_offset
	global_store_b16 v20, v8, s[2:3] scale_offset
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v18, v29, v43 :: v_dual_bitop2_b32 v17, 48, v58 bitop3:0x54
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v19, v25, v44 :: v_dual_add_nc_u32 v20, v25, v46
	v_cvt_f16_f32_e32 v8, v9
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_add_nc_u32_e32 v21, v17, v37
	v_dual_add_nc_u32 v9, v29, v41 :: v_dual_add_nc_u32 v16, v29, v42
	v_mad_u32 v19, 0xb64, v19, v45
	v_mad_u32 v20, 0xb64, v20, v47
	s_delay_alu instid0(VALU_DEP_4)
	v_mul_lo_u32 v21, 0xb64, v21
	v_cvt_f16_f32_e32 v11, v11
	v_mad_u32 v23, 0xb64, v23, v52
	s_clause 0x2
	global_store_b16 v9, v8, s[2:3] scale_offset
	global_store_b16 v16, v10, s[2:3] scale_offset
	global_store_b16 v18, v11, s[2:3] scale_offset
	s_wait_xcnt 0x2
	v_cvt_f16_f32_e32 v8, v12
	v_cvt_f16_f32_e32 v9, v13
	s_wait_xcnt 0x1
	v_cvt_f16_f32_e32 v10, v14
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v11, v15
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f16_f32_e32 v2, v2
	v_add_nc_u32_e32 v12, v21, v40
	s_clause 0x4
	global_store_b16 v19, v8, s[2:3] scale_offset
	global_store_b16 v20, v9, s[2:3] scale_offset
	global_store_b16 v22, v10, s[2:3] scale_offset
	global_store_b16 v23, v11, s[2:3] scale_offset
	global_store_b16 v12, v0, s[2:3] scale_offset
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v9, v17, v44 :: v_dual_add_nc_u32 v10, v17, v46
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v11, v17, v48 :: v_dual_add_nc_u32 v12, v17, v51
	v_cvt_f16_f32_e32 v0, v1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_mad_u32 v9, 0xb64, v9, v45
	v_mad_u32 v10, 0xb64, v10, v47
	v_mad_u32 v11, 0xb64, v11, v49
	v_add_nc_u32_e32 v1, v21, v41
	v_mad_u32 v12, 0xb64, v12, v52
	v_dual_add_nc_u32 v8, v21, v42 :: v_dual_add_nc_u32 v13, v21, v43
	v_cvt_f16_f32_e32 v3, v3
	v_cvt_f16_f32_e32 v4, v4
	s_mov_b32 s8, 64
	s_and_b32 vcc_lo, exec_lo, s1
	s_mov_b32 s1, 0
	v_cvt_f16_f32_e32 v5, v5
	v_cvt_f16_f32_e32 v6, v6
	v_cvt_f16_f32_e32 v7, v7
	s_clause 0x6
	global_store_b16 v1, v0, s[2:3] scale_offset
	global_store_b16 v8, v2, s[2:3] scale_offset
	global_store_b16 v13, v3, s[2:3] scale_offset
	global_store_b16 v9, v4, s[2:3] scale_offset
	global_store_b16 v10, v5, s[2:3] scale_offset
	global_store_b16 v11, v6, s[2:3] scale_offset
	global_store_b16 v12, v7, s[2:3] scale_offset
	s_wait_storecnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccnz .LBB1_14
.LBB1_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_3 Depth 2
                                        ;     Child Loop BB1_5 Depth 2
                                        ;     Child Loop BB1_8 Depth 2
                                        ;       Child Loop BB1_10 Depth 3
                                        ;       Child Loop BB1_12 Depth 3
	s_wait_xcnt 0x6
	v_dual_mov_b32 v0, v54 :: v_dual_mov_b32 v1, v50
	s_wait_xcnt 0x5
	v_mov_b32_e32 v2, v53
	s_xor_b32 s1, s1, -1
	s_mov_b32 s9, 0
.LBB1_3:                                ;   Parent Loop BB1_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_wait_xcnt 0x4
	v_mul_hi_u32 v3, 0x59e60383, v0
	v_add_nc_u32_e32 v2, 0x80, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0x77f, v2
	s_or_b32 s9, vcc_lo, s9
	v_lshrrev_b32_e32 v3, 10, v3
	s_wait_xcnt 0x3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v4, 0xb64, v3
	v_sub_nc_u32_e32 v4, v0, v4
	v_lshl_or_b32 v3, v3, 6, v34
	v_add_nc_u32_e32 v0, 4, v0
	s_wait_xcnt 0x2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_lshrrev_b16 v5, 1, v4
	v_mul_lo_u32 v3, 0xc40, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v5, 0xffff, v5
	v_mul_u32_u24_e32 v5, 0x97b5, v5
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v5, 20, v5
	s_wait_xcnt 0x1
	v_mul_lo_u16 v6, v5, 54
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_nc_u16 v4, v4, v6
	v_and_b32_e32 v4, 0xffff, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_add_nc_u32 v4, v4, v39 :: v_dual_add_nc_u32 v5, v5, v38
	v_mul_u32_u24_e32 v5, 56, v5
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v3, v4, v3, v5
	s_wait_kmcnt 0x0
	global_load_u8 v3, v3, s[4:5]
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_fp8_e32 v3, v3
	s_delay_alu instid0(VALU_DEP_1)
	v_cvt_f16_f32_e32 v3, v3
	ds_store_b16 v1, v3
	v_add_nc_u32_e32 v1, 0x100, v1
	s_and_not1_b32 exec_lo, exec_lo, s9
	s_cbranch_execnz .LBB1_3
; %bb.4:                                ;   in Loop: Header=BB1_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s9
	v_add_nc_u32_e32 v0, s8, v56
	s_mov_b32 s9, 0
	v_mov_b32_e32 v3, v53
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_lo_u32 v1, 0x240, v0
	v_dual_mov_b32 v0, v55 :: v_dual_bitop2_b32 v2, v32, v1 bitop3:0x54
.LBB1_5:                                ;   Parent Loop BB1_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u8 v4, v2, s[6:7]
	v_add_nc_u32_e32 v3, 0x80, v3
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 0x900, v2
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 0x77f, v3
	s_or_b32 s9, vcc_lo, s9
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v4, v4
	v_cvt_f16_f32_e32 v4, v4
	ds_store_b16 v0, v4
	v_add_nc_u32_e32 v0, 0x100, v0
	s_and_not1_b32 exec_lo, exec_lo, s9
	s_cbranch_execnz .LBB1_5
; %bb.6:                                ;   in Loop: Header=BB1_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s9
	v_dual_mov_b32 v0, 0 :: v_dual_add_nc_u32 v58, v57, v1
	s_mov_b32 s9, 0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_dual_mov_b32 v7, v0 :: v_dual_mov_b32 v24, v0
	v_dual_mov_b32 v25, v0 :: v_dual_mov_b32 v26, v0
	v_dual_mov_b32 v27, v0 :: v_dual_mov_b32 v28, v0
	v_dual_mov_b32 v29, v0 :: v_dual_mov_b32 v30, v0
	v_dual_mov_b32 v31, v0 :: v_dual_mov_b32 v16, v0
	v_dual_mov_b32 v17, v0 :: v_dual_mov_b32 v18, v0
	v_dual_mov_b32 v19, v0 :: v_dual_mov_b32 v20, v0
	v_dual_mov_b32 v21, v0 :: v_dual_mov_b32 v22, v0
	v_dual_mov_b32 v23, v0 :: v_dual_mov_b32 v8, v0
	v_dual_mov_b32 v9, v0 :: v_dual_mov_b32 v10, v0
	v_dual_mov_b32 v11, v0 :: v_dual_mov_b32 v12, v0
	v_dual_mov_b32 v13, v0 :: v_dual_mov_b32 v14, v0
	v_mov_b32_e32 v15, v0
	s_barrier_wait -1
	s_branch .LBB1_8
.LBB1_7:                                ;   in Loop: Header=BB1_8 Depth=2
	s_lshl_b32 s10, s10, 12
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_add_nc_u32 v58, 32, v58 :: v_dual_bitop2_b32 v59, s10, v35 bitop3:0x54
	v_add_nc_u32_e32 v76, s10, v36
	s_cmp_eq_u32 s9, 18
	ds_load_b128 v[60:63], v59
	ds_load_b128 v[64:67], v59 offset:32
	ds_load_b128 v[68:71], v76
	ds_load_b128 v[72:75], v76 offset:32
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[24:31], v[60:67], v[68:75], v[24:31]
	ds_load_b128 v[68:71], v76 offset:1024
	ds_load_b128 v[72:75], v76 offset:1056
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[16:23], v[60:67], v[68:75], v[16:23]
	ds_load_b128 v[68:71], v76 offset:2048
	ds_load_b128 v[72:75], v76 offset:2080
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[8:15], v[60:67], v[68:75], v[8:15]
	ds_load_b128 v[68:71], v76 offset:3072
	ds_load_b128 v[72:75], v76 offset:3104
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[0:7], v[60:67], v[68:75], v[0:7]
	s_cbranch_scc1 .LBB1_1
.LBB1_8:                                ;   Parent Loop BB1_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB1_10 Depth 3
                                        ;       Child Loop BB1_12 Depth 3
	s_mov_b32 s11, s9
	s_and_b32 s10, s9, 1
	s_add_co_i32 s9, s9, 1
	s_cmp_eq_u32 s11, 17
	s_cbranch_scc1 .LBB1_7
; %bb.9:                                ;   in Loop: Header=BB1_8 Depth=2
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v60, s9, 5, v32
	s_lshl_b32 s11, s10, 12
	v_mov_b32_e32 v64, v53
	s_mov_b32 s12, 0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v59, 0xffff, v60
	v_mul_u32_u24_e32 v59, 0xe38f, v59
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v59, 19, v59
	v_mul_lo_u16 v61, v59, 9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_nc_u16 v60, v60, v61
	v_mul_lo_u16 v61, 0xab, v60
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b16 v62, 9, v61
	v_mul_lo_u16 v61, v62, 3
	v_and_b32_e32 v62, 0xffff, v62
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_sub_nc_u16 v63, v60, v61
	v_mov_b32_e32 v60, v54
	v_bitop3_b32 v61, v50, s11, 0x1000 bitop3:0xf6
	s_xor_b32 s11, s11, 0x1000
	v_and_b32_e32 v63, 0xff, v63
.LBB1_10:                               ;   Parent Loop BB1_2 Depth=1
                                        ;     Parent Loop BB1_8 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_mul_hi_u32 v65, 0x59e60383, v60
	v_add_nc_u32_e32 v64, 0x80, v64
	v_cmp_lt_u32_e32 vcc_lo, 0x77f, v64
	s_or_b32 s12, vcc_lo, s12
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v65, 10, v65
	v_mul_u32_u24_e32 v66, 0xb64, v65
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_sub_nc_u32_e32 v66, v60, v66
	v_lshl_add_u32 v65, v65, 6, v59
	v_add_nc_u32_e32 v60, 4, v60
	v_lshrrev_b16 v67, 1, v66
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v65, 0xc40, v65
	v_and_b32_e32 v67, 0xffff, v67
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v67, 0x97b5, v67
	v_lshrrev_b32_e32 v67, 20, v67
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_lo_u16 v68, v67, 54
	v_sub_nc_u16 v66, v66, v68
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v66, 0xffff, v66
	v_dual_add_nc_u32 v67, v67, v62 :: v_dual_add_nc_u32 v66, v66, v63
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v67, 56, v67
	v_add3_u32 v65, v66, v65, v67
	global_load_u8 v65, v65, s[4:5]
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_cvt_f32_fp8_e32 v65, v65
	s_delay_alu instid0(VALU_DEP_1)
	v_cvt_f16_f32_e32 v65, v65
	ds_store_b16 v61, v65
	v_add_nc_u32_e32 v61, 0x100, v61
	s_and_not1_b32 exec_lo, exec_lo, s12
	s_cbranch_execnz .LBB1_10
; %bb.11:                               ;   in Loop: Header=BB1_8 Depth=2
	s_or_b32 exec_lo, exec_lo, s12
	v_dual_mov_b32 v60, v58 :: v_dual_add_nc_u32 v59, s11, v55
	v_mov_b32_e32 v61, v53
	s_mov_b32 s11, 0
.LBB1_12:                               ;   Parent Loop BB1_2 Depth=1
                                        ;     Parent Loop BB1_8 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	global_load_u8 v62, v60, s[6:7]
	v_add_nc_u32_e32 v61, 0x80, v61
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v60, 0x900, v60
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 0x77f, v61
	s_or_b32 s11, vcc_lo, s11
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v62, v62
	v_cvt_f16_f32_e32 v62, v62
	ds_store_b16 v59, v62
	v_add_nc_u32_e32 v59, 0x100, v59
	s_and_not1_b32 exec_lo, exec_lo, s11
	s_cbranch_execnz .LBB1_12
; %bb.13:                               ;   in Loop: Header=BB1_8 Depth=2
	s_or_b32 exec_lo, exec_lo, s11
	s_branch .LBB1_7
.LBB1_14:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel convolution_f8_original
		.amdhsa_group_segment_fixed_size 16384
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 77
		.amdhsa_next_free_sgpr 13
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 25
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
	.size	convolution_f8_original, .Lfunc_end1-convolution_f8_original
                                        ; -- End function
	.set convolution_f8_original.num_vgpr, 77
	.set convolution_f8_original.num_agpr, 0
	.set convolution_f8_original.numbered_sgpr, 13
	.set convolution_f8_original.num_named_barrier, 0
	.set convolution_f8_original.private_seg_size, 0
	.set convolution_f8_original.uses_vcc, 1
	.set convolution_f8_original.uses_flat_scratch, 0
	.set convolution_f8_original.has_dyn_sized_stack, 0
	.set convolution_f8_original.has_recursion, 0
	.set convolution_f8_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3096
; TotalNumSgprs: 15
; NumVgprs: 77
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16384 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 15
; NumVGPRsForWavesPerEU: 77
; NamedBarCnt: 0
; Occupancy: 12
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
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
	.type	__hip_cuid_b89ae42108a03594,@object ; @__hip_cuid_b89ae42108a03594
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_b89ae42108a03594
__hip_cuid_b89ae42108a03594:
	.byte	0                               ; 0x0
	.size	__hip_cuid_b89ae42108a03594, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_b89ae42108a03594
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
    .group_segment_fixed_size: 24576
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           convolution_f16_original
    .private_segment_fixed_size: 0
    .sgpr_count:     25
    .sgpr_spill_count: 0
    .symbol:         convolution_f16_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     176
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
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           convolution_f8_original
    .private_segment_fixed_size: 0
    .sgpr_count:     15
    .sgpr_spill_count: 0
    .symbol:         convolution_f8_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     77
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
