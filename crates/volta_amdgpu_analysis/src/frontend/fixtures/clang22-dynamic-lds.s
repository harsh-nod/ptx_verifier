	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	dynamic_lds             ; -- Begin function dynamic_lds
	.globl	dynamic_lds
	.p2align	8
	.type	dynamic_lds,@function
dynamic_lds:                            ; @dynamic_lds
; %bb.0:                                ; %entry
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_lshlrev_b32_e32 v2, 2, v0
	s_mov_b64 s[4:5], src_shared_base
	v_mov_b32_e32 v3, s5
	v_xor_b32_e32 v0, 1, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v2, s[0:1]
	v_add_u32_e32 v5, 32, v2
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt vmcnt(0)
	flat_store_dword v[2:3], v1 sc0 sc1
	s_waitcnt vmcnt(0)
	global_load_dword v4, v2, s[0:1] offset:8
	v_mov_b32_e32 v1, s5
	s_waitcnt vmcnt(0)
	ds_write_b32 v5, v4
	s_waitcnt lgkmcnt(0)
	s_barrier
	flat_load_dword v1, v[0:1] sc0 sc1
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v0, 32, v0
	ds_read_b32 v0, v0
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v1, v0
	global_store_dword v2, v0, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel dynamic_lds
		.amdhsa_group_segment_fixed_size 32
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 6
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
.Lfunc_end0:
	.size	dynamic_lds, .Lfunc_end0-dynamic_lds
                                        ; -- End function
	.set dynamic_lds.num_vgpr, 6
	.set dynamic_lds.num_agpr, 0
	.set dynamic_lds.numbered_sgpr, 6
	.set dynamic_lds.num_named_barrier, 0
	.set dynamic_lds.private_seg_size, 0
	.set dynamic_lds.uses_vcc, 0
	.set dynamic_lds.uses_flat_scratch, 0
	.set dynamic_lds.has_dyn_sized_stack, 0
	.set dynamic_lds.has_recursion, 0
	.set dynamic_lds.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 136
; TotalNumSgprs: 12
; NumVgprs: 6
; NumAgprs: 0
; TotalNumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 6
; AccumOffset: 8
; Occupancy: 8
; WaveLimiterHint : 0
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
	.type	__hip_cuid_d81207042f29516a,@object ; @__hip_cuid_d81207042f29516a
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_d81207042f29516a
__hip_cuid_d81207042f29516a:
	.byte	0                               ; 0x0
	.size	__hip_cuid_d81207042f29516a, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_d81207042f29516a
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .name:           x.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           dynamic_lds
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         dynamic_lds.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
