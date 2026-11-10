//! Conservative reaching definitions for opaque, ordered code-address words.
//!
//! These are compile-time identities, not numeric register values. Only exact
//! scalar copies and literal lane transports can preserve them. Runtime still
//! checks the actual opaque words, source origin, target and active call frame.

use super::LowerError;
use crate::frontend::{Instruction, Operand};
use crate::ir::{CodeAddressSequence, FunctionRange, Opcode, Register, RegisterClass};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Cell {
    Scalar(u16),
    Lane(u16, u8),
}

#[derive(Clone, Copy, PartialEq, Eq)]
struct Word {
    anchor: usize,
    high: bool,
}

type Facts = BTreeMap<Cell, Word>;

fn plain(register: &Register, class: RegisterClass, count: u16) -> bool {
    register.class == class && register.count == count && register.special.is_none()
}

/// Include every explicit word, including sources and nested/modified operands.
/// Using mentions rather than inferred destinations deliberately overapproximates
/// writes. All implicit ALU destinations are special registers (EXEC/VCC/SCC),
/// outside the plain SGPR/literal VGPR cells tracked here. A call's saved-PC pair
/// is explicit. There are no admitted indirect register-file writes.
fn mentions(operand: &Operand, output: &mut BTreeSet<(u8, u16)>) {
    match operand {
        Operand::Register(register) if register.special.is_none() => {
            let file = match register.class {
                RegisterClass::Scalar => 0,
                RegisterClass::Vector => 1,
                _ => return,
            };
            for offset in 0..register.count {
                output.insert((file, register.index + offset));
            }
        }
        Operand::Modified { value, .. } => mentions(value, output),
        Operand::Dual(x, y) => {
            for operand in x.operands.iter().chain(&y.operands) {
                mentions(operand, output);
            }
        }
        _ => {}
    }
}

fn kill(facts: &mut Facts, touched: &BTreeSet<(u8, u16)>) {
    facts.retain(|cell, _| {
        let word = match *cell {
            Cell::Scalar(index) => (0, index),
            Cell::Lane(index, _) => (1, index),
        };
        !touched.contains(&word)
    });
}

fn copy(facts: &mut Facts, destination: Cell, source: Cell) {
    match facts.get(&source).copied() {
        Some(word) => {
            facts.insert(destination, word);
        }
        None => {
            facts.remove(&destination);
        }
    }
}

fn transport(instruction: &Instruction, facts: &mut Facts) -> bool {
    if !instruction.modifiers.is_empty() {
        return false;
    }
    match instruction.operands.as_slice() {
        [Operand::Register(destination), Operand::Register(source)]
            if matches!(instruction.mnemonic.as_str(), "s_mov_b32" | "s_mov_b64")
                && plain(destination, RegisterClass::Scalar, source.count)
                && plain(source, RegisterClass::Scalar, destination.count)
                && destination.count
                    == if instruction.mnemonic == "s_mov_b32" {
                        1
                    } else {
                        2
                    } =>
        {
            // Snapshot the complete source before writing an overlapping tuple.
            let words = (0..source.count)
                .map(|offset| facts.get(&Cell::Scalar(source.index + offset)).copied())
                .collect::<Vec<_>>();
            for (offset, word) in words.into_iter().enumerate() {
                let destination = Cell::Scalar(destination.index + offset as u16);
                facts.remove(&destination);
                if let Some(word) = word {
                    facts.insert(destination, word);
                }
            }
            true
        }
        [
            Operand::Register(destination),
            Operand::Register(source),
            Operand::Integer(lane @ 0..=63),
        ] if instruction.mnemonic == "v_writelane_b32"
            && plain(destination, RegisterClass::Vector, 1)
            && plain(source, RegisterClass::Scalar, 1) =>
        {
            copy(
                facts,
                Cell::Lane(destination.index, *lane as u8),
                Cell::Scalar(source.index),
            );
            true
        }
        [
            Operand::Register(destination),
            Operand::Register(source),
            Operand::Integer(lane @ 0..=63),
        ] if instruction.mnemonic == "v_readlane_b32"
            && plain(destination, RegisterClass::Scalar, 1)
            && plain(source, RegisterClass::Vector, 1) =>
        {
            copy(
                facts,
                Cell::Scalar(destination.index),
                Cell::Lane(source.index, *lane as u8),
            );
            true
        }
        _ => false,
    }
}

pub(super) fn resolve(
    instructions: &[Instruction],
    functions: &[FunctionRange],
    sequences: &BTreeMap<usize, CodeAddressSequence>,
) -> Result<BTreeMap<usize, usize>, LowerError> {
    let branch_entries = instructions
        .iter()
        .flat_map(|instruction| {
            instruction.operands.iter().filter_map(|operand| {
                if let Operand::BranchTarget(pc) = operand {
                    Some(*pc)
                } else {
                    None
                }
            })
        })
        .collect::<BTreeSet<_>>();
    // Every selected helper is included, not merely the immediate callee. This
    // safely covers transitive calls, either branch and all explicit wide tuple
    // words without assuming ABI-preserved registers. An untouched saved lane
    // cell survives; mentioning its VGPR anywhere in a helper kills every lane.
    let mut helper_touches = BTreeSet::new();
    for function in functions.iter().skip(1) {
        for instruction in &instructions[function.start..function.end] {
            for operand in &instruction.operands {
                mentions(operand, &mut helper_touches);
            }
        }
    }
    let finishes = sequences
        .values()
        .map(|sequence| (sequence.anchor_pc + 2, sequence))
        .collect::<BTreeMap<_, _>>();
    let mut targets = BTreeMap::new();
    for function in functions {
        let mut facts = Facts::new();
        for (offset, instruction) in instructions[function.start..function.end]
            .iter()
            .enumerate()
        {
            let pc = function.start + offset;
            let fail = |message: &str| LowerError {
                message: message.into(),
                span: instruction.span,
            };
            if branch_entries.contains(&pc) {
                facts.clear();
            }
            if instruction.mnemonic == "s_endpgm" && function.start != 0 {
                return Err(fail(
                    "device function cannot terminate its caller with s_endpgm",
                ));
            }
            if instruction.mnemonic == "s_setpc_b64" && function.start == 0 {
                return Err(fail("entry kernel has no caller return address"));
            }
            if let Some(sequence) = finishes.get(&pc) {
                // Canonical relocation validation already checks this boundary.
                // Keep the reaching-definition proof explicit as well: entering
                // at either add stage cannot manufacture an executed anchor.
                if sequence.anchor_pc < function.start
                    || branch_entries
                        .range(sequence.anchor_pc + 1..=pc)
                        .next()
                        .is_some()
                {
                    return Err(fail("alternate entry into code-address construction"));
                }
                for high in [false, true] {
                    facts.insert(
                        Cell::Scalar(sequence.register_pair.index + u16::from(high)),
                        Word {
                            anchor: sequence.anchor_pc,
                            high,
                        },
                    );
                }
                continue;
            }
            if instruction.mnemonic == "s_swappc_b64" {
                let [Operand::Register(saved), Operand::Register(target)] =
                    instruction.operands.as_slice()
                else {
                    return Err(fail("invalid call operands"));
                };
                let sequence = facts
                    .get(&Cell::Scalar(target.index))
                    .filter(|word| !word.high)
                    .and_then(|low| {
                        (facts.get(&Cell::Scalar(target.index + 1))
                            == Some(&Word { high: true, ..*low }))
                        .then(|| sequences.get(&low.anchor))
                        .flatten()
                    })
                    .filter(|sequence| {
                        sequence.register_pair == *target
                            && sequence.anchor_pc >= function.start
                            && sequence.anchor_pc + 2 < pc
                    })
                    .ok_or_else(|| {
                        fail("call target has no supported straight-line rel32 reaching definition")
                    })?;
                if pc + 1 >= function.end {
                    return Err(fail("call has no continuation in its source function"));
                }
                targets.insert(pc, sequence.target_pc);
                // s_swappc snapshots its target before defining the saved pair.
                let mut touched = helper_touches.clone();
                mentions(&Operand::Register(*saved), &mut touched);
                kill(&mut facts, &touched);
                continue;
            }
            if transport(instruction, &mut facts) {
                continue;
            }
            if instruction.opcode == Opcode::Branch
                || instruction.opcode == Opcode::Control
                    && !matches!(instruction.mnemonic.as_str(), "s_nop" | "v_nop")
            {
                facts.clear();
                continue;
            }
            let mut touched = BTreeSet::new();
            for operand in &instruction.operands {
                mentions(operand, &mut touched);
            }
            kill(&mut facts, &touched);
        }
    }
    Ok(targets)
}
