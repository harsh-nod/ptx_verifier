//! Independent finite FP8 byte oracles and exact source-selection obligations.
#[path = "gfx950_common/mod.rs"]
mod native_common;

use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph::AmdRegisterFile;
use volta_graph_check::GraphConclusion;
use volta_graph_check::amdgpu::AmdRegisterHazardKind;

fn source(body: &str) -> String {
    format!(
        r#".amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_load_b32 s6,s[0:1],8
s_wait_kmcnt 0
v_mov_b32 v0,0
{body}
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 12
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: bits
        .offset: 8
        .size: 4
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    )
}

fn config(bits: u32, threads: u32, outputs: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((threads, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: outputs,
        kind: ArrayKind::Output,
    });
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Int(i64::from(bits)),
    ];
    config
}

// Public binary exponent definitions, independent of the interpreter decoder.
fn reference(byte: u8, e5m2: bool) -> Option<f64> {
    let magnitude = if e5m2 {
        let exponent = (byte >> 2) & 31;
        let fraction = byte & 3;
        if exponent == 31 {
            return None;
        }
        if exponent == 0 {
            f64::from(fraction) * 2f64.powi(-16)
        } else {
            f64::from(4 + fraction) * 2f64.powi(i32::from(exponent) - 17)
        }
    } else {
        let exponent = (byte >> 3) & 15;
        let fraction = byte & 7;
        if exponent == 15 && fraction == 7 {
            return None;
        }
        if exponent == 0 {
            f64::from(fraction) * 2f64.powi(-9)
        } else {
            f64::from(8 + fraction) * 2f64.powi(i32::from(exponent) - 10)
        }
    };
    Some(if byte & 128 == 0 {
        magnitude
    } else {
        -magnitude
    })
}

#[test]
fn every_e4m3_and_e5m2_byte_decodes_independently_in_all_four_positions() {
    let mut finite = 0;
    let mut exceptional = 0;
    for (format, e5m2, poison) in [("fp8", false, 0x7f7f7f7fu32), ("bf8", true, 0x7c7c7c7c)] {
        for selected in 0..4 {
            let assembly = source(&format!(
                "v_cvt_f32_{format}_e64 v1,s6 byte_sel:{selected}\nglobal_store_b32 v0,v1,s[4:5]"
            ));
            let module = frontend::parse(&assembly).unwrap();
            for byte in 0..=255u8 {
                let word =
                    (poison & !(255 << (selected * 8))) | (u32::from(byte) << (selected * 8));
                let run = native_common::check(&assembly, &module, Some("k"), config(word, 1, 1))
                    .unwrap();
                let context = format!("{format}/byte{selected}/{byte:#04x}");
                if let Some(expected) = reference(byte, e5m2) {
                    finite += 1;
                    assert_eq!(
                        run.checks.conclusion(),
                        GraphConclusion::Verified,
                        "{context}: {:?}",
                        run.checks
                    );
                    let out = run.analysis.symbolic_outputs().unwrap();
                    assert_eq!(out.outputs.len(), 1, "{context}");
                    assert_eq!(out.outputs[0].0, "out");
                    assert_eq!(out.outputs[0].1.len(), 1, "{context}");
                    assert_eq!(out.outputs[0].1[0].0, 0, "{context}");
                    assert_eq!(
                        out.arena.as_f64(out.outputs[0].1[0].1),
                        Some(expected),
                        "{context}"
                    );
                } else {
                    exceptional += 1;
                    let error = run.analysis.symbolic_outputs().unwrap_err().to_string();
                    assert!(
                        error.contains("NaN") || error.contains("infinity"),
                        "{context}: {error}"
                    );
                    assert_ne!(
                        run.checks.conclusion(),
                        GraphConclusion::Verified,
                        "{context}"
                    );
                }
            }
        }
    }
    assert_eq!((finite, exceptional), (2008, 40));
}

#[test]
fn vector_source_aliases_snapshot_each_active_wave32_lane_and_preserve_unwritten_indices() {
    for (format, e5m2) in [("fp8", false), ("bf8", true)] {
        for selected in 0..4 {
            for mask in [u32::MAX, 0xaaaa_aaaa] {
                for alias in [false, true] {
                    let destination = if alias { "v1" } else { "v2" };
                    let assembly = source(&format!(
                        "v_add_nc_u32 v1,v0,0x30201000\ns_mov_b32 exec_lo,{mask}\n\
                         v_cvt_f32_{format}_e64 {destination},v1 byte_sel:{selected}\n\
                         v_lshlrev_b32 v0,2,v0\nglobal_store_b32 v0,{destination},s[4:5]"
                    ))
                    .replacen("v_mov_b32 v0,0\n", "", 1);
                    let module = frontend::parse(&assembly).unwrap();
                    let run =
                        native_common::check(&assembly, &module, Some("k"), config(0, 32, 32))
                            .unwrap();
                    assert_eq!(
                        run.checks.conclusion(),
                        GraphConclusion::Verified,
                        "{format}/{selected}/{mask:#x}/{alias}: {:?}",
                        run.checks
                    );
                    let out = run.analysis.symbolic_outputs().unwrap();
                    let expected_indices: Vec<_> =
                        (0u64..32).filter(|lane| mask & (1 << lane) != 0).collect();
                    assert_eq!(
                        out.outputs[0]
                            .1
                            .iter()
                            .map(|(index, _)| *index)
                            .collect::<Vec<_>>(),
                        expected_indices
                    );
                    for (index, expression) in &out.outputs[0].1 {
                        let raw = ((0x3020_1000 + *index as u32) >> (8 * selected)) as u8;
                        assert_eq!(
                            out.arena.as_f64(*expression),
                            reference(raw, e5m2),
                            "{format}/{selected}/{mask:#x}/{alias}/lane{index}"
                        );
                    }
                }
            }
        }
    }
}

#[test]
fn empty_exec_does_not_read_an_undefined_source_or_modify_scalar_flags() {
    for format in ["fp8", "bf8"] {
        let assembly = source(&format!(
            "s_mov_b32 vcc_lo,5\ns_cmp_eq_u32 s6,s6\ns_mov_b32 exec_lo,0\n\
             v_cvt_f32_{format}_e64 v1,v2 byte_sel:3\n\
             s_cselect_b32 s7,1,0\ns_mov_b32 s8,vcc_lo\ns_mov_b32 exec_lo,1\n\
             v_add_f32 v1,0,2.0\nv_add_nc_u32 v2,0,s7\nv_add_nc_u32 v3,0,s8\n\
             global_store_b32 v0,v1,s[4:5]\ns_wait_xcnt 0\n\
             global_store_b32 v0,v2,s[4:5] offset:4\ns_wait_xcnt 0\n\
             global_store_b32 v0,v3,s[4:5] offset:8"
        ));
        let module = frontend::parse(&assembly).unwrap();
        let run = native_common::check(&assembly, &module, Some("k"), config(0, 1, 3)).unwrap();
        assert_eq!(
            run.checks.conclusion(),
            GraphConclusion::Verified,
            "{:?}",
            run.checks
        );
        let out = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs[0].1.len(), 3);
        assert_eq!(out.arena.as_f64(out.element("out", 0).unwrap()), Some(2.0));
        for (index, expected) in [(1, 1), (2, 5)] {
            assert_eq!(
                out.arena.as_int_const(out.element("out", index).unwrap()),
                Some(expected)
            );
        }
    }
}

#[test]
fn bf8_source_readiness_requires_the_km_counter_and_keeps_numerical_results_separate() {
    for wait in [
        "s_wait_kmcnt 0",
        "s_wait_loadcnt 0",
        "s_wait_dscnt 0",
        "s_wait_asynccnt 0",
        "s_wait_xcnt 0",
    ] {
        let assembly = source("v_cvt_f32_bf8_e64 v1,s6 byte_sel:3\nglobal_store_b32 v0,v1,s[4:5]")
            .replace(
                "s_load_b32 s6,s[0:1],8\ns_wait_kmcnt 0",
                &format!("s_wait_kmcnt 0\ns_load_b32 s6,s[0:1],8\n{wait}"),
            );
        let module = frontend::parse(&assembly).unwrap();
        let run =
            native_common::check(&assembly, &module, Some("k"), config(0x3c00_0000, 1, 1)).unwrap();
        let out = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs[0].1.len(), 1);
        assert_eq!(out.arena.as_f64(out.element("out", 0).unwrap()), Some(1.0));
        if wait == "s_wait_kmcnt 0" {
            assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
        } else {
            assert!(
                matches!(run.checks.conclusion(), GraphConclusion::Rejected { .. }),
                "{wait}: {:?}",
                run.checks
            );
            let graph = run.analysis.graph();
            assert!(
                run.checks
                    .amd
                    .as_ref()
                    .unwrap()
                    .wait_readiness
                    .violations()
                    .iter()
                    .any(|hazard| {
                        hazard.kind == AmdRegisterHazardKind::ReadBeforeReady
                            && hazard.register.file == AmdRegisterFile::Scalar
                            && hazard.register.index == 6
                            && graph.event(hazard.issue).pc.unwrap().0 == 2
                            && graph.event(hazard.use_event).pc.unwrap().0 == 5
                    }),
                "{wait}: {:?}",
                run.checks
            );
        }
    }
}

#[test]
fn bf8_default_vop1_and_vop3_forms_and_explicit_masks_keep_selected_raw_bits() {
    for conversion in [
        "v_cvt_f32_bf8 v1,s6",
        "v_cvt_f32_bf8_e32 v1,s6",
        "v_cvt_f32_bf8_e64 v1,s6",
        "v_cvt_f32_bf8_e64 v1,s6 byte_sel:0",
        "v_cvt_f32_bf8_e64 v1,0x7c7c7c3c byte_sel:0",
    ] {
        let assembly = source(&format!("{conversion}\nglobal_store_b32 v0,v1,s[4:5]"));
        let module = frontend::parse(&assembly).unwrap();
        let run =
            native_common::check(&assembly, &module, Some("k"), config(0x7c7c7c3c, 1, 1)).unwrap();
        assert_eq!(
            run.checks.conclusion(),
            GraphConclusion::Verified,
            "{conversion}"
        );
        let out = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs[0].1.len(), 1);
        assert_eq!(out.arena.as_f64(out.element("out", 0).unwrap()), Some(1.0));
    }
    let assembly = source(
        "s_and_b32 s7,ttmp8,0xfe000000\nv_cvt_f32_bf8_e64 v1,s7 byte_sel:3\nglobal_store_b32 v0,v1,s[4:5]",
    );
    let module = frontend::parse(&assembly).unwrap();
    let run = native_common::check(&assembly, &module, Some("k"), config(0, 1, 1)).unwrap();
    assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
    let out = run.analysis.symbolic_outputs().unwrap();
    assert_eq!(out.arena.as_f64(out.element("out", 0).unwrap()), Some(0.0));
}

#[test]
fn bf8_selected_known_bits_do_not_define_or_retype_other_source_bits() {
    for selected in 0..4 {
        let assembly = source(&format!(
            "v_cvt_f32_bf8_e64 v1,ttmp8 byte_sel:{selected}\nglobal_store_b32 v0,v1,s[4:5]"
        ));
        let module = frontend::parse(&assembly).unwrap();
        let run = native_common::check(&assembly, &module, Some("k"), config(0, 1, 1)).unwrap();
        assert!(
            run.analysis.symbolic_outputs().is_err(),
            "partly undefined TTMP8 byte{selected}"
        );
        assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
        let symbolic = source(&format!(
            "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\nv_cvt_f32_bf8_e64 v1,v1 byte_sel:{selected}\nglobal_store_b32 v0,v1,s[4:5]"
        ));
        let module = frontend::parse(&symbolic).unwrap();
        let mut input = config(0, 1, 1);
        input.arrays[0].kind = ArrayKind::InputOutput;
        let run = native_common::check(&symbolic, &module, Some("k"), input).unwrap();
        assert!(
            run.analysis
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("symbolic E5M2 decoding is not modeled")
        );
        assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
    }
    let assembly = source(
        "v_add_f32 v1,0,1.0\nv_cvt_f32_bf8_e64 v1,v1 byte_sel:3\nglobal_store_b32 v0,v1,s[4:5]",
    );
    let module = frontend::parse(&assembly).unwrap();
    let run = native_common::check(&assembly, &module, Some("k"), config(0, 1, 1)).unwrap();
    assert!(
        run.analysis
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("symbolic E5M2 decoding is not modeled")
    );
    assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
}

#[test]
fn bf8_byte_selection_rejects_invalid_forms_and_caller_built_target_bypasses() {
    for instruction in [
        "v_cvt_f32_bf8_e32 v1,s6 byte_sel:1",
        "v_cvt_f32_bf8_e64 v1,s6 byte_sel:-1",
        "v_cvt_f32_bf8_e64 v1,s6 byte_sel:4",
        "v_cvt_f32_bf8_e64 v1,s6 byte_sel",
        "v_cvt_f32_bf8_e64 v1,s6 byte_sel:0 byte_sel:1",
        "v_cvt_f32_bf8_e64 v1,s6 clamp",
        "v_cvt_f32_bf8_e64 v1,-s6",
        "v_cvt_f32_bf8_e64 v1,s[6:7]",
        "v_cvt_f32_bf8_e64 v1,1.0",
        "v_cvt_f32_bf8_sdwa v1,s6 src0_sel:BYTE_1",
    ] {
        assert!(
            frontend::parse(&source(instruction)).is_err(),
            "{instruction}"
        );
    }
    let assembly = source("v_cvt_f32_bf8_e64 v1,s6 byte_sel:3");
    let module = frontend::parse(&assembly).unwrap();
    for target in ["gfx942", "gfx950"] {
        let mut retargeted = module.clone();
        retargeted.target = Some(target.into());
        retargeted.kernels[0]
            .descriptor
            .fields
            .insert("wavefront_size32".into(), 0);
        assert!(
            volta_amdgpu_analysis::lower::lower_module_kernel(&retargeted, "k").is_err(),
            "{target}"
        );
    }
    for selector in ["-1", "4"] {
        let mut invalid = module.clone();
        let instruction = invalid.kernels[0]
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "v_cvt_f32_bf8_e64")
            .unwrap();
        instruction.modifiers[0].value = Some(selector.into());
        assert!(
            volta_amdgpu_analysis::lower::lower_module_kernel(&invalid, "k").is_err(),
            "{selector}"
        );
    }
    for invalid_form in ["e32", "duplicate", "missing-value"] {
        let mut invalid = module.clone();
        let instruction = invalid.kernels[0]
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "v_cvt_f32_bf8_e64")
            .unwrap();
        match invalid_form {
            "e32" => instruction.mnemonic = "v_cvt_f32_bf8_e32".into(),
            "duplicate" => instruction.modifiers.push(instruction.modifiers[0].clone()),
            "missing-value" => instruction.modifiers[0].value = None,
            _ => unreachable!(),
        }
        assert!(
            volta_amdgpu_analysis::lower::lower_module_kernel(&invalid, "k").is_err(),
            "{invalid_form}"
        );
    }
}
