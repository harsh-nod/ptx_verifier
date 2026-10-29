//! A display projection of a fully checked graph. It never changes that graph or report.
use std::collections::{BTreeSet, HashMap};

use super::{EventGraph, EventId, EventKind, ExecContext, Json, Lanes};

pub(super) const EVENT_LIMIT: usize = 50_000;
pub(super) const FINDING_LIMIT: usize = 128;

pub(super) struct DisplayEvents {
    total: usize,
    selected: Option<Vec<EventId>>,
    positions: HashMap<EventId, u32>,
    total_findings: usize,
    included_findings: usize,
    limit: usize,
}

fn field_mut<'a>(value: &'a mut Json, name: &str) -> Option<&'a mut Json> {
    let Json::Obj(fields) = value else {
        return None;
    };
    fields
        .iter_mut()
        .find(|(key, _)| *key == name)
        .map(|(_, value)| value)
}

fn include(
    graph: &EventGraph,
    selected: &mut BTreeSet<EventId>,
    ids: &[EventId],
    limit: usize,
) -> bool {
    let mut group = BTreeSet::new();
    for &id in ids {
        let Some(event) = graph.events().get(id) else {
            return false;
        };
        group.insert(id);
        // Keep actual async issue/completion endpoints together. An omitted completion
        // must never turn a completed operation into a displayed pending operation.
        let operation = match (event.ctx, event.kind) {
            (ExecContext::Async(op), _) | (_, EventKind::AsyncIssue(op)) => Some(op),
            _ => None,
        };
        if let Some(op) = operation {
            let op = graph.async_op(op);
            group.insert(op.issue);
            group.extend(op.completion);
        }
    }
    if selected.len() + group.difference(selected).count() > limit {
        return false;
    }
    selected.extend(group);
    true
}

fn retain_findings(
    graph: &EventGraph,
    selected: &mut BTreeSet<EventId>,
    value: &mut Json,
    limit: usize,
) -> usize {
    let Json::Arr(findings) = value else { return 0 };
    findings.retain(|finding| {
        let Json::Obj(fields) = finding else {
            return false;
        };
        let Some(Json::Arr(events)) = fields
            .iter()
            .find(|(key, _)| *key == "events")
            .map(|(_, v)| v)
        else {
            return false;
        };
        let ids: Option<Vec<_>> = events
            .iter()
            .map(|event| match event {
                Json::Int(id) => u32::try_from(*id).ok().map(EventId),
                _ => None,
            })
            .collect();
        let Some(ids) = ids else { return false };
        if !include(graph, selected, &ids, limit) {
            return false;
        }
        true
    });
    findings.len()
}

impl DisplayEvents {
    pub(super) fn of(
        graph: &EventGraph,
        lanes: &Lanes,
        checks: &mut Json,
        terminal: &mut Json,
        limit: Option<usize>,
    ) -> Self {
        let total = graph.events().len();
        let mut view = Self {
            total,
            selected: None,
            positions: HashMap::new(),
            total_findings: 0,
            included_findings: 0,
            limit: limit.unwrap_or(total),
        };
        let Some(limit) = limit.filter(|&limit| total > limit) else {
            return view;
        };
        let mut selected = BTreeSet::new();
        if let Some(notes) = field_mut(terminal, "notes") {
            if let Json::Arr(notes) = notes {
                view.total_findings += notes.len();
            }
            view.included_findings += retain_findings(graph, &mut selected, notes, limit);
        }
        if let Json::Arr(checks) = checks {
            for check in checks {
                let total = match field_mut(check, "totalFindings") {
                    Some(Json::Int(n)) => *n as usize,
                    _ => 0,
                };
                view.total_findings += total;
                if let Some(findings) = field_mut(check, "findings") {
                    view.included_findings +=
                        retain_findings(graph, &mut selected, findings, limit);
                }
            }
        }
        let witnesses: Vec<_> = selected.iter().copied().collect();
        let mut by_pc = HashMap::new();
        let mut by_lane = HashMap::new();
        for (id, event) in graph.events().iter() {
            if let Some(pc) = event.pc {
                by_pc
                    .entry(pc)
                    .and_modify(|span: &mut (EventId, EventId)| span.1 = id)
                    .or_insert((id, id));
            }
            by_lane
                .entry(lanes.lane_of(graph, event.ctx))
                .and_modify(|span: &mut (EventId, EventId)| span.1 = id)
                .or_insert((id, id));
        }
        // Stable order makes repeated exports reproducible despite randomized hash tables.
        let mut spans: Vec<_> = by_pc.into_values().chain(by_lane.into_values()).collect();
        spans.sort_unstable();
        for (first, last) in spans {
            include(graph, &mut selected, &[first, last], limit);
        }
        for id in witnesses {
            for neighbor in [id.0.checked_sub(1), id.0.checked_add(1)]
                .into_iter()
                .flatten()
            {
                include(graph, &mut selected, &[EventId(neighbor)], limit);
            }
        }
        for slot in 0..limit {
            let id = if limit > 1 {
                slot * (total - 1) / (limit - 1)
            } else {
                0
            };
            include(graph, &mut selected, &[EventId(id as u32)], limit);
        }
        for id in 0..total {
            if selected.len() >= limit {
                break;
            }
            include(graph, &mut selected, &[EventId(id as u32)], limit);
        }
        let ids: Vec<_> = selected.into_iter().collect();
        view.positions = ids
            .iter()
            .enumerate()
            .map(|(index, &id)| (id, index as u32))
            .collect();
        view.selected = Some(ids);
        view.remap_findings(checks);
        view.remap_findings(terminal);
        view
    }

    fn remap_findings(&self, value: &mut Json) {
        match value {
            Json::Arr(values) => values.iter_mut().for_each(|v| self.remap_findings(v)),
            Json::Obj(fields) => {
                for (key, value) in fields {
                    if *key == "events" {
                        if let Json::Arr(events) = value {
                            for event in events {
                                let Json::Int(original) = event else {
                                    unreachable!()
                                };
                                *event = Json::uint(
                                    self.index(EventId(*original as u32))
                                        .expect("retained witness endpoint"),
                                );
                            }
                        }
                    } else {
                        self.remap_findings(value);
                    }
                }
            }
            _ => {}
        }
    }

    pub(super) fn index(&self, id: EventId) -> Option<u32> {
        if self.selected.is_some() {
            self.positions.get(&id).copied()
        } else {
            ((id.0 as usize) < self.total).then_some(id.0)
        }
    }

    pub(super) fn ids(&self) -> Box<dyn Iterator<Item = EventId> + '_> {
        match &self.selected {
            Some(ids) => Box::new(ids.iter().copied()),
            None => Box::new((0..self.total).map(|id| EventId(id as u32))),
        }
    }

    pub(super) fn fields(&self) -> Vec<(&'static str, Json)> {
        let Some(ids) = &self.selected else {
            return Vec::new();
        };
        vec![
            (
                "eventIds",
                Json::Arr(ids.iter().map(|id| Json::uint(id.0)).collect()),
            ),
            (
                "display",
                Json::Obj(vec![
                    ("eventLimit", Json::uint(self.limit as u64)),
                    ("findingLimitPerProperty", Json::uint(FINDING_LIMIT as u64)),
                    ("totalEvents", Json::uint(self.total as u64)),
                    ("includedEvents", Json::uint(ids.len() as u64)),
                    ("omittedEvents", Json::uint((self.total - ids.len()) as u64)),
                    ("totalFindings", Json::uint(self.total_findings as u64)),
                    (
                        "includedFindings",
                        Json::uint(self.included_findings as u64),
                    ),
                    (
                        "omittedFindings",
                        Json::uint((self.total_findings - self.included_findings) as u64),
                    ),
                    (
                        "selection",
                        Json::str(
                            "display only: selected finding witnesses, first/last source and lane events, evenly spaced events; checks use the complete graph",
                        ),
                    ),
                ]),
            ),
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use volta_graph::{
        AccessMode, AsyncOpKind, FenceKind, Footprint, GraphBuilder, InstructionInfo, MemAccess,
        OperandRole, OrderingKind, ProgramPoint, Provenance, Proxy, Space, Terminal, ThreadIx,
    };

    fn graph() -> (EventGraph, EventId, EventId, EventId) {
        let mut b = GraphBuilder::new(Provenance {
            kernel: "projection".into(),
            block_dim: (2, 1, 1),
            grid_dim: (1, 1, 1),
            targets: vec!["Sm100a".into()],
            assumptions: vec![],
            instructions: vec![
                InstructionInfo {
                    kind: "Fence",
                    span: None
                };
                2
            ],
        });
        for n in 0..100 {
            b.fence(
                ThreadIx(n % 2),
                ProgramPoint(if n == 79 { 1 } else { 0 }),
                FenceKind::ProxyAsync { space: None },
            );
        }
        let op = b.async_issue(ThreadIx(0), ProgramPoint(0), AsyncOpKind::CpAsync);
        let issue = b.graph_so_far().async_op(op).issue;
        let effect = b.async_effect(
            op,
            MemAccess {
                space: Space::Shared,
                mode: AccessMode::Read,
                ordering: OrderingKind::Ordinary,
                proxy: Proxy::Async,
                footprint: Footprint::Bytes { addr: 0, width: 4 },
                role: OperandRole::Plain,
                attributed: ThreadIx(0),
                value: None,
            },
        );
        for _ in 0..20 {
            b.fence(
                ThreadIx(1),
                ProgramPoint(0),
                FenceKind::ProxyAsync { space: None },
            );
        }
        let completion = b.async_complete(op);
        b.exit(ThreadIx(0), ProgramPoint(0));
        b.exit(ThreadIx(1), ProgramPoint(0));
        (b.finish(Terminal::Completed), issue, effect, completion)
    }

    fn check(ids: &[u32]) -> Json {
        Json::Arr(vec![Json::Obj(vec![
            ("verdict", Json::str("unknown")),
            ("totalFindings", Json::uint(1u32)),
            (
                "findings",
                Json::Arr(vec![Json::Obj(vec![
                    ("text", Json::str("late witness")),
                    (
                        "events",
                        Json::Arr(ids.iter().map(|&id| Json::uint(id)).collect()),
                    ),
                ])]),
            ),
        ])])
    }

    fn terminal() -> Json {
        Json::Obj(vec![
            ("kind", Json::str("completed")),
            ("notes", Json::Arr(vec![])),
        ])
    }

    #[test]
    fn full_identity_and_small_records_keep_their_existing_ids_and_fields() {
        let (graph, _, _, _) = graph();
        for limit in [None, Some(graph.events().len())] {
            let mut checks = check(&[73]);
            let old = checks.clone();
            let mut terminal = terminal();
            let view = DisplayEvents::of(
                &graph,
                &Lanes::of(&graph),
                &mut checks,
                &mut terminal,
                limit,
            );
            assert_eq!(view.ids().count(), graph.events().len());
            assert_eq!(view.index(EventId(73)), Some(73));
            assert!(view.fields().is_empty());
            assert_eq!(checks, old);
        }
    }

    #[test]
    fn late_witnesses_remain_linked_to_original_ids_and_actual_async_completion() {
        let (graph, issue, effect, completion) = graph();
        let original_graph = graph.clone();
        let mut checks = check(&[73, effect.0]);
        let mut terminal = terminal();
        let view = DisplayEvents::of(
            &graph,
            &Lanes::of(&graph),
            &mut checks,
            &mut terminal,
            Some(16),
        );
        let ids: Vec<_> = view.ids().collect();
        assert!(ids.len() <= 16);
        assert!(ids.windows(2).all(|w| w[0] < w[1]));
        for id in [EventId(73), EventId(79), issue, effect, completion] {
            assert!(view.index(id).is_some(), "{id:?}");
        }
        assert_ne!(view.index(effect), Some(effect.0));
        let Json::Arr(checks) = checks else { panic!() };
        let Json::Obj(fields) = &checks[0] else {
            panic!()
        };
        assert!(fields.contains(&("verdict", Json::str("unknown"))));
        assert!(format!("{checks:?}").contains(&format!("Int({})", view.index(effect).unwrap())));
        let operations = super::super::async_ops(&graph, &view);
        let Json::Arr(operations) = operations else {
            panic!()
        };
        assert_eq!(
            operations,
            [Json::Arr(vec![
                Json::uint(view.index(issue).unwrap()),
                Json::uint(view.index(completion).unwrap()),
                Json::uint(view.index(effect).unwrap()),
            ])]
        );
        assert_eq!(graph, original_graph);
    }

    #[test]
    fn oversize_or_invalid_witnesses_are_omitted_whole_and_counted() {
        let (graph, _, _, _) = graph();
        for ids in [(0..100).collect::<Vec<_>>(), vec![999]] {
            let mut checks = check(&ids);
            let mut terminal = terminal();
            let view = DisplayEvents::of(
                &graph,
                &Lanes::of(&graph),
                &mut checks,
                &mut terminal,
                Some(8),
            );
            assert!(view.ids().count() <= 8);
            assert_eq!(view.total_findings, 1);
            assert_eq!(view.included_findings, 0);
            assert!(format!("{:?}", view.fields()).contains("omittedFindings"));
            assert!(!format!("{checks:?}").contains("late witness"));
            assert!(format!("{checks:?}").contains("unknown"));
        }
    }

    #[test]
    fn projection_is_reproducible_and_every_exported_edge_uses_display_indices() {
        let (graph, _, effect, _) = graph();
        let mut views = Vec::new();
        for _ in 0..2 {
            let mut checks = check(&[effect.0]);
            let mut terminal = terminal();
            views.push(DisplayEvents::of(
                &graph,
                &Lanes::of(&graph),
                &mut checks,
                &mut terminal,
                Some(16),
            ));
        }
        assert_eq!(views[0].fields(), views[1].fields());
        let edges = super::super::edges(&graph, &views[0]);
        let Json::Obj(kinds) = edges else { panic!() };
        for (_, values) in kinds {
            let Json::Arr(values) = values else { panic!() };
            for endpoints in values.chunks_exact(2) {
                let [Json::Int(from), Json::Int(to)] = endpoints else {
                    panic!()
                };
                assert!(*from < *to);
                assert!(*to < views[0].ids().count() as i64);
            }
        }
    }

    #[test]
    fn omitting_all_effects_does_not_invent_an_effectless_async_operation() {
        let (graph, issue, _, completion) = graph();
        let ids = vec![issue, completion];
        let view = DisplayEvents {
            total: graph.events().len(),
            positions: ids
                .iter()
                .enumerate()
                .map(|(index, &id)| (id, index as u32))
                .collect(),
            selected: Some(ids),
            total_findings: 0,
            included_findings: 0,
            limit: 2,
        };
        assert_eq!(super::super::async_ops(&graph, &view), Json::Arr(vec![]));
    }
}
