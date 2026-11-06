.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl mixed_lgkm_copy
.type mixed_lgkm_copy,@function
mixed_lgkm_copy:
    s_load_dwordx4 s[4:7], s[0:1], 0
    s_waitcnt lgkmcnt(0)
    v_lshlrev_b32 v2, 2, v0
    global_load_dword v8, v2, s[4:5]
    s_waitcnt vmcnt(0)
    ds_write_b32 v2, v8
    s_waitcnt lgkmcnt(0)
    s_load_dwordx2 s[12:13], s[4:5], 0
    ds_read_b32 v10, v2
    ds_read_b32 v11, v2
    s_waitcnt lgkmcnt(1)
    global_store_dword v2, v10, s[6:7]
    s_waitcnt lgkmcnt(0)
    s_endpgm
.amdhsa_kernel mixed_lgkm_copy
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_group_segment_fixed_size 1024
    .amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: mixed_lgkm_copy
    .symbol: mixed_lgkm_copy.kd
    .kernarg_segment_size: 16
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
