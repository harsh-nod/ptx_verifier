use super::*;
use crate::frontend;

fn program(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.text\n.type copy,@function\ncopy:\n{body}\n.size copy, .-copy\n"
    )
}

#[test]
fn resolves_forward_branch_and_native_clang_labels() {
    let module = frontend::parse(&program(
        "s_branch .Ldone\nv_mov_b32 v0, 1\n.Ldone:\ns_endpgm",
    ))
    .unwrap();
    let lowered = lower_kernel(&module.kernels[0]).unwrap();
    assert!(matches!(
        lowered.instructions[0].operation(),
        crate::ir::Operation::Branch(crate::ir::BranchInstruction { target: 2, .. })
    ));
    let module = frontend::parse(include_str!("../frontend/fixtures/clang22-copy-add.s")).unwrap();
    for kernel in &module.kernels {
        let lowered = lower_kernel(kernel).unwrap();
        assert!(
            lowered
                .instructions
                .iter()
                .filter_map(|instruction| match instruction.operation() {
                    crate::ir::Operation::Branch(branch) => Some(branch),
                    _ => None,
                })
                .all(|branch| branch.target < lowered.instructions.len())
        );
    }
}

#[test]
fn rejects_undefined_and_nonexecutable_branch_destinations() {
    for body in [
        "s_branch missing\ns_endpgm",
        "s_branch .Lend\ns_endpgm\n.Lend:",
    ] {
        let module = frontend::parse(&program(body)).unwrap();
        assert!(lower_kernel(&module.kernels[0]).is_err());
    }
}

#[test]
fn unreachable_undefined_branches_and_relocations_are_statically_rejected() {
    for body in [
        "s_branch .Ldone\ns_branch undefined\n.Ldone:\ns_endpgm",
        "s_mov_b64 exec, 0\ns_branch undefined\ns_endpgm",
        "s_branch .Ldone\ns_getpc_b64 s[2:3]\ns_add_u32 s2, s2, undefined@rel32@lo+4\ns_addc_u32 s3, s3, undefined@rel32@hi+12\n.Ldone:\ns_endpgm",
    ] {
        let module = frontend::parse(&program(body)).unwrap();
        assert!(
            lower_kernel_in_module(&module, &module.kernels[0]).is_err(),
            "{body}"
        );
    }
}

#[test]
fn native_module_relocations_preserve_all_original_instructions() {
    let module = frontend::parse(include_str!(
        "../frontend/fixtures/clang22-module-globals.s"
    ))
    .unwrap();
    let lowered = lower_kernel_in_module(&module, &module.kernels[0]).unwrap();
    for (lowered, source) in lowered
        .instructions
        .iter()
        .zip(&module.kernels[0].instructions)
    {
        assert_eq!(lowered.mnemonic(), &source.mnemonic);
        assert_eq!(lowered.span(), source.span);
        assert_eq!(lowered.modifiers(), &source.modifiers);
    }
    assert_eq!(
        lowered.instructions.len(),
        module.kernels[0].instructions.len()
    );
    assert_eq!(lowered.globals, module.globals);
    assert_eq!(lowered.global_address_sequences.len(), 3);
    for (pc, sequence) in lowered.global_address_sequences {
        assert_eq!(pc, sequence.anchor_pc);
        assert_eq!(lowered.instructions[pc].mnemonic(), "s_getpc_b64");
    }
    assert!(
        lower_kernel(&module.kernels[0]).is_err(),
        "module context is mandatory"
    );
}

#[test]
fn only_complete_matching_unbranched_address_sequences_can_resolve_objects() {
    let source = include_str!("../frontend/fixtures/clang22-module-globals.s");
    let cases = [
        source.replacen("constant_table@rel32@lo+4", "constant_table@rel32@lo+8", 1),
        source.replacen("constant_table@rel32@hi+12", "constant_table@rel32@hi+4", 1),
        source.replacen("constant_table@rel32@hi+12", "global_bias@rel32@hi+12", 1),
        source
            .replacen("constant_table@rel32@lo+4", "undefined@rel32@lo+4", 1)
            .replacen("constant_table@rel32@hi+12", "undefined@rel32@hi+12", 1),
        source.replacen(
            "s_add_u32 s2, s2, constant_table",
            "s_add_u32 s4, s2, constant_table",
            1,
        ),
        source
            .replacen(
                "s_add_u32 s2, s2, constant_table",
                ".Lmiddle:\n\ts_add_u32 s2, s2, constant_table",
                1,
            )
            .replacen("module_globals:", "module_globals:\n\ts_branch .Lmiddle", 1),
        source
            .replacen(
                "s_addc_u32 s3, s3, constant_table",
                ".Lmiddle:\n\ts_addc_u32 s3, s3, constant_table",
                1,
            )
            .replacen("module_globals:", "module_globals:\n\ts_branch .Lmiddle", 1),
        source.replacen("s_getpc_b64 s[2:3]", "s_mov_b64 s[2:3], 0", 1),
    ];
    for bad in cases {
        let module = frontend::parse(&bad).unwrap();
        assert!(lower_kernel_in_module(&module, &module.kernels[0]).is_err());
    }
    for bad in [
        "constant_table@gotpcrel+4",
        "constant_table@rel32@unknown+4",
        "constant_table@rel32@lo+arbitrary",
    ] {
        let source = source.replacen("constant_table@rel32@lo+4", bad, 1);
        match frontend::parse(&source) {
            Err(_) => {}
            Ok(module) => assert!(lower_kernel_in_module(&module, &module.kernels[0]).is_err()),
        }
    }
}

/// Build the typed form independently of instruction-parser availability. The
/// native compiler corpus separately pins the actual spelling and encoding.
fn rel64_module() -> Module {
    let pair = Register {
        class: RegisterClass::Scalar,
        index: 2,
        count: 2,
        special: None,
    };
    let instruction = |mnemonic: &str, operands: Vec<Operand>| crate::frontend::Instruction {
        mnemonic: mnemonic.into(),
        opcode: if mnemonic == "s_endpgm" {
            Opcode::Control
        } else {
            Opcode::ScalarAlu
        },
        operands,
        modifiers: Vec::new(),
        span: SourceSpan::default(),
    };
    Module {
        target: Some("gfx1250".into()),
        globals: vec![Global {
            symbol: "object".into(),
            size: 4,
            alignment: 4,
            initial_bytes: vec![3, 0, 0, 0],
            read_only: false,
            span: SourceSpan::default(),
        }],
        kernels: vec![Kernel {
            name: "address".into(),
            descriptor: crate::ir::KernelDescriptor {
                fields: [("wavefront_size32".into(), 1)].into(),
            },
            instructions: vec![
                instruction("s_get_pc_i64", vec![Operand::Register(pair)]),
                instruction(
                    "s_add_nc_u64",
                    vec![
                        Operand::Register(pair),
                        Operand::Register(pair),
                        Operand::Relocation(crate::ir::Relocation {
                            symbol: "object".into(),
                            kind: RelocationKind::Rel64,
                            addend: 4,
                        }),
                    ],
                ),
                instruction("s_endpgm", vec![]),
            ],
            ..Kernel::default()
        }],
        ..Module::default()
    }
}

#[test]
fn native_rel64_preserves_source_pcs_and_requires_module_globals_and_target_gate() {
    let module = rel64_module();
    let kernel = &module.kernels[0];
    let lowered = lower_with_globals(
        kernel,
        &module.globals,
        crate::target::Architecture::Gfx1250,
    )
    .unwrap();
    assert_eq!(lowered.instructions.len(), kernel.instructions.len());
    for (lowered, source) in lowered.instructions.iter().zip(&kernel.instructions) {
        assert_eq!(lowered.mnemonic(), &source.mnemonic);
        assert_eq!(lowered.span(), source.span);
        assert_eq!(lowered.modifiers(), &source.modifiers);
    }
    let sequence = &lowered.global_address_sequences[&0];
    assert_eq!(sequence.form, GlobalAddressForm::Rel64);
    assert_eq!(sequence.symbol, "object");
    assert_eq!(sequence.form.mnemonics().len(), 2);
    assert!(lower_kernel(kernel).is_err());
    assert!(
        lower_with_globals(kernel, &module.globals, crate::target::Architecture::Gfx950).is_err()
    );
}

#[test]
fn native_rel64_rejects_unbounded_mismatched_and_branch_entered_profiles() {
    let base = rel64_module();
    for mutation in 0..8 {
        let mut module = base.clone();
        match mutation {
            0 => {
                let Operand::Relocation(relocation) =
                    &mut module.kernels[0].instructions[1].operands[2]
                else {
                    unreachable!()
                };
                relocation.addend = 8;
            }
            1 => module.globals.clear(),
            2 => module.globals[0].initial_bytes.pop().map(|_| ()).unwrap(),
            3 => {
                let Operand::Register(pair) = &mut module.kernels[0].instructions[1].operands[0]
                else {
                    unreachable!()
                };
                pair.index += 2;
            }
            4 => module.kernels[0].instructions[0].mnemonic = "s_mov_b64".into(),
            5 => {
                let mut branch = module.kernels[0].instructions[2].clone();
                branch.mnemonic = "s_branch".into();
                branch.opcode = Opcode::Branch;
                branch.operands = vec![Operand::Symbol("middle".into())];
                module.kernels[0].labels.insert("middle".into(), 1);
                module.kernels[0].instructions.push(branch);
            }
            6 => module.globals.push(module.globals[0].clone()),
            7 => module.globals[0].alignment = 3,
            _ => unreachable!(),
        }
        assert!(
            lower_with_globals(
                &module.kernels[0],
                &module.globals,
                crate::target::Architecture::Gfx1250
            )
            .is_err(),
            "mutation {mutation}"
        );
    }
}
