# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6,<7"]
# ///
"""Check original-shape HipKittens GEMMs for one selected workgroup, on the CPU.

Reuse complete compiler/MC-accepted campaign modules. The finite profiles retain
the upstream host shapes, descriptors, grid, threads and dynamic LDS allocation.
Disjoint output views name every original physical element written by WG0; they
neither compact a strided matrix nor prove execution of the remaining grid.
"""
from __future__ import annotations

import argparse
import ast
import importlib.util
import itertools
import json
import math
import re
import struct
from collections import Counter
from pathlib import Path

import hipkittens_corpus as corpus
import hipkittens_inventory as inventory
import hipkittens_vectors as vectors

LADDER = "kernels/cdna5/gemm/bf16fp32/gfx1250/"
GEMM4 = "kernels/cdna4/gemm/bf16fp32/"
PROFILES = {
    "gfx1250-gemm00": {
        "source": LADDER + "00_gemm_naive.cpp", "host": LADDER + "utils.py",
        "shape_variable": "SHAPES", "target": "gfx1250", "architecture": "cdna5",
        "symbol": "_Z20gemm_00_naive_kernelN12gfx1250_gemm12gemm_globalsEiii",
        "tile": 64, "block": 128, "wave": 32, "dynamic_shared_bytes": 8704,
        "descriptor_bytes": 40, "globals_bytes": 120, "layout": "column-major",
        "shapes": ((8192, 8192, 8192), (4096, 8192, 2048),
                   (8192, 4096, 2048), (2048, 1024, 1024)),
        "inputs": (LADDER + "common.h", LADDER + "harness.h", LADDER + "pyext.h",
                   LADDER + "test.py", LADDER + "Makefile"),
    },
    "gfx950-bf16-gemm": {
        "source": GEMM4 + "256_256_64_32_with16x32.cpp", "host": GEMM4 + "test.py",
        "shape_variable": "test_shapes", "target": "gfx950", "architecture": "cdna4",
        "symbol": "_Z8micro_tk13micro_globalsiii",
        "tile": 256, "block": 512, "wave": 64, "dynamic_shared_bytes": 160000,
        "descriptor_bytes": 48, "globals_bytes": 168, "layout": "row-major",
        "shapes": ((8192, 8192, 8192), (4096, 8192, 2048), (8192, 4096, 2048),
                   (8192, 2048, 4096), (512, 1024, 1024), (512, 1024, 2048),
                   (2048, 1024, 512)),
        "inputs": (GEMM4 + "utils.py", GEMM4 + "Makefile"),
    },
}
BASES = {"A": 0x10000000, "B": 0x40000000, "C": 0x80000000}
DEFAULT_CONTRACT = inventory.EXTERNAL / "hipkittens/complex/contracts.json"
BUILD_HELPER = corpus.ROOT / "tests/gfx1250/measure_tensor_bounds.py"
_BUILD_SPEC = importlib.util.spec_from_file_location("complex_build_records", BUILD_HELPER)
build_records = importlib.util.module_from_spec(_BUILD_SPEC)
_BUILD_SPEC.loader.exec_module(build_records)


def literal_shapes(text, variable):
    values = [node.value for node in ast.parse(text).body if isinstance(node, ast.Assign)
              and any(isinstance(target, ast.Name) and target.id == variable for target in node.targets)]
    inventory.require(len(values) == 1, "missing or duplicate original host shape list")
    return tuple(tuple(shape) for shape in ast.literal_eval(values[0]))


def make_cases(name):
    profile = PROFILES[name]
    return [{"id": name + "-" + "x".join(map(str, shape)), "profile": name,
             "shape": list(shape), "workgroup_id": [0, 0, 0],
             "required_output_elements": profile["tile"] ** 2,
             "original_allocations": {name: {"base": BASES[name], "shape": list(dimensions),
                                              "bytes": 2 * math.prod(dimensions)}
                                      for name, dimensions in (("A", (shape[0], shape[2])),
                                                               ("B", (shape[1], shape[2])),
                                                               ("C", (shape[0], shape[1])))}}
            for shape in profile["shapes"]]


def validate_case(case):
    inventory.require(case.get("profile") in PROFILES, "unknown complex profile")
    inventory.require(case in make_cases(case["profile"]),
                      "case differs from a complete original host shape/WG0 contract")
    return PROFILES[case["profile"]]


def descriptor(base, rows, cols, size):
    payload = struct.pack("<5Q", base, 1, 1, rows, cols)
    inventory.require(size in {40, 48}, "unknown original GL ABI")
    return payload + bytes(size - len(payload))


def launch(case):
    profile = validate_case(case)
    m, n, k = case["shape"]
    tile = profile["tile"]
    grid = [m // tile, n // tile, 1] if profile["target"] == "gfx1250" else [m // tile * (n // tile), 1, 1]
    arrays = [{"name": name, "base": BASES[name], "shape": [rows, k],
               "dtype": "bf16", "kind": "in"} for name, rows in (("A", m), ("B", n))]
    # Keep the original leading dimension. Each named contiguous view is a
    # separate column (CDNA5) or row (CDNA4), at its actual matrix byte offset.
    stride = m if profile["layout"] == "column-major" else n
    arrays += [{"name": f"C{index}", "base": BASES["C"] + 2 * index * stride,
                "shape": [tile], "dtype": "bf16", "kind": "out"} for index in range(tile)]
    payload = b"".join(descriptor(BASES[name], rows, cols, profile["descriptor_bytes"])
                       for name, rows, cols in (("A", m, k), ("B", n, k), ("C", m, n)))
    if profile["target"] == "gfx950":
        payload += bytes(8) + struct.pack("<3i4x", m, n, k)  # stream, cached M/N/K, tail padding
    inventory.require(len(payload) == profile["globals_bytes"], "original globals ABI size changed")
    result = {"kernel": profile["symbol"], "block": [profile["block"], 1, 1], "grid": grid,
              "workgroup_id": [0, 0, 0], "dynamic_shared_bytes": profile["dynamic_shared_bytes"],
              "arrays": arrays, "params": [{"bytes": list(payload)}] + [{"int": value} for value in (m, n, k)]}
    validate_views(result, case)
    return result


def validate_views(config, case):
    profile = validate_case(case)
    m, n, k = case["shape"]
    tile = profile["tile"]
    arrays = config["arrays"]
    inventory.require(len({array["name"] for array in arrays}) == len(arrays), "duplicate array view")
    expected = {"C" + str(index): (BASES["C"] + 2 * index * (m if profile["layout"] == "column-major" else n), tile)
                for index in range(tile)}
    actual = {array["name"]: (array["base"], math.prod(array["shape"]))
              for array in arrays if array["kind"] == "out"}
    inventory.require(actual == expected, "missing, shifted, extra or compacted original output view")
    inventory.require(sum(count for _, count in actual.values()) == case["required_output_elements"],
                      "incomplete original output footprint")
    ranges = sorted((array["base"], array["base"] + 2 * math.prod(array["shape"])) for array in arrays)
    inventory.require(all(first[1] <= second[0] for first, second in itertools.pairwise(ranges)), "aliased array views")
    inventory.require(all(array["dtype"] == "bf16" for array in arrays), "original BF16 dtype changed")
    inputs = [array for array in arrays if array["kind"] == "in"]
    inventory.require(inputs == [{"name": name, "base": BASES[name], "shape": [rows, k], "dtype": "bf16", "kind": "in"}
                                 for name, rows in (("A", m), ("B", n))], "original full input allocation changed")


def specification(name, *, wrong=False):
    profile = PROFILES[name]
    tile = profile["tile"]
    lines = ["dim M; dim N; dim K;", "array A[M, K]; array B[N, K];"]
    for index in range(tile):
        row, col = ("i", str(index)) if profile["layout"] == "column-major" else (str(index), "i")
        correction = " + 1" if wrong and index == 0 else ""
        lines += [f"array C{index}[{tile}];",
                  f"C{index}[i] = sum(k in 0..K, A[{row}, k] * B[{col}, k]){correction};"]
    return "\n".join(lines) + "\n"


def validate_metadata(kernels, name):
    profile = PROFILES[name]
    selected = [kernel for kernel in kernels if kernel[".name"] == profile["symbol"]]
    inventory.require(len(selected) == 1, "missing or duplicate original GEMM entrypoint")
    kernel = selected[0]
    args = [arg for arg in kernel[".args"] if not arg[".value_kind"].startswith("hidden_")]
    size = profile["globals_bytes"]
    expected = [{".offset": 0, ".size": size, ".value_kind": "by_value"}]
    expected += [{".offset": size + 4 * index, ".size": 4, ".value_kind": "by_value"} for index in range(3)]
    inventory.require(args == expected, "original GEMM parameter offsets/sizes/roles changed")
    inventory.require(kernel[".wavefront_size"] == profile["wave"]
                      and kernel[".max_flat_workgroup_size"] == profile["block"]
                      and kernel[".group_segment_fixed_size"] == 0
                      and kernel[".private_segment_fixed_size"] == 0, "original native resource profile changed")
    return kernel


def contract(source_root):
    document = inventory.build_inventory(source_root)  # exact clean upstream pin, including headers
    profiles = {}
    for name, profile in PROFILES.items():
        inventory.require(literal_shapes((source_root / profile["host"]).read_text(), profile["shape_variable"])
                          == profile["shapes"], "original host shapes changed")
        paths = (profile["source"], profile["host"], *profile["inputs"])
        profiles[name] = {key: value for key, value in profile.items() if key not in {"inputs", "shapes", "shape_variable"}}
        profiles[name].update(source_sha256={path: document["source_sha256"].get(path, inventory.sha((source_root / path).read_bytes()))
                                             for path in paths}, cases=make_cases(name),
                             spec_sha256=inventory.sha(specification(name).encode()),
                             wrong_spec_sha256=inventory.sha(specification(name, wrong=True).encode()))
    return {"schema": 1, "source_revision": inventory.REVISION, "repository": inventory.REPOSITORY,
            "scope": "One original workgroup (0,0,0); all original host dimensions and full-K work retained. Other workgroups are outside the result.",
            "input_allocations": "Complete original A[M,K] and B[N,K] allocations; no prefix reduction. Full M/N/K descriptor extents and strides retained.",
            "output_allocation_limit": "The complete original C[M,N] base/extent is recorded per case. The native interface forbids overlapping arrays, so the launch declares only disjoint selected-WG output views, not an overlapping full-C array. This is a selected-workgroup contract, not a full-matrix/all-workgroups proof.",
            "output_views": "Every physical tile element, as disjoint contiguous columns/rows at the original leading-dimension offsets. Unselected matrix elements are not outputs of WG0.",
            "math": "C[r,c] = sum(k=0..K-1,A[r,k]*B[c,k]); abstract mathematical BF16 input values/fp32 accumulation. This does not check hardware rounding or the upstream torch tolerance.",
            "profiles": profiles}


def load_module(campaign, source_root, name):
    profile = PROFILES[name]
    report_path = campaign / "report.json"
    report = json.loads(report_path.read_text())
    inventory.require(report["source_revision"] == inventory.REVISION, "campaign source pin differs")
    rows = [row for row in report["results"] if row["source"] == profile["source"] and row["profile"]["target"] == profile["target"]]
    inventory.require(len(rows) == 1, "missing or duplicate original complete module")
    row = rows[0]
    inventory.require(row["source_sha256"] == inventory.sha((source_root / profile["source"]).read_bytes()), "campaign source differs")
    directory = campaign / row["id"]
    assembly, obj = directory / "kernel.s", directory / "kernel.o"
    inventory.require(inventory.sha(assembly.read_bytes()) == row["assembly_sha256"]
                      and inventory.sha(obj.read_bytes()) == row["object_sha256"], "stale original assembly/object")
    compiled = json.loads((directory / "compile.json").read_text())
    assembled = json.loads((directory / "assemble.json").read_text())
    inventory.require(all(record["status"] == "succeeded" and record["returncode"] == 0 for record in (compiled, assembled)),
                      "original module compile/MC failed")
    kernels = corpus.metadata(assembly.read_text(), profile["target"])
    inventory.require(kernels == row["emitted_kernels"], "campaign metadata differs from complete module")
    validate_metadata(kernels, name)
    return assembly, obj, report_path, compiled


def layout_source(source_root, name):
    profile = PROFILES[name]
    lines = [f'#include "{source_root / profile["source"]}"', "#include <cstddef>"]
    gl = "gfx1250_gemm::gl_e" if profile["target"] == "gfx1250" else "_gl_A"
    globals_type = "gfx1250_gemm::gemm_globals" if profile["target"] == "gfx1250" else "micro_globals"
    lines += [f"using OriginalGL = {gl};", f"static_assert(sizeof(OriginalGL) == {profile['descriptor_bytes']} && alignof(OriginalGL) == 8);"]
    for field, offset in (("raw_ptr", 0), ("batch_internal", 8), ("depth_internal", 16), ("rows_internal", 24), ("cols_internal", 32)):
        lines.append(f"static_assert(offsetof(OriginalGL, {field}) == {offset});")
    lines.append(f"static_assert(sizeof({globals_type}) == {profile['globals_bytes']});")
    for index, field in enumerate(("a", "b", "c")):
        lines.append(f"static_assert(offsetof({globals_type}, {field}) == {index * profile['descriptor_bytes']});")
    if profile["target"] == "gfx1250":
        lines += ["static_assert(sizeof(gfx1250_gemm::A_tile) + sizeof(gfx1250_gemm::B_tile) == 8704);",
                  "static_assert(NUM_THREADS == 128 && BLOCK_M == 64 && BLOCK_N == 64 && BLOCK_K == 32);"]
    else:
        lines += ["static_assert(offsetof(micro_globals, stream) == 144 && offsetof(micro_globals, M) == 152);",
                  "static_assert(offsetof(micro_globals, N) == 156 && offsetof(micro_globals, K) == 160);",
                  "static_assert(NUM_THREADS == 512 && BLOCK_SIZE == 256 && MAX_SHARED_MEMORY == 160000);"]
    return "\n".join(lines) + "\n"


def verification_command(binary, assembly, spec, config, case):
    profile = validate_case(case)
    command = [str(binary), "--no-log-file", "--backend", "amdgpu", "--target", profile["target"], "verify",
               str(assembly), str(spec), "--config", str(config), "--sample", "0", "--no-profile"]
    for name, value in zip(("M", "N", "K"), case["shape"]):
        command += ["--dim", f"{name}={value}"]
    return command


def classify(record, stdout, stderr, elements, parse_record):
    status = vectors.classify_verify(record, stdout, stderr, elements)
    if parse_record["status"] != "succeeded":
        inventory.require(status not in {"verified", "graph_rejected", "mathematical_mismatch"},
                          "verification contradicts whole-module parser refusal")
        if record["status"] == "rejected" and status == "execution_or_driver_error" and "error:" in stderr:
            return "parse_rejected"
    return status


def require_stable(paths, hashes, generated):
    inventory.require(all(inventory.sha(path.read_bytes()) == hashes[name] for name, path in paths.items()), "run input changed")
    inventory.require(all(path.read_bytes() == data for path, data in generated.items()), "generated contract input changed")


def run(options, frozen_contract):
    output, source_root = options.output.resolve(), options.source_root.resolve()
    inventory.require(not output.is_relative_to(corpus.ROOT) and not output.is_relative_to(source_root), "raw output must be outside source repositories")
    inventory.require(re.fullmatch(r"[0-9a-f]{40}", options.binary_revision) is not None, "full binary source revision required")
    binary, compiler, assembler = (path.resolve() for path in (options.binary, options.compiler, options.assembler))
    paths = {"binary": binary, "compiler": compiler, "assembler": assembler,
             "driver": Path(__file__).resolve(), "corpus": Path(corpus.__file__).resolve(),
             "inventory_helper": Path(inventory.__file__).resolve(), "vector_validation": Path(vectors.__file__).resolve(),
             "contract": options.contract.resolve(), "build_helper": BUILD_HELPER,
             "build_record": options.build_record.resolve()}
    build_identity = build_records.build_identity(paths["build_record"], options.binary_revision, binary)
    modules = {}
    for name in options.profile or PROFILES:
        modules[name] = load_module(options.campaign.resolve(), source_root, name)
        for label, path in zip(("assembly", "object", "campaign_report"), modules[name][:3]):
            paths[name + "_" + label] = path
        for label in ("compile", "assemble"):
            paths[name + "_" + label + "_record"] = modules[name][0].parent / (label + ".json")
    hashes = {name: inventory.sha(path.read_bytes()) for name, path in paths.items()}
    output.mkdir(parents=True, exist_ok=False)
    for label in ("driver", "corpus", "inventory_helper", "vector_validation", "build_helper"):
        (output / (label + "-source.py")).write_bytes(paths[label].read_bytes())
    (output / "contracts.json").write_text(json.dumps(frozen_contract, indent=2) + "\n")
    generated = {}
    results, module_results = [], []
    for name, (assembly, _, _, compiled) in modules.items():
        profile = PROFILES[name]
        directory = output / name
        directory.mkdir()
        layout = directory / "layout.cpp"
        layout.write_text(layout_source(source_root, name))
        generated[layout] = layout.read_bytes()
        flags = compiled["command"][1:]
        source_args = [index for index, arg in enumerate(flags) if Path(arg).resolve() == source_root / profile["source"]]
        inventory.require(len(source_args) == 1 and flags.count("-o") == 1 and flags.count("-S") == 1,
                          "ambiguous original compile source/output")
        source_index, output_index = source_args[0], flags.index("-o")
        kept = [arg for index, arg in enumerate(flags) if index not in {source_index, output_index, output_index + 1} and arg != "-S"]
        layout_record, _, _ = corpus.stage([str(compiler), *kept, "-fsyntax-only", str(layout)], directory, "layout", options.timeout)
        inventory.require(layout_record["status"] == "succeeded", "compiler refused original GL/global/tile layout assertions")
        mc_record, _, _ = corpus.stage([str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=" + profile["target"],
                                       "-filetype=obj", str(assembly), "-o", str(directory / "checked.o")], directory, "assemble", options.timeout)
        inventory.require(mc_record["status"] == "succeeded", "complete original module failed MC")
        parse_record, _, _ = corpus.stage([str(binary), "--no-log-file", "--backend", "amdgpu", "--target", profile["target"],
                                          "parse", str(assembly)], directory, "parse", options.timeout)
        module_results.append({"profile": name, "layout": layout_record, "assemble": mc_record, "parse": parse_record})
        spec = directory / "gemm.spec"
        spec.write_text(specification(name))
        generated[spec] = spec.read_bytes()
        for case in make_cases(name):
            case_dir = directory / case["id"]
            case_dir.mkdir()
            config = case_dir / "launch.json"
            config.write_text(json.dumps(launch(case), indent=2) + "\n")
            generated[config] = config.read_bytes()
            command = verification_command(binary, assembly, spec, config, case)
            record, stdout, stderr = corpus.stage(command, case_dir, "verify", options.timeout)
            try:
                status = classify(record, stdout, stderr, case["required_output_elements"], parse_record)
            except ValueError:
                status = "contract_error"
            result = {**case, "status": status, "full_specification_proved": status in {"verified", "graph_rejected"}
                      and vectors.full_specification_result(record, stdout, stderr, case["required_output_elements"]),
                      "launch_sha256": inventory.sha(config.read_bytes()), "stage": record}
            if status != "verified":
                result["detail"] = next((line.strip() for line in (stderr + "\n" + stdout).splitlines() if re.search(
                    r"unsupported .*instruction|execution stopped|MemoryConflict|error:|NOT EQUIVALENT", line)), "")
            results.append(result)
            print(case["id"], status, flush=True)
        # A wrong equation is meaningful only after a complete passing original
        # graph. A parser refusal cannot pass a mathematical negative control.
        verified = next((case for case in results if case["profile"] == name and case["status"] == "verified"), None)
        control = {"profile": name, "status": "no_verified_original_case", "passed": False}
        if verified:
            wrong = directory / "wrong.spec"
            wrong.write_text(specification(name, wrong=True))
            generated[wrong] = wrong.read_bytes()
            command = verification_command(binary, assembly, wrong, directory / verified["id"] / "launch.json",
                                           next(case for case in make_cases(name) if case["id"] == verified["id"]))
            record, stdout, stderr = corpus.stage(command, directory, "wrong-spec", options.timeout)
            control.update(status=vectors.classify_verify(record, stdout, stderr, verified["required_output_elements"]), stage=record)
            control["passed"] = control["status"] == "mathematical_mismatch"
        module_results[-1]["mathematical_control"] = control
    inventory.require(contract(source_root) == frozen_contract, "original source changed during run")
    require_stable(paths, hashes, generated)
    inventory.require(build_records.build_identity(paths["build_record"], options.binary_revision, binary) == build_identity,
                      "build identity changed")
    report = {"schema": 1, "source_revision": inventory.REVISION, "binary_revision": options.binary_revision,
              "build_identity": build_identity,
              "input_sha256": hashes, "timeout_seconds": options.timeout, "scope": frozen_contract["scope"],
              "modules": module_results, "results": results, "outcomes": dict(sorted(Counter(row["status"] for row in results).items())),
              "all_original_cases_verified": all(row["status"] == "verified" for row in results)
              and all(row["mathematical_control"]["passed"] for row in module_results)}
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=inventory.DEFAULT_SOURCE)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--write-contract", action="store_true")
    parser.add_argument("--check", action="store_true", help="validate only the immutable source/shape/math contract")
    parser.add_argument("--profile", action="append", choices=PROFILES)
    parser.add_argument("--campaign", type=Path)
    parser.add_argument("--binary", type=Path)
    parser.add_argument("--binary-revision")
    parser.add_argument("--build-record", type=Path, help="caller-attested release/default-feature build record matching source and executable")
    parser.add_argument("--compiler", type=Path, default=Path("/opt/rocm/llvm/bin/clang++"))
    parser.add_argument("--assembler", type=Path, default=Path("/opt/rocm/llvm/bin/llvm-mc"))
    parser.add_argument("--output", type=Path)
    parser.add_argument("--timeout", type=float, default=60)
    options = parser.parse_args()
    try:
        inventory.require(math.isfinite(options.timeout) and options.timeout > 0, "finite positive timeout required")
        inventory.require(not options.profile or len(options.profile) == len(set(options.profile)), "duplicate profile")
        current = contract(options.source_root.resolve())
        if options.write_contract:
            options.contract.parent.mkdir(parents=True, exist_ok=True)
            options.contract.write_text(json.dumps(current, indent=2) + "\n")
        inventory.require(json.loads(options.contract.read_text()) == current, "stored complex source contract drifted; regenerate explicitly")
        if options.check or options.write_contract:
            return
        inventory.require(all((options.campaign, options.binary, options.binary_revision, options.build_record, options.output)),
                          "execution requires --campaign, --binary, --binary-revision, --build-record and --output")
        run(options, current)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
