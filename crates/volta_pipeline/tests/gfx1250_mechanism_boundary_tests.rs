//! Native static counterparts for the portable barrier operand contract.
use volta_amdgpu_analysis::frontend;

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-named-barriers.s");
const MUTATIONS: &str =
    include_str!("../../../tests/gfx1250/portable-boundaries/mechanism-syntax-mutations.tsv");

fn replace_instruction(kernel: &str, original: &str, replacement: &str) -> String {
    let start = SOURCE.find(&format!("\n{kernel}:")).unwrap();
    let end = start + SOURCE[start..].find(".Lfunc_end").unwrap();
    let body = &SOURCE[start..end];
    assert_eq!(body.matches(original).count(), 1);
    format!(
        "{}{}{}",
        &SOURCE[..start],
        body.replacen(original, replacement, 1),
        &SOURCE[end..]
    )
}

#[test]
fn actual_named_barrier_missing_and_extra_operands_reject_before_reachability() {
    frontend::parse(SOURCE).expect("unaltered genuine allocated named barriers parse");
    let mut cases = 0;
    for row in MUTATIONS.lines().skip(1) {
        let fields = row.split('\t').collect::<Vec<_>>();
        let [id, kernel, original, malformed] = fields.as_slice() else {
            panic!("unexpected mutation schema: {row}")
        };
        for instruction in [
            malformed.to_string(),
            format!("s_branch .Lmechanism_skip\n{malformed}\n.Lmechanism_skip:"),
            format!("s_mov_b32 exec_lo, 0\n{malformed}"),
        ] {
            let source = replace_instruction(kernel, original, &instruction);
            assert!(
                frontend::parse(&source).is_err(),
                "static malformed barrier accepted: {id}: {instruction}"
            );
        }
        cases += 1;
    }
    assert_eq!(cases, 9, "complete MC-checked native operand inventory");
}

#[test]
fn compiler_hardware_field_read_never_generalizes_to_unmodeled_field_bits() {
    use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};
    use volta_graph::{AbortCause, Terminal};
    use volta_graph_check::GraphConclusion;

    const SOURCE: &str = include_str!("../../../tests/gfx1250/full/fixtures/original-f16.s");
    let mut config = AnalysisConfig::new((128, 1, 1));
    config.arrays = [
        ("x", 0x10000, ArrayKind::Input),
        ("out", 0x20000, ArrayKind::Output),
    ]
    .map(|(name, base, kind)| ArrayDef {
        name: name.into(),
        base,
        elem_width: 2,
        len: 1024,
        kind,
    })
    .into();
    config.params = ["x", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    for (field, supported) in [
        ("HW_REG_IB_STS2, 6, 4", true),
        ("HW_REG_IB_STS2, 6, 5", false),
        ("HW_REG_IB_STS2, 5, 4", false),
    ] {
        let source = SOURCE.replace("HW_REG_IB_STS2, 6, 4", field);
        let module = frontend::parse(&source).expect("actual MC-valid hardware field shape");
        let analysis =
            volta_amdgpu_analysis::analyze(&module, Some("relu_f16"), config.clone()).unwrap();
        let checks = volta_graph_check::check_graph(analysis.graph());
        if supported {
            assert_eq!(checks.conclusion(), GraphConclusion::Verified);
            let outputs = analysis.symbolic_outputs().unwrap();
            assert_eq!(
                outputs.outputs[0]
                    .1
                    .iter()
                    .map(|(index, _)| *index)
                    .collect::<Vec<_>>(),
                (0..1024).collect::<Vec<_>>()
            );
        } else {
            assert!(matches!(
                analysis.graph().terminal(),
                Terminal::Aborted { cause: AbortCause::Unsupported, reason, .. }
                    if reason.contains("s_getreg_b32")
            ));
            assert!(analysis.symbolic_outputs().is_err());
            assert_ne!(checks.conclusion(), GraphConclusion::Verified);
        }
    }
}
