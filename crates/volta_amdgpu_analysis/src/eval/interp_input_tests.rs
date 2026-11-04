//! Compare demand-backed execution with the previous small-fixture eager setup.
use super::*;
use crate::{ArrayDef, frontend, lower::lower_kernel_in_module};
use volta_expr::structurally_equal;

fn array(name: &str, base: u64, width: u64, len: u64, kind: ArrayKind) -> ArrayDef {
    ArrayDef {
        name: name.into(),
        base,
        elem_width: width,
        len,
        kind,
    }
}

fn config(width: u64, len: u64, kind: ArrayKind) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![
        array("x", 0x10000, width, len, kind),
        array("out", 0x20000, width, len, ArrayKind::Output),
    ];
    config
}

fn source(target: &str, body: &str) -> String {
    let wave32 = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\ns_mov_b64 s[4:5],0x10000\ns_mov_b64 s[6:7],0x20000\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n{wave32}\n.amdhsa_system_vgpr_workitem_id 0\n.amdhsa_group_segment_fixed_size 16\n.end_amdhsa_kernel\n"
    )
}

fn same_value(a: &RunArtifacts, x: StoredValue, b: &RunArtifacts, y: StoredValue) {
    let pairs = match (x, y) {
        (StoredValue::Opaque, StoredValue::Opaque) => Vec::new(),
        (StoredValue::Scalar(x), StoredValue::Scalar(y)) => vec![(x, y)],
        (StoredValue::Pair(x0, x1), StoredValue::Pair(y0, y1)) => vec![(x0, y0), (x1, y1)],
        (StoredValue::Quad(x), StoredValue::Quad(y)) => x.into_iter().zip(y).collect(),
        _ => panic!("stored value shapes changed: {x:?} versus {y:?}"),
    };
    for (x, y) in pairs {
        assert!(structurally_equal(&a.arena, x, &b.arena, y));
    }
}

fn compare(source: &str, kernel: &str, config: AnalysisConfig) -> RunArtifacts {
    let module = frontend::parse(source).unwrap();
    // Use the public producer's provenance, avoiding a second instruction-kind
    // mapping in this oracle. All fixtures here are small and finite.
    let public = crate::analyze(&module, Some(kernel), config.clone()).unwrap();
    let program = lower_kernel_in_module(
        &module,
        module.kernels.iter().find(|k| k.name == kernel).unwrap(),
    )
    .unwrap();
    let provenance = public.graph().provenance().clone();
    let lazy = Interpreter::new(&program, config.clone(), provenance.clone())
        .unwrap()
        .execute(None);
    let mut eager = Interpreter::new(&program, config, provenance).unwrap();
    eager
        .inputs
        .initialize_eager(&eager.config.arrays, &mut eager.global, &mut eager.arena);
    let eager = eager.execute(None);
    lazy.graph.validate().unwrap();
    eager.graph.validate().unwrap();
    assert_eq!(lazy.graph.provenance(), eager.graph.provenance());
    assert_eq!(lazy.graph.terminal(), eager.graph.terminal());
    assert_eq!(lazy.graph.threads(), eager.graph.threads());
    for thread in 0..lazy.graph.threads() {
        assert_eq!(
            lazy.graph.program_order(ThreadIx(thread)),
            eager.graph.program_order(ThreadIx(thread))
        );
    }
    assert_eq!(lazy.graph.objects(), eager.graph.objects());
    assert_eq!(lazy.graph.generations(), eager.graph.generations());
    assert_eq!(lazy.graph.async_ops(), eager.graph.async_ops());
    assert_eq!(lazy.graph.events(), eager.graph.events());
    assert_eq!(lazy.graph.accesses(), eager.graph.accesses());
    assert_eq!(lazy.graph.amd_events(), eager.graph.amd_events());
    assert_eq!(
        lazy.graph.amd_memory_effects(),
        eager.graph.amd_memory_effects()
    );
    assert_eq!(
        lazy.graph.shared_allocation_layout(),
        eager.graph.shared_allocation_layout()
    );
    assert_eq!(lazy.op_counts, eager.op_counts);
    assert_eq!(
        (
            lazy.stats.instructions,
            lazy.stats.block_syncs,
            lazy.stats.warp_syncs
        ),
        (
            eager.stats.instructions,
            eager.stats.block_syncs,
            eager.stats.warp_syncs
        )
    );
    for (a, b) in lazy
        .graph
        .accesses()
        .iter()
        .zip(eager.graph.accesses().iter())
    {
        if let (Some(x), Some(y)) = (a.1.value, b.1.value) {
            same_value(&lazy, lazy.graph.value(x), &eager, eager.graph.value(y));
        }
    }
    match (&lazy.outputs, &eager.outputs) {
        (Ok(a), Ok(b)) => {
            assert_eq!(a.len(), b.len());
            for ((an, aa), (bn, bb)) in a.iter().zip(b) {
                assert_eq!(an, bn);
                assert_eq!(aa.len(), bb.len());
                for ((ai, av), (bi, bv)) in aa.iter().zip(bb) {
                    assert_eq!(ai, bi);
                    assert!(structurally_equal(&lazy.arena, *av, &eager.arena, *bv));
                }
            }
        }
        (Err(a), Err(b)) => assert_eq!(a.to_string(), b.to_string()),
        _ => panic!("output availability differs"),
    }
    lazy
}

#[test]
fn packed_and_wide_first_touches_match_eager_execution() {
    for (width, len, load, store) in [
        (
            1,
            4,
            "global_load_b32 v1,v0,s[4:5]",
            "global_store_b32 v0,v1,s[6:7]",
        ),
        (
            2,
            2,
            "global_load_b32 v1,v0,s[4:5]",
            "global_store_b32 v0,v1,s[6:7]",
        ),
        (
            4,
            2,
            "global_load_b32 v1,v0,s[4:5] offset:4",
            "global_store_b32 v0,v1,s[6:7] offset:4",
        ),
        // High word first must create both parts of the same original symbol.
        (
            8,
            1,
            "global_load_b32 v3,v0,s[4:5] offset:4\nglobal_load_b32 v2,v0,s[4:5]",
            "global_store_b64 v0,v[2:3],s[6:7]",
        ),
    ] {
        let s = source(
            "gfx1250",
            &format!(
                "v_mov_b32 v0,0\n{load}\ns_wait_loadcnt 0\ns_wait_xcnt 0\n{store}\ns_wait_storecnt 0\ns_wait_xcnt 0"
            ),
        );
        let run = compare(&s, "k", config(width, len, ArrayKind::Input));
        assert_eq!(run.graph.terminal(), &Terminal::Completed);
        assert!(run.outputs.is_ok());
        assert_eq!(
            run.outputs.as_ref().unwrap()[0].1.len(),
            if width == 4 { 1 } else { len as usize }
        );
    }
}

#[test]
fn overwritten_defaults_do_not_return_and_unwritten_inout_stays_absent() {
    let s = source(
        "gfx1250",
        "v_mov_b32 v0,0\nv_add_u32 v1,7,0\nglobal_store_b32 v0,v1,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0\nglobal_load_b32 v2,v0,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nglobal_store_b32 v0,v2,s[6:7]",
    );
    let run = compare(&s, "k", config(4, 4, ArrayKind::InputOutput));
    let outputs = run.outputs.unwrap();
    assert_eq!(
        outputs.iter().map(|(_, xs)| xs.len()).collect::<Vec<_>>(),
        vec![1, 1]
    );
    for (_, xs) in outputs {
        assert_eq!(xs[0].0, 0);
        assert_eq!(run.arena.as_int_const(xs[0].1), Some(7));
    }
}

#[test]
fn partial_writes_retain_eager_symbolic_refusals_and_concrete_bytes() {
    for width in [2, 4, 8] {
        let s = source(
            "gfx1250",
            "v_mov_b32 v0,0\nv_add_u32 v1,7,0\nglobal_store_b8 v0,v1,s[4:5]",
        );
        let run = compare(&s, "k", config(width, 2, ArrayKind::Input));
        assert!(
            run.outputs
                .unwrap_err()
                .to_string()
                .contains("partial overwrite of a symbolic granule")
        );
    }
    // Byte stores into a concrete word split its original cell. A later wide
    // read must combine the preserved/new bytes, never restore the index value.
    let s = source(
        "gfx1250",
        "v_mov_b32 v0,0\nv_add_u32 v1,170,0\nglobal_store_b8 v0,v1,s[4:5] offset:1\ns_wait_storecnt 0\ns_wait_xcnt 0\nglobal_load_b32 v2,v0,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nv_add_u32 v2,0,v2\nglobal_store_b32 v0,v2,s[6:7]",
    );
    let run = compare(&s, "k", config(4, 2, ArrayKind::IndexInput));
    assert_eq!(
        run.arena.as_int_const(run.outputs.unwrap()[0].1[0].1),
        Some(0xaa00)
    );
}

#[test]
fn one_word_overwrites_keep_mismatched_wide_pairs_refused() {
    for offset in [0, 4] {
        let s = source(
            "gfx1250",
            &format!(
                "v_mov_b32 v0,0\nv_add_u32 v1,19,0\nglobal_store_b32 v0,v1,s[4:5] offset:{offset}\ns_wait_storecnt 0\ns_wait_xcnt 0\nglobal_load_b64 v[2:3],v0,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nglobal_store_b64 v0,v[2:3],s[6:7]"
            ),
        );
        let run = compare(&s, "k", config(8, 1, ArrayKind::IndexInput));
        assert!(
            run.outputs
                .unwrap_err()
                .to_string()
                .contains("matching ordered words")
        );
    }
}

#[test]
fn cross_wave_write_then_read_uses_one_global_backing() {
    let s = source(
        "gfx1250",
        "s_lshr_b32 s8,ttmp8,25\ns_and_b32 s8,s8,31\ns_cmp_eq_u32 s8,0\ns_cbranch_scc0 rendezvous\ns_mov_b32 exec_lo,1\nv_mov_b32 v1,0\nv_add_u32 v2,23,0\nglobal_store_b32 v1,v2,s[4:5]\ns_wait_storecnt 0\ns_wait_xcnt 0\ns_mov_b32 exec_lo,-1\nrendezvous:\ns_barrier_signal -1\ns_barrier_wait -1\nv_mov_b32 v1,0\nglobal_load_b32 v2,v1,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nv_lshlrev_b32 v1,2,v0\nglobal_store_b32 v1,v2,s[6:7]\ns_wait_storecnt 0\ns_wait_xcnt 0",
    );
    let mut c = config(4, 1, ArrayKind::InputOutput);
    c.block_dim = (64, 1, 1);
    c.arrays[1].len = 64;
    let run = compare(&s, "k", c);
    let outputs = run.outputs.unwrap();
    assert_eq!(outputs[0].1.len(), 1);
    assert_eq!(outputs[1].1.len(), 64);
    for (_, value) in &outputs[1].1 {
        assert_eq!(run.arena.as_int_const(*value), Some(23));
    }
}

#[test]
fn scalar_flat_buffer_and_atomic_routes_match_eager() {
    for body in [
        "s_load_b32 s8,s[4:5],0\ns_wait_kmcnt 0\ns_wait_xcnt 0\nv_mov_b32 v1,s8\nglobal_store_b32 v0,v1,s[6:7]",
        "flat_load_b32 v1,v[4:5]\ns_wait_loadcnt_dscnt 0\ns_wait_xcnt 0\nglobal_store_b32 v0,v1,s[6:7]",
        "v_mov_b32 v1,0x3fc00000\nglobal_atomic_add_f32 v0,v1,s[4:5] scope:SCOPE_DEV\ns_wait_storecnt 0\ns_wait_xcnt 0\nglobal_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nglobal_store_b32 v0,v1,s[6:7]",
    ] {
        let s = source(
            "gfx1250",
            &format!("v_mov_b32 v0,0\nv_mov_b32 v4,0x10000\nv_mov_b32 v5,0\n{body}"),
        );
        let run = compare(&s, "k", config(4, 1, ArrayKind::InputOutput));
        assert!(run.outputs.is_ok(), "{:?}", run.outputs);
        assert_eq!(run.graph.terminal(), &Terminal::Completed);
    }
    let body = "v_mov_b32 v0,0\ns_mov_b32 s8,0x10000\ns_mov_b32 s9,0\ns_mov_b32 s10,8\ns_mov_b32 s11,0x20000\ns_mov_b32 s12,0x20000\ns_mov_b32 s13,0\ns_mov_b32 s14,8\ns_mov_b32 s15,0x20000\nbuffer_load_dwordx2 v[2:3],v0,s[8:11],0 offen\ns_waitcnt vmcnt(0)\nbuffer_store_dwordx2 v[2:3],v0,s[12:15],0 offen\ns_waitcnt vmcnt(0)";
    assert!(
        compare(&source("gfx950", body), "k", config(4, 2, ArrayKind::Input))
            .outputs
            .is_ok()
    );
    let body = "v_mov_b32 v0,0\ns_mov_b32 s8,0x10000\ns_mov_b32 s9,0x20000000\ns_mov_b32 s10,0\ns_mov_b32 s11,0\nbuffer_load_b128 v[2:5],v0,s[8:11],null offen\ns_wait_loadcnt 0\ns_wait_xcnt 0\nglobal_store_b128 v0,v[2:5],s[6:7]";
    assert!(
        compare(
            &source("gfx1250", body),
            "k",
            config(4, 4, ArrayKind::Input)
        )
        .outputs
        .is_ok()
    );
}

#[test]
fn original_tensor_load_and_store_routes_match_eager() {
    let s =
        include_str!("../../../../tests/gfx1250/portable-graph/async-memory/native-async-memory.s");
    let mut c = config(4, 5, ArrayKind::InputOutput);
    c.block_dim = (64, 1, 1);
    c.params = vec![
        ParamValue::ArrayPtr("x".into()),
        ParamValue::ArrayPtr("out".into()),
    ];
    let mut load_config = config(4, 1, ArrayKind::Input);
    load_config.params = c.params.clone();
    let load_run = compare(s, "async_copy4_same_actor", load_config);
    assert!(load_run.outputs.is_ok());
    let run = compare(s, "async_copy16_source_reuse", c);
    assert!(run.outputs.is_ok(), "{:?}", run.outputs);
    assert!(run.graph.amd_events().iter().any(|r| matches!(
        r.kind,
        AmdEventKind::MemoryIssue {
            class: AmdMemoryClass::TensorStoreFromLds,
            ..
        }
    )));
}

#[test]
fn uninitialized_spaces_bounds_and_format_conflicts_stay_refused() {
    for body in [
        "global_load_b32 v1,v0,s[6:7]",
        "ds_load_b32 v1,v0",
        "global_load_b64 v[2:3],v0,s[4:5]",
        "global_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nv_add_f32 v2,1.0,v1\nv_add_u32 v3,1,v1",
    ] {
        let run = compare(
            &source("gfx1250", &format!("v_mov_b32 v0,0\n{body}")),
            "k",
            config(4, 1, ArrayKind::Input),
        );
        assert!(run.outputs.is_err(), "unexpected completion for {body}");
    }
}

#[test]
fn huge_unused_inputs_preserve_full_extent_without_eager_nodes() {
    let s = source(
        "gfx1250",
        "v_mov_b32 v0,0\nglobal_load_b32 v1,v0,s[4:5]\ns_wait_loadcnt 0\ns_wait_xcnt 0\nglobal_store_b32 v0,v1,s[6:7]",
    );
    let module = frontend::parse(&s).unwrap();
    let mut c = config(4, 1, ArrayKind::Input);
    c.arrays[0].len = 1 << 32;
    c.arrays[1].base = 1 << 40;
    let program = lower_kernel_in_module(&module, &module.kernels[0]).unwrap();
    let provenance = Provenance {
        kernel: "k".into(),
        block_dim: c.block_dim,
        grid_dim: c.grid_dim,
        workgroup_id: c.workgroup_id,
        targets: vec!["gfx1250".into()],
        assumptions: Vec::new(),
        instructions: Vec::new(),
    };
    let mut i = Interpreter::new(&program, c, provenance).unwrap();
    assert_eq!(i.arena.node_count(), 0);
    assert!(i.global.read(0x10000, 4).is_err());
    let first = i.global_read(0x10000, 4).unwrap();
    let last = i.global_read(0x10000 + ((1u64 << 32) - 1) * 4, 4).unwrap();
    assert_eq!(i.arena.node_count(), 2);
    assert_eq!(i.global_read(0x10000, 4).unwrap(), first);
    for (v, expected) in [(first, 0), (last, (1u64 << 32) - 1)] {
        let Value::Input(e) = v else {
            panic!("input identity")
        };
        assert!(matches!(i.arena.node(e),ExprNode::InputElement{index,..}if *index==expected));
    }
    let wave = &i.waves[0];
    assert!(
        i.validate_memory_range(wave, 0, false, 0x10000 + (1u64 << 32) * 4, 4, false)
            .is_err()
    );
}
