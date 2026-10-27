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
fn compiler_exchange_and_relu(){
    let module=frontend::parse(include_str!("../src/frontend/fixtures/clang22-exchange-reduce-relu.s")).unwrap();
    let result=analyze(&module,Some("exchange"),config(128,128)).unwrap();let outputs=result.symbolic_outputs().unwrap();assert_eq!(outputs.outputs[0].1.len(),128);for index in 0..128{assert!(matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::InputElement{index:found,..} if *found==(index^64)));}
    let result=analyze(&module,Some("relu"),config(128,128)).unwrap();let outputs=result.symbolic_outputs().unwrap();assert_eq!(outputs.outputs[0].1.len(),128);for index in 0..128{assert!(matches!(outputs.arena.node(outputs.element("out",index).unwrap()),ExprNode::Max(..)));}
}

fn leaf_weights(arena:&volta_expr::ExprArena,expr:volta_expr::ExprId,weights:&mut std::collections::BTreeMap<u64,u32>){
    match arena.node(expr){ExprNode::InputElement{index,..}=>*weights.entry(*index).or_default()+=1,ExprNode::Add(a,b)=>{leaf_weights(arena,*a,weights);leaf_weights(arena,*b,weights);},node=>panic!("unexpected reduction node {node:?}")}
}

#[test]
fn compiler_wave64_reduction_has_each_input_exactly_once(){
    let module=frontend::parse(include_str!("../src/frontend/fixtures/clang22-exchange-reduce-relu.s")).unwrap();
    let mut cfg=config(128,128);cfg.arrays[1].len=2;let result=analyze(&module,Some("reduce"),cfg).unwrap();let outputs=result.symbolic_outputs().unwrap();assert_eq!(outputs.outputs[0].1.len(),2);
    for output in 0..2 {let mut weights=std::collections::BTreeMap::new();leaf_weights(&outputs.arena,outputs.element("out",output).unwrap(),&mut weights);assert_eq!(weights.len(),64);for index in output*64..output*64+64{assert_eq!(weights.get(&index),Some(&1));}}
}
fn product_terms(arena:&volta_expr::ExprArena,expr:volta_expr::ExprId,terms:&mut Vec<(u64,u64)>){
    match arena.node(expr){
        ExprNode::Add(a,b)=>{product_terms(arena,*a,terms);product_terms(arena,*b,terms);},
        ExprNode::Mul(a,b)=>{
            let input=|id|match arena.node(id){ExprNode::InputElement{array,index}=>(arena.string(*array),*index),node=>panic!("unexpected factor {node:?}")};
            let (name_a,index_a)=input(*a);let(name_b,index_b)=input(*b);assert_eq!(name_a,"a");assert_eq!(name_b,"b");terms.push((index_a,index_b));
        },
        node=>panic!("unexpected matrix term {node:?}")
    }
}
fn mfma_config()->AnalysisConfig{
    let mut cfg=AnalysisConfig::new((64,1,1));cfg.arrays=vec![array("a",0x10000,64,ArrayKind::Input),array("b",0x20000,64,ArrayKind::Input),array("out",0x30000,256,ArrayKind::Output)];cfg.params=vec![ParamValue::ArrayPtr("a".into()),ParamValue::ArrayPtr("b".into()),ParamValue::ArrayPtr("out".into())];cfg
}
#[test]
fn native_mfma_all_256_coordinates_match_independent_dot_products(){
    let module=frontend::parse(include_str!("../src/frontend/fixtures/clang22-mfma-f32.s")).unwrap();
    let result=analyze(&module,None,mfma_config()).unwrap();let outputs=result.symbolic_outputs().unwrap();assert_eq!(outputs.outputs[0].1.len(),256);
    for lane in 0..64u64 {for register in 0..4{let row=4*(lane/16)+register;let column=lane%16;let index=4*lane+register;let mut terms=Vec::new();product_terms(&outputs.arena,outputs.element("out",index).unwrap(),&mut terms);assert_eq!(terms,(0..4).map(|k|(row+16*k,column+16*k)).collect::<Vec<_>>());}}
    assert_eq!(result.stats.warp_syncs,1);assert!(result.graph.validate().is_ok());
}

#[test]
fn mfma_partial_wave_and_nonzero_layout_modifiers_are_incomplete(){
    let text=include_str!("../src/frontend/fixtures/clang22-mfma-f32.s");let module=frontend::parse(text).unwrap();let mut cfg=mfma_config();cfg.block_dim=(63,1,1);let result=analyze(&module,None,cfg).unwrap();assert!(result.symbolic_outputs().is_err());
    let text=text.replace("v[2:5], v2, v3, 0","v[2:5], v2, v3, 0 blgp:1");let module=frontend::parse(&text).unwrap();let result=analyze(&module,None,mfma_config()).unwrap();assert!(result.symbolic_outputs().is_err());
}

#[test]
fn explicit_global_values_and_abi_count_mismatch_are_rejected(){
    let text=source(COPY,0);let module=frontend::parse(&text).unwrap();let mut cfg=config(64,64);cfg.global_values.push(("undeclared".into(),7));assert!(analyze(&module,None,cfg).is_err());
    let text=text.replace(".amdhsa_kernarg_size 16",".amdhsa_kernarg_size 16\n.amdhsa_user_sgpr_count 4");let module=frontend::parse(&text).unwrap();assert!(analyze(&module,None,config(64,64)).is_err());
}
#[test]
fn compiler_packed_f16_relu_preserves_each_half_identity(){
    let module=frontend::parse(include_str!("../src/frontend/fixtures/portable-f16.s")).unwrap();
    let mut cfg=config(128,1024);for array in &mut cfg.arrays{array.elem_width=2;}
    let result=analyze(&module,Some("relu_f16"),cfg).unwrap();let outputs=result.symbolic_outputs().unwrap();assert_eq!(outputs.outputs[0].1.len(),1024);
    for index in 0..1024{let root=outputs.element("out",index).unwrap();let ExprNode::Max(a,b)=outputs.arena.node(root)else{panic!("not max for {index}")};let identity=|id|matches!(outputs.arena.node(id),ExprNode::InputElement{index:found,..} if *found==index);assert!(identity(*a)||identity(*b));}
}
