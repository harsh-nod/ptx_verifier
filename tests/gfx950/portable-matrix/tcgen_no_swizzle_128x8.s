// Native matrix/layout counterpart: tcgen_no_swizzle_128x8.
// Explicit gfx950 AMDHSA x/out ABI. See cases.json for original contracts.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.p2align 8
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_and_b32 v1,63,v0
v_lshrrev_b32 v2,6,v0
v_and_b32 v3,15,v1
v_lshl_add_u32 v20,v2,4,v3
v_lshrrev_b32 v6,4,v1
v_mov_b32 v4,0
v_mov_b32 v5,0
v_cmp_eq_u32 vcc,0,v20
v_cndmask_b32 v4,0,v4,vcc
v_cndmask_b32 v5,0,v5,vcc
v_lshlrev_b32 v21,5,v20
v_lshl_add_u32 v21,v6,3,v21
ds_write_b64 v21,v[4:5]
v_mov_b32 v8,0
v_mov_b32 v9,0
v_lshlrev_b32 v22,5,v3
v_lshl_add_u32 v22,v6,3,v22
v_add_u32 v22,4096,v22
v_cmp_lt_u32 vcc,v0,64
s_and_saveexec_b64 s[8:9],vcc
ds_write_b64 v22,v[8:9]
s_mov_b64 exec,s[8:9]
s_waitcnt lgkmcnt(0)
s_barrier
ds_read_b64 v[4:5],v21
ds_read_b64 v[8:9],v22
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
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
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:32
global_store_dword v2,v14,s[6:7] offset:64
global_store_dword v2,v15,s[6:7] offset:96
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 4608
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
    .group_segment_fixed_size: 4608
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
