//! Remaining portable storage lifetime, native counter and zero-matrix boundaries.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use std::collections::BTreeSet;
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue, frontend,
};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{AccessMode, AmdEventKind, AmdMemoryClass, EventKind, Footprint, Space};
use volta_graph_check::{
    GraphConclusion, Property, Verdict, amdgpu::AmdRegisterHazardKind, domain::ConflictKind,
};
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const BORROW: &str = include_str!("../../../tests/gfx1250/fixtures/native-lifetime-boundaries.s");
const COUNTS: &str =
    include_str!("../../../tests/gfx1250/fixtures/native-named-count-boundaries.s");
const MATRIX: &str = include_str!("../../../tests/gfx1250/fixtures/native-matrix-numeric.s");
const ORDERING: &str = include_str!("../../../tests/gfx1250/fixtures/native-matrix-ordering.s");

fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}
fn execute(source: &str, kernel: &str, config: AnalysisConfig) -> native_common::Checked {
    let module = frontend::parse(source).unwrap();
    native_common::check(source, &module, Some(kernel), config).unwrap()
}
fn equivalent(checked: &native_common::Checked, expected: &SymbolicOutputs) {
    let actual = checked
        .analysis
        .symbolic_outputs()
        .expect("complete candidate outputs");
    assert_eq!(actual.outputs.len(), expected.outputs.len());
    let names: Vec<_> = expected
        .outputs
        .iter()
        .map(|(name, values)| {
            let found = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
            assert_eq!(
                found.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
                values.iter().map(|(i, _)| *i).collect::<Vec<_>>()
            );
            name.clone()
        })
        .collect();
    let result = check_output_equivalence(actual, expected, &names).unwrap();
    assert!(matches!(result, EquivOutcome::Equivalent), "{result:?}");
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
}
fn borrow_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("input", 0x10000, 4, 64, ArrayKind::Input),
        array("out", 0x20000, 4, 64, ArrayKind::Output),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("input".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    config
}
fn identity() -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let input = arena.intern_string("input");
    let values = (0..64)
        .map(|i| (i, arena.input_element(input, i)))
        .collect();
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), values)],
    }
}
fn tensor_bytes(checked: &native_common::Checked, space: Space, mode: AccessMode) -> BTreeSet<u64> {
    let graph = &checked.analysis.graph;
    let issues: BTreeSet<_> = graph
        .amd_events()
        .iter()
        .filter_map(|event| match event.kind {
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::TensorStoreFromLds,
                ..
            } => Some(event.event),
            _ => None,
        })
        .collect();
    graph
        .amd_memory_effects()
        .iter()
        .filter(|link| issues.contains(&link.issue))
        .flat_map(|link| {
            let EventKind::Access(id) = graph.event(link.effect).kind else {
                panic!("memory effect")
            };
            let access = graph.access(id);
            let Footprint::Bytes { addr, width } = access.footprint else {
                panic!("byte footprint")
            };
            if access.space == space && access.mode == mode {
                addr..addr + u64::from(width)
            } else {
                0..0
            }
        })
        .collect()
}

#[test]
fn a_full128_byte_source_borrow_finishes_before_cross_wave_reuse() {
    let expected = identity();
    let positive = execute(BORROW, "async_source128_reuse", borrow_config());
    equivalent(&positive, &expected);
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        positive.checks
    );
    assert_eq!(
        tensor_bytes(&positive, Space::Shared, AccessMode::Read),
        (0..128).collect()
    );
    assert_eq!(
        tensor_bytes(&positive, Space::Global, AccessMode::Write),
        (0x20000..0x20080).collect()
    );
    assert_eq!(BORROW.matches("s_wait_tensorcnt 0x0").count(), 1);
    for replacement in ["s_nop 0", "s_wait_storecnt 0\n\ts_wait_dscnt 0"] {
        let source = BORROW.replace("s_wait_tensorcnt 0x0", replacement);
        let candidate = execute(&source, "async_source128_reuse", borrow_config());
        equivalent(&candidate, &expected);
        assert_eq!(
            candidate.checks.verdict(Property::AmdMemoryConflict),
            Verdict::Fail,
            "{:#?}",
            candidate.checks
        );
        assert!(
            candidate
                .checks
                .amd
                .as_ref()
                .unwrap()
                .memory_conflict
                .violations()
                .iter()
                .any(|witness| witness.kind == ConflictKind::ReadWrite
                    && witness.location.space == Space::Shared)
        );
    }
}

#[test]
fn non_null_named_expected_count_preserves_one_and_the_actual16_bit_maximum() {
    for (kernel, expected) in [
        ("named_expected_one", 1),
        ("named_expected_maximum", u16::MAX),
    ] {
        let checked = execute(COUNTS, kernel, AnalysisConfig::new((32, 1, 1)));
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            checked.checks
        );
        assert!(
            checked
                .analysis
                .symbolic_outputs()
                .unwrap()
                .outputs
                .is_empty()
        );
        let fields: Vec<_> = checked
            .analysis
            .graph
            .amd_events()
            .iter()
            .filter_map(|event| match event.kind {
                AmdEventKind::NamedBarrierInit { object, expected } => Some((object.id, expected)),
                _ => None,
            })
            .collect();
        assert_eq!(fields, [(1, expected)]);
    }
}

#[test]
fn zero_expected_count_is_rejected_only_for_a_non_null_object() {
    let invalid = execute(
        COUNTS,
        "named_expected_zero",
        AnalysisConfig::new((32, 1, 1)),
    );
    assert!(
        matches!(invalid.analysis.symbolic_outputs(), Err(OutputsUnavailable::Aborted(EvalError::Invalid {
        what, ..
    })) if what == "named barrier expected count must be positive")
    );
    assert_ne!(invalid.checks.conclusion(), GraphConclusion::Verified);
    let null = execute(COUNTS, "named_null_zero", AnalysisConfig::new((32, 1, 1)));
    assert_eq!(
        null.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        null.checks
    );
    assert!(null.analysis.symbolic_outputs().unwrap().outputs.is_empty());
    assert!(
        null.analysis
            .graph
            .amd_events()
            .iter()
            .any(|event| matches!(event.kind,
        AmdEventKind::NamedBarrierInit { object, expected: 0 } if object.id == 0))
    );
}

#[test]
fn original_transaction_credit_boundary_positive_is_retained_separately() {
    let source = include_str!("ptx/soundness/mbarrier_tx_count_out_of_range.ptx");
    let control = source.replace("1048575;", "1048574;");
    let parse = |source: &str| {
        Parser::new(source.as_bytes().as_ascii_slice().unwrap())
            .parse_module()
            .unwrap()
    };
    let module = parse(&control);
    let accepted =
        volta_pipeline::verify_kernel(&module, Some("k"), AnalysisConfig::new((1, 1, 1))).unwrap();
    assert_eq!(accepted.graph.conclusion(), GraphConclusion::Verified);
    assert!(
        accepted
            .analysis
            .symbolic_outputs()
            .unwrap()
            .outputs
            .is_empty()
    );
    let module = parse(source);
    let rejected =
        volta_pipeline::verify_kernel(&module, Some("k"), AnalysisConfig::new((1, 1, 1))).unwrap();
    assert!(matches!(
        rejected.analysis.symbolic_outputs(),
        Err(volta_ptx_analysis::OutputsUnavailable::Aborted(
            volta_ptx_analysis::EvalError::MbarrierTxCountOutOfRange {
                tx_count: 1048576,
                ..
            }
        ))
    ));
    // Native barrier expected counts use their own16-bit encoded field, while
    // TDM completion is tied to the actual128-byte source borrow above. Neither
    // is relabeled as NVIDIA's manual20-bit transaction-byte-credit mechanism.
    let native = execute(
        COUNTS,
        "named_expected_maximum",
        AnalysisConfig::new((32, 1, 1)),
    );
    assert_eq!(native.checks.conclusion(), GraphConclusion::Verified);
}

fn zero_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((256, 1, 1));
    config.arrays = vec![
        array("out", 0x10000, 4, 32768, ArrayKind::Output),
        array("native", 0x40000, 4, 32768, ArrayKind::Output),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::ArrayPtr("native".into()),
    ];
    config
}
fn all_zero() -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let zero = arena.int(0);
    SymbolicOutputs {
        arena,
        outputs: ["out", "native"]
            .map(|name| (name.into(), (0..32768).map(|i| (i, zero)).collect()))
            .to_vec(),
    }
}

#[test]
fn completed_zero_mma_keeps_every_result_and_rejects_early_destination_reuse() {
    let positive = execute(MATRIX, "matrix_zero_128x256", zero_config());
    equivalent(&positive, &all_zero());
    assert_eq!(positive.checks.conclusion(), GraphConclusion::Verified);
    let begin = MATRIX.find("\nmatrix_zero_128x256:").unwrap();
    let end = begin + MATRIX[begin..].find(".Lfunc_end").unwrap();
    let region = &MATRIX[begin..end];
    let wmma = region
        .lines()
        .find(|line| line.trim_start().starts_with("v_wmma_f32_"))
        .unwrap();
    let register: u32 = wmma
        .split_whitespace()
        .nth(1)
        .unwrap()
        .trim_start_matches("v[")
        .split(':')
        .next()
        .unwrap()
        .parse()
        .unwrap();
    let mutation = format!("{wmma}\n\tv_add_f32_e64 v{register}, 1.0, 0");
    let source = format!(
        "{}{}{}",
        &MATRIX[..begin],
        region.replacen(wmma, &mutation, 1),
        &MATRIX[end..]
    );
    let candidate = execute(&source, "matrix_zero_128x256", zero_config());
    let outputs = candidate
        .analysis
        .symbolic_outputs()
        .expect("complete destination-reuse candidate");
    assert_eq!(
        outputs
            .outputs
            .iter()
            .map(|(_, xs)| xs.len())
            .collect::<Vec<_>>(),
        [32768, 32768]
    );
    assert_eq!(candidate.checks.verdict(Property::AmdTrace), Verdict::Pass);
    assert_eq!(
        candidate.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Fail
    );
    assert!(
        candidate
            .checks
            .amd
            .as_ref()
            .unwrap()
            .wait_readiness
            .violations()
            .iter()
            .any(|witness| witness.kind == AmdRegisterHazardKind::MatrixDestinationReuse)
    );
}

#[test]
fn original_zero_boundary_math_has_explicit_complete_native_projections_and_superset() {
    for (source, m, n) in [
        (
            include_str!("ptx/success/tcgen05_mma_encoding_shape_ws_m32_n64.ptx"),
            32,
            64,
        ),
        (
            include_str!("ptx/success/tcgen05_mma_encoding_idesc_max_shift_ws.ptx"),
            128,
            64,
        ),
        (
            include_str!("ptx/success/tcgen05_mma_encoding_d_lane0_col8.ptx"),
            128,
            256,
        ),
        (
            include_str!("ptx/success/tcgen05_dealloc_after_the_mma_completed_is_accepted.ptx"),
            128,
            8,
        ),
    ] {
        let module = Parser::new(source.as_bytes().as_ascii_slice().unwrap())
            .parse_module()
            .unwrap();
        let original =
            volta_pipeline::verify_kernel(&module, Some("k"), AnalysisConfig::new((32, 1, 1)))
                .unwrap();
        assert_eq!(original.graph.conclusion(), GraphConclusion::Verified);
        assert!(
            original
                .analysis
                .symbolic_outputs()
                .unwrap()
                .outputs
                .is_empty()
        );
        let projected: BTreeSet<_> = (0..m)
            .flat_map(|row| (0..n).map(move |column| row * 256 + column))
            .collect();
        assert_eq!(projected.len(), m * n);
        assert!(projected.iter().all(|index| *index < 32768));
    }
    let native = execute(MATRIX, "matrix_zero_128x256", zero_config());
    equivalent(&native, &all_zero());
    assert_eq!(native.checks.conclusion(), GraphConclusion::Verified);
}

fn ordering_config(metadata: bool) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("input", 0x10000, 2, 256, ArrayKind::Input),
        array("out", 0x20000, 4, 256, ArrayKind::Output),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("input".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    if metadata {
        config.arrays.extend([
            array("metadata_in", 0x30000, 4, 1, ArrayKind::Input),
            array("metadata_out", 0x40000, 4, 1, ArrayKind::Output),
        ]);
        config.params.extend([
            ParamValue::ArrayPtr("metadata_in".into()),
            ParamValue::ArrayPtr("metadata_out".into()),
        ]);
    }
    config
}
fn ordering_math(metadata: bool) -> SymbolicOutputs {
    let mut arena = ExprArena::new();
    let input = arena.intern_string("input");
    let mut values = Vec::new();
    for row in 0..16 {
        let mut sum = arena.int(0);
        for k in 0..16 {
            let x = arena.input_element(input, row * 16 + k);
            let weight = arena.int(k as i64 + 1);
            let product = arena.mul(x, weight);
            sum = arena.add(sum, product);
        }
        for column in 0..16 {
            values.push((row * 16 + column, sum));
        }
    }
    let mut outputs = vec![("out".into(), values)];
    if metadata {
        let metadata = arena.intern_string("metadata_in");
        outputs.push((
            "metadata_out".into(),
            vec![(0, arena.input_element(metadata, 0))],
        ));
    }
    SymbolicOutputs { arena, outputs }
}
fn mutate_ordering(kernel: &str, completion: bool) -> String {
    let begin = ORDERING.find(&format!("\n{kernel}:")).unwrap();
    let end = begin + ORDERING[begin..].find(".Lfunc_end").unwrap();
    let mut region = ORDERING[begin..end].to_owned();
    if completion {
        let needle = "s_wait_dscnt 0x0\n\ts_barrier_signal -1";
        let at = region.rfind(needle).unwrap();
        region.replace_range(
            at..at + needle.len(),
            "s_wait_loadcnt 0x0\n\ts_barrier_signal -1",
        );
    } else {
        for barrier in ["s_barrier_signal -1", "s_barrier_wait -1"] {
            let at = region.rfind(barrier).unwrap();
            region.replace_range(at..at + barrier.len(), "s_nop 0");
        }
    }
    format!("{}{}{}", &ORDERING[..begin], region, &ORDERING[end..])
}
fn complete_ordering_candidate(checked: &native_common::Checked, metadata: bool) {
    let actual = checked
        .analysis
        .symbolic_outputs()
        .expect("complete ordering candidate");
    assert_eq!(actual.outputs.len(), if metadata { 2 } else { 1 });
    for (name, values) in &actual.outputs {
        let count = if name == "out" {
            256
        } else {
            assert!(metadata && name == "metadata_out");
            1
        };
        assert_eq!(
            values.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            (0..count).collect::<Vec<_>>()
        );
    }
    assert_eq!(checked.checks.verdict(Property::AmdTrace), Verdict::Pass);
}

#[test]
fn cross_wave_lds_production_is_published_before_all_wmma_operand_reads() {
    let kernel = "matrix_input_cross_wave";
    let positive = execute(ORDERING, kernel, ordering_config(false));
    equivalent(&positive, &ordering_math(false));
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        positive.checks
    );
    for completion in [false, true] {
        let candidate = execute(
            &mutate_ordering(kernel, completion),
            kernel,
            ordering_config(false),
        );
        complete_ordering_candidate(&candidate, false);
        assert_eq!(
            candidate.checks.verdict(Property::AmdMemoryConflict),
            Verdict::Fail,
            "{:#?}",
            candidate.checks
        );
        assert!(
            candidate
                .checks
                .amd
                .as_ref()
                .unwrap()
                .memory_conflict
                .violations()
                .iter()
                .any(|witness| witness.kind == ConflictKind::WriteRead
                    && witness.location.space == Space::Shared)
        );
    }
}

#[test]
fn matrix_completion_cannot_publish_an_unrelated_earlier_metadata_store() {
    let kernel = "matrix_completion_keeps_metadata_separate";
    let positive = execute(ORDERING, kernel, ordering_config(true));
    equivalent(&positive, &ordering_math(true));
    assert_eq!(
        positive.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        positive.checks
    );
    let candidate = execute(
        &mutate_ordering(kernel, false),
        kernel,
        ordering_config(true),
    );
    complete_ordering_candidate(&candidate, true);
    assert_eq!(
        candidate.checks.verdict(Property::AmdWaitReadiness),
        Verdict::Pass
    );
    assert_eq!(
        candidate.checks.verdict(Property::AmdMemoryConflict),
        Verdict::Fail,
        "{:#?}",
        candidate.checks
    );
    let violations = candidate
        .checks
        .amd
        .as_ref()
        .unwrap()
        .memory_conflict
        .violations();
    assert!(
        violations
            .iter()
            .any(|witness| witness.kind == ConflictKind::WriteRead
                && witness.location.space == Space::Shared
                && witness.location.addr < 4)
    );
}
