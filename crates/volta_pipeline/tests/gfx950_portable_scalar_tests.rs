//! Portable scalar/output contracts paired with the actual upstream fixtures.
//! Every native source is assembled for gfx950; source mapping is in
//! tests/gfx950/portable-scalar/cases.json. These are real-number model checks,
//! sharing the upstream abstraction for rounding and approximate math.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, ExprNode, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

struct Case {
    source: &'static str,
    expected: &'static str,
    block: u32,
    input_width: u64,
    input_len: u64,
    output_width: u64,
    output_len: u64,
    dynamic_shared: u64,
    input_base: u64,
    output_base: u64,
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

fn execute(source: &str, kernel: &str, config: AnalysisConfig) -> SymbolicOutputs {
    let module = frontend::parse(source).expect("native assembly parses");
    let checked = gfx950_common::check(source, &module, Some(kernel), config)
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
    checked
        .analysis
        .into_parts()
        .outputs
        .expect("native execution produces outputs")
}

fn expected(kind: &str, count: u64) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let inputs: Vec<ExprId> = (0..32).map(|i| arena.input_element(x, i)).collect();
    let mut values = Vec::new();
    for i in 0..count {
        if kind == "elect_skip" && i == 0 {
            continue;
        }
        let integer = match kind {
            "zero" => Some(0),
            "three" => Some(3),
            "shift16" => Some([0, 0, 65535][i as usize]),
            "shift64" => Some([3298534883328, 3][i as usize]),
            "bfe" => Some([10, 4294967290, 4294967295, 0][i as usize]),
            "bfi" => Some([48, 5, 5, 7][i as usize]),
            "intabs" => Some([5, 2147483648][i as usize]),
            "one" => Some(1),
            "magicdiv" => Some([1, 3][i as usize]),
            "funnel" => Some([286331153, 572662306, 143165576, 1145324612][i as usize]),
            "elect" => Some(if i == 0 { 1000 } else { 0 }),
            "elect_skip" => Some(if i == 1 { 1001 } else { 0 }),
            "offsets" => Some(i as i64 * 4),
            "fortytwo" => Some(42),
            "seven" => Some(7),
            "regionedge" => Some([7, 1][i as usize]),
            _ => None,
        };
        let value = if let Some(value) = integer {
            arena.int(value)
        } else {
            match kind {
                "copy" | "bytepair" => inputs[i as usize],
                "copy4" => inputs[4],
                "exchange" => inputs[(i ^ 1) as usize],
                "abs_bits" => match i {
                    0 => arena.int(5),
                    1 => arena.float_from_f64(f64::INFINITY).unwrap(),
                    2 => arena.abs(inputs[0]),
                    _ => unreachable!(),
                },
                "raw_math" => match i {
                    0 => arena.int(2),
                    1 => arena.float_from_f64(0.25).unwrap(),
                    2 => {
                        let four = arena.int(4);
                        arena.sqrt(four)
                    }
                    3 => arena.int(1),
                    4 => arena.int(-4),
                    5 => {
                        let abs = arena.abs(inputs[0]);
                        arena.neg(abs)
                    }
                    _ => unreachable!(),
                },
                "neg_bits" => match i {
                    0 | 2 => arena.int(5),
                    1 => arena.int(2147483648),
                    3 => arena.float_from_f64(f64::INFINITY).unwrap(),
                    4 => arena.neg(inputs[0]),
                    _ => unreachable!(),
                },
                "packed_fma" => {
                    arena.fma(inputs[i as usize], inputs[i as usize], inputs[i as usize])
                }
                "packed_square" => arena.mul(inputs[i as usize], inputs[i as usize]),
                "div3" | "div768" => {
                    let divisor = arena.int(if kind == "div3" { 3 } else { 768 });
                    arena.div(inputs[0], divisor)
                }
                "sum16" => inputs[..16]
                    .iter()
                    .copied()
                    .reduce(|a, b| arena.add(a, b))
                    .unwrap(),
                "exp" => arena.exp(inputs[0]),
                "tanh" | "tanh_zero_fragment" => {
                    let z = if kind == "tanh" {
                        let two = arena.int(2);
                        arena.mul(inputs[0], two)
                    } else {
                        arena.int(0)
                    };
                    let e = arena.exp(z);
                    let one = arena.int(1);
                    let numerator = arena.sub(e, one);
                    let denominator = arena.add(e, one);
                    arena.div(numerator, denominator)
                }
                _ => panic!("missing independent reference for {kind}"),
            }
        };
        values.push((i, value));
    }
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    }
}

fn run(case: &Case) -> SymbolicOutputs {
    let mut config = AnalysisConfig::new((case.block, 1, 1));
    config.dynamic_shared_bytes = case.dynamic_shared;
    config.arrays = vec![
        array(
            "x",
            case.input_base,
            case.input_width,
            case.input_len,
            ArrayKind::Input,
        ),
        array(
            "out",
            case.output_base,
            case.output_width,
            case.output_len,
            ArrayKind::Output,
        ),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    execute(case.source, "k", config)
}

fn check(case: &Case) {
    let mut actual = run(case);
    let mut expected = expected(case.expected, case.output_len);
    assert_eq!(actual.outputs.len(), 1, "unexpected output arrays");
    let actual_indices: Vec<u64> = actual.outputs[0].1.iter().map(|(i, _)| *i).collect();
    let expected_indices: Vec<u64> = expected.outputs[0].1.iter().map(|(i, _)| *i).collect();
    assert_eq!(
        actual_indices, expected_indices,
        "complete written footprint"
    );
    // Non-finite constants are outside polynomial equivalence; compare their
    // exact sign/value directly, retaining the footprint assertion above.
    let nonfinite: Vec<u64> = expected.outputs[0]
        .1
        .iter()
        .filter_map(|(i, root)| match expected.arena.node(*root) {
            ExprNode::RealConst(value) if value.is_infinite() => {
                let actual_root = actual.element("out", *i).unwrap();
                assert_eq!(actual.arena.node(actual_root), expected.arena.node(*root));
                Some(*i)
            }
            _ => None,
        })
        .collect();
    actual.outputs[0].1.retain(|(i, _)| !nonfinite.contains(i));
    expected.outputs[0]
        .1
        .retain(|(i, _)| !nonfinite.contains(i));
    let result = check_output_equivalence(&actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}

const COPYSIGN_COMBINES_THE_SIGN_OF_A_WITH_THE_MAGNITUDE_OF_B: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/copysign_combines_the_sign_of_a_with_the_magnitude_of_b.s"
    ),
    expected: "zero",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn copysign_combines_the_sign_of_a_with_the_magnitude_of_b() {
    check(&COPYSIGN_COMBINES_THE_SIGN_OF_A_WITH_THE_MAGNITUDE_OF_B);
}

const FLOAT_ABS_DECODES_RAW_BITS: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/float_abs_decodes_raw_bits.s"),
    expected: "abs_bits",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 3,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn float_abs_decodes_raw_bits() {
    check(&FLOAT_ABS_DECODES_RAW_BITS);
}

const FLOAT_OPS_DECODE_RAW_BIT_PATTERNS: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/float_ops_decode_raw_bit_patterns.s"
    ),
    expected: "raw_math",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 6,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn float_ops_decode_raw_bit_patterns() {
    check(&FLOAT_OPS_DECODE_RAW_BIT_PATTERNS);
}

const NEG_READS_OPERAND_AS_INSTRUCTION_TYPE: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/neg_reads_operand_as_instruction_type.s"
    ),
    expected: "neg_bits",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 5,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn neg_reads_operand_as_instruction_type() {
    check(&NEG_READS_OPERAND_AS_INSTRUCTION_TYPE);
}

const MIXED_PRECISION_FMA_DECODES_MULTIPLICANDS_AT_THEIR_OWN_TYPE: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/mixed_precision_fma_decodes_multiplicands_at_their_own_type.s"
    ),
    expected: "three",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn mixed_precision_fma_decodes_multiplicands_at_their_own_type() {
    check(&MIXED_PRECISION_FMA_DECODES_MULTIPLICANDS_AT_THEIR_OWN_TYPE);
}

const F32X2_CONSTANT_BIT_PATTERN_OPERAND: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/f32x2_constant_bit_pattern_operand.s"
    ),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_constant_bit_pattern_operand() {
    check(&F32X2_CONSTANT_BIT_PATTERN_OPERAND);
}

const F32X2_FMA_VIA_64BIT_MEMORY_ACCESS: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/f32x2_fma_via_64bit_memory_access.s"
    ),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_fma_via_64bit_memory_access() {
    check(&F32X2_FMA_VIA_64BIT_MEMORY_ACCESS);
}

const F32X2_FMA_VIA_REGISTER_PACK: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/f32x2_fma_via_register_pack.s"),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_fma_via_register_pack() {
    check(&F32X2_FMA_VIA_REGISTER_PACK);
}

const F32X2_LANE_EXTRACTED_WITH_SHIFT: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/f32x2_lane_extracted_with_shift.s"),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_lane_extracted_with_shift() {
    check(&F32X2_LANE_EXTRACTED_WITH_SHIFT);
}

const F32X2_MUL_ADD_VIA_REGISTER_PACK: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/f32x2_mul_add_via_register_pack.s"),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_mul_add_via_register_pack() {
    check(&F32X2_MUL_ADD_VIA_REGISTER_PACK);
}

const F32X2_OPERAND_ASSEMBLED_WITH_CVT_ZERO_EXTENSION: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/f32x2_operand_assembled_with_cvt_zero_extension.s"
    ),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_operand_assembled_with_cvt_zero_extension() {
    check(&F32X2_OPERAND_ASSEMBLED_WITH_CVT_ZERO_EXTENSION);
}

const F32X2_OPERAND_ASSEMBLED_WITH_SHIFT_AND_OR: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/f32x2_operand_assembled_with_shift_and_or.s"
    ),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_operand_assembled_with_shift_and_or() {
    check(&F32X2_OPERAND_ASSEMBLED_WITH_SHIFT_AND_OR);
}

const F32X2_SCALAR_REFERENCE: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/f32x2_scalar_reference.s"),
    expected: "packed_fma",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_scalar_reference() {
    check(&F32X2_SCALAR_REFERENCE);
}

const F32X2_WRONG_LANE_MATH: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/f32x2_wrong_lane_math.s"),
    expected: "packed_square",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn f32x2_wrong_lane_math() {
    check(&F32X2_WRONG_LANE_MATH);
}

const B16_SHIFT_AMOUNT_IS_READ_AS_U32: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/b16_shift_amount_is_read_as_u32.s"),
    expected: "shift16",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 3,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn b16_shift_amount_is_read_as_u32() {
    check(&B16_SHIFT_AMOUNT_IS_READ_AS_U32);
}

const B64_SHIFT_BY_U32_REGISTER: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/b64_shift_by_u32_register.s"),
    expected: "shift64",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 8,
    output_len: 2,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn b64_shift_by_u32_register() {
    check(&B64_SHIFT_BY_U32_REGISTER);
}

const BFE_EXTRACT_AND_SIGN_FILL: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/bfe_extract_and_sign_fill.s"),
    expected: "bfe",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn bfe_extract_and_sign_fill() {
    check(&BFE_EXTRACT_AND_SIGN_FILL);
}

const BFI_CLIPS_FIELD_TO_REGISTER_WIDTH: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/bfi_clips_field_to_register_width.s"
    ),
    expected: "bfi",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn bfi_clips_field_to_register_width() {
    check(&BFI_CLIPS_FIELD_TO_REGISTER_WIDTH);
}

const INT_ABS_READ_AT_SIGNED_WIDTH: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/int_abs_read_at_signed_width.s"),
    expected: "intabs",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 2,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn int_abs_read_at_signed_width() {
    check(&INT_ABS_READ_AT_SIGNED_WIDTH);
}

const MUL_HI_U32_NEGATIVE_OPERAND: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/mul_hi_u32_negative_operand.s"),
    expected: "one",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn mul_hi_u32_negative_operand() {
    check(&MUL_HI_U32_NEGATIVE_OPERAND);
}

const MUL_WIDE_U16_MAGIC_DIVISION: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/mul_wide_u16_magic_division.s"),
    expected: "magicdiv",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 2,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn mul_wide_u16_magic_division() {
    check(&MUL_WIDE_U16_MAGIC_DIVISION);
}

const SHF_CLAMP_NEGATIVE_SHIFT_AMOUNT_SATURATES: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/shf_clamp_negative_shift_amount_saturates.s"
    ),
    expected: "funnel",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn shf_clamp_negative_shift_amount_saturates() {
    check(&SHF_CLAMP_NEGATIVE_SHIFT_AMOUNT_SATURATES);
}

const DIV_BY_THREE_VS_RCP_OF_THREE: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/div_by_three_vs_rcp_of_three.s"),
    expected: "div3",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn div_by_three_vs_rcp_of_three() {
    check(&DIV_BY_THREE_VS_RCP_OF_THREE);
}

const DIV_BY_THREE_VS_RCP_OF_THREE_2: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/div_by_three_vs_rcp_of_three_2.s"),
    expected: "div3",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn div_by_three_vs_rcp_of_three_2() {
    check(&DIV_BY_THREE_VS_RCP_OF_THREE_2);
}

const DIV_BY_N_VS_MUL_BY_COMPUTED_RECIPROCAL: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/div_by_n_vs_mul_by_computed_reciprocal.s"
    ),
    expected: "div768",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn div_by_n_vs_mul_by_computed_reciprocal() {
    check(&DIV_BY_N_VS_MUL_BY_COMPUTED_RECIPROCAL);
}

const DIV_BY_N_VS_MUL_BY_COMPUTED_RECIPROCAL_2: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/div_by_n_vs_mul_by_computed_reciprocal_2.s"
    ),
    expected: "div768",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn div_by_n_vs_mul_by_computed_reciprocal_2() {
    check(&DIV_BY_N_VS_MUL_BY_COMPUTED_RECIPROCAL_2);
}

const ELECT_SYNC_ELECTS_THE_LOWEST_ACTIVE_LANE: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/elect_sync_elects_the_lowest_active_lane.s"
    ),
    expected: "elect",
    block: 32,
    input_width: 4,
    input_len: 32,
    output_width: 4,
    output_len: 32,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn elect_sync_elects_the_lowest_active_lane() {
    check(&ELECT_SYNC_ELECTS_THE_LOWEST_ACTIVE_LANE);
}

const ELECT_SYNC_SKIPS_AN_ALREADY_EXITED_LANE: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/elect_sync_skips_an_already_exited_lane.s"
    ),
    expected: "elect_skip",
    block: 32,
    input_width: 4,
    input_len: 32,
    output_width: 4,
    output_len: 32,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn elect_sync_skips_an_already_exited_lane() {
    check(&ELECT_SYNC_SKIPS_AN_ALREADY_EXITED_LANE);
}

const SHFL_SYNC_IDX_EXCHANGE: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/shfl_sync_idx_exchange.s"),
    expected: "exchange",
    block: 2,
    input_width: 4,
    input_len: 2,
    output_width: 4,
    output_len: 2,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn shfl_sync_idx_exchange() {
    check(&SHFL_SYNC_IDX_EXCHANGE);
}

const TAIL_EXIT_WARP_SHFL_REDUCTION: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/tail_exit_warp_shfl_reduction.s"),
    expected: "sum16",
    block: 32,
    input_width: 4,
    input_len: 16,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn tail_exit_warp_shfl_reduction() {
    check(&TAIL_EXIT_WARP_SHFL_REDUCTION);
}

const TAIL_EXIT_WARP_SHFL_REDUCTION_REFERENCE: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/tail_exit_warp_shfl_reduction_reference.s"
    ),
    expected: "sum16",
    block: 1,
    input_width: 4,
    input_len: 16,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn tail_exit_warp_shfl_reduction_reference() {
    check(&TAIL_EXIT_WARP_SHFL_REDUCTION_REFERENCE);
}

const SYMEXPF_CALLSEQ: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/symexpf_callseq.s"),
    expected: "exp",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn symexpf_callseq() {
    check(&SYMEXPF_CALLSEQ);
}

const TANH_APPROX_EXPANDS_TO_EXP_FRAGMENT: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/tanh_approx_expands_to_exp_fragment.s"
    ),
    expected: "tanh",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn tanh_approx_expands_to_exp_fragment() {
    check(&TANH_APPROX_EXPANDS_TO_EXP_FRAGMENT);
}

const TANH_APPROX_ZERO_VS_ZERO: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/tanh_approx_zero_vs_zero.s"),
    expected: "tanh_zero_fragment",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn tanh_approx_zero_vs_zero() {
    check(&TANH_APPROX_ZERO_VS_ZERO);
}

const TANH_APPROX_ZERO_VS_ZERO_2: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/tanh_approx_zero_vs_zero_2.s"),
    expected: "zero",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn tanh_approx_zero_vs_zero_2() {
    check(&TANH_APPROX_ZERO_VS_ZERO_2);
}

const CVTA_TO_GLOBAL_ACCEPTED: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/cvta_to_global_accepted.s"),
    expected: "copy",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn cvta_to_global_accepted() {
    check(&CVTA_TO_GLOBAL_ACCEPTED);
}

const MAPA_RANK_ZERO_IS_THE_IDENTITY: Case = Case {
    source: include_str!("../../../tests/gfx950/portable-scalar/mapa_rank_zero_is_the_identity.s"),
    expected: "offsets",
    block: 4,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 4,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn mapa_rank_zero_is_the_identity() {
    check(&MAPA_RANK_ZERO_IS_THE_IDENTITY);
}

const EXTERN_ONLY_SHARED_PLACEMENT_AND_BOUNDS: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/extern_only_shared_placement_and_bounds.s"
    ),
    expected: "fortytwo",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 16,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn extern_only_shared_placement_and_bounds() {
    check(&EXTERN_ONLY_SHARED_PLACEMENT_AND_BOUNDS);
}

const EXTERN_VS_STATIC_SHARED_NO_FALSE_RACE: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/extern_vs_static_shared_no_false_race.s"
    ),
    expected: "seven",
    block: 2,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 16,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn extern_vs_static_shared_no_false_race() {
    check(&EXTERN_VS_STATIC_SHARED_NO_FALSE_RACE);
}

const BYTE_PAIR_ROUND_TRIPS_THROUGH_SHARED_MEMORY_AT_NATIVE_16_BIT_WIDTH: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/byte_pair_round_trips_through_shared_memory_at_native_16_bit_width.s"
    ),
    expected: "bytepair",
    block: 1,
    input_width: 1,
    input_len: 2,
    output_width: 4,
    output_len: 2,
    dynamic_shared: 16,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn byte_pair_round_trips_through_shared_memory_at_native_16_bit_width() {
    check(&BYTE_PAIR_ROUND_TRIPS_THROUGH_SHARED_MEMORY_AT_NATIVE_16_BIT_WIDTH);
}

const UPPER_HALF_ADDRESS_SPACE_ACCESS_IN_BOUNDS: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/upper_half_address_space_access_in_bounds.s"
    ),
    expected: "copy4",
    block: 1,
    input_width: 4,
    input_len: 8,
    output_width: 4,
    output_len: 1,
    dynamic_shared: 0,
    input_base: 9223372036854775792,
    output_base: 131072,
};

#[test]
fn upper_half_address_space_access_in_bounds() {
    check(&UPPER_HALF_ADDRESS_SPACE_ACCESS_IN_BOUNDS);
}

const REGION_EDGE_EXACT_FIT_ACCESSES_PASS: Case = Case {
    source: include_str!(
        "../../../tests/gfx950/portable-scalar/region_edge_exact_fit_accesses_pass.s"
    ),
    expected: "regionedge",
    block: 1,
    input_width: 4,
    input_len: 4,
    output_width: 4,
    output_len: 2,
    dynamic_shared: 0,
    input_base: 65536,
    output_base: 131072,
};

#[test]
fn region_edge_exact_fit_accesses_pass() {
    check(&REGION_EDGE_EXACT_FIT_ACCESSES_PASS);
}

#[test]
fn packed_native_variants_match_the_scalar_reference_and_reject_wrong_math() {
    let scalar = run(&F32X2_SCALAR_REFERENCE);
    for case in [
        &F32X2_CONSTANT_BIT_PATTERN_OPERAND,
        &F32X2_FMA_VIA_64BIT_MEMORY_ACCESS,
        &F32X2_FMA_VIA_REGISTER_PACK,
        &F32X2_LANE_EXTRACTED_WITH_SHIFT,
        &F32X2_MUL_ADD_VIA_REGISTER_PACK,
        &F32X2_OPERAND_ASSEMBLED_WITH_CVT_ZERO_EXTENSION,
        &F32X2_OPERAND_ASSEMBLED_WITH_SHIFT_AND_OR,
    ] {
        let actual = run(case);
        let result = check_output_equivalence(&actual, &scalar, &["out".into()]).unwrap();
        assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
    }
    let wrong = run(&F32X2_WRONG_LANE_MATH);
    let result = check_output_equivalence(&wrong, &scalar, &["out".into()]).unwrap();
    assert!(
        matches!(result, EquivOutcome::NotEquivalent { .. }),
        "{result:?}"
    );
}

#[test]
fn module_global_window_half_open_boundary_is_disjoint_and_bindings_are_loaded() {
    // The upstream positive boundary has no writes. This counterpart also
    // reads actual initialized/BSS/overridden objects, strengthening that check.
    let source =
        include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-module-globals.s");
    let mut config = AnalysisConfig::new((4, 1, 1));
    config.arrays = vec![
        array(
            "boundary",
            0x7000_0000_0000_0000 - 16,
            4,
            4,
            ArrayKind::Input,
        ),
        array("out", 0x20000, 4, 4, ArrayKind::Output),
    ];
    config.params = vec![ParamValue::ArrayPtr("out".into())];
    config.global_values = vec![("bound_global".into(), 17), ("global_bias".into(), 5)];
    let actual = execute(source, "module_globals", config);
    assert_eq!(actual.outputs[0].1.len(), 4);
    let mut arena = ExprArena::new();
    let values = [24, 25, 27, 29]
        .into_iter()
        .enumerate()
        .map(|(i, v)| (i as u64, arena.int(v)))
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    assert!(matches!(
        check_output_equivalence(&actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn launch_grid_and_group_dimensions_are_emitted_as_integer_outputs() {
    // Native ordinary grid/workgroup fields are the portable subset of the
    // upstream cluster fixture; NVIDIA cluster-only fields stay separately scoped.
    let source =
        include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-grid-output.s");
    let mut config = AnalysisConfig::new((4, 3, 2));
    config.grid_dim = (2, 3, 4);
    // The pinned compiler uses2/4/3-dword stores; keep each store within one
    // explicitly bounded array, then check all9 emitted values.
    config.arrays = vec![
        array("grid_xy", 0x100000, 4, 2, ArrayKind::Output),
        array("grid_z_and_group", 0x100008, 4, 4, ArrayKind::Output),
        array("block_xyz", 0x100018, 4, 3, ArrayKind::Output),
    ];
    config.params = vec![ParamValue::ArrayPtr("grid_xy".into())];
    let actual = execute(source, "grid_output", config);
    let mut arena = ExprArena::new();
    let outputs = [
        ("grid_xy", vec![2, 3]),
        ("grid_z_and_group", vec![4, 0, 0, 0]),
        ("block_xyz", vec![4, 3, 2]),
    ]
    .into_iter()
    .map(|(name, values)| {
        (
            name.into(),
            values
                .into_iter()
                .enumerate()
                .map(|(i, v)| (i as u64, arena.int(v)))
                .collect(),
        )
    })
    .collect();
    let expected = SymbolicOutputs { arena, outputs };
    assert_eq!(
        actual.outputs.iter().map(|(_, v)| v.len()).sum::<usize>(),
        9
    );
    let names = vec![
        "grid_xy".into(),
        "grid_z_and_group".into(),
        "block_xyz".into(),
    ];
    assert!(matches!(
        check_output_equivalence(&actual, &expected, &names).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn compiler_dynamic_shared_window_retains_static_alignment_padding() {
    let source =
        include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-dynamic-lds.s");
    let mut config = AnalysisConfig::new((2, 1, 1));
    config.dynamic_shared_bytes = 8;
    config.arrays = vec![
        array("x", 0x10000, 4, 4, ArrayKind::Input),
        array("out", 0x20000, 4, 2, ArrayKind::Output),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let actual = execute(source, "dynamic_lds", config);
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let values = (0..2)
        .map(|i| {
            let fixed = arena.input_element(x, i ^ 1);
            let dynamic = arena.input_element(x, (i ^ 1) + 2);
            (i, arena.add(fixed, dynamic))
        })
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    assert_eq!(actual.outputs[0].1.len(), 2);
    assert!(matches!(
        check_output_equivalence(&actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn compiler_mixed_byvalue_parameters_keep_width_sign_and_symbolic_identity() {
    let source =
        include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-mixed-byvalue.s");
    let mut config = AnalysisConfig::new((4, 1, 1));
    config.arrays = vec![array("out", 0x20000, 4, 4, ArrayKind::Output)];
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::SymFloat("alpha".into()),
        ParamValue::Float(0.5),
        ParamValue::Int(4),
        ParamValue::Int(-3),
        ParamValue::Int(250),
    ];
    let actual = execute(source, "mixed_byvalue", config);
    let mut arena = ExprArena::new();
    let alpha = arena.param_symbol("alpha");
    let coefficient = arena.float_from_f64(247.5).unwrap();
    let result = arena.add(alpha, coefficient);
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), (0..4).map(|i| (i, result)).collect())],
    };
    assert_eq!(actual.outputs[0].1.len(), 4);
    assert!(matches!(
        check_output_equivalence(&actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}
