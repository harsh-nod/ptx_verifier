	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mixed_byvalue           ; -- Begin function mixed_byvalue
	.globl	mixed_byvalue
	.p2align	8
	.type	mixed_byvalue,@function
mixed_byvalue:                          ; @mixed_byvalue
; %bb.0:                                ; %entry
	s_load_dwordx2 s[2:3], s[0:1], 0x18
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_u32_e32 vcc, s2, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_2
; %bb.1:                                ; %if.then
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dword s2, s[0:1], 0x8
	s_load_dwordx2 s[6:7], s[0:1], 0x10
	s_load_dword s8, s[0:1], 0x1c
	s_sext_i32_i16 s0, s3
	v_cvt_f32_i32_e32 v1, s0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	v_cvt_f32_f64_e32 v2, s[6:7]
	v_add_f32_e32 v2, s2, v2
	v_add_f32_e32 v1, v2, v1
	v_cvt_f32_ubyte2_e32 v2, s8
	v_add_f32_e32 v1, v1, v2
	global_store_dword v0, v1, s[4:5]
.LBB0_2:                                ; %if.end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mixed_byvalue
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 9
		.amdhsa_accum_offset 4
		.amdhsa_reserve_vcc 1
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
	.size	mixed_byvalue, .Lfunc_end0-mixed_byvalue
                                        ; -- End function
	.set mixed_byvalue.num_vgpr, 3
	.set mixed_byvalue.num_agpr, 0
	.set mixed_byvalue.numbered_sgpr, 9
	.set mixed_byvalue.num_named_barrier, 0
	.set mixed_byvalue.private_seg_size, 0
	.set mixed_byvalue.uses_vcc, 1
	.set mixed_byvalue.uses_flat_scratch, 0
	.set mixed_byvalue.has_dyn_sized_stack, 0
	.set mixed_byvalue.has_recursion, 0
	.set mixed_byvalue.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 104
; TotalNumSgprs: 15
; NumVgprs: 3
; NumAgprs: 0
; TotalNumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 15
; NumVGPRsForWavesPerEU: 3
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
	.type	__hip_cuid_7ed21fbe7b3acc1e,@object ; @__hip_cuid_7ed21fbe7b3acc1e
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_7ed21fbe7b3acc1e
__hip_cuid_7ed21fbe7b3acc1e:
	.byte	0                               ; 0x0
	.size	__hip_cuid_7ed21fbe7b3acc1e, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_7ed21fbe7b3acc1e
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
      - .name:           alpha
        .offset:         8
        .size:           4
        .value_kind:     by_value
      - .name:           beta
        .offset:         16
        .size:           8
        .value_kind:     by_value
      - .name:           !str n
        .offset:         24
        .size:           4
        .value_kind:     by_value
      - .name:           s
        .offset:         28
        .size:           2
        .value_kind:     by_value
      - .name:           b
        .offset:         30
        .size:           1
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           mixed_byvalue
    .private_segment_fixed_size: 0
    .sgpr_count:     15
    .sgpr_spill_count: 0
    .symbol:         mixed_byvalue.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
