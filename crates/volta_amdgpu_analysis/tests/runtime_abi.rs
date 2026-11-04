use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, EvalError, ParamValue, analyze, frontend,
};

fn source(target: &str, enabled: bool, observe_id: bool) -> String {
    let wave32 = target == "gfx1250";
    let wave_descriptor = if wave32 {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    let load = if wave32 {
        "s_load_b64"
    } else {
        "s_load_dwordx2"
    };
    let wait = if wave32 {
        "s_wait_kmcnt 0"
    } else {
        "s_waitcnt lgkmcnt(0)"
    };
    let add = if wave32 { "s_add_co_u32" } else { "s_add_u32" };
    let store = if wave32 {
        "global_store_b32"
    } else {
        "global_store_dword"
    };
    let data = if observe_id { "s2" } else { "7" };
    let finish = if wave32 {
        "s_wait_storecnt 0\ns_wait_xcnt 0\ns_endpgm"
    } else {
        "s_endpgm"
    };
    let accum = if wave32 { "" } else { ".amdhsa_accum_offset 4" };
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.amdhsa_code_object_version 6
.text
.globl abi_probe
.type abi_probe,@function
.p2align 8
abi_probe:
{load} s[4:5], s[0:1], 0
{wait}
{add} s6, {data}, 0
v_mov_b32 v1, s6
{store} v0, v1, s[4:5]
{finish}
.Lend:
.size abi_probe, .Lend-abi_probe
.amdhsa_kernel abi_probe
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_user_sgpr_dispatch_id {enabled}
{wave_descriptor}
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 8
.amdhsa_next_free_vgpr 2
{accum}
.amdhsa_group_segment_fixed_size 0
.amdhsa_kernarg_size 8
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: abi_probe
    .symbol: abi_probe.kd
    .kernarg_segment_size: 8
    .kernarg_segment_align: 8
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .sgpr_count: 8
    .vgpr_count: 2
    .wavefront_size: {wave_size}
    .max_flat_workgroup_size: 1024
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .value_type: f32
...
.end_amdgpu_metadata
"#,
        enabled = u8::from(enabled),
        wave_size = if wave32 { 32 } else { 64 },
    )
}

fn config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    config
}

fn assert_unavailable_input(result: &AnalysisResult) {
    assert!(matches!(
        result.symbolic_outputs(),
        Err(volta_amdgpu_analysis::OutputsUnavailable::Aborted(EvalError::Invalid { what, .. }))
            if what.contains("uninitialized Scalar register 2")
    ));
}

fn assert_marker_seven(result: &AnalysisResult) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].1.len(), 1);
    assert_eq!(
        outputs.arena.as_i64(outputs.element("out", 0).unwrap()),
        Some(7)
    );
    result.graph.validate().unwrap();
}

#[test]
fn dispatch_id_is_not_inferred_from_workgroup_zero() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let module = frontend::parse(&source(target, true, true)).unwrap();
        let result = analyze(&module, Some("abi_probe"), config()).unwrap();
        assert_unavailable_input(&result);
    }
}

#[test]
fn runtime_private_allocation_is_not_the_unrounded_fixed_descriptor_size() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for fixed_size in [0, 6, 8] {
            for observe_input in [false, true] {
                let source = source(target, false, observe_input)
                .replace(
                    ".amdhsa_user_sgpr_dispatch_id 0",
                    &format!(
                        ".amdhsa_user_sgpr_dispatch_id 0\n.amdhsa_user_sgpr_private_segment_size 1\n.amdhsa_private_segment_fixed_size {fixed_size}"
                    ),
                )
                .replace(
                    ".private_segment_fixed_size: 0",
                    &format!(".private_segment_fixed_size: {fixed_size}"),
                );
                let module = frontend::parse(&source).unwrap();
                let result = analyze(&module, Some("abi_probe"), config()).unwrap();
                if observe_input {
                    assert_unavailable_input(&result);
                } else {
                    assert_marker_seven(&result);
                }
            }
        }
    }
}

#[test]
fn unused_dispatch_id_slots_preserve_configured_pointer_and_marker_data() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for enabled in [false, true] {
            let module = frontend::parse(&source(target, enabled, false)).unwrap();
            let result = analyze(&module, Some("abi_probe"), config()).unwrap();
            assert_marker_seven(&result);
        }
    }
}

#[test]
fn disabled_dispatch_id_registers_remain_uninitialized() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let module = frontend::parse(&source(target, false, true)).unwrap();
        let result = analyze(&module, Some("abi_probe"), config()).unwrap();
        assert_unavailable_input(&result);
    }
}

#[test]
fn scalar_u32_add_and_sub_have_no_fabricated_no_carry_spellings() {
    // The pinned LLVM SOPInstructions.td defines real S_ADD/SUB_U32 as
    // s_add/sub_co_u32. Its no-carry scalar forms have 64-bit destinations.
    let valid = source("gfx1250", false, false);
    let module = frontend::parse(&valid).unwrap();
    for mnemonic in ["s_add_nc_u32", "s_sub_nc_u32"] {
        let invalid = valid.replace("s_add_co_u32 s6, 7, 0", &format!("{mnemonic} s6, 7, 0"));
        assert!(
            frontend::parse(&invalid)
                .unwrap_err()
                .message
                .contains(mnemonic)
        );

        let mut forged = module.clone();
        forged.kernels[0]
            .instructions
            .iter_mut()
            .find(|instruction| instruction.mnemonic == "s_add_co_u32")
            .unwrap()
            .mnemonic = mnemonic.into();
        assert!(volta_amdgpu_analysis::lower::lower_module_kernel(&forged, "abi_probe").is_err());
    }
}

#[test]
fn genuine_scalar_add_and_sub_replace_scc_with_their_carry_result() {
    for mnemonic in ["s_add_co_u32", "s_sub_co_u32"] {
        let source = source("gfx1250", false, false).replace(
            "s_add_co_u32 s6, 7, 0",
            &format!("s_cmp_eq_u32 0, 0\n{mnemonic} s6, 7, 0\ns_cselect_b32 s6, 7, 0"),
        );
        let module = frontend::parse(&source).unwrap();
        let result = analyze(&module, Some("abi_probe"), config()).unwrap();
        let output = result.symbolic_outputs().unwrap();
        assert_eq!(output.outputs[0].1.len(), 1);
        assert_eq!(
            output.arena.as_i64(output.element("out", 0).unwrap()),
            Some(0)
        );
    }
}
