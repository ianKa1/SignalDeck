# 04 — implementing (parallel-wave worker #1)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-4-wheel-activation`, branch
`feature/dw-4-wheel-activation`. Every command runs from the worktree root
unless stated.

## Step 0 — worktree prep (check only)

- `git branch --show-current` → `feature/dw-4-wheel-activation`
- `ls -l .env server/data/` → `.env -> /Users/kaimao/Projects/astrology/.env`;
  `seas_18.se1`, `semo_18.se1`, `sepl_18.se1` symlinks into the primary
  checkout; no `*.db` present (none shared).
- `node_modules/@astrace/core -> ../../packages/core`
- Baseline `npm run typecheck`: both `tsc --noEmit` clean.
- Baseline `npm test`: `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`
  (jest); `Test Files 13 passed (13)` / `Tests 72 passed (72)` (vitest).
- No commit (nothing changed).

## Step 1 — the store and the mapping

New `web-divination/src/chart/wheel-activation.ts` (+ `.test.ts`).
- `npx vitest run src/chart/wheel-activation.test.ts` → `Test Files 1 passed (1)`,
  `Tests 4 passed (4)` (T1, T2, T3, T6).
- Root `npm run typecheck` clean; root `npm test`: jest `90 passed / 1069 passed`
  (guards G1/G4/G5 accept the file), vitest `14 passed (14)` / `76 passed (76)`.
- Commit `13dfe99`.

## Step 2 — wheel attributes

`ChartWheel.tsx`: optional `activation` prop → `data-active` on the svg,
`data-lit`/`data-echo` on planet groups, chords, conjunction dots, hub nodes
(incl. the Ascendant node); hub circles always carry `data-planet-node`.
- `npx vitest run src/chart/ChartWheel.test.tsx` → `Tests 6 passed (6)`
  (dw-1's three cases unedited + T4 ×2 + T5).

## Step 3 — stage wiring

`ChartStage.tsx`: `activationFor(shown, useActivation()?.refs ?? [])` → wheel;
remount key unchanged. New ChartStage test: `showRefs([VENUS])` on the empty
ring → no `data-active`; on the ready fixture wheel → `data-active` + Venus
`data-lit`; clear → none.
- `npx vitest run src/chart` → `Test Files 5 passed (5)`, `Tests 19 passed (19)`.
- Root: typecheck clean; jest `90 passed / 1069 passed`; vitest `14 passed (14)` / `80 passed (80)`.
- Commits `9b67b84` (step 2), `b9e7bdd` (step 3).

## Step 4 — wheel look and motion

`/frontend-design` loaded. `wheel.css`: base transition 900ms ease-in-out on
zodiac, houses, planet, planet-glyph, tick, chord, conjunction, node;
`.wheel[data-active] …` 600ms ease-out; dim 0.18, ring+houses 0.55, echo 0.6;
lit planet glyph `--venus`, tick `--venus`, group glow `drop-shadow(0 0 3px var(--venus)) drop-shadow(0 0 9px var(--venus-ghost))`;
lit hub node fill `--venus` + same glow; lit chord width 2.2, opacity 1, glow in
its `--aspect-<type>`; lit conjunction glow `--aspect-conjunction`. Reduced motion:
`transition: none` on both selector sets. Five reveal rules `both` → `backwards`
(keyframes untouched).
- G3: `grep -n "animation:.* both" web-divination/src/chart/wheel.css` → no output.
- Root `npm test`: jest `90 passed / 1069 passed` (colour guard included); vitest `14 passed (14)` / `80 passed (80)`.
- Commit `38b3a62`.

## Step 5 — chat drives it

- `useChat.ts`: `clearActivation()` first in `run` (send + Retry);
  `showRefs(chartRefs)` right after a non-empty finished persona append;
  shrink-clear effect (D1: last-seen transcript length ref; a drop clears).
- `ChatPanel.tsx`: `ChartRefChips` takes the entry index; each `li` holds a
  `button type="button"` with `aria-pressed = (activation.chip === "<entry>:<ref>")`;
  click → pressed ? clear : `showRefs([ref], id)`. The aspect `aria-label`
  moved from the `li` to the button, so the three dw-3 assertions that read it
  from the `li` now read it from `li button` (W2, W2 zh, W3 remount — the
  accessible NAME is unchanged; only the element carrying it moved).
- `chat.css`: only the dw-3 chip block. `.chat__ref` keeps the rise-in
  animation; the seal look moved onto `.chat__ref-button` (same border,
  padding, font), plus hover/focus `--theme-ghost`, focus-visible 1px `--voice`
  outline offset 2px, pressed border `--venus` + glyph glow
  `drop-shadow(0 0 3px var(--venus-ghost))`, reduced-motion `transition: none`.
- Tests: dw-3 W4 replaced by W4 (en) + W4 (zh); `clearActivation()` added to
  the file's `beforeEach`; a D1 shrink-clear test in an appended describe.
  App.test: appended `describe('App wheel activation (dw-4)')` with W1, W2,
  W3, W5, W6 (every module re-imported after `resetModules`, a fresh gated
  StreamPost installed through the re-imported core platform).
- `npx vitest run src/chat` → `Test Files 2 passed (2)`, `Tests 35 passed (35)`;
  `npx vitest run src/app` → `Tests 8 passed (8)`.
- Root: typecheck clean (both workspaces); jest `Test Suites: 90 passed, 90 total`,
  `Tests: 1069 passed, 1069 total` (guards, colour guard, native i18n parity);
  vitest `Test Files 14 passed (14)`, `Tests 87 passed (87)` (web i18n parity, no new key).

Status: implementing complete → validating.
