//! Encoding controls independently checked with the pinned gfx1250 assembler.
use volta_amdgpu_analysis::{frontend, target};

fn native(body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx1250\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_wavefront_size32 1\n.end_amdhsa_kernel\n"
    )
}

#[test]
fn f16_fmac_respects_e32_source_positions_and_one_literal_word() {
    for good in [
        "v_fmac_f16_e32 v1,v2,v3",
        "v_fmac_f16_e32 v1,0x1234,v2",
        "v_fmac_f16_e64 v1,v2,0x1234",
        "v_fmac_f16 v1,v2,0x1234",
    ] {
        frontend::parse(&native(good)).unwrap_or_else(|e| panic!("{good}: {e}"));
    }
    for bad in [
        "v_fmac_f16_e32 v1,v2,0x1234",
        "v_fmac_f16_e32 v1,v2,s4",
        "v_fmac_f16_e32 v1,65536,v2",
        "v_fmac_f16_e64 v1,0x1234,0x5678",
    ] {
        assert!(frontend::parse(&native(bad)).is_err(), "accepted {bad}");
    }
    let mut typed = frontend::parse(&native("v_fmac_f16_e32 v1,v2,v3")).unwrap();
    typed.kernels[0].instructions[0].operands[2] = frontend::Operand::Integer(0x1234);
    assert!(target::validate(&typed).is_err());
}

#[test]
fn readlane_selector_requires_an_unmodified_scalar_source_or_inline_constant() {
    for good in [
        "v_readlane_b32 s4,v0,s5",
        "v_readlane_b32 s4,v0,ttmp0",
        "v_readlane_b32 s4,v0,exec_lo",
        "v_readlane_b32 s4,v0,vcc_lo",
        "v_readlane_b32 s4,v0,m0",
        "v_readlane_b32 s4,v0,null",
        "v_readlane_b32 s4,v0,31",
        "v_readlane_b32 s4,v0,-1",
        "v_readlane_b32 s4,v0,1.0",
        "v_readlane_b32 s4,v0,0x3f800000",
        "v_readlane_b32 s4,v0,0x3e22f983",
        "v_readlane_b32 s4,v0,0xffffffff",
    ] {
        frontend::parse(&native(good)).unwrap_or_else(|e| panic!("{good}: {e}"));
    }
    for bad in [
        "v_readlane_b32 s4,v0,v1",
        "v_readlane_b32 s4,v0,acc0",
        "v_readlane_b32 s4,v0,s[4:5]",
        "v_readlane_b32 s4,v0,65",
        "v_readlane_b32 s4,v0,-17",
        "v_readlane_b32 s4,v0,0x1234",
        "v_readlane_b32 s4,v0,-s5",
        "v_readlane_b32 s4,v0,-0.0",
        "v_readlane_b32 s4,v0,1.25",
    ] {
        assert!(frontend::parse(&native(bad)).is_err(), "accepted {bad}");
    }
    let mut typed = frontend::parse(&native("v_readlane_b32 s4,v0,s5")).unwrap();
    typed.kernels[0].instructions[0].operands[2] =
        frontend::Operand::Register(frontend::Register {
            class: frontend::RegisterClass::Vector,
            index: 1,
            count: 1,
            special: None,
        });
    assert!(target::validate(&typed).is_err());
}
