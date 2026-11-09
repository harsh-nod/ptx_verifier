//! Persisted AMD scope annotations retain their existing text and distinguish new scopes.

use volta_graph::{
    Assumption, GraphBuilder, InstructionInfo, ProgramPoint, Provenance, Terminal, ThreadIx,
    ThreadUnit,
};

fn graph(
    target: &str,
    lanes: u32,
    grid_dim: (u32, u32, u32),
    workgroup_id: (u32, u32, u32),
    assumptions: Vec<Assumption>,
) -> volta_graph::EventGraph {
    let mut builder = GraphBuilder::new(Provenance {
        kernel: "scope".into(),
        block_dim: (lanes, 1, 1),
        unit: ThreadUnit::Wave { lanes },
        grid_dim,
        workgroup_id,
        targets: vec![target.into()],
        assumptions,
        instructions: vec![InstructionInfo {
            kind: "exit",
            span: None,
        }],
    });
    builder.exit(ThreadIx(0), ProgramPoint(0));
    builder.finish(Terminal::Completed)
}

#[test]
fn native_selected_workgroup_assumption_keeps_its_unit_api_and_dump_text() {
    let scope = Assumption::SingleWorkgroupAnalyzed;
    assert_eq!(format!("{scope:?}"), "SingleWorkgroupAnalyzed");
    assert_eq!(
        scope.describe(),
        "only the selected AMD workgroup is analyzed; other workgroups and inter-workgroup conflicts are outside this result"
    );
    for (target, lanes) in [("gfx942", 64), ("gfx950", 64), ("gfx1250", 32)] {
        let graph = graph(target, lanes, (3, 4, 6), (2, 3, 5), vec![scope]);
        graph.validate().unwrap();
        assert_eq!(
            graph
                .dump()
                .lines()
                .filter(|line| line.starts_with("assume "))
                .collect::<Vec<_>>(),
            ["assume SingleWorkgroupAnalyzed"]
        );
    }
}

#[test]
fn coordinate_scope_records_the_selected_workgroup_without_a_grid_safety_claim() {
    let selected = Assumption::SelectedWorkgroupAnalyzed { id: (2, 3, 5) };
    let graph = graph("gfx950", 64, (3, 4, 6), (2, 3, 5), vec![selected]);
    graph.validate().unwrap();
    let dump = graph.dump();
    assert!(dump.contains("grid 3,4,6 workgroup 2,3,5"));
    assert!(dump.contains("assume SelectedWorkgroupAnalyzed { id: (2, 3, 5) }\n"));
    assert!(
        selected
            .describe()
            .contains("cross-workgroup interactions are not checked")
    );
    assert_ne!(selected, Assumption::SingleWorkgroupAnalyzed);
    assert_ne!(
        selected,
        Assumption::SelectedWorkgroupAnalyzed { id: (0, 0, 0) }
    );
}

#[test]
fn representative_grid_scope_is_distinct_and_new_variants_follow_existing_ones() {
    let scope = Assumption::UniformWorkgroupControlFlow;
    let graph = graph("gfx950", 64, (2, 3, 1), (0, 0, 0), vec![scope]);
    graph.validate().unwrap();
    let dump = graph.dump();
    assert!(dump.contains("assume UniformWorkgroupControlFlow\n"));
    assert!(!dump.contains("SingleWorkgroupAnalyzed"));
    assert!(!dump.contains("SelectedWorkgroupAnalyzed"));
    assert!(
        scope
            .describe()
            .contains("not inter-workgroup memory safety")
    );
    assert!(Assumption::SharedMemoryOnly < Assumption::SelectedWorkgroupAnalyzed { id: (0, 0, 0) });
    assert!(Assumption::SelectedWorkgroupAnalyzed { id: (0, 0, 0) } < scope);
}
