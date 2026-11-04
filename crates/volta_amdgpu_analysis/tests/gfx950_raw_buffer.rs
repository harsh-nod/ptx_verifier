//! CDNA4 raw DWORD resources use their own layout and independent allocation bounds.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend, lower,
};
use volta_expr::ExprNode;
use volta_graph::AmdEventKind;

const LOAD: &str = "buffer_load_dword v1,v2,s[8:11],0 offen";
const STORE: &str = "buffer_store_dword v1,v2,s[12:15],0 offen";

fn quad(first: u32, words: [u32; 4]) -> String {
    words
        .into_iter()
        .enumerate()
        .map(|(i, word)| format!("s_mov_b32 s{},{}\n", first + i as u32, word))
        .collect()
}

fn resource(base: u64, bytes: u32, stride: u32) -> [u32; 4] {
    [
        base as u32,
        (base >> 32) as u32 | (stride << 16),
        bytes,
        0x20000,
    ]
}

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.text\n.type k,@function\nk:\nv_lshlrev_b32 v2,2,v0\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    )
}

fn run_at(body: &str, block: u32, input_base: u64, input_len: u64) -> AnalysisResult {
    let module = frontend::parse(&source(body)).unwrap();
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
            len: u64::from(block),
            kind: ArrayKind::Output,
        },
    ];
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn run(body: &str, block: u32) -> AnalysisResult {
    run_at(body, block, 0x10000, 64)
}

fn copy_body(input: [u32; 4], offset: u32, immediate: u32) -> String {
    quad(8, input)
        + &quad(12, resource(0x20000, 256, 0))
        + &format!(
            "v_mov_b32 v2,{offset}\n{LOAD} offset:{immediate}\ns_waitcnt vmcnt(0)\nv_mov_b32 v2,0\n{STORE}\ns_waitcnt vmcnt(0)"
        )
}

fn assert_input_indices(result: &AnalysisResult, expected: &[u64]) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), expected.len());
    for (index, expected) in expected.iter().enumerate() {
        let ExprNode::InputElement {
            array,
            index: actual,
        } = outputs
            .arena
            .node(outputs.element("out", index as u64).unwrap())
        else {
            panic!("input transport")
        };
        assert_eq!(outputs.arena.string(*array), "x");
        assert_eq!(*actual, *expected);
    }
}

fn assert_no_buffer_issue(result: &AnalysisResult, text: &str) {
    assert!(result.symbolic_outputs().is_err());
    let module = frontend::parse(&source(text)).unwrap();
    for (pc, i) in module.kernels[0]
        .instructions
        .iter()
        .enumerate()
        .filter(|(_, i)| i.mnemonic.starts_with("buffer_"))
    {
        assert!(
            !result.graph().amd_events().iter().any(|r| matches!(
                r.kind,
                AmdEventKind::MemoryIssue { .. }
            ) && result.graph().event(r.event).pc
                == Some(volta_graph::ProgramPoint(pc as u32))),
            "invented issue at {}",
            i.mnemonic
        );
    }
}

#[test]
fn cdna4_base48_byte_bounds_and_raw_stride_are_not_cdna5_fields() {
    for stride in [0, 1, 0x3fff] {
        for (vector, immediate, expected) in [(0, 0, 0), (4, 0, 1), (8, 4, 3), (0, 4092, 1023)] {
            let body = copy_body(resource(0x1_0001_0000, 4096, stride), vector, immediate);
            assert_input_indices(&run_at(&body, 1, 0x1_0001_0000, 1024), &[expected]);
        }
        // Alignment applies to the final byte address. Unlike SMEM, do not
        // discard each component's low2 bits before adding them.
        let body = copy_body(resource(0x10000, 8192, stride), 1, 4095);
        assert_input_indices(&run_at(&body, 1, 0x10000, 2048), &[1024]);
    }
    let body = quad(8, resource(0x10000, 256, 0))
        + &quad(12, resource(0x20000, 256, 0))
        + &format!("{LOAD}\ns_waitcnt vmcnt(0)\n{STORE}\ns_waitcnt vmcnt(0)");
    assert_input_indices(&run(&body, 64), &(0..64).collect::<Vec<_>>());
}

#[test]
fn address_destination_alias_and_sparse_exec_preserve_inactive_words() {
    let body = quad(8, resource(0x10000, 256, 0))
        + &quad(12, resource(0x20000, 16, 0))
        + "v_mov_b32 v1,v2\ns_mov_b64 exec,5\nbuffer_load_dword v2,v2,s[8:11],0 offen\ns_waitcnt vmcnt(0)\nv_mov_b32 v1,v2\ns_mov_b64 exec,15\nv_lshlrev_b32 v2,2,v0\n"
        + STORE
        + "\ns_waitcnt vmcnt(0)";
    let result = run(&body, 4);
    let outputs = result.symbolic_outputs().unwrap();
    for lane in 0..4 {
        let id = outputs.element("out", lane).unwrap();
        if lane % 2 == 1 {
            assert_eq!(outputs.arena.as_int_const(id), Some((lane * 4) as i64));
        } else {
            assert!(
                matches!(outputs.arena.node(id), ExprNode::InputElement { index, .. } if *index == lane)
            );
        }
    }
}

#[test]
fn empty_exec_never_reads_unknown_descriptors_offsets_or_data() {
    let body = "s_mov_b64 exec,0\n".to_owned()
        + LOAD
        + "\n"
        + STORE
        + "\ns_mov_b64 exec,1\nv_mov_b32 v1,7\nv_add_u32 v1,0,v1\n"
        + &quad(12, resource(0x20000, 4, 0))
        + STORE
        + "\ns_waitcnt vmcnt(0)";
    let result = run(&body, 1);
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(
        outputs
            .arena
            .as_int_const(outputs.element("out", 0).unwrap()),
        Some(7)
    );
    assert_eq!(
        result
            .graph()
            .amd_events()
            .iter()
            .filter(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
            .count(),
        1
    );
}

#[test]
fn every_descriptor_word_address_and_store_source_must_be_defined_before_issue() {
    for missing in 8..12 {
        let body = quad(8, resource(0x10000, 256, 0))
            .lines()
            .filter(|l| !l.starts_with(&format!("s_mov_b32 s{missing},")))
            .collect::<Vec<_>>()
            .join("\n")
            + "\n"
            + LOAD;
        let result = run(&body, 1);
        assert!(
            result
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized")
        );
        assert_no_buffer_issue(&result, &body);
    }
    for body in [
        quad(8, resource(0x10000, 256, 0)) + "buffer_load_dword v1,v20,s[8:11],0 offen",
        quad(12, resource(0x20000, 256, 0)) + STORE,
    ] {
        let result = run(&body, 1);
        assert!(
            result
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized")
        );
        assert_no_buffer_issue(&result, &body);
    }
}

#[test]
fn partially_initialized_abi_bits_cannot_be_buffer_addresses_or_stored_data() {
    for consumer in [
        format!("s_mov_b32 s8,s20\n{LOAD}"),
        format!("v_mov_b32 v2,s20\n{LOAD}"),
        format!("v_mov_b32 v1,s20\n{STORE}"),
    ] {
        let body = quad(8, resource(0x10000, 256, 0))
            + &quad(12, resource(0x20000, 4, 0))
            + "s_load_dword s20,s[0:1],0\ns_waitcnt lgkmcnt(0)\n"
            + &consumer;
        let text = source(&body).replace(
            ".amdhsa_kernel k",
            ".amdhsa_kernel k\n.amdhsa_user_sgpr_kernarg_segment_ptr 1\n.amdhsa_kernarg_size 4",
        ) + r#"
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: byte
        .offset: 0
        .size: 1
        .value_kind: by_value
...
.end_amdgpu_metadata
"#;
        let module = frontend::parse(&text).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.params.push(ParamValue::Bytes(vec![7]));
        config.arrays = vec![
            ArrayDef {
                name: "x".into(),
                base: 0x10000,
                elem_width: 4,
                len: 64,
                kind: ArrayKind::Input,
            },
            ArrayDef {
                name: "out".into(),
                base: 0x20000,
                elem_width: 4,
                len: 1,
                kind: ArrayKind::Output,
            },
        ];
        let result = analyze(&module, Some("k"), config).unwrap();
        assert!(
            result
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("undefined")
        );
        assert_no_buffer_issue(&result, &body);
    }
}

#[test]
fn resource_faults_bad_flags_and_address_domain_fail_before_any_issue() {
    for input in [
        resource(0x10000, 0, 0),
        resource(0x10000, 3, 0),
        resource(0x10000, 2, 0),
        resource(0x10000, 256, 0x4000),
        resource(0x10000, 256, 0x8000),
        [0x10000, 0, 256, 0],
        [0x10000, 0, 256, 0x20001],
        [0x10000, 0, 256, 0x820000],
        [0x10000, 0, 256, 0x40020000],
        resource((1u64 << 48) - 4, 256, 0),
    ] {
        let body = copy_body(input, 4, 0);
        assert_no_buffer_issue(&run(&body, 1), &body);
    }
    for (vector, immediate) in [(0xffff_fffcu32, 4), (256, 0), (1, 0)] {
        let body = copy_body(resource(0x10000, 256, 0), vector, immediate);
        assert_no_buffer_issue(&run(&body, 1), &body);
    }
    let body = quad(12, resource(0x20000, 4, 0)) + "v_mov_b32 v1,7\nv_mov_b32 v2,4\n" + STORE;
    assert_no_buffer_issue(&run(&body, 1), &body);
}

#[test]
fn broader_resource_bound_never_replaces_a_real_allocation_bound() {
    let body = copy_body(resource(0x10000, 256, 0), 4, 0);
    let result = run_at(&body, 1, 0x10000, 1);
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("out-of-bounds")
    );
    assert_no_buffer_issue(&result, &body);
    // A later active lane failing the real allocation must not leave an earlier
    // lane's issue/effects behind for the same hardware instruction.
    let body = quad(8, resource(0x10000, 256, 0)) + LOAD;
    assert_no_buffer_issue(&run_at(&body, 2, 0x10000, 1), &body);
}

#[test]
fn other_targets_wider_encodings_and_nonselected_operand_modes_stay_unsupported() {
    for operation in [
        LOAD.replace("dword", "dword_e64"),
        LOAD.replace("v1", "a1"),
        LOAD.replace(",0 offen", ",s20 offen"),
        LOAD.replace(",0 offen", ",1 offen"),
        LOAD.replace("offen", "idxen"),
        LOAD.replace("offen", "offen glc"),
        LOAD.replace("offen", "offen lds"),
        LOAD.replace("dword v1", "dwordx3 v[0:2]"),
        STORE.replace("dword v1", "dwordx4 v[0:3]"),
        format!("{LOAD} offset:4096"),
        format!("{LOAD} offset:-1"),
    ] {
        let body = quad(8, resource(0x10000, 256, 0))
            + &quad(12, resource(0x20000, 256, 0))
            + "v_mov_b32 v1,7\ns_mov_b32 s20,0\n"
            + &operation;
        if frontend::parse(&source(&body)).is_err() {
            continue;
        }
        let result = run(&body, 1);
        assert_no_buffer_issue(&result, &body);
    }
    for target in ["gfx942", "gfx1250"] {
        let text = source(&(quad(8, resource(0x10000, 256, 0)) + LOAD)).replace("gfx950", target);
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

#[test]
fn selected_form_validation_also_covers_empty_exec_unreachable_code_and_direct_ast() {
    for bad in [
        LOAD.replace(",0 offen", ",s20 offen"),
        LOAD.replace(",0 offen", ",1 offen"),
        LOAD.replace("offen", "idxen"),
        LOAD.replace("offen", "offen glc"),
        LOAD.replace("offen", "offen lds"),
        LOAD.replace("v1", "a1"),
        LOAD.replace("v2", "v[2:3]"),
        format!("{LOAD} offset:4096"),
        format!("{LOAD} offset:-1"),
    ] {
        for body in [
            format!("s_mov_b64 exec,0\n{bad}"),
            format!("s_branch done\n{bad}\ndone:"),
        ] {
            assert!(frontend::parse(&source(&body)).is_err(), "{body}");
        }
    }
    let module = frontend::parse(&source(LOAD)).unwrap();
    for mutate in 0..4 {
        let mut kernel = module.kernels[0].clone();
        let i = kernel
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "buffer_load_dword")
            .unwrap();
        match mutate {
            0 => i.operands[3] = frontend::Operand::Integer(1),
            1 => i.modifiers[0].name = "idxen".into(),
            2 => i.modifiers.push(frontend::Modifier {
                name: "offset".into(),
                value: Some("4096".into()),
            }),
            _ => i.operands[1] = frontend::Operand::Integer(0),
        }
        assert!(lower::lower_kernel_in_module(&module, &kernel).is_err());
    }
}
