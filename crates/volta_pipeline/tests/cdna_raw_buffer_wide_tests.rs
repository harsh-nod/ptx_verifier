//! CDNA3/4 §9.1.5/§9.1.7 and §12.13: bounded linear raw DWORD/X2/X4.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, frontend, lower};
use volta_expr::ExprNode;
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile, ProgramPoint};
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

fn quad(first: u32, base: u64, bytes: u32, stride: u32) -> String {
    [
        base as u32,
        (base >> 32) as u32 | stride << 16,
        bytes,
        0x20000,
    ]
    .into_iter()
    .enumerate()
    .map(|(i, word)| format!("s_mov_b32 s{},{}\n", first + i as u32, word))
    .collect()
}

fn operation(words: u32, store: bool, address: u32, resource: u32, offset: u32) -> String {
    let suffix = if words == 1 {
        String::new()
    } else {
        format!("x{words}")
    };
    let data = if words == 1 {
        "v4".into()
    } else {
        format!("v[4:{}]", words + 3)
    };
    format!(
        "buffer_{}_dword{suffix} {data},v{address},s[{resource}:{}],0 offen offset:{offset}",
        if store { "store" } else { "load" },
        resource + 3
    )
}

fn source(target: &str, body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    )
}

fn run_at(
    target: &str,
    body: &str,
    block: u32,
    input_base: u64,
    input_len: u64,
    output_len: u64,
) -> gfx950_common::Checked {
    let source = source(target, body);
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: input_base,
            elem_width: 4,
            len: input_len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: output_len,
            kind: ArrayKind::Output,
        },
    ];
    let checked = gfx950_common::check(&source, &module, Some("k"), config).unwrap();
    checked.analysis.graph().validate().unwrap();
    checked
}

fn run(target: &str, body: &str, block: u32, words: u32) -> gfx950_common::Checked {
    let len = u64::from(block * words);
    run_at(target, body, block, 0x10000, len, len)
}

fn copy_body(words: u32, block: u32) -> String {
    quad(8, 0x10000, block * words * 4, 0)
        + &quad(12, 0x20000, block * words * 4, 0)
        + &format!("v_mul_lo_u32 v16,{},v0\n", words * 4)
        + &operation(words, false, 16, 8, 0)
        + "\ns_waitcnt vmcnt(0)\n"
        + &operation(words, true, 16, 12, 0)
        + "\ns_waitcnt vmcnt(0)"
}

fn assert_input(checked: &gfx950_common::Checked, index: u64, expected: u64) {
    let outputs = checked.analysis.symbolic_outputs().unwrap();
    let ExprNode::InputElement {
        array,
        index: actual,
    } = outputs.arena.node(outputs.element("out", index).unwrap())
    else {
        panic!("expected raw input at output {index}")
    };
    assert_eq!(outputs.arena.string(*array), "x");
    assert_eq!(*actual, expected, "output {index}");
}

fn verified_copy(checked: &gfx950_common::Checked, len: u64, first: u64) {
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:?}",
        checked.checks.amd
    );
    assert_eq!(
        checked.analysis.symbolic_outputs().unwrap().outputs[0]
            .1
            .len(),
        len as usize
    );
    for i in 0..len {
        assert_input(checked, i, first + i);
    }
}

fn hazard(
    checked: &gfx950_common::Checked,
    kind: AmdRegisterHazardKind,
    file: AmdRegisterFile,
    index: u16,
) {
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:?}",
        checked.checks
    );
    let PropertyResult::Fail(hazards) = &checked.checks.amd.as_ref().unwrap().wait_readiness else {
        panic!("readiness failure")
    };
    assert!(
        hazards
            .iter()
            .any(|h| h.kind == kind && h.register.file == file && h.register.index == index),
        "{hazards:?}"
    );
}

fn no_buffer_issue(target: &str, body: &str, checked: &gfx950_common::Checked, store: bool) {
    assert!(checked.analysis.symbolic_outputs().is_err());
    let module = frontend::parse(&source(target, body)).unwrap();
    for (pc, _) in module.kernels[0]
        .instructions
        .iter()
        .enumerate()
        .filter(|(_, i)| {
            i.mnemonic
                .starts_with(if store { "buffer_store" } else { "buffer_load" })
        })
    {
        assert!(
            !checked
                .analysis
                .graph()
                .amd_events()
                .iter()
                .any(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. })
                    && checked.analysis.graph().event(r.event).pc == Some(ProgramPoint(pc as u32)))
        );
    }
}

#[test]
fn all_words_and_wave_boundaries_retain_independent_absolute_input_coordinates() {
    for target in ["gfx942", "gfx950"] {
        for words in [1, 2, 4] {
            for block in [1, 31, 32, 63, 64, 65] {
                let checked = run(target, &copy_body(words, block), block, words);
                verified_copy(&checked, u64::from(block * words), 0);
                let issues: Vec<_> = checked
                    .analysis
                    .graph()
                    .amd_events()
                    .iter()
                    .filter_map(|r| {
                        if let AmdEventKind::MemoryIssue {
                            class,
                            counters,
                            held_sources,
                            destinations,
                        } = &r.kind
                        {
                            Some((class, counters, held_sources, destinations))
                        } else {
                            None
                        }
                    })
                    .collect();
                assert_eq!(issues.len(), 2 * block.div_ceil(64) as usize);
                for (class, counters, held, destinations) in issues {
                    assert_eq!(counters, &[(AmdCounter::Vm, 1)]);
                    if !destinations.is_empty() {
                        assert_eq!(*class, AmdMemoryClass::VectorMemory);
                        assert!(held.is_empty());
                        assert_eq!(destinations.len(), words as usize);
                    } else {
                        assert!(destinations.is_empty());
                        if words == 4 {
                            assert_eq!(*class, AmdMemoryClass::VectorStoreWide);
                            assert_eq!(
                                held.iter().map(|r| r.index).collect::<Vec<_>>(),
                                [4, 5, 6, 7]
                            );
                        } else {
                            assert!(held.is_empty());
                        }
                    }
                }
            }
        }
    }
}

#[test]
fn final_alignment_does_not_apply_scalar_memory_masks_to_individual_components() {
    for target in ["gfx942", "gfx950"] {
        for (allocation, base, vector, immediate, first) in [
            (0x10000, 0x10001, 1, 2, 1),
            (0x10000, 0x10003, 4093, 0, 1024),
            (0x10000, 0x10000, 1, 4095, 1024),
            (0xffff_fffc, 0xffff_fffd, 1, 2, 1),
        ] {
            for stride in [0, 1, 0x3fff] {
                let body = quad(8, base, 8192, stride)
                    + &quad(12, 0x20000, 16, 0)
                    + &format!("v_mov_b32 v16,{vector}\nv_mov_b32 v17,0\n")
                    + &operation(4, false, 16, 8, immediate)
                    + "\ns_waitcnt vmcnt(0)\n"
                    + &operation(4, true, 17, 12, 0);
                let checked = run_at(target, &body, 1, allocation, 2048, 4);
                // Independently: align(base + vector + immediate) = allocation + first*4.
                // Masking base/vector/immediate separately loses one word in each row.
                verified_copy(&checked, 4, first);
            }
        }
        for (base, vector, immediate) in [(0x10001, 0, 0), (0x10000, 1, 0), (0x10000, 0, 1)] {
            let body = quad(8, base, 64, 0)
                + &format!("v_mov_b32 v16,{vector}\n")
                + &operation(4, false, 16, 8, immediate);
            let checked = run_at(target, &body, 1, 0x10000, 16, 4);
            no_buffer_issue(target, &body, &checked, false);
        }
    }
}

#[test]
fn aliased_address_sparse_mask_and_empty_exec_keep_all_four_words_and_flags() {
    for target in ["gfx942", "gfx950"] {
        let prefix = quad(8, 0x10000, 1024, 0)
            + &quad(12, 0x20000, 1024, 0)
            + "v_mul_lo_u32 v16,16,v0\nv_mov_b32 v4,v16\nv_mov_b32 v5,21\nv_mov_b32 v6,22\nv_mov_b32 v7,23\ns_mov_b32 vcc_lo,1\ns_mov_b32 vcc_hi,1\ns_cmp_eq_u32 1,1\ns_mov_b32 exec_lo,1\ns_mov_b32 exec_hi,0x80000001\n";
        let body = prefix
            + &operation(4, false, 4, 8, 0)
            + "\ns_waitcnt vmcnt(0)\ns_mov_b64 exec,-1\nv_add_u32 v4,0,v4\nv_add_u32 v5,0,v5\nv_add_u32 v6,0,v6\nv_add_u32 v7,0,v7\n"
            + &operation(4, true, 16, 12, 0)
            + "\ns_cbranch_scc0 bad\ns_cbranch_vccz bad\ns_branch done\nbad:\nv_mov_b32 v8,v250\ndone:";
        let checked = run(target, &body, 64, 4);
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{:?}",
            checked.checks
        );
        let outputs = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 256);
        for lane in 0..64 {
            for word in 0..4 {
                if [0, 32, 63].contains(&lane) {
                    assert_input(&checked, lane * 4 + word, lane * 4 + word);
                } else {
                    // Explicit integer consumers disambiguate the raw MOV words.
                    let bits = if word == 0 {
                        lane as u32 * 16
                    } else {
                        20 + word as u32
                    };
                    assert_eq!(
                        outputs
                            .arena
                            .as_int_const(outputs.element("out", lane * 4 + word).unwrap()),
                        Some(i64::from(bits))
                    );
                }
            }
        }
        let body = "s_mov_b64 exec,0\nbuffer_load_dwordx4 v[4:7],v16,s[8:11],0 offen\nbuffer_store_dwordx4 v[4:7],v16,s[12:15],0 offen\ns_mov_b64 exec,1\n".to_owned() + &copy_body(4, 1);
        verified_copy(&run(target, &body, 1, 4), 4, 0);
    }
}

#[test]
fn every_descriptor_word_loaded_result_and_store_word_keeps_its_readiness_obligation() {
    for target in ["gfx942", "gfx950"] {
        let copy = copy_body(4, 1);
        for wait in [
            "s_waitcnt lgkmcnt(0)",
            "s_waitcnt vmcnt(0)",
            "s_waitcnt expcnt(0)",
        ] {
            for word in 0..4 {
                // Scalar reload from initialized output preserves the same raw descriptor
                // word numerically while adding an independent LGKM producer.
                let value = [0x10000, 0, 16, 0x20000][word];
                let body = quad(8, 0x10000, 16, 0)
                    + &quad(12, 0x20000, 16, 0)
                    + &format!(
                        "v_mov_b32 v16,0\nv_mov_b32 v20,{value}\nglobal_store_dword v16,v20,s[12:13]\ns_waitcnt vmcnt(0)\ns_load_dword s{},s[12:13],0\n{wait}\n",
                        8 + word
                    )
                    + &copy[copy.find("v_mul_lo_u32").unwrap()..];
                let checked = run(target, &body, 1, 4);
                if wait == "s_waitcnt lgkmcnt(0)" {
                    verified_copy(&checked, 4, 0);
                } else {
                    hazard(
                        &checked,
                        AmdRegisterHazardKind::ReadBeforeReady,
                        AmdRegisterFile::Scalar,
                        (8 + word) as u16,
                    );
                }
            }
        }
        for word in 4..8 {
            let base = quad(8, 0x10000, 16, 0)
                + &quad(12, 0x20000, 16, 0)
                + "v_mov_b32 v16,0\n"
                + &operation(4, false, 16, 8, 0);
            for wait in ["s_waitcnt vmcnt(0)", "s_waitcnt lgkmcnt(0)"] {
                let body = base.clone()
                    + &format!("\n{wait}\nv_add_u32 v20,0,v{word}\n")
                    + &operation(4, true, 16, 12, 0);
                let checked = run(target, &body, 1, 4);
                if wait == "s_waitcnt vmcnt(0)" {
                    verified_copy(&checked, 4, 0);
                } else {
                    hazard(
                        &checked,
                        AmdRegisterHazardKind::ReadBeforeReady,
                        AmdRegisterFile::Vector,
                        word as u16,
                    );
                }
            }
        }
    }
}

#[test]
fn x4_stores_retain_the_data_tuple_for_two_states_and_not_the_address_register() {
    for target in ["gfx942", "gfx950"] {
        for word in 4..8 {
            for states in [0, 1, 2] {
                let body = copy_body(4, 1);
                let body = body.trim_end_matches("\ns_waitcnt vmcnt(0)").to_owned()
                    + &"\ns_nop 0".repeat(states)
                    + &format!("\nv_mov_b32 v{word},0");
                let checked = run(target, &body, 1, 4);
                if states == 2 {
                    verified_copy(&checked, 4, 0);
                } else {
                    hazard(
                        &checked,
                        AmdRegisterHazardKind::SourceReuse,
                        AmdRegisterFile::Vector,
                        word,
                    );
                }
            }
        }
        let body = copy_body(4, 1)
            .trim_end_matches("\ns_waitcnt vmcnt(0)")
            .to_owned()
            + "\nv_mov_b32 v16,0";
        verified_copy(&run(target, &body, 1, 4), 4, 0);
    }
}

#[test]
fn complete_resource_allocation_and_store_data_preflight_precedes_every_effect() {
    for target in ["gfx942", "gfx950"] {
        for body in [
            quad(8, 0x10000, 12, 0) + "v_mov_b32 v16,0\n" + &operation(4, false, 16, 8, 0),
            quad(8, 0x10000, 0, 0) + "v_mov_b32 v16,0\n" + &operation(4, false, 16, 8, 0),
            quad(8, 0x10000, 16, 0)
                + "s_mov_b32 s9,0x40000000\nv_mov_b32 v16,0\n"
                + &operation(4, false, 16, 8, 0),
            quad(8, 0x10000, 16, 0)
                + "s_mov_b32 s11,0x820000\nv_mov_b32 v16,0\n"
                + &operation(4, false, 16, 8, 0),
            quad(8, 0x10000, 0xffff_fffc, 0)
                + "v_mov_b32 v16,0xfffffffc\n"
                + &operation(4, false, 16, 8, 4),
            quad(8, (1u64 << 48) - 4, 16, 0) + "v_mov_b32 v16,0\n" + &operation(4, false, 16, 8, 0),
        ] {
            let checked = run(target, &body, 1, 4);
            no_buffer_issue(target, &body, &checked, false);
        }
        // Resource allows the last lane, but the configured allocation does not.
        let body = copy_body(4, 64);
        let checked = run_at(target, &body, 64, 0x10000, 255, 256);
        no_buffer_issue(target, &body, &checked, false);
        for missing in 4..8 {
            let body = quad(12, 0x20000, 16, 0)
                + "v_mov_b32 v16,0\n"
                + &(4..8)
                    .filter(|w| *w != missing)
                    .map(|w| format!("v_mov_b32 v{w},1\n"))
                    .collect::<String>()
                + &operation(4, true, 16, 12, 0);
            let checked = run(target, &body, 1, 4);
            no_buffer_issue(target, &body, &checked, true);
        }
        let body = quad(12, 0x20000, 16, 0)
            + "v_mov_b32 v16,0\nv_mov_b32 v4,1\nv_mov_b32 v5,2\nv_mov_b32 v6,3\nv_mov_b32 v7,4\nv_lshlrev_b16 v7,1,v7\n"
            + &operation(4, true, 16, 12, 0);
        no_buffer_issue(target, &body, &run(target, &body, 1, 4), true);
    }
}

#[test]
fn malformed_or_wider_profiles_cannot_bypass_text_or_typed_lowering() {
    for target in ["gfx942", "gfx950"] {
        for bad in [
            "buffer_load_dwordx4_e64 v[4:7],v16,s[8:11],0 offen",
            "buffer_load_dwordx4 v[5:8],v16,s[8:11],0 offen",
            "buffer_load_dwordx4 v[4:7],v16,s[9:12],0 offen",
            "buffer_load_dwordx4 v[4:7],v16,s[8:11],0 offen offset:4096",
            "buffer_load_dwordx4 v[4:7],v16,s[8:11],0 offen offset:-1",
        ] {
            assert!(
                frontend::parse(&source(target, bad)).is_err(),
                "{target}: {bad}"
            );
        }
        let mut module = frontend::parse(&source(target, &operation(4, false, 16, 8, 0))).unwrap();
        // Encoding legality also survives a mutable-AST bypass of text parsing.
        module.kernels[0].instructions[0].mnemonic = "buffer_load_dwordx4_e64".into();
        assert!(lower::lower_module_kernel(&module, "k").is_err());
        if target == "gfx950" {
            for outside in [
                "buffer_load_dwordx4 v[4:7],v16,s[8:11],1 offen",
                "buffer_load_dwordx4 v[4:7],v16,s[8:11],0 offen glc",
                "buffer_store_dwordx4 a[4:7],v16,s[8:11],0 offen",
            ] {
                assert!(frontend::parse(&source(target, outside)).is_err());
            }
            let mut module =
                frontend::parse(&source(target, &operation(4, false, 16, 8, 0))).unwrap();
            module.kernels[0].instructions[0].operands[3] = frontend::Operand::Integer(1);
            assert!(lower::lower_module_kernel(&module, "k").is_err());
        }
        // DWORDX3 is still recognized but outside this execution increment.
        let body = quad(8, 0x10000, 16, 0)
            + "v_mov_b32 v16,0\nbuffer_load_dwordx3 v[4:6],v16,s[8:11],0 offen";
        no_buffer_issue(target, &body, &run(target, &body, 1, 4), false);
    }
}
