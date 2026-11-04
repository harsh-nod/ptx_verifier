// Native matrix/layout counterpart: wmma_fragment_stride64.
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
v_lshlrev_b32 v2,3,v0
global_load_dwordx2 v[4:5],v2,s[4:5]
s_waitcnt vmcnt(0)
v_lshrrev_b32 v3,2,v0
v_mul_lo_u32 v3,64,v3
v_and_b32 v6,3,v0
v_lshl_add_u32 v3,v6,3,v3
ds_write_b64 v3,v[4:5]
s_waitcnt lgkmcnt(0)
s_barrier
v_and_b32 v3,15,v0
v_mul_lo_u32 v3,64,v3
v_lshrrev_b32 v6,4,v0
v_lshl_add_u32 v3,v6,3,v3
ds_read_b64 v[4:5],v3
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v6,2,v6
v_add_u32 v7,1,v6
v_cvt_f32_u32 v7,v7
v_cvt_f16_f32 v8,v7
v_add_u32 v7,2,v6
v_cvt_f32_u32 v7,v7
v_cvt_f16_f32 v9,v7
v_add_u32 v7,3,v6
v_cvt_f32_u32 v7,v7
v_cvt_f16_f32 v10,v7
v_add_u32 v7,4,v6
v_cvt_f32_u32 v7,v7
v_cvt_f16_f32 v11,v7
v_pack_b32_f16 v8,v8,v9
v_pack_b32_f16 v9,v10,v11
s_nop 3
v_mfma_f32_16x16x16f16 v[12:15],v[4:5],v[8:9],0
s_nop 15
s_nop 15
v_and_b32 v2,15,v0
v_lshlrev_b32 v2,2,v2
v_and_b32 v3,48,v0
v_lshl_add_u32 v2,v3,4,v2
global_store_dword v2,v12,s[6:7]
global_store_dword v2,v13,s[6:7] offset:64
global_store_dword v2,v14,s[6:7] offset:128
global_store_dword v2,v15,s[6:7] offset:192
v_lshlrev_b32 v2,3,v0
global_store_dwordx2 v2,v[4:5],s[6:7] offset:1024
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 2048
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
    .group_segment_fixed_size: 2048
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
