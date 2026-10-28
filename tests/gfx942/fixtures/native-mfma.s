	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.text
	.protected	mfma_f32                ; -- Begin function mfma_f32
	.globl	mfma_f32
	.p2align	8
	.type	mfma_f32,@function
mfma_f32:                               ; @mfma_f32
; %bb.0:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v1, 2, v0
	v_lshlrev_b32_e32 v0, 4, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v2, v1, s[4:5]
	global_load_dword v3, v1, s[6:7]
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x4_f32 a[0:3], v2, v3, 0
	s_nop 9
	global_store_dwordx4 v0, a[0:3], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mfma_f32
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 4
		.amdhsa_reserve_vcc 0
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
	.size	mfma_f32, .Lfunc_end0-mfma_f32
                                        ; -- End function
	.set mfma_f32.num_vgpr, 4
	.set mfma_f32.num_agpr, 4
	.set mfma_f32.numbered_sgpr, 8
	.set mfma_f32.num_named_barrier, 0
	.set mfma_f32.private_seg_size, 0
	.set mfma_f32.uses_vcc, 0
	.set mfma_f32.uses_flat_scratch, 0
	.set mfma_f32.has_dyn_sized_stack, 0
	.set mfma_f32.has_recursion, 0
	.set mfma_f32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 72
; TotalNumSgprs: 14
; NumVgprs: 4
; NumAgprs: 4
; TotalNumVgprs: 8
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 8
; AccumOffset: 4
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 0
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.protected	mfma_f16                ; -- Begin function mfma_f16
	.globl	mfma_f16
	.p2align	8
	.type	mfma_f16,@function
mfma_f16:                               ; @mfma_f16
; %bb.0:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v1, 3, v0
	v_lshlrev_b32_e32 v0, 4, v0
	s_waitcnt lgkmcnt(0)
	global_load_dwordx2 v[2:3], v1, s[4:5]
	global_load_dwordx2 v[4:5], v1, s[6:7]
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x16_f16 a[0:3], v[2:3], v[4:5], 0
	s_nop 6
	global_store_dwordx4 v0, a[0:3], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mfma_f16
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 8
		.amdhsa_reserve_vcc 0
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
	.size	mfma_f16, .Lfunc_end1-mfma_f16
                                        ; -- End function
	.set mfma_f16.num_vgpr, 6
	.set mfma_f16.num_agpr, 4
	.set mfma_f16.numbered_sgpr, 8
	.set mfma_f16.num_named_barrier, 0
	.set mfma_f16.private_seg_size, 0
	.set mfma_f16.uses_vcc, 0
	.set mfma_f16.uses_flat_scratch, 0
	.set mfma_f16.has_dyn_sized_stack, 0
	.set mfma_f16.has_recursion, 0
	.set mfma_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 72
; TotalNumSgprs: 14
; NumVgprs: 6
; NumAgprs: 4
; TotalNumVgprs: 12
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 12
; AccumOffset: 8
; Occupancy: 8
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 1
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_9380e9d022798c2c,@object ; @__hip_cuid_9380e9d022798c2c
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_9380e9d022798c2c
__hip_cuid_9380e9d022798c2c:
	.byte	0                               ; 0x0
	.size	__hip_cuid_9380e9d022798c2c, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_9380e9d022798c2c
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     4
    .args:
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
    .max_flat_workgroup_size: 64
    .name:           mfma_f32
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         mfma_f32.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     4
    .args:
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
    .max_flat_workgroup_size: 64
    .name:           mfma_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         mfma_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     12
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
