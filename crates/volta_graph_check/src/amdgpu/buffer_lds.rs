//! Selected CDNA4 raw MUBUF-to-LDS transfer contracts, not descriptor decoding.
//! Concrete addresses and successful complete batches remain producer premises.

use std::collections::{HashMap, HashSet};

use volta_graph::{
    AccessMode, AmdArchitecture, AmdEvent, AmdMemoryClass, AmdMemoryEffect, AmdMemoryScope,
    AmdRegister, AmdRegisterFile, Assumption, EventGraph, EventId, EventKind, ExecContext,
    Footprint, OperandRole, OrderingKind, Proxy, Space,
};

use super::InstructionRecord;
use crate::Unresolved;

pub(super) fn width(class: AmdMemoryClass) -> Option<u64> {
    match class {
        AmdMemoryClass::BufferLoadToLds32 => Some(4),
        AmdMemoryClass::BufferLoadToLds128 => Some(16),
        _ => None,
    }
}

struct Transfer {
    wave: u32,
    mask: u64,
    width: u64,
    effects: Vec<AmdMemoryEffect>,
}

pub(super) struct Trace {
    architecture: AmdArchitecture,
    initialized_m0: HashSet<u32>,
    transfers: HashMap<EventId, Transfer>,
}

impl Trace {
    pub(super) fn new(architecture: AmdArchitecture) -> Self {
        Self {
            architecture,
            initialized_m0: HashSet::new(),
            transfers: HashMap::new(),
        }
    }

    pub(super) fn instruction(
        &mut self,
        record: &AmdEvent,
        kind: Option<&str>,
        mask: u64,
        reads: &[AmdRegister],
        writes: &[AmdRegister],
        unresolved: &mut Vec<Unresolved>,
    ) {
        let m0 = |r: &AmdRegister| r.file == AmdRegisterFile::Scalar && r.index == 124;
        if reads.iter().any(m0)
            && (self.architecture != AmdArchitecture::Gfx950
                || kind != Some("vector memory")
                || mask == 0
                || !self.initialized_m0.contains(&record.wave))
        {
            unresolved.push(Unresolved::at(
                record.event,
                "legacy M0 read requires an initialized gfx950 LDS DMA source",
            ));
        }
        if writes.iter().any(m0) {
            if self.architecture != AmdArchitecture::Gfx950 || kind != Some("scalar ALU") {
                unresolved.push(Unresolved::at(
                    record.event,
                    "selected legacy M0 initialization requires a gfx950 scalar ALU instruction",
                ));
            }
            self.initialized_m0.insert(record.wave);
        }
    }

    #[expect(
        clippy::too_many_arguments,
        reason = "checks the complete existing memory-issue record against its instruction"
    )]
    pub(super) fn issue(
        &mut self,
        graph: &EventGraph,
        record: &AmdEvent,
        instruction: &InstructionRecord,
        class: AmdMemoryClass,
        destinations: &[AmdRegister],
        held_sources: &[AmdRegister],
        unresolved: &mut Vec<Unresolved>,
    ) {
        let Some(width) = width(class) else {
            if instruction
                .reads
                .iter()
                .any(|r| r.file == AmdRegisterFile::Scalar && r.index == 124)
            {
                unresolved.push(Unresolved::at(
                    record.event,
                    "M0 memory source requires the selected gfx950 buffer-to-LDS class",
                ));
            }
            return;
        };
        let mut scalars: Vec<_> = instruction
            .reads
            .iter()
            .filter(|r| r.file == AmdRegisterFile::Scalar && r.index != 124)
            .collect();
        scalars.sort_unstable_by_key(|r| r.index);
        let vectors: Vec<_> = instruction
            .reads
            .iter()
            .filter(|r| r.file == AmdRegisterFile::Vector)
            .collect();
        let m0: Vec<_> = instruction
            .reads
            .iter()
            .filter(|r| r.file == AmdRegisterFile::Scalar && r.index == 124)
            .collect();
        let quad = scalars.len() == 4
            && scalars[0].index.is_multiple_of(4)
            && scalars
                .iter()
                .enumerate()
                .all(|(i, r)| r.index == scalars[0].index + i as u16 && r.lanes == u64::MAX);
        if self.architecture != AmdArchitecture::Gfx950
            || instruction.exec_mask == 0
            || instruction.pc.is_none_or(|pc| {
                graph.provenance().instructions[pc.0 as usize].kind != "vector memory"
            })
            || instruction.reads.len() != 6
            || !instruction.writes.is_empty()
            || !destinations.is_empty()
            || !held_sources.is_empty()
            || !quad
            || vectors.len() != 1
            || vectors
                .first()
                .is_some_and(|r| r.lanes != instruction.exec_mask)
            || m0.len() != 1
            || m0.first().is_some_and(|r| r.lanes != u64::MAX)
            || !self.initialized_m0.contains(&record.wave)
        {
            unresolved.push(Unresolved::at(record.event,
                "gfx950 buffer-to-LDS DMA requires one active VGPR offset, an aligned descriptor quad, initialized M0 and no register destination or held sources"));
        }
        self.transfers.insert(
            record.event,
            Transfer {
                wave: record.wave,
                mask: instruction.exec_mask,
                width,
                effects: Vec::new(),
            },
        );
    }

    pub(super) fn effect(&mut self, link: &AmdMemoryEffect) {
        if let Some(transfer) = self.transfers.get_mut(&link.issue) {
            transfer.effects.push(*link);
        }
    }

    pub(super) fn finish(self, graph: &EventGraph, unresolved: &mut Vec<Unresolved>) {
        if self.transfers.is_empty() {
            return;
        }
        let limits: Vec<_> = graph
            .provenance()
            .assumptions
            .iter()
            .filter_map(|a| {
                if let Assumption::ConfiguredLdsBytes(bytes) = a {
                    Some(*bytes)
                } else {
                    None
                }
            })
            .collect();
        let limit = if limits.len() == 1 && limits[0] <= AmdArchitecture::Gfx950.lds_capacity() {
            Some(limits[0])
        } else {
            unresolved.push(Unresolved::global(
                "buffer-to-LDS DMA requires exactly one bounded configured LDS extent",
            ));
            None
        };
        if limit.is_some_and(|limit| {
            graph
                .shared_allocation_layout()
                .iter()
                .any(|region| region.offset + region.size > limit)
        }) {
            unresolved.push(Unresolved::global(
                "configured DMA LDS subobjects exceed the declared LDS extent",
            ));
        }
        for (issue, transfer) in self.transfers {
            if !transfer.valid(graph, limit) {
                unresolved.push(Unresolved::at(issue,
                    "buffer-to-LDS DMA effects must cover every active physical lane with complete paired Global reads/Shared writes, bounded M0 pitch and whole LDS intervals"));
            }
        }
    }
}

impl Transfer {
    fn valid(&self, graph: &EventGraph, limit: Option<u64>) -> bool {
        let Some(limit) = limit else {
            return false;
        };
        let components = self.width as usize / 4;
        if self.effects.len() != self.mask.count_ones() as usize * components * 2 {
            return false;
        }
        let mut lanes = HashMap::<u32, (Vec<u64>, Vec<u64>)>::new();
        for link in &self.effects {
            let event = graph.event(link.effect);
            let EventKind::Access(id) = event.kind else {
                return false;
            };
            let access = graph.access(id);
            let lane = access.attributed.0 % 64;
            let Footprint::Bytes { addr, width } = access.footprint else {
                return false;
            };
            if access.attributed.0 / 64 != self.wave
                || self.mask & (1u64 << lane) == 0
                || event.ctx != ExecContext::Thread(access.attributed)
                || access.role != OperandRole::Plain
                || access.ordering != OrderingKind::Ordinary
                || access.proxy != Proxy::Generic
                || width != 4
                || !addr.is_multiple_of(4)
                || link.scope != AmdMemoryScope::Unspecified
            {
                return false;
            }
            let row = lanes.entry(lane).or_default();
            match (access.space, access.mode) {
                (Space::Global, AccessMode::Read) if access.value.is_none() => row.0.push(addr),
                (Space::Shared, AccessMode::Write) if access.value.is_some() => row.1.push(addr),
                _ => return false,
            }
        }
        let mut m0 = None;
        for lane in 0..64 {
            if self.mask & (1u64 << lane) == 0 {
                continue;
            }
            let Some((global, shared)) = lanes.get_mut(&lane) else {
                return false;
            };
            global.sort_unstable();
            shared.sort_unstable();
            if global.len() != components
                || shared.len() != components
                || !global.windows(2).all(|p| p[0].checked_add(4) == Some(p[1]))
                || !shared.windows(2).all(|p| p[0].checked_add(4) == Some(p[1]))
                || global[0]
                    .checked_add(self.width)
                    .is_none_or(|end| end > 1u64 << 48)
            {
                return false;
            }
            let Some(base) = shared[0].checked_sub(u64::from(lane) * self.width) else {
                return false;
            };
            if base > 0xffff || m0.is_some_and(|old| old != base) {
                return false;
            }
            m0 = Some(base);
            let Some(end) = shared[0].checked_add(self.width) else {
                return false;
            };
            if end > limit
                || (!graph.shared_allocation_layout().is_empty()
                    && !graph.shared_allocation_layout().iter().any(|region| {
                        shared[0] >= region.offset && end <= region.offset + region.size
                    }))
            {
                return false;
            }
        }
        true
    }
}
