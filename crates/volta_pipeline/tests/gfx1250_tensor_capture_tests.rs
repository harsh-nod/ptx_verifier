//! TDM captures descriptor SGPRs at issue, independently of Tensor completion.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph_check::GraphConclusion;
const SOURCE: &str = include_str!("../../../tests/gfx1250/fixtures/native-tensor-roundtrip.s");
#[test]
fn tensor_descriptor_reuse_before_completion_preserves_every_original_output() {
    let needle = "tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]";
    assert!(SOURCE.contains(needle));
    let source = SOURCE.replacen(needle, &format!("{needle}\n\ts_mov_b32 s4,0"), 1);
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 128,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 128,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let run = native_common::check(&source, &module, Some("tensor_roundtrip"), config).unwrap();
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        run.checks
    );
    let out = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(out.outputs.len(), 1);
    assert_eq!(out.outputs[0].1.len(), 128);
    for (index, (written, value)) in out.outputs[0].1.iter().enumerate() {
        assert_eq!(*written, index as u64);
        assert_eq!(out.arena.display_expr(*value), format!("(1 + x[{index}])"));
    }
}
