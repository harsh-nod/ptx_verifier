//! Selected CDNA5 VOP2 unsigned64 multiplication and its source/encoding boundary.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend, ir, lower,
};
use volta_graph::{AmdEventKind, AmdRegisterFile};

fn source(body: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.type k,@function
k:
s_load_b64 s[4:5],s[0:1],0
s_wait_kmcnt 0
v_lshlrev_b32 v12,4,v0
v_mov_b32 v2,0x12345678
v_mov_b32 v3,0x9abcdef0
s_mov_b32 vcc_lo,0xaaaaaaaa
s_cmp_eq_u32 0,0
{body}
s_cselect_b32 s16,1,0
v_mov_b32 v14,s16
v_cndmask_b32_e64 v15,0,1,vcc_lo
v_add_nc_u32 v2,0,v2
v_add_nc_u32 v3,0,v3
v_add_nc_u32 v14,0,v14
v_add_nc_u32 v15,0,v15
global_store_b32 v12,v2,s[4:5]
global_store_b32 v12,v3,s[4:5] offset:4
global_store_b32 v12,v14,s[4:5] offset:8
global_store_b32 v12,v15,s[4:5] offset:12
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
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

fn run(body: &str, block: u32) -> AnalysisResult {
    let module = frontend::parse(&source(body)).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 65536,
        elem_width: 4,
        len: u64::from(block) * 4,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn assert_words(result: &AnalysisResult, expected: &[u64]) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), expected.len() * 4);
    for (lane, expected) in expected.iter().enumerate() {
        for (word, expected) in [
            *expected as u32,
            (*expected >> 32) as u32,
            1,
            (0xaaaa_aaaau32 >> lane) & 1,
        ]
        .into_iter()
        .enumerate()
        {
            assert_eq!(
                outputs
                    .arena
                    .as_int_const(outputs.element("out", (lane * 4 + word) as u64).unwrap()),
                Some(i64::from(expected)),
                "lane {lane}, word {word}"
            );
        }
    }
}

fn constants(a: u64, b: u64) -> String {
    format!(
        "s_mov_b32 s36,{}\ns_mov_b32 s37,{}\nv_mov_b32 v6,{}\nv_mov_b32 v7,{}\nv_mov_b32 v10,{}\nv_mov_b32 v11,{}\n",
        a as u32,
        (a >> 32) as u32,
        a as u32,
        (a >> 32) as u32,
        b as u32,
        (b >> 32) as u32
    )
}

#[test]
fn products_wrap_at_64_bits_and_leave_scalar_flags_unchanged() {
    // Independently worked products distinguish full64 factors from low32-only
    // multiplication and from saturating/signed-result interpretations.
    for (a, b, expected) in [
        (0u64, u64::MAX, 0),
        (u64::MAX, u64::MAX, 1),
        (0xffff_ffff, 0xffff_ffff, 0xffff_fffe_0000_0001),
        (0x1_0000_0001, 0x1_0000_0001, 0x2_0000_0001),
        (0x8000_0000_0000_0000, 2, 0),
        (0x8000_0000_0000_0001, 3, 0x8000_0000_0000_0003),
        (0x0123_4567_89ab_cdef, 16, 0x1234_5678_9abc_def0),
        (0xdead_beef_0000_0001, 0x1_0000_0001, 0xdead_bef0_0000_0001),
    ] {
        for (encoding, first) in [("_e32", "s[36:37]"), ("", "v[6:7]")] {
            let body = constants(a, b) + &format!("v_mul_u64{encoding} v[2:3],{first},v[10:11]");
            assert_words(&run(&body, 1), &[expected]);
        }
    }
}

#[test]
fn e32_pair_boundary_registers_preserve_the_same_integer_contract() {
    assert_words(
        &run(
            "s_mov_b32 s104,3\ns_mov_b32 s105,0\nv_mov_b32 v254,1\nv_mov_b32 v255,1\nv_mul_u64_e32 v[254:255],s[104:105],v[254:255]\nv_mov_b32 v2,v254\nv_mov_b32 v3,v255",
            1,
        ),
        &[0x3_0000_0003],
    );
}

#[test]
fn both_sources_are_snapshotted_before_aliasing_destination_words_are_written() {
    let a = 0x1_0000_0001u64;
    let b = 0x2_0000_0003u64;
    for (prepare, operation, expected) in [
        (
            "v_mov_b32 v2,1\nv_mov_b32 v3,1",
            "v_mul_u64_e32 v[2:3],v[2:3],v[10:11]",
            0x5_0000_0003,
        ),
        (
            "v_mov_b32 v2,3\nv_mov_b32 v3,2",
            "v_mul_u64_e32 v[2:3],s[36:37],v[2:3]",
            0x5_0000_0003,
        ),
        (
            "v_mov_b32 v2,1\nv_mov_b32 v3,1",
            "v_mul_u64_e32 v[2:3],v[2:3],v[2:3]",
            0x2_0000_0001,
        ),
    ] {
        let body = constants(a, b) + prepare + "\n" + operation;
        assert_words(&run(&body, 32), &[expected; 32]);
    }
}

#[test]
fn sparse_exec_preserves_inactive_pairs_and_empty_exec_does_not_read_sources() {
    let active = (1u32 << 31) | 1;
    let body = constants(0x1_0000_0001, 3)
        + &format!(
            "s_mov_b32 exec_lo,{active}\nv_mul_u64_e32 v[2:3],s[36:37],v[10:11]\ns_mov_b32 exec_lo,-1"
        );
    let expected: Vec<_> = (0..32)
        .map(|lane| {
            if active & (1 << lane) != 0 {
                0x3_0000_0003
            } else {
                0x9abc_def0_1234_5678
            }
        })
        .collect();
    assert_words(&run(&body, 32), &expected);
    assert_words(
        &run(
            "s_mov_b32 exec_lo,0\nv_mul_u64_e32 v[2:3],s[36:37],v[10:11]\ns_mov_b32 exec_lo,-1",
            32,
        ),
        &[0x9abc_def0_1234_5678; 32],
    );
}

#[test]
fn every_observed_input_word_must_be_defined_even_with_a_zero_other_factor() {
    for missing in ["s36", "s37", "v10", "v11"] {
        let body = ["s36", "s37", "v10", "v11"]
            .into_iter()
            .filter(|register| *register != missing)
            .map(|register| {
                if register.starts_with('s') {
                    format!("s_mov_b32 {register},0\n")
                } else {
                    format!("v_mov_b32 {register},0\n")
                }
            })
            .collect::<String>()
            + "v_mul_u64_e32 v[2:3],s[36:37],v[10:11]";
        assert!(run(&body, 1).symbolic_outputs().is_err(), "{missing}");
    }
}

#[test]
fn typed_operation_and_graph_roles_retain_both_words_of_both_sources() {
    let body = constants(3, 5) + "v_mul_u64_e32 v[2:3],s[36:37],v[10:11]";
    let module = frontend::parse(&source(&body)).unwrap();
    let program = lower::lower_module_kernel(&module, "k").unwrap();
    let pc = program
        .instructions
        .iter()
        .position(|i| i.mnemonic().as_str() == "v_mul_u64_e32")
        .unwrap();
    let ir::Operation::VectorAlu(alu) = program.instructions[pc].operation() else {
        panic!("vector ALU")
    };
    assert_eq!(
        alu.operation,
        ir::AluOperation::Opcode(ir::AluOpcode::VMulU64)
    );
    let result = run(&body, 1);
    let record = result
        .graph()
        .amd_events()
        .iter()
        .find(|record| {
            result.graph().event(record.event).pc == Some(volta_graph::ProgramPoint(pc as u32))
                && matches!(record.kind, AmdEventKind::Instruction { .. })
        })
        .unwrap();
    let AmdEventKind::Instruction { reads, writes, .. } = &record.kind else {
        unreachable!()
    };
    for (file, indices) in [
        (AmdRegisterFile::Scalar, [36, 37]),
        (AmdRegisterFile::Vector, [10, 11]),
    ] {
        for index in indices {
            assert!(reads.iter().any(|r| r.file == file && r.index == index));
        }
    }
    for index in [2, 3] {
        assert!(
            writes
                .iter()
                .any(|r| r.file == AmdRegisterFile::Vector && r.index == index)
        );
    }
    assert!(writes.iter().all(|r| r.file == AmdRegisterFile::Vector));
}

#[test]
fn encoding_target_and_direct_ast_bypasses_fail_closed() {
    let valid = "v_mul_u64_e32 v[2:3],s[36:37],v[10:11]";
    for invalid in [
        valid.replace("_e32", "_e64"),
        valid.replace("v[2:3]", "v2"),
        valid.replace("v[2:3]", "s[2:3]"),
        valid.replace("s[36:37]", "s36"),
        valid.replace("s[36:37]", "exec"),
        valid.replace("s[36:37]", "0.5"),
        valid.replace("s[36:37]", "-1"),
        valid.replace("s[36:37]", "abs(s[36:37])"),
        valid.replace("v[10:11]", "s[10:11]"),
        valid.replace("v[10:11]", "v10"),
        valid.replace("v[2:3]", "v[256:257]"),
        valid.replace("s[36:37]", "v[256:257]"),
        valid.replace("v[10:11]", "v[256:257]"),
        format!("{valid} clamp"),
    ] {
        assert!(frontend::parse(&source(&invalid)).is_err(), "{invalid}");
    }
    for target in ["gfx942", "gfx950"] {
        let text = format!(
            ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n{valid}\ns_endpgm\n.size k,.-k"
        );
        assert!(frontend::parse(&text).is_err(), "{target}");
    }
    let module = frontend::parse(&source(valid)).unwrap();
    for mutate in 0..3 {
        let mut kernel = module.kernels[0].clone();
        let instruction = kernel
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "v_mul_u64_e32")
            .unwrap();
        match mutate {
            0 => instruction.mnemonic = "v_mul_u64_e64".into(),
            1 => instruction.operands[1] = frontend::Operand::Integer(1),
            _ => {
                if let frontend::Operand::Register(register) = &mut instruction.operands[2] {
                    register.count = 1;
                }
            }
        }
        assert!(lower::lower_kernel_in_module(&module, &kernel).is_err());
    }
}
