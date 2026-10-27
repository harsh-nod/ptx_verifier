//! Lowered native gfx950 program; syntax types remain owned by the frontend.

pub use crate::frontend::ast::*;

#[derive(Debug, Clone)]
pub struct LoweredKernel {
    pub name: String,
    pub instructions: Vec<Instruction>,
    pub descriptor: KernelDescriptor,
    pub args: Vec<KernelArg>,
}
