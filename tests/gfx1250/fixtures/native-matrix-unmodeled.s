	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	matrix_b_reuse_boundary ; -- Begin function matrix_b_reuse_boundary
	.globl	matrix_b_reuse_boundary
	.p2align	8
	.type	matrix_b_reuse_boundary,@function
matrix_b_reuse_boundary:                ; @matrix_b_reuse_boundary
; %bb.0:
	s_load_b128 s[4:7], s[0:1], 0x0
	v_lshlrev_b32_e32 v24, 5, v0
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x10
	s_wait_kmcnt 0x0
	s_clause 0x3
	global_load_b128 v[4:7], v24, s[4:5] offset:16
	global_load_b128 v[12:15], v24, s[6:7] offset:16
	global_load_b128 v[0:3], v24, s[4:5]
	global_load_b128 v[8:11], v24, s[6:7]
	s_wait_loadcnt 0x0
	v_wmma_f32_16x16x32_f16 v[16:23], v[0:7], v[8:15], 0 matrix_b_reuse
	s_clause 0x1
	global_store_b128 v24, v[20:23], s[0:1] offset:16
	global_store_b128 v24, v[16:19], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_b_reuse_boundary
		.amdhsa_group_segment_fixed_size 0
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
		.amdhsa_next_free_vgpr 25
		.amdhsa_next_free_sgpr 8
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 1
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
	.size	matrix_b_reuse_boundary, .Lfunc_end0-matrix_b_reuse_boundary
                                        ; -- End function
	.set matrix_b_reuse_boundary.num_vgpr, 25
	.set matrix_b_reuse_boundary.num_agpr, 0
	.set matrix_b_reuse_boundary.numbered_sgpr, 8
	.set matrix_b_reuse_boundary.num_named_barrier, 0
	.set matrix_b_reuse_boundary.private_seg_size, 0
	.set matrix_b_reuse_boundary.uses_vcc, 0
	.set matrix_b_reuse_boundary.uses_flat_scratch, 0
	.set matrix_b_reuse_boundary.has_dyn_sized_stack, 0
	.set matrix_b_reuse_boundary.has_recursion, 0
	.set matrix_b_reuse_boundary.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 124
; TotalNumSgprs: 8
; NumVgprs: 25
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 25
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
	.type	__hip_cuid_cb32e1f9fa012840,@object ; @__hip_cuid_cb32e1f9fa012840
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_cb32e1f9fa012840
__hip_cuid_cb32e1f9fa012840:
	.byte	0                               ; 0x0
	.size	__hip_cuid_cb32e1f9fa012840, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_cb32e1f9fa012840
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           matrix_b_reuse_boundary
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_b_reuse_boundary.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     25
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
