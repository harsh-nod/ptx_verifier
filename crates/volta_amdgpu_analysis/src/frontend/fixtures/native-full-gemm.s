	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	gemm_f16_full           ; -- Begin function gemm_f16_full
	.globl	gemm_f16_full
	.p2align	8
	.type	gemm_f16_full,@function
gemm_f16_full:                          ; @gemm_f16_full
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_lshl_b32 s10, s2, 8
	v_lshrrev_b32_e32 v1, 2, v0
	v_lshlrev_b32_e32 v2, 3, v0
	v_and_b32_e32 v40, 0xf8, v2
	v_or_b32_e32 v2, s10, v1
	v_lshlrev_b32_e32 v2, 12, v2
	v_mov_b32_e32 v3, 0
	v_lshlrev_b64 v[38:39], 1, v[2:3]
	v_lshlrev_b32_e32 v78, 4, v0
	v_lshrrev_b32_e32 v29, 5, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[38:39]
	v_and_b32_e32 v2, 48, v78
	s_lshl_b32 s2, s3, 8
	s_mov_b32 s3, 0
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[2:3]
	v_lshlrev_b32_e32 v2, 13, v29
	global_load_dwordx4 v[30:33], v[4:5], off
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[2:3]
	s_lshl_b64 s[12:13], s[2:3], 1
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[12:13]
	v_lshlrev_b32_e32 v6, 1, v40
	v_mov_b32_e32 v7, v3
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[6:7]
	global_load_dwordx4 v[34:37], v[4:5], off
	s_load_dwordx2 s[0:1], s[0:1], 0x10
	v_and_b32_e32 v43, 3, v0
	v_and_b32_e32 v44, 31, v0
	v_lshl_or_b32 v38, v43, 4, v38
	s_add_u32 s6, s6, s12
	v_lshrrev_b32_e32 v79, 6, v0
	v_lshlrev_b32_e32 v41, 6, v0
	v_lshlrev_b32_e32 v40, 6, v40
	v_lshl_add_u64 v[38:39], s[4:5], 0, v[38:39]
	s_addc_u32 s7, s7, s13
	v_lshl_or_b32 v2, v44, 4, v2
	s_mov_b32 s14, 0x8000
	s_mov_b64 s[8:9], 0x40000
	v_and_b32_e32 v42, 48, v0
	v_lshlrev_b32_e32 v45, 10, v79
	v_and_b32_e32 v41, 0x3c0, v41
	v_lshl_or_b32 v29, v29, 1, v40
	v_lshl_add_u64 v[74:75], v[38:39], 0, 64
	v_lshl_add_u64 v[38:39], s[6:7], 0, v[2:3]
	s_mov_b32 s11, s3
	v_mov_b32_e32 v4, v3
	v_mov_b32_e32 v5, v3
	v_mov_b32_e32 v6, v3
	v_mov_b32_e32 v8, v3
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v11, v3
	v_mov_b32_e32 v12, v3
	v_mov_b32_e32 v13, v3
	v_mov_b32_e32 v14, v3
	v_mov_b32_e32 v15, v3
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v17, v3
	v_mov_b32_e32 v18, v3
	v_mov_b32_e32 v19, v3
	v_mov_b32_e32 v20, v3
	v_mov_b32_e32 v21, v3
	v_mov_b32_e32 v22, v3
	v_mov_b32_e32 v23, v3
	v_mov_b32_e32 v24, v3
	v_mov_b32_e32 v25, v3
	v_mov_b32_e32 v26, v3
	v_mov_b32_e32 v27, v3
	v_mov_b32_e32 v28, v3
	v_or3_b32 v80, v45, v41, v42
	v_or3_b32 v81, v41, v42, s14
	v_or_b32_e32 v82, 0x8000, v29
	v_mov_b32_e32 v2, v3
	v_lshl_add_u64 v[76:77], v[38:39], 0, s[8:9]
	v_mov_b32_e32 v38, v3
	v_mov_b32_e32 v39, v3
	v_mov_b32_e32 v40, v3
	v_mov_b32_e32 v41, v3
	v_mov_b32_e32 v42, v3
	v_mov_b32_e32 v43, v3
	v_mov_b32_e32 v44, v3
	v_mov_b32_e32 v45, v3
	v_mov_b32_e32 v46, v3
	v_mov_b32_e32 v47, v3
	v_mov_b32_e32 v48, v3
	v_mov_b32_e32 v49, v3
	v_mov_b32_e32 v50, v3
	v_mov_b32_e32 v51, v3
	v_mov_b32_e32 v52, v3
	s_waitcnt vmcnt(1)
	ds_write_b128 v78, v[30:33]
	s_waitcnt vmcnt(0)
	ds_write_b16 v29, v34 offset:32768
	ds_write_b16_d16_hi v29, v34 offset:32832
	ds_write_b16 v29, v35 offset:32896
	ds_write_b16_d16_hi v29, v35 offset:32960
	ds_write_b16 v29, v36 offset:33024
	ds_write_b16_d16_hi v29, v36 offset:33088
	ds_write_b16 v29, v37 offset:33152
	ds_write_b16_d16_hi v29, v37 offset:33216
	v_mov_b32_e32 v29, v3
	v_mov_b32_e32 v30, v3
	v_mov_b32_e32 v31, v3
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v33, v3
	v_mov_b32_e32 v34, v3
	v_mov_b32_e32 v35, v3
	v_mov_b32_e32 v36, v3
	v_mov_b32_e32 v37, v3
	v_mov_b32_e32 v53, v3
	v_mov_b32_e32 v54, v3
	v_mov_b32_e32 v55, v3
	v_mov_b32_e32 v56, v3
	v_mov_b32_e32 v57, v3
	v_mov_b32_e32 v58, v3
	v_mov_b32_e32 v59, v3
	v_mov_b32_e32 v60, v3
	v_mov_b32_e32 v61, v3
	v_mov_b32_e32 v62, v3
	v_mov_b32_e32 v63, v3
	v_mov_b32_e32 v64, v3
	v_mov_b32_e32 v65, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
                                        ; implicit-def: $vgpr66_vgpr67_vgpr68_vgpr69
                                        ; implicit-def: $vgpr70_vgpr71_vgpr72_vgpr73
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end108.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s11, s11, 32
	v_lshl_add_u64 v[74:75], v[74:75], 0, 64
	v_lshl_add_u64 v[76:77], v[76:77], 0, s[8:9]
	s_andn2_b64 vcc, exec, s[4:5]
	s_add_i32 s3, s3, 1
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccz .LBB0_6
.LBB0_2:                                ; %for.body30.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lt_u32 s11, 0xfe0
	s_cselect_b64 s[6:7], -1, 0
	s_cmpk_gt_u32 s11, 0xfdf
	s_cselect_b64 s[4:5], -1, 0
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	global_load_dwordx4 v[66:69], v[74:75], off
	global_load_dwordx4 v[70:73], v[76:77], off
.LBB0_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_and_b32 s12, s3, 1
	s_lshl_b32 s13, s12, 14
	v_or_b32_e32 v83, s13, v80
	ds_read_b128 v[84:87], v83
	v_add_u32_e32 v83, s13, v81
	ds_read_b128 v[88:91], v83
	s_andn2_b64 vcc, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[62:65], v[84:87], v[88:91], v[62:65]
	ds_read_b128 v[88:91], v83 offset:1024
	ds_read_b128 v[92:95], v83 offset:2048
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[58:61], v[84:87], v[88:91], v[58:61]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[54:57], v[84:87], v[92:95], v[54:57]
	ds_read_b128 v[88:91], v83 offset:3072
	ds_read_b128 v[92:95], v83 offset:4096
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[50:53], v[84:87], v[88:91], v[50:53]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[46:49], v[84:87], v[92:95], v[46:49]
	ds_read_b128 v[88:91], v83 offset:5120
	ds_read_b128 v[92:95], v83 offset:6144
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[42:45], v[84:87], v[88:91], v[42:45]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[38:41], v[84:87], v[92:95], v[38:41]
	ds_read_b128 v[88:91], v83 offset:7168
	ds_read_b128 v[92:95], v83 offset:8192
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[34:37], v[84:87], v[88:91], v[34:37]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[30:33], v[84:87], v[92:95], v[30:33]
	ds_read_b128 v[88:91], v83 offset:9216
	ds_read_b128 v[92:95], v83 offset:10240
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[26:29], v[84:87], v[88:91], v[26:29]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[22:25], v[84:87], v[92:95], v[22:25]
	ds_read_b128 v[88:91], v83 offset:11264
	ds_read_b128 v[92:95], v83 offset:12288
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[18:21], v[84:87], v[88:91], v[18:21]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[14:17], v[84:87], v[92:95], v[14:17]
	ds_read_b128 v[88:91], v83 offset:13312
	ds_read_b128 v[92:95], v83 offset:14336
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[10:13], v[84:87], v[88:91], v[10:13]
	ds_read_b128 v[88:91], v83 offset:15360
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[6:9], v[84:87], v[92:95], v[6:9]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[2:5], v[84:87], v[88:91], v[2:5]
	s_cbranch_vccnz .LBB0_1
; %bb.5:                                ; %if.then86.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_xor_b32 s6, s12, 1
	s_lshl_b32 s6, s6, 14
	v_or_b32_e32 v83, s6, v78
	s_waitcnt vmcnt(1)
	ds_write_b128 v83, v[66:69]
	v_add_u32_e32 v83, s6, v82
	s_waitcnt vmcnt(0)
	ds_write_b16 v83, v70
	ds_write_b16_d16_hi v83, v70 offset:64
	ds_write_b16 v83, v71 offset:128
	ds_write_b16_d16_hi v83, v71 offset:192
	ds_write_b16 v83, v72 offset:256
	ds_write_b16_d16_hi v83, v72 offset:320
	ds_write_b16 v83, v73 offset:384
	ds_write_b16_d16_hi v83, v73 offset:448
	s_branch .LBB0_1
.LBB0_6:                                ; %_Z8full_f16ILb0EEvPKDF16_S1_S1_PDF16_.exit
	s_waitcnt vmcnt(1)
	v_lshlrev_b32_e32 v66, 4, v79
	v_and_b32_e32 v1, 12, v1
	v_or3_b32 v1, v66, v1, s10
	v_cvt_f16_f32_e32 v67, v62
	v_and_or_b32 v66, v0, 15, s2
	v_lshlrev_b32_e32 v62, 12, v1
	v_add_u32_e32 v0, v62, v66
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[0:1]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v63
	v_or_b32_e32 v63, 0x1000, v62
	v_add_u32_e32 v0, v63, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[0:1]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v64
	v_or_b32_e32 v64, 0x2000, v62
	v_add_u32_e32 v0, v64, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[0:1]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v65
	v_or_b32_e32 v65, 0x3000, v62
	v_add_u32_e32 v0, v65, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v58, v58
	global_store_short v[68:69], v67, off
	v_or_b32_e32 v67, 16, v66
	s_waitcnt vmcnt(4)
	v_cvt_f16_f32_e32 v70, v59
	v_add_u32_e32 v0, v62, v67
	v_cvt_f16_f32_e32 v60, v60
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v67
	v_cvt_f16_f32_e32 v61, v61
	global_store_short v[68:69], v58, off
	v_lshl_add_u64 v[58:59], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v67
	global_store_short v[58:59], v70, off
	v_lshl_add_u64 v[58:59], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v67
	global_store_short v[58:59], v60, off
	v_lshl_add_u64 v[58:59], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v54, v54
	global_store_short v[58:59], v61, off
	v_or_b32_e32 v60, 32, v66
	v_cvt_f16_f32_e32 v61, v55
	v_add_u32_e32 v0, v62, v60
	v_cvt_f16_f32_e32 v56, v56
	v_lshl_add_u64 v[58:59], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v60
	v_cvt_f16_f32_e32 v57, v57
	global_store_short v[58:59], v54, off
	v_lshl_add_u64 v[54:55], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v60
	global_store_short v[54:55], v61, off
	v_lshl_add_u64 v[54:55], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v60
	global_store_short v[54:55], v56, off
	v_lshl_add_u64 v[54:55], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v50, v50
	global_store_short v[54:55], v57, off
	v_or_b32_e32 v56, 48, v66
	v_cvt_f16_f32_e32 v57, v51
	v_add_u32_e32 v0, v62, v56
	v_cvt_f16_f32_e32 v52, v52
	v_lshl_add_u64 v[54:55], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v56
	v_cvt_f16_f32_e32 v53, v53
	global_store_short v[54:55], v50, off
	v_lshl_add_u64 v[50:51], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v56
	global_store_short v[50:51], v57, off
	v_lshl_add_u64 v[50:51], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v56
	global_store_short v[50:51], v52, off
	v_lshl_add_u64 v[50:51], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v46, v46
	global_store_short v[50:51], v53, off
	v_or_b32_e32 v52, 64, v66
	v_cvt_f16_f32_e32 v53, v47
	v_add_u32_e32 v0, v62, v52
	v_cvt_f16_f32_e32 v48, v48
	v_lshl_add_u64 v[50:51], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v52
	v_cvt_f16_f32_e32 v49, v49
	global_store_short v[50:51], v46, off
	v_lshl_add_u64 v[46:47], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v52
	global_store_short v[46:47], v53, off
	v_lshl_add_u64 v[46:47], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v52
	global_store_short v[46:47], v48, off
	v_lshl_add_u64 v[46:47], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v42, v42
	global_store_short v[46:47], v49, off
	v_or_b32_e32 v48, 0x50, v66
	v_cvt_f16_f32_e32 v49, v43
	v_add_u32_e32 v0, v62, v48
	v_cvt_f16_f32_e32 v44, v44
	v_lshl_add_u64 v[46:47], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v48
	v_cvt_f16_f32_e32 v45, v45
	global_store_short v[46:47], v42, off
	v_lshl_add_u64 v[42:43], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v48
	global_store_short v[42:43], v49, off
	v_lshl_add_u64 v[42:43], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v48
	global_store_short v[42:43], v44, off
	v_lshl_add_u64 v[42:43], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v38, v38
	global_store_short v[42:43], v45, off
	v_or_b32_e32 v44, 0x60, v66
	v_cvt_f16_f32_e32 v45, v39
	v_add_u32_e32 v0, v62, v44
	v_cvt_f16_f32_e32 v40, v40
	v_lshl_add_u64 v[42:43], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v44
	v_cvt_f16_f32_e32 v41, v41
	global_store_short v[42:43], v38, off
	v_lshl_add_u64 v[38:39], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v44
	global_store_short v[38:39], v45, off
	v_lshl_add_u64 v[38:39], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v44
	global_store_short v[38:39], v40, off
	v_lshl_add_u64 v[38:39], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v34, v34
	global_store_short v[38:39], v41, off
	v_or_b32_e32 v40, 0x70, v66
	v_cvt_f16_f32_e32 v41, v35
	v_add_u32_e32 v0, v62, v40
	v_cvt_f16_f32_e32 v36, v36
	v_lshl_add_u64 v[38:39], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v40
	v_cvt_f16_f32_e32 v37, v37
	global_store_short v[38:39], v34, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v40
	global_store_short v[34:35], v41, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v40
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v30, v30
	global_store_short v[34:35], v37, off
	v_or_b32_e32 v36, 0x80, v66
	v_cvt_f16_f32_e32 v37, v31
	v_add_u32_e32 v0, v62, v36
	v_cvt_f16_f32_e32 v32, v32
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v36
	v_cvt_f16_f32_e32 v33, v33
	global_store_short v[34:35], v30, off
	v_lshl_add_u64 v[30:31], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v36
	global_store_short v[30:31], v37, off
	v_lshl_add_u64 v[30:31], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v36
	global_store_short v[30:31], v32, off
	v_lshl_add_u64 v[30:31], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v26, v26
	global_store_short v[30:31], v33, off
	v_or_b32_e32 v32, 0x90, v66
	v_cvt_f16_f32_e32 v33, v27
	v_add_u32_e32 v0, v62, v32
	v_cvt_f16_f32_e32 v28, v28
	v_lshl_add_u64 v[30:31], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v32
	v_cvt_f16_f32_e32 v29, v29
	global_store_short v[30:31], v26, off
	v_lshl_add_u64 v[26:27], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v32
	global_store_short v[26:27], v33, off
	v_lshl_add_u64 v[26:27], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v32
	global_store_short v[26:27], v28, off
	v_lshl_add_u64 v[26:27], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v22, v22
	global_store_short v[26:27], v29, off
	v_or_b32_e32 v28, 0xa0, v66
	v_cvt_f16_f32_e32 v29, v23
	v_add_u32_e32 v0, v62, v28
	v_cvt_f16_f32_e32 v24, v24
	v_lshl_add_u64 v[26:27], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v28
	v_cvt_f16_f32_e32 v25, v25
	global_store_short v[26:27], v22, off
	v_lshl_add_u64 v[22:23], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v28
	global_store_short v[22:23], v29, off
	v_lshl_add_u64 v[22:23], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v28
	global_store_short v[22:23], v24, off
	v_lshl_add_u64 v[22:23], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v18, v18
	global_store_short v[22:23], v25, off
	v_or_b32_e32 v24, 0xb0, v66
	v_cvt_f16_f32_e32 v25, v19
	v_add_u32_e32 v0, v62, v24
	v_cvt_f16_f32_e32 v20, v20
	v_lshl_add_u64 v[22:23], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v24
	v_cvt_f16_f32_e32 v21, v21
	global_store_short v[22:23], v18, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v24
	global_store_short v[18:19], v25, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v24
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v14, v14
	global_store_short v[18:19], v21, off
	v_or_b32_e32 v20, 0xc0, v66
	v_cvt_f16_f32_e32 v21, v15
	v_add_u32_e32 v0, v62, v20
	v_cvt_f16_f32_e32 v16, v16
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v20
	v_cvt_f16_f32_e32 v17, v17
	global_store_short v[18:19], v14, off
	v_lshl_add_u64 v[14:15], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v20
	global_store_short v[14:15], v21, off
	v_lshl_add_u64 v[14:15], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v20
	global_store_short v[14:15], v16, off
	v_lshl_add_u64 v[14:15], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v10, v10
	global_store_short v[14:15], v17, off
	v_or_b32_e32 v16, 0xd0, v66
	v_cvt_f16_f32_e32 v17, v11
	v_add_u32_e32 v0, v62, v16
	v_cvt_f16_f32_e32 v12, v12
	v_lshl_add_u64 v[14:15], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v16
	v_cvt_f16_f32_e32 v13, v13
	global_store_short v[14:15], v10, off
	v_lshl_add_u64 v[10:11], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v16
	global_store_short v[10:11], v17, off
	v_lshl_add_u64 v[10:11], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v16
	global_store_short v[10:11], v12, off
	v_lshl_add_u64 v[10:11], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v6, v6
	global_store_short v[10:11], v13, off
	v_or_b32_e32 v12, 0xe0, v66
	v_cvt_f16_f32_e32 v13, v7
	v_add_u32_e32 v0, v62, v12
	v_cvt_f16_f32_e32 v8, v8
	v_lshl_add_u64 v[10:11], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v12
	v_cvt_f16_f32_e32 v9, v9
	global_store_short v[10:11], v6, off
	v_lshl_add_u64 v[6:7], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v12
	global_store_short v[6:7], v13, off
	v_lshl_add_u64 v[6:7], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v12
	global_store_short v[6:7], v8, off
	v_lshl_add_u64 v[6:7], v[0:1], 1, s[0:1]
	v_cvt_f16_f32_e32 v2, v2
	global_store_short v[6:7], v9, off
	v_or_b32_e32 v8, 0xf0, v66
	v_cvt_f16_f32_e32 v9, v3
	v_add_u32_e32 v0, v62, v8
	v_lshl_add_u64 v[6:7], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v63, v8
	v_cvt_f16_f32_e32 v4, v4
	v_cvt_f16_f32_e32 v5, v5
	global_store_short v[6:7], v2, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v64, v8
	global_store_short v[2:3], v9, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[0:1]
	v_add_u32_e32 v0, v65, v8
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[0:1]
	global_store_short v[2:3], v4, off
	global_store_short v[0:1], v5, off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 96
		.amdhsa_next_free_sgpr 15
		.amdhsa_accum_offset 96
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
	.size	gemm_f16_full, .Lfunc_end0-gemm_f16_full
                                        ; -- End function
	.set gemm_f16_full.num_vgpr, 96
	.set gemm_f16_full.num_agpr, 0
	.set gemm_f16_full.numbered_sgpr, 15
	.set gemm_f16_full.num_named_barrier, 0
	.set gemm_f16_full.private_seg_size, 0
	.set gemm_f16_full.uses_vcc, 1
	.set gemm_f16_full.uses_flat_scratch, 0
	.set gemm_f16_full.has_dyn_sized_stack, 0
	.set gemm_f16_full.has_recursion, 0
	.set gemm_f16_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2876
; TotalNumSgprs: 21
; NumVgprs: 96
; NumAgprs: 0
; TotalNumVgprs: 96
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 11
; NumSGPRsForWavesPerEU: 21
; NumVGPRsForWavesPerEU: 96
; AccumOffset: 96
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 23
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	gemm_add_silu_f16_full  ; -- Begin function gemm_add_silu_f16_full
	.globl	gemm_add_silu_f16_full
	.p2align	8
	.type	gemm_add_silu_f16_full,@function
gemm_add_silu_f16_full:                 ; @gemm_add_silu_f16_full
; %bb.0:                                ; %entry
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_lshl_b32 s12, s2, 8
	v_lshrrev_b32_e32 v1, 2, v0
	v_lshlrev_b32_e32 v2, 3, v0
	v_and_b32_e32 v41, 0xf8, v2
	v_or_b32_e32 v2, s12, v1
	v_lshlrev_b32_e32 v2, 12, v2
	v_mov_b32_e32 v3, 0
	v_lshlrev_b64 v[38:39], 1, v[2:3]
	v_lshlrev_b32_e32 v78, 4, v0
	v_lshrrev_b32_e32 v40, 5, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[38:39]
	v_and_b32_e32 v2, 48, v78
	s_lshl_b32 s0, s3, 8
	s_mov_b32 s1, 0
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[2:3]
	v_lshlrev_b32_e32 v2, 13, v40
	global_load_dwordx4 v[30:33], v[4:5], off
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[2:3]
	s_lshl_b64 s[14:15], s[0:1], 1
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[14:15]
	v_lshlrev_b32_e32 v6, 1, v41
	v_mov_b32_e32 v7, v3
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[6:7]
	global_load_dwordx4 v[34:37], v[4:5], off
	v_and_b32_e32 v44, 3, v0
	v_and_b32_e32 v45, 31, v0
	v_lshl_or_b32 v38, v44, 4, v38
	s_add_u32 s6, s6, s14
	v_lshrrev_b32_e32 v79, 6, v0
	v_lshlrev_b32_e32 v42, 6, v0
	v_lshlrev_b32_e32 v41, 6, v41
	v_lshl_add_u64 v[38:39], s[4:5], 0, v[38:39]
	s_addc_u32 s7, s7, s15
	v_lshl_or_b32 v2, v45, 4, v2
	s_mov_b32 s16, 0x8000
	s_mov_b64 s[2:3], 0x40000
	v_and_b32_e32 v43, 48, v0
	v_lshlrev_b32_e32 v46, 10, v79
	v_and_b32_e32 v42, 0x3c0, v42
	v_lshl_or_b32 v40, v40, 1, v41
	v_lshl_add_u64 v[74:75], v[38:39], 0, 64
	v_lshl_add_u64 v[38:39], s[6:7], 0, v[2:3]
	s_mov_b32 s13, s1
	v_mov_b32_e32 v4, v3
	v_mov_b32_e32 v5, v3
	v_mov_b32_e32 v6, v3
	v_mov_b32_e32 v8, v3
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v11, v3
	v_mov_b32_e32 v12, v3
	v_mov_b32_e32 v13, v3
	v_mov_b32_e32 v14, v3
	v_mov_b32_e32 v15, v3
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v17, v3
	v_mov_b32_e32 v18, v3
	v_mov_b32_e32 v19, v3
	v_mov_b32_e32 v20, v3
	v_mov_b32_e32 v21, v3
	v_mov_b32_e32 v22, v3
	v_mov_b32_e32 v23, v3
	v_mov_b32_e32 v24, v3
	v_mov_b32_e32 v25, v3
	v_mov_b32_e32 v26, v3
	v_mov_b32_e32 v27, v3
	v_mov_b32_e32 v28, v3
	v_mov_b32_e32 v29, v3
	v_or3_b32 v80, v46, v42, v43
	v_or3_b32 v81, v42, v43, s16
	v_or_b32_e32 v82, 0x8000, v40
	v_mov_b32_e32 v2, v3
	v_lshl_add_u64 v[76:77], v[38:39], 0, s[2:3]
	v_mov_b32_e32 v38, v3
	v_mov_b32_e32 v39, v3
	v_mov_b32_e32 v41, v3
	v_mov_b32_e32 v42, v3
	v_mov_b32_e32 v43, v3
	v_mov_b32_e32 v44, v3
	v_mov_b32_e32 v45, v3
	v_mov_b32_e32 v46, v3
	v_mov_b32_e32 v47, v3
	v_mov_b32_e32 v48, v3
	v_mov_b32_e32 v49, v3
	v_mov_b32_e32 v50, v3
	v_mov_b32_e32 v51, v3
	v_mov_b32_e32 v52, v3
	v_mov_b32_e32 v53, v3
	s_waitcnt vmcnt(1)
	ds_write_b128 v78, v[30:33]
	s_waitcnt vmcnt(0)
	ds_write_b16 v40, v34 offset:32768
	ds_write_b16_d16_hi v40, v34 offset:32832
	ds_write_b16 v40, v35 offset:32896
	ds_write_b16_d16_hi v40, v35 offset:32960
	ds_write_b16 v40, v36 offset:33024
	ds_write_b16_d16_hi v40, v36 offset:33088
	ds_write_b16 v40, v37 offset:33152
	ds_write_b16_d16_hi v40, v37 offset:33216
	v_mov_b32_e32 v30, v3
	v_mov_b32_e32 v31, v3
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v33, v3
	v_mov_b32_e32 v34, v3
	v_mov_b32_e32 v35, v3
	v_mov_b32_e32 v36, v3
	v_mov_b32_e32 v37, v3
	v_mov_b32_e32 v40, v3
	v_mov_b32_e32 v54, v3
	v_mov_b32_e32 v55, v3
	v_mov_b32_e32 v56, v3
	v_mov_b32_e32 v57, v3
	v_mov_b32_e32 v58, v3
	v_mov_b32_e32 v59, v3
	v_mov_b32_e32 v60, v3
	v_mov_b32_e32 v61, v3
	v_mov_b32_e32 v62, v3
	v_mov_b32_e32 v63, v3
	v_mov_b32_e32 v64, v3
	v_mov_b32_e32 v65, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
                                        ; implicit-def: $vgpr66_vgpr67_vgpr68_vgpr69
                                        ; implicit-def: $vgpr70_vgpr71_vgpr72_vgpr73
	s_branch .LBB1_2
.LBB1_1:                                ; %if.end108.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_add_i32 s13, s13, 32
	v_lshl_add_u64 v[74:75], v[74:75], 0, 64
	v_lshl_add_u64 v[76:77], v[76:77], 0, s[2:3]
	s_andn2_b64 vcc, exec, s[4:5]
	s_add_i32 s1, s1, 1
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccz .LBB1_6
.LBB1_2:                                ; %for.body30.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lt_u32 s13, 0xfe0
	s_cselect_b64 s[6:7], -1, 0
	s_cmpk_gt_u32 s13, 0xfdf
	s_cselect_b64 s[4:5], -1, 0
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB1_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	global_load_dwordx4 v[66:69], v[74:75], off
	global_load_dwordx4 v[70:73], v[76:77], off
.LBB1_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_and_b32 s14, s1, 1
	s_lshl_b32 s15, s14, 14
	v_or_b32_e32 v83, s15, v80
	ds_read_b128 v[84:87], v83
	v_add_u32_e32 v83, s15, v81
	ds_read_b128 v[88:91], v83
	s_andn2_b64 vcc, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[62:65], v[84:87], v[88:91], v[62:65]
	ds_read_b128 v[88:91], v83 offset:1024
	ds_read_b128 v[92:95], v83 offset:2048
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[58:61], v[84:87], v[88:91], v[58:61]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[54:57], v[84:87], v[92:95], v[54:57]
	ds_read_b128 v[88:91], v83 offset:3072
	ds_read_b128 v[92:95], v83 offset:4096
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[50:53], v[84:87], v[88:91], v[50:53]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[46:49], v[84:87], v[92:95], v[46:49]
	ds_read_b128 v[88:91], v83 offset:5120
	ds_read_b128 v[92:95], v83 offset:6144
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[42:45], v[84:87], v[88:91], v[42:45]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[38:41], v[84:87], v[92:95], v[38:41]
	ds_read_b128 v[88:91], v83 offset:7168
	ds_read_b128 v[92:95], v83 offset:8192
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[34:37], v[84:87], v[88:91], v[34:37]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[30:33], v[84:87], v[92:95], v[30:33]
	ds_read_b128 v[88:91], v83 offset:9216
	ds_read_b128 v[92:95], v83 offset:10240
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[26:29], v[84:87], v[88:91], v[26:29]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[22:25], v[84:87], v[92:95], v[22:25]
	ds_read_b128 v[88:91], v83 offset:11264
	ds_read_b128 v[92:95], v83 offset:12288
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[18:21], v[84:87], v[88:91], v[18:21]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[14:17], v[84:87], v[92:95], v[14:17]
	ds_read_b128 v[88:91], v83 offset:13312
	ds_read_b128 v[92:95], v83 offset:14336
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[10:13], v[84:87], v[88:91], v[10:13]
	ds_read_b128 v[88:91], v83 offset:15360
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_f16 v[6:9], v[84:87], v[92:95], v[6:9]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_f16 v[2:5], v[84:87], v[88:91], v[2:5]
	s_cbranch_vccnz .LBB1_1
; %bb.5:                                ; %if.then86.i
                                        ;   in Loop: Header=BB1_2 Depth=1
	s_xor_b32 s6, s14, 1
	s_lshl_b32 s6, s6, 14
	v_or_b32_e32 v83, s6, v78
	s_waitcnt vmcnt(1)
	ds_write_b128 v83, v[66:69]
	v_add_u32_e32 v83, s6, v82
	s_waitcnt vmcnt(0)
	ds_write_b16 v83, v70
	ds_write_b16_d16_hi v83, v70 offset:64
	ds_write_b16 v83, v71 offset:128
	ds_write_b16_d16_hi v83, v71 offset:192
	ds_write_b16 v83, v72 offset:256
	ds_write_b16_d16_hi v83, v72 offset:320
	ds_write_b16 v83, v73 offset:384
	ds_write_b16_d16_hi v83, v73 offset:448
	s_branch .LBB1_1
.LBB1_6:                                ; %_Z8full_f16ILb1EEvPKDF16_S1_S1_PDF16_.exit
	s_waitcnt vmcnt(1)
	v_lshlrev_b32_e32 v66, 4, v79
	v_and_b32_e32 v1, 12, v1
	v_or3_b32 v1, v66, v1, s12
	v_and_or_b32 v66, v0, 15, s0
	v_lshlrev_b32_e32 v67, 12, v1
	v_add_u32_e32 v0, v67, v66
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[68:69], 1, v[0:1]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[70:71], s[8:9], 0, v[68:69]
	global_load_ushort v0, v[70:71], off
	v_lshl_add_u64 v[68:69], s[10:11], 0, v[68:69]
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v74, v62, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v74
	v_exp_f32_e32 v70, v0
	v_or_b32_e32 v62, 0x1000, v67
	v_add_u32_e32 v0, v62, v66
	v_add_f32_e32 v70, 1.0, v70
	v_rcp_f32_e32 v75, v70
	v_lshlrev_b64 v[70:71], 1, v[0:1]
	v_lshl_add_u64 v[72:73], s[8:9], 0, v[70:71]
	v_fma_mixlo_f16 v0, v74, v75, 0
	global_store_short v[68:69], v0, off
	global_load_ushort v0, v[72:73], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v74, v63, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v74
	v_exp_f32_e32 v68, v0
	v_or_b32_e32 v63, 0x2000, v67
	v_add_u32_e32 v0, v63, v66
	v_add_f32_e32 v68, 1.0, v68
	v_rcp_f32_e32 v75, v68
	v_lshl_add_u64 v[68:69], s[10:11], 0, v[70:71]
	v_lshlrev_b64 v[70:71], 1, v[0:1]
	v_lshl_add_u64 v[72:73], s[8:9], 0, v[70:71]
	v_fma_mixlo_f16 v0, v74, v75, 0
	global_store_short v[68:69], v0, off
	global_load_ushort v0, v[72:73], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v74, v64, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v74
	v_exp_f32_e32 v68, v0
	v_or_b32_e32 v64, 0x3000, v67
	v_add_u32_e32 v0, v64, v66
	v_add_f32_e32 v68, 1.0, v68
	v_rcp_f32_e32 v75, v68
	v_lshl_add_u64 v[68:69], s[10:11], 0, v[70:71]
	v_lshlrev_b64 v[70:71], 1, v[0:1]
	v_lshl_add_u64 v[72:73], s[8:9], 0, v[70:71]
	v_fma_mixlo_f16 v0, v74, v75, 0
	global_store_short v[68:69], v0, off
	global_load_ushort v0, v[72:73], off
	v_or_b32_e32 v74, 16, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v65, v65, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v65
	v_exp_f32_e32 v68, v0
	v_add_u32_e32 v0, v67, v74
	v_add_f32_e32 v68, 1.0, v68
	v_rcp_f32_e32 v75, v68
	v_lshl_add_u64 v[68:69], s[10:11], 0, v[70:71]
	v_lshlrev_b64 v[70:71], 1, v[0:1]
	v_lshl_add_u64 v[72:73], s[8:9], 0, v[70:71]
	v_fma_mixlo_f16 v0, v65, v75, 0
	global_store_short v[68:69], v0, off
	global_load_ushort v0, v[72:73], off
	v_lshl_add_u64 v[68:69], s[10:11], 0, v[70:71]
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v58, v58, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v58
	v_exp_f32_e32 v65, v0
	v_add_u32_e32 v0, v62, v74
	v_lshlrev_b64 v[70:71], 1, v[0:1]
	v_lshl_add_u64 v[72:73], s[8:9], 0, v[70:71]
	v_add_f32_e32 v65, 1.0, v65
	v_rcp_f32_e32 v65, v65
	s_nop 0
	v_fma_mixlo_f16 v0, v58, v65, 0
	global_store_short v[68:69], v0, off
	global_load_ushort v0, v[72:73], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v65, v59, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v65
	v_exp_f32_e32 v58, v0
	v_add_u32_e32 v0, v63, v74
	v_lshlrev_b64 v[68:69], 1, v[0:1]
	v_add_f32_e32 v58, 1.0, v58
	v_rcp_f32_e32 v72, v58
	v_lshl_add_u64 v[58:59], s[10:11], 0, v[70:71]
	v_lshl_add_u64 v[70:71], s[8:9], 0, v[68:69]
	v_fma_mixlo_f16 v0, v65, v72, 0
	global_store_short v[58:59], v0, off
	global_load_ushort v0, v[70:71], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v60, v60, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v60
	v_exp_f32_e32 v58, v0
	v_add_u32_e32 v0, v64, v74
	v_add_f32_e32 v58, 1.0, v58
	v_rcp_f32_e32 v65, v58
	v_lshl_add_u64 v[58:59], s[10:11], 0, v[68:69]
	v_lshlrev_b64 v[68:69], 1, v[0:1]
	v_lshl_add_u64 v[70:71], s[8:9], 0, v[68:69]
	v_fma_mixlo_f16 v0, v60, v65, 0
	global_store_short v[58:59], v0, off
	global_load_ushort v0, v[70:71], off
	v_or_b32_e32 v70, 32, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v65, v61, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v65
	v_exp_f32_e32 v58, v0
	v_add_u32_e32 v0, v67, v70
	v_lshlrev_b64 v[60:61], 1, v[0:1]
	v_add_f32_e32 v58, 1.0, v58
	v_rcp_f32_e32 v71, v58
	v_lshl_add_u64 v[58:59], s[10:11], 0, v[68:69]
	v_lshl_add_u64 v[68:69], s[8:9], 0, v[60:61]
	v_fma_mixlo_f16 v0, v65, v71, 0
	global_store_short v[58:59], v0, off
	global_load_ushort v0, v[68:69], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v54, v54, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v54
	v_exp_f32_e32 v58, v0
	v_add_u32_e32 v0, v62, v70
	v_add_f32_e32 v58, 1.0, v58
	v_rcp_f32_e32 v65, v58
	v_lshl_add_u64 v[58:59], s[10:11], 0, v[60:61]
	v_lshlrev_b64 v[60:61], 1, v[0:1]
	v_lshl_add_u64 v[68:69], s[8:9], 0, v[60:61]
	v_fma_mixlo_f16 v0, v54, v65, 0
	global_store_short v[58:59], v0, off
	global_load_ushort v0, v[68:69], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v65, v55, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v65
	v_exp_f32_e32 v54, v0
	v_add_u32_e32 v0, v63, v70
	v_lshlrev_b64 v[58:59], 1, v[0:1]
	v_add_f32_e32 v54, 1.0, v54
	v_rcp_f32_e32 v68, v54
	v_lshl_add_u64 v[54:55], s[10:11], 0, v[60:61]
	v_lshl_add_u64 v[60:61], s[8:9], 0, v[58:59]
	v_fma_mixlo_f16 v0, v65, v68, 0
	global_store_short v[54:55], v0, off
	global_load_ushort v0, v[60:61], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v56, v56, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v56
	v_exp_f32_e32 v54, v0
	v_add_u32_e32 v0, v64, v70
	v_add_f32_e32 v54, 1.0, v54
	v_rcp_f32_e32 v65, v54
	v_lshl_add_u64 v[54:55], s[10:11], 0, v[58:59]
	v_lshlrev_b64 v[58:59], 1, v[0:1]
	v_lshl_add_u64 v[60:61], s[8:9], 0, v[58:59]
	v_fma_mixlo_f16 v0, v56, v65, 0
	global_store_short v[54:55], v0, off
	global_load_ushort v0, v[60:61], off
	v_or_b32_e32 v61, 48, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v60, v57, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v60
	v_exp_f32_e32 v54, v0
	v_add_u32_e32 v0, v67, v61
	v_lshlrev_b64 v[56:57], 1, v[0:1]
	v_add_f32_e32 v54, 1.0, v54
	v_rcp_f32_e32 v65, v54
	v_lshl_add_u64 v[54:55], s[10:11], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[56:57]
	v_fma_mixlo_f16 v0, v60, v65, 0
	global_store_short v[54:55], v0, off
	global_load_ushort v0, v[58:59], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v50, v50, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v50
	v_exp_f32_e32 v54, v0
	v_add_u32_e32 v0, v62, v61
	v_add_f32_e32 v54, 1.0, v54
	v_rcp_f32_e32 v60, v54
	v_lshl_add_u64 v[54:55], s[10:11], 0, v[56:57]
	v_lshlrev_b64 v[56:57], 1, v[0:1]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[56:57]
	v_fma_mixlo_f16 v0, v50, v60, 0
	global_store_short v[54:55], v0, off
	global_load_ushort v0, v[58:59], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v58, v51, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v58
	v_exp_f32_e32 v50, v0
	v_add_u32_e32 v0, v63, v61
	v_lshlrev_b64 v[54:55], 1, v[0:1]
	v_add_f32_e32 v50, 1.0, v50
	v_rcp_f32_e32 v59, v50
	v_lshl_add_u64 v[50:51], s[10:11], 0, v[56:57]
	v_lshl_add_u64 v[56:57], s[8:9], 0, v[54:55]
	v_fma_mixlo_f16 v0, v58, v59, 0
	global_store_short v[50:51], v0, off
	global_load_ushort v0, v[56:57], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v52, v52, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v52
	v_exp_f32_e32 v50, v0
	v_add_u32_e32 v0, v64, v61
	v_add_f32_e32 v50, 1.0, v50
	v_rcp_f32_e32 v58, v50
	v_lshl_add_u64 v[50:51], s[10:11], 0, v[54:55]
	v_lshlrev_b64 v[54:55], 1, v[0:1]
	v_lshl_add_u64 v[56:57], s[8:9], 0, v[54:55]
	v_fma_mixlo_f16 v0, v52, v58, 0
	global_store_short v[50:51], v0, off
	global_load_ushort v0, v[56:57], off
	v_or_b32_e32 v57, 64, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v56, v53, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v56
	v_exp_f32_e32 v50, v0
	v_add_u32_e32 v0, v67, v57
	v_lshlrev_b64 v[52:53], 1, v[0:1]
	v_add_f32_e32 v50, 1.0, v50
	v_rcp_f32_e32 v58, v50
	v_lshl_add_u64 v[50:51], s[10:11], 0, v[54:55]
	v_lshl_add_u64 v[54:55], s[8:9], 0, v[52:53]
	v_fma_mixlo_f16 v0, v56, v58, 0
	global_store_short v[50:51], v0, off
	global_load_ushort v0, v[54:55], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v46, v46, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v46
	v_exp_f32_e32 v50, v0
	v_add_u32_e32 v0, v62, v57
	v_add_f32_e32 v50, 1.0, v50
	v_rcp_f32_e32 v56, v50
	v_lshl_add_u64 v[50:51], s[10:11], 0, v[52:53]
	v_lshlrev_b64 v[52:53], 1, v[0:1]
	v_lshl_add_u64 v[54:55], s[8:9], 0, v[52:53]
	v_fma_mixlo_f16 v0, v46, v56, 0
	global_store_short v[50:51], v0, off
	global_load_ushort v0, v[54:55], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v54, v47, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v54
	v_exp_f32_e32 v46, v0
	v_add_u32_e32 v0, v63, v57
	v_lshlrev_b64 v[50:51], 1, v[0:1]
	v_add_f32_e32 v46, 1.0, v46
	v_rcp_f32_e32 v55, v46
	v_lshl_add_u64 v[46:47], s[10:11], 0, v[52:53]
	v_lshl_add_u64 v[52:53], s[8:9], 0, v[50:51]
	v_fma_mixlo_f16 v0, v54, v55, 0
	global_store_short v[46:47], v0, off
	global_load_ushort v0, v[52:53], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v48, v48, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v48
	v_exp_f32_e32 v46, v0
	v_add_u32_e32 v0, v64, v57
	v_add_f32_e32 v46, 1.0, v46
	v_rcp_f32_e32 v54, v46
	v_lshl_add_u64 v[46:47], s[10:11], 0, v[50:51]
	v_lshlrev_b64 v[50:51], 1, v[0:1]
	v_lshl_add_u64 v[52:53], s[8:9], 0, v[50:51]
	v_fma_mixlo_f16 v0, v48, v54, 0
	global_store_short v[46:47], v0, off
	global_load_ushort v0, v[52:53], off
	v_or_b32_e32 v53, 0x50, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v52, v49, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v52
	v_exp_f32_e32 v46, v0
	v_add_u32_e32 v0, v67, v53
	v_lshlrev_b64 v[48:49], 1, v[0:1]
	v_add_f32_e32 v46, 1.0, v46
	v_rcp_f32_e32 v54, v46
	v_lshl_add_u64 v[46:47], s[10:11], 0, v[50:51]
	v_lshl_add_u64 v[50:51], s[8:9], 0, v[48:49]
	v_fma_mixlo_f16 v0, v52, v54, 0
	global_store_short v[46:47], v0, off
	global_load_ushort v0, v[50:51], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v42, v42, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v42
	v_exp_f32_e32 v46, v0
	v_add_u32_e32 v0, v62, v53
	v_add_f32_e32 v46, 1.0, v46
	v_rcp_f32_e32 v52, v46
	v_lshl_add_u64 v[46:47], s[10:11], 0, v[48:49]
	v_lshlrev_b64 v[48:49], 1, v[0:1]
	v_lshl_add_u64 v[50:51], s[8:9], 0, v[48:49]
	v_fma_mixlo_f16 v0, v42, v52, 0
	global_store_short v[46:47], v0, off
	global_load_ushort v0, v[50:51], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v50, v43, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v50
	v_exp_f32_e32 v42, v0
	v_add_u32_e32 v0, v63, v53
	v_lshlrev_b64 v[46:47], 1, v[0:1]
	v_add_f32_e32 v42, 1.0, v42
	v_rcp_f32_e32 v51, v42
	v_lshl_add_u64 v[42:43], s[10:11], 0, v[48:49]
	v_lshl_add_u64 v[48:49], s[8:9], 0, v[46:47]
	v_fma_mixlo_f16 v0, v50, v51, 0
	global_store_short v[42:43], v0, off
	global_load_ushort v0, v[48:49], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v44, v44, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v44
	v_exp_f32_e32 v42, v0
	v_add_u32_e32 v0, v64, v53
	v_add_f32_e32 v42, 1.0, v42
	v_rcp_f32_e32 v50, v42
	v_lshl_add_u64 v[42:43], s[10:11], 0, v[46:47]
	v_lshlrev_b64 v[46:47], 1, v[0:1]
	v_lshl_add_u64 v[48:49], s[8:9], 0, v[46:47]
	v_fma_mixlo_f16 v0, v44, v50, 0
	global_store_short v[42:43], v0, off
	global_load_ushort v0, v[48:49], off
	v_or_b32_e32 v49, 0x60, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v48, v45, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v48
	v_exp_f32_e32 v42, v0
	v_add_u32_e32 v0, v67, v49
	v_lshlrev_b64 v[44:45], 1, v[0:1]
	v_add_f32_e32 v42, 1.0, v42
	v_rcp_f32_e32 v50, v42
	v_lshl_add_u64 v[42:43], s[10:11], 0, v[46:47]
	v_lshl_add_u64 v[46:47], s[8:9], 0, v[44:45]
	v_fma_mixlo_f16 v0, v48, v50, 0
	global_store_short v[42:43], v0, off
	global_load_ushort v0, v[46:47], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v38, v38, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v38
	v_exp_f32_e32 v42, v0
	v_add_u32_e32 v0, v62, v49
	v_add_f32_e32 v42, 1.0, v42
	v_rcp_f32_e32 v48, v42
	v_lshl_add_u64 v[42:43], s[10:11], 0, v[44:45]
	v_lshlrev_b64 v[44:45], 1, v[0:1]
	v_lshl_add_u64 v[46:47], s[8:9], 0, v[44:45]
	v_fma_mixlo_f16 v0, v38, v48, 0
	global_store_short v[42:43], v0, off
	global_load_ushort v0, v[46:47], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v46, v39, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v46
	v_exp_f32_e32 v38, v0
	v_add_u32_e32 v0, v63, v49
	v_lshlrev_b64 v[42:43], 1, v[0:1]
	v_add_f32_e32 v38, 1.0, v38
	v_rcp_f32_e32 v47, v38
	v_lshl_add_u64 v[38:39], s[10:11], 0, v[44:45]
	v_lshl_add_u64 v[44:45], s[8:9], 0, v[42:43]
	v_fma_mixlo_f16 v0, v46, v47, 0
	global_store_short v[38:39], v0, off
	global_load_ushort v0, v[44:45], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v40, v40, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v40
	v_exp_f32_e32 v38, v0
	v_add_u32_e32 v0, v64, v49
	v_add_f32_e32 v38, 1.0, v38
	v_rcp_f32_e32 v46, v38
	v_lshl_add_u64 v[38:39], s[10:11], 0, v[42:43]
	v_lshlrev_b64 v[42:43], 1, v[0:1]
	v_lshl_add_u64 v[44:45], s[8:9], 0, v[42:43]
	v_fma_mixlo_f16 v0, v40, v46, 0
	global_store_short v[38:39], v0, off
	global_load_ushort v0, v[44:45], off
	v_or_b32_e32 v45, 0x70, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v44, v41, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v44
	v_exp_f32_e32 v38, v0
	v_add_u32_e32 v0, v67, v45
	v_lshlrev_b64 v[40:41], 1, v[0:1]
	v_add_f32_e32 v38, 1.0, v38
	v_rcp_f32_e32 v46, v38
	v_lshl_add_u64 v[38:39], s[10:11], 0, v[42:43]
	v_lshl_add_u64 v[42:43], s[8:9], 0, v[40:41]
	v_fma_mixlo_f16 v0, v44, v46, 0
	global_store_short v[38:39], v0, off
	global_load_ushort v0, v[42:43], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v34, v34, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v34
	v_exp_f32_e32 v38, v0
	v_add_u32_e32 v0, v62, v45
	v_add_f32_e32 v38, 1.0, v38
	v_rcp_f32_e32 v44, v38
	v_lshl_add_u64 v[38:39], s[10:11], 0, v[40:41]
	v_lshlrev_b64 v[40:41], 1, v[0:1]
	v_lshl_add_u64 v[42:43], s[8:9], 0, v[40:41]
	v_fma_mixlo_f16 v0, v34, v44, 0
	global_store_short v[38:39], v0, off
	global_load_ushort v0, v[42:43], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v42, v35, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v42
	v_exp_f32_e32 v34, v0
	v_add_u32_e32 v0, v63, v45
	v_lshlrev_b64 v[38:39], 1, v[0:1]
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v43, v34
	v_lshl_add_u64 v[34:35], s[10:11], 0, v[40:41]
	v_lshl_add_u64 v[40:41], s[8:9], 0, v[38:39]
	v_fma_mixlo_f16 v0, v42, v43, 0
	global_store_short v[34:35], v0, off
	global_load_ushort v0, v[40:41], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v36, v36, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v0
	v_add_u32_e32 v0, v64, v45
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v42, v34
	v_lshl_add_u64 v[34:35], s[10:11], 0, v[38:39]
	v_lshlrev_b64 v[38:39], 1, v[0:1]
	v_lshl_add_u64 v[40:41], s[8:9], 0, v[38:39]
	v_fma_mixlo_f16 v0, v36, v42, 0
	global_store_short v[34:35], v0, off
	global_load_ushort v0, v[40:41], off
	v_or_b32_e32 v41, 0x80, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v40, v37, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v40
	v_exp_f32_e32 v34, v0
	v_add_u32_e32 v0, v67, v41
	v_lshlrev_b64 v[36:37], 1, v[0:1]
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v42, v34
	v_lshl_add_u64 v[34:35], s[10:11], 0, v[38:39]
	v_lshl_add_u64 v[38:39], s[8:9], 0, v[36:37]
	v_fma_mixlo_f16 v0, v40, v42, 0
	global_store_short v[34:35], v0, off
	global_load_ushort v0, v[38:39], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v30, v30, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v30
	v_exp_f32_e32 v34, v0
	v_add_u32_e32 v0, v62, v41
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v40, v34
	v_lshl_add_u64 v[34:35], s[10:11], 0, v[36:37]
	v_lshlrev_b64 v[36:37], 1, v[0:1]
	v_lshl_add_u64 v[38:39], s[8:9], 0, v[36:37]
	v_fma_mixlo_f16 v0, v30, v40, 0
	global_store_short v[34:35], v0, off
	global_load_ushort v0, v[38:39], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v38, v31, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v38
	v_exp_f32_e32 v30, v0
	v_add_u32_e32 v0, v63, v41
	v_lshlrev_b64 v[34:35], 1, v[0:1]
	v_add_f32_e32 v30, 1.0, v30
	v_rcp_f32_e32 v39, v30
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[36:37]
	v_lshl_add_u64 v[36:37], s[8:9], 0, v[34:35]
	v_fma_mixlo_f16 v0, v38, v39, 0
	global_store_short v[30:31], v0, off
	global_load_ushort v0, v[36:37], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v32, v32, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v32
	v_exp_f32_e32 v30, v0
	v_add_u32_e32 v0, v64, v41
	v_add_f32_e32 v30, 1.0, v30
	v_rcp_f32_e32 v38, v30
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[34:35]
	v_lshlrev_b64 v[34:35], 1, v[0:1]
	v_lshl_add_u64 v[36:37], s[8:9], 0, v[34:35]
	v_fma_mixlo_f16 v0, v32, v38, 0
	global_store_short v[30:31], v0, off
	global_load_ushort v0, v[36:37], off
	v_or_b32_e32 v37, 0x90, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v36, v33, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v36
	v_exp_f32_e32 v30, v0
	v_add_u32_e32 v0, v67, v37
	v_lshlrev_b64 v[32:33], 1, v[0:1]
	v_add_f32_e32 v30, 1.0, v30
	v_rcp_f32_e32 v38, v30
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[34:35]
	v_lshl_add_u64 v[34:35], s[8:9], 0, v[32:33]
	v_fma_mixlo_f16 v0, v36, v38, 0
	global_store_short v[30:31], v0, off
	global_load_ushort v0, v[34:35], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v26, v26, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v26
	v_exp_f32_e32 v30, v0
	v_add_u32_e32 v0, v62, v37
	v_add_f32_e32 v30, 1.0, v30
	v_rcp_f32_e32 v36, v30
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[32:33]
	v_lshlrev_b64 v[32:33], 1, v[0:1]
	v_lshl_add_u64 v[34:35], s[8:9], 0, v[32:33]
	v_fma_mixlo_f16 v0, v26, v36, 0
	global_store_short v[30:31], v0, off
	global_load_ushort v0, v[34:35], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v34, v27, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v34
	v_exp_f32_e32 v26, v0
	v_add_u32_e32 v0, v63, v37
	v_lshlrev_b64 v[30:31], 1, v[0:1]
	v_add_f32_e32 v26, 1.0, v26
	v_rcp_f32_e32 v35, v26
	v_lshl_add_u64 v[26:27], s[10:11], 0, v[32:33]
	v_lshl_add_u64 v[32:33], s[8:9], 0, v[30:31]
	v_fma_mixlo_f16 v0, v34, v35, 0
	global_store_short v[26:27], v0, off
	global_load_ushort v0, v[32:33], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v28, v28, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v28
	v_exp_f32_e32 v26, v0
	v_add_u32_e32 v0, v64, v37
	v_add_f32_e32 v26, 1.0, v26
	v_rcp_f32_e32 v34, v26
	v_lshl_add_u64 v[26:27], s[10:11], 0, v[30:31]
	v_lshlrev_b64 v[30:31], 1, v[0:1]
	v_lshl_add_u64 v[32:33], s[8:9], 0, v[30:31]
	v_fma_mixlo_f16 v0, v28, v34, 0
	global_store_short v[26:27], v0, off
	global_load_ushort v0, v[32:33], off
	v_or_b32_e32 v33, 0xa0, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v32, v29, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v32
	v_exp_f32_e32 v26, v0
	v_add_u32_e32 v0, v67, v33
	v_lshlrev_b64 v[28:29], 1, v[0:1]
	v_add_f32_e32 v26, 1.0, v26
	v_rcp_f32_e32 v34, v26
	v_lshl_add_u64 v[26:27], s[10:11], 0, v[30:31]
	v_lshl_add_u64 v[30:31], s[8:9], 0, v[28:29]
	v_fma_mixlo_f16 v0, v32, v34, 0
	global_store_short v[26:27], v0, off
	global_load_ushort v0, v[30:31], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v22, v22, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v22
	v_exp_f32_e32 v26, v0
	v_add_u32_e32 v0, v62, v33
	v_add_f32_e32 v26, 1.0, v26
	v_rcp_f32_e32 v32, v26
	v_lshl_add_u64 v[26:27], s[10:11], 0, v[28:29]
	v_lshlrev_b64 v[28:29], 1, v[0:1]
	v_lshl_add_u64 v[30:31], s[8:9], 0, v[28:29]
	v_fma_mixlo_f16 v0, v22, v32, 0
	global_store_short v[26:27], v0, off
	global_load_ushort v0, v[30:31], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v30, v23, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v30
	v_exp_f32_e32 v22, v0
	v_add_u32_e32 v0, v63, v33
	v_lshlrev_b64 v[26:27], 1, v[0:1]
	v_add_f32_e32 v22, 1.0, v22
	v_rcp_f32_e32 v31, v22
	v_lshl_add_u64 v[22:23], s[10:11], 0, v[28:29]
	v_lshl_add_u64 v[28:29], s[8:9], 0, v[26:27]
	v_fma_mixlo_f16 v0, v30, v31, 0
	global_store_short v[22:23], v0, off
	global_load_ushort v0, v[28:29], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v24, v24, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v24
	v_exp_f32_e32 v22, v0
	v_add_u32_e32 v0, v64, v33
	v_add_f32_e32 v22, 1.0, v22
	v_rcp_f32_e32 v30, v22
	v_lshl_add_u64 v[22:23], s[10:11], 0, v[26:27]
	v_lshlrev_b64 v[26:27], 1, v[0:1]
	v_lshl_add_u64 v[28:29], s[8:9], 0, v[26:27]
	v_fma_mixlo_f16 v0, v24, v30, 0
	global_store_short v[22:23], v0, off
	global_load_ushort v0, v[28:29], off
	v_or_b32_e32 v29, 0xb0, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v28, v25, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v28
	v_exp_f32_e32 v22, v0
	v_add_u32_e32 v0, v67, v29
	v_lshlrev_b64 v[24:25], 1, v[0:1]
	v_add_f32_e32 v22, 1.0, v22
	v_rcp_f32_e32 v30, v22
	v_lshl_add_u64 v[22:23], s[10:11], 0, v[26:27]
	v_lshl_add_u64 v[26:27], s[8:9], 0, v[24:25]
	v_fma_mixlo_f16 v0, v28, v30, 0
	global_store_short v[22:23], v0, off
	global_load_ushort v0, v[26:27], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v18, v18, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v18
	v_exp_f32_e32 v22, v0
	v_add_u32_e32 v0, v62, v29
	v_add_f32_e32 v22, 1.0, v22
	v_rcp_f32_e32 v28, v22
	v_lshl_add_u64 v[22:23], s[10:11], 0, v[24:25]
	v_lshlrev_b64 v[24:25], 1, v[0:1]
	v_lshl_add_u64 v[26:27], s[8:9], 0, v[24:25]
	v_fma_mixlo_f16 v0, v18, v28, 0
	global_store_short v[22:23], v0, off
	global_load_ushort v0, v[26:27], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v26, v19, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v26
	v_exp_f32_e32 v18, v0
	v_add_u32_e32 v0, v63, v29
	v_lshlrev_b64 v[22:23], 1, v[0:1]
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v27, v18
	v_lshl_add_u64 v[18:19], s[10:11], 0, v[24:25]
	v_lshl_add_u64 v[24:25], s[8:9], 0, v[22:23]
	v_fma_mixlo_f16 v0, v26, v27, 0
	global_store_short v[18:19], v0, off
	global_load_ushort v0, v[24:25], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v20, v20, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v0
	v_add_u32_e32 v0, v64, v29
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v26, v18
	v_lshl_add_u64 v[18:19], s[10:11], 0, v[22:23]
	v_lshlrev_b64 v[22:23], 1, v[0:1]
	v_lshl_add_u64 v[24:25], s[8:9], 0, v[22:23]
	v_fma_mixlo_f16 v0, v20, v26, 0
	global_store_short v[18:19], v0, off
	global_load_ushort v0, v[24:25], off
	v_or_b32_e32 v25, 0xc0, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v24, v21, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v24
	v_exp_f32_e32 v18, v0
	v_add_u32_e32 v0, v67, v25
	v_lshlrev_b64 v[20:21], 1, v[0:1]
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v26, v18
	v_lshl_add_u64 v[18:19], s[10:11], 0, v[22:23]
	v_lshl_add_u64 v[22:23], s[8:9], 0, v[20:21]
	v_fma_mixlo_f16 v0, v24, v26, 0
	global_store_short v[18:19], v0, off
	global_load_ushort v0, v[22:23], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v14, v14, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v14
	v_exp_f32_e32 v18, v0
	v_add_u32_e32 v0, v62, v25
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v24, v18
	v_lshl_add_u64 v[18:19], s[10:11], 0, v[20:21]
	v_lshlrev_b64 v[20:21], 1, v[0:1]
	v_lshl_add_u64 v[22:23], s[8:9], 0, v[20:21]
	v_fma_mixlo_f16 v0, v14, v24, 0
	global_store_short v[18:19], v0, off
	global_load_ushort v0, v[22:23], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v22, v15, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v22
	v_exp_f32_e32 v14, v0
	v_add_u32_e32 v0, v63, v25
	v_lshlrev_b64 v[18:19], 1, v[0:1]
	v_add_f32_e32 v14, 1.0, v14
	v_rcp_f32_e32 v23, v14
	v_lshl_add_u64 v[14:15], s[10:11], 0, v[20:21]
	v_lshl_add_u64 v[20:21], s[8:9], 0, v[18:19]
	v_fma_mixlo_f16 v0, v22, v23, 0
	global_store_short v[14:15], v0, off
	global_load_ushort v0, v[20:21], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v16, v16, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v16
	v_exp_f32_e32 v14, v0
	v_add_u32_e32 v0, v64, v25
	v_add_f32_e32 v14, 1.0, v14
	v_rcp_f32_e32 v22, v14
	v_lshl_add_u64 v[14:15], s[10:11], 0, v[18:19]
	v_lshlrev_b64 v[18:19], 1, v[0:1]
	v_lshl_add_u64 v[20:21], s[8:9], 0, v[18:19]
	v_fma_mixlo_f16 v0, v16, v22, 0
	global_store_short v[14:15], v0, off
	global_load_ushort v0, v[20:21], off
	v_or_b32_e32 v21, 0xd0, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v20, v17, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v20
	v_exp_f32_e32 v14, v0
	v_add_u32_e32 v0, v67, v21
	v_lshlrev_b64 v[16:17], 1, v[0:1]
	v_add_f32_e32 v14, 1.0, v14
	v_rcp_f32_e32 v22, v14
	v_lshl_add_u64 v[14:15], s[10:11], 0, v[18:19]
	v_lshl_add_u64 v[18:19], s[8:9], 0, v[16:17]
	v_fma_mixlo_f16 v0, v20, v22, 0
	global_store_short v[14:15], v0, off
	global_load_ushort v0, v[18:19], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v10, v10, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v10
	v_exp_f32_e32 v14, v0
	v_add_u32_e32 v0, v62, v21
	v_add_f32_e32 v14, 1.0, v14
	v_rcp_f32_e32 v20, v14
	v_lshl_add_u64 v[14:15], s[10:11], 0, v[16:17]
	v_lshlrev_b64 v[16:17], 1, v[0:1]
	v_lshl_add_u64 v[18:19], s[8:9], 0, v[16:17]
	v_fma_mixlo_f16 v0, v10, v20, 0
	global_store_short v[14:15], v0, off
	global_load_ushort v0, v[18:19], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v18, v11, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v18
	v_exp_f32_e32 v10, v0
	v_add_u32_e32 v0, v63, v21
	v_lshlrev_b64 v[14:15], 1, v[0:1]
	v_add_f32_e32 v10, 1.0, v10
	v_rcp_f32_e32 v19, v10
	v_lshl_add_u64 v[10:11], s[10:11], 0, v[16:17]
	v_lshl_add_u64 v[16:17], s[8:9], 0, v[14:15]
	v_fma_mixlo_f16 v0, v18, v19, 0
	global_store_short v[10:11], v0, off
	global_load_ushort v0, v[16:17], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v12, v12, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v12
	v_exp_f32_e32 v10, v0
	v_add_u32_e32 v0, v64, v21
	v_add_f32_e32 v10, 1.0, v10
	v_rcp_f32_e32 v18, v10
	v_lshl_add_u64 v[10:11], s[10:11], 0, v[14:15]
	v_lshlrev_b64 v[14:15], 1, v[0:1]
	v_lshl_add_u64 v[16:17], s[8:9], 0, v[14:15]
	v_fma_mixlo_f16 v0, v12, v18, 0
	global_store_short v[10:11], v0, off
	global_load_ushort v0, v[16:17], off
	v_or_b32_e32 v17, 0xe0, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v16, v13, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v16
	v_exp_f32_e32 v10, v0
	v_add_u32_e32 v0, v67, v17
	v_lshlrev_b64 v[12:13], 1, v[0:1]
	v_add_f32_e32 v10, 1.0, v10
	v_rcp_f32_e32 v18, v10
	v_lshl_add_u64 v[10:11], s[10:11], 0, v[14:15]
	v_lshl_add_u64 v[14:15], s[8:9], 0, v[12:13]
	v_fma_mixlo_f16 v0, v16, v18, 0
	global_store_short v[10:11], v0, off
	global_load_ushort v0, v[14:15], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v6, v6, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v6
	v_exp_f32_e32 v10, v0
	v_add_u32_e32 v0, v62, v17
	v_add_f32_e32 v10, 1.0, v10
	v_rcp_f32_e32 v16, v10
	v_lshl_add_u64 v[10:11], s[10:11], 0, v[12:13]
	v_lshlrev_b64 v[12:13], 1, v[0:1]
	v_lshl_add_u64 v[14:15], s[8:9], 0, v[12:13]
	v_fma_mixlo_f16 v0, v6, v16, 0
	global_store_short v[10:11], v0, off
	global_load_ushort v0, v[14:15], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v14, v7, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v14
	v_exp_f32_e32 v6, v0
	v_add_u32_e32 v0, v63, v17
	v_lshlrev_b64 v[10:11], 1, v[0:1]
	v_add_f32_e32 v6, 1.0, v6
	v_rcp_f32_e32 v15, v6
	v_lshl_add_u64 v[6:7], s[10:11], 0, v[12:13]
	v_lshl_add_u64 v[12:13], s[8:9], 0, v[10:11]
	v_fma_mixlo_f16 v0, v14, v15, 0
	global_store_short v[6:7], v0, off
	global_load_ushort v0, v[12:13], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v8, v8, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v8
	v_exp_f32_e32 v6, v0
	v_add_u32_e32 v0, v64, v17
	v_add_f32_e32 v6, 1.0, v6
	v_rcp_f32_e32 v14, v6
	v_lshl_add_u64 v[6:7], s[10:11], 0, v[10:11]
	v_lshlrev_b64 v[10:11], 1, v[0:1]
	v_lshl_add_u64 v[12:13], s[8:9], 0, v[10:11]
	v_fma_mixlo_f16 v0, v8, v14, 0
	global_store_short v[6:7], v0, off
	global_load_ushort v0, v[12:13], off
	v_or_b32_e32 v13, 0xf0, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v12, v9, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v12
	v_exp_f32_e32 v6, v0
	v_add_u32_e32 v0, v67, v13
	v_lshlrev_b64 v[8:9], 1, v[0:1]
	v_add_f32_e32 v6, 1.0, v6
	v_rcp_f32_e32 v14, v6
	v_lshl_add_u64 v[6:7], s[10:11], 0, v[10:11]
	v_lshl_add_u64 v[10:11], s[8:9], 0, v[8:9]
	v_fma_mixlo_f16 v0, v12, v14, 0
	global_store_short v[6:7], v0, off
	global_load_ushort v0, v[10:11], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v2, v2, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v2
	v_exp_f32_e32 v6, v0
	v_add_u32_e32 v0, v62, v13
	v_add_f32_e32 v6, 1.0, v6
	v_rcp_f32_e32 v12, v6
	v_lshl_add_u64 v[6:7], s[10:11], 0, v[8:9]
	v_lshlrev_b64 v[8:9], 1, v[0:1]
	v_lshl_add_u64 v[10:11], s[8:9], 0, v[8:9]
	v_fma_mixlo_f16 v0, v2, v12, 0
	global_store_short v[6:7], v0, off
	global_load_ushort v0, v[10:11], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v10, v3, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v10
	v_exp_f32_e32 v2, v0
	v_add_u32_e32 v0, v63, v13
	v_lshlrev_b64 v[6:7], 1, v[0:1]
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v11, v2
	v_lshl_add_u64 v[2:3], s[10:11], 0, v[8:9]
	v_lshl_add_u64 v[8:9], s[8:9], 0, v[6:7]
	v_fma_mixlo_f16 v0, v10, v11, 0
	global_store_short v[2:3], v0, off
	global_load_ushort v0, v[8:9], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v0, v0
	v_add_f32_e32 v4, v4, v0
	v_mul_f32_e32 v0, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v0
	v_add_u32_e32 v0, v64, v13
	v_lshlrev_b64 v[0:1], 1, v[0:1]
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v8, v2
	v_lshl_add_u64 v[2:3], s[10:11], 0, v[6:7]
	v_lshl_add_u64 v[6:7], s[8:9], 0, v[0:1]
	v_lshl_add_u64 v[0:1], s[10:11], 0, v[0:1]
	v_fma_mixlo_f16 v4, v4, v8, 0
	global_store_short v[2:3], v4, off
	global_load_ushort v2, v[6:7], off
	s_waitcnt vmcnt(0)
	v_cvt_f32_f16_e32 v2, v2
	v_add_f32_e32 v2, v5, v2
	v_mul_f32_e32 v3, 0xbfb8aa3b, v2
	v_exp_f32_e32 v3, v3
	s_nop 0
	v_add_f32_e32 v3, 1.0, v3
	v_rcp_f32_e32 v3, v3
	s_nop 0
	v_fma_mixlo_f16 v2, v2, v3, 0
	global_store_short v[0:1], v2, off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 96
		.amdhsa_next_free_sgpr 17
		.amdhsa_accum_offset 96
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
	.size	gemm_add_silu_f16_full, .Lfunc_end1-gemm_add_silu_f16_full
                                        ; -- End function
	.set gemm_add_silu_f16_full.num_vgpr, 96
	.set gemm_add_silu_f16_full.num_agpr, 0
	.set gemm_add_silu_f16_full.numbered_sgpr, 17
	.set gemm_add_silu_f16_full.num_named_barrier, 0
	.set gemm_add_silu_f16_full.private_seg_size, 0
	.set gemm_add_silu_f16_full.uses_vcc, 1
	.set gemm_add_silu_f16_full.uses_flat_scratch, 0
	.set gemm_add_silu_f16_full.has_dyn_sized_stack, 0
	.set gemm_add_silu_f16_full.has_recursion, 0
	.set gemm_add_silu_f16_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 6720
; TotalNumSgprs: 23
; NumVgprs: 96
; NumAgprs: 0
; TotalNumVgprs: 96
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 11
; NumSGPRsForWavesPerEU: 23
; NumVGPRsForWavesPerEU: 96
; AccumOffset: 96
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 23
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	gemm_f8_full            ; -- Begin function gemm_f8_full
	.globl	gemm_f8_full
	.p2align	8
	.type	gemm_f8_full,@function
gemm_f8_full:                           ; @gemm_f8_full
; %bb.0:                                ; %entry
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	s_lshl_b32 s12, s2, 8
	v_lshrrev_b32_e32 v2, 2, v0
	v_or_b32_e32 v2, s12, v2
	v_lshlrev_b32_e32 v1, 4, v0
	v_lshlrev_b32_e32 v2, 12, v2
	v_mov_b32_e32 v3, 0
	v_and_b32_e32 v20, 48, v1
	v_lshrrev_b32_e32 v26, 4, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	v_mov_b32_e32 v21, v3
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[20:21]
	v_lshlrev_b32_e32 v24, 12, v26
	v_mov_b32_e32 v25, v3
	s_lshl_b32 s0, s3, 8
	s_mov_b32 s1, 0
	global_load_dwordx4 v[12:15], v[4:5], off
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[24:25]
	v_and_b32_e32 v22, 0xf0, v1
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[0:1]
	v_mov_b32_e32 v23, v3
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[22:23]
	global_load_dwordx4 v[16:19], v[4:5], off
	s_movk_i32 s14, 0x80
	v_lshlrev_b32_e32 v21, 1, v0
	v_and_b32_e32 v25, 31, v0
	v_lshrrev_b32_e32 v23, 1, v0
	v_and_or_b32 v119, v21, s14, v25
	s_mov_b32 s13, 0x8000
	v_and_b32_e32 v23, 16, v23
	v_lshlrev_b32_e32 v21, 6, v119
	v_or_b32_e32 v2, v20, v2
	s_add_u32 s6, s6, s0
	v_lshrrev_b32_e32 v118, 7, v0
	v_lshlrev_b32_e32 v28, 6, v25
	v_lshl_or_b32 v25, v22, 6, v26
	v_or3_b32 v122, v23, v21, s13
	v_lshl_add_u64 v[20:21], s[4:5], 0, v[2:3]
	v_or_b32_e32 v2, v24, v22
	s_addc_u32 s7, s7, 0
	s_mov_b64 s[2:3], 0x40000
	v_lshlrev_b32_e32 v27, 11, v118
	v_lshl_add_u64 v[114:115], v[20:21], 0, 64
	v_lshl_add_u64 v[20:21], s[6:7], 0, v[2:3]
	s_mov_b64 s[10:11], 0
	v_mov_b32_e32 v4, v3
	v_mov_b32_e32 v5, v3
	v_mov_b32_e32 v6, v3
	v_mov_b32_e32 v7, v3
	v_mov_b32_e32 v8, v3
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v11, v3
	v_or3_b32 v120, v27, v28, v23
	v_or_b32_e32 v121, 0x8000, v25
	v_mov_b32_e32 v2, v3
	v_lshl_add_u64 v[116:117], v[20:21], 0, s[2:3]
	v_mov_b32_e32 v20, v3
	v_mov_b32_e32 v21, v3
	v_mov_b32_e32 v22, v3
	v_mov_b32_e32 v23, v3
	v_mov_b32_e32 v24, v3
	v_mov_b32_e32 v26, v3
	v_mov_b32_e32 v27, v3
	v_mov_b32_e32 v28, v3
	v_mov_b32_e32 v29, v3
	v_mov_b32_e32 v30, v3
	v_mov_b32_e32 v31, v3
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v33, v3
	v_mov_b32_e32 v34, v3
	v_mov_b32_e32 v35, v3
	v_mov_b32_e32 v36, v3
	v_mov_b32_e32 v37, v3
	v_mov_b32_e32 v38, v3
	v_mov_b32_e32 v39, v3
	v_mov_b32_e32 v40, v3
	v_mov_b32_e32 v41, v3
	v_mov_b32_e32 v42, v3
	v_mov_b32_e32 v43, v3
	v_mov_b32_e32 v44, v3
	v_mov_b32_e32 v45, v3
	v_mov_b32_e32 v46, v3
	v_mov_b32_e32 v47, v3
	v_mov_b32_e32 v48, v3
	v_mov_b32_e32 v49, v3
	v_mov_b32_e32 v50, v3
	v_mov_b32_e32 v51, v3
	s_waitcnt vmcnt(1)
	ds_write_b128 v1, v[12:15]
	s_waitcnt vmcnt(0)
	ds_write_b8 v25, v16 offset:32768
	v_lshrrev_b32_e32 v12, 8, v16
	ds_write_b8_d16_hi v25, v16 offset:32896
	v_lshrrev_b32_e32 v13, 24, v16
	ds_write_b8 v25, v17 offset:33024
	v_lshrrev_b32_e32 v14, 8, v17
	ds_write_b8_d16_hi v25, v17 offset:33152
	v_lshrrev_b32_e32 v15, 24, v17
	ds_write_b8 v25, v18 offset:33280
	v_lshrrev_b32_e32 v16, 8, v18
	ds_write_b8_d16_hi v25, v18 offset:33408
	v_lshrrev_b32_e32 v17, 24, v18
	ds_write_b8 v25, v19 offset:33536
	v_lshrrev_b32_e32 v18, 8, v19
	ds_write_b8_d16_hi v25, v19 offset:33664
	v_lshrrev_b32_e32 v19, 24, v19
	ds_write_b8 v25, v12 offset:32832
	ds_write_b8 v25, v13 offset:32960
	ds_write_b8 v25, v14 offset:33088
	ds_write_b8 v25, v15 offset:33216
	ds_write_b8 v25, v16 offset:33344
	ds_write_b8 v25, v17 offset:33472
	ds_write_b8 v25, v18 offset:33600
	ds_write_b8 v25, v19 offset:33728
	v_mov_b32_e32 v12, v3
	v_mov_b32_e32 v13, v3
	v_mov_b32_e32 v14, v3
	v_mov_b32_e32 v15, v3
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v17, v3
	v_mov_b32_e32 v18, v3
	v_mov_b32_e32 v19, v3
	v_mov_b32_e32 v25, v3
	v_mov_b32_e32 v52, v3
	v_mov_b32_e32 v53, v3
	v_mov_b32_e32 v54, v3
	v_mov_b32_e32 v55, v3
	v_mov_b32_e32 v56, v3
	v_mov_b32_e32 v57, v3
	v_mov_b32_e32 v58, v3
	v_mov_b32_e32 v59, v3
	v_mov_b32_e32 v60, v3
	v_mov_b32_e32 v61, v3
	v_mov_b32_e32 v62, v3
	v_mov_b32_e32 v63, v3
	v_mov_b32_e32 v64, v3
	v_mov_b32_e32 v65, v3
	v_mov_b32_e32 v123, 0x7f
	s_waitcnt lgkmcnt(0)
	s_barrier
                                        ; implicit-def: $vgpr106_vgpr107_vgpr108_vgpr109
                                        ; implicit-def: $vgpr110
	s_branch .LBB2_2
.LBB2_1:                                ; %if.end158.i
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[66:73], v[98:105], v[50:65], v123, v123 op_sel_hi:[0,0,0]
	s_add_u32 s10, s10, 64
	s_addc_u32 s11, s11, 0
	s_add_i32 s1, s1, 1
	s_sub_i32 s4, s10, 64
	v_lshl_add_u64 v[116:117], v[116:117], 0, s[2:3]
	s_cmpk_lt_u32 s4, 0xfc0
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[66:73], v[90:97], v[34:49], v123, v123 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[66:73], v[82:89], v[18:33], v123, v123 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[66:73], v[74:81], v[2:17], v123, v123 op_sel_hi:[0,0,0]
	s_cbranch_scc0 .LBB2_6
.LBB2_2:                                ; %for.body33.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lt_u32 s10, 0xfc0
	s_cselect_b64 s[4:5], -1, 0
	s_cmpk_gt_u32 s10, 0xfbf
	s_cbranch_scc1 .LBB2_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB2_2 Depth=1
	v_lshl_add_u64 v[66:67], v[114:115], 0, s[10:11]
	global_load_dwordx4 v[106:109], v[66:67], off
	global_load_dwordx4 v[110:113], v[116:117], off
.LBB2_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_and_b32 s6, s1, 1
	s_lshl_b32 s7, s6, 14
	v_or_b32_e32 v70, s7, v120
	v_add_u32_e32 v78, s7, v122
	ds_read_b128 v[66:69], v70
	ds_read_b128 v[70:73], v70 offset:32
	ds_read_b128 v[98:101], v78
	ds_read_b128 v[102:105], v78 offset:32
	ds_read_b128 v[90:93], v78 offset:2048
	ds_read_b128 v[94:97], v78 offset:2080
	ds_read_b128 v[82:85], v78 offset:4096
	ds_read_b128 v[86:89], v78 offset:4128
	ds_read_b128 v[74:77], v78 offset:6144
	ds_read_b128 v[78:81], v78 offset:6176
	s_andn2_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB2_1
; %bb.5:                                ; %if.then125.i
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_xor_b32 s4, s6, 1
	s_lshl_b32 s4, s4, 14
	v_or_b32_e32 v124, s4, v1
	s_waitcnt vmcnt(0)
	;;#ASMSTART
	;;#ASMEND
	ds_write_b128 v124, v[106:109]
	v_add_u32_e32 v124, s4, v121
	v_lshrrev_b32_e32 v125, 8, v110
	ds_write_b8 v124, v110
	ds_write_b8 v124, v125 offset:64
	ds_write_b8_d16_hi v124, v110 offset:128
	v_lshrrev_b32_e32 v125, 24, v110
	ds_write_b8 v124, v125 offset:192
	ds_write_b8 v124, v111 offset:256
	v_lshrrev_b32_e32 v125, 8, v111
	ds_write_b8 v124, v125 offset:320
	ds_write_b8_d16_hi v124, v111 offset:384
	v_lshrrev_b32_e32 v125, 24, v111
	ds_write_b8 v124, v125 offset:448
	ds_write_b8 v124, v112 offset:512
	v_lshrrev_b32_e32 v125, 8, v112
	ds_write_b8 v124, v125 offset:576
	ds_write_b8_d16_hi v124, v112 offset:640
	v_lshrrev_b32_e32 v125, 24, v112
	ds_write_b8 v124, v125 offset:704
	ds_write_b8 v124, v113 offset:768
	v_lshrrev_b32_e32 v125, 8, v113
	ds_write_b8 v124, v125 offset:832
	ds_write_b8_d16_hi v124, v113 offset:896
	v_lshrrev_b32_e32 v125, 24, v113
	ds_write_b8 v124, v125 offset:960
	s_branch .LBB2_1
.LBB2_6:                                ; %_Z7full_f8ILb0EEvPKhS1_S1_PDF16_.exit
	v_lshrrev_b32_e32 v0, 3, v0
	v_lshlrev_b32_e32 v1, 5, v118
	v_and_b32_e32 v0, 4, v0
	v_or3_b32 v0, v1, v0, s12
	s_nop 3
	v_cvt_f16_f32_e32 v67, v50
	v_or_b32_e32 v66, s0, v119
	v_lshlrev_b32_e32 v50, 12, v0
	v_add_u32_e32 v0, v50, v66
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v51
	v_or_b32_e32 v51, 0x1000, v50
	v_add_u32_e32 v0, v51, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v52
	v_or_b32_e32 v52, 0x2000, v50
	v_add_u32_e32 v0, v52, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v53
	v_or_b32_e32 v53, 0x3000, v50
	v_add_u32_e32 v0, v53, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v54
	v_or_b32_e32 v54, 0x8000, v50
	v_add_u32_e32 v0, v54, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v55
	v_or_b32_e32 v55, 0x9000, v50
	v_add_u32_e32 v0, v55, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v56
	v_or_b32_e32 v56, 0xa000, v50
	v_add_u32_e32 v0, v56, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v57
	v_or_b32_e32 v57, 0xb000, v50
	v_add_u32_e32 v0, v57, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v58
	v_or_b32_e32 v58, 0x10000, v50
	v_add_u32_e32 v0, v58, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v59
	v_or_b32_e32 v59, 0x11000, v50
	v_add_u32_e32 v0, v59, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v60
	v_or_b32_e32 v60, 0x12000, v50
	v_add_u32_e32 v0, v60, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v61
	v_or_b32_e32 v61, 0x13000, v50
	v_add_u32_e32 v0, v61, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v62
	v_or_b32_e32 v62, 0x18000, v50
	v_add_u32_e32 v0, v62, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v63
	v_or_b32_e32 v63, 0x19000, v50
	v_add_u32_e32 v0, v63, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v64
	v_or_b32_e32 v64, 0x1a000, v50
	v_add_u32_e32 v0, v64, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	global_store_short v[68:69], v67, off
	v_cvt_f16_f32_e32 v67, v65
	v_or_b32_e32 v65, 0x1b000, v50
	v_add_u32_e32 v0, v65, v66
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v34, v34
	global_store_short v[68:69], v67, off
	v_or_b32_e32 v67, 32, v66
	v_cvt_f16_f32_e32 v70, v35
	v_add_u32_e32 v0, v50, v67
	v_cvt_f16_f32_e32 v36, v36
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v51, v67
	v_cvt_f16_f32_e32 v37, v37
	global_store_short v[68:69], v34, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v52, v67
	global_store_short v[34:35], v70, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v53, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v36, v38
	global_store_short v[34:35], v37, off
	v_cvt_f16_f32_e32 v37, v39
	v_add_u32_e32 v0, v54, v67
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v55, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v36, v40
	global_store_short v[34:35], v37, off
	v_cvt_f16_f32_e32 v37, v41
	v_add_u32_e32 v0, v56, v67
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v57, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v36, v42
	global_store_short v[34:35], v37, off
	v_cvt_f16_f32_e32 v37, v43
	v_add_u32_e32 v0, v58, v67
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v59, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v36, v44
	global_store_short v[34:35], v37, off
	v_cvt_f16_f32_e32 v37, v45
	v_add_u32_e32 v0, v60, v67
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v61, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v36, v46
	global_store_short v[34:35], v37, off
	v_cvt_f16_f32_e32 v37, v47
	v_add_u32_e32 v0, v62, v67
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v63, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v36, v48
	global_store_short v[34:35], v37, off
	v_cvt_f16_f32_e32 v37, v49
	v_add_u32_e32 v0, v64, v67
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v65, v67
	global_store_short v[34:35], v36, off
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v18, v18
	global_store_short v[34:35], v37, off
	v_or_b32_e32 v36, 64, v66
	v_cvt_f16_f32_e32 v37, v19
	v_add_u32_e32 v0, v50, v36
	v_cvt_f16_f32_e32 v20, v20
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v51, v36
	v_cvt_f16_f32_e32 v21, v21
	global_store_short v[34:35], v18, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v52, v36
	global_store_short v[18:19], v37, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v53, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v22
	global_store_short v[18:19], v21, off
	v_cvt_f16_f32_e32 v21, v23
	v_add_u32_e32 v0, v54, v36
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v55, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v24
	global_store_short v[18:19], v21, off
	v_cvt_f16_f32_e32 v21, v25
	v_add_u32_e32 v0, v56, v36
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v57, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v26
	global_store_short v[18:19], v21, off
	v_cvt_f16_f32_e32 v21, v27
	v_add_u32_e32 v0, v58, v36
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v59, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v28
	global_store_short v[18:19], v21, off
	v_cvt_f16_f32_e32 v21, v29
	v_add_u32_e32 v0, v60, v36
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v61, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v30
	global_store_short v[18:19], v21, off
	v_cvt_f16_f32_e32 v21, v31
	v_add_u32_e32 v0, v62, v36
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v63, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v20, v32
	global_store_short v[18:19], v21, off
	v_cvt_f16_f32_e32 v21, v33
	v_add_u32_e32 v0, v64, v36
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v65, v36
	global_store_short v[18:19], v20, off
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v2, v2
	global_store_short v[18:19], v21, off
	v_or_b32_e32 v20, 0x60, v66
	v_cvt_f16_f32_e32 v21, v3
	v_add_u32_e32 v0, v50, v20
	v_cvt_f16_f32_e32 v4, v4
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v51, v20
	v_cvt_f16_f32_e32 v5, v5
	global_store_short v[18:19], v2, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v52, v20
	global_store_short v[2:3], v21, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v53, v20
	global_store_short v[2:3], v4, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v6
	global_store_short v[2:3], v5, off
	v_cvt_f16_f32_e32 v5, v7
	v_add_u32_e32 v0, v54, v20
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v55, v20
	global_store_short v[2:3], v4, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v8
	global_store_short v[2:3], v5, off
	v_cvt_f16_f32_e32 v5, v9
	v_add_u32_e32 v0, v56, v20
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v57, v20
	global_store_short v[2:3], v4, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v10
	global_store_short v[2:3], v5, off
	v_cvt_f16_f32_e32 v5, v11
	v_add_u32_e32 v0, v58, v20
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v59, v20
	global_store_short v[2:3], v4, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v12
	global_store_short v[2:3], v5, off
	v_cvt_f16_f32_e32 v5, v13
	v_add_u32_e32 v0, v60, v20
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v61, v20
	global_store_short v[2:3], v4, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_cvt_f16_f32_e32 v4, v14
	global_store_short v[2:3], v5, off
	v_cvt_f16_f32_e32 v5, v15
	v_add_u32_e32 v0, v62, v20
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v63, v20
	global_store_short v[2:3], v4, off
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	global_store_short v[2:3], v5, off
	v_cvt_f16_f32_e32 v4, v16
	v_cvt_f16_f32_e32 v5, v17
	v_add_u32_e32 v0, v64, v20
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[8:9]
	v_add_u32_e32 v0, v65, v20
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[8:9]
	global_store_short v[2:3], v4, off
	global_store_short v[0:1], v5, off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 126
		.amdhsa_next_free_sgpr 15
		.amdhsa_accum_offset 128
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
.Lfunc_end2:
	.size	gemm_f8_full, .Lfunc_end2-gemm_f8_full
                                        ; -- End function
	.set gemm_f8_full.num_vgpr, 126
	.set gemm_f8_full.num_agpr, 0
	.set gemm_f8_full.numbered_sgpr, 15
	.set gemm_f8_full.num_named_barrier, 0
	.set gemm_f8_full.private_seg_size, 0
	.set gemm_f8_full.uses_vcc, 1
	.set gemm_f8_full.uses_flat_scratch, 0
	.set gemm_f8_full.has_dyn_sized_stack, 0
	.set gemm_f8_full.has_recursion, 0
	.set gemm_f8_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2888
; TotalNumSgprs: 21
; NumVgprs: 126
; NumAgprs: 0
; TotalNumVgprs: 126
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 15
; NumSGPRsForWavesPerEU: 21
; NumVGPRsForWavesPerEU: 126
; AccumOffset: 128
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 31
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	gemm_add_silu_f8_full   ; -- Begin function gemm_add_silu_f8_full
	.globl	gemm_add_silu_f8_full
	.p2align	8
	.type	gemm_add_silu_f8_full,@function
gemm_add_silu_f8_full:                  ; @gemm_add_silu_f8_full
; %bb.0:                                ; %entry
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_lshl_b32 s14, s2, 8
	v_lshrrev_b32_e32 v2, 2, v0
	v_or_b32_e32 v2, s14, v2
	v_lshlrev_b32_e32 v1, 4, v0
	v_lshlrev_b32_e32 v2, 12, v2
	v_mov_b32_e32 v3, 0
	v_and_b32_e32 v22, 48, v1
	v_lshrrev_b32_e32 v13, 4, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	v_mov_b32_e32 v23, v3
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[22:23]
	v_lshlrev_b32_e32 v26, 12, v13
	v_mov_b32_e32 v27, v3
	s_lshl_b32 s0, s3, 8
	s_mov_b32 s1, 0
	global_load_dwordx4 v[14:17], v[4:5], off
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[26:27]
	v_and_b32_e32 v24, 0xf0, v1
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[0:1]
	v_mov_b32_e32 v25, v3
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[24:25]
	global_load_dwordx4 v[18:21], v[4:5], off
	s_movk_i32 s16, 0x80
	v_lshlrev_b32_e32 v23, 1, v0
	v_and_b32_e32 v27, 31, v0
	v_lshrrev_b32_e32 v25, 1, v0
	v_and_or_b32 v119, v23, s16, v27
	s_mov_b32 s15, 0x8000
	v_and_b32_e32 v25, 16, v25
	v_lshlrev_b32_e32 v23, 6, v119
	v_or_b32_e32 v2, v22, v2
	s_add_u32 s6, s6, s0
	v_lshrrev_b32_e32 v118, 7, v0
	v_lshl_or_b32 v13, v24, 6, v13
	v_or3_b32 v122, v25, v23, s15
	v_lshl_add_u64 v[22:23], s[4:5], 0, v[2:3]
	v_or_b32_e32 v2, v26, v24
	s_addc_u32 s7, s7, 0
	s_mov_b64 s[2:3], 0x40000
	v_lshlrev_b32_e32 v28, 11, v118
	v_lshlrev_b32_e32 v29, 6, v27
	v_lshl_add_u64 v[114:115], v[22:23], 0, 64
	v_lshl_add_u64 v[22:23], s[6:7], 0, v[2:3]
	s_mov_b64 s[12:13], 0
	v_mov_b32_e32 v4, v3
	v_mov_b32_e32 v5, v3
	v_mov_b32_e32 v6, v3
	v_mov_b32_e32 v7, v3
	v_mov_b32_e32 v8, v3
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v11, v3
	v_mov_b32_e32 v12, v3
	v_or3_b32 v120, v28, v29, v25
	v_or_b32_e32 v121, 0x8000, v13
	v_mov_b32_e32 v2, v3
	v_lshl_add_u64 v[116:117], v[22:23], 0, s[2:3]
	v_mov_b32_e32 v22, v3
	v_mov_b32_e32 v23, v3
	v_mov_b32_e32 v24, v3
	v_mov_b32_e32 v25, v3
	v_mov_b32_e32 v26, v3
	v_mov_b32_e32 v27, v3
	v_mov_b32_e32 v28, v3
	v_mov_b32_e32 v29, v3
	v_mov_b32_e32 v30, v3
	v_mov_b32_e32 v31, v3
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v33, v3
	v_mov_b32_e32 v34, v3
	v_mov_b32_e32 v35, v3
	v_mov_b32_e32 v36, v3
	v_mov_b32_e32 v37, v3
	v_mov_b32_e32 v38, v3
	v_mov_b32_e32 v39, v3
	v_mov_b32_e32 v40, v3
	v_mov_b32_e32 v41, v3
	v_mov_b32_e32 v42, v3
	v_mov_b32_e32 v43, v3
	v_mov_b32_e32 v44, v3
	v_mov_b32_e32 v45, v3
	v_mov_b32_e32 v46, v3
	v_mov_b32_e32 v47, v3
	v_mov_b32_e32 v48, v3
	v_mov_b32_e32 v49, v3
	v_mov_b32_e32 v50, v3
	v_mov_b32_e32 v51, v3
	v_mov_b32_e32 v52, v3
	s_waitcnt vmcnt(1)
	ds_write_b128 v1, v[14:17]
	s_waitcnt vmcnt(0)
	ds_write_b8 v13, v18 offset:32768
	v_lshrrev_b32_e32 v14, 8, v18
	ds_write_b8_d16_hi v13, v18 offset:32896
	v_lshrrev_b32_e32 v15, 24, v18
	ds_write_b8 v13, v19 offset:33024
	v_lshrrev_b32_e32 v16, 8, v19
	ds_write_b8_d16_hi v13, v19 offset:33152
	v_lshrrev_b32_e32 v17, 24, v19
	ds_write_b8 v13, v20 offset:33280
	v_lshrrev_b32_e32 v18, 8, v20
	ds_write_b8_d16_hi v13, v20 offset:33408
	v_lshrrev_b32_e32 v19, 24, v20
	ds_write_b8 v13, v21 offset:33536
	v_lshrrev_b32_e32 v20, 8, v21
	ds_write_b8_d16_hi v13, v21 offset:33664
	v_lshrrev_b32_e32 v21, 24, v21
	ds_write_b8 v13, v14 offset:32832
	ds_write_b8 v13, v15 offset:32960
	ds_write_b8 v13, v16 offset:33088
	ds_write_b8 v13, v17 offset:33216
	ds_write_b8 v13, v18 offset:33344
	ds_write_b8 v13, v19 offset:33472
	ds_write_b8 v13, v20 offset:33600
	ds_write_b8 v13, v21 offset:33728
	v_mov_b32_e32 v13, v3
	v_mov_b32_e32 v14, v3
	v_mov_b32_e32 v15, v3
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v17, v3
	v_mov_b32_e32 v18, v3
	v_mov_b32_e32 v19, v3
	v_mov_b32_e32 v20, v3
	v_mov_b32_e32 v21, v3
	v_mov_b32_e32 v53, v3
	v_mov_b32_e32 v54, v3
	v_mov_b32_e32 v55, v3
	v_mov_b32_e32 v56, v3
	v_mov_b32_e32 v57, v3
	v_mov_b32_e32 v58, v3
	v_mov_b32_e32 v59, v3
	v_mov_b32_e32 v60, v3
	v_mov_b32_e32 v61, v3
	v_mov_b32_e32 v62, v3
	v_mov_b32_e32 v63, v3
	v_mov_b32_e32 v64, v3
	v_mov_b32_e32 v65, v3
	v_mov_b32_e32 v123, 0x7f
	s_waitcnt lgkmcnt(0)
	s_barrier
                                        ; implicit-def: $vgpr106_vgpr107_vgpr108_vgpr109
                                        ; implicit-def: $vgpr110
	s_branch .LBB3_2
.LBB3_1:                                ; %if.end158.i
                                        ;   in Loop: Header=BB3_2 Depth=1
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[66:73], v[98:105], v[50:65], v123, v123 op_sel_hi:[0,0,0]
	s_add_u32 s12, s12, 64
	s_addc_u32 s13, s13, 0
	s_add_i32 s1, s1, 1
	s_sub_i32 s4, s12, 64
	v_lshl_add_u64 v[116:117], v[116:117], 0, s[2:3]
	s_cmpk_lt_u32 s4, 0xfc0
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[66:73], v[90:97], v[34:49], v123, v123 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[66:73], v[82:89], v[18:33], v123, v123 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[66:73], v[74:81], v[2:17], v123, v123 op_sel_hi:[0,0,0]
	s_cbranch_scc0 .LBB3_6
.LBB3_2:                                ; %for.body33.i
                                        ; =>This Inner Loop Header: Depth=1
	s_cmpk_lt_u32 s12, 0xfc0
	s_cselect_b64 s[4:5], -1, 0
	s_cmpk_gt_u32 s12, 0xfbf
	s_cbranch_scc1 .LBB3_4
; %bb.3:                                ; %if.then.i
                                        ;   in Loop: Header=BB3_2 Depth=1
	v_lshl_add_u64 v[66:67], v[114:115], 0, s[12:13]
	global_load_dwordx4 v[106:109], v[66:67], off
	global_load_dwordx4 v[110:113], v[116:117], off
.LBB3_4:                                ; %if.end.i
                                        ;   in Loop: Header=BB3_2 Depth=1
	s_and_b32 s6, s1, 1
	s_lshl_b32 s7, s6, 14
	v_or_b32_e32 v70, s7, v120
	v_add_u32_e32 v78, s7, v122
	ds_read_b128 v[66:69], v70
	ds_read_b128 v[70:73], v70 offset:32
	ds_read_b128 v[98:101], v78
	ds_read_b128 v[102:105], v78 offset:32
	ds_read_b128 v[90:93], v78 offset:2048
	ds_read_b128 v[94:97], v78 offset:2080
	ds_read_b128 v[82:85], v78 offset:4096
	ds_read_b128 v[86:89], v78 offset:4128
	ds_read_b128 v[74:77], v78 offset:6144
	ds_read_b128 v[78:81], v78 offset:6176
	s_andn2_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB3_1
; %bb.5:                                ; %if.then125.i
                                        ;   in Loop: Header=BB3_2 Depth=1
	s_xor_b32 s4, s6, 1
	s_lshl_b32 s4, s4, 14
	v_or_b32_e32 v124, s4, v1
	s_waitcnt vmcnt(0)
	;;#ASMSTART
	;;#ASMEND
	ds_write_b128 v124, v[106:109]
	v_add_u32_e32 v124, s4, v121
	v_lshrrev_b32_e32 v125, 8, v110
	ds_write_b8 v124, v110
	ds_write_b8 v124, v125 offset:64
	ds_write_b8_d16_hi v124, v110 offset:128
	v_lshrrev_b32_e32 v125, 24, v110
	ds_write_b8 v124, v125 offset:192
	ds_write_b8 v124, v111 offset:256
	v_lshrrev_b32_e32 v125, 8, v111
	ds_write_b8 v124, v125 offset:320
	ds_write_b8_d16_hi v124, v111 offset:384
	v_lshrrev_b32_e32 v125, 24, v111
	ds_write_b8 v124, v125 offset:448
	ds_write_b8 v124, v112 offset:512
	v_lshrrev_b32_e32 v125, 8, v112
	ds_write_b8 v124, v125 offset:576
	ds_write_b8_d16_hi v124, v112 offset:640
	v_lshrrev_b32_e32 v125, 24, v112
	ds_write_b8 v124, v125 offset:704
	ds_write_b8 v124, v113 offset:768
	v_lshrrev_b32_e32 v125, 8, v113
	ds_write_b8 v124, v125 offset:832
	ds_write_b8_d16_hi v124, v113 offset:896
	v_lshrrev_b32_e32 v125, 24, v113
	ds_write_b8 v124, v125 offset:960
	s_branch .LBB3_1
.LBB3_6:                                ; %_Z7full_f8ILb1EEvPKhS1_S1_PDF16_.exit
	v_lshrrev_b32_e32 v0, 3, v0
	v_lshlrev_b32_e32 v1, 5, v118
	v_and_b32_e32 v0, 4, v0
	v_or3_b32 v0, v1, v0, s14
	v_or_b32_e32 v66, s0, v119
	v_lshlrev_b32_e32 v67, 12, v0
	v_add_u32_e32 v0, v67, v66
	global_load_ubyte v1, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v1, v1
	v_add_f32_e32 v70, v50, v1
	v_mul_f32_e32 v1, 0xbfb8aa3b, v70
	v_exp_f32_e32 v50, v1
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v50, 1.0, v50
	v_rcp_f32_e32 v71, v50
	v_or_b32_e32 v50, 0x1000, v67
	v_add_u32_e32 v0, v50, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v51, v68
	v_mul_f32_e32 v51, 0xbfb8aa3b, v70
	v_exp_f32_e32 v51, v51
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v51, 1.0, v51
	v_rcp_f32_e32 v71, v51
	v_or_b32_e32 v51, 0x2000, v67
	v_add_u32_e32 v0, v51, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v52, v68
	v_mul_f32_e32 v52, 0xbfb8aa3b, v70
	v_exp_f32_e32 v52, v52
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v52, 1.0, v52
	v_rcp_f32_e32 v71, v52
	v_or_b32_e32 v52, 0x3000, v67
	v_add_u32_e32 v0, v52, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v53, v68
	v_mul_f32_e32 v53, 0xbfb8aa3b, v70
	v_exp_f32_e32 v53, v53
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v53, 1.0, v53
	v_rcp_f32_e32 v71, v53
	v_or_b32_e32 v53, 0x8000, v67
	v_add_u32_e32 v0, v53, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v54, v68
	v_mul_f32_e32 v54, 0xbfb8aa3b, v70
	v_exp_f32_e32 v54, v54
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v54, 1.0, v54
	v_rcp_f32_e32 v71, v54
	v_or_b32_e32 v54, 0x9000, v67
	v_add_u32_e32 v0, v54, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v55, v68
	v_mul_f32_e32 v55, 0xbfb8aa3b, v70
	v_exp_f32_e32 v55, v55
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v55, 1.0, v55
	v_rcp_f32_e32 v71, v55
	v_or_b32_e32 v55, 0xa000, v67
	v_add_u32_e32 v0, v55, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v56, v68
	v_mul_f32_e32 v56, 0xbfb8aa3b, v70
	v_exp_f32_e32 v56, v56
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v56, 1.0, v56
	v_rcp_f32_e32 v71, v56
	v_or_b32_e32 v56, 0xb000, v67
	v_add_u32_e32 v0, v56, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v57, v68
	v_mul_f32_e32 v57, 0xbfb8aa3b, v70
	v_exp_f32_e32 v57, v57
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v57, 1.0, v57
	v_rcp_f32_e32 v71, v57
	v_or_b32_e32 v57, 0x10000, v67
	v_add_u32_e32 v0, v57, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v58, v68
	v_mul_f32_e32 v58, 0xbfb8aa3b, v70
	v_exp_f32_e32 v58, v58
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v58, 1.0, v58
	v_rcp_f32_e32 v71, v58
	v_or_b32_e32 v58, 0x11000, v67
	v_add_u32_e32 v0, v58, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v59, v68
	v_mul_f32_e32 v59, 0xbfb8aa3b, v70
	v_exp_f32_e32 v59, v59
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v59, 1.0, v59
	v_rcp_f32_e32 v71, v59
	v_or_b32_e32 v59, 0x12000, v67
	v_add_u32_e32 v0, v59, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v60, v68
	v_mul_f32_e32 v60, 0xbfb8aa3b, v70
	v_exp_f32_e32 v60, v60
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v60, 1.0, v60
	v_rcp_f32_e32 v71, v60
	v_or_b32_e32 v60, 0x13000, v67
	v_add_u32_e32 v0, v60, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v61, v68
	v_mul_f32_e32 v61, 0xbfb8aa3b, v70
	v_exp_f32_e32 v61, v61
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v61, 1.0, v61
	v_rcp_f32_e32 v71, v61
	v_or_b32_e32 v61, 0x18000, v67
	v_add_u32_e32 v0, v61, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v62, v68
	v_mul_f32_e32 v62, 0xbfb8aa3b, v70
	v_exp_f32_e32 v62, v62
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v62, 1.0, v62
	v_rcp_f32_e32 v71, v62
	v_or_b32_e32 v62, 0x19000, v67
	v_add_u32_e32 v0, v62, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v63, v68
	v_mul_f32_e32 v63, 0xbfb8aa3b, v70
	v_exp_f32_e32 v63, v63
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v63, 1.0, v63
	v_rcp_f32_e32 v71, v63
	v_or_b32_e32 v63, 0x1a000, v67
	v_add_u32_e32 v0, v63, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v70, v64, v68
	v_mul_f32_e32 v64, 0xbfb8aa3b, v70
	v_exp_f32_e32 v64, v64
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_f32_e32 v64, 1.0, v64
	v_rcp_f32_e32 v71, v64
	v_or_b32_e32 v64, 0x1b000, v67
	v_add_u32_e32 v0, v64, v66
	v_fma_mixlo_f16 v70, v70, v71, 0
	global_store_short v[68:69], v70, off
	global_load_ubyte v68, v0, s[8:9]
	v_or_b32_e32 v71, 32, v66
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v68, v68
	v_add_f32_e32 v65, v65, v68
	v_mul_f32_e32 v68, 0xbfb8aa3b, v65
	v_exp_f32_e32 v68, v68
	s_nop 0
	v_add_f32_e32 v68, 1.0, v68
	v_rcp_f32_e32 v70, v68
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v67, v71
	v_fma_mixlo_f16 v65, v65, v70, 0
	global_store_short v[68:69], v65, off
	global_load_ubyte v65, v0, s[8:9]
	v_lshl_add_u64 v[68:69], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v50, v71
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v65, v65
	v_add_f32_e32 v34, v34, v65
	v_mul_f32_e32 v65, 0xbfb8aa3b, v34
	v_exp_f32_e32 v65, v65
	s_nop 0
	v_add_f32_e32 v65, 1.0, v65
	v_rcp_f32_e32 v65, v65
	s_nop 0
	v_fma_mixlo_f16 v34, v34, v65, 0
	global_store_short v[68:69], v34, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v65, v35, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v65
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v68, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v51, v71
	v_fma_mixlo_f16 v65, v65, v68, 0
	global_store_short v[34:35], v65, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v36, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v65, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v52, v71
	v_fma_mixlo_f16 v36, v36, v65, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v37, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v53, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v38, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	v_or_b32_e32 v38, 64, v66
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v54, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v39, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v55, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v40, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v56, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v41, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v57, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v42, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v58, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v43, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v59, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v44, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v60, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v45, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v61, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v46, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v62, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v47, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v63, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v48, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v64, v71
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v36, v49, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v36
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v37, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v67, v38
	v_fma_mixlo_f16 v36, v36, v37, 0
	global_store_short v[34:35], v36, off
	global_load_ubyte v34, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v34, v34
	v_add_f32_e32 v18, v18, v34
	v_mul_f32_e32 v34, 0xbfb8aa3b, v18
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_add_f32_e32 v34, 1.0, v34
	v_rcp_f32_e32 v36, v34
	v_lshl_add_u64 v[34:35], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v50, v38
	v_fma_mixlo_f16 v18, v18, v36, 0
	global_store_short v[34:35], v18, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v34, v19, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v34
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v35, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v51, v38
	v_fma_mixlo_f16 v34, v34, v35, 0
	global_store_short v[18:19], v34, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v20, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v34, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v52, v38
	v_fma_mixlo_f16 v20, v20, v34, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v21, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v53, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v22, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	v_or_b32_e32 v22, 0x60, v66
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v54, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v23, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v55, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v24, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v56, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v25, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v57, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v26, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v58, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v27, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v59, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v28, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v60, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v29, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v61, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v30, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v62, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v31, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v63, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v32, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v64, v38
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v20, v33, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v20
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v67, v22
	v_fma_mixlo_f16 v20, v20, v21, 0
	global_store_short v[18:19], v20, off
	global_load_ubyte v18, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v18, v18
	v_add_f32_e32 v2, v2, v18
	v_mul_f32_e32 v18, 0xbfb8aa3b, v2
	v_exp_f32_e32 v18, v18
	s_nop 0
	v_add_f32_e32 v18, 1.0, v18
	v_rcp_f32_e32 v20, v18
	v_lshl_add_u64 v[18:19], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v50, v22
	v_fma_mixlo_f16 v2, v2, v20, 0
	global_store_short v[18:19], v2, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v18, v3, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v18
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v19, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v51, v22
	v_fma_mixlo_f16 v18, v18, v19, 0
	global_store_short v[2:3], v18, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v4, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v18, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v52, v22
	v_fma_mixlo_f16 v4, v4, v18, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v5, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v53, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v6, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v54, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v7, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v55, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v8, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v56, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v9, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v57, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v10, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v58, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v11, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v59, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v12, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v60, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v13, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v61, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v14, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v62, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v15, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v63, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v4, v16, v2
	v_mul_f32_e32 v2, 0xbfb8aa3b, v4
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_add_f32_e32 v2, 1.0, v2
	v_rcp_f32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[0:1], 1, s[10:11]
	v_add_u32_e32 v0, v64, v22
	v_fma_mixlo_f16 v4, v4, v5, 0
	global_store_short v[2:3], v4, off
	global_load_ubyte v2, v0, s[8:9]
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[10:11]
	s_waitcnt vmcnt(0)
	v_cvt_f32_fp8_e32 v2, v2
	v_add_f32_e32 v2, v17, v2
	v_mul_f32_e32 v3, 0xbfb8aa3b, v2
	v_exp_f32_e32 v3, v3
	s_nop 0
	v_add_f32_e32 v3, 1.0, v3
	v_rcp_f32_e32 v3, v3
	s_nop 0
	v_fma_mixlo_f16 v2, v2, v3, 0
	global_store_short v[0:1], v2, off
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 126
		.amdhsa_next_free_sgpr 17
		.amdhsa_accum_offset 128
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
.Lfunc_end3:
	.size	gemm_add_silu_f8_full, .Lfunc_end3-gemm_add_silu_f8_full
                                        ; -- End function
	.set gemm_add_silu_f8_full.num_vgpr, 126
	.set gemm_add_silu_f8_full.num_agpr, 0
	.set gemm_add_silu_f8_full.numbered_sgpr, 17
	.set gemm_add_silu_f8_full.num_named_barrier, 0
	.set gemm_add_silu_f8_full.private_seg_size, 0
	.set gemm_add_silu_f8_full.uses_vcc, 1
	.set gemm_add_silu_f8_full.uses_flat_scratch, 0
	.set gemm_add_silu_f8_full.has_dyn_sized_stack, 0
	.set gemm_add_silu_f8_full.has_recursion, 0
	.set gemm_add_silu_f8_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5888
; TotalNumSgprs: 23
; NumVgprs: 126
; NumAgprs: 0
; TotalNumVgprs: 126
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 65536 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 15
; NumSGPRsForWavesPerEU: 23
; NumVGPRsForWavesPerEU: 126
; AccumOffset: 128
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 31
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_4f46009fd3dfd0a,@object ; @__hip_cuid_4f46009fd3dfd0a
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_4f46009fd3dfd0a
__hip_cuid_4f46009fd3dfd0a:
	.byte	0                               ; 0x0
	.size	__hip_cuid_4f46009fd3dfd0a, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_4f46009fd3dfd0a
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           a.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           b.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     21
    .sgpr_spill_count: 0
    .symbol:         gemm_f16_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     96
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           a.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           b.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           add.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     23
    .sgpr_spill_count: 0
    .symbol:         gemm_add_silu_f16_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     96
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           a.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           b.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     21
    .sgpr_spill_count: 0
    .symbol:         gemm_f8_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     126
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           a.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           b.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           add.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
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
    .sgpr_count:     23
    .sgpr_spill_count: 0
    .symbol:         gemm_add_silu_f8_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     126
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
