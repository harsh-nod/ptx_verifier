//! Native counterparts for specific matrix layouts and operand encodings.
//! The manifest records each upstream assertion and each architectural change.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

struct Case {
    source: &'static str,
    reference: &'static str,
    block: u32,
    input_width: u64,
    input_len: u64,
    output_width: u64,
    output_len: u64,
    fragment: bool,
}

fn array(name: &str, base: u64, elem_width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width,
        len,
        kind,
    }
}

fn run(case: &Case) -> SymbolicOutputs {
    let module = frontend::parse(case.source).expect("legal native assembly parses");
    let mut config = AnalysisConfig::new((case.block, 1, 1));
    config.arrays = vec![
        array(
            "x",
            0x10000,
            case.input_width,
            case.input_len,
            ArrayKind::Input,
        ),
        array(
            "out",
            0x20000,
            case.output_width,
            case.output_len,
            ArrayKind::Output,
        ),
    ];
    if case.fragment {
        config
            .arrays
            .push(array("fragment", 0x20400, 2, 256, ArrayKind::Output));
    }
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let checked = gfx950_common::check(case.source, &module, Some("k"), config)
        .expect("native analysis starts");
    checked
        .analysis
        .symbolic_outputs()
        .expect("native execution completes");
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks.conclusion()
    );
    checked.analysis.into_parts().outputs.unwrap()
}

fn expected(case: &Case) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let mut values = Vec::new();
    for i in 0..case.output_len {
        let value = match case.reference {
            "transpose8" => arena.input_element(x, (i % 8) * 8 + i / 8),
            "four_pairs" => arena.input_element(x, ((i % 8) / 2) * 64 + (i / 8) * 2 + i % 2),
            "lane_words" => arena.int(if i == 0 { 1005 } else { 999 + i as i64 }),
            "weighted16" => {
                let mut sum = arena.int(0);
                for k in 0..16 {
                    let element = arena.input_element(x, (i / 16) * 16 + k);
                    let weight = arena.int((k + 1) as i64);
                    let product = arena.mul(element, weight);
                    sum = arena.add(sum, product);
                }
                sum
            }
            "ones" => arena.int(1),
            "identity_c" => arena.int(i64::from(i % 4 == 0)),
            "numeric136" => arena.int(if i == 0 { (1..=16).sum() } else { 0 }),
            "raw17" => arena.int(if i == 0 { 16 * 1 + 1 } else { 1 }),
            "mixed408" => arena.int(if i == 0 {
                (1..=16).map(|k| k + 2 * k).sum()
            } else {
                0
            }),
            "mixed476" => arena.int(if i == 0 { 476 } else { 0 }),
            "zero" => arena.int(0),
            "pair" => arena.int(if i == 0 { 1 } else { -1 }),
            "pair_relu" => arena.int(if i == 0 { 1 } else { 0 }),
            "bytes4" | "byte0" => arena.input_element(x, i),
            "bytes02" => arena.input_element(x, 2 * i),
            other => panic!("missing independent reference: {other}"),
        };
        values.push((i, value));
    }
    let mut outputs = vec![("out".into(), values)];
    if case.fragment {
        let fragment = (0..256)
            .map(|i| {
                let lane = i / 4;
                let row = lane % 16;
                let k = 4 * (lane / 16) + i % 4;
                (i, arena.input_element(x, row * 16 + k))
            })
            .collect();
        outputs.push(("fragment".into(), fragment));
    }
    SymbolicOutputs { arena, outputs }
}

fn check(case: &Case) {
    let actual = run(case);
    let expected = expected(case);
    assert_eq!(
        actual.outputs.len(),
        expected.outputs.len(),
        "complete output array footprint"
    );
    for (name, values) in &expected.outputs {
        let actual_values = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
        let indices: Vec<_> = actual_values.iter().map(|(i, _)| *i).collect();
        assert_eq!(
            indices,
            (0..values.len() as u64).collect::<Vec<_>>(),
            "complete {name} footprint"
        );
    }
    let names: Vec<_> = expected
        .outputs
        .iter()
        .map(|(name, _)| name.clone())
        .collect();
    let outcome = check_output_equivalence(&actual, &expected, &names).unwrap();
    assert!(matches!(outcome, EquivOutcome::Equivalent), "{outcome:?}");
}

const LDMATRIX_TRANSPOSE_8X8: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/ldmatrix_transpose_8x8.s"),
    reference: "transpose8",
    block: 32,
    input_width: 2,
    input_len: 64,
    output_width: 2,
    output_len: 64,
    fragment: false,
};

#[test]
fn ldmatrix_transpose_8x8() {
    check(&LDMATRIX_TRANSPOSE_8X8);
}

const LDMATRIX_FOUR_FRAGMENT_PAIRS: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/ldmatrix_four_fragment_pairs.s"),
    reference: "four_pairs",
    block: 32,
    input_width: 2,
    input_len: 256,
    output_width: 2,
    output_len: 256,
    fragment: false,
};

#[test]
fn ldmatrix_four_fragment_pairs() {
    check(&LDMATRIX_FOUR_FRAGMENT_PAIRS);
}

const STMATRIX_LANE_WORD_PLACEMENT: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/stmatrix_lane_word_placement.s"),
    reference: "lane_words",
    block: 32,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 33,
    fragment: false,
};

#[test]
fn stmatrix_lane_word_placement() {
    check(&STMATRIX_LANE_WORD_PLACEMENT);
}

const WMMA_FRAGMENT_CONTIGUOUS: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/wmma_fragment_contiguous.s"),
    reference: "weighted16",
    block: 64,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 256,
    fragment: true,
};

#[test]
fn wmma_fragment_contiguous() {
    check(&WMMA_FRAGMENT_CONTIGUOUS);
}

const WMMA_FRAGMENT_STRIDE48: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/wmma_fragment_stride48.s"),
    reference: "weighted16",
    block: 64,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 256,
    fragment: true,
};

#[test]
fn wmma_fragment_stride48() {
    check(&WMMA_FRAGMENT_STRIDE48);
}

const WMMA_FRAGMENT_STRIDE64: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/wmma_fragment_stride64.s"),
    reference: "weighted16",
    block: 64,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 256,
    fragment: true,
};

#[test]
fn wmma_fragment_stride64() {
    check(&WMMA_FRAGMENT_STRIDE64);
}

const WMMA_STORE_TILE_ONES: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/wmma_store_tile_ones.s"),
    reference: "ones",
    block: 64,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 256,
    fragment: false,
};

#[test]
fn wmma_store_tile_ones() {
    check(&WMMA_STORE_TILE_ONES);
}

const MMA_RAW_ACCUMULATOR_IDENTITY: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/mma_raw_accumulator_identity.s"),
    reference: "identity_c",
    block: 64,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 128,
    fragment: false,
};

#[test]
fn mma_raw_accumulator_identity() {
    check(&MMA_RAW_ACCUMULATOR_IDENTITY);
}

const MMA_IMMEDIATE_ACCUMULATOR_IDENTITY: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-matrix/mma_immediate_accumulator_identity.s"
    ),
    reference: "identity_c",
    block: 64,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 128,
    fragment: false,
};

#[test]
fn mma_immediate_accumulator_identity() {
    check(&MMA_IMMEDIATE_ACCUMULATOR_IDENTITY);
}

const TCGEN_NUMERIC136: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/tcgen_numeric136.s"),
    reference: "numeric136",
    block: 512,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 1024,
    fragment: false,
};

#[test]
fn tcgen_numeric136() {
    check(&TCGEN_NUMERIC136);
}

const TCGEN_RAW_OPERANDS_ACCUMULATOR17: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-matrix/tcgen_raw_operands_accumulator17.s"
    ),
    reference: "raw17",
    block: 512,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 1024,
    fragment: false,
};

#[test]
fn tcgen_raw_operands_accumulator17() {
    check(&TCGEN_RAW_OPERANDS_ACCUMULATOR17);
}

const TCGEN_NO_SWIZZLE_128X8: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/tcgen_no_swizzle_128x8.s"),
    reference: "zero",
    block: 512,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 1024,
    fragment: false,
};

#[test]
fn tcgen_no_swizzle_128x8() {
    check(&TCGEN_NO_SWIZZLE_128X8);
}

const TCGEN_MIXED_FP8_NUMERIC408: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/tcgen_mixed_fp8_numeric408.s"),
    reference: "mixed408",
    block: 512,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 1024,
    fragment: false,
};

#[test]
fn tcgen_mixed_fp8_numeric408() {
    check(&TCGEN_MIXED_FP8_NUMERIC408);
}

const TCGEN_MIXED_FP8_WRONG_B_FORMAT: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/tcgen_mixed_fp8_wrong_b_format.s"),
    reference: "mixed476",
    block: 512,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 1024,
    fragment: false,
};

#[test]
fn tcgen_mixed_fp8_wrong_b_format() {
    check(&TCGEN_MIXED_FP8_WRONG_B_FORMAT);
}

const E4M3_CONCRETE_PAIR: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/e4m3_concrete_pair.s"),
    reference: "pair",
    block: 1,
    input_width: 1,
    input_len: 1,
    output_width: 4,
    output_len: 2,
    fragment: false,
};

#[test]
fn e4m3_concrete_pair() {
    check(&E4M3_CONCRETE_PAIR);
}

const E4M3_CONCRETE_PAIR_RELU: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/e4m3_concrete_pair_relu.s"),
    reference: "pair_relu",
    block: 1,
    input_width: 1,
    input_len: 1,
    output_width: 4,
    output_len: 2,
    fragment: false,
};

#[test]
fn e4m3_concrete_pair_relu() {
    check(&E4M3_CONCRETE_PAIR_RELU);
}

const E4M3_VECTOR_BYTES: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/e4m3_vector_bytes.s"),
    reference: "bytes4",
    block: 1,
    input_width: 1,
    input_len: 8,
    output_width: 4,
    output_len: 4,
    fragment: false,
};

#[test]
fn e4m3_vector_bytes() {
    check(&E4M3_VECTOR_BYTES);
}

const E4M3_SELECTED_LOW_HALVES: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/e4m3_selected_low_halves.s"),
    reference: "bytes02",
    block: 1,
    input_width: 1,
    input_len: 4,
    output_width: 4,
    output_len: 2,
    fragment: false,
};

#[test]
fn e4m3_selected_low_halves() {
    check(&E4M3_SELECTED_LOW_HALVES);
}

const E4M3_ZERO_EXTENDED_BYTE: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/e4m3_zero_extended_byte.s"),
    reference: "byte0",
    block: 1,
    input_width: 1,
    input_len: 1,
    output_width: 4,
    output_len: 1,
    fragment: false,
};

#[test]
fn e4m3_zero_extended_byte() {
    check(&E4M3_ZERO_EXTENDED_BYTE);
}

const TCGEN_SHAPE128X256_LDS_BOUNDS: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-matrix/tcgen_shape128x256_lds_bounds.s"),
    reference: "zero",
    block: 1024,
    input_width: 2,
    input_len: 256,
    output_width: 4,
    output_len: 32768,
    fragment: false,
};

#[test]
fn tcgen_shape128x256_lds_bounds() {
    check(&TCGEN_SHAPE128X256_LDS_BOUNDS);
}

#[test]
fn skewed_and_larger_stride_fragments_match_the_contiguous_control() {
    let contiguous = run(&WMMA_FRAGMENT_CONTIGUOUS);
    for case in [&WMMA_FRAGMENT_STRIDE48, &WMMA_FRAGMENT_STRIDE64] {
        let actual = run(case);
        let outcome =
            check_output_equivalence(&actual, &contiguous, &["out".into(), "fragment".into()])
                .unwrap();
        assert!(matches!(outcome, EquivOutcome::Equivalent), "{outcome:?}");
    }
}

#[test]
fn mixed_fp8_operand_formats_cannot_be_interchanged() {
    let mixed = run(&TCGEN_MIXED_FP8_NUMERIC408);
    let wrong = run(&TCGEN_MIXED_FP8_WRONG_B_FORMAT);
    let outcome = check_output_equivalence(&mixed, &wrong, &["out".into()]).unwrap();
    assert!(
        matches!(outcome, EquivOutcome::NotEquivalent { .. }),
        "{outcome:?}"
    );
}
