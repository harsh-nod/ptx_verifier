//! Native LDS allocation premises through the existing public launch JSON path.
use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
};

use serde_json::{Value, json};

fn directory() -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "volta-gfx1250-launch-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    fs::create_dir(&path).unwrap();
    path
}

fn config(regions: Value) -> Value {
    json!({
        "kernel": "exchange", "block": [64,1,1], "grid": [1,1,1],
        "arrays": [
            {"name":"x", "base":65536, "dtype":"f32", "len":64, "kind":"in"},
            {"name":"out", "base":131072, "dtype":"f32", "len":64, "kind":"out"}
        ],
        "params": [{"ptr":"x"}, {"ptr":"out"}],
        "shared_allocations": regions
    })
}

fn analyze(source: &Path, config: &Path, dump: &Path, backend: &str) -> Output {
    let mut command = Command::new(env!("CARGO_BIN_EXE_volta"));
    command.args(["--no-log-file", "--backend", backend]);
    if backend == "amdgpu" {
        command.args(["--target", "gfx1250"]);
    }
    command
        .arg("analyze")
        .arg(source)
        .arg("--config")
        .arg(config);
    command.args(["--no-profile", "--dump-graph"]).arg(dump);
    command.output().unwrap()
}

#[test]
fn genuine_gfx1250_exchange_retains_json_layout_and_all_output_math() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250");
    let dir = directory();
    let launch = dir.join("launch.json");
    let dump = dir.join("graph.txt");
    let source = root.join("fixtures/native-lds-ids.s");
    fs::write(
        &launch,
        config(json!([{"name":"tile", "offset":0, "size":256}])).to_string(),
    )
    .unwrap();
    let result = analyze(&source, &launch, &dump, "amdgpu");
    assert!(
        result.status.success(),
        "{}\n{}",
        String::from_utf8_lossy(&result.stdout),
        String::from_utf8_lossy(&result.stderr)
    );
    let output = String::from_utf8_lossy(&result.stdout);
    assert!(output.contains("GRAPH VERIFICATION: VERIFIED"));
    assert!(output.contains("output 'out': 64 element(s) written"));
    let graph = fs::read_to_string(&dump).unwrap();
    assert!(graph.contains("ConfiguredSharedAllocationLayout"));
    assert!(graph.contains("shared-allocation \"tile\" offset=0x0 size=256"));
    let verify = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args([
            "--no-log-file",
            "--backend",
            "amdgpu",
            "--target",
            "gfx1250",
            "verify",
        ])
        .arg(&source)
        .arg(root.join("specs/exchange.spec"))
        .arg("--config")
        .arg(&launch)
        .args([
            "--dim",
            "WAVES=2",
            "--dim",
            "LANES=32",
            "--sample",
            "0",
            "--verify-numeric",
        ])
        .output()
        .unwrap();
    assert!(
        verify.status.success(),
        "{}\n{}",
        String::from_utf8_lossy(&verify.stdout),
        String::from_utf8_lossy(&verify.stderr)
    );
    assert!(String::from_utf8_lossy(&verify.stdout).contains("VERDICT: ACCEPT"));
    fs::remove_dir_all(dir).unwrap();
}

#[test]
fn json_layout_outside_capacity_or_omitting_the_last_lds_element_cannot_verify() {
    let source = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../tests/gfx1250/fixtures/native-lds-ids.s");
    let dir = directory();
    for size in [252, 257] {
        let launch = dir.join(format!("launch-{size}.json"));
        let dump = dir.join(format!("graph-{size}.txt"));
        fs::write(
            &launch,
            config(json!([{"name":"tile", "offset":0, "size":size}])).to_string(),
        )
        .unwrap();
        let result = analyze(&source, &launch, &dump, "amdgpu");
        assert!(!result.status.success(), "size={size}");
        let text = format!(
            "{}\n{}",
            String::from_utf8_lossy(&result.stdout),
            String::from_utf8_lossy(&result.stderr)
        );
        assert!(
            text.contains("allocation") || text.contains("LDS"),
            "{text}"
        );
        assert!(!text.contains("GRAPH VERIFICATION: VERIFIED"), "{text}");
    }
    fs::remove_dir_all(dir).unwrap();
}

#[test]
fn ptx_launch_json_still_rejects_native_lds_premises() {
    let dir = directory();
    let source = dir.join("kernel.ptx");
    let launch = dir.join("launch.json");
    fs::write(
        &source,
        ".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }",
    )
    .unwrap();
    fs::write(&launch, json!({"kernel":"k","block":32,"shared_allocations":[{"name":"tile","offset":0,"size":256}]}).to_string()).unwrap();
    let result = analyze(&source, &launch, &dir.join("graph.txt"), "ptx");
    assert!(!result.status.success());
    assert!(String::from_utf8_lossy(&result.stderr).contains("shared_allocations"));
    fs::remove_dir_all(dir).unwrap();
}
