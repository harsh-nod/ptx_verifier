//! Explicit architecture selection through the native public CLI.
use std::{
    path::PathBuf,
    process::{Command, Output},
};

fn fixture() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx942/fixtures/native-copy-add.s")
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
fn config(block: u32, n: u32) -> Vec<String> {
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
fn genuine_gfx942_copy_parses_and_verifies_complete_wave_boundaries() {
    let parse = code(
        &run("gfx942", &["parse".into(), fixture().display().to_string()]),
        0,
    );
    assert!(parse.contains("(gfx942)"));
    for (block, n) in [(1, 1), (63, 63), (64, 64), (65, 65), (128, 65), (256, 256)] {
        let mut args = vec![
            "verify".into(),
            fixture().display().to_string(),
            "dim N; array x[N]; array out[N]; out[i] = x[i];".into(),
            "--dim".into(),
            format!("N={n}"),
        ];
        args.extend(config(block, n));
        assert!(code(&run("gfx942", &args), 0).contains("VERDICT: ACCEPT"));
    }
}

#[test]
fn requested_and_declared_architectures_cannot_conflict() {
    let output = run("gfx950", &["parse".into(), fixture().display().to_string()]);
    code(&output, 1);
    assert!(
        String::from_utf8_lossy(&output.stderr)
            .contains("selected target gfx950 conflicts with source target gfx942")
    );
    let output = run("gfx940", &["parse".into(), fixture().display().to_string()]);
    code(&output, 1);
    assert!(String::from_utf8_lossy(&output.stderr).contains("expected gfx942 or gfx950"));
}

#[test]
fn gfx942_graph_target_features_and_missing_wait_are_preserved() {
    let directory = std::env::temp_dir().join(format!(
        "volta-gfx942-cli-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    std::fs::create_dir(&directory).unwrap();
    let source = std::fs::read_to_string(fixture())
        .unwrap()
        .replace("gfx942", "gfx942:sramecc+:xnack-");
    for (name, contents, exit, verdict) in [
        ("good", source.clone(), 0, "VERIFIED"),
        (
            "missing-wait",
            source.replace("s_waitcnt vmcnt(0)", "s_nop 0"),
            1,
            "REJECTED",
        ),
    ] {
        let path = directory.join(format!("{name}.s"));
        let dump = directory.join(format!("{name}.graph"));
        std::fs::write(&path, contents).unwrap();
        let mut args = vec![
            "analyze".into(),
            path.display().to_string(),
            "--dump-graph".into(),
            dump.display().to_string(),
        ];
        args.extend(config(128, 65));
        let stdout = code(&run("gfx942", &args), exit);
        assert!(
            stdout.contains(&format!("GRAPH VERIFICATION: {verdict}")),
            "{stdout}"
        );
        if exit == 1 {
            assert!(stdout.contains("ReadBeforeReady"), "{stdout}");
        }
        let graph = std::fs::read_to_string(dump).unwrap();
        assert!(graph.starts_with("volta-graph 2\n"));
        assert!(graph.contains("gfx942:sramecc+:xnack-"));
    }
    std::fs::remove_dir_all(directory).unwrap();
}
