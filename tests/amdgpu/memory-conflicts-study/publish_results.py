#!/usr/bin/env python3
"""Render compact public observations from completed, reviewed raw study reports.

No collection, verifier invocation or independent arithmetic-audit claim.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
_SPEC = importlib.util.spec_from_file_location(
    "publication_heldouts", HERE / "heldout.py"
)
H = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(H)
B = H.B
STATUSES = frozenset(
    {
        "graph_verified",
        "graph_accepted_without_output_proof",
        "ordinary_rejection",
        "certified_rejection",
        "spec_verified",
        "mathematical_refutation",
        "inconclusive",
        "unsupported",
        "timeout",
        "process_error",
        "contract_error",
        "assembler_refused",
    }
)
MISSES = frozenset({"inconclusive", "unsupported", "timeout"})


def sha_value(value):
    B.require(
        isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value),
        "missing or malformed SHA-256",
    )
    return value


def commit(value):
    B.require(
        isinstance(value, str) and re.fullmatch(r"[0-9a-f]{40}", value),
        "missing or malformed source revision",
    )
    return value


def number(value, *, integer=False, nullable=False, negative=False):
    if value is None and nullable:
        return None
    B.require(
        type(value) is int if integer else type(value) in (int, float),
        "missing or nonnumeric observation",
    )
    B.require(
        math.isfinite(value) and (negative or value >= 0),
        "nonfinite or invalid negative observation",
    )
    return value


def boolean(value, *, nullable=False):
    B.require(
        type(value) is bool or (nullable and value is None),
        "missing or invalid Boolean observation",
    )
    return value


def status(value):
    B.require(value in STATUSES, "unknown outcome classification")
    return value


def exact_rows(rows, ids, key="case"):
    B.require(
        len(rows) == len(ids)
        and len({r[key] for r in rows}) == len(rows)
        and {r[key] for r in rows} == set(ids),
        "missing, duplicate or extra case rows",
    )
    return {row[key]: row for row in rows}


def observation(value, expected_counts):
    if value is None:
        return None
    counts = value["output_counts"]
    B.require(
        set(counts) <= set(expected_counts), "unknown output label in observation"
    )
    return {
        "sha256": sha_value(value["sha256"]),
        "bytes": number(value["bytes"], integer=True),
        "coordinates_sha256": sha_value(value["coordinates_sha256"]),
        "output_counts": {
            name: number(count, integer=True) for name, count in sorted(counts.items())
        },
    }


def retention(value, expected_counts):
    result = {
        "validated_complete": boolean(value["validated_complete"]),
        "observation": observation(value["observation"], expected_counts),
    }
    if result["validated_complete"]:
        expected = {name: list(range(count)) for name, count in expected_counts.items()}
        B.require(
            result["observation"] is not None
            and result["observation"]["output_counts"] == expected_counts
            and result["observation"]["coordinates_sha256"]
            == B.study.canonical(expected),
            "claimed complete retention lacks exact configured coordinates",
        )
    return result


def sample(value, expected_counts):
    """Explicit whitelist; never copy a command, path, context or error message."""
    usage = value["usage"]
    errors = value["measurement_errors"]
    B.require(
        isinstance(errors, list) and all(isinstance(error, str) for error in errors),
        "malformed measurement errors",
    )
    mode = value["detection_mode"]
    B.require(
        mode in {None, "complete_trace", "certified_prefix"}, "unknown detection mode"
    )
    result = {
        "status": status(value["status"]),
        "detection_mode": mode,
        "returncode": number(value["returncode"], integer=True, negative=True),
        "seconds": number(value["seconds"]),
        "first_diagnostic_seconds": number(
            value["time_to_detection_seconds"], nullable=True
        ),
        "peak_rss_kib": number(usage.get("max_rss_kib"), nullable=True),
        "user_seconds": number(usage.get("user_seconds"), nullable=True),
        "system_seconds": number(usage.get("system_seconds"), nullable=True),
        "executed_instructions": number(
            value["executed_instructions"], integer=True, nullable=True
        ),
        "measurement_error_count": len(errors),
        "measurement_errors_sha256": B.study.canonical(errors),
        "command_sha256": B.study.canonical(value["command"]),
        "stdout_sha256": sha_value(value["stdout_sha256"]),
        "stderr_sha256": sha_value(value["stderr_sha256"]),
        "resources_sha256": sha_value(value["resources_sha256"])
        if value["resources_sha256"] is not None
        else None,
        "diagnostics_sha256": sha_value(value["diagnostics_sha256"]),
        "expressions": observation(value["expressions"], expected_counts),
    }
    for key in (
        "timed_out",
        "detected",
        "graph_accepted",
        "enabled",
        "false_positive",
        "unsafe_acceptance",
    ):
        result[key] = boolean(value[key])
    prefix = value["prefix_counts"]
    B.require(prefix is None or len(prefix) == 3, "malformed prefix counters")
    result["prefix_counts"] = (
        [number(x, integer=True) for x in prefix] if prefix is not None else None
    )
    export = value["export"]
    result["export"] = (
        {
            **retention(export, expected_counts),
            "duplicate_removed": boolean(export["duplicate_removed"]),
        }
        if export is not None
        else None
    )
    config = value["launch_configuration"]
    result["launch_configuration_sha256"] = (
        sha_value(config["sha256"]) if config is not None else None
    )
    return result


def build(value):
    B.require(
        value["schema_version"] == 1
        and value["trust"] == "caller_attested"
        and value["source_clean"] is True,
        "missing caller-attested build contract",
    )
    B.require(
        value["profile"] == "release"
        and value["features"] == []
        and value["default_features"] is True
        and value["command"] == ["cargo", "build", "--release", "-p", "volta_cli"],
        "build profile differs",
    )
    result = {
        "revision": commit(value["revision"]),
        "binary_sha256": sha_value(value["binary_sha256"]),
        "build_record_sha256": sha_value(value["build_record_sha256"]),
        "trust": "caller_attested",
        "source_clean": True,
        "profile": "release",
        "features": [],
        "default_features": True,
    }
    fingerprint = value["rust_workspace_fingerprint"]
    B.require(
        fingerprint["algorithm"] == "sha256-git-tree-v1",
        "unknown workspace fingerprint",
    )
    result["rust_workspace_fingerprint"] = {
        "algorithm": "sha256-git-tree-v1",
        "sha256": sha_value(fingerprint["sha256"]),
        "file_count": number(fingerprint["file_count"], integer=True),
    }
    for tool in ("rustc", "cargo"):
        B.require(
            re.fullmatch(
                tool
                + r" \d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)? \([0-9a-f]+ \d{4}-\d{2}-\d{2}\)",
                value[tool],
            ),
            "unexpected compiler version format",
        )
        result[tool] = value[tool]
    return result


def pin(report, relative, expected):
    values = [
        digest
        for path, digest in report["input_sha256"].items()
        if Path(path).as_posix().endswith("/" + relative)
    ]
    B.require(
        values and all(digest == expected for digest in values),
        "report source pin differs: " + relative,
    )


def check_sources(reports, document):
    shared = [
        B.HERE / name
        for name in (
            "study.py",
            "cases.json",
            "benchmark.py",
            "test_benchmark.py",
            "test_study.py",
            "protocol.md",
            "results/baseline-20261031.json",
        )
    ]
    shared += [
        Path(B.corpus.__file__),
        Path(B.corpus.harness.__file__),
        Path(B.study.build_records.__file__),
        Path(B.statistics.__file__),
    ]
    held = [
        B.HERE / name
        for name in ("heldout.py", "test_heldout.py", "heldout-protocol.md")
    ]
    for name, report in reports.items():
        if name == "baseline":
            continue  # Its original fixed report/source pins are separately checked.
        for path in shared + (held if name.startswith("heldout") else []):
            pin(report, path.relative_to(B.ROOT).as_posix(), B.sha(path))
        B.require(report["protocol"] == document["protocol"], "report protocol differs")
        for workload in document["workloads"]:
            for key in ("source", "assembly", "spec", "manifest", "launch_config"):
                if key in workload:
                    pin(report, workload[key], workload[key + "_sha256"])
    return [
        {"path": path.relative_to(B.ROOT).as_posix(), "sha256": B.sha(path)}
        for path in sorted(set(shared + held))
    ]


def check_new_coverage(rows, new, *, development):
    actual_misses = {
        row["case"]
        for row in rows
        if row["expectation"] == "hazard"
        and (
            row["baseline"]["status"]
            if development
            else row["variants"]["baseline"]["status"]
        )
        in MISSES
    }
    B.require(
        all(
            row["case"] in actual_misses
            and row["baseline_status"] in MISSES
            and row["baseline_ratio"] is None
            for row in new
        ),
        "new coverage includes an existing baseline detection",
    )


def check_links(reports, hashes, document):
    baseline, preflight, paired, qualification, heldout = (
        reports[key]
        for key in (
            "baseline",
            "development_preflight",
            "development_paired",
            "heldout_qualification",
            "heldout_paired",
        )
    )
    B.require(
        preflight["phase"] == "paired_functional_preflight"
        and paired["phase"] == "paired_development_measurement"
        and heldout["phase"] == "paired_heldout_measurement",
        "wrong collection phase",
    )
    identity = preflight["identity"]
    B.require(
        all(
            report["identity"] == identity
            for report in (paired, qualification, heldout)
        ),
        "mixed source/build identities",
    )
    B.require(
        preflight["baseline_report_sha256"] == hashes["baseline"] == B.BASELINE_SHA
        and paired["preflight_sha256"] == hashes["development_preflight"]
        and heldout["qualification_sha256"] == hashes["heldout_qualification"],
        "report chain hash differs",
    )
    B.require(
        preflight["timing_eligible"] == baseline["timing_eligible"],
        "development baseline eligibility differs",
    )
    B.require(
        hashes["development_preflight"] in qualification["input_sha256"].values(),
        "heldout qualification did not bind reviewed development preflight",
    )
    B.require(
        preflight["heldouts_executed"] == paired["heldouts_executed"] == 0
        and qualification["heldouts_executed"] == heldout["heldouts_executed"] == 6
        and qualification["development_cases_executed"]
        == heldout["development_cases_executed"]
        == 0,
        "collection scope differs",
    )
    B.require(
        identity["sources"]["common_parent"]
        == identity["sources"]["baseline_revision"]
        == B.COMMON_PARENT,
        "wrong common parent",
    )
    B.require(
        identity["builds"]["baseline"] == baseline["build_identity"],
        "baseline build differs",
    )
    mechanism = commit(identity["sources"]["candidate_revision"])
    H.validate_freeze(mechanism, identity)
    B.require(
        qualification["frozen_mechanism"] == heldout["frozen_mechanism"] == mechanism,
        "heldout mechanism differs",
    )
    dev_cases = B.development(document)
    workloads = {row["id"]: row for row in document["workloads"]}
    dev_rows = exact_rows(preflight["results"], [c["id"] for c in dev_cases])
    base_rows = exact_rows(baseline["results"], [c["id"] for c in dev_cases])
    for case in dev_cases:
        row = dev_rows[case["id"]]
        B.require(
            row["baseline"] == base_rows[case["id"]]
            and row["baseline_timing_eligible"]
            == (case["id"] in baseline["timing_eligible"])
            and row["expectation"] == case["expectation"]
            and row["category"] == case["category"],
            "development baseline/expectation drift",
        )
        B.require(
            row["family"] == workloads[case["workload"]]["family"],
            "development family differs from frozen manifest",
        )
    B.require(
        preflight["functional"]
        == B.functional_summary(
            preflight["results"], preflight["mathematical_controls"]
        ),
        "development functional summary differs",
    )
    B.require(
        paired["functional"] == preflight["functional"],
        "paired functional obligations differ",
    )
    held_rows = H.validate_qualification(qualification, document, identity, mechanism)
    B.require(
        heldout["functional"] == qualification["functional"],
        "heldout functional obligations differ",
    )
    for scope, rows in (
        ("development", list(dev_rows.values())),
        ("heldout", held_rows),
    ):
        new = (
            preflight["functional"]["new_coverage"]
            if scope == "development"
            else qualification["functional"]["new_coverage"]
        )
        check_new_coverage(rows, new, development=scope == "development")
    dev_selected = [
        case for case in dev_cases if case["id"] in baseline["timing_eligible"]
    ]
    expected = B.timing_summary(
        dev_selected, paired["samples"], preflight["functional"], document["protocol"]
    )
    B.require(
        paired["comparison"] == expected,
        "development arithmetic consistency check failed",
    )
    held_selected = [
        case
        for case in H.heldouts(document)
        if case["id"] in qualification["functional"]["baseline_timing_eligible"]
    ]
    calculated = B.timing_summary(
        held_selected,
        heldout["samples"],
        qualification["functional"],
        document["protocol"],
    )
    for key in (
        "baseline_fixed_cases",
        "successful_paired_comparisons",
        "failed_candidate_or_baseline_qualifiers",
        "cases",
        "correctness_gates_pass",
        "overhead_gates_pass",
    ):
        B.require(
            heldout["comparison"][key] == calculated[key],
            "heldout arithmetic consistency check failed",
        )
    B.require(
        heldout["comparison"]["heldout_retention_and_overhead_gates_pass"]
        == (calculated["correctness_gates_pass"] and calculated["overhead_gates_pass"])
        and heldout["comparison"]["development_family_adoption_gate_evaluated"]
        is False,
        "heldout gate scope differs",
    )
    return identity


def process_record(value):
    return {
        "returncode": number(value["returncode"], integer=True, negative=True),
        "timed_out": boolean(value["timed_out"]),
        "seconds": number(value["seconds"]),
        "command_sha256": B.study.canonical(value["command"]),
    }


def typed_witness(path, expected_sha, mode):
    raw = path.read_bytes()
    B.require(
        B.study.digest(raw) == sha_value(expected_sha),
        "witness stdout differs from bound sample",
    )
    text = raw.decode()
    B.require(mode in {"complete_trace", "certified_prefix"}, "unknown witness mode")
    matches = (
        B.study.WITNESS if mode == "certified_prefix" else B.study.ORDINARY_WITNESS
    ).findall(text)
    B.require(
        matches and all(left != right for _, _, left, right in matches),
        "detected role lacks typed distinct-event WriteWrite witness",
    )
    space, byte, earlier, later = matches[0]
    first = {
        "kind": "WriteWrite",
        "space": space,
        "lowest_overlap_byte": int(byte),
        "earlier_event": int(earlier),
        "later_event": int(later),
    }
    if mode == "certified_prefix":
        fields = re.findall(
            r"^  instruction=EventId\((\d+)\) issue=EventId\((\d+)\) wave=(\d+) earlier_thread=ThreadIx\((\d+)\) later_thread=ThreadIx\((\d+)\)$",
            text,
            re.M,
        )
        B.require(
            len(matches) == 1 and len(fields) == 1 and fields[0][3] != fields[0][4],
            "certified witness lacks unique instruction/issue/physical-thread evidence",
        )
        first.update(
            dict(
                zip(
                    (
                        "instruction_event",
                        "issue_event",
                        "wave",
                        "earlier_physical_thread",
                        "later_physical_thread",
                    ),
                    map(int, fields[0]),
                )
            )
        )
    return {"printed_write_write_witnesses": len(matches), "first": first}


def functional_sample(value, expected_counts):
    result = sample(value, expected_counts)
    if value["detected"]:
        result["write_write_evidence"] = typed_witness(
            Path(value["directory"]) / "stdout",
            value["stdout_sha256"],
            value["detection_mode"],
        )
    return result


def baseline_transcripts(report, directory):
    entries, frozen, stdout = [], {}, {}
    stages = [
        (row["case"], stage, row[stage])
        for row in report["results"]
        for stage in ("assemble", "analyze", "verify")
        if stage in row
    ]
    stages += [
        (row["id"], "wrong-spec", row["stage"])
        for row in report["mathematical_controls"]
    ]
    for case, stage, record in stages:
        entry = B.transcript_entry(directory, case, stage, record)
        entries.append(entry)
        for stream in ("stdout", "stderr"):
            frozen[str(directory / case / (stage + "." + stream))] = entry[
                stream + "_sha256"
            ]
        stdout[(case, stage)] = entry["stdout_sha256"]
    receipt = json.loads(B.RECEIPT.read_text())
    B.require(
        B.study.canonical(entries) == receipt["transcript_inventory_sha256"],
        "baseline transcript inventory differs",
    )
    return frozen, stdout


def bind_detected_stdout(reports, frozen):
    for name in ("development_preflight", "heldout_qualification"):
        for row in reports[name]["results"]:
            samples = list(row["variants"].values()) + list(
                row["specifications"].values()
            )
            if "baseline_export_control" in row:
                samples.append(row["baseline_export_control"])
            for value in samples:
                if value["detected"] and "directory" in value:
                    path = Path(value["directory"]) / "stdout"
                    B.require(
                        B.sha(path) == value["stdout_sha256"],
                        "functional witness input changed",
                    )
                    frozen[str(path)] = value["stdout_sha256"]


def reference(value, expected_counts):
    return retention(value, expected_counts)


def functional_row(row, case, *, baseline_directory=None, baseline_stdout=None):
    counts = {name: len(indices) for name, indices in case["output_indices"].items()}
    B.require(
        set(row["specifications"]) <= set(B.ROLES)
        and set(row["references"]) <= set(B.ROLES),
        "unknown proof/reference role",
    )
    result = {
        "id": case["id"],
        "workload": case["workload"],
        "target": case["target"],
        "category": case["category"],
        "expectation": case["expectation"],
        "primary_latency": boolean(case["primary_latency"]),
        "expected_outputs": number(case["expected_outputs"], integer=True),
        "expected_coordinates_sha256": B.study.canonical(case["output_indices"]),
        "baseline_timing_eligible": boolean(row["baseline_timing_eligible"]),
        "default_off_invariance": {
            "comparable": boolean(row["default_off_invariance"]["comparable"]),
            "passed": boolean(row["default_off_invariance"]["passed"], nullable=True),
        },
        "roles": {},
        "specifications": {
            role: functional_sample(value, counts)
            for role, value in row["specifications"].items()
        },
        "safe_references": {
            role: reference(value, counts) for role, value in row["references"].items()
        },
    }
    if baseline_directory is not None:
        value = row["baseline"]
        result["roles"]["baseline"] = {
            "status": status(value["status"]),
            "detected": boolean(value["detected"]),
            "process": process_record(value["analyze"]),
            "stdout_sha256": B.sha(baseline_directory / case["id"] / "analyze.stdout"),
            "stderr_sha256": B.sha(baseline_directory / case["id"] / "analyze.stderr"),
            "specification_status": status(value["specification"]["status"])
            if "specification" in value
            else None,
        }
        if value["detected"]:
            result["roles"]["baseline"]["write_write_evidence"] = typed_witness(
                baseline_directory / case["id"] / "analyze.stdout",
                baseline_stdout[(case["id"], "analyze")],
                "complete_trace",
            )
        result["baseline_export_control"] = (
            functional_sample(row["baseline_export_control"], counts)
            if "directory" in row["baseline_export_control"]
            else {
                "status": status(row["baseline_export_control"]["status"]),
                "diagnostics_sha256": sha_value(
                    row["baseline_export_control"]["diagnostics_sha256"]
                ),
                "executed_instructions": number(
                    row["baseline_export_control"]["executed_instructions"],
                    integer=True,
                    nullable=True,
                ),
                "expressions": observation(
                    row["baseline_export_control"]["expressions"], counts
                ),
            }
        )
        if "verify" in value:
            result["baseline_specification_process"] = process_record(value["verify"])
            result["baseline_specification_stdout_sha256"] = B.sha(
                baseline_directory / case["id"] / "verify.stdout"
            )
            result["baseline_specification_stderr_sha256"] = B.sha(
                baseline_directory / case["id"] / "verify.stderr"
            )
        result["assemble"] = process_record(value["assemble"])
    elif "assemble" in row:
        result["assemble"] = process_record(row["assemble"])
    for role, value in row["variants"].items():
        B.require(role in B.ROLES, "unknown role")
        result["roles"][role] = (
            functional_sample(value, counts)
            if "directory" in value
            else {
                "status": status(value["status"]),
                "detected": boolean(value["detected"]),
            }
        )
    return result


def metric(value):
    result = {
        "repeats": number(value["repeats"], integer=True),
        "detected_repeats": number(value["detected_repeats"], integer=True),
        "timeouts": number(value["timeouts"], integer=True),
        "measurement_errors": number(value["measurement_errors"], integer=True),
        "statuses": {
            status(key): number(count, integer=True)
            for key, count in value["statuses"].items()
        },
    }
    for key in (
        "process_median_seconds",
        "process_p95_seconds",
        "detection_median_seconds",
        "detection_p95_seconds",
        "max_rss_kib",
    ):
        result[key] = number(value[key], nullable=key.startswith("detection_"))
    return result


def interval(value):
    if value is None:
        return None
    return {
        key: number(value[key], integer=key in {"resamples", "paired_observations"})
        for key in ("lower", "upper", "resamples", "paired_observations", "level")
    }


def comparison(value):
    rows = []
    for row in value["cases"]:
        rows.append(
            {
                "id": row["case"],
                "baseline_eligible": boolean(row["baseline_eligible"]),
                "all_samples_qualified": boolean(row["all_samples_qualified"]),
                "primary": boolean(row["primary"]),
                "metrics": {
                    role: metric(data) for role, data in row["metrics"].items()
                },
                "overhead_gates": {
                    key: boolean(passed)
                    for key, passed in row["overhead_gates"].items()
                }
                if row["overhead_gates"] is not None
                else None,
                "median_ratio_interval": interval(row["median_ratio_interval"]),
            }
        )
    return {
        "baseline_fixed_cases": number(value["baseline_fixed_cases"], integer=True),
        "successful_paired_comparisons": number(
            value["successful_paired_comparisons"], integer=True
        ),
        "failed_candidate_or_baseline_qualifiers": list(
            value["failed_candidate_or_baseline_qualifiers"]
        ),
        "correctness_gates_pass": boolean(value["correctness_gates_pass"]),
        "overhead_gates_pass": boolean(value["overhead_gates_pass"]),
        "cases": rows,
    }


def paired_samples(value, cases):
    result = []
    for case in cases:
        counts = {
            name: len(indices) for name, indices in case["output_indices"].items()
        }
        roles = {}
        for role in ("baseline", "candidate"):
            selected = sorted(
                (
                    s
                    for s in value["samples"]
                    if s["case"] == case["id"] and s["role"] == role
                ),
                key=lambda s: s["repeat"],
            )
            B.require(
                [row["repeat"] for row in selected] == list(range(32)),
                "missing or duplicate first/repeated observations",
            )
            roles[role] = [
                {"repeat": row["repeat"], **sample(row, counts)} for row in selected
            ]
        result.append({"id": case["id"], "roles": roles})
    return result


def functional_summary(value):
    result = {}
    for key in (
        "correctness_gates_pass",
        "baseline_qualifications_retained",
        "default_off_invariance",
        "safe_enabled_output_invariance",
        "no_false_outcomes",
        "process_contracts_valid",
    ):
        result[key] = boolean(value[key])
    for key in (
        "mathematical_controls",
        "all_complete_modules_assembled",
        "development_family_adoption_gate_evaluated",
    ):
        if key in value:
            result[key] = boolean(value[key])
    result["counts"] = {}
    for role, counts in value["counts"].items():
        B.require(role in B.ROLES, "unknown role")
        result["counts"][role] = {
            key: (
                {
                    status(label): number(count, integer=True)
                    for label, count in count_value.items()
                }
                if key == "statuses"
                else number(count_value, integer=True)
            )
            for key, count_value in counts.items()
            if key
            in {
                "statuses",
                "safe_graphs",
                "safe_complete_proofs",
                "core_detections",
                "tail_detections",
                "hazards_detected",
            }
        }
    result["new_coverage"] = [
        {
            "id": row["case"],
            "baseline_status": status(row["baseline_status"]),
            "candidate_status": status(row["candidate_status"]),
            "observed_certified_seconds": number(
                row["observed_certified_seconds"], nullable=True
            ),
            "baseline_ratio": None,
        }
        for row in value["new_coverage"]
    ]
    # Family strings below are verified separately against the frozen manifest.
    for key in (
        "new_coverage_families",
        "new_complex_coverage_families",
        "certified_families",
        "certified_complex_families",
    ):
        if key in value:
            result[key] = list(value[key])
    return result


def primary_outcomes(cases, rows, comparisons):
    primaries = [case for case in cases if case["primary_latency"]]
    B.require(
        {case["id"] for case in primaries} == B.study.PRIMARIES,
        "four frozen primaries changed",
    )
    observed = {row["case"]: row for row in rows}
    measured = {row["case"]: row for row in comparisons["cases"]}
    return [
        {
            "id": case["id"],
            "baseline_timing_eligible": boolean(
                observed[case["id"]]["baseline_timing_eligible"]
            ),
            "baseline_status": status(observed[case["id"]]["baseline"]["status"]),
            "candidate_status": status(
                observed[case["id"]]["variants"]["candidate"]["status"]
            ),
            "has_baseline_ratio": case["id"] in measured
            and measured[case["id"]]["median_ratio_interval"] is not None,
        }
        for case in primaries
    ]


def public_document(
    reports,
    hashes,
    document,
    identity,
    harness,
    baseline_path,
    baseline_stdout,
    audit_sha=None,
):
    preflight, paired, qualification, heldout = (
        reports[key]
        for key in (
            "development_preflight",
            "development_paired",
            "heldout_qualification",
            "heldout_paired",
        )
    )
    workloads = []
    for value in document["workloads"]:
        row = {
            key: value[key]
            for key in (
                "id",
                "family",
                "target",
                "kernel",
                "origin",
                "origin_id",
                "expected_outputs",
                "manifest_row_sha256",
            )
        }
        for key in ("source", "assembly", "spec", "manifest", "launch_config"):
            if key in value:
                row[key] = {
                    "path": value[key],
                    "sha256": sha_value(value[key + "_sha256"]),
                }
        workloads.append(row)
    dev_cases, held_cases = B.development(document), H.heldouts(document)
    known = {case["id"]: case for case in dev_cases + held_cases}
    families = {row["family"] for row in document["workloads"]}
    for raw in (preflight["functional"], qualification["functional"]):
        for key in (
            "new_coverage_families",
            "new_complex_coverage_families",
            "certified_families",
            "certified_complex_families",
        ):
            B.require(set(raw.get(key, [])) <= families, "unknown public family")
    selected = [
        case for case in dev_cases if case["id"] in preflight["timing_eligible"]
    ]
    held_selected = [
        case
        for case in held_cases
        if case["id"] in qualification["functional"]["baseline_timing_eligible"]
    ]
    math_controls = []
    for row in reports["baseline"]["mathematical_controls"]:
        control = next(
            c for c in document["mathematical_controls"] if c["id"] == row["id"]
        )
        directory = baseline_path.parent / row["id"]
        math_controls.append(
            {
                "id": row["id"],
                "role": "baseline",
                "expected_mismatches": control["expected_mismatches"],
                "spec_sha256": sha_value(control["spec_sha256"]),
                "status": status(row["classification"]["status"]),
                "process": process_record(row["stage"]),
                "stdout_sha256": B.sha(directory / "wrong-spec.stdout"),
                "stderr_sha256": B.sha(directory / "wrong-spec.stderr"),
            }
        )
    for row in preflight["mathematical_controls"]:
        control = next(
            c for c in document["mathematical_controls"] if c["id"] == row["case"]
        )
        B.require(row["role"] in B.ROLES[1:], "unknown math-control role")
        case = next(
            c
            for c in dev_cases
            if c["workload"] == control["workload"] and c["expectation"] == "safe"
        )
        math_controls.append(
            {
                "id": row["case"],
                "role": row["role"],
                "expected_mismatches": control["expected_mismatches"],
                "spec_sha256": sha_value(control["spec_sha256"]),
                "result": sample(
                    row["result"],
                    {
                        name: len(indices)
                        for name, indices in case["output_indices"].items()
                    },
                ),
            }
        )
    result = {
        "schema_version": 1,
        "scope": "Frozen source-bound development and heldout configurations; no GPU execution. Counts are configurations, not distinct application bug sites. Synthetic tails are separate backend stressors.",
        "identity": {
            "common_parent": commit(identity["sources"]["common_parent"]),
            "source_diff_sha256": sha_value(identity["sources"]["source_diff_sha256"]),
            "baseline": build(identity["builds"]["baseline"]),
            "candidate": build(identity["builds"]["candidate"]),
            "manifest_sha256": B.MANIFEST_SHA,
            "raw_reports_sha256": {
                name: sha_value(value) for name, value in hashes.items()
            },
            "harness_sources": harness,
            "publication_tool": {
                "path": Path(__file__).relative_to(B.ROOT).as_posix(),
                "sha256": B.sha(Path(__file__)),
            },
            "independent_audit_sha256": sha_value(audit_sha)
            if audit_sha is not None
            else None,
            "trust": "Build source/binary association is caller-attested. Recomputed summaries are consistency checks using the original helper, not an independent arithmetic audit.",
        },
        "protocol": {
            "repeats": 31,
            "first_sample_separate": True,
            "seed": 20261031,
            "timeout_seconds_per_stage": 60,
            "safe_overhead_limits": document["protocol"]["safe_overhead_limits"],
            "max_rss_population": "maximum over first process plus 31 repeated processes; median/p95 timing excludes first",
            "statistical_ratios": "Only successful baseline-qualified pairs. Candidate failures remain failed qualifiers; new coverage has no baseline ratio.",
            "witness_counts": "printed_write_write_witnesses counts exact typed matches in bound stdout; CLI rendering may cap them. It is not a total conflict or bug count.",
            "safe_export_policy": "Every timed safe export has complete unique coordinates and exact expression/reference hashes. Remove only validated exact duplicates; retain all logs/digests and unmatched artifacts.",
        },
        "workloads": workloads,
        "development": {
            "configurations": 40,
            "safe_denominator": 18,
            "core_hazard_denominator": 20,
            "synthetic_tail_denominator": 2,
            "baseline_fixed_timing_cases": 28,
            "functional": functional_summary(preflight["functional"]),
            "cases": [
                functional_row(
                    row,
                    known[row["case"]],
                    baseline_directory=baseline_path.parent,
                    baseline_stdout=baseline_stdout,
                )
                for row in preflight["results"]
            ],
            "mathematical_controls": math_controls,
            "comparison": comparison(paired["comparison"]),
            "adoption_gates_pass": boolean(paired["comparison"]["adoption_gates_pass"]),
            "additional_coverage_gate_pass": boolean(
                paired["comparison"]["additional_coverage_gate_pass"]
            ),
            "primary_outcomes": primary_outcomes(
                dev_cases, preflight["results"], paired["comparison"]
            ),
            "samples": paired_samples(paired, selected),
        },
        "heldout": {
            "configurations": 6,
            "safe_denominator": 3,
            "hazard_denominator": 3,
            "functional": functional_summary(qualification["functional"]),
            "cases": [
                functional_row(row, known[row["case"]])
                for row in qualification["results"]
            ],
            "comparison": comparison(heldout["comparison"]),
            "retention_and_overhead_gates_pass": boolean(
                heldout["comparison"]["heldout_retention_and_overhead_gates_pass"]
            ),
            "development_family_adoption_gate_evaluated": False,
            "samples": paired_samples(heldout, held_selected),
        },
    }
    return result


def write_fresh(output, value, frozen):
    output = output.resolve()
    B.require(
        not output.exists() and str(output) not in frozen,
        "public output exists or aliases an input",
    )
    B.require(
        not output.is_relative_to(B.ROOT),
        "render outside the repository for review before copying",
    )
    B.unchanged(frozen)
    data = (
        json.dumps(value, ensure_ascii=True, allow_nan=False, separators=(",", ":"))
        + "\n"
    )
    B.unchanged(frozen)
    with output.open("x") as stream:
        stream.write(data)
    return B.sha(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-report", type=Path, required=True)
    for name in (
        "development-preflight",
        "development-paired",
        "heldout-qualification",
        "heldout-paired",
    ):
        parser.add_argument("--" + name, type=Path, required=True)
        parser.add_argument("--" + name + "-sha256", required=True)
    parser.add_argument("--independent-audit", type=Path)
    parser.add_argument("--independent-audit-sha256")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        document = B.study.load_cases()
        paths = {
            name: getattr(args, name).resolve(strict=True)
            for name in (
                "baseline_report",
                "development_preflight",
                "development_paired",
                "heldout_qualification",
                "heldout_paired",
            )
        }
        paths["baseline"] = paths.pop("baseline_report")
        hashes = {name: B.sha(path) for name, path in paths.items()}
        B.require(hashes["baseline"] == B.BASELINE_SHA, "wrong frozen baseline report")
        for name in paths.keys() - {"baseline"}:
            B.require(
                hashes[name] == sha_value(getattr(args, name + "_sha256")),
                "raw report differs from reviewed digest",
            )
        frozen = B.snapshots(
            list(paths.values()) + [Path(__file__), HERE / "test_publish_results.py"]
        )
        audit_sha = None
        B.require(
            bool(args.independent_audit) == bool(args.independent_audit_sha256),
            "audit needs both file and explicit reviewed hash",
        )
        if args.independent_audit:
            audit_sha = B.sha(args.independent_audit.resolve(strict=True))
            B.require(
                audit_sha == sha_value(args.independent_audit_sha256),
                "independent-audit digest differs",
            )
            frozen[str(args.independent_audit.resolve())] = audit_sha
        reports = {name: json.loads(path.read_text()) for name, path in paths.items()}
        B.baseline_report(paths["baseline"], document)
        transcripts, baseline_stdout = baseline_transcripts(
            reports["baseline"], paths["baseline"].parent
        )
        frozen.update(transcripts)
        bind_detected_stdout(reports, frozen)
        identity = check_links(reports, hashes, document)
        harness = check_sources(reports, document)
        for row in harness:
            frozen[str(B.ROOT / row["path"])] = row["sha256"]
        for workload in document["workloads"]:
            for key in ("source", "assembly", "spec", "manifest", "launch_config"):
                if key in workload:
                    frozen[str(B.ROOT / workload[key])] = workload[key + "_sha256"]
        output = public_document(
            reports,
            hashes,
            document,
            identity,
            harness,
            paths["baseline"],
            baseline_stdout,
            audit_sha,
        )
        print(
            json.dumps(
                {
                    "output_sha256": write_fresh(args.output, output, frozen),
                    "development": 40,
                    "heldout": 6,
                    "collection_processes_executed": 0,
                },
                indent=2,
            )
        )
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        StopIteration,
        subprocess.SubprocessError,
    ) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
