// Portable native payload: masked_matrix_publication.
// Every native MFMA participant executes under full EXEC; the later publication mask omits only D[0][0]. Native LDS definedness replaces target-specific output-lane/TMEM storage behavior.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_cmp_lt_u32 vcc,v0,64
s_cbranch_vccz .Lconsumer
v_mov_b32 v8,1.0
v_mov_b32 v9,2.0
v_mov_b32 v12,3.0
v_mov_b32 v13,3.0
v_mov_b32 v14,3.0
v_mov_b32 v15,3.0
s_nop 1
v_mfma_f32_16x16x4_f32 v[12:15],v8,v9,v[12:15]
s_nop 9
v_and_b32 v2,15,v0
v_lshlrev_b32 v2,2,v2
v_and_b32 v3,48,v0
v_lshl_add_u32 v2,v3,4,v2
v_cmp_ne_u32 vcc,v0,0
s_and_saveexec_b64 s[8:9],vcc
ds_write_b32 v2,v12
s_mov_b64 exec,s[8:9]
ds_write_b32 v2,v13 offset:64
ds_write_b32 v2,v14 offset:128
ds_write_b32 v2,v15 offset:192
s_waitcnt lgkmcnt(0)
s_branch .Lpublication
.Lconsumer:
v_mov_b32 v2,0
.Lpublication:
s_barrier
v_cmp_ge_u32 vcc,v0,64
s_cbranch_vccz .Ldone
v_sub_u32 v2,v0,64
v_lshlrev_b32 v2,4,v2
ds_read_b128 v[20:23],v2
s_waitcnt lgkmcnt(0)
global_store_dwordx4 v2,v[20:23],s[6:7]
.Ldone:
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
    .group_segment_fixed_size: 1024
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
