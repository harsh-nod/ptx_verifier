//! Exact native counterparts for portable model, syntax and mutation contracts.
#![allow(unused_macros)]
#[macro_use]
mod common;
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_expr::text::{read_text, to_text};
use volta_graph_check::GraphConclusion;

const EQUIVALENCE: &str =
    include_str!("../../../tests/gfx1250/portable-boundaries/native-equivalence.s");

fn config(threads: u32, input_width: u64, input_len: u64, output_len: u64) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((threads, 1, 1));
    if input_len != 0 {
        cfg.arrays.push(ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: input_width,
            len: input_len,
            kind: ArrayKind::Input,
        });
        cfg.params.push(ParamValue::ArrayPtr("in".into()));
    }
    cfg.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: input_width,
        len: output_len,
        kind: ArrayKind::Output,
    });
    cfg.params.push(ParamValue::ArrayPtr("out".into()));
    cfg
}

fn native(kernel: &str, cfg: AnalysisConfig) -> SymbolicOutputs {
    let module = frontend::parse(EQUIVALENCE).expect("genuine compiler module parses");
    let run = gfx950_common::check(EQUIVALENCE, &module, Some(kernel), cfg).unwrap();
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        run.checks
    );
    run.analysis
        .into_parts()
        .outputs
        .expect("complete native outputs")
}

fn original(name: &'static str, cfg: AnalysisConfig) -> SymbolicOutputs {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/ptx/negative_equivalence")
        .join(format!("{name}.ptx"));
    let source = std::fs::read_to_string(path).unwrap();
    let parsed = common::parse_named(name, &source);
    let run = common::verify(&parsed, None, cfg).unwrap();
    assert_eq!(run.graph.conclusion(), GraphConclusion::Verified);
    run.analysis
        .into_parts()
        .outputs
        .expect("complete original outputs")
}

fn outcome(a: &SymbolicOutputs, b: &SymbolicOutputs) -> EquivOutcome {
    let arrays = ["out".into()];
    let direct = check_output_equivalence(a, b, &arrays).expect("decision procedure succeeds");
    let replayed = check_output_equivalence(
        &read_text(&to_text(a)).expect("exported reference replays"),
        &read_text(&to_text(b)).expect("exported candidate replays"),
        &arrays,
    )
    .expect("replayed decision procedure succeeds");
    assert_eq!(format!("{direct:?}"), format!("{replayed:?}"));
    direct
}

struct Pair {
    native_ref: &'static str,
    native_mut: &'static str,
    original_ref: &'static str,
    original_mut: &'static str,
    threads: u32,
    width: u64,
    input_len: u64,
    output_len: u64,
}

const PAIRS: [Pair; 11] = [
    Pair {
        native_ref: "constant_ref",
        native_mut: "constant_mut",
        original_ref: "constant_perturbation_ref",
        original_mut: "constant_perturbation_mut",
        threads: 1,
        width: 4,
        input_len: 1,
        output_len: 1,
    },
    Pair {
        native_ref: "sum_ref",
        native_mut: "sum_dropped",
        original_ref: "dropped_term_ref",
        original_mut: "dropped_term_mut",
        threads: 1,
        width: 4,
        input_len: 4,
        output_len: 1,
    },
    Pair {
        native_ref: "noncommutative_ref",
        native_mut: "noncommutative_mut",
        original_ref: "swapped_noncommutative_ref",
        original_mut: "swapped_noncommutative_mut",
        threads: 1,
        width: 4,
        input_len: 2,
        output_len: 2,
    },
    Pair {
        native_ref: "index_ref",
        native_mut: "index_mut",
        original_ref: "off_by_one_index_ref",
        original_mut: "off_by_one_index_mut",
        threads: 4,
        width: 4,
        input_len: 8,
        output_len: 4,
    },
    Pair {
        native_ref: "relu_ref",
        native_mut: "relu_mut",
        original_ref: "missing_relu_clamp_ref",
        original_mut: "missing_relu_clamp_mut",
        threads: 1,
        width: 2,
        input_len: 3,
        output_len: 1,
    },
    Pair {
        native_ref: "sentinel_ref",
        native_mut: "sentinel_mut",
        original_ref: "sentinel_off_by_one_ref",
        original_mut: "sentinel_off_by_one_mut",
        threads: 1,
        width: 4,
        input_len: 0,
        output_len: 1,
    },
    Pair {
        native_ref: "fma_ref",
        native_mut: "fma_mut",
        original_ref: "fma_different_addend_ref",
        original_mut: "fma_different_addend_mut",
        threads: 1,
        width: 4,
        input_len: 4,
        output_len: 1,
    },
    Pair {
        native_ref: "sum_ref",
        native_mut: "sum_doubled_leaf",
        original_ref: "linear_chain_sum",
        original_mut: "balanced_tree_sum_doubled_leaf",
        threads: 1,
        width: 4,
        input_len: 4,
        output_len: 1,
    },
    Pair {
        native_ref: "maximum_ref",
        native_mut: "minimum_mut",
        original_ref: "max_vs_min_ref",
        original_mut: "max_vs_min_mut",
        threads: 1,
        width: 4,
        input_len: 2,
        output_len: 1,
    },
    Pair {
        native_ref: "exp_product_ref",
        native_mut: "exp_product_mut",
        original_ref: "exp_product_of_exps",
        original_mut: "exp_of_product",
        threads: 1,
        width: 4,
        input_len: 2,
        output_len: 1,
    },
    Pair {
        native_ref: "sign_xor_ref",
        native_mut: "sign_negate_mut",
        original_ref: "integer_sign_bit_xor_ref",
        original_mut: "integer_sign_bit_xor_mut",
        threads: 1,
        width: 4,
        input_len: 1,
        output_len: 1,
    },
];

fn check_original_pair(index: usize) {
    let pair = &PAIRS[index];
    let cfg = config(pair.threads, pair.width, pair.input_len, pair.output_len);
    let a = native(pair.native_ref, cfg.clone());
    let b = native(pair.native_mut, cfg.clone());
    for outputs in [&a, &b] {
        assert_eq!(outputs.outputs.len(), 1);
        assert_eq!(
            outputs.outputs[0]
                .1
                .iter()
                .map(|(i, _)| *i)
                .collect::<Vec<_>>(),
            (0..pair.output_len).collect::<Vec<_>>()
        );
    }
    for (actual, name) in [(&a, pair.original_ref), (&b, pair.original_mut)] {
        let mut baseline = original(name, cfg.clone());
        let mut native_view = read_text(&to_text(actual)).unwrap();
        if pair.native_ref == "sign_xor_ref" {
            // Compare BOTH declared U32 store views. The shared legacy
            // arithmetic model retains mathematical ring subtraction, while
            // bitwise native XOR records its finite word. Applying the same
            // explicit storage projection does not constrain any input and
            // leaves the raw native mutation check below unchanged.
            for outputs in [&mut baseline, &mut native_view] {
                let mask = outputs.arena.int(u32::MAX.into());
                for (_, roots) in &mut outputs.outputs {
                    for (_, root) in roots {
                        // Idempotence is exact: (x & M) & M == x & M.
                        // Keep one explicit view mask because the decision
                        // procedure intentionally treats bitwise operators as
                        // uninterpreted and does not simplify nested ANDs.
                        let already_masked = matches!(outputs.arena.node(*root),
                            volta_expr::ExprNode::BitAnd(_, right)
                                if outputs.arena.as_i64(*right) == Some(u32::MAX.into()));
                        if !already_masked {
                            *root = outputs.arena.bit_and(*root, mask);
                        }
                    }
                }
            }
        }
        assert!(
            matches!(outcome(&baseline, &native_view), EquivOutcome::Equivalent),
            "{name}: native mathematical computation differs: baseline={} native={}",
            baseline
                .arena
                .display_expr(baseline.element("out", 0).unwrap()),
            native_view
                .arena
                .display_expr(native_view.element("out", 0).unwrap())
        );
    }
    let EquivOutcome::NotEquivalent { mismatches } = outcome(&a, &b) else {
        panic!("{}: changed computation accepted", pair.native_mut);
    };
    assert_eq!(
        mismatches
            .iter()
            .map(|m| (m.array.as_str(), m.index))
            .collect::<Vec<_>>(),
        (0..pair.output_len).map(|i| ("out", i)).collect::<Vec<_>>(),
        "{}",
        pair.native_mut
    );
}

#[test]
fn native_constant_perturbation_retains_exact_original_pair_and_coordinates() {
    check_original_pair(0);
}

#[test]
fn native_dropped_term_retains_exact_original_pair_and_coordinates() {
    check_original_pair(1);
}

#[test]
fn native_swapped_noncommutative_retains_exact_original_pair_and_coordinates() {
    check_original_pair(2);
}

#[test]
fn native_off_by_one_index_retains_exact_original_pair_and_coordinates() {
    check_original_pair(3);
}

#[test]
fn native_missing_f16_relu_clamp_retains_exact_original_pair_and_coordinates() {
    check_original_pair(4);
}

#[test]
fn native_u32_sentinel_retains_exact_original_pair_and_coordinates() {
    check_original_pair(5);
}

#[test]
fn native_different_fma_addend_retains_exact_original_pair_and_coordinates() {
    check_original_pair(6);
}

#[test]
fn native_reassociated_doubled_leaf_retains_exact_original_pair_and_coordinates() {
    check_original_pair(7);
}

#[test]
fn native_max_vs_min_retains_exact_original_pair_and_coordinates() {
    check_original_pair(8);
}

#[test]
fn native_exp_of_product_retains_exact_original_pair_and_coordinates() {
    check_original_pair(9);
}

#[test]
fn native_integer_sign_xor_retains_exact_original_pair_and_coordinates() {
    check_original_pair(10);
}

#[test]
fn genuine_native_algebra_controls_preserve_reassociation_fma_exp_and_u32_sentinel() {
    for (a, b, width, input_len) in [
        ("sum_ref", "sum_balanced", 4, 4),
        ("fma_ref", "fma_control", 4, 4),
        ("exp_product_ref", "exp_sum_control", 4, 2),
        ("sentinel_ref", "sentinel_not_control", 4, 0),
    ] {
        let cfg = config(1, width, input_len, 1);
        assert!(matches!(
            outcome(&native(a, cfg.clone()), &native(b, cfg.clone())),
            EquivOutcome::Equivalent
        ));
        let original_control = match b {
            "sum_balanced" => Some("balanced_tree_sum"),
            "exp_sum_control" => Some("exp_of_sum"),
            _ => None,
        };
        if let Some(name) = original_control {
            assert!(matches!(
                outcome(&original(name, cfg.clone()), &native(b, cfg)),
                EquivOutcome::Equivalent
            ));
        }
    }
}

const CONTROLS: &str = include_str!("../../../tests/gfx1250/portable-boundaries/native-controls.s");

fn checked_source(source: &str, kernel: &str, cfg: AnalysisConfig) -> gfx950_common::Checked {
    let module = frontend::parse(source).expect("known legal native control");
    gfx950_common::check(source, &module, Some(kernel), cfg).unwrap()
}

#[test]
fn canonical_native_termination_wait_and_complete_vector_load_controls_are_legal() {
    for kernel in ["control_end", "control_wait"] {
        let run = checked_source(CONTROLS, kernel, AnalysisConfig::new((1, 1, 1)));
        assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
        assert!(run.analysis.symbolic_outputs().unwrap().outputs.is_empty());
    }
    let run = checked_source(CONTROLS, "control_vector", config(1, 4, 4, 4));
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let outputs = run.analysis.into_parts().outputs.unwrap();
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        vec![0, 1, 2, 3]
    );
    assert!(matches!(
        outcome(
            &original("off_by_one_index_ref", config(4, 4, 4, 4)),
            &outputs
        ),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn recognized_native_trap_is_parsed_but_never_silently_executed_or_certified() {
    use volta_amdgpu_analysis::{EvalError, OutputsUnavailable};
    let run = checked_source(CONTROLS, "control_trap", AnalysisConfig::new((1, 1, 1)));
    assert!(matches!(run.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::Unsupported { what, .. }))
            if what.contains("s_trap")));
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

fn replace_entry(source: &str, kernel: &str, old: &str, replacement: &str) -> String {
    let start = source.find(&format!("\n{kernel}:")).unwrap();
    let end = start + source[start..].find(".Lfunc_end").unwrap();
    let body = &source[start..end];
    assert_eq!(
        body.matches(old).count(),
        1,
        "one precise original instruction"
    );
    format!(
        "{}{}{}",
        &source[..start],
        body.replacen(old, replacement, 1),
        &source[end..]
    )
}

#[test]
fn malformed_known_native_instructions_reject_in_live_unreachable_and_zero_exec_paths() {
    let table = include_str!("../../../tests/gfx1250/portable-boundaries/syntax-mutations.tsv");
    let cases = table
        .lines()
        .skip(1)
        .map(|line| {
            let fields: Vec<_> = line.split('\t').collect();
            assert_eq!(fields.len(), 4);
            (fields[1], fields[2], fields[3])
        })
        .collect::<Vec<_>>();
    assert_eq!(cases.len(), 10, "complete shared syntax inventory");
    // Known opcode controls parse before any malformed mutation is attempted.
    frontend::parse(CONTROLS).unwrap();
    for (kernel, old, bad) in cases {
        for wrapped in [
            bad.to_string(),
            format!("s_branch .Lboundary_skip\n{bad}\n.Lboundary_skip:"),
            format!("s_mov_b32 exec_lo, 0\n{bad}"),
        ] {
            let source = replace_entry(CONTROLS, kernel, old, &wrapped);
            assert!(
                frontend::parse(&source).is_err(),
                "malformed source accepted: {kernel}: {wrapped}"
            );
        }
    }
}

#[test]
fn native_trap_identifier_profile_is_explicitly_bounded() {
    // LLVM's SOPP encoder accepts wider immediates, while this verifier's
    // deliberately supported trap-ID profile is 0..255. A trap handler is
    // never assumed, even for an encodable instruction.
    for id in [0, 255] {
        let source = replace_entry(
            CONTROLS,
            "control_trap",
            "s_trap 7",
            &format!("s_trap {id}"),
        );
        frontend::parse(&source).unwrap();
    }
    let source = replace_entry(CONTROLS, "control_trap", "s_trap 7", "s_trap 256");
    assert!(frontend::parse(&source).is_err());
}

#[test]
fn unknown_directive_and_unresolved_branch_are_statically_rejected() {
    assert!(frontend::parse(&format!(".text\n{CONTROLS}")).is_ok());
    assert!(frontend::parse(&format!(".not_a_real_native_directive\n{CONTROLS}")).is_err());
    for replacement in [
        "s_branch .Lnot_defined".to_string(),
        "s_branch .Lboundary_after\ns_branch .Lnot_defined\n.Lboundary_after:\ns_endpgm"
            .to_string(),
    ] {
        let source = replace_entry(CONTROLS, "control_end", "s_endpgm", &replacement);
        let module = frontend::parse(&source).expect("branch grammar is legal");
        let kernel = module
            .kernels
            .iter()
            .find(|kernel| kernel.name == "control_end")
            .unwrap();
        let error =
            volta_amdgpu_analysis::lower::lower_kernel_in_module(&module, kernel).unwrap_err();
        assert!(
            error.to_string().contains("undefined") || error.to_string().contains("unknown"),
            "{error}"
        );
    }
}

const MODEL: &str = include_str!("../../../tests/gfx1250/portable-boundaries/native-model.s");

fn output_only(width: u64) -> AnalysisConfig {
    config(1, width, 0, 1)
}

#[test]
fn real_model_rejects_actual_nan_bits_and_nan_byvalue_parameters() {
    use volta_amdgpu_analysis::{AnalysisError, EvalError, OutputsUnavailable};
    let run = checked_source(MODEL, "model_nan_bits", output_only(4));
    assert!(matches!(run.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::Unsupported { what, .. } | EvalError::Invalid { what, .. }))
            if what.contains("NaN")));
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    let module = frontend::parse(MODEL).unwrap();
    let mut cfg = output_only(4);
    cfg.params.push(ParamValue::Float(f64::NAN));
    assert!(
        matches!(gfx950_common::check(MODEL, &module, Some("model_branch_parameter"), cfg),
        Err(AnalysisError::Eval(EvalError::InvalidConfig(what)))
            if what.contains("NaN") || what.contains("finite"))
    );
}

#[test]
fn zero_over_zero_native_control_cannot_become_a_successful_equivalence() {
    use volta_amdgpu_analysis::{EvalError, OutputsUnavailable};
    let run = checked_source(MODEL, "model_zero_over_zero", output_only(4));
    match run.analysis.symbolic_outputs() {
        Err(OutputsUnavailable::Aborted(
            EvalError::Unsupported { what, .. } | EvalError::Invalid { what, .. },
        )) => {
            assert!(
                what.contains("NaN")
                    || what.contains("division")
                    || what.contains("non-real")
                    || what.contains("zero reciprocal"),
                "{what}"
            );
            assert!(matches!(
                run.checks.conclusion(),
                GraphConclusion::Unknown { .. }
            ));
        }
        Ok(outputs) => {
            assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
            let error = check_output_equivalence(outputs, outputs, &["out".into()])
                .expect_err("undefined division must not be an equivalent real constant");
            assert!(
                error.to_string().contains("division") || error.to_string().contains("infinite"),
                "{error}"
            );
        }
        other => panic!("wrong model boundary: {other:?}"),
    }
}

#[test]
fn symbolic_native_branch_is_explicit_while_concrete_branch_retains_its_value() {
    use volta_amdgpu_analysis::{EvalError, OutputsUnavailable};
    let run = checked_source(MODEL, "model_branch", config(1, 4, 1, 1));
    assert!(
        matches!(run.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::Invalid { wave: 0, lane: None, pc: 7, what }))
            if what == "symbolic predicate mask used as concrete VCC/control bits"),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    let mut cfg = output_only(4);
    cfg.params.push(ParamValue::Float(2.0));
    let run = checked_source(MODEL, "model_branch_parameter", cfg);
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let outputs = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(
        outputs
            .arena
            .display_expr(outputs.element("out", 0).unwrap()),
        "2"
    );
}

#[test]
fn native_integer_division_by_two_is_flooring_not_rational_cancellation() {
    let cfg = config(1, 4, 1, 1);
    let run = checked_source(MODEL, "model_divide_two", cfg.clone());
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let quotient = run.analysis.into_parts().outputs.unwrap();
    let expected_quotient = expected_scalar(|arena| {
        let index = arena.int(0);
        let input = arena.symbolic_read("in", index);
        let mask = arena.int(u32::MAX.into());
        let input_word = arena.bit_and(input, mask);
        let one = arena.int(1);
        let shifted = arena.lshr(input_word, one);
        arena.bit_and(shifted, mask)
    });
    assert!(matches!(
        outcome(&expected_quotient, &quotient),
        EquivOutcome::Equivalent
    ));
    let run = checked_source(MODEL, "model_divide_then_double", cfg);
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let doubled = run.analysis.into_parts().outputs.unwrap();
    let input = native("index_ref", config(1, 4, 1, 1));
    assert!(
        matches!(outcome(&doubled, &input), EquivOutcome::NotEquivalent { mismatches } if mismatches.len()==1 && mismatches[0].index==0)
    );
    assert_eq!(
        quotient.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        vec![0]
    );
    let run = checked_source(MODEL, "model_divide_concrete", output_only(4));
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let outputs = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(
        outputs
            .arena
            .display_expr(outputs.element("out", 0).unwrap()),
        "3"
    );
}

#[test]
fn original_predicate_side_effect_is_not_erased_when_both_lanes_write() {
    let run = checked_source(MODEL, "model_predicate_side_effect", config(2, 4, 0, 4));
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "race candidate must finish"
    );
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses.iter().any(|witness| {
            witness.kind == volta_graph_check::domain::ConflictKind::WriteWrite
                && witness.location.space == volta_graph::Space::Global
                && witness.location.addr == 0x20000
        }),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let run = checked_source(MODEL, "model_predicate_single_writer", config(2, 4, 0, 4));
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let outputs = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(outputs.outputs[0].1[0].0, 0);
    assert_eq!(
        outputs
            .arena
            .display_expr(outputs.element("out", 0).unwrap()),
        "1"
    );
}

fn expected_scalar(
    build: impl FnOnce(&mut volta_expr::ExprArena) -> volta_expr::ExprId,
) -> SymbolicOutputs {
    let mut outputs = SymbolicOutputs::default();
    let value = build(&mut outputs.arena);
    outputs.outputs.push(("out".into(), vec![(0, value)]));
    outputs
}

#[test]
fn native_subword_store_refuses_ambiguous_symbolic_truncation_but_keeps_concrete_low_byte() {
    use volta_amdgpu_analysis::{EvalError, OutputsUnavailable};
    let mut cfg = config(1, 4, 1, 1);
    cfg.arrays[1].elem_width = 1;
    let run = checked_source(MODEL, "model_truncated_store", cfg);
    assert!(
        matches!(run.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::Invalid { what, .. } | EvalError::Unsupported { what, .. }))
            if what == "symbolic byte truncation is unsupported"),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    for value in [0u32, 255, 256, 0x12345678, u32::MAX] {
        let mut cfg = output_only(1);
        cfg.params.push(ParamValue::Int(value.into()));
        let run = checked_source(MODEL, "model_truncated_concrete", cfg);
        assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
        let actual = run.analysis.into_parts().outputs.unwrap();
        let expected = expected_scalar(|arena| arena.int((value & 255).into()));
        assert!(matches!(
            outcome(&expected, &actual),
            EquivOutcome::Equivalent
        ));
    }
}

#[test]
fn native_signed_global_byte_widening_has_an_explicit_signed_input_and_u32_store_view() {
    const SIGNED: &str =
        include_str!("../../../tests/gfx1250/portable-boundaries/native-signed-byte.s");
    let mut cfg = config(1, 1, 1, 1);
    cfg.arrays[1].elem_width = 4;
    let run = checked_source(SIGNED, "model_signed_byte", cfg);
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let actual = run.analysis.into_parts().outputs.unwrap();
    let expected = expected_scalar(|arena| {
        let index = arena.int(0);
        arena.symbolic_read("in", index)
    });
    // SignedI8 input atoms denote values in [-128,127]. Hardware sign-extension
    // into a 32-bit store preserves that mathematical signed value. The same
    // explicit U32 storage view is applied to both sides, without guessing that
    // a byte is FP8 or constraining an arbitrary input to one concrete pattern.
    let stored = |mut outputs: SymbolicOutputs| {
        let mask = outputs.arena.int(u32::MAX.into());
        let root = outputs.element("out", 0).unwrap();
        outputs.outputs[0].1[0].1 = outputs.arena.bit_and(root, mask);
        outputs
    };
    assert!(matches!(
        outcome(&stored(expected), &stored(actual)),
        EquivOutcome::Equivalent
    ));
}
