#!/usr/bin/env python3
"""Replay one unchanged HipKittens gfx950 LDS copy, or check retained records."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess

ROOT = Path(__file__).resolve().parent
MASK = 2**64 - 1
PROPERTIES = (
    "AMD trace completeness",
    "AMD wait and register readiness",
    "AMD workgroup barrier generations",
    "AMD memory-conflict freedom",
)
STOP = "opaque shared aperture cannot be used as ordinary bits"
PINS = {
    "fixtures/original.s": "5cd06ff39ac43a8178c89d570361a5329c39b0d2077020438fbc93701ffe9542",
    "launch.json": "3e1054f80948e9cafe11a8ca008c097939b8b5a44955ba585104ddfaab67150b",
    "identity.spec": "dfaaf87789dfec7bcaadc0e1a4dd9863575540ed223799561770c53ea60b438b",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def inputs(root=ROOT):
    inventory = json.loads((root / "checksums.json").read_text())
    actual = {
        p.relative_to(root).as_posix()
        for p in root.rglob("*")
        if p.is_file()
        and not {"__pycache__", ".ruff_cache"}.intersection(p.relative_to(root).parts)
        and p != root / "checksums.json"
    }
    require(set(inventory) == actual, "package inventory changed")
    for name, digest in inventory.items():
        path = (root / name).resolve(strict=True)
        require(path.is_relative_to(root.resolve()), "input escapes package")
        require(sha(path) == digest, "package input changed: " + name)
    require(
        all(inventory.get(k) == v for k, v in PINS.items()), "original pins changed"
    )
    return {name: sha(root / name) for name in inventory}


def check_identity(text):
    lines = text.splitlines()
    require(lines and lines[0] == "volta-expr 1", "expression header changed")
    nodes, roots = {}, {}
    for line in lines[1:]:
        node = re.fullmatch(r'n(\d+) = elem "x" (\d+)', line)
        out = re.fullmatch(r'out "out" (\d+) n(\d+)', line)
        if node:
            identity, index = map(int, node.groups())
            require(identity not in nodes and not roots, "duplicate/late node")
            nodes[identity] = index
        elif out:
            index, identity = map(int, out.groups())
            require(index not in roots and identity in nodes, "duplicate/dangling root")
            roots[index] = identity
        else:
            raise ValueError("unexpected expression record")
    require(
        len(nodes) == 64 and set(nodes.values()) == set(range(64)), "input footprint"
    )
    require(set(roots) == set(range(64)), "output footprint")
    require(all(nodes[n] == i for i, n in roots.items()), "non-identity root")


def check_transcript(stdout, stderr, code, baseline, verify):
    require(code == (2 if baseline else 0), "unexpected exit code")
    require(
        not re.search(
            r"MemoryConflict\s*\{|ReadBeforeReady|WriteBeforeReady|DestinationReuse|"
            r"AmdBarrierViolation|AmdRegisterHazard|EARLY_[A-Z_]+:|\bFAIL\b|\bREJECT(?:ED)?\b|"
            r"\bpanic(?:ked)?\b|unsupported AMD instruction|NOT EQUIVALENT",
            stdout + "\n" + stderr,
            re.I,
        ),
        "contradictory safety/error diagnostic",
    )
    require(
        not stderr
        if verify
        else bool(re.fullmatch(r"Wrote event graph to [^\n]+\n", stderr)),
        "unexpected stderr",
    )
    rows = re.findall(r"^  (AMD [^\n]+) \([^\n]*\) +(PASS|FAIL|UNKNOWN)$", stdout, re.M)
    require(
        len(rows) == 4 and {name for name, _ in rows} == set(PROPERTIES),
        "property population changed",
    )
    require(all(status == "PASS" for _, status in rows), "non-PASS property")
    require(
        re.findall(r"instructions: (\d+)", stdout) == ["25" if baseline else "31"],
        "instruction count changed",
    )
    require(
        re.findall(r"block syncs: (\d+)", stdout) == ["0" if baseline else "1"],
        "barrier count changed",
    )
    marker = "VERDICT" if verify else "GRAPH VERIFICATION"
    expected = "UNKNOWN" if baseline else ("ACCEPT" if verify else "VERIFIED")
    if not verify:
        expected += " (no equivalence check requested)"
    require(
        re.findall(r"^" + marker + r": (.*)$", stdout, re.M) == [expected],
        "overall conclusion changed",
    )
    require(
        not re.search(r"^(?:GRAPH VERIFICATION|VERDICT):", stdout, re.M)
        or not re.search(
            r"^" + ("GRAPH VERIFICATION" if verify else "VERDICT") + ":", stdout, re.M
        ),
        "contradictory overall endpoint",
    )
    equivalence_details = re.findall(r"^  equivalence: (.*)$", stdout, re.M)
    if not verify:
        require(not equivalence_details, "unexpected equivalence detail in analyze")
    if baseline:
        if verify:
            require(
                equivalence_details
                == [
                    "not decided: kernel: execution stopped: wave 0 lane Some(0), pc 24: "
                    + STOP
                ],
                "baseline equivalence detail changed",
            )
        require(
            STOP in stdout and "pc 24:" in stdout and "only a prefix:" in stdout,
            "baseline refusal changed",
        )
        require(
            "EQUIVALENT" not in stdout and "VC check:" not in stdout,
            "prefix received an equivalence result",
        )
        require(
            not re.search(r"^\s*out\[|element\(s\) written", stdout, re.M),
            "prefix has output values",
        )
    else:
        require(
            not re.search(
                r"execution stopped|only a prefix|aborted|no outputs|"
                r"\bUNKNOWN\b|outputs unavailable|\berror\b",
                stdout + stderr,
                re.I,
            ),
            "incomplete execution",
        )
        if verify:
            require(
                stdout.splitlines().count("EQUIVALENT (matches spec)") == 1,
                "complete equivalence missing",
            )
            require(
                len(re.findall(r"^VC check: [^\n]*  elements: 64$", stdout, re.M)) == 1,
                "VC footprint changed",
            )
            require(
                equivalence_details == ["all 64 compared elements proved equivalent"],
                "proof population or equivalence detail changed",
            )
        else:
            rows = re.findall(r"^    out\[(\d+)\] = x\[(\d+)\]$", stdout, re.M)
            require(
                rows == [(str(i), str(i)) for i in range(64)], "printed roots changed"
            )
            require(
                stdout.count("output 'out': 64 element(s) written") == 1,
                "printed output footprint changed",
            )
            require(
                len(re.findall(r"^\s*out\[", stdout, re.M)) == 64,
                "unexpected printed output",
            )


def check_graph(text, kernel, baseline):
    lines = text.splitlines()
    require(
        lines[:2]
        == [
            "volta-graph 2",
            f'kernel "{kernel}" block 64,1,1 grid 1,1,1 workgroup 0,0,0 targets gfx950',
        ],
        "graph geometry/kernel changed",
    )
    expected_assumptions = {
        "StructuredCta",
        "SingleWorkgroupAnalyzed",
        "MathematicalRealArithmetic",
        "EagerAsyncData",
        "XnackReplayDisabled",
        "SingleCuWorkgroup",
        "ConfiguredLdsBytes(80000)",
    }
    assumptions = [line[7:] for line in lines if line.startswith("assume ")]
    require(
        len(assumptions) == len(expected_assumptions)
        and set(assumptions) == expected_assumptions,
        "graph assumptions changed",
    )
    events, instructions, effects, links = {}, [], {}, []
    for line in lines:
        event = re.fullmatch(r"e(\d+) t(\d+) pc(\d+) (.+)", line)
        link = re.fullmatch(r"amd-memory issue=e(\d+) effect=e(\d+)", line)
        if event:
            identity, thread, pc = map(int, event.groups()[:3])
            body = event[4]
            require(
                identity not in events and thread < 64, "duplicate/out-of-launch event"
            )
            events[identity] = (thread, pc, body)
            if body.startswith("amd wave=0 Instruction {"):
                require(
                    thread == 0 and f"exec_mask: {MASK}," in body,
                    "instruction EXEC changed",
                )
                instructions.append(pc)
            effect = re.fullmatch(
                r"(read|write) ordinary generic (global|shared) Plain by t(\d+) \[0x([0-9a-f]+),\+4\)(?: = n(\d+))?",
                body,
            )
            if effect:
                kind, space, lane, address, value = effect.groups()
                require(int(lane) == thread, "effect owner changed")
                effects[identity] = (pc, kind, space, thread, int(address, 16), value)
        elif link:
            links.append(tuple(map(int, link.groups())))
    require(list(events) == list(range(len(events))), "event IDs/order changed")
    require(
        instructions == list(range(25 if baseline else 31)),
        "incomplete/duplicate PC trace",
    )
    require(
        all(pc < (25 if baseline else 31) for _, pc, _ in events.values()),
        "event beyond terminal PC",
    )
    terminals = [line for line in lines if line.startswith("terminal ")]
    require(
        terminals
        == ["terminal aborted error t0 pc24: wave 0 lane Some(0), pc 24: " + STOP]
        if baseline
        else terminals == ["terminal completed"],
        "terminal changed",
    )
    require(lines[-1] == terminals[0], "records after terminal")
    require(len(links) == len(set(links)), "duplicate memory link")

    def one(pc, body):
        hits = [
            eid
            for eid, (thread, event_pc, event_body) in events.items()
            if thread == 0 and event_pc == pc and event_body == "amd wave=0 " + body
        ]
        require(len(hits) == 1, "missing/duplicate semantic record at pc" + str(pc))
        return hits[0]

    def footprint(issue, pc, kind, space, base):
        matched = {
            eid: value
            for eid, value in effects.items()
            if value[:3] == (pc, kind, space)
        }
        require(len(matched) == 64, "effect cardinality changed")
        require(
            {v[3] for v in matched.values()} == set(range(64)),
            "effect lane coverage changed",
        )
        require(
            all(v[4] == base + 4 * v[3] for v in matched.values()),
            "effect address changed",
        )
        require(
            all(links.count((issue, eid)) == 1 for eid in matched), "unlinked effect"
        )
        return {v[3]: v[5] for v in matched.values()}

    one(20, "Wait { vmcnt: None, lgkmcnt: Some(0), expcnt: None }")
    dma = one(
        21,
        "MemoryIssue { class: BufferLoadToLds32, counters: [(Vm, 1)], destinations: [], held_sources: [] }",
    )
    footprint(dma, 21, "read", "global", 65536)
    written = footprint(dma, 21, "write", "shared", 0)
    require(all(v is not None for v in written.values()), "DMA payload missing")
    if not baseline:
        one(25, "Wait { vmcnt: Some(0), lgkmcnt: Some(0), expcnt: Some(0) }")
        one(26, f"BarrierArrive {{ generation: 0, exec_mask: {MASK} }}")
        one(26, "BarrierRelease { generation: 0 }")
        flat = one(
            27,
            f"MemoryIssue {{ class: Flat, counters: [(Vm, 1), (Lgkm, 1)], destinations: [AmdRegister {{ file: Vector, index: 1, lanes: {MASK} }}], held_sources: [] }}",
        )
        footprint(flat, 27, "read", "shared", 0)
        one(28, "Wait { vmcnt: Some(0), lgkmcnt: Some(0), expcnt: None }")
        store = one(
            29,
            "MemoryIssue { class: VectorMemory, counters: [(Vm, 1)], destinations: [], held_sources: [] }",
        )
        require(
            footprint(store, 29, "write", "global", 131072) == written,
            "stored expression transport changed",
        )
        one(30, "Wait { vmcnt: Some(0), lgkmcnt: Some(0), expcnt: Some(0) }")
        exits = [(thread, pc) for thread, pc, body in events.values() if body == "exit"]
        require(exits == [(i, 30) for i in range(64)], "incomplete lane exits")


def check_artifacts(directory, kernel, baseline):
    check_graph((directory / "original.graph").read_text(), kernel, baseline)
    expr = directory / "original.vexpr"
    if baseline:
        require(not expr.exists(), "baseline unexpectedly exports outputs")
    else:
        check_identity(expr.read_text())


def check_recorded(root=ROOT):
    before = inputs(root)
    manifest = json.loads((root / "manifest.json").read_text())
    for role in ("baseline", "candidate"):
        directory = root / "results" / role
        report_path = directory / "report.json"
        require(
            sha(report_path) == manifest["roles"][role]["captured_report_sha256"],
            "capture report changed",
        )
        report = json.loads(report_path.read_text())
        require(
            report["binary_sha256"] == manifest["roles"][role]["binary_sha256"],
            "captured binary mismatch",
        )
        require(
            report["build_record_sha256"]
            == manifest["roles"][role]["build_record_sha256"],
            "captured build mismatch",
        )
        for key in ("assembly_sha256", "launch_sha256", "spec_sha256"):
            require(report[key] == manifest[key], "captured input mismatch")
        require(len(report["runs"]) == 2, "process population changed")
        for command, record in zip(("verify", "analyze"), report["runs"]):
            require(record["argv"][1] == command, "captured command changed")
            for suffix in ("stdout", "stderr"):
                require(
                    sha(directory / f"{command}.{suffix}")
                    == record[suffix + "_sha256"],
                    "raw transcript changed",
                )
            check_transcript(
                (directory / f"{command}.stdout").read_text(),
                (directory / f"{command}.stderr").read_text(),
                record["exit_code"],
                role == "baseline",
                command == "verify",
            )
        for name, digest in report["artifacts"].items():
            require(sha(directory / name) == digest, "captured artifact changed")
        check_artifacts(directory, manifest["kernel"], role == "baseline")
    require(inputs(root) == before, "package changed during validation")


def capture(command, directory, name):
    child = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True
    )
    timeout = False
    try:
        stdout, stderr = child.communicate(timeout=60)
    except subprocess.TimeoutExpired:
        timeout = True
        os.killpg(child.pid, signal.SIGKILL)
        stdout, stderr = child.communicate()
    for suffix, data in (("stdout", stdout), ("stderr", stderr)):
        (directory / f"{name}.{suffix}").write_bytes(data)
    record = {
        "command": command,
        "exit_code": child.returncode,
        "timed_out": timeout,
        "stdout_sha256": sha(directory / f"{name}.stdout"),
        "stderr_sha256": sha(directory / f"{name}.stderr"),
    }
    write_json(directory / f"{name}.json", record)
    require(not timeout, "60-second process budget exceeded")
    return record, stdout.decode("utf-8"), stderr.decode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--baseline", action="store_true")
    parser.add_argument("--check-recorded", action="store_true")
    args = parser.parse_args()
    if args.check_recorded:
        require(
            not args.binary and not args.output and not args.baseline,
            "check-recorded does not execute binaries",
        )
        check_recorded()
        print("Retained before/after records match the complete contract.")
        return
    require(args.binary and args.output, "--binary and --output are required")
    before = inputs()
    binary = args.binary.resolve(strict=True)
    binary_sha = sha(binary)
    output = args.output.resolve()
    require(
        not output.is_relative_to(ROOT) and not ROOT.is_relative_to(output),
        "output aliases package",
    )
    require(not binary.is_relative_to(output), "output aliases binary")
    output.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((ROOT / "manifest.json").read_text())
    result = {
        "schema": 1,
        "baseline": args.baseline,
        "binary_sha256": binary_sha,
        "input_sha256": before,
        "runs": [],
        "passed": False,
        "trust": "User-supplied binary; hashes do not prove its source/build association.",
    }
    try:
        common = [
            "--config",
            str(ROOT / "launch.json"),
            "--backend",
            "amdgpu",
            "--target",
            "gfx950",
            "--no-log-file",
        ]
        for command in ("verify", "analyze"):
            argv = [str(binary), command, str(ROOT / "fixtures/original.s")]
            if command == "verify":
                argv += (
                    [str(ROOT / "identity.spec")]
                    + common
                    + ["--dim", "N=64", "--sample", "0", "--verify-numeric"]
                )
            else:
                argv += common + [
                    "--print-outputs",
                    "64",
                    "--dump-graph",
                    str(output / "original.graph"),
                    "--emit-exprs",
                    str(output / "original.vexpr"),
                ]
            record, stdout, stderr = capture(argv, output, command)
            result["runs"].append(record)
            check_transcript(
                stdout, stderr, record["exit_code"], args.baseline, command == "verify"
            )
        check_artifacts(output, manifest["kernel"], args.baseline)
        require(
            sha(binary) == binary_sha and inputs() == before,
            "binary/package changed during execution",
        )
        result["artifacts"] = {
            p.name: sha(p) for p in output.iterdir() if p.suffix in (".graph", ".vexpr")
        }
        result["passed"] = True
    except (OSError, ValueError) as error:
        result["error"] = str(error)
        raise
    finally:
        write_json(output / "report.json", result)
    print("Expected full-original outcome retained; no performance or hardware claim.")


if __name__ == "__main__":
    main()
