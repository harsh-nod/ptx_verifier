//! Unambiguous output identities, representable shapes and complete footprints.
use std::collections::HashMap;
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_spec::{
    InstantiateErrorKind, OutputSpec, Shape, SpecEnv, SpecError, SpecExpr, instantiate,
    output_index_mismatch, parse_spec, unfold,
};

fn zero_output(shape: Vec<u64>) -> OutputSpec {
    OutputSpec {
        array: "out".into(),
        vars: (0..shape.len()).map(|i| format!("i{i}")).collect(),
        shape: Shape::new(shape),
        body: SpecExpr::int(0),
    }
}

#[test]
fn contradictory_output_equations_reject_in_either_order() {
    for bodies in ["out[i]=0;out[i]=1;", "out[i]=1;out[i]=0;"] {
        let parsed = parse_spec(&format!("dim N;array out[N];{bodies}")).unwrap();
        assert!(
            matches!(instantiate(&parsed, &HashMap::from([("N".into(), 4)])),
                         Err(InstantiateErrorKind::DuplicateOutput(name)) if name == "out")
        );
    }
}

#[test]
fn direct_unfold_also_rejects_duplicate_output_equations() {
    let spec = zero_output(vec![2]);
    for sample in [0, 1] {
        assert!(
            matches!(unfold(&[spec.clone(), spec.clone()], &SpecEnv::default(), sample),
                         Err(SpecError::DuplicateOutput(name)) if name == "out")
        );
    }
}

#[test]
fn parsed_input_and_output_shape_overflow_is_an_error() {
    for source in [
        "dim N;dim M;array out[N,M];out[i,j]=0;",
        "dim N;dim M;array input[N,M];array out[N];out[i]=0;",
    ] {
        let parsed = parse_spec(source).unwrap();
        assert!(matches!(
            instantiate(
                &parsed,
                &HashMap::from([("N".into(), 1u64 << 32), ("M".into(), 1u64 << 32)])
            ),
            Err(InstantiateErrorKind::ShapeOverflow(_))
        ));
    }
}

#[test]
fn direct_unfold_rejects_overflow_before_empty_or_sampled_unrolling() {
    let oversized = zero_output(vec![1u64 << 32, 1u64 << 32]);
    let env = SpecEnv {
        arrays: HashMap::from([("input".into(), Shape::new(vec![u64::MAX, 2]))]),
        ..SpecEnv::default()
    };
    for sample in [0, 1] {
        assert!(matches!(
            unfold(
                std::slice::from_ref(&oversized),
                &SpecEnv::default(),
                sample
            ),
            Err(SpecError::ShapeOverflow { .. })
        ));
        assert!(matches!(
            unfold(&[zero_output(vec![1])], &env, sample),
            Err(SpecError::ShapeOverflow { .. })
        ));
    }
}

#[test]
fn scalar_empty_and_maximum_representable_shape_sizes_remain_defined() {
    assert_eq!(Shape::new(vec![]).checked_size(), Some(1));
    assert_eq!(Shape::new(vec![u64::MAX]).checked_size(), Some(u64::MAX));
    assert_eq!(Shape::new(vec![u64::MAX, 2, 0]).checked_size(), Some(0));
    assert_eq!(Shape::new(vec![u64::MAX, 2]).checked_size(), None);
    assert!(
        unfold(&[zero_output(vec![0])], &SpecEnv::default(), 0)
            .unwrap()
            .outputs[0]
            .1
            .is_empty()
    );
}

#[test]
fn full_output_footprints_identify_missing_extra_and_shifted_indices() {
    let spec = zero_output(vec![2]);
    for (indices, missing, extra) in [
        (vec![0], vec![1], vec![]),
        (vec![0, 1, 2], vec![], vec![2]),
        (vec![0, 2], vec![1], vec![2]),
        (vec![], vec![0, 1], vec![]),
    ] {
        let mut arena = ExprArena::new();
        let zero = arena.int(0);
        let outputs = SymbolicOutputs {
            arena,
            outputs: vec![(
                "out".into(),
                indices.into_iter().map(|i| (i, zero)).collect(),
            )],
        };
        let mismatch = output_index_mismatch(&outputs, std::slice::from_ref(&spec))
            .unwrap()
            .unwrap();
        assert_eq!(mismatch.unwritten, missing);
        assert_eq!(mismatch.unexpected, extra);
    }
    let full = unfold(std::slice::from_ref(&spec), &SpecEnv::default(), 0).unwrap();
    assert_eq!(output_index_mismatch(&full, &[spec]).unwrap(), None);
}
