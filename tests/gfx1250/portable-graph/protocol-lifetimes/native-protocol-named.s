	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_initialization_42         ; -- Begin function named_initialization_42
	.p2align	8
	.type	named_initialization_42,@function
named_initialization_42:                ; @named_initialization_42
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_3
; %bb.1:                                ; %init
	s_load_b32 s0, s[4:5], 0x8
	s_wait_kmcnt 0x0
	s_cmp_lg_u32 s0, 0
	s_cbranch_scc1 .LBB0_3
; %bb.2:                                ; %initialize
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB0_3:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s1
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execnz .LBB0_6
; %bb.4:                                ; %Flow2
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execnz .LBB0_9
.LBB0_5:                                ; %end
	s_endpgm
.LBB0_6:                                ; %consume
	s_mov_b32 s1, exec_lo
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB0_8
; %bb.7:                                ; %read
	v_mov_b32_e32 v0, 0
	s_load_b64 s[2:3], s[4:5], 0x0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB0_8:                                ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
                                        ; implicit-def: $vgpr0
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB0_5
.LBB0_9:                                ; %produce
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_11
; %bb.10:                               ; %write
	v_dual_mov_b32 v1, 0x42280000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	ds_store_b32 v0, v1
.LBB0_11:                               ; %signal
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_initialization_42
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
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
		.amdhsa_next_free_vgpr 113
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 1
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
	.size	named_initialization_42, .Lfunc_end0-named_initialization_42
                                        ; -- End function
	.set named_initialization_42.num_vgpr, 2
	.set named_initialization_42.num_agpr, 0
	.set named_initialization_42.numbered_sgpr, 6
	.set named_initialization_42.num_named_barrier, 1
	.set named_initialization_42.private_seg_size, 0
	.set named_initialization_42.uses_vcc, 1
	.set named_initialization_42.uses_flat_scratch, 0
	.set named_initialization_42.has_dyn_sized_stack, 0
	.set named_initialization_42.has_recursion, 0
	.set named_initialization_42.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 8
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 113
; NamedBarCnt: 1
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_live_reinitialization_42  ; -- Begin function named_live_reinitialization_42
	.p2align	8
	.type	named_live_reinitialization_42,@function
named_live_reinitialization_42:         ; @named_live_reinitialization_42
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e64 s0, 32, v0
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB1_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB1_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b32 s1, s[4:5], 0x8
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_cmp_lg_u32 s1, 0
	s_cselect_b32 s1, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b32 s1, s0, s1
	s_and_saveexec_b32 s0, s1
	s_cbranch_execz .LBB1_4
; %bb.3:                                ; %resetlive
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB1_4:                                ; %dispatch
	s_or_b32 exec_lo, exec_lo, s0
	s_and_saveexec_b32 s0, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execnz .LBB1_7
; %bb.5:                                ; %Flow2
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execnz .LBB1_10
.LBB1_6:                                ; %end
	s_endpgm
.LBB1_7:                                ; %consume
	s_mov_b32 s1, exec_lo
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB1_9
; %bb.8:                                ; %read
	v_mov_b32_e32 v0, 0
	s_load_b64 s[2:3], s[4:5], 0x0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB1_9:                                ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
                                        ; implicit-def: $vgpr0
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB1_6
.LBB1_10:                               ; %produce
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_12
; %bb.11:                               ; %write
	v_dual_mov_b32 v1, 0x42280000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	ds_store_b32 v0, v1
.LBB1_12:                               ; %signal
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 1
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_live_reinitialization_42
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
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
		.amdhsa_next_free_vgpr 113
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 1
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
.Lfunc_end1:
	.size	named_live_reinitialization_42, .Lfunc_end1-named_live_reinitialization_42
                                        ; -- End function
	.set named_live_reinitialization_42.num_vgpr, 2
	.set named_live_reinitialization_42.num_agpr, 0
	.set named_live_reinitialization_42.numbered_sgpr, 6
	.set named_live_reinitialization_42.num_named_barrier, 1
	.set named_live_reinitialization_42.private_seg_size, 0
	.set named_live_reinitialization_42.uses_vcc, 1
	.set named_live_reinitialization_42.uses_flat_scratch, 0
	.set named_live_reinitialization_42.has_dyn_sized_stack, 0
	.set named_live_reinitialization_42.has_recursion, 0
	.set named_live_reinitialization_42.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 272
; TotalNumSgprs: 8
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 113
; NamedBarCnt: 1
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_new_lifetime_count_change ; -- Begin function named_new_lifetime_count_change
	.p2align	8
	.type	named_new_lifetime_count_change,@function
named_new_lifetime_count_change:        ; @named_new_lifetime_count_change
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e64 s0, 32, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB2_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB2_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s1
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB2_4
; %bb.3:                                ; %write
	v_dual_mov_b32 v2, 0x40e00000 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	v_add_f32 v2, 0, v2
	;;#ASMEND
	ds_store_b32 v1, v2
.LBB2_4:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b64 s[2:3], s[4:5], 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB2_6
; %bb.5:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB2_6:                                ; %leave
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_barrier_leave
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB2_9
; %bb.7:                                ; %newinit
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB2_9
; %bb.8:                                ; %marker
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB2_9:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_new_lifetime_count_change
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
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
		.amdhsa_next_free_vgpr 113
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 1
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
.Lfunc_end2:
	.size	named_new_lifetime_count_change, .Lfunc_end2-named_new_lifetime_count_change
                                        ; -- End function
	.set named_new_lifetime_count_change.num_vgpr, 3
	.set named_new_lifetime_count_change.num_agpr, 0
	.set named_new_lifetime_count_change.numbered_sgpr, 6
	.set named_new_lifetime_count_change.num_named_barrier, 1
	.set named_new_lifetime_count_change.private_seg_size, 0
	.set named_new_lifetime_count_change.uses_vcc, 1
	.set named_new_lifetime_count_change.uses_flat_scratch, 0
	.set named_new_lifetime_count_change.has_dyn_sized_stack, 0
	.set named_new_lifetime_count_change.has_recursion, 0
	.set named_new_lifetime_count_change.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 256
; TotalNumSgprs: 8
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 113
; NamedBarCnt: 1
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_count_mismatch_7          ; -- Begin function named_count_mismatch_7
	.p2align	8
	.type	named_count_mismatch_7,@function
named_count_mismatch_7:                 ; @named_count_mismatch_7
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e64 s0, 32, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB3_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x30001
	s_barrier_init m0 
.LBB3_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s1
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB3_4
; %bb.3:                                ; %write
	v_dual_mov_b32 v2, 0x40e00000 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	v_add_f32 v2, 0, v2
	;;#ASMEND
	ds_store_b32 v1, v2
.LBB3_4:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b64 s[2:3], s[4:5], 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB3_6
; %bb.5:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB3_6:                                ; %leave
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_barrier_leave
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB3_9
; %bb.7:                                ; %newinit
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_9
; %bb.8:                                ; %marker
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB3_9:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_count_mismatch_7
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
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
		.amdhsa_next_free_vgpr 113
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 1
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
.Lfunc_end3:
	.size	named_count_mismatch_7, .Lfunc_end3-named_count_mismatch_7
                                        ; -- End function
	.set named_count_mismatch_7.num_vgpr, 3
	.set named_count_mismatch_7.num_agpr, 0
	.set named_count_mismatch_7.numbered_sgpr, 6
	.set named_count_mismatch_7.num_named_barrier, 1
	.set named_count_mismatch_7.private_seg_size, 0
	.set named_count_mismatch_7.uses_vcc, 1
	.set named_count_mismatch_7.uses_flat_scratch, 0
	.set named_count_mismatch_7.has_dyn_sized_stack, 0
	.set named_count_mismatch_7.has_recursion, 0
	.set named_count_mismatch_7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 256
; TotalNumSgprs: 8
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 113
; NamedBarCnt: 1
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_wait_without_first_arrival ; -- Begin function named_wait_without_first_arrival
	.p2align	8
	.type	named_wait_without_first_arrival,@function
named_wait_without_first_arrival:       ; @named_wait_without_first_arrival
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB4_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB4_2:                                ; %join
	s_or_b32 exec_lo, exec_lo, s0
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_wait 1
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_wait_without_first_arrival
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
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
		.amdhsa_next_free_vgpr 113
		.amdhsa_next_free_sgpr 1
		.amdhsa_named_barrier_count 1
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
	.size	named_wait_without_first_arrival, .Lfunc_end4-named_wait_without_first_arrival
                                        ; -- End function
	.set named_wait_without_first_arrival.num_vgpr, 1
	.set named_wait_without_first_arrival.num_agpr, 0
	.set named_wait_without_first_arrival.numbered_sgpr, 1
	.set named_wait_without_first_arrival.num_named_barrier, 1
	.set named_wait_without_first_arrival.private_seg_size, 0
	.set named_wait_without_first_arrival.uses_vcc, 0
	.set named_wait_without_first_arrival.uses_flat_scratch, 0
	.set named_wait_without_first_arrival.has_dyn_sized_stack, 0
	.set named_wait_without_first_arrival.has_recursion, 0
	.set named_wait_without_first_arrival.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 72
; TotalNumSgprs: 1
; NumVgprs: 1
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 1
; NumVGPRsForWavesPerEU: 113
; NamedBarCnt: 1
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
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
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .name:           out
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .name:           initialize_late
        .offset:         8
        .size:           4
        .value_kind:     by_value
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
      - .offset:         96
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         104
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         112
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         120
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         128
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         216
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_initialization_42
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_initialization_42.kd
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .name:           out
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .name:           reinitialize_live
        .offset:         8
        .size:           4
        .value_kind:     by_value
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
      - .offset:         96
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         104
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         112
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         120
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         128
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         216
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_live_reinitialization_42
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_live_reinitialization_42.kd
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .name:           out
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .name:           unused
        .offset:         8
        .size:           4
        .value_kind:     by_value
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
      - .offset:         96
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         104
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         112
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         120
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         128
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         216
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_new_lifetime_count_change
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_new_lifetime_count_change.kd
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .name:           out
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .name:           unused
        .offset:         8
        .size:           4
        .value_kind:     by_value
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
      - .offset:         96
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         104
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         112
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         120
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         128
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         216
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_count_mismatch_7
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_count_mismatch_7.kd
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .name:           out
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .name:           unused
        .offset:         8
        .size:           4
        .value_kind:     by_value
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
      - .offset:         96
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         104
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         112
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         120
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         128
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         216
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_wait_without_first_arrival
    .private_segment_fixed_size: 0
    .sgpr_count:     1
    .sgpr_spill_count: 0
    .symbol:         named_wait_without_first_arrival.kd
    .uses_dynamic_stack: false
    .vgpr_count:     1
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
