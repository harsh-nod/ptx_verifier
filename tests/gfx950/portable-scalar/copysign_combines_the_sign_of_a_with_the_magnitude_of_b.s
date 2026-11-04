// Native counterpart: crates/volta_pipeline/tests/ptx/success/copysign_combines_the_sign_of_a_with_the_magnitude_of_b.ptx
// Actual AMDHSA x/out ABI; exact real-number arithmetic contract.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.p2align 8
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_mov_b32 v2,0
v_mov_b32 v4,0x40000000
v_mov_b32 v5,0x40400000
v_and_b32 v6,0x80000000,v4
v_and_b32 v7,0x7fffffff,v5
v_or_b32 v8,v6,v7
v_add_f32 v8,v8,0.0
v_mov_b32 v4,0xc0000000
v_and_b32 v6,0x80000000,v4
v_or_b32 v9,v6,v7
v_add_f32 v9,v9,0.0
v_mov_b32 v4,0x40000000
v_mov_b32 v5,0xc0400000
v_and_b32 v6,0x80000000,v4
v_and_b32 v7,0x7fffffff,v5
v_or_b32 v10,v6,v7
v_add_f32 v10,v10,0.0
v_mov_b32 v4,0xc0000000
v_and_b32 v6,0x80000000,v4
v_or_b32 v7,v6,v7
v_add_f32 v7,v7,0.0
v_add_f32 v8,v8,v10
v_add_f32 v9,v9,v7
v_add_f32 v10,v8,v9
global_store_dword v2,v10,s[6:7] offset:0
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 0
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
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .wavefront_size: 64
    .sgpr_count: 18
    .vgpr_count: 32
    .max_flat_workgroup_size: 64
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
