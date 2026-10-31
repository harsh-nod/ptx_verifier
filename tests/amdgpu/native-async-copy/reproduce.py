#!/usr/bin/env python3
"""Replay the complete original async-copy case and its separate wait repair."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parent


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def run(command, stem):
    started = time.perf_counter_ns()
    timed_out = False
    try:
        result = subprocess.run(command, capture_output=True, timeout=60)
        stdout, stderr, code = result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired as error:
        stdout, stderr, code = error.stdout or b"", error.stderr or b"", None
        timed_out = True
    stem.with_suffix(".stdout").write_bytes(stdout)
    stem.with_suffix(".stderr").write_bytes(stderr)
    record = {
        "command": command,
        "returncode": code,
        "timed_out": timed_out,
        "elapsed_ns": time.perf_counter_ns() - started,
        "stdout_sha256": sha(stem.with_suffix(".stdout")),
        "stderr_sha256": sha(stem.with_suffix(".stderr")),
    }
    write_json(stem.with_suffix(".json"), record)
    return record, stdout.decode("utf-8"), stderr.decode("utf-8")


def check_identity(path):
    lines = path.read_text().splitlines()
    require(lines and lines[0] == "volta-expr 1", "expression header changed")
    nodes, outputs = {}, {}
    for line in lines[1:]:
        node = re.fullmatch(r'n(\d+) = elem "x" (\d+)', line)
        output = re.fullmatch(r'out "out" (\d+) n(\d+)', line)
        if node:
            identity, index = map(int, node.groups())
            require(identity not in nodes, "duplicate node definition")
            require(not outputs, "node definition follows output roots")
            nodes[identity] = index
        elif output:
            index, identity = map(int, output.groups())
            require(index not in outputs, "duplicate output coordinate")
            require(identity in nodes, "output references an undefined node")
            outputs[index] = identity
        else:
            raise ValueError("unrecognized expression record: " + line)
    require(
        len(nodes) == 256 and set(nodes.values()) == set(range(256)),
        "input nodes changed",
    )
    require(set(outputs) == set(range(256)), "output footprint changed")
    require(
        all(nodes[node] == index for index, node in outputs.items()),
        "identity roots changed",
    )


def check_safety(stdout, arm, verify):
    require(
        not any(
            diagnostic in stdout.lower()
            for diagnostic in (
                "execution stopped:",
                "unsupported amd instruction",
                "trace generator aborted",
                "only a prefix",
                "no outputs:",
                "outputs unavailable",
                "terminal aborted",
            )
        ),
        "execution did not complete",
    )
    if arm == "repair":
        require(
            "MemoryConflict {" not in stdout, "repair still reports a typed conflict"
        )
    properties = [
        "AMD trace completeness",
        "AMD wait and register readiness",
        "AMD workgroup barrier generations",
        "AMD memory-conflict freedom",
    ]
    rows = re.findall(r"^  (AMD [^\n]+) \([^\n]*\) +(PASS|FAIL|UNKNOWN)$", stdout, re.M)
    require(len(rows) == 4, "safety property population changed")
    require({name for name, _ in rows} == set(properties), "safety properties changed")
    for name in properties:
        expected = "FAIL" if arm == "original" and name == properties[-1] else "PASS"
        require(
            [status for key, status in rows if key == name] == [expected],
            "safety property result changed: " + name,
        )
    if verify:
        markers = re.findall(r"^VERDICT: (.*)$", stdout, re.M)
        require(
            markers == ["REJECT" if arm == "original" else "ACCEPT"], "verdict changed"
        )
    else:
        markers = re.findall(r"^GRAPH VERIFICATION: (.*)$", stdout, re.M)
        expected = "REJECTED" if arm == "original" else "VERIFIED"
        require(
            markers == [expected + " (no equivalence check requested)"],
            "graph verdict changed",
        )
    if arm == "original":
        witnesses = re.findall(
            r"^ +MemoryConflict \{ kind: WriteRead, location: ByteLocation \{ space: Shared, addr: 0 \}, "
            r"earlier: EventId\((\d+)\), later: EventId\((\d+)\) \}$",
            stdout,
            re.M,
        )
        require(len(witnesses) == 1, "missing unique typed Shared byte-zero witness")
        earlier, later = witnesses[0]
        require(
            re.search(
                r"^ +e" + earlier + r" t\d+ +line \d+: global_load_async_to_lds_b128 ",
                stdout,
                re.M,
            ),
            "witness producer changed",
        )
        require(
            re.search(r"^ +e" + later + r" t\d+ +line \d+: ds_read_b64 ", stdout, re.M),
            "witness consumer changed",
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--baseline", action="store_true")
    args = parser.parse_args()
    binary = args.binary.resolve(strict=True)
    output = args.output.resolve()
    manifest = json.loads((ROOT / "manifest.json").read_text())
    contract = json.loads((ROOT / "provenance/manifest.json").read_text())
    launches = {case["dtype"]: case for case in contract["cases"]}
    require(
        sha(ROOT / "identity.spec") == contract["spec_sha256"], "specification changed"
    )
    source = ROOT / manifest["original_assembly"]
    require(
        sha(source) == manifest["original_assembly_sha256"], "original assembly changed"
    )
    output.mkdir(parents=True, exist_ok=False)
    source_text = source.read_text()
    repaired, count = re.subn(
        r"(?m)^(\s*global_load_async_to_lds_b128[^\n]*\n)",
        r"\1\ts_wait_asynccnt 0\n",
        source_text,
    )
    require(count == 2, "expected exactly two original async copies")
    require(
        repaired.replace("\ts_wait_asynccnt 0\n", "") == source_text,
        "repair changed other bytes",
    )
    repair = output / "two-waits-control.s"
    repair.write_text(repaired)
    recorded = json.loads((ROOT / "results/repair/report.json").read_text())
    require(
        sha(repair) == recorded["control_assembly_sha256"], "repair assembly changed"
    )
    records = []
    common = [
        str(binary),
        "--no-log-file",
        "--backend",
        "amdgpu",
        "--target",
        "gfx1250",
    ]
    for dtype, launch_name in manifest["launches"].items():
        launch = ROOT / launch_name
        require(
            sha(launch) == launches[dtype]["launch_sha256"],
            "original launch bytes changed",
        )
        config = json.loads(launch.read_text())
        require(
            config["grid"] == [1, 1, 1] and config["block"] == [32, 1, 1],
            "geometry changed",
        )
        require(config["dynamic_shared_bytes"] == 163840, "LDS extent changed")
        require(
            all(a["shape"] == [256] and a["dtype"] == dtype for a in config["arrays"]),
            "array contract changed",
        )
        for arm, assembly in [("original", source), ("repair", repair)]:
            if args.baseline and arm == "repair":
                continue
            prefix = output / (dtype + "-" + arm)
            command = common + [
                "verify",
                str(assembly),
                str(ROOT / "identity.spec"),
                "--config",
                str(launch),
                "--sample",
                "0",
                "--dim",
                "N=256",
                "--verify-numeric",
                "--no-profile",
            ]
            record, stdout, stderr = run(
                command, prefix.with_name(prefix.name + "-verify")
            )
            records.append(record)
            if args.baseline:
                require(
                    record["returncode"] == 1
                    and "unsupported AMD instruction `global_load_async_to_lds_b128`"
                    in stderr,
                    "baseline refusal changed",
                )
                continue
            require(
                record["returncode"] == (1 if arm == "original" else 0),
                "verification result changed",
            )
            require(
                stdout.splitlines().count("EQUIVALENT (matches spec)") == 1
                and "NOT EQUIVALENT" not in stdout
                and re.search(r"^VC check: [^\n]*  elements: 256$", stdout, re.M),
                "complete specification result changed",
            )
            check_safety(stdout, arm, verify=True)
            expr = prefix.with_suffix(".vexpr")
            graph = prefix.with_suffix(".graph")
            command = common + [
                "analyze",
                str(assembly),
                "--config",
                str(launch),
                "--print-outputs",
                "256",
                "--no-profile",
                "--emit-exprs",
                str(expr),
                "--dump-graph",
                str(graph),
            ]
            record, analysis_stdout, _ = run(
                command, prefix.with_name(prefix.name + "-analyze")
            )
            records.append(record)
            require(
                record["returncode"] == (1 if arm == "original" else 0),
                "analysis result changed",
            )
            check_safety(analysis_stdout, arm, verify=False)
            require(
                [
                    line
                    for line in graph.read_text().splitlines()
                    if line.startswith("terminal ")
                ]
                == ["terminal completed"],
                "execution incomplete",
            )
            check_identity(expr)
        if not args.baseline:
            require(
                (output / (dtype + "-original.vexpr")).read_bytes()
                == (output / (dtype + "-repair.vexpr")).read_bytes(),
                "repair changed outputs",
            )
    require(
        sha(source) == manifest["original_assembly_sha256"],
        "original assembly changed during replay",
    )
    write_json(
        output / "report.json",
        {
            "schema": 1,
            "scope": "CPU-only functional replay; elapsed observations are not speedup estimates.",
            "binary_sha256": sha(binary),
            "binary_trust": "caller supplied",
            "baseline": args.baseline,
            "original_assembly_sha256": sha(source),
            "repair_assembly_sha256": sha(repair),
            "processes": records,
        },
    )
    print(f"Replay passed; full records: {output / 'report.json'}")


if __name__ == "__main__":
    main()
