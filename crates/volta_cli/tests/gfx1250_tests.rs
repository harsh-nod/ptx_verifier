//! Real gfx1250 compiler fixtures through the existing public CLI.
use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
};

use serde_json::{Value, json};

fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250")
}

fn directory() -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "volta-gfx1250-cli-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    fs::create_dir(&path).unwrap();
    path
}

fn run(target: &str, args: &[String]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "--backend", "amdgpu", "--target", target])
        .args(args)
        .output()
        .unwrap()
}

fn code(output: &Output, expected: i32) -> String {
    let stdout = String::from_utf8_lossy(&output.stdout).into_owned();
    assert_eq!(
        output.status.code(),
        Some(expected),
        "{stdout}\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    stdout
}

#[test]
fn portable_math_specs_cover_every_configured_output() {
    let manifest: Value =
        serde_json::from_str(&fs::read_to_string(root().join("portable-cases.json")).unwrap())
            .unwrap();
    for case in manifest["cases"].as_array().unwrap() {
        let path = root().join(case["spec"].as_str().unwrap());
        let parsed = volta_spec::parse_spec(&fs::read_to_string(&path).unwrap())
            .unwrap_or_else(|e| panic!("{}: {e:?}", path.display()));
        let dims = case["dimensions"]
            .as_object()
            .unwrap()
            .iter()
            .map(|(name, value)| (name.clone(), value.as_u64().unwrap()))
            .collect::<std::collections::HashMap<_, _>>();
        let (env, specs) = volta_spec::instantiate(&parsed, &dims).unwrap();
        let outputs = volta_spec::unfold(&specs, &env, 0).unwrap();
        let count = outputs
            .outputs
            .iter()
            .map(|(_, elements)| elements.len() as u64)
            .sum::<u64>();
        assert_eq!(
            count,
            case["expected_outputs"].as_u64().unwrap(),
            "{}",
            path.display()
        );
    }
}

fn launch(case: &Value, destination: &Path) {
    let arrays = case["arrays"]
        .as_array()
        .unwrap()
        .iter()
        .map(|a| {
            json!({
                "name": a["name"], "base": a["base_address"], "elem_width": a["element_size"],
                "len": a["length"], "kind": a["kind"]
            })
        })
        .collect::<Vec<_>>();
    let params = case["params"]
        .as_array()
        .unwrap()
        .iter()
        .map(|p| {
            if let Some(p) = p.as_str() {
                let (kind, value) = p.split_once(':').unwrap();
                match kind {
                    "ptr" => json!({"ptr": value}),
                    "int" => json!({"int": value.parse::<i64>().unwrap()}),
                    _ => panic!("unhandled fixture parameter {p}"),
                }
            } else {
                p.clone()
            }
        })
        .collect::<Vec<_>>();
    let mut config = json!({"kernel":case["kernel"], "block":case["block"],
        "grid":case["grid"], "arrays":arrays, "params":params});
    if let Some(bytes) = case.get("dynamic_shared") {
        config["dynamic_shared_bytes"] = bytes.clone();
    }
    if let Some(globals) = case.get("global_values") {
        config["globals"] = globals
            .as_array()
            .unwrap()
            .iter()
            .map(|p| (p[0].as_str().unwrap().to_owned(), p[1].clone()))
            .collect::<serde_json::Map<_, _>>()
            .into();
    }
    fs::write(destination, serde_json::to_string(&config).unwrap()).unwrap();
}

#[test]
fn compiler_corpus_parses_analyzes_and_matches_full_specs_via_launch_json() {
    let manifest: Value =
        serde_json::from_str(&fs::read_to_string(root().join("cases.json")).unwrap()).unwrap();
    let portable: Value =
        serde_json::from_str(&fs::read_to_string(root().join("portable-cases.json")).unwrap())
            .unwrap();
    let cases = manifest["cases"]
        .as_array()
        .unwrap()
        .iter()
        .chain(portable["cases"].as_array().unwrap())
        .collect::<Vec<_>>();
    assert!(!cases.is_empty(), "empty corpus cannot establish support");
    let directory = directory();
    for (index, case) in cases.iter().enumerate() {
        let source = root()
            .join(case["assembly"].as_str().unwrap())
            .display()
            .to_string();
        let config = directory.join(format!("{index}.json"));
        launch(case, &config);
        assert!(code(&run("gfx1250", &["parse".into(), source.clone()]), 0).contains("gfx1250"));
        let analyzed = code(
            &run(
                "gfx1250",
                &[
                    "analyze".into(),
                    source.clone(),
                    "--config".into(),
                    config.display().to_string(),
                    "--no-profile".into(),
                ],
            ),
            0,
        );
        assert!(
            analyzed.contains("GRAPH VERIFICATION: VERIFIED"),
            "{analyzed}"
        );
        for array in case["arrays"]
            .as_array()
            .unwrap()
            .iter()
            .filter(|a| matches!(a["kind"].as_str(), Some("out" | "inout")))
        {
            let footprint = format!(
                "output '{}': {} element(s) written",
                array["name"].as_str().unwrap(),
                array["length"]
            );
            assert!(analyzed.contains(&footprint), "{footprint}\n{analyzed}");
        }
        if let Some(constants) = case.get("expected_constants") {
            for (index, expected) in constants.as_array().unwrap().iter().enumerate() {
                let prefix = format!("out[{index}] = ");
                let actual = analyzed
                    .lines()
                    .find_map(|line| line.trim().strip_prefix(&prefix))
                    .unwrap_or_else(|| panic!("missing {prefix} in {analyzed}"));
                let bits = actual.parse::<i128>().expect("exact integer output") as u64;
                assert_eq!(bits, expected.as_u64().unwrap(), "case {index}: {analyzed}");
            }
            continue;
        }
        let mut args = vec![
            "verify".into(),
            source,
            root()
                .join(case["spec"].as_str().unwrap())
                .display()
                .to_string(),
            "--config".into(),
            config.display().to_string(),
            "--no-profile".into(),
        ];
        for (name, value) in case["dimensions"].as_object().unwrap() {
            args.extend(["--dim".into(), format!("{name}={value}")]);
        }
        assert!(
            code(&run("gfx1250", &args), 0).contains("VERDICT: ACCEPT"),
            "case {index}"
        );
    }
    fs::remove_dir_all(directory).unwrap();
}

fn copy_config(block: u32, n: u32) -> Vec<String> {
    vec![
        "--kernel".into(),
        "copy".into(),
        "--block".into(),
        block.to_string(),
        "--array".into(),
        format!("x:0x10000:4:{n}:in"),
        "--array".into(),
        format!("out:0x30000:4:{n}:out"),
        "--param".into(),
        "ptr:x".into(),
        "--param".into(),
        "ptr:out".into(),
        "--param".into(),
        format!("int:{n}"),
        "--no-profile".into(),
    ]
}

#[test]
fn wave32_tails_cover_every_output_and_target_selection_rejects_neighbors() {
    let source = root()
        .join("fixtures/native-copy-add.s")
        .display()
        .to_string();
    for block in [1, 31, 32, 33, 63, 64, 65, 128] {
        let n = if block == 128 { 65 } else { block };
        let mut args = vec![
            "verify".into(),
            source.clone(),
            "dim N; array x[N]; array out[N]; out[i] = x[i];".into(),
            "--dim".into(),
            format!("N={n}"),
        ];
        args.extend(copy_config(block, n));
        assert!(code(&run("gfx1250", &args), 0).contains("VERDICT: ACCEPT"));
    }
    for target in ["gfx942", "gfx950", "gfx1251", "gfx1250-strict"] {
        let out = run(target, &["parse".into(), source.clone()]);
        code(&out, 1);
        let stderr = String::from_utf8_lossy(&out.stderr);
        assert!(
            stderr.contains("conflicts with source") || stderr.contains("unsupported AMD target"),
            "{stderr}"
        );
    }
}

#[test]
fn compare_expression_vc_and_graph_artifacts_preserve_native_wave32_results() {
    let directory = directory();
    let source = root()
        .join("fixtures/native-copy-add.s")
        .display()
        .to_string();
    let expressions = directory.join("copy.vexpr");
    let graph = directory.join("copy.graph");
    let vcs = directory.join("copy.vcdump");
    let mut args = vec![
        "analyze".into(),
        source.clone(),
        "--emit-exprs".into(),
        expressions.display().to_string(),
        "--dump-graph".into(),
        graph.display().to_string(),
    ];
    args.extend(copy_config(65, 65));
    assert!(code(&run("gfx1250", &args), 0).contains("65 element(s) written"));
    let dump = fs::read_to_string(&graph).unwrap();
    assert!(dump.contains("gfx1250"), "{dump}");
    let mut compare = vec![
        "compare".into(),
        source.clone(),
        source,
        "--kernel1".into(),
        "copy".into(),
        "--kernel2".into(),
        "copy".into(),
        "--check-array".into(),
        "out".into(),
        "--dump-vcs".into(),
        vcs.display().to_string(),
        "--verify-numeric".into(),
        "--iterations".into(),
        "2".into(),
        "--recycle-terms".into(),
        "16".into(),
    ];
    let mut config = copy_config(65, 65);
    config.drain(0..2); // compare selects its two kernel entries explicitly.
    compare.extend(config);
    compare.extend(["--block2".into(), "128".into()]);
    assert!(code(&run("gfx1250", &compare), 0).contains("VERDICT: ACCEPT"));
    for replay in [
        vec![
            "compare".into(),
            "--from-dump".into(),
            vcs.display().to_string(),
        ],
        vec![
            "compare".into(),
            "--exprs".into(),
            expressions.display().to_string(),
            expressions.display().to_string(),
        ],
    ] {
        let mut args = replay;
        args.extend(["--check-array".into(), "out".into()]);
        let replay = code(&run("gfx1250", &args), 0);
        assert!(replay.contains("EQUIVALENT"), "{replay}");
        assert!(replay.contains("no graph property was checked"), "{replay}");
    }
    fs::remove_dir_all(directory).unwrap();
}

#[test]
fn wave32_profiles_and_run_logs_preserve_success_and_typed_failure() {
    let directory = directory();
    let source = root().join("fixtures/native-copy-add.s");
    let bad = directory.join("missing-load-wait.s");
    fs::write(
        &bad,
        fs::read_to_string(&source)
            .unwrap()
            .replace("s_wait_loadcnt 0x0", "s_nop 0"),
    )
    .unwrap();
    for (name, source, expected) in [("good", source, 0), ("bad", bad, 1)] {
        let logs = directory.join(format!("{name}-logs"));
        let graph = directory.join(format!("{name}.graph"));
        let mut args = vec![
            "--backend".into(),
            "amdgpu".into(),
            "--target".into(),
            "gfx1250".into(),
            "--log-dir".into(),
            logs.display().to_string(),
            "analyze".into(),
            source.display().to_string(),
            "--dump-graph".into(),
            graph.display().to_string(),
        ];
        args.extend(copy_config(65, 65));
        args.retain(|arg| arg != "--no-profile");
        let output = Command::new(env!("CARGO_BIN_EXE_volta"))
            .args(args)
            .output()
            .unwrap();
        let stdout = code(&output, expected);
        assert!(stdout.contains("instruction profile:"), "{stdout}");
        assert!(stdout.contains("65 element(s) written"), "{stdout}");
        let graph = fs::read_to_string(graph).unwrap();
        assert!(
            graph.starts_with("volta-graph 2\n") && graph.contains("gfx1250"),
            "{graph}"
        );
        let files = fs::read_dir(logs)
            .unwrap()
            .collect::<Result<Vec<_>, _>>()
            .unwrap();
        assert_eq!(files.len(), 1);
        let log = fs::read_to_string(files[0].path()).unwrap();
        assert!(log.contains("--backend amdgpu --target gfx1250"), "{log}");
        assert!(
            log.contains(if expected == 0 {
                "VERIFIED"
            } else {
                "REJECTED"
            }),
            "{log}"
        );
    }
    fs::remove_dir_all(directory).unwrap();
}

#[test]
fn missing_wait_is_rejected_and_sampling_remains_inconclusive() {
    let directory = directory();
    let source = root().join("fixtures/native-copy-add.s");
    let text = fs::read_to_string(&source).unwrap();
    assert!(text.contains("s_wait_loadcnt 0x0"));
    let bad = directory.join("missing-wait.s");
    fs::write(&bad, text.replace("s_wait_loadcnt 0x0", "s_nop 0")).unwrap();
    let mut args = vec!["analyze".into(), bad.display().to_string()];
    args.extend(copy_config(65, 65));
    assert!(code(&run("gfx1250", &args), 1).contains("ReadBeforeReady"));
    let mut args = vec![
        "verify".into(),
        source.display().to_string(),
        "dim N; array x[N]; array out[N]; out[i] = x[i];".into(),
        "--dim".into(),
        "N=65".into(),
        "--sample".into(),
        "1".into(),
    ];
    args.extend(copy_config(65, 65));
    assert!(code(&run("gfx1250", &args), 2).contains("VERDICT: UNKNOWN"));
    fs::remove_dir_all(directory).unwrap();
}
