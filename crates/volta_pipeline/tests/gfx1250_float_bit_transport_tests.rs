//! F32 sign transport is decoded only by a typed consumer; raw words remain integers.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
use volta_graph_check::GraphConclusion;

fn source(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.p2align 8
.globl k
.type k,@function
k:
s_load_b128 s[4:7],s[0:1],0
s_wait_kmcnt 0
v_mov_b32 v0,0
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

fn run(body: &str, width: u64, len: u64) -> native_common::Checked {
    let source = source(body);
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "input".into(),
            base: 0x10000,
            elem_width: 4,
            len: 2,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: width,
            len,
            kind: ArrayKind::Output,
        },
    ];
    config.params = vec![
        ParamValue::ArrayPtr("input".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    native_common::check(&source, &module, Some("k"), config).unwrap()
}

const INPUT: &str = "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0";
const XOR: &str = "v_xor_b32 v2,0x80000000,v1";
const STORE: &str = "global_store_b32 v0,v2,s[6:7]";

#[test]
fn typed_float_consumption_decodes_sign_bits_but_raw_xor_is_not_real_negation() {
    let reference = run(&format!("{INPUT}\nv_mul_f32_e64 v2,-1.0,v1\n{STORE}"), 4, 1);
    let decoded = run(&format!("{INPUT}\n{XOR}\nv_add_f32 v2,0,v2\n{STORE}"), 4, 1);
    let raw = run(&format!("{INPUT}\n{XOR}\n{STORE}"), 4, 1);
    for checked in [&reference, &decoded, &raw] {
        assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
        let outputs = checked.analysis.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 1);
        assert_eq!(outputs.outputs[0].1[0].0, 0);
    }
    let expected = reference.analysis.symbolic_outputs().unwrap();
    assert!(matches!(
        check_output_equivalence(
            decoded.analysis.symbolic_outputs().unwrap(),
            expected,
            &["out".into()]
        )
        .unwrap(),
        EquivOutcome::Equivalent
    ));
    assert!(matches!(
        check_output_equivalence(
            raw.analysis.symbolic_outputs().unwrap(),
            expected,
            &["out".into()]
        )
        .unwrap(),
        EquivOutcome::NotEquivalent { .. }
    ));
}

#[test]
fn mixed_raw_and_float_observation_of_the_same_input_is_rejected_in_either_order() {
    for body in [
        format!(
            "{INPUT}\n{XOR}\n{STORE}\nv_add_f32 v3,0,v2\nglobal_store_b32 v0,v3,s[6:7] offset:4"
        ),
        format!(
            "{INPUT}\n{XOR}\nv_add_f32 v3,0,v2\nglobal_store_b32 v0,v3,s[6:7] offset:4\n{STORE}"
        ),
        format!("{INPUT}\n{XOR}\nv_add_nc_u32 v3,0,v2\nv_add_f32 v2,0,v2\n{STORE}"),
    ] {
        let checked = run(&body, 4, 2);
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(
            error.contains("conflicting word interpretations"),
            "{error}"
        );
    }
}

#[test]
fn arbitrary_masks_and_modified_integer_operands_do_not_become_float_bitcasts() {
    for operation in ["v_xor_b32 v2,0x40000000,v1", "v_and_b32 v2,0x7ffffffe,v1"] {
        let checked = run(
            &format!("{INPUT}\n{operation}\nv_add_f32 v2,0,v2\n{STORE}"),
            4,
            1,
        );
        assert!(checked.analysis.symbolic_outputs().is_err());
    }
    let modified = run(
        &format!("{INPUT}\nv_xor_b32_e64 v2,0x80000000,-v1\nv_add_f32 v2,0,v2\n{STORE}"),
        4,
        1,
    );
    assert!(modified.analysis.symbolic_outputs().is_err());
}

#[test]
fn sign_bit_insert_and_abs_are_mathematical_only_after_float_consumption() {
    let checked = run(
        "global_load_b64 v[2:3],v0,s[4:5]\ns_wait_loadcnt 0\nv_bfi_b32 v4,0x80000000,v2,v3\nv_add_f32 v4,0,v4\nv_and_b32 v3,0x7fffffff,v3\nv_add_f32 v3,0,v3\nglobal_store_b32 v0,v4,s[6:7]\nglobal_store_b32 v0,v3,s[6:7] offset:4",
        4,
        2,
    );
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let actual = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), 2);
    let mut expected = actual.clone();
    let input = expected.arena.intern_string("input");
    let sign = expected.arena.input_element(input, 0);
    let magnitude = expected.arena.input_element(input, 1);
    let zero = expected.arena.int(0);
    let nonnegative = expected.arena.ge(sign, zero);
    let absolute = expected.arena.abs(magnitude);
    let negative = expected.arena.neg(absolute);
    let selected = expected.arena.select(nonnegative, absolute, negative);
    expected.outputs[0].1 = vec![(0, selected), (1, absolute)];
    assert!(matches!(
        check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        EquivOutcome::Equivalent
    ));
}

#[test]
fn widened_integer_pairs_require_the_low_word_to_match_the_saved_sign_extension() {
    let prelude = "v_mov_b32 v2,-8\nv_ashrrev_i32 v3,31,v2";
    let checked = run(
        &format!("{prelude}\nglobal_store_b64 v0,v[2:3],s[6:7]"),
        8,
        1,
    );
    assert_eq!(checked.checks.conclusion(), GraphConclusion::Verified);
    let out = checked.analysis.symbolic_outputs().unwrap();
    assert_eq!(out.outputs[0].1.len(), 1);
    assert_eq!(out.arena.as_int_const(out.outputs[0].1[0].1), Some(-8));
    for alteration in [
        "v_mov_b32 v2,-7",
        "v_mov_b32 v4,v2\nv_mov_b32 v2,v3\nv_mov_b32 v3,v4",
    ] {
        let checked = run(
            &format!("{prelude}\n{alteration}\nglobal_store_b64 v0,v[2:3],s[6:7]"),
            8,
            1,
        );
        let error = checked.analysis.symbolic_outputs().unwrap_err().to_string();
        assert!(error.contains("matching ordered words"), "{error}");
    }
    let checked = run(
        "v_mov_b32 v2,7\nv_mov_b32 v3,0\nglobal_store_b64 v0,v[2:3],s[6:7]",
        8,
        1,
    );
    assert!(checked.analysis.symbolic_outputs().is_err());
}
