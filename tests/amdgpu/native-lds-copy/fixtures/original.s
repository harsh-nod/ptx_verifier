	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.section	.text._ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_,"axG",@progbits,_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_,comdat
	.globl	_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_ ; -- Begin function _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_
	.p2align	8
	.type	_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_,@function
_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_: ; @_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_cmp_lg_u32 0, -1
	s_cselect_b32 s2, s3, 0
	s_cselect_b32 s3, 0, 0
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	s_and_b32 s0, s3, 63
	s_and_b32 s6, s3, 0xffffffc0
	s_add_u32 s6, s6, 64
	s_mov_b32 s1, 0
	s_addc_u32 s7, s2, 0
	s_cmp_eq_u64 s[0:1], 0
	s_cselect_b32 s0, s3, s6
	v_lshlrev_b32_e32 v1, 2, v0
	s_cselect_b32 s1, s2, s7
	s_mov_b32 s7, 0x110000
	s_movk_i32 s6, 0x100
	v_and_b32_e32 v1, 0xfc, v1
	s_mov_b32 m0, s0
	v_and_b32_e32 v0, 63, v0
	s_waitcnt lgkmcnt(0)
	buffer_load_dword v1, s[4:7], 0 offen lds
	v_lshlrev_b32_e32 v0, 2, v0
	v_mov_b32_e32 v1, 0
	v_lshl_add_u64 v[2:3], s[0:1], 0, v[0:1]
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	s_barrier
	flat_load_dword v1, v[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	global_store_dword v0, v1, s[8:9]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_
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
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 10
		.amdhsa_accum_offset 4
		.amdhsa_reserve_vcc 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.section	.text._ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_,"axG",@progbits,_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_,comdat
.Lfunc_end0:
	.size	_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_, .Lfunc_end0-_ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_
                                        ; -- End function
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.num_vgpr, 4
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.num_agpr, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.numbered_sgpr, 10
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.num_named_barrier, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.private_seg_size, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.uses_vcc, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.uses_flat_scratch, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.has_dyn_sized_stack, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.has_recursion, 0
	.set _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 160
; TotalNumSgprs: 16
; NumVgprs: 4
; NumAgprs: 0
; TotalNumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 16
; NumVGPRsForWavesPerEU: 4
; AccumOffset: 4
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 0
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_e5b86aac605b32d2,@object ; @__hip_cuid_e5b86aac605b32d2
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_e5b86aac605b32d2
__hip_cuid_e5b86aac605b32d2:
	.byte	0                               ; 0x0
	.size	__hip_cuid_e5b86aac605b32d2, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __shm
	.addrsig_sym __hip_cuid_e5b86aac605b32d2
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
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
    .max_flat_workgroup_size: 1024
    .name:           _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_
    .private_segment_fixed_size: 0
    .sgpr_count:     16
    .sgpr_spill_count: 0
    .symbol:         _ZL17global_wrapper_1dI21shared_vec_load_storeIfEN7kittens5ducks8rt_shape8rt_shapeILi16ELi16ELi4EEENS3_8st_shape8st_16x16EfLi4ELi1ETkNS3_2gl3allENS2_2glIfLi1ELi1ELi1ELi64EJEEEJEEvT5_SC_.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
