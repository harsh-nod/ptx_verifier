	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	attention_small         ; -- Begin function attention_small
	.globl	attention_small
	.p2align	8
	.type	attention_small,@function
attention_small:                        ; @attention_small
; %bb.0:
	v_mbcnt_lo_u32_b32 v6, -1, 0
	v_dual_mov_b32 v1, 0 :: v_dual_lshlrev_b32 v2, 2, v0
	v_lshlrev_b32_e32 v0, 7, v0
	s_load_b256 s[4:11], s[0:1], 0x0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_xor_b32_e32 v3, 16, v6
	v_xor_b32_e32 v7, 2, v6
	s_wait_xcnt 0x0
	s_mov_b64 s[0:1], 0
	v_cmp_gt_i32_e32 vcc_lo, 32, v3
	v_dual_cndmask_b32 v9, v6, v3, vcc_lo :: v_dual_bitop2_b32 v4, 8, v6 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_cmp_gt_i32_e32 vcc_lo, 32, v4
	v_dual_mov_b32 v3, v1 :: v_dual_bitop2_b32 v5, 4, v6 bitop3:0x14
	v_cndmask_b32_e32 v4, v6, v4, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v5
	v_dual_lshlrev_b32 v10, 2, v9 :: v_dual_bitop2_b32 v8, 1, v6 bitop3:0x14
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_cndmask_b32 v12, v6, v5 :: v_dual_lshlrev_b32 v11, 2, v4
	v_cmp_gt_i32_e32 vcc_lo, 32, v7
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[4:5], s[6:7], v[0:1]
	v_cndmask_b32_e32 v13, v6, v7, vcc_lo
	v_cmp_gt_i32_e32 vcc_lo, 32, v8
	v_cndmask_b32_e32 v14, v6, v8, vcc_lo
	v_add_nc_u64_e32 v[6:7], s[8:9], v[2:3]
	v_add_nc_u64_e32 v[8:9], s[10:11], v[2:3]
	v_dual_lshlrev_b32 v0, 2, v12 :: v_dual_lshlrev_b32 v3, 2, v13
	s_delay_alu instid0(VALU_DEP_4)
	v_lshlrev_b32_e32 v12, 2, v14
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	s_wait_xcnt 0x21
	s_add_nc_u64 s[2:3], s[4:5], s[0:1]
	s_clause 0x5
	global_load_b128 v[14:17], v[4:5], off offset:48
	global_load_b128 v[18:21], v[4:5], off offset:32
	global_load_b128 v[22:25], v[4:5], off offset:16
	global_load_b128 v[26:29], v[4:5], off
	global_load_b128 v[30:33], v[4:5], off offset:112
	global_load_b128 v[34:37], v[4:5], off offset:96
	s_clause 0x3
	global_load_b128 v[38:41], v1, s[2:3] offset:96
	global_load_b128 v[42:45], v1, s[2:3] offset:16
	global_load_b128 v[46:49], v1, s[2:3]
	global_load_b128 v[50:53], v1, s[2:3] offset:112
	s_wait_loadcnt 0x3
	v_pk_mul_f32 v[54:55], v[38:39], v[34:35]
	v_pk_mul_f32 v[56:57], v[40:41], v[36:37]
	global_load_b128 v[34:37], v1, s[2:3] offset:32
	s_wait_loadcnt 0x1
	v_pk_mul_f32 v[50:51], v[50:51], v[30:31]
	v_pk_mul_f32 v[52:53], v[52:53], v[32:33]
	global_load_b128 v[30:33], v1, s[2:3] offset:48
	global_load_b128 v[38:41], v[4:5], off offset:80
	v_fma_f32 v13, v46, v26, 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v47, v27
	v_fmac_f32_e32 v13, v48, v28
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v49, v29
	global_load_b128 v[26:29], v[4:5], off offset:64
	global_load_b128 v[46:49], v1, s[2:3] offset:64
	v_fmac_f32_e32 v13, v42, v22
	v_fmac_f32_e32 v13, v43, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v44, v24
	v_fmac_f32_e32 v13, v45, v25
	global_load_b128 v[22:25], v1, s[2:3] offset:80
	s_wait_loadcnt 0x5
	v_fmac_f32_e32 v13, v34, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v35, v19
	v_fmac_f32_e32 v13, v36, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v37, v21
	s_wait_loadcnt 0x4
	v_fmac_f32_e32 v13, v30, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v31, v15
	v_fmac_f32_e32 v13, v32, v16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v33, v17
	s_wait_loadcnt 0x1
	v_fmac_f32_e32 v13, v46, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v47, v27
	v_fmac_f32_e32 v13, v48, v28
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v49, v29
	s_wait_loadcnt 0x0
	v_fmac_f32_e32 v13, v22, v38
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v23, v39
	v_fmac_f32_e32 v13, v24, v40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v25, v41
	v_add_f32_e32 v13, v13, v54
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v55
	v_add_f32_e32 v13, v13, v56
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v57
	v_add_f32_e32 v13, v13, v50
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v51
	v_add_f32_e32 v13, v13, v52
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v53
	v_mul_f32_e32 v13, 0x3e000000, v13
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v13, 0x3fb8aa3b, v13
	v_exp_f32_e32 v13, v13
	ds_bpermute_b32 v14, v10, v13
	s_wait_dscnt 0x0
	v_nop
	v_add_f32_e32 v14, v13, v14
	ds_bpermute_b32 v15, v11, v14
	s_wait_dscnt 0x0
	v_add_f32_e32 v14, v14, v15
	ds_bpermute_b32 v15, v0, v14
	s_wait_dscnt 0x0
	v_add_f32_e32 v14, v14, v15
	ds_bpermute_b32 v15, v3, v14
	s_wait_dscnt 0x0
	v_add_f32_e32 v14, v14, v15
	ds_bpermute_b32 v15, v12, v14
	s_wait_dscnt 0x0
	v_add_f32_e32 v14, v14, v15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)
	v_rcp_f32_e32 v14, v14
	v_nop
	v_mul_f32_e32 v13, v13, v14
	ds_store_b32 v2, v13
	s_wait_dscnt 0x0
	; wave barrier
	s_clause 0x1f
	global_load_b32 v13, v[6:7], off
	global_load_b32 v22, v[6:7], off offset:128
	global_load_b32 v23, v[6:7], off offset:256
	global_load_b32 v24, v[6:7], off offset:384
	global_load_b32 v25, v[6:7], off offset:512
	global_load_b32 v38, v[6:7], off offset:640
	global_load_b32 v39, v[6:7], off offset:768
	global_load_b32 v40, v[6:7], off offset:896
	global_load_b32 v41, v[6:7], off offset:1024
	global_load_b32 v42, v[6:7], off offset:1152
	global_load_b32 v43, v[6:7], off offset:1280
	global_load_b32 v44, v[6:7], off offset:1408
	global_load_b32 v45, v[6:7], off offset:1536
	global_load_b32 v46, v[6:7], off offset:1664
	global_load_b32 v47, v[6:7], off offset:1792
	global_load_b32 v48, v[6:7], off offset:1920
	global_load_b32 v49, v[6:7], off offset:2048
	global_load_b32 v50, v[6:7], off offset:2176
	global_load_b32 v51, v[6:7], off offset:2304
	global_load_b32 v26, v[6:7], off offset:2560
	global_load_b32 v27, v[6:7], off offset:2688
	global_load_b32 v52, v[6:7], off offset:2432
	global_load_b32 v28, v[6:7], off offset:2816
	global_load_b32 v29, v[6:7], off offset:2944
	global_load_b32 v30, v[6:7], off offset:3072
	global_load_b32 v31, v[6:7], off offset:3200
	global_load_b32 v32, v[6:7], off offset:3328
	global_load_b32 v33, v[6:7], off offset:3456
	global_load_b32 v34, v[6:7], off offset:3584
	global_load_b32 v35, v[6:7], off offset:3712
	global_load_b32 v36, v[6:7], off offset:3840
	global_load_b32 v37, v[6:7], off offset:3968
	ds_load_b128 v[14:17], v1
	ds_load_b128 v[18:21], v1 offset:16
	s_wait_loadcnt_dscnt 0x1f01
	v_fma_f32 v13, v14, v13, 0
	s_wait_loadcnt 0x1e
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v15, v22
	s_wait_loadcnt 0x1d
	v_fmac_f32_e32 v13, v16, v23
	s_wait_loadcnt 0x1c
	s_delay_alu instid0(VALU_DEP_1)
	v_fmac_f32_e32 v13, v17, v24
	ds_load_b128 v[14:17], v1 offset:32
	s_wait_loadcnt_dscnt 0x1b01
	v_fmac_f32_e32 v13, v18, v25
	ds_load_b128 v[22:25], v1 offset:80
	s_wait_loadcnt 0x1a
	v_fmac_f32_e32 v13, v19, v38
	s_wait_loadcnt 0x19
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v20, v39
	s_wait_loadcnt 0x18
	v_fmac_f32_e32 v13, v21, v40
	ds_load_b128 v[18:21], v1 offset:48
	s_wait_loadcnt_dscnt 0x1702
	v_fmac_f32_e32 v13, v14, v41
	s_wait_loadcnt 0x16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v15, v42
	s_wait_loadcnt 0x15
	v_fmac_f32_e32 v13, v16, v43
	s_wait_loadcnt 0x14
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v17, v44
	ds_load_b128 v[14:17], v1 offset:64
	s_wait_loadcnt_dscnt 0x1301
	v_fmac_f32_e32 v13, v18, v45
	s_wait_loadcnt 0x12
	v_fmac_f32_e32 v13, v19, v46
	s_wait_loadcnt 0x11
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v20, v47
	s_wait_loadcnt 0x10
	v_fmac_f32_e32 v13, v21, v48
	ds_load_b128 v[18:21], v1 offset:96
	s_wait_loadcnt_dscnt 0xf01
	v_fmac_f32_e32 v13, v14, v49
	s_wait_loadcnt 0xe
	s_delay_alu instid0(VALU_DEP_1)
	v_fmac_f32_e32 v13, v15, v50
	s_wait_loadcnt 0xb
	v_pk_mul_f32 v[14:15], v[22:23], v[26:27]
	s_wait_loadcnt 0x8
	v_pk_mul_f32 v[22:23], v[24:25], v[28:29]
	v_fmac_f32_e32 v13, v16, v51
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_fmac_f32_e32 v13, v17, v52
	v_add_f32_e32 v13, v13, v14
	s_delay_alu instid0(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v15
	ds_load_b128 v[14:17], v1 offset:112
	s_wait_loadcnt_dscnt 0x601
	v_pk_mul_f32 v[18:19], v[18:19], v[30:31]
	s_wait_loadcnt 0x4
	v_pk_mul_f32 v[20:21], v[20:21], v[32:33]
	v_add_f32_e32 v13, v13, v22
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v23
	v_add_f32_e32 v13, v13, v18
	s_delay_alu instid0(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v19
	s_wait_loadcnt_dscnt 0x200
	v_pk_mul_f32 v[14:15], v[14:15], v[34:35]
	s_wait_loadcnt 0x0
	v_pk_mul_f32 v[16:17], v[16:17], v[36:37]
	v_add_f32_e32 v13, v13, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v21
	v_add_f32_e32 v13, v13, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	v_add_f32_e32 v13, v13, v15
	v_add_nc_u64_e32 v[14:15], s[0:1], v[8:9]
	s_add_nc_u64 s[0:1], s[0:1], 0x80
	s_cmp_lg_u32 s0, 0x800
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_f32_e32 v13, v13, v16
	v_add_f32_e32 v13, v13, v17
	global_store_b32 v[14:15], v13, off
	s_wait_storecnt 0x0
	; wave barrier
	s_cbranch_scc1 .LBB0_1
; %bb.2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel attention_small
		.amdhsa_group_segment_fixed_size 128
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
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 58
		.amdhsa_next_free_sgpr 12
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 13
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
	.size	attention_small, .Lfunc_end0-attention_small
                                        ; -- End function
	.set attention_small.num_vgpr, 58
	.set attention_small.num_agpr, 0
	.set attention_small.numbered_sgpr, 12
	.set attention_small.num_named_barrier, 0
	.set attention_small.private_seg_size, 0
	.set attention_small.uses_vcc, 1
	.set attention_small.uses_flat_scratch, 0
	.set attention_small.has_dyn_sized_stack, 0
	.set attention_small.has_recursion, 0
	.set attention_small.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1588
; TotalNumSgprs: 14
; NumVgprs: 58
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 58
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_d48429d4b55c1ac1,@object ; @__hip_cuid_d48429d4b55c1ac1
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_d48429d4b55c1ac1
__hip_cuid_d48429d4b55c1ac1:
	.byte	0                               ; 0x0
	.size	__hip_cuid_d48429d4b55c1ac1, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_d48429d4b55c1ac1
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
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           attention_small
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         attention_small.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     58
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
