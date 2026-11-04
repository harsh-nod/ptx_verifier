	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	flash_attention_reduced ; -- Begin function flash_attention_reduced
	.globl	flash_attention_reduced
	.p2align	8
	.type	flash_attention_reduced,@function
flash_attention_reduced:                ; @flash_attention_reduced
; %bb.0:                                ; %entry
	s_bitcmp1_b32 s2, 0
	s_cselect_b64 s[4:5], -1, 0
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_17
; %bb.1:                                ; %for.cond.preheader.i
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_lshl_b32 s12, s3, 11
	v_mov_b32_e32 v39, 0
	v_or_b32_e32 v38, s12, v0
	v_lshlrev_b64 v[4:5], 1, v[38:39]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[6:7], 0, v[4:5]
	v_lshl_add_u64 v[4:5], s[8:9], 0, v[4:5]
	global_load_ushort v1, v[2:3], off
	global_load_ushort v6, v[4:5], off
	global_load_ushort v7, v[2:3], off offset:256
	global_load_ushort v8, v[4:5], off offset:256
	global_load_ushort v9, v[2:3], off offset:512
	global_load_ushort v10, v[4:5], off offset:512
	global_load_ushort v11, v[2:3], off offset:768
	global_load_ushort v12, v[4:5], off offset:768
	global_load_ushort v13, v[2:3], off offset:1024
	global_load_ushort v14, v[4:5], off offset:1024
	global_load_ushort v15, v[2:3], off offset:1280
	global_load_ushort v18, v[4:5], off offset:1280
	global_load_ushort v19, v[2:3], off offset:1536
	global_load_ushort v20, v[4:5], off offset:1536
	global_load_ushort v21, v[2:3], off offset:1792
	global_load_ushort v22, v[4:5], off offset:1792
	v_mbcnt_lo_u32_b32 v17, -1, 0
	v_mbcnt_hi_u32_b32 v24, -1, v17
	v_and_b32_e32 v17, 0x70, v24
	v_xor_b32_e32 v25, 8, v24
	v_add_u32_e32 v29, 16, v17
	v_xor_b32_e32 v26, 4, v24
	v_cmp_lt_i32_e32 vcc, v25, v29
	v_xor_b32_e32 v27, 2, v24
	v_xor_b32_e32 v28, 1, v24
	v_cndmask_b32_e32 v25, v24, v25, vcc
	v_cmp_lt_i32_e32 vcc, v26, v29
	v_lshlrev_b32_e32 v59, 1, v0
	v_lshrrev_b32_e32 v23, 6, v0
	v_cndmask_b32_e32 v26, v24, v26, vcc
	v_cmp_lt_i32_e32 vcc, v27, v29
	s_lshl_b32 s2, s2, 6
	v_lshrrev_b32_e32 v16, 2, v0
	v_cndmask_b32_e32 v27, v24, v27, vcc
	v_cmp_lt_i32_e32 vcc, v28, v29
	v_lshl_or_b32 v60, v23, 4, s2
	v_and_b32_e32 v58, 15, v0
	v_and_b32_e32 v61, 12, v16
	v_lshlrev_b32_e32 v0, 5, v0
	v_or_b32_e32 v16, v60, v58
	v_lshlrev_b32_e32 v63, 2, v25
	v_lshlrev_b32_e32 v64, 2, v26
	v_lshlrev_b32_e32 v65, 2, v27
	v_and_b32_e32 v0, 0x1e0, v0
	v_lshlrev_b32_e32 v41, 1, v61
	s_load_dwordx2 s[0:1], s[0:1], 0x20
	v_lshl_add_u32 v36, v16, 6, s12
	v_mov_b32_e32 v16, s4
	v_mov_b32_e32 v17, s5
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
	s_mov_b32 s13, 0
	v_or_b32_e32 v62, 0x1000, v59
	v_lshlrev_b32_e32 v69, 7, v61
	v_lshl_or_b32 v73, v58, 7, v41
	s_mov_b64 s[4:5], -1
	s_mov_b32 s2, 0x5040100
	v_mov_b32_e32 v56, v39
	v_mov_b32_e32 v57, v39
                                        ; implicit-def: $vgpr78
                                        ; implicit-def: $vgpr80
                                        ; implicit-def: $vgpr82
                                        ; implicit-def: $vgpr84
                                        ; implicit-def: $vgpr79
                                        ; implicit-def: $vgpr81
                                        ; implicit-def: $vgpr83
                                        ; implicit-def: $vgpr85
	s_waitcnt vmcnt(15)
	ds_write_b16 v59, v1
	s_waitcnt vmcnt(14)
	ds_write_b16 v59, v6 offset:4096
	s_waitcnt vmcnt(13)
	ds_write_b16 v59, v7 offset:256
	s_waitcnt vmcnt(12)
	ds_write_b16 v59, v8 offset:4352
	s_waitcnt vmcnt(11)
	ds_write_b16 v59, v9 offset:512
	s_waitcnt vmcnt(10)
	ds_write_b16 v59, v10 offset:4608
	s_waitcnt vmcnt(9)
	ds_write_b16 v59, v11 offset:768
	s_waitcnt vmcnt(8)
	ds_write_b16 v59, v12 offset:4864
	s_waitcnt vmcnt(7)
	ds_write_b16 v59, v13 offset:1024
	s_waitcnt vmcnt(6)
	ds_write_b16 v59, v14 offset:5120
	s_waitcnt vmcnt(5)
	ds_write_b16 v59, v15 offset:1280
	s_waitcnt vmcnt(4)
	ds_write_b16 v59, v18 offset:5376
	s_waitcnt vmcnt(3)
	ds_write_b16 v59, v19 offset:1536
	s_waitcnt vmcnt(2)
	ds_write_b16 v59, v20 offset:5632
	s_waitcnt vmcnt(1)
	ds_write_b16 v59, v21 offset:1792
	s_waitcnt vmcnt(0)
	ds_write_b16 v59, v22 offset:5888
	v_cndmask_b32_e32 v1, v24, v28, vcc
	v_or_b32_e32 v18, 0x600, v38
	v_mov_b32_e32 v19, v39
	v_lshlrev_b32_e32 v66, 2, v1
	v_mov_b32_e32 v1, 0x2000
	v_lshlrev_b64 v[18:19], 1, v[18:19]
	v_lshl_or_b32 v1, v23, 9, v1
	v_lshl_add_u64 v[20:21], s[6:7], 0, v[18:19]
	v_lshl_add_u64 v[22:23], s[8:9], 0, v[18:19]
	v_or_b32_e32 v18, 0x680, v38
	v_mov_b32_e32 v19, v39
	v_lshlrev_b64 v[18:19], 1, v[18:19]
	v_lshl_add_u64 v[24:25], s[6:7], 0, v[18:19]
	v_lshl_add_u64 v[26:27], s[8:9], 0, v[18:19]
	v_or_b32_e32 v18, 0x700, v38
	v_mov_b32_e32 v19, v39
	v_or3_b32 v67, v1, v0, v41
	v_or_b32_e32 v0, 0x480, v38
	v_or_b32_e32 v8, 0x500, v38
	v_or_b32_e32 v12, 0x580, v38
	v_lshlrev_b64 v[18:19], 1, v[18:19]
	v_or_b32_e32 v38, 0x780, v38
	v_lshlrev_b32_e32 v6, 1, v58
	v_lshl_add_u64 v[28:29], s[6:7], 0, v[18:19]
	v_lshl_add_u64 v[30:31], s[8:9], 0, v[18:19]
	v_lshlrev_b64 v[18:19], 1, v[38:39]
	v_or_b32_e32 v38, v36, v61
	v_or_b32_e32 v40, v1, v6
	v_mov_b32_e32 v1, v39
	v_mov_b32_e32 v9, v39
	v_mov_b32_e32 v13, v39
	v_lshl_add_u64 v[32:33], s[6:7], 0, v[18:19]
	v_lshl_add_u64 v[34:35], s[8:9], 0, v[18:19]
	v_lshl_add_u64 v[36:37], v[38:39], 1, v[16:17]
	v_or_b32_e32 v16, 1, v61
	v_or_b32_e32 v17, 2, v61
	v_or_b32_e32 v18, 3, v61
	v_or_b32_e32 v68, 0x1000, v6
	v_lshlrev_b64 v[6:7], 1, v[0:1]
	v_lshlrev_b64 v[10:11], 1, v[8:9]
	v_lshlrev_b64 v[14:15], 1, v[12:13]
	v_lshlrev_b32_e32 v19, 5, v61
	v_lshlrev_b32_e32 v38, 5, v16
	v_lshlrev_b32_e32 v42, 5, v17
	v_lshlrev_b32_e32 v43, 5, v18
	v_lshl_add_u64 v[0:1], s[6:7], 0, v[6:7]
	v_lshl_add_u64 v[6:7], s[8:9], 0, v[6:7]
	v_lshl_add_u64 v[8:9], s[6:7], 0, v[10:11]
	v_lshl_add_u64 v[10:11], s[8:9], 0, v[10:11]
	v_lshl_add_u64 v[12:13], s[6:7], 0, v[14:15]
	v_lshl_add_u64 v[14:15], s[8:9], 0, v[14:15]
	v_lshlrev_b32_e32 v70, 7, v16
	v_lshlrev_b32_e32 v71, 7, v17
	v_lshlrev_b32_e32 v72, 7, v18
	s_mov_b32 s8, 0x3e000000
	v_add_u32_e32 v74, v40, v19
	v_add_u32_e32 v75, v40, v38
	v_add_u32_e32 v76, v40, v42
	v_add_u32_e32 v77, v40, v43
	v_mov_b32_e32 v18, v39
	v_mov_b32_e32 v19, v39
	v_mov_b32_e32 v16, v39
	v_mov_b32_e32 v17, v39
	v_mov_b32_e32 v38, v39
	s_waitcnt lgkmcnt(0)
	s_barrier
.LBB0_2:                                ; %for.body27.i
                                        ; =>This Inner Loop Header: Depth=1
	s_xor_b64 s[6:7], s[4:5], -1
	v_accvgpr_read_b32 v41, a15
	v_accvgpr_read_b32 v40, a14
	v_accvgpr_read_b32 v47, a13
	v_accvgpr_read_b32 v46, a12
	v_accvgpr_read_b32 v43, a11
	v_accvgpr_read_b32 v42, a10
	v_accvgpr_read_b32 v51, a9
	v_accvgpr_read_b32 v50, a8
	v_accvgpr_read_b32 v45, a7
	v_accvgpr_read_b32 v44, a6
	v_accvgpr_read_b32 v53, a5
	v_accvgpr_read_b32 v52, a4
	v_accvgpr_read_b32 v49, a3
	v_accvgpr_read_b32 v48, a2
	v_accvgpr_read_b32 v55, a1
	v_accvgpr_read_b32 v54, a0
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccnz .LBB0_4
; %bb.3:                                ; %for.body35.preheader.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	global_load_ushort v78, v[2:3], off offset:2048
	global_load_ushort v79, v[4:5], off offset:2048
	global_load_ushort v80, v[0:1], off
	global_load_ushort v81, v[6:7], off
	global_load_ushort v82, v[8:9], off
	global_load_ushort v83, v[10:11], off
	global_load_ushort v84, v[12:13], off
	global_load_ushort v85, v[14:15], off
	global_load_ushort v86, v[22:23], off
	global_load_ushort v87, v[26:27], off
	global_load_ushort v88, v[30:31], off
	global_load_ushort v89, v[34:35], off
	global_load_ushort v90, v[20:21], off
	global_load_ushort v91, v[24:25], off
	global_load_ushort v92, v[28:29], off
	global_load_ushort v93, v[32:33], off
	s_waitcnt vmcnt(13)
	v_perm_b32 v78, v80, v78, s2
	s_waitcnt vmcnt(12)
	v_perm_b32 v79, v81, v79, s2
	s_waitcnt vmcnt(9)
	v_perm_b32 v80, v84, v82, s2
	s_waitcnt vmcnt(8)
	v_perm_b32 v81, v85, v83, s2
	s_waitcnt vmcnt(6)
	v_perm_b32 v83, v87, v86, s2
	s_waitcnt vmcnt(4)
	v_perm_b32 v85, v89, v88, s2
	s_waitcnt vmcnt(2)
	v_perm_b32 v82, v91, v90, s2
	s_waitcnt vmcnt(0)
	v_perm_b32 v84, v93, v92, s2
.LBB0_4:                                ; %if.end51.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	global_load_dwordx2 v[90:91], v[36:37], off
	global_load_dwordx2 v[92:93], v[36:37], off offset:32
	global_load_dwordx2 v[94:95], v[36:37], off offset:64
	global_load_dwordx2 v[96:97], v[36:37], off offset:96
	s_lshl_b32 s9, s13, 1
	v_add_u32_e32 v98, s9, v73
	ds_read2_b64 v[86:89], v98 offset1:4
	s_andn2_b64 vcc, exec, s[4:5]
	s_waitcnt vmcnt(3) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[90:91], v[86:87], 0
	s_waitcnt vmcnt(2)
	v_mfma_f32_16x16x16_f16 a[0:3], v[92:93], v[88:89], a[0:3]
	ds_read2_b64 v[86:89], v98 offset0:8 offset1:12
	s_waitcnt vmcnt(1) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[94:95], v[86:87], a[0:3]
	v_add_u32_e32 v86, s9, v68
	v_add_u32_e32 v108, v86, v69
	v_add_u32_e32 v109, v86, v70
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[96:97], v[88:89], a[0:3]
	v_add_u32_e32 v110, v86, v71
	v_add_u32_e32 v111, v86, v72
	s_nop 5
	v_accvgpr_read_b32 v94, a0
	v_accvgpr_read_b32 v95, a1
	v_accvgpr_read_b32 v96, a2
	v_accvgpr_read_b32 v97, a3
	v_mul_f32_e32 v87, 0x3e000000, v94
	v_mul_f32_e32 v88, 0x3e000000, v95
	v_mul_f32_e32 v89, 0x3e000000, v96
	v_mul_f32_e32 v90, 0x3e000000, v97
	ds_bpermute_b32 v91, v63, v87
	ds_bpermute_b32 v92, v63, v88
	ds_bpermute_b32 v93, v63, v89
	ds_bpermute_b32 v98, v63, v90
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v87, v87, v91
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v88, v88, v92
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v89, v89, v93
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v90, v90, v98
	ds_bpermute_b32 v91, v64, v87
	ds_bpermute_b32 v92, v64, v88
	ds_bpermute_b32 v93, v64, v89
	ds_bpermute_b32 v98, v64, v90
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v87, v87, v91
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v88, v88, v92
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v89, v89, v93
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v90, v90, v98
	ds_bpermute_b32 v91, v65, v87
	ds_bpermute_b32 v92, v65, v88
	ds_bpermute_b32 v93, v65, v89
	ds_bpermute_b32 v98, v65, v90
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v87, v87, v91
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v88, v88, v92
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v89, v89, v93
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v90, v90, v98
	ds_bpermute_b32 v91, v66, v87
	ds_bpermute_b32 v92, v66, v88
	ds_bpermute_b32 v93, v66, v89
	ds_bpermute_b32 v98, v66, v90
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v91, v87, v91
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v92, v88, v92
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v93, v89, v93
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v98, v90, v98
	v_max_f32_e32 v89, v39, v91
	v_max_f32_e32 v88, v38, v92
	v_max_f32_e32 v87, v56, v93
	v_max_f32_e32 v86, v57, v98
	v_cndmask_b32_e64 v90, v89, v91, s[4:5]
	v_cndmask_b32_e64 v91, v88, v92, s[4:5]
	v_cndmask_b32_e64 v92, v87, v93, s[4:5]
	v_cndmask_b32_e64 v93, v86, v98, s[4:5]
	v_fma_f32 v94, v94, s8, -v90
	v_fma_f32 v95, v95, s8, -v91
	v_fma_f32 v96, v96, s8, -v92
	v_fma_f32 v97, v97, s8, -v93
	v_mul_f32_e32 v94, 0x3fb8aa3b, v94
	v_mul_f32_e32 v95, 0x3fb8aa3b, v95
	v_mul_f32_e32 v96, 0x3fb8aa3b, v96
	v_mul_f32_e32 v97, 0x3fb8aa3b, v97
	v_sub_f32_e32 v39, v39, v90
	v_sub_f32_e32 v38, v38, v91
	v_exp_f32_e32 v100, v94
	v_exp_f32_e32 v101, v95
	v_exp_f32_e32 v102, v96
	v_exp_f32_e32 v103, v97
	v_sub_f32_e32 v56, v56, v92
	v_sub_f32_e32 v57, v57, v93
	v_mul_f32_e32 v39, 0x3fb8aa3b, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v38
	v_mul_f32_e32 v56, 0x3fb8aa3b, v56
	v_mul_f32_e32 v57, 0x3fb8aa3b, v57
	v_exp_f32_e32 v94, v39
	v_exp_f32_e32 v38, v38
	v_exp_f32_e32 v56, v56
	v_exp_f32_e32 v57, v57
	ds_bpermute_b32 v104, v63, v100
	ds_bpermute_b32 v105, v63, v101
	ds_bpermute_b32 v106, v63, v102
	ds_bpermute_b32 v107, v63, v103
	v_cvt_f16_f32_e32 v112, v100
	v_cvt_f16_f32_e32 v113, v101
	v_cndmask_b32_e64 v39, v38, 0, s[4:5]
	v_cndmask_b32_e64 v38, v94, 0, s[4:5]
	v_cvt_f16_f32_e32 v114, v102
	v_cndmask_b32_e64 v57, v57, 0, s[4:5]
	v_cndmask_b32_e64 v56, v56, 0, s[4:5]
	v_pk_mul_f32 v[94:95], v[38:39], v[54:55]
	v_pk_mul_f32 v[52:53], v[38:39], v[52:53]
	v_cvt_f16_f32_e32 v115, v103
	v_pk_mul_f32 v[96:97], v[56:57], v[48:49]
	v_pk_mul_f32 v[54:55], v[56:57], v[44:45]
	v_accvgpr_write_b32 a0, v94
	v_accvgpr_write_b32 a4, v52
	v_accvgpr_write_b32 a1, v95
	v_accvgpr_write_b32 a2, v96
	v_accvgpr_write_b32 a3, v97
	v_accvgpr_write_b32 a5, v53
	v_accvgpr_write_b32 a6, v54
	v_accvgpr_write_b32 a7, v55
	ds_write_b16 v74, v112
	ds_write_b16 v75, v113
	ds_write_b16 v76, v114
	ds_write_b16 v77, v115
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64 v[48:49], v67
	ds_read_u16 v52, v108
	ds_read_u16 v95, v108 offset:32
	ds_read_u16 v96, v109
	ds_read_u16 v112, v109 offset:32
	ds_read_u16 v113, v108 offset:64
	ds_read_u16 v114, v109 offset:64
	ds_read_u16 v108, v108 offset:96
	ds_read_u16 v53, v110
	ds_read_u16 v97, v110 offset:32
	ds_read_u16 v115, v111
	ds_read_u16 v116, v111 offset:32
	ds_read_u16 v117, v110 offset:64
	ds_read_u16 v118, v111 offset:64
	ds_read_u16 v110, v110 offset:96
	ds_read_u16 v109, v109 offset:96
	ds_read_u16 v111, v111 offset:96
	v_pk_add_f32 v[44:45], v[100:101], v[104:105]
	v_pk_add_f32 v[54:55], v[102:103], v[106:107]
	v_pk_mul_f32 v[98:99], v[38:39], v[46:47]
	ds_bpermute_b32 v46, v64, v44
	ds_bpermute_b32 v47, v64, v45
	ds_bpermute_b32 v94, v64, v54
	s_waitcnt lgkmcnt(14)
	v_perm_b32 v52, v96, v52, s2
	v_perm_b32 v96, v112, v95, s2
	ds_bpermute_b32 v95, v64, v55
	v_pk_mul_f32 v[50:51], v[38:39], v[50:51]
	s_waitcnt lgkmcnt(10)
	v_perm_b32 v53, v115, v53, s2
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[44:45], v[44:45], v[46:47]
	ds_bpermute_b32 v46, v65, v44
	v_mfma_f32_16x16x16_f16 a[0:3], v[48:49], v[52:53], a[0:3]
	v_mul_f32_e64 v52, v56, v42
	v_mul_f32_e64 v53, v57, v43
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[42:43], v[54:55], v[94:95]
	v_accvgpr_write_b32 a8, v50
	ds_bpermute_b32 v47, v65, v45
	v_accvgpr_write_b32 a9, v51
	v_accvgpr_write_b32 a10, v52
	v_accvgpr_write_b32 a11, v53
	ds_bpermute_b32 v50, v65, v42
	ds_bpermute_b32 v51, v65, v43
	v_perm_b32 v101, v118, v117, s2
	v_perm_b32 v100, v114, v113, s2
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[44:45], v[44:45], v[46:47]
	v_perm_b32 v97, v116, v97, s2
	v_mfma_f32_16x16x16_f16 a[8:11], v[48:49], v[100:101], a[8:11]
	v_mul_f32_e64 v100, v56, v40
	v_mul_f32_e64 v101, v57, v41
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[40:41], v[42:43], v[50:51]
	v_accvgpr_write_b32 a12, v98
	v_perm_b32 v103, v111, v110, s2
	v_perm_b32 v102, v109, v108, s2
	ds_bpermute_b32 v46, v66, v44
	ds_bpermute_b32 v47, v66, v45
	v_accvgpr_write_b32 a13, v99
	v_accvgpr_write_b32 a14, v100
	v_accvgpr_write_b32 a15, v101
	ds_bpermute_b32 v42, v66, v40
	ds_bpermute_b32 v43, v66, v41
	v_mfma_f32_16x16x16_f16 a[4:7], v[48:49], v[96:97], a[4:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_f32_16x16x16_f16 a[12:15], v[48:49], v[102:103], a[12:15]
	s_cbranch_vccnz .LBB0_6
; %bb.5:                                ; %for.body199.preheader.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	ds_write_b16 v59, v78 offset:2048
	ds_write_b16 v62, v79 offset:2048
	ds_write_b16_d16_hi v59, v78 offset:2304
	ds_write_b16_d16_hi v62, v79 offset:2304
	ds_write_b16 v59, v80 offset:2560
	ds_write_b16 v62, v81 offset:2560
	ds_write_b16_d16_hi v59, v80 offset:2816
	ds_write_b16_d16_hi v62, v81 offset:2816
	ds_write_b16 v59, v82 offset:3072
	ds_write_b16 v62, v83 offset:3072
	ds_write_b16_d16_hi v59, v82 offset:3328
	ds_write_b16_d16_hi v62, v83 offset:3328
	ds_write_b16 v59, v84 offset:3584
	ds_write_b16 v62, v85 offset:3584
	ds_write_b16_d16_hi v59, v84 offset:3840
	ds_write_b16_d16_hi v62, v85 offset:3840
.LBB0_6:                                ; %if.end214.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_pk_fma_f32 v[18:19], v[38:39], v[18:19], v[46:47]
	v_pk_fma_f32 v[16:17], v[56:57], v[16:17], v[42:43]
	v_pk_add_f32 v[18:19], v[18:19], v[44:45]
	v_pk_add_f32 v[16:17], v[16:17], v[40:41]
	s_movk_i32 s13, 0x400
	s_mov_b64 s[4:5], 0
	s_and_b64 vcc, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccnz .LBB0_8
; %bb.7:                                ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v39, v90
	v_mov_b32_e32 v38, v91
	v_mov_b32_e32 v56, v92
	v_mov_b32_e32 v57, v93
	s_branch .LBB0_2
.LBB0_8:                                ; %for.cond219.preheader.i
	v_rcp_f32_e32 v26, v18
	v_accvgpr_read_b32 v11, a7
	v_accvgpr_read_b32 v15, a3
	v_or_b32_e32 v22, v60, v61
	v_or_b32_e32 v23, s12, v58
	v_accvgpr_read_b32 v0, a12
	v_accvgpr_read_b32 v4, a8
	v_accvgpr_read_b32 v8, a4
	v_accvgpr_read_b32 v12, a0
	v_lshl_add_u32 v20, v22, 6, v23
	v_mov_b32_e32 v21, 0
	v_accvgpr_read_b32 v1, a13
	v_accvgpr_read_b32 v2, a14
	v_accvgpr_read_b32 v3, a15
	v_accvgpr_read_b32 v5, a9
	v_accvgpr_read_b32 v6, a10
	v_accvgpr_read_b32 v7, a11
	v_accvgpr_read_b32 v10, a6
	v_accvgpr_read_b32 v9, a5
	v_accvgpr_read_b32 v14, a2
	v_accvgpr_read_b32 v13, a1
	s_lshl_b32 s4, s3, 5
	v_cmp_eq_u32_e32 vcc, 0, v58
	v_fma_mixlo_f16 v12, v26, v12, 0
	v_lshl_add_u64 v[24:25], v[20:21], 1, s[10:11]
	v_fma_mixlo_f16 v8, v26, v8, 0
	v_fma_mixlo_f16 v4, v26, v4, 0
	v_fma_mixlo_f16 v0, v26, v0, 0
	global_store_short v[24:25], v12, off
	global_store_short v[24:25], v8, off offset:32
	global_store_short v[24:25], v4, off offset:64
	global_store_short v[24:25], v0, off offset:96
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_10
; %bb.9:                                ; %if.then252.i
	v_log_f32_e32 v0, v18
	v_add_u32_e32 v20, s4, v22
	v_lshl_add_u64 v[24:25], v[20:21], 2, s[0:1]
	v_fmamk_f32 v0, v0, 0x3f317218, v89
	global_store_dword v[24:25], v0, off
.LBB0_10:                               ; %if.end261.i
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v4, v19
	v_or_b32_e32 v0, 1, v22
	v_lshl_add_u32 v20, v0, 6, v23
	v_lshl_add_u64 v[20:21], v[20:21], 1, s[10:11]
	v_fma_mixlo_f16 v8, v4, v13, 0
	global_store_short v[20:21], v8, off
	v_fma_mixlo_f16 v8, v4, v9, 0
	v_fma_mixlo_f16 v5, v4, v5, 0
	v_fma_mixlo_f16 v1, v4, v1, 0
	global_store_short v[20:21], v8, off offset:32
	global_store_short v[20:21], v5, off offset:64
	global_store_short v[20:21], v1, off offset:96
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_12
; %bb.11:                               ; %if.then252.1.i
	v_log_f32_e32 v4, v19
	v_add_u32_e32 v0, s4, v0
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[0:1], v[0:1], 2, s[0:1]
	v_fmamk_f32 v4, v4, 0x3f317218, v88
	global_store_dword v[0:1], v4, off
.LBB0_12:                               ; %if.end261.1.i
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v5, v16
	v_or_b32_e32 v4, 2, v22
	v_mov_b32_e32 v1, 0
	v_lshl_add_u32 v0, v4, 6, v23
	v_lshl_add_u64 v[8:9], v[0:1], 1, s[10:11]
	v_fma_mixlo_f16 v0, v5, v10, 0
	global_store_short v[8:9], v0, off offset:32
	v_fma_mixlo_f16 v0, v5, v6, 0
	v_fma_mixlo_f16 v12, v5, v14, 0
	global_store_short v[8:9], v0, off offset:64
	v_fma_mixlo_f16 v0, v5, v2, 0
	global_store_short v[8:9], v12, off
	global_store_short v[8:9], v0, off offset:96
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_14
; %bb.13:                               ; %if.then252.2.i
	v_log_f32_e32 v2, v16
	v_add_u32_e32 v0, s4, v4
	v_lshl_add_u64 v[4:5], v[0:1], 2, s[0:1]
	v_fmamk_f32 v2, v2, 0x3f317218, v87
	global_store_dword v[4:5], v2, off
.LBB0_14:                               ; %if.end261.2.i
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v4, v17
	v_or_b32_e32 v2, 3, v22
	v_lshl_add_u32 v0, v2, 6, v23
	v_lshl_add_u64 v[0:1], v[0:1], 1, s[10:11]
	v_fma_mixlo_f16 v5, v4, v15, 0
	global_store_short v[0:1], v5, off
	v_fma_mixlo_f16 v5, v4, v11, 0
	global_store_short v[0:1], v5, off offset:32
	v_fma_mixlo_f16 v5, v4, v7, 0
	v_fma_mixlo_f16 v3, v4, v3, 0
	global_store_short v[0:1], v5, off offset:64
	global_store_short v[0:1], v3, off offset:96
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_16
; %bb.15:                               ; %if.then252.3.i
	v_log_f32_e32 v3, v17
	v_add_u32_e32 v0, s4, v2
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[0:1], v[0:1], 2, s[0:1]
	v_fmamk_f32 v2, v3, 0x3f317218, v86
	global_store_dword v[0:1], v2, off
.LBB0_16:                               ; %if.end261.3.i
	s_or_b64 exec, exec, s[2:3]
	s_barrier
.LBB0_17:                               ; %_Z9attentionILj32ELj1EEvPKDF16_S1_S1_PDF16_PfS2_S2_S2_.exit
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel flash_attention_reduced
		.amdhsa_group_segment_fixed_size 9216
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
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 136
		.amdhsa_next_free_sgpr 14
		.amdhsa_accum_offset 120
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
	.size	flash_attention_reduced, .Lfunc_end0-flash_attention_reduced
                                        ; -- End function
	.set flash_attention_reduced.num_vgpr, 119
	.set flash_attention_reduced.num_agpr, 16
	.set flash_attention_reduced.numbered_sgpr, 14
	.set flash_attention_reduced.num_named_barrier, 0
	.set flash_attention_reduced.private_seg_size, 0
	.set flash_attention_reduced.uses_vcc, 1
	.set flash_attention_reduced.uses_flat_scratch, 0
	.set flash_attention_reduced.has_dyn_sized_stack, 0
	.set flash_attention_reduced.has_recursion, 0
	.set flash_attention_reduced.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3760
; TotalNumSgprs: 20
; NumVgprs: 119
; NumAgprs: 16
; TotalNumVgprs: 136
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 9216 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 16
; NumSGPRsForWavesPerEU: 20
; NumVGPRsForWavesPerEU: 136
; AccumOffset: 120
; Occupancy: 3
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 29
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	flash_attention_full    ; -- Begin function flash_attention_full
	.globl	flash_attention_full
	.p2align	8
	.type	flash_attention_full,@function
flash_attention_full:                   ; @flash_attention_full
; %bb.0:                                ; %entry
	s_bitcmp1_b32 s2, 0
	s_cselect_b64 s[4:5], -1, 0
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB1_18
; %bb.1:                                ; %for.cond.preheader.i
	v_lshrrev_b32_e32 v3, 2, v0
	v_and_b32_e32 v38, 12, v3
	v_mbcnt_lo_u32_b32 v3, -1, 0
	v_mbcnt_hi_u32_b32 v3, -1, v3
	v_and_b32_e32 v4, 0x70, v3
	v_add_u32_e32 v4, 16, v4
	v_xor_b32_e32 v5, 8, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx2 s[12:13], s[0:1], 0x20
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v40, 2, v5
	v_xor_b32_e32 v5, 4, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_lshl_b32 s15, s3, 16
	v_lshrrev_b32_e32 v2, 6, v0
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v41, 2, v5
	v_xor_b32_e32 v5, 2, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_lshl_b32 s0, s2, 6
	v_and_b32_e32 v39, 15, v0
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v42, 2, v5
	v_xor_b32_e32 v5, 1, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	v_mov_b32_e32 v21, 0
	v_lshl_or_b32 v1, v2, 4, s0
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_lshlrev_b32_e32 v43, 2, v3
	v_mov_b32_e32 v3, 0x2000
	v_lshlrev_b32_e32 v5, 5, v0
	v_lshl_or_b32 v2, v2, 9, v3
	v_lshlrev_b32_e32 v3, 1, v39
	v_and_b32_e32 v5, 0x1e0, v5
	v_lshlrev_b32_e32 v6, 1, v38
	v_or_b32_e32 v18, s15, v0
	v_mov_b32_e32 v19, v21
	v_or_b32_e32 v4, v2, v3
	v_or3_b32 v44, v2, v5, v6
	v_or_b32_e32 v45, 0x1000, v3
	v_lshlrev_b64 v[2:3], 1, v[18:19]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[22:23], s[6:7], 0, v[2:3]
	v_lshl_add_u64 v[24:25], s[8:9], 0, v[2:3]
	v_or_b32_e32 v2, 1, v38
	v_or_b32_e32 v3, 2, v38
	v_or_b32_e32 v5, 3, v38
	v_lshlrev_b32_e32 v19, 1, v0
	v_lshlrev_b32_e32 v7, 5, v38
	v_lshlrev_b32_e32 v8, 5, v2
	v_lshlrev_b32_e32 v9, 5, v3
	v_lshlrev_b32_e32 v10, 5, v5
	s_lshl_b32 s14, s3, 10
	s_mov_b32 s16, 0
	v_or_b32_e32 v46, s15, v39
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
	v_or_b32_e32 v47, 0x1000, v19
	v_lshlrev_b32_e32 v48, 7, v38
	v_lshlrev_b32_e32 v49, 7, v2
	v_lshlrev_b32_e32 v50, 7, v3
	v_lshlrev_b32_e32 v51, 7, v5
	v_lshl_or_b32 v52, v39, 7, v6
	s_mov_b32 s17, 0x5040100
	s_mov_b32 s18, 0x3e000000
	v_add_u32_e32 v53, v4, v7
	v_add_u32_e32 v54, v4, v8
	v_add_u32_e32 v55, v4, v9
	v_add_u32_e32 v56, v4, v10
                                        ; implicit-def: $vgpr57
                                        ; implicit-def: $vgpr59
                                        ; implicit-def: $vgpr60
                                        ; implicit-def: $vgpr62
                                        ; implicit-def: $vgpr58
                                        ; implicit-def: $vgpr61
                                        ; implicit-def: $vgpr63
                                        ; implicit-def: $vgpr64
	s_branch .LBB1_3
.LBB1_2:                                ; %if.end261.3.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	s_or_b64 exec, exec, s[2:3]
	s_add_i32 s16, s16, 1
	s_cmp_lg_u32 s16, 4
	s_barrier
	s_cbranch_scc0 .LBB1_18
.LBB1_3:                                ; %for.body.i
                                        ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_4 Depth 2
	global_load_ushort v2, v[22:23], off
	v_lshl_add_u32 v65, s16, 5, v1
	s_mov_b32 s19, 0
	v_mov_b32_e32 v34, v21
	v_mov_b32_e32 v35, v21
	v_mov_b32_e32 v36, v21
	v_mov_b32_e32 v37, v21
	v_mov_b32_e32 v28, v21
	v_mov_b32_e32 v29, v21
	v_mov_b32_e32 v26, v21
	v_mov_b32_e32 v27, v21
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
	ds_write_b16 v19, v2
	global_load_ushort v2, v[24:25], off
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2
	global_load_ushort v2, v[22:23], off offset:256
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:256
	global_load_ushort v2, v[24:25], off offset:256
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:256
	global_load_ushort v2, v[22:23], off offset:512
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:512
	global_load_ushort v2, v[24:25], off offset:512
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:512
	global_load_ushort v2, v[22:23], off offset:768
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:768
	global_load_ushort v2, v[24:25], off offset:768
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:768
	global_load_ushort v2, v[22:23], off offset:1024
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:1024
	global_load_ushort v2, v[24:25], off offset:1024
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1024
	global_load_ushort v2, v[22:23], off offset:1280
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:1280
	global_load_ushort v2, v[24:25], off offset:1280
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1280
	global_load_ushort v2, v[22:23], off offset:1536
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:1536
	global_load_ushort v2, v[24:25], off offset:1536
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1536
	global_load_ushort v2, v[22:23], off offset:1792
	s_waitcnt vmcnt(0)
	ds_write_b16 v19, v2 offset:1792
	global_load_ushort v2, v[24:25], off offset:1792
	s_waitcnt vmcnt(0)
	ds_write_b16 v47, v2 offset:1792
	v_or_b32_e32 v2, v65, v39
	v_lshl_add_u32 v4, v2, 6, s15
	v_or_b32_e32 v20, v4, v38
	v_lshl_add_u64 v[2:3], v[20:21], 1, s[4:5]
	v_add_u32_e32 v20, v4, v38
	v_lshl_add_u64 v[4:5], v[20:21], 1, s[4:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
.LBB1_4:                                ; %for.body27.i
                                        ;   Parent Loop BB1_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_cmpk_lg_u32 s19, 0xfc00
	v_accvgpr_read_b32 v7, a15
	v_accvgpr_read_b32 v6, a14
	v_accvgpr_read_b32 v13, a13
	v_accvgpr_read_b32 v12, a12
	v_accvgpr_read_b32 v9, a11
	v_accvgpr_read_b32 v8, a10
	v_accvgpr_read_b32 v17, a9
	v_accvgpr_read_b32 v16, a8
	v_accvgpr_read_b32 v11, a7
	v_accvgpr_read_b32 v10, a6
	v_accvgpr_read_b32 v31, a5
	v_accvgpr_read_b32 v30, a4
	v_accvgpr_read_b32 v15, a3
	v_accvgpr_read_b32 v14, a2
	v_accvgpr_read_b32 v33, a1
	s_cselect_b64 s[2:3], -1, 0
	s_cmpk_eq_u32 s19, 0xfc00
	v_accvgpr_read_b32 v32, a0
	s_cbranch_scc1 .LBB1_6
; %bb.5:                                ; %for.cond32.preheader.i
                                        ;   in Loop: Header=BB1_4 Depth=2
	v_add_u32_e32 v57, s19, v18
	v_add_u32_e32 v20, 0x400, v57
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x480, v57
	global_load_ushort v63, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v62, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x500, v57
	global_load_ushort v66, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v64, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x580, v57
	global_load_ushort v68, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v67, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x600, v57
	global_load_ushort v70, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v69, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x680, v57
	global_load_ushort v72, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v71, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x700, v57
	global_load_ushort v74, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v73, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	v_add_u32_e32 v20, 0x780, v57
	global_load_ushort v76, v[58:59], off
	v_lshlrev_b64 v[58:59], 1, v[20:21]
	global_load_ushort v75, v[60:61], off
	v_lshl_add_u64 v[60:61], s[6:7], 0, v[58:59]
	v_lshl_add_u64 v[58:59], s[8:9], 0, v[58:59]
	global_load_ushort v20, v[58:59], off
	global_load_ushort v77, v[60:61], off
	s_waitcnt vmcnt(13)
	v_perm_b32 v58, v66, v63, s17
	s_waitcnt vmcnt(12)
	v_perm_b32 v57, v64, v62, s17
	s_waitcnt vmcnt(9)
	v_perm_b32 v61, v70, v68, s17
	s_waitcnt vmcnt(8)
	v_perm_b32 v59, v69, v67, s17
	s_waitcnt vmcnt(5)
	v_perm_b32 v63, v74, v72, s17
	s_waitcnt vmcnt(4)
	v_perm_b32 v60, v73, v71, s17
	s_waitcnt vmcnt(1)
	v_perm_b32 v64, v20, v76, s17
	s_waitcnt vmcnt(0)
	v_perm_b32 v62, v77, v75, s17
.LBB1_6:                                ; %if.end51.i
                                        ;   in Loop: Header=BB1_4 Depth=2
	global_load_dwordx2 v[70:71], v[2:3], off
	global_load_dwordx2 v[72:73], v[4:5], off offset:32
	global_load_dwordx2 v[74:75], v[4:5], off offset:64
	global_load_dwordx2 v[76:77], v[4:5], off offset:96
	s_lshl_b32 s20, s19, 1
	s_and_b32 s20, s20, 0x800
	v_or_b32_e32 v20, s20, v52
	ds_read2_b64 v[66:69], v20 offset1:4
	s_cmp_eq_u32 s19, 0
	s_cselect_b64 vcc, -1, 0
	s_waitcnt vmcnt(3) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[70:71], v[66:67], 0
	s_waitcnt vmcnt(2)
	v_mfma_f32_16x16x16_f16 a[0:3], v[72:73], v[68:69], a[0:3]
	ds_read2_b64 v[66:69], v20 offset0:8 offset1:12
	v_add_u32_e32 v20, s20, v45
	v_add_u32_e32 v90, v20, v48
	v_add_u32_e32 v91, v20, v49
	s_waitcnt vmcnt(1) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[74:75], v[66:67], a[0:3]
	v_add_u32_e32 v92, v20, v50
	v_add_u32_e32 v93, v20, v51
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[76:77], v[68:69], a[0:3]
	s_nop 7
	v_accvgpr_read_b32 v73, a0
	v_accvgpr_read_b32 v74, a1
	v_accvgpr_read_b32 v75, a2
	v_accvgpr_read_b32 v76, a3
	v_mul_f32_e32 v66, 0x3e000000, v73
	v_mul_f32_e32 v67, 0x3e000000, v74
	v_mul_f32_e32 v68, 0x3e000000, v75
	v_mul_f32_e32 v69, 0x3e000000, v76
	ds_bpermute_b32 v70, v40, v66
	ds_bpermute_b32 v71, v40, v67
	ds_bpermute_b32 v72, v40, v68
	ds_bpermute_b32 v77, v40, v69
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v66, v66, v70
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v67, v67, v71
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v68, v68, v72
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v69, v69, v77
	ds_bpermute_b32 v70, v41, v66
	ds_bpermute_b32 v71, v41, v67
	ds_bpermute_b32 v72, v41, v68
	ds_bpermute_b32 v77, v41, v69
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v66, v66, v70
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v67, v67, v71
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v68, v68, v72
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v69, v69, v77
	ds_bpermute_b32 v70, v42, v66
	ds_bpermute_b32 v71, v42, v67
	ds_bpermute_b32 v72, v42, v68
	ds_bpermute_b32 v77, v42, v69
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v66, v66, v70
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v67, v67, v71
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v68, v68, v72
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v69, v69, v77
	ds_bpermute_b32 v70, v43, v66
	ds_bpermute_b32 v71, v43, v67
	ds_bpermute_b32 v72, v43, v68
	ds_bpermute_b32 v77, v43, v69
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v20, v66, v70
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v70, v67, v71
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v71, v68, v72
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v72, v69, v77
	v_max_f32_e32 v69, v34, v20
	v_max_f32_e32 v68, v35, v70
	v_cndmask_b32_e32 v20, v69, v20, vcc
	v_max_f32_e32 v67, v36, v71
	v_max_f32_e32 v66, v37, v72
	v_cndmask_b32_e32 v70, v68, v70, vcc
	v_fma_f32 v73, v73, s18, -v20
	v_cndmask_b32_e32 v71, v67, v71, vcc
	v_cndmask_b32_e32 v72, v66, v72, vcc
	v_fma_f32 v74, v74, s18, -v70
	v_sub_f32_e32 v34, v34, v20
	v_sub_f32_e32 v35, v35, v70
	v_mul_f32_e32 v73, 0x3fb8aa3b, v73
	v_fma_f32 v75, v75, s18, -v71
	v_fma_f32 v76, v76, s18, -v72
	v_sub_f32_e32 v36, v36, v71
	v_sub_f32_e32 v37, v37, v72
	v_mul_f32_e32 v74, 0x3fb8aa3b, v74
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_exp_f32_e32 v80, v73
	v_mul_f32_e32 v75, 0x3fb8aa3b, v75
	v_mul_f32_e32 v76, 0x3fb8aa3b, v76
	v_mul_f32_e32 v36, 0x3fb8aa3b, v36
	v_mul_f32_e32 v37, 0x3fb8aa3b, v37
	v_exp_f32_e32 v81, v74
	v_exp_f32_e32 v34, v34
	v_exp_f32_e32 v35, v35
	v_exp_f32_e32 v84, v75
	v_exp_f32_e32 v85, v76
	v_exp_f32_e32 v36, v36
	v_exp_f32_e32 v37, v37
	v_cvt_f16_f32_e32 v73, v80
	v_cvt_f16_f32_e32 v94, v81
	v_cndmask_b32_e64 v35, v35, 0, vcc
	v_cndmask_b32_e64 v34, v34, 0, vcc
	v_cvt_f16_f32_e32 v95, v84
	ds_bpermute_b32 v86, v40, v80
	ds_bpermute_b32 v87, v40, v81
	ds_bpermute_b32 v88, v40, v84
	ds_bpermute_b32 v89, v40, v85
	v_cndmask_b32_e64 v37, v37, 0, vcc
	v_cndmask_b32_e64 v36, v36, 0, vcc
	v_pk_mul_f32 v[74:75], v[34:35], v[32:33]
	v_pk_mul_f32 v[30:31], v[34:35], v[30:31]
	v_cvt_f16_f32_e32 v96, v85
	v_pk_mul_f32 v[76:77], v[36:37], v[14:15]
	v_pk_mul_f32 v[32:33], v[36:37], v[10:11]
	v_accvgpr_write_b32 a0, v74
	v_accvgpr_write_b32 a4, v30
	v_pk_mul_f32 v[78:79], v[34:35], v[16:17]
	v_accvgpr_write_b32 a1, v75
	v_accvgpr_write_b32 a2, v76
	v_accvgpr_write_b32 a3, v77
	v_accvgpr_write_b32 a5, v31
	v_accvgpr_write_b32 a6, v32
	v_accvgpr_write_b32 a7, v33
	ds_write_b16 v53, v73
	ds_write_b16 v54, v94
	ds_write_b16 v55, v95
	ds_write_b16 v56, v96
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64 v[14:15], v44
	ds_read_u16 v16, v90
	ds_read_u16 v30, v90 offset:32
	ds_read_u16 v31, v91
	ds_read_u16 v32, v91 offset:32
	ds_read_u16 v73, v90 offset:64
	ds_read_u16 v74, v91 offset:64
	ds_read_u16 v75, v90 offset:96
	ds_read_u16 v17, v92
	ds_read_u16 v33, v92 offset:32
	ds_read_u16 v76, v93
	ds_read_u16 v77, v93 offset:32
	ds_read_u16 v90, v92 offset:64
	ds_read_u16 v94, v93 offset:64
	ds_read_u16 v92, v92 offset:96
	ds_read_u16 v91, v91 offset:96
	ds_read_u16 v93, v93 offset:96
	s_waitcnt lgkmcnt(13)
	v_perm_b32 v16, v31, v16, s17
	s_waitcnt lgkmcnt(5)
	v_perm_b32 v31, v77, v33, s17
	v_perm_b32 v30, v32, v30, s17
	v_pk_add_f32 v[10:11], v[80:81], v[86:87]
	v_perm_b32 v17, v76, v17, s17
	v_mfma_f32_16x16x16_f16 a[4:7], v[14:15], v[30:31], a[4:7]
	v_add_f32_e64 v30, v84, v88
	v_add_f32_e64 v31, v85, v89
	v_pk_mul_f32 v[82:83], v[34:35], v[12:13]
	ds_bpermute_b32 v12, v41, v10
	ds_bpermute_b32 v13, v41, v11
	v_perm_b32 v32, v74, v73, s17
	v_mfma_f32_16x16x16_f16 a[0:3], v[14:15], v[16:17], a[0:3]
	s_waitcnt lgkmcnt(3)
	v_perm_b32 v16, v91, v75, s17
	ds_bpermute_b32 v74, v41, v30
	ds_bpermute_b32 v75, v41, v31
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[10:11], v[10:11], v[12:13]
	v_pk_mul_f32 v[80:81], v[36:37], v[8:9]
	ds_bpermute_b32 v12, v42, v10
	ds_bpermute_b32 v13, v42, v11
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[8:9], v[30:31], v[74:75]
	ds_bpermute_b32 v30, v42, v8
	ds_bpermute_b32 v31, v42, v9
	v_accvgpr_write_b32 a8, v78
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[10:11], v[10:11], v[12:13]
	v_pk_mul_f32 v[84:85], v[36:37], v[6:7]
	v_perm_b32 v33, v94, v90, s17
	v_accvgpr_write_b32 a12, v82
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[6:7], v[8:9], v[30:31]
	v_perm_b32 v17, v93, v92, s17
	ds_bpermute_b32 v12, v43, v10
	v_accvgpr_write_b32 a9, v79
	v_accvgpr_write_b32 a10, v80
	v_accvgpr_write_b32 a11, v81
	ds_bpermute_b32 v13, v43, v11
	v_accvgpr_write_b32 a13, v83
	v_accvgpr_write_b32 a14, v84
	v_accvgpr_write_b32 a15, v85
	ds_bpermute_b32 v8, v43, v6
	ds_bpermute_b32 v9, v43, v7
	v_mfma_f32_16x16x16_f16 a[8:11], v[14:15], v[32:33], a[8:11]
	s_andn2_b64 vcc, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_f32_16x16x16_f16 a[12:15], v[14:15], v[16:17], a[12:15]
	s_cbranch_vccnz .LBB1_8
; %bb.7:                                ; %if.then191.i
                                        ;   in Loop: Header=BB1_4 Depth=2
	s_add_i32 s2, s19, 0x400
	s_and_b32 s2, s2, 0x400
	v_or_b32_e32 v14, s2, v0
	v_lshlrev_b32_e32 v14, 1, v14
	ds_write_b16 v14, v57
	ds_write_b16 v14, v58 offset:4096
	ds_write_b16_d16_hi v14, v57 offset:256
	ds_write_b16_d16_hi v14, v58 offset:4352
	ds_write_b16 v14, v59 offset:512
	ds_write_b16 v14, v61 offset:4608
	ds_write_b16_d16_hi v14, v59 offset:768
	ds_write_b16_d16_hi v14, v61 offset:4864
	ds_write_b16 v14, v60 offset:1024
	ds_write_b16 v14, v63 offset:5120
	ds_write_b16_d16_hi v14, v60 offset:1280
	ds_write_b16_d16_hi v14, v63 offset:5376
	ds_write_b16 v14, v62 offset:1536
	ds_write_b16 v14, v64 offset:5632
	ds_write_b16_d16_hi v14, v62 offset:1792
	ds_write_b16_d16_hi v14, v64 offset:5888
.LBB1_8:                                ; %if.end214.i
                                        ;   in Loop: Header=BB1_4 Depth=2
	v_pk_fma_f32 v[12:13], v[34:35], v[28:29], v[12:13]
	v_pk_fma_f32 v[8:9], v[36:37], v[26:27], v[8:9]
	s_addk_i32 s19, 0x400
	v_pk_add_f32 v[28:29], v[12:13], v[10:11]
	v_pk_add_f32 v[26:27], v[8:9], v[6:7]
	s_cmp_eq_u32 s19, 0x10000
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc1 .LBB1_10
; %bb.9:                                ;   in Loop: Header=BB1_4 Depth=2
	v_mov_b32_e32 v34, v20
	v_mov_b32_e32 v35, v70
	v_mov_b32_e32 v36, v71
	v_mov_b32_e32 v37, v72
	s_branch .LBB1_4
.LBB1_10:                               ; %for.cond219.preheader.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	v_rcp_f32_e32 v31, v28
	v_accvgpr_read_b32 v13, a7
	v_accvgpr_read_b32 v17, a3
	v_or_b32_e32 v30, v65, v38
	v_accvgpr_read_b32 v2, a12
	v_accvgpr_read_b32 v6, a8
	v_accvgpr_read_b32 v10, a4
	v_accvgpr_read_b32 v14, a0
	v_lshl_add_u32 v20, v30, 6, v46
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
	v_fma_mixlo_f16 v14, v31, v14, 0
	v_lshl_add_u64 v[32:33], v[20:21], 1, s[10:11]
	v_fma_mixlo_f16 v10, v31, v10, 0
	v_fma_mixlo_f16 v6, v31, v6, 0
	v_fma_mixlo_f16 v2, v31, v2, 0
	global_store_short v[32:33], v14, off
	global_store_short v[32:33], v10, off offset:32
	global_store_short v[32:33], v6, off offset:64
	global_store_short v[32:33], v2, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB1_12
; %bb.11:                               ; %if.then252.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	v_log_f32_e32 v2, v28
	v_add_u32_e32 v20, s14, v30
	v_lshl_add_u64 v[32:33], v[20:21], 2, s[12:13]
	v_fmac_f32_e32 v69, 0x3f317218, v2
	global_store_dword v[32:33], v69, off
.LBB1_12:                               ; %if.end261.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v6, v29
	v_or_b32_e32 v2, 1, v30
	v_lshl_add_u32 v20, v2, 6, v46
	v_lshl_add_u64 v[32:33], v[20:21], 1, s[10:11]
	v_fma_mixlo_f16 v10, v6, v15, 0
	global_store_short v[32:33], v10, off
	v_fma_mixlo_f16 v10, v6, v11, 0
	v_fma_mixlo_f16 v7, v6, v7, 0
	v_fma_mixlo_f16 v3, v6, v3, 0
	global_store_short v[32:33], v10, off offset:32
	global_store_short v[32:33], v7, off offset:64
	global_store_short v[32:33], v3, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB1_14
; %bb.13:                               ; %if.then252.1.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	v_log_f32_e32 v3, v29
	v_add_u32_e32 v20, s14, v2
	v_fmac_f32_e32 v68, 0x3f317218, v3
	v_lshl_add_u64 v[2:3], v[20:21], 2, s[12:13]
	global_store_dword v[2:3], v68, off
.LBB1_14:                               ; %if.end261.1.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v3, v26
	v_or_b32_e32 v2, 2, v30
	v_lshl_add_u32 v20, v2, 6, v46
	v_lshl_add_u64 v[6:7], v[20:21], 1, s[10:11]
	v_fma_mixlo_f16 v10, v3, v16, 0
	global_store_short v[6:7], v10, off
	v_fma_mixlo_f16 v10, v3, v12, 0
	v_fma_mixlo_f16 v8, v3, v8, 0
	v_fma_mixlo_f16 v3, v3, v4, 0
	global_store_short v[6:7], v10, off offset:32
	global_store_short v[6:7], v8, off offset:64
	global_store_short v[6:7], v3, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB1_16
; %bb.15:                               ; %if.then252.2.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	v_log_f32_e32 v3, v26
	v_add_u32_e32 v20, s14, v2
	v_fmac_f32_e32 v67, 0x3f317218, v3
	v_lshl_add_u64 v[2:3], v[20:21], 2, s[12:13]
	global_store_dword v[2:3], v67, off
.LBB1_16:                               ; %if.end261.2.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	s_or_b64 exec, exec, s[2:3]
	v_rcp_f32_e32 v3, v27
	v_or_b32_e32 v2, 3, v30
	v_lshl_add_u32 v20, v2, 6, v46
	v_lshl_add_u64 v[6:7], v[20:21], 1, s[10:11]
	v_fma_mixlo_f16 v4, v3, v17, 0
	global_store_short v[6:7], v4, off
	v_fma_mixlo_f16 v4, v3, v13, 0
	global_store_short v[6:7], v4, off offset:32
	v_fma_mixlo_f16 v4, v3, v9, 0
	v_fma_mixlo_f16 v3, v3, v5, 0
	global_store_short v[6:7], v4, off offset:64
	global_store_short v[6:7], v3, off offset:96
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB1_2
; %bb.17:                               ; %if.then252.3.i
                                        ;   in Loop: Header=BB1_3 Depth=1
	v_log_f32_e32 v3, v27
	v_add_u32_e32 v20, s14, v2
	v_fmac_f32_e32 v66, 0x3f317218, v3
	v_lshl_add_u64 v[2:3], v[20:21], 2, s[12:13]
	global_store_dword v[2:3], v66, off
	s_branch .LBB1_2
.LBB1_18:                               ; %_Z9attentionILj1024ELj4EEvPKDF16_S1_S1_PDF16_PfS2_S2_S2_.exit
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel flash_attention_full
		.amdhsa_group_segment_fixed_size 9216
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
		.amdhsa_system_sgpr_workgroup_id_z 0
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
.Lfunc_end1:
	.size	flash_attention_full, .Lfunc_end1-flash_attention_full
                                        ; -- End function
	.set flash_attention_full.num_vgpr, 97
	.set flash_attention_full.num_agpr, 28
	.set flash_attention_full.numbered_sgpr, 21
	.set flash_attention_full.num_named_barrier, 0
	.set flash_attention_full.private_seg_size, 0
	.set flash_attention_full.uses_vcc, 1
	.set flash_attention_full.uses_flat_scratch, 0
	.set flash_attention_full.has_dyn_sized_stack, 0
	.set flash_attention_full.has_recursion, 0
	.set flash_attention_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3872
; TotalNumSgprs: 27
; NumVgprs: 97
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
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
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
	.type	__hip_cuid_d2158c706b98c4e5,@object ; @__hip_cuid_d2158c706b98c4e5
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_d2158c706b98c4e5
__hip_cuid_d2158c706b98c4e5:
	.byte	0                               ; 0x0
	.size	__hip_cuid_d2158c706b98c4e5, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_d2158c706b98c4e5
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     16
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
        .name:           out.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           lse.coerce
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 9216
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           flash_attention_reduced
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         flash_attention_reduced.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     136
    .vgpr_spill_count: 0
    .wavefront_size: 64
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
        .name:           out.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           lse.coerce
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 9216
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           flash_attention_full
    .private_segment_fixed_size: 0
    .sgpr_count:     27
    .sgpr_spill_count: 0
    .symbol:         flash_attention_full.kd
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
