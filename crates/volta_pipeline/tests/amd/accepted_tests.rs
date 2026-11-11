//! AMD kernels expected to complete and verify: each fixture kernel's symbolic outputs, compared
//! with `amd/success/<name>.out`, and the launch and grid behavior around them. Every test reads
//! a run's outputs only once the graph check concludes `Verified`.

use crate::common;

use common::amd::{
    AmdChecked, CK_GEMM_KERNEL, CK_GEMM_SIGMOID_KERNEL, amd_fixture, array, array_of, check_amd,
    check_amd_launch, ck_gemm_kernarg,
};
use volta_amd_analysis::OutputType::{F32, U32};
use volta_amd_analysis::frontend::ast::Operand;
use volta_amd_analysis::frontend::parse::parse_kernel;
use volta_amd_analysis::{
    AnalysisError, AnalysisResult, ArrayKind, EvalError, InstrId, LdsLaneAccess, LdsRace,
    LowerError, StoreConflict, Terminal, WaveId, WorkgroupLaunch, analyze, analyze_grid,
};
use volta_expr::SymbolicOutputs;
use volta_graph_check::{GraphConclusion, check_graph};

// Test nonzero X/Y/Z coordinates in every lane, including descriptors with unused axes.
#[test]
fn workgroup_ids_follow_the_kernel_descriptor() {
    let cases: [(&str, &[u32]); 4] = [
        ("workgroup_x", &[2]),
        ("workgroup_y", &[3]),
        ("workgroup_z", &[5]),
        ("workgroup_xyz", &[2, 3, 5]),
    ];
    for (name, expected) in cases {
        let actual = run_workgroup_id_kernel(name).verified_outputs();
        assert_eq!(actual.outputs.len(), 1);
        let (array, elements) = &actual.outputs[0];
        assert_eq!(array, "out");
        assert_eq!(elements.len(), expected.len() * 64);

        // Each coordinate must reach all 64 lanes, with no missing or extra stores.
        for (i, &(index, value)) in elements.iter().enumerate() {
            assert_eq!(index, i as u64);
            assert_eq!(
                actual.arena.as_int_const(value),
                Some(i64::from(expected[i / 64])),
                "{name}[{index}]"
            );
        }
    }
}

// Test that graph metadata identifies the selected workgroup and the full launch grid.
#[test]
fn workgroup_graph_records_selected_launch() {
    let run = run_workgroup_id_kernel("workgroup_xyz");
    let provenance = run.analysis.graph.provenance();
    assert_eq!(provenance.grid_dim, (3, 4, 6));
    assert_eq!(provenance.workgroup_id, (2, 3, 5));
    assert!(
        provenance.assumes(volta_graph::Assumption::SelectedWorkgroupAnalyzed { id: (2, 3, 5) })
    );
    assert!(!provenance.assumes(volta_graph::Assumption::UniformWorkgroupControlFlow));
}

/// Run a coordinate fixture in workgroup (2, 3, 5) with room for all three coordinates per lane,
/// and check its graph.
fn run_workgroup_id_kernel(name: &str) -> AmdChecked {
    let launch = WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
        workgroup_id: (2, 3, 5),
        grid_size: (3, 4, 6),
    };
    let out = array_of("out", 0x10000, 3 * 64, ArrayKind::Output(U32));
    let run = check_amd_launch(
        "success/workgroup_ids.s",
        amd_fixture!("success/workgroup_ids"),
        name,
        &launch,
        &out.base.to_le_bytes(),
        std::slice::from_ref(&out),
    );
    assert_eq!(run.analysis.terminal, Terminal::Completed, "{name}");
    run
}

// Test that one run over a 2 x 2 x 2 grid gives every workgroup the coordinates a run of that
// workgroup alone stores, and reports each element that later workgroups store again.
#[test]
fn a_grid_run_gives_each_workgroup_its_own_outputs() {
    let grid_size = (2, 2, 2);
    let launch = |workgroup_id| WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
        workgroup_id,
        grid_size,
    };
    let source = amd_fixture!("success/workgroup_ids");
    let kernel = parse_kernel(source, "workgroup_xyz").unwrap();
    let out = array_of("out", 0x10000, 3 * 64, ArrayKind::Output(U32));
    let arrays = std::slice::from_ref(&out);
    let kernarg = out.base.to_le_bytes();
    // A grid run ignores the selected coordinate, even when it lies outside the grid.
    let grid = analyze_grid(
        &kernel,
        &launch((u32::MAX, u32::MAX, u32::MAX)),
        &kernarg,
        arrays,
    )
    .unwrap();
    assert_eq!(grid.terminal, Terminal::Completed);
    assert_eq!(
        check_graph(&grid.graph).conclusion(),
        GraphConclusion::Verified
    );
    assert_eq!(grid.workgroups.len(), 8);
    assert_eq!(grid.graph.provenance().workgroup_id, (0, 0, 0));
    assert!(
        grid.graph
            .provenance()
            .assumes(volta_graph::Assumption::UniformWorkgroupControlFlow)
    );
    assert!(
        !grid
            .graph
            .provenance()
            .assumes(volta_graph::Assumption::SingleWorkgroupAnalyzed)
    );
    assert!(
        !grid
            .graph
            .provenance()
            .assumptions
            .iter()
            .any(|assumption| {
                matches!(
                    assumption,
                    volta_graph::Assumption::SelectedWorkgroupAnalyzed { .. }
                )
            })
    );

    // Each workgroup's stored words must equal those of a verified run that selects it.
    for (id, outputs) in &grid.workgroups {
        let file = "success/workgroup_ids.s";
        let alone = check_amd_launch(
            file,
            source,
            "workgroup_xyz",
            &launch(*id),
            &kernarg,
            arrays,
        );
        let expected = alone.verified_outputs();
        assert_eq!(output_words(outputs), output_words(&expected), "{id:?}");
    }

    // All eight workgroups store the same 192 elements, so each later one conflicts with the first.
    assert_eq!(grid.conflicts.len(), 7 * 192);
    assert_eq!(
        grid.conflicts[0],
        StoreConflict {
            array: "out".into(),
            index: 0,
            workgroups: [(0, 0, 0), (1, 0, 0)],
        }
    );
}

/// Each written element of the first output array with its concrete word, if it has one.
fn output_words(outputs: &SymbolicOutputs) -> Vec<(u64, Option<i64>)> {
    outputs.outputs[0]
        .1
        .iter()
        .map(|&(index, value)| (index, outputs.arena.as_int_const(value)))
        .collect()
}

// Test rejection of empty or overflowing grids and selected workgroups outside the grid.
#[test]
fn invalid_workgroup_launches_are_rejected() {
    let kernel = parse_kernel(include_str!("success/workgroup_ids.s"), "workgroup_xyz").unwrap();
    let out = array_of("out", 0x10000, 192, ArrayKind::Output(U32));
    for (grid_size, workgroup_id) in [
        ((0, 1, 1), (0, 0, 0)),
        ((1, 0, 1), (0, 0, 0)),
        ((1, 1, 0), (0, 0, 0)),
        ((3, 4, 6), (3, 0, 0)),
        ((3, 4, 6), (0, 4, 0)),
        ((3, 4, 6), (0, 0, 6)),
    ] {
        let launch = WorkgroupLaunch {
            kernarg_address: 0x1000,
            workgroup_size: (64, 1, 1),
            workgroup_id,
            grid_size,
        };
        let result = analyze(
            &kernel,
            &launch,
            &out.base.to_le_bytes(),
            std::slice::from_ref(&out),
        );
        assert!(
            matches!(result, Err(AnalysisError::Eval(EvalError::Launch { .. }))),
            "expected launch rejection for grid {grid_size:?}, workgroup {workgroup_id:?}"
        );
    }
    for grid_size in [(0, 1, 1), (1, 0, 1), (1, 1, 0), (1 << 31, 1 << 31, 4)] {
        let launch = WorkgroupLaunch {
            kernarg_address: 0x1000,
            workgroup_size: (64, 1, 1),
            workgroup_id: (0, 0, 0),
            grid_size,
        };
        let result = analyze_grid(
            &kernel,
            &launch,
            &out.base.to_le_bytes(),
            std::slice::from_ref(&out),
        );
        assert!(
            matches!(result, Err(AnalysisError::Eval(EvalError::Launch { .. }))),
            "expected launch rejection for grid {grid_size:?}"
        );
    }
}

#[test]
fn grid_results_that_cannot_fit_addressable_memory_are_rejected_before_enumeration() {
    let mut kernel =
        parse_kernel(include_str!("success/workgroup_ids.s"), "workgroup_xyz").unwrap();
    // The product fits usize on 64-bit hosts, but not a Vec of per-workgroup results.
    let launch = WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
        workgroup_id: (0, 0, 0),
        grid_size: (u32::MAX, u32::MAX, 1),
    };
    for enabled in [1, 0] {
        for axis in ["x", "y", "z"] {
            kernel
                .descriptor
                .insert(format!("system_sgpr_workgroup_id_{axis}"), enabled);
        }
        assert!(matches!(
            analyze_grid(&kernel, &launch, &[], &[]),
            Err(AnalysisError::Eval(EvalError::Launch { .. }))
        ));
    }
}

#[test]
fn small_grids_without_workgroup_id_inputs_keep_every_copy_output() {
    let mut kernel = parse_kernel(include_str!("success/copy.s"), "copy").unwrap();
    for axis in ["x", "y", "z"] {
        kernel
            .descriptor
            .insert(format!("system_sgpr_workgroup_id_{axis}"), 0);
    }
    let launch = WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
        workgroup_id: (0, 0, 0),
        grid_size: (2, 1, 1),
    };
    let arrays = [
        array("in", 0x10000, ArrayKind::Input),
        array("out", 0x20000, ArrayKind::Output(F32)),
    ];
    let kernarg: Vec<_> = arrays
        .iter()
        .flat_map(|array| array.base.to_le_bytes())
        .collect();
    let grid = analyze_grid(&kernel, &launch, &kernarg, &arrays).unwrap();
    assert_eq!(grid.terminal, Terminal::Completed);
    assert_eq!(grid.workgroups.len(), 2);
    assert_eq!(grid.conflicts.len(), 64);
    for (group, (id, outputs)) in grid.workgroups.iter().enumerate() {
        assert_eq!(*id, (group as u32, 0, 0));
        assert_eq!(outputs.outputs[0].0, "out");
        assert_eq!(outputs.outputs[0].1.len(), 64);
        for (index, value) in &outputs.outputs[0].1 {
            assert!(matches!(
                outputs.arena.node(*value),
                volta_expr::ExprNode::InputElement { array, index: input_index }
                    if outputs.arena.string(*array) == "in" && input_index == index
            ));
        }
    }
}

// Test that equal LDS addresses can depend on workgroup IDs, while each workgroup's words
// retain their bits through LDS, XOR and lane exchange, and convert numerically to floats.
#[test]
fn grid_lds_words_keep_their_integer_bits() {
    let kernel = parse_kernel(include_str!("success/workgroup_ids.s"), "grid_lds_words").unwrap();
    let launch = WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
        workgroup_id: (0, 0, 0),
        grid_size: (2, 1, 1),
    };
    let arrays = [
        array_of("out", 0x10000, 2 * 192, ArrayKind::Output(U32)),
        array_of("converted", 0x20000, 2 * 64, ArrayKind::Output(F32)),
    ];
    let kernarg: Vec<u8> = arrays.iter().flat_map(|a| a.base.to_le_bytes()).collect();
    let grid = analyze_grid(&kernel, &launch, &kernarg, &arrays).unwrap();
    assert_eq!(grid.terminal, Terminal::Completed);
    assert_eq!(
        check_graph(&grid.graph).conclusion(),
        GraphConclusion::Verified
    );
    assert_eq!(grid.workgroups.len(), 2);
    assert!(grid.conflicts.is_empty());

    for (id, outputs) in &grid.workgroups {
        let group = u64::from(id.0);
        assert_eq!(outputs.outputs.len(), 2);
        let (name, words) = &outputs.outputs[0];
        assert_eq!(name, "out");
        assert_eq!(words.len(), 192);
        for (local, &(index, value)) in words.iter().enumerate() {
            assert_eq!(index, group * 192 + local as u64);
            let lane = local as u64 % 64;
            let read = group * 64 + (lane ^ 1) + 1;
            let expected = match local / 64 {
                0 => read,
                1 => read ^ 85,
                2 => group * 64 + (lane ^ 3) + 1,
                _ => unreachable!(),
            };
            assert_eq!(outputs.arena.as_int_const(value), Some(expected as i64));
        }

        let (name, converted) = &outputs.outputs[1];
        assert_eq!(name, "converted");
        assert_eq!(converted.len(), 64);
        for (lane, &(index, value)) in converted.iter().enumerate() {
            assert_eq!(index, group * 64 + lane as u64);
            let expected = group * 64 + (lane as u64 ^ 1) + 1;
            assert_eq!(outputs.arena.as_f64(value), Some(expected as f64));
        }
    }
}

// Test that differing VCC masks may take the same branch and still select different lanes.
#[test]
fn grid_branches_compare_taken_paths_not_individual_vcc_bits() {
    let kernel = parse_kernel(include_str!("success/workgroup_ids.s"), "grid_vcc_branch").unwrap();
    let launch = WorkgroupLaunch {
        kernarg_address: 0x1000,
        workgroup_size: (64, 1, 1),
        workgroup_id: (0, 0, 0),
        grid_size: (2, 1, 1),
    };
    let out = array_of("out", 0x10000, 128, ArrayKind::Output(U32));
    let grid = analyze_grid(&kernel, &launch, &out.base.to_le_bytes(), &[out]).unwrap();
    assert_eq!(grid.terminal, Terminal::Completed);
    assert_eq!(
        check_graph(&grid.graph).conclusion(),
        GraphConclusion::Verified
    );
    assert_eq!(grid.workgroups.len(), 2);
    assert!(grid.conflicts.is_empty());
    for (id, outputs) in &grid.workgroups {
        let expected: Vec<_> = (0..64)
            .map(|lane| {
                (
                    u64::from(id.0) * 64 + lane,
                    Some(if lane == u64::from(id.0) { 17 } else { 0 }),
                )
            })
            .collect();
        assert_eq!(output_words(outputs), expected, "{id:?}");
    }
}

#[test]
fn the_copy_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/copy",
        &[
            array("in", 0x10000, ArrayKind::Input),
            array("out", 0x20000, ArrayKind::Output(F32)),
        ],
    );
}

#[test]
fn the_add_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/add",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array("b", 0x20000, ArrayKind::Input),
            array("out", 0x30000, ArrayKind::Output(F32)),
        ],
    );
}

#[test]
fn the_relu_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/relu",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array("out", 0x20000, ArrayKind::Output(F32)),
        ],
    );
}

#[test]
fn the_sigmoid_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/sigmoid",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array("out", 0x20000, ArrayKind::Output(F32)),
        ],
    );
}

// Test eight independent 16-element softmax rows across two waves.
#[test]
fn the_softmax_kernel_writes_its_expected_outputs() {
    common::amd::check_run_on(
        "success/softmax",
        128,
        &[
            array_of("input", 0x10000, 128, ArrayKind::Input),
            array_of("output", 0x20000, 128, ArrayKind::Output(F32)),
        ],
    );
}

/// The elements of each 8 x 8 matrix; work-item `i` computes element `i` of the product.
const MATMUL_ELEMENTS: u32 = 8 * 8;

#[test]
fn the_matmul_kernel_writes_its_expected_outputs() {
    let len = u64::from(MATMUL_ELEMENTS);
    common::amd::check_run_on(
        "success/matmul",
        MATMUL_ELEMENTS,
        &[
            array_of("a", 0x10000, len, ArrayKind::Input),
            array_of("b", 0x20000, len, ArrayKind::Input),
            array_of("c", 0x30000, len, ArrayKind::Output(F32)),
        ],
    );
}

// Test that each element of an 8 x 8 matrix is written to its transposed position.
#[test]
fn the_transpose_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/transpose",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array("out", 0x20000, ArrayKind::Output(F32)),
        ],
    );
}

/// Each work-item writes one result per operation to its own row of 32 floats.
const FLOAT_OPS_ROW: u64 = 32;

// Test packed add, multiply and FMA with selectors, negation and overlapping sources.
// The expected expressions are derived from the source operations for both components.
#[test]
fn the_packed_float_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/packed_float_ops",
        &[
            array_of("a", 0x10000, 128, ArrayKind::Input),
            array_of("b", 0x20000, 128, ArrayKind::Input),
            array_of("c", 0x30000, 128, ArrayKind::Input),
            array_of("out", 0x40000, 64 * 32, ArrayKind::Output(F32)),
        ],
    );
}

// Test float arithmetic, source modifiers and selects against their expected expressions.
#[test]
fn the_float_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/float_ops",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array("b", 0x20000, ArrayKind::Input),
            array_of("out", 0x30000, 64 * FLOAT_OPS_ROW, ArrayKind::Output(F32)),
        ],
    );
}

// Test that each f32 comparison keeps its symbolic predicate per lane in an SGPR mask,
// so a select on that mask reads as `(a op b) ? b : a`.
#[test]
fn the_compare_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/compare_ops",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array("b", 0x20000, ArrayKind::Input),
            array_of("out", 0x30000, 64 * 12, ArrayKind::Output(F32)),
            array_of("out_e32", 0x40000, 64 * 12, ArrayKind::Output(F32)),
        ],
    );
}

// Test that accumulator writes preserve symbolic VGPR and SGPR sources and inline constants,
// and that reading the original accumulator back preserves each lane's input.
#[test]
fn the_accvgpr_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/accvgpr",
        &[
            array("a", 0x10000, ArrayKind::Input),
            array_of("out", 0x20000, 4 * 64, ArrayKind::Output(F32)),
            array("back", 0x30000, ArrayKind::Output(F32)),
        ],
    );
}

/// The four waves of a 32 x 32 product with an inner dimension of 8, each one 16 x 16 tile.
const MFMA_MATMUL_WORKITEMS: u32 = 4 * 64;

#[test]
fn the_mfma_matmul_kernel_writes_its_expected_outputs() {
    common::amd::check_run_on(
        "success/mfma_matmul",
        MFMA_MATMUL_WORKITEMS,
        &[
            array_of("a", 0x10000, 32 * 8, ArrayKind::Input),
            array_of("b", 0x20000, 8 * 32, ArrayKind::Input),
            array_of("c", 0x30000, 32 * 32, ArrayKind::Output(F32)),
        ],
    );
}

/// Each work-item writes integer and float results to separate rows of 64 elements.
const BIT_OPS_ROW: u64 = 64;

// Test concrete bit operations, including NOT in both encodings, and symbolic float arithmetic
// against independently calculated outputs for all 64 lanes.
#[test]
fn the_bit_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/bit_ops",
        &[
            array_of("a", 0x10000, 2 * 64, ArrayKind::Input),
            array("b", 0x20000, ArrayKind::Input),
            array_of("out", 0x30000, 64 * BIT_OPS_ROW, ArrayKind::Output(U32)),
            array_of(
                "float_out",
                0x40000,
                64 * BIT_OPS_ROW,
                ArrayKind::Output(F32),
            ),
        ],
    );
}

// Test signed arithmetic, comparisons of 64-bit values with equal low words,
// and a two-iteration scalar loop.
#[test]
fn the_scalar_ops_kernel_writes_its_expected_outputs() {
    let out = 0x10000_u64;
    let mut kernarg = out.to_le_bytes().to_vec();
    for value in [-(1_i32 << 30), -8] {
        kernarg.extend(value.to_le_bytes());
    }
    // The OR is 3 << 32; x and y differ only in their high words.
    for value in [1_u64 << 32, 2_u64 << 32, 3_u64 << 32] {
        kernarg.extend(value.to_le_bytes());
    }
    kernarg.extend(2_i32.to_le_bytes());
    common::amd::check_run_kernel(
        "success/scalar_ops",
        "scalar_ops",
        64,
        &kernarg,
        &[array_of("out", out, 64 * 8, ArrayKind::Output(U32))],
    );
}

/// Launch the scalar fixture with concrete arithmetic operands, comparison
/// words and loop count, and check its graph.
fn run_scalar_ops(signed: [i32; 2], words: [u64; 3], count: i32) -> AmdChecked {
    let out = 0x10000_u64;
    let mut kernarg = out.to_le_bytes().to_vec();
    for value in signed {
        kernarg.extend(value.to_le_bytes());
    }
    for value in words {
        kernarg.extend(value.to_le_bytes());
    }
    kernarg.extend(count.to_le_bytes());
    check_amd(
        "success/scalar_ops.s",
        amd_fixture!("success/scalar_ops"),
        "scalar_ops",
        64,
        &kernarg,
        &[array_of("out", out, 64 * 8, ArrayKind::Output(U32))],
    )
}

/// Check all six written words in every lane's row of a verified run, with no extra output
/// elements.
fn assert_scalar_rows(run: AmdChecked, expected: [u32; 6]) {
    let outputs = run.verified_outputs();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    assert_eq!(outputs.outputs[0].1.len(), 64 * 6);
    for lane in 0..64 {
        for (column, word) in expected.iter().enumerate() {
            let index = lane * 8 + column as u64;
            let actual = outputs
                .element("out", index)
                .and_then(|id| outputs.arena.as_int_const(id));
            assert_eq!(actual, Some(i64::from(*word)), "out[{index}]");
        }
    }
}

// Test arithmetic boundaries, 64-bit comparisons and loop counts. The zero comparison
// adds one to the loop result only when x is zero, exercising both branch outcomes.
#[test]
fn scalar_ops_handles_boundary_arguments() {
    let kernel = parse_kernel(include_str!("success/scalar_ops.s"), "scalar_ops").unwrap();
    // Require the compiled fixture to retain both instruction forms under test.
    assert!(kernel.instructions.iter().any(|instr| {
        instr.opcode == "s_cmp_eq_u64" && instr.operands.last() == Some(&Operand::Imm(0))
    }));
    assert!(
        kernel
            .instructions
            .iter()
            .any(|instr| instr.opcode == "s_cbranch_scc0")
    );
    for (signed, words, count, expected) in [
        // Zero OR differs from a word with a nonzero high half; x = 0 adds one to the loop result.
        (
            [i32::MIN, -1],
            [0, 0, 1 << 32],
            1,
            [0, u32::MAX, 1, 0, 1, 27],
        ),
        // Equal full-width words and three iterations of the recurrence.
        (
            [i32::MAX, i32::MAX],
            [0x8000_0001_0000_0001; 3],
            3,
            [0x3fff_ffff, 0xc000_0000, i32::MAX as u32, 1, 1, 480_266],
        ),
        // Equal signed maximum operands; comparison words differ only in
        // their low halves.
        (
            [-8, 8],
            [0x1_0000_0001, 0x1_0000_0002, 0x1_0000_0003],
            2,
            [u32::MAX, 0, 0xffff_fff8, 1, 0, 693],
        ),
    ] {
        assert_scalar_rows(run_scalar_ops(signed, words, count), expected);
    }
}

// Test integer multiplication, bit counts, 64-bit and packed moves, and signed comparisons.
// Check all 64 lanes against the expected outputs in vector_int_ops.out.
#[test]
fn the_vector_int_ops_kernel_writes_its_expected_outputs() {
    let out = 0x10000_u64;
    let mut kernarg = out.to_le_bytes().to_vec();
    // The multiplication factor, then the mask for the masked bit counts.
    for value in [0x1_0001_u32, 0xaaaa_aaaa] {
        kernarg.extend(value.to_le_bytes());
    }
    // Compare values above, below and equal to 0x7fffffff, including a negative value.
    for value in [1_u64 << 32, 0x8000_0000, 0x7fff_fffe, u64::MAX, 0x7fff_ffff] {
        kernarg.extend(value.to_le_bytes());
    }
    common::amd::check_run_kernel(
        "success/vector_int_ops",
        "vector_int_ops",
        64,
        &kernarg,
        &[array_of("out", out, 64 * 64, ArrayKind::Output(U32))],
    );
}

// Test every 64-bit integer comparison in its e32 and e64 encodings across lanes whose values
// are below, equal to and above zero, and 64-bit moves from a VGPR pair.
#[test]
fn the_compare64_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/compare64_ops",
        &[array_of("out", 0x10000, 64 * 32, ArrayKind::Output(U32))],
    );
}

// Test the conversions between f32 and 32-bit integers in both signednesses: words with the
// sign bit set, from a VGPR and an SGPR, and floats that truncate toward zero or clamp at each
// bound of the result's range.
#[test]
fn the_convert_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/convert_ops",
        &[
            array_of("floats", 0x10000, 64 * 4, ArrayKind::Output(F32)),
            array_of("words", 0x20000, 64 * 4, ArrayKind::Output(U32)),
        ],
    );
}

// Test the scalar ALU results and the SCC each one leaves, every scalar comparison in both
// operand orders, bit comparisons, branches on VCC and EXEC, and 64-bit literal sources.
#[test]
fn the_scalar_alu_ops_kernel_writes_its_expected_outputs() {
    let out = 0x10000_u64;
    let mut kernarg = out.to_le_bytes().to_vec();
    // Two operands whose signed and unsigned orders differ, then two shift counts and bit indices.
    for value in [0xf0f0_f00f_u32, 0x1234_5678, 36, 32] {
        kernarg.extend(value.to_le_bytes());
    }
    for value in [0xf0f0_f0f0_0000_ffff_u64, 0x0ff0_0ff0_1234_5678] {
        kernarg.extend(value.to_le_bytes());
    }
    common::amd::check_run_kernel(
        "success/scalar_alu_ops",
        "scalar_alu_ops",
        64,
        &kernarg,
        &[array_of("out", out, 64 * 128, ArrayKind::Output(U32))],
    );
}

/// Each work-item writes its results to a row of 32 words.
const EXEC_OPS_ROW: u64 = 32;

// Test instructions that run while EXEC holds only some lanes, against the expected outputs in
// exec_ops.out: an inactive lane keeps its registers and writes no memory, its bit is clear in
// a comparison or carry mask, and EXEC branches and first-lane reads follow the mask.
#[test]
fn the_exec_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/exec_ops",
        &[
            array("input", 0x10000, ArrayKind::Input),
            array_of("out", 0x20000, 64 * EXEC_OPS_ROW, ArrayKind::Output(U32)),
            array("floats", 0x30000, ArrayKind::Output(F32)),
        ],
    );
}

// Test every scalar operation that writes EXEC, against the expected outputs in
// saveexec_ops.out: the EXEC and SCC each one leaves from a source mask and the active lanes,
// the old or new EXEC it copies, and then the compiler's own masking of a branch.
#[test]
fn the_saveexec_ops_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/saveexec_ops",
        // Each of the 64 work-items writes its results to a row of 80 words.
        &[array_of("out", 0x10000, 64 * 80, ArrayKind::Output(U32))],
    );
}

// Test f64 arithmetic, modifiers, constants, conversions, comparisons, moves and overlapping
// registers. Check all 64 lanes against the expected outputs in f64_ops.out.
#[test]
fn the_f64_ops_kernel_writes_its_expected_outputs() {
    let arrays = [
        array("a", 0x10000, ArrayKind::Input),
        array("b", 0x20000, ArrayKind::Input),
        array("c", 0x30000, ArrayKind::Input),
        array_of("out", 0x40000, 64 * 64, ArrayKind::Output(F32)),
        array_of("int_out", 0x50000, 64 * 8, ArrayKind::Output(U32)),
    ];
    let mut kernarg: Vec<u8> = arrays.iter().flat_map(|a| a.base.to_le_bytes()).collect();
    kernarg.extend(1.5_f64.to_bits().to_le_bytes());
    common::amd::check_run_kernel("success/f64_ops", "f64_ops", 64, &kernarg, &arrays);
}

/// Run a `ck_gemm.hip`-style instance on an 8 x 8 x 8 problem.
fn check_ck_gemm(fixture: &str, kernel: &str) {
    let (a, b, c) = (0x10000, 0x20000, 0x30000);
    common::amd::check_run_kernel(
        fixture,
        kernel,
        128,
        &ck_gemm_kernarg(a, b, c, [8, 8, 8]),
        &[
            array_of("a", a, 8 * 8, ArrayKind::Input),
            array_of("b", b, 8 * 8, ArrayKind::Input),
            array_of("c", c, 8 * 8, ArrayKind::Output(F32)),
        ],
    );
}

#[test]
fn the_ck_gemm_kernel_writes_its_expected_outputs() {
    check_ck_gemm("success/ck_gemm", CK_GEMM_KERNEL);
}

// Test the fused sigmoid epilogue: its exp's underflow guard compares symbolic accumulators into
// SGPR lane masks and selects a negated source on them.
#[test]
fn the_ck_gemm_sigmoid_kernel_writes_its_expected_outputs() {
    check_ck_gemm("success/ck_gemm_sigmoid", CK_GEMM_SIGMOID_KERNEL);
}

// Test that each output sums 25 adjacent input values weighted by the shared filter.
#[test]
fn the_convolution_1d_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/convolution_1d",
        &[
            array_of("input", 0x10000, 64 + 25 - 1, ArrayKind::Input),
            array_of("filter", 0x20000, 25, ArrayKind::Input),
            array("output", 0x30000, ArrayKind::Output(F32)),
        ],
    );
}

// Test that each output of the 8 x 8 image sums its 3 x 3 window of the 10 x 10 input,
// weighted by the shared filter.
#[test]
fn the_convolution_2d_kernel_writes_its_expected_outputs() {
    common::amd::check_run(
        "success/convolution_2d",
        &[
            array_of("input", 0x10000, 10 * 10, ArrayKind::Input),
            array_of("filter", 0x20000, 3 * 3, ArrayKind::Input),
            array("output", 0x30000, ArrayKind::Output(F32)),
        ],
    );
}

// Test that the same stored bits become real constants in float outputs and words in integer outputs.
#[test]
fn constant_outputs_follow_their_declared_types() {
    common::amd::check_run(
        "success/output_constants",
        &[
            array("floats", 0x10000, ArrayKind::Output(F32)),
            array("words", 0x20000, ArrayKind::Output(U32)),
        ],
    );
}

// Test that a symbolic input cannot be exported as a concrete integer word.
#[test]
fn symbolic_integer_outputs_are_rejected() {
    let arrays = [
        array("in", 0x10000, ArrayKind::Input),
        array("out", 0x20000, ArrayKind::Output(U32)),
    ];
    common::amd::check_rejected_kernel("success/copy", "copy", &arrays, |result| {
        matches!(
            result,
            Ok(AnalysisResult {
                terminal: Terminal::Aborted {
                    error: EvalError::InvalidIntegerOutput { address: 0x20000 },
                    ..
                },
                symbolic_outputs: None,
                ..
            })
        )
    });
}

// Test that storing a NaN bit pattern to a float output aborts instead of exporting a real value.
#[test]
fn nan_float_outputs_are_rejected() {
    let arrays = [array("out", 0x10000, ArrayKind::Output(F32))];
    common::amd::check_rejected_kernel(
        "success/output_constants",
        "nan_output",
        &arrays,
        |result| {
            matches!(
                result,
                Ok(AnalysisResult {
                    terminal: Terminal::Aborted {
                        error: EvalError::InvalidFloatOutput { address: 0x10000 },
                        ..
                    },
                    symbolic_outputs: None,
                    ..
                })
            )
        },
    );
}

// Test that integer arithmetic and bitwise operations reject symbolic inputs,
// because symbolic values are floats without known bits.
#[test]
fn integer_operations_on_symbolic_values_are_rejected() {
    let arrays = [
        array("input", 0x10000, ArrayKind::Input),
        array("output", 0x20000, ArrayKind::Output(F32)),
    ];
    for kernel in [
        "symbolic_shift",
        "symbolic_negation",
        "symbolic_add",
        "symbolic_not",
    ] {
        common::amd::check_rejected_kernel(
            "execution_error/unsupported",
            kernel,
            &arrays,
            |result| {
                matches!(
                    result,
                    Ok(AnalysisResult {
                        terminal: Terminal::Aborted {
                            error: EvalError::SymbolicWord { lane: 0 },
                            ..
                        },
                        symbolic_outputs: None,
                        ..
                    })
                )
            },
        );
    }
}

// Test that a scalar AND rejects the symbolic lane mask produced by a float comparison.
#[test]
fn scalar_operations_on_symbolic_masks_are_rejected() {
    let arrays = [
        array("input", 0x10000, ArrayKind::Input),
        array("output", 0x20000, ArrayKind::Output(U32)),
    ];
    common::amd::check_rejected_kernel(
        "execution_error/unsupported",
        "symbolic_mask",
        &arrays,
        |result| {
            matches!(
                result,
                Ok(AnalysisResult {
                    terminal: Terminal::Aborted {
                        error: EvalError::SymbolicSgpr(_),
                        ..
                    },
                    symbolic_outputs: None,
                    ..
                })
            )
        },
    );
}

// Test that a float comparison choosing between two constants is rejected, because the
// chosen words could encode floats or integers.
#[test]
fn selecting_between_constants_under_a_symbolic_condition_is_rejected() {
    let arrays = [
        array("input", 0x10000, ArrayKind::Input),
        array("output", 0x20000, ArrayKind::Output(F32)),
    ];
    common::amd::check_rejected_kernel(
        "execution_error/unsupported",
        "symbolic_select",
        &arrays,
        |result| {
            matches!(
                result,
                Ok(AnalysisResult {
                    terminal: Terminal::Aborted {
                        error: EvalError::AmbiguousSelect { lane: 0 },
                        ..
                    },
                    symbolic_outputs: None,
                    ..
                })
            )
        },
    );
}

// Symbolic input comparisons cannot select a concrete EXEC mask, even when saveexec is modeled.
#[test]
fn intra_wave_divergence_is_rejected() {
    let arrays = [
        array("input", 0x10000, ArrayKind::Input),
        array("output", 0x20000, ArrayKind::Output(F32)),
    ];
    common::amd::check_rejected_kernel(
        "execution_error/unsupported",
        "divergent_store",
        &arrays,
        |result| {
            matches!(
                result,
                Ok(AnalysisResult {
                    terminal: Terminal::Aborted {
                        wave: WaveId(0),
                        pc: InstrId(6),
                        error: EvalError::SymbolicVcc { lane: 0 },
                    },
                    symbolic_outputs: None,
                    ..
                })
            )
        },
    );
}

mod lds_completion {
    //! Ordinary LDS completion and certified cross-wave barrier conflicts.

    use volta_amd_analysis::frontend::parse::parse_kernel;
    use volta_amd_analysis::{
        AnalysisResult, ArrayDef, ArrayKind, EvalError, InstrId, OutputType, Terminal, Vgpr,
        WaveId, WorkgroupLaunch, analyze,
    };
    use volta_expr::ExprNode;

    const WRITE: &str = include_str!("success/lds_write_before_barrier.s");
    const READ: &str = include_str!("success/lds_read_before_barrier.s");

    fn run(source: &str, kernel: &str, workitems: u32) -> AnalysisResult {
        let kernel = parse_kernel(source, kernel).unwrap();
        let mut args = 0x10000_u64.to_le_bytes().to_vec();
        args.extend(0x20000_u64.to_le_bytes());
        analyze(
            &kernel,
            &WorkgroupLaunch {
                kernarg_address: 0x1000,
                workgroup_size: (workitems, 1, 1),
                workgroup_id: (0, 0, 0),
                grid_size: (1, 1, 1),
            },
            &args,
            &[
                ArrayDef {
                    name: "input".into(),
                    base: 0x10000,
                    len: u64::from(workitems),
                    kind: ArrayKind::Input,
                },
                ArrayDef {
                    name: "out".into(),
                    base: 0x20000,
                    len: u64::from(workitems),
                    kind: ArrayKind::Output(OutputType::F32),
                },
            ],
        )
        .unwrap()
    }

    fn assert_outputs(result: AnalysisResult, workitems: u64, xor: u64) {
        assert_eq!(result.terminal, Terminal::Completed);
        assert_eq!(
            volta_graph_check::check_graph(&result.graph).conclusion(),
            volta_graph_check::GraphConclusion::Verified
        );
        let outputs = result.symbolic_outputs.unwrap();
        assert_eq!(outputs.outputs.len(), 1);
        assert_eq!(outputs.outputs[0].0, "out");
        assert_eq!(outputs.outputs[0].1.len(), workitems as usize);
        for i in 0..workitems {
            let id = outputs.element("out", i).unwrap();
            assert!(matches!(
                outputs.arena.node(id),
                ExprNode::InputElement { array, index }
                    if outputs.arena.string(*array) == "input" && *index == (i ^ xor)
            ));
        }
    }

    fn assert_barrier_conflict(result: AnalysisResult, pc: u32) {
        use volta_graph::Space;
        use volta_graph_check::domain::ConflictKind;
        use volta_graph_check::{GraphConclusion, check_graph};
        assert_eq!(result.terminal, Terminal::Completed);
        let report = check_graph(&result.graph);
        assert!(matches!(
            report.conclusion(),
            GraphConclusion::Rejected { .. }
        ));
        assert!(
            report.memory_conflict.violations().iter().any(|conflict| {
                conflict.location.space == Space::Shared
                    && result.graph.acting_thread(conflict.earlier)
                        != result.graph.acting_thread(conflict.later)
                    && matches!(
                        conflict.kind,
                        ConflictKind::WriteRead | ConflictKind::ReadWrite
                    )
            }),
            "missing cross-wave LDS conflict at barrier pc {pc}: {:?}",
            report.memory_conflict
        );
    }

    fn single_wave(body: &str) -> String {
        format!(
            r#".amdgcn_target "amdgcn-amd-amdhsa--gfx950:xnack-"
    .text
    k:
    s_load_dwordx4 s[4:7], s[0:1], 0
    s_waitcnt lgkmcnt(0)
    v_lshlrev_b32_e32 v2, 2, v0
    global_load_dword v1, v2, s[4:5]
    s_waitcnt vmcnt(0)
    {body}
    s_endpgm
    .section .rodata
    .amdhsa_kernel k
    .amdhsa_group_segment_fixed_size 512
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_system_sgpr_workgroup_id_x 0
    .amdhsa_system_sgpr_workgroup_id_y 0
    .amdhsa_system_sgpr_workgroup_id_z 0
    .amdhsa_system_vgpr_workitem_id 0
    .end_amdhsa_kernel
    "#
        )
    }

    #[test]
    fn cross_wave_write_then_read_requires_completion_before_the_barrier() {
        assert_barrier_conflict(run(WRITE, "lds_write_before_barrier", 128), 6);
        let safe = WRITE.replacen(
            "ds_write_b32 v2, v1\ns_barrier",
            "ds_write_b32 v2, v1\ns_waitcnt lgkmcnt(0)\ns_barrier",
            1,
        );
        assert_ne!(safe, WRITE);
        assert_outputs(run(&safe, "lds_write_before_barrier", 128), 128, 64);
    }

    #[test]
    fn cross_wave_read_then_overwrite_requires_completion_before_the_barrier() {
        assert_barrier_conflict(run(READ, "lds_read_before_barrier", 128), 10);
        let safe = READ.replacen(
            "ds_read_b32 v4, v3\ns_barrier",
            "ds_read_b32 v4, v3\ns_waitcnt lgkmcnt(0)\ns_barrier",
            1,
        );
        assert_ne!(safe, READ);
        assert_outputs(run(&safe, "lds_read_before_barrier", 128), 128, 64);
    }

    #[test]
    fn a_wrong_or_partial_wait_does_not_complete_the_pending_lds_write() {
        for wait in [
            "s_waitcnt vmcnt(0)",
            "s_waitcnt lgkmcnt(1)",
            "s_waitcnt lgkmcnt(15)",
        ] {
            let source = WRITE.replacen(
                "ds_write_b32 v2, v1\ns_barrier",
                &format!("ds_write_b32 v2, v1\n{wait}\ns_barrier"),
                1,
            );
            assert_ne!(source, WRITE);
            assert_barrier_conflict(run(&source, "lds_write_before_barrier", 128), 7);
        }
    }

    #[test]
    fn a_later_write_counts_toward_the_partial_wait_and_releases_the_older_read() {
        let body = "ds_write_b32 v2, v1\ns_waitcnt lgkmcnt(0)\nds_read_b32 v4, v2\nds_write_b32 v2, v1\ns_waitcnt lgkmcnt(1)\nglobal_store_dword v2, v4, s[6:7]";
        assert_outputs(run(&single_wave(body), "k", 64), 64, 0);
        let barrier = body.replace("global_store_dword", "s_barrier\nglobal_store_dword");
        // A single wave's issue-ordered DS operations have no cross-wave conflict;
        // a pending later write alone does not make its barrier invalid.
        assert_outputs(run(&single_wave(&barrier), "k", 64), 64, 0);
        let drained = barrier.replace("s_barrier", "s_waitcnt lgkmcnt(0)\ns_barrier");
        assert_outputs(run(&single_wave(&drained), "k", 64), 64, 0);
    }

    #[test]
    fn a_partial_wait_keeps_the_newer_read_pending_after_an_older_write() {
        let body = "ds_write_b32 v2, v1\nds_read_b32 v4, v2\ns_waitcnt lgkmcnt(1)\nglobal_store_dword v2, v4, s[6:7]";
        let result = run(&single_wave(body), "k", 64);
        assert_eq!(
            result.terminal,
            Terminal::Aborted {
                wave: WaveId(0),
                pc: InstrId(8),
                error: EvalError::PendingVgpr {
                    lane: 0,
                    reg: Vgpr(4),
                },
            }
        );
        assert!(result.symbolic_outputs.is_none());
        let drained = body.replace("lgkmcnt(1)", "lgkmcnt(0)");
        assert_outputs(run(&single_wave(&drained), "k", 64), 64, 0);
    }

    #[test]
    fn wide_lds_stores_have_one_completion_entry_for_the_whole_instruction() {
        let body = "ds_write2_b32 v2, v1, v1 offset0:0 offset1:64\nds_read_b32 v4, v2\nds_write2_b32 v2, v1, v1 offset0:0 offset1:64\ns_waitcnt lgkmcnt(2)\nglobal_store_dword v2, v4, s[6:7]";
        let result = run(&single_wave(body), "k", 64);
        assert!(matches!(
            result.terminal,
            Terminal::Aborted {
                error: EvalError::PendingVgpr {
                    lane: 0,
                    reg: Vgpr(4)
                },
                ..
            }
        ));
        assert!(result.symbolic_outputs.is_none());
        let released = body.replace("lgkmcnt(2)", "lgkmcnt(1)");
        assert_outputs(run(&single_wave(&released), "k", 64), 64, 0);
    }

    #[test]
    fn a_maximal_lgkm_field_does_not_release_a_read_from_a_long_logical_history() {
        let writes = "ds_write_b32 v2, v1\n".repeat(16);
        let body = format!(
            "ds_write_b32 v2, v1\ns_waitcnt lgkmcnt(0)\nds_read_b32 v4, v2\n{writes}s_waitcnt lgkmcnt(15)\nglobal_store_dword v2, v4, s[6:7]"
        );
        let result = run(&single_wave(&body), "k", 64);
        assert_eq!(
            result.terminal,
            Terminal::Aborted {
                wave: WaveId(0),
                pc: InstrId(25),
                error: EvalError::PendingVgpr {
                    lane: 0,
                    reg: Vgpr(4),
                },
            }
        );
        assert!(result.symbolic_outputs.is_none());
        let drained = body.replace("lgkmcnt(15)", "lgkmcnt(0)");
        assert_outputs(run(&single_wave(&drained), "k", 64), 64, 0);
    }

    #[test]
    fn empty_lds_queues_allow_repeated_barriers_and_vm_only_work_is_separate() {
        let body = "s_barrier\ns_barrier\nglobal_store_dword v2, v1, s[6:7]";
        assert_outputs(run(&single_wave(body), "k", 64), 64, 0);
        let vm_pending = "global_load_dword v4, v2, s[4:5]\ns_barrier\ns_waitcnt vmcnt(0)\nglobal_store_dword v2, v4, s[6:7]";
        assert_outputs(run(&single_wave(vm_pending), "k", 64), 64, 0);
        assert!(
            EvalError::PendingLdsAtBarrier
                .to_string()
                .contains("lgkmcnt(0)")
        );
    }

    #[test]
    fn pending_scalar_memory_does_not_inherit_the_lds_fifo() {
        let body = "s_load_dword s8, s[0:1], 0\nds_write_b32 v2, v1\ns_waitcnt lgkmcnt(1)\ns_barrier\nds_read_b32 v4, v2\ns_waitcnt lgkmcnt(0)\nglobal_store_dword v2, v4, s[6:7]";
        let result = run(&single_wave(body), "k", 64);
        assert_eq!(
            result.terminal,
            Terminal::Aborted {
                wave: WaveId(0),
                pc: InstrId(7),
                error: EvalError::UnsupportedInstruction,
            }
        );
        assert!(result.symbolic_outputs.is_none());
        let drained = body.replace("lgkmcnt(1)", "lgkmcnt(0)");
        assert_outputs(run(&single_wave(&drained), "k", 64), 64, 0);
    }

    #[test]
    fn lane_exchanges_and_lds_writes_share_the_existing_ds_completion_order() {
        let body = "ds_bpermute_b32 v4, v2, v1\nds_write_b32 v2, v1\ns_waitcnt lgkmcnt(1)\nglobal_store_dword v2, v4, s[6:7]";
        assert_outputs(run(&single_wave(body), "k", 64), 64, 0);
    }
}

// Test that lanes 0 and 32 writing word 0 in one ds_write_b32 (instruction 7) is rejected.
#[test]
fn two_lds_writes_in_the_same_wave_are_rejected() {
    let arrays = [
        array("input", 0x10000, ArrayKind::Input),
        array("output", 0x20000, ArrayKind::Output(F32)),
    ];
    let ds_write_lane = |lane| LdsLaneAccess {
        wave: WaveId(0),
        lane,
        pc: InstrId(7),
    };
    let expected = Terminal::Aborted {
        wave: WaveId(0),
        pc: InstrId(7),
        error: EvalError::LdsRace(LdsRace {
            address: 0,
            earlier: ds_write_lane(0),
            later: ds_write_lane(32),
        }),
    };
    common::amd::check_rejected_kernel(
        "execution_error/lds_race",
        "write_write_race",
        &arrays,
        |result| result.as_ref().is_ok_and(|run| run.terminal == expected),
    );
}

// Test that lgkmcnt(1) completes every DS instruction in flight but the last, writes included,
// and that a partial wait with a scalar load in flight is rejected (issue #19).
#[test]
fn a_partial_lgkm_wait_completes_all_but_the_last_instructions() {
    let arrays = [
        array("input", 0x10000, ArrayKind::Input),
        array("output", 0x20000, ArrayKind::Output(F32)),
    ];
    let kernarg: Vec<u8> = arrays.iter().flat_map(|a| a.base.to_le_bytes()).collect();
    common::amd::check_run_kernel("success/lgkm_wait", "partial_wait", 64, &kernarg, &arrays);

    let expected = Terminal::Aborted {
        wave: WaveId(0),
        pc: InstrId(8),
        error: EvalError::UnsupportedInstruction,
    };
    let kernel = "partial_wait_with_scalar_load";
    common::amd::check_rejected_kernel("success/lgkm_wait", kernel, &arrays, |result| {
        result.as_ref().is_ok_and(|run| run.terminal == expected)
    });
}
