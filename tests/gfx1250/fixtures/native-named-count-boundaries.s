	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_expected_one              ; -- Begin function named_expected_one
	.p2align	8
	.type	named_expected_one,@function
named_expected_one:                     ; @named_expected_one
; %bb.0:
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_expected_one
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 256
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr 1
		.amdhsa_next_free_sgpr 1
		.amdhsa_named_barrier_count 1
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
	.size	named_expected_one, .Lfunc_end0-named_expected_one
                                        ; -- End function
	.set named_expected_one.num_vgpr, 0
	.set named_expected_one.num_agpr, 0
	.set named_expected_one.numbered_sgpr, 0
	.set named_expected_one.num_named_barrier, 1
	.set named_expected_one.private_seg_size, 0
	.set named_expected_one.uses_vcc, 0
	.set named_expected_one.uses_flat_scratch, 0
	.set named_expected_one.has_dyn_sized_stack, 0
	.set named_expected_one.has_recursion, 0
	.set named_expected_one.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 16
; TotalNumSgprs: 0
; NumVgprs: 0
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 1
; NumVGPRsForWavesPerEU: 1
; NamedBarCnt: 1
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_expected_maximum          ; -- Begin function named_expected_maximum
	.p2align	8
	.type	named_expected_maximum,@function
named_expected_maximum:                 ; @named_expected_maximum
; %bb.0:
	s_mov_b32 m0, 0xffff0001
	s_barrier_init m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_expected_maximum
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 256
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr 1
		.amdhsa_next_free_sgpr 1
		.amdhsa_named_barrier_count 1
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
.Lfunc_end1:
	.size	named_expected_maximum, .Lfunc_end1-named_expected_maximum
                                        ; -- End function
	.set named_expected_maximum.num_vgpr, 0
	.set named_expected_maximum.num_agpr, 0
	.set named_expected_maximum.numbered_sgpr, 0
	.set named_expected_maximum.num_named_barrier, 1
	.set named_expected_maximum.private_seg_size, 0
	.set named_expected_maximum.uses_vcc, 0
	.set named_expected_maximum.uses_flat_scratch, 0
	.set named_expected_maximum.has_dyn_sized_stack, 0
	.set named_expected_maximum.has_recursion, 0
	.set named_expected_maximum.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 16
; TotalNumSgprs: 0
; NumVgprs: 0
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 1
; NumVGPRsForWavesPerEU: 1
; NamedBarCnt: 1
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_expected_zero             ; -- Begin function named_expected_zero
	.p2align	8
	.type	named_expected_zero,@function
named_expected_zero:                    ; @named_expected_zero
; %bb.0:
	s_mov_b32 m0, 1
	s_barrier_init m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_expected_zero
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 256
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr 1
		.amdhsa_next_free_sgpr 1
		.amdhsa_named_barrier_count 1
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
.Lfunc_end2:
	.size	named_expected_zero, .Lfunc_end2-named_expected_zero
                                        ; -- End function
	.set named_expected_zero.num_vgpr, 0
	.set named_expected_zero.num_agpr, 0
	.set named_expected_zero.numbered_sgpr, 0
	.set named_expected_zero.num_named_barrier, 1
	.set named_expected_zero.private_seg_size, 0
	.set named_expected_zero.uses_vcc, 0
	.set named_expected_zero.uses_flat_scratch, 0
	.set named_expected_zero.has_dyn_sized_stack, 0
	.set named_expected_zero.has_recursion, 0
	.set named_expected_zero.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 12
; TotalNumSgprs: 0
; NumVgprs: 0
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 1
; NumVGPRsForWavesPerEU: 1
; NamedBarCnt: 1
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_null_zero                 ; -- Begin function named_null_zero
	.p2align	8
	.type	named_null_zero,@function
named_null_zero:                        ; @named_null_zero
; %bb.0:
	s_mov_b32 m0, 0
	s_barrier_init m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_null_zero
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 256
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr 1
		.amdhsa_next_free_sgpr 1
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
.Lfunc_end3:
	.size	named_null_zero, .Lfunc_end3-named_null_zero
                                        ; -- End function
	.set named_null_zero.num_vgpr, 0
	.set named_null_zero.num_agpr, 0
	.set named_null_zero.numbered_sgpr, 0
	.set named_null_zero.num_named_barrier, 0
	.set named_null_zero.private_seg_size, 0
	.set named_null_zero.uses_vcc, 0
	.set named_null_zero.uses_flat_scratch, 0
	.set named_null_zero.has_dyn_sized_stack, 0
	.set named_null_zero.has_recursion, 0
	.set named_null_zero.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 12
; TotalNumSgprs: 0
; NumVgprs: 0
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 1
; NumVGPRsForWavesPerEU: 1
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .offset:         0
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         4
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         12
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         14
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         16
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         18
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         20
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         22
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         40
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         64
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         80
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         88
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         96
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         104
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         112
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         200
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 256
    .max_flat_workgroup_size: 32
    .name:           named_expected_one
    .private_segment_fixed_size: 0
    .sgpr_count:     0
    .sgpr_spill_count: 0
    .symbol:         named_expected_one.kd
    .uses_dynamic_stack: false
    .vgpr_count:     0
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         4
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         12
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         14
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         16
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         18
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         20
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         22
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         40
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         64
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         80
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         88
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         96
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         104
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         112
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         200
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 256
    .max_flat_workgroup_size: 32
    .name:           named_expected_maximum
    .private_segment_fixed_size: 0
    .sgpr_count:     0
    .sgpr_spill_count: 0
    .symbol:         named_expected_maximum.kd
    .uses_dynamic_stack: false
    .vgpr_count:     0
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         4
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         12
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         14
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         16
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         18
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         20
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         22
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         40
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         64
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         80
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         88
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         96
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         104
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         112
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         200
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 256
    .max_flat_workgroup_size: 32
    .name:           named_expected_zero
    .private_segment_fixed_size: 0
    .sgpr_count:     0
    .sgpr_spill_count: 0
    .symbol:         named_expected_zero.kd
    .uses_dynamic_stack: false
    .vgpr_count:     0
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         4
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         12
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         14
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         16
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         18
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         20
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         22
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         40
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         64
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         80
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         88
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         96
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         104
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         112
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         200
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 256
    .max_flat_workgroup_size: 32
    .name:           named_null_zero
    .private_segment_fixed_size: 0
    .sgpr_count:     0
    .sgpr_spill_count: 0
    .symbol:         named_null_zero.kd
    .uses_dynamic_stack: false
    .vgpr_count:     0
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
