	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_phase_count_update7       ; -- Begin function named_phase_count_update7
	.p2align	8
	.type	named_phase_count_update7,@function
named_phase_count_update7:              ; @named_phase_count_update7
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB0_2:                                ; %join
	s_or_b32 exec_lo, exec_lo, s0
	v_cmp_eq_u32_e64 s0, 0, v0
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_4
; %bb.3:                                ; %write
	v_dual_mov_b32 v2, 0x40e00000 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	v_add_f32 v2, 0, v2
	;;#ASMEND
	ds_store_b32 v1, v2
.LBB0_4:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b64 s[2:3], s[4:5], 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 0x20001
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB0_6
; %bb.5:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB0_6:                                ; %gate
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB0_9
; %bb.7:                                ; %second
	s_mov_b32 m0, 0x10001
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_b32 exec_lo, exec_lo, s0
	s_cbranch_execz .LBB0_9
; %bb.8:                                ; %marker
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB0_9:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_phase_count_update7
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
	.size	named_phase_count_update7, .Lfunc_end0-named_phase_count_update7
                                        ; -- End function
	.set named_phase_count_update7.num_vgpr, 3
	.set named_phase_count_update7.num_agpr, 0
	.set named_phase_count_update7.numbered_sgpr, 6
	.set named_phase_count_update7.num_named_barrier, 1
	.set named_phase_count_update7.private_seg_size, 0
	.set named_phase_count_update7.uses_vcc, 1
	.set named_phase_count_update7.uses_flat_scratch, 0
	.set named_phase_count_update7.has_dyn_sized_stack, 0
	.set named_phase_count_update7.has_recursion, 0
	.set named_phase_count_update7.has_indirect_call, 0
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
	.globl	named_signal_count_deadlock7    ; -- Begin function named_signal_count_deadlock7
	.p2align	8
	.type	named_signal_count_deadlock7,@function
named_signal_count_deadlock7:           ; @named_signal_count_deadlock7
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e64 s0, 31, v0
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB1_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB1_2:                                ; %join
	s_or_b32 exec_lo, exec_lo, s1
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB1_4
; %bb.3:                                ; %delayconsumer
	;;#ASMSTART
	s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
	;;#ASMEND
.LBB1_4:                                ; %dispatch
	s_or_b32 exec_lo, exec_lo, s1
	v_cmp_eq_u32_e64 s0, 0, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB1_6
; %bb.5:                                ; %write
	v_dual_mov_b32 v2, 0x40e00000 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	v_add_f32 v2, 0, v2
	;;#ASMEND
	ds_store_b32 v1, v2
.LBB1_6:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b64 s[2:3], s[4:5], 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 0x30001
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB1_8
; %bb.7:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB1_8:                                ; %gate
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB1_11
; %bb.9:                                ; %second
	s_mov_b32 m0, 0x10001
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_b32 exec_lo, exec_lo, s0
	s_cbranch_execz .LBB1_11
; %bb.10:                               ; %marker
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB1_11:                               ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_signal_count_deadlock7
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
	.size	named_signal_count_deadlock7, .Lfunc_end1-named_signal_count_deadlock7
                                        ; -- End function
	.set named_signal_count_deadlock7.num_vgpr, 3
	.set named_signal_count_deadlock7.num_agpr, 0
	.set named_signal_count_deadlock7.numbered_sgpr, 6
	.set named_signal_count_deadlock7.num_named_barrier, 1
	.set named_signal_count_deadlock7.private_seg_size, 0
	.set named_signal_count_deadlock7.uses_vcc, 1
	.set named_signal_count_deadlock7.uses_flat_scratch, 0
	.set named_signal_count_deadlock7.has_dyn_sized_stack, 0
	.set named_signal_count_deadlock7.has_recursion, 0
	.set named_signal_count_deadlock7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 276
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
	.globl	named_signal_count_deadlock7_reverse ; -- Begin function named_signal_count_deadlock7_reverse
	.p2align	8
	.type	named_signal_count_deadlock7_reverse,@function
named_signal_count_deadlock7_reverse:   ; @named_signal_count_deadlock7_reverse
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB2_2:                                ; %join
	s_or_b32 exec_lo, exec_lo, s0
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB2_4
; %bb.3:                                ; %delayproducer
	;;#ASMSTART
	s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
	;;#ASMEND
.LBB2_4:                                ; %dispatch
	s_or_b32 exec_lo, exec_lo, s0
	v_cmp_eq_u32_e64 s0, 0, v0
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB2_6
; %bb.5:                                ; %write
	v_dual_mov_b32 v2, 0x40e00000 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	v_add_f32 v2, 0, v2
	;;#ASMEND
	ds_store_b32 v1, v2
.LBB2_6:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s1
	s_load_b64 s[2:3], s[4:5], 0x0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 0x30001
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB2_8
; %bb.7:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB2_8:                                ; %gate
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s1, vcc_lo
	s_cbranch_execz .LBB2_11
; %bb.9:                                ; %second
	s_mov_b32 m0, 0x10001
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_b32 exec_lo, exec_lo, s0
	s_cbranch_execz .LBB2_11
; %bb.10:                               ; %marker
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3] offset:4
.LBB2_11:                               ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_signal_count_deadlock7_reverse
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
.Lfunc_end2:
	.size	named_signal_count_deadlock7_reverse, .Lfunc_end2-named_signal_count_deadlock7_reverse
                                        ; -- End function
	.set named_signal_count_deadlock7_reverse.num_vgpr, 3
	.set named_signal_count_deadlock7_reverse.num_agpr, 0
	.set named_signal_count_deadlock7_reverse.numbered_sgpr, 6
	.set named_signal_count_deadlock7_reverse.num_named_barrier, 1
	.set named_signal_count_deadlock7_reverse.private_seg_size, 0
	.set named_signal_count_deadlock7_reverse.uses_vcc, 1
	.set named_signal_count_deadlock7_reverse.uses_flat_scratch, 0
	.set named_signal_count_deadlock7_reverse.has_dyn_sized_stack, 0
	.set named_signal_count_deadlock7_reverse.has_recursion, 0
	.set named_signal_count_deadlock7_reverse.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 268
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
	.globl	named_decrease_below_arrived7   ; -- Begin function named_decrease_below_arrived7
	.p2align	8
	.type	named_decrease_below_arrived7,@function
named_decrease_below_arrived7:          ; @named_decrease_below_arrived7
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB3_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x30001
	s_barrier_init m0 
.LBB3_2:                                ; %join
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
	s_cbranch_execnz .LBB3_5
; %bb.3:                                ; %Flow
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execnz .LBB3_6
.LBB3_4:                                ; %UnifiedReturnBlock
	s_endpgm
.LBB3_5:                                ; %consume
	;;#ASMSTART
	s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
	;;#ASMEND
	s_mov_b32 m0, 0x10001
                                        ; implicit-def: $vgpr0
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB3_4
.LBB3_6:                                ; %produce
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB3_8
; %bb.7:                                ; %write
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	ds_store_b32 v0, v1
.LBB3_8:                                ; %arrive
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 0x30001
	s_barrier_signal m0 
	s_barrier_signal m0 
	s_barrier_wait 1
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_decrease_below_arrived7
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
		.amdhsa_next_free_sgpr 2
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
	.size	named_decrease_below_arrived7, .Lfunc_end3-named_decrease_below_arrived7
                                        ; -- End function
	.set named_decrease_below_arrived7.num_vgpr, 2
	.set named_decrease_below_arrived7.num_agpr, 0
	.set named_decrease_below_arrived7.numbered_sgpr, 2
	.set named_decrease_below_arrived7.num_named_barrier, 1
	.set named_decrease_below_arrived7.private_seg_size, 0
	.set named_decrease_below_arrived7.uses_vcc, 1
	.set named_decrease_below_arrived7.uses_flat_scratch, 0
	.set named_decrease_below_arrived7.has_dyn_sized_stack, 0
	.set named_decrease_below_arrived7.has_recursion, 0
	.set named_decrease_below_arrived7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 180
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 4
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
	.globl	named_equal_arrived_boundary7   ; -- Begin function named_equal_arrived_boundary7
	.p2align	8
	.type	named_equal_arrived_boundary7,@function
named_equal_arrived_boundary7:          ; @named_equal_arrived_boundary7
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB4_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB4_2:                                ; %join
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
	s_cbranch_execnz .LBB4_5
; %bb.3:                                ; %Flow
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execnz .LBB4_6
.LBB4_4:                                ; %UnifiedReturnBlock
	s_endpgm
.LBB4_5:                                ; %consume
	;;#ASMSTART
	s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
	;;#ASMEND
	s_mov_b32 m0, 0x10001
                                        ; implicit-def: $vgpr0
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB4_4
.LBB4_6:                                ; %produce
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB4_8
; %bb.7:                                ; %write
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	ds_store_b32 v0, v1
.LBB4_8:                                ; %arrive
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 0x20001
	s_barrier_signal m0 
	s_barrier_wait 1
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_equal_arrived_boundary7
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
		.amdhsa_next_free_sgpr 2
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
.Lfunc_end4:
	.size	named_equal_arrived_boundary7, .Lfunc_end4-named_equal_arrived_boundary7
                                        ; -- End function
	.set named_equal_arrived_boundary7.num_vgpr, 2
	.set named_equal_arrived_boundary7.num_agpr, 0
	.set named_equal_arrived_boundary7.numbered_sgpr, 2
	.set named_equal_arrived_boundary7.num_named_barrier, 1
	.set named_equal_arrived_boundary7.private_seg_size, 0
	.set named_equal_arrived_boundary7.uses_vcc, 1
	.set named_equal_arrived_boundary7.uses_flat_scratch, 0
	.set named_equal_arrived_boundary7.has_dyn_sized_stack, 0
	.set named_equal_arrived_boundary7.has_recursion, 0
	.set named_equal_arrived_boundary7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 176
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 4
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
	.globl	named_zero_update_marker7       ; -- Begin function named_zero_update_marker7
	.p2align	8
	.type	named_zero_update_marker7,@function
named_zero_update_marker7:              ; @named_zero_update_marker7
; %bb.0:                                ; %entry
	s_mov_b32 m0, 0x10001
	s_mov_b32 s0, 1
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
.LBB5_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	s_add_co_i32 s0, s0, -1
	s_barrier_signal m0 
	s_cmp_lg_u32 s0, 0
	s_cbranch_scc1 .LBB5_1
; %bb.2:                                ; %wait
	s_load_b64 s[0:1], s[4:5], 0x0
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	s_barrier_wait 1
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_zero_update_marker7
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
.Lfunc_end5:
	.size	named_zero_update_marker7, .Lfunc_end5-named_zero_update_marker7
                                        ; -- End function
	.set named_zero_update_marker7.num_vgpr, 2
	.set named_zero_update_marker7.num_agpr, 0
	.set named_zero_update_marker7.numbered_sgpr, 6
	.set named_zero_update_marker7.num_named_barrier, 1
	.set named_zero_update_marker7.private_seg_size, 0
	.set named_zero_update_marker7.uses_vcc, 0
	.set named_zero_update_marker7.uses_flat_scratch, 0
	.set named_zero_update_marker7.has_dyn_sized_stack, 0
	.set named_zero_update_marker7.has_recursion, 0
	.set named_zero_update_marker7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 84
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
	.globl	named_null_update_marker7       ; -- Begin function named_null_update_marker7
	.p2align	8
	.type	named_null_update_marker7,@function
named_null_update_marker7:              ; @named_null_update_marker7
; %bb.0:                                ; %entry
	s_mov_b32 m0, 0x7f0000
	s_mov_b32 s0, 1
	s_barrier_signal m0 
	s_mov_b32 m0, 0x10001
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
.LBB6_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	s_add_co_i32 s0, s0, -1
	s_barrier_signal m0 
	s_cmp_lg_u32 s0, 0
	s_cbranch_scc1 .LBB6_1
; %bb.2:                                ; %wait
	s_load_b64 s[0:1], s[4:5], 0x0
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	s_barrier_wait 1
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_null_update_marker7
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
.Lfunc_end6:
	.size	named_null_update_marker7, .Lfunc_end6-named_null_update_marker7
                                        ; -- End function
	.set named_null_update_marker7.num_vgpr, 2
	.set named_null_update_marker7.num_agpr, 0
	.set named_null_update_marker7.numbered_sgpr, 6
	.set named_null_update_marker7.num_named_barrier, 1
	.set named_null_update_marker7.private_seg_size, 0
	.set named_null_update_marker7.uses_vcc, 0
	.set named_null_update_marker7.uses_flat_scratch, 0
	.set named_null_update_marker7.has_dyn_sized_stack, 0
	.set named_null_update_marker7.has_recursion, 0
	.set named_null_update_marker7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 96
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
	.globl	named_max_signal_count7         ; -- Begin function named_max_signal_count7
	.p2align	8
	.type	named_max_signal_count7,@function
named_max_signal_count7:                ; @named_max_signal_count7
; %bb.0:                                ; %entry
	s_mov_b32 m0, 0x10001
	s_movk_i32 s0, 0x7f
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_mov_b32 m0, 0x7f0001
.LBB7_1:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	s_add_co_i32 s0, s0, -1
	s_barrier_signal m0 
	s_cmp_lg_u32 s0, 0
	s_cbranch_scc1 .LBB7_1
; %bb.2:                                ; %wait
	s_load_b64 s[0:1], s[4:5], 0x0
	v_dual_mov_b32 v1, 0x40e00000 :: v_dual_mov_b32 v0, 0
	s_barrier_wait 1
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_max_signal_count7
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
.Lfunc_end7:
	.size	named_max_signal_count7, .Lfunc_end7-named_max_signal_count7
                                        ; -- End function
	.set named_max_signal_count7.num_vgpr, 2
	.set named_max_signal_count7.num_agpr, 0
	.set named_max_signal_count7.numbered_sgpr, 6
	.set named_max_signal_count7.num_named_barrier, 1
	.set named_max_signal_count7.private_seg_size, 0
	.set named_max_signal_count7.uses_vcc, 0
	.set named_max_signal_count7.uses_flat_scratch, 0
	.set named_max_signal_count7.has_dyn_sized_stack, 0
	.set named_max_signal_count7.has_recursion, 0
	.set named_max_signal_count7.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 92
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
    .name:           named_phase_count_update7
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_phase_count_update7.kd
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
    .name:           named_signal_count_deadlock7
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_signal_count_deadlock7.kd
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
    .name:           named_signal_count_deadlock7_reverse
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         named_signal_count_deadlock7_reverse.kd
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
    .name:           named_decrease_below_arrived7
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         named_decrease_below_arrived7.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 264
    .max_flat_workgroup_size: 64
    .name:           named_equal_arrived_boundary7
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         named_equal_arrived_boundary7.kd
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
    .name:           named_zero_update_marker7
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_zero_update_marker7.kd
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
    .name:           named_null_update_marker7
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_null_update_marker7.kd
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
    .name:           named_max_signal_count7
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_max_signal_count7.kd
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
