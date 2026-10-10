# 05 — validating (2026-09-29, parallel-wave worker)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-17-web-two-pane-layout`. Evidence files in
`/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/dw17/`
(scenario scripts r1–r5.mjs, home.mjs, ovf.mjs, cdp.mjs, mint.py; screenshots).

## Environment (never the Neon URLs, never `--env-file`)
- Throwaway cluster: `initdb -D scratchpad/dw17-pg -U astrace --auth=trust -E UTF8`; `pg_ctl … -o "-p 54317 -c unix_socket_directories=''" start`;
  `createdb -h 127.0.0.1 -p 54317 -U astrace astrace_dw17`. Shell env had no DATABASE_URL/WEB_DATABASE_URL (`env | grep -c` → 0).
- Backend: `DATABASE_URL=postgresql://astrace@127.0.0.1:54317/astrace_dw17 WEB_DATABASE_URL= CORS_ALLOW_ORIGINS=http://localhost:5175
  ANALYSIS_LLM=claude-cli GOOGLE_CLIENT_ID=dw17-placeholder.apps.googleusercontent.com conda run --no-capture-output -n astrology
  uvicorn app.main:app --app-dir server --port 8002`. `GET :8002/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`.
- Web: `VITE_API_BASE=http://localhost:8002 GOOGLE_CLIENT_ID=… npx vite --port 5175 --strictPort` (200).
- Chrome 154 headless, `--remote-debugging-port=9318 --user-data-dir=scratchpad/dw17-chrome`; driver = dw-12's cdp.mjs copied (port 9318 + an
  `Emulation.setDeviceMetricsOverride` viewport helper).
- Mint (validation only, not shipped; asserts the 54317 URL): `_upsert_user` + `_mint_bearer` →
  `dw17.real@example.com e043093f-ed35-44f3-976c-53a4416a0b24 dhyy3V… 2026-10-06T21:01:58…`; written to the three `astrace.auth.*` KV keys;
  birth = Beijing 1990-06-15 08:30 fixture in `astrology.birthData.v1.traveler`.

## Real app
- **R1 PASS (1440×900).** `/chat/venus`: stage `x116 w588 h721`, side `x736 w588 h721` (equal, side by side, same top 155);
  `document.documentElement.scrollHeight` 900 = innerHeight 900; composer bottom 875 ≤ 900; disc 549×549; toggle + caption under it
  (caption bottom 871); jumps `display:none`; `/big three|Placements/i` in body text → false; `.placements, .big-three, [data-placement]` → 0;
  chip "☉1990-06-15·Beijing", title "1990-06-15 · 08:30 · Beijing (Asia/Shanghai)"; spotlight `live`. Screenshot `r1-desktop.png`.
- **R2 PASS.** One `click()` on the chip → dialog "Your birth" with the form, `aria-expanded="true"`, focus on `date`. Country GB, typed "London",
  picked the option (dialog stayed open: the city list is inside, N3) (`r2-picked.png`); "Cast the chart" → dialog closed, chip
  "☉1990-06-15·London", title "… London (Europe/London)", focus back on the chip, KV location London / Europe/London, 10 planets, Moon node
  moved; new :8002 requests `POST /api/chart`, `POST /api/divination/persona` (`r2-after.png`).
- **R3 PASS (first try, no retry).** claude-cli Venus turn "Where does my Venus sit in my chart, and what does it say about how I love?" →
  4 pressable pills; reply began "Oh, you've got a good one. Yours is ♀♉︎10 Venus in Taurus, 10th house…". Log `scrollHeight 1032 > clientHeight
  397`, pinned at bottom (autoscroll works in the flex-filled log); page scrollHeight still 900. Pill "Venus in Taurus, 10th house" →
  `aria-pressed=true`, wheel `data-active`, `data-lit` on Venus (planet + node) (`r3-pill-lit.png`). Toggle: "Show full chart"/false/focus Venus →
  "Focus on Venus"/true/focus null (`r3-full-chart.png`) → back to "Show full chart"/false/Venus.
- **R4 — first run FAILED two things, fixed, re-run PASS (390×844, mobile).** First run: chart pane 300 px wide instead of 358 (inherited
  `.layout { align-items: start }` shrink-wraps in the flex column) and the composer row overflowed (SEND clipped at the right edge; now visible as
  a horizontal scrollbar in the pane scroller — the clipping pre-dates dw-17 at this width). Fixes: `align-items: stretch` on the narrow
  `.layout--chat`; `.chat__actions` wraps under 520 px with the hint on its own line (commit 2089259). Re-run: masthead bottom 209; chat pane first
  at y 237 (h 583, bottom 820), composer bottom 819 ≤ 844 without scrolling; stage after it at y 856 w 358, disc 358×358; layout scrollWidth 358 =
  clientWidth, Send right edge 349. "Chart ↓" → layout scrollTop 563, disc y 347–705 (in view); "↑ Chat" → scrollTop 0; path stays `/chat/venus`
  (no hash). No birth data: form first at y 237, chat at y 897, no jumps. Screenshots `r4-phone-chat-first.png`, `r4-phone-chart.png`,
  `r4-phone-no-birth.png`.
- **R5 PASS.** `/` → plate link → `/chat/venus` (two panes, shell--chat) → running head → `/sessions` → Back `/chat/venus` → Back `/` → Forward
  `/chat/venus` → Forward `/sessions`, each with the right screen and title. Back to `/chat/venus`, reload → stage 588 / side 588 at x 736,
  scrollHeight 900 = innerHeight (`r5-reload.png`).
- Extra (W5 on the real app): Home chip opens its popover; first run it ran past the content column (right 1353 vs column edge 1317) → Home's
  colophon anchors it right (roster.css); re-run left 901 right 1317 (`home-popover.png`).

## Suites (after the fixes)
- `npm test`: jest `Test Suites: 90 passed, 90 total`, `Tests: 1078 passed, 1078 total` (architecture, colour, text guards included);
  vitest `Test Files 43 passed (43)`, `Tests 394 passed (394)`. `npm run typecheck` EXIT 0. `npm run build` (web-divination) OK (only the
  existing chunk-size warning).

## Teardown
uvicorn :8002, Vite :5175, Chrome :9318 killed; `pg_ctl stop`; `scratchpad/dw17-pg` and `scratchpad/dw17-chrome` removed.
`lsof -iTCP:{8002,5175,9318,54317} -sTCP:LISTEN` → 0 each. Nobody else's port or directory touched.

Status: validating → docs-sync. Fixes found here were made in place (validating "fix and stay"); no trip back to implementing.
