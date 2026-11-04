//! Encoded halfword transport must preserve byte order without numeric bitcasts.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, analyze, frontend,
};
use volta_expr::ExprNode;

fn source(target: &str, body: &str) -> String {
    let (load, store, load_wait, store_wait, wave) = if target == "gfx1250" {
        (
            "global_load_b32",
            "global_store_b32",
            "s_wait_loadcnt 0",
            "s_wait_storecnt 0\ns_wait_xcnt 0",
            ".amdhsa_wavefront_size32 1",
        )
    } else {
        (
            "global_load_dword",
            "global_store_dword",
            "s_waitcnt vmcnt(0)",
            "s_waitcnt vmcnt(0)",
            "",
        )
    };
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n\
         s_mov_b32 s4,0x10000\ns_mov_b32 s5,0\ns_mov_b32 s6,0x20000\ns_mov_b32 s7,0\n\
         v_lshlrev_b32 v0,2,v0\n{load} v1,v0,s[4:5]\n{load_wait}\n{body}\n\
         {store} v0,v1,s[6:7]\n{store_wait}\ns_endpgm\n.size k,.-k\n\
         .amdhsa_kernel k\n.amdhsa_system_vgpr_workitem_id 0\n{wave}\n.end_amdhsa_kernel\n"
    )
}

fn run_width(target: &str, body: &str, block: u32, width: u64) -> AnalysisResult {
    let module = frontend::parse(&source(target, body)).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: width,
            len: 4 * u64::from(block) / width,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: width,
            len: 4 * u64::from(block) / width,
            kind: ArrayKind::Output,
        },
    ];
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn assert_identity(result: &AnalysisResult, elements: u64) {
    let actual = result.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(actual.outputs[0].1.len(), elements as usize);
    for index in 0..elements {
        let node = actual.arena.node(actual.element("out", index).unwrap());
        let ExprNode::InputElement {
            array,
            index: input,
        } = node
        else {
            panic!("transport changed encoded input: {node:?}");
        };
        assert_eq!(actual.arena.string(*array), "x");
        assert_eq!(*input, index);
    }
}

const SPLIT: &str = "v_and_b32_e32 v2,0xffff0000,v1\nv_and_b32_e32 v1,0xffff,v1";

#[test]
fn original_compiler_split_and_rejoin_preserves_every_half_across_waves() {
    for target in ["gfx950", "gfx1250"] {
        for block in [1, 17, 65] {
            for body in [
                format!("{SPLIT}\nv_or_b32_e32 v1,v2,v1"),
                "v_mov_b32 v3,0xffff\nv_mov_b32 v4,0xffff0000\nv_and_b32_e64 v2,v1,v3\nv_and_b32_e64 v1,v1,v4\nv_or_b32_e32 v1,v2,v1"
                    .into(),
                format!("{SPLIT}\nv_or_b32_e32 v2,v1,v2\nv_mov_b32 v1,v2"),
            ] {
                assert_identity(&run_width(target, &body, block, 2), 2 * u64::from(block));
            }
        }
    }
}

#[test]
fn zero_or_preserves_concrete_address_bits_and_encoded_values() {
    for target in ["gfx950", "gfx1250"] {
        let body = format!("{SPLIT}\nv_or_b32 v1,v2,v1\nv_or_b32 v0,0,0\nv_or_b32 v1,0,v1");
        assert_identity(&run_width(target, &body, 1, 2), 2);
    }
}

#[test]
fn high_mask_clears_low_storage_half_without_decoding_high_data() {
    for target in ["gfx950", "gfx1250"] {
        let result = run_width(target, "v_and_b32 v1,0xffff0000,v1", 17, 2);
        let output = result.symbolic_outputs().unwrap();
        assert_eq!(output.outputs[0].1.len(), 34);
        for index in 0..34 {
            let expr = output.element("out", index).unwrap();
            if index % 2 == 0 {
                assert_eq!(output.arena.as_int_const(expr), Some(0));
            } else {
                let ExprNode::InputElement {
                    array,
                    index: actual,
                } = output.arena.node(expr)
                else {
                    panic!("high storage half changed");
                };
                assert_eq!(output.arena.string(*array), "x");
                assert_eq!(*actual, index);
            }
        }
    }
}

#[test]
fn half_transport_does_not_enable_arbitrary_bitwise_float_operations() {
    for target in ["gfx950", "gfx1250"] {
        for (body, reason) in [
            (
                "v_and_b32 v1,0x7fff0000,v1".to_owned(),
                "cannot be reinterpreted",
            ),
            (
                "v_or_b32 v1,v1,v1".to_owned(),
                "OR of overlapping encoded halves",
            ),
            (
                format!("{SPLIT}\nv_or_b32 v1,v1,v2\nv_add_u32 v1,0,v1"),
                "cannot be reinterpreted",
            ),
        ] {
            let result = run_width(target, &body, 1, 2);
            let error = result.symbolic_outputs().unwrap_err().to_string();
            assert!(error.contains(reason), "{error}");
        }
        // A numerical F32 result is not an encoded pair of F16/BF16 values.
        let body = "v_add_f32 v1,0,v1\nv_and_b32 v1,0xffff0000,v1";
        assert!(run_width(target, body, 1, 4).symbolic_outputs().is_err());
    }
}

#[test]
fn empty_exec_skips_undefined_packed_operands() {
    for target in ["gfx950", "gfx1250"] {
        let (disable, enable) = if target == "gfx1250" {
            ("s_mov_b32 exec_lo,0", "s_mov_b32 exec_lo,1")
        } else {
            ("s_mov_b64 exec,0", "s_mov_b64 exec,1")
        };
        let body = format!("{disable}\nv_and_b32 v3,0xffff0000,v99\nv_or_b32 v3,v98,v99\n{enable}");
        assert_identity(&run_width(target, &body, 1, 2), 2);
    }
}

#[test]
fn selected_high_half_does_not_resurrect_undefined_true16_bits() {
    let result = run_width(
        "gfx1250",
        "v_cvt_f16_f32 v4,1.0\nv_and_b32 v1,0xffff0000,v4",
        1,
        2,
    );
    let error = result.symbolic_outputs().unwrap_err().to_string();
    assert!(
        error.contains("AND observes an undefined high half"),
        "{error}"
    );
}

#[test]
fn masking_discards_undefined_true16_upper_bits_before_reassembly() {
    let result = run_width(
        "gfx1250",
        "v_cvt_f16_f32 v4,1.0\nv_and_b32 v4,0xffff,v4\nv_and_b32 v2,0xffff0000,v1\nv_or_b32 v1,v2,v4",
        1,
        2,
    );
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(output.outputs[0].1.len(), 2);
    assert_eq!(
        output.arena.as_f64(output.element("out", 0).unwrap()),
        Some(1.0)
    );
    let ExprNode::InputElement { array, index } =
        output.arena.node(output.element("out", 1).unwrap())
    else {
        panic!("high half changed");
    };
    assert_eq!(output.arena.string(*array), "x");
    assert_eq!(*index, 1);
}
