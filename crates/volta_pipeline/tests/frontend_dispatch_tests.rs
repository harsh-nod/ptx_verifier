//! File-based frontends preserve native dispatch and keep prefixes out of proofs.
use std::collections::HashMap;

use volta_equivalence::EquivCheckOptions;
use volta_graph_check::GraphConclusion;
use volta_pipeline::{
    Backend, GraphEvidence, Isa, LeanExtractionError, Solver, Spec, Verdict, analyze_source,
};
use volta_ptx_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue};

const LEGACY: &str =
    include_str!("../../volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s");
const CDNA5: &str = include_str!("../../../tests/gfx1250/fixtures/native-copy-add.s");
const SPEC: &str = "dim N; array x[N]; array out[N]; out[i]=x[i];";

fn source(target: &str) -> String {
    if target == "gfx1250" {
        CDNA5.into()
    } else {
        LEGACY.replace("--gfx950", &format!("--{target}"))
    }
}
fn config(n: u64) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((32, 1, 1));
    for (name, base, kind) in [
        ("x", 65536, ArrayKind::Input),
        ("out", 131072, ArrayKind::Output),
    ] {
        config.arrays.push(ArrayDef {
            name: name.into(),
            base,
            elem_width: 4,
            len: n,
            kind,
        });
        config.params.push(ParamValue::ArrayPtr(name.into()));
    }
    config.params.push(ParamValue::Int(n as i64));
    config
}
fn spec(n: u64) -> Spec {
    Spec::new(
        &volta_spec::parse_spec(SPEC).unwrap(),
        &HashMap::from([("N".into(), n)]),
    )
    .unwrap()
}
fn backend(target: &str) -> Backend {
    Backend::select("amdgpu", Some(target)).unwrap()
}
fn solver(sample: u64) -> Solver {
    Solver::Canonical(EquivCheckOptions {
        sample,
        ..Default::default()
    })
}

#[test]
fn native_solve_and_lean_keep_all_outputs_graph_and_actual_statistics() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let mut run =
            analyze_source(backend(target), &source(target), Some("copy"), config(32)).unwrap();
        let native = run.native.as_ref().unwrap();
        assert!(native.stats.instructions > 0);
        assert!(!native.op_counts.is_empty());
        let GraphEvidence::Checked { graph, report } = &run.graph else {
            panic!("native graph lost")
        };
        assert_eq!(report.conclusion(), GraphConclusion::Verified);
        assert_eq!(graph.provenance().workgroup_id, (0, 0, 0));
        assert_eq!(run.outputs.as_ref().unwrap().outputs[0].1.len(), 32);
        let solution = run.solve(&spec(32), &solver(0)).unwrap();
        assert_eq!(run.decide(&solution).verdict, Verdict::Accept);
        assert_eq!(run.extract_lean(&spec(32), None).unwrap().statements, 32);
    }
}

#[test]
fn selected_group_absolute_footprint_is_checked_before_sampling_or_lean() {
    let mut config = config(96);
    config.grid_dim = (3, 1, 1);
    config.workgroup_id = (1, 0, 0);
    let mut run = analyze_source(Backend::Amdgpu, LEGACY, Some("copy"), config).unwrap();
    let outputs = run.outputs.as_ref().unwrap();
    let indices: Vec<_> = outputs.outputs[0].1.iter().map(|(i, _)| *i).collect();
    assert_eq!(indices, (32..64).collect::<Vec<_>>());
    let GraphEvidence::Checked { graph, report } = &run.graph else {
        panic!("native graph lost")
    };
    assert_eq!(graph.provenance().workgroup_id, (1, 0, 0));
    assert_eq!(report.conclusion(), GraphConclusion::Verified);
    let solution = run.solve(&spec(96), &solver(1)).unwrap();
    assert_eq!(run.decide(&solution).verdict, Verdict::Reject);
    assert!(matches!(
        run.extract_lean(&spec(96), None),
        Err(LeanExtractionError::NoStatements(_))
    ));
}

#[test]
fn native_memory_and_readiness_prefixes_reject_without_lean_or_outputs() {
    for target in ["gfx950", "gfx1250"] {
        let mut config = config(32);
        config.early_memory_conflicts = true;
        let (needle, replacement) = if target == "gfx1250" {
            (
                "global_store_b32 v0, v1, s[2:3] scale_offset",
                "v_mov_b32 v0, 0\n\tglobal_store_b32 v0, v1, s[2:3] scale_offset",
            )
        } else {
            (
                "global_store_dword v[0:1], v2, off",
                "v_mov_b32 v0, 0x20000\n\tv_mov_b32 v1, 0\n\tglobal_store_dword v[0:1], v2, off",
            )
        };
        let text = source(target);
        assert!(text.contains(needle));
        let text = text.replacen(needle, replacement, 1);
        let mut run = analyze_source(backend(target), &text, Some("copy"), config).unwrap();
        assert!(run.native.as_ref().unwrap().early_memory_conflict.is_some());
        assert!(run.outputs.is_err());
        let GraphEvidence::Checked { report, .. } = &run.graph else {
            panic!("native graph lost")
        };
        assert!(matches!(
            report.conclusion(),
            GraphConclusion::Unknown { .. }
        ));
        let solution = run.solve(&spec(32), &solver(0)).unwrap();
        assert_eq!(run.decide(&solution).verdict, Verdict::Reject);
        assert!(matches!(
            run.extract_lean(&spec(32), None),
            Err(LeanExtractionError::CertifiedPrefix(_))
        ));
    }
    let mut config = config(32);
    config.early_readiness = true;
    let text = CDNA5.replacen("s_wait_kmcnt 0x0", "s_nop 0", 1);
    let run = analyze_source(Backend::AmdgpuGfx1250, &text, Some("copy"), config).unwrap();
    assert!(run.native.as_ref().unwrap().early_readiness.is_some());
    assert!(matches!(
        run.extract_lean(&spec(32), None),
        Err(LeanExtractionError::CertifiedPrefix(_))
    ));
}

#[test]
fn explicit_target_and_incomplete_trace_cannot_be_lost_in_generic_frontend() {
    assert!(analyze_source(Backend::AmdgpuGfx1250, LEGACY, Some("copy"), config(32)).is_err());
    let mut config = config(32);
    config.max_instructions = 1;
    let run = analyze_source(Backend::Amdgpu, LEGACY, Some("copy"), config).unwrap();
    assert!(matches!(
        run.extract_lean(&spec(32), None),
        Err(LeanExtractionError::Incomplete(_))
    ));
}

#[test]
fn extension_adapters_refuse_native_only_launch_fields_instead_of_ignoring_them() {
    let experimental = include_str!("amd/success/add.s");
    let mut changes: Vec<AnalysisConfig> = Vec::new();
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.grid_dim = (2, 1, 1);
    changes.push(c);
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.workgroup_id = (1, 0, 0);
    changes.push(c);
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.early_readiness = true;
    changes.push(c);
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.early_memory_conflicts = true;
    changes.push(c);
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.shared_allocations
        .push(volta_ptx_analysis::SharedAllocation {
            name: "tile".into(),
            offset: 0,
            size: 4,
        });
    changes.push(c);
    let mut c = AnalysisConfig::new((1, 1, 1));
    c.max_instructions = 1;
    changes.push(c);
    for config in changes {
        assert!(
            Isa::Amd
                .frontend()
                .analyze(experimental, Some("add"), config.clone())
                .is_err()
        );
        // Refusal precedes NKI parsing, so malformed text cannot hide an ignored field.
        assert!(Isa::Trainium.frontend().analyze("", None, config).is_err());
    }
}
