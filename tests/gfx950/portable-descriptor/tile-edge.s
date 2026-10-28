// Native explicit address/stride descriptor publication and edge zero-fill.
// Payload mirrors the4x4 tile at(6,6) in the baseline8x8 F16 tensor cases.
// AMD has no TMA tensor-map proxy object; LDS completion/barrier publish bytes.
// Explicit AMDHSA x/out ABI; unused input slots remain ordinary declared data.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
// Wave0/lane0 publishes {base64,pitch,width,height,row0,col0,box_width}.
v_cmp_eq_u32 vcc, 0, v0
s_and_saveexec_b64 s[8:9], vcc
v_mov_b32 v3, 0
v_mov_b32 v4, s4
v_mov_b32 v5, s5
v_mov_b32 v6, 16
v_mov_b32 v7, 8
v_mov_b32 v8, 8
v_mov_b32 v9, 6
v_mov_b32 v10, 6
v_mov_b32 v11, 4
ds_write_b128 v3, v[4:7]
ds_write_b128 v3, v[8:11] offset:16
s_waitcnt lgkmcnt(0) // producer completion
s_mov_b64 exec, s[8:9]
s_barrier // descriptor publication
// Wave1/lane0..15 consume the actual descriptor and copy its4x4 tile.
v_sub_u32 v26, v0, 64
v_cmp_lt_u32 vcc, v26, 16
s_and_saveexec_b64 s[10:11], vcc
v_mov_b32 v3, 0
ds_read_b128 v[16:19], v3
ds_read_b128 v[20:23], v3 offset:16
s_waitcnt lgkmcnt(0) // descriptor consumption
v_lshrrev_b32 v27, 2, v26
v_and_b32 v28, 3, v26
v_add_u32 v27, v27, v21
v_add_u32 v28, v28, v22
v_cmp_lt_u32 vcc, v27, v20
s_mov_b64 s[12:13], vcc
v_cmp_lt_u32 vcc, v28, v19
s_and_b64 s[12:13], s[12:13], vcc
v_mov_b32 v24, 0
s_and_saveexec_b64 s[14:15], s[12:13]
v_mul_lo_u32 v25, v27, v18
v_lshlrev_b32 v28, 1, v28
v_add_u32 v25, v25, v28
v_add_co_u32 v30, vcc, v16, v25
v_addc_co_u32 v31, vcc, v17, 0, vcc
global_load_ushort v24, v[30:31], off
s_waitcnt vmcnt(0)
s_mov_b64 exec, s[14:15]
v_lshlrev_b32 v29, 1, v26
ds_write_b16 v29, v24 offset:32
s_waitcnt lgkmcnt(0) // tile completion
s_mov_b64 exec, s[10:11]
s_barrier // tile publication
// Wave2/lane0..15 read the completed LDS tile, including zero-fill.
v_mov_b32 v26, 128
v_sub_u32 v26, v0, v26
v_cmp_lt_u32 vcc, v26, 16
s_and_saveexec_b64 s[10:11], vcc
v_lshlrev_b32 v29, 1, v26
ds_read_u16 v24, v29 offset:32
s_waitcnt lgkmcnt(0) // tile consumption
global_store_short v29, v24, s[6:7]
s_mov_b64 exec, s[10:11]
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 64
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
    .group_segment_fixed_size: 64
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .wavefront_size: 64
    .sgpr_count: 18
    .vgpr_count: 32
    .max_flat_workgroup_size: 256
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
