use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend};
use volta_expr::ExprNode;

const COPY: &str = include_str!("../../../tests/gfx1250/fixtures/native-copy-add.s");

fn config(block: u32, n: u64, add: bool) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    for (name, base, kind) in [
        ("x", 0x10000, ArrayKind::Input),
        ("y", 0x20000, ArrayKind::Input),
        ("out", 0x30000, ArrayKind::Output),
    ] {
        if name == "y" && !add {
            continue;
        }
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: 4,
            len: n,
            kind,
        });
        config.params.push(ParamValue::ArrayPtr(name.into()));
    }
    config.params.push(ParamValue::Int(n as i64));
    config
}

#[test]
fn genuine_wave32_compiler_source_parses_with_original_instructions() {
    for source in [
        COPY,
        include_str!("../../../tests/gfx1250/fixtures/native-lds-ids.s"),
        include_str!("../../../tests/gfx1250/fixtures/native-wmma.s"),
    ] {
        let module = frontend::parse(source).unwrap();
        assert_eq!(module.target.as_deref(), Some("gfx1250"));
        for kernel in module.kernels {
            assert!(kernel.descriptor.flag("wavefront_size32"));
        }
    }
}

#[test]
fn native_copy_has_complete_output_at_each_wave32_boundary() {
    let module = frontend::parse(COPY).unwrap();
    for block in [1, 31, 32, 33, 63, 64, 65, 96, 128] {
        for n in [1, block] {
            let result = analyze(&module, Some("copy"), config(block, n as u64, false)).unwrap();
            let outputs = result.symbolic_outputs().unwrap();
            assert_eq!(outputs.outputs[0].1.len(), n as usize);
            for i in 0..n as u64 {
                match outputs.arena.node(outputs.element("out", i).unwrap()) {
                    ExprNode::InputElement { array, index } => {
                        assert_eq!(outputs.arena.string(*array), "x");
                        assert_eq!(*index, i);
                    }
                    other => panic!("{other:?}"),
                }
            }
            assert!(
                result.graph().validate().is_ok(),
                "{:#?}",
                result.graph().validate()
            );
            assert!(
                !result
                    .graph()
                    .provenance()
                    .assumptions
                    .iter()
                    .any(|a| format!("{a:?}") == "XnackReplayDisabled")
            );
        }
    }
}
