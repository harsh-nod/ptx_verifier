//! Source width determines floating inline bits even for scalar bit operations.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend,
};
use volta_equivalence::{EquivCheckOptions, EquivOutcome, check_output_equivalence_with};
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const TARGETS: [&str; 3] = ["gfx942", "gfx950", "gfx1250"];

fn module(target: &str, body: &str) -> frontend::Module {
    let template = match target {
        "gfx942" => include_str!("fixtures/scalar-inline64/gfx942.s"),
        "gfx950" => include_str!("fixtures/scalar-inline64/gfx950.s"),
        "gfx1250" => include_str!("fixtures/scalar-inline64/gfx1250.s"),
        _ => unreachable!(),
    };
    let source = template.replace("s_mov_b64 s[8:9],1.0", body);
    frontend::parse(&source).unwrap()
}

fn execute(module: &frontend::Module) -> AnalysisResult {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    analyze(module, Some("k"), config).unwrap()
}

fn run(target: &str, body: &str) -> AnalysisResult {
    execute(&module(target, body))
}

fn assert_words(result: &AnalysisResult, low: u32, high: u32) {
    result.graph().validate().unwrap();
    let safety = check_graph(result.graph());
    assert_eq!(
        safety.conclusion(),
        GraphConclusion::Verified,
        "{safety:#?}"
    );
    let actual = result.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        vec![0, 1]
    );
    let source = format!(
        "dim N; array out[N]; out[i] = {low} + i * {};",
        i64::from(high) - i64::from(low)
    );
    let spec = volta_spec::parse_spec(&source).unwrap();
    let (env, outputs) =
        volta_spec::instantiate(&spec, &std::collections::HashMap::from([("N".into(), 2)]))
            .unwrap();
    let expected = volta_spec::unfold(&outputs, &env, 0).unwrap();
    let report = check_output_equivalence_with(
        actual,
        &expected,
        &["out".into()],
        &EquivCheckOptions {
            sample: 0,
            verify_numeric: true,
            ..Default::default()
        },
    )
    .unwrap();
    assert_eq!(report.elements_total, 2);
    assert_eq!(report.elements_checked, 2);
    assert!(
        matches!(report.outcome, EquivOutcome::Equivalent),
        "{report:?}"
    );
}

#[test]
fn complete_mc_accepted_modules_match_both_native_words() {
    for target in TARGETS {
        let result = run(target, "s_mov_b64 s[8:9],1.0");
        assert_eq!(
            result.stats.instructions,
            if target == "gfx1250" { 13 } else { 12 }
        );
        assert_words(&result, 0, 0x3ff0_0000);
    }
}

#[test]
fn positive_inline_table_preserves_the_entire_64_bit_encoding() {
    // CDNA4 operand table / CDNA5 section 4.1, including selector 248's exact bits.
    for (literal, low, high) in [
        ("0.0", 0, 0),
        ("0.5", 0, 0x3fe0_0000),
        ("1.0", 0, 0x3ff0_0000),
        ("2.0", 0, 0x4000_0000),
        ("4.0", 0, 0x4010_0000),
        ("0.15915494309189532", 0x6dc9_c882, 0x3fc4_5f30),
    ] {
        for target in TARGETS {
            assert_words(
                &run(target, &format!("s_mov_b64 s[8:9],{literal}")),
                low,
                high,
            );
        }
    }
}

#[test]
fn either_binary_source_and_aliased_destination_keep_both_words() {
    for target in TARGETS {
        for operation in ["s_or_b64", "s_xor_b64"] {
            for (a, b) in [("s[8:9]", "1.0"), ("1.0", "s[8:9]")] {
                assert_words(
                    &run(
                        target,
                        &format!("s_mov_b64 s[8:9],0\n{operation} s[8:9],{a},{b}"),
                    ),
                    0,
                    0x3ff0_0000,
                );
            }
        }
    }
}

#[test]
fn typed_ast_negative_inline_values_keep_the_sign_and_high_word() {
    // AST clients can supply a native inline Float directly. This does not
    // broaden the source lexer's conservative negative-modifier profile.
    for target in TARGETS {
        for (value, high) in [
            (-0.5, 0xbfe0_0000),
            (-1.0, 0xbff0_0000),
            (-2.0, 0xc000_0000),
            (-4.0, 0xc010_0000),
        ] {
            let mut module = module(target, "s_mov_b64 s[8:9],1.0");
            let instruction = module.kernels[0]
                .instructions
                .iter_mut()
                .find(|instruction| instruction.mnemonic == "s_mov_b64")
                .unwrap();
            instruction.operands[1] = frontend::Operand::Float(value);
            assert_words(&execute(&module), 0, high);
        }
    }
}

#[test]
fn shifts_keep_a_32_bit_count_and_a_64_bit_data_source() {
    for target in TARGETS {
        for count in ["0.15915494309189532", "0.15915494", "0x3e22f983"] {
            // Inline32 inverse-two-pi ends in 0x83 (shift 3); Inline64's
            // corresponding low word ends in 0x82 (shift 2).
            assert_words(
                &run(
                    target,
                    &format!("s_mov_b64 s[8:9],1\ns_lshl_b64 s[8:9],s[8:9],{count}"),
                ),
                8,
                0,
            );
            assert_words(
                &run(
                    target,
                    &format!("s_mov_b64 s[8:9],16\ns_lshr_b64 s[8:9],s[8:9],{count}"),
                ),
                2,
                0,
            );
        }
        assert_words(&run(target, "s_lshl_b64 s[8:9],1.0,1"), 0, 0x7fe0_0000);
    }
}

#[test]
fn raw_integer_and_32_bit_float_sources_keep_their_original_bits() {
    for target in TARGETS {
        for body in [
            "s_mov_b64 s[8:9],0x3f800000",
            "s_mov_b32 s8,1.0\ns_mov_b32 s9,0",
        ] {
            assert_words(&run(target, body), 0x3f80_0000, 0);
        }
    }
}

#[test]
fn scalar_flags_and_empty_exec_do_not_change_inline_bit_semantics() {
    for target in TARGETS {
        assert_words(
            &run(
                target,
                "s_cmp_eq_u32 0,1\ns_mov_b64 s[8:9],1.0\ns_cselect_b32 s8,1,0",
            ),
            0,
            0x3ff0_0000,
        );
        assert_words(
            &run(
                target,
                "s_mov_b64 s[8:9],1.0\ns_xor_b64 s[8:9],s[8:9],1.0\ns_cselect_b32 s8,1,0",
            ),
            0,
            0,
        );
        assert_words(
            &run(
                target,
                "s_mov_b64 s[8:9],0\ns_or_b64 s[8:9],s[8:9],1.0\ns_cselect_b32 s8,1,0",
            ),
            1,
            0x3ff0_0000,
        );
        let exec = if target != "gfx1250" {
            "s_mov_b64 exec"
        } else {
            "s_mov_b32 exec_lo"
        };
        assert_words(
            &run(target, &format!("{exec},0\ns_mov_b64 s[8:9],1.0\n{exec},1")),
            0,
            0x3ff0_0000,
        );
    }
}

#[test]
fn noninline_or_rounded_decimal_float_sources_refuse_without_outputs() {
    for target in TARGETS {
        for literal in ["1.5", "1.0000000001", "0.15915494"] {
            let result = run(target, &format!("s_mov_b64 s[8:9],{literal}"));
            assert!(result.symbolic_outputs().is_err());
            let report = check_graph(result.graph());
            assert!(
                matches!(report.conclusion(), GraphConclusion::Unknown { .. }),
                "{report:#?}"
            );
            assert!(
                result
                    .symbolic_outputs()
                    .unwrap_err()
                    .to_string()
                    .contains("exact floating inline constant")
            );
        }
    }
}

#[test]
fn float_decoding_never_releases_a_pending_scalar_register_source() {
    for target in TARGETS {
        let load = if target != "gfx1250" {
            "s_load_dwordx2"
        } else {
            "s_load_b64"
        };
        let result = run(
            target,
            &format!("{load} s[8:9],s[0:1],0\ns_or_b64 s[8:9],s[8:9],1.0"),
        );
        let safety = check_graph(result.graph());
        assert_eq!(
            safety.verdict(Property::AmdWaitReadiness),
            Verdict::Fail,
            "{safety:#?}"
        );
    }
}

#[test]
fn finite_gfx1250_and_compare_profiles_still_refuse_float_sources() {
    for body in [
        "s_mov_b64 s[8:9],0\ns_and_b64 s[8:9],s[8:9],1.0",
        "s_mov_b64 s[8:9],0\ns_cmp_eq_u64 s[8:9],1.0",
    ] {
        let result = run("gfx1250", body);
        assert!(result.symbolic_outputs().is_err());
        assert!(matches!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
}
