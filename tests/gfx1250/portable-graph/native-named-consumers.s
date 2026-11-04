	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.globl	named_independent_consumers     ; -- Begin function named_independent_consumers
	.p2align	8
	.type	named_independent_consumers,@function
named_independent_consumers:            ; @named_independent_consumers
; %bb.0:                                ; %entry
	v_and_b32_e32 v0, 0x3ff, v0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_lt_u32_e32 vcc_lo, 31, v0
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_2
; %bb.1:                                ; %init
	s_mov_b32 m0, 0x10002
	s_barrier_init m0 
	s_mov_b32 m0, 0x20001
	s_barrier_init m0 
.LBB0_2:                                ; %choose
	s_or_b32 exec_lo, exec_lo, s1
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB0_4
; %bb.3:                                ; %joinfull
	s_mov_b32 m0, 2
	s_barrier_join m0 
.LBB0_4:                                ; %Flow7
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB0_6
; %bb.5:                                ; %joinempty
	s_mov_b32 m0, 1
	s_barrier_join m0 
.LBB0_6:                                ; %rendezvous
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b128 s[8:11], s[4:5], 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s1, exec_lo, s0
	s_cbranch_execnz .LBB0_9
; %bb.7:                                ; %Flow5
	s_and_not1_saveexec_b32 s0, s1
	s_cbranch_execnz .LBB0_16
.LBB0_8:                                ; %end
	s_endpgm
.LBB0_9:                                ; %consume0
	v_dual_lshrrev_b32 v1, 5, v0 :: v_dual_bitop2_b32 v2, 31, v0 bitop3:0x40
	s_barrier_wait 2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_cmp_eq_u32_e32 vcc_lo, 0, v2
	v_lshl_add_u32 v0, v1, 1, -2
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_11
; %bb.10:                               ; %read0
	v_mov_b32_e32 v2, 0
	ds_load_b32 v2, v2
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b32 v0, v2, s[10:11] scale_offset
.LBB0_11:                               ; %releaseempty
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_load_b32 s0, s[4:5], 0x10
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 2
	s_mov_b32 s2, exec_lo
	s_barrier_join m0 
	s_wait_kmcnt 0x0
	v_cmpx_ne_u32_e64 s0, v1
	s_cbranch_execz .LBB0_13
; %bb.12:                               ; %signalempty
	s_mov_b32 m0, 1
	s_barrier_signal m0 
.LBB0_13:                               ; %consume1
	s_or_b32 exec_lo, exec_lo, s2
	s_barrier_wait 2
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_15
; %bb.14:                               ; %read1
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v0, 1, v0
	ds_load_b32 v1, v1
	s_wait_dscnt 0x0
	global_store_b32 v0, v1, s[10:11] scale_offset
.LBB0_15:                               ; %Flow
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
                                        ; implicit-def: $vgpr0
	s_and_not1_saveexec_b32 s0, s1
	s_cbranch_execz .LBB0_8
.LBB0_16:                               ; %produce0
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_18
; %bb.17:                               ; %write0
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[8:9]
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB0_18:                               ; %signal0
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_mov_b32 m0, 2
	s_barrier_signal m0 
	s_barrier_wait 1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_20
; %bb.19:                               ; %write1
	v_mov_b32_e32 v0, 0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[8:9] offset:4
	s_wait_loadcnt 0x0
	ds_store_b32 v0, v1
.LBB0_20:                               ; %signal1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	s_barrier_signal m0 
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel named_independent_consumers
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
		.amdhsa_next_free_vgpr 65
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
	.size	named_independent_consumers, .Lfunc_end0-named_independent_consumers
                                        ; -- End function
	.set named_independent_consumers.num_vgpr, 3
	.set named_independent_consumers.num_agpr, 0
	.set named_independent_consumers.numbered_sgpr, 12
	.set named_independent_consumers.num_named_barrier, 2
	.set named_independent_consumers.private_seg_size, 0
	.set named_independent_consumers.uses_vcc, 1
	.set named_independent_consumers.uses_flat_scratch, 0
	.set named_independent_consumers.has_dyn_sized_stack, 0
	.set named_independent_consumers.has_recursion, 0
	.set named_independent_consumers.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 460
; TotalNumSgprs: 14
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 14
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
      - .name:           skip_consumer
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
    .max_flat_workgroup_size: 96
    .name:           named_independent_consumers
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         named_independent_consumers.kd
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
