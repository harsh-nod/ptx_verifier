	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	exact_wave_elect        ; -- Begin function exact_wave_elect
	.globl	exact_wave_elect
	.p2align	8
	.type	exact_wave_elect,@function
exact_wave_elect:                       ; @exact_wave_elect
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_readfirstlane_b32 s2, v0
	s_add_co_i32 s3, s2, 0x3e8
	v_cmp_eq_u32_e32 vcc_lo, s2, v0
	s_cvt_f32_u32 s3, s3
	s_delay_alu instid0(SALU_CYCLE_3)
	v_cndmask_b32_e64 v1, 0, s3, vcc_lo
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_elect
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
		.amdhsa_next_free_sgpr 4
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
	.size	exact_wave_elect, .Lfunc_end0-exact_wave_elect
                                        ; -- End function
	.set exact_wave_elect.num_vgpr, 2
	.set exact_wave_elect.num_agpr, 0
	.set exact_wave_elect.numbered_sgpr, 4
	.set exact_wave_elect.num_named_barrier, 0
	.set exact_wave_elect.private_seg_size, 0
	.set exact_wave_elect.uses_vcc, 1
	.set exact_wave_elect.uses_flat_scratch, 0
	.set exact_wave_elect.has_dyn_sized_stack, 0
	.set exact_wave_elect.has_recursion, 0
	.set exact_wave_elect.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	exact_wave_elect_skip   ; -- Begin function exact_wave_elect_skip
	.globl	exact_wave_elect_skip
	.p2align	8
	.type	exact_wave_elect_skip,@function
exact_wave_elect_skip:                  ; @exact_wave_elect_skip
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_ne_u32_e32 0, v0
	s_cbranch_execz .LBB1_2
; %bb.1:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_readfirstlane_b32 s2, v0
	s_add_co_i32 s3, s2, 0x3e8
	v_cmp_eq_u32_e32 vcc_lo, s2, v0
	s_cvt_f32_u32 s3, s3
	s_delay_alu instid0(SALU_CYCLE_3)
	v_cndmask_b32_e64 v1, 0, s3, vcc_lo
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] scale_offset
.LBB1_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_elect_skip
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
		.amdhsa_next_free_sgpr 4
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
.Lfunc_end1:
	.size	exact_wave_elect_skip, .Lfunc_end1-exact_wave_elect_skip
                                        ; -- End function
	.set exact_wave_elect_skip.num_vgpr, 2
	.set exact_wave_elect_skip.num_agpr, 0
	.set exact_wave_elect_skip.numbered_sgpr, 4
	.set exact_wave_elect_skip.num_named_barrier, 0
	.set exact_wave_elect_skip.private_seg_size, 0
	.set exact_wave_elect_skip.uses_vcc, 1
	.set exact_wave_elect_skip.uses_flat_scratch, 0
	.set exact_wave_elect_skip.has_dyn_sized_stack, 0
	.set exact_wave_elect_skip.has_recursion, 0
	.set exact_wave_elect_skip.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 72
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	exact_wave_exchange     ; -- Begin function exact_wave_exchange
	.globl	exact_wave_exchange
	.p2align	8
	.type	exact_wave_exchange,@function
exact_wave_exchange:                    ; @exact_wave_exchange
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_lshlrev_b32_e32 v2, 2, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_xor_b32_e32 v2, 4, v2
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	ds_bpermute_b32 v1, v2, v1
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_exchange
		.amdhsa_group_segment_fixed_size 0
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
		.amdhsa_next_free_vgpr 3
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
.Lfunc_end2:
	.size	exact_wave_exchange, .Lfunc_end2-exact_wave_exchange
                                        ; -- End function
	.set exact_wave_exchange.num_vgpr, 3
	.set exact_wave_exchange.num_agpr, 0
	.set exact_wave_exchange.numbered_sgpr, 4
	.set exact_wave_exchange.num_named_barrier, 0
	.set exact_wave_exchange.private_seg_size, 0
	.set exact_wave_exchange.uses_vcc, 0
	.set exact_wave_exchange.uses_flat_scratch, 0
	.set exact_wave_exchange.has_dyn_sized_stack, 0
	.set exact_wave_exchange.has_recursion, 0
	.set exact_wave_exchange.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 68
; TotalNumSgprs: 4
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_wave_tail_sum     ; -- Begin function exact_wave_tail_sum
	.globl	exact_wave_tail_sum
	.p2align	8
	.type	exact_wave_tail_sum,@function
exact_wave_tail_sum:                    ; @exact_wave_tail_sum
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 16, v0
	s_cbranch_execz .LBB3_3
; %bb.1:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_add_nc_u32 v1, 8, v0 :: v_dual_add_nc_u32 v3, 4, v0
	v_cmp_gt_u32_e32 vcc_lo, 8, v0
	v_add_nc_u32_e32 v4, 2, v0
	s_wait_kmcnt 0x0
	global_load_b32 v2, v0, s[0:1] scale_offset
	s_wait_xcnt 0x0
	v_cmp_gt_u32_e64 s0, 12, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_cndmask_b32 v1, v0, v1, vcc_lo :: v_dual_cndmask_b32 v3, v0, v3, s0
	v_dual_lshlrev_b32 v1, 2, v1 :: v_dual_lshlrev_b32 v3, 2, v3
	s_wait_loadcnt 0x0
	ds_bpermute_b32 v1, v1, v2
	s_wait_dscnt 0x0
	v_add_f32_e32 v1, v2, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_cndmask_b32_e32 v1, v2, v1, vcc_lo
	v_cmp_gt_u32_e32 vcc_lo, 14, v0
	v_cndmask_b32_e32 v4, v0, v4, vcc_lo
	ds_bpermute_b32 v3, v3, v1
	s_wait_dscnt 0x0
	v_dual_add_f32 v1, v1, v3 :: v_dual_lshlrev_b32 v3, 2, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)
	v_dual_add_nc_u32 v4, 1, v0 :: v_dual_cndmask_b32 v1, v2, v1, s0
	v_cmp_ne_u32_e64 s0, 15, v0
	ds_bpermute_b32 v3, v3, v1
	s_wait_dscnt 0x0
	v_dual_add_f32 v1, v1, v3 :: v_dual_cndmask_b32 v3, 15, v4, s0
	v_dual_cndmask_b32 v2, v2, v1 :: v_dual_lshlrev_b32 v3, 2, v3
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	ds_bpermute_b32 v2, v3, v2
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_3
; %bb.2:
	s_wait_dscnt 0x0
	v_dual_add_f32 v1, v1, v2 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
.LBB3_3:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_tail_sum
		.amdhsa_group_segment_fixed_size 0
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
		.amdhsa_reserve_vcc 1
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
.Lfunc_end3:
	.size	exact_wave_tail_sum, .Lfunc_end3-exact_wave_tail_sum
                                        ; -- End function
	.set exact_wave_tail_sum.num_vgpr, 5
	.set exact_wave_tail_sum.num_agpr, 0
	.set exact_wave_tail_sum.numbered_sgpr, 4
	.set exact_wave_tail_sum.num_named_barrier, 0
	.set exact_wave_tail_sum.private_seg_size, 0
	.set exact_wave_tail_sum.uses_vcc, 1
	.set exact_wave_tail_sum.uses_flat_scratch, 0
	.set exact_wave_tail_sum.has_dyn_sized_stack, 0
	.set exact_wave_tail_sum.has_recursion, 0
	.set exact_wave_tail_sum.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 260
; TotalNumSgprs: 6
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	exact_wave_tail_reference ; -- Begin function exact_wave_tail_reference
	.globl	exact_wave_tail_reference
	.p2align	8
	.type	exact_wave_tail_reference,@function
exact_wave_tail_reference:              ; @exact_wave_tail_reference
; %bb.0:
	s_load_b128 s[16:19], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b512 s[0:15], s[16:17], 0x0
	s_wait_kmcnt 0x0
	s_add_f32 s0, s0, s1
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s2
	s_add_f32 s0, s0, s3
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s4
	s_add_f32 s0, s0, s5
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s6
	s_add_f32 s0, s0, s7
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s8
	s_add_f32 s0, s0, s9
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s10
	s_add_f32 s0, s0, s11
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s12
	s_add_f32 s0, s0, s13
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_add_f32 s0, s0, s14
	s_add_f32 s0, s0, s15
	s_delay_alu instid0(SALU_CYCLE_3)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[18:19]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_tail_reference
		.amdhsa_group_segment_fixed_size 0
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 20
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
.Lfunc_end4:
	.size	exact_wave_tail_reference, .Lfunc_end4-exact_wave_tail_reference
                                        ; -- End function
	.set exact_wave_tail_reference.num_vgpr, 2
	.set exact_wave_tail_reference.num_agpr, 0
	.set exact_wave_tail_reference.numbered_sgpr, 20
	.set exact_wave_tail_reference.num_named_barrier, 0
	.set exact_wave_tail_reference.private_seg_size, 0
	.set exact_wave_tail_reference.uses_vcc, 0
	.set exact_wave_tail_reference.uses_flat_scratch, 0
	.set exact_wave_tail_reference.has_dyn_sized_stack, 0
	.set exact_wave_tail_reference.has_recursion, 0
	.set exact_wave_tail_reference.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 140
; TotalNumSgprs: 20
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 20
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
	.protected	exact_wave_divergent_leaders ; -- Begin function exact_wave_divergent_leaders
	.globl	exact_wave_divergent_leaders
	.p2align	8
	.type	exact_wave_divergent_leaders,@function
exact_wave_divergent_leaders:           ; @exact_wave_divergent_leaders
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	s_mov_b32 s2, exec_lo
	v_cmpx_lt_u32_e32 15, v0
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execz .LBB5_4
; %bb.1:
	v_readfirstlane_b32 s3, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_eq_u32_e32 vcc_lo, s3, v0
	s_and_saveexec_b32 s3, vcc_lo
	s_cbranch_execz .LBB5_3
; %bb.2:
	v_dual_mov_b32 v1, 2.0 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1] offset:4
.LBB5_3:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s3
                                        ; implicit-def: $vgpr0
.LBB5_4:
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB5_7
; %bb.5:
	v_readfirstlane_b32 s2, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_eq_u32_e32 vcc_lo, s2, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_7
; %bb.6:
	v_dual_mov_b32 v1, 1.0 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
.LBB5_7:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_divergent_leaders
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
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
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
.Lfunc_end5:
	.size	exact_wave_divergent_leaders, .Lfunc_end5-exact_wave_divergent_leaders
                                        ; -- End function
	.set exact_wave_divergent_leaders.num_vgpr, 2
	.set exact_wave_divergent_leaders.num_agpr, 0
	.set exact_wave_divergent_leaders.numbered_sgpr, 4
	.set exact_wave_divergent_leaders.num_named_barrier, 0
	.set exact_wave_divergent_leaders.private_seg_size, 0
	.set exact_wave_divergent_leaders.uses_vcc, 1
	.set exact_wave_divergent_leaders.uses_flat_scratch, 0
	.set exact_wave_divergent_leaders.has_dyn_sized_stack, 0
	.set exact_wave_divergent_leaders.has_recursion, 0
	.set exact_wave_divergent_leaders.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 132
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	exact_wave_memory_exchange ; -- Begin function exact_wave_memory_exchange
	.globl	exact_wave_memory_exchange
	.p2align	8
	.type	exact_wave_memory_exchange,@function
exact_wave_memory_exchange:             ; @exact_wave_memory_exchange
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b64 s[4:5], src_shared_base
	v_and_b32_e32 v2, 31, v0
	v_cvt_f32_ubyte0_e32 v3, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v2, 2, v2 :: v_dual_bitop2_b32 v4, 32, v0 bitop3:0x14
	v_xor_b32_e32 v2, 4, v2
	ds_bpermute_b32 v5, v2, v3
	v_dual_mov_b32 v3, s5 :: v_dual_lshlrev_b32 v2, 2, v0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_lshlrev_b32_e32 v2, 2, v4
	s_wait_dscnt 0x1
	;;#ASMSTART
	;;#ASMEND
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b32 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_fmac_f32_e32 v1, 0, v5
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_wave_memory_exchange
		.amdhsa_group_segment_fixed_size 256
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
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 6
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
.Lfunc_end6:
	.size	exact_wave_memory_exchange, .Lfunc_end6-exact_wave_memory_exchange
                                        ; -- End function
	.set exact_wave_memory_exchange.num_vgpr, 6
	.set exact_wave_memory_exchange.num_agpr, 0
	.set exact_wave_memory_exchange.numbered_sgpr, 6
	.set exact_wave_memory_exchange.num_named_barrier, 0
	.set exact_wave_memory_exchange.private_seg_size, 0
	.set exact_wave_memory_exchange.uses_vcc, 0
	.set exact_wave_memory_exchange.uses_flat_scratch, 0
	.set exact_wave_memory_exchange.has_dyn_sized_stack, 0
	.set exact_wave_memory_exchange.has_recursion, 0
	.set exact_wave_memory_exchange.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 152
; TotalNumSgprs: 6
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 256 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 6
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
	.type	__hip_cuid_9ea92ff784246c2f,@object ; @__hip_cuid_9ea92ff784246c2f
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_9ea92ff784246c2f
__hip_cuid_9ea92ff784246c2f:
	.byte	0                               ; 0x0
	.size	__hip_cuid_9ea92ff784246c2f, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_9ea92ff784246c2f
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
    .max_flat_workgroup_size: 32
    .name:           exact_wave_elect
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_wave_elect.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
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
    .max_flat_workgroup_size: 32
    .name:           exact_wave_elect_skip
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_wave_elect_skip.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 2
    .name:           exact_wave_exchange
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_wave_exchange.kd
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
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           exact_wave_tail_sum
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_wave_tail_sum.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     5
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_wave_tail_reference
    .private_segment_fixed_size: 0
    .sgpr_count:     20
    .sgpr_spill_count: 0
    .symbol:         exact_wave_tail_reference.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
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
    .max_flat_workgroup_size: 32
    .name:           exact_wave_divergent_leaders
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_wave_divergent_leaders.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 256
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           exact_wave_memory_exchange
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_wave_memory_exchange.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
