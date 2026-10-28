use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisError, ArrayDef, ArrayKind, EvalError, analyze, frontend,
    target::Architecture,
};

fn source(target: &str, body: &str, lds: u64) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.p2align 8\n.type k,@function\nk:\n{body}\n.amdhsa_kernel k\n.amdhsa_group_segment_fixed_size {lds}\n.end_amdhsa_kernel\n"
    )
}

#[test]
fn source_architecture_and_feature_suffixes_are_preserved() {
    for target in ["gfx942", "gfx942:sramecc+:xnack-", "gfx950:xnack-"] {
        let module = frontend::parse(&source(target, "s_endpgm", 0)).unwrap();
        assert_eq!(module.target.as_deref(), Some(target));
        let result = analyze(&module, None, AnalysisConfig::new((65, 1, 1))).unwrap();
        assert!(result.symbolic_outputs().is_ok());
        assert_eq!(result.graph().provenance().targets, [target]);
        assert_eq!(result.graph().threads(), 65);
    }
    for target in [
        "gfx940",
        "gfx942:xnack+:xnack-",
        "gfx942:sramecc+:sramecc+",
        "gfx942:unknown",
    ] {
        assert!(
            frontend::parse(&source(target, "s_endpgm", 0)).is_err(),
            "{target}"
        );
    }
}

#[test]
fn lds_limit_is_architectural_and_includes_dynamic_allocation() {
    assert_eq!(Architecture::Gfx942.lds_capacity(), 65_536);
    assert_eq!(Architecture::Gfx950.lds_capacity(), 163_840);
    for (target, size, dynamic, ok) in [
        ("gfx942", 65_536, 0, true),
        ("gfx942", 65_532, 4, true),
        ("gfx942", 65_536, 1, false),
        ("gfx942", 65_537, 0, false),
        ("gfx950", 65_537, 0, true),
        ("gfx950", 163_840, 0, true),
        ("gfx950", 163_840, 1, false),
    ] {
        let module = frontend::parse(&source(target, "s_endpgm", size)).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.dynamic_shared_bytes = dynamic;
        let result = analyze(&module, None, config);
        if ok {
            assert!(
                result.unwrap().symbolic_outputs().is_ok(),
                "{target} {size}+{dynamic}"
            );
        } else {
            assert!(
                matches!(result, Err(AnalysisError::Eval(EvalError::InvalidConfig(ref what))) if what.contains(target) && what.contains("capacity")),
                "{target} {size}+{dynamic}: {result:?}"
            );
        }
    }
}

#[test]
fn cdna4_forms_and_different_fp8_numbers_cannot_be_relabelled_as_gfx942() {
    for instruction in [
        "v_bitop3_b32 v0, v1, v2, v3 bitop3:0xc8",
        "v_cvt_pk_f16_f32 v0, v1, v2",
        "v_mfma_f32_16x16x32_f16 v[0:3], v[4:7], v[8:11], 0",
        "v_mfma_f32_16x16x32_bf16 v[0:3], v[4:7], v[8:11], 0",
        "v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[4:11], v[12:19], 0, v20, v20 op_sel_hi:[0,0,0]",
        "v_cvt_f32_fp8_e32 v0, v1",
        "v_cvt_pk_f32_bf8 v[0:1], v2",
    ] {
        let original = source("gfx950", &format!("{instruction}\ns_endpgm"), 0);
        let mut module =
            frontend::parse(&original).unwrap_or_else(|e| panic!("{instruction}: {e}"));
        assert!(
            frontend::parse(&original.replace("gfx950", "gfx942")).is_err(),
            "{instruction}"
        );
        module.target = Some("gfx942".into());
        assert!(
            matches!(
                analyze(&module, None, AnalysisConfig::new((64, 1, 1))),
                Err(AnalysisError::Lower(_))
            ),
            "typed module bypass: {instruction}"
        );
    }
}

#[test]
fn shared_cdna3_address_and_alu_forms_remain_available() {
    for instruction in [
        "v_lshl_add_u64 v[0:1], s[0:1], 0, v[2:3]",
        "v_mov_b64_e32 v[0:1], v[2:3]",
        "v_pk_fma_f32 v[0:1], v[2:3], v[4:5], v[6:7]",
        "v_cvt_pkrtz_f16_f32 v0, v1, v2",
        "v_mfma_f32_16x16x4_f32 v[0:3], v4, v5, 0",
        "v_mfma_f32_16x16x16_f16 v[0:3], v[4:5], v[6:7], 0",
        "v_mfma_f32_16x16x16bf16_1k v[0:3], v[4:5], v[6:7], 0",
    ] {
        frontend::parse(&source("gfx942", &format!("{instruction}\ns_endpgm"), 0))
            .unwrap_or_else(|e| panic!("{instruction}: {e}"));
    }
}

#[test]
fn register_names_and_unified_descriptor_allocation_have_distinct_bounds() {
    for target in ["gfx942", "gfx950"] {
        for instruction in [
            "v_mov_b32 v256, v0",
            "v_mov_b32 v511, v0",
            "v_accvgpr_mov_b32 a256, a0",
            "v_accvgpr_mov_b32 a511, a0",
            "s_mov_b32 s102, 0",
        ] {
            assert!(
                frontend::parse(&source(target, &format!("{instruction}\ns_endpgm"), 0)).is_err(),
                "{target}: {instruction}"
            );
        }
        let valid = source(target, "v_mov_b32 v4, 0x10000\nv_mov_b32 v5, 0\nv_accvgpr_write_b32 a255, 0\nglobal_store_dword v[4:5], a255, off\ns_endpgm", 0)
            .replace(".end_amdhsa_kernel", ".amdhsa_accum_offset 256\n.amdhsa_next_free_vgpr 512\n.amdhsa_next_free_sgpr 0\n.end_amdhsa_kernel");
        let module = frontend::parse(&valid).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 0x10000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        let result = analyze(&module, None, config).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 1);
        assert_eq!(
            outputs.arena.as_f64(outputs.element("out", 0).unwrap()),
            Some(0.0)
        );
        assert!(result.graph().validate().is_ok());
        for invalid in [
            valid.replace("next_free_vgpr 512", "next_free_vgpr 511"),
            valid.replace("next_free_vgpr 512", "next_free_vgpr 513"),
            valid.replace("next_free_sgpr 0", "next_free_sgpr 103"),
            valid.replace("accum_offset 256", "accum_offset 260"),
            valid.replace("accum_offset 256", "accum_offset 4"),
        ] {
            assert!(frontend::parse(&invalid).is_err(), "{target}: {invalid}");
        }
    }
}
