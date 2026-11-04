	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mamba2_chunk_scan_full  ; -- Begin function mamba2_chunk_scan_full
	.globl	mamba2_chunk_scan_full
	.p2align	8
	.type	mamba2_chunk_scan_full,@function
mamba2_chunk_scan_full:                 ; @mamba2_chunk_scan_full
; %bb.0:                                ; %entry
	s_load_dwordx16 s[8:23], s[0:1], 0x0
	s_and_b32 s5, s3, 3
	s_lshr_b32 s3, s3, 2
	s_lshl_b32 s25, s5, 19
	s_lshl_b32 s0, s3, 15
	s_add_i32 s25, s25, s0
	s_lshl_b32 s0, s4, 12
	s_add_i32 s0, s25, s0
	s_mov_b32 s1, 0
	s_lshr_b32 s24, s4, 2
	s_lshl_b64 s[6:7], s[0:1], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s6, s14, s6
	s_addc_u32 s7, s15, s7
	s_lshl_b32 s14, s3, 13
	s_lshl_b32 s26, s2, 11
	s_lshl_b32 s0, s5, 17
	s_add_i32 s14, s14, s26
	s_lshl_b32 s15, s24, 5
	s_add_i32 s0, s14, s0
	s_add_i32 s0, s0, s15
	s_lshl_b64 s[14:15], s[0:1], 1
	v_and_b32_e32 v50, 15, v0
	v_lshlrev_b32_e32 v1, 2, v0
	s_movk_i32 s0, 0x1c0
	v_and_or_b32 v2, v1, s0, v50
	v_or_b32_e32 v3, 0x200, v1
	s_movk_i32 s0, 0x3c0
	v_lshlrev_b32_e32 v8, 1, v2
	v_and_or_b32 v2, v3, s0, v50
	v_or_b32_e32 v5, 0x400, v1
	s_movk_i32 s0, 0x5c0
	v_and_or_b32 v4, v5, s0, v50
	v_or_b32_e32 v1, 0x600, v1
	s_movk_i32 s0, 0x7c0
	v_lshlrev_b32_e32 v51, 1, v0
	v_and_or_b32 v13, v1, s0, v50
	v_or_b32_e32 v10, 0x100, v51
	s_movk_i32 s0, 0x1e0
	v_and_or_b32 v10, v10, s0, v50
	v_sub_u32_e32 v3, v3, v51
	s_movk_i32 s0, 0x3e0
	v_and_or_b32 v3, v3, s0, v50
	v_lshlrev_b32_e32 v12, 2, v3
	v_or_b32_e32 v3, 0x300, v51
	v_and_or_b32 v3, v3, s0, v50
	s_movk_i32 s0, 0x7e0
	v_sub_u32_e32 v1, v1, v51
	v_and_or_b32 v1, v1, s0, v50
	v_lshlrev_b32_e32 v28, 2, v3
	v_sub_u32_e32 v3, v5, v51
	v_lshlrev_b32_e32 v34, 2, v1
	v_or_b32_e32 v1, 0x700, v51
	v_and_or_b32 v3, v3, s0, v50
	v_and_or_b32 v1, v1, s0, v50
	v_or_b32_e32 v20, 0x900, v51
	s_movk_i32 s0, 0x9e0
	v_and_or_b32 v20, v20, s0, v50
	v_lshlrev_b32_e32 v40, 2, v20
	v_or_b32_e32 v20, 0xa00, v51
	s_movk_i32 s0, 0xae0
	v_and_or_b32 v20, v20, s0, v50
	v_lshlrev_b32_e32 v42, 2, v20
	v_or_b32_e32 v20, 0xb00, v51
	s_movk_i32 s0, 0xbe0
	v_and_or_b32 v20, v20, s0, v50
	v_lshlrev_b32_e32 v44, 2, v20
	v_or_b32_e32 v20, 0xc00, v51
	s_movk_i32 s0, 0xce0
	v_and_or_b32 v20, v20, s0, v50
	v_lshlrev_b32_e32 v46, 2, v20
	v_or_b32_e32 v20, 0xd00, v51
	s_movk_i32 s0, 0xde0
	v_and_or_b32 v20, v20, s0, v50
	v_lshlrev_b32_e32 v48, 2, v20
	v_or_b32_e32 v20, 0xe00, v51
	s_movk_i32 s0, 0xee0
	v_and_b32_e32 v14, 0xe0, v51
	v_and_or_b32 v20, v20, s0, v50
	s_add_u32 s12, s12, s14
	v_or_b32_e32 v38, 0x800, v14
	v_lshlrev_b32_e32 v52, 2, v20
	v_or_b32_e32 v20, 0xf00, v51
	s_movk_i32 s0, 0xfe0
	s_addc_u32 s13, s13, s15
	v_or_b32_e32 v6, v14, v50
	v_lshlrev_b32_e32 v30, 2, v3
	v_or_b32_e32 v3, 0x500, v51
	s_movk_i32 s14, 0x5e0
	v_or_b32_e32 v14, v38, v50
	v_and_or_b32 v20, v20, s0, v50
	v_lshlrev_b32_e32 v2, 1, v2
	v_lshlrev_b32_e32 v4, 1, v4
	global_load_ushort v7, v8, s[12:13]
	global_load_ushort v9, v2, s[12:13]
	global_load_ushort v11, v4, s[12:13]
	v_lshlrev_b32_e32 v6, 2, v6
	v_and_or_b32 v3, v3, s14, v50
	v_lshlrev_b32_e32 v14, 2, v14
	v_lshlrev_b32_e32 v54, 2, v20
	v_lshlrev_b32_e32 v20, 1, v13
	v_lshlrev_b32_e32 v10, 2, v10
	v_lshlrev_b32_e32 v32, 2, v3
	v_lshlrev_b32_e32 v36, 2, v1
	global_load_dword v1, v6, s[6:7]
	global_load_dword v3, v10, s[6:7]
	global_load_dword v5, v12, s[6:7]
	global_load_dword v15, v28, s[6:7]
	global_load_dword v16, v30, s[6:7]
	global_load_dword v17, v32, s[6:7]
	global_load_dword v18, v34, s[6:7]
	global_load_dword v19, v36, s[6:7]
	global_load_dword v21, v14, s[6:7]
	global_load_dword v22, v40, s[6:7]
	global_load_dword v23, v42, s[6:7]
	global_load_dword v24, v44, s[6:7]
	global_load_dword v25, v46, s[6:7]
	global_load_dword v26, v48, s[6:7]
	global_load_dword v27, v52, s[6:7]
	global_load_dword v29, v54, s[6:7]
	global_load_ushort v13, v20, s[12:13]
	s_waitcnt vmcnt(19)
	ds_write_b16 v51, v7 offset:8192
	s_waitcnt vmcnt(18)
	ds_write_b16 v51, v9 offset:8448
	s_waitcnt vmcnt(17)
	ds_write_b16 v51, v11 offset:8704
	s_movk_i32 s0, 0x2000
	s_waitcnt vmcnt(16)
	v_cvt_f16_f32_e32 v1, v1
	s_waitcnt vmcnt(15)
	v_cvt_f16_f32_e32 v3, v3
	s_waitcnt vmcnt(14)
	v_cvt_f16_f32_e32 v5, v5
	s_waitcnt vmcnt(13)
	v_cvt_f16_f32_e32 v7, v15
	s_waitcnt vmcnt(12)
	v_cvt_f16_f32_e32 v9, v16
	s_waitcnt vmcnt(11)
	v_cvt_f16_f32_e32 v11, v17
	s_waitcnt vmcnt(10)
	v_cvt_f16_f32_e32 v14, v18
	s_waitcnt vmcnt(9)
	v_cvt_f16_f32_e32 v15, v19
	s_waitcnt vmcnt(8)
	v_cvt_f16_f32_e32 v16, v21
	s_waitcnt vmcnt(7)
	v_cvt_f16_f32_e32 v17, v22
	s_waitcnt vmcnt(6)
	v_cvt_f16_f32_e32 v18, v23
	s_waitcnt vmcnt(5)
	v_cvt_f16_f32_e32 v19, v24
	s_waitcnt vmcnt(4)
	v_cvt_f16_f32_e32 v21, v25
	s_waitcnt vmcnt(3)
	v_cvt_f16_f32_e32 v22, v26
	s_waitcnt vmcnt(2)
	v_cvt_f16_f32_e32 v23, v27
	s_waitcnt vmcnt(1)
	v_cvt_f16_f32_e32 v24, v29
	s_waitcnt vmcnt(0)
	ds_write_b16 v51, v13 offset:8960
	ds_write_b16 v51, v1
	ds_write_b16 v51, v3 offset:256
	ds_write_b16 v51, v5 offset:512
	ds_write_b16 v51, v7 offset:768
	ds_write_b16 v51, v9 offset:1024
	ds_write_b16 v51, v11 offset:1280
	ds_write_b16 v51, v14 offset:1536
	ds_write_b16 v51, v15 offset:1792
	ds_write_b16 v51, v16 offset:2048
	ds_write_b16 v51, v17 offset:2304
	ds_write_b16 v51, v18 offset:2560
	ds_write_b16 v51, v19 offset:2816
	ds_write_b16 v51, v21 offset:3072
	ds_write_b16 v51, v22 offset:3328
	ds_write_b16 v51, v23 offset:3584
	ds_write_b16 v51, v24 offset:3840
	v_lshrrev_b32_e32 v1, 2, v0
	v_and_b32_e32 v101, 16, v1
	v_or_b32_e32 v3, v101, v50
	v_and_b32_e32 v102, 12, v1
	v_lshlrev_b32_e32 v1, 5, v3
	v_lshlrev_b32_e32 v3, 1, v102
	v_or_b32_e32 v100, 16, v50
	v_or3_b32 v104, v1, v3, s0
	v_mov_b32_e32 v9, 0
	v_or_b32_e32 v1, v38, v100
	v_lshl_or_b32 v105, v50, 5, v3
	v_lshl_add_u64 v[14:15], s[12:13], 0, v[8:9]
	v_mov_b32_e32 v3, v9
	v_mov_b32_e32 v5, v9
	v_mov_b32_e32 v21, v9
	v_mov_b32_e32 v7, v9
	v_mov_b32_e32 v11, v9
	v_mov_b32_e32 v13, v9
	v_mov_b32_e32 v29, v9
	v_mov_b32_e32 v31, v9
	v_mov_b32_e32 v33, v9
	v_mov_b32_e32 v35, v9
	v_mov_b32_e32 v37, v9
	v_lshlrev_b32_e32 v8, 2, v1
	v_mov_b32_e32 v41, v9
	v_mov_b32_e32 v43, v9
	v_mov_b32_e32 v45, v9
	v_mov_b32_e32 v47, v9
	v_mov_b32_e32 v49, v9
	v_mov_b32_e32 v53, v9
	v_mov_b32_e32 v55, v9
	v_or_b32_e32 v103, 0x2000, v51
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
	v_lshl_add_u64 v[16:17], s[12:13], 0, v[2:3]
	v_lshl_add_u64 v[18:19], s[12:13], 0, v[4:5]
	v_lshl_add_u64 v[20:21], s[12:13], 0, v[20:21]
	v_lshl_add_u64 v[22:23], s[6:7], 0, v[6:7]
	v_lshl_add_u64 v[24:25], s[6:7], 0, v[10:11]
	v_lshl_add_u64 v[26:27], s[6:7], 0, v[12:13]
	v_lshl_add_u64 v[28:29], s[6:7], 0, v[28:29]
	v_lshl_add_u64 v[30:31], s[6:7], 0, v[30:31]
	v_lshl_add_u64 v[32:33], s[6:7], 0, v[32:33]
	v_lshl_add_u64 v[34:35], s[6:7], 0, v[34:35]
	v_lshl_add_u64 v[36:37], s[6:7], 0, v[36:37]
	v_lshl_add_u64 v[38:39], s[6:7], 0, v[8:9]
	v_lshl_add_u64 v[40:41], s[6:7], 0, v[40:41]
	v_lshl_add_u64 v[42:43], s[6:7], 0, v[42:43]
	v_lshl_add_u64 v[44:45], s[6:7], 0, v[44:45]
	v_lshl_add_u64 v[46:47], s[6:7], 0, v[46:47]
	v_lshl_add_u64 v[48:49], s[6:7], 0, v[48:49]
	v_lshl_add_u64 v[52:53], s[6:7], 0, v[52:53]
	v_lshl_add_u64 v[54:55], s[6:7], 0, v[54:55]
	s_mov_b64 s[6:7], -1
	s_mov_b32 s0, 0x5040100
	v_mov_b32_e32 v1, v9
	v_mov_b32_e32 v56, v9
	v_mov_b32_e32 v8, v9
	v_mov_b32_e32 v2, v9
	v_mov_b32_e32 v4, v9
	v_mov_b32_e32 v6, v9
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end40.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 s1, 16
	s_andn2_b64 vcc, exec, s[12:13]
	s_mov_b64 s[6:7], 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccz .LBB0_6
.LBB0_2:                                ; %for.body.i
                                        ; =>This Inner Loop Header: Depth=1
	s_xor_b64 s[12:13], s[6:7], -1
	s_and_b64 vcc, exec, s[12:13]
	s_cbranch_vccnz .LBB0_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	global_load_dword v1, v[38:39], off
	global_load_dword v2, v[40:41], off offset:64
	global_load_dword v3, v[42:43], off offset:64
	global_load_dword v4, v[44:45], off offset:64
	global_load_dword v5, v[46:47], off offset:64
	global_load_dword v6, v[48:49], off offset:64
	global_load_dword v7, v[52:53], off offset:64
	global_load_dword v8, v[54:55], off offset:64
	global_load_dword v10, v[22:23], off offset:64
	global_load_dword v11, v[24:25], off offset:64
	global_load_dword v9, v[26:27], off offset:64
	global_load_dword v12, v[28:29], off offset:64
	global_load_dword v13, v[30:31], off offset:64
	global_load_dword v56, v[34:35], off offset:64
	global_load_dword v57, v[36:37], off offset:64
	global_load_dword v58, v[32:33], off offset:64
	global_load_ushort v59, v[14:15], off offset:32
	global_load_ushort v60, v[16:17], off offset:32
	global_load_ushort v61, v[18:19], off offset:32
	global_load_ushort v62, v[20:21], off offset:32
	s_waitcnt vmcnt(14)
	v_cvt_pk_f16_f32 v6, v5, v6
	v_cvt_pk_f16_f32 v5, v3, v4
	s_waitcnt vmcnt(12)
	v_cvt_pk_f16_f32 v7, v7, v8
	v_cvt_pk_f16_f32 v4, v1, v2
	s_waitcnt vmcnt(10)
	v_cvt_pk_f16_f32 v8, v10, v11
	s_waitcnt vmcnt(8)
	v_cvt_pk_f16_f32 v9, v9, v12
	s_waitcnt vmcnt(5)
	v_cvt_pk_f16_f32 v3, v56, v57
	s_waitcnt vmcnt(4)
	v_cvt_pk_f16_f32 v2, v13, v58
	s_waitcnt vmcnt(2)
	v_perm_b32 v1, v60, v59, s0
	s_waitcnt vmcnt(0)
	v_perm_b32 v56, v62, v61, s0
.LBB0_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_lshl_add_u32 v10, s1, 6, v104
	ds_read_b64 v[62:63], v10
	v_lshl_add_u32 v57, s1, 8, v105
	ds_read2st64_b64 v[10:13], v57 offset1:1
	ds_read2st64_b64 v[58:61], v57 offset0:2 offset1:3
	s_andn2_b64 vcc, exec, s[6:7]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 a[0:3], v[62:63], v[10:11], a[0:3]
	v_mfma_f32_16x16x16_f16 a[4:7], v[62:63], v[12:13], a[4:7]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[8:11], v[62:63], v[58:59], a[8:11]
	v_mfma_f32_16x16x16_f16 a[12:15], v[62:63], v[60:61], a[12:15]
	ds_read2st64_b64 v[10:13], v57 offset0:4 offset1:5
	ds_read2st64_b64 v[58:61], v57 offset0:6 offset1:7
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 a[16:19], v[62:63], v[10:11], a[16:19]
	v_mfma_f32_16x16x16_f16 a[20:23], v[62:63], v[12:13], a[20:23]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[24:27], v[62:63], v[58:59], a[24:27]
	v_mfma_f32_16x16x16_f16 a[28:31], v[62:63], v[60:61], a[28:31]
	s_cbranch_vccnz .LBB0_1
; %bb.5:                                ; %if.then34.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	ds_write_b16 v103, v1 offset:1024
	ds_write_b16_d16_hi v103, v1 offset:1280
	ds_write_b16 v103, v56 offset:1536
	ds_write_b16_d16_hi v103, v56 offset:1792
	ds_write_b16 v51, v8 offset:4096
	ds_write_b16_d16_hi v51, v8 offset:4352
	ds_write_b16 v51, v9 offset:4608
	ds_write_b16_d16_hi v51, v9 offset:4864
	ds_write_b16 v51, v2 offset:5120
	ds_write_b16_d16_hi v51, v2 offset:5376
	ds_write_b16 v51, v3 offset:5632
	ds_write_b16_d16_hi v51, v3 offset:5888
	ds_write_b16 v51, v4 offset:6144
	ds_write_b16_d16_hi v51, v4 offset:6400
	ds_write_b16 v51, v5 offset:6656
	ds_write_b16_d16_hi v51, v5 offset:6912
	ds_write_b16 v51, v6 offset:7168
	ds_write_b16_d16_hi v51, v6 offset:7424
	ds_write_b16 v51, v7 offset:7680
	ds_write_b16_d16_hi v51, v7 offset:7936
	s_branch .LBB0_1
.LBB0_6:                                ; %for.cond.preheader
	s_lshl_b32 s6, s3, 7
	s_lshl_b32 s7, s4, 11
	s_lshl_b32 s0, s5, 14
	s_add_i32 s6, s6, s7
	s_mov_b32 s1, 0
	s_add_i32 s0, s6, s0
	s_lshl_b32 s26, s2, 5
	s_lshl_b64 s[6:7], s[0:1], 2
	s_add_u32 s12, s18, s6
	v_or_b32_e32 v2, s26, v102
	v_or_b32_e32 v1, 0x80, v0
	v_mov_b32_e32 v9, 0
	s_addc_u32 s13, s19, s7
	v_add_u32_e32 v8, v2, v101
	v_lshrrev_b32_e32 v35, 4, v0
	v_lshl_add_u64 v[2:3], v[8:9], 2, s[12:13]
	v_or_b32_e32 v8, s26, v35
	v_lshrrev_b32_e32 v1, 4, v1
	v_or_b32_e32 v5, 0x100, v0
	v_lshlrev_b32_e32 v46, 2, v50
	v_lshl_add_u64 v[52:53], v[8:9], 2, s[12:13]
	v_or_b32_e32 v8, s26, v1
	v_lshlrev_b32_e32 v36, 10, v50
	v_or_b32_e32 v34, 0x180, v0
	v_lshl_add_u64 v[54:55], v[8:9], 2, s[12:13]
	v_lshl_or_b32 v8, v1, 9, v46
	v_lshrrev_b32_e32 v5, 4, v5
	v_or_b32_e32 v1, v1, v36
	v_lshrrev_b32_e32 v34, 4, v34
	v_lshlrev_b32_e32 v98, 1, v1
	v_or_b32_e32 v1, v5, v36
	v_lshlrev_b32_e32 v96, 1, v1
	v_or_b32_e32 v1, v34, v36
	v_lshlrev_b32_e32 v94, 1, v1
	v_or_b32_e32 v1, 0x200, v0
	v_lshrrev_b32_e32 v1, 4, v1
	v_or_b32_e32 v1, v1, v36
	v_lshlrev_b32_e32 v92, 1, v1
	v_or_b32_e32 v1, 0x280, v0
	v_lshrrev_b32_e32 v1, 4, v1
	s_lshl_b32 s0, s24, 14
	s_lshl_b32 s14, s2, 12
	v_or_b32_e32 v1, v1, v36
	s_add_i32 s0, s0, s14
	v_lshlrev_b32_e32 v90, 1, v1
	v_or_b32_e32 v1, 0x300, v0
	s_add_i32 s0, s0, s25
	v_lshrrev_b32_e32 v1, 4, v1
	s_lshl_b64 s[14:15], s[0:1], 2
	v_or_b32_e32 v1, v1, v36
	s_add_u32 s8, s8, s14
	v_lshlrev_b32_e32 v88, 1, v1
	v_or_b32_e32 v1, 0x380, v0
	s_addc_u32 s9, s9, s15
	v_lshrrev_b32_e32 v1, 4, v1
	s_add_u32 s14, s16, s6
	v_lshl_or_b32 v4, v35, 9, v46
	v_or_b32_e32 v1, v1, v36
	s_addc_u32 s15, s17, s7
	global_load_dwordx4 v[30:33], v[2:3], off
	global_load_dword v47, v46, s[12:13]
	global_load_dword v48, v46, s[14:15]
	v_lshl_add_u64 v[2:3], s[8:9], 0, v[8:9]
	global_load_dword v49, v4, s[8:9]
	global_load_dword v61, v8, s[8:9]
	v_or_b32_e32 v8, s26, v5
	v_lshlrev_b32_e32 v86, 1, v1
	v_or_b32_e32 v1, 0x480, v0
	v_lshl_add_u64 v[56:57], v[8:9], 2, s[12:13]
	v_lshl_or_b32 v8, v5, 9, v46
	v_lshrrev_b32_e32 v1, 4, v1
	v_lshl_add_u64 v[6:7], s[8:9], 0, v[8:9]
	global_load_dword v62, v8, s[8:9]
	v_or_b32_e32 v8, s26, v34
	v_or_b32_e32 v1, v1, v36
	v_lshl_add_u64 v[58:59], v[8:9], 2, s[12:13]
	global_load_dword v63, v[52:53], off
	global_load_dword v64, v[54:55], off
	global_load_dword v65, v[56:57], off
	global_load_dword v66, v[58:59], off
	v_lshlrev_b32_e32 v84, 1, v1
	v_or_b32_e32 v1, 0x500, v0
	v_lshrrev_b32_e32 v1, 4, v1
	v_or_b32_e32 v1, v1, v36
	v_lshlrev_b32_e32 v82, 1, v1
	v_or_b32_e32 v1, 0x580, v0
	v_lshrrev_b32_e32 v1, 4, v1
	v_or_b32_e32 v1, v1, v36
	v_lshlrev_b32_e32 v80, 1, v1
	v_or_b32_e32 v1, 0x600, v0
	v_lshrrev_b32_e32 v1, 4, v1
	v_or_b32_e32 v1, v1, v36
	s_lshl_b32 s3, s3, 17
	s_lshl_b32 s4, s4, 7
	v_lshlrev_b32_e32 v78, 1, v1
	v_or_b32_e32 v1, 0x680, v0
	s_lshl_b32 s0, s5, 21
	s_add_i32 s3, s3, s4
	v_lshrrev_b32_e32 v1, 4, v1
	s_add_i32 s0, s3, s0
	v_or_b32_e32 v1, v1, v36
	s_lshl_b64 s[4:5], s[0:1], 1
	v_lshlrev_b32_e32 v77, 1, v1
	v_or_b32_e32 v1, 0x700, v0
	v_or_b32_e32 v0, 0x780, v0
	s_add_u32 s4, s10, s4
	v_lshl_or_b32 v8, v34, 9, v46
	v_or_b32_e32 v35, v36, v35
	v_lshrrev_b32_e32 v1, 4, v1
	v_lshrrev_b32_e32 v0, 4, v0
	s_addc_u32 s5, s11, s5
	global_load_dword v67, v8, s[8:9]
	v_lshlrev_b32_e32 v60, 1, v35
	v_or_b32_e32 v1, v1, v36
	v_or_b32_e32 v0, v0, v36
	global_load_ushort v5, v60, s[4:5]
	global_load_ushort v68, v60, s[4:5] offset:128
	global_load_ushort v69, v98, s[4:5]
	global_load_ushort v70, v96, s[4:5]
	global_load_ushort v71, v94, s[4:5]
	global_load_ushort v72, v92, s[4:5]
	global_load_ushort v73, v90, s[4:5]
	global_load_ushort v74, v88, s[4:5]
	global_load_ushort v75, v86, s[4:5]
	global_load_ushort v76, v84, s[4:5]
	v_lshlrev_b32_e32 v79, 1, v1
	v_lshlrev_b32_e32 v81, 1, v0
	global_load_ushort v83, v82, s[4:5]
	global_load_ushort v85, v80, s[4:5]
	global_load_ushort v87, v78, s[4:5]
	global_load_ushort v89, v77, s[4:5]
	global_load_ushort v91, v79, s[4:5]
	global_load_ushort v93, v81, s[4:5]
	v_accvgpr_read_b32 v10, a28
	v_accvgpr_read_b32 v14, a24
	v_accvgpr_read_b32 v18, a20
	v_accvgpr_read_b32 v25, a19
	v_accvgpr_read_b32 v29, a15
	v_accvgpr_read_b32 v37, a11
	v_accvgpr_read_b32 v41, a7
	v_accvgpr_read_b32 v45, a3
	v_accvgpr_read_b32 v11, a29
	v_accvgpr_read_b32 v12, a30
	v_accvgpr_read_b32 v13, a31
	v_accvgpr_read_b32 v15, a25
	v_accvgpr_read_b32 v16, a26
	v_accvgpr_read_b32 v17, a27
	v_accvgpr_read_b32 v19, a21
	v_accvgpr_read_b32 v20, a22
	v_accvgpr_read_b32 v21, a23
	v_accvgpr_read_b32 v24, a18
	v_accvgpr_read_b32 v23, a17
	v_accvgpr_read_b32 v22, a16
	v_accvgpr_read_b32 v28, a14
	v_accvgpr_read_b32 v27, a13
	v_accvgpr_read_b32 v26, a12
	v_accvgpr_read_b32 v36, a10
	v_accvgpr_read_b32 v35, a9
	v_accvgpr_read_b32 v34, a8
	v_accvgpr_read_b32 v40, a6
	v_accvgpr_read_b32 v39, a5
	v_accvgpr_read_b32 v38, a4
	v_accvgpr_read_b32 v44, a2
	v_accvgpr_read_b32 v43, a1
	v_accvgpr_read_b32 v42, a0
	v_accvgpr_write_b32 a27, 0
	v_accvgpr_write_b32 a26, 0
	v_accvgpr_write_b32 a25, 0
	v_accvgpr_write_b32 a24, 0
	s_waitcnt vmcnt(20)
	v_sub_f32_e32 v0, v63, v47
	v_min_f32_e32 v0, 0, v0
	s_waitcnt vmcnt(19)
	v_sub_f32_e32 v1, v64, v47
	v_mul_f32_e32 v0, 0x3fb8aa3b, v0
	v_min_f32_e32 v1, 0, v1
	v_exp_f32_e32 v0, v0
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v1
	v_accvgpr_write_b32 a23, 0
	v_mul_f32_e32 v0, v49, v0
	v_fma_mixlo_f16 v49, v48, v0, 0
	v_mul_f32_e32 v0, v61, v1
	v_fma_mixlo_f16 v61, v48, v0, 0
	s_waitcnt vmcnt(18)
	v_sub_f32_e32 v0, v65, v47
	v_min_f32_e32 v0, 0, v0
	s_waitcnt vmcnt(17)
	v_sub_f32_e32 v1, v66, v47
	v_mul_f32_e32 v0, 0x3fb8aa3b, v0
	v_min_f32_e32 v1, 0, v1
	v_exp_f32_e32 v0, v0
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_exp_f32_e32 v47, v1
	v_accvgpr_write_b32 a22, 0
	v_mul_f32_e32 v0, v62, v0
	v_fma_mixlo_f16 v62, v48, v0, 0
	v_lshl_add_u64 v[0:1], s[8:9], 0, v[8:9]
	v_accvgpr_write_b32 a21, 0
	v_accvgpr_write_b32 a20, 0
	v_accvgpr_write_b32 a19, 0
	v_accvgpr_write_b32 a18, 0
	v_accvgpr_write_b32 a17, 0
	v_accvgpr_write_b32 a16, 0
	v_accvgpr_write_b32 a15, 0
	v_accvgpr_write_b32 a14, 0
	v_accvgpr_write_b32 a13, 0
	v_accvgpr_write_b32 a12, 0
	s_waitcnt vmcnt(16)
	v_mul_f32_e32 v8, v67, v47
	v_fma_mixlo_f16 v8, v48, v8, 0
	ds_write_b16 v103, v49
	ds_write_b16 v103, v61 offset:256
	ds_write_b16 v103, v62 offset:512
	ds_write_b16 v103, v8 offset:768
	s_waitcnt vmcnt(15)
	ds_write_b16 v51, v5
	s_waitcnt vmcnt(13)
	ds_write_b16 v51, v69 offset:256
	s_waitcnt vmcnt(12)
	ds_write_b16 v51, v70 offset:512
	s_waitcnt vmcnt(11)
	ds_write_b16 v51, v71 offset:768
	s_waitcnt vmcnt(10)
	ds_write_b16 v51, v72 offset:1024
	s_waitcnt vmcnt(9)
	ds_write_b16 v51, v73 offset:1280
	s_waitcnt vmcnt(8)
	ds_write_b16 v51, v74 offset:1536
	s_waitcnt vmcnt(7)
	ds_write_b16 v51, v75 offset:1792
	ds_write_b16 v51, v68 offset:2048
	s_waitcnt vmcnt(6)
	ds_write_b16 v51, v76 offset:2304
	s_waitcnt vmcnt(5)
	ds_write_b16 v51, v83 offset:2560
	s_waitcnt vmcnt(4)
	ds_write_b16 v51, v85 offset:2816
	s_waitcnt vmcnt(3)
	ds_write_b16 v51, v87 offset:3072
	s_waitcnt vmcnt(2)
	ds_write_b16 v51, v89 offset:3328
	s_waitcnt vmcnt(1)
	ds_write_b16 v51, v91 offset:3584
	s_waitcnt vmcnt(0)
	ds_write_b16 v51, v93 offset:3840
	v_mov_b32_e32 v5, v9
	v_lshl_add_u64 v[62:63], v[0:1], 0, 64
	v_lshl_add_u64 v[0:1], s[8:9], 0, v[4:5]
	v_lshl_add_u64 v[68:69], v[0:1], 0, 64
	v_or3_b32 v0, s6, v46, 64
	v_mov_b32_e32 v1, s7
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
	v_lshl_add_u64 v[64:65], v[6:7], 0, 64
	v_lshl_add_u64 v[66:67], v[2:3], 0, 64
	v_lshl_add_u64 v[70:71], s[16:17], 0, v[0:1]
	v_lshl_add_u64 v[72:73], s[18:19], 0, v[0:1]
	s_mov_b32 s3, 0x8000
	v_or_b32_e32 v8, 0x8000, v81
	v_or_b32_e32 v74, 0x8000, v79
	v_mov_b32_e32 v75, v9
	v_or_b32_e32 v76, 0x8000, v77
	v_mov_b32_e32 v77, v9
	v_or_b32_e32 v78, 0x8000, v78
	v_mov_b32_e32 v79, v9
	v_or_b32_e32 v80, 0x8000, v80
	v_mov_b32_e32 v81, v9
	v_or_b32_e32 v82, 0x8000, v82
	v_mov_b32_e32 v83, v9
	v_or_b32_e32 v84, 0x8000, v84
	v_mov_b32_e32 v85, v9
	v_or_b32_e32 v86, 0x8000, v86
	v_mov_b32_e32 v87, v9
	v_or_b32_e32 v88, 0x8000, v88
	v_mov_b32_e32 v89, v9
	v_or_b32_e32 v90, 0x8000, v90
	v_mov_b32_e32 v91, v9
	v_or_b32_e32 v92, 0x8000, v92
	v_mov_b32_e32 v93, v9
	v_or_b32_e32 v94, 0x8000, v94
	v_mov_b32_e32 v95, v9
	v_or_b32_e32 v96, 0x8000, v96
	v_mov_b32_e32 v97, v9
	v_or_b32_e32 v98, 0x8000, v98
	v_mov_b32_e32 v99, v9
	v_mov_b32_e32 v61, v9
	v_mov_b32_e32 v0, v9
	v_mov_b32_e32 v1, v9
	v_mov_b32_e32 v2, v9
	v_mov_b32_e32 v3, v9
	v_mov_b32_e32 v4, v9
	v_mov_b32_e32 v6, v9
	v_mov_b32_e32 v7, v9
	s_mov_b64 s[6:7], 0
	s_mov_b32 s12, 0x5040100
	s_mov_b32 s13, s1
	v_mov_b32_e32 v106, v9
	v_mov_b32_e32 v107, v9
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .LBB0_8
.LBB0_7:                                ; %if.end40.i237
                                        ;   in Loop: Header=BB0_8 Depth=1
	s_add_i32 s13, s13, 16
	s_add_u32 s6, s6, 64
	s_addc_u32 s7, s7, 0
	s_add_u32 s4, s4, 0x8000
	s_addc_u32 s5, s5, 0
	s_andn2_b64 vcc, exec, s[8:9]
	s_add_i32 s1, s1, 1
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccz .LBB0_12
.LBB0_8:                                ; %for.body.i233
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lt_u32 s13, 0x70
	s_cselect_b64 s[10:11], -1, 0
	s_cmpk_gt_u32 s13, 0x6f
	s_cselect_b64 s[8:9], -1, 0
	s_and_b64 vcc, exec, s[8:9]
	s_cbranch_vccnz .LBB0_10
; %bb.9:                                ; %if.then.i239
                                        ;   in Loop: Header=BB0_8 Depth=1
	v_lshl_add_u64 v[0:1], v[72:73], 0, s[6:7]
	global_load_dword v120, v[52:53], off
	global_load_dword v121, v[0:1], off
	global_load_dword v122, v[54:55], off
	global_load_dword v123, v[56:57], off
	global_load_dword v124, v[58:59], off
	v_lshl_add_u64 v[48:49], s[4:5], 0, v[86:87]
	v_lshl_add_u64 v[110:111], s[4:5], 0, v[80:81]
	v_lshl_add_u64 v[112:113], s[4:5], 0, v[78:79]
	v_lshl_add_u64 v[114:115], s[4:5], 0, v[76:77]
	v_lshl_add_u64 v[116:117], s[4:5], 0, v[74:75]
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[92:93]
	v_lshl_add_u64 v[6:7], s[4:5], 0, v[90:91]
	v_lshl_add_u64 v[46:47], s[4:5], 0, v[88:89]
	v_lshl_add_u64 v[106:107], s[4:5], 0, v[84:85]
	v_lshl_add_u64 v[108:109], s[4:5], 0, v[82:83]
	v_lshl_add_u64 v[118:119], s[4:5], 0, v[8:9]
	global_load_ushort v125, v[48:49], off
	global_load_ushort v126, v[106:107], off
	global_load_ushort v127, v[108:109], off
	s_nop 0
	global_load_ushort v110, v[110:111], off
	s_nop 0
	global_load_ushort v111, v[112:113], off
	s_nop 0
	global_load_ushort v112, v[114:115], off
	global_load_ushort v113, v[116:117], off
	s_nop 0
	global_load_ushort v114, v[118:119], off
	global_load_ushort v115, v[0:1], off
	global_load_ushort v116, v[6:7], off
	global_load_ushort v117, v[46:47], off
	v_lshl_add_u64 v[48:49], s[4:5], 0, v[60:61]
	v_lshl_add_u64 v[2:3], v[70:71], 0, s[6:7]
	v_lshl_add_u64 v[0:1], v[66:67], 0, s[6:7]
	v_add_co_u32_e32 v48, vcc, s3, v48
	v_lshl_add_u64 v[106:107], s[4:5], 0, v[96:97]
	v_lshl_add_u64 v[108:109], s[4:5], 0, v[94:95]
	v_lshl_add_u64 v[4:5], v[68:69], 0, s[6:7]
	v_lshl_add_u64 v[6:7], v[64:65], 0, s[6:7]
	v_lshl_add_u64 v[46:47], v[62:63], 0, s[6:7]
	v_addc_co_u32_e32 v49, vcc, 0, v49, vcc
	global_load_ushort v118, v[106:107], off
	global_load_ushort v119, v[108:109], off
	global_load_ushort v128, v[48:49], off offset:128
	s_nop 0
	global_load_dword v106, v[4:5], off
	global_load_dword v107, v[0:1], off
	global_load_dword v108, v[6:7], off
	global_load_dword v109, v[46:47], off
	s_nop 0
	global_load_dword v0, v[2:3], off
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[98:99]
	global_load_ushort v129, v[2:3], off
	global_load_ushort v130, v[48:49], off
	s_waitcnt vmcnt(24)
	v_sub_f32_e32 v1, v120, v121
	s_waitcnt vmcnt(23)
	v_sub_f32_e32 v4, v122, v121
	s_waitcnt vmcnt(22)
	v_sub_f32_e32 v46, v123, v121
	s_waitcnt vmcnt(21)
	v_sub_f32_e32 v47, v124, v121
	v_min_f32_e32 v1, 0, v1
	v_min_f32_e32 v4, 0, v4
	v_min_f32_e32 v46, 0, v46
	v_min_f32_e32 v47, 0, v47
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_mul_f32_e32 v4, 0x3fb8aa3b, v4
	v_mul_f32_e32 v48, 0x3fb8aa3b, v46
	v_mul_f32_e32 v49, 0x3fb8aa3b, v47
	v_exp_f32_e32 v46, v1
	v_exp_f32_e32 v47, v4
	v_exp_f32_e32 v48, v48
	v_exp_f32_e32 v49, v49
	s_waitcnt vmcnt(13)
	v_perm_b32 v7, v114, v113, s12
	v_perm_b32 v6, v112, v111, s12
	v_perm_b32 v5, v110, v127, s12
	s_waitcnt vmcnt(10)
	v_perm_b32 v3, v125, v117, s12
	v_perm_b32 v2, v116, v115, s12
	s_waitcnt vmcnt(8)
	v_perm_b32 v1, v119, v118, s12
	s_waitcnt vmcnt(7)
	v_perm_b32 v4, v126, v128, s12
	s_waitcnt vmcnt(5)
	v_pk_mul_f32 v[46:47], v[106:107], v[46:47]
	s_waitcnt vmcnt(3)
	v_pk_mul_f32 v[48:49], v[108:109], v[48:49]
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[46:47], v[0:1], v[46:47] op_sel_hi:[0,1]
	v_pk_mul_f32 v[48:49], v[0:1], v[48:49] op_sel_hi:[0,1]
	v_cvt_pk_f16_f32 v106, v46, v47
	v_cvt_pk_f16_f32 v107, v48, v49
	s_waitcnt vmcnt(0)
	v_perm_b32 v0, v129, v130, s12
.LBB0_10:                               ; %if.end.i235
                                        ;   in Loop: Header=BB0_8 Depth=1
	s_and_b32 s14, s1, 1
	v_lshl_add_u32 v46, s14, 10, v104
	ds_read_b64 v[112:113], v46
	v_lshl_or_b32 v114, s14, 12, v105
	ds_read2st64_b64 v[46:49], v114 offset1:1
	ds_read2st64_b64 v[108:111], v114 offset0:2 offset1:3
	s_andn2_b64 vcc, exec, s[10:11]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 a[0:3], v[112:113], v[46:47], a[0:3]
	v_mfma_f32_16x16x16_f16 a[4:7], v[112:113], v[48:49], a[4:7]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[8:11], v[112:113], v[108:109], a[8:11]
	v_mfma_f32_16x16x16_f16 a[12:15], v[112:113], v[110:111], a[12:15]
	ds_read2st64_b64 v[46:49], v114 offset0:4 offset1:5
	ds_read2st64_b64 v[108:111], v114 offset0:6 offset1:7
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 a[16:19], v[112:113], v[46:47], a[16:19]
	v_mfma_f32_16x16x16_f16 a[20:23], v[112:113], v[48:49], a[20:23]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[24:27], v[112:113], v[108:109], a[24:27]
	v_mfma_f32_16x16x16_f16 a[28:31], v[112:113], v[110:111], a[28:31]
	s_cbranch_vccnz .LBB0_7
; %bb.11:                               ; %if.then34.i238
                                        ;   in Loop: Header=BB0_8 Depth=1
	s_xor_b32 s10, s14, 1
	v_lshl_add_u32 v46, s10, 10, v103
	ds_write_b16 v46, v106
	ds_write_b16_d16_hi v46, v106 offset:256
	ds_write_b16 v46, v107 offset:512
	ds_write_b16_d16_hi v46, v107 offset:768
	v_lshl_or_b32 v46, s10, 12, v51
	ds_write_b16 v46, v0
	ds_write_b16_d16_hi v46, v0 offset:256
	ds_write_b16 v46, v1 offset:512
	ds_write_b16_d16_hi v46, v1 offset:768
	ds_write_b16 v46, v2 offset:1024
	ds_write_b16_d16_hi v46, v2 offset:1280
	ds_write_b16 v46, v3 offset:1536
	ds_write_b16_d16_hi v46, v3 offset:1792
	ds_write_b16 v46, v4 offset:2048
	ds_write_b16_d16_hi v46, v4 offset:2304
	ds_write_b16 v46, v5 offset:2560
	ds_write_b16_d16_hi v46, v5 offset:2816
	ds_write_b16 v46, v6 offset:3072
	ds_write_b16_d16_hi v46, v6 offset:3328
	ds_write_b16 v46, v7 offset:3584
	ds_write_b16_d16_hi v46, v7 offset:3840
	s_branch .LBB0_7
.LBB0_12:                               ; %for.cond87.preheader
	v_mul_f32_e32 v9, 0x3fb8aa3b, v30
	v_exp_f32_e32 v9, v9
	s_lshl_b32 s1, s2, 15
	v_mul_f32_e32 v30, 0x3fb8aa3b, v31
	s_add_i32 s0, s0, s1
	s_mov_b32 s1, 0
	v_accvgpr_read_b32 v71, a3
	v_exp_f32_e32 v30, v30
	v_mul_f32_e32 v31, 0x3fb8aa3b, v32
	s_lshl_b64 s[2:3], s[0:1], 1
	v_or_b32_e32 v32, v101, v102
	v_accvgpr_read_b32 v68, a0
	v_exp_f32_e32 v31, v31
	s_add_u32 s0, s20, s2
	v_lshlrev_b32_e32 v32, 10, v32
	v_mul_f32_e32 v8, 0x3fb8aa3b, v33
	s_addc_u32 s1, s21, s3
	v_fma_mixlo_f16 v33, v42, v9, v68
	v_or_b32_e32 v42, v32, v50
	v_accvgpr_read_b32 v69, a1
	s_add_u32 s2, s22, s2
	v_lshlrev_b32_e32 v42, 1, v42
	v_accvgpr_read_b32 v70, a2
	v_exp_f32_e32 v8, v8
	s_addc_u32 s3, s23, s3
	global_store_short v42, v33, s[0:1]
	v_mov_b32_e32 v33, 0
	v_fma_mixlo_f16 v43, v43, v30, v69
	global_store_short v42, v33, s[2:3]
	global_store_short v42, v43, s[0:1] offset:2048
	global_store_short v42, v33, s[2:3] offset:2048
	v_fma_mixlo_f16 v43, v44, v31, v70
	v_or_b32_e32 v44, 0x800, v32
	v_or_b32_e32 v51, v44, v50
	v_lshlrev_b32_e32 v51, 1, v51
	v_accvgpr_read_b32 v67, a7
	global_store_short v51, v43, s[0:1]
	global_store_short v51, v33, s[2:3]
	v_fma_mixlo_f16 v43, v45, v8, v71
	v_or_b32_e32 v45, 0xc00, v32
	v_accvgpr_read_b32 v64, a4
	v_or_b32_e32 v51, v45, v50
	v_accvgpr_read_b32 v65, a5
	v_lshlrev_b32_e32 v51, 1, v51
	v_fma_mixlo_f16 v38, v38, v9, v64
	global_store_short v51, v43, s[0:1]
	global_store_short v51, v33, s[2:3]
	global_store_short v42, v38, s[0:1] offset:32
	global_store_short v42, v33, s[2:3] offset:32
	v_fma_mixlo_f16 v38, v39, v30, v65
	v_or_b32_e32 v39, v32, v100
	v_lshlrev_b32_e32 v39, 1, v39
	v_accvgpr_read_b32 v66, a6
	global_store_short v39, v38, s[0:1] offset:2048
	global_store_short v39, v33, s[2:3] offset:2048
	v_or_b32_e32 v39, v44, v100
	v_fma_mixlo_f16 v38, v40, v31, v66
	v_lshlrev_b32_e32 v39, 1, v39
	v_accvgpr_read_b32 v63, a11
	global_store_short v39, v38, s[0:1]
	global_store_short v39, v33, s[2:3]
	v_or_b32_e32 v39, v45, v100
	v_accvgpr_read_b32 v60, a8
	v_fma_mixlo_f16 v38, v41, v8, v67
	v_lshlrev_b32_e32 v39, 1, v39
	v_accvgpr_read_b32 v61, a9
	global_store_short v39, v38, s[0:1]
	global_store_short v39, v33, s[2:3]
	v_or_b32_e32 v38, 32, v50
	v_fma_mixlo_f16 v34, v34, v9, v60
	global_store_short v42, v34, s[0:1] offset:64
	global_store_short v42, v33, s[2:3] offset:64
	v_fma_mixlo_f16 v34, v35, v30, v61
	v_or_b32_e32 v35, v32, v38
	v_lshlrev_b32_e32 v35, 1, v35
	v_accvgpr_read_b32 v62, a10
	global_store_short v35, v34, s[0:1] offset:2048
	global_store_short v35, v33, s[2:3] offset:2048
	v_or_b32_e32 v35, v44, v38
	v_fma_mixlo_f16 v34, v36, v31, v62
	v_lshlrev_b32_e32 v35, 1, v35
	v_accvgpr_read_b32 v59, a15
	global_store_short v35, v34, s[0:1]
	global_store_short v35, v33, s[2:3]
	v_or_b32_e32 v35, v45, v38
	v_accvgpr_read_b32 v56, a12
	v_fma_mixlo_f16 v34, v37, v8, v63
	v_lshlrev_b32_e32 v35, 1, v35
	v_accvgpr_read_b32 v57, a13
	global_store_short v35, v34, s[0:1]
	global_store_short v35, v33, s[2:3]
	v_or_b32_e32 v34, 48, v50
	v_fma_mixlo_f16 v26, v26, v9, v56
	global_store_short v42, v26, s[0:1] offset:96
	global_store_short v42, v33, s[2:3] offset:96
	v_fma_mixlo_f16 v26, v27, v30, v57
	v_or_b32_e32 v27, v32, v34
	v_lshlrev_b32_e32 v27, 1, v27
	v_accvgpr_read_b32 v58, a14
	global_store_short v27, v26, s[0:1] offset:2048
	global_store_short v27, v33, s[2:3] offset:2048
	v_or_b32_e32 v27, v44, v34
	v_fma_mixlo_f16 v26, v28, v31, v58
	v_lshlrev_b32_e32 v27, 1, v27
	v_accvgpr_read_b32 v55, a19
	global_store_short v27, v26, s[0:1]
	global_store_short v27, v33, s[2:3]
	v_or_b32_e32 v27, v45, v34
	v_accvgpr_read_b32 v52, a16
	v_fma_mixlo_f16 v26, v29, v8, v59
	v_lshlrev_b32_e32 v27, 1, v27
	v_accvgpr_read_b32 v53, a17
	global_store_short v27, v26, s[0:1]
	global_store_short v27, v33, s[2:3]
	v_or_b32_e32 v26, 64, v50
	v_fma_mixlo_f16 v22, v22, v9, v52
	global_store_short v42, v22, s[0:1] offset:128
	global_store_short v42, v33, s[2:3] offset:128
	v_fma_mixlo_f16 v22, v23, v30, v53
	v_or_b32_e32 v23, v32, v26
	v_lshlrev_b32_e32 v23, 1, v23
	v_accvgpr_read_b32 v54, a18
	global_store_short v23, v22, s[0:1] offset:2048
	global_store_short v23, v33, s[2:3] offset:2048
	v_or_b32_e32 v23, v44, v26
	v_fma_mixlo_f16 v22, v24, v31, v54
	v_lshlrev_b32_e32 v23, 1, v23
	global_store_short v23, v22, s[0:1]
	global_store_short v23, v33, s[2:3]
	v_or_b32_e32 v23, v45, v26
	v_accvgpr_read_b32 v4, a20
	v_fma_mixlo_f16 v22, v25, v8, v55
	v_lshlrev_b32_e32 v23, 1, v23
	v_accvgpr_read_b32 v5, a21
	global_store_short v23, v22, s[0:1]
	global_store_short v23, v33, s[2:3]
	v_or_b32_e32 v22, 0x50, v50
	v_fma_mixlo_f16 v4, v18, v9, v4
	global_store_short v42, v4, s[0:1] offset:160
	global_store_short v42, v33, s[2:3] offset:160
	v_fma_mixlo_f16 v4, v19, v30, v5
	v_or_b32_e32 v5, v32, v22
	v_lshlrev_b32_e32 v5, 1, v5
	v_accvgpr_read_b32 v6, a22
	global_store_short v5, v4, s[0:1] offset:2048
	global_store_short v5, v33, s[2:3] offset:2048
	v_or_b32_e32 v5, v44, v22
	v_fma_mixlo_f16 v4, v20, v31, v6
	v_lshlrev_b32_e32 v5, 1, v5
	v_accvgpr_read_b32 v7, a23
	global_store_short v5, v4, s[0:1]
	global_store_short v5, v33, s[2:3]
	v_or_b32_e32 v5, v45, v22
	v_accvgpr_read_b32 v0, a24
	v_fma_mixlo_f16 v4, v21, v8, v7
	v_lshlrev_b32_e32 v5, 1, v5
	v_accvgpr_read_b32 v1, a25
	global_store_short v5, v4, s[0:1]
	global_store_short v5, v33, s[2:3]
	v_or_b32_e32 v4, 0x60, v50
	v_fma_mixlo_f16 v0, v14, v9, v0
	global_store_short v42, v0, s[0:1] offset:192
	global_store_short v42, v33, s[2:3] offset:192
	v_fma_mixlo_f16 v0, v15, v30, v1
	v_or_b32_e32 v1, v32, v4
	v_lshlrev_b32_e32 v1, 1, v1
	v_accvgpr_read_b32 v2, a26
	global_store_short v1, v0, s[0:1] offset:2048
	global_store_short v1, v33, s[2:3] offset:2048
	v_or_b32_e32 v1, v44, v4
	v_fma_mixlo_f16 v0, v16, v31, v2
	v_lshlrev_b32_e32 v1, 1, v1
	v_accvgpr_read_b32 v3, a27
	global_store_short v1, v0, s[0:1]
	global_store_short v1, v33, s[2:3]
	v_or_b32_e32 v1, v45, v4
	v_accvgpr_read_b32 v49, a31
	v_fma_mixlo_f16 v0, v17, v8, v3
	v_lshlrev_b32_e32 v1, 1, v1
	v_accvgpr_read_b32 v46, a28
	global_store_short v1, v0, s[0:1]
	global_store_short v1, v33, s[2:3]
	v_or_b32_e32 v0, 0x70, v50
	v_accvgpr_read_b32 v47, a29
	v_fma_mixlo_f16 v1, v10, v9, v46
	v_or_b32_e32 v2, v32, v0
	global_store_short v42, v1, s[0:1] offset:224
	global_store_short v42, v33, s[2:3] offset:224
	v_fma_mixlo_f16 v1, v11, v30, v47
	v_lshlrev_b32_e32 v2, 1, v2
	v_accvgpr_read_b32 v48, a30
	global_store_short v2, v1, s[0:1] offset:2048
	global_store_short v2, v33, s[2:3] offset:2048
	v_or_b32_e32 v2, v44, v0
	v_fma_mixlo_f16 v1, v12, v31, v48
	v_lshlrev_b32_e32 v2, 1, v2
	v_or_b32_e32 v0, v45, v0
	global_store_short v2, v1, s[0:1]
	global_store_short v2, v33, s[2:3]
	v_fma_mixlo_f16 v1, v13, v8, v49
	v_lshlrev_b32_e32 v0, 1, v0
	global_store_short v0, v1, s[0:1]
	global_store_short v0, v33, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mamba2_chunk_scan_full
		.amdhsa_group_segment_fixed_size 10240
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 164
		.amdhsa_next_free_sgpr 27
		.amdhsa_accum_offset 132
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
	.size	mamba2_chunk_scan_full, .Lfunc_end0-mamba2_chunk_scan_full
                                        ; -- End function
	.set mamba2_chunk_scan_full.num_vgpr, 131
	.set mamba2_chunk_scan_full.num_agpr, 32
	.set mamba2_chunk_scan_full.numbered_sgpr, 27
	.set mamba2_chunk_scan_full.num_named_barrier, 0
	.set mamba2_chunk_scan_full.private_seg_size, 0
	.set mamba2_chunk_scan_full.uses_vcc, 1
	.set mamba2_chunk_scan_full.uses_flat_scratch, 0
	.set mamba2_chunk_scan_full.has_dyn_sized_stack, 0
	.set mamba2_chunk_scan_full.has_recursion, 0
	.set mamba2_chunk_scan_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 6580
; TotalNumSgprs: 33
; NumVgprs: 131
; NumAgprs: 32
; TotalNumVgprs: 164
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 10240 bytes/workgroup (compile time only)
; SGPRBlocks: 4
; VGPRBlocks: 20
; NumSGPRsForWavesPerEU: 33
; NumVGPRsForWavesPerEU: 164
; AccumOffset: 132
; Occupancy: 3
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 32
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_3a8e0072e2f62122,@object ; @__hip_cuid_3a8e0072e2f62122
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_3a8e0072e2f62122
__hip_cuid_3a8e0072e2f62122:
	.byte	0                               ; 0x0
	.size	__hip_cuid_3a8e0072e2f62122, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_3a8e0072e2f62122
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     32
    .args:
      - .address_space:  global
        .name:           cb.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           x.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           c.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           prev.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           dt.coerce
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           da.coerce
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out_x.coerce
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 10240
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           mamba2_chunk_scan_full
    .private_segment_fixed_size: 0
    .sgpr_count:     33
    .sgpr_spill_count: 0
    .symbol:         mamba2_chunk_scan_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     164
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
