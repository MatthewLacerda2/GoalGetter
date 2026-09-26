#!/usr/bin/env node
// Phone screenshots of the Flutter web app, headless — so Claude can look at a
// screen without a human holding the phone (issue #58).
//
//   node tools/shot.mjs --url http://127.0.0.1:8090 /home /goals
//   node tools/shot.mjs --token .claude/token /home      # signed in
//   node tools/shot.mjs --token .claude/token --goal <id> /lesson
//
// Flutter web draws on a canvas, so the DOM says little: the PNG is the
// evidence. Three things this gets right on purpose:
//
// - The viewport is set through CDP `Emulation.setDeviceMetricsOverride`, not
//   `--window-size`, which lays the page out shorter than the file it writes.
// - A session is injected *before* the app boots, straight into the keys
//   shared_preferences reads on web: localStorage `flutter.<key>`, holding the
//   JSON encoding of the value (a string is stored with its quotes — read back
//   from a running build: `flutter.user_language` = `"en"`).
// - A session is a token *and* an active goal. The app writes the goal key
//   itself, but only at the `/` splash (AppStartController); a deep link
//   straight to /lesson skips it, so the screen photographed as its "no active
//   goal" empty state however much the student had seeded (issue #127).
//
// Needs Node >= 22 (built-in WebSocket) and chromium. No npm dependencies.
import { spawn } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  if (i === -1) return fallback;
  const [value] = args.splice(i, 2).slice(1);
  return value;
};
const baseUrl = opt("url", process.env.SHOT_URL || "http://127.0.0.1:8090").replace(/\/$/, "");
const tokenFile = opt("token", "");
const goalOption = opt("goal", "");
const outDir = opt("out", "shots");
const width = Number(opt("width", 412));
const height = Number(opt("height", 915));
const settleMs = Number(opt("settle", 1500));
const timeoutMs = Number(opt("timeout", 45000));
// `--scheme dark` photographs the phone in dark mode: the app follows the
// phone's brightness unless the student picked one (#178).
const scheme = opt("scheme", "light");
const chromium = process.env.CHROMIUM || "/usr/bin/chromium";
const routes = args.length ? args : ["/"];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitForDevtools(port) {
  for (let i = 0; i < 100; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/json/list`);
      const page = (await res.json()).find((t) => t.type === "page");
      if (page) return page.webSocketDebuggerUrl;
    } catch {}
    await sleep(100);
  }
  throw new Error("chromium never opened its devtools port");
}

function connect(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let nextId = 1;
  const pending = new Map();
  const listeners = [];
  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
    } else if (msg.method) {
      listeners.forEach((fn) => fn(msg));
    }
  };
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = nextId++;
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });
  const opened = new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = reject;
  });
  return { opened, send, on: (fn) => listeners.push(fn), close: () => ws.close() };
}

// Resolves once the network has been quiet for `settleMs` and Flutter has
// mounted its view, or rejects at `timeoutMs`.
function settle(cdp) {
  let inflight = 0;
  let lastActivity = Date.now();
  cdp.on(({ method }) => {
    if (method === "Network.requestWillBeSent") inflight++, (lastActivity = Date.now());
    if (method === "Network.loadingFinished" || method === "Network.loadingFailed") {
      inflight = Math.max(0, inflight - 1);
      lastActivity = Date.now();
    }
  });
  return async () => {
    const start = Date.now();
    lastActivity = Date.now();
    while (Date.now() - start < timeoutMs) {
      await sleep(200);
      const { result } = await cdp.send("Runtime.evaluate", {
        expression: "!!document.querySelector('flutter-view, flt-glass-pane')",
        returnByValue: true,
      });
      if (result.value && inflight === 0 && Date.now() - lastActivity > settleMs) return;
    }
    const { result } = await cdp.send("Runtime.evaluate", {
      expression: "!!document.querySelector('flutter-view, flt-glass-pane')",
      returnByValue: true,
    });
    throw new Error(
      `the app did not settle within ${timeoutMs} ms: flutter view ${result.value ? "mounted" : "missing"}, ` +
        `${inflight} request(s) still open, last network activity ${Date.now() - lastActivity} ms ago`,
    );
  };
}

// The goal the injected session is "on". `--goal` names one; with none, the
// student's active goal is read back with the same token, so the usual call
// needs nothing extra. A student with no active goal resolves to null and the
// key is left unwritten — the empty state, which is then the true screen.
async function resolveGoalId(token) {
  if (goalOption) return goalOption;
  const res = await fetch(`${baseUrl}/api/v1/goals`, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`GET /api/v1/goals answered ${res.status}`);
  const goals = await res.json();
  return goals.find((goal) => goal.is_active)?.id ?? null;
}

function sessionScript(token, goalId) {
  // Mirrors SettingsStorage's keys (frontend/lib/core/utils/settings_storage.dart).
  const entries = { access_token: token, ...(goalId ? { current_goal_id: goalId } : {}) };
  const lines = Object.entries(entries).map(
    ([key, value]) => `localStorage.setItem(${JSON.stringify("flutter." + key)}, ${JSON.stringify(JSON.stringify(value))});`,
  );
  return lines.join("\n");
}

const fileName = (route) => (route.replace(/^\/+|\/+$/g, "").replace(/[^a-zA-Z0-9]+/g, "_") || "root") + ".png";

async function main() {
  const profile = mkdtempSync(join(tmpdir(), "gg-shot-"));
  const port = 9300 + Math.floor(Math.random() * 500);
  const browser = spawn(
    chromium,
    ["--headless=new", "--enable-unsafe-swiftshader", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, "--no-first-run", "--hide-scrollbars", "about:blank"],
    { stdio: "ignore" },
  );
  try {
    const cdp = connect(await waitForDevtools(port));
    await cdp.opened;
    await cdp.send("Network.enable");
    await cdp.send("Page.enable");
    await cdp.send("Runtime.enable");
    await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 2, mobile: true });
    await cdp.send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: scheme }] });
    const waitSettled = settle(cdp);

    if (tokenFile) {
      const token = readFileSync(tokenFile, "utf8").trim();
      if (!token) throw new Error(`${tokenFile} is empty — run make claude-token`);
      let goalId = null;
      try {
        goalId = await resolveGoalId(token);
      } catch (err) {
        console.error(`shot: could not read the active goal (${err.message}); screens that need one will photograph empty`);
      }
      await cdp.send("Page.addScriptToEvaluateOnNewDocument", { source: sessionScript(token, goalId) });
    }

    mkdirSync(outDir, { recursive: true });
    for (const route of routes) {
      await cdp.send("Page.navigate", { url: baseUrl + route });
      await waitSettled();
      const { data } = await cdp.send("Page.captureScreenshot", { format: "png" });
      const path = join(outDir, fileName(route));
      writeFileSync(path, Buffer.from(data, "base64"));
      const { result } = await cdp.send("Runtime.evaluate", { expression: "location.pathname", returnByValue: true });
      console.log(`${path}  (${route} -> landed on ${result.value})`);
    }
    cdp.close();
  } finally {
    const exited = new Promise((resolve) => browser.once("exit", resolve));
    browser.kill();
    await exited;
    rmSync(profile, { recursive: true, force: true, maxRetries: 5 });
  }
}

main().catch((err) => {
  console.error(`shot: ${err.message}`);
  process.exit(1);
});
