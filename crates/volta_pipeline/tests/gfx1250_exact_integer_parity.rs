//! Exact original fixed-width assertions through genuine gfx1250 compiler output.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_graph_check::GraphConclusion;
use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};
const NATIVE: &str = include_str!("../../../tests/gfx1250/fixtures/native-exact-integer.s");
fn config(kind: &str, width: u64, len: u64) -> AnalysisConfig {
    let mut cfg = AnalysisConfig::new((if kind == "tile" { 64 } else { 1 }, 1, 1));
    if kind == "scratch" {
        cfg.arrays.push(ArrayDef {
            name: "scratch".into(),
            base: 0x30000,
            elem_width: 1,
            len: 8,
            kind: ArrayKind::Input,
        });
        cfg.params.push(ParamValue::ArrayPtr("scratch".into()));
    } else if kind != "out" {
        cfg.arrays.push(ArrayDef {
            name: "in".into(),
            base: 0x10000,
            elem_width: width,
            len,
            kind: ArrayKind::Input,
        });
        cfg.params.push(ParamValue::ArrayPtr("in".into()));
    }
    cfg.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: width,
        len,
        kind: ArrayKind::Output,
    });
    cfg.params.push(ParamValue::ArrayPtr("out".into()));
    cfg
}
fn check(kernel: &str, baseline: &str, golden: &str, kind: &str, width: u64, len: u64) {
    let cfg = config(kind, width, len);
    let module = frontend::parse(NATIVE).unwrap();
    let run = native_common::check(NATIVE, &module, Some(kernel), cfg.clone()).unwrap();
    let actual = run
        .analysis
        .symbolic_outputs()
        .unwrap_or_else(|e| panic!("{kernel}: {e}"));
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{kernel}: {:#?}",
        run.checks
    );
    let arena = &actual.arena;
    let lines = actual
        .outputs
        .iter()
        .flat_map(|(name, values)| {
            values
                .iter()
                .map(move |(i, v)| format!("{name}[{i}] = {}", arena.display_expr(*v)))
        })
        .collect::<Vec<_>>()
        .join("\n");
    assert_eq!(
        lines.trim(),
        golden.trim(),
        "{kernel}: exact original values and complete written index set"
    );
    let baseline = Parser::new(baseline.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let reference = volta_ptx_analysis::analyze(&baseline, Some("k"), cfg).unwrap();
    assert!(matches!(
        check_output_equivalence(
            actual,
            reference.symbolic_outputs().unwrap(),
            &["out".into()]
        )
        .unwrap(),
        EquivOutcome::Equivalent
    ));
}
#[test]
fn b16_shift_amount_is_read_as_u32() {
    check(
        "exact_b16_shift_count_u32",
        include_str!("ptx/success/b16_shift_amount_is_read_as_u32.ptx"),
        include_str!("ptx/success/b16_shift_amount_is_read_as_u32.out"),
        "io",
        4,
        3,
    );
}
#[test]
fn b64_shift_by_u32_register() {
    check(
        "exact_b64_shift_u32",
        include_str!("ptx/success/b64_shift_by_u32_register.ptx"),
        include_str!("ptx/success/b64_shift_by_u32_register.out"),
        "io",
        8,
        2,
    );
}
#[test]
fn bfe_extract_and_sign_fill() {
    check(
        "exact_bfe_clipping",
        include_str!("ptx/success/bfe_extract_and_sign_fill.ptx"),
        include_str!("ptx/success/bfe_extract_and_sign_fill.out"),
        "out",
        4,
        4,
    );
}
#[test]
fn bfi_clips_field_to_register_width() {
    check(
        "exact_bfi_clipping",
        include_str!("ptx/success/bfi_clips_field_to_register_width.ptx"),
        include_str!("ptx/success/bfi_clips_field_to_register_width.out"),
        "out",
        4,
        4,
    );
}
#[test]
fn clusterlaunchcontrol_declined_cancel_ends_the_persistent_loop() {
    check(
        "exact_declined_cancel_one_pass",
        include_str!(
            "ptx/success/clusterlaunchcontrol_declined_cancel_ends_the_persistent_loop.ptx"
        ),
        include_str!(
            "ptx/success/clusterlaunchcontrol_declined_cancel_ends_the_persistent_loop.out"
        ),
        "tile",
        4,
        64,
    );
}
#[test]
fn int_abs_read_at_signed_width() {
    check(
        "exact_int_abs_signed_width",
        include_str!("ptx/success/int_abs_read_at_signed_width.ptx"),
        include_str!("ptx/success/int_abs_read_at_signed_width.out"),
        "io",
        4,
        2,
    );
}
#[test]
fn load_s8_sign_extends() {
    check(
        "exact_load_s8_sign_extends",
        include_str!("ptx/success/load_s8_sign_extends.ptx"),
        include_str!("ptx/success/load_s8_sign_extends.out"),
        "scratch",
        4,
        2,
    );
}
#[test]
fn load_s8_sign_extends_2() {
    check(
        "exact_load_s8_direct_minus_one",
        include_str!("ptx/success/load_s8_sign_extends_2.ptx"),
        include_str!("ptx/success/load_s8_sign_extends_2.out"),
        "scratch",
        4,
        2,
    );
}
#[test]
fn mov_neg1_vs_not_zero() {
    check(
        "exact_mov_minus_one",
        include_str!("ptx/success/mov_neg1_vs_not_zero.ptx"),
        include_str!("ptx/success/mov_neg1_vs_not_zero.out"),
        "out",
        4,
        1,
    );
}
#[test]
fn mov_neg1_vs_not_zero_2() {
    check(
        "exact_not_zero",
        include_str!("ptx/success/mov_neg1_vs_not_zero_2.ptx"),
        include_str!("ptx/success/mov_neg1_vs_not_zero_2.out"),
        "out",
        4,
        1,
    );
}
#[test]
fn mul_hi_u32_negative_operand() {
    check(
        "exact_mul_high_u32",
        include_str!("ptx/success/mul_hi_u32_negative_operand.ptx"),
        include_str!("ptx/success/mul_hi_u32_negative_operand.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn mul_wide_u16_magic_division() {
    check(
        "exact_mul_wide_u16",
        include_str!("ptx/success/mul_wide_u16_magic_division.ptx"),
        include_str!("ptx/success/mul_wide_u16_magic_division.out"),
        "io",
        4,
        2,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_add_s32_neg1() {
    check(
        "exact_ring_add_s32_neg1",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_add_s32_neg1.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_add_s32_neg1.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_add_u32_neg1() {
    check(
        "exact_ring_add_u32_neg1",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_add_u32_neg1.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_add_u32_neg1.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_sub_s32_neg7() {
    check(
        "exact_ring_sub_s32_neg7",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_sub_s32_neg7.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_sub_s32_neg7.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_sub_u32_neg7() {
    check(
        "exact_ring_sub_u32_neg7",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_sub_u32_neg7.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_sub_u32_neg7.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_sub_u32_1() {
    check(
        "exact_ring_sub_u32_1",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_sub_u32_1.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_sub_u32_1.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_mul_lo_s32_neg3() {
    check(
        "exact_ring_mul_s32_neg3",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_mul_lo_s32_neg3.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_mul_lo_s32_neg3.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn ring_op_constant_signedness_is_irrelevant_mul_lo_u32_neg3() {
    check(
        "exact_ring_mul_u32_neg3",
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_mul_lo_u32_neg3.ptx"),
        include_str!("ptx/success/ring_op_constant_signedness_is_irrelevant_mul_lo_u32_neg3.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn setp_selp_canonicalize_operands() {
    check(
        "exact_select_minus_one",
        include_str!("ptx/success/setp_selp_canonicalize_operands.ptx"),
        include_str!("ptx/success/setp_selp_canonicalize_operands.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn setp_selp_canonicalize_operands_2() {
    check(
        "exact_select_complement",
        include_str!("ptx/success/setp_selp_canonicalize_operands_2.ptx"),
        include_str!("ptx/success/setp_selp_canonicalize_operands_2.out"),
        "io",
        4,
        1,
    );
}
#[test]
fn shf_clamp_negative_shift_amount_saturates() {
    check(
        "exact_funnel_clamp_wrap",
        include_str!("ptx/success/shf_clamp_negative_shift_amount_saturates.ptx"),
        include_str!("ptx/success/shf_clamp_negative_shift_amount_saturates.out"),
        "io",
        4,
        4,
    );
}
#[test]
fn store_u8_truncates_to_low_bits() {
    check(
        "exact_store_u8_truncates",
        include_str!("ptx/success/store_u8_truncates_to_low_bits.ptx"),
        include_str!("ptx/success/store_u8_truncates_to_low_bits.out"),
        "scratch",
        4,
        2,
    );
}
#[test]
fn unsigned_sub_register_load_passes_through() {
    check(
        "exact_unsigned_byte_identity",
        include_str!("ptx/success/unsigned_sub_register_load_passes_through.ptx"),
        include_str!("ptx/success/unsigned_sub_register_load_passes_through.out"),
        "scratch",
        4,
        2,
    );
}
#[test]
fn vector_store_with_immediate_source() {
    check(
        "exact_vector_immediates",
        include_str!("ptx/success/vector_store_with_immediate_source.ptx"),
        include_str!("ptx/success/vector_store_with_immediate_source.out"),
        "io",
        4,
        4,
    );
}

fn scalar_source(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
k:
s_load_b128 s[4:7],s[0:1],0
s_wait_kmcnt 0
v_mov_b32 v0,0
s_load_b32 s8,s[4:5],0
s_wait_kmcnt 0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: input
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}

#[test]
fn symbolic_salu_conditions_select_data_but_never_control_carry_or_addresses() {
    for body in [
        "s_cmp_eq_u32 s8,-1\ns_cbranch_scc1 done\ns_mov_b32 s9,1\ndone:\nv_mov_b32 v1,1\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]",
        "s_cmp_eq_u32 s8,-1\ns_add_co_ci_u32 s9,0,0",
        "s_cmp_eq_u32 s8,-1\ns_cselect_b32 s9,-1,0\ns_mov_b32 exec_lo,s9",
        "s_cmp_eq_u32 s8,-1\ns_cselect_b32 s9,-1,0\ns_mov_b32 s6,s9\nv_mov_b32 v1,1\nglobal_store_b32 v0,v1,s[6:7]",
        "s_add_co_i32 s8,s8,-1\ns_cselect_b32 s9,1,0",
    ] {
        let source = scalar_source(body);
        let module = frontend::parse(&source).unwrap();
        let run = native_common::check(&source, &module, Some("k"), config("io", 4, 1)).unwrap();
        let error = run.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("symbolic") || error.contains("uninitialized SCC"),
            "{body}: {error}"
        );
        assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
    }
}

#[test]
fn explicit_scc_register_escape_is_rejected_by_native_syntax() {
    assert!(frontend::parse(&scalar_source("s_cmp_eq_u32 s8,-1\ns_mov_b32 s9,scc")).is_err());
}

#[test]
fn symbolic_scalar_multiply_preserves_prior_scc_without_inventing_overflow() {
    let source = scalar_source(
        "s_cmp_eq_u32 1,1\ns_mul_i32 s8,-3,s8\ns_cselect_b32 s9,1,0\nv_mov_b32 v1,s9\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]",
    );
    let module = frontend::parse(&source).unwrap();
    let run = native_common::check(&source, &module, Some("k"), config("io", 4, 1)).unwrap();
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let out = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(out.outputs[0].1.len(), 1);
    assert_eq!(out.arena.as_int_const(out.outputs[0].1[0].1), Some(1));
}

#[test]
fn readfirstlane_uses_the_lowest_active_lane_and_retains_pending_load_dependencies() {
    let source=scalar_source("s_mov_b32 exec_lo,4\nv_readfirstlane_b32 s9,v0\ns_mov_b32 exec_lo,1\nv_mov_b32 v1,s9\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]").replace("v_mov_b32 v0,0","v_mov_b32 v2,0").replace("global_store_b32 v0,v1","global_store_b32 v2,v1");
    let module = frontend::parse(&source).unwrap();
    let mut cfg = config("io", 4, 1);
    cfg.block_dim = (4, 1, 1);
    let run = native_common::check(&source, &module, Some("k"), cfg).unwrap();
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let out = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(out.arena.as_int_const(out.outputs[0].1[0].1), Some(2));
    let source = scalar_source(
        "global_load_b32 v1,v0,s[4:5]\nv_readfirstlane_b32 s9,v1\nv_mov_b32 v1,s9\nv_add_nc_u32 v1,0,v1\nglobal_store_b32 v0,v1,s[6:7]",
    );
    let module = frontend::parse(&source).unwrap();
    let run = native_common::check(&source, &module, Some("k"), config("io", 4, 1)).unwrap();
    assert!(run.analysis.symbolic_outputs().is_ok());
    assert!(matches!(
        run.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    assert!(format!("{:?}", run.checks).contains("ReadBeforeReady"));
}

#[test]
fn paired_signed_max_uses_preissue_values_and_its_pinned_y_slot() {
    let source = scalar_source(
        "v_mov_b32 v0,0x80000000\nv_mov_b32 v2,-5\nv_dual_mov_b32 v0,0 :: v_dual_max_i32 v2,v2,v0\nv_add_nc_u32 v2,0,v2\nglobal_store_b32 v0,v2,s[6:7]",
    );
    let module = frontend::parse(&source).unwrap();
    let run = native_common::check(&source, &module, Some("k"), config("io", 4, 1)).unwrap();
    assert_eq!(
        run.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        run.checks
    );
    let out = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(
        out.arena.as_int_const(out.outputs[0].1[0].1),
        Some(4294967291)
    );
    for bad in [
        "v_dual_max_i32 v0,v2,v3 :: v_dual_mov_b32 v2,0",
        "v_dual_mov_b32 v0,0 :: v_dual_max_i32 v2,v2,-v0",
        "v_dual_mov_b32 v0,0 :: v_dual_max_i32 v2,s8,v0",
    ] {
        assert!(frontend::parse(&scalar_source(bad)).is_err(), "{bad}");
    }
}
