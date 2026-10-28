"""Check the external kernels for data races with Volta, one framework after the other.

    python3 external/races.py                               # every framework
    python3 external/races.py --framework thunderkittens    # one of `FRAMEWORKS`
    python3 external/races.py --framework hipkittens        # native gfx950 assembly
    python3 external/races.py --framework tritonbench -k add_example --timeout 300

Each launch file `<framework>/**/<stem>.<case>.launch.json` is analyzed, in name
order, with `volta analyze <stem>.ptx --config <launch file>` (or `<stem>.s`
with `--backend amdgpu --target gfx950` for HipKittens). Outcomes, colors and parsing are
`ai_compiler_kernels/check_races.py`'s; a run with no verdict within `--timeout`
is UNKNOWN. Each framework's outcomes go to `output/<framework>.csv`; the exit
status is 1 if any run is a RACE-CONDITION, CHECK-FAILED, DEADLOCK or ERROR.
"""

import argparse
import csv
import json
import math
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

EXTERNAL_ROOT = Path(__file__).resolve().parent
OUTPUT_DIR = EXTERNAL_ROOT / "output"
sys.path.insert(0, str(EXTERNAL_ROOT.parent / "ai_compiler_kernels"))

import check_races  # noqa: E402
from check_races import BOLD, GREEN, OUTCOME_CODES, OUTCOME_WIDTH, RED, Outcome, Style  # noqa: E402

# TritonBench-G (`extraction/tritonbench.py`) and ThunderKittens' educational GEMMs (`extraction/thunderkittens.py`).
FRAMEWORKS = ("tritonbench", "thunderkittens", "hipkittens")
FAILURES = {Outcome.RACE_CONDITION, Outcome.CHECK_FAILED, Outcome.DEADLOCK, Outcome.ERROR}
INCONCLUSIVE = {Outcome.UNKNOWN, Outcome.UNSUPPORTED}


@dataclass(frozen=True)
class Run:
    name: str
    outcome: Outcome
    seconds: float
    detail: str


def check(launch: Path, root: Path, timeout: float, binary: Path | None = None) -> Run:
    name = str(launch.relative_to(root)).removesuffix(".launch.json")
    native = root.name == "hipkittens"
    source = launch.with_name(launch.name.removesuffix(".launch.json").rsplit(".", 1)[0] + (".s" if native else ".ptx"))
    try:
        config = json.loads(launch.read_text())
        expected_outputs = sum(math.prod(a["shape"]) if "shape" in a else a["len"]
                               for a in config.get("arrays", []) if a["kind"] in {"out", "inout"})
    except (OSError, ValueError, KeyError, TypeError) as error:
        return Run(name, Outcome.ERROR, 0, f"invalid launch file: {error}")
    command = [
        str(binary or check_races.VOLTA), "--no-log-file",
        *(["--backend", "amdgpu", "--target", "gfx950"] if native else []),
        "analyze", str(source), "--config", str(launch),
        "--print-outputs", "0", "--no-profile",
    ]
    start = time.perf_counter()
    try:
        done = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return Run(name, Outcome.UNKNOWN, timeout, f"no verdict within {timeout:.0f}s")
    except OSError as error:
        return Run(name, Outcome.ERROR, time.perf_counter() - start, str(error))
    if done.returncode not in {0, 1, 2}:
        return Run(name, Outcome.ERROR, time.perf_counter() - start, f"volta exited with status {done.returncode}: {done.stderr.strip()}")
    report = check_races.parse_cli(done.stdout)
    try:
        outcome, detail = check_races.classify(report, done.stderr, expected_outputs)
    except check_races.VoltaFailure as failure:
        outcome, detail = Outcome.ERROR, str(failure)
        if native and (match := check_races.NATIVE_PARSE_UNSUPPORTED.search(done.stderr)):
            outcome, detail = Outcome.UNSUPPORTED, match[0]
    if done.returncode != 0 and outcome in {Outcome.RACE_FREE, Outcome.REDUCED_RACE_FREE}:
        outcome, detail = Outcome.ERROR, f"successful graph report with nonzero exit status {done.returncode}"
    return Run(name, outcome, time.perf_counter() - start, detail)


def check_framework(framework: str, match: str, timeout: float, style: Style,
                    binary: Path | None = None, strict: bool = False) -> bool:
    """Run every matching launch file of `framework` in order; whether any run failed."""
    root = EXTERNAL_ROOT / framework
    launches = [p for p in sorted(root.rglob("*.launch.json")) if match in str(p.relative_to(root))]
    print(style.paint(f"== {framework}: {len(launches)} launches", BOLD), flush=True)
    width = max((len(str(p.relative_to(root))) for p in launches), default=0) - len(".launch.json")
    runs = []
    for launch in launches:
        run = check(launch, root, timeout, binary)
        runs.append(run)
        painted = style.paint(f"{run.outcome.value:<{OUTCOME_WIDTH}}", *OUTCOME_CODES[run.outcome])
        print(f"{run.name:<{width}}  {painted}  {run.seconds:6.1f}s  {run.detail}", flush=True)

    OUTPUT_DIR.mkdir(exist_ok=True)
    csv_path = OUTPUT_DIR / f"{framework}.csv"
    with csv_path.open("w", newline="") as out:
        writer = csv.writer(out)
        writer.writerow(["launch", "outcome", "seconds", "detail"])
        writer.writerows((r.name, r.outcome.value, f"{r.seconds:.3f}", r.detail) for r in runs)
    outcomes = [r.outcome for r in runs]
    failed = not runs or any(o in FAILURES or (strict and o in INCONCLUSIVE) for o in outcomes)
    counts = ", ".join(f"{outcomes.count(o)} {o.value}" for o in Outcome if o in outcomes) or "no launches"
    print(f"\n{framework}: {style.paint(counts, BOLD, RED if failed else GREEN)}\nwrote {csv_path}\n", flush=True)
    return failed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--framework", choices=FRAMEWORKS, help="check only this framework (default: all, in order)")
    parser.add_argument("-k", dest="match", default="", help="only launches whose name contains this")
    parser.add_argument("--timeout", type=float, default=60, help="seconds per run (default 60)")
    parser.add_argument("--binary", type=Path, help="use an existing CLI without rebuilding")
    parser.add_argument("--strict", action="store_true", help="also fail for unsupported/unknown results and empty selections")
    args = parser.parse_args()

    style = Style(sys.stdout.isatty() and not os.environ.get("NO_COLOR"))
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if args.binary:
        args.binary = args.binary.resolve()
    else:
        check_races.build_volta()
    frameworks = (args.framework,) if args.framework else FRAMEWORKS
    failed = [check_framework(f, args.match, args.timeout, style, args.binary, args.strict) for f in frameworks]
    return 1 if any(failed) else 0


if __name__ == "__main__":
    sys.exit(main())
