//! Python-facing mirror of `volta_ptx_analysis::AnalysisConfig`, wrapping the Rust
//! types 1:1 instead of the CLI's flat string mini-DSL
//! (`"in:0x10000:4:128:in"`).

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use volta_pipeline::Backend;

use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, SharedAllocation};

#[pyclass(name = "ArrayKind", eq, eq_int, from_py_object)]
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum ArrayKindPy {
    Input,
    Output,
    InputOutput,
    IndexInput,
}

impl From<ArrayKindPy> for ArrayKind {
    fn from(kind: ArrayKindPy) -> Self {
        match kind {
            ArrayKindPy::Input => ArrayKind::Input,
            ArrayKindPy::Output => ArrayKind::Output,
            ArrayKindPy::InputOutput => ArrayKind::InputOutput,
            ArrayKindPy::IndexInput => ArrayKind::IndexInput,
        }
    }
}

/// A value bound to a kernel parameter. Built via the static constructors
/// (`Param.int(5)`, `Param.array_ptr("A")`, ...) rather than exposed as a
/// Python-visible tagged union.
#[pyclass(name = "Param", from_py_object)]
#[derive(Clone)]
pub struct ParamPy(pub(crate) ParamValue);

#[pymethods]
impl ParamPy {
    #[staticmethod]
    fn int(value: i64) -> Self {
        ParamPy(ParamValue::Int(value))
    }

    #[staticmethod]
    fn float(value: f64) -> Self {
        ParamPy(ParamValue::Float(value))
    }

    #[staticmethod]
    fn sym_float(name: String) -> Self {
        ParamPy(ParamValue::SymFloat(name))
    }

    #[staticmethod]
    fn array_ptr(name: String) -> Self {
        ParamPy(ParamValue::ArrayPtr(name))
    }

    /// Exact native by-value ABI payload. PTX rejects this form.
    #[staticmethod]
    fn bytes(value: Vec<u8>) -> Self {
        ParamPy(ParamValue::Bytes(value))
    }

    fn __repr__(&self) -> String {
        format!("{:?}", self.0)
    }
}

#[pyclass(name = "ArrayDef", from_py_object)]
#[derive(Clone)]
pub struct ArrayDefPy(pub(crate) ArrayDef);

#[pymethods]
impl ArrayDefPy {
    #[new]
    fn new(name: String, base: u64, elem_width: u64, len: u64, kind: ArrayKindPy) -> Self {
        ArrayDefPy(ArrayDef {
            name,
            base,
            elem_width,
            len,
            kind: kind.into(),
        })
    }

    fn __repr__(&self) -> String {
        format!("{:?}", self.0)
    }
}

/// Full launch/memory configuration for analyzing one kernel; mirrors
/// `AnalysisConfig` field-for-field.
#[pyclass(name = "Config", from_py_object)]
#[derive(Clone)]
pub struct ConfigPy(pub(crate) AnalysisConfig, pub(crate) Backend);

#[pymethods]
impl ConfigPy {
    #[new]
    #[pyo3(signature = (block, grid=(1, 1, 1), dynamic_shared_bytes=0, max_instructions=2_000_000_000, *, backend="ptx", target=None))]
    fn new(
        block: (u32, u32, u32),
        grid: (u32, u32, u32),
        dynamic_shared_bytes: u64,
        max_instructions: u64,
        backend: &str,
        target: Option<&str>,
    ) -> PyResult<Self> {
        let mut config = AnalysisConfig::new(block);
        config.grid_dim = grid;
        config.dynamic_shared_bytes = dynamic_shared_bytes;
        config.max_instructions = max_instructions;
        let backend = Backend::select(backend, target).map_err(PyValueError::new_err)?;
        Ok(ConfigPy(config, backend))
    }

    #[getter]
    fn backend(&self) -> &'static str {
        self.1.name()
    }

    #[getter]
    fn target(&self) -> Option<&'static str> {
        self.1.target()
    }

    /// Declare a global-memory array visible to the kernel.
    fn add_array(&mut self, array: ArrayDefPy) {
        self.0.arrays.push(array.0);
    }

    /// Add an explicit native LDS source-allocation premise, in bytes.
    /// Empty layouts retain aggregate bounds; PTX rejects nonempty layouts.
    fn add_shared_allocation(&mut self, name: String, offset: u64, size: u64) -> PyResult<()> {
        let mut layout = self.0.shared_allocations.clone();
        layout.push(SharedAllocation { name, offset, size });
        // Validate transactionally so a rejected region cannot poison the config.
        let mut candidate = self.0.clone();
        candidate.shared_allocations = layout;
        candidate.validate().map_err(PyValueError::new_err)?;
        self.0.shared_allocations = candidate.shared_allocations;
        Ok(())
    }

    #[getter]
    fn shared_allocations(&self) -> Vec<(String, u64, u64)> {
        self.0
            .shared_allocations
            .iter()
            .map(|r| (r.name.clone(), r.offset, r.size))
            .collect()
    }

    /// Bind the next kernel parameter (in declaration order).
    fn add_param(&mut self, param: ParamPy) {
        self.0.params.push(param.0);
    }

    /// Set a module-scope `.global` variable's concrete value.
    fn set_global(&mut self, name: String, value: i64) {
        self.0.global_values.push((name, value));
    }

    fn __repr__(&self) -> String {
        format!("{:?}", self.0)
    }
}
