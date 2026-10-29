//! One candidate wave64 execution; semantic checking consumes its recorded graph.
mod float_bits;
mod interp;
mod matrix;
mod memory;
mod scalar;
mod value;
pub use interp::{EvalError, OutputsUnavailable, Stats, ThreadId};
pub(crate) use interp::{Interpreter, RunArtifacts};
pub(crate) fn interp_kind(opcode: crate::ir::Opcode) -> &'static str {
    use crate::ir::Opcode;
    match opcode {
        Opcode::ScalarAlu => "scalar ALU",
        Opcode::VectorAlu => "vector ALU",
        Opcode::ScalarMemory => "scalar memory",
        Opcode::VectorMemory => "vector memory",
        Opcode::Lds => "LDS",
        Opcode::Branch => "branch",
        Opcode::Wait => "wait",
        Opcode::Barrier => "barrier",
        Opcode::Matrix => "MFMA",
        Opcode::Control => "control",
    }
}
