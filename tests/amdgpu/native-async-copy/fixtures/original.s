	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.section	.text._ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,"axG",@progbits,_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,comdat
	.globl	_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_ ; -- Begin function _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
	.p2align	8
	.type	_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,@function
_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_: ; @_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
; %bb.0:
	s_load_b64 s[4:5], s[0:1], 0x10
	s_cmp_lg_u32 0, -1
	s_cselect_b32 s2, 0, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b64 s[2:3], s[2:3], 15
	s_sub_co_i32 s6, 16, s2
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_lshr_b32 s6, s6, 2
	s_cmp_lg_u64 s[2:3], 0
	s_cselect_b32 s2, s6, 0
	s_lshl_b32 s2, s2, 2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_co_i32 s2, s2, 0
	s_mov_b32 s3, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_xor_b32 s6, exec_lo, s3
; %bb.1:
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s9
; %bb.2:
	s_or_saveexec_b32 s6, s6
	v_mov_b64_e32 v[2:3], s[2:3]
	v_lshlrev_b32_e32 v1, 4, v0
	s_xor_b32 exec_lo, exec_lo, s6
	s_cbranch_execz .LBB0_4
; %bb.3:
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x0
	v_and_b32_e32 v2, 0x1e0, v1
	v_mov_b32_e32 v3, 0
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	s_mov_b32 s3, s9
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[4:5], s[0:1], v[2:3]
	v_and_b32_e32 v2, 16, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u64_e32 v[2:3], v[4:5], v[2:3]
	v_add_nc_u32_e32 v4, s2, v1
	global_load_async_to_lds_b128 v4, v[2:3], off
	v_mov_b64_e32 v[2:3], s[2:3]
.LBB0_4:
	s_or_b32 exec_lo, exec_lo, s6
	v_dual_lshlrev_b32 v3, 5, v0 :: v_dual_lshrrev_b32 v4, 1, v0
	; wave barrier
	s_mov_b32 s7, 0x20000
	s_movk_i32 s6, 0x200
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_bitop3_b32 v3, v3, 0x1e8, v4 bitop3:0xc8
	v_dual_lshrrev_b32 v0, 2, v0 :: v_dual_add_nc_u32 v5, v3, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_bitop3_b32 v0, v0, 0xf4, v1 bitop3:0xc8
	v_dual_add_nc_u32 v6, 16, v5 :: v_dual_lshlrev_b32 v4, 1, v0
	;;#ASMSTART
	ds_read_b64 v[0:1], v5 offset:0

	;;#ASMEND
	;;#ASMSTART
	ds_read_b64 v[2:3], v6 offset:0

	;;#ASMEND
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	; wave barrier
	;;#ASMSTART
	ds_write_b64 v5, v[0:1] offset:0

	;;#ASMEND
	;;#ASMSTART
	ds_write_b64 v6, v[2:3] offset:0

	;;#ASMEND
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	; wave barrier
	s_wait_kmcnt 0x0
	s_clause 0x1
	buffer_store_b64 v[0:1], v4, s[4:7], null offen
	buffer_store_b64 v[2:3], v4, s[4:7], null offen offset:16
	;;#ASMSTART
	s_wait_storecnt 0
	;;#ASMEND
	; wave barrier
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
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
		.amdhsa_next_free_vgpr 7
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
	.section	.text._ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,"axG",@progbits,_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,comdat
.Lfunc_end0:
	.size	_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_, .Lfunc_end0-_ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
                                        ; -- End function
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.num_vgpr, 7
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.num_agpr, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.numbered_sgpr, 10
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.num_named_barrier, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.private_seg_size, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.uses_vcc, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.uses_flat_scratch, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.has_dyn_sized_stack, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.has_recursion, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 296
; TotalNumSgprs: 10
; NumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.section	.text._ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,"axG",@progbits,_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,comdat
	.globl	_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_ ; -- Begin function _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
	.p2align	8
	.type	_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,@function
_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_: ; @_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
; %bb.0:
	s_load_b64 s[4:5], s[0:1], 0x10
	s_cmp_lg_u32 0, -1
	s_cselect_b32 s2, 0, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b64 s[2:3], s[2:3], 15
	s_sub_co_i32 s6, 16, s2
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_lshr_b32 s6, s6, 2
	s_cmp_lg_u64 s[2:3], 0
	s_cselect_b32 s2, s6, 0
	s_lshl_b32 s2, s2, 2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_co_i32 s2, s2, 0
	s_mov_b32 s3, exec_lo
	v_cmpx_lt_u32_e32 31, v0
	s_xor_b32 s6, exec_lo, s3
; %bb.1:
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s9
; %bb.2:
	s_or_saveexec_b32 s6, s6
	v_mov_b64_e32 v[2:3], s[2:3]
	v_lshlrev_b32_e32 v1, 4, v0
	s_xor_b32 exec_lo, exec_lo, s6
	s_cbranch_execz .LBB1_4
; %bb.3:
	s_wait_xcnt 0x0
	s_load_b64 s[0:1], s[0:1], 0x0
	v_and_b32_e32 v2, 0x1e0, v1
	v_mov_b32_e32 v3, 0
	s_mov_b64 s[8:9], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	s_mov_b32 s3, s9
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[4:5], s[0:1], v[2:3]
	v_and_b32_e32 v2, 16, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_add_nc_u64_e32 v[2:3], v[4:5], v[2:3]
	v_add_nc_u32_e32 v4, s2, v1
	global_load_async_to_lds_b128 v4, v[2:3], off
	v_mov_b64_e32 v[2:3], s[2:3]
.LBB1_4:
	s_or_b32 exec_lo, exec_lo, s6
	v_dual_lshlrev_b32 v3, 5, v0 :: v_dual_lshrrev_b32 v4, 1, v0
	; wave barrier
	s_mov_b32 s7, 0x20000
	s_movk_i32 s6, 0x200
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_bitop3_b32 v3, v3, 0x1e8, v4 bitop3:0xc8
	v_dual_lshrrev_b32 v0, 2, v0 :: v_dual_add_nc_u32 v5, v3, v2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_bitop3_b32 v0, v0, 0xf4, v1 bitop3:0xc8
	v_dual_add_nc_u32 v6, 16, v5 :: v_dual_lshlrev_b32 v4, 1, v0
	;;#ASMSTART
	ds_read_b64 v[0:1], v5 offset:0

	;;#ASMEND
	;;#ASMSTART
	ds_read_b64 v[2:3], v6 offset:0

	;;#ASMEND
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	; wave barrier
	;;#ASMSTART
	ds_write_b64 v5, v[0:1] offset:0

	;;#ASMEND
	;;#ASMSTART
	ds_write_b64 v6, v[2:3] offset:0

	;;#ASMEND
	;;#ASMSTART
	s_wait_dscnt 0
	;;#ASMEND
	; wave barrier
	s_wait_kmcnt 0x0
	s_clause 0x1
	buffer_store_b64 v[0:1], v4, s[4:7], null offen
	buffer_store_b64 v[2:3], v4, s[4:7], null offen offset:16
	;;#ASMSTART
	s_wait_storecnt 0
	;;#ASMEND
	; wave barrier
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
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
		.amdhsa_next_free_vgpr 7
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
	.section	.text._ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,"axG",@progbits,_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_,comdat
.Lfunc_end1:
	.size	_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_, .Lfunc_end1-_ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
                                        ; -- End function
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.num_vgpr, 7
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.num_agpr, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.numbered_sgpr, 10
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.num_named_barrier, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.private_seg_size, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.uses_vcc, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.uses_flat_scratch, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.has_dyn_sized_stack, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.has_recursion, 0
	.set _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 296
; TotalNumSgprs: 10
; NumVgprs: 7
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 10
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
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_895377c00841e2f7,@object ; @__hip_cuid_895377c00841e2f7
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_895377c00841e2f7
__hip_cuid_895377c00841e2f7:
	.byte	0                               ; 0x0
	.size	__hip_cuid_895377c00841e2f7, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __shm
	.addrsig_sym __hip_cuid_895377c00841e2f7
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .offset:         0
        .size:           16
        .value_kind:     by_value
      - .offset:         16
        .size:           16
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         _ZL17global_wrapper_2dI20sharedreg_load_storeI14__hip_bfloat16EN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .offset:         0
        .size:           16
        .value_kind:     by_value
      - .offset:         16
        .size:           16
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         _ZL17global_wrapper_2dI20sharedreg_load_storeI6__halfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS4_8st_shape8st_16x16ES1_Li1ELi1ELi1ENS3_2glIS1_Li1ELi1ELi16ELi16ENS4_9gl_layout9row_majorEEEJNS4_9rt_layout3rowEEEvT6_SG_.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     7
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
