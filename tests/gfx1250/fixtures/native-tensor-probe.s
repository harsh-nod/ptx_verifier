	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	tensor_load_probe       ; -- Begin function tensor_load_probe
	.globl	tensor_load_probe
	.p2align	8
	.type	tensor_load_probe,@function
tensor_load_probe:                      ; @tensor_load_probe
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_clause 0x1
	s_load_b128 s[20:23], s[0:1], 0x0
	s_load_b512 s[4:19], s[0:1], 0x20
	s_wait_kmcnt 0x0
	tensor_load_to_lds s[20:23], s[4:11], s[12:15], s[16:19]
.LBB0_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_wait_tensorcnt 0x0
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_load_probe
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
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
		.amdhsa_next_free_vgpr 1
		.amdhsa_next_free_sgpr 24
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
	.size	tensor_load_probe, .Lfunc_end0-tensor_load_probe
                                        ; -- End function
	.set tensor_load_probe.num_vgpr, 1
	.set tensor_load_probe.num_agpr, 0
	.set tensor_load_probe.numbered_sgpr, 24
	.set tensor_load_probe.num_named_barrier, 0
	.set tensor_load_probe.private_seg_size, 0
	.set tensor_load_probe.uses_vcc, 0
	.set tensor_load_probe.uses_flat_scratch, 0
	.set tensor_load_probe.has_dyn_sized_stack, 0
	.set tensor_load_probe.has_recursion, 0
	.set tensor_load_probe.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 24
; NumVgprs: 1
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
; NumVGPRsForWavesPerEU: 1
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
	.protected	tensor_store_probe      ; -- Begin function tensor_store_probe
	.globl	tensor_store_probe
	.p2align	8
	.type	tensor_store_probe,@function
tensor_store_probe:                     ; @tensor_store_probe
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_2
; %bb.1:
	s_clause 0x1
	s_load_b128 s[20:23], s[0:1], 0x0
	s_load_b512 s[4:19], s[0:1], 0x20
	s_wait_kmcnt 0x0
	tensor_store_from_lds s[20:23], s[4:11], s[12:15], s[16:19]
.LBB1_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_wait_tensorcnt 0x0
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_store_probe
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
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
		.amdhsa_next_free_vgpr 1
		.amdhsa_next_free_sgpr 24
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
	.size	tensor_store_probe, .Lfunc_end1-tensor_store_probe
                                        ; -- End function
	.set tensor_store_probe.num_vgpr, 1
	.set tensor_store_probe.num_agpr, 0
	.set tensor_store_probe.numbered_sgpr, 24
	.set tensor_store_probe.num_named_barrier, 0
	.set tensor_store_probe.private_seg_size, 0
	.set tensor_store_probe.uses_vcc, 0
	.set tensor_store_probe.uses_flat_scratch, 0
	.set tensor_store_probe.has_dyn_sized_stack, 0
	.set tensor_store_probe.has_recursion, 0
	.set tensor_store_probe.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 24
; NumVgprs: 1
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 24
; NumVGPRsForWavesPerEU: 1
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
	.type	__hip_cuid_ea61b515efef3d21,@object ; @__hip_cuid_ea61b515efef3d21
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_ea61b515efef3d21
__hip_cuid_ea61b515efef3d21:
	.byte	0                               ; 0x0
	.size	__hip_cuid_ea61b515efef3d21, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_ea61b515efef3d21
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .offset:         0
        .size:           16
        .value_kind:     by_value
      - .offset:         32
        .size:           32
        .value_kind:     by_value
      - .offset:         64
        .size:           16
        .value_kind:     by_value
      - .offset:         80
        .size:           16
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 32
    .kernarg_segment_size: 96
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           tensor_load_probe
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         tensor_load_probe.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     1
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           16
        .value_kind:     by_value
      - .offset:         32
        .size:           32
        .value_kind:     by_value
      - .offset:         64
        .size:           16
        .value_kind:     by_value
      - .offset:         80
        .size:           16
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 32
    .kernarg_segment_size: 96
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           tensor_store_probe
    .private_segment_fixed_size: 0
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         tensor_store_probe.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     1
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
