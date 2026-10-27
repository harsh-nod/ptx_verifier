//! Exact encoded scalar controls retained from the upstream real-number model.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph_check::GraphConclusion;

fn source(body: &str) -> String {
    let template =
        include_str!("../../../tests/gfx950/portable-negative/sentinel_off_by_one_ref.s");
    let begin = template.find("v_lshlrev_b32").unwrap();
    let end = template.find("s_endpgm").unwrap();
    format!(
        "{}v_mov_b32 v2, 0\n{body}\nglobal_store_dwordx2 v2, v[8:9], s[6:7]\n{}",
        &template[..begin],
        &template[end..]
    )
}

fn constant(register: u32, bits: u64) -> String {
    format!(
        "v_mov_b32 v{register}, 0x{:08x}\nv_mov_b32 v{}, 0x{:08x}\n",
        bits as u32,
        register + 1,
        bits >> 32
    )
}

fn run(body: &str) -> SymbolicOutputs {
    let source = source(body);
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 8,
            len: 1,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 8,
            len: 1,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let checked = gfx950_common::check(&source, &module, Some("k"), config).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let outputs = checked.analysis.into_parts().outputs.unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 1);
    outputs
}

#[test]
fn f64_runtime_sum_keeps_encoded_coefficients_distinct_from_prerounded_literal() {
    let sum = format!(
        "{}{}v_add_f64 v[8:9], v[10:11], v[12:13]",
        constant(10, 0x3fb999999999999a),
        constant(12, 0x3fc999999999999a)
    );
    // 0x3fd3333333333334 is the exact baseline's prerounded sum. Both
    // operations are interpreted over reals, so native IEEE rounding is not
    // inserted between these symbolic operations.
    let literal = format!(
        "{}v_add_f64 v[8:9], v[10:11], 0.0",
        constant(10, 0x3fd3333333333334)
    );
    let a = run(&sum);
    let b = run(&literal);
    let result = check_output_equivalence(&a, &b, &["out".into()]).unwrap();
    assert!(
        matches!(result, EquivOutcome::NotEquivalent { .. }),
        "{result:?}"
    );
}

#[test]
fn f64_fma_and_separate_multiply_add_share_the_existing_real_arithmetic_contract() {
    let inputs = format!(
        "{}{}{}",
        constant(10, 0x3fb999999999999a),
        constant(12, 0x3fc999999999999a),
        constant(14, 0x3fd3333333333333)
    );
    let fused = run(&format!(
        "{inputs}v_fma_f64 v[8:9], v[10:11], v[12:13], v[14:15]"
    ));
    let separate = run(&format!(
        "{inputs}v_mul_f64 v[16:17], v[10:11], v[12:13]\nv_add_f64 v[8:9], v[16:17], v[14:15]"
    ));
    let result = check_output_equivalence(&fused, &separate, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}
