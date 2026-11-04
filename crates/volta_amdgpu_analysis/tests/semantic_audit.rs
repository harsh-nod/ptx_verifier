//! Source-encoding and flag boundaries of the selected scalar-immediate forms.
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend, lower, target,
};

fn source(architecture: &str, body: &str) -> String {
    let wave32 = architecture == "gfx1250";
    let (load, wait, add, store, finish, descriptor) = if wave32 {
        (
            "s_load_b64",
            "s_wait_kmcnt 0",
            "v_add_nc_u32",
            "global_store_b32",
            "s_wait_storecnt 0\ns_wait_xcnt 0\ns_endpgm",
            ".amdhsa_wavefront_size32 1",
        )
    } else {
        (
            "s_load_dwordx2",
            "s_waitcnt lgkmcnt(0)",
            "v_add_u32",
            "global_store_dword",
            "s_endpgm",
            "",
        )
    };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{architecture}"
.text
.type k,@function
k:
{load} s[8:9],s[0:1],0
{wait}
{body}
{add} v1,s2,0
{store} v0,v1,s[8:9]
{finish}
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
{descriptor}
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}

fn config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn assert_marker(architecture: &str, body: &str) {
    let module = frontend::parse(&source(architecture, body)).unwrap();
    let result = analyze(&module, Some("k"), config()).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(
        outputs
            .arena
            .as_int_const(outputs.element("out", 0).unwrap()),
        Some(7),
        "{architecture}: {body}"
    );
    result.graph().validate().unwrap();
}

fn forms(architecture: &str) -> Vec<&'static str> {
    let mut forms = vec!["s_movk_i32", "s_mulk_i32"];
    if architecture == "gfx1250" {
        forms.push("s_addk_co_i32");
    } else {
        forms.extend([
            "s_addk_i32",
            "s_cmpk_eq_i32",
            "s_cmpk_lg_i32",
            "s_cmpk_eq_u32",
            "s_cmpk_lg_u32",
            "s_cmpk_gt_u32",
            "s_cmpk_lt_u32",
        ]);
    }
    forms
}

#[test]
fn sopk_requires_an_encoded_immediate_in_text_and_direct_ast() {
    for architecture in ["gfx942", "gfx950", "gfx1250"] {
        for opcode in forms(architecture) {
            let unsigned = opcode.starts_with("s_cmpk_") && opcode.ends_with("_u32");
            for immediate in ["0", "32767", "32768", "65535"] {
                frontend::parse(&source(architecture, &format!("{opcode} s2,{immediate}")))
                    .unwrap();
            }
            if !unsigned {
                frontend::parse(&source(architecture, &format!("{opcode} s2,-32768"))).unwrap();
            }
            for malformed in ["s3", "1.0", "65536", "-32769"] {
                assert!(
                    frontend::parse(&source(architecture, &format!("{opcode} s2,{malformed}")))
                        .is_err(),
                    "{architecture}: {opcode} {malformed}"
                );
            }
            if unsigned {
                assert!(
                    frontend::parse(&source(architecture, &format!("{opcode} s2,-1"))).is_err()
                );
            }
            for operand in [
                frontend::Operand::Integer(65536),
                frontend::Operand::Float(1.0),
                frontend::Operand::Register(frontend::Register {
                    class: frontend::RegisterClass::Scalar,
                    index: 3,
                    count: 1,
                    special: None,
                }),
            ] {
                let mut module =
                    frontend::parse(&source(architecture, &format!("{opcode} s2,0"))).unwrap();
                let instruction = module.kernels[0]
                    .instructions
                    .iter_mut()
                    .find(|instruction| instruction.mnemonic == opcode)
                    .unwrap();
                instruction.operands[1] = operand;
                assert!(lower::lower_module_kernel(&module, "k").is_err());
                assert!(lower::lower_kernel(&module.kernels[0]).is_err());
            }
        }
    }
}

#[test]
fn gfx1250_cannot_inherit_cdna_sopk_compare_encodings() {
    for opcode in [
        "s_cmpk_eq_i32",
        "s_cmpk_lg_i32",
        "s_cmpk_eq_u32",
        "s_cmpk_lg_u32",
        "s_cmpk_gt_u32",
        "s_cmpk_lt_u32",
    ] {
        let assembly = source("gfx1250", &format!("{opcode} s2,1"));
        assert!(frontend::parse(&assembly).is_err(), "{opcode}");
        let cdna = frontend::parse(&source("gfx950", &format!("{opcode} s2,1"))).unwrap();
        let mut forged = frontend::parse(&source("gfx1250", "s_mov_b32 s2,0")).unwrap();
        forged.kernels[0].instructions[2] = cdna.kernels[0].instructions[2].clone();
        let error = target::validate(&forged).unwrap_err();
        assert!(error.message.contains("SOPK compare"), "{error:?}");
        assert!(lower::lower_module_kernel(&forged, "k").is_err());
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    }
}

#[test]
fn gfx1250_scale_offset_requires_global_scalar_base_mode() {
    for body in [
        "global_load_b32 v4,v[2:3],off",
        "global_store_b32 v[2:3],v4,off",
    ] {
        let assembly = source("gfx1250", body);
        let ordinary = frontend::parse(&assembly).unwrap();
        lower::lower_module_kernel(&ordinary, "k").unwrap();
        let scaled = assembly.replace(body, &format!("{body} scale_offset"));
        assert!(frontend::parse(&scaled).is_err(), "{body}");
        let mut forged = ordinary;
        forged.kernels[0].instructions[2]
            .modifiers
            .push(frontend::Modifier {
                name: "scale_offset".into(),
                value: None,
            });
        assert!(target::validate(&forged).is_err());
        assert!(lower::lower_module_kernel(&forged, "k").is_err());
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    }
}

#[test]
fn movk_sign_extends_its_word_and_preserves_both_old_scc_values() {
    for architecture in ["gfx942", "gfx950", "gfx1250"] {
        for (encoded, expected) in [("0", 0), ("32767", 32767), ("32768", -32768), ("65535", -1)] {
            for old_scc in [false, true] {
                let (yes, no) = if old_scc { (7, 9) } else { (9, 7) };
                assert_marker(
                    architecture,
                    &format!(
                        "s_cmp_eq_u32 0,{}\ns_movk_i32 s2,{encoded}\ns_cselect_b32 s3,{yes},{no}\ns_cmp_eq_i32 s2,{expected}\ns_cselect_b32 s2,s3,9",
                        u8::from(!old_scc)
                    ),
                );
            }
        }
    }
}

#[test]
fn addk_replaces_scc_with_signed_overflow_and_mulk_preserves_it() {
    for architecture in ["gfx942", "gfx950", "gfx1250"] {
        let add = if architecture == "gfx1250" {
            "s_addk_co_i32"
        } else {
            "s_addk_i32"
        };
        for (initial, immediate, expected, overflow) in [
            (2147483647_i64, "1", -2147483648_i64, true),
            (-2147483648, "65535", 2147483647, true),
            (6, "-2", 4, false),
        ] {
            let (yes, no) = if overflow { (7, 9) } else { (9, 7) };
            assert_marker(
                architecture,
                &format!(
                    "s_mov_b32 s2,{initial}\ns_cmp_eq_u32 0,{}\n{add} s2,{immediate}\ns_cselect_b32 s3,{yes},{no}\ns_cmp_eq_i32 s2,{expected}\ns_cselect_b32 s2,s3,9",
                    u8::from(overflow)
                ),
            );
        }
        for old_scc in [false, true] {
            let (yes, no) = if old_scc { (7, 9) } else { (9, 7) };
            assert_marker(
                architecture,
                &format!(
                    "s_mov_b32 s2,6\ns_cmp_eq_u32 0,{}\ns_mulk_i32 s2,65535\ns_cselect_b32 s3,{yes},{no}\ns_cmp_eq_i32 s2,-6\ns_cselect_b32 s2,s3,9",
                    u8::from(!old_scc)
                ),
            );
        }
    }
}

#[test]
fn cmpk_signed_and_unsigned_fields_have_distinct_extension_rules() {
    for architecture in ["gfx942", "gfx950"] {
        for (opcode, value, immediate, condition) in [
            ("s_cmpk_eq_i32", -1_i64, 65535, true),
            ("s_cmpk_lg_i32", -1, 65535, false),
            ("s_cmpk_eq_u32", 65535, 65535, true),
            ("s_cmpk_eq_u32", -1, 65535, false),
            ("s_cmpk_lg_u32", 65535, 65535, false),
            ("s_cmpk_gt_u32", 65536, 65535, true),
            ("s_cmpk_lt_u32", 0, 65535, true),
        ] {
            let (yes, no) = if condition { (7, 9) } else { (9, 7) };
            assert_marker(
                architecture,
                &format!(
                    "s_mov_b32 s2,{value}\n{opcode} s2,{immediate}\ns_cselect_b32 s2,{yes},{no}"
                ),
            );
        }
    }
}
