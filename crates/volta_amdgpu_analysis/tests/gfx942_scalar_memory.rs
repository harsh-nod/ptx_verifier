//! CDNA3 §8.2.1.1 masks each address component before adding it.
//! Wide SMEM reads snapshot their address before an aliased destination changes.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend,
};
use volta_expr::ExprNode;
use volta_graph::{AmdEventKind, AmdMemoryClass, AmdRegisterFile, Terminal};
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

fn source(words: u32, wait: &str, empty_exec: bool) -> String {
    assert!(matches!(words, 2 | 4));
    let enter = if empty_exec {
        "s_and_saveexec_b64 s[10:11],0"
    } else {
        ""
    };
    let leave = if empty_exec {
        "s_mov_b64 exec,s[10:11]"
    } else {
        ""
    };
    let moves = (0..words)
        .map(|word| format!("v_mov_b32 v{},s{}\n", word + 4, word + 4))
        .collect::<String>();
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
.text
.type k,@function
k:
s_load_dwordx4 s[4:7],s[0:1],0
s_waitcnt lgkmcnt(0)
s_mov_b64 s[12:13],s[6:7]
s_add_u32 s4,s4,3
s_addc_u32 s5,s5,0
s_mov_b32 s8,19
{enter}
s_load_dwordx{words} s[4:{last}],s[4:5],s8 offset:19
{wait}
{leave}
{moves}
v_lshlrev_b32 v2,{shift},v0
global_store_dwordx{words} v2,v[4:{last}],s[12:13]
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 16
.amdhsa_next_free_vgpr 8
.amdhsa_accum_offset 8
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .sgpr_count: 16
    .vgpr_count: 8
    .wavefront_size: 64
    .max_flat_workgroup_size: 64
    .args:
      - .name: x
        .offset: 0
        .size: 8
        .value_kind: global_buffer
        .address_space: global
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
        .address_space: global
...
.end_amdgpu_metadata
"#,
        last = words + 3,
        shift = if words == 2 { 3 } else { 4 },
    )
}

fn config(words: u32, block: u32, base: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base,
            elem_width: 4,
            len: 12,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x30000,
            elem_width: 4,
            len: u64::from(words * block),
            kind: ArrayKind::Output,
        },
    ];
    config.params = ["x", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    config
}

fn run(words: u32, wait: &str, empty_exec: bool, config: AnalysisConfig) -> AnalysisResult {
    let module = frontend::parse(&source(words, wait, empty_exec)).unwrap();
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn complete_words(result: &AnalysisResult, words: u32, block: u32) {
    assert_eq!(result.graph().terminal(), &Terminal::Completed);
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    let elements = &outputs.outputs[0].1;
    assert_eq!(elements.len(), (words * block) as usize);
    for (expected_index, &(index, expression)) in elements.iter().enumerate() {
        assert_eq!(index, expected_index as u64);
        let ExprNode::InputElement {
            array,
            index: input,
        } = outputs.arena.node(expression)
        else {
            panic!("expected an unchanged input word at out[{index}]");
        };
        assert_eq!(outputs.arena.string(*array), "x");
        // The three discarded component residues must not combine into a carry:
        // (base+3)&~3 + 19&~3 + 19&~3 = base+32.
        assert_eq!(*input, 8 + index % u64::from(words));
    }
}

#[test]
fn wide_loads_mask_components_before_addition_and_snapshot_the_aliased_base() {
    for words in [2, 4] {
        for block in [1, 32, 64] {
            for base in [0x10000, 0xffff_fffc, 0x1_0001_0000] {
                for empty_exec in [false, true] {
                    let result = run(
                        words,
                        "s_waitcnt lgkmcnt(0)",
                        empty_exec,
                        config(words, block, base),
                    );
                    complete_words(&result, words, block);
                    assert_eq!(
                        check_graph(result.graph()).conclusion(),
                        GraphConclusion::Verified
                    );
                }
            }
        }
    }
}

#[test]
fn every_loaded_word_needs_lgkm_completion_even_when_exec_was_empty() {
    for words in [2, 4] {
        for wait in ["", "s_waitcnt vmcnt(0)", "s_waitcnt lgkmcnt(1)"] {
            let result = run(words, wait, true, config(words, 64, 0x10000));
            complete_words(&result, words, 64);
            let checks = check_graph(result.graph());
            assert_eq!(checks.verdict(Property::AmdTrace), Verdict::Pass);
            assert_eq!(checks.verdict(Property::AmdWaitReadiness), Verdict::Fail);
            assert!(matches!(
                checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
            let hazards = checks.amd.as_ref().unwrap().wait_readiness.violations();
            for word in 4..4 + words {
                assert!(
                    hazards.iter().any(|hazard| {
                        hazard.register.file == AmdRegisterFile::Scalar
                            && hazard.register.index == word as u16
                    }),
                    "missing readiness obligation for s{word}: {checks:#?}"
                );
            }
        }
    }
}

#[test]
fn masking_keeps_the_full_wide_allocation_footprint() {
    let mut config = config(4, 64, 0x10000);
    config.arrays[0].len = 11;
    let result = run(4, "s_waitcnt lgkmcnt(0)", true, config);
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("out-of-bounds")
    );
    assert!(matches!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Unknown { .. }
    ));
    assert!(!result.graph().amd_events().iter().any(|event| {
        matches!(
            event.kind,
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::VectorStoreWide,
                ..
            }
        )
    }));
}
