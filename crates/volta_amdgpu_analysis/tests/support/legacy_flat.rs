//! Small complete LDS/FLAT transport fixture; no original kernel is modified.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

pub fn source(target: &str, body: &str) -> String {
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
s_load_dwordx4 s[4:7],s[0:1],0
s_waitcnt lgkmcnt(0)
{body}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 24
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
      - .name: zeros
        .offset: 16
        .size: 8
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    )
}

pub fn config(block: u32) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: u64::from(block),
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: u64::from(block),
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Bytes(vec![0; 8]),
    ];
    config.dynamic_shared_bytes = u64::from(block) * 4 + 8;
    config
}

pub fn copy(alias: bool) -> String {
    let destination = if alias { "v[0:1]" } else { "v[2:3]" };
    format!(
        "v_lshlrev_b32 v0,2,v0\nv_mov_b32 v1,0\nv_mov_b32 v10,v0\nglobal_load_dword v4,v0,s[4:5]\ns_waitcnt vmcnt(0)\nv_add_f32 v4,0,v4\nds_write_b32 v0,v4 offset:8\ns_waitcnt lgkmcnt(0)\ns_mov_b64 s[8:9],src_shared_base\ns_mov_b32 s8,8\nv_lshl_add_u64 {destination},s[8:9],0,v[0:1]\nflat_load_dword v5,{destination}\ns_waitcnt vmcnt(0) lgkmcnt(0)\nv_add_f32 v5,0,v5\nglobal_store_dword v10,v5,s[6:7]\ns_waitcnt vmcnt(0)"
    )
}
