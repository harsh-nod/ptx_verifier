use volta_amdgpu_analysis::{frontend, lower};

const UPSTREAM_COPY: &str = include_str!("fixtures/upstream-copy.s");
const HELPER: &str = ".type helper,@function\nhelper:\nv_future_unsupported v0\ns_setpc_b64 s[30:31]\n.Lhelper_end:\n.size helper, .Lhelper_end-helper\n";

fn entry(body: &str) -> String {
    format!(".type k,@function\nk:\n{body}\n.size k, .-k\n")
}

fn descriptor(target: &str, name: &str) -> String {
    let wave32 = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1\n"
    } else {
        ""
    };
    format!(".amdhsa_kernel {name}\n{wave32}.end_amdhsa_kernel\n")
}

fn module(target: &str, bodies: &str) -> String {
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n{bodies}{}",
        descriptor(target, "k")
    )
}

fn metadata(target: &str, name: &str) -> String {
    let wave_size = if target == "gfx1250" { 32 } else { 64 };
    format!(
        ".amdgpu_metadata\n---\namdhsa.version: [1, 2]\namdhsa.kernels:\n  - .name: {name}\n    .wavefront_size: {wave_size}\n...\n.end_amdgpu_metadata\n"
    )
}

#[test]
fn unchanged_upstream_compiler_copy_excludes_non_entry_helper() {
    let module = frontend::parse(UPSTREAM_COPY).unwrap();
    assert_eq!(module.source, UPSTREAM_COPY);
    assert_eq!(module.target.as_deref(), Some("gfx950:xnack-"));
    assert_eq!(module.code_object_version, Some(6));
    assert_eq!(module.metadata_version.as_deref(), Some(&[1, 2][..]));
    assert_eq!(module.kernels.len(), 1);
    let copy = &module.kernels[0];
    assert_eq!(copy.name, "copy");
    assert_eq!(copy.instructions.len(), 7);
    assert_eq!(copy.descriptor.get("kernarg_size"), Some(16));
    assert_eq!(copy.descriptor.get("next_free_sgpr"), Some(4));
    assert_eq!(copy.args.len(), 2);
    assert_eq!((copy.args[1].offset, copy.args[1].size), (8, 8));
    assert_eq!(copy.instructions.last().unwrap().mnemonic, "s_endpgm");
    for instruction in &copy.instructions {
        let span = instruction.span;
        assert!(UPSTREAM_COPY[span.start..span.end].starts_with(&instruction.mnemonic));
        assert_eq!(
            UPSTREAM_COPY
                .lines()
                .nth(span.line - 1)
                .unwrap()
                .trim_start(),
            &UPSTREAM_COPY[span.start..span.end]
        );
    }
    lower::lower_module_kernel(&module, "copy").unwrap();
    assert!(lower::lower_module_kernel(&module, "__clang_ocl_kern_imp_copy").is_err());
}

#[test]
fn entries_and_helpers_are_classified_independently_of_order_and_target() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        for bodies in [
            format!("{HELPER}{}", entry("s_endpgm")),
            format!("{}{HELPER}", entry("s_endpgm")),
        ] {
            for source in [
                module(target, &bodies),
                format!(
                    ".amdgcn_target \"{target}\"\n{}\n.text\n{bodies}",
                    descriptor(target, "k")
                ),
            ] {
                let module = frontend::parse(&source).unwrap();
                assert_eq!(module.kernels.len(), 1);
                assert_eq!(module.kernels[0].name, "k");
                assert_eq!(module.kernels[0].instructions.len(), 1);
                lower::lower_module_kernel(&module, "k").unwrap();
            }
        }
    }
}

#[test]
fn metadata_only_entries_are_selected_and_checked() {
    for target in ["gfx942", "gfx950"] {
        let source = format!(
            ".amdgcn_target \"{target}\"\n{HELPER}{}{}",
            entry("s_endpgm"),
            metadata(target, "k")
        );
        let module = frontend::parse(&source).unwrap();
        assert_eq!(module.kernels.len(), 1);
        assert_eq!(module.kernels[0].name, "k");
        assert!(frontend::parse(&source.replace("s_endpgm", "v_future_unsupported v0")).is_err());
    }
}

#[test]
fn metadata_selection_keeps_the_gfx1250_descriptor_wave32_requirement() {
    let source = format!(
        ".amdgcn_target \"gfx1250\"\n{HELPER}{}{}",
        entry("s_endpgm"),
        metadata("gfx1250", "k")
    );
    assert!(
        frontend::parse(&source)
            .unwrap_err()
            .message
            .contains("requires wave32")
    );
    let module = frontend::parse(&(source + &descriptor("gfx1250", "k"))).unwrap();
    assert_eq!(module.kernels.len(), 1);
}

#[test]
fn late_function_types_and_named_local_branches_keep_distinct_bodies() {
    let source = module(
        "gfx950",
        &format!(
            "{}{}",
            HELPER.replace(".type helper,@function\n", "") + ".type helper,@function\n",
            entry("s_branch later\nback:\ns_endpgm\nlater:\ns_branch back")
        ),
    );
    let module = frontend::parse(&source).unwrap();
    let kernel = &module.kernels[0];
    assert_eq!(kernel.labels["back"], 1);
    assert_eq!(kernel.labels["later"], 2);
    lower::lower_module_kernel(&module, "k").unwrap();
}

#[test]
fn helper_classification_uses_declarations_rather_than_symbol_spelling() {
    for helper in [
        HELPER
            .replace("helper", "ordinary_function")
            .replace("@function", "%function"),
        HELPER.replace("helper", ".local_function"),
        HELPER
            .replace(".type helper,@function\n", "")
            .replace("helper:\n", "helper: .type helper,@function\n"),
    ] {
        let source = module("gfx950", &format!("{}{helper}", entry("s_endpgm")));
        let module = frontend::parse(&source).unwrap();
        assert_eq!(module.kernels.len(), 1);
        assert_eq!(module.kernels[0].name, "k");
    }
    for annotation in [
        "; .type helper,@function",
        "# .type helper,@function",
        "// .type helper,@function",
        "/* .type helper,@function */",
    ] {
        let helper = HELPER.replace(".type helper,@function", annotation);
        assert!(
            frontend::parse(&module("gfx950", &format!("{}{helper}", entry("s_endpgm")))).is_err()
        );
    }
}

#[test]
fn excluding_helper_instructions_never_excludes_module_state_directives() {
    for directive in [
        ".unknown_semantic_directive 1",
        ".amdgcn_target \"gfx942\"",
        ".pushsection .data",
        ".amdhsa_wavefront_size32 1",
        ".long 0x12345678",
    ] {
        let helper = HELPER.replace("v_future_unsupported v0", directive);
        assert!(
            frontend::parse(&module("gfx950", &format!("{}{helper}", entry("s_endpgm")))).is_err(),
            "{directive}"
        );
    }
}

#[test]
fn descriptor_free_handwritten_modules_keep_strict_whole_module_parsing() {
    let source = format!(".amdgcn_target \"gfx950\"\n{}{HELPER}", entry("s_endpgm"));
    assert!(
        frontend::parse(&source)
            .unwrap_err()
            .message
            .contains("unsupported")
    );
}

#[test]
fn entry_bodies_are_never_skipped_for_calls_or_unreachable_instructions() {
    for instruction in [
        "s_setpc_b64 s[30:31]",
        "s_swappc_b64 s[0:1], s[30:31]",
        "s_call_b64 s[0:1], helper",
        "s_cbranch_i_fork s[0:1], helper",
        "v_future_unsupported v0",
    ] {
        for body in [
            format!("{instruction}\ns_endpgm"),
            format!("s_branch .Lend\n{instruction}\n.Lend:\ns_endpgm"),
        ] {
            let source = module("gfx950", &format!("{}{HELPER}", entry(&body)));
            match frontend::parse(&source) {
                Ok(module) => {
                    // Recognized calls still require a validated reaching code
                    // definition; an entry cannot return without a caller.
                    assert!(
                        lower::lower_module_kernel(&module, "k").is_err(),
                        "{instruction}"
                    );
                }
                Err(error) => {
                    assert!(
                        error.message.contains("unsupported"),
                        "{instruction}: {error}"
                    );
                    assert!(source[error.span.start..error.span.end].contains(instruction));
                }
            }
        }
    }
}

#[test]
fn direct_branches_cannot_reach_excluded_helper_code() {
    for target in ["helper", ".Lhelper_end", "alias", ".Lfunc_end_alias"] {
        let helper = HELPER.replace("helper:\n", "helper:\nalias:\n.Lfunc_end_alias:\n");
        let source = module(
            "gfx950",
            &format!("{}{helper}", entry(&format!("s_branch {target}\ns_endpgm"))),
        );
        let module = frontend::parse(&source).unwrap();
        assert!(
            lower::lower_module_kernel(&module, "k")
                .unwrap_err()
                .message
                .contains("undefined branch label")
        );
    }
}

#[test]
fn helper_label_collisions_and_aliases_cannot_change_entry_boundaries() {
    let source = module(
        "gfx950",
        &format!("{}{HELPER}", entry(".Lcollision:\ns_endpgm")),
    );
    let collision = source.replace(".Lhelper_end:", ".Lcollision:\n.Lhelper_end:");
    assert!(
        frontend::parse(&collision)
            .unwrap_err()
            .message
            .contains("duplicate assembly label")
    );
    let overlap = module("gfx950", &format!("{}{HELPER}", entry("helper:\ns_endpgm")));
    assert!(frontend::parse(&overlap).is_err());
    let alias_before = module(
        "gfx950",
        &format!("{}alias:\n{HELPER}", entry("s_branch alias\ns_endpgm")),
    );
    assert!(frontend::parse(&alias_before).is_err());
}

#[test]
fn an_additional_unsupported_entry_is_checked_in_full() {
    let source = module("gfx950", &format!("{}{HELPER}", entry("s_endpgm")))
        + ".type another,@function\nanother:\ns_branch .Ldone\ns_setpc_b64 s[30:31]\n.Ldone:\ns_endpgm\n.size another, .-another\n"
        + &descriptor("gfx950", "another");
    let error = frontend::parse(&source).unwrap_err();
    assert!(error.message.contains("s_setpc_b64"));
    assert_eq!(
        &source[error.span.start..error.span.end],
        "s_setpc_b64 s[30:31]"
    );
}

#[test]
fn helpers_promoted_to_entries_are_validated_even_when_not_selected_for_execution() {
    let source = module("gfx950", &format!("{}{HELPER}", entry("s_endpgm")));
    for declaration in [descriptor("gfx950", "helper"), metadata("gfx950", "helper")] {
        assert!(
            frontend::parse(&(source.clone() + &declaration))
                .unwrap_err()
                .message
                .contains("unsupported")
        );
    }
}

#[test]
fn malformed_or_unbounded_helpers_cannot_hide_kernel_bytes() {
    for helper in [
        HELPER.replace(".type helper,@function\n", ""),
        HELPER.replace(".size helper, .Lhelper_end-helper\n", ""),
        HELPER.replace(".size helper,", ".size other,"),
        format!(
            ".size helper, .-helper\n{}",
            HELPER.replace(".size helper, .Lhelper_end-helper\n", "")
        ),
    ] {
        assert!(
            frontend::parse(&module("gfx950", &format!("{}{helper}", entry("s_endpgm")))).is_err(),
            "{helper}"
        );
    }
    for bodies in [
        format!(
            "{}{HELPER}",
            entry("s_endpgm").replace(".size k, .-k\n", "")
        ),
        format!("{}{HELPER}", entry("v_mov_b32 v0, 0")),
    ] {
        assert!(frontend::parse(&module("gfx950", &bodies)).is_err());
    }
}

#[test]
fn missing_or_mismatched_entry_definitions_and_descriptors_fail() {
    let source = module("gfx950", &format!("{}{HELPER}", entry("s_endpgm")));
    for source in [
        source.replace(".amdhsa_kernel k", ".amdhsa_kernel missing"),
        source.clone() + &metadata("gfx950", "missing"),
        source.clone() + &descriptor("gfx950", "k"),
        source.clone() + HELPER,
        source.clone() + &entry("s_endpgm"),
        source.clone()
            + ".amdgpu_metadata\n---\namdhsa.version: [1,2]\namdhsa.kernels: [{.name: k, .symbol: helper.kd}]\n.end_amdgpu_metadata\n",
    ] {
        assert!(frontend::parse(&source).is_err(), "{source}");
    }
}

#[test]
fn globals_metadata_comments_and_original_source_locations_survive_selection() {
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let source = module(
            target,
            &format!(
                "/* .type phantom,@function\nphantom:\n*/\n{HELPER}{}\n.type g,@object\n.data\n.p2align 2\ng:\n.long 0x12345678\n.size g,4\n.text\n",
                entry("v_mov_b32 v0, 9\ns_endpgm")
            ),
        ) + &metadata(target, "k");
        let module = frontend::parse(&source).unwrap();
        assert_eq!(module.source, source);
        assert_eq!(module.globals.len(), 1);
        let object = &module.globals[0];
        assert_eq!(object.initial_bytes, [0x78, 0x56, 0x34, 0x12]);
        assert_eq!(&source[object.span.start..object.span.end], "g:");
        assert_eq!(
            module.kernels[0].instructions[0].span.line,
            source
                .lines()
                .position(|line| line == "v_mov_b32 v0, 9")
                .unwrap()
                + 1
        );
        lower::lower_module_kernel(&module, "k").unwrap();
        assert!(frontend::parse(&source.replace(".size g,4", ".size g,8")).is_err());
        assert!(
            frontend::parse(&source.replace(
                ".type phantom,@function",
                "*/\n.unknown_semantic_directive\n/*"
            ))
            .is_err()
        );
    }
}
