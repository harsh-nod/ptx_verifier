use std::collections::BTreeMap;

use pyo3::exceptions::PyRuntimeWarning;
use pyo3::prelude::*;
use pyo3::types::PyList;

use volta_expr::SymbolicOutputs;
use volta_graph_check::GraphConclusion;
use volta_pipeline::{Backend, KernelModule, verify_source_kernel};
use volta_ptx_analysis::frontend::ascii::{AsAscii, AsciiChar};
use volta_ptx_analysis::frontend::ast::Module;
use volta_ptx_analysis::frontend::parse as ptx_parse;
use volta_ptx_analysis::{AnalysisConfig, Stats};

use crate::config::ConfigPy;
use crate::error::{EarlyReadinessError, VoltaError, graph_failure_to_py, parse_error_to_py};

pub(crate) fn parse_module(source: &str, backend: Backend) -> PyResult<KernelModule> {
    match backend {
        Backend::Ptx => parse_ptx_module(source).map(KernelModule::Ptx),
        Backend::Amdgpu | Backend::AmdgpuGfx942 | Backend::AmdgpuGfx1250 => {
            let module = volta_amdgpu_analysis::frontend::parse(source)
                .map_err(|error| VoltaError::new_err(error.to_string()))?;
            backend
                .validate_amd_target(module.target.as_deref())
                .map_err(VoltaError::new_err)?;
            Ok(KernelModule::Amdgpu(module))
        }
    }
}

fn parse_ptx_module(source: &str) -> PyResult<Module> {
    let ascii_src: &[AsciiChar] = source
        .as_bytes()
        .as_ascii_slice()
        .ok_or_else(|| VoltaError::new_err("source contains non-ASCII characters"))?;
    let mut parser = ptx_parse::Parser::new(ascii_src);
    parser
        .parse_module()
        .map_err(|e| parse_error_to_py(source, &e))
}

/// Parse source for the selected PTX or native AMD backend; raise `VoltaError` on a syntax error.
#[pyfunction]
#[pyo3(signature = (source, *, backend="ptx", target=None))]
pub fn parse(source: &str, backend: &str, target: Option<&str>) -> PyResult<()> {
    let backend = Backend::select(backend, target).map_err(VoltaError::new_err)?;
    parse_module(source, backend)?;
    Ok(())
}

#[pyclass(name = "Stats", from_py_object)]
#[derive(Clone)]
pub struct StatsPy {
    #[pyo3(get)]
    pub instructions: u64,
    #[pyo3(get)]
    pub block_syncs: u64,
    #[pyo3(get)]
    pub warp_syncs: u64,
}

/// The result of symbolically executing one kernel: per-output-array written
/// elements (pretty-printed; the arena is not exposed) plus statistics.
#[pyclass(name = "AnalyzeResult")]
pub struct AnalyzeResultPy {
    #[pyo3(get)]
    pub stats: StatsPy,
    // Retain the compact DAG, rather than a second complete copy of every
    // expanded expression string. The getter still returns ordinary Python
    // lists/tuples/strings and never exposes arena handles.
    exprs: SymbolicOutputs,
    #[pyo3(get)]
    pub op_counts: BTreeMap<String, u64>,
    /// Whether graph verification is complete: the trace completed and the graph checks
    /// (barrier epochs, mbarrier ordering, memory conflicts, proxy and tensor ordering, resource
    /// lifetime, allocation order and permit, mbarrier release order) all passed. A failed check
    /// or a deadlock raises instead. For AMD this covers only `workgroup_id`,
    /// including when `grid` is larger.
    #[pyo3(get)]
    pub race_verified: bool,
    /// Why verification is incomplete; empty when `race_verified`.
    #[pyo3(get)]
    pub unresolved: Vec<String>,
    /// Native AMD checks cover only this workgroup, not other groups or their conflicts.
    #[pyo3(get)]
    pub workgroup_id: (u32, u32, u32),
    /// Modeling assumptions of the execution whose outputs are returned.
    #[pyo3(get)]
    pub assumptions: Vec<String>,
}

#[pymethods]
impl AnalyzeResultPy {
    /// `[(array_name, [(index, pretty_printed_expr), ...]), ...]`
    #[getter]
    fn outputs<'py>(&self, py: Python<'py>) -> PyResult<Bound<'py, PyList>> {
        let outputs = PyList::empty(py);
        for (name, elements) in &self.exprs.outputs {
            let values = PyList::empty(py);
            for (index, expr) in elements {
                // Convert each string directly into its Python result. A
                // whole Rust Vec<String> would retain or clone hundreds of
                // GiB for original-size attention results before conversion.
                values.append((*index, self.exprs.arena.display_expr(*expr)))?;
            }
            outputs.append((name, values))?;
        }
        Ok(outputs)
    }
}

/// One kernel that ran to completion with no failed graph check.
pub(crate) struct CheckedKernel {
    pub workgroup_id: (u32, u32, u32),
    pub assumptions: Vec<String>,
    pub exprs: SymbolicOutputs,
    pub stats: Stats,
    pub op_counts: BTreeMap<&'static str, u64>,
    /// Why graph verification is incomplete; empty when it is verified.
    pub unresolved: Vec<String>,
}

/// Run the analysis stage and the graph branch. A failed graph check or a deadlock raises (see
/// `graph_failure_to_py`), before an execution that produced no outputs raises `VoltaError`;
/// incomplete verification emits a `RuntimeWarning`, so a returned result never silently
/// stands for a race-freedom proof.
pub(crate) fn check_kernel(
    py: Python<'_>,
    module: &KernelModule,
    kernel: Option<&str>,
    config: AnalysisConfig,
) -> PyResult<CheckedKernel> {
    let verified = verify_source_kernel(module, kernel, config).map_err(VoltaError::new_err)?;
    if let Some(finding) = &verified.early_readiness {
        let hazard = finding.hazard();
        let exception = EarlyReadinessError::new_err(format!(
            "certified scalar readiness prefix rejection: {hazard:?}; first finding only; complete outputs and equivalence unavailable"
        ));
        let value = exception.value(py);
        value.setattr("issue_event", hazard.issue.0)?;
        value.setattr("use_event", hazard.use_event.0)?;
        value.setattr("wave", hazard.wave)?;
        value.setattr("register_index", hazard.register.index)?;
        value.setattr("register_file", format!("{:?}", hazard.register.file))?;
        value.setattr("instructions", verified.analysis.stats.instructions)?;
        value.setattr("prefix_amd_records", finding.certificate().amd_records)?;
        value.setattr("prefix_graph_events", finding.certificate().graph_events)?;
        return Err(exception);
    }
    let unresolved = match verified.graph.conclusion() {
        GraphConclusion::Rejected { failed, deadlock } => {
            return Err(graph_failure_to_py(&failed, deadlock.as_ref()));
        }
        GraphConclusion::Verified => Vec::new(),
        GraphConclusion::Unknown { reasons } => {
            let message = format!(
                "graph verification is UNKNOWN, race freedom is not established: {}",
                reasons.join("; ")
            );
            let message = std::ffi::CString::new(message.replace('\0', " "))
                .expect("NUL bytes were replaced");
            PyErr::warn(py, &py.get_type::<PyRuntimeWarning>(), &message, 1)?;
            reasons
        }
    };
    let parts = verified.analysis;
    let provenance = parts.graph.provenance();
    let workgroup_id = provenance.workgroup_id;
    let assumptions = provenance
        .assumptions
        .iter()
        .map(|a| a.describe().to_owned())
        .collect();
    let exprs = parts
        .outputs
        .map_err(|why| VoltaError::new_err(why.to_string()))?;
    Ok(CheckedKernel {
        workgroup_id,
        assumptions,
        exprs,
        stats: parts.stats,
        op_counts: parts.op_counts,
        unresolved,
    })
}

/// Symbolically execute `kernel` (or the module's unique entry) under
/// `config`. Raises `DataRaceError` / `DeadlockError` for those findings and
/// `VoltaError` for any other analysis failure.
#[pyfunction]
#[pyo3(signature = (source, config, kernel=None))]
pub fn analyze(
    py: Python<'_>,
    source: &str,
    config: &ConfigPy,
    kernel: Option<&str>,
) -> PyResult<AnalyzeResultPy> {
    let module = parse_module(source, config.1)?;
    let output = check_kernel(py, &module, kernel, config.0.clone())?;

    Ok(AnalyzeResultPy {
        workgroup_id: output.workgroup_id,
        assumptions: output.assumptions,
        stats: StatsPy {
            instructions: output.stats.instructions,
            block_syncs: output.stats.block_syncs,
            warp_syncs: output.stats.warp_syncs,
        },
        exprs: output.exprs,
        op_counts: output
            .op_counts
            .iter()
            .map(|(k, v)| (k.to_string(), *v))
            .collect(),
        race_verified: output.unresolved.is_empty(),
        unresolved: output.unresolved,
    })
}
