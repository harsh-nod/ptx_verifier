//! Additive gfx950 trace metadata. AMD checks interpret these records without borrowing
//! PTX synchronization certificates or treating trace order as memory completion.

use crate::{EventId, ThreadIx};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum AmdCounter {
    Vm,
    Lgkm,
    Exp,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AmdMemoryClass {
    VectorMemory,
    VectorStoreWide,
    ScalarMemory,
    Lds,
    Flat,
    FlatStoreWide,
    Message,
    CrossLane,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AmdRegisterFile {
    Scalar,
    Vector,
    Accumulator,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[allow(non_camel_case_types)] // Match the ISA's matrix dimensions and data-type names.
pub enum AmdMatrixKind {
    F32_16x16x4,
    F32_32x32x2,
    F16_16x16x16,
    F16_32x32x8,
    F16_16x16x32,
    F16_32x32x16,
    Bf16_16x16x16,
    Bf16_32x32x8,
    Bf16_16x16x32,
    Bf16_32x32x16,
    Fp8_16x16x128,
    Fp8_32x32x64,
    Fp8Scale_16x16x128,
    Fp8Scale_32x32x64,
}

impl AmdMatrixKind {
    pub fn destination_registers(self) -> usize {
        match self {
            Self::F32_32x32x2
            | Self::F16_32x32x8
            | Self::F16_32x32x16
            | Self::Bf16_32x32x8
            | Self::Bf16_32x32x16
            | Self::Fp8_32x32x64
            | Self::Fp8Scale_32x32x64 => 16,
            _ => 4,
        }
    }
    pub fn input_registers(self) -> usize {
        match self {
            Self::F32_16x16x4 | Self::F32_32x32x2 => 1,
            Self::F16_16x16x16 | Self::F16_32x32x8 | Self::Bf16_16x16x16 | Self::Bf16_32x32x8 => 2,
            Self::F16_16x16x32 | Self::F16_32x32x16 | Self::Bf16_16x16x32 | Self::Bf16_32x32x16 => {
                4
            }
            _ => 8,
        }
    }
    pub fn scale_registers(self) -> usize {
        if matches!(self, Self::Fp8Scale_16x16x128 | Self::Fp8Scale_32x32x64) {
            2
        } else {
            0
        }
    }
    pub fn passes(self) -> u64 {
        match self {
            Self::F32_32x32x2 | Self::Fp8_32x32x64 | Self::Fp8Scale_32x32x64 => 16,
            Self::F16_16x16x16 | Self::F16_16x16x32 | Self::Bf16_16x16x16 | Self::Bf16_16x16x32 => {
                4
            }
            _ => 8,
        }
    }
    pub fn is_xdl(self) -> bool {
        !matches!(self, Self::F32_16x16x4 | Self::F32_32x32x2)
    }
}

/// One 32-bit register, restricted to a lane mask for vector/accumulator registers.
/// A register pair/range is represented by one entry per register. Scalar masks are ignored.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct AmdRegister {
    pub file: AmdRegisterFile,
    pub index: u16,
    pub lanes: u64,
}

impl AmdRegister {
    pub fn overlaps(self, other: Self) -> bool {
        self.file == other.file
            && self.index == other.index
            && (self.file == AmdRegisterFile::Scalar || self.lanes & other.lanes != 0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AmdEventKind {
    /// A supported MFMA form, with operand roles retained for forwarding checks.
    MatrixIssue {
        kind: AmdMatrixKind,
        destinations: Vec<AmdRegister>,
        sources_ab: Vec<AmdRegister>,
        accumulator: Vec<AmdRegister>,
    },
    /// S_NOP's encoded immediate plus one (1..16 independent wait states).
    Delay {
        cycles: u16,
    },
    /// Every executed instruction, including scalar instructions with EXEC=0.
    Instruction {
        exec_mask: u64,
        reads: Vec<AmdRegister>,
        writes: Vec<AmdRegister>,
    },
    /// One issued instruction, not one lane. SMEM charges 1 for dword and 2 for wider
    /// transfers. FLAT charges both VM and LGKM. Destinations remain unavailable until
    /// completion. Wide-store held sources use Table 11's independent-state rules;
    /// other explicitly held sources remain held until operation completion.
    MemoryIssue {
        class: AmdMemoryClass,
        counters: Vec<(AmdCounter, u16)>,
        destinations: Vec<AmdRegister>,
        held_sources: Vec<AmdRegister>,
    },
    Wait {
        vmcnt: Option<u16>,
        lgkmcnt: Option<u16>,
        expcnt: Option<u16>,
    },
    /// One arrival per live wave. The mask is recorded for diagnostics, not a requirement
    /// that EXEC be all ones: S_BARRIER is a scalar instruction.
    BarrierArrive {
        generation: u32,
        exec_mask: u64,
    },
    BarrierRelease {
        generation: u32,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AmdEvent {
    pub event: EventId,
    pub wave: u32,
    pub kind: AmdEventKind,
}

/// Associates an ordinary graph memory event with the AMD instruction that issues it.
/// Its thread attribution identifies the lane; this association makes it pending rather
/// than a synchronous memory effect in AMD's ordering model.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AmdMemoryEffect {
    pub issue: EventId,
    pub effect: EventId,
}

pub fn amd_wave_thread(wave: u32) -> ThreadIx {
    ThreadIx(wave * 64)
}
