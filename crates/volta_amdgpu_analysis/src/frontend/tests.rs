use super::*;

fn program(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.text\n.type copy,@function\ncopy:\n{body}\n.size copy, .-copy\n"
    )
}

#[test]
fn parses_native_clang22_copy_and_add_with_full_metadata() {
    let module = parse(include_str!("fixtures/clang22-copy-add.s")).unwrap();
    assert_eq!(module.target.as_deref(), Some("gfx950"));
    assert_eq!(module.code_object_version, Some(6));
    assert_eq!(module.metadata_version.as_deref(), Some(&[1, 2][..]));
    assert_eq!(module.kernels.len(), 2);
    let copy = &module.kernels[0];
    assert_eq!(copy.name, "copy");
    assert_eq!(copy.args[0].name.as_deref(), Some("x.coerce"));
    assert_eq!((copy.args[0].offset, copy.args[0].size), (0, 8));
    assert_eq!(copy.args[2].name.as_deref(), Some("n"));
    assert_eq!(copy.args[2].offset, 16);
    assert_eq!(copy.descriptor.get("kernarg_size"), Some(280));
    assert!(copy.descriptor.flag("user_sgpr_kernarg_segment_ptr"));
    assert_eq!(copy.instructions.last().unwrap().mnemonic, "s_endpgm");
    assert!(
        !module
            .kernels
            .iter()
            .any(|kernel| kernel.name.starts_with("__hip"))
    );
}

#[test]
fn parses_native_clang22_cross_lane_lds_and_matrix_corpus() {
    let module = parse(include_str!("fixtures/clang22-exchange-reduce-relu.s")).unwrap();
    assert_eq!(
        module
            .kernels
            .iter()
            .map(|kernel| kernel.name.as_str())
            .collect::<Vec<_>>(),
        ["exchange", "reduce", "relu"]
    );
    let module = parse(include_str!("fixtures/clang22-mfma-f32.s")).unwrap();
    assert!(
        module.kernels[0]
            .instructions
            .iter()
            .any(|instruction| instruction.mnemonic == "v_mfma_f32_16x16x4_f32")
    );
}

#[test]
fn parses_real_portable_f16_compiler_corpus() {
    let module = parse(include_str!("fixtures/portable-f16.s")).unwrap();
    assert_eq!(module.kernels.len(), 9);
    assert!(
        module
            .kernels
            .iter()
            .any(|kernel| kernel.name == "rmsnorm_f16")
    );
    assert!(
        module
            .kernels
            .iter()
            .any(|kernel| kernel.name == "reduction_f16")
    );
}

#[test]
fn parses_ranges_special_aliases_literals_and_source_positions() {
    let module = parse(&program("s_mov_b64 exec, -1\nv_add_f32_e64 v2, -|v0|, v1 clamp\ns_waitcnt vmcnt(2) lgkmcnt(0)\ns_endpgm")).unwrap();
    let instructions = &module.kernels[0].instructions;
    assert!(matches!(
        instructions[0].operands[0],
        Operand::Register(Register {
            special: Some(SpecialRegister::Exec),
            count: 2,
            ..
        })
    ));
    assert!(matches!(
        instructions[1].operands[1],
        Operand::Modified {
            negate: true,
            absolute: true,
            ..
        }
    ));
    assert_eq!(instructions[1].modifiers[0].name, "clamp");
    assert_eq!(instructions[0].span.line, 5);
    assert_eq!(
        instructions[2].operands,
        vec![
            Operand::WaitCounter {
                name: "vmcnt".into(),
                value: 2
            },
            Operand::WaitCounter {
                name: "lgkmcnt".into(),
                value: 0
            }
        ]
    );
}

#[test]
fn resolves_named_register_indices_and_implicit_vcc() {
    let source = program(
        ".set first, 4\n.set last, first+3\ns_load_dwordx4 s[first:last], s[0:1], 0\nv_mov_b32 v[first], 1\nv_cndmask_b32_e32 v0, v1, v2\ns_endpgm",
    );
    let module = parse(&source).unwrap();
    let instructions = &module.kernels[0].instructions;
    assert!(matches!(
        instructions[0].operands[0],
        Operand::Register(Register {
            index: 4,
            count: 4,
            ..
        })
    ));
    assert_eq!(instructions[2].operands.len(), 4);
    assert!(matches!(
        instructions[2].operands[3],
        Operand::Register(Register {
            special: Some(SpecialRegister::Vcc),
            ..
        })
    ));
}

#[test]
fn rejects_unknown_and_malformed_executable_syntax() {
    for body in [
        "v_imaginary_f32 v0, v1, v2",
        "v_add_f32_e32 v0, v1",
        "v_add_f32_e32 v0,,v1,v2",
        "v_add_f32_e32 v0, v1, v2 mystery:1",
        "v_add_f32_e32 v0, v1, v2 offset:4",
        "v_mov_b32 v256, 0",
        "s_mov_b64 s[1:2], 0",
        "v_mov_b64 v[1:2], 0",
        "s_mov_b32 s102, 0",
        "s_mov_b32 s0, v0",
        "s_load_dwordx4 s[0:1], s[2:3], 0",
        "global_load_dword v0, v1, off",
        "s_waitcnt lgkmcnt(16)",
        "s_waitcnt vmcnt(64)",
        "s_waitcnt vmcnt(0) vmcnt(1)",
        "v_mov_b32 v0, v[2:1]",
        "v_add_f32_e32 v0, |v1, v2",
        ".unknown_meaning_changing_directive 1",
        ".long 0xbf810000",
    ] {
        let error = parse(&program(body)).expect_err(body);
        assert!(error.span.line >= 5, "{body}: {error}");
    }
}

#[test]
fn rejects_other_targets_and_bad_descriptors() {
    assert!(parse(&program("s_endpgm").replace("gfx950", "gfx942")).is_err());
    for field in [
        ".amdhsa_wavefront_size32 1",
        ".amdhsa_system_vgpr_workitem_id 3",
        ".amdhsa_user_sgpr_kernarg_segment_ptr 2",
        ".amdhsa_unknown_flag 1",
    ] {
        let source = format!(
            "{}\n.amdhsa_kernel copy\n{field}\n.end_amdhsa_kernel\n",
            program("s_endpgm")
        );
        assert!(parse(&source).is_err(), "{field}");
    }
}

fn metadata(args: &str) -> String {
    format!(
        "{}\n.amdgpu_metadata\n---\namdhsa.version: [1, 2]\namdhsa.target: amdgcn-amd-amdhsa--gfx950\namdhsa.kernels:\n  - .name: copy\n    .symbol: copy.kd\n    .kernarg_segment_size: 16\n    .wavefront_size: 64\n    .args:\n{args}\n...\n.end_amdgpu_metadata\n",
        program("s_endpgm")
    )
}

#[test]
fn rejects_ambiguous_and_malformed_metadata() {
    for args in [
        "      - .size: 8\n        .value_kind: global_buffer",
        "      - .offset: 0\n        .size: 0\n        .value_kind: global_buffer",
        "      - .offset: 12\n        .size: 8\n        .value_kind: global_buffer",
        "      - .offset: 0\n        .size: 8\n        .value_kind: made_up",
        "      - .offset: 0\n        .size: 8\n        .value_kind: global_buffer\n      - .offset: 4\n        .size: 8\n        .value_kind: global_buffer",
        "      - .offset: 0\n        .size: 8\n        .value_kind: global_buffer\n        .unknown: 1",
    ] {
        assert!(parse(&metadata(args)).is_err(), "{args}");
    }
    let valid =
        metadata("      - .offset: 0\n        .size: 8\n        .value_kind: global_buffer");
    assert!(
        parse(&valid.replace(
            "amdhsa.target: amdgcn-amd-amdhsa--gfx950",
            "amdhsa.target: amdgcn-amd-amdhsa--gfx942"
        ))
        .is_err()
    );
    assert!(parse(&valid.replace(".wavefront_size: 64", ".wavefront_size: 32")).is_err());
    assert!(parse(&valid.replace(".offset: 0", ".offset: [")).is_err());
    assert!(parse(&valid.replace(".offset: 0", ".offset: 0\n        .offset: 4")).is_err());
}
