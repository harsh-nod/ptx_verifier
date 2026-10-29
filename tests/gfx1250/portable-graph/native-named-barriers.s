	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_identity                  ; -- Begin function named_identity
	.p2align	8
	.type	named_identity,@function
named_identity:                         ; @named_identity
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB0_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b128 s[0:3], s[4:5], 0x0
	s_mov_b32 m0, 1
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_4
; %bb.3:                                ; %produce
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, s0
	ds_store_b32 v1, v2
.LBB0_4:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s4
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 1
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB0_6
; %bb.5:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB0_6:                                ; %leave
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_barrier_leave
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_identity
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
.Lfunc_end0:
	.size	named_identity, .Lfunc_end0-named_identity
                                        ; -- End function
	.set named_identity.num_vgpr, 3
	.set named_identity.num_agpr, 0
	.set named_identity.numbered_sgpr, 6
	.set named_identity.num_named_barrier, 1
	.set named_identity.private_seg_size, 0
	.set named_identity.uses_vcc, 0
	.set named_identity.uses_flat_scratch, 0
	.set named_identity.has_dyn_sized_stack, 0
	.set named_identity.has_recursion, 0
	.set named_identity.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 184
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 6
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
	.globl	named_encoded_wait_uses_last_join ; -- Begin function named_encoded_wait_uses_last_join
	.p2align	8
	.type	named_encoded_wait_uses_last_join,@function
named_encoded_wait_uses_last_join:      ; @named_encoded_wait_uses_last_join
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB1_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB1_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b128 s[0:3], s[4:5], 0x0
	s_mov_b32 m0, 1
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_4
; %bb.3:                                ; %produce
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, s0
	ds_store_b32 v1, v2
.LBB1_4:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s4
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_mov_b32 s0, exec_lo
	s_barrier_signal m0 
	s_barrier_wait 2
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB1_6
; %bb.5:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB1_6:                                ; %leave
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_barrier_leave
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_encoded_wait_uses_last_join
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
	.size	named_encoded_wait_uses_last_join, .Lfunc_end1-named_encoded_wait_uses_last_join
                                        ; -- End function
	.set named_encoded_wait_uses_last_join.num_vgpr, 3
	.set named_encoded_wait_uses_last_join.num_agpr, 0
	.set named_encoded_wait_uses_last_join.numbered_sgpr, 6
	.set named_encoded_wait_uses_last_join.num_named_barrier, 1
	.set named_encoded_wait_uses_last_join.private_seg_size, 0
	.set named_encoded_wait_uses_last_join.uses_vcc, 0
	.set named_encoded_wait_uses_last_join.uses_flat_scratch, 0
	.set named_encoded_wait_uses_last_join.has_dyn_sized_stack, 0
	.set named_encoded_wait_uses_last_join.has_recursion, 0
	.set named_encoded_wait_uses_last_join.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 184
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 6
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
	.globl	named_reinitialized_identity    ; -- Begin function named_reinitialized_identity
	.p2align	8
	.type	named_reinitialized_identity,@function
named_reinitialized_identity:           ; @named_reinitialized_identity
; %bb.0:                                ; %entry
	s_load_b128 s[4:7], s[4:5], 0x0
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b64 s[2:3], 0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	v_cmp_eq_u32_e64 s0, 0, v0
	v_cmp_eq_u32_e64 s1, 32, v0
	v_mov_b32_e32 v0, 0
	s_branch .LBB2_2
.LBB2_1:                                ; %leave
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s8
	s_add_nc_u64 s[2:3], s[2:3], 4
	s_barrier_leave
	s_wait_kmcnt 0x0
	s_cmp_lg_u32 s2, 8
	s_barrier_signal -1
	s_barrier_wait -1
	s_cbranch_scc0 .LBB2_8
.LBB2_2:                                ; %loop
                                        ; =>This Inner Loop Header: Depth=1
	s_and_saveexec_b32 s8, vcc_lo
	s_cbranch_execz .LBB2_4
; %bb.3:                                ; %init
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB2_4:                                ; %rendezvous
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s8
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_and_saveexec_b32 s8, s0
	s_cbranch_execz .LBB2_6
; %bb.5:                                ; %produce
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[10:11], s[4:5], s[2:3]
	global_load_b32 v1, v0, s[10:11]
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB2_6:                                ; %signal
                                        ;   in Loop: Header=BB2_2 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s8
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_saveexec_b32 s8, s1
	s_cbranch_execz .LBB2_1
; %bb.7:                                ; %read
                                        ;   in Loop: Header=BB2_2 Depth=1
	ds_load_b32 v1, v0
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[10:11], s[6:7], s[2:3]
	s_wait_dscnt 0x0
	global_store_b32 v0, v1, s[10:11]
	s_branch .LBB2_1
.LBB2_8:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_reinitialized_identity
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
.Lfunc_end2:
	.size	named_reinitialized_identity, .Lfunc_end2-named_reinitialized_identity
                                        ; -- End function
	.set named_reinitialized_identity.num_vgpr, 2
	.set named_reinitialized_identity.num_agpr, 0
	.set named_reinitialized_identity.numbered_sgpr, 12
	.set named_reinitialized_identity.num_named_barrier, 1
	.set named_reinitialized_identity.private_seg_size, 0
	.set named_reinitialized_identity.uses_vcc, 1
	.set named_reinitialized_identity.uses_flat_scratch, 0
	.set named_reinitialized_identity.has_dyn_sized_stack, 0
	.set named_reinitialized_identity.has_recursion, 0
	.set named_reinitialized_identity.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 232
; TotalNumSgprs: 14
; NumVgprs: 2
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
	.globl	named_subset_drop               ; -- Begin function named_subset_drop
	.p2align	8
	.type	named_subset_drop,@function
named_subset_drop:                      ; @named_subset_drop
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB3_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x30001
	s_barrier_init m0 
.LBB3_2:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_mov_b32 m0, 1
	s_mov_b32 s6, exec_lo
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	v_cmpx_gt_u32_e32 64, v0
	s_cbranch_execz .LBB3_7
; %bb.3:                                ; %work
	s_load_b128 s[0:3], s[4:5], 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB3_5
; %bb.4:                                ; %produce
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, s0
	ds_store_b32 v1, v2
.LBB3_5:                                ; %signal
	s_or_b32 exec_lo, exec_lo, s4
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_7
; %bb.6:                                ; %read
	v_mov_b32_e32 v0, 0
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[2:3]
.LBB3_7:                                ; %Flow4
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s6
	s_barrier_leave
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_subset_drop
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
		.amdhsa_next_free_vgpr 65
		.amdhsa_next_free_sgpr 7
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
	.size	named_subset_drop, .Lfunc_end3-named_subset_drop
                                        ; -- End function
	.set named_subset_drop.num_vgpr, 3
	.set named_subset_drop.num_agpr, 0
	.set named_subset_drop.numbered_sgpr, 7
	.set named_subset_drop.num_named_barrier, 1
	.set named_subset_drop.private_seg_size, 0
	.set named_subset_drop.uses_vcc, 1
	.set named_subset_drop.uses_flat_scratch, 0
	.set named_subset_drop.has_dyn_sized_stack, 0
	.set named_subset_drop.has_recursion, 0
	.set named_subset_drop.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 196
; TotalNumSgprs: 9
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 65
; NamedBarCnt: 1
; Occupancy: 12
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
	.text
	.globl	named_null_unjoin               ; -- Begin function named_null_unjoin
	.p2align	8
	.type	named_null_unjoin,@function
named_null_unjoin:                      ; @named_null_unjoin
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 m0, 0
	s_mov_b32 s0, exec_lo
	s_barrier_init m0 
	s_mov_b32 m0, 0x50000
	s_barrier_leave
	s_barrier_signal m0 
	s_barrier_join 0
	s_barrier_wait 0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB4_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB4_2:                                ; %rendezvous
	s_wait_kmcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_mov_b32 m0, 1
	s_barrier_signal -1
	s_barrier_wait -1
	s_barrier_join m0 
	s_barrier_join 0
	s_barrier_wait 1
	s_barrier_leave
	s_barrier_wait 1
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB4_4
; %bb.3:                                ; %copy
	s_load_b128 s[0:3], s[4:5], 0x0
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	global_store_b32 v0, v1, s[2:3]
.LBB4_4:                                ; %end
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_null_unjoin
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
	.size	named_null_unjoin, .Lfunc_end4-named_null_unjoin
                                        ; -- End function
	.set named_null_unjoin.num_vgpr, 2
	.set named_null_unjoin.num_agpr, 0
	.set named_null_unjoin.numbered_sgpr, 6
	.set named_null_unjoin.num_named_barrier, 1
	.set named_null_unjoin.private_seg_size, 0
	.set named_null_unjoin.uses_vcc, 0
	.set named_null_unjoin.uses_flat_scratch, 0
	.set named_null_unjoin.has_dyn_sized_stack, 0
	.set named_null_unjoin.has_recursion, 0
	.set named_null_unjoin.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 164
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 6
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
	.globl	named_two_arrivals_one_wave     ; -- Begin function named_two_arrivals_one_wave
	.p2align	8
	.type	named_two_arrivals_one_wave,@function
named_two_arrivals_one_wave:            ; @named_two_arrivals_one_wave
; %bb.0:                                ; %entry
	s_load_b128 s[0:3], s[4:5], 0x0
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
	s_mov_b32 m0, 1
	s_barrier_join m0 
	s_barrier_signal m0 
	s_barrier_signal m0 
	; wave barrier
	s_wait_kmcnt 0x0
	s_load_b32 s0, s[0:1], 0x0
	s_wait_kmcnt 0x0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s0
	global_store_b32 v0, v1, s[2:3]
	s_barrier_leave
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_two_arrivals_one_wave
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
		.amdhsa_system_vgpr_workitem_id 0
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
	.size	named_two_arrivals_one_wave, .Lfunc_end5-named_two_arrivals_one_wave
                                        ; -- End function
	.set named_two_arrivals_one_wave.num_vgpr, 2
	.set named_two_arrivals_one_wave.num_agpr, 0
	.set named_two_arrivals_one_wave.numbered_sgpr, 6
	.set named_two_arrivals_one_wave.num_named_barrier, 1
	.set named_two_arrivals_one_wave.private_seg_size, 0
	.set named_two_arrivals_one_wave.uses_vcc, 0
	.set named_two_arrivals_one_wave.uses_flat_scratch, 0
	.set named_two_arrivals_one_wave.has_dyn_sized_stack, 0
	.set named_two_arrivals_one_wave.has_recursion, 0
	.set named_two_arrivals_one_wave.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 80
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
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
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
    .name:           named_identity
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_identity.kd
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .name:           named_encoded_wait_uses_last_join
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_encoded_wait_uses_last_join.kd
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .name:           named_reinitialized_identity
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         named_reinitialized_identity.kd
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .max_flat_workgroup_size: 96
    .name:           named_subset_drop
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         named_subset_drop.kd
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .name:           named_null_unjoin
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_null_unjoin.kd
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
    .max_flat_workgroup_size: 1
    .name:           named_two_arrivals_one_wave
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         named_two_arrivals_one_wave.kd
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
