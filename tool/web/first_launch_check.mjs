// Teacher review 6, finding 1: on the web, what a child did in the FIRST
// launch must still be there after the browser is closed and opened again.
//
//   node tool/web/first_launch_check.mjs build/web
//
// Serves the web build, then for each browser storage drift can pick
// (IndexedDB normally; OPFS when the page is cross-origin isolated) starts
// headless Chrome with a new profile, completes onboarding, closes Chrome,
// starts it again with the same profile and checks the child is listed.
// Needs Node 22+ and Chrome (CHROME=path to override). Exits 1 on failure.
import { spawn } from 'node:child_process';
import { createReadStream, existsSync, mkdtempSync, readFileSync, rmSync, statSync } from 'node:fs';
import http from 'node:http';
import { tmpdir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';

const web = resolve(process.argv[2] ?? 'build/web');
const chrome = process.env.CHROME ?? (process.platform === 'win32'
  ? 'C:/Program Files/Google/Chrome/Application/chrome.exe'
  : 'google-chrome');
const child = 'Nour';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.webp': 'image/webp', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf',
};

function serve(isolated) {
  const server = http.createServer((req, res) => {
    const path = decodeURIComponent(req.url.split('?')[0]);
    let file = resolve(join(web, path));
    if (!file.startsWith(web + sep) || !existsSync(file) || statSync(file).isDirectory()) {
      file = join(web, 'index.html');
    }
    res.writeHead(200, {
      'Content-Type': types[extname(file)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
      ...(isolated && {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
      }),
    });
    createReadStream(file).pipe(res);
  });
  return new Promise((r) => server.listen(0, '127.0.0.1', () => r(server)));
}

function devtools(url) {
  const ws = new WebSocket(url);
  let id = 0;
  const pending = new Map();
  const events = [];
  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    if (pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    } else events.forEach((l) => l(msg));
  };
  const opened = new Promise((r) => (ws.onopen = r));
  const send = (method, params = {}) =>
    new Promise((r) => {
      pending.set(++id, r);
      ws.send(JSON.stringify({ id, method, params }));
    });
  return { opened, send, onEvent: (l) => events.push(l) };
}

// One launch of the app in Chrome with [profile]; [act] runs on the page.
async function launch(profile, url, act) {
  const proc = spawn(chrome, [
    '--headless=new', `--user-data-dir=${profile}`, '--remote-debugging-port=0',
    '--no-first-run', '--no-default-browser-check', '--window-size=1280,800',
    ...(process.env.CI ? ['--no-sandbox'] : []), 'about:blank',
  ], { stdio: 'ignore' });
  try {
    // "<port>\n/devtools/browser/<id>". Read again on every try: Chrome
    // restarts itself once on a new profile and then listens on a new port.
    const port = () => {
      try {
        const [first, second] = readFileSync(join(profile, 'DevToolsActivePort'), 'utf8').split('\n');
        return second?.startsWith('/devtools/') ? first.trim() : null;
      } catch {
        return null;
      }
    };
    const json = async (path) => {
      for (let i = 0; ; i++) {
        try {
          return await (await fetch(`http://127.0.0.1:${port()}${path}`)).json();
        } catch (error) {
          if (i === 100) throw new Error(`Chrome did not start (${error.cause?.code ?? error})`);
          await sleep(200);
        }
      }
    };
    const version = await json('/json/version');
    const target = (await json('/json/list')).find((t) => t.type === 'page');
    const page = devtools(target.webSocketDebuggerUrl);
    await page.opened;
    page.onEvent((m) => {
      if (m.method === 'Runtime.exceptionThrown') {
        console.log('    page error:', m.params.exceptionDetails.exception?.description ?? m.params.exceptionDetails.text);
      }
    });
    await page.send('Runtime.enable');
    // The page is 1280×800 whatever the window size of headless Chrome on
    // this OS (as in the review).
    await page.send('Emulation.setDeviceMetricsOverride', {
      width: 1280, height: 800, deviceScaleFactor: 1, mobile: false,
    });
    await page.send('Page.navigate', { url });

    const evaluate = async (expression) =>
      (await page.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true }))
        .result?.result?.value;
    // The labels Flutter exposes to screen readers (turned on here).
    const screen = () => evaluate(`(async () => {
      document.querySelector('flt-semantics-placeholder')?.click();
      await new Promise(r => setTimeout(r, 200));
      return Array.from(document.querySelectorAll('flt-semantics, input'))
        .map(e => (e.getAttribute('aria-label') || (e.children.length ? '' : e.textContent) || '').trim())
        .filter(Boolean);
    })()`);
    const waitFor = async (label, seconds = 60) => {
      for (let i = 0; i < seconds * 2; i++) {
        const labels = (await screen()) ?? [];
        if (labels.includes(label)) return labels;
        await sleep(500);
      }
      throw new Error(`"${label}" never appeared; screen: ${JSON.stringify(await screen())}`);
    };
    // Taps [label]; with [next], taps again until [next] is on screen (a tap
    // during a page transition can be lost).
    const tap = async (label, next) => {
      for (let attempt = 1; ; attempt++) {
        await waitFor(label);
        await sleep(400);
        const where = () => evaluate(`(() => {
          const all = Array.from(document.querySelectorAll('flt-semantics, input'));
          const e = all.find(e => (e.getAttribute('aria-label') || '').trim() === ${JSON.stringify(label)})
            || all.find(e => !e.children.length && e.textContent.trim() === ${JSON.stringify(label)});
          const r = e.getBoundingClientRect();
          return { x: r.x + r.width / 2, y: r.y + r.height / 2, view: innerHeight };
        })()`);
        // Below the page's edge: scroll it up with the mouse wheel first.
        let at = await where();
        for (let i = 0; i < 5 && (at.y > at.view - 20 || at.y < 20); i++) {
          await page.send('Input.dispatchMouseEvent', {
            type: 'mouseWheel', x: 640, y: 400, deltaX: 0, deltaY: at.y - at.view / 2,
          });
          await sleep(500);
          at = await where();
        }
        delete at.view;
        for (const type of ['mousePressed', 'mouseReleased']) {
          await page.send('Input.dispatchMouseEvent', { type, ...at, button: 'left', clickCount: 1 });
        }
        if (!next) return sleep(600);
        try {
          return await waitFor(next, 5);
        } catch (error) {
          if (attempt === 4) throw error;
        }
      }
    };
    const type = (text) => page.send('Input.insertText', { text });
    const storage = () => evaluate(`(async () => {
      const files = [];
      async function walk(dir, prefix) {
        for await (const [name, h] of dir.entries()) {
          if (h.kind === 'directory') await walk(h, prefix + name + '/');
          else files.push(prefix + name);
        }
      }
      try { await walk(await navigator.storage.getDirectory(), ''); } catch {}
      return { indexedDb: (await indexedDB.databases()).map(d => d.name), opfs: files };
    })()`);

    const result = await act({ waitFor, tap, type, storage });
    await sleep(3000); // idle before closing, as in the review
    const browser = devtools(version.webSocketDebuggerUrl);
    await browser.opened;
    await browser.send('Browser.close');
    return result;
  } finally {
    if (proc.exitCode === null) {
      const exited = new Promise((r) => proc.on('exit', r));
      setTimeout(() => proc.kill(), 10000).unref();
      await exited;
    }
  }
}

let failed = false;
for (const [name, isolated] of [['IndexedDB', false], ['OPFS (cross-origin isolated)', true]]) {
  const server = await serve(isolated);
  const url = `http://127.0.0.1:${server.address().port}/`;
  const profile = mkdtempSync(join(tmpdir(), 'first-launch-'));
  try {
    const stored = await launch(profile, url, async ({ waitFor, tap, type, storage }) => {
      await tap('My first name');
      await type(child);
      await tap('Next', 'Back');
      await tap('Next', 'Start exploring');
      await tap('Start exploring', child);
      return storage();
    });
    const again = await launch(profile, url, async ({ waitFor }) => {
      try {
        return await waitFor(child);
      } catch (error) {
        return String(error.message);
      }
    });
    const ok = Array.isArray(again);
    console.log(`${ok ? 'PASS' : 'FAIL'} ${name}: storage ${JSON.stringify(stored)}`);
    if (!ok) {
      console.log(`    after a restart: ${again}`);
      failed = true;
    }
  } catch (error) {
    console.log(`FAIL ${name}: ${error.message}`);
    failed = true;
  } finally {
    server.close();
    // Best effort: Chrome's helpers may still be writing as it closes.
    try {
      rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
    } catch {}
  }
}
process.exit(failed ? 1 : 0);
