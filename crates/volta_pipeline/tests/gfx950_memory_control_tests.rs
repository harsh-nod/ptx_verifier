//! Portable memory/control obligations exercised through native gfx950 execution
//! and the target-selected graph checker. These are assembly fixtures, not PTX
//! translations: AMD counters and workgroup barriers retain their own semantics.
mod gfx950_common;

use gfx950_common::Checked as Run;
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue, frontend,
};
use volta_expr::ExprNode;
use volta_graph::{Space, Terminal};
use volta_graph_check::amdgpu::AmdRegisterHazardKind;
use volta_graph_check::domain::ConflictKind;
use volta_graph_check::{GraphConclusion, PropertyResult};

fn source(body: &str, lds: u64) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl k
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v2, 2, v0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_group_segment_fixed_size {lds}
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .kernarg_segment_size: 16
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}

fn config(block: u32, len: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}

fn run_config(body: &str, lds: u64, config: AnalysisConfig) -> Run {
    run_target(body, lds, config, "gfx950")
}

fn run_target(body: &str, lds: u64, config: AnalysisConfig, target: &str) -> Run {
    let source = source(body, lds).replace("--gfx950\"", &format!("--{target}\""));
    let module = frontend::parse(&source).unwrap();
    let checked = gfx950_common::check(&source, &module, Some("k"), config).unwrap();
    assert!(checked.analysis.graph.validate().is_ok());
    checked
}

fn run(body: &str, lds: u64, block: u32) -> Run {
    run_config(body, lds, config(block, u64::from(block)))
}

fn assert_verified(run: &Run) {
    assert!(
        run.analysis.symbolic_outputs().is_ok(),
        "{:?}",
        run.analysis.symbolic_outputs()
    );
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks.amd
    );
}

fn assert_input_permutation(run: &Run, block: u32, partner: impl Fn(u64) -> u64) {
    assert_verified(run);
    let outputs = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), block as usize);
    for index in 0..u64::from(block) {
        let node = outputs.arena.node(outputs.element("out", index).unwrap());
        assert!(
            matches!(node, ExprNode::InputElement { array, index: found }
                if outputs.arena.string(*array) == "x" && *found == partner(index)),
            "out[{index}]: {node:?}"
        );
    }
}

fn assert_readiness(run: &Run, expected: AmdRegisterHazardKind) {
    assert!(run.analysis.symbolic_outputs().is_ok());
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let witnesses = run.checks.amd.as_ref().unwrap().wait_readiness.violations();
    assert!(
        witnesses.iter().any(|w| w.kind == expected),
        "{witnesses:?}"
    );
    assert!(witnesses.iter().all(|w| w.issue != w.use_event));
}

fn assert_shared_conflict(run: &Run, expected: ConflictKind) {
    assert!(run.analysis.symbolic_outputs().is_ok());
    let witnesses = run
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        witnesses
            .iter()
            .any(|w| w.kind == expected && w.location.space == Space::Shared),
        "{witnesses:?}"
    );
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
}

fn assert_invalid(run: &Run, fragment: &str) {
    match run.analysis.symbolic_outputs() {
        Err(OutputsUnavailable::Aborted(EvalError::Invalid { what, .. })) => {
            assert!(what.contains(fragment), "{what}");
        }
        other => panic!("expected typed invalid execution containing {fragment:?}: {other:?}"),
    }
    assert!(matches!(
        run.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

const EXCHANGE: &str = r#"
global_load_dword v5, v2, s[4:5]
s_waitcnt vmcnt(0)
ds_write_b32 v2, v5
s_waitcnt lgkmcnt(0)
s_barrier
v_xor_b32 v10, 256, v2
ds_read_b32 v8, v10
s_waitcnt lgkmcnt(0)
global_store_dword v2, v8, s[6:7]
"#;

#[test]
fn crosswave_lds_exchange_requires_waits_and_a_workgroup_barrier() {
    assert_input_permutation(&run(EXCHANGE, 512, 128), 128, |i| i ^ 64);

    let no_barrier = run(&EXCHANGE.replace("s_barrier", ""), 512, 128);
    assert_shared_conflict(&no_barrier, ConflictKind::WriteRead);

    for wait in ["", "s_waitcnt vmcnt(0)"] {
        let body = EXCHANGE.replacen(
            "s_waitcnt lgkmcnt(0)\ns_barrier",
            &format!("{wait}\ns_barrier"),
            1,
        );
        let missing_producer_wait = run(&body, 512, 128);
        assert_shared_conflict(&missing_producer_wait, ConflictKind::WriteRead);
    }
}

#[test]
fn a_wait_on_the_wrong_counter_does_not_make_a_register_ready() {
    for wait in ["", "s_waitcnt lgkmcnt(0)"] {
        let body = EXCHANGE.replacen("s_waitcnt vmcnt(0)", wait, 1);
        assert_readiness(
            &run(&body, 512, 128),
            AmdRegisterHazardKind::ReadBeforeReady,
        );
    }
    for wait in ["", "s_waitcnt vmcnt(0)"] {
        let body = EXCHANGE.replace(
            "ds_read_b32 v8, v10\ns_waitcnt lgkmcnt(0)",
            &format!("ds_read_b32 v8, v10\n{wait}"),
        );
        assert_readiness(
            &run(&body, 512, 128),
            AmdRegisterHazardKind::ReadBeforeReady,
        );
    }
}

#[test]
fn partial_vmcnt_only_retires_the_completed_load_prefix() {
    let body = r#"
global_load_dword v8, v2, s[4:5]
global_load_dword v9, v2, s[4:5]
s_waitcnt vmcnt(1)
global_store_dword v2, v8, s[6:7]
s_waitcnt vmcnt(0)
"#;
    assert_input_permutation(&run(body, 0, 64), 64, |i| i);
    let pending_second = body.replace("global_store_dword v2, v8", "global_store_dword v2, v9");
    assert_readiness(
        &run(&pending_second, 0, 64),
        AmdRegisterHazardKind::ReadBeforeReady,
    );
}

#[test]
fn partial_waves_participate_in_the_same_barrier_generation() {
    for block in [1_u32, 63, 64, 65, 96, 127, 128] {
        let body = format!(
            r#"
global_load_dword v5, v2, s[4:5]
s_waitcnt vmcnt(0)
ds_write_b32 v2, v5
s_waitcnt lgkmcnt(0)
s_barrier
v_xor_b32 v10, 64, v0
v_cmp_lt_u32 vcc, v10, {block}
v_cndmask_b32 v10, v0, v10, vcc
v_lshlrev_b32 v10, 2, v10
ds_read_b32 v8, v10
s_waitcnt lgkmcnt(0)
global_store_dword v2, v8, s[6:7]
"#
        );
        let result = run(&body, u64::from(block) * 4, block);
        assert_input_permutation(&result, block, |i| {
            if i ^ 64 < u64::from(block) { i ^ 64 } else { i }
        });
        match &result.checks.amd.as_ref().unwrap().barrier {
            PropertyResult::Pass(evidence) => {
                assert_eq!(evidence.generations, 1);
                assert_eq!(evidence.arrivals, block.div_ceil(64) as usize);
            }
            other => panic!("{other:?}"),
        }
    }
}

#[test]
fn scalar_barrier_participation_is_independent_of_empty_exec() {
    for empty_wave in ["", "v_cmp_lt_u32 vcc, v0, 64\ns_cbranch_vccz .Larrive"] {
        let barrier = format!(
            "s_mov_b64 s[8:9], exec\n{empty_wave}\ns_mov_b64 exec, 0\n.Larrive:\ns_barrier\ns_mov_b64 exec, s[8:9]"
        );
        let result = run(&EXCHANGE.replace("s_barrier", &barrier), 512, 128);
        assert_input_permutation(&result, 128, |i| i ^ 64);
        let mut arrivals: Vec<_> = result
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter_map(|e| {
                if let volta_graph::AmdEventKind::BarrierArrive { exec_mask, .. } = e.kind {
                    Some((e.wave, exec_mask))
                } else {
                    None
                }
            })
            .collect();
        arrivals.sort_by_key(|&(wave, _)| wave);
        assert_eq!(arrivals.len(), 2);
        assert_eq!(arrivals[0], (0, 0));
        assert_eq!(
            arrivals[1],
            (1, if empty_wave.is_empty() { 0 } else { u64::MAX })
        );
    }
}

#[test]
fn dynamic_lds_extends_the_static_region_with_exact_fit_bounds() {
    let body = "v_mov_b32 v10, 28\nv_add_u32 v8, 7, 0\nds_write_b32 v10, v8\ns_waitcnt lgkmcnt(0)\nds_read_b32 v8, v10\ns_waitcnt lgkmcnt(0)\nglobal_store_dword v2, v8, s[6:7]";
    for (static_bytes, dynamic_bytes) in [(16, 16), (0, 32), (32, 0)] {
        let mut cfg = config(1, 1);
        cfg.dynamic_shared_bytes = dynamic_bytes;
        let result = run_config(body, static_bytes, cfg);
        assert_verified(&result);
        let outputs = result.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 1);
        assert!(matches!(
            outputs.arena.node(outputs.element("out", 0).unwrap()),
            ExprNode::IntConst(7)
        ));
    }
    let mut too_small = config(1, 1);
    too_small.dynamic_shared_bytes = 12;
    assert_invalid(&run_config(body, 16, too_small), "out-of-bounds");
}

#[test]
fn compiler_static_and_dynamic_lds_share_bytes_through_flat_and_ds() {
    let source =
        include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-dynamic-lds.s");
    let module = frontend::parse(source).unwrap();
    let mut cfg = config(2, 2);
    cfg.arrays[0].len = 4;
    cfg.dynamic_shared_bytes = 8;
    let result = gfx950_common::check(source, &module, Some("dynamic_lds"), cfg.clone()).unwrap();
    assert_verified(&result);
    let outputs = result.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 2);
    for index in 0..2 {
        let ExprNode::Add(a, b) = outputs.arena.node(outputs.element("out", index).unwrap()) else {
            panic!("expected native static/dynamic LDS sum");
        };
        let mut inputs = [*a, *b].map(|id| match outputs.arena.node(id) {
            ExprNode::InputElement { array, index } if outputs.arena.string(*array) == "x" => {
                *index
            }
            other => panic!("unexpected input {other:?}"),
        });
        inputs.sort();
        assert_eq!(inputs, [1 - index, 3 - index]);
    }
    let graph = &result.analysis.graph;
    assert!(graph.amd_memory_effects().iter().any(|effect| {
        let volta_graph::EventKind::Access(access) = graph.event(effect.effect).kind else {
            return false;
        };
        let volta_graph::EventKind::Amd(record) = graph.event(effect.issue).kind else {
            return false;
        };
        graph.access(access).space == Space::Shared
            && effect.scope == volta_graph::AmdMemoryScope::Unspecified
            && matches!(
                graph.amd_event(record).unwrap().kind,
                volta_graph::AmdEventKind::MemoryIssue {
                    class: volta_graph::AmdMemoryClass::Flat,
                    ..
                }
            )
    }));
    for capacity in [0, 4, 7] {
        cfg.dynamic_shared_bytes = capacity;
        let too_small =
            gfx950_common::check(source, &module, Some("dynamic_lds"), cfg.clone()).unwrap();
        assert_invalid(&too_small, "out-of-bounds LDS");
    }
}

#[test]
fn byte_and_halfword_lds_roundtrips_preserve_symbolic_elements() {
    for (width, load, store, ds_write, ds_read) in [
        (
            1,
            "global_load_ubyte",
            "global_store_byte",
            "ds_write_b8",
            "ds_read_u8",
        ),
        (
            2,
            "global_load_ushort",
            "global_store_short",
            "ds_write_b16",
            "ds_read_u16",
        ),
    ] {
        let body = format!(
            "v_mul_lo_u32 v10, {width}, v0\n{load} v5, v10, s[4:5]\ns_waitcnt vmcnt(0)\n{ds_write} v10, v5\ns_waitcnt lgkmcnt(0)\n{ds_read} v8, v10\ns_waitcnt lgkmcnt(0)\n{store} v10, v8, s[6:7]"
        );
        let mut cfg = config(65, 65);
        for array in &mut cfg.arrays {
            array.elem_width = width;
        }
        assert_input_permutation(&run_config(&body, 65 * width, cfg), 65, |i| i);
    }
}

#[test]
fn ds_permute_and_its_completion_do_not_create_crosswave_memory_order() {
    let permute = "ds_bpermute_b32 v9, v2, v5\ns_waitcnt lgkmcnt(0)";
    let no_barrier = run(&EXCHANGE.replace("s_barrier", permute), 512, 128);
    assert_eq!(no_barrier.analysis.stats.warp_syncs, 2);
    assert_shared_conflict(&no_barrier, ConflictKind::WriteRead);
    let with_barrier = EXCHANGE.replace("s_barrier", &format!("{permute}\ns_barrier"));
    assert_input_permutation(&run(&with_barrier, 512, 128), 128, |i| i ^ 64);
}

#[test]
fn pending_load_destinations_cannot_be_reused_before_their_wait() {
    for wait in ["", "s_waitcnt vmcnt(0)"] {
        let result = run(
            &format!(
                "global_load_dword v8, v2, s[4:5]\n{wait}\nv_add_u32 v8, 0, 0\ns_waitcnt vmcnt(0)"
            ),
            0,
            64,
        );
        if wait.is_empty() {
            assert_readiness(&result, AmdRegisterHazardKind::DestinationReuse);
        } else {
            assert_verified(&result);
        }
    }
}

#[test]
fn wide_store_data_lifetime_uses_two_independent_states_not_full_completion() {
    for (delay, safe) in [
        ("", false),
        ("s_nop 0", false),
        ("s_nop 1", true),
        ("s_waitcnt vmcnt(0)", true),
    ] {
        let body = format!(
            "global_load_dwordx4 v[8:11], v2, s[4:5]\ns_waitcnt vmcnt(0)\nglobal_store_dwordx4 v2, v[8:11], s[6:7]\n{delay}\nv_add_u32 v8, 0, 0"
        );
        let result = run_config(&body, 0, config(1, 4));
        if safe {
            assert_input_permutation(&result, 4, |i| i);
        } else {
            assert_readiness(&result, AmdRegisterHazardKind::SourceReuse);
        }
    }
    // A one-DWORD GLOBAL store does not have the wide-store data hold.
    let narrow = "global_load_dword v8, v2, s[4:5]\ns_waitcnt vmcnt(0)\nglobal_store_dword v2, v8, s[6:7]\nv_add_u32 v8, 0, 0";
    assert_input_permutation(&run(narrow, 0, 64), 64, |i| i);
}

#[test]
fn terminated_waves_do_not_block_later_surviving_wave_generations() {
    for block in [65, 96, 128] {
        for empty_exec in ["", "s_mov_b64 exec, 0"] {
            let body = format!(
                "v_cmp_lt_u32 vcc, v0, 64\ns_cbranch_vccz .Lsurvive\n{empty_exec}\ns_endpgm\n.Lsurvive:\ns_barrier\ns_barrier\nv_add_u32 v8, v0, 0\nglobal_store_dword v2, v8, s[6:7]"
            );
            let result = run(&body, 0, block);
            assert_verified(&result);
            let outputs = result.analysis.symbolic_outputs().unwrap();
            assert_eq!(outputs.outputs[0].1.len(), (block - 64) as usize);
            for index in 64..u64::from(block) {
                assert!(
                    matches!(outputs.arena.node(outputs.element("out", index).unwrap()), ExprNode::IntConst(value) if *value == index as i64)
                );
            }
            match &result.checks.amd.as_ref().unwrap().barrier {
                PropertyResult::Pass(evidence) => {
                    assert_eq!(evidence.generations, 2);
                    assert_eq!(evidence.arrivals, 2);
                    assert_eq!(evidence.releases, 2);
                }
                other => panic!("{other:?}"),
            }
        }
    }
}

#[test]
fn endpgm_completes_pending_lds_but_a_survivor_still_needs_its_barrier() {
    // Four separate independent instructions ensure the candidate interpreter
    // visits the producer write before the negative control reads it. They do
    // not establish inter-wave ordering in the graph.
    let body = r#"
v_cmp_lt_u32 vcc, v0, 64
s_cbranch_vccz .Lsurvive
global_load_dword v5, v2, s[4:5]
s_waitcnt vmcnt(0)
ds_write_b32 v2, v5
s_endpgm
.Lsurvive:
s_nop 0
s_nop 0
s_nop 0
s_nop 0
{join}
v_xor_b32 v10, 256, v2
ds_read_b32 v8, v10
s_waitcnt lgkmcnt(0)
global_store_dword v2, v8, s[6:7]
"#;
    for block in [65, 96, 128] {
        let ordered = run(&body.replace("{join}", "s_barrier"), 256, block);
        assert_verified(&ordered);
        let outputs = ordered.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), (block - 64) as usize);
        for index in 64..u64::from(block) {
            assert!(
                matches!(outputs.arena.node(outputs.element("out", index).unwrap()), ExprNode::InputElement { index: found, .. } if *found == index - 64)
            );
        }
        let unordered = run(&body.replace("{join}", ""), 256, block);
        assert_shared_conflict(&unordered, ConflictKind::WriteRead);
    }
}

#[test]
fn a_live_wave_that_never_arrives_is_not_treated_as_terminated() {
    let body = "v_cmp_lt_u32 vcc, v0, 64\ns_cbranch_vccz .Lsurvive\n.Lspin:\ns_branch .Lspin\n.Lsurvive:\ns_barrier";
    let mut cfg = config(128, 128);
    cfg.max_instructions = 100;
    let result = run_config(body, 0, cfg);
    assert!(matches!(
        result.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::BudgetExceeded {
            limit: 100
        }))
    ));
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}

#[test]
fn matrix_result_readiness_uses_documented_states_not_memory_wait_counters() {
    // Selected SGEMM form has eight passes and a ten-state ordinary result
    // dependency (CDNA4 §7.6/Table38). Numeric zero inputs isolate readiness.
    for (delay, safe) in [
        ("", false),
        ("s_waitcnt vmcnt(0) lgkmcnt(0)", false),
        ("s_nop 8", false),
        ("s_nop 9", true),
    ] {
        let body = format!(
            "v_mov_b32 v8, 0\nv_mov_b32 v9, 0\ns_nop 1\nv_mfma_f32_16x16x4_f32 v[12:15], v8, v9, 0\n{delay}\nglobal_store_dword v2, v12, s[6:7]"
        );
        let result = run(&body, 0, 64);
        if safe {
            assert_verified(&result);
        } else {
            assert_readiness(&result, AmdRegisterHazardKind::MatrixReadBeforeReady);
        }
    }
}

#[test]
fn workgroup_scoped_global_publication_requires_scope_completion_and_rendezvous() {
    // CDNA4 §9.1.10.2/Table49-50 and LLVM SIGfx6CacheControl:
    // native GLOBAL SC0=1/SC1=0 supplies workgroup visibility. With TG_SPLIT
    // disabled the workgroup shares one CU/L1; waits and S_BARRIER still supply
    // completion and inter-wave ordering independently of those scope bits.
    for (store_scope, load_scope, producer_wait, barrier, consumer_wait, expected) in [
        (
            "sc0",
            "sc0",
            "s_waitcnt vmcnt(0)",
            "s_barrier",
            "s_waitcnt vmcnt(0)",
            "verified",
        ),
        (
            "",
            "sc0",
            "s_waitcnt vmcnt(0)",
            "s_barrier",
            "s_waitcnt vmcnt(0)",
            "unknown",
        ),
        (
            "sc0",
            "",
            "s_waitcnt vmcnt(0)",
            "s_barrier",
            "s_waitcnt vmcnt(0)",
            "unknown",
        ),
        (
            "sc0 sc1",
            "sc0",
            "s_waitcnt vmcnt(0)",
            "s_barrier",
            "s_waitcnt vmcnt(0)",
            "unknown",
        ),
        (
            "sc0",
            "sc0",
            "",
            "s_barrier",
            "s_waitcnt vmcnt(0)",
            "conflict",
        ),
        (
            "sc0",
            "sc0",
            "s_waitcnt vmcnt(0)",
            "",
            "s_waitcnt vmcnt(0)",
            "conflict",
        ),
        (
            "sc0",
            "sc0",
            "s_waitcnt vmcnt(0)",
            "s_barrier",
            "",
            "readiness",
        ),
    ] {
        let body = format!(
            "global_load_dword v5, v2, s[4:5]\ns_waitcnt vmcnt(0)\nv_mul_f32 v5, 2.0, v5\nglobal_store_dword v2, v5, s[4:5] {store_scope}\n{producer_wait}\n{barrier}\nv_xor_b32 v10, 256, v2\nglobal_load_dword v8, v10, s[4:5] {load_scope}\n{consumer_wait}\nglobal_store_dword v2, v8, s[6:7]"
        );
        let mut cfg = config(128, 128);
        cfg.arrays[0].kind = ArrayKind::InputOutput;
        let result = run_config(&body, 0, cfg);
        assert!(result.analysis.symbolic_outputs().is_ok());
        match expected {
            "verified" => {
                assert_verified(&result);
                assert!(
                    result
                        .analysis
                        .graph
                        .provenance()
                        .assumptions
                        .contains(&volta_graph::Assumption::SingleCuWorkgroup)
                );
                assert_eq!(
                    result
                        .analysis
                        .graph
                        .amd_memory_effects()
                        .iter()
                        .filter(|effect| effect.scope == volta_graph::AmdMemoryScope::Workgroup)
                        .count(),
                    256
                );
                let outputs = result.analysis.symbolic_outputs().unwrap();
                for (name, exchange) in [("x", false), ("out", true)] {
                    let elements = &outputs
                        .outputs
                        .iter()
                        .find(|(array, _)| array == name)
                        .unwrap()
                        .1;
                    assert_eq!(elements.len(), 128);
                    for &(index, expression) in elements {
                        let expected_index = if exchange { index ^ 64 } else { index };
                        let is_input = |id| matches!(outputs.arena.node(id), ExprNode::InputElement { array, index } if outputs.arena.string(*array) == "x" && *index == expected_index);
                        match outputs.arena.node(expression) {
                            ExprNode::Mul(a, b) => assert!(
                                (outputs.arena.as_f64(*a) == Some(2.0) && is_input(*b))
                                    || (outputs.arena.as_f64(*b) == Some(2.0) && is_input(*a))
                            ),
                            other => panic!(
                                "expected independent doubled input at {name}[{index}]: {other:?}"
                            ),
                        }
                    }
                }
            }
            "unknown" => {
                assert!(matches!(
                    result.checks.conclusion(),
                    GraphConclusion::Unknown { .. }
                ));
                assert!(matches!(
                    result.checks.amd.as_ref().unwrap().memory_conflict,
                    PropertyResult::Unknown(_)
                ));
            }
            "conflict" => {
                assert!(
                    result
                        .checks
                        .amd
                        .as_ref()
                        .unwrap()
                        .memory_conflict
                        .violations()
                        .iter()
                        .any(|w| w.kind == ConflictKind::WriteRead
                            && w.location.space == Space::Global)
                );
                assert!(matches!(
                    result.checks.conclusion(),
                    GraphConclusion::Rejected { .. }
                ));
            }
            "readiness" => assert_readiness(&result, AmdRegisterHazardKind::ReadBeforeReady),
            _ => unreachable!(),
        }
    }
}

#[test]
fn repeated_doublebuffer_generations_preserve_both_producer_and_consumer_order() {
    let body = r#"
global_load_dword v5, v2, s[4:5]
s_waitcnt vmcnt(0)
s_mov_b32 s8, 3
.Lrepeat:
v_and_b32 v10, 1, s8
v_lshlrev_b32 v10, 9, v10
v_add_u32 v10, v2, v10
ds_write_b32 v10, v5
s_waitcnt lgkmcnt(0)
s_barrier
v_xor_b32 v11, 256, v10
ds_read_b32 v8, v11
s_waitcnt lgkmcnt(0)
s_barrier
s_sub_u32 s8, s8, 1
s_cmp_eq_u32 s8, 0
s_cbranch_scc0 .Lrepeat
global_store_dword v2, v8, s[6:7]
"#;
    let result = run(body, 1024, 128);
    assert_input_permutation(&result, 128, |i| i ^ 64);
    let barrier = &result.checks.amd.as_ref().unwrap().barrier;
    match barrier {
        PropertyResult::Pass(evidence) => {
            assert_eq!(evidence.generations, 6);
            assert_eq!(evidence.arrivals, 12);
            assert_eq!(evidence.releases, 12);
        }
        other => panic!("{other:?}"),
    }

    // Reusing one buffer without joining its readers is a distinct generation
    // hazard, even though each producer generation still has a barrier.
    let single_buffer = body.replace("v_and_b32 v10, 1, s8", "v_mov_b32 v10, 0");
    assert_input_permutation(&run(&single_buffer, 512, 128), 128, |i| i ^ 64);
    let missing_consumer_join = single_buffer.replace(
        "s_waitcnt lgkmcnt(0)\ns_barrier\ns_sub_u32",
        "s_waitcnt lgkmcnt(0)\ns_sub_u32",
    );
    assert_shared_conflict(
        &run(&missing_consumer_join, 512, 128),
        ConflictKind::ReadWrite,
    );
}

#[test]
fn equal_value_writes_are_still_conflicting_effects() {
    let body = r#"
v_and_b32 v10, 63, v0
v_cmp_eq_u32 vcc, v10, 0
s_and_saveexec_b64 s[8:9], vcc
v_mov_b32 v11, 0
v_add_u32 v8, 7, 0
ds_write_b32 v11, v8
s_waitcnt lgkmcnt(0)
"#;
    assert_shared_conflict(&run(body, 8, 128), ConflictKind::WriteWrite);
    let disjoint = body.replace(
        "v_mov_b32 v11, 0",
        "v_lshrrev_b32 v11, 6, v0\nv_lshlrev_b32 v11, 2, v11",
    );
    assert_verified(&run(&disjoint, 8, 128));

    let ordered_same_address = r#"
v_mov_b32 v11, 0
v_add_u32 v8, 7, 0
v_cmp_eq_u32 vcc, v0, 0
s_and_saveexec_b64 s[8:9], vcc
ds_write_b32 v11, v8
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
s_barrier
v_cmp_eq_u32 vcc, v0, 64
s_and_saveexec_b64 s[8:9], vcc
ds_write_b32 v11, v8
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
"#;
    assert_verified(&run(ordered_same_address, 4, 128));
}

#[test]
fn equal_value_read_write_still_needs_a_completed_effect_barrier() {
    let body = r#"
v_mov_b32 v11, 0
v_add_u32 v8, 7, 0
v_cmp_eq_u32 vcc, v0, 0
s_and_saveexec_b64 s[8:9], vcc
ds_write_b32 v11, v8
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
s_barrier
v_cmp_lt_u32 vcc, v0, 64
s_cbranch_vccz .Lreader
v_cmp_eq_u32 vcc, v0, 0
s_and_saveexec_b64 s[8:9], vcc
ds_write_b32 v11, v8
s_waitcnt lgkmcnt(0)
s_mov_b64 exec, s[8:9]
.Lreader:
{join}
v_cmp_eq_u32 vcc, v0, 64
s_and_saveexec_b64 s[8:9], vcc
ds_read_b32 v8, v11
s_waitcnt lgkmcnt(0)
global_store_dword v2, v8, s[6:7]
"#;
    let ordered = run(&body.replace("{join}", "s_barrier"), 4, 128);
    assert_verified(&ordered);
    assert_eq!(
        ordered.analysis.symbolic_outputs().unwrap().outputs[0]
            .1
            .len(),
        1
    );
    let unordered = run(&body.replace("{join}", ""), 4, 128);
    assert_shared_conflict(&unordered, ConflictKind::WriteRead);
}

#[test]
fn uninitialized_scalar_vector_and_lds_reads_abort_with_typed_errors() {
    for (body, lds, text) in [
        ("v_mov_b32 v8, s8", 0, "uninitialized"),
        ("global_store_dword v2, v8, s[6:7]", 0, "uninitialized"),
        (
            "ds_read_b32 v8, v2\ns_waitcnt lgkmcnt(0)\nglobal_store_dword v2, v8, s[6:7]",
            256,
            "uninitialized",
        ),
        (
            "ds_read_b32 v8, v2\ns_waitcnt lgkmcnt(0)\nv_add_u32 v8, v8, 1\nglobal_store_dword v2, v8, s[6:7]",
            256,
            "uninitialized",
        ),
        (
            "v_mov_b32 v8, 0\nv_add_f64 v[10:11], v[8:9], 0",
            0,
            "uninitialized",
        ),
    ] {
        assert_invalid(&run(body, lds, 64), text);
    }
    assert_verified(&run(
        "s_mov_b32 s8, 3\nv_add_u32 v8, s8, 0\nglobal_store_dword v2, v8, s[6:7]",
        0,
        64,
    ));
    assert_verified(&run(
        "v_mov_b32 v8, 0\nv_mov_b32 v9, 0\nv_add_f64 v[10:11], v[8:9], 0",
        0,
        64,
    ));
    assert_verified(&run(
        "v_mov_b32 v8, 0\nds_write_b32 v2, v8\ns_waitcnt lgkmcnt(0)\nds_read_b32 v8, v2\ns_waitcnt lgkmcnt(0)",
        256,
        64,
    ));
}

#[test]
fn uninitialized_condition_cannot_choose_a_control_path() {
    let body = "s_cbranch_scc1 .Ldone\nv_mov_b32 v8, 7\n.Ldone:";
    assert_invalid(&run(body, 0, 64), "SCC");
    assert_verified(&run(&format!("s_cmp_eq_u32 s4, s4\n{body}"), 0, 64));
}

#[test]
fn initialized_bytes_and_halves_do_not_define_the_rest_of_a_word() {
    let partial_lds = "v_mov_b32 v10, 0\nv_mov_b32 v8, 0\nds_write_b16 v10, v8\ns_waitcnt lgkmcnt(0)\nds_read_b32 v9, v10\ns_waitcnt lgkmcnt(0)";
    assert_invalid(&run(partial_lds, 4, 1), "uninitialized byte");
    assert_verified(&run(
        &partial_lds.replace("ds_write_b16", "ds_write_b32"),
        4,
        1,
    ));

    let partial_vgpr = "v_fma_mixhi_f16 v8, 1.0, 2.0, 0.0\ns_nop 0\nv_cvt_f32_f16 v9, v8";
    let missing_low_half = run(partial_vgpr, 0, 1);
    assert!(matches!(
        missing_low_half.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::Unsupported { what, .. }))
            if what == "unknown half after partial register write"
    ));
    assert!(matches!(
        missing_low_half.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    assert_verified(&run(
        &format!("v_cvt_f16_f32 v8, 0.0\n{partial_vgpr}"),
        0,
        1,
    ));
}

#[test]
fn distinct_static_barrier_instructions_are_not_a_matching_rendezvous() {
    // CDNA4 §4.3 requires the other waves to reach the same instruction. This
    // tests that contract rather than importing PTX's numbered barrier IDs.
    let distinct = "v_cmp_lt_u32 vcc, v0, 64\ns_cbranch_vccz .Lsecond\ns_barrier\ns_branch .Ldone\n.Lsecond:\ns_barrier\n.Ldone:";
    let result = run(distinct, 0, 128);
    assert!(result.analysis.symbolic_outputs().is_ok());
    let witnesses = result.checks.amd.as_ref().unwrap().barrier.violations();
    assert!(
        witnesses
            .iter()
            .any(|w| w.reason == "waves reached different barrier instructions"),
        "{witnesses:?}"
    );
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));

    let common = "v_cmp_lt_u32 vcc, v0, 64\ns_cbranch_vccz .Lsecond\nv_mov_b32 v8, 0\ns_branch .Ljoin\n.Lsecond:\nv_mov_b32 v8, 1\n.Ljoin:\ns_barrier";
    assert_verified(&run(common, 0, 128));
}

#[test]
fn unaligned_ordinary_accesses_remain_outside_the_current_memory_model() {
    // This is an explicit verifier restriction, not a claim that all AMD memory
    // instruction families trap on unaligned addresses. In particular, SMEM
    // low address bits and scratch accesses have different native rules.
    for body in [
        "v_mov_b32 v10, 2\nglobal_load_dword v8, v10, s[4:5]\ns_waitcnt vmcnt(0)",
        "v_mov_b32 v10, 2\nv_add_u32 v8, 7, 0\nglobal_store_dword v10, v8, s[6:7]",
        "v_mov_b32 v10, 2\nv_mov_b32 v8, 0\nds_write_b32 v10, v8\ns_waitcnt lgkmcnt(0)",
    ] {
        assert_invalid(&run_config(body, 8, config(1, 2)), "misaligned access");
        assert_verified(&run_config(
            &body.replace("v10, 2", "v10, 0"),
            8,
            config(1, 2),
        ));
    }
}

#[test]
fn smem_clause_address_sources_cannot_be_overwritten_except_isolated_dword() {
    // CDNA4 §8.2.1.1: replay of a scalar-memory clause must see its original
    // address sources. A single-DWORD, one-instruction clause is the exception.
    for body in [
        "s_load_dwordx2 s[4:5], s[4:5], 0\ns_waitcnt lgkmcnt(0)",
        "s_load_dword s4, s[4:5], 0\ns_load_dword s8, s[4:5], 0\ns_waitcnt lgkmcnt(0)",
        "s_load_dword s8, s[4:5], 0\ns_load_dword s12, s[8:9], 0\ns_waitcnt lgkmcnt(0)",
        "s_mov_b32 s8, 0\ns_load_dwordx2 s[8:9], s[4:5], s8\ns_waitcnt lgkmcnt(0)",
    ] {
        let result = run_target(body, 0, config(64, 64), "gfx950:xnack+");
        assert!(
            matches!(
                result.analysis.symbolic_outputs(),
                Err(OutputsUnavailable::Aborted(EvalError::Unsupported { what, .. }))
                    if what.starts_with("SMEM clause destination") && what.contains("overlaps an address source")
            ),
            "{:?}",
            result.analysis.symbolic_outputs()
        );
        assert!(matches!(
            result.checks.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
    }
    for body in [
        "s_load_dword s4, s[4:5], 0\ns_waitcnt lgkmcnt(0)",
        "s_load_dwordx2 s[8:9], s[4:5], 0\ns_waitcnt lgkmcnt(0)",
        "s_load_dword s8, s[4:5], 0\ns_load_dword s9, s[4:5], 4\ns_waitcnt lgkmcnt(0)",
    ] {
        assert_verified(&run_target(body, 0, config(64, 64), "gfx950:xnack+"));
    }

    // The replay hazard does not apply to the modeled xnack- execution. Generic
    // code is scoped to that mode by an explicit assumption; an explicit +
    // target retains the stricter alias guard above.
    let self_alias = "s_load_dwordx2 s[4:5], s[4:5], 0\ns_waitcnt lgkmcnt(0)";
    for target in ["gfx950", "gfx950:xnack-"] {
        let result = run_target(self_alias, 0, config(64, 64), target);
        assert_verified(&result);
        assert!(
            result
                .analysis
                .graph
                .provenance()
                .assumptions
                .contains(&volta_graph::Assumption::XnackReplayDisabled)
        );
        assert_eq!(result.analysis.graph.provenance().targets, [target]);
    }
    let replay = run_target(
        "s_load_dword s4, s[4:5], 0\ns_waitcnt lgkmcnt(0)",
        0,
        config(64, 64),
        "gfx950:xnack+",
    );
    assert!(
        !replay
            .analysis
            .graph
            .provenance()
            .assumptions
            .contains(&volta_graph::Assumption::XnackReplayDisabled)
    );
}

#[test]
fn exact_fit_and_wrapped_lds_addresses_have_explicit_allocation_boundaries() {
    // The verifier diagnoses allocation violations even where physical LDS
    // out-of-range hardware semantics discard writes or return zero.
    let body = "v_mov_b32 v8, 7\nv_mov_b32 v10, 252\nds_write_b32 v10, v8\ns_waitcnt lgkmcnt(0)\nds_read_b32 v8, v10\ns_waitcnt lgkmcnt(0)";
    assert_verified(&run(body, 256, 1));
    assert_invalid(
        &run(&body.replace("v10, 252", "v10, 256"), 256, 1),
        "out-of-bounds",
    );

    let wrapped = "v_mov_b32 v8, 7\nv_mov_b32 v10, -64\nds_write_b32 v10, v8 offset:64\ns_waitcnt lgkmcnt(0)\nds_read_b32 v8, v10 offset:64\ns_waitcnt lgkmcnt(0)";
    assert_verified(&run(wrapped, 4, 1));
    assert_invalid(
        &run(&wrapped.replace(" offset:64", ""), 4, 1),
        "out-of-bounds",
    );
}

#[test]
fn exact_fit_global_transfers_and_negative_offsets_respect_arrays() {
    let body =
        "global_load_dword v8, v2, s[4:5]\ns_waitcnt vmcnt(0)\nglobal_store_dword v2, v8, s[6:7]";
    assert_input_permutation(&run(body, 0, 64), 64, |i| i);
    let overflow = body.replace(
        "global_load_dword v8, v2, s[4:5]",
        "global_load_dword v8, v2, s[4:5] offset:4",
    );
    assert_invalid(&run(&overflow, 0, 64), "out-of-bounds");
    let underflow = body.replace(
        "global_load_dword v8, v2, s[4:5]",
        "global_load_dword v8, v2, s[4:5] offset:-4",
    );
    assert_invalid(&run(&underflow, 0, 64), "out-of-bounds");
    let wrapped_index = body.replace(
        "global_load_dword v8, v2, s[4:5]",
        "v_sub_u32 v10, v0, 1\nv_lshlrev_b32 v10, 2, v10\nglobal_load_dword v8, v10, s[4:5]",
    );
    assert_invalid(&run(&wrapped_index, 0, 64), "out-of-bounds");
}

#[test]
fn vector_transfers_check_every_component_at_the_region_end() {
    let global = "global_load_dwordx4 v[8:11], v2, s[4:5]\ns_waitcnt vmcnt(0)\nglobal_store_dwordx4 v2, v[8:11], s[6:7]";
    assert_input_permutation(&run_config(global, 0, config(1, 4)), 4, |i| i);
    assert_invalid(&run_config(global, 0, config(1, 3)), "out-of-bounds");

    let lds = "v_mov_b32 v10, 240\nv_mov_b32 v8, 0\nv_mov_b32 v9, 0\nv_mov_b32 v11, 0\nv_mov_b32 v12, 0\nds_write_b128 v10, v[8:11]\ns_waitcnt lgkmcnt(0)\nds_read_b128 v[12:15], v10\ns_waitcnt lgkmcnt(0)";
    assert_verified(&run(lds, 256, 1));
    assert_invalid(
        &run(&lds.replace("v10, 240", "v10, 244"), 256, 1),
        "out-of-bounds",
    );
}

#[test]
fn incomplete_execution_never_receives_a_verified_graph() {
    let mut cfg = config(64, 64);
    cfg.max_instructions = 20;
    let result = run_config(".Lforever:\ns_branch .Lforever", 0, cfg);
    assert!(matches!(
        result.analysis.symbolic_outputs(),
        Err(OutputsUnavailable::Aborted(EvalError::BudgetExceeded {
            limit: 20
        }))
    ));
    assert!(matches!(
        result.analysis.graph.terminal(),
        Terminal::Aborted { .. }
    ));
    assert!(matches!(
        result.checks.conclusion(),
        GraphConclusion::Unknown { .. }
    ));
}
