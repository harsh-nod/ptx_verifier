//! Candidate execution and the two existing downstream artifacts, without verdicts.
use crate::{
    config::AnalysisConfig,
    eval::{EvalError, Interpreter, OutputsUnavailable, RunArtifacts, Stats},
    frontend::Module,
    lower::{LowerError, lower_kernel_in_module},
};
use std::{collections::BTreeMap, error::Error, fmt};
use volta_expr::{ExprArena, SymbolicOutputs};
use volta_graph::{Assumption, EventGraph, InstructionInfo, Provenance};

#[derive(Debug)]
pub enum AnalysisError {
    KernelNotFound { name: Option<String> },
    Lower(LowerError),
    Eval(EvalError),
}
impl fmt::Display for AnalysisError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::KernelNotFound { name } => write!(f, "no AMD kernel matching {name:?}"),
            Self::Lower(e) => write!(f, "{e}"),
            Self::Eval(e) => write!(f, "{e}"),
        }
    }
}
impl Error for AnalysisError {}

#[derive(Debug)]
pub struct AnalysisResult {
    symbolic: SymbolicOutputs,
    outputs: Result<(), OutputsUnavailable>,
    pub graph: EventGraph,
    pub stats: Stats,
    pub op_counts: BTreeMap<&'static str, u64>,
}
impl AnalysisResult {
    fn from_run(run: RunArtifacts) -> Self {
        let (outputs, status) = match run.outputs {
            Ok(outputs) => (outputs, Ok(())),
            Err(why) => (Vec::new(), Err(why)),
        };
        Self {
            symbolic: SymbolicOutputs {
                arena: run.arena,
                outputs,
            },
            outputs: status,
            graph: run.graph,
            stats: run.stats,
            op_counts: run.op_counts,
        }
    }
    pub fn symbolic_outputs(&self) -> Result<&SymbolicOutputs, &OutputsUnavailable> {
        self.outputs.as_ref().map(|()| &self.symbolic)
    }
    pub fn arena(&self) -> &ExprArena {
        &self.symbolic.arena
    }
    pub fn graph(&self) -> &EventGraph {
        &self.graph
    }
    pub fn into_parts(self) -> AnalysisParts {
        AnalysisParts {
            outputs: self.outputs.map(|()| self.symbolic),
            graph: self.graph,
            stats: self.stats,
            op_counts: self.op_counts,
        }
    }
}
#[derive(Debug)]
pub struct AnalysisParts {
    pub outputs: Result<SymbolicOutputs, OutputsUnavailable>,
    pub graph: EventGraph,
    pub stats: Stats,
    pub op_counts: BTreeMap<&'static str, u64>,
}

pub fn analyze(
    module: &Module,
    name: Option<&str>,
    config: AnalysisConfig,
) -> Result<AnalysisResult, AnalysisError> {
    let kernel = module
        .kernels
        .iter()
        .find(|kernel| name.is_none_or(|name| kernel.name == name))
        .ok_or_else(|| AnalysisError::KernelNotFound {
            name: name.map(str::to_string),
        })?;
    let program = lower_kernel_in_module(module, kernel).map_err(AnalysisError::Lower)?;
    let target = module.target.clone().unwrap_or_else(|| "gfx950".into());
    let replay_enabled = target.split(':').any(|feature| feature == "xnack+");
    let mut assumptions = vec![
        Assumption::StructuredCta,
        Assumption::SingleWorkgroupAnalyzed,
        Assumption::MathematicalRealArithmetic,
        Assumption::EagerAsyncData,
    ];
    if crate::target::Architecture::from_target(&target)
        == Some(crate::target::Architecture::Gfx1250)
    {
        assumptions.push(Assumption::UnclusteredWorkgroup);
        let named = kernel.descriptor.value("named_barrier_count", 0);
        if named != 0 {
            assumptions.push(Assumption::AllocatedNamedBarriers((named * 4) as u8));
        }
    } else if !replay_enabled {
        assumptions.push(Assumption::XnackReplayDisabled);
    }
    if crate::target::Architecture::from_target(&target)
        != Some(crate::target::Architecture::Gfx1250)
        && !program.descriptor.flag("tg_split")
    {
        assumptions.push(Assumption::SingleCuWorkgroup);
    }
    let provenance = Provenance {
        kernel: kernel.name.clone(),
        block_dim: config.block_dim,
        grid_dim: config.grid_dim,
        targets: vec![target],
        assumptions,
        instructions: program
            .instructions
            .iter()
            .map(|instruction| InstructionInfo {
                kind: if instruction.mnemonic() == "global_atomic_add_f32" {
                    "atomic f32 add no return"
                } else if module
                    .target
                    .as_deref()
                    .and_then(crate::target::Architecture::from_target)
                    == Some(crate::target::Architecture::Gfx1250)
                    && instruction.mnemonic().starts_with("flat_")
                {
                    "flat memory"
                } else if instruction.mnemonic().starts_with("tensor_") {
                    "tensor memory"
                } else if instruction.mnemonic() == "v_nop" {
                    "vector ALU"
                } else if instruction.mnemonic() == "s_getreg_b32"
                    || (instruction.mnemonic() == "s_sendmsg"
                        && module
                            .target
                            .as_deref()
                            .and_then(crate::target::Architecture::from_target)
                            == Some(crate::target::Architecture::Gfx1250))
                {
                    "xcnt drain"
                } else if instruction.mnemonic() == "s_delay_alu" {
                    "s_delay_alu"
                } else if instruction.mnemonic() == "s_barrier_signal" {
                    if matches!(instruction.operands(), [crate::ir::Operand::Integer(-1)]) {
                        "barrier signal"
                    } else {
                        "named barrier signal"
                    }
                } else if instruction.mnemonic() == "s_barrier_wait" {
                    if matches!(instruction.operands(), [crate::ir::Operand::Integer(-1)]) {
                        "barrier wait"
                    } else {
                        "named barrier wait"
                    }
                } else if instruction.mnemonic() == "s_barrier_init" {
                    "named barrier init"
                } else if instruction.mnemonic() == "s_barrier_join" {
                    "named barrier join"
                } else if instruction.mnemonic() == "s_barrier_leave" {
                    "named barrier leave"
                } else if instruction.mnemonic() == "s_nop" {
                    "s_nop"
                } else if instruction.mnemonic() == "s_endpgm" {
                    "s_endpgm"
                } else if matches!(
                    instruction.mnemonic().as_str(),
                    "v_fma_mixlo_f16" | "v_fma_mixhi_f16"
                ) {
                    "shifted ALU"
                } else if matches!(
                    instruction
                        .mnemonic()
                        .trim_end_matches("_e32")
                        .trim_end_matches("_e64"),
                    "v_s_exp_f32"
                        | "v_exp_f32"
                        | "v_log_f32"
                        | "v_rcp_f32"
                        | "v_rsq_f32"
                        | "v_sqrt_f32"
                        | "v_rcp_f64"
                        | "v_sqrt_f64"
                ) {
                    "trans ALU"
                } else {
                    super::eval::interp_kind(instruction.opcode(), instruction.mnemonic())
                },
                span: Some((instruction.span().start, instruction.span().end)),
            })
            .collect(),
    };
    let interpreter =
        Interpreter::new(&program, config, provenance).map_err(AnalysisError::Eval)?;
    Ok(AnalysisResult::from_run(interpreter.execute()))
}

pub fn write_op_counts(
    out: &mut dyn std::io::Write,
    label: &str,
    counts: &BTreeMap<&'static str, u64>,
) -> std::io::Result<()> {
    if counts.is_empty() {
        return Ok(());
    }
    let total: u64 = counts.values().sum();
    let mut entries: Vec<_> = counts.iter().collect();
    entries.sort_by(|a, b| b.1.cmp(a.1).then(a.0.cmp(b.0)));
    writeln!(out, "{label} profile:")?;
    for (kind, count) in entries {
        writeln!(
            out,
            "  {kind:<16} {count:>10}  ({:>5.1}%)",
            100.0 * *count as f64 / total as f64
        )?;
    }
    Ok(())
}
