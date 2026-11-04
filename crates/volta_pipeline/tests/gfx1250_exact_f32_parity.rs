//! Preserve the exact original F32 scalar assertions through genuine gfx1250 code.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::ExprNode;
use volta_graph_check::GraphConclusion;
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-exact-f32.s");

fn config(input: bool, width: u64, length: u64, block: u32) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    if input {
        config.arrays.push(ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: 4,
            len: u64::from(block),
            kind: ArrayKind::Input,
        });
        config.params.push(ParamValue::ArrayPtr("in".into()));
    }
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: width,
        len: length,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn check(kernel: &str, baseline: &str, golden: &str, config: AnalysisConfig) {
    let module = frontend::parse(SOURCE).unwrap();
    let checked = native_common::check(SOURCE, &module, Some(kernel), config.clone()).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        checked.checks
    );
    let mut actual = checked.analysis.into_parts().outputs.unwrap();
    let module = Parser::new(baseline.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let reference = volta_ptx_analysis::analyze(&module, Some("k"), config).unwrap();
    let mut expected = reference.symbolic_outputs().unwrap().clone();
    // Preserve the original golden independently of the native implementation.
    let mut rendered = Vec::new();
    for (name, elements) in &expected.outputs {
        for (index, value) in elements {
            rendered.push(format!(
                "{name}[{index}] = {}",
                expected.arena.display_expr(*value)
            ));
        }
    }
    assert_eq!(rendered.join("\n").trim(), golden.trim());
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        expected.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        "complete original index set"
    );
    let nonfinite: Vec<_> = expected.outputs[0].1.iter().filter_map(|(index, value)| {
        if matches!(expected.arena.node(*value), ExprNode::RealConst(value) if value.is_infinite()) {
            let native = actual.element("out", *index).unwrap();
            assert_eq!(actual.arena.node(native), expected.arena.node(*value));
            Some(*index)
        } else { None }
    }).collect();
    // Non-finite constants are checked above, outside polynomial equivalence.
    actual.outputs[0].1.retain(|(i, _)| !nonfinite.contains(i));
    expected.outputs[0]
        .1
        .retain(|(i, _)| !nonfinite.contains(i));
    assert!(
        matches!(
            check_output_equivalence(&actual, &expected, &["out".into()]).unwrap(),
            EquivOutcome::Equivalent
        ),
        "{kernel}: exact original scalar computation"
    );
}

macro_rules! original {
    ($test:ident, $kernel:literal, $baseline:literal, $input:literal, $width:literal, $len:literal, $block:literal) => {
        #[test]
        fn $test() {
            check(
                $kernel,
                include_str!(concat!("ptx/success/", $baseline, ".ptx")),
                include_str!(concat!("ptx/success/", $baseline, ".out")),
                config($input, $width, $len, $block),
            );
        }
    };
}

original!(
    saturated_add,
    "exact_add_sat",
    "add_sat_f32_concrete_clamps",
    false,
    4,
    2,
    1
);
original!(
    copysign,
    "exact_copysign",
    "copysign_combines_the_sign_of_a_with_the_magnitude_of_b",
    false,
    4,
    1,
    1
);
original!(
    source_integer_format,
    "exact_source_integer_format",
    "cvt_reinterprets_at_source_format",
    false,
    8,
    2,
    1
);
original!(
    div768,
    "exact_div768",
    "div_by_n_vs_mul_by_computed_reciprocal",
    true,
    4,
    1,
    1
);
original!(
    mul_recip768,
    "exact_mul_recip768",
    "div_by_n_vs_mul_by_computed_reciprocal_2",
    true,
    4,
    1,
    1
);
original!(
    div_recip3,
    "exact_div_recip3",
    "div_by_three_vs_rcp_of_three",
    true,
    4,
    1,
    1
);
original!(
    rcp3,
    "exact_rcp3",
    "div_by_three_vs_rcp_of_three_2",
    true,
    4,
    1,
    1
);
original!(
    abs_raw_bits,
    "exact_abs_bits",
    "float_abs_decodes_raw_bits",
    true,
    4,
    3,
    1
);
original!(
    raw_math,
    "exact_raw_math",
    "float_ops_decode_raw_bit_patterns",
    true,
    4,
    6,
    1
);
original!(
    mixed_fma,
    "exact_mixed_fma",
    "mixed_precision_fma_decodes_multiplicands_at_their_own_type",
    true,
    4,
    1,
    1
);
original!(
    neg_raw_bits,
    "exact_neg_bits",
    "neg_reads_operand_as_instruction_type",
    true,
    4,
    5,
    1
);
original!(
    relu_explicit,
    "exact_relu_explicit",
    "relu_epilogue_vs_explicit_max_explicit",
    true,
    2,
    2,
    2
);
original!(
    relu_fused,
    "exact_relu_fused",
    "relu_epilogue_vs_explicit_max_fused",
    true,
    2,
    2,
    2
);
original!(exp_call, "exact_exp", "symexpf_callseq", true, 4, 1, 1);
original!(
    tanh_fragment,
    "exact_tanh",
    "tanh_approx_expands_to_exp_fragment",
    true,
    4,
    1,
    1
);
original!(
    tanh_zero,
    "exact_tanh_zero",
    "tanh_approx_zero_vs_zero",
    false,
    4,
    1,
    1
);
original!(
    zero,
    "exact_zero",
    "tanh_approx_zero_vs_zero_2",
    false,
    4,
    1,
    1
);
original!(
    fence_data_identity,
    "exact_fence_identity",
    "tcgen05_fence_is_a_no_op",
    false,
    4,
    1,
    1
);
