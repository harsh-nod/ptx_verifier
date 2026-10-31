	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	transpose_8x8_b16       ; -- Begin function transpose_8x8_b16
	.globl	transpose_8x8_b16
	.p2align	8
	.type	transpose_8x8_b16,@function
transpose_8x8_b16:                      ; @transpose_8x8_b16
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_lshlrev_b32 v2, 5, v0 :: v_dual_lshrrev_b32 v3, 1, v0
	v_lshlrev_b32_e32 v4, 2, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_bitop3_b32 v2, v2, 0x6e, v3 bitop3:0xc8
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	ds_store_b32 v4, v1
	s_wait_dscnt 0x0
	; wave barrier
	ds_load_u16 v1, v2
	ds_load_u16 v2, v2 offset:16
	s_wait_dscnt 0x0
	v_perm_b32 v1, v2, v1, 0x5040100
	global_store_b32 v0, v1, s[2:3] scale_offset
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
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 5
		.amdhsa_next_free_sgpr 4
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
	.size	transpose_8x8_b16, .Lfunc_end0-transpose_8x8_b16
                                        ; -- End function
	.set transpose_8x8_b16.num_vgpr, 5
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
; codeLenInByte = 120
; TotalNumSgprs: 4
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 5
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
	.protected	high64_mul_mad          ; -- Begin function high64_mul_mad
	.globl	high64_mul_mad
	.p2align	8
	.type	high64_mul_mad,@function
high64_mul_mad:                         ; @high64_mul_mad
; %bb.0:
	s_load_b256 s[4:11], s[0:1], 0x0
	s_mov_b64 s[2:3], 0xffffffff
	s_wait_xcnt 0x0
	s_mov_b32 s1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s13, s1
	s_mov_b32 s15, s1
	s_mov_b32 s17, s1
	s_mov_b32 s18, s1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, s4
	s_and_b64 s[2:3], s[6:7], s[2:3]
	s_mov_b32 s12, s7
	s_mul_u64 s[6:7], s[2:3], s[0:1]
	s_mul_u64 s[20:21], s[12:13], s[0:1]
	s_mov_b32 s0, s7
	s_mov_b32 s14, s5
	s_add_nc_u64 s[4:5], s[20:21], s[0:1]
	s_mul_u64 s[2:3], s[2:3], s[14:15]
	s_mov_b32 s0, s5
	s_mov_b32 s5, s1
	s_mov_b32 s7, s1
	s_add_nc_u64 s[2:3], s[2:3], s[4:5]
	s_mul_u64 s[12:13], s[12:13], s[14:15]
	s_mov_b32 s16, s3
	s_mov_b32 s19, s2
	s_add_nc_u64 s[0:1], s[0:1], s[16:17]
	s_or_b64 s[2:3], s[6:7], s[18:19]
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v2, s2
	s_add_nc_u64 s[0:1], s[12:13], s[0:1]
	s_add_co_u32 s2, s2, s8
	v_dual_mov_b32 v3, s3 :: v_dual_mov_b32 v0, s0
	s_add_co_ci_u32 s3, s3, s9
	s_add_co_ci_u32 s0, s0, 0
	v_dual_mov_b32 v1, s1 :: v_dual_mov_b32 v6, s2
	s_add_co_ci_u32 s1, s1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v4, s0 :: v_dual_mov_b32 v5, s1
	v_mov_b32_e32 v7, s3
	s_clause 0x1
	global_store_b128 v8, v[0:3], s[10:11]
	global_store_b128 v8, v[4:7], s[10:11] offset:16
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
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 9
		.amdhsa_next_free_sgpr 22
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 2
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
	.size	high64_mul_mad, .Lfunc_end1-high64_mul_mad
                                        ; -- End function
	.set high64_mul_mad.num_vgpr, 9
	.set high64_mul_mad.num_agpr, 0
	.set high64_mul_mad.numbered_sgpr, 22
	.set high64_mul_mad.num_named_barrier, 0
	.set high64_mul_mad.private_seg_size, 0
	.set high64_mul_mad.uses_vcc, 0
	.set high64_mul_mad.uses_flat_scratch, 0
	.set high64_mul_mad.has_dyn_sized_stack, 0
	.set high64_mul_mad.has_recursion, 0
	.set high64_mul_mad.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 220
; TotalNumSgprs: 22
; NumVgprs: 9
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 22
; NumVGPRsForWavesPerEU: 9
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
	.protected	high64_signed_mul_mad   ; -- Begin function high64_signed_mul_mad
	.globl	high64_signed_mul_mad
	.p2align	8
	.type	high64_signed_mul_mad,@function
high64_signed_mul_mad:                  ; @high64_signed_mul_mad
; %bb.0:
	s_load_b256 s[4:11], s[0:1], 0x0
	s_mov_b64 s[2:3], 0xffffffff
	s_wait_xcnt 0x0
	s_mov_b32 s1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s13, s1
	s_mov_b32 s15, s1
	s_mov_b32 s17, s1
	s_mov_b32 s18, s1
	s_wait_kmcnt 0x0
	s_mov_b32 s0, s4
	s_and_b64 s[2:3], s[6:7], s[2:3]
	s_mov_b32 s12, s7
	s_mul_u64 s[26:27], s[2:3], s[0:1]
	s_mov_b32 s14, s5
	s_mul_u64 s[24:25], s[12:13], s[0:1]
	s_mov_b32 s0, s27
	s_mul_u64 s[2:3], s[2:3], s[14:15]
	s_mul_u64 s[12:13], s[12:13], s[14:15]
	s_add_nc_u64 s[14:15], s[24:25], s[0:1]
	s_ashr_i32 s20, s5, 31
	s_mov_b32 s0, s15
	s_mov_b32 s15, s1
	s_ashr_i32 s22, s7, 31
	s_add_nc_u64 s[2:3], s[2:3], s[14:15]
	s_mov_b32 s21, s20
	s_mov_b32 s23, s22
	s_mov_b32 s16, s3
	s_mul_u64 s[4:5], s[4:5], s[22:23]
	s_mul_u64 s[6:7], s[20:21], s[6:7]
	s_mov_b32 s27, s1
	s_mov_b32 s19, s2
	s_add_nc_u64 s[0:1], s[0:1], s[16:17]
	s_add_nc_u64 s[4:5], s[6:7], s[4:5]
	s_or_b64 s[2:3], s[26:27], s[18:19]
	s_add_nc_u64 s[0:1], s[12:13], s[0:1]
	s_ashr_i32 s28, s9, 31
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v2, s2
	s_add_nc_u64 s[0:1], s[0:1], s[4:5]
	s_add_co_u32 s2, s2, s8
	v_dual_mov_b32 v3, s3 :: v_dual_mov_b32 v0, s0
	s_add_co_ci_u32 s3, s3, s9
	s_add_co_ci_u32 s0, s0, s28
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_dual_mov_b32 v1, s1 :: v_dual_mov_b32 v4, s0
	s_add_co_ci_u32 s1, s1, s28
	v_dual_mov_b32 v6, s2 :: v_dual_mov_b32 v5, s1
	v_mov_b32_e32 v7, s3
	s_clause 0x1
	global_store_b128 v8, v[0:3], s[10:11]
	global_store_b128 v8, v[4:7], s[10:11] offset:16
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
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 9
		.amdhsa_next_free_sgpr 29
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 2
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
	.size	high64_signed_mul_mad, .Lfunc_end2-high64_signed_mul_mad
                                        ; -- End function
	.set high64_signed_mul_mad.num_vgpr, 9
	.set high64_signed_mul_mad.num_agpr, 0
	.set high64_signed_mul_mad.numbered_sgpr, 29
	.set high64_signed_mul_mad.num_named_barrier, 0
	.set high64_signed_mul_mad.private_seg_size, 0
	.set high64_signed_mul_mad.uses_vcc, 0
	.set high64_signed_mul_mad.uses_flat_scratch, 0
	.set high64_signed_mul_mad.has_dyn_sized_stack, 0
	.set high64_signed_mul_mad.has_recursion, 0
	.set high64_signed_mul_mad.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 252
; TotalNumSgprs: 29
; NumVgprs: 9
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 29
; NumVGPRsForWavesPerEU: 9
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
	.type	__hip_cuid_e9f7a0fb75e7b8a7,@object ; @__hip_cuid_e9f7a0fb75e7b8a7
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_e9f7a0fb75e7b8a7
__hip_cuid_e9f7a0fb75e7b8a7:
	.byte	0                               ; 0x0
	.size	__hip_cuid_e9f7a0fb75e7b8a7, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_e9f7a0fb75e7b8a7
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
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
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         transpose_8x8_b16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     5
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
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
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         high64_mul_mad.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     9
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
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
    .sgpr_count:     29
    .sgpr_spill_count: 0
    .symbol:         high64_signed_mul_mad.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     9
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
