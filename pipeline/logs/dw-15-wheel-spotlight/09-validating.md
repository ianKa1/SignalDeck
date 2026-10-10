# 09 — validating (dw-15-wheel-spotlight)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-15-wheel-spotlight` at 7bee835.
Plan steps 12–13.

## Step 12 — suites
- `npm test` (root; same tree as step 11, exit 0): jest `Test Suites: 90 passed, 90 total`,
  `Tests: 1075 passed, 1075 total`; vitest `Test Files 39 passed (39)`, `Tests 351 passed (351)`.
  Baseline before the feature was 1072 / 308 (+3 jest: G14, G15, self-check; +43 vitest).
  No "Not implemented" jsdom output (0 matches), no unhandled rejection.
- `npm run typecheck`: exit 0 (app-native, then web-divination).
- `npm run build --workspace web-divination`: exit 0; `canvaskit-DmFMth8j.wasm 7,155.82 kB │ gzip: 2,942.06 kB`
  emitted as a `?url` asset; loader chunk `canvaskit-BuG3NqSa.js 118.53 kB` split lazily.
- `cd server && DATABASE_URL= conda run -n astrology pytest -q`: `1380 passed, 55 skipped, 1 warning in 118.60s` (exit 0).

## Step 13 — real app (R1–R5)
Environment (all stopped afterwards):
- Throwaway Postgres: `initdb -U astrace --auth=trust` in `scratchpad/dw15/pg`,
  `pg_ctl -o "-p 54341 -k '' -c listen_addresses=127.0.0.1"`, `createdb astrace_dw15`.
- Backend :8001, explicit env only (no `--env-file`, API keys unset):
  `DATABASE_URL=postgresql://astrace@127.0.0.1:54341/astrace_dw15 ANALYSIS_LLM=claude-cli
  CORS_ALLOW_ORIGINS=http://localhost:5174 GOOGLE_CLIENT_ID=dw15-placeholder.apps.googleusercontent.com
  uvicorn app.main:app --app-dir server --port 8001`. `curl :8001/api/health` →
  `{"status":"ok","db":"ok","ephemeris":"ok"}`; `psql` on 54341 showed 12 applied migrations
  and the minted user — the backend was on the local cluster.
- Bearer pair: `scratchpad/dw15/mint.py` (dw-12 recipe, asserts the `127.0.0.1:54341` prefix)
  → user `dw15.validate@example.com` / `18830af1-8185-4ae9-91a0-d8829b22c260`, access expiring
  2026-10-06T19:36:24Z. Written to `astrace.auth.access/.refresh/.expiresAt`.
- Vite :5174: `VITE_API_BASE=http://localhost:8001 GOOGLE_CLIENT_ID=dw15-placeholder… npx vite --port 5174`.
  The wasm loaded from the dev server with NO `optimizeDeps` change (Vite pre-bundled
  `node_modules/.vite/deps/canvaskit-wasm.js` and served `canvaskit.wasm?import&url` →
  `canvaskit.wasm`), so the spec's contingency was not needed; `vite.config.ts` untouched.

### Browser — deviation D-9
Birth data F was entered THROUGH THE FORM in Claude-in-Chrome (tab on :5174, signed in via
the KV pair): date 06/15/1990, time 08:30 AM, country China (native `<select>` set by a
value setter + change event — Claude-in-Chrome cannot drive the macOS select popup), city
typed "Beijing" and picked from the list, "Cast the chart". Result: stored record
`{"date":"1990-06-15","time":"08:30","location":{"name":"Beijing","latitude":39.9075,"longitude":116.3972},"timezone":"Asia/Shanghai","schemaVersion":1}`,
stage `status: ready`, `data-spotlight: live`, `data-focus: Venus`, 1 canvas with the
5 Venus keys — but `data-frames: null`, and `document.visibilityState` read **`"hidden"`**
(`hasFocus: true`): the shared Chrome window was held by another worker's tab (:5180), so
rAF never ran (a 500 ms rAF probe hung the CDP evaluate for 45 s). R1's frame-growth check
cannot pass in a hidden tab, and bringing another session's window forward is not mine to
do. So R1–R5 were driven in MY OWN headless Chrome 154 over CDP
(`--headless=new --remote-debugging-port=9241 --user-data-dir=scratchpad/dw15/chrome-prof`,
driver `scratchpad/dw15/cdp.mjs` + `r12.mjs`/`r3.mjs`/`r3b.mjs`/`r4.mjs`), with the
same pair, `active=venus`, and the exact birth record the form had just written seeded into
`astrology.birthData.v1.traveler`. Headless reads `visibilityState: "visible"`.
Screenshots: `logs/dw-15-wheel-spotlight/shots/`.

### R1 — PASS
- ready → `data-spotlight="live"` in **407 ms** (< 5 s).
- `canvases: 1`; svg rect `{x:138.5, y:152.109375, w:640, h:640}` = canvas rect
  `{x:138.5, y:152.109375, w:640, h:640}` (0 px off); backing store `640×640` (dpr 1).
- `data-beam-keys`: `Venus|sextile|Jupiter Venus|opposition|Pluto Venus|trine|Neptune Venus|trine|Saturn Moon|sextile|Venus`
  (the 5 Venus-family keys, tightest orb first).
- `data-frames`: read 1 = `80`, read 2 (2.6 s later) = `233` → growth **153** (≥ 60).
- visible aspects (computed opacity ≠ 0): **5**; planets at opacity 0.16: `Sun, Mercury, Mars, Uranus`.
- Toggle: `"♀Show full chart"`, `aria-pressed="false"`.
- Screenshot `shots/r1-focus-live.png`: glowing teal sextiles to Jupiter and the Moon, blue
  trines to Saturn and Neptune, red opposition to Pluto, all from Venus; no other chord drawn;
  the Sun, Mercury, Mars, Uranus glyphs ghosted; zodiac ring and houses unchanged.

### R2 — PASS
- Press "Show full chart" (real mouse event): `data-focus: null`, `canvases: 0`,
  `data-spotlight: "static"`, visible aspects **20**, dimmed planets `[]`, toggle
  `"♀Focus on Venus"` `aria-pressed="true"`. Screenshot `shots/r2-full-chart.png` (the whole
  static wheel, no glow).
- Press again: `live`, 1 canvas, same 5 keys, frames counting again (`47`), 5 visible
  aspects, the same 4 planets dimmed, `"♀Show full chart"` / `"false"`.

### R3 — PASS
- Real Venus turn through claude-cli: sent "How does my Venus trine Saturn shape the way I
  love — and does my Mars square Jupiter push against it?"; `POST /api/divination/turn 200`;
  reply with pills after 20.6 s: aspect pills `Venus trine Saturn`, `Mars square Jupiter`,
  `Venus sextile Jupiter` + 4 placement pills. The reply's `done` refs activated the wheel
  (voice beams `Mars|square|Jupiter Venus|trine|Saturn`, the focus beams silenced).
- Press `Venus trine Saturn`: `aria-pressed="true"`, `data-beam-keys` = **`Venus|trine|Saturn`**
  alone; that chord lit, not focus-out, opacity 1, computed `filter: none` (live rule drops the
  SVG drop-shadow); Venus and Saturn lit, opacity 1. Screenshot `shots/r3-pill-voice-beam.png`.
  Press again: `aria-pressed="false"`, no activation, beams back to the 5 focus keys.
- Out-of-web pill `Mars square Jupiter`: `data-beam-keys` = **`Mars|square|Jupiter`**,
  `data-focus` still `Venus`; chord `{out:false, lit:true, opacity:1}`, Mars
  `{out:false, lit:true, opacity:1}`, Jupiter `{out:false, lit:true, opacity:1}`; 14 other
  out-of-focus chords still at opacity 0. Screenshot `shots/r3-out-of-web-pill.png` (one amber
  beam Mars→Jupiter; Mars glyph restored). Press again: beams back to the 5 Venus keys, Mars
  and the chord `data-focus-out` again.

### R4 — PASS (headless Chrome + CDP `Emulation.setEmulatedMedia` reduce, then reload)
- At rest: `matchMedia(reduce).matches: true`, `data-spotlight: "static"`, `canvases: 0`,
  `data-focus: "Venus"`, 24 `data-focus-out` elements, 15 chords at opacity 0,
  `performance` resource entries matching /canvaskit/: **[]** (CanvasKit never fetched).
- Press the stored `Venus trine Saturn` pill: still `static`, 0 canvases, chord lit with
  `filter: drop-shadow(rgb(127, 149, 221) 0px 0px 2.5px)`, opacity 1 (dw-4's static lit
  chord). Screenshot `shots/r4-reduced-motion-static-pill.png`.
- Extra (D10 live follow): media set to `no-preference` WITHOUT a reload → `live`, 1 canvas,
  beams `Venus|trine|Saturn`, and only now the three canvaskit requests appear
  (`.vite/deps/canvaskit-wasm.js`, `canvaskit.wasm?import&url`, `canvaskit.wasm`). Back to
  `reduce` → `static`, 0 canvases.

### R5 — PASS
With Venus picked the wheel shows just her web of aspects with the flowing glow (R1); one
press of the control shows the whole chart (R2), another returns the focus. Console across
R1–R4: `warnings []`; the only error-level entry is the network 404 for
`http://localhost:5174/favicon.ico` (the workspace ships no favicon — pre-existing, not an app
error). No exceptions, no failed app requests. Backend log: 0 tracebacks, no 4xx/5xx
(`POST /api/chart 200` ×3, `POST /api/divination/turn 200`).

## Teardown
Headless Chrome (9241), uvicorn (8001), Vite (5174) killed; `pg_ctl stop` → "server stopped";
`scratchpad/dw15/pg`, `chrome-prof`, `pair.json`, `kv.js` deleted. `lsof` on
9241/8001/5174/54341 → nothing listening. The Claude-in-Chrome tab I opened was closed; the
other session's :5180 tab was not touched.

Status transition: validating → docs-sync (0 trips back to implementing; cycles 0).
