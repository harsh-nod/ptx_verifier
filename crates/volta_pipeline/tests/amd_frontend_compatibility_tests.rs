//! Shared compiler input for the upstream syntax parser and the native AMD verifier.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amd_analysis::frontend::{ast as upstream, parse::parse_kernel};
use volta_amd_analysis::{InstrId, LoweredInstr, lower_kernel};
use volta_amdgpu_analysis::frontend::{self, Operand, RegisterClass};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::{GraphConclusion, PropertyResult};
use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

const COPY: &str = include_str!("../../volta_amd_analysis/tests/fixtures/copy.s");

#[test]
fn frontends_agree_on_the_upstream_compiler_kernel() {
    assert_eq!(
        COPY,
        include_str!("../../volta_amdgpu_analysis/tests/fixtures/upstream-copy.s")
    );
    let upstream = parse_kernel(COPY, "copy").unwrap();
    let module = frontend::parse(COPY).unwrap();
    assert_eq!(module.kernels.len(), 1);
    let native = &module.kernels[0];
    assert_eq!(native.name, upstream.name);
    assert_eq!(
        module.target.as_deref(),
        upstream.target.strip_prefix("amdgcn-amd-amdhsa--")
    );
    // The native metadata reader adds these three settings to the inline descriptor.
    let native_inline_descriptor = native
        .descriptor
        .fields
        .iter()
        .filter(|(name, _)| {
            !matches!(
                name.as_str(),
                "kernarg_segment_align" | "max_flat_workgroup_size" | "uniform_work_group_size"
            )
        })
        .map(|(name, value)| (name.clone(), *value))
        .collect::<std::collections::BTreeMap<_, _>>();
    assert_eq!(native_inline_descriptor, upstream.descriptor);
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
    verify_copy(COPY, &[1, 63, 64, 65, 128, 256]);
}

#[test]
fn experimental_copy_outputs_and_empty_amd_graph_do_not_supply_a_safety_proof() {
    use volta_amd_analysis::{ArrayDef as UpstreamArray, ArrayKind as UpstreamKind};

    let kernel = parse_kernel(COPY, "copy").unwrap();
    let arrays = [
        UpstreamArray {
            name: "x".into(),
            base: 0x10000,
            len: 64,
            kind: UpstreamKind::Input,
        },
        UpstreamArray {
            name: "out".into(),
            base: 0x20000,
            len: 64,
            kind: UpstreamKind::Output,
        },
    ];
    let kernarg: Vec<_> = arrays
        .iter()
        .flat_map(|array| array.base.to_le_bytes())
        .collect();
    let launch = volta_amd_analysis::WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
    };
    let result = volta_amd_analysis::analyze(&kernel, &launch, &kernarg, &arrays).unwrap();
    assert_eq!(result.terminal, volta_amd_analysis::Terminal::Completed);
    assert_eq!(
        result.symbolic_outputs.as_ref().unwrap().outputs[0].1.len(),
        64
    );
    assert!(result.graph.events().is_empty());
    assert_eq!(result.graph.provenance().workgroup_id, (0, 0, 0));
    assert_eq!(result.graph.provenance().targets, ["gfx950:xnack-"]);
    let report = volta_graph_check::check_graph(&result.graph);
    assert!(report.amd.is_some());
    assert!(matches!(
        report.conclusion(),
        GraphConclusion::Unknown { .. }
    ));

    for target in [
        "amdgcn-amd-amdhsa--gfx950:xnack-",
        "amdgcn-amd-amdhsa--gfx1250",
    ] {
        let mut provenance = result.graph.provenance().clone();
        provenance.targets = vec![target.into()];
        let graph =
            volta_graph::GraphBuilder::new(provenance).finish(volta_graph::Terminal::Completed);
        let report = volta_graph_check::check_graph(&graph);
        assert!(report.amd.is_some());
        assert!(matches!(
            report.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
}

fn verify_copy(source: &str, blocks: &[u32]) {
    let module = frontend::parse(source).unwrap();
    for &block in blocks {
        let checked = native_common::check(source, &module, Some("copy"), config(block)).unwrap();
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
fn upstream_amd_lowering_retains_shift_inputs_and_wait_classes() {
    let source = COPY.replacen(
        "v_lshlrev_b32_e32 v0, 2, v0",
        "v_lshlrev_b32_e32 v0, 34, v0",
        1,
    );
    assert_ne!(source, COPY);
    let parsed = parse_kernel(&source, "copy").unwrap();
    let lowered = lower_kernel(&parsed).unwrap();
    assert_eq!(lowered.name, parsed.name);
    assert_eq!(lowered.target, parsed.target);
    assert_eq!(lowered.descriptor, parsed.descriptor);
    assert_eq!(lowered.instructions.len(), parsed.instructions.len());
    assert!(matches!(
        lowered.instructions[InstrId(1)],
        LoweredInstr::Shl32 { shift: 34, .. }
    ));
    let waits = lowered
        .instructions
        .values()
        .filter_map(|instruction| match instruction {
            LoweredInstr::WaitCnt { vmcnt, lgkmcnt } => Some((*vmcnt, *lgkmcnt)),
            _ => None,
        })
        .collect::<Vec<_>>();
    assert_eq!(waits, [(None, Some(0)), (Some(0), None)]);
    verify_copy(&source, &[65]);
}

#[test]
fn parsing_the_kernel_does_not_certify_its_memory_readiness() {
    for wait in ["\ts_waitcnt lgkmcnt(0)\n", "\ts_waitcnt vmcnt(0)\n"] {
        let source = COPY.replacen(wait, "", 1);
        assert_ne!(source, COPY);
        lower_kernel(&parse_kernel(&source, "copy").unwrap()).unwrap();
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

#[test]
fn both_amd_paths_reject_invalid_target_features() {
    for target in [
        "gfx950:banana",
        "gfx950:xnack+:xnack-",
        "gfx950:xnack-:xnack-",
    ] {
        let source = COPY.replace("gfx950:xnack-", target);
        let parsed = parse_kernel(&source, "copy").unwrap();
        assert!(matches!(
            lower_kernel(&parsed),
            Err(volta_amd_analysis::LowerError::UnsupportedTarget { .. })
        ));
        assert!(frontend::parse(&source).is_err());
    }
}
