//! Exact initialized .asciz bytes; no hostcall, call or new ISA support.
use volta_amdgpu_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, ParamValue, analyze, frontend, lower,
};

fn source(target: &str, literal: &str, size: usize) -> String {
    let wave32 = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1\n"
    } else {
        ""
    };
    format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n\
         .text\n.type k,@function\nk:\ns_endpgm\n.size k,.-k\n\
         .amdhsa_kernel k\n{wave32}.end_amdhsa_kernel\n\
         .type __const.__assert_fail.fmt,@object\n\
         .section .rodata.str1.16,\"aMS\",@progbits,1\n.p2align 4,0\n\
         __const.__assert_fail.fmt:\n.asciz {literal}\n\
         .size __const.__assert_fail.fmt,{size}\n"
    )
}

#[test]
fn original_compiler_assertion_format_keeps_all_bytes_nul_alignment_and_source() {
    let literal = r#""%s:%u: %s: Device-side assertion `%s' failed.\n""#;
    let expected = b"%s:%u: %s: Device-side assertion `%s' failed.\n\0";
    assert_eq!(expected.len(), 47);
    for target in ["gfx942", "gfx950", "gfx1250"] {
        let text = source(target, literal, expected.len());
        let module = frontend::parse(&text).unwrap();
        assert_eq!(module.source, text);
        assert_eq!(module.globals.len(), 1);
        let object = &module.globals[0];
        assert_eq!(object.symbol, "__const.__assert_fail.fmt");
        assert_eq!(object.initial_bytes, expected);
        assert_eq!(
            (object.size, object.alignment, object.read_only),
            (47, 16, true)
        );
        assert_eq!(
            &text[object.span.start..object.span.end],
            "__const.__assert_fail.fmt:"
        );
        lower::lower_module_kernel(&module, "k").unwrap();
    }
}

#[test]
fn supported_escapes_empty_literals_and_comment_characters_are_exact() {
    for (literal, expected) in [
        (r#""""#, b"\0".as_slice()),
        (r#""a\\b\"c\nd\re\tf""#, b"a\\b\"c\nd\re\tf\0".as_slice()),
        (
            r#""; # // /* */ :,%'`""#,
            b"; # // /* */ :,%'`\0".as_slice(),
        ),
    ] {
        for target in ["gfx942", "gfx950", "gfx1250"] {
            let text = source(target, literal, expected.len());
            let module = frontend::parse(&text).unwrap();
            assert_eq!(module.globals[0].initial_bytes, expected, "{literal}");
            let with_comment = text.replace(
                &format!(".asciz {literal}"),
                &format!(".asciz {literal} ; after literal"),
            );
            assert_eq!(
                frontend::parse(&with_comment).unwrap().globals[0].initial_bytes,
                expected
            );
        }
    }
}

#[test]
fn malformed_unknown_multiple_trailing_and_non_ascii_literals_are_refused() {
    for literal in [
        "",
        "plain",
        "\"unterminated",
        "\"unterminated\\\"",
        "\"a\"junk",
        "\"a\" \"b\"",
        "\"a\",\"b\"",
        "\"a\",",
        "\"a\"+1",
        "\"a\"@rel32",
        "\"é\"",
        "\"a\tb\"",
        "\"a\rb\"",
        "\"a\nb\"",
        "\"a\0b\"",
        r#""\x41""#,
        r#""\101""#,
        r#""\0""#,
        r#""\q""#,
        r#""\u0041""#,
    ] {
        for target in ["gfx942", "gfx950", "gfx1250"] {
            assert!(
                frontend::parse(&source(target, literal, 1)).is_err(),
                "{target}: {literal:?}"
            );
        }
    }
}

#[test]
fn declared_object_size_section_and_termination_constraints_stay_strict() {
    let original = source("gfx950", r#""abc""#, 4);
    for text in [
        original.replace(
            ".size __const.__assert_fail.fmt,4",
            ".size __const.__assert_fail.fmt,3",
        ),
        original.replace(
            ".size __const.__assert_fail.fmt,4",
            ".size __const.__assert_fail.fmt,5",
        ),
        original.replace(".size __const.__assert_fail.fmt,4", ""),
        original.replace(".asciz \"abc\"", ".asciz \"abc\"\n.text"),
        original.replace(".rodata.str1.16", ".unsupported"),
        original.replace(".p2align 4,0", ".p2align 25,0"),
        original.replace(".p2align 4,0", ".p2align 4,0,1"),
        original.replace(".asciz \"abc\"", ".asciz \"abc\"\n.asciz \"x\""),
        original.replace("s_endpgm", ".asciz \"abc\"\ns_endpgm"),
        original.replace(".type __const.__assert_fail.fmt,@object", ""),
    ] {
        assert!(frontend::parse(&text).is_err(), "{text}");
    }
    let writable = original.replace(".rodata.str1.16,\"aMS\"", ".data,\"aw\"");
    assert!(!frontend::parse(&writable).unwrap().globals[0].read_only);
}

#[test]
fn nul_bytes_count_toward_each_object_and_the_existing_allocation_bound() {
    let zero = source("gfx950", r#""""#, 1);
    let exact = zero
        .replace(".asciz \"\"", ".zero 16777215\n.asciz \"\"")
        .replace(
            ".size __const.__assert_fail.fmt,1",
            ".size __const.__assert_fail.fmt,16777216",
        );
    let module = frontend::parse(&exact).unwrap();
    assert_eq!(module.globals[0].initial_bytes.len(), 16777216);
    drop(module);
    let overflow = exact.replace(".zero 16777215", ".zero 16777216");
    assert!(
        frontend::parse(&overflow)
            .unwrap_err()
            .message
            .contains("envelope")
    );
    let huge_literal = source("gfx950", &format!("\"{}\"", "x".repeat(16777216)), 16777217);
    assert!(
        frontend::parse(&huge_literal)
            .unwrap_err()
            .message
            .contains("envelope")
    );
}

#[test]
fn string_bytes_do_not_change_plain_ascii_profile_or_make_calls_legal() {
    let original = source("gfx950", r#""abc""#, 4);
    let plain_ascii = original
        .replace(".asciz", ".ascii")
        .replace(".fmt,4", ".fmt,3");
    assert_eq!(
        frontend::parse(&plain_ascii).unwrap().globals[0].initial_bytes,
        b"abc"
    );
    for text in [
        original.replace(".asciz", ".string"),
        original.replace("s_endpgm", "s_call_b64 s[30:31],helper\ns_endpgm"),
        original.replace(
            "s_endpgm",
            "s_branch done\nunknown_instruction v0\ndone:\ns_endpgm",
        ),
        plain_ascii.replace("\"abc\"", r#""a\nb""#),
    ] {
        assert!(frontend::parse(&text).is_err());
    }
}

#[test]
fn nobits_storage_preserves_zero_fill_and_refuses_every_nonzero_initializer() {
    for section in [
        ".bss",
        ".section .bss,\"aw\",@nobits",
        ".section .bss,\"aw\"",
        ".section .bss.zeros,\"aw\"",
        ".section .data.zeros,\"aw\",@nobits",
        ".section .rodata.zeros,\"a\",@nobits",
    ] {
        for (initializer, size) in [
            (".asciz \"\"", 1),
            (".byte 0", 1),
            (".long 0", 4),
            (".zero 4", 4),
            (".space 4,0", 4),
            (".fill 2,2,0", 4),
        ] {
            let text = source("gfx950", "\"\"", size)
                .replace(".section .rodata.str1.16,\"aMS\",@progbits,1", section)
                .replace(".asciz \"\"", initializer);
            let module = frontend::parse(&text).unwrap();
            assert_eq!(module.globals[0].initial_bytes, vec![0; size]);
        }
        for (initializer, size) in [
            (".asciz \"A\"", 2),
            (".ascii \"A\"", 1),
            (".byte 1", 1),
            (".long 1", 4),
            (".space 4,1", 4),
            (".fill 2,2,1", 4),
        ] {
            let text = source("gfx950", "\"\"", size)
                .replace(".section .rodata.str1.16,\"aMS\",@progbits,1", section)
                .replace(".asciz \"\"", initializer);
            assert!(
                frontend::parse(&text)
                    .unwrap_err()
                    .message
                    .contains("NOBITS"),
                "{section}: {initializer}"
            );
        }
    }
}

#[test]
fn canonical_or_redefined_section_type_contradictions_and_unknown_types_refuse() {
    let original = source("gfx950", "\"\"", 1);
    for section in [
        ".section .data,\"aw\",@nobits",
        ".section .rodata,\"a\",@nobits",
        ".section .bss,\"aw\",@progbits",
        ".section .data.custom,\"aw\",@note",
        ".section .data.custom,\"aw\",unknown",
        ".section .data.custom,\"aw\",",
    ] {
        let text = original.replace(".section .rodata.str1.16,\"aMS\",@progbits,1", section);
        assert!(
            frontend::parse(&text)
                .unwrap_err()
                .message
                .contains("storage type"),
            "{section}"
        );
    }
    let changed = original.replace(
        ".section .rodata.str1.16,\"aMS\",@progbits,1",
        ".section .data.custom,\"aw\",@nobits",
    ) + ".section .data.custom,\"aw\",@progbits\n";
    assert!(
        frontend::parse(&changed)
            .unwrap_err()
            .message
            .contains("cannot change")
    );
}

#[test]
fn explicit_custom_storage_types_and_section_transitions_do_not_leak_nobits_state() {
    for section in [
        ".section .bss.custom,\"aw\",@progbits",
        ".section .data.custom,\"aw\",@progbits",
    ] {
        let text = source("gfx950", "\"A\"", 2)
            .replace(".section .rodata.str1.16,\"aMS\",@progbits,1", section);
        assert_eq!(
            frontend::parse(&text).unwrap().globals[0].initial_bytes,
            b"A\0"
        );
    }
    let text = source("gfx950", "\"\"", 1)
        .replace(".section .rodata.str1.16,\"aMS\",@progbits,1", ".bss")
        + ".text\n.data\n.type second,@object\nsecond:\n.asciz \"A\"\n.size second,2\n\
           .bss\n.type third,@object\nthird:\n.zero 2\n.size third,2\n\
           .rodata\n.type fourth,@object\nfourth:\n.asciz \"B\"\n.size fourth,2\n";
    let module = frontend::parse(&text).unwrap();
    assert_eq!(
        module
            .globals
            .iter()
            .map(|g| g.initial_bytes.as_slice())
            .collect::<Vec<_>>(),
        [
            b"\0".as_slice(),
            b"A\0".as_slice(),
            b"\0\0".as_slice(),
            b"B\0".as_slice()
        ]
    );
    assert_eq!(
        module
            .globals
            .iter()
            .map(|g| g.read_only)
            .collect::<Vec<_>>(),
        [false, false, false, true]
    );
}

#[test]
fn readonly_section_names_cannot_be_weakened_by_writable_flags() {
    for section in [
        ".section .rodata,\"aw\",@progbits",
        ".section .rodata.custom,\"aw\",@progbits",
        ".section .rodata.custom,\"aw\",@nobits",
    ] {
        let text = source("gfx950", "\"\"", 1)
            .replace(".section .rodata.str1.16,\"aMS\",@progbits,1", section);
        assert!(
            frontend::parse(&text)
                .unwrap_err()
                .message
                .contains("writable flags")
        );
    }
    let changed = source("gfx950", "\"A\"", 2) + ".section .rodata.str1.16,\"aw\",@progbits,1\n";
    assert!(
        frontend::parse(&changed)
            .unwrap_err()
            .message
            .contains("writable flags")
    );
    let writable = source("gfx950", "\"A\"", 2).replace(
        ".section .rodata.str1.16,\"aMS\",@progbits,1",
        ".section .data.custom,\"aw\",@progbits",
    );
    assert!(!frontend::parse(&writable).unwrap().globals[0].read_only);
}

fn string_table_module() -> frontend::Module {
    let original = include_str!("../src/frontend/fixtures/clang22-module-globals.s");
    let (prefix, tail) = original.split_once("constant_table:\n").unwrap();
    let (_, suffix) = tail.split_once("\t.size\tconstant_table, 16").unwrap();
    let text = format!(
        "{prefix}constant_table:\n.asciz \"ABCDEFGHIJKLMNO\"\n.size constant_table,16{suffix}"
    );
    frontend::parse(&text).unwrap()
}

#[test]
fn initialized_string_words_including_nul_reach_existing_checked_global_reads() {
    let module = string_table_module();
    let bytes = b"ABCDEFGHIJKLMNO\0";
    let mut config = AnalysisConfig::new((64, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x20000,
        elem_width: 4,
        len: 64,
        kind: ArrayKind::Output,
    }];
    config.params = vec![ParamValue::ArrayPtr("out".into())];
    let result = analyze(&module, Some("module_globals"), config.clone()).unwrap();
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs[0].1.len(), 64);
    for index in 0..64 {
        let offset = (index as usize % 4) * 4;
        let expected = u32::from_le_bytes(bytes[offset..offset + 4].try_into().unwrap()) as i64 + 3;
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index).unwrap()),
            Some(expected)
        );
    }
    assert!(result.graph.validate().is_ok());
    config.global_values = vec![("constant_table".into(), 0)];
    assert!(
        analyze(&module, None, config.clone())
            .unwrap_err()
            .to_string()
            .contains("read-only module global")
    );
    config.global_values.clear();
    let forbidden_store = module.source.replace(
        "global_load_dword v1, v1, s[2:3]",
        "global_store_dword v1, v0, s[2:3]",
    );
    let module = frontend::parse(&forbidden_store).unwrap();
    let aborted = analyze(&module, None, config).unwrap();
    assert!(
        aborted
            .symbolic_outputs()
            .unwrap_err()
            .to_string()
            .contains("read-only module-global")
    );
}
