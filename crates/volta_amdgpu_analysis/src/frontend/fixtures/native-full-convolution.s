	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	convolution_f16_full    ; -- Begin function convolution_f16_full
	.globl	convolution_f16_full
	.p2align	8
	.type	convolution_f16_full,@function
convolution_f16_full:                   ; @convolution_f16_full
; %bb.0:                                ; %entry
	v_and_b32_e32 v34, 15, v0
	v_cmp_lt_u32_e32 vcc, 8, v34
	v_add_u16_e32 v2, -9, v34
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	v_cndmask_b32_e64 v1, 0, 1, vcc
	v_cmp_gt_u32_e32 vcc, 9, v34
	s_movk_i32 s0, 0xab
	s_lshl_b32 s2, s2, 7
	v_cndmask_b32_e32 v2, v2, v34, vcc
	v_mul_lo_u16_sdwa v3, v2, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v4, 9, v3
	v_mul_lo_u16_e32 v3, 3, v4
	v_lshrrev_b32_e32 v6, 4, v0
	v_sub_u16_e32 v5, v2, v3
	v_or_b32_e32 v2, s2, v6
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v3, v2, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_u32_u24_e32 v7, 0xb64, v3
	v_sub_u32_e32 v2, v2, v7
	v_lshrrev_b16_e32 v7, 1, v2
	v_mul_u32_u24_e32 v7, 0x97b5, v7
	v_lshrrev_b32_e32 v35, 20, v7
	v_mul_lo_u16_e32 v8, 54, v35
	v_lshlrev_b32_e32 v37, 6, v3
	v_add_u32_e32 v7, v35, v4
	v_sub_u16_e32 v36, v2, v8
	v_or_b32_e32 v2, v37, v1
	s_movk_i32 s11, 0xc40
	v_mul_lo_u32 v2, v2, s11
	v_mul_u32_u24_e32 v3, 56, v7
	v_add_u32_sdwa v7, v36, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v32, v7, v2, v3
	v_mov_b32_e32 v33, 0
	s_lshl_b32 s10, s3, 7
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[4:5]
	global_load_ushort v7, v[2:3], off
	v_or_b32_e32 v2, s10, v6
	s_movk_i32 s1, 0x240
	v_mul_lo_u32 v2, v2, s1
	v_or_b32_e32 v32, v2, v34
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[6:7]
	global_load_ushort v8, v[2:3], off
	v_or_b32_e32 v2, 0x200, v0
	v_lshrrev_b32_e32 v9, 4, v2
	v_or_b32_e32 v2, s2, v9
	v_mul_hi_u32 v3, v2, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_u32_u24_e32 v10, 0xb64, v3
	v_sub_u32_e32 v2, v2, v10
	v_lshrrev_b16_e32 v10, 1, v2
	v_mul_u32_u24_e32 v10, 0x97b5, v10
	v_lshrrev_b32_e32 v38, 20, v10
	v_mul_lo_u16_e32 v11, 54, v38
	v_lshlrev_b32_e32 v40, 6, v3
	v_add_u32_e32 v10, v38, v4
	v_sub_u16_e32 v39, v2, v11
	v_or_b32_e32 v2, v40, v1
	v_mul_lo_u32 v2, v2, s11
	v_mul_u32_u24_e32 v3, 56, v10
	v_add_u32_sdwa v10, v39, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v32, v10, v2, v3
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[4:5]
	global_load_ushort v10, v[2:3], off
	v_or_b32_e32 v2, s10, v9
	v_mul_lo_u32 v2, v2, s1
	v_or_b32_e32 v32, v2, v34
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[6:7]
	v_or_b32_e32 v12, 64, v6
	global_load_ushort v11, v[2:3], off
	v_or_b32_e32 v2, s2, v12
	v_mul_hi_u32 v3, v2, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_u32_u24_e32 v13, 0xb64, v3
	v_sub_u32_e32 v2, v2, v13
	v_lshrrev_b16_e32 v13, 1, v2
	v_mul_u32_u24_e32 v13, 0x97b5, v13
	v_lshrrev_b32_e32 v41, 20, v13
	v_mul_lo_u16_e32 v14, 54, v41
	v_lshlrev_b32_e32 v43, 6, v3
	v_add_u32_e32 v13, v41, v4
	v_sub_u16_e32 v42, v2, v14
	v_or_b32_e32 v2, v43, v1
	v_mul_lo_u32 v2, v2, s11
	v_mul_u32_u24_e32 v3, 56, v13
	v_add_u32_sdwa v13, v42, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v32, v13, v2, v3
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[4:5]
	global_load_ushort v13, v[2:3], off
	v_or_b32_e32 v2, s10, v12
	v_mul_lo_u32 v2, v2, s1
	v_or_b32_e32 v32, v2, v34
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[6:7]
	global_load_ushort v12, v[2:3], off
	v_or_b32_e32 v2, 0x600, v0
	v_lshrrev_b32_e32 v14, 4, v2
	v_or_b32_e32 v2, s2, v14
	v_mul_hi_u32 v3, v2, s0
	v_lshrrev_b32_e32 v3, 10, v3
	v_mul_u32_u24_e32 v15, 0xb64, v3
	v_sub_u32_e32 v2, v2, v15
	v_lshrrev_b16_e32 v15, 1, v2
	v_mul_u32_u24_e32 v15, 0x97b5, v15
	v_lshrrev_b32_e32 v44, 20, v15
	v_mul_lo_u16_e32 v15, 54, v44
	v_lshlrev_b32_e32 v46, 6, v3
	v_add_u32_e32 v4, v44, v4
	v_sub_u16_e32 v45, v2, v15
	v_or_b32_e32 v1, v46, v1
	v_mul_lo_u32 v1, v1, s11
	v_mul_u32_u24_e32 v2, 56, v4
	v_add_u32_sdwa v3, v45, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v32, v3, v1, v2
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[4:5]
	global_load_ushort v1, v[2:3], off
	v_or_b32_e32 v2, s10, v14
	v_mul_lo_u32 v2, v2, s1
	v_or_b32_e32 v32, v2, v34
	v_lshl_add_u64 v[2:3], v[32:33], 1, s[6:7]
	global_load_ushort v2, v[2:3], off
	v_lshlrev_b32_e32 v48, 1, v0
	s_waitcnt vmcnt(7)
	ds_write_b16 v48, v7
	v_lshrrev_b32_e32 v47, 6, v0
	s_movk_i32 s0, 0x2000
	v_or_b32_e32 v49, 0x2000, v48
	s_mov_b32 s12, 0xe38f
	s_mov_b32 s13, 0x5040100
	s_mov_b32 s14, 0
	v_mov_b32_e32 v3, v33
	v_mov_b32_e32 v4, v33
	v_mov_b32_e32 v5, v33
	v_mov_b32_e32 v7, v33
	v_mov_b32_e32 v15, v33
	v_mov_b32_e32 v16, v33
	v_mov_b32_e32 v17, v33
	v_mov_b32_e32 v18, v33
	v_mov_b32_e32 v19, v33
	v_mov_b32_e32 v20, v33
	v_mov_b32_e32 v21, v33
	v_mov_b32_e32 v22, v33
	v_mov_b32_e32 v23, v33
	v_mov_b32_e32 v24, v33
	v_mov_b32_e32 v25, v33
	v_mov_b32_e32 v26, v33
	v_mov_b32_e32 v27, v33
	v_mov_b32_e32 v28, v33
	v_mov_b32_e32 v29, v33
	v_mov_b32_e32 v30, v33
	v_mov_b32_e32 v31, v33
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v58, 0
	s_waitcnt vmcnt(6)
	ds_write_b16 v48, v8 offset:8192
	s_waitcnt vmcnt(5)
	ds_write_b16 v48, v10 offset:1024
	s_waitcnt vmcnt(4)
	ds_write_b16 v48, v11 offset:9216
	s_waitcnt vmcnt(3)
	ds_write_b16 v48, v13 offset:2048
	s_waitcnt vmcnt(2)
	ds_write_b16 v48, v12 offset:10240
	s_waitcnt vmcnt(1)
	ds_write_b16 v48, v1 offset:3072
	s_waitcnt vmcnt(0)
	ds_write_b16 v48, v2 offset:11264
	v_lshrrev_b32_e32 v1, 2, v0
	v_and_b32_e32 v50, 12, v1
	v_lshlrev_b32_e32 v0, 5, v0
	v_and_b32_e32 v0, 0x1e0, v0
	v_lshlrev_b32_e32 v2, 1, v50
	v_lshlrev_b32_e32 v1, 9, v47
	v_or3_b32 v52, v0, v2, s0
	s_mul_i32 s0, s3, 0x12000
	v_or3_b32 v51, v1, v0, v2
	v_mov_b32_e32 v0, s0
	v_mad_u32_u24 v1, v14, s1, v0
	v_or3_b32 v53, v1, v34, 16
	v_mad_u32_u24 v1, v6, s1, v0
	v_mad_u32_u24 v0, v9, s1, v0
	v_or_b32_e32 v54, v1, v34
	v_or3_b32 v55, v0, v34, 16
	s_mov_b32 s3, 0
	v_mov_b32_e32 v0, v33
	v_mov_b32_e32 v1, v33
	v_mov_b32_e32 v2, v33
	v_mov_b32_e32 v6, v33
	v_mov_b32_e32 v8, v33
	v_mov_b32_e32 v9, v33
	v_mov_b32_e32 v10, v33
	v_mov_b32_e32 v11, v33
	v_mov_b32_e32 v12, v33
	v_mov_b32_e32 v13, v33
	v_mov_b32_e32 v14, v33
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end54.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s14, s14, 16
	s_addk_i32 s3, 0x800
	s_cmpk_lg_i32 s14, 0x240
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc0 .LBB0_6
.LBB0_2:                                ; %for.body.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lg_i32 s14, 0x230
	s_cselect_b64 s[0:1], -1, 0
	s_cmpk_eq_i32 s14, 0x230
	s_cbranch_scc1 .LBB0_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_add3_u32 v32, v34, s14, 16
	v_mul_u32_u24_sdwa v56, v32, s12 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v58, 19, v56
	v_mul_lo_u16_e32 v56, 9, v58
	v_sub_u16_e32 v32, v32, v56
	v_mul_lo_u16_e32 v56, 0xab, v32
	v_lshrrev_b16_e32 v59, 9, v56
	v_mul_lo_u16_e32 v56, 3, v59
	v_sub_u16_e32 v60, v32, v56
	v_add_u32_e32 v32, v59, v35
	v_add_u32_e32 v56, v37, v58
	v_mul_lo_u32 v56, v56, s11
	v_mul_u32_u24_e32 v32, 56, v32
	v_add_u32_sdwa v57, v60, v36 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v32, v57, v56, v32
	v_add_u32_e32 v62, s14, v54
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[4:5]
	v_add_u32_e32 v32, 16, v62
	global_load_ushort v61, v[56:57], off
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[6:7]
	global_load_ushort v63, v[56:57], off
	v_add_u32_e32 v32, v59, v38
	v_add_u32_e32 v56, v40, v58
	v_mul_lo_u32 v56, v56, s11
	v_mul_u32_u24_e32 v32, 56, v32
	v_add_u32_sdwa v57, v60, v39 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v32, v57, v56, v32
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[4:5]
	v_add_u32_e32 v32, s14, v55
	global_load_ushort v64, v[56:57], off
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[6:7]
	global_load_ushort v65, v[56:57], off
	v_add_u32_e32 v32, v59, v41
	v_add_u32_e32 v56, v43, v58
	v_mul_lo_u32 v56, v56, s11
	v_mul_u32_u24_e32 v32, 56, v32
	v_add_u32_sdwa v57, v60, v42 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v32, v57, v56, v32
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[4:5]
	v_add_u32_e32 v32, 0x9010, v62
	global_load_ushort v66, v[56:57], off
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[6:7]
	global_load_ushort v62, v[56:57], off
	v_add_u32_e32 v32, v59, v44
	v_add_u32_e32 v56, v46, v58
	v_mul_lo_u32 v56, v56, s11
	v_mul_u32_u24_e32 v32, 56, v32
	v_add_u32_sdwa v57, v60, v45 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v32, v57, v56, v32
	v_lshl_add_u64 v[56:57], v[32:33], 1, s[4:5]
	v_add_u32_e32 v32, s14, v53
	v_lshl_add_u64 v[58:59], v[32:33], 1, s[6:7]
	global_load_ushort v60, v[58:59], off
	global_load_ushort v67, v[56:57], off
	s_waitcnt vmcnt(5)
	v_perm_b32 v32, v64, v61, s13
	s_waitcnt vmcnt(4)
	v_perm_b32 v56, v65, v63, s13
	s_waitcnt vmcnt(1)
	v_perm_b32 v58, v60, v62, s13
	s_waitcnt vmcnt(0)
	v_perm_b32 v57, v67, v66, s13
.LBB0_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_and_b32 s15, s3, 0x800
	s_lshl_b32 s16, s15, 1
	v_or_b32_e32 v59, s16, v51
	ds_read_b64 v[68:69], v59
	v_add_u32_e32 v59, s16, v52
	ds_read2st64_b64 v[60:63], v59 offset1:1
	ds_read2st64_b64 v[64:67], v59 offset0:2 offset1:3
	s_andn2_b64 vcc, exec, s[0:1]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 v[28:31], v[68:69], v[60:61], v[28:31]
	v_mfma_f32_16x16x16_f16 v[24:27], v[68:69], v[62:63], v[24:27]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 v[20:23], v[68:69], v[64:65], v[20:23]
	v_mfma_f32_16x16x16_f16 v[16:19], v[68:69], v[66:67], v[16:19]
	ds_read2st64_b64 v[60:63], v59 offset0:4 offset1:5
	ds_read2st64_b64 v[64:67], v59 offset0:6 offset1:7
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 v[12:15], v[68:69], v[60:61], v[12:15]
	v_mfma_f32_16x16x16_f16 v[8:11], v[68:69], v[62:63], v[8:11]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 v[4:7], v[68:69], v[64:65], v[4:7]
	v_mfma_f32_16x16x16_f16 v[0:3], v[68:69], v[66:67], v[0:3]
	s_cbranch_vccnz .LBB0_1
; %bb.5:                                ; %if.then50.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_xor_b32 s0, s15, 0x800
	s_lshl_b32 s0, s0, 1
	v_add_u32_e32 v59, s0, v48
	v_add_u32_e32 v60, s0, v49
	ds_write_b16 v59, v32
	ds_write_b16 v60, v56
	ds_write_b16_d16_hi v59, v32 offset:1024
	ds_write_b16_d16_hi v60, v56 offset:1024
	ds_write_b16 v59, v57 offset:2048
	ds_write_b16 v60, v58 offset:2048
	ds_write_b16_d16_hi v59, v57 offset:3072
	ds_write_b16_d16_hi v60, v58 offset:3072
	s_branch .LBB0_1
.LBB0_6:                                ; %_Z16convolution_fullILb0EEvPKvS1_PVDF16_PDF16_S4_.exit
	v_lshl_add_u32 v32, v47, 4, s2
	v_or_b32_e32 v36, v32, v50
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v32, v36, s0
	v_lshrrev_b32_e32 v32, 10, v32
	v_or_b32_e32 v33, s10, v34
	v_lshl_add_u32 v33, v32, 7, v33
	s_movk_i32 s1, 0xb64
	v_cvt_f16_f32_e32 v28, v28
	v_mul_u32_u24_e32 v32, 0xb64, v32
	v_mul_lo_u32 v37, v33, s1
	v_sub_u32_e32 v38, v36, v32
	v_add_u32_e32 v32, v37, v38
	v_mov_b32_e32 v33, 0
	v_lshl_add_u64 v[34:35], v[32:33], 1, s[8:9]
	flat_store_short v[34:35], v28 sc0 sc1
	s_waitcnt vmcnt(0)
	v_or_b32_e32 v28, 1, v36
	v_cvt_f16_f32_e32 v34, v29
	v_mul_hi_u32 v29, v28, s0
	v_lshrrev_b32_e32 v29, 10, v29
	v_mul_u32_u24_e32 v29, 0xb64, v29
	v_sub_u32_e32 v35, v28, v29
	v_add_u32_e32 v32, v37, v35
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	flat_store_short v[28:29], v34 sc0 sc1
	s_waitcnt vmcnt(0)
	v_or_b32_e32 v28, 2, v36
	v_mul_hi_u32 v29, v28, s0
	v_lshrrev_b32_e32 v29, 10, v29
	v_cvt_f16_f32_e32 v30, v30
	v_mul_u32_u24_e32 v29, 0xb64, v29
	v_sub_u32_e32 v34, v28, v29
	v_add_u32_e32 v32, v37, v34
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	flat_store_short v[28:29], v30 sc0 sc1
	s_waitcnt vmcnt(0)
	v_or_b32_e32 v28, 3, v36
	v_mul_hi_u32 v29, v28, s0
	v_lshrrev_b32_e32 v29, 10, v29
	v_cvt_f16_f32_e32 v30, v31
	v_mul_u32_u24_e32 v29, 0xb64, v29
	v_sub_u32_e32 v31, v28, v29
	v_add_u32_e32 v32, v37, v31
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v24, v24
	flat_store_short v[28:29], v30 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v30, 0xb640, v37
	v_cvt_f16_f32_e32 v36, v25
	v_add_u32_e32 v32, v30, v38
	v_cvt_f16_f32_e32 v26, v26
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v30, v35
	v_cvt_f16_f32_e32 v27, v27
	flat_store_short v[28:29], v24 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v30, v34
	flat_store_short v[24:25], v36 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v30, v31
	flat_store_short v[24:25], v26 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v20
	flat_store_short v[24:25], v27 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v26, 0x16c80, v37
	v_cvt_f16_f32_e32 v27, v21
	v_add_u32_e32 v32, v26, v38
	v_cvt_f16_f32_e32 v22, v22
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v26, v35
	v_cvt_f16_f32_e32 v23, v23
	flat_store_short v[24:25], v20 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v26, v34
	flat_store_short v[20:21], v27 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v26, v31
	flat_store_short v[20:21], v22 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v16, v16
	flat_store_short v[20:21], v23 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v22, 0x222c0, v37
	v_cvt_f16_f32_e32 v23, v17
	v_add_u32_e32 v32, v22, v38
	v_cvt_f16_f32_e32 v18, v18
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v22, v35
	v_cvt_f16_f32_e32 v19, v19
	flat_store_short v[20:21], v16 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v22, v34
	flat_store_short v[16:17], v23 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v22, v31
	flat_store_short v[16:17], v18 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v12, v12
	flat_store_short v[16:17], v19 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v18, 0x2d900, v37
	v_cvt_f16_f32_e32 v19, v13
	v_add_u32_e32 v32, v18, v38
	v_cvt_f16_f32_e32 v14, v14
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v18, v35
	v_cvt_f16_f32_e32 v15, v15
	flat_store_short v[16:17], v12 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v18, v34
	flat_store_short v[12:13], v19 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v18, v31
	flat_store_short v[12:13], v14 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v8, v8
	flat_store_short v[12:13], v15 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v14, 0x38f40, v37
	v_cvt_f16_f32_e32 v15, v9
	v_add_u32_e32 v32, v14, v38
	v_cvt_f16_f32_e32 v10, v10
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v14, v35
	v_cvt_f16_f32_e32 v11, v11
	flat_store_short v[12:13], v8 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v14, v34
	flat_store_short v[8:9], v15 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v14, v31
	flat_store_short v[8:9], v10 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v4
	flat_store_short v[8:9], v11 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v10, 0x44580, v37
	v_cvt_f16_f32_e32 v11, v5
	v_add_u32_e32 v32, v10, v38
	v_cvt_f16_f32_e32 v6, v6
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v10, v35
	v_cvt_f16_f32_e32 v7, v7
	flat_store_short v[8:9], v4 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v10, v34
	flat_store_short v[4:5], v11 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v10, v31
	flat_store_short v[4:5], v6 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v0, v0
	flat_store_short v[4:5], v7 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v6, 0x4fbc0, v37
	v_cvt_f16_f32_e32 v7, v1
	v_add_u32_e32 v32, v6, v38
	v_cvt_f16_f32_e32 v2, v2
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v6, v35
	v_cvt_f16_f32_e32 v3, v3
	flat_store_short v[4:5], v0 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v6, v34
	flat_store_short v[0:1], v7 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v6, v31
	flat_store_short v[0:1], v2 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[32:33], 1, s[8:9]
	flat_store_short v[0:1], v3 sc0 sc1
	s_waitcnt vmcnt(0)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel convolution_f16_full
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 70
		.amdhsa_next_free_sgpr 17
		.amdhsa_accum_offset 72
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
	.size	convolution_f16_full, .Lfunc_end0-convolution_f16_full
                                        ; -- End function
	.set convolution_f16_full.num_vgpr, 70
	.set convolution_f16_full.num_agpr, 0
	.set convolution_f16_full.numbered_sgpr, 17
	.set convolution_f16_full.num_named_barrier, 0
	.set convolution_f16_full.private_seg_size, 0
	.set convolution_f16_full.uses_vcc, 1
	.set convolution_f16_full.uses_flat_scratch, 0
	.set convolution_f16_full.has_dyn_sized_stack, 0
	.set convolution_f16_full.has_recursion, 0
	.set convolution_f16_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2868
; TotalNumSgprs: 23
; NumVgprs: 70
; NumAgprs: 0
; TotalNumVgprs: 70
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16384 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 8
; NumSGPRsForWavesPerEU: 23
; NumVGPRsForWavesPerEU: 70
; AccumOffset: 72
; Occupancy: 7
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 17
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	convolution_f8_full     ; -- Begin function convolution_f8_full
	.globl	convolution_f8_full
	.p2align	8
	.type	convolution_f8_full,@function
convolution_f8_full:                    ; @convolution_f8_full
; %bb.0:                                ; %entry
	v_and_b32_e32 v32, 15, v0
	v_cmp_lt_u32_e32 vcc, 8, v32
	v_add_u16_e32 v2, -9, v32
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	v_cndmask_b32_e64 v1, 0, 1, vcc
	v_cmp_gt_u32_e32 vcc, 9, v32
	s_movk_i32 s0, 0xab
	s_lshl_b32 s2, s2, 7
	v_cndmask_b32_e32 v2, v2, v32, vcc
	v_mul_lo_u16_sdwa v3, v2, s0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_lshrrev_b16_e32 v3, 9, v3
	v_mul_lo_u16_e32 v4, 3, v3
	v_sub_u16_e32 v2, v2, v4
	v_lshrrev_b32_e32 v4, 4, v0
	v_or_b32_e32 v5, s2, v4
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v6, v5, s0
	v_lshrrev_b32_e32 v6, 10, v6
	v_mul_u32_u24_e32 v7, 0xb64, v6
	v_sub_u32_e32 v5, v5, v7
	v_lshrrev_b16_e32 v7, 1, v5
	v_mul_u32_u24_e32 v7, 0x97b5, v7
	v_lshrrev_b32_e32 v33, 20, v7
	v_mul_lo_u16_e32 v8, 54, v33
	v_lshlrev_b32_e32 v35, 6, v6
	v_add_u32_e32 v7, v33, v3
	v_sub_u16_e32 v34, v5, v8
	v_or_b32_e32 v5, v35, v1
	s_movk_i32 s11, 0xc40
	v_mul_lo_u32 v5, v5, s11
	v_mul_u32_u24_e32 v6, 56, v7
	v_add_u32_sdwa v7, v34, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v5, v7, v5, v6
	v_or_b32_e32 v7, 0x200, v0
	v_lshrrev_b32_e32 v7, 4, v7
	v_or_b32_e32 v8, s2, v7
	v_mul_hi_u32 v9, v8, s0
	v_lshrrev_b32_e32 v9, 10, v9
	v_mul_u32_u24_e32 v10, 0xb64, v9
	v_sub_u32_e32 v8, v8, v10
	v_lshrrev_b16_e32 v10, 1, v8
	v_mul_u32_u24_e32 v10, 0x97b5, v10
	v_lshrrev_b32_e32 v36, 20, v10
	v_mul_lo_u16_e32 v11, 54, v36
	v_lshlrev_b32_e32 v38, 6, v9
	v_add_u32_e32 v10, v36, v3
	v_sub_u16_e32 v37, v8, v11
	v_or_b32_e32 v8, v38, v1
	v_mul_lo_u32 v8, v8, s11
	v_mul_u32_u24_e32 v9, 56, v10
	v_add_u32_sdwa v10, v37, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v8, v10, v8, v9
	v_or_b32_e32 v10, 64, v4
	v_or_b32_e32 v11, s2, v10
	v_mul_hi_u32 v12, v11, s0
	v_lshrrev_b32_e32 v12, 10, v12
	v_mul_u32_u24_e32 v13, 0xb64, v12
	v_sub_u32_e32 v11, v11, v13
	v_lshrrev_b16_e32 v13, 1, v11
	v_mul_u32_u24_e32 v13, 0x97b5, v13
	v_lshrrev_b32_e32 v39, 20, v13
	v_mul_lo_u16_e32 v14, 54, v39
	v_lshlrev_b32_e32 v41, 6, v12
	v_add_u32_e32 v13, v39, v3
	v_sub_u16_e32 v40, v11, v14
	v_or_b32_e32 v11, v41, v1
	v_mul_lo_u32 v11, v11, s11
	v_mul_u32_u24_e32 v12, 56, v13
	v_add_u32_sdwa v13, v40, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_add3_u32 v11, v13, v11, v12
	v_or_b32_e32 v12, 0x600, v0
	v_lshrrev_b32_e32 v12, 4, v12
	v_or_b32_e32 v13, s2, v12
	v_mul_hi_u32 v14, v13, s0
	v_lshrrev_b32_e32 v14, 10, v14
	v_mul_u32_u24_e32 v15, 0xb64, v14
	v_sub_u32_e32 v13, v13, v15
	v_lshrrev_b16_e32 v15, 1, v13
	s_lshl_b32 s10, s3, 7
	v_mul_u32_u24_e32 v15, 0x97b5, v15
	v_or_b32_e32 v6, s10, v4
	s_movk_i32 s1, 0x240
	v_lshrrev_b32_e32 v42, 20, v15
	v_mul_lo_u32 v6, v6, s1
	v_mul_lo_u16_e32 v15, 54, v42
	v_lshlrev_b32_e32 v44, 6, v14
	v_or_b32_e32 v6, v6, v32
	v_or_b32_e32 v9, s10, v7
	v_add_u32_e32 v3, v42, v3
	v_sub_u16_e32 v43, v13, v15
	v_or_b32_e32 v1, v44, v1
	s_waitcnt lgkmcnt(0)
	global_load_ubyte v5, v5, s[4:5]
	v_mul_lo_u32 v9, v9, s1
	global_load_ubyte v6, v6, s[6:7]
	v_mul_lo_u32 v1, v1, s11
	v_mul_u32_u24_e32 v3, 56, v3
	v_add_u32_sdwa v2, v43, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	global_load_ubyte v8, v8, s[4:5]
	v_or_b32_e32 v9, v9, v32
	v_or_b32_e32 v10, s10, v10
	v_add3_u32 v1, v2, v1, v3
	v_or_b32_e32 v2, s10, v12
	global_load_ubyte v9, v9, s[6:7]
	v_mul_lo_u32 v10, v10, s1
	v_mul_lo_u32 v2, v2, s1
	global_load_ubyte v11, v11, s[4:5]
	v_or_b32_e32 v10, v10, v32
	global_load_ubyte v1, v1, s[4:5]
	v_or_b32_e32 v2, v2, v32
	global_load_ubyte v10, v10, s[6:7]
	v_lshlrev_b32_e32 v46, 1, v0
	global_load_ubyte v2, v2, s[6:7]
	v_lshrrev_b32_e32 v45, 6, v0
	s_movk_i32 s0, 0x2000
	v_or_b32_e32 v47, 0x2000, v46
	v_mov_b32_e32 v54, 0
	s_mov_b32 s12, 0xe38f
	s_mov_b32 s13, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v56, 0
	s_waitcnt vmcnt(7)
	v_cvt_f32_fp8_e32 v3, v5
	s_waitcnt vmcnt(6)
	v_cvt_f32_fp8_e32 v5, v6
	v_cvt_f16_f32_e32 v3, v3
	s_waitcnt vmcnt(5)
	v_cvt_f32_fp8_e32 v6, v8
	v_cvt_f16_f32_e32 v5, v5
	ds_write_b16 v46, v3
	v_cvt_f16_f32_e32 v6, v6
	s_waitcnt vmcnt(4)
	v_cvt_f32_fp8_e32 v8, v9
	s_waitcnt vmcnt(3)
	v_cvt_f32_fp8_e32 v9, v11
	v_cvt_f16_f32_e32 v8, v8
	s_waitcnt vmcnt(2)
	v_cvt_f32_fp8_e32 v1, v1
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v10, v10
	v_cvt_f16_f32_e32 v9, v9
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_cvt_f16_f32_e32 v1, v1
	v_cvt_f16_f32_e32 v10, v10
	v_cvt_f16_f32_e32 v2, v2
	ds_write_b16 v46, v5 offset:8192
	ds_write_b16 v46, v6 offset:1024
	ds_write_b16 v46, v8 offset:9216
	ds_write_b16 v46, v9 offset:2048
	ds_write_b16 v46, v10 offset:10240
	ds_write_b16 v46, v1 offset:3072
	ds_write_b16 v46, v2 offset:11264
	v_lshrrev_b32_e32 v1, 2, v0
	v_and_b32_e32 v48, 12, v1
	v_lshlrev_b32_e32 v0, 5, v0
	v_and_b32_e32 v0, 0x1e0, v0
	v_lshlrev_b32_e32 v2, 1, v48
	v_lshlrev_b32_e32 v1, 9, v45
	v_or3_b32 v50, v0, v2, s0
	s_mul_i32 s0, s3, 0x12000
	v_or3_b32 v49, v1, v0, v2
	v_mov_b32_e32 v0, s0
	v_mad_u32_u24 v1, v12, s1, v0
	v_or3_b32 v51, v1, v32, 16
	v_mad_u32_u24 v1, v4, s1, v0
	v_mad_u32_u24 v0, v7, s1, v0
	v_or3_b32 v53, v0, v32, 16
	v_mov_b32_e32 v0, 0
	v_or_b32_e32 v52, v1, v32
	s_mov_b32 s3, 0
	v_mov_b32_e32 v1, v0
	v_mov_b32_e32 v2, v0
	v_mov_b32_e32 v3, v0
	v_mov_b32_e32 v4, v0
	v_mov_b32_e32 v5, v0
	v_mov_b32_e32 v6, v0
	v_mov_b32_e32 v7, v0
	v_mov_b32_e32 v8, v0
	v_mov_b32_e32 v9, v0
	v_mov_b32_e32 v10, v0
	v_mov_b32_e32 v11, v0
	v_mov_b32_e32 v12, v0
	v_mov_b32_e32 v13, v0
	v_mov_b32_e32 v14, v0
	v_mov_b32_e32 v15, v0
	v_mov_b32_e32 v16, v0
	v_mov_b32_e32 v17, v0
	v_mov_b32_e32 v18, v0
	v_mov_b32_e32 v19, v0
	v_mov_b32_e32 v20, v0
	v_mov_b32_e32 v21, v0
	v_mov_b32_e32 v22, v0
	v_mov_b32_e32 v23, v0
	v_mov_b32_e32 v24, v0
	v_mov_b32_e32 v25, v0
	v_mov_b32_e32 v26, v0
	v_mov_b32_e32 v27, v0
	v_mov_b32_e32 v28, v0
	v_mov_b32_e32 v29, v0
	v_mov_b32_e32 v30, v0
	v_mov_b32_e32 v31, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .LBB1_2
.LBB1_1:                                ; %if.end54.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_add_i32 s13, s13, 16
	s_addk_i32 s3, 0x800
	s_cmpk_lg_i32 s13, 0x240
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc0 .LBB1_6
.LBB1_2:                                ; %for.body.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lg_i32 s13, 0x230
	s_cselect_b64 s[0:1], -1, 0
	s_cmpk_eq_i32 s13, 0x230
	s_cbranch_scc1 .LBB1_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	v_add3_u32 v54, v32, s13, 16
	v_mul_u32_u24_sdwa v55, v54, s12 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshrrev_b32_e32 v55, 19, v55
	v_mul_lo_u16_e32 v56, 9, v55
	v_sub_u16_e32 v54, v54, v56
	v_mul_lo_u16_e32 v56, 0xab, v54
	v_lshrrev_b16_e32 v56, 9, v56
	v_mul_lo_u16_e32 v57, 3, v56
	v_sub_u16_e32 v54, v54, v57
	v_add_u32_e32 v60, v56, v36
	v_add_u32_e32 v61, v38, v55
	v_add_u32_e32 v57, v56, v33
	v_add_u32_e32 v58, v35, v55
	v_mul_lo_u32 v61, v61, s11
	v_mul_u32_u24_e32 v60, 56, v60
	v_add_u32_sdwa v62, v54, v37 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_mul_lo_u32 v58, v58, s11
	v_mul_u32_u24_e32 v57, 56, v57
	v_add_u32_sdwa v59, v54, v34 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add3_u32 v60, v62, v61, v60
	v_add_u32_e32 v62, v56, v39
	v_add_u32_e32 v63, v41, v55
	v_add_u32_e32 v56, v56, v42
	v_add_u32_e32 v55, v44, v55
	v_add3_u32 v57, v59, v58, v57
	v_add_u32_e32 v58, s13, v52
	v_mul_lo_u32 v63, v63, s11
	v_mul_u32_u24_e32 v62, 56, v62
	v_add_u32_sdwa v64, v54, v40 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_mul_lo_u32 v55, v55, s11
	v_mul_u32_u24_e32 v56, 56, v56
	v_add_u32_sdwa v54, v54, v43 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
	v_add_u32_e32 v59, 16, v58
	v_add_u32_e32 v61, s13, v53
	v_add3_u32 v62, v64, v63, v62
	v_add_u32_e32 v58, 0x9010, v58
	v_add_u32_e32 v63, s13, v51
	v_add3_u32 v54, v54, v55, v56
	global_load_ubyte v57, v57, s[4:5]
	s_nop 0
	global_load_ubyte v54, v54, s[4:5]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v57, v57
	global_load_ubyte v59, v59, s[6:7]
	s_nop 0
	global_load_ubyte v58, v58, s[6:7]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v59, v59
	global_load_ubyte v60, v60, s[4:5]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v58, v58
	global_load_ubyte v61, v61, s[6:7]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v60, v60
	global_load_ubyte v62, v62, s[4:5]
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v55, v61
	global_load_ubyte v63, v63, s[6:7]
	v_cvt_pk_f16_f32 v55, v59, v55
	s_waitcnt vmcnt(1)
	v_cvt_f32_fp8_e32 v61, v62
	v_cvt_f32_fp8_e32 v62, v54
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v56, v63
	v_cvt_pk_f16_f32 v54, v57, v60
	v_cvt_pk_f16_f32 v57, v61, v62
	v_cvt_pk_f16_f32 v56, v58, v56
.LBB1_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_and_b32 s14, s3, 0x800
	s_lshl_b32 s15, s14, 1
	v_or_b32_e32 v58, s15, v49
	ds_read_b64 v[66:67], v58
	v_add_u32_e32 v68, s15, v50
	ds_read2st64_b64 v[58:61], v68 offset1:1
	ds_read2st64_b64 v[62:65], v68 offset0:2 offset1:3
	s_andn2_b64 vcc, exec, s[0:1]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 v[28:31], v[66:67], v[58:59], v[28:31]
	v_mfma_f32_16x16x16_f16 v[24:27], v[66:67], v[60:61], v[24:27]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 v[20:23], v[66:67], v[62:63], v[20:23]
	v_mfma_f32_16x16x16_f16 v[16:19], v[66:67], v[64:65], v[16:19]
	ds_read2st64_b64 v[58:61], v68 offset0:4 offset1:5
	ds_read2st64_b64 v[62:65], v68 offset0:6 offset1:7
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x16_f16 v[12:15], v[66:67], v[58:59], v[12:15]
	v_mfma_f32_16x16x16_f16 v[8:11], v[66:67], v[60:61], v[8:11]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 v[4:7], v[66:67], v[62:63], v[4:7]
	v_mfma_f32_16x16x16_f16 v[0:3], v[66:67], v[64:65], v[0:3]
	s_cbranch_vccnz .LBB1_1
; %bb.5:                                ; %if.then50.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_xor_b32 s0, s14, 0x800
	s_lshl_b32 s0, s0, 1
	v_add_u32_e32 v58, s0, v46
	v_add_u32_e32 v59, s0, v47
	ds_write_b16 v58, v54
	ds_write_b16 v59, v55
	ds_write_b16_d16_hi v58, v54 offset:1024
	ds_write_b16_d16_hi v59, v55 offset:1024
	ds_write_b16 v58, v57 offset:2048
	ds_write_b16 v59, v56 offset:2048
	ds_write_b16_d16_hi v58, v57 offset:3072
	ds_write_b16_d16_hi v59, v56 offset:3072
	s_branch .LBB1_1
.LBB1_6:                                ; %_Z16convolution_fullILb1EEvPKvS1_PVDF16_PDF16_S4_.exit
	v_lshl_add_u32 v33, v45, 4, s2
	v_or_b32_e32 v36, v33, v48
	s_mov_b32 s0, 0x59e60383
	v_mul_hi_u32 v33, v36, s0
	v_lshrrev_b32_e32 v33, 10, v33
	v_or_b32_e32 v32, s10, v32
	v_lshl_add_u32 v32, v33, 7, v32
	s_movk_i32 s1, 0xb64
	v_mul_lo_u32 v37, v32, s1
	v_cvt_f16_f32_e32 v28, v28
	v_mul_u32_u24_e32 v32, 0xb64, v33
	v_sub_u32_e32 v38, v36, v32
	v_add_u32_e32 v32, v37, v38
	v_mov_b32_e32 v33, 0
	v_lshl_add_u64 v[34:35], v[32:33], 1, s[8:9]
	flat_store_short v[34:35], v28 sc0 sc1
	s_waitcnt vmcnt(0)
	v_or_b32_e32 v28, 1, v36
	v_cvt_f16_f32_e32 v34, v29
	v_mul_hi_u32 v29, v28, s0
	v_lshrrev_b32_e32 v29, 10, v29
	v_mul_u32_u24_e32 v29, 0xb64, v29
	v_sub_u32_e32 v35, v28, v29
	v_add_u32_e32 v32, v37, v35
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	flat_store_short v[28:29], v34 sc0 sc1
	s_waitcnt vmcnt(0)
	v_or_b32_e32 v28, 2, v36
	v_mul_hi_u32 v29, v28, s0
	v_lshrrev_b32_e32 v29, 10, v29
	v_cvt_f16_f32_e32 v30, v30
	v_mul_u32_u24_e32 v29, 0xb64, v29
	v_sub_u32_e32 v34, v28, v29
	v_add_u32_e32 v32, v37, v34
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	flat_store_short v[28:29], v30 sc0 sc1
	s_waitcnt vmcnt(0)
	v_or_b32_e32 v28, 3, v36
	v_mul_hi_u32 v29, v28, s0
	v_lshrrev_b32_e32 v29, 10, v29
	v_cvt_f16_f32_e32 v30, v31
	v_mul_u32_u24_e32 v29, 0xb64, v29
	v_sub_u32_e32 v31, v28, v29
	v_add_u32_e32 v32, v37, v31
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v24, v24
	flat_store_short v[28:29], v30 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v30, 0xb640, v37
	v_cvt_f16_f32_e32 v36, v25
	v_add_u32_e32 v32, v30, v38
	v_cvt_f16_f32_e32 v26, v26
	v_lshl_add_u64 v[28:29], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v30, v35
	v_cvt_f16_f32_e32 v27, v27
	flat_store_short v[28:29], v24 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v30, v34
	flat_store_short v[24:25], v36 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v30, v31
	flat_store_short v[24:25], v26 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v20
	flat_store_short v[24:25], v27 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v26, 0x16c80, v37
	v_cvt_f16_f32_e32 v27, v21
	v_add_u32_e32 v32, v26, v38
	v_cvt_f16_f32_e32 v22, v22
	v_lshl_add_u64 v[24:25], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v26, v35
	v_cvt_f16_f32_e32 v23, v23
	flat_store_short v[24:25], v20 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v26, v34
	flat_store_short v[20:21], v27 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v26, v31
	flat_store_short v[20:21], v22 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v16, v16
	flat_store_short v[20:21], v23 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v22, 0x222c0, v37
	v_cvt_f16_f32_e32 v23, v17
	v_add_u32_e32 v32, v22, v38
	v_cvt_f16_f32_e32 v18, v18
	v_lshl_add_u64 v[20:21], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v22, v35
	v_cvt_f16_f32_e32 v19, v19
	flat_store_short v[20:21], v16 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v22, v34
	flat_store_short v[16:17], v23 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v22, v31
	flat_store_short v[16:17], v18 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v12, v12
	flat_store_short v[16:17], v19 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v18, 0x2d900, v37
	v_cvt_f16_f32_e32 v19, v13
	v_add_u32_e32 v32, v18, v38
	v_cvt_f16_f32_e32 v14, v14
	v_lshl_add_u64 v[16:17], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v18, v35
	v_cvt_f16_f32_e32 v15, v15
	flat_store_short v[16:17], v12 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v18, v34
	flat_store_short v[12:13], v19 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v18, v31
	flat_store_short v[12:13], v14 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v8, v8
	flat_store_short v[12:13], v15 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v14, 0x38f40, v37
	v_cvt_f16_f32_e32 v15, v9
	v_add_u32_e32 v32, v14, v38
	v_cvt_f16_f32_e32 v10, v10
	v_lshl_add_u64 v[12:13], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v14, v35
	v_cvt_f16_f32_e32 v11, v11
	flat_store_short v[12:13], v8 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v14, v34
	flat_store_short v[8:9], v15 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v14, v31
	flat_store_short v[8:9], v10 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v4
	flat_store_short v[8:9], v11 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v10, 0x44580, v37
	v_cvt_f16_f32_e32 v11, v5
	v_add_u32_e32 v32, v10, v38
	v_cvt_f16_f32_e32 v6, v6
	v_lshl_add_u64 v[8:9], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v10, v35
	v_cvt_f16_f32_e32 v7, v7
	flat_store_short v[8:9], v4 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v10, v34
	flat_store_short v[4:5], v11 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v10, v31
	flat_store_short v[4:5], v6 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_cvt_f16_f32_e32 v0, v0
	flat_store_short v[4:5], v7 sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v6, 0x4fbc0, v37
	v_cvt_f16_f32_e32 v7, v1
	v_add_u32_e32 v32, v6, v38
	v_cvt_f16_f32_e32 v2, v2
	v_lshl_add_u64 v[4:5], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v6, v35
	v_cvt_f16_f32_e32 v3, v3
	flat_store_short v[4:5], v0 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v6, v34
	flat_store_short v[0:1], v7 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[32:33], 1, s[8:9]
	v_add_u32_e32 v32, v6, v31
	flat_store_short v[0:1], v2 sc0 sc1
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[32:33], 1, s[8:9]
	flat_store_short v[0:1], v3 sc0 sc1
	s_waitcnt vmcnt(0)
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel convolution_f8_full
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 69
		.amdhsa_next_free_sgpr 16
		.amdhsa_accum_offset 72
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
	.size	convolution_f8_full, .Lfunc_end1-convolution_f8_full
                                        ; -- End function
	.set convolution_f8_full.num_vgpr, 69
	.set convolution_f8_full.num_agpr, 0
	.set convolution_f8_full.numbered_sgpr, 16
	.set convolution_f8_full.num_named_barrier, 0
	.set convolution_f8_full.private_seg_size, 0
	.set convolution_f8_full.uses_vcc, 1
	.set convolution_f8_full.uses_flat_scratch, 0
	.set convolution_f8_full.has_dyn_sized_stack, 0
	.set convolution_f8_full.has_recursion, 0
	.set convolution_f8_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2844
; TotalNumSgprs: 22
; NumVgprs: 69
; NumAgprs: 0
; TotalNumVgprs: 69
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16384 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 8
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 69
; AccumOffset: 72
; Occupancy: 7
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 17
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_25fb71cfa643285b,@object ; @__hip_cuid_25fb71cfa643285b
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_25fb71cfa643285b
__hip_cuid_25fb71cfa643285b:
	.byte	0                               ; 0x0
	.size	__hip_cuid_25fb71cfa643285b, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_25fb71cfa643285b
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
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
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           convolution_f16_full
    .private_segment_fixed_size: 0
    .sgpr_count:     23
    .sgpr_spill_count: 0
    .symbol:         convolution_f16_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     70
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
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
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           convolution_f8_full
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         convolution_f8_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     69
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
