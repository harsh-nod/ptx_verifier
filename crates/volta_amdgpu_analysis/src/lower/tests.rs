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

#[test]
fn unreachable_undefined_branches_and_relocations_are_statically_rejected() {
    for body in [
        "s_branch .Ldone\ns_branch undefined\n.Ldone:\ns_endpgm",
        "s_mov_b64 exec, 0\ns_branch undefined\ns_endpgm",
        "s_branch .Ldone\ns_getpc_b64 s[2:3]\ns_add_u32 s2, s2, undefined@rel32@lo+4\ns_addc_u32 s3, s3, undefined@rel32@hi+12\n.Ldone:\ns_endpgm",
    ] {
        let module = frontend::parse(&program(body)).unwrap();
        assert!(
            lower_kernel_in_module(&module, &module.kernels[0]).is_err(),
            "{body}"
        );
    }
}

#[test]
fn native_module_relocations_preserve_all_original_instructions() {
    let module = frontend::parse(include_str!(
        "../frontend/fixtures/clang22-module-globals.s"
    ))
    .unwrap();
    let lowered = lower_kernel_in_module(&module, &module.kernels[0]).unwrap();
    assert_eq!(lowered.instructions, module.kernels[0].instructions);
    assert_eq!(lowered.globals, module.globals);
    assert_eq!(lowered.global_address_sequences.len(), 3);
    for (pc, sequence) in lowered.global_address_sequences {
        assert_eq!(pc, sequence.anchor_pc);
        assert_eq!(lowered.instructions[pc].mnemonic, "s_getpc_b64");
    }
    assert!(
        lower_kernel(&module.kernels[0]).is_err(),
        "module context is mandatory"
    );
}

#[test]
fn only_complete_matching_unbranched_address_sequences_can_resolve_objects() {
    let source = include_str!("../frontend/fixtures/clang22-module-globals.s");
    let cases = [
        source.replacen("constant_table@rel32@lo+4", "constant_table@rel32@lo+8", 1),
        source.replacen("constant_table@rel32@hi+12", "constant_table@rel32@hi+4", 1),
        source.replacen("constant_table@rel32@hi+12", "global_bias@rel32@hi+12", 1),
        source
            .replacen("constant_table@rel32@lo+4", "undefined@rel32@lo+4", 1)
            .replacen("constant_table@rel32@hi+12", "undefined@rel32@hi+12", 1),
        source.replacen(
            "s_add_u32 s2, s2, constant_table",
            "s_add_u32 s4, s2, constant_table",
            1,
        ),
        source
            .replacen(
                "s_add_u32 s2, s2, constant_table",
                ".Lmiddle:\n\ts_add_u32 s2, s2, constant_table",
                1,
            )
            .replacen("module_globals:", "module_globals:\n\ts_branch .Lmiddle", 1),
        source
            .replacen(
                "s_addc_u32 s3, s3, constant_table",
                ".Lmiddle:\n\ts_addc_u32 s3, s3, constant_table",
                1,
            )
            .replacen("module_globals:", "module_globals:\n\ts_branch .Lmiddle", 1),
        source.replacen("s_getpc_b64 s[2:3]", "s_mov_b64 s[2:3], 0", 1),
    ];
    for bad in cases {
        let module = frontend::parse(&bad).unwrap();
        assert!(lower_kernel_in_module(&module, &module.kernels[0]).is_err());
    }
    for bad in [
        "constant_table@gotpcrel+4",
        "constant_table@rel32@unknown+4",
        "constant_table@rel32@lo+arbitrary",
    ] {
        let source = source.replacen("constant_table@rel32@lo+4", bad, 1);
        match frontend::parse(&source) {
            Err(_) => {}
            Ok(module) => assert!(lower_kernel_in_module(&module, &module.kernels[0]).is_err()),
        }
    }
}
