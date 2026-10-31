#!/usr/bin/env python3
"""Inventory every tracked HIP kernel declaration in the pinned public HipKittens tree.

This is a lexical source inventory, not a C++ instantiation or support claim.
Compiler-emitted entrypoints are recorded separately by the extraction campaign.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

EXTERNAL = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = EXTERNAL / "sources/HipKittens"
DEFAULT_OUTPUT = EXTERNAL / "hipkittens/corpus/inventory.json"
REVISION = "8cde3dd146bd1c4be78023b582c1f4375c48489f"
REPOSITORY = "https://github.com/HazyResearch/HipKittens"
SOURCE_SUFFIXES = {".cpp", ".cu", ".cuh", ".h", ".hpp", ".hip"}
LITERALS = re.compile(r'//[^\n]*|/\*.*?\*/|R"(?P<delimiter>[^ ()\\\t\r\n]{0,16})\(.*?\)(?P=delimiter)"|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', re.S)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args])


def mask_literals(text):
    """Keep source positions/newlines while excluding comments and literals."""
    return LITERALS.sub(lambda match: "".join("\n" if char == "\n" else " " for char in match[0]), text)


def closing(text, start, left="(", right=")"):
    require(text[start] == left, "invalid balanced-region start")
    depth = 0
    for index in range(start, len(text)):
        depth += text[index] == left
        depth -= text[index] == right
        if depth == 0:
            return index
    raise ValueError("unterminated source region")


def line_at(text, offset):
    return text.count("\n", 0, offset) + 1


def compact(text):
    return " ".join(text.split())


def template_prefix(text, masked, start):
    # Record the declaration verbatim rather than guessing values for template
    # parameters. A preceding completed declaration/body is a hard boundary.
    boundary = max(masked.rfind(";", 0, start), masked.rfind("}", 0, start), masked.rfind("{", 0, start))
    prefix = masked[boundary + 1:start]
    match = re.search(r"\btemplate\s*<", prefix)
    return compact(text[boundary + 1 + match.start():start]) if match else None


def declarations(text):
    """Account for every real __global__ token; unknown forms are errors."""
    masked = mask_literals(text)
    result = []
    for match in re.finditer(r"\b__global__\b", masked):
        start = match.start()
        function = re.search(r"\bvoid\s+([A-Za-z_]\w*)\s*\(", masked[match.end():])
        require(function is not None, f"unparsed __global__ at line {line_at(text, start)}")
        name = function[1]
        name_start = match.end() + function.start(1)
        open_args = match.end() + function.end() - 1
        require("__global__" not in masked[match.end():name_start], "kernel token skipped another declaration")
        close_args = closing(masked, open_args)
        tail = re.search(r"[;{]", masked[close_args + 1:])
        require(tail is not None, "kernel declaration has no body or semicolon")
        terminal = close_args + 1 + tail.start()
        definition = masked[terminal] == "{"
        end = closing(masked, terminal, "{", "}") + 1 if definition else terminal + 1
        result.append({"name": name, "line": line_at(text, start), "definition": definition,
                       "template": template_prefix(text, masked, start),
                       "signature": compact(text[start:terminal]),
                       "declaration_sha256": sha(text[start:end].encode())})
    return result


def launches(text):
    masked = mask_literals(text)
    result = []
    for match in re.finditer(r"\b([A-Za-z_]\w*)(\s*<[^;{}]*?>)?\s*<<<", masked):
        begin = match.start()
        result.append({"line": line_at(text, begin), "style": "triple_chevron",
                       "callee": compact(text[begin:match.end() - 3])})
    for match in re.finditer(r"\bhipLaunchKernelGGL\s*\(", masked):
        end = closing(masked, match.end() - 1)
        result.append({"line": line_at(text, match.start()), "style": "hipLaunchKernelGGL",
                       "expression": compact(text[match.start():end + 1])})
    return sorted(result, key=lambda row: row["line"])


def scope(path):
    if "/archive/" in path or "/data_logs/" in path:
        return "archive"
    return {"kernels": "application", "analysis": "analysis", "tests": "unit_test",
            "training": "training", "distributed-kernels": "distributed"}.get(path.split("/")[0], "library")


def profiles(path, makefile):
    for architecture, target in (("cdna3", "gfx942"), ("cdna4", "gfx950"), ("cdna5", "gfx1250")):
        if architecture in Path(path).parts:
            return [{"architecture": architecture, "target": target}]
    if "/mi325x/" in path or "/mi300x/" in path:
        return [{"architecture": "cdna3", "target": "gfx942"}]
    if "/mi350x/" in path:
        return [{"architecture": "cdna4", "target": "gfx950"}]
    match = re.search(r"(?m)^\s*GPU_TARGET\s*[:?+]?=\s*(CDNA[345])\b", makefile or "")
    if match:
        architecture = match[1].lower()
        return [{"architecture": architecture, "target": {"cdna3": "gfx942", "cdna4": "gfx950", "cdna5": "gfx1250"}[architecture]}]
    if path.startswith("tests/unit/common/"):
        return [{"architecture": "cdna4", "target": "gfx950"}, {"architecture": "cdna5", "target": "gfx1250"}]
    # The shared kernel build rules explicitly default to CDNA4. Preserve that
    # origin rather than silently targeting another architecture.
    return [{"architecture": "cdna4", "target": "gfx950", "basis": "kernels/common.mk default"}]


def build_inventory(root):
    require((root / "include/kittens.cuh").is_file(), "initialize the pinned HipKittens submodule")
    require(git(root, "rev-parse", "HEAD").decode().strip() == REVISION, "unexpected HipKittens revision")
    require(not git(root, "status", "--porcelain", "--untracked-files=all").strip(), "HipKittens source is modified or has untracked files")
    tracked = sorted(path.decode() for path in git(root, "ls-tree", "-r", "--name-only", "-z", REVISION).split(b"\0") if path)
    source_paths = [path for path in tracked if Path(path).suffix in SOURCE_SUFFIXES]
    build_paths = [path for path in tracked if Path(path).name == "Makefile" or Path(path).suffix == ".mk"]
    builds = {path: (root / path).read_bytes().decode() for path in build_paths}
    sources, kernels, units = {}, [], []
    for path in source_paths:
        raw = (root / path).read_bytes()
        text = raw.decode()
        sources[path] = sha(raw)
        rows = declarations(text)
        ancestors = [str(parent / "Makefile") for parent in Path(path).parents if str(parent) != "."]
        nearest = next((candidate for candidate in ancestors if candidate in builds), None)
        native_profiles = profiles(path, builds.get(nearest))
        for row in rows:
            kernels.append({"source": path, "scope": scope(path), "profiles": native_profiles, **row})
        if rows or (Path(path).suffix in {".cpp", ".cu", ".hip"}):
            units.append({"source": path, "scope": scope(path), "profiles": native_profiles,
                          "standalone_translation_unit": Path(path).suffix in {".cpp", ".cu", ".hip"},
                          "build_file": nearest, "kernel_declarations": len(rows),
                          "launch_sites": launches(text)})
    definitions = [row for row in kernels if row["definition"]]
    return {"schema_version": 1, "repository": REPOSITORY, "revision": REVISION,
            "tree": git(root, "rev-parse", REVISION + "^{tree}").decode().strip(),
            "inventory_scope": "Every tracked C/C++/HIP source; all lexical __global__ definitions and declarations, including archives, analysis, training, distributed and unit wrappers.",
            "template_scope": "Template declarations and source launch expressions are recorded without inventing instantiations. Actual emitted specializations belong to compiler metadata.",
            "summary": {"tracked_files": len(tracked), "source_files": len(sources), "build_files": len(builds),
                        "kernel_definitions": len(definitions), "kernel_declarations": len(kernels) - len(definitions),
                        "definitions_by_scope": dict(sorted(Counter(row["scope"] for row in definitions).items())),
                        "definitions_by_target": dict(sorted(Counter(profile["target"] for row in definitions for profile in row["profiles"]).items()))},
            "source_sha256": sources, "build_sha256": {path: sha(text.encode()) for path, text in builds.items()},
            "kernels": kernels, "compilation_units": units}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true", help="Refuse missing or stale checked-in inventory")
    args = parser.parse_args()
    try:
        document = build_inventory(args.source_root.resolve())
        if args.check:
            require(json.loads(args.output.read_text()) == document, "inventory drift; regenerate explicitly")
        else:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(document, indent=2) + "\n")
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.error(str(error))
    print(json.dumps(document["summary"], indent=2))


if __name__ == "__main__":
    main()
