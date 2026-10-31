#!/usr/bin/env python3
"""Index actual original32 opcode/operand/modifier profiles, never runtime coverage."""

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
REGISTRY = ROOT / "tests/gfx1250/full/cases.json"
PIPE = "crates/volta_pipeline/tests/"
AMD = "crates/volta_amdgpu_analysis/"
GRAPH = "crates/volta_graph_check/"
INTERP = AMD + "src/eval/interp.rs"
PUBLIC = "https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/"


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def reference(path, function):
    text = (ROOT / path).read_text()
    match = re.search(r"\b(?:fn|def)\s+" + re.escape(function) + r"\s*\(", text)
    if not match:
        raise ValueError(f"missing function: {path}::{function}")
    return {
        "path": path,
        "function": function,
        "line": text.count("\n", 0, match.start()) + 1,
    }


def category(row):
    name, family = row["mnemonic"], row["family"]
    if name == "s_sendmsg":
        return "release"
    if name == "s_getreg_b32":
        return "hardware_abi"
    if name == "ds_bpermute_b32":
        return "permutation"
    if name.startswith("global_atomic_"):
        return "atomic"
    return {
        "ScalarAlu": "scalar",
        "VectorAlu": "vector",
        "ScalarMemory": "memory",
        "VectorMemory": "memory",
        "Lds": "memory",
        "Branch": "branch",
        "Control": "control",
        "Wait": "wait",
        "Barrier": "barrier",
        "Matrix": "matrix",
    }[family]


def implementation_contracts():
    def test(file, function):
        return reference(PIPE + file + ".rs", function)

    def graph(function):
        return reference(GRAPH + "tests/gfx1250_tests.rs", function)

    definitions = {
        "hardware_abi": (
            "scalar",
            "Only the compiler's HW_REG_IB_STS2 offset6 width4 read is modeled in the selected unsplit launch profile. Other hardware fields never receive a fabricated zero; no general hardware-register model is claimed.",
            [
                reference(
                    AMD + "tests/gfx1250_full_execution.rs",
                    "original_f16_relu_preserves_both_symbolically_selected_halves",
                )
            ],
            [
                test(
                    "gfx1250_mechanism_boundary_tests",
                    "compiler_hardware_field_read_never_generalizes_to_unmodeled_field_bits",
                )
            ],
        ),
        "scalar": (
            "scalar",
            "Exact concrete integer/bit/carry and typed mathematical scalar data; opaque address and SCC restrictions remain explicit.",
            [
                test(
                    "gfx1250_exact_integer_parity",
                    "symbolic_salu_conditions_select_data_but_never_control_carry_or_addresses",
                ),
                test(
                    "cdna_bfe64_tests",
                    "data_and_control_use_target_specific_counters_even_under_empty_exec",
                ),
            ],
            [
                test(
                    "gfx1250_exact_integer_parity",
                    "explicit_scc_register_escape_is_rejected_by_native_syntax",
                ),
                test(
                    "cdna_bfe64_tests",
                    "data_and_control_use_target_specific_counters_even_under_empty_exec",
                ),
            ],
        ),
        "vector": (
            "vector",
            "Selected per-lane integer and mathematical-real forms, finite raw storage conversions and exact partial-register effects; VOPD reads a pre-issue snapshot. No IEEE exceptional/rounding proof.",
            [
                test(
                    "gfx1250_packed_subword_tests",
                    "native_packed_negation_applies_independently_to_each_output_and_operand",
                ),
                reference(
                    AMD + "tests/gfx1250_full_execution.rs",
                    "original_f16_relu_preserves_both_symbolically_selected_halves",
                ),
                test(
                    "gfx1250_mul_u64_tests",
                    "each_word_of_each_factor_needs_its_actual_load_counter_only_when_executed",
                ),
            ],
            [
                test(
                    "gfx1250_packed_subword_tests",
                    "malformed_negate_arrays_never_get_partial_or_default_semantics",
                ),
                reference(
                    AMD + "tests/gfx1250_full_execution.rs",
                    "new_half_and_byte_forms_enforce_encoding_target_and_selector_bounds",
                ),
                test(
                    "gfx1250_mul_u64_tests",
                    "each_word_of_each_factor_needs_its_actual_load_counter_only_when_executed",
                ),
            ],
        ),
        "memory": (
            "memory_instruction",
            "Actual byte widths, per-component scalar address masking after register scaling, encoded nonnegative scalar offsets, configured allocations/subobjects, initialized data, source leases and native completion classes. Scope annotations do not create happens-before or whole-device guarantees.",
            [
                test(
                    "gfx1250_portable_abi_tests",
                    "complete_native_vector_transfer_keeps_last_input_and_whole_bounds",
                ),
                test(
                    "gfx1250_byte_definedness_tests",
                    "scalar_address_masks_follow_payload_width_and_scale_the_register_index_first",
                ),
                test(
                    "gfx1250_byte_definedness_tests",
                    "scalar_scaling_uses_the_complete_payload_and_retains_products_above_32_bits",
                ),
            ],
            [
                test(
                    "gfx1250_portable_abi_tests",
                    "whole_vector_transfer_cannot_straddle_adjacent_configured_lds_objects",
                ),
                graph(
                    "system_scope_visibility_requires_both_endpoints_completion_and_publication"
                ),
            ],
        ),
        "permutation": (
            "permute",
            "Wave32 source-lane exchange with its DS readiness dependency; no invented LDS memory access or publication.",
            [
                test(
                    "gfx1250_compiler_tests",
                    "real_gfx1250_crosswave_lds_exchange_and_complete_wave32_reduction",
                )
            ],
            [
                test(
                    "gfx1250_exact_wave_parity",
                    "native_crosslane_completion_does_not_publish_payload_between_waves",
                )
            ],
        ),
        "atomic": (
            "atomic_add_f32_no_return",
            "Selected no-return F32 RMW consumes initialized inout value, preserves its full footprint and separates translation/data completion.",
            [
                reference(
                    AMD + "tests/gfx1250_full_execution.rs",
                    "native_no_return_atomic_preserves_existing_f32_inout_value",
                )
            ],
            [
                graph("atomic_and_non_atomic_cross_wave_writes_have_typed_conflicts"),
                graph(
                    "atomic_trace_cannot_forge_return_results_counter_classes_or_rmw_effects"
                ),
            ],
        ),
        "branch": (
            "step",
            "Concrete native SCC/EXEC/VCC and resolved label control; symbolic data-dependent control and exhausted execution budgets cannot certify completion.",
            [
                test(
                    "gfx1250_boundary_parity_tests",
                    "symbolic_native_branch_is_explicit_while_concrete_branch_retains_its_value",
                )
            ],
            [
                test(
                    "gfx1250_boundary_parity_tests",
                    "unknown_directive_and_unresolved_branch_are_statically_rejected",
                )
            ],
        ),
        "control": (
            "step",
            "Selected nop/delay/clause/end controls retain issue/termination records. Delay instructions never substitute data completion or WMMA VALU spacing.",
            [
                test(
                    "gfx1250_boundary_parity_tests",
                    "canonical_native_termination_wait_and_complete_vector_load_controls_are_legal",
                )
            ],
            [
                graph(
                    "scalar_nop_data_wait_and_delay_alu_do_not_replace_wmma_valu_spacing"
                ),
                graph(
                    "completed_prefix_and_progress_after_endpgm_cannot_claim_a_complete_native_trace"
                ),
            ],
        ),
        "wait": (
            "wait",
            "Exact target-selected load/store/DS/KM/X counter thresholds; replay-source retirement does not fabricate data completion.",
            [graph("separate_data_counters_and_thresholds_control_register_readiness")],
            [
                graph(
                    "replay_lease_blocks_source_overwrite_but_xcnt_wait_does_not_complete_data"
                )
            ],
        ),
        "barrier": (
            "step",
            "Native unnamed shader split signal/wait across actual live waves; only completed effects publish and issue order cannot fabricate a wait.",
            [
                test(
                    "gfx1250_compiler_tests",
                    "real_gfx1250_crosswave_lds_exchange_and_complete_wave32_reduction",
                )
            ],
            [
                test(
                    "gfx1250_mechanism_boundary_tests",
                    "actual_named_barrier_missing_and_extra_operands_reject_before_reachability",
                ),
                graph(
                    "split_barrier_publishes_only_completed_effects_and_needs_all_live_waves"
                ),
            ],
        ),
        "matrix": (
            "wmma",
            "Actual complete-wave native F16 WMMA 16x16x32 register fragments, input snapshots, accumulator/result layouts and independent readiness windows.",
            [
                test(
                    "gfx1250_compiler_tests",
                    "real_gfx1250_wmma_all_a_and_b_basis_coordinates_run_through_native_interpreter",
                )
            ],
            [
                test(
                    "gfx1250_matrix_publication",
                    "wmma_result_read_and_source_reuse_need_their_actual_readiness_window",
                ),
                graph(
                    "malformed_wmma_roles_partial_waves_and_missing_implicit_exec_stay_unknown"
                ),
            ],
        ),
        "release": (
            "step",
            "Only terminal MSG_DEALLOC_VGPRS with zero scratch and following END; X leases drain without inventing data completion.",
            [
                reference(
                    AMD + "tests/gfx1250_deallocation.rs",
                    "native_symbolic_and_encoded_deallocation_spellings_share_the_epilogue",
                )
            ],
            [
                reference(
                    AMD + "tests/gfx1250_deallocation.rs",
                    "deallocation_cannot_enable_other_messages_scratch_or_post_release_register_use",
                )
            ],
        ),
    }
    result = {}
    for name, (value, meaning, positives, negatives) in definitions.items():
        result[name] = {
            "scope": meaning,
            "frontend_legality": [
                reference(AMD + "src/frontend/instr.rs", "validate_registers"),
                reference(AMD + "src/frontend/gfx1250.rs", "validate_typed_profile"),
            ],
            "lowering": [reference(AMD + "src/lower/mod.rs", "lower_with_globals")],
            "value_semantics": [reference(INTERP, value)],
            "event_semantics": [
                reference(INTERP, "step"),
                reference(INTERP, "instruction_registers"),
            ],
            "checker": [
                reference(GRAPH + "src/amdgpu.rs", "trace_contract"),
                reference(GRAPH + "src/amdgpu.rs", "check_amdgpu"),
            ],
            "primary_sources": [
                PUBLIC + "llvm/docs/AMDGPUUsage.md",
                PUBLIC + "llvm/docs/AMDGPUExecutionSynchronization.md",
            ],
            "positive_controls": positives,
            "negative_controls": negatives,
            "control_scope": "Named controls test the selected semantic family. They do not establish execution of every indexed PC or arbitrary immediate/modifier combinations.",
        }
    result["memory"]["primary_sources"].append(
        "https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf"
    )
    result["matrix"]["primary_sources"].append(
        "https://github.com/ROCm/FlyDSL/blob/f37f7a2b98f295902240f9f96612222003578b40/lib/Dialect/FlyROCDL/GFX1250/MmaAtom.cpp"
    )
    result["wait"]["lowering"].append(
        reference(AMD + "src/ir/instruction.rs", "lower_wait")
    )
    return result


def index_instructions(instructions, cases):
    owners = {}
    for case in cases:
        key = (case["assembly"], case["kernel"])
        if key in owners:
            raise ValueError(f"duplicate native entry: {key}")
        owners[key] = case["baseline_id"]
    profiles, found = {}, set()
    per_case = defaultdict(Counter)
    for row in instructions:
        owner = owners.get((row["path"], row["kernel"]))
        if owner is None:
            raise ValueError(
                f"unregistered native entry: {row['path']}::{row['kernel']}"
            )
        found.add(owner)
        form = {
            key: row.get(key)
            for key in ["mnemonic", "family", "operands", "modifiers", "component_slot"]
        }
        encoded = json.dumps(form, sort_keys=True, separators=(",", ":"))
        profile_id = hashlib.sha256(encoded.encode()).hexdigest()[:16]
        if profile_id not in profiles:
            profiles[profile_id] = {
                "id": profile_id,
                **form,
                "implementation_contract": category(row),
                "occurrences": 0,
                "case_occurrences": Counter(),
                "example": {key: row[key] for key in ["path", "kernel", "line"]},
            }
        elif any(profiles[profile_id][key] != value for key, value in form.items()):
            raise ValueError("instruction profile identity collision")
        profiles[profile_id]["occurrences"] += 1
        profiles[profile_id]["case_occurrences"][owner] += 1
        per_case[owner][profile_id] += 1
    missing = {case["baseline_id"] for case in cases} - found
    if missing:
        raise ValueError(f"native entries have no profiles: {sorted(missing)}")
    for row in profiles.values():
        row["case_occurrences"] = dict(sorted(row["case_occurrences"].items()))
    return sorted(
        profiles.values(), key=lambda row: (row["mnemonic"], row["id"])
    ), per_case


def generate():
    registry = json.loads(REGISTRY.read_text())
    cases, pins = [], {}
    for original in registry["cases"]:
        case = dict(original)
        for field in ["source", "assembly", "spec", "launch_config"]:
            path = REGISTRY.parent / case[field]
            actual = sha256(path)
            if actual != case[field + "_sha256"]:
                raise ValueError(f"stale original32 {field}: {case['baseline_id']}")
            case[field] = str(path.relative_to(ROOT))
            if field in {"source", "assembly"}:
                pins[case[field]] = actual
        cases.append(case)
    if len(cases) != 32 or len({case["baseline_id"] for case in cases}) != 32:
        raise ValueError("expected exactly32 original native cases")
    assemblies = sorted({case["assembly"] for case in cases})
    if len(assemblies) != 7:
        raise ValueError("expected exactly7 original native compiler modules")
    argv = [
        "cargo",
        "run",
        "--quiet",
        "-p",
        "volta_amdgpu_analysis",
        "--example",
        "instruction_inventory",
        "--",
        "--components",
        "--lower",
        *assemblies,
    ]
    result = subprocess.run(argv, cwd=ROOT, text=True, capture_output=True, check=True)
    instructions = [json.loads(line) for line in result.stdout.splitlines()]
    profiles, per_case = index_instructions(instructions, cases)
    contracts = implementation_contracts()
    case_rows = []
    for case in cases:
        case_rows.append(
            {
                "baseline_id": case["baseline_id"],
                "kernel": case["kernel"],
                **{
                    key: case[key]
                    for key in [
                        "source",
                        "source_sha256",
                        "assembly",
                        "assembly_sha256",
                        "spec",
                        "spec_sha256",
                        "launch_config",
                        "launch_config_sha256",
                    ]
                },
                "profile_occurrences": dict(
                    sorted(per_case[case["baseline_id"]].items())
                ),
                "positive_gates": [
                    {
                        "path": "tests/gfx1250/full/cpu/prove_cli.py",
                        "kernel_option": ["--kernel", case["kernel"]],
                    },
                    {
                        "path": "tests/gfx1250/full/cpu/prove_python.py",
                        "kernel_option": ["--kernel", case["kernel"]],
                    },
                ],
                "negative_harness_control": reference(
                    "tests/gfx1250/full/cpu/test_prove_cli.py",
                    "test_snapshot_runtime_and_log_mutations_fail",
                ),
            }
        )
    return {
        "schema_version": 1,
        "target": "gfx1250",
        "scope": "Original workload opcode/operand-shape/modifier profiles, including both VOPD component slots. This index validates frontend and lowering forms; it does not execute the workloads.",
        "profile_identity": "Mnemonic, typed family, operand shapes, exact named modifier values and optional VOPD slot. Register indices and immediate data values remain source-specific; their legality/semantics are never generalized from a shape.",
        "registry": {
            "path": str(REGISTRY.relative_to(ROOT)),
            "sha256": sha256(REGISTRY),
        },
        "generator_sha256": sha256(Path(__file__)),
        "inventory_example_sha256": sha256(
            ROOT / (AMD + "examples/instruction_inventory.rs")
        ),
        "source_pins": dict(sorted(pins.items())),
        "static_generation_command": argv,
        "case_count": 32,
        "assembly_count": 7,
        "mnemonic_count": len({row["mnemonic"] for row in profiles}),
        "profile_count": len(profiles),
        "instruction_component_occurrences": len(instructions),
        "implementation_contracts": contracts,
        "cases": case_rows,
        "profiles": profiles,
    }


def markdown(document):
    lines = [
        "# Actual original32 opcode and modifier profiles",
        "",
        "This generated index complements [stage-support.md](stage-support.md). Its typed frontend and lowering checks do not execute instructions. Value/event/checker contracts and named positive/negative family controls are linked in [stage-profiles.json](stage-profiles.json); each profile links its actual source entries. See the [CPU workflow guide](../full/cpu/README.md) for full-workload CLI/Python runs.",
        "",
        f"The seven compiler modules contain {document['mnemonic_count']} mnemonics and {document['profile_count']} typed profiles across {document['instruction_component_occurrences']} component occurrences. Both VOPD slots are indexed separately. A profile records operand shapes and exact named modifiers; it does not enable every immediate, register index or combination with those shapes.",
        "",
        "Regenerate with `python3 tests/gfx1250/full-parity/generate_stage_profiles.py`; use `--check` to reject drift.",
        "",
        "| Native opcode | Exact modifier sets | Profiles | Semantic contracts | Original cases |",
        "| --- | --- | --- | --- | --- |",
    ]
    by_name = defaultdict(list)
    for row in document["profiles"]:
        by_name[row["mnemonic"]].append(row)
    for name, rows in sorted(by_name.items()):
        modifiers = sorted(
            {
                ", ".join(
                    m["name"] + (":" + m["value"] if m["value"] is not None else "")
                    for m in row["modifiers"]
                )
                or "none"
                for row in rows
            }
        )
        contracts = sorted({row["implementation_contract"] for row in rows})
        cases = sorted({case for row in rows for case in row["case_occurrences"]})
        lines.append(
            f"| `{name}` | {'; '.join(modifiers)} | {len(rows)} | {', '.join(contracts)} | {', '.join(cases)} |"
        )
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    document = generate()
    outputs = {
        HERE / "stage-profiles.json": json.dumps(document, indent=2) + "\n",
        HERE / "stage-profiles.md": markdown(document),
    }
    for path, content in outputs.items():
        if args.check:
            if not path.is_file() or path.read_text() != content:
                raise SystemExit(f"stale generated stage profile index: {path.name}")
        else:
            path.write_text(content)
    print(
        f"Static parse/lower index: {document['case_count']} cases, {document['assembly_count']} modules, {document['mnemonic_count']} mnemonics, {document['profile_count']} profiles. Runtime checks are separate from this static index."
    )


if __name__ == "__main__":
    main()
