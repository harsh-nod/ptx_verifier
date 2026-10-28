//! Native gfx950 assembly analysis, producing the existing expression and event artifacts.
mod analysis;
mod config;
mod eval;
pub mod frontend;
pub mod ir;
pub mod lower;

pub use analysis::{AnalysisError, AnalysisParts, AnalysisResult, analyze, write_op_counts};
pub use config::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, SharedAllocation};
pub use eval::{EvalError, OutputsUnavailable, Stats, ThreadId};
