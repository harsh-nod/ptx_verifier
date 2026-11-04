//! Complete bounded computations; no hardware or original-shape parity claim.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend};
use volta_equivalence::{EquivOutcome, check_output_equivalence};
#[test]
fn all_twenty_compiler_workload_families_match_complete_independent_specs() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../tests/gfx1250");
    let cases: serde_yaml::Value =
        serde_yaml::from_str(&std::fs::read_to_string(root.join("portable-cases.json")).unwrap())
            .unwrap();
    let source =
        std::fs::read_to_string(root.join("fixtures/native-portable-workloads.s")).unwrap();
    let module = frontend::parse(&source).unwrap();
    let mut failures = Vec::new();
    for case in cases["cases"].as_sequence().unwrap() {
        let kernel = case["kernel"].as_str().unwrap();
        let block = case["block"].as_sequence().unwrap();
        let mut config = AnalysisConfig::new((
            block[0].as_u64().unwrap() as u32,
            block[1].as_u64().unwrap() as u32,
            block[2].as_u64().unwrap() as u32,
        ));
        for array in case["arrays"].as_sequence().unwrap() {
            config.arrays.push(ArrayDef {
                name: array["name"].as_str().unwrap().into(),
                base: array["base_address"].as_u64().unwrap(),
                elem_width: array["element_size"].as_u64().unwrap(),
                len: array["length"].as_u64().unwrap(),
                kind: match array["kind"].as_str().unwrap() {
                    "in" => ArrayKind::Input,
                    "index" => ArrayKind::IndexInput,
                    "out" => ArrayKind::Output,
                    kind => panic!("{kind}"),
                },
            });
        }
        for param in case["params"].as_sequence().unwrap() {
            let (kind, value) = param.as_str().unwrap().split_once(':').unwrap();
            config.params.push(match kind {
                "ptr" => ParamValue::ArrayPtr(value.into()),
                "int" => ParamValue::Int(value.parse().unwrap()),
                other => panic!("{other}"),
            });
        }
        let result = analyze(&module, Some(kernel), config).unwrap();
        let actual = match result.symbolic_outputs() {
            Ok(outputs) => outputs,
            Err(e) => {
                failures.push(format!("{kernel}: {e:?}"));
                continue;
            }
        };
        result.graph().validate().unwrap();
        let parsed = volta_spec::parse_spec(
            &std::fs::read_to_string(root.join(case["spec"].as_str().unwrap())).unwrap(),
        )
        .unwrap();
        let dims = case["dimensions"]
            .as_mapping()
            .unwrap()
            .iter()
            .map(|(k, v)| (k.as_str().unwrap().to_string(), v.as_u64().unwrap()))
            .collect();
        let (env, spec) = volta_spec::instantiate(&parsed, &dims).unwrap();
        let expected = volta_spec::unfold(&spec, &env, 0).unwrap();
        for (name, items) in &expected.outputs {
            let actual_items = &actual.outputs.iter().find(|(n, _)| n == name).unwrap().1;
            assert_eq!(
                actual_items.iter().map(|(i, _)| i).collect::<Vec<_>>(),
                items.iter().map(|(i, _)| i).collect::<Vec<_>>(),
                "{kernel}"
            );
        }
        let names = expected
            .outputs
            .iter()
            .map(|(n, _)| n.clone())
            .collect::<Vec<_>>();
        let outcome = check_output_equivalence(actual, &expected, &names).unwrap();
        if !matches!(outcome, EquivOutcome::Equivalent) {
            failures.push(format!("{kernel}: {outcome:?}"));
        } else {
            eprintln!("PASS {kernel}");
        }
    }
    assert!(failures.is_empty(), "{}", failures.join("\n"));
}
