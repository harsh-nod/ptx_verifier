//! Native gfx950 assembly frontend. Parsing preserves typed operands and source
//! locations; lowering resolves local control flow before symbolic execution.
//!
//! The accepted descriptor/metadata dialect is LLVM AMDHSA code-object 4–6,
//! metadata 1.0–1.2. Unknown semantic directives and opcodes are errors.

pub mod ast;
mod instr;
mod metadata;
mod parse;

pub use ast::*;
pub use parse::{ParseError, parse, parse_module};

#[cfg(test)]
mod tests;
