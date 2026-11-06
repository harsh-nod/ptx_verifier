//! Native AMD matrix ops execution.
use super::*;

impl Interpreter<'_> {
    pub(super) fn matrix_input(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        item: usize,
        kind: super::super::matrix::InputKind,
    ) -> Result<ExprId, EvalError> {
        use super::super::matrix::InputKind;
        let per_register = match kind {
            InputKind::F32 => 1,
            InputKind::F16 | InputKind::Bf16 => 2,
            InputKind::Fp8E4m3 | InputKind::Fp8E5m2 => 4,
        };
        let component = item / per_register;
        let selected = if let Operand::Register(register) = operand {
            let mut register = *register;
            register.index += component as u16;
            register.count = 1;
            Operand::Register(register)
        } else {
            operand.clone()
        };
        match kind {
            InputKind::F32 => self.real(wave, &selected, lane),
            InputKind::F16 => self.half(wave, &selected, lane, !item.is_multiple_of(2)),
            InputKind::Fp8E4m3 => self.fp8(wave, &selected, lane, item % 4),
            InputKind::Bf16 => {
                let high = !item.is_multiple_of(2);
                let symbolic = match wave.value(&selected, lane)? {
                    Value::Half(expr) if !high => Some(expr),
                    Value::Half(_) if high => Some(self.arena.int(0)),
                    Value::Halves(lo, hi) => Some(if high { hi } else { lo }),
                    _ => None,
                };
                if let Some(expr) = symbolic {
                    if !matches!(self.arena.node(expr), ExprNode::InputElement { .. })
                        && self.arena.as_f64(expr) != Some(0.0)
                    {
                        return Err(EvalError::Unsupported {
                            pc: wave.pc,
                            what: "produced F16 cannot be reinterpreted as symbolic BF16".into(),
                        });
                    }
                    self.claim_half_format(wave, expr, WordFormat::Bfloat16)?;
                    return Ok(expr);
                }
                let bits = wave.bits(&selected, lane)? >> (16 * (item % 2));
                let value = super::super::matrix::decode_bits(kind, bits)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                self.arena
                    .float_from_f64(value)
                    .map_err(|e| wave.fail(Some(lane), e.to_string()))
            }
            InputKind::Fp8E5m2 => {
                let bits =
                    wave.bits(&selected, lane)? >> (8 * (item % per_register) * (4 / per_register));
                let value = super::super::matrix::decode_bits(kind, bits)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                self.arena
                    .float_from_f64(value)
                    .map_err(|e| wave.fail(Some(lane), e.to_string()))
            }
        }
    }
    pub(super) fn wmma(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        use super::super::matrix::InputKind;
        if self.architecture != AmdArchitecture::Gfx1250
            || wave.valid != 0xffff_ffff
            || wave.exec != 0xffff_ffff
            || !instruction.modifiers().is_empty()
        {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "WMMA requires one complete active wave32 and supported unmodified operands"
                    .into(),
            });
        }
        let Operation::Matrix(matrix) = instruction.operation() else {
            unreachable!("typed matrix dispatch")
        };
        let (kind, input_kind, k) = match matrix.operation {
            MatrixOpcode::VWmmaF3216x16x4F32 => (AmdWmmaKind::F32_16x16x4, InputKind::F32, 4),
            MatrixOpcode::VWmmaF3216x16x32F16 => (AmdWmmaKind::F16_16x16x32, InputKind::F16, 32),
            MatrixOpcode::VWmmaF3216x16x32Bf16 => (AmdWmmaKind::Bf16_16x16x32, InputKind::Bf16, 32),
            _ => return Err(self.unsupported(wave, instruction)),
        };
        let o = instruction.operands();
        let (_, destinations) = self.instruction_registers(instruction, wave);
        let sources = [o[0].clone(), o[1].clone(), o[2].clone()];
        let (sources_ab, _) = self.instruction_registers_for_operands(instruction, &sources, wave);
        let sources = [o[0].clone(), o[3].clone()];
        let (accumulator, _) = self.instruction_registers_for_operands(instruction, &sources, wave);
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::WmmaIssue {
                kind,
                destinations,
                sources_ab,
                accumulator,
            },
        );
        let mut a = vec![Vec::new(); 32];
        let mut b = vec![Vec::new(); 32];
        let mut c = vec![Vec::new(); 32];
        for lane in 0..32u8 {
            for item in 0..k / 2 {
                a[lane as usize].push(self.matrix_input(wave, &o[1], lane, item, input_kind)?);
                b[lane as usize].push(self.matrix_input(wave, &o[2], lane, item, input_kind)?);
            }
            for component in 0..8 {
                let value = if let Operand::Register(register) = o[3] {
                    let value = wave.reg(register, lane, component)?;
                    self.real_value(wave, value, lane)?
                } else {
                    self.real(wave, &o[3], lane)?
                };
                c[lane as usize].push(value);
            }
        }
        if a.iter().chain(&b).chain(&c).flatten().any(|&value| {
            self.arena
                .as_f64(value)
                .is_some_and(|value| !value.is_finite())
        }) {
            return Err(wave.fail(None, "WMMA requires finite concrete operands"));
        }
        // Public FlyDSL f37f7a2 MmaAtom.cpp: A/B are column-major
        // (row,K), while C/D row=(lane/16)*8+register,col=lane%16.
        let input = |row: usize, kk: usize| {
            if k == 4 {
                (row + (kk / 2) * 16, kk % 2)
            } else {
                (row + ((kk / 8) % 2) * 16, (kk / 16) * 8 + kk % 8)
            }
        };
        let destination = wave.destination(&o[0])?;
        for (lane, accumulator) in c.iter().enumerate() {
            for (component, &initial) in accumulator.iter().enumerate() {
                let row = (lane / 16) * 8 + component;
                let col = lane % 16;
                let mut value = initial;
                for kk in 0..k {
                    let (al, av) = input(row, kk);
                    let (bl, bv) = input(col, kk);
                    value = self.arena.fma(a[al][av], b[bl][bv], value);
                }
                wave.put(
                    destination,
                    lane as u8,
                    component as u16,
                    Value::Real(value),
                )?;
            }
        }
        Ok(())
    }
    pub(super) fn matrix(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        let Operation::Matrix(matrix) = instruction.operation() else {
            unreachable!("typed matrix dispatch")
        };
        if matrix.family == MatrixFamily::Wmma {
            return self.wmma(wave, instruction);
        }

        use super::super::matrix::{Form, InputKind};
        let mut form = Form::from_operation(matrix.operation)
            .ok_or_else(|| self.unsupported(wave, instruction))?;
        let mut cbsz = 0u8;
        let mut blgp = 0u8;
        for modifier in instruction.modifiers() {
            match modifier.name.as_str() {
                "cbsz" => {
                    cbsz = modifier
                        .value
                        .as_deref()
                        .and_then(parse_u64)
                        .and_then(|value| u8::try_from(value).ok())
                        .ok_or_else(|| self.unsupported(wave, instruction))?
                }
                "blgp" => {
                    blgp = modifier
                        .value
                        .as_deref()
                        .and_then(parse_u64)
                        .and_then(|value| u8::try_from(value).ok())
                        .ok_or_else(|| self.unsupported(wave, instruction))?
                }
                "abid" if modifier.value.as_deref() == Some("0") => {}
                "op_sel" | "op_sel_hi" if form.is_scaled() => {}
                _ => return Err(self.unsupported(wave, instruction)),
            }
        }
        if matches!(form.input_kind, InputKind::Fp8E4m3 | InputKind::Fp8E5m2) {
            form = form
                .with_fp8_formats(cbsz, blgp)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
        } else if cbsz != 0 || blgp != 0 {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec != u64::MAX || wave.valid != u64::MAX {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "MFMA requires a complete active wave64".into(),
            });
        }
        let o = instruction.operands();
        let destination = wave.destination(&o[0])?;
        let output_items = form.accumulator_items_per_lane();
        if destination.count as usize != output_items || destination.index % 2 != 0 {
            return Err(wave.fail(None, "MFMA destination register count/alignment mismatch"));
        }
        for source in [&o[1], &o[2]] {
            if let Operand::Register(register) = source {
                if register.count as usize != form.input_registers_per_operand() {
                    return Err(wave.fail(None, "MFMA input register count mismatch"));
                }
            } else if !matches!(source, Operand::Integer(0) | Operand::Float(0.0)) {
                return Err(self.unsupported(wave, instruction));
            }
        }
        if let Operand::Register(register) = o[3]
            && register.count as usize != output_items
        {
            return Err(wave.fail(None, "MFMA accumulator register count mismatch"));
        }
        if form.is_scaled() {
            if o.len() != 6 {
                return Err(self.unsupported(wave, instruction));
            }
            let low = selectors(instruction, "op_sel", 3, 0)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let high = selectors(instruction, "op_sel_hi", 3, 0)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            if low[2] != 0 || high[2] != 0 {
                return Err(self.unsupported(wave, instruction));
            }
            for lane in 0..64 {
                for index in 0..2 {
                    let exponent = if let Operand::Float(value) = o[4 + index] {
                        ((value as f32).to_bits() >> 23) & 255
                    } else {
                        let byte = (2 * high[index] + low[index]) as u32;
                        (wave.bits(&o[4 + index], lane)? >> (8 * byte)) & 255
                    };
                    if exponent != 127 {
                        return Err(EvalError::Unsupported{pc:wave.pc,what:"block-scaled MFMA currently requires every selected E8M0 scale byte to equal127 (unit scale)".into()});
                    }
                }
            }
        } else if o.len() != 4 {
            return Err(self.unsupported(wave, instruction));
        }
        let (_, writes) = self.instruction_registers(instruction, wave);
        let mut sources = vec![o[0].clone(), o[1].clone(), o[2].clone()];
        if form.is_scaled() {
            sources.extend_from_slice(&o[4..6]);
        }
        let (sources_ab, _) = self.instruction_registers_for_operands(instruction, &sources, wave);
        let sources = [o[0].clone(), o[3].clone()];
        let (accumulator, _) = self.instruction_registers_for_operands(instruction, &sources, wave);
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MatrixIssue {
                kind: form.graph_kind(),
                destinations: writes,
                sources_ab,
                accumulator,
            },
        );
        let mut a = Vec::with_capacity(64);
        let mut b = Vec::with_capacity(64);
        let mut c = Vec::with_capacity(64);
        for lane in 0..64 {
            let mut av = Vec::new();
            let mut bv = Vec::new();
            let mut cv = Vec::new();
            for item in 0..form.input_items_per_lane() {
                av.push(self.matrix_input(wave, &o[1], lane, item, form.input_kind)?);
                bv.push(self.matrix_input(wave, &o[2], lane, item, form.input_kind_b)?);
            }
            for item in 0..output_items {
                cv.push(if let Operand::Register(register) = o[3] {
                    let value = wave.reg(register, lane, item as u16)?;
                    self.real_value(wave, value, lane)?
                } else {
                    self.real(wave, &o[3], lane)?
                });
            }
            a.push(av);
            b.push(bv);
            c.push(cv);
        }
        let outputs = super::super::matrix::compute(&mut self.arena, form, &a, &b, &c)
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
        for (lane, values) in outputs.into_iter().enumerate() {
            for (component, expression) in values.into_iter().enumerate() {
                wave.put(
                    destination,
                    lane as u8,
                    component as u16,
                    Value::Real(expression),
                )?;
            }
        }
        self.stats.warp_syncs += 1;
        Ok(())
    }
}
