#!/usr/bin/env python3
"""Publish sanitized phase observations from an audited attribution campaign.

Example: python3 publish_prefix_attribution.py --plan plan.json --report report.json \
  --patch instrumentation.patch --selection selection.json --protocol protocol.md \
  --audit independent-audit.json \
  --output-dir public-results
"""

import argparse
from collections import Counter
import csv
import hashlib
import io
import json
from pathlib import Path
import re
import statistics

PHASES = [
    "discovery",
    "live_prefix_validation",
    "final_prefix_validation",
    "final_ordinary_graph",
    "remaining_execution_output",
]
BASE = "f0ee44285286aa1ea92f3e99aed6574ad89f3c82"
SOURCE = "4be3a57f7493271d635f9e9399dd1998c1c4ce49"
CURRENT = "57d555dbafee093f804b2c0744c477c4a5e567726aece81017f828647bdbc167"
BINARY = "d58991cdb7d41ec42744068caacb2e65a6e0559c27e675c0b3895585029ed45e"


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def hfile(path):
    return sha(Path(path).read_bytes())


def read(path):
    return json.loads(Path(path).read_text())


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(",", ":")).encode())


def relative(path):
    require(
        isinstance(path, str)
        and not Path(path).is_absolute()
        and ".." not in Path(path).parts,
        "expected a public repository-relative path",
    )
    return path


def repository_path(path):
    parts = Path(path).parts
    for anchor in ["crates", "tests", "ai_compiler_kernels"]:
        if anchor in parts:
            return relative("/".join(parts[parts.index(anchor) :]))
    return None


def build(value):
    require(
        value["trust"] == "caller_attested"
        and value["source_clean"] is True
        and value["profile"] == "release"
        and value["features"] == []
        and value["default_features"] is True,
        "unexpected build profile",
    )
    for tool in ["cargo", "rustc"]:
        require(
            re.fullmatch(
                tool + r" \d+\.\d+\.\d+ \([0-9a-f]+ \d{4}-\d{2}-\d{2}\)", value[tool]
            ),
            "tool version is not a plain public compiler identifier",
        )
    return {
        key: value[key]
        for key in [
            "revision",
            "trust",
            "source_clean",
            "profile",
            "features",
            "default_features",
            "binary_sha256",
            "rust_workspace_fingerprint",
            "cargo",
            "rustc",
            "build_record_sha256",
        ]
    }


def witness(stdout):
    rows = re.findall(
        r"^  kernel: MemoryConflict \{ kind: (\w+), location: ByteLocation \{ space: (\w+), addr: (\d+) \}, earlier: EventId\((\d+)\), later: EventId\((\d+)\) \}$",
        stdout,
        re.M,
    )
    return [
        {
            "kind": k,
            "space": s,
            "byte_address": int(a),
            "earlier_event": int(x),
            "later_event": int(y),
        }
        for k, s, a, x, y in rows
    ]


def distribution(values):
    require(len(values) == 5, "distribution requires all five fixed samples")
    return {"min": min(values), "median": statistics.median(values), "max": max(values)}


def project(args):
    plan, report, selected = read(args.plan), read(args.report), read(args.selection)
    audit = read(args.audit)
    require(
        audit["pass"] is True
        and not audit["errors"]
        and audit["checks"] > 0
        and audit["report_sha256"] == hfile(args.report)
        and audit["plan_sha256"] == hfile(args.plan),
        "independent raw audit does not bind these exact artifacts",
    )
    require(
        plan["source_parent"] == BASE and plan["instrumented_revision"] == SOURCE,
        "wrong instrumentation source",
    )
    require(
        report["reviewed_plan_sha256"] == hfile(args.plan),
        "report/plan binding differs",
    )
    require(
        plan["selection"] == selected
        and plan["selection_sha256"] == hfile(args.selection)
        and plan["protocol_sha256"] == hfile(args.protocol)
        and plan["instrumentation_patch_sha256"] == hfile(args.patch),
        "selection/protocol/patch changed",
    )
    require(
        selected["repeats"] == 5
        and selected["timeout_seconds"] == 60
        and selected["seed"] == 20261031,
        "fixed sample budget changed",
    )
    require(
        plan["builds"]["current_on"]["binary_sha256"] == CURRENT
        and plan["builds"]["instrumented"]["binary_sha256"] == BINARY,
        "frozen executable identity changed",
    )
    require(
        hfile(plan["binaries"]["current_on"]) == CURRENT
        and hfile(plan["binaries"]["instrumented"]) == BINARY,
        "actual frozen executable changed",
    )
    case_ids = sum(
        [selected[k] for k in ["late_hazards", "early_primaries", "safe_controls"]], []
    )
    require(
        len(case_ids) == len(set(case_ids)) == 26 and len(selected["gate_cases"]) == 5,
        "changed fixed population",
    )
    rows = {r["case"]["id"]: r for r in plan["cases"]}
    samples = report["samples"]
    require(
        set(rows) == set(case_ids) and len(rows) == 26 and len(samples) == 130,
        "missing or extra case/observation",
    )
    require(
        Counter((s["case"], s["repeat"]) for s in samples)
        == Counter((c, r) for c in case_ids for r in range(1, 6)),
        "duplicate or changed observation identity",
    )
    observations, cases, table = [], [], []
    for sample in samples:
        case_id, repeat = sample["case"], sample["repeat"]
        original = rows[case_id]
        process, measured = sample["process"], sample["phases"]
        require(
            measured["schema_version"] == 1
            and measured["valid"] is True
            and set(measured["phases"]) == set(PHASES),
            "invalid phase observation",
        )
        require(
            sum(p["exclusive_ns"] for p in measured["phases"].values())
            == measured["root_ns"],
            "exclusive phase sum differs from pipeline span",
        )
        for phase in measured["phases"].values():
            require(
                set(phase) == {"exclusive_ns", "calls"}
                and all(type(v) is int and v >= 0 for v in phase.values()),
                "phase observation is not exact nonnegative integer data",
            )
        root = Path(process["directory"])
        for name, key in [
            ("stdout", "stdout_sha256"),
            ("stderr", "stderr_sha256"),
            ("resources.txt", "resources_sha256"),
        ]:
            require(
                hfile(root / name) == process[key],
                "raw transcript/resource bytes changed",
            )
        require(
            read(root / "phases.json") == measured,
            "raw metrics differ from recorded observations",
        )
        exports = process["expressions"]
        if exports is not None:
            require(
                set(exports)
                == {"sha256", "bytes", "coordinates_sha256", "output_counts"}
                and all(
                    re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", k)
                    and type(v) is int
                    and v >= 0
                    for k, v in exports["output_counts"].items()
                ),
                "unexpected complete-export metadata",
            )
            require(
                process["export"]["validated_complete"] is True
                and process["export"]["duplicate_removed"] is False,
                "full safe export is not retained",
            )
            require(
                (root / "outputs.vexpr").stat().st_size == exports["bytes"],
                "full safe export size changed",
            )
        expected = original["expected"]
        functional = {
            key: process[key]
            for key in [
                "status",
                "returncode",
                "detected",
                "detection_mode",
                "graph_accepted",
                "executed_instructions",
                "prefix_counts",
                "diagnostics_sha256",
                "expressions",
            ]
        }
        require(
            all(functional[k] == expected[k] for k in functional),
            "archived current-ON functional outcome changed",
        )
        actual_witness = witness((root / "stdout").read_text())
        expected_witness = [
            {
                "kind": "WriteWrite",
                "space": s,
                "byte_address": int(a),
                "earlier_event": int(x),
                "later_event": int(y),
            }
            for s, a, x, y in expected["first_typed_witness"]
        ]
        require(actual_witness == expected_witness, "exact first typed witness changed")
        require(
            not sample["attribution_errors"] and not process["measurement_errors"],
            "publication contains invalid observations",
        )
        observations.append(
            {
                "case": case_id,
                "repeat": repeat,
                "parent_endpoint_kind": "certified_marker_reception"
                if original["case"]["expectation"] == "hazard"
                else "process_completion",
                "parent_wall_endpoint_ns": sample["parent_prediagnostic_wall_ns"],
                "unassigned_parent_remainder_ns": sample[
                    "unassigned_parent_remainder_ns"
                ],
                "pipeline_span_ns": measured["root_ns"],
                "phases": measured["phases"],
                "safe_complete_equation_previously_proved": sample[
                    "safe_complete_equation_previously_proved"
                ],
                "process": {
                    key: process[key]
                    for key in [
                        "status",
                        "returncode",
                        "timed_out",
                        "seconds",
                        "detected",
                        "detection_mode",
                        "graph_accepted",
                        "enabled",
                        "false_positive",
                        "unsafe_acceptance",
                        "executed_instructions",
                        "prefix_counts",
                        "diagnostics_sha256",
                        "stdout_sha256",
                        "stderr_sha256",
                        "resources_sha256",
                    ]
                },
                "whole_process_resources": {
                    key: process["usage"][key]
                    for key in ["max_rss_kib", "user_seconds", "system_seconds"]
                },
                "complete_expression_export": exports,
                "typed_memory_conflicts": actual_witness,
                "phase_record_sha256": hfile(root / "phases.json"),
                "raw_sample_record_sha256": canonical(sample),
                "command_sha256": canonical(process["command"]),
                "launch_configuration_sha256": process["launch_configuration"]["sha256"]
                if process["launch_configuration"]
                else None,
                "attribution_error_count": len(sample["attribution_errors"]),
                "measurement_error_count": len(process["measurement_errors"]),
            }
        )
    for case_id in case_ids:
        entry = rows[case_id]
        case = entry["case"]
        observed = [s for s in observations if s["case"] == case_id]
        phases = {}
        for phase in PHASES:
            phases[phase] = {
                "exclusive_ns": distribution(
                    [s["phases"][phase]["exclusive_ns"] for s in observed]
                ),
                "calls": distribution([s["phases"][phase]["calls"] for s in observed]),
                "parent_wall_share": distribution(
                    [
                        s["phases"][phase]["exclusive_ns"]
                        / s["parent_wall_endpoint_ns"]
                        for s in observed
                    ]
                ),
                "pipeline_share": distribution(
                    [
                        s["phases"][phase]["exclusive_ns"] / s["pipeline_span_ns"]
                        for s in observed
                    ]
                ),
            }
            table.append(
                {
                    "case": case_id,
                    "expectation": case["expectation"],
                    "phase": phase,
                    **{
                        key + "_" + stat: value
                        for key, d in phases[phase].items()
                        for stat, value in d.items()
                    },
                }
            )
        final = phases["final_prefix_validation"]
        gate = bool(
            case_id in selected["gate_cases"]
            and final["exclusive_ns"]["median"] >= 1000000
            and final["parent_wall_share"]["median"] >= 0.15
        )
        summary = next(r for r in report["summary"]["cases"] if r["case"] == case_id)
        require(
            summary["all_five_valid"] is True
            and summary["meets_cost_gate"] == gate
            and summary["median_final_prefix_validation_ns"]
            == final["exclusive_ns"]["median"]
            and summary["median_per_sample_final_share"]
            == final["parent_wall_share"]["median"],
            "published arithmetic differs from raw fixed-gate summary",
        )
        contract = {
            k: case[k]
            for k in [
                "id",
                "workload",
                "kernel",
                "target",
                "expectation",
                "category",
                "expected_outputs",
                "materialized_assembly_sha256",
            ]
        }
        for key in ["source", "assembly", "spec"]:
            contract[key] = {
                "path": relative(case[key]),
                "sha256": case[key + "_sha256"],
            }
        contract.update(
            {
                k: case[k]
                for k in [
                    "block",
                    "grid",
                    "workgroup",
                    "dimensions",
                    "dtype",
                    "layout",
                    "launch_config",
                    "source_revision",
                ]
                if k in case
            }
        )
        contract["arrays_sha256"] = canonical(case.get("arrays"))
        contract["params_sha256"] = canonical(case.get("params"))
        contract["output_coordinate_counts"] = {
            k: len(v) for k, v in case["output_indices"].items()
        }
        contract["output_coordinates_sha256"] = canonical(case["output_indices"])
        cases.append(
            {
                "case": contract,
                "archived_functional_reference_sha256": canonical(entry["expected"]),
                "safe_complete_equation_previously_proved": entry[
                    "safe_complete_equation_previously_proved"
                ],
                "parent_endpoint_kind": observed[0]["parent_endpoint_kind"],
                "parent_wall_endpoint_ns": distribution(
                    [s["parent_wall_endpoint_ns"] for s in observed]
                ),
                "pipeline_span_ns": distribution(
                    [s["pipeline_span_ns"] for s in observed]
                ),
                "unassigned_parent_remainder_ns": distribution(
                    [s["unassigned_parent_remainder_ns"] for s in observed]
                ),
                "phase_distributions": phases,
                "gate_case": case_id in selected["gate_cases"],
                "meets_cost_gate": gate,
            }
        )
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=list(table[0]))
    writer.writeheader()
    writer.writerows(table)
    csv_data = stream.getvalue().encode()
    qualify = sum(c["meets_cost_gate"] for c in cases)
    require(
        qualify == report["summary"]["qualifying_gate_cases"] == 0
        and report["summary"]["gate_pass"] is False,
        "negative gate conclusion differs",
    )
    inputs = []
    for path, digest in plan["input_sha256"].items():
        row = {"input_identity_sha256": sha(path.encode()), "sha256": digest}
        if (public := repository_path(path)) is not None:
            row["repository_path"] = public
        inputs.append(row)
    resource_tools = [
        {"name": "GNU time", "sha256": digest}
        for path, digest in plan["input_sha256"].items()
        if Path(path).name == "time"
    ]
    require(len(resource_tools) == 1, "missing or ambiguous frozen resource tool")
    for path, digest in plan["input_sha256"].items():
        if Path(path).name == "time":
            require(hfile(path) == digest, "frozen resource tool changed")
    result = {
        "schema_version": 1,
        "study": "Existing-ON prefix replay phase attribution",
        "conclusion": "Fixed cost gate failed (0/5); suspension proposal rejected before implementation.",
        "scope": "One instrumented arm,26 fixed configurations and5 processes each; exclusive wall-clock phases, not phase CPU attribution, speedup or new mathematical proofs.",
        "identity": {
            "source_parent": BASE,
            "instrumented_revision": SOURCE,
            "raw_plan_sha256": hfile(args.plan),
            "raw_report_sha256": hfile(args.report),
            "patch_sha256": hfile(args.patch),
            "selection_sha256": hfile(args.selection),
            "protocol_sha256": hfile(args.protocol),
            "publisher_sha256": hfile(Path(__file__)),
            "builds": {k: build(v) for k, v in plan["builds"].items()},
            "resource_tools": resource_tools,
            "bound_inputs": inputs,
        },
        "selection": selected,
        "independent_raw_audit": {
            "sha256": hfile(args.audit),
            "checks": audit["checks"],
            "errors": 0,
            "auditor_script_sha256": audit["auditor_script_sha256"],
            "raw_process_digests_sha256": audit["raw_process_digests_sha256"],
            "raw_phase_files_sha256": audit["raw_phase_files_sha256"],
        },
        "summary": {
            "observations": 130,
            "configurations": 26,
            "retained_actual_safe_expression_bytes": sum(
                s["complete_expression_export"]["bytes"]
                for s in observations
                if s["complete_expression_export"]
            ),
            "retained_actual_safe_output_coordinates": sum(
                sum(s["complete_expression_export"]["output_counts"].values())
                for s in observations
                if s["complete_expression_export"]
            ),
            "process_outcomes": dict(
                Counter(s["process"]["status"] for s in observations)
            ),
            "attribution_error_count": sum(
                s["attribution_error_count"] for s in observations
            ),
            "gate_case_count": 5,
            "qualifying_gate_cases": qualify,
            "gate_pass": False,
            "previously_proved_safe_equation_configurations": sum(
                c["case"]["expectation"] == "safe"
                and c["safe_complete_equation_previously_proved"]
                for c in cases
            ),
            "previously_unproved_safe_equation_configurations": sum(
                c["case"]["expectation"] == "safe"
                and not c["safe_complete_equation_previously_proved"]
                for c in cases
            ),
        },
        "phase_distribution_csv_sha256": sha(csv_data),
        "cases": cases,
        "observations": observations,
        "limits": [
            "Build source/binary association remains caller-attested; hashes bind identity rather than prove a build.",
            "The recorded pipeline phase excludes startup, parsing, CLI output/export and recorder file-write work; that parent remainder stays unassigned.",
            "Instrumented observations cannot replace the earlier uninstrumented samples or establish phase CPU costs.",
            "Eleven safe-control equations were established earlier; two remain unproved. Profiling establishes no new complete equation.",
            "Raw expression payloads, full graphs, commands, private paths, host/device identities and diagnostic text are omitted. Complete export and transcript hashes/counts are retained.",
        ],
    }
    raw = json.dumps(result, indent=2) + "\n"
    require(
        not re.search(
            r'/tmp/|/home/|/opt/|/mnt/|"directory"|"command"|"wrapped_command"|"cwd"|hostname|device_id',
            raw,
            re.I,
        ),
        "unexpected private path/command/identity field",
    )
    out = args.output_dir
    lines = [
        "# Prefix replay attribution: negative result",
        "",
        "The fixed Stage A cost gate failed: **0 of 5 cases qualified**. The suspension proposal was rejected before production implementation; no retuning followed.",
        "",
        f"The instrumentation-only source is `{SOURCE}` on parent `{BASE}`. The immutable current-ON executable is `{CURRENT}`; the separate instrumented executable is `{BINARY}`.",
        "",
        "All 26 declared configurations ran exactly 5 times: 65 certified hazardous-prefix rejections and 65 safe graph analyses. All 130 phase records and archived outcome/first-witness/export comparisons were valid. The 13 safe controls retained complete exports; 11 had previously proved equations and 2 remain unproved. This collection creates no new mathematical proofs.",
        "",
        "A gate case needed both median final replay >=1ms and median per-observation final-replay share >=15% of parent marker-reception wall time. At least 3/5 cases had to qualify.",
        "",
        "| Fixed gate case | Median final replay (ns) | Median per-sample parent share | Qualifies |",
        "| --- | ---: | ---: | --- |",
    ]
    for c in cases:
        if c["gate_case"]:
            p = c["phase_distributions"]["final_prefix_validation"]
            lines.append(
                f"| `{c['case']['id']}` | {p['exclusive_ns']['median']} | {p['parent_wall_share']['median']} | no |"
            )
    lines += [
        "",
        "[All 130 observations and all 26 summaries](observations.json) retain full numeric precision. [All 130 case/phase distribution rows](phase-distributions.csv) give min/median/max exclusive nanoseconds, calls and per-observation shares over exactly 5 observations; these are descriptive distributions, not tail estimates.",
        "",
        "Hazard endpoints are parent-observed certified-marker reception; safe endpoints are full process completion including export. Phases are exclusive wall-clock observations. Startup, parsing, rendering/export and recorder-write work outside the pipeline span remain unassigned. No CPU attribution, speedup comparison, GPU result or replacement implementation is claimed.",
        "",
        f"Raw report SHA-256: `{hfile(args.report)}`. Plan SHA-256: `{hfile(args.plan)}`. Public observations SHA-256: `{sha(raw.encode())}`. Distribution CSV SHA-256: `{sha(csv_data)}`.",
        "",
        f"The [independent raw audit](independent-audit.json) passed {audit['checks']:,} checks with zero errors, verifying all 130 records, 5,654,460,115 retained safe-expression bytes and 125,400 coordinates. Its SHA-256 is `{hfile(args.audit)}`.",
        "",
        "Regenerate with the publisher and the exact bound raw plan/report/patch, selection and protocol. Independent raw/projection audit receipts are bound separately, avoiding a self-hash cycle. The earlier study remains unchanged.",
        "",
    ]
    artifacts = {
        "observations.json": raw.encode(),
        "phase-distributions.csv": csv_data,
        "README.md": "\n".join(lines).encode(),
        "independent-audit.json": args.audit.read_bytes(),
    }
    if args.check:
        require(
            all(
                (out / name).is_file() and (out / name).read_bytes() == data
                for name, data in artifacts.items()
            ),
            "stale or missing public projection",
        )
    else:
        require(not out.exists(), "output directory must be new")
        out.mkdir()
        for name, data in artifacts.items():
            (out / name).write_bytes(data)
    print(
        json.dumps(
            {
                "observations_sha256": hfile(out / "observations.json"),
                "csv_sha256": sha(csv_data),
                "readme_sha256": hfile(out / "README.md"),
                "observations": 130,
                "case_phase_rows": len(table),
                "qualifying": qualify,
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in [
        "plan",
        "report",
        "patch",
        "selection",
        "protocol",
        "audit",
        "output-dir",
    ]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Compare all public artifacts without writing",
    )
    project(parser.parse_args())
