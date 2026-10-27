//! Concrete native unsigned64 output must not inherit i64 constant overflow.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprNode, Real, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

#[test]
fn unsigned64_shifts_preserve_the_top_bit_and_distinct_low_high_words() {
    let source = include_str!("../../../tests/gfx950/portable-data/u64_shift_boundaries.s");
    let module = frontend::parse(source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 8,
            len: 1,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 8,
            len: 4,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let checked = gfx950_common::check(source, &module, Some("k"), config).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let actual = checked.analysis.into_parts().outputs.unwrap();
    assert_eq!(actual.outputs[0].1.len(), 4);
    let mut arena = ExprArena::new();
    let values = [
        0x8000_0000_0000_0000u64,
        u64::MAX,
        0x89ab_cdef_0123_4567,
        0x0123_4567_89ab_cdef,
    ];
    let elements = values
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            let expected = Real::from_rational(value.into());
            let found = match actual
                .arena
                .node(actual.element("out", index as u64).unwrap())
            {
                ExprNode::IntConst(value) => Real::from_i64(*value),
                ExprNode::RealConst(value) => value.clone(),
                other => panic!("unexpected unsigned constant {other:?}"),
            };
            assert_eq!(found, expected, "unsigned value {value:#018x}");
            (index as u64, arena.real(expected))
        })
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    };
    let result = check_output_equivalence(&actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}
