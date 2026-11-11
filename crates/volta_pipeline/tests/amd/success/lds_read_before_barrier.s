.amdgcn_target "amdgcn-amd-amdhsa--gfx950:xnack-"
.text
lds_read_before_barrier:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_lshlrev_b32_e32 v2, 2, v0
global_load_dword v1, v2, s[4:5]
s_waitcnt vmcnt(0)
ds_write_b32 v2, v1
s_waitcnt lgkmcnt(0)
s_barrier
v_xor_b32_e32 v3, 256, v2
ds_read_b32 v4, v3
s_barrier
v_mov_b32_e32 v1, 42
ds_write_b32 v2, v1
s_waitcnt lgkmcnt(0)
global_store_dword v2, v4, s[6:7]
s_endpgm
.section .rodata
.amdhsa_kernel lds_read_before_barrier
.amdhsa_group_segment_fixed_size 512
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_sgpr_workgroup_id_x 0
.amdhsa_system_sgpr_workgroup_id_y 0
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.end_amdhsa_kernel
