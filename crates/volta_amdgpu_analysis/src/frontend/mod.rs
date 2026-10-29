//! Native gfx942/gfx950/gfx1250 assembly frontend. Parsing preserves typed operands and source
//! locations; lowering resolves local control flow before symbolic execution.
//!
//! The accepted descriptor/metadata dialect is LLVM AMDHSA code-object 4–6,
//! metadata 1.0–1.2. Unknown semantic directives and entry opcodes are errors.
//! Descriptors and metadata identify entry kernels. Explicit `.type ...,@function`
//! bodies with matching `.size` that are not entries are excluded from the module;
//! their instructions are not analyzed. Entry instructions remain strict even on
//! unreachable paths. Calls and computed jumps are unsupported, and lowering
//! rejects branches outside the selected kernel. With no entry declarations,
//! all handwritten function bodies are parsed strictly.

pub mod ast;
pub(crate) mod gfx1250;
mod instr;
mod metadata;
mod parse;

pub use ast::*;
pub use parse::{ParseError, parse, parse_module};

#[cfg(test)]
mod tests;
