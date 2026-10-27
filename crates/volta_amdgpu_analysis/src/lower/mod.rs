//! Resolve local labels and constants without importing execution or checking.

use std::{error::Error, fmt};

use crate::ir::{Kernel, LoweredKernel, Module, Opcode, Operand, SourceSpan};

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

pub fn lower_kernel(kernel: &Kernel) -> Result<LoweredKernel, LowerError> {
    let mut instructions = kernel.instructions.clone();
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
    Ok(LoweredKernel {
        name: kernel.name.clone(),
        instructions,
        descriptor: kernel.descriptor.clone(),
        args: kernel.args.clone(),
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
    lower_kernel(kernel)
}
