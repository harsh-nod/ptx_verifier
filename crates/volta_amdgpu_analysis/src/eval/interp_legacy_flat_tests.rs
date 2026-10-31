//! Private tag, full-word and alias boundaries for the legacy shift-zero identity.
use super::*;

const LEGACY: [&str; 2] = ["gfx942", "gfx950"];

fn program(target: &str, instruction: &str) -> Result<LoweredKernel, String> {
    let wave32 = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    let module = crate::frontend::parse(&format!(
        ".amdgcn_target \"{target}\"\n.text\n.type k,@function\nk:\n{instruction}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n{wave32}\n.end_amdhsa_kernel\n"
    ))
    .map_err(|error| error.to_string())?;
    crate::lower::lower_module_kernel(&module, "k").map_err(|error| error.to_string())
}

fn interpreter<'a>(program: &'a LoweredKernel, target: &str) -> Interpreter<'a> {
    Interpreter::new(
        program,
        AnalysisConfig::new((1, 1, 1)),
        Provenance {
            kernel: "k".into(),
            block_dim: (1, 1, 1),
            grid_dim: (1, 1, 1),
            workgroup_id: (0, 0, 0),
            targets: vec![target.into()],
            assumptions: Vec::new(),
            instructions: Vec::new(),
        },
    )
    .unwrap()
}

fn vector(
    interpreter: &mut Interpreter<'_>,
    program: &LoweredKernel,
    wave: &mut Wave,
) -> Result<(), EvalError> {
    let instruction = &program.instructions[0];
    interpreter.vector(wave, instruction, instruction.alu_operation().unwrap())
}

fn wave(target: &str, low: u32, addend: u32) -> Wave {
    let width = AmdArchitecture::from_target(target).unwrap().wave_size();
    let mut wave = Wave::new(0, width, width);
    wave.exec = 1;
    wave.scalar[0] = Some(Value::Bits(low));
    wave.scalar[1] = Some(Value::SharedApertureHi);
    wave.vector.insert((0, 0), Value::Bits(addend));
    wave.vector.insert((1, 0), Value::Bits(0));
    wave.vector.insert((2, 0), Value::Bits(123));
    wave.vector.insert((3, 0), Value::Bits(456));
    wave
}

#[test]
fn exact_identity_preserves_tag_at_u32_boundaries_and_under_addend_alias() {
    for target in LEGACY {
        for destination in [0, 2] {
            let program = program(
                target,
                &format!(
                    "v_lshl_add_u64 v[{destination}:{}],s[0:1],0,v[0:1]",
                    destination + 1
                ),
            )
            .unwrap();
            let mut interpreter = interpreter(&program, target);
            for (low, addend) in [(0, 0), (0, 252), (12, 20), (u32::MAX, 0), (u32::MAX - 7, 7)] {
                let mut wave = wave(target, low, addend);
                let before = wave.scalar.clone();
                vector(&mut interpreter, &program, &mut wave).unwrap();
                assert_eq!(wave.scalar, before);
                assert_eq!(wave.vector[&(destination, 0)], Value::Bits(low + addend));
                assert_eq!(wave.vector[&(destination + 1, 0)], Value::SharedApertureHi);
                let result = program.instructions[0].operands()[0].clone();
                assert!(wave.wide(&result, 0).is_err());
                assert!(wave.vector[&(destination + 1, 0)].bits().is_err());
                assert_eq!(
                    interpreter
                        .flat_memory_address(&wave, &result, 0, 0)
                        .unwrap(),
                    (u64::from(low + addend), true)
                );
                if low + addend == u32::MAX {
                    assert!(
                        interpreter
                            .flat_memory_address(&wave, &result, 0, 1)
                            .is_err()
                    );
                }
            }
        }
    }
}

#[test]
fn active_lanes_and_every_source_word_keep_their_original_roles_and_flags() {
    for target in LEGACY {
        let program = program(target, "v_lshl_add_u64 v[2:3],s[0:1],0,v[0:1]").unwrap();
        let mut interpreter = interpreter(&program, target);
        let mut wave = wave(target, 8, 4);
        wave.exec = 5;
        wave.vector.insert((0, 2), Value::Bits(12));
        wave.vector.insert((1, 2), Value::Bits(0));
        wave.vector.insert((2, 1), Value::Bits(111));
        wave.vector.insert((3, 1), Value::Bits(222));
        wave.set_scc(true);
        wave.vcc = 0x1234_5678_9abc_def0;
        wave.vcc_defined = 3;
        let condition = interpreter.arena.int(0);
        wave.scc_condition = Some(condition);
        let before = wave.scalar.clone();
        vector(&mut interpreter, &program, &mut wave).unwrap();
        assert_eq!(wave.vector[&(2, 0)], Value::Bits(12));
        assert_eq!(wave.vector[&(2, 2)], Value::Bits(20));
        assert_eq!(wave.vector[&(2, 1)], Value::Bits(111));
        assert_eq!(wave.vector[&(3, 1)], Value::Bits(222));
        assert_eq!(wave.scalar, before);
        assert_eq!(wave.exec, 5);
        assert!(wave.scc && wave.scc_defined);
        assert_eq!(wave.scc_condition, Some(condition));
        assert_eq!(wave.vcc, 0x1234_5678_9abc_def0);
        assert_eq!(wave.vcc_defined, 3);
        let (reads, writes) = interpreter.instruction_registers(&program.instructions[0], &wave);
        assert_eq!(reads.len(), 4);
        for index in [0, 1] {
            assert!(reads.contains(&AmdRegister {
                file: AmdRegisterFile::Scalar,
                index,
                lanes: u64::MAX,
            }));
            assert!(reads.contains(&AmdRegister {
                file: AmdRegisterFile::Vector,
                index,
                lanes: 5,
            }));
        }
        assert_eq!(writes.len(), 2);
        for index in [2, 3] {
            assert!(writes.contains(&AmdRegister {
                file: AmdRegisterFile::Vector,
                index,
                lanes: 5,
            }));
        }
        wave.exec = 0;
        wave.scalar[0] = None;
        wave.scalar[1] = None;
        wave.vector.remove(&(0, 0));
        wave.vector.remove(&(1, 0));
        let before = wave.vector.clone();
        vector(&mut interpreter, &program, &mut wave).unwrap();
        assert_eq!(wave.vector, before);
        assert_eq!(
            interpreter.instruction_registers(&program.instructions[0], &wave),
            (Vec::new(), Vec::new())
        );
    }
}

#[test]
fn carry_and_nonzero_high_addend_refuse_before_any_aliased_write() {
    for target in LEGACY {
        for destination in [0, 2] {
            let program = program(
                target,
                &format!(
                    "v_lshl_add_u64 v[{destination}:{}],s[0:1],0,v[0:1]",
                    destination + 1
                ),
            )
            .unwrap();
            let mut interpreter = interpreter(&program, target);
            for (low, addend, high) in [(u32::MAX, 1, 0), (1, u32::MAX, 0), (0, 0, 1)] {
                let mut wave = wave(target, low, addend);
                wave.vector.insert((1, 0), Value::Bits(high));
                let before = wave.vector.clone();
                let error = vector(&mut interpreter, &program, &mut wave).unwrap_err();
                assert!(error.to_string().contains(if high == 0 {
                    "overflows low32"
                } else {
                    "zero high word"
                }));
                assert_eq!(wave.vector, before);
            }
        }
    }
}

#[test]
fn every_observed_word_refuses_undefined_mathematical_or_other_opaque_values() {
    for target in LEGACY {
        let program = program(target, "v_lshl_add_u64 v[0:1],s[0:1],0,v[0:1]").unwrap();
        let mut interpreter = interpreter(&program, target);
        let zero = interpreter.arena.int(0);
        let invalid = [
            None,
            Some(Value::PartialBits {
                bits: 0,
                defined: 0xffff,
            }),
            Some(Value::Input(zero)),
            Some(Value::Real(zero)),
            Some(Value::IntExpr(zero)),
            Some(Value::SharedApertureHi),
            Some(Value::RelocationWord {
                anchor: 0,
                high: false,
            }),
            Some(Value::CodeWord {
                target: 0,
                origin: 0,
                returning: false,
                high: false,
            }),
            Some(Value::PredicateWord {
                mask: 0,
                high: false,
            }),
        ];
        for bad in invalid {
            for word in 0..3 {
                let mut wave = wave(target, 0, 0);
                if word == 0 {
                    wave.scalar[0] = bad;
                } else if let Some(bad) = bad {
                    wave.vector.insert((word - 1, 0), bad);
                } else {
                    wave.vector.remove(&(word - 1, 0));
                }
                let before = wave.vector.clone();
                assert!(vector(&mut interpreter, &program, &mut wave).is_err());
                assert_eq!(wave.vector, before);
            }
            if bad != Some(Value::SharedApertureHi) {
                let mut wave = wave(target, 0, 0);
                wave.scalar[1] = bad;
                let before = wave.vector.clone();
                assert!(vector(&mut interpreter, &program, &mut wave).is_err());
                assert_eq!(wave.vector, before);
            }
        }
    }
}

#[test]
fn other_shift_shapes_register_classes_modifiers_and_targets_do_not_gain_an_identity() {
    for target in LEGACY {
        for instruction in [
            "v_lshl_add_u64 v[2:3],s[0:1],1,v[0:1]",
            "v_lshl_add_u64 v[2:3],s[0:1],64,v[0:1]",
            "v_lshl_add_u64 v[2:3],s[0:1],0.0,v[0:1]",
            "v_lshl_add_u64 v[2:3],s[0:1],s4,v[0:1]",
            "v_lshl_add_u64_e64 v[2:3],s[0:1],0,v[0:1]",
            "v_lshl_add_u64_e32 v[2:3],s[0:1],0,v[0:1]",
            "v_lshl_add_u64 v[2:3],v[4:5],0,v[0:1]",
            "v_lshl_add_u64 v[2:3],s[0:1],0,s[4:5]",
            "v_lshl_add_u64 v[2:3],vcc,0,v[0:1]",
            "v_lshl_add_u64 v[2:3],-s[0:1],0,v[0:1]",
            "v_lshl_add_u64 v[2:3],s[0:1],0,v[0:1] clamp",
            "v_lshl_add_u64 vcc,s[0:1],0,v[0:1]",
        ] {
            // Some malformed forms are already refused by the shared frontend.
            let Ok(program) = program(target, instruction) else {
                continue;
            };
            let mut interpreter = interpreter(&program, target);
            let mut wave = wave(target, 0, 0);
            wave.scalar[4] = Some(Value::Bits(0));
            wave.scalar[5] = Some(Value::Bits(0));
            wave.vector.insert((4, 0), Value::Bits(0));
            wave.vector.insert((5, 0), Value::SharedApertureHi);
            wave.vcc_predicates = [Some(Value::SharedApertureHi); 2];
            wave.vcc_defined = 3;
            let before = wave.vector.clone();
            assert!(
                vector(&mut interpreter, &program, &mut wave).is_err(),
                "{target}: {instruction}"
            );
            assert_eq!(wave.vector, before);
        }
    }
    let program = program("gfx1250", "v_lshl_add_u64 v[2:3],s[0:1],0,v[0:1]").unwrap();
    let mut interpreter = interpreter(&program, "gfx1250");
    let mut wave = wave("gfx1250", 0, 0);
    assert!(vector(&mut interpreter, &program, &mut wave).is_err());
}

#[test]
fn fully_concrete_ordinary_arithmetic_retains_its_existing_wide_behavior() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for mnemonic in ["v_lshl_add_u64", "v_lshl_add_u64_e64"] {
            let program = program(target, &format!("{mnemonic} v[2:3],s[0:1],0,v[0:1]")).unwrap();
            let mut interpreter = interpreter(&program, target);
            let mut wave = wave(target, u32::MAX, 1);
            wave.scalar[1] = Some(Value::Bits(7));
            wave.vector.insert((1, 0), Value::Bits(2));
            vector(&mut interpreter, &program, &mut wave).unwrap();
            assert_eq!(wave.vector[&(2, 0)], Value::Bits(0));
            assert_eq!(wave.vector[&(3, 0)], Value::Bits(10));
        }
    }
}
