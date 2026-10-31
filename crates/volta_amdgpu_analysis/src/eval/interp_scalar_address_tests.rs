//! Exact private-state controls for scalar word comparisons and opaque transport.
use super::*;

const TARGETS: [&str; 3] = ["gfx942", "gfx950", "gfx1250"];

fn program(target: &str, instruction: &str) -> LoweredKernel {
    let wave32 = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    let module = crate::frontend::parse(&format!(
        ".amdgcn_target \"{target}\"\n.text\n.type k,@function\nk:\n{instruction}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n{wave32}\n.end_amdhsa_kernel\n"
    ))
    .unwrap();
    crate::lower::lower_module_kernel(&module, "k").unwrap()
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

fn scalar(
    interpreter: &mut Interpreter<'_>,
    program: &LoweredKernel,
    wave: &mut Wave,
) -> Result<(), EvalError> {
    let instruction = &program.instructions[0];
    interpreter.scalar(wave, instruction, instruction.alu_operation().unwrap())
}

fn wave(target: &str) -> Wave {
    let width = AmdArchitecture::from_target(target).unwrap().wave_size();
    let mut wave = Wave::new(0, width, width);
    wave.vcc = 0x1234_5678_9abc_def0;
    wave.vcc_defined = 3;
    wave
}

#[test]
fn comparisons_replace_even_unknown_scc_and_preserve_all_other_state() {
    for target in TARGETS {
        for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            let program = program(target, &format!("{name} s[6:7],s[12:13]"));
            let mut interpreter = interpreter(&program, target);
            for equal in [false, true] {
                for exec in [0, 5, interpreter.architecture.full_exec_mask()] {
                    for old in [None, Some(false), Some(true)] {
                        let mut wave = wave(target);
                        wave.exec = exec;
                        wave.scalar[6] = Some(Value::Bits(7));
                        wave.scalar[7] = Some(Value::Bits(1));
                        wave.scalar[12] = Some(Value::Bits(7));
                        wave.scalar[13] = Some(Value::Bits(u32::from(equal)));
                        if let Some(old) = old {
                            wave.set_scc(old);
                        } else {
                            let zero = interpreter.arena.int(0);
                            wave.scc_condition = Some(interpreter.arena.ne(zero, zero));
                        }
                        let before = wave.scalar.clone();
                        let vcc = wave.vcc;
                        scalar(&mut interpreter, &program, &mut wave).unwrap();
                        assert_eq!(wave.read_scc().unwrap(), equal == (name == "s_cmp_eq_u64"));
                        assert_eq!(wave.scalar, before);
                        assert_eq!(wave.exec, exec);
                        assert_eq!(wave.vcc, vcc);
                        assert_eq!(wave.vcc_defined, 3);
                        let (reads, writes) =
                            interpreter.instruction_registers(&program.instructions[0], &wave);
                        assert!(writes.is_empty());
                        assert_eq!(reads.len(), 4);
                        for index in [6, 7, 12, 13] {
                            assert!(reads.iter().any(|r| r.file == AmdRegisterFile::Scalar
                                && r.index == index
                                && r.lanes == u64::MAX));
                        }
                    }
                }
            }
        }
    }
}

#[test]
fn comparisons_never_bypass_undefined_or_typed_words() {
    for target in TARGETS {
        for name in ["s_cmp_eq_u64", "s_cmp_lg_u64"] {
            for same in [false, true] {
                let other = if same { "s[6:7]" } else { "s[12:13]" };
                let program = program(target, &format!("{name} s[6:7],{other}"));
                let mut interpreter = interpreter(&program, target);
                let zero = interpreter.arena.int(0);
                let invalid = [
                    None,
                    Some(Value::PartialBits {
                        bits: 0,
                        defined: 0xffff,
                    }),
                    Some(Value::SharedApertureHi),
                    Some(Value::Input(zero)),
                    Some(Value::Real(zero)),
                    Some(Value::IntExpr(zero)),
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
                    for index in [6, 7, 12, 13].into_iter().filter(|i| !same || *i < 8) {
                        let mut wave = wave(target);
                        wave.set_scc(true);
                        for reg in [6, 7, 12, 13] {
                            wave.scalar[reg] = Some(Value::Bits(0));
                        }
                        // A differing known low word must not short-circuit a
                        // missing or opaque high word in either full source.
                        wave.scalar[12] = Some(Value::Bits(1));
                        wave.scalar[index] = bad;
                        let before = wave.scalar.clone();
                        assert!(scalar(&mut interpreter, &program, &mut wave).is_err());
                        assert_eq!(wave.scalar, before);
                        assert!(wave.read_scc().unwrap());
                    }
                }
            }
        }
    }
}

#[test]
fn aperture_addc_is_alias_safe_exec_independent_and_keeps_opaque_identity() {
    for target in ["gfx942", "gfx950"] {
        for sources in ["s2,s3", "s3,s2", "s2,0", "0,s2"] {
            for destination in [2, 3, 7] {
                let program = program(target, &format!("s_addc_u32 s{destination},{sources}"));
                let mut interpreter = interpreter(&program, target);
                for zero in [Value::Bits(0), Value::Integer(0), Value::SignedInteger(0)] {
                    for exec in [0, 5, u64::MAX] {
                        let mut wave = wave(target);
                        wave.exec = exec;
                        wave.set_scc(false);
                        wave.scalar[2] = Some(Value::SharedApertureHi);
                        wave.scalar[3] = Some(zero);
                        scalar(&mut interpreter, &program, &mut wave).unwrap();
                        assert_eq!(wave.scalar[destination], Some(Value::SharedApertureHi));
                        assert_eq!(wave.scalar[2], Some(Value::SharedApertureHi));
                        if destination != 3 {
                            assert_eq!(wave.scalar[3], Some(zero));
                        }
                        assert!(!wave.read_scc().unwrap());
                        assert_eq!(wave.exec, exec);
                        assert_eq!(wave.vcc, 0x1234_5678_9abc_def0);
                        assert!(wave.scalar[destination].unwrap().bits().is_err());
                        let (reads, writes) =
                            interpreter.instruction_registers(&program.instructions[0], &wave);
                        assert!(reads.iter().any(|r| r.index == 2 && r.lanes == u64::MAX));
                        if sources.contains("s3") {
                            assert!(reads.iter().any(|r| r.index == 3 && r.lanes == u64::MAX));
                        }
                        assert_eq!(writes.len(), 1);
                        assert_eq!(writes[0].index, destination as u16);
                        assert_eq!(writes[0].lanes, u64::MAX);
                    }
                }
            }
        }
    }
}

#[test]
fn opaque_addc_refusals_preserve_aliases_and_scc() {
    for target in ["gfx942", "gfx950"] {
        for destination in [2, 3] {
            for sources in ["s2,s3", "s3,s2"] {
                let program = program(target, &format!("s_addc_u32 s{destination},{sources}"));
                let mut interpreter = interpreter(&program, target);
                let zero = interpreter.arena.int(0);
                let bad_zero = [
                    None,
                    Some(Value::Bits(1)),
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
                ];
                for value in bad_zero {
                    let mut wave = wave(target);
                    wave.exec = 0;
                    wave.set_scc(false);
                    wave.scalar[2] = Some(Value::SharedApertureHi);
                    wave.scalar[3] = value;
                    let before = wave.scalar.clone();
                    assert!(scalar(&mut interpreter, &program, &mut wave).is_err());
                    assert_eq!(wave.scalar, before);
                    assert!(!wave.read_scc().unwrap());
                }
                for carry in [0, 1, 2] {
                    let mut wave = wave(target);
                    wave.scalar[2] = Some(Value::SharedApertureHi);
                    wave.scalar[3] = Some(Value::Bits(0));
                    match carry {
                        0 => wave.set_scc(true),
                        1 => wave.clear_scc(),
                        _ => wave.scc_condition = Some(interpreter.arena.ne(zero, zero)),
                    }
                    let before = wave.scalar.clone();
                    let flags = (wave.scc, wave.scc_defined, wave.scc_condition);
                    assert!(scalar(&mut interpreter, &program, &mut wave).is_err());
                    assert_eq!(wave.scalar, before);
                    assert_eq!((wave.scc, wave.scc_defined, wave.scc_condition), flags);
                }
            }
        }
    }
}

#[test]
fn special_destinations_float_immediates_and_gfx1250_do_not_gain_opaque_arithmetic() {
    for target in TARGETS {
        let cases = if target == "gfx1250" {
            vec!["s_addc_u32 s7,s2,0"]
        } else {
            vec![
                "s_addc_u32 exec_lo,s2,0",
                "s_addc_u32 vcc_lo,0,s2",
                "s_addc_u32 s7,s2,0.0",
            ]
        };
        for source in cases {
            let program = program(target, source);
            let mut interpreter = interpreter(&program, target);
            let mut wave = wave(target);
            wave.scalar[2] = Some(Value::SharedApertureHi);
            wave.set_scc(false);
            let before = wave.scalar.clone();
            let exec = wave.exec;
            let vcc = wave.vcc;
            assert!(scalar(&mut interpreter, &program, &mut wave).is_err());
            assert_eq!(wave.scalar, before);
            assert_eq!(wave.exec, exec);
            assert_eq!(wave.vcc, vcc);
            assert!(!wave.read_scc().unwrap());
        }
    }
}
