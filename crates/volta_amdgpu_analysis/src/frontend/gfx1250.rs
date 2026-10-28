//! Exact selected gfx1250 syntax. Native mnemonics/source spans remain intact.
use super::*;
use crate::target::Architecture;

pub(super) fn signature(name: &str) -> Option<(Opcode, usize, usize)> {
    use Opcode::*;
    Some(
        match name.trim_end_matches("_e32").trim_end_matches("_e64") {
            "s_load_b32" | "s_load_b64" | "s_load_b96" | "s_load_b128" | "s_load_b256"
            | "s_load_b512" => (ScalarMemory, 3, 3),
            "global_load_u16" | "global_load_u8" | "global_store_b16" | "global_store_b8"
            | "global_load_b32" | "global_load_b64" | "global_load_b128" | "global_store_b32"
            | "global_store_b64" | "global_store_b128" => (VectorMemory, 3, 3),
            "ds_load_u16" | "ds_load_i16" | "ds_load_u8" | "ds_load_i8" | "ds_store_b16"
            | "ds_store_b8" | "ds_load_b32" | "ds_load_b64" | "ds_load_b128" | "ds_store_b32"
            | "ds_store_b64" | "ds_store_b128" => (Lds, 2, 2),
            "s_wait_loadcnt_dscnt"
            | "s_wait_storecnt_dscnt"
            | "s_wait_loadcnt"
            | "s_wait_storecnt"
            | "s_wait_dscnt"
            | "s_wait_kmcnt"
            | "s_wait_xcnt"
            | "s_wait_asynccnt"
            | "s_wait_tensorcnt" => (Wait, 1, 1),
            "s_barrier_signal" | "s_barrier_wait" => (Barrier, 1, 1),
            "s_clause" => (Control, 1, 1),
            "v_nop" => (Control, 0, 0),
            "tensor_load_to_lds" | "tensor_store_from_lds" => (VectorMemory, 4, 4),
            "s_add_co_u32" | "s_add_co_ci_u32" | "s_mul_u64" | "s_add_nc_u64"
            | "s_and_not1_b32" | "s_add_co_i32" | "s_add_nc_u32" | "s_sub_nc_u32" => {
                (ScalarAlu, 3, 3)
            }
            "s_and_saveexec_b32" | "s_andn2_saveexec_b32" | "s_or_saveexec_b32" => {
                (ScalarAlu, 2, 2)
            }
            "v_mad_u32" => (VectorAlu, 4, 4),
            "v_add_co_ci_u32" => (VectorAlu, 5, 5),
            "v_add_nc_u64" | "v_add_nc_u32" | "v_sub_nc_u32" | "v_bitop2_b32" => (VectorAlu, 3, 3),
            "v_wmma_f32_16x16x4_f32" | "v_wmma_f32_16x16x32_f16" | "v_wmma_f32_16x16x32_bf16" => {
                (Matrix, 4, 4)
            }
            _ => return None,
        },
    )
}

pub(super) fn parse_special(
    text: &str,
    span: SourceSpan,
) -> Result<Option<Instruction>, ParseError> {
    let fail = |message: &str| ParseError {
        message: message.into(),
        span,
    };
    if let Some((x, y)) = text.split_once("::") {
        if y.contains("::") {
            return Err(fail("VOPD requires exactly two operations"));
        }
        fn half(text: &str, span: SourceSpan) -> Result<Instruction, ParseError> {
            let (name, rest) = text
                .trim()
                .split_once(char::is_whitespace)
                .unwrap_or((text.trim(), ""));
            let name = name.strip_prefix("v_dual_").ok_or_else(|| ParseError {
                message: "VOPD requires v_dual_ operations".into(),
                span,
            })?;
            if ![
                "add_f32",
                "mul_f32",
                "fma_f32",
                "lshlrev_b32",
                "lshrrev_b32",
                "mov_b32",
                "bitop2_b32",
                "cndmask_b32",
                "fmac_f32",
                "add_nc_u32",
                "sub_f32",
                "max_num_f32",
            ]
            .contains(&name)
            {
                return Err(ParseError {
                    message: format!("unsupported VOPD operation {name}"),
                    span,
                });
            }
            let text = if name == "cndmask_b32" && rest.split(',').count() == 3 {
                format!("v_{name}_e64 {rest}, vcc_lo")
            } else {
                format!("v_{name} {rest}")
            };
            let mut op = super::instr::parse_instruction(&text, span, Architecture::Gfx1250)?;
            if name == "bitop2_b32" {
                op.mnemonic = "v_bitop3_b32".into();
                op.operands.push(Operand::Integer(0));
            }
            Ok(op)
        }
        let x = half(x, span)?;
        let y = half(y, span)?;
        if x.operands[0] == y.operands[0] {
            return Err(fail("VOPD destinations must be distinct"));
        }
        return Ok(Some(Instruction {
            mnemonic: text.split_whitespace().next().unwrap().into(),
            opcode: Opcode::VectorAlu,
            operands: vec![Operand::Dual(Box::new(x), Box::new(y))],
            modifiers: vec![],
            span,
        }));
    }
    if let Some(rest) = text.strip_prefix("s_delay_alu ") {
        let encoded = if let Some(value) = super::instr::integer(rest.trim()) {
            value
        } else {
            let mut encoded = 0i64;
            let mut fields = std::collections::BTreeSet::new();
            for item in rest.split('|') {
                let (field, value) = item
                    .trim()
                    .split_once('(')
                    .and_then(|(a, b)| b.strip_suffix(')').map(|b| (a, b)))
                    .ok_or_else(|| fail("invalid s_delay_alu field"))?;
                if !fields.insert(field) {
                    return Err(fail("duplicate s_delay_alu field"));
                }
                let (shift, value) = if field == "instskip" {
                    (
                        4,
                        match value {
                            "SAME" => 0,
                            "NEXT" => 1,
                            "SKIP_1" => 2,
                            "SKIP_2" => 3,
                            "SKIP_3" => 4,
                            "SKIP_4" => 5,
                            _ => return Err(fail("invalid instskip")),
                        },
                    )
                } else {
                    let shift = match field {
                        "instid0" => 0,
                        "instid1" => 7,
                        _ => return Err(fail("invalid dependency field")),
                    };
                    let value = match value {
                        "NO_DEP" => 0,
                        "VALU_DEP_1" => 1,
                        "VALU_DEP_2" => 2,
                        "VALU_DEP_3" => 3,
                        "VALU_DEP_4" => 4,
                        "TRANS32_DEP_1" => 5,
                        "TRANS32_DEP_2" => 6,
                        "TRANS32_DEP_3" => 7,
                        "FMA_ACCUM_CYCLE_1" => 8,
                        "SALU_CYCLE_1" => 9,
                        "SALU_CYCLE_2" => 10,
                        "SALU_CYCLE_3" => 11,
                        _ => return Err(fail("invalid ALU dependency")),
                    };
                    (shift, value)
                };
                encoded |= value << shift;
            }
            encoded
        };
        if encoded < 0
            || encoded >> 11 != 0
            || (encoded & 15) > 11
            || ((encoded >> 4) & 7) > 5
            || ((encoded >> 7) & 15) > 11
        {
            return Err(fail("invalid s_delay_alu encoding"));
        }
        return Ok(Some(Instruction {
            mnemonic: "s_delay_alu".into(),
            opcode: Opcode::Control,
            operands: vec![Operand::Integer(encoded)],
            modifiers: vec![],
            span,
        }));
    }
    if let Some(rest) = text.strip_prefix("s_getreg_b32 ") {
        let (destination, source) = rest
            .split_once(',')
            .ok_or_else(|| fail("s_getreg_b32 requires destination and hwreg"))?;
        let mut instruction = super::instr::parse_instruction(
            &format!("s_mov_b32 {}, 0", destination.trim()),
            span,
            Architecture::Gfx1250,
        )?;
        let args = source
            .trim()
            .strip_prefix("hwreg(")
            .and_then(|s| s.strip_suffix(')'))
            .ok_or_else(|| fail("invalid hardware register operand"))?
            .split(',')
            .map(str::trim)
            .collect::<Vec<_>>();
        if args.len() != 3 {
            return Err(fail("hwreg requires name,offset,width"));
        }
        let offset = args[1]
            .parse::<u8>()
            .map_err(|_| fail("invalid hwreg offset"))?;
        let width = args[2]
            .parse::<u8>()
            .map_err(|_| fail("invalid hwreg width"))?;
        if width == 0 || u16::from(offset) + u16::from(width) > 32 {
            return Err(fail("hwreg bit selection outside 32-bit register"));
        }
        instruction.mnemonic = "s_getreg_b32".into();
        instruction.operands[1] = Operand::HardwareRegister {
            name: args[0].into(),
            offset,
            width,
        };
        return Ok(Some(instruction));
    }
    Ok(None)
}
