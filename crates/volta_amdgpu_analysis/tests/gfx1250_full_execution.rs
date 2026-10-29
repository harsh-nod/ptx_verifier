//! Required original-shape/dtype native forms; numerical hardware evidence is separate.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, analyze, frontend};

const F16: &str = include_str!("../../../tests/gfx1250/full/fixtures/original-f16.s");
const F8: &str = include_str!("../../../tests/gfx1250/full/fixtures/original-f8.s");

fn native(body: &str) -> String {
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
fn original_eighteen_compiler_entries_preserve_native_wave32_metadata() {
    for (source, suffix) in [(F16, "f16"), (F8, "f8")] {
        let module = frontend::parse(source).unwrap();
        assert_eq!(module.target.as_deref(), Some("gfx1250"));
        assert_eq!(module.kernels.len(), 9);
        for family in [
            "relu",
            "silu",
            "sigmoid",
            "swiglu",
            "rope",
            "reduction",
            "softmax",
            "rmsnorm",
            "matvec",
        ] {
            let entry = module
                .kernels
                .iter()
                .find(|k| k.name == format!("{family}_{suffix}"))
                .unwrap();
            assert!(entry.descriptor.flag("wavefront_size32"));
            assert_eq!(
                entry.descriptor.value("private_segment_fixed_size", 0),
                0,
                "scratch is not modeled"
            );
        }
    }
}

#[test]
fn gfx1250_byte_selection_decodes_all_four_ocp_e4m3_positions() {
    let mut body = String::from("s_mov_b32 s6, 0x30b84038\nv_mov_b32 v0, 0\n");
    for byte in 0..4 {
        body += &format!(
            "v_cvt_f32_fp8_e64 v1, s6 byte_sel:{byte}\nglobal_store_b32 v0, v1, s[4:5] offset:{}\ns_wait_xcnt 0\ns_wait_storecnt 0\n",
            byte * 4
        );
    }
    let module = frontend::parse(&native(&body)).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 4,
        kind: ArrayKind::Output,
    });
    config
        .params
        .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
    let result = analyze(&module, Some("k"), config).unwrap();
    let output = result.symbolic_outputs().unwrap();
    assert_eq!(output.outputs.len(), 1);
    assert_eq!(output.outputs[0].1.len(), 4);
    for ((index, value), expected) in output.outputs[0].1.iter().zip([1., 2., -1., 0.5]) {
        assert!(*index < 4);
        assert_eq!(output.arena.as_f64(*value), Some(expected));
    }
    result.graph().validate().unwrap();
}

#[test]
fn new_half_and_byte_forms_enforce_encoding_target_and_selector_bounds() {
    for good in [
        "v_pk_max_num_f16 v1,v2,v3",
        "v_max_num_f16_e32 v1,v2,v3",
        "v_max3_num_f16 v1,v2,v3,v4",
        "v_cvt_f32_fp8_e64 v1,v2 byte_sel:3",
    ] {
        frontend::parse(&native(good)).unwrap_or_else(|error| panic!("{good}: {error}"));
    }
    for bad in [
        "v_pk_max_num_f16_e32 v1,v2,v3",
        "v_max3_num_f16_e32 v1,v2,v3,v4",
        "v_cvt_f32_fp8_e32 v1,v2 byte_sel:1",
        "v_cvt_f32_fp8_e64 v1,v2 byte_sel:4",
        "v_cvt_f32_fp8_e64 v1,v2 byte_sel:-1",
        "v_add_f32_e64 v1,v2,v3 byte_sel:1",
    ] {
        assert!(frontend::parse(&native(bad)).is_err(), "accepted {bad}");
    }
    let retarget = frontend::parse(&native("v_cvt_f32_fp8_e64 v1,v2 byte_sel:3")).unwrap();
    let mut retarget = retarget;
    retarget.target = Some("gfx950".into());
    retarget.kernels[0]
        .descriptor
        .fields
        .insert("wavefront_size32".into(), 0);
    assert!(volta_amdgpu_analysis::target::validate(&retarget).is_err());
}

#[test]
fn native_no_return_atomic_preserves_existing_f32_inout_value() {
    let source = native(
        "v_mov_b32 v0, 0\nv_mov_b32 v1, 0x3fc00000\ns_wait_xcnt 0\nglobal_atomic_add_f32 v0, v1, s[4:5] scale_offset scope:SCOPE_DEV\ns_wait_storecnt 0\ns_wait_xcnt 0",
    );
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::InputOutput,
    });
    config
        .params
        .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
    let result = analyze(&module, Some("k"), config).unwrap();
    let actual = result.symbolic_outputs().unwrap();
    let mut arena = volta_expr::ExprArena::new();
    let name = arena.intern_string("out");
    let previous = arena.input_element(name, 0);
    let addend = arena.real(volta_expr::Real::from_f64(1.5).unwrap());
    let next = arena.add(previous, addend);
    let expected = volta_expr::SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), vec![(0, next)])],
    };
    assert!(matches!(
        volta_equivalence::check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        volta_equivalence::EquivOutcome::Equivalent
    ));
    let effects = result.graph().amd_memory_effects();
    assert!(effects.len() >= 2);
    result.graph().validate().unwrap();
}

#[test]
fn original_f16_relu_preserves_both_symbolically_selected_halves() {
    let module = frontend::parse(F16).unwrap();
    let mut config = AnalysisConfig::new((128, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 2,
            len: 1024,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 2,
            len: 1024,
            kind: ArrayKind::Output,
        },
    ];
    config.params = ["x", "out"]
        .map(|name| volta_amdgpu_analysis::ParamValue::ArrayPtr(name.into()))
        .into();
    let result = analyze(&module, Some("relu_f16"), config).unwrap();
    let actual = result.symbolic_outputs().unwrap();
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        (0..1024).collect::<Vec<_>>()
    );
    let mut arena = volta_expr::ExprArena::new();
    let name = arena.intern_string("x");
    let zero = arena.int(0);
    let outputs = (0..1024)
        .map(|index| {
            let input = arena.input_element(name, index);
            (index, arena.max(input, zero))
        })
        .collect();
    let expected = volta_expr::SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), outputs)],
    };
    assert!(matches!(
        volta_equivalence::check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        volta_equivalence::EquivOutcome::Equivalent
    ));
    result.graph().validate().unwrap();
}

#[test]
fn original_advanced_compiler_entries_preserve_wave32_and_have_no_scratch() {
    for (source, count) in [
        (
            include_str!("../../../tests/gfx1250/full/fixtures/original-convolution.s"),
            2,
        ),
        (
            include_str!("../../../tests/gfx1250/full/fixtures/original-attention.s"),
            3,
        ),
        (
            include_str!("../../../tests/gfx1250/full/fixtures/original-sinkhorn.s"),
            1,
        ),
        (
            include_str!("../../../tests/gfx1250/full/fixtures/original-mamba.s"),
            2,
        ),
    ] {
        let module =
            frontend::parse(source).unwrap_or_else(|error| panic!("{count} kernels: {error}"));
        assert_eq!(module.kernels.len(), count);
        assert_eq!(module.target.as_deref(), Some("gfx1250"));
        for kernel in &module.kernels {
            assert!(kernel.descriptor.flag("wavefront_size32"));
            assert_eq!(kernel.descriptor.value("private_segment_fixed_size", 0), 0);
        }
    }
}

#[test]
fn native_packed_integer_address_operations_wrap_each_selected_half() {
    for (instruction, expected) in [
        ("v_pk_mul_lo_u16 v1,v2,v3", 0xfffe8000u32),
        ("v_pk_mul_lo_u16 v1,v2,v3 op_sel_hi:[1,0]", 0xfffd8000u32),
        ("v_pk_sub_i16 v1,v2,v3", 0xfffd7ffdu32),
    ] {
        let source = native(&format!(
            "v_mov_b32 v2,0xffff8000\nv_mov_b32 v3,0x00020003\n{instruction}\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
        ));
        let module = frontend::parse(&source).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 65536,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        config
            .params
            .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
        let analysis = analyze(&module, Some("k"), config).unwrap();
        let output = analysis.symbolic_outputs().unwrap();
        assert_eq!(
            output.arena.as_int_const(output.outputs[0].1[0].1),
            Some(i64::from(expected))
        );
    }
    for instruction in [
        "v_pk_mul_lo_u16_e32 v1,v2,v3",
        "v_ashrrev_i16_e32 v1,8,v2",
        "v_xad_u32_e32 v1,v2,v3,v4",
        "s_addk_co_i32 s4,65536",
    ] {
        assert!(
            frontend::parse(&native(instruction)).is_err(),
            "accepted {instruction}"
        );
    }
}

#[test]
fn native_signed16_shift_consumes_only_low16_and_never_exposes_a_fabricated_upper_half() {
    for (shift, expected) in [(0, -32768.), (1, -16384.), (8, -128.), (15, -1.)] {
        let source = native(&format!(
            "v_mov_b32 v2,0x55558000\nv_ashrrev_i16 v1,{shift},v2\nv_cvt_f16_i16 v1,v1\nv_cvt_f32_f16 v1,v1\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0"
        ));
        let module = frontend::parse(&source).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 65536,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        config
            .params
            .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
        let analysis = analyze(&module, Some("k"), config).unwrap();
        let output = analysis.symbolic_outputs().unwrap();
        assert_eq!(
            output.arena.as_f64(output.outputs[0].1[0].1),
            Some(expected)
        );
    }
    for consumer in ["v_cvt_f32_i32 v1,v1", "v_add_u32 v1,0,v1"] {
        let source = native(&format!(
            "v_mov_b32 v2,0x55558000\nv_ashrrev_i16 v1,8,v2\n{consumer}\nv_mov_b32 v0,0\nglobal_store_b32 v0,v1,s[4:5]"
        ));
        let module = frontend::parse(&source).unwrap();
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 65536,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        config
            .params
            .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
        let analysis = analyze(&module, Some("k"), config).unwrap();
        assert!(
            analysis.symbolic_outputs().is_err(),
            "upper half escaped via {consumer}"
        );
    }
}

#[test]
fn native_signed_byte_extracts_preserve_four_independent_input_identities() {
    let mut body = String::from(
        "s_load_b64 s[6:7],s[0:1],8\ns_wait_kmcnt 0\nv_mov_b32 v0,0\nglobal_load_b32 v1,v0,s[6:7]\ns_wait_loadcnt 0\n",
    );
    for byte in 0..4 {
        if byte == 1 {
            body += "v_ashrrev_i16 v2,8,v1\n";
        } else {
            body += &format!("v_bfe_i32 v2,v1,{},8\n", byte * 8);
        }
        body += &format!(
            "v_cvt_f16_i16 v2,v2\nv_cvt_f32_f16 v2,v2\nglobal_store_b32 v0,v2,s[4:5] offset:{}\ns_wait_xcnt 0\ns_wait_storecnt 0\n",
            byte * 4
        );
    }
    let source=native(&body).replace(".amdhsa_kernarg_size 8", ".amdhsa_kernarg_size 16").replace("        .value_kind: global_buffer\n", "        .value_kind: global_buffer\n      - .name: bytes\n        .offset: 8\n        .size: 8\n        .value_kind: global_buffer\n");
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "out".into(),
            base: 65536,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::Output,
        },
        ArrayDef {
            name: "bytes".into(),
            base: 131072,
            elem_width: 1,
            len: 4,
            kind: ArrayKind::Input,
        },
    ];
    config.params = vec![
        volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()),
        volta_amdgpu_analysis::ParamValue::ArrayPtr("bytes".into()),
    ];
    let analysis = analyze(&module, Some("k"), config).unwrap();
    let output = analysis.symbolic_outputs().unwrap();
    assert_eq!(output.outputs[0].1.len(), 4);
    for (index, expr) in &output.outputs[0].1 {
        let volta_expr::ExprNode::InputElement {
            array,
            index: source_index,
        } = output.arena.node(*expr)
        else {
            panic!("byte identity lost")
        };
        assert_eq!(output.arena.string(*array), "bytes");
        assert_eq!(index, source_index);
    }
}

#[test]
fn vopd_fmamk_pair_has_one_shared_literal_and_exact_snapshot_inputs() {
    frontend::parse(&native(
        "v_dual_fmamk_f32 v2,v4,0x3e38aa3b,v1 :: v_dual_fmamk_f32 v3,v5,0x3e38aa3b,v1",
    ))
    .unwrap();
    assert!(
        frontend::parse(&native(
            "v_dual_fmamk_f32 v2,v4,0x3e38aa3b,v1 :: v_dual_fmamk_f32 v3,v5,0x3e000000,v1"
        ))
        .is_err()
    );
}

#[test]
fn signed16_variable_shift_does_not_broadcast_lane_zero_shift() {
    let source = native(
        "v_mov_b32 v2,0x8000\nv_lshlrev_b32 v3,3,v0\nv_sub_u32 v3,8,v3\nv_ashrrev_i16 v1,v3,v2\nv_cvt_f16_i16 v1,v1\nv_cvt_f32_f16 v1,v1\nv_lshlrev_b32 v0,2,v0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0",
    );
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((2, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    });
    config
        .params
        .push(volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()));
    let analysis = analyze(&module, Some("k"), config).unwrap();
    let output = analysis.symbolic_outputs().unwrap();
    assert_eq!(output.outputs[0].1.len(), 2);
    assert_eq!(output.arena.as_f64(output.outputs[0].1[0].1), Some(-128.));
    assert_eq!(output.arena.as_f64(output.outputs[0].1[1].1), Some(-32768.));
}
