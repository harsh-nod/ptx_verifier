	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	tensor_roundtrip        ; -- Begin function tensor_roundtrip
	.globl	tensor_roundtrip
	.p2align	8
	.type	tensor_roundtrip,@function
tensor_roundtrip:                       ; @tensor_roundtrip
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 s5, 0
	s_and_saveexec_b32 s8, vcc_lo
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_wait_kmcnt 0x0
	s_and_b32 s6, s1, 0x1ffffff
	s_mov_b32 s4, 1
	s_mov_b32 s13, 0x400000
	s_or_b32 s7, s6, 0x80000000
	s_mov_b32 s6, s0
	s_mov_b32 s17, 64
	s_mov_b32 s14, 0x10000
	s_mov_b32 s12, 0x20000
	s_mov_b32 s15, s13
	s_mov_b32 s16, s4
	s_mov_b32 s18, s5
	s_mov_b32 s19, s5
	s_mov_b32 s20, s5
	s_mov_b32 s21, s5
	s_mov_b32 s22, s5
	s_mov_b32 s23, s5
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]
.LBB0_2:
	s_or_b32 exec_lo, exec_lo, s8
	v_lshlrev_b32_e32 v0, 2, v0
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	v_add_f32_e32 v1, 1.0, v1
	ds_store_b32 v0, v1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB0_4
; %bb.3:
	s_wait_kmcnt 0x0
	s_and_b32 s5, s3, 0x1ffffff
	s_mov_b32 s17, 0
	s_mov_b32 s16, 1
	s_mov_b32 s9, 0x400000
	s_or_b32 s19, s5, 0x80000000
	s_mov_b32 s18, s2
	s_mov_b32 s13, 64
	s_mov_b32 s10, 0x10000
	s_mov_b32 s8, 0x20000
	s_mov_b32 s11, s9
	s_mov_b32 s12, s16
	s_mov_b32 s14, s17
	s_mov_b32 s15, s17
	s_mov_b32 s20, s17
	s_mov_b32 s21, s17
	s_mov_b32 s22, s17
	s_mov_b32 s23, s17
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_store_from_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB0_4:
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB0_6
; %bb.5:
	s_wait_kmcnt 0x0
	s_add_nc_u64 s[18:19], s[0:1], 0x100
	s_mov_b32 s17, 0
	s_and_b32 s0, s19, 0x1ffffff
	s_mov_b32 s16, 1
	s_mov_b32 s9, 0x400000
	s_or_b32 s19, s0, 0x80000000
	s_mov_b32 s13, 64
	s_mov_b32 s10, 0x10000
	s_mov_b32 s8, 0x20000
	s_mov_b32 s11, s9
	s_mov_b32 s12, s16
	s_mov_b32 s14, s17
	s_mov_b32 s15, s17
	s_mov_b32 s20, s17
	s_mov_b32 s21, s17
	s_mov_b32 s22, s17
	s_mov_b32 s23, s17
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_load_to_lds s[16:19], s[8:15], s[20:23], s[20:23]
.LBB0_6:
	s_or_b32 exec_lo, exec_lo, s4
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	ds_load_b32 v1, v0
	s_wait_dscnt 0x0
	v_add_f32_e32 v1, 1.0, v1
	ds_store_b32 v0, v1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_wait_kmcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB0_8
; %bb.7:
	s_add_nc_u64 s[14:15], s[2:3], 0x100
	s_mov_b32 s13, 0
	s_and_b32 s1, s15, 0x1ffffff
	s_mov_b32 s12, 1
	s_mov_b32 s5, 0x400000
	s_or_b32 s15, s1, 0x80000000
	s_mov_b32 s9, 64
	s_mov_b32 s6, 0x10000
	s_mov_b32 s4, 0x20000
	s_mov_b32 s7, s5
	s_mov_b32 s8, s12
	s_mov_b32 s10, s13
	s_mov_b32 s11, s13
	s_mov_b32 s16, s13
	s_mov_b32 s17, s13
	s_mov_b32 s18, s13
	s_mov_b32 s19, s13
	s_delay_alu instid0(SALU_CYCLE_1)
	tensor_store_from_lds s[12:15], s[4:11], s[16:19], s[16:19]
.LBB0_8:
	s_or_b32 exec_lo, exec_lo, s0
	s_wait_tensorcnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel tensor_roundtrip
		.amdhsa_group_segment_fixed_size 256
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
		.amdhsa_next_free_vgpr 2
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
		.amdhsa_inst_pref_size 5
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
	.size	tensor_roundtrip, .Lfunc_end0-tensor_roundtrip
                                        ; -- End function
	.set tensor_roundtrip.num_vgpr, 2
	.set tensor_roundtrip.num_agpr, 0
	.set tensor_roundtrip.numbered_sgpr, 24
	.set tensor_roundtrip.num_named_barrier, 0
	.set tensor_roundtrip.private_seg_size, 0
	.set tensor_roundtrip.uses_vcc, 1
	.set tensor_roundtrip.uses_flat_scratch, 0
	.set tensor_roundtrip.has_dyn_sized_stack, 0
	.set tensor_roundtrip.has_recursion, 0
	.set tensor_roundtrip.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 628
; TotalNumSgprs: 26
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 256 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 26
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
	.type	__hip_cuid_5ec141188545e347,@object ; @__hip_cuid_5ec141188545e347
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_5ec141188545e347
__hip_cuid_5ec141188545e347:
	.byte	0                               ; 0x0
	.size	__hip_cuid_5ec141188545e347, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_5ec141188545e347
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
    .group_segment_fixed_size: 256
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           tensor_roundtrip
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         tensor_roundtrip.kd
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
