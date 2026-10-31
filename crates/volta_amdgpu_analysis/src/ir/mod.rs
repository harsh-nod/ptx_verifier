//! Executable native AMD operations, value operands, source identity and module metadata.

mod instruction;
mod ops;
pub use crate::frontend::ast::{
    Global, Kernel, KernelArg, KernelDescriptor, Modifier, Module, Opcode, Register, RegisterClass,
    Relocation, RelocationKind, SourceSpan, SpecialRegister,
};
pub use instruction::*;
pub use ops::{AluOpcode, MatrixOpcode, MemoryOpcode};
use std::collections::BTreeMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GlobalAddressForm {
    SplitRel32,
    Rel64,
}

impl GlobalAddressForm {
    pub fn mnemonics(self) -> &'static [&'static str] {
        match self {
            Self::SplitRel32 => &["s_getpc_b64", "s_add_u32", "s_addc_u32"],
            Self::Rel64 => &["s_get_pc_i64", "s_add_nc_u64"],
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GlobalAddressSequence {
    pub anchor_pc: usize,
    pub register_pair: Register,
    pub symbol: String,
    pub form: GlobalAddressForm,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FunctionRange {
    pub name: String,
    pub start: usize,
    pub end: usize,
}
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeAddressSequence {
    pub anchor_pc: usize,
    pub register_pair: Register,
    pub target_pc: usize,
}

#[derive(Debug, Clone)]
pub struct LoweredKernel {
    pub name: String,
    pub instructions: Vec<Instruction>,
    pub descriptor: KernelDescriptor,
    pub args: Vec<KernelArg>,
    pub globals: Vec<Global>,
    /// Anchor-PC keyed exact native PC-relative constructions. Original
    /// instructions, PCs and register/SCC side effects remain present.
    pub global_address_sequences: BTreeMap<usize, GlobalAddressSequence>,
    /// Entry first, then the bounded transitive helper closure. No-call PCs stay unchanged.
    pub functions: Vec<FunctionRange>,
    pub code_address_sequences: BTreeMap<usize, CodeAddressSequence>,
    /// Each accepted direct call is tied to its reaching code-address definition.
    pub call_targets: BTreeMap<usize, usize>,
}
