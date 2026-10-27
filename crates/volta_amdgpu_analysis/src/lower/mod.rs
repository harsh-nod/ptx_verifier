//! Resolve local labels and constants without importing execution or checking.

use std::{collections::BTreeMap, error::Error, fmt};

use crate::ir::{
    Global, GlobalAddressSequence, Kernel, LoweredKernel, Module, Opcode, Operand, Register,
    RegisterClass, RelocationKind, SourceSpan,
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

pub fn lower_kernel(kernel: &Kernel) -> Result<LoweredKernel, LowerError> {
    lower_with_globals(kernel, &[])
}

pub fn lower_kernel_in_module(
    module: &Module,
    kernel: &Kernel,
) -> Result<LoweredKernel, LowerError> {
    lower_with_globals(kernel, &module.globals)
}

fn lower_with_globals(kernel: &Kernel, globals: &[Global]) -> Result<LoweredKernel, LowerError> {
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
        // A high relocation is visited after its already-validated low stage.
        if pc >= 2 && global_address_sequences.contains_key(&(pc - 2)) {
            continue;
        }
        let Some(anchor) = instructions.get(anchor_pc) else {
            unreachable!()
        };
        let Some(high) = instructions.get(pc + 1) else {
            return Err(fail("incomplete split PC-relative relocation sequence"));
        };
        let [Operand::Register(pair)] = anchor.operands.as_slice() else {
            return Err(fail("PC-relative relocation requires an SGPR pair anchor"));
        };
        if anchor.mnemonic != "s_getpc_b64"
            || pair.class != RegisterClass::Scalar
            || pair.count != 2
            || pair.special.is_some()
            || !anchor.modifiers.is_empty()
            || !instruction.modifiers.is_empty()
            || !high.modifiers.is_empty()
        {
            return Err(fail("unsupported PC-relative anchor or modifiers"));
        }
        let low_register = Register { count: 1, ..*pair };
        let high_register = Register {
            index: pair.index + 1,
            count: 1,
            ..*pair
        };
        let [
            Operand::Register(low_dst),
            Operand::Register(low_src),
            Operand::Relocation(low),
        ] = instruction.operands.as_slice()
        else {
            return Err(fail("invalid low PC-relative relocation stage"));
        };
        let [
            Operand::Register(high_dst),
            Operand::Register(high_src),
            Operand::Relocation(high_reloc),
        ] = high.operands.as_slice()
        else {
            return Err(fail("invalid high PC-relative relocation stage"));
        };
        if instruction.mnemonic != "s_add_u32"
            || high.mnemonic != "s_addc_u32"
            || *low_dst != low_register
            || *low_src != low_register
            || *high_dst != high_register
            || *high_src != high_register
            || low.kind != RelocationKind::Rel32Lo
            || high_reloc.kind != RelocationKind::Rel32Hi
            || low.addend != 4
            || high_reloc.addend != 12
            || low.symbol != high_reloc.symbol
        {
            return Err(fail(
                "only exact matching rel32 lo+4/hi+12 address construction is modeled",
            ));
        }
        let Some(global) = globals.iter().find(|global| global.symbol == low.symbol) else {
            return Err(fail(
                "PC-relative relocation names an undefined or unbounded module object",
            ));
        };
        if global.size == 0
            || global.initial_bytes.len() as u64 != global.size
            || global.alignment == 0
            || !global.alignment.is_power_of_two()
            || globals
                .iter()
                .filter(|item| item.symbol == low.symbol)
                .count()
                != 1
        {
            return Err(fail(
                "PC-relative object has invalid size, alignment or ambiguous identity",
            ));
        }
        if instructions.iter().any(|item| {
            item.operands.iter().any(|operand|
            matches!(operand, Operand::BranchTarget(target) if *target == pc || *target == pc + 1))
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
                symbol: low.symbol.clone(),
            },
        );
    }
    Ok(LoweredKernel {
        name: kernel.name.clone(),
        instructions,
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
