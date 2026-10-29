// Actual native named-object rendering; proof and hardware evidence are separate.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const html = path.resolve(process.argv[2] || '');
const output = path.resolve(process.argv[3] || 'named-browser-evidence');
const receiptPath = path.join(output, 'named-browser-review.json');
const hash = data => crypto.createHash('sha256').update(data).digest('hex');
fs.mkdirSync(output, { recursive: true });
function receipt(value) {
  fs.writeFileSync(receiptPath + '.tmp', JSON.stringify(value, null, 2) + '\n');
  fs.renameSync(receiptPath + '.tmp', receiptPath);
}
receipt({ status: 'incomplete', started_utc: new Date().toISOString() });
let browser;
const errors = [];
(async () => {
  assert.equal(process.argv.length, 4, 'usage: named_browser.cjs MIXED_HTML EVIDENCE_DIRECTORY');
  const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
  browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  await page.goto(pathToFileURL(html).href);
  const documents = await page.evaluate(() => [...document.querySelectorAll('script[id^="run-"]')]
    .map((element, ordinal) => ({ ordinal, data: JSON.parse(element.textContent) })));
  const targets = [...new Set(documents.flatMap(({ data }) => data.launch?.targets || []))];
  for (const target of ['gfx942', 'gfx950', 'gfx1250']) {
    assert(targets.some(t => t.startsWith(target)), 'mixed target required: ' + target);
  }
  assert(documents.some(({ data }) => data.source_language === 'ptx' && data.events.length));
  const named = documents.filter(({ data }) => data.meta.suite === 'gfx1250_named_barrier_tests');
  assert(named.length >= 12, 'actual positive and negative named runs required');
  function info(data, event) {
    return Object.fromEntries(event.slice(4).map(pair =>
      [data.strings[data.pairs[pair * 2]], data.strings[data.pairs[pair * 2 + 1]]]));
  }
  async function open(control) {
    await page.evaluate(key => { location.hash = key; }, control.data.meta.key);
    await page.waitForFunction(key => document.querySelector('#run-header .run-link.active')?.getAttribute('href') === '#' + key,
      control.data.meta.key);
  }
  const selected = [];
  for (const kernel of ['named_identity', 'named_encoded_wait_uses_last_join',
    'named_reinitialized_identity', 'named_subset_drop', 'named_null_unjoin', 'named_two_arrivals_one_wave']) {
    const control = named.find(({ data }) => data.meta.kernel === kernel && data.meta.status === 'race-free');
    assert(control, 'complete native positive required: ' + kernel);
    const d = control.data;
    assert.deepEqual(d.launch.targets, ['gfx1250']);
    assert.equal(d.launch.wave_size, 32);
    const row = d.events.findIndex(event => {
      const label = d.strings[event[3]], details = info(d, event);
      if (kernel === 'named_encoded_wait_uses_last_join') return label.startsWith('named wait 1 ') && details['encoded WAIT selector'] === '2';
      if (kernel === 'named_reinitialized_identity') return label.startsWith('named init ') && details['named object'] === '1 incarnation 1';
      if (kernel === 'named_subset_drop') return label.startsWith('named leave 1 phase 0') && details.wave === '2';
      if (kernel === 'named_null_unjoin') return label.startsWith('named wait 0 ') && details['encoded WAIT selector'] === '1';
      return label.startsWith(kernel === 'named_two_arrivals_one_wave' ? 'named signal ' : 'named init ');
    });
    assert(row >= 0, kernel + ': actual native event required');
    const id = d.eventIds?.[row] ?? row;
    const line = d.instructions[d.events[row][1]].line;
    const sourceLine = d.source.split('\n')[line - 1];
    assert(sourceLine.includes('s_barrier_'), 'selected event must map to the real barrier instruction');
    if (kernel === 'named_two_arrivals_one_wave') {
      assert.equal(d.events.filter(event => d.strings[event[3]] === 'named signal 1 phase 0').length, 2);
    }
    await open(control);
    const go = page.getByRole('textbox', { name: 'Go to event', exact: true });
    await go.fill('e' + id); await go.press('Enter');
    await page.locator('[data-tab="event"]').click();
    assert.equal(await page.locator('#tab-event .event-id').textContent(), 'e' + id);
    assert.equal(await page.locator('#tab-event .event-label').textContent(), d.strings[d.events[row][3]]);
    assert((await page.locator('#tab-event').textContent()).includes(info(d, d.events[row])['named object']));
    await page.locator('[data-tab="source"]').click();
    assert.equal(await page.locator('#tab-source .src-line.current').getAttribute('data-line'), String(line));
    await page.screenshot({ path: path.join(output, kernel + '.png'), fullPage: true });
    selected.push({ kernel, key: d.meta.key, event: id, line, source_line: sourceLine,
      source_sha256: hash(d.source), details: info(d, d.events[row]) });
  }
  const deadlock = named.find(({ data }) => data.meta.status === 'deadlock' &&
    data.meta.test === 'ending_a_joined_wave_does_not_implicitly_drop_its_named_object');
  assert(deadlock, 'END-without-drop typed deadlock required');
  await open(deadlock);
  assert(JSON.stringify(deadlock.data.terminal).includes('2/3 arrivals'));
  await page.locator('[data-tab="checks"]').click();
  await page.screenshot({ path: path.join(output, 'named-end-without-drop.png'), fullPage: true });
  const unbound = named.find(({ data }) => data.meta.test === 'unbound_null_wait_preserves_the_honest_hardware_state_limit' && data.meta.status === 'unsupported');
  assert(unbound, 'unbound NULL selector must remain unsupported');
  const conflict = named.find(({ data }) => data.meta.test === 'named_arrival_does_not_substitute_for_lds_completion' && data.meta.status === 'race-condition');
  assert(conflict, 'wrong completion must retain its actual typed conflict');
  const memory = conflict.data.checks.find(check => check.name === 'AMD memory-conflict freedom');
  assert.equal(memory.verdict, 'fail');
  assert(memory.findings.some(finding => finding.text.toLowerCase().includes('shared')));
  await open(conflict);
  await page.locator('[data-tab="checks"]').click();
  await page.locator('#tab-checks .event-chip').first().click();
  await page.locator('[data-tab="event"]').click();
  assert(await page.locator('#tab-event .event-id').count(), 'actual Shared witness navigates to its memory event');
  await page.screenshot({ path: path.join(output, 'named-wrong-completion.png'), fullPage: true });
  assert.deepEqual(errors, []);
  receipt({ status: 'pass', scope: 'Actual browser rendering and navigation only; independent math, graph and hardware evidence are separate.',
    browser: browser.version(), html, html_sha256: hash(fs.readFileSync(html)),
    script_sha256: hash(fs.readFileSync(__filename)), mixed_runs: documents.length,
    named_runs: named.length, selected_events: selected, deadlock_key: deadlock.data.meta.key,
    unbound_null_key: unbound.data.meta.key, conflict_key: conflict.data.meta.key, browser_errors: errors });
  await browser.close();
  console.log('PASS: six allocated native named kernels, counted deadlock and unbound NULL boundary');
})().catch(async error => {
  receipt({ status: 'fail', error: String(error), browser_errors: errors });
  console.error(error);
  if (browser) await browser.close();
  process.exitCode = 1;
});
