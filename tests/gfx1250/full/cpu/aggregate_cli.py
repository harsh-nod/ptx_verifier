#!/usr/bin/env python3
"""Validate all32 CLI proofs across disjoint groups with one binary/source pin.

This validates retained CPU proof artifacts; it does not execute GPU code or
convert a successful subset, unknown verdict or aggregate element count into
full original-shape acceptance.
"""

import argparse
import importlib.util
import json
from pathlib import Path
import re
import time

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "original_cli_driver", HERE / "prove_cli.py"
)
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)
require, sha, atomic_json = DRIVER.require, DRIVER.sha, DRIVER.atomic_json
IDENTITY_KEYS = (
    "binary_revision_supplied_by_builder",
    "fixture_revision_supplied_by_builder",
    "driver_sha256",
    "bounded_driver_sha256",
    "binary_sha256",
    "runtime_sha256",
    "input_sha256",
    "output_contracts",
    "mode",
    "log_level",
    "host",
    "platform",
)


def retained_artifacts(registry, receipts):
    protected = DRIVER.retained_inputs(registry) | {Path(__file__)}
    for path in receipts:
        protected.add(path)
        try:
            record = json.loads(path.read_text())
        except (ValueError, OSError):
            continue
        if not isinstance(record, dict):
            continue
        snapshot = record.get("snapshot")
        if isinstance(snapshot, str):
            snapshot = Path(snapshot)
            protected.add(snapshot / "volta")
            pins = record.get("input_sha256")
            if isinstance(pins, dict):
                protected.update(
                    snapshot / "corpus" / name for name in pins if isinstance(name, str)
                )
        runtimes = record.get("runtime_sha256")
        if isinstance(runtimes, dict):
            protected.update(Path(name) for name in runtimes if isinstance(name, str))
        results = record.get("results")
        if isinstance(results, list):
            for result in results:
                if isinstance(result, dict) and isinstance(result.get("kernel"), str):
                    protected.update(
                        path.parent / result["kernel"] / name
                        for name in ("stdout.txt", "stderr.txt", "resources.txt")
                    )
    return protected


def aggregate(registry, receipts):
    _, cases, pins, outputs = DRIVER.load_registry(registry)
    cases = {case["kernel"]: case for case in cases}
    require(receipts, "at least one completed CLI group required")
    receipts = [path.resolve(strict=True) for path in receipts]
    require(len(receipts) == len(set(receipts)), "duplicate receipt path")
    identity, seen, groups = None, set(), []
    for path in receipts:
        record = json.loads(path.read_text())
        require(
            record.get("schema_version") == 1 and record.get("gate") == DRIVER.GATE,
            "unchanged original32 CLI gate required",
        )
        require(
            record.get("hardware_execution") is False
            and record.get("sampling") is False,
            "unsampled CPU-only proof required",
        )
        names = record["selected_kernels"]
        require(
            names and len(names) == len(set(names)),
            "empty or duplicate selected kernels",
        )
        require(not set(names) - cases.keys(), "unknown original CLI case")
        require(not seen.intersection(names), "overlapping CLI groups")
        complete = set(names) == cases.keys()
        require(
            record.get("status") == ("pass" if complete else "partial")
            and record.get("all_required_complete") is complete,
            "incomplete, unsuccessful or mislabeled CLI group",
        )
        require(
            record["expected_outputs"]
            == sum(cases[name]["expected_outputs"] for name in names),
            "partial or incorrect output footprint",
        )
        require(
            record.get("finished_unix", 0) >= record.get("started_unix", 0) > 0,
            "unfinished CLI group",
        )
        current = {key: record[key] for key in IDENTITY_KEYS}
        for key in (
            "binary_revision_supplied_by_builder",
            "fixture_revision_supplied_by_builder",
        ):
            require(
                re.fullmatch(r"[0-9a-f]{40}", current[key]),
                "exact builder/fixture revision required",
            )
        require(
            current["driver_sha256"] == sha(HERE / "prove_cli.py")
            and current["bounded_driver_sha256"] == sha(HERE / "prove_advanced.py"),
            "different CLI proof or bounded driver",
        )
        require(
            current["input_sha256"] == pins,
            "missing, stale or extra original input pins",
        )
        require(
            current["output_contracts"] == outputs,
            "incomplete per-array index contracts",
        )
        require(
            current["mode"] in ("default", "logging")
            and current["log_level"] in ("info", "debug"),
            "unknown CLI build profile",
        )
        require(current["runtime_sha256"], "empty runtime pins")
        require(
            identity is None or identity == current,
            "mixed source, binary, build profile, host, runtime or input pins",
        )
        identity = current
        snapshot = Path(record["snapshot"])
        require(snapshot.is_absolute(), "absolute immutable snapshot required")
        binary, corpus = snapshot / "volta", snapshot / "corpus"
        require(sha(binary) == current["binary_sha256"], "snapshot binary changed")
        require(
            all(sha(corpus / name) == digest for name, digest in pins.items()),
            "snapshot input changed",
        )
        probe = record["capability_probe"]
        require(
            probe["argv"] == [str(binary), "--help"] and probe["exit_code"] == 0,
            "missing successful binary capability probe",
        )
        limits = record["limits"]
        require(
            all(
                isinstance(limits[key], int) and limits[key] > 0
                for key in (
                    "wall_seconds",
                    "cpu_seconds",
                    "rss_bytes",
                    "address_space_bytes",
                )
            )
            and limits["address_space_bytes"] >= limits["rss_bytes"],
            "invalid proof budget",
        )
        results = record["results"]
        require(
            [result["kernel"] for result in results] == names,
            "missing, reordered or duplicate CLI case results",
        )
        artifacts = {}
        for result in results:
            name, case = result["kernel"], cases[result["kernel"]]
            require(
                result.get("passed") is True and result.get("outcome") == "passed",
                "unsuccessful required CLI case",
            )
            require(
                result["baseline_id"] == case["baseline_id"]
                and result["expected_outputs"] == case["expected_outputs"]
                and result["output_contract"] == outputs[name],
                "changed original case contract",
            )
            directory = path.parent / name
            expected = DRIVER.command(
                binary, corpus, case, current["mode"], current["log_level"]
            )
            require(
                result["argv"] == expected,
                "different target, config, dimensions or sampled CLI command",
            )
            require(
                result["measured_argv"]
                == [
                    "/usr/bin/time",
                    "-f",
                    DRIVER.TIME_FORMAT,
                    "-o",
                    str(directory / "resources.txt"),
                    *expected,
                ],
                "unmeasured CLI process",
            )
            streams = {
                stream: directory / (stream + ".txt") for stream in ("stdout", "stderr")
            }
            for stream, artifact in streams.items():
                require(
                    sha(artifact) == result[stream + "_sha256"],
                    f"{stream} artifact changed",
                )
            DRIVER.check_process(
                result,
                streams["stdout"].read_text(errors="replace"),
                case["expected_outputs"],
            )
            resources = directory / "resources.txt"
            require(
                resources.read_text() == result["resources"],
                "resource artifact changed",
            )
            require(
                re.findall(r"\bexit=(\d+)\s*$", result["resources"], re.M) == ["0"],
                "unsuccessful measured CLI process",
            )
            peaks = re.findall(r"\bpeak_rss_kib=(\d+)\b", result["resources"])
            require(
                len(peaks) == 1 and int(peaks[0]) * 1024 <= limits["rss_bytes"],
                "proof exceeded RSS budget",
            )
            artifacts[name] = {
                key: sha(artifact)
                for key, artifact in {**streams, "resources": resources}.items()
            }
        groups.append(
            {
                "receipt": str(path),
                "receipt_sha256": sha(path),
                "selected_kernels": names,
                "expected_outputs": record["expected_outputs"],
                "artifact_sha256": artifacts,
                "limits": limits,
            }
        )
        seen.update(names)
    require(seen == cases.keys(), "missing original CLI cases")
    require(
        all(sha(path) == digest for path, digest in identity["runtime_sha256"].items()),
        "runtime changed after proofs completed",
    )
    return {
        "identity": identity,
        "groups": groups,
        "case_count": len(seen),
        "expected_outputs": DRIVER.TOTAL_OUTPUTS,
        "registry_sha256": sha(registry),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", required=True, type=Path)
    parser.add_argument("--receipt", action="append", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        DRIVER.refuse_alias(
            args.output, retained_artifacts(args.registry, args.receipt)
        )
    except (ValueError, OSError) as error:
        parser.error(str(error))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    receipt = {
        "schema_version": 1,
        "gate": "complete original32 CLI groups",
        "status": "incomplete",
        "hardware_execution": False,
        "sampling": False,
        "started_unix": time.time(),
        "driver_sha256": sha(__file__),
    }
    atomic_json(args.output, receipt)
    try:
        receipt.update(aggregate(args.registry, args.receipt), status="pass")
    except (ValueError, OSError, KeyError, TypeError) as error:
        receipt.update(status="fail", error=f"{type(error).__name__}: {error}")
    finally:
        receipt["finished_unix"] = time.time()
        atomic_json(args.output, receipt)
        print(
            json.dumps(
                {
                    key: receipt.get(key)
                    for key in ("status", "case_count", "expected_outputs", "error")
                }
            )
        )
    return 0 if receipt["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
