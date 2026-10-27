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
    ScalarMemory,
    Lds,
    Flat,
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
pub enum AmdMatrixKind {
    F32_16x16x4,
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
    /// completion; held sources cannot be overwritten until the operation releases them.
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
