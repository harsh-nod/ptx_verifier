//! Fixed gfx950 scratch executes real bodies and preserves exact register words.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend, ir, lower,
};
use volta_equivalence::{EquivCheckOptions, EquivOutcome, check_output_equivalence_with};
use volta_graph::{AbortCause, AmdEventKind, AmdMemoryClass, Assumption, Terminal};
use volta_graph_check::{GraphConclusion, check_graph};

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"gfx950\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_private_segment_fixed_size 8\n.amdhsa_enable_private_segment 1\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n.amdgpu_metadata\n---\namdhsa.version: [1, 2]\namdhsa.kernels:\n  - .name: k\n    .private_segment_fixed_size: 8\n...\n.end_amdgpu_metadata\n"
    )
}

fn config(block: u32) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: u64::from(block),
        kind: ArrayKind::Output,
    });
    config
}

fn output() -> &'static str {
    "s_mov_b32 s8,0x20000\ns_mov_b32 s9,0\nv_lshlrev_b32 v3,2,v0\nv_cvt_f32_u32 v2,v2\nglobal_store_dword v3,v2,s[8:9]\n"
}

fn run(body: &str, block: u32) -> AnalysisResult {
    let module = frontend::parse(&source(body)).unwrap();
    let result = analyze(&module, Some("k"), config(block)).unwrap();
    result.graph().validate().unwrap();
    result
}

fn safe(result: &AnalysisResult) {
    let checked = check_graph(result.graph());
    assert_eq!(
        checked.conclusion(),
        GraphConclusion::Verified,
        "{checked:#?}"
    );
}

fn values(result: &AnalysisResult, expected: impl Fn(u64) -> f64, count: u64) {
    let actual = result.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].1.len(), count as usize);
    for index in 0..count {
        assert_eq!(
            actual.arena.as_f64(actual.element("out", index).unwrap()),
            Some(expected(index)),
            "output {index}"
        );
    }
}

fn private_issues(result: &AnalysisResult, load: bool) -> usize {
    result.graph().amd_events().iter().filter(|event| matches!(event.kind,
        AmdEventKind::MemoryIssue { class, .. } if class == if load { AmdMemoryClass::ScratchLoad32 } else { AmdMemoryClass::ScratchStore32 }
    )).count()
}

fn unsupported(result: &AnalysisResult, text: &str) {
    assert!(result.symbolic_outputs().is_err());
    let Terminal::Aborted { cause, reason, .. } = result.graph().terminal() else {
        panic!("aborted profile")
    };
    assert_eq!(*cause, AbortCause::Unsupported);
    assert!(reason.contains(text), "{reason}");
    assert!(!matches!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    ));
}

#[test]
fn fixed_private_cells_are_per_physical_item_and_preserve_last_word() {
    // Both waves use the same offset. Each physical item's own value survives.
    for policy in ["", "sc0 sc1"] {
        let body = format!(
            "s_mov_b32 s4,8\nv_add_u32 v1,1000,v0\nscratch_store_dword off,v1,s4 offset:-4 {policy}\ns_waitcnt vmcnt(0)\nscratch_load_dword v2,off,s4 offset:-4 {policy}\ns_waitcnt vmcnt(0)\n{}",
            output()
        );
        let result = run(&body, 128);
        safe(&result);
        values(&result, |index| 1000. + index as f64, 128);
        assert_eq!(private_issues(&result, false), 2);
        assert_eq!(private_issues(&result, true), 2);
        assert!(
            result
                .graph()
                .provenance()
                .assumptions
                .contains(&Assumption::FixedPrivateAllocation(8))
        );
        assert_eq!(
            result
                .graph()
                .amd_events()
                .iter()
                .filter(|event| matches!(event.kind, AmdEventKind::PrivateMemoryAccess { .. }))
                .count(),
            256
        );
    }
}

#[test]
fn adjacent_private_words_keep_exact_unsigned_patterns_without_byte_reversal() {
    let body = format!(
        "s_mov_b32 s4,0\nv_mov_b32 v1,0x11223344\nscratch_store_dword off,v1,s4\ns_waitcnt vmcnt(0)\nv_mov_b32 v1,0xa1b2c3d4\nscratch_store_dword off,v1,s4 offset:4\ns_waitcnt vmcnt(0)\nscratch_load_dword v1,off,s4\ns_waitcnt vmcnt(0)\nscratch_load_dword v2,off,s4 offset:4\ns_waitcnt vmcnt(0)\nv_xor_b32 v2,v1,v2\n{}",
        output()
    );
    let result = run(&body, 64);
    safe(&result);
    values(&result, |_| f64::from(0x11223344u32 ^ 0xa1b2c3d4), 64);
}

#[test]
fn sparse_and_empty_exec_do_not_compress_lanes_or_observe_absent_sources() {
    let body = format!(
        "v_add_u32 v2,100,v0\ns_mov_b64 exec,0\nscratch_store_dword off,v20,s4 sc0 sc1\nscratch_load_dword v21,off,s4\ns_mov_b64 exec,-1\n{}",
        output()
    );
    let empty = run(&body, 64);
    safe(&empty);
    values(&empty, |i| 100. + i as f64, 64);
    assert_eq!(
        private_issues(&empty, false) + private_issues(&empty, true),
        0
    );

    let body = format!(
        "s_mov_b32 s4,0\nv_add_u32 v2,100,v0\ns_mov_b64 exec,5\nscratch_store_dword off,v2,s4\ns_waitcnt vmcnt(0)\nv_mov_b32 v2,999\nscratch_load_dword v2,off,s4\ns_waitcnt vmcnt(0)\ns_mov_b64 exec,-1\n{}",
        output()
    );
    let sparse = run(&body, 64);
    safe(&sparse);
    values(&sparse, |i| 100. + i as f64, 64);
    let threads: Vec<_> = sparse
        .graph()
        .amd_events()
        .iter()
        .filter_map(|event| match event.kind {
            AmdEventKind::PrivateMemoryAccess { thread, .. } => Some(thread.0),
            _ => None,
        })
        .collect();
    assert_eq!(threads, [0, 2, 0, 2]);
}

#[test]
fn missing_private_cell_fails_all_lane_preflight_without_partial_load_issue() {
    let result = run(
        "s_mov_b32 s4,0\nv_mov_b32 v1,7\ns_mov_b64 exec,1\nscratch_store_dword off,v1,s4\ns_waitcnt vmcnt(0)\ns_mov_b64 exec,3\nscratch_load_dword v2,off,s4",
        64,
    );
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("uninitialized private")
    );
    assert_eq!(private_issues(&result, false), 1);
    assert_eq!(private_issues(&result, true), 0);
    assert_eq!(
        result
            .graph()
            .amd_events()
            .iter()
            .filter(|event| matches!(event.kind, AmdEventKind::PrivateMemoryAccess { .. }))
            .count(),
        1
    );
}

#[test]
fn interval_failures_and_unavailable_address_never_issue_or_fill_private_cells() {
    for (base, offset) in [
        ("0", "-4"),
        ("5", "0"),
        ("4", "1"),
        ("8", "0"),
        ("0xffffffff", "1"),
    ] {
        let result = run(
            &format!(
                "s_mov_b32 s4,{base}\nv_mov_b32 v1,7\nscratch_store_dword off,v1,s4 offset:{offset}"
            ),
            64,
        );
        unsupported(&result, "declared fixed private extent");
        assert_eq!(private_issues(&result, false), 0);
    }
    for setup in ["", "s_mov_b32 s4,s33\n"] {
        let result = run(
            &format!("{setup}v_mov_b32 v1,7\nscratch_store_dword off,v1,s4"),
            64,
        );
        assert!(result.symbolic_outputs().is_err());
        assert_eq!(private_issues(&result, false), 0);
    }
    let result = run("s_mov_b32 s4,0\nscratch_load_dword v1,off,s4", 64);
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("uninitialized private")
    );
    assert_eq!(private_issues(&result, true), 0);
}

#[test]
fn private_store_visibility_and_source_guard_require_explicit_decoded_vm0() {
    let prologue = "s_mov_b32 s4,0\nv_mov_b32 v1,7\nscratch_store_dword off,v1,s4\n";
    for wait in ["", "s_waitcnt lgkmcnt(0)\n", "s_waitcnt vmcnt(1)\n"] {
        for consumer in ["scratch_load_dword v2,off,s4\n", "v_mov_b32 v1,99\n"] {
            let result = run(&format!("{prologue}{wait}{consumer}{}", output()), 64);
            // No outputs exist, so even a deliberately mismatched specification
            // cannot turn this conservative profile refusal into a refutation.
            unsupported(&result, "requires explicit VM0");
            assert_eq!(private_issues(&result, true), 0);
        }
    }
    unsupported(&run(prologue, 64), "requires explicit VM0"); // END is not source VM0.
    let good = run(
        &format!(
            "{prologue}s_waitcnt 0\nscratch_load_dword v2,off,s4\ns_waitcnt vmcnt(0)\n{}",
            output()
        ),
        64,
    );
    safe(&good);
    values(&good, |_| 7., 64);
}

#[test]
fn partial_waits_never_certify_a_conservative_private_load_ordering() {
    let setup = "s_mov_b32 s4,0\nv_mov_b32 v1,7\nscratch_store_dword off,v1,s4\ns_waitcnt vmcnt(0)\nscratch_load_dword v1,off,s4\nscratch_load_dword v2,off,s4\n";
    for wait in ["", "s_waitcnt vmcnt(1)\n", "s_waitcnt lgkmcnt(0)\n"] {
        for use_word in ["v_mov_b32 v3,v1\n", "v_mov_b32 v1,9\n", ""] {
            let result = run(&format!("{setup}{wait}{use_word}"), 64);
            unsupported(&result, "requires explicit VM0");
        }
    }
    let good = run(&format!("{setup}s_waitcnt vmcnt(0)\n{}", output()), 64);
    safe(&good);
    values(&good, |_| 7., 64);
}

#[test]
fn unspecified_word_spills_stay_undefined_and_do_not_change_nonprivate_mov() {
    let body = "s_mov_b32 s6,s33\nv_mov_b32 v1,s6\ns_mov_b32 s4,0\nscratch_store_dword off,v1,s4\ns_waitcnt vmcnt(0)\nscratch_load_dword v2,off,s4\ns_waitcnt vmcnt(0)\n";
    let transported = run(&format!("{body}v_mov_b32 v2,7\n{}", output()), 64);
    safe(&transported);
    values(&transported, |_| 7., 64);
    let observed = run(&format!("{body}{}", output()), 64);
    assert!(
        observed
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("undefined")
    );
    let ordinary = run("s_mov_b32 s6,s33\nv_mov_b32 v2,7", 64);
    assert!(
        ordinary
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("uninitialized")
    );
    assert!(
        !ordinary
            .graph()
            .provenance()
            .assumptions
            .iter()
            .any(|assumption| matches!(assumption, Assumption::FixedPrivateAllocation(_)))
    );
}

#[test]
fn lane_transport_is_exec_independent_but_cannot_reach_unlaunched_lanes() {
    let body = format!(
        "s_mov_b32 s6,42\nv_mov_b32 v1,0\ns_mov_b64 exec,0\nv_writelane_b32 v1,s6,5\ns_nop 0\nv_readlane_b32 s7,v1,5\ns_mov_b64 exec,-1\ns_nop 0\nv_mov_b32 v2,s7\n{}",
        output()
    );
    let result = run(&body, 64);
    safe(&result);
    values(&result, |_| 42., 64);
    assert!(
        result
            .graph()
            .amd_events()
            .iter()
            .any(|event| matches!(event.kind, AmdEventKind::LaneRead { lane: 5 }))
    );
    let bad = run(
        &body.replace(
            "v_writelane_b32 v1,s6,5\ns_nop 0\n",
            "v_writelane_b32 v1,s6,5\n",
        ),
        64,
    );
    let checked = volta_graph_check::amdgpu::check_amdgpu(bad.graph());
    assert_eq!(checked.trace.verdict(), volta_graph_check::Verdict::Pass);
    assert!(checked.wait_readiness.violations().iter().any(|hazard| {
        hazard.kind == volta_graph_check::amdgpu::AmdRegisterHazardKind::ValuLaneReadBeforeReady
            && hazard.register.file == volta_graph::AmdRegisterFile::Vector
            && hazard.register.index == 1
            && hazard.register.lanes == 1 << 5
    }));
    let outside = run("v_readlane_b32 s7,v0,5", 1);
    unsupported(&outside, "outside the launch");
}

#[test]
fn scratch_form_guards_run_under_empty_exec_and_on_unreachable_code() {
    for bad in [
        "scratch_store_dword off,v1,s4 sc0",
        "scratch_store_dword off,v1,s4 sc1",
        "scratch_store_dword off,v1,s4 glc",
        "scratch_store_dword v0,v1,s4",
        "scratch_store_dword off,v[1:2],s4",
        "scratch_store_dword off,v1,s[4:5]",
        "scratch_load_dword v1,off,v4",
        "scratch_load_dword v1,off,s4 offset:4096",
        "scratch_load_dword v1,off,s4 offset:-4097",
        "scratch_load_dword_e64 v1,off,s4",
    ] {
        for prefix in ["s_mov_b64 exec,0\n", "s_branch .Lout\n"] {
            assert!(
                frontend::parse(&source(&format!("{prefix}{bad}\n.Lout:\nv_mov_b32 v2,7")))
                    .is_err(),
                "{bad}"
            );
        }
    }
    for target in ["gfx942", "gfx1250"] {
        assert!(
            frontend::parse(&source("scratch_store_dword off,v1,s4").replace("gfx950", target))
                .is_err()
        );
    }
    let parsed = frontend::parse(&source("scratch_load_dword v1,off,s4")).unwrap();
    let mut forged = parsed.clone();
    forged.kernels[0].instructions[0].operands.pop();
    assert!(lower::lower_module_kernel(&forged, "k").is_err());
    let replay = frontend::parse(
        &source("s_mov_b32 s4,0\nv_mov_b32 v1,7\nscratch_store_dword off,v1,s4")
            .replace("\"gfx950\"", "\"gfx950:xnack+\""),
    )
    .unwrap();
    let replay = analyze(&replay, Some("k"), config(64)).unwrap();
    assert!(replay.symbolic_outputs().is_err());
    assert_eq!(private_issues(&replay, false), 0);
    assert!(
        !replay
            .graph()
            .provenance()
            .assumptions
            .contains(&Assumption::XnackReplayDisabled)
    );
}

#[test]
fn fixed_extent_is_required_and_dynamic_metadata_does_not_create_capacity() {
    let text = source(&format!(
        "s_mov_b32 s4,0\nv_mov_b32 v1,7\nscratch_store_dword off,v1,s4\ns_waitcnt vmcnt(0)\nv_mov_b32 v2,7\n{}",
        output()
    ));
    for changed in [
        text.replace(".amdhsa_enable_private_segment 1\n", ""),
        text.replace("fixed_size 8", "fixed_size 0")
            .replace("fixed_size: 8", "fixed_size: 0"),
        text.replace(".amdhsa_private_segment_fixed_size 8\n", ""),
    ] {
        let module = frontend::parse(&changed).unwrap();
        assert!(analyze(&module, Some("k"), config(64)).is_err());
    }
    let dynamic = text.replace(
        ".amdhsa_enable_private_segment 1",
        ".amdhsa_enable_private_segment 1\n.amdhsa_uses_dynamic_stack 1",
    );
    let module = frontend::parse(&dynamic).unwrap();
    let actual = analyze(&module, Some("k"), config(64)).unwrap();
    assert!(actual.symbolic_outputs().is_ok());
    let beyond = dynamic.replace("s4,0", "s4,8");
    unsupported(
        &analyze(&frontend::parse(&beyond).unwrap(), Some("k"), config(64)).unwrap(),
        "declared fixed private extent",
    );
    let without_metadata = text.split(".amdgpu_metadata").next().unwrap();
    assert!(
        analyze(
            &frontend::parse(without_metadata).unwrap(),
            Some("k"),
            config(64)
        )
        .is_err()
    );
    let mismatch = text.replace(
        ".private_segment_fixed_size: 8",
        ".private_segment_fixed_size: 4",
    );
    assert!(
        frontend::parse(&mismatch)
            .unwrap_err()
            .message
            .contains("metadata disagrees")
    );
    for pair in [Some((4, 8)), Some((8, 4)), None] {
        let mut forged = frontend::parse(&text).unwrap();
        forged.kernels[0]
            .descriptor
            .private_segment_fixed_size_sources = pair;
        assert!(analyze(&forged, Some("k"), config(64)).is_err());
    }
}

fn call(target: &str, first: u16) -> String {
    format!(
        "s_getpc_b64 s[{first}:{}]\ns_add_u32 s{first},s{first},{target}@rel32@lo+4\ns_addc_u32 s{},s{},{target}@rel32@hi+12\ns_swappc_b64 s[30:31],s[{first}:{}]\n",
        first + 1,
        first + 1,
        first + 1,
        first + 1
    )
}

#[test]
fn opaque_return_words_roundtrip_private_cells_and_corruption_cannot_return() {
    let save = "v_mov_b32 v8,s30\nv_mov_b32 v9,s31\ns_mov_b32 s4,0\nscratch_store_dword off,v8,s4\nscratch_store_dword off,v9,s4 offset:4\ns_waitcnt vmcnt(0)\n";
    let restore = "scratch_load_dword v8,off,s4\nscratch_load_dword v9,off,s4 offset:4\ns_waitcnt vmcnt(0)\nv_readlane_b32 s30,v8,0\nv_readlane_b32 s31,v9,0\ns_setpc_b64 s[30:31]\n";
    let mut text = source(&(call("outer", 0) + output()));
    text += &format!(
        ".type outer,@function\nouter:\n{save}{}{restore}.size outer,.-outer\n.type leaf,@function\nleaf:\nv_mov_b32 v2,7\ns_setpc_b64 s[30:31]\n.size leaf,.-leaf\n",
        call("leaf", 2)
    );
    let module = frontend::parse(&text).unwrap();
    let good = analyze(&module, Some("k"), config(64)).unwrap();
    safe(&good);
    values(&good, |_| 7., 64);
    let swapped = text.replace(
        "v_readlane_b32 s30,v8,0\nv_readlane_b32 s31,v9,0",
        "v_readlane_b32 s30,v9,0\nv_readlane_b32 s31,v8,0",
    );
    let wrong = analyze(&frontend::parse(&swapped).unwrap(), Some("k"), config(64)).unwrap();
    assert!(
        wrong
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("return address")
    );
}

#[test]
fn source_address_readiness_remains_real_at_scratch_reads() {
    // VM0 cannot make an LGKM-loaded address ready. The address happens to
    // have an eager model value0; source roles must still retain the hazard.
    for wait in ["", "s_waitcnt vmcnt(0)\n", "s_waitcnt lgkmcnt(0)\n"] {
        let body = format!(
            "s_mov_b32 s8,0x10000\ns_mov_b32 s9,0\ns_load_dword s4,s[8:9],0\n{wait}v_mov_b32 v1,7\nscratch_store_dword off,v1,s4\ns_waitcnt vmcnt(0)\nscratch_load_dword v2,off,s4\ns_waitcnt vmcnt(0)\n{}",
            output()
        );
        let module = frontend::parse(&source(&body)).unwrap();
        let mut cfg = config(64);
        cfg.arrays.push(ArrayDef {
            name: "index".into(),
            base: 0x10000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::IndexInput,
        });
        let result = analyze(&module, Some("k"), cfg).unwrap();
        if wait.contains("lgkmcnt") {
            safe(&result);
        } else {
            assert!(matches!(
                check_graph(result.graph()).conclusion(),
                GraphConclusion::Rejected { .. }
            ));
        }
    }
}

fn compiler_fixture(source: &str, launch: &str, specification: &str, calls: usize) {
    let contract: serde_yaml::Value = serde_yaml::from_str(launch).unwrap();
    assert_eq!(contract["block"], serde_yaml::to_value([64, 1, 1]).unwrap());
    assert_eq!(contract["grid"], serde_yaml::to_value([1, 1, 1]).unwrap());
    assert_eq!(
        contract["workgroup_id"],
        serde_yaml::to_value([0, 0, 0]).unwrap()
    );
    let mut config = AnalysisConfig::new((64, 1, 1));
    for array in contract["arrays"].as_sequence().unwrap() {
        assert_eq!(array["dtype"].as_str(), Some("f32"));
        assert_eq!(array["shape"], serde_yaml::to_value([64]).unwrap());
        config.arrays.push(ArrayDef {
            name: array["name"].as_str().unwrap().into(),
            base: array["base"].as_u64().unwrap(),
            elem_width: 4,
            len: 64,
            kind: if array["kind"] == "in" {
                ArrayKind::Input
            } else {
                ArrayKind::Output
            },
        });
    }
    for parameter in contract["params"].as_sequence().unwrap() {
        config.params.push(ParamValue::ArrayPtr(
            parameter["ptr"].as_str().unwrap().into(),
        ));
    }
    let module = frontend::parse(source).unwrap();
    assert_eq!(module.source, source);
    let kernel = contract["kernel"].as_str().unwrap();
    let program = lower::lower_module_kernel(&module, kernel).unwrap();
    assert_eq!(program.call_targets.len(), calls);
    assert_eq!(
        program
            .instructions
            .iter()
            .filter(|instruction| matches!(instruction.operation(), ir::Operation::Return(_)))
            .count(),
        calls
    );
    let actual = analyze(&module, Some(kernel), config).unwrap();
    safe(&actual);
    let outputs = actual.symbolic_outputs().unwrap();
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|&(index, _)| index)
            .collect::<Vec<_>>(),
        (0..64).collect::<Vec<_>>()
    );
    assert!(actual.graph().amd_events().iter().any(|event| matches!(
        event.kind,
        AmdEventKind::PrivateMemoryAccess {
            kind: volta_graph::AccessMode::Write,
            ..
        }
    )));
    assert!(actual.graph().amd_events().iter().any(|event| matches!(
        event.kind,
        AmdEventKind::PrivateMemoryAccess {
            kind: volta_graph::AccessMode::Read,
            ..
        }
    )));
    let spec = volta_spec::parse_spec(specification).unwrap();
    let (environment, assertions) =
        volta_spec::instantiate(&spec, &std::collections::HashMap::from([("N".into(), 64)]))
            .unwrap();
    let expected = volta_spec::unfold(&assertions, &environment, 0).unwrap();
    let report = check_output_equivalence_with(
        outputs,
        &expected,
        &["out".into()],
        &EquivCheckOptions {
            sample: 0,
            verify_numeric: true,
            ..Default::default()
        },
    )
    .unwrap();
    assert_eq!(report.elements_total, 64);
    assert_eq!(report.elements_checked, 64);
    assert!(
        matches!(report.outcome, EquivOutcome::Equivalent),
        "{report:?}"
    );
}

#[test]
fn whole_compiler_stack_leaf_proves_all_64_active_volatile_roundtrips() {
    compiler_fixture(
        include_str!("fixtures/device-private/stack-leaf.s"),
        include_str!("fixtures/device-private/stack-leaf.launch.json"),
        include_str!("fixtures/device-private/stack-leaf.spec"),
        1,
    );
}

#[test]
fn whole_compiler_nested_call_proves_all_64_outputs_without_abi_stubs() {
    compiler_fixture(
        include_str!("fixtures/device-private/stack-nested.s"),
        include_str!("fixtures/device-private/stack-nested.launch.json"),
        include_str!("fixtures/device-private/stack-nested.spec"),
        2,
    );
}
