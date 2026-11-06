//! Finite gfx950 scratch and opaque-private-aperture FLAT share per-item words.
//!
//! CDNA4 9.1.10.2/10.5 and pinned LLVM FLATInstructions.td. The backing
//! extent is a declared valid-dispatch premise, not a discovered host address.
//! Store visibility/source overwrite and load-result use/overwrite require
//! explicit VM0; private FLAT additionally requires LGKM0. Both waits must
//! follow the issued operation. Violations of this conservative admission
//! profile are Unsupported, never evidence of a hardware bug.
use super::*;

/// Recognizing an old assembly form does not admit it for execution. Scan the
/// complete selected entry/called closure, including unreachable instructions,
/// before the scheduler, any Instruction record or an observer callback. The
/// immutable source identity retains suffix/encoding and modifiers; lane B32
/// operands have no f64/implicit-operand source normalization.
pub(super) fn admit_lane_program(
    program: &LoweredKernel,
    architecture: AmdArchitecture,
) -> Result<(), EvalError> {
    if architecture != AmdArchitecture::Gfx950 {
        return Ok(());
    }
    for (pc, instruction) in program.instructions.iter().enumerate() {
        let (read, name) = match instruction.alu_operation() {
            Some(AluOperation::VReadlaneB32) => (true, "v_readlane_b32"),
            Some(AluOperation::VWritelaneB32) => (false, "v_writelane_b32"),
            _ => continue,
        };
        if instruction.mnemonic() != name
            || instruction.source().encoding != Encoding::Default
            || !instruction.modifiers().is_empty()
            || !matches!(instruction.operands(),
                [Operand::Register(destination), Operand::Register(source), Operand::Integer(0..=63)]
                    if destination.count == 1 && source.count == 1
                        && destination.special.is_none() && source.special.is_none()
                        && destination.class == if read { RegisterClass::Scalar } else { RegisterClass::Vector }
                        && source.class == if read { RegisterClass::Vector } else { RegisterClass::Scalar })
        {
            return Err(EvalError::Unsupported {
                pc,
                what: "selected gfx950 lane execution requires bare plain SGPR/VGPR words and a literal lane 0..63".into(),
            });
        }
    }
    Ok(())
}

pub(super) fn lane(wave: &Wave, instruction: &Instruction) -> Result<u8, EvalError> {
    let Some(Operand::Integer(lane @ 0..=63)) = instruction.operands().get(2) else {
        return Err(wave.fail(None, "selected lane transport requires a literal lane"));
    };
    let lane = *lane as u8;
    if wave.valid & (1u64 << lane) == 0 {
        return Err(EvalError::Unsupported {
            pc: wave.pc,
            what: "selected lane transport cannot access a lane outside the launch".into(),
        });
    }
    Ok(lane)
}

#[derive(Default)]
pub(super) struct State {
    pub(super) extent: Option<u32>,
    cells: BTreeMap<(u32, u8, u32), Value>,
    pending_stores: BTreeMap<u32, Vec<AmdRegister>>,
    pending_loads: BTreeMap<u32, Vec<AmdRegister>>,
    completion: BTreeMap<u32, u8>,
}

impl State {
    pub(super) fn new(
        program: &LoweredKernel,
        architecture: AmdArchitecture,
    ) -> Result<Self, EvalError> {
        if !program.instructions.iter().any(|instruction| {
            matches!(instruction.operation(), Operation::Memory(memory)
                if matches!(memory.kind, MemoryKind::ScratchLoad | MemoryKind::ScratchStore))
                || instruction.operands().iter().any(|operand| matches!(operand, Operand::Register(r) if r.special == Some(SpecialRegister::PrivateBase)))
        }) {
            return Ok(Self::default());
        }
        let extent = program
            .descriptor
            .get("private_segment_fixed_size")
            .and_then(|bytes| u32::try_from(bytes).ok())
            .filter(|&bytes| bytes != 0);
        if architecture != AmdArchitecture::Gfx950
            || !program.descriptor.flag("enable_private_segment")
            || extent.is_none()
            || extent.is_some_and(|bytes| {
                program.descriptor.private_segment_fixed_size_sources
                    != Some((u64::from(bytes), u64::from(bytes)))
            })
        {
            return Err(EvalError::InvalidConfig(
                "selected gfx950 scratch requires enabled private memory and an explicit positive fixed private extent matching code-object metadata".into(),
            ));
        }
        Ok(Self {
            extent,
            ..Self::default()
        })
    }

    pub(super) fn before_instruction(
        &self,
        wave: &Wave,
        instruction: &Instruction,
        reads: &[AmdRegister],
        writes: &[AmdRegister],
    ) -> Result<(), EvalError> {
        let held = self
            .pending_stores
            .get(&wave.id)
            .map_or(&[][..], Vec::as_slice);
        let pending = self
            .pending_loads
            .get(&wave.id)
            .map_or(&[][..], Vec::as_slice);
        let dependent_load = wave.exec != 0
            && matches!(instruction.operation(), Operation::Memory(memory)
                if memory.kind == MemoryKind::ScratchLoad
                    || memory.kind == MemoryKind::FlatLoad && private_address(wave, memory).is_some());
        let end = matches!(instruction.operation(), Operation::Control(control)
            if control.operation == ControlOperation::EndProgram);
        // Private classes use conservative independent completion slots. Even
        // an ordinary destination can rely on mixed NoSampler FIFO ordering,
        // so do not admit a partial/max VM wait while private work is pending.
        let nonzero_vm_wait = matches!(instruction.operation(),
            Operation::Wait(WaitInstruction::Cdna { vmcnt: Some(threshold), .. })
                if *threshold != 0);
        if (!held.is_empty() && dependent_load)
            || (end && (!held.is_empty() || !pending.is_empty()))
            || (nonzero_vm_wait && (!held.is_empty() || !pending.is_empty()))
            || writes
                .iter()
                .any(|write| held.iter().any(|source| write.overlaps(*source)))
            || reads.iter().chain(writes).any(|register| {
                pending
                    .iter()
                    .any(|destination| register.overlaps(*destination))
            })
        {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "selected private-memory profile requires explicit VM0 before a dependent private load, stored-source overwrite, loaded-destination use/overwrite, END or nonzero VM wait with private work pending".into(),
            });
        }
        Ok(())
    }

    pub(super) fn complete(&mut self, wave: u32, vm: bool, lgkm: bool) {
        if let Some(remaining) = self.completion.get_mut(&wave) {
            *remaining &= !((u8::from(vm)) | (u8::from(lgkm) << 1));
            if *remaining != 0 {
                return;
            }
            self.completion.remove(&wave);
            self.pending_stores.remove(&wave);
            self.pending_loads.remove(&wave);
        }
    }
}

fn private_address(wave: &Wave, memory: &MemoryInstruction) -> Option<Register> {
    let address = &memory.operands()[usize::from(memory.kind == MemoryKind::FlatLoad)];
    let Operand::Register(register) = address else {
        return None;
    };
    (register.class == RegisterClass::Vector
        && register.count == 2
        && wave
            .active()
            .any(|lane| wave.reg(*register, lane, 1).ok() == Some(Value::PrivateApertureHi)))
    .then_some(*register)
}

impl Interpreter<'_> {
    pub(super) fn private_lane(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        let lane = lane(wave, instruction)?;
        let read = instruction.alu_operation() == Some(AluOperation::VReadlaneB32);
        let source = wave.destination(&instruction.operands()[1])?;
        let destination = wave.destination(&instruction.operands()[0])?;
        let source_lane = if read { lane } else { 0 };
        let value = if self.private.extent.is_some() {
            wave.spill_word(source, source_lane)?
        } else {
            wave.reg(source, source_lane, 0)?
        };
        // Literal lane moves ignore EXEC, including when it is empty. They
        // copy one exact word and never turn opaque or unknown bits into data.
        wave.put(destination, if read { 0 } else { lane }, 0, value)?;
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            if read {
                AmdEventKind::LaneRead { lane }
            } else {
                AmdEventKind::LaneWrite { lane }
            },
        );
        Ok(())
    }

    pub(super) fn scratch(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        memory: &MemoryInstruction,
    ) -> Result<(), EvalError> {
        if self.architecture != AmdArchitecture::Gfx950 || self.xnack_replay_enabled {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec == 0 {
            return Ok(());
        }
        let MemoryAddress::Scratch { scalar } = memory.address() else {
            unreachable!("typed scratch address")
        };
        let scalar = u64::from(wave.bits(scalar, 0)?);
        let immediate = self.private_offset(wave, instruction)?;
        let address = i128::from(scalar) + i128::from(immediate);
        let addresses = wave
            .active()
            .map(|lane| (lane, address))
            .collect::<Vec<_>>();
        self.private_transfer(wave, instruction, memory, &addresses, false)
    }

    /// Select only a proven private aperture. Numeric high words retain the
    /// ordinary FLAT path; a mixed aperture issue is outside this finite model.
    pub(super) fn flat_private(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        memory: &MemoryInstruction,
    ) -> Result<bool, EvalError> {
        if wave.exec == 0 {
            return Ok(false);
        }
        let Some(address) = private_address(wave, memory) else {
            return Ok(false);
        };
        if self.architecture != AmdArchitecture::Gfx950
            || self.xnack_replay_enabled
            || memory.operands().len() != 2
            || instruction
                .modifiers()
                .iter()
                .any(|m| match m.name.as_str() {
                    "offset" => m
                        .value
                        .as_deref()
                        .and_then(parse_i64)
                        .is_none_or(|n| !(0..=4095).contains(&n)),
                    "sc0" | "sc1" => m.value.is_some(),
                    _ => true,
                })
            || instruction.modifiers().iter().any(|m| m.name == "sc0")
                != instruction.modifiers().iter().any(|m| m.name == "sc1")
        {
            return Err(self.unsupported(wave, instruction));
        }
        let immediate = self.private_offset(wave, instruction)?;
        let addresses = wave
            .active()
            .map(|lane| {
                if wave.reg(address, lane, 1)? != Value::PrivateApertureHi {
                    return Err(EvalError::Unsupported {
                        pc: wave.pc,
                        what: "FLAT instruction mixes Private and another aperture".into(),
                    });
                }
                let low = wave
                    .reg(address, lane, 0)?
                    .bits()
                    .map_err(|e| wave.fail(Some(lane), e))?;
                Ok((lane, i128::from(low) + i128::from(immediate)))
            })
            .collect::<Result<Vec<_>, EvalError>>()?;
        self.private_transfer(wave, instruction, memory, &addresses, true)?;
        Ok(true)
    }

    fn private_offset(&self, wave: &Wave, instruction: &Instruction) -> Result<i64, EvalError> {
        instruction
            .modifiers()
            .iter()
            .find(|m| m.name == "offset")
            .map_or(Some(0), |m| m.value.as_deref().and_then(parse_i64))
            .ok_or_else(|| self.unsupported(wave, instruction))
    }

    fn private_transfer(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        memory: &MemoryInstruction,
        addresses: &[(u8, i128)],
        flat: bool,
    ) -> Result<(), EvalError> {
        let extent = self
            .private
            .extent
            .ok_or_else(|| self.unsupported(wave, instruction))?;
        let TransferShape::Registers {
            bytes_per_register: 4,
            registers_per_part: words @ 1..=4,
            parts: 1,
        } = memory.shape
        else {
            return Err(self.unsupported(wave, instruction));
        };
        let words = u16::from(words);
        let width = u32::from(words) * 4;
        let store = matches!(
            memory.kind,
            MemoryKind::ScratchStore | MemoryKind::FlatStore
        );
        let data = wave.destination(&memory.operands()[usize::from(store)])?;
        if data.class != RegisterClass::Vector || data.count != words {
            return Err(self.unsupported(wave, instruction));
        }
        // Capture the complete active transfer before issuing or modifying any
        // destination, including when the destination aliases its address pair.
        let mut transfers = Vec::new();
        for &(lane, address) in addresses {
            let offset = u32::try_from(address).ok().filter(|offset| offset.is_multiple_of(4)
                && offset.checked_add(width).is_some_and(|end| end <= extent))
                .ok_or_else(|| EvalError::Unsupported { pc: wave.pc,
                    what: "scratch DWORD interval is outside the aligned declared fixed private extent".into() })?;
            let mut values = Vec::new();
            for component in 0..words {
                let offset = offset + u32::from(component) * 4;
                let value = if store {
                    let source = Register {
                        index: data.index + component,
                        count: 1,
                        ..data
                    };
                    wave.spill_word(source, lane)?
                } else {
                    self.private
                        .cells
                        .get(&(wave.id, lane, offset))
                        .copied()
                        .ok_or_else(|| {
                            wave.fail(Some(lane), "read of an uninitialized private DWORD")
                        })?
                };
                values.push(value);
            }
            transfers.push((lane, offset, values));
        }
        let (reads, writes) = self.instruction_registers(instruction, wave);
        let held_sources = reads
            .into_iter()
            .filter(|r| r.file == AmdRegisterFile::Vector)
            .collect::<Vec<_>>();
        let class = match (flat, store, words == 1) {
            (true, false, _) => AmdMemoryClass::FlatPrivateLoad,
            (true, true, _) => AmdMemoryClass::FlatPrivateStore,
            (false, false, true) => AmdMemoryClass::ScratchLoad32,
            (false, true, true) => AmdMemoryClass::ScratchStore32,
            (false, false, false) => AmdMemoryClass::ScratchLoadWide,
            (false, true, false) => AmdMemoryClass::ScratchStoreWide,
        };
        let mut counters = vec![(AmdCounter::Vm, 1)];
        if flat {
            counters.push((AmdCounter::Lgkm, 1));
        }
        let issue = self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations: writes.clone(),
                held_sources: if store {
                    held_sources.clone()
                } else {
                    Vec::new()
                },
            },
        );
        for (lane, offset, values) in transfers {
            for (component, value) in values.into_iter().enumerate() {
                if store {
                    self.private
                        .cells
                        .insert((wave.id, lane, offset + component as u32 * 4), value);
                } else {
                    wave.put(data, lane, component as u16, value)?;
                }
            }
            self.builder.amd_event(
                wave.id,
                ProgramPoint(wave.pc as u32),
                AmdEventKind::PrivateMemoryAccess {
                    issue,
                    thread: ThreadIx(wave.id * wave.width + u32::from(lane)),
                    offset: u64::from(offset),
                    width,
                    kind: if store {
                        AccessMode::Write
                    } else {
                        AccessMode::Read
                    },
                },
            );
        }
        *self.private.completion.entry(wave.id).or_default() |= if flat { 3 } else { 1 };
        if store {
            self.private
                .pending_stores
                .entry(wave.id)
                .or_default()
                .extend(held_sources);
        } else {
            self.private
                .pending_loads
                .entry(wave.id)
                .or_default()
                .extend(writes);
        }
        Ok(())
    }
}
