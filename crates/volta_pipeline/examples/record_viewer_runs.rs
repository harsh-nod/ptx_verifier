//! Record real PTX/native analysis results for manual or browser viewer checks.
//! Usage: record_viewer_runs STORE NAME BACKEND SOURCE LAUNCH [NAME BACKEND SOURCE LAUNCH ...]
use std::{collections::HashSet, num::NonZeroU32, path::Path};
use volta_graph::{AbortCause, EventGraph};
use volta_graph_check::check_graph;
use volta_ptx_analysis::{AnalysisConfig, LaunchFile, frontend::ascii::AsAscii};
use volta_viz::{Outcome, Run, RunId, write_page, write_run};

fn executed<'a>(
    graph: &'a EventGraph,
    arena: &'a volta_expr::ExprArena,
    report: &'a volta_graph_check::GraphReport,
) -> Outcome<'a> {
    Outcome::Executed {
        graph,
        arena,
        report: Some(report),
    }
}
fn save(
    store: &Path,
    id: &RunId,
    file: &str,
    source: &str,
    outcome: Outcome<'_>,
) -> Result<(), String> {
    write_run(
        store,
        &Run {
            id,
            ptx_file: Some(file),
            source,
            outcome,
        },
    )
    .map_err(|e| e.to_string())
}
fn stopped(
    store: &Path,
    id: &RunId,
    file: &str,
    source: &str,
    error: impl ToString,
) -> Result<(), String> {
    save(
        store,
        id,
        file,
        source,
        Outcome::NotStarted {
            cause: AbortCause::Error,
            error: error.to_string(),
        },
    )
}
fn record(
    store: &Path,
    name: &str,
    backend: &str,
    file: &str,
    launch_path: &str,
) -> Result<(), String> {
    let source = std::fs::read_to_string(file).map_err(|e| e.to_string())?;
    let launch =
        LaunchFile::from_json(&std::fs::read_to_string(launch_path).map_err(|e| e.to_string())?)?;
    let id = RunId {
        suite: "browser_validation".into(),
        test: name.into(),
        ordinal: NonZeroU32::new(1).unwrap(),
    };
    let config: AnalysisConfig = launch.config;
    match backend {
        "amdgpu" => {
            let module = match volta_amdgpu_analysis::frontend::parse(&source) {
                Ok(module) => module,
                Err(error) => {
                    return save(
                        store,
                        &id,
                        file,
                        &source,
                        Outcome::NotStarted {
                            cause: if error.message.starts_with("unsupported ") {
                                AbortCause::Unsupported
                            } else {
                                AbortCause::Error
                            },
                            error: error.to_string(),
                        },
                    );
                }
            };
            match volta_amdgpu_analysis::analyze(&module, launch.kernel.as_deref(), config) {
                Ok(result) => {
                    let report = check_graph(&result.graph);
                    println!("{name}: {:?}", report.conclusion());
                    save(
                        store,
                        &id,
                        file,
                        &source,
                        executed(&result.graph, result.arena(), &report),
                    )
                }
                Err(error) => save(
                    store,
                    &id,
                    file,
                    &source,
                    Outcome::NotStarted {
                        cause: match error {
                            volta_amdgpu_analysis::AnalysisError::Lower(_) => {
                                AbortCause::Unsupported
                            }
                            _ => AbortCause::Error,
                        },
                        error: error.to_string(),
                    },
                ),
            }
        }
        "ptx" => {
            let Some(ascii) = source.as_bytes().as_ascii_slice() else {
                return stopped(store, &id, file, &source, "PTX source must be ASCII");
            };
            let module =
                match volta_ptx_analysis::frontend::parse::Parser::new(ascii).parse_module() {
                    Ok(module) => module,
                    Err(error) => return stopped(store, &id, file, &source, format!("{error:?}")),
                };
            match volta_ptx_analysis::analyze(&module, launch.kernel.as_deref(), config) {
                Ok(result) => {
                    let report = check_graph(&result.graph);
                    println!("{name}: {:?}", report.conclusion());
                    save(
                        store,
                        &id,
                        file,
                        &source,
                        executed(&result.graph, result.arena(), &report),
                    )
                }
                Err(error) => save(
                    store,
                    &id,
                    file,
                    &source,
                    Outcome::NotStarted {
                        cause: match error {
                            volta_ptx_analysis::AnalysisError::Lower(_) => AbortCause::Unsupported,
                            _ => AbortCause::Error,
                        },
                        error: error.to_string(),
                    },
                ),
            }
        }
        _ => Err(format!("unknown backend {backend:?}; use ptx or amdgpu")),
    }
}
fn main() -> Result<(), String> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    if args.len() < 5 || (args.len() - 1) % 4 != 0 {
        return Err("usage: record_viewer_runs STORE NAME BACKEND SOURCE LAUNCH [NAME BACKEND SOURCE LAUNCH ...]".into());
    }
    let store = Path::new(&args[0]);
    let mut names = HashSet::new();
    for args in args[1..].chunks_exact(4) {
        if !names.insert(&args[0]) {
            return Err(format!("duplicate run name {:?}", args[0]));
        }
        record(store, &args[0], &args[1], &args[2], &args[3])?;
    }
    let page = store.join("index.html");
    let runs = write_page(store, &page).map_err(|e| e.to_string())?;
    println!("{runs} recorded runs: {}", page.display());
    Ok(())
}
