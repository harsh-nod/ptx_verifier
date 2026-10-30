//! A recognized target must not turn missing native evidence into acceptance.
use volta_graph::{GraphBuilder, InstructionInfo, ProgramPoint, Provenance, Terminal, ThreadIx};
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

#[test]
fn completed_threads_without_native_wave_evidence_never_verify_gfx1250() {
    for threads in [1, 31, 32, 33, 63, 64, 65, 128] {
        let mut builder = GraphBuilder::new(Provenance {
            kernel: "missing-wave-evidence".into(),
            block_dim: (threads, 1, 1),
            grid_dim: (1, 1, 1),
            workgroup_id: (0, 0, 0),
            targets: vec!["gfx1250".into()],
            assumptions: vec![],
            instructions: vec![InstructionInfo {
                kind: "control",
                span: None,
            }],
        });
        for thread in 0..threads {
            builder.exit(ThreadIx(thread), ProgramPoint(0));
        }
        let graph = builder.finish(Terminal::Completed);
        assert!(
            graph.validate().is_ok(),
            "structural graph must be valid: {:?}",
            graph.validate()
        );
        let report = check_graph(&graph);
        assert_ne!(report.conclusion(), GraphConclusion::Verified);
        assert!(report.applicable_properties().contains(&Property::AmdTrace));
        assert_ne!(report.summary(Property::AmdTrace).verdict, Verdict::Pass);
    }
}
