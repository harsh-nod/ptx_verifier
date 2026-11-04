//! Tensor-map types: the fields `tensormap.replace` writes (PTX ISA 9.7.9.27, Table 33),
//! named since the 128-byte object is opaque (5.5.8), and how `cp.async.bulk.tensor`
//! copies through a map (its `.load_mode`, an im2col map's box).

use crate::ir::Operand;

pub use volta_common::tensor_map::{
    Im2colBox, TensorElemType, TensorFillMode, TensorInterleaveLayout, TensorSwizzleAtomicity,
    TensorSwizzleMode,
};

/// A `cp.async.bulk.tensor` load's `.load_mode` (PTX ISA 5.5.3, 5.5.4).
#[derive(Debug, Clone, PartialEq)]
pub enum TensorLoadMode {
    /// `.tile`, the ISA's default: a box of the tensor
    Tile,
    /// `.im2col`: a pixel column; `offsets` (16-bit) shift the filter base's spatial
    /// coordinates, innermost (W) first like the tensor coordinates
    Im2col { offsets: Vec<Operand> },
}

/// One `tensormap.replace` field write, already decoded/validated at
/// lowering time (`.field3`/`ord` immediates are required by the ISA and
/// statically known there - see `lower::tma::lower_tensormap_replace`).
#[derive(Debug, Clone)]
pub enum TensormapFieldWrite {
    GlobalAddress(Operand),
    Rank(Operand),
    BoxDim { ord: u32, new_val: Operand },
    GlobalDim { ord: u32, new_val: Operand },
    GlobalStride { ord: u32, new_val: Operand },
    ElementStride { ord: u32, new_val: Operand },
    Elemtype(TensorElemType),
    InterleaveLayout(TensorInterleaveLayout),
    SwizzleMode(TensorSwizzleMode),
    SwizzleAtomicity(TensorSwizzleAtomicity),
    FillMode(TensorFillMode),
}
