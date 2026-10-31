# Native async-copy functional comparison

CPU analysis finds a missing async-completion dependency in the BF16 and F16
instantiations of one unchanged public HipKittens test. The global-to-LDS copy
can overlap the subsequent LDS reads. A separately labeled repair control adds
one `s_wait_asynccnt 0` after the copy in each entry.

| Case, both data types | Safety result | Completed instructions per entry | Complete identity specification |
| --- | --- | ---: | --- |
| Frozen earlier verifier, original assembly | Unsupported async instruction | Not executed | Unavailable |
| Updated verifier, original assembly | REJECT: unordered LDS access | 61 | All 256 elements match |
| Updated verifier, wait-repair control | ACCEPT | 62 | All 256 elements match |

This is one modeled missing-wait pattern across two data types. The original
and repair output-expression files are byte-identical for each type. Each launch
retains its original 16×16 tile, grid1/block32, 512-byte input, 512-byte output,
163840-byte dynamic LDS allocation and two 16-byte by-value arguments. Every
output is compared with the identity specification and numerical confirmation;
no output sampling is used.

## Source and semantic contract

The complete [original assembly](fixtures/original.s) comes from
[HipKittens shared_to_register.cu](https://github.com/HazyResearch/HipKittens/blob/8cde3dd146bd1c4be78023b582c1f4375c48489f/tests/unit/cdna5/warp/memory/tile/shared_to_register.cu),
at revision `8cde3dd146bd1c4be78023b582c1f4375c48489f` (the original
[MIT notice](fixtures/LICENSE.HipKittens) is retained), using the public ROCm LLVM
compiler revision `7b800a19466229b8479a78de19143dc33c3ab9b5`. Original source,
compiler commands, ABI layout checks and allocation hashes are retained in
[provenance](provenance/manifest.json). The
[repair diff](results/repair/repair.diff) contains exactly two inserted waits,
one per entry; it is a control, separate from the original source.

The public [CDNA5 ISA §10.8](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
tracks these transfers with ASYNCCNT and permits their LDS effects out of order.
The bounded native model uses default scheduling, captures symbolic data and
addresses at issue, and independently checks completion and memory ordering.
It uses mathematical-real arithmetic. These results cover the configured
workgroup, which is the entire grid for these two launches. They are CPU verifier
findings; hardware wrong results were not measured.

## Replay and inspect

Build the candidate source in a separate worktree. Run the replay from the
checkout containing this dataset:

```sh
git worktree add --detach /tmp/native-async-source bd591464883c21150495fba3baa3328a133e05de
cargo build --release --manifest-path /tmp/native-async-source/Cargo.toml -p volta_cli
python3 tests/amdgpu/native-async-copy/reproduce.py \
  --binary /tmp/native-async-source/target/release/volta --output /tmp/native-async-replay
```

The replay checks the unchanged assembly hash, reconstructs the complete repair
module from the two insertions, preserves full launch/specification contracts and
records fresh stdout, stderr, graphs and all output expressions. It does not run
a GPU. `--baseline` replays the two original cases with the frozen earlier
verifier; its expected outcome is an unsupported instruction.

[Recorded results](results/original/report.json),
[repair controls](results/repair/report.json) and the
[independent audit](results/independent-audit.json) retain artifact identities,
complete transcripts and typed graph witnesses. The separate 68-module syntax
replay has 8 parses and 60 refusals; its
[complete transcripts](results/original/parse-records.json) remain syntax counts.
Build-to-source associations are caller-attested. Single-run times in these
records support no speedup or memory-use comparison; paired latency studies are
reported separately in the repository README.
