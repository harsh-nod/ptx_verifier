// Native matrix/layout counterpart: ldmatrix_four_fragment_pairs.
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
global_load_dword v4,v2,s[4:5] offset:0
global_load_dword v5,v2,s[4:5] offset:128
global_load_dword v6,v2,s[4:5] offset:256
global_load_dword v7,v2,s[4:5] offset:384
s_waitcnt vmcnt(0)
ds_write_b32 v2,v4 offset:0
ds_write_b32 v2,v5 offset:128
ds_write_b32 v2,v6 offset:256
ds_write_b32 v2,v7 offset:384
s_waitcnt lgkmcnt(0)
s_barrier
ds_read_b32 v12,v2 offset:0
ds_read_b32 v13,v2 offset:128
ds_read_b32 v14,v2 offset:256
ds_read_b32 v15,v2 offset:384
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v2,4,v0
global_store_dwordx4 v2,v[12:15],s[6:7]
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 1024
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
    .group_segment_fixed_size: 1024
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
