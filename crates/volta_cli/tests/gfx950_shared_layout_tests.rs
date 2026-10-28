//! Optional caller-supplied native LDS object bounds through the public CLI.
use std::{
    path::PathBuf,
    process::{Command, Output},
};

const SOURCE: &str = r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl k
.type k,@function
k:
v_mov_b32 v0, 32
v_mov_b32 v8, 0
ds_write_b32 v0, v8
ds_write_b32 v0, v8 offset:4
ds_write_b32 v0, v8 offset:8
ds_write_b32 v0, v8 offset:12
s_waitcnt lgkmcnt(0)
ds_read_b128 v[12:15], v0
s_waitcnt lgkmcnt(0)
s_endpgm
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 112
.amdhsa_kernarg_size 0
.end_amdhsa_kernel
"#;

fn directory() -> PathBuf {
    let path = std::env::temp_dir().join(format!(
        "gfx950-layout-cli-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    std::fs::create_dir(&path).unwrap();
    path
}
fn run(path: &std::path::Path, regions: &[&str], dump: &std::path::Path) -> Output {
    let mut command = Command::new(env!("CARGO_BIN_EXE_volta"));
    command
        .args([
            "--no-log-file",
            "--backend",
            "amdgpu",
            "--target",
            "gfx950",
            "analyze",
        ])
        .arg(path)
        .args(["--no-profile", "--dump-graph"])
        .arg(dump);
    for region in regions {
        command.args(["--shared-allocation", region]);
    }
    command.output().unwrap()
}

#[test]
fn optional_layout_is_visible_and_rejects_a_vector_straddling_adjacent_objects() {
    let dir = directory();
    let source = dir.join("native.s");
    let dump = dir.join("graph.txt");
    std::fs::write(&source, SOURCE).unwrap();
    for regions in [&[][..], &["A:0:48", "B:0x30:64"][..]] {
        let output = run(&source, regions, &dump);
        assert!(
            output.status.success(),
            "{}\n{}",
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
        let graph = std::fs::read_to_string(&dump).unwrap();
        assert_eq!(
            graph.contains("ConfiguredSharedAllocationLayout"),
            !regions.is_empty()
        );
        if !regions.is_empty() {
            assert!(graph.contains("shared-allocation \"B\" offset=0x30 size=64"));
        }
    }
    let invalid = run(&source, &["A:0:40", "B:40:64"], &dump);
    assert!(!invalid.status.success());
    assert!(String::from_utf8_lossy(&invalid.stdout).contains("configured allocation boundaries"));
    for regions in [
        &["A:0:40", "B:39:64"][..],
        &["A:0:40", "A:40:64"][..],
        &["A:0:0"][..],
        &["A:0:113"][..],
        &["A:0"][..],
    ] {
        assert!(
            !run(&source, regions, &dump).status.success(),
            "{regions:?}"
        );
    }
    std::fs::remove_dir_all(dir).unwrap();
}

#[test]
fn ptx_cli_rejects_the_native_layout_option() {
    let dir = directory();
    let source = dir.join("native.ptx");
    std::fs::write(
        &source,
        ".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }",
    )
    .unwrap();
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "analyze"])
        .arg(source)
        .args(["--shared-allocation", "A:0:40", "--no-profile"])
        .output()
        .unwrap();
    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("shared_allocations"));
    std::fs::remove_dir_all(dir).unwrap();
}
