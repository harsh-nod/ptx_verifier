//! Concrete SOPC U64 comparisons observe both source words and their leases.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::{AmdEventKind, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, Property, Verdict};

fn source(body: &str) -> String {
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_wait_kmcnt 0
s_mov_b32 s8,123
s_mov_b32 s9,456
{body}
s_cselect_b32 s16,1,0
v_mov_b32 v0,0
v_mov_b32 v1,s8
v_mov_b32 v2,s9
v_mov_b32 v3,s16
v_add_nc_u32 v1,0,v1
v_add_nc_u32 v2,0,v2
v_add_nc_u32 v3,0,v3
global_store_b32 v0,v1,s[4:5]
s_wait_xcnt 0
global_store_b32 v0,v2,s[4:5] offset:4
s_wait_xcnt 0
global_store_b32 v0,v3,s[4:5] offset:8
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: byte
        .offset: 8
        .size: 1
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    )
}

fn run(body: &str) -> native_common::Checked {
    let text = source(body);
    let module = frontend::parse(&text).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "out".into(),
            base: 65536,
            elem_width: 4,
            len: 3,
            kind: ArrayKind::Output,
        },
        ArrayDef {
            name: "input".into(),
            base: 196608,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Input,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Bytes(vec![10]),
    ];
    native_common::check(&text, &module, Some("k"), config).unwrap()
}

fn output(checked: &native_common::Checked, expected: [u32; 3]) {
    let outputs = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    assert_eq!(outputs.outputs[0].1.len(), expected.len());
    for (index, expected) in expected.into_iter().enumerate() {
        assert_eq!(outputs.outputs[0].1[index].0, index as u64);
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index as u64).unwrap()),
            Some(i64::from(expected))
        );
    }
}

fn verified(body: &str, scc: bool) {
    let checked = run(body);
    output(&checked, [123, 456, u32::from(scc)]);
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
}

fn refused(body: &str, reason: &str) {
    let checked = run(body);
    let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(error.contains(reason), "{body}: {error}");
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

fn pair(register: u16, value: u64) -> String {
    format!(
        "s_mov_b32 s{register},{}\ns_mov_b32 s{},{}",
        value as u32,
        register + 1,
        (value >> 32) as u32
    )
}

#[test]
fn original_mask_then_lg_prologue_has_fully_defined_comparison_inputs() {
    for low in [0, 1, 15, 16] {
        verified(
            &format!("s_mov_b32 s2,{low}\ns_and_b64 s[2:3],s[2:3],15\ns_cmp_lg_u64 s[2:3],0"),
            low & 15 != 0,
        );
    }
}

#[test]
fn equality_and_inequality_observe_both_words() {
    for (a, b) in [
        (0, 0),
        (0, 1u64 << 32),
        (7, (1u64 << 32) | 7),
        (u64::MAX, u64::MAX),
        (u64::MAX, u64::from(u32::MAX)),
        (0x1234_5678_9abc_def0, 0x1234_5678_9abc_def1),
    ] {
        for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            verified(
                &format!(
                    "{}\n{}\n{instruction} s[6:7],s[12:13]",
                    pair(6, a),
                    pair(12, b)
                ),
                if instruction == "s_cmp_eq_u64" {
                    a == b
                } else {
                    a != b
                },
            );
        }
    }
}

#[test]
fn inline_integer_constants_are_signed_extended_to_64_bits() {
    for immediate in [-16i64, -1, 0, 15, 64] {
        for equal in [false, true] {
            let value = (immediate as u64) ^ if equal { 0 } else { 1u64 << 32 };
            for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
                for sources in [format!("s[6:7],{immediate}"), format!("{immediate},s[6:7]")] {
                    verified(
                        &format!("{}\n{instruction} {sources}", pair(6, value)),
                        if instruction == "s_cmp_eq_u64" {
                            equal
                        } else {
                            !equal
                        },
                    );
                }
            }
        }
    }
    verified("s_cmp_eq_u64 -1,-1", true);
    verified("s_cmp_lg_u64 -16,64", true);
}

#[test]
fn scalar_comparisons_execute_with_empty_exec_and_replace_scc() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        for equal in [false, true] {
            for previous in [false, true] {
                let checked = run(&format!(
                    "s_mov_b64 s[6:7],1\ns_mov_b64 s[12:13],{}\ns_cmp_eq_u32 0,{}\ns_mov_b32 exec_lo,0\n{instruction} s[6:7],s[12:13]\ns_mov_b32 exec_lo,1",
                    if equal { 1 } else { 2 },
                    u32::from(!previous)
                ));
                let result = if instruction == "s_cmp_eq_u64" {
                    equal
                } else {
                    !equal
                };
                output(&checked, [123, 456, u32::from(result)]);
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
                assert!(checked.analysis.graph().amd_events().iter().any(|event| {
                    matches!(&event.kind, AmdEventKind::Instruction { exec_mask: 0, reads, writes, .. }
                        if writes.is_empty() && [6, 7, 12, 13].into_iter().all(|index|
                            reads.iter().any(|register| register.file == AmdRegisterFile::Scalar
                                && register.index == index && register.lanes == u64::MAX)))
                }));
            }
        }
    }
    // An earlier symbolic SCC must not survive a later concrete comparison.
    verified(
        "s_mov_b64 s[14:15],196608\ns_load_b32 s6,s[14:15],0\ns_wait_kmcnt 0\ns_cmp_eq_u32 s6,0\ns_cmp_eq_u64 -1,-1",
        true,
    );
}

#[test]
fn existing_32bit_comparisons_keep_their_width_and_signedness() {
    for (instruction, expected) in [
        ("s_cmp_eq_u32", true),
        ("s_cmp_lg_u32", false),
        ("s_cmp_eq_i32", true),
        ("s_cmp_lg_i32", false),
        ("s_cmp_gt_u32", true),
        ("s_cmp_gt_i32", false),
    ] {
        let (low, other) = if instruction.contains("gt") {
            (u32::MAX, 0)
        } else {
            (65, 65)
        };
        verified(
            &format!("s_mov_b32 s6,{low}\n{instruction} s6,{other}"),
            expected,
        );
    }
}

#[test]
fn identical_source_pairs_preserve_data_and_drive_scalar_branches() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        let taken = instruction == "s_cmp_eq_u64";
        let checked = run(&format!(
            "{}\n{instruction} s[8:9],s[8:9]\ns_cbranch_{} .Lsame\ns_mov_b32 s8,0\ns_branch .Ldone\n.Lsame:\ns_mov_b32 s8,99\n.Ldone:",
            pair(8, 0x1234_5678_0000_007b),
            if taken { "scc1" } else { "scc0" }
        ));
        output(&checked, [99, 0x1234_5678, u32::from(taken)]);
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    }
}

#[test]
fn uninitialized_or_partial_words_refuse_even_identical_source_pairs() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        for initialized in [6, 7] {
            refused(
                &format!("s_mov_b32 s{initialized},0\n{instruction} s[6:7],s[6:7]"),
                "uninitialized Scalar register",
            );
        }
        refused(
            &format!(
                "s_load_b32 s6,s[0:1],8\ns_wait_kmcnt 0\ns_mov_b32 s7,0\n{instruction} s[6:7],s[6:7]"
            ),
            "undefined bits",
        );
    }
}

#[test]
fn undefined_second_source_is_not_bypassed_by_known_different_bits() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        refused(
            &format!("s_mov_b64 s[6:7],0\ns_mov_b32 s12,1\n{instruction} s[6:7],s[12:13]"),
            "uninitialized Scalar register 13",
        );
    }
}

#[test]
fn mathematical_and_opaque_words_are_not_concrete_comparison_values() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        refused(
            &format!(
                "s_mov_b64 s[14:15],196608\ns_load_b32 s6,s[14:15],0\ns_wait_kmcnt 0\ns_mov_b32 s7,0\n{instruction} s[6:7],s[6:7]"
            ),
            "symbolic mathematical data",
        );
        refused(
            &format!("s_mov_b64 s[6:7],src_shared_base\n{instruction} s[6:7],s[6:7]"),
            "opaque shared aperture",
        );
    }
}

#[test]
fn float_noninline_literals_and_special_register_aliases_refuse() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        for value in ["0.5", "65", "-17", "0xffffffff", "0x100000000", "exec"] {
            for sources in [format!("s[6:7],{value}"), format!("{value},s[6:7]")] {
                refused(
                    &format!("s_mov_b64 s[6:7],-1\n{instruction} {sources}"),
                    "requires SGPR pairs or integer inline constants",
                );
            }
        }
    }
}

#[test]
fn every_source_word_keeps_its_scalar_load_readiness_obligation() {
    for instruction in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
        for wait in ["", "s_wait_kmcnt 0"] {
            let checked = run(&format!(
                "s_load_b64 s[6:7],s[0:1],0\n{wait}\ns_mov_b32 s12,65536\ns_mov_b32 s13,1\n{instruction} s[6:7],s[12:13]"
            ));
            // The low words match; only the high word establishes inequality.
            output(
                &checked,
                [123, 456, u32::from(instruction == "s_cmp_lg_u64")],
            );
            assert_eq!(
                checked.checks.verdict(Property::AmdWaitReadiness),
                if wait.is_empty() {
                    Verdict::Fail
                } else {
                    Verdict::Pass
                }
            );
            if wait.is_empty() {
                let violations = checked
                    .checks
                    .amd
                    .as_ref()
                    .unwrap()
                    .wait_readiness
                    .violations();
                for index in [6, 7] {
                    assert!(violations.iter().any(|hazard| {
                        hazard.register.file == AmdRegisterFile::Scalar
                            && hazard.register.index == index
                    }));
                }
            } else {
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
            }
            assert!(checked.analysis.graph().amd_events().iter().any(|event| {
                matches!(&event.kind, AmdEventKind::Instruction { reads, writes, .. }
                    if writes.is_empty() && [6, 7, 12, 13].into_iter().all(|index|
                        reads.iter().any(|register| register.file == AmdRegisterFile::Scalar
                            && register.index == index)))
            }));
        }
    }
}
