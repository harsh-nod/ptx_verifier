//! Explicit backend selection on the shared solve/extract paths retains native evidence.
use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
};

use serde_json::json;

const SPEC: &str = "dim N; array x[N]; array out[N]; out[i] = x[i];";

struct Files(PathBuf);
impl Files {
    fn new() -> Self {
        let path = std::env::temp_dir().join(format!(
            "volta-native-frontend-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        fs::create_dir(&path).unwrap();
        Self(path)
    }
    fn path(&self, name: &str) -> PathBuf {
        self.0.join(name)
    }
}
impl Drop for Files {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}
fn source(target: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(match target {
        "gfx942" => "../../tests/gfx942/fixtures/native-copy-add.s",
        "gfx950" => "../volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s",
        "gfx1250" => "../../tests/gfx1250/fixtures/native-copy-add.s",
        _ => unreachable!(),
    })
}
fn command(target: &str, action: &str, source: &Path, size: u32) -> Command {
    let mut command = Command::new(env!("CARGO_BIN_EXE_volta"));
    command.args(["--no-log-file", "--backend", "amdgpu", "--target", target]);
    command.arg(action);
    if action == "extract" {
        command.arg("lean");
    }
    command.arg(source).args(["--kernel", "copy", "--block"]);
    command.arg(size.to_string());
    for (name, base, kind) in [("x", 65536, "in"), ("out", 131072, "out")] {
        command.args(["--array", &format!("{name}:{base}:4:{size}:{kind}")]);
        command.args(["--param", &format!("ptr:{name}")]);
    }
    command.args(["--param", &format!("int:{size}")]);
    command
}
fn text(output: &Output, code: i32) -> String {
    let text = format!(
        "{}\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(output.status.code(), Some(code), "{text}");
    text
}

#[test]
fn shared_commands_keep_all_three_native_targets_and_full_output_footprints() {
    let files = Files::new();
    for (target, size) in [("gfx942", 64), ("gfx950", 64), ("gfx1250", 32)] {
        let exprs = files.path(&format!("{target}.vexpr"));
        let output = command(target, "solve", &source(target), size)
            .args([
                "--spec",
                SPEC,
                "--dim",
                &format!("N={size}"),
                "--emit-exprs",
            ])
            .arg(&exprs)
            .output()
            .unwrap();
        let result = text(&output, 0);
        assert!(result.contains("VERDICT: ACCEPT"), "{result}");
        assert!(result.contains("graph verification"), "{result}");
        assert!(!result.contains("race freedom not checked"), "{result}");
        let outputs = volta_expr::text::read_text(&fs::read_to_string(exprs).unwrap()).unwrap();
        assert_eq!(outputs.outputs[0].1.len(), size as usize);
        let lean = files.path(&format!("{target}.lean"));
        let output = command(target, "extract", &source(target), size)
            .args(["--spec", SPEC, "--dim", &format!("N={size}"), "--output"])
            .arg(&lean)
            .output()
            .unwrap();
        text(&output, 0);
        assert_eq!(
            fs::read_to_string(lean)
                .unwrap()
                .matches(" : Prop :=")
                .count(),
            size as usize
        );
    }
}

#[test]
fn certified_native_prefixes_reject_shared_commands_without_overwriting_artifacts() {
    let files = Files::new();
    for (target, flag, before, after, marker) in [
        (
            "gfx1250",
            "--early-readiness",
            "s_wait_kmcnt 0x0",
            "s_nop 0",
            "EARLY_READINESS: CERTIFIED_REJECTION",
        ),
        (
            "gfx950",
            "--early-memory-conflicts",
            "global_store_dword v[0:1], v2, off",
            "v_mov_b32 v0, 0x20000\n\tv_mov_b32 v1, 0\n\tglobal_store_dword v[0:1], v2, off",
            "EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION",
        ),
    ] {
        let original = fs::read_to_string(source(target)).unwrap();
        assert!(original.contains(before));
        let bad = files.path(&format!("{target}.s"));
        fs::write(&bad, original.replacen(before, after, 1)).unwrap();
        for action in ["solve", "extract"] {
            let artifact = files.path(&format!("{target}-{action}.output"));
            fs::write(&artifact, "existing artifact").unwrap();
            let mut command = command(target, action, &bad, 32);
            command.args(["--spec", SPEC, "--dim", "N=32", flag]);
            command
                .arg(if action == "extract" {
                    "--output"
                } else {
                    "--emit-exprs"
                })
                .arg(&artifact);
            let output = command.output().unwrap();
            let result = text(&output, 1);
            assert!(
                result.contains(marker) && result.contains("VERDICT: REJECT"),
                "{result}"
            );
            assert!(!result.contains("output 'out'"), "{result}");
            assert_eq!(fs::read_to_string(artifact).unwrap(), "existing artifact");
        }
    }
}

#[test]
fn incomplete_native_trace_cannot_extract_lean_or_change_an_existing_file() {
    let files = Files::new();
    let config = files.path("limited.json");
    fs::write(
        &config,
        json!({"kernel":"copy", "block":64, "max_instructions":1,
        "arrays":[{"name":"x","base":65536,"dtype":"f32","len":64,"kind":"in"},
                  {"name":"out","base":131072,"dtype":"f32","len":64,"kind":"out"}],
        "params":[{"ptr":"x"},{"ptr":"out"},{"int":64}]})
        .to_string(),
    )
    .unwrap();
    let lean = files.path("limited.lean");
    fs::write(&lean, "existing proof").unwrap();
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args([
            "--no-log-file",
            "--backend",
            "amdgpu",
            "--target",
            "gfx950",
            "extract",
            "lean",
        ])
        .arg(source("gfx950"))
        .arg("--config")
        .arg(config)
        .args(["--spec", SPEC, "--dim", "N=64", "--output"])
        .arg(&lean)
        .output()
        .unwrap();
    let result = text(&output, 1);
    assert!(result.contains("UNKNOWN"), "{result}");
    assert_eq!(fs::read_to_string(lean).unwrap(), "existing proof");
}

#[test]
fn explicit_native_target_mismatch_is_not_reinterpreted_as_experimental_amd() {
    let output = command("gfx1250", "solve", &source("gfx950"), 32)
        .output()
        .unwrap();
    let result = text(&output, 1);
    assert!(
        result.contains("conflicts with source target gfx950"),
        "{result}"
    );
    assert!(!result.contains("OUTPUTS EXTRACTED"), "{result}");
}
