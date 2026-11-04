// Rendering/navigation of full W27-W32 graphs. Math and hardware receipts are separate.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const html = path.resolve(process.argv[2] || '');
const output = path.resolve(process.argv[3] || 'matrix-browser-evidence');
const casesPath = path.resolve(process.argv[4] || '');
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const destination = path.join(output, 'matrix-browser-review.json');
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(destination, JSON.stringify({ status: 'incomplete', started_utc: new Date().toISOString() }) + '\n');
let browser;
const errors = [];

(async () => {
  assert.equal(process.argv.length, 5, 'usage: matrix_browser.cjs MIXED_HTML EVIDENCE_DIRECTORY CASES_JSON');
  const names = ['gemm_f16_full', 'gemm_f8_full', 'gemm_add_silu_f16_full', 'gemm_add_silu_f8_full', 'bitdelta_full', 'bitdelta_batched_full'];
  const cases = JSON.parse(fs.readFileSync(casesPath)).cases;
  const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
  browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  await page.goto(pathToFileURL(html).href);
  const index = JSON.parse(await page.locator('#volta-index').textContent());
  const reviewed = [];
  for (const name of [...names, 'matrix-wrong_initial_ds_completion', 'matrix-missing_initial_workgroup_publication']) {
    const ordinal = index.findIndex(run => run.test === name);
    assert(ordinal >= 0, 'missing full original trace ' + name);
    assert.equal(index.filter(run => run.test === name).length, 1, 'ambiguous trace ' + name);
    const negative = name.startsWith('matrix-');
    const kernel = negative ? 'gemm_f16_full' : name;
    const selected = cases.filter(candidate => candidate.kernel === kernel);
    assert.equal(selected.length, 1);
    const registration = selected[0];
    assert.equal(registration.dimensions.K, 4096);
    assert.equal(registration.reduced_case, false);
    assert.equal(index[ordinal].status, negative ? 'race-condition' : 'race-free');
    await page.evaluate(key => { location.hash = key; }, index[ordinal].key);
    await page.waitForFunction(test => document.querySelector('#run-header h1')?.textContent === test, name);
    const details = await page.evaluate(ordinal => {
      const data = JSON.parse(document.getElementById('run-' + ordinal).textContent);
      const positions = new Set(data.eventIds);
      const omitted = data.eventIds.find((id, row) => id > 0 && !positions.has(id - 1));
      const row = data.events.findIndex((event, row) => data.eventIds[row] >= data.events.length && data.instructions[event[1]]?.line != null);
      const event = data.events[row];
      return { display: data.display, full_events: data.meta.events, events: data.events.length,
        kernel: data.meta.kernel, terminal: data.terminal.kind, launch: data.launch,
        source: data.source, ids: data.eventIds, checks: data.checks,
        row, original: data.eventIds[row], line: data.instructions[event[1]]?.line,
        label: data.strings[event[3]], omitted: omitted == null ? null : omitted - 1,
        final_lane: data.lanes.filter(lane => lane.kind === 'thread').at(-1)?.label };
    }, ordinal);
    assert.equal(details.kernel, kernel);
    assert.equal(details.terminal, 'completed');
    assert.deepEqual(details.launch.targets, ['gfx1250']);
    assert.equal(details.launch.wave_size, 32);
    assert.deepEqual(details.launch.block, registration.block);
    assert.equal(details.final_lane, kernel.startsWith('gemm') ? 'w31:l31' : 'w7:l31');
    assert(details.full_events > 50000, 'full execution must exceed the display limit');
    assert.equal(details.display.totalEvents, details.full_events);
    assert.equal(details.full_events, index[ordinal].events);
    assert.equal(details.display.includedEvents, details.events);
    assert(details.events <= 50000);
    assert.equal(details.events + details.display.omittedEvents, details.full_events);
    assert.equal(details.ids.length, details.events);
    assert(details.ids.every((id, row) => id >= 0 && id < details.full_events && (!row || id > details.ids[row - 1])));
    assert((await page.locator('#run-header .display-note').textContent()).includes('Checks use the complete graph'));
    if (!negative) assert.equal(hash(details.source), registration.assembly_sha256, 'complete frozen compiler source must remain visible');
    assert(details.row >= 0 && details.original >= details.events, 'navigation must exercise an original ID outside the display row range');
    const goto = page.getByRole('textbox', { name: 'Go to event', exact: true });
    await goto.fill('e' + details.original); await goto.press('Enter');
    await page.locator('[data-tab="event"]').click();
    assert.equal(await page.locator('#tab-event .event-id').textContent(), 'e' + details.original);
    assert.equal(await page.locator('#tab-event .event-label').textContent(), details.label);
    await page.locator('[data-tab="source"]').click();
    assert.equal(await page.locator('#tab-source .src-line.current').getAttribute('data-line'), String(details.line));
    assert(details.omitted != null);
    await goto.fill('e' + details.omitted); await goto.press('Enter');
    assert((await goto.getAttribute('class') || '').includes('invalid'), 'an omitted event cannot navigate to an unrelated display row');
    assert((await goto.getAttribute('title')).includes('omitted'));
    await page.locator('[data-tab="event"]').click();
    assert.equal(await page.locator('#tab-event .event-id').textContent(), 'e' + details.original);
    assert.equal(details.checks.length, 4);
    for (const check of details.checks) {
      assert.equal(check.verdict, negative && check.name === 'AMD memory-conflict freedom' ? 'fail' : 'pass');
    }
    await page.locator('[data-tab="checks"]').click();
    if (negative) {
      const memory = details.checks.find(check => check.name === 'AMD memory-conflict freedom');
      assert(memory.totalFindings >= memory.findings.length && memory.findings.length > 0);
      assert(memory.findings.some(finding => finding.text.includes('at shared ')));
      const chip = page.locator('#tab-checks .event-chip').first();
      const expected = await chip.textContent();
      await chip.click(); await page.locator('[data-tab="event"]').click();
      assert.equal(await page.locator('#tab-event .event-id').textContent(), expected);
    }
    await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
    delete details.source; delete details.ids;
    reviewed.push({ test: name, expected_outputs: registration.expected_outputs,
      source_sha256: hash(await page.evaluate(ordinal => JSON.parse(document.getElementById('run-' + ordinal).textContent).source, ordinal)), ...details });
  }
  assert.deepEqual(errors, [], 'no browser exceptions or console errors');
  fs.writeFileSync(destination, JSON.stringify({ status: 'pass', scope: 'Full W27-W32 native graph rendering/navigation only; mathematical and hardware receipts are separate.',
    browser: browser.version(), html, html_sha256: hash(fs.readFileSync(html)), cases_sha256: hash(fs.readFileSync(casesPath)),
    script_sha256: hash(fs.readFileSync(__filename)), reviewed, browser_errors: errors }, null, 2) + '\n');
  await browser.close();
  console.log('PASS: six full original matrix graphs and two typed shared-memory failures in real Chromium');
})().catch(async error => {
  fs.writeFileSync(destination, JSON.stringify({ status: 'fail', error: String(error), browser_errors: errors }, null, 2) + '\n');
  console.error(error);
  if (browser) await browser.close();
  process.exitCode = 1;
});
