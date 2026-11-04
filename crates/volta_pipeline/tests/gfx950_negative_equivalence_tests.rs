//! Native counterparts of all24 pinned PTX negative-equivalence sources.
//! Every runnable side must pass AMD graph checks and produce its complete
//! output before the existing equivalence checker sees it, including .vexpr replay.
use volta_amdgpu_analysis::frontend;
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_expr::text::{read_text, to_text};
use volta_graph_check::GraphConclusion;
use volta_pipeline::{KernelModule, verify_source_kernel};
use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

macro_rules! native {
    ($name:literal) => {
        include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../../tests/gfx950/portable-negative/",
            $name,
            ".s"
        ))
    };
}

fn configuration(name: &str) -> AnalysisConfig {
    let indexed = name.starts_with("off_by_one_index");
    let mut config = AnalysisConfig::new((if indexed { 4 } else { 1 }, 1, 1));
    let width = if name.starts_with("missing_relu_clamp") {
        2
    } else {
        4
    };
    let outputs = if indexed {
        4
    } else if name.starts_with("swapped_noncommutative") {
        2
    } else {
        1
    };
    config.arrays = vec![
        ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: width,
            len: if indexed { 8 } else { 4 },
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: width,
            len: outputs,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("in".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}

fn outputs(name: &str, source: &str) -> SymbolicOutputs {
    let config = configuration(name);
    let expected = config.arrays[1].len as usize;
    let module =
        KernelModule::Amdgpu(frontend::parse(source).unwrap_or_else(|e| panic!("{name}: {e}")));
    let verified =
        verify_source_kernel(&module, Some("k"), config).unwrap_or_else(|e| panic!("{name}: {e}"));
    assert_eq!(
        verified.graph.conclusion(),
        GraphConclusion::Verified,
        "{name}: {:#?}",
        verified.graph
    );
    let output = verified
        .analysis
        .outputs
        .unwrap_or_else(|why| panic!("{name}: {why}"));
    assert_eq!(
        output.outputs[0].1.len(),
        expected,
        "{name}: incomplete output footprint"
    );
    output
}

fn compare(name: &str, reference: &str, other: &str) -> EquivOutcome {
    let a = outputs(name, reference);
    let b = outputs(name, other);
    let arrays = ["out".into()];
    let verdict =
        check_output_equivalence(&a, &b, &arrays).unwrap_or_else(|e| panic!("{name}: {e}"));
    let replay_a = read_text(&to_text(&a)).unwrap();
    let replay_b = read_text(&to_text(&b)).unwrap();
    let replay = check_output_equivalence(&replay_a, &replay_b, &arrays).unwrap();
    assert_eq!(
        format!("{verdict:?}"),
        format!("{replay:?}"),
        "{name}: text replay changed verdict"
    );
    verdict
}

#[test]
fn every_native_mutation_is_refuted_at_the_expected_elements() {
    let cases: &[(&str, &str, &str, &[u64])] = &[
        (
            "constant_perturbation",
            native!("constant_perturbation_ref"),
            native!("constant_perturbation_mut"),
            &[0],
        ),
        (
            "dropped_term",
            native!("dropped_term_ref"),
            native!("dropped_term_mut"),
            &[0],
        ),
        (
            "swapped_noncommutative",
            native!("swapped_noncommutative_ref"),
            native!("swapped_noncommutative_mut"),
            &[0, 1],
        ),
        (
            "off_by_one_index",
            native!("off_by_one_index_ref"),
            native!("off_by_one_index_mut"),
            &[0, 1, 2, 3],
        ),
        (
            "missing_relu_clamp",
            native!("missing_relu_clamp_ref"),
            native!("missing_relu_clamp_mut"),
            &[0],
        ),
        (
            "sentinel_off_by_one",
            native!("sentinel_off_by_one_ref"),
            native!("sentinel_off_by_one_mut"),
            &[0],
        ),
        (
            "fma_different_addend",
            native!("fma_different_addend_ref"),
            native!("fma_different_addend_mut"),
            &[0],
        ),
        (
            "perturbed_reduction_leaf",
            native!("linear_chain_sum"),
            native!("balanced_tree_sum_doubled_leaf"),
            &[0],
        ),
        (
            "max_vs_min",
            native!("max_vs_min_ref"),
            native!("max_vs_min_mut"),
            &[0],
        ),
        (
            "exp_of_product",
            native!("exp_product_of_exps"),
            native!("exp_of_product"),
            &[0],
        ),
        (
            "integer_sign_bit_xor",
            native!("integer_sign_bit_xor_ref"),
            native!("integer_sign_bit_xor_mut"),
            &[0],
        ),
    ];
    for &(name, reference, mutant, expected) in cases {
        let verdict = compare(name, reference, mutant);
        let EquivOutcome::NotEquivalent { mismatches } = verdict else {
            panic!("{name}: mutation was not refuted: {verdict:?}");
        };
        let actual: Vec<_> = mismatches
            .iter()
            .map(|m| {
                assert_eq!(m.array, "out");
                m.index
            })
            .collect();
        assert_eq!(actual, expected, "{name}: wrong mismatch set");
    }
}

#[test]
fn reassociation_and_exponential_fusion_controls_remain_equivalent() {
    for (name, a, b) in [
        (
            "balanced_tree_control",
            native!("linear_chain_sum"),
            native!("balanced_tree_sum"),
        ),
        (
            "exp_fusion_control",
            native!("exp_product_of_exps"),
            native!("exp_of_sum"),
        ),
    ] {
        assert!(
            matches!(compare(name, a, b), EquivOutcome::Equivalent),
            "{name}: valid identity was lost"
        );
    }
}

#[test]
fn exact_constant_fma_and_integer_sentinel_controls_remain_equivalent() {
    let coefficient = native!("constant_perturbation_ref");
    let same_bits = coefficient.replace("0.5", "0x3f000000");
    assert_ne!(same_bits, coefficient);
    assert!(matches!(
        compare("constant_control", coefficient, &same_bits),
        EquivOutcome::Equivalent
    ));
    let fma = native!("fma_different_addend_ref");
    let mul_add = native!("fma_different_addend_mut").replace("v8, v8, v7", "v8, v8, v6");
    assert_ne!(mul_add, native!("fma_different_addend_mut"));
    assert!(matches!(
        compare("fma_control", fma, &mul_add),
        EquivOutcome::Equivalent
    ));
    let sentinel = native!("sentinel_off_by_one_ref");
    let complement = sentinel.replace("v_add_u32 v8, -1, v10", "v_not_b32 v8, 0");
    assert_ne!(complement, sentinel);
    assert!(matches!(
        compare("sentinel_control", sentinel, &complement),
        EquivOutcome::Equivalent
    ));
    let out = outputs("sentinel_control", sentinel);
    assert_eq!(
        out.arena.display_expr(out.element("out", 0).unwrap()),
        "4294967295"
    );
}
