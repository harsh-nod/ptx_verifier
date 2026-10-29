//! Exact portable computations from the upstream rebase, with explicit layout adapters.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::{ExprArena, ExprId, SymbolicOutputs};
use volta_graph_check::GraphConclusion;

const NATIVE: &str = include_str!("../../../tests/gfx1250/fixtures/native-upstream-adapters.s");
fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}
fn input(arena: &mut ExprArena, name: &str, index: u64) -> ExprId {
    let name = arena.intern_string(name);
    arena.input_element(name, index)
}
fn native_output(kernel: &str, config: AnalysisConfig) -> SymbolicOutputs {
    let module = frontend::parse(NATIVE).unwrap();
    let checked = native_common::check(NATIVE, &module, Some(kernel), config).unwrap();
    assert_eq!(
        checked.checks.conclusion(),
        GraphConclusion::Verified,
        "{:#?}",
        checked.checks
    );
    checked.analysis.into_parts().outputs.unwrap()
}
fn bf16_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((32, 1, 1));
    config.arrays = vec![
        array("a", 0x10000, 2, 256, ArrayKind::Input),
        array("b", 0x20000, 2, 128, ArrayKind::Input),
        array("out", 0x30000, 4, 4, ArrayKind::Output),
        array("native", 0x40000, 4, 256, ArrayKind::Output),
    ];
    config.params = ["a", "b", "native", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .to_vec();
    config
}

#[test]
fn bf16_m16n8k16_preserves_original_fragments_and_checks_all_padded_native_outputs() {
    let actual = native_output("bf16_m16n8k16_fragment_adapter", bf16_config());
    let mut arena = ExprArena::new();
    // Independently invert the PTX fragment assignment. Each lane loads four
    // packed A words and two packed B words before MMA. This is deliberately
    // the inverse enumeration, rather than the native source's gather formula.
    let mut a = vec![None; 256];
    let mut b = vec![None; 128];
    for lane in 0..32 {
        for register in 0..4 {
            for half in 0..2 {
                let row = lane / 4 + (register % 2) * 8;
                let k = (lane % 4) * 2 + (register / 2) * 8 + half;
                let slot = &mut a[row * 16 + k];
                assert!(slot.is_none());
                *slot = Some(input(
                    &mut arena,
                    "a",
                    (lane * 8 + register * 2 + half) as u64,
                ));
            }
        }
        for register in 0..2 {
            for half in 0..2 {
                let column = lane / 4;
                let k = (lane % 4) * 2 + register * 8 + half;
                let slot = &mut b[k * 8 + column];
                assert!(slot.is_none());
                *slot = Some(input(
                    &mut arena,
                    "b",
                    (lane * 4 + register * 2 + half) as u64,
                ));
            }
        }
    }
    assert!(a.iter().all(Option::is_some));
    assert!(b.iter().all(Option::is_some));
    let mut native = Vec::new();
    for row in 0..16 {
        for column in 0..16 {
            let mut sum = arena.int(0);
            if column < 8 {
                for k in 0..16 {
                    sum = arena.fma(a[row * 16 + k].unwrap(), b[k * 8 + column].unwrap(), sum);
                }
            }
            native.push(((row * 16 + column) as u64, sum));
        }
    }
    let original = vec![
        (0, native[0].1),
        (1, native[1].1),
        (2, native[128].1),
        (3, native[129].1),
    ];
    let expected = SymbolicOutputs {
        arena,
        outputs: vec![("native".into(), native), ("out".into(), original)],
    };
    for (name, elements) in &expected.outputs {
        let actual_elements = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
        assert_eq!(
            actual_elements.iter().map(|(i, _)| *i).collect::<Vec<_>>(),
            elements.iter().map(|(i, _)| *i).collect::<Vec<_>>()
        );
    }
    assert!(matches!(
        check_output_equivalence(&actual, &expected, &["out".into(), "native".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
    // Compare the four original assertion cells directly against the upstream
    // backend's actual fragment result as well as the independent full matrix.
    use volta_ptx_analysis::frontend::{ascii::AsAscii, parse::Parser};
    let source = include_str!("ptx/success/mma_bf16.ptx");
    let module = Parser::new(source.as_bytes().as_ascii_slice().unwrap())
        .parse_module()
        .unwrap();
    let mut baseline = bf16_config();
    baseline.arrays.retain(|a| a.name != "native");
    baseline.params = ["a", "b", "out"]
        .map(|n| ParamValue::ArrayPtr(n.into()))
        .to_vec();
    let baseline = volta_ptx_analysis::analyze(&module, Some("k"), baseline).unwrap();
    let baseline = baseline.symbolic_outputs().unwrap();
    assert!(matches!(
        check_output_equivalence(&actual, baseline, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn exact_magic_division_uses_high64_then_shift_then_u32_projection() {
    let magic = 0xaaaa_aaaa_aaaa_aaabu64;
    for (dividend, reciprocal) in [
        (10, magic),
        (0, magic),
        (u64::MAX, magic),
        (u64::MAX, u64::MAX),
        (1u64 << 63, magic),
    ] {
        let mut config = AnalysisConfig::new((1, 1, 1));
        config
            .arrays
            .push(array("out", 0x30000, 4, 1, ArrayKind::Output));
        config.params = vec![
            ParamValue::Int(dividend as i64),
            ParamValue::Int(reciprocal as i64),
            ParamValue::ArrayPtr("out".into()),
        ];
        let output = native_output("high64_division_projection", config);
        assert_eq!(output.outputs[0].1.len(), 1);
        assert_eq!(output.outputs[0].1[0].0, 0);
        let expected = (((u128::from(dividend) * u128::from(reciprocal)) >> 64) >> 1) as u32;
        assert_eq!(
            output.arena.as_int_const(output.outputs[0].1[0].1),
            Some(i64::from(expected))
        );
        if dividend == 10 {
            assert_eq!(expected, 3);
        }
    }
}

#[test]
fn copied_bf16_fragments_still_reject_conflicting_f16_interpretation() {
    let needle = "s_wait_loadcnt 0x0\n\tv_perm_b32 v2, 0, v2, 0x5040100";
    assert_eq!(NATIVE.matches(needle).count(), 1);
    let source = NATIVE.replacen(
        needle,
        "s_wait_loadcnt 0x0\n\tv_cvt_f32_f16 v18,v2\n\tv_perm_b32 v2, 0, v2, 0x5040100",
        1,
    );
    let module = frontend::parse(&source).unwrap();
    let checked = native_common::check(
        &source,
        &module,
        Some("bf16_m16n8k16_fragment_adapter"),
        bf16_config(),
    )
    .unwrap();
    let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(
        error.contains("conflicting word interpretations"),
        "{error}"
    );
    assert_ne!(checked.checks.conclusion(), GraphConclusion::Verified);
}

fn half_copy_source(body: &str) -> String {
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
global_load_b32 v1,v0,s[4:5]
s_wait_loadcnt 0
{body}
s_wait_storecnt 0
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
fn half_copy_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        array("input", 0x10000, 2, 2, ArrayKind::Input),
        array("out", 0x20000, 2, 2, ArrayKind::Output),
    ];
    config.params = ["input", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .to_vec();
    config
}

#[test]
fn bfi_copies_encoded_halves_without_changing_order_or_defining_unknown_halves() {
    for (mask, selected) in [(0xffffu32, 0), (0xffff0000, 1)] {
        let source = half_copy_source(&format!(
            "v_mov_b32 v2,0\nv_bfi_b32 v3,{mask},v1,v2\nglobal_store_b32 v0,v3,s[6:7]"
        ));
        let module = frontend::parse(&source).unwrap();
        let checked =
            native_common::check(&source, &module, Some("k"), half_copy_config()).unwrap();
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
        let actual = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(actual.outputs[0].1.len(), 2);
        for index in 0..2 {
            let value = actual.element("out", index).unwrap();
            if index == selected {
                assert!(
                    matches!(actual.arena.node(value), volta_expr::ExprNode::InputElement { array, index: i } if actual.arena.string(*array) == "input" && *i == index)
                );
            } else {
                assert_eq!(actual.arena.as_f64(value), Some(0.));
            }
        }
    }
    // The BFI mask selects only the low half from input; the base register's
    // uninitialized high half must remain unobservable, rather than become 0.
    for consumer in [
        "global_store_b32 v0,v3,s[6:7]",
        "v_perm_b32 v3,0,v3,0x03020302\nglobal_store_b32 v0,v3,s[6:7]",
    ] {
        let source = half_copy_source(&format!("v_bfi_b32 v3,0xffff,v1,v2\n{consumer}"));
        let module = frontend::parse(&source).unwrap();
        let checked =
            native_common::check(&source, &module, Some("k"), half_copy_config()).unwrap();
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("unknown half") || error.contains("partially initialized"),
            "{consumer}: {error}"
        );
    }
}
