//! Legacy LLVM target spelling compatibility without changing the ISA profile.
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, analyze, frontend, target};
use volta_graph_check::{GraphConclusion, check_graph};
use volta_pipeline::backend::Backend;

const CANONICAL: &str = "amdgcn-amd-amdhsa--gfx1250";
const LEGACY: &str = "amdgcn-amd-amdhsa-unknown-gfx1250";

fn source(directive: &str, metadata: &str) -> String {
    format!(
        r#".amdgcn_target "{directive}"
.text
.type k,@function
k:
v_mov_b32 v1,0
v_mov_b32 v2,7
s_mov_b64 s[4:5],0x10000
global_store_b32 v1,v2,s[4:5]
s_wait_storecnt 0
s_wait_xcnt 0
s_endpgm
.size k,.-k
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.target: "{metadata}"
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .kernarg_segment_size: 0
    .wavefront_size: 32
...
.end_amdgpu_metadata
"#
    )
}

#[test]
fn legacy_and_canonical_targets_have_identical_execution_and_selection() {
    // LLVM's public legacy-architecture disassembly test uses this spelling:
    // https://lists.llvm.org/pipermail/llvm-commits/Week-of-Mon-20260629/1963241.html
    // llvm/test/MC/AMDGPU/arch-amdgcn-legacy-arch-name.s, DIS-AMDGCN.
    for (directive, metadata) in [
        (CANONICAL, CANONICAL),
        (LEGACY, LEGACY),
        (CANONICAL, LEGACY),
        (LEGACY, CANONICAL),
    ] {
        let module = frontend::parse(&source(directive, metadata)).unwrap();
        assert_eq!(module.target.as_deref(), Some("gfx1250"));
        assert_eq!(
            target::validate(&module).unwrap(),
            target::Architecture::Gfx1250
        );
        Backend::AmdgpuGfx1250
            .validate_amd_target(module.target.as_deref())
            .unwrap();

        let mut config = AnalysisConfig::new((1, 1, 1));
        config.arrays.push(ArrayDef {
            name: "out".into(),
            base: 0x10000,
            elem_width: 4,
            len: 1,
            kind: ArrayKind::Output,
        });
        let result = analyze(&module, Some("k"), config).unwrap();
        let outputs = result.symbolic_outputs().unwrap();
        assert_eq!(outputs.outputs[0].1.len(), 1);
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", 0).unwrap()),
            Some(7)
        );
        assert_eq!(result.graph().provenance().targets, ["gfx1250"]);
        assert_eq!(
            check_graph(result.graph()).conclusion(),
            GraphConclusion::Verified
        );
    }
}

#[test]
fn normalized_legacy_target_cannot_change_selected_architecture() {
    let module = frontend::parse(&source(LEGACY, LEGACY)).unwrap();
    for selected in [Backend::Amdgpu, Backend::AmdgpuGfx942] {
        let error = selected
            .validate_amd_target(module.target.as_deref())
            .unwrap_err();
        assert!(error.contains("conflicts with source target gfx1250"));
    }
    for target in ["gfx942", "gfx950"] {
        let mut retargeted = module.clone();
        retargeted.target = Some(target.into());
        assert!(target::validate(&retargeted).is_err());
        assert!(analyze(&retargeted, Some("k"), AnalysisConfig::new((1, 1, 1))).is_err());
    }
}

#[test]
fn assembly_and_metadata_must_still_agree_after_normalization() {
    for different in ["gfx942", "amdgcn-amd-amdhsa--gfx950"] {
        for (directive, metadata) in [(LEGACY, different), (different, LEGACY)] {
            let error = frontend::parse(&source(directive, metadata)).unwrap_err();
            assert!(
                error
                    .message
                    .contains("conflicting assembly and metadata targets")
            );
        }
    }
}

#[test]
fn legacy_alias_keeps_existing_feature_and_quote_rejections() {
    for spelling in [CANONICAL, LEGACY] {
        for suffix in [
            ":xnack+",
            ":xnack-",
            ":sramecc+",
            ":sramecc-",
            ":xnack+:xnack-",
            ":xnack-:xnack-",
            ":unknown",
            ":",
        ] {
            let invalid = format!("{spelling}{suffix}");
            for (directive, metadata) in [
                (invalid.as_str(), invalid.as_str()),
                (invalid.as_str(), LEGACY),
                (LEGACY, invalid.as_str()),
            ] {
                assert!(
                    frontend::parse(&source(directive, metadata)).is_err(),
                    "{directive} / {metadata}"
                );
            }
        }
    }
    let valid = source(LEGACY, LEGACY);
    for malformed in [
        valid.replacen(&format!("\"{LEGACY}\""), &format!("\"{LEGACY}"), 1),
        valid.replacen(&format!("\"{LEGACY}\""), &format!("{LEGACY}\""), 1),
        valid.replacen(&format!("\"{LEGACY}\""), &format!("\"{LEGACY}\" junk"), 1),
    ] {
        assert!(frontend::parse(&malformed).is_err());
    }
}

#[test]
fn alias_is_limited_to_the_legacy_gfx1250_target_spelling() {
    for invalid in [
        "amdgcn-amd-amdhsa-unknown-gfx942",
        "amdgcn-amd-amdhsa-unknown-gfx950",
        "amdgcn-amd-amdhsa-unknown-gfx1250extra",
        "amdgcn-amd-amdhsa-none-gfx1250",
        "amdgcn-amd-amdpal-unknown-gfx1250",
        "amdgcn-amd-amdhsa-unknown-unknown-gfx1250",
        "amdgpu-amd-amdhsa-unknown-gfx1250",
        "amdgpu12.50-amd-amdhsa-unknown-gfx1250",
    ] {
        assert!(
            frontend::parse(&source(invalid, invalid)).is_err(),
            "{invalid}"
        );
    }
    // Canonical legacy-target syntax and its supported feature suffixes stay valid.
    for target in ["gfx942:sramecc+:xnack-", "gfx950:xnack-"] {
        let module =
            frontend::parse(&format!(".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n")).unwrap();
        assert_eq!(module.target.as_deref(), Some(target));
    }
}
