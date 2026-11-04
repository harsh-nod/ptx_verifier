//! CDNA4 raw DWORD values and VM readiness use independent execution/checking.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

const LOAD: &str = "buffer_load_dword v1,v2,s[8:11],0 offen";
const STORE: &str = "buffer_store_dword v1,v2,s[12:15],0 offen";

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
v_lshlrev_b32 v2,2,v0
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
fn full_output_copy_and_add_one_survive_descriptor_reuse_before_vm_completion() {
    for len in [1, 32, 64] {
        for (arithmetic, add) in [("", 0), ("v_add_f32 v1,1.0,v1", 1)] {
            // The actual maps kernel replaces the descriptor base immediately
            // after load issuance. CDNA4 does not impose the C5 X-source lease.
            let checked = run(
                &format!(
                    "{LOAD}\ns_mov_b64 s[8:9],s[12:13]\ns_waitcnt vmcnt(0)\n{arithmetic}\nbuffer_store_dword v1,v2,s[8:11],0 offen"
                ),
                len as u32,
                len,
            );
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
            assert!(matches!(
                math(&checked, len, 0, add),
                EquivOutcome::Equivalent
            ));
            assert!(matches!(
                math(&checked, len, 0, add + 1),
                EquivOutcome::NotEquivalent { mismatches } if !mismatches.is_empty()
            ));
        }
    }
}

#[test]
fn all_descriptor_words_require_lgkm_and_load_results_require_vm() {
    for word in 0..4 {
        for wait in ["s_waitcnt lgkmcnt(0)", "", "s_waitcnt vmcnt(0) expcnt(0)"] {
            let checked = run(
                &format!(
                    "s_load_dword s{},s[0:1],{}\n{wait}\n{LOAD}\ns_waitcnt vmcnt(0)\n{STORE}",
                    8 + word,
                    32 + 4 * word
                ),
                1,
                1,
            );
            assert!(matches!(math(&checked, 1, 0, 0), EquivOutcome::Equivalent));
            if wait == "s_waitcnt lgkmcnt(0)" {
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
            } else {
                assert_hazard(&checked, AmdRegisterFile::Scalar, 8 + word as u16);
            }
        }
    }
    for wait in ["s_waitcnt vmcnt(0)", "", "s_waitcnt lgkmcnt(0) expcnt(0)"] {
        let checked = run(
            &format!("{LOAD}\n{wait}\nv_add_f32 v1,1.0,v1\n{STORE}"),
            32,
            32,
        );
        assert!(matches!(math(&checked, 32, 0, 1), EquivOutcome::Equivalent));
        if wait == "s_waitcnt vmcnt(0)" {
            assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
        } else {
            assert_hazard(&checked, AmdRegisterFile::Vector, 1);
        }
        let store = run(&format!("{LOAD}\n{wait}\n{STORE}"), 32, 32);
        assert!(matches!(math(&store, 32, 0, 0), EquivOutcome::Equivalent));
        if wait == "s_waitcnt vmcnt(0)" {
            assert_eq!(store.checks.conclusion(), GraphConclusion::Verified);
        } else {
            assert_hazard(&store, AmdRegisterFile::Vector, 1);
        }
    }
}

#[test]
fn asynchronous_vector_offset_needs_vm_even_when_its_eager_bits_are_known() {
    for wait in ["s_waitcnt vmcnt(0)", "", "s_waitcnt lgkmcnt(0) expcnt(0)"] {
        let checked = run(
            &format!(
                "v_mov_b32 v1,4\n{STORE}\ns_waitcnt vmcnt(0)\nglobal_load_dword v2,v2,s[12:13]\n{wait}\n{LOAD}\ns_waitcnt vmcnt(0)\nv_mov_b32 v2,0\n{STORE}"
            ),
            1,
            2,
        );
        // Two output cells exist; only out[0] is defined in this address probe.
        let outputs = checked.analysis.symbolic_outputs().unwrap();
        assert!(matches!(
            outputs.arena.node(outputs.element("out", 0).unwrap()),
            volta_expr::ExprNode::InputElement { index: 1, .. }
        ));
        if wait == "s_waitcnt vmcnt(0)" {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
        } else {
            assert_hazard(&checked, AmdRegisterFile::Vector, 2);
        }
    }
}

#[test]
fn ordinary_buffer_issues_preserve_all_roles_and_charge_only_vm() {
    let checked = run(&format!("{LOAD}\ns_waitcnt vmcnt(0)\n{STORE}"), 1, 1);
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let issues: Vec<_> = checked
        .analysis
        .graph()
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
    for (_, counters, _, held) in &issues {
        assert_eq!(counters.as_slice(), &[(AmdCounter::Vm, 1)]);
        assert!(held.is_empty());
    }
    assert_eq!(issues[0].2.len(), 1);
    assert!(issues[1].2.is_empty());
    let pc = checked.analysis.graph().event(issues[0].0.event).pc;
    let reads = checked
        .analysis
        .graph()
        .amd_events()
        .iter()
        .find_map(|r| match &r.kind {
            AmdEventKind::Instruction { reads, .. }
                if checked.analysis.graph().event(r.event).pc == pc =>
            {
                Some(reads)
            }
            _ => None,
        })
        .unwrap();
    for index in 8..12 {
        assert!(
            reads
                .iter()
                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
        );
    }
    assert!(
        reads
            .iter()
            .any(|r| r.file == AmdRegisterFile::Vector && r.index == 2)
    );
}
