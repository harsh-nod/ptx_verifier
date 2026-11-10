//! CDNA4 Table54 disables SADDR with selector0x7f; §10.5 retains per-item offsets.
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, analyze, frontend, lower,
};
use volta_graph::{AmdCounter, AmdEventKind, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, check_graph};

fn source(body: &str) -> String {
    format!(
        ".amdgcn_target \"gfx950\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n.amdhsa_private_segment_fixed_size 32\n.amdhsa_enable_private_segment 1\n.amdhsa_system_vgpr_workitem_id 0\n.end_amdhsa_kernel\n.amdgpu_metadata\n---\namdhsa.version: [1,2]\namdhsa.kernels:\n  - .name: k\n    .private_segment_fixed_size: 32\n...\n.end_amdgpu_metadata\n"
    )
}

fn run(body: &str, block: u32, words: u32) -> AnalysisResult {
    let module = frontend::parse(&source(body)).unwrap();
    let mut config = AnalysisConfig::new((block, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: u64::from(block * words),
        kind: ArrayKind::Output,
    });
    let result = analyze(&module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn op(words: u32, store: bool, scalar: &str, offset: i32) -> String {
    let suffix = if words == 1 {
        String::new()
    } else {
        format!("x{words}")
    };
    let data = if words == 1 {
        "v4".into()
    } else {
        format!("v[4:{}]", 3 + words)
    };
    if store {
        format!("scratch_store_dword{suffix} off,{data},{scalar} offset:{offset}")
    } else {
        format!("scratch_load_dword{suffix} {data},off,{scalar} offset:{offset}")
    }
}

fn output(words: u32) -> String {
    let suffix = if words == 1 {
        String::new()
    } else {
        format!("x{words}")
    };
    let data = if words == 1 {
        "v4".into()
    } else {
        format!("v[4:{}]", 3 + words)
    };
    format!(
        "s_mov_b64 s[8:9],0x20000\nv_mul_lo_u32 v16,{},v0\nglobal_store_dword{suffix} v16,{data},s[8:9]",
        words * 4
    )
}

fn body(words: u32, scalar: &str, offset: i32) -> String {
    "s_mov_b32 s20,0\n".to_owned()
        + &(0..words)
            .map(|word| format!("v_add_u32 v{}, {},v0\n", 4 + word, 1000 + word * 100))
            .collect::<String>()
        + &op(words, true, scalar, offset)
        + "\ns_waitcnt vmcnt(0)\n"
        + &(0..words)
            .map(|word| format!("v_mov_b32 v{},0\n", 4 + word))
            .collect::<String>()
        + &op(words, false, scalar, offset)
        + "\ns_waitcnt vmcnt(0)\n"
        + &output(words)
}

fn assert_values(result: &AnalysisResult, block: u32, words: u32) {
    assert_eq!(
        check_graph(result.graph()).conclusion(),
        GraphConclusion::Verified
    );
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), (block * words) as usize);
    for lane in 0..block {
        for word in 0..words {
            assert_eq!(
                outputs.arena.as_int_const(
                    outputs
                        .element("out", u64::from(lane * words + word))
                        .unwrap()
                ),
                Some(i64::from(1000 + lane + word * 100))
            );
        }
    }
}

#[test]
fn disabled_scalar_and_zero_sgpr_preserve_every_word_at_the_private_extent_end() {
    for words in [1, 2, 4] {
        for block in [1, 63, 64, 65, 128] {
            for scalar in ["off", "s20"] {
                let result = run(&body(words, scalar, 32 - words as i32 * 4), block, words);
                assert_values(&result, block, words);
                for record in result.graph().amd_events() {
                    if let AmdEventKind::PrivateMemoryAccess { offset, width, .. } = record.kind {
                        assert_eq!(offset, 32 - u64::from(words) * 4);
                        assert_eq!(width, words * 4);
                    }
                    if let AmdEventKind::MemoryIssue { counters, .. } = &record.kind {
                        assert_eq!(counters, &[(AmdCounter::Vm, 1)]);
                    }
                }
            }
        }
    }
}

#[test]
fn disabled_scalar_has_no_fabricated_sgpr_read_and_still_requires_vm_completion() {
    let body = body(4, "off", 16);
    let result = run(&body, 64, 4);
    let module = frontend::parse(&source(&body)).unwrap();
    for record in result.graph().amd_events() {
        if let AmdEventKind::Instruction { reads, .. } = &record.kind {
            let pc = result.graph().event(record.event).pc.unwrap().0 as usize;
            if module.kernels[0].instructions[pc]
                .mnemonic
                .starts_with("scratch_")
            {
                assert!(
                    !reads
                        .iter()
                        .any(|r| r.file == AmdRegisterFile::Scalar && r.index < 102)
                );
            }
        }
    }
    for wait in ["", "s_waitcnt lgkmcnt(0)", "s_waitcnt expcnt(0)"] {
        let result = run(&body.replace("s_waitcnt vmcnt(0)", wait), 64, 4);
        assert!(result.symbolic_outputs().is_err());
        assert!(!matches!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        ));
    }
}

#[test]
fn zero_base_does_not_wrap_negative_unaligned_or_partial_out_of_extent_transfers() {
    for words in [1, 2, 4] {
        for offset in [-4096, -4, -1, 1, 2, 32, 4095, 36 - words as i32 * 4] {
            let result = run(&body(words, "off", offset), 64, words);
            assert!(
                result.symbolic_outputs().is_err(),
                "words{words}/offset{offset}"
            );
            assert!(
                !result
                    .graph()
                    .amd_events()
                    .iter()
                    .any(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
            );
        }
    }
    let result = run(&op(4, false, "off", 16), 64, 4);
    assert!(result.symbolic_outputs().is_err());
    assert!(
        !result
            .graph()
            .amd_events()
            .iter()
            .any(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
    );
    let result = run(
        "v_mov_b32 v4,1\nv_mov_b32 v5,2\nv_mov_b32 v6,3\nscratch_store_dwordx4 off,v[4:7],off offset:16\ns_waitcnt vmcnt(0)\nscratch_load_dwordx4 v[4:7],off,off offset:16\ns_waitcnt vmcnt(0)\nv_add_u32 v7,0,v7",
        64,
        4,
    );
    assert!(
        result
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("undefined")
    );
    // Existing pure spills preserve unspecified words; the later numeric read
    // must still refuse to invent their bits after store/reload transport.
    assert_eq!(
        result
            .graph()
            .amd_events()
            .iter()
            .filter(|r| matches!(r.kind, AmdEventKind::MemoryIssue { .. }))
            .count(),
        2
    );
}

#[test]
fn empty_exec_ignores_disabled_offset_and_undefined_data_but_other_source_forms_stay_outside() {
    let result = run(&("s_mov_b64 exec,0\nscratch_store_dwordx4 off,v[4:7],off\nscratch_load_dwordx4 v[4:7],off,off\ns_mov_b64 exec,1\n".to_owned() + &body(1, "off", 28)), 1, 1);
    assert_values(&result, 1, 1);
    for bad in ["zero", "null", "0", "v20", "s[20:21]"] {
        assert!(
            frontend::parse(&source(&op(1, false, bad, 0))).is_err(),
            "{bad}"
        );
    }
    for target in ["gfx942", "gfx1250"] {
        assert!(
            frontend::parse(&source(&op(1, false, "off", 0)).replace("gfx950", target)).is_err()
        );
    }
    let mut module = frontend::parse(&source(&op(1, false, "off", 0))).unwrap();
    module.kernels[0].instructions[0].operands[2] = frontend::Operand::Symbol("zero".into());
    assert!(lower::lower_module_kernel(&module, "k").is_err());
}
