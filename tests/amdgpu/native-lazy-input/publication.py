#!/usr/bin/env python3
"""Publish allowlisted, deterministic metadata from the completed native-input study.

No verifier, build or measurement is run. Raw reports stay unchanged. Reproduce
with the named report paths in results/README.md; local path roots are remapped,
never copied into public records. Existing independent audits validate semantics;
this tool checks identities, denominators, projection types and arithmetic.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import math
from pathlib import Path, PurePosixPath
import re
import statistics

HERE = Path(__file__).resolve().parent
REPORT_SHA256 = {
    "baseline_plan": "9c05c6dbf68410c95255aa049047f8e27e5e38321de452181c464e359a91b4be",
    "comparison_plan": "9bcf643796b9c2b1b43bc9b49a8cd08c1909155efee31b2d1751b5dae14f2587",
    "baseline_qualification": "2b44f922b3108cab60a299e2e28612c9db96744cb0b827193f1327cd5d09e7ea",
    "candidate_qualification": "7144b3bb26922716b02fc396c835b81f8ffe4599489f004b566e70e87114c512",
    "paired": "667f748b27b59c45c0b0efb1dfc3f4fb38bceef7a3c3f6d8689504b8f1ec4bb1",
    "semantics": "d5b4839b539548af05ac9c2a9c51111ebd2d6b1ff2c5e7d8a4b9553e4d69d41a",
}
STATUSES = frozenset(
    (
        "certified_rejection",
        "ordinary_rejection",
        "graph_verified",
        "graph_accepted_without_output_proof",
        "spec_verified",
        "mathematical_refutation",
        "timeout",
        "unsupported",
        "inconclusive",
        "process_error",
        "contract_error",
    )
)
PROPERTIES = frozenset(
    (
        "AMD trace completeness",
        "AMD wait and register readiness",
        "AMD workgroup barrier generations",
        "AMD memory-conflict freedom",
    )
)
SAMPLE_NUMBERS = (
    "returncode",
    "timed_out",
    "log_limit_exceeded",
    "seconds",
    "raw_log_bytes",
    "first_marker_seconds",
    "qualified",
    "detected",
    "graph_accepted",
    "false_positive",
    "unsafe_acceptance",
    "endpoint_seconds",
    "new_contract_witness_audit_required",
    "new_coverage_credited",
)
SUMMARY_KEYS = (
    "primary",
    "valid",
    "benefit",
    "endpoint_nonregression",
    "rss_nonregression",
    "baseline_median_seconds",
    "candidate_median_seconds",
    "baseline_max_rss_kib",
    "candidate_max_rss_kib",
)
PUBLIC_HELPERS = {
    "tests/amdgpu/native-lazy-input/" + name
    for name in (
        "collect.py",
        "test_collect.py",
        "protocol.md",
        "selection.json",
        "comparison.py",
        "semantics.py",
        "test_comparison.py",
        "test_semantics.py",
        "collection.md",
        "compare_vexpr_structure_20261031.py",
        "test_compare_vexpr_structure_20261031.py",
    )
} | {
    "tests/amdgpu/memory-conflicts-study/benchmark.py",
    "tests/amdgpu/memory-conflicts-study/study.py",
    "tests/amdgpu/compiler-corpus/corpus.py",
    "tests/amdgpu/design-study/benchmark.py",
    "ai_compiler_kernels/check_races.py",
    "tests/gfx1250/measure_tensor_bounds.py",
}


def require(value, message):
    if not value:
        raise ValueError(message)


def encoded(value):
    return (
        json.dumps(value, sort_keys=True, indent=2, allow_nan=False) + "\n"
    ).encode()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return sha(
        json.dumps(
            value, sort_keys=True, separators=(",", ":"), allow_nan=False
        ).encode()
    )


def digest(value, optional=False):
    if optional and value is None:
        return None
    require(
        isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value),
        "invalid SHA256",
    )
    return value


def identifier(value):
    require(
        isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]*", value),
        "invalid public identifier",
    )
    return value


def choice(value, values, name):
    require(value in values, "unknown " + name)
    return value


def repo_path(value):
    require(
        isinstance(value, str)
        and not value.startswith(("/", "~"))
        and "\\" not in value,
        "invalid repository path",
    )
    parts = PurePosixPath(value).parts
    require(
        parts
        and parts[0] in {"tests", "crates", "external", "ai_compiler_kernels", "docs"}
        and ".." not in parts
        and all(re.fullmatch(r"[A-Za-z0-9_.-]+", part) for part in parts),
        "unsafe repository path",
    )
    return "repo/" + value


def numeric(value):
    require(
        value is None or type(value) in (bool, int, float), "non-numeric observation"
    )
    require(type(value) is not float or math.isfinite(value), "nonfinite observation")
    return value


def selected(row, keys):
    return {key: numeric(row[key]) for key in keys if key in row}


def counts(row):
    require(isinstance(row, dict), "invalid named counts")
    result = {}
    for key, value in row.items():
        require(type(value) is int and value >= 0, "invalid count")
        result[identifier(key)] = value
    return result


def diagnostics(errors):
    require(
        isinstance(errors, list) and all(isinstance(v, str) for v in errors),
        "invalid diagnostic list",
    )
    return {"count": len(errors), "raw_list_sha256": canonical(errors)}


def expression(row):
    if row is None:
        return None
    require(row["compression"] in {"gzip", "none"}, "unknown expression compression")
    return {
        **selected(
            row,
            (
                "artifact_bytes",
                "decoded_vexpr_bytes",
                "node_records",
                "node_table_payload_bytes",
                "output_count",
            ),
        ),
        **{
            key: digest(row[key])
            for key in (
                "artifact_sha256",
                "decoded_vexpr_sha256",
                "coordinate_map_sha256",
                "structural_output_map_sha256",
            )
        },
        "output_counts": counts(row["output_counts"]),
        "compression": row["compression"],
    }


def sample(row, *, role=None):
    result = {
        "case": identifier(row["case"]),
        "status": choice(row["status"], STATUSES, "status"),
        **selected(row, SAMPLE_NUMBERS),
        "measurement_errors": diagnostics(row["measurement_errors"]),
        "raw_record_sha256": canonical(row),
        "command_sha256": canonical(row["command"]),
        "role": choice(role or row["role"], {"baseline", "candidate"}, "arm"),
        "detection_mode": choice(
            row["detection_mode"],
            {None, "certified_prefix", "ordinary_graph"},
            "detection mode",
        ),
        "usage": selected(
            row["usage"], ("max_rss_kib", "user_seconds", "system_seconds")
        ),
        "transcript_sha256": {
            key: digest(row.get(key + "_sha256"), optional=True)
            for key in ("stdout", "stderr", "resources")
        },
        "capture_failure_recorded": bool(
            row.get("capture_failure") or row.get("not_run_reason")
        ),
    }
    if "stage" in row:
        result["stage"] = choice(row["stage"], {"export", "verify"}, "semantic stage")
    if "repeat" in row:
        require(
            type(row["repeat"]) is int and 1 <= row["repeat"] <= 5, "invalid repetition"
        )
        result["repeat"] = row["repeat"]
    signature = row["signature"]
    out = {
        "status": choice(signature["status"], STATUSES, "signature status"),
        **selected(signature, ("returncode", "executed_instructions")),
        "diagnostics_sha256": digest(signature["diagnostics_sha256"]),
    }
    for key, length in (("certificate_frame", 5), ("prefix_counts", 3)):
        values = signature.get(key)
        require(
            values is None
            or isinstance(values, list)
            and len(values) == length
            and all(type(v) is int and v >= 0 for v in values),
            "invalid certificate count/frame",
        )
        out[key] = values
    out["first_typed_witness"] = []
    for space, address, earlier, later in signature.get("first_typed_witness", []):
        require(
            space in {"Global", "Shared"}
            and all(re.fullmatch(r"\d+", str(v)) for v in (address, earlier, later)),
            "invalid numeric witness",
        )
        out["first_typed_witness"].append(
            {
                "space": space,
                "byte_address": int(address),
                "earlier_event": int(earlier),
                "later_event": int(later),
            }
        )
    result["signature"] = out
    if "graph_failure_names" in row:
        require(
            all(name in PROPERTIES for name in row["graph_failure_names"]),
            "unknown graph property",
        )
        result["graph_failure_names"] = row["graph_failure_names"]
    if "mathematical_mismatch_elements" in row:
        require(
            all(
                type(v) is int and v > 0 for v in row["mathematical_mismatch_elements"]
            ),
            "invalid mismatch count",
        )
        result["mathematical_mismatch_elements"] = row["mathematical_mismatch_elements"]
    if "gzip_capture" in row:
        capture = row["gzip_capture"]
        require(
            capture["compression"] == "gzip-level1-mtime0-empty-filename",
            "capture encoding changed",
        )
        result["gzip_capture"] = {
            **selected(
                capture,
                ("received_decoded_bytes", "writer_eof", "complete", "artifact_bytes"),
            ),
            "received_decoded_sha256": digest(
                capture.get("received_decoded_sha256"), optional=True
            ),
            "artifact_sha256": digest(capture.get("artifact_sha256"), optional=True),
            "errors": diagnostics(capture["errors"]),
            "compression": capture["compression"],
        }
    if "expressions" in row:
        result["expressions"] = expression(row["expressions"])
    if "full_output_artifact_valid" in row:
        result["full_output_artifact_valid"] = numeric(
            row["full_output_artifact_valid"]
        )
    return result


def build(row):
    require(re.fullmatch(r"[0-9a-f]{40}", row["revision"]), "invalid source revision")
    require(
        row["trust"] == "caller_attested"
        and row["source_clean"] is True
        and row["profile"] == "release"
        and row["default_features"] is True
        and row["features"] == [],
        "build profile differs",
    )
    require(
        row["command"] == ["cargo", "build", "--release", "-p", "volta_cli"],
        "build command differs",
    )
    fingerprint = row["rust_workspace_fingerprint"]
    require(
        fingerprint["algorithm"] == "sha256-git-tree-v1",
        "unknown workspace fingerprint",
    )
    versions = {}
    for name in ("rustc", "cargo"):
        require(
            re.fullmatch(
                name + r" \d+\.\d+\.\d+(?:[-\w.]*)? \([0-9a-f]+ \d{4}-\d{2}-\d{2}\)",
                row[name],
            ),
            "unrecognized compiler version",
        )
        versions[name] = row[name]
    return {
        "revision": row["revision"],
        "source_clean": True,
        "trust": row["trust"],
        "binary_sha256": digest(row["binary_sha256"]),
        "build_record_sha256": digest(row["build_record_sha256"]),
        "profile": "release",
        "default_features": True,
        "features": [],
        "command": row["command"],
        "rust_workspace_fingerprint": {
            "algorithm": fingerprint["algorithm"],
            "sha256": digest(fingerprint["sha256"]),
            "file_count": numeric(fingerprint["file_count"]),
        },
        "tool_versions": versions,
    }


def context(row):
    release = row.get("kernel_release", "").lower()
    version = re.match(r"\d+\.\d+\.\d+", row.get("python_version", ""))
    return {
        "platform": "WSL2"
        if any(v in release for v in ("microsoft", "wsl"))
        else "Linux",
        "architecture": choice(
            row["architecture"], {"x86_64", "aarch64", "riscv64"}, "architecture"
        ),
        **selected(row, ("logical_cpus", "allowed_logical_cpus")),
        "python_version": version.group(0) if version else None,
    }


def contract(row, pins):
    case, definition = row["case"], row["definition"]
    require(
        all(
            isinstance(values, list)
            and len(values) == len(set(values))
            and all(type(v) is int and v >= 0 for v in values)
            for values in case["output_indices"].values()
        ),
        "invalid output coordinates",
    )
    require(
        pins[row["assembly"]] == case["materialized_assembly_sha256"],
        "prepared module identity differs",
    )
    result = {
        "id": identifier(case["id"]),
        "target": choice(case["target"], {"gfx950", "gfx1250"}, "target"),
        "kernel": identifier(case["kernel"]),
        "expectation": choice(case["expectation"], {"safe", "hazard"}, "expectation"),
        "primary": bool(definition["primary"]),
        "previous_complete_equation_proved": definition[
            "previous_complete_equation_proved"
        ],
        "dimensions": counts(case["dimensions"]),
        "arrays": [],
        "output_indices": {
            identifier(k): [numeric(v) for v in values]
            for k, values in case["output_indices"].items()
        },
        "expected_outputs": numeric(case["expected_outputs"]),
        "input_elements": numeric(definition["input_elements"]),
        "input_bytes": numeric(definition["input_bytes"]),
        "materialized_assembly_sha256": digest(case["materialized_assembly_sha256"]),
        "configuration_sha256": digest(pins[row["configuration"]]),
        "prepared_module_sha256": digest(pins[row["assembly"]]),
    }
    require(
        result["previous_complete_equation_proved"] is None
        or type(result["previous_complete_equation_proved"]) is bool,
        "invalid prior proof flag",
    )
    for key in ("block", "grid", "workgroup"):
        require(
            len(case[key]) == 3 and all(type(v) is int and v >= 0 for v in case[key]),
            "invalid launch coordinates",
        )
        result[key] = case[key]
    for a in case["arrays"]:
        out = {
            "name": identifier(a["name"]),
            **selected(a, ("base_address", "element_size", "length")),
            "kind": choice(a["kind"], {"in", "out", "inout", "index"}, "array kind"),
        }
        if "dtype" in a:
            out["dtype"] = choice(
                a["dtype"],
                {"f16", "bf16", "f32", "f64", "u32", "u64", "i32", "i64"},
                "dtype",
            )
        result["arrays"].append(out)
    for key in (
        "source",
        "assembly",
        "spec",
        "launch_config",
        "launch_template",
        "spec_template",
    ):
        if key in case:
            result[key] = repo_path(case[key])
            result[key + "_sha256"] = digest(case[key + "_sha256"])
    require(
        all(
            re.fullmatch(r"(?:ptr:[A-Za-z0-9_]+|int:-?\d+)", v) for v in case["params"]
        ),
        "unsafe parameter",
    )
    result["params"] = case["params"]
    for key in (
        "configured_selected_output_elements",
        "logical_full_grid_output_elements",
    ):
        if key in case:
            result[key] = counts(case[key])
    if "contract_kind" in case:
        result["contract_kind"] = choice(
            case["contract_kind"],
            {"attention_full_query", "gemm_full_inputs"},
            "derived contract",
        )
    return result


def population(rows, expected, name):
    actual = [r["case"] for r in rows]
    require(
        len(actual) == len(set(actual)) == len(expected)
        and set(actual) == set(expected),
        name + " denominator differs",
    )


def functionals(row):
    return {
        **selected(
            row,
            (
                "candidate_cases",
                "baseline_qualified",
                "all_baseline_qualifiers_retained",
                "false_findings",
                "unsafe_acceptances",
                "passed",
            ),
        ),
        "safe_graph_failures": [
            {
                "case": identifier(r["case"]),
                "properties": [
                    choice(v, PROPERTIES, "property") for v in r["properties"]
                ],
            }
            for r in row["safe_graph_failures"]
        ],
        "baseline_unqualified_outcomes": [
            {
                "case": identifier(r["case"]),
                "status": choice(r["status"], STATUSES, "status"),
                "qualified": numeric(r["qualified"]),
                "measurement_errors": diagnostics(r["measurement_errors"]),
            }
            for r in row["baseline_unqualified_outcomes"]
        ],
    }


def summaries(paired, contracts):
    result = []
    primary = {r["id"]: r["primary"] for r in contracts}
    for row in paired["summary"]["cases"]:
        out = {"case": identifier(row["case"]), **selected(row, SUMMARY_KEYS)}
        groups = {
            arm: [
                r
                for r in paired["samples"]
                if r["case"] == row["case"] and r["role"] == arm
            ]
            for arm in ("baseline", "candidate")
        }
        valid = all(r["qualified"] for values in groups.values() for r in values)
        require(
            row["valid"] == valid and row["primary"] == primary[row["case"]],
            "summary validity/primary differs",
        )
        if valid:
            b, c = (
                statistics.median(r["endpoint_seconds"] for r in groups[arm])
                for arm in ("baseline", "candidate")
            )
            bm, cm = (
                max(r["usage"]["max_rss_kib"] for r in groups[arm])
                for arm in ("baseline", "candidate")
            )
            derived = {
                "baseline_median_seconds": b,
                "candidate_median_seconds": c,
                "baseline_max_rss_kib": bm,
                "candidate_max_rss_kib": cm,
                "benefit": bool(row["primary"] and c <= b * 0.8 and b - c >= 0.005),
                "endpoint_nonregression": c <= b * 1.10 + 0.002,
                "rss_nonregression": cm <= bm + max(bm * 0.05, 8192),
            }
            require(
                all(row[k] == v for k, v in derived.items()),
                "summary arithmetic differs",
            )
            require(b > 0 and c > 0, "invalid median endpoint")
            out.update(
                endpoint_delta_seconds=c - b,
                endpoint_change_percent=(c / b - 1) * 100,
                baseline_over_candidate=b / c,
                candidate_slower=c > b,
            )
        result.append(out)
    return result


def input_inventory(cp, bp):
    named = {
        cp["baseline_plan"]: "plans/baseline.json",
        cp["baseline_report"]: "baseline-qualification/report.json",
        cp["candidate"]["binary"]: "builds/candidate-volta",
        cp["candidate"]["build"]: "builds/candidate-build.json",
        bp["baseline"]["binary"]: "builds/baseline-volta",
        bp["baseline"]["build"]: "builds/baseline-build.json",
    }
    public_paths = set(PUBLIC_HELPERS)
    for row in bp["cases"]:
        cid = identifier(row["case"]["id"])
        named[row["assembly"]] = f"launches/{cid}/complete-module.s"
        named[row["configuration"]] = f"launches/{cid}/enabled.launch.json"
        public_paths.update(
            row["case"][key]
            for key in (
                "source",
                "assembly",
                "spec",
                "launch_config",
                "launch_template",
                "spec_template",
            )
            if key in row["case"]
        )
    result = []
    for index, (path, value) in enumerate(sorted(cp["input_sha256"].items())):
        alias = named.get(path)
        if alias is None:
            for relative in sorted(public_paths):
                if path.endswith("/" + relative):
                    alias = repo_path(relative)
                    break
        result.append(
            {"alias": alias or f"opaque-inputs/{index:04d}", "sha256": digest(value)}
        )
    require(len(result) == 195, "bound input count differs")
    return result


def project(documents, hashes):
    bp, cp, bq, cq, paired, semantic = [documents[k] for k in REPORT_SHA256]
    require(
        bq["role"] == "baseline" and cq["role"] == "candidate",
        "qualification roles differ",
    )
    require(
        bq["plan_sha256"] == cq["plan_sha256"] == hashes["baseline_plan"],
        "qualification plan binding differs",
    )
    require(
        paired["plan_sha256"] == semantic["plan_sha256"] == hashes["comparison_plan"],
        "comparison plan binding differs",
    )
    require(
        paired["candidate_qualification_sha256"]
        == semantic["candidate_qualification_sha256"]
        == hashes["candidate_qualification"],
        "qualification binding differs",
    )
    require(
        cp["baseline_report_sha256"] == hashes["baseline_qualification"]
        and cq["build"] == cp["candidate"]["identity"]
        and bq["build"] == bp["baseline"]["identity"],
        "build/baseline binding differs",
    )
    require(paired["functional"] == semantic["functional"], "functional gates differ")
    contracts = [contract(row, bp["input_sha256"]) for row in bp["cases"]]
    ids = [r["id"] for r in contracts]
    require(
        len(ids) == len(set(ids)) == 28 and sum(r["primary"] for r in contracts) == 3,
        "contract denominator differs",
    )
    population(bq["results"], ids, "baseline qualification")
    population(cq["results"], ids, "candidate qualification")
    eligible = cp["eligible"]
    require(
        len(eligible) == len(set(eligible)) == 27
        and eligible == bq["timing_eligible"] == cq["timing_eligible"],
        "baseline-only eligibility differs",
    )
    require(
        [(r["case"], r["repeat"], r["role"]) for r in paired["samples"]]
        == [tuple(r) for r in cp["schedule"]]
        and len(paired["samples"]) == 270,
        "paired observations differ",
    )
    require(
        [(r["case"], r["role"], r["stage"]) for r in semantic["process_records"]]
        == [tuple(r) for r in cp["semantic_schedule"]]
        and len(semantic["process_records"]) == 52,
        "semantic observations differ",
    )
    expected = {
        (cid, repeat, arm)
        for cid in eligible
        for repeat in range(1, 6)
        for arm in ("baseline", "candidate")
    }
    require(
        {tuple(v) for v in cp["schedule"]} == expected
        and len(cp["schedule"]) == len(expected),
        "paired coverage differs",
    )
    safe = cp["safe_semantic_cases"]
    require(
        len(safe) == len(set(safe)) == 13
        and all(
            next(r for r in contracts if r["id"] == cid)["expectation"] == "safe"
            for cid in safe
        ),
        "safe semantic denominator differs",
    )
    require(
        cp["semantic_schedule"]
        == [
            [cid, arm, stage]
            for cid in safe
            for arm in ("baseline", "candidate")
            for stage in ("export", "verify")
        ],
        "semantic schedule differs",
    )
    population(paired["summary"]["cases"], eligible, "case summary")
    population(semantic["output_comparisons"], safe, "structural comparison")
    previous = semantic["proofs"]["previously_proved_cases"]
    require(
        len(previous) == len(set(previous)) == 11 and set(previous) <= set(safe),
        "proof denominator differs",
    )
    structural = [
        {
            "case": identifier(r["case"]),
            "all_coordinates_valid": numeric(r["all_coordinates_valid"]),
            "structural_match": numeric(r["structural_match"]),
            **{arm: expression(r[arm]) for arm in ("baseline", "candidate")},
        }
        for r in semantic["output_comparisons"]
    ]
    case_summaries = summaries(paired, contracts)
    wins = sum(row["benefit"] for row in case_summaries)
    require(
        paired["summary"]["primary_wins"] == wins
        and paired["summary"]["primaries_required"] == 2
        and paired["summary"]["performance_point_gates_pass"]
        == (
            wins >= 2
            and all(
                row["valid"]
                and row["endpoint_nonregression"]
                and row["rss_nonregression"]
                for row in case_summaries
            )
        ),
        "aggregate point-gate arithmetic differs",
    )
    require(
        cp["budgets"]
        == {
            "timeout_seconds": 60,
            "repeats": 5,
            "seed": 20261031,
            "gzip_bytes": 2**31,
            "reserve_bytes": 2**31,
            "other_bytes": 256 * 2**20,
        },
        "study budgets differ",
    )
    return {
        "schema_version": 1,
        "dataset": "native-demand-input-materialization",
        "raw_report_sha256": {k: digest(v) for k, v in hashes.items()},
        "protocol_sha256": digest(bp["protocol_sha256"]),
        "selection_sha256": digest(bp["selection_sha256"]),
        "builds": {
            "baseline": build(bp["baseline"]["identity"]),
            "candidate": build(cp["candidate"]["identity"]),
        },
        "candidate_patch_sha256": digest(cp["candidate"]["reviewed_patch_sha256"]),
        "runtime": context(paired["runtime_context"]),
        "budgets": cp["budgets"],
        "structural_comparator": {
            key: digest(cp["structural_comparator"][key])
            for key in ("sha256", "tests_sha256")
        },
        "bound_inputs": input_inventory(cp, bp),
        "raw_bound_input_inventory_sha256": canonical(cp["input_sha256"]),
        "contracts": contracts,
        "baseline_qualification": [sample(r, role="baseline") for r in bq["results"]],
        "candidate_qualification": [sample(r, role="candidate") for r in cq["results"]],
        "paired_observations": [sample(r) for r in paired["samples"]],
        "case_summaries": case_summaries,
        "semantic_observations": [sample(r) for r in semantic["process_records"]],
        "output_comparisons": structural,
        "proofs": {
            "previously_proved_cases": [identifier(v) for v in previous],
            "all_previous_complete_proofs_retained": numeric(
                semantic["proofs"]["all_previous_complete_proofs_retained"]
            ),
            "other_equations": [
                {
                    "case": identifier(r["case"]),
                    "role": choice(r["role"], {"baseline", "candidate"}, "arm"),
                    "status": choice(r["status"], STATUSES, "status"),
                    "measurement_errors": diagnostics(r["measurement_errors"]),
                }
                for r in semantic["proofs"]["other_equations"]
            ],
        },
        "functional_gates": functionals(paired["functional"]),
        "semantic_gates": selected(
            semantic,
            (
                "all_semantic_controls_pass",
                "false_findings",
                "unsafe_acceptances",
                "mathematical_refutations",
                "compressed_bytes",
                "aggregate_raw_log_bytes",
                "other_bytes",
            ),
        ),
        "point_gates": selected(
            paired["summary"],
            ("primary_wins", "primaries_required", "performance_point_gates_pass"),
        ),
        "slower_cases": [
            r["case"] for r in case_summaries if r.get("candidate_slower")
        ],
        "baseline_timing_eligible": [identifier(v) for v in eligible],
        "dataset_metrics": {
            name: selected(
                row,
                (
                    "aggregate_raw_log_bytes",
                    "aggregate_log_budget_exceeded",
                    "other_bytes",
                ),
            )
            for name, row in (
                ("baseline_qualification", bq),
                ("candidate_qualification", cq),
                ("paired", paired),
                ("semantics", semantic),
            )
        },
        "arithmetic": {
            "endpoint": "Hazard: first validated-certificate marker; safe: parent-observed process completion.",
            "case_median": "Median of all five endpoint_seconds observations per arm, including the first.",
            "case_rss": "Maximum usage.max_rss_kib across all five observations per arm.",
            "primary_benefit": "candidate_median <= baseline_median*0.8 AND baseline_median-candidate_median >=0.005 seconds; at least two of three primaries.",
            "endpoint_nonregression": "candidate_median <= baseline_median*1.10+0.002 seconds.",
            "rss_nonregression": "candidate_max <= baseline_max+max(baseline_max*0.05,8192 KiB).",
        },
        "limits": [
            "Five descriptive observations per arm, including the first; no p95, CI, phase CPU attribution or universal speedup claim.",
            "Every timeout, refusal and unqualified case is retained; unavailable metrics supply no ratio.",
            "Thirteen output-structure matches are not mathematical proofs: eleven previous full equations are retained; convolution and attention remain unproved.",
            "Full-input GEMM safe qualification timed out in both arms; it has no paired ratio, export or mathematical proof.",
            "CPU-only WSL2 measurements; no GPU execution or hardware-performance claim.",
            "Build/source association is caller-attested; source/binary hashes do not prove reproducible builds.",
            "Private paths, commands, diagnostics, host/device identities and expression payloads are omitted; their identity hashes remain.",
        ],
    }


def csv_bytes(rows):
    columns = sorted(set().union(*(set(row) for row in rows)))
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=columns, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow(
            {
                k: json.dumps(v, sort_keys=True, separators=(",", ":"), allow_nan=False)
                if isinstance(v, (dict, list))
                else v
                for k, v in row.items()
            }
        )
    return output.getvalue().encode()


def readme(result):
    rows = result["case_summaries"]
    gates = result["point_gates"]
    passed = (
        result["functional_gates"]["passed"]
        and result["semantic_gates"]["all_semantic_controls_pass"]
        and gates["performance_point_gates_pass"]
    )
    comparisons = result["output_comparisons"]
    matched = sum(r["structural_match"] for r in comparisons)
    exports = [r for r in result["semantic_observations"] if r["stage"] == "export"]
    selected_outputs = sum(
        sum(r["output_counts"].values())
        for r in (v["baseline"] for v in comparisons)
        if r is not None
    )
    lines = [
        "# Native demand-input materialization results",
        "",
        "The fixed five-pair CPU-only WSL2 study "
        + (
            "passed its predeclared functional, performance and semantic gates."
            if passed
            else "did not pass every predeclared gate; failures remain in the data."
        ),
        f"The three predeclared wide primaries had {gates['primary_wins']} benefit-gate wins. All 27 cases appear below, including every regression. These are descriptive results from five processes per arm, including the first.",
        "",
        f"The candidate median was slower in {len(result['slower_cases'])} of 27 cases. Hazard endpoints are parent-observed first validated-certificate rejection; safe endpoints are parent-observed process completion. RSS is the maximum of all five processes. JSON/CSV preserve unrounded values; only this table rounds for reading.",
        "",
        "| Case | Baseline ms | Candidate ms | Change | Baseline/candidate | Max RSS KiB baseline/candidate | Within allowances |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]
    for row in rows:
        if row["valid"]:
            lines.append(
                f"| `{row['case']}` | {row['baseline_median_seconds'] * 1000:.3f} | {row['candidate_median_seconds'] * 1000:.3f} | {row['endpoint_change_percent']:+.2f}% | {row['baseline_over_candidate']:.2f}× | {row['baseline_max_rss_kib']:g}/{row['candidate_max_rss_kib']:g} | {'yes' if row['endpoint_nonregression'] and row['rss_nonregression'] else 'no'} |"
            )
        else:
            lines.append(
                f"| `{row['case']}` | unavailable | unavailable | unavailable | unavailable | unavailable | no |"
            )
    for cid, label in (
        ("memory-wide-gfx1250-matvec_f16-safe", "Safe matvec"),
        ("memory-gfx950-elementwise-address-alias", "gfx950 elementwise hazard"),
    ):
        row = next((r for r in rows if r["case"] == cid and r["valid"]), None)
        if row:
            lines += [
                "",
                f"{label} was slower by {row['endpoint_change_percent']:+.2f}% ({row['endpoint_delta_seconds'] * 1000:+.2f} ms). This remains visible even when inside the predeclared 10% + 2 ms allowance.",
            ]
    lines += [
        "",
        "The publication retains all 56 qualification outcomes, 270 paired observations (14 hazardous and 13 safe configurations) and 52 separate semantic/specification controls. Both full-input GEMM safe qualifications timed out and supplied no paired ratio, export or proof.",
        f"All {len(exports)} full export records remain. {matched} of 13 exact-coordinate rooted DAG maps matched modulo node numbering, covering {selected_outputs:,} selected outputs per arm. Retention of all 11 previous complete equation proofs: {str(result['proofs']['all_previous_complete_proofs_retained']).lower()}. The four retained specification attempts for the same two previously unproved equations (convolution and attention), in the two arms, remain listed individually. Structural equality is not a mathematical proof. Export/specification timings supply no performance claim.",
        "",
        "The full-A/B GEMM inserted-collision case is nonprimary. It retains its new full allocation contract and source-grounded certificate; the improvement does not constitute new algorithmic bug-detection coverage. The old attention-prefix and GEMM-prefix studies remain unchanged. See [protocol](../protocol.md) and [collection](../collection.md) for selection, thresholds and process controls.",
        "",
        "`metadata.json` contains declared allocations, selected workgroup/output coordinates, source/module/spec/config/build/binary/tool hashes, per-observation transcript hashes and redacted-diagnostic identity hashes. `observations.csv` contains the same 378 individual records; `case-summaries.csv` contains all 27 descriptive medians/maxima/gates. Commands and private local roots are omitted. Bound inputs use `repo/`, `builds/` and `launches/` aliases; other inputs retain an opaque alias and content hash. Raw reports and full gzip payloads remain retained locally.",
        "",
        "[Independent audit bindings](audit.json) retain the raw receipt hashes, check/error counts and script identities without private paths or free-form context.",
        "",
        "Recalculate the published numbers without private raw files:",
        "",
        "```sh",
        "python3 tests/amdgpu/native-lazy-input/publication.py --check-public tests/amdgpu/native-lazy-input/results/metadata.json",
        "```",
        "",
        "For each case/arm, take the median of all five `endpoint_seconds` values and the maximum `usage.max_rss_kib`. The benefit gate requires at least two of three primary medians to improve by at least 20% and 5 ms. Every eligible case must satisfy candidate median ≤ baseline × 1.10 + 2 ms and candidate maximum RSS ≤ baseline + max(5%, 8192 KiB). All observations, including the first, enter these formulas. `--check-public` verifies the public sibling hashes, recomputes these formulas and checks all 27 rows; it runs no verifier.",
        "",
        "Reproduce the projection from the named immutable raw inputs (replace `RAW` with local archived paths):",
        "",
        "```sh",
        "python3 tests/amdgpu/native-lazy-input/publication.py \\",
        "  --baseline-plan RAW/baseline-plan/plan.json \\",
        "  --comparison-plan RAW/comparison/plan.json \\",
        "  --baseline-qualification RAW/baseline-qualification/report.json \\",
        "  --candidate-qualification RAW/comparison/candidate-qualification/report.json \\",
        "  --paired RAW/comparison/paired/report.json \\",
        "  --semantics RAW/comparison/semantics/report.json \\",
        "  --output PUBLICATION",
        "```",
        "",
        "The projection command accepts only the six archived report identities recorded in its source; it does not accept newly repeated measurements. Include one `--audit NAME=SHA256=RAW_RECEIPT` per entry in `audit.json` to reproduce those audit bindings. Repeating the study uses the separate protocol/collection commands and creates new raw results; recalculating public arithmetic needs only the public metadata/CSV. The raw source/build association remains caller-attested; no GPU execution, phase CPU attribution, confidence interval or universal speed claim is inferred.",
        "",
    ]
    return "\n".join(lines).encode()


def artifacts(result):
    observations = []
    for dataset in (
        "baseline_qualification",
        "candidate_qualification",
        "paired_observations",
        "semantic_observations",
    ):
        observations.extend({"dataset": dataset, **row} for row in result[dataset])
    output = {
        "observations.csv": csv_bytes(observations),
        "case-summaries.csv": csv_bytes(result["case_summaries"]),
        "README.md": readme(result),
        "audit.json": encoded(result.get("independent_audits", [])),
    }
    metadata = {
        **result,
        "public_artifact_sha256": {name: sha(data) for name, data in output.items()},
    }
    return {"metadata.json": encoded(metadata), **output}


def load(paths):
    documents, hashes = {}, {}
    for name, path in paths.items():
        raw = path.read_bytes()
        require(sha(raw) == REPORT_SHA256[name], "frozen " + name + " identity differs")
        documents[name], hashes[name] = json.loads(raw), sha(raw)
    return documents, hashes


def audit_receipts(items):
    result = []
    seen = set()
    for value in items:
        name, expected, filename = value.split("=", 2)
        choice(
            name,
            {"baseline", "candidate_plan", "candidate", "paired", "semantics"},
            "audit name",
        )
        require(name not in seen, "duplicate audit receipt")
        seen.add(name)
        raw = Path(filename).read_bytes()
        require(sha(raw) == digest(expected), "audit receipt identity differs")
        row = json.loads(raw)
        require(
            type(row["checks"]) is int
            and row["checks"] >= 0
            and type(row["pass"]) is bool,
            "invalid audit counts/result",
        )
        errors = row["errors"]
        error_count = len(errors) if isinstance(errors, list) else errors
        require(
            type(error_count) is int and error_count >= 0, "invalid audit error count"
        )
        require(row["pass"] == (error_count == 0), "inconsistent audit pass/errors")
        result.append(
            {
                "name": name,
                "receipt_sha256": expected,
                "checks": row["checks"],
                "errors": error_count,
                "pass": row["pass"],
                **{
                    key: digest(row[key])
                    for key in ("script_sha256", "tests_sha256")
                    if key in row
                },
            }
        )
    return sorted(result, key=lambda row: row["name"])


def check_public(result):
    cases = result["case_summaries"]
    rows = result["paired_observations"]
    definitions = result["contracts"]
    ids = [row["id"] for row in definitions]
    require(len(ids) == len(set(ids)) == 28, "public contract denominator differs")
    population(result["baseline_qualification"], ids, "public baseline qualification")
    population(result["candidate_qualification"], ids, "public candidate qualification")
    safe = [
        row["id"]
        for row in definitions
        if row["expectation"] == "safe"
        and row["id"] in result["baseline_timing_eligible"]
    ]
    require(len(safe) == 13, "public safe semantic denominator differs")
    semantic = result["semantic_observations"]
    require(
        len(semantic) == 52
        and [(row["case"], row["role"], row["stage"]) for row in semantic]
        == [
            (cid, arm, stage)
            for cid in safe
            for arm in ("baseline", "candidate")
            for stage in ("export", "verify")
        ],
        "public semantic denominator/order differs",
    )
    population(result["output_comparisons"], safe, "public output comparison")
    previous = [
        row["id"] for row in definitions if row["previous_complete_equation_proved"]
    ]
    require(
        len(previous) == 11 and result["proofs"]["previously_proved_cases"] == previous,
        "public proof denominator differs",
    )
    require(len(cases) == 27, "public summary count differs")
    population(cases, result["baseline_timing_eligible"], "public case summary")
    expected = {
        (cid, repeat, arm)
        for cid in result["baseline_timing_eligible"]
        for repeat in range(1, 6)
        for arm in ("baseline", "candidate")
    }
    require(
        len(rows) == len(expected) == 270
        and {(r["case"], r["repeat"], r["role"]) for r in rows} == expected,
        "public paired denominator differs",
    )
    require(
        summaries({"summary": {"cases": cases}, "samples": rows}, result["contracts"])
        == cases,
        "public descriptive arithmetic differs",
    )
    wins = sum(row["benefit"] for row in cases)
    passed = wins >= 2 and all(
        row["valid"] and row["endpoint_nonregression"] and row["rss_nonregression"]
        for row in cases
    )
    require(
        result["point_gates"]
        == {
            "primary_wins": wins,
            "primaries_required": 2,
            "performance_point_gates_pass": passed,
        },
        "public aggregate gate differs",
    )
    require(
        result["slower_cases"]
        == [row["case"] for row in cases if row.get("candidate_slower")],
        "public regression list differs",
    )
    return {
        "paired_observations": len(rows),
        "case_summaries": len(cases),
        "slower_cases": len(result["slower_cases"]),
        "performance_point_gates_pass": passed,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in REPORT_SHA256:
        parser.add_argument("--" + name.replace("_", "-"), type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check-public", type=Path)
    parser.add_argument(
        "--audit", action="append", default=[], metavar="NAME=SHA256=PATH"
    )
    args = parser.parse_args()
    if args.check_public:
        require(
            args.output is None
            and not args.audit
            and all(getattr(args, name) is None for name in REPORT_SHA256),
            "check-public accepts only public metadata",
        )
        result = json.loads(args.check_public.read_text())
        require(
            set(result["public_artifact_sha256"])
            == {"observations.csv", "case-summaries.csv", "README.md", "audit.json"},
            "public sibling artifact denominator differs",
        )
        for name, expected in result["public_artifact_sha256"].items():
            require(
                name
                in {
                    "observations.csv",
                    "case-summaries.csv",
                    "README.md",
                    "audit.json",
                },
                "unknown public artifact",
            )
            require(
                sha((args.check_public.parent / name).read_bytes()) == digest(expected),
                "public sibling artifact differs",
            )
        print(json.dumps(check_public(result), sort_keys=True))
        return
    require(
        args.output is not None
        and all(getattr(args, name) is not None for name in REPORT_SHA256),
        "projection needs all six named reports and --output",
    )
    require(not args.output.exists(), "publication directory must be fresh")
    documents, hashes = load({name: getattr(args, name) for name in REPORT_SHA256})
    result = project(documents, hashes)
    result["independent_audits"] = audit_receipts(args.audit)
    result["publication_tools"] = {
        "publisher_sha256": sha(Path(__file__).read_bytes()),
        "tests_sha256": sha((HERE / "test_publication.py").read_bytes()),
    }
    output = artifacts(result)
    args.output.mkdir(parents=True)
    for name, data in output.items():
        (args.output / name).write_bytes(data)
    print(
        json.dumps({name: sha(data) for name, data in output.items()}, sort_keys=True)
    )


if __name__ == "__main__":
    main()
