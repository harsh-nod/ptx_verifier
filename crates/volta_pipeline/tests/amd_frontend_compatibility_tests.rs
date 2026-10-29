//! Shared compiler input for the upstream syntax parser and the native AMD verifier.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amd_analysis::frontend::{ast as upstream, parse::parse_kernel};
use volta_amdgpu_analysis::frontend::{self, Operand, RegisterClass};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::{GraphConclusion, PropertyResult};
use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

const COPY: &str = include_str!("../../volta_amd_analysis/tests/fixtures/copy.s");

#[test]
fn frontends_agree_on_the_upstream_compiler_kernel() {
    let upstream = parse_kernel(COPY, "copy").unwrap();
    let module = frontend::parse(COPY).unwrap();
    assert_eq!(module.kernels.len(), 1);
    let native = &module.kernels[0];
    assert_eq!(native.name, upstream.name);
    assert_eq!(
        module.target.as_deref(),
        upstream.target.strip_prefix("amdgcn-amd-amdhsa--")
    );
    for (name, value) in &upstream.descriptor {
        assert_eq!(native.descriptor.get(name), Some(*value), "{name}");
    }
    assert_eq!(native.instructions.len(), upstream.instructions.len());
    for (native, upstream) in native.instructions.iter().zip(&upstream.instructions) {
        assert_eq!(native.mnemonic, upstream.opcode);
        assert!(native.modifiers.is_empty());
        let expected: Vec<_> = upstream.operands.iter().map(native_operand).collect();
        assert_eq!(native.operands, expected);
        assert!(
            COPY[native.span.start..native.span.end]
                .trim_start()
                .starts_with(&native.mnemonic)
        );
    }
}

fn native_operand(operand: &upstream::Operand) -> Operand {
    match operand {
        upstream::Operand::Reg { file, first, last } => Operand::Register(frontend::Register {
            class: match file {
                upstream::RegFile::Scalar => RegisterClass::Scalar,
                upstream::RegFile::Vector => RegisterClass::Vector,
            },
            index: (*first).try_into().unwrap(),
            count: (last - first + 1).try_into().unwrap(),
            special: None,
        }),
        upstream::Operand::Imm(value) => Operand::Integer((*value).try_into().unwrap()),
        upstream::Operand::Wait { counter, value } => Operand::WaitCounter {
            name: match counter {
                upstream::Counter::Vm => "vmcnt",
                upstream::Counter::Lgkm => "lgkmcnt",
            }
            .into(),
            value: (*value).try_into().unwrap(),
        },
    }
}

fn config(block: u32) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: block.into(),
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: block.into(),
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}

#[test]
fn unchanged_upstream_copy_verifies_all_outputs_across_wave64_boundaries() {
    let module = frontend::parse(COPY).unwrap();
    for block in [1, 63, 64, 65, 128, 256] {
        let checked = native_common::check(COPY, &module, Some("copy"), config(block)).unwrap();
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
        let actual = checked.analysis.symbolic_outputs().unwrap();
        let mut arena = ExprArena::new();
        let input = arena.intern_string("x");
        let elements = (0..u64::from(block))
            .map(|i| (i, arena.input_element(input, i)))
            .collect();
        let expected = SymbolicOutputs {
            arena,
            outputs: vec![("out".into(), elements)],
        };
        assert_eq!(actual.outputs.len(), 1);
        assert_eq!(actual.outputs[0].1.len(), block as usize);
        assert!(matches!(
            check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
            EquivOutcome::Equivalent
        ));
    }
}

#[test]
fn parsing_the_kernel_does_not_certify_its_memory_readiness() {
    for wait in ["\ts_waitcnt lgkmcnt(0)\n", "\ts_waitcnt vmcnt(0)\n"] {
        let source = COPY.replacen(wait, "", 1);
        assert_ne!(source, COPY);
        parse_kernel(&source, "copy").unwrap();
        let module = frontend::parse(&source).unwrap();
        let checked = native_common::check(&source, &module, Some("copy"), config(65)).unwrap();
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ));
        assert!(matches!(
            checked.checks.amd.unwrap().wait_readiness,
            PropertyResult::Fail(_)
        ));
    }
}

#[test]
fn both_frontends_reject_unknown_operands_in_the_selected_kernel() {
    let load = "global_load_dword v1, v0, s[0:1]";
    let source = COPY.replacen(load, &format!("{load} unknown_modifier"), 1);
    assert_ne!(source, COPY);
    assert!(parse_kernel(&source, "copy").is_err());
    assert!(frontend::parse(&source).is_err());
}
