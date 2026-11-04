//! Exact original packed payloads through genuinely compiled gfx1250 kernels.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, OutputsUnavailable, ParamValue, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_graph_check::{GraphConclusion, Property, Verdict, amdgpu::AmdRegisterHazardKind};
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const PACKED: &str = include_str!("../../../tests/gfx1250/fixtures/native-packed-data.s");
const FP8: &str = include_str!("../../../tests/gfx1250/fixtures/native-fp8-packing.s");

fn config(
    block: u32,
    input_name: &str,
    input_width: u64,
    inputs: u64,
    width: u64,
    outputs: u64,
) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    if inputs != 0 {
        config.arrays.push(ArrayDef {
            name: input_name.into(),
            base: 0x10000,
            elem_width: input_width,
            len: inputs,
            kind: ArrayKind::Input,
        });
        config.params.push(ParamValue::ArrayPtr(input_name.into()));
    }
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: width,
        len: outputs,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}
fn run(source: &str, kernel: &str, config: AnalysisConfig) -> native_common::Checked {
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), config).unwrap()
}
fn check(source: &str, kernel: &str, baseline: &str, golden: &str, config: AnalysisConfig) {
    let actual = run(source, kernel, config.clone());
    assert_eq!(
        actual.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:?}\n{:?}",
        actual.analysis.graph.terminal(),
        actual.checks
    );
    let actual = actual.analysis.symbolic_outputs().unwrap();
    let original = Parser::new(baseline.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let original = volta_ptx_analysis::analyze(&original, Some("k"), config).unwrap();
    let expected = original.symbolic_outputs().unwrap();
    let text = expected
        .outputs
        .iter()
        .flat_map(|(name, elements)| {
            elements.iter().map(move |(index, value)| {
                format!("{name}[{index}] = {}", expected.arena.display_expr(*value))
            })
        })
        .collect::<Vec<_>>()
        .join("\n");
    assert_eq!(text.trim(), golden.trim(), "independent original golden");
    assert_eq!(
        actual
            .outputs
            .iter()
            .map(|(name, xs)| (name, xs.iter().map(|x| x.0).collect::<Vec<_>>()))
            .collect::<Vec<_>>(),
        expected
            .outputs
            .iter()
            .map(|(name, xs)| (name, xs.iter().map(|x| x.0).collect::<Vec<_>>()))
            .collect::<Vec<_>>(),
        "every original written coordinate, including sparse holes"
    );
    assert!(
        matches!(
            check_output_equivalence(actual, expected, &["out".into()]).unwrap(),
            EquivOutcome::Equivalent
        ),
        "{kernel}: original full payload"
    );
}
macro_rules! original {
    ($test:ident, $source:ident, $kernel:literal, $baseline:literal, $block:literal, $name:literal, $input_width:literal, $inputs:literal, $width:literal, $outputs:literal) => {
        #[test]
        fn $test() {
            check(
                $source,
                $kernel,
                include_str!(concat!("ptx/success/", $baseline, ".ptx")),
                include_str!(concat!("ptx/success/", $baseline, ".out")),
                config($block, $name, $input_width, $inputs, $width, $outputs),
            );
        }
    };
}

original!(
    packed_scalar_reference,
    PACKED,
    "packed_scalar_reference",
    "f32x2_scalar_reference",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_register_fma,
    PACKED,
    "packed_register_fma",
    "f32x2_fma_via_register_pack",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_memory_fma,
    PACKED,
    "packed_memory_fma",
    "f32x2_fma_via_64bit_memory_access",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_unfused,
    PACKED,
    "packed_unfused",
    "f32x2_mul_add_via_register_pack",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_constant_operand,
    PACKED,
    "packed_constant_operand",
    "f32x2_constant_bit_pattern_operand",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_wrong_math,
    PACKED,
    "packed_wrong_math",
    "f32x2_wrong_lane_math",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_shift_or,
    PACKED,
    "packed_shift_or",
    "f32x2_operand_assembled_with_shift_and_or",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_zero_extend,
    PACKED,
    "packed_zero_extend",
    "f32x2_operand_assembled_with_cvt_zero_extension",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_high_shift,
    PACKED,
    "packed_high_shift",
    "f32x2_lane_extracted_with_shift",
    2,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_pointer_direct,
    PACKED,
    "packed_pointer_direct",
    "mov_b64_integer_pack_recombines_as_scalar_direct",
    1,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_pointer_reassembled,
    PACKED,
    "packed_pointer_reassembled",
    "mov_b64_integer_pack_recombines_as_scalar_packed",
    1,
    "in",
    4,
    4,
    4,
    4
);
original!(
    packed_half_pack,
    PACKED,
    "packed_half_pack",
    "mov_pack_b32_always_builds_pair",
    1,
    "in",
    2,
    2,
    2,
    2
);
original!(
    packed_half_unpack,
    PACKED,
    "packed_half_unpack",
    "mov_unpack_native_pair_source",
    1,
    "in",
    2,
    2,
    2,
    2
);
original!(
    packed_integer_halves,
    PACKED,
    "packed_integer_halves",
    "mov_pack_b64_integer_halves_recombine",
    1,
    "",
    1,
    0,
    8,
    1
);
original!(
    packed_raw_halfwords,
    PACKED,
    "packed_raw_halfwords",
    "mov_vector_destination_unpack_values",
    1,
    "",
    1,
    0,
    2,
    2
);
original!(
    half_pack_values,
    FP8,
    "fp8_pack_half_values",
    "cvt_pack_halves_values",
    1,
    "",
    1,
    0,
    2,
    2
);
original!(
    half_relu,
    FP8,
    "fp8_relu_to_half",
    "cvt_relu_symbolic_is_max",
    1,
    "in",
    4,
    1,
    2,
    1
);
original!(
    fp8_concrete_pair,
    FP8,
    "fp8_concrete_pair",
    "e4m3x2_decodes_a_concrete_scalar_bit_pattern",
    1,
    "",
    1,
    0,
    4,
    2
);
original!(
    fp8_concrete_relu,
    FP8,
    "fp8_concrete_relu",
    "e4m3x2_relu_clamps_a_negative_decoded_lane_to_zero",
    1,
    "",
    1,
    0,
    4,
    2
);
original!(
    fp8_vector_bytes,
    FP8,
    "fp8_vector_bytes",
    "e4m3x2_vector_load_keeps_four_symbolic_bytes_independent",
    1,
    "x",
    1,
    8,
    4,
    4
);
original!(
    fp8_selected_halves,
    FP8,
    "fp8_selected_halves",
    "e4m3x2_low_half_extracted_via_cvt_u16_u32_truncation_of_a_quad",
    1,
    "x",
    1,
    4,
    4,
    2
);
original!(
    fp8_zero_extended_byte,
    FP8,
    "fp8_zero_extended_byte",
    "e4m3x2_scalar_source_from_a_zero_extended_byte_load",
    1,
    "x",
    1,
    1,
    4,
    1
);

#[test]
fn concrete_ocp_nan_is_rejected_by_the_actual_native_decoder() {
    let actual = run(FP8, "fp8_nan_decode", config(1, "", 1, 0, 4, 1));
    let error = actual.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(matches!(
        actual.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(_))
    ));
    assert!(error.to_lowercase().contains("nan"), "{error}");
    assert_ne!(actual.checks.conclusion(), GraphConclusion::Verified);
}

#[test]
fn native_ubyte_zero_extension_defines_high_byte_without_fabricating_ptx_storage() {
    let actual = run(FP8, "fp8_byte_low_and_high", config(1, "x", 1, 1, 4, 2));
    assert_eq!(actual.checks.conclusion(), GraphConclusion::Verified);
    let outputs = actual.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 2);
    assert_eq!(
        outputs.arena.display_expr(outputs.outputs[0].1[0].1),
        "x[0]"
    );
    assert_eq!(
        outputs.arena.as_int_const(outputs.outputs[0].1[1].1),
        Some(0)
    );
    let source =
        include_str!("ptx/failing/e4m3x2_scalar_source_high_lane_is_undefined_not_fabricated.ptx");
    let module = Parser::new(source.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let original = volta_ptx_analysis::analyze(&module, Some("k"), config(1, "x", 1, 1, 4, 1));
    let error = match original {
        Err(error) => error.to_string(),
        Ok(result) => result.symbolic_outputs().unwrap_err().to_string(),
    };
    assert!(error.to_lowercase().contains("undefined"), "{error}");
}

#[test]
fn full_packed_wrong_math_is_not_equivalent_and_load_readiness_is_not_optional() {
    let cfg = config(2, "in", 4, 4, 4, 4);
    let reference = run(PACKED, "packed_memory_fma", cfg.clone());
    let mutant = run(PACKED, "packed_wrong_math", cfg.clone());
    for result in [&reference, &mutant] {
        assert_eq!(result.checks.conclusion(), GraphConclusion::Verified);
        assert_eq!(
            result.analysis.symbolic_outputs().unwrap().outputs[0]
                .1
                .len(),
            4
        );
    }
    let verdict = check_output_equivalence(
        reference.analysis.symbolic_outputs().unwrap(),
        mutant.analysis.symbolic_outputs().unwrap(),
        &["out".into()],
    )
    .unwrap();
    let EquivOutcome::NotEquivalent { mismatches } = verdict else {
        panic!("the square-only mutant must have concrete mismatch coordinates: {verdict:?}");
    };
    assert_eq!(
        mismatches
            .iter()
            .map(|mismatch| (mismatch.array.as_str(), mismatch.index))
            .collect::<Vec<_>>(),
        [("out", 0), ("out", 1), ("out", 2), ("out", 3)]
    );
    let source = PACKED.replace("s_wait_loadcnt 0x0", "s_nop 0");
    let missing = run(&source, "packed_memory_fma", cfg);
    assert_eq!(
        missing.analysis.symbolic_outputs().unwrap().outputs[0]
            .1
            .len(),
        4
    );
    assert!(matches!(
        missing.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    assert_eq!(missing.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        missing.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Fail
    );
    assert!(
        missing
            .checks
            .amd
            .as_ref()
            .unwrap()
            .wait_readiness
            .violations()
            .iter()
            .any(|hazard| hazard.kind == AmdRegisterHazardKind::ReadBeforeReady)
    );
}
