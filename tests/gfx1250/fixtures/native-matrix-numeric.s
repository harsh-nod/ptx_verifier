	.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
	.amdhsa_code_object_version 6
	.text
	.protected	matrix_numeric136       ; -- Begin function matrix_numeric136
	.globl	matrix_numeric136
	.p2align	8
	.type	matrix_numeric136,@function
matrix_numeric136:                      ; @matrix_numeric136
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_dual_mov_b32 v3, s3 :: v_dual_add_nc_u32 v2, 1, v0
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_mov_b32_e32 v1, 0
	v_or_b32_e32 v12, 0x400, v0
	v_cvt_f32_u32_e32 v4, v2
	v_dual_mov_b32 v5, s3 :: v_dual_lshlrev_b32 v2, 1, v0
	v_dual_mov_b32 v7, s3 :: v_dual_mov_b32 v9, s3
	v_mov_b32_e32 v11, s3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f16_f32_e32 v6, v4
	v_or_b32_e32 v4, 0x200, v2
	v_or_b32_e32 v8, 0x600, v2
	s_mov_b32 s2, exec_lo
	v_or_b32_e32 v10, 0x800, v2
	v_cndmask_b32_e32 v13, 0, v6, vcc_lo
	v_or_b32_e32 v6, 0x400, v2
	flat_store_b16 v[2:3], v13 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[8:9], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[10:11], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x700, v12
	s_cbranch_execz .LBB0_4
; %bb.1:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v4, 0xa00, v2
	v_mov_b32_e32 v5, s5
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x200, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB0_4
; %bb.2:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v4, 0xc00, v2
	v_dual_mov_b32 v5, s5 :: v_dual_mov_b32 v1, 0
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB0_4
; %bb.3:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0xe00, v2
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x80, v0
	s_cbranch_execz .LBB0_8
; %bb.5:
	v_and_b32_e32 v1, 7, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b32 s3, vcc_lo
	s_cbranch_execz .LBB0_7
; %bb.6:
	v_mov_b32_e32 v1, 0x3c00
	;;#ASMSTART
	;;#ASMEND
.LBB0_7:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_or_b32 v2, v0, 1, 0x1000
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB0_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v10, 5, v0
	v_and_b32_e32 v16, 15, v0
	s_mov_b64 s[2:3], src_shared_base
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_dual_lshlrev_b32 v0, 9, v10 :: v_dual_bitop2_b32 v11, 8, v1 bitop3:0x40
	v_lshlrev_b32_e32 v1, 5, v16
	s_barrier_wait -1
	v_mov_b32_e32 v9, s3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_lshlrev_b32_e32 v2, 1, v11
	v_cmp_gt_u32_e64 s2, 8, v16
	v_lshl_or_b32 v12, v16, 1, 0x1000
	v_cmp_lt_u32_e32 vcc_lo, 7, v16
	v_or3_b32 v8, v0, v1, v2
	v_mov_b32_e32 v0, 0
	flat_load_u16 v9, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_mov_b32_e32 v7, v0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v2, v11, 4, v12
	v_dual_mov_b32 v3, s5 :: v_dual_mov_b32 v19, v0
	v_dual_mov_b32 v20, v0 :: v_dual_mov_b32 v21, v0
	v_dual_mov_b32 v22, v0 :: v_dual_mov_b32 v23, v0
	flat_load_u16 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v24, v0 :: v_dual_mov_b32 v25, v0
	s_wait_dscnt 0x0
	v_and_b32_e32 v18, 0xffff, v1
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[0:1], v[18:19]
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
.LBB0_10:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 2, v8
	flat_load_u16 v13, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_lshlrev_b32_e32 v14, 4, v11
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v18, v12, v14, 16
	v_mov_b32_e32 v19, s5
	flat_load_u16 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v0, v15, v0, 0x5040100
.LBB0_12:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 4, v8
	flat_load_u16 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v14, 32
	v_mov_b32_e32 v19, s5
	flat_load_u16 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v1, 0xffff, v17, v1
.LBB0_14:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 6, v8
	flat_load_u16 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v14, 48
	v_mov_b32_e32 v19, s5
	flat_load_u16 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v1, v18, v1, 0x5040100
.LBB0_16:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 8, v8
	flat_load_u16 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v14, 64
	v_mov_b32_e32 v21, s5
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v2, 0xffff, v19, v2
.LBB0_18:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 10, v8
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v14, 0x50
	v_mov_b32_e32 v21, s5
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v2, v20, v2, 0x5040100
.LBB0_20:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 12, v8
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v14, 0x60
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v21, v3
.LBB0_22:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 14, v8
	flat_load_u16 v8, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB0_24
; %bb.23:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v14, 0x70
	v_mov_b32_e32 v23, s5
	flat_load_u16 v12, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v3, v12, v3, 0x5040100
.LBB0_24:
	s_or_b32 exec_lo, exec_lo, s3
	s_load_b128 s[0:3], s[0:1], 0x0
	s_wait_dscnt 0x4
	v_perm_b32 v21, v17, v15, 0x5040100
	v_lshl_or_b32 v17, v10, 4, v11
	v_mov_b32_e32 v24, 0
	s_wait_dscnt 0x2
	v_perm_b32 v22, v19, v18, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v23, v8, v20, 0x5040100
	v_perm_b32 v20, v13, v9, 0x5040100
	v_dual_mov_b32 v25, v24 :: v_dual_lshlrev_b32 v18, 4, v17
	v_dual_mov_b32 v26, v24 :: v_dual_mov_b32 v27, v24
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_or_b32_e32 v19, v18, v16
	v_wmma_f32_16x16x32_f16 v[8:15], v[20:27], v[0:7], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
                                        ; implicit-def: $vgpr3
	s_wait_kmcnt 0x0
	global_store_b32 v19, v8, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.25:
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v3, 16, v18
; %bb.26:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	v_lshlrev_b32_e32 v2, 2, v16
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB0_28
; %bb.27:
	v_or_b32_e32 v0, 1, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v4, v17, 5, v2
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v8, s[0:1]
	global_store_b32 v5, v9, s[2:3]
.LBB0_28:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 2, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v9, off
	global_store_b32 v3, v10, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.29:
	v_or_b32_e32 v3, 48, v18
                                        ; implicit-def: $vgpr4
; %bb.30:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB0_32
; %bb.31:
	v_or_b32_e32 v0, 3, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v10, s[0:1]
	global_store_b32 v5, v11, s[2:3]
.LBB0_32:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 4, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v11, off
	global_store_b32 v3, v12, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.33:
	v_or_b32_e32 v3, 0x50, v18
                                        ; implicit-def: $vgpr4
; %bb.34:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB0_36
; %bb.35:
	v_or_b32_e32 v0, 5, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v12, s[0:1]
	global_store_b32 v5, v13, s[2:3]
.LBB0_36:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 6, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v13, off
	global_store_b32 v3, v14, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.37:
	v_or_b32_e32 v3, 0x70, v18
                                        ; implicit-def: $vgpr4
                                        ; implicit-def: $vgpr2
                                        ; implicit-def: $vgpr17
; %bb.38:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB0_40
; %bb.39:
	v_or_b32_e32 v0, 7, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v2, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v14, s[0:1]
	global_store_b32 v2, v15, s[2:3]
.LBB0_40:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v2, v3, v16 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	global_store_b32 v[0:1], v15, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_numeric136
		.amdhsa_group_segment_fixed_size 4352
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
		.amdhsa_next_free_vgpr 28
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 17
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
	.size	matrix_numeric136, .Lfunc_end0-matrix_numeric136
                                        ; -- End function
	.set matrix_numeric136.num_vgpr, 28
	.set matrix_numeric136.num_agpr, 0
	.set matrix_numeric136.numbered_sgpr, 6
	.set matrix_numeric136.num_named_barrier, 0
	.set matrix_numeric136.private_seg_size, 0
	.set matrix_numeric136.uses_vcc, 1
	.set matrix_numeric136.uses_flat_scratch, 0
	.set matrix_numeric136.has_dyn_sized_stack, 0
	.set matrix_numeric136.has_recursion, 0
	.set matrix_numeric136.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2160
; TotalNumSgprs: 8
; NumVgprs: 28
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4352 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 28
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
	.protected	matrix_raw17            ; -- Begin function matrix_raw17
	.globl	matrix_raw17
	.p2align	8
	.type	matrix_raw17,@function
matrix_raw17:                           ; @matrix_raw17
; %bb.0:
	v_dual_mov_b32 v1, v0 :: v_dual_lshlrev_b32 v2, 1, v0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
	s_branch .LBB1_2
.LBB1_1:                                ;   in Loop: Header=BB1_2 Depth=1
	s_or_b32 exec_lo, exec_lo, s4
	v_mov_b32_e32 v3, s3
	v_add_nc_u32_e32 v5, 0x100, v1
	v_cmp_lt_u32_e32 vcc_lo, 0x6ff, v1
	flat_store_b16 v[2:3], v4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_dual_mov_b32 v1, v5 :: v_dual_add_nc_u32 v2, 0x200, v2
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execz .LBB1_4
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v4, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 16, v1
	s_cbranch_execz .LBB1_1
; %bb.3:                                ;   in Loop: Header=BB1_2 Depth=1
	v_mov_b32_e32 v4, 0x3c00
	;;#ASMSTART
	;;#ASMEND
	s_branch .LBB1_1
.LBB1_4:
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x80, v0
	s_cbranch_execz .LBB1_8
; %bb.5:
	v_and_b32_e32 v1, 7, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b32 s3, vcc_lo
	s_cbranch_execz .LBB1_7
; %bb.6:
	v_mov_b32_e32 v1, 0x3c00
	;;#ASMSTART
	;;#ASMEND
.LBB1_7:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_or_b32 v2, v0, 1, 0x1000
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB1_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_lshrrev_b32 v1, 5, v0
	s_mov_b64 s[2:3], src_shared_base
	v_and_b32_e32 v18, 15, v0
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v11, s3 :: v_dual_bitop2_b32 v12, 8, v2 bitop3:0x40
	v_dual_lshlrev_b32 v2, 9, v1 :: v_dual_lshlrev_b32 v3, 5, v18
	s_barrier_signal -1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_3)
	v_lshlrev_b32_e32 v4, 1, v12
	s_barrier_wait -1
	v_cmp_gt_u32_e64 s2, 8, v18
	v_lshl_or_b32 v13, v18, 1, 0x1000
	v_or3_b32 v10, v2, v3, v4
	v_mov_b32_e32 v2, 0
	v_cmp_lt_u32_e32 vcc_lo, 7, v18
	flat_load_u16 v11, v[10:11] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_mov_b32_e32 v9, v2
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v4, v12, 4, v13
	v_dual_mov_b32 v5, s5 :: v_dual_mov_b32 v21, v2
	v_dual_mov_b32 v22, v2 :: v_dual_mov_b32 v23, v2
	v_dual_mov_b32 v24, v2 :: v_dual_mov_b32 v25, v2
	flat_load_u16 v3, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v26, v2 :: v_dual_mov_b32 v27, v2
	s_wait_dscnt 0x0
	v_and_b32_e32 v20, 0xffff, v3
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
	v_mov_b64_e32 v[8:9], v[26:27]
.LBB1_10:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 2, v10
	v_lshlrev_b32_e32 v16, 4, v12
	flat_load_u16 v14, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v13, v16, 16
	v_mov_b32_e32 v21, s5
	flat_load_u16 v15, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v2, v15, v2, 0x5040100
.LBB1_12:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 4, v10
	flat_load_u16 v15, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v13, v16, 32
	v_mov_b32_e32 v21, s5
	flat_load_u16 v17, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v17, v3
.LBB1_14:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 6, v10
	flat_load_u16 v17, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v13, v16, 48
	v_mov_b32_e32 v21, s5
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v3, v19, v3, 0x5040100
.LBB1_16:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 8, v10
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v13, v16, 64
	v_mov_b32_e32 v21, s5
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v4, 0xffff, v20, v4
.LBB1_18:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 10, v10
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v13, v16, 0x50
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v4, v21, v4, 0x5040100
.LBB1_20:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 12, v10
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v13, v16, 0x60
	v_mov_b32_e32 v23, s5
	flat_load_u16 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v5, 0xffff, v22, v5
.LBB1_22:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 14, v10
	flat_load_u16 v10, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB1_24
; %bb.23:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v13, v16, 0x70
	v_mov_b32_e32 v23, s5
	flat_load_u16 v13, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v5, v13, v5, 0x5040100
.LBB1_24:
	s_or_b32 exec_lo, exec_lo, s3
	v_dual_mov_b32 v26, 0 :: v_dual_bitop2_b32 v0, 8, v0 bitop3:0x40
	s_wait_dscnt 0x0
	v_perm_b32 v25, v10, v21, 0x5040100
	;;#ASMSTART
	v_mov_b32 v10, 0x3f800000
	;;#ASMEND
	v_perm_b32 v24, v20, v19, 0x5040100
	v_lshl_or_b32 v19, v1, 4, v12
	v_cmp_eq_u32_e64 s2, 0, v0
	v_mov_b32_e32 v27, v26
	v_perm_b32 v23, v17, v15, 0x5040100
	v_perm_b32 v22, v14, v11, 0x5040100
	v_dual_mov_b32 v28, v26 :: v_dual_mov_b32 v29, v26
	v_cndmask_b32_e64 v10, 0, v10, s2
	s_load_b128 s[0:3], s[0:1], 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_dual_mov_b32 v17, v10 :: v_dual_lshlrev_b32 v20, 4, v19
	v_dual_mov_b32 v11, v10 :: v_dual_mov_b32 v12, v10
	v_dual_mov_b32 v13, v10 :: v_dual_mov_b32 v14, v10
	v_dual_mov_b32 v15, v10 :: v_dual_mov_b32 v16, v10
	v_or_b32_e32 v0, v20, v18
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x32_f16 v[10:17], v[22:29], v[2:9], v[10:17]
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
                                        ; implicit-def: $vgpr3
	s_wait_kmcnt 0x0
	global_store_b32 v0, v10, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.25:
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v3, 16, v20
; %bb.26:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	v_lshlrev_b32_e32 v2, 2, v18
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB1_28
; %bb.27:
	v_or_b32_e32 v0, 1, v19
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v4, v19, 5, v2
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v10, s[0:1]
	global_store_b32 v5, v11, s[2:3]
.LBB1_28:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v18 bitop3:0x54
	v_or_b32_e32 v4, 2, v19
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v11, off
	global_store_b32 v3, v12, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.29:
	v_or_b32_e32 v3, 48, v20
                                        ; implicit-def: $vgpr4
; %bb.30:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB1_32
; %bb.31:
	v_or_b32_e32 v0, 3, v19
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v12, s[0:1]
	global_store_b32 v5, v13, s[2:3]
.LBB1_32:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v18 bitop3:0x54
	v_or_b32_e32 v4, 4, v19
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v13, off
	global_store_b32 v3, v14, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.33:
	v_or_b32_e32 v3, 0x50, v20
                                        ; implicit-def: $vgpr4
; %bb.34:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB1_36
; %bb.35:
	v_or_b32_e32 v0, 5, v19
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v14, s[0:1]
	global_store_b32 v5, v15, s[2:3]
.LBB1_36:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v18 bitop3:0x54
	v_or_b32_e32 v4, 6, v19
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v15, off
	global_store_b32 v3, v16, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.37:
	v_or_b32_e32 v3, 0x70, v20
                                        ; implicit-def: $vgpr4
                                        ; implicit-def: $vgpr2
                                        ; implicit-def: $vgpr19
; %bb.38:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB1_40
; %bb.39:
	v_or_b32_e32 v0, 7, v19
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v2, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v16, s[0:1]
	global_store_b32 v2, v17, s[2:3]
.LBB1_40:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v2, v3, v18 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	global_store_b32 v[0:1], v17, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_raw17
		.amdhsa_group_segment_fixed_size 4352
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
		.amdhsa_next_free_vgpr 30
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 16
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
	.size	matrix_raw17, .Lfunc_end1-matrix_raw17
                                        ; -- End function
	.set matrix_raw17.num_vgpr, 30
	.set matrix_raw17.num_agpr, 0
	.set matrix_raw17.numbered_sgpr, 6
	.set matrix_raw17.num_named_barrier, 0
	.set matrix_raw17.private_seg_size, 0
	.set matrix_raw17.uses_vcc, 1
	.set matrix_raw17.uses_flat_scratch, 0
	.set matrix_raw17.has_dyn_sized_stack, 0
	.set matrix_raw17.has_recursion, 0
	.set matrix_raw17.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1972
; TotalNumSgprs: 8
; NumVgprs: 30
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4352 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 8
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
	.protected	matrix_zero_128x8       ; -- Begin function matrix_zero_128x8
	.globl	matrix_zero_128x8
	.p2align	8
	.type	matrix_zero_128x8,@function
matrix_zero_128x8:                      ; @matrix_zero_128x8
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v5, s3 :: v_dual_lshlrev_b32 v2, 1, v0
	v_dual_mov_b32 v3, s3 :: v_dual_mov_b32 v1, 0
	v_or_b32_e32 v12, 0x400, v0
	v_or_b32_e32 v4, 0x200, v2
	v_dual_mov_b32 v7, s3 :: v_dual_mov_b32 v9, s3
	v_or_b32_e32 v6, 0x400, v2
	v_or_b32_e32 v8, 0x600, v2
	v_or_b32_e32 v10, 0x800, v2
	v_mov_b32_e32 v11, s3
	s_mov_b32 s2, exec_lo
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[8:9], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[10:11], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x700, v12
	s_cbranch_execz .LBB2_4
; %bb.1:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v4, 0xa00, v2
	v_mov_b32_e32 v5, s5
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x200, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB2_4
; %bb.2:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v4, 0xc00, v2
	v_dual_mov_b32 v5, s5 :: v_dual_mov_b32 v1, 0
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB2_4
; %bb.3:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0xe00, v2
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x80, v0
	s_cbranch_execz .LBB2_6
; %bb.5:
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_or_b32 v2, v0, 1, 0x1000
	v_dual_mov_b32 v3, s5 :: v_dual_mov_b32 v1, 0
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB2_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v10, 5, v0
	v_and_b32_e32 v16, 15, v0
	s_mov_b64 s[2:3], src_shared_base
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_dual_lshlrev_b32 v0, 9, v10 :: v_dual_bitop2_b32 v11, 8, v1 bitop3:0x40
	v_lshlrev_b32_e32 v1, 5, v16
	s_barrier_wait -1
	v_mov_b32_e32 v9, s3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_lshlrev_b32_e32 v2, 1, v11
	v_cmp_gt_u32_e64 s2, 8, v16
	v_lshl_or_b32 v12, v16, 1, 0x1000
	v_cmp_lt_u32_e32 vcc_lo, 7, v16
	v_or3_b32 v8, v0, v1, v2
	v_mov_b32_e32 v0, 0
	flat_load_u16 v9, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_mov_b32_e32 v7, v0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_8
; %bb.7:
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v2, v11, 4, v12
	v_dual_mov_b32 v3, s5 :: v_dual_mov_b32 v19, v0
	v_dual_mov_b32 v20, v0 :: v_dual_mov_b32 v21, v0
	v_dual_mov_b32 v22, v0 :: v_dual_mov_b32 v23, v0
	flat_load_u16 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v24, v0 :: v_dual_mov_b32 v25, v0
	s_wait_dscnt 0x0
	v_and_b32_e32 v18, 0xffff, v1
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[0:1], v[18:19]
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
.LBB2_8:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 2, v8
	flat_load_u16 v13, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_lshlrev_b32_e32 v14, 4, v11
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v18, v12, v14, 16
	v_mov_b32_e32 v19, s5
	flat_load_u16 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v0, v15, v0, 0x5040100
.LBB2_10:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 4, v8
	flat_load_u16 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v14, 32
	v_mov_b32_e32 v19, s5
	flat_load_u16 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v1, 0xffff, v17, v1
.LBB2_12:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 6, v8
	flat_load_u16 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v14, 48
	v_mov_b32_e32 v19, s5
	flat_load_u16 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v1, v18, v1, 0x5040100
.LBB2_14:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 8, v8
	flat_load_u16 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v14, 64
	v_mov_b32_e32 v21, s5
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v2, 0xffff, v19, v2
.LBB2_16:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 10, v8
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v14, 0x50
	v_mov_b32_e32 v21, s5
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v2, v20, v2, 0x5040100
.LBB2_18:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 12, v8
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v14, 0x60
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v21, v3
.LBB2_20:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 14, v8
	flat_load_u16 v8, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB2_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v14, 0x70
	v_mov_b32_e32 v23, s5
	flat_load_u16 v12, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v3, v12, v3, 0x5040100
.LBB2_22:
	s_or_b32 exec_lo, exec_lo, s3
	s_load_b128 s[0:3], s[0:1], 0x0
	s_wait_dscnt 0x4
	v_perm_b32 v21, v17, v15, 0x5040100
	v_lshl_or_b32 v17, v10, 4, v11
	v_mov_b32_e32 v24, 0
	s_wait_dscnt 0x2
	v_perm_b32 v22, v19, v18, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v23, v8, v20, 0x5040100
	v_perm_b32 v20, v13, v9, 0x5040100
	v_dual_mov_b32 v25, v24 :: v_dual_lshlrev_b32 v18, 4, v17
	v_dual_mov_b32 v26, v24 :: v_dual_mov_b32 v27, v24
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_or_b32_e32 v19, v18, v16
	v_wmma_f32_16x16x32_f16 v[8:15], v[20:27], v[0:7], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
                                        ; implicit-def: $vgpr3
	s_wait_kmcnt 0x0
	global_store_b32 v19, v8, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.23:
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v3, 16, v18
; %bb.24:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	v_lshlrev_b32_e32 v2, 2, v16
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB2_26
; %bb.25:
	v_or_b32_e32 v0, 1, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v4, v17, 5, v2
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v8, s[0:1]
	global_store_b32 v5, v9, s[2:3]
.LBB2_26:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 2, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v9, off
	global_store_b32 v3, v10, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.27:
	v_or_b32_e32 v3, 48, v18
                                        ; implicit-def: $vgpr4
; %bb.28:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB2_30
; %bb.29:
	v_or_b32_e32 v0, 3, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v10, s[0:1]
	global_store_b32 v5, v11, s[2:3]
.LBB2_30:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 4, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v11, off
	global_store_b32 v3, v12, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.31:
	v_or_b32_e32 v3, 0x50, v18
                                        ; implicit-def: $vgpr4
; %bb.32:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB2_34
; %bb.33:
	v_or_b32_e32 v0, 5, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v12, s[0:1]
	global_store_b32 v5, v13, s[2:3]
.LBB2_34:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 6, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v13, off
	global_store_b32 v3, v14, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.35:
	v_or_b32_e32 v3, 0x70, v18
                                        ; implicit-def: $vgpr4
                                        ; implicit-def: $vgpr2
                                        ; implicit-def: $vgpr17
; %bb.36:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB2_38
; %bb.37:
	v_or_b32_e32 v0, 7, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v2, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v14, s[0:1]
	global_store_b32 v2, v15, s[2:3]
.LBB2_38:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v2, v3, v16 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	global_store_b32 v[0:1], v15, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_zero_128x8
		.amdhsa_group_segment_fixed_size 4352
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
		.amdhsa_next_free_vgpr 28
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 17
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
	.size	matrix_zero_128x8, .Lfunc_end2-matrix_zero_128x8
                                        ; -- End function
	.set matrix_zero_128x8.num_vgpr, 28
	.set matrix_zero_128x8.num_agpr, 0
	.set matrix_zero_128x8.numbered_sgpr, 6
	.set matrix_zero_128x8.num_named_barrier, 0
	.set matrix_zero_128x8.private_seg_size, 0
	.set matrix_zero_128x8.uses_vcc, 1
	.set matrix_zero_128x8.uses_flat_scratch, 0
	.set matrix_zero_128x8.has_dyn_sized_stack, 0
	.set matrix_zero_128x8.has_recursion, 0
	.set matrix_zero_128x8.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2112
; TotalNumSgprs: 8
; NumVgprs: 28
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4352 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 28
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
	.protected	matrix_zero_128x256     ; -- Begin function matrix_zero_128x256
	.globl	matrix_zero_128x256
	.p2align	8
	.type	matrix_zero_128x256,@function
matrix_zero_128x256:                    ; @matrix_zero_128x256
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v7, s3 :: v_dual_lshlrev_b32 v2, 1, v0
	v_dual_mov_b32 v5, s3 :: v_dual_mov_b32 v1, 0
	v_or_b32_e32 v3, 0x400, v0
	v_or_b32_e32 v4, 0x2000, v2
	v_or_b32_e32 v6, 0x2200, v2
	v_dual_mov_b32 v9, s3 :: v_dual_mov_b32 v11, s3
	v_or_b32_e32 v8, 0x2400, v2
	v_or_b32_e32 v10, 0x2600, v2
	v_or_b32_e32 v12, 0x2800, v2
	v_mov_b32_e32 v13, s3
	s_mov_b32 s2, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[8:9], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[10:11], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[12:13], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x700, v3
	s_cbranch_execz .LBB3_4
; %bb.1:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v7, s5 :: v_dual_add_nc_u32 v6, 0xa00, v4
	v_cmp_gt_u32_e32 vcc_lo, 0x200, v0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_4
; %bb.2:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v7, s5 :: v_dual_add_nc_u32 v6, 0xc00, v4
	v_mov_b32_e32 v3, 0
	v_cmp_gt_u32_e32 vcc_lo, 0x100, v0
	flat_store_b16 v[6:7], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_4
; %bb.3:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v5, s5 :: v_dual_add_nc_u32 v4, 0xe00, v4
	flat_store_b16 v[4:5], v3 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB3_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_or_b32_e32 v4, 0xffffff00, v0
	s_mov_b64 s[2:3], src_shared_base
	s_mov_b32 s2, 0
.LBB3_5:                                ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_dual_mov_b32 v3, s3 :: v_dual_add_nc_u32 v4, 0x100, v4
	v_cmp_lt_u32_e32 vcc_lo, 0xeff, v4
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v2, 0x200, v2
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB3_5
; %bb.6:
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v2, 5, v0
	v_and_b32_e32 v0, 15, v0
	s_mov_b64 s[4:5], src_shared_base
	s_load_b128 s[0:3], s[0:1], 0x0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v17, s5 :: v_dual_lshlrev_b32 v3, 9, v2
	v_dual_lshlrev_b32 v4, 5, v0 :: v_dual_bitop2_b32 v1, 8, v1 bitop3:0x40
	v_dual_mov_b32 v15, s5 :: v_dual_mov_b32 v9, s5
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_lshlrev_b32 v2, 12, v2 :: v_dual_lshlrev_b32 v5, 1, v1
	v_dual_mov_b32 v21, s5 :: v_dual_mov_b32 v11, s5
	v_dual_mov_b32 v13, s5 :: v_dual_mov_b32 v19, s5
	v_or3_b32 v3, v3, v4, v5
	v_dual_lshlrev_b32 v5, 9, v1 :: v_dual_lshlrev_b32 v1, 8, v1
	v_dual_mov_b32 v4, 0 :: v_dual_mov_b32 v23, s5
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)
	v_or_b32_e32 v8, 0x2000, v3
	v_or_b32_e32 v10, 0x2002, v3
	v_or3_b32 v1, v2, v1, v0
	v_lshlrev_b32_e32 v0, 1, v0
	v_or_b32_e32 v12, 0x2004, v3
	v_or_b32_e32 v14, 0x2006, v3
	v_or_b32_e32 v16, 0x2008, v3
	v_or_b32_e32 v18, 0x200a, v3
	v_or_b32_e32 v20, 0x200c, v3
	v_or_b32_e32 v22, 0x200e, v3
	v_dual_mov_b32 v25, v4 :: v_dual_lshlrev_b32 v24, 2, v1
	v_or3_b32 v26, v5, v0, 0xe00
	s_mov_b32 s4, -16
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
.LBB3_7:                                ; =>This Inner Loop Header: Depth=1
	v_dual_mov_b32 v1, s5 :: v_dual_add_nc_u32 v0, 0xfffff200, v26
	v_dual_mov_b32 v6, v4 :: v_dual_mov_b32 v32, v4
	flat_load_u16 v2, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v3, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_dual_mov_b32 v27, s5 :: v_dual_add_nc_u32 v0, 0xfffff400, v26
	flat_load_u16 v28, v[10:11] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v5, v4 :: v_dual_mov_b32 v34, v4
	flat_load_u16 v29, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v0, 0xfffff600, v26
	flat_load_u16 v30, v[12:13] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v31, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_dual_mov_b32 v7, v4 :: v_dual_add_nc_u32 v0, 0xfffff800, v26
	flat_load_u16 v36, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v37, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_dual_mov_b32 v33, v4 :: v_dual_add_nc_u32 v0, 0xfffffa00, v26
	flat_load_u16 v38, v[16:17] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v39, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_dual_mov_b32 v35, v4 :: v_dual_add_nc_u32 v0, 0xfffffc00, v26
	flat_load_u16 v40, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v41, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v0, 0xfffffe00, v26
	flat_load_u16 v42, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v43, v[0:1] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v48, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	flat_load_u16 v49, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_kmcnt 0x0
	v_add_nc_u64_e32 v[44:45], s[2:3], v[24:25]
	v_add_nc_u64_e32 v[46:47], s[0:1], v[24:25]
	s_wait_xcnt 0x0
	v_add_nc_u32_e32 v26, 32, v26
	s_add_co_i32 s4, s4, 16
	s_add_nc_u64 s[2:3], s[2:3], 64
	s_add_nc_u64 s[0:1], s[0:1], 64
	s_cmp_lt_u32 s4, 0xf0
	s_wait_dscnt 0xd
	v_perm_b32 v0, v28, v2, 0x5040100
	s_wait_dscnt 0xc
	v_perm_b32 v28, v29, v3, 0x5040100
	s_wait_dscnt 0x9
	v_perm_b32 v1, v36, v30, 0x5040100
	s_wait_dscnt 0x8
	v_perm_b32 v29, v37, v31, 0x5040100
	s_wait_dscnt 0x5
	v_perm_b32 v2, v40, v38, 0x5040100
	s_wait_dscnt 0x4
	v_perm_b32 v30, v41, v39, 0x5040100
	s_wait_dscnt 0x1
	v_perm_b32 v3, v48, v42, 0x5040100
	s_wait_dscnt 0x0
	v_perm_b32 v31, v49, v43, 0x5040100
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x32_f16 v[36:43], v[0:7], v[28:35], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	global_store_b32 v[44:45], v36, off
	global_store_b32 v[46:47], v36, off
	global_store_b32 v[44:45], v37, off offset:1024
	global_store_b32 v[46:47], v37, off offset:1024
	global_store_b32 v[44:45], v38, off offset:2048
	global_store_b32 v[46:47], v38, off offset:2048
	global_store_b32 v[44:45], v39, off offset:3072
	global_store_b32 v[46:47], v39, off offset:3072
	global_store_b32 v[44:45], v40, off offset:4096
	global_store_b32 v[46:47], v40, off offset:4096
	global_store_b32 v[44:45], v41, off offset:5120
	global_store_b32 v[46:47], v41, off offset:5120
	global_store_b32 v[44:45], v42, off offset:6144
	global_store_b32 v[46:47], v42, off offset:6144
	global_store_b32 v[44:45], v43, off offset:7168
	global_store_b32 v[46:47], v43, off offset:7168
	s_cbranch_scc1 .LBB3_7
; %bb.8:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_zero_128x256
		.amdhsa_group_segment_fixed_size 12288
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
		.amdhsa_next_free_vgpr 50
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 12
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
	.size	matrix_zero_128x256, .Lfunc_end3-matrix_zero_128x256
                                        ; -- End function
	.set matrix_zero_128x256.num_vgpr, 50
	.set matrix_zero_128x256.num_agpr, 0
	.set matrix_zero_128x256.numbered_sgpr, 6
	.set matrix_zero_128x256.num_named_barrier, 0
	.set matrix_zero_128x256.private_seg_size, 0
	.set matrix_zero_128x256.uses_vcc, 1
	.set matrix_zero_128x256.uses_flat_scratch, 0
	.set matrix_zero_128x256.has_dyn_sized_stack, 0
	.set matrix_zero_128x256.has_recursion, 0
	.set matrix_zero_128x256.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1448
; TotalNumSgprs: 8
; NumVgprs: 50
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 12288 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 8
; NumVGPRsForWavesPerEU: 50
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
	.protected	matrix_disabled_first_output ; -- Begin function matrix_disabled_first_output
	.globl	matrix_disabled_first_output
	.p2align	8
	.type	matrix_disabled_first_output,@function
matrix_disabled_first_output:           ; @matrix_disabled_first_output
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)
	v_dual_mov_b32 v3, s3 :: v_dual_add_nc_u32 v2, 1, v0
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_mov_b32_e32 v1, 0
	v_or_b32_e32 v12, 0x400, v0
	v_cvt_f32_u32_e32 v4, v2
	v_dual_mov_b32 v5, s3 :: v_dual_lshlrev_b32 v2, 1, v0
	v_dual_mov_b32 v7, s3 :: v_dual_mov_b32 v9, s3
	v_mov_b32_e32 v11, s3
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_cvt_f16_f32_e32 v6, v4
	v_or_b32_e32 v4, 0x200, v2
	v_or_b32_e32 v8, 0x600, v2
	s_mov_b32 s2, exec_lo
	v_or_b32_e32 v10, 0x800, v2
	v_cndmask_b32_e32 v13, 0, v6, vcc_lo
	v_or_b32_e32 v6, 0x400, v2
	flat_store_b16 v[2:3], v13 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[8:9], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[10:11], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x700, v12
	s_cbranch_execz .LBB4_4
; %bb.1:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v4, 0xa00, v2
	v_mov_b32_e32 v5, s5
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x200, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB4_4
; %bb.2:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v4, 0xc00, v2
	v_dual_mov_b32 v5, s5 :: v_dual_mov_b32 v1, 0
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB4_4
; %bb.3:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0xe00, v2
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x80, v0
	s_cbranch_execz .LBB4_8
; %bb.5:
	v_and_b32_e32 v1, 7, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_eq_u32_e32 vcc_lo, 0, v1
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b32 s3, vcc_lo
	s_cbranch_execz .LBB4_7
; %bb.6:
	v_mov_b32_e32 v1, 0x3c00
	;;#ASMSTART
	;;#ASMEND
.LBB4_7:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_or_b32 v2, v0, 1, 0x1000
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB4_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v10, 5, v0
	v_and_b32_e32 v16, 15, v0
	s_mov_b64 s[2:3], src_shared_base
	s_wait_dscnt 0x0
	s_barrier_signal -1
	v_dual_lshlrev_b32 v0, 9, v10 :: v_dual_bitop2_b32 v11, 8, v1 bitop3:0x40
	v_lshlrev_b32_e32 v1, 5, v16
	s_barrier_wait -1
	v_mov_b32_e32 v9, s3
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_lshlrev_b32_e32 v2, 1, v11
	v_cmp_gt_u32_e32 vcc_lo, 8, v16
	v_lshl_or_b32 v12, v16, 1, 0x1000
	v_or3_b32 v8, v0, v1, v2
	v_mov_b32_e32 v0, 0
	flat_load_u16 v9, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_mov_b32_e32 v7, v0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v2, v11, 4, v12
	v_dual_mov_b32 v3, s5 :: v_dual_mov_b32 v19, v0
	v_dual_mov_b32 v20, v0 :: v_dual_mov_b32 v21, v0
	v_dual_mov_b32 v22, v0 :: v_dual_mov_b32 v23, v0
	flat_load_u16 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v24, v0 :: v_dual_mov_b32 v25, v0
	s_wait_dscnt 0x0
	v_and_b32_e32 v18, 0xffff, v1
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[0:1], v[18:19]
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
.LBB4_10:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s3 :: v_dual_add_nc_u32 v14, 2, v8
	flat_load_u16 v13, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_lshlrev_b32_e32 v14, 4, v11
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v18, v12, v14, 16
	v_mov_b32_e32 v19, s5
	flat_load_u16 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v0, v15, v0, 0x5040100
.LBB4_12:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s3 :: v_dual_add_nc_u32 v18, 4, v8
	flat_load_u16 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v14, 32
	v_mov_b32_e32 v19, s5
	flat_load_u16 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v1, 0xffff, v17, v1
.LBB4_14:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s3 :: v_dual_add_nc_u32 v18, 6, v8
	flat_load_u16 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v14, 48
	v_mov_b32_e32 v19, s5
	flat_load_u16 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v1, v18, v1, 0x5040100
.LBB4_16:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s3 :: v_dual_add_nc_u32 v18, 8, v8
	flat_load_u16 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v14, 64
	v_mov_b32_e32 v21, s5
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v2, 0xffff, v19, v2
.LBB4_18:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s3 :: v_dual_add_nc_u32 v20, 10, v8
	flat_load_u16 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v14, 0x50
	v_mov_b32_e32 v21, s5
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v2, v20, v2, 0x5040100
.LBB4_20:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s3 :: v_dual_add_nc_u32 v20, 12, v8
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v14, 0x60
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v21, v3
.LBB4_22:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s3 :: v_dual_add_nc_u32 v22, 14, v8
	flat_load_u16 v8, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB4_24
; %bb.23:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v14, 0x70
	v_mov_b32_e32 v23, s5
	flat_load_u16 v12, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v3, v12, v3, 0x5040100
.LBB4_24:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_wait_dscnt 0x4
	v_perm_b32 v21, v17, v15, 0x5040100
	v_lshl_or_b32 v17, v10, 4, v11
	v_mov_b32_e32 v24, 0
	s_wait_dscnt 0x2
	v_perm_b32 v22, v19, v18, 0x5040100
	v_cmp_gt_u32_e32 vcc_lo, 8, v16
	s_wait_dscnt 0x0
	v_perm_b32 v23, v8, v20, 0x5040100
	v_dual_lshlrev_b32 v19, 4, v17 :: v_dual_mov_b32 v27, v24
	v_or_b32_e32 v18, v17, v16
	v_perm_b32 v20, v13, v9, 0x5040100
	v_dual_mov_b32 v25, v24 :: v_dual_mov_b32 v26, v24
	s_delay_alu instid0(VALU_DEP_4)
	v_or_b32_e32 v28, v19, v16
	s_wait_xcnt 0x0
	v_cmp_ne_u32_e64 s0, 0, v18
	v_lshlrev_b32_e32 v18, 2, v16
	v_wmma_f32_16x16x32_f16 v[8:15], v[20:27], v[0:7], 0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	s_and_b32 s1, vcc_lo, s0
	s_wait_kmcnt 0x0
	global_store_b32 v28, v8, s[6:7] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, s1
	s_cbranch_execz .LBB4_26
; %bb.25:
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v0, v17, 5, v18
	global_store_b32 v0, v8, s[4:5]
.LBB4_26:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v0, 1, v17
                                        ; implicit-def: $vgpr2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	v_lshl_or_b32 v1, v0, 6, v18
	global_store_b32 v1, v9, s[6:7]
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB4_28
; %bb.27:
	v_or_b32_e32 v1, 2, v17
	v_lshl_or_b32 v0, v0, 5, v18
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v2, 3, v1
	v_lshl_or_b32 v3, v1, 6, v18
	global_store_b32 v0, v9, s[4:5]
	global_store_b32 v3, v10, s[6:7]
.LBB4_28:
	s_wait_xcnt 0x0
	s_or_saveexec_b32 s0, s0
	v_mov_b64_e32 v[0:1], s[4:5]
	s_xor_b32 exec_lo, exec_lo, s0
; %bb.29:
	v_mov_b64_e32 v[0:1], s[6:7]
	v_or_b32_e32 v2, 32, v19
; %bb.30:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v5, 0 :: v_dual_bitop2_b32 v4, v2, v16 bitop3:0x54
	v_or_b32_e32 v3, 3, v17
	v_lshl_add_u64 v[0:1], v[4:5], 2, v[0:1]
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	v_lshl_or_b32 v2, v3, 6, v18
	global_store_b32 v[0:1], v10, off
	global_store_b32 v2, v11, s[6:7]
                                        ; implicit-def: $vgpr2
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB4_32
; %bb.31:
	v_or_b32_e32 v0, 4, v17
	v_lshl_or_b32 v1, v3, 5, v18
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshl_or_b32 v3, v0, 6, v18
	global_store_b32 v1, v11, s[4:5]
	global_store_b32 v3, v12, s[6:7]
.LBB4_32:
	s_wait_xcnt 0x0
	s_or_saveexec_b32 s0, s0
	v_mov_b64_e32 v[0:1], s[4:5]
	s_xor_b32 exec_lo, exec_lo, s0
; %bb.33:
	v_mov_b64_e32 v[0:1], s[6:7]
	v_or_b32_e32 v2, 64, v19
; %bb.34:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v5, 0 :: v_dual_bitop2_b32 v4, v2, v16 bitop3:0x54
	v_or_b32_e32 v3, 5, v17
	v_lshl_add_u64 v[0:1], v[4:5], 2, v[0:1]
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	v_lshl_or_b32 v2, v3, 6, v18
	global_store_b32 v[0:1], v12, off
	global_store_b32 v2, v13, s[6:7]
                                        ; implicit-def: $vgpr2
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB4_36
; %bb.35:
	v_or_b32_e32 v0, 6, v17
	v_lshl_or_b32 v1, v3, 5, v18
                                        ; implicit-def: $vgpr19
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshl_or_b32 v3, v0, 6, v18
	global_store_b32 v1, v13, s[4:5]
	global_store_b32 v3, v14, s[6:7]
.LBB4_36:
	s_wait_xcnt 0x0
	s_or_saveexec_b32 s0, s0
	v_mov_b64_e32 v[0:1], s[4:5]
	s_xor_b32 exec_lo, exec_lo, s0
; %bb.37:
	v_mov_b64_e32 v[0:1], s[6:7]
	v_or_b32_e32 v2, 0x60, v19
; %bb.38:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v5, 0 :: v_dual_bitop2_b32 v4, v2, v16 bitop3:0x54
	v_or_b32_e32 v2, 7, v17
	v_lshl_add_u64 v[0:1], v[4:5], 2, v[0:1]
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v3, v2, 6, v18
	global_store_b32 v[0:1], v14, off
	global_store_b32 v3, v15, s[6:7]
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB4_40
; %bb.39:
	v_lshl_or_b32 v0, v2, 5, v18
	global_store_b32 v0, v15, s[4:5]
.LBB4_40:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_disabled_first_output
		.amdhsa_group_segment_fixed_size 4352
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
		.amdhsa_next_free_vgpr 29
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
		.amdhsa_inst_pref_size 17
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
	.size	matrix_disabled_first_output, .Lfunc_end4-matrix_disabled_first_output
                                        ; -- End function
	.set matrix_disabled_first_output.num_vgpr, 29
	.set matrix_disabled_first_output.num_agpr, 0
	.set matrix_disabled_first_output.numbered_sgpr, 8
	.set matrix_disabled_first_output.num_named_barrier, 0
	.set matrix_disabled_first_output.private_seg_size, 0
	.set matrix_disabled_first_output.uses_vcc, 1
	.set matrix_disabled_first_output.uses_flat_scratch, 0
	.set matrix_disabled_first_output.has_dyn_sized_stack, 0
	.set matrix_disabled_first_output.has_recursion, 0
	.set matrix_disabled_first_output.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2156
; TotalNumSgprs: 10
; NumVgprs: 29
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4352 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 29
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
	.protected	matrix_disabled_lds_read ; -- Begin function matrix_disabled_lds_read
	.globl	matrix_disabled_lds_read
	.p2align	8
	.type	matrix_disabled_lds_read,@function
matrix_disabled_lds_read:               ; @matrix_disabled_lds_read
; %bb.0:
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_dual_mov_b32 v19, s3 :: v_dual_add_nc_u32 v2, 1, v0
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_dual_mov_b32 v1, 0 :: v_dual_lshlrev_b32 v18, 1, v0
	v_cvt_f32_u32_e32 v2, v2
	v_or_b32_e32 v10, 0x400, v0
	v_dual_mov_b32 v3, s3 :: v_dual_mov_b32 v5, s3
	v_dual_mov_b32 v7, s3 :: v_dual_mov_b32 v9, s3
	s_delay_alu instid0(VALU_DEP_4)
	v_cvt_f16_f32_e32 v4, v2
	v_or_b32_e32 v2, 0x200, v18
	v_or_b32_e32 v6, 0x600, v18
	s_mov_b32 s2, exec_lo
	v_or_b32_e32 v8, 0x800, v18
	v_cndmask_b32_e32 v11, 0, v4, vcc_lo
	v_or_b32_e32 v4, 0x400, v18
	flat_store_b16 v[18:19], v11 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[4:5], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[6:7], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	flat_store_b16 v[8:9], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x700, v10
	s_cbranch_execz .LBB5_4
; %bb.1:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0xa00, v18
	v_mov_b32_e32 v3, s5
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x200, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB5_4
; %bb.2:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0xc00, v18
	v_dual_mov_b32 v3, s5 :: v_dual_mov_b32 v1, 0
	s_mov_b32 s3, exec_lo
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s3, exec_lo, s3
	s_cbranch_execz .LBB5_4
; %bb.3:
	s_mov_b64 s[4:5], src_shared_base
	v_or_b32_e32 v2, 0xe00, v18
	v_mov_b32_e32 v3, s5
	flat_store_b16 v[2:3], v1 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_4:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_and_b32_e32 v1, 7, v0
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x80, v0
	s_cbranch_execz .LBB5_8
; %bb.5:
	v_mov_b32_e32 v2, 0
	s_mov_b32 s3, exec_lo
	v_cmpx_eq_u32_e32 0, v1
	s_cbranch_execz .LBB5_7
; %bb.6:
	v_mov_b32_e32 v2, 0x3c00
	;;#ASMSTART
	;;#ASMEND
.LBB5_7:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_or_b32 v4, v0, 1, 0x2000
	v_mov_b32_e32 v5, s5
	flat_store_b16 v[4:5], v2 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB5_8:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v2, 1, v0 :: v_dual_lshrrev_b32 v12, 5, v0
	s_mov_b64 s[2:3], src_shared_base
	s_wait_dscnt 0x0
	s_barrier_signal -1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v2, 9, v12 :: v_dual_bitop2_b32 v13, 8, v2 bitop3:0x40
	v_and_b32_e32 v19, 15, v0
	s_barrier_wait -1
	v_dual_mov_b32 v11, s3 :: v_dual_lshlrev_b32 v4, 1, v13
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_lshlrev_b32_e32 v3, 5, v19
	v_cmp_gt_u32_e32 vcc_lo, 8, v19
	v_lshl_or_b32 v14, v19, 1, 0x2000
	v_or3_b32 v10, v2, v3, v4
	v_mov_b32_e32 v2, 0
	flat_load_u16 v11, v[10:11] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v3, v2 :: v_dual_mov_b32 v4, v2
	v_dual_mov_b32 v5, v2 :: v_dual_mov_b32 v6, v2
	v_dual_mov_b32 v7, v2 :: v_dual_mov_b32 v8, v2
	v_mov_b32_e32 v9, v2
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	v_lshl_add_u32 v4, v13, 4, v14
	v_dual_mov_b32 v5, s5 :: v_dual_mov_b32 v21, v2
	v_dual_mov_b32 v22, v2 :: v_dual_mov_b32 v23, v2
	v_dual_mov_b32 v24, v2 :: v_dual_mov_b32 v25, v2
	flat_load_u16 v3, v[4:5] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v26, v2 :: v_dual_mov_b32 v27, v2
	s_wait_dscnt 0x0
	v_and_b32_e32 v20, 0xffff, v3
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
	v_mov_b64_e32 v[8:9], v[26:27]
.LBB5_10:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v17, s3 :: v_dual_add_nc_u32 v16, 2, v10
	flat_load_u16 v15, v[16:17] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	v_lshlrev_b32_e32 v16, 4, v13
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(VALU_DEP_1)
	v_add3_u32 v20, v14, v16, 16
	v_mov_b32_e32 v21, s5
	flat_load_u16 v17, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v2, v17, v2, 0x5040100
.LBB5_12:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s3 :: v_dual_add_nc_u32 v20, 4, v10
	flat_load_u16 v17, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v14, v16, 32
	v_mov_b32_e32 v21, s5
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v3, 0xffff, v20, v3
.LBB5_14:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s3 :: v_dual_add_nc_u32 v20, 6, v10
	flat_load_u16 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v14, v16, 48
	v_mov_b32_e32 v23, s5
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v3, v21, v3, 0x5040100
.LBB5_16:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s3 :: v_dual_add_nc_u32 v22, 8, v10
	flat_load_u16 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v14, v16, 64
	v_mov_b32_e32 v23, s5
	flat_load_u16 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v4, 0xffff, v22, v4
.LBB5_18:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s3 :: v_dual_add_nc_u32 v22, 10, v10
	flat_load_u16 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v14, v16, 0x50
	v_mov_b32_e32 v25, s5
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v4, v23, v4, 0x5040100
.LBB5_20:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v25, s3 :: v_dual_add_nc_u32 v24, 12, v10
	flat_load_u16 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v14, v16, 0x60
	v_mov_b32_e32 v25, s5
	flat_load_u16 v24, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_bfi_b32 v5, 0xffff, v24, v5
.LBB5_22:
	s_or_b32 exec_lo, exec_lo, s2
	s_mov_b64 s[2:3], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v25, s3 :: v_dual_add_nc_u32 v24, 14, v10
	flat_load_u16 v10, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s2, vcc_lo
	s_cbranch_execz .LBB5_24
; %bb.23:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v14, v16, 0x70
	v_mov_b32_e32 v25, s5
	flat_load_u16 v14, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_perm_b32 v5, v14, v5, 0x5040100
.LBB5_24:
	s_or_b32 exec_lo, exec_lo, s2
	s_load_b128 s[4:7], s[0:1], 0x0
	s_wait_dscnt 0x4
	v_perm_b32 v25, v20, v17, 0x5040100
	v_lshl_or_b32 v20, v12, 4, v13
	s_wait_dscnt 0x2
	v_perm_b32 v26, v22, v21, 0x5040100
	v_mov_b32_e32 v28, 0
	v_cmp_gt_u32_e32 vcc_lo, 8, v19
	s_wait_dscnt 0x0
	v_perm_b32 v27, v10, v23, 0x5040100
	v_dual_lshlrev_b32 v22, 4, v20 :: v_dual_bitop2_b32 v21, v20, v19 bitop3:0x54
	v_perm_b32 v24, v15, v11, 0x5040100
	v_dual_mov_b32 v29, v28 :: v_dual_mov_b32 v30, v28
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_cmp_ne_u32_e64 s0, 0, v21
	v_dual_mov_b32 v31, v28 :: v_dual_bitop2_b32 v23, v22, v19 bitop3:0x54
	v_lshlrev_b32_e32 v21, 2, v19
	v_wmma_f32_16x16x32_f16 v[10:17], v[24:31], v[2:9], 0
	s_and_b32 s1, vcc_lo, s0
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
	s_wait_kmcnt 0x0
	global_store_b32 v23, v10, s[6:7] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, s1
	s_cbranch_execz .LBB5_26
; %bb.25:
	v_nop
	v_nop
	v_nop
	v_nop
	v_lshl_or_b32 v2, v20, 5, v21
	global_store_b32 v2, v10, s[4:5]
.LBB5_26:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_nop
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v2, 1, v20
                                        ; implicit-def: $vgpr4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(SALU_CYCLE_1)
	v_lshl_or_b32 v3, v2, 6, v21
	global_store_b32 v3, v11, s[6:7]
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB5_28
; %bb.27:
	v_or_b32_e32 v3, 2, v20
	v_lshl_or_b32 v2, v2, 5, v21
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v4, 3, v3
	v_lshl_or_b32 v5, v3, 6, v21
	global_store_b32 v2, v11, s[4:5]
	global_store_b32 v5, v12, s[6:7]
.LBB5_28:
	s_wait_xcnt 0x0
	s_or_saveexec_b32 s0, s0
	v_mov_b64_e32 v[2:3], s[4:5]
	s_xor_b32 exec_lo, exec_lo, s0
; %bb.29:
	v_mov_b64_e32 v[2:3], s[6:7]
	v_or_b32_e32 v4, 32, v22
; %bb.30:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v4, v19 bitop3:0x54
	v_or_b32_e32 v5, 3, v20
	v_lshl_add_u64 v[2:3], v[6:7], 2, v[2:3]
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	v_lshl_or_b32 v4, v5, 6, v21
	global_store_b32 v[2:3], v12, off
	global_store_b32 v4, v13, s[6:7]
                                        ; implicit-def: $vgpr4
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB5_32
; %bb.31:
	v_or_b32_e32 v2, 4, v20
	v_lshl_or_b32 v3, v5, 5, v21
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v4, 3, v2
	v_lshl_or_b32 v5, v2, 6, v21
	global_store_b32 v3, v13, s[4:5]
	global_store_b32 v5, v14, s[6:7]
.LBB5_32:
	s_wait_xcnt 0x0
	s_or_saveexec_b32 s0, s0
	v_mov_b64_e32 v[2:3], s[4:5]
	s_xor_b32 exec_lo, exec_lo, s0
; %bb.33:
	v_mov_b64_e32 v[2:3], s[6:7]
	v_or_b32_e32 v4, 64, v22
; %bb.34:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v4, v19 bitop3:0x54
	v_or_b32_e32 v5, 5, v20
	v_lshl_add_u64 v[2:3], v[6:7], 2, v[2:3]
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	v_lshl_or_b32 v4, v5, 6, v21
	global_store_b32 v[2:3], v14, off
	global_store_b32 v4, v15, s[6:7]
                                        ; implicit-def: $vgpr4
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB5_36
; %bb.35:
	v_or_b32_e32 v2, 6, v20
	v_lshl_or_b32 v3, v5, 5, v21
                                        ; implicit-def: $vgpr22
	s_delay_alu instid0(VALU_DEP_2)
	v_lshlrev_b32_e32 v4, 3, v2
	v_lshl_or_b32 v5, v2, 6, v21
	global_store_b32 v3, v15, s[4:5]
	global_store_b32 v5, v16, s[6:7]
.LBB5_36:
	s_wait_xcnt 0x0
	s_or_saveexec_b32 s0, s0
	v_mov_b64_e32 v[2:3], s[4:5]
	s_xor_b32 exec_lo, exec_lo, s0
; %bb.37:
	v_mov_b64_e32 v[2:3], s[6:7]
	v_or_b32_e32 v4, 0x60, v22
; %bb.38:
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v4, v19 bitop3:0x54
	v_or_b32_e32 v4, 7, v20
	v_lshl_add_u64 v[2:3], v[6:7], 2, v[2:3]
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v4, 6, v21
	global_store_b32 v[2:3], v16, off
	global_store_b32 v5, v17, s[6:7]
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s0, vcc_lo
	s_cbranch_execz .LBB5_40
; %bb.39:
	v_lshl_or_b32 v2, v4, 5, v21
	global_store_b32 v2, v17, s[4:5]
.LBB5_40:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s0
	v_lshl_or_b32 v2, v0, 2, 0x1000
	v_or_b32_e32 v4, 0xffffff00, v0
	s_mov_b32 s0, 0
	s_branch .LBB5_42
.LBB5_41:                               ;   in Loop: Header=BB5_42 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s1
	v_add_nc_u32_e32 v4, 0x100, v4
	v_add_nc_u32_e32 v2, 0x400, v2
	v_add_nc_u32_e32 v18, 0x200, v18
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_cmp_lt_u32_e32 vcc_lo, 0x2ff, v4
	s_or_b32 s0, vcc_lo, s0
	s_and_not1_b32 exec_lo, exec_lo, s0
	s_cbranch_execz .LBB5_44
.LBB5_42:                               ; =>This Inner Loop Header: Depth=1
	s_mov_b32 s1, exec_lo
	v_cmpx_ne_u32_e32 0, v18
	s_cbranch_execz .LBB5_41
; %bb.43:                               ;   in Loop: Header=BB5_42 Depth=1
	v_and_or_b32 v3, 0x7f0, v18, v1
	s_mov_b64 s[2:3], src_shared_base
	global_load_b32 v5, v3, s[6:7] scale_offset
	s_wait_xcnt 0x0
	v_mov_b32_e32 v3, s3
	s_wait_loadcnt 0x0
	flat_store_b32 v[2:3], v5 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_branch .LBB5_41
.LBB5_44:
	s_or_b32 exec_lo, exec_lo, s0
	s_wait_storecnt_dscnt 0x0
	s_barrier_signal -1
	s_barrier_wait -1
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v0
	s_cbranch_execz .LBB5_46
; %bb.45:
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[0:1], src_shared_base
	s_movk_i32 s0, 0x1000
	flat_load_b32 v1, v0, s[0:1] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	global_store_b32 v0, v1, s[4:5]
.LBB5_46:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_disabled_lds_read
		.amdhsa_group_segment_fixed_size 8448
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
		.amdhsa_next_free_vgpr 32
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
		.amdhsa_inst_pref_size 19
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
	.size	matrix_disabled_lds_read, .Lfunc_end5-matrix_disabled_lds_read
                                        ; -- End function
	.set matrix_disabled_lds_read.num_vgpr, 32
	.set matrix_disabled_lds_read.num_agpr, 0
	.set matrix_disabled_lds_read.numbered_sgpr, 8
	.set matrix_disabled_lds_read.num_named_barrier, 0
	.set matrix_disabled_lds_read.private_seg_size, 0
	.set matrix_disabled_lds_read.uses_vcc, 1
	.set matrix_disabled_lds_read.uses_flat_scratch, 0
	.set matrix_disabled_lds_read.has_dyn_sized_stack, 0
	.set matrix_disabled_lds_read.has_recursion, 0
	.set matrix_disabled_lds_read.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2392
; TotalNumSgprs: 10
; NumVgprs: 32
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8448 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 10
; NumVGPRsForWavesPerEU: 32
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
	.protected	matrix_mixed408         ; -- Begin function matrix_mixed408
	.globl	matrix_mixed408
	.p2align	8
	.type	matrix_mixed408,@function
matrix_mixed408:                        ; @matrix_mixed408
; %bb.0:
	v_dual_mov_b32 v17, 0 :: v_dual_bitop2_b32 v16, 15, v0 bitop3:0x40
	v_dual_lshlrev_b32 v1, 3, v0 :: v_dual_mov_b32 v5, v0
	s_get_pc_i64 s[4:5]
	s_add_nc_u64 s[4:5], s[4:5], __const._Z16mixed_fp8_matrixILb0EEvPfS0_.e4@rel64+4
	s_mov_b64 s[2:3], src_shared_base
	v_add_nc_u64_e32 v[2:3], s[4:5], v[16:17]
	v_mov_b32_e32 v4, v1
	s_mov_b32 s2, 0
	s_branch .LBB6_2
.LBB6_1:                                ;   in Loop: Header=BB6_2 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_add_nc_u32_e32 v7, 0x100, v5
	v_cmp_lt_u32_e32 vcc_lo, 0xeff, v5
	v_and_or_b32 v8, 0x7f80, v4, v16
	v_dual_mov_b32 v9, s3 :: v_dual_add_nc_u32 v4, 0x800, v4
	s_delay_alu instid0(VALU_DEP_4)
	v_mov_b32_e32 v5, v7
	s_or_b32 s2, vcc_lo, s2
	s_wait_loadcnt 0x0
	flat_store_b8 v[8:9], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execz .LBB6_4
.LBB6_2:                                ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v6, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 32, v5
	s_cbranch_execz .LBB6_1
; %bb.3:                                ;   in Loop: Header=BB6_2 Depth=1
	global_load_u8 v6, v[2:3], off
	s_branch .LBB6_1
.LBB6_4:
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB6_6
; %bb.5:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_and_b32_e32 v1, 0x780, v1
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_mov_b32_e32 v3, s5
	v_cndmask_b32_e64 v2, 64, 60, vcc_lo
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	v_cndmask_b32_e32 v4, 0, v2, vcc_lo
	v_or3_b32 v2, v1, v16, 0x8000
	flat_store_b8 v[2:3], v4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB6_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v10, 5, v0
	s_mov_b64 s[2:3], src_shared_base
	v_lshlrev_b32_e32 v2, 8, v16
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v0, 12, v10 :: v_dual_bitop2_b32 v11, 8, v1 bitop3:0x40
	v_mov_b32_e32 v9, s3
	s_barrier_signal -1
	s_barrier_wait -1
	v_or3_b32 v8, v0, v2, v11
	v_mov_b32_e32 v0, 0
	v_cmp_gt_u32_e64 s2, 8, v16
	v_or_b32_e32 v12, 0x8000, v2
	v_cmp_lt_u32_e32 vcc_lo, 7, v16
	flat_load_u8 v9, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_mov_b32_e32 v7, v0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_8
; %bb.7:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s5 :: v_dual_add_nc_u32 v2, v12, v11
	v_dual_mov_b32 v19, v0 :: v_dual_mov_b32 v20, v0
	v_dual_mov_b32 v21, v0 :: v_dual_mov_b32 v22, v0
	flat_load_u8 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v23, v0 :: v_dual_mov_b32 v24, v0
	v_mov_b32_e32 v25, v0
	s_wait_dscnt 0x0
	v_cvt_f32_bf8_e32 v1, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v1, v1
	v_pack_b32_f16 v18, v1, 0
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[0:1], v[18:19]
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
.LBB6_8:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 1, v8
	flat_load_u8 v13, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v14, v12, v11, 1
	v_mov_b32_e32 v15, s5
	flat_load_u8 v14, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v14, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v14, v14
	v_perm_b32 v0, v14, v0, 0x5040100
.LBB6_10:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 2, v8
	flat_load_u8 v14, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v11, 2
	v_mov_b32_e32 v19, s5
	flat_load_u8 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v15, v15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v15, v15
	v_bfi_b32 v1, 0xffff, v15, v1
.LBB6_12:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 3, v8
	flat_load_u8 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v11, 3
	v_mov_b32_e32 v19, s5
	flat_load_u8 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v17, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v17, v17
	v_perm_b32 v1, v17, v1, 0x5040100
.LBB6_14:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 4, v8
	flat_load_u8 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v11, 4
	v_mov_b32_e32 v19, s5
	flat_load_u8 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v18, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v18, v18
	v_bfi_b32 v2, 0xffff, v18, v2
.LBB6_16:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 5, v8
	flat_load_u8 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v11, 5
	v_mov_b32_e32 v21, s5
	flat_load_u8 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v19, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v19, v19
	v_perm_b32 v2, v19, v2, 0x5040100
.LBB6_18:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 6, v8
	flat_load_u8 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v11, 6
	v_mov_b32_e32 v21, s5
	flat_load_u8 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v20, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v20, v20
	v_bfi_b32 v3, 0xffff, v20, v3
.LBB6_20:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 7, v8
	flat_load_u8 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v11, 7
	v_mov_b32_e32 v23, s5
	flat_load_u8 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v21, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v21, v21
	v_perm_b32 v3, v21, v3, 0x5040100
.LBB6_22:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 0x80, v8
	flat_load_u8 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_24
; %bb.23:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v11, 0x80
	v_mov_b32_e32 v23, s5
	flat_load_u8 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v22, v22
	v_bfi_b32 v4, 0xffff, v22, v4
.LBB6_24:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 0x81, v8
	flat_load_u8 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_26
; %bb.25:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v12, v11, 0x81
	v_mov_b32_e32 v25, s5
	flat_load_u8 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v23, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v23, v23
	v_perm_b32 v4, v23, v4, 0x5040100
.LBB6_26:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v24, 0x82, v8
	flat_load_u8 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_28
; %bb.27:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v12, v11, 0x82
	v_mov_b32_e32 v25, s5
	flat_load_u8 v24, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_bfi_b32 v5, 0xffff, v24, v5
.LBB6_28:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v24, 0x83, v8
	flat_load_u8 v24, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_30
; %bb.29:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v26, v12, v11, 0x83
	v_mov_b32_e32 v27, s5
	flat_load_u8 v25, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v25, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v25, v25
	v_perm_b32 v5, v25, v5, 0x5040100
.LBB6_30:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v27, s5 :: v_dual_add_nc_u32 v26, 0x84, v8
	flat_load_u8 v25, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_32
; %bb.31:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v26, v12, v11, 0x84
	v_mov_b32_e32 v27, s5
	flat_load_u8 v26, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v26, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v26, v26
	v_bfi_b32 v6, 0xffff, v26, v6
.LBB6_32:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v27, s5 :: v_dual_add_nc_u32 v26, 0x85, v8
	flat_load_u8 v26, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_34
; %bb.33:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v28, v12, v11, 0x85
	v_mov_b32_e32 v29, s5
	flat_load_u8 v27, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v27, v27
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v27, v27
	v_perm_b32 v6, v27, v6, 0x5040100
.LBB6_34:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v29, s5 :: v_dual_add_nc_u32 v28, 0x86, v8
	flat_load_u8 v27, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_36
; %bb.35:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v28, v12, v11, 0x86
	v_mov_b32_e32 v29, s5
	flat_load_u8 v28, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v28, v28
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v28, v28
	v_bfi_b32 v7, 0xffff, v28, v7
.LBB6_36:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v29, s5 :: v_dual_add_nc_u32 v28, 0x87, v8
	flat_load_u8 v8, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_38
; %bb.37:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v28, v12, v11, 0x87
	v_mov_b32_e32 v29, s5
	flat_load_u8 v12, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_bf8_e32 v12, v12
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v12, v12
	v_perm_b32 v7, v12, v7, 0x5040100
.LBB6_38:
	s_or_b32 exec_lo, exec_lo, s3
	s_wait_dscnt 0xe
	v_and_b32_e32 v12, 0xff, v13
	s_wait_dscnt 0xd
	v_and_b32_e32 v13, 0xff, v14
	s_wait_dscnt 0xc
	v_and_b32_e32 v14, 0xff, v15
	s_wait_dscnt 0xb
	v_and_b32_e32 v15, 0xff, v17
	s_wait_dscnt 0xa
	v_and_b32_e32 v17, 0xff, v18
	s_wait_dscnt 0x9
	v_and_b32_e32 v18, 0xff, v19
	s_wait_dscnt 0x7
	v_and_b32_e32 v19, 0xff, v21
	s_wait_dscnt 0x5
	v_and_b32_e32 v21, 0xff, v23
	v_and_b32_e32 v22, 0xff, v22
	s_wait_dscnt 0x3
	v_and_b32_e32 v23, 0xff, v25
	s_wait_dscnt 0x1
	v_and_b32_e32 v25, 0xff, v27
	s_wait_dscnt 0x0
	v_and_b32_e32 v8, 0xff, v8
	v_and_b32_e32 v24, 0xff, v24
	v_cvt_f32_fp8_e32 v15, v15
	v_cvt_f32_fp8_e32 v17, v17
	v_and_b32_e32 v20, 0xff, v20
	v_cvt_f32_fp8_e32 v19, v19
	v_cvt_f32_fp8_e32 v21, v21
	v_and_b32_e32 v26, 0xff, v26
	v_cvt_f32_fp8_e32 v25, v25
	v_cvt_f32_fp8_e32 v8, v8
	v_cvt_f32_fp8_e32 v24, v24
	v_cvt_f32_fp8_e32 v22, v22
	s_load_b128 s[0:3], s[0:1], 0x0
	v_and_b32_e32 v9, 0xff, v9
	v_cvt_f32_fp8_e32 v18, v18
	v_cvt_f32_fp8_e32 v23, v23
	v_cvt_f32_fp8_e32 v26, v26
	v_cvt_f32_fp8_e32 v20, v20
	v_cvt_pk_f16_f32 v27, v25, v8
	v_cvt_pk_f16_f32 v25, v21, v24
	v_cvt_pk_f16_f32 v24, v19, v22
	v_cvt_pk_f16_f32 v22, v15, v17
	v_lshl_or_b32 v17, v10, 4, v11
	v_cvt_f32_fp8_e32 v9, v9
	v_cvt_f32_fp8_e32 v12, v12
	v_cvt_f32_fp8_e32 v13, v13
	v_cvt_f32_fp8_e32 v14, v14
	v_cvt_pk_f16_f32 v26, v23, v26
	v_cvt_pk_f16_f32 v23, v18, v20
	v_lshlrev_b32_e32 v18, 4, v17
	v_cvt_pk_f16_f32 v20, v9, v12
	v_cvt_pk_f16_f32 v21, v13, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_wmma_f32_16x16x32_f16 v[8:15], v[20:27], v[0:7], 0
	v_or_b32_e32 v19, v18, v16
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
                                        ; implicit-def: $vgpr3
	s_wait_kmcnt 0x0
	global_store_b32 v19, v8, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.39:
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v3, 16, v18
; %bb.40:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	v_lshlrev_b32_e32 v2, 2, v16
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB6_42
; %bb.41:
	v_or_b32_e32 v0, 1, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v4, v17, 5, v2
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v8, s[0:1]
	global_store_b32 v5, v9, s[2:3]
.LBB6_42:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 2, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v9, off
	global_store_b32 v3, v10, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.43:
	v_or_b32_e32 v3, 48, v18
                                        ; implicit-def: $vgpr4
; %bb.44:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB6_46
; %bb.45:
	v_or_b32_e32 v0, 3, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v10, s[0:1]
	global_store_b32 v5, v11, s[2:3]
.LBB6_46:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 4, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v11, off
	global_store_b32 v3, v12, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.47:
	v_or_b32_e32 v3, 0x50, v18
                                        ; implicit-def: $vgpr4
; %bb.48:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB6_50
; %bb.49:
	v_or_b32_e32 v0, 5, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v12, s[0:1]
	global_store_b32 v5, v13, s[2:3]
.LBB6_50:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 6, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v13, off
	global_store_b32 v3, v14, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.51:
	v_or_b32_e32 v3, 0x70, v18
                                        ; implicit-def: $vgpr4
                                        ; implicit-def: $vgpr2
                                        ; implicit-def: $vgpr17
; %bb.52:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB6_54
; %bb.53:
	v_or_b32_e32 v0, 7, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v2, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v14, s[0:1]
	global_store_b32 v2, v15, s[2:3]
.LBB6_54:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v2, v3, v16 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	global_store_b32 v[0:1], v15, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_mixed408
		.amdhsa_group_segment_fixed_size 34816
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
		.amdhsa_next_free_vgpr 30
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 25
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
.Lfunc_end6:
	.size	matrix_mixed408, .Lfunc_end6-matrix_mixed408
                                        ; -- End function
	.set matrix_mixed408.num_vgpr, 30
	.set matrix_mixed408.num_agpr, 0
	.set matrix_mixed408.numbered_sgpr, 6
	.set matrix_mixed408.num_named_barrier, 0
	.set matrix_mixed408.private_seg_size, 0
	.set matrix_mixed408.uses_vcc, 1
	.set matrix_mixed408.uses_flat_scratch, 0
	.set matrix_mixed408.has_dyn_sized_stack, 0
	.set matrix_mixed408.has_recursion, 0
	.set matrix_mixed408.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3156
; TotalNumSgprs: 8
; NumVgprs: 30
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 34816 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 8
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
	.protected	matrix_wrong_b476       ; -- Begin function matrix_wrong_b476
	.globl	matrix_wrong_b476
	.p2align	8
	.type	matrix_wrong_b476,@function
matrix_wrong_b476:                      ; @matrix_wrong_b476
; %bb.0:
	v_dual_mov_b32 v17, 0 :: v_dual_bitop2_b32 v16, 15, v0 bitop3:0x40
	v_dual_lshlrev_b32 v1, 3, v0 :: v_dual_mov_b32 v5, v0
	s_get_pc_i64 s[4:5]
	s_add_nc_u64 s[4:5], s[4:5], __const._Z16mixed_fp8_matrixILb1EEvPfS0_.e4@rel64+4
	s_mov_b64 s[2:3], src_shared_base
	v_add_nc_u64_e32 v[2:3], s[4:5], v[16:17]
	v_mov_b32_e32 v4, v1
	s_mov_b32 s2, 0
	s_branch .LBB7_2
.LBB7_1:                                ;   in Loop: Header=BB7_2 Depth=1
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_add_nc_u32_e32 v7, 0x100, v5
	v_cmp_lt_u32_e32 vcc_lo, 0xeff, v5
	v_and_or_b32 v8, 0x7f80, v4, v16
	v_dual_mov_b32 v9, s3 :: v_dual_add_nc_u32 v4, 0x800, v4
	s_delay_alu instid0(VALU_DEP_4)
	v_mov_b32_e32 v5, v7
	s_or_b32 s2, vcc_lo, s2
	s_wait_loadcnt 0x0
	flat_store_b8 v[8:9], v6 scope:SCOPE_SYS
	s_wait_storecnt 0x0
	s_wait_xcnt 0x0
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execz .LBB7_4
.LBB7_2:                                ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v6, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_gt_u32_e32 32, v5
	s_cbranch_execz .LBB7_1
; %bb.3:                                ;   in Loop: Header=BB7_2 Depth=1
	global_load_u8 v6, v[2:3], off
	s_branch .LBB7_1
.LBB7_4:
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s2, exec_lo
	v_cmpx_gt_u32_e32 0x100, v0
	s_cbranch_execz .LBB7_6
; %bb.5:
	v_cmp_gt_u32_e32 vcc_lo, 16, v0
	v_and_b32_e32 v1, 0x780, v1
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_mov_b32_e32 v3, s5
	v_cndmask_b32_e64 v2, 64, 60, vcc_lo
	v_cmp_gt_u32_e32 vcc_lo, 32, v0
	v_cndmask_b32_e32 v4, 0, v2, vcc_lo
	v_or3_b32 v2, v1, v16, 0x8000
	flat_store_b8 v[2:3], v4 scope:SCOPE_SYS
	s_wait_storecnt 0x0
.LBB7_6:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s2
	v_dual_lshrrev_b32 v1, 1, v0 :: v_dual_lshrrev_b32 v10, 5, v0
	s_mov_b64 s[2:3], src_shared_base
	v_lshlrev_b32_e32 v2, 8, v16
	s_wait_dscnt 0x0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_2)
	v_dual_lshlrev_b32 v0, 12, v10 :: v_dual_bitop2_b32 v11, 8, v1 bitop3:0x40
	v_mov_b32_e32 v9, s3
	s_barrier_signal -1
	s_barrier_wait -1
	v_or3_b32 v8, v0, v2, v11
	v_mov_b32_e32 v0, 0
	v_cmp_gt_u32_e64 s2, 8, v16
	v_or_b32_e32 v12, 0x8000, v2
	v_cmp_lt_u32_e32 vcc_lo, 7, v16
	flat_load_u8 v9, v[8:9] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v1, v0 :: v_dual_mov_b32 v2, v0
	v_dual_mov_b32 v3, v0 :: v_dual_mov_b32 v4, v0
	v_dual_mov_b32 v5, v0 :: v_dual_mov_b32 v6, v0
	v_mov_b32_e32 v7, v0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_8
; %bb.7:
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v3, s5 :: v_dual_add_nc_u32 v2, v12, v11
	v_dual_mov_b32 v19, v0 :: v_dual_mov_b32 v20, v0
	v_dual_mov_b32 v21, v0 :: v_dual_mov_b32 v22, v0
	flat_load_u8 v1, v[2:3] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	v_dual_mov_b32 v23, v0 :: v_dual_mov_b32 v24, v0
	v_mov_b32_e32 v25, v0
	s_wait_dscnt 0x0
	v_cvt_f32_fp8_e32 v1, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v1, v1
	v_pack_b32_f16 v18, v1, 0
	s_wait_xcnt 0x0
	s_delay_alu instid0(VALU_DEP_1)
	v_mov_b64_e32 v[0:1], v[18:19]
	v_mov_b64_e32 v[2:3], v[20:21]
	v_mov_b64_e32 v[4:5], v[22:23]
	v_mov_b64_e32 v[6:7], v[24:25]
.LBB7_8:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 1, v8
	flat_load_u8 v13, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_10
; %bb.9:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v14, v12, v11, 1
	v_mov_b32_e32 v15, s5
	flat_load_u8 v14, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v14, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v14, v14
	v_perm_b32 v0, v14, v0, 0x5040100
.LBB7_10:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v15, s5 :: v_dual_add_nc_u32 v14, 2, v8
	flat_load_u8 v14, v[14:15] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_12
; %bb.11:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v11, 2
	v_mov_b32_e32 v19, s5
	flat_load_u8 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v15, v15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v15, v15
	v_bfi_b32 v1, 0xffff, v15, v1
.LBB7_12:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 3, v8
	flat_load_u8 v15, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_14
; %bb.13:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v11, 3
	v_mov_b32_e32 v19, s5
	flat_load_u8 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v17, v17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v17, v17
	v_perm_b32 v1, v17, v1, 0x5040100
.LBB7_14:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 4, v8
	flat_load_u8 v17, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_16
; %bb.15:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v18, v12, v11, 4
	v_mov_b32_e32 v19, s5
	flat_load_u8 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v18, v18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v18, v18
	v_bfi_b32 v2, 0xffff, v18, v2
.LBB7_16:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v19, s5 :: v_dual_add_nc_u32 v18, 5, v8
	flat_load_u8 v18, v[18:19] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_18
; %bb.17:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v11, 5
	v_mov_b32_e32 v21, s5
	flat_load_u8 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v19, v19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v19, v19
	v_perm_b32 v2, v19, v2, 0x5040100
.LBB7_18:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 6, v8
	flat_load_u8 v19, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_20
; %bb.19:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v20, v12, v11, 6
	v_mov_b32_e32 v21, s5
	flat_load_u8 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v20, v20
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v20, v20
	v_bfi_b32 v3, 0xffff, v20, v3
.LBB7_20:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v21, s5 :: v_dual_add_nc_u32 v20, 7, v8
	flat_load_u8 v20, v[20:21] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_22
; %bb.21:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v11, 7
	v_mov_b32_e32 v23, s5
	flat_load_u8 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v21, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v21, v21
	v_perm_b32 v3, v21, v3, 0x5040100
.LBB7_22:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 0x80, v8
	flat_load_u8 v21, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_24
; %bb.23:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v22, v12, v11, 0x80
	v_mov_b32_e32 v23, s5
	flat_load_u8 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v22, v22
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v22, v22
	v_bfi_b32 v4, 0xffff, v22, v4
.LBB7_24:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v23, s5 :: v_dual_add_nc_u32 v22, 0x81, v8
	flat_load_u8 v22, v[22:23] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_26
; %bb.25:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v12, v11, 0x81
	v_mov_b32_e32 v25, s5
	flat_load_u8 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v23, v23
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v23, v23
	v_perm_b32 v4, v23, v4, 0x5040100
.LBB7_26:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v24, 0x82, v8
	flat_load_u8 v23, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_28
; %bb.27:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v24, v12, v11, 0x82
	v_mov_b32_e32 v25, s5
	flat_load_u8 v24, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v24, v24
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v24, v24
	v_bfi_b32 v5, 0xffff, v24, v5
.LBB7_28:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v25, s5 :: v_dual_add_nc_u32 v24, 0x83, v8
	flat_load_u8 v24, v[24:25] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_30
; %bb.29:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v26, v12, v11, 0x83
	v_mov_b32_e32 v27, s5
	flat_load_u8 v25, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v25, v25
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v25, v25
	v_perm_b32 v5, v25, v5, 0x5040100
.LBB7_30:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v27, s5 :: v_dual_add_nc_u32 v26, 0x84, v8
	flat_load_u8 v25, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_32
; %bb.31:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v26, v12, v11, 0x84
	v_mov_b32_e32 v27, s5
	flat_load_u8 v26, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v26, v26
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v26, v26
	v_bfi_b32 v6, 0xffff, v26, v6
.LBB7_32:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v27, s5 :: v_dual_add_nc_u32 v26, 0x85, v8
	flat_load_u8 v26, v[26:27] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_34
; %bb.33:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v28, v12, v11, 0x85
	v_mov_b32_e32 v29, s5
	flat_load_u8 v27, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v27, v27
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v27, v27
	v_perm_b32 v6, v27, v6, 0x5040100
.LBB7_34:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v29, s5 :: v_dual_add_nc_u32 v28, 0x86, v8
	flat_load_u8 v27, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_36
; %bb.35:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v28, v12, v11, 0x86
	v_mov_b32_e32 v29, s5
	flat_load_u8 v28, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v28, v28
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v28, v28
	v_bfi_b32 v7, 0xffff, v28, v7
.LBB7_36:
	s_or_b32 exec_lo, exec_lo, s3
	s_mov_b64 s[4:5], src_shared_base
	s_delay_alu instid0(SALU_CYCLE_1)
	v_dual_mov_b32 v29, s5 :: v_dual_add_nc_u32 v28, 0x87, v8
	flat_load_u8 v8, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt 0x0
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB7_38
; %bb.37:
	s_mov_b64 s[4:5], src_shared_base
	v_add3_u32 v28, v12, v11, 0x87
	v_mov_b32_e32 v29, s5
	flat_load_u8 v12, v[28:29] scope:SCOPE_SYS
	s_wait_loadcnt_dscnt 0x0
	v_cvt_f32_fp8_e32 v12, v12
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_f16_f32_e32 v12, v12
	v_perm_b32 v7, v12, v7, 0x5040100
.LBB7_38:
	s_or_b32 exec_lo, exec_lo, s3
	s_wait_dscnt 0xe
	v_and_b32_e32 v12, 0xff, v13
	s_wait_dscnt 0xd
	v_and_b32_e32 v13, 0xff, v14
	s_wait_dscnt 0xc
	v_and_b32_e32 v14, 0xff, v15
	s_wait_dscnt 0xb
	v_and_b32_e32 v15, 0xff, v17
	s_wait_dscnt 0xa
	v_and_b32_e32 v17, 0xff, v18
	s_wait_dscnt 0x9
	v_and_b32_e32 v18, 0xff, v19
	s_wait_dscnt 0x7
	v_and_b32_e32 v19, 0xff, v21
	s_wait_dscnt 0x5
	v_and_b32_e32 v21, 0xff, v23
	v_and_b32_e32 v22, 0xff, v22
	s_wait_dscnt 0x3
	v_and_b32_e32 v23, 0xff, v25
	s_wait_dscnt 0x1
	v_and_b32_e32 v25, 0xff, v27
	s_wait_dscnt 0x0
	v_and_b32_e32 v8, 0xff, v8
	v_and_b32_e32 v24, 0xff, v24
	v_cvt_f32_fp8_e32 v15, v15
	v_cvt_f32_fp8_e32 v17, v17
	v_and_b32_e32 v20, 0xff, v20
	v_cvt_f32_fp8_e32 v19, v19
	v_cvt_f32_fp8_e32 v21, v21
	v_and_b32_e32 v26, 0xff, v26
	v_cvt_f32_fp8_e32 v25, v25
	v_cvt_f32_fp8_e32 v8, v8
	v_cvt_f32_fp8_e32 v24, v24
	v_cvt_f32_fp8_e32 v22, v22
	s_load_b128 s[0:3], s[0:1], 0x0
	v_and_b32_e32 v9, 0xff, v9
	v_cvt_f32_fp8_e32 v18, v18
	v_cvt_f32_fp8_e32 v23, v23
	v_cvt_f32_fp8_e32 v26, v26
	v_cvt_f32_fp8_e32 v20, v20
	v_cvt_pk_f16_f32 v27, v25, v8
	v_cvt_pk_f16_f32 v25, v21, v24
	v_cvt_pk_f16_f32 v24, v19, v22
	v_cvt_pk_f16_f32 v22, v15, v17
	v_lshl_or_b32 v17, v10, 4, v11
	v_cvt_f32_fp8_e32 v9, v9
	v_cvt_f32_fp8_e32 v12, v12
	v_cvt_f32_fp8_e32 v13, v13
	v_cvt_f32_fp8_e32 v14, v14
	v_cvt_pk_f16_f32 v26, v23, v26
	v_cvt_pk_f16_f32 v23, v18, v20
	v_lshlrev_b32_e32 v18, 4, v17
	v_cvt_pk_f16_f32 v20, v9, v12
	v_cvt_pk_f16_f32 v21, v13, v14
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_wmma_f32_16x16x32_f16 v[8:15], v[20:27], v[0:7], 0
	v_or_b32_e32 v19, v18, v16
	;;#ASMSTART
	v_nop
	v_nop
	v_nop
	v_nop
	;;#ASMEND
                                        ; implicit-def: $vgpr3
	s_wait_kmcnt 0x0
	global_store_b32 v19, v8, s[2:3] scale_offset
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.39:
	v_nop
	v_nop
	v_nop
	v_or_b32_e32 v3, 16, v18
; %bb.40:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	v_lshlrev_b32_e32 v2, 2, v16
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB7_42
; %bb.41:
	v_or_b32_e32 v0, 1, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v4, v17, 5, v2
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v8, s[0:1]
	global_store_b32 v5, v9, s[2:3]
.LBB7_42:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 2, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v9, off
	global_store_b32 v3, v10, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.43:
	v_or_b32_e32 v3, 48, v18
                                        ; implicit-def: $vgpr4
; %bb.44:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB7_46
; %bb.45:
	v_or_b32_e32 v0, 3, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v10, s[0:1]
	global_store_b32 v5, v11, s[2:3]
.LBB7_46:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 4, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v11, off
	global_store_b32 v3, v12, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.47:
	v_or_b32_e32 v3, 0x50, v18
                                        ; implicit-def: $vgpr4
; %bb.48:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB7_50
; %bb.49:
	v_or_b32_e32 v0, 5, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v5, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v12, s[0:1]
	global_store_b32 v5, v13, s[2:3]
.LBB7_50:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v7, 0 :: v_dual_bitop2_b32 v6, v3, v16 bitop3:0x54
	v_or_b32_e32 v4, 6, v17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[0:1]
	v_lshl_or_b32 v3, v4, 6, v2
	global_store_b32 v[0:1], v13, off
	global_store_b32 v3, v14, s[2:3]
                                        ; implicit-def: $vgpr3
	s_wait_xcnt 0x0
	s_and_saveexec_b32 s4, vcc_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s4, exec_lo, s4
; %bb.51:
	v_or_b32_e32 v3, 0x70, v18
                                        ; implicit-def: $vgpr4
                                        ; implicit-def: $vgpr2
                                        ; implicit-def: $vgpr17
; %bb.52:
	s_or_saveexec_b32 s4, s4
	v_mov_b64_e32 v[0:1], s[2:3]
	s_xor_b32 exec_lo, exec_lo, s4
	s_cbranch_execz .LBB7_54
; %bb.53:
	v_or_b32_e32 v0, 7, v17
	v_lshl_or_b32 v4, v4, 5, v2
	s_delay_alu instid0(VALU_DEP_2)
	v_lshl_or_b32 v2, v0, 6, v2
	v_lshlrev_b32_e32 v3, 3, v0
	v_mov_b64_e32 v[0:1], s[0:1]
	global_store_b32 v4, v14, s[0:1]
	global_store_b32 v2, v15, s[2:3]
.LBB7_54:
	s_wait_xcnt 0x0
	s_or_b32 exec_lo, exec_lo, s4
	v_dual_mov_b32 v3, 0 :: v_dual_bitop2_b32 v2, v3, v16 bitop3:0x54
	s_delay_alu instid0(VALU_DEP_1)
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	global_store_b32 v[0:1], v15, off
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel matrix_wrong_b476
		.amdhsa_group_segment_fixed_size 34816
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
		.amdhsa_next_free_vgpr 30
		.amdhsa_next_free_sgpr 6
		.amdhsa_named_barrier_count 0
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_fp16_overflow 0
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_inst_pref_size 25
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
.Lfunc_end7:
	.size	matrix_wrong_b476, .Lfunc_end7-matrix_wrong_b476
                                        ; -- End function
	.set matrix_wrong_b476.num_vgpr, 30
	.set matrix_wrong_b476.num_agpr, 0
	.set matrix_wrong_b476.numbered_sgpr, 6
	.set matrix_wrong_b476.num_named_barrier, 0
	.set matrix_wrong_b476.private_seg_size, 0
	.set matrix_wrong_b476.uses_vcc, 1
	.set matrix_wrong_b476.uses_flat_scratch, 0
	.set matrix_wrong_b476.has_dyn_sized_stack, 0
	.set matrix_wrong_b476.has_recursion, 0
	.set matrix_wrong_b476.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3156
; TotalNumSgprs: 8
; NumVgprs: 30
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 34816 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 8
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
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__const._Z16mixed_fp8_matrixILb0EEvPfS0_.e4,@object ; @__const._Z16mixed_fp8_matrixILb0EEvPfS0_.e4
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0
__const._Z16mixed_fp8_matrixILb0EEvPfS0_.e4:
	.ascii	"8@DHJLNPQRSTUVWX"
	.size	__const._Z16mixed_fp8_matrixILb0EEvPfS0_.e4, 16

	.type	__const._Z16mixed_fp8_matrixILb1EEvPfS0_.e4,@object ; @__const._Z16mixed_fp8_matrixILb1EEvPfS0_.e4
	.p2align	4, 0x0
__const._Z16mixed_fp8_matrixILb1EEvPfS0_.e4:
	.ascii	"8@DHJLNPQRSTUVWX"
	.size	__const._Z16mixed_fp8_matrixILb1EEvPfS0_.e4, 16

	.type	__hip_cuid_22e557790ff48768,@object ; @__hip_cuid_22e557790ff48768
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_22e557790ff48768
__hip_cuid_22e557790ff48768:
	.byte	0                               ; 0x0
	.size	__hip_cuid_22e557790ff48768, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_22e557790ff48768
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
    .group_segment_fixed_size: 4352
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_numeric136
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_numeric136.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     28
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
    .group_segment_fixed_size: 4352
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_raw17
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_raw17.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     30
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
    .group_segment_fixed_size: 4352
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_zero_128x8
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_zero_128x8.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     28
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
    .group_segment_fixed_size: 12288
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_zero_128x256
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_zero_128x256.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     50
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
    .group_segment_fixed_size: 4352
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_disabled_first_output
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matrix_disabled_first_output.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     29
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
    .group_segment_fixed_size: 8448
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_disabled_lds_read
    .private_segment_fixed_size: 0
    .sgpr_count:     10
    .sgpr_spill_count: 0
    .symbol:         matrix_disabled_lds_read.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     32
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
    .group_segment_fixed_size: 34816
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_mixed408
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_mixed408.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     30
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
    .group_segment_fixed_size: 34816
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 256
    .name:           matrix_wrong_b476
    .private_segment_fixed_size: 0
    .sgpr_count:     8
    .sgpr_spill_count: 0
    .symbol:         matrix_wrong_b476.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     30
    .vgpr_spill_count: 0
    .wavefront_size: 32
amdhsa.target:   amdgcn-amd-amdhsa--gfx1250
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
