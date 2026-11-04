//! Shared launch arguments and conversion to analysis configuration.

use std::path::PathBuf;

use clap::Args;
use volta_common::config::SharedAllocation;
use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, LaunchFile, ParamValue};

/// Launch configuration shared by `analyze`, `compare` and `verify` (flattened into each, so
/// they cannot drift apart). For `compare` it describes the reference kernel; `--block2`/`--grid2`
/// override the optimized kernel's dims.
#[derive(Args)]
pub(crate) struct LaunchArgs {
    /// JSON launch file in place of the flags below: block, grid, arrays, params, globals and
    /// the kernel to run (see `volta_ptx_analysis`'s `launch_file` docs for the format)
    #[arg(
        long,
        value_name = "FILE",
        conflicts_with_all = ["block", "grid", "workgroup_id", "early_readiness", "early_memory_conflicts", "arrays", "params", "globals", "dyn_shared", "shared_allocations"]
    )]
    pub(crate) config: Option<PathBuf>,

    /// Block dimensions, e.g. "128" or "32,4,1"
    #[arg(short, long, default_value = "1")]
    block: String,

    /// Grid dimensions, e.g. "64,64"
    #[arg(short, long, default_value = "1")]
    grid: String,

    /// Native AMD workgroup to analyze, exactly "X,Y,Z"; other groups are outside the result.
    #[arg(long, default_value = "0,0,0")]
    workgroup_id: String,

    /// Stop at the first independently certified gfx1250 scalar-readiness finding.
    /// Default runs retain complete traces. This option never enables early acceptance.
    #[arg(long)]
    pub(crate) early_readiness: bool,

    /// Stop at the first independently certified same-instruction gfx950/gfx1250
    /// memory conflict. Default retains complete traces; never accepts early.
    #[arg(long)]
    pub(crate) early_memory_conflicts: bool,

    /// Global array: "name:base:elem_width:len:kind" where kind is
    /// in|out|inout|index (e.g. "in:0x10000:4:128:in"). Repeatable.
    #[arg(long = "array")]
    arrays: Vec<String>,

    /// Kernel parameter (in declaration order): "int:N", "float:X",
    /// "sym:name", or "ptr:array_name". Repeatable.
    #[arg(long = "param")]
    params: Vec<String>,

    /// Module-scope .global variable value: "NAME=value". Repeatable.
    #[arg(long = "global")]
    globals: Vec<String>,

    /// Dynamic (extern) shared memory size in bytes
    #[arg(long, default_value_t = 0)]
    dyn_shared: u64,

    /// Native LDS source-allocation premise: "name:offset:size" in bytes.
    /// Repeat for disjoint named regions. PTX rejects this option.
    #[arg(long = "shared-allocation")]
    shared_allocations: Vec<String>,
}

/// Parse "x[,y[,z]]" dimensions.
pub(crate) fn parse_dims(s: &str) -> Result<(u32, u32, u32), String> {
    let mut dims = [1; 3];
    for (axis, part) in s.split(',').enumerate() {
        let dim = dims
            .get_mut(axis)
            .ok_or("expected one to three comma-separated dimensions")?;
        *dim = part.trim().parse::<u32>().map_err(|e| e.to_string())?;
    }
    Ok((dims[0], dims[1], dims[2]))
}

fn parse_workgroup_id(value: &str) -> Result<(u32, u32, u32), String> {
    let fields: Vec<_> = value.split(',').collect();
    let [x, y, z] = fields.as_slice() else {
        return Err("expected exactly three coordinates X,Y,Z".into());
    };
    let parse = |field: &str| field.trim().parse::<u32>().map_err(|e| e.to_string());
    Ok((parse(x)?, parse(y)?, parse(z)?))
}

pub(crate) fn parse_u64_value(s: &str) -> Result<u64, String> {
    if let Some(hex) = s.strip_prefix("0x") {
        u64::from_str_radix(hex, 16).map_err(|e| e.to_string())
    } else {
        s.parse()
            .map_err(|e: std::num::ParseIntError| e.to_string())
    }
}

/// Parse "name:base:elem_width:len:kind".
fn parse_array(s: &str) -> Result<ArrayDef, String> {
    let parts: Vec<&str> = s.split(':').collect();
    let [name, base, elem_width, len, kind] = parts.as_slice() else {
        return Err(format!(
            "expected name:base:elem_width:len:kind, got '{}'",
            s
        ));
    };
    let kind = match *kind {
        "in" => ArrayKind::Input,
        "out" => ArrayKind::Output,
        "inout" => ArrayKind::InputOutput,
        "index" => ArrayKind::IndexInput,
        other => return Err(format!("unknown array kind '{}'", other)),
    };
    Ok(ArrayDef {
        name: name.to_string(),
        base: parse_u64_value(base)?,
        elem_width: parse_u64_value(elem_width)?,
        len: parse_u64_value(len)?,
        kind,
    })
}

/// Parse "int:N" | "float:X" | "sym:name" | "ptr:array".
fn parse_param(s: &str) -> Result<ParamValue, String> {
    let Some((kind, value)) = s.split_once(':') else {
        return Err(format!("expected kind:value, got '{}'", s));
    };
    match kind {
        "int" => Ok(ParamValue::Int(
            value.parse().map_err(|e| format!("{}", e))?,
        )),
        "float" => Ok(ParamValue::Float(
            value.parse().map_err(|e| format!("{}", e))?,
        )),
        "sym" => Ok(ParamValue::SymFloat(value.to_string())),
        "ptr" => Ok(ParamValue::ArrayPtr(value.to_string())),
        other => Err(format!("unknown param kind '{}'", other)),
    }
}

/// The launch `--config` or the flags describe; only a launch file names a kernel or a spec,
/// whose path is resolved here against the launch file's directory.
pub(crate) fn launch_config(launch: &LaunchArgs) -> Result<LaunchFile, String> {
    let Some(path) = &launch.config else {
        return build_config(launch).map(|config| LaunchFile {
            kernel: None,
            spec: None,
            config,
        });
    };
    let text =
        std::fs::read_to_string(path).map_err(|e| format!("read {}: {}", path.display(), e))?;
    let mut file =
        LaunchFile::from_json(&text).map_err(|e| format!("{}: {}", path.display(), e))?;
    if let (Some(spec), Some(dir)) = (&mut file.spec, path.parent()) {
        spec.path = dir.join(&spec.path);
    }
    Ok(file)
}

/// `launch_config` for `command`, which never reads a spec from the launch file.
pub(crate) fn launch_config_without_spec(
    launch: &LaunchArgs,
    command: &str,
) -> Result<LaunchFile, String> {
    let file = launch_config(launch)?;
    match &file.spec {
        Some(spec) => Err(format!(
            "the launch file names spec {}, which `volta {command}` does not read: check it with \
             `volta solve`, or drop its \"spec\" and \"dims\"",
            spec.path.display()
        )),
        None => Ok(file),
    }
}

fn build_config(input: &LaunchArgs) -> Result<AnalysisConfig, String> {
    let block_dim = parse_dims(&input.block).map_err(|e| format!("invalid --block: {}", e))?;
    let mut config = AnalysisConfig::new(block_dim);
    config.grid_dim = parse_dims(&input.grid).map_err(|e| format!("invalid --grid: {}", e))?;
    config.workgroup_id = parse_workgroup_id(&input.workgroup_id)
        .map_err(|e| format!("invalid --workgroup-id: {e}"))?;
    config.early_readiness = input.early_readiness;
    config.early_memory_conflicts = input.early_memory_conflicts;
    config.dynamic_shared_bytes = input.dyn_shared;
    for value in &input.shared_allocations {
        let fields: Vec<_> = value.split(':').collect();
        let [name, offset, size] = fields.as_slice() else {
            return Err(format!(
                "invalid --shared-allocation: expected name:offset:size, got {value:?}"
            ));
        };
        config.shared_allocations.push(SharedAllocation {
            name: (*name).into(),
            offset: parse_u64_value(offset)
                .map_err(|e| format!("invalid --shared-allocation offset: {e}"))?,
            size: parse_u64_value(size)
                .map_err(|e| format!("invalid --shared-allocation size: {e}"))?,
        });
    }
    volta_common::config::validate_shared_allocations(&config.shared_allocations)?;
    for a in &input.arrays {
        config
            .arrays
            .push(parse_array(a).map_err(|e| format!("invalid --array: {}", e))?);
    }
    for p in &input.params {
        config
            .params
            .push(parse_param(p).map_err(|e| format!("invalid --param: {}", e))?);
    }
    for g in &input.globals {
        let (name, value) = g
            .split_once('=')
            .ok_or_else(|| format!("invalid --global (expected NAME=value): {}", g))?;
        let v: i64 = value
            .parse()
            .map_err(|e: std::num::ParseIntError| format!("invalid --global value: {}", e))?;
        config.global_values.push((name.to_string(), v));
    }
    Ok(config)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn launch_dimensions_accept_one_to_three_components() {
        for (input, expected) in [
            ("64", (64, 1, 1)),
            ("8,4", (8, 4, 1)),
            (" 8 , 4 , 2 ", (8, 4, 2)),
        ] {
            assert_eq!(parse_dims(input), Ok(expected));
        }
        for input in [
            "",
            "1,",
            "1,,3",
            "-1",
            "4294967296",
            "1,2,3,4",
            "1,2,3,",
            "1,2,3,x",
        ] {
            assert!(parse_dims(input).is_err(), "{input:?}");
        }
    }
}
