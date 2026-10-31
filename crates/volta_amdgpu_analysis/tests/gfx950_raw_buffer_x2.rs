//! CDNA4 §12.13 opcodes21/29 transfer two ascending 32-bit words, not a cast.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend, lower,
};
use volta_expr::ExprNode;
use volta_graph::{AmdEventKind, ProgramPoint, Terminal};

const LOAD: &str = "buffer_load_dwordx2 v[0:1],v4,s[8:11],0 offen";
const STORE: &str = "buffer_store_dwordx2 v[0:1],v4,s[12:15],0 offen";
fn quad(first: u32, base: u64, bytes: u32, stride: u32) -> String {
    [
        base as u32,
        (base >> 32) as u32 | stride << 16,
        bytes,
        0x20000,
    ]
    .into_iter()
    .enumerate()
    .map(|(i, w)| format!("s_mov_b32 s{},{}\n", first + i as u32, w))
    .collect()
}
fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.text\n.type k,@function\nk:\nv_lshlrev_b32 v4,3,v0\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    )
}
fn run_at(
    body: &str,
    block: u32,
    base: u64,
    width: u64,
    input_len: u64,
    output_len: u64,
    indices: bool,
) -> AnalysisResult {
    let module = frontend::parse(&source(body)).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base,
            elem_width: width,
            len: input_len,
            kind: if indices {
                ArrayKind::IndexInput
            } else {
                ArrayKind::Input
            },
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: output_len,
            kind: ArrayKind::Output,
        },
    ];
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}
fn run(body: &str, block: u32) -> AnalysisResult {
    run_at(body, block, 0x10000, 4, 128, u64::from(block) * 2, false)
}
fn copy_body(block: u32) -> String {
    quad(8, 0x10000, 512, 0)
        + &quad(12, 0x20000, block * 8, 0)
        + LOAD
        + "\ns_waitcnt vmcnt(0)\n"
        + STORE
        + "\ns_waitcnt vmcnt(0)"
}
fn assert_inputs(result: &AnalysisResult, expected: &[u64]) {
    assert_eq!(result.graph().terminal(), &Terminal::Completed);
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), expected.len());
    for (out, &input) in expected.iter().enumerate() {
        let ExprNode::InputElement { array, index } = outputs
            .arena
            .node(outputs.element("out", out as u64).unwrap())
        else {
            panic!("unmodified symbolic word")
        };
        assert_eq!(outputs.arena.string(*array), "x");
        assert_eq!(*index, input);
    }
}
fn no_buffer_issue(result: &AnalysisResult, body: &str) {
    assert!(result.symbolic_outputs().is_err());
    let module = frontend::parse(&source(body)).unwrap();
    for (pc, _) in module.kernels[0]
        .instructions
        .iter()
        .enumerate()
        .filter(|(_, i)| i.mnemonic.starts_with("buffer_"))
    {
        assert!(!result.graph().amd_events().iter().any(|r| matches!(
            r.kind,
            AmdEventKind::MemoryIssue { .. }
        ) && result.graph().event(r.event).pc
            == Some(ProgramPoint(pc as u32))));
    }
}

#[test]
fn both_words_and_all_lanes_keep_ascending_symbolic_element_order() {
    for block in [1, 2, 32, 48, 64] {
        assert_inputs(
            &run(&copy_body(block), block),
            &(0..u64::from(block) * 2).collect::<Vec<_>>(),
        );
    }
    // DWORD alignment is sufficient; imposing natural 8-byte alignment would
    // reject this legal two-word address and hide a word-order error.
    for stride in [0, 1, 0x3fff] {
        let body = quad(8, 0x10004, 8, stride)
            + &quad(12, 0x20000, 8, 0)
            + LOAD
            + "\ns_waitcnt vmcnt(0)\n"
            + STORE
            + "\ns_waitcnt vmcnt(0)";
        assert_inputs(&run(&body, 1), &[1, 2]);
    }
    let body = quad(8, 0x1_0001_0000, 4104, 0)
        + &quad(12, 0x20000, 8, 0)
        + "v_mov_b32 v4,1\n"
        + LOAD
        + " offset:4095\ns_waitcnt vmcnt(0)\nv_mov_b32 v4,0\n"
        + STORE
        + "\ns_waitcnt vmcnt(0)";
    assert_inputs(
        &run_at(&body, 1, 0x1_0001_0000, 4, 1026, 2, false),
        &[1024, 1025],
    );
}

#[test]
fn concrete_byte_inputs_expose_little_endian_low_and_high_words() {
    let body = quad(8, 0x10000, 8, 0)
        + &quad(12, 0x20000, 8, 0)
        + LOAD
        + "\ns_waitcnt vmcnt(0)\nv_add_u32 v0,0,v0\nv_add_u32 v1,0,v1\n"
        + STORE
        + "\ns_waitcnt vmcnt(0)";
    let result = run_at(&body, 1, 0x10000, 1, 8, 2, true);
    let outputs = result.symbolic_outputs().unwrap();
    for (index, value) in [(0, 0x0302_0100i64), (1, 0x0706_0504)] {
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index).unwrap()),
            Some(value)
        );
    }
}

#[test]
fn address_destination_alias_snapshots_both_words_and_sparse_exec_preserves_inactive_pairs() {
    let body = quad(8, 0x10000, 512, 0)
        + &quad(12, 0x20000, 32, 0)
        + "v_add_f32 v5,2.0,0.0\ns_mov_b64 exec,5\nbuffer_load_dwordx2 v[4:5],v4,s[8:11],0 offen\ns_waitcnt vmcnt(0)\ns_mov_b64 exec,15\nv_lshlrev_b32 v6,3,v0\nbuffer_store_dwordx2 v[4:5],v6,s[12:15],0 offen\ns_waitcnt vmcnt(0)";
    let result = run(&body, 4);
    let outputs = result.symbolic_outputs().unwrap();
    for lane in 0..4 {
        for component in 0..2 {
            let id = outputs.element("out", lane * 2 + component).unwrap();
            if lane % 2 == 0 {
                assert!(
                    matches!(outputs.arena.node(id),ExprNode::InputElement{index,..}if *index==lane*2+component)
                );
            } else if component == 0 {
                assert_eq!(outputs.arena.as_int_const(id), Some((lane * 8) as i64));
            } else {
                assert!(
                    matches!(outputs.arena.node(id), ExprNode::RealConst(value) if value.to_f64() == 2.0)
                );
            }
        }
    }
}

#[test]
fn resource_allocation_and_domain_preflight_cover_the_complete_pair_and_every_lane() {
    for (records, block) in [(4, 1), (12, 2)] {
        for op in [LOAD, STORE] {
            let body = quad(8, 0x10000, records, 0)
                + &quad(12, 0x20000, records, 0)
                + "v_add_f32 v0,1.0,0.0\nv_add_f32 v1,2.0,0.0\n"
                + op;
            no_buffer_issue(&run(&body, block), &body);
        }
    }
    let body = quad(8, 0x10000, 16, 0) + LOAD;
    no_buffer_issue(&run_at(&body, 2, 0x10000, 4, 3, 4, false), &body);
    let body = quad(12, 0x20000, 16, 0) + "v_add_f32 v0,1.0,0.0\nv_add_f32 v1,2.0,0.0\n" + STORE;
    no_buffer_issue(&run_at(&body, 2, 0x10000, 4, 4, 3, false), &body);
    let top = (1u64 << 48) - 8;
    let body = quad(8, top, 8, 0)
        + &quad(12, 0x20000, 8, 0)
        + LOAD
        + "\ns_waitcnt vmcnt(0)\n"
        + STORE
        + "\ns_waitcnt vmcnt(0)";
    assert_inputs(&run_at(&body, 1, top, 4, 2, 2, false), &[0, 1]);
    let body = quad(8, (1u64 << 48) - 4, 8, 0) + LOAD;
    no_buffer_issue(&run(&body, 1), &body);
    let body = quad(8, 0x10000, u32::MAX - 3, 0) + "v_mov_b32 v4,0xfffffffc\n" + LOAD + " offset:4";
    no_buffer_issue(&run(&body, 1), &body);
}

#[test]
fn every_descriptor_and_high_store_word_must_be_defined_before_any_effect() {
    for missing in 8..12 {
        let body = quad(8, 0x10000, 512, 0)
            .lines()
            .filter(|line| !line.starts_with(&format!("s_mov_b32 s{missing},")))
            .collect::<Vec<_>>()
            .join("\n")
            + "\n"
            + LOAD;
        no_buffer_issue(&run(&body, 1), &body);
    }
    let body = quad(12, 0x20000, 16, 0)
        + "s_mov_b64 exec,1\nv_add_f32 v0,1.0,0.0\nv_add_f32 v1,2.0,0.0\ns_mov_b64 exec,3\n"
        + STORE;
    no_buffer_issue(&run(&body, 2), &body);
    for missing in [0, 1] {
        let values = if missing == 0 {
            "v_add_f32 v1,2.0,0.0\nv_mov_b32 v0,v20"
        } else {
            "v_add_f32 v0,1.0,0.0"
        };
        let body = quad(12, 0x20000, 8, 0) + values + "\n" + STORE;
        no_buffer_issue(&run(&body, 1), &body);
    }
    // Explicitly supplied one-byte ABI data leaves the other bits undefined.
    let body = quad(12, 0x20000, 8, 0)
        + "v_add_f32 v0,1.0,0.0\ns_load_dword s20,s[0:1],0\ns_waitcnt lgkmcnt(0)\nv_mov_b32 v1,s20\n"
        + STORE;
    let text = source(&body).replace(
        ".amdhsa_kernel k",
        ".amdhsa_kernel k\n.amdhsa_user_sgpr_kernarg_segment_ptr 1\n.amdhsa_kernarg_size 4",
    ) + ".amdgpu_metadata\n---\namdhsa.version: [1,2]\namdhsa.kernels:\n  - .name: k\n    .args:\n      - .name: byte\n        .offset: 0\n        .size: 1\n        .value_kind: by_value\n...\n.end_amdgpu_metadata\n";
    let module = frontend::parse(&text).unwrap();
    let mut cfg = AnalysisConfig::new((1, 1, 1));
    cfg.params.push(ParamValue::Bytes(vec![7]));
    cfg.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    });
    let result = analyze(&module, Some("k"), cfg).unwrap();
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("undefined")
    );
    no_buffer_issue(&result, &body);
}

#[test]
fn zero_exec_skips_all_valid_profile_input_reads_but_not_static_profile_validation() {
    let body = "s_mov_b64 exec,0\n".to_string()
        + LOAD
        + "\n"
        + STORE
        + "\ns_mov_b64 exec,1\n"
        + &copy_body(1);
    let result = run(&body, 1);
    assert_inputs(&result, &[0, 1]);
    assert_eq!(
        result
            .graph()
            .amd_events()
            .iter()
            .filter(|e| matches!(e.kind, AmdEventKind::MemoryIssue { .. }))
            .count(),
        2
    );
    for op in [LOAD, STORE] {
        for bad in [
            op.replace(",0 offen", ",s20 offen"),
            op.replace(",0 offen", ",1 offen"),
            op.replace("offen", "idxen"),
            op.replace("offen", "offen glc"),
            op.replace("offen", "offen lds"),
            op.replace("v[0:1]", "a[0:1]"),
            op.replace("dwordx2", "dwordx2_e64"),
            format!("{op} offset:4096"),
            format!("{op} offset:-1"),
        ] {
            for body in [
                format!("s_mov_b64 exec,0\n{bad}"),
                format!("s_branch done\n{bad}\ndone:"),
            ] {
                assert!(frontend::parse(&source(&body)).is_err(), "{body}");
            }
        }
    }
    let module = frontend::parse(&source(LOAD)).unwrap();
    for bad in 0..3 {
        let mut kernel = module.kernels[0].clone();
        let i = kernel
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "buffer_load_dwordx2")
            .unwrap();
        match bad {
            0 => i.operands[3] = frontend::Operand::Integer(1),
            1 => {
                i.operands[0] = frontend::Operand::Register(frontend::Register {
                    class: frontend::RegisterClass::Vector,
                    index: 0,
                    count: 1,
                    special: None,
                })
            }
            _ => i.modifiers.push(frontend::Modifier {
                name: "idxen".into(),
                value: None,
            }),
        }
        assert!(lower::lower_kernel_in_module(&module, &kernel).is_err());
    }
}

#[test]
fn descriptor_policies_misalignment_and_other_targets_do_not_gain_support() {
    for (word, value) in [
        (9, 1u32 << 30),
        (9, 1u32 << 31),
        (11, 0),
        (11, 0x20001),
        (11, 0x820000),
        (10, 0),
    ] {
        let body = quad(8, 0x10000, 512, 0) + &format!("s_mov_b32 s{word},{value}\n") + LOAD;
        no_buffer_issue(&run(&body, 1), &body);
    }
    let body = quad(8, 0x10000, 512, 0) + "v_mov_b32 v4,1\n" + LOAD;
    no_buffer_issue(&run(&body, 1), &body);
    for target in ["gfx942", "gfx1250"] {
        let text = source(&copy_body(1)).replace("gfx950", target);
        let text = if target == "gfx1250" {
            text.replace(
                ".amdhsa_kernel k",
                ".amdhsa_kernel k\n.amdhsa_wavefront_size32 1",
            )
        } else {
            text
        };
        if let Ok(module) = frontend::parse(&text) {
            let result = analyze(&module, Some("k"), AnalysisConfig::new((1, 1, 1))).unwrap();
            assert!(result.symbolic_outputs().is_err());
            assert!(
                !result
                    .graph()
                    .amd_events()
                    .iter()
                    .any(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
            );
        }
    }
}
