//! Selected subword consumers retain byte identities without defining unknown high bits.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
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
fn run_with(body: &str, width: u64, len: u64) -> native_common::Checked {
    let s = source(body);
    let m = frontend::parse(&s).unwrap();
    let mut c = config();
    c.arrays[1].elem_width = width;
    c.arrays[1].len = len;
    native_common::check(&s, &m, Some("k"), c).unwrap()
}
const PACK: &str = "global_load_u8 v1,v0,s[4:5]\nglobal_load_u8 v2,v0,s[4:5] offset:1\ns_wait_loadcnt 0\nv_lshlrev_b16 v2,8,v2\nv_or_b32 v1,v1,v2";
#[test]
fn true16_byte_packing_preserves_both_original_raw_bytes_and_omits_unwritten_slots() {
    let run = run_with(&format!("{PACK}\nglobal_store_b16 v0,v1,s[6:7]"), 1, 3);
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let o = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.outputs[0].1.len(), 2);
    for index in 0..2 {
        assert_eq!(o.outputs[0].1[index].0, index as u64);
        assert_eq!(
            o.arena.display_expr(o.outputs[0].1[index].1),
            format!("scratch[{index}]")
        );
    }
}
#[test]
fn true16_packed_bytes_never_fabricate_defined_upper_bits() {
    for consumer in [
        "global_store_b32 v0,v1,s[6:7]",
        "v_cvt_f32_ubyte3_e32 v3,v1\nglobal_store_b32 v0,v3,s[6:7]",
        "v_cvt_f32_ubyte2_e32 v3,v1\nglobal_store_b32 v0,v3,s[6:7]",
    ] {
        let run = run_with(&format!("{PACK}\n{consumer}"), 4, 1);
        let error = run.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("undefined"), "{consumer}: {error}");
        assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
    }
}
#[test]
fn scalar_subword_loads_use_real_byte_offsets_and_keep_original_raw_identity() {
    for (opcode, offset, width) in [("s_load_u8", 3, 1), ("s_load_u16", 2, 2)] {
        let run = run_with(
            &format!(
                "{opcode} s8,s[4:5],{offset}\ns_wait_kmcnt 0\nv_mov_b32 v1,s8\nglobal_store_b{} v0,v1,s[6:7]",
                width * 8
            ),
            1,
            width,
        );
        assert_eq!(
            run.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            run.checks
        );
        let o = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(o.outputs[0].1.len(), width as usize);
        for i in 0..width {
            assert_eq!(
                o.arena.display_expr(o.outputs[0].1[i as usize].1),
                format!("scratch[{}]", offset + i)
            );
        }
    }
}
#[test]
fn scalar_address_masks_follow_payload_width_and_scale_the_register_index_first() {
    for (opcode, base, register, immediate, scaled, width, first) in [
        ("s_load_u8", 1, 1, 1, false, 1, 3),
        ("s_load_u16", 1, 1, 1, false, 2, 0),
        ("s_load_u16", 3, 3, 3, false, 2, 6),
        ("s_load_b32", 3, 3, 3, false, 4, 0),
        ("s_load_b32", 7, 7, 7, false, 4, 12),
        ("s_load_u8", 1, 3, 1, true, 1, 5),
        ("s_load_u16", 3, 3, 3, true, 2, 10),
        ("s_load_b32", 3, 3, 3, true, 4, 12),
    ] {
        let body = format!(
            "s_add_u32 s4,s4,{base}\ns_addc_u32 s5,s5,0\n\
             s_mov_b32 s12,{register}\n\
             {opcode} s8,s[4:5],s12 offset:{immediate} {}\n\
             s_wait_kmcnt 0\nv_mov_b32 v1,s8\nglobal_store_b{} v0,v1,s[6:7]",
            if scaled { "scale_offset" } else { "" },
            width * 8,
        );
        let assembly = source(&body);
        let module = frontend::parse(&assembly).unwrap();
        let mut config = config();
        config.arrays[0].len = 32;
        config.arrays[1].elem_width = 1;
        config.arrays[1].len = width;
        let result = native_common::check(&assembly, &module, Some("k"), config).unwrap();
        assert_eq!(
            result.checks.conclusion(),
            GraphConclusion::Verified,
            "{body}: {:#?}",
            result.checks
        );
        let outputs = result.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), width as usize);
        for index in 0..width {
            assert_eq!(
                outputs
                    .arena
                    .display_expr(outputs.element("out", index).unwrap()),
                format!("scratch[{}]", first + index)
            );
        }
    }
}

#[test]
fn scalar_scaling_uses_the_complete_payload_and_retains_products_above_32_bits() {
    for (load, index, immediate, input_base, input_len, first) in [
        ("s_load_b96 s[8:10]", 1u64, 4, 0x10000u64, 28, 16),
        ("s_load_b32 s8", 0x40000000, 0, 0x100010000, 4, 0),
    ] {
        let body = format!(
            "s_mov_b32 s12,{index}\n{load},s[4:5],s12 offset:{immediate} scale_offset\n\
             s_wait_kmcnt 0\nv_mov_b32 v1,s8\nglobal_store_b32 v0,v1,s[6:7]",
        );
        let assembly = source(&body);
        let module = frontend::parse(&assembly).unwrap();
        let mut config = config();
        config.params[0] = ParamValue::Int(0x10000);
        config.arrays[0].base = input_base;
        config.arrays[0].len = input_len;
        config.arrays[1].elem_width = 1;
        config.arrays[1].len = 4;
        let result = native_common::check(&assembly, &module, Some("k"), config.clone()).unwrap();
        assert_eq!(
            result.checks.conclusion(),
            GraphConclusion::Verified,
            "{body}"
        );
        let outputs = result.analysis.symbolic_outputs().unwrap();
        for index in 0..4 {
            assert_eq!(
                outputs
                    .arena
                    .display_expr(outputs.element("out", index).unwrap()),
                format!("scratch[{}]", first + index)
            );
        }
        if input_len == 28 {
            config.arrays[0].len = 27;
            let short = native_common::check(&assembly, &module, Some("k"), config).unwrap();
            assert!(short.analysis.symbolic_outputs().is_err());
            assert_ne!(short.checks.conclusion(), GraphConclusion::Verified);
        }
    }
}

#[test]
fn upper_byte_conversion_selects_only_encoded_bits_and_keeps_format_alias_guards() {
    let run = run_with(
        "v_mov_b32 v1,0xfa123456\nv_cvt_f32_ubyte3_e32 v1,v1\nglobal_store_b32 v0,v1,s[6:7]",
        4,
        1,
    );
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let o = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(o.arena.as_int_const(o.outputs[0].1[0].1), Some(250));
    let run = run_with(
        "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\nv_cvt_f32_ubyte3_e32 v2,v1\nv_cvt_f32_fp8_e32 v3,v1\nv_add_f32 v2,v2,v3\nglobal_store_b32 v0,v2,s[6:7]",
        4,
        1,
    );
    let error = run.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(
        error.contains("conflicting byte interpretations"),
        "{error}"
    );
}

#[test]
fn byte_zero_conversion_consumes_only_its_selected_encoded_byte() {
    for (prelude, expected) in [
        ("v_mov_b32 v1,0xabcdefe7", "231"),
        (
            "global_load_u8 v1,v0,s[4:5]\ns_wait_loadcnt 0",
            "scratch[0]",
        ),
        (PACK, "scratch[0]"),
    ] {
        let run = run_with(
            &format!("{prelude}\nv_cvt_f32_ubyte0_e32 v3,v1\nglobal_store_b32 v0,v3,s[6:7]"),
            4,
            1,
        );
        assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
        let out = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs[0].1.len(), 1);
        assert_eq!(out.outputs[0].1[0].0, 0);
        assert_eq!(out.arena.display_expr(out.outputs[0].1[0].1), expected);
    }
}

#[test]
fn byte_zero_conversion_does_not_expand_target_or_source_profiles() {
    for instruction in [
        "v_cvt_f32_ubyte0_e32 v3,-v1",
        "v_cvt_f32_ubyte0_e32 v3,v1 clamp",
        "v_cvt_f32_ubyte0_e32 v3,0x100000000",
        "v_cvt_f32_ubyte0_e32 v3,v[1:2]",
    ] {
        assert!(
            frontend::parse(&source(instruction)).is_err(),
            "{instruction}"
        );
    }
    for target in ["gfx942", "gfx950"] {
        let source = source("v_cvt_f32_ubyte0_e32 v3,v1").replace("gfx1250", target);
        assert!(frontend::parse(&source).is_err(), "{target}");
    }
}

#[test]
fn real_flat_abi_mutations_retain_typed_source_and_partial_wait_failures() {
    const TRANSFERS: &str = include_str!("../../../tests/gfx1250/portable-abi/native-transfers.s");
    for (kernel, original, replacement, hazard) in [
        (
            "abi_pair_truncation",
            "flat_load_u16 v1, v0, s[4:5] scope:SCOPE_SYS",
            "v_mov_b32_e32 v1, 0",
            "SourceReuse",
        ),
        (
            "abi_scalar_granule",
            "s_wait_loadcnt_dscnt 0x1",
            "s_wait_loadcnt_dscnt 0x2",
            "ReadBeforeReady",
        ),
    ] {
        let mut cfg = config();
        if kernel == "abi_pair_truncation" {
            cfg.arrays.remove(0);
            cfg.params.remove(0);
            cfg.arrays[0].len = 3;
        } else {
            cfg.arrays[0].elem_width = 2;
            cfg.arrays[0].len = 1;
            cfg.arrays[1].len = 1;
        }
        let module = frontend::parse(TRANSFERS).unwrap();
        let positive = native_common::check(TRANSFERS, &module, Some(kernel), cfg.clone()).unwrap();
        assert_eq!(
            positive.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            positive.checks
        );
        let start = TRANSFERS.find(&format!("\n{kernel}:")).unwrap();
        let end = start + TRANSFERS[start..].find("\n\t.section\t.rodata").unwrap();
        let body = &TRANSFERS[start..end];
        assert_eq!(body.matches(original).count(), 1);
        let mutated = format!(
            "{}{}{}",
            &TRANSFERS[..start],
            body.replacen(original, replacement, 1),
            &TRANSFERS[end..]
        );
        let module = frontend::parse(&mutated).unwrap();
        let negative = native_common::check(&mutated, &module, Some(kernel), cfg).unwrap();
        assert!(
            negative.analysis.symbolic_outputs().is_ok(),
            "{:?}",
            negative.analysis.symbolic_outputs()
        );
        assert!(
            matches!(
                negative.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "{:#?}",
            negative.checks
        );
        assert!(
            format!("{:?}", negative.checks).contains(hazard),
            "{:#?}",
            negative.checks
        );
    }
}

#[test]
fn selected_subword_encodings_reject_unrepresented_offsets_and_modifiers() {
    for bad in [
        "s_load_u16 s8,s[4:5],0x1000000",
        "s_load_u8 s8,s[4:5],-1",
        "s_load_u16 s8,s[4:5],v1",
        "v_cvt_f32_ubyte3_e32 v1,0x100000000",
        "v_cvt_f32_ubyte3_e64 v1,-v2",
        "v_cvt_f32_ubyte3_e64 v1,v2 clamp",
    ] {
        assert!(frontend::parse(&source(bad)).is_err(), "{bad}");
    }
}
