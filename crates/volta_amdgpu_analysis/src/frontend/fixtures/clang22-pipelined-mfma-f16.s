	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	pipelined_mfma_f16      ; -- Begin function pipelined_mfma_f16
	.globl	pipelined_mfma_f16
	.p2align	8
	.type	pipelined_mfma_f16,@function
pipelined_mfma_f16:                     ; @pipelined_mfma_f16
; %bb.0:                                ; %entry
	v_lshrrev_b32_e32 v6, 6, v0
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_lshlrev_b32_e32 v1, 2, v0
	v_lshlrev_b32_e32 v2, 9, v6
	v_lshlrev_b32_e32 v8, 3, v0
	v_xor_b32_e32 v7, 0x200, v2
	v_and_b32_e32 v2, 0x1e0, v8
	v_and_b32_e32 v3, 12, v1
	v_or3_b32 v2, v7, v2, v3
	v_lshlrev_b32_e32 v9, 1, v2
	v_and_b32_e32 v10, 0x1f8, v8
	s_waitcnt lgkmcnt(0)
	global_load_dwordx2 v[2:3], v9, s[4:5]
	global_load_dwordx2 v[4:5], v10, s[6:7]
	v_and_b32_e32 v13, 0xc0, v1
	v_lshlrev_b32_e32 v6, 8, v6
	s_mov_b32 s0, 0x5040100
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v8, v[2:3], v[4:5] offset1:4
	s_waitcnt lgkmcnt(0)
	s_barrier
	global_load_dwordx2 v[2:3], v9, s[4:5] offset:32
	global_load_dwordx2 v[4:5], v10, s[6:7] offset:512
	v_and_b32_e32 v9, 15, v0
	v_bfe_u32 v0, v0, 4, 2
	v_lshlrev_b32_e32 v11, 3, v0
	v_lshlrev_b32_e32 v0, 7, v0
	v_lshlrev_b32_e32 v12, 1, v9
	v_lshlrev_b32_e32 v10, 5, v9
	v_or3_b32 v0, v0, v7, v12
	v_or3_b32 v10, v10, v11, v7
	v_or_b32_e32 v11, 0x800, v0
	v_or_b32_e32 v1, 0x820, v0
	v_or_b32_e32 v7, 0x840, v0
	v_or_b32_e32 v0, 0x860, v0
	ds_read_u16 v12, v11
	ds_read_u16 v14, v1
	ds_read_u16 v7, v7
	ds_read_u16 v15, v0
	ds_read_b64 v[0:1], v10
	v_or3_b32 v6, v6, v13, v9
	v_lshlrev_b32_e32 v9, 1, v6
	s_waitcnt lgkmcnt(3)
	v_perm_b32 v6, v14, v12, s0
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v7, v15, v7, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_f32_16x16x16_f16 a[0:3], v[0:1], v[6:7], 0
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v8, v[2:3], v[4:5] offset0:2 offset1:6
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64 v[0:1], v10 offset:1024
	ds_read_u16 v2, v11 offset:1024
	ds_read_u16 v4, v11 offset:1056
	ds_read_u16 v3, v11 offset:1088
	ds_read_u16 v5, v11 offset:1120
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_perm_b32 v2, v4, v2, s0
	v_perm_b32 v3, v5, v3, s0
	s_barrier
	s_nop 0
	v_mfma_f32_16x16x16_f16 a[0:3], v[0:1], v[2:3], a[0:3]
	s_nop 7
	v_accvgpr_read_b32 v0, a0
	v_accvgpr_read_b32 v1, a1
	v_cvt_f16_f32_e32 v0, v0
	v_accvgpr_read_b32 v2, a2
	v_cvt_f16_f32_e32 v1, v1
	v_accvgpr_read_b32 v3, a3
	v_cvt_f16_f32_e32 v2, v2
	v_cvt_f16_f32_e32 v3, v3
	global_store_short v9, v0, s[2:3]
	global_store_short v9, v1, s[2:3] offset:32
	global_store_short v9, v2, s[2:3] offset:64
	global_store_short v9, v3, s[2:3] offset:96
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel pipelined_mfma_f16
		.amdhsa_group_segment_fixed_size 4096
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
		.amdhsa_next_free_vgpr 20
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 16
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
	.size	pipelined_mfma_f16, .Lfunc_end0-pipelined_mfma_f16
                                        ; -- End function
	.set pipelined_mfma_f16.num_vgpr, 16
	.set pipelined_mfma_f16.num_agpr, 4
	.set pipelined_mfma_f16.numbered_sgpr, 8
	.set pipelined_mfma_f16.num_named_barrier, 0
	.set pipelined_mfma_f16.private_seg_size, 0
	.set pipelined_mfma_f16.uses_vcc, 0
	.set pipelined_mfma_f16.uses_flat_scratch, 0
	.set pipelined_mfma_f16.has_dyn_sized_stack, 0
	.set pipelined_mfma_f16.has_recursion, 0
	.set pipelined_mfma_f16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 504
; TotalNumSgprs: 14
; NumVgprs: 16
; NumAgprs: 4
; TotalNumVgprs: 20
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 20
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_352c45481760421e,@object ; @__hip_cuid_352c45481760421e
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_352c45481760421e
__hip_cuid_352c45481760421e:
	.byte	0                               ; 0x0
	.size	__hip_cuid_352c45481760421e, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_352c45481760421e
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     4
    .args:
      - .address_space:  global
        .name:           a.coerce
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           b.coerce
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out.coerce
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           pipelined_mfma_f16
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         pipelined_mfma_f16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     20
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
