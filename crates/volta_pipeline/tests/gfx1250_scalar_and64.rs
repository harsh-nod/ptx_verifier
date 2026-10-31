//! Bitwise selection must not read discarded SGPR bits or hide register leases.
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

fn verified(body: &str, expected: [u32; 3]) {
    let checked = run(body);
    output(&checked, expected);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks
    );
}

#[test]
fn original_prologue_mask_discards_the_uninitialized_upper_word() {
    for low in [0, 1, 15, 16, u32::MAX] {
        verified(
            &format!("s_mov_b32 s2,{low}\ns_and_b64 s[2:3],s[2:3],15\ns_mov_b64 s[8:9],s[2:3]"),
            [low & 15, 0, u32::from(low & 15 != 0)],
        );
    }
    // Scalar execution and register writes are independent of empty EXEC.
    verified(
        "s_mov_b32 exec_lo,0\ns_mov_b32 s2,15\ns_and_b64 s[2:3],s[2:3],15\ns_mov_b64 s[8:9],s[2:3]\ns_mov_b32 exec_lo,1",
        [15, 0, 1],
    );
}

#[test]
fn inline_integer_masks_have_their_full_64bit_width() {
    for mask in [-16i64, -1, 0, 15, 64] {
        verified(
            &format!("s_mov_b64 s[6:7],-1\ns_and_b64 s[8:9],s[6:7],{mask}"),
            [
                mask as u32,
                ((mask as u64) >> 32) as u32,
                u32::from(mask != 0),
            ],
        );
    }
}

#[test]
fn either_operand_and_either_word_can_supply_the_known_zero_mask() {
    for high in [false, true] {
        for swap in [false, true] {
            let prepare = if high {
                "s_mov_b32 s7,10\ns_mov_b32 s12,0\ns_mov_b32 s13,15"
            } else {
                "s_mov_b32 s6,10\ns_mov_b64 s[12:13],15"
            };
            let sources = if swap {
                "s[12:13],s[6:7]"
            } else {
                "s[6:7],s[12:13]"
            };
            verified(
                &format!("{prepare}\ns_and_b64 s[8:9],{sources}"),
                if high { [0, 10, 1] } else { [10, 0, 1] },
            );
        }
    }
    verified("s_and_b64 s[8:9],s[6:7],0", [0, 0, 0]);
}

#[test]
fn partially_initialized_abi_bits_survive_only_exact_selection() {
    for high in [false, true] {
        let body = if high {
            "s_load_b32 s7,s[0:1],8\ns_wait_kmcnt 0\ns_mov_b32 s12,0\ns_mov_b32 s13,15\ns_and_b64 s[8:9],s[6:7],s[12:13]"
        } else {
            "s_load_b32 s6,s[0:1],8\ns_wait_kmcnt 0\ns_and_b64 s[8:9],s[6:7],15"
        };
        verified(body, if high { [0, 10, 1] } else { [10, 0, 1] });
    }
    // Neither low source word is fully defined. Their disjoint known-zero
    // bits nevertheless cover every output bit, independently proving zero.
    verified(
        "s_and_b32 s6,s10,-2\ns_and_b32 s12,s11,1\ns_mov_b32 s7,0\ns_mov_b32 s13,0\ns_and_b64 s[8:9],s[6:7],s[12:13]",
        [0, 0, 0],
    );
    let checked =
        run("s_load_b32 s6,s[0:1],8\ns_wait_kmcnt 0\ns_mov_b32 s7,0\ns_and_b64 s[8:9],s[6:7],-1");
    assert!(
        checked
            .analysis
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("undefined")
    );
}

#[test]
fn aliased_destinations_capture_all_source_words_before_writing() {
    let a = 0x0123_4567_89ab_cdefu64;
    let b = 0x8765_4321_fedc_ba98u64;
    for destination in ["s[6:7]", "s[12:13]"] {
        verified(
            &format!(
                "s_mov_b32 s6,{}\ns_mov_b32 s7,{}\ns_mov_b32 s12,{}\ns_mov_b32 s13,{}\ns_and_b64 {destination},s[6:7],s[12:13]\ns_mov_b64 s[8:9],{destination}",
                a as u32,
                (a >> 32) as u32,
                b as u32,
                (b >> 32) as u32
            ),
            [
                (a & b) as u32,
                ((a & b) >> 32) as u32,
                u32::from(a & b != 0),
            ],
        );
    }
}

#[test]
fn known_nonzero_scc_does_not_make_other_result_bits_known() {
    verified(
        "s_mov_b32 s6,1\ns_and_b64 s[8:9],s[6:7],-1\ns_cselect_b32 s17,1,0\ns_mov_b64 s[8:9],0\ns_mov_b32 s8,s17",
        [1, 0, 1],
    );
    for body in [
        "s_mov_b32 s6,1\ns_and_b64 s[8:9],s[6:7],-1",
        "s_mov_b32 s6,0\ns_and_b64 s[8:9],s[6:7],-1",
    ] {
        let checked = run(body);
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("undefined") || error.contains("uninitialized SCC"),
            "{error}"
        );
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Unknown);
    }
}

#[test]
fn masked_words_remain_register_reads_and_require_scalar_load_completion() {
    for wait in ["", "s_wait_kmcnt 0"] {
        let checked = run(&format!(
            "s_load_b64 s[6:7],s[0:1],0\n{wait}\ns_mov_b64 s[12:13],0\ns_and_b64 s[8:9],s[6:7],s[12:13]"
        ));
        output(&checked, [0, 0, 0]);
        assert_eq!(
            checked.checks.verdict(Property::AmdWaitReadiness),
            if wait.is_empty() {
                Verdict::Fail
            } else {
                Verdict::Pass
            },
            "{:?}",
            checked.checks
        );
        if wait.is_empty() {
            assert!(
                checked
                    .checks
                    .amd
                    .as_ref()
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|hazard| hazard.register.file == AmdRegisterFile::Scalar
                        && hazard.register.index == 7)
            );
        }
        let graph = checked.analysis.graph();
        // Locate the typed source event by its full source-register set; these
        // reads remain even though the mask determines every output bit.
        let reads = graph
            .amd_events()
            .iter()
            .find_map(|event| match &event.kind {
                AmdEventKind::Instruction { reads, writes, .. }
                    if writes
                        .iter()
                        .any(|r| r.file == AmdRegisterFile::Scalar && r.index == 8)
                        && [6, 7, 12, 13].into_iter().all(|index| {
                            reads
                                .iter()
                                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
                        }) =>
                {
                    Some(reads)
                }
                _ => None,
            });
        assert!(reads.is_some(), "missing complete scalar source roles");
    }
}

#[test]
fn opaque_math_data_cannot_become_concrete_bits_even_under_a_zero_mask() {
    let checked = run(
        "s_mov_b64 s[14:15],196608\ns_load_b32 s6,s[14:15],0\ns_wait_kmcnt 0\ns_mov_b32 s7,0\ns_and_b64 s[8:9],s[6:7],0",
    );
    assert!(
        checked
            .analysis
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("symbolic mathematical data")
    );
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Unknown);
}

#[test]
fn unknown_result_bits_cannot_supply_addresses_or_execution_masks() {
    for suffix in [
        "v_mov_b32 v0,0\nv_mov_b32 v1,1\nglobal_store_b32 v0,v1,s[8:9]",
        "s_and_b64 exec,s[8:9],-1",
    ] {
        let checked = run(&format!(
            "s_mov_b32 s6,65536\ns_and_b64 s[8:9],s[6:7],-1\n{suffix}"
        ));
        assert!(
            checked
                .analysis
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("undefined")
        );
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Unknown);
    }
}

#[test]
fn other_64bit_operations_keep_their_existing_undefined_input_boundary() {
    for instruction in ["s_or_b64", "s_xor_b64", "s_andn2_b64"] {
        let checked = run(&format!("s_mov_b32 s6,0\n{instruction} s[8:9],s[6:7],0"));
        assert!(
            checked
                .analysis
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized Scalar register 7")
        );
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Unknown);
    }
}

#[test]
fn float_and_noninline_literal_widths_remain_explicitly_unsupported() {
    for literal in ["0.5", "-1.0", "65", "-17", "0xffffffff", "0x100000000"] {
        let checked = run(&format!(
            "s_mov_b64 s[6:7],-1\ns_and_b64 s[8:9],s[6:7],{literal}"
        ));
        assert!(
            checked
                .analysis
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("requires register pairs or integer inline constants"),
            "{literal}"
        );
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Unknown);
    }
}
