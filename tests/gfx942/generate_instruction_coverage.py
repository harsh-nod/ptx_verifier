#!/usr/bin/env python3
"""Inventory gfx942 compiler forms using the native parser and typed lowerer.

Run from any directory. --check compares without writing. Named semantic tests
are coverage references, not a claim that every observed PC has executed.
"""

import argparse
import collections
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "tests/gfx942"
COMPILER_TESTS = "crates/volta_pipeline/tests/gfx942_compiler_tests.rs"
SEMANTIC_TESTS = "crates/volta_amdgpu_analysis/tests/gfx942_scalar_memory.rs"
PROOFS = {
    "copy": "real_gfx942_manifest_tail_and_nonzero_groups_preserve_absolute_output_indices",
    "add": "real_gfx942_manifest_tail_and_nonzero_groups_preserve_absolute_output_indices",
    "exchange": "real_gfx942_crosswave_lds_exchange_and_complete_wave64_reduction",
    "reduce": "real_gfx942_crosswave_lds_exchange_and_complete_wave64_reduction",
    "ids_3d": "real_gfx942_three_dimensional_ids_match_all_24_coordinates",
    "mfma_f32": "real_gfx942_f32_and_f16_mfma_match_all_independent_dot_products",
    "mfma_f16": "real_gfx942_f32_and_f16_mfma_match_all_independent_dot_products",
    "pipelined_mfma_f16": "real_gfx942_two_wave_lds_mfma_pipeline_computes_all_512_outputs",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def reference(path, function):
    text = (ROOT / path).read_text()
    if not re.search(r"\bfn\s+" + re.escape(function) + r"\s*\(", text):
        raise ValueError(f"missing Rust function: {path}::{function}")
    return {"path": path, "function": function}


def generate():
    cases_path = CORPUS / "cases.json"
    cases = json.loads(cases_path.read_text())["cases"]
    provenance = json.loads((CORPUS / "fixtures/compiler-provenance.json").read_text())
    paths = sorted({f"tests/gfx942/{case['assembly']}" for case in cases})
    compiler = {
        f"tests/gfx942/fixtures/{row['assembly']}": row
        for row in provenance["fixtures"]
    }
    if set(paths) != set(compiler):
        raise ValueError("case and compiler-provenance assembly sets differ")
    for path in paths:
        if digest(ROOT / path) != compiler[path]["assembly_sha256"]:
            raise ValueError(f"compiler assembly hash mismatch: {path}")
        if not re.search(
            r'\.amdgcn_target\s+"amdgcn-amd-amdhsa--gfx942"', (ROOT / path).read_text()
        ):
            raise ValueError(f"source is not an original gfx942 module: {path}")
    for case in cases:
        for field in ("assembly", "source", "spec"):
            if digest(CORPUS / case[field]) != case[f"{field}_sha256"]:
                raise ValueError(f"{case['kernel']}: {field} hash mismatch")
        reference(COMPILER_TESTS, PROOFS[case["kernel"]])

    command = [
        "cargo",
        "run",
        "--release",
        "--quiet",
        "--locked",
        "--offline",
        "-p",
        "volta_amdgpu_analysis",
        "--example",
        "instruction_inventory",
        "--",
        "--lower",
        *paths,
    ]
    run = subprocess.run(command, cwd=ROOT, check=True, capture_output=True, text=True)
    instructions = [json.loads(line) for line in run.stdout.splitlines()]
    expected_kernels = {
        (f"tests/gfx942/{case['assembly']}", case["kernel"]) for case in cases
    }
    if {(row["path"], row["kernel"]) for row in instructions} != expected_kernels:
        raise ValueError("parsed entry set differs from the complete case manifest")
    groups = collections.defaultdict(list)
    for row in instructions:
        profile = {key: row[key] for key in ("family", "operands", "modifiers")}
        groups[(row["mnemonic"], json.dumps(profile, sort_keys=True))].append(row)
    forms = []
    for (mnemonic, profile), rows in sorted(groups.items()):
        examples = []
        for row in rows:
            text = (
                (ROOT / row["path"]).read_text().splitlines()[row["line"] - 1].strip()
            )
            examples.append(
                {**{key: row[key] for key in ("path", "kernel", "line")}, "text": text}
            )
        forms.append(
            {
                "mnemonic": mnemonic,
                "profile": json.loads(profile),
                "frontend": "parsed",
                "typed_lowering": "lowered",
                "execution": "not measured per form; see separate complete-kernel tests",
                "independent_semantics": "not measured per form; see separate kernel proofs and interaction controls",
                "complete_kernel_proof": "not measured per form; see separate kernel_proofs",
                "kernel_contexts": sorted({row["kernel"] for row in rows}),
                "occurrences": examples,
            }
        )

    inventory = {
        "schema_version": 1,
        "target": "gfx942",
        "wavefront_size": 64,
        "scope": "Unchanged compiler assemblies in tests/gfx942/cases.json; not the complete ISA or all inline Rust fixtures.",
        "interpretation": [
            "Regeneration parses and lowers every selected entry in each complete original module. It does not execute instructions.",
            "Profiles distinguish exact mnemonic suffixes, register classes/tuple widths, source modifiers and instruction modifiers. Integer values remain in exact source occurrences, not profile keys.",
            "Execution, independent mathematical semantics and complete selected-workgroup proofs are separate named test references. They do not assert every static PC or every encodable operand executes.",
            "Incomplete execution remains UNKNOWN. A readiness or synchronization rejection is distinct from an output-equivalence proof.",
        ],
        "generator": "tests/gfx942/generate_instruction_coverage.py",
        "parse_lower_command": command,
        "totals": {
            "compiler_modules": len(paths),
            "kernel_configurations": len(cases),
            "instructions": len(instructions),
            "exact_mnemonics": len({row["mnemonic"] for row in instructions}),
            "observed_operand_modifier_profiles": len(forms),
        },
        "inputs": [
            {"path": path, "sha256": digest(ROOT / path)}
            for path in [
                "tests/gfx942/cases.json",
                "tests/gfx942/fixtures/compiler-provenance.json",
                *paths,
            ]
        ],
        "kernel_proofs": [
            {
                "kernel": case["kernel"],
                "assembly": f"tests/gfx942/{case['assembly']}",
                "launch_and_allocations": "tests/gfx942/cases.json",
                "specification": f"tests/gfx942/{case['spec']}",
                "complete_output_elements": case["expected_outputs"],
                "independent_semantics_and_graph_check": reference(
                    COMPILER_TESTS, PROOFS[case["kernel"]]
                ),
            }
            for case in cases
        ],
        "interaction_controls": [
            reference(SEMANTIC_TESTS, name)
            for name in (
                "wide_loads_mask_components_before_addition_and_snapshot_the_aliased_base",
                "every_loaded_word_needs_lgkm_completion_even_when_exec_was_empty",
                "masking_keeps_the_full_wide_allocation_footprint",
            )
        ]
        + [
            reference(COMPILER_TESTS, name)
            for name in (
                "removing_real_gfx942_lds_publication_barriers_exposes_typed_shared_conflicts",
                "removing_real_gfx942_load_waits_or_matrix_result_spacing_cannot_verify",
            )
        ],
        "explicit_boundaries": [
            {
                "profile": "gfx942 FP8/BF8 FNUZ decoding and CDNA4-only matrix forms",
                "status": "unsupported",
                "control": reference(
                    "crates/volta_amdgpu_analysis/tests/targets.rs",
                    "cdna4_forms_and_different_fp8_numbers_cannot_be_relabelled_as_gfx942",
                ),
            },
            {
                "profile": "gfx942 raw buffers, direct-to-LDS, atomics, scratch/private and general device calls",
                "status": "unsupported",
                "contract": "crates/volta_amdgpu_analysis/README.md",
            },
            {
                "profile": "All other ISA forms absent from this compiler corpus",
                "status": "not inventoried; absence is not support or refusal evidence",
            },
        ],
        "public_semantic_sources": [
            {
                "title": "AMD Instinct MI300 CDNA3 ISA",
                "url": "https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf",
                "sections": [
                    "4.4 counters",
                    "8.2.1.1 scalar address components",
                    "8.4 alignment",
                    "12.6 scalar memory widths",
                ],
            },
            {
                "title": "Pinned LLVM SMEM encoding",
                "url": "https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SMInstructions.td",
            },
        ],
        "forms": forms,
    }
    return json.dumps(inventory, indent=2) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    text = generate()
    output = CORPUS / "instruction-coverage.json"
    if args.check:
        if not output.is_file() or output.read_text() != text:
            raise SystemExit("gfx942 instruction inventory is stale; regenerate it")
    else:
        output.write_text(text)
    print(json.dumps(json.loads(text)["totals"], sort_keys=True))


if __name__ == "__main__":
    main()
