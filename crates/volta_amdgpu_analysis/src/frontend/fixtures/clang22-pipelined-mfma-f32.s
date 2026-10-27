	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	pipelined_mfma_f32      ; -- Begin function pipelined_mfma_f32
	.globl	pipelined_mfma_f32
	.p2align	8
	.type	pipelined_mfma_f32,@function
pipelined_mfma_f32:                     ; @pipelined_mfma_f32
; %bb.0:                                ; %entry
	v_lshrrev_b32_e32 v2, 6, v0
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	v_xor_b32_e32 v3, 1, v2
	v_lshlrev_b32_e32 v6, 1, v0
	v_and_b32_e32 v4, 3, v0
	v_lshlrev_b32_e32 v5, 7, v3
	v_and_b32_e32 v6, 0x78, v6
	v_and_b32_e32 v1, 63, v0
	v_or3_b32 v4, v5, v6, v4
	v_lshlrev_b32_e32 v4, 2, v4
	v_lshlrev_b32_e32 v1, 2, v1
	s_waitcnt lgkmcnt(0)
	global_load_dword v5, v4, s[4:5]
	global_load_dword v6, v1, s[6:7]
	v_lshlrev_b32_e32 v7, 2, v0
	v_lshlrev_b32_e32 v3, 8, v3
	v_lshlrev_b32_e32 v2, 8, v2
	s_waitcnt vmcnt(0)
	ds_write2st64_b32 v7, v5, v6 offset1:4
	s_waitcnt lgkmcnt(0)
	s_barrier
	global_load_dword v5, v4, s[4:5] offset:16
	global_load_dword v6, v1, s[6:7] offset:256
	v_bfe_u32 v4, v0, 4, 2
	v_and_b32_e32 v0, 15, v0
	v_lshlrev_b32_e32 v8, 4, v0
	v_lshlrev_b32_e32 v9, 2, v4
	v_or3_b32 v8, v3, v8, v9
	v_or_b32_e32 v1, v3, v1
	ds_read_b32 v3, v8
	ds_read_b32 v9, v1 offset:1024
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_f32_16x16x4_f32 a[0:3], v3, v9, 0
	v_lshlrev_b32_e32 v3, 6, v4
	v_or3_b32 v0, v2, v3, v0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt vmcnt(0)
	ds_write2st64_b32 v7, v5, v6 offset0:2 offset1:6
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v5, v8 offset:512
	ds_read_b32 v1, v1 offset:1536
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x4_f32 a[0:3], v5, v1, a[0:3]
	s_barrier
	s_barrier
	s_nop 7
	global_store_dword v0, a0, s[2:3]
	global_store_dword v0, a1, s[2:3] offset:64
	global_store_dword v0, a2, s[2:3] offset:128
	global_store_dword v0, a3, s[2:3] offset:192
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel pipelined_mfma_f32
		.amdhsa_group_segment_fixed_size 2048
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
		.amdhsa_next_free_vgpr 16
		.amdhsa_next_free_sgpr 8
		.amdhsa_accum_offset 12
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
	.size	pipelined_mfma_f32, .Lfunc_end0-pipelined_mfma_f32
                                        ; -- End function
	.set pipelined_mfma_f32.num_vgpr, 10
	.set pipelined_mfma_f32.num_agpr, 4
	.set pipelined_mfma_f32.numbered_sgpr, 8
	.set pipelined_mfma_f32.num_named_barrier, 0
	.set pipelined_mfma_f32.private_seg_size, 0
	.set pipelined_mfma_f32.uses_vcc, 0
	.set pipelined_mfma_f32.uses_flat_scratch, 0
	.set pipelined_mfma_f32.has_dyn_sized_stack, 0
	.set pipelined_mfma_f32.has_recursion, 0
	.set pipelined_mfma_f32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 308
; TotalNumSgprs: 14
; NumVgprs: 10
; NumAgprs: 4
; TotalNumVgprs: 16
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 2048 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 16
; AccumOffset: 12
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 2
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_cccd2f605993e2ef,@object ; @__hip_cuid_cccd2f605993e2ef
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_cccd2f605993e2ef
__hip_cuid_cccd2f605993e2ef:
	.byte	0                               ; 0x0
	.size	__hip_cuid_cccd2f605993e2ef, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/ROCm/llvm-project  25496 9b0f9aa3067a907226b0ebb8bee1fe51d1f0fca5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_cccd2f605993e2ef
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
    .group_segment_fixed_size: 2048
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 128
    .name:           pipelined_mfma_f32
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         pipelined_mfma_f32.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     16
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
