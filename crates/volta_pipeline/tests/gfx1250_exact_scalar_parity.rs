//! Original scalar assertions through genuine gfx1250 compiler output.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph_check::GraphConclusion;
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};

const F64: &str = include_str!("../../../tests/gfx1250/fixtures/native-exact-f64.s");

fn f64_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 8,
        len: 1,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn checked_native(source: &str, name: &str, config: AnalysisConfig) -> SymbolicOutputs {
    let module = frontend::parse(source).unwrap();
    let checked = native_common::check(source, &module, Some(name), config).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{name}: {:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}

fn f64_case(kernel: &str, ptx: &str, golden: &str) -> SymbolicOutputs {
    let actual = checked_native(F64, kernel, f64_config());
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].0, "out");
    assert_eq!(actual.outputs[0].1.len(), 1);
    assert_eq!(actual.outputs[0].1[0].0, 0);
    let expected = golden.trim().strip_prefix("out[0] = ").unwrap();
    assert_eq!(
        actual.arena.display_expr(actual.outputs[0].1[0].1),
        expected
    );
    let module = Parser::new(ptx.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let baseline = volta_ptx_analysis::analyze(&module, Some("k"), f64_config()).unwrap();
    assert!(matches!(
        check_output_equivalence(
            &actual,
            baseline.symbolic_outputs().unwrap(),
            &["out".into()]
        )
        .unwrap(),
        EquivOutcome::Equivalent
    ));
    actual
}

#[test]
fn all_four_exact_f64_assertions_preserve_binary64_bits_and_original_full_output() {
    for (kernel, source, golden) in [
        (
            "exact_f64_fma",
            include_str!("ptx/success/concrete_fma_vs_mul_add.ptx"),
            include_str!("ptx/success/concrete_fma_vs_mul_add.out"),
        ),
        (
            "exact_f64_mul_add",
            include_str!("ptx/success/concrete_fma_vs_mul_add_2.ptx"),
            include_str!("ptx/success/concrete_fma_vs_mul_add_2.out"),
        ),
        (
            "exact_f64_runtime_sum",
            include_str!("ptx/success/runtime_sum_differs_from_prerounded_literal.ptx"),
            include_str!("ptx/success/runtime_sum_differs_from_prerounded_literal.out"),
        ),
        (
            "exact_f64_prerounded_literal",
            include_str!("ptx/success/runtime_sum_differs_from_prerounded_literal_2.ptx"),
            include_str!("ptx/success/runtime_sum_differs_from_prerounded_literal_2.out"),
        ),
    ] {
        f64_case(kernel, source, golden);
    }
}

#[test]
fn exact_f64_pairs_keep_original_positive_and_negative_equivalence_outcomes() {
    let fused = checked_native(F64, "exact_f64_fma", f64_config());
    let separate = checked_native(F64, "exact_f64_mul_add", f64_config());
    assert!(matches!(
        check_output_equivalence(&fused, &separate, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    let sum = checked_native(F64, "exact_f64_runtime_sum", f64_config());
    let literal = checked_native(F64, "exact_f64_prerounded_literal", f64_config());
    assert!(matches!(
        check_output_equivalence(&sum, &literal, &["out".into()]).unwrap(),
        EquivOutcome::NotEquivalent { .. }
    ));
}

#[test]
fn f64_vop2_encoding_is_target_specific_and_keeps_vgpr_second_source() {
    for target in ["gfx1250", "gfx950"] {
        for operation in ["add", "mul"] {
            for (encoding, source1, expected) in [
                ("e32", "v[4:5]", target == "gfx1250"),
                ("e64", "v[4:5]", true),
                ("e32", "s[4:5]", false),
                ("e32", "0", false),
            ] {
                let instruction = format!("v_{operation}_f64_{encoding} v[0:1],v[2:3],{source1}");
                let wave32 = u8::from(target == "gfx1250");
                let source = format!(
                    ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.globl k\n.type k,@function\nk:\n{instruction}\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_wavefront_size32 {wave32}\n.end_amdhsa_kernel\n"
                );
                assert_eq!(
                    frontend::parse(&source).is_ok(),
                    expected,
                    "{target}: {instruction}"
                );
            }
        }
    }
}

#[test]
fn f64_vopd3_profile_preserves_both_words_and_rejects_overlaps_or_other_slots() {
    // The real runtime-sum kernel overwrites source v2 in its Y-slot MOV.
    // Its exact rational golden above already proves both F64 source words
    // were read from the preissue snapshot, before either destination write.
    for (instruction, expected) in [
        (
            "v_dual_add_f64 v[0:1],v[0:1],v[2:3] :: v_dual_mov_b32 v2,0",
            true,
        ),
        (
            "v_dual_mul_f64 v[0:1],v[2:3],v[4:5] :: v_dual_mov_b32 v6,0",
            true,
        ),
        (
            "v_dual_add_f64 v[0:1],v[2:3],v[4:5] :: v_dual_mov_b32 v0,0",
            false,
        ),
        (
            "v_dual_add_f64 v[0:1],v[2:3],v[4:5] :: v_dual_mov_b32 v1,0",
            false,
        ),
        (
            "v_dual_add_f64 v[1:2],v[2:3],v[4:5] :: v_dual_mov_b32 v6,0",
            false,
        ),
        (
            "v_dual_add_f64 v[0:1],v[1:2],v[4:5] :: v_dual_mov_b32 v6,0",
            false,
        ),
        (
            "v_dual_add_f64 v[0:1],v[2:3],v[3:4] :: v_dual_mov_b32 v6,0",
            false,
        ),
        (
            "v_dual_mov_b32 v6,0 :: v_dual_add_f64 v[0:1],v[2:3],v[4:5]",
            false,
        ),
        (
            "v_dual_add_f64 v[0:1],v[2:3],v[4:5] :: v_dual_mov_b32 v6,1",
            false,
        ),
    ] {
        let source = format!(
            ".amdgcn_target \"amdgcn-amd-amdhsa--gfx1250\"\n.text\n.globl k\n.type k,@function\nk:\n{instruction}\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_wavefront_size32 1\n.end_amdhsa_kernel\n"
        );
        assert_eq!(frontend::parse(&source).is_ok(), expected, "{instruction}");
    }
    let mut module = frontend::parse(F64).unwrap();
    let dual = module
        .kernels
        .iter_mut()
        .flat_map(|kernel| &mut kernel.instructions)
        .find(|instruction| {
            matches!(
                instruction.operands.as_slice(),
                [frontend::Operand::Dual(..)]
            )
        })
        .unwrap();
    let frontend::Operand::Dual(x, _) = &mut dual.operands[0] else {
        unreachable!()
    };
    x.operands.clear();
    assert!(volta_amdgpu_analysis::target::validate(&module).is_err());
}
