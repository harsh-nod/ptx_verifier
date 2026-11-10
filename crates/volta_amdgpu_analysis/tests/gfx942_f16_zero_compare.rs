//! The CDNA3 ReLU VOPC profile reads low16 and writes a full wave64 VCC mask.
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, OutputsUnavailable, analyze, frontend,
};
use volta_expr::ExprNode;
use volta_graph_check::{GraphConclusion, check_graph};

fn source(body: &str) -> String {
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--gfx942"
.text
.type k,@function
k:
{body}
v_cndmask_b32 v3,0,1,vcc
v_add_u32 v3,0,v3
v_lshlrev_b32 v4,2,v0
s_mov_b32 s4,0x20000
s_mov_b32 s5,0
global_store_dword v4,v3,s[4:5]
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_accum_offset 64
.amdhsa_system_vgpr_workitem_id 0
.end_amdhsa_kernel
"#
    )
}

fn config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 64,
        kind: ArrayKind::Output,
    }];
    config
}

fn run(text: &str) -> volta_amdgpu_analysis::AnalysisResult {
    let module = frontend::parse(text).unwrap();
    analyze(&module, Some("k"), config()).unwrap()
}

#[test]
fn malformed_direct_ast_operands_and_modifiers_cannot_bypass_bounded_admission() {
    use frontend::{Modifier, Operand, RegisterClass, SpecialRegister};
    let module =
        frontend::parse(&source("v_mov_b32 v2,0x3c00\nv_cmp_lt_f16_e32 vcc,0,v2")).unwrap();
    for variant in 0..17 {
        let mut malformed = module.clone();
        let compare = &mut malformed.kernels[0].instructions[1];
        match variant {
            0 => {
                compare.operands.pop();
            }
            1 => compare.operands.push(Operand::Integer(0)),
            2 => compare.operands.clear(),
            3..=7 => {
                let Operand::Register(mask) = &mut compare.operands[0] else {
                    unreachable!()
                };
                match variant {
                    3 => mask.class = RegisterClass::Scalar,
                    4 => mask.index = 1,
                    5 => mask.count = 1,
                    6 => mask.special = None,
                    _ => mask.special = Some(SpecialRegister::Exec),
                }
            }
            8..=12 => {
                let Operand::Register(value) = &mut compare.operands[2] else {
                    unreachable!()
                };
                match variant {
                    8 => value.class = RegisterClass::Accumulator,
                    9 => value.class = RegisterClass::Scalar,
                    10 => value.index = 256,
                    11 => value.count = 2,
                    _ => value.special = Some(SpecialRegister::Vcc),
                }
            }
            13 => compare.operands[1] = Operand::Float(0.0),
            14 => compare.operands[1] = Operand::Integer(0x10000),
            15 => compare.modifiers.push(Modifier {
                name: "op_sel".into(),
                value: Some("[0,1]".into()),
            }),
            _ => {
                compare.operands[2] = Operand::Modified {
                    value: Box::new(compare.operands[2].clone()),
                    negate: false,
                    absolute: true,
                }
            }
        }
        if let Ok(result) = analyze(&malformed, Some("k"), config()) {
            assert!(
                matches!(
                    result.symbolic_outputs(),
                    Err(OutputsUnavailable::Aborted(_))
                ),
                "AST variant {variant}: {:?}",
                result.symbolic_outputs()
            );
        }
    }
}

#[test]
fn independent_encoded_halves_compare_low16_in_every_wave64_lane() {
    // Including signed zero and the smallest subnormal distinguishes the
    // selected F16 interpretation from integer and F32 comparisons.
    for (bits, expected) in [
        (0xffff_0000_u32, 0),
        (0x3c00_8000, 0),
        (0xbc00_0001, 1),
        (0x0000_8001, 0),
        (0xbc00_3c00, 1),
        (0x3c00_bc00, 0),
        (0x0000_7bff, 1),
    ] {
        let result = run(&source(&format!(
            "v_mov_b32 v2,0x{bits:08x}\nv_cmp_lt_f16_e32 vcc,0,v2"
        )));
        assert_eq!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        );
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 64);
        for index in 0..64 {
            assert!(
                matches!(outputs.arena.node(outputs.element("out", index).unwrap()),
                ExprNode::IntConst(value) if *value == expected),
                "bits={bits:x}, lane={index}"
            );
        }
    }
}

#[test]
fn sign_varying_lanes_and_sparse_exec_keep_their_own_predicates() {
    for (exec, first, step) in [
        ("", 0, 1),
        (
            "s_mov_b32 exec_lo,0xaaaaaaaa\ns_mov_b32 exec_hi,0xaaaaaaaa",
            1,
            2,
        ),
    ] {
        let result = run(&source(&format!(
            "v_lshlrev_b32 v2,15,v0\nv_or_b32 v2,0xdead3c00,v2\n{exec}\nv_cmp_lt_f16_e32 vcc,0,v2"
        )));
        assert_eq!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        );
        let outputs = result.symbolic_outputs().unwrap();
        let expected: Vec<_> = (first..64).step_by(step).collect();
        assert_eq!(
            outputs.outputs[0]
                .1
                .iter()
                .map(|(i, _)| *i)
                .collect::<Vec<_>>(),
            expected
        );
        for index in expected {
            let expected = i64::from(index % 2 == 0);
            assert!(
                matches!(outputs.arena.node(outputs.element("out", index).unwrap()),
                ExprNode::IntConst(value) if *value == expected)
            );
        }
    }
}

#[test]
fn neighboring_encodings_relations_operands_and_nan_remain_incomplete() {
    for instruction in [
        "v_cmp_lt_f16_e64 vcc,0,v2",
        "v_cmp_le_f16_e32 vcc,0,v2",
        "v_cmpx_lt_f16_e32 vcc,0,v2",
        "v_cmp_lt_f16_e32 vcc,1,v2",
        "v_cmp_lt_f16_e32 vcc,v2,v2",
        "v_cmp_lt_f16_e32 vcc,0,-v2",
    ] {
        let text = source(&format!("v_mov_b32 v2,0x3c00\n{instruction}"));
        // A syntax/lowering rejection also refuses a neighboring form.
        if let Ok(module) = frontend::parse(&text) {
            let mut config = AnalysisConfig::new((64, 1, 1));
            config.arrays = vec![ArrayDef {
                name: "out".into(),
                base: 0x20000,
                elem_width: 4,
                len: 64,
                kind: ArrayKind::Output,
            }];
            if let Ok(result) = analyze(&module, Some("k"), config) {
                assert!(result.symbolic_outputs().is_err(), "{instruction}");
            }
        }
    }
    let result = run(&source("v_mov_b32 v2,0x7e00\nv_cmp_lt_f16_e32 vcc,0,v2"));
    assert!(
        result.symbolic_outputs().is_err(),
        "NaN cannot enter the real model"
    );
    let result = run(&source("v_cmp_lt_f16_e32 vcc,0,v2"));
    assert!(
        result.symbolic_outputs().is_err(),
        "undefined low16 cannot become a predicate"
    );
}
