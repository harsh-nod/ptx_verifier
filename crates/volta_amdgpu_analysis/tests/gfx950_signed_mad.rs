//! CDNA4 signed 65-bit MAD results, flag masks and the selected encoding boundary.
//!
//! Public CDNA4 ISA 12.11 V_MAD_I64_I32 defines {D1,D0} as the 65-bit sum;
//! LLVM 5fd50ec8 VOP3Instructions.td uses VOP3b_I64_I1_I32_I32_I64_DPP.
//! The compiler uses this form in unchanged HipKittens 8cde3dd CDNA4 softmax,
//! rotary and BF16 GEMM address construction. This test is a bounded ISA
//! control, not an acceptance claim for those complete applications.
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend, ir, lower,
};
use volta_graph::{AmdEventKind, AmdRegisterFile};

fn source(body: &str, mask: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.type k,@function
k:
s_load_dwordx2 s[4:5],s[0:1],0
s_waitcnt lgkmcnt(0)
v_mul_lo_u32 v12,12,v0
v_mov_b32 v2,0x12345678
v_mov_b32 v3,0x9abcdef0
{body}
v_cndmask_b32_e64 v14,0,1,{mask}
v_add_u32 v2,0,v2
v_add_u32 v3,0,v3
v_add_u32 v14,0,v14
global_store_dword v12,v2,s[4:5]
global_store_dword v12,v3,s[4:5] offset:4
global_store_dword v12,v14,s[4:5] offset:8
s_waitcnt vmcnt(0)
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_kernarg_size 8
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
...
.end_amdgpu_metadata
"#
    )
}

fn run(body: &str, mask: &str, block: u32) -> volta_amdgpu_analysis::AnalysisResult {
    let module = frontend::parse(&source(body, mask)).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: u64::from(block) * 3,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn assert_words(result: &volta_amdgpu_analysis::AnalysisResult, expected: &[[u32; 3]]) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), expected.len() * 3);
    for (lane, words) in expected.iter().enumerate() {
        for (word, expected) in words.iter().enumerate() {
            assert_eq!(
                outputs
                    .arena
                    .as_int_const(outputs.element("out", (lane * 3 + word) as u64).unwrap()),
                Some(i64::from(*expected)),
                "lane {lane}, word {word}"
            );
        }
    }
}

fn constants(a: i32, b: i32, c: i64) -> String {
    format!(
        "v_mov_b32 v6,{}\nv_mov_b32 v7,{}\nv_mov_b32 v10,{}\nv_mov_b32 v11,{}\n",
        a as u32,
        b as u32,
        c as u32,
        (c as u64 >> 32) as u32
    )
}

#[test]
fn signed_result_and_bit64_mask_are_distinct_from_signed_overflow() {
    // Explicit independently worked 65-bit results include negative nonoverflow
    // and positive signed64 overflow, so an overflow predicate is insufficient.
    for (a, b, c, expected) in [
        (-1, 1, 0, [0xffff_ffff, 0xffff_ffff, 1]),
        (-2, 3, 5, [0xffff_ffff, 0xffff_ffff, 1]),
        (i32::MAX, i32::MAX, i64::MAX, [0, 0xbfff_ffff, 0]),
        (i32::MIN, i32::MAX, i64::MIN, [0x8000_0000, 0x4000_0000, 1]),
        (i32::MIN, i32::MIN, -1, [0xffff_ffff, 0x3fff_ffff, 0]),
        (0, i32::MIN, i64::MIN, [0, 0x8000_0000, 1]),
        (i32::MAX, -1, 1i64 << 31, [1, 0, 0]),
        (i32::MIN, -1, i64::MAX, [0x7fff_ffff, 0x8000_0000, 0]),
    ] {
        for (encoding, mask) in [("", "s[8:9]"), ("_e64", "vcc")] {
            let body = constants(a, b, c)
                + &format!("v_mad_i64_i32{encoding} v[2:3],{mask},v6,v7,v[10:11]");
            assert_words(&run(&body, mask, 1), &[expected]);
        }
    }
}

#[test]
fn lanes_in_both_mask_words_are_independent_and_inactive_data_is_preserved() {
    let active = (1u64 << 63) | (1u64 << 32) | 1;
    let body = format!(
        "v_sub_u32 v6,0,v0\nv_mov_b32 v7,1\nv_mov_b64 v[10:11],0\ns_mov_b64 s[8:9],-1\ns_mov_b32 exec_lo,{}\ns_mov_b32 exec_hi,{}\nv_mad_i64_i32 v[2:3],s[8:9],v6,v7,v[10:11]\ns_mov_b64 exec,-1",
        active as u32,
        (active >> 32) as u32
    );
    let expected: Vec<_> = (0..64)
        .map(|lane| {
            if active & (1u64 << lane) == 0 {
                [0x1234_5678, 0x9abc_def0, 0]
            } else if lane == 0 {
                [0, 0, 0]
            } else {
                [0u32.wrapping_sub(lane), u32::MAX, 1]
            }
        })
        .collect();
    assert_words(&run(&body, "s[8:9]", 64), &expected);
}

#[test]
fn empty_exec_clears_the_mask_without_reading_undefined_sources() {
    assert_words(
        &run(
            "s_mov_b64 s[8:9],-1\ns_mov_b64 exec,0\nv_mad_i64_i32 v[2:3],s[8:9],v6,v7,v[10:11]\ns_mov_b64 exec,-1",
            "s[8:9]",
            64,
        ),
        &[[0x1234_5678, 0x9abc_def0, 0]; 64],
    );
}

#[test]
fn scalar_source_aliases_are_read_before_the_mask_is_written() {
    assert_words(
        &run(
            "s_mov_b32 s8,-7\nv_mov_b32 v7,1\nv_mad_i64_i32 v[2:3],s[8:9],s8,v7,0",
            "s[8:9]",
            64,
        ),
        &[[0xffff_fff9, 0xffff_ffff, 1]; 64],
    );
}

#[test]
fn typed_operation_and_graph_roles_retain_both_destinations_and_all_sources() {
    let text = source(
        &(constants(-2, 3, 5) + "v_mad_i64_i32 v[2:3],s[8:9],v6,v7,v[10:11]"),
        "s[8:9]",
    );
    let module = frontend::parse(&text).unwrap();
    let program = lower::lower_module_kernel(&module, "k").unwrap();
    let pc = program
        .instructions
        .iter()
        .position(|i| i.mnemonic().as_str() == "v_mad_i64_i32")
        .unwrap();
    let ir::Operation::VectorAlu(alu) = program.instructions[pc].operation() else {
        panic!("vector ALU")
    };
    assert_eq!(
        alu.operation,
        ir::AluOperation::Opcode(ir::AluOpcode::VMadI64I32)
    );
    let result = run(
        &(constants(-2, 3, 5) + "v_mad_i64_i32 v[2:3],s[8:9],v6,v7,v[10:11]"),
        "s[8:9]",
        1,
    );
    let record = result
        .graph()
        .amd_events()
        .iter()
        .find(|r| {
            result.graph().event(r.event).pc == Some(volta_graph::ProgramPoint(pc as u32))
                && matches!(r.kind, AmdEventKind::Instruction { .. })
        })
        .unwrap();
    let AmdEventKind::Instruction { reads, writes, .. } = &record.kind else {
        unreachable!()
    };
    for index in [6, 7, 10, 11] {
        assert!(
            reads
                .iter()
                .any(|r| r.file == AmdRegisterFile::Vector && r.index == index)
        );
    }
    for (file, indices) in [
        (AmdRegisterFile::Vector, [2, 3]),
        (AmdRegisterFile::Scalar, [8, 9]),
    ] {
        for index in indices {
            assert!(writes.iter().any(|r| r.file == file && r.index == index));
        }
    }
    assert!(
        !reads
            .iter()
            .any(|r| r.file == AmdRegisterFile::Scalar && matches!(r.index, 8 | 9))
    );
}

#[test]
fn unsupported_encodings_and_direct_ast_bypasses_are_refused() {
    let valid = "v_mad_i64_i32 v[2:3],s[8:9],v6,v7,v[10:11]";
    for invalid in [
        valid.replace("v_mad_i64_i32", "v_mad_i64_i32_e32"),
        valid.replace("v[2:3]", "v2"),
        valid.replace("s[8:9]", "s8"),
        valid.replace("s[8:9]", "exec"),
        valid.replace("v6", "v[6:7]"),
        valid.replace("v[10:11]", "v10"),
        valid.replace("v6", "abs(v6)"),
        valid.replace("v6", "1.0"),
        valid.replace("v6", "65"),
        valid.replace("v6,v7", "s10,s11"),
        format!("{valid} clamp"),
    ] {
        assert!(
            frontend::parse(&source(&invalid, "s[8:9]")).is_err(),
            "{invalid}"
        );
    }
    for target in ["gfx942", "gfx1250"] {
        assert!(frontend::parse(&source(valid, "s[8:9]").replace("gfx950", target)).is_err());
    }
    let module = frontend::parse(&source(valid, "s[8:9]")).unwrap();
    for mutate in 0..3 {
        let mut kernel = module.kernels[0].clone();
        let instruction = kernel
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "v_mad_i64_i32")
            .unwrap();
        match mutate {
            0 => instruction.mnemonic += "_e32",
            1 => instruction.operands[4] = frontend::Operand::Integer(65),
            _ => instruction.operands.pop().map(|_| ()).unwrap(),
        }
        assert!(lower::lower_kernel_in_module(&module, &kernel).is_err());
    }
}

#[test]
fn undefined_observed_source_words_abort_without_inventing_a_result() {
    for prefix in [
        "v_mov_b32 v6,1\nv_mov_b32 v7,2\nv_mov_b32 v10,0\n",
        "v_mov_b32 v7,2\nv_mov_b64 v[10:11],0\n",
    ] {
        let result = run(
            &(prefix.to_owned() + "v_mad_i64_i32 v[2:3],s[8:9],v6,v7,v[10:11]"),
            "s[8:9]",
            1,
        );
        assert!(result.symbolic_outputs().is_err());
    }
}

#[test]
fn unsigned_mad_retains_its_carry_out_contract() {
    let body = constants(-1, -1, -1) + "v_mad_u64_u32 v[2:3],s[8:9],v6,v7,v[10:11]";
    assert_words(&run(&body, "s[8:9]", 1), &[[0, 0xffff_fffe, 1]]);
}
