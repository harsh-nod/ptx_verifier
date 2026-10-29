#!/usr/bin/env python3
"""Replay W21-W26, preserving full sequences, dtypes and all companion outputs.

Flash uses its actual grid16 and validates all1024 native rows, including the
original CTA0 projection of128 rows. Other cases use their original grid1.
"""
from original_run import Profile, main


ADVANCED = Profile(
    contract={"flash_attention_original": (66560, 393216, 5),
              "forgetting_attention_original": (8320, 282624, 6),
              "sage_attention_original": (8192, 32780, 6),
              "sinkhorn_original": (32, 143488, 6),
              "mamba_state_original": (8192, 526336, 5),
              "mamba_scan_original": (8192, 300032, 8)},
    modules=("attention", "sinkhorn", "mamba"),
    driver="full/hardware/original_advanced.cpp", runner="full/hardware/original_advanced_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_advanced_run.py", "full/hardware/original_common.hpp",
           "full/hardware/original_advanced.cpp", "full/fixtures/original-attention.hip",
           "full/fixtures/original-attention.s", "full/fixtures/original-sinkhorn.hip",
           "full/fixtures/original-sinkhorn.s", "full/fixtures/original-mamba.hip",
           "full/fixtures/original-mamba.s"),
    patterns=4, minimum_patterns=4, maximum_patterns=16,
    gaps={"flash_attention_original": 0, "forgetting_attention_original": 0,
          "sage_attention_original": 0, "sinkhorn_original": 0,
          "mamba_state_original": 0, "mamba_scan_original": 114688},
    original_outputs={"flash_attention_original": 8320, "forgetting_attention_original": 8320,
                      "sage_attention_original": 8192, "sinkhorn_original": 32,
                      "mamba_state_original": 8192, "mamba_scan_original": 8192},
)


if __name__ == "__main__":
    raise SystemExit(main(ADVANCED))
