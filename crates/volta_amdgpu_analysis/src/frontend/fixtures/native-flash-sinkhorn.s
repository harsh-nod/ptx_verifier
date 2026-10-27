	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	flash_sinkhorn_full     ; -- Begin function flash_sinkhorn_full
	.globl	flash_sinkhorn_full
	.p2align	8
	.type	flash_sinkhorn_full,@function
flash_sinkhorn_full:                    ; @flash_sinkhorn_full
; %bb.0:                                ; %entry
	s_load_dwordx16 s[4:19], s[0:1], 0x0
	s_lshl_b32 s24, s2, 5
	s_cmp_lt_u32 s2, 32
	s_cselect_b64 s[2:3], -1, 0
	s_and_b64 s[0:1], s[2:3], exec
	s_waitcnt lgkmcnt(0)
	s_cselect_b32 s1, s7, s5
	s_cselect_b32 s0, s6, s4
	v_lshlrev_b32_e32 v2, 1, v0
	global_load_ushort v1, v2, s[0:1]
	global_load_ushort v14, v2, s[0:1] offset:256
	global_load_ushort v15, v2, s[0:1] offset:512
	global_load_ushort v16, v2, s[0:1] offset:768
	global_load_ushort v17, v2, s[0:1] offset:1024
	global_load_ushort v18, v2, s[0:1] offset:1280
	global_load_ushort v19, v2, s[0:1] offset:1536
	global_load_ushort v20, v2, s[0:1] offset:1792
	v_mbcnt_lo_u32_b32 v4, -1, 0
	v_mov_b32_e32 v6, 0x3f0
	v_lshrrev_b32_e32 v7, 2, v0
	v_mbcnt_hi_u32_b32 v8, -1, v4
	v_bitop3_b32 v23, s24, v6, v7 bitop3:0xc8
	v_and_b32_e32 v6, 0x70, v8
	v_and_b32_e32 v22, 12, v7
	v_xor_b32_e32 v7, 8, v8
	v_add_u32_e32 v6, 16, v6
	v_xor_b32_e32 v10, 4, v8
	v_cmp_lt_i32_e32 vcc, v7, v6
	v_xor_b32_e32 v11, 2, v8
	v_and_b32_e32 v24, 15, v0
	v_cndmask_b32_e32 v7, v8, v7, vcc
	v_cmp_lt_i32_e32 vcc, v10, v6
	v_xor_b32_e32 v21, 1, v8
	v_mov_b32_e32 v3, 0
	v_cndmask_b32_e32 v10, v8, v10, vcc
	v_cmp_lt_i32_e32 vcc, v11, v6
	v_or_b32_e32 v25, v23, v24
	v_lshlrev_b32_e32 v26, 1, v22
	v_cndmask_b32_e32 v11, v8, v11, vcc
	v_cmp_lt_i32_e32 vcc, v21, v6
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v13, v3
	v_lshlrev_b32_e32 v12, 2, v24
	v_cndmask_b32_e32 v6, v8, v21, vcc
	v_lshl_or_b32 v8, v25, 7, v26
	s_cselect_b32 s5, s5, s7
	s_cselect_b32 s4, s4, s6
	s_cselect_b32 s7, s11, s9
	s_cselect_b32 s6, s10, s8
	s_cselect_b32 s13, s15, s13
	s_cselect_b32 s12, s14, s12
	s_mov_b32 s22, 0
	s_mov_b64 s[20:21], 0
	s_mov_b32 s23, 0x5040100
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v30, v3
	v_mov_b32_e32 v31, v3
	v_mov_b32_e32 v4, v3
	v_mov_b32_e32 v5, v3
	v_mov_b32_e32 v0, v3
	v_lshl_or_b32 v25, v24, 7, v26
	v_lshlrev_b32_e32 v26, 2, v7
	v_lshlrev_b32_e32 v27, 2, v10
	v_lshlrev_b32_e32 v28, 2, v11
	v_lshlrev_b32_e32 v29, 2, v6
	v_lshl_add_u64 v[6:7], s[0:1], 0, v[2:3]
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[8:9]
	v_lshl_add_u64 v[10:11], s[6:7], 0, v[12:13]
	v_lshl_add_u64 v[12:13], s[12:13], 0, v[12:13]
                                        ; implicit-def: $vgpr33
                                        ; implicit-def: $vgpr34
                                        ; implicit-def: $vgpr35
                                        ; implicit-def: $vgpr36
	s_waitcnt vmcnt(7)
	ds_write_b16 v2, v1
	s_waitcnt vmcnt(6)
	ds_write_b16 v2, v14 offset:256
	s_waitcnt vmcnt(5)
	ds_write_b16 v2, v15 offset:512
	s_waitcnt vmcnt(4)
	ds_write_b16 v2, v16 offset:768
	s_waitcnt vmcnt(3)
	ds_write_b16 v2, v17 offset:1024
	s_waitcnt vmcnt(2)
	ds_write_b16 v2, v18 offset:1280
	s_waitcnt vmcnt(1)
	ds_write_b16 v2, v19 offset:1536
	s_waitcnt vmcnt(0)
	ds_write_b16 v2, v20 offset:1792
	v_mov_b32_e32 v1, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .LBB0_2
.LBB0_1:                                ; %if.end159
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_sub_f32_e32 v3, v3, v41
	v_exp_f32_e32 v3, v3
	v_sub_f32_e32 v32, v32, v42
	v_exp_f32_e32 v32, v32
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[18:19], v[18:19], v[20:21]
	v_cndmask_b32_e64 v46, v3, 0, s[0:1]
	v_sub_f32_e32 v3, v30, v43
	v_sub_f32_e32 v30, v31, v44
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v3, v3
	v_cndmask_b32_e64 v47, v32, 0, s[0:1]
	s_add_u32 s20, s20, 0x800
	v_pk_fma_f32 v[4:5], v[4:5], v[46:47], v[18:19]
	v_cndmask_b32_e64 v19, v30, 0, s[0:1]
	v_cndmask_b32_e64 v18, v3, 0, s[0:1]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	s_addc_u32 s21, s21, 0
	s_add_i32 s22, s22, 1
	v_pk_fma_f32 v[0:1], v[0:1], v[18:19], v[14:15]
	v_lshl_add_u64 v[10:11], v[10:11], 0, 64
	v_lshl_add_u64 v[12:13], v[12:13], 0, 64
	s_cmp_eq_u32 s20, 0x20000
	v_mov_b32_e32 v3, v41
	v_mov_b32_e32 v32, v42
	v_mov_b32_e32 v30, v43
	v_mov_b32_e32 v31, v44
	s_barrier
	s_cbranch_scc1 .LBB0_6
.LBB0_2:                                ; %for.body47
                                        ; =>This Inner Loop Header: Depth=1
	s_cmp_lg_u32 s20, 0x1f800
	s_cselect_b64 s[4:5], -1, 0
	s_cmp_eq_u32 s20, 0x1f800
	s_cbranch_scc1 .LBB0_4
; %bb.3:                                ; %for.cond51.preheader
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_lshl_add_u64 v[14:15], v[6:7], 0, s[20:21]
	global_load_ushort v16, v[14:15], off offset:2048
	global_load_ushort v17, v[14:15], off offset:2304
	global_load_ushort v18, v[14:15], off offset:2560
	global_load_ushort v19, v[14:15], off offset:2816
	global_load_ushort v20, v[14:15], off offset:3072
	global_load_ushort v21, v[14:15], off offset:3328
	global_load_ushort v36, v[14:15], off offset:3584
	global_load_ushort v37, v[14:15], off offset:3840
	s_waitcnt vmcnt(6)
	v_perm_b32 v33, v17, v16, s23
	s_waitcnt vmcnt(4)
	v_perm_b32 v34, v19, v18, s23
	s_waitcnt vmcnt(2)
	v_perm_b32 v35, v21, v20, s23
	s_waitcnt vmcnt(0)
	v_perm_b32 v36, v37, v36, s23
.LBB0_4:                                ; %if.end
                                        ;   in Loop: Header=BB0_2 Depth=1
	global_load_dwordx2 v[18:19], v[8:9], off
	global_load_dwordx2 v[20:21], v[8:9], off offset:32
	global_load_dwordx2 v[38:39], v[8:9], off offset:64
	s_and_b32 s6, s22, 1
	v_lshl_or_b32 v37, s6, 11, v25
	ds_read2_b64 v[14:17], v37 offset1:4
	global_load_dwordx2 v[40:41], v[8:9], off offset:96
	global_load_dword v42, v[12:13], off
	v_max_f32_e32 v43, v30, v30
	v_max_f32_e32 v44, v31, v31
	s_cmp_eq_u32 s20, 0
	s_cselect_b64 s[0:1], -1, 0
	s_andn2_b64 vcc, exec, s[4:5]
	s_waitcnt vmcnt(4) lgkmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[18:19], v[14:15], 0
	global_load_dword v18, v[10:11], off
	s_waitcnt vmcnt(4)
	v_mfma_f32_16x16x16_f16 a[0:3], v[20:21], v[16:17], a[0:3]
	ds_read2_b64 v[14:17], v37 offset0:8 offset1:12
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(3)
	v_mfma_f32_16x16x16_f16 a[0:3], v[38:39], v[14:15], a[0:3]
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v15, 0x3fb8aa3b, v42
	v_max_f32_e32 v14, v3, v3
	v_max_f32_e32 v38, v32, v32
	v_mfma_f32_16x16x16_f16 a[0:3], v[40:41], v[16:17], a[0:3]
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v15, 0x3fb8aa3b, v18
	s_nop 5
	v_accvgpr_read_b32 v16, a0
	v_accvgpr_read_b32 v17, a1
	v_accvgpr_read_b32 v18, a2
	v_accvgpr_read_b32 v19, a3
	v_fmamk_f32 v16, v16, 0x4038aa3b, v15
	v_fmamk_f32 v17, v17, 0x4038aa3b, v15
	v_fmamk_f32 v18, v18, 0x4038aa3b, v15
	v_fmac_f32_e32 v15, 0x4038aa3b, v19
	ds_bpermute_b32 v19, v26, v16
	ds_bpermute_b32 v20, v26, v17
	ds_bpermute_b32 v21, v26, v18
	ds_bpermute_b32 v37, v26, v15
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v19, v19, v19
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v20, v20, v20
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v21, v21, v21
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v37, v37, v37
	v_max_f32_e32 v19, v16, v19
	v_max_f32_e32 v20, v17, v20
	v_max_f32_e32 v21, v18, v21
	v_max_f32_e32 v37, v15, v37
	ds_bpermute_b32 v39, v27, v19
	ds_bpermute_b32 v40, v27, v20
	ds_bpermute_b32 v41, v27, v21
	ds_bpermute_b32 v42, v27, v37
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v39, v39, v39
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v40, v40, v40
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v41, v41, v41
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v42, v42, v42
	v_max_f32_e32 v19, v19, v39
	v_max_f32_e32 v20, v20, v40
	v_max_f32_e32 v21, v21, v41
	v_max_f32_e32 v37, v37, v42
	ds_bpermute_b32 v39, v28, v19
	ds_bpermute_b32 v40, v28, v20
	ds_bpermute_b32 v41, v28, v21
	ds_bpermute_b32 v42, v28, v37
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v39, v39, v39
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v40, v40, v40
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v41, v41, v41
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v42, v42, v42
	v_max_f32_e32 v19, v19, v39
	v_max_f32_e32 v20, v20, v40
	v_max_f32_e32 v21, v21, v41
	v_max_f32_e32 v37, v37, v42
	ds_bpermute_b32 v39, v29, v19
	ds_bpermute_b32 v40, v29, v20
	ds_bpermute_b32 v41, v29, v21
	ds_bpermute_b32 v42, v29, v37
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v39, v39, v39
	s_waitcnt lgkmcnt(2)
	v_max_f32_e32 v40, v40, v40
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v41, v41, v41
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v42, v42, v42
	v_max_f32_e32 v19, v19, v39
	v_max_f32_e32 v20, v20, v40
	v_max_f32_e32 v21, v21, v41
	v_max_f32_e32 v45, v37, v42
	v_max_f32_e32 v40, v14, v19
	v_max_f32_e32 v39, v38, v20
	v_max_f32_e32 v38, v43, v21
	v_max_f32_e32 v37, v44, v45
	v_cndmask_b32_e64 v41, v40, v19, s[0:1]
	v_cndmask_b32_e64 v42, v39, v20, s[0:1]
	v_cndmask_b32_e64 v43, v38, v21, s[0:1]
	v_cndmask_b32_e64 v44, v37, v45, s[0:1]
	v_sub_f32_e32 v14, v16, v41
	v_sub_f32_e32 v16, v17, v42
	v_sub_f32_e32 v17, v18, v43
	v_sub_f32_e32 v18, v15, v44
	v_exp_f32_e32 v14, v14
	v_exp_f32_e32 v15, v16
	v_exp_f32_e32 v16, v17
	v_exp_f32_e32 v17, v18
	ds_bpermute_b32 v18, v26, v14
	ds_bpermute_b32 v19, v26, v15
	ds_bpermute_b32 v20, v26, v16
	ds_bpermute_b32 v21, v26, v17
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	ds_bpermute_b32 v18, v27, v14
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	ds_bpermute_b32 v19, v27, v15
	ds_bpermute_b32 v20, v27, v16
	ds_bpermute_b32 v21, v27, v17
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	ds_bpermute_b32 v18, v28, v14
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	ds_bpermute_b32 v19, v28, v15
	ds_bpermute_b32 v20, v28, v16
	ds_bpermute_b32 v21, v28, v17
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[18:19], v[14:15], v[18:19]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[14:15], v[16:17], v[20:21]
	ds_bpermute_b32 v20, v29, v18
	ds_bpermute_b32 v21, v29, v19
	ds_bpermute_b32 v16, v29, v14
	ds_bpermute_b32 v17, v29, v15
	s_cbranch_vccnz .LBB0_1
; %bb.5:                                ; %for.cond145.preheader
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_xor_b32 s4, s6, 1
	v_lshl_or_b32 v45, s4, 11, v2
	ds_write_b16 v45, v33
	ds_write_b16_d16_hi v45, v33 offset:256
	ds_write_b16 v45, v34 offset:512
	ds_write_b16_d16_hi v45, v34 offset:768
	ds_write_b16 v45, v35 offset:1024
	ds_write_b16_d16_hi v45, v35 offset:1280
	ds_write_b16 v45, v36 offset:1536
	ds_write_b16_d16_hi v45, v36 offset:1792
	s_branch .LBB0_1
.LBB0_6:                                ; %for.cond.cleanup45
	v_cmp_eq_u32_e32 vcc, 0, v24
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_8
; %bb.7:                                ; %for.cond167.preheader
	s_and_b64 s[0:1], s[2:3], exec
	v_or_b32_e32 v2, v23, v22
	s_cselect_b32 s1, s9, s11
	s_cselect_b32 s0, s8, s10
	v_lshlrev_b32_e32 v2, 2, v2
	global_load_dword v3, v2, s[0:1]
	v_max_f32_e32 v4, v4, v4
	v_max_f32_e32 v4, 0x116c2, v4
	v_log_f32_e32 v4, v4
	s_cselect_b32 s3, s17, s19
	s_cselect_b32 s2, s16, s18
	v_max_f32_e32 v0, v0, v0
	v_add_f32_e32 v4, v40, v4
	v_mul_f32_e32 v4, 0x3f317218, v4
	v_max_f32_e32 v0, 0x116c2, v0
	v_log_f32_e32 v0, v0
	v_max_f32_e32 v1, v1, v1
	v_max_f32_e32 v1, 0x116c2, v1
	v_log_f32_e32 v1, v1
	v_add_f32_e32 v0, v38, v0
	v_mul_f32_e32 v0, 0x3f317218, v0
	v_add_f32_e32 v1, v37, v1
	v_mul_f32_e32 v1, 0x3f317218, v1
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v3, 0.5, v3
	v_fmac_f32_e32 v3, -0.5, v4
	global_store_dword v2, v3, s[2:3]
	global_load_dword v3, v2, s[0:1] offset:4
	v_max_f32_e32 v4, v5, v5
	v_max_f32_e32 v4, 0x116c2, v4
	v_log_f32_e32 v4, v4
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v3, 0.5, v3
	v_add_f32_e32 v4, v39, v4
	v_mul_f32_e32 v4, 0x3f317218, v4
	v_fmac_f32_e32 v3, -0.5, v4
	global_store_dword v2, v3, s[2:3] offset:4
	global_load_dword v3, v2, s[0:1] offset:8
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v3, 0.5, v3
	v_fmac_f32_e32 v3, -0.5, v0
	global_store_dword v2, v3, s[2:3] offset:8
	global_load_dword v0, v2, s[0:1] offset:12
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v0, 0.5, v0
	v_fmac_f32_e32 v0, -0.5, v1
	global_store_dword v2, v0, s[2:3] offset:12
.LBB0_8:                                ; %if.end190
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel flash_sinkhorn_full
		.amdhsa_group_segment_fixed_size 4096
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
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 52
		.amdhsa_next_free_sgpr 25
		.amdhsa_accum_offset 48
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
	.size	flash_sinkhorn_full, .Lfunc_end0-flash_sinkhorn_full
                                        ; -- End function
	.set flash_sinkhorn_full.num_vgpr, 48
	.set flash_sinkhorn_full.num_agpr, 4
	.set flash_sinkhorn_full.numbered_sgpr, 25
	.set flash_sinkhorn_full.num_named_barrier, 0
	.set flash_sinkhorn_full.private_seg_size, 0
	.set flash_sinkhorn_full.uses_vcc, 1
	.set flash_sinkhorn_full.uses_flat_scratch, 0
	.set flash_sinkhorn_full.has_dyn_sized_stack, 0
	.set flash_sinkhorn_full.has_recursion, 0
	.set flash_sinkhorn_full.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1984
; TotalNumSgprs: 31
; NumVgprs: 48
; NumAgprs: 4
; TotalNumVgprs: 52
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 31
; NumVGPRsForWavesPerEU: 52
; AccumOffset: 48
; Occupancy: 8
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 11
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_2fa8f248d9224846,@object ; @__hip_cuid_2fa8f248d9224846
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_2fa8f248d9224846
__hip_cuid_2fa8f248d9224846:
	.byte	0                               ; 0x0
	.size	__hip_cuid_2fa8f248d9224846, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_2fa8f248d9224846
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     4
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           y.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           f_hat.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           g_hat.coerce
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           log_a.coerce
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           log_b.coerce
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           f_out.coerce
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           g_out.coerce
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           flash_sinkhorn_full
    .private_segment_fixed_size: 0
    .sgpr_count:     31
    .sgpr_spill_count: 0
    .symbol:         flash_sinkhorn_full.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     52
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
