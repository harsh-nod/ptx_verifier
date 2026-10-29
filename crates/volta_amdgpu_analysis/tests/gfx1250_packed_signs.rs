//! Arbitrary external-u32 packed signs, not an IndexInput substitution.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, analyze, frontend};

fn native(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
k:
s_load_b64 s[4:5], s[0:1], 0
s_wait_kmcnt 0
{body}
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
"#
    )
}

#[test]
fn packed_external_words_decode_all_thirty_two_sign_bits_without_index_input() {
    let mut body = String::from(
        "s_load_b64 s[6:7], s[0:1], 8\ns_wait_kmcnt 0\nv_mov_b32 v0, 0\nglobal_load_b32 v1, v0, s[6:7]\ns_wait_loadcnt 0\nv_mov_b32 v3, 0xbc00\n",
    );
    for bit in 0..32 {
        if bit == 31 {
            body += "v_cmp_lt_i32_e32 vcc_lo, -1, v1\n";
        } else {
            body += &format!(
                "v_and_b32_e32 v2, {}, v1\nv_cmp_eq_u32_e32 vcc_lo, 0, v2\n",
                1u32 << bit
            );
        }
        body += &format!(
            "v_cndmask_b32_e32 v2, 0x3c00, v3, vcc_lo\nv_cvt_f32_f16_e32 v2, v2\nglobal_store_b32 v0, v2, s[4:5] offset:{}\ns_wait_xcnt 0\ns_wait_storecnt 0\n",
            bit * 4
        );
    }
    let source = native(&body).replace(".amdhsa_kernarg_size 8", ".amdhsa_kernarg_size 16").replace(
        "        .value_kind: global_buffer\n", "        .value_kind: global_buffer\n      - .name: words\n        .offset: 8\n        .size: 8\n        .value_kind: global_buffer\n");
    let module = frontend::parse(&source).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "out".into(),
            base: 0x10000,
            elem_width: 4,
            len: 32,
            kind: ArrayKind::Output,
        },
        ArrayDef {
            name: "words".into(),
            base: 0x20000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Input,
        },
    ];
    config.params = vec![
        volta_amdgpu_analysis::ParamValue::ArrayPtr("out".into()),
        volta_amdgpu_analysis::ParamValue::ArrayPtr("words".into()),
    ];
    let analysis = analyze(&module, Some("k"), config).unwrap();
    let actual = analysis.symbolic_outputs().unwrap();
    assert_eq!(actual.outputs[0].1.len(), 32);
    let mut arena = volta_expr::ExprArena::new();
    let words = arena.intern_string("words");
    let word = arena.input_element(words, 0);
    let mut entries = Vec::new();
    for bit in 0..32 {
        let index = arena.int(bit);
        let shifted = arena.lshr(word, index);
        let one = arena.int(1);
        let selected = arena.bit_and(shifted, one);
        let zero = arena.int(0);
        let predicate = arena.ne(selected, zero);
        let minus_one = arena.int(-1);
        entries.push((bit as u64, arena.select(predicate, one, minus_one)));
    }
    let expected = volta_expr::SymbolicOutputs {
        arena,
        outputs: vec![("out".into(), entries)],
    };
    assert!(matches!(
        volta_equivalence::check_output_equivalence(actual, &expected, &["out".into()]).unwrap(),
        volta_equivalence::EquivOutcome::Equivalent
    ));
    analysis.graph().validate().unwrap();
}
