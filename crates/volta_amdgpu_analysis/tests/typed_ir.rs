use volta_amdgpu_analysis::{frontend, ir, lower};

fn module(target: &str, body: &str) -> frontend::Module {
    let wave = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    frontend::parse(&format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n{body}\n.size k, .-k\n.amdhsa_kernel k\n{wave}\n.end_amdhsa_kernel\n"
    )).unwrap()
}

#[test]
fn copy_lowers_to_semantic_roles_without_losing_source_identity() {
    let module = frontend::parse(include_str!("fixtures/upstream-copy.s")).unwrap();
    let kernel = &module.kernels[0];
    let lowered = lower::lower_module_kernel(&module, "copy").unwrap();
    assert_eq!(lowered.instructions.len(), kernel.instructions.len());
    for (instruction, source) in lowered.instructions.iter().zip(&kernel.instructions) {
        assert_eq!(instruction.mnemonic(), &source.mnemonic);
        assert_eq!(instruction.span(), source.span);
        assert_eq!(instruction.modifiers(), &source.modifiers);
    }
    let ir::Operation::Memory(load) = lowered.instructions[0].operation() else {
        panic!("scalar load")
    };
    assert_eq!(load.kind, ir::MemoryKind::ScalarLoad);
    assert_eq!(
        load.shape,
        ir::TransferShape::Registers {
            bytes_per_register: 4,
            registers_per_part: 4,
            parts: 1
        }
    );
    let ir::MemoryAddress::Scalar { base, offset } = load.address() else {
        panic!("scalar base")
    };
    assert!(matches!(base, ir::Operand::Register(r) if r.index == 0 && r.count == 2));
    assert_eq!(offset, &ir::Operand::Integer(0));
    let ir::Operation::VectorAlu(shift) = lowered.instructions[1].operation() else {
        panic!("typed shift")
    };
    assert_eq!(
        shift.operation,
        ir::AluOperation::Opcode(ir::AluOpcode::VLshlrevB32)
    );
    assert_eq!(lowered.instructions[1].source().encoding, ir::Encoding::E32);
    assert_eq!(lowered.instructions[1].semantic_name(), "v_lshlrev_b32");
    let ir::Operation::Memory(load) = lowered.instructions[3].operation() else {
        panic!("global load")
    };
    let ir::MemoryAddress::Global { vector, scalar } = load.address() else {
        panic!("global address")
    };
    assert!(matches!(vector, ir::Operand::Register(r) if r.index == 0 && r.count == 1));
    assert!(matches!(scalar, ir::Operand::Register(r) if r.index == 0 && r.count == 2));
    assert!(matches!(load.data_destinations(), [ir::Operand::Register(r)] if r.index == 1));
}

#[test]
fn branch_targets_conditions_and_wait_omissions_are_semantic_fields() {
    let module = module(
        "gfx950",
        "s_cbranch_scc0 .Ldone\ns_waitcnt vmcnt(0)\ns_waitcnt 0\n.Ldone:\ns_endpgm",
    );
    let lowered = lower::lower_module_kernel(&module, "k").unwrap();
    assert!(matches!(
        lowered.instructions[0].operation(),
        ir::Operation::Branch(ir::BranchInstruction {
            condition: ir::BranchCondition::SccZero,
            target: 3
        })
    ));
    assert!(matches!(
        lowered.instructions[1].operation(),
        ir::Operation::Wait(ir::WaitInstruction::Cdna {
            vmcnt: Some(0),
            lgkmcnt: None,
            expcnt: None
        })
    ));
    assert!(matches!(
        lowered.instructions[2].operation(),
        ir::Operation::Wait(ir::WaitInstruction::Cdna {
            vmcnt: Some(0),
            lgkmcnt: Some(0),
            expcnt: Some(0)
        })
    ));
}

#[test]
fn native_aliases_share_an_operation_but_preserve_the_encoding_and_spelling() {
    for (target, spelling) in [("gfx950", "s_sub_u32"), ("gfx1250", "s_sub_co_u32")] {
        let module = module(target, &format!("{spelling} s2, s3, 1\ns_endpgm"));
        let lowered = lower::lower_module_kernel(&module, "k").unwrap();
        let ir::Operation::ScalarAlu(alu) = lowered.instructions[0].operation() else {
            panic!("typed scalar operation")
        };
        assert_eq!(
            alu.operation,
            ir::AluOperation::Opcode(ir::AluOpcode::SSubU32)
        );
        assert_eq!(lowered.instructions[0].mnemonic(), spelling);
    }
}

#[test]
fn dual_issue_contains_two_lowered_operations_and_their_pre_issue_operand_roles() {
    let module = module(
        "gfx1250",
        "v_dual_add_f32 v0, v2, v4 :: v_dual_mul_f32 v1, v3, v5\ns_endpgm",
    );
    let lowered = lower::lower_module_kernel(&module, "k").unwrap();
    let instruction = &lowered.instructions[0];
    assert_eq!(instruction.source().encoding, ir::Encoding::Vopd);
    let ir::Operation::Dual { x, y } = instruction.operation() else {
        panic!("typed dual issue")
    };
    for (operation, expected) in [(x, ir::AluOpcode::VAddF32), (y, ir::AluOpcode::VMulF32)] {
        let ir::Operation::VectorAlu(alu) = operation.operation() else {
            panic!("typed component")
        };
        assert_eq!(alu.operation, ir::AluOperation::Opcode(expected));
        assert_eq!(operation.span(), instruction.span());
        assert_eq!(alu.operands().len(), 3);
    }
}

#[test]
fn recognized_unsupported_memory_forms_still_have_truthful_roles() {
    let module = module(
        "gfx950",
        "global_atomic_add v0, v1, s[2:3]\nglobal_atomic_add v4, v0, v1, s[2:3]\ns_buffer_load_dword s0, s[4:7], 0\ns_endpgm",
    );
    let lowered = lower::lower_module_kernel(&module, "k").unwrap();
    for (index, kind) in [
        (0, ir::MemoryKind::AtomicNoReturn),
        (1, ir::MemoryKind::AtomicReturning),
    ] {
        let ir::Operation::Memory(memory) = lowered.instructions[index].operation() else {
            panic!("typed atomic")
        };
        assert_eq!(memory.kind, kind);
        let ir::MemoryAddress::Global { vector, scalar } = memory.address() else {
            panic!("atomic address")
        };
        assert!(matches!(vector, ir::Operand::Register(r) if r.index == 0 && r.count == 1));
        assert!(matches!(scalar, ir::Operand::Register(r) if r.index == 2 && r.count == 2));
        assert!(matches!(memory.data_sources(), [ir::Operand::Register(r)] if r.index == 1));
    }
    let ir::Operation::Memory(memory) = lowered.instructions[2].operation() else {
        panic!("buffer load")
    };
    assert_eq!(memory.kind, ir::MemoryKind::ScalarBufferLoad);
    assert!(
        matches!(memory.address(), ir::MemoryAddress::ScalarBuffer { descriptor: ir::Operand::Register(r), .. } if r.index == 4 && r.count == 4)
    );
}

#[test]
fn direct_ast_callers_cannot_create_short_or_contradictory_executable_roles() {
    for (target, source) in [
        ("gfx950", "global_load_dword v0, v1, s[2:3]"),
        ("gfx950", "v_mfma_f32_16x16x4_f32 v[0:3], v4, v5, 0"),
        (
            "gfx1250",
            "v_wmma_f32_16x16x4_f32 v[0:7], v[8:9], v[10:11], 0",
        ),
    ] {
        let valid = module(target, &format!("{source}\ns_endpgm"));
        for mutation in 0..4 {
            let mut forged = valid.clone();
            let instruction = &mut forged.kernels[0].instructions[0];
            match mutation {
                0 => instruction.operands.clear(),
                1 => {
                    instruction.operands.pop();
                }
                2 => instruction.opcode = frontend::Opcode::Control,
                3 => instruction.modifiers.push(frontend::Modifier {
                    name: "invented_modifier".into(),
                    value: None,
                }),
                _ => unreachable!(),
            }
            assert!(
                lower::lower_kernel(&forged.kernels[0]).is_err(),
                "{target}/{mutation}"
            );
            assert!(
                lower::lower_module_kernel(&forged, "k").is_err(),
                "{target}/{mutation}"
            );
        }
    }
}

#[test]
fn direct_ast_register_and_nested_issue_forgery_is_refused_before_accessors_run() {
    let valid = module("gfx950", "global_load_dword v0, v1, s[2:3]\ns_endpgm");
    for mutation in 0..4 {
        let mut forged = valid.clone();
        let instruction = &mut forged.kernels[0].instructions[0];
        match mutation {
            0 => {
                if let frontend::Operand::Register(r) = &mut instruction.operands[0] {
                    r.count = 0;
                }
            }
            1 => {
                if let frontend::Operand::Register(r) = &mut instruction.operands[1] {
                    r.index = u16::MAX;
                }
            }
            2 => {
                if let frontend::Operand::Register(r) = &mut instruction.operands[2] {
                    r.count = 1;
                }
            }
            3 => {
                let nested = Box::new(instruction.clone());
                instruction.operands[1] = frontend::Operand::Dual(nested.clone(), nested);
            }
            _ => unreachable!(),
        }
        assert!(
            lower::lower_kernel(&forged.kernels[0]).is_err(),
            "{mutation}"
        );
    }
}

#[test]
fn direct_wait_syntax_cannot_truncate_overwrite_or_mix_counter_contracts() {
    let valid = module("gfx950", "s_waitcnt vmcnt(0)\ns_endpgm");
    use frontend::Operand::{Integer, WaitCounter};
    for operands in [
        vec![Integer(65_536)],
        vec![Integer(-1)],
        vec![
            WaitCounter {
                name: "vmcnt".into(),
                value: 0,
            },
            WaitCounter {
                name: "vmcnt".into(),
                value: 1,
            },
        ],
        vec![
            Integer(0),
            WaitCounter {
                name: "lgkmcnt".into(),
                value: 0,
            },
        ],
        vec![WaitCounter {
            name: "vmcnt".into(),
            value: 64,
        }],
        vec![WaitCounter {
            name: "invented_counter".into(),
            value: 0,
        }],
    ] {
        let mut forged = valid.clone();
        forged.kernels[0].instructions[0].operands = operands;
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
        assert!(lower::lower_module_kernel(&forged, "k").is_err());
    }
}

#[test]
fn direct_register_tuples_share_the_text_alignment_and_fp64_encoding_rules() {
    for (source, operand, index) in [
        ("global_load_dwordx2 v[0:1], v2, s[2:3]", 0, 1),
        ("s_load_dwordx4 s[4:7], s[0:1], 0", 0, 2),
    ] {
        let mut forged = module("gfx950", &format!("{source}\ns_endpgm"));
        let frontend::Operand::Register(r) =
            &mut forged.kernels[0].instructions[0].operands[operand]
        else {
            unreachable!()
        };
        r.index = index;
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    }
    let valid = module("gfx950", "v_mul_f64 v[0:1], v[2:3], 1.0\ns_endpgm");
    for value in [
        frontend::Operand::Float(0.1),
        frontend::Operand::Integer(0x1234_5678_9abc_def0),
    ] {
        let mut forged = valid.clone();
        forged.kernels[0].instructions[0].operands[2] = value;
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    }
}

#[test]
fn moduleless_and_external_kernel_entry_points_apply_the_selected_target_profile() {
    let valid = module("gfx1250", "s_endpgm");
    for source in [
        module("gfx950", "s_waitcnt vmcnt(0)\ns_endpgm"),
        module("gfx950", "s_barrier\ns_endpgm"),
        module(
            "gfx950",
            "v_mfma_f32_16x16x4_f32 v[0:3], v4, v5, 0\ns_endpgm",
        ),
    ] {
        let mut kernel = source.kernels[0].clone();
        kernel.descriptor = valid.kernels[0].descriptor.clone();
        assert!(lower::lower_kernel(&kernel).is_err());
        assert!(lower::lower_kernel_in_module(&valid, &kernel).is_err());
    }
    let mut kernel = valid.kernels[0].clone();
    kernel
        .descriptor
        .fields
        .insert("next_free_sgpr".into(), 107);
    assert!(lower::lower_kernel(&kernel).is_err());
    assert!(lower::lower_kernel_in_module(&valid, &kernel).is_err());
}

#[test]
fn scalar_buffer_load_under_empty_exec_keeps_its_unsupported_boundary() {
    let source = module(
        "gfx950",
        "s_mov_b64 exec, 0\ns_buffer_load_dword s4, s[8:11], 0\ns_endpgm",
    );
    let result = volta_amdgpu_analysis::analyze(
        &source,
        None,
        volta_amdgpu_analysis::AnalysisConfig::new((1, 1, 1)),
    )
    .unwrap();
    assert!(matches!(result.symbolic_outputs(),
        Err(volta_amdgpu_analysis::OutputsUnavailable::Aborted(volta_amdgpu_analysis::EvalError::Unsupported { pc: 1, what }))
        if what.contains("s_buffer_load_dword")));
}

#[test]
fn multi_source_and_descriptor_transfers_expose_complete_data_roles() {
    let source = module(
        "gfx950",
        "ds_write2_b32 v0, v1, v2 offset0:0 offset1:1\nds_bpermute_b32 v0, v1, v2\nbuffer_load_dword v0, v1, s[4:7], s0\nbuffer_store_dword v0, v1, s[4:7], s0\ns_endpgm",
    );
    let lowered = lower::lower_module_kernel(&source, "k").unwrap();
    let memories: Vec<_> = lowered
        .instructions
        .iter()
        .filter_map(|i| match i.operation() {
            ir::Operation::Memory(m) => Some(m),
            _ => None,
        })
        .collect();
    assert_eq!(memories[0].data_sources().len(), 2);
    assert_eq!(memories[1].data_destinations().len(), 1);
    assert_eq!(memories[1].data_sources().len(), 1);
    assert!(
        matches!(memories[1].address(), ir::MemoryAddress::CrossLane { index: ir::Operand::Register(r) } if r.index == 1)
    );
    assert!(
        matches!(memories[2].address(), ir::MemoryAddress::Buffer { vector: ir::Operand::Register(v), descriptor: ir::Operand::Register(d), offset: ir::Operand::Register(s) } if v.index == 1 && d.count == 4 && s.index == 0)
    );
    assert_eq!(memories[2].data_destinations().len(), 1);
    assert_eq!(memories[3].data_sources().len(), 1);
    assert!(memories[3].data_destinations().is_empty());
    let source = module(
        "gfx1250",
        "tensor_load_to_lds s[0:3], s[4:11], s[12:15], s[16:19]\ns_endpgm",
    );
    let lowered = lower::lower_module_kernel(&source, "k").unwrap();
    let ir::Operation::Memory(memory) = lowered.instructions[0].operation() else {
        panic!("tensor operation")
    };
    assert_eq!(memory.shape, ir::TransferShape::TensorDescriptor);
    assert!(memory.data_sources().is_empty() && memory.data_destinations().is_empty());
}

#[test]
fn implicit_cndmask_and_dual_operands_are_normalized_without_losing_dependencies() {
    let canonical = module("gfx950", "v_cndmask_b32_e32 v0, v1, v2\ns_endpgm");
    let mut direct = canonical.clone();
    direct.kernels[0].instructions[0].operands.pop();
    let expected = lower::lower_module_kernel(&canonical, "k").unwrap();
    for _ in 0..2 {
        let actual = lower::lower_module_kernel(&direct, "k").unwrap();
        assert_eq!(actual.instructions, expected.instructions);
        assert!(
            matches!(actual.instructions[0].operands().last(), Some(ir::Operand::Register(r)) if r.special == Some(frontend::SpecialRegister::Vcc))
        );
    }
    let canonical = module(
        "gfx1250",
        "v_dual_cndmask_b32 v0, v2, v4 :: v_dual_mul_f32 v1, v3, v5\ns_endpgm",
    );
    let first = lower::lower_module_kernel(&canonical, "k").unwrap();
    let second = lower::lower_kernel(&canonical.kernels[0]).unwrap();
    assert_eq!(first.instructions, second.instructions);
    let ir::Operation::Dual { x, .. } = first.instructions[0].operation() else {
        unreachable!()
    };
    assert_eq!(x.operands().len(), 4);
    assert!(
        matches!(x.operands()[3], ir::Operand::Register(r) if r.special == Some(frontend::SpecialRegister::VccLo))
    );
}

#[test]
fn direct_dual_constituents_destinations_and_encoding_must_be_genuine() {
    let canonical = module(
        "gfx1250",
        "v_dual_add_f32 v0, v2, v4 :: v_dual_mul_f32 v1, v3, v5\ns_endpgm",
    );
    for mutation in 0..6 {
        let mut forged = canonical.clone();
        let frontend::Operand::Dual(x, y) = &mut forged.kernels[0].instructions[0].operands[0]
        else {
            unreachable!()
        };
        match mutation {
            0 => y.operands[0] = x.operands[0].clone(),
            1 => y.mnemonic = "v_min_num_f32".into(),
            2 => {
                x.mnemonic = "v_cndmask_b32_e64".into();
                x.operands
                    .push(frontend::Operand::Register(frontend::Register {
                        class: frontend::RegisterClass::Special,
                        index: 0,
                        count: 1,
                        special: Some(frontend::SpecialRegister::VccLo),
                    }));
                y.mnemonic = "v_fma_f32".into();
                y.operands.push(frontend::Operand::Integer(0));
            }
            3 => x.mnemonic = "v_max_i32_e64".into(),
            4 => x.mnemonic = "v_add_f64_e64".into(),
            5 => x.mnemonic = "v_cndmask_b32_e64".into(),
            _ => unreachable!(),
        }
        assert!(
            lower::lower_kernel(&forged.kernels[0]).is_err(),
            "{mutation}"
        );
        assert!(
            lower::lower_module_kernel(&forged, "k").is_err(),
            "{mutation}"
        );
    }
    let canonical = module(
        "gfx1250",
        "v_dual_cndmask_b32 v0, v2, v4 :: v_dual_mul_f32 v1, v3, v5\ns_endpgm",
    );
    for wrong_selector in [None, Some(frontend::Operand::Integer(0))] {
        let mut forged = canonical.clone();
        let frontend::Operand::Dual(x, _) = &mut forged.kernels[0].instructions[0].operands[0]
        else {
            unreachable!()
        };
        x.operands.pop();
        if let Some(selector) = wrong_selector {
            x.operands.push(selector);
        }
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
        assert!(lower::lower_module_kernel(&forged, "k").is_err());
    }
}

#[test]
fn direct_semantic_flags_hwreg_and_delay_fields_share_the_parser_boundary() {
    let canonical = module(
        "gfx950",
        "v_add_u32_sdwa v0, v1, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD\ns_endpgm",
    );
    let mut forged = canonical.clone();
    forged.kernels[0].instructions[0]
        .modifiers
        .push(frontend::Modifier {
            name: "src0_sext".into(),
            value: None,
        });
    assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    let canonical = module("gfx1250", "s_delay_alu 0\ns_endpgm");
    for encoded in [12, 6 << 4, 12 << 7] {
        let mut forged = canonical.clone();
        forged.kernels[0].instructions[0].operands[0] = frontend::Operand::Integer(encoded);
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    }
    let canonical = module(
        "gfx1250",
        "s_getreg_b32 s0, hwreg(HW_REG_IB_STS2, 6, 4)\ns_endpgm",
    );
    for (offset, width) in [(6, 0), (31, 2), (255, 1)] {
        let mut forged = canonical.clone();
        let frontend::Operand::HardwareRegister {
            offset: start,
            width: count,
            ..
        } = &mut forged.kernels[0].instructions[0].operands[1]
        else {
            unreachable!()
        };
        *start = offset;
        *count = width;
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
    }
    let mut forged = module("gfx950", "v_add_f32 v0, v1, v2\ns_endpgm");
    let original = forged.kernels[0].instructions[0].operands[1].clone();
    forged.kernels[0].instructions[0].operands[1] = frontend::Operand::Modified {
        value: Box::new(frontend::Operand::Modified {
            value: Box::new(original),
            negate: true,
            absolute: false,
        }),
        negate: true,
        absolute: false,
    };
    assert!(lower::lower_kernel(&forged.kernels[0]).is_err());
}

#[test]
fn direct_descriptors_use_the_same_launch_and_allocation_guards_as_text() {
    let canonical = module("gfx950", "global_load_dword v0, v1, s[2:3]\ns_endpgm");
    for (key, value) in [
        ("system_vgpr_workitem_id", 3),
        ("user_sgpr_dispatch_id", 2),
        ("float_round_mode_32", 4),
        ("next_free_sgpr", 3),
        ("next_free_vgpr", 1),
    ] {
        let mut forged = canonical.clone();
        forged.kernels[0]
            .descriptor
            .fields
            .insert(key.into(), value);
        assert!(lower::lower_kernel(&forged.kernels[0]).is_err(), "{key}");
    }
}
