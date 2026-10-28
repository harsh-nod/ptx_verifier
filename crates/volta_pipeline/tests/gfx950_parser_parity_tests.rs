//! Portable malformed-control obligations use legal native positive controls.
//! PTX BRKPT is modeled as a no-op; AMD S_TRAP enters an external handler and
//! deliberately aborts this verifier. Those target behaviors are not equated.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, EvalError, OutputsUnavailable, frontend};
use volta_graph::{AbortCause, Terminal};
use volta_graph_check::GraphConclusion;

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.text\n.globl k\n.p2align 8\n.type k,@function\nk:\n{body}\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_kernarg_size 0\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    )
}

fn assert_aborted_unsupported(body: &str) {
    let text = source(body);
    let module = frontend::parse(&text).expect("recognized legal native syntax");
    let checked = gfx950_common::check(&text, &module, Some("k"), AnalysisConfig::new((64, 1, 1)))
        .expect("native analysis starts");
    assert!(matches!(
        checked.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::Unsupported { .. }))
    ));
    assert!(matches!(
        checked.analysis.graph.terminal(),
        Terminal::Aborted {
            cause: AbortCause::Unsupported,
            ..
        }
    ));
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    assert!(checked.analysis.graph.validate().is_ok());
}

#[test]
fn canonical_native_endpgm_and_optional_encoded_immediate_complete() {
    for end in ["s_endpgm", "s_endpgm 0", "s_endpgm 65535"] {
        let text = source(end);
        let module = frontend::parse(&text).unwrap();
        let checked =
            gfx950_common::check(&text, &module, Some("k"), AnalysisConfig::new((64, 1, 1)))
                .unwrap();
        checked
            .analysis
            .symbolic_outputs()
            .expect("canonical native termination completes");
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    }
}

#[test]
fn malformed_termination_is_rejected_before_control_flow_or_exec_can_hide_it() {
    for malformed in [
        "s_endpgm 0, 1",
        "s_endpgm v0",
        "s_endpgm 65536",
        "s_endpgm clamp",
        "s_endpgm mystery:1",
    ] {
        for body in [
            format!("{malformed}"),
            format!("s_branch .Ldone\n{malformed}\n.Ldone:\ns_endpgm"),
            format!("s_mov_b64 exec, 0\n{malformed}\ns_endpgm"),
        ] {
            frontend::parse(&source(&body)).expect_err(&body);
        }
    }
}

#[test]
fn native_trap_ids_are_recognized_but_never_assume_a_returning_handler() {
    // ID0 is reserved by hardware; it is still an encoded8bit ID and cannot
    // acquire a successful handler assumption. No trap is run on a GPU here.
    for id in [0, 1, 255] {
        assert_aborted_unsupported(&format!("s_trap {id}\ns_endpgm"));
    }
}

#[test]
fn malformed_traps_are_rejected_even_when_unreachable_or_exec_is_zero() {
    for malformed in [
        "s_trap",
        "s_trap s0",
        "s_trap 1, 2",
        "s_trap 1 clamp",
        "s_trap 1 mystery:1",
        "s_trap 256",
        "s_trap -1",
    ] {
        for body in [
            format!("{malformed}\ns_endpgm"),
            format!("s_branch .Ldone\n{malformed}\n.Ldone:\ns_endpgm"),
            format!("s_mov_b64 exec, 0\n{malformed}\ns_endpgm"),
        ] {
            frontend::parse(&source(&body)).expect_err(&body);
        }
    }
}

#[test]
fn valid_text_directive_is_a_control_for_unknown_directive_rejection() {
    let good = source(".text\ns_endpgm");
    frontend::parse(&good).expect("ordinary native .text is accepted");
    for directive in [".unknown_directive", ".unknown_directive 1"] {
        let bad = source(&format!("{directive}\ns_endpgm"));
        frontend::parse(&bad).expect_err(directive);
    }
}

#[test]
fn native_wait_requires_its_own_counter_operand_grammar() {
    for wait in [
        "s_waitcnt 0",
        "s_waitcnt vmcnt(0)",
        "s_waitcnt vmcnt(0) lgkmcnt(0)",
    ] {
        let text = source(&format!("{wait}\ns_endpgm"));
        let module = frontend::parse(&text).expect("canonical native counter wait");
        let checked =
            gfx950_common::check(&text, &module, Some("k"), AnalysisConfig::new((64, 1, 1)))
                .unwrap();
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    }
    for body in [
        "s_waitcnt\ns_endpgm",
        "s_branch .Ldone\ns_waitcnt\n.Ldone:\ns_endpgm",
        "s_mov_b64 exec, 0\ns_waitcnt\ns_endpgm",
    ] {
        let error = frontend::parse(&source(body)).expect_err(body);
        assert!(
            error.message.contains("s_waitcnt") && error.message.contains("expects 1..=3 operands"),
            "{body}: {error}"
        );
    }
}

#[test]
fn recognized_unmodeled_lane_and_atomic_forms_withhold_native_certificates() {
    // Both forms are emitted by unchanged portable-f16.s and accepted by the
    // pinned assembler. Recognizing their syntax cannot certify their effects.
    for instruction in [
        "v_readlane_b32 s4, v1, s2",
        "global_atomic_add_f32 v1, v0, s[0:1]",
    ] {
        assert_aborted_unsupported(&format!("{instruction}\ns_endpgm"));
    }
}
