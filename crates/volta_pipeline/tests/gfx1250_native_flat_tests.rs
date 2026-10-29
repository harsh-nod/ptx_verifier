//! Genuine gfx1250 FLAT identity, byte extension, counters, and target boundaries.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass};
use volta_graph_check::GraphConclusion;
fn source(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
k:
s_load_b128 s[4:7],s[0:1],0
s_wait_kmcnt 0
v_mov_b32 v0,0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: scratch
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}
fn config() -> AnalysisConfig {
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.arrays = vec![
        ArrayDef {
            name: "scratch".into(),
            base: 0x10000,
            elem_width: 1,
            len: 8,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 2,
            kind: ArrayKind::Output,
        },
    ];
    c.params = vec![
        ParamValue::ArrayPtr("scratch".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    c
}
fn checked(body: &str) -> native_common::Checked {
    let s = source(body);
    let m = frontend::parse(&s).unwrap();
    native_common::check(&s, &m, Some("k"), config()).unwrap()
}
#[test]
fn native_flat_signed_and_unsigned_bytes_are_real_dual_counter_operations() {
    for (load, value, expected) in [("flat_load_i8", 255, u32::MAX), ("flat_load_u8", 300, 44)] {
        let run = checked(&format!(
            "v_mov_b32 v1,{value}\nflat_store_b8 v0,v1,s[4:5] scope:SCOPE_SYS\ns_wait_storecnt 0\n{load} v1,v0,s[4:5] scope:SCOPE_SYS\ns_wait_loadcnt_dscnt 0\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]"
        ));
        assert_eq!(
            run.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            run.checks
        );
        let o = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(o.outputs[0].1.len(), 1);
        assert_eq!(o.outputs[0].1[0].0, 0);
        assert_eq!(
            o.arena.as_int_const(o.outputs[0].1[0].1),
            Some(i64::from(expected))
        );
        let classes = run
            .analysis
            .graph()
            .amd_events()
            .iter()
            .filter_map(|e| match &e.kind {
                AmdEventKind::MemoryIssue {
                    class, counters, ..
                } if matches!(
                    class,
                    AmdMemoryClass::FlatGlobalLoad | AmdMemoryClass::FlatGlobalStore
                ) =>
                {
                    Some((*class, counters.clone()))
                }
                _ => None,
            })
            .collect::<Vec<_>>();
        assert_eq!(classes.len(), 2);
        assert_eq!(
            classes[0],
            (
                AmdMemoryClass::FlatGlobalStore,
                vec![
                    (AmdCounter::Store, 1),
                    (AmdCounter::Ds, 1),
                    (AmdCounter::X, 1)
                ]
            )
        );
        assert_eq!(
            classes[1],
            (
                AmdMemoryClass::FlatGlobalLoad,
                vec![
                    (AmdCounter::Load, 1),
                    (AmdCounter::Ds, 1),
                    (AmdCounter::X, 1)
                ]
            )
        );
    }
}
#[test]
fn missing_flat_data_wait_remains_rejected() {
    let run = checked(
        "v_mov_b32 v1,255\nflat_store_b8 v0,v1,s[4:5] scope:SCOPE_SYS\ns_wait_storecnt 0\nflat_load_u8 v1,v0,s[4:5] scope:SCOPE_SYS\ns_wait_xcnt 0\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]",
    );
    assert!(run.analysis.symbolic_outputs().is_ok());
    assert!(
        matches!(run.checks.conclusion(), GraphConclusion::Rejected { .. }),
        "{:#?}",
        run.checks
    );
    assert!(format!("{:?}", run.checks).contains("ReadBeforeReady"));
}
#[test]
fn scalar_signed_conversion_preserves_scc_and_unsigned_byte_keeps_its_source_identity() {
    let run = checked(
        "s_load_u8 s8,s[4:5],0\ns_wait_kmcnt 0\ns_cmp_eq_u32 1,1\ns_mov_b32 s9,-3\ns_cvt_f32_i32 s9,s9\ns_cselect_b32 s10,1,0\nv_mov_b32 v1,s9\nglobal_store_b32 v0,v1,s[6:7]\nv_mov_b32 v2,s10\nv_add_nc_u32 v2,0,v2\nglobal_store_b32 v0,v2,s[6:7] offset:4",
    );
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let o = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.outputs[0].1.len(), 2);
    assert_eq!(o.arena.as_int_const(o.outputs[0].1[0].1), Some(-3));
    assert_eq!(o.arena.as_int_const(o.outputs[0].1[1].1), Some(1));
}
#[test]
fn new_scalar_and_flat_profiles_reject_incorrect_registers_modifiers_and_retargeting() {
    for line in [
        "flat_load_b32 v1,v0,s[4:5] scale_offset",
        "flat_load_b32 v1,v[0:1],s[4:5]",
        "flat_load_b32 v1,v0,s4",
        "flat_load_b32_e64 v1,v0,s[4:5]",
        "s_load_u8 v1,s[4:5],0",
        "s_cvt_f32_i32 s8,v1",
        "s_get_pc_i64 s3",
        "s_sub_co_i32 s8,s[4:5],0",
        "s_sub_co_i32 s8,0x12345678,0x12345679",
        "s_cvt_f32_i32 s8,0x100000000",
    ] {
        assert!(frontend::parse(&source(line)).is_err(), "{line}");
    }
    let mut m = frontend::parse(&source("s_cvt_f32_i32 s8,s9")).unwrap();
    m.target = Some("gfx950".into());
    m.kernels[0]
        .descriptor
        .fields
        .insert("wavefront_size32".into(), 0);
    assert!(volta_amdgpu_analysis::analyze(&m, Some("k"), config()).is_err());
}

#[test]
fn native_flat_signed24_displacements_preserve_byte_units_and_reject_adjacent_limits() {
    for offset in [-8_388_608i64, -1, 0, 4096, 8_388_607] {
        for scalar_base in [true, false] {
            let mut cfg = config();
            cfg.arrays[0].base = 0x1000_0000;
            let base = (cfg.arrays[0].base as i64 - offset) as u64;
            let (setup, address) = if scalar_base {
                (
                    format!("s_mov_b32 s4,{}\ns_mov_b32 s5,0", base),
                    "v0,s[4:5]",
                )
            } else {
                (format!("v_mov_b32 v2,{}\nv_mov_b32 v3,0", base), "v[2:3]")
            };
            let s = source(&format!(
                "{setup}\nflat_load_u8 v1,{address} offset:{offset} scope:SCOPE_SYS\ns_wait_loadcnt_dscnt 0\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]"
            ));
            let m = frontend::parse(&s).unwrap();
            let run = native_common::check(&s, &m, Some("k"), cfg).unwrap();
            assert_eq!(
                run.checks.conclusion(),
                GraphConclusion::Verified,
                "{offset} {scalar_base}: {:#?}",
                run.checks
            );
            let out = run.analysis.symbolic_outputs().unwrap();
            assert_eq!(out.outputs[0].1.len(), 1);
            assert_eq!(out.arena.display_expr(out.outputs[0].1[0].1), "scratch[0]");
        }
    }
    for offset in [-8_388_609, 8_388_608] {
        let run = checked(&format!(
            "flat_load_u8 v1,v0,s[4:5] offset:{offset}\ns_wait_loadcnt_dscnt 0\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]"
        ));
        assert!(
            run.analysis
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("encoded range")
        );
        assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
    }
}

#[test]
fn scalar_signed_subtract_alias_uses_signed_overflow_and_keeps_original_result_bits() {
    for (a, b) in [
        (0x8000_0000u32, 1u32),
        (0, 1),
        (1, 1),
        (0x7fff_ffff, 0xffff_ffff),
    ] {
        let run = checked(&format!(
            "s_mov_b32 s8,{a}\ns_mov_b32 s9,{b}\ns_sub_co_i32 s8,s8,s9\ns_cselect_b32 s9,1,0\nv_mov_b32 v1,s8\nv_mov_b32 v2,s9\nv_add_nc_u32 v1,0,v1\nv_add_nc_u32 v2,0,v2\nglobal_store_b32 v0,v1,s[6:7]\nglobal_store_b32 v0,v2,s[6:7] offset:4"
        ));
        assert_eq!(
            run.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            run.checks
        );
        let out = run.analysis.symbolic_outputs().unwrap();
        let (value, overflow) = (a as i32).overflowing_sub(b as i32);
        assert_eq!(out.outputs[0].1.len(), 2);
        assert_eq!(
            out.arena.as_int_const(out.outputs[0].1[0].1),
            Some(i64::from(value as u32))
        );
        assert_eq!(
            out.arena.as_int_const(out.outputs[0].1[1].1),
            Some(i64::from(overflow))
        );
    }
}
