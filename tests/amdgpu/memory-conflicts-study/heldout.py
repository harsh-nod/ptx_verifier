#!/usr/bin/env python3
"""Explicit frozen-mechanism collection for the six predeclared heldouts.

Implementation alone does not authorize execution. See heldout-protocol.md.
"""

from __future__ import annotations

import argparse
from collections import Counter
import importlib.util
import json
import os
from pathlib import Path
import random
import re
import subprocess

HERE = Path(__file__).resolve().parent
_SPEC = importlib.util.spec_from_file_location(
    "memory_paired_measurement", HERE / "benchmark.py"
)
B = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(B)


def heldouts(document):
    workloads = {row["id"]: row for row in document["workloads"]}
    selected = [
        B.study.expanded_case(workloads[c["workload"]], c)
        for c in document["cases"]
        if c["split"] == "heldout"
    ]
    B.require(
        len(selected) == 6 and {c["id"] for c in selected} == B.study.HELDOUTS,
        "heldout case set changed",
    )
    B.require(
        sum(c["expectation"] == "safe" for c in selected) == 3,
        "heldout expectation set changed",
    )
    return selected


def validate_freeze(mechanism, identity):
    B.require(
        re.fullmatch(r"[0-9a-f]{40}", mechanism) is not None,
        "frozen mechanism must be one exact full commit",
    )
    B.require(
        mechanism
        == identity["sources"]["candidate_revision"]
        == identity["builds"]["candidate"]["revision"],
        "frozen mechanism differs from candidate source/build",
    )


def setup(args):
    document, _, identity, frozen = B.common_setup(args)
    validate_freeze(args.frozen_mechanism, identity)
    path = args.development_preflight.resolve(strict=True)
    B.require(
        B.sha(path) == args.development_preflight_sha256,
        "development preflight differs from reviewed digest",
    )
    preflight = json.loads(path.read_text())
    B.require(
        preflight["phase"] == "paired_functional_preflight"
        and preflight["identity"] == identity
        and preflight["baseline_report_sha256"] == B.BASELINE_SHA
        and preflight["heldouts_executed"] == 0,
        "development preflight source/build/scope differs",
    )
    B.require(
        len(preflight["results"]) == 40
        and {row["case"] for row in preflight["results"]}
        == {case["id"] for case in B.development(document)},
        "development preflight case set differs",
    )
    B.require(
        preflight["functional"]
        == B.functional_summary(
            preflight["results"], preflight["mathematical_controls"]
        ),
        "development preflight outcome gates differ",
    )
    B.require(
        preflight["functional"]["correctness_gates_pass"],
        "development correctness must pass before heldouts",
    )
    B.unchanged(preflight["input_sha256"])
    frozen.update(preflight["input_sha256"])
    frozen[str(path)] = B.sha(path)
    frozen.update(
        B.snapshots(
            [Path(__file__), HERE / "test_heldout.py", HERE / "heldout-protocol.md"]
        )
    )
    return document, identity, frozen


def baseline_eligible(case, baseline, specification):
    if case["expectation"] == "hazard" and baseline["status"] != "ordinary_rejection":
        return False
    return B.qualified(case, baseline, specification=specification)


def summary(rows):
    """The heldout subset has retention gates, not the development family gate."""
    retained = all(
        not row["baseline_timing_eligible"]
        or all(
            B.qualified(
                {"expectation": row["expectation"]},
                row["variants"][role],
                specification=row["specifications"].get(role),
            )
            for role in B.ROLES[1:]
        )
        for row in rows
    )
    invariant = all(
        row["default_off_invariance"]["passed"] is not False
        and (
            not row["baseline_timing_eligible"]
            or row["default_off_invariance"]["passed"] is True
        )
        for row in rows
    )
    no_false = all(
        not sample["false_positive"] and not sample["unsafe_acceptance"]
        for row in rows
        for sample in row["variants"].values()
    )
    outputs = all(
        not row["baseline_timing_eligible"]
        or row["expectation"] != "safe"
        or row["variants"]["baseline"]["expressions"]
        == row["variants"]["candidate"]["expressions"]
        for row in rows
    )
    contracts = all(
        sample["status"] not in {"contract_error", "process_error"}
        and (not sample["measurement_errors"] or sample["timed_out"])
        for row in rows
        for sample in list(row["variants"].values())
        + list(row["specifications"].values())
    )
    assembled = all(
        row["assemble"]["returncode"] == 0 and not row["assemble"]["timed_out"]
        for row in rows
    )
    counts = {}
    for role in B.ROLES:
        counts[role] = {
            "statuses": dict(Counter(row["variants"][role]["status"] for row in rows)),
            "safe_graphs": sum(
                row["expectation"] == "safe"
                and row["variants"][role]["status"] == "graph_verified"
                for row in rows
            ),
            "safe_complete_proofs": sum(
                row["expectation"] == "safe"
                and B.qualified(
                    {"expectation": "safe"},
                    row["variants"][role],
                    specification=row["specifications"].get(role),
                )
                for row in rows
            ),
            "hazards_detected": sum(
                row["expectation"] == "hazard" and row["variants"][role]["detected"]
                for row in rows
            ),
        }
    new = [
        row
        for row in rows
        if row["expectation"] == "hazard"
        and not row["baseline_timing_eligible"]
        and row["variants"]["candidate"]["status"] == "certified_rejection"
        and not row["variants"]["candidate"]["measurement_errors"]
    ]
    return {
        "configurations": len(rows),
        "safe_denominator": 3,
        "hazard_denominator": 3,
        "baseline_timing_eligible": [
            row["case"] for row in rows if row["baseline_timing_eligible"]
        ],
        "counts": counts,
        "baseline_qualifications_retained": retained,
        "default_off_invariance": invariant,
        "safe_enabled_output_invariance": outputs,
        "no_false_outcomes": no_false,
        "process_contracts_valid": contracts,
        "all_complete_modules_assembled": assembled,
        "correctness_gates_pass": retained
        and invariant
        and outputs
        and no_false
        and contracts
        and assembled,
        "new_coverage_families": sorted({row["family"] for row in new}),
        "new_complex_coverage_families": sorted(
            {row["family"] for row in new if row["case"].startswith("memory-wide-")}
        ),
        "new_coverage": [
            {
                "case": row["case"],
                "baseline_status": row["variants"]["baseline"]["status"],
                "candidate_status": row["variants"]["candidate"]["status"],
                "observed_certified_seconds": row["variants"]["candidate"][
                    "time_to_detection_seconds"
                ],
                "baseline_ratio": None,
            }
            for row in new
        ],
        "development_family_adoption_gate_evaluated": False,
    }


def refused_sample():
    return {
        "status": "assembler_refused",
        "detected": False,
        "false_positive": False,
        "unsafe_acceptance": False,
        "measurement_errors": [],
        "timed_out": False,
        "expressions": None,
    }


def qualify(args):
    document, identity, frozen = setup(args)
    frozen[str(args.assembler)] = B.sha(args.assembler)
    output = B.fresh(args.output)
    B.snapshot_harness(output, frozen)
    workloads = {row["id"]: row for row in document["workloads"]}
    rows = []
    for case in heldouts(document):
        directory = output / case["id"]
        directory.mkdir()
        assembly = directory / "complete-module.s"
        assembly.write_bytes(B.study.changed_source(workloads[case["workload"]], case))
        B.require(
            B.sha(assembly) == case["materialized_assembly_sha256"],
            "heldout materialization changed",
        )
        frozen[str(assembly)] = B.sha(assembly)
        assemble_directory = directory / "assemble"
        assemble_directory.mkdir()
        mc = B.capture(
            [
                str(args.assembler),
                "-triple=amdgcn-amd-amdhsa",
                "--mcpu=" + case["target"],
                "-filetype=obj",
                str(assembly),
                "-o",
                str(directory / "complete-module.o"),
            ],
            assemble_directory,
        )
        for name in ("stdout", "stderr", "resources.txt"):
            path = assemble_directory / name
            if path.exists():
                frozen[str(path)] = B.sha(path)
        proofs, references = {}, {}
        if mc["returncode"] == 0 and not mc["timed_out"]:
            variants = {}
            for role in B.ROLES:
                variants[role] = B.execute(
                    args.baseline_binary
                    if role == "baseline"
                    else args.candidate_binary,
                    case,
                    assembly,
                    directory / role,
                    enabled=role == "candidate",
                    export=case["expectation"] == "safe" or role != "candidate",
                )
                if case["expectation"] == "safe":
                    proofs[role] = B.execute(
                        args.baseline_binary
                        if role == "baseline"
                        else args.candidate_binary,
                        case,
                        assembly,
                        directory / (role + "-specification"),
                        enabled=role == "candidate",
                        verify=True,
                    )
                    path = directory / role / "outputs.vexpr"
                    if path.is_file():
                        try:
                            references[role] = B.safe_export(path, case)
                        except ValueError:
                            pass  # Nonqualifying artifacts remain untouched.
            eligibility = baseline_eligible(
                case, variants["baseline"], proofs.get("baseline")
            )
            invariant = B.invariance(variants["baseline"], variants["candidate-off"])
        else:
            variants = {role: refused_sample() for role in B.ROLES}
            eligibility = False
            invariant = {
                "comparable": False,
                "passed": None,
                "reason": "complete module refused by assembler; no verifier run",
            }
        row = {
            "case": case["id"],
            "family": workloads[case["workload"]]["family"],
            "expectation": case["expectation"],
            "category": case["category"],
            "assemble": mc,
            "baseline_timing_eligible": eligibility,
            "default_off_invariance": invariant,
            "variants": variants,
            "specifications": proofs,
            "references": references,
            "assembly": str(assembly),
            "assembly_sha256": B.sha(assembly),
        }
        for sample in list(variants.values()) + list(proofs.values()):
            B.bind_sample(frozen, sample)
        rows.append(row)
        B.unchanged(frozen)
        print(
            case["id"],
            {role: sample["status"] for role, sample in variants.items()},
            "baseline-eligible=" + str(eligibility),
            flush=True,
        )
        B.write(output / "checkpoint.json", {"results": rows})
    B.unchanged(frozen)
    B.write(
        output / "report.json",
        {
            "schema_version": 1,
            "phase": "heldout_functional_qualification",
            "harness_revision": subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=B.ROOT, text=True
            ).strip(),
            "frozen_mechanism": args.frozen_mechanism,
            "identity": identity,
            "input_sha256": frozen,
            "protocol": document["protocol"],
            "heldouts_executed": len(rows),
            "development_cases_executed": 0,
            "results": rows,
            "functional": summary(rows),
            "scope": "First fixed-budget heldout functional qualification; descriptive durations only, no paired latency comparison. All six frozen IDs and every miss retained.",
        },
    )


def validate_qualification(report, document, identity, mechanism):
    B.require(
        report["phase"] == "heldout_functional_qualification"
        and report["frozen_mechanism"] == mechanism
        and report["identity"] == identity,
        "heldout qualification source/build identity differs",
    )
    cases = {case["id"]: case for case in heldouts(document)}
    workloads = {row["id"]: row for row in document["workloads"]}
    rows = report["results"]
    B.require(
        len(rows) == 6 and {row["case"] for row in rows} == set(cases),
        "missing, duplicate or extra heldout qualification",
    )
    for row in rows:
        case = cases[row["case"]]
        expected = baseline_eligible(
            case, row["variants"]["baseline"], row["specifications"].get("baseline")
        )
        B.require(
            row["baseline_timing_eligible"] == expected
            and row["expectation"] == case["expectation"]
            and row["category"] == case["category"]
            and row["family"] == workloads[case["workload"]]["family"]
            and row["assembly_sha256"] == case["materialized_assembly_sha256"],
            "heldout baseline eligibility or source contract changed",
        )
    B.require(
        report["functional"] == summary(rows),
        "heldout qualification gates differ from recorded outcomes",
    )
    return rows


def compare(args):
    document, identity, frozen = setup(args)
    path = args.qualification.resolve(strict=True)
    B.require(
        B.sha(path) == args.qualification_sha256,
        "heldout qualification differs from reviewed digest",
    )
    report = json.loads(path.read_text())
    rows = validate_qualification(report, document, identity, args.frozen_mechanism)
    B.unchanged(report["input_sha256"])
    frozen.update(report["input_sha256"])
    frozen[str(path)] = B.sha(path)
    output = B.fresh(args.output)
    B.snapshot_harness(output, frozen)
    controls = {row["case"]: row for row in rows}
    cases = [
        case
        for case in heldouts(document)
        if controls[case["id"]]["baseline_timing_eligible"]
    ]
    for case in cases:
        control = controls[case["id"]]
        B.require(
            B.sha(Path(control["assembly"])) == case["materialized_assembly_sha256"],
            "heldout module changed",
        )
        if case["expectation"] == "safe":
            for role in ("baseline", "candidate"):
                reference = control["references"].get(role)
                B.require(
                    reference is not None
                    and B.expression_observation(Path(reference["path"]))
                    == reference["observation"],
                    "missing or stale full safe reference",
                )
    generator = random.Random(document["protocol"]["seed"])
    samples = []
    before = {
        "context": B.statistics.runtime_context(),
        "load_average": list(os.getloadavg()),
    }
    # Selection differs from development; execution and statistical primitives
    # remain the reviewed frozen benchmark helpers, with identical budgets.
    for repeat in range(32):
        order = list(cases)
        generator.shuffle(order)
        for case in order:
            roles = ["baseline", "candidate"]
            generator.shuffle(roles)
            for role in roles:
                control = controls[case["id"]]
                value = B.execute(
                    args.baseline_binary
                    if role == "baseline"
                    else args.candidate_binary,
                    case,
                    Path(control["assembly"]),
                    output / case["id"] / f"{repeat:02d}-{role}",
                    enabled=role == "candidate",
                    export=case["expectation"] == "safe",
                    reference=control["references"].get(role),
                    discard_duplicate=True,
                )
                samples.append(
                    {"case": case["id"], "role": role, "repeat": repeat, **value}
                )
                B.unchanged(
                    {
                        str(args.baseline_binary): identity["builds"]["baseline"][
                            "binary_sha256"
                        ],
                        str(args.candidate_binary): identity["builds"]["candidate"][
                            "binary_sha256"
                        ],
                        control["assembly"]: control["assembly_sha256"],
                    }
                )
                print(repeat, case["id"], role, value["status"], flush=True)
                B.write(output / "checkpoint.json", {"samples": samples})
        B.unchanged(frozen)
    timing = B.timing_summary(
        cases, samples, report["functional"], document["protocol"]
    )
    # Development's >=4-family adoption gate and four primaries are not tests of
    # this six-row subset. Keep all applicable retention/overhead/sample gates.
    applicable = {
        key: timing[key]
        for key in (
            "baseline_fixed_cases",
            "successful_paired_comparisons",
            "failed_candidate_or_baseline_qualifiers",
            "cases",
            "correctness_gates_pass",
            "overhead_gates_pass",
        )
    }
    applicable["heldout_retention_and_overhead_gates_pass"] = (
        timing["correctness_gates_pass"] and timing["overhead_gates_pass"]
    )
    applicable["development_family_adoption_gate_evaluated"] = False
    B.unchanged(frozen)
    B.write(
        output / "report.json",
        {
            "schema_version": 1,
            "phase": "paired_heldout_measurement",
            "frozen_mechanism": args.frozen_mechanism,
            "identity": identity,
            "input_sha256": frozen,
            "qualification_sha256": B.sha(path),
            "protocol": document["protocol"],
            "heldouts_executed": 6,
            "development_cases_executed": 0,
            "runtime_before": before,
            "runtime_after": {
                "context": B.statistics.runtime_context(),
                "load_average": list(os.getloadavg()),
            },
            "functional": report["functional"],
            "samples": samples,
            "comparison": applicable,
            "scope": "Fixed heldout subset. Baseline-only eligibility; all functional misses retained. Ratios only for successful common qualifiers. First samples separate; process RSS maximum includes first plus31 repeats.",
        },
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="mode", required=True)
    commands.add_parser("check")
    for name in ("qualify", "compare"):
        command = commands.add_parser(name)
        for field in (
            "baseline-report",
            "baseline-binary",
            "baseline-build-record",
            "candidate-binary",
            "candidate-build-record",
            "development-preflight",
        ):
            command.add_argument("--" + field, type=Path, required=True)
        command.add_argument("--candidate-revision", required=True)
        command.add_argument("--frozen-mechanism", required=True)
        command.add_argument("--development-preflight-sha256", required=True)
        command.add_argument("--output", type=Path, required=True)
        if name == "qualify":
            command.add_argument(
                "--assembler", type=Path, default=Path("/opt/rocm/llvm/bin/llvm-mc")
            )
        else:
            command.add_argument("--qualification", type=Path, required=True)
            command.add_argument("--qualification-sha256", required=True)
    args = parser.parse_args()
    try:
        if args.mode == "check":
            document = B.study.load_cases()
            B.require(
                B.sha(B.study.MANIFEST) == B.MANIFEST_SHA, "frozen manifest changed"
            )
            print(
                json.dumps(
                    {
                        "heldout_cases": [case["id"] for case in heldouts(document)],
                        "subprocesses_executed": 0,
                        "manifest_sha256": B.MANIFEST_SHA,
                    },
                    indent=2,
                )
            )
        else:
            for field in (
                "baseline_report",
                "baseline_binary",
                "baseline_build_record",
                "candidate_binary",
                "candidate_build_record",
                "development_preflight",
                "assembler" if args.mode == "qualify" else "qualification",
            ):
                setattr(args, field, getattr(args, field).resolve(strict=True))
            (qualify if args.mode == "qualify" else compare)(args)
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.SubprocessError,
    ) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
