//! CDNA4 raw DWORDX2 values and VM readiness use independent execution/checking.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

const LOAD: &str = "buffer_load_dwordx2 v[0:1],v4,s[8:11],0 offen";
const STORE: &str = "buffer_store_dwordx2 v[0:1],v4,s[12:15],0 offen";

fn run(body: &str, block: u32, len: u64) -> gfx950_common::Checked {
    let source = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.type k,@function
k:
s_load_dwordx2 s[12:13],s[0:1],16
s_load_dwordx4 s[8:11],s[0:1],32
s_waitcnt lgkmcnt(0)
s_mov_b32 s14,{bytes}
s_mov_b32 s15,0x20000
v_lshlrev_b32 v4,3,v0
{body}
s_waitcnt vmcnt(0)
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 48
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: input_gl
        .offset: 0
        .size: 16
        .value_kind: by_value
      - .name: output_gl
        .offset: 16
        .size: 16
        .value_kind: by_value
      - .name: resource
        .offset: 32
        .size: 16
        .value_kind: by_value
...
.end_amdgpu_metadata
"#,
        bytes = len * 4
    );
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len,
            kind: ArrayKind::Output,
        },
    ];
    let gl = |base: u32| {
        ParamValue::Bytes(
            [base, 0, 0, 0]
                .into_iter()
                .flat_map(u32::to_le_bytes)
                .collect(),
        )
    };
    config.params = vec![
        gl(0x10000),
        gl(0x20000),
        ParamValue::Bytes(
            [0x10000u32, 0, (len * 4) as u32, 0x20000]
                .into_iter()
                .flat_map(u32::to_le_bytes)
                .collect(),
        ),
    ];
    let module = frontend::parse(&source).unwrap();
    let checked = gfx950_common::check(&source, &module, Some("k"), config).unwrap();
    checked.analysis.graph().validate().unwrap();
    checked
}

fn math(checked: &gfx950_common::Checked, len: u64, first: u64, add: i64) -> EquivOutcome {
    let mut arena = ExprArena::new();
    let name = arena.intern_string("x");
    let constant = arena.int(add);
    let values = (0..len)
        .map(|i| {
            let input = arena.input_element(name, first + i);
            (i, arena.add(input, constant))
        })
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    };
    check_output_equivalence(
        checked.analysis.symbolic_outputs().unwrap(),
        &expected,
        &["out".into()],
    )
    .unwrap()
}

fn assert_hazard(checked: &gfx950_common::Checked, file: AmdRegisterFile, index: u16) {
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:?}",
        checked.checks
    );
    let PropertyResult::Fail(hazards) = &checked.checks.amd.as_ref().unwrap().wait_readiness else {
        panic!("readiness finding")
    };
    assert!(
        hazards
            .iter()
            .any(|h| h.kind == AmdRegisterHazardKind::ReadBeforeReady
                && h.register.file == file
                && h.register.index == index),
        "{hazards:?}"
    );
}

#[test]
fn complete_two_word_copy_and_packed_add_match_full_output_specs_and_refute_swaps() {
    for block in [1, 32, 48, 64] {
        let len = block * 2;
        for (arithmetic, add) in [
            ("", 0),
            ("v_pk_add_f32 v[0:1],v[0:1],1.0 op_sel_hi:[1,0]", 1),
        ] {
            // Genuine N96/N128 maps sources replace SRSRC before VM0 and use
            // this pair arithmetic; no CDNA5 held-source lease is introduced.
            let checked = run(
                &format!(
                    "{LOAD}\ns_mov_b64 s[8:9],s[12:13]\ns_waitcnt vmcnt(0)\n{arithmetic}\nbuffer_store_dwordx2 v[0:1],v4,s[8:11],0 offen"
                ),
                block,
                len.into(),
            );
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
            assert!(matches!(
                math(&checked, len.into(), 0, add),
                EquivOutcome::Equivalent
            ));
            assert!(
                matches!(math(&checked,len.into(),0,add+1),EquivOutcome::NotEquivalent{mismatches}if !mismatches.is_empty())
            );
            let mut arena = ExprArena::new();
            let name = arena.intern_string("x");
            let c = arena.int(add);
            let swapped = (0..u64::from(len))
                .map(|i| {
                    let x = arena.input_element(name, i ^ 1);
                    (i, arena.add(x, c))
                })
                .collect();
            let wrong = SymbolicOutputs {
                arena,
                outputs: vec![("out".into(), swapped)],
            };
            assert!(
                matches!(check_output_equivalence(checked.analysis.symbolic_outputs().unwrap(),&wrong,&["out".into()]).unwrap(),EquivOutcome::NotEquivalent{mismatches}if !mismatches.is_empty())
            );
        }
    }
}

#[test]
fn both_pending_result_words_and_all_descriptor_words_keep_independent_readiness() {
    for wait in ["s_waitcnt vmcnt(0)", "", "s_waitcnt lgkmcnt(0) expcnt(0)"] {
        for use_math in [false, true] {
            let arithmetic = if use_math {
                "v_pk_add_f32 v[0:1],v[0:1],1.0 op_sel_hi:[1,0]"
            } else {
                ""
            };
            let checked = run(&format!("{LOAD}\n{wait}\n{arithmetic}\n{STORE}"), 32, 64);
            assert!(matches!(
                math(&checked, 64, 0, i64::from(use_math)),
                EquivOutcome::Equivalent
            ));
            if wait == "s_waitcnt vmcnt(0)" {
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
            } else {
                for word in 0..2 {
                    assert_hazard(&checked, AmdRegisterFile::Vector, word);
                }
            }
        }
    }
    for word in 0..4 {
        for wait in ["s_waitcnt lgkmcnt(0)", "", "s_waitcnt vmcnt(0) expcnt(0)"] {
            let checked = run(
                &format!(
                    "s_load_dword s{},s[0:1],{}\n{wait}\n{LOAD}\ns_waitcnt vmcnt(0)\n{STORE}",
                    8 + word,
                    32 + 4 * word
                ),
                1,
                2,
            );
            assert!(matches!(math(&checked, 2, 0, 0), EquivOutcome::Equivalent));
            if wait == "s_waitcnt lgkmcnt(0)" {
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
            } else {
                assert_hazard(&checked, AmdRegisterFile::Scalar, 8 + word as u16);
            }
        }
    }
}

#[test]
fn vm_is_charged_once_and_both_components_keep_exact_lane_and_register_provenance() {
    use volta_graph::{AccessMode, EventKind, Footprint, Space};
    let checked = run(&format!("{LOAD}\ns_waitcnt vmcnt(0)\n{STORE}"), 2, 4);
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let graph = checked.analysis.graph();
    let issues: Vec<_> = graph
        .amd_events()
        .iter()
        .filter_map(|r| match &r.kind {
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::VectorMemory,
                counters,
                destinations,
                held_sources,
            } => Some((r, counters, destinations, held_sources)),
            _ => None,
        })
        .collect();
    assert_eq!(issues.len(), 2);
    for (ordinal, (record, counters, destinations, held)) in issues.iter().enumerate() {
        assert_eq!(counters.as_slice(), &[(AmdCounter::Vm, 1)]);
        assert!(held.is_empty());
        if ordinal == 0 {
            assert_eq!(destinations.len(), 2);
            for word in 0..2 {
                assert!(
                    destinations
                        .iter()
                        .any(|r| r.file == AmdRegisterFile::Vector
                            && r.index == word
                            && r.lanes == 3)
                );
            }
        } else {
            assert!(destinations.is_empty());
        }
        let links: Vec<_> = graph
            .amd_memory_effects()
            .iter()
            .filter(|e| e.issue == record.event)
            .collect();
        assert_eq!(links.len(), 4);
        for (i, link) in links.iter().enumerate() {
            let event = graph.event(link.effect);
            let EventKind::Access(id) = event.kind else {
                panic!("memory effect")
            };
            let access = graph.access(id);
            assert_eq!(access.space, Space::Global);
            assert_eq!(
                access.mode,
                if ordinal == 0 {
                    AccessMode::Read
                } else {
                    AccessMode::Write
                }
            );
            assert_eq!(access.attributed.0, (i / 2) as u32);
            assert_eq!(
                access.footprint,
                Footprint::Bytes {
                    addr: if ordinal == 0 { 0x10000 } else { 0x20000 } + (i as u64) * 4,
                    width: 4
                }
            );
        }
        let pc = graph.event(record.event).pc;
        let reads = graph
            .amd_events()
            .iter()
            .find_map(|r| match &r.kind {
                AmdEventKind::Instruction { reads, .. } if graph.event(r.event).pc == pc => {
                    Some(reads)
                }
                _ => None,
            })
            .unwrap();
        for index in if ordinal == 0 { 8..12 } else { 12..16 } {
            assert!(
                reads
                    .iter()
                    .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
            );
        }
        assert!(
            reads
                .iter()
                .any(|r| r.file == AmdRegisterFile::Vector && r.index == 4 && r.lanes == 3)
        );
        if ordinal == 1 {
            for word in 0..2 {
                assert!(
                    reads.iter().any(|r| r.file == AmdRegisterFile::Vector
                        && r.index == word
                        && r.lanes == 3)
                );
            }
        }
    }
}
