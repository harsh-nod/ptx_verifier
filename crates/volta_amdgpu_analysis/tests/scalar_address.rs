//! Concrete CDNA scalar comparisons and sealed aperture-word identity controls.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend, lower,
};
use volta_graph::{AmdEventKind, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const TARGETS: [&str; 3] = ["gfx942", "gfx950", "gfx1250"];
const LEGACY: [&str; 2] = ["gfx942", "gfx950"];

fn source(target: &str, body: &str) -> String {
    let (load, wait, add, store, finish, descriptor) = if target == "gfx1250" {
        (
            "s_load_b64",
            "s_wait_kmcnt 0",
            "v_add_nc_u32",
            "global_store_b32",
            "s_wait_storecnt 0\ns_wait_xcnt 0",
            ".amdhsa_wavefront_size32 1",
        )
    } else {
        (
            "s_load_dwordx2",
            "s_waitcnt lgkmcnt(0)",
            "v_add_u32",
            "global_store_dword",
            "s_waitcnt vmcnt(0)",
            "",
        )
    };
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
{load} s[4:5],s[0:1],0
{wait}
s_mov_b32 s8,123
s_mov_b32 s9,456
{body}
s_cselect_b32 s16,1,0
v_mov_b32 v0,0
v_mov_b32 v1,s8
v_mov_b32 v2,s9
v_mov_b32 v3,s16
{add} v1,0,v1
{add} v2,0,v2
{add} v3,0,v3
{store} v0,v1,s[4:5]
{finish}
{store} v0,v2,s[4:5] offset:4
{finish}
{store} v0,v3,s[4:5] offset:8
{finish}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 24
{descriptor}
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
      - .name: words
        .offset: 8
        .size: 16
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    )
}

fn config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 3,
        kind: ArrayKind::Output,
    });
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Bytes(vec![0; 16]),
    ];
    config
}

fn execute(module: &frontend::Module, config: AnalysisConfig) -> AnalysisResult {
    let result = analyze(module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn run(target: &str, body: &str) -> AnalysisResult {
    execute(&frontend::parse(&source(target, body)).unwrap(), config())
}

fn words(result: &AnalysisResult, expected: [u32; 3]) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 3);
    for (index, expected) in expected.into_iter().enumerate() {
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index as u64).unwrap()),
            Some(i64::from(expected))
        );
    }
}

fn verified(target: &str, body: &str, expected: bool) {
    let result = run(target, body);
    words(&result, [123, 456, u32::from(expected)]);
    let safety = check_graph(result.graph());
    assert_eq!(
        safety.conclusion(),
        GraphConclusion::Verified,
        "{target}: {body}\n{safety:#?}"
    );
}

fn refused(target: &str, body: &str, expected: &str) {
    let result = run(target, body);
    let error = result.symbolic_outputs().unwrap_err().to_string();
    assert!(error.contains(expected), "{target}: {body}\n{error}");
    assert_ne!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
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
fn full_64bit_truth_table_distinguishes_high_words_and_preserves_sources() {
    for target in TARGETS {
        for (a, b) in [
            (0, 0),
            (7, 7),
            (7, (1u64 << 32) | 7),
            (0, 1u64 << 63),
            (u64::MAX, u64::MAX),
            (u64::MAX, u64::from(u32::MAX)),
            (0x1234_5678_9abc_def0, 0x1234_5678_9abc_def1),
        ] {
            for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
                for sources in ["s[6:7],s[12:13]", "s[12:13],s[6:7]"] {
                    verified(
                        target,
                        &format!("{}\n{}\n{name} {sources}", pair(6, a), pair(12, b)),
                        (a == b) == (name == "s_cmp_eq_u64"),
                    );
                }
            }
        }
        verified(
            target,
            "s_mov_b64 s[100:101],7\ns_cmp_eq_u64 s[100:101],7",
            true,
        );
    }
}

#[test]
fn integer_inline_bounds_are_sign_extended_in_both_source_positions() {
    for target in TARGETS {
        for immediate in [-16i64, -1, 0, 1, 64] {
            for same in [false, true] {
                let value = (immediate as u64) ^ if same { 0 } else { 1u64 << 32 };
                for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
                    for sources in [format!("s[6:7],{immediate}"), format!("{immediate},s[6:7]")] {
                        verified(
                            target,
                            &format!("{}\n{name} {sources}", pair(6, value)),
                            same == (name == "s_cmp_eq_u64"),
                        );
                    }
                }
            }
        }
        verified(target, "s_cmp_eq_u64 -1,-1", true);
        verified(target, "s_cmp_lg_u64 -16,64", true);
    }
}

#[test]
fn scalar_result_controls_branch_and_cselect_independently_of_exec() {
    for target in LEGACY {
        for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            for exec in ["0", "5", "-1"] {
                let module = frontend::parse(&source(
                    target,
                    &format!(
                        "s_mov_b32 vcc_lo,85\ns_mov_b32 vcc_hi,170\ns_mov_b64 s[6:7],1\ns_cmp_eq_u32 0,0\ns_mov_b64 exec,{exec}\n{name} s[6:7],-1\ns_mov_b64 exec,1\ns_cbranch_scc1 .Ltrue\ns_mov_b32 s8,85\ns_branch .Ldone\n.Ltrue:\ns_mov_b32 s8,170\n.Ldone:\ns_mov_b32 s9,vcc_hi"
                    ),
                )).unwrap();
                // All tested EXEC bits belong to real launched threads; only
                // lane0 is restored for the three scalar-result stores.
                let mut launch = config();
                launch.block_dim = (64, 1, 1);
                let result = execute(&module, launch);
                let expected = name == "s_cmp_lg_u64";
                words(
                    &result,
                    [if expected { 170 } else { 85 }, 170, u32::from(expected)],
                );
                assert_eq!(
                    check_graph(result.graph()).conclusion(),
                    GraphConclusion::Verified
                );
                let compare = result
                    .graph()
                    .amd_events()
                    .iter()
                    .find_map(|record| match &record.kind {
                        AmdEventKind::Instruction {
                            reads,
                            writes,
                            exec_mask,
                            ..
                        } if reads.iter().any(|r| r.index == 6)
                            && reads.iter().any(|r| r.index == 7)
                            && writes.is_empty() =>
                        {
                            Some((reads, exec_mask))
                        }
                        _ => None,
                    })
                    .unwrap();
                assert_eq!(
                    *compare.1,
                    match exec {
                        "0" => 0,
                        "5" => 5,
                        _ => u64::MAX,
                    }
                );
                assert!(
                    compare
                        .0
                        .iter()
                        .all(|r| r.file == AmdRegisterFile::Scalar && r.lanes == u64::MAX)
                );
            }
        }
    }
}

#[test]
fn comparison_refuses_missing_words_and_unsupported_source_values() {
    for target in TARGETS {
        for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            for initialized in [6, 7] {
                refused(
                    target,
                    &format!("s_mov_b32 s{initialized},0\n{name} s[6:7],s[6:7]"),
                    "uninitialized Scalar register",
                );
            }
            refused(
                target,
                &format!("s_mov_b64 s[6:7],0\ns_mov_b32 s12,1\n{name} s[6:7],s[12:13]"),
                "uninitialized Scalar register 13",
            );
            refused(
                target,
                &format!("s_mov_b64 s[6:7],src_shared_base\n{name} s[6:7],s[6:7]"),
                "opaque shared aperture",
            );
            for value in ["0.5", "65", "-17", "0xffffffff", "exec"] {
                refused(
                    target,
                    &format!("s_mov_b64 s[6:7],0\n{name} s[6:7],{value}"),
                    "requires SGPR pairs or integer inline constants",
                );
            }
        }
    }
}

#[test]
fn malformed_text_and_direct_ast_cannot_bypass_register_shape_checks() {
    for target in TARGETS {
        for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            for bad in ["s6", "s[7:8]", "s[6:9]", "v[6:7]", "-s[6:7]"] {
                assert!(frontend::parse(&source(target, &format!("{name} {bad},0"))).is_err());
            }
            for (index, count) in [(7, 2), (6, 1), (8, 4), (102, 2)] {
                if target == "gfx1250" && index == 102 {
                    continue;
                }
                let mut module =
                    frontend::parse(&source(target, &format!("{name} s[6:7],0"))).unwrap();
                let instruction = module.kernels[0]
                    .instructions
                    .iter_mut()
                    .find(|i| i.mnemonic == name)
                    .unwrap();
                instruction.operands[0] = frontend::Operand::Register(frontend::Register {
                    class: frontend::RegisterClass::Scalar,
                    index,
                    count,
                    special: None,
                });
                assert!(lower::lower_module_kernel(&module, "k").is_err());
            }
        }
    }
}

#[test]
fn every_source_word_retains_its_independent_lgkm_readiness_obligation() {
    for target in LEGACY {
        for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            for index in [6, 7, 12, 13] {
                for wait in ["", "s_waitcnt vmcnt(0)", "s_waitcnt lgkmcnt(0)"] {
                    let module=frontend::parse(&source(target,&format!(
                        "s_mov_b64 s[6:7],0\ns_mov_b64 s[12:13],0\ns_load_dword s{index},s[0:1],8\n{wait}\n{name} s[6:7],s[12:13]"))).unwrap();
                    let mut config = config();
                    let mut bytes = vec![0; 16];
                    bytes[0] = 1;
                    config.params[1] = ParamValue::Bytes(bytes);
                    let result = execute(&module, config);
                    words(&result, [123, 456, u32::from(name == "s_cmp_lg_u64")]);
                    let report = check_graph(result.graph());
                    assert_eq!(
                        report.verdict(Property::AmdWaitReadiness),
                        if wait.contains("lgkmcnt") {
                            Verdict::Pass
                        } else {
                            Verdict::Fail
                        }
                    );
                    if !wait.contains("lgkmcnt") {
                        assert!(
                            report
                                .amd
                                .as_ref()
                                .unwrap()
                                .wait_readiness
                                .violations()
                                .iter()
                                .any(|hazard| hazard.register.file == AmdRegisterFile::Scalar
                                    && hazard.register.index == index)
                        );
                    } else {
                        assert_eq!(report.conclusion(), GraphConclusion::Verified);
                    }
                }
            }
        }
    }
}

#[test]
fn legacy_aperture_addc_transports_only_zero_with_carry_zero() {
    for target in LEGACY {
        for sources in ["s19,0", "0,s19", "s19,s12", "s12,s19"] {
            for destination in [12, 19, 20] {
                verified(
                    target,
                    &format!(
                        "s_mov_b64 s[18:19],src_shared_base\ns_mov_b32 s12,0\ns_cmp_eq_u32 0,1\ns_mov_b64 exec,0\ns_addc_u32 s{destination},{sources}\ns_mov_b64 exec,1"
                    ),
                    false,
                );
            }
        }
        for (setup, tail, error) in [
            ("s_cmp_eq_u32 0,0", "s_addc_u32 s20,s19,0", "carry-in zero"),
            ("s_cmp_eq_u32 0,1", "s_addc_u32 s20,s19,1", "concrete zero"),
            (
                "s_cmp_eq_u32 0,1",
                "s_addc_u32 s20,s19,s19",
                "concrete zero",
            ),
            (
                "s_cmp_eq_u32 0,1",
                "s_addc_u32 s20,s19,0.0",
                "concrete zero",
            ),
            (
                "s_cmp_eq_u32 0,1",
                "s_addc_u32 exec_lo,s19,0",
                "plain SGPR destination",
            ),
            (
                "s_cmp_eq_u32 0,1",
                "s_addc_u32 s20,s19,0\ns_cmp_eq_u32 s20,0",
                "opaque shared aperture",
            ),
            (
                "s_cmp_eq_u32 0,1",
                "s_addc_u32 s20,s19,0\ns_mov_b32 exec_lo,s20",
                "opaque shared aperture",
            ),
        ] {
            refused(
                target,
                &format!("s_mov_b64 s[18:19],src_shared_base\n{setup}\n{tail}"),
                error,
            );
        }
        refused(
            target,
            "s_mov_b64 s[18:19],src_shared_base\ns_addc_u32 s20,s19,0",
            "uninitialized SCC",
        );
    }
}

#[test]
fn aperture_identity_keeps_pending_zero_word_reads_visible_to_the_checker() {
    for target in LEGACY {
        for sources in ["s19,s12", "s12,s19"] {
            for wait in ["", "s_waitcnt vmcnt(0)", "s_waitcnt lgkmcnt(0)"] {
                let result = run(
                    target,
                    &format!(
                        "s_mov_b64 s[18:19],src_shared_base\ns_load_dword s12,s[0:1],8\n{wait}\ns_cmp_eq_u32 0,1\ns_addc_u32 s20,{sources}"
                    ),
                );
                words(&result, [123, 456, 0]);
                let report = check_graph(result.graph());
                assert_eq!(
                    report.verdict(Property::AmdWaitReadiness),
                    if wait.contains("lgkmcnt") {
                        Verdict::Pass
                    } else {
                        Verdict::Fail
                    }
                );
                if !wait.contains("lgkmcnt") {
                    assert!(
                        report
                            .amd
                            .as_ref()
                            .unwrap()
                            .wait_readiness
                            .violations()
                            .iter()
                            .any(|hazard| hazard.register.file == AmdRegisterFile::Scalar
                                && hazard.register.index == 12)
                    );
                }
            }
        }
    }
}
