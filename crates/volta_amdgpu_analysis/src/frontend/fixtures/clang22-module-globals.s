	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	module_globals          ; -- Begin function module_globals
	.globl	module_globals
	.p2align	8
	.type	module_globals,@function
module_globals:                         ; @module_globals
; %bb.0:                                ; %entry
	v_and_b32_e32 v1, 3, v0
	v_lshlrev_b32_e32 v1, 2, v1
	s_getpc_b64 s[2:3]
	s_add_u32 s2, s2, constant_table@rel32@lo+4
	s_addc_u32 s3, s3, constant_table@rel32@hi+12
	global_load_dword v1, v1, s[2:3]
	s_getpc_b64 s[2:3]
	s_add_u32 s2, s2, bound_global@rel32@lo+4
	s_addc_u32 s3, s3, bound_global@rel32@hi+12
	s_getpc_b64 s[4:5]
	s_add_u32 s4, s4, global_bias@rel32@lo+4
	s_addc_u32 s5, s5, global_bias@rel32@hi+12
	s_load_dword s8, s[2:3], 0x0
	s_load_dword s9, s[4:5], 0x0
	s_load_dwordx2 s[6:7], s[0:1], 0x0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s9, s9, s8
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v1, s9, v1
	global_store_dword v0, v1, s[6:7]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel module_globals
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 10
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
	.size	module_globals, .Lfunc_end0-module_globals
                                        ; -- End function
	.set module_globals.num_vgpr, 2
	.set module_globals.num_agpr, 0
	.set module_globals.numbered_sgpr, 10
	.set module_globals.num_named_barrier, 0
	.set module_globals.private_seg_size, 0
	.set module_globals.uses_vcc, 0
	.set module_globals.uses_flat_scratch, 0
	.set module_globals.has_dyn_sized_stack, 0
	.set module_globals.has_recursion, 0
	.set module_globals.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 132
; TotalNumSgprs: 16
; NumVgprs: 2
; NumAgprs: 0
; TotalNumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 16
; NumVGPRsForWavesPerEU: 2
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
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.protected	bound_global            ; @bound_global
	.type	bound_global,@object
	.section	.bss,"aw",@nobits
	.globl	bound_global
	.p2align	2, 0x0
bound_global:
	.long	0                               ; 0x0
	.size	bound_global, 4

	.protected	global_bias             ; @global_bias
	.type	global_bias,@object
	.data
	.globl	global_bias
	.p2align	2, 0x0
global_bias:
	.long	3                               ; 0x3
	.size	global_bias, 4

	.protected	constant_table          ; @constant_table
	.type	constant_table,@object
	.section	.rodata,"a",@progbits
	.globl	constant_table
	.p2align	4, 0x0
constant_table:
	.long	2                               ; 0x2
	.long	3                               ; 0x3
	.long	5                               ; 0x5
	.long	7                               ; 0x7
	.size	constant_table, 16

	.type	__hip_cuid_f5c3acce39873753,@object ; @__hip_cuid_f5c3acce39873753
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_f5c3acce39873753
__hip_cuid_f5c3acce39873753:
	.byte	0                               ; 0x0
	.size	__hip_cuid_f5c3acce39873753, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym bound_global
	.addrsig_sym global_bias
	.addrsig_sym constant_table
	.addrsig_sym __hip_cuid_f5c3acce39873753
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           out.coerce
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
    .name:           module_globals
    .private_segment_fixed_size: 0
    .sgpr_count:     16
    .sgpr_spill_count: 0
    .symbol:         module_globals.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
