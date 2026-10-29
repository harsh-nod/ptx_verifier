//! Native static counterparts for the portable barrier operand contract.
use volta_amdgpu_analysis::frontend;

const SOURCE: &str = include_str!("../../../tests/gfx1250/portable-graph/native-named-barriers.s");
const MUTATIONS: &str =
    include_str!("../../../tests/gfx1250/portable-boundaries/mechanism-syntax-mutations.tsv");

fn replace_instruction(kernel: &str, original: &str, replacement: &str) -> String {
    let start = SOURCE.find(&format!("\n{kernel}:")).unwrap();
    let end = start + SOURCE[start..].find(".Lfunc_end").unwrap();
    let body = &SOURCE[start..end];
    assert_eq!(body.matches(original).count(), 1);
    format!(
        "{}{}{}",
        &SOURCE[..start],
        body.replacen(original, replacement, 1),
        &SOURCE[end..]
    )
}

#[test]
fn actual_named_barrier_missing_and_extra_operands_reject_before_reachability() {
    frontend::parse(SOURCE).expect("unaltered genuine allocated named barriers parse");
    let mut cases = 0;
    for row in MUTATIONS.lines().skip(1) {
        let fields = row.split('\t').collect::<Vec<_>>();
        let [id, kernel, original, malformed] = fields.as_slice() else {
            panic!("unexpected mutation schema: {row}")
        };
        for instruction in [
            malformed.to_string(),
            format!("s_branch .Lmechanism_skip\n{malformed}\n.Lmechanism_skip:"),
            format!("s_mov_b32 exec_lo, 0\n{malformed}"),
        ] {
            let source = replace_instruction(kernel, original, &instruction);
            assert!(
                frontend::parse(&source).is_err(),
                "static malformed barrier accepted: {id}: {instruction}"
            );
        }
        cases += 1;
    }
    assert_eq!(cases, 9, "complete MC-checked native operand inventory");
}
