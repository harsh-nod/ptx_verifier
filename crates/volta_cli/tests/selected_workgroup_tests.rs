//! Selected native groups keep absolute output indices and explicit graph scope.
use serde_json::{Value, json};
use std::{
    fs,
    path::PathBuf,
    process::{Command, Output},
};

struct Files(PathBuf);
impl Files {
    fn new() -> Self {
        let path = std::env::temp_dir().join(format!(
            "volta-selected-group-{}-{}",
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

fn source() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s")
}
fn launch() -> Value {
    json!({"block":64,"grid":[3,1,1],"workgroup_id":[1,0,0],"arrays":[
        {"name":"x","base":65536,"dtype":"f32","len":192,"kind":"in"},
        {"name":"out","base":131072,"dtype":"f32","len":192,"kind":"out"}
    ],"params":[{"ptr":"x"},{"ptr":"out"},{"int":192}]})
}
fn command() -> Command {
    let mut c = Command::new(env!("CARGO_BIN_EXE_volta"));
    c.args(["--no-log-file", "--backend", "amdgpu", "--target", "gfx950"]);
    c
}
fn diagnostic(output: &Output) -> String {
    format!(
        "{}\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    )
}

#[test]
fn json_and_flags_select_the_same_absolute_copy_tile_and_record_scope() {
    let files = Files::new();
    let config = files.path("launch.json");
    let graph = files.path("copy.graph");
    let exprs = files.path("copy.vexpr");
    fs::write(&config, launch().to_string()).unwrap();
    let result = command()
        .arg("analyze")
        .arg(source())
        .args([
            "--kernel",
            "copy",
            "--no-profile",
            "--print-outputs",
            "1",
            "--config",
        ])
        .arg(&config)
        .arg("--dump-graph")
        .arg(&graph)
        .arg("--emit-exprs")
        .arg(&exprs)
        .output()
        .unwrap();
    assert!(result.status.success(), "{}", diagnostic(&result));
    let text = diagnostic(&result);
    assert!(text.contains("selected workgroup: (1, 0, 0)"), "{text}");
    assert!(text.contains("inter-workgroup conflicts are outside this result"));
    assert!(text.contains("out[64] = x[64]"), "{text}");
    assert!(
        fs::read_to_string(graph)
            .unwrap()
            .contains("workgroup 1,0,0")
    );
    let output = volta_expr::text::read_text(&fs::read_to_string(exprs).unwrap()).unwrap();
    assert_eq!(
        output.outputs[0]
            .1
            .iter()
            .map(|(index, _)| *index)
            .collect::<Vec<_>>(),
        (64..128).collect::<Vec<_>>()
    );
    let flags = command()
        .arg("analyze")
        .arg(source())
        .args([
            "--kernel",
            "copy",
            "--no-profile",
            "--print-outputs",
            "1",
            "--block",
            "64",
            "--grid",
            "3",
            "--workgroup-id",
            "1,0,0",
            "--array",
            "x:65536:4:192:in",
            "--array",
            "out:131072:4:192:out",
            "--param",
            "ptr:x",
            "--param",
            "ptr:out",
            "--param",
            "int:192",
        ])
        .output()
        .unwrap();
    assert!(flags.status.success(), "{}", diagnostic(&flags));
    assert!(diagnostic(&flags).contains("out[64] = x[64]"));
}

#[test]
fn a_selected_tile_cannot_pass_a_whole_array_spec_even_when_sampling() {
    let files = Files::new();
    let config = files.path("launch.json");
    let spec = files.path("copy.spec");
    fs::write(&config, launch().to_string()).unwrap();
    fs::write(&spec, "dim N; array x[N]; array out[N]; out[i]=x[i];").unwrap();
    let result = command()
        .arg("verify")
        .arg(source())
        .arg(spec)
        .args(["--kernel", "copy", "--no-profile", "--config"])
        .arg(config)
        .args(["--dim", "N=192", "--sample", "1"])
        .output()
        .unwrap();
    assert!(!result.status.success());
    assert!(
        diagnostic(&result).contains("128 never written"),
        "{}",
        diagnostic(&result)
    );
}

#[test]
fn grid_override_and_malformed_coordinates_cannot_change_selection_silently() {
    let files = Files::new();
    let config = files.path("launch.json");
    fs::write(&config, launch().to_string()).unwrap();
    let compared = command()
        .arg("compare")
        .arg(source())
        .arg(source())
        .args([
            "--kernel1",
            "copy",
            "--kernel2",
            "copy",
            "--check-array",
            "out",
            "--no-profile",
            "--config",
        ])
        .arg(&config)
        .args(["--grid2", "1"])
        .output()
        .unwrap();
    assert!(!compared.status.success());
    assert!(
        diagnostic(&compared).contains("workgroup_id.x"),
        "{}",
        diagnostic(&compared)
    );
    for coordinate in ["1", "1,0", "1,0,0,0", "-1,0,0", "4294967296,0,0"] {
        let result = command()
            .arg("analyze")
            .arg(source())
            .args(["--workgroup-id", coordinate])
            .output()
            .unwrap();
        assert!(!result.status.success(), "{coordinate}");
    }
    let conflict = command()
        .arg("analyze")
        .arg(source())
        .arg("--config")
        .arg(config)
        .args(["--workgroup-id", "1,0,0"])
        .output()
        .unwrap();
    assert!(!conflict.status.success());
    assert!(diagnostic(&conflict).contains("cannot be used"));
}

#[test]
fn ptx_rejects_a_nonzero_native_group_selection() {
    let files = Files::new();
    let ptx = files.path("k.ptx");
    fs::write(
        &ptx,
        ".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }\n",
    )
    .unwrap();
    let result = Command::new(env!("CARGO_BIN_EXE_volta"))
        .arg("--no-log-file")
        .arg("analyze")
        .arg(ptx)
        .args(["--grid", "2", "--workgroup-id", "1,0,0", "--no-profile"])
        .output()
        .unwrap();
    assert!(!result.status.success());
    assert!(
        diagnostic(&result).contains("workgroup_id"),
        "{}",
        diagnostic(&result)
    );
}
