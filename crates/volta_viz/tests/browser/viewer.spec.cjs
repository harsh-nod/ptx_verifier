const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { pathToFileURL } = require('node:url');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

let activeBrowser;
(async () => {
  const html = path.resolve(process.argv[2]);
  const output = path.resolve(process.argv[3] || 'browser-evidence');
  fs.mkdirSync(output, { recursive: true });
  fs.writeFileSync(path.join(output, 'browser-errors.json'), '[]\n');
  const browser = activeBrowser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
  // Observe the real canvas header, rather than inferring its grouping from JSON.
  await page.addInitScript(() => {
    const original = CanvasRenderingContext2D.prototype.fillText;
    CanvasRenderingContext2D.prototype.fillText = function(text, ...args) {
      (window.__voltaCanvasText ||= []).push(String(text));
      return original.call(this, text, ...args);
    };
  });
  const errors = [];
  const recordError = error => { errors.push(error); fs.writeFileSync(path.join(output, 'browser-errors.json'), JSON.stringify(errors, null, 2)); };
  page.on('pageerror', error => recordError({ message: String(error), stack: error.stack, url: page.url() }));
  page.on('console', message => { if (message.type() === 'error') recordError(message.text()); });
  await page.goto(pathToFileURL(html).href);
  const index = JSON.parse(await page.locator('#volta-index').textContent());
  assert(index.length > 0, 'recorded runs must exist');
  await page.screenshot({ path: path.join(output, 'overview.png'), fullPage: true });
  const opened = [];
  async function open(i) {
    await page.evaluate(key => {
      window.__voltaCanvasText = [];
      location.hash = key;
      window.dispatchEvent(new Event('resize'));
      return new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    }, index[i].key);
    await page.waitForFunction(({ test, key }) => {
      const active = document.querySelector('#run-header .run-link.active');
      return document.querySelector('#run-header h1')?.textContent === test && (!active || active.getAttribute('href') === '#' + key);
    }, { test: index[i].test, key: index[i].key });
    return page.evaluate(i => {
      const d = JSON.parse(document.getElementById('run-' + i).textContent);
      const featureEvents = {};
      for (const [name, pattern] of Object.entries({ wait: /^native wait /, wmma: / WMMA /, tensor: /Tensor(LoadToLds|StoreFromLds)/, delay: /^s_delay_alu /, signal: /^s_barrier_signal -1 /, barrier_wait: /^s_barrier_wait -1 /, release: /^barrier -1 phase .* released$/ })) {
        const id = (d.events || []).findIndex(e => pattern.test(d.strings[e[3]]));
        if (id >= 0) { const e = d.events[id]; featureEvents[name] = { event: id, label: d.strings[e[3]], line: d.instructions[e[1]]?.line }; }
      }
      return { target: d.launch?.targets || (d.source_target ? [d.source_target] : []),
        wave: d.launch?.wave_size || d.source_wave_size, wave_kind: d.launch?.wave_kind || d.source_wave_kind || ((d.source_language || d.launch?.source_language) === 'amdgpu' ? 'wave' : 'warp'),
        source_language: d.source_language || d.launch?.source_language, declared_only: !d.launch,
        threads: d.launch?.block?.reduce((a, b) => a * b, 1),
        lane_labels: (d.lanes || []).filter(l => l.kind === 'thread').map(l => l.label),
        feature_events: featureEvents,
        drawn_groups: [...new Set((window.__voltaCanvasText || []).filter(t => /^(wave|warp) \d+$/.test(t)))],
        events: d.events?.length || 0, checks: d.checks?.length || 0, source_lines: (d.source || '').split('\n').length };
    }, i);
  }
  for (let i = 0; i < index.length; ++i) {
    const info = await open(i);
    const target = info.target.join(',');
    if (/gfx942|gfx950|gfx1250/.test(target)) {
      const width = target.startsWith('gfx1250') ? 32 : 64;
      assert.equal(info.wave, width, index[i].key + ': native geometry');
      assert.equal(info.source_language, 'amdgpu');
      assert.equal(info.wave_kind, 'wave');
      assert((await page.locator('#run-header .facts').textContent()).includes(info.declared_only ? String(width) : 'wave' + width));
      if (!info.declared_only) {
        assert.equal(await page.locator('#tab-checks .check').count(), 4);
        assert(!(await page.locator('#tab-checks').textContent()).includes('gfx950 graph contract'), 'target-neutral checker label');
      }
      if (info.events && info.threads > 1) {
        assert(info.drawn_groups.some(g => g.startsWith('wave ')), index[i].key + ': canvas draws AMD wave headers');
        assert(!info.drawn_groups.some(g => g.startsWith('warp ')), index[i].key + ': AMD canvas is not grouped as a warp');
      }
      if (info.threads) assert(info.lane_labels.includes('w' + Math.floor((info.threads - 1) / width) + ':l' + ((info.threads - 1) % width)), index[i].key + ': final physical lane');
    } else if (info.events) {
      assert.equal(info.wave, 32, index[i].key + ': PTX compatibility');
    }
    if (info.events) {
      const goto = page.getByRole('textbox', { name: 'Go to event', exact: true });
      await goto.fill('e0');
      await goto.press('Enter');
      await page.locator('[data-tab="event"]').click();
      assert.equal(await page.locator('#tab-event .event-id').textContent(), 'e0');
      await page.locator('[data-tab="source"]').click();
      const mapped = page.locator('#tab-source .src-line.has-events');
      if (await mapped.count()) {
        await mapped.first().click();
        assert.equal(await page.locator('#focus-bar').isVisible(), true);
      }
      await page.locator('[data-tab="checks"]').click();
    } else {
      await page.locator('[data-tab="source"]').click();
      assert((await page.locator('#tab-source').textContent()).length > 0, 'failed trace retains source');
      if (info.source_language === 'amdgpu') assert(await page.locator('#tab-source .syn-dir, #tab-source .syn-op').count() > 0, 'native failed source highlighting');
      await page.locator('[data-tab="checks"]').click();
    }
    opened.push({ key: index[i].key, status: index[i].status, ...info });
  }
  for (const target of ['gfx942', 'gfx950', 'gfx1250']) {
    assert(opened.some(r => r.target.some(t => t.startsWith(target))), 'mixed store requires ' + target);
  }
  assert(opened.some(r => r.source_language === 'ptx' && r.events), 'mixed store requires executed PTX');
  const gfx1250 = opened.filter(r => r.target.includes('gfx1250'));
  assert(gfx1250.some(r => r.status === 'race-free'), 'gfx1250 positive graph control required');
  assert(gfx1250.some(r => ['race-condition', 'check-failed', 'deadlock'].includes(r.status)), 'gfx1250 typed harmful graph control required');
  assert(gfx1250.some(r => r.threads > 32 && r.threads % 32 !== 0), 'gfx1250 partial wave required');
  assert(gfx1250.some(r => !r.events && r.status === 'unsupported'), 'gfx1250 eventless unsupported source required');
  for (const feature of ['wait', 'wmma', 'tensor', 'delay', 'signal', 'barrier_wait', 'release']) {
    const run = opened.findIndex(r => r.target.includes('gfx1250') && r.feature_events[feature]);
    assert(run >= 0, 'gfx1250 ' + feature + ' event required');
    const event = opened[run].feature_events[feature];
    await open(run);
    const goto = page.getByRole('textbox', { name: 'Go to event', exact: true });
    await goto.fill('e' + event.event); await goto.press('Enter');
    await page.locator('[data-tab="event"]').click();
    assert.equal(await page.locator('#tab-event .event-label').textContent(), event.label);
    if (event.line != null) {
      await page.locator('[data-tab="source"]').click();
      assert.equal(await page.locator('#tab-source .src-line.current').getAttribute('data-line'), String(event.line), feature + ': source link');
    }
  }
  const gfx1250Failure = opened.findIndex(r => r.target.includes('gfx1250') && r.status === 'race-condition');
  assert(gfx1250Failure >= 0, 'gfx1250 readiness or memory failure required');
  await open(gfx1250Failure);
  await page.locator('[data-tab="checks"]').click();
  await page.locator('#tab-checks .event-chip').first().click();
  await page.locator('[data-tab="event"]').click();
  assert(await page.locator('#tab-event .event-id').count(), 'gfx1250 typed witness navigates to an event');
  await page.screenshot({ path: path.join(output, 'gfx1250-typed-finding.png'), fullPage: true });
  const native = opened.findIndex(r => r.target.some(t => t.startsWith('gfx942')) && r.status === 'race-condition');
  assert(native >= 0, 'real gfx942 failed-wait/barrier control required');
  await open(native);
  const filter = page.getByRole('textbox', { name: 'Threads to show', exact: true });
  await filter.fill('0-1,64');
  await page.waitForTimeout(200); // the real UI's filter debounce is150ms
  assert(!(await filter.getAttribute('class') || '').includes('invalid'));
  await filter.fill('999999');
  await page.waitForTimeout(200);
  assert(!(await filter.getAttribute('class') || '').includes('invalid'), 'zero-match lane filter remains valid');
  await page.screenshot({ path: path.join(output, 'zero-visible-lanes.png'), fullPage: true });
  await filter.fill('bad!');
  await page.waitForTimeout(200);
  assert((await filter.getAttribute('class') || '').includes('invalid'));
  await filter.fill('');
  await page.waitForTimeout(200);
  const goto = page.getByRole('textbox', { name: 'Go to event', exact: true });
  await goto.fill('e0');
  await goto.press('Enter');
  await page.locator('[data-tab="event"]').click();
  assert.equal(await page.locator('#tab-event .event-id').textContent(), 'e0', 'event navigation recovers after empty lane filters');
  await page.locator('[data-tab="checks"]').click();
  const finding = page.locator('#tab-checks .event-chip').first();
  if (await finding.count()) {
    await finding.click();
    await page.locator('[data-tab="event"]').click();
    assert(await page.locator('#tab-event .event-id').count());
  }
  await page.screenshot({ path: path.join(output, 'gfx942-failed-readiness.png'), fullPage: true });
  await page.locator('#test-filter').fill('hipkittens');
  const matches = await page.locator('.test-item').count();
  assert(matches > 0 && matches < index.length, 'test search filters the mixed store');
  await page.locator('#test-filter').fill('');
  const unsupported = index.findIndex(r => r.test === 'hipkittens-softmax');
  assert(unsupported >= 0);
  await open(unsupported);
  assert.equal(index[unsupported].status, 'unsupported', 'valid unmodeled app remains unsupported');
  assert((await page.locator('#tab-checks').textContent()).includes('never started'));
  await page.locator('[data-tab="source"]').click();
  assert(await page.locator('#tab-source .syn-reg').count() > 0, 'native registers are highlighted');
  await page.screenshot({ path: path.join(output, 'hipkittens-unsupported.png'), fullPage: true });
  await page.locator('#theme-toggle').click();
  const status = page.locator('#status-filter .status-chip').filter({ hasText: /race.free/i }).first();
  await status.click({ modifiers: ['Shift'] });
  assert(await page.locator('.test-item').count() < index.length, 'status filter works');
  await page.getByRole('button', { name: 'Shortcuts' }).click();
  assert(await page.locator('#help').isVisible());
  await page.locator('#help-close').click();
  assert.deepEqual(errors, [], 'no browser exceptions or console errors');
  const sha256 = value => crypto.createHash('sha256').update(value).digest('hex');
  const documents = await page.evaluate(() => [...document.querySelectorAll('script[id^="run-"]')].map(e => ({ id: e.id, text: e.textContent })));
  const receipt = { scope: 'Rendering and interaction only; hardware validation pending',
    browser: browser.version(), html, html_sha256: sha256(fs.readFileSync(html)), script_sha256: sha256(fs.readFileSync(__filename)),
    documents: documents.map(d => ({ id: d.id, sha256: sha256(d.text) })), runs: index.length, opened, assertions: 'all runs rendered; PTX/gfx942/gfx950/gfx1250; actual canvas wave/warp grouping; four native checks; source mapping/selection; typed failures; partial waves; filters; eventless unsupported source; theme/help', browser_errors: errors };
  fs.writeFileSync(path.join(output, 'browser-review.json'), JSON.stringify(receipt, null, 2) + '\n');
  await browser.close();
  console.log(`PASS: ${index.length} mixed runs in a real browser; evidence ${output}`);
})().catch(async error => { console.error(error); if (activeBrowser) await activeBrowser.close(); process.exitCode = 1; });
