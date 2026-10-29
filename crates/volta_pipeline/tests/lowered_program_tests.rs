//! Direct IR execution through the public API, without a source-language frontend.

use volta_graph::{Assumption, InstructionInfo, Provenance};
use volta_graph_check::{GraphConclusion, check_graph};
use volta_ptx_analysis::{
    AnalysisConfig, ArrayDef, ArrayKind, EvalError, InstrId, LoweredInstr, LoweredProgram,
    MemSpace, Operand, ScalarType, SharedAllocation, SourceMap, SymbolTable, analyze_lowered,
};

const OUTPUT_BASE: u64 = 0x20000;

fn store_program() -> LoweredProgram {
    // Direct callers must finalize the layout even when no shared memory is declared.
    let mut symbols = SymbolTable::new();
    symbols.finalize_shared_layout().unwrap();

    // out[0] = 42; return. This needs no parameters or registers.
    let mut program = LoweredProgram {
        instructions: Default::default(),
        predicates: Default::default(),
        symbols,
        source_map: SourceMap::default(),
        entry_pc: InstrId(0),
    };
    for instruction in [
        LoweredInstr::Store {
            space: MemSpace::Global,
            base: Operand::ImmU64(OUTPUT_BASE),
            offset: 0,
            src: Operand::ImmI64(42),
            ty: ScalarType::U32,
        },
        LoweredInstr::Exit,
    ] {
        let _ = program.instructions.push(instruction);
        let _ = program.predicates.push(None);
    }

    program
}

fn store_config() -> AnalysisConfig {
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays = vec![ArrayDef {
        name: "out".into(),
        base: OUTPUT_BASE,
        elem_width: 4,
        len: 1,
        kind: ArrayKind::Output,
    }];
    config
}

#[test]
fn executes_a_lowered_store() {
    let program = store_program();
    let config = store_config();
    let provenance = provenance(&program, &config);
    let result = analyze_lowered(&program, config, provenance).unwrap();

    // An Ok result alone does not establish that execution completed.
    assert_eq!(
        check_graph(&result.graph).conclusion(),
        GraphConclusion::Verified
    );
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(
        outputs
            .arena
            .display_expr(outputs.element("out", 0).unwrap()),
        "42"
    );
}

#[test]
fn direct_ir_execution_rejects_native_amd_layout_premises() {
    let program = store_program();
    let mut config = store_config();
    config.shared_allocations.push(SharedAllocation {
        name: "native_tile".into(),
        offset: 0,
        size: 4,
    });
    let provenance = provenance(&program, &config);
    let error = analyze_lowered(&program, config, provenance).unwrap_err();
    assert!(
        matches!(error, EvalError::Config { ref message } if message.contains("shared_allocations"))
    );
}

#[test]
fn direct_ir_execution_validates_the_launch_configuration() {
    let program = store_program();
    let mut config = store_config();
    config.arrays[0].base += 1;
    let provenance = provenance(&program, &config);
    assert!(matches!(
        analyze_lowered(&program, config, provenance),
        Err(EvalError::Config { .. })
    ));
}

/// Record the interpreter's assumptions and the supplied program and launch configuration.
fn provenance(program: &LoweredProgram, config: &AnalysisConfig) -> Provenance {
    Provenance {
        kernel: "store".into(),
        block_dim: config.block_dim,
        grid_dim: config.grid_dim,
        targets: Vec::new(),
        assumptions: vec![
            Assumption::StructuredCta,
            Assumption::SingleCtaAnalyzed,
            Assumption::SingleCtaCluster,
            Assumption::NeverStealClusterLaunchControl,
            Assumption::ExitedThreadsArrive,
            Assumption::EagerAsyncData,
        ],
        instructions: program
            .instructions
            .values()
            .map(|instruction| InstructionInfo {
                kind: instruction.kind_name(),
                span: None,
            })
            .collect(),
    }
}
