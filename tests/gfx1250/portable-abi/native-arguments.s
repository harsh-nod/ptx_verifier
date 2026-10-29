	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	abi_mixed_byvalue       ; -- Begin function abi_mixed_byvalue
	.globl	abi_mixed_byvalue
	.p2align	8
	.type	abi_mixed_byvalue,@function
abi_mixed_byvalue:                      ; @abi_mixed_byvalue
; %bb.0:
	s_load_b64 s[2:3], s[0:1], 0x18
	s_wait_kmcnt 0x0
	v_cmp_gt_u32_e32 vcc_lo, s2, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_clause 0x1
	s_load_b64 s[4:5], s[0:1], 0x10
	s_load_b32 s6, s[0:1], 0x1c
	s_sext_i32_i16 s3, s3
	s_wait_xcnt 0x0
	s_load_b96 s[0:2], s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_cvt_f32_f64_e32 v1, s[4:5]
	v_cvt_f32_ubyte2_e32 v2, s6
	s_delay_alu instid0(VALU_DEP_2)
	v_add_f32_e32 v1, s2, v1
	s_cvt_f32_i32 s2, s3
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_3)
	v_add_f32_e32 v1, s2, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_add_f32_e32 v1, v1, v2
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB0_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_mixed_byvalue
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
		.amdhsa_next_free_vgpr 3
		.amdhsa_next_free_sgpr 7
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
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
	.size	abi_mixed_byvalue, .Lfunc_end0-abi_mixed_byvalue
                                        ; -- End function
	.set abi_mixed_byvalue.num_vgpr, 3
	.set abi_mixed_byvalue.num_agpr, 0
	.set abi_mixed_byvalue.numbered_sgpr, 7
	.set abi_mixed_byvalue.num_named_barrier, 0
	.set abi_mixed_byvalue.private_seg_size, 0
	.set abi_mixed_byvalue.uses_vcc, 1
	.set abi_mixed_byvalue.uses_flat_scratch, 0
	.set abi_mixed_byvalue.has_dyn_sized_stack, 0
	.set abi_mixed_byvalue.has_recursion, 0
	.set abi_mixed_byvalue.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 116
; TotalNumSgprs: 9
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 3
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
	.protected	abi_grid_dimensions     ; -- Begin function abi_grid_dimensions
	.globl	abi_grid_dimensions
	.p2align	8
	.type	abi_grid_dimensions,@function
abi_grid_dimensions:                    ; @abi_grid_dimensions
; %bb.0:
	v_and_b32_e32 v0, 0x3fffffff, v0
	s_mov_b32 s2, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_2
; %bb.1:
	s_clause 0x2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b96 s[8:10], s[0:1], 0x10
	s_load_u16 s2, s[0:1], 0x16
	s_wait_xcnt 0x0
	s_bfe_u32 s1, ttmp6, 0x40014
	s_bfe_u32 s12, ttmp6, 0x40010
	s_bfe_u32 s15, ttmp6, 0x4000c
	s_lshr_b32 s0, ttmp7, 16
	s_and_b32 s11, ttmp7, 0xffff
	s_add_co_i32 s1, s1, 1
	s_add_co_i32 s12, s12, 1
	s_add_co_i32 s15, s15, 1
	s_bfe_u32 s3, ttmp6, 0x40008
	s_bfe_u32 s13, ttmp6, 0x40004
	s_and_b32 s14, ttmp6, 15
	s_mul_i32 s1, s0, s1
	s_mul_i32 s12, s11, s12
	s_mul_i32 s15, ttmp9, s15
	s_getreg_b32 s16, hwreg(HW_REG_IB_STS2, 6, 4)
	v_mov_b32_e32 v0, 0
	s_add_co_i32 s3, s3, s1
	s_add_co_i32 s13, s13, s12
	s_add_co_i32 s14, s14, s15
	s_cmp_eq_u32 s16, 0
	s_wait_kmcnt 0x0
	v_mov_b32_e32 v1, s6
	s_cselect_b32 s1, ttmp9, s14
	v_dual_mov_b32 v2, s7 :: v_dual_mov_b32 v3, s8
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_cselect_b32 s0, s0, s3
	global_store_b32 v0, v1, s[4:5]
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	global_store_b32 v0, v2, s[4:5] offset:4
	;;#ASMSTART
	v_add_nc_u32 v3, 0, v3
	;;#ASMEND
	s_wait_xcnt 0x1
	v_mov_b32_e32 v1, s1
	s_cselect_b32 s1, s11, s13
	global_store_b32 v0, v3, s[4:5] offset:8
	s_wait_xcnt 0x0
	v_mov_b32_e32 v3, s0
	s_and_b32 s0, s9, 0xffff
	v_mov_b32_e32 v2, s1
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[4:5] offset:12
	s_wait_xcnt 0x0
	v_mov_b32_e32 v1, s0
	s_and_b32 s0, s10, 0xffff
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	global_store_b32 v0, v2, s[4:5] offset:16
	;;#ASMSTART
	v_add_nc_u32 v3, 0, v3
	;;#ASMEND
	s_wait_xcnt 0x0
	v_mov_b32_e32 v2, s2
	global_store_b32 v0, v3, s[4:5] offset:20
	s_wait_xcnt 0x0
	v_mov_b32_e32 v3, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[4:5] offset:24
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	global_store_b32 v0, v2, s[4:5] offset:28
	;;#ASMSTART
	v_add_nc_u32 v3, 0, v3
	;;#ASMEND
	global_store_b32 v0, v3, s[4:5] offset:32
.LBB1_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_grid_dimensions
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 264
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 17
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 3
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
	.size	abi_grid_dimensions, .Lfunc_end1-abi_grid_dimensions
                                        ; -- End function
	.set abi_grid_dimensions.num_vgpr, 4
	.set abi_grid_dimensions.num_agpr, 0
	.set abi_grid_dimensions.numbered_sgpr, 17
	.set abi_grid_dimensions.num_named_barrier, 0
	.set abi_grid_dimensions.private_seg_size, 0
	.set abi_grid_dimensions.uses_vcc, 0
	.set abi_grid_dimensions.uses_flat_scratch, 0
	.set abi_grid_dimensions.has_dyn_sized_stack, 0
	.set abi_grid_dimensions.has_recursion, 0
	.set abi_grid_dimensions.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 360
; TotalNumSgprs: 17
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 17
; NumVGPRsForWavesPerEU: 4
; NamedBarCnt: 0
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_dbc2e07d22d6d954,@object ; @__hip_cuid_dbc2e07d22d6d954
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_dbc2e07d22d6d954
__hip_cuid_dbc2e07d22d6d954:
	.byte	0                               ; 0x0
	.size	__hip_cuid_dbc2e07d22d6d954, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_dbc2e07d22d6d954
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           8
        .value_kind:     by_value
      - .offset:         24
        .size:           4
        .value_kind:     by_value
      - .offset:         28
        .size:           2
        .value_kind:     by_value
      - .offset:         30
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
    .name:           abi_mixed_byvalue
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         abi_mixed_byvalue.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         12
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         20
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         22
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         24
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         26
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         28
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         30
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         72
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 264
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_grid_dimensions
    .private_segment_fixed_size: 0
    .sgpr_count:     17
    .sgpr_spill_count: 0
    .symbol:         abi_grid_dimensions.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
