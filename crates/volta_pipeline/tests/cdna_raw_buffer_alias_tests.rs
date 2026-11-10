//! A raw X4 store holds each data word once when VADDR aliases the tuple.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, frontend};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

fn run(target: &str, address_word: u16, after: &str, sparse: bool) -> gfx950_common::Checked {
    let source = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
s_mov_b32 s8,0x20000
s_mov_b32 s9,0
s_mov_b32 s10,1024
s_mov_b32 s11,0x20000
v_add_u32 v4,4096,v0
v_add_u32 v5,4196,v0
v_add_u32 v6,4296,v0
v_add_u32 v7,4396,v0
v_lshlrev_b32 v16,4,v0
v_mov_b32 v{address_word},v16
{mask}
buffer_store_dwordx4 v[4:7],v{address_word},s[8:11],0 offen
{after}
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_system_vgpr_workitem_id 0
.end_amdhsa_kernel
"#,
        mask = if sparse {
            "s_mov_b32 exec_lo,1\ns_mov_b32 exec_hi,0x80000001"
        } else {
            ""
        }
    );
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 256,
        kind: ArrayKind::Output,
    });
    let checked = gfx950_common::check(&source, &module, Some("k"), config).unwrap();
    checked.analysis.graph().validate().unwrap();
    checked
}

fn assert_values(checked: &gfx950_common::Checked, address_word: u16, sparse: bool) {
    let outputs = checked.analysis.symbolic_outputs().unwrap();
    let lanes: Vec<u64> = if sparse {
        vec![0, 32, 63]
    } else {
        (0..64).collect()
    };
    let expected_indices: Vec<_> = lanes
        .iter()
        .flat_map(|lane| (0..4).map(move |word| lane * 4 + word))
        .collect();
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        expected_indices
    );
    for lane in lanes {
        for word in 0..4 {
            let expected = if word + 4 == u64::from(address_word) {
                lane * 16
            } else {
                4096 + word * 100 + lane
            };
            assert_eq!(
                outputs
                    .arena
                    .as_int_const(outputs.element("out", lane * 4 + word).unwrap()),
                Some(expected as i64),
                "lane{lane}/word{word}"
            );
        }
    }
    let issues: Vec<_> = checked
        .analysis
        .graph()
        .amd_events()
        .iter()
        .filter_map(|event| {
            if let AmdEventKind::MemoryIssue {
                class,
                counters,
                held_sources,
                destinations,
            } = &event.kind
            {
                Some((class, counters, held_sources, destinations))
            } else {
                None
            }
        })
        .collect();
    assert_eq!(issues.len(), 1);
    let (class, counters, held, destinations) = issues[0];
    assert_eq!(*class, AmdMemoryClass::VectorStoreWide);
    assert_eq!(counters, &[(AmdCounter::Vm, 1)]);
    assert!(destinations.is_empty());
    assert_eq!(held.len(), 4);
    for (word, register) in held.iter().enumerate() {
        assert_eq!(register.file, AmdRegisterFile::Vector);
        assert_eq!(register.index, 4 + word as u16);
        assert_eq!(
            register.lanes,
            if sparse {
                1 | (1 << 32) | (1 << 63)
            } else {
                u64::MAX
            }
        );
    }
}

#[test]
fn every_x4_data_word_can_also_address_the_complete_store() {
    for target in ["gfx942", "gfx950"] {
        for address_word in 4..8 {
            for sparse in [false, true] {
                let checked = run(target, address_word, "", sparse);
                assert_values(&checked, address_word, sparse);
                assert_eq!(
                    checked.checks.conclusion(),
                    GraphConclusion::Verified,
                    "{target}/v{address_word}: {:?}",
                    checked.checks
                );
            }
        }
    }
}

#[test]
fn aliasing_an_address_does_not_remove_any_data_words_two_state_lifetime() {
    for target in ["gfx942", "gfx950"] {
        for address_word in 4..8 {
            for overwritten_word in 4..8 {
                for states in [0, 1, 2] {
                    let after =
                        "s_nop 0\n".repeat(states) + &format!("v_mov_b32 v{overwritten_word},0");
                    let checked = run(target, address_word, &after, false);
                    assert_values(&checked, address_word, false);
                    if states == 2 {
                        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
                    } else {
                        assert!(
                            matches!(
                                checked.checks.conclusion(),
                                GraphConclusion::Rejected { .. }
                            ),
                            "{:?}",
                            checked.checks
                        );
                        let PropertyResult::Fail(hazards) =
                            &checked.checks.amd.as_ref().unwrap().wait_readiness
                        else {
                            panic!("wide data-source timing")
                        };
                        assert!(
                            hazards
                                .iter()
                                .any(|h| h.kind == AmdRegisterHazardKind::SourceReuse
                                    && h.register.file == AmdRegisterFile::Vector
                                    && h.register.index == overwritten_word),
                            "{hazards:?}"
                        );
                    }
                }
            }
            // The separate address copy is not data and has no retained lifetime.
            let checked = run(target, address_word, "v_mov_b32 v16,0", false);
            assert_values(&checked, address_word, false);
            assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
        }
    }
}
