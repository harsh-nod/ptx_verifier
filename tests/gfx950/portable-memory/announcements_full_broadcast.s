// Portable native payload: a completed two-chunk producer copy is broadcast as all64 outputs=in4.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_dwordx4 s[4:7],s[0:1],0
s_waitcnt lgkmcnt(0)
v_mov_b32 v2,0
v_cmp_lt_u32 vcc,v0,64
s_cbranch_vccz .Lpublish
s_and_b64 exec,exec,1
global_load_dwordx4 v[8:11],v2,s[4:5]
s_waitcnt vmcnt(0)
ds_write_b128 v2,v[8:11]
s_waitcnt lgkmcnt(0)
global_load_dwordx4 v[8:11],v2,s[4:5] offset:16
s_waitcnt vmcnt(0)
ds_write_b128 v2,v[8:11] offset:16
s_waitcnt lgkmcnt(0)
.Lpublish:
s_barrier
v_cmp_ge_u32 vcc,v0,64
s_and_b64 exec,exec,vcc
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
s_nop 0
ds_read_b32 v12,v2 offset:16
s_waitcnt lgkmcnt(0)
v_sub_u32 v10,v0,64
v_lshlrev_b32 v10,2,v10
global_store_dword v10,v12,s[6:7]
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 32
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
    .group_segment_fixed_size: 32
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
