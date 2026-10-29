# volta_viz

Named signal-time count updates show their updated expected arrivals on the
single signal row and retain ordinary arrival-to-release edges.

The run store accepts PTX, gfx942/gfx950 wave64 and gfx1250 wave32 graphs.
Native runs show AMD wave/lane labels, target-width EXEC and register masks,
counter charges and wait thresholds, MFMA or WMMA operands, delay states,
LDS/tensor footprints and barrier generations. Typed AMD findings
link the issuing and consuming events back to their source lines. AMD barrier deadlocks
name missing waves directly.

Gfx1250 named-barrier rows retain physical ID, initialization incarnation and
phase, including INIT counts and WAIT's encoded versus last-joined selector.
Candidate signal/drop-to-release edges remain separate from checked findings.
Named deadlocks display expected and observed arrival counts; they do not invent
a PTX synchronization object or treat END as a named drop.

The wire format remains `volta-viz 1`: `launch.wave_size` and
`launch.source_language` and `launch.wave_kind` are additive fields. Legacy
stores without geometry/language metadata use the warp32 fallback; stored AMD
wave64 width still identifies wave grouping. Source-only unsupported outcomes
retain declared target/geometry separately, without inventing a launch. Source
filenames still occupy the legacy `ptx` metadata key, including `.s`
files, so stored-run readers remain compatible. Candidate barrier/issue edges are
visualized as recorded associations; check findings establish their validity.

Run `cargo test -p volta_viz --test amdgpu_viewer_tests` for AMD source mapping,
wait/readiness witnesses, aborted/unsupported status, and deadlock export coverage.

The event-graph viewer. It records kernel runs into a directory (a **run
store**) and turns that store into **one self-contained HTML page** showing
each run's displayed event graph as a space-time diagram. The diagram has a lane per
thread, per issuing thread's async ops and per sync object; the typed edges;
the graph checks' findings; and the PTX or native AMD source behind every event.

```sh
just viz   # records the complete pipeline suite, including thousands of numeric variations
```

For a smaller store, use the [focused gfx1250 recipe](../../tests/gfx1250/README.md#software-acceptance-and-reproduction).
Set `VOLTA_VIZ_DIR` to an absolute path: Cargo runs each test from its crate
folder, so a relative store path may differ from the subsequent CLI invocation.

For graphs above 50,000 events, `write_run` exports a display selection. Graph
construction, all checks and the run's status still use the complete graph.
The document preserves the complete source, target and launch metadata, and
reports total/included/omitted event and finding counts in `display`.
`meta.events` remains the full graph count; `events` contains displayed rows.
`eventIds[row]` gives each row's original graph EventId. Edges, async operation
links and finding event lists index the displayed rows; the UI displays original
IDs and accepts them in event navigation. Records without these additive fields
retain the original identity mapping.

Selection prioritizes terminal notes and up to 128 findings per property,
retaining each selected finding's complete witness endpoints. Findings whose
endpoints cannot fit are omitted whole and counted. Remaining space covers
first/last events per executed source instruction and lane, nearby witness
context, and evenly spaced events. Async issue/completion endpoints stay
together so filtering cannot invent a pending operation. The page discloses the
selection and omitted counts. Diagram layers describe the retained display,
not cycle timing or all paths in the full graph. `write_complete_run` keeps every
event for archival consumers; such documents can exceed browser string limits.

## High-level logic

```
Run { outcome: Executed { graph, arena, report } | NotStarted { cause, error }, source, ... }
   │ write_run(dir, &run)           (store.rs, export.rs)
   ▼
<dir>/<suite>/<test>[~n].json       the run as a `volta-viz 1` document
<dir>/<suite>/<test>[~n].meta.json  its summary (status, counts)
   │ write_page(dir, out)           (page.rs)
   ▼
one HTML page: viewer/{page.html, style.css, app.js} inlined
               + every document as an inert <script type="application/json"> block
```

- `store.rs`: the store layout. The page's index is built from the
  `.meta.json` summaries alone, so no document is parsed up front.
- `export.rs`: one run to its JSON document, and its **status**: race-free,
  race-condition (a native AMD memory/readiness failure, or a PTX memory-conflict,
  proxy-order or tensor-order failure),
  check-failed, deadlock, unsupported, unknown, error or unchecked.
- `json.rs`: a minimal JSON value and compact writer (the crate's only wire
  format; no serde).
- `page.rs`: assembles the page. A run's JSON is parsed only when it is opened,
  so the page loads quickly however many runs it holds.

## How the visual graph is built

### In Rust (`export.rs`)

1. **Lanes** (`Lanes::of`): each thread gets a lane, followed by an async lane
   if it issues async ops. Then each sync object gets a lane. Every event goes
   in the lane of its `ExecContext`: `Thread(t)` to t's lane, `Async(op)` to
   the issuer's async lane, `Generation(g)` to g's object's lane.
2. **Events** are compact rows `[lane, pc or -1, category, label, detail
   pairs...]`. Strings and `key=value` detail pairs are interned into
   document-wide tables, because a large trace holds tens of thousands of
   near-identical events.
3. **Edges** (`edges`): flat `[from, to, ...]` lists per kind:
   - `contribute` (contribution -> generation completion) and `release`
     (completion -> `Resume`). An `ExecutionOnly` collective's member edges
     get `-execution-only` kinds and are drawn dashed, because they order
     nothing;
   - `pipeline`: `volta_graph_check::pipeline`'s `E_pipeline` edges.

   Program order is implicit in each lane's event sequence. Each async op is
   listed once as `[issue, completion or -1, effects...]` instead of two edges
   per effect.
4. **Findings**: every check's witnesses and unresolved obligations, and a
   stuck trace's blocked threads, resolved to event ids so the page can ring
   them.
5. **Source**: the PTX or native AMD text and a pc -> line map from the graph's
   `Provenance`.

### In the browser (`viewer/app.js`)

`derive(doc)` lays out rows by **longest-path layering**. An event sits one row
below its lane predecessor and below the source of every edge into it. Edges
run forward in trace order, so one pass in event order is enough. Around the
diagram the page has an overview of all runs (statuses, suites), a step ruler,
a minimap while zoomed, a legend that highlights or steps through one event
kind, and keyboard navigation (`?` lists the keys).

## Dependencies

`volta_graph` (the graph), `volta_graph_check` (findings, pipeline edges) and
`volta_expr` (rendering stored values). `tests/viewer_tests.rs` covers export
and page assembly.

## Native gfx1250 records

The viewer labels native gfx1250 lanes as AMD wave32, including source-only
unsupported outcomes. It displays target-specific wait counters, WMMA/tensor
issues, split signal/wait/release events and typed findings with source links.
The mixed-target Chromium harness covers PTX, gfx942, gfx950 and gfx1250;
rendering a run is separate from successful proof or hardware validation.

The full-size matrix Chromium harness requires all six W27–W32 records and
both typed shared-memory mutation controls. It checks complete source hashes
against the registration, wave32 geometry, disclosed omissions, original IDs
outside the display row range, omitted-ID rejection and finding/source links.
The shared harness also accepts legacy identity-mapped records in the same page.

```sh
PLAYWRIGHT_MODULE=/path/to/playwright node tests/gfx1250/full-parity/browser.cjs mixed/index.html browser-evidence
PLAYWRIGHT_MODULE=/path/to/playwright node tests/gfx1250/full-parity/matrix_browser.cjs mixed/index.html matrix-browser-evidence tests/gfx1250/full/cases.json
```

Both commands write browser receipts and screenshots. They require actual
recorded native graphs; no sampled computation substitutes for a full-size run.
