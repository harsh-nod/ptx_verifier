//! Public-API semantic controls for deferred initialization of configured inputs.
//! Expected values come from program writes and configured input identities.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, analyze, frontend,
};
use volta_expr::ExprNode;

#[derive(Clone, Copy)]
struct Ops {
    load: &'static str,
    store: &'static str,
    byte_store: &'static str,
    load_wait: &'static str,
    store_wait: &'static str,
    leader: &'static str,
    barrier: &'static str,
    wave: u32,
}
fn ops(target: &str) -> Ops {
    if target == "gfx1250" {
        Ops {
            load: "global_load_b32",
            store: "global_store_b32",
            byte_store: "global_store_b8",
            load_wait: "s_wait_loadcnt 0",
            store_wait: "s_wait_storecnt 0\ns_wait_xcnt 0",
            leader: "s_mov_b32 exec_lo,1",
            barrier: "s_barrier_signal -1\ns_barrier_wait -1",
            wave: 32,
        }
    } else {
        Ops {
            load: "global_load_dword",
            store: "global_store_dword",
            byte_store: "global_store_byte",
            load_wait: "s_waitcnt vmcnt(0)",
            store_wait: "s_waitcnt vmcnt(0)",
            leader: "s_mov_b64 exec,1",
            barrier: "s_barrier",
            wave: 64,
        }
    }
}
fn source(target: &str, body: &str) -> String {
    let wave = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n\
         s_mov_b32 s4,0x10000\ns_mov_b32 s5,0\ns_mov_b32 s6,0x20000\ns_mov_b32 s7,0\n\
         {body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n\
         .amdhsa_system_vgpr_workitem_id 0\n{wave}\n.end_amdhsa_kernel\n"
    )
}
fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}
fn run(target: &str, body: &str, block: u32, arrays: Vec<ArrayDef>) -> AnalysisResult {
    let module = frontend::parse(&source(target, body)).expect("selected native instruction forms");
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays = arrays;
    let result = analyze(&module, Some("k"), config).expect("valid finite launch");
    result
        .graph()
        .validate()
        .expect("structural graph contract");
    result
}
fn expect_int(result: &AnalysisResult, name: &str, index: u64, expected: i64) {
    let outputs = result
        .symbolic_outputs()
        .expect("complete execution outputs");
    assert_eq!(
        outputs
            .arena
            .as_int_const(outputs.element(name, index).unwrap()),
        Some(expected)
    );
}
fn coordinates(result: &AnalysisResult, name: &str) -> Vec<u64> {
    result
        .symbolic_outputs()
        .unwrap()
        .outputs
        .iter()
        .find(|(n, _)| n == name)
        .unwrap()
        .1
        .iter()
        .map(|(index, _)| *index)
        .collect()
}

#[test]
fn overwrite_before_first_read_is_observed_and_inputoutput_dirty_set_is_sparse() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let o = ops(target);
        // Read an untouched element, overwrite a different element, then read it back.
        let body = format!(
            "v_mov_b32 v0,8\n{} v3,v0,s[4:5]\n{}\n\
             v_mov_b32 v0,4\nv_add_u32 v1,11,0\n{} v0,v1,s[4:5]\n{}\n\
             {} v2,v0,s[4:5]\n{}\nv_mov_b32 v0,0\n{} v0,v2,s[6:7]\n{}",
            o.load, o.load_wait, o.store, o.store_wait, o.load, o.load_wait, o.store, o.store_wait,
        );
        let result = run(
            target,
            &body,
            1,
            vec![
                array("io", 0x10000, 4, 3, ArrayKind::InputOutput),
                array("out", 0x20000, 4, 1, ArrayKind::Output),
            ],
        );
        assert_eq!(coordinates(&result, "io"), vec![1], "{target}");
        assert_eq!(coordinates(&result, "out"), vec![0]);
        expect_int(&result, "io", 1, 11);
        expect_int(&result, "out", 0, 11);
    }
}

#[test]
fn first_partial_index_write_keeps_the_other_concrete_bytes() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let o = ops(target);
        // Index input element3 is integer3. Replacing byte1 by0xaa yields0xaa03.
        let body = format!(
            "v_mov_b32 v0,13\ns_mov_b32 s8,170\nv_add_u32 v1,s8,0\n{} v0,v1,s[4:5]\n{}\n\
             v_mov_b32 v0,12\n{} v2,v0,s[4:5]\n{}\nv_add_u32 v2,v2,0\n\
             v_mov_b32 v0,0\n{} v0,v2,s[6:7]\n{}",
            o.byte_store, o.store_wait, o.load, o.load_wait, o.store, o.store_wait,
        );
        let result = run(
            target,
            &body,
            1,
            vec![
                array("index", 0x10000, 4, 4, ArrayKind::IndexInput),
                array("out", 0x20000, 4, 1, ArrayKind::Output),
            ],
        );
        expect_int(&result, "out", 0, 0xaa03);
    }
}

#[test]
fn first_partial_write_cannot_turn_symbolic_f32_storage_into_concrete_bytes() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for byte in [0, 1, 3] {
            let o = ops(target);
            let body = format!(
                "v_mov_b32 v0,{byte}\nv_add_u32 v1,7,0\n{} v0,v1,s[4:5]\n{}",
                o.byte_store, o.store_wait,
            );
            let result = run(
                target,
                &body,
                1,
                vec![array("io", 0x10000, 4, 1, ArrayKind::InputOutput)],
            );
            assert!(
                result
                    .symbolic_outputs()
                    .unwrap_err()
                    .to_string()
                    .contains("partial overwrite of a symbolic granule"),
                "{target}/{byte}"
            );
        }
    }
}

#[test]
fn either_first_half_load_reconstructs_one_width8_input_identity() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for high_first in [false, true] {
            let o = ops(target);
            let mut body = String::new();
            for (register, offset) in if high_first {
                [(9, 4), (8, 0)]
            } else {
                [(8, 0), (9, 4)]
            } {
                body.push_str(&format!(
                    "v_mov_b32 v0,{offset}\n{} v{register},v0,s[4:5]\n{}\n",
                    o.load, o.load_wait
                ));
            }
            let store64 = if target == "gfx1250" {
                "global_store_b64"
            } else {
                "global_store_dwordx2"
            };
            body.push_str(&format!(
                "v_mov_b32 v0,0\n{store64} v0,v[8:9],s[6:7]\n{}",
                o.store_wait
            ));
            let result = run(
                target,
                &body,
                1,
                vec![
                    array("x", 0x10000, 8, 1, ArrayKind::Input),
                    array("out", 0x20000, 8, 1, ArrayKind::Output),
                ],
            );
            let out = result.symbolic_outputs().unwrap();
            let ExprNode::InputElement { array, index } =
                out.arena.node(out.element("out", 0).unwrap())
            else {
                panic!("{target}/{high_first}: width8 identity changed");
            };
            assert_eq!(out.arena.string(*array), "x");
            assert_eq!(*index, 0);
        }
    }
}

#[test]
fn first_one_word_overwrite_of_width8_input_is_not_resurrected_on_other_half_read() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for replaced_offset in [0, 4] {
            let o = ops(target);
            let mut body = format!(
                "v_mov_b32 v0,{replaced_offset}\nv_add_u32 v1,0,0\n{} v0,v1,s[4:5]\n{}\n",
                o.store, o.store_wait,
            );
            // Read the untouched word first. The changed word must still remain changed.
            let read_order = if replaced_offset == 0 {
                [(9, 4), (8, 0)]
            } else {
                [(8, 0), (9, 4)]
            };
            for (register, offset) in read_order {
                body.push_str(&format!(
                    "v_mov_b32 v0,{offset}\n{} v{register},v0,s[4:5]\n{}\n",
                    o.load, o.load_wait
                ));
            }
            let store64 = if target == "gfx1250" {
                "global_store_b64"
            } else {
                "global_store_dwordx2"
            };
            body.push_str(&format!(
                "v_mov_b32 v0,0\n{store64} v0,v[8:9],s[6:7]\n{}",
                o.store_wait
            ));
            let result = run(
                target,
                &body,
                1,
                vec![
                    array("x", 0x10000, 8, 1, ArrayKind::Input),
                    array("out", 0x20000, 8, 1, ArrayKind::Output),
                ],
            );
            assert!(
                result
                    .symbolic_outputs()
                    .unwrap_err()
                    .to_string()
                    .contains("64-bit output requires matching ordered words"),
                "{target}/{replaced_offset}"
            );
        }
    }
}

#[test]
fn another_wave_observes_published_overwrite_instead_of_an_initial_input() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let o = ops(target);
        let selector = if target == "gfx1250" {
            "v_cmp_lt_u32 vcc_lo,v0,32\ns_mov_b32 s8,vcc_lo"
        } else {
            "v_cmp_lt_u32 vcc,v0,64\ns_mov_b32 s8,vcc_lo"
        };
        let restore = if target == "gfx1250" {
            "s_mov_b32 exec_lo,-1"
        } else {
            "s_mov_b64 exec,-1"
        };
        let body = format!(
            "{selector}\ns_cmp_eq_u32 s8,0\ns_cbranch_scc1 .Lpublished\n\
             {}\nv_mov_b32 v0,4\nv_add_u32 v1,29,0\n{} v0,v1,s[4:5]\n{}\n\
             {restore}\n.Lpublished:\n{}\ns_cmp_eq_u32 s8,0\ns_cbranch_scc0 .Ldone\n\
             {}\nv_mov_b32 v0,4\n{} v2,v0,s[4:5]\n{}\n\
             v_mov_b32 v0,0\n{} v0,v2,s[6:7]\n{}\n.Ldone:",
            o.leader,
            o.store,
            o.store_wait,
            o.barrier,
            o.leader,
            o.load,
            o.load_wait,
            o.store,
            o.store_wait,
        );
        let result = run(
            target,
            &body,
            o.wave + 1,
            vec![
                array("io", 0x10000, 4, 3, ArrayKind::InputOutput),
                array("out", 0x20000, 4, 1, ArrayKind::Output),
            ],
        );
        assert_eq!(coordinates(&result, "io"), vec![1]);
        expect_int(&result, "io", 1, 29);
        expect_int(&result, "out", 0, 29);
    }
}

#[test]
fn numeric_format_claims_remain_per_array_across_distinct_lazy_first_indices() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for first_is_float in [false, true] {
            let o = ops(target);
            let first = if first_is_float {
                "v_add_f32 v2,v1,1.0"
            } else {
                "v_add_u32 v2,v1,1"
            };
            let second = if first_is_float {
                "v_add_u32 v2,v1,1"
            } else {
                "v_add_f32 v2,v1,1.0"
            };
            let body = format!(
                "v_mov_b32 v0,0\n{} v1,v0,s[4:5]\n{}\n{first}\n\
                 v_mov_b32 v0,4\n{} v1,v0,s[4:5]\n{}\n{second}",
                o.load, o.load_wait, o.load, o.load_wait,
            );
            let result = run(
                target,
                &body,
                1,
                vec![array("x", 0x10000, 4, 2, ArrayKind::Input)],
            );
            assert!(
                result
                    .symbolic_outputs()
                    .unwrap_err()
                    .to_string()
                    .contains("conflicting word interpretations"),
                "{target}/{first_is_float}"
            );
        }
    }
}

#[test]
fn adjacent_allocations_do_not_license_a_cross_boundary_transfer() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let load64 = if target == "gfx1250" {
            "global_load_b64"
        } else {
            "global_load_dwordx2"
        };
        let result = run(
            target,
            &format!("v_mov_b32 v0,0\n{load64} v[8:9],v0,s[4:5]"),
            1,
            vec![
                array("x", 0x10000, 4, 1, ArrayKind::Input),
                array("y", 0x10004, 4, 1, ArrayKind::Input),
            ],
        );
        assert!(
            result
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("out-of-bounds"),
            "{target}"
        );
    }
}

#[test]
fn output_only_storage_is_never_initialized_as_input() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let o = ops(target);
        let result = run(
            target,
            &format!("v_mov_b32 v0,0\n{} v1,v0,s[4:5]\n{}", o.load, o.load_wait),
            1,
            vec![array("out", 0x10000, 4, 1, ArrayKind::Output)],
        );
        assert!(
            result
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized byte"),
            "{target}"
        );
    }
}

#[test]
fn separate_input_arrays_keep_distinct_symbol_and_format_identity() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let o = ops(target);
        let body = format!(
            "s_mov_b32 s10,0x30000\ns_mov_b32 s11,0\nv_mov_b32 v0,0\n{} v1,v0,s[4:5]\n{}\n\
             v_add_f32 v2,v1,1.0\n{} v0,v2,s[10:11]\n{}\n\
             {} v1,v0,s[6:7]\n{}\nv_add_u32 v2,v1,1\n\
             {} v0,v2,s[10:11] offset:4\n{}",
            o.load, o.load_wait, o.store, o.store_wait, o.load, o.load_wait, o.store, o.store_wait,
        );
        let result = run(
            target,
            &body,
            1,
            vec![
                array("float_input", 0x10000, 4, 1, ArrayKind::Input),
                array("integer_input", 0x20000, 4, 1, ArrayKind::Input),
                array("out", 0x30000, 4, 2, ArrayKind::Output),
            ],
        );
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(coordinates(&result, "out"), vec![0, 1]);
        for (index, expected_name) in [(0, "float_input"), (1, "integer_input")] {
            let ExprNode::Add(a, b) = outputs.arena.node(outputs.element("out", index).unwrap())
            else {
                panic!("expected input plus one");
            };
            assert!([*a, *b].iter().any(|id| match outputs.arena.node(*id) {
                ExprNode::InputElement { array, index } =>
                    outputs.arena.string(*array) == expected_name && *index == 0,
                _ => false,
            }));
        }
    }
}
