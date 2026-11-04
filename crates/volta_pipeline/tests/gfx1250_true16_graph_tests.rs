//! True16 preserved upper halves retain asynchronous producer dependencies.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AmdEventKind, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, Verdict, amdgpu::AmdRegisterHazardKind};

const OPERATIONS: &[(&str, f64)] = &[
    ("add", 5.),
    ("sub", -1.),
    ("mul", 6.),
    ("max_num", 3.),
    ("min", 2.),
    ("cvt", 2.),
    ("fmac", 6.),
];

fn source(operation: &str, encoding: &str, producer: bool, wait: bool) -> String {
    let load = if producer {
        "global_load_b32 v1, v0, s[4:5]\ns_wait_xcnt 0"
    } else {
        "s_nop 0"
    };
    let completion = if wait { "s_wait_loadcnt 0" } else { "s_nop 0" };
    let instruction = if operation == "cvt" {
        format!("v_mov_b32 v2, 0x40000000\nv_cvt_f16_f32_{encoding} v1, v2")
    } else {
        format!(
            "v_mov_b32 v2, 0x4000\nv_mov_b32 v3, 0x4200\nv_{operation}_f16_{encoding} v1, v2, v3"
        )
    };
    let text = format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.amdhsa_code_object_version 6
.text
.globl k
.p2align 8
.type k,@function
k:
s_load_b128 s[4:7], s[0:1], 0
s_wait_kmcnt 0
v_lshlrev_b32 v0, 2, v0
{load}
{completion}
{instruction}
v_cvt_f32_f16_e32 v4, v1
v_lshrrev_b32 v5, 16, v1
v_cvt_f32_f16_e32 v5, v5
v_lshlrev_b32 v0, 1, v0
global_store_b32 v0, v4, s[6:7]
s_wait_xcnt 0
global_store_b32 v0, v5, s[6:7] offset:4
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.Lend:
.size k, .Lend-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_user_sgpr_count 2
.amdhsa_reserve_vcc 0
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 16
.amdhsa_next_free_sgpr 8
.amdhsa_next_free_vgpr 6
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .wavefront_size: 32
    .sgpr_count: 8
    .vgpr_count: 6
    .max_flat_workgroup_size: 32
    .args:
      - .name: x
        .address_space: global
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .address_space: global
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    );
    if let Some(directory) = std::env::var_os("VOLTA_GFX1250_TRUE16_ASSEMBLY_DIR") {
        let directory = std::path::PathBuf::from(directory);
        std::fs::create_dir_all(&directory).unwrap();
        std::fs::write(
            directory.join(format!(
                "{operation}-{encoding}-producer{producer}-wait{wait}.s"
            )),
            &text,
        )
        .unwrap();
    }
    text
}

fn checked(text: &str) -> native_common::Checked {
    let module = frontend::parse(text).expect("native true16 control parses");
    let mut config = AnalysisConfig::new((32, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 65536,
            elem_width: 2,
            len: 64,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 131072,
            elem_width: 4,
            len: 64,
            kind: ArrayKind::Output,
        },
    ];
    config.params = ["x", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    native_common::check(text, &module, Some("k"), config).unwrap()
}

fn complete_values(result: &native_common::Checked, operation: &str, low: f64) {
    let actual = result
        .analysis
        .symbolic_outputs()
        .expect("candidate completes every output");
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..64).collect::<Vec<_>>()
    );
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let mut elements = Vec::new();
    for lane in 0..32 {
        let mut value = arena.float_from_f64(low).unwrap();
        if operation == "fmac" {
            let prior_low = arena.input_element(x, lane * 2);
            value = arena.add(value, prior_low);
        }
        elements.push((lane * 2, value));
        let prior_high = arena.input_element(x, lane * 2 + 1);
        elements.push((lane * 2 + 1, prior_high));
    }
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    };
    let outcome = check_output_equivalence(actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(outcome, EquivOutcome::Equivalent), "{outcome:?}");
}

#[test]
fn completed_async_producer_preserves_every_true16_upper_half() {
    for encoding in ["e32", "e64"] {
        for &(operation, low) in OPERATIONS {
            let text = source(operation, encoding, true, true);
            let result = checked(&text);
            assert_eq!(
                result.checks.conclusion(),
                GraphConclusion::Verified,
                "{operation}/{encoding}: {:#?}",
                result.checks
            );
            complete_values(&result, operation, low);
        }
    }
}

#[test]
fn missing_load_completion_has_a_read_before_ready_at_the_preserved_destination() {
    for encoding in ["e32", "e64"] {
        for &(operation, low) in OPERATIONS {
            let text = source(operation, encoding, true, false);
            let result = checked(&text);
            complete_values(&result, operation, low);
            assert!(
                matches!(result.checks.conclusion(), GraphConclusion::Rejected { .. }),
                "{operation}/{encoding}: {:#?}",
                result.checks
            );
            let report = result.checks.amd.as_ref().unwrap();
            assert_eq!(report.trace.verdict(), Verdict::Pass);
            assert_eq!(report.barrier.verdict(), Verdict::Pass);
            assert_eq!(report.memory_conflict.verdict(), Verdict::Pass);
            let prefix = if operation == "cvt" {
                "v_cvt_f16_f32_".into()
            } else {
                format!("v_{operation}_f16_")
            };
            let graph = &result.analysis.graph;
            let witnesses: Vec<_> = report
                .wait_readiness
                .violations()
                .iter()
                .filter(|hazard| {
                    if hazard.kind != AmdRegisterHazardKind::ReadBeforeReady
                        || hazard.register.file != AmdRegisterFile::Vector
                        || hazard.register.index != 1
                    {
                        return false;
                    }
                    let pc = graph.event(hazard.use_event).pc.unwrap().0 as usize;
                    let (start, end) = graph.provenance().instructions[pc].span.unwrap();
                    text[start..end].starts_with(&prefix)
                })
                .collect();
            assert!(
                !witnesses.is_empty(),
                "true16 preservation needs its own typed read dependency: {operation}/{encoding}: {:#?}",
                report.wait_readiness
            );
            assert!(graph.amd_events().iter().any(|event| event.event == witnesses[0].use_event && matches!(&event.kind, AmdEventKind::Instruction { reads, .. } if reads.iter().any(|r| r.file == AmdRegisterFile::Vector && r.index == 1))));
        }
    }
}

#[test]
fn unknown_upper_half_stays_undefined_after_a_legal_true16_write() {
    for encoding in ["e32", "e64"] {
        let text = source("add", encoding, false, true);
        let result = checked(&text);
        assert!(
            matches!(result.analysis.symbolic_outputs(), Err(OutputsUnavailable::Aborted(EvalError::Unsupported { what, .. })) if what.contains("unknown half"))
        );
        assert!(!matches!(
            result.checks.conclusion(),
            GraphConclusion::Verified
        ));
    }
}
