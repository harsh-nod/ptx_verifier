//! A real native convolution cell that exposed cancellation in the numeric oracle.
use volta_amdgpu_analysis::frontend;
use volta_equivalence::numeric::{agree_at, eval_f64, verify_verdict};
use volta_ptx_analysis::LaunchFile;

#[test]
fn original_convolution_cancellation_is_checked_against_an_independent_exact_assignment() {
    let source = include_str!("../../../tests/gfx1250/full/fixtures/original-convolution.s");
    let launch = LaunchFile::from_json(include_str!(
        "../../../tests/gfx1250/full/launch/convolution_f16_original.json"
    ))
    .unwrap();
    assert_eq!(launch.kernel.as_deref(), Some("convolution_f16_original"));
    let module = frontend::parse(source).unwrap();
    let analysis =
        volta_amdgpu_analysis::analyze(&module, launch.kernel.as_deref(), launch.config).unwrap();
    let actual = analysis.symbolic_outputs().unwrap();
    assert_eq!(
        actual
            .outputs
            .iter()
            .map(|(_, values)| values.len())
            .sum::<usize>(),
        16_384
    );

    // This regression checks the known cancellation cell, not a sampled claim
    // of complete workload equivalence. The native candidate still executes
    // its unchanged original full configuration. The full32 gate is separate.
    let parsed = volta_spec::parse_spec(include_str!(
        "../../../tests/gfx1250/full/specs/convolution_f16_original.spec"
    ))
    .unwrap();
    let dimensions = [
        ("C", 64),
        ("H", 56),
        ("W", 56),
        ("O", 128),
        ("R", 3),
        ("S", 3),
        ("SPATIAL", 128),
    ]
    .into_iter()
    .map(|(name, value)| (name.into(), value))
    .collect();
    let (environment, mut specifications) = volta_spec::instantiate(&parsed, &dimensions).unwrap();
    specifications.retain(|specification| specification.array == "out071");
    let expected = volta_spec::unfold(&specifications, &environment, 0).unwrap();
    assert_eq!(expected.outputs[0].1.len(), 128);
    let a = actual.element("out071", 77).unwrap();
    let b = expected.element("out071", 77).unwrap();
    let seed = 0xdeadbeef;
    let va = eval_f64(&actual.arena, a, seed).unwrap();
    let vb = eval_f64(&expected.arena, b, seed).unwrap();
    assert!(
        ((va - vb) / va.abs().max(vb.abs())).abs() > 1e-9,
        "this real fixture must still exercise the binary64 disagreement"
    );
    // A zero tolerance forces the independent exact-arithmetic fallback at
    // this assignment. No canonical equality result is supplied to the oracle.
    assert!(agree_at(&actual.arena, a, &expected.arena, b, seed, 0.0).unwrap());
    verify_verdict(&actual.arena, a, &expected.arena, b, true).unwrap();
}
