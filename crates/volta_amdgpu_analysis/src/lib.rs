//! Native gfx942/gfx950/gfx1250 assembly analysis using the existing expression and event artifacts.
//!
//! [`frontend::parse`] validates compiler-module directives, metadata and globals,
//! then parses every descriptor/metadata entry body. Explicitly declared and
//! bounded non-entry functions are excluded. Calls and computed jumps in entries
//! remain unsupported; [`lower::lower_module_kernel`] resolves branches only
//! within the chosen kernel. Modules without entry declarations retain strict
//! parsing of all handwritten function bodies.
mod analysis;
mod config;
mod eval;
pub mod frontend;
pub mod ir;
pub mod lower;
pub mod target;

pub use analysis::{
    AnalysisError, AnalysisParts, AnalysisResult, analyze, analyze_with_observer, write_op_counts,
};
pub use config::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, SharedAllocation};
pub use eval::{
    EvalError, InstructionObserver, OBSERVER_STOP_REASON, OutputsUnavailable, Stats, ThreadId,
};
