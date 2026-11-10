//! CDNA4 selector bits, lane definedness and Table11 software dependencies.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend,
};
use volta_graph::{AmdEventKind, AmdRegisterFile, Terminal};
use volta_graph_check::{
    GraphConclusion, Verdict,
    amdgpu::{AmdRegisterHazardKind, check_amdgpu},
    check_graph,
};

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"gfx950\"\n.text\n.globl k\nk:\n{body}\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_kernarg_size 4\n.amdhsa_user_sgpr_kernarg_segment_ptr 1\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n.amdgpu_metadata\n---\namdhsa.version: [1,2]\namdhsa.kernels:\n  - .name: k\n    .args:\n      - .name: selector\n        .offset: 0\n        .size: 4\n        .value_kind: by_value\n...\n.end_amdgpu_metadata\n"
    )
}
fn run(body: &str, block: u32) -> AnalysisResult {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: u64::from(block),
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::Int(5));
    analyze(&frontend::parse(&source(body)).unwrap(), Some("k"), config).unwrap()
}
fn output() -> &'static str {
    "s_mov_b32 s8,0x20000\ns_mov_b32 s9,0\nv_lshlrev_b32 v3,2,v0\nv_cvt_f32_u32 v2,v2\nglobal_store_dword v3,v2,s[8:9]"
}
fn values(result: &AnalysisResult, count: u32, expected: impl Fn(u32) -> f64) {
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), count as usize);
    for index in 0..count {
        assert_eq!(
            outputs
                .arena
                .as_f64(outputs.element("out", u64::from(index)).unwrap()),
            Some(expected(index)),
            "output {index}"
        );
    }
}

#[test]
fn register_selectors_use_exactly_the_low_six_bits_and_allow_destination_aliases() {
    for selector in [0u32, 5, 63, 64, 69, u32::MAX] {
        for destination in ["s6", "s5"] {
            let result = run(
                &format!(
                    "s_mov_b32 s5,{selector}\nv_readlane_b32 {destination},v0,s5\ns_nop 1\nv_mov_b32 v2,{destination}\n{}",
                    output()
                ),
                64,
            );
            values(&result, 64, |_| f64::from(selector & 63));
            let record = result
                .graph()
                .amd_events()
                .iter()
                .find(|record| matches!(record.kind, AmdEventKind::LaneRead { .. }))
                .unwrap();
            assert!(
                matches!(record.kind, AmdEventKind::LaneRead { lane } if u32::from(lane) == selector & 63)
            );
        }
    }
}

#[test]
fn scalar_selected_reads_and_writes_ignore_empty_exec_and_preserve_other_lanes() {
    let body = format!(
        "v_mov_b32 v1,7\ns_mov_b32 s4,42\ns_mov_b32 s5,69\ns_mov_b64 exec,0\nv_writelane_b32 v1,s5,s5\ns_nop 0\nv_readlane_b32 s6,v1,s5\ns_nop 1\ns_mov_b64 exec,-1\nv_mov_b32 v2,v1\n{}",
        output()
    );
    let result = run(&body, 64);
    values(&result, 64, |index| if index == 5 { 69. } else { 7. });
    assert!(
        result
            .graph()
            .amd_events()
            .iter()
            .any(|r| matches!(r.kind, AmdEventKind::LaneWrite { lane: 5 }))
    );
    let broadcast = run(&body.replace("v_mov_b32 v2,v1", "v_mov_b32 v2,s6"), 64);
    values(&broadcast, 64, |_| 69.);
}

#[test]
fn every_partial_wave_uses_its_own_selector_and_cannot_reach_unlaunched_lanes() {
    let result = run(
        &format!(
            "s_mov_b32 s5,64\nv_readlane_b32 s6,v0,s5\ns_nop 1\nv_mov_b32 v2,s6\n{}",
            output()
        ),
        65,
    );
    values(&result, 65, |index| if index < 64 { 0. } else { 64. });
    for instruction in ["v_readlane_b32 s6,v0,s5", "v_writelane_b32 v0,s5,s5"] {
        let result = run(
            &format!("s_mov_b32 s4,7\ns_mov_b32 s5,69\n{instruction}"),
            65,
        );
        assert!(
            matches!(result.graph().terminal(), Terminal::Aborted { reason, .. } if reason.contains("outside the launch"))
        );
        assert!(result.symbolic_outputs().is_err());
    }
}

#[test]
fn unknown_selectors_and_undefined_inactive_source_lanes_are_never_fabricated() {
    for (index, body) in [
        "s_mov_b64 exec,0\nv_readlane_b32 s6,v0,s5",
        "s_mov_b64 exec,0\ns_mov_b32 s4,7\nv_writelane_b32 v0,s5,s5",
        "s_mov_b32 s5,5\ns_mov_b64 exec,1\nv_mov_b32 v1,7\ns_mov_b64 exec,0\nv_readlane_b32 s6,v1,s5",
    ].into_iter().enumerate() {
        let result = run(body, 64);
        if index < 2 {
            assert!(!result.graph().amd_events().iter().any(|record| matches!(record.kind, AmdEventKind::Instruction { .. }) && result.graph().event(record.event).pc.and_then(|pc| result.graph().provenance().instructions.get(pc.0 as usize)).is_some_and(|i| matches!(i.kind,"readlane scalar"|"writelane scalar"))));
        }
        assert!(matches!(
            result.graph().terminal(),
            Terminal::Aborted { .. }
        ));
        assert!(result.symbolic_outputs().is_err());
        assert!(!result.graph().amd_events().iter().any(|record| matches!(
            record.kind,
            AmdEventKind::LaneRead { .. } | AmdEventKind::LaneWrite { .. }
        )));
        assert!(!matches!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        ));
    }
}

#[test]
fn valu_produced_selectors_need_four_states_for_reads_and_writes_even_under_empty_exec() {
    for states in 0..=4 {
        for consumer in ["v_readlane_b32 s6,v0,s5", "v_writelane_b32 v0,s5,s5"] {
            let wait = if states == 0 {
                String::new()
            } else {
                format!("s_nop {}\n", states - 1)
            };
            let result = run(
                &format!(
                    "s_mov_b32 s4,7\ns_mov_b64 exec,0\nv_readlane_b32 s5,v0,0\n{wait}{consumer}"
                ),
                64,
            );
            let checked = check_amdgpu(result.graph());
            assert_eq!(checked.trace.verdict(), Verdict::Pass);
            let hazards = checked
                .wait_readiness
                .violations()
                .iter()
                .filter(|hazard| {
                    hazard.kind == AmdRegisterHazardKind::ValuScalarReadBeforeReady
                        && hazard.register.file == AmdRegisterFile::Scalar
                        && hazard.register.index == 5
                })
                .count();
            assert_eq!(hazards != 0, states < 4, "{consumer}, states={states}");
            if states == 4 {
                assert_eq!(
                    check_graph(result.graph()).conclusion(),
                    GraphConclusion::Verified
                );
            }
        }
    }
}

#[test]
fn pending_scalar_selector_reads_require_lgkm_completion_even_with_empty_exec() {
    for wait in ["", "s_waitcnt lgkmcnt(0)\n"] {
        let result = run(
            &format!("s_load_dword s5,s[0:1],0\ns_mov_b64 exec,0\n{wait}v_readlane_b32 s6,v0,s5"),
            64,
        );
        let checked = check_amdgpu(result.graph());
        assert_eq!(checked.trace.verdict(), Verdict::Pass);
        let selector_hazard = checked.wait_readiness.violations().iter().any(|hazard| {
            hazard.kind == AmdRegisterHazardKind::ReadBeforeReady
                && hazard.register.file == AmdRegisterFile::Scalar
                && hazard.register.index == 5
        });
        assert_eq!(selector_hazard, wait.is_empty());
    }
}

#[test]
fn exec_word_mask_count_preserves_every_active_rank_and_inactive_output() {
    for mask in [0, 1, 1 << 63, 0x8000000100000025, u64::MAX] {
        let result = run(
            &format!(
                "v_mov_b32 v2,99\ns_mov_b32 exec_lo,{}\ns_mov_b32 exec_hi,{}\nv_mbcnt_lo_u32_b32 v1,exec_lo,0\nv_mbcnt_hi_u32_b32 v2,exec_hi,v1\ns_mov_b64 exec,-1\n{}",
                mask as u32,
                mask >> 32,
                output()
            ),
            64,
        );
        values(&result, 64, |index| {
            if mask & (1u64 << index) == 0 {
                99.
            } else {
                f64::from((mask & ((1u64 << index) - 1)).count_ones())
            }
        });
        for event in result.graph().amd_events() {
            if let AmdEventKind::Instruction { reads, .. } = &event.kind {
                let scalar_reads = reads
                    .iter()
                    .filter(|r| r.file == AmdRegisterFile::Scalar && matches!(r.index, 126 | 127))
                    .count();
                if scalar_reads != 0 {
                    assert_eq!(scalar_reads, 1);
                }
            }
        }
    }
}

#[test]
fn valu_produced_exec_words_keep_the_two_state_scalar_data_dependency() {
    for states in 0..=2 {
        let wait = if states == 0 {
            String::new()
        } else {
            format!("s_nop {}\n", states - 1)
        };
        for instruction in [
            "v_mbcnt_lo_u32_b32 v1,exec_lo,0",
            "v_mbcnt_hi_u32_b32 v1,exec_hi,0",
        ] {
            let result = run(&format!("v_cmpx_eq_u32 vcc,v0,v0\n{wait}{instruction}"), 64);
            let checked = check_amdgpu(result.graph());
            assert_eq!(checked.trace.verdict(), Verdict::Pass);
            assert_eq!(
                checked.wait_readiness.violations().iter().any(|h| h.kind
                    == AmdRegisterHazardKind::ValuScalarReadBeforeReady
                    && matches!(h.register.index, 126 | 127)),
                states < 2
            );
        }
    }
}
