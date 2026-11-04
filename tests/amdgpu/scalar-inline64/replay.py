#!/usr/bin/env python3
"""Replay complete two-word scalar inline64 controls from checked-in fixtures."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

TARGETS = ("gfx942", "gfx950", "gfx1250")
FIXTURES = Path("crates/volta_amdgpu_analysis/tests/fixtures/scalar-inline64")
FIXTURE_REVISION = "f1a252aae8cc105a2f0d6aa0e696cac6688ba059"
PINS = {
    "gfx942.s": "8165d59d2c796f6f679657f6da07c3a51ee3a718e0dbce69e304b11e6059dfa3",
    "gfx950.s": "76ab5b310b27f51497221e3c2f07f958d0b91ced7375e8d2cb46301c15b029e4",
    "gfx1250.s": "faa0cdbdf23552ab450cbb76d537776745fbd368b6d2879b52694f22440cb016",
    "one.spec": "b0697b64b3180e70ad7455c2316b44cdffb23e6674a98dc6cf6bc3a35cdec7f8",
    **dict.fromkeys(
        (f"{target}.launch.json" for target in TARGETS),
        "77af3f5d44cdaa68575d2f365cd32e19d645189c71296c5a47414f1810e4b5d6",
    ),
}
PROPERTIES = {
    "AMD trace completeness",
    "AMD wait and register readiness",
    "AMD workgroup barrier generations",
    "AMD memory-conflict freedom",
}
CORRECT_WORDS = [0, 1072693248]
BASELINE_WORDS = [1065353216, 0]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n")


def fixture_paths(repo):
    paths = {name: repo / FIXTURES / name for name in PINS}
    require(all(p.is_file() for p in paths.values()), "missing checked-in fixture")
    require(
        all(sha(p) == PINS[name] for name, p in paths.items()), "fixture hash changed"
    )
    return paths


def check_transcript(stdout, stderr, code, target, mode, baseline):
    require(target in TARGETS and mode in ("verify", "analyze"), "invalid case")
    combined = stdout + "\n" + stderr
    require(
        not re.search(
            r"UNKNOWN|\bFAIL\b|\bUNSUPPORTED\b|\bpanic(?:ked)?\b|error:|"
            r"execution stopped:|unsupported AMD instruction|trace generator aborted|"
            r"only a prefix|no outputs:|outputs unavailable|terminal aborted|"
            r"CERTIFIED_REJECTION|MemoryConflict\s*\{|\b[A-Za-z]*ReadBeforeReady\b|"
            r"\b[A-Za-z]*WriteBeforeReady\b",
            combined,
            re.I,
        ),
        "incomplete or contradictory diagnostics",
    )
    if mode == "verify":
        require(not stderr, "unexpected verification stderr")
    else:
        lines = stderr.splitlines()
        require(
            len(lines) == 1
            and lines[0].startswith("Wrote event graph to ")
            and Path(lines[0].removeprefix("Wrote event graph to ")).name
            == f"{target}.graph",
            "unexpected analysis stderr",
        )
    rows = re.findall(
        r"^  (AMD [^\n]+?) \([^\n]*\) +(PASS|FAIL|UNKNOWN)$", stdout, re.M
    )
    require(
        len(rows) == 4 and {name for name, _ in rows} == PROPERTIES,
        "property population changed",
    )
    require(all(status == "PASS" for _, status in rows), "graph property did not pass")
    require(
        len(re.findall(r"^  AMD ", stdout, re.M)) == 4,
        "extra or malformed graph property",
    )
    if mode == "verify":
        require(code == (1 if baseline else 0), "verification process failed")
        require(
            re.findall(r"^VERDICT: (.*)$", stdout, re.M)
            == ["REJECT" if baseline else "ACCEPT"],
            "wrong overall verdict",
        )
        require(
            not re.search(r"^GRAPH VERIFICATION:", stdout, re.M),
            "contradictory graph verdict",
        )
        vc = re.findall(r"^VC check: [^\n]* elements: (\d+)$", stdout, re.M)
        require(vc == ["2"], "incomplete equivalence footprint")
        equivalent = re.findall(r"^(?:NOT )?EQUIVALENT[^\n]*$", stdout, re.M)
        require(
            equivalent
            == [
                "NOT EQUIVALENT: 2 mismatched element(s) vs spec"
                if baseline
                else "EQUIVALENT (matches spec)"
            ],
            "wrong equivalence result",
        )
        mismatches = re.findall(r"^  out\[(\d+)\]$", stdout, re.M)
        require(
            mismatches == (["0", "1"] if baseline else []),
            "mismatch coordinates changed",
        )
        expected_reason = (
            "2 element(s) refuted by a numeric counterexample, first out[0]"
            if baseline
            else "all 2 compared elements proved equivalent"
        )
        require(
            re.findall(r"^  equivalence: (.*)$", stdout, re.M) == [expected_reason],
            "contradictory or incomplete equivalence evidence",
        )
    else:
        require(code == 0, "analysis process failed")
        require(
            re.findall(r"^GRAPH VERIFICATION: (.*)$", stdout, re.M)
            == ["VERIFIED (no equivalence check requested)"],
            "graph did not verify",
        )
        require(
            not re.search(r"^VERDICT:|^VC check:|^(?:NOT )?EQUIVALENT", stdout, re.M),
            "contradictory analysis verdict",
        )
        require(
            re.findall(
                r"^  output '([^']+)': (\d+) element\(s\) written$", stdout, re.M
            )
            == [("out", "2")],
            "analysis output population changed",
        )
        values = re.findall(r"^    out\[(\d+)\] = (\d+)$", stdout, re.M)
        expected = BASELINE_WORDS if baseline else CORRECT_WORDS
        require(
            values == [(str(i), str(value)) for i, value in enumerate(expected)],
            "wrong typed output words",
        )
    counts = re.findall(r"instructions: (\d+)", stdout)
    require(
        counts == ["13" if target == "gfx1250" else "12"], "instruction count changed"
    )


def check_expressions(path, expected):
    lines = path.read_text().splitlines()
    require(lines and lines[0] == "volta-expr 1", "expression header changed")
    nodes, roots = {}, {}
    for line in lines[1:]:
        node = re.fullmatch(r"n(\d+) = int (\d+)", line)
        root = re.fullmatch(r'out "out" (\d+) n(\d+)', line)
        if node:
            identity, value = map(int, node.groups())
            require(
                identity not in nodes and not roots and value <= 0xFFFFFFFF,
                "invalid integer node",
            )
            nodes[identity] = value
        elif root:
            index, identity = map(int, root.groups())
            require(
                index not in roots and identity in nodes,
                "invalid or duplicate output root",
            )
            roots[index] = identity
        else:
            raise ValueError("unexpected expression record")
    require(
        set(roots) == {0, 1} and len(nodes) == 2 and set(roots.values()) == set(nodes),
        "incomplete/aliased output roots",
    )
    require(
        [nodes[roots[i]] for i in range(2)] == expected, "expression values changed"
    )


def check_graph(path, target):
    lines = path.read_text().splitlines()
    require(
        lines[:2]
        == [
            "volta-graph 2",
            f'kernel "k" block 1,1,1 grid 1,1,1 workgroup 0,0,0 targets {target}',
        ],
        "graph scope changed",
    )
    terminals = [line for line in lines if line.startswith("terminal ")]
    require(
        terminals == ["terminal completed"] and lines[-1] == terminals[0],
        "trace is not complete",
    )
    events = [line for line in lines if re.match(r"e\d+ ", line)]
    require(
        [int(re.match(r"e(\d+) ", line)[1]) for line in events]
        == list(range(len(events))),
        "graph event IDs changed",
    )
    pcs = re.findall(
        r"^e\d+ t0 pc(\d+) amd wave=0 Instruction \{", "\n".join(lines), re.M
    )
    count = 13 if target == "gfx1250" else 12
    require(
        list(map(int, pcs)) == list(range(count)), "instruction trace is incomplete"
    )
    exits = re.findall(r"^e\d+ t0 pc(\d+) exit$", "\n".join(lines), re.M)
    require(exits == [str(count - 1)], "missing unique normal exit")
    writes = [line for line in events if "write ordinary generic global" in line]
    require(len(writes) == 2, "global output write population changed")
    footprints = [re.search(r"\[(0x[0-9a-f]+),\+4\) = n\d+$", line) for line in writes]
    require(
        all(footprints) and [m[1] for m in footprints] == ["0x10000", "0x10004"],
        "global output footprint changed",
    )


def capture(command, stem, cwd, binary, repo):
    try:
        result = subprocess.run(command, cwd=cwd, capture_output=True, timeout=60)
        stdout, stderr, code, timeout = (
            result.stdout,
            result.stderr,
            result.returncode,
            False,
        )
    except subprocess.TimeoutExpired as error:
        stdout, stderr, code, timeout = (
            error.stdout or b"",
            error.stderr or b"",
            None,
            True,
        )
    for suffix, data in (("stdout", stdout), ("stderr", stderr)):
        with stem.with_suffix("." + suffix).open("xb") as handle:
            handle.write(data)
    logical = [
        arg.replace(str(binary), "{binary}").replace(str(repo), "{repo}")
        for arg in command
    ]
    record = {
        "command": logical,
        "returncode": code,
        "timed_out": timeout,
        "stdout_sha256": sha(stem.with_suffix(".stdout")),
        "stderr_sha256": sha(stem.with_suffix(".stderr")),
    }
    write_json(stem.with_suffix(".json"), record)
    require(not timeout, "verification timed out; partial records retained")
    return record, stdout.decode("utf-8"), stderr.decode("utf-8")


def collect(binary, output, repo, baseline=False, targets=TARGETS):
    binary, repo, output = (
        binary.resolve(strict=True),
        repo.resolve(strict=True),
        output.resolve(),
    )
    require(
        targets and len(set(targets)) == len(targets) and set(targets) <= set(TARGETS),
        "invalid targets",
    )
    paths = fixture_paths(repo)
    inputs = {
        "binary": (binary, sha(binary)),
        "replayer": (Path(__file__), sha(Path(__file__))),
    }
    inputs.update({name: (p, PINS[name]) for name, p in paths.items()})
    require(not output.exists(), "output already exists")
    require(
        not any(p == output or output in p.parents for p, _ in inputs.values()),
        "output aliases an input",
    )
    output.mkdir(parents=True)
    report = {
        "schema": 1,
        "fixture_revision": FIXTURE_REVISION,
        "fixture_sha256": PINS,
        "binary_sha256": inputs["binary"][1],
        "replayer_sha256": inputs["replayer"][1],
        "role": "baseline" if baseline else "candidate",
        "cases": [],
    }
    try:
        for target in targets:
            common = [
                "--config",
                str(paths[f"{target}.launch.json"]),
                "--backend",
                "amdgpu",
                "--target",
                target,
                "--no-log-file",
            ]
            commands = {
                "verify": [
                    str(binary),
                    "verify",
                    str(paths[f"{target}.s"]),
                    str(paths["one.spec"]),
                    *common,
                    "--dim",
                    "N=2",
                    "--sample",
                    "0",
                    "--verify-numeric",
                ],
                "analyze": [
                    str(binary),
                    "analyze",
                    str(paths[f"{target}.s"]),
                    *common,
                    "--print-outputs",
                    "2",
                    "--dump-graph",
                    f"{target}.graph",
                    "--emit-exprs",
                    f"{target}.vexpr",
                ],
            }
            processes = {}
            for mode, command in commands.items():
                record, stdout, stderr = capture(
                    command, output / f"{target}-{mode}", output, binary, repo
                )
                processes[mode] = record
                check_transcript(
                    stdout, stderr, record["returncode"], target, mode, baseline
                )
            expected = BASELINE_WORDS if baseline else CORRECT_WORDS
            check_graph(output / f"{target}.graph", target)
            check_expressions(output / f"{target}.vexpr", expected)
            report["cases"].append(
                {
                    "target": target,
                    "processes": processes,
                    "graph_sha256": sha(output / f"{target}.graph"),
                    "expression_sha256": sha(output / f"{target}.vexpr"),
                    "output_coordinates": [0, 1],
                    "actual_u32_words": expected,
                    "required_u32_words": CORRECT_WORDS,
                    "graph_properties_pass": 4,
                    "mismatched_coordinates": [0, 1] if baseline else [],
                    "equivalence": "numeric_refuted" if baseline else "equivalent",
                }
            )
        require(
            all(sha(p) == digest for p, digest in inputs.values()),
            "input changed during collection",
        )
        report["inputs_unchanged"] = True
        report["checks_passed"] = True
    except (ValueError, OSError) as error:
        report["checks_passed"] = False
        report["error"] = str(error)
        raise
    finally:
        write_json(output / "report.json", report)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--baseline", action="store_true")
    parser.add_argument("--repo", type=Path)
    args = parser.parse_args()
    repo = args.repo or next(
        (p for p in Path(__file__).resolve().parents if (p / FIXTURES).is_dir()), None
    )
    require(repo is not None, "pass --repo with the checked-in fixtures")
    report = collect(args.binary, args.output, repo, args.baseline)
    print(
        json.dumps(
            {
                "role": report["role"],
                "targets": len(report["cases"]),
                "checks_passed": True,
            }
        )
    )


if __name__ == "__main__":
    main()
