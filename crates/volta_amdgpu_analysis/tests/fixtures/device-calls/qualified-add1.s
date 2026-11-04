	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.hidden	qualified_leaf_add1             ; -- Begin function qualified_leaf_add1
	.globl	qualified_leaf_add1
	.p2align	2
	.type	qualified_leaf_add1,@function
qualified_leaf_add1:                    ; @qualified_leaf_add1
; %bb.0:                                ; %entry
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	v_add_f32_e32 v0, 1.0, v0
	s_setpc_b64 s[30:31]
.Lfunc_end0:
	.size	qualified_leaf_add1, .Lfunc_end0-qualified_leaf_add1
                                        ; -- End function
	.set qualified_leaf_add1.num_vgpr, 1
	.set qualified_leaf_add1.num_agpr, 0
	.set qualified_leaf_add1.numbered_sgpr, 32
	.set qualified_leaf_add1.num_named_barrier, 0
	.set qualified_leaf_add1.private_seg_size, 0
	.set qualified_leaf_add1.uses_vcc, 0
	.set qualified_leaf_add1.uses_flat_scratch, 0
	.set qualified_leaf_add1.has_dyn_sized_stack, 0
	.set qualified_leaf_add1.has_recursion, 0
	.set qualified_leaf_add1.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 12
; TotalNumSgprs: 38
; NumVgprs: 1
; NumAgprs: 0
; TotalNumVgprs: 1
; ScratchSize: 0
; MemoryBound: 0
	.text
	.globl	qualified_leaf_add1_copy64      ; -- Begin function qualified_leaf_add1_copy64
	.p2align	8
	.type	qualified_leaf_add1_copy64,@function
qualified_leaf_add1_copy64:             ; @qualified_leaf_add1_copy64
; %bb.0:                                ; %entry
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	v_and_b32_e32 v1, 0x3ff, v0
	v_lshlrev_b32_e32 v2, 2, v1
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, qualified_leaf_add1@rel32@lo+4
	s_addc_u32 s1, s1, qualified_leaf_add1@rel32@hi+12
	s_mov_b32 s12, s2
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v2, s[10:11]
	s_mov_b32 s13, s3
	s_mov_b32 s14, s4
	v_mov_b32_e32 v31, v0
	s_mov_b32 s32, 0
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v0, v1
	s_swappc_b64 s[30:31], s[0:1]
	global_store_dword v2, v0, s[8:9]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qualified_leaf_add1_copy64
		.amdhsa_group_segment_fixed_size 0
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
		.amdhsa_uses_dynamic_stack 1
		.amdhsa_enable_private_segment 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr 32
		.amdhsa_next_free_sgpr 33
		.amdhsa_accum_offset 32
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
	.size	qualified_leaf_add1_copy64, .Lfunc_end1-qualified_leaf_add1_copy64
                                        ; -- End function
	.set qualified_leaf_add1_copy64.num_vgpr, max(32, qualified_leaf_add1.num_vgpr)
	.set qualified_leaf_add1_copy64.num_agpr, max(0, qualified_leaf_add1.num_agpr)
	.set qualified_leaf_add1_copy64.numbered_sgpr, max(33, qualified_leaf_add1.numbered_sgpr)
	.set qualified_leaf_add1_copy64.num_named_barrier, max(0, qualified_leaf_add1.num_named_barrier)
	.set qualified_leaf_add1_copy64.private_seg_size, 0+max(qualified_leaf_add1.private_seg_size)
	.set qualified_leaf_add1_copy64.uses_vcc, or(0, qualified_leaf_add1.uses_vcc)
	.set qualified_leaf_add1_copy64.uses_flat_scratch, or(0, qualified_leaf_add1.uses_flat_scratch)
	.set qualified_leaf_add1_copy64.has_dyn_sized_stack, or(0, qualified_leaf_add1.has_dyn_sized_stack)
	.set qualified_leaf_add1_copy64.has_recursion, or(1, qualified_leaf_add1.has_recursion)
	.set qualified_leaf_add1_copy64.has_indirect_call, or(0, qualified_leaf_add1.has_indirect_call)
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 96
; TotalNumSgprs: 39
; NumVgprs: 32
; NumAgprs: 0
; TotalNumVgprs: 32
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 4
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 39
; NumVGPRsForWavesPerEU: 32
; AccumOffset: 32
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 1
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 7
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 1
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 32
	.text
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           out
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           in
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .max_flat_workgroup_size: 64
    .name:           qualified_leaf_add1_copy64
    .private_segment_fixed_size: 0
    .sgpr_count:     39
    .sgpr_spill_count: 0
    .symbol:         qualified_leaf_add1_copy64.kd
    .uses_dynamic_stack: true
    .vgpr_count:     32
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
