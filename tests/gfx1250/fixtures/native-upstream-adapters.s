	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	bf16_m16n8k16_fragment_adapter ; -- Begin function bf16_m16n8k16_fragment_adapter
	.globl	bf16_m16n8k16_fragment_adapter
	.p2align	8
	.type	bf16_m16n8k16_fragment_adapter,@function
bf16_m16n8k16_fragment_adapter:         ; @bf16_m16n8k16_fragment_adapter
; %bb.0:
	s_load_b256 s[4:11], s[0:1], 0x0
	v_dual_mov_b32 v18, 0 :: v_dual_lshlrev_b32 v2, 2, v0
	v_dual_lshrrev_b32 v3, 2, v0 :: v_dual_bitop2_b32 v1, 15, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v19, v18 :: v_dual_lshrrev_b32 v4, 3, v0
	v_and_b32_e32 v2, 28, v2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v20, v18 :: v_dual_bitop2_b32 v26, 2, v3 bitop3:0x40
	v_dual_mov_b32 v21, v18 :: v_dual_bitop2_b32 v4, 2, v4 bitop3:0x40
	v_dual_mov_b32 v22, v18 :: v_dual_mov_b32 v23, v18
	v_dual_mov_b32 v24, v18 :: v_dual_mov_b32 v25, v18
	v_lshlrev_b32_e32 v28, 3, v2
	s_delay_alu instid0(VALU_DEP_4)
	v_lshl_or_b32 v27, v1, 4, v4
	v_and_b32_e32 v29, 4, v3
	v_mov_b64_e32 v[10:11], v[18:19]
	v_mov_b64_e32 v[2:3], v[18:19]
	v_mov_b64_e32 v[12:13], v[20:21]
	v_mov_b64_e32 v[14:15], v[22:23]
	v_mov_b64_e32 v[16:17], v[24:25]
	v_mov_b64_e32 v[4:5], v[20:21]
	v_mov_b64_e32 v[6:7], v[22:23]
	v_mov_b64_e32 v[8:9], v[24:25]
	s_wait_xcnt 0x0
	v_cmp_gt_u32_e64 s0, 32, v0
	v_cmp_gt_u32_e32 vcc_lo, 8, v1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_4
; %bb.1:
	v_or3_b32 v2, v28, v29, v26
	v_dual_mov_b32 v19, v18 :: v_dual_mov_b32 v20, v18
	v_dual_mov_b32 v21, v18 :: v_dual_mov_b32 v22, v18
	s_wait_kmcnt 0x0
	global_load_u16 v2, v2, s[4:5] scale_offset
	v_dual_mov_b32 v23, v18 :: v_dual_mov_b32 v24, v18
	v_mov_b32_e32 v25, v18
	v_mov_b64_e32 v[10:11], v[18:19]
	v_mov_b64_e32 v[12:13], v[20:21]
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_mov_b64_e32 v[14:15], v[22:23]
	v_mov_b64_e32 v[16:17], v[24:25]
	s_wait_loadcnt 0x0
	v_perm_b32 v2, 0, v2, 0x5040100
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_3
; %bb.2:
	global_load_u16 v3, v27, s[6:7] scale_offset
	v_dual_mov_b32 v11, v18 :: v_dual_mov_b32 v12, v18
	v_dual_mov_b32 v13, v18 :: v_dual_mov_b32 v14, v18
	v_dual_mov_b32 v15, v18 :: v_dual_mov_b32 v16, v18
	v_mov_b32_e32 v17, v18
	s_wait_loadcnt 0x0
	v_perm_b32 v10, 0, v3, 0x5040100
.LBB0_3:
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_mov_b32 v3, v18 :: v_dual_mov_b32 v4, v18
	v_dual_mov_b32 v5, v18 :: v_dual_mov_b32 v6, v18
	v_dual_mov_b32 v7, v18 :: v_dual_mov_b32 v8, v18
	v_mov_b32_e32 v9, v18
.LBB0_4:
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_8
; %bb.5:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:2 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v2, v18, v2, 0x5040100
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_7
; %bb.6:
	global_load_u16 v18, v27, s[6:7] offset:2 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v10, v18, v10, 0x5040100
.LBB0_7:
	s_or_b32 exec_lo, exec_lo, s2
.LBB0_8:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_12
; %bb.9:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:16 scale_offset
	s_wait_loadcnt 0x0
	v_bfi_b32 v3, 0xffff, v18, v3
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_11
; %bb.10:
	global_load_u16 v18, v27, s[6:7] offset:8 scale_offset
	s_wait_loadcnt 0x0
	v_bfi_b32 v11, 0xffff, v18, v11
.LBB0_11:
	s_or_b32 exec_lo, exec_lo, s2
.LBB0_12:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_16
; %bb.13:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:18 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v3, v18, v3, 0x5040100
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_15
; %bb.14:
	global_load_u16 v18, v27, s[6:7] offset:10 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v11, v18, v11, 0x5040100
.LBB0_15:
	s_or_b32 exec_lo, exec_lo, s2
.LBB0_16:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_20
; %bb.17:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:32 scale_offset
	s_wait_loadcnt 0x0
	v_bfi_b32 v4, 0xffff, v18, v4
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_19
; %bb.18:
	global_load_u16 v18, v27, s[6:7] offset:16 scale_offset
	s_wait_loadcnt 0x0
	v_bfi_b32 v12, 0xffff, v18, v12
.LBB0_19:
	s_or_b32 exec_lo, exec_lo, s2
.LBB0_20:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_24
; %bb.21:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:34 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v4, v18, v4, 0x5040100
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_23
; %bb.22:
	global_load_u16 v18, v27, s[6:7] offset:18 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v12, v18, v12, 0x5040100
.LBB0_23:
	s_or_b32 exec_lo, exec_lo, s2
.LBB0_24:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_28
; %bb.25:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:48 scale_offset
	s_wait_loadcnt 0x0
	v_bfi_b32 v5, 0xffff, v18, v5
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_27
; %bb.26:
	global_load_u16 v18, v27, s[6:7] offset:24 scale_offset
	s_wait_loadcnt 0x0
	v_bfi_b32 v13, 0xffff, v18, v13
.LBB0_27:
	s_or_b32 exec_lo, exec_lo, s2
.LBB0_28:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_32
; %bb.29:
	v_or3_b32 v18, v28, v29, v26
	s_wait_kmcnt 0x0
	global_load_u16 v18, v18, s[4:5] offset:50 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v5, v18, v5, 0x5040100
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_31
; %bb.30:
	global_load_u16 v18, v27, s[6:7] offset:26 scale_offset
	s_wait_loadcnt 0x0
	v_perm_b32 v13, v18, v13, 0x5040100
.LBB0_31:
	s_or_b32 exec_lo, exec_lo, s0
.LBB0_32:
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	s_or_b32 exec_lo, exec_lo, s1
	v_dual_lshlrev_b32 v1, 2, v1 :: v_dual_lshlrev_b32 v18, 5, v0
	s_mov_b32 s0, exec_lo
	v_and_or_b32 v1, 0x200, v18, v1
	v_wmma_f32_16x16x32_bf16 v[18:25], v[2:9], v[10:17], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v2, 0x1c0, v1
	s_wait_kmcnt 0x0
	s_clause 0x7
	global_store_b32 v1, v18, s[8:9]
	global_store_b32 v1, v19, s[8:9] offset:64
	global_store_b32 v1, v20, s[8:9] offset:128
	global_store_b32 v1, v21, s[8:9] offset:192
	global_store_b32 v1, v22, s[8:9] offset:256
	global_store_b32 v1, v23, s[8:9] offset:320
	global_store_b32 v1, v24, s[8:9] offset:384
	global_store_b32 v2, v25, s[8:9]
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 2, v0
	s_cbranch_execz .LBB0_34
; %bb.33:
	global_store_b32 v0, v18, s[10:11] scale_offset
.LBB0_34:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_and_b32_e32 v1, 30, v0
	s_mov_b32 s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_eq_u32_e32 16, v1
	s_cbranch_execz .LBB0_36
; %bb.35:
	global_store_b32 v0, v18, s[10:11] offset:-56 scale_offset
.LBB0_36:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel bf16_m16n8k16_fragment_adapter
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
		.amdhsa_next_free_vgpr 30
		.amdhsa_next_free_sgpr 12
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 10
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
	.size	bf16_m16n8k16_fragment_adapter, .Lfunc_end0-bf16_m16n8k16_fragment_adapter
                                        ; -- End function
	.set bf16_m16n8k16_fragment_adapter.num_vgpr, 30
	.set bf16_m16n8k16_fragment_adapter.num_agpr, 0
	.set bf16_m16n8k16_fragment_adapter.numbered_sgpr, 12
	.set bf16_m16n8k16_fragment_adapter.num_named_barrier, 0
	.set bf16_m16n8k16_fragment_adapter.private_seg_size, 0
	.set bf16_m16n8k16_fragment_adapter.uses_vcc, 1
	.set bf16_m16n8k16_fragment_adapter.uses_flat_scratch, 0
	.set bf16_m16n8k16_fragment_adapter.has_dyn_sized_stack, 0
	.set bf16_m16n8k16_fragment_adapter.has_recursion, 0
	.set bf16_m16n8k16_fragment_adapter.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1260
; TotalNumSgprs: 14
; NumVgprs: 30
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 30
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
	.protected	high64_division_projection ; -- Begin function high64_division_projection
	.globl	high64_division_projection
	.p2align	8
	.type	high64_division_projection,@function
high64_division_projection:             ; @high64_division_projection
; %bb.0:
	s_load_b128 s[4:7], s[0:1], 0x0
	s_mov_b64 s[8:9], 0xffffffff
	s_mov_b32 s3, 0
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x10
	s_mov_b32 s11, s3
	s_mov_b32 s13, s3
	s_wait_kmcnt 0x0
	s_mov_b32 s2, s4
	s_and_b64 s[8:9], s[6:7], s[8:9]
	s_mov_b32 s10, s7
	s_mul_u64 s[6:7], s[8:9], s[2:3]
	s_mul_u64 s[14:15], s[10:11], s[2:3]
	s_mov_b32 s2, s7
	s_mov_b32 s12, s5
	s_add_nc_u64 s[4:5], s[14:15], s[2:3]
	s_mul_u64 s[6:7], s[8:9], s[12:13]
	s_mov_b32 s2, s5
	s_mov_b32 s5, s3
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	s_add_nc_u64 s[4:5], s[6:7], s[4:5]
	s_mov_b32 s7, s3
	s_mov_b32 s6, s5
	s_mul_u64 s[4:5], s[10:11], s[12:13]
	s_add_nc_u64 s[2:3], s[2:3], s[6:7]
	s_add_nc_u64 s[2:3], s[4:5], s[2:3]
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_lshr_b64 s[2:3], s[2:3], 1
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, s2
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel high64_division_projection
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
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
		.amdhsa_next_free_sgpr 16
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
.Lfunc_end1:
	.size	high64_division_projection, .Lfunc_end1-high64_division_projection
                                        ; -- End function
	.set high64_division_projection.num_vgpr, 2
	.set high64_division_projection.num_agpr, 0
	.set high64_division_projection.numbered_sgpr, 16
	.set high64_division_projection.num_named_barrier, 0
	.set high64_division_projection.private_seg_size, 0
	.set high64_division_projection.uses_vcc, 0
	.set high64_division_projection.uses_flat_scratch, 0
	.set high64_division_projection.has_dyn_sized_stack, 0
	.set high64_division_projection.has_recursion, 0
	.set high64_division_projection.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 148
; TotalNumSgprs: 16
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 16
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_9195e374296c6d7,@object ; @__hip_cuid_9195e374296c6d7
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_9195e374296c6d7
__hip_cuid_9195e374296c6d7:
	.byte	0                               ; 0x0
	.size	__hip_cuid_9195e374296c6d7, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_9195e374296c6d7
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
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           bf16_m16n8k16_fragment_adapter
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         bf16_m16n8k16_fragment_adapter.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     30
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           8
        .value_kind:     by_value
      - .offset:         8
        .size:           8
        .value_kind:     by_value
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1
    .name:           high64_division_projection
    .private_segment_fixed_size: 0
    .sgpr_count:     16
    .sgpr_spill_count: 0
    .symbol:         high64_division_projection.kd
    .uniform_work_group_size: 1
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
