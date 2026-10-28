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
fn parses_defined_native_module_objects_and_split_relocations() {
    let module = parse(include_str!("fixtures/clang22-module-globals.s")).unwrap();
    let bound = module
        .globals
        .iter()
        .find(|object| object.symbol == "bound_global")
        .unwrap();
    assert_eq!(
        (bound.size, bound.alignment, bound.read_only),
        (4, 4, false)
    );
    assert_eq!(bound.initial_bytes, [0, 0, 0, 0]);
    let bias = module
        .globals
        .iter()
        .find(|object| object.symbol == "global_bias")
        .unwrap();
    assert_eq!(bias.initial_bytes, 3i32.to_le_bytes());
    let table = module
        .globals
        .iter()
        .find(|object| object.symbol == "constant_table")
        .unwrap();
    assert_eq!(
        (table.size, table.alignment, table.read_only),
        (16, 16, true)
    );
    assert_eq!(
        table.initial_bytes,
        [2i32, 3, 5, 7]
            .into_iter()
            .flat_map(i32::to_le_bytes)
            .collect::<Vec<_>>()
    );
    assert_eq!(
        module.kernels[0]
            .instructions
            .iter()
            .flat_map(|instruction| &instruction.operands)
            .filter(|operand| matches!(operand, Operand::Relocation(_)))
            .count(),
        6
    );
    let module = parse(include_str!("fixtures/clang22-dynamic-lds.s")).unwrap();
    assert_eq!(
        module.kernels[0].descriptor.get("group_segment_fixed_size"),
        Some(32)
    );
    let module = parse(include_str!("fixtures/clang22-grid-output.s")).unwrap();
    for name in [
        "hidden_block_count_x",
        "hidden_block_count_y",
        "hidden_block_count_z",
        "hidden_group_size_x",
        "hidden_group_size_y",
        "hidden_group_size_z",
    ] {
        assert!(
            module.kernels[0]
                .args
                .iter()
                .any(|arg| arg.value_kind == name),
            "{name}"
        );
    }
}

#[test]
fn module_object_data_never_silently_loses_size_bytes_or_identity() {
    let object = ".type g,@object\n.data\n.p2align 3\ng:\n.quad 0x0123456789abcdef\n.size g,8\n";
    let source = format!("{}\n{object}", program("s_endpgm"));
    let module = parse(&source).unwrap();
    assert_eq!(
        module.globals[0].initial_bytes,
        0x0123456789abcdefu64.to_le_bytes()
    );
    assert_eq!(module.globals[0].alignment, 8);
    for bad in [
        object.replace(".size g,8", ".size g,4"),
        object.replace(".size g,8", ""),
        object.replace(".quad 0x0123456789abcdef", ".quad external@rel64"),
        object.replace(".quad 0x0123456789abcdef", ".asciz \"not modeled\""),
        object.replace(".quad 0x0123456789abcdef", ".zero 16777217"),
        object.replace(".p2align 3", ".balign 3"),
        object.replace(".p2align 3", ".p2align 3,0,1"),
        object.replace(".size g,8", ".size wrong,8\n.text"),
        format!("{object}{object}"),
    ] {
        assert!(
            parse(&format!("{}\n{bad}", program("s_endpgm"))).is_err(),
            "{bad}"
        );
    }
}

#[test]
fn shared_aperture_source_has_only_the_pinned_64bit_move_profile() {
    let module = parse(&program("s_mov_b64 s[2:3], src_shared_base\ns_endpgm")).unwrap();
    assert!(matches!(
        module.kernels[0].instructions[0].operands[1],
        Operand::Register(Register {
            count: 2,
            special: Some(SpecialRegister::SharedBase),
            ..
        })
    ));
    for body in [
        "s_mov_b32 s2, src_shared_base",
        "s_mov_b64 src_shared_base, s[2:3]",
        "s_mov_b64 exec, src_shared_base",
        "s_add_u64 s[2:3], src_shared_base, s[4:5]",
        "v_mov_b64 v[2:3], src_shared_base",
        "s_mov_b64 s[2:3], -src_shared_base",
    ] {
        assert!(parse(&program(body)).is_err(), "{body}");
    }
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
fn parses_full_convolution_tiles_with_original_output_pitches() {
    let module = parse(include_str!("fixtures/native-full-convolution.s")).unwrap();
    assert_eq!(module.kernels.len(), 2);
    for kernel in &module.kernels {
        assert_eq!(
            kernel.descriptor.get("group_segment_fixed_size"),
            Some(16384)
        );
        assert_eq!(kernel.descriptor.get("private_segment_fixed_size"), Some(0));
        assert_eq!(kernel.descriptor.get("max_flat_workgroup_size"), Some(512));
    }
}

#[test]
fn parses_native_cdna4_f16_bf16_and_scaled_e4m3_matrix_forms() {
    let module = parse(include_str!("fixtures/clang22-cdna4-mfma-types.s")).unwrap();
    assert_eq!(module.kernels.len(), 4);
    let instruction = module.kernels[2]
        .instructions
        .iter()
        .find(|instruction| instruction.opcode == Opcode::Matrix)
        .unwrap();
    assert_eq!(instruction.mnemonic, "v_mfma_scale_f32_16x16x128_f8f6f4");
    assert_eq!(instruction.operands.len(), 6);
}

#[test]
fn parses_full_shape_native_gemm_without_private_spills() {
    let module = parse(include_str!("fixtures/native-full-gemm.s")).unwrap();
    assert_eq!(module.kernels.len(), 4);
    for kernel in &module.kernels {
        assert_eq!(
            kernel.descriptor.get("group_segment_fixed_size"),
            Some(65536)
        );
        assert_eq!(kernel.descriptor.get("private_segment_fixed_size"), Some(0));
        assert_eq!(kernel.descriptor.get("max_flat_workgroup_size"), Some(1024));
        assert!(kernel.instructions.iter().any(|instruction| {
            matches!(
                instruction.mnemonic.as_str(),
                "v_mfma_f32_16x16x32_f16" | "v_mfma_scale_f32_32x32x64_f8f6f4"
            )
        }));
    }
}

#[test]
fn parses_native_scalar_integer_and_binary64_types() {
    let module = parse(include_str!("fixtures/clang22-scalar-types.s")).unwrap();
    assert_eq!(module.kernels.len(), 3);
    let kernel = module
        .kernels
        .iter()
        .find(|kernel| kernel.name == "scalar_f64")
        .unwrap();
    for mnemonic in [
        "v_add_f64",
        "v_mul_f64",
        "v_fmac_f64",
        "v_rcp_f64",
        "v_sqrt_f64",
        "v_cvt_f64_f32",
        "v_cvt_f32_f64",
    ] {
        assert!(
            kernel
                .instructions
                .iter()
                .any(|instruction| instruction.mnemonic.trim_end_matches("_e32") == mnemonic),
            "{mnemonic}"
        );
    }
}

#[test]
fn parses_mixed_byvalue_abi_without_inventing_padding_arguments() {
    let module = parse(include_str!("fixtures/clang22-mixed-byvalue.s")).unwrap();
    let kernel = &module.kernels[0];
    assert_eq!(kernel.args.len(), 6);
    for body in [
        "s_sext_i32_i16 s0, s1",
        "v_cvt_f32_ubyte2_e32 v0, v1",
        "v_cvt_f32_ubyte2_e64 v0, s1",
    ] {
        parse(&program(body)).unwrap_or_else(|error| panic!("{body}: {error}"));
    }
    for body in [
        "s_sext_i32_i16 s[0:1], s2",
        "s_sext_i32_i16 s0, s[2:3]",
        "s_sext_i32_i16 s0, v1",
        "s_sext_i32_i16 s0, s1, s2",
        "v_cvt_f32_ubyte2 v[0:1], v2",
        "v_cvt_f32_ubyte2 v0, v[2:3]",
        "v_cvt_f32_ubyte2 v0, v1, v2",
    ] {
        parse(&program(body)).expect_err(body);
    }
}

#[test]
fn parses_full_shape_weighted_state_and_forgetting_attention() {
    for (assembly, name, shared) in [
        (
            include_str!("fixtures/native-mamba2-state.s"),
            "mamba2_chunk_state_full",
            12288,
        ),
        (
            include_str!("fixtures/native-forgetting-attention.s"),
            "forgetting_attention_full",
            9216,
        ),
        (
            include_str!("fixtures/native-flash-sinkhorn.s"),
            "flash_sinkhorn_full",
            4096,
        ),
        (
            include_str!("fixtures/native-sage-attention.s"),
            "sage_attention_full",
            9216,
        ),
    ] {
        let module = parse(assembly).unwrap();
        assert_eq!(module.kernels.len(), 1);
        assert_eq!(module.kernels[0].name, name);
        assert_eq!(
            module.kernels[0].descriptor.get("group_segment_fixed_size"),
            Some(shared)
        );
        assert_eq!(
            module.kernels[0]
                .descriptor
                .get("private_segment_fixed_size"),
            Some(0)
        );
    }
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
fn binary64_immediates_preserve_the_actual_encoded_precision() {
    for body in [
        "v_add_f64 v[0:1], 1.0, v[2:3]",
        "v_add_f64 v[0:1], 0x3ff00000, v[2:3]",
        "v_add_f64 v[0:1], 0x3ff0000000000000, v[2:3]",
        "v_fma_f64 v[0:1], -0.5, v[2:3], v[4:5]",
        "v_rcp_f64_e32 v[0:1], 1.5",
        "v_rcp_f64_e32 v[0:1], -0.5",
        "v_rcp_f64_e32 v[0:1], 0x3ff80000",
        "v_cvt_f32_f64_e32 v0, 0x3ff80000",
        "v_fmac_f64_e32 v[0:1], 0x3ff80000, v[2:3]",
    ] {
        parse(&program(body)).expect(body);
    }
    let module = parse(&program(
        "v_add_f64 v[0:1], 0x3ff0000000000000, v[2:3]\nv_rcp_f64_e32 v[0:1], 1.5",
    ))
    .unwrap();
    assert_eq!(
        module.kernels[0].instructions[0].operands[1],
        Operand::Float(1.0)
    );
    assert_eq!(
        module.kernels[0].instructions[1].operands[1],
        Operand::Integer(0x3ff80000)
    );
    for body in [
        "v_add_f64 v[0:1], 0.1, v[2:3]",
        "v_add_f64 v[0:1], 1.5, v[2:3]",
        "v_add_f64 v[0:1], 65, v[2:3]",
        "v_add_f64 v[0:1], 0x3ff80000, v[2:3]",
        "v_fma_f64 v[0:1], 0x3ff80000, v[2:3], v[4:5]",
        "v_rcp_f64_e32 v[0:1], 0.1",
        "v_rcp_f64_e32 v[0:1], 0.15915494309189535",
        "v_rcp_f64_e32 v[0:1], 0x3ff8000000000000",
        "v_rcp_f64_e32 v[0:1], -v[2:3]",
        "v_fmac_f64_e32 v[0:1], v[2:3], 1.0",
    ] {
        parse(&program(body)).expect_err(body);
    }
}

#[test]
fn bitop3_has_its_own_truth_table_modifier_contract() {
    parse(&program("v_bitop3_b32 v0, s0, v1, v2 bitop3:0xc8")).unwrap();
    for body in [
        "v_bitop3_b32 v0, v1, v2, v3",
        "v_bitop3_b32 v0, v1, v2, v3 bitop3:256",
        "v_bitop3_b32 v0, v1, v2, v3 bitop3:-1",
        "v_bitop3_b32 v0, v1, v2, v3 bitop3:1 clamp",
        "v_bitop3_b32 v0, -v1, v2, v3 bitop3:1",
        "v_bitop3_b32 v0, v1, v2, v3 bitop3:0.5",
        "v_add_f32 v0, v1, v2 bitop3:1",
    ] {
        parse(&program(body)).expect_err(body);
    }
}

#[test]
fn sdwa_integer_sign_extension_is_scoped_to_the_modeled_conversion() {
    let module = parse(&program(
        "v_cvt_f16_i16_sdwa v0, sext(v1) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0",
    ))
    .unwrap();
    assert!(
        module.kernels[0].instructions[0]
            .modifiers
            .iter()
            .any(|modifier| modifier.name == "src0_sext")
    );
    for body in [
        "v_cvt_f16_i16_e32 v0, sext(v1)",
        "v_cvt_f16_i16_sdwa v0, sext(1)",
        "v_cvt_f16_i16_sdwa v0, sext(v[2:3])",
        "v_cvt_f16_i16_sdwa v0, v1 src0_sext",
        "v_add_u32_sdwa v0, sext(v1), v2",
    ] {
        parse(&program(body)).expect_err(body);
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
        "v_add_f64 v0, v[2:3], v[4:5]",
        "v_add_f64 v[0:1], v2, v[4:5]",
        "v_fma_f64 v[0:1], v[2:3], v[4:5], v6",
        "v_rcp_f64 v0, v[2:3]",
        "v_sqrt_f64 v[0:1], v2",
        "v_cvt_f64_f32 v0, v1",
        "v_cvt_f64_f32 v[0:1], v[2:3]",
        "v_cvt_f32_f64 v[0:1], v[2:3]",
        "v_cvt_f32_f64 v0, v2",
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
fn malformed_native_instructions_are_rejected_even_when_unreachable_or_exec_zero() {
    for malformed in [
        "v_add_f32 v0, v1",
        "v_add_f32 v0, v1, v2 mystery:1",
        "v_mfma_f32_16x16x4_f32 v0, v1, v2, 0",
        "s_waitcnt v0",
    ] {
        for body in [
            format!("s_branch .Ldone\n{malformed}\n.Ldone:\ns_endpgm"),
            format!("s_mov_b64 exec, 0\n{malformed}\ns_endpgm"),
        ] {
            parse(&program(&body)).expect_err(&body);
        }
    }
}

#[test]
fn mfma_operand_classes_match_the_pinned_gfx950_assembler() {
    // This includes positive and negative A/B/C cases across F32, F16,
    // BF16, F8F6F4, F64 and I8 forms. The assembly receipt records the
    // actual encoding or diagnostic, rather than assuming zero is legal.
    let receipt: serde_yaml::Value = serde_yaml::from_str(include_str!(
        "../../../../tests/gfx950/portable-matrix/mfma-operand-assembler.json"
    ))
    .unwrap();
    let cases = receipt["cases"].as_sequence().unwrap();
    assert_eq!(cases.len(), 317);
    for case in cases {
        let instruction = case["source"].as_str().unwrap();
        let source = format!(
            "{}\n.amdhsa_kernel copy\n.amdhsa_next_free_sgpr 64\n.amdhsa_next_free_vgpr 128\n.amdhsa_accum_offset 64\n.end_amdhsa_kernel\n",
            program(&format!("{instruction}\ns_endpgm"))
        );
        let parsed = parse(&source);
        let legal = case["returncode"].as_i64().unwrap() == 0;
        assert_eq!(
            parsed.is_ok(),
            legal,
            "{instruction}: parser={parsed:?}; assembler={}",
            case["stderr"].as_str().unwrap()
        );
    }
}

#[test]
fn binary_vop_source_positions_match_the_pinned_gfx950_assembler() {
    let receipt: serde_yaml::Value = serde_yaml::from_str(include_str!(
        "../../tests/fixtures/vop-operand-assembler.json"
    ))
    .unwrap();
    let cases = receipt["cases"].as_sequence().unwrap();
    assert_eq!(cases.len(), 624);
    let extra = receipt["extra_cases"].as_sequence().unwrap();
    assert_eq!(extra.len(), 19);
    for case in cases.iter().chain(extra) {
        let instruction = case["source"].as_str().unwrap();
        let parsed = parse(&program(&format!("{instruction}\ns_endpgm")));
        assert_eq!(
            parsed.is_ok(),
            case["returncode"].as_i64().unwrap() == 0,
            "{instruction}: parser={parsed:?}; assembler={}",
            case["stderr"].as_str().unwrap()
        );
    }
    for bad in [
        "v_sub_u32 v26, v0, 128",
        "v_add_f32_e32 v0, v1, 1.0",
        "v_add_f32 v0, 128, v1 clamp",
        "v_add_u32 v0, 0x100000000, v1",
    ] {
        for body in [
            bad.to_owned(),
            format!("s_branch .Ldone\n{bad}\n.Ldone:\ns_endpgm"),
        ] {
            parse(&program(&body)).expect_err(&body);
        }
    }
}

#[test]
fn floating_vop_sources_require_actual_native_encodings() {
    let receipt: serde_yaml::Value = serde_yaml::from_str(include_str!(
        "../../tests/fixtures/vop-floating-assembler.json"
    ))
    .unwrap();
    assert_eq!(receipt["cases"].as_sequence().unwrap().len(), 891);
    for case in receipt["cases"].as_sequence().unwrap() {
        let instruction = case["source"].as_str().unwrap();
        let expected = case["expected_parse"].as_bool().unwrap();
        let parsed = parse(&program(&format!("{instruction}\ns_endpgm")));
        assert_eq!(parsed.is_ok(), expected, "{instruction}: {parsed:?}");
    }
    // Positive register/inline/valid SRC0 literal controls prevent rejection
    // from being attributed to an unknown mnemonic. Invalid source positions
    // remain malformed even behind a branch or with an empty active mask.
    for invalid in [
        "v_max_f32 v8, v4, 3.0",
        "v_min_f32 v8, v4, 3.0",
        "v_fma_f32 v8, v4, 3.0, v4",
    ] {
        for body in [
            invalid.to_string(),
            format!("s_branch .Ldone\n{invalid}\n.Ldone:\ns_endpgm"),
            format!("s_mov_b64 exec, 0\n{invalid}\ns_endpgm"),
        ] {
            parse(&program(&body)).expect_err(&body);
        }
    }
}

#[test]
fn fp8_sdwa_conversion_has_only_native_source_selection_fields() {
    for conversion in ["v_cvt_f32_fp8_sdwa", "v_cvt_f32_bf8_sdwa"] {
        parse(&program(&format!("{conversion} v0, v1 src0_sel:BYTE_1"))).unwrap();
        for destination in ["dst_sel:DWORD", "dst_unused:UNUSED_PAD"] {
            parse(&program(&format!(
                "{conversion} v0, v1 src0_sel:BYTE_1 {destination}"
            )))
            .expect_err(destination);
        }
    }
}

#[test]
fn trap_and_signed64_shift_profiles_match_pinned_native_controls() {
    let controls: serde_yaml::Value = serde_yaml::from_str(include_str!(
        "../../../../tests/gfx950/portable-parser/control-assembler.json"
    ))
    .unwrap();
    for case in controls["cases"].as_sequence().unwrap() {
        let body = case["source"].as_str().unwrap();
        let expected = case["expected_parse"].as_bool().unwrap();
        assert_eq!(
            parse(&program(&format!("{body}\ns_endpgm"))).is_ok(),
            expected,
            "{body}"
        );
    }
}

#[test]
fn rejects_other_targets_and_bad_descriptors() {
    assert!(parse(&program("s_endpgm").replace("gfx950", "gfx940")).is_err());
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

#[test]
fn target_features_preserve_unique_settings_and_reject_duplicates_or_conflicts() {
    for suffix in [
        "",
        ":xnack-",
        ":xnack+",
        ":sramecc-",
        ":sramecc+",
        ":sramecc+:xnack-",
        ":xnack+:sramecc-",
    ] {
        let target = format!("gfx950{suffix}");
        let source = program("s_endpgm").replace("gfx950", &target);
        assert_eq!(
            parse(&source).unwrap().target.as_deref(),
            Some(target.as_str())
        );
    }
    for suffix in [
        ":xnack+:xnack-",
        ":xnack-:xnack+",
        ":sramecc+:sramecc-",
        ":sramecc-:sramecc+",
        ":xnack+:xnack+",
        ":xnack-:sramecc+:xnack-",
        ":sramecc+:sramecc+",
        ":sramecc-:sramecc-",
        ":",
        "::xnack-",
        ":xnack-:",
    ] {
        let source = program("s_endpgm").replace("gfx950", &format!("gfx950{suffix}"));
        assert!(parse(&source).is_err(), "accepted invalid target {suffix}");
        let source = metadata("").replace(
            "amdhsa.target: amdgcn-amd-amdhsa--gfx950",
            &format!("amdhsa.target: amdgcn-amd-amdhsa--gfx950{suffix}"),
        );
        assert!(
            parse(&source).is_err(),
            "accepted invalid metadata target {suffix}"
        );
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
