//! Measure candidate-analysis artifacts for one existing native case manifest.
//! This does not run graph checks or equivalence and emits no verification claim.
use serde_yaml::Value;
use std::{env, fs, path::Path, time::Instant};
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, ParamValue, SharedAllocation, analyze, frontend,
};

fn number(value: &Value) -> u64 {
    value.as_u64().expect("nonnegative integer")
}

fn dimensions(value: &Value) -> (u32, u32, u32) {
    let values = value.as_sequence().expect("three dimensions");
    assert_eq!(values.len(), 3);
    let at = |index| u32::try_from(number(&values[index])).expect("dimension fits u32");
    (at(0), at(1), at(2))
}

fn main() {
    let args: Vec<_> = env::args().collect();
    assert_eq!(args.len(), 3, "artifact_stats MANIFEST KERNEL");
    let path = Path::new(&args[1]);
    let document: Value = serde_yaml::from_str(&fs::read_to_string(path).unwrap()).unwrap();
    let row = document["cases"]
        .as_sequence()
        .unwrap()
        .iter()
        .find(|row| row["kernel"].as_str() == Some(&args[2]))
        .expect("kernel case exists");
    let mut config = AnalysisConfig::new(dimensions(&row["block"]));
    if !row["grid"].is_null() {
        config.grid_dim = dimensions(&row["grid"]);
    }
    if !row["workgroup"].is_null() {
        assert_eq!(dimensions(&row["workgroup"]), (0, 0, 0));
    }
    if !row["dynamic_shared"].is_null() {
        config.dynamic_shared_bytes = number(&row["dynamic_shared"]);
    }
    if !row["max_instructions"].is_null() {
        config.max_instructions = number(&row["max_instructions"]);
    }
    if !row["shared_allocations"].is_null() {
        for region in row["shared_allocations"].as_sequence().expect("LDS layout") {
            config.shared_allocations.push(SharedAllocation {
                name: region["name"].as_str().unwrap().into(),
                offset: number(&region["offset"]),
                size: number(&region["size"]),
            });
        }
    }
    for array in row["arrays"].as_sequence().unwrap() {
        config.arrays.push(ArrayDef {
            name: array["name"].as_str().unwrap().into(),
            base: number(&array["base_address"]),
            elem_width: number(&array["element_size"]),
            len: number(&array["length"]),
            kind: match array["kind"].as_str().unwrap() {
                "in" => ArrayKind::Input,
                "out" => ArrayKind::Output,
                "inout" => ArrayKind::InputOutput,
                other => panic!("unsupported array kind {other}"),
            },
        });
    }
    for param in row["params"].as_sequence().unwrap() {
        let (kind, value) = param.as_str().unwrap().split_once(':').unwrap();
        config.params.push(match kind {
            "ptr" => ParamValue::ArrayPtr(value.into()),
            "int" => ParamValue::Int(value.parse().unwrap()),
            other => panic!("unsupported parameter kind {other}"),
        });
    }
    if !row["global_values"].is_null() {
        for pair in row["global_values"].as_sequence().expect("global bindings") {
            config
                .global_values
                .push((pair[0].as_str().unwrap().into(), pair[1].as_i64().unwrap()));
        }
    }
    let source = fs::read_to_string(
        path.parent()
            .unwrap()
            .join(row["assembly"].as_str().unwrap()),
    )
    .unwrap();
    let start = Instant::now();
    let module = frontend::parse(&source).expect("parse native source");
    let parse_seconds = start.elapsed().as_secs_f64();
    let start = Instant::now();
    let result = analyze(&module, Some(&args[2]), config).expect("start native analysis");
    let analysis_seconds = start.elapsed().as_secs_f64();
    let outputs = result
        .symbolic_outputs()
        .expect("complete candidate outputs");
    let written: usize = outputs
        .outputs
        .iter()
        .map(|(_, elements)| elements.len())
        .sum();
    let expected: u64 = row["arrays"]
        .as_sequence()
        .unwrap()
        .iter()
        .filter(|array| matches!(array["kind"].as_str(), Some("out" | "inout")))
        .map(|array| number(&array["length"]))
        .sum();
    assert_eq!(written as u64, expected, "complete declared output count");
    println!(
        "{{\"kernel\":{:?},\"parse_seconds\":{},\"analysis_seconds\":{},\"instructions\":{},\"graph_events\":{},\"memory_accesses\":{},\"expression_nodes\":{},\"written_outputs\":{},\"expected_outputs\":{},\"verification_performed\":false}}",
        args[2],
        parse_seconds,
        analysis_seconds,
        result.stats.instructions,
        result.graph.events().len(),
        result.graph.accesses().len(),
        result.arena().node_count(),
        written,
        expected
    );
}
