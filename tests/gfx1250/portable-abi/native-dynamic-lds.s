	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	abi_dynamic_static      ; -- Begin function abi_dynamic_static
	.globl	abi_dynamic_static
	.p2align	8
	.type	abi_dynamic_static,@function
abi_dynamic_static:                     ; @abi_dynamic_static
; %bb.0:
	s_load_b128 s[0:3], s[0:1], 0x0
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v3, s5 :: v_dual_lshlrev_b32 v2, 2, v0
	v_dual_add_nc_u32 v5, 32, v2 :: v_dual_bitop2_b32 v4, 1, v0 bitop3:0x14
	s_wait_kmcnt 0x0
	global_load_b32 v1, v0, s[0:1] scale_offset
	s_wait_loadcnt 0x0
	flat_store_b32 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	global_load_b32 v1, v0, s[0:1] offset:8 scale_offset
	v_lshlrev_b32_e32 v2, 2, v4
	s_wait_loadcnt 0x0
	ds_store_b32 v5, v1
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b32 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 32, v2
	ds_load_b32 v2, v2
	s_wait_dscnt 0x0
	v_add_f32_e32 v1, v1, v2
	global_store_b32 v0, v1, s[2:3] scale_offset
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_dynamic_static
		.amdhsa_group_segment_fixed_size 32
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
		.amdhsa_next_free_vgpr 6
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
.Lfunc_end0:
	.size	abi_dynamic_static, .Lfunc_end0-abi_dynamic_static
                                        ; -- End function
	.set abi_dynamic_static.num_vgpr, 6
	.set abi_dynamic_static.num_agpr, 0
	.set abi_dynamic_static.numbered_sgpr, 6
	.set abi_dynamic_static.num_named_barrier, 0
	.set abi_dynamic_static.private_seg_size, 0
	.set abi_dynamic_static.uses_vcc, 0
	.set abi_dynamic_static.uses_flat_scratch, 0
	.set abi_dynamic_static.has_dyn_sized_stack, 0
	.set abi_dynamic_static.has_recursion, 0
	.set abi_dynamic_static.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 168
; TotalNumSgprs: 6
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 6
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
	.protected	abi_extern_only         ; -- Begin function abi_extern_only
	.globl	abi_extern_only
	.p2align	8
	.type	abi_extern_only,@function
abi_extern_only:                        ; @abi_extern_only
; %bb.0:
	s_load_b64 s[0:1], s[0:1], 0x0
	s_mov_b64 s[2:3], src_shared_base
	s_add_co_i32 s2, 0, 12
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 0x42280000
	s_cmp_lg_u32 s2, -1
	s_cselect_b32 s2, s2, 0
	s_cselect_b32 s3, s3, 0
	flat_store_b32 v0, v1, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_extern_only
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_sgpr 4
		.amdhsa_named_barrier_count 0
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
.Lfunc_end1:
	.size	abi_extern_only, .Lfunc_end1-abi_extern_only
                                        ; -- End function
	.set abi_extern_only.num_vgpr, 2
	.set abi_extern_only.num_agpr, 0
	.set abi_extern_only.numbered_sgpr, 4
	.set abi_extern_only.num_named_barrier, 0
	.set abi_extern_only.private_seg_size, 0
	.set abi_extern_only.uses_vcc, 0
	.set abi_extern_only.uses_flat_scratch, 0
	.set abi_extern_only.has_dyn_sized_stack, 0
	.set abi_extern_only.has_recursion, 0
	.set abi_extern_only.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 100
; TotalNumSgprs: 4
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 4
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
	.protected	abi_static_dynamic_disjoint ; -- Begin function abi_static_dynamic_disjoint
	.globl	abi_static_dynamic_disjoint
	.p2align	8
	.type	abi_static_dynamic_disjoint,@function
abi_static_dynamic_disjoint:            ; @abi_static_dynamic_disjoint
; %bb.0:
	v_cmp_eq_u32_e32 vcc_lo, 0, v0
	s_mov_b32 s2, 0
	s_and_saveexec_b32 s4, vcc_lo
	s_cbranch_execz .LBB2_2
; %bb.1:
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v2, 0x40e00000
	s_mov_b64 s[6:7], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, s7
	flat_store_b32 v1, v2, s[2:3] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_2:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s3, exec_lo
	v_cmpx_eq_u32_e32 32, v0
	s_cbranch_execz .LBB2_4
; %bb.3:
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v1, 0x41100000
	s_mov_b64 s[4:5], src_shared_base
	s_cmp_lg_u32 32, -1
	s_cselect_b32 s5, s5, 0
	s_cselect_b32 s4, 32, 0
	flat_store_b32 v0, v1, s[4:5] scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s3
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB2_6
; %bb.5:
	s_load_b64 s[0:1], s[0:1], 0x0
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	s_cmp_lg_u32 32, -1
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_cselect_b32 s3, s3, 0
	s_cselect_b32 s2, 32, 0
	s_wait_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v0, v1, s[0:1]
	flat_load_b32 v1, v0, s[2:3] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	;;#ASMSTART
	v_add_f32 v1, 0, v1
	;;#ASMEND
	global_store_b32 v0, v1, s[0:1] offset:4
.LBB2_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel abi_static_dynamic_disjoint
		.amdhsa_group_segment_fixed_size 32
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
.Lfunc_end2:
	.size	abi_static_dynamic_disjoint, .Lfunc_end2-abi_static_dynamic_disjoint
                                        ; -- End function
	.set abi_static_dynamic_disjoint.num_vgpr, 3
	.set abi_static_dynamic_disjoint.num_agpr, 0
	.set abi_static_dynamic_disjoint.numbered_sgpr, 8
	.set abi_static_dynamic_disjoint.num_named_barrier, 0
	.set abi_static_dynamic_disjoint.private_seg_size, 0
	.set abi_static_dynamic_disjoint.uses_vcc, 1
	.set abi_static_dynamic_disjoint.uses_flat_scratch, 0
	.set abi_static_dynamic_disjoint.has_dyn_sized_stack, 0
	.set abi_static_dynamic_disjoint.has_recursion, 0
	.set abi_static_dynamic_disjoint.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 256
; TotalNumSgprs: 10
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 32 bytes/workgroup (compile time only)
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_f184edd36654e070,@object ; @__hip_cuid_f184edd36654e070
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_f184edd36654e070
__hip_cuid_f184edd36654e070:
	.byte	0                               ; 0x0
	.size	__hip_cuid_f184edd36654e070, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym words
	.addrsig_sym disjoint_flexible
	.addrsig_sym __hip_cuid_f184edd36654e070
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
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_dynamic_static
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         abi_dynamic_static.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_extern_only
    .private_segment_fixed_size: 0
    .sgpr_count:     4
    .sgpr_spill_count: 0
    .symbol:         abi_extern_only.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           abi_static_dynamic_disjoint
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         abi_static_dynamic_disjoint.kd
    .uniform_work_group_size: 1
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
