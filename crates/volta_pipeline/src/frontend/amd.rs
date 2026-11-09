//! Experimental gfx950 assembly frontend, restricted to workgroup zero of a one-group grid.
//! Its graph checks LDS accesses, waits and barriers; global-memory races are outside its scope.

use volta_amd_analysis::frontend::parse::parse_kernel;
use volta_amd_analysis::{ArrayDef, ArrayKind, OutputType, Terminal, WorkgroupLaunch, analyze};
use volta_graph_check::check_graph;
use volta_ptx_analysis::{AnalysisConfig, ParamValue};

use super::{Frontend, FrontendError, GraphEvidence, KernelRun, only_kernel};

/// Where the kernel argument buffer sits: below the first array a launch file lays out.
const KERNARG_ADDRESS: u64 = 0x1000;

pub struct AmdFrontend;

impl Frontend for AmdFrontend {
    /// The default kernel is the source's only `.amdhsa_kernel` descriptor.
    fn analyze(
        &self,
        source: &str,
        kernel: Option<&str>,
        launch: AnalysisConfig,
    ) -> Result<KernelRun, FrontendError> {
        let name = match kernel {
            Some(name) => name.to_string(),
            None => only_kernel(descriptors(source))?,
        };
        let parsed = parse_kernel(source, &name).map_err(|message| FrontendError::Parse {
            title: "AMD assembly parse error".into(),
            message: Some(message),
            span: None,
        })?;
        if parsed.target.split(':').next() != Some("amdgcn-amd-amdhsa--gfx950") {
            return Err(FrontendError::Launch(
                "the experimental AMD frontend supports only gfx950; select the native amdgpu backend for other targets".into(),
            ));
        }

        let (workgroup, kernarg, arrays) = workgroup_launch(&launch)?;
        let result = analyze(&parsed, &workgroup, &kernarg, &arrays)
            .map_err(|e| FrontendError::Analysis(e.to_string()))?;

        let report = check_graph(&result.graph);
        let outputs = result
            .symbolic_outputs
            .ok_or_else(|| match &result.terminal {
                Terminal::Aborted { wave, pc, error } => {
                    format!("wave {} aborted at instruction {}: {error}", wave.0, pc.0)
                }
                Terminal::Completed => "the run completed without outputs".into(),
            });

        Ok(KernelRun {
            native: None,
            outputs,
            graph: GraphEvidence::Checked {
                graph: Box::new(result.graph),
                report: Box::new(report),
            },
        })
    }
}

/// The kernels `source`'s `.amdhsa_kernel` descriptors name.
fn descriptors(source: &str) -> Vec<String> {
    source
        .lines()
        .filter_map(|line| {
            let (directive, name) = line.trim().split_once(char::is_whitespace)?;
            (directive == ".amdhsa_kernel").then(|| name.trim().to_string())
        })
        .collect()
}

/// `launch` as `volta_amd_analysis` takes it. The parameters fill the argument buffer as clang
/// lays out kernel arguments: each at the next offset aligned to its size.
fn workgroup_launch(
    launch: &AnalysisConfig,
) -> Result<(WorkgroupLaunch, Vec<u8>, Vec<ArrayDef>), FrontendError> {
    if launch.grid_dim != (1, 1, 1)
        || launch.workgroup_id != (0, 0, 0)
        || launch.early_readiness
        || launch.early_memory_conflicts
        || !launch.shared_allocations.is_empty()
        || launch.max_instructions != AnalysisConfig::new((1, 1, 1)).max_instructions
    {
        return Err(FrontendError::Launch(
            "the experimental AMD frontend supports only workgroup zero in a one-group grid, \
             its default instruction budget and no native observer or LDS-layout settings; \
             select the native amdgpu backend for those launch fields"
                .into(),
        ));
    }
    launch.validate().map_err(FrontendError::Launch)?;
    if !launch.global_values.is_empty() {
        return Err(FrontendError::Launch(
            "AMD kernels take no module-scope globals".into(),
        ));
    }

    if launch.dynamic_shared_bytes != 0 {
        return Err(FrontendError::Launch(
            "AMD kernels take their LDS size from their descriptor, not a dynamic shared size"
                .into(),
        ));
    }

    let arrays = launch
        .arrays
        .iter()
        .map(word_array)
        .collect::<Result<_, _>>()?;

    let mut kernarg = Vec::new();
    for param in &launch.params {
        let bytes = argument(launch, param)?;
        kernarg.resize(kernarg.len().next_multiple_of(bytes.len()), 0);
        kernarg.extend(bytes);
    }

    let workgroup = WorkgroupLaunch {
        kernarg_address: KERNARG_ADDRESS,
        workgroup_size: launch.block_dim,
        workgroup_id: launch.workgroup_id,
        grid_size: launch.grid_dim,
    };
    Ok((workgroup, kernarg, arrays))
}

fn word_array(array: &volta_ptx_analysis::ArrayDef) -> Result<ArrayDef, FrontendError> {
    let kind = match array.kind {
        volta_ptx_analysis::ArrayKind::Input => ArrayKind::Input,
        // A launch carries no element type, so every output word is read as an f32.
        volta_ptx_analysis::ArrayKind::Output => ArrayKind::Output(OutputType::F32),
        volta_ptx_analysis::ArrayKind::InputOutput | volta_ptx_analysis::ArrayKind::IndexInput => {
            return Err(FrontendError::Launch(format!(
                "AMD array `{}` must be `in` or `out`",
                array.name
            )));
        }
    };

    if array.elem_width != 4 {
        return Err(FrontendError::Launch(format!(
            "AMD array `{}` has {}-byte elements; AMD arrays hold 32-bit words",
            array.name, array.elem_width
        )));
    }

    Ok(ArrayDef {
        name: array.name.clone(),
        base: array.base,
        len: array.len,
        kind,
    })
}

/// The bytes of one kernel argument: a 64-bit array base, a 32-bit integer or an f32.
fn argument(launch: &AnalysisConfig, param: &ParamValue) -> Result<Vec<u8>, FrontendError> {
    match param {
        ParamValue::ArrayPtr(name) => launch
            .array(name)
            .map(|array| array.base.to_le_bytes().to_vec())
            .ok_or_else(|| FrontendError::Launch(format!("`ptr:{name}` names no array"))),

        ParamValue::Int(value) => i32::try_from(*value)
            .map(|value| value.to_le_bytes().to_vec())
            .map_err(|_| {
                FrontendError::Launch(format!("`int:{value}` does not fit a 32-bit argument"))
            }),

        ParamValue::Float(value) => {
            let single = *value as f32;
            if f64::from(single) == *value {
                Ok(single.to_le_bytes().to_vec())
            } else {
                Err(FrontendError::Launch(format!(
                    "`float:{value}` is not exactly an f32"
                )))
            }
        }

        ParamValue::SymFloat(name) => Err(FrontendError::Launch(format!(
            "`sym:{name}` has no bytes: AMD kernel arguments are concrete"
        ))),

        ParamValue::Struct(_) => Err(FrontendError::Launch(
            "AMD kernels take no struct parameters".into(),
        )),
        ParamValue::Bytes(_) => Err(FrontendError::Launch(
            "exact by-value bytes require the native amdgpu backend".into(),
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn experimental_frontend_preserves_its_single_workgroup_scope() {
        let launch = AnalysisConfig::new((64, 1, 1));
        let (workgroup, _, _) = workgroup_launch(&launch).unwrap();
        assert_eq!(workgroup.workgroup_id, launch.workgroup_id);
        assert_eq!(workgroup.grid_size, launch.grid_dim);

        for (grid, selected) in [
            ((2, 1, 1), (0, 0, 0)),
            ((2, 1, 1), (1, 0, 0)),
            ((1, 2, 1), (0, 1, 0)),
            ((1, 1, 2), (0, 0, 1)),
        ] {
            let mut launch = AnalysisConfig::new((64, 1, 1));
            launch.grid_dim = grid;
            launch.workgroup_id = selected;
            assert!(matches!(
                workgroup_launch(&launch),
                Err(FrontendError::Launch(message))
                    if message.contains("only workgroup zero in a one-group grid")
            ));
        }
    }
}
