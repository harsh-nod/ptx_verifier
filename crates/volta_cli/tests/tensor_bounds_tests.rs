use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
};
const LOAD: &str = "tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]";
fn args(source: &Path) -> Vec<String> {
    vec![
        "analyze".into(),
        source.display().to_string(),
        "--kernel".into(),
        "tensor_roundtrip".into(),
        "--block".into(),
        "64".into(),
        "--array".into(),
        "x:65536:4:128:in".into(),
        "--array".into(),
        "out:131072:4:128:out".into(),
        "--param".into(),
        "ptr:x".into(),
        "--param".into(),
        "ptr:out".into(),
        "--no-profile".into(),
    ]
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
fn certified(o: Output) {
    let text = String::from_utf8_lossy(&o.stdout);
    assert_eq!(
        o.status.code(),
        Some(1),
        "{text}\n{}",
        String::from_utf8_lossy(&o.stderr)
    );
    assert_eq!(
        text.matches("TENSOR_BOUNDS: CERTIFIED_REJECTION").count(),
        1,
        "{text}"
    );
    assert!(
        text.contains("TensorBoundsViolation") && text.contains("VERDICT: REJECT"),
        "{text}"
    );
    assert!(
        text.contains("transfer not issued")
            && !text.contains("VC check:")
            && !text.contains("output 'out'"),
        "{text}"
    );
}
#[test]
fn source_commands_reject_only_certified_bounds_without_exports_or_equivalence() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250");
    let original = root.join("fixtures/native-tensor-roundtrip.s");
    let source = fs::read_to_string(&original).unwrap();
    let dir = std::env::temp_dir().join(format!("volta-tensor-bounds-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let bad = dir.join("bad.s");
    fs::write(
        &bad,
        source.replacen(LOAD, &format!("s_mov_b32 s5, 256\n\t{LOAD}"), 1),
    )
    .unwrap();
    let export = dir.join("bad.vexpr");
    let mut a = args(&bad);
    a.extend(["--emit-exprs".into(), export.display().to_string()]);
    certified(run(&a));
    assert!(!export.exists());
    let mut a = args(&bad);
    a[0] = "verify".into();
    a.insert(
        2,
        root.join("specs/tensor-roundtrip.spec")
            .display()
            .to_string(),
    );
    a.extend(["--dim".into(), "N=128".into()]);
    certified(run(&a));
    for bad_reference in [true, false] {
        let mut a = args(if bad_reference { &bad } else { &original });
        a[0] = "compare".into();
        a.insert(
            2,
            if bad_reference { &original } else { &bad }
                .display()
                .to_string(),
        );
        let index = a.iter().position(|x| x == "--kernel").unwrap();
        a[index] = "--kernel1".into();
        a.extend([
            "--kernel2".into(),
            "tensor_roundtrip".into(),
            "--check-array".into(),
            "out".into(),
        ]);
        certified(run(&a));
    }
    let unsupported = dir.join("unsupported.s");
    fs::write(
        &unsupported,
        source.replacen(LOAD, &format!("s_mov_b32 s20, 1\n\t{LOAD}"), 1),
    )
    .unwrap();
    let o = run(&args(&unsupported));
    let text = String::from_utf8_lossy(&o.stdout);
    assert_eq!(o.status.code(), Some(2), "{text}");
    assert!(!text.contains("CERTIFIED_REJECTION"));
    assert!(text.contains("UNKNOWN"));
    for bad_reference in [true, false] {
        let mut a = args(if bad_reference {
            &unsupported
        } else {
            &original
        });
        a[0] = "compare".into();
        a.insert(
            2,
            if bad_reference {
                &original
            } else {
                &unsupported
            }
            .display()
            .to_string(),
        );
        let index = a.iter().position(|x| x == "--kernel").unwrap();
        a[index] = "--kernel1".into();
        a.extend([
            "--kernel2".into(),
            "tensor_roundtrip".into(),
            "--check-array".into(),
            "out".into(),
        ]);
        let o = run(&a);
        let text = String::from_utf8_lossy(&o.stdout);
        assert_eq!(o.status.code(), Some(2), "{text}");
        assert!(!text.contains("CERTIFIED_REJECTION"));
    }
    fs::remove_dir_all(dir).unwrap();
}
