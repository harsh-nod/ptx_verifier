use super::{
    memory::Memory,
    value::{Value, WideKind},
};
use crate::{
    config::{AnalysisConfig, ArrayKind, ParamValue},
    ir::*,
};
use std::{collections::BTreeMap, error::Error, fmt};
use volta_expr::{ExprArena, ExprId, ExprNode};
use volta_graph::*;

const KERNARG_BASE: u64 = 0xffff_0000_0000;
const DISPATCH_BASE: u64 = 0xffff_1000_0000;
// Synthetic module storage is disjoint from host-bound arrays and analyzer ABI
// packets. Match the existing PTX module-window convention without a dependency.
pub const MODULE_GLOBAL_BASE: u64 = 0x7000_0000_0000_0000;

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
            Self::InvalidConfig(what) => write!(f, "invalid AMD configuration: {what}"),
            Self::Unsupported { pc, what } => {
                write!(f, "unsupported AMD instruction at pc {pc}: {what}")
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

#[derive(Debug, Clone)]
struct Wave {
    id: u32,
    width: u32,
    pc: usize,
    valid: u64,
    exec: u64,
    vcc: u64,
    vcc_defined: u8,
    vcc_predicates: [Option<Value>; 2],
    scc: bool,
    scc_defined: bool,
    m0: u32,
    scalar: Vec<Option<Value>>,
    temporary: [Option<Value>; 16],
    vector: BTreeMap<(u16, u8), Value>,
    accumulator: BTreeMap<(u16, u8), Value>,
    at_barrier: Option<u32>,
    generation: u32,
    signal_generation: Option<u32>,
    exited: bool,
}
impl Wave {
    fn new(id: u32, lanes: u32, width: u32) -> Self {
        let valid = if lanes == 64 {
            u64::MAX
        } else {
            (1u64 << lanes) - 1
        };
        Self {
            id,
            width,
            pc: 0,
            valid,
            exec: valid,
            vcc: 0,
            vcc_defined: 0,
            vcc_predicates: [None; 2],
            scc: false,
            scc_defined: false,
            m0: 0,
            scalar: vec![None; 128],
            temporary: [None; 16],
            vector: BTreeMap::new(),
            accumulator: BTreeMap::new(),
            at_barrier: None,
            generation: 0,
            signal_generation: None,
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
        (0..self.width as u8).filter(move |lane| mask & (1u64 << lane) != 0)
    }
    fn read_vcc(&self) -> Result<u64, EvalError> {
        if self.vcc_defined & ((1 << (self.width / 32)) - 1) != ((1 << (self.width / 32)) - 1) {
            return Err(self.fail(None, "uninitialized VCC flag (both halves must be defined)"));
        }
        if self.vcc_predicates.iter().any(Option::is_some) {
            return Err(self.fail(
                None,
                "symbolic predicate mask used as concrete VCC/control bits",
            ));
        }
        Ok(self.vcc)
    }
    fn read_scc(&self) -> Result<bool, EvalError> {
        if !self.scc_defined {
            return Err(self.fail(None, "uninitialized SCC flag"));
        }
        Ok(self.scc)
    }
    fn set_scc(&mut self, value: bool) {
        self.scc = value;
        self.scc_defined = true;
    }
    fn reg(&self, reg: Register, lane: u8, component: u16) -> Result<Value, EvalError> {
        let index = reg.index + component;
        let value = match reg.class {
            RegisterClass::Scalar => self.scalar.get(index as usize).copied().flatten(),
            RegisterClass::Temporary => self.temporary.get(index as usize).copied().flatten(),
            RegisterClass::Vector => self.vector.get(&(index, lane)).copied(),
            RegisterClass::Accumulator => self.accumulator.get(&(index, lane)).copied(),
            RegisterClass::Special => {
                let val = match reg.special {
                    Some(SpecialRegister::SharedBase) => {
                        if reg.count != 2 {
                            return Err(self.fail(
                                Some(lane),
                                "shared aperture source requires its approved64-bit profile",
                            ));
                        }
                        return Ok(if component == 0 {
                            Value::Bits(0)
                        } else {
                            Value::SharedApertureHi
                        });
                    }
                    Some(SpecialRegister::Exec) => self.exec,
                    Some(SpecialRegister::ExecLo) => self.exec as u32 as u64,
                    Some(SpecialRegister::ExecHi) => self.exec >> 32,
                    Some(SpecialRegister::Vcc) => {
                        if self.vcc_defined & (1 << component) == 0 {
                            return Err(self.fail(Some(lane), "uninitialized VCC flag component"));
                        }
                        if let Some(value) = self.vcc_predicates[component as usize] {
                            return Ok(value);
                        }
                        self.vcc
                    }
                    Some(SpecialRegister::VccLo) => {
                        if self.vcc_defined & 1 == 0 {
                            return Err(self.fail(Some(lane), "uninitialized VCC_LO flag"));
                        }
                        if let Some(value) = self.vcc_predicates[0] {
                            return Ok(value);
                        }
                        self.vcc as u32 as u64
                    }
                    Some(SpecialRegister::VccHi) => {
                        if self.vcc_defined & 2 == 0 {
                            return Err(self.fail(Some(lane), "uninitialized VCC_HI flag"));
                        }
                        if let Some(value) = self.vcc_predicates[1] {
                            return Ok(value);
                        }
                        self.vcc >> 32
                    }
                    Some(SpecialRegister::Scc) => self.read_scc()? as u64,
                    Some(SpecialRegister::M0) => {
                        return Err(EvalError::Unsupported {
                            pc: self.pc,
                            what: "initial M0 value is not part of the modeled kernel ABI".into(),
                        });
                    }
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
            RegisterClass::Temporary => {
                return Err(self.fail(Some(lane), "architected system inputs are read-only"));
            }
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
                let vcc_word = match reg.special {
                    Some(SpecialRegister::Vcc) => Some(component as usize),
                    Some(SpecialRegister::VccLo) => Some(0),
                    Some(SpecialRegister::VccHi) => Some(1),
                    _ => None,
                };
                if let Some(word) = vcc_word {
                    if matches!(value, Value::PredicateWord { .. }) {
                        self.vcc_predicates[word] = Some(value);
                        self.vcc_defined |= 1 << word;
                        return Ok(());
                    }
                    // Read/validate before clearing an existing predicate word.
                    value.bits().map_err(|e| self.fail(Some(lane), e))?;
                    self.vcc_predicates[word] = None;
                }
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
                            | (bits << (32 * component));
                        self.vcc_defined |= 1 << component;
                    }
                    Some(SpecialRegister::VccLo) => {
                        self.vcc = (self.vcc & 0xffff_ffff_0000_0000) | bits;
                        self.vcc_defined |= 1;
                    }
                    Some(SpecialRegister::VccHi) => {
                        self.vcc = (self.vcc & 0xffff_ffff) | (bits << 32);
                        self.vcc_defined |= 2;
                    }
                    Some(SpecialRegister::Scc) => self.set_scc(bits != 0),
                    Some(SpecialRegister::M0) => {
                        return Err(EvalError::Unsupported {
                            pc: self.pc,
                            what: "explicit M0 writes need software dependency-spacing checks"
                                .into(),
                        });
                    }
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
    fn move_wide(&mut self, destination: &Operand, source: &Operand) -> Result<(), EvalError> {
        if let Operand::Register(source) = source {
            if source.count == 2 {
                let values = [self.reg(*source, 0, 0)?, self.reg(*source, 0, 1)?];
                let destination = self.destination(destination)?;
                self.put(destination, 0, 0, values[0])?;
                return self.put(destination, 0, 1, values[1]);
            }
        }
        let bits = self.wide(source, 0)?;
        self.put_wide(destination, 0, bits)
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
    architecture: AmdArchitecture,
    byte_formats: BTreeMap<volta_expr::StringId, ByteFormat>,
    word_formats: BTreeMap<volta_expr::StringId, WordFormat>,
    predicate_masks: Vec<[ExprId; 64]>,
    xnack_replay_enabled: bool,
    module_globals: BTreeMap<String, GlobalAllocation>,
}
#[derive(Debug, Clone, Copy)]
struct GlobalAllocation {
    base: u64,
    size: u64,
    read_only: bool,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ByteFormat {
    OcpE4m3,
    SignedI8,
    UnsignedU8,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum WordFormat {
    Float32,
    Integer32,
    Float64,
    Float16,
    Bfloat16,
}
impl<'a> Interpreter<'a> {
    pub fn new(
        program: &'a LoweredKernel,
        config: AnalysisConfig,
        provenance: Provenance,
    ) -> Result<Self, EvalError> {
        config.validate().map_err(EvalError::InvalidConfig)?;
        let xnack_replay_enabled = provenance
            .targets
            .iter()
            .any(|target| target.split(':').any(|feature| feature == "xnack+"));
        let mut module_globals = BTreeMap::new();
        let mut module_end = MODULE_GLOBAL_BASE;
        for object in &program.globals {
            if object.symbol.is_empty()
                || object.size == 0
                || !object.alignment.is_power_of_two()
                || object.initial_bytes.len() as u64 != object.size
            {
                return Err(EvalError::InvalidConfig(format!(
                    "invalid size/alignment/initializer for module global '{}'",
                    object.symbol
                )));
            }
            let base = module_end
                .checked_add(object.alignment - 1)
                .map(|address| address & !(object.alignment - 1))
                .ok_or_else(|| {
                    EvalError::InvalidConfig(
                        "module-global alignment overflows address space".into(),
                    )
                })?;
            module_end = base.checked_add(object.size).ok_or_else(|| {
                EvalError::InvalidConfig("module-global window overflows address space".into())
            })?;
            if module_globals
                .insert(
                    object.symbol.clone(),
                    GlobalAllocation {
                        base,
                        size: object.size,
                        read_only: object.read_only,
                    },
                )
                .is_some()
            {
                return Err(EvalError::InvalidConfig(format!(
                    "duplicate module global '{}'",
                    object.symbol
                )));
            }
        }
        let mut bound_globals = std::collections::BTreeSet::new();
        for (name, _) in &config.global_values {
            if !bound_globals.insert(name) {
                return Err(EvalError::InvalidConfig(format!(
                    "duplicate module-global binding '{name}'"
                )));
            }
            let object = module_globals.get(name).ok_or_else(|| {
                EvalError::InvalidConfig(format!("no module global named '{name}'"))
            })?;
            if object.read_only {
                return Err(EvalError::InvalidConfig(format!(
                    "read-only module global '{name}' cannot be rebound"
                )));
            }
            if ![1, 2, 4, 8].contains(&object.size) {
                return Err(EvalError::InvalidConfig(format!(
                    "module-global binding '{name}' requires a scalar object of 1,2,4 or8 bytes"
                )));
            }
        }
        if module_end > MODULE_GLOBAL_BASE {
            for array in &config.arrays {
                if array.base < module_end && MODULE_GLOBAL_BASE < array.base + array.size_bytes() {
                    return Err(EvalError::InvalidConfig(format!(
                        "array '{}' overlaps the reserved module-global window",
                        array.name
                    )));
                }
            }
        }
        let threads = config
            .block_dim
            .0
            .checked_mul(config.block_dim.1)
            .and_then(|n| n.checked_mul(config.block_dim.2))
            .ok_or_else(|| EvalError::InvalidConfig("block dimension overflow".into()))?;
        if threads == 0 || threads > 1024 {
            return Err(EvalError::InvalidConfig(
                "native AMD workgroup must contain 1..=1024 workitems".into(),
            ));
        }
        if config.grid_dim.0 == 0 || config.grid_dim.1 == 0 || config.grid_dim.2 == 0 {
            return Err(EvalError::InvalidConfig(
                "grid dimensions must be nonzero".into(),
            ));
        }
        for (groups, threads) in [
            (config.grid_dim.0, config.block_dim.0),
            (config.grid_dim.1, config.block_dim.1),
            (config.grid_dim.2, config.block_dim.2),
        ] {
            if groups.checked_mul(threads).is_none() {
                return Err(EvalError::InvalidConfig(
                    "HSA grid size exceeds the 32-bit dispatch-packet field".into(),
                ));
            }
        }
        for array in &config.arrays {
            if array.kind == ArrayKind::IndexInput
                && array.elem_width < 4
                && array.len > 1u64 << (8 * array.elem_width)
            {
                return Err(EvalError::InvalidConfig(
                    "index array element width cannot represent its indices".into(),
                ));
            }
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
        let architecture = AmdArchitecture::from_targets(&provenance.targets).ok_or_else(|| {
            EvalError::InvalidConfig("expected one supported native AMD target".into())
        })?;
        if lds_size > architecture.lds_capacity() {
            return Err(EvalError::InvalidConfig(format!(
                "requested LDS exceeds {} capacity of {} bytes",
                architecture.name(),
                architecture.lds_capacity()
            )));
        }
        for allocation in &config.shared_allocations {
            if allocation
                .offset
                .checked_add(allocation.size)
                .is_none_or(|end| end > lds_size)
            {
                return Err(EvalError::InvalidConfig(format!(
                    "shared allocation '{}' exceeds configured LDS capacity",
                    allocation.name
                )));
            }
        }
        if program.descriptor.flag("tg_split") {
            return Err(EvalError::InvalidConfig(
                "tg_split workgroups require a different LDS/barrier execution model".into(),
            ));
        }
        fn registers(operand: &Operand, result: &mut Vec<Register>) {
            match operand {
                Operand::Register(register) => result.push(*register),
                Operand::Modified { value, .. } => registers(value, result),
                _ => {}
            }
        }
        let mut referenced = Vec::new();
        for instruction in &program.instructions {
            for operand in &instruction.operands {
                registers(operand, &mut referenced);
            }
        }
        if referenced
            .iter()
            .any(|register| register.class == RegisterClass::Accumulator)
        {
            let offset = program.descriptor.get("accum_offset").ok_or_else(|| {
                EvalError::InvalidConfig(
                    "AGPR use requires explicit accum_offset descriptor".into(),
                )
            })?;
            if offset < 4 || offset % 4 != 0 || offset > 256 {
                return Err(EvalError::InvalidConfig(
                    "invalid accumulator register offset".into(),
                ));
            }
            if referenced.iter().any(|register| {
                register.class == RegisterClass::Vector
                    && register.index as u64 + register.count as u64 > offset
            }) {
                return Err(EvalError::InvalidConfig(
                    "explicit VGPR range aliases the AGPR register window".into(),
                ));
            }
        }
        if program
            .descriptor
            .get("max_flat_workgroup_size")
            .is_some_and(|max| threads as u64 > max)
        {
            return Err(EvalError::InvalidConfig(
                "launch exceeds metadata max_flat_workgroup_size".into(),
            ));
        }
        for (field, actual) in [
            ("reqd_workgroup_size_x", config.block_dim.0),
            ("reqd_workgroup_size_y", config.block_dim.1),
            ("reqd_workgroup_size_z", config.block_dim.2),
        ] {
            if program
                .descriptor
                .get(field)
                .is_some_and(|required| required != actual as u64)
            {
                return Err(EvalError::InvalidConfig(format!(
                    "launch does not match metadata {field}"
                )));
            }
        }
        if program.descriptor.flag("wavefront_size32") != (architecture.wave_size() == 32) {
            return Err(EvalError::InvalidConfig(format!(
                "{} requires wave{}",
                architecture.name(),
                architecture.wave_size()
            )));
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
            architecture,
            byte_formats: BTreeMap::new(),
            word_formats: BTreeMap::new(),
            predicate_masks: Vec::new(),
            xnack_replay_enabled,
            module_globals,
        };
        result
            .builder
            .set_shared_allocation_layout(result.config.shared_allocations.clone());
        result.initialize_memory()?;
        for id in 0..threads.div_ceil(architecture.wave_size()) {
            let mut wave = Wave::new(
                id,
                (threads - id * architecture.wave_size()).min(architecture.wave_size()),
                architecture.wave_size(),
            );
            wave.m0 = lds_size as u32;
            result.initialize_wave(&mut wave)?;
            result.waves.push(wave);
        }
        Ok(result)
    }
    fn initialize_memory(&mut self) -> Result<(), EvalError> {
        for object in &self.program.globals {
            let allocation = self.module_globals[&object.symbol];
            if let Some((_, binding)) = self
                .config
                .global_values
                .iter()
                .find(|(name, _)| name == &object.symbol)
            {
                if object.size <= 4 {
                    let bits = (*binding as u64)
                        & if object.size == 4 {
                            u32::MAX as u64
                        } else {
                            (1u64 << (8 * object.size)) - 1
                        };
                    self.global.initialize(
                        allocation.base,
                        object.size,
                        Value::Integer(bits as u32),
                    );
                } else {
                    self.global
                        .initialize(allocation.base, 4, Value::Integer(*binding as u32));
                    self.global.initialize(
                        allocation.base + 4,
                        4,
                        Value::Integer((*binding as u64 >> 32) as u32),
                    );
                }
            } else {
                for (offset, &byte) in object.initial_bytes.iter().enumerate() {
                    self.global.initialize(
                        allocation.base + offset as u64,
                        1,
                        Value::Bits(byte as u32),
                    );
                }
            }
        }
        for array in &self.config.arrays {
            if !array.kind.is_input() {
                continue;
            }
            let name = self.arena.intern_string(array.name.clone());
            for index in 0..array.len {
                let addr = array.base + index * array.elem_width;
                if array.elem_width == 8 {
                    let expr = if array.kind == ArrayKind::IndexInput {
                        self.arena.int(index as i64)
                    } else {
                        self.arena.input_element(name, index)
                    };
                    let kind = if array.kind == ArrayKind::IndexInput {
                        WideKind::Integer
                    } else {
                        WideKind::Input
                    };
                    self.global.initialize(
                        addr,
                        4,
                        Value::WidePart {
                            expr,
                            high: false,
                            kind,
                        },
                    );
                    self.global.initialize(
                        addr + 4,
                        4,
                        Value::WidePart {
                            expr,
                            high: true,
                            kind,
                        },
                    );
                    continue;
                }
                let value = if array.kind == ArrayKind::IndexInput {
                    Value::Integer(index as u32)
                } else {
                    let expr = self.arena.input_element(name, index);
                    if array.elem_width == 1 {
                        Value::Byte(expr)
                    } else if array.elem_width == 2 {
                        Value::Half(expr)
                    } else {
                        Value::Input(expr)
                    }
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
                if let ParamValue::Bytes(bytes) = param {
                    if arg.value_kind != "by_value" || bytes.len() as u64 != arg.size {
                        return Err(EvalError::InvalidConfig(format!(
                            "byte payload for argument {:?} must match its by_value metadata size ({} bytes)",
                            arg.name, arg.size
                        )));
                    }
                    for (offset, byte) in bytes.iter().enumerate() {
                        self.kernargs.initialize(
                            KERNARG_BASE + arg.offset + offset as u64,
                            1,
                            Value::Bits(u32::from(*byte)),
                        );
                    }
                    continue;
                }
                if matches!(param, ParamValue::Float(_) | ParamValue::SymFloat(_)) {
                    let expected = match arg.size {
                        4 => "f32",
                        8 => "f64",
                        _ => {
                            return Err(EvalError::InvalidConfig(
                                "floating arguments require32-bit or64-bit storage".into(),
                            ));
                        }
                    };
                    if arg.value_kind != "by_value"
                        || arg.value_type.as_deref().is_some_and(|ty| ty != expected)
                    {
                        return Err(EvalError::InvalidConfig(format!(
                            "floating argument metadata must describe a by-value {expected}"
                        )));
                    }
                }
                match param {
                    ParamValue::Bytes(_) => unreachable!("native byte payload bound above"),
                    ParamValue::Int(value) => Some((*value as u64, None)),
                    ParamValue::Float(value) => Some((
                        if arg.size == 8 {
                            value.to_bits()
                        } else {
                            (*value as f32).to_bits() as u64
                        },
                        None,
                    )),
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
                    if arg.size == 8 {
                        self.kernargs.initialize(
                            KERNARG_BASE + arg.offset,
                            4,
                            Value::WidePart {
                                expr: expression,
                                high: false,
                                kind: WideKind::Float,
                            },
                        );
                        self.kernargs.initialize(
                            KERNARG_BASE + arg.offset + 4,
                            4,
                            Value::WidePart {
                                expr: expression,
                                high: true,
                                kind: WideKind::Float,
                            },
                        );
                    } else {
                        self.kernargs.initialize(
                            KERNARG_BASE + arg.offset,
                            4,
                            Value::Real(expression),
                        );
                    }
                } else if arg.value_kind.starts_with("hidden_") && arg.size == 4 {
                    // These fields are numeric launch quantities, rather than
                    // pointers or arbitrary data bits. Preserve that distinction
                    // when native code copies grid dimensions directly to output.
                    self.kernargs.initialize(
                        KERNARG_BASE + arg.offset,
                        4,
                        Value::Integer(bits as u32),
                    );
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
        if self.architecture == AmdArchitecture::Gfx1250 {
            // Single unclustered workgroup0, LLVM architected-SGPR ABI.
            wave.temporary[6] = Some(Value::PartialBits {
                bits: 0,
                defined: 0x0fff_ffff,
            });
            wave.temporary[7] = Some(Value::Integer(0));
            wave.temporary[9] = Some(Value::Integer(0));
            wave.temporary[8] = Some(Value::PartialBits {
                bits: wave.id << 25,
                defined: 0x3e00_0000,
            });
        }
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
        if descriptor
            .get("user_sgpr_count")
            .is_some_and(|count| count != sgpr as u64)
        {
            return Err(EvalError::InvalidConfig(format!(
                "descriptor user_sgpr_count disagrees with enabled ABI inputs: expected {sgpr}"
            )));
        }
        for field in [
            "system_sgpr_workgroup_id_x",
            "system_sgpr_workgroup_id_y",
            "system_sgpr_workgroup_id_z",
        ] {
            if descriptor.flag(field) && self.architecture != AmdArchitecture::Gfx1250 {
                wave.scalar[sgpr] = Some(Value::Integer(0));
                sgpr += 1;
            }
        }
        if descriptor.flag("system_sgpr_workgroup_info") {
            return Err(EvalError::InvalidConfig(
                "workgroup_info SGPR not implemented".into(),
            ));
        }
        let dimensions = descriptor.value("system_vgpr_workitem_id", 0);
        for lane in 0..wave.width as u8 {
            if wave.valid & (1u64 << lane) == 0 {
                continue;
            }
            let linear = wave.id * wave.width + lane as u32;
            let x = linear % self.config.block_dim.0;
            let y = (linear / self.config.block_dim.0) % self.config.block_dim.1;
            let z = linear / (self.config.block_dim.0 * self.config.block_dim.1);
            // gfx942/gfx950 use the packed-workitem-ID ABI: x in 9:0, enabled y in
            // 19:10 and enabled z in 29:20 of v0. v1/v2 are not initialized.
            let packed = x
                | if dimensions >= 1 { y << 10 } else { 0 }
                | if dimensions >= 2 { z << 20 } else { 0 };
            wave.vector.insert((0, lane), Value::Integer(packed));
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
                    EvalError::Invalid { wave, pc, .. } => (
                        Some(ThreadIx(wave * self.architecture.wave_size())),
                        Some(ProgramPoint(*pc as u32)),
                    ),
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
                let mut wave = std::mem::replace(
                    &mut self.waves[index],
                    Wave::new(index as u32, 1, self.architecture.wave_size()),
                );
                let step = self.step(&mut wave);
                self.waves[index] = wave;
                step?;
                progress = true;
            }
            if self.architecture == AmdArchitecture::Gfx1250 {
                // SIGNAL snapshots one phase without blocking. A WAIT can
                // complete as soon as every surviving wave has signalled it,
                // even if another participant has not reached its WAIT yet.
                let ready: Vec<_> = self
                    .waves
                    .iter()
                    .filter_map(|wave| wave.at_barrier)
                    .filter(|generation| {
                        self.waves.iter().filter(|wave| !wave.exited).all(|wave| {
                            wave.signal_generation
                                .is_some_and(|signal| signal >= *generation)
                        })
                    })
                    .collect();
                for wave in self.waves.iter_mut().filter(|wave| !wave.exited) {
                    if let Some(generation) = wave
                        .at_barrier
                        .filter(|generation| ready.contains(generation))
                    {
                        self.builder.amd_event(
                            wave.id,
                            ProgramPoint(wave.pc as u32),
                            AmdEventKind::SplitBarrierRelease {
                                barrier: -1,
                                generation,
                            },
                        );
                        wave.at_barrier = None;
                        wave.generation += 1;
                        wave.pc += 1;
                        progress = true;
                    }
                }
            }
            if self.architecture != AmdArchitecture::Gfx1250
                && self.waves.iter().any(|wave| wave.at_barrier.is_some())
                && self
                    .waves
                    .iter()
                    .filter(|wave| !wave.exited)
                    .all(|wave| wave.at_barrier.is_some())
            {
                let generation = self
                    .waves
                    .iter()
                    .find_map(|wave| if wave.exited { None } else { wave.at_barrier })
                    .unwrap();
                if self
                    .waves
                    .iter()
                    .filter(|wave| !wave.exited)
                    .any(|wave| wave.at_barrier != Some(generation))
                {
                    return Err(EvalError::Invalid {
                        wave: 0,
                        lane: None,
                        pc: 0,
                        what: "barrier generation mismatch".into(),
                    });
                }
                for wave in self.waves.iter_mut().filter(|wave| !wave.exited) {
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
                    let (file, base, count) = match register.class {
                        RegisterClass::Scalar => {
                            (AmdRegisterFile::Scalar, register.index, register.count)
                        }
                        RegisterClass::Temporary => {
                            (AmdRegisterFile::Temporary, register.index, register.count)
                        }
                        RegisterClass::Vector => {
                            (AmdRegisterFile::Vector, register.index, register.count)
                        }
                        RegisterClass::Accumulator => {
                            (AmdRegisterFile::Accumulator, register.index, register.count)
                        }
                        RegisterClass::Special => match register.special {
                            Some(SpecialRegister::Vcc) => (AmdRegisterFile::Scalar, 106, 2),
                            Some(SpecialRegister::VccLo) => (AmdRegisterFile::Scalar, 106, 1),
                            Some(SpecialRegister::VccHi) => (AmdRegisterFile::Scalar, 107, 1),
                            Some(SpecialRegister::Exec) => (AmdRegisterFile::Scalar, 126, 2),
                            Some(SpecialRegister::ExecLo) => (AmdRegisterFile::Scalar, 126, 1),
                            Some(SpecialRegister::ExecHi) => (AmdRegisterFile::Scalar, 127, 1),
                            _ => return,
                        },
                    };
                    if mask == 0
                        && !matches!(file, AmdRegisterFile::Scalar | AmdRegisterFile::Temporary)
                    {
                        return;
                    }
                    for component in 0..count {
                        result.push(AmdRegister {
                            file,
                            index: base + component,
                            lanes: if matches!(
                                file,
                                AmdRegisterFile::Scalar | AmdRegisterFile::Temporary
                            ) {
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
        if let [Operand::Dual(x, y)] = instruction.operands.as_slice() {
            let (mut reads, mut writes) = self.instruction_registers(x, wave);
            let (r, w) = self.instruction_registers(y, wave);
            reads.extend(r);
            writes.extend(w);
            return (reads, writes);
        }
        let mut reads = Vec::new();
        let mut writes = Vec::new();
        let mnemonic = canonical_alu(
            instruction
                .mnemonic
                .trim_end_matches("_e32")
                .trim_end_matches("_e64"),
        );
        if mnemonic.starts_with("v_cmpx_") {
            writes.extend(
                (126..126 + (wave.width / 32) as u16).map(|index| AmdRegister {
                    file: AmdRegisterFile::Scalar,
                    index,
                    lanes: u64::MAX,
                }),
            );
        }
        if mnemonic == "v_readlane_b32" && self.architecture == AmdArchitecture::Gfx1250 {
            let lane = wave.bits(&instruction.operands[2], 0).unwrap_or(0) & (wave.width - 1);
            add(&instruction.operands[0], u64::MAX, &mut writes);
            add(&instruction.operands[1], 1u64 << lane, &mut reads);
            add(&instruction.operands[2], u64::MAX, &mut reads);
            return (reads, writes);
        }
        if wave.exec == 0
            && matches!(
                instruction.opcode,
                Opcode::VectorAlu | Opcode::VectorMemory | Opcode::Lds
            )
        {
            // Compare and carry masks overwrite their complete scalar result,
            // including clearing bits for inactive lanes. Ordinary vector data
            // sources and destinations have no obligations under empty EXEC.
            let mask_destination =
                if mnemonic.starts_with("v_cmp_") || mnemonic.starts_with("v_cmpx_") {
                    instruction.operands.first()
                } else if matches!(
                    mnemonic,
                    "v_add_co_u32"
                        | "v_addc_co_u32"
                        | "v_sub_co_u32"
                        | "v_subb_co_u32"
                        | "v_subrev_co_u32"
                        | "v_subbrev_co_u32"
                        | "v_mad_u64_u32"
                ) {
                    instruction.operands.get(1)
                } else {
                    None
                };
            if let Some(operand) =
                mask_destination.filter(|_| !(wave.width == 32 && mnemonic.starts_with("v_cmpx_")))
            {
                add(operand, u64::MAX, &mut writes);
            }
            return (reads, writes);
        }
        if matches!(mnemonic, "v_pk_mul_f32" | "v_pk_add_f32" | "v_pk_fma_f32") {
            add(&instruction.operands[0], wave.exec, &mut writes);
            let count = instruction.operands.len() - 1;
            if let (Some(low), Some(high)) = (
                selectors(instruction, "op_sel", count, 0),
                selectors(instruction, "op_sel_hi", count, 1),
            ) {
                fn selected(
                    operand: &Operand,
                    component: u16,
                    mask: u64,
                    result: &mut Vec<AmdRegister>,
                ) {
                    match operand {
                        Operand::Register(register) if register.count == 2 => {
                            let mut register = *register;
                            register.index += component;
                            register.count = 1;
                            add(&Operand::Register(register), mask, result);
                        }
                        Operand::Modified { value, .. } => selected(value, component, mask, result),
                        _ => add(operand, mask, result),
                    }
                }
                for index in 0..count {
                    selected(
                        &instruction.operands[index + 1],
                        low[index],
                        wave.exec,
                        &mut reads,
                    );
                    if high[index] != low[index] {
                        selected(
                            &instruction.operands[index + 1],
                            high[index],
                            wave.exec,
                            &mut reads,
                        );
                    }
                }
                return (reads, writes);
            }
        }
        if mnemonic == "v_readfirstlane_b32" || mnemonic == "v_readlane_b32" {
            let lane = if mnemonic == "v_readfirstlane_b32" {
                wave.exec.trailing_zeros().min(wave.width - 1)
            } else {
                wave.bits(&instruction.operands[2], 0).unwrap_or(0) & (wave.width - 1)
            };
            add(&instruction.operands[0], u64::MAX, &mut writes);
            add(&instruction.operands[1], 1u64 << lane, &mut reads);
            if instruction.operands.len() > 2 {
                add(&instruction.operands[2], u64::MAX, &mut reads);
            }
            return (reads, writes);
        }
        if mnemonic == "v_writelane_b32" {
            let lane = wave.bits(&instruction.operands[2], 0).unwrap_or(0) & (wave.width - 1);
            add(&instruction.operands[0], 1u64 << lane, &mut writes);
            add(&instruction.operands[1], u64::MAX, &mut reads);
            add(&instruction.operands[2], u64::MAX, &mut reads);
            return (reads, writes);
        }
        let store = instruction.mnemonic.contains("store")
            || instruction.mnemonic.starts_with("ds_write")
            || instruction.mnemonic == "global_atomic_add_f32";
        let no_destination = instruction.mnemonic.starts_with("tensor_")
            || (wave.width == 32 && mnemonic.starts_with("v_cmpx_"))
            || matches!(
                instruction.opcode,
                Opcode::Branch | Opcode::Wait | Opcode::Barrier | Opcode::Control
            )
            || instruction.mnemonic.starts_with("s_cmp")
            || instruction.mnemonic.starts_with("s_bitcmp");
        for (index, operand) in instruction.operands.iter().enumerate() {
            if (index == 0
                || (index == 1
                    && (mnemonic.starts_with("v_add_co_")
                        || mnemonic.starts_with("v_addc_co_")
                        || mnemonic.starts_with("v_sub_co_")
                        || mnemonic.starts_with("v_subb_co_")
                        || mnemonic.starts_with("v_subrev_co_")
                        || mnemonic.starts_with("v_subbrev_co_")
                        || mnemonic == "v_mad_u64_u32")))
                && !store
                && !no_destination
            {
                add(operand, wave.exec, &mut writes)
            } else {
                add(operand, wave.exec, &mut reads)
            }
        }
        if matches!(
            mnemonic,
            "v_fmac_f32"
                | "v_fmac_f64"
                | "v_fmac_f16"
                | "v_fma_mixlo_f16"
                | "v_fma_mixhi_f16"
                | "s_mulk_i32"
                | "s_addk_i32"
                | "s_bitset1_b32"
        ) {
            add(&instruction.operands[0], wave.exec, &mut reads);
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && matches!(
                mnemonic,
                "v_add_f16"
                    | "v_sub_f16"
                    | "v_mul_f16"
                    | "v_max_f16"
                    | "v_min_f16"
                    | "v_cvt_f16_f32"
            )
        {
            // True16 arithmetic updates low16 and preserves the destination
            // high16, including any asynchronous producer of that half.
            add(&instruction.operands[0], wave.exec, &mut reads);
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && instruction.opcode == Opcode::VectorMemory
            && wave.exec != 0
        {
            reads.push(AmdRegister {
                file: AmdRegisterFile::Scalar,
                index: 126,
                lanes: u64::MAX,
            });
        }
        (reads, writes)
    }
    fn scalar_mask_reads(&self, instruction: &Instruction, wave: &Wave) -> Vec<AmdRegister> {
        if let [Operand::Dual(x, y)] = instruction.operands.as_slice() {
            let rx = self.scalar_mask_reads(x, wave);
            let ry = self.scalar_mask_reads(y, wave);
            let (xr, _) = self.instruction_registers(x, wave);
            let (yr, _) = self.instruction_registers(y, wave);
            let data: Vec<_> = xr
                .into_iter()
                .filter(|r| !rx.contains(r))
                .chain(yr.into_iter().filter(|r| !ry.contains(r)))
                .collect();
            return rx
                .into_iter()
                .chain(ry)
                .filter(|r| !data.iter().any(|d| r.overlaps(*d)))
                .collect();
        }
        if wave.exec == 0 || instruction.opcode != Opcode::VectorAlu {
            return Vec::new();
        }
        let name = canonical_alu(
            instruction
                .mnemonic
                .trim_end_matches("_e32")
                .trim_end_matches("_e64"),
        );
        let role = if name == "v_cndmask_b32" {
            Some(3)
        } else if matches!(name, "v_addc_co_u32" | "v_subb_co_u32" | "v_subbrev_co_u32") {
            Some(4)
        } else {
            None
        };
        let Some(role) = role else {
            return Vec::new();
        };
        fn scalar(operand: &Operand, out: &mut Vec<AmdRegister>) {
            match operand {
                Operand::Modified { value, .. } => scalar(value, out),
                Operand::Register(register) => {
                    let (index, count) = match register.class {
                        RegisterClass::Scalar => (register.index, register.count),
                        RegisterClass::Special => match register.special {
                            Some(SpecialRegister::Vcc) => (106, 2),
                            Some(SpecialRegister::VccLo) => (106, 1),
                            Some(SpecialRegister::VccHi) => (107, 1),
                            _ => return,
                        },
                        _ => return,
                    };
                    out.extend((index..index + count).map(|index| AmdRegister {
                        file: AmdRegisterFile::Scalar,
                        index,
                        lanes: u64::MAX,
                    }));
                }
                _ => {}
            }
        }
        let mut masks = Vec::new();
        if let Some(operand) = instruction.operands.get(role) {
            scalar(operand, &mut masks);
        }
        let mut data = Vec::new();
        let first_source = if role == 4 { 2 } else { 1 };
        for operand in &instruction.operands[first_source..role.min(instruction.operands.len())] {
            scalar(operand, &mut data);
        }
        masks.retain(|register| !data.iter().any(|other| register.overlaps(*other)));
        masks
    }
    fn step(&mut self, wave: &mut Wave) -> Result<(), EvalError> {
        let instruction = self
            .program
            .instructions
            .get(wave.pc)
            .ok_or_else(|| wave.fail(None, "fell off kernel without s_endpgm"))?;
        let instruction = instruction.clone();
        let (mut reads, writes) = self.instruction_registers(&instruction, wave);
        if instruction.opcode == Opcode::Matrix {
            reads.extend(
                (126..126 + (wave.width / 32) as u16).map(|index| AmdRegister {
                    file: AmdRegisterFile::Scalar,
                    index,
                    lanes: u64::MAX,
                }),
            );
        }
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::Instruction {
                exec_mask: wave.exec,
                reads,
                writes,
                scalar_mask_reads: self.scalar_mask_reads(&instruction, wave),
            },
        );
        self.stats.instructions += 1;
        *self
            .op_counts
            .entry(super::interp_kind(instruction.opcode))
            .or_default() += 1;
        let name = canonical_alu(
            instruction
                .mnemonic
                .trim_end_matches("_e32")
                .trim_end_matches("_e64")
                .trim_end_matches("_sdwa"),
        );
        // Mask flags used as ordinary vector data have additional software
        // dependency/alias requirements. Carry and cndmask selector roles are
        // separately supported; treating all such reads as scalar data would
        // bypass those obligations because the graph has no special-file slice.
        if matches!(
            instruction.opcode,
            Opcode::VectorAlu | Opcode::VectorMemory | Opcode::Matrix
        ) {
            fn special(operand: &Operand) -> Option<SpecialRegister> {
                match operand {
                    Operand::Register(register) => register.special,
                    Operand::Modified { value, .. } => special(value),
                    _ => None,
                }
            }
            let dual_destination = matches!(
                name,
                "v_add_co_u32"
                    | "v_addc_co_u32"
                    | "v_sub_co_u32"
                    | "v_subb_co_u32"
                    | "v_subrev_co_u32"
                    | "v_subbrev_co_u32"
                    | "v_mad_u64_u32"
            );
            for (index, operand) in instruction.operands.iter().enumerate() {
                if instruction.opcode != Opcode::VectorMemory
                    && (index == 0 || (dual_destination && index == 1))
                {
                    continue;
                }
                let Some(register) = special(operand) else {
                    continue;
                };
                if register == SpecialRegister::Null {
                    continue;
                }
                if self.architecture == AmdArchitecture::Gfx1250
                    && name == "v_mbcnt_lo_u32_b32"
                    && index == 1
                    && register == SpecialRegister::ExecLo
                {
                    // Wave32 lane rank uses the architectural concrete EXEC
                    // mask; the default gfx1250 ALU pipeline is interlocked.
                    continue;
                }
                let selector = name == "v_cndmask_b32" && index == 3;
                let carry = matches!(name, "v_addc_co_u32" | "v_subb_co_u32" | "v_subbrev_co_u32")
                    && index == 4;
                if (selector || carry)
                    && (register == SpecialRegister::Vcc
                        || (wave.width == 32 && register == SpecialRegister::VccLo))
                {
                    continue;
                }
                return Err(EvalError::Unsupported{pc:wave.pc,what:"special mask registers used as vector data require additional Table 11 dependency checks".into()});
            }
        }
        match instruction.opcode {
            Opcode::ScalarMemory | Opcode::VectorMemory | Opcode::Lds => {
                self.memory_instruction(wave, &instruction)?
            }
            Opcode::Wait => self.wait(wave, &instruction)?,
            Opcode::Barrier if self.architecture == AmdArchitecture::Gfx1250 => {
                if !matches!(instruction.operands.as_slice(), [Operand::Integer(-1)]) {
                    return Err(self.unsupported(wave, &instruction));
                }
                match name {
                    "s_barrier_signal" => {
                        if wave.signal_generation == Some(wave.generation) {
                            return Err(wave.fail(
                                None,
                                "duplicate workgroup barrier signal before phase wait",
                            ));
                        }
                        self.builder.amd_event(
                            wave.id,
                            ProgramPoint(wave.pc as u32),
                            AmdEventKind::SplitBarrierSignal {
                                barrier: -1,
                                generation: wave.generation,
                                exec_mask: wave.exec,
                            },
                        );
                        wave.signal_generation = Some(wave.generation);
                    }
                    "s_barrier_wait" => {
                        if wave.signal_generation != Some(wave.generation) {
                            return Err(self.unsupported(wave, &instruction));
                        }
                        self.builder.amd_event(
                            wave.id,
                            ProgramPoint(wave.pc as u32),
                            AmdEventKind::SplitBarrierWait {
                                barrier: -1,
                                generation: wave.generation,
                            },
                        );
                        wave.at_barrier = Some(wave.generation);
                        self.stats.block_syncs += 1;
                        return Ok(());
                    }
                    _ => return Err(self.unsupported(wave, &instruction)),
                }
            }
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
                    "s_cbranch_scc0" => !wave.read_scc()?,
                    "s_cbranch_scc1" => wave.read_scc()?,
                    "s_cbranch_vccz" => wave.read_vcc()? == 0,
                    "s_cbranch_vccnz" => wave.read_vcc()? != 0,
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
                "v_nop" => {}
                "s_sendmsg"
                    if self.architecture == AmdArchitecture::Gfx1250
                        && instruction.operands == [Operand::Integer(3)] => {}
                "s_endpgm" => {
                    // CDNA4 S_ENDPGM drains all memory counters before the wave
                    // terminates and ceases participating in workgroup barriers.
                    if self.architecture != AmdArchitecture::Gfx1250 {
                        self.builder.amd_event(
                            wave.id,
                            ProgramPoint(wave.pc as u32),
                            AmdEventKind::Wait {
                                vmcnt: Some(0),
                                lgkmcnt: Some(0),
                                expcnt: Some(0),
                            },
                        );
                    }
                    for lane in 0..wave.width {
                        if wave.valid & (1u64 << lane) != 0 {
                            self.builder.exit(
                                ThreadIx(wave.id * wave.width + lane),
                                ProgramPoint(wave.pc as u32),
                            );
                        }
                    }
                    wave.exited = true;
                }
                "s_clause" => {
                    // An encoding clause marker; per-operation X replay sources remain recorded.
                    if self.architecture != AmdArchitecture::Gfx1250
                        || !matches!(instruction.operands.as_slice(), [Operand::Integer(0..=63)])
                    {
                        return Err(self.unsupported(wave, &instruction));
                    }
                }
                "s_delay_alu" => {
                    let Some(Operand::Integer(encoded)) = instruction.operands.first() else {
                        return Err(self.unsupported(wave, &instruction));
                    };
                    let instid0 = AmdAluDependency::from_encoding((encoded & 15) as u8)
                        .ok_or_else(|| self.unsupported(wave, &instruction))?;
                    let raw1 = ((encoded >> 7) & 15) as u8;
                    let instid1 = if raw1 == 0 {
                        None
                    } else {
                        Some(
                            AmdAluDependency::from_encoding(raw1)
                                .ok_or_else(|| self.unsupported(wave, &instruction))?,
                        )
                    };
                    self.builder.amd_event(
                        wave.id,
                        ProgramPoint(wave.pc as u32),
                        AmdEventKind::DelayAlu {
                            instid0,
                            instskip: ((encoded >> 4) & 7) as u8,
                            instid1,
                        },
                    );
                }
                "s_nop" => {
                    let Some(Operand::Integer(count)) = instruction.operands.first() else {
                        return Err(self.unsupported(wave, &instruction));
                    };
                    if !(0..=15).contains(count) {
                        return Err(wave.fail(None, "s_nop wait count outside 0..15"));
                    }
                    self.builder.amd_event(
                        wave.id,
                        ProgramPoint(wave.pc as u32),
                        AmdEventKind::Delay {
                            cycles: *count as u16 + 1,
                        },
                    );
                }
                _ => return Err(self.unsupported(wave, &instruction)),
            },
            Opcode::ScalarAlu => self.scalar(wave, &instruction, name)?,
            Opcode::VectorAlu => {
                if let [Operand::Dual(x, y)] = instruction.operands.as_slice() {
                    let original = wave.clone();
                    let mut wx = original.clone();
                    let mut wy = original;
                    self.vector(
                        &mut wx,
                        x,
                        canonical_alu(x.mnemonic.trim_end_matches("_e32").trim_end_matches("_e64")),
                    )?;
                    self.vector(
                        &mut wy,
                        y,
                        canonical_alu(y.mnemonic.trim_end_matches("_e32").trim_end_matches("_e64")),
                    )?;
                    for (op, computed) in [(&**x, &wx), (&**y, &wy)] {
                        let register = wave.destination(&op.operands[0])?;
                        for lane in wave.active().collect::<Vec<_>>() {
                            for component in 0..register.count {
                                wave.put(
                                    register,
                                    lane,
                                    component,
                                    computed.reg(register, lane, component)?,
                                )?;
                            }
                        }
                    }
                } else {
                    self.vector(wave, &instruction, name)?;
                }
            }
            Opcode::Matrix => self.matrix(wave, &instruction)?,
        }
        if wave.exec & !wave.valid != 0 {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "EXEC activates lanes outside the launched partial wave".into(),
            });
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
        let value = wave.value(operand, lane)?;
        self.real_value(wave, value, lane)
    }
    fn real_value(&mut self, wave: &Wave, value: Value, lane: u8) -> Result<ExprId, EvalError> {
        if let Value::Input(expr) = value {
            self.claim_word_format(wave, expr, WordFormat::Float32)?;
            return Ok(expr);
        }
        value
            .real(&mut self.arena)
            .map_err(|e| wave.fail(Some(lane), e))
    }
    fn claim_word_format(
        &mut self,
        wave: &Wave,
        expr: ExprId,
        format: WordFormat,
    ) -> Result<(), EvalError> {
        if let ExprNode::InputElement { array, .. } = self.arena.node(expr) {
            if let Some(previous) = self.word_formats.get(array) {
                if *previous != format {
                    return Err(EvalError::Unsupported {
                        pc: wave.pc,
                        what: format!(
                            "input array '{}' has conflicting word interpretations {previous:?} and {format:?}",
                            self.arena.string(*array)
                        ),
                    });
                }
            } else {
                self.word_formats.insert(*array, format);
            }
        }
        Ok(())
    }
    fn claim_half_format(
        &mut self,
        wave: &Wave,
        expr: ExprId,
        format: WordFormat,
    ) -> Result<(), EvalError> {
        // Only the original configured 16-bit input fixes a raw format.
        // A mathematical F32 value rounded/transported through F16 retains
        // its expression identity in this abstraction, not its input encoding.
        if let ExprNode::InputElement { array, .. } = self.arena.node(expr) {
            let name = self.arena.string(*array);
            if self
                .config
                .arrays
                .iter()
                .any(|a| a.name == name && a.elem_width == 2)
            {
                self.claim_word_format(wave, expr, format)?;
            } else if format == WordFormat::Bfloat16 {
                return Err(EvalError::Unsupported{pc:wave.pc,what:"symbolic BF16 requires original16-bit input storage, not a produced F16 encoding".into()});
            }
        }
        Ok(())
    }
    fn integer_expression(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        ty: super::scalar::IntType,
    ) -> Result<ExprId, EvalError> {
        if let Operand::Integer(value) = operand {
            return Ok(self.arena.int(*value));
        }
        match wave.value(operand, lane)? {
            Value::Input(expr) => {
                self.claim_word_format(wave, expr, WordFormat::Integer32)?;
                Ok(expr)
            }
            Value::Byte(expr) => {
                // Native UBYTE loads zero-extend; an integer consumer fixes
                // the encoded input's numeric interpretation as unsigned8.
                self.claim_byte_format(wave, expr, ByteFormat::UnsignedU8)?;
                Ok(expr)
            }
            Value::IntExpr(expr) | Value::NarrowInt { expr, .. } => Ok(expr),
            Value::SignedInteger(value) => Ok(self.arena.int(value as i64)),
            Value::Bits(value) | Value::Integer(value) => Ok(self.arena.int(if ty.signed {
                value as i32 as i64
            } else {
                value as i64
            })),
            Value::SharedApertureHi => Err(wave.fail(
                Some(lane),
                "opaque shared aperture cannot be used as integer data",
            )),
            Value::RelocationWord { .. } => Err(wave.fail(
                Some(lane),
                "opaque PC relocation cannot be used as integer data",
            )),
            Value::PartialBits { bits, defined } if ty.bits == 16 && defined & 65535 == 65535 => {
                Ok(self.arena.int((bits & 65535) as i64))
            }
            Value::PartialBits { .. } => Err(wave.fail(
                Some(lane),
                "integer arithmetic observes undefined bits from ABI padding",
            )),
            _ => Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "typed floating/packed data cannot be reinterpreted as a symbolic integer"
                    .into(),
            }),
        }
    }
    fn integer_result(&self, expr: ExprId, signed: bool) -> Value {
        match self.arena.as_int_const(expr) {
            Some(value) if signed => Value::SignedInteger(value as i32),
            Some(value) => Value::Integer(value as u32),
            None => Value::IntExpr(expr),
        }
    }
    fn write_predicates(
        &mut self,
        wave: &mut Wave,
        destination: Option<&Operand>,
        predicates: [ExprId; 64],
    ) -> Result<(), EvalError> {
        let mask_id = u32::try_from(self.predicate_masks.len())
            .map_err(|_| wave.fail(None, "predicate pool exhausted"))?;
        let mut words = [Value::Bits(0); 2];
        let mut symbolic = false;
        for half in 0..2 {
            let mut bits = 0u32;
            let mut concrete = true;
            for bit in 0..32 {
                match self.arena.as_bool(predicates[half * 32 + bit]) {
                    Some(true) => bits |= 1u32 << bit,
                    Some(false) => {}
                    None => concrete = false,
                }
            }
            words[half] = if concrete {
                Value::Bits(bits)
            } else {
                symbolic = true;
                Value::PredicateWord {
                    mask: mask_id,
                    high: half != 0,
                }
            };
        }
        if symbolic {
            self.predicate_masks.push(predicates);
        }
        let register = match destination {
            Some(operand) => wave.destination(operand)?,
            None => Register {
                class: RegisterClass::Special,
                index: 0,
                count: (wave.width / 32) as u16,
                special: Some(SpecialRegister::Vcc),
            },
        };
        wave.put(register, 0, 0, words[0])?;
        if register.count > 1 {
            wave.put(register, 0, 1, words[1])
        } else {
            Ok(())
        }
    }
    fn predicate_condition(
        &mut self,
        wave: &Wave,
        operand: Option<&Operand>,
        lane: u8,
    ) -> Result<ExprId, EvalError> {
        let register = match operand {
            Some(operand) => wave.destination(operand)?,
            None => Register {
                class: RegisterClass::Special,
                index: 0,
                count: (wave.width / 32) as u16,
                special: Some(SpecialRegister::Vcc),
            },
        };
        let word = wave.reg(register, 0, (lane / 32) as u16)?;
        match word {
            Value::PredicateWord { mask, high } => self
                .predicate_masks
                .get(mask as usize)
                .map(|predicates| predicates[(lane % 32) as usize + if high { 32 } else { 0 }])
                .ok_or_else(|| wave.fail(Some(lane), "invalid predicate mask identity")),
            value => {
                let bits = value.bits().map_err(|e| wave.fail(Some(lane), e))?;
                Ok(self.arena.bool_val(bits & (1u32 << (lane % 32)) != 0))
            }
        }
    }
    /// Float helper APIs accept raw IntConst bit patterns. Values here have
    /// already been decoded, so keep integral mathematical floats as reals.
    fn decoded_float_argument(&mut self, expression: ExprId) -> ExprId {
        if let Some(value) = self.arena.as_int_const(expression) {
            self.arena.real(volta_expr::Real::from_i64(value))
        } else {
            expression
        }
    }
    fn select_word(
        &mut self,
        wave: &Wave,
        condition: ExprId,
        when_true: &Operand,
        when_false: &Operand,
        lane: u8,
        force_float: bool,
    ) -> Result<Value, EvalError> {
        use super::scalar::{FloatType, IntType, ScalarType, select};
        if let Some(condition) = self.arena.as_bool(condition) {
            return self.modified_value(wave, if condition { when_true } else { when_false }, lane);
        }
        let half_payload = |operand: &Operand| {
            matches!(
                wave.value(operand, lane),
                Ok(Value::Half(_) | Value::Halves(..) | Value::PartialHalves(..))
            )
        };
        if !force_float && (half_payload(when_true) || half_payload(when_false)) {
            // CNDMASK copies a whole encoded word. Preserve both independent
            // half identities under the same condition rather than retyping
            // packed floating data as an integer or selecting only low16.
            let mut components = [None, None];
            for (component, high) in [false, true].into_iter().enumerate() {
                let defined = |operand: &Operand| match wave.value(operand, lane) {
                    Ok(Value::PartialHalves(lo, hi)) => if high { hi } else { lo }.is_some(),
                    _ => true,
                };
                if !defined(when_true) || !defined(when_false) {
                    continue;
                }
                let a = self.half(wave, when_true, lane, high)?;
                let b = self.half(wave, when_false, lane, high)?;
                let a = self.decoded_float_argument(a);
                let b = self.decoded_float_argument(b);
                components[component] = Some(
                    super::scalar::select_packed_half(&mut self.arena, condition, a, b)
                        .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?,
                );
            }
            return Ok(match components {
                [Some(lo), Some(hi)] => Value::Halves(lo, hi),
                [lo, hi] => Value::PartialHalves(lo, hi),
            });
        }
        let is_float = |operand: &Operand| {
            if matches!(operand, Operand::Float(_) | Operand::Modified { .. }) {
                return true;
            }
            match wave.value(operand, lane) {
                Ok(Value::Real(_)) => true,
                Ok(Value::Input(expr)) => match self.arena.node(expr) {
                    ExprNode::InputElement { array, .. } => {
                        self.word_formats.get(array) == Some(&WordFormat::Float32)
                    }
                    _ => false,
                },
                _ => false,
            }
        };
        if force_float || is_float(when_true) || is_float(when_false) {
            let a = self.real(wave, when_true, lane)?;
            let b = self.real(wave, when_false, lane)?;
            let a = self.decoded_float_argument(a);
            let b = self.decoded_float_argument(b);
            let result = select(
                &mut self.arena,
                ScalarType::Float(FloatType::F32),
                condition,
                a,
                b,
            )
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
            Ok(Value::Real(result))
        } else {
            let ty = IntType {
                bits: 32,
                signed: false,
            };
            let a = self.integer_expression(wave, when_true, lane, ty)?;
            let b = self.integer_expression(wave, when_false, lane, ty)?;
            let result = select(&mut self.arena, ScalarType::Int(ty), condition, a, b)
                .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
            Ok(self.integer_result(result, false))
        }
    }
    fn real64(&mut self, wave: &Wave, operand: &Operand, lane: u8) -> Result<ExprId, EvalError> {
        use super::scalar::{FloatType, decode_float};
        if let Operand::Modified {
            value,
            negate,
            absolute,
        } = operand
        {
            let mut expr = self.real64(wave, value, lane)?;
            if *absolute {
                expr = self.arena.abs(expr);
            }
            if *negate {
                expr = self.arena.neg(expr);
            }
            return Ok(expr);
        }
        if let Operand::Float(value) = operand {
            let magnitude = value.abs();
            if ![0.0, 0.5, 1.0, 2.0, 4.0].contains(&magnitude) {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "non-inline f64 constants require their actual encoded high-word literal"
                        .into(),
                });
            }
            return self
                .arena
                .float_from_f64(*value)
                .map_err(|e| wave.fail(Some(lane), e.to_string()));
        }
        if let Operand::Integer(value) = operand {
            if *value != 0 && (-16..=64).contains(value) {
                return Err(EvalError::Unsupported{pc:wave.pc,what:"nonzero integer inline constants used as f64 need explicit encoding semantics".into()});
            }
            if *value < i32::MIN as i64 || *value > u32::MAX as i64 {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "f64 literal is one encoded32-bit high word".into(),
                });
            }
            return decode_float(
                &mut self.arena,
                FloatType::F64,
                (*value as u32 as u64) << 32,
            )
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what });
        }
        if let Operand::Register(register) = operand {
            if register.count != 2 {
                return Err(wave.fail(
                    Some(lane),
                    "f64 source must contain two ordered register words",
                ));
            }
            let lo = wave.reg(*register, lane, 0)?;
            let hi = wave.reg(*register, lane, 1)?;
            match (lo, hi) {
                (Value::WidePart { expr: a, high: false, kind: ak },
                 Value::WidePart { expr: b, high: true, kind: bk })
                 if a == b && ak == bk && matches!(ak, WideKind::Input | WideKind::Float) => {
                    if ak==WideKind::Input {self.claim_word_format(wave,a,WordFormat::Float64)?;}
                    return Ok(a);
                 },
                (lo, hi) if lo.bits().is_ok() && hi.bits().is_ok() => {},
                _ => return Err(EvalError::Unsupported { pc: wave.pc, what: "f64 requires matching ordered words of one floating/input value; packed or integer words cannot be reinterpreted".into() }),
            }
        }
        let bits = wave.wide(operand, lane)?;
        decode_float(&mut self.arena, FloatType::F64, bits)
            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })
    }
    fn put_real64(
        &self,
        wave: &mut Wave,
        operand: &Operand,
        lane: u8,
        expr: ExprId,
    ) -> Result<(), EvalError> {
        let register = wave.destination(operand)?;
        if register.count != 2 {
            return Err(wave.fail(Some(lane), "f64 destination must contain two ordered words"));
        }
        wave.put(
            register,
            lane,
            0,
            Value::WidePart {
                expr,
                high: false,
                kind: WideKind::Float,
            },
        )?;
        wave.put(
            register,
            lane,
            1,
            Value::WidePart {
                expr,
                high: true,
                kind: WideKind::Float,
            },
        )
    }
    fn real_component(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        component: u16,
    ) -> Result<ExprId, EvalError> {
        match operand {
            Operand::Register(register) if register.count == 2 => {
                let value = wave.reg(*register, lane, component)?;
                self.real_value(wave, value, lane)
            }
            Operand::Modified {
                value,
                negate,
                absolute,
            } => {
                let mut expr = self.real_component(wave, value, lane, component)?;
                if *absolute {
                    expr = self.arena.abs(expr);
                }
                if *negate {
                    expr = self.arena.neg(expr);
                }
                Ok(expr)
            }
            _ => self.real(wave, operand, lane),
        }
    }
    fn selected_bits(
        &self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        instruction: &Instruction,
        index: u8,
    ) -> Result<u32, EvalError> {
        let bits = wave.bits(operand, lane)?;
        let field = if index == 0 { "src0_sel" } else { "src1_sel" };
        Ok(
            match instruction
                .modifiers
                .iter()
                .find(|modifier| modifier.name == field)
                .and_then(|modifier| modifier.value.as_deref())
                .unwrap_or("DWORD")
            {
                "DWORD" => bits,
                "WORD_0" => bits & 65535,
                "WORD_1" => bits >> 16,
                "BYTE_0" => bits & 255,
                "BYTE_1" => (bits >> 8) & 255,
                "BYTE_2" => (bits >> 16) & 255,
                "BYTE_3" => bits >> 24,
                _ => return Err(self.unsupported(wave, instruction)),
            },
        )
    }
    fn modified_value(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
    ) -> Result<Value, EvalError> {
        if matches!(operand, Operand::Modified { .. }) {
            Ok(Value::Real(self.real(wave, operand, lane)?))
        } else {
            wave.value(operand, lane)
        }
    }
    fn fp8(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        byte: usize,
    ) -> Result<ExprId, EvalError> {
        if byte > 3 {
            return Err(self.unsupported(wave, &self.program.instructions[wave.pc]));
        }
        let bits = match wave.value(operand, lane)? {
            Value::Bytes(bytes) => {
                self.claim_byte_format(wave, bytes[byte], ByteFormat::OcpE4m3)?;
                return Ok(bytes[byte]);
            }
            Value::BytePair(lo, hi) => {
                if byte < 2 {
                    let value = if byte == 0 { lo } else { hi };
                    self.claim_byte_format(wave, value, ByteFormat::OcpE4m3)?;
                    return Ok(value);
                }
                return Ok(self.arena.int(0));
            }
            Value::Byte(expr) => {
                if byte == 0 {
                    self.claim_byte_format(wave, expr, ByteFormat::OcpE4m3)?;
                    return Ok(expr);
                } else {
                    return Ok(self.arena.int(0));
                }
            }
            value @ (Value::Bits(_) | Value::Integer(_) | Value::SignedInteger(_)) => {
                (value.bits().unwrap() >> (8 * byte)) & 255
            }
            _ => {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what: "non-FP8 storage used by OCP E4M3 decoder".into(),
                });
            }
        };
        let sign = if bits & 128 == 0 { 1.0 } else { -1.0 };
        let exponent = (bits >> 3) & 15;
        let fraction = bits & 7;
        if exponent == 15 && fraction == 7 {
            return Err(wave.fail(Some(lane), "OCP E4M3 NaN is outside the real-number model"));
        }
        let value = if exponent == 0 {
            sign * fraction as f64 * 2f64.powi(-9)
        } else {
            sign * (1.0 + fraction as f64 / 8.0) * 2f64.powi(exponent as i32 - 7)
        };
        self.arena
            .float_from_f64(value)
            .map_err(|e| wave.fail(Some(lane), e.to_string()))
    }
    fn claim_byte_format(
        &mut self,
        wave: &Wave,
        expr: ExprId,
        format: ByteFormat,
    ) -> Result<(), EvalError> {
        if let ExprNode::InputElement { array, .. } = self.arena.node(expr) {
            if let Some(previous) = self.byte_formats.get(array) {
                if *previous != format {
                    return Err(EvalError::Unsupported {
                        pc: wave.pc,
                        what: format!(
                            "input array '{}' has conflicting byte interpretations {previous:?} and {format:?}",
                            self.arena.string(*array)
                        ),
                    });
                }
            } else {
                self.byte_formats.insert(*array, format);
            }
        }
        Ok(())
    }
    fn signed16_to_half(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        instruction: &Instruction,
    ) -> Result<ExprId, EvalError> {
        let selector = instruction
            .modifiers
            .iter()
            .find(|modifier| modifier.name == "src0_sel")
            .and_then(|modifier| modifier.value.as_deref())
            .unwrap_or("DWORD");
        let sext = instruction
            .modifiers
            .iter()
            .any(|modifier| modifier.name == "src0_sext");
        let byte = selector
            .strip_prefix("BYTE_")
            .and_then(|value| value.parse::<usize>().ok());
        let value = wave.value(operand, lane)?;
        let symbolic = match value {
            Value::Byte(expr) if byte == Some(0) || selector == "DWORD" => Some(expr),
            Value::Byte(_) if byte.is_some() => return Ok(self.arena.int(0)),
            Value::Bytes(bytes) if byte.is_some() => Some(bytes[byte.unwrap()]),
            Value::Low16Integer(expr) if selector == "DWORD" => return Ok(expr),
            Value::NarrowInt { expr, bits, signed }
                if selector == "DWORD" && bits <= 16 && signed =>
            {
                return Ok(expr);
            }
            Value::NarrowInt {
                expr,
                bits: 8,
                signed: true,
            } if byte == Some(0) && sext => return Ok(expr),
            _ => None,
        };
        if let Some(expr) = symbolic {
            self.claim_byte_format(
                wave,
                expr,
                if sext {
                    ByteFormat::SignedI8
                } else {
                    ByteFormat::UnsignedU8
                },
            )?;
            return Ok(expr);
        }
        let bits = value.bits().map_err(|_| EvalError::Unsupported {
            pc: wave.pc,
            what: "signed16 conversion requires concrete bits or a typed signed-byte data path"
                .into(),
        })?;
        let selected = match selector {
            "DWORD" => bits,
            "WORD_0" => bits & 65535,
            "WORD_1" => bits >> 16,
            _ => byte
                .map(|index| (bits >> (8 * index)) & 255)
                .ok_or_else(|| self.unsupported(wave, instruction))?,
        };
        let number = if byte.is_some() && sext {
            selected as i8 as i64
        } else {
            selected as i16 as i64
        };
        Ok(self.arena.int(number))
    }
    fn half(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        high: bool,
    ) -> Result<ExprId, EvalError> {
        if let Operand::Float(value) = operand {
            return self
                .arena
                .float_from_f64(*value)
                .map_err(|e| wave.fail(Some(lane), e.to_string()));
        }
        if let Operand::Modified {
            value,
            negate,
            absolute,
        } = operand
        {
            let mut expr = self.half(wave, value, lane, high)?;
            if *absolute {
                expr = self.arena.abs(expr);
            }
            if *negate {
                expr = self.arena.neg(expr);
            }
            return Ok(expr);
        }
        match wave.value(operand, lane)? {
            Value::Halves(lo, hi) => {
                let expr = if high { hi } else { lo };
                self.claim_half_format(wave, expr, WordFormat::Float16)?;
                Ok(expr)
            }
            Value::PartialHalves(lo, hi) => {
                if high { hi } else { lo }.ok_or_else(|| EvalError::Unsupported {
                    pc: wave.pc,
                    what: "unknown half after partial register write".into(),
                })
            }
            Value::Half(expr) => {
                if high {
                    Ok(self.arena.int(0))
                } else {
                    self.claim_half_format(wave, expr, WordFormat::Float16)?;
                    Ok(expr)
                }
            }
            value @ (Value::Bits(_) | Value::Integer(_) | Value::SignedInteger(_)) => {
                let bits = value.bits().unwrap();
                let bits = if high { bits >> 16 } else { bits & 0xffff };
                let sign = if bits & 0x8000 == 0 { 1.0 } else { -1.0 };
                let exponent = (bits >> 10) & 31;
                let fraction = bits & 1023;
                let value = if exponent == 31 {
                    if fraction != 0 {
                        return Err(wave.fail(Some(lane), "half NaN outside real arithmetic model"));
                    }
                    sign * f64::INFINITY
                } else if exponent == 0 {
                    sign * (fraction as f64) * 2f64.powi(-24)
                } else {
                    sign * (1.0 + fraction as f64 / 1024.0) * 2f64.powi(exponent as i32 - 15)
                };
                self.arena
                    .float_from_f64(value)
                    .map_err(|e| wave.fail(Some(lane), e.to_string()))
            }
            Value::IntExpr(expr) => super::scalar::decode_half_select(&mut self.arena, expr, high)
                .map_err(|what| EvalError::Unsupported { pc: wave.pc, what }),
            Value::Input(_)
            | Value::PredicateWord { .. }
            | Value::RelocationWord { .. }
            | Value::SharedApertureHi
            | Value::PartialBits { .. }
            | Value::NarrowInt { .. }
            | Value::Low16Integer(_)
            | Value::WidePart { .. }
            | Value::Real(_)
            | Value::Byte(_)
            | Value::Bytes(_)
            | Value::BytePair(..) => Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "symbolic non-f16 bits reinterpreted as half".into(),
            }),
        }
    }
    fn exp2(&mut self, argument: ExprId) -> ExprId {
        if let Some(unscaled) = self.factor_exp2_idiom(argument) {
            self.builder.assume(Assumption::CompilerExp2Idiom);
            return self.arena.exp(unscaled);
        }
        let ln2 = self.ln2_constant();
        let scaled = self.arena.mul(argument, ln2);
        self.arena.exp(scaled)
    }
    fn ln2_constant(&mut self) -> ExprId {
        self.builder.assume(Assumption::CompilerBase2Conversion);
        let log2e = volta_expr::Real::from_f64(std::f64::consts::LOG2_E as f32 as f64)
            .expect("the pinned finite LOG2_E_F32 constant is representable");
        self.arena
            .real(log2e.try_recip().expect("LOG2_E_F32 is nonzero"))
    }
    /// Only the exact rounded binary32 constant generated by the pinned compiler
    /// is abstracted as log2(e). Near constants and unfactored additive offsets
    /// deliberately retain their actual exp2 expression.
    fn factor_exp2_idiom(&mut self, argument: ExprId) -> Option<ExprId> {
        let constant = std::f64::consts::LOG2_E as f32 as f64;
        let factor = |arena: &ExprArena, id| match arena.node(id) {
            ExprNode::RealConst(value) if value.to_f64().abs() == constant => {
                Some(value.to_f64().is_sign_negative())
            }
            _ => None,
        };
        match self.arena.node(argument).clone() {
            ExprNode::IntConst(0) => Some(argument),
            ExprNode::RealConst(value) if value.to_f64() == 0.0 => Some(argument),
            ExprNode::Mul(a, b) => {
                for (value, other) in [(a, b), (b, a)] {
                    if let Some(negative) = factor(&self.arena, value) {
                        return Some(if negative {
                            self.arena.neg(other)
                        } else {
                            other
                        });
                    }
                }
                None
            }
            ExprNode::Add(a, b) => {
                let a = self.factor_exp2_idiom(a)?;
                let b = self.factor_exp2_idiom(b)?;
                Some(self.arena.add(a, b))
            }
            ExprNode::Sub(a, b) => {
                let a = self.factor_exp2_idiom(a)?;
                let b = self.factor_exp2_idiom(b)?;
                Some(self.arena.sub(a, b))
            }
            ExprNode::Neg(a) => {
                let a = self.factor_exp2_idiom(a)?;
                Some(self.arena.neg(a))
            }
            ExprNode::Fma(a, b, c) => {
                let (other, negative) = if let Some(negative) = factor(&self.arena, a) {
                    (b, negative)
                } else {
                    (a, factor(&self.arena, b)?)
                };
                let product = if negative {
                    self.arena.neg(other)
                } else {
                    other
                };
                let rest = self.factor_exp2_idiom(c)?;
                Some(self.arena.add(product, rest))
            }
            _ => None,
        }
    }
    fn scalar(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        name: &str,
    ) -> Result<(), EvalError> {
        if matches!(name, "s_add_nc_u64" | "s_mul_u64") {
            let a = wave.wide(&instruction.operands[1], 0)?;
            let b = wave.wide(&instruction.operands[2], 0)?;
            let value = if name == "s_mul_u64" {
                a.wrapping_mul(b)
            } else {
                a.wrapping_add(b)
            };
            let reg = wave.destination(&instruction.operands[0])?;
            wave.put(reg, 0, 0, Value::Integer(value as u32))?;
            return wave.put(reg, 0, 1, Value::Integer((value >> 32) as u32));
        }
        if matches!(
            name,
            "s_add_f32" | "s_sub_f32" | "s_mul_f32" | "s_min_num_f32"
        ) {
            if !instruction.modifiers.is_empty() {
                return Err(self.unsupported(wave, instruction));
            }
            let a = self.real(wave, &instruction.operands[1], 0)?;
            let b = self.real(wave, &instruction.operands[2], 0)?;
            let value = match name {
                "s_add_f32" => self.arena.add(a, b),
                "s_sub_f32" => self.arena.sub(a, b),
                "s_mul_f32" => self.arena.mul(a, b),
                _ => self.arena.min(a, b),
            };
            return wave.put_value(&instruction.operands[0], 0, Value::Real(value));
        }
        if name == "s_getreg_b32" {
            if self.architecture != AmdArchitecture::Gfx1250
                || !matches!(&instruction.operands[1],Operand::HardwareRegister{name,offset:6,width:4} if name=="HW_REG_IB_STS2")
            {
                return Err(self.unsupported(wave, instruction));
            }
            return wave.put_value(&instruction.operands[0], 0, Value::Integer(0));
        }
        if self.module_address_scalar(wave, instruction)? {
            return Ok(());
        }
        if !name.starts_with("s_cmp_")
            && !name.starts_with("s_cmpk_")
            && !name.starts_with("s_bitcmp")
            && !matches!(
                name,
                "s_mov_b32"
                    | "s_mov_b64"
                    | "s_movk_i32"
                    | "s_mulk_i32"
                    | "s_addk_i32"
                    | "s_bitset1_b32"
                    | "s_sext_i32_i16"
                    | "s_ff1_i32_b64"
                    | "s_ff1_i32_b32"
                    | "s_brev_b32"
                    | "s_cselect_b32"
                    | "s_cselect_b64"
                    | "s_and_b64"
                    | "s_or_b64"
                    | "s_xor_b64"
                    | "s_andn2_b64"
                    | "s_orn2_b64"
                    | "s_not_b64"
                    | "s_and_saveexec_b64"
                    | "s_or_saveexec_b64"
                    | "s_xor_saveexec_b64"
                    | "s_andn2_saveexec_b64"
                    | "s_lshl_b64"
                    | "s_lshr_b64"
                    | "s_add_u32"
                    | "s_add_i32"
                    | "s_sub_i32"
                    | "s_addc_u32"
                    | "s_sub_u32"
                    | "s_subb_u32"
                    | "s_mul_i32"
                    | "s_mul_hi_u32"
                    | "s_and_b32"
                    | "s_or_b32"
                    | "s_xor_b32"
                    | "s_andn2_b32"
                    | "s_not_b32"
                    | "s_lshl_b32"
                    | "s_lshr_b32"
                    | "s_ashr_i32"
                    | "s_min_u32"
                    | "s_max_u32"
                    | "s_min_i32"
                    | "s_max_i32"
                    | "s_add_nc_u32"
                    | "s_sub_nc_u32"
                    | "s_and_saveexec_b32"
                    | "s_andn2_saveexec_b32"
                    | "s_or_saveexec_b32"
                    | "s_mul_u64"
                    | "s_add_nc_u64"
                    | "s_bfe_u32"
            )
        {
            return Err(self.unsupported(wave, instruction));
        }
        let o = &instruction.operands;
        if !instruction.modifiers.is_empty() {
            return Err(self.unsupported(wave, instruction));
        }
        if name.starts_with("s_bitcmp") {
            let bits = if name.ends_with("b64") {
                wave.wide(&o[0], 0)?
            } else {
                wave.bits(&o[0], 0)? as u64
            };
            let bit = wave.bits(&o[1], 0)? & if name.ends_with("b64") { 63 } else { 31 };
            let set = bits & (1u64 << bit) != 0;
            wave.set_scc(if name.starts_with("s_bitcmp1") {
                set
            } else {
                !set
            });
            return Ok(());
        }
        if name.starts_with("s_cmpk_") {
            let signed = name.ends_with("i32");
            if !signed && !name.ends_with("u32") {
                return Err(self.unsupported(wave, instruction));
            }
            let a = wave.bits(&o[0], 0)?;
            let b = wave.bits(&o[1], 0)?;
            let comparison = name
                .trim_start_matches("s_cmpk_")
                .trim_end_matches("_i32")
                .trim_end_matches("_u32");
            let result = compare(
                comparison,
                if signed { a as i32 as i64 } else { a as i64 },
                if signed {
                    b as i16 as i64
                } else {
                    b as u16 as i64
                },
            )
            .ok_or_else(|| self.unsupported(wave, instruction))?;
            wave.set_scc(result);
            return Ok(());
        }
        if name.starts_with("s_cmp_") {
            let a = wave.bits(&o[0], 0)?;
            let b = wave.bits(&o[1], 0)?;
            let signed = name.ends_with("i32");
            let cmp = name
                .trim_start_matches("s_cmp_")
                .trim_end_matches("_u32")
                .trim_end_matches("_i32");
            let result = compare(
                cmp,
                if signed { a as i32 as i64 } else { a as i64 },
                if signed { b as i32 as i64 } else { b as i64 },
            )
            .ok_or_else(|| self.unsupported(wave, instruction))?;
            wave.set_scc(result);
            return Ok(());
        }
        let dest = &o[0];
        if name == "s_sext_i32_i16" {
            // CDNA4 SOP1 observes only low16 and preserves SCC.
            let value = wave
                .value(&o[1], 0)?
                .selected_bits(0, 16)
                .map_err(|error| wave.fail(None, error))? as i16 as i32;
            return wave.put_value(dest, 0, Value::SignedInteger(value));
        }
        if name == "s_bitset1_b32" {
            let value = wave.bits(dest, 0)? | (1u32 << (wave.bits(&o[1], 0)? & 31));
            return wave.put_value(dest, 0, Value::Integer(value));
        }
        if name == "s_addk_i32" {
            let a = wave.bits(dest, 0)? as i32;
            let b = wave.bits(&o[1], 0)? as i16 as i32;
            let (value, overflow) = a.overflowing_add(b);
            wave.set_scc(overflow);
            return wave.put_value(dest, 0, Value::SignedInteger(value));
        }
        if name == "s_brev_b32" {
            let value = wave.bits(&o[1], 0)?.reverse_bits();
            return wave.put_value(dest, 0, Value::Integer(value));
        }
        if name == "s_ff1_i32_b32" {
            let bits = wave.bits(&o[1], 0)?;
            let first = if bits == 0 {
                -1
            } else {
                bits.trailing_zeros() as i32
            };
            return wave.put_value(dest, 0, Value::SignedInteger(first));
        }
        if name == "s_ff1_i32_b64" {
            let source = wave.wide(&o[1], 0)?;
            let first = if source == 0 {
                -1
            } else {
                source.trailing_zeros() as i32
            };
            return wave.put_value(dest, 0, Value::SignedInteger(first));
        }
        if name == "s_movk_i32" {
            let value = wave.bits(&o[1], 0)? as i16 as i32 as u32;
            return wave.put_value(dest, 0, Value::Integer(value));
        }
        if name == "s_mulk_i32" {
            let old = wave.bits(dest, 0)?;
            let multiplier = wave.bits(&o[1], 0)? as i16 as i32 as u32;
            return wave.put_value(dest, 0, Value::Integer(old.wrapping_mul(multiplier)));
        }
        if name == "s_mov_b64" {
            return wave.move_wide(dest, &o[1]);
        }
        if name == "s_mov_b32" {
            let value = wave.value(&o[1], 0)?;
            return wave.put_value(dest, 0, value);
        }
        if name == "s_cselect_b32" || name == "s_cselect_b64" {
            let source = if wave.read_scc()? { &o[1] } else { &o[2] };
            return if name.ends_with("64") {
                wave.move_wide(dest, source)
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
            wave.set_scc(if name.contains("saveexec") {
                wave.exec != 0
            } else {
                value != 0
            });
            if self.architecture == AmdArchitecture::Gfx1250 && !name.contains("saveexec") {
                let dest = wave.destination(dest)?;
                wave.put(dest, 0, 0, Value::Integer(value as u32))?;
                return wave.put(dest, 0, 1, Value::Integer((value >> 32) as u32));
            }
            return wave.put_wide(dest, 0, value);
        }
        if matches!(
            name,
            "s_and_saveexec_b32" | "s_andn2_saveexec_b32" | "s_or_saveexec_b32"
        ) {
            let source = wave.bits(&o[1], 0)? as u64;
            let old = wave.exec;
            wave.exec = match name {
                "s_and_saveexec_b32" => old & source,
                "s_andn2_saveexec_b32" => old & !source,
                _ => old | source,
            };
            wave.set_scc(wave.exec != 0);
            return wave.put_value(dest, 0, Value::Bits(old as u32));
        }
        if name == "s_and_b32" && self.architecture != AmdArchitecture::Gfx1250 {
            if let Value::PartialBits { bits, defined } = wave.value(&o[1], 0)? {
                let mask = wave.bits(&o[2], 0)?;
                if mask & !defined != 0 {
                    return Err(wave.fail(None, "and observes undefined architected system bits"));
                }
                let result = bits & mask;
                wave.set_scc(result != 0);
                return wave.put_value(dest, 0, Value::Integer(result));
            }
        }
        if name == "s_bfe_u32" {
            let control = wave.bits(&o[2], 0)?;
            let offset = control & 31;
            let width = (control >> 16) & 127;
            if let Value::PartialBits { .. } = wave.value(&o[1], 0)? {
                let value = wave
                    .value(&o[1], 0)?
                    .selected_bits(offset, width)
                    .map_err(|e| wave.fail(None, e))?;
                wave.set_scc(value != 0);
                return wave.put_value(dest, 0, Value::Integer(value));
            }
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && matches!(
                name,
                "s_and_b32" | "s_andn2_b32" | "s_or_b32" | "s_xor_b32" | "s_not_b32"
            )
        {
            fn partial(wave: &Wave, operand: &Operand) -> Result<(u32, u32), EvalError> {
                if let Operand::Register(r) = operand {
                    if r.class == RegisterClass::Scalar
                        && wave
                            .scalar
                            .get(r.index as usize)
                            .copied()
                            .flatten()
                            .is_none()
                    {
                        return Ok((0, 0));
                    }
                }
                match wave.value(operand, 0)? {
                    Value::PartialBits { bits, defined } => Ok((bits, defined)),
                    v => Ok((v.bits().map_err(|e| wave.fail(None, e))?, u32::MAX)),
                }
            }
            let (a, da) = partial(wave, &o[1])?;
            let (mut b, db) = if o.len() > 2 {
                partial(wave, &o[2])?
            } else {
                (0, u32::MAX)
            };
            if name == "s_andn2_b32" {
                b = !b;
            }
            let (bits, defined) = match name {
                "s_and_b32" | "s_andn2_b32" => (a & b, (da & db) | (da & !a) | (db & !b)),
                "s_or_b32" => (a | b, (da & db) | (da & a) | (db & b)),
                "s_xor_b32" => (a ^ b, da & db),
                _ => (!a, da),
            };
            if bits & defined != 0 {
                wave.set_scc(true);
            } else if defined == u32::MAX {
                wave.set_scc(false);
            } else {
                wave.scc_defined = false;
            }
            return wave.put_value(
                dest,
                0,
                if defined == u32::MAX {
                    Value::Integer(bits)
                } else {
                    Value::PartialBits {
                        bits: bits & defined,
                        defined,
                    }
                },
            );
        }
        let a = wave.bits(&o[1], 0)?;
        let b = if o.len() > 2 { wave.bits(&o[2], 0)? } else { 0 };
        let (value, scc) = match name {
            "s_add_i32" => {
                let (value, overflow) = (a as i32).overflowing_add(b as i32);
                (value as u32, overflow)
            }
            "s_sub_i32" => {
                let (value, overflow) = (a as i32).overflowing_sub(b as i32);
                (value as u32, overflow)
            }
            "s_add_u32" => {
                let (v, c) = a.overflowing_add(b);
                (v, c)
            }
            "s_addc_u32" => {
                let (v, c) = a.overflowing_add(b);
                let (v, d) = v.overflowing_add(wave.read_scc()? as u32);
                (v, c || d)
            }
            "s_sub_u32" => {
                let (v, c) = a.overflowing_sub(b);
                (v, c)
            }
            "s_subb_u32" => {
                let (v, c) = a.overflowing_sub(b);
                let (v, d) = v.overflowing_sub(wave.read_scc()? as u32);
                (v, c || d)
            }
            "s_add_nc_u32" => (a.wrapping_add(b), wave.scc),
            "s_sub_nc_u32" => (a.wrapping_sub(b), wave.scc),
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
            "s_max_u32" => (a.max(b), a >= b),
            "s_min_i32" => ((a as i32).min(b as i32) as u32, (a as i32) < (b as i32)),
            "s_max_i32" => ((a as i32).max(b as i32) as u32, (a as i32) >= (b as i32)),
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
        if !matches!(
            name,
            "s_mul_i32" | "s_mul_hi_u32" | "s_add_nc_u32" | "s_sub_nc_u32"
        ) {
            wave.set_scc(scc);
        }
        wave.put_value(
            dest,
            0,
            if name.contains("i32") {
                Value::SignedInteger(value as i32)
            } else {
                Value::Integer(value)
            },
        )
    }
    fn module_address_scalar(
        &self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<bool, EvalError> {
        let sequence = (0..=2).find_map(|stage| {
            wave.pc.checked_sub(stage).and_then(|anchor| {
                self.program
                    .global_address_sequences
                    .get(&anchor)
                    .map(|sequence| (stage, sequence))
            })
        });
        let Some((stage, sequence)) = sequence else {
            return Ok(false);
        };
        if sequence.anchor_pc + stage != wave.pc
            || instruction.mnemonic != ["s_getpc_b64", "s_add_u32", "s_addc_u32"][stage]
        {
            return Err(wave.fail(None, "invalid approved module-address sequence stage"));
        }
        let anchor = u32::try_from(sequence.anchor_pc)
            .map_err(|_| wave.fail(None, "module-address anchor exceeds program-point range"))?;
        let pair = sequence.register_pair;
        let address = self
            .module_globals
            .get(&sequence.symbol)
            .ok_or_else(|| wave.fail(None, "approved relocation has no allocated module object"))?
            .base;
        match stage {
            0 => {
                wave.put(
                    pair,
                    0,
                    0,
                    Value::RelocationWord {
                        anchor,
                        high: false,
                    },
                )?;
                wave.put(pair, 0, 1, Value::RelocationWord { anchor, high: true })?;
            }
            1 => {
                if wave.reg(pair, 0, 0)?
                    != (Value::RelocationWord {
                        anchor,
                        high: false,
                    })
                    || wave.reg(pair, 0, 1)? != (Value::RelocationWord { anchor, high: true })
                {
                    return Err(wave.fail(None, "PC-relative low stage lost its opaque anchor"));
                }
                wave.put(pair, 0, 0, Value::Bits(address as u32))?;
                wave.scc_defined = false;
            }
            2 => {
                if wave.reg(pair, 0, 0)?.bits().ok() != Some(address as u32)
                    || wave.reg(pair, 0, 1)? != (Value::RelocationWord { anchor, high: true })
                {
                    return Err(wave.fail(None, "PC-relative high stage lost its approved anchor"));
                }
                wave.put(pair, 0, 1, Value::Bits((address >> 32) as u32))?;
                // The chosen abstract storage address determines the pointer,
                // not the actual code address or linker carry/overflow bits.
                wave.scc_defined = false;
            }
            _ => unreachable!(),
        }
        Ok(true)
    }
    fn matrix_input(
        &mut self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        item: usize,
        kind: super::matrix::InputKind,
    ) -> Result<ExprId, EvalError> {
        use super::matrix::InputKind;
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
            InputKind::F16 => self.half(wave, &selected, lane, item % 2 != 0),
            InputKind::Fp8E4m3 => self.fp8(wave, &selected, lane, item % 4),
            InputKind::Bf16 => {
                let high = item % 2 != 0;
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
                let value = super::matrix::decode_bits(kind, bits)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                self.arena
                    .float_from_f64(value)
                    .map_err(|e| wave.fail(Some(lane), e.to_string()))
            }
            InputKind::Fp8E5m2 => {
                let bits =
                    wave.bits(&selected, lane)? >> (8 * (item % per_register) * (4 / per_register));
                let value = super::matrix::decode_bits(kind, bits)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                self.arena
                    .float_from_f64(value)
                    .map_err(|e| wave.fail(Some(lane), e.to_string()))
            }
        }
    }
    fn wmma(&mut self, wave: &mut Wave, instruction: &Instruction) -> Result<(), EvalError> {
        use super::matrix::InputKind;
        if self.architecture != AmdArchitecture::Gfx1250
            || wave.valid != 0xffff_ffff
            || wave.exec != 0xffff_ffff
            || !instruction.modifiers.is_empty()
        {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "WMMA requires one complete active wave32 and supported unmodified operands"
                    .into(),
            });
        }
        let (kind, input_kind, k) = match instruction.mnemonic.as_str() {
            "v_wmma_f32_16x16x4_f32" => (AmdWmmaKind::F32_16x16x4, InputKind::F32, 4),
            "v_wmma_f32_16x16x32_f16" => (AmdWmmaKind::F16_16x16x32, InputKind::F16, 32),
            "v_wmma_f32_16x16x32_bf16" => (AmdWmmaKind::Bf16_16x16x32, InputKind::Bf16, 32),
            _ => return Err(self.unsupported(wave, instruction)),
        };
        let o = &instruction.operands;
        let (_, destinations) = self.instruction_registers(instruction, wave);
        let mut role = instruction.clone();
        role.operands = vec![o[0].clone(), o[1].clone(), o[2].clone()];
        let (sources_ab, _) = self.instruction_registers(&role, wave);
        role.operands = vec![o[0].clone(), o[3].clone()];
        let (accumulator, _) = self.instruction_registers(&role, wave);
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
        for lane in 0..32u8 {
            for component in 0..8 {
                let row = (lane as usize / 16) * 8 + component;
                let col = lane as usize % 16;
                let mut value = c[lane as usize][component];
                for kk in 0..k {
                    let (al, av) = input(row, kk);
                    let (bl, bv) = input(col, kk);
                    value = self.arena.fma(a[al][av], b[bl][bv], value);
                }
                wave.put(destination, lane, component as u16, Value::Real(value))?;
            }
        }
        Ok(())
    }
    fn matrix(&mut self, wave: &mut Wave, instruction: &Instruction) -> Result<(), EvalError> {
        if instruction.mnemonic.starts_with("v_wmma_") {
            return self.wmma(wave, instruction);
        }

        use super::matrix::{Form, InputKind};
        let mut form = Form::from_mnemonic(&instruction.mnemonic)
            .ok_or_else(|| self.unsupported(wave, instruction))?;
        let mut cbsz = 0u8;
        let mut blgp = 0u8;
        for modifier in &instruction.modifiers {
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
        let o = &instruction.operands;
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
        if let Operand::Register(register) = o[3] {
            if register.count as usize != output_items {
                return Err(wave.fail(None, "MFMA accumulator register count mismatch"));
            }
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
        let mut source_instruction = instruction.clone();
        source_instruction.operands = vec![o[0].clone(), o[1].clone(), o[2].clone()];
        if form.is_scaled() {
            source_instruction.operands.extend_from_slice(&o[4..6]);
        }
        let (sources_ab, _) = self.instruction_registers(&source_instruction, wave);
        source_instruction.operands = vec![o[0].clone(), o[3].clone()];
        let (accumulator, _) = self.instruction_registers(&source_instruction, wave);
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
        let outputs = super::matrix::compute(&mut self.arena, form, &a, &b, &c)
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
    fn vector(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
        name: &str,
    ) -> Result<(), EvalError> {
        if matches!(
            name,
            "v_readlane_b32" | "v_readfirstlane_b32" | "v_writelane_b32"
        ) && !(name == "v_readlane_b32" && self.architecture == AmdArchitecture::Gfx1250)
        {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "lane/accumulator register moves need Table 11 software dependency checks"
                    .into(),
            });
        }
        let o = &instruction.operands;
        if name == "v_s_exp_f32" {
            fn scalar_source(operand: &Operand) -> bool {
                match operand {
                    Operand::Register(r) => {
                        r.count == 1
                            && matches!(
                                r.class,
                                RegisterClass::Scalar
                                    | RegisterClass::Temporary
                                    | RegisterClass::Special
                            )
                    }
                    Operand::Modified { value, .. } => scalar_source(value),
                    Operand::Integer(_) | Operand::Float(_) => true,
                    _ => false,
                }
            }
            if !scalar_source(&o[1]) {
                return Err(EvalError::Unsupported {
                    pc: wave.pc,
                    what:
                        "v_s_exp_f32 requires a scalar source; vector-lane broadcast is not modeled"
                            .into(),
                });
            }
            if !instruction.modifiers.is_empty() || wave.exec == 0 {
                return Err(self.unsupported(wave, instruction));
            }
            let a = self.real(wave, &o[1], 0)?;
            let value = self.exp2(a);
            return wave.put_value(&o[0], 0, Value::Real(value));
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && (name == "v_ashrrev_i16" || name == "v_bfe_i32")
        {
            if !instruction.modifiers.is_empty()
                || o.iter()
                    .any(|operand| matches!(operand, Operand::Modified { .. }))
            {
                return Err(self.unsupported(wave, instruction));
            }
            let uniform_bits = |operand: &Operand| {
                if matches!(operand, Operand::Register(register) if matches!(register.class, RegisterClass::Vector | RegisterClass::Accumulator))
                {
                    None
                } else {
                    wave.bits(operand, 0).ok()
                }
            };
            let (operand, byte) = if name == "v_ashrrev_i16" && uniform_bits(&o[1]) == Some(8) {
                (&o[2], Some(1))
            } else if name == "v_bfe_i32" && uniform_bits(&o[3]) == Some(8) {
                let offset = uniform_bits(&o[2]);
                (
                    &o[1],
                    offset
                        .filter(|offset| *offset < 32 && *offset % 8 == 0)
                        .map(|offset| offset / 8),
                )
            } else {
                (&o[1], None)
            };
            if let Some(byte) = byte {
                let lanes = wave.active().collect::<Vec<_>>();
                let mut decoded = Vec::new();
                for lane in &lanes {
                    let value = wave.value(operand, *lane)?;
                    let zero = self.arena.int(0);
                    let expr = match value {
                        Value::Bytes(values) => Some(values[byte as usize]),
                        Value::Byte(expr) => Some(if byte == 0 { expr } else { zero }),
                        Value::BytePair(a, b) => Some(match byte {
                            0 => a,
                            1 => b,
                            _ => zero,
                        }),
                        _ => None,
                    };
                    if let Some(expr) = expr {
                        self.claim_byte_format(wave, expr, ByteFormat::SignedI8)?;
                        decoded.push((*lane, expr));
                    } else {
                        break;
                    }
                }
                if decoded.len() == lanes.len() {
                    for (lane, expr) in decoded {
                        wave.put_value(
                            &o[0],
                            lane,
                            if name == "v_ashrrev_i16" {
                                Value::Low16Integer(expr)
                            } else {
                                Value::NarrowInt {
                                    expr,
                                    bits: 8,
                                    signed: true,
                                }
                            },
                        )?;
                    }
                    return Ok(());
                }
            }
            if name == "v_ashrrev_i16" {
                if !instruction.modifiers.is_empty() {
                    return Err(self.unsupported(wave, instruction));
                }
                for lane in wave.active().collect::<Vec<_>>() {
                    let shift = wave
                        .value(&o[1], lane)?
                        .selected_bits(0, 4)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let source = wave
                        .value(&o[2], lane)?
                        .selected_bits(0, 16)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let result = self.arena.int(((source as i16) >> shift) as i64);
                    wave.put_value(&o[0], lane, Value::Low16Integer(result))?;
                }
                return Ok(());
            }
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && matches!(name, "v_pk_mul_lo_u16" | "v_pk_sub_i16")
        {
            if !instruction
                .modifiers
                .iter()
                .all(|m| matches!(m.name.as_str(), "op_sel" | "op_sel_hi"))
            {
                return Err(self.unsupported(wave, instruction));
            }
            let low = selectors(instruction, "op_sel", 2, 0)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            let high = selectors(instruction, "op_sel_hi", 2, 1)
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            for lane in wave.active().collect::<Vec<_>>() {
                let mut result = 0u32;
                for (half, selection) in [low.as_slice(), high.as_slice()].into_iter().enumerate() {
                    let a = wave
                        .value(&o[1], lane)?
                        .selected_bits(u32::from(selection[0]) * 16, 16)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let b = wave
                        .value(&o[2], lane)?
                        .selected_bits(u32::from(selection[1]) * 16, 16)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    let bits = if name == "v_pk_mul_lo_u16" {
                        a.wrapping_mul(b)
                    } else {
                        a.wrapping_sub(b)
                    };
                    result |= (bits & 65535) << (half * 16);
                }
                wave.put_value(&o[0], lane, Value::Integer(result))?;
            }
            return Ok(());
        }
        if self.architecture == AmdArchitecture::Gfx1250
            && matches!(
                name,
                "v_lshlrev_b16" | "v_lshrrev_b16" | "v_sub_u16" | "v_mul_lo_u16" | "v_bitop3_b16"
            )
        {
            // True16 shifts observe low16 data and low4 count bits. The
            // remaining destination bits stay undefined in this profile.
            if (name != "v_bitop3_b16" && !instruction.modifiers.is_empty())
                || (name == "v_bitop3_b16"
                    && (instruction.modifiers.len() != 1
                        || instruction.modifiers[0].name != "bitop3"))
            {
                return Err(self.unsupported(wave, instruction));
            }
            for lane in wave.active().collect::<Vec<_>>() {
                let a = wave
                    .value(&o[1], lane)?
                    .selected_bits(
                        0,
                        if matches!(name, "v_lshlrev_b16" | "v_lshrrev_b16") {
                            4
                        } else {
                            16
                        },
                    )
                    .map_err(|e| wave.fail(Some(lane), e))?;
                let b = wave
                    .value(&o[2], lane)?
                    .selected_bits(0, 16)
                    .map_err(|e| wave.fail(Some(lane), e))?;
                let value = match name {
                    "v_lshlrev_b16" => b.wrapping_shl(a & 15),
                    "v_lshrrev_b16" => b >> a,
                    "v_sub_u16" => a.wrapping_sub(b),
                    "v_mul_lo_u16" => a.wrapping_mul(b),
                    _ => {
                        let c = wave
                            .value(&o[3], lane)?
                            .selected_bits(0, 16)
                            .map_err(|e| wave.fail(Some(lane), e))?;
                        let table = instruction.modifiers[0]
                            .value
                            .as_deref()
                            .and_then(parse_u64)
                            .ok_or_else(|| self.unsupported(wave, instruction))?;
                        let mut result = 0;
                        for index in 0..8 {
                            if table & (1 << index) != 0 {
                                result |= (if index & 4 != 0 { a } else { !a })
                                    & (if index & 2 != 0 { b } else { !b })
                                    & (if index & 1 != 0 { c } else { !c });
                            }
                        }
                        result
                    }
                };
                wave.put_value(
                    &o[0],
                    lane,
                    Value::PartialBits {
                        bits: value & 65535,
                        defined: 65535,
                    },
                )?;
            }
            return Ok(());
        }
        let packed = name.starts_with("v_pk_");
        let mix = matches!(
            name,
            "v_fma_mixlo_f16" | "v_fma_mixhi_f16" | "v_fma_mix_f32"
        );
        let half_select_high = instruction.modifiers.iter().any(|modifier| {
            modifier.name == "src0_sel" && modifier.value.as_deref() == Some("WORD_1")
        });
        let half_select_high1 = instruction.modifiers.iter().any(|modifier| {
            modifier.name == "src1_sel" && modifier.value.as_deref() == Some("WORD_1")
        });
        let half_op = matches!(
            name,
            "v_cvt_f32_f16" | "v_add_f16" | "v_sub_f16" | "v_mul_f16" | "v_max_f16" | "v_min_f16"
        );
        let integer_sdwa = matches!(name, "v_add_u32" | "v_mul_lo_u16" | "v_mul_u32_u24");
        let clamp_f32 = matches!(
            name,
            "v_add_f32"
                | "v_sub_f32"
                | "v_subrev_f32"
                | "v_mul_f32"
                | "v_min_f32"
                | "v_max_f32"
                | "v_fma_f32"
                | "v_fmac_f32"
                | "v_rcp_f32"
                | "v_sqrt_f32"
                | "v_rsq_f32"
                | "v_exp_f32"
                | "v_log_f32"
                | "v_mov_b32"
                | "v_cndmask_b32"
        );
        let saturate = instruction
            .modifiers
            .iter()
            .any(|modifier| modifier.name == "clamp");
        if saturate
            && (instruction.mnemonic.ends_with("_e32") || instruction.mnemonic.ends_with("_sdwa"))
        {
            return Err(self.unsupported(wave, instruction));
        }
        let valid_modifiers = if packed || mix {
            instruction
                .modifiers
                .iter()
                .all(|modifier| matches!(modifier.name.as_str(), "op_sel" | "op_sel_hi"))
        } else if name == "v_cvt_f16_i16" {
            instruction.modifiers.iter().all(|modifier| {
                matches!(
                    (modifier.name.as_str(), modifier.value.as_deref()),
                    ("src0_sext", None)
                        | (
                            "src0_sel",
                            Some(
                                "DWORD"
                                    | "WORD_0"
                                    | "WORD_1"
                                    | "BYTE_0"
                                    | "BYTE_1"
                                    | "BYTE_2"
                                    | "BYTE_3"
                            )
                        )
                        | ("dst_sel", Some("DWORD"))
                        | ("dst_unused", Some("UNUSED_PAD"))
                )
            })
        } else if name == "v_bitop3_b32" {
            instruction.modifiers.len() == 1
                && instruction.modifiers[0].name == "bitop3"
                && instruction.modifiers[0]
                    .value
                    .as_deref()
                    .and_then(parse_u64)
                    .is_some_and(|value| value <= 255)
        } else if name == "v_cvt_f32_fp8" {
            instruction.modifiers.iter().all(|modifier| {
                (self.architecture == AmdArchitecture::Gfx1250
                    && modifier.name == "byte_sel"
                    && modifier
                        .value
                        .as_deref()
                        .and_then(parse_u64)
                        .is_some_and(|byte| byte <= 3))
                    || matches!(
                        (modifier.name.as_str(), modifier.value.as_deref()),
                        ("src0_sel", Some("BYTE_0" | "BYTE_1" | "BYTE_2" | "BYTE_3"))
                            | ("dst_sel", Some("DWORD"))
                            | ("dst_unused", Some("UNUSED_PAD"))
                    )
            })
        } else if half_op {
            instruction.modifiers.iter().all(|modifier| {
                matches!(
                    (modifier.name.as_str(), modifier.value.as_deref()),
                    ("src0_sel" | "src1_sel", Some("DWORD" | "WORD_0" | "WORD_1"))
                        | ("dst_sel", Some("DWORD"))
                        | ("dst_unused", Some("UNUSED_PAD"))
                )
            })
        } else if integer_sdwa {
            instruction.modifiers.iter().all(|modifier| {
                matches!(
                    (modifier.name.as_str(), modifier.value.as_deref()),
                    (
                        "src0_sel" | "src1_sel",
                        Some(
                            "DWORD"
                                | "WORD_0"
                                | "WORD_1"
                                | "BYTE_0"
                                | "BYTE_1"
                                | "BYTE_2"
                                | "BYTE_3"
                        )
                    ) | ("dst_sel", Some("DWORD"))
                        | ("dst_unused", Some("UNUSED_PAD"))
                )
            })
        } else if clamp_f32 {
            instruction
                .modifiers
                .iter()
                .all(|modifier| modifier.name == "clamp" && modifier.value.is_none())
        } else {
            instruction.modifiers.is_empty()
        };
        if !valid_modifiers {
            return Err(self.unsupported(wave, instruction));
        }
        let low_select = selectors(instruction, "op_sel", o.len() - 1, 0)
            .ok_or_else(|| self.unsupported(wave, instruction))?;
        let high_select = selectors(
            instruction,
            "op_sel_hi",
            o.len() - 1,
            if mix { 0 } else { 1 },
        )
        .ok_or_else(|| self.unsupported(wave, instruction))?;
        let lanes: Vec<_> = wave.active().collect();
        if matches!(
            name,
            "v_add_f64"
                | "v_mul_f64"
                | "v_min_f64"
                | "v_max_f64"
                | "v_fma_f64"
                | "v_fmac_f64"
                | "v_rcp_f64"
                | "v_sqrt_f64"
                | "v_cvt_f64_f32"
                | "v_cvt_f32_f64"
        ) {
            use super::scalar::{FloatBinOp, FloatUnOp, float_binary, float_fma, float_unary};
            for lane in lanes {
                let a = if name == "v_cvt_f64_f32" {
                    self.real(wave, &o[1], lane)?
                } else {
                    self.real64(wave, &o[1], lane)?
                };
                let result = match name {
                    "v_cvt_f32_f64" => {
                        wave.put_value(&o[0], lane, Value::Real(a))?;
                        continue;
                    }
                    "v_cvt_f64_f32" => a,
                    "v_rcp_f64" => {
                        if self.concrete_zero(a) {
                            return Err(EvalError::Unsupported{pc:wave.pc,what:"concrete zero reciprocal is undefined under the real-arithmetic contract".into()});
                        }
                        float_unary(&mut self.arena, FloatUnOp::Rcp, a)
                    }
                    "v_sqrt_f64" => {
                        if self.concrete_sign(a) == Some(std::cmp::Ordering::Less) {
                            return Err(EvalError::Unsupported{pc:wave.pc,what:"negative concrete square root is undefined under the real-arithmetic contract".into()});
                        }
                        float_unary(&mut self.arena, FloatUnOp::Sqrt, a)
                    }
                    _ => {
                        let b = self.real64(wave, &o[2], lane)?;
                        match name {
                            "v_fma_f64" | "v_fmac_f64" => {
                                let c = self.real64(
                                    wave,
                                    &o[if name == "v_fmac_f64" { 0 } else { 3 }],
                                    lane,
                                )?;
                                float_fma(&mut self.arena, a, b, c)
                            }
                            _ => float_binary(
                                &mut self.arena,
                                match name {
                                    "v_add_f64" => FloatBinOp::Add,
                                    "v_mul_f64" => FloatBinOp::Mul,
                                    "v_min_f64" => FloatBinOp::Min,
                                    _ => FloatBinOp::Max,
                                },
                                a,
                                b,
                            ),
                        }
                    }
                };
                self.put_real64(wave, &o[0], lane, result)?;
            }
            return Ok(());
        }
        if (integer_sdwa && (name != "v_add_u32" || !instruction.modifiers.is_empty()))
            || matches!(name, "v_add_u16" | "v_sub_u16" | "v_lshrrev_b16")
        {
            for lane in lanes {
                let a = self.selected_bits(wave, &o[1], lane, instruction, 0)?;
                let b = self.selected_bits(wave, &o[2], lane, instruction, 1)?;
                let result = match name {
                    "v_add_u16" => (a & 65535).wrapping_add(b & 65535) & 65535,
                    "v_sub_u16" => (a & 65535).wrapping_sub(b & 65535) & 65535,
                    "v_mul_lo_u16" => (a & 65535).wrapping_mul(b & 65535) & 65535,
                    "v_lshrrev_b16" => (b & 65535) >> (a & 15),
                    "v_add_u32" => a.wrapping_add(b),
                    _ => (a & 0xffffff).wrapping_mul(b & 0xffffff),
                };
                wave.put_value(&o[0], lane, Value::Integer(result))?;
            }
            return Ok(());
        }
        if matches!(name, "v_pk_mul_f32" | "v_pk_add_f32" | "v_pk_fma_f32") {
            let destination = wave.destination(&o[0])?;
            if destination.count != 2 {
                return Err(self.unsupported(wave, instruction));
            }
            for lane in lanes {
                let mut results = Vec::with_capacity(2);
                for component in 0..2 {
                    let select = if component == 0 {
                        &low_select
                    } else {
                        &high_select
                    };
                    let a = self.real_component(wave, &o[1], lane, select[0])?;
                    let b = self.real_component(wave, &o[2], lane, select[1])?;
                    results.push(match name {
                        "v_pk_mul_f32" => self.arena.mul(a, b),
                        "v_pk_add_f32" => self.arena.add(a, b),
                        _ => {
                            let c = self.real_component(wave, &o[3], lane, select[2])?;
                            self.arena.fma(a, b, c)
                        }
                    });
                }
                for (component, result) in results.into_iter().enumerate() {
                    wave.put(destination, lane, component as u16, Value::Real(result))?;
                }
            }
            return Ok(());
        }
        if name == "v_add_nc_u64" {
            for lane in lanes {
                let a = wave.wide(&o[1], lane)?;
                let b = wave.wide(&o[2], lane)?;
                wave.put_wide(&o[0], lane, a.wrapping_add(b))?;
            }
            return Ok(());
        }
        if name == "v_mad_u64_u32" {
            let mut mask = 0;
            for lane in lanes {
                let a = wave.bits(&o[2], lane)? as u64;
                let b = wave.bits(&o[3], lane)? as u64;
                let addend = wave.wide(&o[4], lane)?;
                let (result, carry) = a.wrapping_mul(b).overflowing_add(addend);
                wave.put_wide(&o[0], lane, result)?;
                if carry {
                    mask |= 1u64 << lane;
                }
            }
            return wave.put_wide(&o[1], 0, mask);
        }
        if name.starts_with("v_cmp_") || name.starts_with("v_cmpx_") {
            use super::scalar::{CmpOp, FloatType, IntType, ScalarType};
            let cmpx = name.starts_with("v_cmpx_");
            let prefix = if cmpx { "v_cmpx_" } else { "v_cmp_" };
            let (condition, kind) = name
                .trim_start_matches(prefix)
                .rsplit_once('_')
                .ok_or_else(|| self.unsupported(wave, instruction))?;
            if !matches!(kind, "f32" | "i32" | "u32" | "u16")
                && !(kind == "f16" && self.architecture == AmdArchitecture::Gfx1250)
            {
                return Err(self.unsupported(wave, instruction));
            }
            let start = if cmpx && wave.width == 32 {
                0
            } else if matches!(o.first(),Some(Operand::Register(reg)) if reg.class==RegisterClass::Special || reg.class==RegisterClass::Scalar)
            {
                1
            } else {
                0
            };
            if condition == "u" && kind == "f32" {
                for lane in lanes {
                    self.real(wave, &o[start], lane)?;
                    self.real(wave, &o[start + 1], lane)?;
                }
                return wave.put_wide(
                    if start == 1 {
                        &o[0]
                    } else {
                        return Err(self.unsupported(wave, instruction));
                    },
                    0,
                    0,
                );
            }
            let operation = match condition {
                "eq" => CmpOp::Eq,
                "ne" | "neq" => CmpOp::Ne,
                "lt" => CmpOp::Lt,
                "le" => CmpOp::Le,
                "gt" => CmpOp::Gt,
                "ge" => CmpOp::Ge,
                _ => return Err(self.unsupported(wave, instruction)),
            };
            let inactive = self.arena.bool_val(false);
            let mut predicates = [inactive; 64];
            let mut concrete_mask = Some(0u64);
            for lane in lanes {
                let (ty, a, b) = if matches!(kind, "f32" | "f16") {
                    let (a, b) = if kind == "f16" {
                        (
                            self.half(wave, &o[start], lane, false)?,
                            self.half(wave, &o[start + 1], lane, false)?,
                        )
                    } else {
                        (
                            self.real(wave, &o[start], lane)?,
                            self.real(wave, &o[start + 1], lane)?,
                        )
                    };
                    (
                        ScalarType::Float(FloatType::F32),
                        self.decoded_float_argument(a),
                        self.decoded_float_argument(b),
                    )
                } else {
                    let ty = IntType {
                        bits: if kind == "u16" { 16 } else { 32 },
                        signed: kind == "i32",
                    };
                    let a = self.integer_expression(wave, &o[start], lane, ty)?;
                    let b = self.integer_expression(wave, &o[start + 1], lane, ty)?;
                    (ScalarType::Int(ty), a, b)
                };
                let predicate = super::scalar::compare(&mut self.arena, ty, operation, a, b)
                    .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                predicates[lane as usize] = predicate;
                match self.arena.as_bool(predicate) {
                    Some(true) => {
                        if let Some(mask) = &mut concrete_mask {
                            *mask |= 1u64 << lane;
                        }
                    }
                    Some(false) => {}
                    None => concrete_mask = None,
                }
            }
            if cmpx {
                let mask = concrete_mask.ok_or_else(|| EvalError::Unsupported {
                    pc: wave.pc,
                    what: "symbolic comparison cannot drive EXEC or data-dependent control".into(),
                })?;
                wave.exec &= mask;
            }
            if cmpx && wave.width == 32 {
                return Ok(());
            }
            self.write_predicates(
                wave,
                if start == 1 { Some(&o[0]) } else { None },
                predicates,
            )?;
            return Ok(());
        }
        if name == "v_readfirstlane_b32" {
            let lane = wave.exec.trailing_zeros();
            if lane >= wave.width {
                return Err(wave.fail(None, "readfirstlane with empty EXEC"));
            }
            let value = wave.value(&o[1], lane as u8)?;
            return wave.put_value(&o[0], 0, value);
        }
        if name == "v_readlane_b32" {
            let lane = wave.bits(&o[2], 0)?;
            if lane >= wave.width {
                return Err(wave.fail(None, "readlane index out of range"));
            }
            let value = wave.value(&o[1], lane as u8)?;
            return wave.put_value(&o[0], 0, value);
        }
        if name == "v_writelane_b32" {
            let lane = wave.bits(&o[2], 0)?;
            if lane >= wave.width {
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
            let incoming = if o.len() > 4 && wave.exec != 0 {
                wave.wide(&o[4], 0)?
            } else {
                0
            };
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
                "v_perm_b32" => {
                    let selector = wave.bits(&o[3], lane)?;
                    let a = wave.value(&o[1], lane)?;
                    let b = wave.value(&o[2], lane)?;
                    if let (Ok(a), Ok(b)) = (a.bits(), b.bits()) {
                        let source = (a as u64) << 32 | b as u64;
                        let mut output = 0;
                        for byte in 0..4 {
                            let select = (selector >> (8 * byte)) & 255;
                            let value = match select {
                                0..=7 => (source >> (8 * select)) as u8,
                                8..=11 => {
                                    if source & (1u64 << (8 * (2 * (select - 8) + 1) + 7)) != 0 {
                                        255
                                    } else {
                                        0
                                    }
                                }
                                12 => 0,
                                _ => 255,
                            };
                            output |= (value as u32) << (8 * byte);
                        }
                        Value::Bits(output)
                    } else {
                        let mut halves = Vec::new();
                        for half in 0..2 {
                            let lo = (selector >> (16 * half)) & 255;
                            let hi = (selector >> (16 * half + 8)) & 255;
                            if lo == 12 && hi == 12 {
                                halves.push(self.arena.int(0));
                            } else {
                                if lo >= 8 || lo % 2 != 0 || hi != lo + 1 {
                                    return Err(self.unsupported(wave, instruction));
                                }
                                let source = if lo < 4 { &o[2] } else { &o[1] };
                                halves.push(self.half(wave, source, lane, lo % 4 == 2)?);
                            }
                        }
                        Value::Halves(halves[0], halves[1])
                    }
                }
                "v_fma_f16" => {
                    let a = self.half(wave, &o[1], lane, false)?;
                    let b = self.half(wave, &o[2], lane, false)?;
                    let c = self.half(wave, &o[3], lane, false)?;
                    Value::Half(self.arena.fma(a, b, c))
                }
                "v_alignbit_b32" => {
                    let shift = wave.bits(&o[3], lane)? & 31;
                    if shift == 0 {
                        wave.value(&o[2], lane)?
                    } else if shift == 16 {
                        Value::Halves(
                            self.half(wave, &o[2], lane, true)?,
                            self.half(wave, &o[1], lane, false)?,
                        )
                    } else {
                        let a = wave.bits(&o[1], lane)? as u64;
                        let b = wave.bits(&o[2], lane)? as u64;
                        Value::Bits((((a << 32) | b) >> shift) as u32)
                    }
                }
                "v_and_b32"
                    if matches!(wave.value(&o[1], lane)?, Value::PartialBits { .. })
                        || matches!(wave.value(&o[2], lane)?, Value::PartialBits { .. }) =>
                {
                    let (partial, mask) =
                        if matches!(wave.value(&o[1], lane)?, Value::PartialBits { .. }) {
                            (wave.value(&o[1], lane)?, wave.bits(&o[2], lane)?)
                        } else {
                            (wave.value(&o[2], lane)?, wave.bits(&o[1], lane)?)
                        };
                    let Value::PartialBits { bits, defined } = partial else {
                        unreachable!()
                    };
                    if mask & !defined != 0 {
                        return Err(
                            wave.fail(Some(lane), "AND observes undefined narrow result bits")
                        );
                    }
                    Value::Integer(bits & mask)
                }
                "v_lshrrev_b32" | "v_lshlrev_b32" => {
                    if matches!(
                        wave.value(&o[2], lane)?,
                        Value::Input(_) | Value::IntExpr(_)
                    ) {
                        let ty = super::scalar::IntType {
                            bits: 32,
                            signed: false,
                        };
                        let a = self.integer_expression(wave, &o[2], lane, ty)?;
                        let b = self.integer_expression(wave, &o[1], lane, ty)?;
                        let operation = if name == "v_lshrrev_b32" {
                            super::scalar::IntBinOp::LShr
                        } else {
                            super::scalar::IntBinOp::Shl
                        };
                        let expr = super::scalar::int_binary(&mut self.arena, ty, operation, a, b)
                            .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                        wave.put_value(&o[0], lane, self.integer_result(expr, false))?;
                        continue;
                    }
                    let shift = wave.bits(&o[1], lane)? & 31;
                    let value = wave.value(&o[2], lane)?;
                    if shift == 0 {
                        value
                    } else if shift % 8 == 0
                        && matches!(
                            value,
                            Value::Byte(_) | Value::BytePair(..) | Value::Bytes(_)
                        )
                    {
                        let zero = self.arena.int(0);
                        let bytes = match value {
                            Value::Byte(expr) => [expr, zero, zero, zero],
                            Value::BytePair(lo, hi) => [lo, hi, zero, zero],
                            Value::Bytes(bytes) => bytes,
                            _ => unreachable!(),
                        };
                        let mut output = [zero; 4];
                        let count = (shift / 8) as usize;
                        if name == "v_lshrrev_b32" {
                            output[..4 - count].copy_from_slice(&bytes[count..]);
                        } else {
                            output[count..].copy_from_slice(&bytes[..4 - count]);
                        }
                        Value::Bytes(output)
                    } else if shift == 16
                        && matches!(
                            value,
                            Value::Half(_) | Value::Halves(..) | Value::PartialHalves(..)
                        )
                    {
                        if name == "v_lshrrev_b32" {
                            Value::Half(self.half(wave, &o[2], lane, true)?)
                        } else {
                            let zero = self.arena.int(0);
                            Value::Halves(zero, self.half(wave, &o[2], lane, false)?)
                        }
                    } else {
                        let bits = value.bits().map_err(|e| wave.fail(Some(lane), e))?;
                        Value::Integer(if name == "v_lshrrev_b32" {
                            bits >> shift
                        } else {
                            bits.wrapping_shl(shift)
                        })
                    }
                }
                "v_cvt_pk_f32_fp8" => {
                    // Default encoding uses source bytes0/1. Both inputs are
                    // snapshotted before either destination register changes.
                    let low = self.fp8(wave, &o[1], lane, 0)?;
                    let high = self.fp8(wave, &o[1], lane, 1)?;
                    let destination = wave.destination(&o[0])?;
                    wave.put(destination, lane, 0, Value::Real(low))?;
                    wave.put(destination, lane, 1, Value::Real(high))?;
                    continue;
                }
                "v_cvt_f32_fp8" => {
                    let byte = instruction
                        .modifiers
                        .iter()
                        .find(|modifier| modifier.name == "src0_sel")
                        .and_then(|modifier| modifier.value.as_deref())
                        .and_then(|value| value.strip_prefix("BYTE_"))
                        .and_then(|value| value.parse::<usize>().ok())
                        .or_else(|| {
                            instruction
                                .modifiers
                                .iter()
                                .find(|modifier| modifier.name == "byte_sel")
                                .and_then(|modifier| modifier.value.as_deref())
                                .and_then(parse_u64)
                                .and_then(|byte| usize::try_from(byte).ok())
                        })
                        .unwrap_or(0);
                    Value::Real(self.fp8(wave, &o[1], lane, byte)?)
                }
                "v_fma_mixlo_f16" | "v_fma_mixhi_f16" | "v_fma_mix_f32" => {
                    let mut arguments = Vec::with_capacity(3);
                    for index in 0..3 {
                        arguments.push(if high_select[index] != 0 {
                            self.half(wave, &o[index + 1], lane, low_select[index] != 0)?
                        } else {
                            self.real(wave, &o[index + 1], lane)?
                        });
                    }
                    let result = self.arena.fma(arguments[0], arguments[1], arguments[2]);
                    if name == "v_fma_mix_f32" {
                        wave.put_value(&o[0], lane, Value::Real(result))?;
                        continue;
                    }
                    let old = wave.value(&o[0], lane).ok();
                    let old_half = |high| match old {
                        Some(Value::Halves(lo, hi)) => Some(if high { hi } else { lo }),
                        Some(Value::Half(expr)) if !high => Some(expr),
                        Some(Value::PartialHalves(lo, hi)) => {
                            if high {
                                hi
                            } else {
                                lo
                            }
                        }
                        _ => None,
                    };
                    let (lo, hi) = if name == "v_fma_mixlo_f16" {
                        (Some(result), old_half(true))
                    } else {
                        (old_half(false), Some(result))
                    };
                    if let (Some(lo), Some(hi)) = (lo, hi) {
                        Value::Halves(lo, hi)
                    } else {
                        Value::PartialHalves(lo, hi)
                    }
                }
                "v_mov_b64" => {
                    let destination = wave.destination(&o[0])?;
                    if let Operand::Register(source) = o[1] {
                        if source.count != 2 {
                            return Err(self.unsupported(wave, instruction));
                        }
                        let lo = wave.reg(source, lane, 0)?;
                        let hi = wave.reg(source, lane, 1)?;
                        wave.put(destination, lane, 0, lo)?;
                        wave.put(destination, lane, 1, hi)?;
                    } else {
                        let value = wave.wide(&o[1], lane)?;
                        wave.put_wide(&o[0], lane, value)?;
                    }
                    continue;
                }
                "v_cvt_f16_i16" => {
                    Value::Half(self.signed16_to_half(wave, &o[1], lane, instruction)?)
                }
                "v_cvt_f32_f16" => Value::Real(self.half(wave, &o[1], lane, half_select_high)?),
                "v_cvt_f16_f32" => Value::Half(self.real(wave, &o[1], lane)?),
                "v_cvt_pkrtz_f16_f32" | "v_cvt_pk_f16_f32" => {
                    Value::Halves(self.real(wave, &o[1], lane)?, self.real(wave, &o[2], lane)?)
                }
                "v_pack_b32_f16" => Value::Halves(
                    self.half(wave, &o[1], lane, false)?,
                    self.half(wave, &o[2], lane, false)?,
                ),
                "v_add_f16" | "v_sub_f16" | "v_mul_f16" | "v_max_f16" | "v_min_f16" => {
                    let a = self.half(wave, &o[1], lane, half_select_high)?;
                    let b = self.half(wave, &o[2], lane, half_select_high1)?;
                    Value::Half(match name {
                        "v_add_f16" => self.arena.add(a, b),
                        "v_sub_f16" => self.arena.sub(a, b),
                        "v_mul_f16" => self.arena.mul(a, b),
                        "v_max_f16" => self.arena.max(a, b),
                        _ => self.arena.min(a, b),
                    })
                }
                "v_fmac_f16" => {
                    let a = self.half(wave, &o[1], lane, false)?;
                    let b = self.half(wave, &o[2], lane, false)?;
                    let c = self.half(wave, &o[0], lane, false)?;
                    Value::Half(self.arena.fma(a, b, c))
                }
                "v_max3_f16" => {
                    let a = self.half(wave, &o[1], lane, false)?;
                    let b = self.half(wave, &o[2], lane, false)?;
                    let c = self.half(wave, &o[3], lane, false)?;
                    let partial = self.arena.max(a, b);
                    Value::Half(self.arena.max(partial, c))
                }
                "v_pk_add_f16" | "v_pk_mul_f16" | "v_pk_max_f16" | "v_pk_min_f16"
                | "v_pk_fma_f16" => {
                    let mut pair = Vec::with_capacity(2);
                    for high in [false, true] {
                        let select = if high { &high_select } else { &low_select };
                        let a = self.half(wave, &o[1], lane, select[0] != 0)?;
                        let b = self.half(wave, &o[2], lane, select[1] != 0)?;
                        pair.push(match name {
                            "v_pk_add_f16" => self.arena.add(a, b),
                            "v_pk_mul_f16" => self.arena.mul(a, b),
                            "v_pk_max_f16" => self.arena.max(a, b),
                            "v_pk_min_f16" => self.arena.min(a, b),
                            _ => {
                                let c = self.half(wave, &o[3], lane, select[2] != 0)?;
                                self.arena.fma(a, b, c)
                            }
                        });
                    }
                    Value::Halves(pair[0], pair[1])
                }
                "v_mov_b32"
                | "v_accvgpr_read_b32"
                | "v_accvgpr_write_b32"
                | "v_accvgpr_mov_b32" => self.modified_value(wave, &o[1], lane)?,
                "v_cndmask_b32" => {
                    let condition = self.predicate_condition(wave, o.get(3), lane)?;
                    self.select_word(wave, condition, &o[2], &o[1], lane, saturate)?
                }
                "v_lshlrev_b64" | "v_lshrrev_b64" | "v_ashrrev_i64" => {
                    let shift = wave.bits(&o[1], lane)? & 63;
                    let destination = wave.destination(&o[0])?;
                    if name == "v_ashrrev_i64" {
                        // CDNA4 V_ASHRREV_I64: D0.i64 = S1.i64 >> S0[5:0].
                        // The signed consumer fixes the output interpretation;
                        // store width alone never supplies signedness.
                        let value = (wave.wide(&o[2], lane)? as i64) >> shift;
                        let expr = self.arena.int(value);
                        wave.put(
                            destination,
                            lane,
                            0,
                            Value::WidePart {
                                expr,
                                high: false,
                                kind: WideKind::Integer,
                            },
                        )?;
                        wave.put(
                            destination,
                            lane,
                            1,
                            Value::WidePart {
                                expr,
                                high: true,
                                kind: WideKind::Integer,
                            },
                        )?;
                        continue;
                    }
                    if let Ok(bits) = wave.wide(&o[2], lane) {
                        let result = if name == "v_lshlrev_b64" {
                            bits.wrapping_shl(shift)
                        } else {
                            bits >> shift
                        };
                        wave.put(destination, lane, 0, Value::Integer(result as u32))?;
                        wave.put(destination, lane, 1, Value::Integer((result >> 32) as u32))?;
                    } else if matches!(shift, 0 | 32) {
                        let source = wave.destination(&o[2])?;
                        let low = wave.reg(source, lane, 0)?;
                        let high = wave.reg(source, lane, 1)?;
                        let (low, high) = if shift == 0 {
                            (low, high)
                        } else if name == "v_lshlrev_b64" {
                            (Value::Bits(0), low)
                        } else {
                            (high, Value::Bits(0))
                        };
                        wave.put(destination, lane, 0, low)?;
                        wave.put(destination, lane, 1, high)?;
                    } else {
                        return Err(wave.fail(
                            Some(lane),
                            "non-word symbolic64-bit shift requires exact encoded data bits",
                        ));
                    }
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
                "v_max3_num_f32" => {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    let c = self.real(wave, &o[3], lane)?;
                    let ab = self.arena.max(a, b);
                    Value::Real(self.arena.max(ab, c))
                }
                "v_fma_f32" | "v_mad_f32" | "v_fmac_f32" | "v_fmamk_f32" | "v_fmaak_f32" => {
                    let a = self.real(wave, &o[1], lane)?;
                    let b = self.real(wave, &o[2], lane)?;
                    let c =
                        self.real(wave, if name == "v_fmac_f32" { &o[0] } else { &o[3] }, lane)?;
                    Value::Real(self.arena.fma(a, b, c))
                }
                "v_rcp_f32" | "v_sqrt_f32" | "v_rsq_f32" | "v_exp_f32" | "v_log_f32" => {
                    let a = self.real(wave, &o[1], lane)?;
                    if matches!(name, "v_rcp_f32" | "v_rsq_f32") && self.concrete_zero(a) {
                        return Err(EvalError::Unsupported{pc:wave.pc,what:"concrete zero reciprocal/rsqrt is undefined under the real-arithmetic contract".into()});
                    }
                    let sign = self.concrete_sign(a);
                    if (matches!(name, "v_sqrt_f32" | "v_rsq_f32")
                        && sign == Some(std::cmp::Ordering::Less))
                        || (name == "v_log_f32"
                            && matches!(
                                sign,
                                Some(std::cmp::Ordering::Less | std::cmp::Ordering::Equal)
                            ))
                    {
                        return Err(EvalError::Unsupported {
                            pc: wave.pc,
                            what: format!(
                                "concrete operand outside {name} domain is undefined under the real-arithmetic contract"
                            ),
                        });
                    }
                    let result = match name {
                        "v_rcp_f32" => self.arena.rcp(a),
                        "v_sqrt_f32" => self.arena.sqrt(a),
                        "v_rsq_f32" => {
                            let root = self.arena.sqrt(a);
                            self.arena.rcp(root)
                        }
                        "v_exp_f32" => self.exp2(a),
                        _ => {
                            let ln2 = self.ln2_constant();
                            let log = self.arena.log(a);
                            self.arena.div(log, ln2)
                        }
                    };
                    Value::Real(result)
                }
                "v_cvt_f32_ubyte2" => {
                    let value = wave.value(&o[1], lane)?;
                    let expr = if let Value::Bytes(bytes) = value {
                        self.claim_byte_format(wave, bytes[2], ByteFormat::UnsignedU8)?;
                        bytes[2]
                    } else {
                        let byte = value
                            .selected_bits(16, 8)
                            .map_err(|error| wave.fail(Some(lane), error))?;
                        self.arena.int(byte as i64)
                    };
                    Value::Real(expr)
                }
                "v_cvt_f32_u32" | "v_cvt_f32_i32" => {
                    if name == "v_cvt_f32_u32"
                        && matches!(
                            wave.value(&o[1], lane)?,
                            Value::NarrowInt { signed: true, .. }
                        )
                    {
                        return Err(EvalError::Unsupported{pc:wave.pc,what:"signed narrow data reinterpreted as unsigned32 before float conversion".into()});
                    }
                    let ty = super::scalar::IntType {
                        bits: 32,
                        signed: name == "v_cvt_f32_i32",
                    };
                    let expr = self.integer_expression(wave, &o[1], lane, ty)?;
                    Value::Real(if let Some(value) = self.arena.as_int_const(expr) {
                        let value = super::scalar::canonical_int(value, ty)
                            .map_err(|e| wave.fail(Some(lane), e))?;
                        self.arena.int(value)
                    } else {
                        expr
                    })
                }
                _ => {
                    use super::scalar::{IntBinOp, IntType};
                    if name == "v_or_b32" {
                        let a = wave.value(&o[1], lane)?;
                        let b = wave.value(&o[2], lane)?;
                        let transport = |value: Value| {
                            matches!(
                                value,
                                Value::Input(_)
                                    | Value::Real(_)
                                    | Value::IntExpr(_)
                                    | Value::WidePart { .. }
                                    | Value::Half(_)
                                    | Value::Halves(..)
                                    | Value::PartialHalves(..)
                                    | Value::Byte(_)
                                    | Value::BytePair(..)
                                    | Value::Bytes(_)
                                    | Value::NarrowInt { .. }
                            )
                        };
                        let moved = if b.bits() == Ok(0) && transport(a) {
                            Some(a)
                        } else if a.bits() == Ok(0) && transport(b) {
                            Some(b)
                        } else {
                            None
                        };
                        if let Some(value) = moved {
                            wave.put_value(&o[0], lane, value)?;
                            continue;
                        }
                    }
                    let operation = match name {
                        "v_add_u32" | "v_add_nc_u32" => Some((IntBinOp::Add, false)),
                        "v_sub_u32" | "v_sub_nc_u32" => Some((IntBinOp::Sub, false)),
                        "v_subrev_u32" => Some((IntBinOp::Sub, true)),
                        "v_mul_lo_u32" | "v_mul_lo_i32" => Some((IntBinOp::MulLo, false)),
                        "v_min_u32" | "v_min_i32" => Some((IntBinOp::Min, false)),
                        "v_max_u32" | "v_max_i32" => Some((IntBinOp::Max, false)),
                        "v_and_b32" => Some((IntBinOp::And, false)),
                        "v_or_b32" => Some((IntBinOp::Or, false)),
                        "v_xor_b32" => Some((IntBinOp::Xor, false)),
                        "v_ashrrev_i32" => Some((IntBinOp::AShr, true)),
                        _ => None,
                    };
                    if let Some((operation, reverse)) = operation {
                        let ty = IntType {
                            bits: 32,
                            signed: name.ends_with("i32"),
                        };
                        let a = self.integer_expression(
                            wave,
                            &o[if reverse { 2 } else { 1 }],
                            lane,
                            ty,
                        )?;
                        let b = self.integer_expression(
                            wave,
                            &o[if reverse { 1 } else { 2 }],
                            lane,
                            ty,
                        )?;
                        let result =
                            super::scalar::int_binary(&mut self.arena, ty, operation, a, b)
                                .map_err(|what| EvalError::Unsupported { pc: wave.pc, what })?;
                        let value = self.integer_result(result, ty.signed);
                        wave.put_value(&o[0], lane, value)?;
                        continue;
                    }
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
                        "v_bfrev_b32" => a.reverse_bits(),
                        "v_lshlrev_b32" => b.wrapping_shl(a & 31),
                        "v_lshrrev_b32" => b.wrapping_shr(a & 31),
                        "v_ashrrev_i32" => ((b as i32) >> (a & 31)) as u32,
                        "v_min_u32" => a.min(b),
                        "v_max_u32" => a.max(b),
                        "v_min_i32" => (a as i32).min(b as i32) as u32,
                        "v_max_i32" => (a as i32).max(b as i32) as u32,
                        "v_mad_u32" => a.wrapping_mul(b).wrapping_add(wave.bits(&o[3], lane)?),
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
                        "v_or3_b32" => a | b | wave.bits(&o[3], lane)?,
                        "v_and_or_b32" => (a & b) | wave.bits(&o[3], lane)?,
                        "v_add3_u32" => a.wrapping_add(b).wrapping_add(wave.bits(&o[3], lane)?),
                        "v_xad_u32" => (a ^ b).wrapping_add(wave.bits(&o[3], lane)?),
                        "v_bfe_u32" | "v_bfe_i32" => {
                            super::scalar::bfe32(a, b, wave.bits(&o[3], lane)?, name == "v_bfe_i32")
                        }
                        "v_bfi_b32" => super::scalar::bfi32(a, b, wave.bits(&o[3], lane)?),
                        "v_bitop3_b32" => {
                            let c = wave.bits(&o[3], lane)?;
                            let table = instruction.modifiers[0]
                                .value
                                .as_deref()
                                .and_then(parse_u64)
                                .unwrap() as u8;
                            let mut result = 0;
                            for index in 0..8 {
                                if table & (1 << index) != 0 {
                                    result |= (if index & 4 != 0 { a } else { !a })
                                        & (if index & 2 != 0 { b } else { !b })
                                        & (if index & 1 != 0 { c } else { !c });
                                }
                            }
                            result
                        }
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
                    if name.contains("i32") {
                        Value::SignedInteger(value as i32)
                    } else {
                        Value::Integer(value)
                    }
                }
            };
            let value = if saturate {
                let decoded = self.real_value(wave, value, lane)?;
                Value::Real(super::scalar::clamp(
                    &mut self.arena,
                    super::scalar::Clamp::Sat,
                    decoded,
                ))
            } else {
                value
            };
            let value = if self.architecture == AmdArchitecture::Gfx1250
                && matches!(
                    name,
                    "v_add_f16"
                        | "v_sub_f16"
                        | "v_mul_f16"
                        | "v_max_f16"
                        | "v_min_f16"
                        | "v_cvt_f16_f32"
                        | "v_fmac_f16"
                ) {
                let Value::Half(low) = value else {
                    return Err(self.unsupported(wave, instruction));
                };
                // The hardware preserves the old upper half. If that payload
                // is not representable by the selected packed-data model,
                // retain it as undefined rather than inventing zero bits.
                let high = self.half(wave, &o[0], lane, true).ok();
                Value::PartialHalves(Some(low), high)
            } else {
                value
            };
            wave.put_value(&o[0], lane, value)?;
        }
        Ok(())
    }
    fn concrete_zero(&self, value: ExprId) -> bool {
        match self.arena.node(value) {
            ExprNode::IntConst(0) => true,
            ExprNode::RealConst(value) => value.is_zero(),
            _ => false,
        }
    }
    fn concrete_sign(&self, value: ExprId) -> Option<std::cmp::Ordering> {
        match self.arena.node(value) {
            ExprNode::IntConst(value) => Some(value.cmp(&0)),
            ExprNode::RealConst(value) => Some(value.cmp(&volta_expr::Real::from_i64(0))),
            _ => None,
        }
    }
    fn wait(&mut self, wave: &Wave, instruction: &Instruction) -> Result<(), EvalError> {
        if self.architecture == AmdArchitecture::Gfx1250 {
            if matches!(
                instruction.mnemonic.as_str(),
                "s_wait_loadcnt_dscnt" | "s_wait_storecnt_dscnt"
            ) {
                let Some(Operand::Integer(encoded)) = instruction.operands.first() else {
                    return Err(self.unsupported(wave, instruction));
                };
                if *encoded < 0 || *encoded > 0x3f3f {
                    return Err(self.unsupported(wave, instruction));
                }
                self.builder.amd_event(
                    wave.id,
                    ProgramPoint(wave.pc as u32),
                    AmdEventKind::WaitCounters {
                        thresholds: vec![
                            (
                                if instruction.mnemonic == "s_wait_loadcnt_dscnt" {
                                    AmdCounter::Load
                                } else {
                                    AmdCounter::Store
                                },
                                ((*encoded >> 8) & 63) as u16,
                            ),
                            (AmdCounter::Ds, (*encoded & 63) as u16),
                        ],
                    },
                );
                return Ok(());
            }
            let counter = match instruction.mnemonic.as_str() {
                "s_wait_loadcnt" => AmdCounter::Load,
                "s_wait_storecnt" => AmdCounter::Store,
                "s_wait_dscnt" => AmdCounter::Ds,
                "s_wait_kmcnt" => AmdCounter::Km,
                "s_wait_xcnt" => AmdCounter::X,
                "s_wait_asynccnt" => AmdCounter::Async,
                "s_wait_tensorcnt" => AmdCounter::Tensor,
                _ => return Err(self.unsupported(wave, instruction)),
            };
            let [Operand::Integer(value)] = instruction.operands.as_slice() else {
                return Err(self.unsupported(wave, instruction));
            };
            let value = u16::try_from(*value).map_err(|_| self.unsupported(wave, instruction))?;
            self.builder.amd_event(
                wave.id,
                ProgramPoint(wave.pc as u32),
                AmdEventKind::WaitCounters {
                    thresholds: vec![(counter, value)],
                },
            );
            return Ok(());
        }
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
    fn tensor(&mut self, wave: &mut Wave, instruction: &Instruction) -> Result<(), EvalError> {
        if self.architecture != AmdArchitecture::Gfx1250 || !instruction.modifiers.is_empty() {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec == 0 {
            return Ok(());
        }
        let load = match instruction.mnemonic.as_str() {
            "tensor_load_to_lds" => true,
            "tensor_store_from_lds" => false,
            _ => return Err(self.unsupported(wave, instruction)),
        };
        let mut groups = Vec::new();
        for (operand, count) in instruction.operands.iter().zip([4, 8, 4, 4]) {
            let register = wave.destination(operand)?;
            if register.class != RegisterClass::Scalar || register.count != count {
                return Err(self.unsupported(wave, instruction));
            }
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
        let d0 = &groups[0];
        let d1 = &groups[1];
        // Public LLVM/FlyDSL D0..D3 profile: non-cluster 2D, no
        // padding, atomic barrier, iteration, gather, OOB fill or swizzle.
        if d0[0] > 1
            || d0[3] & 0xfe00_0000 != 0x8000_0000
            || d1[0] & !0x30000 != 0
            || groups[2].iter().chain(&groups[3]).any(|&x| x != 0)
        {
            return Err(EvalError::Unsupported{pc:wave.pc,what:"tensor descriptor requires bounded non-padded 2D global/LDS profile without multicast/atomic/iteration/gather".into()});
        }
        if d0[0] == 0 {
            return Ok(());
        }
        let data_size = (d1[0] >> 16) & 3;
        if data_size > 2 {
            return Err(self.unsupported(wave, instruction));
        }
        let width = 1u64 << data_size;
        let dim0 = ((d1[1] >> 16) as u64) | (((d1[2] & 65535) as u64) << 16);
        let dim1 = ((d1[2] >> 16) as u64) | (((d1[3] & 65535) as u64) << 16);
        let cols = (d1[3] >> 16) as u64;
        let rows = (d1[4] & 65535) as u64;
        let stride = d1[5] as u64;
        if d1[1] & 65535 != 0
            || d1[4] >> 16 != 0
            || d1[6] != 0
            || d1[7] != 0
            || cols == 0
            || rows == 0
            || cols > dim0
            || rows > dim1
            || stride < dim0
        {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "tensor 2D shape/stride/OOB descriptor unsupported".into(),
            });
        }
        let global = d0[2] as u64 | (((d0[3] & 0x1ffffff) as u64) << 32);
        let shared = d0[1] as u64;
        let bytes = rows
            .checked_mul(cols)
            .and_then(|v| v.checked_mul(width))
            .filter(|&v| v <= self.lds_size)
            .ok_or_else(|| wave.fail(None, "tensor tile exceeds LDS capacity"))?;
        let global_end = (rows - 1)
            .checked_mul(stride)
            .and_then(|v| v.checked_add(cols))
            .and_then(|v| v.checked_mul(width))
            .and_then(|v| v.checked_add(global))
            .ok_or_else(|| wave.fail(None, "tensor global address overflow"))?;
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
        let shared_end = shared
            .checked_add(bytes)
            .filter(|&v| v <= self.lds_size)
            .ok_or_else(|| wave.fail(None, "tensor footprint exceeds LDS capacity"))?;
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
        let (reads, _) = self.instruction_registers(instruction, wave);
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
                held_sources: reads
                    .into_iter()
                    .filter(|r| r.file != AmdRegisterFile::Scalar || r.index != 126)
                    .collect(),
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
                    self.global.read(ga, width)
                } else {
                    self.lds.read(sa, width)
                }
                .map_err(|e| wave.fail(Some(lane), e))?;
                if load {
                    self.lds.write(sa, width, value)
                } else {
                    self.global.write(ga, width, value)
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
    fn atomic_add_f32_no_return(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        let operands = &instruction.operands;
        if self.architecture != AmdArchitecture::Gfx1250
            || operands.len() != 3
            || instruction
                .modifiers
                .iter()
                .filter(|modifier| {
                    modifier.name == "scope" && modifier.value.as_deref() == Some("SCOPE_DEV")
                })
                .count()
                != 1
            || instruction
                .modifiers
                .iter()
                .any(|modifier| !matches!(modifier.name.as_str(), "scope" | "scale_offset"))
            || instruction
                .modifiers
                .iter()
                .filter(|modifier| modifier.name == "scale_offset")
                .count()
                > 1
        {
            return Err(self.unsupported(wave, instruction));
        }
        if wave.exec == 0 {
            return Ok(());
        }
        if wave.exec.count_ones() != 1 {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "native F32 atomic add currently requires one issuing lane per wave".into(),
            });
        }
        let lane = wave.exec.trailing_zeros() as u8;
        let scale = if instruction
            .modifiers
            .iter()
            .any(|modifier| modifier.name == "scale_offset")
        {
            4
        } else {
            1
        };
        let address = (wave.bits(&operands[0], lane)? as u64)
            .checked_mul(scale)
            .and_then(|offset| wave.wide(&operands[2], lane).ok()?.checked_add(offset))
            .ok_or_else(|| {
                wave.fail(
                    Some(lane),
                    "native atomic address overflow or invalid scalar base",
                )
            })?;
        self.validate_address(wave, lane, false, address, 4, true)?;
        let previous = self
            .global
            .read(address, 4)
            .map_err(|error| wave.fail(Some(lane), error))?;
        let previous = self.real_value(wave, previous, lane)?;
        let addend = self.real(wave, &operands[1], lane)?;
        let next = self.arena.add(previous, addend);
        let (reads, writes) = self.instruction_registers(instruction, wave);
        debug_assert!(writes.is_empty());
        let issue = self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::GlobalAtomicAddF32NoReturn,
                counters: vec![(AmdCounter::Store, 1), (AmdCounter::X, 1)],
                destinations: Vec::new(),
                held_sources: reads,
            },
        );
        self.global
            .write(address, 4, Value::Real(next))
            .map_err(|error| wave.fail(Some(lane), error))?;
        let thread = ThreadIx(wave.id * wave.width + lane as u32);
        for mode in [AccessMode::Read, AccessMode::Write] {
            let value = if mode == AccessMode::Write {
                Some(self.builder.value(StoredValue::Scalar(next)))
            } else {
                None
            };
            let effect = self.builder.thread_access(
                thread,
                ProgramPoint(wave.pc as u32),
                MemAccess {
                    space: Space::Global,
                    mode,
                    ordering: OrderingKind::Atomic,
                    proxy: Proxy::Generic,
                    footprint: Footprint::Bytes {
                        addr: address,
                        width: 4,
                    },
                    role: OperandRole::Plain,
                    attributed: thread,
                    value,
                },
            );
            self.builder.amd_memory_effect(issue, effect);
        }
        Ok(())
    }
    fn memory_instruction(
        &mut self,
        wave: &mut Wave,
        instruction: &Instruction,
    ) -> Result<(), EvalError> {
        let name = match instruction.mnemonic.as_str() {
            "ds_store_b16_d16_hi" => "ds_write_b16_d16_hi",
            name => name,
        };
        let o = &instruction.operands;
        if name == "global_atomic_add_f32" {
            return self.atomic_add_f32_no_return(wave, instruction);
        }
        if name.starts_with("tensor_") {
            return self.tensor(wave, instruction);
        }
        if name == "ds_bpermute_b32" || name == "ds_permute_b32" {
            return self.permute(wave, instruction);
        }
        let store = name.contains("store") || name.starts_with("ds_write");
        let scalar = instruction.opcode == Opcode::ScalarMemory;
        let lds = instruction.opcode == Opcode::Lds;
        let dual = name.starts_with("ds_read2") || name.starts_with("ds_write2");
        if name.contains("_d16") && !matches!(name, "ds_write_b16_d16_hi" | "ds_write_b8_d16_hi") {
            return Err(self.unsupported(wave, instruction));
        }
        if !scalar && wave.exec == 0 {
            return Ok(());
        }
        if self.xnack_replay_enabled && instruction.opcode == Opcode::VectorMemory {
            return Err(EvalError::Unsupported {pc:wave.pc,what:"XNACK-enabled vector memory replay clauses and source retention are not modeled".into()});
        }
        let flat = name.starts_with("flat_load_") || name.starts_with("flat_store_");
        if !(name.starts_with("s_load_")
            || name.starts_with("global_load_")
            || name.starts_with("global_store_")
            || flat
            || name.starts_with("ds_read_")
            || name.starts_with("ds_write_")
            || name.starts_with("ds_load_")
            || name.starts_with("ds_store_")
            || dual)
        {
            return Err(self.unsupported(wave, instruction));
        }
        if scalar && self.xnack_replay_enabled {
            self.validate_smem_clause(wave)?;
        }
        let mut dual_offsets = [0u64; 2];
        let offset =
            instruction
                .modifiers
                .iter()
                .try_fold(0i64, |offset, modifier| match modifier.name.as_str() {
                    "offset" => modifier
                        .value
                        .as_ref()
                        .and_then(|value| parse_i64(value))
                        .ok_or_else(|| self.unsupported(wave, instruction)),
                    "glc" | "slc" | "dlc" | "sc0" | "sc1" | "scale_offset" => Ok(offset),
                    "offset0" | "offset1" if dual => {
                        let index = if modifier.name == "offset0" { 0 } else { 1 };
                        dual_offsets[index] = modifier
                            .value
                            .as_deref()
                            .and_then(parse_u64)
                            .ok_or_else(|| self.unsupported(wave, instruction))?;
                        Ok(offset)
                    }
                    _ => Err(self.unsupported(wave, instruction)),
                })?;
        let offset_valid = if lds {
            (0..=65535).contains(&offset)
        } else if flat {
            (0..=4095).contains(&offset)
        } else if scalar {
            (0..=(1 << 21) - 1).contains(&offset)
        } else if self.architecture == AmdArchitecture::Gfx1250 && name.starts_with("global_") {
            // LLVM FeatureFlatOffsetBits24 and VFLAT_Real encode a signed24
            // immediate. scale_offset scales the VGPR index, not this byte offset.
            (-8_388_608..=8_388_607).contains(&offset)
        } else {
            (-4096..=4095).contains(&offset)
        };
        if !offset_valid || dual_offsets.iter().any(|&value| value > 255) {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "memory offset is outside its native encoded range".into(),
            });
        }
        let registers = if name.contains("dwordx16") || name.ends_with("b512") {
            16
        } else if name.contains("dwordx8") || name.ends_with("b256") {
            8
        } else if name.contains("dwordx4") || name.ends_with("b128") {
            4
        } else if name.contains("dwordx3") || name.ends_with("b96") {
            3
        } else if name.contains("dwordx2") || name.ends_with("b64") {
            2
        } else {
            1
        };
        let registers_per_part = registers;
        let registers = if dual { registers * 2 } else { registers };
        if dual && dual_offsets[0] == dual_offsets[1] {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what:
                    "equal-offset DS_READ2/DS_WRITE2 requires explicit duplicate-access semantics"
                        .into(),
            });
        }
        let width = if name.contains("short")
            || name.ends_with("u16")
            || name.ends_with("i16")
            || name.contains("_b16")
        {
            2
        } else if name.contains("byte")
            || name.ends_with("u8")
            || name.ends_with("i8")
            || name.contains("_b8")
        {
            1
        } else {
            4
        };
        let scalar_displacement = if scalar {
            wave.wide(&o[2], 0)?
                .checked_mul(
                    if instruction
                        .modifiers
                        .iter()
                        .any(|m| m.name == "scale_offset")
                    {
                        width * registers as u64
                    } else {
                        1
                    },
                )
                .ok_or_else(|| wave.fail(None, "scaled scalar offset overflow"))?
        } else {
            0
        };
        if scalar && ((wave.wide(&o[1], 0)? | scalar_displacement | offset as u64) & 3) != 0 {
            return Err(EvalError::Unsupported {
                pc: wave.pc,
                what: "unaligned SMEM address components require native low-bit masking semantics"
                    .into(),
            });
        }
        let class = if self.architecture == AmdArchitecture::Gfx1250 {
            if flat {
                return Err(self.unsupported(wave, instruction));
            }
            if scalar {
                AmdMemoryClass::ScalarLoad
            } else if lds {
                AmdMemoryClass::Ds
            } else if store {
                AmdMemoryClass::VectorStore
            } else {
                AmdMemoryClass::VectorLoad
            }
        } else if flat && store && registers >= 3 {
            AmdMemoryClass::FlatStoreWide
        } else if !scalar && !lds && store && registers >= 3 {
            AmdMemoryClass::VectorStoreWide
        } else if flat {
            AmdMemoryClass::Flat
        } else if scalar {
            AmdMemoryClass::ScalarMemory
        } else if lds {
            AmdMemoryClass::Lds
        } else {
            AmdMemoryClass::VectorMemory
        };
        let counters = if self.architecture == AmdArchitecture::Gfx1250 {
            if scalar {
                vec![(AmdCounter::Km, 1), (AmdCounter::X, 1)]
            } else if lds {
                vec![(AmdCounter::Ds, 1)]
            } else if store {
                vec![(AmdCounter::Store, 1), (AmdCounter::X, 1)]
            } else {
                vec![(AmdCounter::Load, 1), (AmdCounter::X, 1)]
            }
        } else if flat {
            vec![(AmdCounter::Vm, 1), (AmdCounter::Lgkm, 1)]
        } else if scalar {
            vec![(AmdCounter::Lgkm, if registers > 1 { 2 } else { 1 })]
        } else if lds {
            vec![(AmdCounter::Lgkm, 1)]
        } else {
            vec![(AmdCounter::Vm, 1)]
        };
        let (reads, writes) = self.instruction_registers(instruction, wave);
        let held_sources = if self.architecture == AmdArchitecture::Gfx1250 && !lds {
            reads.clone()
        } else if store && !lds && registers >= 3 {
            let data_register = wave.destination(&o[1])?;
            reads
                .iter()
                .copied()
                .filter(|register| {
                    register.index >= data_register.index
                        && register.index < data_register.index + data_register.count
                        && matches!(
                            (register.file, data_register.class),
                            (AmdRegisterFile::Vector, RegisterClass::Vector)
                                | (AmdRegisterFile::Accumulator, RegisterClass::Accumulator)
                        )
                })
                .collect()
        } else {
            Vec::new()
        };
        let issue = self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class,
                counters,
                destinations: if store { Vec::new() } else { writes },
                held_sources,
            },
        );
        let lanes: Vec<_> = if scalar {
            vec![0]
        } else {
            wave.active().collect()
        };
        for lane in lanes {
            let mut effective_lds = lds;
            let (address, data_operand) = if scalar {
                (
                    wave.wide(&o[1], lane)?
                        .checked_add(scalar_displacement)
                        .and_then(|addr| addr.checked_add(offset as u64))
                        .ok_or_else(|| wave.fail(Some(lane), "scalar load address overflow"))?,
                    &o[0],
                )
            } else if lds {
                if store {
                    (
                        wave.bits(&o[0], lane)?.wrapping_add(offset as u32) as u64,
                        &o[1],
                    )
                } else {
                    (
                        wave.bits(&o[1], lane)?.wrapping_add(offset as u32) as u64,
                        &o[0],
                    )
                }
            } else if flat {
                let operand = if store { &o[0] } else { &o[1] };
                let (address, shared) =
                    self.flat_memory_address(wave, operand, lane, offset as u64)?;
                effective_lds = shared;
                (address, if store { &o[1] } else { &o[0] })
            } else if store {
                (
                    wave.wide(&o[0], lane)?
                        .wrapping_mul(
                            if instruction
                                .modifiers
                                .iter()
                                .any(|m| m.name == "scale_offset")
                            {
                                width * registers as u64
                            } else {
                                1
                            },
                        )
                        .wrapping_add(if o.len() > 2 {
                            wave.wide(&o[2], lane)?
                        } else {
                            0
                        })
                        .wrapping_add(offset as u64),
                    &o[1],
                )
            } else {
                (
                    wave.wide(&o[1], lane)?
                        .wrapping_mul(
                            if instruction
                                .modifiers
                                .iter()
                                .any(|m| m.name == "scale_offset")
                            {
                                width * registers as u64
                            } else {
                                1
                            },
                        )
                        .wrapping_add(if o.len() > 2 {
                            wave.wide(&o[2], lane)?
                        } else {
                            0
                        })
                        .wrapping_add(offset as u64),
                    &o[0],
                )
            };
            let register = wave.destination(data_operand)?;
            let component_address = |component: u16| -> Result<u64, &str> {
                let displacement = if dual {
                    let part = component / registers_per_part;
                    let unit = if name.ends_with("b64") { 8 } else { 4 };
                    let stride = if name.contains("st64") { 64 } else { 1 };
                    dual_offsets[part as usize] * unit * stride
                        + (component % registers_per_part) as u64 * width
                } else {
                    component as u64 * width
                };
                if lds {
                    Ok((address as u32).wrapping_add(displacement as u32) as u64)
                } else {
                    address
                        .checked_add(displacement)
                        .ok_or("memory address overflow")
                }
            };
            if !effective_lds || !self.config.shared_allocations.is_empty() {
                let mut first = u64::MAX;
                let mut end = 0;
                for component in 0..registers {
                    let addr = component_address(component)
                        .map_err(|error| wave.fail(Some(lane), error))?;
                    first = first.min(addr);
                    end = end.max(addr.checked_add(width).ok_or_else(|| {
                        wave.fail(Some(lane), "shared instruction footprint overflow")
                    })?);
                }
                let kernarg_size = self.program.descriptor.value("kernarg_size", 0);
                let abi_end =
                    if scalar && address >= KERNARG_BASE && address - KERNARG_BASE < kernarg_size {
                        Some(KERNARG_BASE + kernarg_size)
                    } else if scalar && address >= DISPATCH_BASE && address - DISPATCH_BASE < 64 {
                        Some(DISPATCH_BASE + 64)
                    } else {
                        None
                    };
                let fits = if effective_lds {
                    self.config.shared_allocations.iter().any(|allocation| {
                        allocation.offset <= first && end <= allocation.offset + allocation.size
                    })
                } else if let Some(limit) = abi_end {
                    end <= limit
                } else {
                    self.config.arrays.iter().any(|allocation| {
                        allocation.base <= first && end <= allocation.base + allocation.size_bytes()
                    }) || self.module_globals.values().any(|allocation| {
                        allocation.base <= first && end <= allocation.base + allocation.size
                    })
                };
                if !fits {
                    return Err(wave.fail(
                        Some(lane),
                        if effective_lds {
                            "shared instruction footprint crosses configured allocation boundaries"
                        } else if abi_end.is_some() {
                            "load exceeds the declared ABI segment"
                        } else {
                            "out-of-bounds global instruction footprint crosses allocation boundaries"
                        },
                    ));
                }
            }
            for component in 0..registers {
                let addr =
                    component_address(component).map_err(|error| wave.fail(Some(lane), error))?;
                let kernarg_size = self.program.descriptor.value("kernarg_size", 0);
                let kernarg = scalar && addr >= KERNARG_BASE && addr - KERNARG_BASE < kernarg_size;
                let dispatch = scalar && addr >= DISPATCH_BASE && addr - DISPATCH_BASE < 64;
                let abi = kernarg || dispatch;
                if abi
                    && width
                        > if kernarg {
                            kernarg_size - (addr - KERNARG_BASE)
                        } else {
                            64 - (addr - DISPATCH_BASE)
                        }
                {
                    return Err(wave.fail(Some(lane), "load exceeds the declared ABI segment"));
                }
                if !abi {
                    self.validate_address(wave, lane, effective_lds, addr, width, store)?;
                }
                let value = if store {
                    let source_register = if dual && component >= registers_per_part {
                        wave.destination(&o[2])?
                    } else {
                        register
                    };
                    let source_component = if dual {
                        component % registers_per_part
                    } else {
                        component
                    };
                    let value = if name == "ds_write_b8_d16_hi" {
                        match wave.reg(source_register, lane, source_component)? {
                            Value::Bytes(bytes) => Value::Byte(bytes[2]),
                            Value::Byte(_) => Value::Bits(0),
                            value => Value::Bits(
                                (value.bits().map_err(|e| wave.fail(Some(lane), e))? >> 16) & 255,
                            ),
                        }
                    } else if name == "ds_write_b16_d16_hi" {
                        let mut source = source_register;
                        source.index += source_component;
                        source.count = 1;
                        Value::Half(self.half(wave, &Operand::Register(source), lane, true)?)
                    } else {
                        wave.reg(source_register, lane, source_component)?
                    };
                    let memory = if effective_lds {
                        &mut self.lds
                    } else {
                        &mut self.global
                    };
                    let value = memory
                        .write(addr, width, value)
                        .map_err(|e| wave.fail(Some(lane), e))?;
                    Some(value)
                } else {
                    let memory = if dispatch {
                        &self.dispatch
                    } else if kernarg {
                        &self.kernargs
                    } else if effective_lds {
                        &self.lds
                    } else {
                        &self.global
                    };
                    let mut value = memory
                        .read(addr, width)
                        .or_else(|error| {
                            if kernarg {
                                memory.read_partial_abi(addr, width)
                            } else {
                                Err(error)
                            }
                        })
                        .map_err(|e| {
                            wave.fail(
                                Some(lane),
                                format!(
                                    "{} {addr:#x}: {e}",
                                    if effective_lds {
                                        "LDS"
                                    } else if abi {
                                        "kernarg"
                                    } else {
                                        "global"
                                    }
                                ),
                            )
                        })?;
                    if name.contains("sbyte") || name.ends_with("i8") {
                        value = match value {
                            Value::Byte(expr) => {
                                self.claim_byte_format(wave, expr, ByteFormat::SignedI8)?;
                                Value::NarrowInt {
                                    expr,
                                    bits: 8,
                                    signed: true,
                                }
                            }
                            Value::NarrowInt {
                                bits: 8,
                                signed: true,
                                ..
                            } => value,
                            _ => Value::SignedInteger(
                                value
                                    .bits()
                                    .map_err(|_| self.unsupported(wave, instruction))?
                                    as i8 as i32,
                            ),
                        };
                    }
                    if name.contains("sshort") || name.ends_with("i16") {
                        value = Value::SignedInteger(
                            value
                                .bits()
                                .map_err(|_| self.unsupported(wave, instruction))?
                                as i16 as i32,
                        );
                    }
                    wave.put(register, lane, component, value)?;
                    None
                };
                {
                    let stored = if let Some(value) = value {
                        Some(self.builder.value(match value {
                            Value::Input(expression)
                            | Value::IntExpr(expression)
                            | Value::NarrowInt {
                                expr: expression, ..
                            }
                            | Value::Real(expression)
                            | Value::Half(expression)
                            | Value::Byte(expression) => StoredValue::Scalar(expression),
                            Value::Bits(bits) | Value::Integer(bits) => {
                                StoredValue::Scalar(self.arena.int(bits as i64))
                            }
                            Value::SignedInteger(value) => {
                                StoredValue::Scalar(self.arena.int(value as i64))
                            }
                            Value::Halves(lo, hi) | Value::BytePair(lo, hi) => {
                                StoredValue::Pair(lo, hi)
                            }
                            Value::Bytes(bytes) => StoredValue::Quad(bytes),
                            Value::PartialHalves(..)
                            | Value::WidePart { .. }
                            | Value::PredicateWord { .. }
                            | Value::RelocationWord { .. }
                            | Value::SharedApertureHi
                            | Value::PartialBits { .. }
                            | Value::Low16Integer(_) => StoredValue::Opaque,
                        }))
                    } else {
                        None
                    };
                    let effect = self.builder.thread_access(
                        ThreadIx(wave.id * wave.width + lane as u32),
                        ProgramPoint(wave.pc as u32),
                        MemAccess {
                            space: if effective_lds {
                                Space::Shared
                            } else {
                                Space::Global
                            },
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
                            attributed: ThreadIx(wave.id * wave.width + lane as u32),
                            value: stored,
                        },
                    );
                    let scope = if self.architecture != AmdArchitecture::Gfx1250
                        && name.starts_with("global_")
                        && instruction
                            .modifiers
                            .iter()
                            .any(|modifier| modifier.name == "sc0")
                        && !instruction
                            .modifiers
                            .iter()
                            .any(|modifier| modifier.name == "sc1")
                    {
                        AmdMemoryScope::Workgroup
                    } else {
                        AmdMemoryScope::Unspecified
                    };
                    self.builder.amd_memory_effect_scoped(issue, effect, scope);
                }
            }
        }
        Ok(())
    }
    fn flat_memory_address(
        &self,
        wave: &Wave,
        operand: &Operand,
        lane: u8,
        offset: u64,
    ) -> Result<(u64, bool), EvalError> {
        if let Operand::Register(register) = operand {
            if register.count == 2 && wave.reg(*register, lane, 1)? == Value::SharedApertureHi {
                let low =
                    wave.reg(*register, lane, 0)?
                        .bits()
                        .map_err(|error| wave.fail(Some(lane), error))? as u64;
                let address = low
                    .checked_add(offset)
                    .filter(|value| *value <= u32::MAX as u64)
                    .ok_or_else(|| {
                        wave.fail(Some(lane), "FLAT offset escapes the shared aperture")
                    })?;
                return Ok((address, true));
            }
        }
        Ok((wave.wide(operand, lane)?.wrapping_add(offset), false))
    }
    /// CDNA4 §8.2.1 forbids replay-enabled scalar-memory clauses from overwriting
    /// an address-source SGPR, except one DWORD loaded by an isolated instruction.
    /// Treat each maximal contiguous SMEM run as one clause conservatively.
    fn validate_smem_clause(&self, wave: &Wave) -> Result<(), EvalError> {
        let mut start = wave.pc;
        while start > 0 && self.program.instructions[start - 1].opcode == Opcode::ScalarMemory {
            start -= 1;
        }
        let mut end = wave.pc + 1;
        while end < self.program.instructions.len()
            && self.program.instructions[end].opcode == Opcode::ScalarMemory
        {
            end += 1;
        }
        let clause = &self.program.instructions[start..end];
        if clause.len() == 1 && clause[0].mnemonic == "s_load_dword" {
            return Ok(());
        }
        let mut sources = std::collections::BTreeSet::new();
        for instruction in clause {
            for operand in instruction.operands.iter().skip(1) {
                if let Operand::Register(register) = operand {
                    if register.class == RegisterClass::Scalar {
                        sources.extend(register.index..register.index + register.count);
                    }
                }
            }
        }
        for instruction in clause {
            if let Some(Operand::Register(destination)) = instruction.operands.first() {
                if destination.class == RegisterClass::Scalar {
                    if let Some(overlap) = (destination.index
                        ..destination.index + destination.count)
                        .find(|index| sources.contains(index))
                    {
                        return Err(EvalError::Unsupported {
                            pc: wave.pc,
                            what: format!(
                                "SMEM clause destination s{overlap} overlaps an address source; only an isolated single-DWORD load permits this alias"
                            ),
                        });
                    }
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
        let (_, writes) = self.instruction_registers(instruction, wave);
        self.builder.amd_event(
            wave.id,
            ProgramPoint(wave.pc as u32),
            AmdEventKind::MemoryIssue {
                class: AmdMemoryClass::CrossLane,
                counters: vec![(
                    if self.architecture == AmdArchitecture::Gfx1250 {
                        AmdCounter::Ds
                    } else {
                        AmdCounter::Lgkm
                    },
                    1,
                )],
                destinations: writes,
                held_sources: Vec::new(),
            },
        );
        let mut data = [Value::Bits(0); 64];
        let mut addresses = [0usize; 64];
        let lanes: Vec<_> = wave.active().collect();
        for &lane in &lanes {
            data[lane as usize] = wave.value(&o[2], lane)?;
            addresses[lane as usize] = ((wave.bits(&o[1], lane)? >> 2) & (wave.width - 1)) as usize;
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
        write: bool,
    ) -> Result<(), EvalError> {
        let valid = if lds {
            addr <= self.lds_size && width <= self.lds_size - addr
        } else {
            self.config.arrays.iter().any(|array| {
                width <= array.size_bytes()
                    && addr >= array.base
                    && addr - array.base <= array.size_bytes() - width
            }) || self.module_globals.values().any(|object| {
                addr >= object.base
                    && width <= object.size
                    && addr - object.base <= object.size - width
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
        if !lds
            && write
            && self.module_globals.values().any(|object| {
                object.read_only && addr >= object.base && addr - object.base < object.size
            })
        {
            return Err(wave.fail(Some(lane), "store to read-only module-global object"));
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
fn parse_i64(value: &str) -> Option<i64> {
    if let Some(value) = value.strip_prefix('-') {
        i64::try_from(parse_u64(value)?).ok()?.checked_neg()
    } else {
        i64::try_from(parse_u64(value)?).ok()
    }
}
fn selectors(
    instruction: &Instruction,
    name: &str,
    count: usize,
    default: u16,
) -> Option<Vec<u16>> {
    match instruction
        .modifiers
        .iter()
        .find(|modifier| modifier.name == name)
    {
        None => Some(vec![default; count]),
        Some(modifier) => {
            let value = modifier.value.as_deref()?;
            let values: Option<Vec<_>> = value
                .strip_prefix('[')?
                .strip_suffix(']')?
                .split(',')
                .map(|value| value.trim().parse::<u16>().ok().filter(|value| *value <= 1))
                .collect();
            values.filter(|values| values.len() == count)
        }
    }
}

fn canonical_alu(name: &str) -> &str {
    match name {
        "s_add_co_i32" => "s_add_i32",
        "s_addk_co_i32" => "s_addk_i32",
        "s_add_co_u32" => "s_add_u32",
        "s_add_co_ci_u32" => "s_addc_u32",
        "s_and_not1_b32" => "s_andn2_b32",
        "s_and_not1_saveexec_b32" => "s_andn2_saveexec_b32",
        "s_ctz_i32_b32" => "s_ff1_i32_b32",
        "v_add_nc_u32" => "v_add_u32",
        "v_sub_nc_u32" => "v_sub_u32",
        "v_subrev_nc_u32" => "v_subrev_u32",
        "v_sub_nc_u16" => "v_sub_u16",
        "v_max_num_f32" => "v_max_f32",
        "v_max_num_f16" => "v_max_f16",
        "v_max3_num_f16" => "v_max3_f16",
        "v_pk_max_num_f16" => "v_pk_max_f16",
        "v_min_num_f32" => "v_min_f32",
        "v_add_co_ci_u32" => "v_addc_co_u32",
        _ => name,
    }
}
