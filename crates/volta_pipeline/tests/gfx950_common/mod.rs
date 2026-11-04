//! Native AMD analysis/checking with the same optional run store as `just viz`.
//! Include this module in a native integration test and call `check` after parsing.

use std::{cell::Cell, num::NonZeroU32, path::Path};
use volta_amdgpu_analysis::{AnalysisConfig, AnalysisError, AnalysisResult, analyze, frontend};
use volta_graph::AbortCause;
use volta_graph_check::{GraphReport, check_graph};
use volta_viz::{Outcome, Run, RunId, write_run};

pub struct Checked {
    pub analysis: AnalysisResult,
    pub checks: GraphReport,
}

/// Analyze and check a native module, recording both complete and aborted runs
/// whenever `VOLTA_VIZ_DIR` is set. Execution failures retain their typed error
/// in `analysis.symbolic_outputs()` and their partial graph in the viewer.
pub fn check(
    source: &str,
    module: &frontend::Module,
    kernel: Option<&str>,
    config: AnalysisConfig,
) -> Result<Checked, AnalysisError> {
    let result = analyze(module, kernel, config).map(|analysis| {
        let checks = check_graph(&analysis.graph);
        Checked { analysis, checks }
    });
    let outcome = match &result {
        Ok(checked) => Outcome::Executed {
            graph: &checked.analysis.graph,
            arena: checked.analysis.arena(),
            report: Some(&checked.checks),
        },
        Err(error) => Outcome::NotStarted {
            cause: match error {
                AnalysisError::Lower(_) => AbortCause::Unsupported,
                AnalysisError::KernelNotFound { .. } | AnalysisError::Eval(_) => AbortCause::Error,
            },
            error: error.to_string(),
        },
    };
    record(source, outcome);
    result
}

fn record(source: &str, outcome: Outcome<'_>) {
    let Some(dir) = std::env::var_os("VOLTA_VIZ_DIR") else {
        return;
    };
    thread_local! {
        static RUNS: Cell<u32> = const { Cell::new(0) };
    }
    let ordinal = RUNS.with(|runs| {
        runs.set(runs.get() + 1);
        runs.get()
    });
    let id = RunId {
        suite: env!("CARGO_CRATE_NAME").into(),
        test: std::thread::current().name().unwrap_or("unnamed").into(),
        ordinal: NonZeroU32::new(ordinal).expect("the count starts at 1"),
    };
    let run = Run {
        id: &id,
        ptx_file: None,
        source,
        outcome,
    };
    let dir = Path::new(&dir);
    write_run(dir, &run).unwrap_or_else(|error| panic!("record into {}: {error}", dir.display()));
}
