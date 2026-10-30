use super::*;

fn register(class: RegisterClass, index: u16, count: u16) -> Register {
    Register {
        class,
        index,
        count,
        special: None,
    }
}

fn program() -> LoweredKernel {
    LoweredKernel {
        name: "address_controls".into(),
        instructions: Vec::new(),
        descriptor: KernelDescriptor {
            fields: [("wavefront_size32".into(), 1)].into(),
        },
        args: Vec::new(),
        globals: Vec::new(),
        global_address_sequences: BTreeMap::new(),
    }
}

fn interpreter(program: &LoweredKernel) -> Interpreter<'_> {
    Interpreter::new(
        program,
        AnalysisConfig::new((1, 1, 1)),
        Provenance {
            kernel: program.name.clone(),
            block_dim: (1, 1, 1),
            grid_dim: (1, 1, 1),
            targets: vec!["gfx1250".into()],
            assumptions: Vec::new(),
            instructions: Vec::new(),
        },
    )
    .unwrap()
}

#[test]
fn flat_scalar_aperture_and_vector_offset_remain_opaque_and_checked() {
    let program = program();
    let interpreter = interpreter(&program);
    let mut wave = Wave::new(0, 1, 32);
    let scalar = register(RegisterClass::Scalar, 8, 2);
    let vector = register(RegisterClass::Vector, 4, 1);
    wave.put(scalar, 0, 0, Value::Bits(16)).unwrap();
    wave.put(scalar, 0, 1, Value::SharedApertureHi).unwrap();
    wave.put(vector, 0, 0, Value::Bits(8)).unwrap();
    let resolve = |wave: &Wave, offset| {
        interpreter.flat_memory_address_with_saddr(
            wave,
            &Operand::Register(vector),
            Some(&Operand::Register(scalar)),
            0,
            offset,
        )
    };
    assert_eq!(resolve(&wave, -4).unwrap(), (20, true));
    assert!(wave.wide(&Operand::Register(scalar), 0).is_err());
    wave.put(scalar, 0, 0, Value::Bits(0)).unwrap();
    wave.put(vector, 0, 0, Value::Bits(0)).unwrap();
    assert!(
        matches!(resolve(&wave, -1), Err(EvalError::Invalid { what, .. }) if what.contains("escapes the shared aperture"))
    );
    wave.put(scalar, 0, 0, Value::Bits(u32::MAX)).unwrap();
    wave.put(vector, 0, 0, Value::Bits(1)).unwrap();
    assert!(resolve(&wave, 0).is_err());
    wave.scalar[9] = None;
    assert!(
        resolve(&wave, 0).is_err(),
        "an undefined high word is not a global address"
    );
}

#[test]
fn flat_global_scalar_and_vector_pair_profiles_preserve_exact_address_bits() {
    let program = program();
    let interpreter = interpreter(&program);
    let mut wave = Wave::new(0, 1, 32);
    let scalar = register(RegisterClass::Scalar, 8, 2);
    let vector = register(RegisterClass::Vector, 4, 1);
    wave.put(scalar, 0, 0, Value::Bits(0xffff_fffc)).unwrap();
    wave.put(scalar, 0, 1, Value::Bits(0x7fff_ffff)).unwrap();
    wave.put(vector, 0, 0, Value::Bits(8)).unwrap();
    assert_eq!(
        interpreter
            .flat_memory_address_with_saddr(
                &wave,
                &Operand::Register(vector),
                Some(&Operand::Register(scalar)),
                0,
                0,
            )
            .unwrap(),
        (0x8000_0000_0000_0004, false)
    );
    let pair = register(RegisterClass::Vector, 6, 2);
    wave.put(pair, 0, 0, Value::Bits(12)).unwrap();
    wave.put(pair, 0, 1, Value::SharedApertureHi).unwrap();
    assert_eq!(
        interpreter
            .flat_memory_address_with_saddr(&wave, &Operand::Register(pair), None, 0, -4,)
            .unwrap(),
        (8, true)
    );
    wave.put(pair, 0, 1, Value::Bits(0)).unwrap();
    assert_eq!(
        interpreter
            .flat_memory_address_with_saddr(&wave, &Operand::Register(pair), None, 0, -16,)
            .unwrap(),
        (u64::MAX - 3, false)
    );
}

#[test]
fn rel64_materializes_only_the_approved_pair_and_preserves_scc() {
    let mut program = program();
    let pair = register(RegisterClass::Scalar, 2, 2);
    program.globals.push(Global {
        symbol: "object".into(),
        size: 4,
        alignment: 4,
        initial_bytes: vec![3, 0, 0, 0],
        read_only: false,
        span: SourceSpan::default(),
    });
    program.global_address_sequences.insert(
        0,
        GlobalAddressSequence {
            anchor_pc: 0,
            register_pair: pair,
            symbol: "object".into(),
            form: GlobalAddressForm::Rel64,
        },
    );
    let raw_pair = crate::frontend::Operand::Register(pair);
    for (name, opcode, operands) in [
        ("s_get_pc_i64", Opcode::ScalarAlu, vec![raw_pair.clone()]),
        (
            "s_add_nc_u64",
            Opcode::ScalarAlu,
            vec![
                raw_pair.clone(),
                raw_pair,
                crate::frontend::Operand::Integer(4),
            ],
        ),
        ("s_endpgm", Opcode::Control, vec![]),
    ] {
        program.instructions.push(
            Instruction::lower(&crate::frontend::Instruction {
                mnemonic: name.into(),
                opcode,
                operands,
                modifiers: Vec::new(),
                span: SourceSpan::default(),
            })
            .unwrap(),
        );
    }
    let interpreter = interpreter(&program);
    for scc in [false, true] {
        let mut wave = Wave::new(0, 1, 32);
        wave.set_scc(scc);
        assert!(
            interpreter
                .module_address_scalar(&mut wave, &program.instructions[0])
                .unwrap()
        );
        assert!(
            wave.wide(&Operand::Register(pair), 0).is_err(),
            "PC anchors are not numeric pointers"
        );
        wave.pc = 1;
        assert!(
            interpreter
                .module_address_scalar(&mut wave, &program.instructions[1])
                .unwrap()
        );
        assert_eq!(
            wave.wide(&Operand::Register(pair), 0).unwrap(),
            MODULE_GLOBAL_BASE
        );
        assert_eq!(wave.scc, scc);
        assert!(wave.scc_defined);
        wave.pc = 2;
        assert!(
            !interpreter
                .module_address_scalar(&mut wave, &program.instructions[2])
                .unwrap(),
            "the next instruction is outside the two-stage profile"
        );
    }
    let mut wave = Wave::new(0, 1, 32);
    wave.pc = 1;
    assert!(
        interpreter
            .module_address_scalar(&mut wave, &program.instructions[1])
            .is_err(),
        "the add cannot invent a missing PC anchor"
    );
}
