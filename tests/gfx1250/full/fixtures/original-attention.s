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
	s_mul_i32 s0, ttmp7, s0
	v_dual_lshlrev_b32 v4, 5, v0 :: v_dual_bitop2_b32 v1, 15, v0 bitop3:0x40
	s_add_co_i32 s1, s1, s0
	v_dual_mov_b32 v6, 0 :: v_dual_lshlrev_b32 v64, 1, v0
	v_dual_lshlrev_b32 v65, 4, v2 :: v_dual_bitop2_b32 v66, 8, v3 bitop3:0x40
	v_lshl_or_b32 v5, v2, 9, 0x2000
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_lshlrev_b32 v7, 1, v1 :: v_dual_mov_b32 v3, v6
	s_wait_kmcnt 0x0
	s_lshl_b32 s3, s3, 6
	s_cmp_eq_u32 s2, 0
	v_mbcnt_lo_u32_b32 v75, -1, 0
	s_cselect_b32 s1, ttmp7, s1
	v_and_b32_e32 v4, 0x1e0, v4
	s_mul_i32 s19, s3, s1
	v_dual_lshlrev_b32 v9, 1, v66 :: v_dual_bitop2_b32 v8, v5, v7 bitop3:0x54
	s_lshl_b32 s23, s19, 6
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_dual_lshlrev_b32 v67, 7, v66 :: v_dual_bitop2_b32 v2, s23, v0 bitop3:0x54
	v_or_b32_e32 v68, 0x1000, v7
	v_dual_lshlrev_b32 v7, 5, v66 :: v_dual_bitop2_b32 v73, s19, v1 bitop3:0x54
	s_lshr_b32 s20, s3, 4
	v_lshlrev_b64_e32 v[2:3], 1, v[2:3]
	v_cmp_eq_u32_e64 s0, 0, v1
	v_or3_b32 v69, v5, v4, v9
	v_or_b32_e32 v70, 0x100, v67
	v_or_b32_e32 v71, 0x200, v67
	v_or_b32_e32 v72, 0x300, v67
	s_cmp_lg_u32 s3, 0
	v_add_nc_u64_e32 v[50:51], s[14:15], v[2:3]
	v_add_nc_u64_e32 v[52:53], s[16:17], v[2:3]
	v_or_b32_e32 v2, 0x200, v0
	v_or_b32_e32 v3, 0x300, v0
	v_or_b32_e32 v74, 0x1000, v64
	v_cmp_gt_u32_e64 s1, 0x380, v0
	v_cmp_gt_u32_e64 s2, 0x300, v0
	v_cmp_gt_u32_e64 s5, 0x380, v2
	v_and_b32_e32 v2, 16, v75
	v_cmp_gt_u32_e64 s3, 0x280, v0
	v_cmp_gt_u32_e64 s4, 0x200, v0
	v_cmp_gt_u32_e64 s6, 0x100, v0
	v_cmp_gt_u32_e64 s7, 0x380, v3
	v_lshl_or_b32 v76, v1, 7, v9
	v_dual_add_nc_u32 v77, 16, v2 :: v_dual_bitop2_b32 v78, 8, v75 bitop3:0x14
	v_xor_b32_e32 v79, 4, v75
	v_xor_b32_e32 v80, 2, v75
	v_xor_b32_e32 v81, 1, v75
	v_add_nc_u32_e32 v82, v8, v7
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
	global_load_u16 v2, v[50:51], off
	global_load_u16 v3, v[52:53], off
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3
	s_and_saveexec_b32 s26, s1
	s_cbranch_execz .LBB0_11
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:256
	global_load_u16 v3, v[52:53], off offset:256
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:256
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:256
	s_and_b32 exec_lo, exec_lo, s2
	s_cbranch_execz .LBB0_11
; %bb.5:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:512
	global_load_u16 v3, v[52:53], off offset:512
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:512
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:512
	s_and_b32 exec_lo, exec_lo, s3
	s_cbranch_execz .LBB0_11
; %bb.6:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:768
	global_load_u16 v3, v[52:53], off offset:768
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:768
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:768
	s_and_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB0_11
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:1024
	global_load_u16 v3, v[52:53], off offset:1024
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:1024
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:1024
	s_and_b32 exec_lo, exec_lo, s5
	s_cbranch_execz .LBB0_11
; %bb.8:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:1280
	global_load_u16 v3, v[52:53], off offset:1280
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:1280
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:1280
	s_and_b32 exec_lo, exec_lo, s6
	s_cbranch_execz .LBB0_11
; %bb.9:                                ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:1536
	global_load_u16 v3, v[52:53], off offset:1536
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:1536
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:1536
	s_and_b32 exec_lo, exec_lo, s7
	s_cbranch_execz .LBB0_11
; %bb.10:                               ;   in Loop: Header=BB0_3 Depth=1
	global_load_u16 v2, v[50:51], off offset:1792
	global_load_u16 v3, v[52:53], off offset:1792
	s_wait_loadcnt 0x1
	ds_store_b16 v64, v2 offset:1792
	s_wait_loadcnt 0x0
	ds_store_b16 v74, v3 offset:1792
.LBB0_11:                               ;   in Loop: Header=BB0_3 Depth=1
	s_or_b32 exec_lo, exec_lo, s26
	s_or_b32 s25, s25, s18
	s_and_not1_b32 vcc_lo, exec_lo, s21
	v_lshl_or_b32 v83, s25, 6, v65
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_vccnz .LBB0_19
; %bb.12:                               ;   in Loop: Header=BB0_3 Depth=1
	v_dual_add_nc_u32 v2, v73, v83 :: v_dual_mov_b32 v10, 0
	v_mov_b32_e32 v3, v6
	s_mov_b32 s28, 0
	s_mov_b32 s25, s23
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v2, v2, 6, v66
	v_dual_mov_b32 v11, v10 :: v_dual_mov_b32 v12, v10
	v_dual_mov_b32 v13, v10 :: v_dual_mov_b32 v14, v10
	v_dual_mov_b32 v15, v10 :: v_dual_mov_b32 v16, v10
	v_mov_b32_e32 v17, v10
	v_lshl_add_u64 v[62:63], v[2:3], 1, s[12:13]
	v_dual_mov_b32 v18, v10 :: v_dual_mov_b32 v19, v10
	v_dual_mov_b32 v20, v10 :: v_dual_mov_b32 v21, v10
	v_dual_mov_b32 v22, v10 :: v_dual_mov_b32 v23, v10
	v_dual_mov_b32 v24, v10 :: v_dual_mov_b32 v25, v10
	v_dual_mov_b32 v26, v10 :: v_dual_mov_b32 v27, v10
	v_dual_mov_b32 v28, v10 :: v_dual_mov_b32 v29, v10
	v_dual_mov_b32 v30, v10 :: v_dual_mov_b32 v31, v10
	v_dual_mov_b32 v32, v10 :: v_dual_mov_b32 v33, v10
	v_dual_mov_b32 v34, v10 :: v_dual_mov_b32 v35, v10
	v_dual_mov_b32 v36, v10 :: v_dual_mov_b32 v37, v10
	v_dual_mov_b32 v38, v10 :: v_dual_mov_b32 v39, v10
	v_dual_mov_b32 v40, v10 :: v_dual_mov_b32 v41, v10
	v_dual_mov_b32 v91, v10 :: v_dual_mov_b32 v9, v10
	v_dual_mov_b32 v8, v10 :: v_dual_mov_b32 v7, v10
	v_dual_mov_b32 v5, v10 :: v_dual_mov_b32 v4, v10
	v_dual_mov_b32 v3, v10 :: v_dual_mov_b32 v2, v10
	v_dual_mov_b32 v60, v10 :: v_dual_mov_b32 v61, v10
	v_dual_mov_b32 v58, v10 :: v_dual_mov_b32 v59, v10
	v_dual_mov_b32 v56, v10 :: v_dual_mov_b32 v57, v10
	v_dual_mov_b32 v54, v10 :: v_dual_mov_b32 v55, v10
.LBB0_13:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_15 Depth 3
	s_add_co_i32 s26, s28, 1
	s_and_b32 s27, s28, 1
	s_cmp_ge_u32 s26, s20
	s_cbranch_scc1 .LBB0_17
; %bb.14:                               ;   in Loop: Header=BB0_13 Depth=2
	s_lshl_b32 s29, s27, 11
	v_mov_b32_e32 v43, v0
	v_bitop3_b32 v42, v64, s29, 0x800 bitop3:0xf6
	s_mov_b32 s29, 0
.LBB0_15:                               ;   Parent Loop BB0_3 Depth=1
                                        ;     Parent Loop BB0_13 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u32_e32 v44, s25, v43
	v_cmp_lt_u32_e32 vcc_lo, 0x37f, v43
	s_clause 0x1
	global_load_u16 v45, v44, s[14:15] scale_offset
	global_load_u16 v46, v44, s[16:17] scale_offset
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v44, 0x80, v43
	s_or_b32 s29, vcc_lo, s29
	s_wait_loadcnt 0x1
	ds_store_b16 v42, v45
	s_wait_loadcnt 0x0
	ds_store_b16 v42, v46 offset:4096
	v_dual_mov_b32 v43, v44 :: v_dual_add_nc_u32 v42, 0x100, v42
	s_and_not1_b32 exec_lo, exec_lo, s29
	s_cbranch_execnz .LBB0_15
; %bb.16:                               ;   in Loop: Header=BB0_13 Depth=2
	s_or_b32 exec_lo, exec_lo, s29
.LBB0_17:                               ;   in Loop: Header=BB0_13 Depth=2
	s_lshl_b32 s27, s27, 11
	global_load_b128 v[92:95], v[62:63], off
	v_or_b32_e32 v84, s27, v76
	v_cmp_lt_i32_e32 vcc_lo, v78, v77
	s_cmp_eq_u32 s28, 0
	ds_load_b128 v[100:103], v84
	ds_load_b128 v[104:107], v84 offset:32
	global_load_b128 v[96:99], v[62:63], off offset:32
	s_wait_loadcnt_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[42:49], v[92:99], v[100:107], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	global_load_b128 v[92:95], v[62:63], off offset:64
	ds_load_b128 v[100:103], v84 offset:64
	ds_load_b128 v[104:107], v84 offset:96
	global_load_b128 v[96:99], v[62:63], off offset:96
	v_cndmask_b32_e32 v84, v75, v78, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v79, v77
	s_wait_loadcnt_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[42:49], v[92:99], v[100:107], v[42:49]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	v_dual_cndmask_b32 v84, v75, v79 :: v_dual_lshlrev_b32 v103, 2, v84
	v_cmp_lt_i32_e32 vcc_lo, v80, v77
	v_nop
	v_nop
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_lshlrev_b32_e32 v104, 2, v84
	v_cndmask_b32_e32 v84, v75, v80, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v81, v77
	v_dual_cndmask_b32 v84, v75, v81 :: v_dual_lshlrev_b32 v105, 2, v84
	s_cselect_b32 vcc_lo, -1, 0
	s_addk_co_i32 s25, 0x400
	s_cmp_eq_u32 s26, s22
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v106, 2, v84
	v_mul_f32_e32 v84, 0x3e000000, v42
	ds_bpermute_b32 v85, v103, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v84, v84, v85
	ds_bpermute_b32 v85, v104, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v84, v84, v85
	ds_bpermute_b32 v85, v105, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	v_max_num_f32_e32 v84, v84, v85
	ds_bpermute_b32 v85, v106, v84
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v85, v85, v85
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v84, v84, v85 :: v_dual_max_num_f32 v85, v91, v91
	v_max_num_f32_e32 v85, v85, v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v84, v85, v84, vcc_lo
	v_fma_f32 v42, 0x3e000000, v42, -v84
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_sub_f32 v85, v91, v84 :: v_dual_mul_f32 v42, 0x3fb8aa3b, v42
	v_mul_f32_e32 v85, 0x3fb8aa3b, v85
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v42, v42
	v_exp_f32_e32 v88, v85
	v_nop
	s_delay_alu instid0(TRANS32_DEP_2)
	v_cvt_f16_f32_e32 v85, v42
	ds_bpermute_b32 v86, v103, v42
	ds_store_b16 v82, v85
	v_mul_f32_e32 v85, 0x3e000000, v43
	ds_bpermute_b32 v87, v103, v85
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v85, v85, v87
	ds_bpermute_b32 v87, v104, v85
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	v_max_num_f32_e32 v85, v85, v87
	ds_bpermute_b32 v87, v105, v85
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v85, v85, v87
	ds_bpermute_b32 v87, v106, v85
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	v_max_num_f32_e32 v85, v85, v87
	v_max_num_f32_e32 v87, v9, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v87, v87, v85
	v_cndmask_b32_e32 v85, v87, v85, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_fma_f32 v43, 0x3e000000, v43, -v85
	v_sub_f32_e32 v9, v9, v85
	v_mul_f32_e32 v43, 0x3fb8aa3b, v43
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_f32_e32 v9, 0x3fb8aa3b, v9
	v_exp_f32_e32 v43, v43
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v9, v9
	v_cvt_f16_f32_e32 v87, v43
	ds_store_b16 v82, v87 offset:32
	ds_bpermute_b32 v87, v103, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[42:43], v[86:87]
	ds_bpermute_b32 v86, v104, v42
	ds_bpermute_b32 v87, v104, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[42:43], v[86:87]
	ds_bpermute_b32 v86, v105, v42
	ds_bpermute_b32 v87, v105, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[92:93], v[42:43], v[86:87]
	v_cndmask_b32_e64 v43, v9, 0, vcc_lo
	v_mul_f32_e32 v9, 0x3e000000, v44
	v_cndmask_b32_e64 v42, v88, 0, vcc_lo
	ds_bpermute_b32 v94, v106, v92
	ds_bpermute_b32 v95, v106, v93
	ds_bpermute_b32 v86, v103, v9
	v_pk_mul_f32 v[34:35], v[34:35], v[42:43]
	v_pk_mul_f32 v[26:27], v[26:27], v[42:43]
	v_pk_mul_f32 v[18:19], v[18:19], v[42:43]
	v_pk_mul_f32 v[10:11], v[10:11], v[42:43]
	s_wait_dscnt 0x1
	v_pk_add_f32 v[92:93], v[92:93], v[94:95]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v86, v86, v86
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_fma_f32 v[60:61], v[60:61], v[42:43], v[92:93]
	v_max_num_f32_e32 v9, v9, v86
	ds_bpermute_b32 v86, v104, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v86, v86, v86
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v9, v9, v86
	ds_bpermute_b32 v86, v105, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v86, v86, v86
	v_max_num_f32_e32 v9, v9, v86
	ds_bpermute_b32 v86, v106, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v86, v86, v86
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v9, v9, v86 :: v_dual_max_num_f32 v86, v8, v8
	v_max_num_f32_e32 v86, v86, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v86, v86, v9, vcc_lo
	v_sub_f32_e32 v8, v8, v86
	v_fma_f32 v9, 0x3e000000, v44, -v86
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mul_f32 v8, 0x3fb8aa3b, v8 :: v_dual_mul_f32 v9, 0x3fb8aa3b, v9
	v_exp_f32_e32 v88, v8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_exp_f32_e32 v8, v9
	v_nop
	v_cvt_f16_f32_e32 v9, v8
	ds_bpermute_b32 v44, v103, v8
	ds_store_b16 v82, v9 offset:64
	v_mul_f32_e32 v9, 0x3e000000, v45
	ds_bpermute_b32 v87, v103, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v9, v9, v87
	ds_bpermute_b32 v87, v104, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	v_max_num_f32_e32 v9, v9, v87
	ds_bpermute_b32 v87, v105, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v9, v9, v87
	ds_bpermute_b32 v87, v106, v9
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	v_max_num_f32_e32 v9, v9, v87
	v_max_num_f32_e32 v87, v7, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v87, v87, v9
	v_cndmask_b32_e32 v87, v87, v9, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_fma_f32 v9, 0x3e000000, v45, -v87
	v_sub_f32_e32 v7, v7, v87
	v_mul_f32_e32 v9, 0x3fb8aa3b, v9
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v9, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v7, v7
	v_cvt_f16_f32_e32 v45, v9
	ds_store_b16 v82, v45 offset:96
	ds_bpermute_b32 v45, v103, v9
	s_wait_dscnt 0x0
	v_pk_add_f32 v[8:9], v[8:9], v[44:45]
	ds_bpermute_b32 v44, v104, v8
	ds_bpermute_b32 v45, v104, v9
	s_wait_dscnt 0x0
	v_pk_add_f32 v[8:9], v[8:9], v[44:45]
	ds_bpermute_b32 v44, v105, v8
	ds_bpermute_b32 v45, v105, v9
	s_wait_dscnt 0x0
	v_pk_add_f32 v[8:9], v[8:9], v[44:45]
	v_cndmask_b32_e64 v45, v7, 0, vcc_lo
	v_mul_f32_e32 v7, 0x3e000000, v46
	v_cndmask_b32_e64 v44, v88, 0, vcc_lo
	ds_bpermute_b32 v96, v106, v8
	ds_bpermute_b32 v97, v106, v9
	ds_bpermute_b32 v88, v103, v7
	v_pk_mul_f32 v[36:37], v[36:37], v[44:45]
	v_pk_mul_f32 v[28:29], v[28:29], v[44:45]
	v_pk_mul_f32 v[20:21], v[20:21], v[44:45]
	v_pk_mul_f32 v[12:13], v[12:13], v[44:45]
	s_wait_dscnt 0x1
	v_pk_add_f32 v[8:9], v[8:9], v[96:97]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_fma_f32 v[58:59], v[58:59], v[44:45], v[8:9]
	v_dual_max_num_f32 v7, v7, v88 :: v_dual_mov_b32 v8, v6
	v_mov_b32_e32 v9, v6
	ds_bpermute_b32 v88, v104, v7
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v7, v7, v88
	ds_bpermute_b32 v88, v105, v7
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v7, v7, v88
	ds_bpermute_b32 v88, v106, v7
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v7, v7, v88 :: v_dual_max_num_f32 v88, v5, v5
	v_max_num_f32_e32 v88, v88, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v88, v88, v7, vcc_lo
	v_sub_f32_e32 v5, v5, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_mul_f32_e32 v5, 0x3fb8aa3b, v5
	v_fma_f32 v7, 0x3e000000, v46, -v88
	v_exp_f32_e32 v99, v5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v46, v7
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_cvt_f16_f32_e32 v5, v46
	ds_bpermute_b32 v90, v103, v46
	ds_store_b16 v82, v5 offset:128
	v_mul_f32_e32 v5, 0x3e000000, v47
	ds_bpermute_b32 v7, v103, v5
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v5, v5, v7
	ds_bpermute_b32 v7, v104, v5
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	v_max_num_f32_e32 v5, v5, v7
	ds_bpermute_b32 v7, v105, v5
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v5, v5, v7
	ds_bpermute_b32 v7, v106, v5
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	v_dual_max_num_f32 v5, v5, v7 :: v_dual_max_num_f32 v7, v4, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v7, v7, v5
	v_cndmask_b32_e32 v89, v7, v5, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fma_f32 v5, 0x3e000000, v47, -v89
	v_sub_f32_e32 v4, v4, v89
	v_dual_mul_f32 v5, 0x3fb8aa3b, v5 :: v_dual_mul_f32 v4, 0x3fb8aa3b, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v47, v5
	v_exp_f32_e32 v7, v4
	ds_bpermute_b32 v91, v103, v47
	v_nop
	v_cvt_f16_f32_e32 v4, v47
	ds_store_b16 v82, v4 offset:160
	s_wait_dscnt 0x1
	v_pk_add_f32 v[4:5], v[46:47], v[90:91]
	ds_bpermute_b32 v46, v104, v4
	ds_bpermute_b32 v47, v104, v5
	s_wait_dscnt 0x0
	v_pk_add_f32 v[4:5], v[4:5], v[46:47]
	ds_bpermute_b32 v46, v105, v4
	ds_bpermute_b32 v47, v105, v5
	s_wait_dscnt 0x0
	v_pk_add_f32 v[4:5], v[4:5], v[46:47]
	v_cndmask_b32_e64 v47, v7, 0, vcc_lo
	v_mul_f32_e32 v7, 0x3e000000, v48
	v_cndmask_b32_e64 v46, v99, 0, vcc_lo
	ds_bpermute_b32 v98, v106, v4
	ds_bpermute_b32 v99, v106, v5
	ds_bpermute_b32 v90, v103, v7
	v_pk_mul_f32 v[38:39], v[38:39], v[46:47]
	v_pk_mul_f32 v[30:31], v[30:31], v[46:47]
	v_pk_mul_f32 v[22:23], v[22:23], v[46:47]
	v_pk_mul_f32 v[14:15], v[14:15], v[46:47]
	s_wait_dscnt 0x1
	v_pk_add_f32 v[4:5], v[4:5], v[98:99]
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v90, v90, v90
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pk_fma_f32 v[56:57], v[56:57], v[46:47], v[4:5]
	v_max_num_f32_e32 v7, v7, v90
	ds_bpermute_b32 v90, v104, v7
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v90, v90, v90
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v7, v7, v90
	ds_bpermute_b32 v90, v105, v7
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v90, v90, v90
	v_max_num_f32_e32 v7, v7, v90
	ds_bpermute_b32 v90, v106, v7
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v90, v90, v90
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v7, v7, v90
	v_max_num_f32_e32 v90, v3, v3
	v_max_num_f32_e32 v90, v90, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v90, v90, v7, vcc_lo
	v_fma_f32 v7, 0x3e000000, v48, -v90
	v_sub_f32_e32 v3, v3, v90
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v100, v7
	v_exp_f32_e32 v91, v3
	v_nop
	s_delay_alu instid0(TRANS32_DEP_2)
	v_cvt_f16_f32_e32 v3, v100
	ds_bpermute_b32 v102, v103, v100
	ds_store_b16 v82, v3 offset:192
	v_mul_f32_e32 v3, 0x3e000000, v49
	ds_bpermute_b32 v7, v103, v3
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v3, v3, v7
	ds_bpermute_b32 v7, v104, v3
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	v_max_num_f32_e32 v3, v3, v7
	ds_bpermute_b32 v7, v105, v3
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v3, v3, v7
	ds_bpermute_b32 v7, v106, v3
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v7, v7, v7
	v_dual_max_num_f32 v3, v3, v7 :: v_dual_max_num_f32 v7, v2, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v7, v7, v3
	v_cndmask_b32_e32 v48, v7, v3, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_fma_f32 v3, 0x3e000000, v49, -v48
	v_add_nc_u32_e32 v49, s27, v68
	v_dual_mul_f32 v3, 0x3fb8aa3b, v3 :: v_dual_sub_f32 v2, v2, v48
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v101, v3
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v7, v2
	ds_bpermute_b32 v103, v103, v101
	v_nop
	v_cvt_f16_f32_e32 v2, v101
	ds_store_b16 v82, v2 offset:224
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_pk_add_f32 v[2:3], v[100:101], v[102:103]
	v_cndmask_b32_e64 v103, v7, 0, vcc_lo
	v_cndmask_b32_e64 v102, v91, 0, vcc_lo
	v_dual_add_nc_u32 v91, v49, v67 :: v_dual_mov_b32 v7, v6
	ds_bpermute_b32 v100, v104, v2
	ds_bpermute_b32 v101, v104, v3
	v_pk_mul_f32 v[40:41], v[40:41], v[102:103]
	v_pk_mul_f32 v[32:33], v[32:33], v[102:103]
	v_pk_mul_f32 v[24:25], v[24:25], v[102:103]
	v_pk_mul_f32 v[16:17], v[16:17], v[102:103]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[2:3], v[2:3], v[100:101]
	ds_bpermute_b32 v100, v105, v2
	ds_bpermute_b32 v101, v105, v3
	s_wait_dscnt 0x0
	v_pk_add_f32 v[2:3], v[2:3], v[100:101]
	ds_bpermute_b32 v100, v106, v2
	ds_bpermute_b32 v101, v106, v3
	s_wait_dscnt 0x0
	v_pk_add_f32 v[2:3], v[2:3], v[100:101]
	v_dual_add_nc_u32 v100, v49, v70 :: v_dual_add_nc_u32 v101, v49, v71
	v_add_nc_u32_e32 v49, v49, v72
	s_delay_alu instid0(VALU_DEP_3)
	v_pk_fma_f32 v[54:55], v[54:55], v[102:103], v[2:3]
	ds_load_b128 v[2:5], v69
	ds_load_u16 v92, v91
	ds_load_u16 v93, v91 offset:128
	ds_load_u16 v94, v100
	ds_load_u16 v95, v91 offset:384
	ds_load_u16 v96, v101
	ds_load_u16 v97, v91 offset:640
	ds_load_u16 v98, v49
	ds_load_u16 v99, v91 offset:896
	s_wait_dscnt 0x6
	v_perm_b32 v92, v93, v92, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v93, v95, v94, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v94, v97, v96, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v95, v99, v98, 0x5040100
	v_dual_mov_b32 v96, v6 :: v_dual_mov_b32 v97, v6
	v_dual_mov_b32 v98, v6 :: v_dual_mov_b32 v99, v6
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[34:41], v[2:9], v[92:99], v[34:41]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v92, v91 offset:32
	ds_load_u16 v93, v91 offset:160
	ds_load_u16 v94, v100 offset:32
	ds_load_u16 v95, v91 offset:416
	ds_load_u16 v96, v101 offset:32
	ds_load_u16 v97, v91 offset:672
	ds_load_u16 v98, v49 offset:32
	ds_load_u16 v99, v91 offset:928
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v93, v92, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v93, v95, v94, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v94, v97, v96, 0x5040100
	v_mov_b32_e32 v96, v6
	s_wait_dscnt 0x0
	v_perm_b32 v95, v99, v98, 0x5040100
	v_dual_mov_b32 v97, v6 :: v_dual_mov_b32 v98, v6
	v_mov_b32_e32 v99, v6
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[26:33], v[2:9], v[92:99], v[26:33]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v92, v91 offset:64
	ds_load_u16 v93, v91 offset:192
	ds_load_u16 v94, v100 offset:64
	ds_load_u16 v95, v91 offset:448
	ds_load_u16 v96, v101 offset:64
	ds_load_u16 v97, v91 offset:704
	ds_load_u16 v98, v49 offset:64
	ds_load_u16 v99, v91 offset:960
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v93, v92, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v93, v95, v94, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v94, v97, v96, 0x5040100
	v_mov_b32_e32 v96, v6
	s_wait_dscnt 0x0
	v_perm_b32 v95, v99, v98, 0x5040100
	v_dual_mov_b32 v97, v6 :: v_dual_mov_b32 v98, v6
	v_mov_b32_e32 v99, v6
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[92:99], v[18:25]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v92, v91 offset:96
	ds_load_u16 v93, v91 offset:224
	ds_load_u16 v94, v100 offset:96
	ds_load_u16 v95, v91 offset:480
	ds_load_u16 v96, v101 offset:96
	ds_load_u16 v97, v91 offset:736
	ds_load_u16 v49, v49 offset:96
	ds_load_u16 v91, v91 offset:992
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v92, v93, v92, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v93, v95, v94, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v94, v97, v96, 0x5040100
	v_mov_b32_e32 v96, v6
	s_wait_dscnt 0x0
	v_perm_b32 v95, v91, v49, 0x5040100
	v_mov_b32_e32 v97, v6
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[10:17], v[2:9], v[92:99], v[10:17]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_scc1 .LBB0_20
; %bb.18:                               ;   in Loop: Header=BB0_13 Depth=2
	v_dual_mov_b32 v91, v84 :: v_dual_mov_b32 v9, v85
	v_dual_mov_b32 v8, v86 :: v_dual_mov_b32 v7, v87
	v_dual_mov_b32 v5, v88 :: v_dual_mov_b32 v4, v89
	v_dual_mov_b32 v3, v90 :: v_dual_mov_b32 v2, v48
	s_mov_b32 s28, s26
	s_branch .LBB0_13
.LBB0_19:                               ;   in Loop: Header=BB0_3 Depth=1
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v90, 0
	v_dual_mov_b32 v89, 0 :: v_dual_mov_b32 v88, 0
	v_dual_mov_b32 v87, 0 :: v_dual_mov_b32 v86, 0
	v_dual_mov_b32 v85, 0 :: v_dual_mov_b32 v84, 0
	s_delay_alu instid0(VALU_DEP_4)
	v_dual_mov_b32 v55, 0 :: v_dual_mov_b32 v54, v48
	v_dual_mov_b32 v57, 0 :: v_dual_mov_b32 v56, v48
	v_dual_mov_b32 v59, 0 :: v_dual_mov_b32 v58, v48
	v_dual_mov_b32 v61, 0 :: v_dual_mov_b32 v60, v48
	v_dual_mov_b32 v41, 0 :: v_dual_mov_b32 v40, v48
	v_dual_mov_b32 v39, v48 :: v_dual_mov_b32 v38, v48
	v_dual_mov_b32 v37, v48 :: v_dual_mov_b32 v36, v48
	v_dual_mov_b32 v35, v48 :: v_dual_mov_b32 v34, v48
	v_dual_mov_b32 v33, 0 :: v_dual_mov_b32 v32, v48
	v_dual_mov_b32 v31, v48 :: v_dual_mov_b32 v30, v48
	v_dual_mov_b32 v29, v48 :: v_dual_mov_b32 v28, v48
	v_dual_mov_b32 v27, v48 :: v_dual_mov_b32 v26, v48
	v_dual_mov_b32 v25, 0 :: v_dual_mov_b32 v24, v48
	v_dual_mov_b32 v23, v48 :: v_dual_mov_b32 v22, v48
	v_dual_mov_b32 v21, v48 :: v_dual_mov_b32 v20, v48
	v_dual_mov_b32 v19, v48 :: v_dual_mov_b32 v18, v48
	v_dual_mov_b32 v17, 0 :: v_dual_mov_b32 v16, v48
	v_dual_mov_b32 v15, v48 :: v_dual_mov_b32 v14, v48
	v_dual_mov_b32 v13, v48 :: v_dual_mov_b32 v12, v48
	v_dual_mov_b32 v11, v48 :: v_dual_mov_b32 v10, v48
.LBB0_20:                               ;   in Loop: Header=BB0_3 Depth=1
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v2, v83, v66
	v_rcp_f32_e32 v4, v60
	s_xor_b32 s24, s24, -1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_add_nc_u32_e32 v3, s19, v2
	v_fma_mixlo_f16 v5, v34, v4, 0
	v_fma_mixlo_f16 v8, v26, v4, 0
	s_delay_alu instid0(VALU_DEP_3)
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
	v_log_f32_e32 v4, v60
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v84, 0x3f317218, v4
	global_store_b32 v3, v84, s[10:11] scale_offset
.LBB0_22:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v61
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
	v_log_f32_e32 v4, v61
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v85, 0x3f317218, v4
	global_store_b32 v3, v85, s[10:11] scale_offset
.LBB0_24:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v58
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
	v_log_f32_e32 v4, v58
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v86, 0x3f317218, v4
	global_store_b32 v3, v86, s[10:11] scale_offset
.LBB0_26:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v59
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
	v_log_f32_e32 v4, v59
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v87, 0x3f317218, v4
	global_store_b32 v3, v87, s[10:11] scale_offset
.LBB0_28:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v56
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
	v_log_f32_e32 v4, v56
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v88, 0x3f317218, v4
	global_store_b32 v3, v88, s[10:11] scale_offset
.LBB0_30:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v57
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
	v_log_f32_e32 v4, v57
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v89, 0x3f317218, v4
	global_store_b32 v3, v89, s[10:11] scale_offset
.LBB0_32:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v4, v54
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
	v_log_f32_e32 v4, v54
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v90, 0x3f317218, v4
	global_store_b32 v3, v90, s[10:11] scale_offset
.LBB0_34:                               ;   in Loop: Header=BB0_3 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s25
	v_rcp_f32_e32 v3, v55
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
	v_log_f32_e32 v3, v55
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fmac_f32_e32 v48, 0x3f317218, v3
	global_store_b32 v2, v48, s[10:11] scale_offset
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
		.amdhsa_next_free_vgpr 108
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
		.amdhsa_inst_pref_size 47
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
	.set flash_attention_original.num_vgpr, 108
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
; codeLenInByte = 6000
; TotalNumSgprs: 32
; NumVgprs: 108
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 10240 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 32
; NumVGPRsForWavesPerEU: 108
; NamedBarCnt: 0
; Occupancy: 9
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
	v_lshl_or_b32 v59, v0, 1, 0x1000
	s_cselect_b32 s12, s12, s13
	s_cselect_b32 s13, s16, s17
	s_lshl_b32 s12, s12, 14
	s_lshl_b32 s13, s13, 10
	v_dual_mov_b32 v1, v59 :: v_dual_mov_b32 v2, v0
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
	v_dual_lshrrev_b32 v1, 5, v0 :: v_dual_lshrrev_b32 v2, 1, v0
	s_mul_i32 s15, ttmp9, s15
	v_dual_lshlrev_b32 v3, 5, v0 :: v_dual_bitop2_b32 v58, 15, v0 bitop3:0x40
	s_add_co_i32 s16, s16, s15
	s_cmp_eq_u32 s14, 0
	v_and_b32_e32 v60, 8, v2
	s_cselect_b32 s14, ttmp9, s16
	v_dual_lshlrev_b32 v5, 1, v58 :: v_dual_bitop2_b32 v62, s12, v58 bitop3:0x54
	s_lshl_b32 s14, s14, 7
	v_and_b32_e32 v4, 0x1e0, v3
	v_lshl_or_b32 v61, v1, 4, s14
	v_dual_lshlrev_b32 v1, 9, v1 :: v_dual_lshlrev_b32 v6, 1, v60
	v_dual_mov_b32 v36, 0 :: v_dual_lshlrev_b32 v7, 7, v58
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_add_nc_u32_e32 v2, v62, v61
	v_mbcnt_lo_u32_b32 v63, -1, 0
	v_dual_mov_b32 v3, v36 :: v_dual_bitop2_b32 v8, v1, v5 bitop3:0x54
	v_or3_b32 v64, v1, v4, v6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_lshl_or_b32 v2, v2, 6, v60
	v_dual_lshlrev_b32 v4, 5, v60 :: v_dual_bitop2_b32 v1, 16, v63 bitop3:0x40
	v_dual_mov_b32 v53, v36 :: v_dual_lshlrev_b32 v70, 7, v60
	v_or_b32_e32 v65, 0x2000, v5
	s_delay_alu instid0(VALU_DEP_4)
	v_lshl_add_u64 v[54:55], v[2:3], 1, s[4:5]
	v_or3_b32 v66, v7, v6, 0x1000
	v_or_b32_e32 v67, 0xffffff00, v0
	v_dual_add_nc_u32 v68, 16, v1 :: v_dual_add_nc_u32 v69, v8, v4
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
	v_dual_mov_b32 v27, v36 :: v_dual_mov_b32 v28, v36
	v_dual_mov_b32 v29, v36 :: v_dual_mov_b32 v30, v36
	v_dual_mov_b32 v31, v36 :: v_dual_mov_b32 v46, 0
	v_dual_mov_b32 v47, v36 :: v_dual_mov_b32 v52, 0
	v_dual_mov_b32 v50, 0 :: v_dual_mov_b32 v51, v36
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v49, v36
	v_or_b32_e32 v71, 0x100, v70
	v_or_b32_e32 v72, 0x200, v70
	v_or_b32_e32 v73, 0x300, v70
	v_dual_mov_b32 v57, 0 :: v_dual_bitop2_b32 v74, 8, v63 bitop3:0x14
	v_dual_mov_b32 v56, 0 :: v_dual_bitop2_b32 v75, 4, v63 bitop3:0x14
	v_dual_mov_b32 v98, 0 :: v_dual_bitop2_b32 v76, 2, v63 bitop3:0x14
	v_dual_mov_b32 v97, 0 :: v_dual_bitop2_b32 v77, 1, v63 bitop3:0x14
	v_dual_mov_b32 v96, 0 :: v_dual_mov_b32 v95, 0
	v_dual_mov_b32 v94, 0 :: v_dual_mov_b32 v32, 0
	s_mov_b32 s14, 0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB1_4
.LBB1_3:                                ;   in Loop: Header=BB1_4 Depth=1
	s_lshl_b32 s5, s5, 11
	global_load_b128 v[78:81], v[54:55], off
	v_nop
	v_add_nc_u32_e32 v33, s5, v66
	v_cmp_lt_i32_e32 vcc_lo, v74, v68
	s_add_co_i32 s4, s14, 1
	s_cmp_eq_u32 s14, 0
	ds_load_b128 v[86:89], v33
	ds_load_b128 v[90:93], v33 offset:32
	global_load_b128 v[82:85], v[54:55], off offset:32
	s_wait_loadcnt_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[38:45], v[78:85], v[86:93], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	global_load_b128 v[78:81], v[54:55], off offset:64
	ds_load_b128 v[86:89], v33 offset:64
	ds_load_b128 v[90:93], v33 offset:96
	global_load_b128 v[82:85], v[54:55], off offset:96
	v_lshl_add_u32 v33, s14, 4, v62
	s_mov_b32 s14, s4
	s_wait_loadcnt_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[38:45], v[78:85], v[86:93], v[38:45]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	global_load_b32 v33, v33, s[10:11] scale_offset
	s_wait_loadcnt 0x0
	v_nop
	v_nop
	v_nop
	v_nop
	v_mul_f32_e32 v93, 0xbfb8aa3b, v33
	v_cndmask_b32_e32 v33, v63, v74, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v75, v68
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_lshlrev_b32_e32 v34, 2, v33
	v_dual_fmamk_f32 v38, v38, 0x3e38aa3b, v93 :: v_dual_fmamk_f32 v39, v39, 0x3e38aa3b, v93
	ds_bpermute_b32 v78, v34, v38
	v_cndmask_b32_e32 v33, v63, v75, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v76, v68
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_dual_max_num_f32 v78, v78, v78 :: v_dual_lshlrev_b32 v35, 2, v33
	v_cndmask_b32_e32 v33, v63, v76, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v77, v68
	v_dual_max_num_f32 v78, v38, v78 :: v_dual_lshlrev_b32 v37, 2, v33
	v_cndmask_b32_e32 v33, v63, v77, vcc_lo
	s_cselect_b32 vcc_lo, -1, 0
	ds_bpermute_b32 v79, v35, v78
	s_addk_co_i32 s13, 0x400
	s_cmp_eq_u32 s4, 64
	s_wait_dscnt 0x0
	v_dual_lshlrev_b32 v33, 2, v33 :: v_dual_max_num_f32 v79, v79, v79
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v78, v78, v79
	ds_bpermute_b32 v79, v37, v78
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v79, v79, v79
	v_max_num_f32_e32 v78, v78, v79
	ds_bpermute_b32 v79, v33, v78
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v79, v79, v79
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v79, v78, v79 :: v_dual_max_num_f32 v78, v57, v57
	v_max_num_f32_e32 v78, v78, v79
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v80, v78, v79, vcc_lo
	v_dual_sub_f32 v38, v38, v80 :: v_dual_sub_f32 v57, v57, v80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v38, v38
	v_exp_f32_e32 v84, v57
	v_nop
	s_delay_alu instid0(TRANS32_DEP_2)
	v_cvt_f16_f32_e32 v57, v38
	ds_bpermute_b32 v82, v34, v38
	ds_store_b16 v69, v57
	ds_bpermute_b32 v57, v34, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v57, v57, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v39, v57
	ds_bpermute_b32 v79, v35, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v79, v79, v79
	v_max_num_f32_e32 v57, v57, v79
	ds_bpermute_b32 v79, v37, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v79, v79, v79
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v57, v79
	ds_bpermute_b32 v79, v33, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v79, v79, v79
	v_dual_max_num_f32 v57, v57, v79 :: v_dual_max_num_f32 v79, v56, v56
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v79, v79, v57
	v_cndmask_b32_e32 v81, v79, v57, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_sub_f32 v56, v56, v81 :: v_dual_sub_f32 v39, v39, v81
	v_exp_f32_e32 v85, v56
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v39, v39
	ds_bpermute_b32 v83, v34, v39
	v_nop
	v_cvt_f16_f32_e32 v56, v39
	ds_store_b16 v69, v56 offset:32
	s_wait_dscnt 0x1
	v_pk_add_f32 v[38:39], v[38:39], v[82:83]
	ds_bpermute_b32 v56, v35, v38
	ds_bpermute_b32 v57, v35, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[56:57]
	ds_bpermute_b32 v56, v37, v38
	ds_bpermute_b32 v57, v37, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[56:57]
	v_cndmask_b32_e64 v57, v85, 0, vcc_lo
	v_cndmask_b32_e64 v56, v84, 0, vcc_lo
	ds_bpermute_b32 v82, v33, v38
	ds_bpermute_b32 v83, v33, v39
	v_pk_mul_f32 v[24:25], v[24:25], v[56:57]
	v_pk_mul_f32 v[16:17], v[16:17], v[56:57]
	v_pk_mul_f32 v[8:9], v[8:9], v[56:57]
	v_pk_mul_f32 v[0:1], v[0:1], v[56:57]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[82:83]
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_fma_f32 v[52:53], v[52:53], v[56:57], v[38:39]
	v_fmamk_f32 v38, v40, 0x3e38aa3b, v93
	v_mov_b32_e32 v57, v80
	ds_bpermute_b32 v39, v34, v38
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v38, v39
	ds_bpermute_b32 v40, v35, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v40, v40, v40
	v_max_num_f32_e32 v39, v39, v40
	ds_bpermute_b32 v40, v37, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v40, v40, v40
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v40
	ds_bpermute_b32 v40, v33, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v40, v40, v40
	v_dual_max_num_f32 v39, v39, v40 :: v_dual_max_num_f32 v40, v98, v98
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v82, v40, v39
	v_cndmask_b32_e32 v84, v82, v39, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_sub_f32_e32 v38, v38, v84
	v_sub_f32_e32 v39, v98, v84
	v_exp_f32_e32 v38, v38
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v85, v39
	v_nop
	v_cvt_f16_f32_e32 v39, v38
	ds_bpermute_b32 v40, v34, v38
	ds_store_b16 v69, v39 offset:64
	v_fmamk_f32 v39, v41, 0x3e38aa3b, v93
	v_mov_b32_e32 v56, v81
	ds_bpermute_b32 v41, v34, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v41, v41, v41
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v41, v39, v41
	ds_bpermute_b32 v83, v35, v41
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v83, v83, v83
	v_max_num_f32_e32 v41, v41, v83
	ds_bpermute_b32 v83, v37, v41
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v83, v83, v83
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v41, v41, v83
	ds_bpermute_b32 v83, v33, v41
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v83, v83, v83
	v_max_num_f32_e32 v41, v41, v83
	v_max_num_f32_e32 v83, v97, v97
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v83, v83, v41
	v_cndmask_b32_e32 v86, v83, v41, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_sub_f32 v39, v39, v86 :: v_dual_sub_f32 v41, v97, v86
	v_exp_f32_e32 v39, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v87, v41
	v_nop
	v_cvt_f16_f32_e32 v41, v39
	ds_store_b16 v69, v41 offset:96
	ds_bpermute_b32 v41, v34, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[40:41]
	ds_bpermute_b32 v40, v35, v38
	ds_bpermute_b32 v41, v35, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[40:41]
	ds_bpermute_b32 v40, v37, v38
	ds_bpermute_b32 v41, v37, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[40:41]
	v_cndmask_b32_e64 v41, v87, 0, vcc_lo
	v_cndmask_b32_e64 v40, v85, 0, vcc_lo
	ds_bpermute_b32 v88, v33, v38
	ds_bpermute_b32 v89, v33, v39
	v_pk_mul_f32 v[26:27], v[26:27], v[40:41]
	v_pk_mul_f32 v[18:19], v[18:19], v[40:41]
	v_pk_mul_f32 v[10:11], v[10:11], v[40:41]
	v_pk_mul_f32 v[2:3], v[2:3], v[40:41]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[88:89]
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_pk_fma_f32 v[50:51], v[50:51], v[40:41], v[38:39]
	v_fmamk_f32 v38, v42, 0x3e38aa3b, v93
	ds_bpermute_b32 v39, v34, v38
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	v_max_num_f32_e32 v39, v38, v39
	ds_bpermute_b32 v42, v35, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v42, v42, v42
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v42
	ds_bpermute_b32 v42, v37, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v42, v42, v42
	v_max_num_f32_e32 v39, v39, v42
	ds_bpermute_b32 v42, v33, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v42, v42, v42
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v39, v39, v42 :: v_dual_max_num_f32 v42, v96, v96
	v_max_num_f32_e32 v85, v42, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v89, v85, v39, vcc_lo
	v_dual_sub_f32 v38, v38, v89 :: v_dual_sub_f32 v39, v96, v89
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v38, v38
	v_exp_f32_e32 v88, v39
	v_nop
	s_delay_alu instid0(TRANS32_DEP_2)
	v_cvt_f16_f32_e32 v39, v38
	ds_bpermute_b32 v42, v34, v38
	ds_store_b16 v69, v39 offset:128
	v_fmamk_f32 v39, v43, 0x3e38aa3b, v93
	ds_bpermute_b32 v43, v34, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v43, v43, v43
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v43, v39, v43
	ds_bpermute_b32 v87, v35, v43
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	v_max_num_f32_e32 v43, v43, v87
	ds_bpermute_b32 v87, v37, v43
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v43, v43, v87
	ds_bpermute_b32 v87, v33, v43
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v87, v87, v87
	v_max_num_f32_e32 v43, v43, v87
	v_max_num_f32_e32 v87, v95, v95
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v87, v87, v43
	v_cndmask_b32_e32 v90, v87, v43, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_sub_f32_e32 v39, v39, v90
	v_sub_f32_e32 v43, v95, v90
	v_exp_f32_e32 v39, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v91, v43
	v_nop
	v_cvt_f16_f32_e32 v43, v39
	ds_store_b16 v69, v43 offset:160
	ds_bpermute_b32 v43, v34, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[42:43]
	ds_bpermute_b32 v42, v35, v38
	ds_bpermute_b32 v43, v35, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[42:43]
	ds_bpermute_b32 v42, v37, v38
	ds_bpermute_b32 v43, v37, v39
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[42:43]
	v_cndmask_b32_e64 v43, v91, 0, vcc_lo
	v_cndmask_b32_e64 v42, v88, 0, vcc_lo
	ds_bpermute_b32 v96, v33, v38
	ds_bpermute_b32 v97, v33, v39
	v_pk_mul_f32 v[28:29], v[28:29], v[42:43]
	v_pk_mul_f32 v[20:21], v[20:21], v[42:43]
	v_pk_mul_f32 v[12:13], v[12:13], v[42:43]
	v_pk_mul_f32 v[4:5], v[4:5], v[42:43]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[38:39], v[38:39], v[96:97]
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_pk_fma_f32 v[48:49], v[48:49], v[42:43], v[38:39]
	v_dual_fmamk_f32 v38, v44, 0x3e38aa3b, v93 :: v_dual_fmac_f32 v93, 0x3e38aa3b, v45
	ds_bpermute_b32 v39, v34, v38
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	v_max_num_f32_e32 v39, v38, v39
	ds_bpermute_b32 v44, v35, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v44, v44, v44
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v44
	ds_bpermute_b32 v44, v37, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v44, v44, v44
	v_max_num_f32_e32 v39, v39, v44
	ds_bpermute_b32 v44, v33, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v44, v44, v44
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v39, v39, v44 :: v_dual_max_num_f32 v44, v94, v94
	v_max_num_f32_e32 v88, v44, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v91, v88, v39, vcc_lo
	v_sub_f32_e32 v38, v38, v91
	v_sub_f32_e32 v39, v94, v91
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v38, v38
	v_exp_f32_e32 v94, v39
	v_nop
	s_delay_alu instid0(TRANS32_DEP_2)
	v_cvt_f16_f32_e32 v39, v38
	ds_bpermute_b32 v44, v34, v38
	ds_store_b16 v69, v39 offset:192
	ds_bpermute_b32 v39, v34, v93
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v39, v39, v39
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v93, v39
	ds_bpermute_b32 v45, v35, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v45, v45, v45
	v_max_num_f32_e32 v39, v39, v45
	ds_bpermute_b32 v45, v37, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v45, v45, v45
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v39, v39, v45
	ds_bpermute_b32 v45, v33, v39
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v45, v45, v45
	v_dual_max_num_f32 v39, v39, v45 :: v_dual_max_num_f32 v45, v32, v32
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v92, v45, v39
	v_cndmask_b32_e32 v102, v92, v39, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_sub_f32 v39, v93, v102 :: v_dual_sub_f32 v32, v32, v102
	v_exp_f32_e32 v39, v39
	s_delay_alu instid0(VALU_DEP_1)
	v_exp_f32_e32 v93, v32
	ds_bpermute_b32 v45, v34, v39
	v_nop
	v_cvt_f16_f32_e32 v32, v39
	ds_store_b16 v69, v32 offset:224
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_pk_add_f32 v[38:39], v[38:39], v[44:45]
	v_cndmask_b32_e64 v45, v93, 0, vcc_lo
	v_add_nc_u32_e32 v93, s5, v65
	v_cndmask_b32_e64 v44, v94, 0, vcc_lo
	ds_bpermute_b32 v34, v35, v38
	ds_bpermute_b32 v35, v35, v39
	v_dual_add_nc_u32 v103, v93, v70 :: v_dual_add_nc_u32 v104, v93, v71
	v_dual_add_nc_u32 v105, v93, v72 :: v_dual_add_nc_u32 v93, v93, v73
	v_pk_mul_f32 v[30:31], v[30:31], v[44:45]
	v_pk_mul_f32 v[22:23], v[22:23], v[44:45]
	v_pk_mul_f32 v[14:15], v[14:15], v[44:45]
	v_pk_mul_f32 v[6:7], v[6:7], v[44:45]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[34:35], v[38:39], v[34:35]
	ds_bpermute_b32 v38, v37, v34
	ds_bpermute_b32 v39, v37, v35
	v_mov_b32_e32 v37, v36
	s_wait_dscnt 0x0
	v_pk_add_f32 v[34:35], v[34:35], v[38:39]
	v_dual_mov_b32 v38, v36 :: v_dual_mov_b32 v39, v36
	ds_bpermute_b32 v32, v33, v34
	ds_bpermute_b32 v33, v33, v35
	s_wait_dscnt 0x0
	v_pk_add_f32 v[32:33], v[34:35], v[32:33]
	s_delay_alu instid0(VALU_DEP_1)
	v_pk_fma_f32 v[46:47], v[46:47], v[44:45], v[32:33]
	ds_load_b128 v[32:35], v64
	ds_load_u16 v94, v103
	ds_load_u16 v95, v103 offset:128
	ds_load_u16 v96, v104
	ds_load_u16 v97, v103 offset:384
	ds_load_u16 v98, v105
	ds_load_u16 v99, v103 offset:640
	ds_load_u16 v100, v93
	ds_load_u16 v101, v103 offset:896
	s_wait_dscnt 0x6
	v_perm_b32 v94, v95, v94, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v95, v97, v96, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v96, v99, v98, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v97, v101, v100, 0x5040100
	v_dual_mov_b32 v98, v36 :: v_dual_mov_b32 v99, v36
	v_dual_mov_b32 v100, v36 :: v_dual_mov_b32 v101, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[94:101], v[24:31]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v94, v103 offset:32
	ds_load_u16 v95, v103 offset:160
	ds_load_u16 v96, v104 offset:32
	ds_load_u16 v97, v103 offset:416
	ds_load_u16 v98, v105 offset:32
	ds_load_u16 v99, v103 offset:672
	ds_load_u16 v100, v93 offset:32
	ds_load_u16 v101, v103 offset:928
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v94, v95, v94, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v95, v97, v96, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v96, v99, v98, 0x5040100
	v_dual_mov_b32 v98, v36 :: v_dual_mov_b32 v99, v36
	s_wait_dscnt 0x0
	v_perm_b32 v97, v101, v100, 0x5040100
	v_dual_mov_b32 v100, v36 :: v_dual_mov_b32 v101, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[94:101], v[16:23]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v94, v103 offset:64
	ds_load_u16 v95, v103 offset:192
	ds_load_u16 v96, v104 offset:64
	ds_load_u16 v97, v103 offset:448
	ds_load_u16 v98, v105 offset:64
	ds_load_u16 v99, v103 offset:704
	ds_load_u16 v100, v93 offset:64
	ds_load_u16 v101, v103 offset:960
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v94, v95, v94, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v95, v97, v96, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v96, v99, v98, 0x5040100
	v_dual_mov_b32 v98, v36 :: v_dual_mov_b32 v99, v36
	s_wait_dscnt 0x0
	v_perm_b32 v97, v101, v100, 0x5040100
	v_dual_mov_b32 v100, v36 :: v_dual_mov_b32 v101, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[94:101], v[8:15]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v94, v103 offset:96
	ds_load_u16 v95, v103 offset:224
	ds_load_u16 v96, v104 offset:96
	ds_load_u16 v97, v103 offset:480
	ds_load_u16 v98, v105 offset:96
	ds_load_u16 v99, v103 offset:736
	ds_load_u16 v93, v93 offset:96
	ds_load_u16 v100, v103 offset:992
	s_wait_dscnt 0x6
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v94, v95, v94, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v95, v97, v96, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v96, v99, v98, 0x5040100
	v_dual_mov_b32 v98, v36 :: v_dual_mov_b32 v99, v36
	s_wait_dscnt 0x0
	v_perm_b32 v97, v100, v93, 0x5040100
	v_mov_b32_e32 v100, v36
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[94:101], v[0:7]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	v_dual_mov_b32 v98, v84 :: v_dual_mov_b32 v97, v86
	v_dual_mov_b32 v96, v89 :: v_dual_mov_b32 v95, v90
	v_dual_mov_b32 v94, v91 :: v_dual_mov_b32 v32, v102
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_scc1 .LBB1_8
.LBB1_4:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_6 Depth 2
	s_and_b32 s5, s14, 1
	s_cmp_eq_u32 s14, 63
	s_cbranch_scc1 .LBB1_3
; %bb.5:                                ;   in Loop: Header=BB1_4 Depth=1
	s_lshl_b32 s4, s5, 11
	v_nop
	v_mov_b32_e32 v34, v67
	v_xad_u32 v33, 0x800, s4, v59
	s_mov_b32 s4, 0
.LBB1_6:                                ;   Parent Loop BB1_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_2)
	v_add3_u32 v35, s13, v34, 0x500
	v_add_nc_u32_e32 v34, 0x100, v34
	s_clause 0x1
	global_load_u16 v37, v35, s[6:7] scale_offset
	global_load_u16 v38, v35, s[8:9] scale_offset
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v34
	s_wait_loadcnt 0x1
	ds_store_b16 v33, v37
	s_wait_loadcnt 0x0
	ds_store_b16 v33, v38 offset:4096
	v_add_nc_u32_e32 v33, 0x200, v33
	s_or_b32 s4, vcc_lo, s4
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s4
	s_cbranch_execnz .LBB1_6
; %bb.7:                                ;   in Loop: Header=BB1_4 Depth=1
	s_or_b32 exec_lo, exec_lo, s4
	s_branch .LBB1_3
.LBB1_8:
	v_nop
	v_or_b32_e32 v32, v61, v60
	v_rcp_f32_e32 v34, v52
	v_cmp_eq_u32_e32 vcc_lo, 0, v58
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_add_nc_u32_e32 v33, s12, v32
	v_fma_mixlo_f16 v24, v34, v24, 0
	v_fma_mixlo_f16 v16, v34, v16, 0
	s_delay_alu instid0(VALU_DEP_3)
	v_lshl_or_b32 v35, v33, 6, v58
	v_fma_mixlo_f16 v8, v34, v8, 0
	v_fma_mixlo_f16 v0, v34, v0, 0
	s_clause 0x3
	global_store_b16 v35, v24, s[2:3] scale_offset
	global_store_b16 v35, v16, s[2:3] offset:32 scale_offset
	global_store_b16 v35, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v35, v0, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_10
; %bb.9:
	global_load_b32 v0, v33, s[10:11] scale_offset
	v_log_f32_e32 v8, v52
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v78, v8
	s_wait_loadcnt 0x0
	v_fmamk_f32 v0, v8, 0x3f317218, v0
	global_store_b32 v33, v0, s[0:1] scale_offset
.LBB1_10:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v8, v53
	v_add3_u32 v0, s12, v32, 1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v16, v0, 6, v58
	v_fma_mixlo_f16 v24, v8, v25, 0
	v_fma_mixlo_f16 v17, v8, v17, 0
	v_fma_mixlo_f16 v9, v8, v9, 0
	v_fma_mixlo_f16 v1, v8, v1, 0
	s_clause 0x3
	global_store_b16 v16, v24, s[2:3] scale_offset
	global_store_b16 v16, v17, s[2:3] offset:32 scale_offset
	global_store_b16 v16, v9, s[2:3] offset:64 scale_offset
	global_store_b16 v16, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_12
; %bb.11:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v8, v53
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v8, v79, v8
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v8, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_12:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v50
	v_add3_u32 v0, s12, v32, 2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v8, v0, 6, v58
	v_fma_mixlo_f16 v9, v1, v26, 0
	v_fma_mixlo_f16 v16, v1, v18, 0
	v_fma_mixlo_f16 v10, v1, v10, 0
	v_fma_mixlo_f16 v1, v1, v2, 0
	s_clause 0x3
	global_store_b16 v8, v9, s[2:3] scale_offset
	global_store_b16 v8, v16, s[2:3] offset:32 scale_offset
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
	v_add_f32_e32 v2, v82, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_14:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v51
	v_add3_u32 v0, s12, v32, 3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v58
	v_fma_mixlo_f16 v8, v1, v27, 0
	v_fma_mixlo_f16 v9, v1, v19, 0
	v_fma_mixlo_f16 v10, v1, v11, 0
	v_fma_mixlo_f16 v1, v1, v3, 0
	s_clause 0x3
	global_store_b16 v2, v8, s[2:3] scale_offset
	global_store_b16 v2, v9, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v10, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_16
; %bb.15:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v51
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v83, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_16:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v48
	v_add3_u32 v0, s12, v32, 4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v58
	v_fma_mixlo_f16 v3, v1, v28, 0
	v_fma_mixlo_f16 v8, v1, v20, 0
	v_fma_mixlo_f16 v9, v1, v12, 0
	v_fma_mixlo_f16 v1, v1, v4, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v9, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_18
; %bb.17:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v48
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v85, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_18:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v49
	v_add3_u32 v0, s12, v32, 5
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v58
	v_fma_mixlo_f16 v3, v1, v29, 0
	v_fma_mixlo_f16 v4, v1, v21, 0
	v_fma_mixlo_f16 v8, v1, v13, 0
	v_fma_mixlo_f16 v1, v1, v5, 0
	s_clause 0x3
	global_store_b16 v2, v3, s[2:3] scale_offset
	global_store_b16 v2, v4, s[2:3] offset:32 scale_offset
	global_store_b16 v2, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v2, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_20
; %bb.19:
	global_load_b32 v1, v0, s[10:11] scale_offset
	v_log_f32_e32 v2, v49
	v_nop
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_add_f32_e32 v2, v87, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_20:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v46
	v_add3_u32 v0, s12, v32, 6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v58
	v_fma_mixlo_f16 v3, v1, v30, 0
	v_fma_mixlo_f16 v4, v1, v22, 0
	v_fma_mixlo_f16 v5, v1, v14, 0
	v_fma_mixlo_f16 v1, v1, v6, 0
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
	v_add_f32_e32 v2, v88, v2
	s_wait_loadcnt 0x0
	v_fmamk_f32 v1, v2, 0x3f317218, v1
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_22:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_rcp_f32_e32 v1, v47
	v_add3_u32 v0, s12, v32, 7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_lshl_or_b32 v2, v0, 6, v58
	v_fma_mixlo_f16 v3, v1, v31, 0
	v_fma_mixlo_f16 v4, v1, v23, 0
	v_fma_mixlo_f16 v5, v1, v15, 0
	v_fma_mixlo_f16 v1, v1, v7, 0
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
	v_add_f32_e32 v2, v92, v2
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
		.amdhsa_next_free_vgpr 106
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
.Lfunc_end1:
	.size	forgetting_attention_original, .Lfunc_end1-forgetting_attention_original
                                        ; -- End function
	.set forgetting_attention_original.num_vgpr, 106
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
; codeLenInByte = 5308
; TotalNumSgprs: 20
; NumVgprs: 106
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 12288 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 20
; NumVGPRsForWavesPerEU: 106
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
	v_lshl_or_b32 v60, v0, 1, 0x1000
	s_cselect_b32 s16, s16, s17
	s_cselect_b32 s13, s13, s14
	s_lshl_b32 s15, s16, 1
	s_lshr_b32 s14, s13, 3
	v_dual_mov_b32 v1, v60 :: v_dual_mov_b32 v2, v0
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
	s_bfe_u32 s17, ttmp6, 0x4000c
	s_lshl_b32 s16, s16, 4
	s_add_co_i32 s17, s17, 1
	s_and_b32 s18, ttmp6, 15
	s_mul_i32 s17, ttmp9, s17
	s_add_co_i32 s19, s16, s13
	s_add_co_i32 s18, s18, s17
	s_cmp_eq_u32 s12, 0
	v_dual_lshrrev_b32 v1, 5, v0 :: v_dual_bitop2_b32 v61, 15, v0 bitop3:0x40
	s_cselect_b32 s12, ttmp9, s18
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_lshlrev_b32 v3, 5, v0
	s_lshl_b32 s16, s12, 7
	s_lshl_b32 s17, s19, 3
	v_lshl_or_b32 v62, v1, 4, s16
	s_mov_b32 s13, 0
	s_add_co_i32 s12, s17, s12
	v_dual_lshlrev_b32 v1, 9, v1 :: v_dual_bitop2_b32 v63, 8, v2 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v6, 1, v61 :: v_dual_bitop2_b32 v4, v62, v61 bitop3:0x54
	s_lshl_b64 s[16:17], s[12:13], 2
	s_lshl_b32 s12, s19, 16
	v_mov_b32_e32 v36, 0
	v_lshl_add_u32 v2, v4, 6, s12
	v_and_b32_e32 v5, 0x1e0, v3
	v_dual_lshlrev_b32 v7, 1, v63 :: v_dual_lshlrev_b32 v8, 7, v61
	v_mbcnt_lo_u32_b32 v64, -1, 0
	v_or_b32_e32 v4, v1, v6
	v_dual_mov_b32 v3, v36 :: v_dual_bitop2_b32 v2, v2, v63 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_or3_b32 v65, v1, v5, v7
	v_dual_lshlrev_b32 v5, 5, v63 :: v_dual_bitop2_b32 v1, 16, v64 bitop3:0x40
	v_dual_mov_b32 v55, v36 :: v_dual_lshlrev_b32 v71, 7, v63
	s_delay_alu instid0(VALU_DEP_4)
	v_add_nc_u64_e32 v[50:51], s[4:5], v[2:3]
	v_or_b32_e32 v66, 0x2000, v6
	v_or3_b32 v67, v8, v7, 0x1000
	v_or_b32_e32 v68, 0xffffff00, v0
	v_dual_mov_b32 v0, v36 :: v_dual_add_nc_u32 v69, 16, v1
	v_dual_add_nc_u32 v70, v4, v5 :: v_dual_mov_b32 v46, 0
	v_dual_mov_b32 v1, v36 :: v_dual_mov_b32 v2, v36
	v_dual_mov_b32 v4, v36 :: v_dual_mov_b32 v5, v36
	v_dual_mov_b32 v6, v36 :: v_dual_mov_b32 v7, v36
	v_dual_mov_b32 v8, v36 :: v_dual_mov_b32 v9, v36
	v_dual_mov_b32 v10, v36 :: v_dual_mov_b32 v11, v36
	v_dual_mov_b32 v12, v36 :: v_dual_mov_b32 v13, v36
	v_dual_mov_b32 v14, v36 :: v_dual_mov_b32 v15, v36
	v_dual_mov_b32 v16, v36 :: v_dual_mov_b32 v17, v36
	v_dual_mov_b32 v18, v36 :: v_dual_mov_b32 v19, v36
	v_dual_mov_b32 v20, v36 :: v_dual_mov_b32 v21, v36
	v_dual_mov_b32 v22, v36 :: v_dual_mov_b32 v23, v36
	v_dual_mov_b32 v24, v36 :: v_dual_mov_b32 v25, v36
	v_dual_mov_b32 v26, v36 :: v_dual_mov_b32 v27, v36
	v_dual_mov_b32 v28, v36 :: v_dual_mov_b32 v29, v36
	v_dual_mov_b32 v30, v36 :: v_dual_mov_b32 v31, v36
	v_dual_mov_b32 v47, v36 :: v_dual_mov_b32 v54, 0
	v_dual_mov_b32 v52, 0 :: v_dual_mov_b32 v53, v36
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v49, v36
	v_or_b32_e32 v72, 0x100, v71
	v_or_b32_e32 v73, 0x200, v71
	v_or_b32_e32 v74, 0x300, v71
	v_dual_mov_b32 v81, 0 :: v_dual_bitop2_b32 v75, 8, v64 bitop3:0x14
	v_dual_mov_b32 v85, 0 :: v_dual_bitop2_b32 v76, 4, v64 bitop3:0x14
	v_dual_mov_b32 v82, 0 :: v_dual_bitop2_b32 v77, 2, v64 bitop3:0x14
	v_dual_mov_b32 v86, 0 :: v_dual_bitop2_b32 v78, 1, v64 bitop3:0x14
	v_dual_mov_b32 v79, 0 :: v_dual_mov_b32 v83, 0
	v_dual_mov_b32 v80, 0 :: v_dual_mov_b32 v84, 0
	s_add_nc_u64 s[10:11], s[10:11], s[16:17]
	s_lshl_b32 s15, s15, 1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_branch .LBB2_4
.LBB2_3:                                ;   in Loop: Header=BB2_4 Depth=1
	global_load_b64 v[32:33], v[50:51], off offset:16
	s_lshl_b32 s4, s4, 11
	s_lshr_b32 s5, s13, 2
	v_cmp_lt_i32_e32 vcc_lo, v75, v69
	s_add_co_i32 s5, s5, s15
	s_wait_loadcnt 0x0
	v_nop
	v_nop
	v_nop
	v_ashrrev_i16 v34, 8, v32
	v_ashrrev_i16 v35, 8, v33
	v_bfe_i32 v37, v33, 0, 8
	v_bfe_i32 v38, v32, 0, 8
	v_dual_lshrrev_b32 v33, 16, v33 :: v_dual_lshrrev_b32 v32, 16, v32
	v_cvt_f16_i16_e32 v34, v34
	v_cvt_f16_i16_e32 v35, v35
	v_cvt_f16_i16_e32 v37, v37
	v_cvt_f16_i16_e32 v38, v38
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v94, v37, v35
	v_pack_b32_f16 v92, v38, v34
	global_load_b64 v[34:35], v[50:51], off
	s_wait_loadcnt 0x0
	v_ashrrev_i16 v37, 8, v35
	v_bfe_i32 v38, v35, 0, 8
	v_lshrrev_b32_e32 v35, 16, v35
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_cvt_f16_i16_e32 v37, v37
	v_cvt_f16_i16_e32 v38, v38
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_pack_b32_f16 v90, v38, v37
	v_ashrrev_i16 v37, 8, v34
	v_bfe_i32 v38, v34, 0, 8
	v_lshrrev_b32_e32 v34, 16, v34
	v_cvt_f16_i16_e32 v37, v37
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v38, v38
	v_pack_b32_f16 v88, v38, v37
	v_ashrrev_i16 v37, 8, v33
	v_bfe_i32 v33, v33, 0, 8
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_i16_e32 v37, v37
	v_cvt_f16_i16_e32 v33, v33
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_4)
	v_pack_b32_f16 v95, v33, v37
	v_ashrrev_i16 v33, 8, v32
	v_bfe_i32 v32, v32, 0, 8
	v_ashrrev_i16 v37, 8, v35
	v_bfe_i32 v35, v35, 0, 8
	v_cvt_f16_i16_e32 v33, v33
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_cvt_f16_i16_e32 v32, v32
	v_cvt_f16_i16_e32 v35, v35
	s_delay_alu instid0(VALU_DEP_2)
	v_pack_b32_f16 v93, v32, v33
	v_ashrrev_i16 v32, 8, v34
	v_bfe_i32 v33, v34, 0, 8
	v_cvt_f16_i16_e32 v34, v37
	v_add_nc_u32_e32 v37, s4, v67
	ds_load_b128 v[96:99], v37
	ds_load_b128 v[100:103], v37 offset:32
	v_cvt_f16_i16_e32 v32, v32
	v_cvt_f16_i16_e32 v33, v33
	v_pack_b32_f16 v91, v35, v34
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_pack_b32_f16 v89, v33, v32
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[38:45], v[88:95], v[96:103], 0
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	global_load_b64 v[32:33], v[50:51], off offset:48
	s_wait_loadcnt 0x0
	v_ashrrev_i16 v34, 8, v32
	v_ashrrev_i16 v35, 8, v33
	v_bfe_i32 v56, v33, 0, 8
	v_bfe_i32 v57, v32, 0, 8
	v_lshrrev_b32_e32 v33, 16, v33
	v_cvt_f16_i16_e32 v34, v34
	v_cvt_f16_i16_e32 v35, v35
	v_cvt_f16_i16_e32 v56, v56
	v_cvt_f16_i16_e32 v57, v57
	v_lshrrev_b32_e32 v32, 16, v32
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_pack_b32_f16 v94, v56, v35
	v_pack_b32_f16 v92, v57, v34
	global_load_b64 v[34:35], v[50:51], off offset:32
	ds_load_b128 v[96:99], v37 offset:64
	ds_load_b128 v[100:103], v37 offset:96
	s_wait_loadcnt 0x0
	v_ashrrev_i16 v56, 8, v35
	v_bfe_i32 v57, v35, 0, 8
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_i16_e32 v56, v56
	v_cvt_f16_i16_e32 v57, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v90, v57, v56
	v_ashrrev_i16 v56, 8, v34
	v_bfe_i32 v57, v34, 0, 8
	v_cvt_f16_i16_e32 v56, v56
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v57, v57
	v_pack_b32_f16 v88, v57, v56
	v_ashrrev_i16 v56, 8, v33
	v_bfe_i32 v33, v33, 0, 8
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cvt_f16_i16_e32 v56, v56
	v_cvt_f16_i16_e32 v33, v33
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_pack_b32_f16 v95, v33, v56
	v_ashrrev_i16 v33, 8, v32
	v_bfe_i32 v32, v32, 0, 8
	v_cvt_f16_i16_e32 v33, v33
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v32, v32
	v_pack_b32_f16 v93, v32, v33
	v_lshrrev_b32_e32 v32, 16, v35
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_ashrrev_i16 v33, 8, v32
	v_bfe_i32 v32, v32, 0, 8
	v_cvt_f16_i16_e32 v33, v33
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v32, v32
	v_pack_b32_f16 v91, v32, v33
	v_lshrrev_b32_e32 v32, 16, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_ashrrev_i16 v33, 8, v32
	v_bfe_i32 v32, v32, 0, 8
	v_cvt_f16_i16_e32 v33, v33
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_i16_e32 v32, v32
	v_pack_b32_f16 v89, v32, v33
	v_mov_b32_e32 v32, s5
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x32_f16 v[38:45], v[88:95], v[96:103], v[38:45]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	global_load_b32 v33, v32, s[0:1] scale_offset
	global_load_b32 v34, v36, s[10:11]
	s_add_co_i32 s5, s13, 1
	s_cmp_eq_u32 s13, 0
	v_dual_mov_b32 v93, v36 :: v_dual_mov_b32 v94, v36
	s_mov_b32 s13, s5
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v92, v36 :: v_dual_mul_f32 v33, v34, v33
	v_nop
	v_nop
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mul_f32 v35, v39, v33 :: v_dual_cndmask_b32 v32, v64, v75
	v_cmp_lt_i32_e32 vcc_lo, v76, v69
	v_dual_mul_f32 v32, v38, v33 :: v_dual_lshlrev_b32 v87, 2, v32
	ds_bpermute_b32 v34, v87, v32
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v34, v34, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v32, v32, v34
	ds_bpermute_b32 v34, v87, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v34, v34, v34
	v_dual_max_num_f32 v34, v35, v34 :: v_dual_mul_f32 v35, v40, v33
	ds_bpermute_b32 v37, v87, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v37, v37, v37
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v35, v35, v37
	v_mul_f32_e32 v37, v41, v33
	ds_bpermute_b32 v56, v87, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v56, v56, v56
	v_dual_max_num_f32 v37, v37, v56 :: v_dual_mul_f32 v56, v42, v33
	ds_bpermute_b32 v57, v87, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v57, v57, v57
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v56, v56, v57
	v_mul_f32_e32 v57, v43, v33
	ds_bpermute_b32 v58, v87, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v58, v58, v58
	v_dual_max_num_f32 v57, v57, v58 :: v_dual_mul_f32 v58, v44, v33
	ds_bpermute_b32 v59, v87, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v59, v59, v59
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v58, v58, v59 :: v_dual_mul_f32 v59, v45, v33
	ds_bpermute_b32 v88, v87, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v59, v59, v88
	v_cndmask_b32_e32 v88, v64, v76, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, v77, v69
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v100, 2, v88
	ds_bpermute_b32 v88, v100, v32
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v32, v32, v88
	ds_bpermute_b32 v88, v100, v34
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v34, v34, v88
	ds_bpermute_b32 v88, v100, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v35, v35, v88
	ds_bpermute_b32 v88, v100, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v37, v37, v88
	ds_bpermute_b32 v88, v100, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v56, v56, v88
	ds_bpermute_b32 v88, v100, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v57, v88
	ds_bpermute_b32 v88, v100, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v58, v58, v88
	ds_bpermute_b32 v88, v100, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_max_num_f32 v59, v59, v88 :: v_dual_cndmask_b32 v88, v64, v77
	v_cmp_lt_i32_e32 vcc_lo, v78, v69
	v_lshlrev_b32_e32 v101, 2, v88
	ds_bpermute_b32 v88, v101, v32
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v32, v32, v88
	ds_bpermute_b32 v88, v101, v34
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v34, v34, v88
	ds_bpermute_b32 v88, v101, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v35, v35, v88
	ds_bpermute_b32 v88, v101, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v37, v37, v88
	ds_bpermute_b32 v88, v101, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v56, v56, v88
	ds_bpermute_b32 v88, v101, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v57, v57, v88
	ds_bpermute_b32 v88, v101, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v58, v58, v88
	ds_bpermute_b32 v88, v101, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_dual_max_num_f32 v59, v59, v88 :: v_dual_cndmask_b32 v88, v64, v78
	s_cselect_b32 vcc_lo, -1, 0
	s_addk_co_i32 s14, 0x400
	s_cmp_lg_u32 s5, 8
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v102, 2, v88
	ds_bpermute_b32 v88, v102, v32
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v32, v32, v88
	ds_bpermute_b32 v88, v102, v34
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v34, v34, v88
	ds_bpermute_b32 v88, v102, v35
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v35, v35, v88
	ds_bpermute_b32 v88, v102, v37
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v37, v37, v88
	ds_bpermute_b32 v88, v102, v56
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v56, v56, v88
	ds_bpermute_b32 v88, v102, v57
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v57, v57, v88
	ds_bpermute_b32 v88, v102, v58
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	v_max_num_f32_e32 v58, v58, v88
	ds_bpermute_b32 v88, v102, v59
	s_wait_dscnt 0x0
	v_max_num_f32_e32 v88, v88, v88
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v59, v59, v88 :: v_dual_max_num_f32 v88, v81, v81
	v_max_num_f32_e32 v88, v88, v32
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_cndmask_b32 v103, v88, v32 :: v_dual_max_num_f32 v32, v85, v85
	v_max_num_f32_e32 v32, v32, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cndmask_b32_e32 v104, v32, v34, vcc_lo
	v_max_num_f32_e32 v32, v82, v82
	v_dual_max_num_f32 v32, v32, v35 :: v_dual_fma_f32 v34, v39, v33, -v104
	v_mov_b32_e32 v95, v36
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_cndmask_b32 v105, v32, v35 :: v_dual_max_num_f32 v32, v86, v86
	v_max_num_f32_e32 v32, v32, v37
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_fma_f32 v35, v40, v33, -v105
	v_dual_cndmask_b32 v106, v32, v37, vcc_lo :: v_dual_max_num_f32 v32, v79, v79
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v32, v32, v56 :: v_dual_fma_f32 v37, v41, v33, -v106
	v_dual_cndmask_b32 v107, v32, v56 :: v_dual_max_num_f32 v32, v83, v83
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v32, v32, v57
	v_cndmask_b32_e32 v108, v32, v57, vcc_lo
	v_max_num_f32_e32 v32, v80, v80
	v_exp_f32_e32 v57, v34
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_max_num_f32 v32, v32, v58 :: v_dual_fma_f32 v39, v43, v33, -v108
	v_cndmask_b32_e32 v109, v32, v58, vcc_lo
	v_max_num_f32_e32 v32, v84, v84
	v_exp_f32_e32 v58, v35
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_4) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v43, v39
	v_nop
	v_mov_b32_e32 v39, v36
	v_max_num_f32_e32 v32, v32, v59
	v_fma_f32 v40, v44, v33, -v109
	v_dual_cndmask_b32 v110, v32, v59, vcc_lo :: v_dual_fma_f32 v32, v38, v33, -v103
	v_fma_f32 v38, v42, v33, -v107
	v_exp_f32_e32 v59, v37
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v40, v40
	v_fma_f32 v33, v45, v33, -v110
	v_exp_f32_e32 v56, v32
	v_exp_f32_e32 v42, v38
	v_nop
	v_mov_b32_e32 v38, v36
	v_exp_f32_e32 v41, v33
	s_delay_alu instid0(TRANS32_DEP_3)
	v_cvt_f16_f32_e32 v32, v56
	ds_store_b16 v70, v32
	v_cvt_f16_f32_e32 v32, v57
	ds_store_b16 v70, v32 offset:32
	v_cvt_f16_f32_e32 v32, v58
	ds_store_b16 v70, v32 offset:64
	v_cvt_f16_f32_e32 v32, v59
	ds_store_b16 v70, v32 offset:96
	v_cvt_f16_f32_e32 v32, v42
	ds_store_b16 v70, v32 offset:128
	v_cvt_f16_f32_e32 v32, v43
	ds_store_b16 v70, v32 offset:160
	v_cvt_f16_f32_e32 v32, v40
	ds_store_b16 v70, v32 offset:192
	v_cvt_f16_f32_e32 v32, v41
	ds_store_b16 v70, v32 offset:224
	v_add_nc_u32_e32 v32, s4, v66
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_add_nc_u32 v111, v32, v71 :: v_dual_add_nc_u32 v113, v32, v73
	v_add_nc_u32_e32 v112, v32, v72
	ds_load_u16 v33, v111
	ds_load_u16 v34, v111 offset:128
	ds_load_u16 v35, v111 offset:384
	ds_load_u16 v37, v112
	v_add_nc_u32_e32 v114, v32, v74
	s_wait_dscnt 0x2
	v_perm_b32 v88, v34, v33, 0x5040100
	ds_load_u16 v33, v113
	ds_load_u16 v34, v111 offset:640
	s_wait_dscnt 0x2
	v_perm_b32 v89, v35, v37, 0x5040100
	v_mov_b32_e32 v37, v36
	s_wait_dscnt 0x0
	v_perm_b32 v90, v34, v33, 0x5040100
	ds_load_u16 v32, v114
	ds_load_u16 v33, v111 offset:896
	s_wait_dscnt 0x0
	v_perm_b32 v91, v33, v32, 0x5040100
	v_sub_f32_e32 v32, v85, v104
	v_dual_sub_f32 v33, v81, v103 :: v_dual_mov_b32 v85, v104
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_cndmask_b32_e64 v97, v32, 0, vcc_lo
	v_cndmask_b32_e64 v96, v33, 0, vcc_lo
	v_sub_f32_e32 v32, v86, v106
	v_sub_f32_e32 v33, v82, v105
	v_mov_b32_e32 v86, v106
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_pk_mul_f32 v[24:25], v[24:25], v[96:97]
	v_exp_f32_e32 v32, v32
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v33, v33
	v_pk_mul_f32 v[16:17], v[16:17], v[96:97]
	v_pk_mul_f32 v[8:9], v[8:9], v[96:97]
	v_pk_mul_f32 v[0:1], v[0:1], v[96:97]
	v_cndmask_b32_e64 v99, v32, 0, vcc_lo
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_cndmask_b32_e64 v98, v33, 0, vcc_lo
	v_sub_f32_e32 v32, v83, v108
	v_sub_f32_e32 v33, v79, v107
	v_pk_mul_f32 v[26:27], v[26:27], v[98:99]
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	v_pk_mul_f32 v[18:19], v[18:19], v[98:99]
	v_pk_mul_f32 v[10:11], v[10:11], v[98:99]
	v_pk_mul_f32 v[2:3], v[2:3], v[98:99]
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)
	v_cndmask_b32_e64 v83, v32, 0, vcc_lo
	v_cndmask_b32_e64 v82, v33, 0, vcc_lo
	v_sub_f32_e32 v32, v84, v110
	v_sub_f32_e32 v33, v80, v109
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_pk_mul_f32 v[28:29], v[28:29], v[82:83]
	v_exp_f32_e32 v32, v32
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(TRANS32_DEP_2)
	v_exp_f32_e32 v33, v33
	v_pk_mul_f32 v[20:21], v[20:21], v[82:83]
	v_pk_mul_f32 v[12:13], v[12:13], v[82:83]
	v_pk_mul_f32 v[4:5], v[4:5], v[82:83]
	v_cndmask_b32_e64 v45, v32, 0, vcc_lo
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_cndmask_b32_e64 v44, v33, 0, vcc_lo
	ds_load_b128 v[32:35], v65
	v_pk_mul_f32 v[30:31], v[30:31], v[44:45]
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[24:31], v[32:39], v[88:95], v[24:31]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v79, v111 offset:32
	ds_load_u16 v80, v111 offset:160
	ds_load_u16 v81, v112 offset:32
	ds_load_u16 v84, v111 offset:416
	v_pk_mul_f32 v[22:23], v[22:23], v[44:45]
	v_pk_mul_f32 v[14:15], v[14:15], v[44:45]
	v_pk_mul_f32 v[6:7], v[6:7], v[44:45]
	s_wait_dscnt 0x2
	v_nop
	v_perm_b32 v88, v80, v79, 0x5040100
	ds_load_u16 v79, v113 offset:32
	ds_load_u16 v80, v111 offset:672
	s_wait_dscnt 0x2
	v_perm_b32 v89, v84, v81, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v90, v80, v79, 0x5040100
	ds_load_u16 v79, v114 offset:32
	ds_load_u16 v80, v111 offset:928
	s_wait_dscnt 0x0
	v_perm_b32 v91, v80, v79, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[16:23], v[32:39], v[88:95], v[16:23]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	ds_load_u16 v79, v111 offset:64
	ds_load_u16 v80, v111 offset:192
	ds_load_u16 v81, v112 offset:64
	ds_load_u16 v84, v111 offset:448
	s_wait_dscnt 0x2
	v_nop
	v_nop
	v_nop
	v_nop
	v_perm_b32 v88, v80, v79, 0x5040100
	ds_load_u16 v79, v113 offset:64
	ds_load_u16 v80, v111 offset:704
	s_wait_dscnt 0x2
	v_perm_b32 v89, v84, v81, 0x5040100
	ds_bpermute_b32 v81, v87, v59
	v_mov_b32_e32 v84, v110
	s_wait_dscnt 0x1
	v_perm_b32 v90, v80, v79, 0x5040100
	ds_load_u16 v79, v114 offset:64
	ds_load_u16 v80, v111 offset:960
	s_wait_dscnt 0x0
	v_perm_b32 v91, v80, v79, 0x5040100
	ds_bpermute_b32 v80, v87, v58
	v_wmma_f32_16x16x32_f16 v[8:15], v[32:39], v[88:95], v[8:15]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	v_mov_b32_e32 v79, v107
	s_wait_dscnt 0x0
	v_pk_add_f32 v[58:59], v[58:59], v[80:81]
	ds_bpermute_b32 v80, v100, v58
	ds_bpermute_b32 v81, v100, v59
	s_wait_dscnt 0x0
	v_pk_add_f32 v[58:59], v[58:59], v[80:81]
	ds_bpermute_b32 v80, v101, v58
	ds_bpermute_b32 v81, v101, v59
	s_wait_dscnt 0x0
	v_pk_add_f32 v[58:59], v[58:59], v[80:81]
	ds_bpermute_b32 v80, v102, v58
	ds_bpermute_b32 v81, v102, v59
	s_wait_dscnt 0x0
	v_pk_add_f32 v[58:59], v[58:59], v[80:81]
	v_dual_mov_b32 v81, v103 :: v_dual_mov_b32 v80, v109
	s_delay_alu instid0(VALU_DEP_2)
	v_pk_fma_f32 v[52:53], v[52:53], v[98:99], v[58:59]
	ds_bpermute_b32 v58, v87, v56
	ds_bpermute_b32 v59, v87, v57
	s_wait_dscnt 0x0
	v_pk_add_f32 v[56:57], v[56:57], v[58:59]
	ds_bpermute_b32 v58, v87, v42
	ds_bpermute_b32 v59, v87, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[42:43], v[58:59]
	ds_bpermute_b32 v58, v87, v40
	ds_bpermute_b32 v59, v87, v41
	s_wait_dscnt 0x0
	v_pk_add_f32 v[40:41], v[40:41], v[58:59]
	ds_bpermute_b32 v58, v100, v56
	ds_bpermute_b32 v59, v100, v57
	s_wait_dscnt 0x0
	v_pk_add_f32 v[56:57], v[56:57], v[58:59]
	ds_bpermute_b32 v58, v100, v42
	ds_bpermute_b32 v59, v100, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[42:43], v[58:59]
	ds_bpermute_b32 v58, v100, v40
	ds_bpermute_b32 v59, v100, v41
	s_wait_dscnt 0x0
	v_pk_add_f32 v[40:41], v[40:41], v[58:59]
	ds_bpermute_b32 v58, v101, v56
	ds_bpermute_b32 v59, v101, v57
	s_wait_dscnt 0x0
	v_pk_add_f32 v[56:57], v[56:57], v[58:59]
	ds_bpermute_b32 v58, v101, v42
	ds_bpermute_b32 v59, v101, v43
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[42:43], v[58:59]
	ds_bpermute_b32 v58, v102, v56
	ds_bpermute_b32 v59, v102, v57
	s_wait_dscnt 0x0
	v_pk_add_f32 v[56:57], v[56:57], v[58:59]
	ds_bpermute_b32 v58, v102, v42
	ds_bpermute_b32 v59, v102, v43
	v_pk_fma_f32 v[54:55], v[54:55], v[96:97], v[56:57]
	s_wait_dscnt 0x0
	v_pk_add_f32 v[42:43], v[42:43], v[58:59]
	ds_bpermute_b32 v58, v101, v40
	ds_bpermute_b32 v59, v101, v41
	v_pk_fma_f32 v[48:49], v[48:49], v[82:83], v[42:43]
	v_dual_mov_b32 v82, v105 :: v_dual_mov_b32 v83, v108
	s_wait_dscnt 0x0
	v_pk_add_f32 v[40:41], v[40:41], v[58:59]
	ds_load_u16 v56, v112 offset:96
	ds_load_u16 v57, v111 offset:96
	ds_load_u16 v58, v111 offset:224
	ds_load_u16 v59, v111 offset:480
	ds_bpermute_b32 v42, v102, v40
	ds_bpermute_b32 v43, v102, v41
	s_wait_dscnt 0x3
	v_perm_b32 v88, v58, v57, 0x5040100
	s_wait_dscnt 0x2
	v_perm_b32 v89, v59, v56, 0x5040100
	s_wait_dscnt 0x0
	v_pk_add_f32 v[40:41], v[40:41], v[42:43]
	ds_load_u16 v42, v113 offset:96
	ds_load_u16 v43, v111 offset:736
	v_pk_fma_f32 v[46:47], v[46:47], v[44:45], v[40:41]
	s_wait_dscnt 0x0
	v_perm_b32 v90, v43, v42, 0x5040100
	ds_load_u16 v42, v114 offset:96
	ds_load_u16 v43, v111 offset:992
	s_wait_dscnt 0x0
	v_perm_b32 v91, v43, v42, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[0:7], v[32:39], v[88:95], v[0:7]
	;;#ASMSTART
	v_nop
v_nop
v_nop
v_nop
	;;#ASMEND
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_scc0 .LBB2_8
.LBB2_4:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB2_6 Depth 2
	s_and_b32 s4, s13, 1
	s_cmp_eq_u32 s13, 7
	s_cbranch_scc1 .LBB2_3
; %bb.5:                                ;   in Loop: Header=BB2_4 Depth=1
	s_lshl_b32 s5, s4, 11
	v_nop
	v_nop
	v_nop
	v_nop
	v_mov_b32_e32 v33, v68
	v_xad_u32 v32, 0x800, s5, v60
	s_mov_b32 s5, 0
.LBB2_6:                                ;   Parent Loop BB2_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_2)
	v_add3_u32 v34, s14, v33, 0x500
	v_add_nc_u32_e32 v33, 0x100, v33
	s_clause 0x1
	global_load_i8 v35, v34, s[6:7]
	global_load_u16 v37, v34, s[8:9] scale_offset
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v33
	s_or_b32 s5, vcc_lo, s5
	s_wait_loadcnt 0x1
	s_wait_xcnt 0x0
	v_cvt_f16_i16_e32 v34, v35
	ds_store_b16 v32, v34
	s_wait_loadcnt 0x0
	ds_store_b16 v32, v37 offset:4096
	v_add_nc_u32_e32 v32, 0x200, v32
	s_and_not1_b32 exec_lo, exec_lo, s5
	s_cbranch_execnz .LBB2_6
; %bb.7:                                ;   in Loop: Header=BB2_4 Depth=1
	s_or_b32 exec_lo, exec_lo, s5
	s_branch .LBB2_3
.LBB2_8:
	v_rcp_f32_e32 v33, v54
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v32, v62, v63
	v_or_b32_e32 v34, s12, v61
	v_rcp_f32_e32 v35, v55
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u32 v32, v32, 6, v34
	v_fma_mixlo_f16 v24, v33, v24, 0
	v_rcp_f32_e32 v34, v52
	v_fma_mixlo_f16 v16, v33, v16, 0
	v_fma_mixlo_f16 v8, v33, v8, 0
	v_fma_mixlo_f16 v0, v33, v0, 0
	v_add_nc_u32_e32 v33, 64, v32
	v_fma_mixlo_f16 v1, v35, v1, 0
	s_clause 0x4
	global_store_b16 v32, v24, s[2:3] scale_offset
	global_store_b16 v32, v16, s[2:3] offset:32 scale_offset
	global_store_b16 v32, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v32, v0, s[2:3] offset:96 scale_offset
	global_store_b16 v33, v1, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x3
	v_rcp_f32_e32 v16, v53
	v_fma_mixlo_f16 v25, v35, v25, 0
	v_fma_mixlo_f16 v17, v35, v17, 0
	v_fma_mixlo_f16 v2, v34, v2, 0
	v_fma_mixlo_f16 v9, v35, v9, 0
	s_wait_xcnt 0x2
	v_fma_mixlo_f16 v8, v34, v18, 0
	s_wait_xcnt 0x1
	v_add_nc_u32_e32 v0, 0x80, v32
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v1, v34, v26, 0
	v_fma_mixlo_f16 v10, v34, v10, 0
	s_clause 0x5
	global_store_b16 v33, v25, s[2:3] scale_offset
	global_store_b16 v33, v17, s[2:3] offset:32 scale_offset
	global_store_b16 v33, v9, s[2:3] offset:64 scale_offset
	global_store_b16 v0, v1, s[2:3] scale_offset
	global_store_b16 v0, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v0, v2, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x3
	v_rcp_f32_e32 v9, v48
	s_wait_xcnt 0x2
	v_add_nc_u32_e32 v1, 0xc0, v32
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v2, v16, v27, 0
	v_fma_mixlo_f16 v8, v16, v19, 0
	v_fma_mixlo_f16 v3, v16, v3, 0
	s_clause 0x3
	global_store_b16 v0, v10, s[2:3] offset:64 scale_offset
	global_store_b16 v1, v2, s[2:3] scale_offset
	global_store_b16 v1, v8, s[2:3] offset:32 scale_offset
	global_store_b16 v1, v3, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x1
	v_rcp_f32_e32 v8, v49
	v_fma_mixlo_f16 v11, v16, v11, 0
	v_fma_mixlo_f16 v4, v9, v4, 0
	v_add_nc_u32_e32 v0, 0x100, v32
	v_fma_mixlo_f16 v2, v9, v28, 0
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v3, v9, v20, 0
	v_fma_mixlo_f16 v9, v9, v12, 0
	s_clause 0x3
	global_store_b16 v1, v11, s[2:3] offset:64 scale_offset
	global_store_b16 v0, v2, s[2:3] scale_offset
	global_store_b16 v0, v3, s[2:3] offset:32 scale_offset
	global_store_b16 v0, v4, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v8, v5, 0
	v_rcp_f32_e32 v5, v46
	v_add_nc_u32_e32 v1, 0x140, v32
	v_fma_mixlo_f16 v2, v8, v29, 0
	v_fma_mixlo_f16 v3, v8, v21, 0
	s_clause 0x3
	global_store_b16 v0, v9, s[2:3] offset:64 scale_offset
	global_store_b16 v1, v2, s[2:3] scale_offset
	global_store_b16 v1, v3, s[2:3] offset:32 scale_offset
	global_store_b16 v1, v4, s[2:3] offset:96 scale_offset
	s_wait_xcnt 0x1
	v_rcp_f32_e32 v3, v47
	v_fma_mixlo_f16 v8, v8, v13, 0
	v_add_nc_u32_e32 v0, 0x180, v32
	v_fma_mixlo_f16 v2, v5, v14, 0
	s_wait_xcnt 0x0
	v_fma_mixlo_f16 v4, v5, v30, 0
	v_fma_mixlo_f16 v9, v5, v22, 0
	s_clause 0x1
	global_store_b16 v1, v8, s[2:3] offset:64 scale_offset
	global_store_b16 v0, v2, s[2:3] offset:64 scale_offset
	s_wait_xcnt 0x1
	v_fma_mixlo_f16 v1, v5, v6, 0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 0x1c0, v32
	v_fma_mixlo_f16 v5, v3, v31, 0
	v_fma_mixlo_f16 v6, v3, v23, 0
	v_fma_mixlo_f16 v8, v3, v15, 0
	v_fma_mixlo_f16 v3, v3, v7, 0
	s_clause 0x6
	global_store_b16 v0, v4, s[2:3] scale_offset
	global_store_b16 v0, v9, s[2:3] offset:32 scale_offset
	global_store_b16 v0, v1, s[2:3] offset:96 scale_offset
	global_store_b16 v2, v5, s[2:3] scale_offset
	global_store_b16 v2, v6, s[2:3] offset:32 scale_offset
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
		.amdhsa_next_free_vgpr 115
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
	.set sage_attention_original.num_vgpr, 115
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
; codeLenInByte = 5292
; TotalNumSgprs: 22
; NumVgprs: 115
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 12288 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 115
; NamedBarCnt: 0
; Occupancy: 8
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
    .vgpr_count:     108
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
    .vgpr_count:     106
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
    .vgpr_count:     115
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
