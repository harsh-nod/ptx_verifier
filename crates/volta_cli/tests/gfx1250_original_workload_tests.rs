//! Original-shape registrations exercise the existing public CLI without sampling.
use std::{collections::BTreeMap, fs, path::PathBuf, process::Command};

use serde_json::Value;
use volta_expr::text::read_text;

fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250/full")
}
fn directory() -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "gfx1250-original-cli-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    fs::create_dir(&path).unwrap();
    path
}
fn invoke(arguments: &[String], code: i32) -> String {
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args([
            "--no-log-file",
            "--backend",
            "amdgpu",
            "--target",
            "gfx1250",
        ])
        .args(arguments)
        .output()
        .unwrap();
    let text = String::from_utf8_lossy(&output.stdout).into_owned();
    assert_eq!(
        output.status.code(),
        Some(code),
        "{arguments:?}\n{text}\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    text
}
fn cases() -> Vec<Value> {
    let manifest: Value =
        serde_json::from_str(&fs::read_to_string(root().join("cases.json")).unwrap()).unwrap();
    let cases = manifest["cases"].as_array().unwrap().clone();
    assert!(!cases.is_empty(), "zero registrations do not pass");
    assert_eq!(
        manifest["required_baseline_ids"].as_array().unwrap().len(),
        32
    );
    assert_eq!(
        cases.len() + manifest["pending_baseline_ids"].as_array().unwrap().len(),
        32
    );
    if std::env::var_os("VOLTA_GFX1250_ORIGINAL_FULL").is_some() {
        assert!(
            manifest["pending_baseline_ids"]
                .as_array()
                .unwrap()
                .is_empty(),
            "full32 workflow gate requires all original registrations"
        );
        cases
    } else {
        let cases: Vec<_> = cases
            .into_iter()
            .filter(|c| c["baseline_id"].as_str().unwrap() <= "W18")
            .collect();
        assert_eq!(
            cases.len(),
            18,
            "fast gate requires every first-family original case"
        );
        cases
    }
}

#[test]
fn selected_original_cases_keep_every_output_index_and_full_numeric_spec() {
    let root = root();
    let dir = directory();
    for case in cases() {
        let name = case["kernel"].as_str().unwrap();
        let source = root
            .join(case["assembly"].as_str().unwrap())
            .display()
            .to_string();
        let config = root
            .join(case["launch_config"].as_str().unwrap())
            .display()
            .to_string();
        invoke(&["parse".into(), source.clone()], 0);
        let expressions = dir.join(format!("{name}.vexpr"));
        let graph = dir.join(format!("{name}.graph"));
        let text = invoke(
            &[
                "analyze".into(),
                source.clone(),
                "--config".into(),
                config.clone(),
                "--emit-exprs".into(),
                expressions.display().to_string(),
                "--dump-graph".into(),
                graph.display().to_string(),
            ],
            0,
        );
        assert!(
            text.contains("GRAPH VERIFICATION: VERIFIED"),
            "{name}: {text}"
        );
        assert!(fs::read_to_string(&graph).unwrap().contains("gfx1250"));
        let actual = read_text(&fs::read_to_string(&expressions).unwrap()).unwrap();
        let mut expected: BTreeMap<String, Vec<u64>> = BTreeMap::new();
        for projection in case["output_projection"].as_array().unwrap() {
            let start = projection["native_start"].as_u64().unwrap();
            let length = projection["length"].as_u64().unwrap();
            expected
                .entry(projection["native_array"].as_str().unwrap().into())
                .or_default()
                .extend(start..start + length);
        }
        for indices in expected.values_mut() {
            indices.sort_unstable();
            assert!(!indices.windows(2).any(|pair| pair[0] == pair[1]));
        }
        let observed: BTreeMap<_, _> = actual
            .outputs
            .iter()
            .map(|(name, values)| {
                (
                    name.clone(),
                    values.iter().map(|(index, _)| *index).collect::<Vec<_>>(),
                )
            })
            .collect();
        assert_eq!(
            observed, expected,
            "{name}: exact output coordinates differ"
        );
        assert_eq!(
            expected.values().map(Vec::len).sum::<usize>() as u64,
            case["expected_outputs"].as_u64().unwrap()
        );
        let mut verify = vec![
            "verify".into(),
            source,
            root.join(case["spec"].as_str().unwrap())
                .display()
                .to_string(),
            "--config".into(),
            config,
            "--sample".into(),
            "0".into(),
            "--verify-numeric".into(),
        ];
        for (dimension, value) in case["dimensions"].as_object().unwrap() {
            verify.extend([
                "--dim".into(),
                format!("{dimension}={}", value.as_u64().unwrap()),
            ]);
        }
        let verdict = invoke(&verify, 0);
        assert!(verdict.contains("VERDICT: ACCEPT"), "{name}: {verdict}");
    }
    fs::remove_dir_all(dir).unwrap();
}

#[test]
fn original_relu_exports_replay_and_full_size_mismatch_keep_honest_verdicts() {
    let root = root();
    let dir = directory();
    let case = cases()
        .into_iter()
        .find(|case| case["baseline_id"] == "W01")
        .unwrap();
    let source = root
        .join(case["assembly"].as_str().unwrap())
        .display()
        .to_string();
    let config = root
        .join(case["launch_config"].as_str().unwrap())
        .display()
        .to_string();
    let expressions = dir.join("relu.vexpr").display().to_string();
    invoke(
        &[
            "analyze".into(),
            source.clone(),
            "--config".into(),
            config.clone(),
            "--emit-exprs".into(),
            expressions.clone(),
        ],
        0,
    );
    let mut pair_launch: Value =
        serde_json::from_str(&fs::read_to_string(&config).unwrap()).unwrap();
    pair_launch.as_object_mut().unwrap().remove("kernel");
    let pair_config = dir.join("compare.json");
    fs::write(
        &pair_config,
        serde_json::to_vec_pretty(&pair_launch).unwrap(),
    )
    .unwrap();
    let config = pair_config.display().to_string();
    let dump = dir.join("relu.vcdump").display().to_string();
    let compare = vec![
        "compare".into(),
        source.clone(),
        source.clone(),
        "--kernel1".into(),
        "relu_f16".into(),
        "--kernel2".into(),
        "relu_f16".into(),
        "--config".into(),
        config.clone(),
        "--check-array".into(),
        "output".into(),
        "--sample".into(),
        "0".into(),
        "--verify-numeric".into(),
        "--iterations".into(),
        "2".into(),
        "--recycle-terms".into(),
        "16".into(),
        "--dump-vcs".into(),
        dump.clone(),
    ];
    assert!(invoke(&compare, 0).contains("VERDICT: ACCEPT"));
    for mut arguments in [
        vec!["compare".into(), "--from-dump".into(), dump],
        vec![
            "compare".into(),
            "--exprs".into(),
            expressions.clone(),
            expressions,
        ],
    ] {
        arguments.extend([
            "--check-array".into(),
            "output".into(),
            "--sample".into(),
            "0".into(),
            "--verify-numeric".into(),
        ]);
        let text = invoke(&arguments, 0);
        assert!(text.contains("EQUIVALENT"), "{text}");
        assert!(!text.contains("GRAPH VERIFICATION:"), "{text}");
    }
    let mismatch = vec![
        "compare".into(),
        source.clone(),
        source,
        "--kernel1".into(),
        "relu_f16".into(),
        "--kernel2".into(),
        "sigmoid_f16".into(),
        "--block2".into(),
        "256".into(),
        "--config".into(),
        config,
        "--check-array".into(),
        "output".into(),
        "--sample".into(),
        "0".into(),
        "--verify-numeric".into(),
    ];
    assert!(invoke(&mismatch, 1).contains("VERDICT: REJECT"));
    fs::remove_dir_all(dir).unwrap();
}
