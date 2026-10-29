//! Concrete OCP E5M2 decoding is distinct from E4M3 and never invents symbolic bits.
#[path = "gfx950_common/mod.rs"]
mod native_common;
use volta_amdgpu_analysis::{AnalysisConfig, ArrayDef, ArrayKind, ParamValue, frontend};
use volta_graph_check::GraphConclusion;
fn source(conversion: &str) -> String {
    format!(
        r#"
.amdgcn_target "amdgcn-amd-amdhsa--gfx1250"
.text
.globl k
.type k,@function
.p2align 8
k:
s_load_b64 s[4:5],s[0:1],0
s_load_b32 s6,s[0:1],8
s_wait_kmcnt 0
v_mov_b32 v0,0
{conversion}
global_store_b32 v0,v1,s[4:5]
s_wait_storecnt 0
s_endpgm
.amdhsa_kernel k
.amdhsa_wavefront_size32 1
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_kernarg_size 12
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1,2]
amdhsa.kernels:
  - .name: k
    .args:
      - .name: out
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: bits
        .offset: 8
        .size: 4
        .value_kind: by_value
...
.end_amdgpu_metadata
"#
    )
}
fn config(bits: ParamValue) -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    }];
    config.params = vec![ParamValue::ArrayPtr("out".into()), bits];
    config
}
#[test]
fn every_finite_e5m2_byte_matches_independent_binary_exponent_reference() {
    let s = source("v_cvt_f32_bf8_e32 v1,s6");
    let module = frontend::parse(&s).unwrap();
    for byte in 0u32..256 {
        let run = native_common::check(
            &s,
            &module,
            Some("k"),
            config(ParamValue::Int((0xa5c30000 | byte) as i64)),
        )
        .unwrap();
        if (byte >> 2) & 31 == 31 {
            let error = run.analysis.symbolic_outputs().unwrap_err().to_string();
            assert!(error.contains("E5M2 NaN or infinity"), "{byte:#x}: {error}");
            assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
            continue;
        }
        assert_eq!(
            run.checks.conclusion(),
            GraphConclusion::Verified,
            "{byte:#x}: {:?}",
            run.checks
        );
        let exponent = ((byte >> 2) & 31) as i32;
        let mantissa = (byte & 3) as f64;
        let magnitude = if exponent == 0 {
            mantissa * 2f64.powi(-16)
        } else {
            (4.0 + mantissa) * 2f64.powi(exponent - 17)
        };
        let expected = if byte & 128 != 0 {
            -magnitude
        } else {
            magnitude
        };
        let out = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.outputs.len(), 1);
        assert_eq!(out.outputs[0].1.len(), 1);
        assert_eq!(out.outputs[0].1[0].0, 0);
        assert_eq!(
            out.arena.as_f64(out.outputs[0].1[0].1),
            Some(expected),
            "{byte:#x}"
        );
    }
}
#[test]
fn concrete_e4m3_and_e5m2_are_not_aliased() {
    for (conversion, expected) in [("v_cvt_f32_bf8_e32", 1.0), ("v_cvt_f32_fp8_e32", 1.5)] {
        let s = source(&format!("{conversion} v1,s6"));
        let m = frontend::parse(&s).unwrap();
        let run = native_common::check(&s, &m, Some("k"), config(ParamValue::Int(0x3c))).unwrap();
        assert_eq!(run.checks.conclusion(), GraphConclusion::Verified);
        let out = run.analysis.symbolic_outputs().unwrap();
        assert_eq!(out.arena.as_f64(out.outputs[0].1[0].1), Some(expected));
    }
}
#[test]
fn symbolic_e5m2_storage_remains_explicitly_unsupported() {
    let s = source("global_load_u8 v1,v0,s[4:5]\ns_wait_loadcnt 0\nv_cvt_f32_bf8_e32 v1,v1");
    let m = frontend::parse(&s).unwrap();
    let mut c = config(ParamValue::Int(0));
    c.arrays[0].kind = ArrayKind::Input;
    c.arrays[0].elem_width = 1;
    let run = native_common::check(&s, &m, Some("k"), c).unwrap();
    let error = run.analysis.symbolic_outputs().unwrap_err().to_string();
    assert!(
        error.contains("symbolic E5M2 decoding is not modeled"),
        "{error}"
    );
    assert_ne!(run.checks.conclusion(), GraphConclusion::Verified);
}
#[test]
fn selected_e5m2_profile_does_not_accept_unmodeled_encodings_or_modifiers() {
    for conversion in [
        "v_cvt_f32_bf8_e64 v1,s6",
        "v_cvt_f32_bf8_e32 v1,s6 byte_sel:1",
        "v_cvt_f32_bf8_e32 v1,-s6",
    ] {
        assert!(
            frontend::parse(&source(conversion)).is_err(),
            "{conversion}"
        );
    }
    let s = source("v_cvt_f32_bf8_e32 v1,s6");
    let m = frontend::parse(&s).unwrap();
    for target in ["gfx942", "gfx950"] {
        let mut retarget = m.clone();
        retarget.target = Some(target.into());
        let run = native_common::check(&s, &retarget, Some("k"), config(ParamValue::Int(0x3c)));
        assert!(
            run.is_err() || run.unwrap().analysis.symbolic_outputs().is_err(),
            "{target}"
        );
    }
}

#[test]
fn decoder_source_keeps_pending_scalar_memory_readiness_obligations() {
    let source = source("v_cvt_f32_bf8_e32 v1,s6").replace("s_wait_kmcnt 0", "s_nop 0");
    let module = frontend::parse(&source).unwrap();
    let run =
        native_common::check(&source, &module, Some("k"), config(ParamValue::Int(0x40))).unwrap();
    assert!(run.analysis.symbolic_outputs().is_ok());
    assert!(
        matches!(run.checks.conclusion(), GraphConclusion::Rejected { .. }),
        "{:?}",
        run.checks
    );
    assert!(format!("{:?}", run.checks).contains("ReadBeforeReady"));
}
