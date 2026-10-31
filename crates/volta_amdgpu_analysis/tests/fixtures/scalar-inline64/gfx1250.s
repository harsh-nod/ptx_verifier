.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_wait_kmcnt 0
s_mov_b64 s[8:9],1.0
v_mov_b32 v0,0
v_mov_b32 v1,s8
v_mov_b32 v2,s9
v_add_nc_u32 v1,0,v1
v_add_nc_u32 v2,0,v2
global_store_b32 v0,v1,s[4:5]
global_store_b32 v0,v2,s[4:5] offset:4
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.rodata
.p2align 6
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.amdhsa_next_free_vgpr 4
.amdhsa_next_free_sgpr 10
.end_amdhsa_kernel

.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .kernarg_segment_size: 8
    .kernarg_segment_align: 8
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .sgpr_count: 10
    .vgpr_count: 4
    .max_flat_workgroup_size: 1
    .wavefront_size: 32
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .address_space: global
        .value_kind: global_buffer
...
.end_amdgpu_metadata
