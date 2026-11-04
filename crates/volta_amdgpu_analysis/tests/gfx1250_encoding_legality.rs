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

#[test]
fn gfx1250_true16_e32_has_a_distinct_low128_vgpr_encoding_boundary() {
    for mnemonic in [
        "v_fmac_f16",
        "v_add_f16",
        "v_sub_f16",
        "v_mul_f16",
        "v_min_f16",
        "v_max_f16",
        "v_max_num_f16",
    ] {
        frontend::parse(&native(&format!("{mnemonic}_e32 v127,v126,v125"))).unwrap();
        for suffix in ["", "_e64"] {
            frontend::parse(&native(&format!("{mnemonic}{suffix} v128,v129,v130"))).unwrap();
        }
        for operands in ["v128,v1,v2", "v1,v128,v2", "v1,v2,v128"] {
            let source = format!("{mnemonic}_e32 {operands}");
            assert!(
                frontend::parse(&native(&source)).is_err(),
                "accepted {source}"
            );
        }
    }
    for source in [
        "v_cmp_gt_f16_e32 vcc_lo,v127,v126",
        "v_cmpx_gt_f16_e32 v127,v126",
        "v_cmp_gt_f16_e64 vcc_lo,v128,v129",
        "v_pk_max_num_f16 v128,v129,v130",
        "v_cvt_f16_f32_e32 v1,v128",
        "v_cvt_f32_f16_e32 v128,v1",
        "v_cvt_f32_bf16_e32 v128,v1",
        "v_cvt_f16_i16_e32 v127,v126",
    ] {
        frontend::parse(&native(source)).unwrap_or_else(|e| panic!("{source}: {e}"));
    }
    for source in [
        "v_cmp_gt_f16_e32 vcc_lo,v128,v1",
        "v_cmp_gt_f16_e32 vcc_lo,v1,v128",
        "v_cmpx_gt_f16_e32 v128,v1",
        "v_cvt_f16_f32_e32 v128,v1",
        "v_cvt_f32_f16_e32 v1,v128",
        "v_cvt_f32_bf16_e32 v1,v128",
        "v_cvt_f16_i16_e32 v128,v1",
        "v_cvt_f16_i16_e32 v1,v128",
    ] {
        assert!(
            frontend::parse(&native(source)).is_err(),
            "accepted {source}"
        );
    }
    let mut typed = frontend::parse(&native("v_fmac_f16_e32 v1,v2,v3")).unwrap();
    if let frontend::Operand::Register(r) = &mut typed.kernels[0].instructions[0].operands[0] {
        r.index = 128;
    }
    assert!(target::validate(&typed).is_err());
}

#[test]
fn gfx1250_f16_e32_comparisons_keep_the_fixed_vcc_and_source_encodings() {
    for good in [
        "v_cmp_gt_f16_e32 vcc_lo,v1,v2",
        "v_cmp_gt_f16_e32 vcc_lo,0x1234,v1",
        "v_cmp_gt_f16_e64 s4,v1,v2",
        "v_cmp_gt_f16_e64 vcc_lo,v1,s4",
        "v_cmpx_gt_f16_e32 v1,v2",
        "v_cmpx_gt_f16_e32 0x1234,v1",
    ] {
        frontend::parse(&native(good)).unwrap_or_else(|e| panic!("{good}: {e}"));
    }
    for bad in [
        "v_cmp_gt_f16_e32 s4,v1,v2",
        "v_cmp_gt_f16_e32 exec_lo,v1,v2",
        "v_cmp_gt_f16_e32 vcc_lo,v1,s4",
        "v_cmp_gt_f16_e32 vcc_lo,v1,0",
        "v_cmp_gt_f16_e32 vcc_lo,65536,v1",
        "v_cmp_gt_f16_e32 vcc_lo,-v1,v2",
        "v_cmpx_gt_f16_e32 v1,s4",
        "v_cmpx_gt_f16_e32 65536,v1",
    ] {
        assert!(frontend::parse(&native(bad)).is_err(), "accepted {bad}");
    }
    let mut typed = frontend::parse(&native("v_cmp_gt_f16_e32 vcc_lo,v1,v2")).unwrap();
    typed.kernels[0].instructions[0].operands[0] =
        frontend::Operand::Register(frontend::Register {
            class: frontend::RegisterClass::Scalar,
            index: 4,
            count: 1,
            special: None,
        });
    assert!(target::validate(&typed).is_err());
}
