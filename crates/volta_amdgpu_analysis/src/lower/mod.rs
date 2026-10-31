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
    let (program, functions) = compose_functions(module, kernel, architecture)?;
    lower_with_globals(&program, &module.globals, architecture, functions)
}

/// Keep source functions distinct while assigning deterministic executable PCs.
/// Relocation references select a conservative closure; unsupported helper bodies
/// cannot become executable prefixes, and labels never cross function bounds.
fn compose_functions(
    module: &Module,
    entry: &Kernel,
    architecture: crate::target::Architecture,
) -> Result<(Kernel, Vec<crate::ir::FunctionRange>), LowerError> {
    let fail = |message: String, span| LowerError { message, span };
    let mut catalog = BTreeMap::new();
    for function in &module.functions {
        if function.name == entry.name
            || module.kernels.iter().any(|k| k.name == function.name)
            || catalog.insert(function.name.as_str(), function).is_some()
        {
            return Err(fail(
                format!("ambiguous code symbol `{}`", function.name),
                function.span,
            ));
        }
    }
    let mut selected = std::collections::BTreeSet::new();
    let mut pending = vec![entry.instructions.as_slice()];
    while let Some(body) = pending.pop() {
        for instruction in body {
            for operand in &instruction.operands {
                if let Operand::Relocation(relocation) = operand {
                    if relocation.symbol == entry.name {
                        return Err(fail(
                            "recursive entry code reference is unsupported".into(),
                            instruction.span,
                        ));
                    }
                    if let Some(function) = catalog.get(relocation.symbol.as_str())
                        && selected.insert(function.name.as_str())
                    {
                        if architecture != crate::target::Architecture::Gfx950 {
                            return Err(fail(
                                "device functions require the selected gfx950 call profile".into(),
                                instruction.span,
                            ));
                        }
                        if let Some((message, span)) = &function.refusal {
                            return Err(fail(
                                format!("called function `{}`: {message}", function.name),
                                *span,
                            ));
                        }
                        pending.push(&function.instructions);
                    }
                }
            }
        }
    }
    let mut program = entry.clone();
    program.instructions.clear();
    program.labels.clear();
    let mut ranges = Vec::new();
    let bodies = std::iter::once((entry.name.as_str(), &entry.instructions, &entry.labels)).chain(
        selected.iter().map(|name| {
            let function = catalog[name];
            (
                function.name.as_str(),
                &function.instructions,
                &function.labels,
            )
        }),
    );
    for (name, body, labels) in bodies {
        let start = program.instructions.len();
        let end = start
            .checked_add(body.len())
            .filter(|end| *end <= u32::MAX as usize)
            .ok_or_else(|| {
                fail(
                    "code exceeds program-point range".into(),
                    SourceSpan::default(),
                )
            })?;
        if body.is_empty()
            || (name != entry.name
                && !matches!(
                    body.last().unwrap().mnemonic.as_str(),
                    "s_setpc_b64" | "s_branch"
                ))
            || (!selected.is_empty()
                && name == entry.name
                && !matches!(
                    body.last().unwrap().mnemonic.as_str(),
                    "s_endpgm" | "s_branch"
                ))
        {
            return Err(fail(
                format!("function `{name}` has no explicit supported terminator"),
                body.last().map(|i| i.span).unwrap_or_default(),
            ));
        }
        for (label, pc) in labels {
            if *pc > body.len() {
                return Err(fail(
                    format!("invalid label `{label}` in `{name}`"),
                    SourceSpan::default(),
                ));
            }
            program
                .labels
                .insert(format!("{name}::{label}"), start + pc);
        }
        for original in body {
            let mut instruction = original.clone();
            if instruction.opcode == Opcode::Branch
                && let Some(Operand::Symbol(label)) = instruction.operands.first_mut()
            {
                let local = labels.get(label).ok_or_else(|| {
                    fail(
                        format!("undefined branch label `{label}` in source function `{name}`"),
                        instruction.span,
                    )
                })?;
                if *local >= body.len() {
                    return Err(fail(
                        "branch target falls outside its source function".into(),
                        instruction.span,
                    ));
                }
                *label = format!("{name}::{label}");
            }
            program.instructions.push(instruction);
        }
        ranges.push(crate::ir::FunctionRange {
            name: name.into(),
            start,
            end,
        });
    }
    Ok((program, ranges))
}

fn lower_with_globals(
    kernel: &Kernel,
    globals: &[Global],
    architecture: crate::target::Architecture,
    functions: Vec<crate::ir::FunctionRange>,
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
            if let Operand::Symbol(symbol) = operand
                && instruction.opcode != Opcode::Branch
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
    let mut code_address_sequences = BTreeMap::new();
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
            && (code_address_sequences.contains_key(&(pc - 2))
                || global_address_sequences.get(&(pc - 2)).is_some_and(
                    |sequence: &GlobalAddressSequence| {
                        sequence.form == GlobalAddressForm::SplitRel32
                    },
                ))
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
        if let Some(function) = functions
            .iter()
            .skip(1)
            .find(|function| function.name == symbol)
        {
            if architecture != crate::target::Architecture::Gfx950 || form != GlobalAddressForm::SplitRel32
                || globals.iter().any(|global| global.symbol == symbol)
                || !functions.iter().any(|function| function.start <= anchor_pc && final_pc < function.end)
                || instructions.iter().any(|item| item.operands.iter().any(|operand|
                    matches!(operand, Operand::BranchTarget(target) if (pc..=final_pc).contains(target)))) {
                return Err(fail("invalid selected code-address construction"));
            }
            code_address_sequences.insert(
                anchor_pc,
                crate::ir::CodeAddressSequence {
                    anchor_pc,
                    register_pair: *pair,
                    target_pc: function.start,
                },
            );
            continue;
        }
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
    let mut call_targets = BTreeMap::new();
    for (pc, instruction) in instructions.iter().enumerate() {
        let function = functions
            .iter()
            .find(|f| f.start <= pc && pc < f.end)
            .unwrap();
        if instruction.mnemonic == "s_endpgm" && function.start != 0 {
            return Err(LowerError {
                message: "device function cannot terminate its caller with s_endpgm".into(),
                span: instruction.span,
            });
        }
        if instruction.mnemonic == "s_setpc_b64" && function.start == 0 {
            return Err(LowerError {
                message: "entry kernel has no caller return address".into(),
                span: instruction.span,
            });
        }
        if instruction.mnemonic != "s_swappc_b64" {
            continue;
        }
        let [Operand::Register(_), Operand::Register(target)] = instruction.operands.as_slice()
        else {
            return Err(LowerError {
                message: "invalid call operands".into(),
                span: instruction.span,
            });
        };
        let sequence = code_address_sequences.values().rev().find(|sequence| {
            let finish = sequence.anchor_pc + 2;
            if sequence.register_pair != *target || sequence.anchor_pc < function.start || finish >= pc { return false; }
            // A conservative straight-line reaching-definition certificate.
            // Any mention of either word, call, branch or alternate entry after
            // construction refuses this selected form instead of guessing def-use.
            !instructions[finish + 1..pc].iter().any(|item| {
                matches!(item.opcode, Opcode::Branch | Opcode::Control)
                    || item.operands.iter().any(|operand| matches!(operand, Operand::Register(r)
                        if r.class == RegisterClass::Scalar && r.index < target.index + 2 && target.index < r.index + r.count))
            }) && !instructions.iter().any(|item| item.operands.iter().any(|operand|
                matches!(operand, Operand::BranchTarget(destination) if (sequence.anchor_pc + 1..=pc).contains(destination))))
        }).ok_or_else(|| LowerError { message: "call target has no supported straight-line rel32 reaching definition".into(), span: instruction.span })?;
        if pc + 1 >= function.end {
            return Err(LowerError {
                message: "call has no continuation in its source function".into(),
                span: instruction.span,
            });
        }
        call_targets.insert(pc, sequence.target_pc);
    }
    // Reject recursive call graphs; bounded explicit frames then need at most
    // one frame per helper, independent of the instruction budget.
    let mut edges: BTreeMap<usize, std::collections::BTreeSet<usize>> = functions
        .iter()
        .map(|function| (function.start, std::collections::BTreeSet::new()))
        .collect();
    let mut incoming: BTreeMap<usize, usize> = functions
        .iter()
        .map(|function| (function.start, 0))
        .collect();
    for function in &functions {
        for (_, target) in call_targets.range(function.start..function.end) {
            if edges.get_mut(&function.start).unwrap().insert(*target) {
                *incoming.get_mut(target).unwrap() += 1;
            }
        }
    }
    let mut ready = incoming
        .iter()
        .filter_map(|(pc, count)| (*count == 0).then_some(*pc))
        .collect::<Vec<_>>();
    let mut visited = 0;
    while let Some(pc) = ready.pop() {
        visited += 1;
        for target in &edges[&pc] {
            let count = incoming.get_mut(target).unwrap();
            *count -= 1;
            if *count == 0 {
                ready.push(*target);
            }
        }
    }
    if visited != functions.len() {
        return Err(LowerError {
            message: "recursive device calls are unsupported".into(),
            span: SourceSpan::default(),
        });
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
        functions,
        code_address_sequences,
        call_targets,
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
