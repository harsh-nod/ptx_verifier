//! Resolve local labels and constants without importing execution or checking.

use std::{collections::BTreeMap, error::Error, fmt};

use crate::frontend::Operand;
use crate::ir::{
    Global, GlobalAddressForm, GlobalAddressSequence, Instruction as LoweredInstruction, Kernel,
    LoweredKernel, Module, Opcode, Register, RegisterClass, RelocationKind, SourceSpan,
};

#[cfg(test)]
mod tests;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LowerError {
    pub message: String,
    pub span: SourceSpan,
}

impl fmt::Display for LowerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{}:{}: {}",
            self.span.line, self.span.column, self.message
        )
    }
}

impl Error for LowerError {}

/// Lower without module globals. Wave64 retains the gfx950 default; wave32
/// descriptors select the gfx1250 profile. Explicit gfx942 requires a module.
pub fn lower_kernel(kernel: &Kernel) -> Result<LoweredKernel, LowerError> {
    let target = if kernel.descriptor.flag("wavefront_size32") {
        "gfx1250"
    } else {
        "gfx950"
    };
    let context = Module {
        target: Some(target.into()),
        kernels: vec![kernel.clone()],
        ..Module::default()
    };
    lower_kernel_in_module(&context, &context.kernels[0])
}

pub fn lower_kernel_in_module(
    module: &Module,
    kernel: &Kernel,
) -> Result<LoweredKernel, LowerError> {
    let architecture = crate::target::validate(module).map_err(|error| LowerError {
        message: error.message,
        span: error.span,
    })?;
    // The public API may receive a kernel other than a member of `module`.
    // Its descriptor and instructions need the same selected-target contract.
    if !module
        .kernels
        .iter()
        .any(|entry| std::ptr::eq(entry, kernel))
    {
        let context = Module {
            target: module.target.clone(),
            kernels: vec![kernel.clone()],
            ..Module::default()
        };
        crate::target::validate(&context).map_err(|error| LowerError {
            message: error.message,
            span: error.span,
        })?;
    }
    lower_with_globals(kernel, &module.globals, architecture)
}

fn lower_with_globals(
    kernel: &Kernel,
    globals: &[Global],
    architecture: crate::target::Architecture,
) -> Result<LoweredKernel, LowerError> {
    let allow_rel64 = architecture == crate::target::Architecture::Gfx1250;
    let mut instructions = kernel.instructions.clone();
    for instruction in &mut instructions {
        crate::frontend::normalize_for_lowering(instruction).map_err(|error| LowerError {
            message: error.message,
            span: error.span,
        })?;
        crate::frontend::validate_for_lowering(instruction, architecture).map_err(|error| {
            LowerError {
                message: error.message,
                span: error.span,
            }
        })?;
    }
    // Descriptor validation runs only after all register shapes are safe.
    let validated = Kernel {
        instructions: instructions.clone(),
        ..kernel.clone()
    };
    crate::frontend::validate_descriptor_for_lowering(&validated).map_err(|error| LowerError {
        message: error.message,
        span: error.span,
    })?;
    let instruction_count = instructions.len();
    for instruction in &mut instructions {
        for operand in &instruction.operands {
            if let Operand::Symbol(symbol) = operand {
                if instruction.opcode != Opcode::Branch
                    && !(instruction.opcode == Opcode::VectorMemory && symbol == "off")
                {
                    return Err(LowerError {
                        message: format!(
                            "unresolved assembly symbol or unsupported relocation `{symbol}`"
                        ),
                        span: instruction.span,
                    });
                }
            }
        }
        if instruction.opcode != Opcode::Branch {
            continue;
        }
        let Some(Operand::Symbol(label)) = instruction.operands.first() else {
            return Err(LowerError {
                message: "branch requires a local label".into(),
                span: instruction.span,
            });
        };
        let pc = kernel.labels.get(label).ok_or_else(|| LowerError {
            message: format!("undefined branch label `{label}`"),
            span: instruction.span,
        })?;
        if *pc >= instruction_count {
            return Err(LowerError {
                message: format!("branch label `{label}` has no executable instruction"),
                span: instruction.span,
            });
        }
        instruction.operands[0] = Operand::BranchTarget(*pc);
    }
    let mut global_address_sequences = BTreeMap::new();
    for (pc, instruction) in instructions.iter().enumerate() {
        if !instruction
            .operands
            .iter()
            .any(|operand| matches!(operand, Operand::Relocation(_)))
        {
            continue;
        }
        let fail = |message: &str| LowerError {
            message: message.into(),
            span: instruction.span,
        };
        let Some(anchor_pc) = pc.checked_sub(1) else {
            return Err(fail(
                "relocation is not part of a canonical getpc/add/addc sequence",
            ));
        };
        // The high word belongs to an already validated three-instruction profile.
        if pc >= 2
            && global_address_sequences.get(&(pc - 2)).is_some_and(
                |sequence: &GlobalAddressSequence| sequence.form == GlobalAddressForm::SplitRel32,
            )
        {
            continue;
        }
        let anchor = &instructions[anchor_pc];
        let [Operand::Register(pair)] = anchor.operands.as_slice() else {
            return Err(fail("PC-relative relocation requires an SGPR pair anchor"));
        };
        if pair.class != RegisterClass::Scalar
            || pair.count != 2
            || pair.special.is_some()
            || !anchor.modifiers.is_empty()
            || !instruction.modifiers.is_empty()
        {
            return Err(fail("unsupported PC-relative anchor or modifiers"));
        }
        let [
            Operand::Register(destination),
            Operand::Register(source),
            Operand::Relocation(relocation),
        ] = instruction.operands.as_slice()
        else {
            return Err(fail("invalid PC-relative relocation stage"));
        };
        let (form, symbol, final_pc) = if relocation.kind == RelocationKind::Rel64 {
            if !allow_rel64
                || anchor.mnemonic != "s_get_pc_i64"
                || instruction.mnemonic != "s_add_nc_u64"
                || destination != pair
                || source != pair
                || relocation.addend != 4
            {
                return Err(fail(
                    "only the gfx1250 get_pc/add_nc matching rel64+4 profile is modeled",
                ));
            }
            (GlobalAddressForm::Rel64, relocation.symbol.as_str(), pc)
        } else {
            let Some(high) = instructions.get(pc + 1) else {
                return Err(fail("incomplete split PC-relative relocation sequence"));
            };
            let low_register = Register { count: 1, ..*pair };
            let high_register = Register {
                index: pair.index + 1,
                count: 1,
                ..*pair
            };
            let [
                Operand::Register(high_dst),
                Operand::Register(high_src),
                Operand::Relocation(high_reloc),
            ] = high.operands.as_slice()
            else {
                return Err(fail("invalid high PC-relative relocation stage"));
            };
            if anchor.mnemonic != "s_getpc_b64"
                || instruction.mnemonic != "s_add_u32"
                || high.mnemonic != "s_addc_u32"
                || !high.modifiers.is_empty()
                || *destination != low_register
                || *source != low_register
                || *high_dst != high_register
                || *high_src != high_register
                || relocation.kind != RelocationKind::Rel32Lo
                || high_reloc.kind != RelocationKind::Rel32Hi
                || relocation.addend != 4
                || high_reloc.addend != 12
                || relocation.symbol != high_reloc.symbol
            {
                return Err(fail(
                    "only exact matching rel32 lo+4/hi+12 address construction is modeled",
                ));
            }
            (
                GlobalAddressForm::SplitRel32,
                relocation.symbol.as_str(),
                pc + 1,
            )
        };
        let Some(global) = globals.iter().find(|global| global.symbol == symbol) else {
            return Err(fail(
                "PC-relative relocation names an undefined or unbounded module object",
            ));
        };
        if global.size == 0
            || global.initial_bytes.len() as u64 != global.size
            || global.alignment == 0
            || !global.alignment.is_power_of_two()
            || globals.iter().filter(|item| item.symbol == symbol).count() != 1
        {
            return Err(fail(
                "PC-relative object has invalid size, alignment or ambiguous identity",
            ));
        }
        if instructions.iter().any(|item| {
            item.operands.iter().any(|operand|
            matches!(operand, Operand::BranchTarget(target) if (pc..=final_pc).contains(target)))
        }) {
            return Err(fail(
                "branch target enters the middle of a PC-relative address sequence",
            ));
        }
        global_address_sequences.insert(
            anchor_pc,
            GlobalAddressSequence {
                anchor_pc,
                register_pair: *pair,
                symbol: symbol.to_string(),
                form,
            },
        );
    }
    Ok(LoweredKernel {
        name: kernel.name.clone(),
        instructions: instructions
            .iter()
            .map(|instruction| {
                LoweredInstruction::lower(instruction).map_err(|message| LowerError {
                    message,
                    span: instruction.span,
                })
            })
            .collect::<Result<_, _>>()?,
        descriptor: kernel.descriptor.clone(),
        args: kernel.args.clone(),
        globals: globals.to_vec(),
        global_address_sequences,
    })
}

/// Convenience entry point for consumers selecting a kernel by its export name.
pub fn lower_module_kernel(module: &Module, name: &str) -> Result<LoweredKernel, LowerError> {
    let kernel = module
        .kernels
        .iter()
        .find(|kernel| kernel.name == name)
        .ok_or_else(|| LowerError {
            message: format!("kernel `{name}` not found"),
            span: SourceSpan::default(),
        })?;
    lower_kernel_in_module(module, kernel)
}
