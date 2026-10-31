//! MOV transports ordered Values; immediate decoding must not coerce register pairs.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend,
};
use volta_equivalence::{EquivCheckOptions, EquivOutcome, check_output_equivalence_with};
use volta_expr::ExprNode;
use volta_graph_check::{GraphConclusion, check_graph};

fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}

fn checked(source: &str, kernel: &str, config: AnalysisConfig) -> AnalysisResult {
    let module = frontend::parse(source).unwrap();
    let result = analyze(&module, Some(kernel), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn safe(result: &AnalysisResult) {
    let report = check_graph(result.graph());
    assert_eq!(
        report.conclusion(),
        GraphConclusion::Verified,
        "{report:#?}"
    );
}

fn kernel(target: &str, body: &str, two_pointers: bool) -> String {
    let (load, wait, wave32) = if target == "gfx1250" {
        (
            if two_pointers {
                "s_load_b128"
            } else {
                "s_load_b64"
            },
            "s_wait_kmcnt 0",
            ".amdhsa_wavefront_size32 1",
        )
    } else {
        (
            if two_pointers {
                "s_load_dwordx4"
            } else {
                "s_load_dwordx2"
            },
            "s_waitcnt lgkmcnt(0)",
            "",
        )
    };
    let (pointer_regs, args, size) = if two_pointers {
        (
            "s[4:7]",
            "      - .name: x\n        .offset: 0\n        .size: 8\n        .value_kind: global_buffer\n      - .name: out\n        .offset: 8\n        .size: 8\n        .value_kind: global_buffer",
            16,
        )
    } else {
        (
            "s[4:5]",
            "      - .name: out\n        .offset: 0\n        .size: 8\n        .value_kind: global_buffer",
            8,
        )
    };
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
{load} {pointer_regs},s[0:1],0
{wait}
{body}
s_endpgm
.size k,.-k
.amdhsa_kernel k
{wave32}
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size {size}
.amdhsa_next_free_sgpr 16
.amdhsa_next_free_vgpr 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
{args}
...
.end_amdgpu_metadata
"#
    )
}

#[test]
fn ordered_symbolic_f64_halves_survive_scalar_pair_copies_and_whole_storage() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let (load, wait, store, finish) = if target == "gfx1250" {
            (
                "s_load_b64",
                "s_wait_kmcnt 0",
                "global_store_b64",
                "s_wait_storecnt 0\ns_wait_xcnt 0",
            )
        } else {
            (
                "s_load_dwordx2",
                "s_waitcnt lgkmcnt(0)",
                "global_store_dwordx2",
                "s_waitcnt vmcnt(0)",
            )
        };
        let body = format!(
            "{load} s[8:9],s[4:5],0\n{wait}\ns_mov_b64 s[10:11],s[8:9]\ns_mov_b64 s[8:9],s[10:11]\nv_mov_b32 v0,0\nv_mov_b32 v2,s8\nv_mov_b32 v3,s9\n{store} v0,v[2:3],s[6:7]\n{finish}"
        );
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays = vec![
            array("x", 0x10000, 8, 1, ArrayKind::Input),
            array("out", 0x20000, 8, 1, ArrayKind::Output),
        ];
        config.params = vec![
            ParamValue::ArrayPtr("x".into()),
            ParamValue::ArrayPtr("out".into()),
        ];
        let result = checked(&kernel(target, &body, true), "k", config.clone());
        safe(&result);
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs.len(), 1);
        assert_eq!(outputs.outputs[0].0, "out");
        assert_eq!(outputs.outputs[0].1.len(), 1);
        let root = outputs.element("out", 0).unwrap();
        let ExprNode::InputElement { array, index } = outputs.arena.node(root) else {
            panic!("MOV must preserve the original whole symbolic input");
        };
        assert_eq!(outputs.arena.string(*array), "x");
        assert_eq!(*index, 0);
        for corruption in [
            "s_mov_b32 s9,0",
            "s_mov_b32 s12,s8\ns_mov_b32 s8,s9\ns_mov_b32 s9,s12",
        ] {
            let corrupt = body.replace("v_mov_b32 v0,0", &format!("{corruption}\nv_mov_b32 v0,0"));
            let result = checked(&kernel(target, &corrupt, true), "k", config.clone());
            assert!(
                result.symbolic_outputs().is_err(),
                "mixed or reversed halves cannot become a whole-value proof"
            );
        }
    }
}

#[test]
fn copied_aperture_pair_remains_opaque_and_reaches_only_the_existing_shared_consumer() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let (ds, ds_wait, flat, flat_wait, store, finish) = if target == "gfx1250" {
            (
                "ds_store_b32",
                "s_wait_dscnt 0",
                "flat_load_b32 v4,v[2:3] scope:SCOPE_SYS",
                "s_wait_loadcnt_dscnt 0",
                "global_store_b32",
                "s_wait_storecnt 0\ns_wait_xcnt 0",
            )
        } else {
            (
                "ds_write_b32",
                "s_waitcnt lgkmcnt(0)",
                "flat_load_dword v4,v[2:3]",
                "s_waitcnt vmcnt(0) lgkmcnt(0)",
                "global_store_dword",
                "s_waitcnt vmcnt(0)",
            )
        };
        let integer = if target == "gfx1250" {
            "v_add_nc_u32"
        } else {
            "v_add_u32"
        };
        let body = format!(
            "s_mov_b64 s[8:9],src_shared_base\ns_mov_b64 s[10:11],s[8:9]\nv_mov_b64 v[2:3],s[10:11]\nv_mov_b32 v0,0\nv_mov_b32 v4,123\n{ds} v0,v4\n{ds_wait}\n{flat}\n{flat_wait}\n{integer} v4,0,v4\n{store} v0,v4,s[4:5]\n{finish}"
        );
        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays = vec![array("out", 0x10000, 4, 1, ArrayKind::Output)];
        config.params = vec![ParamValue::ArrayPtr("out".into())];
        config.dynamic_shared_bytes = 4;
        let result = checked(&kernel(target, &body, false), "k", config.clone());
        safe(&result);
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs.len(), 1);
        assert_eq!(outputs.outputs[0].1.len(), 1);
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", 0).unwrap()),
            Some(123)
        );
        for invalid in [
            body.replace(
                "v_mov_b64 v[2:3],s[10:11]",
                "s_cmp_eq_u32 s11,0\nv_mov_b64 v[2:3],s[10:11]",
            ),
            body.replace(
                "v_mov_b64 v[2:3],s[10:11]",
                "s_mov_b32 s11,0\nv_mov_b64 v[2:3],s[10:11]",
            ),
        ] {
            assert!(
                checked(&kernel(target, &invalid, false), "k", config.clone())
                    .symbolic_outputs()
                    .is_err()
            );
        }
    }
}

#[test]
fn genuine_compiler_call_keeps_code_word_copies_and_every_original_output() {
    const SOURCE: &str = include_str!("fixtures/device-calls/qualified-add1.s");
    const SPEC: &str = include_str!("fixtures/device-calls/qualified-add1.spec");
    let launch: serde_yaml::Value = serde_yaml::from_str(include_str!(
        "fixtures/device-calls/qualified-add1.launch.json"
    ))
    .unwrap();
    assert_eq!(launch["block"], serde_yaml::to_value([64, 1, 1]).unwrap());
    assert_eq!(launch["grid"], serde_yaml::to_value([1, 1, 1]).unwrap());
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![
        array("x", 0x10000, 4, 64, ArrayKind::Input),
        array("out", 0x20000, 4, 64, ArrayKind::Output),
    ];
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::ArrayPtr("x".into()),
    ];
    let copy = "s_mov_b64 s[28:29],s[30:31]\ns_mov_b64 s[30:31],s[28:29]\ns_setpc_b64 s[30:31]";
    assert_eq!(SOURCE.matches("s_setpc_b64 s[30:31]").count(), 1);
    for extra_copy in [false, true] {
        // Original source/launch stay intact; this additional transport control
        // retains the genuine helper and every original instruction/coordinate.
        let source = if extra_copy {
            SOURCE.replace("s_setpc_b64 s[30:31]", copy)
        } else {
            SOURCE.into()
        };
        let result = checked(&source, "qualified_leaf_add1_copy64", config.clone());
        safe(&result);
        assert_eq!(result.stats.instructions, if extra_copy { 23 } else { 21 });
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs.len(), 1);
        assert_eq!(
            outputs.outputs[0]
                .1
                .iter()
                .map(|(i, _)| *i)
                .collect::<Vec<_>>(),
            (0..64).collect::<Vec<_>>()
        );
        let spec = volta_spec::parse_spec(SPEC).unwrap();
        let (env, expressions) =
            volta_spec::instantiate(&spec, &std::collections::HashMap::from([("N".into(), 64)]))
                .unwrap();
        let reference = volta_spec::unfold(&expressions, &env, 0).unwrap();
        let proof = check_output_equivalence_with(
            outputs,
            &reference,
            &["out".into()],
            &EquivCheckOptions {
                sample: 0,
                verify_numeric: true,
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(proof.elements_total, 64);
        assert_eq!(proof.elements_checked, 64);
        assert!(matches!(proof.outcome, EquivOutcome::Equivalent));
    }
    let invalid = SOURCE.replace(
        "s_setpc_b64 s[30:31]",
        "s_mov_b64 s[30:31],0\ns_setpc_b64 s[30:31]",
    );
    assert!(
        checked(&invalid, "qualified_leaf_add1_copy64", config)
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("return address")
    );
}
