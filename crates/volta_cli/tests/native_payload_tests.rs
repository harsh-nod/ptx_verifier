//! Native aggregates use the exact supplied ABI bytes; PTX rejects this form.
use std::{fs, path::PathBuf, process::Command};

const SOURCE: &str = r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl payload
.type payload,@function
payload:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_mov_b32 v0, 0
v_mov_b32 v1, s7
v_add_u32_e32 v1, 0, v1
global_store_dword v0, v1, s[4:5]
s_endpgm
.amdhsa_kernel payload
.amdhsa_kernarg_size 16
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.kernels:
  - .name: payload
    .symbol: payload.kd
    .kernarg_segment_size: 16
    .args:
      - .offset: 0
        .size: 16
        .value_kind: by_value
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
"#;

fn directory() -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "volta-native-payload-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    fs::create_dir(&path).unwrap();
    path
}

#[test]
fn exact_aggregate_bytes_bind_high_offsets_and_reject_invalid_payloads() {
    let directory = directory();
    let source = directory.join("payload.s");
    let config = directory.join("launch.json");
    fs::write(&source, SOURCE).unwrap();
    let bytes = "[0,0,1,0,0,0,0,0,0,0,0,0,120,86,52,18]";
    let launch = format!(
        r#"{{"block":1,"arrays":[{{"name":"out","base":65536,"kind":"out","dtype":"u32","len":1}}],"params":[{{"bytes":{bytes}}}]}}"#
    );
    fs::write(&config, &launch).unwrap();
    let run = |path: &std::path::Path| {
        Command::new(env!("CARGO_BIN_EXE_volta"))
            .args(["--no-log-file", "--backend", "amdgpu", "verify"])
            .arg(path)
            .arg("dim N; array out[N]; out[i] = 305419896;")
            .args(["--dim", "N=1"])
            .arg("--config")
            .arg(&config)
            .arg("--no-profile")
            .output()
            .unwrap()
    };
    let output = run(&source);
    assert!(
        output.status.success(),
        "{}\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(String::from_utf8_lossy(&output.stdout).contains("VERDICT: ACCEPT"));

    for invalid in [
        launch.replace(bytes, "[0]"),
        launch.replace(bytes, "[]"),
        launch.replace(bytes, "[256]"),
        launch.replace("\"bytes\":", "\"int\":0,\"bytes\":"),
    ] {
        fs::write(&config, invalid).unwrap();
        assert!(!run(&source).status.success());
    }
    fs::write(&config, &launch).unwrap();
    fs::write(&source, SOURCE.replace("by_value", "global_buffer")).unwrap();
    let invalid = run(&source);
    assert!(!invalid.status.success());
    assert!(String::from_utf8_lossy(&invalid.stderr).contains("by_value metadata size"));

    let ptx = directory.join("payload.ptx");
    fs::write(
        &ptx,
        ".version 8.0\n.target sm_80\n.address_size 64\n.visible .entry k(.param .u64 p) { ret; }",
    )
    .unwrap();
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "analyze"])
        .arg(ptx)
        .arg("--config")
        .arg(config)
        .output()
        .unwrap();
    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("native AMD backend"));
    fs::remove_dir_all(directory).unwrap();
}
