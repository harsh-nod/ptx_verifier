use super::{memory::Memory, value::Value};
use crate::{
    config::{AnalysisConfig, ArrayKind, ParamValue},
    ir::*,
};
use std::{collections::BTreeMap, error::Error, fmt};
use volta_expr::{ExprArena, ExprId, ExprNode};
use volta_graph::*;

const KERNARG_BASE: u64 = 0xffff_0000_0000;
const DISPATCH_BASE: u64 = 0xffff_1000_0000;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ThreadId(pub u32);
#[derive(Debug, Default, Clone, Copy)]
pub struct Stats {
    pub instructions: u64,
    pub block_syncs: u64,
    pub warp_syncs: u64,
}
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EvalError {
    InvalidConfig(String),
    Unsupported {
        pc: usize,
        what: String,
    },
    Invalid {
        wave: u32,
        lane: Option<u8>,
        pc: usize,
        what: String,
    },
    BudgetExceeded {
        limit: u64,
    },
}
impl fmt::Display for EvalError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidConfig(what) => write!(f, "invalid gfx950 configuration: {what}"),
            Self::Unsupported { pc, what } => {
                write!(f, "unsupported gfx950 instruction at pc {pc}: {what}")
            }
            Self::Invalid {
                wave,
                lane,
                pc,
                what,
            } => write!(f, "wave {wave} lane {lane:?}, pc {pc}: {what}"),
            Self::BudgetExceeded { limit } => write!(
                f,
                "analysis instruction budget {limit} exhausted (inconclusive)"
            ),
        }
    }
}
impl Error for EvalError {}
#[derive(Debug)]
pub enum OutputsUnavailable {
    Aborted(EvalError),
    Stuck { blocked: Vec<(ThreadId, usize)> },
    Extraction(EvalError),
}
impl fmt::Display for OutputsUnavailable {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Aborted(e) => write!(f, "execution stopped: {e}"),
            Self::Stuck { blocked } => {
                write!(f, "execution is stuck with {} blocked lanes", blocked.len())
            }
            Self::Extraction(e) => write!(f, "output extraction failed: {e}"),
        }
    }
}
pub(crate) struct RunArtifacts {
    pub arena: ExprArena,
    pub outputs: Result<Vec<(String, Vec<(u64, ExprId)>)>, OutputsUnavailable>,
    pub graph: EventGraph,
    pub stats: Stats,
    pub op_counts: BTreeMap<&'static str, u64>,
}

#[derive(Debug)]
struct Wave {
    id: u32,
    pc: usize,
    valid: u64,
    exec: u64,
    vcc: u64,
    scc: bool,
    m0: u32,
    scalar: Vec<Option<Value>>,
    vector: BTreeMap<(u16, u8), Value>,
    accumulator: BTreeMap<(u16, u8), Value>,
    at_barrier: Option<u32>,
    generation: u32,
    exited: bool,
}
impl Wave {
    fn new(id: u32, lanes: u32) -> Self {
        let valid = if lanes == 64 {
            u64::MAX
        } else {
            (1u64 << lanes) - 1
        };
        Self {
            id,
            pc: 0,
            valid,
            exec: valid,
            vcc: 0,
            scc: false,
            m0: 0,
            scalar: vec![None; 128],
            vector: BTreeMap::new(),
            accumulator: BTreeMap::new(),
            at_barrier: None,
            generation: 0,
            exited: false,
        }
    }
    fn fail(&self, lane: Option<u8>, what: impl Into<String>) -> EvalError {
        EvalError::Invalid {
            wave: self.id,
            lane,
            pc: self.pc,
            what: what.into(),
        }
    }
    fn active(&self) -> impl Iterator<Item = u8> {
        let mask = self.exec;
        (0..64).filter(move |lane| mask & (1u64 << lane) != 0)
    }
    fn reg(&self, reg: Register, lane: u8, component: u16) -> Result<Value, EvalError> {
        let index = reg.index + component;
        let value = match reg.class {
            RegisterClass::Scalar => self.scalar.get(index as usize).copied().flatten(),
            RegisterClass::Vector => self.vector.get(&(index, lane)).copied(),
            RegisterClass::Accumulator => self.accumulator.get(&(index, lane)).copied(),
            RegisterClass::Special => {
                let val = match reg.special {
                    Some(SpecialRegister::Exec) => self.exec,
                    Some(SpecialRegister::ExecLo) => self.exec as u32 as u64,
                    Some(SpecialRegister::ExecHi) => self.exec >> 32,
                    Some(SpecialRegister::Vcc) => self.vcc,
                    Some(SpecialRegister::VccLo) => self.vcc as u32 as u64,
                    Some(SpecialRegister::VccHi) => self.vcc >> 32,
                    Some(SpecialRegister::Scc) => self.scc as u64,
                    Some(SpecialRegister::M0) => self.m0 as u64,
                    Some(SpecialRegister::Null) => 0,
                    _ => return Err(self.fail(Some(lane), "unsupported special register")),
                };
                Some(Value::Bits((val >> (32 * component)) as u32))
            }
        };
        value.ok_or_else(|| {
            self.fail(
                Some(lane),
                format!("uninitialized {:?} register {index}", reg.class),
            )
        })
    }
    fn put(
        &mut self,
        reg: Register,
        lane: u8,
        component: u16,
        value: Value,
    ) -> Result<(), EvalError> {
        let index = reg.index + component;
        match reg.class {
            RegisterClass::Scalar => {
                let error = self.fail(Some(lane), "scalar register index out of range");
                *self.scalar.get_mut(index as usize).ok_or(error)? = Some(value);
            }
            RegisterClass::Vector => {
                self.vector.insert((index, lane), value);
            }
            RegisterClass::Accumulator => {
                self.accumulator.insert((index, lane), value);
            }
            RegisterClass::Special => {
                let bits = value.bits().map_err(|e| self.fail(Some(lane), e))? as u64;
                match reg.special {
                    Some(SpecialRegister::Exec) => {
                        self.exec = (self.exec & !(0xffff_ffffu64 << (32 * component)))
                            | (bits << (32 * component));
                    }
                    Some(SpecialRegister::ExecLo) => {
                        self.exec = (self.exec & 0xffff_ffff_0000_0000) | bits
                    }
                    Some(SpecialRegister::ExecHi) => {
                        self.exec = (self.exec & 0xffff_ffff) | (bits << 32)
                    }
                    Some(SpecialRegister::Vcc) => {
                        self.vcc = (self.vcc & !(0xffff_ffffu64 << (32 * component)))
                            | (bits << (32 * component))
                    }
                    Some(SpecialRegister::VccLo) => {
                        self.vcc = (self.vcc & 0xffff_ffff_0000_0000) | bits
                    }
                    Some(SpecialRegister::VccHi) => {
                        self.vcc = (self.vcc & 0xffff_ffff) | (bits << 32)
                    }
                    Some(SpecialRegister::Scc) => self.scc = bits != 0,
                    Some(SpecialRegister::M0) => return Err(EvalError::Unsupported{pc:self.pc,what:"explicit M0 writes need software dependency-spacing checks".into()}),
                    Some(SpecialRegister::Null) => {}
                    _ => return Err(self.fail(Some(lane), "unsupported special destination")),
                }
            }
        }
        Ok(())
    }
    fn value(&self, operand: &Operand, lane: u8) -> Result<Value, EvalError> {
        match operand {
            Operand::Register(reg) => self.reg(*reg, lane, 0),
            Operand::Integer(v) => Ok(Value::Bits(*v as u32)),
            Operand::Float(v) => Ok(Value::Bits((*v as f32).to_bits())),
            Operand::Symbol(s) if s == "off" => Ok(Value::Bits(0)),
            _ => Err(self.fail(Some(lane), format!("non-value operand {operand:?}"))),
        }
    }
    fn bits(&self, operand: &Operand, lane: u8) -> Result<u32, EvalError> {
        self.value(operand, lane)?
            .bits()
            .map_err(|e| self.fail(Some(lane), e))
    }
    fn wide(&self, operand: &Operand, lane: u8) -> Result<u64, EvalError> {
        match operand {
            Operand::Register(reg) if reg.count == 2 => {
                let lo = self
                    .reg(*reg, lane, 0)?
                    .bits()
                    .map_err(|e| self.fail(Some(lane), e))?;
                let hi = self
                    .reg(*reg, lane, 1)?
                    .bits()
                    .map_err(|e| self.fail(Some(lane), e))?;
                Ok(lo as u64 | ((hi as u64) << 32))
            }
            Operand::Integer(v) => Ok(*v as u64),
            Operand::Symbol(s) if s == "off" => Ok(0),
            _ => Ok(self.bits(operand, lane)? as u64),
        }
    }
    fn destination(&self, operand: &Operand) -> Result<Register, EvalError> {
        match operand {
            Operand::Register(reg) => Ok(*reg),
            _ => Err(self.fail(None, "destination is not a register")),
        }
    }
    fn put_value(&mut self, operand: &Operand, lane: u8, value: Value) -> Result<(), EvalError> {
        let reg = self.destination(operand)?;
        self.put(reg, lane, 0, value)
    }
    fn put_wide(&mut self, operand: &Operand, lane: u8, value: u64) -> Result<(), EvalError> {
        let reg = self.destination(operand)?;
        self.put(reg, lane, 0, Value::Bits(value as u32))?;
        if reg.count == 2 {
            self.put(reg, lane, 1, Value::Bits((value >> 32) as u32))?;
        }
        Ok(())
    }
}

pub(crate) struct Interpreter<'a> {
    program: &'a LoweredKernel,
    config: AnalysisConfig,
    arena: ExprArena,
    global: Memory,
    lds: Memory,
    kernargs: Memory,
    dispatch: Memory,
    waves: Vec<Wave>,
    builder: GraphBuilder,
    stats: Stats,
    op_counts: BTreeMap<&'static str, u64>,
    lds_size: u64,
}
impl<'a> Interpreter<'a> {
    pub fn new(
        program: &'a LoweredKernel,
        config: AnalysisConfig,
        provenance: Provenance,
    ) -> Result<Self, EvalError> {
        config.validate().map_err(EvalError::InvalidConfig)?;
        if !config.global_values.is_empty() {
            return Err(EvalError::InvalidConfig("AMD module global bindings are not yet implemented".into()));
        }
        let threads = config
            .block_dim
            .0
            .checked_mul(config.block_dim.1)
            .and_then(|n| n.checked_mul(config.block_dim.2))
            .ok_or_else(|| EvalError::InvalidConfig("block dimension overflow".into()))?;
        if threads == 0 || threads > 1024 {
            return Err(EvalError::InvalidConfig(
                "gfx950 workgroup must contain 1..=1024 workitems".into(),
            ));
        }
        if config.grid_dim.0 == 0 || config.grid_dim.1 == 0 || config.grid_dim.2 == 0 {
            return Err(EvalError::InvalidConfig(
                "grid dimensions must be nonzero".into(),
            ));
        }
        for array in &config.arrays {
            if array.base < DISPATCH_BASE + 64 && array.base + array.size_bytes() > KERNARG_BASE {
                return Err(EvalError::InvalidConfig(
                    "allocation overlaps analyzer ABI address window".into(),
                ));
            }
            if ![1, 2, 4, 8].contains(&array.elem_width) {
                return Err(EvalError::InvalidConfig(
                    "supported array element widths are 1,2,4,8 bytes".into(),
                ));
            }
        }
        let lds_size = program
            .descriptor
            .value("group_segment_fixed_size", 0)
            .checked_add(config.dynamic_shared_bytes)
            .ok_or_else(|| EvalError::InvalidConfig("LDS size overflow".into()))?;
        if lds_size > 163840 {
            return Err(EvalError::InvalidConfig(
                "requested LDS exceeds gfx950 capacity".into(),
            ));
        }
        if program.descriptor.flag("wavefront_size32") {
            return Err(EvalError::InvalidConfig("gfx950 requires wave64".into()));
        }
        if program
            .descriptor
            .value("user_sgpr_kernarg_preload_length", 0)
            != 0
        {
            return Err(EvalError::InvalidConfig(
                "kernarg preloading not implemented".into(),
            ));
        }
        let mut result = Self {
            program,
            config,
            arena: ExprArena::new(),
            global: Memory::default(),
            lds: Memory::default(),
            kernargs: Memory::default(),
            dispatch: Memory::default(),
            waves: Vec::new(),
            builder: GraphBuilder::new(provenance),
            stats: Stats::default(),
            op_counts: BTreeMap::new(),
            lds_size,
        };
        result.initialize_memory()?;
        for id in 0..threads.div_ceil(64) {
            let mut wave = Wave::new(id, (threads - id * 64).min(64));
            wave.m0 = lds_size as u32;
            result.initialize_wave(&mut wave)?;
            result.waves.push(wave);
        }
        Ok(result)
    }
    fn initialize_memory(&mut self) -> Result<(), EvalError> {
        for array in &self.config.arrays {
            if !array.kind.is_input() {
                continue;
            }
            let name = self.arena.intern_string(array.name.clone());
            for index in 0..array.len {
                let addr = array.base + index * array.elem_width;
                let value = if array.kind == ArrayKind::IndexInput {
                    Value::Integer(index as u32)
                } else {
                    let expr=self.arena.input_element(name,index);
                    if array.elem_width==2{Value::Half(expr)}else{Value::Real(expr)}
                };
                self.global.initialize(addr, array.elem_width, value);
            }
        }
        let mut position = 0;
        for arg in &self.program.args {
            let value = if arg.value_kind.starts_with("hidden_") {
                self.hidden_arg(&arg.value_kind)?
            } else {
                let param = self.config.params.get(position).ok_or_else(|| {
                    EvalError::InvalidConfig(format!(
                        "missing argument {position} ({:?})",
                        arg.name
                    ))
                })?;
                position += 1;
                match param {
                    ParamValue::Int(value) => Some((*value as u64, None)),
                    ParamValue::Float(value) => Some(((*value as f32).to_bits() as u64, None)),
                    ParamValue::SymFloat(name) => {
                        Some((0, Some(self.arena.param_symbol(name.clone()))))
                    }
                    ParamValue::ArrayPtr(name) => Some((
                        self.config
                            .array(name)
                            .ok_or_else(|| {
                                EvalError::InvalidConfig(format!("unknown pointer array {name}"))
                            })?
                            .base,
                        None,
                    )),
                }
            };
            if let Some((bits, expression)) = value {
                if let Some(expression) = expression {
                    if arg.size != 4 {
                        return Err(EvalError::InvalidConfig(
                            "symbolic scalar arguments require f32 storage".into(),
                        ));
                    }
                    self.kernargs
                        .initialize(KERNARG_BASE + arg.offset, 4, Value::Real(expression));
                } else {
                    for byte in 0..arg.size {
                        if byte >= 8 {
                            return Err(EvalError::InvalidConfig(format!(
                                "argument {:?} wider than 64 bits",
                                arg.name
                            )));
                        }
                        self.kernargs.initialize(
                            KERNARG_BASE + arg.offset + byte,
                            1,
                            Value::Bits(((bits >> (8 * byte)) & 255) as u32),
                        );
                    }
                }
            }
        }
        if position != self.config.params.len() {
            return Err(EvalError::InvalidConfig(format!(
                "{} parameters provided but metadata declares {position} explicit arguments",
                self.config.params.len()
            )));
        }
        // HSA dispatch packet fields used by LLVM AMDGPU ABI.
        for (offset, width, bits) in [
            (4, 2, self.config.block_dim.0 as u64),
            (6, 2, self.config.block_dim.1 as u64),
            (8, 2, self.config.block_dim.2 as u64),
            (
                12,
                4,
                self.config.grid_dim.0 as u64 * self.config.block_dim.0 as u64,
            ),
            (
                16,
                4,
                self.config.grid_dim.1 as u64 * self.config.block_dim.1 as u64,
            ),
            (
                20,
                4,
                self.config.grid_dim.2 as u64 * self.config.block_dim.2 as u64,
            ),
            (28, 4, self.lds_size),
        ] {
            for byte in 0..width {
                self.dispatch.initialize(
                    DISPATCH_BASE + offset + byte,
                    1,
                    Value::Bits(((bits >> (8 * byte)) & 255) as u32),
                );
            }
        }
        Ok(())
    }
    fn hidden_arg(&self, kind: &str) -> Result<Option<(u64, Option<ExprId>)>, EvalError> {
        let value = match kind {
            "hidden_block_count_x" => self.config.grid_dim.0 as u64,
            "hidden_block_count_y" => self.config.grid_dim.1 as u64,
            "hidden_block_count_z" => self.config.grid_dim.2 as u64,
            "hidden_group_size_x" => self.config.block_dim.0 as u64,
            "hidden_group_size_y" => self.config.block_dim.1 as u64,
            "hidden_group_size_z" => self.config.block_dim.2 as u64,
            "hidden_remainder_x"
            | "hidden_remainder_y"
            | "hidden_remainder_z"
            | "hidden_global_offset_x"
            | "hidden_global_offset_y"
            | "hidden_global_offset_z" => 0,
            "hidden_grid_dims" => {
                if self.config.grid_dim.2 > 1 || self.config.block_dim.2 > 1 {
                    3
                } else if self.config.grid_dim.1 > 1 || self.config.block_dim.1 > 1 {
                    2
                } else {
                    1
                }
            }
            "hidden_dynamic_lds_size" => self.config.dynamic_shared_bytes,
            _ => return Ok(None), // Unknown runtime facilities remain uninitialized, never guessed.
        };
        Ok(Some((value, None)))
    }
    fn initialize_wave(&self, wave: &mut Wave) -> Result<(), EvalError> {
        let mut sgpr = 0usize;
        let descriptor = &self.program.descriptor;
        for (field, count, value) in [
            ("user_sgpr_private_segment_buffer", 4, None),
            ("user_sgpr_dispatch_ptr", 2, Some(DISPATCH_BASE)),
            ("user_sgpr_queue_ptr", 2, None),
            ("user_sgpr_kernarg_segment_ptr", 2, Some(KERNARG_BASE)),
            ("user_sgpr_dispatch_id", 2, Some(0)),
            ("user_sgpr_flat_scratch_init", 2, None),
            (
                "user_sgpr_private_segment_size",
                1,
                Some(descriptor.value("private_segment_fixed_size", 0)),
            ),
        ] {
            if descriptor.flag(field) {
                if let Some(value) = value {
                    for component in 0..count {
                        wave.scalar[sgpr + component] =
                            Some(Value::Bits((value >> (32 * component)) as u32));
                    }
                }
                sgpr += count;
            }
        }
        if descriptor.get("user_sgpr_count").is_some_and(|count|count!=sgpr as u64) {
            return Err(EvalError::InvalidConfig(format!("descriptor user_sgpr_count disagrees with enabled ABI inputs: expected {sgpr}")));
        }
        for field in [
            "system_sgpr_workgroup_id_x",
            "system_sgpr_workgroup_id_y",
            "system_sgpr_workgroup_id_z",
        ] {
            if descriptor.flag(field) {
                wave.scalar[sgpr] = Some(Value::Bits(0));
                sgpr += 1;
            }
        }
        if descriptor.flag("system_sgpr_workgroup_info") {
            return Err(EvalError::InvalidConfig(
                "workgroup_info SGPR not implemented".into(),
            ));
        }
        let dimensions = descriptor.value("system_vgpr_workitem_id", 0);
        for lane in 0..64 {
            if wave.valid & (1u64 << lane) == 0 {
                continue;
            }
            let linear = wave.id * 64 + lane as u32;
            let x = linear % self.config.block_dim.0;
            let y = (linear / self.config.block_dim.0) % self.config.block_dim.1;
            let z = linear / (self.config.block_dim.0 * self.config.block_dim.1);
            for (register, value) in [(0, x), (1, y), (2, z)] {
                if register as u64 <= dimensions {
                    wave.vector.insert((register, lane), Value::Bits(value));
                }
            }
        }
        Ok(())
    }
    pub fn execute(mut self) -> RunArtifacts {
        let end = self.run();
        let (terminal, outputs) = match end {
            Ok(()) => {
                let outputs = self.extract().map_err(OutputsUnavailable::Extraction);
                (Terminal::Completed, outputs)
            }
            Err(error) => {
                let cause = if matches!(error, EvalError::Unsupported { .. }) {
                    AbortCause::Unsupported
                } else {
                    AbortCause::Error
                };
                let (thread, pc) = match &error {
                    EvalError::Invalid { wave, pc, .. } => {
                        (Some(ThreadIx(wave * 64)), Some(ProgramPoint(*pc as u32)))
                    }
                    EvalError::Unsupported { pc, .. } => (None, Some(ProgramPoint(*pc as u32))),
                    _ => (None, None),
                };
                (
                    Terminal::Aborted {
                        thread,
                        pc,
                        cause,
                        reason: error.to_string(),
                    },
                    Err(OutputsUnavailable::Aborted(error)),
                )
            }
        };
        RunArtifacts {
            arena: self.arena,
            outputs,
            graph: self.builder.finish(terminal),
            stats: self.stats,
            op_counts: self.op_counts,
        }
    }
    fn extract(&mut self) -> Result<Vec<(String, Vec<(u64, ExprId)>)>, EvalError> {
        let mut outputs = Vec::new();
        for array in &self.config.arrays {
            if !array.kind.is_output() {
                continue;
            }
            let mut elements = Vec::new();
            for index in 0..array.len {
                let addr = array.base + array.elem_width * index;
                let fully_written = (0..array.elem_width).all(|byte| {
                    self.global
                        .written
                        .range(..=addr + byte)
                        .next_back()
                        .is_some_and(|(&start, &width)| addr + byte - start < width)
                });
                if fully_written {
                    elements.push((
                        index,
                        self.global
                            .expression(addr, array.elem_width, &mut self.arena)
                            .map_err(|what| EvalError::Invalid {
                                wave: 0,
                                lane: None,
                                pc: 0,
                                what,
                            })?,
                    ));
                }
            }
            outputs.push((array.name.clone(), elements));
        }
        Ok(outputs)
    }
    fn run(&mut self) -> Result<(), EvalError> {
        loop {
            if self.waves.iter().all(|wave| wave.exited) {
                return Ok(());
            }
            let mut progress = false;
            for index in 0..self.waves.len() {
                if self.waves[index].exited || self.waves[index].at_barrier.is_some() {
                    continue;
                }
                if self.stats.instructions >= self.config.max_instructions {
                    return Err(EvalError::BudgetExceeded {
                        limit: self.config.max_instructions,
                    });
                }
                let mut wave =
                    std::mem::replace(&mut self.waves[index], Wave::new(index as u32, 1));
                let step = self.step(&mut wave);
                self.waves[index] = wave;
                step?;
                progress = true;
            }
            if self.waves.iter().any(|wave| wave.at_barrier.is_some())
                && self
                    .waves
                    .iter()
                    .filter(|wave| !wave.exited)
                    .all(|wave| wave.at_barrier.is_some())
            {
                if self.waves.iter().any(|wave| wave.exited) {
                    return Err(EvalError::Unsupported {
                        pc: 0,
                        what: "barrier with a previously terminated wave".into(),
                    });
                }
                let generation = self.waves[0].at_barrier.unwrap();
                if self
                    .waves
                    .iter()
                    .any(|wave| wave.at_barrier != Some(generation))
                {
                    return Err(EvalError::Invalid {
                        wave: 0,
                        lane: None,
                        pc: 0,
                        what: "barrier generation mismatch".into(),
                    });
                }
                for wave in &mut self.waves {
                    self.builder.amd_event(
                        wave.id,
                        ProgramPoint(wave.pc as u32),
                        AmdEventKind::BarrierRelease { generation },
                    );
                    wave.at_barrier = None;
                    wave.generation += 1;
                    wave.pc += 1;
                }
                progress = true;
            }
            if !progress {
                return Err(EvalError::Invalid {
                    wave: 0,
                    lane: None,
                    pc: 0,
                    what: "workgroup rendezvous made no progress".into(),
                });
            }
        }
    }
    fn instruction_registers(
        &self,
        instruction: &Instruction,
        wave: &Wave,
    ) -> (Vec<AmdRegister>, Vec<AmdRegister>) {
        fn add(operand: &Operand, mask: u64, result: &mut Vec<AmdRegister>) {
            match operand {
                Operand::Register(register) => {
                    let file = match register.class {
                        RegisterClass::Scalar => AmdRegisterFile::Scalar,
                        RegisterClass::Vector => AmdRegisterFile::Vector,
                        RegisterClass::Accumulator => AmdRegisterFile::Accumulator,
                        RegisterClass::Special => return,
                    };
                    if mask==0 && register.class!=RegisterClass::Scalar {return;}
                    for component in 0..register.count {
                        result.push(AmdRegister {
                            file,
                            index: register.index + component,
                            lanes: if register.class == RegisterClass::Scalar {
                                u64::MAX
                            } else {
                                mask
                            },
                        });
                    }
                }
                Operand::Modified { value, .. } => add(value, mask, result),
                _ => {}
            }
        }
        let mut reads = Vec::new();
        let mut writes = Vec::new();
        let mnemonic=instruction.mnemonic.trim_end_matches("_e32").trim_end_matches("_e64");
        if mnemonic=="v_readfirstlane_b32" || mnemonic=="v_readlane_b32" {
            let lane=if mnemonic=="v_readfirstlane_b32" {wave.exec.trailing_zeros().min(63)}else{wave.bits(&instruction.operands[2],0).unwrap_or(0)&63};
            add(&instruction.operands[0],u64::MAX,&mut writes);
            add(&instruction.operands[1],1u64<<lane,&mut reads);
            if instruction.operands.len()>2{add(&instruction.operands[2],u64::MAX,&mut reads);}
            return (reads,writes);
        }
        if mnemonic=="v_writelane_b32" {
            let lane=wave.bits(&instruction.operands[2],0).unwrap_or(0)&63;
            add(&instruction.operands[0],1u64<<lane,&mut writes);
            add(&instruction.operands[1],u64::MAX,&mut reads);add(&instruction.operands[2],u64::MAX,&mut reads);
            return (reads,writes);
        }
        let store =
            instruction.mnemonic.contains("store") || instruction.mnemonic.starts_with("ds_write");
        let no_destination = matches!(
            instruction.opcode,
            Opcode::Branch | Opcode::Wait | Opcode::Barrier | Opcode::Control
        ) || instruction.mnemonic.starts_with("s_cmp");
        for (index, operand) in instruction.operands.iter().enumerate() {
            if (index == 0 || (index==1 && (mnemonic.starts_with("v_add_co_")||mnemonic.starts_with("v_addc_co_")||mnemonic.starts_with("v_sub_co_")||mnemonic.starts_with("v_subb_co_")||mnemonic.starts_with("v_subrev_co_")||mnemonic.starts_with("v_subbrev_co_")))) && !store && !no_destination {
                add(operand, wave.exec, &mut writes)
            } else {
                add(operand, wave.exec, &mut reads)
            }
        }
        (reads, writes)
    }
    fn step(&mut self, wave: &mut Wave) -> Result<(), EvalError> {
        let instruction = self
            .program
            .instructions
            .get(wave.pc)
            .ok_or_else(|| wave.fail(None, "fell off kernel without s_endpgm"))?;
        let instruction = instruction.clone();
        let (reads, writes) = self.instruction_registers(&instruction, wave);
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::Instruction {
                exec_mask: wave.exec,
                reads,
                writes,
            },
        );
        self.stats.instructions += 1;
        *self
            .op_counts
            .entry(super::interp_kind(instruction.opcode))
            .or_default() += 1;
        let name = instruction
            .mnemonic
            .trim_end_matches("_e32")
            .trim_end_matches("_e64")
            .trim_end_matches("_sdwa");
        match instruction.opcode {
            Opcode::ScalarMemory | Opcode::VectorMemory | Opcode::Lds => {
                self.memory_instruction(wave, &instruction)?
            }
            Opcode::Wait => self.wait(wave, &instruction)?,
            Opcode::Barrier => {
                self.builder.amd_event(
                    wave.id,
                    ProgramPoint(wave.pc as u32),
                    AmdEventKind::BarrierArrive {
                        generation: wave.generation,
                        exec_mask: wave.exec,
                    },
                );
                wave.at_barrier = Some(wave.generation);
                self.stats.block_syncs += 1;
                return Ok(());
            }
            Opcode::Branch => {
                let take = match name {
                    "s_branch" => true,
                    "s_cbranch_scc0" => !wave.scc,
                    "s_cbranch_scc1" => wave.scc,
                    "s_cbranch_vccz" => wave.vcc == 0,
                    "s_cbranch_vccnz" => wave.vcc != 0,
                    "s_cbranch_execz" => wave.exec == 0,
                    "s_cbranch_execnz" => wave.exec != 0,
                    _ => return Err(self.unsupported(wave, &instruction)),
                };
                if take {
                    let Some(Operand::BranchTarget(target)) = instruction.operands.first() else {
                        return Err(wave.fail(None, "unresolved branch"));
                    };
                    wave.pc = *target;
                    return Ok(());
                }
            }
            Opcode::Control => match name {
                "s_endpgm" => {
                    for lane in 0..64 {
                        if wave.valid & (1u64 << lane) != 0 {
                            self.builder
                                .exit(ThreadIx(wave.id * 64 + lane), ProgramPoint(wave.pc as u32));
                        }
                    }
                    wave.exited = true;
                }
                "s_nop" => {
                    let Some(Operand::Integer(count))=instruction.operands.first() else {return Err(self.unsupported(wave,&instruction));};
                    if !(0..=15).contains(count){return Err(wave.fail(None,"s_nop wait count outside 0..15"));}
                    self.builder.amd_event(wave.id,ProgramPoint(wave.pc as u32),AmdEventKind::Delay{cycles:*count as u16+1});
                }
                _ => return Err(self.unsupported(wave, &instruction)),
            },
            Opcode::ScalarAlu => self.scalar(wave, &instruction, name)?,
            Opcode::VectorAlu => self.vector(wave, &instruction, name)?,
            Opcode::Matrix => self.matrix(wave,&instruction)?,
        }
        wave.pc += 1;
        Ok(())
    }
    fn unsupported(&self, wave: &Wave, instruction: &Instruction) -> EvalError {
        EvalError::Unsupported {
            pc: wave.pc,
            what: format!("{} {:?}", instruction.mnemonic, instruction.modifiers),
        }
    }
    fn real(&mut self, wave: &Wave, operand: &Operand, lane: u8) -> Result<ExprId, EvalError> {
        if let Operand::Modified {
            value,
            negate,
            absolute,
        } = operand
        {
            let mut expression = self.real(wave, value, lane)?;
            if *absolute {
                expression = self.arena.abs(expression);
            }
            if *negate {
                expression = self.arena.neg(expression);
            }
            return Ok(expression);
        }
        wave.value(operand, lane)?
            .real(&mut self.arena)
            .map_err(|e| wave.fail(Some(lane), e))
    }
    fn half(&mut self,wave:&Wave,operand:&Operand,lane:u8,high:bool)->Result<ExprId,EvalError>{
        if let Operand::Modified{value,negate,absolute}=operand {let mut expr=self.half(wave,value,lane,high)?;if *absolute{expr=self.arena.abs(expr);}if *negate{expr=self.arena.neg(expr);}return Ok(expr);}
        match wave.value(operand,lane)? {
            Value::Halves(lo,hi)=>Ok(if high{hi}else{lo}),
            Value::Half(expr)=>Ok(if high{self.arena.int(0)}else{expr}),
            Value::Bits(bits)|Value::Integer(bits)=>{let bits=if high{bits>>16}else{bits&0xffff};let sign=if bits&0x8000==0{1.0}else{-1.0};let exponent=(bits>>10)&31;let fraction=bits&1023;let value=if exponent==31{if fraction!=0{return Err(wave.fail(Some(lane),"half NaN outside real arithmetic model"));}sign*f64::INFINITY}else if exponent==0{sign*(fraction as f64)*2f64.powi(-24)}else{sign*(1.0+fraction as f64/1024.0)*2f64.powi(exponent as i32-15)};self.arena.float_from_f64(value).map_err(|e|wave.fail(Some(lane),e.to_string()))},
            Value::Real(_)=>Err(EvalError::Unsupported{pc:wave.pc,what:"symbolic f32 bits reinterpreted as half".into()}),
        }
    }
    fn scalar(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        name: &str,
    ) -> Result<(), EvalError> {
        let o = &instruction.operands;
        if !instruction.modifiers.is_empty() {
            return Err(self.unsupported(wave, instruction));
        }
        if name.starts_with("s_cmp_") {
            let a = wave.bits(&o[0], 0)?;
            let b = wave.bits(&o[1], 0)?;
            let signed = name.ends_with("i32");
            let cmp = name
                .trim_start_matches("s_cmp_")
                .trim_end_matches("_u32")
                .trim_end_matches("_i32");
            wave.scc = compare(
                cmp,
                if signed { a as i32 as i64 } else { a as i64 },
                if signed { b as i32 as i64 } else { b as i64 },
            )
            .ok_or_else(|| self.unsupported(wave, instruction))?;
            return Ok(());
        }
        let dest = &o[0];
        if name == "s_mov_b64" {
            let bits = wave.wide(&o[1], 0)?;
            return wave.put_wide(dest, 0, bits);
        }
        if name == "s_mov_b32" {
            let value = wave.value(&o[1], 0)?;
            return wave.put_value(dest, 0, value);
        }
        if name == "s_cselect_b32" || name == "s_cselect_b64" {
            let source = if wave.scc { &o[1] } else { &o[2] };
            return if name.ends_with("64") {
                let bits = wave.wide(source, 0)?;
                wave.put_wide(dest, 0, bits)
            } else {
                let value = wave.value(source, 0)?;
                wave.put_value(dest, 0, value)
            };
        }
        if name.ends_with("b64") {
            let a = wave.wide(&o[1], 0)?;
            let b = if o.len() > 2 { wave.wide(&o[2], 0)? } else { 0 };
            let old_exec = wave.exec;
            let value = match name {
                "s_and_b64" => a & b,
                "s_or_b64" => a | b,
                "s_xor_b64" => a ^ b,
                "s_andn2_b64" => a & !b,
                "s_orn2_b64" => a | !b,
                "s_not_b64" => !a,
                "s_and_saveexec_b64" => {
                    wave.exec &= a;
                    old_exec
                }
                "s_or_saveexec_b64" => {
                    wave.exec |= a;
                    old_exec
                }
                "s_xor_saveexec_b64" => {
                    wave.exec ^= a;
                    old_exec
                }
                "s_andn2_saveexec_b64" => {
                    wave.exec &= !a;
                    old_exec
                }
                "s_lshl_b64" => a.wrapping_shl((b & 63) as u32),
                "s_lshr_b64" => a.wrapping_shr((b & 63) as u32),
                _ => return Err(self.unsupported(wave, instruction)),
            };
            wave.scc = if name.contains("saveexec") {
                wave.exec != 0
            } else {
                value != 0
            };
            return wave.put_wide(dest, 0, value);
        }
        let a = wave.bits(&o[1], 0)?;
        let b = if o.len() > 2 { wave.bits(&o[2], 0)? } else { 0 };
        let (value, scc) = match name {
            "s_add_u32" => {
                let (v, c) = a.overflowing_add(b);
                (v, c)
            }
            "s_addc_u32" => {
                let (v, c) = a.overflowing_add(b);
                let (v, d) = v.overflowing_add(wave.scc as u32);
                (v, c || d)
            }
            "s_sub_u32" => {
                let (v, c) = a.overflowing_sub(b);
                (v, c)
            }
            "s_subb_u32" => {
                let (v, c) = a.overflowing_sub(b);
                let (v, d) = v.overflowing_sub(wave.scc as u32);
                (v, c || d)
            }
            "s_mul_i32" => (a.wrapping_mul(b), wave.scc),
            "s_mul_hi_u32" => (((a as u64 * b as u64) >> 32) as u32, wave.scc),
            "s_and_b32" => (a & b, a & b != 0),
            "s_or_b32" => (a | b, a | b != 0),
            "s_xor_b32" => (a ^ b, a ^ b != 0),
            "s_andn2_b32" => (a & !b, a & !b != 0),
            "s_not_b32" => (!a, !a != 0),
            "s_lshl_b32" => (a.wrapping_shl(b & 31), a.wrapping_shl(b & 31) != 0),
            "s_lshr_b32" => (a.wrapping_shr(b & 31), a.wrapping_shr(b & 31) != 0),
            "s_ashr_i32" => (
                ((a as i32) >> (b & 31)) as u32,
                ((a as i32) >> (b & 31)) != 0,
            ),
            "s_min_u32" => (a.min(b), a < b),
            "s_max_u32" => (a.max(b), a > b),
            "s_min_i32" => ((a as i32).min(b as i32) as u32, (a as i32) < (b as i32)),
            "s_max_i32" => ((a as i32).max(b as i32) as u32, (a as i32) > (b as i32)),
            "s_bfe_u32" => {
                let offset = b & 31;
                let width = (b >> 16) & 127;
                let value = if width == 0 {
                    0
                } else {
                    (a >> offset)
                        & if width >= 32 {
                            u32::MAX
                        } else {
                            (1u32 << width) - 1
                        }
                };
                (value, value != 0)
            }
            _ => return Err(self.unsupported(wave, instruction)),
        };
        wave.scc = scc;
        wave.put_value(dest, 0, Value::Integer(value))
    }
    /// CDNA4 ISA §7.1.4, pp.47–50: K_L=1, H=4, B_I=1, M_I=4.
    /// A[i,k] and B[k,j] live on lanes i+16k and j+16k respectively;
    /// D[i,j] is register i%4 of lane j+16*floor(i/4).
    fn matrix(&mut self,wave:&mut Wave,instruction:&Instruction)->Result<(),EvalError>{
        if !matches!(instruction.mnemonic.as_str(),"v_mfma_f32_16x16x4_f32"|"v_mfma_f32_16x16x4f32") {
            return Err(self.unsupported(wave,instruction));
        }
        if instruction.modifiers.iter().any(|modifier| !matches!(modifier.name.as_str(),"cbsz"|"abid"|"blgp")||modifier.value.as_deref()!=Some("0")) {
            return Err(self.unsupported(wave,instruction));
        }
        if wave.exec!=u64::MAX||wave.valid!=u64::MAX {return Err(EvalError::Unsupported{pc:wave.pc,what:"MFMA requires a complete wave64 with all lanes active".into()});}
        let o=&instruction.operands;let destination=wave.destination(&o[0])?;
        if destination.count!=4||destination.index%2!=0{return Err(wave.fail(None,"MFMA f32_16x16x4 destination requires four registers aligned to two registers"));}
        let (_,writes)=self.instruction_registers(instruction,wave);
        let mut source_instruction=instruction.clone();source_instruction.operands=vec![o[0].clone(),o[1].clone(),o[2].clone()];
        let (sources_ab,_)=self.instruction_registers(&source_instruction,wave);
        source_instruction.operands=vec![o[0].clone(),o[3].clone()];let (accumulator,_)=self.instruction_registers(&source_instruction,wave);
        self.builder.amd_event(wave.id,ProgramPoint(wave.pc as u32),AmdEventKind::MatrixIssue{kind:AmdMatrixKind::F32_16x16x4,destinations:writes,sources_ab,accumulator});
        let mut a=Vec::with_capacity(64);let mut b=Vec::with_capacity(64);
        for lane in 0..64 {a.push(self.real(wave,&o[1],lane)?);b.push(self.real(wave,&o[2],lane)?);}
        let mut outputs=Vec::with_capacity(256);
        for lane in 0..64u8 {let column=lane as usize%16;
            for component in 0..4 {let row=(lane as usize/16)*4+component as usize;
                let mut sum=if let Operand::Register(register)=o[3] {if register.count!=4{return Err(wave.fail(Some(lane),"MFMA accumulator requires four registers"));}wave.reg(register,lane,component)?.real(&mut self.arena).map_err(|e|wave.fail(Some(lane),e))?}else{self.real(wave,&o[3],lane)?};
                for k in 0..4 {let product=self.arena.mul(a[row+16*k],b[column+16*k]);sum=self.arena.add(sum,product);}
                outputs.push((lane,component,sum));
            }
        }
        for (lane,component,expression) in outputs {wave.put(destination,lane,component,Value::Real(expression))?;}
        self.stats.warp_syncs+=1;Ok(())
    }
    fn vector(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        name: &str,
    ) -> Result<(), EvalError> {
        let half_select_high=instruction.modifiers.iter().any(|modifier|modifier.name=="src0_sel"&&modifier.value.as_deref()==Some("WORD_1"));
        if !instruction.modifiers.is_empty() && !(name=="v_cvt_f32_f16"&&instruction.modifiers.iter().all(|modifier|matches!((modifier.name.as_str(),modifier.value.as_deref()),("src0_sel",Some("WORD_0"|"WORD_1"))|("dst_sel",Some("DWORD"))|("dst_unused",Some("UNUSED_PAD"))))) {
            return Err(self.unsupported(wave, instruction));
        }
        let o = &instruction.operands;
        let lanes: Vec<_> = wave.active().collect();
        if name.starts_with("v_cmp_") || name.starts_with("v_cmpx_") {
            let cmpx = name.starts_with("v_cmpx_");
            let prefix = if cmpx { "v_cmpx_" } else { "v_cmp_" };
            let (condition, kind) = name
                .trim_start_matches(prefix)
                .rsplit_once('_')
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let start = if matches!(o.first(),Some(Operand::Register(reg)) if reg.class==RegisterClass::Special || reg.class==RegisterClass::Scalar)
            {
                1
            } else {
                0
            };
            let mut mask = 0u64;
            for lane in lanes {
                let result = if kind == "f32" {
                    let a = self.real(wave, &o[start], lane)?;
                    let b = self.real(wave, &o[start + 1], lane)?;
                    let expr = match condition {
                        "eq" => self.arena.eq(a, b),
                        "ne" | "neq" => self.arena.ne(a, b),
                        "lt" => self.arena.lt(a, b),
                        "le" => self.arena.le(a, b),
                        "gt" => self.arena.gt(a, b),
                        "ge" => self.arena.ge(a, b),
                        _ => return Err(self.unsupported(wave, instruction)),
                    };
                    match self.arena.node(expr) {
                        ExprNode::BoolConst(value) => *value,
                        _ => {
                            return Err(wave
                                .fail(Some(lane), "symbolic VCC comparison is not yet supported"));
                        }
                    }
                } else {
                    let a = wave.bits(&o[start], lane)?;
                    let b = wave.bits(&o[start + 1], lane)?;
                    let signed = kind == "i32";
                    compare(
                        condition,
                        if signed { a as i32 as i64 } else { a as i64 },
                        if signed { b as i32 as i64 } else { b as i64 },
                    )
                    .ok_or_else(|| self.unsupported(wave, instruction))?
                };
                if result {
                    mask |= 1u64 << lane;
                }
            }
            if start == 1 {
                wave.put_wide(&o[0], 0, mask)?;
            } else {
                wave.vcc = mask;
            }
            if cmpx {
                wave.exec &= mask;
            }
            return Ok(());
        }
        if name == "v_readfirstlane_b32" {
            let lane = wave.exec.trailing_zeros();
            if lane >= 64 {
                return Err(wave.fail(None, "readfirstlane with empty EXEC"));
            }
            let value = wave.value(&o[1], lane as u8)?;
            return wave.put_value(&o[0], 0, value);
        }
        if name == "v_readlane_b32" {
            let lane = wave.bits(&o[2], 0)?;
            if lane >= 64 {
                return Err(wave.fail(None, "readlane index out of range"));
            }
            let value = wave.value(&o[1], lane as u8)?;
            return wave.put_value(&o[0], 0, value);
        }
        if name == "v_writelane_b32" {
            let lane = wave.bits(&o[2], 0)?;
            if lane >= 64 {
                return Err(wave.fail(None, "writelane index out of range"));
            }
            let value = wave.value(&o[1], 0)?;
            return wave.put_value(&o[0], lane as u8, value);
        }
        if matches!(
            name,
            "v_add_co_u32"
                | "v_addc_co_u32"
                | "v_sub_co_u32"
                | "v_subb_co_u32"
                | "v_subrev_co_u32"
                | "v_subbrev_co_u32"
        ) {
            let incoming = if o.len() > 4 { wave.wide(&o[4], 0)? } else { 0 };
            let mut mask = 0;
            for lane in lanes {
                let a = wave.bits(&o[2], lane)?;
                let b = wave.bits(&o[3], lane)?;
                let carry = ((incoming >> lane) & 1) as u32;
                let (value, bit) = match name {
                    "v_add_co_u32" => a.overflowing_add(b),
                    "v_addc_co_u32" => {
                        let (v, c) = a.overflowing_add(b);
                        let (v, d) = v.overflowing_add(carry);
                        (v, c || d)
                    }
                    "v_sub_co_u32" => a.overflowing_sub(b),
                    "v_subrev_co_u32" => b.overflowing_sub(a),
                    "v_subb_co_u32" => {
                        let (v, c) = a.overflowing_sub(b);
                        let (v, d) = v.overflowing_sub(carry);
                        (v, c || d)
                    }
                    _ => {
                        let (v, c) = b.overflowing_sub(a);
                        let (v, d) = v.overflowing_sub(carry);
                        (v, c || d)
                    }
                };
                wave.put_value(&o[0], lane, Value::Integer(value))?;
                if bit {
                    mask |= 1u64 << lane;
                }
            }
            return wave.put_wide(&o[1], 0, mask);
        }
        for lane in lanes {
            let value = match name {
                "v_cvt_f32_f16"=>Value::Real(self.half(wave,&o[1],lane,half_select_high)?),
                "v_cvt_f16_f32"=>Value::Half(self.real(wave,&o[1],lane)?),
                "v_cvt_pkrtz_f16_f32"|"v_cvt_pk_f16_f32"=>Value::Halves(self.real(wave,&o[1],lane)?,self.real(wave,&o[2],lane)?),
                "v_pack_b32_f16"=>Value::Halves(self.half(wave,&o[1],lane,false)?,self.half(wave,&o[2],lane,false)?),
                "v_add_f16"|"v_sub_f16"|"v_mul_f16"|"v_max_f16"|"v_min_f16"=>{let a=self.half(wave,&o[1],lane,false)?;let b=self.half(wave,&o[2],lane,false)?;Value::Half(match name{"v_add_f16"=>self.arena.add(a,b),"v_sub_f16"=>self.arena.sub(a,b),"v_mul_f16"=>self.arena.mul(a,b),"v_max_f16"=>self.arena.max(a,b),_=>self.arena.min(a,b)})},
                "v_pk_add_f16"|"v_pk_mul_f16"|"v_pk_max_f16"|"v_pk_min_f16"|"v_pk_fma_f16"=>{let mut pair=Vec::with_capacity(2);for high in [false,true]{let a=self.half(wave,&o[1],lane,high)?;let b=self.half(wave,&o[2],lane,high)?;pair.push(match name{"v_pk_add_f16"=>self.arena.add(a,b),"v_pk_mul_f16"=>self.arena.mul(a,b),"v_pk_max_f16"=>self.arena.max(a,b),"v_pk_min_f16"=>self.arena.min(a,b),_=>{let c=self.half(wave,&o[3],lane,high)?;self.arena.fma(a,b,c)}});}Value::Halves(pair[0],pair[1])},
                "v_mov_b32" | "v_accvgpr_read_b32" | "v_accvgpr_write_b32" => {
                    wave.value(&o[1], lane)?
                }
                "v_cndmask_b32" => {
                    let mask = if o.len() > 3 {
                        wave.wide(&o[3], lane)?
                    } else {
                        wave.vcc
                    };
                    wave.value(
                        if mask & (1u64 << lane) == 0 {
                            &o[1]
                        } else {
                            &o[2]
                        },
                        lane,
                    )?
                }
                "v_lshlrev_b64" | "v_lshrrev_b64" => {
                    let shift = wave.bits(&o[1], lane)? & 63;
                    let bits = wave.wide(&o[2], lane)?;
                    wave.put_wide(
                        &o[0],
                        lane,
                        if name == "v_lshlrev_b64" {
                            bits.wrapping_shl(shift)
                        } else {
                            bits >> shift
                        },
                    )?;
                    continue;
                }
                "v_lshl_add_u64" => {
                    let base = wave.wide(&o[1], lane)?;
                    let shift = wave.bits(&o[2], lane)? & 63;
                    let addend = wave.wide(&o[3], lane)?;
                    wave.put_wide(&o[0], lane, base.wrapping_shl(shift).wrapping_add(addend))?;
                    continue;
                }
                "v_add_f32" | "v_sub_f32" | "v_subrev_f32" | "v_mul_f32" | "v_max_f32"
                | "v_min_f32" => {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    Value::Real(match name {
                        "v_add_f32" => self.arena.add(a, b),
                        "v_sub_f32" => self.arena.sub(a, b),
                        "v_subrev_f32" => self.arena.sub(b, a),
                        "v_mul_f32" => self.arena.mul(a, b),
                        "v_max_f32" => self.arena.max(a, b),
                        _ => self.arena.min(a, b),
                    })
                }
                "v_fma_f32" | "v_mad_f32" | "v_fmac_f32"=> {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    let c = self.real(wave, if name=="v_fmac_f32"{&o[0]}else{&o[3]}, lane)?;
                    Value::Real(self.arena.fma(a, b, c))
                }
                "v_rcp_f32" | "v_sqrt_f32" | "v_rsq_f32" | "v_exp_f32" | "v_log_f32" => {
                    let a = self.real(wave, &o[1], lane)?;
                    let result = match name {
                        "v_rcp_f32" => self.arena.rcp(a),
                        "v_sqrt_f32" => self.arena.sqrt(a),
                        "v_rsq_f32" => {
                            let root = self.arena.sqrt(a);
                            self.arena.rcp(root)
                        }
                        "v_exp_f32" => {
                            let ln2 = self.arena.float_from_f64(std::f64::consts::LN_2).unwrap();
                            let scaled = self.arena.mul(a, ln2);
                            self.arena.exp(scaled)
                        }
                        _ => {
                            let ln2 = self.arena.float_from_f64(std::f64::consts::LN_2).unwrap();
                            let log = self.arena.log(a);
                            self.arena.div(log, ln2)
                        }
                    };
                    Value::Real(result)
                }
                "v_cvt_f32_u32" | "v_cvt_f32_i32" => {
                    let bits = wave.bits(&o[1], lane)?;
                    Value::Real(self.arena.int(if name == "v_cvt_f32_i32" {
                        bits as i32 as i64
                    } else {
                        bits as i64
                    }))
                }
                _ => {
                    let a = wave.bits(&o[1], lane)?;
                    let b = if o.len() > 2 {
                        wave.bits(&o[2], lane)?
                    } else {
                        0
                    };
                    let value = match name {
                        "v_add_u32" | "v_add_nc_u32" => a.wrapping_add(b),
                        "v_sub_u32" | "v_sub_nc_u32" => a.wrapping_sub(b),
                        "v_subrev_u32" => b.wrapping_sub(a),
                        "v_mul_lo_u32" | "v_mul_lo_i32" => a.wrapping_mul(b),
                        "v_mul_hi_u32" => ((a as u64 * b as u64) >> 32) as u32,
                        "v_mul_u32_u24" => (a & 0xffffff).wrapping_mul(b & 0xffffff),
                        "v_and_b32" => a & b,
                        "v_or_b32" => a | b,
                        "v_xor_b32" => a ^ b,
                        "v_not_b32" => !a,
                        "v_lshlrev_b32" => b.wrapping_shl(a & 31),
                        "v_lshrrev_b32" => b.wrapping_shr(a & 31),
                        "v_ashrrev_i32" => ((b as i32) >> (a & 31)) as u32,
                        "v_min_u32" => a.min(b),
                        "v_max_u32" => a.max(b),
                        "v_min_i32" => (a as i32).min(b as i32) as u32,
                        "v_max_i32" => (a as i32).max(b as i32) as u32,
                        "v_mad_u32_u24" => (a & 0xffffff)
                            .wrapping_mul(b & 0xffffff)
                            .wrapping_add(wave.bits(&o[3], lane)?),
                        "v_lshl_add_u32" => {
                            a.wrapping_shl(b & 31).wrapping_add(wave.bits(&o[3], lane)?)
                        }
                        "v_add_lshl_u32" => {
                            a.wrapping_add(b).wrapping_shl(wave.bits(&o[3], lane)? & 31)
                        }
                        "v_lshl_or_b32" => a.wrapping_shl(b & 31) | wave.bits(&o[3], lane)?,
                        "v_mbcnt_lo_u32_b32" => {
                            let below = if lane >= 32 {
                                u32::MAX
                            } else if lane == 0 {
                                0
                            } else {
                                (1u32 << lane) - 1
                            };
                            (a & below).count_ones().wrapping_add(b)
                        }
                        "v_mbcnt_hi_u32_b32" => {
                            let below = if lane <= 32 {
                                0
                            } else {
                                (1u32 << (lane - 32)) - 1
                            };
                            (a & below).count_ones().wrapping_add(b)
                        }
                        _ => return Err(self.unsupported(wave, instruction)),
                    };
                    Value::Integer(value)
                }
            };
            wave.put_value(&o[0], lane, value)?;
        }
        Ok(())
    }
    fn wait(&mut self, wave: &Wave, instruction: &Instruction) -> Result<(), EvalError> {
        let (mut vmcnt, mut lgkmcnt, mut expcnt) = (None, None, None);
        for operand in &instruction.operands {
            match operand {
                Operand::WaitCounter { name, value } => {
                    let value = u16::try_from(*value)
                        .map_err(|_| wave.fail(None, "wait threshold exceeds range"))?;
                    match name.as_str() {
                        "vmcnt" => vmcnt = Some(value),
                        "lgkmcnt" => lgkmcnt = Some(value),
                        "expcnt" => expcnt = Some(value),
                        _ => return Err(self.unsupported(wave, instruction)),
                    }
                }
                Operand::Integer(value) if instruction.mnemonic == "s_waitcnt" => {
                    let bits = *value as u16;
                    vmcnt = Some((bits & 15) | ((bits >> 10) & 48));
                    expcnt = Some((bits >> 4) & 7);
                    lgkmcnt = Some((bits >> 8) & 15);
                }
                _ => return Err(self.unsupported(wave, instruction)),
            }
        }
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::Wait {
                vmcnt,
                lgkmcnt,
                expcnt,
            },
        );
        Ok(())
    }
    fn memory_instruction(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        let name = instruction.mnemonic.as_str();
        let o = &instruction.operands;
        if name == "ds_bpermute_b32" || name == "ds_permute_b32" {
            return self.permute(wave, instruction);
        }
        let store = name.contains("store") || name.starts_with("ds_write");
        let scalar = instruction.opcode == Opcode::ScalarMemory;
        let lds = instruction.opcode == Opcode::Lds;
        if !scalar && wave.exec == 0 {
            return Ok(());
        }
        let flat = name.starts_with("flat_");
        if !(name.starts_with("s_load_")
            || name.starts_with("global_load_")
            || name.starts_with("global_store_")
            || flat
            || name.starts_with("ds_read_")
            || name.starts_with("ds_write_"))
        {
            return Err(self.unsupported(wave, instruction));
        }
        let offset =
            instruction
                .modifiers
                .iter()
                .try_fold(0u64, |offset, modifier| match modifier.name.as_str() {
                    "offset" => modifier
                        .value
                        .as_ref()
                        .and_then(|value| parse_u64(value))
                        .ok_or_else(|| self.unsupported(wave, instruction)),
                    "glc" | "slc" | "dlc" => Ok(offset),
                    _ => Err(self.unsupported(wave, instruction)),
                })?;
        let registers = if name.contains("dwordx16") {
            16
        } else if name.contains("dwordx8") {
            8
        } else if name.contains("dwordx4") || name.ends_with("b128") {
            4
        } else if name.contains("dwordx2") || name.ends_with("b64") {
            2
        } else {
            1
        };
        let width = if name.contains("ushort") || name.ends_with("u16") || name.ends_with("b16") {
            2
        } else if name.contains("ubyte") || name.ends_with("u8") || name.ends_with("b8") {
            1
        } else {
            4
        };
        let class = if flat {
            AmdMemoryClass::Flat
        } else if scalar {
            AmdMemoryClass::ScalarMemory
        } else if lds {
            AmdMemoryClass::Lds
        } else {
            AmdMemoryClass::VectorMemory
        };
        let counters = if flat {
            vec![(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)]
        } else if scalar {
            vec![(AmdCounter::Lgkm, if registers > 1 { 2 } else { 1 })]
        } else if lds {
            vec![(AmdCounter::Lgkm, 1)]
        } else {
            vec![(AmdCounter::Vm, 1)]
        };
        let (reads, writes) = self.instruction_registers(instruction, wave);
        let issue = self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations: if store { Vec::new() } else { writes },
                held_sources: if store { reads } else { Vec::new() },
            },
        );
        let lanes: Vec<_> = if scalar {
            vec![0]
        } else {
            wave.active().collect()
        };
        for lane in lanes {
            let (address, data_operand) = if scalar {
                (
                    wave.wide(&o[1], lane)?
                        .checked_add(wave.wide(&o[2], lane)?)
                        .and_then(|addr| addr.checked_add(offset))
                        .ok_or_else(|| wave.fail(Some(lane), "scalar load address overflow"))?,
                    &o[0],
                )
            } else if lds {
                if store {
                    (wave.bits(&o[0], lane)? as u64 + offset, &o[1])
                } else {
                    (wave.bits(&o[1], lane)? as u64 + offset, &o[0])
                }
            } else if store {
                (
                    wave.wide(&o[0], lane)?
                        .wrapping_add(if o.len() > 2 {
                            wave.wide(&o[2], lane)?
                        } else {
                            0
                        })
                        .checked_add(offset)
                        .ok_or_else(|| wave.fail(Some(lane), "store address overflow"))?,
                    &o[1],
                )
            } else {
                (
                    wave.wide(&o[1], lane)?
                        .wrapping_add(if o.len() > 2 {
                            wave.wide(&o[2], lane)?
                        } else {
                            0
                        })
                        .checked_add(offset)
                        .ok_or_else(|| wave.fail(Some(lane), "load address overflow"))?,
                    &o[0],
                )
            };
            let register = wave.destination(data_operand)?;
            for component in 0..registers {
                let addr = address
                    .checked_add(component as u64 * width)
                    .ok_or_else(|| wave.fail(Some(lane), "memory address overflow"))?;
                let abi = scalar && addr >= KERNARG_BASE;
                if !abi {
                    self.validate_address(wave, lane, lds, addr, width)?;
                }
                let value = if store {
                    let value = wave.reg(register, lane, component)?;
                    let memory = if lds { &mut self.lds } else { &mut self.global };
                    memory
                        .write(addr, width, value)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    Some(value)
                } else {
                    let memory = if scalar && addr >= DISPATCH_BASE {
                        &self.dispatch
                    } else if abi {
                        &self.kernargs
                    } else if lds {
                        &self.lds
                    } else {
                        &self.global
                    };
                    let value = memory.read(addr, width).map_err(|e| {
                        wave.fail(
                            Some(lane),
                            format!(
                                "{} {addr:#x}: {e}",
                                if lds {
                                    "LDS"
                                } else if abi {
                                    "kernarg"
                                } else {
                                    "global"
                                }
                            ),
                        )
                    })?;
                    wave.put(register, lane, component, value)?;
                    None
                };
                {
                    let stored = if let Some(value) = value {
                        Some(self.builder.value(match value {
                            Value::Real(expression) | Value::Half(expression) => StoredValue::Scalar(expression),
                            Value::Bits(bits) | Value::Integer(bits) => StoredValue::Scalar(self.arena.int(bits as i64)),
                            Value::Halves(lo, hi) => StoredValue::Pair(lo, hi),
                        }))
                    } else {
                        None
                    };
                    let effect = self.builder.thread_access(
                        ThreadIx(wave.id * 64 + lane as u32),
                        ProgramPoint(wave.pc as u32),
                        MemAccess {
                            space: if lds { Space::Shared } else { Space::Global },
                            mode: if store {
                                AccessMode::Write
                            } else {
                                AccessMode::Read
                            },
                            ordering: OrderingKind::Ordinary,
                            proxy: Proxy::Generic,
                            footprint: Footprint::Bytes {
                                addr,
                                width: width as u32,
                            },
                            role: OperandRole::Plain,
                            attributed: ThreadIx(wave.id * 64 + lane as u32),
                            value: stored,
                        },
                    );
                    self.builder.amd_memory_effect(issue, effect);
                }
            }
        }
        Ok(())
    }
    fn permute(&mut self, wave: &mut Wave, instruction: &Instruction) -> Result<(), EvalError> {
        if !instruction.modifiers.is_empty() {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec == 0 {
            return Ok(());
        }
        let o = &instruction.operands;
        let (reads, writes) = self.instruction_registers(instruction, wave);
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::CrossLane,
                counters: vec![(AmdCounter::Lgkm, 1)],
                destinations: writes,
                held_sources: reads,
            },
        );
        let mut data = [Value::Bits(0); 64];
        let mut addresses = [0usize; 64];
        let lanes: Vec<_> = wave.active().collect();
        for &lane in &lanes {
            data[lane as usize] = wave.value(&o[2], lane)?;
            addresses[lane as usize] = ((wave.bits(&o[1], lane)? >> 2) & 63) as usize;
        }
        if instruction.mnemonic == "ds_bpermute_b32" {
            for lane in lanes {
                wave.put_value(&o[0], lane, data[addresses[lane as usize]])?;
            }
        } else {
            let mut outputs = [Value::Bits(0); 64];
            for &lane in &lanes {
                outputs[addresses[lane as usize]] = data[lane as usize];
            }
            for lane in lanes {
                wave.put_value(&o[0], lane, outputs[lane as usize])?;
            }
        }
        self.stats.warp_syncs += 1;
        Ok(())
    }
    fn validate_address(
        &self,
        wave: &Wave,
        lane: u8,
        lds: bool,
        addr: u64,
        width: u64,
    ) -> Result<(), EvalError> {
        let valid = if lds {
            addr <= self.lds_size && width <= self.lds_size - addr
        } else {
            self.config.arrays.iter().any(|array| {
                width <= array.size_bytes()
                    && addr >= array.base
                    && addr - array.base <= array.size_bytes() - width
            })
        };
        if !valid {
            return Err(wave.fail(
                Some(lane),
                format!(
                    "out-of-bounds {} access [{addr:#x},+{width})",
                    if lds { "LDS" } else { "global" }
                ),
            ));
        }
        if addr % width.min(4) != 0 {
            return Err(wave.fail(
                Some(lane),
                format!("misaligned access at {addr:#x} width {width}"),
            ));
        }
        Ok(())
    }
}

fn compare(condition: &str, a: i64, b: i64) -> Option<bool> {
    Some(match condition {
        "eq" => a == b,
        "ne" | "lg" | "neq" => a != b,
        "lt" => a < b,
        "le" => a <= b,
        "gt" => a > b,
        "ge" => a >= b,
        _ => return None,
    })
}
fn parse_u64(value: &str) -> Option<u64> {
    if let Some(hex) = value.strip_prefix("0x") {
        u64::from_str_radix(hex, 16).ok()
    } else {
        value.parse().ok()
    }
}
