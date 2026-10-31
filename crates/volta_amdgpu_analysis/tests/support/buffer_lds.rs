use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};

pub fn source(body: &str) -> String {
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.type k,@function
k:
{body}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 32
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: resource
        .offset: 0
        .size: 16
        .value_kind: by_value
      - .name: partial_m0
        .offset: 16
        .size: 1
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    )
}

pub fn config(block: u32, len: u64, lds: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.dynamic_shared_bytes = lds;
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::Bytes(
            [0x10000u32, 0, (len * 4) as u32, 0x110000]
                .into_iter()
                .flat_map(u32::to_le_bytes)
                .collect(),
        ),
        ParamValue::Bytes(vec![10]),
    ];
    config
}

pub fn quad(base: u64, records: u32, word3: u32) -> String {
    [base as u32, (base >> 32) as u32, records, word3]
        .into_iter()
        .enumerate()
        .map(|(i, value)| format!("s_mov_b32 s{},{value}\n", 8 + i))
        .collect()
}

pub fn opcode(bytes: u64) -> &'static str {
    if bytes == 4 {
        "buffer_load_dword"
    } else {
        "buffer_load_dwordx4"
    }
}

pub fn copy(bytes: u64, m0: u32, records: u32) -> String {
    let (ds, data, store) = if bytes == 4 {
        ("ds_read_b32", "v4", "global_store_dword")
    } else {
        ("ds_read_b128", "v[4:7]", "global_store_dwordx4")
    };
    format!(
        "{}v_lshlrev_b32 v1,{},v0\nv_add_u32 v2,{m0},v1\ns_mov_b64 s[12:13],0x20000\ns_mov_b32 m0,{m0}\ns_nop 0\n{} v1,s[8:11],0 offen lds\ns_waitcnt vmcnt(0)\n{ds} {data},v2\ns_waitcnt lgkmcnt(0)\n{store} v1,{data},s[12:13]\ns_waitcnt vmcnt(0)",
        quad(0x10000, records, 0x110000),
        bytes.trailing_zeros(),
        opcode(bytes)
    )
}

pub fn module(body: &str) -> frontend::Module {
    frontend::parse(&source(body)).unwrap()
}
