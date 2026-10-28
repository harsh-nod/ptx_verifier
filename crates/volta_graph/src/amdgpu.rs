//! Additive native AMD trace metadata. Checks interpret these records without borrowing
//! PTX synchronization certificates or treating trace order as memory completion.

use crate::{EventId, ThreadIx};

/// Architectures with an explicitly implemented native graph contract.
/// Target features remain in `Provenance::targets`; recognizing a target does
/// not imply that every instruction or execution mode is supported.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AmdArchitecture {
    Gfx942,
    Gfx950,
    Gfx1250,
}

impl AmdArchitecture {
    pub fn from_target(target: &str) -> Option<Self> {
        let mut fields = target.split(':');
        let architecture = match fields.next()? {
            "gfx942" => Self::Gfx942,
            "gfx950" => Self::Gfx950,
            "gfx1250" => Self::Gfx1250,
            _ => return None,
        };
        let (mut xnack, mut sramecc) = (false, false);
        for feature in fields {
            // gfx1250 XNACK is hardwired on, rather than a selectable mode.
            // Only the bare target is in the implemented feature envelope.
            if architecture == Self::Gfx1250 {
                return None;
            }
            let seen = match feature {
                "xnack+" | "xnack-" => &mut xnack,
                "sramecc+" | "sramecc-" => &mut sramecc,
                _ => return None,
            };
            if *seen {
                return None;
            }
            *seen = true;
        }
        Some(architecture)
    }

    pub fn from_targets(targets: &[String]) -> Option<Self> {
        if targets.len() != 1 {
            return None;
        }
        Self::from_target(&targets[0])
    }

    pub const fn name(self) -> &'static str {
        match self {
            Self::Gfx942 => "gfx942",
            Self::Gfx950 => "gfx950",
            Self::Gfx1250 => "gfx1250",
        }
    }

    pub const fn wave_size(self) -> u32 {
        match self {
            Self::Gfx942 | Self::Gfx950 => 64,
            Self::Gfx1250 => 32,
        }
    }

    pub const fn full_exec_mask(self) -> u64 {
        u64::MAX >> (64 - self.wave_size())
    }

    pub const fn lds_capacity(self) -> u64 {
        match self {
            Self::Gfx942 => 65_536,
            Self::Gfx950 => 163_840,
            // LLVM AMDGPU.td FeatureISAVersion12_50 at the public reference
            // 5fd50ec8e07abb94e203933017e8d6e40fb51824 selects 320 KiB LDS.
            Self::Gfx1250 => 327_680,
        }
    }

    /// This model's selected MFMA forms, not an exhaustive ISA inventory.
    /// CDNA4's doubled-K and f8f6f4/scale forms must not become CDNA3
    /// instructions merely by changing a graph's target string.
    pub fn supports_matrix(self, kind: AmdMatrixKind) -> bool {
        self == Self::Gfx950
            || self == Self::Gfx942
                && matches!(
                    kind,
                    AmdMatrixKind::F32_16x16x4
                        | AmdMatrixKind::F32_32x32x2
                        | AmdMatrixKind::F16_16x16x16
                        | AmdMatrixKind::F16_32x32x8
                        | AmdMatrixKind::Bf16_16x16x16
                        | AmdMatrixKind::Bf16_32x32x8
                )
    }
}

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
/// VCC low/high use scalar106/107; EXEC low/high use scalar126/127.
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
        /// Scalar reads serving only as carry-in/condition masks, rather than
        /// ordinary scalar data. This is a validated subset of `reads`.
        scalar_mask_reads: Vec<AmdRegister>,
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

/// Native visibility policy of an ordinary AMD memory effect.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum AmdMemoryScope {
    #[default]
    Unspecified,
    /// Native GLOBAL SC0=1, SC1=0. Visibility additionally requires a recorded
    /// single-CU workgroup premise; scope does not create memory ordering.
    Workgroup,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Associates an ordinary memory event with its issuing AMD instruction. Its
/// lane attribution and this association retain asynchronous completion.
pub struct AmdMemoryEffect {
    pub issue: EventId,
    pub effect: EventId,
    pub scope: AmdMemoryScope,
}

pub fn amd_wave_thread(wave: u32) -> ThreadIx {
    ThreadIx(wave * 64)
}

/// First physical thread of a wave for an explicitly selected native target.
/// The original `amd_wave_thread` retains its wave64 meaning for old callers.
pub fn amd_wave_thread_for(architecture: AmdArchitecture, wave: u32) -> ThreadIx {
    ThreadIx(wave.saturating_mul(architecture.wave_size()))
}

#[cfg(test)]
mod architecture_tests {
    use super::*;

    #[test]
    fn targets_retain_architecture_and_reject_conflicting_or_unknown_features() {
        for (target, expected) in [
            ("gfx942", Some(AmdArchitecture::Gfx942)),
            ("gfx942:sramecc+:xnack-", Some(AmdArchitecture::Gfx942)),
            ("gfx950:xnack+:sramecc-", Some(AmdArchitecture::Gfx950)),
            ("gfx1250", Some(AmdArchitecture::Gfx1250)),
            ("gfx1250:xnack-", None),
            ("gfx1250:xnack+", None),
            ("gfx1250-strict", None),
            ("gfx1251", None),
            ("gfx942:xnack+:xnack-", None),
            ("gfx942:sramecc+:sramecc+", None),
            ("gfx942:wave32", None),
            ("gfx942:", None),
            ("gfx941", None),
            ("sm_100a", None),
        ] {
            assert_eq!(AmdArchitecture::from_target(target), expected, "{target}");
        }
        assert_eq!(AmdArchitecture::from_targets(&[]), None);
        assert_eq!(
            AmdArchitecture::from_targets(&["gfx942".into(), "gfx950".into()]),
            None
        );
        assert_eq!(AmdArchitecture::Gfx942.lds_capacity(), 65_536);
        assert_eq!(AmdArchitecture::Gfx950.lds_capacity(), 163_840);
        assert_eq!(AmdArchitecture::Gfx1250.lds_capacity(), 327_680);
        for architecture in [
            AmdArchitecture::Gfx942,
            AmdArchitecture::Gfx950,
            AmdArchitecture::Gfx1250,
        ] {
            let size = architecture.wave_size();
            assert_eq!(
                size,
                if architecture == AmdArchitecture::Gfx1250 {
                    32
                } else {
                    64
                }
            );
            assert_eq!(amd_wave_thread_for(architecture, 3), ThreadIx(3 * size));
            assert_eq!(architecture.full_exec_mask().count_ones(), size);
            assert!(!AmdArchitecture::Gfx1250.supports_matrix(AmdMatrixKind::F32_16x16x4));
        }
        assert!(AmdArchitecture::Gfx942.supports_matrix(AmdMatrixKind::F16_16x16x16));
        for kind in [
            AmdMatrixKind::F16_16x16x32,
            AmdMatrixKind::Bf16_32x32x16,
            AmdMatrixKind::Fp8_16x16x128,
            AmdMatrixKind::Fp8Scale_32x32x64,
        ] {
            assert!(!AmdArchitecture::Gfx942.supports_matrix(kind));
            assert!(AmdArchitecture::Gfx950.supports_matrix(kind));
        }
    }
}
