//! Private instrumentation for an isolated phase-attribution build.
//! No phase observation authorizes, suppresses or changes a verifier result.
use std::{cell::RefCell, io::Write, path::PathBuf, time::Instant};

#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Phase {
    RemainingExecutionOutput,
    Discovery,
    LivePrefixValidation,
    FinalPrefixValidation,
    FinalOrdinaryGraph,
}

const PHASES: [(Phase, &str); 5] = [
    (
        Phase::RemainingExecutionOutput,
        "remaining_execution_output",
    ),
    (Phase::Discovery, "discovery"),
    (Phase::LivePrefixValidation, "live_prefix_validation"),
    (Phase::FinalPrefixValidation, "final_prefix_validation"),
    (Phase::FinalOrdinaryGraph, "final_ordinary_graph"),
];

impl Phase {
    fn index(self) -> usize {
        self as usize
    }
}

#[derive(Default, Clone, Copy)]
struct Observation {
    exclusive_ns: u128,
    calls: u64,
}

struct Frame {
    phase: Phase,
    children_ns: u128,
}

#[derive(Default)]
struct State {
    observations: [Observation; 5],
    stack: Vec<Frame>,
    root_ns: u128,
    valid: bool,
}

impl State {
    fn close(&mut self, phase: Phase, elapsed_ns: u128) {
        let Some(frame) = self.stack.pop() else {
            self.valid = false;
            return;
        };
        let Some(exclusive_ns) = elapsed_ns.checked_sub(frame.children_ns) else {
            self.valid = false;
            return;
        };
        self.valid &= frame.phase == phase;
        let observation = &mut self.observations[phase.index()];
        observation.exclusive_ns += exclusive_ns;
        observation.calls += 1;
        if let Some(parent) = self.stack.last_mut() {
            parent.children_ns += elapsed_ns;
        } else {
            self.root_ns += elapsed_ns;
        }
    }
}

thread_local! {
    static STATE: RefCell<Option<State>> = const { RefCell::new(None) };
}

pub(crate) struct Session(Option<PathBuf>);

impl Session {
    pub(crate) fn new() -> Self {
        let path = std::env::var_os("VOLTA_STAGE_A_PHASES").map(PathBuf::from);
        let enabled = path.is_some()
            && STATE.with_borrow_mut(|state| {
                if state.is_some() {
                    false
                } else {
                    *state = Some(State {
                        valid: true,
                        ..State::default()
                    });
                    true
                }
            });
        Self(if enabled { path } else { None })
    }
}

impl Drop for Session {
    fn drop(&mut self) {
        let Some(path) = &self.0 else { return };
        let Some(state) = STATE.with_borrow_mut(Option::take) else {
            return;
        };
        let sum: u128 = state.observations.iter().map(|o| o.exclusive_ns).sum();
        let valid = state.valid && state.stack.is_empty() && sum == state.root_ns;
        let mut output = format!(
            "{{\"schema_version\":1,\"valid\":{valid},\"root_ns\":{},\"phases\":{{",
            state.root_ns
        );
        for (index, (phase, name)) in PHASES.iter().enumerate() {
            let observation = state.observations[phase.index()];
            if index != 0 {
                output.push(',');
            }
            output.push_str(&format!(
                "\"{name}\":{{\"exclusive_ns\":{},\"calls\":{}}}",
                observation.exclusive_ns, observation.calls
            ));
        }
        output.push_str("}}\n");
        // Measurement failure stays a missing/invalid measurement. It never
        // changes functional stdout, stderr, control flow or exit status.
        if let Ok(mut file) = std::fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(path)
        {
            let _ = file.write_all(output.as_bytes());
        }
    }
}

pub(crate) struct Scope {
    phase: Phase,
    started: Option<Instant>,
}

impl Scope {
    pub(crate) fn new(phase: Phase) -> Self {
        let started = STATE.with_borrow_mut(|state| {
            state.as_mut().map(|state| {
                state.stack.push(Frame {
                    phase,
                    children_ns: 0,
                });
                Instant::now()
            })
        });
        Self { phase, started }
    }
}

impl Drop for Scope {
    fn drop(&mut self) {
        if let Some(started) = self.started {
            let elapsed = started.elapsed().as_nanos();
            STATE.with_borrow_mut(|state| {
                if let Some(state) = state {
                    state.close(self.phase, elapsed);
                }
            });
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{Frame, Phase, State};

    #[test]
    fn nested_children_are_subtracted_once_without_clock_measurements() {
        let mut state = State {
            valid: true,
            ..State::default()
        };
        state.stack.push(Frame {
            phase: Phase::RemainingExecutionOutput,
            children_ns: 0,
        });
        state.stack.push(Frame {
            phase: Phase::LivePrefixValidation,
            children_ns: 0,
        });
        state.stack.push(Frame {
            phase: Phase::Discovery,
            children_ns: 0,
        });
        state.close(Phase::Discovery, 3);
        state.close(Phase::LivePrefixValidation, 8);
        state.close(Phase::RemainingExecutionOutput, 20);
        assert!(state.valid);
        assert_eq!(state.root_ns, 20);
        assert_eq!(state.observations[Phase::Discovery.index()].exclusive_ns, 3);
        assert_eq!(
            state.observations[Phase::LivePrefixValidation.index()].exclusive_ns,
            5
        );
        assert_eq!(
            state.observations[Phase::RemainingExecutionOutput.index()].exclusive_ns,
            12
        );
    }

    #[test]
    fn impossible_nesting_is_invalid_instead_of_fabricating_zero_cost() {
        let mut state = State {
            valid: true,
            ..State::default()
        };
        state.stack.push(Frame {
            phase: Phase::Discovery,
            children_ns: 7,
        });
        state.close(Phase::Discovery, 6);
        assert!(!state.valid);
    }
}
