// Original dtype/atomic traces supplement the shared real-Chromium regression.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { pathToFileURL } = require('node:url');

const root = path.resolve(__dirname, '../../..');
const html = path.resolve(process.argv[2] || '');
const output = path.resolve(process.argv[3] || 'original-browser-evidence');
const receiptPath = path.join(output, 'original-browser-review.json');
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(receiptPath, JSON.stringify({ status: 'incomplete', started_utc: new Date().toISOString() }) + '\n');
let activeBrowser;
const errors = [];

(async () => {
  const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
  assert.equal(process.argv.length, 4, 'usage: browser.cjs MIXED_HTML EVIDENCE_DIRECTORY');
  const shared = path.join(root, 'crates/volta_viz/tests/browser/viewer.spec.cjs');
  const mixed = path.join(output, 'mixed');
  const baseline = spawnSync(process.execPath, [shared, html, mixed], {
    encoding: 'utf8', timeout: 180000, env: process.env,
  });
  fs.writeFileSync(path.join(output, 'mixed.stdout.txt'), baseline.stdout || '');
  fs.writeFileSync(path.join(output, 'mixed.stderr.txt'), baseline.stderr || '');
  assert.equal(baseline.status, 0, baseline.stderr || String(baseline.error));
  const sharedReceipt = JSON.parse(fs.readFileSync(path.join(mixed, 'browser-review.json')));
  assert.deepEqual(sharedReceipt.browser_errors, []);

  const browser = activeBrowser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  await page.goto(pathToFileURL(html).href);
  const index = JSON.parse(await page.locator('#volta-index').textContent());
  const selected = [];
  for (const control of [
    { test: 'original-reduction_f16', kernel: 'reduction_f16', instruction: 'global_atomic_add_f32' },
    { test: 'original-reduction_f8', kernel: 'reduction_f8', instruction: 'global_atomic_add_f32' },
    { test: 'original-rope_f16', kernel: 'rope_f16', instruction: 'v_cvt_f32_f16' },
    { test: 'original-rope_f8', kernel: 'rope_f8', instruction: 'v_cvt_f32_fp8' },
  ]) {
    const ordinal = index.findIndex(run => run.test === control.test);
    assert(ordinal >= 0, 'missing original trace ' + control.test);
    assert.equal(index[ordinal].status, 'race-free', 'original positive must have a complete verified graph');
    await page.evaluate(key => { location.hash = key; }, index[ordinal].key);
    await page.waitForFunction(test => document.querySelector('#run-header h1')?.textContent === test, control.test);
    const details = await page.evaluate(({ ordinal, instruction }) => {
      const data = JSON.parse(document.getElementById('run-' + ordinal).textContent);
      const source = data.source.split('\n');
      const event = data.events.findIndex(value => {
        const line = data.instructions[value[1]]?.line;
        return line != null && source[line - 1]?.includes(instruction);
      });
      if (event < 0) return { event };
      const line = data.instructions[data.events[event][1]].line;
      return { event, line, instruction: source[line - 1], label: data.strings[data.events[event][3]],
        target: data.launch.targets, wave: data.launch.wave_size, kernel: data.meta.kernel,
        terminal: data.terminal, source_sha256_input: data.source };
    }, { ordinal, instruction: control.instruction });
    assert(details.event >= 0, 'positive trace must execute ' + control.instruction);
    assert.deepEqual(details.target, ['gfx1250']);
    assert.equal(details.wave, 32);
    assert.equal(details.kernel, control.kernel);
    const goto = page.getByRole('textbox', { name: 'Go to event', exact: true });
    await goto.fill('e' + details.event);
    await goto.press('Enter');
    await page.locator('[data-tab="event"]').click();
    assert.equal(await page.locator('#tab-event .event-id').textContent(), 'e' + details.event);
    assert.equal(await page.locator('#tab-event .event-label').textContent(), details.label);
    await page.locator('[data-tab="source"]').click();
    const current = page.locator('#tab-source .src-line.current');
    assert.equal(await current.getAttribute('data-line'), String(details.line));
    assert((await current.textContent()).includes(control.instruction));
    await page.screenshot({ path: path.join(output, control.test + '.png'), fullPage: true });
    details.source_sha256 = hash(details.source_sha256_input);
    delete details.source_sha256_input;
    selected.push({ test: control.test, ...details });
  }
  assert.equal(selected.length, 4);
  assert.deepEqual(errors, [], 'no errors on original dtype/atomic event navigation');
  const receipt = { status: 'pass', scope: 'Rendering/navigation only; mathematical and hardware receipts are separate.',
    browser: browser.version(), html, html_sha256: hash(fs.readFileSync(html)),
    script_sha256: hash(fs.readFileSync(__filename)),
    shared_script_sha256: hash(fs.readFileSync(shared)), shared_receipt_sha256: hash(fs.readFileSync(path.join(mixed, 'browser-review.json'))),
    mixed_runs: sharedReceipt.runs, original_selected_events: selected, browser_errors: errors };
  fs.writeFileSync(receiptPath, JSON.stringify(receipt, null, 2) + '\n');
  await browser.close();
  console.log('PASS: shared mixed-store regression and four original atomic/F16/FP8 event/source links');
})().catch(async error => {
  fs.writeFileSync(receiptPath, JSON.stringify({ status: 'fail', error: String(error), browser_errors: errors }, null, 2) + '\n');
  console.error(error);
  if (activeBrowser) await activeBrowser.close();
  process.exitCode = 1;
});
