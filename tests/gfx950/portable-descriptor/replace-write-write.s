// Ordinary native descriptor bytes: exact replace/copy memory-conflict controls.
//128-byte LDS descriptor and global copy; no tensor-map proxy is invented.
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
v_lshlrev_b32 v2, 2, v0
v_cmp_lt_u32 vcc, v0, 32
s_and_saveexec_b64 s[8:9], vcc
v_add_u32 v4, 42, 0
ds_write_b32 v2, v4
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
s_barrier
v_cmp_eq_u32 vcc, 0, v0
s_and_saveexec_b64 s[8:9], vcc
v_mov_b32 v3, 0
v_add_u32 v4, 19, 0
ds_write_b32 v3, v4
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
s_nop 0 // replace-to-replace join
v_cmp_eq_u32 vcc, v0, 64
s_and_saveexec_b64 s[8:9], vcc
v_mov_b32 v3, 0
v_add_u32 v4, 23, 0
ds_write_b32 v3, v4
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
s_barrier
v_cmp_eq_u32 vcc, 0, v0
s_and_saveexec_b64 s[8:9], vcc
v_mov_b32 v3, 0
ds_read_b32 v4, v3
s_waitcnt lgkmcnt(0)
global_store_dword v3, v4, s[4:5]
s_waitcnt vmcnt(0)
s_mov_b64 exec, s[8:9]
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
    .group_segment_fixed_size: 128
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
