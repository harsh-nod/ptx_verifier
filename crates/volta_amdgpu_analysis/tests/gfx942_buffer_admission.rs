//! Generic CDNA3 MUBUF roles stay recognizable without extending execution.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, EvalError, OutputsUnavailable, analyze,
    frontend, ir, lower,
};
use volta_graph::AmdEventKind;

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"gfx942\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_accum_offset 64\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n"
    )
}

fn run(module: &frontend::Module) -> AnalysisResult {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::Input,
        },
        ArrayDef {
            name: "out".into(),
            base: 0x20000,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::Output,
        },
    ];
    let result = analyze(module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn refuse(module: &frontend::Module, pc: usize) {
    lower::lower_module_kernel(module, "k").unwrap();
    let result = run(module);
    assert!(
        matches!(result.symbolic_outputs(),
            Err(OutputsUnavailable::Aborted(EvalError::Unsupported { pc: actual, .. }))
            if *actual == pc),
        "{:?}",
        result.symbolic_outputs()
    );
    assert!(result.graph().accesses().is_empty());
    assert!(
        !result
            .graph()
            .amd_events()
            .iter()
            .any(|record| matches!(record.kind, AmdEventKind::MemoryIssue { .. }))
    );
}

fn operation(words: u32, store: bool, data: &str, scalar: &str, modifiers: &str) -> String {
    let suffix = if words == 1 {
        String::new()
    } else {
        format!("x{words}")
    };
    format!(
        "buffer_{}_dword{suffix} {data},v16,s[8:11],{scalar} {modifiers}",
        if store { "store" } else { "load" },
    )
}

#[test]
fn original_general_buffer_fixture_keeps_address_descriptor_and_data_roles() {
    // These exact instructions also remain unchanged in the older typed_ir test.
    let module = frontend::parse(&source(
        "buffer_load_dword v0, v1, s[4:7], s0\nbuffer_store_dword v0, v1, s[4:7], s0",
    ))
    .unwrap();
    let program = lower::lower_module_kernel(&module, "k").unwrap();
    for (index, instruction) in program.instructions[..2].iter().enumerate() {
        let ir::Operation::Memory(memory) = instruction.operation() else {
            panic!("buffer")
        };
        assert!(matches!(memory.address(), ir::MemoryAddress::Buffer {
            vector: ir::Operand::Register(v), descriptor: ir::Operand::Register(d),
            offset: ir::Operand::Register(s),
        } if v.class == frontend::RegisterClass::Vector && v.index == 1 && v.count == 1
            && d.class == frontend::RegisterClass::Scalar && d.index == 4 && d.count == 4
            && s.class == frontend::RegisterClass::Scalar && s.index == 0 && s.count == 1));
        assert_eq!(memory.data_sources().len(), index);
        assert_eq!(memory.data_destinations().len(), 1 - index);
    }
    // Refuse before trying to read any of this deliberately uninitialized state.
    refuse(&module, 0);
}

#[test]
fn recognized_scalar_offsets_address_modes_policies_and_acc_data_never_execute() {
    for words in [1, 2, 4] {
        let vector_data = if words == 1 {
            "v4".into()
        } else {
            format!("v[4:{}]", words + 3)
        };
        let accumulator_data = if words == 1 {
            "a4".into()
        } else {
            format!("a[4:{}]", words + 3)
        };
        for store in [false, true] {
            for (data, scalar, modifiers) in [
                (vector_data.as_str(), "s0", "offen"), // Its concrete bits are zero.
                (vector_data.as_str(), "s1", "offen"),
                (vector_data.as_str(), "m0", "offen"),
                (vector_data.as_str(), "1", "offen"),
                (vector_data.as_str(), "0", ""),
                (vector_data.as_str(), "0", "offset:4"),
                (vector_data.as_str(), "0", "idxen"),
                (vector_data.as_str(), "0", "offen glc"),
                (vector_data.as_str(), "0", "offen slc"),
                (accumulator_data.as_str(), "0", "offen"),
            ] {
                for empty in [false, true] {
                    // Valid mapped resources/data make ignored options observable
                    // as accidental execution, rather than an unrelated bounds error.
                    let body = format!(
                        "s_mov_b32 s0,0\ns_mov_b32 s1,4\ns_mov_b32 m0,0\ns_mov_b32 s8,{}\ns_mov_b32 s9,0\ns_mov_b32 s10,16\ns_mov_b32 s11,0x20000\nv_mov_b32 v16,0\nv_add_u32 v4,10,v0\nv_add_u32 v5,20,v0\nv_add_u32 v6,30,v0\nv_add_u32 v7,40,v0\n{}{}",
                        if store { 0x20000 } else { 0x10000 },
                        if empty { "s_mov_b64 exec,0\n" } else { "" },
                        operation(words, store, data, scalar, modifiers),
                    );
                    let module = frontend::parse(&source(&body)).unwrap();
                    refuse(&module, 12 + usize::from(empty));
                }
            }
        }
    }
}

#[test]
fn runtime_admission_uses_exact_operand_variants_even_after_ast_lowering() {
    for store in [false, true] {
        for operand in 0..4 {
            let mut module =
                frontend::parse(&source(&operation(4, store, "v[4:7]", "0", "offen"))).unwrap();
            let old = module.kernels[0].instructions[0].operands[operand].clone();
            module.kernels[0].instructions[0].operands[operand] = frontend::Operand::Modified {
                value: Box::new(old),
                negate: true,
                absolute: false,
            };
            refuse(&module, 0);
        }
    }
}

#[test]
fn malformed_encoding_and_immediates_stay_rejected_in_mutable_ast_lowering() {
    for target in ["gfx942", "gfx950"] {
        for words in [1, 2, 4] {
            for store in [false, true] {
                let data = if words == 1 {
                    "v4".into()
                } else {
                    format!("v[4:{}]", words + 3)
                };
                let original =
                    source(&operation(words, store, &data, "0", "offen")).replace("gfx942", target);
                let mut module = frontend::parse(&original).unwrap();
                module.kernels[0].instructions[0].operands.pop();
                assert!(lower::lower_module_kernel(&module, "k").is_err());
                let mut module = frontend::parse(&original).unwrap();
                module.kernels[0].instructions[0]
                    .operands
                    .push(frontend::Operand::Integer(0));
                assert!(lower::lower_module_kernel(&module, "k").is_err());
            }
        }
        let original =
            source("buffer_load_dwordx4 v[4:7],v16,s[8:11],0 offen").replace("gfx942", target);
        for offset in ["-1", "4096", "not_an_immediate"] {
            let mut module = frontend::parse(&original).unwrap();
            module.kernels[0].instructions[0]
                .modifiers
                .push(frontend::Modifier {
                    name: "offset".into(),
                    value: Some(offset.into()),
                });
            assert!(lower::lower_module_kernel(&module, "k").is_err());
        }
        let mut module = frontend::parse(&original).unwrap();
        module.kernels[0].instructions[0].mnemonic = "buffer_load_dwordx4_e64".into();
        assert!(lower::lower_module_kernel(&module, "k").is_err());
    }
}
