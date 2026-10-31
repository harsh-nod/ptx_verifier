	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.hidden	leaf                            ; -- Begin function leaf
	.globl	leaf
	.p2align	2
	.type	leaf,@function
leaf:                                   ; @leaf
; %bb.0:                                ; %entry
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	v_add_u32_e32 v0, 7, v0
	s_setpc_b64 s[30:31]
.Lfunc_end0:
	.size	leaf, .Lfunc_end0-leaf
                                        ; -- End function
	.set leaf.num_vgpr, 1
	.set leaf.num_agpr, 0
	.set leaf.numbered_sgpr, 32
	.set leaf.num_named_barrier, 0
	.set leaf.private_seg_size, 0
	.set leaf.uses_vcc, 0
	.set leaf.uses_flat_scratch, 0
	.set leaf.has_dyn_sized_stack, 0
	.set leaf.has_recursion, 0
	.set leaf.has_indirect_call, 0
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
	.globl	device_call_leaf                ; -- Begin function device_call_leaf
	.p2align	8
	.type	device_call_leaf,@function
device_call_leaf:                       ; @device_call_leaf
; %bb.0:                                ; %entry
	s_load_dwordx2 s[16:17], s[4:5], 0x0
	s_mov_b32 s12, s8
	s_add_u32 s8, s4, 8
	s_mov_b32 s13, s9
	s_addc_u32 s9, s5, 0
	s_mov_b32 s14, s10
	s_mov_b64 s[10:11], s[6:7]
	s_getpc_b64 s[18:19]
	s_add_u32 s18, s18, leaf@rel32@lo+4
	s_addc_u32 s19, s19, leaf@rel32@hi+12
	s_mov_b64 s[4:5], s[0:1]
	s_mov_b64 s[6:7], s[2:3]
	v_mov_b32_e32 v31, v0
	v_mov_b32_e32 v0, 0
	s_mov_b32 s32, 0
	v_mov_b32_e32 v1, 0
	s_swappc_b64 s[30:31], s[18:19]
	global_store_dword v1, v0, s[16:17]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel device_call_leaf
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 264
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
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
	.size	device_call_leaf, .Lfunc_end1-device_call_leaf
                                        ; -- End function
	.set device_call_leaf.num_vgpr, max(32, leaf.num_vgpr)
	.set device_call_leaf.num_agpr, max(0, leaf.num_agpr)
	.set device_call_leaf.numbered_sgpr, max(33, leaf.numbered_sgpr)
	.set device_call_leaf.num_named_barrier, max(0, leaf.num_named_barrier)
	.set device_call_leaf.private_seg_size, 0+max(leaf.private_seg_size)
	.set device_call_leaf.uses_vcc, or(0, leaf.uses_vcc)
	.set device_call_leaf.uses_flat_scratch, or(0, leaf.uses_flat_scratch)
	.set device_call_leaf.has_dyn_sized_stack, or(0, leaf.has_dyn_sized_stack)
	.set device_call_leaf.has_recursion, or(1, leaf.has_recursion)
	.set device_call_leaf.has_indirect_call, or(0, leaf.has_indirect_call)
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 92
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
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
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
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         12
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         20
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         22
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         24
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         26
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         28
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         30
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         72
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         88
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         96
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         104
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         112
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         120
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         208
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 264
    .max_flat_workgroup_size: 64
    .name:           device_call_leaf
    .private_segment_fixed_size: 0
    .sgpr_count:     39
    .sgpr_spill_count: 0
    .symbol:         device_call_leaf.kd
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
