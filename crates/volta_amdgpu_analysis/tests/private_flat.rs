//! Private aperture pointers retain identity and alias the same per-item scratch.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, analyze, frontend,
};
use volta_graph::{AmdEventKind, AmdMemoryClass, Terminal};
use volta_graph_check::{GraphConclusion, check_graph};

fn run(body: &str, items: u32) -> AnalysisResult {
    let text = format!(
        ".amdgcn_target \"gfx950\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_private_segment_fixed_size 32\n.amdhsa_enable_private_segment 1\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n.amdgpu_metadata\n---\namdhsa.version: [1, 2]\namdhsa.kernels:\n  - .name: k\n    .private_segment_fixed_size: 32\n...\n.end_amdgpu_metadata\n"
    );
    let module = frontend::parse(&text).expect("native source");
    let mut config = AnalysisConfig::new((items, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: u64::from(items),
        kind: ArrayKind::Output,
    });
    analyze(&module, Some("k"), config).expect("launch")
}
fn pointer(offset: &str) -> String {
    format!("s_mov_b64 s[4:5],src_private_base\nv_mov_b32 v20,{offset}\nv_mov_b32 v21,s5\n")
}
fn output() -> &'static str {
    "s_mov_b32 s8,0x20000\ns_mov_b32 s9,0\nv_lshlrev_b32 v3,2,v0\nv_cvt_f32_u32 v2,v2\nglobal_store_dword v3,v2,s[8:9]\n"
}
fn check(result: &AnalysisResult, items: u64, expected: impl Fn(u64) -> f64) {
    result.graph().validate().unwrap();
    let report = check_graph(result.graph());
    assert_eq!(
        report.conclusion(),
        GraphConclusion::Verified,
        "{report:#?}"
    );
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), items as usize);
    for i in 0..items {
        assert_eq!(
            outputs.arena.as_f64(outputs.element("out", i).unwrap()),
            Some(expected(i)),
            "item {i}"
        );
    }
}
fn refused(result: &AnalysisResult, reason: &str) {
    assert!(result.symbolic_outputs().is_err());
    let Terminal::Aborted { reason: actual, .. } = result.graph().terminal() else {
        panic!("must abort")
    };
    assert!(actual.contains(reason), "{actual}");
    assert_ne!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
}
fn issues(result: &AnalysisResult) -> usize {
    result
        .graph()
        .amd_events()
        .iter()
        .filter(|r| {
            matches!(
                r.kind,
                AmdEventKind::MemoryIssue {
                    class: AmdMemoryClass::FlatPrivateLoad
                        | AmdMemoryClass::FlatPrivateStore
                        | AmdMemoryClass::ScratchLoadWide
                        | AmdMemoryClass::ScratchStoreWide,
                    ..
                }
            )
        })
        .count()
}

#[test]
fn scratch_and_flat_alias_in_both_directions_for_every_word_of_wide_tuples() {
    for words in 1..=4 {
        let suffix = if words == 1 {
            String::new()
        } else {
            format!("x{words}")
        };
        let tuple = if words == 1 {
            "v10".into()
        } else {
            format!("v[10:{}]", 9 + words)
        };
        let setup = (0..words)
            .map(|word| format!("v_add_u32 v{}, {},v0\n", 10 + word, 1000 + 37 * word))
            .collect::<String>();
        for flat_store in [false, true] {
            for component in 0..words {
                let stores = if flat_store {
                    format!("flat_store_dword{suffix} v[20:21],{tuple}\n")
                } else {
                    format!("scratch_store_dword{suffix} off,{tuple},s6\n")
                };
                let loads = if flat_store {
                    format!("scratch_load_dword{suffix} {tuple},off,s6\n")
                } else {
                    format!("flat_load_dword{suffix} {tuple},v[20:21]\n")
                };
                let body = format!(
                    "{}s_mov_b32 s6,4\n{setup}{stores}s_waitcnt vmcnt(0) lgkmcnt(0)\n{loads}s_waitcnt vmcnt(0) lgkmcnt(0)\nv_mov_b32 v2,v{}\n{}",
                    pointer("4"),
                    10 + component,
                    output()
                );
                let result = run(&body, 128);
                check(&result, 128, |i| {
                    1000. + 37. * f64::from(component) + i as f64
                });
            }
        }
    }
}

#[test]
fn varying_offsets_are_per_item_and_pointer_destination_alias_is_snapshotted() {
    let body = format!(
        "{}v_and_b32 v20,1,v0\nv_lshlrev_b32 v20,4,v20\nv_add_u32 v10,101,v0\nv_add_u32 v11,303,v0\nflat_store_dwordx2 v[20:21],v[10:11]\ns_waitcnt 0\nflat_load_dwordx2 v[20:21],v[20:21]\ns_waitcnt 0\nv_add_u32 v2,v20,v21\n{}",
        pointer("0"),
        output()
    );
    check(&run(&body, 128), 128, |i| 404. + 2. * i as f64);
}

#[test]
fn private_flat_waits_require_both_explicit_counter_zeros() {
    for waits in [
        "s_waitcnt vmcnt(0)",
        "s_waitcnt lgkmcnt(0)",
        "s_waitcnt vmcnt(63)",
    ] {
        let body = format!(
            "{}v_mov_b32 v1,7\nflat_store_dword v[20:21],v1\n{waits}\nflat_load_dword v2,v[20:21]\ns_waitcnt 0\n{}",
            pointer("0"),
            output()
        );
        refused(&run(&body, 64), "explicit VM0");
    }
    for waits in [
        "s_waitcnt vmcnt(0)\ns_waitcnt lgkmcnt(0)",
        "s_waitcnt lgkmcnt(0)\ns_waitcnt vmcnt(0)",
    ] {
        let body = format!(
            "{}v_mov_b32 v1,7\nflat_store_dword v[20:21],v1\n{waits}\nflat_load_dword v2,v[20:21]\n{waits}\n{}",
            pointer("0"),
            output()
        );
        check(&run(&body, 64), 64, |_| 7.);
    }
}

#[test]
fn full_interval_and_all_active_sources_are_checked_before_issue() {
    for offset in ["28", "30", "32", "0xfffffffc"] {
        let result = run(
            &format!(
                "{}v_mov_b32 v10,7\nv_mov_b32 v11,9\nflat_store_dwordx2 v[20:21],v[10:11]",
                pointer(offset)
            ),
            64,
        );
        refused(&result, "declared fixed private extent");
        assert_eq!(issues(&result), 0);
    }
    let result = run(
        &format!(
            "{}v_mov_b32 v10,7\nflat_load_dwordx4 v[10:13],v[20:21]",
            pointer("0")
        ),
        64,
    );
    refused(&result, "uninitialized private");
    assert_eq!(issues(&result), 0);
}

#[test]
fn empty_exec_observes_neither_private_addresses_nor_payloads() {
    let body = format!(
        "{}s_mov_b64 exec,0\nflat_store_dwordx4 v[30:31],v[40:43]\nflat_load_dwordx4 v[40:43],v[30:31]\ns_mov_b64 exec,-1\nv_add_u32 v2,11,v0\n{}",
        pointer("0"),
        output()
    );
    let result = run(&body, 64);
    check(&result, 64, |i| 11. + i as f64);
    assert_eq!(issues(&result), 0);
}

#[test]
fn private_pointer_never_becomes_numeric_data_or_a_global_address() {
    for consumer in [
        "v_mov_b32 v2,s5\nv_cvt_f32_u32 v2,v2",
        "v_mov_b32 v20,0\nflat_load_dword v2,v[20:21]",
        "global_load_dword v2,v[20:21],off",
    ] {
        let result = run(&format!("{}{consumer}", pointer("0")), 64);
        assert!(result.symbolic_outputs().is_err());
        assert_ne!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        );
    }
}

#[test]
fn sparse_private_flat_never_reads_another_lanes_cell_and_pending_sources_stay_live() {
    let missing = run(
        &format!(
            "{}v_add_u32 v1,77,v0\ns_mov_b64 exec,1\nflat_store_dword v[20:21],v1\ns_waitcnt 0\ns_mov_b64 exec,2\nflat_load_dword v2,v[20:21]",
            pointer("0")
        ),
        64,
    );
    refused(&missing, "uninitialized private");
    assert_eq!(issues(&missing), 1);
    for dependent in ["v_mov_b32 v1,9", "v_mov_b32 v20,4", "s_endpgm"] {
        let result = run(
            &format!(
                "{}v_mov_b32 v1,7\nflat_store_dword v[20:21],v1\n{dependent}",
                pointer("0")
            ),
            64,
        );
        refused(&result, "explicit VM0");
    }
    let mixed = run(
        &format!(
            "{}s_mov_b64 exec,1\nv_mov_b32 v21,0\ns_mov_b64 exec,-1\nv_mov_b32 v1,7\nflat_store_dword v[20:21],v1",
            pointer("0")
        ),
        64,
    );
    refused(&mixed, "mixes Private");
    assert_eq!(issues(&mixed), 0);
}

#[test]
fn an_earlier_zero_does_not_complete_a_later_private_flat_issue() {
    for (earlier, later) in [("vmcnt(0)", "lgkmcnt(0)"), ("lgkmcnt(0)", "vmcnt(0)")] {
        let body = format!(
            "{}v_mov_b32 v1,7\nflat_store_dword v[20:21],v1\ns_waitcnt {earlier}\nflat_store_dword v[20:21],v1\ns_waitcnt {later}\nflat_load_dword v2,v[20:21]",
            pointer("0")
        );
        refused(&run(&body, 64), "explicit VM0");
    }
}

#[test]
fn final_active_lane_oob_prevents_every_private_issue() {
    let body = format!(
        "{}v_cmp_eq_u32 vcc,v0,63\nv_cndmask_b32 v20,4,28,vcc\nv_mov_b32 v10,7\nv_mov_b32 v11,9\nflat_store_dwordx2 v[20:21],v[10:11]",
        pointer("4")
    );
    let result = run(&body, 64);
    refused(&result, "declared fixed private extent");
    assert_eq!(issues(&result), 0);
    assert!(
        !result
            .graph()
            .amd_events()
            .iter()
            .any(|record| matches!(record.kind, AmdEventKind::PrivateMemoryAccess { .. }))
    );
}

#[test]
fn narrower_flat_overwrite_aliases_middle_words_of_full_scratch_tuple() {
    for component in 0..4 {
        let body = format!(
            "{}s_mov_b32 s6,4\nv_add_u32 v10,1000,v0\nv_add_u32 v11,1037,v0\nv_add_u32 v12,1074,v0\nv_add_u32 v13,1111,v0\nscratch_store_dwordx4 off,v[10:13],s6\ns_waitcnt 0\nv_add_u32 v14,900,v0\nv_add_u32 v15,1100,v0\nflat_store_dwordx2 v[20:21],v[14:15]\ns_waitcnt 0\nscratch_load_dwordx4 v[10:13],off,s6\ns_waitcnt 0\nv_mov_b32 v2,v{}\n{}",
            pointer("8"),
            10 + component,
            output()
        );
        check(&run(&body, 128), 128, |i| {
            [1000., 900., 1100., 1111.][component] + i as f64
        });
    }
}

#[test]
fn private_base_target_and_caller_constructed_ast_are_validated() {
    let text = ".amdgcn_target \"gfx950\"\n.text\n.type k,@function\nk:\ns_mov_b64 s[4:5],src_private_base\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.end_amdhsa_kernel\n";
    let module = frontend::parse(text).unwrap();
    for target in ["gfx942", "gfx1250"] {
        assert!(frontend::parse(&text.replace("gfx950", target)).is_err());
        let mut retargeted = module.clone();
        retargeted.target = Some(target.into());
        assert!(volta_amdgpu_analysis::lower::lower_module_kernel(&retargeted, "k").is_err());
    }
    let mut malformed = module;
    let frontend::Operand::Register(register) =
        &mut malformed.kernels[0].instructions[0].operands[1]
    else {
        panic!("register")
    };
    register.count = 1;
    assert!(volta_amdgpu_analysis::lower::lower_module_kernel(&malformed, "k").is_err());
}
