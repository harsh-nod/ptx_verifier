//! Selected CDNA4 scalar calls execute bounded helper code with shared state.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, analyze, frontend, ir, lower};
use volta_graph::{AmdEventKind, AmdRegisterFile, ProgramPoint};
use volta_graph_check::{GraphConclusion, check_graph};

fn body(name: &str, text: &str) -> String {
    format!(".type {name},@function\n{name}:\n{text}\n.size {name},.-{name}\n")
}
fn address(target: &str, pair: u16) -> String {
    format!(
        "s_getpc_b64 s[{pair}:{}]\ns_add_u32 s{pair},s{pair},{target}@rel32@lo+4\ns_addc_u32 s{},s{},{target}@rel32@hi+12\n",
        pair + 1,
        pair + 1,
        pair + 1
    )
}
fn call(target: &str, pair: u16, saved: u16) -> String {
    address(target, pair)
        + &format!(
            "s_swappc_b64 s[{saved}:{}],s[{pair}:{}]\n",
            saved + 1,
            pair + 1
        )
}
fn module(entry: &str, helpers: &str) -> String {
    format!(
        ".amdgcn_target \"gfx950\"\n.text\n{}{}\n.amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n",
        body("k", entry),
        helpers
    )
}
fn config(block: u32) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: u64::from(block),
        kind: ArrayKind::Output,
    }];
    config
}
fn store() -> &'static str {
    "s_mov_b32 s8,0x10000\ns_mov_b32 s9,0\nv_lshlrev_b32 v2,2,v0\nv_cvt_f32_u32 v1,v1\nglobal_store_dword v2,v1,s[8:9]\ns_endpgm"
}
fn run(source: &str, block: u32) -> volta_amdgpu_analysis::AnalysisResult {
    let m = frontend::parse(source).unwrap();
    let result = analyze(&m, Some("k"), config(block)).unwrap();
    result.graph().validate().unwrap();
    result
}
fn values(result: &volta_amdgpu_analysis::AnalysisResult, expected: f64, block: u32) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), block as usize);
    for index in 0..u64::from(block) {
        assert_eq!(
            outputs.arena.as_f64(outputs.element("out", index).unwrap()),
            Some(expected)
        );
    }
}

#[test]
fn aliasing_swappc_snapshots_target_and_keeps_source_pcs_and_roles() {
    let src = module(
        &(call("leaf", 0, 0) + store()),
        &body("leaf", "v_mov_b32 v1,7\ns_setpc_b64 s[0:1]"),
    );
    let parsed = frontend::parse(&src).unwrap();
    assert_eq!(parsed.functions.len(), 1);
    assert!(parsed.functions[0].refusal.is_none());
    let lowered = lower::lower_module_kernel(&parsed, "k").unwrap();
    let count = parsed.kernels[0].instructions.len();
    assert_eq!(lowered.functions[1].start, count);
    assert_eq!(lowered.call_targets[&3], count);
    assert!(matches!(
        lowered.instructions[3].operation(),
        ir::Operation::Call(_)
    ));
    assert!(matches!(
        lowered.instructions[count + 1].operation(),
        ir::Operation::Return(_)
    ));
    for (index, original) in parsed.kernels[0].instructions.iter().enumerate() {
        assert_eq!(lowered.instructions[index].span(), original.span);
        assert_eq!(lowered.instructions[index].mnemonic(), &original.mnemonic);
    }
    let result = run(&src, 65);
    values(&result, 7., 65);
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
    let events = result.graph().amd_events();
    let record = events
        .iter()
        .find(|record| result.graph().event(record.event).pc == Some(ProgramPoint(3)))
        .unwrap();
    let AmdEventKind::Instruction { reads, writes, .. } = &record.kind else {
        panic!("call instruction")
    };
    for index in [0, 1] {
        assert!(
            reads
                .iter()
                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
        );
        assert!(
            writes
                .iter()
                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
        );
    }
    // Return has no hidden memory drain: one real END wait per launched wave.
    assert_eq!(
        events
            .iter()
            .filter(|r| matches!(r.kind, AmdEventKind::Wait { .. }))
            .count(),
        2
    );
}

#[test]
fn nested_calls_share_registers_and_explicitly_preserve_the_outer_return() {
    let outer = "s_mov_b64 s[28:29],s[30:31]\n".to_string()
        + &call("leaf", 2, 30)
        + "s_mov_b64 s[30:31],s[28:29]\nv_add_u32 v1,3,v1\ns_setpc_b64 s[30:31]";
    let src = module(
        &(call("outer", 0, 30) + store()),
        &(body("outer", &outer) + &body("leaf", "v_mov_b32 v1,4\ns_setpc_b64 s[30:31]")),
    );
    let result = run(&src, 64);
    values(&result, 7., 64);
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
    let bad = src.replace("s_mov_b64 s[30:31],s[28:29]", "s_mov_b64 s[30:31],0");
    let stopped = run(&bad, 1);
    assert!(
        stopped
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("return address")
    );
}

#[test]
fn callee_changes_to_exec_and_flags_remain_visible_to_the_caller() {
    let helper = body(
        "leaf",
        "s_mov_b64 exec,0\ns_cmp_eq_u32 s8,s8\ns_setpc_b64 s[30:31]",
    );
    let src = module(
        &("s_mov_b32 s8,9\n".to_string()
            + &call("leaf", 0, 30)
            + "s_cbranch_scc0 .Lbad\ns_cbranch_execnz .Lbad\ns_mov_b64 exec,1\nv_mov_b32 v1,7\ns_branch .Lout\n.Lbad:\ns_mov_b64 exec,1\nv_mov_b32 v1,99\n.Lout:\n"
            + store()),
        &helper,
    );
    values(&run(&src, 1), 7., 1);
    let empty = module(
        &("s_mov_b64 exec,0\n".to_string()
            + &call("leaf", 0, 30)
            + "s_cbranch_scc0 .Lbad\ns_mov_b64 exec,1\nv_mov_b32 v1,7\ns_branch .Lout\n.Lbad:\ns_mov_b64 exec,1\nv_mov_b32 v1,99\n.Lout:\n"
            + store()),
        &body("leaf", "s_cmp_eq_u32 s30,s30\ns_setpc_b64 s[30:31]"),
    );
    // Code words cannot enter integer compares, even when EXEC is empty.
    assert!(run(&empty, 1).symbolic_outputs().is_err());
    let empty = module(
        &("s_mov_b64 exec,0\n".to_string()
            + &call("leaf", 0, 30)
            + "s_mov_b64 exec,1\nv_mov_b32 v1,s4\n"
            + store()),
        &body("leaf", "s_mov_b32 s4,7\ns_setpc_b64 s[30:31]"),
    );
    // Both scalar transfers and the callee's scalar write execute under EXEC=0.
    values(&run(&empty, 1), 7., 1);
}

#[test]
fn code_construction_does_not_invent_linker_carry_flags() {
    let src = module(
        &(call("leaf", 0, 30) + store()),
        &body(
            "leaf",
            "s_cbranch_scc1 .Lret\nv_mov_b32 v1,7\n.Lret:\ns_setpc_b64 s[30:31]",
        ),
    );
    assert!(
        run(&src, 1)
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("SCC")
    );
}

#[test]
fn scalar_load_readiness_is_shared_across_call_and_return_without_implicit_wait() {
    let prologue = "s_mov_b32 s8,0x20000\ns_mov_b32 s9,0\ns_load_dword s4,s[8:9],0\n";
    let src = module(
        &(prologue.to_string() + &call("leaf", 0, 30) + store()),
        &body("leaf", "v_mov_b32 v1,s4\ns_setpc_b64 s[30:31]"),
    );
    let parsed = frontend::parse(&src).unwrap();
    let mut cfg = config(1);
    cfg.arrays.push(ArrayDef {
        name: "x".into(),
        base: 0x20000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::IndexInput,
    });
    let bad = analyze(&parsed, Some("k"), cfg.clone()).unwrap();
    assert!(matches!(
        check_graph(bad.graph()).conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let good = src.replace("v_mov_b32 v1,s4", "s_waitcnt lgkmcnt(0)\nv_mov_b32 v1,s4");
    let good = analyze(&frontend::parse(&good).unwrap(), Some("k"), cfg).unwrap();
    values(&good, 0., 1);
    assert_eq!(
        check_graph(good.graph()).conclusion(),
        GraphConclusion::Verified
    );
    let helper = body("leaf", &(prologue.to_owned() + "s_setpc_b64 s[30:31]"));
    let source = module(
        &(call("leaf", 0, 30) + "v_mov_b32 v1,s4\n" + store()),
        &helper,
    );
    let mut cfg = config(1);
    cfg.arrays.push(ArrayDef {
        name: "x".into(),
        base: 0x20000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::IndexInput,
    });
    let bad = analyze(&frontend::parse(&source).unwrap(), Some("k"), cfg.clone()).unwrap();
    assert!(matches!(
        check_graph(bad.graph()).conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let waited = source.replace("v_mov_b32 v1,s4", "s_waitcnt lgkmcnt(0)\nv_mov_b32 v1,s4");
    let good = analyze(&frontend::parse(&waited).unwrap(), Some("k"), cfg).unwrap();
    values(&good, 0., 1);
    assert_eq!(
        check_graph(good.graph()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn code_pointer_data_and_mismatched_return_halves_are_refused() {
    for helper in [
        "s_mov_b32 s31,s30\ns_setpc_b64 s[30:31]",
        "s_mov_b32 s30,0\ns_setpc_b64 s[30:31]",
        "s_mov_b32 s8,0x10000\ns_mov_b32 s9,0\nv_mov_b32 v1,s30\nv_mov_b32 v2,0\nglobal_store_dword v2,v1,s[8:9]\ns_setpc_b64 s[30:31]",
    ] {
        let src = module(&(call("leaf", 0, 30) + store()), &body("leaf", helper));
        assert!(run(&src, 1).symbolic_outputs().is_err(), "{helper}");
    }
}

#[test]
fn calls_require_actual_reaching_definitions_and_local_function_bounds() {
    let leaf = body("leaf", "v_mov_b32 v1,7\ns_setpc_b64 s[30:31]");
    let good = call("leaf", 0, 30) + store();
    for bad in [
        good.replace("s_swappc_b64", "s_mov_b32 s0,0\ns_swappc_b64"),
        good.replace("s_swappc_b64", "s_branch .Lcall\n.Lcall:\ns_swappc_b64"),
        good.replace(
            "s_swappc_b64 s[30:31],s[0:1]",
            "s_swappc_b64 s[30:31],s[2:3]",
        ),
        good.replace("@hi+12", "@hi+8"),
        good.replace("leaf@rel32@hi", "other@rel32@hi"),
        good.replace("s_getpc_b64", "s_branch .Lmiddle\ns_getpc_b64")
            .replace("s_add_u32", ".Lmiddle:\ns_add_u32"),
    ] {
        let parsed = frontend::parse(&module(&bad, &leaf)).unwrap();
        assert!(lower::lower_module_kernel(&parsed, "k").is_err(), "{bad}");
    }
    for helper in [
        "s_branch k\ns_setpc_b64 s[30:31]",
        "v_mov_b32 v1,7",
        "s_endpgm",
    ] {
        let parsed = frontend::parse(&module(&good, &body("leaf", helper))).unwrap();
        assert!(
            lower::lower_module_kernel(&parsed, "k").is_err(),
            "{helper}"
        );
    }
}

#[test]
fn caller_constructed_names_cannot_alias_function_local_label_keys() {
    let src = module(
        &(call("leaf", 0, 30) + "s_branch .Lout\nv_mov_b32 v1,99\n.Lout:\n" + store()),
        &body("leaf", "v_mov_b32 v1,7\n.Lret:\ns_setpc_b64 s[30:31]"),
    );
    let mut parsed = frontend::parse(&src).unwrap();
    parsed.kernels[0].name = "a".into();
    parsed.kernels[0].labels = [("b::c".into(), 6)].into();
    parsed.kernels[0].instructions[4].operands[0] = frontend::Operand::Symbol("b::c".into());
    parsed.functions[0].name = "a::b".into();
    parsed.functions[0].labels = [("c".into(), 1)].into();
    for instruction in &mut parsed.kernels[0].instructions {
        for operand in &mut instruction.operands {
            if let frontend::Operand::Relocation(relocation) = operand {
                relocation.symbol = "a::b".into();
            }
        }
    }
    let lowered = lower::lower_module_kernel(&parsed, "a").unwrap();
    assert!(matches!(
        lowered.instructions[4].operation(),
        ir::Operation::Branch(ir::BranchInstruction { target: 6, .. })
    ));
    let result = analyze(&parsed, Some("a"), config(1)).unwrap();
    values(&result, 7., 1);
}

#[test]
fn recursive_calls_and_unreachable_unresolved_calls_fail_closed() {
    let src = module(
        &(call("leaf", 0, 30) + store()),
        &body("leaf", &(call("leaf", 2, 30) + "s_setpc_b64 s[30:31]")),
    );
    assert!(
        lower::lower_module_kernel(&frontend::parse(&src).unwrap(), "k")
            .unwrap_err()
            .message
            .contains("recursive")
    );
    let src = module(
        "s_branch .Ldone\ns_swappc_b64 s[30:31],s[0:1]\n.Ldone:\ns_endpgm",
        "",
    );
    assert!(lower::lower_module_kernel(&frontend::parse(&src).unwrap(), "k").is_err());
}

#[test]
fn unsupported_helpers_are_cataloged_but_never_executed_as_parsed_prefixes() {
    let helper = body(
        "leaf",
        "v_mov_b32 v1,7\nscratch_load_dword v0,off,s32\ns_setpc_b64 s[30:31]",
    );
    let uncalled = frontend::parse(&module("s_endpgm", &helper)).unwrap();
    assert!(uncalled.functions[0].refusal.is_some());
    assert!(uncalled.functions[0].instructions.is_empty());
    lower::lower_module_kernel(&uncalled, "k").unwrap();
    let called = frontend::parse(&module(&(call("leaf", 0, 30) + store()), &helper)).unwrap();
    assert!(
        lower::lower_module_kernel(&called, "k")
            .unwrap_err()
            .message
            .contains("called function")
    );
}

#[test]
fn target_and_direct_ast_call_shapes_are_checked_before_execution() {
    let src = module(
        &(call("leaf", 0, 30) + store()),
        &body("leaf", "v_mov_b32 v1,7\ns_setpc_b64 s[30:31]"),
    );
    assert!(frontend::parse(&src.replace("gfx950", "gfx942")).is_err());
    assert!(frontend::parse(&src.replace("gfx950", "gfx1250")).is_err());
    for instruction in [
        "s_swappc_b64 v[0:1],s[0:1]",
        "s_setpc_b64 s0",
        "s_setpc_b64 -1",
        "s_swappc_b64 s[30:31],s[0:1] glc",
    ] {
        assert!(
            frontend::parse(&module(&(instruction.to_owned() + "\ns_endpgm"), "")).is_err(),
            "{instruction}"
        );
    }
    let parsed = frontend::parse(&src).unwrap();
    for operands in [vec![], vec![frontend::Operand::Integer(0)]] {
        let mut forged = parsed.clone();
        forged.kernels[0].instructions[3].operands = operands;
        assert!(lower::lower_module_kernel(&forged, "k").is_err());
    }
}

#[test]
fn uncalled_helpers_do_not_change_no_call_executable_pcs() {
    let plain = module("s_branch .Lend\nv_mov_b32 v1,99\n.Lend:\ns_endpgm", "");
    let with_helper = plain.clone() + &body("unused", "v_mov_b32 v1,7\ns_setpc_b64 s[30:31]");
    let left = lower::lower_module_kernel(&frontend::parse(&plain).unwrap(), "k").unwrap();
    let right = lower::lower_module_kernel(&frontend::parse(&with_helper).unwrap(), "k").unwrap();
    assert_eq!(left.instructions, right.instructions);
    assert!(right.code_address_sequences.is_empty());
    assert_eq!(right.functions.len(), 1);
}

#[test]
fn complete_compiler_modules_retain_real_leaf_and_scratch_refusal() {
    const LEAF: &str = include_str!("fixtures/device-calls/leaf.s");
    const NESTED: &str = include_str!("fixtures/device-calls/nested.s");
    let leaf = frontend::parse(LEAF).unwrap();
    assert_eq!(leaf.source, LEAF);
    assert_eq!(leaf.kernels.len(), 1);
    assert_eq!(leaf.functions.len(), 1);
    let lowered = lower::lower_module_kernel(&leaf, "device_call_leaf").unwrap();
    assert_eq!(lowered.call_targets.len(), 1);
    assert!(
        lowered
            .instructions
            .iter()
            .any(|i| matches!(i.operation(), ir::Operation::Return(_)))
    );
    let mut cfg = config(1);
    cfg.params = vec![volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into())];
    let result = analyze(&leaf, Some("device_call_leaf"), cfg).unwrap();
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("uninitialized")
    );
    let nested = frontend::parse(NESTED).unwrap();
    assert_eq!(nested.source, NESTED);
    let outer = nested
        .functions
        .iter()
        .find(|function| function.name == "outer")
        .unwrap();
    assert!(
        outer
            .refusal
            .as_ref()
            .unwrap()
            .0
            .contains("scratch_store_dword")
    );
    assert!(
        lower::lower_module_kernel(&nested, "device_call_nested")
            .unwrap_err()
            .message
            .contains("called function `outer`")
    );
}
