//! Exact remaining positive payload assertions from the original PTX suite.
//! Native source mappings and pinned baseline hashes are in payload-cases.json.
mod gfx950_common;

use std::path::Path;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

fn source(name: &str) -> String {
    std::fs::read_to_string(
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../../tests/gfx950/portable-data")
            .join(format!("payload_{name}.s")),
    )
    .unwrap()
}
fn config(input_name: &str, iw: u64, il: u64, ow: u64, ol: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: input_name.into(),
            base: 0x10000,
            elem_width: iw,
            len: il,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: ow,
            len: ol,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr(input_name.into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}
fn complete_text(text: &str, config: AnalysisConfig) -> SymbolicOutputs {
    let module = frontend::parse(text).unwrap();
    let checked = gfx950_common::check(text, &module, Some("k"), config).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn complete(name: &str, config: AnalysisConfig) -> SymbolicOutputs {
    complete_text(&source(name), config)
}
fn reference(mut entries: impl FnMut(&mut ExprArena) -> Vec<(u64, ExprId)>) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let elements = entries(&mut arena).into_iter().collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    }
}
fn constants(values: &[(u64, i64)]) -> SymbolicOutputs {
    reference(|arena| {
        values
            .iter()
            .map(|&(index, value)| (index, arena.int(value)))
            .collect()
    })
}
fn inputs(name: &str, indices: &[(u64, u64)]) -> SymbolicOutputs {
    reference(|arena| {
        let name = arena.intern_string(name);
        indices
            .iter()
            .map(|&(out, input)| (out, arena.input_element(name, input)))
            .collect()
    })
}
fn equivalent(actual: SymbolicOutputs, expected: SymbolicOutputs) {
    // Exact sparse footprint is part of every baseline assertion.
    assert_eq!(
        actual
            .outputs
            .iter()
            .map(|(name, elements)| (
                name,
                elements.iter().map(|(index, _)| *index).collect::<Vec<_>>()
            ))
            .collect::<Vec<_>>(),
        expected
            .outputs
            .iter()
            .map(|(name, elements)| (
                name,
                elements.iter().map(|(index, _)| *index).collect::<Vec<_>>()
            ))
            .collect::<Vec<_>>()
    );
    let result = check_output_equivalence(&actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}

#[test]
fn f32_saturation_matches_both_concrete_endpoint_assertions() {
    equivalent(
        complete("add_sat_f32_concrete_clamps", config("in", 4, 1, 4, 2)),
        constants(&[(0, 1), (1, 0)]),
    );
}

#[test]
fn native_halfword_at_two_mod_four_preserves_the_only_written_index() {
    equivalent(
        complete("aligned_u16_access_at_2_mod_4", config("in", 2, 4, 2, 4)),
        inputs("in", &[(1, 1)]),
    );
}

#[test]
fn four_component_load_retains_the_fourth_independent_input() {
    equivalent(
        complete("aligned_vector_load", config("in", 4, 8, 4, 8)),
        inputs("in", &[(0, 3)]),
    );
}

#[test]
fn source_signedness_selects_minus_eight_or_unsigned_4294967288_at_64_bits() {
    equivalent(
        complete(
            "cvt_reinterprets_at_source_format",
            config("in", 4, 1, 8, 2),
        ),
        constants(&[(0, -8), (1, 4_294_967_288)]),
    );
    // CDNA4 V_ASHRREV_I64 uses an arithmetic shift and the low six count bits.
    for (count, expected) in [(1, -4), (63, -1), (64, -8)] {
        let text = source("cvt_reinterprets_at_source_format").replace(
            "v_ashrrev_i64 v[8:9],0,",
            &format!("v_ashrrev_i64 v[8:9],{count},"),
        );
        equivalent(
            complete_text(&text, config("in", 4, 1, 8, 2)),
            constants(&[(0, expected), (1, 4_294_967_288)]),
        );
    }
}

#[test]
fn signed_byte_and_minus_one_complement_rows_canonicalize_the_u32_output() {
    for name in [
        "load_s8_sign_extends",
        "load_s8_sign_extends_2",
        "mov_neg1_vs_not_zero",
        "mov_neg1_vs_not_zero_2",
    ] {
        equivalent(
            complete(name, config("in", 1, 1, 4, 1)),
            constants(&[(0, 4_294_967_295)]),
        );
    }
}

#[test]
fn direct_and_assembled_integer_pointers_write_only_output_index_two() {
    for name in [
        "mov_b64_integer_pack_recombines_as_scalar_direct",
        "mov_b64_integer_pack_recombines_as_scalar_packed",
    ] {
        equivalent(
            complete(name, config("in", 4, 4, 4, 4)),
            inputs("in", &[(2, 0)]),
        );
    }
}

#[test]
fn native_half_pair_pack_and_unpack_retain_both_symbolic_elements() {
    for name in [
        "mov_pack_b32_always_builds_pair",
        "mov_unpack_native_pair_source",
    ] {
        equivalent(
            complete(name, config("in", 2, 2, 2, 2)),
            inputs("in", &[(0, 0), (1, 1)]),
        );
    }
}

#[test]
fn integer_pair_packing_and_raw_halfword_unpacking_preserve_exact_bits() {
    equivalent(
        complete(
            "mov_pack_b64_integer_halves_recombine",
            config("in", 4, 1, 8, 1),
        ),
        constants(&[(0, 12_884_901_893)]),
    );
    equivalent(
        complete(
            "mov_vector_destination_unpack_values",
            config("in", 4, 1, 2, 2),
        ),
        constants(&[(0, 43_981), (1, 4_660)]),
    );
}

#[test]
fn both_native_relu_half_epilogues_match_two_independent_maxima() {
    for name in [
        "relu_epilogue_vs_explicit_max_explicit",
        "relu_epilogue_vs_explicit_max_fused",
    ] {
        let mut cfg = config("in", 4, 2, 2, 2);
        cfg.block_dim = (2, 1, 1);
        let expected = reference(|arena| {
            let name = arena.intern_string("in");
            (0..2)
                .map(|index| {
                    let input = arena.input_element(name, index);
                    let zero = arena.int(0);
                    (index, arena.max(zero, input))
                })
                .collect()
        });
        equivalent(complete(name, cfg), expected);
    }
}

#[test]
fn byte_store_truncates_300_and_unsigned_byte_load_remains_its_numeric_input() {
    equivalent(
        complete("store_u8_truncates_to_low_bits", config("in", 1, 1, 4, 1)),
        constants(&[(0, 44)]),
    );
    equivalent(
        complete(
            "unsigned_sub_register_load_passes_through",
            config("scratch", 1, 1, 4, 1),
        ),
        inputs("scratch", &[(0, 0)]),
    );
}

#[test]
fn native_vector_store_preserves_both_input_and_immediate_lanes() {
    let expected = reference(|arena| {
        let name = arena.intern_string("in");
        vec![
            (0, arena.input_element(name, 0)),
            (1, arena.int(0)),
            (2, arena.input_element(name, 1)),
            (3, arena.int(1)),
        ]
    });
    equivalent(
        complete(
            "vector_store_with_immediate_source",
            config("in", 4, 2, 4, 4),
        ),
        expected,
    );
}

#[test]
fn unsigned_byte_numeric_consumption_cannot_alias_fp8_decoding() {
    let text = source("unsigned_sub_register_load_passes_through").replace(
        "v_add_u32 v8,0,v4",
        "v_add_u32 v8,0,v4\nv_cvt_f32_fp8 v9,v4",
    );
    let module = frontend::parse(&text).unwrap();
    let checked =
        gfx950_common::check(&text, &module, Some("k"), config("scratch", 1, 1, 4, 1)).unwrap();
    let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(
        error.contains("conflicting byte interpretations"),
        "{error}"
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}
