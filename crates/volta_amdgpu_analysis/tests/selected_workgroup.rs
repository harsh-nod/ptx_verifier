//! One selected group has concrete launch coordinates and an unchanged absolute footprint.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend};
use volta_expr::ExprNode;
use volta_graph::Assumption;

fn output_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.grid_dim = (8, 12, 14);
    config.workgroup_id = (7, 11, 13);
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 3,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn source(target: &str, body: &str, enabled: (u8, u8, u8)) -> String {
    let native = target == "gfx1250";
    let (load, wait) = if native {
        ("s_load_b64", "s_wait_kmcnt 0\ns_wait_xcnt 0")
    } else {
        ("s_load_dwordx2", "s_waitcnt lgkmcnt(0)")
    };
    let wave = if native {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
{load} s[8:9], s[0:1], 0
{wait}
{body}
s_endpgm
.size k, .-k
.amdhsa_kernel k
.amdhsa_kernarg_size 8
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_sgpr_workgroup_id_x {x}
.amdhsa_system_sgpr_workgroup_id_y {y}
.amdhsa_system_sgpr_workgroup_id_z {z}
{wave}
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .kernarg_segment_size: 8
    .args:
      - .name: out
        .size: 8
        .offset: 0
        .value_kind: global_buffer
        .address_space: global
...
.end_amdgpu_metadata
"#,
        x = enabled.0,
        y = enabled.1,
        z = enabled.2
    )
}

#[test]
fn enabled_cdna_group_axes_are_compact_and_leave_other_slots_uninitialized() {
    for target in ["gfx942", "gfx950"] {
        for (enabled, expected) in [
            ((1, 1, 1), vec![7, 11, 13]),
            ((0, 1, 1), vec![11, 13]),
            ((1, 0, 1), vec![7, 13]),
            ((0, 0, 1), vec![13]),
            ((1, 0, 0), vec![7]),
        ] {
            let mut body = String::new();
            for i in 0..expected.len() {
                body.push_str(&format!(
                    "v_mov_b32 v{}, s{}\nglobal_store_dword v0, v{}, s[8:9] offset:{}\n",
                    i + 1,
                    i + 2,
                    i + 1,
                    i * 4
                ));
            }
            let module = frontend::parse(&source(target, &body, enabled)).unwrap();
            let result = analyze(&module, Some("k"), output_config()).unwrap();
            let outputs = result.symbolic_outputs().unwrap();
            assert_eq!(outputs.outputs[0].1.len(), expected.len());
            for (index, value) in expected.iter().enumerate() {
                assert_eq!(
                    outputs
                        .arena
                        .as_int_const(outputs.element("out", index as u64).unwrap()),
                    Some(*value)
                );
            }
            assert_eq!(result.graph().provenance().workgroup_id, (7, 11, 13));
            assert!(
                result
                    .graph()
                    .provenance()
                    .assumes(Assumption::SingleWorkgroupAnalyzed)
            );
            assert!(
                !result
                    .graph()
                    .provenance()
                    .assumes(Assumption::SingleCtaAnalyzed)
            );
            assert!(result.graph().dump().contains("workgroup 7,11,13"));
            let free = expected.len() + 2;
            let module =
                frontend::parse(&source(target, &format!("s_mov_b32 s12, s{free}"), enabled))
                    .unwrap();
            let result = analyze(&module, Some("k"), output_config()).unwrap();
            assert!(result.symbolic_outputs().is_err(), "{target}/{enabled:?}");
        }
    }
}

#[test]
fn gfx1250_packs_group_yz_and_preserves_local_wave_state_and_undefined_bits() {
    let body = "s_and_b32 s2, ttmp7, 65535\ns_lshr_b32 s3, ttmp7, 16\nv_mov_b32 v1, ttmp9\nv_mov_b32 v2, s2\nv_mov_b32 v3, s3\nglobal_store_b32 v0, v1, s[8:9]\nglobal_store_b32 v0, v2, s[8:9] offset:4\nglobal_store_b32 v0, v3, s[8:9] offset:8\ns_wait_storecnt 0\ns_wait_xcnt 0";
    let module = frontend::parse(&source("gfx1250", body, (1, 1, 1))).unwrap();
    for selection in [(7, 11, 13), (u32::MAX - 1, 65535, 65535)] {
        let mut config = output_config();
        config.grid_dim = (u32::MAX, 65536, 65536);
        config.workgroup_id = selection;
        let result = analyze(&module, Some("k"), config).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        for (index, value) in [selection.0, selection.1, selection.2]
            .into_iter()
            .enumerate()
        {
            assert_eq!(
                outputs
                    .arena
                    .as_int_const(outputs.element("out", index as u64).unwrap()),
                Some(i64::from(value))
            );
        }
    }
    for selection in [(0, 65536, 0), (0, 0, 65536)] {
        let mut config = output_config();
        config.grid_dim = (1, 65537, 65537);
        config.workgroup_id = selection;
        assert!(
            analyze(&module, Some("k"), config)
                .unwrap_err()
                .to_string()
                .contains("16-bit")
        );
    }
    for read in [
        "v_mov_b32 v1, ttmp6\nglobal_store_b32 v0, v1, s[8:9]",
        "v_mov_b32 v1, ttmp8\nglobal_store_b32 v0, v1, s[8:9]",
    ] {
        let module = frontend::parse(&source("gfx1250", read, (0, 0, 0))).unwrap();
        let result = analyze(&module, Some("k"), output_config()).unwrap();
        assert!(result.symbolic_outputs().is_err(), "{read}");
    }
}

#[test]
fn genuine_compiler_copy_keeps_absolute_selected_tile_indices() {
    for (target, source) in [
        (
            "gfx942",
            include_str!("../src/frontend/fixtures/clang22-copy-add.s")
                .replace("--gfx950", "--gfx942"),
        ),
        (
            "gfx950",
            include_str!("../src/frontend/fixtures/clang22-copy-add.s").into(),
        ),
        (
            "gfx1250",
            include_str!("../../../tests/gfx1250/fixtures/native-copy-add.s").into(),
        ),
    ] {
        let module = frontend::parse(&source).unwrap();
        let mut config = AnalysisConfig::new((64, 1, 1));
        config.grid_dim = (3, 1, 1);
        config.workgroup_id = (1, 0, 0);
        for (name, base, kind) in [
            ("x", 0x10000, ArrayKind::Input),
            ("out", 0x20000, ArrayKind::Output),
        ] {
            config.arrays.push(ArrayDef {
                name: name.into(),
                base,
                elem_width: 4,
                len: 192,
                kind,
            });
            config.params.push(ParamValue::ArrayPtr(name.into()));
        }
        config.params.push(ParamValue::Int(192));
        let result = analyze(&module, Some("copy"), config).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(
            outputs.outputs[0]
                .1
                .iter()
                .map(|(index, _)| *index)
                .collect::<Vec<_>>(),
            (64..128).collect::<Vec<_>>(),
            "{target}"
        );
        for &(index, expression) in &outputs.outputs[0].1 {
            assert!(
                matches!(outputs.arena.node(expression), ExprNode::InputElement { array, index: source } if outputs.arena.string(*array)=="x" && *source==index)
            );
        }
        let parsed =
            volta_spec::parse_spec("dim N; array x[N]; array out[N]; out[i]=x[i];").unwrap();
        let (_, specs) = volta_spec::instantiate(
            &parsed,
            &std::collections::HashMap::from([("N".into(), 192)]),
        )
        .unwrap();
        let mismatch = volta_spec::output_index_mismatch(outputs, &specs)
            .unwrap()
            .unwrap();
        assert_eq!(mismatch.unwritten.len(), 128);
        assert!(mismatch.unexpected.is_empty());
        let mut encoded = Vec::new();
        volta_expr::text::write_text(&mut encoded, outputs).unwrap();
        let restored = volta_expr::text::read_text(std::str::from_utf8(&encoded).unwrap()).unwrap();
        assert_eq!(
            restored.outputs[0]
                .1
                .iter()
                .map(|(index, _)| *index)
                .collect::<Vec<_>>(),
            (64..128).collect::<Vec<_>>()
        );
    }
}

#[test]
fn three_dimensional_selected_coordinates_do_not_change_local_ids() {
    let module =
        frontend::parse(include_str!("../src/frontend/fixtures/clang22-ids-3d.s")).unwrap();
    let mut config = AnalysisConfig::new((4, 3, 2));
    config.grid_dim = (2, 3, 4);
    config.workgroup_id = (1, 2, 3);
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 24,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    let result = analyze(&module, Some("ids_3d"), config).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    for z in 0..2 {
        for y in 0..3 {
            for x in 0..4 {
                let index = x + 4 * (y + 3 * z);
                assert_eq!(
                    outputs
                        .arena
                        .as_int_const(outputs.element("out", index).unwrap()),
                    Some((x + 10 * y + 100 * z + 321000) as i64)
                );
            }
        }
    }
}

fn store_scalar(prologue: &str) -> String {
    format!(
        "{prologue}\nv_mov_b32 v1, s2\nglobal_store_b32 v0, v1, s[8:9]\ns_wait_storecnt 0\ns_wait_xcnt 0"
    )
}

#[test]
fn gfx1250_grid_yz_valid_follows_shader_enables_and_wave_ids_stay_local() {
    for (enabled, grid, selection, expected_yz, valid) in [
        ((0, 0, 0), (8, 12, 14), (7, 11, 13), None, 0),
        ((0, 1, 0), (1, 1, 1), (0, 0, 0), Some(0), 1),
        ((0, 1, 0), (8, 12, 14), (7, 11, 13), Some(11), 1),
        (
            (0, 0, 1),
            (8, 12, 14),
            (7, 11, 13),
            Some(11 | (13 << 16)),
            1,
        ),
    ] {
        for (prologue, expected) in [
            ("s_mov_b32 s2, ttmp7", expected_yz),
            ("s_bfe_u32 s2, ttmp8, 0x1001e", Some(valid)),
            ("s_bfe_u32 s2, ttmp8, 0x1001f", Some(0)),
            ("s_mov_b32 s2, ttmp9", Some(selection.0)),
        ] {
            let module =
                frontend::parse(&source("gfx1250", &store_scalar(prologue), enabled)).unwrap();
            let mut config = output_config();
            config.grid_dim = grid;
            config.workgroup_id = selection;
            let result = analyze(&module, Some("k"), config).unwrap();
            if let Some(expected) = expected {
                let outputs = result.symbolic_outputs().unwrap();
                assert_eq!(
                    outputs
                        .arena
                        .as_int_const(outputs.element("out", 0).unwrap()),
                    Some(i64::from(expected)),
                    "{enabled:?}/{prologue}"
                );
            } else {
                assert!(result.symbolic_outputs().is_err(), "{enabled:?}/{prologue}");
            }
        }
    }
    let body = "s_bfe_u32 s2, ttmp8, 0x50019\nv_lshlrev_b32 v0, 2, v0\nv_mov_b32 v1, s2\nglobal_store_b32 v0, v1, s[8:9]\ns_wait_storecnt 0\ns_wait_xcnt 0";
    let module = frontend::parse(&source("gfx1250", body, (0, 0, 0))).unwrap();
    let mut config = output_config();
    config.block_dim = (64, 1, 1);
    config.arrays[0].len = 64;
    let result = analyze(&module, Some("k"), config).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    for index in 0..64 {
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index).unwrap()),
            Some((index / 32) as i64)
        );
    }
}

#[test]
fn undefined_cluster_fallback_values_can_be_discarded_but_not_observed() {
    for prologue in [
        "s_bfe_u32 s2, ttmp6, 0x4000c",
        "s_and_b32 s2, ttmp6, 15\ns_add_co_i32 s2, s2, 1",
        "s_bfe_u32 s2, ttmp6, 0x4000c\ns_mul_i32 s2, ttmp9, s2",
        "s_lshr_b32 s2, ttmp6, 4",
        "s_lshl_b32 s2, ttmp6, 4",
        "s_sub_co_i32 s2, ttmp6, 1",
    ] {
        let body = store_scalar(&format!(
            "{prologue}\ns_getreg_b32 s4, hwreg(HW_REG_IB_STS2, 6, 4)\ns_cmp_eq_u32 s4, 0\ns_cselect_b32 s2, ttmp9, s2"
        ));
        let module = frontend::parse(&source("gfx1250", &body, (0, 0, 0))).unwrap();
        let result = analyze(&module, Some("k"), output_config()).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", 0).unwrap()),
            Some(7)
        );
        let module =
            frontend::parse(&source("gfx1250", &store_scalar(prologue), (0, 0, 0))).unwrap();
        let result = analyze(&module, Some("k"), output_config()).unwrap();
        assert!(result.symbolic_outputs().is_err(), "{prologue}");
    }
    for body in [
        "s_add_co_i32 s2, ttmp6, 1\ns_cbranch_scc1 .Ldone\n.Ldone:",
        "s_add_co_i32 s2, ttmp6, 1\nv_mov_b32 v0, s2\nv_mov_b32 v1, 7\nglobal_store_b32 v0, v1, s[8:9]",
        "s_bfe_u32 s2, ttmp8, 0x10000\ns_cbranch_scc1 .Ldone\n.Ldone:",
    ] {
        let module = frontend::parse(&source("gfx1250", body, (0, 0, 0))).unwrap();
        let result = analyze(&module, Some("k"), output_config()).unwrap();
        assert!(result.symbolic_outputs().is_err(), "{body}");
    }
    for prologue in [
        "s_lshr_b32 s2, ttmp6, 4\ns_and_b32 s2, s2, 0xf0000000",
        "s_lshl_b32 s2, ttmp6, 4\ns_and_b32 s2, s2, 15",
        "s_bfe_u32 s2, ttmp6, 0",
    ] {
        let module =
            frontend::parse(&source("gfx1250", &store_scalar(prologue), (0, 0, 0))).unwrap();
        let result = analyze(&module, Some("k"), output_config()).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", 0).unwrap()),
            Some(0)
        );
    }
}
