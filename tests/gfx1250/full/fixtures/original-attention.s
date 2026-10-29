	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	flash_attention_original ; -- Begin function flash_attention_original
	.globl	flash_attention_original
	.p2align	8
	.type	flash_attention_original,@function
flash_attention_original:               ; @flash_attention_original
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x4000c
	s_and_b32 s3, ttmp6, 15
	s_add_co_i32 s2, s2, 1
	s_mov_b32 s25, 0
	s_mul_i32 s4, ttmp9, s2
	s_getreg_b32 s2, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s3, s3, s4
	s_cmp_eq_u32 s2, 0
	s_cselect_b32 s18, ttmp9, s3
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	s_bitcmp1_b32 s18, 0
	s_cselect_b32 s3, -1, 0
	s_and_b32 vcc_lo, exec_lo, s3
	s_cbranch_vccnz .LBB0_36
; %bb.1:
	s_clause 0x3
	s_load_b32 s3, s[0:1], 0x38
	s_load_b128 s[8:11], s[0:1], 0x20
	s_load_b128 s[12:15], s[0:1], 0x0
	s_load_b64 s[16:17], s[0:1], 0x10
	s_wait_xcnt 0x0
	s_bfe_u32 s0, ttmp6, 0x40010
	s_bfe_u32 s1, ttmp6, 0x40004
	s_add_co_i32 s0, s0, 1
	v_dual_lshrrev_b32 v2, 5, v0 :: v_dual_lshrrev_b32 v3, 1, v0
	s_mul_i32 s4, ttmp7, s0
	v_dual_lshlrev_b32 v4, 5, v0 :: v_dual_bitop2_b32 v1, 15, v0 bitop3:0x40
	s_add_co_i32 s1, s1, s4
	v_dual_mov_b32 v6, 0 :: v_dual_lshlrev_b32 v56, 1, v0
	v_dual_lshlrev_b32 v57, 4, v2 :: v_dual_bitop2_b32 v58, 8, v3 bitop3:0x40
	v_lshl_or_b32 v5, v2, 9, 0x2000
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_lshlrev_b32 v7, 1, v1 :: v_dual_mov_b32 v3, v6
	s_wait_kmcnt 0x0
	s_lshl_b32 s3, s3, 6
	s_cmp_eq_u32 s2, 0
	v_mbcnt_lo_u32_b32 v67, -1, 0
	s_cselect_b32 s1, ttmp7, s1
	v_and_b32_e32 v4, 0x1e0, v4
	s_mul_i32 s19, s3, s1
	v_dual_lshlrev_b32 v9, 1, v58 :: v_dual_bitop2_b32 v8, v5, v7 bitop3:0x54
	s_lshl_b32 s23, s19, 6
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_dual_lshlrev_b32 v59, 7, v58 :: v_dual_bitop2_b32 v2, s23, v0 bitop3:0x54
	v_or_b32_e32 v60, 0x1000, v7
	v_dual_lshlrev_b32 v7, 5, v58 :: v_dual_bitop2_b32 v65, s19, v1 bitop3:0x54
	s_lshr_b32 s20, s3, 4
	v_lshlrev_b64_e32 v[2:3], 1, v[2:3]
	v_cmp_eq_u32_e64 s0, 0, v1
	v_or3_b32 v61, v5, v4, v9
	v_or_b32_e32 v62, 0x100, v59
	v_or_b32_e32 v63, 0x200, v59
	v_or_b32_e32 v64, 0x300, v59
	s_cmp_lg_u32 s3, 0
	v_add_nc_u64_e32 v[42:43], s[14:15], v[2:3]
	v_add_nc_u64_e32 v[44:45], s[16:17], v[2:3]
	v_or_b32_e32 v2, 0x200, v0
	v_or_b32_e32 v3, 0x300, v0
	v_or_b32_e32 v66, 0x1000, v56
	v_cmp_gt_u32_e64 s1, 0x380, v0
	v_cmp_gt_u32_e64 s2, 0x300, v0
	v_cmp_gt_u32_e64 s5, 0x380, v2
	v_and_b32_e32 v2, 16, v67
	v_cmp_gt_u32_e64 s3, 0x280, v0
	v_cmp_gt_u32_e64 s4, 0x200, v0
	v_cmp_gt_u32_e64 s6, 0x100, v0
	v_cmp_gt_u32_e64 s7, 0x380, v3
	v_lshl_or_b32 v68, v1, 7, v9
	v_dual_add_nc_u32 v69, v8, v7 :: v_dual_add_nc_u32 v70, 16, v2
	v_xor_b32_e32 v71, 8, v67
	v_xor_b32_e32 v72, 4, v67
	v_xor_b32_e32 v73, 2, v67
	v_xor_b32_e32 v74, 1, v67
	s_cselect_b32 s21, -1, 0
	s_max_u32 s22, s20, 1
	s_bitset1_b32 s23, 10
	s_mov_b32 s24, -1
	s_branch .LBB0_3
.LBB0_2:                                ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	s_mov_b32 s25, 1
	s_and_not1_b32 vcc_lo, exec_lo, s24
	s_mov_b32 s24, 0
	s_wait_storecnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccz .LBB0_36
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_13 Depth 2
                                        ;       Child Loop BB0_15 Depth 3
	global_load_u16 v2, v[42:43], off
	global_load_u16 v3, v[44:45], off
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3
	s_and_saveexec_b32 s26, s1
	s_cbranch_execz .LBB0_11
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:256
	global_load_u16 v3, v[44:45], off offset:256
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:256
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:256
	s_and_b32 exec_lo, exec_lo, s2
	s_cbranch_execz .LBB0_11
; %bb.5:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:512
	global_load_u16 v3, v[44:45], off offset:512
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:512
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:512
	s_and_b32 exec_lo, exec_lo, s3
	s_cbranch_execz .LBB0_11
; %bb.6:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:768
	global_load_u16 v3, v[44:45], off offset:768
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:768
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:768
	s_and_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB0_11
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:1024
	global_load_u16 v3, v[44:45], off offset:1024
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:1024
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:1024
	s_and_b32 exec_lo, exec_lo, s5
	s_cbranch_execz .LBB0_11
; %bb.8:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:1280
	global_load_u16 v3, v[44:45], off offset:1280
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:1280
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:1280
	s_and_b32 exec_lo, exec_lo, s6
	s_cbranch_execz .LBB0_11
; %bb.9:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:1536
	global_load_u16 v3, v[44:45], off offset:1536
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:1536
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:1536
	s_and_b32 exec_lo, exec_lo, s7
	s_cbranch_execz .LBB0_11
; %bb.10:                               ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[42:43], off offset:1792
	global_load_u16 v3, v[44:45], off offset:1792
	s_wait_loadcnt 0x1
	ds_store_b16 v56, v2 offset:1792
	s_wait_loadcnt 0x0
	ds_store_b16 v66, v3 offset:1792
.LBB0_11:                               ;   in Loop: Header=BB0_3 Depth=1
	s_or_b32 exec_lo, exec_lo, s26
	s_or_b32 s25, s25, s18
	s_and_not1_b32 vcc_lo, exec_lo, s21
	v_lshl_or_b32 v75, s25, 6, v57
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccnz .LBB0_19
; %bb.12:                               ;   in Loop: Header=BB0_3 Depth=1
	v_cmp_lt_i32_e32 vcc_lo, v71, v70
	v_dual_mov_b32 v82, 0 :: v_dual_mov_b32 v83, 0
	v_dual_mov_b32 v84, 0 :: v_dual_mov_b32 v85, 0
	v_cndmask_b32_e32 v4, v67, v71, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v72, v70
	v_add_nc_u32_e32 v2, v65, v75
	s_mov_b32 s27, 0
	s_mov_b32 s25, s23
	v_dual_mov_b32 v3, v6 :: v_dual_cndmask_b32 v5, v67, v72, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v73, v70
	v_lshl_or_b32 v2, v2, 6, v58
	s_delay_alu instid0(VALU_DEP_3)
	v_lshlrev_b32_e32 v77, 2, v5
	v_cndmask_b32_e32 v7, v67, v73, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v74, v70
	v_dual_lshlrev_b32 v76, 2, v4 :: v_dual_mov_b32 v4, 0
	v_lshl_add_u64 v[54:55], v[2:3], 1, s[12:13]
	v_dual_mov_b32 v2, 0 :: v_dual_cndmask_b32 v8, v67, v74, vcc_lo
	v_dual_mov_b32 v3, 0 :: v_dual_lshlrev_b32 v78, 2, v7
	v_dual_mov_b32 v5, 0 :: v_dual_mov_b32 v52, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_mov_b32 v53, v4 :: v_dual_lshlrev_b32 v79, 2, v8
	v_dual_mov_b32 v50, 0 :: v_dual_mov_b32 v51, v4
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v49, v4
	v_dual_mov_b32 v46, 0 :: v_dual_mov_b32 v47, v4
	v_dual_mov_b32 v34, 0 :: v_dual_mov_b32 v35, v4
	v_dual_mov_b32 v36, v4 :: v_dual_mov_b32 v37, v4
	v_dual_mov_b32 v38, v4 :: v_dual_mov_b32 v39, v4
	v_dual_mov_b32 v40, v4 :: v_dual_mov_b32 v41, v4
	v_dual_mov_b32 v26, 0 :: v_dual_mov_b32 v27, v4
	v_dual_mov_b32 v28, v4 :: v_dual_mov_b32 v29, v4
	v_dual_mov_b32 v30, v4 :: v_dual_mov_b32 v31, v4
	v_dual_mov_b32 v32, v4 :: v_dual_mov_b32 v33, v4
	v_dual_mov_b32 v18, 0 :: v_dual_mov_b32 v19, v4
	v_dual_mov_b32 v20, v4 :: v_dual_mov_b32 v21, v4
	v_dual_mov_b32 v22, v4 :: v_dual_mov_b32 v23, v4
	v_dual_mov_b32 v24, v4 :: v_dual_mov_b32 v25, v4
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, v4
	v_dual_mov_b32 v12, v4 :: v_dual_mov_b32 v13, v4
	v_dual_mov_b32 v14, v4 :: v_dual_mov_b32 v15, v4
	v_dual_mov_b32 v16, v4 :: v_dual_mov_b32 v17, v4
.LBB0_13:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_15 Depth 3
	s_add_co_i32 s26, s27, 1
	s_and_b32 s28, s27, 1
	s_cmp_ge_u32 s26, s20
	s_cbranch_scc1 .LBB0_17
; %bb.14:                               ;   in Loop: Header=BB0_13 Depth=2
	s_lshl_b32 s29, s28, 11
	v_mov_b32_e32 v8, v0
	v_bitop3_b32 v7, v56, s29, 0x800 bitop3:0xf6
	s_mov_b32 s29, 0
.LBB0_15:                               ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_13 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v9, s25, v8
	v_cmp_lt_u32_e32 vcc_lo, 0x37f, v8
	s_clause 0x1
	global_load_u16 v80, v9, s[14:15] scale_offset
	global_load_u16 v81, v9, s[16:17] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v9, 0x80, v8
	s_or_b32 s29, vcc_lo, s29
	s_wait_loadcnt 0x1
	ds_store_b16 v7, v80
	s_wait_loadcnt 0x0
	ds_store_b16 v7, v81 offset:4096
	v_dual_mov_b32 v8, v9 :: v_dual_add_nc_u32 v7, 0x100, v7
	s_and_not1_b32 exec_lo, exec_lo, s29
	s_cbranch_execnz .LBB0_15
; %bb.16:                               ;   in Loop: Header=BB0_13 Depth=2
	s_or_b32 exec_lo, exec_lo, s29
.LBB0_17:                               ;   in Loop: Header=BB0_13 Depth=2
	s_clause 0x3
	global_load_b128 v[86:89], v[54:55], off
	global_load_b128 v[90:93], v[54:55], off offset:32
	global_load_b128 v[94:97], v[54:55], off offset:64
	global_load_b128 v[98:101], v[54:55], off offset:96
	s_lshl_b32 s28, s28, 11
	s_cmp_eq_u32 s27, 0
	v_or_b32_e32 v7, s28, v68
	s_cselect_b32 vcc_lo, -1, 0
	s_addk_co_i32 s25, 0x400
	s_cmp_eq_u32 s26, s22
	ds_load_b128 v[102:105], v7
	ds_load_b128 v[106:109], v7 offset:32
	s_wait_loadcnt_dscnt 0x200
	v_wmma_f32_16x16x32_f16 v[110:117], v[86:93], v[102:109], 0
	ds_load_b128 v[86:89], v7 offset:64
	ds_load_b128 v[90:93], v7 offset:96
	v_nop
	v_nop
	v_nop
	v_nop
	v_add_nc_u32_e32 v108, s28, v60
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v118, v108, v59
	s_wait_loadcnt_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[110:117], v[94:101], v[86:93], v[110:117]
	v_dual_max_num_f32 v97, v4, v4 :: v_dual_max_num_f32 v100, v5, v5
	v_nop
	v_nop
	v_nop
	v_max_num_f32_e32 v101, v82, v82
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_dual_mul_f32 v7, 0x3e000000, v110 :: v_dual_mul_f32 v8, 0x3e000000, v111
	v_dual_mul_f32 v9, 0x3e000000, v112 :: v_dual_mul_f32 v80, 0x3e000000, v113
	v_dual_mul_f32 v81, 0x3e000000, v114 :: v_dual_mul_f32 v86, 0x3e000000, v115
	v_dual_mul_f32 v87, 0x3e000000, v116 :: v_dual_mul_f32 v88, 0x3e000000, v117
	ds_bpermute_b32 v89, v76, v7
	ds_bpermute_b32 v90, v76, v8
	ds_bpermute_b32 v91, v76, v9
	ds_bpermute_b32 v92, v76, v80
	ds_bpermute_b32 v93, v76, v81
	ds_bpermute_b32 v96, v76, v88
	ds_bpermute_b32 v94, v76, v86
	ds_bpermute_b32 v95, v76, v87
	s_wait_dscnt 0x6
	v_dual_max_num_f32 v89, v89, v89 :: v_dual_max_num_f32 v90, v90, v90
	s_wait_dscnt 0x4
	v_dual_max_num_f32 v91, v91, v91 :: v_dual_max_num_f32 v92, v92, v92
	s_wait_dscnt 0x2
	v_dual_max_num_f32 v93, v93, v93 :: v_dual_max_num_f32 v96, v96, v96
	v_dual_max_num_f32 v7, v7, v89 :: v_dual_max_num_f32 v8, v8, v90
	s_wait_dscnt 0x1
	v_dual_max_num_f32 v9, v9, v91 :: v_dual_max_num_f32 v94, v94, v94
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v95, v95, v95 :: v_dual_max_num_f32 v80, v80, v92
	v_max_num_f32_e32 v81, v81, v93
	ds_bpermute_b32 v89, v77, v7
	ds_bpermute_b32 v90, v77, v8
	v_dual_max_num_f32 v86, v86, v94 :: v_dual_max_num_f32 v87, v87, v95
	ds_bpermute_b32 v91, v77, v9
	ds_bpermute_b32 v92, v77, v80
	ds_bpermute_b32 v93, v77, v81
	ds_bpermute_b32 v94, v77, v86
	v_max_num_f32_e32 v88, v88, v96
	ds_bpermute_b32 v95, v77, v87
	s_wait_dscnt 0x6
	v_max_num_f32_e32 v89, v89, v89
	ds_bpermute_b32 v96, v77, v88
	s_wait_dscnt 0x5
	v_dual_max_num_f32 v90, v90, v90 :: v_dual_max_num_f32 v91, v91, v91
	s_wait_dscnt 0x4
	v_dual_max_num_f32 v92, v92, v92 :: v_dual_max_num_f32 v7, v7, v89
	s_wait_dscnt 0x3
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_max_num_f32 v89, v93, v93 :: v_dual_max_num_f32 v8, v8, v90
	s_wait_dscnt 0x2
	v_dual_max_num_f32 v90, v94, v94 :: v_dual_max_num_f32 v9, v9, v91
	s_wait_dscnt 0x1
	v_dual_max_num_f32 v93, v95, v95 :: v_dual_max_num_f32 v80, v80, v92
	ds_bpermute_b32 v94, v78, v8
	ds_bpermute_b32 v91, v78, v7
	ds_bpermute_b32 v92, v78, v9
	v_dual_max_num_f32 v81, v81, v89 :: v_dual_max_num_f32 v86, v86, v90
	v_max_num_f32_e32 v87, v87, v93
	ds_bpermute_b32 v89, v78, v80
	s_wait_dscnt 0x4
	v_dual_max_num_f32 v98, v2, v2 :: v_dual_max_num_f32 v95, v96, v96
	ds_bpermute_b32 v90, v78, v81
	ds_bpermute_b32 v93, v78, v86
	v_max_num_f32_e32 v88, v88, v95
	ds_bpermute_b32 v95, v78, v87
	s_wait_dscnt 0x6
	v_max_num_f32_e32 v94, v94, v94
	ds_bpermute_b32 v96, v78, v88
	s_wait_dscnt 0x5
	v_dual_max_num_f32 v91, v91, v91 :: v_dual_max_num_f32 v92, v92, v92
	s_wait_dscnt 0x4
	v_dual_max_num_f32 v8, v8, v94 :: v_dual_max_num_f32 v89, v89, v89
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_max_num_f32_e32 v7, v7, v91
	v_dual_max_num_f32 v91, v3, v3 :: v_dual_max_num_f32 v9, v9, v92
	s_wait_dscnt 0x2
	v_dual_max_num_f32 v90, v90, v90 :: v_dual_max_num_f32 v93, v93, v93
	ds_bpermute_b32 v92, v79, v7
	ds_bpermute_b32 v94, v79, v8
	s_wait_dscnt 0x3
	v_dual_max_num_f32 v95, v95, v95 :: v_dual_max_num_f32 v80, v80, v89
	ds_bpermute_b32 v99, v79, v9
	v_dual_max_num_f32 v81, v81, v90 :: v_dual_max_num_f32 v102, v83, v83
	v_max_num_f32_e32 v87, v87, v95
	ds_bpermute_b32 v89, v79, v80
	s_wait_dscnt 0x4
	v_dual_max_num_f32 v96, v96, v96 :: v_dual_max_num_f32 v86, v86, v93
	ds_bpermute_b32 v90, v79, v81
	ds_bpermute_b32 v95, v79, v87
	v_max_num_f32_e32 v103, v84, v84
	v_max_num_f32_e32 v88, v88, v96
	ds_bpermute_b32 v93, v79, v86
	ds_bpermute_b32 v96, v79, v88
	s_wait_dscnt 0x6
	v_dual_max_num_f32 v92, v92, v92 :: v_dual_max_num_f32 v94, v94, v94
	s_wait_dscnt 0x5
	v_max_num_f32_e32 v99, v99, v99
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_max_num_f32 v7, v7, v92 :: v_dual_max_num_f32 v8, v8, v94
	v_max_num_f32_e32 v92, v85, v85
	s_wait_dscnt 0x4
	v_max_num_f32_e32 v89, v89, v89
	s_wait_dscnt 0x3
	v_dual_max_num_f32 v9, v9, v99 :: v_dual_max_num_f32 v90, v90, v90
	s_wait_dscnt 0x2
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_max_num_f32 v94, v95, v95 :: v_dual_max_num_f32 v80, v80, v89
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v93, v93, v93
	v_dual_max_num_f32 v81, v81, v90 :: v_dual_max_num_f32 v89, v91, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v95, v96, v96
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_dual_max_num_f32 v86, v86, v93 :: v_dual_add_nc_u32 v119, v108, v62
	v_dual_max_num_f32 v93, v87, v94 :: v_dual_max_num_f32 v87, v97, v7
	v_dual_max_num_f32 v94, v88, v95 :: v_dual_max_num_f32 v88, v98, v8
	v_dual_max_num_f32 v95, v100, v80 :: v_dual_max_num_f32 v96, v101, v81
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_max_num_f32 v97, v102, v86 :: v_dual_max_num_f32 v98, v103, v93
	v_dual_max_num_f32 v92, v92, v94 :: v_dual_cndmask_b32 v91, v87, v7
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_cndmask_b32 v90, v88, v8 :: v_dual_cndmask_b32 v89, v89, v9
	v_dual_cndmask_b32 v88, v95, v80 :: v_dual_cndmask_b32 v87, v96, v81
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_cndmask_b32 v86, v97, v86 :: v_dual_cndmask_b32 v81, v98, v93
	v_cndmask_b32_e32 v80, v92, v94, vcc_lo
	v_fma_f32 v7, 0x3e000000, v110, -v91
	v_fma_f32 v8, 0x3e000000, v111, -v90
	v_fma_f32 v9, 0x3e000000, v112, -v89
	v_fma_f32 v92, 0x3e000000, v113, -v88
	v_fma_f32 v93, 0x3e000000, v114, -v87
	v_fma_f32 v94, 0x3e000000, v115, -v86
	v_fma_f32 v95, 0x3e000000, v116, -v81
	v_fma_f32 v96, 0x3e000000, v117, -v80
	v_dual_mul_f32 v7, 0x3fb8aa3b, v7 :: v_dual_mul_f32 v8, 0x3fb8aa3b, v8
	v_dual_mul_f32 v9, 0x3fb8aa3b, v9 :: v_dual_mul_f32 v92, 0x3fb8aa3b, v92
	v_dual_mul_f32 v93, 0x3fb8aa3b, v93 :: v_dual_mul_f32 v94, 0x3fb8aa3b, v94
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_mul_f32 v95, 0x3fb8aa3b, v95 :: v_dual_mul_f32 v96, 0x3fb8aa3b, v96
	v_exp_f32_e32 v100, v7
	v_exp_f32_e32 v101, v8
	v_exp_f32_e32 v102, v9
	v_exp_f32_e32 v103, v92
	v_exp_f32_e32 v104, v93
	v_exp_f32_e32 v105, v94
	v_exp_f32_e32 v106, v95
	v_exp_f32_e32 v107, v96
	v_cvt_f16_f32_e32 v7, v100
	v_cvt_f16_f32_e32 v8, v101
	v_cvt_f16_f32_e32 v9, v102
	v_cvt_f16_f32_e32 v92, v103
	v_cvt_f16_f32_e32 v93, v104
	v_cvt_f16_f32_e32 v94, v105
	v_cvt_f16_f32_e32 v95, v106
	v_cvt_f16_f32_e32 v96, v107
	ds_store_b16 v69, v7
	ds_store_b16 v69, v8 offset:32
	ds_store_b16 v69, v9 offset:64
	ds_store_b16 v69, v92 offset:96
	ds_store_b16 v69, v93 offset:128
	ds_store_b16 v69, v94 offset:160
	ds_store_b16 v69, v95 offset:192
	ds_store_b16 v69, v96 offset:224
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	ds_load_u16 v92, v118 offset:128
	ds_load_u16 v93, v118
	ds_load_u16 v94, v118 offset:384
	ds_load_u16 v95, v119
	v_dual_add_nc_u32 v114, v108, v63 :: v_dual_add_nc_u32 v115, v108, v64
	ds_load_u16 v99, v118 offset:640
	ds_load_u16 v112, v118 offset:896
	v_dual_sub_f32 v4, v4, v91 :: v_dual_sub_f32 v2, v2, v90
	ds_load_u16 v113, v115
	v_dual_sub_f32 v82, v82, v87 :: v_dual_sub_f32 v83, v83, v86
	v_dual_sub_f32 v84, v84, v81 :: v_dual_sub_f32 v85, v85, v80
	v_dual_sub_f32 v3, v3, v89 :: v_dual_sub_f32 v5, v5, v88
	v_mul_f32_e32 v4, 0x3fb8aa3b, v4
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_dual_mul_f32 v82, 0x3fb8aa3b, v82 :: v_dual_mul_f32 v83, 0x3fb8aa3b, v83
	s_wait_dscnt 0x5
	v_perm_b32 v92, v92, v93, 0x5040100
	v_dual_mul_f32 v84, 0x3fb8aa3b, v84 :: v_dual_mul_f32 v85, 0x3fb8aa3b, v85
	s_wait_dscnt 0x3
	v_perm_b32 v93, v94, v95, 0x5040100
	ds_load_u16 v94, v114
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_mul_f32_e32 v5, 0x3fb8aa3b, v5
	v_exp_f32_e32 v95, v4
	v_exp_f32_e32 v108, v2
	v_exp_f32_e32 v110, v82
	v_exp_f32_e32 v116, v84
	v_exp_f32_e32 v109, v3
	v_exp_f32_e32 v111, v83
	v_exp_f32_e32 v117, v85
	v_cndmask_b32_e64 v82, v95, 0, vcc_lo
	v_cndmask_b32_e64 v83, v108, 0, vcc_lo
	v_cndmask_b32_e64 v108, v110, 0, vcc_lo
	v_cndmask_b32_e64 v110, v116, 0, vcc_lo
	v_cndmask_b32_e64 v84, v109, 0, vcc_lo
	v_cndmask_b32_e64 v109, v111, 0, vcc_lo
	v_cndmask_b32_e64 v111, v117, 0, vcc_lo
	v_dual_mov_b32 v7, v6 :: v_dual_mov_b32 v8, v6
	v_dual_mov_b32 v9, v6 :: v_dual_mov_b32 v96, v6
	s_wait_dscnt 0x0
	v_perm_b32 v94, v99, v94, 0x5040100
	v_exp_f32_e32 v99, v5
	ds_load_b128 v[2:5], v61
	v_perm_b32 v95, v112, v113, 0x5040100
	ds_load_u16 v112, v118 offset:32
	ds_load_u16 v113, v119 offset:32
	ds_load_u16 v116, v118 offset:160
	v_dual_mov_b32 v97, v6 :: v_dual_mov_b32 v98, v6
	v_pk_mul_f32 v[34:35], v[34:35], v[82:83]
	v_cndmask_b32_e64 v85, v99, 0, vcc_lo
	v_mov_b32_e32 v99, v6
	v_pk_mul_f32 v[38:39], v[38:39], v[108:109]
	v_pk_mul_f32 v[40:41], v[40:41], v[110:111]
	v_pk_mul_f32 v[26:27], v[26:27], v[82:83]
	v_pk_mul_f32 v[36:37], v[36:37], v[84:85]
	s_wait_dscnt 0x3
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[34:41], v[2:9], v[92:99], v[34:41]
	ds_load_u16 v93, v118 offset:416
	ds_load_u16 v94, v114 offset:32
	s_wait_dscnt 0x2
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v116, v112, 0x5040100
	ds_load_u16 v95, v118 offset:672
	ds_load_u16 v112, v115 offset:32
	v_pk_mul_f32 v[28:29], v[28:29], v[84:85]
	v_pk_mul_f32 v[30:31], v[30:31], v[108:109]
	v_pk_mul_f32 v[32:33], v[32:33], v[110:111]
	v_pk_mul_f32 v[18:19], v[18:19], v[82:83]
	v_pk_mul_f32 v[20:21], v[20:21], v[84:85]
	v_pk_mul_f32 v[22:23], v[22:23], v[108:109]
	v_pk_mul_f32 v[24:25], v[24:25], v[110:111]
	v_pk_mul_f32 v[10:11], v[10:11], v[82:83]
	v_pk_mul_f32 v[12:13], v[12:13], v[84:85]
	v_pk_mul_f32 v[14:15], v[14:15], v[108:109]
	v_pk_mul_f32 v[16:17], v[16:17], v[110:111]
	s_wait_dscnt 0x3
	v_perm_b32 v93, v93, v113, 0x5040100
	s_wait_dscnt 0x1
	v_perm_b32 v94, v95, v94, 0x5040100
	ds_load_u16 v95, v118 offset:928
	s_wait_dscnt 0x0
	v_perm_b32 v95, v95, v112, 0x5040100
	ds_load_u16 v112, v118 offset:64
	ds_load_u16 v113, v118 offset:192
	ds_load_u16 v116, v119 offset:64
	v_wmma_f32_16x16x32_f16 v[26:33], v[2:9], v[92:99], v[26:33]
	ds_load_u16 v93, v118 offset:448
	ds_load_u16 v94, v114 offset:64
	s_wait_dscnt 0x3
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v113, v112, 0x5040100
	ds_load_u16 v95, v118 offset:704
	ds_load_u16 v112, v115 offset:64
	ds_bpermute_b32 v113, v76, v101
	s_wait_dscnt 0x4
	v_perm_b32 v93, v93, v116, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v94, v95, v94, 0x5040100
	ds_load_u16 v95, v118 offset:960
	ds_load_u16 v116, v118 offset:96
	ds_load_u16 v117, v118 offset:224
	ds_load_u16 v119, v119 offset:96
	ds_load_u16 v120, v118 offset:480
	ds_load_u16 v114, v114 offset:96
	s_wait_dscnt 0x5
	v_perm_b32 v95, v95, v112, 0x5040100
	ds_bpermute_b32 v112, v76, v100
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[92:99], v[18:25]
	ds_bpermute_b32 v92, v76, v102
	ds_bpermute_b32 v93, v76, v103
	ds_bpermute_b32 v94, v76, v104
	ds_bpermute_b32 v95, v76, v105
	ds_bpermute_b32 v96, v76, v106
	ds_bpermute_b32 v97, v76, v107
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_pk_add_f32 v[98:99], v[100:101], v[112:113]
	ds_load_u16 v112, v118 offset:736
	s_wait_dscnt 0x5
	v_pk_add_f32 v[100:101], v[102:103], v[92:93]
	v_perm_b32 v92, v117, v116, 0x5040100
	s_wait_dscnt 0x3
	v_pk_add_f32 v[102:103], v[104:105], v[94:95]
	ds_bpermute_b32 v104, v77, v98
	ds_bpermute_b32 v105, v77, v99
	s_wait_dscnt 0x3
	v_pk_add_f32 v[96:97], v[106:107], v[96:97]
	ds_bpermute_b32 v106, v77, v100
	ds_bpermute_b32 v107, v77, v101
	ds_load_u16 v95, v115 offset:96
	v_perm_b32 v93, v120, v119, 0x5040100
	s_wait_dscnt 0x5
	v_perm_b32 v94, v112, v114, 0x5040100
	ds_load_u16 v112, v118 offset:992
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_pk_add_f32 v[98:99], v[98:99], v[104:105]
	ds_bpermute_b32 v104, v77, v96
	ds_bpermute_b32 v105, v77, v97
	v_pk_add_f32 v[100:101], v[100:101], v[106:107]
	ds_bpermute_b32 v106, v77, v102
	ds_bpermute_b32 v107, v77, v103
	v_perm_b32 v95, v112, v95, 0x5040100
	s_wait_dscnt 0x2
	v_pk_add_f32 v[96:97], v[96:97], v[104:105]
	ds_bpermute_b32 v104, v78, v98
	ds_bpermute_b32 v105, v78, v99
	s_wait_dscnt 0x2
	v_pk_add_f32 v[102:103], v[102:103], v[106:107]
	ds_bpermute_b32 v106, v78, v96
	ds_bpermute_b32 v107, v78, v97
	s_wait_dscnt 0x2
	v_pk_add_f32 v[104:105], v[98:99], v[104:105]
	ds_bpermute_b32 v98, v78, v100
	ds_bpermute_b32 v99, v78, v101
	s_wait_dscnt 0x2
	v_pk_add_f32 v[96:97], v[96:97], v[106:107]
	ds_bpermute_b32 v106, v78, v102
	ds_bpermute_b32 v107, v78, v103
	s_wait_dscnt 0x2
	v_pk_add_f32 v[100:101], v[100:101], v[98:99]
	ds_bpermute_b32 v98, v79, v96
	ds_bpermute_b32 v99, v79, v97
	s_wait_dscnt 0x2
	v_pk_add_f32 v[102:103], v[102:103], v[106:107]
	ds_bpermute_b32 v106, v79, v104
	ds_bpermute_b32 v112, v79, v100
	ds_bpermute_b32 v113, v79, v101
	ds_bpermute_b32 v107, v79, v105
	ds_bpermute_b32 v116, v79, v102
	ds_bpermute_b32 v117, v79, v103
	s_wait_dscnt 0x6
	v_pk_add_f32 v[114:115], v[96:97], v[98:99]
	v_dual_mov_b32 v96, v6 :: v_dual_mov_b32 v97, v6
	v_dual_mov_b32 v98, v6 :: v_dual_mov_b32 v99, v6
	s_wait_dscnt 0x3
	v_pk_add_f32 v[100:101], v[100:101], v[112:113]
	s_wait_dscnt 0x2
	v_pk_add_f32 v[104:105], v[104:105], v[106:107]
	v_wmma_f32_16x16x32_f16 v[10:17], v[2:9], v[92:99], v[10:17]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[102:103], v[102:103], v[116:117]
	v_pk_fma_f32 v[46:47], v[46:47], v[110:111], v[114:115]
	v_pk_fma_f32 v[50:51], v[50:51], v[84:85], v[100:101]
	v_pk_fma_f32 v[52:53], v[52:53], v[82:83], v[104:105]
	s_delay_alu instid0(VALU_DEP_4)
	v_pk_fma_f32 v[48:49], v[48:49], v[108:109], v[102:103]
	s_cbranch_scc1 .LBB0_20
; %bb.18:                               ;   in Loop: Header=BB0_13 Depth=2
	v_dual_mov_b32 v4, v91 :: v_dual_mov_b32 v2, v90
	v_dual_mov_b32 v3, v89 :: v_dual_mov_b32 v5, v88
	v_dual_mov_b32 v82, v87 :: v_dual_mov_b32 v83, v86
	v_dual_mov_b32 v84, v81 :: v_dual_mov_b32 v85, v80
	s_mov_b32 s27, s26
	s_branch .LBB0_13
.LBB0_19:                               ;   in Loop: Header=BB0_3 Depth=1
	v_dual_mov_b32 v80, 0 :: v_dual_mov_b32 v81, 0
	v_dual_mov_b32 v86, 0 :: v_dual_mov_b32 v87, 0
	v_dual_mov_b32 v88, 0 :: v_dual_mov_b32 v89, 0
	v_dual_mov_b32 v90, 0 :: v_dual_mov_b32 v91, 0
	s_delay_alu instid0(VALU_DEP_4)
	v_dual_mov_b32 v47, 0 :: v_dual_mov_b32 v46, v80
	v_dual_mov_b32 v49, 0 :: v_dual_mov_b32 v48, v80
	v_dual_mov_b32 v51, 0 :: v_dual_mov_b32 v50, v80
	v_dual_mov_b32 v53, 0 :: v_dual_mov_b32 v52, v80
	v_dual_mov_b32 v17, 0 :: v_dual_mov_b32 v16, v80
	v_dual_mov_b32 v15, v80 :: v_dual_mov_b32 v14, v80
	v_dual_mov_b32 v13, v80 :: v_dual_mov_b32 v12, v80
	v_dual_mov_b32 v11, v80 :: v_dual_mov_b32 v10, v80
	v_dual_mov_b32 v25, 0 :: v_dual_mov_b32 v24, v80
	v_dual_mov_b32 v23, v80 :: v_dual_mov_b32 v22, v80
	v_dual_mov_b32 v21, v80 :: v_dual_mov_b32 v20, v80
	v_dual_mov_b32 v19, v80 :: v_dual_mov_b32 v18, v80
	v_dual_mov_b32 v33, 0 :: v_dual_mov_b32 v32, v80
	v_dual_mov_b32 v31, v80 :: v_dual_mov_b32 v30, v80
	v_dual_mov_b32 v29, v80 :: v_dual_mov_b32 v28, v80
	v_dual_mov_b32 v27, v80 :: v_dual_mov_b32 v26, v80
	v_dual_mov_b32 v41, 0 :: v_dual_mov_b32 v40, v80
	v_dual_mov_b32 v39, v80 :: v_dual_mov_b32 v38, v80
	v_dual_mov_b32 v37, v80 :: v_dual_mov_b32 v36, v80
	v_dual_mov_b32 v35, v80 :: v_dual_mov_b32 v34, v80
.LBB0_20:                               ;   in Loop: Header=BB0_3 Depth=1
	v_or_b32_e32 v2, v75, v58
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v4, v52
	s_xor_b32 s24, s24, -1
	v_add_nc_u32_e32 v3, s19, v2
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_fma_mixlo_f16 v5, v34, v4, 0
	v_fma_mixlo_f16 v8, v26, v4, 0
	v_lshl_or_b32 v7, v3, 6, v1
	v_fma_mixlo_f16 v9, v18, v4, 0
	v_fma_mixlo_f16 v4, v10, v4, 0
	s_clause 0x3
	global_store_b16 v7, v5, s[8:9] scale_offset
	global_store_b16 v7, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v7, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v7, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_22
; %bb.21:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v52
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v91, 0x3f317218, v4
	global_store_b32 v3, v91, s[10:11] scale_offset
.LBB0_22:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v53
	v_add3_u32 v3, s19, v2, 1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v5, v3, 6, v1
	v_fma_mixlo_f16 v7, v35, v4, 0
	v_fma_mixlo_f16 v8, v27, v4, 0
	v_fma_mixlo_f16 v9, v19, v4, 0
	v_fma_mixlo_f16 v4, v11, v4, 0
	s_clause 0x3
	global_store_b16 v5, v7, s[8:9] scale_offset
	global_store_b16 v5, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v5, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v5, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_24
; %bb.23:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v53
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v90, 0x3f317218, v4
	global_store_b32 v3, v90, s[10:11] scale_offset
.LBB0_24:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v50
	v_add3_u32 v3, s19, v2, 2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v5, v3, 6, v1
	v_fma_mixlo_f16 v7, v36, v4, 0
	v_fma_mixlo_f16 v8, v28, v4, 0
	v_fma_mixlo_f16 v9, v20, v4, 0
	v_fma_mixlo_f16 v4, v12, v4, 0
	s_clause 0x3
	global_store_b16 v5, v7, s[8:9] scale_offset
	global_store_b16 v5, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v5, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v5, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_26
; %bb.25:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v50
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v89, 0x3f317218, v4
	global_store_b32 v3, v89, s[10:11] scale_offset
.LBB0_26:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v51
	v_add3_u32 v3, s19, v2, 3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v5, v3, 6, v1
	v_fma_mixlo_f16 v7, v37, v4, 0
	v_fma_mixlo_f16 v8, v29, v4, 0
	v_fma_mixlo_f16 v9, v21, v4, 0
	v_fma_mixlo_f16 v4, v13, v4, 0
	s_clause 0x3
	global_store_b16 v5, v7, s[8:9] scale_offset
	global_store_b16 v5, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v5, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v5, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_28
; %bb.27:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v51
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v88, 0x3f317218, v4
	global_store_b32 v3, v88, s[10:11] scale_offset
.LBB0_28:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v48
	v_add3_u32 v3, s19, v2, 4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v5, v3, 6, v1
	v_fma_mixlo_f16 v7, v38, v4, 0
	v_fma_mixlo_f16 v8, v30, v4, 0
	v_fma_mixlo_f16 v9, v22, v4, 0
	v_fma_mixlo_f16 v4, v14, v4, 0
	s_clause 0x3
	global_store_b16 v5, v7, s[8:9] scale_offset
	global_store_b16 v5, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v5, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v5, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_30
; %bb.29:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v48
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v87, 0x3f317218, v4
	global_store_b32 v3, v87, s[10:11] scale_offset
.LBB0_30:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v49
	v_add3_u32 v3, s19, v2, 5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v5, v3, 6, v1
	v_fma_mixlo_f16 v7, v39, v4, 0
	v_fma_mixlo_f16 v8, v31, v4, 0
	v_fma_mixlo_f16 v9, v23, v4, 0
	v_fma_mixlo_f16 v4, v15, v4, 0
	s_clause 0x3
	global_store_b16 v5, v7, s[8:9] scale_offset
	global_store_b16 v5, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v5, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v5, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_32
; %bb.31:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v49
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v86, 0x3f317218, v4
	global_store_b32 v3, v86, s[10:11] scale_offset
.LBB0_32:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v46
	v_add3_u32 v3, s19, v2, 6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v5, v3, 6, v1
	v_fma_mixlo_f16 v7, v40, v4, 0
	v_fma_mixlo_f16 v8, v32, v4, 0
	v_fma_mixlo_f16 v9, v24, v4, 0
	v_fma_mixlo_f16 v4, v16, v4, 0
	s_clause 0x3
	global_store_b16 v5, v7, s[8:9] scale_offset
	global_store_b16 v5, v8, s[8:9] offset:32 scale_offset
	global_store_b16 v5, v9, s[8:9] offset:64 scale_offset
	global_store_b16 v5, v4, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_34
; %bb.33:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v4, v46
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v81, 0x3f317218, v4
	global_store_b32 v3, v81, s[10:11] scale_offset
.LBB0_34:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v3, v47
	v_add3_u32 v2, s19, v2, 7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v4, v2, 6, v1
	v_fma_mixlo_f16 v5, v41, v3, 0
	v_fma_mixlo_f16 v7, v33, v3, 0
	v_fma_mixlo_f16 v8, v25, v3, 0
	v_fma_mixlo_f16 v3, v17, v3, 0
	s_clause 0x3
	global_store_b16 v4, v5, s[8:9] scale_offset
	global_store_b16 v4, v7, s[8:9] offset:32 scale_offset
	global_store_b16 v4, v8, s[8:9] offset:64 scale_offset
	global_store_b16 v4, v3, s[8:9] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s25, s0
	s_cbranch_execz .LBB0_2
; %bb.35:                               ;   in Loop: Header=BB0_3 Depth=1
	v_log_f32_e32 v3, v47
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v80, 0x3f317218, v3
	global_store_b32 v2, v80, s[10:11] scale_offset
	s_branch .LBB0_2
.LBB0_36:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel flash_attention_original
		.amdhsa_group_segment_fixed_size 10240
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 312
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
		.amdhsa_next_free_vgpr 121
		.amdhsa_next_free_sgpr 30
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 45
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
	.size	flash_attention_original, .Lfunc_end0-flash_attention_original
                                        ; -- End function
	.set flash_attention_original.num_vgpr, 121
	.set flash_attention_original.num_agpr, 0
	.set flash_attention_original.numbered_sgpr, 30
	.set flash_attention_original.num_named_barrier, 0
	.set flash_attention_original.private_seg_size, 0
	.set flash_attention_original.uses_vcc, 1
	.set flash_attention_original.uses_flat_scratch, 0
	.set flash_attention_original.has_dyn_sized_stack, 0
	.set flash_attention_original.has_recursion, 0
	.set flash_attention_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5752
; TotalNumSgprs: 32
; NumVgprs: 121
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 10240 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 32
; NumVGPRsForWavesPerEU: 121
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
	.protected	forgetting_attention_original ; -- Begin function forgetting_attention_original
	.globl	forgetting_attention_original
	.p2align	8
	.type	forgetting_attention_original,@function
forgetting_attention_original:          ; @forgetting_attention_original
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x40014
	s_load_b256 s[4:11], s[0:1], 0x0
	s_add_co_i32 s13, s2, 1
	s_wait_xcnt 0x0
	s_load_b128 s[0:3], s[0:1], 0x20
	s_bfe_u32 s15, ttmp6, 0x40010
	s_lshr_b32 s12, ttmp7, 16
	s_and_b32 s16, ttmp7, 0xffff
	s_add_co_i32 s15, s15, 1
	s_mul_i32 s13, s12, s13
	s_bfe_u32 s14, ttmp6, 0x40008
	s_mul_i32 s15, s16, s15
	s_bfe_u32 s17, ttmp6, 0x40004
	s_add_co_i32 s13, s14, s13
	s_getreg_b32 s14, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s17, s17, s15
	s_cmp_eq_u32 s14, 0
	v_lshl_or_b32 v67, v0, 1, 0x1000
	s_cselect_b32 s12, s12, s13
	s_cselect_b32 s13, s16, s17
	s_lshl_b32 s12, s12, 14
	s_lshl_b32 s13, s13, 10
	v_dual_mov_b32 v1, v67 :: v_dual_mov_b32 v2, v0
	s_add_co_i32 s12, s12, s13
	s_mov_b32 s15, 0
	s_lshl_b32 s13, s12, 6
.LBB1_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_add_nc_u32_e32 v3, s13, v2
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v2
	s_wait_kmcnt 0x0
	s_clause 0x1
	global_load_u16 v4, v3, s[6:7] scale_offset
	global_load_u16 v5, v3, s[8:9] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v3, 0x100, v2
	s_or_b32 s15, vcc_lo, s15
	s_wait_loadcnt 0x1
	ds_store_b16 v1, v4
	s_wait_loadcnt 0x0
	ds_store_b16 v1, v5 offset:4096
	v_dual_mov_b32 v2, v3 :: v_dual_add_nc_u32 v1, 0x200, v1
	s_and_not1_b32 exec_lo, exec_lo, s15
	s_cbranch_execnz .LBB1_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s15
	s_bfe_u32 s15, ttmp6, 0x4000c
	s_and_b32 s16, ttmp6, 15
	s_add_co_i32 s15, s15, 1
	v_dual_lshrrev_b32 v2, 5, v0 :: v_dual_bitop2_b32 v66, 15, v0 bitop3:0x40
	s_mul_i32 s15, ttmp9, s15
	v_mbcnt_lo_u32_b32 v1, -1, 0
	s_add_co_i32 s16, s16, s15
	s_cmp_eq_u32 s14, 0
	v_dual_lshrrev_b32 v4, 1, v0 :: v_dual_bitop2_b32 v69, s12, v66 bitop3:0x54
	s_cselect_b32 s14, ttmp9, s16
	v_dual_lshlrev_b32 v10, 9, v2 :: v_dual_bitop2_b32 v7, 4, v1 bitop3:0x14
	s_lshl_b32 s14, s14, 7
	v_xor_b32_e32 v8, 2, v1
	v_lshl_or_b32 v68, v2, 4, s14
	v_and_b32_e32 v3, 16, v1
	v_or_b32_e32 v78, 0xffffff00, v0
	v_dual_mov_b32 v37, 0 :: v_dual_mov_b32 v61, 0
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_add_nc_u32 v6, v69, v68 :: v_dual_bitop2_b32 v5, 8, v1 bitop3:0x14
	v_dual_mov_b32 v34, 0 :: v_dual_add_nc_u32 v3, 16, v3
	v_dual_mov_b32 v60, 0 :: v_dual_mov_b32 v32, 0
	v_mov_b32_e32 v35, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_cmp_lt_i32_e32 vcc_lo, v5, v3
	v_dual_lshlrev_b32 v4, 7, v66 :: v_dual_bitop2_b32 v70, 8, v4 bitop3:0x40
	v_dual_mov_b32 v33, 0 :: v_dual_mov_b32 v58, 0
	v_cndmask_b32_e32 v2, v1, v5, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v7, v3
	v_dual_mov_b32 v36, 0 :: v_dual_bitop2_b32 v9, 1, v1 bitop3:0x14
	s_mov_b32 s14, 0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_dual_lshlrev_b32 v71, 2, v2 :: v_dual_cndmask_b32 v5, v1, v7, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v8, v3
	v_lshl_or_b32 v2, v6, 6, v70
	v_dual_lshlrev_b32 v6, 5, v70 :: v_dual_mov_b32 v46, 0
	v_dual_lshlrev_b32 v72, 2, v5 :: v_dual_cndmask_b32 v8, v1, v8, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v9, v3
	v_dual_lshlrev_b32 v7, 5, v0 :: v_dual_lshlrev_b32 v5, 1, v70
	v_dual_mov_b32 v27, v36 :: v_dual_lshlrev_b32 v80, 7, v70
	v_dual_cndmask_b32 v1, v1, v9, vcc_lo :: v_dual_lshlrev_b32 v9, 1, v66
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_and_b32_e32 v7, 0x1e0, v7
	v_dual_lshlrev_b32 v73, 2, v8 :: v_dual_mov_b32 v3, v36
	v_lshlrev_b32_e32 v74, 2, v1
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_or_b32_e32 v1, v10, v9
	v_or3_b32 v75, v10, v7, v5
	v_or_b32_e32 v76, 0x2000, v9
	v_lshl_add_u64 v[54:55], v[2:3], 1, s[4:5]
	v_or3_b32 v77, v4, v5, 0x1000
	v_dual_add_nc_u32 v79, v1, v6 :: v_dual_mov_b32 v47, v36
	v_dual_mov_b32 v52, 0 :: v_dual_mov_b32 v53, v36
	v_dual_mov_b32 v50, 0 :: v_dual_mov_b32 v51, v36
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v49, v36
	v_dual_mov_b32 v0, v36 :: v_dual_mov_b32 v1, v36
	v_dual_mov_b32 v2, v36 :: v_dual_mov_b32 v4, v36
	v_dual_mov_b32 v5, v36 :: v_dual_mov_b32 v6, v36
	v_dual_mov_b32 v7, v36 :: v_dual_mov_b32 v8, v36
	v_dual_mov_b32 v9, v36 :: v_dual_mov_b32 v10, v36
	v_dual_mov_b32 v11, v36 :: v_dual_mov_b32 v12, v36
	v_dual_mov_b32 v13, v36 :: v_dual_mov_b32 v14, v36
	v_dual_mov_b32 v15, v36 :: v_dual_mov_b32 v16, v36
	v_dual_mov_b32 v17, v36 :: v_dual_mov_b32 v18, v36
	v_dual_mov_b32 v19, v36 :: v_dual_mov_b32 v20, v36
	v_dual_mov_b32 v21, v36 :: v_dual_mov_b32 v22, v36
	v_dual_mov_b32 v23, v36 :: v_dual_mov_b32 v24, v36
	v_dual_mov_b32 v25, v36 :: v_dual_mov_b32 v26, v36
	v_dual_mov_b32 v28, v36 :: v_dual_mov_b32 v29, v36
	v_dual_mov_b32 v30, v36 :: v_dual_mov_b32 v31, v36
	v_or_b32_e32 v81, 0x100, v80
	v_or_b32_e32 v82, 0x200, v80
	v_or_b32_e32 v83, 0x300, v80
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB1_4
.LBB1_3:                                ;   in Loop: Header=BB1_4 Depth=1
	s_clause 0x1
	global_load_b128 v[84:87], v[54:55], off
	global_load_b128 v[88:91], v[54:55], off offset:32
	s_lshl_b32 s5, s4, 11
	s_add_co_i32 s4, s14, 1
	v_add_nc_u32_e32 v56, s5, v77
	s_cmp_eq_u32 s14, 0
	v_dual_mov_b32 v104, v36 :: v_dual_mov_b32 v105, v36
	ds_load_b128 v[92:95], v56
	ds_load_b128 v[96:99], v56 offset:32
	s_cselect_b32 vcc_lo, -1, 0
	v_dual_mov_b32 v106, v36 :: v_dual_mov_b32 v107, v36
	s_addk_co_i32 s13, 0x400
	s_cmp_eq_u32 s4, 64
	s_wait_loadcnt_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[38:45], v[84:91], v[92:99], 0
	ds_load_b128 v[84:87], v56 offset:64
	ds_load_b128 v[88:91], v56 offset:96
	v_lshl_add_u32 v56, s14, 4, v69
	s_clause 0x1
	global_load_b128 v[92:95], v[54:55], off offset:64
	global_load_b128 v[96:99], v[54:55], off offset:96
	s_mov_b32 s14, s4
	global_load_b32 v56, v56, s[10:11] scale_offset
	s_wait_loadcnt_dscnt 0x100
	v_wmma_f32_16x16x32_f16 v[38:45], v[92:99], v[84:91], v[38:45]
	s_wait_loadcnt 0x0
	v_mul_f32_e32 v59, 0xbfb8aa3b, v56
	v_nop
	v_nop
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instid1(VALU_DEP_4)
	v_fmamk_f32 v40, v40, 0x3e38aa3b, v59
	ds_bpermute_b32 v56, v71, v40
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	v_dual_fmamk_f32 v38, v38, 0x3e38aa3b, v59 :: v_dual_fmamk_f32 v41, v41, 0x3e38aa3b, v59
	v_dual_fmamk_f32 v39, v39, 0x3e38aa3b, v59 :: v_dual_fmamk_f32 v42, v42, 0x3e38aa3b, v59
	v_dual_fmamk_f32 v43, v43, 0x3e38aa3b, v59 :: v_dual_fmamk_f32 v62, v44, 0x3e38aa3b, v59
	v_fmac_f32_e32 v59, 0x3e38aa3b, v45
	ds_bpermute_b32 v44, v71, v38
	ds_bpermute_b32 v45, v71, v39
	ds_bpermute_b32 v63, v71, v41
	s_wait_dscnt 0x1
	v_dual_max_num_f32 v56, v40, v56 :: v_dual_max_num_f32 v45, v45, v45
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v44, v44, v44 :: v_dual_max_num_f32 v63, v63, v63
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_max_num_f32 v45, v39, v45 :: v_dual_max_num_f32 v44, v38, v44
	v_max_num_f32_e32 v63, v41, v63
	ds_bpermute_b32 v64, v72, v45
	ds_bpermute_b32 v57, v72, v44
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v57, v57, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v44, v44, v57
	ds_bpermute_b32 v57, v72, v56
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v64, v64, v64 :: v_dual_max_num_f32 v57, v57, v57
	v_max_num_f32_e32 v45, v45, v64
	ds_bpermute_b32 v64, v71, v42
	v_max_num_f32_e32 v56, v56, v57
	ds_bpermute_b32 v57, v72, v63
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v64, v64, v64 :: v_dual_max_num_f32 v57, v57, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v64, v42, v64 :: v_dual_max_num_f32 v57, v63, v57
	ds_bpermute_b32 v63, v72, v64
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v63, v63, v63
	v_max_num_f32_e32 v63, v64, v63
	ds_bpermute_b32 v64, v71, v43
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v64, v64, v64
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v64, v43, v64
	ds_bpermute_b32 v65, v72, v64
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v65, v65, v65
	v_max_num_f32_e32 v64, v64, v65
	ds_bpermute_b32 v65, v71, v62
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v65, v65, v65
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v62, v65
	ds_bpermute_b32 v84, v72, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v65, v65, v84
	ds_bpermute_b32 v84, v71, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v84, v59, v84
	ds_bpermute_b32 v85, v72, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v84, v84, v85
	ds_bpermute_b32 v85, v73, v44
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v44, v44, v85
	ds_bpermute_b32 v85, v73, v45
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v45, v45, v85
	ds_bpermute_b32 v85, v73, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v56, v56, v85
	ds_bpermute_b32 v85, v73, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v57, v57, v85
	ds_bpermute_b32 v85, v73, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v63, v63, v85
	ds_bpermute_b32 v85, v73, v64
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v64, v64, v85
	ds_bpermute_b32 v85, v73, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v65, v85
	ds_bpermute_b32 v85, v73, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v84, v84, v85
	ds_bpermute_b32 v85, v74, v44
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v44, v44, v85
	ds_bpermute_b32 v85, v74, v45
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v45, v45, v85
	ds_bpermute_b32 v85, v74, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v85, v56, v85
	ds_bpermute_b32 v56, v74, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	v_max_num_f32_e32 v86, v57, v56
	ds_bpermute_b32 v56, v74, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v63, v63, v56
	ds_bpermute_b32 v56, v74, v64
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	v_max_num_f32_e32 v64, v64, v56
	ds_bpermute_b32 v56, v74, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v65, v56
	ds_bpermute_b32 v56, v74, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	v_dual_max_num_f32 v96, v84, v56 :: v_dual_max_num_f32 v56, v37, v37
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v91, v56, v44 :: v_dual_max_num_f32 v56, v61, v61
	v_dual_cndmask_b32 v92, v91, v44, vcc_lo :: v_dual_max_num_f32 v90, v56, v45
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v93, v90, v45, vcc_lo
	v_dual_sub_f32 v38, v38, v92 :: v_dual_sub_f32 v39, v39, v93
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_exp_f32_e32 v56, v38
	v_nop
	v_max_num_f32_e32 v38, v34, v34
	v_exp_f32_e32 v57, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v89, v38, v85 :: v_dual_max_num_f32 v38, v60, v60
	v_dual_cndmask_b32 v94, v89, v85, vcc_lo :: v_dual_max_num_f32 v88, v38, v86
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_sub_f32 v38, v40, v94 :: v_dual_sub_f32 v34, v34, v94
	v_exp_f32_e32 v44, v38
	v_nop
	v_max_num_f32_e32 v38, v32, v32
	v_cndmask_b32_e32 v95, v88, v86, vcc_lo
	v_exp_f32_e32 v34, v34
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_max_num_f32_e32 v87, v38, v63
	v_max_num_f32_e32 v38, v35, v35
	v_sub_f32_e32 v39, v41, v95
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_cndmask_b32 v97, v87, v63 :: v_dual_max_num_f32 v86, v38, v64
	v_exp_f32_e32 v45, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_sub_f32_e32 v38, v42, v97
	v_exp_f32_e32 v42, v38
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v38, v33, v33 :: v_dual_cndmask_b32 v98, v86, v64, vcc_lo
	v_dual_sub_f32 v37, v37, v92 :: v_dual_max_num_f32 v85, v38, v65
	v_max_num_f32_e32 v38, v58, v58
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_sub_f32_e32 v39, v43, v98
	v_exp_f32_e32 v37, v37
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_max_num_f32 v84, v38, v96 :: v_dual_cndmask_b32 v99, v85, v65
	v_exp_f32_e32 v43, v39
	v_sub_f32_e32 v32, v32, v97
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_cndmask_b32_e64 v64, v37, 0, vcc_lo
	v_dual_cndmask_b32 v96, v84, v96, vcc_lo :: v_dual_sub_f32 v38, v62, v99
	v_sub_f32_e32 v37, v60, v95
	v_sub_f32_e32 v33, v33, v99
	v_exp_f32_e32 v32, v32
	s_delay_alu instid0(VALU_DEP_3)
	v_sub_f32_e32 v39, v59, v96
	v_exp_f32_e32 v40, v38
	v_nop
	v_cvt_f16_f32_e32 v38, v56
	v_exp_f32_e32 v37, v37
	v_exp_f32_e32 v33, v33
	v_exp_f32_e32 v41, v39
	v_cndmask_b32_e64 v60, v32, 0, vcc_lo
	ds_store_b16 v79, v38
	v_cvt_f16_f32_e32 v38, v57
	v_sub_f32_e32 v32, v58, v96
	v_cndmask_b32_e64 v58, v33, 0, vcc_lo
	ds_store_b16 v79, v38 offset:32
	v_cvt_f16_f32_e32 v38, v44
	ds_store_b16 v79, v38 offset:64
	v_cvt_f16_f32_e32 v38, v45
	ds_store_b16 v79, v38 offset:96
	v_cvt_f16_f32_e32 v38, v42
	ds_store_b16 v79, v38 offset:128
	v_cvt_f16_f32_e32 v38, v43
	ds_store_b16 v79, v38 offset:160
	v_cvt_f16_f32_e32 v38, v40
	ds_store_b16 v79, v38 offset:192
	v_cvt_f16_f32_e32 v38, v41
	ds_store_b16 v79, v38 offset:224
	v_add_nc_u32_e32 v38, s5, v76
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_nc_u32 v108, v38, v80 :: v_dual_add_nc_u32 v109, v38, v81
	ds_load_u16 v39, v108 offset:128
	ds_load_u16 v59, v108 offset:384
	ds_load_u16 v62, v108
	ds_load_u16 v63, v109
	v_dual_add_nc_u32 v110, v38, v82 :: v_dual_add_nc_u32 v111, v38, v83
	s_wait_dscnt 0x1
	v_perm_b32 v100, v39, v62, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v101, v59, v63, 0x5040100
	ds_load_u16 v39, v108 offset:640
	ds_load_u16 v59, v110
	v_cndmask_b32_e64 v63, v37, 0, vcc_lo
	v_mov_b32_e32 v37, v36
	v_exp_f32_e32 v32, v32
	v_cndmask_b32_e64 v62, v34, 0, vcc_lo
	v_sub_f32_e32 v34, v35, v98
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_mul_f32 v[2:3], v[2:3], v[62:63]
	v_exp_f32_e32 v34, v34
	v_pk_mul_f32 v[10:11], v[10:11], v[62:63]
	v_pk_mul_f32 v[18:19], v[18:19], v[62:63]
	v_pk_mul_f32 v[26:27], v[26:27], v[62:63]
	s_wait_dscnt 0x0
	v_perm_b32 v102, v39, v59, 0x5040100
	ds_load_u16 v38, v108 offset:896
	ds_load_u16 v39, v111
	v_cndmask_b32_e64 v59, v32, 0, vcc_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_mul_f32 v[6:7], v[6:7], v[58:59]
	v_pk_mul_f32 v[14:15], v[14:15], v[58:59]
	v_pk_mul_f32 v[22:23], v[22:23], v[58:59]
	v_pk_mul_f32 v[30:31], v[30:31], v[58:59]
	s_wait_dscnt 0x0
	v_perm_b32 v103, v38, v39, 0x5040100
	v_sub_f32_e32 v38, v61, v93
	v_cndmask_b32_e64 v61, v34, 0, vcc_lo
	ds_load_b128 v[32:35], v75
	v_mov_b32_e32 v39, v36
	v_exp_f32_e32 v38, v38
	v_pk_mul_f32 v[4:5], v[4:5], v[60:61]
	v_pk_mul_f32 v[12:13], v[12:13], v[60:61]
	v_pk_mul_f32 v[20:21], v[20:21], v[60:61]
	v_pk_mul_f32 v[28:29], v[28:29], v[60:61]
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_cndmask_b32_e64 v65, v38, 0, vcc_lo
	v_mov_b32_e32 v38, v36
	v_pk_mul_f32 v[0:1], v[0:1], v[64:65]
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[100:107], v[0:7]
	ds_load_u16 v100, v108 offset:32
	ds_load_u16 v101, v109 offset:32
	ds_load_u16 v102, v108 offset:160
	ds_load_u16 v103, v108 offset:416
	v_pk_mul_f32 v[8:9], v[8:9], v[64:65]
	v_pk_mul_f32 v[16:17], v[16:17], v[64:65]
	v_pk_mul_f32 v[24:25], v[24:25], v[64:65]
	s_wait_dscnt 0x1
	v_nop
	v_perm_b32 v100, v102, v100, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v101, v103, v101, 0x5040100
	ds_load_u16 v102, v110 offset:32
	ds_load_u16 v103, v108 offset:672
	s_wait_dscnt 0x0
	v_perm_b32 v102, v103, v102, 0x5040100
	ds_load_u16 v103, v111 offset:32
	ds_load_u16 v104, v108 offset:928
	s_wait_dscnt 0x0
	v_perm_b32 v103, v104, v103, 0x5040100
	v_mov_b32_e32 v104, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[100:107], v[8:15]
	ds_load_u16 v100, v108 offset:64
	ds_load_u16 v101, v108 offset:192
	ds_load_u16 v102, v109 offset:64
	ds_load_u16 v103, v108 offset:448
	s_wait_dscnt 0x2
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v100, v101, v100, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v101, v103, v102, 0x5040100
	ds_load_u16 v102, v110 offset:64
	ds_load_u16 v103, v108 offset:704
	s_wait_dscnt 0x0
	v_perm_b32 v102, v103, v102, 0x5040100
	ds_load_u16 v103, v111 offset:64
	ds_load_u16 v104, v108 offset:960
	s_wait_dscnt 0x0
	v_perm_b32 v103, v104, v103, 0x5040100
	v_mov_b32_e32 v104, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[100:107], v[16:23]
	ds_load_u16 v101, v109 offset:96
	ds_load_u16 v100, v108 offset:96
	ds_load_u16 v102, v108 offset:224
	ds_load_u16 v103, v108 offset:480
	s_wait_dscnt 0x1
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v100, v102, v100, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v101, v103, v101, 0x5040100
	ds_load_u16 v102, v110 offset:96
	ds_load_u16 v103, v108 offset:736
	s_wait_dscnt 0x0
	v_perm_b32 v102, v103, v102, 0x5040100
	ds_load_u16 v103, v111 offset:96
	ds_load_u16 v104, v108 offset:992
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_perm_b32 v103, v104, v103, 0x5040100
	v_mov_b32_e32 v104, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[100:107], v[24:31]
	ds_bpermute_b32 v32, v71, v56
	ds_bpermute_b32 v33, v71, v57
	v_nop
	v_nop
	v_nop
	v_nop
	v_mov_b32_e32 v37, v92
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[56:57], v[32:33]
	ds_bpermute_b32 v34, v72, v32
	ds_bpermute_b32 v35, v72, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v73, v32
	ds_bpermute_b32 v35, v73, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v74, v32
	ds_bpermute_b32 v35, v74, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_fma_f32 v[52:53], v[52:53], v[64:65], v[32:33]
	ds_bpermute_b32 v32, v71, v44
	ds_bpermute_b32 v33, v71, v45
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[44:45], v[32:33]
	ds_bpermute_b32 v34, v72, v32
	ds_bpermute_b32 v35, v72, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v73, v32
	ds_bpermute_b32 v35, v73, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v74, v32
	ds_bpermute_b32 v35, v74, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_fma_f32 v[50:51], v[50:51], v[62:63], v[32:33]
	ds_bpermute_b32 v32, v71, v42
	ds_bpermute_b32 v33, v71, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[42:43], v[32:33]
	ds_bpermute_b32 v34, v72, v32
	ds_bpermute_b32 v35, v72, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v73, v32
	ds_bpermute_b32 v35, v73, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v74, v32
	ds_bpermute_b32 v35, v74, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_fma_f32 v[48:49], v[48:49], v[60:61], v[32:33]
	ds_bpermute_b32 v32, v71, v40
	ds_bpermute_b32 v33, v71, v41
	v_dual_mov_b32 v61, v93 :: v_dual_mov_b32 v60, v95
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[40:41], v[32:33]
	ds_bpermute_b32 v34, v72, v32
	ds_bpermute_b32 v35, v72, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v73, v32
	ds_bpermute_b32 v35, v73, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[32:33], v[34:35]
	v_dual_mov_b32 v34, v94 :: v_dual_mov_b32 v32, v97
	v_dual_mov_b32 v35, v98 :: v_dual_mov_b32 v33, v99
	ds_bpermute_b32 v40, v74, v38
	ds_bpermute_b32 v41, v74, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[40:41]
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_fma_f32 v[46:47], v[46:47], v[58:59], v[38:39]
	v_mov_b32_e32 v58, v96
	s_cbranch_scc1 .LBB1_8
.LBB1_4:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_6 Depth 2
	s_and_b32 s4, s14, 1
	s_cmp_eq_u32 s14, 63
	s_cbranch_scc1 .LBB1_3
; %bb.5:                                ;   in Loop: Header=BB1_4 Depth=1
	s_lshl_b32 s5, s4, 11
	v_mov_b32_e32 v39, v78
	v_xad_u32 v38, 0x800, s5, v67
	s_mov_b32 s5, 0
.LBB1_6:                                ;   Parent Loop BB1_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_2)
	v_add3_u32 v40, s13, v39, 0x500
	v_add_nc_u32_e32 v39, 0x100, v39
	s_clause 0x1
	global_load_u16 v41, v40, s[6:7] scale_offset
	global_load_u16 v42, v40, s[8:9] scale_offset
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v39
	s_wait_loadcnt 0x1
	ds_store_b16 v38, v41
	s_wait_loadcnt 0x0
	ds_store_b16 v38, v42 offset:4096
	v_add_nc_u32_e32 v38, 0x200, v38
	s_or_b32 s5, vcc_lo, s5
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s5
	s_cbranch_execnz .LBB1_6
; %bb.7:                                ;   in Loop: Header=BB1_4 Depth=1
	s_or_b32 exec_lo, exec_lo, s5
	s_branch .LBB1_3
.LBB1_8:
	v_or_b32_e32 v32, v68, v70
	v_rcp_f32_e32 v34, v52
	v_cmp_eq_u32_e32 vcc_lo, 0, v66
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_add_nc_u32_e32 v33, s12, v32
	v_fma_mixlo_f16 v0, v34, v0, 0
	v_fma_mixlo_f16 v8, v34, v8, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v35, v33, 6, v66
	v_fma_mixlo_f16 v16, v34, v16, 0
	v_fma_mixlo_f16 v24, v34, v24, 0
	s_clause 0x3
	global_store_b16 v35, v0, s[2:3] scale_offset
	global_store_b16 v35, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v35, v16, s[2:3] offset:64 scale_offset
	global_store_b16 v35, v24, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_10
; %bb.9:
	global_load_b32 v0, v33, s[10:11] scale_offset
	v_log_f32_e32 v8, v52
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v91, v8
	s_wait_loadcnt 0x0
	v_fmamk_f32 v0, v8, 0x3f317218, v0
	global_store_b32 v33, v0, s[0:1] scale_offset
.LBB1_10:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v8, v53
	v_add3_u32 v0, s12, v32, 1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v16, v0, 6, v66
	v_fma_mixlo_f16 v1, v8, v1, 0
	v_fma_mixlo_f16 v9, v8, v9, 0
	v_fma_mixlo_f16 v17, v8, v17, 0
	v_fma_mixlo_f16 v8, v8, v25, 0
	s_clause 0x3
	global_store_b16 v16, v1, s[2:3] scale_offset
	global_store_b16 v16, v9, s[2:3] offset:32 scale_offset
	global_store_b16 v16, v17, s[2:3] offset:64 scale_offset
	global_store_b16 v16, v8, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_12
; %bb.11:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v8, v53
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v90, v8
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v8, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_12:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v50
	v_add3_u32 v0, s12, v32, 2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v8, v0, 6, v66
	v_fma_mixlo_f16 v2, v1, v2, 0
	v_fma_mixlo_f16 v9, v1, v10, 0
	v_fma_mixlo_f16 v10, v1, v18, 0
	v_fma_mixlo_f16 v1, v1, v26, 0
	s_clause 0x3
	global_store_b16 v8, v2, s[2:3] scale_offset
	global_store_b16 v8, v9, s[2:3] offset:32 scale_offset
	global_store_b16 v8, v10, s[2:3] offset:64 scale_offset
	global_store_b16 v8, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_14
; %bb.13:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v50
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v89, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_14:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v51
	v_add3_u32 v0, s12, v32, 3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v66
	v_fma_mixlo_f16 v3, v1, v3, 0
	v_fma_mixlo_f16 v8, v1, v11, 0
	v_fma_mixlo_f16 v9, v1, v19, 0
	v_fma_mixlo_f16 v1, v1, v27, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v9, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_16
; %bb.15:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v51
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v88, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_16:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v48
	v_add3_u32 v0, s12, v32, 4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v66
	v_fma_mixlo_f16 v3, v1, v4, 0
	v_fma_mixlo_f16 v4, v1, v12, 0
	v_fma_mixlo_f16 v8, v1, v20, 0
	v_fma_mixlo_f16 v1, v1, v28, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v4, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_18
; %bb.17:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v48
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v87, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_18:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v49
	v_add3_u32 v0, s12, v32, 5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v66
	v_fma_mixlo_f16 v3, v1, v5, 0
	v_fma_mixlo_f16 v4, v1, v13, 0
	v_fma_mixlo_f16 v5, v1, v21, 0
	v_fma_mixlo_f16 v1, v1, v29, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v4, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v5, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_20
; %bb.19:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v49
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v86, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_20:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v46
	v_add3_u32 v0, s12, v32, 6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v66
	v_fma_mixlo_f16 v3, v1, v6, 0
	v_fma_mixlo_f16 v4, v1, v14, 0
	v_fma_mixlo_f16 v5, v1, v22, 0
	v_fma_mixlo_f16 v1, v1, v30, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v4, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v5, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_22
; %bb.21:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v46
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v85, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_22:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v47
	v_add3_u32 v0, s12, v32, 7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v66
	v_fma_mixlo_f16 v3, v1, v7, 0
	v_fma_mixlo_f16 v4, v1, v15, 0
	v_fma_mixlo_f16 v5, v1, v23, 0
	v_fma_mixlo_f16 v1, v1, v31, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v4, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v5, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB1_24
; %bb.23:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v47
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v84, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_24:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_wait_storecnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel forgetting_attention_original
		.amdhsa_group_segment_fixed_size 12288
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
		.amdhsa_next_free_vgpr 112
		.amdhsa_next_free_sgpr 18
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
.Lfunc_end1:
	.size	forgetting_attention_original, .Lfunc_end1-forgetting_attention_original
                                        ; -- End function
	.set forgetting_attention_original.num_vgpr, 112
	.set forgetting_attention_original.num_agpr, 0
	.set forgetting_attention_original.numbered_sgpr, 18
	.set forgetting_attention_original.num_named_barrier, 0
	.set forgetting_attention_original.private_seg_size, 0
	.set forgetting_attention_original.uses_vcc, 1
	.set forgetting_attention_original.uses_flat_scratch, 0
	.set forgetting_attention_original.has_dyn_sized_stack, 0
	.set forgetting_attention_original.has_recursion, 0
	.set forgetting_attention_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5240
; TotalNumSgprs: 20
; NumVgprs: 112
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 12288 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 20
; NumVGPRsForWavesPerEU: 112
; NamedBarCnt: 0
; Occupancy: 9
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	sage_attention_original ; -- Begin function sage_attention_original
	.globl	sage_attention_original
	.p2align	8
	.type	sage_attention_original,@function
sage_attention_original:                ; @sage_attention_original
; %bb.0:
	s_bfe_u32 s2, ttmp6, 0x40010
	s_load_b256 s[4:11], s[0:1], 0x0
	s_add_co_i32 s12, s2, 1
	s_wait_xcnt 0x0
	s_load_b128 s[0:3], s[0:1], 0x20
	s_bfe_u32 s15, ttmp6, 0x40014
	s_and_b32 s13, ttmp7, 0xffff
	s_lshr_b32 s16, ttmp7, 16
	s_add_co_i32 s15, s15, 1
	s_mul_i32 s12, s13, s12
	s_bfe_u32 s14, ttmp6, 0x40004
	s_mul_i32 s15, s16, s15
	s_bfe_u32 s17, ttmp6, 0x40008
	s_add_co_i32 s14, s14, s12
	s_getreg_b32 s12, hwreg(HW_REG_IB_STS2, 6, 4)
	s_add_co_i32 s17, s17, s15
	s_cmp_eq_u32 s12, 0
	v_lshl_or_b32 v66, v0, 1, 0x1000
	s_cselect_b32 s16, s16, s17
	s_cselect_b32 s13, s13, s14
	s_lshl_b32 s15, s16, 1
	s_lshr_b32 s14, s13, 3
	v_dual_mov_b32 v1, v66 :: v_dual_mov_b32 v2, v0
	s_add_co_i32 s15, s15, s14
	s_mov_b32 s17, 0
	s_lshl_b32 s14, s15, 13
.LBB2_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_add_nc_u32_e32 v3, s14, v2
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v2
	s_wait_kmcnt 0x0
	s_clause 0x1
	global_load_i8 v4, v3, s[6:7]
	global_load_u16 v5, v3, s[8:9] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v3, 0x100, v2
	s_or_b32 s17, vcc_lo, s17
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b32_e32 v2, v3
	s_wait_loadcnt 0x1
	v_cvt_f16_i16_e32 v4, v4
	ds_store_b16 v1, v4
	s_wait_loadcnt 0x0
	ds_store_b16 v1, v5 offset:4096
	v_add_nc_u32_e32 v1, 0x200, v1
	s_and_not1_b32 exec_lo, exec_lo, s17
	s_cbranch_execnz .LBB2_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s17
	v_mbcnt_lo_u32_b32 v2, -1, 0
	s_bfe_u32 s17, ttmp6, 0x4000c
	s_lshl_b32 s16, s16, 4
	s_add_co_i32 s17, s17, 1
	s_and_b32 s18, ttmp6, 15
	v_dual_lshrrev_b32 v9, 1, v0 :: v_dual_bitop2_b32 v5, 1, v2 bitop3:0x14
	v_and_b32_e32 v3, 16, v2
	s_mul_i32 s17, ttmp9, s17
	v_dual_lshrrev_b32 v1, 5, v0 :: v_dual_bitop2_b32 v67, 15, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_add_nc_u32 v3, 16, v3 :: v_dual_bitop2_b32 v6, 8, v2 bitop3:0x14
	v_xor_b32_e32 v7, 4, v2
	s_add_co_i32 s19, s16, s13
	s_add_co_i32 s18, s18, s17
	s_cmp_eq_u32 s12, 0
	v_cmp_lt_i32_e32 vcc_lo, v5, v3
	s_cselect_b32 s12, ttmp9, s18
	v_lshlrev_b32_e32 v10, 7, v67
	s_lshl_b32 s13, s12, 7
	s_lshl_b32 s16, s19, 3
	v_cndmask_b32_e32 v5, v2, v5, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v6, v3
	v_lshl_or_b32 v68, v1, 4, s13
	s_mov_b32 s13, 0
	s_add_co_i32 s12, s16, s12
	v_dual_cndmask_b32 v6, v2, v6 :: v_dual_lshlrev_b32 v11, 5, v0
	v_cmp_lt_i32_e32 vcc_lo, v7, v3
	v_xor_b32_e32 v8, 2, v2
	v_dual_lshlrev_b32 v1, 9, v1 :: v_dual_bitop2_b32 v4, v68, v67 bitop3:0x54
	s_lshl_b64 s[16:17], s[12:13], 2
	v_cndmask_b32_e32 v7, v2, v7, vcc_lo
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cmp_lt_i32_e32 vcc_lo, v8, v3
	v_and_b32_e32 v69, 8, v9
	s_lshl_b32 s12, s19, 16
	v_dual_mov_b32 v36, 0 :: v_dual_lshlrev_b32 v71, 2, v7
	v_cndmask_b32_e32 v2, v2, v8, vcc_lo
	v_lshl_add_u32 v3, v4, 6, s12
	v_and_b32_e32 v8, 0x1e0, v11
	v_dual_lshlrev_b32 v70, 2, v6 :: v_dual_lshlrev_b32 v4, 1, v67
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_4)
	v_dual_lshlrev_b32 v6, 1, v69 :: v_dual_lshlrev_b32 v72, 2, v2
	v_lshlrev_b32_e32 v73, 2, v5
	v_dual_mov_b32 v3, v36 :: v_dual_bitop2_b32 v2, v3, v69 bitop3:0x54
	v_dual_mov_b32 v46, 0 :: v_dual_bitop2_b32 v5, v1, v4 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_4)
	v_or3_b32 v74, v1, v8, v6
	v_dual_lshlrev_b32 v1, 5, v69 :: v_dual_mov_b32 v27, v36
	v_lshlrev_b32_e32 v79, 7, v69
	v_add_nc_u64_e32 v[52:53], s[4:5], v[2:3]
	v_or_b32_e32 v75, 0x2000, v4
	v_or3_b32 v76, v10, v6, 0x1000
	v_or_b32_e32 v77, 0xffffff00, v0
	v_dual_mov_b32 v47, v36 :: v_dual_add_nc_u32 v78, v5, v1
	v_dual_mov_b32 v54, 0 :: v_dual_mov_b32 v55, v36
	v_dual_mov_b32 v50, 0 :: v_dual_mov_b32 v51, v36
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v49, v36
	v_dual_mov_b32 v0, v36 :: v_dual_mov_b32 v1, v36
	v_dual_mov_b32 v2, v36 :: v_dual_mov_b32 v4, v36
	v_dual_mov_b32 v5, v36 :: v_dual_mov_b32 v6, v36
	v_dual_mov_b32 v7, v36 :: v_dual_mov_b32 v8, v36
	v_dual_mov_b32 v9, v36 :: v_dual_mov_b32 v10, v36
	v_dual_mov_b32 v11, v36 :: v_dual_mov_b32 v12, v36
	v_dual_mov_b32 v13, v36 :: v_dual_mov_b32 v14, v36
	v_dual_mov_b32 v15, v36 :: v_dual_mov_b32 v16, v36
	v_dual_mov_b32 v17, v36 :: v_dual_mov_b32 v18, v36
	v_dual_mov_b32 v19, v36 :: v_dual_mov_b32 v20, v36
	v_dual_mov_b32 v21, v36 :: v_dual_mov_b32 v22, v36
	v_dual_mov_b32 v23, v36 :: v_dual_mov_b32 v24, v36
	v_dual_mov_b32 v25, v36 :: v_dual_mov_b32 v26, v36
	v_dual_mov_b32 v28, v36 :: v_dual_mov_b32 v29, v36
	v_dual_mov_b32 v30, v36 :: v_dual_mov_b32 v31, v36
	v_or_b32_e32 v80, 0x100, v79
	v_or_b32_e32 v81, 0x200, v79
	v_or_b32_e32 v82, 0x300, v79
	v_dual_mov_b32 v32, 0 :: v_dual_mov_b32 v64, 0
	v_dual_mov_b32 v35, 0 :: v_dual_mov_b32 v83, 0
	v_dual_mov_b32 v34, 0 :: v_dual_mov_b32 v37, 0
	v_dual_mov_b32 v33, 0 :: v_dual_mov_b32 v62, 0
	s_add_nc_u64 s[10:11], s[10:11], s[16:17]
	s_lshl_b32 s15, s15, 1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB2_4
.LBB2_3:                                ;   in Loop: Header=BB2_4 Depth=1
	s_clause 0x1
	global_load_b64 v[38:39], v[52:53], off offset:16
	global_load_b64 v[40:41], v[52:53], off
	s_lshl_b32 s4, s4, 11
	s_lshr_b32 s5, s13, 2
	v_add_nc_u32_e32 v60, s4, v76
	s_add_co_i32 s5, s5, s15
	ds_load_b128 v[92:95], v60
	ds_load_b128 v[96:99], v60 offset:32
	s_wait_loadcnt 0x1
	v_ashrrev_i16 v43, 8, v39
	v_bfe_i32 v44, v39, 0, 8
	s_wait_loadcnt 0x0
	v_ashrrev_i16 v56, 8, v41
	v_ashrrev_i16 v42, 8, v38
	v_bfe_i32 v45, v38, 0, 8
	v_cvt_f16_i16_e32 v43, v43
	v_cvt_f16_i16_e32 v44, v44
	v_dual_lshrrev_b32 v39, 16, v39 :: v_dual_lshrrev_b32 v38, 16, v38
	v_cvt_f16_i16_e32 v42, v42
	v_cvt_f16_i16_e32 v45, v45
	s_delay_alu instid0(VALU_DEP_4)
	v_pack_b32_f16 v90, v44, v43
	v_cvt_f16_i16_e32 v43, v56
	global_load_b64 v[56:57], v[52:53], off offset:48
	v_lshrrev_b32_e32 v44, 16, v40
	v_pack_b32_f16 v88, v45, v42
	v_bfe_i32 v42, v41, 0, 8
	v_lshrrev_b32_e32 v41, 16, v41
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v42, v42
	v_pack_b32_f16 v86, v42, v43
	v_ashrrev_i16 v42, 8, v40
	v_bfe_i32 v40, v40, 0, 8
	v_ashrrev_i16 v43, 8, v39
	v_bfe_i32 v39, v39, 0, 8
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f16_i16_e32 v42, v42
	v_cvt_f16_i16_e32 v40, v40
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f16_i16_e32 v43, v43
	v_cvt_f16_i16_e32 v39, v39
	s_delay_alu instid0(VALU_DEP_3)
	v_pack_b32_f16 v84, v40, v42
	v_bfe_i32 v40, v44, 0, 8
	v_ashrrev_i16 v42, 8, v44
	v_ashrrev_i16 v44, 8, v41
	v_pack_b32_f16 v91, v39, v43
	v_ashrrev_i16 v39, 8, v38
	v_bfe_i32 v38, v38, 0, 8
	v_bfe_i32 v41, v41, 0, 8
	v_cvt_f16_i16_e32 v42, v42
	v_cvt_f16_i16_e32 v43, v44
	v_cvt_f16_i16_e32 v39, v39
	v_cvt_f16_i16_e32 v38, v38
	v_cvt_f16_i16_e32 v41, v41
	v_cvt_f16_i16_e32 v40, v40
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_pack_b32_f16 v89, v38, v39
	v_pack_b32_f16 v87, v41, v43
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_pack_b32_f16 v85, v40, v42
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[38:45], v[84:91], v[92:99], 0
	s_wait_loadcnt 0x0
	v_ashrrev_i16 v58, 8, v56
	v_ashrrev_i16 v59, 8, v57
	v_bfe_i32 v61, v57, 0, 8
	v_bfe_i32 v63, v56, 0, 8
	v_lshrrev_b32_e32 v57, 16, v57
	v_cvt_f16_i16_e32 v58, v58
	v_cvt_f16_i16_e32 v59, v59
	v_cvt_f16_i16_e32 v61, v61
	v_cvt_f16_i16_e32 v63, v63
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v90, v61, v59
	v_pack_b32_f16 v88, v63, v58
	global_load_b64 v[58:59], v[52:53], off offset:32
	ds_load_b128 v[92:95], v60 offset:64
	ds_load_b128 v[96:99], v60 offset:96
	s_load_b32 s16, s[10:11], 0x0
	s_load_b32 s17, s[0:1], s5 offset:0x0 scale_offset
	s_wait_xcnt 0x0
	s_add_co_i32 s5, s13, 1
	s_cmp_eq_u32 s13, 0
	s_mov_b32 s13, s5
	s_cselect_b32 vcc_lo, -1, 0
	s_addk_co_i32 s14, 0x400
	s_cmp_lg_u32 s5, 8
	s_wait_kmcnt 0x0
	s_mul_f32 s16, s16, s17
	v_lshrrev_b32_e32 v56, 16, v56
	s_wait_loadcnt 0x0
	v_ashrrev_i16 v61, 8, v59
	v_bfe_i32 v63, v59, 0, 8
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_i16_e32 v61, v61
	v_cvt_f16_i16_e32 v63, v63
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v86, v63, v61
	v_ashrrev_i16 v61, 8, v58
	v_bfe_i32 v63, v58, 0, 8
	v_cvt_f16_i16_e32 v61, v61
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v63, v63
	v_pack_b32_f16 v84, v63, v61
	v_ashrrev_i16 v61, 8, v57
	v_bfe_i32 v57, v57, 0, 8
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_i16_e32 v61, v61
	v_cvt_f16_i16_e32 v57, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v91, v57, v61
	v_ashrrev_i16 v57, 8, v56
	v_bfe_i32 v56, v56, 0, 8
	v_cvt_f16_i16_e32 v57, v57
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v56, v56
	v_pack_b32_f16 v89, v56, v57
	v_lshrrev_b32_e32 v56, 16, v59
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_ashrrev_i16 v57, 8, v56
	v_bfe_i32 v56, v56, 0, 8
	v_cvt_f16_i16_e32 v57, v57
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v56, v56
	v_pack_b32_f16 v87, v56, v57
	v_lshrrev_b32_e32 v56, 16, v58
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_ashrrev_i16 v57, 8, v56
	v_bfe_i32 v56, v56, 0, 8
	v_cvt_f16_i16_e32 v57, v57
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v56, v56
	v_pack_b32_f16 v85, v56, v57
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(TRANS32_DEP_1)
	v_wmma_f32_16x16x32_f16 v[38:45], v[84:91], v[92:99], v[38:45]
	v_dual_mov_b32 v97, v36 :: v_dual_mov_b32 v98, v36
	v_nop
	v_nop
	v_nop
	v_dual_mov_b32 v96, v36 :: v_dual_mul_f32 v57, s16, v39
	s_delay_alu instid0(TRANS32_DEP_1)
	v_mul_f32_e32 v59, s16, v40
	ds_bpermute_b32 v60, v70, v57
	v_mul_f32_e32 v56, s16, v38
	ds_bpermute_b32 v61, v70, v59
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v60, v60, v60
	ds_bpermute_b32 v58, v70, v56
	s_wait_dscnt 0x1
	v_max_num_f32_e32 v61, v61, v61
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v57, v57, v60 :: v_dual_max_num_f32 v59, v59, v61
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v58, v58, v58 :: v_dual_mul_f32 v63, s16, v41
	v_max_num_f32_e32 v56, v56, v58
	v_mul_f32_e32 v58, s16, v42
	ds_bpermute_b32 v60, v70, v63
	ds_bpermute_b32 v61, v70, v58
	s_wait_dscnt 0x0
	v_dual_max_num_f32 v60, v60, v60 :: v_dual_max_num_f32 v61, v61, v61
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_max_num_f32 v60, v63, v60 :: v_dual_mul_f32 v63, s16, v43
	v_max_num_f32_e32 v58, v58, v61
	ds_bpermute_b32 v61, v70, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v61, v61, v61
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v61, v63, v61 :: v_dual_mul_f32 v63, s16, v44
	ds_bpermute_b32 v65, v70, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v65, v65, v65
	v_max_num_f32_e32 v63, v63, v65
	v_mul_f32_e32 v65, s16, v45
	ds_bpermute_b32 v84, v70, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v65, v84
	ds_bpermute_b32 v84, v71, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v56, v56, v84
	ds_bpermute_b32 v84, v71, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v57, v84
	ds_bpermute_b32 v84, v71, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v59, v59, v84
	ds_bpermute_b32 v84, v71, v60
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v60, v60, v84
	ds_bpermute_b32 v84, v71, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v58, v58, v84
	ds_bpermute_b32 v84, v71, v61
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v61, v61, v84
	ds_bpermute_b32 v84, v71, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v63, v63, v84
	ds_bpermute_b32 v84, v71, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v65, v84
	ds_bpermute_b32 v84, v72, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v56, v56, v84
	ds_bpermute_b32 v84, v72, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v57, v84
	ds_bpermute_b32 v84, v72, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v59, v59, v84
	ds_bpermute_b32 v84, v72, v60
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v60, v60, v84
	ds_bpermute_b32 v84, v72, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v58, v58, v84
	ds_bpermute_b32 v84, v72, v61
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v61, v61, v84
	ds_bpermute_b32 v84, v72, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v63, v63, v84
	ds_bpermute_b32 v84, v72, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v65, v84
	ds_bpermute_b32 v84, v73, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v56, v56, v84
	ds_bpermute_b32 v84, v73, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v57, v84
	ds_bpermute_b32 v84, v73, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v59, v59, v84
	ds_bpermute_b32 v84, v73, v60
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v60, v60, v84
	ds_bpermute_b32 v84, v73, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v58, v58, v84
	ds_bpermute_b32 v84, v73, v61
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v61, v61, v84
	ds_bpermute_b32 v84, v73, v63
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	v_max_num_f32_e32 v63, v63, v84
	ds_bpermute_b32 v84, v73, v65
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v84, v84, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v65, v65, v84
	v_max_num_f32_e32 v84, v32, v32
	v_max_num_f32_e32 v84, v84, v56
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v87, v84, v56, vcc_lo
	v_max_num_f32_e32 v56, v64, v64
	v_max_num_f32_e32 v56, v56, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_cndmask_b32 v85, v56, v57 :: v_dual_max_num_f32 v56, v35, v35
	v_max_num_f32_e32 v56, v56, v59
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_fma_f32 v39, v39, s16, -v85
	v_cndmask_b32_e32 v86, v56, v59, vcc_lo
	v_max_num_f32_e32 v56, v83, v83
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v57, v39
	v_max_num_f32_e32 v56, v56, v60
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_fma_f32 v40, v40, s16, -v86
	v_dual_sub_f32 v35, v35, v86 :: v_dual_cndmask_b32 v88, v56, v60
	v_max_num_f32_e32 v56, v34, v34
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v35, v35
	v_max_num_f32_e32 v56, v56, v58
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_fma_f32 v41, v41, s16, -v88
	v_dual_cndmask_b32 v89, v56, v58 :: v_dual_max_num_f32 v56, v37, v37
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_max_num_f32_e32 v56, v56, v61
	v_fma_f32 v42, v42, s16, -v89
	v_sub_f32_e32 v34, v34, v89
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_cndmask_b32_e32 v90, v56, v61, vcc_lo
	v_max_num_f32_e32 v56, v33, v33
	v_exp_f32_e32 v42, v42
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v34, v34
	v_max_num_f32_e32 v56, v56, v63
	v_fma_f32 v43, v43, s16, -v90
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_cndmask_b32 v91, v56, v63 :: v_dual_max_num_f32 v56, v62, v62
	v_exp_f32_e32 v43, v43
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_dual_max_num_f32 v56, v56, v65 :: v_dual_sub_f32 v33, v33, v91
	v_fma_f32 v38, v38, s16, -v87
	v_fma_f32 v58, v44, s16, -v91
	v_exp_f32_e32 v44, v40
	v_cndmask_b32_e32 v84, v56, v65, vcc_lo
	v_sub_f32_e32 v32, v32, v87
	v_exp_f32_e32 v56, v38
	v_exp_f32_e32 v40, v58
	v_exp_f32_e32 v33, v33
	v_fma_f32 v59, v45, s16, -v84
	v_exp_f32_e32 v45, v41
	v_exp_f32_e32 v32, v32
	v_mov_b32_e32 v99, v36
	v_cvt_f16_f32_e32 v38, v56
	v_exp_f32_e32 v41, v59
	ds_store_b16 v78, v38
	v_cvt_f16_f32_e32 v38, v57
	ds_store_b16 v78, v38 offset:32
	v_cvt_f16_f32_e32 v38, v44
	ds_store_b16 v78, v38 offset:64
	v_cvt_f16_f32_e32 v38, v45
	ds_store_b16 v78, v38 offset:96
	v_cvt_f16_f32_e32 v38, v42
	ds_store_b16 v78, v38 offset:128
	v_cvt_f16_f32_e32 v38, v43
	ds_store_b16 v78, v38 offset:160
	v_cvt_f16_f32_e32 v38, v40
	ds_store_b16 v78, v38 offset:192
	v_cvt_f16_f32_e32 v38, v41
	ds_store_b16 v78, v38 offset:224
	v_add_nc_u32_e32 v38, s4, v75
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_nc_u32 v100, v38, v79 :: v_dual_add_nc_u32 v101, v38, v80
	ds_load_u16 v39, v100 offset:128
	ds_load_u16 v58, v100 offset:384
	ds_load_u16 v59, v100
	ds_load_u16 v60, v101
	v_dual_add_nc_u32 v102, v38, v81 :: v_dual_add_nc_u32 v103, v38, v82
	s_wait_dscnt 0x1
	v_perm_b32 v92, v39, v59, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v93, v58, v60, 0x5040100
	ds_load_u16 v39, v100 offset:640
	ds_load_u16 v58, v102
	v_cndmask_b32_e64 v60, v34, 0, vcc_lo
	s_wait_dscnt 0x0
	v_perm_b32 v94, v39, v58, 0x5040100
	ds_load_u16 v38, v100 offset:896
	ds_load_u16 v39, v103
	v_cndmask_b32_e64 v58, v35, 0, vcc_lo
	s_wait_dscnt 0x0
	v_perm_b32 v95, v38, v39, 0x5040100
	v_sub_f32_e32 v38, v64, v85
	v_cndmask_b32_e64 v64, v32, 0, vcc_lo
	v_dual_sub_f32 v32, v83, v88 :: v_dual_mov_b32 v39, v36
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v38, v38
	v_exp_f32_e32 v32, v32
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_cndmask_b32_e64 v65, v38, 0, vcc_lo
	v_mov_b32_e32 v38, v36
	v_cndmask_b32_e64 v59, v32, 0, vcc_lo
	v_dual_sub_f32 v32, v37, v90 :: v_dual_mov_b32 v37, v36
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[0:1], v[0:1], v[64:65]
	v_pk_mul_f32 v[8:9], v[8:9], v[64:65]
	v_pk_mul_f32 v[2:3], v[2:3], v[58:59]
	s_delay_alu instid0(VALU_DEP_4)
	v_exp_f32_e32 v32, v32
	v_pk_mul_f32 v[10:11], v[10:11], v[58:59]
	v_pk_mul_f32 v[16:17], v[16:17], v[64:65]
	v_pk_mul_f32 v[18:19], v[18:19], v[58:59]
	v_pk_mul_f32 v[24:25], v[24:25], v[64:65]
	v_pk_mul_f32 v[26:27], v[26:27], v[58:59]
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cndmask_b32_e64 v61, v32, 0, vcc_lo
	v_sub_f32_e32 v32, v62, v84
	v_cndmask_b32_e64 v62, v33, 0, vcc_lo
	v_pk_mul_f32 v[4:5], v[4:5], v[60:61]
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v32, v32
	v_pk_mul_f32 v[12:13], v[12:13], v[60:61]
	v_pk_mul_f32 v[20:21], v[20:21], v[60:61]
	v_pk_mul_f32 v[28:29], v[28:29], v[60:61]
	v_cndmask_b32_e64 v63, v32, 0, vcc_lo
	ds_load_b128 v[32:35], v74
	v_pk_mul_f32 v[6:7], v[6:7], v[62:63]
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[92:99], v[0:7]
	ds_load_u16 v83, v100 offset:32
	ds_load_u16 v93, v101 offset:32
	ds_load_u16 v92, v100 offset:160
	ds_load_u16 v94, v100 offset:416
	v_pk_mul_f32 v[14:15], v[14:15], v[62:63]
	v_pk_mul_f32 v[22:23], v[22:23], v[62:63]
	v_pk_mul_f32 v[30:31], v[30:31], v[62:63]
	s_wait_dscnt 0x1
	v_nop
	v_perm_b32 v92, v92, v83, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v93, v94, v93, 0x5040100
	ds_load_u16 v83, v102 offset:32
	ds_load_u16 v94, v100 offset:672
	s_wait_dscnt 0x0
	v_perm_b32 v94, v94, v83, 0x5040100
	ds_load_u16 v83, v103 offset:32
	ds_load_u16 v95, v100 offset:928
	s_wait_dscnt 0x0
	v_perm_b32 v95, v95, v83, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[92:99], v[8:15]
	ds_load_u16 v83, v100 offset:64
	ds_load_u16 v92, v100 offset:192
	ds_load_u16 v93, v101 offset:64
	ds_load_u16 v94, v100 offset:448
	s_wait_dscnt 0x2
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v92, v83, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v93, v94, v93, 0x5040100
	ds_load_u16 v83, v102 offset:64
	ds_load_u16 v94, v100 offset:704
	s_wait_dscnt 0x0
	v_perm_b32 v94, v94, v83, 0x5040100
	ds_load_u16 v83, v103 offset:64
	ds_load_u16 v95, v100 offset:960
	s_wait_dscnt 0x0
	v_perm_b32 v95, v95, v83, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[92:99], v[16:23]
	ds_load_u16 v83, v101 offset:96
	ds_load_u16 v92, v100 offset:96
	ds_load_u16 v93, v100 offset:224
	ds_load_u16 v94, v100 offset:480
	s_wait_dscnt 0x1
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v93, v92, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v93, v94, v83, 0x5040100
	ds_load_u16 v83, v102 offset:96
	ds_load_u16 v94, v100 offset:736
	s_wait_dscnt 0x0
	v_perm_b32 v94, v94, v83, 0x5040100
	ds_load_u16 v83, v103 offset:96
	ds_load_u16 v95, v100 offset:992
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_perm_b32 v95, v95, v83, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[92:99], v[24:31]
	ds_bpermute_b32 v32, v70, v56
	ds_bpermute_b32 v33, v70, v57
	ds_bpermute_b32 v38, v70, v40
	ds_bpermute_b32 v39, v70, v41
	v_dual_mov_b32 v83, v88 :: v_dual_mov_b32 v37, v90
	s_wait_dscnt 0x2
	v_nop
	v_nop
	v_nop
	v_pk_add_f32 v[32:33], v[56:57], v[32:33]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[40:41], v[38:39]
	ds_bpermute_b32 v34, v71, v32
	ds_bpermute_b32 v35, v71, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v72, v32
	ds_bpermute_b32 v35, v72, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v73, v32
	ds_bpermute_b32 v35, v73, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[34:35]
	ds_bpermute_b32 v34, v70, v42
	ds_bpermute_b32 v35, v70, v43
	v_pk_fma_f32 v[54:55], v[54:55], v[64:65], v[32:33]
	ds_bpermute_b32 v32, v70, v44
	ds_bpermute_b32 v33, v70, v45
	v_mov_b32_e32 v64, v85
	s_wait_dscnt 0x2
	v_pk_add_f32 v[34:35], v[42:43], v[34:35]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[44:45], v[32:33]
	ds_bpermute_b32 v40, v71, v32
	ds_bpermute_b32 v41, v71, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[40:41]
	ds_bpermute_b32 v40, v71, v34
	ds_bpermute_b32 v41, v71, v35
	s_wait_dscnt 0x0
	v_pk_add_f32 v[34:35], v[34:35], v[40:41]
	ds_bpermute_b32 v40, v71, v38
	ds_bpermute_b32 v41, v71, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[40:41]
	ds_bpermute_b32 v40, v72, v32
	ds_bpermute_b32 v41, v72, v33
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[32:33], v[40:41]
	ds_bpermute_b32 v40, v72, v34
	ds_bpermute_b32 v41, v72, v35
	s_wait_dscnt 0x0
	v_pk_add_f32 v[34:35], v[34:35], v[40:41]
	ds_bpermute_b32 v40, v72, v38
	ds_bpermute_b32 v41, v72, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[40:41]
	ds_bpermute_b32 v40, v73, v32
	ds_bpermute_b32 v41, v73, v33
	ds_bpermute_b32 v44, v73, v38
	ds_bpermute_b32 v45, v73, v39
	s_wait_dscnt 0x2
	v_pk_add_f32 v[40:41], v[32:33], v[40:41]
	ds_bpermute_b32 v32, v73, v34
	ds_bpermute_b32 v33, v73, v35
	s_wait_dscnt 0x2
	v_pk_add_f32 v[38:39], v[38:39], v[44:45]
	v_pk_fma_f32 v[50:51], v[50:51], v[58:59], v[40:41]
	s_delay_alu instid0(VALU_DEP_2)
	v_pk_fma_f32 v[46:47], v[46:47], v[62:63], v[38:39]
	v_mov_b32_e32 v62, v84
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[34:35], v[32:33]
	v_dual_mov_b32 v32, v87 :: v_dual_mov_b32 v35, v86
	v_dual_mov_b32 v34, v89 :: v_dual_mov_b32 v33, v91
	s_delay_alu instid0(VALU_DEP_3)
	v_pk_fma_f32 v[48:49], v[48:49], v[60:61], v[42:43]
	s_cbranch_scc0 .LBB2_8
.LBB2_4:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB2_6 Depth 2
	s_and_b32 s4, s13, 1
	s_cmp_eq_u32 s13, 7
	s_cbranch_scc1 .LBB2_3
; %bb.5:                                ;   in Loop: Header=BB2_4 Depth=1
	s_lshl_b32 s5, s4, 11
	v_mov_b32_e32 v39, v77
	v_xad_u32 v38, 0x800, s5, v66
	s_mov_b32 s5, 0
.LBB2_6:                                ;   Parent Loop BB2_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_2)
	v_add3_u32 v40, s14, v39, 0x500
	v_add_nc_u32_e32 v39, 0x100, v39
	s_clause 0x1
	global_load_i8 v41, v40, s[6:7]
	global_load_u16 v42, v40, s[8:9] scale_offset
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v39
	s_or_b32 s5, vcc_lo, s5
	s_wait_loadcnt 0x1
	s_wait_xcnt 0x0
	v_cvt_f16_i16_e32 v40, v41
	ds_store_b16 v38, v40
	s_wait_loadcnt 0x0
	ds_store_b16 v38, v42 offset:4096
	v_add_nc_u32_e32 v38, 0x200, v38
	s_and_not1_b32 exec_lo, exec_lo, s5
	s_cbranch_execnz .LBB2_6
; %bb.7:                                ;   in Loop: Header=BB2_4 Depth=1
	s_or_b32 exec_lo, exec_lo, s5
	s_branch .LBB2_3
.LBB2_8:
	v_or_b32_e32 v32, v68, v69
	v_rcp_f32_e32 v33, v54
	v_or_b32_e32 v34, s12, v67
	v_rcp_f32_e32 v35, v55
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_3)
	v_lshl_add_u32 v32, v32, 6, v34
	v_rcp_f32_e32 v34, v50
	v_fma_mixlo_f16 v0, v33, v0, 0
	v_fma_mixlo_f16 v8, v33, v8, 0
	v_fma_mixlo_f16 v16, v33, v16, 0
	v_fma_mixlo_f16 v24, v33, v24, 0
	v_add_nc_u32_e32 v33, 64, v32
	v_fma_mixlo_f16 v25, v35, v25, 0
	s_clause 0x4
	global_store_b16 v32, v0, s[2:3] scale_offset
	global_store_b16 v32, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v32, v16, s[2:3] offset:64 scale_offset
	global_store_b16 v32, v24, s[2:3] offset:96 scale_offset
	global_store_b16 v33, v25, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x3
	v_fma_mixlo_f16 v8, v34, v10, 0
	v_fma_mixlo_f16 v10, v34, v18, 0
	v_rcp_f32_e32 v18, v51
	v_fma_mixlo_f16 v1, v35, v1, 0
	v_fma_mixlo_f16 v9, v35, v9, 0
	v_fma_mixlo_f16 v2, v34, v2, 0
	v_fma_mixlo_f16 v17, v35, v17, 0
	v_add_nc_u32_e32 v0, 0x80, v32
	s_wait_xcnt 0x2
	v_fma_mixlo_f16 v16, v34, v26, 0
	s_clause 0x5
	global_store_b16 v33, v1, s[2:3] scale_offset
	global_store_b16 v33, v9, s[2:3] offset:32 scale_offset
	global_store_b16 v33, v17, s[2:3] offset:64 scale_offset
	global_store_b16 v0, v2, s[2:3] scale_offset
	global_store_b16 v0, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v0, v16, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x4
	v_rcp_f32_e32 v9, v48
	v_add_nc_u32_e32 v1, 0xc0, v32
	s_wait_xcnt 0x2
	v_fma_mixlo_f16 v2, v18, v3, 0
	v_fma_mixlo_f16 v3, v18, v11, 0
	s_wait_xcnt 0x1
	v_fma_mixlo_f16 v8, v18, v27, 0
	s_clause 0x3
	global_store_b16 v0, v10, s[2:3] offset:64 scale_offset
	global_store_b16 v1, v2, s[2:3] scale_offset
	global_store_b16 v1, v3, s[2:3] offset:32 scale_offset
	global_store_b16 v1, v8, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	v_rcp_f32_e32 v8, v49
	v_fma_mixlo_f16 v11, v18, v19, 0
	v_fma_mixlo_f16 v2, v9, v4, 0
	v_add_nc_u32_e32 v0, 0x100, v32
	v_fma_mixlo_f16 v3, v9, v12, 0
	v_fma_mixlo_f16 v4, v9, v28, 0
	v_fma_mixlo_f16 v9, v9, v20, 0
	s_clause 0x3
	global_store_b16 v1, v11, s[2:3] offset:64 scale_offset
	global_store_b16 v0, v2, s[2:3] scale_offset
	global_store_b16 v0, v3, s[2:3] offset:32 scale_offset
	global_store_b16 v0, v4, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x2
	v_fma_mixlo_f16 v2, v8, v5, 0
	v_rcp_f32_e32 v5, v46
	v_add_nc_u32_e32 v1, 0x140, v32
	s_wait_xcnt 0x1
	v_fma_mixlo_f16 v3, v8, v13, 0
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v8, v29, 0
	s_clause 0x3
	global_store_b16 v0, v9, s[2:3] offset:64 scale_offset
	global_store_b16 v1, v2, s[2:3] scale_offset
	global_store_b16 v1, v3, s[2:3] offset:32 scale_offset
	global_store_b16 v1, v4, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x1
	v_rcp_f32_e32 v3, v47
	v_fma_mixlo_f16 v8, v8, v21, 0
	v_add_nc_u32_e32 v0, 0x180, v32
	v_fma_mixlo_f16 v2, v5, v22, 0
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v5, v6, 0
	v_fma_mixlo_f16 v6, v5, v14, 0
	s_clause 0x1
	global_store_b16 v1, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v0, v2, s[2:3] offset:64 scale_offset
	s_wait_xcnt 0x1
	v_fma_mixlo_f16 v1, v5, v30, 0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 0x1c0, v32
	v_fma_mixlo_f16 v5, v3, v7, 0
	v_fma_mixlo_f16 v7, v3, v15, 0
	v_fma_mixlo_f16 v8, v3, v23, 0
	v_fma_mixlo_f16 v3, v3, v31, 0
	s_clause 0x6
	global_store_b16 v0, v4, s[2:3] scale_offset
	global_store_b16 v0, v6, s[2:3] offset:32 scale_offset
	global_store_b16 v0, v1, s[2:3] offset:96 scale_offset
	global_store_b16 v2, v5, s[2:3] scale_offset
	global_store_b16 v2, v7, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v3, s[2:3] offset:96 scale_offset
	s_wait_storecnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel sage_attention_original
		.amdhsa_group_segment_fixed_size 12288
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
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
		.amdhsa_next_free_vgpr 104
		.amdhsa_next_free_sgpr 20
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 42
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
	.size	sage_attention_original, .Lfunc_end2-sage_attention_original
                                        ; -- End function
	.set sage_attention_original.num_vgpr, 104
	.set sage_attention_original.num_agpr, 0
	.set sage_attention_original.numbered_sgpr, 20
	.set sage_attention_original.num_named_barrier, 0
	.set sage_attention_original.private_seg_size, 0
	.set sage_attention_original.uses_vcc, 1
	.set sage_attention_original.uses_flat_scratch, 0
	.set sage_attention_original.has_dyn_sized_stack, 0
	.set sage_attention_original.has_recursion, 0
	.set sage_attention_original.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5252
; TotalNumSgprs: 22
; NumVgprs: 104
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 12288 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 104
; NamedBarCnt: 0
; Occupancy: 9
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
	.type	__hip_cuid_96bb46cf362e2717,@object ; @__hip_cuid_96bb46cf362e2717
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_96bb46cf362e2717
__hip_cuid_96bb46cf362e2717:
	.byte	0                               ; 0x0
	.size	__hip_cuid_96bb46cf362e2717, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_96bb46cf362e2717
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
      - .offset:         56
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         60
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         64
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         68
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         70
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         72
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         74
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         76
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         78
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         96
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         104
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         112
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         120
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 10240
    .kernarg_segment_align: 8
    .kernarg_segment_size: 312
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           flash_attention_original
    .private_segment_fixed_size: 0
    .sgpr_count:     32
    .sgpr_spill_count: 0
    .symbol:         flash_attention_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     121
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
    .group_segment_fixed_size: 12288
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           forgetting_attention_original
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         forgetting_attention_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     112
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
    .group_segment_fixed_size: 12288
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           sage_attention_original
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         sage_attention_original.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     104
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
