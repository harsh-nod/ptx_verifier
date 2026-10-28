//! Genuine gfx1250 compiler corpus; CPU validation only, no hardware claim.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, ExprNode, RealRepr, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

const COPY: &str = include_str!("../../../tests/gfx1250/fixtures/native-copy-add.s");
const LDS: &str = include_str!("../../../tests/gfx1250/fixtures/native-lds-ids.s");
const MATRIX: &str = include_str!("../../../tests/gfx1250/fixtures/native-wmma.s");
const BASIS: &str = include_str!("../../../tests/gfx1250/fixtures/native-wmma-basis.s");
const VALUES: &str = include_str!("../../../tests/gfx1250/fixtures/native-wmma-values.s");
const TENSOR: &str = include_str!("../../../tests/gfx1250/fixtures/native-tensor-roundtrip.s");
const ATTENTION: &str = include_str!("../../../tests/gfx1250/fixtures/native-attention-small.s");
const WIDE: &str = include_str!("../../../tests/gfx1250/fixtures/native-transpose-high64.s");
const PIPELINE: &str = include_str!("../../../tests/gfx1250/fixtures/native-gemm-pipeline.s");

fn array(name: &str, base: u64, width: u64, length: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len: length,
        kind,
    }
}
fn copy_config(block: u32, n: u64, add: bool) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = vec![array("x", 0x10000, 4, n, ArrayKind::Input)];
    config.params = vec![ParamValue::ArrayPtr("x".into())];
    if add {
        config
            .arrays
            .push(array("y", 0x20000, 4, n, ArrayKind::Input));
        config.params.push(ParamValue::ArrayPtr("y".into()));
    }
    config
        .arrays
        .push(array("out", 0x30000, 4, n, ArrayKind::Output));
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config.params.push(ParamValue::Int(n as i64));
    config
}
fn check(source: &str, kernel: &str, config: AnalysisConfig) -> native_common::Checked {
    let module = frontend::parse(source).expect("actual compiler assembly parses");
    let checked = native_common::check(source, &module, Some(kernel), config).unwrap();
    assert_eq!(checked.analysis.graph.provenance().targets, ["gfx1250"]);
    checked
}
fn verified(source: &str, kernel: &str, config: AnalysisConfig) -> SymbolicOutputs {
    let checked = check(source, kernel, config);
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn input(arena: &mut ExprArena, name: &str, i: u64) -> ExprId {
    let name = arena.intern_string(name);
    arena.input_element(name, i)
}
fn equivalent(actual: &SymbolicOutputs, expected: SymbolicOutputs) {
    assert_eq!(actual.outputs.len(), expected.outputs.len());
    for (name, elements) in &expected.outputs {
        let actual = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
        assert_eq!(
            actual.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            elements.iter().map(|(i, _)| *i).collect::<Vec<_>>()
        );
    }
    let names = expected
        .outputs
        .iter()
        .map(|(name, _)| name.clone())
        .collect::<Vec<_>>();
    let outcome = check_output_equivalence(actual, &expected, &names).unwrap();
    assert!(matches!(outcome, EquivOutcome::Equivalent), "{outcome:?}");
}
fn expected(arena: ExprArena, elements: Vec<(u64, ExprId)>) -> SymbolicOutputs {
    SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), elements)],
    }
}
fn exact_u64(arena: &ExprArena, value: ExprId) -> Option<u64> {
    // ExprArena::as_u64 deliberately permits rounded real coercion. Output
    // bit-pattern oracles require an exact integer, including values >2^53.
    match arena.node(value) {
        ExprNode::IntConst(value) => Some(*value as u64),
        ExprNode::RealConst(value) => match value.repr() {
            RealRepr::Rational(value) if value.is_integer() => value.numer().to_u64(),
            _ => None,
        },
        _ => None,
    }
}

#[test]
fn real_gfx1250_copy_and_add_preserve_every_tail_and_wave_boundary_element() {
    for block in [1_u32, 31, 32, 33, 63, 64, 65, 128] {
        let mut tails = vec![1, block.saturating_sub(1).max(1), block];
        tails.sort();
        tails.dedup();
        for n in tails {
            for add in [false, true] {
                let actual = verified(
                    COPY,
                    if add { "add" } else { "copy" },
                    copy_config(block, n as u64, add),
                );
                let mut arena = ExprArena::new();
                let values = (0..n as u64)
                    .map(|i| {
                        let x = input(&mut arena, "x", i);
                        let value = if add {
                            let y = input(&mut arena, "y", i);
                            arena.add(x, y)
                        } else {
                            x
                        };
                        (i, value)
                    })
                    .collect();
                equivalent(&actual, expected(arena, values));
            }
        }
    }
}

fn lds_config(outputs: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("x", 0x10000, 4, 64, ArrayKind::Input),
        array("out", 0x20000, 4, outputs, ArrayKind::Output),
    ];
    config.params = ["x", "out"].map(|n| ParamValue::ArrayPtr(n.into())).into();
    config
}
#[test]
fn real_gfx1250_crosswave_lds_exchange_and_complete_wave32_reduction() {
    let actual = verified(LDS, "exchange", lds_config(64));
    let mut arena = ExprArena::new();
    let elements = (0..64)
        .map(|i| (i, input(&mut arena, "x", i ^ 32)))
        .collect();
    equivalent(&actual, expected(arena, elements));
    let actual = verified(LDS, "reduce", lds_config(2));
    let mut arena = ExprArena::new();
    let elements = (0..2)
        .map(|wave| {
            let mut sum = arena.int(0);
            for lane in 0..32 {
                let x = input(&mut arena, "x", wave * 32 + lane);
                sum = arena.add(sum, x);
            }
            (wave, sum)
        })
        .collect();
    equivalent(&actual, expected(arena, elements));
}

#[test]
fn real_gfx1250_three_dimensional_ids_match_all_24_coordinates() {
    let mut config = AnalysisConfig::new((4, 3, 2));
    config.arrays = vec![array("out", 0x10000, 4, 24, ArrayKind::Output)];
    config.params = vec![ParamValue::ArrayPtr("out".into())];
    let actual = verified(LDS, "ids_3d", config);
    let mut arena = ExprArena::new();
    let mut elements = Vec::new();
    for z in 0..2 {
        for y in 0..3 {
            for x in 0..4 {
                elements.push((
                    x + 4 * (y + 3 * z),
                    arena.int((x + 10 * y + 100 * z) as i64),
                ));
            }
        }
    }
    equivalent(&actual, expected(arena, elements));
}

fn pointers(block: u32, arrays: Vec<ArrayDef>) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.params = arrays
        .iter()
        .map(|a| ParamValue::ArrayPtr(a.name.clone()))
        .collect();
    config.arrays = arrays;
    config
}
fn matrix_config(width: u64, depth: u64) -> AnalysisConfig {
    pointers(
        32,
        vec![
            array("a", 0x10000, width, 16 * depth, ArrayKind::Input),
            array("b", 0x20000, width, 16 * depth, ArrayKind::Input),
            array("out", 0x30000, 4, 256, ArrayKind::Output),
        ],
    )
}
// Independent inverse lane map from public FlyDSL f37f7a2 MmaAtom.cpp.
// This is an ABI-edge calculation, never imported from executor matrix code.
fn source_index(row: u64, k: u64, depth: u64) -> u64 {
    if depth == 4 {
        (row + 16 * (k / 2)) * 2 + k % 2
    } else {
        (row + 16 * ((k / 8) % 2)) * 16 + k % 8 + 8 * (k / 16)
    }
}
#[test]
fn real_gfx1250_f32_f16_bf16_wmma_match_every_independent_dot_product() {
    for (kernel, width, depth) in [
        ("wmma_f32", 4, 4),
        ("wmma_f16", 2, 32),
        ("wmma_bf16", 2, 32),
    ] {
        let actual = verified(MATRIX, kernel, matrix_config(width, depth));
        let mut arena = ExprArena::new();
        let mut elements = Vec::new();
        for row in 0..16 {
            for col in 0..16 {
                let mut sum = arena.int(0);
                for k in 0..depth {
                    let a = input(&mut arena, "a", source_index(row, k, depth));
                    let b = input(&mut arena, "b", source_index(col, k, depth));
                    let product = arena.mul(a, b);
                    sum = arena.add(sum, product);
                }
                elements.push(((col + 16 * (row / 8)) * 8 + row % 8, sum));
            }
        }
        elements.sort_by_key(|(i, _)| *i);
        equivalent(&actual, expected(arena, elements));
    }
}
fn pipeline_config() -> AnalysisConfig {
    pointers(
        64,
        vec![
            array("a", 0x10000, 2, 32 * 64, ArrayKind::Input),
            array("b", 0x20000, 2, 16 * 64, ArrayKind::Input),
            array("out", 0x30000, 4, 512, ArrayKind::Output),
        ],
    )
}
#[test]
fn real_gfx1250_two_wave_two_stage_gemm_preserves_all_512_outputs_and_k64() {
    let actual = verified(PIPELINE, "gemm_pipeline_f16", pipeline_config());
    let mut arena = ExprArena::new();
    let mut elements = Vec::new();
    for row in 0..32 {
        for col in 0..16 {
            let mut sum = arena.int(0);
            for k in 0..64 {
                let a = input(&mut arena, "a", row * 64 + k);
                let b = input(&mut arena, "b", col * 64 + k);
                let product = arena.mul(a, b);
                sum = arena.add(sum, product);
            }
            elements.push((row * 16 + col, sum));
        }
    }
    equivalent(&actual, expected(arena, elements));
}
fn tensor_config() -> AnalysisConfig {
    pointers(
        64,
        vec![
            array("x", 0x10000, 4, 128, ArrayKind::Input),
            array("out", 0x20000, 4, 128, ArrayKind::Output),
        ],
    )
}
#[test]
fn real_gfx1250_both_tensor_directions_and_buffer_reuse_preserve_all_128_outputs() {
    let actual = verified(TENSOR, "tensor_roundtrip", tensor_config());
    let mut arena = ExprArena::new();
    let elements = (0..128)
        .map(|i| {
            let x = input(&mut arena, "x", i);
            let one = arena.int(1);
            (i, arena.add(x, one))
        })
        .collect();
    equivalent(&actual, expected(arena, elements));
}
fn attention_config() -> AnalysisConfig {
    pointers(
        32,
        vec![
            array("q", 0x10000, 4, 16 * 32, ArrayKind::Input),
            array("k", 0x20000, 4, 32 * 32, ArrayKind::Input),
            array("v", 0x30000, 4, 32 * 32, ArrayKind::Input),
            array("out", 0x40000, 4, 16 * 32, ArrayKind::Output),
        ],
    )
}
#[test]
fn real_gfx1250_attention_retains_all_keys_normalization_and_512_outputs() {
    let actual = verified(ATTENTION, "attention_small", attention_config());
    let mut arena = ExprArena::new();
    let mut elements = Vec::new();
    for row in 0..16 {
        let mut weights = Vec::new();
        let mut denominator = arena.int(0);
        for key in 0..32 {
            let mut dot = arena.int(0);
            for d in 0..32 {
                let q = input(&mut arena, "q", row * 32 + d);
                let k = input(&mut arena, "k", key * 32 + d);
                let product = arena.mul(q, k);
                dot = arena.add(dot, product);
            }
            let eight = arena.int(8);
            let scaled = arena.div(dot, eight);
            let weight = arena.exp(scaled);
            denominator = arena.add(denominator, weight);
            weights.push(weight);
        }
        for d in 0..32 {
            let mut sum = arena.int(0);
            for key in 0..32 {
                let probability = arena.div(weights[key as usize], denominator);
                let v = input(&mut arena, "v", key * 32 + d);
                let weighted = arena.mul(probability, v);
                sum = arena.add(sum, weighted);
            }
            elements.push((row * 32 + d, sum));
        }
    }
    equivalent(&actual, expected(arena, elements));
}
#[test]
fn real_gfx1250_packed16_transpose_preserves_all_64_elements() {
    let config = pointers(
        32,
        vec![
            array("x", 0x10000, 2, 64, ArrayKind::Input),
            array("out", 0x20000, 2, 64, ArrayKind::Output),
        ],
    );
    let actual = verified(WIDE, "transpose_8x8_b16", config);
    let mut arena = ExprArena::new();
    let elements = (0..64)
        .map(|i| (i, input(&mut arena, "x", (i % 8) * 8 + i / 8)))
        .collect();
    equivalent(&actual, expected(arena, elements));
}
#[test]
fn real_gfx1250_wide_product_and_mad_match_exact_unsigned_and_signed_128bit_oracles() {
    let module = frontend::parse(WIDE).expect("actual compiler module parses once");
    let boundaries = [
        0,
        1,
        (1u64 << 32) - 1,
        1u64 << 32,
        (1u64 << 32) + 1,
        1u64 << 63,
        u64::MAX,
    ];
    for signed in [false, true] {
        for a in boundaries {
            for b in boundaries {
                for c in boundaries {
                    let mut config = AnalysisConfig::new((1, 1, 1));
                    config.arrays = vec![array("out", 0x10000, 8, 4, ArrayKind::Output)];
                    config.params = [a, b, c]
                        .map(|x| ParamValue::Bytes(x.to_le_bytes().to_vec()))
                        .into();
                    config.params.push(ParamValue::ArrayPtr("out".into()));
                    let (product, added) = if signed {
                        let p = (a as i64 as i128) * (b as i64 as i128);
                        (p as u128, p.wrapping_add(c as i64 as i128) as u128)
                    } else {
                        let p = (a as u128) * (b as u128);
                        (p, p.wrapping_add(c as u128))
                    };
                    let kernel = if signed {
                        "high64_signed_mul_mad"
                    } else {
                        "high64_mul_mad"
                    };
                    let checked =
                        native_common::check(WIDE, &module, Some(kernel), config).unwrap();
                    assert_eq!(
                        checked.checks.conclusion(),
                        GraphConclusion::Verified,
                        "{:#?}",
                        checked.checks
                    );
                    let actual = checked.analysis.into_parts().outputs.unwrap();
                    let expected = [
                        (product >> 64) as u64,
                        product as u64,
                        (added >> 64) as u64,
                        added as u64,
                    ];
                    assert_eq!(actual.outputs[0].1.len(), 4);
                    for (i, wanted) in expected.into_iter().enumerate() {
                        assert_eq!(
                            exact_u64(&actual.arena, actual.element("out", i as u64).unwrap()),
                            Some(wanted),
                            "signed={signed} a={a:#x} b={b:#x} c={c:#x} i={i}"
                        );
                    }
                }
            }
        }
    }
}

#[test]
fn real_gfx1250_wmma_finite_byvalue_bits_distinguish_f16_and_bf16() {
    let module = frontend::parse(VALUES).expect("actual compiler module parses once");
    let f32_bytes = |values: [f32; 2]| {
        values
            .into_iter()
            .flat_map(f32::to_le_bytes)
            .collect::<Vec<_>>()
    };
    for (kernel, a, b, wanted) in [
        (
            "wmma_f32_values",
            f32_bytes([0.5, -1.0]),
            f32_bytes([2.0, 4.0]),
            -6.0,
        ),
        (
            "wmma_f16_values",
            0x3c00u16.to_le_bytes().repeat(16),
            0x4000u16.to_le_bytes().repeat(16),
            64.0,
        ),
        (
            "wmma_bf16_values",
            0x3f80u16.to_le_bytes().repeat(16),
            0x4000u16.to_le_bytes().repeat(16),
            64.0,
        ),
    ] {
        let mut config = AnalysisConfig::new((32, 1, 1));
        config.arrays = vec![array("out", 0x10000, 4, 256, ArrayKind::Output)];
        config.params = vec![
            ParamValue::Bytes(a),
            ParamValue::Bytes(b),
            ParamValue::ArrayPtr("out".into()),
        ];
        let checked = native_common::check(VALUES, &module, Some(kernel), config).unwrap();
        assert_eq!(
            checked.checks.conclusion(),
            GraphConclusion::Verified,
            "{:#?}",
            checked.checks
        );
        let actual = checked.analysis.into_parts().outputs.unwrap();
        assert_eq!(actual.outputs[0].1.len(), 256);
        for i in 0..256 {
            assert_eq!(
                actual.arena.as_f64(actual.element("out", i).unwrap()),
                Some(wanted),
                "{kernel} output{i}"
            );
        }
    }
}

#[test]
fn real_gfx1250_wmma_all_a_and_b_basis_coordinates_run_through_native_interpreter() {
    let module = frontend::parse(BASIS).expect("actual compiler basis module parses once");
    for (kernel, depth) in [
        ("wmma_f32_basis", 4),
        ("wmma_f16_basis", 32),
        ("wmma_bf16_basis", 32),
    ] {
        for basis_b in 0..2 {
            for selected in 0..16 {
                for k in 0..depth {
                    let mut config = AnalysisConfig::new((32, 1, 1));
                    config.arrays = vec![array("out", 0x10000, 4, 256, ArrayKind::Output)];
                    config.params = vec![
                        ParamValue::ArrayPtr("out".into()),
                        ParamValue::Int(selected),
                        ParamValue::Int(k),
                        ParamValue::Int(basis_b),
                    ];
                    let checked =
                        native_common::check(BASIS, &module, Some(kernel), config).unwrap();
                    assert_eq!(
                        checked.checks.conclusion(),
                        GraphConclusion::Verified,
                        "{kernel} basisB={basis_b} selected={selected} k={k}: {:#?}",
                        checked.checks
                    );
                    let actual = checked.analysis.into_parts().outputs.unwrap();
                    assert_eq!(actual.outputs[0].1.len(), 256);
                    for row in 0..16u64 {
                        for col in 0..16u64 {
                            let raw_index = (col + 16 * (row / 8)) * 8 + row % 8;
                            let coordinate = if basis_b == 0 { row } else { col };
                            let wanted = f64::from(coordinate == selected as u64);
                            assert_eq!(
                                actual
                                    .arena
                                    .as_f64(actual.element("out", raw_index).unwrap()),
                                Some(wanted),
                                "{kernel} basisB={basis_b} selected={selected} k={k} row={row} col={col}"
                            );
                        }
                    }
                }
            }
        }
    }
}

fn mutate(source: &str, kernel: &str, edits: &[(&str, usize, &str)]) -> String {
    let start = source.find(&format!("\n{kernel}:")).unwrap();
    let end = source[start..].find(".Lfunc_end").unwrap() + start;
    let mut selected = Vec::new();
    for &(needle, occurrence, replacement) in edits {
        let offset = source[start..end]
            .match_indices(needle)
            .nth(occurrence)
            .unwrap()
            .0
            + start;
        selected.push((offset, needle.len(), replacement));
    }
    selected.sort_by_key(|x| std::cmp::Reverse(x.0));
    let mut result = source.to_string();
    for (offset, len, replacement) in selected {
        result.replace_range(offset..offset + len, replacement);
    }
    result
}
#[test]
fn real_gfx1250_assemble_valid_safety_mutants_fail_their_actual_native_obligations() {
    // Positive controls run first: unknown opcode/model gaps cannot vacuously
    // satisfy a safety mutation, and every mutation is independently MC-pinned.
    for (source, kernel, config) in [
        (COPY, "copy", copy_config(65, 65, false)),
        (LDS, "exchange", lds_config(64)),
        (MATRIX, "wmma_f32", matrix_config(4, 4)),
        (PIPELINE, "gemm_pipeline_f16", pipeline_config()),
        (TENSOR, "tensor_roundtrip", tensor_config()),
    ] {
        verified(source, kernel, config);
    }
    {
        let mutant = mutate(COPY, "copy", &[("s_wait_kmcnt 0x0", 0, "s_nop 0")]);
        let checked = check(&mutant, "copy", copy_config(65, 65, false));
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "copy_missing_km_wait: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(COPY, "copy", &[("s_wait_loadcnt 0x0", 0, "s_nop 0")]);
        let checked = check(&mutant, "copy", copy_config(65, 65, false));
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "copy_missing_load_wait: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            LDS,
            "exchange",
            &[
                ("s_barrier_signal -1", 0, "s_nop 0"),
                ("s_barrier_wait -1", 0, "s_nop 0"),
            ],
        );
        let checked = check(&mutant, "exchange", lds_config(64));
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "exchange_missing_publication: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            LDS,
            "exchange",
            &[("s_wait_dscnt 0x0", 0, "s_wait_loadcnt 0")],
        );
        let checked = check(&mutant, "exchange", lds_config(64));
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "exchange_wrong_ds_counter: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(MATRIX, "wmma_f32", &[("s_wait_loadcnt 0x0", 0, "s_nop 0")]);
        let checked = check(&mutant, "wmma_f32", matrix_config(4, 4));
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "wmma_missing_operand_load_wait: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            PIPELINE,
            "gemm_pipeline_f16",
            &[
                ("s_barrier_signal -1", 0, "s_nop 0"),
                ("s_barrier_wait -1", 0, "s_nop 0"),
            ],
        );
        let checked = check(&mutant, "gemm_pipeline_f16", pipeline_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "gemm_missing_initial_publication: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            PIPELINE,
            "gemm_pipeline_f16",
            &[
                ("s_barrier_signal -1", 1, "s_nop 0"),
                ("s_barrier_wait -1", 1, "s_nop 0"),
            ],
        );
        let checked = check(&mutant, "gemm_pipeline_f16", pipeline_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "gemm_missing_next_tile_publication: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            PIPELINE,
            "gemm_pipeline_f16",
            &[("s_wait_dscnt 0x0", 2, "s_nop 0")],
        );
        let checked = check(&mutant, "gemm_pipeline_f16", pipeline_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "gemm_missing_matrix_ds_wait: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            TENSOR,
            "tensor_roundtrip",
            &[("s_wait_tensorcnt 0x0", 0, "s_nop 0")],
        );
        let checked = check(&mutant, "tensor_roundtrip", tensor_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "tensor_missing_load_completion: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            TENSOR,
            "tensor_roundtrip",
            &[("s_wait_tensorcnt 0x0", 0, "s_wait_loadcnt 0")],
        );
        let checked = check(&mutant, "tensor_roundtrip", tensor_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "tensor_wrong_load_counter: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        // Without any padding this schedule may diagnose an uninitialized LDS
        // read before the issuing wave finishes descriptor construction. These
        // independent NOPs retain candidate values without adding a memory
        // completion or a cross-wave happens-before edge.
        let scheduling_padding = ["s_nop 0"; 64].join("\n\t");
        let mutant = mutate(
            TENSOR,
            "tensor_roundtrip",
            &[
                ("s_barrier_signal -1", 0, scheduling_padding.as_str()),
                ("s_barrier_wait -1", 0, "s_nop 0"),
            ],
        );
        let checked = check(&mutant, "tensor_roundtrip", tensor_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "tensor_missing_crosswave_publication: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            TENSOR,
            "tensor_roundtrip",
            &[
                ("s_barrier_signal -1", 1, "s_nop 0"),
                ("s_barrier_wait -1", 1, "s_nop 0"),
            ],
        );
        let checked = check(&mutant, "tensor_roundtrip", tensor_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "tensor_missing_store_producers: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            TENSOR,
            "tensor_roundtrip",
            &[("s_wait_tensorcnt 0x0", 1, "s_nop 0")],
        );
        let checked = check(&mutant, "tensor_roundtrip", tensor_config());
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "tensor_missing_store_completion: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
    {
        let mutant = mutate(
            TENSOR,
            "tensor_roundtrip",
            &[("s_mov_b32 s13, 0x400000", 0, "s_mov_b32 s13, 0x410000")],
        );
        let checked = check(&mutant, "tensor_roundtrip", tensor_config());
        assert!(
            checked.analysis.symbolic_outputs().is_err(),
            "oversized tensor tile must report a typed bounds failure"
        );
        assert_ne!(checked.checks.conclusion(), GraphConclusion::Verified);
    }
    {
        let mutant = mutate(
            WIDE,
            "transpose_8x8_b16",
            &[("s_wait_dscnt 0x0", 1, "s_nop 0")],
        );
        let checked = check(
            &mutant,
            "transpose_8x8_b16",
            pointers(
                32,
                vec![
                    array("x", 0x10000, 2, 64, ArrayKind::Input),
                    array("out", 0x20000, 2, 64, ArrayKind::Output),
                ],
            ),
        );
        assert!(
            matches!(
                checked.checks.conclusion(),
                GraphConclusion::Rejected { .. }
            ),
            "transpose_missing_ds_completion: {:#?}",
            checked.checks
        );
        let amd = checked.checks.amd.as_ref().unwrap();
        assert!(
            !amd.wait_readiness.violations().is_empty()
                || !amd.memory_conflict.violations().is_empty()
                || !amd.barrier.violations().is_empty(),
            "must carry a concrete AMD readiness/memory/barrier witness"
        );
    }
}
