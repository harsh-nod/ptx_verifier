	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	forgetting_attention_full ; -- Begin function forgetting_attention_full
	.globl	forgetting_attention_full
	.p2align	8
	.type	forgetting_attention_full,@function
forgetting_attention_full:              ; @forgetting_attention_full
; %bb.0:                                ; %entry
	v_lshrrev_b32_e32 v3, 2, v0
	v_and_b32_e32 v38, 12, v3
	v_mbcnt_lo_u32_b32 v3, -1, 0
	v_mbcnt_hi_u32_b32 v3, -1, v3
	v_and_b32_e32 v4, 0x70, v3
	v_add_u32_e32 v4, 16, v4
	v_xor_b32_e32 v5, 8, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_load_dwordx8 s[8:15], s[0:1], 0x0
	s_load_dwordx4 s[16:19], s[0:1], 0x20
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v41, 2, v5
	v_xor_b32_e32 v5, 4, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_lshl_b32 s5, s4, 14
	s_lshl_b32 s0, s3, 10
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v42, 2, v5
	v_xor_b32_e32 v5, 2, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	v_lshrrev_b32_e32 v2, 6, v0
	s_add_i32 s5, s5, s0
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v43, 2, v5
	v_xor_b32_e32 v5, 1, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_lshl_b32 s0, s2, 7
	v_and_b32_e32 v39, 15, v0
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_lshlrev_b32_e32 v44, 2, v3
	v_mov_b32_e32 v3, 0x2000
	v_lshlrev_b32_e32 v5, 5, v0
	v_lshl_or_b32 v1, v2, 4, s0
	v_lshl_or_b32 v2, v2, 9, v3
	v_lshlrev_b32_e32 v3, 1, v39
	v_and_b32_e32 v5, 0x1e0, v5
	v_lshlrev_b32_e32 v6, 1, v38
	v_lshl_or_b32 v18, s5, 6, v0
	v_mov_b32_e32 v19, 0
	v_or_b32_e32 v4, v2, v3
	v_or3_b32 v45, v2, v5, v6
	v_or_b32_e32 v46, 0x1000, v3
	v_lshlrev_b64 v[2:3], 1, v[18:19]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[20:21], s[10:11], 0, v[2:3]
	v_lshl_add_u64 v[22:23], s[12:13], 0, v[2:3]
	v_or_b32_e32 v2, 1, v38
	v_or_b32_e32 v3, 2, v38
	v_or_b32_e32 v5, 3, v38
	s_lshl_b32 s2, s4, 20
	s_lshl_b32 s3, s3, 16
	v_lshlrev_b32_e32 v47, 1, v0
	v_lshlrev_b32_e32 v7, 5, v38
	v_lshlrev_b32_e32 v8, 5, v2
	v_lshlrev_b32_e32 v9, 5, v3
	v_lshlrev_b32_e32 v10, 5, v5
	s_add_i32 s3, s3, s2
	v_or_b32_e32 v40, s5, v39
	s_mov_b32 s6, 0
	v_cmp_eq_u32_e64 s[0:1], 0, v39
	v_accvgpr_write_b32 a16, 0
	v_accvgpr_write_b32 a17, 0
	v_accvgpr_write_b32 a18, 0
	v_accvgpr_write_b32 a19, 0
	v_accvgpr_write_b32 a20, 0
	v_accvgpr_write_b32 a21, 0
	v_accvgpr_write_b32 a22, 0
	v_accvgpr_write_b32 a23, 0
	v_accvgpr_write_b32 a24, 0
	v_accvgpr_write_b32 a25, 0
	v_accvgpr_write_b32 a26, 0
	v_accvgpr_write_b32 a27, 0
	v_or_b32_e32 v48, 0x1000, v47
	v_lshlrev_b32_e32 v49, 7, v38
	v_lshlrev_b32_e32 v50, 7, v2
	v_lshlrev_b32_e32 v51, 7, v3
	v_lshlrev_b32_e32 v52, 7, v5
	v_lshl_or_b32 v53, v39, 7, v6
	v_or_b32_e32 v54, s3, v0
	s_mov_b32 s4, 0x5040100
	v_add_u32_e32 v55, v4, v7
	v_add_u32_e32 v56, v4, v8
	v_add_u32_e32 v57, v4, v9
	v_add_u32_e32 v58, v4, v10
                                        ; implicit-def: $vgpr59
                                        ; implicit-def: $vgpr61
                                        ; implicit-def: $vgpr63
                                        ; implicit-def: $vgpr65
                                        ; implicit-def: $vgpr60
                                        ; implicit-def: $vgpr62
                                        ; implicit-def: $vgpr64
                                        ; implicit-def: $vgpr66
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end270.3.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_or_b64 exec, exec, s[2:3]
	s_add_i32 s6, s6, 1
	s_cmp_lg_u32 s6, 4
	s_barrier
	s_cbranch_scc0 .LBB0_17
.LBB0_2:                                ; %for.body.i
                                        ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_3 Depth 2
	global_load_ushort v2, v[20:21], off
	v_lshl_add_u32 v67, s6, 5, v1
	s_mov_b32 s7, 0
	v_mov_b32_e32 v36, v19
	v_mov_b32_e32 v37, v19
	v_mov_b32_e32 v74, v19
	v_mov_b32_e32 v75, v19
	v_mov_b32_e32 v26, v19
	v_mov_b32_e32 v27, v19
	v_mov_b32_e32 v24, v19
	v_mov_b32_e32 v25, v19
	v_accvgpr_write_b32 a0, 0
	v_accvgpr_mov_b32 a1, a27
	v_accvgpr_mov_b32 a2, a26
	v_accvgpr_mov_b32 a3, a25
	v_accvgpr_write_b32 a4, 0
	v_accvgpr_mov_b32 a5, a24
	v_accvgpr_mov_b32 a6, a23
	v_accvgpr_mov_b32 a7, a22
	v_accvgpr_write_b32 a8, 0
	v_accvgpr_mov_b32 a9, a21
	v_accvgpr_mov_b32 a10, a20
	v_accvgpr_mov_b32 a11, a19
	v_accvgpr_write_b32 a12, 0
	v_accvgpr_mov_b32 a13, a18
	v_accvgpr_mov_b32 a14, a17
	v_accvgpr_mov_b32 a15, a16
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2
	global_load_ushort v2, v[22:23], off
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2
	global_load_ushort v2, v[20:21], off offset:256
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:256
	global_load_ushort v2, v[22:23], off offset:256
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:256
	global_load_ushort v2, v[20:21], off offset:512
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:512
	global_load_ushort v2, v[22:23], off offset:512
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:512
	global_load_ushort v2, v[20:21], off offset:768
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:768
	global_load_ushort v2, v[22:23], off offset:768
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:768
	global_load_ushort v2, v[20:21], off offset:1024
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1024
	global_load_ushort v2, v[22:23], off offset:1024
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:1024
	global_load_ushort v2, v[20:21], off offset:1280
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1280
	global_load_ushort v2, v[22:23], off offset:1280
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:1280
	global_load_ushort v2, v[20:21], off offset:1536
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1536
	global_load_ushort v2, v[22:23], off offset:1536
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:1536
	global_load_ushort v2, v[20:21], off offset:1792
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1792
	global_load_ushort v2, v[22:23], off offset:1792
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:1792
	v_add_u32_e32 v2, v67, v40
	v_lshl_or_b32 v18, v2, 6, v38
	v_lshl_add_u64 v[2:3], v[18:19], 1, s[8:9]
	v_mov_b32_e32 v18, v40
	s_waitcnt lgkmcnt(0)
	s_barrier
.LBB0_3:                                ; %for.body28.i
                                        ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_cmpk_lg_u32 s7, 0xfc00
	v_accvgpr_read_b32 v5, a15
	v_accvgpr_read_b32 v4, a14
	v_accvgpr_read_b32 v13, a13
	v_accvgpr_read_b32 v12, a12
	v_accvgpr_read_b32 v7, a11
	v_accvgpr_read_b32 v6, a10
	v_accvgpr_read_b32 v15, a9
	v_accvgpr_read_b32 v14, a8
	v_accvgpr_read_b32 v9, a7
	v_accvgpr_read_b32 v8, a6
	v_accvgpr_read_b32 v17, a5
	v_accvgpr_read_b32 v16, a4
	v_accvgpr_read_b32 v11, a3
	v_accvgpr_read_b32 v10, a2
	v_accvgpr_read_b32 v29, a1
	s_cselect_b64 s[2:3], -1, 0
	s_cmpk_eq_u32 s7, 0xfc00
	v_accvgpr_read_b32 v28, a0
	s_cbranch_scc1 .LBB0_5
; %bb.4:                                ; %for.cond32.preheader.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	v_add_u32_e32 v34, s7, v54
	v_add_u32_e32 v30, 0x400, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	v_lshl_add_u64 v[32:33], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[12:13], 0, v[30:31]
	global_load_ushort v60, v[30:31], off
	v_add_u32_e32 v30, 0x480, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	global_load_ushort v59, v[32:33], off
	v_lshl_add_u64 v[32:33], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[12:13], 0, v[30:31]
	global_load_ushort v62, v[30:31], off
	v_add_u32_e32 v30, 0x500, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	global_load_ushort v61, v[32:33], off
	v_lshl_add_u64 v[32:33], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[12:13], 0, v[30:31]
	global_load_ushort v64, v[30:31], off
	v_add_u32_e32 v30, 0x580, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	global_load_ushort v63, v[32:33], off
	v_lshl_add_u64 v[32:33], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[12:13], 0, v[30:31]
	global_load_ushort v66, v[30:31], off
	v_add_u32_e32 v30, 0x600, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	global_load_ushort v65, v[32:33], off
	v_lshl_add_u64 v[32:33], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[12:13], 0, v[30:31]
	global_load_ushort v69, v[30:31], off
	v_add_u32_e32 v30, 0x680, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	global_load_ushort v68, v[32:33], off
	v_lshl_add_u64 v[32:33], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[12:13], 0, v[30:31]
	global_load_ushort v71, v[30:31], off
	v_add_u32_e32 v30, 0x700, v34
	v_mov_b32_e32 v31, v19
	v_lshlrev_b64 v[30:31], 1, v[30:31]
	global_load_ushort v70, v[32:33], off
	v_lshl_add_u64 v[32:33], s[12:13], 0, v[30:31]
	global_load_ushort v72, v[32:33], off
	v_add_u32_e32 v32, 0x780, v34
	v_mov_b32_e32 v33, v19
	v_lshlrev_b64 v[32:33], 1, v[32:33]
	v_lshl_add_u64 v[34:35], s[12:13], 0, v[32:33]
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[30:31]
	global_load_ushort v34, v[34:35], off
	s_waitcnt vmcnt(11)
	v_perm_b32 v60, v62, v60, s4
	global_load_ushort v35, v[30:31], off
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[32:33]
	global_load_ushort v30, v[30:31], off
	s_waitcnt vmcnt(12)
	v_perm_b32 v59, v61, v59, s4
	s_waitcnt vmcnt(9)
	v_perm_b32 v62, v66, v64, s4
	s_waitcnt vmcnt(8)
	v_perm_b32 v61, v65, v63, s4
	s_waitcnt vmcnt(5)
	v_perm_b32 v64, v71, v69, s4
	s_waitcnt vmcnt(4)
	v_perm_b32 v63, v70, v68, s4
	s_waitcnt vmcnt(2)
	v_perm_b32 v66, v34, v72, s4
	s_waitcnt vmcnt(0)
	v_perm_b32 v65, v30, v35, s4
.LBB0_5:                                ; %if.end.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	global_load_dwordx2 v[34:35], v[2:3], off
	s_lshl_b32 s20, s7, 1
	s_and_b32 s20, s20, 0x800
	v_or_b32_e32 v68, s20, v53
	ds_read2_b64 v[30:33], v68 offset1:4
	s_cmp_eq_u32 s7, 0
	s_cselect_b64 vcc, -1, 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[34:35], v[30:31], 0
	global_load_dwordx2 v[30:31], v[2:3], off offset:32
	global_load_dwordx2 v[34:35], v[2:3], off offset:64
	s_waitcnt vmcnt(1)
	v_mfma_f32_16x16x16_f16 a[0:3], v[30:31], v[32:33], a[0:3]
	ds_read2_b64 v[30:33], v68 offset0:8 offset1:12
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[34:35], v[30:31], a[0:3]
	global_load_dwordx2 v[30:31], v[2:3], off offset:96
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[30:31], v[32:33], a[0:3]
	v_lshl_add_u64 v[30:31], v[18:19], 2, s[14:15]
	global_load_dword v30, v[30:31], off
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v33, 0xbfb8aa3b, v30
	s_nop 3
	v_accvgpr_read_b32 v30, a0
	v_fmamk_f32 v30, v30, 0x3e38aa3b, v33
	ds_bpermute_b32 v31, v41, v30
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v31, v31, v31
	v_max_f32_e32 v31, v30, v31
	ds_bpermute_b32 v32, v42, v31
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v32, v32, v32
	v_max_f32_e32 v31, v31, v32
	ds_bpermute_b32 v32, v43, v31
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v32, v32, v32
	v_max_f32_e32 v31, v31, v32
	ds_bpermute_b32 v32, v44, v31
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v32, v32, v32
	v_max_f32_e32 v31, v31, v32
	v_max_f32_e32 v32, v36, v36
	v_max_f32_e32 v68, v32, v31
	v_cndmask_b32_e32 v72, v68, v31, vcc
	v_sub_f32_e32 v30, v30, v72
	v_exp_f32_e32 v30, v30
	v_sub_f32_e32 v36, v36, v72
	v_exp_f32_e32 v36, v36
	v_cvt_f16_f32_e32 v31, v30
	v_cndmask_b32_e64 v36, v36, 0, vcc
	ds_write_b16 v55, v31
	v_accvgpr_read_b32 v31, a1
	v_fmamk_f32 v31, v31, 0x3e38aa3b, v33
	ds_bpermute_b32 v32, v41, v31
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v32, v32, v32
	v_max_f32_e32 v32, v31, v32
	ds_bpermute_b32 v34, v42, v32
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v32, v32, v34
	ds_bpermute_b32 v34, v43, v32
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v32, v32, v34
	ds_bpermute_b32 v34, v44, v32
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v32, v32, v34
	v_max_f32_e32 v34, v37, v37
	v_max_f32_e32 v69, v34, v32
	v_cndmask_b32_e32 v73, v69, v32, vcc
	v_sub_f32_e32 v31, v31, v73
	v_exp_f32_e32 v31, v31
	v_sub_f32_e32 v37, v37, v73
	v_exp_f32_e32 v37, v37
	v_cvt_f16_f32_e32 v32, v31
	v_cndmask_b32_e64 v37, v37, 0, vcc
	v_pk_mul_f32 v[28:29], v[28:29], v[36:37]
	ds_write_b16 v56, v32
	v_accvgpr_read_b32 v32, a2
	v_fmamk_f32 v32, v32, 0x3e38aa3b, v33
	ds_bpermute_b32 v34, v41, v32
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v34, v32, v34
	ds_bpermute_b32 v35, v42, v34
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v34, v34, v35
	ds_bpermute_b32 v35, v43, v34
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v34, v34, v35
	ds_bpermute_b32 v35, v44, v34
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v34, v34, v35
	v_max_f32_e32 v35, v74, v74
	v_max_f32_e32 v70, v35, v34
	v_cndmask_b32_e32 v76, v70, v34, vcc
	v_sub_f32_e32 v32, v32, v76
	v_exp_f32_e32 v32, v32
	v_sub_f32_e32 v74, v74, v76
	v_exp_f32_e32 v84, v74
	v_cvt_f16_f32_e32 v34, v32
	ds_bpermute_b32 v96, v41, v32
	ds_write_b16 v57, v34
	v_accvgpr_read_b32 v34, a3
	v_fmac_f32_e32 v33, 0x3e38aa3b, v34
	ds_bpermute_b32 v34, v41, v33
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v34, v33, v34
	ds_bpermute_b32 v35, v42, v34
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v34, v34, v35
	ds_bpermute_b32 v35, v43, v34
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v34, v34, v35
	ds_bpermute_b32 v35, v44, v34
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v34, v34, v35
	v_max_f32_e32 v35, v75, v75
	v_max_f32_e32 v71, v35, v34
	v_cndmask_b32_e32 v77, v71, v34, vcc
	v_sub_f32_e32 v33, v33, v77
	v_exp_f32_e32 v33, v33
	v_sub_f32_e32 v74, v75, v77
	v_exp_f32_e32 v85, v74
	v_add_u32_e32 v74, s20, v46
	v_cvt_f16_f32_e32 v34, v33
	v_add_u32_e32 v80, v74, v51
	v_add_u32_e32 v78, v74, v49
	v_add_u32_e32 v79, v74, v50
	ds_write_b16 v58, v34
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64 v[34:35], v45
	v_add_u32_e32 v81, v74, v52
	ds_read_u16 v74, v80
	ds_read_u16 v82, v80 offset:32
	ds_read_u16 v75, v81
	ds_read_u16 v83, v81 offset:32
	ds_bpermute_b32 v97, v41, v33
	s_waitcnt lgkmcnt(2)
	v_perm_b32 v75, v75, v74, s4
	ds_read_u16 v74, v78
	ds_read_u16 v86, v78 offset:32
	ds_read_u16 v87, v79
	ds_read_u16 v88, v79 offset:32
	s_waitcnt lgkmcnt(5)
	v_perm_b32 v91, v83, v82, s4
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v74, v87, v74, s4
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v90, v88, v86, s4
	ds_read_u16 v82, v78 offset:64
	ds_read_u16 v83, v79 offset:64
	ds_read_u16 v86, v80 offset:64
	ds_read_u16 v87, v81 offset:64
	ds_read_u16 v78, v78 offset:96
	ds_read_u16 v79, v79 offset:96
	ds_read_u16 v80, v80 offset:96
	ds_read_u16 v81, v81 offset:96
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v92, v83, v82, s4
	v_perm_b32 v94, v79, v78, s4
	v_pk_mul_f32 v[78:79], v[16:17], v[36:37]
	v_perm_b32 v95, v81, v80, s4
	ds_bpermute_b32 v80, v41, v30
	ds_bpermute_b32 v81, v41, v31
	v_cndmask_b32_e64 v17, v85, 0, vcc
	v_cndmask_b32_e64 v16, v84, 0, vcc
	v_perm_b32 v93, v87, v86, s4
	v_pk_mul_f32 v[86:87], v[12:13], v[36:37]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[12:13], v[30:31], v[80:81]
	v_pk_mul_f32 v[88:89], v[4:5], v[16:17]
	v_pk_add_f32 v[4:5], v[32:33], v[96:97]
	v_pk_mul_f32 v[82:83], v[14:15], v[36:37]
	ds_bpermute_b32 v14, v42, v12
	ds_bpermute_b32 v15, v42, v13
	v_pk_mul_f32 v[84:85], v[6:7], v[16:17]
	ds_bpermute_b32 v6, v42, v4
	ds_bpermute_b32 v7, v42, v5
	v_pk_mul_f32 v[30:31], v[10:11], v[16:17]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[12:13], v[12:13], v[14:15]
	ds_bpermute_b32 v14, v43, v12
	ds_bpermute_b32 v15, v43, v13
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	ds_bpermute_b32 v6, v43, v4
	ds_bpermute_b32 v7, v43, v5
	v_pk_mul_f32 v[80:81], v[8:9], v[16:17]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[12:13], v[12:13], v[14:15]
	v_accvgpr_write_b32 a0, v28
	v_accvgpr_write_b32 a4, v78
	v_accvgpr_write_b32 a8, v82
	v_accvgpr_write_b32 a12, v86
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	ds_bpermute_b32 v14, v44, v12
	ds_bpermute_b32 v15, v44, v13
	v_accvgpr_write_b32 a1, v29
	v_accvgpr_write_b32 a2, v30
	v_accvgpr_write_b32 a3, v31
	v_accvgpr_write_b32 a5, v79
	v_accvgpr_write_b32 a6, v80
	v_accvgpr_write_b32 a7, v81
	v_accvgpr_write_b32 a9, v83
	v_accvgpr_write_b32 a10, v84
	v_accvgpr_write_b32 a11, v85
	v_accvgpr_write_b32 a13, v87
	v_accvgpr_write_b32 a14, v88
	v_accvgpr_write_b32 a15, v89
	ds_bpermute_b32 v6, v44, v4
	ds_bpermute_b32 v7, v44, v5
	v_mfma_f32_16x16x16_f16 a[0:3], v[34:35], v[74:75], a[0:3]
	s_andn2_b64 vcc, exec, s[2:3]
	s_barrier
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[4:7], v[34:35], v[90:91], a[4:7]
	v_mfma_f32_16x16x16_f16 a[8:11], v[34:35], v[92:93], a[8:11]
	v_mfma_f32_16x16x16_f16 a[12:15], v[34:35], v[94:95], a[12:15]
	s_cbranch_vccnz .LBB0_7
; %bb.6:                                ; %if.then197.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	s_add_i32 s2, s7, 0x400
	s_and_b32 s2, s2, 0x400
	v_or_b32_e32 v8, s2, v0
	v_lshlrev_b32_e32 v8, 1, v8
	ds_write_b16 v8, v59
	ds_write_b16 v8, v60 offset:4096
	ds_write_b16_d16_hi v8, v59 offset:256
	ds_write_b16_d16_hi v8, v60 offset:4352
	ds_write_b16 v8, v61 offset:512
	ds_write_b16 v8, v62 offset:4608
	ds_write_b16_d16_hi v8, v61 offset:768
	ds_write_b16_d16_hi v8, v62 offset:4864
	ds_write_b16 v8, v63 offset:1024
	ds_write_b16 v8, v64 offset:5120
	ds_write_b16_d16_hi v8, v63 offset:1280
	ds_write_b16_d16_hi v8, v64 offset:5376
	ds_write_b16 v8, v65 offset:1536
	ds_write_b16 v8, v66 offset:5632
	ds_write_b16_d16_hi v8, v65 offset:1792
	ds_write_b16_d16_hi v8, v66 offset:5888
.LBB0_7:                                ; %if.end220.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	v_pk_add_f32 v[8:9], v[12:13], v[14:15]
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	s_addk_i32 s7, 0x400
	v_pk_fma_f32 v[26:27], v[26:27], v[36:37], v[8:9]
	v_pk_fma_f32 v[24:25], v[24:25], v[16:17], v[4:5]
	s_cmp_eq_u32 s7, 0x10000
	v_add_u32_e32 v18, 16, v18
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc1 .LBB0_9
; %bb.8:                                ;   in Loop: Header=BB0_3 Depth=2
	v_mov_b32_e32 v36, v72
	v_mov_b32_e32 v37, v73
	v_mov_b32_e32 v74, v76
	v_mov_b32_e32 v75, v77
	s_branch .LBB0_3
.LBB0_9:                                ; %for.cond225.preheader.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_rcp_f32_e32 v29, v26
	v_or_b32_e32 v30, v67, v38
	v_accvgpr_read_b32 v13, a7
	v_accvgpr_read_b32 v17, a3
	v_add_u32_e32 v28, s5, v30
	v_accvgpr_read_b32 v2, a12
	v_accvgpr_read_b32 v6, a8
	v_accvgpr_read_b32 v10, a4
	v_accvgpr_read_b32 v14, a0
	v_lshl_or_b32 v18, v28, 6, v39
	v_accvgpr_read_b32 v3, a13
	v_accvgpr_read_b32 v4, a14
	v_accvgpr_read_b32 v5, a15
	v_accvgpr_read_b32 v7, a9
	v_accvgpr_read_b32 v8, a10
	v_accvgpr_read_b32 v9, a11
	v_accvgpr_read_b32 v12, a6
	v_accvgpr_read_b32 v11, a5
	v_accvgpr_read_b32 v16, a2
	v_accvgpr_read_b32 v15, a1
	v_fma_mixlo_f16 v14, v14, v29, 0
	v_lshl_add_u64 v[32:33], v[18:19], 1, s[18:19]
	v_fma_mixlo_f16 v10, v10, v29, 0
	v_fma_mixlo_f16 v6, v6, v29, 0
	v_fma_mixlo_f16 v2, v2, v29, 0
	global_store_short v[32:33], v14, off
	global_store_short v[32:33], v10, off offset:32
	global_store_short v[32:33], v6, off offset:64
	global_store_short v[32:33], v2, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_11
; %bb.10:                               ; %if.then258.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v29, v19
	v_lshlrev_b64 v[28:29], 2, v[28:29]
	v_lshl_add_u64 v[32:33], s[14:15], 0, v[28:29]
	global_load_dword v2, v[32:33], off
	v_log_f32_e32 v6, v26
	v_lshl_add_u64 v[28:29], s[16:17], 0, v[28:29]
	v_add_f32_e32 v6, v68, v6
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, 0x3f317218, v6
	global_store_dword v[28:29], v2, off
.LBB0_11:                               ; %if.end270.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v6, v27
	v_add3_u32 v2, s5, v30, 1
	v_lshl_or_b32 v18, v2, 6, v39
	v_lshl_add_u64 v[28:29], v[18:19], 1, s[18:19]
	v_fma_mixlo_f16 v10, v15, v6, 0
	global_store_short v[28:29], v10, off
	v_fma_mixlo_f16 v10, v11, v6, 0
	v_fma_mixlo_f16 v7, v7, v6, 0
	v_fma_mixlo_f16 v3, v3, v6, 0
	global_store_short v[28:29], v10, off offset:32
	global_store_short v[28:29], v7, off offset:64
	global_store_short v[28:29], v3, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_13
; %bb.12:                               ; %if.then258.1.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v3, v19
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	v_lshl_add_u64 v[6:7], s[14:15], 0, v[2:3]
	global_load_dword v6, v[6:7], off
	v_log_f32_e32 v7, v27
	v_lshl_add_u64 v[2:3], s[16:17], 0, v[2:3]
	v_add_f32_e32 v7, v69, v7
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v6, 0x3f317218, v7
	global_store_dword v[2:3], v6, off
.LBB0_13:                               ; %if.end270.1.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v3, v24
	v_add3_u32 v2, s5, v30, 2
	v_lshl_or_b32 v18, v2, 6, v39
	v_lshl_add_u64 v[6:7], v[18:19], 1, s[18:19]
	v_fma_mixlo_f16 v10, v16, v3, 0
	global_store_short v[6:7], v10, off
	v_fma_mixlo_f16 v10, v12, v3, 0
	v_fma_mixlo_f16 v8, v8, v3, 0
	v_fma_mixlo_f16 v3, v4, v3, 0
	global_store_short v[6:7], v10, off offset:32
	global_store_short v[6:7], v8, off offset:64
	global_store_short v[6:7], v3, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_15
; %bb.14:                               ; %if.then258.2.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v3, v19
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	v_lshl_add_u64 v[6:7], s[14:15], 0, v[2:3]
	global_load_dword v4, v[6:7], off
	v_log_f32_e32 v6, v24
	v_lshl_add_u64 v[2:3], s[16:17], 0, v[2:3]
	v_add_f32_e32 v6, v70, v6
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v4, 0x3f317218, v6
	global_store_dword v[2:3], v4, off
.LBB0_15:                               ; %if.end270.2.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v3, v25
	v_add3_u32 v2, s5, v30, 3
	v_lshl_or_b32 v18, v2, 6, v39
	v_lshl_add_u64 v[6:7], v[18:19], 1, s[18:19]
	v_fma_mixlo_f16 v4, v17, v3, 0
	global_store_short v[6:7], v4, off
	v_fma_mixlo_f16 v4, v13, v3, 0
	global_store_short v[6:7], v4, off offset:32
	v_fma_mixlo_f16 v4, v9, v3, 0
	v_fma_mixlo_f16 v3, v5, v3, 0
	global_store_short v[6:7], v4, off offset:64
	global_store_short v[6:7], v3, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_1
; %bb.16:                               ; %if.then258.3.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v3, v19
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	v_lshl_add_u64 v[4:5], s[14:15], 0, v[2:3]
	global_load_dword v4, v[4:5], off
	v_log_f32_e32 v5, v25
	v_lshl_add_u64 v[2:3], s[16:17], 0, v[2:3]
	v_add_f32_e32 v5, v71, v5
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v4, 0x3f317218, v5
	global_store_dword v[2:3], v4, off
	s_branch .LBB0_1
.LBB0_17:                               ; %_Z20forgetting_attentionILj1024ELj4EEvPKDF16_S1_S1_PKfPDF16_PfS4_S4_S4_.exit
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel forgetting_attention_full
		.amdhsa_group_segment_fixed_size 9216
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 128
		.amdhsa_next_free_sgpr 21
		.amdhsa_accum_offset 100
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
	.size	forgetting_attention_full, .Lfunc_end0-forgetting_attention_full
                                        ; -- End function
	.set forgetting_attention_full.num_vgpr, 98
	.set forgetting_attention_full.num_agpr, 28
	.set forgetting_attention_full.numbered_sgpr, 21
	.set forgetting_attention_full.num_named_barrier, 0
	.set forgetting_attention_full.private_seg_size, 0
	.set forgetting_attention_full.uses_vcc, 1
	.set forgetting_attention_full.uses_flat_scratch, 0
	.set forgetting_attention_full.has_dyn_sized_stack, 0
	.set forgetting_attention_full.has_recursion, 0
	.set forgetting_attention_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4068
; TotalNumSgprs: 27
; NumVgprs: 98
; NumAgprs: 28
; TotalNumVgprs: 128
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 9216 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 15
; NumSGPRsForWavesPerEU: 27
; NumVGPRsForWavesPerEU: 128
; AccumOffset: 100
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 24
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_7f877369c1aab79a,@object ; @__hip_cuid_7f877369c1aab79a
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_7f877369c1aab79a
__hip_cuid_7f877369c1aab79a:
	.byte	0                               ; 0x0
	.size	__hip_cuid_7f877369c1aab79a, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_7f877369c1aab79a
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     28
    .args:
      - .address_space:  global
        .name:           q.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           k.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           v.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           log_lambda.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           lse.coerce
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 9216
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           forgetting_attention_full
    .private_segment_fixed_size: 0
    .sgpr_count:     27
    .sgpr_spill_count: 0
    .symbol:         forgetting_attention_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     128
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
