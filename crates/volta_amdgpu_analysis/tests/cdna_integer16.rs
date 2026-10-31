//! Selected CDNA narrow integer encodings and their observed-bit boundary.
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend, lower,
};

fn source(target: &str, body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
s_load_dwordx2 s[4:5],s[0:1],0
s_waitcnt lgkmcnt(0)
{body}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}
fn config(n: u32) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((n, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: n.into(),
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}
fn output(target: &str, body: &str, expected: &[i64]) {
    let body = body.replace(
        "global_store_dword",
        "v_add_u32 v1,0,v1\nglobal_store_dword",
    );
    let module = frontend::parse(&source(target, &body)).unwrap();
    let result = analyze(&module, Some("k"), config(expected.len() as u32)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), expected.len());
    for (index, expected) in expected.iter().enumerate() {
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index as u64).unwrap()),
            Some(*expected),
            "{target} {body}"
        );
    }
    result.graph().validate().unwrap();
}
const STORE: &str = "v_mov_b32 v0,0\nglobal_store_dword v0,v1,s[4:5]";

#[test]
fn unchanged_compiler_modules_parse_and_selected_entries_lower() {
    for (target, text) in [
        (
            "gfx942",
            include_str!("../../../tests/amdgpu/compiler-corpus/fixtures/gfx942-portable.s"),
        ),
        (
            "gfx950",
            include_str!("../../../tests/amdgpu/compiler-corpus/fixtures/gfx950-portable.s"),
        ),
    ] {
        let module = frontend::parse(text).unwrap();
        assert!(
            module.kernels.iter().any(|k| k.name == "portable_softmax"),
            "{target}"
        );
        for entry in [
            "portable_relu",
            "portable_reduction",
            "portable_rmsnorm",
            "portable_gemm",
            "portable_flash_attention",
        ] {
            lower::lower_module_kernel(&module, entry).unwrap();
        }
    }
}

#[test]
fn legacy_shift_observes_low16_data_and_low4_count() {
    for target in ["gfx942", "gfx950"] {
        for encoding in ["_e32", "_e64", ""] {
            for (count, expected) in [
                (0, 0x8001),
                (1, 2),
                (15, 0x8000),
                (16, 0x8001),
                (17, 2),
                (0xffff_ffffu32, 0x8000),
            ] {
                output(
                    target,
                    &format!(
                        "v_mov_b32 v2,0xdead8001\nv_mov_b32 v3,{count}\nv_lshlrev_b16{encoding} v1,v3,v2\nv_and_b32 v1,0xffff,v1\n{STORE}"
                    ),
                    &[expected],
                );
            }
        }
    }
}

#[test]
fn bitop3_truth_table_uses_s0_s1_s2_bit_order() {
    for table in 0u32..256 {
        // Each of the eight truth-table indices occurs twice in these16 bits.
        let a = 0xf0f0u32;
        let b = 0xccccu32;
        let c = 0xaaaau32;
        let expected = (0..16).fold(0u32, |value, bit| {
            let index = (((a >> bit) & 1) << 2) | (((b >> bit) & 1) << 1) | ((c >> bit) & 1);
            value | (((table >> index) & 1) << bit)
        });
        output(
            "gfx950",
            &format!(
                "v_mov_b32 v2,0xbeeff0f0\nv_mov_b32 v3,0xdeadcccc\nv_mov_b32 v4,0x1234aaaa\nv_bitop3_b16 v1,v2,v3,v4 bitop3:{table}\nv_and_b32 v1,0xffff,v1\n{STORE}"
            ),
            &[expected.into()],
        );
    }
}

#[test]
fn u16_comparison_ignores_high_bits_and_accepts_defined_narrow_results() {
    for target in ["gfx942", "gfx950"] {
        for (a, b, expected) in [
            (0xdead0001u32, 0xbeef0001u32, 0),
            (0xdead0001, 0xdead0000, 7),
        ] {
            output(
                target,
                &format!(
                    "v_mov_b32 v2,{a}\nv_mov_b32 v3,{b}\nv_cmp_ne_u16_e32 vcc,v2,v3\nv_cndmask_b32_e64 v1,0,7,vcc\n{STORE}"
                ),
                &[expected],
            );
        }
        output(
            target,
            &format!(
                "v_mov_b32 v2,1\nv_lshlrev_b16_e32 v2,1,v2\nv_cmp_ne_u16_e32 vcc,0,v2\nv_cndmask_b32_e64 v1,0,7,vcc\n{STORE}"
            ),
            &[7],
        );
    }
}

#[test]
fn inactive_lanes_preserve_destination_and_exec_zero_does_not_read_sources() {
    for target in ["gfx942", "gfx950"] {
        output(
            target,
            "v_mov_b32 v1,7\nv_mov_b32 v2,1\ns_mov_b64 exec,1\nv_lshlrev_b16_e32 v1,1,v2\ns_mov_b64 exec,3\nv_and_b32 v1,0xffff,v1\nv_lshlrev_b32 v0,2,v0\nglobal_store_dword v0,v1,s[4:5]",
            &[2, 7],
        );
        output(
            target,
            &format!(
                "s_mov_b64 exec,0\nv_lshlrev_b16_e32 v1,v8,v9\ns_mov_b64 exec,1\nv_mov_b32 v1,7\n{STORE}"
            ),
            &[7],
        );
    }
    output(
        "gfx950",
        &format!(
            "s_mov_b64 exec,0\nv_bitop3_b16 v1,v8,v9,v10 bitop3:0xc8\ns_mov_b64 exec,1\nv_mov_b32 v1,7\n{STORE}"
        ),
        &[7],
    );
}

#[test]
fn unproved_upper_bits_and_undefined_observed_inputs_refuse() {
    for (target, operation) in [
        ("gfx942", "v_lshlrev_b16_e32 v1,1,v2"),
        ("gfx950", "v_lshlrev_b16_e32 v1,1,v2"),
        ("gfx950", "v_bitop3_b16 v1,v2,v2,v2 bitop3:0xc8"),
    ] {
        for body in [
            format!("v_mov_b32 v2,1\n{operation}\n{STORE}"),
            format!("{operation}\nv_and_b32 v1,0xffff,v1\n{STORE}"),
        ] {
            let module = frontend::parse(&source(target, &body)).unwrap();
            let refused = match analyze(&module, Some("k"), config(1)) {
                Err(_) => true,
                Ok(result) => result.symbolic_outputs().is_err(),
            };
            assert!(refused, "{target}: {body}");
        }
    }
}

#[test]
fn selected_encodings_refuse_unrepresentable_forms_in_text_and_direct_ast() {
    for target in ["gfx942", "gfx950"] {
        for bad in [
            "v_lshlrev_b16_e32 v1,1,2",
            "v_lshlrev_b16_e64 v1,0x1234,v2",
            "v_lshlrev_b16_e32 v1,65536,v2",
            "v_lshlrev_b16_e32 v1,1.0,v2",
            "v_lshlrev_b16_e64 v1,s2,s3",
            "v_lshlrev_b16_e32 v1,1,v2 clamp",
            "v_cmp_ne_u16_e32 s[2:3],0,v2",
            "v_cmp_u_f32_e32 s[2:3],v1,v2",
            "v_cmp_u_f32_e32 vcc,v1,s2",
            "v_cmp_u_f32_e64 vcc,s2,s3",
            "v_cmp_u_f32_e64 vcc,v1,v2 clamp",
            "v_bitop3_b16_e32 v1,v2,v3,v4 bitop3:0xc8",
            "v_bitop3_b16 v1,v2,v3,v4 bitop3:256",
            "v_bitop3_b16 v1,v2,v3,v4",
        ] {
            assert!(
                frontend::parse(&source(target, bad)).is_err(),
                "{target}: {bad}"
            );
        }
        let mut module = frontend::parse(&source(target, "v_lshlrev_b16_e32 v1,1,v2")).unwrap();
        let operation = module.kernels[0]
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "v_lshlrev_b16_e32")
            .unwrap();
        operation.operands[2] = frontend::Operand::Integer(2);
        assert!(lower::lower_module_kernel(&module, "k").is_err());
    }
    assert!(frontend::parse(&source("gfx942", "v_bitop3_b16 v1,v2,v3,v4 bitop3:0xc8")).is_err());
}

#[test]
fn symbolic_u16_comparison_cannot_observe_high_input_bits() {
    use volta_expr::{ExprArena, ExprId, ExprNode};
    // Independent substitution oracle for this single comparison/select DAG.
    fn evaluate(arena: &ExprArena, expression: ExprId, input: i64) -> i64 {
        match *arena.node(expression) {
            ExprNode::IntConst(n) => n,
            ExprNode::BoolConst(b) => i64::from(b),
            ExprNode::InputElement { index: 0, .. } => input,
            ExprNode::BitAnd(a, b) => evaluate(arena, a, input) & evaluate(arena, b, input),
            ExprNode::Ne(a, b) => i64::from(evaluate(arena, a, input) != evaluate(arena, b, input)),
            ExprNode::Select(condition, a, b) => evaluate(
                arena,
                if evaluate(arena, condition, input) != 0 {
                    a
                } else {
                    b
                },
                input,
            ),
            ref other => panic!("unexpected comparison expression {other:?}"),
        }
    }
    for target in ["gfx1250", "gfx942", "gfx950"] {
        let mut source = source(target, "v_mov_b32 v0,0\nglobal_load_dword v2,v0,s[6:7]\ns_waitcnt vmcnt(0)\nv_cmp_ne_u16_e32 vcc,0,v2\nv_cndmask_b32_e64 v1,0,7,vcc\nv_add_u32 v1,0,v1\nglobal_store_dword v0,v1,s[4:5]")
            .replace("s_load_dwordx2 s[4:5]", "s_load_dwordx4 s[4:7]")
            .replace(".amdhsa_kernarg_size 8", ".amdhsa_kernarg_size 16")
            .replace("...\n.end_amdgpu_metadata", "      - .name: x\n        .offset: 8\n        .size: 8\n        .value_kind: global_buffer\n...\n.end_amdgpu_metadata");
        if target == "gfx1250" {
            source = source
                .replace("s_load_dwordx4", "s_load_b128")
                .replace("s_waitcnt lgkmcnt(0)", "s_wait_kmcnt 0")
                .replace("s_waitcnt vmcnt(0)", "s_wait_loadcnt 0")
                .replace("global_load_dword", "global_load_b32")
                .replace("global_store_dword", "global_store_b32")
                .replace("v_add_u32", "v_add_nc_u32")
                .replace("vcc", "vcc_lo")
                .replace("s_endpgm", "s_wait_storecnt 0\ns_wait_xcnt 0\ns_endpgm")
                .replace(
                    ".amdhsa_kernel k",
                    ".amdhsa_kernel k\n.amdhsa_wavefront_size32 1",
                );
        }
        let module = frontend::parse(&source).unwrap();
        let mut config = config(1);
        config.arrays.push(ArrayDef {
            name: "x".into(),
            base: 131072,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Input,
        });
        config.params.push(ParamValue::ArrayPtr("x".into()));
        let result = analyze(&module, Some("k"), config).unwrap();
        let output = result.symbolic_outputs().unwrap();
        let expression = output.element("out", 0).unwrap();
        for input in [
            0i64, 1, 65535, 65536, 65537, 0xdead0000, 0xdead0001, 0xffffffff,
        ] {
            assert_eq!(
                evaluate(&output.arena, expression, input),
                if input & 65535 == 0 { 0 } else { 7 },
                "{target} input={input}"
            );
        }
    }
}

#[test]
fn shared_unordered_float_comparison_retains_the_finite_real_boundary() {
    for target in ["gfx942", "gfx950"] {
        output(
            target,
            &format!(
                "v_mov_b32 v2,0x3f800000\nv_cmp_u_f32_e32 vcc,v2,v2\nv_cndmask_b32_e64 v1,7,0,vcc\n{STORE}"
            ),
            &[7],
        );
        let module = frontend::parse(&source(
            target,
            &format!(
                "v_mov_b32 v2,0x7fc00000\nv_cmp_u_f32_e32 vcc,v2,v2\nv_add_u32 v1,0,7\n{STORE}"
            ),
        ))
        .unwrap();
        let result = analyze(&module, Some("k"), config(1)).unwrap();
        let error = result.symbolic_outputs().unwrap_err();
        assert!(format!("{error:?}").contains("NaN"), "{error:?}");
    }
}
