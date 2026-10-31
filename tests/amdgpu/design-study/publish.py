#!/usr/bin/env python3
r"""Publish named completed frozen-readiness reports; never run measurements.

Example (add another --dataset only after that report has completed):
  python3 tests/amdgpu/design-study/publish.py --source-root FROZEN_CHECKOUT \
    --manifest FROZEN_CHECKOUT/tests/amdgpu/design-study/cases.json \
    --builds BUILDS.json \
    --dataset initial development 31 20261030 COMPLETED_REPORT.json \
    --output OUTPUT_DIRECTORY

Report semantics/gates must be independently audited before publication. This
helper checks identities, cardinalities and privacy, and preserves their numbers.
"""
import argparse
from collections import Counter
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import tempfile
from urllib.parse import urlsplit


MANIFEST_SHA = "57a2d020a4c6d1f5db2bbce50fc1dbff3561af7516e8468cdc08b5ec3adcc96b"
DRIVERS = {"driver_sha256": "tests/amdgpu/design-study/benchmark.py",
           "compiler_corpus_driver_sha256": "tests/amdgpu/compiler-corpus/corpus.py",
           "shared_harness_sha256": "ai_compiler_kernels/check_races.py"}
PRIVATE = {"hostname", "host_name", "nodename", "machine_id", "device_uuid", "pci", "pci_id",
           "bdf", "device_identity", "device_name", "raw_logs", "stdout", "stderr", "build_log",
           "candidate_build_log", "cpu_model"}
REASONS = {"graph verified with complete configured output indices",
           "every complete specification element proved before timing", "EARLY_READINESS: CERTIFIED_REJECTION",
           "AMD memory-conflict freedom (AMD completed-effect happens-before) FAIL",
           "AMD wait and register readiness (target-selected counters and register dependencies) FAIL",
           "memory-conflict freedom (Algorithm 3)                   FAIL"}
ERRORS = {"missing per-process resource observation", "nonpositive per-process peak RSS"}
ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]*\Z")
PUBLIC_HOSTS = {"github.com", "llvm.org", "docs.llvm.org", "arxiv.org", "export.arxiv.org",
                "docs.amd.com", "amd.com", "www.amd.com", "gpuopen.com"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def load(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, "duplicate JSON key")
            result[key] = value
        return result

    def nonfinite(_):
        raise ValueError("nonfinite JSON number")

    raw = path.read_bytes()
    return json.loads(raw, object_pairs_hook=unique, parse_constant=nonfinite), sha(raw)


def relative(path):
    require(isinstance(path, str) and path and "\\" not in path
            and not PurePosixPath(path).is_absolute() and ".." not in PurePosixPath(path).parts, "unsafe repository path")
    return path


def identity_rows(rows, key, expected):
    require(isinstance(rows, list) and len(rows) == len(expected)
            and {row[key] for row in rows} == set(expected), "missing/extra/duplicate control identity")


def sanitize(value, root):
    """Whitelist free-form diagnostics; normalize only known local path contexts."""
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            if key.lower() in PRIVATE:
                continue
            if key == "reason":
                result[key] = item if item in REASONS else "Diagnostic text omitted; classification and hash retained."
                result["reason_sha256"] = sha(item.encode())
            elif key == "measurement_errors" and isinstance(item, list):
                result[key] = [text if text in ERRORS else "Measurement error text omitted; hash retained." for text in item]
                result["measurement_error_sha256"] = [sha(text.encode()) for text in item]
            elif key == "kernel_release":
                result["platform"] = "WSL2" if re.search(r"microsoft|wsl", item, re.I) else "Linux"
            elif key == "command":
                if isinstance(item, list):
                    result[key] = ["<verifier-binary>" if index == 0 else
                                   token[len(str(root)) + 1:] if token.startswith(str(root) + "/") else
                                   "<local-artifact>" if Path(token).is_absolute() else token
                                   for index, token in enumerate(item)]
                else:
                    result[key] = re.sub(r"CARGO_TARGET_DIR=\S+", "CARGO_TARGET_DIR=<build-cache>", item)
            elif key == "effective_path":
                result[key] = "<effective-launch-json>"
            else:
                result[key] = sanitize(item, root)
        return result
    if isinstance(value, list):
        return [sanitize(item, root) for item in value]
    if isinstance(value, str):
        def public_url(match):
            url = urlsplit(match.group())
            require(url.scheme == "https" and url.hostname in PUBLIC_HOSTS and not url.username
                    and not url.password and url.port in {None, 443}, "unrecognized public source URL")
            require(url.hostname != "github.com" or url.path.startswith(("/harsh-nod/ptx_verifier/", "/llvm/llvm-project/")), "unrecognized GitHub source")
            return "PUBLIC_URL"
        rest = re.sub(r"https?://[^\s<>]+", public_url, value)
        require(not re.search(r"(?:^|[\s\"'=:(])/(?:[^\s]*)|[A-Za-z]:[\\/]|\\\\|"
                              r"\b(?:\d{1,3}\.){3}\d{1,3}\b|\b[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]\b|"
                              r"\b[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\b", rest),
                "unrecognized local path or machine identity; review before publication")
    return value


def frozen_assets(document, root):
    cases = document["cases"]
    require(len(cases) == len({case["id"] for case in cases})
            and Counter(case["split"] for case in cases) == {"development": 71, "heldout": 6}, "frozen case selection changed")
    assets, materialized = {}, {}
    for case in cases + document["mathematical_controls"]:
        for key, expected in case.items():
            if not key.endswith("_sha256") or key == "mutated_source_sha256":
                continue
            field = "baseline_path" if key == "baseline_sha256" else key[:-7]
            path = relative(case[field])
            actual = (root / path).resolve(strict=True)
            require(actual.is_relative_to(root) and sha(actual.read_bytes()) == expected, "frozen source pin differs: " + path)
            assets[path] = expected
        if "assembly" in case:
            lines = (root / case["assembly"]).read_text().splitlines(keepends=True)
            for edit in case.get("edits", []):
                index = edit["source_line"] - 1
                require(0 <= index < len(lines) and lines[index].strip() == edit["original"], "mutation anchor differs")
                indentation = lines[index][:len(lines[index]) - len(lines[index].lstrip())]
                lines[index] = indentation + edit["replacement"] + "\n"
            materialized[case["id"]] = sha("".join(lines).encode())
            require(materialized[case["id"]] == case.get("mutated_source_sha256", case["assembly_sha256"]), "mutation hash differs")
    return assets, materialized


def check_report(report, split, repeats, seed, document, builds, drivers):
    cases = [case for case in document["cases"] if split == "all" or case["split"] == split]
    ids = {case["id"] for case in cases}
    require(report["case_manifest_sha256"] == MANIFEST_SHA and report["repeated_process_samples"] == repeats
            and report["seed"] == seed and report["timeout_seconds"] == 60, "dataset protocol identity differs")
    for key, expected in drivers.items():
        require(report[key] == expected, "driver hash differs")
    identity_rows(report["variants"], "name", {"baseline", "candidate"})
    for variant in report["variants"]:
        name = variant["name"]
        require(variant["binary_revision"] == builds[name + "_revision"] and variant["binary_sha256"] == builds[name + "_sha256"]
                and variant["early_readiness"] is (name == "candidate"), "binary/variant identity differs")
    comparison = report["source_comparison"]
    require(comparison["baseline_revision"] == comparison["common_parent"] == builds["baseline_revision"]
            and comparison["candidate_revision"] == builds["candidate_revision"], "source comparison differs")
    samples = report["samples"]
    expected = {(case, variant, repeat) for case in ids for variant in ("baseline", "candidate") for repeat in range(repeats + 1)}
    require(len(samples) == len(expected) and {(row["case"], row["variant"], row["repeat"]) for row in samples} == expected,
            "timed sample grid incomplete or duplicated")
    require(report["sample_order"] == [{key: row[key] for key in ("repeat", "case", "variant")} for row in samples], "sample order differs")
    for left, right in zip(samples[::2], samples[1::2]):
        require(left["case"] == right["case"] and left["repeat"] == right["repeat"] and left["variant"] != right["variant"], "pairs are not adjacent")
    for key, name in (("baseline_off", "baseline-off"), ("candidate_off", "candidate-off")):
        identity_rows(report[key], "case", ids)
        require(all(row["variant"] == name and row["early_readiness_enabled"] is False for row in report[key]), "default-off mode differs")
    safe = {case["id"] for case in cases if case["expectation"] == "safe"}
    controls = {control["id"] for control in document["mathematical_controls"] if control["case"] in ids}
    for key, field, wanted in (("safe_spec_preflight", "case", safe), ("mathematical_controls", "id", controls)):
        require(set(report[key]) == {"baseline", "candidate", "candidate-off"}, "control variants incomplete")
        for rows in report[key].values():
            identity_rows(rows, field, wanted)
    identity_rows(report["summary"]["cases"], "case", ids)
    require(report["summary"]["total_configurations"] == len(ids), "summary cardinality differs")
    require(set(report["summary"]["variants"]) == {"baseline", "candidate"}, "summary variants differ")
    for rows in report["summary"]["variants"].values():
        identity_rows(rows, "case", ids)
    return cases


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--builds", required=True, type=Path)
    parser.add_argument("--dataset", required=True, action="append", nargs=5, metavar=("NAME", "SPLIT", "REPEATS", "SEED", "REPORT"))
    parser.add_argument("--output", required=True, type=Path, help="New directory under /tmp")
    args = parser.parse_args()
    root, output = args.source_root.resolve(strict=True), args.output.resolve()
    require(output != Path("/tmp") and output.is_relative_to(Path("/tmp")) and not output.exists(), "output must be a new /tmp directory")
    document, manifest_sha = load(args.manifest)
    require(manifest_sha == MANIFEST_SHA, "not the frozen manifest")
    assets, materialized = frozen_assets(document, root)
    builds, builds_sha = load(args.builds)
    require(builds["source_dirty"] is False and builds["candidate_source_dirty"] is False, "frozen build is dirty")
    for name in ("baseline", "candidate"):
        require(re.fullmatch(r"[0-9a-f]{40}", builds[name + "_revision"]) and re.fullmatch(r"[0-9a-f]{64}", builds[name + "_sha256"]), "incomplete build identity")
    drivers = {key: sha((root / path).read_bytes()) for key, path in DRIVERS.items()}
    metadata = {"schema_version": 1, "exporter_sha256": sha(Path(__file__).read_bytes()), "build_metadata_sha256": builds_sha,
                "builds": sanitize(builds, root), "case_manifest_sha256": manifest_sha, "manifest": sanitize(document, root),
                "source_asset_sha256": assets, "materialized_assembly_sha256": materialized,
                "drivers": {key: {"path": DRIVERS[key], "sha256": value} for key, value in drivers.items()}, "datasets": {}}
    summaries, rows, seen_hashes, source_comparison = {}, [], set(), None
    for name, split, repeat_text, seed_text, path in args.dataset:
        repeats, seed = int(repeat_text), int(seed_text)
        require(ID.fullmatch(name) and name not in summaries and split in {"development", "heldout", "all"}
                and repeats > 0 and seed >= 0, "invalid/duplicate dataset declaration")
        report, report_sha = load(Path(path))
        require(report_sha not in seen_hashes, "same report supplied under multiple names")
        seen_hashes.add(report_sha)
        cases = check_report(report, split, repeats, seed, document, builds, drivers)
        if source_comparison is None:
            source_comparison = report["source_comparison"]
        require(report["source_comparison"] == source_comparison, "datasets have different source changes")
        require(set(report) == {"variants", "source_comparison", "case_manifest_sha256", *DRIVERS, "runtime_context", "load_observations", "seed",
                                "timeout_seconds", "repeated_process_samples", "cache_policy", "safe_spec_preflight", "mathematical_controls",
                                "baseline_off", "candidate_off", "samples", "summary", "measurement_scope", "sample_order"}, "raw report schema changed")
        excluded = {"safe_spec_preflight", "mathematical_controls", "baseline_off", "candidate_off", "samples", "summary", "sample_order"}
        metadata["datasets"][name] = sanitize({key: value for key, value in report.items() if key not in excluded}, root)
        metadata["datasets"][name].update(raw_report_sha256=report_sha, split=split, case_ids=[case["id"] for case in cases])
        summaries[name] = sanitize(report["summary"], root)
        for phase, selected in (("timed", report["samples"]), ("baseline_off", report["baseline_off"]), ("candidate_off", report["candidate_off"])):
            for ordinal, sample in enumerate(selected):
                kind = ("first" if sample["repeat"] == 0 else "repeated") if phase == "timed" else "default_off"
                row = {"dataset": name, "phase": kind, "ordinal": ordinal, **sanitize(sample, root)}
                row["missed_expected_hazard"] = next(case["expectation"] for case in cases if case["id"] == sample["case"]) == "hazard" and not sample["detected_expected_hazard"]
                rows.append(row)
        for phase in ("safe_spec_preflight", "mathematical_controls"):
            for variant, selected in report[phase].items():
                for ordinal, control in enumerate(selected):
                    row = {key: value for key, value in control.items() if key != "stage"}
                    rows.append({"dataset": name, "phase": phase, "variant": variant, "ordinal": ordinal, **sanitize(row, root), **sanitize(control["stage"], root)})
    metadata["candidate_changed_file_sha256"] = {relative(path): sha((root / relative(path)).read_bytes()) for path in source_comparison["changed_paths"]}
    require(output.parent.is_dir(), "output parent must exist")
    temporary = Path(tempfile.mkdtemp(prefix=".readiness-publication-", dir=output.parent))
    try:
        (temporary / "summary.json").write_text(json.dumps({"datasets": summaries}, indent=2, allow_nan=False) + "\n")
        with (
            (temporary / "samples.csv.gz").open("wb") as raw,
            gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as compressed,
            io.TextIOWrapper(compressed, encoding="utf-8", newline="") as stream,
        ):
            writer = csv.DictWriter(stream, fieldnames=["dataset", "phase", "ordinal"] + sorted(set().union(*(row.keys() for row in rows)) - {"dataset", "phase", "ordinal"}), lineterminator="\n")
            writer.writeheader()
            writer.writerows({key: json.dumps(value, separators=(",", ":"), allow_nan=False) if isinstance(value, (dict, list, bool)) or value is None else value for key, value in row.items()} for row in rows)
        lines = ["# Frozen early-readiness measurements", "", "Only explicitly supplied completed datasets are included. Results remain separate; later results do not waive earlier failures.", ""]
        for name, summary in summaries.items():
            run = metadata["datasets"][name]
            lines.append(f"- {name}: {run['split']}, {len(run['case_ids'])} configurations, {run['repeated_process_samples']} repeated samples per arm, seed {run['seed']}; recorded adoption gate: {summary['adoption_gates_pass']}.")
        lines.extend(["", "metadata.json retains the full frozen manifest and source/spec/assembly/launch/ground-truth, materialized mutation, binary, build, driver and raw-report hashes. summary.json preserves audited decisions without recomputing them. samples.csv.gz retains every first/repeated sample and safe-specification, wrong-specification and default-off control. Read it with gzip.open(path, 'rt', encoding='utf-8', newline='') and csv.DictReader, or decompress with gzip -dc. Gzip uses mtime=0 and an empty filename header for deterministic repeated exports. No verifier, test, benchmark or bootstrap is run by this helper.", "",
                      "Reproduction arithmetic: group by dataset/case/variant. Repeat 0 is the separate first post-preflight invocation; medians/p95 use repeat 1..N. Median is the middle value or mean of two middle values; p95 is sorted_values[ceil(.95*N)-1]. Detection-time statistics use detected samples only: retain misses/refusals/timeouts separately, never replace missing endpoints with zero or the timeout budget. RSS maximum includes repeat 0. Safe budgets are median <= baseline*1.05+.001 seconds, p95 <= baseline*1.10+.001 seconds, RSS <= baseline+max(baseline*.05,8192 KiB). Use the exact hashed frozen driver for full gates and paired 2000-resample ratio-of-medians intervals; its bootstrap seed is 20261030, independently of execution-order seed.", "",
                      "Numbers retain round-trip binary64 precision: seconds for all times, KiB for RSS, integers for instructions. JSON structures/booleans/null use JSON within CSV; absent control metrics are empty cells. Ordinal preserves original within-phase sample order. Classification, flags, properties and hashes are observations, not independently re-proven here. Diagnostic latency counts configurations and time to first independently prefix-validated finding, not enumeration of every bug site. Full-mode controls separately preserve diagnostics.", "",
                      "Absolute local paths and artifact destinations become placeholders; reconstruct commands from the pinned manifest and substitute local paths. Raw logs, hostname/device fields, CPU product and machine-specific kernel suffixes are omitted; platform retains WSL2/Linux virtualization context. Nonallowlisted diagnostic/error text is replaced by a category and SHA-256. Source-to-binary revisions are recorded build declarations, not reproducible-build proof. Printed execution time is millisecond-quantized; GNU-time CPU values are centisecond-quantized. Whole-process wall time includes startup, I/O and scheduling; RSS is not assigned to internal phases. No harmful GPU execution is implied."])
        (temporary / "README.md").write_text("\n".join(lines) + "\n")
        metadata["publication_artifact_sha256"] = {name: sha((temporary / name).read_bytes()) for name in ("summary.json", "samples.csv.gz", "README.md")}
        (temporary / "metadata.json").write_text(json.dumps(metadata, indent=2, allow_nan=False) + "\n")
        temporary.rename(output)
    except BaseException:
        shutil.rmtree(temporary, ignore_errors=True)
        raise


if __name__ == "__main__":
    main()
