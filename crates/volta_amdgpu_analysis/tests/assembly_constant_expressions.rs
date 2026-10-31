//! Absolute LLVM AMDGPU resource expressions; no execution or ISA coverage claim.
use volta_amdgpu_analysis::{frontend, lower};

fn source(definitions: &str, body: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--gfx950\"\n{definitions}\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n"
    )
}

#[test]
fn llvm_resource_max_or_and_forward_dependencies_resolve_exactly() {
    let text = source(
        ".set caller.num_vgpr,max(23,callee.num_vgpr,other.num_vgpr)\n\
         .set caller.private_seg_size,224+max(callee.private_seg_size)\n\
         .set caller.uses_vcc,or(0,callee.uses_vcc,other.uses_vcc)\n\
         .set callee.num_vgpr,17\n.set other.num_vgpr,31\n\
         .set callee.private_seg_size,48\n.set callee.uses_vcc,2\n.set other.uses_vcc,4\n\
         .equ mask,or(0x8000000000000000,0x7fffffffffffffff)\n\
         .equiv negative_max,max(-12,-8,-23)\n\
         .set grouped, (max(2,7)+3)-(or(4,1)+1)",
        "v_mov_b32 v0,caller.num_vgpr",
    );
    let module = frontend::parse(&text).unwrap();
    for (name, expected) in [
        ("caller.num_vgpr", 31),
        ("caller.private_seg_size", 272),
        ("caller.uses_vcc", 6),
        ("mask", -1),
        ("negative_max", -8),
        ("grouped", 4),
    ] {
        assert_eq!(module.constants[name], expected, "{name}");
    }
    assert_eq!(
        module.kernels[0].instructions[0].operands[1],
        frontend::Operand::Integer(31)
    );
    lower::lower_module_kernel(&module, "k").unwrap();
}

#[test]
fn forward_control_and_register_index_uses_keep_original_source_spans() {
    let text = source(
        ".set first,max(1,base)\n.set last,first+1\n.set delay,or(1,2)\n.set base,4",
        "s_nop delay\nv_mov_b32 v[first],1\ns_mov_b64 s[first:last],0",
    );
    let module = frontend::parse(&text).unwrap();
    assert_eq!(
        module.kernels[0].instructions[0].operands,
        [frontend::Operand::Integer(3)]
    );
    for instruction in &module.kernels[0].instructions {
        assert!(!module.source[instruction.span.start..instruction.span.end].is_empty());
    }
    lower::lower_module_kernel(&module, "k").unwrap();
}

#[test]
fn missing_cyclic_or_overflowing_dependencies_fail_even_when_unused_or_unreachable() {
    for definitions in [
        ".set result,max(23,missing)",
        ".set a,max(1,a)",
        ".set a,or(1,b)\n.set b,max(0,c)\n.set c,a+1",
        ".set a,0x7fffffffffffffff+1",
        ".set a,-0x8000000000000000-1",
        ".set low,-0x8000000000000000\n.set a,-low",
    ] {
        let error = frontend::parse(&source(definitions, "s_branch done\ndone:")).unwrap_err();
        assert!(
            error.message.contains("unresolved")
                || error.message.contains("cyclic")
                || error.message.contains("overflow"),
            "{error}"
        );
        assert!(error.span.line >= 2);
    }
}

#[test]
fn malformed_function_relocation_and_other_expression_grammar_is_never_dropped() {
    for expression in [
        "max()",
        "or()",
        "max(1,)",
        "max(,1)",
        "or(1 2)",
        "max(1,2",
        "max(1,2))",
        "min(1,2)",
        "unknown(1)",
        "1*2",
        "1/0",
        "1<<3",
        "symbol@rel32",
        ".-label",
        "1.5",
        "1e3",
        "0x10000000000000000",
        "-0xffffffffffffffff",
        "max(1,2)garbage",
    ] {
        assert!(
            frontend::parse(&source(&format!(".set result,{expression}"), "")).is_err(),
            "{expression}"
        );
    }
}

#[test]
fn reassignment_is_explicitly_refused_instead_of_rebinding_earlier_uses() {
    for directive in [".set", ".equ", ".equiv"] {
        for body in [
            format!("{directive} n,1\nv_mov_b32 v0,n\n{directive} n,2"),
            format!("{directive} n,max(1,later)\n{directive} n,2\n.set later,3"),
        ] {
            let error = frontend::parse(&source("", &body)).unwrap_err();
            assert!(
                error.message.contains("reassigned assembly constant"),
                "{error}"
            );
        }
    }
}

#[test]
fn resource_expressions_do_not_make_unknown_entry_instructions_or_directives_legal() {
    for body in [
        "unknown_instruction v0",
        "s_branch done\nunknown_instruction v0\ndone:",
        ".unknown_semantic_directive 1",
    ] {
        assert!(frontend::parse(&source(".set resource,max(2,3)", body)).is_err());
    }
    assert!(frontend::parse(&source(".set n,max(1,2)", ".amdhsa_unknown n")).is_err());
}

#[test]
fn expression_and_dependency_budgets_fail_closed_without_unbounded_recursion() {
    let nested = format!("{}1{}", "max(".repeat(150), ")".repeat(150));
    let repeated = vec!["1"; 1000].join("+");
    for expression in [nested, repeated, "1".repeat(20000)] {
        assert!(frontend::parse(&source(&format!(".set n,{expression}"), "")).is_err());
    }
    let chain = (0..150)
        .map(|n| format!(".set n{n:03},n{:03}\n", n + 1))
        .collect::<String>()
        + ".set n150,1";
    assert!(
        frontend::parse(&source(&chain, ""))
            .unwrap_err()
            .message
            .contains("depth")
    );
}

#[test]
fn signed_max_bitwise_or_and_checked_add_match_independent_small_integer_oracle() {
    for a in [-17i64, -1, 0, 1, 23] {
        for b in [-9i64, -1, 0, 2, 31] {
            for c in [-4i64, 0, 1, 7] {
                let text = source(
                    &format!(
                        ".set result, max(a,b)+(or(b,c)-a)\n.set a,{a}\n.set b,{b}\n.set c,{c}"
                    ),
                    "",
                );
                let module = frontend::parse(&text).unwrap();
                assert_eq!(module.constants["result"], a.max(b) + ((b | c) - a));
            }
        }
    }
}
