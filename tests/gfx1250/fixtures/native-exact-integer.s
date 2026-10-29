	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	exact_b16_shift_count_u32 ; -- Begin function exact_b16_shift_count_u32
	.globl	exact_b16_shift_count_u32
	.p2align	8
	.type	exact_b16_shift_count_u32,@function
exact_b16_shift_count_u32:              ; @exact_b16_shift_count_u32
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_mov_b32_e32 v3, 0x10000
	v_dual_mov_b32 v1, 1 :: v_dual_mov_b32 v2, 0x8000
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_bfe_i32 v0, v2, 0, 16
	v_lshlrev_b32_e32 v1, v3, v1
	v_and_b32_e32 v2, 0xffff, v2
	v_cmp_gt_u32_e32 vcc_lo, 16, v3
	v_ashrrev_i32_e32 v0, v3, v0
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_and_b32_e32 v1, 0xffff, v1
	v_lshrrev_b32_e32 v2, v3, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_and_b32_e32 v0, 0xffff, v0
	v_dual_cndmask_b32 v3, 0, v1, vcc_lo :: v_dual_mov_b32 v1, 0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_cndmask_b32_e32 v2, 0, v2, vcc_lo
	;;#ASMSTART
	v_add_nc_u32 v3, 0, v3
	;;#ASMEND
	v_cndmask_b32_e32 v0, 0xffff, v0, vcc_lo
	s_wait_kmcnt 0x0
	global_store_b32 v1, v3, s[0:1]
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	global_store_b32 v1, v2, s[0:1] offset:4
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v1, v0, s[0:1] offset:8
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_b16_shift_count_u32
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end0:
	.size	exact_b16_shift_count_u32, .Lfunc_end0-exact_b16_shift_count_u32
                                        ; -- End function
	.set exact_b16_shift_count_u32.num_vgpr, 4
	.set exact_b16_shift_count_u32.num_agpr, 0
	.set exact_b16_shift_count_u32.numbered_sgpr, 2
	.set exact_b16_shift_count_u32.num_named_barrier, 0
	.set exact_b16_shift_count_u32.private_seg_size, 0
	.set exact_b16_shift_count_u32.uses_vcc, 1
	.set exact_b16_shift_count_u32.uses_flat_scratch, 0
	.set exact_b16_shift_count_u32.has_dyn_sized_stack, 0
	.set exact_b16_shift_count_u32.has_recursion, 0
	.set exact_b16_shift_count_u32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 160
; TotalNumSgprs: 4
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_b64_shift_u32     ; -- Begin function exact_b64_shift_u32
	.globl	exact_b64_shift_u32
	.p2align	8
	.type	exact_b64_shift_u32,@function
exact_b64_shift_u32:                    ; @exact_b64_shift_u32
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_mov_b64_e32 v[0:1], 3
	v_dual_mov_b32 v2, 40 :: v_dual_mov_b32 v4, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b64_e32 v[0:1], v2, v[0:1]
	v_lshrrev_b64 v[2:3], v2, v[0:1]
	s_wait_kmcnt 0x0
	global_store_b128 v4, v[0:3], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_b64_shift_u32
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
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end1:
	.size	exact_b64_shift_u32, .Lfunc_end1-exact_b64_shift_u32
                                        ; -- End function
	.set exact_b64_shift_u32.num_vgpr, 5
	.set exact_b64_shift_u32.num_agpr, 0
	.set exact_b64_shift_u32.numbered_sgpr, 2
	.set exact_b64_shift_u32.num_named_barrier, 0
	.set exact_b64_shift_u32.private_seg_size, 0
	.set exact_b64_shift_u32.uses_vcc, 0
	.set exact_b64_shift_u32.uses_flat_scratch, 0
	.set exact_b64_shift_u32.has_dyn_sized_stack, 0
	.set exact_b64_shift_u32.has_recursion, 0
	.set exact_b64_shift_u32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 60
; TotalNumSgprs: 2
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_bfe_clipping      ; -- Begin function exact_bfe_clipping
	.globl	exact_bfe_clipping
	.p2align	8
	.type	exact_bfe_clipping,@function
exact_bfe_clipping:                     ; @exact_bfe_clipping
; %bb.0:
	v_dual_mov_b32 v1, 10 :: v_dual_mov_b32 v0, -1
	v_dual_mov_b32 v4, 0 :: v_dual_mov_b32 v5, 4
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_cmp_lt_u32_e32 vcc_lo, 31, v4
	v_cmp_eq_u32_e64 s2, 0, v5
	v_dual_mov_b32 v2, 0 :: v_dual_mov_b32 v3, 4
	v_mov_b32_e32 v6, 0
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 vcc_lo, exec_lo, s2
	s_cbranch_vccnz .LBB2_2
; %bb.1:
	v_dual_sub_nc_u32 v6, 32, v4 :: v_dual_lshrrev_b32 v4, v4, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_min_u32_e32 v5, v5, v6
	v_lshlrev_b32_e64 v6, v5, -1
	v_cmp_ne_u32_e32 vcc_lo, 32, v5
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_not_b32_e32 v6, v6
	v_cndmask_b32_e32 v5, -1, v6, vcc_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_b32_e32 v6, v5, v4
.LBB2_2:
	s_load_b64 s[2:3], s[0:1], 0x0
	v_mov_b32_e32 v4, 0
	;;#ASMSTART
	v_add_nc_u32 v5, 0, v6
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v2, v5, s[2:3]
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_cmp_eq_u32_e32 vcc_lo, 0, v3
	s_and_b32 s0, vcc_lo, exec_lo
	s_cbranch_scc1 .LBB2_7
; %bb.3:
	v_cmp_gt_u32_e32 vcc_lo, 32, v4
	s_cbranch_vccz .LBB2_5
; %bb.4:
	s_wait_xcnt 0x0
	v_sub_nc_u32_e32 v2, 32, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_min_u32_e32 v3, v3, v2
	v_dual_sub_nc_u32 v2, v2, v3 :: v_dual_sub_nc_u32 v3, 32, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v2, v2, v1
	v_ashrrev_i32_e32 v2, v3, v2
	s_cbranch_execz .LBB2_6
	s_branch .LBB2_7
.LBB2_5:
                                        ; implicit-def: $vgpr2
.LBB2_6:
	s_wait_xcnt 0x0
	v_ashrrev_i32_e32 v2, 31, v1
.LBB2_7:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v4, 40
	s_wait_xcnt 0x0
	v_mov_b32_e32 v5, 4
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	v_mov_b32_e32 v3, 0
	global_store_b32 v1, v2, s[2:3] offset:4
	;;#ASMSTART
	;;#ASMEND
	s_wait_xcnt 0x0
	v_mov_b32_e32 v2, 4
	;;#ASMSTART
	;;#ASMEND
	v_cmp_eq_u32_e32 vcc_lo, 0, v5
	s_and_b32 s0, vcc_lo, exec_lo
	s_cbranch_scc1 .LBB2_12
; %bb.8:
	v_cmp_gt_u32_e32 vcc_lo, 32, v4
	s_cbranch_vccz .LBB2_10
; %bb.9:
	v_sub_nc_u32_e32 v3, 32, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_min_u32_e32 v4, v5, v3
	v_dual_sub_nc_u32 v3, v3, v4 :: v_dual_sub_nc_u32 v4, 32, v4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, v3, v0
	v_ashrrev_i32_e32 v3, v4, v3
	s_cbranch_execz .LBB2_11
	s_branch .LBB2_12
.LBB2_10:
                                        ; implicit-def: $vgpr3
.LBB2_11:
	v_ashrrev_i32_e32 v3, 31, v0
.LBB2_12:
	v_mov_b32_e32 v4, 0
	;;#ASMSTART
	v_add_nc_u32 v3, 0, v3
	;;#ASMEND
	global_store_b32 v1, v3, s[2:3] offset:8
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_cmp_lt_u32_e32 vcc_lo, 31, v2
	v_cmp_eq_u32_e64 s0, 0, v4
	s_or_b32 s0, vcc_lo, s0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB2_14
; %bb.13:
	s_wait_xcnt 0x0
	v_dual_sub_nc_u32 v1, 32, v2 :: v_dual_lshrrev_b32 v0, v2, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_min_u32_e32 v1, v4, v1
	v_lshlrev_b32_e64 v3, v1, -1
	v_cmp_ne_u32_e32 vcc_lo, 32, v1
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_not_b32_e32 v3, v3
	v_cndmask_b32_e32 v1, -1, v3, vcc_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_and_b32_e32 v1, v1, v0
.LBB2_14:
	v_mov_b32_e32 v0, 0
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:12
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_bfe_clipping
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
		.amdhsa_next_free_vgpr 7
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
		.amdhsa_inst_pref_size 4
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
	.size	exact_bfe_clipping, .Lfunc_end2-exact_bfe_clipping
                                        ; -- End function
	.set exact_bfe_clipping.num_vgpr, 7
	.set exact_bfe_clipping.num_agpr, 0
	.set exact_bfe_clipping.numbered_sgpr, 4
	.set exact_bfe_clipping.num_named_barrier, 0
	.set exact_bfe_clipping.private_seg_size, 0
	.set exact_bfe_clipping.uses_vcc, 1
	.set exact_bfe_clipping.uses_flat_scratch, 0
	.set exact_bfe_clipping.has_dyn_sized_stack, 0
	.set exact_bfe_clipping.has_recursion, 0
	.set exact_bfe_clipping.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 444
; TotalNumSgprs: 6
; NumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 7
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
	.protected	exact_bfi_clipping      ; -- Begin function exact_bfi_clipping
	.globl	exact_bfi_clipping
	.p2align	8
	.type	exact_bfi_clipping,@function
exact_bfi_clipping:                     ; @exact_bfi_clipping
; %bb.0:
	v_dual_mov_b32 v3, 3 :: v_dual_mov_b32 v0, 0
	v_dual_mov_b32 v4, 4 :: v_dual_mov_b32 v5, 2
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_cmp_lt_u32_e32 vcc_lo, 31, v4
	v_cmp_eq_u32_e64 s2, 0, v5
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 4
	v_readfirstlane_b32 s3, v4
	s_or_b32 s4, vcc_lo, s2
	v_readfirstlane_b32 s2, v5
	s_and_b32 vcc_lo, exec_lo, s4
	s_cbranch_vccnz .LBB3_2
; %bb.1:
	s_sub_co_i32 s4, 32, s3
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_min_u32 s2, s2, s4
	s_lshl_b32 s4, -1, s2
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_not_b32 s4, s4
	s_cmp_lg_u32 s2, 32
	s_cselect_b32 s2, s4, -1
	s_lshl_b32 s4, s2, s3
	v_and_b32_e32 v3, s2, v3
	v_not_b32_e32 v4, s4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v3, s3, v3 :: v_dual_bitop2_b32 v0, v0, v4 bitop3:0x40
	v_or_b32_e32 v0, v0, v3
.LBB3_2:
	s_load_b64 s[2:3], s[0:1], 0x0
	v_dual_mov_b32 v4, 5 :: v_dual_mov_b32 v5, 64
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	v_mov_b32_e32 v3, 64
	s_wait_kmcnt 0x0
	global_store_b32 v1, v0, s[2:3]
	s_wait_xcnt 0x0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_cmp_lt_u32_e32 vcc_lo, 31, v2
	v_cmp_eq_u32_e64 s0, 0, v5
	v_mov_b32_e32 v0, 5
	v_readfirstlane_b32 s1, v2
	s_or_b32 s4, vcc_lo, s0
	v_readfirstlane_b32 s0, v5
	s_and_b32 vcc_lo, exec_lo, s4
	s_cbranch_vccnz .LBB3_4
; %bb.3:
	s_sub_co_i32 s4, 32, s1
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_min_u32 s0, s0, s4
	s_lshl_b32 s4, -1, s0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_not_b32 s4, s4
	s_cmp_lg_u32 s0, 32
	s_cselect_b32 s0, s4, -1
	s_lshl_b32 s4, s0, s1
	v_and_b32_e32 v1, s0, v1
	v_not_b32_e32 v2, s4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v1, s1, v1 :: v_dual_bitop2_b32 v2, v4, v2 bitop3:0x40
	v_or_b32_e32 v4, v2, v1
.LBB3_4:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v5, -1
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v4
	;;#ASMEND
	v_mov_b32_e32 v4, 4
	global_store_b32 v1, v2, s[2:3] offset:4
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	v_cmp_lt_u32_e32 vcc_lo, 31, v3
	s_wait_xcnt 0x0
	v_mov_b32_e32 v2, -1
	;;#ASMSTART
	;;#ASMEND
	v_cmp_eq_u32_e64 s0, 0, v4
	v_readfirstlane_b32 s1, v3
	s_or_b32 s4, vcc_lo, s0
	v_readfirstlane_b32 s0, v4
	s_and_b32 vcc_lo, exec_lo, s4
	s_cbranch_vccnz .LBB3_6
; %bb.5:
	s_sub_co_i32 s4, 32, s1
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_min_u32 s0, s0, s4
	s_lshl_b32 s4, -1, s0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_not_b32 s4, s4
	s_cmp_lg_u32 s0, 32
	s_cselect_b32 s0, s4, -1
	s_lshl_b32 s4, s0, s1
	v_and_b32_e32 v4, s0, v5
	v_not_b32_e32 v3, s4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v3, s1, v4 :: v_dual_bitop2_b32 v0, v0, v3 bitop3:0x40
	v_or_b32_e32 v0, v0, v3
.LBB3_6:
	v_dual_mov_b32 v3, 7 :: v_dual_mov_b32 v4, 40
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v1, v0, s[2:3] offset:8
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_wait_xcnt 0x0
	;;#ASMSTART
	;;#ASMEND
	v_cmp_lt_u32_e32 vcc_lo, 31, v4
	v_cmp_eq_u32_e64 s0, 0, v1
	v_readfirstlane_b32 s1, v4
	s_or_b32 s4, vcc_lo, s0
	v_readfirstlane_b32 s0, v1
	s_and_b32 vcc_lo, exec_lo, s4
	s_cbranch_vccnz .LBB3_8
; %bb.7:
	s_sub_co_i32 s4, 32, s1
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_min_u32 s0, s0, s4
	s_lshl_b32 s4, -1, s0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_not_b32 s4, s4
	s_cmp_lg_u32 s0, 32
	s_cselect_b32 s0, s4, -1
	s_lshl_b32 s4, s0, s1
	v_and_b32_e32 v1, s0, v2
	v_not_b32_e32 v0, s4
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_lshlrev_b32 v1, s1, v1 :: v_dual_bitop2_b32 v0, v3, v0 bitop3:0x40
	v_or_b32_e32 v3, v0, v1
.LBB3_8:
	v_mov_b32_e32 v0, 0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v3
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:12
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_bfi_clipping
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
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 5
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 5
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
	.size	exact_bfi_clipping, .Lfunc_end3-exact_bfi_clipping
                                        ; -- End function
	.set exact_bfi_clipping.num_vgpr, 6
	.set exact_bfi_clipping.num_agpr, 0
	.set exact_bfi_clipping.numbered_sgpr, 5
	.set exact_bfi_clipping.num_named_barrier, 0
	.set exact_bfi_clipping.private_seg_size, 0
	.set exact_bfi_clipping.uses_vcc, 1
	.set exact_bfi_clipping.uses_flat_scratch, 0
	.set exact_bfi_clipping.has_dyn_sized_stack, 0
	.set exact_bfi_clipping.has_recursion, 0
	.set exact_bfi_clipping.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 532
; TotalNumSgprs: 7
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 7
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
	.protected	exact_declined_cancel_one_pass ; -- Begin function exact_declined_cancel_one_pass
	.globl	exact_declined_cancel_one_pass
	.p2align	8
	.type	exact_declined_cancel_one_pass,@function
exact_declined_cancel_one_pass:         ; @exact_declined_cancel_one_pass
; %bb.0:
	s_clause 0x1
	s_load_b32 s2, s[0:1], 0x1c
	s_load_b128 s[4:7], s[0:1], 0x0
	s_wait_xcnt 0x0
	s_bfe_u32 s0, ttmp6, 0x4000c
	s_and_b32 s1, ttmp6, 15
	s_add_co_i32 s0, s0, 1
	s_getreg_b32 s3, hwreg(HW_REG_IB_STS2, 6, 4)
	s_mul_i32 s0, ttmp9, s0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	s_add_co_i32 s1, s1, s0
	s_wait_kmcnt 0x0
	s_and_b32 s2, s2, 0xffff
	s_cmp_eq_u32 s3, 0
	s_cselect_b32 s0, ttmp9, s1
	v_mad_u32 v0, s0, s2, v0
	global_load_b32 v1, v0, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	v_add_f32_e32 v1, v1, v1
	global_store_b32 v0, v1, s[6:7] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_declined_cancel_one_pass
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
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
		.amdhsa_next_free_sgpr 8
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
.Lfunc_end4:
	.size	exact_declined_cancel_one_pass, .Lfunc_end4-exact_declined_cancel_one_pass
                                        ; -- End function
	.set exact_declined_cancel_one_pass.num_vgpr, 2
	.set exact_declined_cancel_one_pass.num_agpr, 0
	.set exact_declined_cancel_one_pass.numbered_sgpr, 8
	.set exact_declined_cancel_one_pass.num_named_barrier, 0
	.set exact_declined_cancel_one_pass.private_seg_size, 0
	.set exact_declined_cancel_one_pass.uses_vcc, 0
	.set exact_declined_cancel_one_pass.uses_flat_scratch, 0
	.set exact_declined_cancel_one_pass.has_dyn_sized_stack, 0
	.set exact_declined_cancel_one_pass.has_recursion, 0
	.set exact_declined_cancel_one_pass.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 120
; TotalNumSgprs: 8
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 8
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
	.protected	exact_int_abs_signed_width ; -- Begin function exact_int_abs_signed_width
	.globl	exact_int_abs_signed_width
	.p2align	8
	.type	exact_int_abs_signed_width,@function
exact_int_abs_signed_width:             ; @exact_int_abs_signed_width
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_mov_b32_e32 v2, -5
	v_bfrev_b32_e32 v3, 1
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_sub_nc_u32 v1, 0, v3 :: v_dual_sub_nc_u32 v0, 0, v2
	v_max_i32_e32 v1, v3, v1
	s_delay_alu instid0(VALU_DEP_2)
	v_dual_mov_b32 v0, 0 :: v_dual_max_i32 v2, v2, v0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v2, s[0:1]
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[0:1] offset:4
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_int_abs_signed_width
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end5:
	.size	exact_int_abs_signed_width, .Lfunc_end5-exact_int_abs_signed_width
                                        ; -- End function
	.set exact_int_abs_signed_width.num_vgpr, 4
	.set exact_int_abs_signed_width.num_agpr, 0
	.set exact_int_abs_signed_width.numbered_sgpr, 2
	.set exact_int_abs_signed_width.num_named_barrier, 0
	.set exact_int_abs_signed_width.private_seg_size, 0
	.set exact_int_abs_signed_width.uses_vcc, 0
	.set exact_int_abs_signed_width.uses_flat_scratch, 0
	.set exact_int_abs_signed_width.has_dyn_sized_stack, 0
	.set exact_int_abs_signed_width.has_recursion, 0
	.set exact_int_abs_signed_width.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 84
; TotalNumSgprs: 2
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_load_s8_sign_extends ; -- Begin function exact_load_s8_sign_extends
	.globl	exact_load_s8_sign_extends
	.p2align	8
	.type	exact_load_s8_sign_extends,@function
exact_load_s8_sign_extends:             ; @exact_load_s8_sign_extends
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 0xff :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	flat_store_b8 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_i8 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_load_s8_sign_extends
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
.Lfunc_end6:
	.size	exact_load_s8_sign_extends, .Lfunc_end6-exact_load_s8_sign_extends
                                        ; -- End function
	.set exact_load_s8_sign_extends.num_vgpr, 2
	.set exact_load_s8_sign_extends.num_agpr, 0
	.set exact_load_s8_sign_extends.numbered_sgpr, 4
	.set exact_load_s8_sign_extends.num_named_barrier, 0
	.set exact_load_s8_sign_extends.private_seg_size, 0
	.set exact_load_s8_sign_extends.uses_vcc, 0
	.set exact_load_s8_sign_extends.uses_flat_scratch, 0
	.set exact_load_s8_sign_extends.has_dyn_sized_stack, 0
	.set exact_load_s8_sign_extends.has_recursion, 0
	.set exact_load_s8_sign_extends.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 72
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_load_s8_direct_minus_one ; -- Begin function exact_load_s8_direct_minus_one
	.globl	exact_load_s8_direct_minus_one
	.p2align	8
	.type	exact_load_s8_direct_minus_one,@function
exact_load_s8_direct_minus_one:         ; @exact_load_s8_direct_minus_one
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_dual_mov_b32 v1, -1 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_load_s8_direct_minus_one
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
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end7:
	.size	exact_load_s8_direct_minus_one, .Lfunc_end7-exact_load_s8_direct_minus_one
                                        ; -- End function
	.set exact_load_s8_direct_minus_one.num_vgpr, 2
	.set exact_load_s8_direct_minus_one.num_agpr, 0
	.set exact_load_s8_direct_minus_one.numbered_sgpr, 2
	.set exact_load_s8_direct_minus_one.num_named_barrier, 0
	.set exact_load_s8_direct_minus_one.private_seg_size, 0
	.set exact_load_s8_direct_minus_one.uses_vcc, 0
	.set exact_load_s8_direct_minus_one.uses_flat_scratch, 0
	.set exact_load_s8_direct_minus_one.has_dyn_sized_stack, 0
	.set exact_load_s8_direct_minus_one.has_recursion, 0
	.set exact_load_s8_direct_minus_one.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 36
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_mov_minus_one     ; -- Begin function exact_mov_minus_one
	.globl	exact_mov_minus_one
	.p2align	8
	.type	exact_mov_minus_one,@function
exact_mov_minus_one:                    ; @exact_mov_minus_one
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v1, -1 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_mov_minus_one
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
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end8:
	.size	exact_mov_minus_one, .Lfunc_end8-exact_mov_minus_one
                                        ; -- End function
	.set exact_mov_minus_one.num_vgpr, 2
	.set exact_mov_minus_one.num_agpr, 0
	.set exact_mov_minus_one.numbered_sgpr, 2
	.set exact_mov_minus_one.num_named_barrier, 0
	.set exact_mov_minus_one.private_seg_size, 0
	.set exact_mov_minus_one.uses_vcc, 0
	.set exact_mov_minus_one.uses_flat_scratch, 0
	.set exact_mov_minus_one.has_dyn_sized_stack, 0
	.set exact_mov_minus_one.has_recursion, 0
	.set exact_mov_minus_one.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 36
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_not_zero          ; -- Begin function exact_not_zero
	.globl	exact_not_zero
	.p2align	8
	.type	exact_not_zero,@function
exact_not_zero:                         ; @exact_not_zero
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_not_b32_e32 v0, v0
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v1, v0, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_not_zero
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
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end9:
	.size	exact_not_zero, .Lfunc_end9-exact_not_zero
                                        ; -- End function
	.set exact_not_zero.num_vgpr, 2
	.set exact_not_zero.num_agpr, 0
	.set exact_not_zero.numbered_sgpr, 2
	.set exact_not_zero.num_named_barrier, 0
	.set exact_not_zero.private_seg_size, 0
	.set exact_not_zero.uses_vcc, 0
	.set exact_not_zero.uses_flat_scratch, 0
	.set exact_not_zero.has_dyn_sized_stack, 0
	.set exact_not_zero.has_recursion, 0
	.set exact_not_zero.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 44
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_mul_high_u32      ; -- Begin function exact_mul_high_u32
	.globl	exact_mul_high_u32
	.p2align	8
	.type	exact_mul_high_u32,@function
exact_mul_high_u32:                     ; @exact_mul_high_u32
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_dual_mov_b32 v0, -1 :: v_dual_mov_b32 v1, 2
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_mul_hi_u32 v1, v1, v0
	v_mov_b32_e32 v0, 0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_mul_high_u32
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
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end10:
	.size	exact_mul_high_u32, .Lfunc_end10-exact_mul_high_u32
                                        ; -- End function
	.set exact_mul_high_u32.num_vgpr, 2
	.set exact_mul_high_u32.num_agpr, 0
	.set exact_mul_high_u32.numbered_sgpr, 2
	.set exact_mul_high_u32.num_named_barrier, 0
	.set exact_mul_high_u32.private_seg_size, 0
	.set exact_mul_high_u32.uses_vcc, 0
	.set exact_mul_high_u32.uses_flat_scratch, 0
	.set exact_mul_high_u32.has_dyn_sized_stack, 0
	.set exact_mul_high_u32.has_recursion, 0
	.set exact_mul_high_u32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 52
; TotalNumSgprs: 2
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_mul_wide_u16      ; -- Begin function exact_mul_wide_u16
	.globl	exact_mul_wide_u16
	.p2align	8
	.type	exact_mul_wide_u16,@function
exact_mul_wide_u16:                     ; @exact_mul_wide_u16
; %bb.0:
	v_dual_mov_b32 v2, 14 :: v_dual_mov_b32 v1, 0xba2f
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_and_b32_e32 v0, 0xffff, v2
	v_and_b32_e32 v1, 0xffff, v1
	s_load_b64 s[0:1], s[0:1], 0x8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_u32_u24_e32 v0, v1, v0
	v_dual_mov_b32 v1, 0 :: v_dual_lshrrev_b32 v3, 19, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_mad_u32_u24 v0, 0xfff5, v3, v2
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v3
	;;#ASMEND
	v_and_b32_e32 v0, 0xffff, v0
	s_wait_kmcnt 0x0
	global_store_b32 v1, v2, s[0:1]
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v1, v0, s[0:1] offset:4
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_mul_wide_u16
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end11:
	.size	exact_mul_wide_u16, .Lfunc_end11-exact_mul_wide_u16
                                        ; -- End function
	.set exact_mul_wide_u16.num_vgpr, 4
	.set exact_mul_wide_u16.num_agpr, 0
	.set exact_mul_wide_u16.numbered_sgpr, 2
	.set exact_mul_wide_u16.num_named_barrier, 0
	.set exact_mul_wide_u16.private_seg_size, 0
	.set exact_mul_wide_u16.uses_vcc, 0
	.set exact_mul_wide_u16.uses_flat_scratch, 0
	.set exact_mul_wide_u16.has_dyn_sized_stack, 0
	.set exact_mul_wide_u16.has_recursion, 0
	.set exact_mul_wide_u16.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 116
; TotalNumSgprs: 2
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
; NumVGPRsForWavesPerEU: 4
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
	.protected	exact_ring_add_s32_neg1 ; -- Begin function exact_ring_add_s32_neg1
	.globl	exact_ring_add_s32_neg1
	.p2align	8
	.type	exact_ring_add_s32_neg1,@function
exact_ring_add_s32_neg1:                ; @exact_ring_add_s32_neg1
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_add_co_i32 s0, s0, -1
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_add_s32_neg1
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
.Lfunc_end12:
	.size	exact_ring_add_s32_neg1, .Lfunc_end12-exact_ring_add_s32_neg1
                                        ; -- End function
	.set exact_ring_add_s32_neg1.num_vgpr, 2
	.set exact_ring_add_s32_neg1.num_agpr, 0
	.set exact_ring_add_s32_neg1.numbered_sgpr, 4
	.set exact_ring_add_s32_neg1.num_named_barrier, 0
	.set exact_ring_add_s32_neg1.private_seg_size, 0
	.set exact_ring_add_s32_neg1.uses_vcc, 0
	.set exact_ring_add_s32_neg1.uses_flat_scratch, 0
	.set exact_ring_add_s32_neg1.has_dyn_sized_stack, 0
	.set exact_ring_add_s32_neg1.has_recursion, 0
	.set exact_ring_add_s32_neg1.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_ring_add_u32_neg1 ; -- Begin function exact_ring_add_u32_neg1
	.globl	exact_ring_add_u32_neg1
	.p2align	8
	.type	exact_ring_add_u32_neg1,@function
exact_ring_add_u32_neg1:                ; @exact_ring_add_u32_neg1
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_add_co_i32 s0, s0, -1
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_add_u32_neg1
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
.Lfunc_end13:
	.size	exact_ring_add_u32_neg1, .Lfunc_end13-exact_ring_add_u32_neg1
                                        ; -- End function
	.set exact_ring_add_u32_neg1.num_vgpr, 2
	.set exact_ring_add_u32_neg1.num_agpr, 0
	.set exact_ring_add_u32_neg1.numbered_sgpr, 4
	.set exact_ring_add_u32_neg1.num_named_barrier, 0
	.set exact_ring_add_u32_neg1.private_seg_size, 0
	.set exact_ring_add_u32_neg1.uses_vcc, 0
	.set exact_ring_add_u32_neg1.uses_flat_scratch, 0
	.set exact_ring_add_u32_neg1.has_dyn_sized_stack, 0
	.set exact_ring_add_u32_neg1.has_recursion, 0
	.set exact_ring_add_u32_neg1.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_ring_sub_s32_neg7 ; -- Begin function exact_ring_sub_s32_neg7
	.globl	exact_ring_sub_s32_neg7
	.p2align	8
	.type	exact_ring_sub_s32_neg7,@function
exact_ring_sub_s32_neg7:                ; @exact_ring_sub_s32_neg7
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_add_co_i32 s0, s0, 7
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_sub_s32_neg7
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
.Lfunc_end14:
	.size	exact_ring_sub_s32_neg7, .Lfunc_end14-exact_ring_sub_s32_neg7
                                        ; -- End function
	.set exact_ring_sub_s32_neg7.num_vgpr, 2
	.set exact_ring_sub_s32_neg7.num_agpr, 0
	.set exact_ring_sub_s32_neg7.numbered_sgpr, 4
	.set exact_ring_sub_s32_neg7.num_named_barrier, 0
	.set exact_ring_sub_s32_neg7.private_seg_size, 0
	.set exact_ring_sub_s32_neg7.uses_vcc, 0
	.set exact_ring_sub_s32_neg7.uses_flat_scratch, 0
	.set exact_ring_sub_s32_neg7.has_dyn_sized_stack, 0
	.set exact_ring_sub_s32_neg7.has_recursion, 0
	.set exact_ring_sub_s32_neg7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_ring_sub_u32_neg7 ; -- Begin function exact_ring_sub_u32_neg7
	.globl	exact_ring_sub_u32_neg7
	.p2align	8
	.type	exact_ring_sub_u32_neg7,@function
exact_ring_sub_u32_neg7:                ; @exact_ring_sub_u32_neg7
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_add_co_i32 s0, s0, 7
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_sub_u32_neg7
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
.Lfunc_end15:
	.size	exact_ring_sub_u32_neg7, .Lfunc_end15-exact_ring_sub_u32_neg7
                                        ; -- End function
	.set exact_ring_sub_u32_neg7.num_vgpr, 2
	.set exact_ring_sub_u32_neg7.num_agpr, 0
	.set exact_ring_sub_u32_neg7.numbered_sgpr, 4
	.set exact_ring_sub_u32_neg7.num_named_barrier, 0
	.set exact_ring_sub_u32_neg7.private_seg_size, 0
	.set exact_ring_sub_u32_neg7.uses_vcc, 0
	.set exact_ring_sub_u32_neg7.uses_flat_scratch, 0
	.set exact_ring_sub_u32_neg7.has_dyn_sized_stack, 0
	.set exact_ring_sub_u32_neg7.has_recursion, 0
	.set exact_ring_sub_u32_neg7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_ring_sub_u32_1    ; -- Begin function exact_ring_sub_u32_1
	.globl	exact_ring_sub_u32_1
	.p2align	8
	.type	exact_ring_sub_u32_1,@function
exact_ring_sub_u32_1:                   ; @exact_ring_sub_u32_1
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_add_co_i32 s0, s0, -1
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_sub_u32_1
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
.Lfunc_end16:
	.size	exact_ring_sub_u32_1, .Lfunc_end16-exact_ring_sub_u32_1
                                        ; -- End function
	.set exact_ring_sub_u32_1.num_vgpr, 2
	.set exact_ring_sub_u32_1.num_agpr, 0
	.set exact_ring_sub_u32_1.numbered_sgpr, 4
	.set exact_ring_sub_u32_1.num_named_barrier, 0
	.set exact_ring_sub_u32_1.private_seg_size, 0
	.set exact_ring_sub_u32_1.uses_vcc, 0
	.set exact_ring_sub_u32_1.uses_flat_scratch, 0
	.set exact_ring_sub_u32_1.has_dyn_sized_stack, 0
	.set exact_ring_sub_u32_1.has_recursion, 0
	.set exact_ring_sub_u32_1.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_ring_mul_s32_neg3 ; -- Begin function exact_ring_mul_s32_neg3
	.globl	exact_ring_mul_s32_neg3
	.p2align	8
	.type	exact_ring_mul_s32_neg3,@function
exact_ring_mul_s32_neg3:                ; @exact_ring_mul_s32_neg3
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_mul_i32 s0, s0, -3
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_mul_s32_neg3
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
.Lfunc_end17:
	.size	exact_ring_mul_s32_neg3, .Lfunc_end17-exact_ring_mul_s32_neg3
                                        ; -- End function
	.set exact_ring_mul_s32_neg3.num_vgpr, 2
	.set exact_ring_mul_s32_neg3.num_agpr, 0
	.set exact_ring_mul_s32_neg3.numbered_sgpr, 4
	.set exact_ring_mul_s32_neg3.num_named_barrier, 0
	.set exact_ring_mul_s32_neg3.private_seg_size, 0
	.set exact_ring_mul_s32_neg3.uses_vcc, 0
	.set exact_ring_mul_s32_neg3.uses_flat_scratch, 0
	.set exact_ring_mul_s32_neg3.has_dyn_sized_stack, 0
	.set exact_ring_mul_s32_neg3.has_recursion, 0
	.set exact_ring_mul_s32_neg3.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_ring_mul_u32_neg3 ; -- Begin function exact_ring_mul_u32_neg3
	.globl	exact_ring_mul_u32_neg3
	.p2align	8
	.type	exact_ring_mul_u32_neg3,@function
exact_ring_mul_u32_neg3:                ; @exact_ring_mul_u32_neg3
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_mul_i32 s0, s0, -3
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_ring_mul_u32_neg3
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
.Lfunc_end18:
	.size	exact_ring_mul_u32_neg3, .Lfunc_end18-exact_ring_mul_u32_neg3
                                        ; -- End function
	.set exact_ring_mul_u32_neg3.num_vgpr, 2
	.set exact_ring_mul_u32_neg3.num_agpr, 0
	.set exact_ring_mul_u32_neg3.numbered_sgpr, 4
	.set exact_ring_mul_u32_neg3.num_named_barrier, 0
	.set exact_ring_mul_u32_neg3.private_seg_size, 0
	.set exact_ring_mul_u32_neg3.uses_vcc, 0
	.set exact_ring_mul_u32_neg3.uses_flat_scratch, 0
	.set exact_ring_mul_u32_neg3.has_dyn_sized_stack, 0
	.set exact_ring_mul_u32_neg3.has_recursion, 0
	.set exact_ring_mul_u32_neg3.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 56
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_select_minus_one  ; -- Begin function exact_select_minus_one
	.globl	exact_select_minus_one
	.p2align	8
	.type	exact_select_minus_one,@function
exact_select_minus_one:                 ; @exact_select_minus_one
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	s_cmp_eq_u32 s0, -1
	s_cselect_b32 s0, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_cndmask_b32_e64 v1, 0, -1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_select_minus_one
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
.Lfunc_end19:
	.size	exact_select_minus_one, .Lfunc_end19-exact_select_minus_one
                                        ; -- End function
	.set exact_select_minus_one.num_vgpr, 2
	.set exact_select_minus_one.num_agpr, 0
	.set exact_select_minus_one.numbered_sgpr, 4
	.set exact_select_minus_one.num_named_barrier, 0
	.set exact_select_minus_one.private_seg_size, 0
	.set exact_select_minus_one.uses_vcc, 0
	.set exact_select_minus_one.uses_flat_scratch, 0
	.set exact_select_minus_one.has_dyn_sized_stack, 0
	.set exact_select_minus_one.has_recursion, 0
	.set exact_select_minus_one.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 64
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_select_complement ; -- Begin function exact_select_complement
	.globl	exact_select_complement
	.p2align	8
	.type	exact_select_complement,@function
exact_select_complement:                ; @exact_select_complement
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 0
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_not_b32_e32 v1, v1
	s_wait_kmcnt 0x0
	global_load_b32 v0, v2, s[0:1]
	s_wait_loadcnt 0x0
	v_cmp_eq_u32_e32 vcc_lo, v0, v1
	v_cndmask_b32_e32 v0, 0, v1, vcc_lo
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v2, v0, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_select_complement
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
.Lfunc_end20:
	.size	exact_select_complement, .Lfunc_end20-exact_select_complement
                                        ; -- End function
	.set exact_select_complement.num_vgpr, 3
	.set exact_select_complement.num_agpr, 0
	.set exact_select_complement.numbered_sgpr, 4
	.set exact_select_complement.num_named_barrier, 0
	.set exact_select_complement.private_seg_size, 0
	.set exact_select_complement.uses_vcc, 1
	.set exact_select_complement.uses_flat_scratch, 0
	.set exact_select_complement.has_dyn_sized_stack, 0
	.set exact_select_complement.has_recursion, 0
	.set exact_select_complement.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 68
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	exact_funnel_clamp_wrap ; -- Begin function exact_funnel_clamp_wrap
	.globl	exact_funnel_clamp_wrap
	.p2align	8
	.type	exact_funnel_clamp_wrap,@function
exact_funnel_clamp_wrap:                ; @exact_funnel_clamp_wrap
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x8
	v_mov_b32_e32 v0, 0x11111111
	v_dual_mov_b32 v1, 0x22222222 :: v_dual_mov_b32 v8, -1
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_min_u32_e32 v4, 32, v8
	v_and_b32_e32 v6, 31, v8
	v_lshlrev_b64_e32 v[2:3], v4, v[0:1]
	v_mov_b32_e32 v2, 0
	v_lshrrev_b64 v[4:5], v4, v[0:1]
	s_delay_alu instid0(VALU_DEP_4)
	v_lshlrev_b64_e32 v[6:7], v6, v[0:1]
	v_alignbit_b32 v0, v1, v0, v8
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v3
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v2, v1, s[0:1]
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v4
	;;#ASMEND
	global_store_b32 v2, v1, s[0:1] offset:4
	s_wait_xcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v7
	;;#ASMEND
	global_store_b32 v2, v1, s[0:1] offset:8
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	global_store_b32 v2, v0, s[0:1] offset:12
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_funnel_clamp_wrap
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
		.amdhsa_next_free_vgpr 9
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end21:
	.size	exact_funnel_clamp_wrap, .Lfunc_end21-exact_funnel_clamp_wrap
                                        ; -- End function
	.set exact_funnel_clamp_wrap.num_vgpr, 9
	.set exact_funnel_clamp_wrap.num_agpr, 0
	.set exact_funnel_clamp_wrap.numbered_sgpr, 2
	.set exact_funnel_clamp_wrap.num_named_barrier, 0
	.set exact_funnel_clamp_wrap.private_seg_size, 0
	.set exact_funnel_clamp_wrap.uses_vcc, 0
	.set exact_funnel_clamp_wrap.uses_flat_scratch, 0
	.set exact_funnel_clamp_wrap.has_dyn_sized_stack, 0
	.set exact_funnel_clamp_wrap.has_recursion, 0
	.set exact_funnel_clamp_wrap.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 136
; TotalNumSgprs: 2
; NumVgprs: 9
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 2
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
	.protected	exact_store_u8_truncates ; -- Begin function exact_store_u8_truncates
	.globl	exact_store_u8_truncates
	.p2align	8
	.type	exact_store_u8_truncates,@function
exact_store_u8_truncates:               ; @exact_store_u8_truncates
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v1, 44 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	s_wait_kmcnt 0x0
	flat_store_b8 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_u8 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_store_u8_truncates
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
.Lfunc_end22:
	.size	exact_store_u8_truncates, .Lfunc_end22-exact_store_u8_truncates
                                        ; -- End function
	.set exact_store_u8_truncates.num_vgpr, 2
	.set exact_store_u8_truncates.num_agpr, 0
	.set exact_store_u8_truncates.numbered_sgpr, 4
	.set exact_store_u8_truncates.num_named_barrier, 0
	.set exact_store_u8_truncates.private_seg_size, 0
	.set exact_store_u8_truncates.uses_vcc, 0
	.set exact_store_u8_truncates.uses_flat_scratch, 0
	.set exact_store_u8_truncates.has_dyn_sized_stack, 0
	.set exact_store_u8_truncates.has_recursion, 0
	.set exact_store_u8_truncates.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 68
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_unsigned_byte_identity ; -- Begin function exact_unsigned_byte_identity
	.globl	exact_unsigned_byte_identity
	.p2align	8
	.type	exact_unsigned_byte_identity,@function
exact_unsigned_byte_identity:           ; @exact_unsigned_byte_identity
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	s_load_u8 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_mov_b32_e32 v1, s0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_unsigned_byte_identity
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
.Lfunc_end23:
	.size	exact_unsigned_byte_identity, .Lfunc_end23-exact_unsigned_byte_identity
                                        ; -- End function
	.set exact_unsigned_byte_identity.num_vgpr, 2
	.set exact_unsigned_byte_identity.num_agpr, 0
	.set exact_unsigned_byte_identity.numbered_sgpr, 4
	.set exact_unsigned_byte_identity.num_named_barrier, 0
	.set exact_unsigned_byte_identity.private_seg_size, 0
	.set exact_unsigned_byte_identity.uses_vcc, 0
	.set exact_unsigned_byte_identity.uses_flat_scratch, 0
	.set exact_unsigned_byte_identity.has_dyn_sized_stack, 0
	.set exact_unsigned_byte_identity.has_recursion, 0
	.set exact_unsigned_byte_identity.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 48
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	exact_vector_immediates ; -- Begin function exact_vector_immediates
	.globl	exact_vector_immediates
	.p2align	8
	.type	exact_vector_immediates,@function
exact_vector_immediates:                ; @exact_vector_immediates
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_dual_mov_b32 v4, 0 :: v_dual_mov_b32 v3, 1.0
	s_wait_kmcnt 0x0
	s_load_b32 s4, s[0:1], 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v4
	;;#ASMEND
	global_load_b32 v2, v4, s[0:1] offset:4
	;;#ASMSTART
	v_add_f32 v3, 0, v3
	;;#ASMEND
	s_wait_kmcnt 0x0
	v_mov_b32_e32 v0, s4
	s_wait_loadcnt 0x0
	global_store_b128 v4, v[0:3], s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel exact_vector_immediates
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
		.amdhsa_next_free_sgpr 5
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
.Lfunc_end24:
	.size	exact_vector_immediates, .Lfunc_end24-exact_vector_immediates
                                        ; -- End function
	.set exact_vector_immediates.num_vgpr, 5
	.set exact_vector_immediates.num_agpr, 0
	.set exact_vector_immediates.numbered_sgpr, 5
	.set exact_vector_immediates.num_named_barrier, 0
	.set exact_vector_immediates.private_seg_size, 0
	.set exact_vector_immediates.uses_vcc, 0
	.set exact_vector_immediates.uses_flat_scratch, 0
	.set exact_vector_immediates.has_dyn_sized_stack, 0
	.set exact_vector_immediates.has_recursion, 0
	.set exact_vector_immediates.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 68
; TotalNumSgprs: 5
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 5
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_98dfb9845f52ae49,@object ; @__hip_cuid_98dfb9845f52ae49
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_98dfb9845f52ae49
__hip_cuid_98dfb9845f52ae49:
	.byte	0                               ; 0x0
	.size	__hip_cuid_98dfb9845f52ae49, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_98dfb9845f52ae49
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_b16_shift_count_u32
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_b16_shift_count_u32.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .name:           exact_b64_shift_u32
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_b64_shift_u32.kd
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           exact_bfe_clipping
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_bfe_clipping.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
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
    .max_flat_workgroup_size: 1
    .name:           exact_bfi_clipping
    .private_segment_fixed_size: 0
    .sgpr_count:     7
    .sgpr_spill_count: 0
    .symbol:         exact_bfi_clipping.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
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
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         20
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         24
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         28
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         30
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         32
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         34
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         36
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         38
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         80
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           exact_declined_cancel_one_pass
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         exact_declined_cancel_one_pass.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_int_abs_signed_width
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_int_abs_signed_width.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .name:           exact_load_s8_sign_extends
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_load_s8_sign_extends.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_load_s8_direct_minus_one
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_load_s8_direct_minus_one.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_mov_minus_one
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_mov_minus_one.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_not_zero
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_not_zero.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_mul_high_u32
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_mul_high_u32.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_mul_wide_u16
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_mul_wide_u16.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .name:           exact_ring_add_s32_neg1
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_add_s32_neg1.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_ring_add_u32_neg1
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_add_u32_neg1.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_ring_sub_s32_neg7
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_sub_s32_neg7.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_ring_sub_u32_neg7
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_sub_u32_neg7.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_ring_sub_u32_1
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_sub_u32_1.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_ring_mul_s32_neg3
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_mul_s32_neg3.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_ring_mul_u32_neg3
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_ring_mul_u32_neg3.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_select_minus_one
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_select_minus_one.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_select_complement
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         exact_select_complement.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_funnel_clamp_wrap
    .private_segment_fixed_size: 0
    .sgpr_count:     2
    .sgpr_spill_count: 0
    .symbol:         exact_funnel_clamp_wrap.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     9
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
    .name:           exact_store_u8_truncates
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_store_u8_truncates.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_unsigned_byte_identity
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         exact_unsigned_byte_identity.kd
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
    .max_flat_workgroup_size: 1
    .name:           exact_vector_immediates
    .private_segment_fixed_size: 0
    .sgpr_count:     5
    .sgpr_spill_count: 0
    .symbol:         exact_vector_immediates.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     5
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
