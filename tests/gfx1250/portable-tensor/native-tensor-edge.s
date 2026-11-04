	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	tensor_edge_4x4         ; -- Begin function tensor_edge_4x4
	.globl	tensor_edge_4x4
	.p2align	8
	.type	tensor_edge_4x4,@function
tensor_edge_4x4:                        ; @tensor_edge_4x4
; %bb.0:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB0_2
; %bb.1:
	v_mov_b32_e32 v2, 0
	;;#ASMSTART
	v_add_f16 v2, v2, v2
	;;#ASMEND
	ds_store_b16 v1, v2
.LBB0_2:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[8:11], s[0:1], 0x0
	s_mov_b32 s6, 0
	s_mov_b32 s12, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB0_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[18:19], s[8:9], 0x6c
	s_mov_b32 s1, 0x20000
	s_and_b32 s0, s19, 0x1ffffff
	s_mov_b32 s17, 32
	s_mov_b32 s16, 1
	s_or_b32 s19, s0, 0x80000000
	s_mov_b32 s5, 8
	s_mov_b32 s4, 2
	s_mov_b32 s0, 0x10000
	s_mov_b32 s2, s1
	s_mov_b32 s3, s1
	s_mov_b32 s7, s6
	s_mov_b32 s20, s6
	s_mov_b32 s21, s6
	s_mov_b32 s22, s6
	s_mov_b32 s23, s6
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[16:19], s[0:7], s[20:23], s[20:23]
.LBB0_4:
	s_or_b32 exec_lo, exec_lo, s12
	s_wait_xcnt 0x0
	s_mov_b32 s1, exec_lo
	s_wait_tensorcnt 0x0
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	v_cmpx_gt_u32_e32 4, v0
	s_cbranch_execz .LBB0_6
; %bb.5:
	ds_load_u16 v2, v1 offset:32
	v_dual_lshlrev_b32 v4, 2, v0 :: v_dual_bitop2_b32 v3, 1, v0 bitop3:0x40
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v3, 1, v3
	v_and_or_b32 v3, v4, 8, v3
	s_wait_dscnt 0x0
	ds_store_b16 v3, v2
.LBB0_6:
	s_or_b32 exec_lo, exec_lo, s1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_8
; %bb.7:
	ds_load_u16 v1, v1
	s_wait_dscnt 0x0
	s_wait_kmcnt 0x0
	global_store_b16 v0, v1, s[10:11] scale_offset
.LBB0_8:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_edge_4x4
		.amdhsa_group_segment_fixed_size 40
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 5
		.amdhsa_next_free_sgpr 24
		.amdhsa_named_barrier_count 0
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
.Lfunc_end0:
	.size	tensor_edge_4x4, .Lfunc_end0-tensor_edge_4x4
                                        ; -- End function
	.set tensor_edge_4x4.num_vgpr, 5
	.set tensor_edge_4x4.num_agpr, 0
	.set tensor_edge_4x4.numbered_sgpr, 24
	.set tensor_edge_4x4.num_named_barrier, 0
	.set tensor_edge_4x4.private_seg_size, 0
	.set tensor_edge_4x4.uses_vcc, 1
	.set tensor_edge_4x4.uses_flat_scratch, 0
	.set tensor_edge_4x4.has_dyn_sized_stack, 0
	.set tensor_edge_4x4.has_recursion, 0
	.set tensor_edge_4x4.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 300
; TotalNumSgprs: 26
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 40 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 5
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
	.type	__hip_cuid_946a0dc7310592fa,@object ; @__hip_cuid_946a0dc7310592fa
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_946a0dc7310592fa
__hip_cuid_946a0dc7310592fa:
	.byte	0                               ; 0x0
	.size	__hip_cuid_946a0dc7310592fa, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_946a0dc7310592fa
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
    .group_segment_fixed_size: 40
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_edge_4x4
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_edge_4x4.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     5
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
