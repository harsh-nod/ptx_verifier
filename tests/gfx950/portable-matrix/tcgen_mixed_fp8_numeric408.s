// Native matrix/layout counterpart: tcgen_mixed_fp8_numeric408.
// Explicit gfx950 AMDHSA x/out ABI. See cases.json for original contracts.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_and_b32 v1,63,v0
v_lshrrev_b32 v2,6,v0
v_and_b32 v3,15,v1
v_lshl_add_u32 v20,v2,4,v3
v_lshrrev_b32 v21,4,v1
v_mov_b32 v4,0
v_mov_b32 v5,0
v_mov_b32 v6,0
v_mov_b32 v7,0
v_mov_b32 v8,0
v_mov_b32 v9,0
v_mov_b32 v10,0
v_mov_b32 v11,0
v_mov_b32 v12,0
v_mov_b32 v13,0
v_mov_b32 v14,0
v_mov_b32 v15,0
v_mov_b32 v16,0
v_mov_b32 v17,0
v_mov_b32 v18,0
v_mov_b32 v19,0
v_mov_b32 v4,0x48444038
v_mov_b32 v5,0x504e4c4a
v_mov_b32 v6,0x54535251
v_mov_b32 v7,0x58575655
v_cmp_eq_u32 vcc,0,v20
v_cndmask_b32 v4,0,v4,vcc
v_cndmask_b32 v5,0,v5,vcc
v_cndmask_b32 v6,0,v6,vcc
v_cndmask_b32 v7,0,v7,vcc
v_cmp_eq_u32 vcc,0,v21
v_mov_b32 v30,0x3c3c3c3c
v_cndmask_b32 v12,0,v30,vcc
v_cmp_eq_u32 vcc,1,v21
v_mov_b32 v30,0x40404040
v_cndmask_b32 v12,v12,v30,vcc
v_cmp_eq_u32 vcc,0,v3
v_cndmask_b32 v12,0,v12,vcc
v_mov_b32 v13,v12
v_mov_b32 v14,v12
v_mov_b32 v15,v12
v_lshlrev_b32 v22,8,v20
v_lshl_add_u32 v22,v21,7,v22
v_lshlrev_b32 v23,8,v3
v_lshl_add_u32 v23,v21,7,v23
v_add_u32 v23,32768,v23
v_cmp_lt_u32 vcc,v21,2
s_and_saveexec_b64 s[8:9],vcc
ds_write_b128 v22,v[4:7]
v_cmp_lt_u32 vcc,v0,64
s_and_saveexec_b64 s[10:11],vcc
ds_write_b128 v23,v[12:15]
s_mov_b64 exec,s[10:11]
s_mov_b64 exec,s[8:9]
s_waitcnt lgkmcnt(0)
s_barrier
v_mov_b32 v4,0
v_mov_b32 v5,0
v_mov_b32 v6,0
v_mov_b32 v7,0
v_mov_b32 v12,0
v_mov_b32 v13,0
v_mov_b32 v14,0
v_mov_b32 v15,0
v_cmp_lt_u32 vcc,v21,2
s_and_saveexec_b64 s[8:9],vcc
ds_read_b128 v[4:7],v22
ds_read_b128 v[12:15],v23
s_waitcnt lgkmcnt(0)
s_mov_b64 exec,s[8:9]
v_mov_b32 v28,0x7f
s_nop 3
v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27],v[4:11],v[12:19],0,v28,v28 op_sel_hi:[0,0,0] blgp:1
s_nop 15
s_nop 15
v_lshrrev_b32 v2,6,v0
v_lshlrev_b32 v2,4,v2
v_lshrrev_b32 v3,4,v1
v_lshl_add_u32 v2,v3,2,v2
v_lshlrev_b32 v2,5,v2
v_and_b32 v3,15,v1
v_lshl_add_u32 v2,v3,2,v2
v_cmp_lt_u32 vcc,v3,8
s_and_saveexec_b64 s[8:9],vcc
global_store_dword v2,v24,s[6:7]
global_store_dword v2,v25,s[6:7] offset:32
global_store_dword v2,v26,s[6:7] offset:64
global_store_dword v2,v27,s[6:7] offset:96
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 36864
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 16
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 16
.amdhsa_next_free_vgpr 64
.amdhsa_accum_offset 64
.amdhsa_reserve_vcc 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .group_segment_fixed_size: 36864
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .wavefront_size: 64
    .sgpr_count: 18
    .vgpr_count: 64
    .max_flat_workgroup_size: 1024
    .args:
      - .name: x
        .address_space: global
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .address_space: global
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
