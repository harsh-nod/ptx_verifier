	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	matrix_cross_wave_publication ; -- Begin function matrix_cross_wave_publication
	.globl	matrix_cross_wave_publication
	.p2align	8
	.type	matrix_cross_wave_publication,@function
matrix_cross_wave_publication:          ; @matrix_cross_wave_publication
; %bb.0:
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB0_3
; %bb.1:
	v_or_b32_e32 v1, 0xffffffc0, v0
	v_dual_lshlrev_b32 v2, 2, v0 :: v_dual_mov_b32 v4, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_add_nc_u32 v1, 64, v1 :: v_dual_mov_b32 v3, s3
	v_cmp_lt_u32_e32 vcc_lo, 0xbf, v1
	flat_store_b32 v[2:3], v4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 0x100, v2
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB0_2
.LBB0_3:
	s_or_b32 exec_lo, exec_lo, s4
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b32 s4, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_5
; %bb.4:
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshlrev_b32 v2, 4, v0
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v29, s7 :: v_dual_bitop2_b32 v11, 15, v0 bitop3:0x40
	v_and_b32_e32 v5, 8, v1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_and_b32_e32 v2, 0xf0, v2
	v_dual_lshlrev_b32 v1, 6, v1 :: v_dual_bitop2_b32 v10, 7, v1 bitop3:0x54
	v_dual_mov_b32 v27, s7 :: v_dual_lshlrev_b32 v38, 2, v11
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_or_b32_e32 v6, v5, v2
	v_dual_mov_b32 v33, s7 :: v_dual_bitop2_b32 v7, v10, v2 bitop3:0x54
	v_dual_mov_b32 v35, s7 :: v_dual_mov_b32 v37, s7
	s_delay_alu instid0(VALU_DEP_3)
	v_dual_mov_b32 v31, s7 :: v_dual_lshlrev_b32 v8, 1, v6
	v_or_b32_e32 v11, 1, v5
	s_wait_kmcnt 0x0
	s_clause 0x2
	global_load_u16 v18, v7, s[0:1] scale_offset
	global_load_u16 v19, v6, s[0:1] offset:12 scale_offset
	global_load_b96 v[2:4], v8, s[0:1]
	s_wait_xcnt 0x1
	v_dual_mov_b32 v6, 0 :: v_dual_bitop2_b32 v12, 2, v5 bitop3:0x54
	v_or_b32_e32 v13, 3, v5
	v_or_b32_e32 v20, 4, v5
	v_or_b32_e32 v21, 5, v5
	v_or_b32_e32 v22, 6, v5
	v_cvt_f32_ubyte0_e32 v23, v10
	v_add_nc_u32_e32 v10, 1, v10
	v_cvt_f32_ubyte0_e32 v11, v11
	v_cvt_f32_ubyte0_e32 v12, v12
	v_cvt_f32_ubyte0_e32 v13, v13
	v_cvt_f32_ubyte0_e32 v20, v20
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v22, v22
	v_cvt_f32_ubyte0_e32 v24, v10
	s_wait_xcnt 0x0
	v_dual_mov_b32 v7, v6 :: v_dual_mov_b32 v8, v6
	v_dual_mov_b32 v9, v6 :: v_dual_mov_b32 v14, v6
	v_dual_mov_b32 v15, v6 :: v_dual_mov_b32 v16, v6
	v_mov_b32_e32 v17, v6
	v_lshl_or_b32 v26, v5, 6, v38
	v_cvt_pk_f16_f32 v10, v11, v12
	v_cvt_pk_f16_f32 v11, v13, v20
	v_cvt_pk_f16_f32 v12, v21, v22
	v_cvt_pk_f16_f32 v13, v23, v24
	v_or_b32_e32 v28, 64, v26
	v_or_b32_e32 v30, 0x80, v26
	v_or_b32_e32 v32, 0xc0, v26
	v_or_b32_e32 v34, 0x100, v26
	v_or_b32_e32 v36, 0x140, v26
	s_wait_loadcnt 0x1
	v_perm_b32 v5, v18, v19, 0x5040100
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	flat_store_b32 v[26:27], v18 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v[28:29], v19 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x1
	v_or_b32_e32 v26, 0x180, v26
	flat_store_b32 v[30:31], v20 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v[32:33], v21 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v[34:35], v22 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v[36:37], v23 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b32 v[26:27], v24 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_or3_b32 v26, v1, v38, 0x1c0
	flat_store_b32 v[26:27], v25 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_5:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB0_7
; %bb.6:
	s_mov_b64 s[0:1], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v1, s1 :: v_dual_bitop2_b32 v4, 31, v0 bitop3:0x40
	v_dual_mov_b32 v3, s1 :: v_dual_lshlrev_b32 v0, 2, v4
	flat_load_b32 v5, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_or_b32_e32 v2, 0x80, v0
	s_wait_dscnt 0x0
	global_store_b32 v4, v5, s[2:3] scale_offset
	flat_load_b32 v5, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0x100, v0
	s_wait_dscnt 0x0
	global_store_b32 v4, v5, s[2:3] offset:128 scale_offset
	flat_load_b32 v5, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0x180, v0
	s_wait_dscnt 0x0
	global_store_b32 v4, v5, s[2:3] offset:256 scale_offset
	flat_load_b32 v5, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0x200, v0
	s_wait_dscnt 0x0
	global_store_b32 v4, v5, s[2:3] offset:384 scale_offset
	flat_load_b32 v5, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0x280, v0
	s_wait_dscnt 0x0
	global_store_b32 v4, v5, s[2:3] offset:512 scale_offset
	flat_load_b32 v5, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_or_b32_e32 v2, 0x300, v0
	v_or_b32_e32 v0, 0x380, v0
	s_wait_dscnt 0x0
	global_store_b32 v4, v5, s[2:3] offset:640 scale_offset
	flat_load_b32 v2, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v4, v2, s[2:3] offset:768 scale_offset
	flat_load_b32 v0, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v4, v0, s[2:3] offset:896 scale_offset
.LBB0_7:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_cross_wave_publication
		.amdhsa_group_segment_fixed_size 1024
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 39
		.amdhsa_next_free_sgpr 8
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 9
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
	.size	matrix_cross_wave_publication, .Lfunc_end0-matrix_cross_wave_publication
                                        ; -- End function
	.set matrix_cross_wave_publication.num_vgpr, 39
	.set matrix_cross_wave_publication.num_agpr, 0
	.set matrix_cross_wave_publication.numbered_sgpr, 8
	.set matrix_cross_wave_publication.num_named_barrier, 0
	.set matrix_cross_wave_publication.private_seg_size, 0
	.set matrix_cross_wave_publication.uses_vcc, 1
	.set matrix_cross_wave_publication.uses_flat_scratch, 0
	.set matrix_cross_wave_publication.has_dyn_sized_stack, 0
	.set matrix_cross_wave_publication.has_recursion, 0
	.set matrix_cross_wave_publication.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1064
; TotalNumSgprs: 10
; NumVgprs: 39
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 1024 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 39
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
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
	.type	__hip_cuid_4604fa8522ccdd6a,@object ; @__hip_cuid_4604fa8522ccdd6a
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_4604fa8522ccdd6a
__hip_cuid_4604fa8522ccdd6a:
	.byte	0                               ; 0x0
	.size	__hip_cuid_4604fa8522ccdd6a, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_4604fa8522ccdd6a
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
    .group_segment_fixed_size: 1024
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           matrix_cross_wave_publication
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matrix_cross_wave_publication.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     39
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
