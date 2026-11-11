//! `volta.extract_lean`: graph checks first, then (optionally) the canonical equivalence
//! check against the spec, then Lean proof obligations, all over one run of the kernel.

use std::collections::HashMap;
use std::path::PathBuf;

use pyo3::prelude::*;
use volta_equivalence::EquivCheckOptions;
use volta_pipeline::{LeanExtractionError, Solver};

use crate::config::ConfigPy;
use crate::error::{certified_prefix_to_py, graph_failure_to_py, other_error_to_py};
use crate::solve::{interpreter_name, load_kernel, parse_spec, provenance, race_verified};

#[pyclass(name = "LeanExtraction")]
pub struct LeanExtractionPy {
    #[pyo3(get)]
    pub isa: String,
    /// True when graph checks passed; None for an ISA without graph checks.
    #[pyo3(get)]
    pub race_verified: Option<bool>,
    /// The canonical solver's `"ACCEPT"`, `"REJECT"` or `"UNKNOWN"` for exact equality with the
    /// spec; None unless `equivalence=True` asked for it.
    #[pyo3(get)]
    pub verdict: Option<String>,
    /// What that verdict rests on, its witnesses or what is missing.
    #[pyo3(get)]
    pub evidence: Vec<String>,
    /// A Lean module of proof obligations, not completed proofs.
    #[pyo3(get)]
    pub lean: String,
    #[pyo3(get)]
    pub statements: usize,
    #[pyo3(get)]
    pub workgroup_id: Option<(u32, u32, u32)>,
    #[pyo3(get)]
    pub assumptions: Vec<String>,
}

/// Extract Lean proof obligations for a kernel against `spec`. `tolerance` is an optional
/// absolute error bound such as "1/1000"; without it, propositions state exact equality.
/// `equivalence=True` also checks exact equality with the canonical solver.
/// Native AMD requires completed target-specific graph checks; extension-inferred AMD
/// checks LDS only, while NKI returns race_verified=None. Graph failures raise typed errors.
#[pyfunction]
#[pyo3(signature = (
    path, config=None, *, spec, kernel=None, dims=None, tolerance=None, equivalence=false
))]
#[allow(clippy::too_many_arguments)]
pub fn extract_lean(
    py: Python<'_>,
    path: PathBuf,
    config: Option<&ConfigPy>,
    spec: &str,
    kernel: Option<&str>,
    dims: Option<HashMap<String, u64>>,
    tolerance: Option<&str>,
    equivalence: bool,
) -> PyResult<LeanExtractionPy> {
    let spec = parse_spec(spec, dims)?;
    let (isa, mut run) = load_kernel(&path, config, kernel)?;
    if let Some(native) = &run.native
        && let Some(error) = certified_prefix_to_py(
            py,
            native.stats.instructions,
            native.early_readiness.as_ref(),
            native.early_memory_conflict.as_ref(),
            native.tensor_bounds.as_ref(),
        )?
    {
        return Err(error);
    }
    let (verdict, evidence) = if equivalence {
        let solver = Solver::Canonical(EquivCheckOptions::default());
        let solution = run.solve(&spec, &solver).map_err(other_error_to_py)?;
        let decision = run.decide(&solution);
        (Some(decision.verdict.name().to_string()), decision.evidence)
    } else {
        (None, Vec::new())
    };
    let challenge = run.extract_lean(&spec, tolerance).map_err(|e| match e {
        LeanExtractionError::Rejected { failed, deadlock } => {
            graph_failure_to_py(&failed, deadlock.as_ref())
        }
        other => other_error_to_py(other),
    })?;
    let (workgroup_id, assumptions) = provenance(&run);
    Ok(LeanExtractionPy {
        isa: interpreter_name(isa, config),
        workgroup_id,
        assumptions,
        race_verified: race_verified(&run),
        verdict,
        evidence,
        lean: challenge.module,
        statements: challenge.statements,
    })
}
