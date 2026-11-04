	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mamba2_chunk_state_full ; -- Begin function mamba2_chunk_state_full
	.globl	mamba2_chunk_state_full
	.p2align	8
	.type	mamba2_chunk_state_full,@function
mamba2_chunk_state_full:                ; @mamba2_chunk_state_full
; %bb.0:                                ; %entry
	s_load_dwordx8 s[16:23], s[0:1], 0x0
	s_load_dwordx2 s[24:25], s[0:1], 0x20
	s_lshl_b32 s0, s4, 9
	s_add_i32 s0, s0, s3
	s_lshr_b32 s34, s0, 6
	s_bfe_u32 s35, s3, 0x30003
	s_and_b32 s33, s3, 7
	s_lshl_b32 s0, s34, 20
	s_lshl_b32 s1, s35, 17
	s_or_b32 s2, s0, s1
	s_lshl_b32 s3, s33, 6
	s_or_b32 s26, s2, s3
	s_mov_b32 s27, 0
	s_lshl_b64 s[0:1], s[26:27], 1
	s_waitcnt lgkmcnt(0)
	s_add_u32 s16, s16, s0
	s_addc_u32 s17, s17, s1
	s_and_b32 s0, s3, 0x180
	s_or_b32 s26, s2, s0
	s_lshl_b64 s[0:1], s[26:27], 1
	s_add_u32 s30, s18, s0
	s_addc_u32 s31, s19, s1
	s_lshl_b32 s0, s34, 14
	s_lshl_b32 s1, s35, 8
	s_or_b32 s0, s0, s1
	s_lshl_b32 s1, s33, 11
	s_or_b32 s26, s0, s1
	s_lshl_b64 s[28:29], s[26:27], 2
	s_add_u32 s18, s22, s28
	v_and_b32_e32 v2, 63, v0
	v_lshrrev_b32_e32 v1, 6, v0
	s_addc_u32 s19, s23, s29
	v_lshlrev_b32_e32 v16, 1, v2
	v_or_b32_e32 v2, 0x80, v0
	s_add_u32 s36, s24, s28
	v_lshlrev_b32_e32 v5, 10, v1
	v_lshrrev_b32_e32 v32, 6, v2
	v_or_b32_e32 v6, 0x100, v0
	s_addc_u32 s37, s25, s29
	v_or_b32_e32 v4, v5, v16
	v_lshl_or_b32 v66, v32, 10, v16
	v_mov_b32_e32 v67, 0
	v_lshrrev_b32_e32 v35, 6, v6
	v_or_b32_e32 v8, 0x180, v0
	s_load_dword s26, s[36:37], 0x3fc
	v_lshl_add_u64 v[2:3], s[16:17], 0, v[66:67]
	global_load_ushort v33, v4, s[16:17]
	global_load_ushort v34, v66, s[16:17]
	v_lshl_or_b32 v66, v35, 10, v16
	v_lshrrev_b32_e32 v37, 6, v8
	v_or_b32_e32 v10, 0x200, v0
	v_lshl_add_u64 v[6:7], s[16:17], 0, v[66:67]
	global_load_ushort v36, v66, s[16:17]
	v_lshl_or_b32 v66, v37, 10, v16
	v_lshrrev_b32_e32 v39, 6, v10
	v_or_b32_e32 v12, 0x280, v0
	v_lshl_add_u64 v[8:9], s[16:17], 0, v[66:67]
	global_load_ushort v38, v66, s[16:17]
	v_lshl_or_b32 v66, v39, 10, v16
	v_lshrrev_b32_e32 v41, 6, v12
	v_or_b32_e32 v14, 0x300, v0
	s_load_dwordx16 s[0:15], s[36:37], 0x0
	v_lshl_add_u64 v[10:11], s[16:17], 0, v[66:67]
	global_load_ushort v40, v66, s[16:17]
	v_lshl_or_b32 v66, v41, 10, v16
	v_lshrrev_b32_e32 v43, 6, v14
	v_or_b32_e32 v17, 0x380, v0
	v_lshl_add_u64 v[12:13], s[16:17], 0, v[66:67]
	global_load_ushort v42, v66, s[16:17]
	v_lshl_or_b32 v66, v43, 10, v16
	v_lshrrev_b32_e32 v45, 6, v17
	v_lshl_add_u64 v[14:15], s[16:17], 0, v[66:67]
	global_load_ushort v44, v66, s[16:17]
	v_lshl_or_b32 v66, v45, 10, v16
	v_lshl_add_u64 v[16:17], s[16:17], 0, v[66:67]
	global_load_ushort v46, v66, s[16:17]
	v_lshlrev_b32_e32 v66, 1, v0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v18, s0
	v_lshl_add_u64 v[74:75], s[30:31], 0, v[66:67]
	s_movk_i32 s0, 0x1000
	v_add_co_u32_e32 v24, vcc, s0, v74
	s_movk_i32 s36, 0x2000
	s_nop 0
	v_addc_co_u32_e32 v25, vcc, 0, v75, vcc
	v_add_co_u32_e32 v26, vcc, s36, v74
	s_movk_i32 s0, 0x3000
	s_nop 0
	v_addc_co_u32_e32 v27, vcc, 0, v75, vcc
	v_add_co_u32_e32 v30, vcc, s0, v74
	global_load_ushort v47, v66, s[30:31] offset:1024
	global_load_ushort v48, v66, s[30:31] offset:2048
	global_load_ushort v49, v66, s[30:31] offset:3072
	v_addc_co_u32_e32 v31, vcc, 0, v75, vcc
	global_load_ushort v50, v[24:25], off offset:1024
	global_load_ushort v51, v[24:25], off offset:2048
	global_load_ushort v52, v[24:25], off offset:3072
	global_load_ushort v53, v[30:31], off
	global_load_ushort v54, v[30:31], off offset:1024
	global_load_ushort v55, v[30:31], off offset:2048
	global_load_ushort v56, v[30:31], off offset:3072
	global_load_ushort v57, v66, s[30:31]
	global_load_ushort v58, v[26:27], off offset:-4096
	global_load_ushort v59, v[26:27], off
	global_load_ushort v60, v[26:27], off offset:1024
	global_load_ushort v61, v[26:27], off offset:2048
	global_load_ushort v62, v[26:27], off offset:3072
	v_mov_b32_e32 v20, s2
	v_sub_f32_e32 v20, s26, v20
	v_lshlrev_b32_e32 v92, 4, v0
	v_min_f32_e32 v20, 0, v20
	v_and_b32_e32 v63, 0x3f0, v92
	v_mul_f32_e32 v20, 0x3fb8aa3b, v20
	v_or_b32_e32 v93, v63, v1
	v_exp_f32_e32 v22, v20
	v_mov_b32_e32 v20, s3
	v_mov_b32_e32 v29, s7
	v_lshlrev_b32_e32 v31, 1, v93
	v_or_b32_e32 v94, v32, v63
	v_mov_b32_e32 v19, s1
	v_sub_f32_e32 v20, s26, v20
	v_sub_f32_e32 v29, s26, v29
	v_or_b32_e32 v95, v35, v63
	v_or_b32_e32 v96, v37, v63
	v_or_b32_e32 v97, v39, v63
	v_sub_f32_e32 v18, s26, v18
	v_sub_f32_e32 v19, s26, v19
	v_min_f32_e32 v20, 0, v20
	v_min_f32_e32 v24, 0, v29
	v_lshlrev_b32_e32 v32, 1, v95
	v_or_b32_e32 v98, v41, v63
	v_min_f32_e32 v18, 0, v18
	v_min_f32_e32 v19, 0, v19
	v_mul_f32_e32 v20, 0x3fb8aa3b, v20
	v_mul_f32_e32 v24, 0x3fb8aa3b, v24
	s_waitcnt vmcnt(23)
	ds_write_b16 v31, v33 offset:8192
	v_lshlrev_b32_e32 v31, 1, v94
	s_waitcnt vmcnt(22)
	ds_write_b16 v31, v34 offset:8192
	v_lshlrev_b32_e32 v33, 1, v96
	v_lshlrev_b32_e32 v34, 1, v97
	v_or_b32_e32 v99, v43, v63
	s_waitcnt vmcnt(21)
	ds_write_b16 v32, v36 offset:8192
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	v_exp_f32_e32 v23, v20
	v_mov_b32_e32 v20, s4
	s_waitcnt vmcnt(20)
	ds_write_b16 v33, v38 offset:8192
	v_mov_b32_e32 v21, s5
	v_mov_b32_e32 v28, s6
	v_exp_f32_e32 v29, v24
	v_mov_b32_e32 v24, s8
	v_mov_b32_e32 v25, s9
	s_waitcnt vmcnt(19)
	ds_write_b16 v34, v40 offset:8192
	v_lshlrev_b32_e32 v34, 1, v98
	v_mov_b32_e32 v26, s10
	v_mov_b32_e32 v27, s11
	v_mov_b32_e32 v30, s12
	v_mov_b32_e32 v31, s13
	v_mov_b32_e32 v32, s14
	v_mov_b32_e32 v33, s15
	s_waitcnt vmcnt(18)
	ds_write_b16 v34, v42 offset:8192
	v_lshlrev_b32_e32 v34, 1, v99
	v_or_b32_e32 v100, v45, v63
	s_load_dwordx16 s[0:15], s[18:19], 0x0
	v_exp_f32_e32 v18, v18
	v_exp_f32_e32 v19, v19
	s_waitcnt vmcnt(17)
	ds_write_b16 v34, v44 offset:8192
	v_lshlrev_b32_e32 v34, 1, v100
	s_waitcnt vmcnt(16)
	ds_write_b16 v34, v46 offset:8192
	v_sub_f32_e32 v20, s26, v20
	v_sub_f32_e32 v21, s26, v21
	v_sub_f32_e32 v28, s26, v28
	v_min_f32_e32 v20, 0, v20
	v_min_f32_e32 v21, 0, v21
	v_min_f32_e32 v28, 0, v28
	v_mul_f32_e32 v20, 0x3fb8aa3b, v20
	v_mul_f32_e32 v21, 0x3fb8aa3b, v21
	v_mul_f32_e32 v28, 0x3fb8aa3b, v28
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[18:19], s[0:1], v[18:19]
	s_waitcnt vmcnt(15)
	v_cvt_f32_f16_e32 v37, v47
	s_waitcnt vmcnt(14)
	v_cvt_f32_f16_e32 v34, v48
	s_waitcnt vmcnt(13)
	v_cvt_f32_f16_e32 v35, v49
	v_pk_mul_f32 v[22:23], s[2:3], v[22:23]
	v_exp_f32_e32 v20, v20
	s_waitcnt vmcnt(5)
	v_cvt_f32_f16_e32 v36, v57
	v_exp_f32_e32 v21, v21
	v_exp_f32_e32 v28, v28
	v_pk_mul_f32 v[22:23], v[22:23], v[34:35]
	v_pk_mul_f32 v[18:19], v[18:19], v[36:37]
	v_cvt_f32_f16_e32 v35, v50
	v_cvt_pk_f16_f32 v18, v18, v19
	v_cvt_pk_f16_f32 v19, v22, v23
	v_cvt_f32_f16_e32 v23, v52
	s_waitcnt vmcnt(4)
	v_cvt_f32_f16_e32 v34, v58
	v_cvt_f32_f16_e32 v22, v51
	v_sub_f32_e32 v24, s26, v24
	v_sub_f32_e32 v25, s26, v25
	v_sub_f32_e32 v26, s26, v26
	v_sub_f32_e32 v27, s26, v27
	v_min_f32_e32 v24, 0, v24
	v_min_f32_e32 v25, 0, v25
	v_min_f32_e32 v26, 0, v26
	v_min_f32_e32 v27, 0, v27
	v_pk_mul_f32 v[28:29], s[6:7], v[28:29]
	v_pk_mul_f32 v[20:21], s[4:5], v[20:21]
	v_mul_f32_e32 v24, 0x3fb8aa3b, v24
	v_mul_f32_e32 v25, 0x3fb8aa3b, v25
	v_mul_f32_e32 v26, 0x3fb8aa3b, v26
	v_mul_f32_e32 v27, 0x3fb8aa3b, v27
	v_pk_mul_f32 v[34:35], v[20:21], v[34:35]
	v_pk_mul_f32 v[20:21], v[28:29], v[22:23]
	v_exp_f32_e32 v24, v24
	v_exp_f32_e32 v25, v25
	v_exp_f32_e32 v26, v26
	v_exp_f32_e32 v27, v27
	v_lshlrev_b32_e32 v101, 5, v0
	v_cvt_pk_f16_f32 v21, v20, v21
	v_cvt_pk_f16_f32 v20, v34, v35
	ds_write_b128 v101, v[18:21]
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v19, v62
	v_cvt_f32_f16_e32 v21, v60
	v_cvt_f32_f16_e32 v20, v59
	v_cvt_f32_f16_e32 v18, v61
	v_sub_f32_e32 v30, s26, v30
	v_sub_f32_e32 v31, s26, v31
	v_sub_f32_e32 v32, s26, v32
	v_sub_f32_e32 v33, s26, v33
	v_min_f32_e32 v30, 0, v30
	v_min_f32_e32 v31, 0, v31
	v_min_f32_e32 v32, 0, v32
	v_min_f32_e32 v33, 0, v33
	v_mul_f32_e32 v30, 0x3fb8aa3b, v30
	v_mul_f32_e32 v31, 0x3fb8aa3b, v31
	v_mul_f32_e32 v32, 0x3fb8aa3b, v32
	v_mul_f32_e32 v33, 0x3fb8aa3b, v33
	v_pk_mul_f32 v[22:23], s[10:11], v[26:27]
	v_pk_mul_f32 v[24:25], s[8:9], v[24:25]
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	v_pk_mul_f32 v[20:21], v[24:25], v[20:21]
	v_pk_mul_f32 v[18:19], v[22:23], v[18:19]
	v_cvt_f32_f16_e32 v23, v54
	v_cvt_pk_f16_f32 v19, v18, v19
	v_cvt_pk_f16_f32 v18, v20, v21
	v_cvt_f32_f16_e32 v21, v56
	v_cvt_f32_f16_e32 v22, v53
	v_cvt_f32_f16_e32 v20, v55
	v_pk_mul_f32 v[24:25], s[14:15], v[32:33]
	v_pk_mul_f32 v[26:27], s[12:13], v[30:31]
	s_mov_b64 s[0:1], 0x4000
	v_pk_mul_f32 v[22:23], v[26:27], v[22:23]
	v_pk_mul_f32 v[20:21], v[24:25], v[20:21]
	v_lshl_add_u64 v[78:79], v[16:17], 0, s[0:1]
	v_cvt_pk_f16_f32 v21, v20, v21
	v_cvt_pk_f16_f32 v20, v22, v23
	ds_write_b128 v101, v[18:21] offset:16
	v_and_b32_e32 v18, 0x3e0, v101
	v_lshrrev_b32_e32 v19, 1, v0
	v_or_b32_e32 v5, v5, v18
	v_and_b32_e32 v19, 16, v19
	v_or3_b32 v102, v5, v19, s36
	v_mov_b32_e32 v5, v67
	v_lshl_add_u64 v[4:5], s[16:17], 0, v[4:5]
	v_or_b32_e32 v103, v18, v19
	v_lshl_add_u64 v[76:77], v[4:5], 0, s[0:1]
	v_lshl_add_u64 v[80:81], v[14:15], 0, s[0:1]
	v_lshl_add_u64 v[82:83], v[12:13], 0, s[0:1]
	v_lshl_add_u64 v[84:85], v[10:11], 0, s[0:1]
	v_lshl_add_u64 v[86:87], v[8:9], 0, s[0:1]
	v_lshl_add_u64 v[88:89], v[6:7], 0, s[0:1]
	v_lshl_add_u64 v[90:91], v[2:3], 0, s[0:1]
	v_accvgpr_write_b32 a15, 0
	v_accvgpr_write_b32 a14, 0
	v_accvgpr_write_b32 a13, 0
	v_accvgpr_write_b32 a12, 0
	v_accvgpr_write_b32 a11, 0
	v_accvgpr_write_b32 a10, 0
	v_accvgpr_write_b32 a9, 0
	v_accvgpr_write_b32 a8, 0
	v_accvgpr_write_b32 a7, 0
	v_accvgpr_write_b32 a6, 0
	v_accvgpr_write_b32 a5, 0
	v_accvgpr_write_b32 a4, 0
	v_accvgpr_write_b32 a3, 0
	v_accvgpr_write_b32 a2, 0
	v_accvgpr_write_b32 a1, 0
	v_accvgpr_write_b32 a0, 0
	v_accvgpr_write_b32 a31, 0
	v_accvgpr_write_b32 a30, 0
	v_accvgpr_write_b32 a29, 0
	v_accvgpr_write_b32 a28, 0
	v_accvgpr_write_b32 a27, 0
	v_accvgpr_write_b32 a26, 0
	v_accvgpr_write_b32 a25, 0
	v_accvgpr_write_b32 a24, 0
	v_accvgpr_write_b32 a23, 0
	v_accvgpr_write_b32 a22, 0
	v_accvgpr_write_b32 a21, 0
	v_accvgpr_write_b32 a20, 0
	v_accvgpr_write_b32 a19, 0
	v_accvgpr_write_b32 a18, 0
	v_accvgpr_write_b32 a17, 0
	v_accvgpr_write_b32 a16, 0
	v_accvgpr_write_b32 a47, 0
	v_accvgpr_write_b32 a46, 0
	v_accvgpr_write_b32 a45, 0
	v_accvgpr_write_b32 a44, 0
	v_accvgpr_write_b32 a43, 0
	v_accvgpr_write_b32 a42, 0
	v_accvgpr_write_b32 a41, 0
	v_accvgpr_write_b32 a40, 0
	v_accvgpr_write_b32 a39, 0
	v_accvgpr_write_b32 a38, 0
	v_accvgpr_write_b32 a37, 0
	v_accvgpr_write_b32 a36, 0
	v_accvgpr_write_b32 a35, 0
	v_accvgpr_write_b32 a34, 0
	v_accvgpr_write_b32 a33, 0
	v_accvgpr_write_b32 a32, 0
	v_accvgpr_write_b32 a63, 0
	v_accvgpr_write_b32 a62, 0
	v_accvgpr_write_b32 a61, 0
	v_accvgpr_write_b32 a60, 0
	v_accvgpr_write_b32 a59, 0
	v_accvgpr_write_b32 a58, 0
	v_accvgpr_write_b32 a57, 0
	v_accvgpr_write_b32 a56, 0
	v_accvgpr_write_b32 a55, 0
	v_accvgpr_write_b32 a54, 0
	v_accvgpr_write_b32 a53, 0
	v_accvgpr_write_b32 a52, 0
	v_accvgpr_write_b32 a51, 0
	v_accvgpr_write_b32 a50, 0
	v_accvgpr_write_b32 a49, 0
	v_accvgpr_write_b32 a48, 0
	s_mov_b64 s[2:3], 0
	s_movk_i32 s52, 0x4000
	s_movk_i32 s53, 0x5000
	s_movk_i32 s54, 0x6000
	s_movk_i32 s55, 0x7000
	s_mov_b32 s56, 0x5040100
	s_mov_b32 s57, s27
	v_mov_b32_e32 v66, v67
	v_mov_b32_e32 v68, v67
	v_mov_b32_e32 v69, v67
	v_mov_b32_e32 v70, v67
	v_mov_b32_e32 v71, v67
	v_mov_b32_e32 v72, v67
	v_mov_b32_e32 v73, v67
	v_mov_b32_e32 v104, v67
	v_mov_b32_e32 v105, v67
	v_mov_b32_e32 v106, v67
	v_mov_b32_e32 v107, v67
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end86
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s57, s57, 16
	s_add_u32 s22, s22, 64
	s_addc_u32 s23, s23, 0
	s_add_u32 s24, s24, 64
	s_addc_u32 s25, s25, 0
	s_add_u32 s2, s2, 0x4000
	s_addc_u32 s3, s3, 0
	s_add_i32 s27, s27, 1
	s_mov_b64 vcc, s[0:1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccnz .LBB0_6
.LBB0_2:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lt_u32 s57, 0xf0
	s_cselect_b64 s[30:31], -1, 0
	s_cmpk_gt_u32 s57, 0xef
	s_cselect_b64 s[0:1], -1, 0
	s_and_b64 s[0:1], exec, s[0:1]
	s_mov_b64 vcc, s[0:1]
	s_cbranch_vccnz .LBB0_4
; %bb.3:                                ; %if.then
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_lshl_add_u64 v[2:3], v[74:75], 0, s[2:3]
	v_add_co_u32_e32 v4, vcc, s52, v2
	v_lshl_add_u64 v[12:13], v[86:87], 0, s[2:3]
	s_nop 0
	v_addc_co_u32_e32 v5, vcc, 0, v3, vcc
	v_add_co_u32_e32 v6, vcc, s53, v2
	v_lshl_add_u64 v[8:9], v[90:91], 0, s[2:3]
	s_nop 0
	v_addc_co_u32_e32 v7, vcc, 0, v3, vcc
	global_load_ushort v22, v[4:5], off offset:1024
	global_load_ushort v23, v[6:7], off offset:-4096
	global_load_ushort v24, v[4:5], off offset:3072
	global_load_ushort v25, v[4:5], off offset:2048
	global_load_ushort v26, v[6:7], off offset:1024
	global_load_ushort v27, v[6:7], off
	v_lshl_add_u64 v[4:5], v[76:77], 0, s[2:3]
	v_lshl_add_u64 v[10:11], v[88:89], 0, s[2:3]
	v_lshl_add_u64 v[14:15], v[84:85], 0, s[2:3]
	v_lshl_add_u64 v[16:17], v[82:83], 0, s[2:3]
	v_lshl_add_u64 v[18:19], v[80:81], 0, s[2:3]
	v_lshl_add_u64 v[20:21], v[78:79], 0, s[2:3]
	global_load_ushort v28, v[6:7], off offset:2048
	global_load_ushort v29, v[6:7], off offset:3072
	global_load_ushort v30, v[4:5], off
	global_load_ushort v31, v[8:9], off
	global_load_ushort v32, v[10:11], off
	global_load_ushort v33, v[12:13], off
                                        ; kill: killed $vgpr6 killed $vgpr7
                                        ; kill: killed $vgpr12_vgpr13
                                        ; kill: killed $vgpr10_vgpr11
                                        ; kill: killed $vgpr8_vgpr9
                                        ; kill: killed $vgpr4_vgpr5
	s_nop 0
	global_load_ushort v12, v[14:15], off
	global_load_ushort v13, v[16:17], off
	global_load_ushort v34, v[18:19], off
	global_load_ushort v35, v[20:21], off
	v_add_co_u32_e32 v4, vcc, s54, v2
	s_add_u32 s36, s24, s28
	s_nop 0
	v_addc_co_u32_e32 v5, vcc, 0, v3, vcc
	v_add_co_u32_e32 v2, vcc, s55, v2
	s_addc_u32 s37, s25, s29
	s_nop 0
	v_addc_co_u32_e32 v3, vcc, 0, v3, vcc
	global_load_ushort v14, v[4:5], off offset:1024
	global_load_ushort v15, v[2:3], off offset:-4096
	s_load_dwordx16 s[4:19], s[36:37], 0x40
	s_add_u32 s58, s22, s28
	global_load_ushort v16, v[4:5], off offset:2048
	global_load_ushort v17, v[4:5], off offset:3072
	global_load_ushort v18, v[2:3], off
	global_load_ushort v19, v[2:3], off offset:1024
	s_addc_u32 s59, s23, s29
	s_load_dwordx16 s[36:51], s[58:59], 0x40
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v6, s6
	v_mov_b32_e32 v7, s7
	v_sub_f32_e32 v6, s26, v6
	v_sub_f32_e32 v7, s26, v7
	v_min_f32_e32 v6, 0, v6
	v_min_f32_e32 v7, 0, v7
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_mov_b32_e32 v4, s4
	v_mov_b32_e32 v5, s5
	v_sub_f32_e32 v4, s26, v4
	v_pk_mul_f32 v[6:7], s[38:39], v[6:7]
	v_sub_f32_e32 v5, s26, v5
	v_mov_b32_e32 v8, s8
	v_min_f32_e32 v4, 0, v4
	v_min_f32_e32 v5, 0, v5
	v_sub_f32_e32 v8, s26, v8
	v_mul_f32_e32 v4, 0x3fb8aa3b, v4
	v_mul_f32_e32 v5, 0x3fb8aa3b, v5
	v_min_f32_e32 v8, 0, v8
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v5, v5
	v_mul_f32_e32 v20, 0x3fb8aa3b, v8
	v_pk_mul_f32 v[4:5], s[36:37], v[4:5]
	s_waitcnt vmcnt(12)
	v_perm_b32 v104, v31, v30, s56
	v_cvt_f32_f16_e32 v9, v22
	v_cvt_f32_f16_e32 v11, v24
	v_cvt_f32_f16_e32 v10, v25
	v_cvt_f32_f16_e32 v8, v23
	s_waitcnt vmcnt(10)
	v_perm_b32 v105, v33, v32, s56
	v_pk_mul_f32 v[6:7], v[6:7], v[10:11]
	global_load_ushort v10, v[2:3], off offset:2048
	global_load_ushort v11, v[2:3], off offset:3072
	v_mov_b32_e32 v3, s9
	v_sub_f32_e32 v3, s26, v3
	v_cvt_pk_f16_f32 v67, v6, v7
	v_min_f32_e32 v3, 0, v3
	v_mov_b32_e32 v6, s10
	v_mov_b32_e32 v7, s11
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_sub_f32_e32 v6, s26, v6
	v_sub_f32_e32 v7, s26, v7
	v_pk_mul_f32 v[4:5], v[4:5], v[8:9]
	v_exp_f32_e32 v2, v20
	v_exp_f32_e32 v3, v3
	v_min_f32_e32 v6, 0, v6
	v_min_f32_e32 v7, 0, v7
	v_cvt_pk_f16_f32 v66, v4, v5
	v_cvt_f32_f16_e32 v5, v26
	v_cvt_f32_f16_e32 v4, v27
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_pk_mul_f32 v[2:3], s[40:41], v[2:3]
	s_waitcnt vmcnt(7)
	v_cvt_f32_f16_e32 v9, v14
	v_pk_mul_f32 v[2:3], v[2:3], v[4:5]
	v_cvt_f32_f16_e32 v5, v29
	v_cvt_pk_f16_f32 v68, v2, v3
	v_pk_mul_f32 v[2:3], s[42:43], v[6:7]
	v_mov_b32_e32 v6, s12
	v_mov_b32_e32 v7, s13
	v_sub_f32_e32 v6, s26, v6
	v_sub_f32_e32 v7, s26, v7
	v_min_f32_e32 v6, 0, v6
	v_min_f32_e32 v7, 0, v7
	v_cvt_f32_f16_e32 v4, v28
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	s_waitcnt vmcnt(6)
	v_cvt_f32_f16_e32 v8, v15
	v_pk_mul_f32 v[2:3], v[2:3], v[4:5]
	s_waitcnt vmcnt(4)
	v_cvt_f32_f16_e32 v5, v17
	v_cvt_pk_f16_f32 v69, v2, v3
	v_pk_mul_f32 v[2:3], s[44:45], v[6:7]
	v_mov_b32_e32 v6, s16
	v_pk_mul_f32 v[2:3], v[2:3], v[8:9]
	v_mov_b32_e32 v7, s17
	v_cvt_pk_f16_f32 v70, v2, v3
	v_mov_b32_e32 v2, s14
	v_mov_b32_e32 v3, s15
	v_sub_f32_e32 v2, s26, v2
	v_sub_f32_e32 v3, s26, v3
	v_min_f32_e32 v2, 0, v2
	v_min_f32_e32 v3, 0, v3
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_sub_f32_e32 v6, s26, v6
	v_sub_f32_e32 v7, s26, v7
	v_exp_f32_e32 v2, v2
	v_exp_f32_e32 v3, v3
	v_min_f32_e32 v6, 0, v6
	v_min_f32_e32 v7, 0, v7
	v_cvt_f32_f16_e32 v4, v16
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_pk_mul_f32 v[2:3], s[46:47], v[2:3]
	v_perm_b32 v106, v13, v12, s56
	v_pk_mul_f32 v[2:3], v[2:3], v[4:5]
	s_waitcnt vmcnt(2)
	v_cvt_f32_f16_e32 v5, v19
	v_cvt_pk_f16_f32 v71, v2, v3
	v_pk_mul_f32 v[2:3], s[48:49], v[6:7]
	v_mov_b32_e32 v6, s18
	v_mov_b32_e32 v7, s19
	v_sub_f32_e32 v6, s26, v6
	v_sub_f32_e32 v7, s26, v7
	v_min_f32_e32 v6, 0, v6
	v_min_f32_e32 v7, 0, v7
	v_cvt_f32_f16_e32 v4, v18
	v_mul_f32_e32 v6, 0x3fb8aa3b, v6
	v_mul_f32_e32 v7, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v9, v11
	v_cvt_f32_f16_e32 v8, v10
	v_pk_mul_f32 v[2:3], v[2:3], v[4:5]
	v_perm_b32 v107, v35, v34, s56
	v_cvt_pk_f16_f32 v72, v2, v3
	v_pk_mul_f32 v[2:3], s[50:51], v[6:7]
	s_nop 0
	v_pk_mul_f32 v[2:3], v[2:3], v[8:9]
	s_nop 0
	v_cvt_pk_f16_f32 v73, v2, v3
.LBB0_4:                                ; %if.end
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_and_b32 s4, s27, 1
	v_lshl_add_u32 v2, s4, 11, v102
	ds_read_b128 v[2:5], v2
	v_lshl_or_b32 v14, s4, 12, v103
	ds_read_b128 v[6:9], v14
	s_andn2_b64 vcc, exec, s[30:31]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_f16 a[0:15], v[2:5], v[6:9], a[0:15]
	ds_read_b128 v[6:9], v14 offset:1024
	ds_read_b128 v[10:13], v14 offset:2048
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_f16 a[16:31], v[2:5], v[6:9], a[16:31]
	ds_read_b128 v[6:9], v14 offset:3072
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_f16 a[32:47], v[2:5], v[10:13], a[32:47]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_f16 a[48:63], v[2:5], v[6:9], a[48:63]
	s_cbranch_vccnz .LBB0_1
; %bb.5:                                ; %if.then79
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_xor_b32 s4, s4, 1
	s_lshl_b32 s5, s4, 11
	s_bitset1_b32 s5, 13
	v_lshl_or_b32 v2, v93, 1, s5
	ds_write_b16 v2, v104
	v_lshl_or_b32 v2, v94, 1, s5
	ds_write_b16_d16_hi v2, v104
	v_lshl_or_b32 v2, v95, 1, s5
	ds_write_b16 v2, v105
	v_lshl_or_b32 v2, v96, 1, s5
	ds_write_b16_d16_hi v2, v105
	v_lshl_or_b32 v2, v97, 1, s5
	ds_write_b16 v2, v106
	v_lshl_or_b32 v2, v98, 1, s5
	ds_write_b16_d16_hi v2, v106
	v_lshl_or_b32 v2, v99, 1, s5
	ds_write_b16 v2, v107
	v_lshl_or_b32 v2, v100, 1, s5
	ds_write_b16_d16_hi v2, v107
	v_lshl_or_b32 v2, s4, 12, v101
	ds_write_b128 v2, v[66:69]
	ds_write_b128 v2, v[70:73] offset:16
	s_branch .LBB0_1
.LBB0_6:                                ; %for.cond91.preheader
	s_lshl_b32 s0, s34, 19
	s_lshl_b32 s1, s35, 16
	s_or_b32 s0, s0, s1
	s_lshl_b32 s1, s33, 13
	s_or_b32 s0, s0, s1
	s_mov_b32 s1, 0
	v_and_b32_e32 v66, 0x200, v92
	s_lshl_b64 s[0:1], s[0:1], 2
	v_and_b32_e32 v0, 31, v0
	v_lshl_or_b32 v1, v1, 12, v66
	v_accvgpr_read_b32 v65, a15
	s_add_u32 s0, s20, s0
	v_or_b32_e32 v66, v1, v0
	v_accvgpr_read_b32 v50, a0
	s_addc_u32 s1, s21, s1
	v_lshlrev_b32_e32 v66, 2, v66
	v_accvgpr_read_b32 v53, a3
	v_accvgpr_read_b32 v52, a2
	v_accvgpr_read_b32 v51, a1
	global_store_dword v66, v50, s[0:1]
	global_store_dword v66, v51, s[0:1] offset:512
	global_store_dword v66, v52, s[0:1] offset:1024
	global_store_dword v66, v53, s[0:1] offset:1536
	v_or_b32_e32 v50, 0x400, v1
	v_or_b32_e32 v51, v50, v0
	v_accvgpr_read_b32 v54, a4
	v_lshlrev_b32_e32 v51, 2, v51
	global_store_dword v51, v54, s[0:1]
	v_or_b32_e32 v51, 0x480, v1
	v_or_b32_e32 v52, v51, v0
	v_accvgpr_read_b32 v55, a5
	v_lshlrev_b32_e32 v52, 2, v52
	global_store_dword v52, v55, s[0:1]
	v_or_b32_e32 v52, 0x500, v1
	v_or_b32_e32 v53, v52, v0
	v_accvgpr_read_b32 v56, a6
	v_lshlrev_b32_e32 v53, 2, v53
	global_store_dword v53, v56, s[0:1]
	v_or_b32_e32 v53, 0x580, v1
	v_or_b32_e32 v54, v53, v0
	v_accvgpr_read_b32 v57, a7
	v_lshlrev_b32_e32 v54, 2, v54
	global_store_dword v54, v57, s[0:1]
	v_or_b32_e32 v54, 0x800, v1
	v_or_b32_e32 v55, v54, v0
	v_accvgpr_read_b32 v58, a8
	v_lshlrev_b32_e32 v55, 2, v55
	global_store_dword v55, v58, s[0:1]
	v_or_b32_e32 v55, 0x880, v1
	v_or_b32_e32 v56, v55, v0
	v_accvgpr_read_b32 v59, a9
	v_lshlrev_b32_e32 v56, 2, v56
	global_store_dword v56, v59, s[0:1]
	v_or_b32_e32 v56, 0x900, v1
	v_or_b32_e32 v57, v56, v0
	v_accvgpr_read_b32 v60, a10
	v_lshlrev_b32_e32 v57, 2, v57
	global_store_dword v57, v60, s[0:1]
	v_or_b32_e32 v57, 0x980, v1
	v_or_b32_e32 v58, v57, v0
	v_accvgpr_read_b32 v61, a11
	v_lshlrev_b32_e32 v58, 2, v58
	global_store_dword v58, v61, s[0:1]
	v_or_b32_e32 v58, 0xc00, v1
	v_or_b32_e32 v59, v58, v0
	v_accvgpr_read_b32 v62, a12
	v_lshlrev_b32_e32 v59, 2, v59
	global_store_dword v59, v62, s[0:1]
	v_or_b32_e32 v59, 0xc80, v1
	v_or_b32_e32 v60, v59, v0
	v_accvgpr_read_b32 v63, a13
	v_lshlrev_b32_e32 v60, 2, v60
	global_store_dword v60, v63, s[0:1]
	v_or_b32_e32 v60, 0xd00, v1
	v_or_b32_e32 v61, v60, v0
	v_accvgpr_read_b32 v64, a14
	v_lshlrev_b32_e32 v61, 2, v61
	global_store_dword v61, v64, s[0:1]
	v_or_b32_e32 v61, 0xd80, v1
	v_or_b32_e32 v62, v61, v0
	v_accvgpr_read_b32 v49, a31
	v_lshlrev_b32_e32 v62, 2, v62
	v_accvgpr_read_b32 v34, a16
	global_store_dword v62, v65, s[0:1]
	v_or_b32_e32 v62, 32, v0
	global_store_dword v66, v34, s[0:1] offset:128
	v_or_b32_e32 v34, v1, v62
	v_accvgpr_read_b32 v35, a17
	v_lshlrev_b32_e32 v34, 2, v34
	v_accvgpr_read_b32 v37, a19
	v_accvgpr_read_b32 v36, a18
	global_store_dword v34, v35, s[0:1] offset:512
	global_store_dword v34, v36, s[0:1] offset:1024
	global_store_dword v34, v37, s[0:1] offset:1536
	v_or_b32_e32 v34, v50, v62
	v_accvgpr_read_b32 v38, a20
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v38, s[0:1]
	v_or_b32_e32 v34, v51, v62
	v_accvgpr_read_b32 v39, a21
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v39, s[0:1]
	v_or_b32_e32 v34, v52, v62
	v_accvgpr_read_b32 v40, a22
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v40, s[0:1]
	v_or_b32_e32 v34, v53, v62
	v_accvgpr_read_b32 v41, a23
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v41, s[0:1]
	v_or_b32_e32 v34, v54, v62
	v_accvgpr_read_b32 v42, a24
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v42, s[0:1]
	v_or_b32_e32 v34, v55, v62
	v_accvgpr_read_b32 v43, a25
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v43, s[0:1]
	v_or_b32_e32 v34, v56, v62
	v_accvgpr_read_b32 v44, a26
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v44, s[0:1]
	v_or_b32_e32 v34, v57, v62
	v_accvgpr_read_b32 v45, a27
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v45, s[0:1]
	v_or_b32_e32 v34, v58, v62
	v_accvgpr_read_b32 v46, a28
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v46, s[0:1]
	v_or_b32_e32 v34, v59, v62
	v_accvgpr_read_b32 v47, a29
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v47, s[0:1]
	v_or_b32_e32 v34, v60, v62
	v_accvgpr_read_b32 v48, a30
	v_lshlrev_b32_e32 v34, 2, v34
	global_store_dword v34, v48, s[0:1]
	v_or_b32_e32 v34, v61, v62
	v_lshlrev_b32_e32 v34, 2, v34
	v_accvgpr_read_b32 v18, a32
	global_store_dword v34, v49, s[0:1]
	v_or_b32_e32 v34, 64, v0
	global_store_dword v66, v18, s[0:1] offset:256
	v_or_b32_e32 v18, v1, v34
	v_accvgpr_read_b32 v19, a33
	v_lshlrev_b32_e32 v18, 2, v18
	v_accvgpr_read_b32 v20, a34
	v_accvgpr_read_b32 v21, a35
	global_store_dword v18, v19, s[0:1] offset:512
	global_store_dword v18, v20, s[0:1] offset:1024
	global_store_dword v18, v21, s[0:1] offset:1536
	v_or_b32_e32 v18, v50, v34
	v_accvgpr_read_b32 v22, a36
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v22, s[0:1]
	v_or_b32_e32 v18, v51, v34
	v_accvgpr_read_b32 v23, a37
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v23, s[0:1]
	v_or_b32_e32 v18, v52, v34
	v_accvgpr_read_b32 v24, a38
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v24, s[0:1]
	v_or_b32_e32 v18, v53, v34
	v_accvgpr_read_b32 v25, a39
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v25, s[0:1]
	v_or_b32_e32 v18, v54, v34
	v_accvgpr_read_b32 v26, a40
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v26, s[0:1]
	v_or_b32_e32 v18, v55, v34
	v_accvgpr_read_b32 v27, a41
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v27, s[0:1]
	v_or_b32_e32 v18, v56, v34
	v_accvgpr_read_b32 v28, a42
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v28, s[0:1]
	v_or_b32_e32 v18, v57, v34
	v_accvgpr_read_b32 v29, a43
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v29, s[0:1]
	v_or_b32_e32 v18, v58, v34
	v_accvgpr_read_b32 v30, a44
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v30, s[0:1]
	v_or_b32_e32 v18, v59, v34
	v_accvgpr_read_b32 v31, a45
	v_lshlrev_b32_e32 v18, 2, v18
	global_store_dword v18, v31, s[0:1]
	v_or_b32_e32 v18, v60, v34
	v_accvgpr_read_b32 v32, a46
	v_lshlrev_b32_e32 v18, 2, v18
	v_or_b32_e32 v0, 0x60, v0
	v_accvgpr_read_b32 v2, a48
	global_store_dword v18, v32, s[0:1]
	v_or_b32_e32 v18, v61, v34
	v_or_b32_e32 v1, v1, v0
	v_accvgpr_read_b32 v33, a47
	v_accvgpr_read_b32 v3, a49
	v_lshlrev_b32_e32 v18, 2, v18
	v_lshlrev_b32_e32 v1, 2, v1
	v_accvgpr_read_b32 v4, a50
	v_accvgpr_read_b32 v5, a51
	global_store_dword v18, v33, s[0:1]
	global_store_dword v66, v2, s[0:1] offset:384
	global_store_dword v1, v3, s[0:1] offset:512
	global_store_dword v1, v4, s[0:1] offset:1024
	global_store_dword v1, v5, s[0:1] offset:1536
	v_or_b32_e32 v1, v50, v0
	v_accvgpr_read_b32 v6, a52
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v6, s[0:1]
	v_or_b32_e32 v1, v51, v0
	v_accvgpr_read_b32 v7, a53
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v7, s[0:1]
	v_or_b32_e32 v1, v52, v0
	v_accvgpr_read_b32 v8, a54
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v8, s[0:1]
	v_or_b32_e32 v1, v53, v0
	v_accvgpr_read_b32 v9, a55
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v9, s[0:1]
	v_or_b32_e32 v1, v54, v0
	v_accvgpr_read_b32 v10, a56
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v10, s[0:1]
	v_or_b32_e32 v1, v55, v0
	v_accvgpr_read_b32 v11, a57
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v11, s[0:1]
	v_or_b32_e32 v1, v56, v0
	v_accvgpr_read_b32 v12, a58
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v12, s[0:1]
	v_or_b32_e32 v1, v57, v0
	v_accvgpr_read_b32 v13, a59
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v13, s[0:1]
	v_or_b32_e32 v1, v58, v0
	v_accvgpr_read_b32 v14, a60
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v14, s[0:1]
	v_or_b32_e32 v1, v59, v0
	v_accvgpr_read_b32 v15, a61
	v_lshlrev_b32_e32 v1, 2, v1
	global_store_dword v1, v15, s[0:1]
	v_or_b32_e32 v1, v60, v0
	v_or_b32_e32 v0, v61, v0
	v_accvgpr_read_b32 v16, a62
	v_accvgpr_read_b32 v17, a63
	v_lshlrev_b32_e32 v1, 2, v1
	v_lshlrev_b32_e32 v0, 2, v0
	global_store_dword v1, v16, s[0:1]
	global_store_dword v0, v17, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mamba2_chunk_state_full
		.amdhsa_group_segment_fixed_size 12288
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
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
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 172
		.amdhsa_next_free_sgpr 75
		.amdhsa_accum_offset 108
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
	.size	mamba2_chunk_state_full, .Lfunc_end0-mamba2_chunk_state_full
                                        ; -- End function
	.set mamba2_chunk_state_full.num_vgpr, 108
	.set mamba2_chunk_state_full.num_agpr, 64
	.set mamba2_chunk_state_full.numbered_sgpr, 60
	.set mamba2_chunk_state_full.num_named_barrier, 0
	.set mamba2_chunk_state_full.private_seg_size, 0
	.set mamba2_chunk_state_full.uses_vcc, 1
	.set mamba2_chunk_state_full.uses_flat_scratch, 0
	.set mamba2_chunk_state_full.has_dyn_sized_stack, 0
	.set mamba2_chunk_state_full.has_recursion, 0
	.set mamba2_chunk_state_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5252
; TotalNumSgprs: 66
; NumVgprs: 108
; NumAgprs: 64
; TotalNumVgprs: 172
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 12288 bytes/workgroup (compile time only)
; SGPRBlocks: 10
; VGPRBlocks: 21
; NumSGPRsForWavesPerEU: 81
; NumVGPRsForWavesPerEU: 172
; AccumOffset: 108
; Occupancy: 2
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 26
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_ad88d6d580871c22,@object ; @__hip_cuid_ad88d6d580871c22
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_ad88d6d580871c22
__hip_cuid_ad88d6d580871c22:
	.byte	0                               ; 0x0
	.size	__hip_cuid_ad88d6d580871c22, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_ad88d6d580871c22
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     64
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           b.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           states.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           dt.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           da.coerce
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 12288
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           mamba2_chunk_state_full
    .private_segment_fixed_size: 0
    .sgpr_count:     66
    .sgpr_spill_count: 0
    .symbol:         mamba2_chunk_state_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     172
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
