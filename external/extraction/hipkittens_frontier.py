#!/usr/bin/env python3
"""Join pinned lexical definitions, original compiler attempts and whole-module parses.

The ledger records relations and missing contracts, not a C++ instantiation proof.
All raw attempts remain immutable. No compiler, kernel execution or GPU is used.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

import hipkittens_inventory as inventory

EXTERNAL = Path(__file__).resolve().parents[1]
ORIGINS = ("baseline-all", "recipe-followup")
DEFAULT_INVENTORY = EXTERNAL / "hipkittens/corpus/inventory.json"
DEFAULT_PROOFS = EXTERNAL / "hipkittens/corpus/buffer-comparison.json"
DEFAULT_LEDGER = EXTERNAL / "hipkittens/corpus/frontier.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def digest(value):
    return inventory.sha(json.dumps(value, sort_keys=True, separators=(",", ":")).encode())


def read(path):
    return json.loads(path.read_text())


def write(path, document):
    path.write_text(json.dumps(document, indent=2) + "\n")


def unique(rows, key, description):
    result = {}
    for row in rows:
        identity = key(row)
        inventory.require(identity not in result, "duplicate " + description)
        result[identity] = row
    return result


def probe_id(source, target):
    return target + "-" + inventory.sha(source.encode())[:16]


def probe_universe(document):
    return {probe_id(unit["source"], profile["target"]): (unit, profile)
            for unit in document["compilation_units"] if unit["translation_unit_probe"]
            for profile in unit["profiles"]}


def load_attempts(campaign, document):
    """Preserve every attempt and select the last explicit recipe attempt per key."""
    expected = probe_universe(document)
    reports, attempts, selected = {}, defaultdict(list), {}
    for origin in ORIGINS:
        path = campaign / origin / "report.json"
        report = read(path)
        inventory.require(report["source_revision"] == document["revision"], "report source revision differs")
        rows = unique(report["results"], lambda row: row["id"], "probe in " + origin)
        if origin == ORIGINS[0]:
            inventory.require(set(rows) == set(expected), "initial report omits or adds source/profile probes")
        inventory.require(set(rows) <= set(expected), "followup contains unknown source/profile probe")
        reports[origin] = {"sha256": sha(path), "schema_version": report["schema_version"],
                           "inventory_sha256": report["inventory_sha256"],
                           "driver_sha256": report["driver_sha256"],
                           "compiler_sha256": report["compiler_sha256"],
                           "assembler_sha256": report["assembler_sha256"], "attempts": len(rows)}
        for identity, row in rows.items():
            unit, profile = expected[identity]
            inventory.require(row["source"] == unit["source"] and row["profile"]["target"] == profile["target"],
                              "probe identity differs from source/profile")
            inventory.require(row["source_sha256"] == document["source_sha256"][row["source"]], "probe source drift")
            directory = campaign / origin / identity
            inventory.require(read(directory / "result.json") == row, "individual attempt differs from report")
            for field, filename in (("assembly_sha256", "kernel.s"), ("object_sha256", "kernel.o")):
                if row.get(field):
                    inventory.require(sha(directory / filename) == row[field], "compiler artifact drift")
            entrypoints = row.get("emitted_kernels", [])
            unique(entrypoints, lambda entry: entry[".name"], "metadata entry in module")
            for entry in entrypoints:
                inventory.require(entry[".wavefront_size"] == {"gfx942": 64, "gfx950": 64, "gfx1250": 32}[profile["target"]],
                                  "emitted wave size differs from original profile")
            if row.get("object_sha256"):
                stage = read(directory / "assemble.json")
                inventory.require(stage["status"] == "succeeded" and stage["returncode"] == 0,
                                  "object lacks successful MC stage")
            attempts[identity].append((origin, row, directory))
            selected[identity] = (origin, row, directory)
    return reports, attempts, selected


def accepted(selected):
    return {key: attempt for key, attempt in selected.items()
            if attempt[1].get("object_sha256") and attempt[1].get("emitted_kernels")}


def parse_status(returncode, timed_out, stderr):
    if timed_out:
        return "timeout"
    if returncode not in (0, 1, 2):
        return "crash"
    if returncode == 0:
        return "parsed"
    return "parse_unsupported" if re.search(r"unsupported .*instruction", stderr, re.I) else "parse_rejected"


def replay(campaign, document, binary, revision, binary_sha256, output, jobs, timeout):
    inventory.require(not output.exists(), "raw replay output must be a fresh directory")
    inventory.require(sha(binary) == binary_sha256, "binary identity differs")
    reports, _, selected = load_attempts(campaign, document)
    modules = accepted(selected)
    output.mkdir(parents=True)

    def run(item):
        identity, (origin, row, directory) = item
        destination = output / identity
        destination.mkdir()
        command = [str(binary), "--no-log-file", "--backend", "amdgpu", "--target",
                   row["profile"]["target"], "parse", str(directory / "kernel.s")]
        start = time.monotonic()
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
        timed_out = False
        try:
            stdout, stderr = process.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            stdout, stderr = process.communicate()
        (destination / "parse.stdout").write_bytes(stdout)
        (destination / "parse.stderr").write_bytes(stderr)
        text = stderr.decode(errors="replace")
        result = {"id": identity, "source": row["source"], "target": row["profile"]["target"],
                  "attempt_origin": origin, "assembly_sha256": row["assembly_sha256"],
                  "object_sha256": row["object_sha256"], "metadata_sha256": digest(row["emitted_kernels"]),
                  "emitted_entry_occurrences": len(row["emitted_kernels"]), "command": command,
                  "returncode": process.returncode, "timed_out": timed_out, "seconds": time.monotonic() - start,
                  "status": parse_status(process.returncode, timed_out, text),
                  "stdout_sha256": sha(destination / "parse.stdout"), "stderr_sha256": sha(destination / "parse.stderr"),
                  "first_diagnostic": next(iter(text.splitlines()), "")}
        write(destination / "parse.json", result)
        return result

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        results = sorted(pool.map(run, sorted(modules.items())), key=lambda row: row["id"])
    inventory.require(sha(binary) == binary_sha256, "binary changed during replay")
    current, _, _ = load_attempts(campaign, document)
    inventory.require(current == reports, "original reports changed during replay")
    result = {"schema_version": 1, "scope": "Whole original MC-accepted module parse replay only; no launch or verification inference.",
              "analysis_revision": revision, "binary_sha256": binary_sha256,
              "reports": {name: {"sha256": bound["sha256"], "source_revision": document["revision"]}
                          for name, bound in reports.items()},
              "probes": len(selected), "modules": len(modules),
              "entry_occurrences": sum(row["emitted_entry_occurrences"] for row in results),
              "outcomes": dict(sorted(Counter(row["status"] for row in results).items())), "results": results}
    write(output / "report.json", result)
    return result


def validate_replay(path, reports, selected):
    report = read(path / "report.json")
    modules = accepted(selected)
    rows = unique(report["results"], lambda row: row["id"], "replayed module")
    inventory.require(set(rows) == set(modules), "replay omits or adds accepted original module")
    for name, bound in reports.items():
        inventory.require(report["reports"][name]["sha256"] == bound["sha256"], "replay report binding drift")
    binaries = set()
    for identity, result in rows.items():
        origin, row, directory = modules[identity]
        inventory.require(read(path / identity / "parse.json") == result, "replay stage differs from report")
        for key, value in (("source", row["source"]), ("target", row["profile"]["target"]),
                           ("attempt_origin", origin), ("assembly_sha256", row["assembly_sha256"]),
                           ("object_sha256", row["object_sha256"]), ("metadata_sha256", digest(row["emitted_kernels"])),
                           ("emitted_entry_occurrences", len(row["emitted_kernels"]))):
            inventory.require(result[key] == value, "replayed module binding differs: " + key)
        stdout = path / identity / "parse.stdout"
        stderr = path / identity / "parse.stderr"
        inventory.require(sha(stdout) == result["stdout_sha256"] and sha(stderr) == result["stderr_sha256"], "parse log drift")
        text = stderr.read_bytes().decode(errors="replace")
        inventory.require(result["status"] == parse_status(result["returncode"], result["timed_out"], text), "parse classification differs")
        inventory.require(result["first_diagnostic"] == next(iter(text.splitlines()), ""), "parse diagnostic differs")
        args = result["command"]
        inventory.require(len(args) == 8 and args[1:7] == ["--no-log-file", "--backend", "amdgpu", "--target", result["target"], "parse"]
                          and Path(args[-1]).resolve() == (directory / "kernel.s").resolve(), "replay command is not exact whole-module parse")
        binaries.add(args[0])
        if result["status"] == "parsed":
            inventory.require("Parsed successfully:" in stdout.read_text() and "Entries (kernels):" in stdout.read_text(), "missing parser success output")
    inventory.require(len(binaries) == 1 and sha(Path(next(iter(binaries)))) == report["binary_sha256"], "replay binary drift")
    inventory.require(report["probes"] == len(selected) and report["modules"] == len(modules)
                      and report["entry_occurrences"] == sum(len(row[1]["emitted_kernels"]) for row in modules.values()), "replay cardinality differs")
    inventory.require(report["outcomes"] == dict(Counter(row["status"] for row in rows.values())), "replay outcome totals differ")
    return report, rows


def definition_id(row):
    return row["source"] + ":" + str(row["line"])


def symbol_name(symbol):
    """Decode only an unqualified Itanium source-name prefix, not templates/types."""
    match = re.match(r"_ZL?(\d+)", symbol)
    if match:
        length = int(match[1])
        name = symbol[match.end():match.end() + length]
        return name if len(name) == length and re.fullmatch(r"[A-Za-z_]\w*", name) else None
    if symbol.startswith("_Z"):
        return None
    return symbol if re.fullmatch(r"[A-Za-z_]\w*", symbol) else None


def include_closure(source, edges):
    seen, pending = set(), [source]
    while pending:
        current = pending.pop()
        if current not in seen:
            seen.add(current)
            pending.extend(edges.get(current, []))
    return seen


def definition_candidates(name, source, definitions, closure):
    local = [row for row in definitions if row["name"] == name and row["source"] in closure]
    if len(local) == 1:
        return "relative_literal_include_candidate", [definition_id(local[0])]
    if local:
        return "ambiguous_relative_literal_include_candidates", sorted(definition_id(row) for row in local)
    global_rows = [row for row in definitions if row["name"] == name]
    if len(global_rows) == 1:
        return "unique_lexical_name_candidate", [definition_id(global_rows[0])]
    return "unresolved" if not global_rows else "ambiguous_lexical_name_candidates", sorted(definition_id(row) for row in global_rows)


def blocker(result, assembly):
    """Publish numeric source location/opcode, never arbitrary diagnostic text."""
    match = re.search(r": (\d+):(\d+): (.*)", result["first_diagnostic"])
    if not match:
        return {"category": result["status"]}
    line, column, message = int(match[1]), int(match[2]), match[3]
    lines = assembly.read_text().splitlines()
    inventory.require(1 <= line <= len(lines), "parser location outside complete assembly")
    instruction = lines[line - 1].strip()
    opcode = re.match(r"([.A-Za-z_][.A-Za-z_0-9]*)", instruction)
    if "only integer assembly constants" in message:
        category = "noninteger_assembly_constant"
    elif "expects" in message and "operands" in message:
        category = "operand_profile"
    elif "unsupported AMD instruction" in message:
        category = "unsupported_instruction"
    else:
        category = "selected_profile_or_grammar"
    symbols = re.findall(r"(?m)^\s*\.type\s+([^,\s]+),\s*@function\s*$", "\n".join(lines[:line]))
    return {"category": category, "line": line, "column": column,
            "opcode_or_directive": opcode[1] if opcode else None,
            "assembly_line_sha256": inventory.sha(lines[line - 1].encode()),
            "preceding_function": symbols[-1] if symbols else None}


def proof_index(path, document, selected):
    """Import separately reviewed, revision-labeled proof evidence, never upgrade parses."""
    proof = read(path)
    inventory.require(proof["upstream"]["revision"] == document["revision"], "proof source revision differs")
    modules = {row[1]["source"]: row[1] for row in accepted(selected).values()}
    result = {}
    for family in proof["families"]:
        row = modules.get(family["source"])
        inventory.require(row is not None and row["profile"]["target"] == "gfx950", "proof module absent from accepted frontier")
        for source, bound in family["source_sha256"].items():
            inventory.require(document["source_sha256"].get(source) == bound, "proof source dependency drift")
        for key in ("assembly", "object"):
            inventory.require(family["shared_input_sha256"][key] == row[key + "_sha256"], "proof module identity differs")
        cases = unique(family["results"], lambda case: case["kernel"], "proof specialization")
        inventory.require(len(cases) == family["cases"] and set(cases) == {k[".name"] for k in row["emitted_kernels"]},
                          "proof selection omits/adds module specialization")
        inventory.require(dict(Counter(case["candidate"]["status"] for case in cases.values())) == family["outcomes"]["candidate"],
                          "proof outcome counts differ")
        for symbol, case in cases.items():
            state = case["candidate"]
            inventory.require(state["status"] != "verified" or (state["full_output_math_proved"] is True
                              and state["returncode"] == 0 and state["process_status"] == "succeeded"), "incomplete proof called verified")
            key = (family["source"], symbol)
            inventory.require(key not in result, "duplicate imported launch contract")
            result[key] = {"receipt_sha256": sha(path), "report_sha256": family["candidate_report_sha256"],
                           "verifier_revision": proof["verifiers"]["candidate"]["revision"],
                           "binary_sha256": proof["verifiers"]["candidate"]["binary_sha256"],
                           "case": case["id"], "elements": case["elements"], "launch_sha256": case["launch_sha256"],
                           "spec_sha256": family["spec_sha256"], "status": state["status"],
                           "full_output_math_proved": state["full_output_math_proved"]}
    return result


def summarize(campaign, replay_directory, document, proof_path):
    reports, attempts, selected = load_attempts(campaign, document)
    parse_report, parses = validate_replay(replay_directory, reports, selected)
    proofs = proof_index(proof_path, document, selected)
    definitions = [row for row in document["kernels"] if row["definition"]]
    unique(definitions, definition_id, "lexical definition")
    edges = defaultdict(list)
    for edge in document["literal_include_edges"]:
        edges[edge["source"]].append(edge["included_source"])
    definition_rows = {definition_id(row): {"id": definition_id(row), "source": row["source"], "line": row["line"],
                       "name": row["name"], "scope": row["scope"], "source_role": document["source_roles"][row["source"]],
                       "declaration_sha256": row["declaration_sha256"],
                       "profiles": [{"target": p["target"], "direct_probe": probe_id(row["source"], p["target"])
                                     if probe_id(row["source"], p["target"]) in selected else None,
                                     "lexically_reachable_probes": [], "entry_candidates": []} for p in row["profiles"]]}
                       for row in definitions}
    probes, mapping_counts = [], Counter()
    for identity in sorted(selected):
        origin, row, directory = selected[identity]
        unit, profile = probe_universe(document)[identity]
        parse = parses.get(identity)
        entries = []
        closure = include_closure(row["source"], edges)
        for definition in definition_rows.values():
            if definition["source"] in closure:
                for reference in definition["profiles"]:
                    if reference["target"] == profile["target"]:
                        reference["lexically_reachable_probes"].append(identity)
        for ordinal, metadata in enumerate(row.get("emitted_kernels", []) if identity in parses else []):
            symbol = metadata[".name"]
            basis, candidates = definition_candidates(symbol_name(symbol), row["source"], definitions, closure)
            mapping_counts[basis] += 1
            entry = {"ordinal": ordinal, "symbol": symbol, "metadata_sha256": digest(metadata),
                     "definition_relation": basis, "definition_candidates": candidates,
                     "launch_contract": "required", "verification": "not_run"}
            historical = proofs.get((row["source"], symbol))
            if historical:
                entry.update(launch_contract="recorded", verification="separate_revision_evidence", evidence=historical)
            entries.append(entry)
            for candidate in candidates:
                for reference in definition_rows[candidate]["profiles"]:
                    if reference["target"] == profile["target"]:
                        reference["entry_candidates"].append({"probe": identity, "ordinal": ordinal, "relation": basis})
        attempt_rows = []
        for attempt_origin, attempt, attempt_directory in attempts[identity]:
            stages = {}
            for name in ("recipe", "compile", "assemble", "parse", "analyze"):
                stage_path = attempt_directory / (name + ".json")
                if stage_path.is_file():
                    stage = read(stage_path)
                    stages[name] = {"record_sha256": sha(stage_path), "status": stage["status"],
                                    "returncode": stage.get("returncode")}
                    for stream in ("stdout", "stderr"):
                        log = attempt_directory / (name + "." + stream)
                        if log.is_file():
                            stages[name][stream + "_sha256"] = sha(log)
            attempt_rows.append({"origin": attempt_origin, "result_sha256": sha(attempt_directory / "result.json"),
                                 "status": attempt["status"], "analysis_status": attempt["analysis"]["status"],
                                 "emitted_entries": len(attempt.get("emitted_kernels", [])),
                                 "assembly_sha256": attempt.get("assembly_sha256"), "object_sha256": attempt.get("object_sha256"),
                                 "process_stages": stages})
        record = {"id": identity, "source": row["source"], "source_sha256": row["source_sha256"],
                  "target": profile["target"], "source_role": unit["source_role"], "scope": unit["scope"],
                  "attempts": attempt_rows, "selected_attempt": origin, "selected_status": row["status"],
                  "parse": {"status": "not_reached"}, "entries": entries}
        if parse:
            record["parse"] = {key: parse[key] for key in ("status", "returncode", "stdout_sha256", "stderr_sha256")}
            record["parse"]["stage_sha256"] = sha(replay_directory / identity / "parse.json")
            if parse["status"] == "parsed":
                count = re.search(r"Entries \(kernels\): (\d+)", (replay_directory / identity / "parse.stdout").read_text())
                inventory.require(count is not None, "missing parser entry count")
                record["parse"]["reported_parser_entries"] = int(count[1])
            if parse["status"] != "parsed":
                record["parse"]["first_blocker"] = blocker(parse, directory / "kernel.s")
        probes.append(record)
    for definition in definition_rows.values():
        for reference in definition["profiles"]:
            reference["disposition"] = ("emitted_name_candidates" if reference["entry_candidates"] else
                                        "no_entry_candidate_observed")
    summary = {"lexical_definitions": len(definitions),
               "definition_target_references": sum(len(row["profiles"]) for row in definitions),
               "source_profile_probes": len(probes), "preserved_compiler_attempts": sum(len(rows) for rows in attempts.values()),
               "accepted_nonempty_modules": len(parses), "emitted_entry_occurrences": sum(len(row["entries"]) for row in probes),
               "parse_modules": dict(sorted(Counter(row["status"] for row in parses.values()).items())),
               "selected_compiler_attempt_status": dict(sorted(Counter(row["selected_status"] for row in probes).items())),
               "definition_relations": dict(sorted(mapping_counts.items())),
               "imported_launch_contracts": len(proofs),
               "separate_revision_verification": dict(sorted(Counter(row["status"] for row in proofs.values()).items()))}
    return {"schema_version": 1, "scope": "All pinned lexical definitions and source/profile probes; whole original module parse replay, with separately revision-labeled existing launch evidence.",
            "upstream": {"repository": document["repository"], "revision": document["revision"], "tree": document["tree"]},
            "inventory_sha256": digest(document), "inventory_hash_encoding": "canonical-json-sha256",
            "generator_sha256": sha(Path(__file__)), "compiler_reports": reports,
            "parse_replay": {"report_sha256": sha(replay_directory / "report.json"), "revision": parse_report["analysis_revision"],
                             "binary_sha256": parse_report["binary_sha256"]},
            "limits": ["Definitions, target references, source probes and emitted entry occurrences are distinct populations.",
                       "Every original and recipe-followup attempt is retained; selected_attempt identifies only the latest explicit attempt.",
                       "Source-name/include relations are lexical candidates, not preprocessor or C++ instantiation proofs; conditional includes and uninstantiated definitions remain explicit.",
                       "A first parser blocker applies to the whole module, not separately to every emitted entry.",
                       "Parse replay does not execute or prove kernels. Existing launch evidence is separately labeled with its actual verifier revision; not_run is not a verifier refusal.",
                       "No GPU, latency measurement or whole-grid proof is performed by this report."],
            "summary": summary, "definitions": list(definition_rows.values()), "probes": probes}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--source-root", type=Path, default=inventory.DEFAULT_SOURCE)
    sub = parser.add_subparsers(dest="mode", required=True)
    collect = sub.add_parser("replay", help="Parse every original MC-accepted nonempty module, without launch")
    collect.add_argument("--campaign", type=Path, required=True)
    collect.add_argument("--binary", type=Path, required=True)
    collect.add_argument("--binary-revision", required=True)
    collect.add_argument("--binary-sha256", required=True)
    collect.add_argument("--output", type=Path, required=True)
    collect.add_argument("--jobs", type=int, default=2)
    collect.add_argument("--timeout", type=float, default=60)
    join = sub.add_parser("summarize", help="Validate immutable raw records and emit a portable frontier")
    join.add_argument("--campaign", type=Path, required=True)
    join.add_argument("--replay", type=Path, required=True)
    join.add_argument("--proofs", type=Path, default=DEFAULT_PROOFS)
    join.add_argument("--output", type=Path, default=DEFAULT_LEDGER)
    join.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        document = read(args.inventory)
        inventory.require(document == inventory.build_inventory(args.source_root.resolve()), "tracked source inventory drift")
        if args.mode == "replay":
            inventory.require(args.jobs > 0 and args.timeout > 0, "positive jobs/timeout required")
            inventory.require(re.fullmatch(r"[0-9a-f]{40}", args.binary_revision) is not None
                              and re.fullmatch(r"[0-9a-f]{64}", args.binary_sha256) is not None, "full source/binary identity required")
            result = replay(args.campaign.resolve(), document, args.binary.resolve(), args.binary_revision,
                            args.binary_sha256, args.output.resolve(), args.jobs, args.timeout)
            print(json.dumps(result["outcomes"], indent=2))
        else:
            result = summarize(args.campaign.resolve(), args.replay.resolve(), document, args.proofs)
            if args.check:
                inventory.require(read(args.output) == result, "frontier drift; regenerate explicitly")
            else:
                write(args.output, result)
            print(json.dumps(result["summary"], indent=2))
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
