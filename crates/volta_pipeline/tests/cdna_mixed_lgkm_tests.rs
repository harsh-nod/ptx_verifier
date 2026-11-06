//! Mixed CDNA LGKM completion is per ordered LDS stream, never global FIFO.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph_check::amdgpu::AmdRegisterHazardKind;
use volta_graph_check::{GraphConclusion, Property, Verdict};

const GFX942: &str = include_str!("../../../tests/amdgpu/native-mixed-lgkm/gfx942.s");
const GFX950: &str = include_str!("../../../tests/amdgpu/native-mixed-lgkm/gfx950.s");

fn run(source: &str, block: u32) -> gfx950_common::Checked {
    let module = frontend::parse(source).expect("target-specific control parses");
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: u64::from(block),
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: u64::from(block),
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    gfx950_common::check(source, &module, Some("mixed_lgkm_copy"), config).expect("native lowering")
}

fn copy_outputs(checked: &gfx950_common::Checked, block: u32) {
    let actual = checked
        .analysis
        .symbolic_outputs()
        .expect("complete numerical outputs");
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(
        actual.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..u64::from(block)).collect::<Vec<_>>()
    );
    let mut arena = ExprArena::new();
    let x = arena.intern_string("x");
    let elements = (0..u64::from(block))
        .map(|i| (i, arena.input_element(x, i)))
        .collect();
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    };
    let result = check_output_equivalence(actual, &expected, &["out".into()]).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}

#[test]
fn mixed_smem_and_lds_partial_wait_proves_every_copy_output() {
    for source in [GFX942, GFX950] {
        for block in [63, 64, 65, 128] {
            let checked = run(source, block);
            copy_outputs(&checked, block);
            assert_eq!(
                checked.checks.conclusion(),
                GraphConclusion::Verified,
                "{:#?}",
                checked.checks
            );
        }
    }
}

#[test]
fn draining_lgkm_is_an_independent_full_output_control() {
    for source in [GFX942, GFX950] {
        let checked = run(
            &source.replace("s_waitcnt lgkmcnt(1)", "s_waitcnt lgkmcnt(0)"),
            64,
        );
        copy_outputs(&checked, 64);
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            checked.checks
        );
    }
}

#[test]
fn mixed_wait_does_not_identify_newest_lds_or_unordered_scalar_results() {
    for source in [GFX942, GFX950] {
        let cases = [
            (
                source.replace("s_waitcnt lgkmcnt(1)", "s_waitcnt vmcnt(0)"),
                AmdRegisterHazardKind::ReadBeforeReady,
            ),
            (
                source.replace("s_waitcnt lgkmcnt(1)", ""),
                AmdRegisterHazardKind::ReadBeforeReady,
            ),
            (
                source.replace("s_waitcnt lgkmcnt(1)", "s_waitcnt lgkmcnt(15)"),
                AmdRegisterHazardKind::ReadBeforeReady,
            ),
            (
                source.replace("global_store_dword v2, v10", "global_store_dword v2, v11"),
                AmdRegisterHazardKind::ReadBeforeReady,
            ),
            (
                source.replace(
                    "global_store_dword v2, v10",
                    "s_mov_b32 s14, s12\n    global_store_dword v2, v10",
                ),
                AmdRegisterHazardKind::ReadBeforeReady,
            ),
            (
                source.replace(
                    "global_store_dword v2, v10",
                    "s_mov_b32 s12, 0\n    global_store_dword v2, v10",
                ),
                AmdRegisterHazardKind::DestinationReuse,
            ),
            (
                source.replace(
                    "global_store_dword v2, v10",
                    "v_mov_b32 v11, 0\n    global_store_dword v2, v10",
                ),
                AmdRegisterHazardKind::DestinationReuse,
            ),
            (
                source.replace(
                    "ds_read_b32 v11, v2",
                    "s_mov_b64 exec, 0\n    ds_read_b32 v11, v2\n    s_mov_b64 exec, -1",
                ),
                AmdRegisterHazardKind::ReadBeforeReady,
            ),
        ];
        for (source, kind) in cases {
            let checked = run(&source, 64);
            copy_outputs(&checked, 64);
            assert_eq!(
                checked.checks.verdict(Property::AmdTrace),
                Verdict::Pass,
                "{:#?}",
                checked.checks
            );
            assert_eq!(
                checked.checks.verdict(Property::AmdWaitReadiness),
                Verdict::Fail,
                "{:#?}",
                checked.checks
            );
            assert!(
                checked
                    .checks
                    .amd
                    .as_ref()
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|hazard| hazard.kind == kind),
                "{:#?}",
                checked.checks
            );
        }
    }
}
