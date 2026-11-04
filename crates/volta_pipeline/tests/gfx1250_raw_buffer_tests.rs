//! Raw-buffer values, load readiness, replay leases and memory effects stay separate.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_expr::ExprNode;
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

const LOAD: &str = "buffer_load_b128 v[2:5],v0,s[12:15],null offen";
const STORE: &str = "buffer_store_b64 v[2:3],v1,s[16:19],null offen";

fn run(body: &str) -> gfx950_common::Checked {
    let text = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_load_b128 s[12:15],s[0:1],8
s_wait_kmcnt 0
s_wait_xcnt 0
s_mov_b32 s16,0x20000
s_mov_b32 s17,0x20000000
s_mov_b32 s18,0
s_mov_b32 s19,0
v_mov_b32 v0,0
v_mov_b32 v1,0
{body}
s_wait_loadcnt 0
s_wait_xcnt 0
{STORE}
buffer_store_b64 v[4:5],v1,s[16:19],null offen offset:8
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 24
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
      - .name: descriptor
        .offset: 8
        .size: 16
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    );
    let module = frontend::parse(&text).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "input".into(),
            base: 0x10000,
            elem_width: 4,
            len: 16,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::Output,
        },
    ];
    let bytes = [0x10000u32, 0x80000000, 0, 0]
        .into_iter()
        .flat_map(u32::to_le_bytes)
        .collect();
    config.params = vec![ParamValue::ArrayPtr("out".into()), ParamValue::Bytes(bytes)];
    gfx950_common::check(&text, &module, Some("k"), config).unwrap()
}

fn assert_values(checked: &gfx950_common::Checked, first: u64) {
    let outputs = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 4);
    for index in 0..4 {
        let ExprNode::InputElement {
            array,
            index: actual,
        } = outputs.arena.node(outputs.element("out", index).unwrap())
        else {
            panic!("input transport")
        };
        assert_eq!(outputs.arena.string(*array), "input");
        assert_eq!(*actual, first + index);
    }
}

fn assert_hazard(
    checked: &gfx950_common::Checked,
    kind: AmdRegisterHazardKind,
    file: AmdRegisterFile,
    index: u16,
) {
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "missing {kind:?} at {file:?}{index}: {:?}",
        checked.checks.amd
    );
    let PropertyResult::Fail(hazards) = &checked.checks.amd.as_ref().unwrap().wait_readiness else {
        panic!("readiness failure")
    };
    assert!(
        hazards
            .iter()
            .any(|h| h.kind == kind && h.register.file == file && h.register.index == index),
        "{hazards:?}"
    );
}

#[test]
fn each_descriptor_word_and_the_vector_address_need_their_own_completion_counter() {
    for word in 0..4 {
        for wait in ["s_wait_kmcnt 0", "", "s_wait_loadcnt 0\ns_wait_xcnt 0"] {
            let body = format!(
                "s_load_b32 s{},s[0:1],{}\n{wait}\n{LOAD}",
                12 + word,
                8 + word * 4
            );
            let checked = run(&body);
            assert_values(&checked, 0);
            if wait == "s_wait_kmcnt 0" {
                assert_eq!(
                    checked.checks.conclusion(),
                    GraphConclusion::Verified,
                    "{:?}",
                    checked.checks.amd
                );
            } else {
                assert_hazard(
                    &checked,
                    AmdRegisterHazardKind::ReadBeforeReady,
                    AmdRegisterFile::Scalar,
                    12 + word as u16,
                );
            }
        }
    }
    for wait in ["s_wait_loadcnt 0", "", "s_wait_kmcnt 0\ns_wait_xcnt 0"] {
        // Seed a concrete address word, then load it asynchronously. Eager
        // address calculation is identical in the correct and faulty traces.
        let body = format!(
            "v_mov_b32 v20,4\nv_add_nc_u32 v20,0,v20\nglobal_store_b32 v0,v20,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0\nglobal_load_b32 v0,v0,s[4:5]\n{wait}\n{LOAD}"
        );
        let checked = run(&body);
        assert_values(&checked, 1);
        if wait == "s_wait_loadcnt 0" {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks.amd
            );
        } else {
            assert_hazard(
                &checked,
                AmdRegisterHazardKind::ReadBeforeReady,
                AmdRegisterFile::Vector,
                0,
            );
        }
    }
}

#[test]
fn load_and_store_leases_retire_with_xcnt_or_full_operation_completion() {
    for (file, index, mutation) in [
        (AmdRegisterFile::Scalar, 12, "s_mov_b32 s12,0"),
        (AmdRegisterFile::Scalar, 13, "s_mov_b32 s13,0"),
        (AmdRegisterFile::Scalar, 14, "s_mov_b32 s14,1"),
        (AmdRegisterFile::Scalar, 15, "s_mov_b32 s15,1"),
        (AmdRegisterFile::Vector, 0, "v_mov_b32 v0,32"),
        (AmdRegisterFile::Scalar, 126, "s_mov_b32 exec_lo,1"),
    ] {
        for wait in ["s_wait_xcnt 0", "s_wait_loadcnt 0", "s_wait_storecnt 0"] {
            let correct = wait != "s_wait_storecnt 0";
            let checked = run(&format!("{LOAD}\n{wait}\n{mutation}"));
            assert_values(&checked, 0);
            if correct {
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
            } else {
                assert_hazard(&checked, AmdRegisterHazardKind::SourceReuse, file, index);
            }
        }
    }
    for (file, index, mutation) in [
        (
            AmdRegisterFile::Scalar,
            16,
            "s_mov_b32 s16,0\ns_mov_b32 s16,0x20000",
        ),
        (
            AmdRegisterFile::Scalar,
            17,
            "s_mov_b32 s17,0\ns_mov_b32 s17,0x20000000",
        ),
        (
            AmdRegisterFile::Scalar,
            18,
            "s_mov_b32 s18,1\ns_mov_b32 s18,0",
        ),
        (
            AmdRegisterFile::Scalar,
            19,
            "s_mov_b32 s19,1\ns_mov_b32 s19,0",
        ),
        (
            AmdRegisterFile::Vector,
            1,
            "v_mov_b32 v1,32\nv_mov_b32 v1,0",
        ),
        (
            AmdRegisterFile::Vector,
            2,
            "v_mov_b32 v2,0\nv_mov_b32 v2,v6",
        ),
        (
            AmdRegisterFile::Vector,
            3,
            "v_mov_b32 v3,0\nv_mov_b32 v3,v7",
        ),
        (AmdRegisterFile::Scalar, 126, "s_mov_b32 exec_lo,1"),
    ] {
        for wait in ["s_wait_xcnt 0", "s_wait_storecnt 0", "s_wait_loadcnt 0"] {
            let correct = wait != "s_wait_loadcnt 0";
            let checked = run(&format!(
                "{LOAD}\ns_wait_loadcnt 0\ns_wait_xcnt 0\nv_mov_b32 v6,v2\nv_mov_b32 v7,v3\n{STORE}\n{wait}\n{mutation}"
            ));
            assert_values(&checked, 0);
            if correct {
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
            } else {
                assert_hazard(&checked, AmdRegisterHazardKind::SourceReuse, file, index);
            }
        }
    }
}

#[test]
fn exact_buffer_roles_and_classes_do_not_invent_lds_or_omit_width_and_counter_charges() {
    let checked = run(LOAD);
    assert_values(&checked, 0);
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let graph = checked.analysis.graph();
    let mut vector_bytes = (0u64, 0u64);
    for record in graph.amd_events() {
        let AmdEventKind::MemoryIssue { class, .. } = record.kind else {
            continue;
        };
        if !matches!(
            class,
            AmdMemoryClass::VectorLoad | AmdMemoryClass::VectorStore
        ) {
            continue;
        }
        let effects: Vec<_> = graph
            .amd_memory_effects()
            .iter()
            .filter(|link| link.issue == record.event)
            .map(|link| {
                let volta_graph::EventKind::Access(id) = graph.event(link.effect).kind else {
                    panic!("access")
                };
                graph.access(id)
            })
            .collect();
        assert_eq!(
            effects.len(),
            if class == AmdMemoryClass::VectorLoad {
                4
            } else {
                2
            }
        );
        for effect in effects {
            assert_eq!(effect.space, volta_graph::Space::Global);
            let volta_graph::Footprint::Bytes { addr, width } = effect.footprint else {
                panic!("bytes")
            };
            assert_eq!(width, 4);
            if class == AmdMemoryClass::VectorLoad {
                assert_eq!(effect.mode, volta_graph::AccessMode::Read);
                assert!((0x10000..0x10010).contains(&addr));
                vector_bytes.0 += u64::from(width);
            } else {
                assert_eq!(effect.mode, volta_graph::AccessMode::Write);
                assert!((0x20000..0x20010).contains(&addr));
                vector_bytes.1 += u64::from(width);
            }
        }
    }
    assert_eq!(vector_bytes, (16, 16));
    let issues: Vec<_> = checked
        .analysis
        .graph()
        .amd_events()
        .iter()
        .filter_map(|r| {
            if let AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations,
                held_sources,
            } = &r.kind
            {
                Some((class, counters, destinations, held_sources))
            } else {
                None
            }
        })
        .collect();
    let (class, counters, destinations, held) = issues
        .iter()
        .find(|(class, _, _, _)| **class == AmdMemoryClass::VectorLoad)
        .unwrap();
    assert_eq!(**class, AmdMemoryClass::VectorLoad);
    assert_eq!(**counters, [(AmdCounter::Load, 1), (AmdCounter::X, 1)]);
    assert_eq!(destinations.len(), 4);
    for index in 12..16 {
        assert!(
            held.iter()
                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
        );
    }
    for (class, counters, destinations, held) in issues
        .iter()
        .filter(|(class, _, _, _)| **class == AmdMemoryClass::VectorStore)
    {
        assert_eq!(**class, AmdMemoryClass::VectorStore);
        assert_eq!(**counters, [(AmdCounter::Store, 1), (AmdCounter::X, 1)]);
        assert!(destinations.is_empty());
        for index in 16..20 {
            assert!(
                held.iter()
                    .any(|r| r.file == AmdRegisterFile::Scalar && r.index == index)
            );
        }
    }
}
