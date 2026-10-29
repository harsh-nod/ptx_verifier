//! Preserve the exact upstream CLI footprint assertions on genuine native code.
use std::{path::PathBuf, process::Command};

fn verify(kernel: &str, length: u32, sample: u32, expected: i32) -> String {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    let output = Command::new(env!("CARGO_BIN_EXE_volta"))
        .args([
            "--no-log-file",
            "--backend",
            "amdgpu",
            "--target",
            "gfx1250",
            "verify",
        ])
        .arg(root.join("tests/gfx1250/fixtures/native-output-footprint.s"))
        .arg(root.join("crates/volta_cli/tests/ptx/soundness/two_zeroes.spec"))
        .args(["--kernel", kernel, "--block", "1,1,1", "--grid", "1,1,1"])
        .args(["--array", &format!("out:0x20000:4:{length}:out")])
        .args([
            "--param",
            "ptr:out",
            "--dim",
            "N=2",
            "--sample",
            &sample.to_string(),
            "--no-profile",
        ])
        .output()
        .expect("run native Volta CLI");
    let stdout = String::from_utf8_lossy(&output.stdout).into_owned();
    assert_eq!(
        output.status.code(),
        Some(expected),
        "{stdout}\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    stdout
}

#[test]
fn complete_original_footprint_is_accepted_only_without_sampling() {
    assert!(verify("output_complete", 2, 0, 0).contains("VERDICT: ACCEPT"));
    assert!(verify("output_complete", 2, 1, 2).contains("VERDICT: UNKNOWN"));
}

#[test]
fn sampled_and_unsampled_native_partial_output_preserve_upstream_rejection() {
    for sample in [0, 1] {
        let stdout = verify("output_partial", 2, sample, 1);
        assert!(
            stdout.contains(
                "out does not have the same set of indices (1 never written, first out[1]"
            ),
            "{stdout}"
        );
    }
}

#[test]
fn native_same_count_shifted_output_names_both_missing_and_extra_indices() {
    for sample in [0, 1] {
        // The allocation includes index2, so rejection must come from the
        // specification's exact index set rather than a memory-bounds failure.
        let stdout = verify("output_shifted", 3, sample, 1);
        assert!(stdout.contains("out does not have the same set of indices (1 never written, first out[1], 1 written outside it, first out[2])"), "{stdout}");
    }
}
