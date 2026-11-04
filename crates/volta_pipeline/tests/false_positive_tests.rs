//! Aligned named barriers must rendezvous at the same visit to an instruction. A static PC
//! match cannot join predicate-selected loop iterations; unaligned barriers keep their usual
//! thread-count semantics.

#[macro_use]
mod common;

use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

use common::*;

/// One output array `out`, passed as the only parameter.
fn out_config(threads: u32, elem_width: u64, len: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((threads, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".to_string(),
        base: 0x20000,
        elem_width,
        len,
        kind: ArrayKind::Output,
    }];
    config.params = vec![ParamValue::ArrayPtr("out".to_string())];
    config
}

/// Lanes 0-15 and 16-31 reach the `.aligned` `bar.sync` on different loop iterations (UB).
#[test]
fn test_aligned_bar_sync_reached_on_different_iterations() {
    for barrier in [
        "bar.sync 0",
        "bar.sync 0, 32",
        "barrier.sync.aligned 0",
        "barrier.sync.aligned 0, 32",
    ] {
        let source = ptx!("false_positive/aligned_bar_sync_reached_on_different_iterations")
            .replace("bar.sync 0", barrier);
        let checked = check(&parse(&source), None, out_config(32, 4, 1));
        let deadlock = checked.report.deadlock().unwrap_or_else(|| {
            panic!(
                "{barrier}: expected a deadlock, got {:?}",
                checked.report.terminal
            )
        });
        assert_eq!(
            deadlock.blocked.len(),
            32,
            "{barrier}: every lane stays blocked"
        );
    }
}

#[test]
fn test_aligned_bar_arrive_reached_on_different_iterations() {
    for barrier in ["bar.arrive 0, 64", "barrier.arrive.aligned 0, 64"] {
        let source = ptx!("failing/aligned_bar_arrive_reached_on_different_iterations")
            .replace("bar.arrive 0, 64", barrier);
        let checked = check(&parse(&source), None, AnalysisConfig::new((64, 1, 1)));
        let deadlock = checked
            .report
            .deadlock()
            .expect("consumer warp must stay blocked");
        let blocked: Vec<_> = deadlock.blocked.iter().map(|t| t.thread.0).collect();
        assert_eq!(blocked, (32..64).collect::<Vec<_>>(), "{barrier}");
    }
}

/// Both skipped and repeated aligned visits remain valid when the warp agrees on them.
#[test]
fn test_aligned_bar_sync_uniform_loop_visits() {
    for (condition, syncs) in [("0", 32), ("1", 32), ("%r7", 64)] {
        let source = ptx!("false_positive/aligned_bar_sync_reached_on_different_iterations")
            .replace(
                "setp.eq.u32 %p3, %r7, %r6",
                &format!("setp.eq.u32 %p3, %r7, {condition}"),
            );
        let output = run_kernel(&parse(&source), None, out_config(32, 4, 1)).unwrap();
        assert_eq!(render_outputs(&output), "out[0] = 42\n");
        assert_eq!(output.stats.block_syncs, syncs);
    }
}

#[test]
fn test_unaligned_barrier_arrive_can_join_different_loop_visits() {
    let source = ptx!("failing/aligned_bar_arrive_reached_on_different_iterations")
        .replace("bar.arrive 0, 64", "barrier.arrive 0, 64");
    run_kernel(&parse(&source), None, AnalysisConfig::new((64, 1, 1))).unwrap();
}

#[test]
fn test_unaligned_barrier_sync_can_join_different_loop_visits() {
    for barrier in ["barrier.sync 0", "barrier.sync 0, 32"] {
        let source = ptx!("false_positive/aligned_bar_sync_reached_on_different_iterations")
            .replace("bar.sync 0", barrier);
        let output = run_kernel(&parse(&source), None, out_config(32, 4, 1)).unwrap();
        assert_eq!(render_outputs(&output), "out[0] = 42\n");
    }
}
