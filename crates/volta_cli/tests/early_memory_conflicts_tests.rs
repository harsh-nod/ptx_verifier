//! Public marker belongs only to an independently validated pipeline finding.
use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
};

fn directory() -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "volta-memory-prefix-{}-{}",
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
fn original(target: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(if target == "gfx1250" {
        "../../tests/gfx1250/fixtures/native-copy-add.s"
    } else {
        "../volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s"
    })
}
fn collision(target: &str) -> String {
    let source = fs::read_to_string(original(target)).unwrap();
    let (op, replacement) = if target == "gfx1250" {
        (
            "global_store_b32 v0, v1, s[2:3] scale_offset",
            "v_mov_b32 v0, 0\n\tglobal_store_b32 v0, v1, s[2:3] scale_offset",
        )
    } else {
        (
            "global_store_dword v[0:1], v2, off",
            "v_mov_b32 v0, 0x20000\n\tv_mov_b32 v1, 0\n\tglobal_store_dword v[0:1], v2, off",
        )
    };
    assert!(source.contains(op));
    source.replacen(op, replacement, 1)
}
fn args(source: &Path, early: bool) -> Vec<String> {
    let mut a = vec![
        "analyze".into(),
        source.display().to_string(),
        "--kernel".into(),
        "copy".into(),
        "--block".into(),
        "32".into(),
        "--array".into(),
        "x:65536:4:32:in".into(),
        "--array".into(),
        "out:131072:4:32:out".into(),
        "--param".into(),
        "ptr:x".into(),
        "--param".into(),
        "ptr:out".into(),
        "--param".into(),
        "int:32".into(),
        "--no-profile".into(),
    ];
    if early {
        a.push("--early-memory-conflicts".into());
    }
    a
}
fn certified(output: &Output) {
    let text = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        output.status.code(),
        Some(1),
        "{text}\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    for expected in [
        "EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION",
        "AMD memory-conflict freedom (certified prefix) FAIL",
        "MemoryConflict { kind: WriteWrite",
        "ByteLocation { space: Global, addr: 131072 }",
        "earlier: EventId(",
        "later: EventId(",
        "earlier_thread=ThreadIx(",
        "later_thread=ThreadIx(",
        "prefix: instructions=",
        "amd_records=",
        "graph_events=",
        "VERDICT: REJECT\n",
        "complete outputs and equivalence unavailable",
    ] {
        assert!(text.contains(expected), "missing {expected}: {text}");
    }
    assert!(
        !text.contains("UNKNOWN")
            && !text.contains("output 'out'")
            && !text.contains("Equivalence: PASS"),
        "{text}"
    );
}
#[test]
fn analyze_verify_and_both_compare_sides_short_circuit_without_outputs_or_vcs() {
    let d = directory();
    for target in ["gfx950", "gfx1250"] {
        let bad = d.join(format!("{target}-bad.s"));
        fs::write(&bad, collision(target)).unwrap();
        let expression = d.join(format!("{target}.vexpr"));
        let mut a = args(&bad, true);
        a.extend(["--emit-exprs".into(), expression.display().to_string()]);
        certified(&run(target, &a));
        assert!(!expression.exists());
        let spec = d.join("copy.spec");
        fs::write(&spec, "dim N; array x[N]; array out[N]; out[i]=x[i];").unwrap();
        let mut a = args(&bad, true);
        a[0] = "verify".into();
        a.insert(2, spec.display().to_string());
        a.extend(["--dim".into(), "N=32".into()]);
        certified(&run(target, &a));
        for reference_bad in [false, true] {
            let (first, second) = if reference_bad {
                (bad.clone(), original(target))
            } else {
                (original(target), bad.clone())
            };
            let mut a = args(&first, true);
            a[0] = "compare".into();
            a.insert(2, second.display().to_string());
            let k = a.iter().position(|value| value == "--kernel").unwrap();
            a[k] = "--kernel1".into();
            let vcs = d.join(format!("{target}-{reference_bad}.vcs"));
            a.extend([
                "--kernel2".into(),
                "copy".into(),
                "--check-array".into(),
                "out".into(),
                "--dump-vcs".into(),
                vcs.display().to_string(),
            ]);
            certified(&run(target, &a));
            assert!(!vcs.exists());
        }
        let ordinary = run(target, &args(&bad, false));
        let text = String::from_utf8_lossy(&ordinary.stdout);
        assert_eq!(ordinary.status.code(), Some(1), "{text}");
        assert!(!text.contains("EARLY_MEMORY_CONFLICTS:"));
        assert!(text.contains("AMD trace completeness"), "{text}");
    }
    fs::remove_dir_all(d).unwrap();
}
#[test]
fn json_preserves_option_and_default_safe_artifacts_match() {
    let d = directory();
    for target in ["gfx950", "gfx1250"] {
        let bad = d.join(format!("{target}.s"));
        fs::write(&bad, collision(target)).unwrap();
        let launch = d.join("launch.json");
        fs::write(&launch, r#"{"kernel":"copy","block":32,"early_memory_conflicts":true,"arrays":[{"name":"x","base":65536,"dtype":"f32","len":32,"kind":"in"},{"name":"out","base":131072,"dtype":"f32","len":32,"kind":"out"}],"params":[{"ptr":"x"},{"ptr":"out"},{"int":32}]}"#).unwrap();
        certified(&run(
            target,
            &[
                "analyze".into(),
                bad.display().to_string(),
                "--config".into(),
                launch.display().to_string(),
                "--no-profile".into(),
            ],
        ));
        let mut mixed = args(&bad, true);
        mixed.extend(["--config".into(), launch.display().to_string()]);
        assert!(!run(target, &mixed).status.success());
        let mut artifacts = Vec::new();
        for enabled in [false, true] {
            let graph = d.join(format!("{target}-{enabled}.graph"));
            let expr = d.join(format!("{target}-{enabled}.vexpr"));
            let mut a = args(&original(target), enabled);
            a.extend([
                "--dump-graph".into(),
                graph.display().to_string(),
                "--emit-exprs".into(),
                expr.display().to_string(),
            ]);
            let output = run(target, &a);
            let text = String::from_utf8_lossy(&output.stdout);
            assert!(
                output.status.success(),
                "{text}\n{}",
                String::from_utf8_lossy(&output.stderr)
            );
            assert!(
                text.contains("output 'out': 32 element(s) written")
                    && !text.contains("CERTIFIED_REJECTION")
            );
            artifacts.push((fs::read(graph).unwrap(), fs::read(expr).unwrap()));
        }
        assert_eq!(artifacts[0], artifacts[1]);
    }
    fs::remove_dir_all(d).unwrap();
}
#[test]
fn unsupported_targets_and_flag_or_json_replay_refuse_without_marker() {
    let d = directory();
    let ptx = d.join("minimal.ptx");
    fs::write(
        &ptx,
        ".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }",
    )
    .unwrap();
    let out = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "analyze"])
        .arg(&ptx)
        .args(["--early-memory-conflicts", "--no-profile"])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&out.stderr).contains("early_memory_conflicts"));
    let gfx942 = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../tests/gfx942/fixtures/native-copy-add.s");
    let out = run("gfx942", &args(&gfx942, true));
    assert_eq!(out.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&out.stderr).contains("early_memory_conflicts"));
    for dump in [false, true] {
        for json in [false, true] {
            let mut a = vec!["compare".into(), "--check-array".into(), "out".into()];
            if dump {
                a.extend(["--from-dump".into(), "absent.vcs".into()]);
            } else {
                a.extend([
                    "absent.vexpr".into(),
                    "absent2.vexpr".into(),
                    "--exprs".into(),
                ]);
            }
            if json {
                let launch = d.join("enabled.json");
                fs::write(&launch, r#"{"block":32,"early_memory_conflicts":true}"#).unwrap();
                a.extend(["--config".into(), launch.display().to_string()]);
            } else {
                a.push("--early-memory-conflicts".into());
            }
            let out = run("gfx1250", &a);
            let err = String::from_utf8_lossy(&out.stderr);
            assert_eq!(out.status.code(), Some(1));
            assert!(err.contains("requires native source execution"), "{err}");
            assert!(!String::from_utf8_lossy(&out.stdout).contains("CERTIFIED_REJECTION"));
        }
    }
    // Disabled JSON preserves the old replay behavior: launch dimensions are
    // irrelevant and the missing expression input remains the reported error.
    let launch = d.join("disabled.json");
    fs::write(
        &launch,
        r#"{"block":"not-a-launch","early_memory_conflicts":false}"#,
    )
    .unwrap();
    let out = run(
        "gfx1250",
        &[
            "compare".into(),
            "absent.vexpr".into(),
            "absent2.vexpr".into(),
            "--exprs".into(),
            "--check-array".into(),
            "out".into(),
            "--config".into(),
            launch.display().to_string(),
        ],
    );
    assert!(String::from_utf8_lossy(&out.stderr).contains("absent.vexpr"));
    fs::remove_dir_all(d).unwrap();
}
