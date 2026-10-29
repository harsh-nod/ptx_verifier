//! Complete dense specification footprints, checked before output sampling.

use crate::{OutputSpec, SpecError};
use std::collections::HashSet;
use std::fmt;
use volta_expr::SymbolicOutputs;

#[derive(Debug, PartialEq, Eq)]
pub struct OutputIndexMismatch {
    pub array: String,
    pub unwritten: Vec<u64>,
    pub unexpected: Vec<u64>,
}

impl fmt::Display for OutputIndexMismatch {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "output '{}' index set mismatch: {} unwritten and {} unexpected indices",
            self.array,
            self.unwritten.len(),
            self.unexpected.len()
        )
    }
}

/// Compare the complete kernel-written indices with each dense spec output.
/// Sampling may limit expression construction/comparison only after this check.
pub fn output_index_mismatch(
    outputs: &SymbolicOutputs,
    specs: &[OutputSpec],
) -> Result<Option<OutputIndexMismatch>, SpecError> {
    let mut names = HashSet::new();
    for spec in specs {
        if !names.insert(&spec.array) {
            return Err(SpecError::DuplicateOutput(spec.array.clone()));
        }
        let expected = spec
            .shape
            .checked_size()
            .ok_or_else(|| SpecError::ShapeOverflow {
                array: spec.array.clone(),
                shape: spec.shape.dims().to_vec(),
            })?;
        let written: Vec<u64> = outputs
            .outputs
            .iter()
            .find(|(name, _)| name == &spec.array)
            .map_or_else(Vec::new, |(_, elems)| {
                elems.iter().map(|&(index, _)| index).collect()
            });
        let unwritten: Vec<u64> = (0..expected)
            .filter(|index| written.binary_search(index).is_err())
            .collect();
        let unexpected: Vec<u64> = written
            .iter()
            .copied()
            .filter(|&index| index >= expected)
            .collect();
        if !unwritten.is_empty() || !unexpected.is_empty() {
            return Ok(Some(OutputIndexMismatch {
                array: spec.array.clone(),
                unwritten,
                unexpected,
            }));
        }
    }
    Ok(None)
}
