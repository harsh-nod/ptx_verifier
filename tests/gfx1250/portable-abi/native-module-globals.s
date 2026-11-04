	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	abi_module_globals      ; -- Begin function abi_module_globals
	.globl	abi_module_globals
	.p2align	8
	.type	abi_module_globals,@function
abi_module_globals:                     ; @abi_module_globals
; %bb.0:
	v_and_b32_e32 v1, 3, v0
	s_get_pc_i64 s[2:3]
	s_add_nc_u64 s[2:3], s[2:3], abi_constant_table@rel64+4
	s_get_pc_i64 s[4:5]
	s_add_nc_u64 s[4:5], s[4:5], abi_global_bias@rel64+4
	global_load_b32 v1, v1, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_get_pc_i64 s[2:3]
	s_add_nc_u64 s[2:3], s[2:3], abi_bound_global@rel64+4
	s_load_b32 s8, s[2:3], 0x0
	s_load_b32 s9, s[4:5], 0x0
	s_load_b64 s[6:7], s[0:1], 0x0
	s_wait_loadcnt 0x0
	s_wait_kmcnt 0x0
	v_add3_u32 v1, s9, s8, v1
	global_store_b32 v0, v1, s[6:7] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_module_globals
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 10
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
	.size	abi_module_globals, .Lfunc_end0-abi_module_globals
                                        ; -- End function
	.set abi_module_globals.num_vgpr, 2
	.set abi_module_globals.num_agpr, 0
	.set abi_module_globals.numbered_sgpr, 10
	.set abi_module_globals.num_named_barrier, 0
	.set abi_module_globals.private_seg_size, 0
	.set abi_module_globals.uses_vcc, 0
	.set abi_module_globals.uses_flat_scratch, 0
	.set abi_module_globals.has_dyn_sized_stack, 0
	.set abi_module_globals.has_recursion, 0
	.set abi_module_globals.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 124
; TotalNumSgprs: 10
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 2
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
	.protected	abi_bound_global        ; @abi_bound_global
	.type	abi_bound_global,@object
	.section	.bss,"aw",@nobits
	.globl	abi_bound_global
	.p2align	2, 0x0
abi_bound_global:
	.long	0                               ; 0x0
	.size	abi_bound_global, 4

	.protected	abi_global_bias         ; @abi_global_bias
	.type	abi_global_bias,@object
	.data
	.globl	abi_global_bias
	.p2align	2, 0x0
abi_global_bias:
	.long	3                               ; 0x3
	.size	abi_global_bias, 4

	.protected	abi_constant_table      ; @abi_constant_table
	.type	abi_constant_table,@object
	.section	.rodata,"a",@progbits
	.globl	abi_constant_table
	.p2align	4, 0x0
abi_constant_table:
	.long	2                               ; 0x2
	.long	3                               ; 0x3
	.long	5                               ; 0x5
	.long	7                               ; 0x7
	.size	abi_constant_table, 16

	.protected	abi_readonly_scalar     ; @abi_readonly_scalar
	.type	abi_readonly_scalar,@object
	.globl	abi_readonly_scalar
	.p2align	2, 0x0
abi_readonly_scalar:
	.long	11                              ; 0xb
	.size	abi_readonly_scalar, 4

	.type	__hip_cuid_428f6374785cfbff,@object ; @__hip_cuid_428f6374785cfbff
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_428f6374785cfbff
__hip_cuid_428f6374785cfbff:
	.byte	0                               ; 0x0
	.size	__hip_cuid_428f6374785cfbff, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym abi_bound_global
	.addrsig_sym abi_global_bias
	.addrsig_sym abi_constant_table
	.addrsig_sym __hip_cuid_428f6374785cfbff
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_module_globals
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         abi_module_globals.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
