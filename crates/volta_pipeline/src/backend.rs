//! Thin ISA dispatch above the existing artifact-producing analysis stages.
use std::collections::BTreeMap;

use volta_expr::SymbolicOutputs;
use volta_graph::EventGraph;
use volta_graph_check::{GraphReport, check_graph};
use volta_ptx_analysis::{AnalysisConfig, Stats};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Backend {
    #[default]
    Ptx,
    Amdgpu,
}

impl Backend {
    pub fn select(name: &str, target: Option<&str>) -> Result<Self, String> {
        match (name, target) {
            ("ptx", None) => Ok(Self::Ptx),
            ("ptx", Some(_)) => Err("--target is only supported with the amdgpu backend; PTX declares its target in source".into()),
            ("amdgpu", None | Some("gfx950")) => Ok(Self::Amdgpu),
            ("amdgpu", Some(target)) => Err(format!("unsupported AMD target '{target}'; this backend requires gfx950")),
            (name, _) => Err(format!("unknown backend '{name}'; expected ptx or amdgpu")),
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Self::Ptx => "ptx",
            Self::Amdgpu => "amdgpu",
        }
    }
}

pub enum KernelModule {
    Ptx(volta_ptx_analysis::frontend::ast::Module),
    Amdgpu(volta_amdgpu_analysis::frontend::Module),
}

/// Common owned artifacts. Normalization happens here, never in an analyzer.
pub struct SourceAnalysisParts {
    pub outputs: Result<SymbolicOutputs, String>,
    pub graph: EventGraph,
    pub stats: Stats,
    pub op_counts: BTreeMap<&'static str, u64>,
}

pub struct SourceKernelVerification {
    pub analysis: SourceAnalysisParts,
    pub graph: GraphReport,
}

pub fn verify_source_kernel(
    module: &KernelModule,
    kernel: Option<&str>,
    config: AnalysisConfig,
) -> Result<SourceKernelVerification, String> {
    let analysis = match module {
        KernelModule::Ptx(module) => {
            let parts = volta_ptx_analysis::analyze(module, kernel, config)
                .map_err(|error| error.to_string())?
                .into_parts();
            SourceAnalysisParts {
                outputs: parts.outputs.map_err(|error| error.to_string()),
                graph: parts.graph,
                stats: parts.stats,
                op_counts: parts.op_counts,
            }
        }
        KernelModule::Amdgpu(module) => {
            let parts = volta_amdgpu_analysis::analyze(module, kernel, config)
                .map_err(|error| error.to_string())?
                .into_parts();
            SourceAnalysisParts {
                outputs: parts.outputs.map_err(|error| error.to_string()),
                graph: parts.graph,
                stats: Stats {
                    instructions: parts.stats.instructions,
                    block_syncs: parts.stats.block_syncs,
                    warp_syncs: parts.stats.warp_syncs,
                },
                op_counts: parts.op_counts,
            }
        }
    };
    let graph = check_graph(&analysis.graph);
    Ok(SourceKernelVerification { analysis, graph })
}

#[cfg(test)]
mod tests {
    use super::Backend;

    #[test]
    fn selection_is_explicit_and_target_specific() {
        assert_eq!(Backend::select("ptx", None), Ok(Backend::Ptx));
        assert_eq!(
            Backend::select("amdgpu", Some("gfx950")),
            Ok(Backend::Amdgpu)
        );
        assert_eq!(Backend::select("amdgpu", None), Ok(Backend::Amdgpu));
        assert!(Backend::select("ptx", Some("gfx950")).is_err());
        assert!(Backend::select("amdgpu", Some("gfx942")).is_err());
        assert!(Backend::select("other", None).is_err());
    }
}
