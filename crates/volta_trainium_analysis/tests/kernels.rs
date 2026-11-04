//! Supported fixtures retain every stage's golden and independent mathematical output.
//! Prospective fixtures instead assert the exact unsupported feature and failure stage.

mod common;

use volta_trainium_analysis::frontend::{ast::Operand, error::ParseError, parse::parse_kernel};
use volta_trainium_analysis::{LowerError, StatementError, lower_kernel};

#[test]
fn the_add_kernel_parses_lowers_and_runs_as_expected() {
    common::check("add", "kernel");
}

#[test]
fn the_sigmoid_kernel_parses_lowers_and_runs_as_expected() {
    common::check("sigmoid", "kernel");
}

#[test]
fn the_transpose_kernel_parses_lowers_and_runs_as_expected() {
    common::check("transpose", "kernel");
}

#[test]
fn the_matmul_kernel_parses_lowers_and_runs_as_expected() {
    common::check("matmul", "kernel");
}

#[test]
fn gemm_relu_parses_its_full_source_but_refuses_unsupported_activation() {
    let parsed = parse_kernel(include_str!("fixtures/gemm_relu.py"), "kernel").unwrap();
    assert_eq!(parsed.to_string(), include_str!("fixtures/gemm_relu.ast"));
    assert_eq!(
        lower_kernel(&parsed).unwrap_err(),
        LowerError::Statement {
            index: 10,
            error: StatementError::UnsupportedActivation(Operand::Member(
                "nki.language.relu".into()
            )),
        }
    );
}

#[test]
fn tiled_copy_refuses_unsupported_loop_before_lowering() {
    assert_eq!(
        parse_kernel(include_str!("fixtures/tiled_copy.py"), "kernel").unwrap_err(),
        ParseError::Syntax {
            line: 11,
            message: "unsupported keyword `for`".into(),
        }
    );
}

#[test]
fn rms_norm_refuses_unsupported_decimal_before_lowering() {
    assert_eq!(
        parse_kernel(include_str!("fixtures/rms_norm.py"), "kernel").unwrap_err(),
        ParseError::Syntax {
            line: 21,
            message: "unsupported number `0.125`".into(),
        }
    );
}
