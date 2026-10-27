//! Native compiler assembly through the public CLI and both verification branches.
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

fn fixture() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s")
}

fn run(args: &[String]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "--backend", "amdgpu", "--target", "gfx950"])
        .args(args)
        .output()
        .expect("run volta")
}

fn copy_config(block: u32, n: u32) -> Vec<String> {
    [
        "-b".into(),
        block.to_string(),
        "--array".into(),
        format!("x:0x10000:4:{n}:in"),
        "--array".into(),
        format!("out:0x20000:4:{n}:out"),
        "--param".into(),
        "ptr:x".into(),
        "--param".into(),
        "ptr:out".into(),
        "--param".into(),
        format!("int:{n}"),
        "--no-profile".into(),
    ]
    .into()
}

fn assert_code(output: &Output, code: i32) -> String {
    let stdout = String::from_utf8_lossy(&output.stdout).into_owned();
    assert_eq!(
        output.status.code(),
        Some(code),
        "stdout:\n{stdout}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    stdout
}

fn temporary_directory() -> PathBuf {
    let name = format!(
        "volta-gfx950-cli-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    );
    let path = std::env::temp_dir().join(name);
    std::fs::create_dir(&path).unwrap();
    path
}

#[test]
fn compiler_output_parses_and_copy_verifies_at_wave_boundaries() {
    assert_code(&run(&["parse".into(), fixture().display().to_string()]), 0);
    for block in [1, 63, 64, 65, 128, 256] {
        let n = if block == 128 { 65 } else { block };
        let mut args = vec![
            "verify".into(),
            fixture().display().to_string(),
            "dim N; array x[N]; array out[N]; out[i] = x[i];".into(),
            "-k".into(),
            "copy".into(),
            "--dim".into(),
            format!("N={n}"),
        ];
        args.extend(copy_config(block, n));
        let stdout = assert_code(&run(&args), 0);
        assert!(stdout.contains("VERDICT: ACCEPT"), "{stdout}");
        assert!(
            stdout.contains("AMD wait and register readiness"),
            "{stdout}"
        );
        assert!(!stdout.contains("barrier epochs (mbarrier"), "{stdout}");
    }
}

#[test]
fn native_add_and_packed_xyz_ids_match_independent_specs() {
    let add: Vec<String> = vec![
        "verify".into(),
        fixture().display().to_string(),
        "dim N; array x[N]; array y[N]; array out[N]; out[i] = x[i] + y[i];".into(),
        "-k".into(),
        "add".into(),
        "--dim".into(),
        "N=65".into(),
        "--block".into(),
        "128".into(),
        "--array".into(),
        "x:0x10000:4:65:in".into(),
        "--array".into(),
        "y:0x20000:4:65:in".into(),
        "--array".into(),
        "out:0x30000:4:65:out".into(),
        "--param".into(),
        "ptr:x".into(),
        "--param".into(),
        "ptr:y".into(),
        "--param".into(),
        "ptr:out".into(),
        "--param".into(),
        "int:65".into(),
        "--no-profile".into(),
    ];
    assert!(assert_code(&run(&add), 0).contains("VERDICT: ACCEPT"));

    let ids_source = fixture().with_file_name("clang22-ids-3d.s");
    let ids_spec = "dim X; dim Y; dim Z; array out[Z,Y,X]; out[z,y,x] = x + 10*y + 100*z;";
    let args: Vec<String> = [
        "verify".into(),
        ids_source.display().to_string(),
        ids_spec.into(),
        "-k".into(),
        "ids_3d".into(),
        "--block".into(),
        "4,3,2".into(),
        "--array".into(),
        "out:0x10000:4:24:out".into(),
        "--param".into(),
        "ptr:out".into(),
        "--dim".into(),
        "X=4".into(),
        "--dim".into(),
        "Y=3".into(),
        "--dim".into(),
        "Z=2".into(),
        "--no-profile".into(),
    ]
    .into();
    assert!(assert_code(&run(&args), 0).contains("VERDICT: ACCEPT"));
}

#[test]
fn native_compare_and_both_expression_replay_modes_work() {
    let directory = temporary_directory();
    let expressions = directory.join("copy.vexpr");
    let dump = directory.join("copy.vcdump");
    let mut analyze = vec![
        "analyze".into(),
        fixture().display().to_string(),
        "-k".into(),
        "copy".into(),
        "--emit-exprs".into(),
        expressions.display().to_string(),
    ];
    analyze.extend(copy_config(65, 65));
    let stdout = assert_code(&run(&analyze), 0);
    assert!(
        stdout.contains("output 'out': 65 element(s) written"),
        "{stdout}"
    );
    let mut compare = vec![
        "compare".into(),
        fixture().display().to_string(),
        fixture().display().to_string(),
        "--kernel1".into(),
        "copy".into(),
        "--kernel2".into(),
        "copy".into(),
        "--check-array".into(),
        "out".into(),
        "--dump-vcs".into(),
        dump.display().to_string(),
        "--iterations".into(),
        "2".into(),
    ];
    compare.extend(copy_config(65, 65));
    assert!(assert_code(&run(&compare), 0).contains("VERDICT: ACCEPT"));
    assert_code(
        &run(&[
            "compare".into(),
            "--from-dump".into(),
            dump.display().to_string(),
            "--check-array".into(),
            "out".into(),
        ]),
        0,
    );
    assert_code(
        &run(&[
            "compare".into(),
            "--exprs".into(),
            expressions.display().to_string(),
            expressions.display().to_string(),
            "--check-array".into(),
            "out".into(),
        ]),
        0,
    );
    std::fs::remove_dir_all(directory).unwrap();
}

#[test]
fn missing_native_wait_is_rejected_by_readiness_check() {
    let directory = temporary_directory();
    let bad = directory.join("missing-wait.s");
    let source = std::fs::read_to_string(fixture()).unwrap();
    assert!(source.contains("s_waitcnt vmcnt(0)"));
    std::fs::write(&bad, source.replace("s_waitcnt vmcnt(0)", "s_nop 0")).unwrap();
    let mut args = vec![
        "analyze".into(),
        bad.display().to_string(),
        "-k".into(),
        "copy".into(),
    ];
    args.extend(copy_config(65, 65));
    let stdout = assert_code(&run(&args), 1);
    assert!(
        stdout.contains("AMD wait and register readiness"),
        "{stdout}"
    );
    assert!(stdout.contains("ReadBeforeReady"), "{stdout}");
    assert!(stdout.contains("GRAPH VERIFICATION: REJECTED"), "{stdout}");
    std::fs::remove_dir_all(directory).unwrap();
}

#[test]
fn empty_exec_scalar_writes_still_detect_pending_memory_overwrites() {
    let directory = temporary_directory();
    let source = std::fs::read_to_string(fixture()).unwrap();
    let entry = source.find("\ncopy:").unwrap();
    let begin = entry + source[entry + 1..].find('\n').unwrap() + 2;
    let end = begin + source[begin..].find("\t.section\t.rodata").unwrap();
    let instructions = "s_load_dwordx2 s[2:3], s[0:1], 0\ns_mov_b64 exec, 0\nv_cmp_eq_u32 s[2:3], 0, 0\ns_endpgm\n";
    let bad = directory.join("empty-exec-overwrite.s");
    std::fs::write(
        &bad,
        format!("{}{instructions}{}", &source[..begin], &source[end..]),
    )
    .unwrap();
    let mut args = vec![
        "analyze".into(),
        bad.display().to_string(),
        "-k".into(),
        "copy".into(),
    ];
    args.extend(copy_config(64, 64));
    let stdout = assert_code(&run(&args), 1);
    assert!(stdout.contains("DestinationReuse"), "{stdout}");
    assert!(stdout.contains("GRAPH VERIFICATION: REJECTED"), "{stdout}");
    std::fs::remove_dir_all(directory).unwrap();
}

#[test]
fn sampling_cannot_accept_and_wrong_target_cannot_parse() {
    let mut args = vec![
        "verify".into(),
        fixture().display().to_string(),
        "dim N; array x[N]; array out[N]; out[i] = x[i];".into(),
        "-k".into(),
        "copy".into(),
        "--dim".into(),
        "N=65".into(),
        "--sample".into(),
        "1".into(),
    ];
    args.extend(copy_config(65, 65));
    assert!(assert_code(&run(&args), 2).contains("VERDICT: UNKNOWN"));
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args(["--no-log-file", "parse"])
        .arg(fixture())
        .args(["--backend", "amdgpu", "--target", "gfx942"])
        .output()
        .unwrap();
    assert_code(&output, 1);
    assert!(String::from_utf8_lossy(&output.stderr).contains("requires gfx950"));
}

#[test]
fn native_mfma_matches_math_spec_and_short_delay_is_rejected() {
    let source = fixture().with_file_name("clang22-mfma-f32.s");
    let spec = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx950/mfma-f32.spec");
    let config: Vec<String> = [
        "-b",
        "64",
        "--array",
        "a:0x10000:4:64:in",
        "--array",
        "b:0x20000:4:64:in",
        "--array",
        "out:0x30000:4:256:out",
        "--param",
        "ptr:a",
        "--param",
        "ptr:b",
        "--param",
        "ptr:out",
        "--no-profile",
    ]
    .map(String::from)
    .into();
    let mut args = vec![
        "verify".into(),
        source.display().to_string(),
        spec.display().to_string(),
        "-k".into(),
        "mfma_f32".into(),
        "--verify-numeric".into(),
        "--dim".into(),
        "K=4".into(),
        "--dim".into(),
        "N=16".into(),
        "--dim".into(),
        "G=4".into(),
        "--dim".into(),
        "R=4".into(),
    ];
    args.extend(config.clone());
    assert!(assert_code(&run(&args), 0).contains("VERDICT: ACCEPT"));

    let directory = temporary_directory();
    let bad = directory.join("short-matrix-delay.s");
    let original = std::fs::read_to_string(&source).unwrap();
    assert!(original.contains("s_nop 9"));
    std::fs::write(&bad, original.replace("s_nop 9", "s_nop 8")).unwrap();
    let mut args = vec![
        "analyze".into(),
        bad.display().to_string(),
        "-k".into(),
        "mfma_f32".into(),
    ];
    args.extend(config.clone());
    let stdout = assert_code(&run(&args), 1);
    assert!(stdout.contains("MatrixReadBeforeReady"), "{stdout}");

    let wrong_layout = directory.join("swapped-matrix-inputs.s");
    assert!(original.contains("v[2:5], v2, v3, 0"));
    std::fs::write(
        &wrong_layout,
        original.replace("v[2:5], v2, v3, 0", "v[2:5], v3, v2, 0"),
    )
    .unwrap();
    let mut args = vec![
        "compare".into(),
        source.display().to_string(),
        wrong_layout.display().to_string(),
        "--kernel1".into(),
        "mfma_f32".into(),
        "--kernel2".into(),
        "mfma_f32".into(),
        "--check-array".into(),
        "out".into(),
        "--verify-numeric".into(),
    ];
    args.extend(config);
    let stdout = assert_code(&run(&args), 1);
    assert!(stdout.contains("numeric counterexample"), "{stdout}");
    std::fs::remove_dir_all(directory).unwrap();
}
