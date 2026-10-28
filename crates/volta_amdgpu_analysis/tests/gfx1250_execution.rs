use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend};
use volta_expr::ExprNode;

const COPY: &str = include_str!("../../../tests/gfx1250/fixtures/native-copy-add.s");

fn config(block: u32, n: u64, add: bool) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    for (name, base, kind) in [
        ("x", 0x10000, ArrayKind::Input),
        ("y", 0x20000, ArrayKind::Input),
        ("out", 0x30000, ArrayKind::Output),
    ] {
        if name == "y" && !add {
            continue;
        }
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: 4,
            len: n,
            kind,
        });
        config.params.push(ParamValue::ArrayPtr(name.into()));
    }
    config.params.push(ParamValue::Int(n as i64));
    config
}

#[test]
fn genuine_wave32_compiler_source_parses_with_original_instructions() {
    for source in [
        COPY,
        include_str!("../../../tests/gfx1250/fixtures/native-lds-ids.s"),
        include_str!("../../../tests/gfx1250/fixtures/native-wmma.s"),
    ] {
        let module = frontend::parse(source).unwrap();
        assert_eq!(module.target.as_deref(), Some("gfx1250"));
        for kernel in module.kernels {
            assert!(kernel.descriptor.flag("wavefront_size32"));
        }
    }
}

#[test]
fn native_copy_has_complete_output_at_each_wave32_boundary() {
    let module = frontend::parse(COPY).unwrap();
    for block in [1, 31, 32, 33, 63, 64, 65, 96, 128] {
        for n in [1, block] {
            let result = analyze(&module, Some("copy"), config(block, n as u64, false)).unwrap();
            let outputs = result.symbolic_outputs().unwrap();
            assert_eq!(outputs.outputs[0].1.len(), n as usize);
            for i in 0..n as u64 {
                match outputs.arena.node(outputs.element("out", i).unwrap()) {
                    ExprNode::InputElement { array, index } => {
                        assert_eq!(outputs.arena.string(*array), "x");
                        assert_eq!(*index, i);
                    }
                    other => panic!("{other:?}"),
                }
            }
            assert!(
                result.graph().validate().is_ok(),
                "{:#?}",
                result.graph().validate()
            );
            assert!(
                !result
                    .graph()
                    .provenance()
                    .assumptions
                    .iter()
                    .any(|a| format!("{a:?}") == "XnackReplayDisabled")
            );
        }
    }
}

#[test]
fn compiler_wmma_all_outputs_match_independent_lane_dot_products() {
    let source = include_str!("../../../tests/gfx1250/fixtures/native-wmma.s");
    let module = frontend::parse(source).unwrap();
    for (kernel, width, k) in [
        ("wmma_f32", 4, 4),
        ("wmma_f16", 2, 32),
        ("wmma_bf16", 2, 32),
    ] {
        let mut config = AnalysisConfig::new((32, 1, 1));
        for (name, base, len, elem_width, kind) in [
            ("a", 0x10000, k * 16, width, ArrayKind::Input),
            ("b", 0x20000, k * 16, width, ArrayKind::Input),
            ("out", 0x30000, 256, 4, ArrayKind::Output),
        ] {
            config.arrays.push(ArrayDef {
                name: name.into(),
                base,
                len,
                elem_width,
                kind,
            });
            config.params.push(ParamValue::ArrayPtr(name.into()));
        }
        let result = analyze(&module, Some(kernel), config).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 256, "{kernel}");
        for lane in 0..32u64 {
            for component in 0..8u64 {
                let row = (lane / 16) * 8 + component;
                let col = lane % 16;
                let mut actual = Vec::new();
                fn terms(
                    arena: &volta_expr::ExprArena,
                    value: volta_expr::ExprId,
                    out: &mut Vec<(String, u64, String, u64)>,
                ) {
                    match arena.node(value) {
                        ExprNode::Add(a, b) => {
                            terms(arena, *a, out);
                            terms(arena, *b, out)
                        }
                        ExprNode::Fma(a, b, c) => {
                            match (arena.node(*a), arena.node(*b)) {
                                (
                                    ExprNode::InputElement {
                                        array: a,
                                        index: ai,
                                    },
                                    ExprNode::InputElement {
                                        array: b,
                                        index: bi,
                                    },
                                ) => out.push((
                                    arena.string(*a).into(),
                                    *ai,
                                    arena.string(*b).into(),
                                    *bi,
                                )),
                                other => panic!("{other:?}"),
                            }
                            terms(arena, *c, out)
                        }
                        ExprNode::Mul(a, b) => match (arena.node(*a), arena.node(*b)) {
                            (
                                ExprNode::InputElement {
                                    array: a,
                                    index: ai,
                                },
                                ExprNode::InputElement {
                                    array: b,
                                    index: bi,
                                },
                            ) => out.push((
                                arena.string(*a).into(),
                                *ai,
                                arena.string(*b).into(),
                                *bi,
                            )),
                            other => panic!("{other:?}"),
                        },
                        ExprNode::IntConst(0) => {}
                        ExprNode::RealConst(_) if arena.as_f64(value) == Some(0.0) => {}
                        other => panic!("{other:?}"),
                    }
                }
                terms(
                    &outputs.arena,
                    outputs.element("out", lane * 8 + component).unwrap(),
                    &mut actual,
                );
                actual.sort();
                let mut expected = Vec::new();
                for kk in 0..k {
                    let index = |r| {
                        if k == 4 {
                            (r + (kk / 2) * 16) * 2 + kk % 2
                        } else {
                            (r + ((kk / 8) % 2) * 16) * 16 + (kk / 16) * 8 + kk % 8
                        }
                    };
                    expected.push(("a".into(), index(row), "b".into(), index(col)));
                }
                expected.sort();
                assert_eq!(actual, expected, "{kernel} lane{lane} component{component}");
            }
        }
        result.graph().validate().unwrap();
    }
}

#[test]
fn compiler_exchange_uses_nonblocking_signal_and_two_wave32_lds() {
    let source = include_str!("../../../tests/gfx1250/fixtures/native-lds-ids.s");
    let module = frontend::parse(source).unwrap();
    let mut cfg = config(64, 64, false);
    cfg.params.pop();
    let result = analyze(&module, Some("exchange"), cfg).unwrap();
    let out = result.symbolic_outputs().unwrap();
    assert_eq!(out.outputs[0].1.len(), 64);
    for i in 0..64 {
        match out.arena.node(out.element("out", i).unwrap()) {
            ExprNode::InputElement { array, index } => {
                assert_eq!(out.arena.string(*array), "x");
                assert_eq!(*index, i ^ 32)
            }
            other => panic!("{other:?}"),
        }
    }
    result.graph().validate().unwrap();
}

#[test]
fn expanded_required_compiler_sources_parse_without_dropping_operations() {
    for source in [
        include_str!("../../../tests/gfx1250/fixtures/native-gemm-pipeline.s"),
        include_str!("../../../tests/gfx1250/fixtures/native-tensor-roundtrip.s"),
        include_str!("../../../tests/gfx1250/fixtures/native-attention-small.s"),
        include_str!("../../../tests/gfx1250/fixtures/native-transpose-high64.s"),
    ] {
        frontend::parse(source).unwrap();
    }
}

fn simple_config(block: u32, arrays: &[(&str, u64, u64, bool)]) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    for (i, &(name, len, width, input)) in arrays.iter().enumerate() {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base: 0x10000 * (i as u64 + 1),
            len,
            elem_width: width,
            kind: if input {
                ArrayKind::Input
            } else {
                ArrayKind::Output
            },
        });
        config.params.push(ParamValue::ArrayPtr(name.into()));
    }
    config
}
#[test]
fn compiler_staged_tensor_gemm_attention_and_transpose_produce_complete_outputs() {
    for (kernel, source, config, count) in [
        (
            "tensor_roundtrip",
            include_str!("../../../tests/gfx1250/fixtures/native-tensor-roundtrip.s"),
            simple_config(64, &[("x", 128, 4, true), ("out", 128, 4, false)]),
            128,
        ),
        (
            "gemm_pipeline_f16",
            include_str!("../../../tests/gfx1250/fixtures/native-gemm-pipeline.s"),
            simple_config(
                64,
                &[
                    ("a", 2048, 2, true),
                    ("b", 1024, 2, true),
                    ("out", 512, 4, false),
                ],
            ),
            512,
        ),
        (
            "attention_small",
            include_str!("../../../tests/gfx1250/fixtures/native-attention-small.s"),
            simple_config(
                32,
                &[
                    ("q", 512, 4, true),
                    ("k", 1024, 4, true),
                    ("v", 1024, 4, true),
                    ("out", 512, 4, false),
                ],
            ),
            512,
        ),
        (
            "transpose_8x8_b16",
            include_str!("../../../tests/gfx1250/fixtures/native-transpose-high64.s"),
            simple_config(32, &[("x", 64, 2, true), ("out", 64, 2, false)]),
            64,
        ),
    ] {
        let module = frontend::parse(source).unwrap();
        let result = analyze(&module, Some(kernel), config).unwrap();
        let outputs = result
            .symbolic_outputs()
            .unwrap_or_else(|e| panic!("{kernel}: {e:?}"));
        assert_eq!(outputs.outputs[0].1.len(), count, "{kernel}");
        result.graph().validate().unwrap();
    }
}

fn tiny_native(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
k:
s_load_b64 s[4:5], s[0:1], 0
s_wait_kmcnt 0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
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
#[test]
fn undefined_scalar_bits_are_eliminated_only_by_proven_bit_masks() {
    let source = tiny_native(
        "s_and_not1_b32 s6, s6, -1\nv_mov_b32 v1, s6\nglobal_store_b32 v0, v1, s[4:5] scale_offset",
    );
    let config = simple_config(1, &[("out", 1, 4, false)]);
    let module = frontend::parse(&source).unwrap();
    let result = analyze(&module, None, config.clone()).unwrap();
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(
        output.arena.as_int_const(output.element("out", 0).unwrap()),
        Some(0)
    );
    for body in [
        "s_and_not1_b32 s6, s6, 1\nv_mov_b32 v1, s6\nglobal_store_b32 v0, v1, s[4:5] scale_offset",
        "s_and_not1_b32 s6, s6, 1\ns_cbranch_scc1 done\ns_nop 0\ndone:",
        "v_mov_b32 v1, 0x1234\nv_sub_nc_u16 v1, v1, 1\nglobal_store_b32 v0, v1, s[4:5] scale_offset",
    ] {
        let module = frontend::parse(&tiny_native(body)).unwrap();
        let result = analyze(&module, None, config.clone()).unwrap();
        assert!(result.symbolic_outputs().is_err(), "{body}");
    }
}
#[test]
fn native_register_banks_and_literal_encodings_have_explicit_boundaries() {
    for body in [
        "v_add_f32_e32 v1, v1, 0x3e000000",
        "v_max_num_f32_e32 v1, v1, 0x3e000000",
        "v_fma_f32 v1, 0x3e000000, v1, 0x3dcccccd",
        "v_mov_b32 v256, 0",
    ] {
        assert!(frontend::parse(&tiny_native(body)).is_err(), "{body}");
    }
    let source = tiny_native("v_fma_f32 v1, 0x3e000000, v1, v1");
    frontend::parse(&source).unwrap();
}

#[test]
fn vopd_both_sources_observe_the_preissue_register_snapshot() {
    let source = tiny_native(
        "v_mov_b32 v1, 2.0\nv_mov_b32 v2, 3.0\nv_dual_add_f32 v1, v1, v2 :: v_dual_mul_f32 v2, v1, v2\nglobal_store_b32 v0, v1, s[4:5]\nglobal_store_b32 v0, v2, s[4:5] offset:4",
    );
    let module = frontend::parse(&source).unwrap();
    let result = analyze(&module, None, simple_config(1, &[("out", 2, 4, false)])).unwrap();
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(output.outputs[0].1.len(), 2);
    assert_eq!(
        output.arena.as_f64(output.element("out", 0).unwrap()),
        Some(5.0)
    );
    assert_eq!(
        output.arena.as_f64(output.element("out", 1).unwrap()),
        Some(6.0)
    );
}

#[test]
fn pseudo_scalar_exp_never_broadcasts_a_vector_lane() {
    for operand in ["v1", "-v1", "abs(v1)", "v[0:1]"] {
        let source = tiny_native(&format!("v_s_exp_f32 s5, {operand}"));
        assert!(frontend::parse(&source).is_err(), "{source}");
    }
    for operand in ["s6", "1.0", "0x3fb8aa3b"] {
        frontend::parse(&tiny_native(&format!("v_s_exp_f32 s5, {operand}"))).unwrap();
    }
}

#[test]
fn vopd_condition_spelling_preserves_vopd3_encoding_choice() {
    for body in [
        "v_dual_cndmask_b32 v2, v4, v1 :: v_dual_fma_f32 v7, v1, v2, v3",
        "v_dual_fma_f32 v7, v1, v2, v3 :: v_dual_cndmask_b32 v2, v4, v1",
    ] {
        assert!(frontend::parse(&tiny_native(body)).is_err(), "{body}");
    }
    frontend::parse(&tiny_native(
        "v_dual_cndmask_b32 v2, v4, v1, vcc_lo :: v_dual_fma_f32 v7, v1, v2, v3",
    ))
    .unwrap();
}

#[test]
fn typed_modules_cannot_retarget_native_scalar_and_vopd_semantics_to_cdna() {
    for body in [
        "s_sub_f32 s5, s6, s7",
        "s_mul_f32 s5, s6, s7",
        "s_min_num_f32 s5, s6, s7",
        "v_s_exp_f32 s5, s6",
        "v_max3_num_f32 v1, v2, v3, v4",
        "v_sub_nc_u16 v1, v2, v3",
        "s_load_b32 s5, s[0:1], s6 scale_offset",
        "v_dual_add_f32 v1, v1, v2 :: v_dual_mul_f32 v2, v1, v2",
    ] {
        let original = frontend::parse(&tiny_native(body)).unwrap();
        for target in ["gfx942", "gfx950"] {
            let mut module = original.clone();
            module.target = Some(target.into());
            let kernel = &mut module.kernels[0];
            kernel
                .descriptor
                .fields
                .insert("wavefront_size32".into(), 0);
            kernel.instructions = vec![
                kernel.instructions[2].clone(),
                kernel.instructions.last().unwrap().clone(),
            ];
            let error = volta_amdgpu_analysis::target::validate(&module).unwrap_err();
            assert!(
                error.message.contains("gfx1250"),
                "{target}: {body}: {error:?}"
            );
        }
    }
}

#[test]
fn native_encoding_suffixes_and_workgroup_premises_do_not_cross_generations() {
    for body in [
        "v_lshlrev_b16_e32 v1, 1, v2",
        "v_sub_nc_u16_e32 v1, v1, 1",
        "v_s_exp_f32_e32 s5, s5",
        "s_mul_f32_e32 s5, s5, 1",
        "s_mul_f32_e64 s5, s5, 1",
        "v_mad_u32_e32 v1, v1, v2, v3",
    ] {
        assert!(frontend::parse(&tiny_native(body)).is_err(), "{body}");
    }
    for body in [
        "v_lshlrev_b16_e64 v1, 1, v2",
        "v_sub_nc_u16_e64 v1, v1, 1",
        "v_s_exp_f32_e64 s5, s5",
    ] {
        frontend::parse(&tiny_native(body)).unwrap();
    }
    let module = frontend::parse(COPY).unwrap();
    let result = analyze(&module, Some("copy"), config(1, 1, false)).unwrap();
    let assumptions = &result.graph().provenance().assumptions;
    assert!(assumptions.contains(&volta_graph::Assumption::UnclusteredWorkgroup));
    assert!(!assumptions.contains(&volta_graph::Assumption::SingleCuWorkgroup));
}
#[test]
fn malformed_typed_scalar_exp_cannot_read_a_vector_lane() {
    let mut module = frontend::parse(&tiny_native("v_s_exp_f32 s5, s6")).unwrap();
    module.kernels[0].instructions[2].operands[1] =
        frontend::Operand::Register(frontend::Register {
            class: frontend::RegisterClass::Vector,
            index: 0,
            count: 1,
            special: None,
        });
    let error = analyze(&module, None, simple_config(1, &[("out", 1, 4, false)]))
        .err()
        .expect("typed invalid source rejected before execution");
    assert!(format!("{error:?}").contains("scalar"));
}

#[test]
fn scalar_memory_has_one_immediate_or_a_pinned_sgpr_offset_profile() {
    for body in [
        "s_load_b32 s2, s[0:1], 4 offset:4 scale_offset",
        "s_load_b32 s2, s[0:1], 4 offset:4",
        "s_load_b32 s2, s[0:1], 4 scale_offset",
    ] {
        assert!(frontend::parse(&tiny_native(body)).is_err(), "{body}");
    }
    for body in [
        "s_load_b32 s2, s[0:1], s4 offset:4 scale_offset",
        "s_load_b32 s2, s[0:1], s4 offset:4",
        "s_load_b32 s2, s[0:1], 4",
    ] {
        frontend::parse(&tiny_native(body)).unwrap();
    }
}

#[test]
fn scalar_float_sources_preserve_one_exact_native_literal_word() {
    for body in [
        "s_sub_f32 s5, 0x3e000000, 0x3dcccccd",
        "s_mul_f32 s5, s5, 0x100000000",
        "s_min_num_f32 s5, 0x3e000000, 0x3dcccccd",
    ] {
        assert!(frontend::parse(&tiny_native(body)).is_err(), "{body}");
    }
    for body in [
        "s_sub_f32 s5, s6, 0x3e000000",
        "s_mul_f32 s5, 0x3e000000, s6",
        "s_min_num_f32 s5, 0x3e000000, 0x3e000000",
    ] {
        frontend::parse(&tiny_native(body)).unwrap();
    }
}
