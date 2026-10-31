//! AMD kernel analysis for Volta.

pub mod frontend;

// Evaluator helpers are exercised by unit tests; the production API is parsing/lowering.
#[cfg(test)]
mod error;
#[cfg(test)]
mod eval;
mod ir;
mod lower;

pub use ir::{LoweredInstr, LoweredKernel, Sgpr, Vgpr};
pub use lower::{LowerError, lower_kernel};
