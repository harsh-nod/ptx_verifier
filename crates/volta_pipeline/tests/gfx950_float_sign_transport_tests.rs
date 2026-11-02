//! Public compiler float-sign idioms preserve the existing real-arithmetic contract.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph_check::GraphConclusion;

const FLOAT_OPS: &str = include_str!("../../volta_amd_analysis/tests/fixtures/float_ops.s");

fn array(name: &str, base: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: 4,
        len,
        kind,
    }
}

/// Independently transcribe the 21 assignments in float_ops.cl. The 11 unwritten
/// slots in each 32-float row remain allocated, but are absent from the footprint.
fn expected_float_ops() -> SymbolicOutputs {
    let mut expected = SymbolicOutputs::default();
    let arena = &mut expected.arena;
    let a = arena.intern_string("a");
    let b = arena.intern_string("b");
    let numerator = arena.int(8_388_608);
    let denominator = arena.int(12_102_203);
    let ln2 = arena.div(numerator, denominator);
    let two = arena.int(2);
    let mut outputs = Vec::new();
    for lane in 0..64 {
        let x = arena.input_element(a, lane);
        let y = arena.input_element(b, lane);
        let neg = arena.neg(x);
        let abs = arena.abs(x);
        let sqrt = arena.sqrt(x);
        let rsq = arena.rcp(sqrt);
        let scaled = arena.mul(x, ln2);
        let exp2 = arena.exp(scaled);
        let log = arena.log(x);
        let log2 = arena.div(log, ln2);
        let reciprocal = arena.rcp(x);
        let add = arena.add(x, y);
        let sub = arena.sub(x, y);
        let mul = arena.mul(x, y);
        let reciprocal_y = arena.rcp(y);
        let div = arena.mul(x, reciprocal_y);
        let min = arena.min(x, y);
        let max = arena.max(x, y);
        let fma = arena.fma(x, y, x);
        let lt = arena.lt(x, y);
        let select_lt = arena.select(lt, x, two);
        let gt = arena.gt(x, y);
        let select_gt = arena.select(gt, x, mul);
        let le = arena.le(x, y);
        let select_le = arena.select(le, x, mul);
        let ge = arena.ge(x, y);
        let select_ge = arena.select(ge, x, mul);
        let eq = arena.eq(x, y);
        let select_eq = arena.select(eq, x, mul);
        let ne = arena.ne(x, y);
        let select_ne = arena.select(ne, x, mul);
        let negative_abs = arena.neg(abs);
        for (column, expression) in [
            neg, abs, sqrt, rsq, exp2, log2, reciprocal, add, sub, mul, div, min, max, fma,
            select_lt, select_gt, select_le, select_ge, select_eq, select_ne, negative_abs,
        ]
        .into_iter()
        .enumerate()
        {
            outputs.push((32 * lane + column as u64, expression));
        }
    }
    expected.outputs.push(("out".into(), outputs));
    expected
}

#[test]
fn unchanged_float_ops_proves_all_1344_writes_and_preserves_row_holes() {
    let module = frontend::parse(FLOAT_OPS).unwrap();
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("a", 0x10000, 64, ArrayKind::Input),
        array("b", 0x20000, 64, ArrayKind::Input),
        array("out", 0x30000, 2048, ArrayKind::Output),
    ];
    config.params = ["a", "b", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    let checked = gfx950_common::check(FLOAT_OPS, &module, Some("float_ops"), config).unwrap();
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].1.len(), 1344);
    for lane in 0..64 {
        for column in 0..32 {
            assert_eq!(actual.element("out", 32 * lane + column).is_some(), column < 21);
        }
    }
    assert!(matches!(
        check_output_equivalence(actual, &expected_float_ops(), &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
