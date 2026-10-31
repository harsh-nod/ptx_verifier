//! Bounded CDNA4 MUBUF DMA keeps exact source bytes and full LDS footprints.
#[path = "support/buffer_lds.rs"]
mod fixture;

use volta_amdgpu_analysis::{AnalysisResult, SharedAllocation, analyze, frontend, ir, lower};
use volta_expr::ExprNode;
use volta_graph::{AccessMode, AmdEventKind, AmdMemoryClass, Assumption, Space, Terminal};

fn run(body: &str, block: u32, len: u64, lds: u64) -> AnalysisResult {
    analyze(
        &fixture::module(body),
        Some("k"),
        fixture::config(block, len, lds),
    )
    .unwrap()
}

fn inputs(result: &AnalysisResult, indices: &[u64]) {
    assert_eq!(result.graph().terminal(), &Terminal::Completed);
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    assert_eq!(outputs.outputs[0].1.len(), indices.len());
    for &index in indices {
        let ExprNode::InputElement {
            array,
            index: input,
        } = outputs.arena.node(outputs.element("out", index).unwrap())
        else {
            panic!("expected unchanged input word at {index}")
        };
        assert_eq!(outputs.arena.string(*array), "x");
        assert_eq!(*input, index);
    }
}

fn no_dma(result: &AnalysisResult) {
    assert!(result.symbolic_outputs().is_err());
    assert!(!result.graph().amd_events().iter().any(|event| matches!(
        event.kind,
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::BufferLoadToLds32 | AmdMemoryClass::BufferLoadToLds128,
            ..
        }
    )));
    assert!(
        !result
            .graph()
            .accesses()
            .values()
            .any(|access| access.space == Space::Shared && access.mode == AccessMode::Write)
    );
}

#[test]
fn typed_dma_has_address_sources_and_no_data_destination() {
    for bytes in [4, 16] {
        let module = fixture::module(&fixture::copy(bytes, 4, 1024));
        let program = lower::lower_module_kernel(&module, "k").unwrap();
        let instruction = program
            .instructions
            .iter()
            .find(|instruction| instruction.mnemonic() == fixture::opcode(bytes))
            .unwrap();
        let ir::Operation::Memory(memory) = instruction.operation() else {
            panic!("memory IR")
        };
        assert_eq!(memory.kind, ir::MemoryKind::BufferLoadToLds);
        assert_eq!(memory.shape, ir::TransferShape::PerLaneBytes(bytes as u8));
        assert!(memory.data_destinations().is_empty());
        assert!(memory.data_sources().is_empty());
        assert!(matches!(
            memory.address(),
            ir::MemoryAddress::BufferToLds { .. }
        ));
    }
}

#[test]
fn every_word_and_physical_lane_retains_its_input_identity() {
    for bytes in [4, 16] {
        for block in [1, 2, 32, 48, 64] {
            let len = u64::from(block) * bytes / 4;
            // DWORDX4 accepts a DWORD-aligned base, not only 16-byte alignment.
            let result = run(&fixture::copy(bytes, 4, (len * 4) as u32), block, len, 2048);
            inputs(&result, &(0..len).collect::<Vec<_>>());
            assert_eq!(
                result
                    .graph()
                    .provenance()
                    .assumptions
                    .iter()
                    .filter(|a| matches!(a, Assumption::ConfiguredLdsBytes(2048)))
                    .count(),
                1
            );
        }
    }
    for stride in [1, 0x3fff] {
        let body = fixture::copy(16, 4, 16)
            .replace("s_mov_b32 s9,0", &format!("s_mov_b32 s9,{}", stride << 16));
        inputs(&run(&body, 1, 4, 1024), &[0, 1, 2, 3]);
    }
}

#[test]
fn sparse_exec_does_not_pack_active_lanes_and_empty_exec_observes_no_sources() {
    for bytes in [4, 16] {
        let len = bytes;
        let body = "s_mov_b64 exec,5\n".to_owned() + &fixture::copy(bytes, 0, (len * 4) as u32);
        inputs(
            &run(&body, 4, len, 1024),
            &(0..bytes / 4)
                .chain(bytes / 2..3 * bytes / 4)
                .collect::<Vec<_>>(),
        );
        let empty = run(
            &format!(
                "s_mov_b64 exec,0\n{} v1,s[8:11],0 offen lds",
                fixture::opcode(bytes)
            ),
            4,
            len,
            1024,
        );
        assert_eq!(empty.graph().terminal(), &Terminal::Completed);
        assert!(
            !empty
                .graph()
                .amd_events()
                .iter()
                .any(|event| matches!(event.kind, AmdEventKind::MemoryIssue { .. }))
        );
    }
}

#[test]
fn aligned_low16_m0_can_produce_an_lds_footprint_crossing_64k_without_wrap() {
    for bytes in [4, 16] {
        let len = bytes / 2;
        inputs(
            &run(
                &fixture::copy(bytes, 65532, (len * 4) as u32),
                2,
                len,
                67072,
            ),
            &(0..len).collect::<Vec<_>>(),
        );
    }
}

#[test]
fn m0_and_descriptor_and_vector_inputs_are_snapshots_not_completion_leases() {
    let mut body = fixture::copy(16, 4, 128);
    body = body.replace(
        "s_waitcnt vmcnt(0)\nds_read",
        "s_mov_b32 m0,128\ns_mov_b32 s8,0\nv_mov_b32 v1,0\ns_waitcnt vmcnt(0)\nds_read",
    );
    // Preserve original output coordinates while deliberately reusing v1.
    body = body.replace("s_mov_b32 m0,4", "v_mov_b32 v3,v1\ns_mov_b32 m0,4");
    body = body.replace("global_store_dwordx4 v1,", "global_store_dwordx4 v3,");
    inputs(&run(&body, 4, 16, 1024), &(0..16).collect::<Vec<_>>());
}

#[test]
fn all_lanes_components_resource_and_allocation_bounds_preflight_before_issue() {
    for bytes in [4, 16] {
        let good = fixture::copy(bytes, 0, 128);
        for body in [
            good.replace("s_mov_b32 s10,128", &format!("s_mov_b32 s10,{}", bytes)),
            good.replace("s_mov_b32 s8,65536", "s_mov_b32 s8,65540"),
            good.replace("s_mov_b32 s8,65536", "s_mov_b32 s8,65537"),
            good.replace("s_mov_b32 m0,0", "s_mov_b32 m0,2"),
            good.replace("s_mov_b32 m0,0", "s_mov_b32 m0,65536"),
            good.replace("s_mov_b32 m0,0", ""),
        ] {
            no_dma(&run(&body, 2, bytes / 2, bytes * 2));
        }
        no_dma(&run(&good, 2, bytes / 2, bytes));
        for word3 in [0, 0x20000, 0x110001, 0x190000, 0x910000] {
            no_dma(&run(
                &good.replace("s_mov_b32 s11,1114112", &format!("s_mov_b32 s11,{word3}")),
                2,
                bytes / 2,
                1024,
            ));
        }
        for high in [0x40000000u32, 0x80000000] {
            no_dma(&run(
                &good.replace("s_mov_b32 s9,0", &format!("s_mov_b32 s9,{high}")),
                2,
                bytes / 2,
                1024,
            ));
        }
        let mut config = fixture::config(1, bytes / 4, 1024);
        config.shared_allocations = vec![
            SharedAllocation {
                name: "a".into(),
                offset: 0,
                size: bytes / 2,
            },
            SharedAllocation {
                name: "b".into(),
                offset: bytes / 2,
                size: bytes / 2,
            },
        ];
        no_dma(&analyze(&fixture::module(&good), Some("k"), config).unwrap());
    }
}

#[test]
fn partial_m0_and_late_uninitialized_payload_refuse_without_a_dma_claim() {
    no_dma(&run(
        &fixture::copy(4, 0, 8).replace(
            "s_mov_b32 m0,0",
            "s_load_dword s6,s[0:1],16\ns_waitcnt lgkmcnt(0)\ns_mov_b32 m0,s6",
        ),
        2,
        2,
        1024,
    ));
    let body = fixture::quad(0x10000, 8, 0x110000)
        + "s_mov_b64 s[14:15],0x10000\ns_mov_b64 exec,1\nv_mov_b32 v1,0\nv_mov_b32 v2,7\nglobal_store_dword v1,v2,s[14:15]\ns_waitcnt vmcnt(0)\ns_mov_b64 exec,3\nv_lshlrev_b32 v1,2,v0\ns_mov_b32 m0,0\ns_nop 0\nbuffer_load_dword v1,s[8:11],0 offen lds";
    let mut config = fixture::config(2, 2, 1024);
    config.arrays[0].kind = volta_amdgpu_analysis::ArrayKind::Output;
    no_dma(&analyze(&fixture::module(&body), Some("k"), config).unwrap());
}

#[test]
fn malformed_roles_other_targets_and_nonselected_forms_remain_refused() {
    for instruction in [
        "buffer_load_dword v[1:2],s[8:11],0 offen lds",
        "buffer_load_dwordx4 v1,s[8:9],0 offen lds",
        "buffer_load_dword v1,s[8:11],1 offen lds",
        "buffer_load_dword v1,s[8:11],0 offen",
        "buffer_load_dword v1,s[8:11],0 offen lds offset:4",
        "buffer_load_dword v1,s[8:11],0 offen lds sc0",
        "buffer_load_dword v1,s[8:11],0 idxen lds",
        "buffer_load_dword v4,v1,s[8:11],0 offen lds",
        "buffer_load_dwordx2 v1,s[8:11],0 offen lds",
    ] {
        assert!(
            frontend::parse(&fixture::source(instruction)).is_err(),
            "{instruction}"
        );
    }
    for target in ["gfx942", "gfx1250"] {
        assert!(
            frontend::parse(
                &fixture::source("buffer_load_dword v1,s[8:11],0 offen lds")
                    .replace("gfx950", target)
            )
            .is_err()
        );
    }
    for body in ["s_mov_b32 m0,0.5", "s_add_u32 m0,0,0"] {
        assert!(run(body, 1, 1, 1024).symbolic_outputs().is_err());
    }
}
