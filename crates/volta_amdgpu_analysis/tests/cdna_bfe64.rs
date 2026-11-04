//! Signed SOP2 extraction across the public CDNA3/4/5 target profiles.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, ParamValue,
    analyze, frontend, ir, lower,
};

const TARGETS: [&str; 3] = ["gfx942", "gfx950", "gfx1250"];

fn source(target: &str, body: &str) -> String {
    let text = format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--{target}"
.text
.type k,@function
k:
s_load_dwordx2 s[4:5],s[0:1],0
s_waitcnt lgkmcnt(0)
{body}
s_cselect_b32 s16,1,0
v_mov_b32 v0,0
v_mov_b32 v2,s8
v_mov_b32 v3,s9
v_mov_b32 v14,s16
v_add_u32 v2,0,v2
v_add_u32 v3,0,v3
v_add_u32 v14,0,v14
global_store_dword v0,v2,s[4:5]
global_store_dword v0,v3,s[4:5] offset:4
global_store_dword v0,v14,s[4:5] offset:8
s_waitcnt vmcnt(0)
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 16
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: a
        .offset: 8
        .size: 5
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    );
    if target == "gfx1250" {
        text.replace("s_load_dwordx2", "s_load_b64")
            .replace("s_waitcnt lgkmcnt(0)", "s_wait_kmcnt 0")
            .replace("global_store_dword", "global_store_b32")
            .replace("v_add_u32", "v_add_nc_u32")
            .replace("s_waitcnt vmcnt(0)", "s_wait_storecnt 0\ns_wait_xcnt 0")
            .replace(
                ".amdhsa_kernel k",
                ".amdhsa_kernel k\n.amdhsa_wavefront_size32 1",
            )
    } else {
        text
    }
}

fn run(target: &str, body: &str) -> AnalysisResult {
    let module = frontend::parse(&source(target, body)).unwrap();
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: 3,
        kind: ArrayKind::Output,
    });
    config.params = vec![
        ParamValue::ArrayPtr("out".into()),
        ParamValue::Bytes(vec![0, 0, 0, 0x80, 0]),
    ];
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn assert_result(result: &AnalysisResult, value: u64, scc: u32) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 3);
    for (index, expected) in [value as u32, (value >> 32) as u32, scc]
        .into_iter()
        .enumerate()
    {
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index as u64).unwrap()),
            Some(i64::from(expected))
        );
    }
}

#[test]
fn signed_fields_cover_zero_full_width_cross_word_and_source_sign_padding() {
    for target in TARGETS {
        for (input, control, expected) in [
            (0x0123_4567_89ab_cdefu64, 32u32 << 16, 0xffff_ffff_89ab_cdef),
            (0x0123_4567_89ab_cdef, (32 << 16) | 32, 0x0123_4567),
            (0x8000_0000_0000_0000, (1 << 16) | 63, u64::MAX),
            (0x8000_0000_0000_0000, (2 << 16) | 62, u64::MAX - 1),
            (0x4000_0000_0000_0000, (2 << 16) | 62, 1),
            (0x8000_0000_0000_0000, (2 << 16) | 63, u64::MAX),
            (0x0123_4567_89ab_cdef, 64 << 16, 0x0123_4567_89ab_cdef),
            (0x8000_0000_0000_0000, (64 << 16) | 63, u64::MAX),
            (0x4000_0000_0000_0000, 63 << 16, 0xc000_0000_0000_0000),
            (u64::MAX, 0, 0),
            (u64::MAX, 128 << 16, 0),
            (
                0x0123_4567_89ab_cdef,
                (32 << 16) | 64 | 0x8080_0000,
                0xffff_ffff_89ab_cdef,
            ),
        ] {
            let prepare = format!(
                "s_mov_b32 s12,{}\ns_mov_b32 s13,{}\n",
                input as u32,
                (input >> 32) as u32
            );
            for register_control in [false, true] {
                let operand = if register_control {
                    "s10".into()
                } else {
                    control.to_string()
                };
                let body = format!(
                    "{prepare}s_mov_b32 s10,{control}\ns_bfe_i64 s[8:9],s[12:13],{operand}"
                );
                assert_result(&run(target, &body), expected, u32::from(expected != 0));
            }
        }
        assert_result(&run(target, "s_bfe_i64 s[8:9],-1,0x200000"), u64::MAX, 1);
    }
}

#[test]
fn scalar_extraction_and_scc_ignore_exec_and_allow_input_output_aliases() {
    for target in TARGETS {
        assert_result(
            &run(
                target,
                "s_mov_b32 s12,0x80000000\ns_mov_b32 exec_lo,0\ns_bfe_i64 s[12:13],s[12:13],0x200000\ns_mov_b64 s[8:9],s[12:13]\ns_mov_b32 exec_lo,1",
            ),
            0xffff_ffff_8000_0000,
            1,
        );
        assert_result(
            &run(
                target,
                "s_mov_b32 s8,0x10000\ns_mov_b32 s12,1\ns_bfe_i64 s[8:9],s[12:13],s8",
            ),
            u64::MAX,
            1,
        );
    }
}

#[test]
fn ignored_padding_and_unknown_words_never_become_invented_observed_values() {
    for target in TARGETS {
        // The second loaded word includes ABI padding; only the defined low32 matter.
        assert_result(
            &run(
                target,
                "s_load_dwordx2 s[12:13],s[0:1],8\ns_waitcnt lgkmcnt(0)\ns_bfe_i64 s[8:9],s[12:13],0x200000",
            ),
            0xffff_ffff_8000_0000,
            1,
        );
        assert_result(&run(target, "s_bfe_i64 s[8:9],s[12:13],0"), 0, 0);
        assert_result(
            &run(
                target,
                "s_mov_b32 s12,1\ns_bfe_i64 s[8:9],s[12:13],0x400000\ns_bfe_i64 s[8:9],s[8:9],0x10000",
            ),
            u64::MAX,
            1,
        );
        // Known nonzero bits justify SCC even when the data result is partial.
        assert_result(
            &run(
                target,
                "s_mov_b32 s12,1\ns_bfe_i64 s[8:9],s[12:13],0x400000\ns_mov_b32 s8,0\ns_mov_b32 s9,0",
            ),
            0,
            1,
        );
        for body in [
            "s_bfe_i64 s[8:9],s[12:13],0x200000",
            "s_mov_b32 s12,1\ns_bfe_i64 s[8:9],s[12:13],0x400000",
            "s_bfe_i64 s[8:9],s[12:13],0x400000\ns_mov_b32 s8,0\ns_mov_b32 s9,0",
            "s_mov_b32 s12,1\ns_bfe_i64 s[8:9],s[12:13],s10",
        ] {
            assert!(
                run(target, body).symbolic_outputs().is_err(),
                "{target} {body}"
            );
        }
    }
}

#[test]
fn selected_width_limit_and_impossible_or_unmodeled_operand_shapes_fail_closed() {
    let valid = "s_bfe_i64 s[8:9],s[12:13],s10";
    for target in TARGETS {
        for width in [65, 127] {
            assert!(matches!(
                run(
                    target,
                    &format!("s_bfe_i64 s[8:9],s[12:13],{}", width << 16)
                )
                .symbolic_outputs(),
                Err(OutputsUnavailable::Aborted(EvalError::Unsupported { .. }))
            ));
        }
        for invalid in [
            valid.replace("s[8:9]", "s8"),
            valid.replace("s[8:9]", "exec"),
            valid.replace("s[12:13]", "s12"),
            valid.replace("s10", "s[10:11]"),
            valid.replace("s[12:13]", "v[12:13]"),
            valid.replace("s10", "1.0"),
            valid.replace("s10", "0x100000000"),
            valid.replace("s[12:13]", "65"),
        ] {
            assert!(
                frontend::parse(&source(target, &invalid)).is_err(),
                "{target} {invalid}"
            );
        }
        let module = frontend::parse(&source(target, valid)).unwrap();
        let lowered = lower::lower_module_kernel(&module, "k").unwrap();
        let instruction = lowered
            .instructions
            .iter()
            .find(|i| i.mnemonic().as_str() == "s_bfe_i64")
            .unwrap();
        let ir::Operation::ScalarAlu(alu) = instruction.operation() else {
            panic!("scalar ALU")
        };
        assert_eq!(
            alu.operation,
            ir::AluOperation::Opcode(ir::AluOpcode::SBfeI64)
        );
        let mut kernel = module.kernels[0].clone();
        let instruction = kernel
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "s_bfe_i64")
            .unwrap();
        if let frontend::Operand::Register(register) = &mut instruction.operands[2] {
            register.count = 2;
        }
        assert!(lower::lower_kernel_in_module(&module, &kernel).is_err());
    }
}
