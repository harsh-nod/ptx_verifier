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
fn parses_real_ocp_e4m3_input_half_output_corpus() {
    let module = parse(include_str!("fixtures/portable-f8.s")).unwrap();
    assert_eq!(module.kernels.len(), 7);
    assert!(
        module.kernels[0]
            .instructions
            .iter()
            .any(|instruction| instruction.mnemonic.starts_with("v_cvt_f32_fp8"))
    );
}

#[test]
fn parses_native_convolution_with_original_reduction_and_layout() {
    let module = parse(include_str!("fixtures/native-convolution.s")).unwrap();
    assert_eq!(module.kernels.len(), 2);
    assert!(
        module
            .kernels
            .iter()
            .all(|kernel| kernel.descriptor.get("group_segment_fixed_size") == Some(4096))
    );
}

#[test]
fn parses_native_cdna4_f16_bf16_and_scaled_e4m3_matrix_forms() {
    let module = parse(include_str!("fixtures/clang22-cdna4-mfma-types.s")).unwrap();
    assert_eq!(module.kernels.len(), 3);
    let instruction = module.kernels[2]
        .instructions
        .iter()
        .find(|instruction| instruction.opcode == Opcode::Matrix)
        .unwrap();
    assert_eq!(instruction.mnemonic, "v_mfma_scale_f32_16x16x128_f8f6f4");
    assert_eq!(instruction.operands.len(), 6);
}

#[test]
fn parses_reduced_and_original_capacity_native_flash_attention() {
    let module = parse(include_str!("fixtures/native-flash-attention.s")).unwrap();
    assert_eq!(module.kernels.len(), 2);
    assert_eq!(module.kernels[0].name, "flash_attention_reduced");
    assert_eq!(module.kernels[1].name, "flash_attention_full");
    assert!(
        module
            .kernels
            .iter()
            .all(
                |kernel| kernel.descriptor.get("group_segment_fixed_size") == Some(9216)
                    && kernel.descriptor.get("private_segment_fixed_size") == Some(0)
            )
    );
}

#[test]
fn parses_native_pipelined_mfma_and_packed_three_dimensional_ids() {
    let module = parse(include_str!("fixtures/clang22-pipelined-mfma-f32.s")).unwrap();
    assert_eq!(
        module.kernels[0].descriptor.get("group_segment_fixed_size"),
        Some(2048)
    );
    let module = parse(include_str!("fixtures/clang22-ids-3d.s")).unwrap();
    assert_eq!(
        module.kernels[0].descriptor.get("system_vgpr_workitem_id"),
        Some(2)
    );
    assert!(
        module.kernels[0]
            .descriptor
            .flag("system_sgpr_workgroup_id_z")
    );
    let module = parse(include_str!("fixtures/clang22-pipelined-mfma-f16.s")).unwrap();
    assert_eq!(
        module.kernels[0].descriptor.get("group_segment_fixed_size"),
        Some(4096)
    );
}

#[test]
fn rejects_registers_outside_declared_allocations_and_unified_aliases() {
    for (body, fields) in [
        ("s_mov_b32 s4, 0\ns_endpgm", ".amdhsa_next_free_sgpr 4"),
        ("v_mov_b32 v4, 0\ns_endpgm", ".amdhsa_next_free_vgpr 4"),
        (
            "v_mfma_f32_16x16x4_f32 a[0:3], v4, v0, 0\ns_endpgm",
            ".amdhsa_next_free_vgpr 8\n.amdhsa_accum_offset 4",
        ),
        (
            "v_mfma_f32_16x16x4_f32 a[0:3], v0, v1, 0\ns_endpgm",
            ".amdhsa_next_free_vgpr 8\n.amdhsa_accum_offset 6",
        ),
        ("s_barrier\ns_endpgm", ".amdhsa_tg_split 1"),
    ] {
        let source = format!(
            "{}\n.amdhsa_kernel copy\n{fields}\n.end_amdhsa_kernel\n",
            program(body)
        );
        assert!(parse(&source).is_err(), "{body}: {fields}");
    }
}

#[test]
fn descriptors_and_metadata_can_precede_native_code() {
    let source = ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.amdhsa_kernel copy\n.amdhsa_kernarg_size 8\n.end_amdhsa_kernel\n.amdgpu_metadata\n---\namdhsa.version: [1,2]\namdhsa.kernels:\n  - .name: copy\n    .args:\n      - .offset: 0\n        .size: 8\n        .value_kind: global_buffer\n...\n.end_amdgpu_metadata\n.text\n.type copy,@function\ncopy:\ns_endpgm\n";
    let module = parse(source).unwrap();
    assert_eq!(module.kernels[0].args.len(), 1);
    assert_eq!(module.kernels[0].descriptor.get("kernarg_size"), Some(8));
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
fn control_immediates_have_explicit_encoded_ranges() {
    for body in [
        "s_endpgm",
        "s_endpgm 0",
        "s_endpgm 65535",
        "s_nop 0\ns_nop 15\ns_endpgm",
        "s_sleep 0\ns_sleep 127\ns_endpgm",
        "s_setprio 0\ns_setprio 3\ns_endpgm",
        "s_sendmsg 0\ns_sendmsg 65535\ns_endpgm",
        ".set delay, 15\ns_nop delay\ns_endpgm",
        "s_nop delay\ns_endpgm\n.set delay, 15",
    ] {
        parse(&program(body)).expect(body);
    }
    for body in [
        "s_endpgm s0",
        "s_endpgm v0",
        "s_endpgm exec",
        "s_endpgm unresolved",
        "s_endpgm 0.5",
        "s_endpgm -1",
        "s_endpgm 65536",
        "s_endpgm 0, 1",
        "s_endpgm 0 clamp",
        "s_endpgm offset:0",
        "s_nop",
        "s_nop s0",
        "s_nop -1",
        "s_nop 16",
        "s_nop 0, 1",
        "s_nop 0 offset:0",
        "s_sleep s0",
        "s_sleep -1",
        "s_sleep 128",
        "s_setprio s0",
        "s_setprio -1",
        "s_setprio 4",
        "s_sendmsg s0",
        "s_sendmsg -1",
        "s_sendmsg 65536",
        "s_sendmsg 0, 1",
        ".set delay, 16\ns_nop delay",
        "s_nop delay\ns_endpgm\n.set delay, 16",
    ] {
        let error = parse(&program(body)).expect_err(body);
        assert!(error.span.line >= 5, "{body}: {error}");
    }
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
        "s_mov_b32 s0, -v0",
        "s_mov_b32 scc, 0",
        "s_mov_b64 s[0:1], s2",
        "v_add_f32 v[2:3], v0, v1",
        "v_add_f32 v2, v[0:1], v1",
        "ds_read_b64 v0, v1",
        "ds_write_b128 v0, v1",
        "v_cndmask_b32 v0, v1, v2, s0",
        "v_mfma_f32_16x16x4_f32 v0, v1, v2, 0",
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
