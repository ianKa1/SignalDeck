# Implementation Plan: dw-15-wheel-spotlight

Spec: `pipeline/specs/dw-15-wheel-spotlight.md` (PASS, `logs/dw-15-wheel-spotlight/06-spec-review.md`).
Epic: `pipeline/epics/divination-web.md`. The spec's Architecture section is
the structure; this file is the ORDER only.

Commands run from the repo root (or the worktree the coordinator assigns).
Web tests: `npx vitest run <file>` from `web-divination/`; native: `npx jest
<file>` from `app-native/`. Tick a box only after its done-when passed and
its `/git-commit` landed (`(<type>): dw-15-wheel-spotlight — <summary>`).
Steps 1–11 are `implementing`, 12–13 `validating`, 14 `docs-sync`. Load
`/frontend-design` before step 10.

## Settled review notes

- **N1 — `data-spotlight` at rest.** `.chart-stage` ALWAYS carries
  `data-spotlight`. With zero beams (full chart at rest, D5; or a focus
  that yields none) it reads `static` — no layer is mounted, and the
  rendering is dw-1's static wheel. The stage derives it: zero beams →
  `static`; otherwise the layer's last reported status (`loading` until the
  first report). When beams drop to zero after `live`, it returns to
  `static` in the same render.
- **N2 — K2's `u_time` is `π / 4.8` (≈ 0.654498 s).** That is the first
  breathing peak (`sin(2.4·t) = 1`, so breathe = 1.0). There the comet sits
  at pulsePos ≈ 0.144 with a full envelope, away from the midpoint. Expected
  midpoint alpha is ≈ 0.95+ (tube 0.8 plus a pulse tail), far over 0.3. The
  far point stays ≈ 0. The test names the constant and cites this note.
- **N3 — F4 wording.** Jupiter is in Venus's family, so it never carried
  `data-focus-out`. F4 asserts Jupiter LACKS it, not that it was removed.

## Steps

- [x] **1. Dependency.** At the repo root run
  `npm install canvaskit-wasm@0.41.0 --save-exact --workspace web-divination`
  (never inside the workspace, so it dedupes with native's copy).
  Files: `web-divination/package.json`, `package-lock.json`.
  Done when: package.json lists `"canvaskit-wasm": "0.41.0"`,
  `npm ls canvaskit-wasm` shows a single 0.41.0 (deduped), and `npm test`
  is still green.

- [x] **2. Core additions (C1–C3).** `packages/core/src/chart-view/spotlight.ts`
  gains `spotlightUniformArray`, `SpotlightChord` and `spotlightChord`, per
  the spec's contracts. `chart-view/index.ts` exports all three.
  `SPOTLIGHT_SKSL` is untouched. New
  `web-divination/src/chart/spotlight/core-spotlight.test.ts`: the C1
  sha256 via `crypto.subtle`, pinned to the value at 416c3dd (compute it
  from `git show 416c3dd:packages/core/src/chart-view/spotlight.ts`); C2
  order; C3's four cases on fixture F plus a synthetic 359°/1° conjunction.
  Done when: that file passes, and
  `git diff 416c3dd -- packages/core/src/chart-view/spotlight.ts` shows no
  hunk inside the SkSL template.

- [x] **3. Native delegates the chord (C4).** In
  `app-native/src/chart/Spotlight.tsx`, `spotlightLineFor` calls
  `spotlightChord(aspect, chart, ACTIVE_WHEEL_VIEW.rHub)`, then keeps its
  own `frame.toPx` and colour. The local midpoint derivation goes.
  Done when: `npx jest src/chart/spotlight.test.tsx src/screens/spotlight-polish.test.tsx src/screens/factor-highlight.test.tsx`
  passes unchanged, and `grep -c "lonA + lonB" app-native/src/chart/Spotlight.tsx`
  prints 0.

- [x] **4. Theme leaves.** Add `web-divination/src/theme/rgb.ts` (`rgb01`:
  hex only, throws otherwise) and `theme/motion.ts` (`useReducedMotion`,
  a live `matchMedia` subscription using DiceCard's query string). Add
  sibling tests: every `webTokens.aspect`/`persona` value parses; a
  non-hex input throws; the hook flips on a `change` event.
  Done when: the two tests pass, and `npx jest src/architecture.test.ts`
  (G7 leaf rule, colour guard) is green.

- [x] **5. Pure focus and beams (B1–B5).** Add `web-divination/src/chart/focus.ts`
  (`focusFor`) and `chart/spotlight/beams.ts` (`beamsFor`, `toBoxPx`,
  `VOICE_GLOW`, `FOCUS_GLOW`, cap 12 by orb). Tests `chart/focus.test.ts`
  (set membership over F: Venus and Saturn, with and without an
  activation) and `chart/spotlight/beams.test.ts` (B1–B5, including the
  time-unknown F for B4).
  Done when: both files pass and the G4 arithmetic guard is green
  (`npx jest src/architecture.test.ts`).

- [x] **6. Engine (K1, K2).** Add `web-divination/src/chart/spotlight/engine.ts`
  per the contract: `initCanvasKit(locateFile?)`, the memoised
  `loadEngine` with the host probe first, `start` with its rAF loop, and
  `drawBeams`. Add `chart/spotlight/canvaskit.node.test.ts`
  (`// @vitest-environment node`) importing only `./engine`: K1 on the
  effect's uniforms; K2 on a 300×300 `MakeSurface`, `u_time = π/4.8` (N2),
  reading alpha with `readPixels`.
  Done when: `npx vitest run src/chart/spotlight/canvaskit.node.test.ts`
  passes, and `npm run typecheck --workspace web-divination` is clean.

- [x] **7. Guards + CLAUDE.md, one commit (C1 guard half, G1, G2).** In
  `app-native/src/architecture.test.ts`, add the four symbols to
  `ONE_DEFINITION_SYMBOLS`, G14 (raw-text shader markers over the three
  trees, skipping the guard file itself) and G15 (comment-stripped single
  `canvaskit-wasm` importer, no exemption), each with a synthetic
  self-check. Replace CLAUDE.md rule 1's "NOTE the weakened claim …"
  passage with the spec's text, in the SAME commit.
  Done when: `npx jest src/architecture.test.ts src/color-guard.test.ts`
  passes, and a temporary second importer of `canvaskit-wasm`
  (reverted) turns G15 red.

- [x] **8. SpotlightLayer (L1–L3).** Add `web-divination/src/chart/spotlight/SpotlightLayer.tsx`:
  reduced motion or no beams means nothing mounts and `loadEngine` is
  never called; otherwise it moves loading → live/static, renders the
  canvas with `data-beam-keys`, writes `data-frames` through a ref about
  every 250 ms, and disposes on unmount. Its test
  (`SpotlightLayer.test.tsx`) injects a fake engine or loader spy (module
  mock of `./engine`).
  Done when: `npx vitest run src/chart/spotlight/SpotlightLayer.test.tsx`
  passes L1–L3 with no unhandled rejection reported by vitest.

- [x] **9. Wheel focus markup + CSS (F6).** `web-divination/src/chart/ChartWheel.tsx`
  gets the optional `focus` prop (`data-focus`, `data-focus-out`).
  `chart/wheel.css` gains the focus hide/dim rules (opacity 0.16, 480 ms
  opacity crossfade), the `.chart-stage[data-spotlight='live']` rules that
  drop the lit-chord and conjunction-dot filter, `.chart-stage__disc` and
  `.chart-stage__beams` (400 ms fade-in, `pointer-events: none`), and
  their reduced-motion removals.
  Done when: `ChartWheel.test.tsx` passes unchanged (no-prop markup is
  byte-identical), a new CSS test reading `wheel.css?raw` asserts F6, and
  the colour guard is green.

- [x] **10. Stage, toggle, App wiring (F1–F5).** Load `/frontend-design`
  first. `chart/ChartStage.tsx` takes the `persona` prop, owns the
  `{persona, full}` state, wraps the svg in the disc with a ResizeObserver
  size, mounts the layer and the `button[data-focus-toggle]` (quiet button,
  `--char` glyph), and sets `data-spotlight` (N1). `app/App.tsx:76` passes
  `persona={active}`. `i18n/en.ts`/`zh.ts` gain `chart.focusShowAll` and
  `chart.focusOn`. New `chart/ChartStage.focus.test.tsx` mounts the app the
  way the existing App tests pass dw-12's gate.
  Done when: the new file passes F1–F5, and `src/i18n.test.ts` plus the
  existing `ChartStage.test.tsx` are green.

- [x] **11. Full client gate.** Run `npm test` and `npm run typecheck` at
  the root, and `npm run build --workspace web-divination` (the `?url`
  wasm must bundle).
  Done when: all three exit 0. Every existing suite passes with no
  assertion edited except where this plan names it.

- [x] **12. Validating: suites.** `npm test`, `npm run typecheck`, and
  `cd server && DATABASE_URL= conda run -n astrology pytest -q` (no server
  change, so this is a regression check).
  Done when: all green, with counts recorded in
  `logs/dw-15-wheel-spotlight/NN-validating.md`.

- [x] **13. Validating: real app (R1–R5).** Leave :8000/:5173 alone. Use
  backend **:8001** and Vite **:5174**. NEVER use the root `.env`'s
  `DATABASE_URL` (shared remote Postgres) and never `--env-file .env`.
  Scratch files go under the session scratchpad `dw15/` only.
  - **Gate (dw-12):** `initdb -U astrace --auth=trust` into
    `scratchpad/dw15/pg`, then `pg_ctl` on a free port (check `lsof`) with
    `listen_addresses=127.0.0.1` and `unix_socket_directories=''`, then
    `createdb astrace_dw15`.
  - **Backend, explicit env only:** `DATABASE_URL=postgresql://astrace@127.0.0.1:<port>/astrace_dw15
    ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5174
    GOOGLE_CLIENT_ID=dw15-placeholder.apps.googleusercontent.com conda run
    --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8001`.
    Check that `curl localhost:8001/api/health` shows the local db.
  - **Bearer pair:** a scratch `mint.py` (dw-12's recipe in
    `logs/dw-12-google-sign-in/05-validating.md`: `_upsert_user` +
    `_mint_bearer` on the throwaway db, `PYTHONPATH=server`, and it asserts
    the 127.0.0.1 URL prefix). Write `astrace.auth.access`, `.refresh` and
    `.expiresAt` through `javascript_tool`, then reload.
  - **Web:** `cd web-divination && VITE_API_BASE=http://localhost:8001
    GOOGLE_CLIENT_ID=dw15-placeholder.apps.googleusercontent.com npx vite --port 5174`.
    If the wasm 404s, apply the spec's `optimizeDeps.exclude` contingency
    in `vite.config.ts` as a `fix` commit and restart.
  - **Drive:** enter F through the form and drive R1–R3 and R5 with
    claude-in-chrome, keeping the tab in the foreground. R4 uses headless
    Chrome + CDP `Emulation.setEmulatedMedia` (dw-4 A5 precedent script).
  Done when: R1–R5 are recorded with observed values, R1–R3 screenshots
  are in the log, the console has no errors, and uvicorn, Vite and the
  cluster are stopped (`pg_ctl stop`, ports free).

- [x] **14. Docs-sync.** Run `/update-architecture-doc` on `docs/ARCHITECTURE.md`
  (the web spotlight layer, core `spotlightChord`/`spotlightUniformArray`,
  G14/G15). Write `docs/features/dw-15-wheel-spotlight.md` describing what
  was actually built, including N1 and N2. Update
  `pipeline/epics/divination-web.md`: add dw-15 under "Built so far", and
  add the canvaskit edge and the `theme/rgb`/`motion` leaves to the
  dependency rules and target modules. The CLAUDE.md rule-1 text already
  landed in step 7: only re-check it against the code.
  Done when: `git diff --stat` touches only those docs, and a
  `grep -n "canvaskit" CLAUDE.md docs/ARCHITECTURE.md` names engine.ts as
  the sole importer in the walked trees.

## Acceptance map

| Criterion | Step(s) | Where it passes |
|---|---|---|
| C1 | 2, 7 | core-spotlight.test.ts sha pin; one-definition enumeration |
| C2 | 2 | core-spotlight.test.ts |
| C3 | 2 | core-spotlight.test.ts |
| C4 | 3 | native spotlight suites + grep |
| G1 | 6, 7 | G14/G15 + self-checks; K test imports only `./engine` |
| G2 | 4, 5, 7, 11 | architecture.test.ts, color-guard.test.ts |
| K1 | 6 | canvaskit.node.test.ts |
| K2 | 6 | canvaskit.node.test.ts, `u_time = π/4.8` (N2) |
| B1–B5 | 5 | beams.test.ts |
| F1–F5 | 10 | ChartStage.focus.test.tsx (F4 per N3) |
| F6 | 9 | wheel.css raw-text test |
| L1–L3 | 8 | SpotlightLayer.test.tsx |
| R1–R5 | 13 | real app, validating log |

## Risks for the implementer

- **The node-environment test still runs `setupFiles`.**
  `src/test-setup.ts` runs under `// @vitest-environment node` too. Its
  `afterEach` calls `localStorage.clear()`, which throws a ReferenceError
  in node. Guard it with `typeof localStorage !== 'undefined'`; that is a
  one-line edit in step 6.
- **Typecheck for `?url`.** The tsconfig already has
  `types: ["vite/client"]`, so the `?url` import types resolve. The
  canvaskit package types come from its own `types/`. Do not add a cast.
- **G15 must stay green in tests.** Mock `./engine` in the layer and stage
  tests, never `canvaskit-wasm` itself: a `vi.mock('canvaskit-wasm')`
  specifier would break G15.
- **The memoised `loadEngine` leaks across tests.** Expose no reset.
  Mock the module per test file instead, so L1's null result does not
  poison L2/L3.
- **`data-frames` in R1 needs a foreground tab.** Take the two reads ≥ 2.5 s
  apart while the tab has focus.
- **App.tsx merges with dw-14.** The one-prop change at :76 is a known
  conflict hunk with dw-14's router. Keep both at landing.
