	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	sage_attention_full     ; -- Begin function sage_attention_full
	.globl	sage_attention_full
	.p2align	8
	.type	sage_attention_full,@function
sage_attention_full:                    ; @sage_attention_full
; %bb.0:                                ; %entry
	v_lshrrev_b32_e32 v3, 2, v0
	v_and_b32_e32 v34, 12, v3
	v_mbcnt_lo_u32_b32 v3, -1, 0
	v_mbcnt_hi_u32_b32 v3, -1, v3
	v_and_b32_e32 v4, 0x70, v3
	v_add_u32_e32 v4, 16, v4
	v_xor_b32_e32 v5, 8, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_load_dwordx8 s[8:15], s[0:1], 0x0
	s_load_dwordx4 s[16:19], s[0:1], 0x20
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v36, 2, v5
	v_xor_b32_e32 v5, 4, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_lshl_b32 s0, s4, 4
	s_add_i32 s0, s0, s3
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v37, 2, v5
	v_xor_b32_e32 v5, 2, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	s_lshl_b32 s1, s4, 1
	s_lshr_b32 s5, s3, 3
	v_cndmask_b32_e32 v5, v3, v5, vcc
	v_lshlrev_b32_e32 v38, 2, v5
	v_xor_b32_e32 v5, 1, v3
	v_cmp_lt_i32_e32 vcc, v5, v4
	v_lshrrev_b32_e32 v2, 6, v0
	s_add_i32 s20, s1, s5
	s_lshl_b32 s6, s0, 16
	s_lshl_b32 s1, s2, 7
	s_lshl_b32 s0, s0, 3
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_lshl_or_b32 v1, v2, 4, s1
	v_and_b32_e32 v35, 15, v0
	s_add_i32 s0, s0, s2
	s_mov_b32 s1, 0
	v_lshlrev_b32_e32 v39, 2, v3
	v_mov_b32_e32 v3, 0x2000
	v_lshlrev_b32_e32 v4, 5, v0
	s_lshl_b64 s[2:3], s[0:1], 2
	v_lshl_or_b32 v2, v2, 9, v3
	v_lshlrev_b32_e32 v3, 1, v35
	v_and_b32_e32 v4, 0x1e0, v4
	v_lshlrev_b32_e32 v9, 1, v34
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s14, s2
	v_or_b32_e32 v8, v2, v3
	v_or3_b32 v40, v2, v4, v9
	v_or_b32_e32 v41, 0x1000, v3
	v_lshl_or_b32 v2, s20, 13, v0
	v_mov_b32_e32 v3, 0
	s_addc_u32 s3, s15, s3
	v_lshl_add_u64 v[4:5], s[10:11], 0, v[2:3]
	v_lshl_add_u64 v[6:7], v[2:3], 1, s[12:13]
	v_or_b32_e32 v2, 1, v34
	v_or_b32_e32 v10, 2, v34
	v_or_b32_e32 v11, 3, v34
	s_lshl_b32 s0, s4, 14
	s_lshl_b32 s4, s5, 13
	v_lshlrev_b32_e32 v43, 1, v0
	v_lshlrev_b32_e32 v12, 5, v34
	v_lshlrev_b32_e32 v13, 5, v2
	v_lshlrev_b32_e32 v14, 5, v10
	v_lshlrev_b32_e32 v15, 5, v11
	s_add_i32 s4, s4, s0
	s_lshl_b32 s7, s20, 1
	v_or_b32_e32 v42, s6, v35
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
	v_or_b32_e32 v44, 0x1000, v43
	v_lshlrev_b32_e32 v45, 7, v34
	v_lshlrev_b32_e32 v46, 7, v2
	v_lshlrev_b32_e32 v47, 7, v10
	v_lshlrev_b32_e32 v48, 7, v11
	v_lshl_or_b32 v49, v35, 7, v9
	v_or_b32_e32 v50, s4, v0
	s_mov_b32 s14, 0x5040100
	v_add_u32_e32 v51, v8, v12
	v_add_u32_e32 v52, v8, v13
	v_add_u32_e32 v53, v8, v14
	v_add_u32_e32 v54, v8, v15
	s_mov_b32 s15, 0
                                        ; implicit-def: $vgpr56
                                        ; implicit-def: $vgpr57
                                        ; implicit-def: $vgpr59
                                        ; implicit-def: $vgpr61
                                        ; implicit-def: $vgpr55
                                        ; implicit-def: $vgpr58
                                        ; implicit-def: $vgpr60
                                        ; implicit-def: $vgpr62
	s_branch .LBB0_2
.LBB0_1:                                ; %for.cond241.preheader.i
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_rcp_f32_e32 v14, v14
	v_accvgpr_read_b32 v19, a11
	v_or_b32_e32 v2, v63, v34
	v_accvgpr_read_b32 v16, a8
	v_lshl_add_u32 v2, v2, 6, v42
	v_lshl_add_u64 v[28:29], v[2:3], 1, s[18:19]
	v_fma_mixlo_f16 v16, v16, v14, 0
	global_store_short v[28:29], v16, off offset:64
	v_rcp_f32_e32 v16, v15
	v_accvgpr_read_b32 v23, a7
	v_accvgpr_read_b32 v27, a3
	v_accvgpr_read_b32 v10, a12
	v_accvgpr_read_b32 v20, a4
	v_accvgpr_read_b32 v24, a0
	v_accvgpr_read_b32 v25, a1
	v_fma_mixlo_f16 v24, v24, v14, 0
	v_fma_mixlo_f16 v20, v20, v14, 0
	v_fma_mixlo_f16 v10, v10, v14, 0
	v_add_u32_e32 v14, 64, v2
	v_mov_b32_e32 v15, v3
	v_accvgpr_read_b32 v21, a5
	global_store_short v[28:29], v10, off offset:96
	v_fma_mixlo_f16 v10, v25, v16, 0
	v_lshl_add_u64 v[14:15], v[14:15], 1, s[18:19]
	v_accvgpr_read_b32 v17, a9
	global_store_short v[28:29], v20, off offset:32
	global_store_short v[14:15], v10, off
	v_fma_mixlo_f16 v10, v21, v16, 0
	v_rcp_f32_e32 v8, v8
	v_accvgpr_read_b32 v11, a13
	global_store_short v[28:29], v24, off
	global_store_short v[14:15], v10, off offset:32
	v_fma_mixlo_f16 v10, v17, v16, 0
	global_store_short v[14:15], v10, off offset:64
	v_fma_mixlo_f16 v10, v11, v16, 0
	v_accvgpr_read_b32 v26, a2
	global_store_short v[14:15], v10, off offset:96
	v_add_u32_e32 v10, 0x80, v2
	v_mov_b32_e32 v11, v3
	v_accvgpr_read_b32 v22, a6
	v_fma_mixlo_f16 v14, v26, v8, 0
	v_lshl_add_u64 v[10:11], v[10:11], 1, s[18:19]
	v_accvgpr_read_b32 v18, a10
	global_store_short v[10:11], v14, off
	v_fma_mixlo_f16 v14, v22, v8, 0
	global_store_short v[10:11], v14, off offset:32
	v_fma_mixlo_f16 v14, v18, v8, 0
	global_store_short v[10:11], v14, off offset:64
	v_rcp_f32_e32 v14, v9
	v_accvgpr_read_b32 v12, a14
	v_fma_mixlo_f16 v8, v12, v8, 0
	v_add_u32_e32 v2, 0xc0, v2
	global_store_short v[10:11], v8, off offset:96
	v_lshl_add_u64 v[8:9], v[2:3], 1, s[18:19]
	v_fma_mixlo_f16 v2, v23, v14, 0
	v_accvgpr_read_b32 v13, a15
	global_store_short v[8:9], v2, off offset:32
	v_fma_mixlo_f16 v2, v19, v14, 0
	s_add_i32 s15, s15, 1
	v_fma_mixlo_f16 v10, v27, v14, 0
	global_store_short v[8:9], v2, off offset:64
	v_fma_mixlo_f16 v2, v13, v14, 0
	s_cmp_eq_u32 s15, 4
	global_store_short v[8:9], v10, off
	global_store_short v[8:9], v2, off offset:96
	s_barrier
	s_cbranch_scc1 .LBB0_9
.LBB0_2:                                ; %for.body.i
                                        ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_3 Depth 2
	global_load_sbyte v2, v[4:5], off
	v_lshl_add_u32 v63, s15, 5, v1
	s_mov_b32 s20, s1
	s_mov_b32 s21, s1
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v33, v3
	v_mov_b32_e32 v64, v3
	v_mov_b32_e32 v65, v3
	v_mov_b32_e32 v14, v3
	v_mov_b32_e32 v15, v3
	v_mov_b32_e32 v9, v3
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
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2
	global_load_ushort v2, v[6:7], off
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2
	global_load_sbyte v2, v[4:5], off offset:128
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:256
	global_load_ushort v2, v[6:7], off offset:256
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:256
	global_load_sbyte v2, v[4:5], off offset:256
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:512
	global_load_ushort v2, v[6:7], off offset:512
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:512
	global_load_sbyte v2, v[4:5], off offset:384
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:768
	global_load_ushort v2, v[6:7], off offset:768
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:768
	global_load_sbyte v2, v[4:5], off offset:512
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:1024
	global_load_ushort v2, v[6:7], off offset:1024
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:1024
	global_load_sbyte v2, v[4:5], off offset:640
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:1280
	global_load_ushort v2, v[6:7], off offset:1280
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:1280
	global_load_sbyte v2, v[4:5], off offset:768
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:1536
	global_load_ushort v2, v[6:7], off offset:1536
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:1536
	global_load_sbyte v2, v[4:5], off offset:896
	s_waitcnt vmcnt(0)
	v_cvt_f16_i16_e32 v2, v2
	ds_write_b16 v43, v2 offset:1792
	global_load_ushort v2, v[6:7], off offset:1792
	s_waitcnt vmcnt(0)
	ds_write_b16 v44, v2 offset:1792
	v_or_b32_e32 v2, v63, v35
	v_lshl_add_u32 v8, v2, 6, s6
	v_or_b32_e32 v2, v8, v34
	v_lshl_add_u64 v[10:11], s[8:9], 0, v[2:3]
	v_add_u32_e32 v2, v8, v34
	v_lshl_add_u64 v[12:13], s[8:9], 0, v[2:3]
	v_mov_b32_e32 v8, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
.LBB0_3:                                ; %for.body35.i
                                        ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_cmpk_lg_i32 s20, 0x1c00
	v_accvgpr_read_b32 v17, a15
	v_accvgpr_read_b32 v16, a14
	v_accvgpr_read_b32 v25, a13
	v_accvgpr_read_b32 v24, a12
	v_accvgpr_read_b32 v19, a11
	v_accvgpr_read_b32 v18, a10
	v_accvgpr_read_b32 v27, a9
	v_accvgpr_read_b32 v26, a8
	v_accvgpr_read_b32 v21, a7
	v_accvgpr_read_b32 v20, a6
	v_accvgpr_read_b32 v29, a5
	v_accvgpr_read_b32 v28, a4
	v_accvgpr_read_b32 v23, a3
	v_accvgpr_read_b32 v22, a2
	v_accvgpr_read_b32 v31, a1
	s_cselect_b64 s[4:5], -1, 0
	s_cmpk_eq_i32 s20, 0x1c00
	v_accvgpr_read_b32 v30, a0
	s_cbranch_scc1 .LBB0_5
; %bb.4:                                ; %for.cond39.preheader.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	v_add_u32_e32 v55, s20, v50
	v_add_u32_e32 v2, 0x400, v55
	global_load_sbyte v62, v2, s[10:11]
	v_lshl_add_u64 v[56:57], v[2:3], 1, s[12:13]
	v_add_u32_e32 v2, 0x480, v55
	global_load_sbyte v72, v2, s[10:11]
	v_lshl_add_u64 v[58:59], v[2:3], 1, s[12:13]
	v_add_u32_e32 v2, 0x500, v55
	global_load_sbyte v73, v2, s[10:11]
	v_lshl_add_u64 v[60:61], v[2:3], 1, s[12:13]
	v_add_u32_e32 v2, 0x580, v55
	global_load_sbyte v74, v2, s[10:11]
	v_lshl_add_u64 v[66:67], v[2:3], 1, s[12:13]
	v_add_u32_e32 v2, 0x600, v55
	global_load_sbyte v75, v2, s[10:11]
	v_lshl_add_u64 v[68:69], v[2:3], 1, s[12:13]
	v_add_u32_e32 v2, 0x680, v55
	global_load_sbyte v76, v2, s[10:11]
	v_lshl_add_u64 v[70:71], v[2:3], 1, s[12:13]
	v_add_u32_e32 v2, 0x700, v55
	global_load_ushort v77, v[56:57], off
	global_load_ushort v78, v[58:59], off
	global_load_ushort v79, v[60:61], off
	global_load_ushort v80, v[66:67], off
	global_load_ushort v81, v[68:69], off
	global_load_ushort v82, v[70:71], off
	v_lshl_add_u64 v[56:57], v[2:3], 1, s[12:13]
	global_load_sbyte v60, v2, s[10:11]
	v_add_u32_e32 v2, 0x780, v55
	global_load_sbyte v61, v2, s[10:11]
	v_lshl_add_u64 v[58:59], v[2:3], 1, s[12:13]
	global_load_ushort v2, v[56:57], off
	global_load_ushort v66, v[58:59], off
	s_waitcnt vmcnt(15)
	v_cvt_f16_i16_e32 v56, v62
	s_waitcnt vmcnt(14)
	v_cvt_f16_i16_e32 v57, v72
	v_pack_b32_f16 v56, v56, v57
	s_waitcnt vmcnt(13)
	v_cvt_f16_i16_e32 v59, v73
	s_waitcnt vmcnt(12)
	v_cvt_f16_i16_e32 v57, v74
	v_pack_b32_f16 v57, v59, v57
	s_waitcnt vmcnt(11)
	v_cvt_f16_i16_e32 v62, v75
	s_waitcnt vmcnt(8)
	v_perm_b32 v55, v78, v77, s14
	v_cvt_f16_i16_e32 v59, v76
	s_waitcnt vmcnt(6)
	v_perm_b32 v58, v80, v79, s14
	v_pack_b32_f16 v59, v62, v59
	s_waitcnt vmcnt(3)
	v_cvt_f16_i16_e32 v67, v60
	v_perm_b32 v60, v82, v81, s14
	s_waitcnt vmcnt(2)
	v_cvt_f16_i16_e32 v61, v61
	v_pack_b32_f16 v61, v67, v61
	s_waitcnt vmcnt(0)
	v_perm_b32 v62, v66, v2, s14
.LBB0_5:                                ; %if.end.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	global_load_dword v2, v[10:11], off
	global_load_dword v74, v[12:13], off offset:16
	global_load_dword v75, v[12:13], off offset:32
	global_load_dword v76, v[12:13], off offset:48
	s_lshl_b32 s0, s20, 1
	s_and_b32 s22, s0, 0x800
	v_or_b32_e32 v70, s22, v49
	s_load_dword s23, s[2:3], 0x0
	ds_read2_b64 v[66:69], v70 offset1:4
	ds_read2_b64 v[70:73], v70 offset0:8 offset1:12
	s_lshr_b32 s24, s21, 2
	s_add_i32 s0, s24, s7
	s_lshl_b64 s[24:25], s[0:1], 2
	s_add_u32 s24, s16, s24
	s_addc_u32 s25, s17, s25
	s_load_dword s0, s[24:25], 0x0
	s_cmp_eq_u32 s20, 0
	s_cselect_b64 vcc, -1, 0
	s_waitcnt vmcnt(3)
	v_lshrrev_b32_e32 v77, 16, v2
	v_lshrrev_b32_e32 v78, 8, v2
	v_lshrrev_b32_e32 v79, 24, v2
	v_cvt_f16_i16_sdwa v2, sext(v2) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	s_waitcnt vmcnt(2)
	v_lshrrev_b32_e32 v80, 16, v74
	v_lshrrev_b32_e32 v81, 8, v74
	v_lshrrev_b32_e32 v82, 24, v74
	v_cvt_f16_i16_sdwa v83, sext(v74) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	s_waitcnt vmcnt(1)
	v_lshrrev_b32_e32 v74, 16, v75
	v_lshrrev_b32_e32 v84, 8, v75
	v_lshrrev_b32_e32 v85, 24, v75
	v_cvt_f16_i16_sdwa v86, sext(v75) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	s_waitcnt vmcnt(0)
	v_lshrrev_b32_e32 v87, 16, v76
	v_lshrrev_b32_e32 v88, 8, v76
	v_lshrrev_b32_e32 v89, 24, v76
	v_cvt_f16_i16_sdwa v90, sext(v76) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v76, sext(v78) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v75, sext(v77) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v77, sext(v79) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v79, sext(v80) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v80, sext(v82) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v82, sext(v74) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_pack_b32_f16 v75, v75, v77
	v_pack_b32_f16 v74, v2, v76
	v_cvt_f16_i16_sdwa v78, sext(v81) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_pack_b32_f16 v77, v79, v80
	v_pack_b32_f16 v76, v83, v78
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[74:75], v[66:67], 0
	v_cvt_f16_i16_sdwa v81, sext(v84) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v2, sext(v85) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_pack_b32_f16 v67, v82, v2
	v_pack_b32_f16 v66, v86, v81
	v_mfma_f32_16x16x16_f16 a[0:3], v[76:77], v[68:69], a[0:3]
	v_cvt_f16_i16_sdwa v84, sext(v88) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v74, sext(v87) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_cvt_f16_i16_sdwa v2, sext(v89) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0
	v_pack_b32_f16 v69, v74, v2
	v_pack_b32_f16 v68, v90, v84
	v_mfma_f32_16x16x16_f16 a[0:3], v[66:67], v[70:71], a[0:3]
	v_mov_b32_e32 v66, s0
	v_mul_f32_e32 v70, s23, v66
	v_max_f32_e32 v2, v32, v32
	v_mfma_f32_16x16x16_f16 a[0:3], v[68:69], v[72:73], a[0:3]
	v_max_f32_e32 v79, v33, v33
	v_max_f32_e32 v80, v64, v64
	v_max_f32_e32 v81, v65, v65
	s_nop 4
	v_accvgpr_read_b32 v69, a0
	v_accvgpr_read_b32 v71, a1
	v_accvgpr_read_b32 v72, a2
	v_accvgpr_read_b32 v73, a3
	v_mul_f32_e32 v66, v69, v70
	v_mul_f32_e32 v67, v71, v70
	v_mul_f32_e32 v68, v72, v70
	v_mul_f32_e32 v74, v73, v70
	ds_bpermute_b32 v75, v36, v66
	ds_bpermute_b32 v76, v36, v67
	ds_bpermute_b32 v77, v36, v68
	ds_bpermute_b32 v78, v36, v74
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v75, v75, v75
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v76, v76, v76
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v77, v77, v77
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v78, v78, v78
	v_max_f32_e32 v66, v66, v75
	v_max_f32_e32 v67, v67, v76
	v_max_f32_e32 v68, v68, v77
	v_max_f32_e32 v74, v74, v78
	ds_bpermute_b32 v75, v37, v66
	ds_bpermute_b32 v76, v37, v67
	ds_bpermute_b32 v77, v37, v68
	ds_bpermute_b32 v78, v37, v74
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v75, v75, v75
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v76, v76, v76
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v77, v77, v77
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v78, v78, v78
	v_max_f32_e32 v66, v66, v75
	v_max_f32_e32 v67, v67, v76
	v_max_f32_e32 v68, v68, v77
	v_max_f32_e32 v74, v74, v78
	ds_bpermute_b32 v75, v38, v66
	ds_bpermute_b32 v76, v38, v67
	ds_bpermute_b32 v77, v38, v68
	ds_bpermute_b32 v78, v38, v74
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v75, v75, v75
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v76, v76, v76
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v77, v77, v77
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v78, v78, v78
	v_max_f32_e32 v66, v66, v75
	v_max_f32_e32 v67, v67, v76
	v_max_f32_e32 v68, v68, v77
	v_max_f32_e32 v74, v74, v78
	ds_bpermute_b32 v75, v39, v66
	ds_bpermute_b32 v76, v39, v67
	ds_bpermute_b32 v77, v39, v68
	ds_bpermute_b32 v78, v39, v74
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v75, v75, v75
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v76, v76, v76
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v77, v77, v77
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v78, v78, v78
	v_max_f32_e32 v66, v66, v75
	v_max_f32_e32 v67, v67, v76
	v_max_f32_e32 v68, v68, v77
	v_max_f32_e32 v74, v74, v78
	v_max_f32_e32 v2, v2, v66
	v_max_f32_e32 v75, v79, v67
	v_max_f32_e32 v76, v80, v68
	v_max_f32_e32 v77, v81, v74
	v_cndmask_b32_e32 v2, v2, v66, vcc
	v_cndmask_b32_e32 v66, v75, v67, vcc
	v_cndmask_b32_e32 v67, v76, v68, vcc
	v_cndmask_b32_e32 v68, v77, v74, vcc
	v_fma_f32 v69, v69, v70, -v2
	v_fma_f32 v71, v71, v70, -v66
	v_fma_f32 v72, v72, v70, -v67
	v_fma_f32 v73, v73, v70, -v68
	v_exp_f32_e32 v70, v69
	v_exp_f32_e32 v71, v71
	v_exp_f32_e32 v76, v72
	v_exp_f32_e32 v77, v73
	v_cvt_f16_f32_e32 v69, v70
	v_cvt_f16_f32_e32 v72, v71
	v_cvt_f16_f32_e32 v73, v76
	v_cvt_f16_f32_e32 v74, v77
	v_sub_f32_e32 v64, v64, v67
	ds_write_b16 v51, v69
	ds_write_b16 v52, v72
	ds_write_b16 v53, v73
	ds_write_b16 v54, v74
	v_exp_f32_e32 v69, v64
	v_sub_f32_e32 v64, v65, v68
	v_exp_f32_e32 v90, v64
	v_add_u32_e32 v64, s22, v41
	v_add_u32_e32 v65, v64, v47
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v72, v64, v45
	v_add_u32_e32 v73, v64, v46
	v_add_u32_e32 v74, v64, v48
	ds_read_u16 v64, v65
	ds_read_u16 v75, v65 offset:32
	ds_read_u16 v78, v74
	ds_read_u16 v80, v74 offset:32
	ds_read_u16 v82, v65 offset:64
	ds_read_u16 v83, v74 offset:64
	ds_read_u16 v84, v65 offset:96
	ds_read_u16 v86, v73 offset:96
	s_waitcnt lgkmcnt(5)
	v_perm_b32 v65, v78, v64, s14
	ds_read_b64 v[78:79], v40
	ds_read_u16 v64, v72
	ds_read_u16 v85, v72 offset:32
	ds_read_u16 v81, v73
	ds_read_u16 v87, v73 offset:32
	ds_read_u16 v88, v72 offset:64
	ds_read_u16 v73, v73 offset:64
	ds_read_u16 v89, v72 offset:96
	s_waitcnt lgkmcnt(10)
	v_perm_b32 v83, v83, v82, s14
	ds_bpermute_b32 v72, v36, v70
	ds_read_u16 v74, v74 offset:96
	s_waitcnt lgkmcnt(3)
	v_perm_b32 v82, v73, v88, s14
	ds_bpermute_b32 v73, v36, v71
	v_sub_f32_e32 v32, v32, v2
	v_sub_f32_e32 v33, v33, v66
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[72:73], v[70:71], v[72:73]
	v_perm_b32 v64, v81, v64, s14
	v_perm_b32 v81, v80, v75, s14
	v_perm_b32 v80, v87, v85, s14
	v_perm_b32 v85, v74, v84, s14
	v_perm_b32 v84, v86, v89, s14
	ds_bpermute_b32 v86, v37, v72
	ds_bpermute_b32 v87, v37, v73
	v_cndmask_b32_e64 v33, v33, 0, vcc
	v_cndmask_b32_e64 v32, v32, 0, vcc
	v_pk_mul_f32 v[70:71], v[30:31], v[32:33]
	ds_bpermute_b32 v88, v36, v76
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[30:31], v[72:73], v[86:87]
	ds_bpermute_b32 v86, v38, v30
	ds_bpermute_b32 v87, v38, v31
	ds_bpermute_b32 v89, v36, v77
	v_pk_mul_f32 v[28:29], v[28:29], v[32:33]
	v_pk_mul_f32 v[74:75], v[24:25], v[32:33]
	v_cndmask_b32_e64 v25, v90, 0, vcc
	v_cndmask_b32_e64 v24, v69, 0, vcc
	v_pk_mul_f32 v[72:73], v[22:23], v[24:25]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[22:23], v[30:31], v[86:87]
	v_accvgpr_write_b32 a0, v70
	v_pk_mul_f32 v[30:31], v[20:21], v[24:25]
	v_accvgpr_write_b32 a1, v71
	v_accvgpr_write_b32 a4, v28
	v_accvgpr_write_b32 a2, v72
	v_accvgpr_write_b32 a3, v73
	v_accvgpr_write_b32 a5, v29
	v_accvgpr_write_b32 a6, v30
	v_accvgpr_write_b32 a7, v31
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[30:31], v[76:77], v[88:89]
	v_mfma_f32_16x16x16_f16 a[0:3], v[78:79], v[64:65], a[0:3]
	ds_bpermute_b32 v64, v37, v30
	ds_bpermute_b32 v65, v37, v31
	v_pk_mul_f32 v[26:27], v[26:27], v[32:33]
	v_pk_mul_f32 v[28:29], v[18:19], v[24:25]
	v_pk_mul_f32 v[76:77], v[16:17], v[24:25]
	v_accvgpr_write_b32 a8, v26
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[18:19], v[30:31], v[64:65]
	v_accvgpr_write_b32 a9, v27
	v_accvgpr_write_b32 a10, v28
	v_accvgpr_write_b32 a11, v29
	ds_bpermute_b32 v26, v38, v18
	ds_bpermute_b32 v27, v38, v19
	v_accvgpr_write_b32 a12, v74
	ds_bpermute_b32 v20, v39, v22
	ds_bpermute_b32 v21, v39, v23
	v_accvgpr_write_b32 a13, v75
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[16:17], v[18:19], v[26:27]
	v_accvgpr_write_b32 a14, v76
	v_accvgpr_write_b32 a15, v77
	ds_bpermute_b32 v18, v39, v16
	ds_bpermute_b32 v19, v39, v17
	v_mfma_f32_16x16x16_f16 a[4:7], v[78:79], v[80:81], a[4:7]
	s_andn2_b64 vcc, exec, s[4:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_f32_16x16x16_f16 a[8:11], v[78:79], v[82:83], a[8:11]
	v_mfma_f32_16x16x16_f16 a[12:15], v[78:79], v[84:85], a[12:15]
	s_cbranch_vccnz .LBB0_7
; %bb.6:                                ; %if.then213.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	s_add_i32 s0, s20, 0x400
	s_and_b32 s0, s0, 0x400
	v_or_b32_e32 v26, s0, v0
	v_lshlrev_b32_e32 v26, 1, v26
	ds_write_b16 v26, v56
	ds_write_b16 v26, v55 offset:4096
	ds_write_b16_d16_hi v26, v56 offset:256
	ds_write_b16_d16_hi v26, v55 offset:4352
	ds_write_b16 v26, v57 offset:512
	ds_write_b16 v26, v58 offset:4608
	ds_write_b16_d16_hi v26, v57 offset:768
	ds_write_b16_d16_hi v26, v58 offset:4864
	ds_write_b16 v26, v59 offset:1024
	ds_write_b16 v26, v60 offset:5120
	ds_write_b16_d16_hi v26, v59 offset:1280
	ds_write_b16_d16_hi v26, v60 offset:5376
	ds_write_b16 v26, v61 offset:1536
	ds_write_b16 v26, v62 offset:5632
	ds_write_b16_d16_hi v26, v61 offset:1792
	ds_write_b16_d16_hi v26, v62 offset:5888
.LBB0_7:                                ; %if.end236.i
                                        ;   in Loop: Header=BB0_3 Depth=2
	v_pk_add_f32 v[20:21], v[22:23], v[20:21]
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	s_addk_i32 s20, 0x400
	s_add_i32 s21, s21, 1
	v_pk_fma_f32 v[14:15], v[14:15], v[32:33], v[20:21]
	v_pk_fma_f32 v[8:9], v[8:9], v[24:25], v[16:17]
	s_cmpk_eq_i32 s20, 0x2000
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc1 .LBB0_1
; %bb.8:                                ;   in Loop: Header=BB0_3 Depth=2
	v_mov_b32_e32 v32, v2
	v_mov_b32_e32 v33, v66
	v_mov_b32_e32 v64, v67
	v_mov_b32_e32 v65, v68
	s_branch .LBB0_3
.LBB0_9:                                ; %_Z14sage_attentionILj128ELj4EEvPKaS1_PKDF16_PKfS5_PDF16_S6_S6_S6_.exit
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel sage_attention_full
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
		.amdhsa_next_free_vgpr 120
		.amdhsa_next_free_sgpr 26
		.amdhsa_accum_offset 92
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
	.size	sage_attention_full, .Lfunc_end0-sage_attention_full
                                        ; -- End function
	.set sage_attention_full.num_vgpr, 91
	.set sage_attention_full.num_agpr, 28
	.set sage_attention_full.numbered_sgpr, 26
	.set sage_attention_full.num_named_barrier, 0
	.set sage_attention_full.private_seg_size, 0
	.set sage_attention_full.uses_vcc, 1
	.set sage_attention_full.uses_flat_scratch, 0
	.set sage_attention_full.has_dyn_sized_stack, 0
	.set sage_attention_full.has_recursion, 0
	.set sage_attention_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3940
; TotalNumSgprs: 32
; NumVgprs: 91
; NumAgprs: 28
; TotalNumVgprs: 120
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 9216 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 14
; NumSGPRsForWavesPerEU: 32
; NumVGPRsForWavesPerEU: 120
; AccumOffset: 92
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 22
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_2c6398c210534300,@object ; @__hip_cuid_2c6398c210534300
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_2c6398c210534300
__hip_cuid_2c6398c210534300:
	.byte	0                               ; 0x0
	.size	__hip_cuid_2c6398c210534300, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_2c6398c210534300
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
        .name:           q_scale.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           k_scale.coerce
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
    .name:           sage_attention_full
    .private_segment_fixed_size: 0
    .sgpr_count:     32
    .sgpr_spill_count: 0
    .symbol:         sage_attention_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     120
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
