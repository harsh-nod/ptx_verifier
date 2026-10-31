#!/usr/bin/env python3
"""Source-bound qualification for instruction-local ordinary memory conflicts.

This collector performs one untimed functional pass. It does not execute a GPU,
run heldouts, build a verifier, or produce a latency comparison.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MANIFEST = HERE / "cases.json"
sys.path.insert(0, str(HERE.parent / "compiler-corpus"))
import corpus  # noqa: E402

_BUILD_SPEC = importlib.util.spec_from_file_location(
    "study_build_records", ROOT / "tests/gfx1250/measure_tensor_bounds.py"
)
build_records = importlib.util.module_from_spec(_BUILD_SPEC)
_BUILD_SPEC.loader.exec_module(build_records)

MARKER = "EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION"
PROPERTY = "AMD memory-conflict freedom"
PROPERTIES = {
    "AMD trace completeness",
    "AMD wait and register readiness",
    "AMD workgroup barrier generations",
    PROPERTY,
}
CONFLICT_BODY = (
    r"MemoryConflict \{ kind: WriteWrite, location: ByteLocation \{ "
    r"space: (Global|Shared), addr: (\d+) \}, earlier: EventId\((\d+)\), "
    r"later: EventId\((\d+)\) \}"
)
WITNESS = re.compile(r"^  kernel: " + CONFLICT_BODY + r"$", re.M)
ORDINARY_WITNESS = re.compile(r"^      " + CONFLICT_BODY + r"$", re.M)
HELDOUTS = frozenset(
    {
        "memory-gfx950-transpose-heldout-safe",
        "memory-gfx950-transpose-heldout-partial-overlap",
        "memory-wide-gfx1250-silu_f16-heldout-safe",
        "memory-wide-gfx1250-silu_f16-heldout-vector-alias",
        "memory-wide-gfx1250-softmax_f16-heldout-safe",
        "memory-wide-gfx1250-softmax_f16-heldout-vector-alias",
    }
)
PRIMARIES = frozenset(
    "memory-wide-gfx1250-" + name + "-inserted-collision"
    for name in (
        "matvec_f16",
        "gemm_f16_full",
        "flash_attention_original",
        "convolution_f16_original",
    )
)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical(row):
    return digest(json.dumps(row, sort_keys=True, separators=(",", ":")).encode())


def source_path(relative, root=ROOT):
    path = Path(relative)
    corpus.require(
        not path.is_absolute() and ".." not in path.parts, "unsafe source path"
    )
    return root / path


def changed_source(workload, case, root=ROOT):
    lines = (
        source_path(workload["assembly"], root).read_text().splitlines(keepends=True)
    )
    start = next(
        i for i, line in enumerate(lines) if line.startswith(workload["kernel"] + ":")
    )
    end = next(
        i
        for i in range(start + 1, len(lines))
        if re.match(r"\s*\.size\s+" + re.escape(workload["kernel"]) + ",", lines[i])
    )
    edits = case["edits"]
    corpus.require(
        len(edits) == len({edit["source_line"] for edit in edits}),
        "duplicate mutation anchor",
    )
    for edit in sorted(edits, key=lambda value: value["source_line"], reverse=True):
        index = edit["source_line"] - 1
        corpus.require(start < index < end, "mutation outside selected kernel")
        corpus.require(
            lines[index].strip() == edit["original"], "stale mutation anchor"
        )
        lines[index] = "\t" + edit["replacement"].replace("\n", "\n\t") + "\n"
    return "".join(lines).encode()


def original_row(workload, root=ROOT):
    path = source_path(workload["manifest"], root)
    corpus.require(
        corpus.sha(path) == workload["manifest_sha256"], "stale original manifest"
    )
    rows = json.loads(path.read_text())["cases"]
    field = "kernel" if workload["origin"] == "original_full" else "id"
    found = [row for row in rows if row[field] == workload["origin_id"]]
    corpus.require(
        len(found) == 1 and canonical(found[0]) == workload["manifest_row_sha256"],
        "missing, duplicate or changed original launch contract",
    )
    return found[0]


def load_cases(path=MANIFEST, root=ROOT):
    document = json.loads(path.read_text())
    corpus.require(document["schema_version"] == 1, "unknown study schema")
    protocol = document["protocol"]
    corpus.require(
        protocol["repeats"] == 31
        and protocol["seed"] == 20261031
        and protocol["wall_timeout_seconds_per_stage"] == 60,
        "predeclared budget changed",
    )
    corpus.require(
        protocol["candidate_marker"] == MARKER
        and protocol["candidate_option"] == "early_memory_conflicts",
        "certificate API changed",
    )
    workloads = {row["id"]: row for row in document["workloads"]}
    cases = document["cases"]
    corpus.require(len(workloads) == len(document["workloads"]), "duplicate workload")
    corpus.require(
        len(cases) == len({row["id"] for row in cases}) == 46 and len(workloads) == 20,
        "missing or duplicate finite study cases",
    )
    corpus.require(
        {c["id"] for c in cases if c["split"] == "heldout"}
        == set(protocol["heldout_cases"])
        == HELDOUTS,
        "heldout selection changed",
    )
    corpus.require(
        {c["id"] for c in cases if c["primary_latency"]}
        == set(protocol["primary_latency_cases"])
        == PRIMARIES,
        "predeclared four primaries changed",
    )
    for workload in workloads.values():
        corpus.require(
            workload["origin"] in {"compiler_corpus", "original_full"},
            "unknown original contract",
        )
        row = original_row(workload, root)
        corpus.require(
            row["kernel"] == workload["kernel"]
            and row["expected_outputs"] == workload["expected_outputs"],
            "original kernel/output changed",
        )
        corpus.require(
            workload["target"] in {"gfx950", "gfx1250"}, "unsupported study target"
        )
        for field in ("source", "assembly", "spec", "launch_config"):
            if field in workload:
                corpus.require(
                    corpus.sha(source_path(workload[field], root))
                    == workload[field + "_sha256"],
                    "stale workload input: " + field,
                )
        corpus.require(
            corpus.harness.native_target_of(
                source_path(workload["assembly"], root).read_text()
            )
            == workload["target"],
            "native target relabeled",
        )
    by_id = {case["id"]: case for case in cases}
    for case in cases:
        corpus.require(
            re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", case["id"]),
            "unsafe case identifier",
        )
        corpus.require(case["split"] in {"development", "heldout"}, "unknown split")
        corpus.require(case["expectation"] in {"safe", "hazard"}, "unknown expectation")
        workload = workloads[case["workload"]]
        source = changed_source(workload, case, root)
        corpus.require(
            digest(source) == case["materialized_assembly_sha256"],
            "mutated byte identity changed",
        )
        if case["expectation"] == "safe":
            corpus.require(not case["edits"], "safe original source changed")
        else:
            truth = case["ground_truth"]
            corpus.require(
                case["required_property"] == PROPERTY and truth["finite_input_witness"],
                "missing independent ground truth",
            )
            corpus.require(
                truth["physical_lanes"] == [0, 1]
                and truth["space"] in {"Global", "Shared"},
                "unknown lane or address-space witness",
            )
            corpus.require(
                0 < truth["overlap_bytes"] <= truth["store_bytes"],
                "invalid overlap extent",
            )
            safe = by_id[case["safe_counterpart"]]
            corpus.require(
                safe["expectation"] == "safe"
                and safe["workload"] == case["workload"]
                and safe["split"] == case["split"]
                and safe.get("launch_overrides") == case.get("launch_overrides"),
                "unmatched safe contract",
            )
            if case["category"] == "inserted_store":
                corpus.require(
                    len(case["edits"]) == 1
                    and truth["mutation_instructions"] == 1
                    and truth["preserves_all_original_initializing_stores"] is True,
                    "primary insertion changed",
                )
                edit = case["edits"][0]
                zero = truth["constant_address"]
                corpus.require(
                    edit["replacement"]
                    == edit["original"]
                    + "\nds_store_b16 "
                    + zero["register"]
                    + ", "
                    + edit["original"].split(", ", 1)[1],
                    "original initialization removed or extra edits",
                )
                lines = source_path(workload["assembly"], root).read_text().splitlines()
                definition = zero["definition"]
                corpus.require(
                    definition["source_line"] < edit["source_line"]
                    and lines[definition["source_line"] - 1].strip()
                    == definition["original"],
                    "stale constant-address definition",
                )
        if case.get("launch_overrides"):
            corpus.require(
                case["id"] in HELDOUTS
                and set(case["launch_overrides"]) == {"array_bases"}
                and case["launch_overrides"]["array_bases"]
                == {"x": 196608, "out": 327680},
                "unexpected launch change",
            )
    for control in document["mathematical_controls"]:
        corpus.require(
            control["workload"] in workloads and control["expected_mismatches"] == 64,
            "unknown mathematical control",
        )
        corpus.require(
            corpus.sha(source_path(control["spec"], root)) == control["spec_sha256"],
            "stale wrong specification",
        )
    return document


def expanded_case(workload, case, root=ROOT):
    row = original_row(workload, root)
    result = {
        **row,
        **case,
        **{
            key: workload[key]
            for key in (
                "target",
                "kernel",
                "source",
                "assembly",
                "spec",
                "expected_outputs",
            )
        },
    }
    if "launch_config" in workload:
        result["launch_config"] = workload["launch_config"]
    else:
        for array in result["arrays"]:
            if array["name"] in case.get("launch_overrides", {}).get("array_bases", {}):
                array["base_address"] = case["launch_overrides"]["array_bases"][
                    array["name"]
                ]
    result["output_indices"] = {
        a["name"]: list(range(a["length"]))
        for a in result["arrays"]
        if a["kind"] in {"out", "inout"}
    }
    corpus.require(
        sum(map(len, result["output_indices"].values())) == result["expected_outputs"],
        "incomplete original outputs",
    )
    return result


def command(
    binary, case, assembly, directory, *, verify=False, enabled=False, export=False
):
    argv = [
        str(binary),
        "--no-log-file",
        "verify" if verify else "analyze",
        str(assembly),
    ]
    if verify:
        argv += [str(ROOT / case["spec"]), "--sample", "0"]
        for name, value in case["dimensions"].items():
            argv += ["--dim", f"{name}={value}"]
    else:
        argv += ["--print-outputs", "0"]
        if export:
            argv += ["--emit-exprs", str(directory / "outputs.vexpr")]
    if case.get("launch_config"):
        original = ROOT / case["launch_config"]
        if enabled:
            configuration = json.loads(original.read_text())
            configuration["early_memory_conflicts"] = True
            derived = directory / "enabled.launch.json"
            derived.write_text(json.dumps(configuration, indent=2) + "\n")
            argv += [
                "--backend",
                "amdgpu",
                "--target",
                case["target"],
                "--no-profile",
                "--config",
                str(derived),
            ]
        else:
            argv += [
                "--backend",
                "amdgpu",
                "--target",
                case["target"],
                "--no-profile",
                "--config",
                str(original),
            ]
    else:
        argv += corpus.launch(case)
        if enabled:
            argv.append("--early-memory-conflicts")
    return argv


def classify(
    code,
    stdout,
    stderr,
    *,
    timed_out=False,
    expected_outputs=None,
    expressions=None,
    verify=False,
):
    """A property FAIL on an aborted/UNKNOWN full execution is not a detection."""
    result = {"detected": False, "detection_mode": None, "graph_accepted": False}
    if timed_out:
        return {**result, "status": "timeout"}
    if code not in (0, 1, 2):
        return {**result, "status": "process_error"}
    graph = corpus.harness.parse_cli(stdout)
    checks = [(name, verdict) for name, verdict, _ in graph.checks]
    complete = (
        len(checks) == len(PROPERTIES) and {name for name, _ in checks} == PROPERTIES
    )
    passing = complete and all(verdict == "PASS" for _, verdict in checks)
    accepted = code == 0 and graph.verdict == "VERIFIED" and passing
    result["graph_accepted"] = accepted
    text = stdout + "\n" + stderr
    markers = stdout.splitlines().count(MARKER)
    witness = WITNESS.findall(stdout)
    contradictory = re.search(
        r"\bunsupported\b|\bUNKNOWN\b|^error:|^Usage:|unvalidated|invalid certificate",
        text,
        re.I | re.M,
    )
    if markers:
        valid = (
            markers == 1
            and code == 1
            and re.findall(r"^VERDICT: (\w+)$", stdout, re.M) == ["REJECT"]
            and stdout.splitlines().count(
                "  AMD memory-conflict freedom (certified prefix) FAIL"
            )
            == 1
            and len(witness) == 1
            and witness[0][2] != witness[0][3]
            and not contradictory
            and not re.search(
                r"^VC check:|EQUIVALENT|^Output|^  out |VERIFIED", stdout, re.M
            )
            and expressions is None
        )
        return {
            **result,
            "status": "certified_rejection" if valid else "contract_error",
            "detected": bool(valid),
            "detection_mode": "certified_prefix" if valid else None,
        }
    stopped = re.search(
        r"execution (?:stopped|aborted)|trace generator aborted|trace: (?:aborted|unsupported)",
        text,
        re.I,
    )
    if stopped or contradictory:
        return {
            **result,
            "status": "unsupported"
            if re.search(r"\bunsupported\b", text, re.I)
            else "inconclusive",
        }
    ordinary_witnesses = ORDINARY_WITNESS.findall(stdout)
    supported = (
        code == 1
        and graph.verdict == "REJECTED"
        and complete
        and bool(ordinary_witnesses)
        and all(left != right for _, _, left, right in ordinary_witnesses)
        and dict(checks)
        == {name: ("FAIL" if name == PROPERTY else "PASS") for name in PROPERTIES}
    )
    if supported:
        return {
            **result,
            "status": "ordinary_rejection",
            "detected": True,
            "detection_mode": "complete_trace",
        }
    if verify:
        counts = re.findall(r"^VC check:.*  elements: (\d+)\s*$", stdout, re.M)
        verdicts = re.findall(r"^VERDICT: (\w+)$", stdout, re.M)
        if (
            code == 0
            and passing
            and verdicts == ["ACCEPT"]
            and counts == [str(expected_outputs)]
            and "EQUIVALENT (matches spec)" in stdout
            and "NOT EQUIVALENT" not in stdout
        ):
            return {**result, "status": "spec_verified"}
        if (
            code == 1
            and passing
            and verdicts == ["REJECT"]
            and counts == [str(expected_outputs)]
            and re.findall(
                r"^NOT EQUIVALENT: (\d+) mismatched element\(s\) vs spec$", stdout, re.M
            )
            == counts
        ):
            return {**result, "status": "mathematical_refutation"}
    elif accepted:
        if expressions is not None:
            try:
                corpus.require(
                    corpus.expression_indices(expressions) == expected_outputs,
                    "missing, shifted or aliased outputs",
                )
                coverage = corpus.harness.array_coverage_error(
                    stdout,
                    {name: len(indices) for name, indices in expected_outputs.items()},
                )
                corpus.require(coverage is None, coverage)
            except ValueError:
                return {**result, "status": "contract_error"}
            return {**result, "status": "graph_verified"}
        return {**result, "status": "graph_accepted_without_output_proof"}
    return {**result, "status": "inconclusive"}


def baseline(args, document):
    output = args.output.resolve()
    corpus.require(
        not output.exists() and not output.is_relative_to(ROOT),
        "raw output must be fresh and outside repository",
    )
    binary = args.binary.resolve(strict=True)
    revision = subprocess.check_output(
        ["git", "rev-parse", args.revision + "^{commit}"], cwd=ROOT, text=True
    ).strip()
    record_path = args.build_record.resolve(strict=True)
    build = build_records.build_identity(record_path, revision, binary)
    paths = {
        "driver": Path(__file__),
        "manifest": MANIFEST,
        "compiler_corpus": Path(corpus.__file__),
        "shared_cli_parser": Path(corpus.harness.__file__),
        "binary": binary,
        "assembler": args.assembler.resolve(strict=True),
        "build_record": record_path,
        "build_validation": Path(build_records.__file__),
    }
    for workload in document["workloads"]:
        for field in ("manifest", "source", "assembly", "spec", "launch_config"):
            if field in workload:
                paths[workload["id"] + ":" + field] = ROOT / workload[field]
    for control in document["mathematical_controls"]:
        paths[control["id"]] = ROOT / control["spec"]
    hashes = {key: corpus.sha(path) for key, path in paths.items()}
    output.mkdir()
    snapshots = output / "harness"
    snapshots.mkdir()
    for key in (
        "driver",
        "manifest",
        "compiler_corpus",
        "shared_cli_parser",
        "build_validation",
    ):
        (snapshots / paths[key].name).write_bytes(paths[key].read_bytes())
    workloads = {row["id"]: row for row in document["workloads"]}
    results = []
    for original in document["cases"]:
        if original["split"] != "development":
            continue  # No subprocess, including MC, may inspect heldout behavior.
        workload = workloads[original["workload"]]
        case = expanded_case(workload, original)
        directory = output / case["id"]
        directory.mkdir()
        assembly = directory / "complete-module.s"
        assembly.write_bytes(changed_source(workload, original))
        frozen = {assembly: corpus.sha(assembly)}
        mc, _, _ = corpus.run_stage(
            [
                str(args.assembler),
                "-triple=amdgcn-amd-amdhsa",
                "--mcpu=" + case["target"],
                "-filetype=obj",
                str(assembly),
                "-o",
                str(directory / "complete-module.o"),
            ],
            directory,
            "assemble",
            60,
        )
        result = {
            "case": case["id"],
            "category": case["category"],
            "expectation": case["expectation"],
            "primary_latency": case["primary_latency"],
            "materialized_assembly_sha256": corpus.sha(assembly),
            "assemble": mc,
        }
        if mc["returncode"] != 0 or mc["timed_out"]:
            result.update(
                status="assembler_refused", detected=False, timing_eligible=False
            )
        else:
            argv = command(
                binary, case, assembly, directory, export=case["expectation"] == "safe"
            )
            stage, stdout, stderr = corpus.run_stage(argv, directory, "analyze", 60)
            expressions = directory / "outputs.vexpr"
            analysis = classify(
                stage["returncode"],
                stdout,
                stderr,
                timed_out=stage["timed_out"],
                expected_outputs=case["output_indices"],
                expressions=expressions.read_text() if expressions.exists() else None,
            )
            result.update(
                analysis=analysis,
                analyze=stage,
                status=analysis["status"],
                detected=analysis["detected"],
                unsafe_acceptance=case["expectation"] == "hazard"
                and analysis["graph_accepted"],
                false_positive=case["expectation"] == "safe" and analysis["detected"],
            )
            if case["expectation"] == "safe":
                argv = command(binary, case, assembly, directory, verify=True)
                proof, stdout, stderr = corpus.run_stage(argv, directory, "verify", 60)
                specification = classify(
                    proof["returncode"],
                    stdout,
                    stderr,
                    timed_out=proof["timed_out"],
                    expected_outputs=case["expected_outputs"],
                    verify=True,
                )
                result.update(specification=specification, verify=proof)
                result["timing_eligible"] = (
                    analysis["status"] == "graph_verified"
                    and specification["status"] == "spec_verified"
                )
            else:
                result["timing_eligible"] = analysis["status"] == "ordinary_rejection"
        corpus.require(
            all(corpus.sha(path) == value for path, value in frozen.items()),
            "generated module changed during qualification",
        )
        corpus.require(
            all(corpus.sha(path) == hashes[key] for key, path in paths.items()),
            "qualification input changed",
        )
        results.append(result)
        print(
            case["id"],
            result["status"],
            "eligible=" + str(result["timing_eligible"]),
            flush=True,
        )
        (output / "checkpoint.json").write_text(
            json.dumps({"results": results}, indent=2) + "\n"
        )
    math_controls = []
    for control in document["mathematical_controls"]:
        case = next(
            c
            for c in document["cases"]
            if c["workload"] == control["workload"]
            and c["expectation"] == "safe"
            and c["split"] == "development"
        )
        case = expanded_case(workloads[case["workload"]], case)
        case["spec"] = control["spec"]
        directory = output / control["id"]
        directory.mkdir()
        assembly = output / case["id"] / "complete-module.s"
        stage, stdout, stderr = corpus.run_stage(
            command(binary, case, assembly, directory, verify=True),
            directory,
            "wrong-spec",
            60,
        )
        classification = classify(
            stage["returncode"],
            stdout,
            stderr,
            timed_out=stage["timed_out"],
            expected_outputs=64,
            verify=True,
        )
        math_controls.append(
            {"id": control["id"], "classification": classification, "stage": stage}
        )
    corpus.require(
        all(corpus.sha(path) == hashes[key] for key, path in paths.items()),
        "qualification input changed",
    )
    load_cases()
    report = {
        "schema_version": 1,
        "phase": "baseline_functional_qualification",
        "binary_revision": revision,
        "input_sha256": hashes,
        "build_identity": build,
        "build_trust": "Caller-attested source/binary association; executable hash is checked, not independently proven by this collector.",
        "protocol": document["protocol"],
        "cases": len(results),
        "heldouts_executed": 0,
        "outcomes": dict(sorted(Counter(row["status"] for row in results).items())),
        "timing_eligible": [row["case"] for row in results if row["timing_eligible"]],
        "mathematical_controls": math_controls,
        "results": results,
        "scope": "One functional baseline qualification, not a latency study. All original shapes and output contracts retained; misses/timeouts are explicit.",
    }
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="mode", required=True)
    commands.add_parser("check")
    collector = commands.add_parser("baseline")
    collector.add_argument("--binary", type=Path, required=True)
    collector.add_argument("--revision", required=True)
    collector.add_argument("--build-record", type=Path, required=True)
    collector.add_argument("--output", type=Path, required=True)
    collector.add_argument(
        "--assembler", type=Path, default=Path("/opt/rocm/llvm/bin/llvm-mc")
    )
    args = parser.parse_args()
    try:
        document = load_cases()
        if args.mode == "baseline":
            baseline(args, document)
        else:
            print(
                json.dumps(
                    {
                        "workloads": len(document["workloads"]),
                        "cases": len(document["cases"]),
                        "development": sum(
                            c["split"] == "development" for c in document["cases"]
                        ),
                        "heldout": len(HELDOUTS),
                        "primaries": sorted(PRIMARIES),
                        "manifest_sha256": corpus.sha(MANIFEST),
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
        subprocess.CalledProcessError,
    ) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
