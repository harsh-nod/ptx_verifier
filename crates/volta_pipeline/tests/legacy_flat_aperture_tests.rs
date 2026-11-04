//! Full-output equivalence never replaces legacy FLAT completion checking.
#[path = "../../volta_amdgpu_analysis/tests/support/legacy_flat.rs"]
mod fixture;
mod gfx950_common;

use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::{GraphConclusion, Property, Verdict};

fn reference(block: u32, wrong: bool) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let one = arena.int(1);
    let elements = (0..u64::from(block))
        .map(|index| {
            let value = arena.input_element(x, index);
            (index, if wrong { arena.add(value, one) } else { value })
        })
        .collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    }
}

fn run(target: &str, body: &str, block: u32) -> gfx950_common::Checked {
    let source = fixture::source(target, body);
    let module = volta_amdgpu_analysis::frontend::parse(&source).unwrap();
    gfx950_common::check(&source, &module, Some("k"), fixture::config(block)).unwrap()
}

#[test]
fn full_identity_and_wrong_equation_cover_every_written_output() {
    for target in ["gfx942", "gfx950"] {
        for block in [1, 64] {
            for alias in [false, true] {
                let checked = run(target, &fixture::copy(alias), block);
                assert_eq!(
                    checked.checks.conclusion(),
                    GraphConclusion::Verified,
                    "{:?}",
                    checked.checks
                );
                let outputs = checked.analysis.symbolic_outputs().unwrap();
                assert_eq!(outputs.outputs.len(), 1);
                assert_eq!(outputs.outputs[0].1.len(), block as usize);
                assert_eq!(
                    outputs.outputs[0]
                        .1
                        .iter()
                        .map(|(i, _)| *i)
                        .collect::<Vec<_>>(),
                    (0..u64::from(block)).collect::<Vec<_>>()
                );
                for wrong in [false, true] {
                    let outcome = check_output_equivalence(
                        outputs,
                        &reference(block, wrong),
                        &["out".into()],
                    )
                    .unwrap();
                    if wrong {
                        assert!(
                            matches!(outcome, EquivOutcome::NotEquivalent { mismatches } if !mismatches.is_empty())
                        );
                    } else {
                        assert!(matches!(outcome, EquivOutcome::Equivalent));
                    }
                }
            }
        }
    }
}

#[test]
fn correct_values_do_not_waive_either_flat_counter() {
    for target in ["gfx942", "gfx950"] {
        for wait in ["s_waitcnt vmcnt(0)", "s_waitcnt lgkmcnt(0)"] {
            let body = fixture::copy(false).replace("s_waitcnt vmcnt(0) lgkmcnt(0)", wait);
            let checked = run(target, &body, 1);
            assert!(matches!(
                check_output_equivalence(
                    checked.analysis.symbolic_outputs().unwrap(),
                    &reference(1, false),
                    &["out".into()]
                )
                .unwrap(),
                EquivOutcome::Equivalent
            ));
            assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
            assert_eq!(
                checked.checks.verdict(Property::AmdWaitReadiness),
                Verdict::Fail
            );
            assert!(matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
        }
    }
}
