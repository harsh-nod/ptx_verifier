//! Genuine mixed-width ABI loads may include padding, whose bits stay unknown.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

const NATIVE: &str =
    include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-mixed-byvalue.s");

fn config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((4, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 4,
        kind: ArrayKind::Output,
    }];
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::SymFloat("alpha".into()),
        ParamValue::Float(0.5),
        ParamValue::Int(4),
        ParamValue::Int(-3),
        ParamValue::Int(250),
    ];
    config
}

fn expected(offset: f64) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let alpha = arena.param_symbol("alpha");
    let offset = arena.float_from_f64(offset).unwrap();
    let result = arena.add(alpha, offset);
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), (0..4).map(|index| (index, result)).collect())],
    }
}

#[test]
fn native_mixed_byvalue_parameters_ignore_only_unobserved_padding() {
    let module = frontend::parse(NATIVE).unwrap();
    let checked = gfx950_common::check(NATIVE, &module, Some("mixed_byvalue"), config()).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let outputs = checked.analysis.into_parts().outputs.unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 4);
    // Independent typed reference: alpha + f64(0.5) + i16(-3) + u8(250).
    let result = check_output_equivalence(&outputs, &expected(247.5), &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
    let result = check_output_equivalence(&outputs, &expected(247.0), &["out".into()]).unwrap();
    assert!(
        matches!(result, EquivOutcome::NotEquivalent { .. }),
        "{result:?}"
    );
}

#[test]
fn selecting_or_observing_unknown_byvalue_padding_never_gets_a_verdict() {
    let select_unknown = NATIVE.replacen(".offset:         30", ".offset:         31", 1);
    assert_ne!(select_unknown, NATIVE);
    let arithmetic = NATIVE.replace("s_sext_i32_i16 s0, s3", "s_add_u32 s0, s3, 0");
    let float = NATIVE.replace("v_cvt_f32_ubyte2_e32 v2, s8", "v_add_f32_e32 v2, s8, v2");
    let store = NATIVE.replace(
        "global_store_dword v0, v1, s[4:5]",
        "v_mov_b32_e32 v1, s8\n\tglobal_store_dword v0, v1, s[4:5]",
    );
    for source in [select_unknown, arithmetic, float, store] {
        assert_ne!(source, NATIVE);
        let module = frontend::parse(&source).unwrap();
        let checked =
            gfx950_common::check(&source, &module, Some("mixed_byvalue"), config()).unwrap();
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("undefined"), "{error}");
        assert!(
            matches!(checked.checks.conclusion(), GraphConclusion::Unknown { .. }),
            "{:#?}",
            checked.checks
        );
    }
}
