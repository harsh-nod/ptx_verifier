#!/usr/bin/env python3
"""Regenerate the scoped gfx950 instruction/stage inventory from typed ASTs.

Run from any directory; --check compares without writing. This inventories
checked-in assembly and implementation/test references, not runtime PC coverage.
"""

import argparse
import collections
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path("crates/volta_amdgpu_analysis/src/frontend/fixtures")
FRONT = "crates/volta_amdgpu_analysis/src/frontend/"
INTERP = "crates/volta_amdgpu_analysis/src/eval/interp.rs"
EXEC = "crates/volta_amdgpu_analysis/tests/execution.rs"
PIPE = "crates/volta_pipeline/tests/"
MEM = PIPE + "gfx950_memory_control_tests.rs"
SOFT = PIPE + "gfx950_software_hazard_tests.rs"
GRAPH = "crates/volta_graph_check/src/amdgpu.rs"
LOWER = "crates/volta_amdgpu_analysis/src/lower/mod.rs"


def reference(path, function):
    text = (ROOT / path).read_text()
    match = re.search(r"\bfn\s+" + re.escape(function) + r"\s*\(", text)
    if not match:
        raise ValueError(f"missing function: {path}::{function}")
    return {
        "path": path,
        "function": function,
        "line": text.count("\n", 0, match.start()) + 1,
    }


def test(path, function):
    return reference(path, function)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    provenance = json.loads((ROOT / FIXTURES / "compiler-provenance.json").read_text())
    compiler = {FIXTURES / item["assembly"]: item for item in provenance["fixtures"]}
    paths = sorted(
        set(compiler)
        | {p.relative_to(ROOT) for p in (ROOT / "tests/gfx950").glob("portable-*/*.s")}
    )
    command = [
        "cargo",
        "run",
        "--quiet",
        "-p",
        "volta_amdgpu_analysis",
        "--example",
        "instruction_inventory",
        "--",
        *map(str, paths),
    ]
    run = subprocess.run(command, cwd=ROOT, check=True, capture_output=True, text=True)
    instructions = [json.loads(line) for line in run.stdout.splitlines()]
    by_name = collections.defaultdict(list)
    by_source = collections.defaultdict(list)
    for instruction in instructions:
        by_name[instruction["mnemonic"]].append(instruction)
        by_source[instruction["path"]].append(instruction)

    # Each stage has its own code references. A parsed opcode is never promoted
    # to execution support by this generator; the value profiles below are an
    # explicit review of dispatch and restrictions.
    stages = {
        "F": {
            "stage": "frontend",
            "meaning": "Typed family, arity, register/tuple roles and recognized modifier syntax; not an exhaustive assembler.",
            "references": [
                reference(FRONT + "instr.rs", "parse_instruction"),
                reference(FRONT + "instr.rs", "validate_registers"),
            ],
        },
        "FV": {
            "stage": "frontend",
            "meaning": "F plus the explicitly enumerated27 binary/FMA VOP source/literal profiles, including type-specific F16/F64 constants; e32/e64 choice is validated only for that pinned set.",
            "references": [
                reference(FRONT + "instr.rs", "validate_vop_literal_positions")
            ],
        },
        "FM": {
            "stage": "frontend",
            "meaning": "F plus MFMA A/B register classes, tuple widths, C/D file agreement and encoded format widths.",
            "references": [reference(FRONT + "instr.rs", "validate_registers")],
        },
        "L": {
            "stage": "lower",
            "meaning": "Retain native instruction/PC; resolve local branch labels, reject unresolved symbols and malformed relocation sequences even in unreachable code.",
            "references": [reference(LOWER, "lower_with_globals")],
        },
        "LR": {
            "stage": "lower",
            "meaning": "Only contiguous compiler-proven getpc/rel32lo+4/rel32hi+12 for bounded defined objects; preserve 3 PCs and reject middle-entry branches.",
            "references": [reference(LOWER, "lower_with_globals")],
        },
        "I": {
            "stage": "event",
            "meaning": "Instruction event includes EXEC lanes, register reads/writes and scalar selector roles; retained on partial abort graphs.",
            "references": [
                reference(INTERP, "step"),
                reference(INTERP, "instruction_registers"),
                reference(INTERP, "scalar_mask_reads"),
            ],
        },
        "IM": {
            "stage": "event",
            "meaning": "I plus MemoryIssue/effects with actual space, transfer bytes, held sources, counter and scope; permutation uses LGKM without fabricated LDS accesses.",
            "references": [
                reference(INTERP, "memory_instruction"),
                reference(INTERP, "permute"),
            ],
        },
        "IX": {
            "stage": "event",
            "meaning": "I plus MatrixIssue form/operand/accumulator/destination slices; full wave64, source snapshots.",
            "references": [reference(INTERP, "matrix")],
        },
        "IW": {
            "stage": "event",
            "meaning": "I plus Wait thresholds (endpgm drains all 3 counters).",
            "references": [reference(INTERP, "wait"), reference(INTERP, "step")],
        },
        "IB": {
            "stage": "event",
            "meaning": "I plus barrier arrival/release generations and active masks; terminated waves leave later generations.",
            "references": [reference(INTERP, "step")],
        },
        "ID": {
            "stage": "event",
            "meaning": "I plus native s_nop immediate + 1 independent instruction states.",
            "references": [reference(INTERP, "step")],
        },
        "C": {
            "stage": "check",
            "meaning": "Independent native trace completeness and register readiness/software hazards. Abort withholds positive verification and outputs.",
            "references": [
                reference(GRAPH, "trace_contract"),
                reference(GRAPH, "check_amdgpu"),
                reference(GRAPH, "check_missing_semantic"),
            ],
        },
        "CM": {
            "stage": "check",
            "meaning": "C plus counter prefixes, whole-transfer bounds, object identity, source lifetime, memory conflicts and required workgroup scope/publication.",
            "references": [
                reference(GRAPH, "check_amdgpu"),
                reference(GRAPH, "memory_conflicts"),
                reference(GRAPH, "missing_global_publication"),
            ],
        },
        "CB": {
            "stage": "check",
            "meaning": "C plus matching live-wave barrier generations/completion; barrier alone does not publish pending LDS work.",
            "references": [reference(GRAPH, "check_amdgpu")],
        },
        "CX": {
            "stage": "check",
            "meaning": "C plus form-specific MFMA result/source/accumulator timing; exact SrcC forwarding only for supported same-form relationships.",
            "references": [reference(GRAPH, "check_amdgpu")],
        },
    }
    values = {}

    def value(key, meaning, functions, positive, negative):
        values[key] = {
            "stage": "value",
            "status": "implemented_with_explicit_limits",
            "meaning": meaning,
            "references": [reference(INTERP, f) for f in functions],
            "positive_controls": [test(*pair) for pair in positive],
            "negative_controls": [test(*pair) for pair in negative],
            "test_scope": "Named representative controls exercise this semantic profile; these are not assertions that every corpus PC/operand combination was executed.",
        }

    value(
        "S",
        "Concrete scalar 32/64 bit arithmetic/flags, masks and moves. Symbolic masks remain opaque; undefined SCC/VCC/control/address use aborts. Special shared-base source is an opaque aperture only.",
        ["scalar"],
        [
            (EXEC, "scalar_min_max_scc_uses_native_tie_rules"),
            (
                EXEC,
                "compiler_grid_and_group_dimensions_retain_numeric_output_provenance",
            ),
        ],
        [
            (MEM, "uninitialized_condition_cannot_choose_a_control_path"),
            (EXEC, "opaque_shared_apertures_cannot_become_data_or_global_addresses"),
        ],
    )
    value(
        "R",
        "Opaque compiler rel32 object addresses; exact triad only, SCC becomes undefined after linker-dependent adds. Arbitrary PC values/GOT/externs are unsupported.",
        ["module_address_scalar"],
        [(EXEC, "compiler_module_globals_use_checked_storage_and_exact_relocations")],
        [(EXEC, "compiler_module_globals_use_checked_storage_and_exact_relocations")],
    )
    value(
        "K",
        "Fixed-width native integer/bit/address ALU, typed symbolic 32 bit ring operations, bit operations and shifts. Symbolic data never becomes concrete address/control bits; general symbolic 64 bit/division remain outside the profile.",
        ["vector", "integer_expression", "integer_result"],
        [(EXEC, "symbolic_integer_ring_operations_preserve_signed_immediate_values")],
        [(EXEC, "produced_symbolic_types_cannot_escape_into_bitcasts_or_addresses")],
    )
    value(
        "F32",
        "Exact real-number f32 arithmetic/transcendentals with decoded finite native constants, disclosed exp/log base conversion, scoped VOP3 clamp. No IEEE rounding/NaN equivalence claim; undefined concrete domains and unsupported modifiers abort.",
        ["vector", "real", "exp2", "factor_exp2_idiom"],
        [(EXEC, "native_f32_clamp_saturates_supported_float_results")],
        [
            (
                EXEC,
                "clamp_does_not_enable_other_modifier_or_integer_exception_semantics",
            ),
            (
                PIPE + "gfx950_real_domain_tests.rs",
                "zero_reciprocal_and_rsqrt_fail_before_undefined_values_can_be_annihilated",
            ),
        ],
    )
    value(
        "F64",
        "Ordered matching word-pair f64 tags and real arithmetic/conversions; actual inline/high-word literal encoding. Mixed words and reinterpretations fail; no floating rounding claim.",
        ["vector", "real64", "put_real64"],
        [(EXEC, "compiler_symbolic_integer_and_f64_data_use_typed_storage")],
        [(EXEC, "f64_storage_preserves_ordered_whole_values_and_rejects_mixed_words")],
    )
    value(
        "H",
        "Typed F16 low/high components, native selected SDWA source fields, signed-I8/I16 conversion and partial destination preservation. Unknown padding is not zero-filled; arbitrary symbolic bit reinterpretation fails.",
        ["vector", "half", "signed16_to_half", "selected_bits"],
        [
            (EXEC, "compiler_packed_f16_relu_preserves_each_half_identity"),
            (
                EXEC,
                "signed_byte_conversion_preserves_numeric_inputs_and_rejects_mixed_formats",
            ),
        ],
        [
            (
                EXEC,
                "input_word_aliases_cannot_acquire_conflicting_numeric_interpretations",
            )
        ],
    )
    value(
        "P",
        "Packed/mixed f32/f16 operations snapshot both sources and honor scoped op_sel/op_sel_hi; mixed half writes preserve the untouched half. Unsupported selector/output-modifier envelopes abort.",
        ["vector", "real_component", "half"],
        [(EXEC, "mixed_half_rope_preserves_only_the_written_half")],
        [
            (
                PIPE + "gfx950_portable_scalar_tests.rs",
                "packed_native_variants_match_the_scalar_reference_and_reject_wrong_math",
            )
        ],
    )
    value(
        "E4",
        "Finite OCP E4M3 byte decoding, explicit BYTE_0..3 selection; paired cvt default bytes0/1 only. Symbolic byte-format interpretation is claimed once per input and conflicts with signed-I8/other numeric meanings abort.",
        ["vector", "fp8", "claim_byte_format"],
        [
            (PIPE + "gfx950_matrix_parity_tests.rs", "e4m3_concrete_pair"),
            (PIPE + "gfx950_matrix_parity_tests.rs", "e4m3_selected_low_halves"),
        ],
        [
            (
                EXEC,
                "signed_byte_conversion_preserves_numeric_inputs_and_rejects_mixed_formats",
            )
        ],
    )
    value(
        "B",
        "Concrete native comparisons/carry plus symbolic signed/unsigned 32 bit and f32 comparison masks; cndmask selects mathematical values and canonical unsigned words. Symbolic EXEC/branch/carry/address/storage interpretations abort.",
        ["vector", "write_predicates", "predicate_condition", "select_word"],
        [(EXEC, "symbolic_native_comparison_masks_select_canonical_integer_words")],
        [
            (
                EXEC,
                "symbolic_masks_remain_opaque_to_control_carry_addresses_and_data_stores",
            )
        ],
    )
    value(
        "A",
        "Disjoint AGPR/VGPR allocation; native accumulator read/write/move preserves words. Unified physical aliases are rejected rather than represented as independent storage.",
        ["vector"],
        [(EXEC, "native_pipelined_f16_mfma_preserves_32_term_dot_products")],
        [
            (
                FRONT + "tests.rs",
                "rejects_registers_outside_declared_allocations_and_unified_aliases",
            )
        ],
    )
    value(
        "M",
        "Typed global/kernarg/LDS byte storage, exact wide/dual components, signed narrow loads, low-bit narrow stores, finite object bounds/alignment; static+dynamic LDS and opaque shared aperture. XNACK replay, atomics, buffers, arbitrary apertures and equal-offset dual DS are outside the envelope.",
        ["memory_instruction", "flat_memory_address", "validate_address"],
        [
            (MEM, "compiler_static_and_dynamic_lds_share_bytes_through_flat_and_ds"),
            (MEM, "an_lds_128_bit_read_preserves_four_independently_stored_words"),
        ],
        [
            (MEM, "vector_transfers_check_every_component_at_the_region_end"),
            (MEM, "initialized_bytes_and_halves_do_not_define_the_rest_of_a_word"),
        ],
    )
    value(
        "Q",
        "DS cross-lane snapshot permute/bpermute under EXEC; concrete lane indices and LGKM completion. Does not synthesize LDS memory reads/writes or cross-wave publication.",
        ["permute"],
        [
            (
                MEM,
                "wave_local_lds_exchange_requires_completion_without_a_workgroup_barrier",
            )
        ],
        [(MEM, "ds_permute_and_its_completion_do_not_create_crosswave_memory_order")],
    )
    value(
        "X",
        "Full wave64 dense MFMA; explicit CDNA4 lane/item coordinates and source snapshots. F16/F32/E4M3 symbolic values; finite concrete BF16/E5M2. Format cbsz/blgp 0/1 only; scaled forms require selected E8M0 bytes 127; other layouts/F6/F4/nonunit scales abort.",
        ["matrix", "matrix_input"],
        [
            (EXEC, "native_mfma_all_256_coordinates_match_independent_dot_products"),
            (EXEC, "native_pipelined_f16_mfma_preserves_32_term_dot_products"),
            (EXEC, "native_unit_scaled_fp8_mfma_preserves_interleaved_k_layout"),
            (PIPE + "gfx950_matrix_parity_tests.rs", "tcgen_mixed_fp8_numeric408"),
        ],
        [
            (EXEC, "mfma_partial_wave_and_nonzero_layout_modifiers_are_incomplete"),
            (
                PIPE + "gfx950_matrix_parity_tests.rs",
                "mixed_fp8_operand_formats_cannot_be_interchanged",
            ),
        ],
    )
    value(
        "J",
        "Concrete scalar branch decisions over SCC/VCC/EXEC or unconditional local targets; one workgroup, budgets bound loops. Symbolic control is unsupported and budget exhaustion is inconclusive.",
        ["step"],
        [(EXEC, "masked_tail_preserves_full_64bit_exec")],
        [(MEM, "uninitialized_condition_cannot_choose_a_control_path")],
    )
    value(
        "W",
        "Native counter thresholds retire actual in-order counter prefixes; maximal thresholds do not falsely mean full completion.",
        ["wait"],
        [(MEM, "partial_vmcnt_only_retires_the_completed_load_prefix")],
        [(MEM, "a_wait_on_the_wrong_counter_does_not_make_a_register_ready")],
    )
    value(
        "G",
        "Scalar workgroup barrier arrival/release for surviving waves, including partial/empty EXEC. Does not replace data completion waits.",
        ["step"],
        [(MEM, "terminated_waves_do_not_block_later_surviving_wave_generations")],
        [(MEM, "distinct_static_barrier_instructions_are_not_a_matching_rendezvous")],
    )
    value(
        "T",
        "Endpgm implicit counter drain and lane termination; NOP encoded 0..15 gives 1..16 states. No fabricated handler/call/return semantics.",
        ["step"],
        [
            (
                MEM,
                "endpgm_completes_pending_lds_but_a_survivor_still_needs_its_barrier",
            ),
            (SOFT, "valu_scalar_data_requires_two_independent_states"),
        ],
        [(FRONT + "tests.rs", "control_immediates_have_explicit_encoded_ranges")],
    )
    value(
        "U",
        "Recognized syntax only: active execution deliberately returns Unsupported and preserves an incomplete graph. It is never counted as successful semantics.",
        ["vector", "memory_instruction", "unsupported"],
        [],
        [
            (
                PIPE + "gfx950_parser_parity_tests.rs",
                "recognized_unmodeled_lane_and_atomic_forms_withhold_native_certificates",
            )
        ],
    )
    values["U"]["status"] = "recognized_but_execution_unsupported"

    def category(name, family):
        plain = re.sub(r"_(e32|e64|sdwa)$", "", name)
        if (
            plain in {"v_readlane_b32", "v_readfirstlane_b32", "v_writelane_b32"}
            or "atomic" in plain
        ):
            return "U"
        if family == "Matrix":
            return "X"
        if family == "Wait":
            return "W"
        if family == "Barrier":
            return "G"
        if family == "Branch":
            return "J"
        if family == "Control":
            return "T"
        if family == "ScalarAlu":
            return "R" if plain == "s_getpc_b64" else "S"
        if family in {"ScalarMemory", "VectorMemory", "Lds"}:
            return "Q" if plain in {"ds_bpermute_b32", "ds_permute_b32"} else "M"
        if plain.startswith("v_accvgpr_"):
            return "A"
        if plain.startswith("v_cmp_") or plain == "v_cndmask_b32":
            return "B"
        if "fp8" in plain:
            return "E4"
        if "f64" in plain:
            return "F64"
        if plain.startswith("v_pk_") or plain.startswith("v_fma_mix"):
            return "P"
        if "f16" in plain:
            return "H"
        if "f32" in plain or plain.startswith("v_cvt_f32_ubyte"):
            return "F32"
        return "K"

    source_rows = []
    for path in paths:
        digest = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        if path in compiler:
            assert digest == compiler[path]["assembly_sha256"], (
                f"pinned compiler source changed: {path}"
            )
        rows = by_source[str(path)]
        source_rows.append(
            {
                "path": str(path),
                "sha256": digest,
                "compiler_pinned": path in compiler,
                "instructions": len(rows),
                "kernels": sorted({r["kernel"] for r in rows}),
            }
        )

    binary = {
        "v_add_u32",
        "v_sub_u32",
        "v_subrev_u32",
        "v_add_f32",
        "v_sub_f32",
        "v_mul_f32",
        "v_and_b32",
        "v_or_b32",
        "v_xor_b32",
        "v_lshlrev_b32",
        "v_lshrrev_b32",
        "v_ashrrev_i32",
        "v_mul_lo_u32",
        "v_subrev_f32",
        "v_min_f32",
        "v_max_f32",
        "v_fmac_f32",
        "v_min_f16",
        "v_max_f16",
        "v_add_f64",
        "v_mul_f64",
        "v_min_f64",
        "v_max_f64",
        "v_fmac_f64",
        "v_fma_f32",
        "v_fma_f16",
        "v_fma_f64",
    }
    opcodes = []
    for name, rows in sorted(by_name.items()):
        family = rows[0]["family"]
        kind = category(name, family)
        groups = collections.defaultdict(list)
        for row in rows:
            groups[
                json.dumps([row["operands"], row["modifiers"]], sort_keys=True)
            ].append(row)
        profiles = []
        for shape, examples in sorted(groups.items()):
            operands, modifiers = json.loads(shape)
            # One exact source position per source+kernel keeps the table useful
            # without pretending that repeated loop PCs provide new coverage.
            locations = {}
            for example in examples:
                locations.setdefault(
                    (example["path"], example["kernel"]), example["line"]
                )
            profiles.append(
                {
                    "operands": operands,
                    "modifiers": modifiers,
                    "occurrences": len(examples),
                    "examples": [
                        {"path": p, "kernel": k, "line": line}
                        for (p, k), line in sorted(locations.items())
                    ],
                }
            )
        frontend = (
            "FM"
            if family == "Matrix"
            else "FV"
            if re.sub(r"_(e32|e64|sdwa)$", "", name) in binary
            and not name.endswith("_sdwa")
            else "F"
        )
        event = (
            "I"
            if kind == "U"
            else "IX"
            if family == "Matrix"
            else "IM"
            if family in {"ScalarMemory", "VectorMemory", "Lds"}
            else "IW"
            if family == "Wait" or name == "s_endpgm"
            else "IB"
            if family == "Barrier"
            else "ID"
            if name == "s_nop"
            else "I"
        )
        check = (
            "CX"
            if family == "Matrix"
            else "CM"
            if event == "IM"
            else "CB"
            if family == "Barrier"
            else "C"
        )
        notes = []
        if "bf16" in name:
            notes.append(
                "Native executor supports finite concrete BF16 words only; source presence and raw hardware basis tests do not establish symbolic BF16 array support."
            )
        if kind == "U":
            notes.append(
                "No positive execution test is claimed for this form; it exists in the fail-closed corpus."
            )
        if name in {"s_sext_i32_i16", "v_cvt_f32_ubyte2_e32"}:
            notes.append(
                "Mixed-byvalue is integrated, not compilation-only: gfx950_byvalue_tests positive ignores only unobserved padding; negative controls select/observe unknown bits."
            )
        opcodes.append(
            {
                "mnemonic": name,
                "family": family,
                "occurrences": len(rows),
                "frontend": frontend,
                "lower": "LR" if name == "s_getpc_b64" else "L",
                "value": kind,
                "event": event,
                "check": check,
                "primary_source": "amd-cdna4",
                "limits": notes,
                "profiles": profiles,
            }
        )

    # Exact compiler-only counts remain a convenient summary, not support data.
    counts = {
        path.name: dict(
            sorted(
                collections.Counter(r["mnemonic"] for r in by_source[str(path)]).items()
            )
        )
        for path in sorted(compiler)
    }
    inventory = {
        "schema_version": 1,
        "target": "gfx950",
        "wavefront_size": 64,
        "scope": "Every assembly named by compiler-provenance.json plus checked-in tests/gfx950/portable-*/*.s at generation time. Inline Rust assembly is represented by named tests, not counted in this source corpus.",
        "interpretation": [
            "Parsing is not execution support. Stage IDs are independent code/evidence references, not a single supported boolean.",
            "Observed profiles record exact mnemonic suffixes, operand classes/tuple sizes/source abs-neg and modifier values, with source hashes and locations. They do not assert all encodable forms work.",
            "Positive/negative controls are actual named tests of the reviewed semantic family; they do not provide per-instruction-PC runtime coverage. Unsupported rows have no positive-control claim.",
            "Mathematical execution uses the repository exact-real model and disclosed assumptions; hardware receipts use finite numeric tolerances. These claims are distinct.",
            "Unknown opcodes/modifiers, typed reinterpretations, unmodeled control/hazards or aborted traces cannot yield a positive native certificate.",
        ],
        "generator": "tests/gfx950/generate_instruction_coverage.py",
        "totals": {
            "sources": len(source_rows),
            "compiler_sources": len(compiler),
            "instructions": len(instructions),
            "exact_mnemonics": len(opcodes),
            "observed_profiles": sum(len(o["profiles"]) for o in opcodes),
        },
        "primary_sources": {
            "amd-cdna4": {
                "title": "AMD Instinct CDNA4 ISA,5 August 2025",
                "url": "https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf",
                "sections": {
                    "control_counters": "4,7.6",
                    "selectors_literals": "6.2",
                    "matrix_layout": "7.1.4–7.1.5",
                    "scalar_memory": "8.3",
                    "flat": "10.2",
                    "scalar_alu": "12.3",
                    "vector_alu": "12.8 and following VOP tables",
                    "lds": "12.12",
                },
            },
            "llvm-abi": {
                "title": "LLVM AMDGPU ABI/assembler",
                "url": "https://llvm.org/docs/AMDGPUUsage.html",
                "pinned_compiler_commit": provenance["compiler_commit"],
                "assembler_controls": [
                    "crates/volta_amdgpu_analysis/tests/fixtures/vop-operand-assembler.json",
                    "crates/volta_amdgpu_analysis/tests/fixtures/vop-floating-assembler.json",
                    "tests/gfx950/portable-matrix/mfma-operand-assembler.json",
                ],
            },
        },
        "stages": stages,
        "value_profiles": values,
        "sources": source_rows,
        "opcodes": opcodes,
        "mixed_byvalue_evidence": {
            "assembly": str(FIXTURES / "clang22-mixed-byvalue.s"),
            "positive": test(
                PIPE + "gfx950_byvalue_tests.rs",
                "native_mixed_byvalue_parameters_ignore_only_unobserved_padding",
            ),
            "negative": test(
                PIPE + "gfx950_byvalue_tests.rs",
                "selecting_or_observing_unknown_byvalue_padding_never_gets_a_verdict",
            ),
            "semantics": "Known bits of a partially defined kernarg word are preserved. Exact low 16 bit sign extension and byte 2 to f32 consume only known bits; observing padding aborts.",
        },
        "external_evidence": [
            "tests/gfx950/evidence/hardware-2026-10-27-initial-corpus.json",
            "tests/gfx950/evidence/hardware-abi-2026-10-27.json",
            "tests/gfx950/evidence/hardware-full-workloads-2026-10-27.json",
            "tests/gfx950/evidence/hardware-advanced-workloads-2026-10-27.json",
            "tests/gfx950/evidence/hardware-attention-2026-10-27.json",
        ],
    }
    lines = [
        "# gfx950 instruction and modifier coverage",
        "",
        "Generated by `python3 tests/gfx950/generate_instruction_coverage.py`; use `--check` to detect stale source hashes or profiles.",
        "",
        f"The corpus contains **{len(source_rows)} sources**, including **{len(compiler)} pinned compiler outputs**, **{len(instructions):,} instructions**, **{len(opcodes)} exact mnemonic forms** and **{inventory['totals']['observed_profiles']} operand/modifier profiles**. [The JSON inventory](instruction-coverage.json) records every profile, exact modifier value, tuple size, source hash and example PC.",
        "",
        "Parsing does not establish execution support. Each column below points to a distinct stage implementation. Value IDs name reviewed, bounded semantic profiles with real positive and negative tests. Representative family controls do not assert runtime coverage of every corpus PC or every possible operand combination. `U` deliberately aborts; BF16/E5M2 symbolic storage, nonunit MFMA scale, F6/F4, arbitrary relocations, XNACK replay, unmodeled lane hazards and unknown modifiers remain outside their stated envelopes.",
        "",
        "The mixed by-value compiler source is included: `s_sext_i32_i16` and `v_cvt_f32_ubyte2_e32` have integrated positive and unknown-padding negative controls in `gfx950_byvalue_tests.rs`. Source counts are regenerated in `emitted-instructions.json`; those counts alone make no support claim.",
        "",
        "## Stage references",
        "",
    ]

    def link(ref):
        return f"[`{ref['function']}`](../../{ref['path']}#L{ref['line']})"

    for key, stage in stages.items():
        lines.append(
            f"- **{key} ({stage['stage']})**: {stage['meaning']} "
            + ", ".join(link(r) for r in stage["references"])
        )
    lines += ["", "## Value profiles and actual controls", ""]
    for key, profile in values.items():
        lines += [
            f"### {key}",
            "",
            profile["meaning"],
            "",
            "Value implementation: "
            + ", ".join(link(r) for r in profile["references"]),
        ]
        lines += [
            "",
            "Positive controls: "
            + (
                ", ".join(link(r) for r in profile["positive_controls"])
                or "none; execution is deliberately unsupported"
            ),
            "",
            "Negative controls: "
            + ", ".join(link(r) for r in profile["negative_controls"]),
            "",
        ]
    lines += [
        "## Exact observed forms",
        "",
        "All source/profile and primary-source details are in the JSON. `F/FV/FM`, `L/LR`, value, event and check columns refer to the registries above. Test columns refer to the explicit positive/negative controls under that value profile. This table is scoped to pinned sources, not a universal gfx950 ISA support declaration.",
        "",
        "| Exact mnemonic | Frontend | Lower | Value | Event | Check | Positive tests | Negative tests | Source profiles / primary |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in opcodes:
        key = row["value"]
        positive = "none" if key == "U" else key
        source = row["profiles"][0]["examples"][0]
        lines.append(
            f"| `{row['mnemonic']}` | {row['frontend']} | {row['lower']} | {key} | {row['event']} | {row['check']} | {positive} | {key} | [{len(row['profiles'])} profiles](../../{source['path']}#L{source['line']}); CDNA4 |"
        )
    lines += [
        "",
        "Primary sources: [AMD CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf), §§4,6.2,7.1.4–7.1.5,7.6,8.3,10.2,12.3,12.8,12.12; [LLVM AMDGPU ABI and assembler](https://llvm.org/docs/AMDGPUUsage.html). The pinned assembler positive/negative probes are linked in the JSON. Physical hardware and mathematical verification receipts remain separate evidence.",
        "",
    ]
    outputs = {
        ROOT / "tests/gfx950/instruction-coverage.json": json.dumps(inventory, indent=2)
        + "\n",
        ROOT / "tests/gfx950/instruction-coverage.md": "\n".join(lines),
        ROOT / FIXTURES / "emitted-instructions.json": json.dumps(counts, indent=2)
        + "\n",
    }
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                raise SystemExit(f"stale inventory: {path.relative_to(ROOT)}")
        else:
            path.write_text(content)
    print(json.dumps(inventory["totals"], sort_keys=True))


if __name__ == "__main__":
    main()
