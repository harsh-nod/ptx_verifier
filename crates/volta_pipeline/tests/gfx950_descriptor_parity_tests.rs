//! Address/stride metadata is ordinary LDS data in this native implementation.
//! It has explicit completion/publication obligations; no TMA proxy is invented.
mod gfx950_common;

use volta_amdgpu_analysis::{frontend, AnalysisConfig, ArrayDef, ArrayKind, ParamValue};
use volta_expr::ExprNode;
use volta_graph::Space;
use volta_graph_check::{amdgpu::AmdRegisterHazardKind, domain::ConflictKind, GraphConclusion};

const SOURCE: &str = include_str!("../../../tests/gfx950/portable-descriptor/tile-edge.s");

fn run(source: &str) -> gfx950_common::Checked {
    let module = frontend::parse(source).unwrap();
    let mut config = AnalysisConfig::new((192, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 2,
            len: 64,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 2,
            len: 16,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    gfx950_common::check(source, &module, Some("k"), config).unwrap()
}

fn assert_payload(checked: &gfx950_common::Checked) {
    let outputs = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 16);
    for i in 0..16u64 {
        let value = outputs.arena.node(outputs.element("out", i).unwrap());
        let row = i / 4 + 6;
        let column = i % 4 + 6;
        if row < 8 && column < 8 {
            assert!(
                matches!(value, ExprNode::InputElement { array, index }
                if outputs.arena.string(*array) == "x" && *index == row * 8 + column),
                "out[{i}]: {value:?}"
            );
        } else {
            assert!(
                matches!(value, ExprNode::IntConst(0)),
                "out[{i}]: {value:?}"
            );
        }
    }
}

#[test]
fn published_native_descriptor_preserves_pitch_coordinates_and_edge_zero_fill() {
    let checked = run(SOURCE);
    assert_payload(&checked);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
}

#[test]
fn descriptor_publication_requires_completion_and_a_crosswave_rendezvous() {
    for source in [
        SOURCE.replace("s_waitcnt lgkmcnt(0) // producer completion", "s_nop 0"),
        SOURCE.replace("s_barrier // descriptor publication", "s_nop 0"),
        SOURCE.replace(
            "s_waitcnt lgkmcnt(0) // producer completion",
            "v_mov_b32 v25, 0\nglobal_load_dword v25, v25, s[4:5]\ns_waitcnt vmcnt(0)",
        ),
    ] {
        assert_ne!(source, SOURCE);
        let checked = run(&source);
        assert_payload(&checked);
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "{:#?}",
            checked.checks
        );
        let violations = checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations();
        assert!(
            violations.iter().any(|v| v.location.space == Space::Shared
                && v.location.addr < 32
                && v.kind == ConflictKind::WriteRead),
            "{violations:?}"
        );
    }
}

#[test]
fn descriptor_words_cannot_form_addresses_before_their_lds_return() {
    let source = SOURCE.replace("s_waitcnt lgkmcnt(0) // descriptor consumption", "s_nop 0");
    assert_ne!(source, SOURCE);
    let checked = run(&source);
    assert_payload(&checked);
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:#?}",
        checked.checks
    );
    let violations = checked
        .checks
        .amd
        .as_ref()
        .unwrap()
        .wait_readiness
        .violations();
    assert!(
        violations
            .iter()
            .any(|v| v.kind == AmdRegisterHazardKind::ReadBeforeReady),
        "{violations:?}"
    );
}

#[test]
fn copied_tile_requires_its_own_completion_and_publication() {
    for source in [
        SOURCE.replace("s_waitcnt lgkmcnt(0) // tile completion", "s_nop 0"),
        SOURCE.replace("s_barrier // tile publication", "s_nop 0"),
    ] {
        assert_ne!(source, SOURCE);
        let checked = run(&source);
        assert_payload(&checked);
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ));
        let violations = checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations();
        assert!(
            violations.iter().any(|v| v.location.space == Space::Shared
                && (32..64).contains(&v.location.addr)
                && v.kind == ConflictKind::WriteRead),
            "{violations:?}"
        );
    }
    for wait in [
        "s_waitcnt vmcnt(0)",
        "s_waitcnt lgkmcnt(0) // tile consumption",
    ] {
        let source = SOURCE.replace(wait, "s_nop 0");
        let checked = run(&source);
        assert_payload(&checked);
        assert!(matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ));
        let violations = checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .wait_readiness
            .violations();
        assert!(
            violations
                .iter()
                .any(|v| v.kind == AmdRegisterHazardKind::ReadBeforeReady),
            "{violations:?}"
        );
    }
}

const REPLACE_METADATA: &str = "v_cmp_eq_u32 vcc, 0, v0\ns_and_saveexec_b64 s[8:9], vcc\nv_mov_b32 v3, 0\nv_mov_b32 v4, 0\nds_write_b32 v3, v4\ns_waitcnt lgkmcnt(0)\ns_mov_b64 exec, s[8:9]\n";

#[test]
fn descriptor_reuse_is_ordered_after_its_consumers_finish() {
    let joined = SOURCE.replace(
        "// Wave2/lane0..15",
        &format!("{REPLACE_METADATA}// Wave2/lane0..15"),
    );
    assert_ne!(joined, SOURCE);
    let checked = run(&joined);
    assert_payload(&checked);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );

    let unjoined = SOURCE.replace(
        "s_barrier // tile publication",
        &format!("{REPLACE_METADATA}s_barrier // tile publication"),
    );
    let checked = run(&unjoined);
    assert_payload(&checked);
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    let violations = checked
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        violations.iter().any(|v| v.location.space == Space::Shared
            && v.location.addr < 32
            && v.kind == ConflictKind::ReadWrite),
        "{violations:?}"
    );
}

fn run_metadata(source: &str) -> gfx950_common::Checked {
    let module = frontend::parse(source).unwrap();
    let mut config = AnalysisConfig::new((128, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "metadata".into(),
        base: 0x10000,
        elem_width: 4,
        len: 32,
        kind: ArrayKind::InputOutput,
    }];
    config.params = vec![
        ParamValue::ArrayPtr("metadata".into()),
        ParamValue::ArrayPtr("metadata".into()),
    ];
    gfx950_common::check(source, &module, Some("k"), config).unwrap()
}

#[test]
fn copying_descriptor_bytes_races_both_the_source_and_destination_replacements() {
    let source = include_str!("../../../tests/gfx950/portable-descriptor/copy-replace-races.s");
    for ordered in [false, true] {
        let source = if ordered {
            source.replace("s_nop 0 // replace-to-copy join", "s_barrier")
        } else {
            source.into()
        };
        let checked = run_metadata(&source);
        let outputs = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 32);
        for i in 0..32 {
            assert!(
                matches!(outputs.arena.node(outputs.element("metadata", i).unwrap()),
                ExprNode::IntConst(value) if *value == if i == 0 {19} else {42})
            );
        }
        if ordered {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:#?}",
                checked.checks
            );
        } else {
            assert!(matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
            let violations = checked
                .checks
                .amd
                .as_ref()
                .unwrap()
                .memory_conflict
                .violations();
            assert!(
                violations.iter().any(|v| v.location.space == Space::Shared
                    && v.location.addr < 4
                    && v.kind == ConflictKind::WriteRead),
                "{violations:?}"
            );
            assert!(
                violations.iter().any(|v| v.location.space == Space::Global
                    && (0x10000..0x10004).contains(&v.location.addr)
                    && v.kind == ConflictKind::WriteWrite),
                "{violations:?}"
            );
        }
    }
}

#[test]
fn independent_descriptor_field_replacements_conflict_at_the_same_lds_word() {
    let source = include_str!("../../../tests/gfx950/portable-descriptor/replace-write-write.s");
    for ordered in [false, true] {
        let source = if ordered {
            source.replace("s_nop 0 // replace-to-replace join", "s_barrier")
        } else {
            source.into()
        };
        let checked = run_metadata(&source);
        let outputs = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 1);
        assert!(matches!(
            outputs.arena.node(outputs.element("metadata", 0).unwrap()),
            ExprNode::IntConst(23)
        ));
        if ordered {
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:#?}",
                checked.checks
            );
        } else {
            assert!(matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ));
            let violations = checked
                .checks
                .amd
                .as_ref()
                .unwrap()
                .memory_conflict
                .violations();
            assert!(
                violations.iter().any(|v| v.location.space == Space::Shared
                    && v.location.addr < 4
                    && v.kind == ConflictKind::WriteWrite),
                "{violations:?}"
            );
        }
    }
}
