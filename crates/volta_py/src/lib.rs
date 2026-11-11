//! Python bindings for PTX and native AMD parsing, analysis and specification
//! verification, with file-based `solve` and `extract_lean` for PTX, AMD and NKI.
//! `prove_lean` and `check_lean_proof` support checking extracted Lean obligations.
//! Kernel comparison and expression/VC replay are exposed through `volta_cli`.

use pyo3::prelude::*;

mod analyze;
mod config;
mod error;
mod extract;
mod logging;
mod prove;
mod solve;
mod verify;

use config::{ArrayDefPy, ArrayKindPy, ConfigPy, ParamPy};
use error::{
    DataRaceError, DeadlockError, EarlyMemoryConflictError, EarlyReadinessError, TensorBoundsError,
    VoltaError,
};

#[pymodule]
fn volta(py: Python<'_>, m: &Bound<'_, PyModule>) -> PyResult<()> {
    logging::install();

    m.add_class::<ConfigPy>()?;
    m.add_class::<ArrayDefPy>()?;
    m.add_class::<ArrayKindPy>()?;
    m.add_class::<ParamPy>()?;
    m.add_class::<analyze::StatsPy>()?;
    m.add_class::<analyze::AnalyzeResultPy>()?;
    m.add_class::<verify::VerifyResultPy>()?;
    m.add_class::<solve::SolveResultPy>()?;
    m.add_class::<extract::LeanExtractionPy>()?;
    m.add_class::<prove::LeanCheckPy>()?;
    m.add_class::<prove::LeanProofPy>()?;

    m.add_function(wrap_pyfunction!(analyze::parse, m)?)?;
    m.add_function(wrap_pyfunction!(analyze::analyze, m)?)?;
    m.add_function(wrap_pyfunction!(verify::verify, m)?)?;
    m.add_function(wrap_pyfunction!(solve::solve, m)?)?;
    m.add_function(wrap_pyfunction!(extract::extract_lean, m)?)?;
    m.add_function(wrap_pyfunction!(prove::prove_lean, m)?)?;
    m.add_function(wrap_pyfunction!(prove::check_lean_proof, m)?)?;
    m.add_function(wrap_pyfunction!(prove::serve_lean_tools, m)?)?;
    m.add("DEFAULT_PROVE_MODEL", volta_lean::DEFAULT_MODEL)?;

    m.add("VoltaError", py.get_type::<VoltaError>())?;
    m.add("DataRaceError", py.get_type::<DataRaceError>())?;
    m.add(
        "EarlyMemoryConflictError",
        py.get_type::<EarlyMemoryConflictError>(),
    )?;
    m.add("EarlyReadinessError", py.get_type::<EarlyReadinessError>())?;
    m.add("TensorBoundsError", py.get_type::<TensorBoundsError>())?;
    m.add("DeadlockError", py.get_type::<DeadlockError>())?;

    Ok(())
}
