//! Operand boundaries for the packed-add and negated-select compiler forms.

use volta_amd_analysis::frontend::ast::{Instruction, Operand, RegFile};
use volta_amd_analysis::frontend::parse::parse_kernel;
use volta_amd_analysis::{LowerError, LoweredInstr, lower_kernel};

fn lower_instruction(instruction: &Instruction) -> Result<LoweredInstr, LowerError> {
    let mut kernel = parse_kernel(include_str!("success/copy.s"), "copy").unwrap();
    kernel.instructions = vec![instruction.clone()];
    Ok(lower_kernel(&kernel)?.instructions.into_vec().remove(0))
}

fn instr(opcode: &str, operands: &[Operand]) -> Instruction {
    Instruction {
        opcode: opcode.into(),
        operands: operands.to_vec(),
    }
}

fn vgpr(index: u32) -> Operand {
    Operand::Reg {
        file: RegFile::Vector,
        first: index,
        last: index,
    }
}

fn vgpr_pair(first: u32) -> Operand {
    Operand::Reg {
        file: RegFile::Vector,
        first,
        last: first + 1,
    }
}

#[test]
fn conditional_select_data_does_not_add_a_second_scalar_bus_source() {
    let scalar = Operand::Reg {
        file: RegFile::Scalar,
        first: 8,
        last: 8,
    };
    let scalar_mask = Operand::Reg {
        file: RegFile::Scalar,
        first: 10,
        last: 11,
    };
    for mask in [Operand::Vcc, scalar_mask] {
        for data in [
            scalar.clone(),
            Operand::NegatedReg {
                file: RegFile::Scalar,
                index: 8,
            },
        ] {
            for [src0, src1] in [[data.clone(), vgpr(1)], [vgpr(1), data.clone()]] {
                assert!(
                    lower_instruction(&instr(
                        "v_cndmask_b32_e64",
                        &[vgpr(0), src0, src1, mask.clone()]
                    ))
                    .is_err(),
                    "scalar data {data:?} with mask {mask:?}"
                );
            }
        }
        for data in [
            vgpr(0),
            Operand::NegatedReg {
                file: RegFile::Vector,
                index: 0,
            },
            Operand::InlineFloat(1.0f32.to_bits()),
            Operand::Imm(-16),
            Operand::Imm(64),
        ] {
            for [src0, src1] in [[data.clone(), vgpr(1)], [vgpr(1), data]] {
                assert!(
                    lower_instruction(&instr(
                        "v_cndmask_b32_e64",
                        &[vgpr(0), src0, src1, mask.clone()]
                    ))
                    .is_ok()
                );
            }
        }
    }
}

#[test]
fn public_float_payloads_cannot_bypass_the_supported_inline_profiles() {
    let forms = |value: Operand| {
        vec![
            instr(
                "v_pk_add_f32",
                &[
                    vgpr_pair(2),
                    vgpr_pair(4),
                    value.clone(),
                    Operand::OpSelHi([true, false]),
                ],
            ),
            instr(
                "v_cndmask_b32_e64",
                &[vgpr(0), value.clone(), vgpr(1), Operand::Vcc],
            ),
            instr(
                "v_cndmask_b32_e64",
                &[vgpr(0), vgpr(1), value.clone(), Operand::Vcc],
            ),
            instr("v_add_f64", &[vgpr_pair(2), vgpr_pair(4), value.clone()]),
            instr("v_add_f64", &[vgpr_pair(2), value.clone(), vgpr_pair(4)]),
            instr(
                "v_mul_f64",
                &[
                    vgpr_pair(2),
                    vgpr_pair(4),
                    Operand::Neg(Box::new(value.clone())),
                ],
            ),
            instr("v_rcp_f64_e32", &[vgpr_pair(2), value.clone()]),
            instr("v_cvt_f32_f64_e64", &[vgpr(0), value.clone()]),
            instr("v_cmp_lt_f64_e64", &[Operand::Vcc, vgpr_pair(4), value]),
        ]
    };
    for bits in [
        0,
        1,
        2.5f32.to_bits(),
        0x3f80_0001,
        0x7f80_0000,
        0x7fc1_2345,
    ] {
        for instruction in forms(Operand::InlineFloat(bits)) {
            assert!(lower_instruction(&instruction).is_err(), "{instruction:?}");
        }
    }
    for value in [0.5f32, -0.5, 1.0, -1.0, 2.0, -2.0, 4.0, -4.0] {
        for instruction in forms(Operand::InlineFloat(value.to_bits())) {
            assert!(lower_instruction(&instruction).is_ok(), "{instruction:?}");
        }
    }
    for value in -16..=64 {
        for instruction in forms(Operand::Imm(value)) {
            assert!(lower_instruction(&instruction).is_ok(), "{instruction:?}");
        }
    }
}

#[test]
fn parsed_scalar_select_data_is_refused_in_either_source_position() {
    for mask in ["vcc", "s[10:11]"] {
        for data in ["s8", "-s8"] {
            for (a, b) in [(data, "v1"), ("v1", data)] {
                let source = format!(
                    ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n\
                     test:\n v_cndmask_b32_e64 v0, {a}, {b}, {mask}\n\
                     s_endpgm\n.Lfunc_end0:\n.amdhsa_kernel test\n.end_amdhsa_kernel\n"
                );
                let kernel = parse_kernel(&source, "test").unwrap();
                assert!(lower_kernel(&kernel).is_err(), "{source}");
                let positive = source.replace(data, "-v8");
                assert!(lower_kernel(&parse_kernel(&positive, "test").unwrap()).is_ok());
            }
        }
    }
}
