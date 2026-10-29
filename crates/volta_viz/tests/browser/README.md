# Real browser regression

This optional check opens a generated `volta-viz 1` run store in Chromium.
It tests source/event navigation, target-specific checks, wave grouping,
filters, unsupported-source highlighting, theme and help. It writes screenshots
and a JSON report, and fails on browser exceptions or console errors.

From the repository root, install the pinned browser dependency:

```sh
(cd crates/volta_viz/tests/browser && npm install && npx playwright install chromium)
```

The test expects a **mixed validation store** containing PTX runs, native gfx942 successes and typed failures, gfx950 runs, gfx1250 successes and typed failures (including a partial wave), an eventless unsupported gfx1250 source, and a typed unsupported HipKittens softmax run named `hipkittens-softmax`. The run recorder accepts existing source and launch JSON pairs and does real analysis/checking; an unsupported source is recorded without inventing a graph or successful proof.
The following root-directory example illustrates the recorder; its two runs
alone do not satisfy the full mixed-store requirements above:

```sh
cargo run -p volta_pipeline --example record_viewer_runs -- \
  /tmp/volta-mixed-viz \
  ptx-success ptx /path/to/kernel.ptx /path/to/ptx.launch.json \
  hipkittens-softmax amdgpu /path/to/softmax.s /path/to/softmax.wg0.launch.json
```

From the repository root, add real compiler successes and barrier/wait/NOP
mutations using an absolute store path:

```sh
VOLTA_VIZ_DIR=/tmp/volta-mixed-viz cargo test --release -p volta_pipeline \
  --test gfx942_compiler_tests
VOLTA_VIZ_DIR=/tmp/volta-mixed-viz cargo test --release -p volta_pipeline \
  --test gfx1250_compiler_tests \
  real_gfx1250_assemble_valid_safety_mutants_fail_their_actual_native_obligations
```

Also record the required eventless unsupported gfx1250 source with the recorder.
A successful compiler case cannot substitute for that source-only control.
The gfx1250 corpus also supplies navigable wait, WMMA, tensor, ALU-delay and
split-barrier events. The JSON report identifies the HTML, browser script and
embedded run documents by hash. After adding runs, invoke the recorder again
to rebuild `index.html`; it includes every existing run in the store.
HipKittens assembly comes from the [extraction workflow](../../../../external/hipkittens/README.md).

From the repository root:

```sh
node crates/volta_viz/tests/browser/viewer.spec.cjs \
  /tmp/volta-mixed-viz/index.html /tmp/volta-browser-evidence
```

`PLAYWRIGHT_MODULE` can point to an externally installed Playwright module, avoiding a repository-local `node_modules`. These browser assertions validate rendering and interaction. They do not add mathematical or hardware validation to a recorded result.
