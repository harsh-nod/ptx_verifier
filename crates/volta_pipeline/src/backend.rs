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
    /// Native AMD gfx950 (the original AMD backend selection).
    Amdgpu,
    /// Native AMD gfx942; selection is checked against the source target.
    AmdgpuGfx942,
    /// Native AMD gfx1250; wave32 semantics are selected by the source target.
    AmdgpuGfx1250,
}

impl Backend {
    pub fn select(name: &str, target: Option<&str>) -> Result<Self, String> {
        match (name, target) {
            ("ptx", None) => Ok(Self::Ptx),
            ("ptx", Some(_)) => Err("--target is only supported with the amdgpu backend; PTX declares its target in source".into()),
            ("amdgpu", None | Some("gfx950")) => Ok(Self::Amdgpu),
            ("amdgpu", Some("gfx942")) => Ok(Self::AmdgpuGfx942),
            ("amdgpu", Some("gfx1250")) => Ok(Self::AmdgpuGfx1250),
            ("amdgpu", Some(target)) => Err(format!("unsupported AMD target '{target}'; expected gfx942, gfx950 or gfx1250")),
            (name, _) => Err(format!("unknown backend '{name}'; expected ptx or amdgpu")),
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Self::Ptx => "ptx",
            Self::Amdgpu | Self::AmdgpuGfx942 | Self::AmdgpuGfx1250 => "amdgpu",
        }
    }

    pub fn target(self) -> Option<&'static str> {
        match self {
            Self::Ptx => None,
            Self::Amdgpu => Some("gfx950"),
            Self::AmdgpuGfx942 => Some("gfx942"),
            Self::AmdgpuGfx1250 => Some("gfx1250"),
        }
    }

    /// Keep explicit API/CLI selection and source architecture consistent. A
    /// missing source directive retains the original gfx950 default.
    pub fn validate_amd_target(self, source_target: Option<&str>) -> Result<(), String> {
        let selected = self
            .target()
            .ok_or("PTX selection cannot load AMD assembly")?;
        let declared = source_target.unwrap_or("gfx950").split(':').next().unwrap();
        if selected != declared {
            return Err(format!(
                "selected target {selected} conflicts with source target {declared}"
            ));
        }
        Ok(())
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
        assert_eq!(
            Backend::select("amdgpu", Some("gfx942")),
            Ok(Backend::AmdgpuGfx942)
        );
        assert_eq!(
            Backend::select("amdgpu", Some("gfx1250")),
            Ok(Backend::AmdgpuGfx1250)
        );
        assert_eq!(Backend::AmdgpuGfx1250.name(), "amdgpu");
        assert_eq!(Backend::AmdgpuGfx1250.target(), Some("gfx1250"));
        assert!(
            Backend::AmdgpuGfx1250
                .validate_amd_target(Some("gfx1250"))
                .is_ok()
        );
        for other in [
            None,
            Some("gfx942"),
            Some("gfx950"),
            Some("gfx1251"),
            Some("gfx1250-strict"),
        ] {
            assert!(Backend::AmdgpuGfx1250.validate_amd_target(other).is_err());
        }
        for target in ["gfx1251", "gfx1250-strict"] {
            assert!(Backend::select("amdgpu", Some(target)).is_err());
        }
        assert!(Backend::select("ptx", Some("gfx1250")).is_err());
        assert!(Backend::select("amdgpu", Some("gfx940")).is_err());
        assert!(
            Backend::AmdgpuGfx942
                .validate_amd_target(Some("gfx942:sramecc+:xnack-"))
                .is_ok()
        );
        assert!(
            Backend::AmdgpuGfx942
                .validate_amd_target(Some("gfx950"))
                .is_err()
        );
        assert!(Backend::Amdgpu.validate_amd_target(Some("gfx942")).is_err());
        assert!(Backend::select("other", None).is_err());
    }
}
