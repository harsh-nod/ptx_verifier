//! Full workload computation and native safety controls. PTX proxy-fence
//! violations remain source-specific; these negatives exercise actual AMD LDS HB.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph::Space;
use volta_graph_check::{GraphConclusion, domain::ConflictKind};

const SCAN: &str =
    include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/native-mamba2-scan.s");
const PORTABLE: &str =
    include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/portable-f16.s");
fn scan_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((128, 1, 1));
    for (name, width, length, base) in [
        ("cb", 4, 4096, 0x1000000),
        ("x", 2, 131072, 0x2000000),
        ("C", 2, 2048, 0x3000000),
        ("prev", 4, 4096, 0x4000000),
        ("dt", 4, 128, 0x5000000),
        ("da", 4, 128, 0x6000000),
    ] {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: width,
            len: length,
            kind: ArrayKind::Input,
        });
    }
    for (prefix, base) in [("out", 0x7000000), ("out_x", 0x8000000)] {
        for row in 0..32 {
            config.arrays.push(ArrayDef {
                name: format!("{prefix}{row:02}"),
                base: base + row * 2048,
                elem_width: 2,
                len: 128,
                kind: ArrayKind::Output,
            });
        }
    }
    config.params = ["cb", "x", "C", "prev", "dt", "da", "out00", "out_x00"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    config
}
fn matvec_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((128, 1, 1));
    for (name, width, length, base, kind) in [
        ("a", 2, 32 * 4096, 0x1000000, ArrayKind::Input),
        ("x", 2, 4096, 0x2000000, ArrayKind::Input),
        ("out", 2, 32, 0x3000000, ArrayKind::Output),
    ] {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: width,
            len: length,
            kind,
        });
    }
    config.params = ["a", "x", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    config
}
fn run(source: &str, kernel: &str, config: AnalysisConfig) -> gfx950_common::Checked {
    let module = frontend::parse(source).unwrap();
    gfx950_common::check(source, &module, Some(kernel), config).unwrap()
}
fn without_first_kernel_barrier(source: &str, kernel: &str) -> String {
    let start = source.find(&format!("{kernel}:")).unwrap();
    let offset = source[start..].find("s_barrier").unwrap() + start;
    let mut text = source.to_string();
    text.replace_range(offset..offset + "s_barrier".len(), "s_nop 0");
    text
}
fn equivalent(actual: &SymbolicOutputs, expected: &SymbolicOutputs) {
    let names = expected
        .outputs
        .iter()
        .map(|(name, _)| name.clone())
        .collect::<Vec<_>>();
    let result = check_output_equivalence(actual, expected, &names).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
}
fn input(arena: &mut ExprArena, name: &str, index: u64) -> ExprId {
    let name = arena.intern_string(name);
    arena.input_element(name, index)
}

#[test]
fn complete_native_scan_computes_all_8192_outputs_with_original_pitches() {
    let checked = run(SCAN, "mamba2_chunk_scan_full", scan_config());
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    let actual = checked.analysis.into_parts().outputs.unwrap();
    assert_eq!(actual.outputs.len(), 64);
    for (name, elements) in &actual.outputs {
        assert_eq!(
            elements.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            (0..128).collect::<Vec<_>>(),
            "{name}"
        );
    }
    assert_eq!(
        actual
            .outputs
            .iter()
            .map(|(_, elements)| elements.len())
            .sum::<usize>(),
        8192
    );
    let mut arena = ExprArena::new();
    let mut outputs = Vec::new();
    for row in 0..32 {
        let da_row = input(&mut arena, "da", row);
        let scale = arena.exp(da_row);
        let mut elements = Vec::new();
        for column in 0..128 {
            let mut state = arena.int(0);
            for j in 0..32 {
                let c = input(&mut arena, "C", row * 64 + j);
                let prev = input(&mut arena, "prev", column * 32 + j);
                let product = arena.mul(c, prev);
                state = arena.add(state, product);
            }
            let state = arena.mul(scale, state);
            let mut scan = arena.int(0);
            for k in 0..128 {
                let cb = input(&mut arena, "cb", row * 128 + k);
                let da_k = input(&mut arena, "da", k);
                let delta = arena.sub(da_row, da_k);
                let zero = arena.int(0);
                let delta = arena.min(delta, zero);
                let decay = arena.exp(delta);
                let dt = input(&mut arena, "dt", k);
                let x = input(&mut arena, "x", k * 1024 + column);
                let weighted = arena.mul(cb, decay);
                let weighted = arena.mul(weighted, dt);
                let term = arena.mul(weighted, x);
                scan = arena.add(scan, term);
            }
            elements.push((column, arena.add(state, scan)));
        }
        outputs.push((format!("out{row:02}"), elements));
        outputs.push((
            format!("out_x{row:02}"),
            (0..128).map(|i| (i, arena.int(0))).collect(),
        ));
    }
    equivalent(&actual, &SymbolicOutputs { arena, outputs });
}

#[test]
fn removing_real_scan_publication_barrier_preserves_computation_but_rejects_lds_race() {
    let text = without_first_kernel_barrier(SCAN, "mamba2_chunk_scan_full");
    let checked = run(&text, "mamba2_chunk_scan_full", scan_config());
    let candidate = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(
        candidate
            .outputs
            .iter()
            .map(|(_, elements)| elements.len())
            .sum::<usize>(),
        8192
    );
    assert!(
        candidate
            .outputs
            .iter()
            .all(|(_, elements)| elements.iter().map(|(i, _)| *i).eq(0..128))
    );
    assert!(
        matches!(
            checked.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:#?}",
        checked.checks
    );
    assert!(
        checked
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(|w| w.location.space == Space::Shared
                && matches!(w.kind, ConflictKind::WriteRead | ConflictKind::ReadWrite)),
        "{:#?}",
        checked.checks
    );
}

#[test]
fn full_matvec_and_actual_publication_mutant_keep_all_32_by_4096_dot_products() {
    let positive = run(PORTABLE, "matvec_f16", matvec_config());
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        positive.checks
    );
    let output = positive.analysis.into_parts().outputs.unwrap();
    assert_eq!(
        output.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        (0..32).collect::<Vec<_>>()
    );
    let text = without_first_kernel_barrier(PORTABLE, "matvec_f16");
    let negative = run(&text, "matvec_f16", matvec_config());
    assert!(
        matches!(
            negative.checks.conclusion(),
            GraphConclusion::Rejected { .. }
        ),
        "{:#?}",
        negative.checks
    );
    assert!(
        negative
            .checks
            .amd
            .as_ref()
            .unwrap()
            .memory_conflict
            .violations()
            .iter()
            .any(|w| w.location.space == Space::Shared
                && matches!(w.kind, ConflictKind::WriteRead | ConflictKind::ReadWrite)),
        "{:#?}",
        negative.checks
    );
    equivalent(&output, &negative.analysis.into_parts().outputs.unwrap());
}
