//! Terminal deallocation is an explicit, bounded compiler epilogue profile.
use volta_amdgpu_analysis::{AnalysisConfig, analyze, frontend};

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx1250\"\n.text\n.globl k\nk:\n{body}\n.amdhsa_kernel k\n.amdhsa_wavefront_size32 1\n.amdhsa_private_segment_fixed_size 0\n.end_amdhsa_kernel\n"
    )
}

#[test]
fn native_symbolic_and_encoded_deallocation_spellings_share_the_epilogue() {
    for operand in ["sendmsg(MSG_DEALLOC_VGPRS)", "3"] {
        let module = frontend::parse(&source(&format!("s_sendmsg {operand}\ns_endpgm"))).unwrap();
        assert_eq!(module.kernels[0].instructions[0].mnemonic, "s_sendmsg");
        assert_eq!(
            module.kernels[0].instructions[0].operands,
            [frontend::Operand::Integer(3)]
        );
        let result = analyze(&module, Some("k"), AnalysisConfig::new((32, 1, 1))).unwrap();
        result.graph().validate().unwrap();
        assert!(result.symbolic_outputs().unwrap().outputs.is_empty());
    }
}

#[test]
fn deallocation_cannot_enable_other_messages_scratch_or_post_release_register_use() {
    for body in [
        "s_sendmsg 2\ns_endpgm",
        "s_sendmsg sendmsg(MSG_INTERRUPT)\ns_endpgm",
        "s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)\nv_mov_b32 v0, 1\ns_endpgm",
        "s_sendmsg 3\ns_nop 0\ns_endpgm",
        "s_sendmsg 3",
        "s_sendmsg 3\ns_sendmsg 3\ns_endpgm",
    ] {
        assert!(frontend::parse(&source(body)).is_err(), "accepted {body}");
    }
    let scratch = source("s_sendmsg 3\ns_endpgm").replace(
        ".amdhsa_private_segment_fixed_size 0",
        ".amdhsa_private_segment_fixed_size 4",
    );
    assert!(frontend::parse(&scratch).is_err());
    let mut module = frontend::parse(&source("s_sendmsg 3\ns_endpgm")).unwrap();
    module.kernels[0].instructions.swap(0, 1);
    assert!(analyze(&module, Some("k"), AnalysisConfig::new((32, 1, 1))).is_err());
}

#[test]
fn genuine_full_matrix_compiler_epilogues_retain_all_six_entries() {
    let module = frontend::parse(include_str!(
        "../../../tests/gfx1250/full/fixtures/original-matrix.s"
    ))
    .unwrap();
    assert_eq!(module.kernels.len(), 6);
    for kernel in &module.kernels {
        let instructions = &kernel.instructions;
        assert_eq!(instructions[instructions.len() - 2].mnemonic, "s_sendmsg");
        assert_eq!(instructions.last().unwrap().mnemonic, "s_endpgm");
    }
}
