//! Unchanged full original F16 source on CDNA3, with independent full equations.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

const SOURCE: &str = include_str!(
    "../../../tests/amdgpu/original-kernel-qualification/fixtures/gfx942-original-f16.s"
);

fn config(kernel: &str) -> (AnalysisConfig, u64) {
    let mut config = AnalysisConfig::new((128, 1, 1));
    let (names, len) = match kernel {
        "relu_f16" => (vec!["x", "output"], 1024),
        "silu_f16" => (vec!["x", "output"], 512),
        "rope_f16" => (vec!["input", "cos", "sin", "output"], 128),
        _ => unreachable!(),
    };
    for (i, name) in names.into_iter().enumerate() {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base: 0x10000 * (i as u64 + 1),
            elem_width: 2,
            len,
            kind: if name == "output" {
                ArrayKind::Output
            } else {
                ArrayKind::Input
            },
        });
        config.params.push(ParamValue::ArrayPtr(name.into()));
    }
    (config, len)
}

fn input(arena: &mut ExprArena, name: &str, index: u64) -> ExprId {
    let name = arena.intern_string(name);
    arena.input_element(name, index)
}

fn expected(kernel: &str, len: u64) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let mut elements = Vec::new();
    for index in 0..len {
        let name = if kernel == "rope_f16" { "input" } else { "x" };
        let x = input(&mut arena, name, index);
        let value = match kernel {
            "relu_f16" => {
                let zero = arena.int(0);
                arena.max(x, zero)
            }
            "silu_f16" => {
                let negative = arena.neg(x);
                let exponential = arena.exp(negative);
                let one = arena.int(1);
                let denominator = arena.add(one, exponential);
                arena.div(x, denominator)
            }
            "rope_f16" => {
                let cosine = input(&mut arena, "cos", index);
                let sine = input(&mut arena, "sin", index);
                let partner = input(&mut arena, "input", index ^ 64);
                let partner = if index < 64 {
                    arena.neg(partner)
                } else {
                    partner
                };
                let left = arena.mul(x, cosine);
                let right = arena.mul(partner, sine);
                arena.add(left, right)
            }
            _ => unreachable!(),
        };
        elements.push((index, value));
    }
    SymbolicOutputs {
        arena,
        outputs: vec![("output".into(), elements)],
    }
}

#[test]
fn full_original_relu_silu_and_rope_keep_every_output_identity_and_equation() {
    let module = frontend::parse(SOURCE).unwrap();
    assert_eq!(module.kernels.len(), 9, "the compiler module remains whole");
    for kernel in ["relu_f16", "silu_f16", "rope_f16"] {
        let (config, len) = config(kernel);
        let checked = gfx950_common::check(SOURCE, &module, Some(kernel), config).unwrap();
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{kernel}"
        );
        let actual = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(actual.outputs.len(), 1);
        assert_eq!(
            actual.outputs[0]
                .1
                .iter()
                .map(|(index, _)| *index)
                .collect::<Vec<_>>(),
            (0..len).collect::<Vec<_>>()
        );
        let reference = expected(kernel, len);
        let result = check_output_equivalence(actual, &reference, &["output".into()]).unwrap();
        assert!(
            matches!(result, EquivOutcome::Equivalent),
            "{kernel}: {result:?}"
        );
    }
}

#[test]
fn missing_actual_relu_load_completion_keeps_a_typed_readiness_failure() {
    let mutant = SOURCE.replacen("s_waitcnt vmcnt(0)", "s_nop 0", 1);
    assert_ne!(mutant, SOURCE);
    let module = frontend::parse(&mutant).unwrap();
    let checked =
        gfx950_common::check(&mutant, &module, Some("relu_f16"), config("relu_f16").0).unwrap();
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    assert!(
        !checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .wait_readiness
            .violations()
            .is_empty()
    );
}
