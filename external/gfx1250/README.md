# Native gfx1250 adapter controls

The external race and mutation adapters accept an explicit gfx1250 target.
They analyze native assembly on the CPU, independently of external library
extraction. Exact-assembly numerical checks are documented in
[the gfx1250 hardware guide](../../tests/gfx1250/hardware/README.md).

The pinned HipKittens extraction recipe remains a gfx950/CDNA4 recipe. Running
`python3 external/extraction/hipkittens.py --target gfx1250` reports `UNSUPPORTED`
with an actionable diagnostic. Its CDNA4 macros and wave64 launch contracts
are not silently relabeled as a gfx1250 implementation.

Use the genuine LLVM-native minimum corpus for adapter controls:

```sh
cargo build -p volta_cli --features logging
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --binary target/debug/volta --color never
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --binary target/debug/volta --mutate -k copy --color never
```

The first command reads `tests/gfx1250/cases.json`, preserves native ABI byte
payloads through its launch configurations, and checks all declared outputs.
Configurations with a `.spec` also run their mathematical references. The
wide-integer configurations have exact native Rust oracles instead of a `.spec`;
this race adapter checks their graph and complete four-element footprints.
The second command removes each of the copy kernel's three waits. Each removal
must produce a concrete failed check. Unsupported, unknown, crashed, empty and
skipped-baseline mutation runs cannot satisfy the negative test.

`--target gfx942` selects its existing genuine native case manifest.
`--backend amdgpu` without a target retains the gfx950 workload default; the
global backend default remains PTX. `--manifest PATH` selects another explicit
native case manifest. Source target markers must agree with the selected target.

For extraction without modifying tracked files, copy the HIP source into a
temporary directory. The compiler records fresh tool/source/assembly/object
hashes there. No assembly is retargeted or rewritten:

```sh
export G1250_EXTERNAL_DIR="$(mktemp -d /tmp/ptx-verifier-gfx1250-external.XXXXXX)"
cp tests/gfx1250/fixtures/native-copy-add.hip "$G1250_EXTERNAL_DIR/"
python3 tests/gfx1250/compile_fixtures.py "$G1250_EXTERNAL_DIR"
python3 - "$G1250_EXTERNAL_DIR" <<'PY'
import json
from pathlib import Path
import sys

directory = Path(sys.argv[1])
row = next(c for c in json.loads(Path("tests/gfx1250/cases.json").read_text())["cases"]
           if c["kernel"] == "copy")
params = []
for param in row["params"]:
    kind, value = param.split(":", 1)
    params.append({kind: int(value) if kind == "int" else value})
launch = {"kernel": row["kernel"], "block": row["block"], "grid": row["grid"],
          "arrays": [{"name": a["name"], "base": a["base_address"],
                      "elem_width": a["element_size"], "len": a["length"], "kind": a["kind"]}
                     for a in row["arrays"]], "params": params}
(directory / "copy.full.launch.json").write_text(json.dumps(launch, indent=2) + "\n")
(directory / "copy.s").symlink_to(directory / "native-copy-add.s")
PY
python3 external/races.py --framework native --root "$G1250_EXTERNAL_DIR" \
  --target gfx1250 --binary target/debug/volta --strict
```

The output is labeled `native`, not HipKittens. The adapter reports unsupported
instructions separately from unknown results and process errors; `--strict`
also fails on unsupported/unknown results. A verified graph with missing output
elements, missing array names, duplicate output reports or a nonzero success exit
cannot pass. Per-target CSV output goes under ignored `external/output/`.

Focused adapter regressions run without a GPU or external library checkout:

```sh
python3 -m unittest discover -s external/tests -v
python3 -m pytest crates/volta_py/tests/test_workload_harness.py -q
```
