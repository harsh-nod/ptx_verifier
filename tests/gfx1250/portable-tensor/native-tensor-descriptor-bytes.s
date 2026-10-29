	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	tensor_descriptor_bytes_ordered ; -- Begin function tensor_descriptor_bytes_ordered
	.globl	tensor_descriptor_bytes_ordered
	.p2align	8
	.type	tensor_descriptor_bytes_ordered,@function
tensor_descriptor_bytes_ordered:        ; @tensor_descriptor_bytes_ordered
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s9 :: v_dual_lshlrev_b32 v2, 2, v0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_wait_kmcnt 0x0
	s_mov_b32 s4, 0
	s_mov_b32 s8, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_4
; %bb.3:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 4
	s_mov_b32 s5, s1
	flat_load_b32 v2, v1, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 8
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 12
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:8 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 16
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:12 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 20
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 24
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:20 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 28
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:24 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 32
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:28 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 36
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:32 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 40
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:36 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 44
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:40 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 48
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:44 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 52
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:48 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 56
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:52 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 60
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:56 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 64
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:60 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x44
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:64 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x48
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:68 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x4c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:72 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x50
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:76 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x54
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:80 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x58
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:84 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x5c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:88 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x60
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:92 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x64
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:96 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x68
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:100 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x6c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:104 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x70
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:108 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x74
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:112 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x78
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:116 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x7c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:120 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:124 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB0_6
; %bb.5:
	v_subrev_nc_u32_e32 v0, 32, v0
	flat_load_b32 v1, v0, s[6:7] scale_offset scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] scale_offset
.LBB0_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_descriptor_bytes_ordered
		.amdhsa_group_segment_fixed_size 128
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 10
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 13
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
	.size	tensor_descriptor_bytes_ordered, .Lfunc_end0-tensor_descriptor_bytes_ordered
                                        ; -- End function
	.set tensor_descriptor_bytes_ordered.num_vgpr, 4
	.set tensor_descriptor_bytes_ordered.num_agpr, 0
	.set tensor_descriptor_bytes_ordered.numbered_sgpr, 10
	.set tensor_descriptor_bytes_ordered.num_named_barrier, 0
	.set tensor_descriptor_bytes_ordered.private_seg_size, 0
	.set tensor_descriptor_bytes_ordered.uses_vcc, 0
	.set tensor_descriptor_bytes_ordered.uses_flat_scratch, 0
	.set tensor_descriptor_bytes_ordered.has_dyn_sized_stack, 0
	.set tensor_descriptor_bytes_ordered.has_recursion, 0
	.set tensor_descriptor_bytes_ordered.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1596
; TotalNumSgprs: 10
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.protected	tensor_descriptor_bytes_replace_race ; -- Begin function tensor_descriptor_bytes_replace_race
	.globl	tensor_descriptor_bytes_replace_race
	.p2align	8
	.type	tensor_descriptor_bytes_replace_race,@function
tensor_descriptor_bytes_replace_race:   ; @tensor_descriptor_bytes_replace_race
; %bb.0:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0x0
	s_load_b64 s[2:3], s[0:1], 0x10
	s_wait_xcnt 0x0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e32 32, v0
	s_cbranch_execz .LBB1_2
; %bb.1:
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s9 :: v_dual_lshlrev_b32 v2, 2, v0
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[4:5] scale_offset
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s0, exec_lo
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_lt_i32_e32 31, v0
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB1_6
; %bb.3:
	s_mov_b32 s1, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB1_5
; %bb.4:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[8:9], src_shared_base
	s_mov_b32 s8, 0
	s_wait_kmcnt 0x0
	global_load_b32 v2, v1, s[4:5] offset:128
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[8:9] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_b32 v2, v1, s[4:5] offset:132
	s_wait_loadcnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_5:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
.LBB1_6:
	s_and_not1_saveexec_b32 s8, s0
	s_cbranch_execz .LBB1_10
; %bb.7:
	s_wait_kmcnt 0x0
	s_mov_b32 s4, 0
	s_mov_b32 s9, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB1_9
; %bb.8:
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[0:1], src_shared_base
	s_mov_b32 s0, 4
	s_mov_b32 s5, s1
	flat_load_b32 v2, v1, s[4:5] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 8
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 12
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:8 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 16
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:12 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 20
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:16 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 24
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:20 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 28
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:24 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 32
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:28 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 36
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:32 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 40
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:36 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 44
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:40 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 48
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:44 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 52
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:48 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 56
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:52 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 60
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:56 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_mov_b32 s0, 64
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:60 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x44
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:64 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x48
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:68 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x4c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:72 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x50
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:76 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x54
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:80 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x58
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:84 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x5c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:88 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x60
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:92 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x64
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:96 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x68
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:100 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x6c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:104 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x70
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:108 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x74
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:112 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x78
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:116 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_movk_i32 s0, 0x7c
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:120 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_load_b32 v2, v1, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v2, 0, v2
	;;#ASMEND
	flat_store_b32 v1, v2, s[6:7] offset:124 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_9:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s9
.LBB1_10:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s8
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_cbranch_execz .LBB1_12
; %bb.11:
	v_subrev_nc_u32_e32 v0, 32, v0
	s_wait_kmcnt 0x0
	flat_load_b32 v1, v0, s[6:7] scale_offset scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_nc_u32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[2:3] scale_offset
.LBB1_12:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_descriptor_bytes_replace_race
		.amdhsa_group_segment_fixed_size 128
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
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 10
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 14
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
	.size	tensor_descriptor_bytes_replace_race, .Lfunc_end1-tensor_descriptor_bytes_replace_race
                                        ; -- End function
	.set tensor_descriptor_bytes_replace_race.num_vgpr, 4
	.set tensor_descriptor_bytes_replace_race.num_agpr, 0
	.set tensor_descriptor_bytes_replace_race.numbered_sgpr, 10
	.set tensor_descriptor_bytes_replace_race.num_named_barrier, 0
	.set tensor_descriptor_bytes_replace_race.private_seg_size, 0
	.set tensor_descriptor_bytes_replace_race.uses_vcc, 0
	.set tensor_descriptor_bytes_replace_race.uses_flat_scratch, 0
	.set tensor_descriptor_bytes_replace_race.has_dyn_sized_stack, 0
	.set tensor_descriptor_bytes_replace_race.has_recursion, 0
	.set tensor_descriptor_bytes_replace_race.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1736
; TotalNumSgprs: 10
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 128 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_6a4beb843dc9cfe9,@object ; @__hip_cuid_6a4beb843dc9cfe9
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_6a4beb843dc9cfe9
__hip_cuid_6a4beb843dc9cfe9:
	.byte	0                               ; 0x0
	.size	__hip_cuid_6a4beb843dc9cfe9, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_6a4beb843dc9cfe9
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
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_descriptor_bytes_ordered
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         tensor_descriptor_bytes_ordered.kd
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
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_descriptor_bytes_replace_race
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         tensor_descriptor_bytes_replace_race.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
