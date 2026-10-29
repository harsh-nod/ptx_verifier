//! Architecture boundaries for the supported native AMD subset.
//!
//! LLVM's AMDGPU processor features and AMD's CDNA3/CDNA4 ISA manuals define
//! the distinction here. In particular, identical FP8 mnemonic spellings do
//! not imply identical number formats on gfx942 and gfx950.

use crate::frontend::{Module, Opcode, ParseError, SourceSpan};
pub use volta_graph::AmdArchitecture as Architecture;

/// Validate target-specific syntax even for caller-constructed typed modules.
/// A missing directive retains the original gfx950 default.
pub fn validate(module: &Module) -> Result<Architecture, ParseError> {
    let target = module.target.as_deref().unwrap_or("gfx950");
    let architecture = Architecture::from_target(target).ok_or_else(|| ParseError {
        message: format!(
            "unsupported or conflicting AMD target `{target}`; expected gfx942, gfx950 or gfx1250"
        ),
        span: SourceSpan::default(),
    })?;
    // Caller-built typed modules receive the same generation profile as text
    // input. Changing their target/descriptor cannot bypass syntax dispatch.
    if architecture != Architecture::Gfx1250 {
        fn native_operand(operand: &crate::frontend::Operand) -> bool {
            use crate::frontend::{Operand, RegisterClass};
            match operand {
                Operand::HardwareRegister { .. } | Operand::Dual(..) => true,
                Operand::Register(r) => r.class == RegisterClass::Temporary,
                Operand::Modified { value, .. } => native_operand(value),
                _ => false,
            }
        }
        for kernel in &module.kernels {
            for instruction in &kernel.instructions {
                if crate::frontend::gfx1250::signature(&instruction.mnemonic).is_some()
                    || instruction.operands.iter().any(native_operand)
                    || instruction
                        .modifiers
                        .iter()
                        .any(|m| matches!(m.name.as_str(), "scale_offset" | "byte_sel" | "scope"))
                {
                    return Err(ParseError {
                        message: format!(
                            "{} requires the gfx1250 instruction profile",
                            instruction.mnemonic
                        ),
                        span: instruction.span,
                    });
                }
            }
        }
    }
    for kernel in &module.kernels {
        let wave32 = architecture == Architecture::Gfx1250;
        if kernel.descriptor.flag("wavefront_size32") != wave32 {
            return Err(ParseError {
                message: format!(
                    "{} requires wave{}",
                    architecture.name(),
                    architecture.wave_size()
                ),
                span: SourceSpan::default(),
            });
        }
        for (key, limit) in [
            ("next_free_vgpr", if wave32 { 1024 } else { 512 }),
            ("next_free_sgpr", if wave32 { 106 } else { 102 }),
        ] {
            if kernel.descriptor.value(key, 0) > limit {
                return Err(ParseError {
                    message: format!("{key} exceeds {} limit", architecture.name()),
                    span: SourceSpan::default(),
                });
            }
        }
    }
    if architecture == Architecture::Gfx1250 {
        for kernel in &module.kernels {
            for instruction in &kernel.instructions {
                crate::frontend::gfx1250::validate_typed_profile(instruction).map_err(
                    |message| ParseError {
                        message,
                        span: instruction.span,
                    },
                )?;
                fn registers(
                    operand: &crate::frontend::Operand,
                    out: &mut Vec<crate::frontend::Register>,
                ) {
                    use crate::frontend::Operand;
                    match operand {
                        Operand::Register(r) => out.push(*r),
                        Operand::Modified { value, .. } => registers(value, out),
                        Operand::Dual(x, y) => {
                            for op in x.operands.iter().chain(&y.operands) {
                                registers(op, out)
                            }
                        }
                        _ => {}
                    }
                }
                let mut used = Vec::new();
                for operand in &instruction.operands {
                    registers(operand, &mut used);
                }
                for register in used {
                    if register.class == crate::frontend::RegisterClass::Accumulator {
                        return Err(ParseError {
                            message: "gfx1250 has no AGPR register namespace".into(),
                            span: instruction.span,
                        });
                    }
                    if register.class == crate::frontend::RegisterClass::Vector
                        && register.index as u32 + register.count as u32 > 256
                    {
                        return Err(ParseError{message:"higher gfx1250 VGPR allocation requires a banked encoding profile which is not implemented; this is not a logical allocation limit".into(),span:instruction.span});
                    }
                }
                if instruction.mnemonic.starts_with("v_mfma")
                    || instruction.mnemonic.starts_with("v_accvgpr")
                    || instruction.mnemonic == "s_waitcnt"
                    || instruction.mnemonic == "s_barrier"
                {
                    return Err(ParseError {
                        message: format!("{} is not a gfx1250 instruction", instruction.mnemonic),
                        span: instruction.span,
                    });
                }
            }
        }
        return Ok(architecture);
    }
    if architecture == Architecture::Gfx950 {
        return Ok(architecture);
    }
    for kernel in &module.kernels {
        for instruction in &kernel.instructions {
            let name = instruction
                .mnemonic
                .trim_end_matches("_e32")
                .trim_end_matches("_e64")
                .trim_end_matches("_sdwa");
            let reason = if name.contains("fp8") || name.contains("bf8") {
                Some("gfx942 FP8/BF8 uses FNUZ formats; the current OCP decoder is gfx950-only")
            } else if instruction.opcode == Opcode::Matrix
                && !matches!(
                    name,
                    "v_mfma_f32_16x16x4_f32"
                        | "v_mfma_f32_16x16x4f32"
                        | "v_mfma_f32_32x32x2_f32"
                        | "v_mfma_f32_32x32x2f32"
                        | "v_mfma_f32_16x16x16_f16"
                        | "v_mfma_f32_16x16x16f16"
                        | "v_mfma_f32_32x32x8_f16"
                        | "v_mfma_f32_32x32x8f16"
                        | "v_mfma_f32_16x16x16bf16_1k"
                        | "v_mfma_f32_32x32x8bf16_1k"
                )
            {
                Some("MFMA form is outside the implemented gfx942 instruction subset")
            } else if matches!(
                name,
                "v_bitop3_b32"
                    | "v_cvt_pk_f16_f32"
                    | "v_cvt_f32_bf16"
                    | "v_cvt_bf16_f32"
                    | "v_cvt_pk_bf16_f32"
            ) {
                Some("instruction requires CDNA4 features absent on gfx942")
            } else {
                None
            };
            if let Some(reason) = reason {
                return Err(ParseError {
                    message: format!(
                        "unsupported gfx942 instruction `{}`: {reason}",
                        instruction.mnemonic
                    ),
                    span: instruction.span,
                });
            }
        }
    }
    Ok(architecture)
}
