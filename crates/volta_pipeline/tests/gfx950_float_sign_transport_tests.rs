//! Public compiler float-sign idioms preserve the existing real-arithmetic contract.
mod gfx950_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_expr::SymbolicOutputs;
use volta_graph_check::GraphConclusion;

const FLOAT_OPS: &str = include_str!("../../volta_amd_analysis/tests/fixtures/float_ops.s");

fn array(name: &str, base: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: 4,
        len,
        kind,
    }
}

/// Independently transcribe the 21 assignments in float_ops.cl. The 11 unwritten
/// slots in each 32-float row remain allocated, but are absent from the footprint.
fn expected_float_ops() -> SymbolicOutputs {
    let mut expected = SymbolicOutputs::default();
    let arena = &mut expected.arena;
    let a = arena.intern_string("a");
    let b = arena.intern_string("b");
    let numerator = arena.int(8_388_608);
    let denominator = arena.int(12_102_203);
    let ln2 = arena.div(numerator, denominator);
    let two = arena.int(2);
    let mut outputs = Vec::new();
    for lane in 0..64 {
        let x = arena.input_element(a, lane);
        let y = arena.input_element(b, lane);
        let neg = arena.neg(x);
        let abs = arena.abs(x);
        let sqrt = arena.sqrt(x);
        let rsq = arena.rcp(sqrt);
        let scaled = arena.mul(x, ln2);
        let exp2 = arena.exp(scaled);
        let log = arena.log(x);
        let log2 = arena.div(log, ln2);
        let reciprocal = arena.rcp(x);
        let add = arena.add(x, y);
        let sub = arena.sub(x, y);
        let mul = arena.mul(x, y);
        let reciprocal_y = arena.rcp(y);
        let div = arena.mul(x, reciprocal_y);
        let min = arena.min(x, y);
        let max = arena.max(x, y);
        let fma = arena.fma(x, y, x);
        let lt = arena.lt(x, y);
        let select_lt = arena.select(lt, x, two);
        let gt = arena.gt(x, y);
        let select_gt = arena.select(gt, x, mul);
        let le = arena.le(x, y);
        let select_le = arena.select(le, x, mul);
        let ge = arena.ge(x, y);
        let select_ge = arena.select(ge, x, mul);
        let eq = arena.eq(x, y);
        let select_eq = arena.select(eq, x, mul);
        let ne = arena.ne(x, y);
        let select_ne = arena.select(ne, x, mul);
        let negative_abs = arena.neg(abs);
        for (column, expression) in [
            neg,
            abs,
            sqrt,
            rsq,
            exp2,
            log2,
            reciprocal,
            add,
            sub,
            mul,
            div,
            min,
            max,
            fma,
            select_lt,
            select_gt,
            select_le,
            select_ge,
            select_eq,
            select_ne,
            negative_abs,
        ]
        .into_iter()
        .enumerate()
        {
            outputs.push((32 * lane + column as u64, expression));
        }
    }
    expected.outputs.push(("out".into(), outputs));
    expected
}

#[test]
fn unchanged_float_ops_proves_all_1344_writes_and_preserves_row_holes() {
    let module = frontend::parse(FLOAT_OPS).unwrap();
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("a", 0x10000, 64, ArrayKind::Input),
        array("b", 0x20000, 64, ArrayKind::Input),
        array("out", 0x30000, 2048, ArrayKind::Output),
    ];
    config.params = ["a", "b", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    let checked = gfx950_common::check(FLOAT_OPS, &module, Some("float_ops"), config).unwrap();
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    assert_eq!(actual.outputs.len(), 1);
    assert_eq!(actual.outputs[0].1.len(), 1344);
    for lane in 0..64 {
        for column in 0..32 {
            assert_eq!(
                actual.element("out", 32 * lane + column).is_some(),
                column < 21
            );
        }
    }
    assert!(matches!(
        check_output_equivalence(actual, &expected_float_ops(), &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

fn source(body: &str, target: &str) -> String {
    let (load, wait, wave) = if target == "gfx950" {
        ("s_load_dwordx4", "s_waitcnt lgkmcnt(0)", "")
    } else {
        (
            "s_load_b128",
            "s_wait_kmcnt 0",
            ".amdhsa_wavefront_size32 1",
        )
    };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
{load} s[4:7],s[0:1],0
{wait}
v_mov_b32 v0,0
{body}
s_endpgm
.size k,.-k
.amdhsa_kernel k
{wave}
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

fn run(body: &str, len: u64, target: &str) -> gfx950_common::Checked {
    let source = source(body, target);
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        array("input", 0x10000, 1, ArrayKind::Input),
        array("out", 0x20000, len, ArrayKind::Output),
    ];
    config.params = ["input", "out"]
        .map(|name| ParamValue::ArrayPtr(name.into()))
        .into();
    gfx950_common::check(&source, &module, Some("k"), config).unwrap()
}

fn memory_ops(target: &str) -> (&'static str, &'static str, &'static str) {
    if target == "gfx950" {
        (
            "global_load_dword v1,v0,s[4:5]",
            "s_waitcnt vmcnt(0)",
            "global_store_dword",
        )
    } else {
        (
            "global_load_b32 v1,v0,s[4:5]",
            "s_wait_loadcnt 0",
            "global_store_b32",
        )
    }
}

fn expected_sign_chain(operations: &[&str], raw: bool) -> SymbolicOutputs {
    let mut expected = SymbolicOutputs::default();
    let arena = &mut expected.arena;
    let input = arena.intern_string("input");
    let mut expression = arena.input_element(input, 0);
    for operation in operations {
        expression = if raw {
            let mask = arena.int(if *operation == "and" {
                0x7fff_ffff
            } else {
                0x8000_0000
            });
            match *operation {
                "and" => arena.bit_and(expression, mask),
                "or" => arena.bit_or(expression, mask),
                _ => arena.bit_xor(expression, mask),
            }
        } else {
            match *operation {
                "and" => arena.abs(expression),
                "or" => {
                    let absolute = arena.abs(expression);
                    arena.neg(absolute)
                }
                _ => arena.neg(expression),
            }
        };
    }
    expected.outputs.push(("out".into(), vec![(0, expression)]));
    expected
}

#[test]
fn sign_logic_has_independent_raw_and_float_oracles_for_both_targets() {
    for target in ["gfx950", "gfx1250"] {
        let (load, wait, store) = memory_ops(target);
        for operations in [
            vec!["and"],
            vec!["or"],
            vec!["xor"],
            vec!["and", "or", "xor"],
            vec!["or", "and", "or"],
        ] {
            for interpretation in ["raw", "deferred", "known", "result"] {
                let prefix = match interpretation {
                    "known" => "v_add_f32 v3,0,v1",
                    "result" => "v_add_f32 v1,0,v1",
                    _ => "",
                };
                let mut body = format!("{load}\n{wait}\n{prefix}\n");
                for operation in &operations {
                    let mask = if *operation == "and" {
                        "0x7fffffff"
                    } else {
                        "0x80000000"
                    };
                    body.push_str(&format!("v_{operation}_b32_e32 v1,{mask},v1\n"));
                }
                if interpretation == "deferred" {
                    body.push_str("v_add_f32 v1,0,v1\n");
                }
                body.push_str(&format!("{store} v0,v1,s[6:7]"));
                let checked = run(&body, 1, target);
                assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
                let actual = checked.analysis.symbolic_outputs().unwrap();
                assert_eq!(actual.outputs[0].1.len(), 1);
                assert!(
                    matches!(
                        check_output_equivalence(
                            actual,
                            &expected_sign_chain(&operations, interpretation == "raw"),
                            &["out".into()]
                        )
                        .unwrap(),
                        EquivOutcome::Equivalent
                    ),
                    "{target} {operations:?} {interpretation}"
                );
            }
        }
    }
}

#[test]
fn integer_consumption_cannot_be_retyped_as_float_in_either_order() {
    for target in ["gfx950", "gfx1250"] {
        let (load, wait, store) = memory_ops(target);
        let integer_add = if target == "gfx950" {
            "v_add_u32"
        } else {
            "v_add_nc_u32"
        };
        for operation in ["and", "or", "xor"] {
            let mask = if operation == "and" {
                "0x7fffffff"
            } else {
                "0x80000000"
            };
            let transport = format!("v_{operation}_b32 v2,{mask},v1");
            for consumers in [
                format!("{store} v0,v2,s[6:7]\nv_add_f32 v3,0,v2"),
                format!("v_add_f32 v3,0,v2\n{store} v0,v2,s[6:7]"),
                format!("{integer_add} v3,0,v2\nv_add_f32 v3,0,v2"),
                format!("v_add_f32 v3,0,v2\n{integer_add} v3,0,v2"),
            ] {
                let checked = run(
                    &format!("{load}\n{wait}\n{transport}\n{consumers}"),
                    1,
                    target,
                );
                let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
                assert!(
                    error.contains("conflicting word interpretations"),
                    "{target}: {error}"
                );
            }
        }
    }
}

#[test]
fn sign_logic_preserves_flags_and_exec_skips_undefined_operands() {
    let (load, wait, store) = memory_ops("gfx950");
    let checked = run(
        &format!(
            "{load}\n{wait}\nv_add_f32 v1,0,v1\n\
             s_cmp_eq_u32 s4,s4\nv_cmp_eq_u32_e32 vcc,v0,v0\n\
             v_or_b32_e32 v1,0x80000000,v1\n\
             v_and_b32_e32 v1,0x7fffffff,v1\n\
             v_xor_b32_e32 v1,0x80000000,v1\n\
             s_cselect_b32 s8,7,11\nv_mov_b32 v2,s8\nv_add_u32 v2,0,v2\n\
             v_mov_b32 v5,17\nv_cndmask_b32_e32 v3,13,v5,vcc\nv_add_u32 v3,0,v3\n\
             v_add_f32 v4,2.0,2.0\ns_mov_b64 exec,0\n\
             v_or_b32_e32 v4,0x80000000,v99\ns_mov_b64 exec,1\n\
             {store} v0,v2,s[6:7]\n{store} v0,v3,s[6:7] offset:4\n\
             {store} v0,v4,s[6:7] offset:8"
        ),
        3,
        "gfx950",
    );
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), 3);
    for (index, expected) in [7, 17, 4].into_iter().enumerate() {
        assert_eq!(
            actual
                .arena
                .as_int_const(actual.element("out", index as u64).unwrap()),
            Some(expected)
        );
    }
}

#[test]
fn sign_logic_requires_load_readiness_even_with_known_float_provenance() {
    let (load, _, store) = memory_ops("gfx950");
    let checked = run(
        &format!("{load}\nv_add_f32 v3,0,v1\nv_or_b32_e32 v1,0x80000000,v1\n{store} v0,v1,s[6:7]"),
        1,
        "gfx950",
    );
    assert!(matches!(
        checked.checks.conclusion(),
        GraphConclusion::Rejected { .. }
    ));
    assert_eq!(
        checked.analysis.symbolic_outputs().unwrap().outputs[0]
            .1
            .len(),
        1
    );
}
