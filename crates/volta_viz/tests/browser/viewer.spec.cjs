const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
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
  const errors = [];
  page.on('pageerror', error => { errors.push({message:String(error),stack:error.stack,url:page.url()}); fs.writeFileSync(path.join(output,'browser-errors.json'),JSON.stringify(errors,null,2)); });
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  await page.goto(pathToFileURL(html).href);
  const index = JSON.parse(await page.locator('#volta-index').textContent());
  assert(index.length > 0, 'recorded runs must exist');
  await page.screenshot({ path: path.join(output, 'overview.png'), fullPage: true });
  const opened = [];
  async function open(i) {
    await page.evaluate(key => {
      location.hash = key;
      return new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    }, index[i].key);
    await page.waitForFunction(test => document.querySelector('#run-header h1')?.textContent === test, index[i].test);
    return page.evaluate(i => {
      const d = JSON.parse(document.getElementById('run-' + i).textContent);
      return { target: d.launch?.targets || [], wave: d.launch?.wave_size, source_language: d.source_language || d.launch?.source_language,
        events: d.events?.length || 0, checks: d.checks?.length || 0, source_lines: (d.source || '').split('\n').length };
    }, i);
  }
  for (let i = 0; i < index.length; ++i) {
    const info = await open(i);
    const target = info.target.join(',');
    if (/gfx942|gfx950/.test(target)) {
      assert.equal(info.wave, 64, index[i].key + ': native wave64');
      assert.equal(info.source_language, 'amdgpu');
      assert.equal(await page.locator('#tab-checks .check').count(), 4);
      assert(!(await page.locator('#tab-checks').textContent()).includes('gfx950 graph contract'), 'target-neutral checker label');
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
  const receipt = { browser: browser.version(), html, runs: index.length, opened, assertions: 'all runs rendered; architecture grouping, four native checks, source mapping/selection, typed findings, test/status/thread filters, unsupported source, theme/help', browser_errors: errors };
  fs.writeFileSync(path.join(output, 'browser-review.json'), JSON.stringify(receipt, null, 2) + '\n');
  await browser.close();
  console.log(`PASS: ${index.length} mixed runs in a real browser; evidence ${output}`);
})().catch(async error => { console.error(error); if (activeBrowser) await activeBrowser.close(); process.exitCode = 1; });
