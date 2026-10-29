# Actual original32 opcode and modifier profiles

This generated index complements [stage-support.md](stage-support.md). Its typed frontend and lowering checks do not execute instructions. Value/event/checker contracts and named positive/negative family controls are linked in [stage-profiles.json](stage-profiles.json); each profile links its actual source entries and all32 retain separate full CLI/Python acceptance gates.

The seven compiler modules contain 185 mnemonics and 497 typed profiles across 13239 component occurrences. Both VOPD slots are indexed separately. A profile records operand shapes and exact named modifiers; it does not enable every immediate, register index or combination with those shapes.

Regenerate with `python3 tests/gfx1250/full-parity/generate_stage_profiles.py`; use `--check` to reject drift.

| Native opcode | Exact modifier sets | Profiles | Semantic contracts | Original cases |
| --- | --- | --- | --- | --- |
| `ds_bpermute_b32` | none | 1 | permutation | W09, W11, W12, W13, W14, W15, W16, W17, W18, W21, W22, W23, W24 |
| `ds_load_b128` | none; offset:1024; offset:1056; offset:16384; offset:16416; offset:2048; offset:2080; offset:3072; offset:3104; offset:32; offset:4096; offset:4128; offset:5120; offset:5152; offset:6144; offset:6176; offset:64; offset:7168; offset:7200; offset:96 | 20 | memory | W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `ds_load_b32` | none | 1 | memory | W11, W12 |
| `ds_load_b96` | offset:32; offset:96 | 2 | memory | W21 |
| `ds_load_u16` | none; offset:108; offset:128; offset:160; offset:192; offset:224; offset:32; offset:384; offset:416; offset:44; offset:448; offset:480; offset:64; offset:640; offset:672; offset:704; offset:736; offset:896; offset:928; offset:96; offset:960; offset:992 | 22 | memory | W15, W21, W22, W23, W24 |
| `ds_load_u8` | offset:32 | 1 | memory | W16 |
| `ds_store_b128` | none; offset:16; offset:32; offset:48 | 4 | memory | W31, W32 |
| `ds_store_b16` | none; offset:1024; offset:10240; offset:12288; offset:128; offset:1280; offset:14336; offset:1536; offset:160; offset:16384; offset:16896; offset:17408; offset:1792; offset:17920; offset:18432; offset:192; offset:2048; offset:224; offset:2304; offset:256; offset:2560; offset:2816; offset:3072; offset:32; offset:32768; offset:3328; offset:34816; offset:3584; offset:36864; offset:384; offset:3840; offset:38912; offset:4096; offset:40960; offset:43008; offset:45056; offset:47104; offset:512; offset:6144; offset:64; offset:768; offset:8192; offset:96 | 43 | memory | W15, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `ds_store_b16_d16_hi` | offset:128; offset:384 | 2 | memory | W25, W26 |
| `ds_store_b32` | none | 1 | memory | W11, W12 |
| `ds_store_b8` | none; offset:128; offset:256; offset:384; offset:512; offset:640; offset:768; offset:896 | 8 | memory | W16 |
| `global_atomic_add_f32` | scale_offset, scope:SCOPE_DEV | 1 | atomic | W17, W18 |
| `global_load_b128` | none; offset:1024, scale_offset; offset:1536, scale_offset; offset:16; offset:32; offset:512, scale_offset; offset:64; offset:96; scale_offset | 9 | memory | W01, W07, W11, W13, W17, W18, W21, W22, W23, W26 |
| `global_load_b32` | none; offset:12, scale_offset; offset:128; offset:16, scale_offset; offset:20, scale_offset; offset:24, scale_offset; offset:28, scale_offset; offset:4, scale_offset; offset:8, scale_offset; scale_offset | 11 | memory | W06, W08, W21, W22, W24, W25, W26, W31, W32 |
| `global_load_b64` | none; offset:16; offset:32; offset:48; scale_offset | 5 | memory | W02, W03, W04, W05, W12, W14, W24 |
| `global_load_b96` | offset:32; offset:96 | 2 | memory | W21 |
| `global_load_i8` | none | 1 | memory | W24 |
| `global_load_u16` | none; offset:1024; offset:108; offset:1280; offset:1536; offset:1792; offset:256; offset:44; offset:512; offset:768; scale_offset | 11 | memory | W09, W15, W19, W21, W22, W23, W24, W25, W26, W27, W29, W31, W32 |
| `global_load_u8` | none | 2 | memory | W10, W16, W20, W28, W30 |
| `global_store_b128` | none; scale_offset | 2 | memory | W01, W02, W04, W07, W11, W12, W13, W14 |
| `global_store_b16` | none; offset:10240; offset:12288; offset:128; offset:128, scale_offset; offset:14336; offset:160; offset:160, scale_offset; offset:16384, scale_offset; offset:192; offset:192, scale_offset; offset:2048; offset:224; offset:224, scale_offset; offset:24576, scale_offset; offset:32; offset:32, scale_offset; offset:32768, scale_offset; offset:4096; offset:40960, scale_offset; offset:49152, scale_offset; offset:57344, scale_offset; offset:6144; offset:64; offset:64, scale_offset; offset:8192; offset:8192, scale_offset; offset:96; offset:96, scale_offset; scale_offset | 30 | memory | W09, W10, W15, W16, W19, W20, W22, W23, W24, W26, W27, W28, W29, W30, W31, W32 |
| `global_store_b32` | none; offset:1024; offset:10240; offset:10752; offset:11264; offset:11776; offset:12, scale_offset; offset:128; offset:1536; offset:16, scale_offset; offset:192; offset:20, scale_offset; offset:2048; offset:24, scale_offset; offset:256; offset:2560; offset:28, scale_offset; offset:3072; offset:320; offset:3584; offset:384; offset:4, scale_offset; offset:448; offset:512; offset:64; offset:8, scale_offset; offset:8192; offset:8704; offset:9216; offset:9728; scale_offset | 31 | memory | W21, W22, W23, W25 |
| `global_store_b64` | scale_offset | 1 | memory | W03, W05, W06, W08 |
| `s_add_co_i32` | none | 2 | scalar | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_add_f32` | none | 1 | scalar | W17, W18 |
| `s_add_nc_u64` | none | 1 | scalar | W18, W24, W25, W26, W32 |
| `s_addk_co_i32` | none | 1 | scalar | W22, W23, W24 |
| `s_and_b32` | none | 6 | scalar | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_and_not1_b32` | none | 3 | scalar | W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_and_not1_saveexec_b32` | none | 1 | scalar | W19 |
| `s_and_saveexec_b32` | none | 2 | scalar | W15, W16, W19, W21, W22, W23, W25, W26, W31, W32 |
| `s_barrier_signal` | none | 1 | barrier | W11, W12, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_barrier_wait` | none | 1 | barrier | W11, W12, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_bfe_u32` | none | 2 | scalar | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_bitcmp1_b32` | none | 1 | scalar | W23 |
| `s_bitset1_b32` | none | 1 | scalar | W23 |
| `s_branch` | none | 1 | branch | W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_brev_b32` | none | 1 | scalar | W17, W18 |
| `s_cbranch_execnz` | none | 1 | branch | W13, W14, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W32 |
| `s_cbranch_execz` | none | 1 | branch | W11, W12, W13, W14, W15, W16, W17, W18, W19, W21, W22, W23, W25, W26, W31, W32 |
| `s_cbranch_scc0` | none | 1 | branch | W24 |
| `s_cbranch_scc1` | none | 1 | branch | W17, W18, W19, W20, W21, W22, W23, W24 |
| `s_cbranch_vccnz` | none | 1 | branch | W19, W20, W23, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_cbranch_vccz` | none | 1 | branch | W23, W26, W27, W31 |
| `s_clause` | none | 1 | control | W07, W08, W09, W11, W12, W15, W16, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W31, W32 |
| `s_cmp_eq_u32` | none | 2 | scalar | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_cmp_ge_u32` | none | 1 | scalar | W23 |
| `s_cmp_gt_u32` | none | 1 | scalar | W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_cmp_lg_u32` | none | 1 | scalar | W17, W18, W23, W24 |
| `s_cmp_lt_u32` | none | 1 | scalar | W21 |
| `s_cselect_b32` | none | 4 | scalar | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_ctz_i32_b32` | none | 1 | scalar | W17, W18 |
| `s_delay_alu` | none | 1 | control | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_endpgm` | none | 1 | control | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_getreg_b32` | none | 1 | hardware_abi | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_load_b128` | none | 1 | memory | W01, W02, W03, W04, W05, W06, W07, W08, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W22, W23, W24, W26, W27, W28, W31, W32 |
| `s_load_b256` | none | 1 | memory | W09, W10, W22, W24, W25, W26, W29, W30 |
| `s_load_b32` | none; offset:0x3fc, scale_offset | 2 | memory | W13, W14, W23, W25 |
| `s_load_b512` | none | 1 | memory | W21 |
| `s_load_b64` | none | 1 | memory | W07, W08, W11, W12, W15, W16, W19, W20, W23, W25, W27, W28, W31, W32 |
| `s_load_b96` | none | 1 | memory | W13, W14 |
| `s_lshl_b32` | none | 2 | scalar | W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_lshl_b64` | none | 1 | scalar | W24, W25, W26, W32 |
| `s_lshr_b32` | none | 2 | scalar | W22, W23, W24, W25, W26, W31, W32 |
| `s_max_u32` | none | 1 | scalar | W23 |
| `s_mov_b32` | none | 3 | scalar | W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_movk_i32` | none | 1 | scalar | W25, W26 |
| `s_mul_i32` | none | 2 | scalar | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_nor_b32` | none | 1 | scalar | W19 |
| `s_or_b32` | none | 3 | scalar | W11, W12, W13, W14, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_sendmsg` | none | 1 | release | W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_wait_dscnt` | none | 1 | wait | W09, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_wait_kmcnt` | none | 1 | wait | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_wait_loadcnt` | none | 1 | wait | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_wait_loadcnt_dscnt` | none | 1 | wait | W11, W12, W15, W22, W23 |
| `s_wait_storecnt` | none | 1 | wait | W19, W20, W22, W23, W24 |
| `s_wait_storecnt_dscnt` | none | 1 | wait | W27 |
| `s_wait_xcnt` | none | 1 | wait | W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `s_xor_b32` | none | 2 | scalar | W17, W18, W19, W20, W21, W23, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_add3_u32` | none | 3 | vector | W19, W20, W22, W23, W24, W31 |
| `v_add_co_u32` | none | 1 | vector | W19 |
| `v_add_f32` | none | 6 | vector | W03, W04, W05, W06, W07, W08, W11, W12, W13, W14, W15, W16, W17, W18, W29, W30 |
| `v_add_f32_e32` | none | 3 | vector | W07, W11, W12, W13, W14, W15, W16, W17, W18, W21, W22, W29, W30 |
| `v_add_lshl_u32` | none | 3 | vector | W25, W26, W31 |
| `v_add_nc_u32` | none | 6 | vector | W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W31, W32 |
| `v_add_nc_u32_e32` | none | 3 | vector | W02, W11, W12, W13, W14, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_add_nc_u64_e32` | none | 3 | vector | W13, W14, W15, W16, W21, W23, W24, W25, W26, W31, W32 |
| `v_alignbit_b32` | none | 1 | vector | W06, W13, W14 |
| `v_and_b32_e32` | none | 2 | vector | W09, W10, W11, W12, W13, W14, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_and_or_b32` | none | 3 | vector | W19, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_ashrrev_i16` | none | 1 | vector | W24 |
| `v_bfe_i32` | none | 1 | vector | W24 |
| `v_bfe_u32` | none | 1 | vector | W14 |
| `v_bitop3_b32` | bitop3:0x14; bitop3:0x40; bitop3:0x54; bitop3:0xc8; bitop3:0xf6 | 7 | vector | W09, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_cmp_eq_u32_e32` | none | 1 | vector | W09, W15, W16, W17, W18, W19, W22, W25, W26, W31, W32 |
| `v_cmp_eq_u32_e64` | none | 1 | vector | W23 |
| `v_cmp_gt_i32_e32` | none | 1 | vector | W09, W11, W12, W13, W14, W15, W16, W17, W18 |
| `v_cmp_gt_u32_e32` | none | 1 | vector | W10, W21 |
| `v_cmp_gt_u32_e64` | none | 1 | vector | W23, W31 |
| `v_cmp_le_u32_e32` | none | 1 | vector | W13, W14 |
| `v_cmp_lt_f16_e32` | none | 1 | vector | W01 |
| `v_cmp_lt_i32_e32` | none | 2 | vector | W11, W12, W22, W23, W24, W31, W32 |
| `v_cmp_lt_i32_e64` | none | 1 | vector | W21 |
| `v_cmp_lt_u32_e32` | none | 1 | vector | W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W32 |
| `v_cmp_lt_u32_e64` | none | 1 | vector | W15, W16, W19, W21 |
| `v_cmp_ne_u32_e64` | none | 1 | vector | W25, W26 |
| `v_cmpx_eq_u32_e32` | none | 1 | vector | W11, W12, W17, W18, W21 |
| `v_cmpx_gt_u32_e32` | none | 1 | vector | W17, W18, W31 |
| `v_cmpx_gt_u32_e64` | none | 1 | vector | W13, W14 |
| `v_cmpx_ne_u32_e32` | none | 1 | vector | W15 |
| `v_cmpx_ne_u32_e64` | none | 2 | vector | W15, W16, W26 |
| `v_cndmask_b32` | none | 2 | vector | W11, W12, W14, W15, W16, W17, W18, W24 |
| `v_cndmask_b32_e32` | none | 2 | vector | W01, W09, W11, W12, W13, W14, W15, W16, W17, W18, W22, W23, W24, W31, W32 |
| `v_cndmask_b32_e64` | none | 7 | vector | W09, W10, W11, W12, W13, W15, W16, W19, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W32 |
| `v_cvt_f16_f32_e32` | none | 1 | vector | W10, W13, W15, W16, W19, W20, W22, W23, W24, W26, W27, W28, W30, W31, W32 |
| `v_cvt_f16_i16_e32` | none | 1 | vector | W24 |
| `v_cvt_f32_f16_e32` | none | 1 | vector | W03, W05, W07, W09, W11, W13, W17, W25, W29, W30 |
| `v_cvt_f32_f16_e64` | none | 1 | vector | W25 |
| `v_cvt_f32_fp8_e32` | none | 1 | vector | W02, W04, W06, W08, W10, W12, W14, W16, W18, W20, W28, W30 |
| `v_cvt_f32_fp8_e64` | byte_sel:1; byte_sel:2; byte_sel:3 | 3 | vector | W02, W04, W06, W08, W12, W14, W18 |
| `v_cvt_pk_f16_f32` | none | 1 | vector | W02, W03, W04, W05, W06, W07, W08, W11, W12, W13, W14, W25, W26 |
| `v_exp_f32_e32` | none | 1 | vector | W03, W04, W05, W06, W07, W08, W13, W14, W21, W22, W23, W24, W25, W26, W29, W30 |
| `v_fma_f32` | none | 3 | vector | W23, W24 |
| `v_fma_mix_f32` | op_sel_hi:[1,1,0] | 1 | vector | W15 |
| `v_fma_mixhi_f16` | none | 1 | vector | W13, W14 |
| `v_fma_mixlo_f16` | none; op_sel_hi:[0,1,0]; op_sel_hi:[1,1,0] | 5 | vector | W06, W09, W10, W13, W14, W22, W23, W24, W25, W26, W29, W30 |
| `v_fmaak_f32` | none | 1 | vector | W11, W12 |
| `v_fmac_f16_e32` | none | 1 | vector | W10 |
| `v_fmac_f32` | none | 4 | vector | W12, W16, W21, W22 |
| `v_fmac_f32_e32` | none | 3 | vector | W12, W21, W23 |
| `v_fmamk_f32` | none | 3 | vector | W21, W22 |
| `v_log_f32_e32` | none | 1 | vector | W21, W22, W23 |
| `v_lshl_add_u32` | none | 3 | vector | W01, W02, W03, W04, W05, W06, W07, W08, W09, W10, W11, W12, W13, W14, W15, W16, W19, W20, W21, W22, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_lshl_add_u64` | none | 2 | vector | W11, W12, W13, W14, W15, W19, W22, W23, W26, W27, W29, W31 |
| `v_lshl_or_b32` | none | 5 | vector | W09, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_lshlrev_b32` | none | 2 | vector | W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_lshlrev_b32_e32` | none | 1 | vector | W09, W11, W12, W13, W14, W15, W16, W17, W19, W20, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_lshlrev_b64_e32` | none | 1 | vector | W23 |
| `v_lshrrev_b16` | none | 1 | vector | W19, W20 |
| `v_lshrrev_b32` | none | 2 | vector | W03, W05, W07, W09, W11, W12, W13, W15, W17, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_lshrrev_b32_e32` | none | 1 | vector | W01, W07, W11, W13, W14, W15, W16, W17, W19, W20, W24, W25, W26, W27, W29, W31, W32 |
| `v_mad_u32` | none | 1 | vector | W19, W20 |
| `v_max3_num_f16` | none | 1 | vector | W13 |
| `v_max3_num_f32` | none | 1 | vector | W14 |
| `v_max_num_f16_e32` | none | 1 | vector | W13 |
| `v_max_num_f32` | none | 4 | vector | W02, W14, W21, W22, W23, W24 |
| `v_max_num_f32_e32` | none | 2 | vector | W02, W13, W14, W21, W22, W23, W24 |
| `v_mbcnt_lo_u32_b32` | none | 2 | vector | W09, W11, W12, W13, W14, W15, W16, W17, W18, W21, W22, W23, W24 |
| `v_min_num_f32_e32` | none | 1 | vector | W25, W26 |
| `v_mov_b32` | none | 6 | vector | W13, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_mov_b32_e32` | none | 3 | vector | W11, W12, W13, W14, W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_mov_b64_e32` | none | 1 | vector | W15, W16, W19, W21, W25, W26 |
| `v_mul_f16_e32` | none | 2 | vector | W10 |
| `v_mul_f32` | none | 5 | vector | W03, W04, W05, W06, W07, W08, W12, W13, W14, W21, W23, W24, W25, W26 |
| `v_mul_f32_e32` | none | 3 | vector | W07, W09, W13, W14, W21, W22, W23, W24, W25, W26, W29, W30 |
| `v_mul_hi_u32` | none | 1 | vector | W19, W20 |
| `v_mul_lo_u16` | none | 2 | vector | W19, W20 |
| `v_mul_lo_u32` | none | 2 | vector | W13, W14, W19, W20 |
| `v_mul_u32_u24_e32` | none | 1 | vector | W19, W20 |
| `v_mul_u32_u24_e64` | none | 1 | vector | W19 |
| `v_nop` | none | 1 | control | W07, W11, W12, W13, W14, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_or3_b32` | none | 8 | vector | W15, W16, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_or_b32_e32` | none | 3 | vector | W15, W16, W17, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_pack_b32_f16` | none | 1 | vector | W06, W13, W14, W24, W31, W32 |
| `v_perm_b32` | none | 1 | vector | W01, W19, W21, W22, W23, W24 |
| `v_pk_add_f32` | none | 1 | vector | W21, W22, W23, W24 |
| `v_pk_fma_f32` | none | 1 | vector | W21, W22, W23, W24 |
| `v_pk_max_num_f16` | none | 2 | vector | W01 |
| `v_pk_mul_f32` | none; op_sel_hi:[0,1] | 2 | vector | W05, W06, W07, W08, W11, W12, W13, W14, W22, W23, W24, W25 |
| `v_pk_mul_lo_u16` | op_sel_hi:[1,0] | 1 | vector | W19 |
| `v_pk_sub_i16` | none | 1 | vector | W19 |
| `v_rcp_f32_e32` | none | 1 | vector | W03, W04, W05, W06, W07, W08, W13, W14, W22, W23, W24, W29, W30 |
| `v_readlane_b32` | none | 1 | vector | W17, W18 |
| `v_rsq_f32_e32` | none | 1 | vector | W11, W12 |
| `v_sub_f16_e32` | none | 1 | vector | W13 |
| `v_sub_f32` | none | 2 | vector | W14, W21, W22, W23, W24 |
| `v_sub_f32_e32` | none | 2 | vector | W14, W21, W22, W23, W24, W25, W26 |
| `v_sub_nc_u16` | none | 1 | vector | W19, W20 |
| `v_sub_nc_u32` | none | 3 | vector | W15, W19, W20 |
| `v_sub_nc_u32_e32` | none | 2 | vector | W15, W16, W19, W20 |
| `v_subrev_co_u32` | none | 1 | vector | W32 |
| `v_subrev_nc_u32_e32` | none | 1 | vector | W25, W26 |
| `v_wmma_f32_16x16x32_f16` | none | 2 | matrix | W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31, W32 |
| `v_xad_u32` | none | 1 | vector | W22, W24 |
| `v_xor_b32_e32` | none | 1 | vector | W09, W10, W11, W12, W13, W14, W15, W16, W17, W18, W21, W23 |
