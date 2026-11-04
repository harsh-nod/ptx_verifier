//! Undefined concrete reciprocals cannot disappear through zero multiplication.
mod gfx950_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

fn config(width: u64, len: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: width,
            len,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}

#[test]
fn zero_reciprocal_and_rsqrt_fail_before_undefined_values_can_be_annihilated() {
    for (source, width) in [
        (
            include_str!("../../../tests/gfx950/portable-data/zero_rcp_f32.s"),
            4,
        ),
        (
            include_str!("../../../tests/gfx950/portable-data/zero_rsqrt_f32.s"),
            4,
        ),
        (
            include_str!("../../../tests/gfx950/portable-data/zero_rcp_f64.s"),
            8,
        ),
    ] {
        let module = frontend::parse(source).unwrap();
        let checked = gfx950_common::check(source, &module, Some("k"), config(width, 1)).unwrap();
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("concrete zero reciprocal") && error.contains("undefined"),
            "{error}"
        );
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
}

#[test]
fn nonzero_f32_f64_reciprocals_and_rsqrt_keep_exact_real_expressions() {
    let source = include_str!("../../../tests/gfx950/portable-data/nonzero_reciprocals.s");
    let module = frontend::parse(source).unwrap();
    let mut cfg = config(4, 2);
    cfg.arrays.push(ArrayDef {
        name: "wide".into(),
        base: 0x20008,
        elem_width: 8,
        len: 1,
        kind: ArrayKind::Output,
    });
    let checked = gfx950_common::check(source, &module, Some("k"), cfg).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let actual = checked.analysis.into_parts().outputs.unwrap();
    let mut arena = ExprArena::new();
    let quarter = arena.float_from_f64(0.25).unwrap();
    // The upstream equivalence fragment keeps sqrt as a shared function
    // node, so use the exact independent expression instead of prerounding it.
    let four = arena.float_from_f64(4.0).unwrap();
    let root = arena.sqrt(four);
    let half = arena.rcp(root);
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![
            ("out".into(), vec![(0, quarter), (1, half)]),
            ("wide".into(), vec![(0, quarter)]),
        ],
    };
    let result =
        check_output_equivalence(&actual, &expected, &["out".into(), "wide".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}

#[test]
fn zero_times_concrete_invalid_sqrt_rsqrt_and_log_never_hides_the_domain_error() {
    for (source, width) in [
        (
            include_str!("../../../tests/gfx950/portable-data/negative_sqrt_f32.s"),
            4,
        ),
        (
            include_str!("../../../tests/gfx950/portable-data/negative_rsqrt_f32.s"),
            4,
        ),
        (
            include_str!("../../../tests/gfx950/portable-data/nonpositive_log_f32.s"),
            4,
        ),
        (
            include_str!("../../../tests/gfx950/portable-data/negative_log_f32.s"),
            4,
        ),
        (
            include_str!("../../../tests/gfx950/portable-data/negative_sqrt_f64.s"),
            8,
        ),
    ] {
        let module = frontend::parse(source).unwrap();
        let checked = gfx950_common::check(source, &module, Some("k"), config(width, 1)).unwrap();
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("undefined"), "{error}");
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
}

#[test]
fn valid_sqrt_rsqrt_and_log_use_the_existing_exact_function_fragment() {
    let source = include_str!("../../../tests/gfx950/portable-data/valid_math_domains.s");
    let module = frontend::parse(source).unwrap();
    let checked = gfx950_common::check(source, &module, Some("k"), config(4, 3)).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let actual = checked.analysis.into_parts().outputs.unwrap();
    let mut arena = ExprArena::new();
    let four = arena.float_from_f64(4.0).unwrap();
    let root = arena.sqrt(four);
    let inverse_root = arena.rcp(root);
    let one = arena.float_from_f64(1.0).unwrap();
    let logarithm = arena.log(one);
    let log2_e = arena
        .float_from_f64(std::f32::consts::LOG2_E as f64)
        .unwrap();
    let ln2 = arena.rcp(log2_e);
    let logarithm = arena.div(logarithm, ln2);
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![(
            "out".into(),
            vec![(0, root), (1, inverse_root), (2, logarithm)],
        )],
    };
    let result = check_output_equivalence(&actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}
