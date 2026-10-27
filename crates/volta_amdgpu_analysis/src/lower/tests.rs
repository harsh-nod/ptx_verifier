use super::*;
use crate::frontend;

fn program(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n.text\n.type copy,@function\ncopy:\n{body}\n.size copy, .-copy\n"
    )
}

#[test]
fn resolves_forward_branch_and_native_clang_labels() {
    let module = frontend::parse(&program(
        "s_branch .Ldone\nv_mov_b32 v0, 1\n.Ldone:\ns_endpgm",
    ))
    .unwrap();
    let lowered = lower_kernel(&module.kernels[0]).unwrap();
    assert_eq!(
        lowered.instructions[0].operands[0],
        Operand::BranchTarget(2)
    );
    let module = frontend::parse(include_str!("../frontend/fixtures/clang22-copy-add.s")).unwrap();
    for kernel in &module.kernels {
        let lowered = lower_kernel(kernel).unwrap();
        assert!(
            lowered
                .instructions
                .iter()
                .filter(|instruction| instruction.opcode == Opcode::Branch)
                .all(|instruction| matches!(instruction.operands[0], Operand::BranchTarget(_)))
        );
    }
}

#[test]
fn rejects_undefined_and_nonexecutable_branch_destinations() {
    for body in [
        "s_branch missing\ns_endpgm",
        "s_branch .Lend\ns_endpgm\n.Lend:",
    ] {
        let module = frontend::parse(&program(body)).unwrap();
        assert!(lower_kernel(&module.kernels[0]).is_err());
    }
}
