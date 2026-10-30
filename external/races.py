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

# Native AMD and PTX extraction adapters share the workload runner.
FRAMEWORKS = ("tritonbench", "thunderkittens", "hipkittens", "gluon", "tilelang")
FAILURES = {Outcome.RACE_CONDITION, Outcome.CHECK_FAILED, Outcome.DEADLOCK, Outcome.ERROR}
INCONCLUSIVE = {Outcome.UNKNOWN, Outcome.UNSUPPORTED}


@dataclass(frozen=True)
class Run:
    name: str
    outcome: Outcome
    seconds: float
    detail: str


def check(launch: Path, root: Path, timeout: float, binary: Path | None = None,
          target: str | None = None) -> Run:
    name = str(launch.relative_to(root)).removesuffix(".launch.json")
    native = root.name == "hipkittens" or target is not None
    source = launch.with_name(launch.name.removesuffix(".launch.json").rsplit(".", 1)[0] + (".s" if native else ".ptx"))
    try:
        config = json.loads(launch.read_text())
        expected_by_array = {}
        for array in config.get("arrays", []):
            if array["kind"] not in {"out", "inout"}:
                continue
            dimensions = array["shape"] if "shape" in array else [array["len"]]
            if not dimensions or any(type(d) is not int or d < 0 for d in dimensions):
                raise ValueError("output dimensions must be nonnegative integers")
            if array["name"] in expected_by_array:
                raise ValueError(f"duplicate output array {array['name']!r}")
            expected_by_array[array["name"]] = math.prod(dimensions)
        expected_outputs = sum(expected_by_array.values())
        if not source.is_file():
            raise ValueError(f"missing kernel source: {source}")
        if native and check_races.native_target_of(source.read_text()) != (target or "gfx950"):
            raise ValueError(f"source target differs from requested {target or 'gfx950'}")
    except (OSError, ValueError, KeyError, TypeError) as error:
        return Run(name, Outcome.ERROR, 0, f"invalid launch file: {error}")
    command = [
        str(binary or check_races.VOLTA), "--no-log-file",
        *(["--backend", "amdgpu", "--target", target or "gfx950"] if native else []),
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
    if outcome in {Outcome.RACE_FREE, Outcome.REDUCED_RACE_FREE}:
        if error := check_races.array_coverage_error(done.stdout, expected_by_array):
            outcome, detail = Outcome.CHECK_FAILED, error
    return Run(name, outcome, time.perf_counter() - start, detail)


def check_framework(framework: str, match: str, timeout: float, style: Style,
                    binary: Path | None = None, strict: bool = False,
                    target: str | None = None, root_override: Path | None = None) -> bool:
    """Run every matching launch file of `framework` in order; whether any run failed."""
    root = root_override or EXTERNAL_ROOT / framework
    launches = [p for p in sorted(root.rglob("*.launch.json")) if match in str(p.relative_to(root))]
    print(style.paint(f"== {framework}: {len(launches)} launches", BOLD), flush=True)
    width = max((len(str(p.relative_to(root))) for p in launches), default=0) - len(".launch.json")
    runs = []
    for launch in launches:
        run = check(launch, root, timeout, binary, target)
        runs.append(run)
        painted = style.paint(f"{run.outcome.value:<{OUTCOME_WIDTH}}", *OUTCOME_CODES[run.outcome])
        print(f"{run.name:<{width}}  {painted}  {run.seconds:6.1f}s  {run.detail}", flush=True)

    OUTPUT_DIR.mkdir(exist_ok=True)
    csv_path = OUTPUT_DIR / f"{framework}{'.' + target if target else ''}.csv"
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
    parser.add_argument("--framework", choices=(*FRAMEWORKS, "native"), help="check one framework; native requires an explicit --root and --target")
    parser.add_argument("-k", dest="match", default="", help="only launches whose name contains this")
    parser.add_argument("--timeout", type=float, default=60, help="seconds per run (default 60)")
    parser.add_argument("--binary", type=Path, help="use an existing CLI without rebuilding")
    parser.add_argument("--target", choices=check_races.NATIVE_TARGETS, help="explicit native AMD target; existing HipKittens default remains gfx950")
    parser.add_argument("--root", type=Path, help="prepared launch/source directory; requires --framework")
    parser.add_argument("--strict", action="store_true", help="also fail for unsupported/unknown results and empty selections")
    args = parser.parse_args()

    style = Style(sys.stdout.isatty() and not os.environ.get("NO_COLOR"))
    if args.timeout <= 0 or not math.isfinite(args.timeout):
        parser.error("--timeout must be positive")
    if args.root and not args.framework:
        parser.error("--root requires --framework")
    if args.target and not args.framework:
        parser.error("--target requires --framework")
    if args.framework == "native" and (not args.root or not args.target):
        parser.error("--framework native requires --root and --target")
    if args.binary:
        args.binary = args.binary.resolve()
    else:
        check_races.build_volta()
    frameworks = (args.framework,) if args.framework else FRAMEWORKS
    failed = [check_framework(f, args.match, args.timeout, style, args.binary, args.strict,
                              args.target, args.root) for f in frameworks]
    return 1 if any(failed) else 0


if __name__ == "__main__":
    sys.exit(main())
