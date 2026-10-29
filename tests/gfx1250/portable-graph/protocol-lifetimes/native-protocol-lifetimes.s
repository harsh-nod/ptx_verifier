	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	ended_reader            ; -- Begin function ended_reader
	.globl	ended_reader
	.p2align	8
	.type	ended_reader,@function
ended_reader:                           ; @ended_reader
; %bb.0:
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 s2, 0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB0_2
; %bb.1:
	v_dual_mov_b32 v2, 42 :: v_dual_mov_b32 v1, 0
	s_mov_b64 s[6:7], src_shared_base
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	s_mov_b32 s3, s7
	flat_store_b32 v1, v2, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_4
; %bb.3:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	flat_load_b32 v1, v1, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	;;#ASMEND
.LBB0_4:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b32 s0, s[0:1], 0x8
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB0_6
; %bb.5:
	s_barrier_signal -1
	s_barrier_wait -1
.LBB0_6:
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB0_9
; %bb.7:
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
	; wave barrier
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB0_9
; %bb.8:
	v_dual_mov_b32 v1, 7 :: v_dual_mov_b32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v0, v1, s[0:1] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_9:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel ended_reader
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 12
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
		.amdhsa_next_free_sgpr 8
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
	.size	ended_reader, .Lfunc_end0-ended_reader
                                        ; -- End function
	.set ended_reader.num_vgpr, 3
	.set ended_reader.num_agpr, 0
	.set ended_reader.numbered_sgpr, 8
	.set ended_reader.num_named_barrier, 0
	.set ended_reader.private_seg_size, 0
	.set ended_reader.uses_vcc, 1
	.set ended_reader.uses_flat_scratch, 0
	.set ended_reader.has_dyn_sized_stack, 0
	.set ended_reader.has_recursion, 0
	.set ended_reader.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 196
; TotalNumSgprs: 10
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.protected	ended_writer            ; -- Begin function ended_writer
	.globl	ended_writer
	.p2align	8
	.type	ended_writer,@function
ended_writer:                           ; @ended_writer
; %bb.0:
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 s2, 0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB1_2
; %bb.1:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 0
	s_mov_b64 s[6:7], src_shared_base
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_mov_b32 s3, s7
	flat_store_b32 v2, v1, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB1_4
; %bb.3:
	v_dual_mov_b32 v2, 42 :: v_dual_mov_b32 v1, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b32 s2, s[0:1], 0x8
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_cmp_eq_u32 s2, 0
	s_cbranch_scc1 .LBB1_6
; %bb.5:
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
.LBB1_6:
	s_mov_b32 s2, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB1_9
; %bb.7:
	v_cmp_eq_u32_e32 vcc_lo, 32, v0
	; wave barrier
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB1_9
; %bb.8:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
.LBB1_9:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel ended_writer
		.amdhsa_group_segment_fixed_size 4
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 12
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
		.amdhsa_next_free_sgpr 8
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
.Lfunc_end1:
	.size	ended_writer, .Lfunc_end1-ended_writer
                                        ; -- End function
	.set ended_writer.num_vgpr, 3
	.set ended_writer.num_agpr, 0
	.set ended_writer.numbered_sgpr, 8
	.set ended_writer.num_named_barrier, 0
	.set ended_writer.private_seg_size, 0
	.set ended_writer.uses_vcc, 1
	.set ended_writer.uses_flat_scratch, 0
	.set ended_writer.has_dyn_sized_stack, 0
	.set ended_writer.has_recursion, 0
	.set ended_writer.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 228
; TotalNumSgprs: 10
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.protected	metadata_eight_bytes    ; -- Begin function metadata_eight_bytes
	.globl	metadata_eight_bytes
	.p2align	8
	.type	metadata_eight_bytes,@function
metadata_eight_bytes:                   ; @metadata_eight_bytes
; %bb.0:
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB2_2
; %bb.1:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[4:5], src_shared_base
	s_mov_b32 s4, 0
	v_dual_mov_b32 v2, 1 :: v_dual_mov_b32 v3, 0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	;;#ASMSTART
	v_add_nc_u32 v3, 0, v3
	;;#ASMEND
	flat_store_b64 v1, v[2:3], s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b32 s2, s[0:1], 0x8
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_wait_kmcnt 0x0
	s_cmp_eq_u32 s2, 0
	s_cbranch_scc1 .LBB2_4
; %bb.3:
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
.LBB2_4:
	s_mov_b32 s2, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB2_6
; %bb.5:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_mov_b32_e32 v2, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	v_dual_mov_b32 v0, 42 :: v_dual_mov_b32 v1, 0
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	flat_store_b64 v2, v[0:1], s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b64 v[0:1], v2, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v0, 0, v0
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v2, v0, s[0:1]
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v2, v1, s[0:1] offset:4
.LBB2_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel metadata_eight_bytes
		.amdhsa_group_segment_fixed_size 8
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 12
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
.Lfunc_end2:
	.size	metadata_eight_bytes, .Lfunc_end2-metadata_eight_bytes
                                        ; -- End function
	.set metadata_eight_bytes.num_vgpr, 4
	.set metadata_eight_bytes.num_agpr, 0
	.set metadata_eight_bytes.numbered_sgpr, 6
	.set metadata_eight_bytes.num_named_barrier, 0
	.set metadata_eight_bytes.private_seg_size, 0
	.set metadata_eight_bytes.uses_vcc, 0
	.set metadata_eight_bytes.uses_flat_scratch, 0
	.set metadata_eight_bytes.has_dyn_sized_stack, 0
	.set metadata_eight_bytes.has_recursion, 0
	.set metadata_eight_bytes.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 192
; TotalNumSgprs: 6
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
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
	.protected	undefined_shuffle_source ; -- Begin function undefined_shuffle_source
	.globl	undefined_shuffle_source
	.p2align	8
	.type	undefined_shuffle_source,@function
undefined_shuffle_source:               ; @undefined_shuffle_source
; %bb.0:
	s_clause 0x1
	s_load_b32 s2, s[0:1], 0x10
	s_load_b128 s[4:7], s[0:1], 0x0
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	s_wait_kmcnt 0x0
	s_cmp_lg_u32 s2, 0
	s_cselect_b32 s0, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s1, s0, vcc_lo
	s_and_saveexec_b32 s0, s1
	s_cbranch_execz .LBB3_2
; %bb.1:
	global_load_b32 v1, v0, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	;;#ASMSTART
	v_mov_b32 v20, v1
	;;#ASMEND
.LBB3_2:
	s_or_b32 exec_lo, exec_lo, s0
	v_lshl_add_u32 v1, v0, 2, 32
	;;#ASMSTART
	ds_bpermute_b32 v1, v1, v20
	s_wait_dscnt 0
	;;#ASMEND
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB3_4
; %bb.3:
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[6:7] scale_offset
.LBB3_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel undefined_shuffle_source
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 20
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
		.amdhsa_next_free_vgpr 21
		.amdhsa_next_free_sgpr 8
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
.Lfunc_end3:
	.size	undefined_shuffle_source, .Lfunc_end3-undefined_shuffle_source
                                        ; -- End function
	.set undefined_shuffle_source.num_vgpr, 21
	.set undefined_shuffle_source.num_agpr, 0
	.set undefined_shuffle_source.numbered_sgpr, 8
	.set undefined_shuffle_source.num_named_barrier, 0
	.set undefined_shuffle_source.private_seg_size, 0
	.set undefined_shuffle_source.uses_vcc, 1
	.set undefined_shuffle_source.uses_flat_scratch, 0
	.set undefined_shuffle_source.has_dyn_sized_stack, 0
	.set undefined_shuffle_source.has_recursion, 0
	.set undefined_shuffle_source.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 104
; TotalNumSgprs: 10
; NumVgprs: 21
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 21
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
	.type	__hip_cuid_dc95fd57f962d330,@object ; @__hip_cuid_dc95fd57f962d330
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_dc95fd57f962d330
__hip_cuid_dc95fd57f962d330:
	.byte	0                               ; 0x0
	.size	__hip_cuid_dc95fd57f962d330, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_dc95fd57f962d330
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
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 12
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           ended_reader
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         ended_reader.kd
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
        .value_kind:     by_value
    .group_segment_fixed_size: 4
    .kernarg_segment_align: 8
    .kernarg_segment_size: 12
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           ended_writer
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         ended_writer.kd
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
        .value_kind:     by_value
    .group_segment_fixed_size: 8
    .kernarg_segment_align: 8
    .kernarg_segment_size: 12
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           metadata_eight_bytes
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         metadata_eight_bytes.kd
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
      - .offset:         16
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           undefined_shuffle_source
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         undefined_shuffle_source.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     21
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
