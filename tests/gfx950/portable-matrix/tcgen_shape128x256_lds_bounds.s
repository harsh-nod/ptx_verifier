// Native matrix/layout counterpart: tcgen_shape128x256_lds_bounds.
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
v_lshlrev_b32 v2,2,v0
v_mov_b32 v4,0
ds_write_b32 v2,v4
ds_write_b32 v2,v4 offset:4096
ds_write_b32 v2,v4 offset:8192
s_waitcnt lgkmcnt(0)
s_barrier
v_and_b32 v1,63,v0
v_lshrrev_b32 v20,6,v0
v_and_b32 v21,7,v20
v_and_b32 v3,15,v1
v_lshl_add_u32 v21,v21,4,v3
v_lshlrev_b32 v21,5,v21
v_lshrrev_b32 v22,4,v1
v_lshl_add_u32 v21,v22,3,v21
ds_read_b64 v[4:5],v21
v_lshrrev_b32 v23,3,v20
v_lshlrev_b32 v23,7,v23
v_and_b32 v24,7,v20
v_lshlrev_b32 v24,4,v24
v_lshl_add_u32 v24,v22,2,v24
v_lshlrev_b32 v24,10,v24
v_add_u32 v25,0,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,16,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,32,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,48,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,64,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,80,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,96,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072
v_add_u32 v25,112,v23
v_and_b32 v3,15,v1
v_add_u32 v25,v25,v3
v_lshlrev_b32 v26,5,v25
v_lshl_add_u32 v26,v22,3,v26
v_add_u32 v26,4096,v26
ds_read_b64 v[8:9],v26
s_waitcnt lgkmcnt(0)
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_lshl_add_u32 v2,v25,2,v24
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:1024
global_store_dword v2,v14,s[6:7] offset:2048
global_store_dword v2,v15,s[6:7] offset:3072

s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 49168
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
    .group_segment_fixed_size: 49168
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
