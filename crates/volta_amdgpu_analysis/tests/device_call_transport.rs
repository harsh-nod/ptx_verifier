//! Compiler lane spills preserve opaque code-word identity, never data bits.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, analyze, frontend, lower};
use volta_graph_check::{GraphConclusion, check_graph};

fn address(target: &str, pair: u16) -> String {
    format!(
        "s_getpc_b64 s[{pair}:{}]\ns_add_u32 s{pair},s{pair},{target}@rel32@lo+4\ns_addc_u32 s{},s{},{target}@rel32@hi+12\n",
        pair + 1,
        pair + 1,
        pair + 1
    )
}
fn module(entry: &str, helper: &str) -> String {
    format!(
        ".amdgcn_target \"gfx950\"\n.text\n.type k,@function\nk:\n{entry}\n.size k,.-k\n.type leaf,@function\nleaf:\n{helper}\ns_setpc_b64 s[30:31]\n.size leaf,.-leaf\n.amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    )
}
fn spill() -> &'static str {
    "v_writelane_b32 v47,s0,38\ns_nop 1\nv_writelane_b32 v47,s1,39\n"
}
fn restore() -> &'static str {
    "v_readlane_b32 s0,v47,38\nv_readlane_b32 s1,v47,39\n"
}
fn call() -> &'static str {
    "s_swappc_b64 s[30:31],s[0:1]\n"
}
fn store() -> &'static str {
    "s_mov_b32 s8,0x10000\ns_mov_b32 s9,0\nv_lshlrev_b32 v2,2,v0\nv_cvt_f32_u32 v1,v1\nglobal_store_dword v2,v1,s[8:9]\ns_endpgm"
}
fn repeated() -> String {
    address("leaf", 0) + spill() + call() + "s_mov_b64 s[0:1],0\n" + restore() + call() + store()
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
fn accepted(entry: &str, helper: &str) {
    let parsed = frontend::parse(&module(entry, helper)).unwrap();
    let result = analyze(&parsed, Some("k"), config(64)).unwrap();
    result.graph().validate().unwrap();
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 64);
    for index in 0..64 {
        assert_eq!(
            outputs.arena.as_f64(outputs.element("out", index).unwrap()),
            Some(7.)
        );
    }
}
fn refused(entry: &str, helper: &str) {
    let parsed = frontend::parse(&module(entry, helper)).unwrap();
    assert!(
        lower::lower_module_kernel(&parsed, "k").is_err(),
        "{entry}\n{helper}"
    );
}

#[test]
fn compiler_spills_restore_targets_after_calls_without_assuming_callee_preservation() {
    accepted(&repeated(), "s_mov_b64 s[0:1],0\nv_mov_b32 v1,7");
    // Same saved-PC and call-target pair: the target is snapshotted before the
    // return address is written. A later lane reload restores the actual target.
    let aliased = repeated().replace("s_swappc_b64 s[30:31]", "s_swappc_b64 s[0:1]");
    let src =
        module(&aliased, "v_mov_b32 v1,7").replace("s_setpc_b64 s[30:31]", "s_setpc_b64 s[0:1]");
    let parsed = frontend::parse(&src).unwrap();
    let result = analyze(&parsed, Some("k"), config(64)).unwrap();
    assert!(result.symbolic_outputs().is_ok());
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
}

#[test]
fn independent_lane_writes_and_scalar_copy_snapshots_preserve_exact_words() {
    let unrelated = repeated().replace(
        call(),
        &("s_mov_b32 s6,123\nv_writelane_b32 v47,s6,40\n".to_owned() + call()),
    );
    accepted(&unrelated, "v_mov_b32 v1,7");
    let scalar = address("leaf", 0)
        + "s_mov_b64 s[2:3],s[0:1]\ns_mov_b64 s[0:1],0\ns_mov_b64 s[0:1],s[2:3]\n"
        + call()
        + store();
    accepted(&scalar, "v_mov_b32 v1,7");
    let ordered = address("leaf", 0)
        + "s_mov_b32 s2,s0\ns_mov_b32 s3,s1\ns_mov_b64 s[0:1],0\ns_mov_b32 s0,s2\ns_mov_b32 s1,s3\n"
        + call()
        + store();
    accepted(&ordered, "v_mov_b32 v1,7");
}

#[test]
fn overwritten_or_unproved_transport_words_and_pair_aliases_are_refused() {
    for insertion in [
        "s_mov_b32 s6,0\nv_writelane_b32 v47,s6,38\n",
        "s_mov_b32 s6,0\nv_writelane_b32 v47,s6,39\n",
        "v_mov_b32 v47,0\n",
    ] {
        refused(
            &(address("leaf", 0)
                + spill()
                + insertion
                + "s_mov_b64 s[0:1],0\n"
                + restore()
                + call()
                + store()),
            "v_mov_b32 v1,7",
        );
    }
    refused(
        &(address("leaf", 0) + "s_mov_b64 s[0:1],0\n" + restore() + call() + store()),
        "v_mov_b32 v1,7",
    );
    refused(
        &repeated()
            .replace("s0,v47,38", "s0,v47,39")
            .replace("s1,v47,39", "s1,v47,38"),
        "v_mov_b32 v1,7",
    );
    refused(
        &(address("leaf", 0) + "s_mov_b64 s[2:3],s[0:1]\ns_swappc_b64 s[30:31],s[2:3]\n" + store()),
        "v_mov_b32 v1,7",
    );
    refused(
        &repeated()
            .replace("s_mov_b64 s[0:1],0", "s_mov_b64 s[0:1],0\ns_mov_b32 s1,0")
            .replace("v_readlane_b32 s1,v47,39\n", ""),
        "v_mov_b32 v1,7",
    );
}

#[test]
fn helper_register_mentions_kill_saved_words_including_one_lane_and_wide_tuples() {
    for helper in [
        "s_mov_b32 s6,0\nv_writelane_b32 v47,s6,38\nv_mov_b32 v1,7",
        "s_mov_b32 s6,0\nv_writelane_b32 v47,s6,39\nv_mov_b32 v1,7",
        "v_mov_b64_e32 v[46:47],0\nv_mov_b32 v1,7",
    ] {
        refused(&repeated(), helper);
    }
}

#[test]
fn transitive_helpers_and_predicated_register_writes_cannot_hide_clobbers() {
    let outer = "s_mov_b64 s[28:29],s[30:31]\n".to_owned()
        + &address("inner", 2)
        + "s_swappc_b64 s[30:31],s[2:3]\ns_mov_b64 s[30:31],s[28:29]\nv_mov_b32 v1,7";
    let source = module(&repeated(), &outer)
        + ".type inner,@function\ninner:\ns_mov_b32 s6,0\nv_writelane_b32 v47,s6,38\ns_setpc_b64 s[30:31]\n.size inner,.-inner\n";
    let parsed = frontend::parse(&source).unwrap();
    assert!(lower::lower_module_kernel(&parsed, "k").is_err());
    // Even an EXEC-zero vector write may clobber a saved bank on another path.
    // The certificate does not infer a callee's dynamic predicate or ABI saves.
    refused(
        &repeated(),
        "s_mov_b64 exec,0\nv_mov_b32 v47,0\ns_mov_b64 exec,-1\nv_mov_b32 v1,7",
    );
}

#[test]
fn caller_mutated_operand_shapes_and_suffixes_do_not_enter_transport_proofs() {
    let good = module(&repeated(), "v_mov_b32 v1,7");
    for mutation in 0..4 {
        let mut parsed = frontend::parse(&good).unwrap();
        let restore = parsed.kernels[0]
            .instructions
            .iter_mut()
            .find(|instruction| instruction.mnemonic == "v_readlane_b32")
            .unwrap();
        match mutation {
            0 => restore.operands.push(frontend::Operand::Integer(0)),
            1 => restore.mnemonic.push_str("_e32"),
            2 => {
                if let frontend::Operand::Register(source) = &mut restore.operands[1] {
                    source.count = 2;
                }
            }
            3 => restore.opcode = frontend::Opcode::Control,
            _ => unreachable!(),
        }
        assert!(lower::lower_module_kernel(&parsed, "k").is_err());
    }
}

#[test]
fn construction_identity_symbol_order_and_carry_adjacency_cannot_be_forged() {
    for entry in [
        repeated().replace("leaf@rel32@hi", "missing@rel32@hi"),
        repeated().replace("@hi+12", "@hi+8"),
        repeated().replace("s_addc_u32", "s_mov_b32 s6,0\ns_addc_u32"),
        repeated().replace("s_addc_u32", "s_cmp_eq_u32 s6,0\ns_addc_u32"),
        repeated().replace("s_add_u32 s0,s0", "s_add_u32 s1,s0"),
        repeated().replace("s_addc_u32 s1,s1", "s_addc_u32 s0,s1"),
    ] {
        refused(&entry, "v_mov_b32 v1,7");
    }
    // Both halves name leaf but belong to different construction origins.
    let different = address("leaf", 0)
        + spill()
        + &address("leaf", 2)
        + "v_writelane_b32 v47,s3,39\ns_mov_b64 s[0:1],0\n"
        + restore()
        + call()
        + store();
    refused(&different, "v_mov_b32 v1,7");
}

#[test]
fn branches_conditional_joins_and_loop_entries_cannot_inherit_fallthrough_facts() {
    for entry in [
        address("leaf", 0)
            + spill()
            + "s_branch .Lrestore\n.Lrestore:\n"
            + restore()
            + call()
            + store(),
        address("leaf", 0)
            + spill()
            + "s_cmp_eq_u32 s6,0\ns_cbranch_scc1 .Lrestore\ns_mov_b32 s6,1\n.Lrestore:\n"
            + restore()
            + call()
            + store(),
        "s_mov_b32 s6,0\ns_cbranch_scc1 .Lrestore\n".to_owned()
            + &address("leaf", 0)
            + spill()
            + ".Lrestore:\n"
            + restore()
            + call()
            + store(),
        address("leaf", 0)
            + spill()
            + ".Lrestore:\n"
            + restore()
            + call()
            + "s_cbranch_scc1 .Lrestore\n"
            + store(),
    ] {
        refused(&entry, "v_mov_b32 v1,7");
    }
}

#[test]
fn branches_must_execute_the_anchor_before_both_canonical_add_stages() {
    for stage in ["s_add_u32", "s_addc_u32"] {
        let entry = "s_branch .Lmiddle\n".to_owned()
            + &address("leaf", 0).replace(stage, &(".Lmiddle:\n".to_owned() + stage))
            + call()
            + store();
        refused(&entry, "v_mov_b32 v1,7");
    }
    let entry =
        "s_branch .Lanchor\n.Lanchor:\n".to_owned() + &address("leaf", 0) + call() + store();
    accepted(&entry, "v_mov_b32 v1,7");
}

#[test]
fn arbitrary_target_arithmetic_and_opaque_data_extraction_are_refused() {
    for operation in [
        "s_add_u32 s0,s0,0\n",
        "s_xor_b32 s2,s0,0\n",
        "s_and_b32 s0,s0,-1\n",
    ] {
        refused(
            &(address("leaf", 0) + operation + call() + store()),
            "v_mov_b32 v1,7",
        );
    }
    let entry = address("leaf", 0)
        + spill()
        + call()
        + "v_readlane_b32 s6,v47,38\nv_mov_b32 v1,s6\n"
        + store();
    let parsed = frontend::parse(&module(&entry, "v_mov_b32 v1,7")).unwrap();
    let result = analyze(&parsed, Some("k"), config(64)).unwrap();
    assert!(result.symbolic_outputs().is_err());
}

#[test]
fn lane_transport_never_invents_unlaunched_lane_storage_or_accepts_modified_sources() {
    let parsed = frontend::parse(&module(&repeated(), "v_mov_b32 v1,7")).unwrap();
    let result = analyze(&parsed, Some("k"), config(1)).unwrap();
    assert!(result.symbolic_outputs().is_err());
    for entry in [
        repeated().replace(
            "v_writelane_b32 v47,s0,38",
            "v_writelane_b32 v47,s0,38 clamp",
        ),
        repeated().replace("v_readlane_b32 s0,v47,38", "v_readlane_b32 s0,abs(v47),38"),
    ] {
        match frontend::parse(&module(&entry, "v_mov_b32 v1,7")) {
            Err(_) => {}
            Ok(parsed) => assert!(
                lower::lower_module_kernel(&parsed, "k").is_err()
                    || analyze(&parsed, Some("k"), config(64)).is_err()
            ),
        }
    }
}
