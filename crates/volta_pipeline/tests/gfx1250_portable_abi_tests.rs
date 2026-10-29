//! Original portable ABI and memory contracts through native gfx1250 sources.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisError, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue,
    SharedAllocation, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

const GLOBALS: &str = include_str!("../../../tests/gfx1250/portable-abi/native-module-globals.s");
const ARGUMENTS: &str = include_str!("../../../tests/gfx1250/portable-abi/native-arguments.s");
const DYNAMIC: &str = include_str!("../../../tests/gfx1250/portable-abi/native-dynamic-lds.s");
const TRANSFERS: &str = include_str!("../../../tests/gfx1250/portable-abi/native-transfers.s");

fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}

fn config(
    block: u32,
    input_width: u64,
    inputs: u64,
    output_width: u64,
    outputs: u64,
) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((block, 1, 1));
    if inputs != 0 {
        cfg.arrays
            .push(array("x", 0x10000, input_width, inputs, ArrayKind::Input));
        cfg.params.push(ParamValue::ArrayPtr("x".into()));
    }
    cfg.arrays.push(array(
        "out",
        0x20000,
        output_width,
        outputs,
        ArrayKind::Output,
    ));
    cfg.params.push(ParamValue::ArrayPtr("out".into()));
    cfg
}

fn checked(
    source: &str,
    kernel: &str,
    cfg: AnalysisConfig,
) -> Result<native_common::Checked, AnalysisError> {
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), cfg)
}

fn verified(source: &str, kernel: &str, cfg: AnalysisConfig) -> SymbolicOutputs {
    let run = checked(source, kernel, cfg).unwrap();
    assert!(
        matches!(run.checks.conclusion(), GraphConclusion::Verified),
        "{:#?}",
        run.checks
    );
    run.analysis.symbolic_outputs().unwrap().clone()
}

fn equal(actual: &SymbolicOutputs, expected: SymbolicOutputs) {
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
            .collect::<Vec<_>>()
    );
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

fn constants(values: &[i64]) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let roots = values
        .iter()
        .enumerate()
        .map(|(i, value)| (i as u64, arena.int(*value)))
        .collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), roots)],
    }
}

fn inputs(indices: &[u64]) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let roots = indices
        .iter()
        .enumerate()
        .map(|(i, index)| (i as u64, arena.input_element(x, *index)))
        .collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), roots)],
    }
}

fn invalid(source: &str, kernel: &str, cfg: AnalysisConfig, fragment: &str) {
    let run = checked(source, kernel, cfg).unwrap();
    assert!(
        matches!(run.analysis.symbolic_outputs(), Err(OutputsUnavailable::Aborted(EvalError::Invalid { what, .. })) if what.contains(fragment)),
        "expected typed invalid {fragment:?}, got {:?}",
        run.analysis.symbolic_outputs()
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

fn mutation(id: &str) -> (String, &'static str) {
    let table = include_str!("../../../tests/gfx1250/portable-abi/mutations.tsv");
    let row: Vec<_> = table
        .lines()
        .skip(1)
        .map(|line| line.split('\t').collect::<Vec<_>>())
        .find(|row| row.first() == Some(&id))
        .unwrap_or_else(|| panic!("unknown assembler-pinned mutation {id}"));
    assert_eq!(row.len(), 5);
    let source = match row[1] {
        "native-dynamic-lds.s" => DYNAMIC,
        "native-transfers.s" => TRANSFERS,
        "native-arguments.s" => ARGUMENTS,
        other => panic!("unknown native source {other}"),
    };
    let begin = source.find(&format!("{}:", row[2])).unwrap();
    let end = begin + source[begin..].find("\t.section\t.rodata").unwrap();
    let body = &source[begin..end];
    assert_eq!(body.matches(row[3]).count(), 1, "{id} old instruction");
    let mut result = source[..begin].to_owned();
    result.push_str(&body.replacen(row[3], row[4], 1));
    result.push_str(&source[end..]);
    (result, row[2])
}

#[test]
fn genuine_native_sources_keep_all_nineteen_entrypoints_and_zero_private_bytes() {
    let mut count = 0;
    for source in [GLOBALS, ARGUMENTS, DYNAMIC, TRANSFERS] {
        let module = frontend::parse(source).unwrap();
        count += module.kernels.len();
        for kernel in &module.kernels {
            assert_eq!(
                kernel.descriptor.fields.get("private_segment_fixed_size"),
                Some(&0)
            );
        }
    }
    assert_eq!(count, 19);
}

#[test]
fn module_globals_preserve_initializers_overrides_and_half_open_storage_boundary() {
    let mut cfg = config(64, 0, 0, 4, 64);
    cfg.arrays.push(array(
        "boundary",
        0x7000_0000_0000_0000 - 16,
        4,
        4,
        ArrayKind::Input,
    ));
    cfg.global_values = vec![
        ("abi_bound_global".into(), 17),
        ("abi_global_bias".into(), 5),
    ];
    let actual = verified(GLOBALS, "abi_module_globals", cfg.clone());
    let expected: Vec<_> = (0..64).map(|index| [24, 25, 27, 29][index & 3]).collect();
    equal(&actual, constants(&expected));
    cfg.arrays.last_mut().unwrap().base += 4;
    assert!(matches!(checked(GLOBALS, "abi_module_globals", cfg),
        Err(AnalysisError::Eval(EvalError::InvalidConfig(what))) if what.contains("module-global")));
}

#[test]
fn mixed_positional_arguments_preserve_symbolic_float_f64_signed16_and_unsigned8() {
    let mut cfg = config(4, 0, 0, 4, 4);
    cfg.params.extend([
        ParamValue::SymFloat("alpha".into()),
        ParamValue::Float(0.5),
        ParamValue::Int(4),
        ParamValue::Int(-3),
        ParamValue::Int(250),
    ]);
    let actual = verified(ARGUMENTS, "abi_mixed_byvalue", cfg);
    let mut arena = ExprArena::new();
    let alpha = arena.param_symbol("alpha");
    let value = arena.float_from_f64(247.5).unwrap();
    let value = arena.add(alpha, value);
    equal(
        &actual,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), (0..4).map(|i| (i, value)).collect())],
        },
    );
}

#[test]
fn ordinary_grid_group_and_block_fields_retain_all_nine_native_values() {
    let mut cfg = config(4, 0, 0, 4, 9);
    cfg.block_dim = (4, 3, 2);
    cfg.grid_dim = (2, 3, 4);
    equal(
        &verified(ARGUMENTS, "abi_grid_dimensions", cfg),
        constants(&[2, 3, 4, 0, 0, 0, 4, 3, 2]),
    );
}

#[test]
fn genuine_static_dynamic_lds_preserves_alignment_padding_and_both_symbolic_sums() {
    let mut cfg = config(2, 4, 4, 4, 2);
    cfg.dynamic_shared_bytes = 8;
    let actual = verified(DYNAMIC, "abi_dynamic_static", cfg.clone());
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let roots = (0..2)
        .map(|i| {
            let a = arena.input_element(x, i ^ 1);
            let b = arena.input_element(x, (i ^ 1) + 2);
            (i, arena.add(a, b))
        })
        .collect();
    equal(
        &actual,
        SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), roots)],
        },
    );
    for capacity in [0, 4, 7] {
        cfg.dynamic_shared_bytes = capacity;
        invalid(DYNAMIC, "abi_dynamic_static", cfg.clone(), "out-of-bounds");
    }
}

#[test]
fn extern_only_dynamic_window_has_exact_end_and_missing_capacity_controls() {
    let mut cfg = config(1, 0, 0, 4, 1);
    cfg.dynamic_shared_bytes = 16;
    equal(
        &verified(DYNAMIC, "abi_extern_only", cfg.clone()),
        constants(&[42]),
    );
    cfg.dynamic_shared_bytes = 12;
    invalid(DYNAMIC, "abi_extern_only", cfg.clone(), "out-of-bounds");
    cfg.dynamic_shared_bytes = 0;
    invalid(DYNAMIC, "abi_extern_only", cfg, "out-of-bounds");
}

#[test]
fn static_and_dynamic_stores_are_disjoint_and_retain_the_original_seven() {
    let mut cfg = config(64, 0, 0, 4, 2);
    cfg.dynamic_shared_bytes = 4;
    equal(
        &verified(DYNAMIC, "abi_static_dynamic_disjoint", cfg),
        constants(&[7, 9]),
    );
}

#[test]
fn four_stored_shared_words_survive_one_complete_native_128bit_load() {
    equal(
        &verified(TRANSFERS, "abi_shared_words", config(1, 4, 4, 4, 4)),
        inputs(&[0, 1, 2, 3]),
    );
}

#[test]
fn native_byte_and_half_pairs_keep_both_independent_inputs() {
    for (kernel, width) in [("abi_half_pair", 2), ("abi_byte_pair", 1)] {
        equal(
            &verified(TRANSFERS, kernel, config(1, width, 2, width, 2)),
            inputs(&[0, 1]),
        );
    }
}

#[test]
fn scalar_zero_granule_and_high_half_overwrite_keep_the_only_input() {
    equal(
        &verified(TRANSFERS, "abi_scalar_granule", config(1, 2, 1, 4, 1)),
        inputs(&[0]),
    );
}

#[test]
fn exact_six_byte_region_preserves_one_two_one_after_word_truncation() {
    equal(
        &verified(TRANSFERS, "abi_pair_truncation", config(1, 0, 0, 4, 3)),
        constants(&[1, 2, 1]),
    );
}

#[test]
fn two_logical_partitions_keep_every_original_zero_and_one() {
    let values: Vec<_> = (0..64).map(|i| i / 32).collect();
    equal(
        &verified(TRANSFERS, "abi_logical_partitions", config(64, 0, 0, 4, 64)),
        constants(&values),
    );
}

#[test]
fn complete_native_vector_transfer_keeps_last_input_and_whole_bounds() {
    let cfg = config(1, 4, 4, 4, 1);
    equal(
        &verified(TRANSFERS, "abi_global_vector_last", cfg.clone()),
        inputs(&[3]),
    );
    let mut short = cfg;
    short.arrays[0].len = 3;
    invalid(TRANSFERS, "abi_global_vector_last", short, "out-of-bounds");
}

#[test]
fn halfword_at_two_mod_four_keeps_only_the_original_sparse_output() {
    let actual = verified(TRANSFERS, "abi_half_at_two_mod_four", config(1, 2, 2, 2, 2));
    let mut expected = inputs(&[1]);
    expected.outputs[0].1[0].0 = 1;
    equal(&actual, expected);
}

#[test]
fn global_identity_crosses_i64_sign_boundary_and_still_checks_the_end() {
    let mut cfg = config(1, 4, 5, 4, 1);
    cfg.arrays[0].base = 0x7fff_ffff_ffff_fff0;
    equal(
        &verified(TRANSFERS, "abi_upper_address", cfg.clone()),
        inputs(&[4]),
    );
    cfg.arrays[0].len = 4;
    invalid(TRANSFERS, "abi_upper_address", cfg, "out-of-bounds");
}

#[test]
fn negative_index_wrap_never_escapes_the_configured_array() {
    let mut cfg = config(1, 4, 4, 4, 1);
    cfg.params[0] = ParamValue::Int(0x10004);
    equal(
        &verified(TRANSFERS, "abi_negative_index", cfg.clone()),
        inputs(&[0]),
    );
    cfg.arrays[0].base = 0;
    cfg.params[0] = ParamValue::ArrayPtr("x".into());
    invalid(TRANSFERS, "abi_negative_index", cfg, "out-of-bounds");
}

#[test]
fn rank_zero_offset_math_retains_all_four_original_coordinates() {
    equal(
        &verified(TRANSFERS, "abi_rank_zero_offsets", config(4, 0, 0, 4, 4)),
        constants(&[0, 4, 8, 12]),
    );
}

#[test]
fn native_shared_tail_checks_lane_48_at_the_real_192byte_boundary() {
    let expected: Vec<_> = (0..48).collect();
    equal(
        &verified(TRANSFERS, "abi_shared_array_tail", config(48, 0, 0, 4, 48)),
        constants(&expected),
    );
    invalid(
        TRANSFERS,
        "abi_shared_array_tail",
        config(64, 0, 0, 4, 64),
        "out-of-bounds",
    );
}

#[test]
fn scalar_and_vector_endpoints_fit_the_same_48byte_region() {
    equal(
        &verified(TRANSFERS, "abi_region_edge", config(1, 0, 0, 4, 2)),
        constants(&[7, 1]),
    );
}

#[test]
fn external_store_cannot_initialize_a_disjoint_static_object() {
    let (source, kernel) = mutation("extern_does_not_initialize_static");
    let mut cfg = config(64, 0, 0, 4, 2);
    cfg.dynamic_shared_bytes = 4;
    invalid(&source, kernel, cfg, "uninitialized");
}

#[test]
fn undefined_shared_values_abort_before_nested_output_arithmetic() {
    let (source, kernel) = mutation("undefined_nested_output");
    let mut cfg = config(2, 4, 4, 4, 2);
    cfg.dynamic_shared_bytes = 8;
    invalid(&source, kernel, cfg, "uninitialized");
    let (source, kernel) = mutation("undefined_low_half");
    invalid(&source, kernel, config(1, 2, 1, 4, 1), "uninitialized");
}

#[test]
fn wide_shared_reads_require_all_four_initialized_words() {
    let (source, kernel) = mutation("missing_fourth_word");
    invalid(&source, kernel, config(1, 4, 4, 4, 4), "uninitialized");
}

#[test]
fn truncated_word_store_cannot_cross_the_exact_six_byte_end() {
    let (source, kernel) = mutation("subword_past_six_byte_end");
    invalid(&source, kernel, config(1, 0, 0, 4, 3), "out-of-bounds");
}

#[test]
fn undefined_mixed_argument_padding_cannot_become_an_unsigned_byte() {
    let (source, kernel) = mutation("padding_is_not_zero");
    let mut cfg = config(4, 0, 0, 4, 4);
    cfg.params.extend([
        ParamValue::SymFloat("alpha".into()),
        ParamValue::Float(0.5),
        ParamValue::Int(4),
        ParamValue::Int(-3),
        ParamValue::Int(250),
    ]);
    invalid(&source, kernel, cfg, "undefined");
}

#[test]
fn whole_vector_transfer_cannot_straddle_adjacent_configured_lds_objects() {
    let mut cfg = config(1, 0, 0, 4, 2);
    cfg.dynamic_shared_bytes = 56;
    cfg.shared_allocations = vec![
        SharedAllocation {
            name: "A".into(),
            offset: 0,
            size: 48,
        },
        SharedAllocation {
            name: "B".into(),
            offset: 48,
            size: 56,
        },
    ];
    equal(
        &verified(TRANSFERS, "abi_region_edge", cfg.clone()),
        constants(&[7, 1]),
    );
    cfg.shared_allocations[0].size = 40;
    cfg.shared_allocations[1].offset = 40;
    cfg.shared_allocations[1].size = 64;
    invalid(TRANSFERS, "abi_region_edge", cfg, "allocation");
}

#[test]
fn native_word_alignment_is_checked_without_importing_ptx_vector_alignment() {
    let mut cfg = config(1, 4, 5, 4, 1);
    cfg.params[0] = ParamValue::Int(0x10004);
    equal(
        &verified(TRANSFERS, "abi_global_vector_last", cfg.clone()),
        inputs(&[4]),
    );
    cfg.params[0] = ParamValue::Int(0x10002);
    invalid(TRANSFERS, "abi_global_vector_last", cfg.clone(), "align");
    cfg.arrays[0].base += 2;
    assert!(matches!(checked(TRANSFERS, "abi_global_vector_last", cfg),
        Err(AnalysisError::Eval(EvalError::InvalidConfig(what))) if what.contains("align")));
    let mut cfg = config(1, 4, 6, 4, 1);
    cfg.params[0] = ParamValue::Int(0x10002);
    invalid(TRANSFERS, "abi_upper_address", cfg, "align");
    let mut cfg = config(4, 0, 0, 4, 4);
    cfg.params[0] = ParamValue::Int(0x20002);
    invalid(TRANSFERS, "abi_rank_zero_offsets", cfg, "align");
}

#[test]
fn impossible_dynamic_lds_sizes_and_readonly_global_overrides_fail_configuration() {
    for size in [327_681, u64::MAX] {
        let mut cfg = config(2, 4, 4, 4, 2);
        cfg.dynamic_shared_bytes = size;
        assert!(matches!(
            checked(DYNAMIC, "abi_dynamic_static", cfg),
            Err(AnalysisError::Eval(EvalError::InvalidConfig(_)))
        ));
    }
    let mut cfg = config(64, 0, 0, 4, 64);
    cfg.global_values = vec![("abi_readonly_scalar".into(), 13)];
    assert!(matches!(checked(GLOBALS, "abi_module_globals", cfg),
        Err(AnalysisError::Eval(EvalError::InvalidConfig(what))) if what.contains("read-only")));
}
