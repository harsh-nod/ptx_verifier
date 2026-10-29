#!/usr/bin/env python3
"""Reproduce allocated named barriers and MC-valid CPU-only negative controls."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(argv):
    result = subprocess.run([str(x) for x in argv], text=True, capture_output=True,
                            timeout=120, check=True)
    return {"argv": [str(x) for x in argv], "exit_code": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--llvm", type=Path, default=Path("/opt/rocm-7.2.0/lib/llvm/bin"))
    parser.add_argument("--module", choices=["native-named-barriers", "native-named-phases", "native-named-lifecycle"],
                        default="native-named-barriers")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    source = directory / (args.module + ".ll")
    if args.output is None:
        args.output = directory / {"native-named-barriers": "named-profile-evidence.json",
                                   "native-named-phases": "named-phases-profile-evidence.json",
                                   "native-named-lifecycle": "named-lifecycle-profile-evidence.json"}[args.module]
    assembly = source.with_suffix(".s")
    llc, mc, linker = [args.llvm / name for name in ("llc", "llvm-mc", "ld.lld")]
    receipt = {"schema_version": 1, "target": "gfx1250", "hardware_execution": False,
               "scope": "Compiler/MC/link provenance; Rust graph and payload gates are separate",
               "input": str(source), "input_sha256": sha(source),
               "assembly": str(assembly), "assembly_sha256": sha(assembly),
               "tools": {name: {"path": str(path), "sha256": sha(path.resolve()),
                                "version": command([path, "--version"])}
                         for name, path in (("llc", llc), ("llvm-mc", mc), ("ld.lld", linker))},
               "mutations": []}
    mutations = [
        ("wrong_expected_count", "named_identity", "s_mov_b32 m0, 0x20001",
         "s_mov_b32 m0, 0x30001", "named deadlock: expected 3, arrived 2"),
        ("missing_signal", "named_identity", "s_barrier_signal m0", "s_nop 0",
         "named deadlock: no named arrival"),
        ("end_does_not_drop_named", "named_subset_drop", "s_barrier_leave", "s_nop 0",
         "named deadlock: ended wave contributes no drop"),
        ("missing_join", "named_identity", "s_barrier_join m0", "s_nop 0",
         "barrier failure: wait has no last joined named object"),
        ("wrong_completion_class", "named_identity", "s_wait_dscnt 0\n",
         "s_wait_loadcnt 0\n", "Shared memory conflict: named arrival does not complete DS"),
    ]
    if args.module == "native-named-phases":
        mutations = [
            ("missing_consumer_handshake", "named_two_object_handshake", "s_barrier_wait 2",
             "s_nop 0", "Shared conflict: the producer cannot reuse the buffer before its consumer completes"),
            ("independent_object_count_mismatch", "named_independent_object_counts",
             "s_mov_b32 m0, 0x10002", "s_mov_b32 m0, 0x20002",
             "named deadlock: distinct objects each retain expected 2 and arrived 1"),
            ("encoded_selector_does_not_change_joined_object", "named_two_object_handshake",
             "s_barrier_wait 2", "s_barrier_wait 1",
             "positive metamorphic control: both complete outputs remain identical"),
        ]
        receipt["runtime_control"] = {"kernel": "named_selected_object_copy",
            "scalar_parameter": "different", "positive": 0, "cpu_only_deadlock": 1,
            "scope": "Same actual assembly; flag 1 makes the two waves join different allocated objects"}
    if args.module == "native-named-lifecycle":
        mutations = [
            ("consumer_only_wait_does_not_complete_lds", "named_wait_only_consumer_42",
             "s_wait_dscnt 0\n", "s_wait_loadcnt 0\n",
             "Shared conflict: arrival/wait cannot replace actual LDS completion"),
            ("earlier_phase_cannot_release_metadata_phase", "named_copy_then_metadata_phase_7",
             "s_barrier_signal m0 \n\ts_endpgm", "s_nop 0\n\ts_endpgm",
             "named deadlock: consumer phase 1 expected 1, arrived 0, after phase 0 completed"),
            ("marker_needs_actual_arrival", "named_one_arrival_marker",
             "s_barrier_signal m0", "s_nop 0",
             "named deadlock: count-1 wait cannot fall through without arrival"),
            ("first_free_buffer_still_needs_later_handshake", "named_producer_first_buffer_is_free",
             "s_barrier_wait 1", "s_nop 0",
             "Shared conflict: an initially free buffer cannot be reused before its consumer releases it"),
        ]
        receipt["runtime_control"] = {"kernel": "named_two_marker_ones",
            "scalar_parameter": "skip", "positive": 0, "cpu_only_deadlock": 1,
            "scope": "Same actual assembly; skip 1 suppresses only wave 1 arrival, leaving expected 2 and arrived 1"}
    with tempfile.TemporaryDirectory(prefix="gfx1250-named-profile-") as temp:
        temp = Path(temp)
        regenerated = temp / assembly.name
        receipt["compile"] = command([llc, "-mtriple=amdgcn-amd-amdhsa", "-mcpu=gfx1250",
                                      "-O2", source, "-o", regenerated])
        if regenerated.read_bytes() != assembly.read_bytes():
            raise RuntimeError("compiler output differs from the frozen assembly")
        text = assembly.read_text()
        kernels = {"native-named-barriers": 6, "native-named-phases": 4,
                   "native-named-lifecycle": 6}[args.module]
        if text.count(".amdhsa_named_barrier_count 1") != kernels:
            raise RuntimeError("each genuine kernel must allocate four named objects")
        obj, code = temp / "native.o", temp / "native.hsaco"
        receipt["assemble"] = command([mc, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                                       "-filetype=obj", assembly, "-o", obj])
        receipt["link"] = command([linker, "-shared", obj, "-o", code])
        receipt["object_sha256"], receipt["code_object_sha256"] = sha(obj), sha(code)
        for name, kernel, before, after, obligation in mutations:
            start = text.index("\n" + kernel + ":")
            end = text.index(".Lfunc_end", start)
            at = text.index(before, start, end)
            mutated = temp / (name + ".s")
            mutated.write_text(text[:at] + after + text[at + len(before):])
            mutant_obj = mutated.with_suffix(".o")
            result = command([mc, "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                              "-filetype=obj", mutated, "-o", mutant_obj])
            receipt["mutations"].append({"name": name, "kernel": kernel,
                "source_line": text[:at].count("\n") + 1, "original": before,
                "replacement": after, "assembly_sha256": sha(mutated),
                "object_sha256": sha(mutant_obj), "assemble": result,
                "expected_obligation": obligation, "hardware_execution": False})
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"receipt": str(args.output), "mc_valid_mutations": len(mutations),
                      "assembly_sha256": receipt["assembly_sha256"]}))


if __name__ == "__main__":
    main()
