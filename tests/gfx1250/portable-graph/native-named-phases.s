	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_two_object_handshake      ; -- Begin function named_two_object_handshake
	.p2align	8
	.type	named_two_object_handshake,@function
named_two_object_handshake:             ; @named_two_object_handshake
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20002
	s_barrier_init m0 
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB0_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b128 s[0:3], s[4:5], 0x0
	s_mov_b32 m0, 2
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execnz .LBB0_5
; %bb.3:                                ; %Flow4
	s_wait_kmcnt 0x0
	s_and_not1_saveexec_b32 s2, s4
	s_cbranch_execnz .LBB0_10
.LBB0_4:                                ; %end
	s_endpgm
.LBB0_5:                                ; %consumer0
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_saveexec_b32 s5, vcc_lo
	s_cbranch_execz .LBB0_7
; %bb.6:                                ; %read0
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB0_7:                                ; %consume0signal
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s5
	s_mov_b32 m0, 1
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_join m0 
	s_barrier_signal m0 
	s_mov_b32 m0, 2
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_saveexec_b32 s5, vcc_lo
	s_cbranch_execz .LBB0_9
; %bb.8:                                ; %read1
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB0_9:                                ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s5
                                        ; implicit-def: $vgpr0
	s_wait_kmcnt 0x0
	s_and_not1_saveexec_b32 s2, s4
	s_cbranch_execz .LBB0_4
.LBB0_10:                               ; %producer0
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_12
; %bb.11:                               ; %write0
	v_mov_b32_e32 v0, 0
	global_load_b32 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB0_12:                               ; %produce0signal
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 2
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_14
; %bb.13:                               ; %write1
	v_mov_b32_e32 v0, 0
	global_load_b32 v1, v0, s[0:1] offset:4
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB0_14:                               ; %produce1signal
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 2
	s_barrier_join m0 
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_two_object_handshake
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
.Lfunc_end0:
	.size	named_two_object_handshake, .Lfunc_end0-named_two_object_handshake
                                        ; -- End function
	.set named_two_object_handshake.num_vgpr, 2
	.set named_two_object_handshake.num_agpr, 0
	.set named_two_object_handshake.numbered_sgpr, 6
	.set named_two_object_handshake.num_named_barrier, 2
	.set named_two_object_handshake.private_seg_size, 0
	.set named_two_object_handshake.uses_vcc, 1
	.set named_two_object_handshake.uses_flat_scratch, 0
	.set named_two_object_handshake.has_dyn_sized_stack, 0
	.set named_two_object_handshake.has_recursion, 0
	.set named_two_object_handshake.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 392
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
	.globl	named_independent_object_counts ; -- Begin function named_independent_object_counts
	.p2align	8
	.type	named_independent_object_counts,@function
named_independent_object_counts:        ; @named_independent_object_counts
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10002
	s_barrier_init m0 
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB1_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_4
; %bb.3:                                ; %solo0
	s_mov_b32 m0, 2
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
.LBB1_4:                                ; %together
	s_or_b32 exec_lo, exec_lo, s0
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 2
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_6
; %bb.5:                                ; %solo1
	s_mov_b32 m0, 2
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
.LBB1_6:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_independent_object_counts
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 256
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
.Lfunc_end1:
	.size	named_independent_object_counts, .Lfunc_end1-named_independent_object_counts
                                        ; -- End function
	.set named_independent_object_counts.num_vgpr, 1
	.set named_independent_object_counts.num_agpr, 0
	.set named_independent_object_counts.numbered_sgpr, 1
	.set named_independent_object_counts.num_named_barrier, 2
	.set named_independent_object_counts.private_seg_size, 0
	.set named_independent_object_counts.uses_vcc, 1
	.set named_independent_object_counts.uses_flat_scratch, 0
	.set named_independent_object_counts.has_dyn_sized_stack, 0
	.set named_independent_object_counts.has_recursion, 0
	.set named_independent_object_counts.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 132
; TotalNumSgprs: 3
; NumVgprs: 1
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 3
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
	.globl	named_three_arrivals_expression ; -- Begin function named_three_arrivals_expression
	.p2align	8
	.type	named_three_arrivals_expression,@function
named_three_arrivals_expression:        ; @named_three_arrivals_expression
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 m0, 0x10001
	s_mov_b32 s0, exec_lo
	s_barrier_init m0 
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB2_2
; %bb.1:                                ; %body
	s_load_b128 s[0:3], s[4:5], 0x0
	s_mov_b32 m0, 1
	s_wait_kmcnt 0x0
	s_load_b64 s[4:5], s[0:1], 0x0
	s_barrier_signal m0 
	s_wait_xcnt 0x0
	s_load_b32 s0, s[0:1], 0x8
	s_barrier_signal m0 
	s_barrier_signal m0 
	s_wait_kmcnt 0x0
	s_add_f32 s1, s4, s5
	s_delay_alu instid0(SALU_CYCLE_3) | instskip(NEXT) | instid1(SALU_CYCLE_3)
	s_mul_f32 s0, s1, s0
	s_sub_f32 s0, s0, s4
	s_delay_alu instid0(SALU_CYCLE_3)
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	global_store_b32 v0, v1, s[2:3]
.LBB2_2:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_three_arrivals_expression
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
		.amdhsa_next_free_vgpr 2
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 1
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
	.size	named_three_arrivals_expression, .Lfunc_end2-named_three_arrivals_expression
                                        ; -- End function
	.set named_three_arrivals_expression.num_vgpr, 2
	.set named_three_arrivals_expression.num_agpr, 0
	.set named_three_arrivals_expression.numbered_sgpr, 6
	.set named_three_arrivals_expression.num_named_barrier, 1
	.set named_three_arrivals_expression.private_seg_size, 0
	.set named_three_arrivals_expression.uses_vcc, 0
	.set named_three_arrivals_expression.uses_flat_scratch, 0
	.set named_three_arrivals_expression.has_dyn_sized_stack, 0
	.set named_three_arrivals_expression.has_recursion, 0
	.set named_three_arrivals_expression.has_indirect_call, 0
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
; NamedBarCnt: 1
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_selected_object_copy      ; -- Begin function named_selected_object_copy
	.p2align	8
	.type	named_selected_object_copy,@function
named_selected_object_copy:             ; @named_selected_object_copy
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20002
	s_barrier_init m0 
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB3_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b128 s[8:11], s[4:5], 0x0
	s_mov_b32 s1, exec_lo
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB3_4
; %bb.3:                                ; %write
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[8:9], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, s0
	ds_store_b32 v1, v2
.LBB3_4:                                ; %join
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b32 s0, s[4:5], 0x10
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_cmp_eq_u32 s0, 0
	s_cselect_b32 s0, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s0, s0, vcc_lo
	s_and_saveexec_b32 s1, s0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s0, exec_lo, s1
	s_cbranch_execz .LBB3_6
; %bb.5:                                ; %joinfull
	s_mov_b32 m0, 2
	s_barrier_join m0 
	s_barrier_signal m0 
.LBB3_6:                                ; %Flow
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB3_8
; %bb.7:                                ; %joinother
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
.LBB3_8:                                ; %wait
	s_or_b32 exec_lo, exec_lo, s0
	s_barrier_wait 1
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB3_10
; %bb.9:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	global_store_b32 v0, v1, s[10:11]
.LBB3_10:                               ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_selected_object_copy
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 280
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
		.amdhsa_next_free_sgpr 12
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
	.size	named_selected_object_copy, .Lfunc_end3-named_selected_object_copy
                                        ; -- End function
	.set named_selected_object_copy.num_vgpr, 3
	.set named_selected_object_copy.num_agpr, 0
	.set named_selected_object_copy.numbered_sgpr, 12
	.set named_selected_object_copy.num_named_barrier, 2
	.set named_selected_object_copy.private_seg_size, 0
	.set named_selected_object_copy.uses_vcc, 1
	.set named_selected_object_copy.uses_flat_scratch, 0
	.set named_selected_object_copy.has_dyn_sized_stack, 0
	.set named_selected_object_copy.has_recursion, 0
	.set named_selected_object_copy.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 244
; TotalNumSgprs: 14
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 14
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
        .name:           in
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out
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
    .name:           named_two_object_handshake
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_two_object_handshake.kd
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         4
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         8
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         12
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         14
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         16
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         18
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         20
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         22
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         40
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         48
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         64
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         80
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         88
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         96
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         104
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         112
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         200
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 256
    .max_flat_workgroup_size: 64
    .name:           named_independent_object_counts
    .private_segment_fixed_size: 0
    .sgpr_count:     3
    .sgpr_spill_count: 0
    .symbol:         named_independent_object_counts.kd
    .uses_dynamic_stack: false
    .vgpr_count:     1
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .name:           in
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out
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
    .max_flat_workgroup_size: 32
    .name:           named_three_arrivals_expression
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_three_arrivals_expression.kd
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .name:           in
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .name:           out
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .name:           different
        .offset:         16
        .size:           4
        .value_kind:     by_value
      - .offset:         24
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         28
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         32
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         36
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         38
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         40
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         42
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         44
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         46
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         80
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         88
        .size:           2
        .value_kind:     hidden_grid_dims
      - .offset:         104
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         112
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         120
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         128
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         136
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         224
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 280
    .max_flat_workgroup_size: 64
    .name:           named_selected_object_copy
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         named_selected_object_copy.kd
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
