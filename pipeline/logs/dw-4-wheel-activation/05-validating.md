# 05 — validating (worker #1) — cycle 1 used

## Real app setup

From the worktree root, in background:
- `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5174 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`
  → `Uvicorn running on http://127.0.0.1:8001`; `/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`.
- `cd web-divination && VITE_API_BASE=http://localhost:8001 npx vite --port 5174` → `VITE v8.3.1 ready`.
- Chrome via claude-in-chrome, in a tab created for this worker (1503514205).
- Fixture birth: written to `localStorage['astrology.birthData.v1.traveler']`
  (the exact value the birth form saves: 1990-06-15 08:30, Beijing,
  Asia/Shanghai) and the page reloaded — the form UI itself was NOT driven
  (dw-1 already validated it). Wheel: 10 `[data-planet]`.

## A1 — reply lights the wheel (REAL APP, claude-cli)

Asked "Why do I keep falling for people who are hard to reach?". A
MutationObserver log of (data-active, listening, caret, chips):
`t=70699 listening, active=false` → `t=79809 caret (streaming), active=false`
→ `t=87363 chips=1, active=true`. So the wheel was unchanged while streaming.
Chips: Saturn · Saturn opposition Ascendant · Venus opposition Pluto · Venus.
`[data-lit]`: Venus|opposition|Pluto, Saturn|opposition|Ascendant, nodes
Venus/Saturn/Pluto/Ascendant, planets Venus/Saturn/Pluto — every chip's target.
Echo: Moon|sextile|Venus, Venus|sextile|Jupiter, Venus|trine|Saturn,
Venus|trine|Neptune, nodes + planets Moon/Jupiter/Neptune.
Computed after ≥1.2 s:
```
Sun - op=0.18   Moon echo op=0.6   Mercury - op=0.18   Venus LIT op=1 filter=drop-shadow
Mars - op=0.18  Jupiter echo op=0.6  Saturn LIT op=1 filter=drop-shadow
Uranus - op=0.18  Neptune echo op=0.6  Pluto LIT op=1 filter=drop-shadow   (td=0.6s)
```
Screenshot (rose-copper Venus–Pluto and Saturn–AC chords, glowing Venus/Saturn/Pluto,
dimmed rest): `/var/folders/k8/krp4szdj4dv1_9s_51qq52z00000gn/T/claude-chrome-screenshots-doWsbQ/screenshot-1790637124207-0.jpg`. PASS.

## A2 — aspect chip press (REAL APP)

Clicked the "Venus opposition Pluto" chip: `aria-pressed="true"`, lit =
{Venus|opposition|Pluto, node:Venus, node:Pluto, Venus, Pluto}, echo = [];
pressed chip `border-top-color: rgb(217, 150, 124)` = `--venus` `#d9967c`.
Screenshot (only that chord and its two ends lit):
`…/screenshot-1790637131873-1.jpg`. Clicked again: `data-active` gone, lit/echo
empty, all ten planets `op=1`, `transition-duration 0.9s`. PASS.

## A3 — follow-up clears, then new set (REAL APP)

With the Venus chip pressed (active), sent "And what does my Moon want in
love?". At the moment "listening" appeared: `active=false`; 1200 ms later
(still listening) all ten planet opacities `"1"`. The reply's chips (Moon,
Moon trine Pluto, Moon trine Jupiter, Moon square Mercury, Mercury) then lit
exactly Moon/Mercury/Jupiter/Pluto + the three aspects + their nodes. PASS.
(Incidental: one mis-aimed click unpressed the Venus chip before the send; it
was re-pressed via `button.click()` and confirmed active before sending.)

## A4 — reload (REAL APP)

After `location.reload()`: `data-active` absent, 10 planets, all 9 chips of both
replies present. Pressing the OLDER reply's "Venus opposition Pluto" chip →
`aria-pressed="true"`, lit = {Venus|opposition|Pluto, nodes Venus/Pluto, Venus, Pluto}. PASS.

## A5 — reduced motion (REAL APP in headless Chrome over CDP)

claude-in-chrome has no media emulation, so a separate headless Chrome
(`--headless=new --remote-debugging-port=9224`, fresh profile in the
scratchpad) drove the same Vite/backend with `Emulation.setEmulatedMedia
prefers-reduced-motion`. Seeded birth + a transcript with [Venus, Venus opp
Pluto] chips; pressed the aspect chip; sampled two animation frames later.

FIRST RUN FAILED the letter of A5:
`reduce.on.litVenusTd = "1e-06s"` (states did apply at once: Mars 0.18).
Cause: `theme/global.css` (dw-1) has a blanket reduced-motion rule
`* { transition-duration: 0.001ms !important }` that outranks the plain
`transition: none` in wheel.css. → back to implementing (cycle 1): the
wheel.css reduced-motion activation block now says `transition: none !important`
(beats `*` by specificity among important declarations), with a comment.

Re-run:
```
no-preference: on  {reducedMotion:false, active:true, litVenusTd:"0.6s", dimMarsOpacity:"0.925482"}  (mid-fade)
               off {active:false, marsOpacity:"0.951216", venusTd:"0.9s"}                           (mid-fade)
reduce:        on  {reducedMotion:true,  active:true, litVenusTd:"0s", litVenusOpacity:"1", litVenusFilter:true, dimMarsOpacity:"0.18"}
               off {active:false, marsOpacity:"1", venusTd:"0s"}
```
PASS (0s, and highlight changes apply at once vs. mid-fade without emulation).

## A6 — zh (REAL APP)

Switched to 中 (`lang=zh-CN`, placeholder 向金星提问…), asked
"我为什么总是爱上难以接近的人？". Chips (label 星盘所见): ♄土星 · 土星冲上升点 ·
金星冲冥王星 · ♀金星. Wheel `data-active`, lit = Venus|opposition|Pluto,
Saturn|opposition|Ascendant, nodes Venus/Saturn/Pluto/Ascendant, planets
Venus/Saturn/Pluto; Venus opacity 1. PASS.

## Automated (tests only): T1–T6, W1–W6, G1–G3

After the cycle-1 fix, from the worktree root:
- `npm run typecheck` → both `tsc --noEmit` clean.
- `npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`;
  vitest `Test Files 14 passed (14)` / `Tests 87 passed (87)`.
- `server/`: `conda run -n astrology pytest -q` → `1035 passed, 50 skipped, 1 warning in 112.83s`.
- G2 `git diff --stat feature/divination_web...HEAD` (+ the uncommitted wheel.css):
  only `web-divination/src/{app/App.test.tsx, chart/*, chat/*}` — no `server/`,
  `packages/`, `app-native/`, `App.tsx`, `tokens.ts`, `i18n/`. PASS.
- G3 `grep -n "animation:.* both" web-divination/src/chart/wheel.css` → nothing;
  reduced-motion block lists all 16 activation selectors (base + active). PASS.

## Teardown

Closed tab 1503514205 (only the pre-existing tab remains). Killed the 8001
(pid 3301) and 5174 (pid 3292) listeners I started; `lsof -iTCP:8001` and
`lsof -iTCP:5174` print nothing. Headless Chrome on 9224 exited (`pgrep` empty).

Status: validating → docs-sync. Cycles used: 1.
