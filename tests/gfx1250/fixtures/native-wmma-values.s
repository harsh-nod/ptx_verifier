	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	wmma_f32_values         ; -- Begin function wmma_f32_values
	.globl	wmma_f32_values
	.p2align	8
	.type	wmma_f32_values,@function
wmma_f32_values:                        ; @wmma_f32_values
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	s_wait_kmcnt 0x0
	v_dual_lshlrev_b32 v0, 5, v0 :: v_dual_mov_b32 v10, s4
	v_dual_mov_b32 v11, s5 :: v_dual_mov_b32 v12, s6
	v_mov_b32_e32 v13, s7
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x4_f32 v[2:9], v[10:11], v[12:13], 0
	s_clause 0x1
	global_store_b128 v0, v[6:9], s[2:3] offset:16
	global_store_b128 v0, v[2:5], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel wmma_f32_values
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
		.amdhsa_next_free_vgpr 14
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
	.size	wmma_f32_values, .Lfunc_end0-wmma_f32_values
                                        ; -- End function
	.set wmma_f32_values.num_vgpr, 14
	.set wmma_f32_values.num_agpr, 0
	.set wmma_f32_values.numbered_sgpr, 8
	.set wmma_f32_values.num_named_barrier, 0
	.set wmma_f32_values.private_seg_size, 0
	.set wmma_f32_values.uses_vcc, 0
	.set wmma_f32_values.uses_flat_scratch, 0
	.set wmma_f32_values.has_dyn_sized_stack, 0
	.set wmma_f32_values.has_recursion, 0
	.set wmma_f32_values.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 92
; TotalNumSgprs: 8
; NumVgprs: 14
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 14
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
	.protected	wmma_f16_values         ; -- Begin function wmma_f16_values
	.globl	wmma_f16_values
	.p2align	8
	.type	wmma_f16_values,@function
wmma_f16_values:                        ; @wmma_f16_values
; %bb.0:
	s_clause 0x2
	s_load_b256 s[4:11], s[0:1], 0x0
	s_load_b256 s[12:19], s[0:1], 0x20
	s_load_b64 s[2:3], s[0:1], 0x40
	v_lshlrev_b32_e32 v0, 5, v0
	s_wait_kmcnt 0x0
	v_mov_b64_e32 v[2:3], s[4:5]
	v_mov_b64_e32 v[10:11], s[12:13]
	v_mov_b64_e32 v[4:5], s[6:7]
	v_mov_b64_e32 v[6:7], s[8:9]
	v_mov_b64_e32 v[8:9], s[10:11]
	v_mov_b64_e32 v[12:13], s[14:15]
	v_mov_b64_e32 v[14:15], s[16:17]
	v_mov_b64_e32 v[16:17], s[18:19]
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[18:25], v[2:9], v[10:17], 0
	s_clause 0x1
	global_store_b128 v0, v[22:25], s[2:3] offset:16
	global_store_b128 v0, v[18:21], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel wmma_f16_values
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 72
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
		.amdhsa_next_free_vgpr 26
		.amdhsa_next_free_sgpr 20
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
.Lfunc_end1:
	.size	wmma_f16_values, .Lfunc_end1-wmma_f16_values
                                        ; -- End function
	.set wmma_f16_values.num_vgpr, 26
	.set wmma_f16_values.num_agpr, 0
	.set wmma_f16_values.numbered_sgpr, 20
	.set wmma_f16_values.num_named_barrier, 0
	.set wmma_f16_values.private_seg_size, 0
	.set wmma_f16_values.uses_vcc, 0
	.set wmma_f16_values.uses_flat_scratch, 0
	.set wmma_f16_values.has_dyn_sized_stack, 0
	.set wmma_f16_values.has_recursion, 0
	.set wmma_f16_values.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 112
; TotalNumSgprs: 20
; NumVgprs: 26
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 20
; NumVGPRsForWavesPerEU: 26
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
	.protected	wmma_bf16_values        ; -- Begin function wmma_bf16_values
	.globl	wmma_bf16_values
	.p2align	8
	.type	wmma_bf16_values,@function
wmma_bf16_values:                       ; @wmma_bf16_values
; %bb.0:
	s_clause 0x2
	s_load_b256 s[4:11], s[0:1], 0x0
	s_load_b256 s[12:19], s[0:1], 0x20
	s_load_b64 s[2:3], s[0:1], 0x40
	v_lshlrev_b32_e32 v0, 5, v0
	s_wait_kmcnt 0x0
	v_mov_b64_e32 v[2:3], s[4:5]
	v_mov_b64_e32 v[10:11], s[12:13]
	v_mov_b64_e32 v[4:5], s[6:7]
	v_mov_b64_e32 v[6:7], s[8:9]
	v_mov_b64_e32 v[8:9], s[10:11]
	v_mov_b64_e32 v[12:13], s[14:15]
	v_mov_b64_e32 v[14:15], s[16:17]
	v_mov_b64_e32 v[16:17], s[18:19]
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_bf16 v[18:25], v[2:9], v[10:17], 0
	s_clause 0x1
	global_store_b128 v0, v[22:25], s[2:3] offset:16
	global_store_b128 v0, v[18:21], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel wmma_bf16_values
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 72
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
		.amdhsa_next_free_vgpr 26
		.amdhsa_next_free_sgpr 20
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
.Lfunc_end2:
	.size	wmma_bf16_values, .Lfunc_end2-wmma_bf16_values
                                        ; -- End function
	.set wmma_bf16_values.num_vgpr, 26
	.set wmma_bf16_values.num_agpr, 0
	.set wmma_bf16_values.numbered_sgpr, 20
	.set wmma_bf16_values.num_named_barrier, 0
	.set wmma_bf16_values.private_seg_size, 0
	.set wmma_bf16_values.uses_vcc, 0
	.set wmma_bf16_values.uses_flat_scratch, 0
	.set wmma_bf16_values.has_dyn_sized_stack, 0
	.set wmma_bf16_values.has_recursion, 0
	.set wmma_bf16_values.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 112
; TotalNumSgprs: 20
; NumVgprs: 26
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 20
; NumVGPRsForWavesPerEU: 26
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
	.type	__hip_cuid_ece4e7ddc0530bbc,@object ; @__hip_cuid_ece4e7ddc0530bbc
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_ece4e7ddc0530bbc
__hip_cuid_ece4e7ddc0530bbc:
	.byte	0                               ; 0x0
	.size	__hip_cuid_ece4e7ddc0530bbc, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_ece4e7ddc0530bbc
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .offset:         0
        .size:           8
        .value_kind:     by_value
      - .offset:         8
        .size:           8
        .value_kind:     by_value
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
    .name:           wmma_f32_values
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         wmma_f32_values.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           32
        .value_kind:     by_value
      - .offset:         32
        .size:           32
        .value_kind:     by_value
      - .address_space:  global
        .offset:         64
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 32
    .kernarg_segment_size: 72
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           wmma_f16_values
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         wmma_f16_values.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     26
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           32
        .value_kind:     by_value
      - .offset:         32
        .size:           32
        .value_kind:     by_value
      - .address_space:  global
        .offset:         64
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 32
    .kernarg_segment_size: 72
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           wmma_bf16_values
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         wmma_bf16_values.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     26
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
