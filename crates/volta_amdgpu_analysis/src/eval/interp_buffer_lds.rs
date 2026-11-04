//! CDNA4 §3.7 / §9.1.9 MUBUF LDS DMA, distinct from gfx1250 ASYNC.
//!
//! LLVM 5fd50ec8 BUFInstructions.td and AMDGPUHWEvents.cpp assign VM_CNT,
//! no VDST and implicit M0/EXEC inputs. The public text/figure disagree on
//! high M0 bits; this profile requires an aligned, fully defined low16 base.
use super::*;

impl Interpreter<'_> {
    pub(super) fn buffer_load_to_lds(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        if self.architecture != AmdArchitecture::Gfx950 || self.xnack_replay_enabled {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec == 0 {
            return Ok(());
        }
        let Operation::Memory(memory) = instruction.operation() else {
            unreachable!("typed buffer DMA dispatch")
        };
        let TransferShape::PerLaneBytes(bytes @ (4 | 16)) = memory.shape else {
            return Err(self.unsupported(wave, instruction));
        };
        let bytes = u64::from(bytes);
        let MemoryAddress::BufferToLds { vector, descriptor } = memory.address() else {
            unreachable!("typed buffer DMA addresses")
        };
        if !wave.m0_defined || wave.m0 > 0xffff || !wave.m0.is_multiple_of(4) {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what:
                    "selected buffer-to-LDS load requires initialized, DWORD-aligned M0 <= 0xffff"
                        .into(),
            });
        }
        let m0 = u64::from(wave.m0);
        let descriptor = wave.destination(descriptor)?;
        let mut words = [0; 4];
        for (component, word) in words.iter_mut().enumerate() {
            *word = wave
                .reg(descriptor, 0, component as u16)?
                .bits()
                .map_err(|error| wave.fail(None, error))?;
        }
        // Table48: a valid DFMT2, disabled UserVM, ADD_TID0/type0. The
        // unformatted opcode derives transfer width and identity channels.
        if words[1] >> 30 != 0 || words[3] != 0x110000 {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "selected buffer-to-LDS resource requires linear/cache-swizzle0 and word3=0x110000".into(),
            });
        }
        let base = u64::from(words[0]) | (u64::from(words[1] & 0xffff) << 32);
        let records = u64::from(words[2]);
        if records == 0 || records == u64::from(u32::MAX) {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "selected buffer-to-LDS load requires an enabled finite byte range".into(),
            });
        }
        // Capture every source and full payload before mutating LDS. Physical
        // lane pitch does not compress sparse EXEC or include the wave index.
        let mut transfers = Vec::new();
        for lane in wave.active() {
            let offset = u64::from(wave.bits(vector, lane)?);
            if offset.checked_add(bytes).is_none_or(|end| end > records) {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "buffer-to-LDS resource-OOB suppression is outside the selected profile"
                        .into(),
                });
            }
            let global = base
                .checked_add(offset)
                .filter(|address| address.checked_add(bytes).is_some_and(|end| end <= 1 << 48))
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let shared = m0
                .checked_add(u64::from(lane) * bytes)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            self.validate_address(wave, lane, false, global, bytes, false)?;
            self.validate_address(wave, lane, true, shared, bytes, true)?;
            if !self.config.shared_allocations.is_empty()
                && !self.config.shared_allocations.iter().any(|allocation| {
                    allocation.offset <= shared
                        && shared + bytes <= allocation.offset + allocation.size
                })
            {
                return Err(wave.fail(
                    Some(lane),
                    "buffer DMA crosses shared allocation boundaries",
                ));
            }
            let mut payload = Vec::new();
            for component in 0..bytes / 4 {
                let value = self
                    .global_read(global + component * 4, 4)
                    .map_err(|error| wave.fail(Some(lane), error))?;
                if matches!(
                    value,
                    Value::PartialBits { .. }
                        | Value::Low16Integer(_)
                        | Value::PartialBytePair(..)
                        | Value::PartialHalves(None, _)
                        | Value::PartialHalves(_, None)
                ) {
                    return Err(wave.fail(Some(lane), "buffer DMA observes undefined payload bits"));
                }
                payload.push(value);
            }
            transfers.push((lane, global, shared, payload));
        }
        // Representation failures must not leave a claimed partial DMA issue.
        // All source snapshots and address checks have already succeeded.
        for (_, _, shared, payload) in &transfers {
            for (component, &value) in payload.iter().enumerate() {
                self.lds
                    .write(shared + component as u64 * 4, 4, value)
                    .map_err(|error| wave.fail(None, error))?;
            }
        }
        let (_, destinations) = self.instruction_registers(instruction, wave);
        debug_assert!(destinations.is_empty());
        let issue = self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class: if bytes == 4 {
                    AmdMemoryClass::BufferLoadToLds32
                } else {
                    AmdMemoryClass::BufferLoadToLds128
                },
                counters: vec![(AmdCounter::Vm, 1)],
                destinations,
                // The model snapshots address/resource/M0 inputs at issue. Ordinary
                // producer-readiness checks remain in Instruction source roles.
                held_sources: Vec::new(),
            },
        );
        for (lane, global, shared, payload) in transfers {
            let thread = ThreadIx(wave.id * wave.width + u32::from(lane));
            for (component, value) in payload.into_iter().enumerate() {
                let displacement = component as u64 * 4;
                let stored = self.builder.value(match value {
                    Value::Input(e) | Value::Real(e) | Value::IntExpr(e) => StoredValue::Scalar(e),
                    Value::Bits(bits) | Value::Integer(bits) => {
                        StoredValue::Scalar(self.arena.int(i64::from(bits)))
                    }
                    Value::Halves(lo, hi) | Value::BytePair(lo, hi) => StoredValue::Pair(lo, hi),
                    Value::Bytes(bytes) => StoredValue::Quad(bytes),
                    _ => StoredValue::Opaque,
                });
                for (space, mode, addr, value) in [
                    (Space::Global, AccessMode::Read, global + displacement, None),
                    (
                        Space::Shared,
                        AccessMode::Write,
                        shared + displacement,
                        Some(stored),
                    ),
                ] {
                    let effect = self.builder.thread_access(
                        thread,
                        ProgramPoint(wave.pc as u32),
                        MemAccess {
                            space,
                            mode,
                            ordering: OrderingKind::Ordinary,
                            proxy: Proxy::Generic,
                            footprint: Footprint::Bytes { addr, width: 4 },
                            role: OperandRole::Plain,
                            attributed: thread,
                            value,
                        },
                    );
                    self.builder.amd_memory_effect(issue, effect);
                }
            }
        }
        Ok(())
    }
}
