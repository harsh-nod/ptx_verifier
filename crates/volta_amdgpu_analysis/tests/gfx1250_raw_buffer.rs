//! Raw CDNA5 descriptors retain their hardware fields and independent allocation bounds.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, analyze, frontend, lower,
};
use volta_expr::ExprNode;
use volta_graph::AmdEventKind;

fn quad(first: u32, words: [u32; 4]) -> String {
    words
        .into_iter()
        .enumerate()
        .map(|(i, word)| format!("s_mov_b32 s{},{}\n", first + i as u32, word))
        .collect()
}

fn resource(base: u64, records: u64, word3_flags: u32) -> [u32; 4] {
    let raw = u128::from(base) | (u128::from(records) << 57);
    [
        raw as u32,
        (raw >> 32) as u32,
        (raw >> 64) as u32,
        (raw >> 96) as u32 | word3_flags,
    ]
}

fn source(body: &str, input_base: u64) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_mov_b32 s4,{}
s_mov_b32 s5,{}
v_lshlrev_b32 v1,4,v0
{body}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_system_vgpr_workitem_id 0
.end_amdhsa_kernel
"#,
        input_base as u32,
        (input_base >> 32) as u32,
    )
}

fn run(body: &str, block: u32, input_base: u64, input_len: u64) -> AnalysisResult {
    let module = frontend::parse(&source(body, input_base)).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "input".into(),
            base: input_base,
            elem_width: 4,
            len: input_len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: u64::from(block) * 4,
            kind: ArrayKind::Output,
        },
    ];
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

const STORE: &str = "s_wait_loadcnt 0\ns_wait_xcnt 0\nbuffer_store_b64 v[2:3],v1,s[16:19],null offen\nbuffer_store_b64 v[4:5],v1,s[16:19],null offen offset:8\ns_wait_storecnt 0\ns_wait_xcnt 0";

fn copy_body(input: [u32; 4], vector_offset: u32, immediate: u32) -> String {
    quad(12, input)
        + &quad(16, resource(0x20000, 16, 0))
        + &format!(
            "v_mov_b32 v0,{vector_offset}\nbuffer_load_b128 v[2:5],v0,s[12:15],null offen offset:{immediate}\n{STORE}"
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
        assert_eq!(outputs.arena.string(*array), "input");
        assert_eq!(*actual, *expected);
    }
}

#[test]
fn exact_fields_component_offsets_and_raw_stride_scale_do_not_reinterpret_the_base() {
    // num_records low7 bits live above base bit56, not in a legacy word2 field.
    assert_eq!(resource(0x10000, 64, 0), [0x10000, 0x8000_0000, 0, 0]);
    for flags in [0, 0x0002_0000, 0x03ff_f000, 0x0fff_f000] {
        for (vector, immediate) in [(0, 0), (16, 0), (32, 16)] {
            let result = run(
                &copy_body(resource(0x10000, 64, flags), vector, immediate),
                1,
                0x10000,
                16,
            );
            let first = u64::from(vector + immediate) / 4;
            assert_input_indices(&result, &[first, first + 1, first + 2, first + 3]);
        }
    }
}

#[test]
fn legacy_shaped_words_keep_expanded_hardware_bounds_and_real_array_bounds() {
    // HK's raw {pointer64, range32, config32} words are interpreted as written:
    // word2=1 means128 bytes of records, and config0x20000 means raw stride32.
    let raw = [0x10000, 0, 1, 0x20000];
    assert_input_indices(
        &run(&copy_body(raw, 64, 0), 1, 0x10000, 32),
        &[16, 17, 18, 19],
    );
    let result = run(&copy_body(raw, 64, 0), 1, 0x10000, 16);
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("out-of-bounds")
    );
}

#[test]
fn load_address_alias_and_sparse_exec_preserve_complete_inactive_data() {
    let body = quad(12, resource(0x10000, 128, 0))
        + &quad(16, resource(0x20000, 64, 0))
        + "global_load_b128 v[2:5],v1,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nv_add_nc_u32 v2,16,v1\ns_mov_b32 exec_lo,5\nbuffer_load_b128 v[2:5],v2,s[12:15],null offen\ns_wait_loadcnt 0\ns_wait_xcnt 0\ns_mov_b32 exec_lo,15\n"
        + STORE;
    let result = run(&body, 4, 0x10000, 32);
    let outputs = result.symbolic_outputs().unwrap();
    for lane in 0..4 {
        for word in 0..4 {
            let index = lane * 4 + word;
            // v2 is both the offset and first loaded destination. Inactive
            // lanes preserve that exact integer offset along with words1-3.
            if lane % 2 == 1 && word == 0 {
                assert_eq!(
                    outputs
                        .arena
                        .as_int_const(outputs.element("out", index).unwrap()),
                    Some(16 + lane as i64 * 16)
                );
                continue;
            }
            let ExprNode::InputElement {
                array,
                index: actual,
            } = outputs.arena.node(outputs.element("out", index).unwrap())
            else {
                panic!("transport lane{lane}/word{word}")
            };
            assert_eq!(outputs.arena.string(*array), "input");
            assert_eq!(*actual, index + if lane % 2 == 0 { 4 } else { 0 });
        }
    }
}

#[test]
fn empty_exec_observes_neither_uninitialized_descriptors_nor_addresses_or_store_data() {
    let body = "global_load_b128 v[2:5],v1,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\ns_mov_b32 exec_lo,0\nbuffer_load_b128 v[6:9],v10,s[12:15],null offen\nbuffer_store_b64 v[20:21],v22,s[24:27],null offen\ns_mov_b32 exec_lo,1\n".to_owned()
        + &quad(16, resource(0x20000, 16, 0)) + STORE;
    let result = run(&body, 1, 0x10000, 4);
    assert_input_indices(&result, &[0, 1, 2, 3]);
    let module = frontend::parse(&source(&body, 0x10000)).unwrap();
    let buffer_pcs: Vec<_> = module.kernels[0]
        .instructions
        .iter()
        .enumerate()
        .filter(|(_, i)| i.mnemonic.starts_with("buffer_"))
        .map(|(pc, _)| pc as u32)
        .collect();
    // There are still real output stores, but the two uninitialized inactive
    // instructions produce no issue and no invented memory footprint.
    assert_eq!(buffer_pcs.len(), 4);
    for pc in &buffer_pcs[..2] {
        assert!(!result.graph().amd_events().iter().any(|r| matches!(
            r.kind,
            AmdEventKind::MemoryIssue { .. }
        ) && result.graph().event(r.event).pc
            == Some(volta_graph::ProgramPoint(*pc))));
    }
}

#[test]
fn resource_oob_unbound_and_nonraw_fields_refuse_without_fabricated_effects() {
    for words in [
        resource(0x10000, 12, 0),
        resource(0x10000, 0, 0),
        resource(0x10000, (1u64 << 45) - 1, 0),
        resource(0x10000, 64, 1 << 6),
        resource(0x10000, 64, 1 << 28),
        resource(0x10000, 64, 1 << 29),
        resource(0x10000, 64, 1 << 30),
    ] {
        let result = run(&copy_body(words, 0, 0), 1, 0x10000, 16);
        assert!(result.symbolic_outputs().is_err());
        assert!(
            !result
                .graph()
                .amd_events()
                .iter()
                .any(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
        );
    }
    let body = quad(16, resource(0x20000, 4, 0))
        + "v_mov_b32 v0,0\nv_mov_b32 v2,0\nv_mov_b32 v3,0\nbuffer_store_b64 v[2:3],v0,s[16:19],null offen";
    let result = run(&body, 1, 0x10000, 16);
    assert!(result.symbolic_outputs().is_err());
    assert!(
        !result
            .graph()
            .amd_events()
            .iter()
            .any(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
    );
}

#[test]
fn observed_unknown_descriptor_address_and_store_data_words_are_never_fabricated() {
    for missing in 12..16 {
        let body = copy_body(resource(0x10000, 64, 0), 0, 0)
            .lines()
            .filter(|line| !line.starts_with(&format!("s_mov_b32 s{missing},")))
            .collect::<Vec<_>>()
            .join("\n");
        assert!(
            run(&body, 1, 0x10000, 16)
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized")
        );
    }
    let body =
        copy_body(resource(0x10000, 64, 0), 0, 0).replace("v_mov_b32 v0,0", "v_mov_b32 v0,v20");
    assert!(
        run(&body, 1, 0x10000, 16)
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("uninitialized")
    );
    for missing in 2..4 {
        let body = quad(16, resource(0x20000, 16, 0))
            + &format!(
                "v_mov_b32 v0,0\nv_mov_b32 v{},1\nbuffer_store_b64 v[2:3],v0,s[16:19],null offen",
                if missing == 2 { 3 } else { 2 }
            );
        assert!(
            run(&body, 1, 0x10000, 16)
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized")
        );
    }
}

#[test]
fn offsets_are_unsigned_and_never_wrap_to_a_small_valid_allocation() {
    let result = run(
        &copy_body(resource(0x10000, 1u64 << 40, 0), 0xffff_fff0, 32),
        1,
        0x10000,
        16,
    );
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("out-of-bounds")
    );
    let base = (1u64 << 57) - 8;
    let result = run(&copy_body(resource(base, 128, 0), 0, 0), 1, base, 16);
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("57-bit")
    );
    let result = run(&copy_body(resource(0x10000, 64, 0), 2, 0), 1, 0x10000, 16);
    assert!(result.symbolic_outputs().is_err());
}

#[test]
fn exact_operands_flags_and_targets_also_gate_direct_ast_construction() {
    let valid = "buffer_load_b128 v[2:5],v0,s[12:15],null offen";
    for legal in [
        "buffer_load_b128 v[252:255],v255,s[100:103],null offen offset:8388607",
        "buffer_store_b64 v[254:255],v255,s[100:103],null offen offset:8388607",
    ] {
        let module = frontend::parse(&source(legal, 0x10000)).unwrap();
        lower::lower_module_kernel(&module, "k").unwrap();
    }
    for invalid in [
        valid.replace("b128", "b128_e32"),
        valid.replace("b128", "b128_e64"),
        valid.replace("v[2:5]", "v[2:3]"),
        valid.replace("v[2:5]", "a[2:5]"),
        valid.replace("v[2:5]", "v[254:257]"),
        valid.replace("v0", "v256"),
        valid.replace("v0", "0"),
        valid.replace("s[12:15]", "s[12:13]"),
        valid.replace("s[12:15]", "0"),
        valid.replace("null", "s20"),
        valid.replace("null", "0"),
        valid.replace("offen", "idxen"),
        valid.replace("offen", "offen idxen"),
        valid.replace("offen", "offen lds"),
        valid.replace("offen", "offen glc"),
        format!("{valid} offset:-1"),
        format!("{valid} offset:8388608"),
        format!("{valid} scale_offset"),
    ] {
        assert!(
            frontend::parse(&source(&invalid, 0x10000)).is_err(),
            "{invalid}"
        );
    }
    for target in ["gfx942", "gfx950"] {
        let text = format!(
            ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n{valid}\ns_endpgm\n.size k,.-k"
        );
        assert!(frontend::parse(&text).is_err());
    }
    let module = frontend::parse(&source(valid, 0x10000)).unwrap();
    for mutate in 0..3 {
        let mut kernel = module.kernels[0].clone();
        let i = kernel
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "buffer_load_b128")
            .unwrap();
        match mutate {
            0 => i.operands[3] = frontend::Operand::Integer(0),
            1 => i.modifiers[0].name = "idxen".into(),
            _ => i.mnemonic += "_e32",
        }
        assert!(lower::lower_kernel_in_module(&module, &kernel).is_err());
    }
}
