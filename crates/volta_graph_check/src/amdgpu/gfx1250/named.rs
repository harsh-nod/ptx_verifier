//! Independent shader named-barrier state and execution frontiers. Counts are
//! arrivals, not lanes or distinct waves; END never contributes a named drop.
use super::*;
use volta_graph::{AmdEvent, AmdNamedBarrier};

#[derive(Clone)]
struct Point {
    event: EventId,
    wave: usize,
    execution: Vec<u32>,
    memory: Vec<u32>,
    arrivals: Vec<u32>,
}
impl Point {
    fn before(&self, later: &Self) -> bool {
        self.event != later.event && later.execution[self.wave] >= self.execution[self.wave]
    }
}
#[derive(Default)]
struct Phase {
    signals: Vec<Point>,
    drops: Vec<Point>,
    complete: bool,
    releases: Vec<Point>,
}
struct Object {
    handle: AmdNamedBarrier,
    init: Point,
    expected: u16,
    arrived: u16,
    phase: u32,
    phases: HashMap<u32, Phase>,
    last_arrive: HashMap<usize, u32>,
    uses: Vec<Point>,
}
#[derive(Clone)]
struct Joined {
    handle: AmdNamedBarrier,
    phase: u32,
    join: Point,
}
#[derive(Clone)]
struct Waiting {
    joined: Joined,
    pc: Option<volta_graph::ProgramPoint>,
}
pub(super) struct Release {
    pub memory: Vec<u32>,
    pub arrivals: Vec<u32>,
    pub drops: bool,
}
pub(super) struct State {
    objects: HashMap<u8, Object>,
    retired: Vec<Object>,
    joined: Vec<Option<Joined>>,
    blocked: Vec<Option<Waiting>>,
    null_waits: Vec<Option<Option<volta_graph::ProgramPoint>>>,
    pub violations: Vec<AmdBarrierViolation>,
    pub unresolved: Vec<Unresolved>,
    pub signals: usize,
    pub releases: usize,
    pub phases: usize,
}
impl State {
    pub fn new(waves: usize) -> Self {
        Self {
            objects: HashMap::new(),
            retired: Vec::new(),
            joined: vec![None; waves],
            blocked: vec![None; waves],
            null_waits: vec![None; waves],
            violations: Vec::new(),
            unresolved: Vec::new(),
            signals: 0,
            releases: 0,
            phases: 0,
        }
    }
    fn fail(&mut self, record: &AmdEvent, phase: u32, reason: &str) {
        self.violations.push(AmdBarrierViolation {
            generation: phase,
            event: record.event,
            wave: record.wave,
            reason: reason.into(),
        });
    }
    pub fn instruction(&mut self, record: &AmdEvent) {
        if self.blocked[record.wave as usize].is_some() {
            self.fail(
                record,
                0,
                "wave progressed while blocked at a named-barrier wait",
            );
        }
    }
    pub fn event(
        &mut self,
        record: &AmdEvent,
        pc: Option<volta_graph::ProgramPoint>,
        execution: &mut [Vec<u32>],
        memory: &[u32],
        arrivals: &[u32],
    ) -> Option<Release> {
        let wave = record.wave as usize;
        let mut point = Point {
            event: record.event,
            wave,
            execution: execution[wave].clone(),
            memory: memory.to_vec(),
            arrivals: arrivals.to_vec(),
        };
        let (handle, phase) = match record.kind {
            AmdEventKind::NamedBarrierInit { object, .. } => (object, 0),
            AmdEventKind::NamedBarrierJoin { object, phase }
            | AmdEventKind::NamedBarrierSignal { object, phase, .. }
            | AmdEventKind::NamedBarrierWait { object, phase, .. }
            | AmdEventKind::NamedBarrierRelease { object, phase }
            | AmdEventKind::NamedBarrierLeave { object, phase } => (object, phase),
            _ => return None,
        };
        if let AmdEventKind::NamedBarrierInit { expected, .. } = record.kind {
            if handle.id == 0 {
                if handle.incarnation != 0 {
                    self.fail(
                        record,
                        0,
                        "NULL named barrier has no initialization lifetime",
                    );
                }
                return None;
            }
            let next = self
                .objects
                .get(&handle.id)
                .map_or(Some(0), |old| old.handle.incarnation.checked_add(1));
            if next != Some(handle.incarnation) || expected == 0 {
                self.fail(
                    record,
                    0,
                    "named init has a stale incarnation or nonpositive expected count",
                );
                return None;
            }
            if self
                .joined
                .iter()
                .flatten()
                .any(|j| j.handle.id == handle.id)
            {
                self.unresolved.push(Unresolved::at(
                    record.event,
                    "reinitialization with outstanding named joins is outside the selected profile",
                ));
            }
            if let Some(previous) = self.objects.get(&handle.id)
                && previous.uses.iter().any(|p| !p.before(&point))
            {
                self.unresolved.push(Unresolved::at(
                    record.event,
                    "named reinitialization is not ordered after every previous use",
                ));
            }
            let previous = self.objects.insert(
                handle.id,
                Object {
                    handle,
                    init: point.clone(),
                    expected,
                    arrived: 0,
                    phase: 0,
                    phases: HashMap::new(),
                    last_arrive: HashMap::new(),
                    uses: vec![point],
                },
            );
            self.retired.extend(previous);
            return None;
        }
        if handle.id == 0 {
            if handle.incarnation != 0 || phase != 0 {
                self.fail(
                    record,
                    phase,
                    "NULL named barrier has no initialization lifetime or phases",
                );
            }
            match record.kind {
                AmdEventKind::NamedBarrierJoin { .. } => {
                    self.joined[wave] = Some(Joined {
                        handle,
                        phase,
                        join: point,
                    })
                }
                AmdEventKind::NamedBarrierSignal { .. } => {}
                AmdEventKind::NamedBarrierWait { .. } => {
                    match self.joined[wave].as_ref() {
                        None => self.unresolved.push(Unresolved::at(record.event,
                            "NULL wait lacks an explicit NULL join; the last-joined selector is not pinned")),
                        Some(joined) if joined.handle != handle => {
                            self.fail(record, phase, "NULL wait is not on the last joined object");
                        }
                        _ => {},
                    }
                    self.null_waits[wave] = Some(pc);
                }
                AmdEventKind::NamedBarrierRelease { .. } => {
                    if self.null_waits[wave].take() != Some(pc) {
                        self.fail(
                            record,
                            phase,
                            "NULL release lacks its matching wait source point",
                        );
                    }
                }
                AmdEventKind::NamedBarrierLeave { .. }
                    if self.joined[wave].as_ref().is_some_and(|j| j.handle.id != 0) =>
                {
                    self.fail(
                        record,
                        phase,
                        "NULL leave disagrees with the last joined object",
                    );
                }
                _ => {}
            }
            return None;
        }
        let Some(object) = self.objects.get_mut(&handle.id) else {
            self.fail(record, phase, "operation on an uninitialized named barrier");
            return None;
        };
        if object.handle != handle {
            self.fail(
                record,
                phase,
                "named operation refers to a stale initialization lifetime",
            );
            return None;
        }
        if !object.init.before(&point) {
            self.unresolved.push(Unresolved::between(
                object.init.event,
                record.event,
                "named initialization is not ordered before another wave's use",
            ));
        }
        object.uses.push(point.clone());
        match record.kind {
            AmdEventKind::NamedBarrierJoin { .. } => {
                if phase != object.phase {
                    self.fail(
                        record,
                        phase,
                        "named join snapshots the wrong forming phase",
                    );
                    return None;
                }
                self.joined[wave] = Some(Joined {
                    handle,
                    phase,
                    join: point,
                });
            }
            AmdEventKind::NamedBarrierSignal { .. } => {
                if phase != object.phase || object.expected == 0 {
                    self.fail(
                        record,
                        phase,
                        "named signal has the wrong phase or zero expected count",
                    );
                    return None;
                }
                object.phases.entry(phase).or_default().signals.push(point);
                object.last_arrive.insert(wave, phase);
                object.arrived += 1;
                self.signals += 1;
                if object.arrived == object.expected {
                    object.phases.entry(phase).or_default().complete = true;
                    object.phase += 1;
                    object.arrived = 0;
                    self.phases += 1;
                }
            }
            AmdEventKind::NamedBarrierWait { .. } => {
                let joined = self.joined[wave].as_ref();
                if joined.is_none_or(|j| j.handle != handle || j.phase != phase) {
                    self.fail(
                        record,
                        phase,
                        "named wait does not match its last joined object and next phase",
                    );
                    return None;
                }
                self.blocked[wave] = joined.cloned().map(|joined| Waiting { joined, pc });
            }
            AmdEventKind::NamedBarrierRelease { .. } => {
                let joined = self.blocked[wave].take();
                if joined.as_ref().is_none_or(|j| {
                    j.joined.handle != handle || j.joined.phase != phase || j.pc != pc
                }) {
                    self.fail(
                        record,
                        phase,
                        "named release lacks its matching object/phase wait source point",
                    );
                    return None;
                }
                let joined = joined.unwrap().joined;
                let Some(completed) = object.phases.get_mut(&phase).filter(|p| p.complete) else {
                    self.fail(
                        record,
                        phase,
                        "named release occurs before the expected arrival/drop count completes",
                    );
                    return None;
                };
                if !completed
                    .signals
                    .iter()
                    .chain(&completed.drops)
                    .any(|p| joined.join.before(p))
                {
                    self.fail(
                        record,
                        phase,
                        "named join is not execution-before any contribution to this wait",
                    );
                    return None;
                }
                let mut release = Release {
                    memory: memory.to_vec(),
                    arrivals: arrivals.to_vec(),
                    drops: !completed.drops.is_empty(),
                };
                for contribution in completed.signals.iter().chain(&completed.drops) {
                    join(&mut execution[wave], &contribution.execution);
                    join(&mut release.memory, &contribution.memory);
                }
                for signal in &completed.signals {
                    join(&mut release.arrivals, &signal.arrivals);
                }
                point.execution = execution[wave].clone();
                completed.releases.push(point);
                self.joined[wave].as_mut().unwrap().phase += 1;
                self.releases += 1;
                return Some(release);
            }
            AmdEventKind::NamedBarrierLeave { .. } => {
                if self.joined[wave]
                    .as_ref()
                    .is_none_or(|j| j.handle != handle)
                {
                    self.fail(record, phase, "named leave has no matching preceding join");
                    return None;
                }
                if phase != object.phase
                    || object.expected == 0
                    || object.last_arrive.get(&wave) == Some(&phase)
                {
                    self.fail(record, phase, "named drop has a stale phase, negative expected count, or uncompleted preceding arrival");
                    return None;
                }
                self.joined[wave] = None;
                object.expected -= 1;
                object.phases.entry(phase).or_default().drops.push(point);
                if object.arrived == object.expected {
                    object.phases.entry(phase).or_default().complete = true;
                    object.phase += 1;
                    object.arrived = 0;
                    self.phases += 1;
                }
            }
            _ => unreachable!(),
        }
        None
    }
    pub fn finish(&mut self, graph: &EventGraph) {
        for object in self.objects.values().chain(&self.retired) {
            for (&phase_id, phase) in &object.phases {
                for wait in &phase.releases {
                    for arrive in phase.signals.iter().chain(&phase.drops) {
                        for (&other_id, other) in &object.phases {
                            if other_id == phase_id || other.releases.is_empty() {
                                continue;
                            }
                            for point in other
                                .signals
                                .iter()
                                .chain(&other.drops)
                                .chain(&other.releases)
                            {
                                if arrive.before(point) && point.before(wait) {
                                    self.violations.push(AmdBarrierViolation { generation: phase_id, event: wait.event, wave: wait.wave as u32, reason: "named barrier phases are not separated in execution order".into() });
                                }
                            }
                        }
                    }
                }
            }
        }
        if matches!(graph.terminal(), Terminal::Completed) {
            for (wave, wait) in self.blocked.iter().enumerate() {
                if let Some(wait) = wait {
                    self.violations.push(AmdBarrierViolation {
                        generation: wait.joined.phase,
                        event: wait.joined.join.event,
                        wave: wave as u32,
                        reason: "completed trace leaves a named-barrier wait blocked".into(),
                    });
                }
            }
        }
    }
}
