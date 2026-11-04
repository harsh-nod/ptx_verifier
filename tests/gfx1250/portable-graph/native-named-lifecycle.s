	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_wait_only_consumer_42     ; -- Begin function named_wait_only_consumer_42
	.p2align	8
	.type	named_wait_only_consumer_42,@function
named_wait_only_consumer_42:            ; @named_wait_only_consumer_42
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB0_2:                                ; %rendezvous
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
	s_cbranch_execnz .LBB0_5
; %bb.3:                                ; %Flow2
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execnz .LBB0_8
.LBB0_4:                                ; %end
	s_endpgm
.LBB0_5:                                ; %consume
	s_mov_b32 s1, exec_lo
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB0_7
; %bb.6:                                ; %read
	v_mov_b32_e32 v0, 0
	s_load_b64 s[2:3], s[4:5], 0x0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB0_7:                                ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
                                        ; implicit-def: $vgpr0
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB0_4
.LBB0_8:                                ; %produce
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_10
; %bb.9:                                ; %write
	v_dual_mov_b32 v1, 0x42280000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	ds_store_b32 v0, v1
.LBB0_10:                               ; %signal
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_wait_only_consumer_42
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 264
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
	.size	named_wait_only_consumer_42, .Lfunc_end0-named_wait_only_consumer_42
                                        ; -- End function
	.set named_wait_only_consumer_42.num_vgpr, 2
	.set named_wait_only_consumer_42.num_agpr, 0
	.set named_wait_only_consumer_42.numbered_sgpr, 6
	.set named_wait_only_consumer_42.num_named_barrier, 1
	.set named_wait_only_consumer_42.private_seg_size, 0
	.set named_wait_only_consumer_42.uses_vcc, 1
	.set named_wait_only_consumer_42.uses_flat_scratch, 0
	.set named_wait_only_consumer_42.has_dyn_sized_stack, 0
	.set named_wait_only_consumer_42.has_recursion, 0
	.set named_wait_only_consumer_42.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 212
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
	.globl	named_two_marker_ones           ; -- Begin function named_two_marker_ones
	.p2align	8
	.type	named_two_marker_ones,@function
named_two_marker_ones:                  ; @named_two_marker_ones
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB1_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB1_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b32 s0, s[4:5], 0x8
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_wait_kmcnt 0x0
	s_cmp_eq_u32 s0, 0
	s_cselect_b32 s0, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s1, s0, vcc_lo
	s_and_saveexec_b32 s0, s1
	s_cbranch_execz .LBB1_4
; %bb.3:                                ; %signal
	s_barrier_signal m0 
.LBB1_4:                                ; %wait
	s_or_b32 exec_lo, exec_lo, s0
	v_and_b32_e32 v1, 31, v0
	s_barrier_wait 1
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 0, v1
	s_cbranch_execz .LBB1_6
; %bb.5:                                ; %write
	s_load_b64 s[0:1], s[4:5], 0x0
	v_dual_mov_b32 v1, 1.0 :: v_dual_lshrrev_b32 v0, 3, v0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1)
	v_and_b32_e32 v0, 0x7c, v0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
.LBB1_6:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_two_marker_ones
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
.Lfunc_end1:
	.size	named_two_marker_ones, .Lfunc_end1-named_two_marker_ones
                                        ; -- End function
	.set named_two_marker_ones.num_vgpr, 2
	.set named_two_marker_ones.num_agpr, 0
	.set named_two_marker_ones.numbered_sgpr, 6
	.set named_two_marker_ones.num_named_barrier, 1
	.set named_two_marker_ones.private_seg_size, 0
	.set named_two_marker_ones.uses_vcc, 1
	.set named_two_marker_ones.uses_flat_scratch, 0
	.set named_two_marker_ones.has_dyn_sized_stack, 0
	.set named_two_marker_ones.has_recursion, 0
	.set named_two_marker_ones.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 172
; TotalNumSgprs: 8
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
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
	.globl	named_one_arrival_marker        ; -- Begin function named_one_arrival_marker
	.p2align	8
	.type	named_one_arrival_marker,@function
named_one_arrival_marker:               ; @named_one_arrival_marker
; %bb.0:                                ; %entry
	s_load_b64 s[0:1], s[4:5], 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 1.0
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_one_arrival_marker
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 264
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
	.size	named_one_arrival_marker, .Lfunc_end2-named_one_arrival_marker
                                        ; -- End function
	.set named_one_arrival_marker.num_vgpr, 2
	.set named_one_arrival_marker.num_agpr, 0
	.set named_one_arrival_marker.numbered_sgpr, 6
	.set named_one_arrival_marker.num_named_barrier, 1
	.set named_one_arrival_marker.private_seg_size, 0
	.set named_one_arrival_marker.uses_vcc, 0
	.set named_one_arrival_marker.uses_flat_scratch, 0
	.set named_one_arrival_marker.has_dyn_sized_stack, 0
	.set named_one_arrival_marker.has_recursion, 0
	.set named_one_arrival_marker.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 64
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
	.globl	named_wait_then_copy_exit       ; -- Begin function named_wait_then_copy_exit
	.p2align	8
	.type	named_wait_then_copy_exit,@function
named_wait_then_copy_exit:              ; @named_wait_then_copy_exit
; %bb.0:                                ; %entry
	s_load_b128 s[0:3], s[4:5], 0x0
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_wait 1
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	global_store_b32 v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_wait_then_copy_exit
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
.Lfunc_end3:
	.size	named_wait_then_copy_exit, .Lfunc_end3-named_wait_then_copy_exit
                                        ; -- End function
	.set named_wait_then_copy_exit.num_vgpr, 2
	.set named_wait_then_copy_exit.num_agpr, 0
	.set named_wait_then_copy_exit.numbered_sgpr, 6
	.set named_wait_then_copy_exit.num_named_barrier, 1
	.set named_wait_then_copy_exit.private_seg_size, 0
	.set named_wait_then_copy_exit.uses_vcc, 0
	.set named_wait_then_copy_exit.uses_flat_scratch, 0
	.set named_wait_then_copy_exit.has_dyn_sized_stack, 0
	.set named_wait_then_copy_exit.has_recursion, 0
	.set named_wait_then_copy_exit.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 76
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
	.globl	named_copy_then_metadata_phase_7 ; -- Begin function named_copy_then_metadata_phase_7
	.p2align	8
	.type	named_copy_then_metadata_phase_7,@function
named_copy_then_metadata_phase_7:       ; @named_copy_then_metadata_phase_7
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB4_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB4_2:                                ; %rendezvous0
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
	s_cbranch_execz .LBB4_4
; %bb.3:                                ; %consume0
	s_barrier_wait 1
.LBB4_4:                                ; %Flow6
	s_or_saveexec_b32 s1, s0
	s_load_b128 s[4:7], s[4:5], 0x0
	s_xor_b32 exec_lo, exec_lo, s1
	s_cbranch_execz .LBB4_8
; %bb.5:                                ; %produce0
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB4_7
; %bb.6:                                ; %copy
	s_wait_kmcnt 0x0
	s_load_b128 s[8:11], s[4:5], 0x0
	v_mov_b32_e32 v1, 0
	s_wait_kmcnt 0x0
	v_mov_b64_e32 v[2:3], s[8:9]
	v_mov_b64_e32 v[4:5], s[10:11]
	ds_store_b128 v1, v[2:5]
.LBB4_7:                                ; %signal0
	s_or_b32 exec_lo, exec_lo, s2
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
.LBB4_8:                                ; %Flow7
	s_or_b32 exec_lo, exec_lo, s1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execnz .LBB4_11
; %bb.9:                                ; %Flow4
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execnz .LBB4_14
.LBB4_10:                               ; %end
	s_endpgm
.LBB4_11:                               ; %consume1
	s_mov_b32 s1, exec_lo
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB4_13
; %bb.12:                               ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0 offset:16
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[6:7]
.LBB4_13:                               ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
                                        ; implicit-def: $vgpr0
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB4_10
.LBB4_14:                               ; %produce1
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB4_16
; %bb.15:                               ; %write
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	ds_store_b32 v0, v1 offset:16
.LBB4_16:                               ; %signal1
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_copy_then_metadata_phase_7
		.amdhsa_group_segment_fixed_size 20
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
.Lfunc_end4:
	.size	named_copy_then_metadata_phase_7, .Lfunc_end4-named_copy_then_metadata_phase_7
                                        ; -- End function
	.set named_copy_then_metadata_phase_7.num_vgpr, 6
	.set named_copy_then_metadata_phase_7.num_agpr, 0
	.set named_copy_then_metadata_phase_7.numbered_sgpr, 12
	.set named_copy_then_metadata_phase_7.num_named_barrier, 1
	.set named_copy_then_metadata_phase_7.private_seg_size, 0
	.set named_copy_then_metadata_phase_7.uses_vcc, 1
	.set named_copy_then_metadata_phase_7.uses_flat_scratch, 0
	.set named_copy_then_metadata_phase_7.has_dyn_sized_stack, 0
	.set named_copy_then_metadata_phase_7.has_recursion, 0
	.set named_copy_then_metadata_phase_7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 324
; TotalNumSgprs: 14
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 20 bytes/workgroup (compile time only)
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
	.globl	named_producer_first_buffer_is_free ; -- Begin function named_producer_first_buffer_is_free
	.p2align	8
	.type	named_producer_first_buffer_is_free,@function
named_producer_first_buffer_is_free:    ; @named_producer_first_buffer_is_free
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB5_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10002
	s_barrier_init m0 
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
.LBB5_2:                                ; %choose
	s_or_b32 exec_lo, exec_lo, s1
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB5_4
; %bb.3:                                ; %joinfull
	s_mov_b32 m0, 2
	s_barrier_join m0 
.LBB5_4:                                ; %Flow6
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB5_6
; %bb.5:                                ; %joinempty
	s_mov_b32 m0, 1
	s_barrier_join m0 
.LBB5_6:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b128 s[0:3], s[4:5], 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
	s_cbranch_execnz .LBB5_9
; %bb.7:                                ; %Flow4
	s_wait_kmcnt 0x0
	s_and_not1_saveexec_b32 s2, s4
	s_cbranch_execnz .LBB5_14
.LBB5_8:                                ; %end
	s_endpgm
.LBB5_9:                                ; %consume0
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
	s_barrier_wait 2
	s_and_saveexec_b32 s5, vcc_lo
	s_cbranch_execz .LBB5_11
; %bb.10:                               ; %read0
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB5_11:                               ; %releaseempty
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s5
	s_mov_b32 m0, 2
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_join m0 
	s_mov_b32 m0, 1
	s_barrier_signal m0 
	s_barrier_wait 2
	s_and_saveexec_b32 s5, vcc_lo
	s_cbranch_execz .LBB5_13
; %bb.12:                               ; %read1
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB5_13:                               ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s5
                                        ; implicit-def: $vgpr0
	s_wait_kmcnt 0x0
	s_and_not1_saveexec_b32 s2, s4
	s_cbranch_execz .LBB5_8
.LBB5_14:                               ; %produce0
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_16
; %bb.15:                               ; %write0
	v_mov_b32_e32 v0, 0
	global_load_b32 v1, v0, s[0:1]
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB5_16:                               ; %signal0
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 2
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_18
; %bb.17:                               ; %write1
	v_mov_b32_e32 v0, 0
	global_load_b32 v1, v0, s[0:1] offset:4
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB5_18:                               ; %signal1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_producer_first_buffer_is_free
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
.Lfunc_end5:
	.size	named_producer_first_buffer_is_free, .Lfunc_end5-named_producer_first_buffer_is_free
                                        ; -- End function
	.set named_producer_first_buffer_is_free.num_vgpr, 2
	.set named_producer_first_buffer_is_free.num_agpr, 0
	.set named_producer_first_buffer_is_free.numbered_sgpr, 6
	.set named_producer_first_buffer_is_free.num_named_barrier, 2
	.set named_producer_first_buffer_is_free.private_seg_size, 0
	.set named_producer_first_buffer_is_free.uses_vcc, 1
	.set named_producer_first_buffer_is_free.uses_flat_scratch, 0
	.set named_producer_first_buffer_is_free.has_dyn_sized_stack, 0
	.set named_producer_first_buffer_is_free.has_recursion, 0
	.set named_producer_first_buffer_is_free.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 408
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
      - .offset:         88
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         96
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         104
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         112
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         120
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         208
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 264
    .max_flat_workgroup_size: 64
    .name:           named_wait_only_consumer_42
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_wait_only_consumer_42.kd
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
      - .name:           skip
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
    .name:           named_two_marker_ones
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_two_marker_ones.kd
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
      - .offset:         88
        .size:           8
        .value_kind:     hidden_hostcall_buffer
      - .offset:         96
        .size:           8
        .value_kind:     hidden_multigrid_sync_arg
      - .offset:         104
        .size:           8
        .value_kind:     hidden_heap_v1
      - .offset:         112
        .size:           8
        .value_kind:     hidden_default_queue
      - .offset:         120
        .size:           8
        .value_kind:     hidden_completion_action
      - .offset:         208
        .size:           8
        .value_kind:     hidden_queue_ptr
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 264
    .max_flat_workgroup_size: 64
    .name:           named_one_arrival_marker
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_one_arrival_marker.kd
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
    .name:           named_wait_then_copy_exit
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_wait_then_copy_exit.kd
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
    .group_segment_fixed_size: 20
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_copy_then_metadata_phase_7
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         named_copy_then_metadata_phase_7.kd
    .uses_dynamic_stack: false
    .vgpr_count:     6
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 64
    .name:           named_producer_first_buffer_is_free
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_producer_first_buffer_is_free.kd
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
