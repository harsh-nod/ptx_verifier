//! CPU-only full native graph/export measurement; no mathematical proof claim.
use std::num::NonZeroU32;
use std::path::Path;
use std::time::Instant;

use volta_graph::Terminal;
use volta_graph_check::GraphConclusion;
use volta_pipeline::{KernelModule, verify_source_kernel};
use volta_ptx_analysis::LaunchFile;
use volta_viz::{Outcome, Run, RunId, write_page, write_run};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 4 {
        return Err("usage: measure_native_export SOURCE.s LAUNCH.json OUTPUT_DIRECTORY".into());
    }
    let started = Instant::now();
    let source = std::fs::read_to_string(&args[1])?;
    let launch = LaunchFile::from_json(&std::fs::read_to_string(&args[2])?)?;
    let kernel = launch
        .kernel
        .as_deref()
        .ok_or("launch kernel is required")?;
    let module = volta_amdgpu_analysis::frontend::parse(&source)?;
    let verified =
        verify_source_kernel(&KernelModule::Amdgpu(module), Some(kernel), launch.config)?;
    if !matches!(verified.analysis.graph.terminal(), Terminal::Completed)
        || !matches!(verified.graph.conclusion(), GraphConclusion::Verified)
    {
        return Err(format!(
            "graph is incomplete or rejected: {:?}",
            verified.graph.conclusion()
        )
        .into());
    }
    let outputs = verified.analysis.outputs.as_ref().map_err(String::as_str)?;
    let output_count: usize = outputs
        .outputs
        .iter()
        .map(|(_, elements)| elements.len())
        .sum();
    println!(
        "graph_complete=true graph_verified=true events={} amd_events={} outputs={} execute_seconds={:.3}",
        verified.analysis.graph.events().len(),
        verified.analysis.graph.amd_events().len(),
        output_count,
        started.elapsed().as_secs_f64(),
    );
    let id = RunId {
        suite: "gfx1250_full_native".into(),
        test: kernel.into(),
        ordinal: NonZeroU32::MIN,
    };
    let run = Run {
        id: &id,
        ptx_file: Some(&args[1]),
        source: &source,
        outcome: Outcome::Executed {
            graph: &verified.analysis.graph,
            arena: &outputs.arena,
            report: Some(&verified.graph),
        },
    };
    let store = Path::new(&args[3]);
    let export = Instant::now();
    write_run(store, &run)?;
    let document = store.join(format!("{}.json", id.key()));
    println!(
        "export_seconds={:.3} document_bytes={}",
        export.elapsed().as_secs_f64(),
        std::fs::metadata(document)?.len()
    );
    let page = Instant::now();
    let output = store.join("index.html");
    write_page(store, &output)?;
    println!(
        "page_seconds={:.3} page_bytes={}",
        page.elapsed().as_secs_f64(),
        std::fs::metadata(output)?.len()
    );
    Ok(())
}
