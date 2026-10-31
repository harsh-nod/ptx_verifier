//! Python bindings for PTX and native AMD parsing, analysis and specification
//! verification through `parse`, `analyze` and `verify`. Kernel comparison and
//! expression/VC replay are exposed through `volta_cli`.

use pyo3::prelude::*;

mod analyze;
mod config;
mod error;
mod verify;

use config::{ArrayDefPy, ArrayKindPy, ConfigPy, ParamPy};
use error::{
    DataRaceError, DeadlockError, EarlyMemoryConflictError, EarlyReadinessError, TensorBoundsError,
    VoltaError,
};

#[pymodule]
fn volta(py: Python<'_>, m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_class::<ConfigPy>()?;
    m.add_class::<ArrayDefPy>()?;
    m.add_class::<ArrayKindPy>()?;
    m.add_class::<ParamPy>()?;
    m.add_class::<analyze::StatsPy>()?;
    m.add_class::<analyze::AnalyzeResultPy>()?;
    m.add_class::<verify::VerifyResultPy>()?;

    m.add_function(wrap_pyfunction!(analyze::parse, m)?)?;
    m.add_function(wrap_pyfunction!(analyze::analyze, m)?)?;
    m.add_function(wrap_pyfunction!(verify::verify, m)?)?;

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
