	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	gemm_pipeline_f16       ; -- Begin function gemm_pipeline_f16
	.globl	gemm_pipeline_f16
	.p2align	8
	.type	gemm_pipeline_f16,@function
gemm_pipeline_f16:                      ; @gemm_pipeline_f16
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	v_dual_lshlrev_b32 v20, 1, v0 :: v_dual_bitop2_b32 v1, 31, v0 bitop3:0x40
	v_or_b32_e32 v21, 0xffffffc0, v0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 0
	s_delay_alu instid0(VALU_DEP_1)
	v_dual_mov_b32 v2, v20 :: v_dual_mov_b32 v3, v21
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_and_or_b32 v4, 0x7c0, v2, v1
	v_add_nc_u32_e32 v3, 64, v3
	s_wait_kmcnt 0x0
	global_load_u16 v4, v4, s[4:5] scale_offset
	v_cmp_lt_u32_e32 vcc_lo, 0x3bf, v3
	s_or_b32 s0, vcc_lo, s0
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v4
	v_add_nc_u32_e32 v2, 0x80, v2
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s0
	s_cbranch_execnz .LBB0_1
; %bb.2:
	s_or_b32 exec_lo, exec_lo, s0
	v_cmp_gt_u32_e32 vcc_lo, 0x200, v0
	v_and_or_b32 v23, v20, 64, v1
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB0_11
; %bb.3:
	global_load_u16 v3, v23, s[6:7] scale_offset
	v_lshlrev_b32_e32 v2, 1, v0
	s_mov_b32 s8, exec_lo
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:4096
	v_cmpx_gt_u32_e32 0x1c0, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.4:
	v_lshl_or_b32 v3, v0, 1, 0x80
	v_or_b32_e32 v2, 0x1000, v2
	s_mov_b32 s8, exec_lo
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v3, 0xc0, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:128
	v_cmpx_gt_u32_e32 0x180, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.5:
	v_lshl_or_b32 v3, v0, 1, 0x100
	s_mov_b32 s8, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x140, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:256
	v_cmpx_gt_u32_e32 0x140, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.6:
	v_lshl_or_b32 v3, v0, 1, 0x180
	s_mov_b32 s8, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x1c0, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:384
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.7:
	v_lshl_or_b32 v3, v0, 1, 0x200
	s_mov_b32 s8, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x240, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:512
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.8:
	v_lshl_or_b32 v3, v0, 1, 0x280
	s_mov_b32 s8, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x2c0, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:640
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.9:
	v_lshl_or_b32 v3, v0, 1, 0x300
	s_mov_b32 s8, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x340, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:768
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s8, exec_lo, s8
	s_cbranch_execz .LBB0_11
; %bb.10:
	v_lshl_or_b32 v3, v0, 1, 0x380
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v3, 0x3c0, v3, v1
	global_load_u16 v3, v3, s[6:7] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v2, v3 offset:896
.LBB0_11:
	s_or_b32 exec_lo, exec_lo, s1
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_lshrrev_b32 v18, 5, v0
	v_lshlrev_b32_e32 v3, 6, v0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_and_b32_e32 v19, 8, v2
	v_lshlrev_b32_e32 v2, 10, v18
	v_and_b32_e32 v3, 0x3c0, v3
	s_barrier_wait -1
	v_lshlrev_b32_e32 v4, 1, v19
	s_mov_b32 s1, 0
	s_delay_alu instid0(VALU_DEP_1)
	v_or3_b32 v22, v2, v3, v4
	v_or_b32_e32 v24, v3, v4
	ds_load_b128 v[2:5], v22
	ds_load_b128 v[6:9], v22 offset:32
	ds_load_b128 v[10:13], v24 offset:4096
	ds_load_b128 v[14:17], v24 offset:4128
	v_or_b32_e32 v24, 0x1000, v24
.LBB0_12:                               ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v25, 0x7c0, v20, v1
	v_add_nc_u32_e32 v21, 64, v21
	global_load_u16 v25, v25, s[4:5] offset:64 scale_offset
	v_cmp_lt_u32_e64 s0, 0x3bf, v21
	s_or_b32 s1, s0, s1
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v25 offset:2048
	v_add_nc_u32_e32 v20, 0x80, v20
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB0_12
; %bb.13:
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_22
; %bb.14:
	global_load_u16 v21, v23, s[6:7] offset:64 scale_offset
	v_lshlrev_b32_e32 v20, 1, v0
	s_mov_b32 s1, exec_lo
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:5120
	v_cmpx_gt_u32_e32 0x1c0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.15:
	v_lshl_or_b32 v21, v0, 1, 0x80
	v_or_b32_e32 v20, 0x1000, v20
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_2)
	v_and_or_b32 v21, 0xc0, v21, v1
	global_load_u16 v21, v21, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:1152
	v_cmpx_gt_u32_e32 0x180, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.16:
	v_lshl_or_b32 v21, v0, 1, 0x100
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v21, 0x140, v21, v1
	global_load_u16 v21, v21, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:1280
	v_cmpx_gt_u32_e32 0x140, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.17:
	v_lshl_or_b32 v21, v0, 1, 0x180
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v21, 0x1c0, v21, v1
	global_load_u16 v21, v21, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:1408
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.18:
	v_lshl_or_b32 v21, v0, 1, 0x200
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v21, 0x240, v21, v1
	global_load_u16 v21, v21, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:1536
	v_cmpx_gt_u32_e32 0xc0, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.19:
	v_lshl_or_b32 v21, v0, 1, 0x280
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v21, 0x2c0, v21, v1
	global_load_u16 v21, v21, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:1664
	v_cmpx_gt_u32_e32 0x80, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.20:
	v_lshl_or_b32 v21, v0, 1, 0x300
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v21, 0x340, v21, v1
	global_load_u16 v21, v21, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v21 offset:1792
	v_cmpx_gt_u32_e32 64, v0
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_22
; %bb.21:
	v_lshl_or_b32 v21, v0, 1, 0x380
	s_delay_alu instid0(VALU_DEP_1)
	v_and_or_b32 v1, 0x3c0, v21, v1
	global_load_u16 v1, v1, s[6:7] offset:64 scale_offset
	s_wait_loadcnt 0x0
	ds_store_b16 v20, v1 offset:1920
.LBB0_22:
	s_or_b32 exec_lo, exec_lo, s0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	ds_load_b128 v[26:29], v24 offset:1024
	ds_load_b128 v[30:33], v24 offset:1056
	ds_load_b128 v[34:37], v22 offset:2048
	ds_load_b128 v[38:41], v22 offset:2080
	v_wmma_f32_16x16x32_f16 v[42:49], v[2:9], v[10:17], 0
	v_dual_lshlrev_b32 v1, 4, v19 :: v_dual_bitop2_b32 v0, 15, v0 bitop3:0x40
	v_nop
	v_nop
	v_nop
	v_lshlrev_b32_e32 v2, 8, v18
	s_delay_alu instid0(VALU_DEP_1)
	v_or3_b32 v0, v2, v1, v0
	s_wait_dscnt 0x0
	v_wmma_f32_16x16x32_f16 v[42:49], v[34:41], v[26:33], v[42:49]
	s_clause 0x7
	global_store_b32 v0, v42, s[2:3] scale_offset
	global_store_b32 v0, v43, s[2:3] offset:64 scale_offset
	global_store_b32 v0, v44, s[2:3] offset:128 scale_offset
	global_store_b32 v0, v45, s[2:3] offset:192 scale_offset
	global_store_b32 v0, v46, s[2:3] offset:256 scale_offset
	global_store_b32 v0, v47, s[2:3] offset:320 scale_offset
	global_store_b32 v0, v48, s[2:3] offset:384 scale_offset
	global_store_b32 v0, v49, s[2:3] offset:448 scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel gemm_pipeline_f16
		.amdhsa_group_segment_fixed_size 6144
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
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 50
		.amdhsa_next_free_sgpr 9
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
	.size	gemm_pipeline_f16, .Lfunc_end0-gemm_pipeline_f16
                                        ; -- End function
	.set gemm_pipeline_f16.num_vgpr, 50
	.set gemm_pipeline_f16.num_agpr, 0
	.set gemm_pipeline_f16.numbered_sgpr, 9
	.set gemm_pipeline_f16.num_named_barrier, 0
	.set gemm_pipeline_f16.private_seg_size, 0
	.set gemm_pipeline_f16.uses_vcc, 1
	.set gemm_pipeline_f16.uses_flat_scratch, 0
	.set gemm_pipeline_f16.has_dyn_sized_stack, 0
	.set gemm_pipeline_f16.has_recursion, 0
	.set gemm_pipeline_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1660
; TotalNumSgprs: 11
; NumVgprs: 50
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 6144 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 11
; NumVGPRsForWavesPerEU: 50
; NamedBarCnt: 0
; Occupancy: 14
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
	.type	__hip_cuid_f7b5d2d5cfeb25f0,@object ; @__hip_cuid_f7b5d2d5cfeb25f0
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_f7b5d2d5cfeb25f0
__hip_cuid_f7b5d2d5cfeb25f0:
	.byte	0                               ; 0x0
	.size	__hip_cuid_f7b5d2d5cfeb25f0, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_f7b5d2d5cfeb25f0
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
    .group_segment_fixed_size: 6144
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           gemm_pipeline_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     11
    .sgpr_spill_count: 0
    .symbol:         gemm_pipeline_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     50
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
