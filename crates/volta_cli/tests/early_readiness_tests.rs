//! Explicit certified-prefix CLI signal; ordinary runs retain complete traces.
use std::{
    fs,
    path::PathBuf,
    process::{Command, Output},
};

fn directory() -> PathBuf {
    let p = std::env::temp_dir().join(format!(
        "volta-early-cli-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    fs::create_dir(&p).unwrap();
    p
}
fn run(args: &[String]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_volta"))
        .args([
            "--no-log-file",
            "--backend",
            "amdgpu",
            "--target",
            "gfx1250",
        ])
        .args(args)
        .output()
        .unwrap()
}
fn args(source: &std::path::Path, early: bool) -> Vec<String> {
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
        a.push("--early-readiness".into());
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
    assert!(
        text.contains("EARLY_READINESS: CERTIFIED_REJECTION"),
        "{text}"
    );
    assert!(
        text.contains("AMD wait and register readiness (certified prefix) FAIL"),
        "{text}"
    );
    assert!(
        text.contains("ReadBeforeReady") && text.contains("VERDICT: REJECT\n"),
        "{text}"
    );
    assert!(
        !text.contains("UNKNOWN") && !text.contains("output 'out'"),
        "{text}"
    );
}
#[test]
fn analyze_verify_and_compare_only_render_certified_rejection_after_validation() {
    let d = directory();
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250");
    let original = fs::read_to_string(root.join("fixtures/native-copy-add.s")).unwrap();
    assert!(original.contains("s_wait_kmcnt 0x0"));
    let p = d.join("bad.s");
    fs::write(&p, original.replacen("s_wait_kmcnt 0x0", "s_nop 0", 1)).unwrap();
    let expression = d.join("bad.vexpr");
    let mut a = args(&p, true);
    a.extend(["--emit-exprs".into(), expression.display().to_string()]);
    certified(&run(&a));
    assert!(!expression.exists());
    let mut a = args(&p, true);
    a[0] = "verify".into();
    a.insert(2, root.join("specs/copy.spec").display().to_string());
    a.extend(["--dim".into(), "N=32".into()]);
    certified(&run(&a));
    let mut a = args(&p, true);
    a[0] = "compare".into();
    a.insert(
        2,
        root.join("fixtures/native-copy-add.s")
            .display()
            .to_string(),
    );
    let k = a.iter().position(|v| v == "--kernel").unwrap();
    a[k] = "--kernel1".into();
    a.extend([
        "--kernel2".into(),
        "copy".into(),
        "--check-array".into(),
        "out".into(),
    ]);
    certified(&run(&a));
    let ordinary = run(&args(&p, false));
    let text = String::from_utf8_lossy(&ordinary.stdout);
    assert_eq!(ordinary.status.code(), Some(1), "{text}");
    assert!(!text.contains("EARLY_READINESS:"));
    assert!(
        text.contains("AMD trace completeness") && text.contains("REJECTED"),
        "{text}"
    );
    fs::remove_dir_all(d).unwrap();
}
#[test]
fn json_boolean_enables_the_same_mode_and_safe_outputs_remain_complete() {
    let d = directory();
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250");
    let p = d.join("bad.s");
    let safe = root.join("fixtures/native-copy-add.s");
    fs::write(
        &p,
        fs::read_to_string(&safe)
            .unwrap()
            .replacen("s_wait_kmcnt 0x0", "s_nop 0", 1),
    )
    .unwrap();
    let config = d.join("launch.json");
    fs::write(&config,r#"{"kernel":"copy","block":32,"early_readiness":true,"arrays":[{"name":"x","base":65536,"dtype":"f32","len":32,"kind":"in"},{"name":"out","base":131072,"dtype":"f32","len":32,"kind":"out"}],"params":[{"ptr":"x"},{"ptr":"out"},{"int":32}]}"#).unwrap();
    certified(&run(&[
        "analyze".into(),
        p.display().to_string(),
        "--config".into(),
        config.display().to_string(),
        "--no-profile".into(),
    ]));
    let safe_run = run(&args(&safe, true));
    let text = String::from_utf8_lossy(&safe_run.stdout);
    assert!(
        safe_run.status.success(),
        "{text}\n{}",
        String::from_utf8_lossy(&safe_run.stderr)
    );
    assert!(
        text.contains("output 'out': 32 element(s) written")
            && text.contains("VERIFIED")
            && !text.contains("EARLY_READINESS:"),
        "{text}"
    );
    let mut mixed = args(&safe, true);
    mixed.extend(["--config".into(), config.display().to_string()]);
    assert!(!run(&mixed).status.success());
    fs::remove_dir_all(d).unwrap();
}

#[test]
fn unsupported_backends_and_replay_cannot_silently_ignore_early_readiness() {
    let d = directory();
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    for (backend, target, path) in [
        (
            "amdgpu",
            Some("gfx942"),
            root.join("tests/gfx942/fixtures/native-copy-add.s"),
        ),
        (
            "amdgpu",
            Some("gfx950"),
            root.join("crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s"),
        ),
    ] {
        let mut command = Command::new(env!("CARGO_BIN_EXE_volta"));
        command.args(["--no-log-file", "--backend", backend]);
        if let Some(target) = target {
            command.args(["--target", target]);
        }
        let output = command.args(args(&path, true)).output().unwrap();
        assert_eq!(output.status.code(), Some(1));
        assert!(String::from_utf8_lossy(&output.stderr).contains("early_readiness"));
        assert!(!String::from_utf8_lossy(&output.stdout).contains("CERTIFIED_REJECTION"));
    }
    let p = d.join("minimal.ptx");
    fs::write(
        &p,
        ".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }",
    )
    .unwrap();
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "analyze"])
        .arg(&p)
        .args(["--early-readiness", "--no-profile"])
        .output()
        .unwrap();
    assert_eq!(output.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&output.stderr).contains("early_readiness"));
    assert!(!String::from_utf8_lossy(&output.stdout).contains("CERTIFIED_REJECTION"));
    let replay = run(&[
        "compare".into(),
        "first.vexpr".into(),
        "second.vexpr".into(),
        "--exprs".into(),
        "--check-array".into(),
        "out".into(),
        "--early-readiness".into(),
    ]);
    assert_eq!(replay.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&replay.stderr).contains("requires native source execution"));
    assert!(!String::from_utf8_lossy(&replay.stdout).contains("CERTIFIED_REJECTION"));
    fs::remove_dir_all(d).unwrap();
}
