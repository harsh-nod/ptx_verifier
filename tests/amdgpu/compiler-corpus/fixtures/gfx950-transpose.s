	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	transpose_8x8_b16       ; -- Begin function transpose_8x8_b16
	.globl	transpose_8x8_b16
	.p2align	8
	.type	transpose_8x8_b16,@function
transpose_8x8_b16:                      ; @transpose_8x8_b16
; %bb.0:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 2, v0
	v_lshlrev_b32_e32 v3, 5, v0
	v_lshrrev_b32_e32 v0, 1, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v2, v1, s[0:1]
	s_movk_i32 s0, 0x6e
	v_bitop3_b32 v0, v3, s0, v0 bitop3:0xc8
	s_mov_b32 s0, 0x5040100
	s_waitcnt vmcnt(0)
	ds_write_b32 v1, v2
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_u16 v2, v0
	ds_read_u16 v0, v0 offset:16
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v0, v0, v2, s0
	global_store_dword v1, v0, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel transpose_8x8_b16
		.amdhsa_group_segment_fixed_size 128
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 4
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
	.size	transpose_8x8_b16, .Lfunc_end0-transpose_8x8_b16
                                        ; -- End function
	.set transpose_8x8_b16.num_vgpr, 4
	.set transpose_8x8_b16.num_agpr, 0
	.set transpose_8x8_b16.numbered_sgpr, 4
	.set transpose_8x8_b16.num_named_barrier, 0
	.set transpose_8x8_b16.private_seg_size, 0
	.set transpose_8x8_b16.uses_vcc, 0
	.set transpose_8x8_b16.uses_flat_scratch, 0
	.set transpose_8x8_b16.has_dyn_sized_stack, 0
	.set transpose_8x8_b16.has_recursion, 0
	.set transpose_8x8_b16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 108
; TotalNumSgprs: 10
; NumVgprs: 4
; NumAgprs: 0
; TotalNumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 4
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
	.protected	high64_mul_mad          ; -- Begin function high64_mul_mad
	.globl	high64_mul_mad
	.p2align	8
	.type	high64_mul_mad,@function
high64_mul_mad:                         ; @high64_mul_mad
; %bb.0:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_mov_b32 s0, 0
	v_mov_b32_e32 v0, 0
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s12, s7, s4
	s_mul_hi_u32 s13, s6, s4
	s_mul_hi_u32 s3, s7, s4
	s_add_u32 s12, s12, s13
	s_mul_i32 s1, s6, s5
	s_addc_u32 s3, s3, 0
	s_mul_hi_u32 s2, s6, s5
	s_add_u32 s1, s1, s12
	s_addc_u32 s2, s2, 0
	s_add_u32 s2, s3, s2
	s_addc_u32 s3, 0, 0
	s_mul_hi_u32 s12, s7, s5
	s_mul_i32 s5, s7, s5
	s_add_u32 s5, s5, s2
	s_addc_u32 s7, s12, s3
	s_mul_i32 s2, s6, s4
	s_mov_b32 s3, s0
	s_or_b64 s[0:1], s[2:3], s[0:1]
	v_mov_b32_e32 v4, s0
	s_add_u32 s0, s0, s8
	v_mov_b32_e32 v5, s1
	s_addc_u32 s1, s1, s9
	s_addc_u32 s2, s5, 0
	v_mov_b32_e32 v2, s5
	v_mov_b32_e32 v3, s7
	s_addc_u32 s3, s7, 0
	global_store_dwordx4 v0, v[2:5], s[10:11]
	s_nop 1
	v_mov_b32_e32 v2, s2
	v_mov_b32_e32 v3, s3
	v_mov_b32_e32 v4, s0
	v_mov_b32_e32 v5, s1
	global_store_dwordx4 v0, v[2:5], s[10:11] offset:16
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel high64_mul_mad
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
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 14
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
.Lfunc_end1:
	.size	high64_mul_mad, .Lfunc_end1-high64_mul_mad
                                        ; -- End function
	.set high64_mul_mad.num_vgpr, 6
	.set high64_mul_mad.num_agpr, 0
	.set high64_mul_mad.numbered_sgpr, 14
	.set high64_mul_mad.num_named_barrier, 0
	.set high64_mul_mad.private_seg_size, 0
	.set high64_mul_mad.uses_vcc, 0
	.set high64_mul_mad.uses_flat_scratch, 0
	.set high64_mul_mad.has_dyn_sized_stack, 0
	.set high64_mul_mad.has_recursion, 0
	.set high64_mul_mad.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 164
; TotalNumSgprs: 20
; NumVgprs: 6
; NumAgprs: 0
; TotalNumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 20
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
	.protected	high64_signed_mul_mad   ; -- Begin function high64_signed_mul_mad
	.globl	high64_signed_mul_mad
	.p2align	8
	.type	high64_signed_mul_mad,@function
high64_signed_mul_mad:                  ; @high64_signed_mul_mad
; %bb.0:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s1, s7, 31
	s_mul_i32 s2, s4, s1
	s_mul_hi_u32 s3, s4, s1
	s_ashr_i32 s0, s5, 31
	s_mul_i32 s1, s5, s1
	s_add_i32 s3, s3, s2
	s_add_i32 s3, s3, s1
	s_mul_i32 s1, s0, s7
	s_mul_hi_u32 s12, s0, s6
	s_add_i32 s1, s12, s1
	s_mul_i32 s0, s0, s6
	s_add_i32 s1, s1, s0
	s_add_u32 s2, s0, s2
	s_addc_u32 s3, s1, s3
	s_mul_i32 s14, s7, s4
	s_mul_hi_u32 s15, s6, s4
	s_mul_hi_u32 s13, s7, s4
	s_add_u32 s14, s14, s15
	s_mul_i32 s1, s6, s5
	s_addc_u32 s13, s13, 0
	s_mul_hi_u32 s12, s6, s5
	s_add_u32 s1, s1, s14
	s_addc_u32 s12, s12, 0
	s_add_u32 s12, s13, s12
	s_addc_u32 s13, 0, 0
	s_mul_hi_u32 s14, s7, s5
	s_mul_i32 s5, s7, s5
	s_add_u32 s5, s5, s12
	s_addc_u32 s7, s14, s13
	s_mov_b32 s0, 0
	s_add_u32 s5, s5, s2
	s_addc_u32 s7, s7, s3
	s_mul_i32 s2, s6, s4
	s_mov_b32 s3, s0
	s_or_b64 s[0:1], s[2:3], s[0:1]
	s_ashr_i32 s2, s9, 31
	v_mov_b32_e32 v4, s0
	s_add_u32 s0, s0, s8
	v_mov_b32_e32 v5, s1
	s_addc_u32 s1, s1, s9
	s_addc_u32 s3, s5, s2
	v_mov_b32_e32 v2, s5
	v_mov_b32_e32 v3, s7
	s_addc_u32 s2, s7, s2
	global_store_dwordx4 v0, v[2:5], s[10:11]
	s_nop 1
	v_mov_b32_e32 v2, s3
	v_mov_b32_e32 v3, s2
	v_mov_b32_e32 v4, s0
	v_mov_b32_e32 v5, s1
	global_store_dwordx4 v0, v[2:5], s[10:11] offset:16
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel high64_signed_mul_mad
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
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 16
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
.Lfunc_end2:
	.size	high64_signed_mul_mad, .Lfunc_end2-high64_signed_mul_mad
                                        ; -- End function
	.set high64_signed_mul_mad.num_vgpr, 6
	.set high64_signed_mul_mad.num_agpr, 0
	.set high64_signed_mul_mad.numbered_sgpr, 16
	.set high64_signed_mul_mad.num_named_barrier, 0
	.set high64_signed_mul_mad.private_seg_size, 0
	.set high64_signed_mul_mad.uses_vcc, 0
	.set high64_signed_mul_mad.uses_flat_scratch, 0
	.set high64_signed_mul_mad.has_dyn_sized_stack, 0
	.set high64_signed_mul_mad.has_recursion, 0
	.set high64_signed_mul_mad.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 22
; NumVgprs: 6
; NumAgprs: 0
; TotalNumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 22
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
	.type	__hip_cuid_5e52889e4f896be0,@object ; @__hip_cuid_5e52889e4f896be0
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_5e52889e4f896be0
__hip_cuid_5e52889e4f896be0:
	.byte	0                               ; 0x0
	.size	__hip_cuid_5e52889e4f896be0, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_5e52889e4f896be0
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           transpose_8x8_b16
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         transpose_8x8_b16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           8
        .value_kind:     by_value
      - .offset:         8
        .size:           8
        .value_kind:     by_value
      - .offset:         16
        .size:           8
        .value_kind:     by_value
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           high64_mul_mad
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         high64_mul_mad.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           8
        .value_kind:     by_value
      - .offset:         8
        .size:           8
        .value_kind:     by_value
      - .offset:         16
        .size:           8
        .value_kind:     by_value
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           high64_signed_mul_mad
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         high64_signed_mul_mad.kd
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
