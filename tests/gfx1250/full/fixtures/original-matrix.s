	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	gemm_f16_full           ; -- Begin function gemm_f16_full
	.globl	gemm_f16_full
	.p2align	8
	.type	gemm_f16_full,@function
gemm_f16_full:                          ; @gemm_f16_full
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_bfe_u32 s4, ttmp6, 0x40010
	s_add_co_i32 s2, s2, 1
	s_and_b32 s3, ttmp6, 15
	s_mul_i32 s2, ttmp9, s2
	s_add_co_i32 s4, s4, 1
	v_or_b32_e32 v2, 0x800, v0
	s_add_co_i32 s3, s3, s2
	s_mul_i32 s2, ttmp7, s4
	s_bfe_u32 s4, ttmp6, 0x40004
	s_getreg_b32 s5, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s2, s4, s2
	s_cmp_eq_u32 s5, 0
	v_or_b32_e32 v1, 0x400, v0
	v_lshrrev_b32_e32 v5, 5, v2
	s_cselect_b32 s10, ttmp9, s3
	s_cselect_b32 s8, ttmp7, s2
	s_lshl_b32 s2, s10, 8
	v_dual_lshrrev_b32 v17, 5, v0 :: v_dual_lshrrev_b32 v4, 5, v1
	v_and_b32_e32 v1, 31, v0
	v_or_b32_e32 v7, 0x1000, v0
	v_or_b32_e32 v6, s2, v5
	s_load_b128 s[4:7], s[0:1], 0x0
	v_or_b32_e32 v8, 0x1400, v0
	v_or_b32_e32 v9, 0x1800, v0
	v_or_b32_e32 v10, 0x1c00, v0
	v_lshrrev_b32_e32 v7, 5, v7
	v_lshl_or_b32 v36, v6, 12, v1
	v_or_b32_e32 v6, 0xc00, v0
	v_dual_lshrrev_b32 v8, 5, v8 :: v_dual_lshrrev_b32 v9, 5, v9
	s_lshl_b32 s3, s8, 8
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_lshrrev_b32 v6, 5, v6 :: v_dual_bitop2_b32 v3, s2, v4 bitop3:0x54
	v_dual_lshrrev_b32 v10, 5, v10 :: v_dual_bitop2_b32 v13, s2, v7 bitop3:0x54
	v_lshl_add_u32 v11, v1, 12, s3
	v_or_b32_e32 v2, s2, v17
	v_dual_lshlrev_b32 v76, 2, v0 :: v_dual_bitop2_b32 v15, s2, v9 bitop3:0x54
	v_lshl_or_b32 v34, v3, 12, v1
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v12, s2, v6 bitop3:0x54
	v_dual_lshrrev_b32 v111, 6, v0 :: v_dual_bitop2_b32 v16, s2, v10 bitop3:0x54
	v_lshrrev_b32_e32 v77, 1, v0
	v_or_b32_e32 v56, v11, v4
	v_dual_lshlrev_b32 v78, 6, v0 :: v_dual_bitop2_b32 v54, v11, v5 bitop3:0x54
	v_dual_lshlrev_b32 v104, 1, v0 :: v_dual_bitop2_b32 v52, v11, v6 bitop3:0x54
	v_dual_mov_b32 v57, v3 :: v_dual_bitop2_b32 v110, 15, v0 bitop3:0x40
	v_or_b32_e32 v105, 0xfffffc00, v0
	v_lshlrev_b32_e32 v0, 12, v17
	v_lshl_or_b32 v2, v2, 12, v1
	v_and_b32_e32 v113, 0x80, v76
	s_wait_kmcnt 0x0
	s_clause 0x2
	global_load_u16 v58, v2, s[4:5] scale_offset
	global_load_u16 v59, v34, s[4:5] scale_offset
	global_load_u16 v60, v36, s[4:5] scale_offset
	v_lshl_or_b32 v0, s10, 20, v0
	v_lshl_or_b32 v38, v16, 12, v1
	v_lshl_add_u64 v[74:75], v[2:3], 1, s[4:5]
	v_dual_mov_b32 v16, v3 :: v_dual_bitop2_b32 v112, 8, v77 bitop3:0x40
	v_and_b32_e32 v77, 0x3c0, v78
	v_or_b32_e32 v78, v113, v110
	s_wait_xcnt 0x2
	v_or_b32_e32 v2, v11, v17
	v_dual_mov_b32 v35, v3 :: v_dual_bitop2_b32 v14, s2, v8 bitop3:0x54
	v_or3_b32 v107, v0, v1, 32
	v_lshl_or_b32 v46, v12, 12, v1
	v_dual_mov_b32 v17, v3 :: v_dual_lshlrev_b32 v83, 6, v78
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_mov_b32 v114, v107 :: v_dual_add_nc_u32 v109, 0x20000, v2
	v_dual_lshlrev_b32 v82, 1, v112 :: v_dual_bitop2_b32 v50, v11, v7 bitop3:0x54
	v_lshl_or_b32 v44, v13, 12, v1
	v_dual_lshlrev_b32 v76, 10, v111 :: v_dual_bitop2_b32 v48, v11, v8 bitop3:0x54
	v_lshl_or_b32 v42, v14, 12, v1
	v_lshl_or_b32 v40, v15, 12, v1
	v_dual_mov_b32 v115, v109 :: v_dual_bitop2_b32 v62, v11, v9 bitop3:0x54
	v_or_b32_e32 v64, v11, v10
	s_clause 0x4
	global_load_u16 v61, v46, s[4:5] scale_offset
	global_load_u16 v66, v44, s[4:5] scale_offset
	global_load_u16 v67, v42, s[4:5] scale_offset
	global_load_u16 v68, v40, s[4:5] scale_offset
	global_load_u16 v69, v38, s[4:5] scale_offset
	s_clause 0x7
	global_load_u16 v70, v2, s[6:7] scale_offset
	global_load_u16 v71, v56, s[6:7] scale_offset
	global_load_u16 v72, v54, s[6:7] scale_offset
	global_load_u16 v73, v52, s[6:7] scale_offset
	global_load_u16 v116, v50, s[6:7] scale_offset
	global_load_u16 v118, v48, s[6:7] scale_offset
	global_load_u16 v119, v62, s[6:7] scale_offset
	global_load_u16 v120, v64, s[6:7] scale_offset
	s_load_b64 s[0:1], s[0:1], 0x10
	v_dual_mov_b32 v37, v3 :: v_dual_mov_b32 v55, v3
	v_dual_mov_b32 v47, v3 :: v_dual_mov_b32 v53, v3
	v_dual_mov_b32 v45, v3 :: v_dual_mov_b32 v51, v3
	v_dual_mov_b32 v43, v3 :: v_dual_mov_b32 v49, v3
	v_dual_mov_b32 v41, v3 :: v_dual_mov_b32 v63, v3
	v_dual_mov_b32 v39, v3 :: v_dual_mov_b32 v65, v3
	v_dual_mov_b32 v4, v3 :: v_dual_mov_b32 v5, v3
	v_dual_mov_b32 v6, v3 :: v_dual_mov_b32 v7, v3
	v_dual_mov_b32 v8, v3 :: v_dual_mov_b32 v9, v3
	v_dual_mov_b32 v26, v3 :: v_dual_mov_b32 v27, v3
	v_dual_mov_b32 v28, v3 :: v_dual_mov_b32 v29, v3
	v_dual_mov_b32 v30, v3 :: v_dual_mov_b32 v31, v3
	v_dual_mov_b32 v32, v3 :: v_dual_mov_b32 v33, v3
	v_dual_mov_b32 v18, v3 :: v_dual_mov_b32 v19, v3
	v_dual_mov_b32 v20, v3 :: v_dual_mov_b32 v21, v3
	v_dual_mov_b32 v22, v3 :: v_dual_mov_b32 v23, v3
	v_dual_mov_b32 v24, v3 :: v_dual_mov_b32 v25, v3
	v_dual_mov_b32 v10, v3 :: v_dual_mov_b32 v11, v3
	v_dual_mov_b32 v12, v3 :: v_dual_mov_b32 v13, v3
	v_dual_mov_b32 v14, v3 :: v_dual_mov_b32 v15, v3
	v_or_b32_e32 v117, 0x8000, v104
	v_or3_b32 v106, v76, v77, v82
	v_lshl_add_u64 v[78:79], v[56:57], 1, s[6:7]
	v_lshl_add_u64 v[88:89], v[54:55], 1, s[6:7]
	v_lshl_add_u64 v[94:95], v[52:53], 1, s[6:7]
	v_lshl_add_u64 v[76:77], v[50:51], 1, s[6:7]
	v_lshl_add_u64 v[80:81], v[48:49], 1, s[6:7]
	v_lshl_add_u64 v[84:85], v[62:63], 1, s[6:7]
	v_lshl_add_u64 v[0:1], v[64:65], 1, s[6:7]
	v_or3_b32 v108, v82, v83, 0x8000
	v_lshl_add_u64 v[82:83], v[34:35], 1, s[4:5]
	v_lshl_add_u64 v[86:87], v[36:37], 1, s[4:5]
	v_lshl_add_u64 v[90:91], v[46:47], 1, s[4:5]
	v_lshl_add_u64 v[96:97], v[44:45], 1, s[4:5]
	v_lshl_add_u64 v[98:99], v[42:43], 1, s[4:5]
	v_lshl_add_u64 v[100:101], v[40:41], 1, s[4:5]
	v_lshl_add_u64 v[92:93], v[38:39], 1, s[4:5]
	v_lshl_add_u64 v[102:103], v[2:3], 1, s[6:7]
	v_mov_b32_e32 v2, v3
	s_mov_b32 s8, 0
	s_mov_b32 s9, -1
	s_wait_loadcnt 0xf
	ds_store_b16 v104, v58
	s_wait_loadcnt 0xe
	ds_store_b16 v104, v59 offset:2048
	s_wait_loadcnt 0xd
	ds_store_b16 v104, v60 offset:4096
	s_wait_loadcnt 0xc
	ds_store_b16 v104, v61 offset:6144
	s_wait_loadcnt 0xb
	ds_store_b16 v104, v66 offset:8192
	s_wait_loadcnt 0xa
	ds_store_b16 v104, v67 offset:10240
	s_wait_loadcnt 0x9
	ds_store_b16 v104, v68 offset:12288
	s_wait_loadcnt 0x8
	ds_store_b16 v104, v69 offset:14336
	s_wait_loadcnt 0x7
	ds_store_b16 v104, v70 offset:32768
	s_wait_loadcnt 0x6
	ds_store_b16 v104, v71 offset:34816
	s_wait_loadcnt 0x5
	ds_store_b16 v104, v72 offset:36864
	s_wait_loadcnt 0x4
	ds_store_b16 v104, v73 offset:38912
	s_wait_loadcnt 0x3
	ds_store_b16 v104, v116 offset:40960
	s_wait_loadcnt 0x2
	ds_store_b16 v104, v118 offset:43008
	s_wait_loadcnt 0x1
	ds_store_b16 v104, v119 offset:45056
	s_wait_loadcnt 0x0
	ds_store_b16 v104, v120 offset:47104
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB0_2
.LBB0_1:                                ;   in Loop: Header=BB0_2 Depth=1
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[26:33], v[34:41], v[66:73], v[26:33]
	v_add_nc_u32_e32 v115, 0x20000, v115
	v_add_nc_u32_e32 v114, 32, v114
	s_add_co_i32 s8, s8, 32
	s_xor_b32 s9, s9, -1
	s_and_b32 vcc_lo, exec_lo, s10
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_wmma_f32_16x16x32_f16 v[18:25], v[34:41], v[58:65], v[18:25]
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[10:17], v[34:41], v[50:57], v[10:17]
	v_wmma_f32_16x16x32_f16 v[2:9], v[34:41], v[42:49], v[2:9]
	s_cbranch_vccnz .LBB0_6
.LBB0_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_4 Depth 2
	s_lshl_b32 s10, s8, 9
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s10, s10, 0x4000
	s_cmp_gt_u32 s8, 0xfdf
	v_dual_add_nc_u32 v46, s10, v108 :: v_dual_bitop2_b32 v38, s10, v106 bitop3:0x54
	s_cselect_b32 s10, -1, 0
	ds_load_b128 v[34:37], v38
	ds_load_b128 v[38:41], v38 offset:32
	ds_load_b128 v[66:69], v46
	ds_load_b128 v[70:73], v46 offset:32
	ds_load_b128 v[58:61], v46 offset:1024
	ds_load_b128 v[62:65], v46 offset:1056
	ds_load_b128 v[50:53], v46 offset:2048
	ds_load_b128 v[54:57], v46 offset:2080
	ds_load_b128 v[42:45], v46 offset:3072
	ds_load_b128 v[46:49], v46 offset:3104
	s_and_b32 vcc_lo, exec_lo, s10
	s_cbranch_vccnz .LBB0_1
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=1
	v_cndmask_b32_e64 v119, 0, 1, s9
	v_dual_mov_b32 v116, v114 :: v_dual_mov_b32 v118, v115
	v_mov_b32_e32 v120, v105
	s_mov_b32 s11, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v119, v119, 14, v104
.LBB0_4:                                ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v121, v116, s[4:5] scale_offset
	global_load_u16 v122, v118, s[6:7] scale_offset
	v_add_nc_u32_e32 v120, 0x400, v120
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v118, 32, v118
	v_add_nc_u32_e32 v116, 0x20000, v116
	s_wait_loadcnt 0x1
	ds_store_b16 v119, v121
	s_wait_loadcnt 0x0
	ds_store_b16 v119, v122 offset:32768
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v120
	v_add_nc_u32_e32 v119, 0x800, v119
	s_or_b32 s11, vcc_lo, s11
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s11
	s_cbranch_execnz .LBB0_4
; %bb.5:                                ;   in Loop: Header=BB0_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s11
	s_branch .LBB0_1
.LBB0_6:
	v_or3_b32 v72, v110, s3, v113
	v_nop
	v_nop
	v_nop
	v_lshlrev_b32_e32 v34, 4, v111
	v_cvt_f16_f32_e32 v26, v26
	v_cvt_f16_f32_e32 v27, v27
	v_cvt_f16_f32_e32 v28, v28
	v_cvt_f16_f32_e32 v29, v29
	v_or3_b32 v34, v34, v112, s2
	v_cvt_f16_f32_e32 v30, v30
	v_cvt_f16_f32_e32 v31, v31
	v_cvt_f16_f32_e32 v32, v32
	v_cvt_f16_f32_e32 v33, v33
	v_lshlrev_b32_e32 v73, 12, v34
	v_cvt_f16_f32_e32 v18, v18
	v_cvt_f16_f32_e32 v19, v19
	v_cvt_f16_f32_e32 v20, v20
	v_cvt_f16_f32_e32 v21, v21
	v_or_b32_e32 v115, 0x2000, v73
	v_cvt_f16_f32_e32 v22, v22
	v_cvt_f16_f32_e32 v25, v25
	v_cvt_f16_f32_e32 v23, v23
	v_cvt_f16_f32_e32 v24, v24
	v_add_nc_u32_e32 v36, v72, v115
	v_or_b32_e32 v116, 0x1000, v73
	v_or_b32_e32 v114, 0x3000, v73
	v_or_b32_e32 v112, 0x4000, v73
	v_add_nc_u32_e32 v34, v72, v73
	v_or_b32_e32 v111, 0x5000, v73
	v_or_b32_e32 v110, 0x6000, v73
	v_or_b32_e32 v113, 0x7000, v73
	v_dual_add_nc_u32 v35, v72, v116 :: v_dual_add_nc_u32 v37, v72, v114
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_add_nc_u32 v38, v72, v112 :: v_dual_add_nc_u32 v39, v72, v111
	v_dual_add_nc_u32 v40, v72, v110 :: v_dual_add_nc_u32 v41, v72, v113
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b16 v34, v26, s[0:1] scale_offset
	global_store_b16 v35, v27, s[0:1] scale_offset
	global_store_b16 v36, v28, s[0:1] scale_offset
	global_store_b16 v37, v29, s[0:1] scale_offset
	global_store_b16 v38, v30, s[0:1] scale_offset
	global_store_b16 v39, v31, s[0:1] scale_offset
	global_store_b16 v40, v32, s[0:1] scale_offset
	global_store_b16 v41, v33, s[0:1] scale_offset
	s_wait_xcnt 0x7
	v_or_b32_e32 v34, 32, v72
	v_or_b32_e32 v42, 16, v72
	v_cvt_f16_f32_e32 v10, v10
	v_cvt_f16_f32_e32 v11, v11
	v_cvt_f16_f32_e32 v12, v12
	v_cvt_f16_f32_e32 v13, v13
	s_wait_xcnt 0x6
	v_dual_add_nc_u32 v26, v42, v73 :: v_dual_add_nc_u32 v27, v42, v116
	s_wait_xcnt 0x4
	v_dual_add_nc_u32 v28, v42, v115 :: v_dual_add_nc_u32 v29, v42, v114
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v30, v42, v112 :: v_dual_add_nc_u32 v31, v42, v111
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v32, v42, v110 :: v_dual_add_nc_u32 v33, v42, v113
	s_clause 0x7
	global_store_b16 v26, v18, s[0:1] scale_offset
	global_store_b16 v27, v19, s[0:1] scale_offset
	global_store_b16 v28, v20, s[0:1] scale_offset
	global_store_b16 v29, v21, s[0:1] scale_offset
	global_store_b16 v30, v22, s[0:1] scale_offset
	global_store_b16 v31, v23, s[0:1] scale_offset
	global_store_b16 v32, v24, s[0:1] scale_offset
	global_store_b16 v33, v25, s[0:1] scale_offset
	s_wait_xcnt 0x7
	v_add_nc_u32_e32 v18, v34, v73
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v25, v34, v113 :: v_dual_bitop2_b32 v26, 48, v72 bitop3:0x54
	v_dual_add_nc_u32 v19, v34, v116 :: v_dual_add_nc_u32 v20, v34, v115
	v_dual_add_nc_u32 v21, v34, v114 :: v_dual_add_nc_u32 v22, v34, v112
	v_cvt_f16_f32_e32 v14, v14
	v_cvt_f16_f32_e32 v15, v15
	v_dual_add_nc_u32 v23, v34, v111 :: v_dual_add_nc_u32 v24, v34, v110
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f16_f32_e32 v17, v17
	s_clause 0x7
	global_store_b16 v18, v10, s[0:1] scale_offset
	global_store_b16 v19, v11, s[0:1] scale_offset
	global_store_b16 v20, v12, s[0:1] scale_offset
	global_store_b16 v21, v13, s[0:1] scale_offset
	global_store_b16 v22, v14, s[0:1] scale_offset
	global_store_b16 v23, v15, s[0:1] scale_offset
	global_store_b16 v24, v16, s[0:1] scale_offset
	global_store_b16 v25, v17, s[0:1] scale_offset
	v_cvt_f16_f32_e32 v2, v2
	s_wait_xcnt 0x7
	v_add_nc_u32_e32 v10, v26, v73
	v_cvt_f16_f32_e32 v3, v3
	s_wait_xcnt 0x5
	v_dual_add_nc_u32 v11, v26, v116 :: v_dual_add_nc_u32 v12, v26, v115
	v_cvt_f16_f32_e32 v4, v4
	v_cvt_f16_f32_e32 v5, v5
	s_wait_xcnt 0x3
	v_dual_add_nc_u32 v13, v26, v114 :: v_dual_add_nc_u32 v14, v26, v112
	v_cvt_f16_f32_e32 v6, v6
	v_cvt_f16_f32_e32 v7, v7
	s_wait_xcnt 0x1
	v_dual_add_nc_u32 v15, v26, v111 :: v_dual_add_nc_u32 v16, v26, v110
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f16_f32_e32 v9, v9
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v17, v26, v113
	s_clause 0x7
	global_store_b16 v10, v2, s[0:1] scale_offset
	global_store_b16 v11, v3, s[0:1] scale_offset
	global_store_b16 v12, v4, s[0:1] scale_offset
	global_store_b16 v13, v5, s[0:1] scale_offset
	global_store_b16 v14, v6, s[0:1] scale_offset
	global_store_b16 v15, v7, s[0:1] scale_offset
	global_store_b16 v16, v8, s[0:1] scale_offset
	global_store_b16 v17, v9, s[0:1] scale_offset
	s_clause 0x7
	global_load_u16 v32, v[74:75], off
	global_load_u16 v33, v[82:83], off
	global_load_u16 v34, v[86:87], off
	global_load_u16 v35, v[90:91], off
	global_load_u16 v36, v[96:97], off
	global_load_u16 v37, v[98:99], off
	global_load_u16 v38, v[100:101], off
	global_load_u16 v39, v[92:93], off
	s_clause 0x7
	global_load_u16 v40, v[102:103], off
	global_load_u16 v41, v[78:79], off
	global_load_u16 v42, v[88:89], off
	global_load_u16 v43, v[94:95], off
	global_load_u16 v44, v[76:77], off
	global_load_u16 v45, v[80:81], off
	global_load_u16 v46, v[84:85], off
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	; meta instruction
	global_load_u16 v47, v[0:1], off
	s_wait_xcnt 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b32 s2, 0
	s_mov_b32 s3, -1
	s_wait_loadcnt 0xf
	ds_store_b16 v104, v32
	s_wait_loadcnt 0xe
	ds_store_b16 v104, v33 offset:2048
	s_wait_loadcnt 0xd
	ds_store_b16 v104, v34 offset:4096
	s_wait_loadcnt 0xc
	ds_store_b16 v104, v35 offset:6144
	s_wait_loadcnt 0xb
	ds_store_b16 v104, v36 offset:8192
	s_wait_loadcnt 0xa
	ds_store_b16 v104, v37 offset:10240
	s_wait_loadcnt 0x9
	ds_store_b16 v104, v38 offset:12288
	s_wait_loadcnt 0x8
	ds_store_b16 v104, v39 offset:14336
	s_wait_loadcnt 0x7
	ds_store_b16 v117, v40
	s_wait_loadcnt 0x6
	ds_store_b16 v117, v41 offset:2048
	s_wait_loadcnt 0x5
	ds_store_b16 v117, v42 offset:4096
	s_wait_loadcnt 0x4
	ds_store_b16 v117, v43 offset:6144
	s_wait_loadcnt 0x3
	ds_store_b16 v117, v44 offset:8192
	s_wait_loadcnt 0x2
	ds_store_b16 v117, v45 offset:10240
	s_wait_loadcnt 0x1
	ds_store_b16 v117, v46 offset:12288
	s_wait_loadcnt 0x0
	ds_store_b16 v117, v47 offset:14336
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
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB0_8
.LBB0_7:                                ;   in Loop: Header=BB0_8 Depth=1
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[64:71], v[24:31]
	v_add_nc_u32_e32 v109, 0x20000, v109
	v_add_nc_u32_e32 v107, 32, v107
	s_add_co_i32 s2, s2, 32
	s_xor_b32 s3, s3, -1
	s_and_not1_b32 vcc_lo, exec_lo, s8
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[56:63], v[16:23]
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[48:55], v[8:15]
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[40:47], v[0:7]
	s_cbranch_vccz .LBB0_12
.LBB0_8:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_10 Depth 2
	s_lshl_b32 s8, s2, 9
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s8, s8, 0x4000
	s_cmp_gt_u32 s2, 0xfdf
	v_dual_add_nc_u32 v44, s8, v108 :: v_dual_bitop2_b32 v36, s8, v106 bitop3:0x54
	s_cselect_b32 s8, -1, 0
	ds_load_b128 v[32:35], v36
	ds_load_b128 v[36:39], v36 offset:32
	ds_load_b128 v[64:67], v44 offset:4096
	ds_load_b128 v[68:71], v44 offset:4128
	ds_load_b128 v[56:59], v44 offset:5120
	ds_load_b128 v[60:63], v44 offset:5152
	ds_load_b128 v[48:51], v44 offset:6144
	ds_load_b128 v[52:55], v44 offset:6176
	ds_load_b128 v[40:43], v44 offset:7168
	ds_load_b128 v[44:47], v44 offset:7200
	s_and_b32 vcc_lo, exec_lo, s8
	s_cbranch_vccnz .LBB0_7
; %bb.9:                                ;   in Loop: Header=BB0_8 Depth=1
	v_cndmask_b32_e64 v76, 0, 1, s3
	v_dual_mov_b32 v74, v107 :: v_dual_mov_b32 v75, v109
	v_mov_b32_e32 v77, v105
	s_mov_b32 s9, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v76, v76, 14, v104
.LBB0_10:                               ;   Parent Loop BB0_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v78, v74, s[4:5] scale_offset
	global_load_u16 v79, v75, s[6:7] scale_offset
	v_add_nc_u32_e32 v77, 0x400, v77
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v75, 32, v75
	v_add_nc_u32_e32 v74, 0x20000, v74
	s_wait_loadcnt 0x1
	ds_store_b16 v76, v78
	s_wait_loadcnt 0x0
	ds_store_b16 v76, v79 offset:32768
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v77
	v_add_nc_u32_e32 v76, 0x800, v76
	s_or_b32 s9, vcc_lo, s9
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s9
	s_cbranch_execnz .LBB0_10
; %bb.11:                               ;   in Loop: Header=BB0_8 Depth=1
	s_or_b32 exec_lo, exec_lo, s9
	s_branch .LBB0_7
.LBB0_12:
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v40, 0x50, v72
	v_or_b32_e32 v32, 64, v72
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f16_f32_e32 v25, v25
	v_cvt_f16_f32_e32 v26, v26
	v_cvt_f16_f32_e32 v27, v27
	v_dual_add_nc_u32 v33, v32, v73 :: v_dual_add_nc_u32 v34, v32, v116
	v_dual_add_nc_u32 v35, v32, v115 :: v_dual_add_nc_u32 v36, v32, v114
	v_cvt_f16_f32_e32 v28, v28
	v_dual_add_nc_u32 v37, v32, v112 :: v_dual_add_nc_u32 v38, v32, v111
	v_dual_add_nc_u32 v39, v32, v110 :: v_dual_add_nc_u32 v32, v32, v113
	v_cvt_f16_f32_e32 v29, v29
	v_cvt_f16_f32_e32 v30, v30
	v_cvt_f16_f32_e32 v31, v31
	s_clause 0x7
	global_store_b16 v33, v24, s[0:1] scale_offset
	global_store_b16 v34, v25, s[0:1] scale_offset
	global_store_b16 v35, v26, s[0:1] scale_offset
	global_store_b16 v36, v27, s[0:1] scale_offset
	global_store_b16 v37, v28, s[0:1] scale_offset
	global_store_b16 v38, v29, s[0:1] scale_offset
	global_store_b16 v39, v30, s[0:1] scale_offset
	global_store_b16 v32, v31, s[0:1] scale_offset
	v_cvt_f16_f32_e32 v16, v16
	s_wait_xcnt 0x7
	v_add_nc_u32_e32 v24, v40, v73
	s_wait_xcnt 0x0
	v_or_b32_e32 v32, 0x60, v72
	v_cvt_f16_f32_e32 v17, v17
	v_dual_add_nc_u32 v25, v40, v116 :: v_dual_add_nc_u32 v26, v40, v115
	v_cvt_f16_f32_e32 v18, v18
	v_cvt_f16_f32_e32 v19, v19
	v_dual_add_nc_u32 v27, v40, v114 :: v_dual_add_nc_u32 v28, v40, v112
	v_cvt_f16_f32_e32 v20, v20
	v_cvt_f16_f32_e32 v21, v21
	v_dual_add_nc_u32 v29, v40, v111 :: v_dual_add_nc_u32 v30, v40, v110
	v_cvt_f16_f32_e32 v22, v22
	v_cvt_f16_f32_e32 v23, v23
	v_add_nc_u32_e32 v31, v40, v113
	s_clause 0x7
	global_store_b16 v24, v16, s[0:1] scale_offset
	global_store_b16 v25, v17, s[0:1] scale_offset
	global_store_b16 v26, v18, s[0:1] scale_offset
	global_store_b16 v27, v19, s[0:1] scale_offset
	global_store_b16 v28, v20, s[0:1] scale_offset
	global_store_b16 v29, v21, s[0:1] scale_offset
	global_store_b16 v30, v22, s[0:1] scale_offset
	global_store_b16 v31, v23, s[0:1] scale_offset
	v_cvt_f16_f32_e32 v8, v8
	s_wait_xcnt 0x6
	v_dual_add_nc_u32 v16, v32, v73 :: v_dual_add_nc_u32 v17, v32, v116
	v_or_b32_e32 v24, 0x70, v72
	v_cvt_f16_f32_e32 v9, v9
	v_cvt_f16_f32_e32 v10, v10
	s_wait_xcnt 0x4
	v_dual_add_nc_u32 v18, v32, v115 :: v_dual_add_nc_u32 v19, v32, v114
	v_cvt_f16_f32_e32 v11, v11
	v_cvt_f16_f32_e32 v12, v12
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v20, v32, v112 :: v_dual_add_nc_u32 v21, v32, v111
	v_cvt_f16_f32_e32 v13, v13
	v_cvt_f16_f32_e32 v14, v14
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v22, v32, v110 :: v_dual_add_nc_u32 v23, v32, v113
	v_cvt_f16_f32_e32 v15, v15
	s_clause 0x7
	global_store_b16 v16, v8, s[0:1] scale_offset
	global_store_b16 v17, v9, s[0:1] scale_offset
	global_store_b16 v18, v10, s[0:1] scale_offset
	global_store_b16 v19, v11, s[0:1] scale_offset
	global_store_b16 v20, v12, s[0:1] scale_offset
	global_store_b16 v21, v13, s[0:1] scale_offset
	global_store_b16 v22, v14, s[0:1] scale_offset
	global_store_b16 v23, v15, s[0:1] scale_offset
	v_cvt_f16_f32_e32 v0, v0
	s_wait_xcnt 0x6
	v_dual_add_nc_u32 v8, v24, v73 :: v_dual_add_nc_u32 v9, v24, v116
	v_cvt_f16_f32_e32 v1, v1
	v_cvt_f16_f32_e32 v2, v2
	s_wait_xcnt 0x4
	v_dual_add_nc_u32 v10, v24, v115 :: v_dual_add_nc_u32 v11, v24, v114
	v_cvt_f16_f32_e32 v3, v3
	v_cvt_f16_f32_e32 v4, v4
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v12, v24, v112 :: v_dual_add_nc_u32 v13, v24, v111
	v_cvt_f16_f32_e32 v5, v5
	v_cvt_f16_f32_e32 v6, v6
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v14, v24, v110 :: v_dual_add_nc_u32 v15, v24, v113
	v_cvt_f16_f32_e32 v7, v7
	s_clause 0x7
	global_store_b16 v8, v0, s[0:1] scale_offset
	global_store_b16 v9, v1, s[0:1] scale_offset
	global_store_b16 v10, v2, s[0:1] scale_offset
	global_store_b16 v11, v3, s[0:1] scale_offset
	global_store_b16 v12, v4, s[0:1] scale_offset
	global_store_b16 v13, v5, s[0:1] scale_offset
	global_store_b16 v14, v6, s[0:1] scale_offset
	global_store_b16 v15, v7, s[0:1] scale_offset
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel gemm_f16_full
		.amdhsa_group_segment_fixed_size 65536
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
		.amdhsa_next_free_vgpr 123
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
		.amdhsa_inst_pref_size 33
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
	.size	gemm_f16_full, .Lfunc_end0-gemm_f16_full
                                        ; -- End function
	.set gemm_f16_full.num_vgpr, 123
	.set gemm_f16_full.num_agpr, 0
	.set gemm_f16_full.numbered_sgpr, 12
	.set gemm_f16_full.num_named_barrier, 0
	.set gemm_f16_full.private_seg_size, 0
	.set gemm_f16_full.uses_vcc, 1
	.set gemm_f16_full.uses_flat_scratch, 0
	.set gemm_f16_full.has_dyn_sized_stack, 0
	.set gemm_f16_full.has_recursion, 0
	.set gemm_f16_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4224
; TotalNumSgprs: 14
; NumVgprs: 123
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 123
; NamedBarCnt: 0
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	gemm_f8_full            ; -- Begin function gemm_f8_full
	.globl	gemm_f8_full
	.p2align	8
	.type	gemm_f8_full,@function
gemm_f8_full:                           ; @gemm_f8_full
; %bb.0:
	s_bfe_u32 s3, ttmp6, 0x4000c
	s_bfe_u32 s4, ttmp6, 0x40010
	s_add_co_i32 s3, s3, 1
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshlrev_b32 v2, 2, v0
	s_and_b32 s2, ttmp6, 15
	s_mul_i32 s3, ttmp9, s3
	s_add_co_i32 s4, s4, 1
	s_add_co_i32 s2, s2, s3
	s_mul_i32 s3, ttmp7, s4
	s_bfe_u32 s4, ttmp6, 0x40004
	s_getreg_b32 s5, hwreg(HW_REG_IB_STS2, 6, 4)
	v_dual_lshrrev_b32 v3, 6, v0 :: v_dual_lshlrev_b32 v4, 6, v0
	v_and_b32_e32 v1, 8, v1
	s_add_co_i32 s4, s4, s3
	s_cmp_eq_u32 s5, 0
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_lshlrev_b32 v6, 10, v3 :: v_dual_bitop2_b32 v5, 15, v0 bitop3:0x40
	s_cselect_b32 s2, ttmp9, s2
	v_and_b32_e32 v2, 0x80, v2
	v_and_b32_e32 v4, 0x3c0, v4
	v_dual_lshlrev_b32 v3, 16, v3 :: v_dual_lshlrev_b32 v7, 1, v1
	v_lshlrev_b32_e32 v1, 12, v1
	s_cselect_b32 s8, ttmp7, s4
	s_lshl_b32 s9, s2, 20
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_or_b32_e32 v8, v2, v5
	v_or3_b32 v72, v3, v1, s9
	v_or3_b32 v73, v6, v4, v7
	s_wait_xcnt 0x0
	s_lshl_b32 s0, s8, 8
	v_dual_lshrrev_b32 v4, 5, v0 :: v_dual_bitop2_b32 v1, 31, v0 bitop3:0x40
	v_lshlrev_b32_e32 v3, 6, v8
	v_or_b32_e32 v74, 0x1000, v72
	v_or_b32_e32 v75, 0x2000, v72
	v_or_b32_e32 v76, 0x3000, v72
	v_lshl_or_b32 v6, v1, 12, v4
	v_lshlrev_b32_e32 v4, 12, v4
	v_or_b32_e32 v77, 0x4000, v72
	v_or_b32_e32 v78, 0x5000, v72
	v_or_b32_e32 v79, 0x6000, v72
	v_or_b32_e32 v80, 0x7000, v72
	v_or3_b32 v81, v5, s0, v2
	v_add_nc_u32_e32 v82, s0, v6
	v_or3_b32 v83, s9, v4, v1
	v_or3_b32 v84, v7, v3, 0x8000
	v_or_b32_e32 v85, 0xfffffc00, v0
	v_lshlrev_b32_e32 v86, 1, v0
	s_mov_b32 s1, 0
	s_mov_b32 s0, -1
	s_branch .LBB1_2
.LBB1_1:                                ;   in Loop: Header=BB1_2 Depth=1
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v32, s1, 6, v81
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f16_f32_e32 v25, v25
	v_cvt_f16_f32_e32 v26, v26
	v_cvt_f16_f32_e32 v27, v27
	v_dual_add_nc_u32 v33, v32, v72 :: v_dual_add_nc_u32 v34, v32, v74
	v_dual_add_nc_u32 v35, v32, v75 :: v_dual_add_nc_u32 v36, v32, v76
	v_cvt_f16_f32_e32 v28, v28
	v_dual_add_nc_u32 v37, v32, v77 :: v_dual_add_nc_u32 v38, v32, v78
	v_cvt_f16_f32_e32 v29, v29
	v_cvt_f16_f32_e32 v30, v30
	v_dual_add_nc_u32 v39, v32, v79 :: v_dual_add_nc_u32 v40, v32, v80
	v_cvt_f16_f32_e32 v31, v31
	s_clause 0x7
	global_store_b16 v33, v24, s[2:3] scale_offset
	global_store_b16 v34, v25, s[2:3] scale_offset
	global_store_b16 v35, v26, s[2:3] scale_offset
	global_store_b16 v36, v27, s[2:3] scale_offset
	global_store_b16 v37, v28, s[2:3] scale_offset
	global_store_b16 v38, v29, s[2:3] scale_offset
	global_store_b16 v39, v30, s[2:3] scale_offset
	global_store_b16 v40, v31, s[2:3] scale_offset
	s_wait_xcnt 0x7
	v_or_b32_e32 v33, 32, v32
	v_or_b32_e32 v41, 16, v32
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f16_f32_e32 v17, v17
	v_cvt_f16_f32_e32 v18, v18
	v_cvt_f16_f32_e32 v19, v19
	s_wait_xcnt 0x6
	v_dual_add_nc_u32 v24, v41, v72 :: v_dual_add_nc_u32 v25, v41, v74
	s_wait_xcnt 0x4
	v_dual_add_nc_u32 v26, v41, v75 :: v_dual_add_nc_u32 v27, v41, v76
	v_cvt_f16_f32_e32 v20, v20
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v28, v41, v77 :: v_dual_add_nc_u32 v29, v41, v78
	v_cvt_f16_f32_e32 v21, v21
	v_cvt_f16_f32_e32 v22, v22
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v30, v41, v79 :: v_dual_add_nc_u32 v31, v41, v80
	v_cvt_f16_f32_e32 v23, v23
	s_clause 0x7
	global_store_b16 v24, v16, s[2:3] scale_offset
	global_store_b16 v25, v17, s[2:3] scale_offset
	global_store_b16 v26, v18, s[2:3] scale_offset
	global_store_b16 v27, v19, s[2:3] scale_offset
	global_store_b16 v28, v20, s[2:3] scale_offset
	global_store_b16 v29, v21, s[2:3] scale_offset
	global_store_b16 v30, v22, s[2:3] scale_offset
	global_store_b16 v31, v23, s[2:3] scale_offset
	v_cvt_f16_f32_e32 v8, v8
	s_wait_xcnt 0x5
	v_dual_add_nc_u32 v16, v33, v72 :: v_dual_add_nc_u32 v18, v33, v75
	v_or_b32_e32 v24, 48, v32
	v_cvt_f16_f32_e32 v9, v9
	v_add_nc_u32_e32 v17, v33, v74
	v_cvt_f16_f32_e32 v10, v10
	v_cvt_f16_f32_e32 v11, v11
	s_wait_xcnt 0x3
	v_dual_add_nc_u32 v19, v33, v76 :: v_dual_add_nc_u32 v20, v33, v77
	v_cvt_f16_f32_e32 v12, v12
	v_cvt_f16_f32_e32 v13, v13
	s_wait_xcnt 0x1
	v_dual_add_nc_u32 v21, v33, v78 :: v_dual_add_nc_u32 v22, v33, v79
	v_cvt_f16_f32_e32 v14, v14
	v_cvt_f16_f32_e32 v15, v15
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v23, v33, v80
	s_clause 0x7
	global_store_b16 v16, v8, s[2:3] scale_offset
	global_store_b16 v17, v9, s[2:3] scale_offset
	global_store_b16 v18, v10, s[2:3] scale_offset
	global_store_b16 v19, v11, s[2:3] scale_offset
	global_store_b16 v20, v12, s[2:3] scale_offset
	global_store_b16 v21, v13, s[2:3] scale_offset
	global_store_b16 v22, v14, s[2:3] scale_offset
	global_store_b16 v23, v15, s[2:3] scale_offset
	v_cvt_f16_f32_e32 v0, v0
	s_wait_xcnt 0x3
	v_dual_add_nc_u32 v8, v24, v72 :: v_dual_add_nc_u32 v12, v24, v77
	v_cvt_f16_f32_e32 v1, v1
	v_add_nc_u32_e32 v9, v24, v74
	v_cvt_f16_f32_e32 v2, v2
	v_add_nc_u32_e32 v10, v24, v75
	v_cvt_f16_f32_e32 v3, v3
	s_wait_xcnt 0x2
	v_dual_add_nc_u32 v11, v24, v76 :: v_dual_add_nc_u32 v13, v24, v78
	s_mov_b32 s1, 1
	s_and_b32 vcc_lo, exec_lo, s0
	s_mov_b32 s0, 0
	v_cvt_f16_f32_e32 v4, v4
	v_cvt_f16_f32_e32 v5, v5
	v_cvt_f16_f32_e32 v6, v6
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v14, v24, v79 :: v_dual_add_nc_u32 v15, v24, v80
	v_cvt_f16_f32_e32 v7, v7
	s_clause 0x7
	global_store_b16 v8, v0, s[2:3] scale_offset
	global_store_b16 v9, v1, s[2:3] scale_offset
	global_store_b16 v10, v2, s[2:3] scale_offset
	global_store_b16 v11, v3, s[2:3] scale_offset
	global_store_b16 v12, v4, s[2:3] scale_offset
	global_store_b16 v13, v5, s[2:3] scale_offset
	global_store_b16 v14, v6, s[2:3] scale_offset
	global_store_b16 v15, v7, s[2:3] scale_offset
	s_cbranch_vccnz .LBB1_10
.LBB1_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_3 Depth 2
                                        ;     Child Loop BB1_6 Depth 2
                                        ;       Child Loop BB1_8 Depth 3
	s_wait_xcnt 0x6
	v_dual_mov_b32 v0, v83 :: v_dual_mov_b32 v1, v82
	s_wait_xcnt 0x4
	v_dual_mov_b32 v2, v86 :: v_dual_mov_b32 v3, v85
	s_xor_b32 s0, s0, -1
	s_mov_b32 s8, 0
.LBB1_3:                                ;   Parent Loop BB1_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_wait_kmcnt 0x0
	global_load_u8 v4, v0, s[4:5]
	global_load_u8 v5, v1, s[6:7]
	v_add_nc_u32_e32 v3, 0x400, v3
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v1, 32, v1
	v_add_nc_u32_e32 v0, 0x20000, v0
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v3
	s_or_b32 s8, vcc_lo, s8
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v4, v4
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v5, v5
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_f32_e32 v4, v4
	v_cvt_f16_f32_e32 v5, v5
	ds_store_b16 v2, v4
	ds_store_b16 v2, v5 offset:32768
	v_add_nc_u32_e32 v2, 0x800, v2
	s_and_not1_b32 exec_lo, exec_lo, s8
	s_cbranch_execnz .LBB1_3
; %bb.4:                                ;   in Loop: Header=BB1_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s8
	v_dual_mov_b32 v0, 0 :: v_dual_bitop2_b32 v87, 32, v83 bitop3:0x54
	v_add_nc_u32_e32 v88, 0x20000, v82
	s_mov_b32 s8, 0
	s_mov_b32 s9, -1
	s_wait_dscnt 0x0
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
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB1_6
.LBB1_5:                                ;   in Loop: Header=BB1_6 Depth=2
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[64:71], v[24:31]
	v_add_nc_u32_e32 v88, 0x20000, v88
	v_add_nc_u32_e32 v87, 32, v87
	s_add_co_i32 s8, s8, 32
	s_xor_b32 s9, s9, -1
	s_and_b32 vcc_lo, exec_lo, s10
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[56:63], v[16:23]
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[48:55], v[8:15]
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[40:47], v[0:7]
	s_cbranch_vccnz .LBB1_1
.LBB1_6:                                ;   Parent Loop BB1_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB1_8 Depth 3
	s_lshl_b32 s10, s8, 9
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_add_u32 v32, s1, 12, v84
	s_and_b32 s10, s10, 0x4000
	s_cmp_gt_u32 s8, 0xfdf
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_nc_u32 v44, s10, v32 :: v_dual_bitop2_b32 v36, s10, v73 bitop3:0x54
	s_cselect_b32 s10, -1, 0
	ds_load_b128 v[32:35], v36
	ds_load_b128 v[36:39], v36 offset:32
	ds_load_b128 v[64:67], v44
	ds_load_b128 v[68:71], v44 offset:32
	ds_load_b128 v[56:59], v44 offset:1024
	ds_load_b128 v[60:63], v44 offset:1056
	ds_load_b128 v[48:51], v44 offset:2048
	ds_load_b128 v[52:55], v44 offset:2080
	ds_load_b128 v[40:43], v44 offset:3072
	ds_load_b128 v[44:47], v44 offset:3104
	s_and_b32 vcc_lo, exec_lo, s10
	s_cbranch_vccnz .LBB1_5
; %bb.7:                                ;   in Loop: Header=BB1_6 Depth=2
	v_cndmask_b32_e64 v91, 0, 1, s9
	v_dual_mov_b32 v89, v87 :: v_dual_mov_b32 v90, v88
	v_mov_b32_e32 v92, v85
	s_mov_b32 s11, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v91, v91, 14, v86
.LBB1_8:                                ;   Parent Loop BB1_2 Depth=1
                                        ;     Parent Loop BB1_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	global_load_u8 v93, v89, s[4:5]
	global_load_u8 v94, v90, s[6:7]
	v_add_nc_u32_e32 v92, 0x400, v92
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v90, 32, v90
	v_add_nc_u32_e32 v89, 0x20000, v89
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v92
	s_or_b32 s11, vcc_lo, s11
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v93, v93
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v94, v94
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_f32_e32 v93, v93
	v_cvt_f16_f32_e32 v94, v94
	ds_store_b16 v91, v93
	ds_store_b16 v91, v94 offset:32768
	v_add_nc_u32_e32 v91, 0x800, v91
	s_and_not1_b32 exec_lo, exec_lo, s11
	s_cbranch_execnz .LBB1_8
; %bb.9:                                ;   in Loop: Header=BB1_6 Depth=2
	s_or_b32 exec_lo, exec_lo, s11
	s_branch .LBB1_5
.LBB1_10:
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel gemm_f8_full
		.amdhsa_group_segment_fixed_size 65536
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
		.amdhsa_next_free_vgpr 95
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
.Lfunc_end1:
	.size	gemm_f8_full, .Lfunc_end1-gemm_f8_full
                                        ; -- End function
	.set gemm_f8_full.num_vgpr, 95
	.set gemm_f8_full.num_agpr, 0
	.set gemm_f8_full.numbered_sgpr, 12
	.set gemm_f8_full.num_named_barrier, 0
	.set gemm_f8_full.private_seg_size, 0
	.set gemm_f8_full.uses_vcc, 1
	.set gemm_f8_full.uses_flat_scratch, 0
	.set gemm_f8_full.has_dyn_sized_stack, 0
	.set gemm_f8_full.has_recursion, 0
	.set gemm_f8_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1884
; TotalNumSgprs: 14
; NumVgprs: 95
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 5
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 95
; NamedBarCnt: 0
; Occupancy: 10
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	gemm_add_silu_f16_full  ; -- Begin function gemm_add_silu_f16_full
	.globl	gemm_add_silu_f16_full
	.p2align	8
	.type	gemm_add_silu_f16_full,@function
gemm_add_silu_f16_full:                 ; @gemm_add_silu_f16_full
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_bfe_u32 s4, ttmp6, 0x40010
	s_add_co_i32 s2, s2, 1
	s_and_b32 s3, ttmp6, 15
	s_mul_i32 s2, ttmp9, s2
	s_add_co_i32 s4, s4, 1
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v2, 6, v0
	v_lshlrev_b32_e32 v3, 2, v0
	s_add_co_i32 s3, s3, s2
	s_mul_i32 s2, ttmp7, s4
	s_bfe_u32 s4, ttmp6, 0x40004
	s_getreg_b32 s5, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s2, s4, s2
	s_cmp_eq_u32 s5, 0
	v_dual_lshlrev_b32 v4, 4, v2 :: v_dual_bitop2_b32 v1, 8, v1 bitop3:0x40
	v_lshlrev_b32_e32 v5, 6, v0
	v_and_b32_e32 v10, 0x80, v3
	v_dual_lshlrev_b32 v2, 10, v2 :: v_dual_bitop2_b32 v11, 15, v0 bitop3:0x40
	s_load_b256 s[4:11], s[0:1], 0x0
	s_wait_xcnt 0x0
	s_cselect_b32 s1, ttmp9, s3
	s_cselect_b32 s0, ttmp7, s2
	s_lshl_b32 s2, s1, 8
	v_lshrrev_b32_e32 v13, 5, v0
	v_or3_b32 v3, v4, v1, s2
	v_and_b32_e32 v4, 0x3c0, v5
	v_dual_lshlrev_b32 v1, 1, v1 :: v_dual_bitop2_b32 v12, 31, v0 bitop3:0x40
	v_or_b32_e32 v5, v10, v11
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_lshlrev_b32_e32 v106, 12, v3
	v_or_b32_e32 v3, 0x400, v0
	v_or3_b32 v107, v2, v4, v1
	v_dual_mov_b32 v73, 0 :: v_dual_bitop2_b32 v2, s2, v13 bitop3:0x54
	s_lshl_b32 s0, s0, 8
	v_or_b32_e32 v7, 0xc00, v0
	v_lshl_add_u32 v14, v12, 12, s0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v72, v2, 12, v12
	v_or_b32_e32 v2, 0x800, v0
	v_dual_lshrrev_b32 v4, 5, v3 :: v_dual_lshlrev_b32 v114, 1, v0
	v_lshlrev_b32_e32 v15, 6, v5
	s_wait_kmcnt 0x0
	v_lshl_add_u64 v[74:75], v[72:73], 1, s[4:5]
	v_dual_lshrrev_b32 v8, 5, v2 :: v_dual_bitop2_b32 v72, v14, v13 bitop3:0x54
	v_dual_mov_b32 v5, v73 :: v_dual_bitop2_b32 v3, s2, v4 bitop3:0x54
	v_dual_lshrrev_b32 v9, 5, v7 :: v_dual_bitop2_b32 v4, v14, v4 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_or_b32_e32 v6, s2, v8
	v_or_b32_e32 v16, 0x1000, v0
	v_lshl_or_b32 v2, v3, 12, v12
	v_dual_mov_b32 v3, v73 :: v_dual_mov_b32 v7, v73
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_lshl_or_b32 v6, v6, 12, v12
	v_lshl_add_u64 v[80:81], v[4:5], 1, s[6:7]
	v_dual_lshrrev_b32 v16, 5, v16 :: v_dual_bitop2_b32 v4, s2, v9 bitop3:0x54
	v_lshl_add_u64 v[78:79], v[2:3], 1, s[4:5]
	s_delay_alu instid0(VALU_DEP_4)
	v_lshl_add_u64 v[82:83], v[6:7], 1, s[4:5]
	v_or_b32_e32 v17, 0x1400, v0
	v_or_b32_e32 v2, v14, v8
	v_lshl_or_b32 v4, v4, 12, v12
	v_or_b32_e32 v6, v14, v9
	v_dual_mov_b32 v9, v73 :: v_dual_bitop2_b32 v8, s2, v16 bitop3:0x54
	v_lshrrev_b32_e32 v17, 5, v17
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_lshl_add_u64 v[86:87], v[4:5], 1, s[4:5]
	v_or_b32_e32 v5, 0x1800, v0
	v_lshl_or_b32 v8, v8, 12, v12
	v_lshl_add_u64 v[84:85], v[2:3], 1, s[6:7]
	v_or_b32_e32 v4, s2, v17
	v_or_b32_e32 v2, v14, v16
	v_lshl_add_u64 v[88:89], v[6:7], 1, s[6:7]
	v_lshl_add_u64 v[90:91], v[8:9], 1, s[4:5]
	v_or_b32_e32 v8, 0x1c00, v0
	v_dual_lshrrev_b32 v9, 5, v5 :: v_dual_mov_b32 v5, v73
	v_lshl_or_b32 v4, v4, 12, v12
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_lshrrev_b32 v8, 5, v8 :: v_dual_bitop2_b32 v6, v14, v17 bitop3:0x54
	v_or_b32_e32 v16, s2, v9
	v_lshl_add_u64 v[92:93], v[2:3], 1, s[6:7]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_lshl_add_u64 v[94:95], v[4:5], 1, s[4:5]
	v_lshl_add_u64 v[96:97], v[6:7], 1, s[6:7]
	v_dual_lshlrev_b32 v13, 12, v13 :: v_dual_bitop2_b32 v6, s2, v8 bitop3:0x54
	v_dual_mov_b32 v9, v73 :: v_dual_bitop2_b32 v4, v14, v9 bitop3:0x54
	v_lshl_or_b32 v2, v16, 12, v12
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v6, v6, 12, v12
	v_or_b32_e32 v8, v14, v8
	v_or_b32_e32 v108, 0x1000, v106
	v_or_b32_e32 v109, 0x2000, v106
	v_lshl_add_u64 v[98:99], v[2:3], 1, s[4:5]
	v_lshl_or_b32 v2, s1, 20, v13
	v_or_b32_e32 v110, 0x3000, v106
	v_or_b32_e32 v111, 0x4000, v106
	v_or_b32_e32 v112, 0x5000, v106
	v_or_b32_e32 v113, 0x6000, v106
	v_or_b32_e32 v115, 0x7000, v106
	v_lshl_add_u64 v[76:77], v[72:73], 1, s[6:7]
	v_or_b32_e32 v116, 0x8000, v114
	v_lshl_add_u64 v[100:101], v[4:5], 1, s[6:7]
	v_lshl_add_u64 v[102:103], v[6:7], 1, s[4:5]
	v_lshl_add_u64 v[104:105], v[8:9], 1, s[6:7]
	v_or3_b32 v117, v11, s0, v10
	v_or3_b32 v118, v1, v15, 0x8000
	v_or_b32_e32 v119, 0xfffffc00, v0
	v_add_nc_u32_e32 v72, 0x20000, v72
	v_or3_b32 v120, v2, v12, 32
	s_mov_b32 s1, 0
	s_mov_b32 s2, -1
	s_branch .LBB2_2
.LBB2_1:                                ;   in Loop: Header=BB2_2 Depth=1
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v32, s1, 6, v117
	s_mov_b32 s1, 1
	s_mov_b32 s2, 0
	s_and_b32 vcc_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v33, v32, v106
	global_load_u16 v34, v33, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v34, v34
	v_add_f32_e32 v24, v24, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v34, 0xbfb8aa3b, v24
	v_exp_f32_e32 v34, v34
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v34, v34
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fma_mixlo_f16 v24, v24, v34, 0
	v_add_nc_u32_e32 v34, v32, v108
	global_store_b16 v33, v24, s[10:11] scale_offset
	global_load_u16 v24, v34, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v25, v24
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v32, v109
	global_store_b16 v34, v24, s[10:11] scale_offset
	global_load_u16 v24, v25, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v26, v24
	v_mul_f32_e32 v26, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v26, v26
	v_nop
	v_add_f32_e32 v26, 1.0, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v26, v26
	v_nop
	v_fma_mixlo_f16 v24, v24, v26, 0
	v_add_nc_u32_e32 v26, v32, v110
	global_store_b16 v25, v24, s[10:11] scale_offset
	global_load_u16 v24, v26, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v24, v27, v24
	v_or_b32_e32 v27, 16, v32
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v32, v111
	global_store_b16 v26, v24, s[10:11] scale_offset
	global_load_u16 v24, v25, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v28, v24
	v_mul_f32_e32 v26, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v26, v26
	v_nop
	v_add_f32_e32 v26, 1.0, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v26, v26
	v_nop
	v_fma_mixlo_f16 v24, v24, v26, 0
	v_add_nc_u32_e32 v26, v32, v112
	global_store_b16 v25, v24, s[10:11] scale_offset
	global_load_u16 v24, v26, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v29, v24
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v32, v113
	global_store_b16 v26, v24, s[10:11] scale_offset
	global_load_u16 v24, v25, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v30, v24
	v_mul_f32_e32 v26, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v26, v26
	v_nop
	v_add_f32_e32 v26, 1.0, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v26, v26
	v_nop
	v_fma_mixlo_f16 v24, v24, v26, 0
	v_add_nc_u32_e32 v26, v32, v115
	global_store_b16 v25, v24, s[10:11] scale_offset
	global_load_u16 v24, v26, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v31, v24
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v27, v106
	global_store_b16 v26, v24, s[10:11] scale_offset
	global_load_u16 v24, v25, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v16, v24
	v_mul_f32_e32 v24, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v24, v24
	v_nop
	v_add_f32_e32 v24, 1.0, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v24, v24
	v_nop
	v_fma_mixlo_f16 v16, v16, v24, 0
	v_add_nc_u32_e32 v24, v27, v108
	global_store_b16 v25, v16, s[10:11] scale_offset
	global_load_u16 v16, v24, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v17, v16
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v27, v109
	global_store_b16 v24, v16, s[10:11] scale_offset
	global_load_u16 v16, v17, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v18, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v18, v18
	v_nop
	v_add_f32_e32 v18, 1.0, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v18, v18
	v_nop
	v_fma_mixlo_f16 v16, v16, v18, 0
	v_add_nc_u32_e32 v18, v27, v110
	global_store_b16 v17, v16, s[10:11] scale_offset
	global_load_u16 v16, v18, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v16, v19, v16
	v_or_b32_e32 v19, 32, v32
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v27, v111
	global_store_b16 v18, v16, s[10:11] scale_offset
	global_load_u16 v16, v17, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v20, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v18, v18
	v_nop
	v_add_f32_e32 v18, 1.0, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v18, v18
	v_nop
	v_fma_mixlo_f16 v16, v16, v18, 0
	v_add_nc_u32_e32 v18, v27, v112
	global_store_b16 v17, v16, s[10:11] scale_offset
	global_load_u16 v16, v18, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v21, v16
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v27, v113
	global_store_b16 v18, v16, s[10:11] scale_offset
	global_load_u16 v16, v17, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v22, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v18, v18
	v_nop
	v_add_f32_e32 v18, 1.0, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v18, v18
	v_nop
	v_fma_mixlo_f16 v16, v16, v18, 0
	v_add_nc_u32_e32 v18, v27, v115
	global_store_b16 v17, v16, s[10:11] scale_offset
	global_load_u16 v16, v18, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v23, v16
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v19, v106
	global_store_b16 v18, v16, s[10:11] scale_offset
	global_load_u16 v16, v17, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v8, v16
	v_mul_f32_e32 v16, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v16, v16
	v_nop
	v_add_f32_e32 v16, 1.0, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v16, v16
	v_nop
	v_fma_mixlo_f16 v8, v8, v16, 0
	v_add_nc_u32_e32 v16, v19, v108
	global_store_b16 v17, v8, s[10:11] scale_offset
	global_load_u16 v8, v16, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v9, v8
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v19, v109
	global_store_b16 v16, v8, s[10:11] scale_offset
	global_load_u16 v8, v9, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v10, v8
	v_mul_f32_e32 v10, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v10, v10
	v_nop
	v_add_f32_e32 v10, 1.0, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v10, v10
	v_nop
	v_fma_mixlo_f16 v8, v8, v10, 0
	v_add_nc_u32_e32 v10, v19, v110
	global_store_b16 v9, v8, s[10:11] scale_offset
	global_load_u16 v8, v10, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v8, v11, v8
	v_or_b32_e32 v11, 48, v32
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v19, v111
	global_store_b16 v10, v8, s[10:11] scale_offset
	global_load_u16 v8, v9, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v12, v8
	v_mul_f32_e32 v10, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v10, v10
	v_nop
	v_add_f32_e32 v10, 1.0, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v10, v10
	v_nop
	v_fma_mixlo_f16 v8, v8, v10, 0
	v_add_nc_u32_e32 v10, v19, v112
	global_store_b16 v9, v8, s[10:11] scale_offset
	global_load_u16 v8, v10, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v13, v8
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v19, v113
	global_store_b16 v10, v8, s[10:11] scale_offset
	global_load_u16 v8, v9, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v14, v8
	v_mul_f32_e32 v10, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v10, v10
	v_nop
	v_add_f32_e32 v10, 1.0, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v10, v10
	v_nop
	v_fma_mixlo_f16 v8, v8, v10, 0
	v_add_nc_u32_e32 v10, v19, v115
	global_store_b16 v9, v8, s[10:11] scale_offset
	global_load_u16 v8, v10, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v15, v8
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v11, v106
	global_store_b16 v10, v8, s[10:11] scale_offset
	global_load_u16 v8, v9, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v0, v8
	v_mul_f32_e32 v8, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v8, v8
	v_nop
	v_add_f32_e32 v8, 1.0, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v8, v8
	v_nop
	v_fma_mixlo_f16 v0, v0, v8, 0
	v_add_nc_u32_e32 v8, v11, v108
	global_store_b16 v9, v0, s[10:11] scale_offset
	global_load_u16 v0, v8, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v1, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	v_add_nc_u32_e32 v1, v11, v109
	global_store_b16 v8, v0, s[10:11] scale_offset
	global_load_u16 v0, v1, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v2, v0
	v_mul_f32_e32 v2, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v2, v2
	v_nop
	v_add_f32_e32 v2, 1.0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v2, v2
	v_nop
	v_fma_mixlo_f16 v0, v0, v2, 0
	v_add_nc_u32_e32 v2, v11, v110
	global_store_b16 v1, v0, s[10:11] scale_offset
	global_load_u16 v0, v2, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v3, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	v_add_nc_u32_e32 v1, v11, v111
	global_store_b16 v2, v0, s[10:11] scale_offset
	global_load_u16 v0, v1, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v4, v0
	v_mul_f32_e32 v2, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v2, v2
	v_nop
	v_add_f32_e32 v2, 1.0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v2, v2
	v_nop
	v_fma_mixlo_f16 v0, v0, v2, 0
	v_add_nc_u32_e32 v2, v11, v112
	global_store_b16 v1, v0, s[10:11] scale_offset
	global_load_u16 v0, v2, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v5, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	v_add_nc_u32_e32 v1, v11, v113
	global_store_b16 v2, v0, s[10:11] scale_offset
	global_load_u16 v0, v1, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v6, v0
	v_mul_f32_e32 v2, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v2, v2
	v_nop
	v_add_f32_e32 v2, 1.0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v2, v2
	v_nop
	v_fma_mixlo_f16 v0, v0, v2, 0
	v_add_nc_u32_e32 v2, v11, v115
	global_store_b16 v1, v0, s[10:11] scale_offset
	global_load_u16 v0, v2, s[8:9] scale_offset
	s_wait_loadcnt 0x0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v7, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	global_store_b16 v2, v0, s[10:11] scale_offset
	s_cbranch_vccnz .LBB2_8
.LBB2_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB2_4 Depth 2
                                        ;       Child Loop BB2_6 Depth 3
	s_clause 0x7
	global_load_u16 v32, v[74:75], off
	global_load_u16 v33, v[78:79], off
	global_load_u16 v34, v[82:83], off
	global_load_u16 v35, v[86:87], off
	global_load_u16 v36, v[90:91], off
	global_load_u16 v37, v[94:95], off
	global_load_u16 v38, v[98:99], off
	global_load_u16 v39, v[102:103], off
	s_clause 0x7
	global_load_u16 v40, v[76:77], off
	global_load_u16 v41, v[80:81], off
	global_load_u16 v42, v[84:85], off
	global_load_u16 v43, v[88:89], off
	global_load_u16 v44, v[92:93], off
	global_load_u16 v45, v[96:97], off
	global_load_u16 v46, v[100:101], off
	global_load_u16 v47, v[104:105], off
	s_wait_xcnt 0x10
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, v73
	v_dual_mov_b32 v2, v73 :: v_dual_mov_b32 v3, v73
	v_dual_mov_b32 v4, v73 :: v_dual_mov_b32 v5, v73
	v_dual_mov_b32 v6, v73 :: v_dual_mov_b32 v7, v73
	v_dual_mov_b32 v24, 0 :: v_dual_mov_b32 v25, v73
	v_dual_mov_b32 v26, v73 :: v_dual_mov_b32 v27, v73
	v_dual_mov_b32 v28, v73 :: v_dual_mov_b32 v29, v73
	v_dual_mov_b32 v30, v73 :: v_dual_mov_b32 v31, v73
	v_dual_mov_b32 v16, 0 :: v_dual_mov_b32 v17, v73
	v_dual_mov_b32 v18, v73 :: v_dual_mov_b32 v19, v73
	v_dual_mov_b32 v20, v73 :: v_dual_mov_b32 v21, v73
	v_dual_mov_b32 v22, v73 :: v_dual_mov_b32 v23, v73
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, v73
	v_dual_mov_b32 v10, v73 :: v_dual_mov_b32 v11, v73
	v_dual_mov_b32 v12, v73 :: v_dual_mov_b32 v13, v73
	v_dual_mov_b32 v14, v73 :: v_dual_mov_b32 v15, v73
	v_dual_mov_b32 v121, v120 :: v_dual_mov_b32 v122, v72
	s_xor_b32 s0, s2, -1
	s_mov_b32 s2, -1
	s_mov_b32 s3, 0
	s_wait_loadcnt 0xf
	ds_store_b16 v114, v32
	s_wait_loadcnt 0xe
	ds_store_b16 v114, v33 offset:2048
	s_wait_loadcnt 0xd
	ds_store_b16 v114, v34 offset:4096
	s_wait_loadcnt 0xc
	ds_store_b16 v114, v35 offset:6144
	s_wait_loadcnt 0xb
	ds_store_b16 v114, v36 offset:8192
	s_wait_loadcnt 0xa
	ds_store_b16 v114, v37 offset:10240
	s_wait_loadcnt 0x9
	ds_store_b16 v114, v38 offset:12288
	s_wait_loadcnt 0x8
	ds_store_b16 v114, v39 offset:14336
	s_wait_loadcnt 0x7
	ds_store_b16 v116, v40
	s_wait_loadcnt 0x6
	ds_store_b16 v116, v41 offset:2048
	s_wait_loadcnt 0x5
	ds_store_b16 v116, v42 offset:4096
	s_wait_loadcnt 0x4
	ds_store_b16 v116, v43 offset:6144
	s_wait_loadcnt 0x3
	ds_store_b16 v116, v44 offset:8192
	s_wait_loadcnt 0x2
	ds_store_b16 v116, v45 offset:10240
	s_wait_loadcnt 0x1
	ds_store_b16 v116, v46 offset:12288
	s_wait_loadcnt 0x0
	ds_store_b16 v116, v47 offset:14336
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB2_4
.LBB2_3:                                ;   in Loop: Header=BB2_4 Depth=2
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[64:71], v[24:31]
	v_add_nc_u32_e32 v122, 0x20000, v122
	v_add_nc_u32_e32 v121, 32, v121
	s_add_co_i32 s3, s3, 32
	s_xor_b32 s2, s2, -1
	s_and_b32 vcc_lo, exec_lo, s12
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[56:63], v[16:23]
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[48:55], v[8:15]
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[40:47], v[0:7]
	s_cbranch_vccnz .LBB2_1
.LBB2_4:                                ;   Parent Loop BB2_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB2_6 Depth 3
	s_lshl_b32 s12, s3, 9
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_add_u32 v32, s1, 12, v118
	s_and_b32 s12, s12, 0x4000
	s_cmp_gt_u32 s3, 0xfdf
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_nc_u32 v44, s12, v32 :: v_dual_bitop2_b32 v36, s12, v107 bitop3:0x54
	s_cselect_b32 s12, -1, 0
	ds_load_b128 v[32:35], v36
	ds_load_b128 v[36:39], v36 offset:32
	ds_load_b128 v[64:67], v44
	ds_load_b128 v[68:71], v44 offset:32
	ds_load_b128 v[56:59], v44 offset:1024
	ds_load_b128 v[60:63], v44 offset:1056
	ds_load_b128 v[48:51], v44 offset:2048
	ds_load_b128 v[52:55], v44 offset:2080
	ds_load_b128 v[40:43], v44 offset:3072
	ds_load_b128 v[44:47], v44 offset:3104
	s_and_b32 vcc_lo, exec_lo, s12
	s_cbranch_vccnz .LBB2_3
; %bb.5:                                ;   in Loop: Header=BB2_4 Depth=2
	v_cndmask_b32_e64 v125, 0, 1, s2
	v_dual_mov_b32 v123, v121 :: v_dual_mov_b32 v124, v122
	v_mov_b32_e32 v126, v119
	s_mov_b32 s13, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v125, v125, 14, v114
.LBB2_6:                                ;   Parent Loop BB2_2 Depth=1
                                        ;     Parent Loop BB2_4 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	global_load_u16 v127, v123, s[4:5] scale_offset
	v_add_nc_u32_e32 v126, 0x400, v126
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v123, 0x20000, v123
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v126
	s_or_b32 s13, vcc_lo, s13
	s_wait_loadcnt 0x0
	ds_store_b16 v125, v127
	global_load_u16 v127, v124, s[6:7] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v124, 32, v124
	s_wait_loadcnt 0x0
	ds_store_b16 v125, v127 offset:32768
	v_add_nc_u32_e32 v125, 0x800, v125
	s_and_not1_b32 exec_lo, exec_lo, s13
	s_cbranch_execnz .LBB2_6
; %bb.7:                                ;   in Loop: Header=BB2_4 Depth=2
	s_or_b32 exec_lo, exec_lo, s13
	s_branch .LBB2_3
.LBB2_8:
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel gemm_add_silu_f16_full
		.amdhsa_group_segment_fixed_size 65536
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 128
		.amdhsa_next_free_sgpr 14
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 37
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
	.size	gemm_add_silu_f16_full, .Lfunc_end2-gemm_add_silu_f16_full
                                        ; -- End function
	.set gemm_add_silu_f16_full.num_vgpr, 128
	.set gemm_add_silu_f16_full.num_agpr, 0
	.set gemm_add_silu_f16_full.numbered_sgpr, 14
	.set gemm_add_silu_f16_full.num_named_barrier, 0
	.set gemm_add_silu_f16_full.private_seg_size, 0
	.set gemm_add_silu_f16_full.uses_vcc, 1
	.set gemm_add_silu_f16_full.uses_flat_scratch, 0
	.set gemm_add_silu_f16_full.has_dyn_sized_stack, 0
	.set gemm_add_silu_f16_full.has_recursion, 0
	.set gemm_add_silu_f16_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4612
; TotalNumSgprs: 16
; NumVgprs: 128
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 16
; NumVGPRsForWavesPerEU: 128
; NamedBarCnt: 0
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	gemm_add_silu_f8_full   ; -- Begin function gemm_add_silu_f8_full
	.globl	gemm_add_silu_f8_full
	.p2align	8
	.type	gemm_add_silu_f8_full,@function
gemm_add_silu_f8_full:                  ; @gemm_add_silu_f8_full
; %bb.0:
	s_bfe_u32 s3, ttmp6, 0x4000c
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshlrev_b32 v2, 2, v0
	s_add_co_i32 s3, s3, 1
	s_bfe_u32 s4, ttmp6, 0x40010
	s_and_b32 s2, ttmp6, 15
	s_mul_i32 s3, ttmp9, s3
	s_add_co_i32 s4, s4, 1
	v_dual_lshrrev_b32 v3, 6, v0 :: v_dual_lshlrev_b32 v4, 6, v0
	v_and_b32_e32 v1, 8, v1
	s_add_co_i32 s2, s2, s3
	s_mul_i32 s3, ttmp7, s4
	s_bfe_u32 s4, ttmp6, 0x40004
	s_getreg_b32 s5, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s4, s4, s3
	s_cmp_eq_u32 s5, 0
	v_dual_lshlrev_b32 v6, 10, v3 :: v_dual_bitop2_b32 v5, 15, v0 bitop3:0x40
	v_and_b32_e32 v2, 0x80, v2
	v_and_b32_e32 v4, 0x3c0, v4
	v_dual_lshlrev_b32 v3, 16, v3 :: v_dual_lshlrev_b32 v7, 1, v1
	v_lshlrev_b32_e32 v1, 12, v1
	s_cselect_b32 s3, ttmp7, s4
	s_load_b256 s[4:11], s[0:1], 0x0
	s_cselect_b32 s2, ttmp9, s2
	v_or_b32_e32 v8, v2, v5
	s_lshl_b32 s2, s2, 20
	v_or3_b32 v73, v6, v4, v7
	v_or3_b32 v72, v3, v1, s2
	s_wait_xcnt 0x0
	s_lshl_b32 s0, s3, 8
	v_dual_lshrrev_b32 v4, 5, v0 :: v_dual_bitop2_b32 v1, 31, v0 bitop3:0x40
	v_lshlrev_b32_e32 v3, 6, v8
	v_or_b32_e32 v74, 0x1000, v72
	v_or_b32_e32 v75, 0x2000, v72
	v_or_b32_e32 v76, 0x3000, v72
	v_lshl_or_b32 v6, v1, 12, v4
	v_lshlrev_b32_e32 v4, 12, v4
	v_or_b32_e32 v77, 0x4000, v72
	v_or_b32_e32 v78, 0x5000, v72
	v_or_b32_e32 v79, 0x6000, v72
	v_or_b32_e32 v80, 0x7000, v72
	v_or3_b32 v81, v5, s0, v2
	v_add_nc_u32_e32 v82, s0, v6
	v_or3_b32 v83, s2, v4, v1
	v_or3_b32 v84, v7, v3, 0x8000
	v_or_b32_e32 v85, 0xfffffc00, v0
	v_lshlrev_b32_e32 v86, 1, v0
	s_mov_b32 s1, 0
	s_mov_b32 s2, -1
	s_branch .LBB3_2
.LBB3_1:                                ;   in Loop: Header=BB3_2 Depth=1
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v32, s1, 6, v81
	s_mov_b32 s1, 1
	s_mov_b32 s2, 0
	s_and_b32 vcc_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v33, v32, v72
	global_load_u8 v34, v33, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v34, v34
	v_cvt_f16_f32_e32 v34, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f32_f16_e32 v34, v34
	v_add_f32_e32 v24, v24, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v34, 0xbfb8aa3b, v24
	v_exp_f32_e32 v34, v34
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v34, v34
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fma_mixlo_f16 v24, v24, v34, 0
	v_add_nc_u32_e32 v34, v32, v74
	global_store_b16 v33, v24, s[10:11] scale_offset
	global_load_u8 v24, v34, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v25, v24
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v32, v75
	global_store_b16 v34, v24, s[10:11] scale_offset
	global_load_u8 v24, v25, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v26, v24
	v_mul_f32_e32 v26, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v26, v26
	v_nop
	v_add_f32_e32 v26, 1.0, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v26, v26
	v_nop
	v_fma_mixlo_f16 v24, v24, v26, 0
	v_add_nc_u32_e32 v26, v32, v76
	global_store_b16 v25, v24, s[10:11] scale_offset
	global_load_u8 v24, v26, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v24, v27, v24
	v_or_b32_e32 v27, 16, v32
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v32, v77
	global_store_b16 v26, v24, s[10:11] scale_offset
	global_load_u8 v24, v25, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v28, v24
	v_mul_f32_e32 v26, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v26, v26
	v_nop
	v_add_f32_e32 v26, 1.0, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v26, v26
	v_nop
	v_fma_mixlo_f16 v24, v24, v26, 0
	v_add_nc_u32_e32 v26, v32, v78
	global_store_b16 v25, v24, s[10:11] scale_offset
	global_load_u8 v24, v26, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v29, v24
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v32, v79
	global_store_b16 v26, v24, s[10:11] scale_offset
	global_load_u8 v24, v25, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v30, v24
	v_mul_f32_e32 v26, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v26, v26
	v_nop
	v_add_f32_e32 v26, 1.0, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v26, v26
	v_nop
	v_fma_mixlo_f16 v24, v24, v26, 0
	v_add_nc_u32_e32 v26, v32, v80
	global_store_b16 v25, v24, s[10:11] scale_offset
	global_load_u8 v24, v26, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v24, v31, v24
	v_mul_f32_e32 v25, 0xbfb8aa3b, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v25, v25
	v_nop
	v_add_f32_e32 v25, 1.0, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v25, v25
	v_nop
	v_fma_mixlo_f16 v24, v24, v25, 0
	v_add_nc_u32_e32 v25, v27, v72
	global_store_b16 v26, v24, s[10:11] scale_offset
	global_load_u8 v24, v25, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f32_f16_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v16, v24
	v_mul_f32_e32 v24, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v24, v24
	v_nop
	v_add_f32_e32 v24, 1.0, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v24, v24
	v_nop
	v_fma_mixlo_f16 v16, v16, v24, 0
	v_add_nc_u32_e32 v24, v27, v74
	global_store_b16 v25, v16, s[10:11] scale_offset
	global_load_u8 v16, v24, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v17, v16
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v27, v75
	global_store_b16 v24, v16, s[10:11] scale_offset
	global_load_u8 v16, v17, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v18, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v18, v18
	v_nop
	v_add_f32_e32 v18, 1.0, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v18, v18
	v_nop
	v_fma_mixlo_f16 v16, v16, v18, 0
	v_add_nc_u32_e32 v18, v27, v76
	global_store_b16 v17, v16, s[10:11] scale_offset
	global_load_u8 v16, v18, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v16, v19, v16
	v_or_b32_e32 v19, 32, v32
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v27, v77
	global_store_b16 v18, v16, s[10:11] scale_offset
	global_load_u8 v16, v17, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v20, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v18, v18
	v_nop
	v_add_f32_e32 v18, 1.0, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v18, v18
	v_nop
	v_fma_mixlo_f16 v16, v16, v18, 0
	v_add_nc_u32_e32 v18, v27, v78
	global_store_b16 v17, v16, s[10:11] scale_offset
	global_load_u8 v16, v18, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v21, v16
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v27, v79
	global_store_b16 v18, v16, s[10:11] scale_offset
	global_load_u8 v16, v17, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v22, v16
	v_mul_f32_e32 v18, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v18, v18
	v_nop
	v_add_f32_e32 v18, 1.0, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v18, v18
	v_nop
	v_fma_mixlo_f16 v16, v16, v18, 0
	v_add_nc_u32_e32 v18, v27, v80
	global_store_b16 v17, v16, s[10:11] scale_offset
	global_load_u8 v16, v18, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v16, v23, v16
	v_mul_f32_e32 v17, 0xbfb8aa3b, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v17, v17
	v_nop
	v_add_f32_e32 v17, 1.0, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v17, v17
	v_nop
	v_fma_mixlo_f16 v16, v16, v17, 0
	v_add_nc_u32_e32 v17, v19, v72
	global_store_b16 v18, v16, s[10:11] scale_offset
	global_load_u8 v16, v17, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f32_f16_e32 v16, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v8, v16
	v_mul_f32_e32 v16, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v16, v16
	v_nop
	v_add_f32_e32 v16, 1.0, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v16, v16
	v_nop
	v_fma_mixlo_f16 v8, v8, v16, 0
	v_add_nc_u32_e32 v16, v19, v74
	global_store_b16 v17, v8, s[10:11] scale_offset
	global_load_u8 v8, v16, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v9, v8
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v19, v75
	global_store_b16 v16, v8, s[10:11] scale_offset
	global_load_u8 v8, v9, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v10, v8
	v_mul_f32_e32 v10, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v10, v10
	v_nop
	v_add_f32_e32 v10, 1.0, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v10, v10
	v_nop
	v_fma_mixlo_f16 v8, v8, v10, 0
	v_add_nc_u32_e32 v10, v19, v76
	global_store_b16 v9, v8, s[10:11] scale_offset
	global_load_u8 v8, v10, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_f32_e32 v8, v11, v8
	v_or_b32_e32 v11, 48, v32
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v19, v77
	global_store_b16 v10, v8, s[10:11] scale_offset
	global_load_u8 v8, v9, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v12, v8
	v_mul_f32_e32 v10, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v10, v10
	v_nop
	v_add_f32_e32 v10, 1.0, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v10, v10
	v_nop
	v_fma_mixlo_f16 v8, v8, v10, 0
	v_add_nc_u32_e32 v10, v19, v78
	global_store_b16 v9, v8, s[10:11] scale_offset
	global_load_u8 v8, v10, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v13, v8
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v19, v79
	global_store_b16 v10, v8, s[10:11] scale_offset
	global_load_u8 v8, v9, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v14, v8
	v_mul_f32_e32 v10, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v10, v10
	v_nop
	v_add_f32_e32 v10, 1.0, v10
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v10, v10
	v_nop
	v_fma_mixlo_f16 v8, v8, v10, 0
	v_add_nc_u32_e32 v10, v19, v80
	global_store_b16 v9, v8, s[10:11] scale_offset
	global_load_u8 v8, v10, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v15, v8
	v_mul_f32_e32 v9, 0xbfb8aa3b, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v9, v9
	v_nop
	v_add_f32_e32 v9, 1.0, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v9, v9
	v_nop
	v_fma_mixlo_f16 v8, v8, v9, 0
	v_add_nc_u32_e32 v9, v11, v72
	global_store_b16 v10, v8, s[10:11] scale_offset
	global_load_u8 v8, v9, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v8, v8
	v_cvt_f32_f16_e32 v8, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v0, v8
	v_mul_f32_e32 v8, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v8, v8
	v_nop
	v_add_f32_e32 v8, 1.0, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v8, v8
	v_nop
	v_fma_mixlo_f16 v0, v0, v8, 0
	v_add_nc_u32_e32 v8, v11, v74
	global_store_b16 v9, v0, s[10:11] scale_offset
	global_load_u8 v0, v8, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v1, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	v_add_nc_u32_e32 v1, v11, v75
	global_store_b16 v8, v0, s[10:11] scale_offset
	global_load_u8 v0, v1, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v2, v0
	v_mul_f32_e32 v2, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v2, v2
	v_nop
	v_add_f32_e32 v2, 1.0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v2, v2
	v_nop
	v_fma_mixlo_f16 v0, v0, v2, 0
	v_add_nc_u32_e32 v2, v11, v76
	global_store_b16 v1, v0, s[10:11] scale_offset
	global_load_u8 v0, v2, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v3, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	v_add_nc_u32_e32 v1, v11, v77
	global_store_b16 v2, v0, s[10:11] scale_offset
	global_load_u8 v0, v1, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v4, v0
	v_mul_f32_e32 v2, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v2, v2
	v_nop
	v_add_f32_e32 v2, 1.0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v2, v2
	v_nop
	v_fma_mixlo_f16 v0, v0, v2, 0
	v_add_nc_u32_e32 v2, v11, v78
	global_store_b16 v1, v0, s[10:11] scale_offset
	global_load_u8 v0, v2, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v5, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	v_add_nc_u32_e32 v1, v11, v79
	global_store_b16 v2, v0, s[10:11] scale_offset
	global_load_u8 v0, v1, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v6, v0
	v_mul_f32_e32 v2, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v2, v2
	v_nop
	v_add_f32_e32 v2, 1.0, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v2, v2
	v_nop
	v_fma_mixlo_f16 v0, v0, v2, 0
	v_add_nc_u32_e32 v2, v11, v80
	global_store_b16 v1, v0, s[10:11] scale_offset
	global_load_u8 v0, v2, s[8:9]
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f32_f16_e32 v0, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v0, v7, v0
	v_mul_f32_e32 v1, 0xbfb8aa3b, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v1, v1
	v_nop
	v_add_f32_e32 v1, 1.0, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v1, v1
	v_nop
	v_fma_mixlo_f16 v0, v0, v1, 0
	global_store_b16 v2, v0, s[10:11] scale_offset
	s_cbranch_vccnz .LBB3_10
.LBB3_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB3_3 Depth 2
                                        ;     Child Loop BB3_6 Depth 2
                                        ;       Child Loop BB3_8 Depth 3
	s_wait_xcnt 0x0
	v_dual_mov_b32 v0, v83 :: v_dual_mov_b32 v1, v82
	v_dual_mov_b32 v2, v86 :: v_dual_mov_b32 v3, v85
	s_xor_b32 s0, s2, -1
	s_mov_b32 s2, 0
.LBB3_3:                                ;   Parent Loop BB3_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_wait_kmcnt 0x0
	global_load_u8 v4, v0, s[4:5]
	global_load_u8 v5, v1, s[6:7]
	v_add_nc_u32_e32 v3, 0x400, v3
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v1, 32, v1
	v_add_nc_u32_e32 v0, 0x20000, v0
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v3
	s_or_b32 s2, vcc_lo, s2
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v4, v4
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v5, v5
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_f32_e32 v4, v4
	v_cvt_f16_f32_e32 v5, v5
	ds_store_b16 v2, v4
	ds_store_b16 v2, v5 offset:32768
	v_add_nc_u32_e32 v2, 0x800, v2
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB3_3
; %bb.4:                                ;   in Loop: Header=BB3_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_mov_b32 v0, 0 :: v_dual_bitop2_b32 v87, 32, v83 bitop3:0x54
	v_add_nc_u32_e32 v88, 0x20000, v82
	s_mov_b32 s2, 0
	s_mov_b32 s3, -1
	s_wait_dscnt 0x0
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
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB3_6
.LBB3_5:                                ;   in Loop: Header=BB3_6 Depth=2
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[64:71], v[24:31]
	v_add_nc_u32_e32 v88, 0x20000, v88
	v_add_nc_u32_e32 v87, 32, v87
	s_add_co_i32 s2, s2, 32
	s_xor_b32 s3, s3, -1
	s_and_b32 vcc_lo, exec_lo, s12
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[56:63], v[16:23]
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[48:55], v[8:15]
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[40:47], v[0:7]
	s_cbranch_vccnz .LBB3_1
.LBB3_6:                                ;   Parent Loop BB3_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB3_8 Depth 3
	s_lshl_b32 s12, s2, 9
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_add_u32 v32, s1, 12, v84
	s_and_b32 s12, s12, 0x4000
	s_cmp_gt_u32 s2, 0xfdf
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_nc_u32 v44, s12, v32 :: v_dual_bitop2_b32 v36, s12, v73 bitop3:0x54
	s_cselect_b32 s12, -1, 0
	ds_load_b128 v[32:35], v36
	ds_load_b128 v[36:39], v36 offset:32
	ds_load_b128 v[64:67], v44
	ds_load_b128 v[68:71], v44 offset:32
	ds_load_b128 v[56:59], v44 offset:1024
	ds_load_b128 v[60:63], v44 offset:1056
	ds_load_b128 v[48:51], v44 offset:2048
	ds_load_b128 v[52:55], v44 offset:2080
	ds_load_b128 v[40:43], v44 offset:3072
	ds_load_b128 v[44:47], v44 offset:3104
	s_and_b32 vcc_lo, exec_lo, s12
	s_cbranch_vccnz .LBB3_5
; %bb.7:                                ;   in Loop: Header=BB3_6 Depth=2
	v_cndmask_b32_e64 v91, 0, 1, s3
	v_dual_mov_b32 v89, v87 :: v_dual_mov_b32 v90, v88
	v_mov_b32_e32 v92, v85
	s_mov_b32 s13, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v91, v91, 14, v86
.LBB3_8:                                ;   Parent Loop BB3_2 Depth=1
                                        ;     Parent Loop BB3_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	global_load_u8 v93, v89, s[4:5]
	global_load_u8 v94, v90, s[6:7]
	v_add_nc_u32_e32 v92, 0x400, v92
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v90, 32, v90
	v_add_nc_u32_e32 v89, 0x20000, v89
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_lt_u32_e32 vcc_lo, 0x1bff, v92
	s_or_b32 s13, vcc_lo, s13
	s_wait_loadcnt 0x1
	v_cvt_f32_fp8_e32 v93, v93
	s_wait_loadcnt 0x0
	v_cvt_f32_fp8_e32 v94, v94
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_f32_e32 v93, v93
	v_cvt_f16_f32_e32 v94, v94
	ds_store_b16 v91, v93
	ds_store_b16 v91, v94 offset:32768
	v_add_nc_u32_e32 v91, 0x800, v91
	s_and_not1_b32 exec_lo, exec_lo, s13
	s_cbranch_execnz .LBB3_8
; %bb.9:                                ;   in Loop: Header=BB3_6 Depth=2
	s_or_b32 exec_lo, exec_lo, s13
	s_branch .LBB3_5
.LBB3_10:
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel gemm_add_silu_f8_full
		.amdhsa_group_segment_fixed_size 65536
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 95
		.amdhsa_next_free_sgpr 14
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 34
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
	.size	gemm_add_silu_f8_full, .Lfunc_end3-gemm_add_silu_f8_full
                                        ; -- End function
	.set gemm_add_silu_f8_full.num_vgpr, 95
	.set gemm_add_silu_f8_full.num_agpr, 0
	.set gemm_add_silu_f8_full.numbered_sgpr, 14
	.set gemm_add_silu_f8_full.num_named_barrier, 0
	.set gemm_add_silu_f8_full.private_seg_size, 0
	.set gemm_add_silu_f8_full.uses_vcc, 1
	.set gemm_add_silu_f8_full.uses_flat_scratch, 0
	.set gemm_add_silu_f8_full.has_dyn_sized_stack, 0
	.set gemm_add_silu_f8_full.has_recursion, 0
	.set gemm_add_silu_f8_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4308
; TotalNumSgprs: 16
; NumVgprs: 95
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 5
; NumSGPRsForWavesPerEU: 16
; NumVGPRsForWavesPerEU: 95
; NamedBarCnt: 0
; Occupancy: 10
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	bitdelta_full           ; -- Begin function bitdelta_full
	.globl	bitdelta_full
	.p2align	8
	.type	bitdelta_full,@function
bitdelta_full:                          ; @bitdelta_full
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	s_getreg_b32 s4, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s2, ttmp9, s2
	v_or_b32_e32 v1, 0x100, v0
	s_add_co_i32 s3, s3, s2
	s_cmp_eq_u32 s4, 0
	v_or_b32_e32 v2, 0x200, v0
	s_cselect_b32 s3, ttmp9, s3
	v_or_b32_e32 v3, 0x300, v0
	s_lshr_b32 s4, s3, 5
	s_and_b32 s2, s3, 7
	s_and_b32 s10, s4, 0x3fffff8
	v_or_b32_e32 v5, 0x400, v0
	v_dual_lshrrev_b32 v1, 5, v1 :: v_dual_lshrrev_b32 v2, 5, v2
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[8:9], s[0:1], 0x10
	s_wait_xcnt 0x0
	s_or_b32 s0, s10, s2
	v_dual_lshrrev_b32 v6, 5, v0 :: v_dual_bitop2_b32 v4, 31, v0 bitop3:0x40
	s_lshl_b32 s10, s0, 6
	v_dual_lshrrev_b32 v3, 5, v3 :: v_dual_lshrrev_b32 v7, 5, v5
	v_or_b32_e32 v8, s10, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_or_b32_e32 v6, s10, v6
	v_cmp_gt_u32_e64 s0, 0x700, v5
	v_dual_lshlrev_b32 v7, 12, v8 :: v_dual_bitop2_b32 v9, s10, v7 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v2, 12, v6 :: v_dual_bitop2_b32 v1, s10, v1 bitop3:0x54
	v_dual_lshlrev_b32 v9, 12, v9 :: v_dual_bitop2_b32 v3, s10, v3 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v6, 12, v1 :: v_dual_bitop2_b32 v10, v7, v4 bitop3:0x54
	v_dual_lshlrev_b32 v8, 12, v3 :: v_dual_bitop2_b32 v1, v2, v4 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_or_b32_e32 v12, v9, v4
	v_or_b32_e32 v3, v6, v4
	s_delay_alu instid0(VALU_DEP_3)
	v_or_b32_e32 v11, v8, v4
	s_wait_kmcnt 0x0
	s_clause 0x4
	global_load_u16 v13, v1, s[4:5] scale_offset
	global_load_u16 v14, v3, s[4:5] scale_offset
	global_load_u16 v15, v10, s[4:5] scale_offset
	global_load_u16 v16, v11, s[4:5] scale_offset
	global_load_u16 v17, v12, s[4:5] scale_offset
	s_wait_xcnt 0x4
	v_lshlrev_b32_e32 v1, 1, v0
	s_wait_xcnt 0x3
	v_or_b32_e32 v3, 0x500, v0
	s_wait_loadcnt 0x4
	ds_store_b16 v1, v13 offset:16384
	s_wait_loadcnt 0x3
	ds_store_b16 v1, v14 offset:16896
	s_wait_loadcnt 0x2
	ds_store_b16 v1, v15 offset:17408
	s_wait_loadcnt 0x1
	ds_store_b16 v1, v16 offset:17920
	s_wait_loadcnt 0x0
	ds_store_b16 v1, v17 offset:18432
	v_or_b32_e32 v76, 0x4000, v1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB4_4
; %bb.1:
	v_lshrrev_b32_e32 v5, 5, v3
	s_mov_b32 s11, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v5, s10, v5
	v_lshl_or_b32 v5, v5, 12, v4
	global_load_u16 v5, v5, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v76, v5 offset:2560
	v_cmpx_gt_u32_e32 0x200, v0
	s_xor_b32 s11, exec_lo, s11
	s_cbranch_execz .LBB4_4
; %bb.2:
	v_or_b32_e32 v5, 0x600, v0
	s_mov_b32 s11, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v5, 5, v5
	v_or_b32_e32 v5, s10, v5
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_or_b32 v5, v5, 12, v4
	global_load_u16 v5, v5, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v76, v5 offset:3072
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s11, exec_lo, s11
	s_cbranch_execz .LBB4_4
; %bb.3:
	v_or_b32_e32 v5, 0x700, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v5, 5, v5
	v_or_b32_e32 v5, s10, v5
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_or_b32 v5, v5, 12, v4
	global_load_u16 v5, v5, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v76, v5 offset:3584
.LBB4_4:
	s_or_b32 exec_lo, exec_lo, s1
	v_lshlrev_b32_e32 v77, 6, v0
	v_cmp_gt_u32_e64 s1, 0x80, v0
	s_lshl_b32 s11, s3, 4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s11, s11, 0xf80
	s_and_saveexec_b32 s12, s1
	s_cbranch_execz .LBB4_6
; %bb.5:
	v_or_b32_e32 v5, s11, v0
	v_mov_b32_e32 v10, 0xbc00
	global_load_b32 v5, v5, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	v_and_b32_e32 v11, 1, v5
	v_cmp_lt_i32_e32 vcc_lo, -1, v5
	v_and_b32_e32 v12, 2, v5
	v_and_b32_e32 v13, 4, v5
	v_and_b32_e32 v14, 8, v5
	v_and_b32_e32 v15, 16, v5
	v_and_b32_e32 v16, 32, v5
	v_and_b32_e32 v17, 64, v5
	v_and_b32_e32 v18, 0x80, v5
	v_and_b32_e32 v19, 0x100, v5
	v_and_b32_e32 v20, 0x200, v5
	v_and_b32_e32 v21, 0x400, v5
	v_and_b32_e32 v22, 0x800, v5
	v_and_b32_e32 v23, 0x1000, v5
	v_and_b32_e32 v24, 0x2000, v5
	v_and_b32_e32 v25, 0x4000, v5
	v_and_b32_e32 v26, 0x8000, v5
	v_and_b32_e32 v27, 0x10000, v5
	v_and_b32_e32 v28, 0x20000, v5
	v_and_b32_e32 v29, 0x40000, v5
	v_and_b32_e32 v30, 0x80000, v5
	v_and_b32_e32 v31, 0x100000, v5
	v_and_b32_e32 v32, 0x200000, v5
	v_and_b32_e32 v33, 0x400000, v5
	v_and_b32_e32 v34, 0x800000, v5
	v_and_b32_e32 v35, 0x1000000, v5
	v_and_b32_e32 v36, 0x2000000, v5
	v_and_b32_e32 v37, 0x4000000, v5
	v_and_b32_e32 v38, 0x8000000, v5
	v_and_b32_e32 v39, 0x10000000, v5
	v_and_b32_e32 v40, 0x20000000, v5
	v_and_b32_e32 v41, 2.0, v5
	v_cndmask_b32_e32 v5, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v11
	v_cndmask_b32_e32 v42, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v12
	v_cndmask_b32_e32 v43, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v13
	v_cndmask_b32_e32 v11, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v14
	v_cndmask_b32_e32 v14, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v15
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v11, v11, v14
	v_cndmask_b32_e32 v12, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v16
	v_cndmask_b32_e32 v15, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v17
	v_pack_b32_f16 v12, v12, v15
	v_cndmask_b32_e32 v13, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v18
	v_cndmask_b32_e32 v16, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v19
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v13, v13, v16
	v_cndmask_b32_e32 v18, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v20
	v_cndmask_b32_e32 v19, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v21
	v_pack_b32_f16 v14, v18, v19
	v_cndmask_b32_e32 v20, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v22
	v_cndmask_b32_e32 v21, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v23
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v15, v20, v21
	v_cndmask_b32_e32 v22, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v24
	v_cndmask_b32_e32 v23, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v25
	v_pack_b32_f16 v16, v22, v23
	v_cndmask_b32_e32 v17, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v26
	v_cndmask_b32_e32 v24, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v27
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v17, v17, v24
	v_cndmask_b32_e32 v25, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v28
	v_cndmask_b32_e32 v26, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v29
	v_pack_b32_f16 v18, v25, v26
	v_cndmask_b32_e32 v27, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v30
	v_cndmask_b32_e32 v28, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v31
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v19, v27, v28
	v_cndmask_b32_e32 v29, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v32
	v_cndmask_b32_e32 v30, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v33
	v_pack_b32_f16 v20, v29, v30
	v_cndmask_b32_e32 v31, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v34
	v_cndmask_b32_e32 v32, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v35
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v21, v31, v32
	v_cndmask_b32_e32 v33, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v36
	v_cndmask_b32_e32 v34, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v37
	v_pack_b32_f16 v22, v33, v34
	v_cndmask_b32_e32 v35, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v38
	v_cndmask_b32_e32 v36, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v39
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v23, v35, v36
	v_cndmask_b32_e32 v37, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v40
	v_cndmask_b32_e32 v38, 0x3c00, v10, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v41
	v_pack_b32_f16 v24, v37, v38
	v_cndmask_b32_e32 v39, 0x3c00, v10, vcc_lo
	v_pack_b32_f16 v10, v42, v43
	s_delay_alu instid0(VALU_DEP_2)
	v_pack_b32_f16 v25, v39, v5
	ds_store_b128 v77, v[10:13]
	ds_store_b128 v77, v[14:17] offset:16
	ds_store_b128 v77, v[18:21] offset:32
	ds_store_b128 v77, v[22:25] offset:48
.LBB4_6:
	s_or_b32 exec_lo, exec_lo, s12
	v_dual_lshrrev_b32 v5, 1, v0 :: v_dual_lshrrev_b32 v78, 6, v0
	v_and_b32_e32 v10, 0x3c0, v77
	v_dual_lshrrev_b32 v12, 5, v3 :: v_dual_bitop2_b32 v11, 15, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v79, 8, v5 bitop3:0x40
	v_lshl_or_b32 v10, v78, 10, v10
	v_or_b32_e32 v14, 0x700, v0
	v_or_b32_e32 v15, 0x600, v0
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_dual_lshlrev_b32 v13, 1, v79 :: v_dual_mov_b32 v5, v3
	v_and_or_b32 v80, v1, 64, v11
	v_lshrrev_b32_e32 v1, 5, v14
	s_lshl_b32 s3, s3, 1
	s_delay_alu instid0(VALU_DEP_3)
	v_or3_b32 v81, v10, v13, 0x4000
	v_add_nc_u64_e32 v[10:11], v[2:3], v[4:5]
	v_lshrrev_b32_e32 v2, 5, v15
	s_and_b32 s3, s3, 0xfffffe00
	s_lshl_b32 s12, s2, 6
	v_add_lshl_u32 v5, v12, s10, 12
	v_or3_b32 v1, v1, s3, s12
	v_or3_b32 v12, v2, s3, s12
	v_lshl_add_u64 v[10:11], v[10:11], 1, s[4:5]
	v_add_lshl_u32 v2, s11, v0, 2
	v_cmp_gt_u32_e64 s2, 0x200, v0
	v_cmp_gt_u32_e64 s3, 0x100, v0
	v_dual_lshlrev_b32 v14, 12, v1 :: v_dual_lshlrev_b32 v12, 12, v12
	v_add_nc_u64_e32 v[0:1], 64, v[10:11]
	v_add_nc_u64_e32 v[10:11], s[6:7], v[2:3]
	v_lshl_or_b32 v82, v80, 6, v13
	s_delay_alu instid0(VALU_DEP_4)
	v_or3_b32 v83, v14, v4, 32
	v_or3_b32 v84, v12, v4, 32
	v_or3_b32 v85, v5, v4, 32
	v_add3_u32 v86, v9, v4, 32
	v_add3_u32 v87, v8, v4, 32
	v_add_nc_u64_e32 v[74:75], 0x4000, v[10:11]
	v_add3_u32 v88, v7, v4, 32
	v_add3_u32 v89, v6, v4, 32
	v_dual_mov_b32 v90, 0xbc00 :: v_dual_mov_b32 v5, v3
	v_dual_mov_b32 v2, v3 :: v_dual_mov_b32 v4, v3
	v_dual_mov_b32 v6, v3 :: v_dual_mov_b32 v7, v3
	v_dual_mov_b32 v8, v3 :: v_dual_mov_b32 v9, v3
	v_dual_mov_b32 v26, v3 :: v_dual_mov_b32 v27, v3
	v_dual_mov_b32 v28, v3 :: v_dual_mov_b32 v29, v3
	v_dual_mov_b32 v30, v3 :: v_dual_mov_b32 v31, v3
	v_dual_mov_b32 v32, v3 :: v_dual_mov_b32 v33, v3
	v_dual_mov_b32 v18, v3 :: v_dual_mov_b32 v19, v3
	v_dual_mov_b32 v20, v3 :: v_dual_mov_b32 v21, v3
	v_dual_mov_b32 v22, v3 :: v_dual_mov_b32 v23, v3
	v_dual_mov_b32 v24, v3 :: v_dual_mov_b32 v25, v3
	v_dual_mov_b32 v10, v3 :: v_dual_mov_b32 v11, v3
	v_dual_mov_b32 v12, v3 :: v_dual_mov_b32 v13, v3
	v_dual_mov_b32 v14, v3 :: v_dual_mov_b32 v15, v3
	v_dual_mov_b32 v16, v3 :: v_dual_mov_b32 v17, v3
	s_mov_b32 s6, 0
	s_mov_b32 s7, 0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB4_9
.LBB4_7:                                ;   in Loop: Header=BB4_9 Depth=1
	s_or_b32 exec_lo, exec_lo, s13
.LBB4_8:                                ;   in Loop: Header=BB4_9 Depth=1
	s_wait_dscnt 0x6
	v_wmma_f32_16x16x32_f16 v[26:33], v[34:41], v[66:73], v[26:33]
	v_add_nc_u64_e32 v[0:1], 64, v[0:1]
	v_add_nc_u64_e32 v[74:75], 0x4000, v[74:75]
	s_add_co_i32 s7, s7, 32
	s_add_co_i32 s6, s6, 1
	s_and_not1_b32 vcc_lo, exec_lo, s12
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_wmma_f32_16x16x32_f16 v[18:25], v[34:41], v[58:65], v[18:25]
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[10:17], v[34:41], v[50:57], v[10:17]
	v_wmma_f32_16x16x32_f16 v[2:9], v[34:41], v[42:49], v[2:9]
	s_cbranch_vccz .LBB4_16
.LBB4_9:                                ; =>This Inner Loop Header: Depth=1
	s_and_b32 s13, s6, 1
	s_cmp_gt_u32 s7, 0xfdf
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_add_u32 v38, s13, 12, v81
	v_lshl_or_b32 v46, s13, 13, v82
	s_cselect_b32 s12, -1, 0
	ds_load_b128 v[34:37], v38
	ds_load_b128 v[38:41], v38 offset:32
	ds_load_b128 v[66:69], v46
	ds_load_b128 v[70:73], v46 offset:32
	ds_load_b128 v[58:61], v46 offset:1024
	ds_load_b128 v[62:65], v46 offset:1056
	ds_load_b128 v[50:53], v46 offset:2048
	ds_load_b128 v[54:57], v46 offset:2080
	ds_load_b128 v[42:45], v46 offset:3072
	ds_load_b128 v[46:49], v46 offset:3104
	s_and_b32 vcc_lo, exec_lo, s12
	s_cbranch_vccnz .LBB4_8
; %bb.10:                               ;   in Loop: Header=BB4_9 Depth=1
	v_dual_add_nc_u32 v91, s7, v89 :: v_dual_add_nc_u32 v92, s7, v88
	v_dual_add_nc_u32 v93, s7, v87 :: v_dual_add_nc_u32 v94, s7, v86
	global_load_u16 v95, v[0:1], off
	s_clause 0x3
	global_load_u16 v96, v91, s[4:5] scale_offset
	global_load_u16 v97, v92, s[4:5] scale_offset
	global_load_u16 v98, v93, s[4:5] scale_offset
	global_load_u16 v99, v94, s[4:5] scale_offset
	s_xor_b32 s14, s13, 1
	s_wait_xcnt 0x3
	v_lshl_add_u32 v91, s14, 12, v76
	s_wait_loadcnt 0x4
	ds_store_b16 v91, v95
	s_wait_loadcnt 0x3
	ds_store_b16 v91, v96 offset:512
	s_wait_loadcnt 0x2
	ds_store_b16 v91, v97 offset:1024
	s_wait_loadcnt 0x1
	ds_store_b16 v91, v98 offset:1536
	s_wait_loadcnt 0x0
	ds_store_b16 v91, v99 offset:2048
	s_and_saveexec_b32 s13, s0
	s_cbranch_execz .LBB4_14
; %bb.11:                               ;   in Loop: Header=BB4_9 Depth=1
	v_add_nc_u32_e32 v92, s7, v85
	global_load_u16 v92, v92, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v91, v92 offset:2560
	s_and_saveexec_b32 s15, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s15, exec_lo, s15
	s_cbranch_execz .LBB4_14
; %bb.12:                               ;   in Loop: Header=BB4_9 Depth=1
	v_add_nc_u32_e32 v92, s7, v84
	global_load_u16 v92, v92, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v91, v92 offset:3072
	s_and_saveexec_b32 s15, s3
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s15, exec_lo, s15
	s_cbranch_execz .LBB4_14
; %bb.13:                               ;   in Loop: Header=BB4_9 Depth=1
	v_add_nc_u32_e32 v92, s7, v83
	global_load_u16 v92, v92, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v91, v92 offset:3584
.LBB4_14:                               ;   in Loop: Header=BB4_9 Depth=1
	s_or_b32 exec_lo, exec_lo, s13
	s_and_saveexec_b32 s13, s1
	s_cbranch_execz .LBB4_7
; %bb.15:                               ;   in Loop: Header=BB4_9 Depth=1
	global_load_b32 v91, v[74:75], off
	v_lshl_add_u32 v108, s14, 13, v77
	s_wait_loadcnt 0x0
	v_and_b32_e32 v92, 1, v91
	v_cmp_lt_i32_e32 vcc_lo, -1, v91
	v_and_b32_e32 v93, 2, v91
	v_and_b32_e32 v94, 4, v91
	v_and_b32_e32 v95, 8, v91
	v_and_b32_e32 v96, 16, v91
	v_and_b32_e32 v97, 32, v91
	v_and_b32_e32 v98, 64, v91
	v_and_b32_e32 v99, 0x80, v91
	v_and_b32_e32 v100, 0x100, v91
	v_and_b32_e32 v101, 0x200, v91
	v_and_b32_e32 v102, 0x400, v91
	v_and_b32_e32 v103, 0x800, v91
	v_and_b32_e32 v104, 0x1000, v91
	v_and_b32_e32 v105, 0x2000, v91
	v_and_b32_e32 v106, 0x4000, v91
	v_and_b32_e32 v107, 0x8000, v91
	v_and_b32_e32 v109, 0x10000, v91
	v_and_b32_e32 v110, 0x20000, v91
	v_and_b32_e32 v111, 0x40000, v91
	v_and_b32_e32 v112, 0x80000, v91
	v_and_b32_e32 v113, 0x100000, v91
	v_and_b32_e32 v114, 0x200000, v91
	v_and_b32_e32 v115, 0x400000, v91
	v_and_b32_e32 v116, 0x800000, v91
	v_and_b32_e32 v117, 0x1000000, v91
	v_and_b32_e32 v118, 0x2000000, v91
	v_and_b32_e32 v119, 0x4000000, v91
	v_and_b32_e32 v120, 0x8000000, v91
	v_and_b32_e32 v121, 0x10000000, v91
	v_and_b32_e32 v122, 0x20000000, v91
	v_and_b32_e32 v123, 2.0, v91
	v_cndmask_b32_e32 v91, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v92
	v_cndmask_b32_e32 v92, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v93
	v_cndmask_b32_e32 v124, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v94
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v92, v92, v124
	v_cndmask_b32_e32 v93, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v95
	v_cndmask_b32_e32 v125, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v96
	v_pack_b32_f16 v93, v93, v125
	v_cndmask_b32_e32 v94, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v97
	v_cndmask_b32_e32 v96, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v98
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v94, v94, v96
	v_cndmask_b32_e32 v95, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v99
	v_cndmask_b32_e32 v97, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v100
	v_pack_b32_f16 v95, v95, v97
	v_cndmask_b32_e32 v100, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v101
	v_cndmask_b32_e32 v101, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v102
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v96, v100, v101
	v_cndmask_b32_e32 v102, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v103
	v_cndmask_b32_e32 v103, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v104
	v_pack_b32_f16 v97, v102, v103
	v_cndmask_b32_e32 v98, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v105
	v_cndmask_b32_e32 v104, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v106
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v98, v98, v104
	v_cndmask_b32_e32 v99, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v107
	v_cndmask_b32_e32 v105, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v109
	v_pack_b32_f16 v99, v99, v105
	v_cndmask_b32_e32 v106, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v110
	v_cndmask_b32_e32 v107, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v111
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v100, v106, v107
	v_cndmask_b32_e32 v109, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v112
	v_cndmask_b32_e32 v110, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v113
	v_pack_b32_f16 v101, v109, v110
	v_cndmask_b32_e32 v111, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v114
	v_cndmask_b32_e32 v112, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v115
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v102, v111, v112
	v_cndmask_b32_e32 v113, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v116
	v_cndmask_b32_e32 v114, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v117
	v_pack_b32_f16 v103, v113, v114
	v_cndmask_b32_e32 v115, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v118
	v_cndmask_b32_e32 v116, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v119
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v104, v115, v116
	v_cndmask_b32_e32 v117, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v120
	v_cndmask_b32_e32 v118, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v121
	v_pack_b32_f16 v105, v117, v118
	v_cndmask_b32_e32 v119, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v122
	v_cndmask_b32_e32 v120, 0x3c00, v90, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v123
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_pack_b32_f16 v106, v119, v120
	v_cndmask_b32_e32 v121, 0x3c00, v90, vcc_lo
	v_pack_b32_f16 v107, v121, v91
	ds_store_b128 v108, v[92:95]
	ds_store_b128 v108, v[96:99] offset:16
	ds_store_b128 v108, v[100:103] offset:32
	ds_store_b128 v108, v[104:107] offset:48
	s_branch .LBB4_7
.LBB4_16:
	v_lshl_add_u32 v0, v78, 4, s10
	v_or_b32_e32 v1, s11, v80
	v_cvt_f16_f32_e32 v26, v26
	v_cvt_f16_f32_e32 v27, v27
	v_cvt_f16_f32_e32 v28, v28
	v_or_b32_e32 v0, v0, v79
	v_cvt_f16_f32_e32 v29, v29
	v_cvt_f16_f32_e32 v30, v30
	v_cvt_f16_f32_e32 v18, v18
	v_cvt_f16_f32_e32 v19, v19
	v_lshl_or_b32 v0, v0, 12, v1
	v_cvt_f16_f32_e32 v1, v31
	v_cvt_f16_f32_e32 v31, v32
	v_cvt_f16_f32_e32 v32, v33
	v_cvt_f16_f32_e32 v20, v20
	s_clause 0x7
	global_store_b16 v0, v26, s[8:9] scale_offset
	global_store_b16 v0, v27, s[8:9] offset:8192 scale_offset
	global_store_b16 v0, v28, s[8:9] offset:16384 scale_offset
	global_store_b16 v0, v29, s[8:9] offset:24576 scale_offset
	global_store_b16 v0, v30, s[8:9] offset:32768 scale_offset
	global_store_b16 v0, v1, s[8:9] offset:40960 scale_offset
	global_store_b16 v0, v31, s[8:9] offset:49152 scale_offset
	global_store_b16 v0, v18, s[8:9] offset:32 scale_offset
	s_wait_xcnt 0x2
	v_add_nc_u32_e32 v1, 16, v0
	v_cvt_f16_f32_e32 v21, v21
	v_cvt_f16_f32_e32 v22, v22
	v_cvt_f16_f32_e32 v23, v23
	v_cvt_f16_f32_e32 v10, v10
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v18, v25
	global_store_b16 v0, v32, s[8:9] offset:57344 scale_offset
	v_cvt_f16_f32_e32 v24, v24
	s_clause 0x7
	global_store_b16 v1, v19, s[8:9] offset:8192 scale_offset
	global_store_b16 v1, v20, s[8:9] offset:16384 scale_offset
	global_store_b16 v1, v21, s[8:9] offset:24576 scale_offset
	global_store_b16 v1, v22, s[8:9] offset:32768 scale_offset
	global_store_b16 v1, v23, s[8:9] offset:40960 scale_offset
	global_store_b16 v1, v24, s[8:9] offset:49152 scale_offset
	global_store_b16 v1, v18, s[8:9] offset:57344 scale_offset
	global_store_b16 v0, v10, s[8:9] offset:64 scale_offset
	s_wait_xcnt 0x1
	v_cvt_f16_f32_e32 v1, v11
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v10, 32, v0
	v_cvt_f16_f32_e32 v11, v12
	v_cvt_f16_f32_e32 v12, v13
	v_cvt_f16_f32_e32 v13, v14
	v_cvt_f16_f32_e32 v14, v15
	v_cvt_f16_f32_e32 v15, v16
	v_cvt_f16_f32_e32 v16, v17
	v_cvt_f16_f32_e32 v2, v2
	s_clause 0x7
	global_store_b16 v10, v1, s[8:9] offset:8192 scale_offset
	global_store_b16 v10, v11, s[8:9] offset:16384 scale_offset
	global_store_b16 v10, v12, s[8:9] offset:24576 scale_offset
	global_store_b16 v10, v13, s[8:9] offset:32768 scale_offset
	global_store_b16 v10, v14, s[8:9] offset:40960 scale_offset
	global_store_b16 v10, v15, s[8:9] offset:49152 scale_offset
	global_store_b16 v10, v16, s[8:9] offset:57344 scale_offset
	global_store_b16 v0, v2, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x7
	v_cvt_f16_f32_e32 v1, v3
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v0, 48, v0
	v_cvt_f16_f32_e32 v2, v4
	v_cvt_f16_f32_e32 v3, v5
	v_cvt_f16_f32_e32 v4, v6
	v_cvt_f16_f32_e32 v5, v7
	v_cvt_f16_f32_e32 v6, v8
	v_cvt_f16_f32_e32 v7, v9
	s_clause 0x6
	global_store_b16 v0, v1, s[8:9] offset:8192 scale_offset
	global_store_b16 v0, v2, s[8:9] offset:16384 scale_offset
	global_store_b16 v0, v3, s[8:9] offset:24576 scale_offset
	global_store_b16 v0, v4, s[8:9] offset:32768 scale_offset
	global_store_b16 v0, v5, s[8:9] offset:40960 scale_offset
	global_store_b16 v0, v6, s[8:9] offset:49152 scale_offset
	global_store_b16 v0, v7, s[8:9] offset:57344 scale_offset
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel bitdelta_full
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
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 126
		.amdhsa_next_free_sgpr 16
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 31
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
	.size	bitdelta_full, .Lfunc_end4-bitdelta_full
                                        ; -- End function
	.set bitdelta_full.num_vgpr, 126
	.set bitdelta_full.num_agpr, 0
	.set bitdelta_full.numbered_sgpr, 16
	.set bitdelta_full.num_named_barrier, 0
	.set bitdelta_full.private_seg_size, 0
	.set bitdelta_full.uses_vcc, 1
	.set bitdelta_full.uses_flat_scratch, 0
	.set bitdelta_full.has_dyn_sized_stack, 0
	.set bitdelta_full.has_recursion, 0
	.set bitdelta_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3884
; TotalNumSgprs: 18
; NumVgprs: 126
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 24576 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 126
; NamedBarCnt: 0
; Occupancy: 8
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	bitdelta_batched_full   ; -- Begin function bitdelta_batched_full
	.globl	bitdelta_batched_full
	.p2align	8
	.type	bitdelta_batched_full,@function
bitdelta_batched_full:                  ; @bitdelta_batched_full
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_bfe_u32 s4, ttmp6, 0x40010
	s_add_co_i32 s2, s2, 1
	s_and_b32 s3, ttmp6, 15
	s_mul_i32 s2, ttmp9, s2
	s_add_co_i32 s4, s4, 1
	s_add_co_i32 s3, s3, s2
	s_mul_i32 s2, ttmp7, s4
	s_bfe_u32 s4, ttmp6, 0x40004
	s_getreg_b32 s5, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s2, s4, s2
	s_cmp_eq_u32 s5, 0
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[10:11], s[0:1], 0x10
	s_cselect_b32 s3, ttmp9, s3
	v_dual_lshrrev_b32 v1, 5, v0 :: v_dual_lshlrev_b32 v138, 6, v0
	v_lshrrev_b32_e32 v2, 1, v0
	s_cselect_b32 s8, ttmp7, s2
	s_lshr_b32 s2, s3, 4
	s_lshl_b32 s15, s3, 5
	s_wait_xcnt 0x0
	s_and_b32 s0, s2, 0x1ff8
	s_and_b32 s2, s3, 7
	v_and_b32_e32 v4, 0x3c0, v138
	v_dual_lshlrev_b32 v3, 4, v1 :: v_dual_bitop2_b32 v2, 8, v2 bitop3:0x40
	v_and_or_b32 v139, 0xf00, s15, v0
	s_or_b32 s0, s0, s2
	s_mov_b32 s9, 0
	s_lshl_b32 s14, s0, 7
	v_lshl_or_b32 v5, v1, 10, v4
	v_or3_b32 v7, s14, v3, v2
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v6, 1, v2
	v_dual_lshlrev_b32 v2, 2, v139 :: v_dual_lshlrev_b32 v1, 12, v1
	s_lshl_b64 s[0:1], s[8:9], 21
	s_lshl_b32 s3, s3, 15
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[0:1], s[6:7], s[0:1]
	v_lshlrev_b32_e32 v141, 12, v7
	v_add_nc_u64_e32 v[136:137], s[0:1], v[2:3]
	v_and_b32_e32 v2, 31, v0
	v_or_b32_e32 v152, v6, v4
	v_and_or_b32 v1, 0xffc00000, s3, v1
	s_lshl_b32 s2, s2, 19
	v_subrev_co_u32 v140, s6, 0x100, v0
	v_or3_b32 v142, v5, v6, 0x8000
	s_delay_alu instid0(VALU_DEP_3)
	v_or3_b32 v149, s2, v1, v2
	v_or_b32_e32 v143, 0x1000, v141
	v_or_b32_e32 v144, 0x2000, v141
	v_or_b32_e32 v145, 0x3000, v141
	v_or_b32_e32 v146, 0x4000, v141
	v_or_b32_e32 v147, 0x5000, v141
	v_or_b32_e32 v148, 0x6000, v141
	v_or_b32_e32 v150, 0x7000, v141
	v_bitop3_b32 v151, v0, 0xf0f, s15 bitop3:0xc8
	v_lshl_or_b32 v153, v0, 1, 0x8000
	v_or_b32_e32 v154, 32, v149
	v_mov_b32_e32 v155, 0xbc00
	s_lshl_b64 s[12:13], s[8:9], 25
	s_mov_b32 s7, -1
	s_add_nc_u64 s[2:3], s[4:5], s[12:13]
	s_add_nc_u64 s[4:5], s[10:11], s[12:13]
	s_branch .LBB5_2
.LBB5_1:                                ;   in Loop: Header=BB5_2 Depth=1
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v64, s9, 7, v151
	v_cvt_f16_f32_e32 v56, v56
	v_cvt_f16_f32_e32 v57, v57
	v_cvt_f16_f32_e32 v58, v58
	v_cvt_f16_f32_e32 v59, v59
	v_dual_add_nc_u32 v66, v64, v141 :: v_dual_bitop2_b32 v65, v64, v141 bitop3:0x54
	v_cvt_f16_f32_e32 v60, v60
	v_cvt_f16_f32_e32 v61, v61
	v_cvt_f16_f32_e32 v62, v62
	global_store_b16 v65, v56, s[4:5] scale_offset
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v56, v63
	s_clause 0x6
	global_store_b16 v66, v57, s[4:5] offset:8192 scale_offset
	global_store_b16 v66, v58, s[4:5] offset:16384 scale_offset
	global_store_b16 v66, v59, s[4:5] offset:24576 scale_offset
	global_store_b16 v66, v60, s[4:5] offset:32768 scale_offset
	global_store_b16 v66, v61, s[4:5] offset:40960 scale_offset
	global_store_b16 v66, v62, s[4:5] offset:49152 scale_offset
	global_store_b16 v66, v56, s[4:5] offset:57344 scale_offset
	v_cvt_f16_f32_e32 v48, v48
	v_cvt_f16_f32_e32 v49, v49
	s_wait_xcnt 0x0
	v_dual_add_nc_u32 v56, v64, v143 :: v_dual_add_nc_u32 v57, v64, v144
	v_cvt_f16_f32_e32 v40, v40
	v_cvt_f16_f32_e32 v41, v41
	v_cvt_f16_f32_e32 v32, v32
	v_cvt_f16_f32_e32 v33, v33
	v_cvt_f16_f32_e32 v24, v24
	v_cvt_f16_f32_e32 v25, v25
	v_cvt_f16_f32_e32 v16, v16
	v_cvt_f16_f32_e32 v17, v17
	v_cvt_f16_f32_e32 v9, v9
	v_cvt_f16_f32_e32 v50, v50
	v_cvt_f16_f32_e32 v42, v42
	v_cvt_f16_f32_e32 v34, v34
	v_cvt_f16_f32_e32 v26, v26
	v_cvt_f16_f32_e32 v18, v18
	v_cvt_f16_f32_e32 v10, v10
	v_cvt_f16_f32_e32 v51, v51
	v_dual_add_nc_u32 v58, v64, v145 :: v_dual_add_nc_u32 v59, v64, v146
	v_cvt_f16_f32_e32 v43, v43
	v_cvt_f16_f32_e32 v35, v35
	v_cvt_f16_f32_e32 v27, v27
	v_cvt_f16_f32_e32 v19, v19
	v_cvt_f16_f32_e32 v11, v11
	v_cvt_f16_f32_e32 v52, v52
	v_cvt_f16_f32_e32 v44, v44
	v_cvt_f16_f32_e32 v36, v36
	v_cvt_f16_f32_e32 v28, v28
	v_cvt_f16_f32_e32 v20, v20
	v_cvt_f16_f32_e32 v12, v12
	v_cvt_f16_f32_e32 v53, v53
	v_dual_add_nc_u32 v60, v64, v147 :: v_dual_add_nc_u32 v61, v64, v148
	v_cvt_f16_f32_e32 v45, v45
	v_cvt_f16_f32_e32 v37, v37
	v_cvt_f16_f32_e32 v29, v29
	v_cvt_f16_f32_e32 v21, v21
	v_cvt_f16_f32_e32 v13, v13
	v_cvt_f16_f32_e32 v0, v0
	v_cvt_f16_f32_e32 v54, v54
	v_cvt_f16_f32_e32 v55, v55
	v_add_nc_u32_e32 v62, v64, v150
	s_clause 0x7
	global_store_b16 v56, v49, s[4:5] offset:32 scale_offset
	global_store_b16 v57, v50, s[4:5] offset:32 scale_offset
	global_store_b16 v58, v51, s[4:5] offset:32 scale_offset
	global_store_b16 v59, v52, s[4:5] offset:32 scale_offset
	global_store_b16 v60, v53, s[4:5] offset:32 scale_offset
	global_store_b16 v61, v54, s[4:5] offset:32 scale_offset
	global_store_b16 v62, v55, s[4:5] offset:32 scale_offset
	global_store_b16 v66, v48, s[4:5] offset:32 scale_offset
	v_cvt_f16_f32_e32 v46, v46
	v_cvt_f16_f32_e32 v47, v47
	s_clause 0x7
	global_store_b16 v56, v41, s[4:5] offset:64 scale_offset
	global_store_b16 v57, v42, s[4:5] offset:64 scale_offset
	global_store_b16 v58, v43, s[4:5] offset:64 scale_offset
	global_store_b16 v59, v44, s[4:5] offset:64 scale_offset
	global_store_b16 v60, v45, s[4:5] offset:64 scale_offset
	global_store_b16 v61, v46, s[4:5] offset:64 scale_offset
	global_store_b16 v62, v47, s[4:5] offset:64 scale_offset
	global_store_b16 v66, v40, s[4:5] offset:64 scale_offset
	v_cvt_f16_f32_e32 v38, v38
	v_cvt_f16_f32_e32 v39, v39
	s_clause 0x7
	global_store_b16 v56, v33, s[4:5] offset:96 scale_offset
	global_store_b16 v57, v34, s[4:5] offset:96 scale_offset
	global_store_b16 v58, v35, s[4:5] offset:96 scale_offset
	global_store_b16 v59, v36, s[4:5] offset:96 scale_offset
	global_store_b16 v60, v37, s[4:5] offset:96 scale_offset
	global_store_b16 v61, v38, s[4:5] offset:96 scale_offset
	global_store_b16 v62, v39, s[4:5] offset:96 scale_offset
	global_store_b16 v66, v32, s[4:5] offset:96 scale_offset
	v_cvt_f16_f32_e32 v30, v30
	v_cvt_f16_f32_e32 v31, v31
	s_clause 0x7
	global_store_b16 v56, v25, s[4:5] offset:128 scale_offset
	global_store_b16 v57, v26, s[4:5] offset:128 scale_offset
	global_store_b16 v58, v27, s[4:5] offset:128 scale_offset
	global_store_b16 v59, v28, s[4:5] offset:128 scale_offset
	global_store_b16 v60, v29, s[4:5] offset:128 scale_offset
	global_store_b16 v61, v30, s[4:5] offset:128 scale_offset
	global_store_b16 v62, v31, s[4:5] offset:128 scale_offset
	global_store_b16 v66, v24, s[4:5] offset:128 scale_offset
	v_cvt_f16_f32_e32 v22, v22
	v_cvt_f16_f32_e32 v23, v23
	s_clause 0x6
	global_store_b16 v56, v17, s[4:5] offset:160 scale_offset
	global_store_b16 v57, v18, s[4:5] offset:160 scale_offset
	global_store_b16 v58, v19, s[4:5] offset:160 scale_offset
	global_store_b16 v59, v20, s[4:5] offset:160 scale_offset
	global_store_b16 v60, v21, s[4:5] offset:160 scale_offset
	global_store_b16 v61, v22, s[4:5] offset:160 scale_offset
	global_store_b16 v62, v23, s[4:5] offset:160 scale_offset
	v_cvt_f16_f32_e32 v8, v8
	global_store_b16 v66, v16, s[4:5] offset:160 scale_offset
	v_cvt_f16_f32_e32 v14, v14
	v_cvt_f16_f32_e32 v15, v15
	v_cvt_f16_f32_e32 v1, v1
	s_clause 0x9
	global_store_b16 v56, v9, s[4:5] offset:192 scale_offset
	global_store_b16 v57, v10, s[4:5] offset:192 scale_offset
	global_store_b16 v58, v11, s[4:5] offset:192 scale_offset
	global_store_b16 v59, v12, s[4:5] offset:192 scale_offset
	global_store_b16 v60, v13, s[4:5] offset:192 scale_offset
	global_store_b16 v61, v14, s[4:5] offset:192 scale_offset
	global_store_b16 v62, v15, s[4:5] offset:192 scale_offset
	global_store_b16 v66, v8, s[4:5] offset:192 scale_offset
	global_store_b16 v66, v0, s[4:5] offset:224 scale_offset
	global_store_b16 v56, v1, s[4:5] offset:224 scale_offset
	s_wait_xcnt 0x1
	v_cvt_f16_f32_e32 v0, v2
	s_wait_xcnt 0x0
	v_cvt_f16_f32_e32 v1, v3
	v_cvt_f16_f32_e32 v2, v4
	v_cvt_f16_f32_e32 v3, v5
	s_mov_b32 s9, 1
	s_and_b32 vcc_lo, exec_lo, s7
	s_mov_b32 s7, 0
	v_cvt_f16_f32_e32 v4, v6
	v_cvt_f16_f32_e32 v5, v7
	s_clause 0x5
	global_store_b16 v57, v0, s[4:5] offset:224 scale_offset
	global_store_b16 v58, v1, s[4:5] offset:224 scale_offset
	global_store_b16 v59, v2, s[4:5] offset:224 scale_offset
	global_store_b16 v60, v3, s[4:5] offset:224 scale_offset
	global_store_b16 v61, v4, s[4:5] offset:224 scale_offset
	global_store_b16 v62, v5, s[4:5] offset:224 scale_offset
	s_cbranch_vccnz .LBB5_14
.LBB5_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB5_3 Depth 2
                                        ;     Child Loop BB5_9 Depth 2
                                        ;       Child Loop BB5_11 Depth 3
	s_wait_xcnt 0x4
	v_dual_mov_b32 v0, v149 :: v_dual_mov_b32 v1, v153
	s_wait_xcnt 0x3
	v_mov_b32_e32 v2, v140
	s_xor_b32 s7, s7, -1
	s_mov_b32 s8, 0
.LBB5_3:                                ;   Parent Loop BB5_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	global_load_u16 v3, v0, s[2:3] scale_offset
	v_add_nc_u32_e32 v2, 0x100, v2
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v0, 0x8000, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xeff, v2
	s_or_b32 s8, vcc_lo, s8
	s_wait_loadcnt 0x0
	ds_store_b16 v1, v3
	v_add_nc_u32_e32 v1, 0x200, v1
	s_and_not1_b32 exec_lo, exec_lo, s8
	s_cbranch_execnz .LBB5_3
; %bb.4:                                ;   in Loop: Header=BB5_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s8
	s_and_saveexec_b32 s8, s6
	s_cbranch_execz .LBB5_6
; %bb.5:                                ;   in Loop: Header=BB5_2 Depth=1
	global_load_b32 v0, v[136:137], off
	s_wait_loadcnt 0x0
	v_and_b32_e32 v1, 1, v0
	v_cmp_lt_i32_e32 vcc_lo, -1, v0
	v_and_b32_e32 v2, 2, v0
	v_and_b32_e32 v3, 4, v0
	v_and_b32_e32 v4, 8, v0
	v_and_b32_e32 v5, 16, v0
	v_cndmask_b32_e32 v32, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	v_and_b32_e32 v6, 32, v0
	v_and_b32_e32 v7, 64, v0
	v_and_b32_e32 v8, 0x80, v0
	v_and_b32_e32 v9, 0x100, v0
	v_and_b32_e32 v10, 0x200, v0
	v_and_b32_e32 v11, 0x400, v0
	v_and_b32_e32 v12, 0x800, v0
	v_and_b32_e32 v13, 0x1000, v0
	v_and_b32_e32 v14, 0x2000, v0
	v_and_b32_e32 v15, 0x4000, v0
	v_and_b32_e32 v16, 0x8000, v0
	v_and_b32_e32 v17, 0x10000, v0
	v_and_b32_e32 v18, 0x20000, v0
	v_and_b32_e32 v19, 0x40000, v0
	v_and_b32_e32 v20, 0x80000, v0
	v_and_b32_e32 v21, 0x100000, v0
	v_and_b32_e32 v22, 0x200000, v0
	v_and_b32_e32 v23, 0x400000, v0
	v_and_b32_e32 v24, 0x800000, v0
	v_and_b32_e32 v25, 0x1000000, v0
	v_and_b32_e32 v26, 0x2000000, v0
	v_and_b32_e32 v27, 0x4000000, v0
	v_and_b32_e32 v28, 0x8000000, v0
	v_and_b32_e32 v29, 0x10000000, v0
	v_and_b32_e32 v30, 0x20000000, v0
	v_and_b32_e32 v31, 2.0, v0
	v_cndmask_b32_e32 v0, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v2
	v_cndmask_b32_e32 v33, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v0, v0, v33
	v_cndmask_b32_e32 v1, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v4
	v_cndmask_b32_e32 v4, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v5
	v_pack_b32_f16 v1, v1, v4
	v_cndmask_b32_e32 v2, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v6
	v_cndmask_b32_e32 v5, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v7
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v2, v2, v5
	v_cndmask_b32_e32 v3, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v8
	v_cndmask_b32_e32 v6, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v9
	v_pack_b32_f16 v3, v3, v6
	v_cndmask_b32_e32 v8, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v10
	v_cndmask_b32_e32 v9, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v11
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v4, v8, v9
	v_cndmask_b32_e32 v10, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v12
	v_cndmask_b32_e32 v11, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v13
	v_pack_b32_f16 v5, v10, v11
	v_cndmask_b32_e32 v12, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v14
	v_cndmask_b32_e32 v13, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v15
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v6, v12, v13
	v_cndmask_b32_e32 v7, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v16
	v_cndmask_b32_e32 v14, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v17
	v_pack_b32_f16 v7, v7, v14
	v_cndmask_b32_e32 v15, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v18
	v_cndmask_b32_e32 v16, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v19
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v8, v15, v16
	v_cndmask_b32_e32 v17, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v20
	v_cndmask_b32_e32 v18, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v21
	v_pack_b32_f16 v9, v17, v18
	v_cndmask_b32_e32 v19, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v22
	v_cndmask_b32_e32 v20, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v23
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v10, v19, v20
	v_cndmask_b32_e32 v21, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v24
	v_cndmask_b32_e32 v22, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v25
	v_pack_b32_f16 v11, v21, v22
	v_cndmask_b32_e32 v23, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v26
	v_cndmask_b32_e32 v24, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v27
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v12, v23, v24
	v_cndmask_b32_e32 v25, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v28
	v_cndmask_b32_e32 v26, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v29
	v_pack_b32_f16 v13, v25, v26
	v_cndmask_b32_e32 v27, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v30
	v_cndmask_b32_e32 v28, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v31
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_pack_b32_f16 v14, v27, v28
	v_cndmask_b32_e32 v29, 0x3c00, v155, vcc_lo
	v_pack_b32_f16 v15, v29, v32
	ds_store_b128 v138, v[0:3]
	ds_store_b128 v138, v[4:7] offset:16
	ds_store_b128 v138, v[8:11] offset:32
	ds_store_b128 v138, v[12:15] offset:48
.LBB5_6:                                ;   in Loop: Header=BB5_2 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s8
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v157, v154
	v_lshl_or_b32 v156, s9, 13, v152
	s_mov_b32 s10, 0
	s_mov_b32 s8, -1
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_dual_mov_b32 v7, v0 :: v_dual_mov_b32 v8, v0
	v_dual_mov_b32 v9, v0 :: v_dual_mov_b32 v10, v0
	v_dual_mov_b32 v11, v0 :: v_dual_mov_b32 v12, v0
	v_dual_mov_b32 v13, v0 :: v_dual_mov_b32 v14, v0
	v_dual_mov_b32 v15, v0 :: v_dual_mov_b32 v16, v0
	v_dual_mov_b32 v17, v0 :: v_dual_mov_b32 v18, v0
	v_dual_mov_b32 v19, v0 :: v_dual_mov_b32 v20, v0
	v_dual_mov_b32 v21, v0 :: v_dual_mov_b32 v22, v0
	v_dual_mov_b32 v23, v0 :: v_dual_mov_b32 v24, v0
	v_dual_mov_b32 v25, v0 :: v_dual_mov_b32 v26, v0
	v_dual_mov_b32 v27, v0 :: v_dual_mov_b32 v28, v0
	v_dual_mov_b32 v29, v0 :: v_dual_mov_b32 v30, v0
	v_dual_mov_b32 v31, v0 :: v_dual_mov_b32 v32, v0
	v_dual_mov_b32 v33, v0 :: v_dual_mov_b32 v34, v0
	v_dual_mov_b32 v35, v0 :: v_dual_mov_b32 v36, v0
	v_dual_mov_b32 v37, v0 :: v_dual_mov_b32 v38, v0
	v_dual_mov_b32 v39, v0 :: v_dual_mov_b32 v40, v0
	v_dual_mov_b32 v41, v0 :: v_dual_mov_b32 v42, v0
	v_dual_mov_b32 v43, v0 :: v_dual_mov_b32 v44, v0
	v_dual_mov_b32 v45, v0 :: v_dual_mov_b32 v46, v0
	v_dual_mov_b32 v47, v0 :: v_dual_mov_b32 v48, v0
	v_dual_mov_b32 v49, v0 :: v_dual_mov_b32 v50, v0
	v_dual_mov_b32 v51, v0 :: v_dual_mov_b32 v52, v0
	v_dual_mov_b32 v53, v0 :: v_dual_mov_b32 v54, v0
	v_dual_mov_b32 v55, v0 :: v_dual_mov_b32 v56, v0
	v_dual_mov_b32 v57, v0 :: v_dual_mov_b32 v58, v0
	v_dual_mov_b32 v59, v0 :: v_dual_mov_b32 v60, v0
	v_dual_mov_b32 v61, v0 :: v_dual_mov_b32 v62, v0
	v_mov_b32_e32 v63, v0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB5_9
.LBB5_7:                                ;   in Loop: Header=BB5_9 Depth=2
	s_or_b32 exec_lo, exec_lo, s12
.LBB5_8:                                ;   in Loop: Header=BB5_9 Depth=2
	s_wait_dscnt 0xe
	v_wmma_f32_16x16x32_f16 v[56:63], v[64:71], v[128:135], v[56:63]
	v_add_nc_u32_e32 v157, 32, v157
	s_xor_b32 s8, s8, -1
	s_and_b32 vcc_lo, exec_lo, s11
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_wmma_f32_16x16x32_f16 v[48:55], v[64:71], v[120:127], v[48:55]
	v_wmma_f32_16x16x32_f16 v[40:47], v[64:71], v[112:119], v[40:47]
	v_wmma_f32_16x16x32_f16 v[32:39], v[64:71], v[104:111], v[32:39]
	v_wmma_f32_16x16x32_f16 v[24:31], v[64:71], v[96:103], v[24:31]
	v_wmma_f32_16x16x32_f16 v[16:23], v[64:71], v[88:95], v[16:23]
	v_wmma_f32_16x16x32_f16 v[8:15], v[64:71], v[80:87], v[8:15]
	v_wmma_f32_16x16x32_f16 v[0:7], v[64:71], v[72:79], v[0:7]
	s_cbranch_vccnz .LBB5_1
.LBB5_9:                                ;   Parent Loop BB5_2 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB5_11 Depth 3
	s_bfe_u32 s13, s10, 0x10005
	s_mov_b32 s11, s10
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_add_u32 v68, s13, 13, v142
	v_lshl_add_u32 v76, s13, 14, v156
	s_add_co_i32 s10, s10, 32
	s_cmp_gt_u32 s11, 0xfdf
	ds_load_b128 v[64:67], v68
	ds_load_b128 v[68:71], v68 offset:32
	ds_load_b128 v[128:131], v76
	ds_load_b128 v[132:135], v76 offset:32
	ds_load_b128 v[120:123], v76 offset:1024
	ds_load_b128 v[124:127], v76 offset:1056
	ds_load_b128 v[112:115], v76 offset:2048
	ds_load_b128 v[116:119], v76 offset:2080
	ds_load_b128 v[104:107], v76 offset:3072
	ds_load_b128 v[108:111], v76 offset:3104
	ds_load_b128 v[96:99], v76 offset:4096
	ds_load_b128 v[100:103], v76 offset:4128
	ds_load_b128 v[88:91], v76 offset:5120
	ds_load_b128 v[92:95], v76 offset:5152
	ds_load_b128 v[80:83], v76 offset:6144
	ds_load_b128 v[84:87], v76 offset:6176
	ds_load_b128 v[72:75], v76 offset:7168
	ds_load_b128 v[76:79], v76 offset:7200
	s_cselect_b32 s11, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 vcc_lo, exec_lo, s11
	s_cbranch_vccnz .LBB5_8
; %bb.10:                               ;   in Loop: Header=BB5_9 Depth=2
	v_cndmask_b32_e64 v159, 0, 1, s8
	v_dual_mov_b32 v158, v157 :: v_dual_mov_b32 v160, v140
	s_mov_b32 s12, 0
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_add_u32 v159, v159, 13, v153
.LBB5_11:                               ;   Parent Loop BB5_2 Depth=1
                                        ;     Parent Loop BB5_9 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	global_load_u16 v161, v158, s[2:3] scale_offset
	v_add_nc_u32_e32 v160, 0x100, v160
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v158, 0x8000, v158
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_lt_u32_e32 vcc_lo, 0xeff, v160
	s_or_b32 s12, vcc_lo, s12
	s_wait_loadcnt 0x0
	ds_store_b16 v159, v161
	v_add_nc_u32_e32 v159, 0x200, v159
	s_and_not1_b32 exec_lo, exec_lo, s12
	s_cbranch_execnz .LBB5_11
; %bb.12:                               ;   in Loop: Header=BB5_9 Depth=2
	s_or_b32 exec_lo, exec_lo, s12
	s_and_saveexec_b32 s12, s6
	s_cbranch_execz .LBB5_7
; %bb.13:                               ;   in Loop: Header=BB5_9 Depth=2
	v_lshl_or_b32 v158, s10, 7, v139
	s_xor_b32 s13, s13, 1
	s_delay_alu instid0(SALU_CYCLE_1)
	v_lshl_or_b32 v174, s13, 14, v138
	global_load_b32 v158, v158, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	v_and_b32_e32 v159, 1, v158
	v_cmp_lt_i32_e32 vcc_lo, -1, v158
	v_and_b32_e32 v160, 2, v158
	v_and_b32_e32 v161, 4, v158
	v_and_b32_e32 v162, 8, v158
	v_and_b32_e32 v163, 16, v158
	v_cndmask_b32_e32 v191, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v159
	v_and_b32_e32 v164, 32, v158
	v_and_b32_e32 v165, 64, v158
	v_and_b32_e32 v166, 0x80, v158
	v_and_b32_e32 v167, 0x100, v158
	v_and_b32_e32 v168, 0x200, v158
	v_and_b32_e32 v169, 0x400, v158
	v_and_b32_e32 v170, 0x800, v158
	v_and_b32_e32 v171, 0x1000, v158
	v_and_b32_e32 v172, 0x2000, v158
	v_and_b32_e32 v173, 0x4000, v158
	v_and_b32_e32 v175, 0x8000, v158
	v_and_b32_e32 v176, 0x10000, v158
	v_and_b32_e32 v177, 0x20000, v158
	v_and_b32_e32 v178, 0x40000, v158
	v_and_b32_e32 v179, 0x80000, v158
	v_and_b32_e32 v180, 0x100000, v158
	v_and_b32_e32 v181, 0x200000, v158
	v_and_b32_e32 v182, 0x400000, v158
	v_and_b32_e32 v183, 0x800000, v158
	v_and_b32_e32 v184, 0x1000000, v158
	v_and_b32_e32 v185, 0x2000000, v158
	v_and_b32_e32 v186, 0x4000000, v158
	v_and_b32_e32 v187, 0x8000000, v158
	v_and_b32_e32 v188, 0x10000000, v158
	v_and_b32_e32 v189, 0x20000000, v158
	v_and_b32_e32 v190, 2.0, v158
	s_wait_xcnt 0x0
	v_cndmask_b32_e32 v158, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v160
	v_cndmask_b32_e32 v192, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v161
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v158, v158, v192
	v_cndmask_b32_e32 v159, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v162
	v_cndmask_b32_e32 v162, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v163
	v_pack_b32_f16 v159, v159, v162
	v_cndmask_b32_e32 v160, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v164
	v_cndmask_b32_e32 v163, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v165
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v160, v160, v163
	v_cndmask_b32_e32 v161, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v166
	v_cndmask_b32_e32 v164, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v167
	v_pack_b32_f16 v161, v161, v164
	v_cndmask_b32_e32 v166, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v168
	v_cndmask_b32_e32 v167, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v169
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v162, v166, v167
	v_cndmask_b32_e32 v168, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v170
	v_cndmask_b32_e32 v169, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v171
	v_pack_b32_f16 v163, v168, v169
	v_cndmask_b32_e32 v170, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v172
	v_cndmask_b32_e32 v171, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v173
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v164, v170, v171
	v_cndmask_b32_e32 v165, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v175
	v_cndmask_b32_e32 v172, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v176
	v_pack_b32_f16 v165, v165, v172
	v_cndmask_b32_e32 v173, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v177
	v_cndmask_b32_e32 v175, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v178
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v166, v173, v175
	v_cndmask_b32_e32 v176, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v179
	v_cndmask_b32_e32 v177, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v180
	v_pack_b32_f16 v167, v176, v177
	v_cndmask_b32_e32 v178, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v181
	v_cndmask_b32_e32 v179, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v182
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v168, v178, v179
	v_cndmask_b32_e32 v180, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v183
	v_cndmask_b32_e32 v181, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v184
	v_pack_b32_f16 v169, v180, v181
	v_cndmask_b32_e32 v182, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v185
	v_cndmask_b32_e32 v183, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v186
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v170, v182, v183
	v_cndmask_b32_e32 v184, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v187
	v_cndmask_b32_e32 v185, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v188
	v_pack_b32_f16 v171, v184, v185
	v_cndmask_b32_e32 v186, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v189
	v_cndmask_b32_e32 v187, 0x3c00, v155, vcc_lo
	v_cmp_eq_u32_e32 vcc_lo, 0, v190
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_pack_b32_f16 v172, v186, v187
	v_cndmask_b32_e32 v188, 0x3c00, v155, vcc_lo
	v_pack_b32_f16 v173, v188, v191
	ds_store_b128 v174, v[158:161]
	ds_store_b128 v174, v[162:165] offset:16
	ds_store_b128 v174, v[166:169] offset:32
	ds_store_b128 v174, v[170:173] offset:48
	s_branch .LBB5_7
.LBB5_14:
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel bitdelta_batched_full
		.amdhsa_group_segment_fixed_size 49152
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
		.amdhsa_next_free_vgpr 193
		.amdhsa_next_free_sgpr 16
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 32
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
	.size	bitdelta_batched_full, .Lfunc_end5-bitdelta_batched_full
                                        ; -- End function
	.set bitdelta_batched_full.num_vgpr, 193
	.set bitdelta_batched_full.num_agpr, 0
	.set bitdelta_batched_full.numbered_sgpr, 16
	.set bitdelta_batched_full.num_named_barrier, 0
	.set bitdelta_batched_full.private_seg_size, 0
	.set bitdelta_batched_full.uses_vcc, 1
	.set bitdelta_batched_full.uses_flat_scratch, 0
	.set bitdelta_batched_full.has_dyn_sized_stack, 0
	.set bitdelta_batched_full.has_recursion, 0
	.set bitdelta_batched_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4084
; TotalNumSgprs: 18
; NumVgprs: 193
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 49152 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 12
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 193
; NamedBarCnt: 0
; Occupancy: 4
; WaveLimiterHint : 1
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
	.type	__hip_cuid_4ef9ada7d8a8cefd,@object ; @__hip_cuid_4ef9ada7d8a8cefd
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_4ef9ada7d8a8cefd
__hip_cuid_4ef9ada7d8a8cefd:
	.byte	0                               ; 0x0
	.size	__hip_cuid_4ef9ada7d8a8cefd, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_4ef9ada7d8a8cefd
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
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           gemm_f16_full
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         gemm_f16_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     123
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
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           gemm_f8_full
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         gemm_f8_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     95
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
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           gemm_add_silu_f16_full
    .private_segment_fixed_size: 0
    .sgpr_count:     16
    .sgpr_spill_count: 0
    .symbol:         gemm_add_silu_f16_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     128
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
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           gemm_add_silu_f8_full
    .private_segment_fixed_size: 0
    .sgpr_count:     16
    .sgpr_spill_count: 0
    .symbol:         gemm_add_silu_f8_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     95
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
    .group_segment_fixed_size: 24576
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           bitdelta_full
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         bitdelta_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     126
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
    .group_segment_fixed_size: 49152
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           bitdelta_batched_full
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         bitdelta_batched_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     193
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
