//! Lowered native gfx950 program; syntax types remain owned by the frontend.

pub use crate::frontend::ast::*;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GlobalAddressSequence {
    pub anchor_pc: usize,
    pub register_pair: Register,
    pub symbol: String,
}

#[derive(Debug, Clone)]
pub struct LoweredKernel {
    pub name: String,
    pub instructions: Vec<Instruction>,
    pub descriptor: KernelDescriptor,
    pub args: Vec<KernelArg>,
    pub globals: Vec<Global>,
    /// Anchor-PC keyed exact getpc/add-low/add-high constructions. Original
    /// instructions, PCs and register/SCC side effects remain present.
    pub global_address_sequences: BTreeMap<usize, GlobalAddressSequence>,
}
