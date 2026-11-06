//! Native AMD tensor ops execution.
use super::*;

impl Interpreter<'_> {
    pub(super) fn tensor(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        if self.architecture != AmdArchitecture::Gfx1250 || !instruction.modifiers().is_empty() {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec == 0 {
            return Ok(());
        }
        let load = match instruction.operation() {
            Operation::Memory(memory) if memory.kind == MemoryKind::TensorLoadToLds => true,
            Operation::Memory(memory) if memory.kind == MemoryKind::TensorStoreFromLds => false,
            _ => return Err(self.unsupported(wave, instruction)),
        };
        let mut groups = Vec::new();
        let mut sources = Vec::new();
        for (operand, count) in instruction.operands().iter().zip([4, 8, 4, 4]) {
            let register = wave.destination(operand)?;
            if register.class != RegisterClass::Scalar || register.count != count {
                return Err(self.unsupported(wave, instruction));
            }
            sources.push(register.index);
            let mut words = Vec::new();
            for i in 0..count {
                words.push(
                    wave.reg(register, 0, i)?
                        .bits()
                        .map_err(|e| wave.fail(None, e))?,
                );
            }
            groups.push(words);
        }
        let descriptor = AmdTensorDescriptor {
            d0: groups[0].clone().try_into().expect("validated D0 tuple"),
            d1: groups[1].clone().try_into().expect("validated D1 tuple"),
            d2: groups[2].clone().try_into().expect("validated D2 tuple"),
            d3: groups[3].clone().try_into().expect("validated D3 tuple"),
        };
        let Some(footprint) = descriptor.decode().map_err(|what| EvalError::Unsupported {
            pc: wave.pc,
            what: what.into(),
        })?
        else {
            return Ok(());
        };
        let AmdTensorFootprint {
            width,
            rows,
            cols,
            stride,
            global,
            shared,
            bytes: _,
            global_end,
            shared_end,
        } = footprint;
        if !self
            .config
            .arrays
            .iter()
            .any(|a| a.base <= global && global_end <= a.base + a.size_bytes())
            && !self
                .module_globals
                .values()
                .any(|a| a.base <= global && global_end <= a.base + a.size)
        {
            return Err(wave.fail(
                None,
                "tensor footprint crosses global allocation boundaries",
            ));
        }
        if shared_end > self.lds_size {
            self.builder.amd_event(
                wave.id,
                ProgramPoint(wave.pc as u32),
                AmdEventKind::TensorAccessFault {
                    load,
                    descriptor,
                    sources: sources
                        .try_into()
                        .expect("validated four descriptor groups"),
                },
            );
            return Err(EvalError::TensorBounds {
                wave: wave.id,
                pc: wave.pc,
                what: TENSOR_BOUNDS_ABORT_REASON,
            });
        }
        if !self.config.shared_allocations.is_empty()
            && !self
                .config
                .shared_allocations
                .iter()
                .any(|a| a.offset <= shared && shared_end <= a.offset + a.size)
        {
            return Err(wave.fail(
                None,
                "tensor footprint crosses shared allocation boundaries",
            ));
        }
        let issue = self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class: if load {
                    AmdMemoryClass::TensorLoadToLds
                } else {
                    AmdMemoryClass::TensorStoreFromLds
                },
                counters: vec![(AmdCounter::Tensor, 1)],
                destinations: vec![],
                // Native TDM captures uniform descriptors at issue. Keep their
                // Instruction reads for pending-KM readiness, without inventing
                // an X/EXP source lease for the Tensor completion counter.
                held_sources: vec![],
            },
        );
        let lane = wave.exec.trailing_zeros() as u8;
        let thread = ThreadIx(wave.id * wave.width + lane as u32);
        for row in 0..rows {
            for col in 0..cols {
                let ga = global + (row * stride + col) * width;
                let sa = shared + (row * cols + col) * width;
                self.validate_address(wave, lane, false, ga, width, !load)?;
                self.validate_address(wave, lane, true, sa, width, load)?;
                let value = if load {
                    self.global_read(ga, width)
                } else {
                    self.lds.read(sa, width)
                }
                .map_err(|e| wave.fail(Some(lane), e))?;
                if load {
                    self.lds.write(sa, width, value)
                } else {
                    self.global_write(ga, width, value)
                }
                .map_err(|e| wave.fail(Some(lane), e))?;
                for (space, addr, mode) in [
                    (
                        Space::Global,
                        ga,
                        if load {
                            AccessMode::Read
                        } else {
                            AccessMode::Write
                        },
                    ),
                    (
                        Space::Shared,
                        sa,
                        if load {
                            AccessMode::Write
                        } else {
                            AccessMode::Read
                        },
                    ),
                ] {
                    let stored = if mode == AccessMode::Write {
                        Some(self.builder.value(match value {
                            Value::Input(e)
                            | Value::Real(e)
                            | Value::Half(e)
                            | Value::Byte(e)
                            | Value::IntExpr(e) => StoredValue::Scalar(e),
                            Value::Halves(a, b) | Value::BytePair(a, b) => StoredValue::Pair(a, b),
                            Value::Bytes(v) => StoredValue::Quad(v),
                            Value::Integer(v) => StoredValue::Scalar(self.arena.int(v as i64)),
                            _ => StoredValue::Opaque,
                        }))
                    } else {
                        None
                    };
                    let effect = self.builder.thread_access(
                        thread,
                        ProgramPoint(wave.pc as u32),
                        MemAccess {
                            space,
                            mode,
                            ordering: OrderingKind::Ordinary,
                            proxy: Proxy::Generic,
                            footprint: Footprint::Bytes {
                                addr,
                                width: width as u32,
                            },
                            role: OperandRole::Plain,
                            attributed: thread,
                            value: stored,
                        },
                    );
                    self.builder.amd_memory_effect(issue, effect);
                }
            }
        }
        Ok(())
    }
}
