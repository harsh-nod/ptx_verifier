use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend};
use volta_expr::ExprNode;

fn array(name: &str, base: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: 4,
        len,
        kind,
    }
}
fn source(instructions: &str, lds: u64) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl copy
.type copy,@function
copy:
{instructions}
.amdhsa_kernel copy
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_group_segment_fixed_size {lds}
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: copy
    .symbol: copy.kd
    .kernarg_segment_size: 16
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}
const COPY: &str = r#"
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v2, 2, v0
v_mov_b32 v3, 0
v_lshl_add_u64 v[6:7], s[4:5], 0, v[2:3]
global_load_dword v5, v[6:7], off
s_waitcnt vmcnt(0)
v_lshl_add_u64 v[6:7], s[6:7], 0, v[2:3]
global_store_dword v[6:7], v5, off
s_endpgm
"#;
fn config(block: u32, n: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        array("x", 0x10000, n, ArrayKind::Input),
        array("out", 0x20000, n, ArrayKind::Output),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}

#[test]
fn native_copy_across_partial_and_multiple_waves() {
    let module = frontend::parse(&source(COPY, 0)).unwrap();
    for block in [1, 63, 64, 65, 128, 256] {
        let result = analyze(&module, None, config(block, block as u64)).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), block as usize);
        for index in 0..block as u64 {
            let root = outputs.element("out", index).unwrap();
            match outputs.arena.node(root) {
                ExprNode::InputElement {
                    array,
                    index: found,
                } => {
                    assert_eq!(outputs.arena.string(*array), "x");
                    assert_eq!(*found, index);
                }
                other => panic!("wrong expression: {other:?}"),
            }
        }
        assert!(result.graph.validate().is_ok());
    }
}

#[test]
fn masked_tail_preserves_full_64bit_exec() {
    let instructions = COPY.replace(
        "global_load_dword",
        "v_cmp_lt_u32 vcc, v0, 65\ns_and_saveexec_b64 s[8:9], vcc\nglobal_load_dword",
    );
    let module = frontend::parse(&source(&instructions, 0)).unwrap();
    let result = analyze(&module, None, config(128, 65)).unwrap();
    assert_eq!(result.symbolic_outputs().unwrap().outputs[0].1.len(), 65);
    assert!(
        result
            .symbolic_outputs()
            .unwrap()
            .element("out", 64)
            .is_some()
    );
}

#[test]
fn missing_output_store_is_missing_from_footprint() {
    let module = frontend::parse(&source(
        &COPY.replace("global_store_dword v[6:7], v5, off", ""),
        0,
    ))
    .unwrap();
    let result = analyze(&module, None, config(64, 64)).unwrap();
    assert!(result.symbolic_outputs().unwrap().outputs[0].1.is_empty());
}

#[test]
fn budget_exhaustion_retains_partial_graph_and_no_outputs() {
    let module = frontend::parse(&source(COPY, 0)).unwrap();
    let mut cfg = config(64, 64);
    cfg.max_instructions = 4;
    let result = analyze(&module, None, cfg).unwrap();
    assert!(result.symbolic_outputs().is_err());
    assert!(matches!(
        result.graph.terminal(),
        volta_graph::Terminal::Aborted { .. }
    ));
    assert!(!result.graph.amd_events().is_empty());
    assert!(result.graph.validate().is_ok());
}

#[test]
fn vector_wide_transfer_retains_each_element() {
    let instructions = COPY
        .replace("global_load_dword v5", "global_load_dwordx4 v[8:11]")
        .replace(
            "global_store_dword v[6:7], v5",
            "global_store_dwordx4 v[6:7], v[8:11]",
        )
        .replace("v_lshlrev_b32 v2, 2", "v_lshlrev_b32 v2, 4");
    let module = frontend::parse(&source(&instructions, 0)).unwrap();
    let result = analyze(&module, None, config(64, 256)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 256);
    for index in 0..256 {
        assert!(
            matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::InputElement{index:found,..} if *found==index)
        );
    }
}

#[test]
fn lds_exchange_uses_workgroup_storage_and_barrier() {
    let instructions=COPY.replace("s_waitcnt vmcnt(0)","s_waitcnt vmcnt(0)\nds_write_b32 v2, v5\ns_waitcnt lgkmcnt(0)\ns_barrier\nv_xor_b32 v6, 256, v2\nds_read_b32 v5, v6\ns_waitcnt lgkmcnt(0)");
    let module = frontend::parse(&source(&instructions, 512)).unwrap();
    let result = analyze(&module, None, config(128, 128)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    for index in 0..128 {
        assert!(
            matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::InputElement{index:found,..} if *found==(index^64))
        );
    }
    assert_eq!(result.stats.block_syncs, 2);
}

#[test]
fn clang22_native_copy_and_add() {
    let module =
        frontend::parse(include_str!("../src/frontend/fixtures/clang22-copy-add.s")).unwrap();
    for n in [1, 63, 64, 65, 128, 256] {
        let mut cfg = config(256, n);
        cfg.params.push(ParamValue::Int(n as i64));
        let result = analyze(&module, Some("copy"), cfg).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), n as usize);
    }
    let mut cfg = config(128, 128);
    cfg.arrays
        .insert(1, array("y", 0x30000, 128, ArrayKind::Input));
    cfg.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("y".into()),
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Int(128),
    ];
    let result = analyze(&module, Some("add"), cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 128);
    for index in 0..128 {
        assert!(matches!(
            outputs.arena.node(outputs.element("out", index).unwrap()),
            ExprNode::Add(..)
        ));
    }
}
#[test]
fn compiler_exchange_and_relu() {
    let module = frontend::parse(include_str!(
        "../src/frontend/fixtures/clang22-exchange-reduce-relu.s"
    ))
    .unwrap();
    let result = analyze(&module, Some("exchange"), config(128, 128)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 128);
    for index in 0..128 {
        assert!(
            matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::InputElement{index:found,..} if *found==(index^64))
        );
    }
    let result = analyze(&module, Some("relu"), config(128, 128)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 128);
    for index in 0..128 {
        assert!(matches!(
            outputs.arena.node(outputs.element("out", index).unwrap()),
            ExprNode::Max(..)
        ));
    }
}

fn leaf_weights(
    arena: &volta_expr::ExprArena,
    expr: volta_expr::ExprId,
    weights: &mut std::collections::BTreeMap<u64, u32>,
) {
    match arena.node(expr) {
        ExprNode::InputElement { index, .. } => *weights.entry(*index).or_default() += 1,
        ExprNode::Add(a, b) => {
            leaf_weights(arena, *a, weights);
            leaf_weights(arena, *b, weights);
        }
        node => panic!("unexpected reduction node {node:?}"),
    }
}

#[test]
fn compiler_wave64_reduction_has_each_input_exactly_once() {
    let module = frontend::parse(include_str!(
        "../src/frontend/fixtures/clang22-exchange-reduce-relu.s"
    ))
    .unwrap();
    let mut cfg = config(128, 128);
    cfg.arrays[1].len = 2;
    let result = analyze(&module, Some("reduce"), cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 2);
    for output in 0..2 {
        let mut weights = std::collections::BTreeMap::new();
        leaf_weights(
            &outputs.arena,
            outputs.element("out", output).unwrap(),
            &mut weights,
        );
        assert_eq!(weights.len(), 64);
        for index in output * 64..output * 64 + 64 {
            assert_eq!(weights.get(&index), Some(&1));
        }
    }
}
fn product_terms(
    arena: &volta_expr::ExprArena,
    expr: volta_expr::ExprId,
    terms: &mut Vec<(u64, u64)>,
) {
    match arena.node(expr) {
        ExprNode::Add(a, b) => {
            product_terms(arena, *a, terms);
            product_terms(arena, *b, terms);
        }
        ExprNode::Mul(a, b) => {
            let input = |id| match arena.node(id) {
                ExprNode::InputElement { array, index } => (arena.string(*array), *index),
                node => panic!("unexpected factor {node:?}"),
            };
            let (name_a, index_a) = input(*a);
            let (name_b, index_b) = input(*b);
            assert_eq!(name_a, "a");
            assert_eq!(name_b, "b");
            terms.push((index_a, index_b));
        }
        node => panic!("unexpected matrix term {node:?}"),
    }
}
fn mfma_config() -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((64, 1, 1));
    cfg.arrays = vec![
        array("a", 0x10000, 64, ArrayKind::Input),
        array("b", 0x20000, 64, ArrayKind::Input),
        array("out", 0x30000, 256, ArrayKind::Output),
    ];
    cfg.params = vec![
        ParamValue::ArrayPtr("a".into()),
        ParamValue::ArrayPtr("b".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    cfg
}
#[test]
fn native_mfma_all_256_coordinates_match_independent_dot_products() {
    let module =
        frontend::parse(include_str!("../src/frontend/fixtures/clang22-mfma-f32.s")).unwrap();
    let result = analyze(&module, None, mfma_config()).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 256);
    for lane in 0..64u64 {
        for register in 0..4 {
            let row = 4 * (lane / 16) + register;
            let column = lane % 16;
            let index = 4 * lane + register;
            let mut terms = Vec::new();
            product_terms(
                &outputs.arena,
                outputs.element("out", index).unwrap(),
                &mut terms,
            );
            assert_eq!(
                terms,
                (0..4)
                    .map(|k| (row + 16 * k, column + 16 * k))
                    .collect::<Vec<_>>()
            );
        }
    }
    assert_eq!(result.stats.warp_syncs, 1);
    assert!(result.graph.validate().is_ok());
}

#[test]
fn mfma_partial_wave_and_nonzero_layout_modifiers_are_incomplete() {
    let text = include_str!("../src/frontend/fixtures/clang22-mfma-f32.s");
    let module = frontend::parse(text).unwrap();
    let mut cfg = mfma_config();
    cfg.block_dim = (63, 1, 1);
    let result = analyze(&module, None, cfg).unwrap();
    assert!(result.symbolic_outputs().is_err());
    let text = text.replace("v[2:5], v2, v3, 0", "v[2:5], v2, v3, 0 blgp:1");
    let module = frontend::parse(&text).unwrap();
    let result = analyze(&module, None, mfma_config()).unwrap();
    assert!(result.symbolic_outputs().is_err());
}

#[test]
fn explicit_global_values_and_abi_count_mismatch_are_rejected() {
    let text = source(COPY, 0);
    let module = frontend::parse(&text).unwrap();
    let mut cfg = config(64, 64);
    cfg.global_values.push(("undeclared".into(), 7));
    assert!(analyze(&module, None, cfg).is_err());
    let text = text.replace(
        ".amdhsa_kernarg_size 16",
        ".amdhsa_kernarg_size 16\n.amdhsa_user_sgpr_count 4",
    );
    let module = frontend::parse(&text).unwrap();
    assert!(analyze(&module, None, config(64, 64)).is_err());
}
#[test]
fn compiler_packed_f16_relu_preserves_each_half_identity() {
    let module = frontend::parse(include_str!("../src/frontend/fixtures/portable-f16.s")).unwrap();
    let mut cfg = config(128, 1024);
    for array in &mut cfg.arrays {
        array.elem_width = 2;
    }
    let result = analyze(&module, Some("relu_f16"), cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 1024);
    for index in 0..1024 {
        let root = outputs.element("out", index).unwrap();
        let ExprNode::Max(a, b) = outputs.arena.node(root) else {
            panic!("not max for {index}")
        };
        let identity = |id| matches!(outputs.arena.node(id),ExprNode::InputElement{index:found,..} if *found==index);
        assert!(identity(*a) || identity(*b));
    }
}
#[test]
fn exp2_compiler_idiom_is_exactly_matched_and_disclosed() {
    let exact = COPY.replace(
        "global_store_dword",
        "v_mul_f32 v5, 0x3fb8aa3b, v5\nv_exp_f32 v5, v5\nglobal_store_dword",
    );
    let module = frontend::parse(&source(&exact, 0)).unwrap();
    let result = analyze(&module, None, config(64, 64)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert!(
        result
            .graph
            .provenance()
            .assumes(volta_graph::Assumption::CompilerExp2Idiom)
    );
    for index in 0..64 {
        let ExprNode::Exp(argument) = outputs.arena.node(outputs.element("out", index).unwrap())
        else {
            panic!("not exp")
        };
        assert!(
            matches!(outputs.arena.node(*argument),ExprNode::InputElement{index:found,..} if *found==index)
        );
    }
    let near = exact.replace("0x3fb8aa3b", "0x3fb8aa3c");
    let module = frontend::parse(&source(&near, 0)).unwrap();
    let result = analyze(&module, None, config(64, 64)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert!(
        !result
            .graph
            .provenance()
            .assumes(volta_graph::Assumption::CompilerExp2Idiom)
    );
    let ExprNode::Exp(argument) = outputs.arena.node(outputs.element("out", 0).unwrap()) else {
        panic!("not exp")
    };
    assert!(!matches!(
        outputs.arena.node(*argument),
        ExprNode::InputElement { .. }
    ));
}

#[test]
fn real_compiler_three_dimensional_packed_ids() {
    let module =
        frontend::parse(include_str!("../src/frontend/fixtures/clang22-ids-3d.s")).unwrap();
    let mut cfg = AnalysisConfig::new((4, 3, 2));
    cfg.arrays = vec![array("out", 0x10000, 24, ArrayKind::Output)];
    cfg.params = vec![ParamValue::ArrayPtr("out".into())];
    let result = analyze(&module, None, cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 24);
    for z in 0..2 {
        for y in 0..3 {
            for x in 0..4 {
                let index = x + 4 * (y + 3 * z);
                let ExprNode::IntConst(value) =
                    outputs.arena.node(outputs.element("out", index).unwrap())
                else {
                    panic!("nonconstant ID")
                };
                assert_eq!(*value, (x + 10 * y + 100 * z) as i64);
            }
        }
    }
}

#[test]
fn pipelined_two_wave_native_mfma_gemm_has_complete_dot_products() {
    let module = frontend::parse(include_str!(
        "../src/frontend/fixtures/clang22-pipelined-mfma-f32.s"
    ))
    .unwrap();
    let mut cfg = mfma_config();
    cfg.block_dim = (128, 1, 1);
    cfg.arrays[0].len = 256;
    cfg.arrays[1].len = 128;
    cfg.arrays[2].len = 512;
    let result = analyze(&module, None, cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 512);
    for row in 0..32u64 {
        for column in 0..16 {
            let mut terms = Vec::new();
            product_terms(
                &outputs.arena,
                outputs.element("out", row * 16 + column).unwrap(),
                &mut terms,
            );
            assert_eq!(
                terms,
                (0..8)
                    .map(|k| (row * 8 + k, k * 16 + column))
                    .collect::<Vec<_>>()
            );
        }
    }
    assert!(result.stats.block_syncs >= 8);
    assert_eq!(result.stats.warp_syncs, 4);
}

#[test]
fn single_operand_unsupported_scalar_does_not_panic() {
    let text = source(&COPY.replace("s_endpgm", "s_getpc_b64 s[8:9]\ns_endpgm"), 0);
    let module = frontend::parse(&text).unwrap();
    let result = analyze(&module, None, config(64, 64)).unwrap();
    assert!(result.symbolic_outputs().is_err());
    assert!(result.graph.validate().is_ok());
}
#[test]
fn compiler_f16_silu_and_sigmoid_use_each_element_independently() {
    let module = frontend::parse(include_str!("../src/frontend/fixtures/portable-f16.s")).unwrap();
    for (kernel, block, n) in [("silu_f16", 128, 512), ("sigmoid_f16", 256, 1024)] {
        let mut cfg = config(block, n);
        for array in &mut cfg.arrays {
            array.elem_width = 2;
        }
        let result = analyze(&module, Some(kernel), cfg).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), n as usize);
        for index in 0..n {
            let root = outputs.element("out", index).unwrap();
            let reciprocal = if kernel == "silu_f16" {
                let ExprNode::Mul(a, b) = outputs.arena.node(root) else {
                    panic!("missing SiLU product")
                };
                if matches!(outputs.arena.node(*a), ExprNode::Rcp(..)) {
                    *a
                } else {
                    *b
                }
            } else {
                root
            };
            let ExprNode::Rcp(denom) = outputs.arena.node(reciprocal) else {
                panic!("missing reciprocal")
            };
            let ExprNode::Add(a, b) = outputs.arena.node(*denom) else {
                panic!("missing denominator sum")
            };
            let exp = if matches!(outputs.arena.node(*a), ExprNode::Exp(..)) {
                *a
            } else {
                *b
            };
            let ExprNode::Exp(negative) = outputs.arena.node(exp) else {
                panic!("missing exp")
            };
            let ExprNode::Neg(input) = outputs.arena.node(*negative) else {
                panic!("missing negative")
            };
            assert!(
                matches!(outputs.arena.node(*input),ExprNode::InputElement{index:found,..}if *found==index)
            );
        }
    }
}
fn numeric_transfer(load: &str, store: Option<&str>, input_width: u64, initial: u32) -> String {
    let setup = if let Some(store) = store {
        format!("v_add_u32 v5, 0x{initial:x}, v0\n{store} v[6:7], v5, off\ns_waitcnt vmcnt(0)\n")
    } else {
        String::new()
    };
    format!(
        "s_load_dwordx4 s[4:7], s[0:1], 0\ns_waitcnt lgkmcnt(0)\nv_mul_lo_u32 v2, {input_width}, v0\nv_mov_b32 v3, 0\nv_lshl_add_u64 v[6:7], s[4:5], 0, v[2:3]\n{setup}{load} v5, v[6:7], off\ns_waitcnt vmcnt(0)\nv_lshlrev_b32 v2, 2, v0\nv_lshl_add_u64 v[6:7], s[6:7], 0, v[2:3]\nglobal_store_dword v[6:7], v5, off\ns_endpgm"
    )
}
#[test]
fn signed_byte_and_short_loads_extend_the_actual_transfer_width() {
    for (load, width, start, len, threads) in [
        ("global_load_sbyte", 1, 0, 256, 256),
        ("global_load_sshort", 2, 32700, 33000, 128),
    ] {
        let module = frontend::parse(&source(&numeric_transfer(load, None, width, 0), 0)).unwrap();
        let mut cfg = config(threads, len);
        cfg.arrays[0].elem_width = width;
        cfg.arrays[0].kind = ArrayKind::IndexInput;
        cfg.arrays[1].len = threads as u64;
        cfg.arrays[1].base = 0x100000;
        cfg.params[0] = ParamValue::Int((0x10000 + start * width) as i64);
        let result = analyze(&module, None, cfg).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), threads as usize);
        for index in 0..threads as u64 {
            let expected = if width == 1 {
                (index + start) as i8 as i64
            } else {
                (index + start) as i16 as i64
            };
            assert!(
                matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::IntConst(value)if *value==expected)
            );
        }
    }
}
#[test]
fn narrow_stores_truncate_before_unsigned_reload() {
    for (store, load, width, initial) in [
        ("global_store_byte", "global_load_ubyte", 1, 0xffff1200),
        ("global_store_short", "global_load_ushort", 2, 0xffff1234),
    ] {
        let module = frontend::parse(&source(
            &numeric_transfer(load, Some(store), width, initial),
            0,
        ))
        .unwrap();
        let mut cfg = config(64, 64);
        cfg.arrays[0].elem_width = width;
        cfg.arrays[0].kind = ArrayKind::Output;
        let result = analyze(&module, None, cfg).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        let mask = if width == 1 { 255 } else { 65535 };
        for index in 0..64 {
            let expected = ((initial as u64 + index) & mask) as i64;
            assert!(
                matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::IntConst(value)if *value==expected)
            );
        }
    }
}
#[test]
fn three_dword_and_lds_96bit_transfers_preserve_all_components() {
    let instructions=COPY.replace("v_lshlrev_b32 v2, 2, v0","v_mul_lo_u32 v2, 12, v0").replace("global_load_dword v5","global_load_dwordx3 v[8:10]").replace("global_store_dword v[6:7], v5","global_store_dwordx3 v[6:7], v[8:10]").replace("s_waitcnt vmcnt(0)","s_waitcnt vmcnt(0)\nds_write_b96 v2, v[8:10]\ns_waitcnt lgkmcnt(0)\ns_barrier\nds_read_b96 v[8:10], v2\ns_waitcnt lgkmcnt(0)");
    let module = frontend::parse(&source(&instructions, 768)).unwrap();
    let result = analyze(&module, None, config(64, 192)).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 192);
    for index in 0..192 {
        assert!(
            matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::InputElement{index:found,..}if *found==index)
        );
    }
}
#[test]
fn inactive_vector_interval_records_no_register_obligations() {
    let instructions=COPY.replace("s_waitcnt lgkmcnt(0)","s_mov_b64 s[8:9], exec\ns_mov_b64 exec, 0\nv_add_u32 v5, s4, v0\ns_mov_b64 exec, s[8:9]\ns_waitcnt lgkmcnt(0)");
    let module = frontend::parse(&source(&instructions, 0)).unwrap();
    let result = analyze(&module, None, config(64, 64)).unwrap();
    assert!(result.symbolic_outputs().is_ok());
    assert!(result.graph.amd_events().iter().any(|event|matches!(&event.kind,volta_graph::AmdEventKind::Instruction{exec_mask:0,reads,writes}if reads.is_empty()&&writes.is_empty())));
}
#[test]
fn inactive_mask_result_records_pending_scalar_destination_overwrite() {
    use volta_graph::{AmdCounter, AmdEventKind, AmdRegister, AmdRegisterFile};
    let expected = [8, 9].map(|index| AmdRegister {
        file: AmdRegisterFile::Scalar,
        index,
        lanes: u64::MAX,
    });
    for operation in [
        "v_cmp_eq_u32 s[8:9], v0, v0",
        "v_add_co_u32 v8, s[8:9], v0, v0",
        "v_addc_co_u32 v8, s[8:9], v0, v0, vcc",
    ] {
        let instructions = COPY.replace(
            "s_endpgm",
            &format!("s_load_dwordx2 s[8:9], s[0:1], 0\ns_mov_b64 s[10:11], exec\ns_mov_b64 exec, 0\n{operation}\ns_mov_b64 exec, s[10:11]\ns_waitcnt lgkmcnt(0)\ns_endpgm"),
        );
        let module = frontend::parse(&source(&instructions, 0)).unwrap();
        let result = analyze(&module, None, config(64, 64)).unwrap();
        assert!(result.symbolic_outputs().is_ok(), "{operation}");
        let events = result.graph.amd_events();
        let issue = events
            .iter()
            .position(|event| {
                matches!(&event.kind,
                    AmdEventKind::MemoryIssue { counters, destinations, .. }
                    if counters == &vec![(AmdCounter::Lgkm, 2)] && destinations == &expected
                )
            })
            .unwrap();
        let overwrite = events
            .iter()
            .position(|event| {
                matches!(&event.kind,
                    AmdEventKind::Instruction { exec_mask: 0, reads, writes }
                    if reads.is_empty() && writes == &expected
                )
            })
            .unwrap();
        assert!(issue < overwrite);
        assert!(!events[issue + 1..overwrite].iter().any(|event| matches!(
            &event.kind,
            AmdEventKind::Wait {
                lgkmcnt: Some(0),
                ..
            }
        )));
        assert!(result.graph.validate().is_ok());
    }
}

#[test]
fn undefined_condition_flags_fail_closed_until_each_required_bit_is_defined() {
    let invalid = [
        "s_cbranch_scc0 .Lflag\n.Lflag:",
        "s_cbranch_vccz .Lflag\n.Lflag:",
        "s_cselect_b32 s8, 1, 0",
        "s_cselect_b64 s[8:9], 1, 0",
        "s_addc_u32 s8, 0, 0",
        "s_subb_u32 s8, 0, 0",
        "v_cndmask_b32 v8, v0, v0, vcc",
        "v_addc_co_u32 v8, vcc, v0, v0, vcc",
        "s_mov_b32 vcc_lo, 0\nv_cndmask_b32 v8, v0, v0, vcc",
        "s_mov_b32 vcc_hi, 0\nv_cndmask_b32 v8, v0, v0, vcc",
        "s_mov_b32 s8, vcc_lo",
        "s_mov_b32 s8, vcc_hi",
        "s_mul_i32 s8, 2, 3\ns_cbranch_scc0 .Lflag\n.Lflag:",
    ];
    for prefix in invalid {
        let module = frontend::parse(&source(&format!("{prefix}\n{COPY}"), 0)).unwrap();
        let result = analyze(&module, None, config(64, 64)).unwrap();
        let error = result.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("uninitialized"), "{prefix}: {error}");
        assert!(result.graph.validate().is_ok());
    }
    for prefix in [
        "s_mov_b64 vcc, 0\nv_cndmask_b32 v8, v0, v0, vcc",
        "s_mov_b32 vcc_lo, 0\ns_mov_b32 vcc_hi, 0\nv_cndmask_b32 v8, v0, v0, vcc",
        "s_mov_b32 vcc_lo, 0\ns_mov_b32 s8, vcc_lo",
        "s_mov_b32 vcc_hi, 0\ns_mov_b32 s8, vcc_hi",
        "s_mov_b32 s8, 7\ns_cmp_eq_u32 s8, 7\ns_mul_i32 s9, s8, 3\ns_cbranch_scc1 .Lflag\ns_mov_b64 exec, -1\n.Lflag:",
    ] {
        let module = frontend::parse(&source(&format!("{prefix}\n{COPY}"), 0)).unwrap();
        let result = analyze(&module, None, config(1, 1)).unwrap();
        assert!(result.symbolic_outputs().is_ok(), "{prefix}");
    }
}
#[test]
fn native_ocp_fp8_relu_and_activations_preserve_byte_identities() {
    let module = frontend::parse(include_str!("../src/frontend/fixtures/portable-f8.s")).unwrap();
    for (kernel, block, n) in [
        ("relu_f8", 128, 2048),
        ("silu_f8", 256, 1024),
        ("sigmoid_f8", 128, 1024),
    ] {
        let mut cfg = config(block, n);
        cfg.arrays[0].elem_width = 1;
        cfg.arrays[1].elem_width = 2;
        let result = analyze(&module, Some(kernel), cfg).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), n as usize);
        if kernel == "relu_f8" {
            for index in 0..n {
                let ExprNode::Max(a, b) =
                    outputs.arena.node(outputs.element("out", index).unwrap())
                else {
                    panic!("not max")
                };
                assert!([*a,*b].iter().any(|id|matches!(outputs.arena.node(*id),ExprNode::InputElement{index:found,..} if *found==index)));
            }
        }
    }
}
#[test]
fn mixed_half_rope_preserves_only_the_written_half() {
    let module = frontend::parse(include_str!("../src/frontend/fixtures/portable-f16.s")).unwrap();
    let mut cfg = AnalysisConfig::new((128, 1, 1));
    cfg.arrays = vec![
        array("x", 0x10000, 128, ArrayKind::Input),
        array("cosine", 0x20000, 128, ArrayKind::Input),
        array("sine", 0x30000, 128, ArrayKind::Input),
        array("out", 0x40000, 128, ArrayKind::Output),
    ];
    for array in &mut cfg.arrays {
        array.elem_width = 2;
    }
    cfg.params = ["x", "cosine", "sine", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .to_vec();
    let result = analyze(&module, Some("rope_f16"), cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 128);
    for index in 0..128 {
        assert!(matches!(
            outputs.arena.node(outputs.element("out", index).unwrap()),
            ExprNode::Fma(..)
        ));
    }
}
#[test]
fn native_pipelined_f16_mfma_preserves_32_term_dot_products() {
    let module = frontend::parse(include_str!(
        "../src/frontend/fixtures/clang22-pipelined-mfma-f16.s"
    ))
    .unwrap();
    let mut cfg = mfma_config();
    cfg.block_dim = (128, 1, 1);
    cfg.arrays[0].len = 1024;
    cfg.arrays[1].len = 512;
    cfg.arrays[2].len = 512;
    for array in &mut cfg.arrays {
        array.elem_width = 2;
    }
    let result = analyze(&module, None, cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 512);
    for row in 0..32u64 {
        for column in 0..16 {
            let mut terms = Vec::new();
            product_terms(
                &outputs.arena,
                outputs.element("out", row * 16 + column).unwrap(),
                &mut terms,
            );
            assert_eq!(
                terms,
                (0..32)
                    .map(|k| (row * 32 + k, k * 16 + column))
                    .collect::<Vec<_>>()
            );
        }
    }
}
#[test]
fn native_unit_scaled_fp8_mfma_preserves_interleaved_k_layout() {
    let source = include_str!("../src/frontend/fixtures/clang22-cdna4-mfma-types.s");
    let module = frontend::parse(source).unwrap();
    let mut cfg = mfma_config();
    cfg.arrays[0].len = 2048;
    cfg.arrays[1].len = 2048;
    cfg.arrays[0].elem_width = 1;
    cfg.arrays[1].elem_width = 1;
    let result = analyze(&module, Some("mfma_e4m3_k128"), cfg.clone()).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 256);
    for lane in 0..64u64 {
        for register in 0..4 {
            let row = 4 * (lane / 16) + register;
            let column = lane % 16;
            let mut terms = Vec::new();
            product_terms(
                &outputs.arena,
                outputs.element("out", 4 * lane + register).unwrap(),
                &mut terms,
            );
            let location = |coordinate: u64, k: u64| {
                (coordinate + 16 * ((k / 16) % 4)) * 32 + k % 16 + 16 * (k / 64)
            };
            assert_eq!(
                terms,
                (0..128)
                    .map(|k| (location(row, k), location(column, k)))
                    .collect::<Vec<_>>()
            );
        }
    }
    let source = source.replace("v1, 0x7f", "v1, 0x80");
    let module = frontend::parse(&source).unwrap();
    let result = analyze(&module, Some("mfma_e4m3_k128"), cfg).unwrap();
    assert!(result.symbolic_outputs().is_err());
}
fn config_from_manifest(text: &str, index: usize) -> (String, AnalysisConfig) {
    let manifest: serde_yaml::Value = serde_yaml::from_str(text).unwrap();
    let case = &manifest["cases"][index];
    let dim = |name| {
        let values = case[name].as_sequence().unwrap();
        (
            values[0].as_u64().unwrap() as u32,
            values[1].as_u64().unwrap() as u32,
            values[2].as_u64().unwrap() as u32,
        )
    };
    let mut cfg = AnalysisConfig::new(dim("block"));
    cfg.grid_dim = dim("grid");
    for array in case["arrays"].as_sequence().unwrap() {
        cfg.arrays.push(ArrayDef {
            name: array["name"].as_str().unwrap().into(),
            base: array["base_address"].as_u64().unwrap(),
            elem_width: array["element_size"].as_u64().unwrap(),
            len: array["length"].as_u64().unwrap(),
            kind: match array["kind"].as_str().unwrap() {
                "in" => ArrayKind::Input,
                "out" => ArrayKind::Output,
                "inout" => ArrayKind::InputOutput,
                other => panic!("unknown arraykind {other}"),
            },
        });
    }
    for param in case["params"].as_sequence().unwrap() {
        let param = param.as_str().unwrap();
        let (kind, value) = param.split_once(':').unwrap();
        cfg.params.push(match kind {
            "ptr" => ParamValue::ArrayPtr(value.into()),
            "int" => ParamValue::Int(value.parse().unwrap()),
            "float" => ParamValue::Float(value.parse().unwrap()),
            other => panic!("unknown param {other}"),
        });
    }
    (case["kernel"].as_str().unwrap().into(), cfg)
}
#[test]
fn native_convolution_retains_original_576_term_reduction_and_pitches() {
    let module = frontend::parse(include_str!(
        "../src/frontend/fixtures/native-convolution.s"
    ))
    .unwrap();
    let (name, cfg) = config_from_manifest(
        include_str!("../src/frontend/fixtures/convolution-cases.json"),
        0,
    );
    let result = analyze(&module, Some(&name), cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 16);
    for (_, elements) in &outputs.outputs {
        assert_eq!(elements.len(), 32);
    }
}
#[test]
fn native_reduced_attention_executes_qk_pv_online_softmax_and_lse() {
    let module = frontend::parse(include_str!(
        "../src/frontend/fixtures/native-flash-attention.s"
    ))
    .unwrap();
    let (name, cfg) = config_from_manifest(
        include_str!("../src/frontend/fixtures/attention-cases.json"),
        0,
    );
    let result = analyze(&module, Some(&name), cfg).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(
        outputs
            .outputs
            .iter()
            .map(|(_, elements)| elements.len())
            .sum::<usize>(),
        2080
    );
    assert!(result.stats.warp_syncs >= 16);
}
#[test]
fn invalid_partial_exec_and_unmodeled_special_data_fail_without_panicking() {
    let partial = source(&format!("s_mov_b64 exec, -1\n{COPY}"), 0);
    let module = frontend::parse(&partial).unwrap();
    let result = analyze(&module, None, config(1, 1)).unwrap();
    assert!(matches!(
        result.symbolic_outputs(),
        Err(volta_amdgpu_analysis::OutputsUnavailable::Aborted(
            volta_amdgpu_analysis::EvalError::Unsupported { .. }
        ))
    ));
    assert!(result.graph.validate().is_ok());
    for operand in ["m0", "vcc_lo", "exec_lo"] {
        let instructions = COPY.replace(
            "s_waitcnt vmcnt(0)",
            &format!("s_waitcnt vmcnt(0)\nv_mov_b32 v5, {operand}"),
        );
        let module = frontend::parse(&source(&instructions, 0)).unwrap();
        let result = analyze(&module, None, config(64, 64)).unwrap();
        assert!(matches!(
            result.symbolic_outputs(),
            Err(volta_amdgpu_analysis::OutputsUnavailable::Aborted(
                volta_amdgpu_analysis::EvalError::Unsupported { .. }
            ))
        ));
        assert!(result.graph.validate().is_ok());
    }
}
