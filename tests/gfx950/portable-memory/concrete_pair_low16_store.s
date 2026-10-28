// Portable native payload: exact legal low16 truncation of a concrete pair.
// PTX deliberately rejects this Pair sub-width store; native truncation is legal and retains neighbor bytes.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_mov_b32 v2,0
v_add_u32 v4,1,0
v_add_u32 v5,2,0
ds_write_b16 v2,v4
ds_write_b16 v2,v5 offset:2
s_waitcnt lgkmcnt(0)
ds_read_b32 v8,v2
s_waitcnt lgkmcnt(0)
ds_write_b16 v2,v8 offset:4
s_waitcnt lgkmcnt(0)
ds_read_u16 v8,v2
ds_read_u16 v9,v2 offset:2
ds_read_u16 v10,v2 offset:4
s_waitcnt lgkmcnt(0)
v_cvt_f32_u32 v12,v8
v_cvt_f32_u32 v13,v9
v_cvt_f32_u32 v14,v10
global_store_dwordx3 v2,v[12:14],s[6:7]
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 6
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 16
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 16
.amdhsa_next_free_vgpr 32
.amdhsa_accum_offset 32
.amdhsa_reserve_vcc 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .group_segment_fixed_size: 6
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .wavefront_size: 64
    .sgpr_count: 18
    .vgpr_count: 32
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
