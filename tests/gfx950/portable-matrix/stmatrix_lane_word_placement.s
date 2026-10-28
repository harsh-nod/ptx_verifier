// Native matrix/layout counterpart: stmatrix_lane_word_placement.
// Explicit gfx950 AMDHSA x/out ABI. See cases.json for original contracts.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_lshrrev_b32 v3,2,v0
v_lshlrev_b32 v3,4,v3
v_and_b32 v4,3,v0
v_lshl_add_u32 v3,v4,2,v3
v_add_u32 v5,1000,v0
ds_write_b32 v3,v5
s_waitcnt lgkmcnt(0)
s_barrier
ds_read_b32 v8,v3
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v2,2,v0
global_store_dword v2,v8,s[6:7] offset:4
v_cmp_eq_u32 vcc,0,v0
s_and_saveexec_b64 s[8:9],vcc
v_mov_b32 v3,20
ds_read_b32 v8,v3
s_waitcnt lgkmcnt(0)
v_mov_b32 v2,0
global_store_dword v2,v8,s[6:7]
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 128
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
    .group_segment_fixed_size: 128
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
