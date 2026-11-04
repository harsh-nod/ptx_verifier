#!/usr/bin/env python3
"""Exact fixed-width output bits, boundary inputs, sparse gaps and byte writes."""
import json
from pathlib import Path

import original_run

MAPPINGS = json.loads((Path(__file__).resolve().parents[2] /
                      "fixtures/exact-integer-provenance.json").read_text())["mappings"]


def accounting(row):
    name, kind = row["native_kernel"], row["config_kind"]
    written = len(row["written_indices"])
    raw_words = written * row["output_width"] // 4
    # Two fixtures intentionally mutate byte0 of their scratch storage. Those
    # buffers receive guard and exact byte/neighbour checks, not an input claim.
    writes = name in ("exact_load_s8_sign_extends", "exact_store_u8_truncates")
    inputs = (0 if writes else 8) if kind == "scratch" else (
        0 if kind == "out" else row["configured_output_capacity"] * row["output_width"])
    return raw_words, inputs, 1 if kind == "out" else 2


INTEGER = original_run.Profile(
    contract={row["native_kernel"]: accounting(row) for row in MAPPINGS},
    modules=("exact-integer",),
    assemblies=("fixtures/native-exact-integer.s",),
    driver="full/hardware/exact_integer.cpp",
    runner="full/hardware/exact_integer_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/exact_integer.cpp",
           "full/hardware/exact_integer_run.py", "fixtures/native-exact-integer.hip",
           "fixtures/native-exact-integer.s", "fixtures/exact-integer-provenance.json"),
    patterns=8, minimum_patterns=8, maximum_patterns=8,
    original_outputs={r["native_kernel"]: len(r["written_indices"]) for r in MAPPINGS},
    gaps={r["native_kernel"]: (r["configured_output_capacity"] - len(r["written_indices"])) *
          r["output_width"] for r in MAPPINGS},
    scope="All25 genuine fixed-width counterparts and all105 original written coordinates per pattern, with eight boundary input patterns. U64 results compare both raw words. Scratch byte0 writes are intentional and checked exactly; all other scratch bytes, output gaps and allocation guards must remain unchanged. The cancellation example retains the original never-steal premise; it claims no native cancellation mechanism. Separate from symbolic graph/equivalence proofs and the original32 workload gate.",
)

if __name__ == "__main__":
    raise SystemExit(original_run.main(INTEGER))
