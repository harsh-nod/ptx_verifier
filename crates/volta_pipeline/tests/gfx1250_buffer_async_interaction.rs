//! Public CDNA5 §5.7/§10.8: separate ordered raw-load and async-load streams.
//! These are complete instruction-interaction controls, not application proofs.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, frontend};
use volta_expr::ExprNode;
use volta_graph::{AmdCounter, AmdEventKind, AmdMemoryClass, AmdRegisterFile, Space};
use volta_graph_check::{GraphConclusion, PropertyResult, amdgpu::AmdRegisterHazardKind};

fn check(load_threshold: u32, async_threshold: u32, reverse: bool) -> gfx950_common::Checked {
    check_with_reuse_wait(load_threshold, async_threshold, reverse, true)
}

fn check_with_reuse_wait(
    load_threshold: u32,
    async_threshold: u32,
    reverse: bool,
    release: bool,
) -> gfx950_common::Checked {
    let first = "buffer_load_b128 v[4:7],v1,s[8:11],null offen\nglobal_load_async_to_lds_b128 v1,v[2:3],off";
    let second = "buffer_load_b128 v[12:15],v1,s[8:11],null offen offset:512\nglobal_load_async_to_lds_b128 v1,v[2:3],off offset:512";
    // Reverse class issuance while keeping each class's two operations in order.
    let issue = [first, second]
        .map(|pair| {
            let lines = pair.lines().collect::<Vec<_>>();
            if reverse {
                format!("{}\n{}", lines[1], lines[0])
            } else {
                pair.into()
            }
        })
        .join("\n");
    let reuse_wait = if release { "s_wait_xcnt 0" } else { "" };
    let source = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_mov_b32 s8,0x10000
s_mov_b32 s9,0
s_mov_b32 s10,8
s_mov_b32 s11,0
s_mov_b64 s[16:17],0x20000
v_lshlrev_b32 v1,4,v0
v_add_nc_u32 v2,0x10000,v1
v_mov_b32 v3,0
v_add_nc_u32 v20,512,v1
{issue}
s_wait_loadcnt {load_threshold}
s_wait_asynccnt {async_threshold}
s_wait_xcnt 0
global_store_b128 v1,v[4:7],s[16:17]
ds_load_b128 v[24:27],v1
s_wait_dscnt 0
global_store_b128 v1,v[24:27],s[16:17] offset:512
s_wait_loadcnt 0
s_wait_asynccnt 0
{reuse_wait}
global_store_b128 v1,v[12:15],s[16:17] offset:1024
ds_load_b128 v[24:27],v20
s_wait_dscnt 0
global_store_b128 v1,v[24:27],s[16:17] offset:1536
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_group_segment_fixed_size 1024
.end_amdhsa_kernel
"#
    );
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((32, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 256,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 512,
            kind: ArrayKind::Output,
        },
    ];
    gfx950_common::check(&source, &module, Some("k"), config).unwrap()
}

#[test]
fn completed_load_and_async_streams_do_not_release_an_earlier_store_source() {
    for reverse in [false, true] {
        let checked = check_with_reuse_wait(1, 1, reverse, false);
        all_outputs(&checked);
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ));
        let PropertyResult::Fail(hazards) = &checked.checks.amd.as_ref().unwrap().wait_readiness
        else {
            panic!("store source lease")
        };
        for word in 24..28 {
            assert!(
                hazards
                    .iter()
                    .any(|h| h.kind == AmdRegisterHazardKind::SourceReuse
                        && h.register.file == AmdRegisterFile::Vector
                        && h.register.index == word),
                "word {word}: {hazards:?}"
            );
        }
    }
}

fn all_outputs(checked: &gfx950_common::Checked) {
    checked.analysis.graph().validate().unwrap();
    let outputs = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 512);
    // Full first raw/async blocks duplicate x[0:128]; second blocks duplicate x[128:256].
    for index in 0..512 {
        let expected = (index / 256) * 128 + index % 128;
        let ExprNode::InputElement {
            array,
            index: actual,
        } = outputs.arena.node(outputs.element("out", index).unwrap())
        else {
            panic!("word {index}")
        };
        assert_eq!(outputs.arena.string(*array), "x");
        assert_eq!(*actual, expected, "output {index}");
    }
}

#[test]
fn mixed_partial_load_and_async_waits_preserve_every_word_in_both_issue_orders() {
    for reverse in [false, true] {
        for (load, asynchronous) in [(1, 1), (0, 1), (1, 0), (0, 0)] {
            let checked = check(load, asynchronous, reverse);
            all_outputs(&checked);
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:?}",
                checked.checks
            );
            let issues = checked
                .analysis
                .graph()
                .amd_events()
                .iter()
                .filter_map(|record| match &record.kind {
                    AmdEventKind::MemoryIssue {
                        class,
                        counters,
                        held_sources,
                        ..
                    } if matches!(
                        class,
                        AmdMemoryClass::VectorLoad | AmdMemoryClass::AsyncLoadToLds
                    ) =>
                    {
                        Some((class, counters, held_sources))
                    }
                    _ => None,
                })
                .collect::<Vec<_>>();
            assert_eq!(issues.len(), 4);
            for (class, counters, held) in issues {
                if *class == AmdMemoryClass::VectorLoad {
                    assert_eq!(counters, &[(AmdCounter::Load, 1), (AmdCounter::X, 1)]);
                    assert!(!held.is_empty());
                } else {
                    assert_eq!(counters, &[(AmdCounter::Async, 1)]);
                    assert!(held.is_empty());
                }
            }
        }
    }
}

#[test]
fn other_stream_completion_and_x_lease_release_cannot_publish_missing_data() {
    for reverse in [false, true] {
        for threshold in [2, 63] {
            let pending_raw = check(threshold, 0, reverse);
            all_outputs(&pending_raw);
            assert!(matches!(
                pending_raw.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
            let PropertyResult::Fail(hazards) =
                &pending_raw.checks.amd.as_ref().unwrap().wait_readiness
            else {
                panic!("raw load readiness")
            };
            for word in 4..8 {
                assert!(
                    hazards
                        .iter()
                        .any(|h| h.kind == AmdRegisterHazardKind::ReadBeforeReady
                            && h.register.file == AmdRegisterFile::Vector
                            && h.register.index == word),
                    "word {word}: {hazards:?}"
                );
            }
            let pending_async = check(0, threshold, reverse);
            all_outputs(&pending_async);
            assert!(matches!(
                pending_async.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
            assert!(
                pending_async
                    .checks
                    .amd
                    .as_ref()
                    .unwrap()
                    .memory_conflict
                    .violations()
                    .iter()
                    .any(|w| w.location.space == Space::Shared)
            );
        }
    }
}
