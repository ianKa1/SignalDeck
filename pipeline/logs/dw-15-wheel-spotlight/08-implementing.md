# 08 — implementing (dw-15-wheel-spotlight)

Worker: worktree `/Users/kaimao/Projects/astrology-wt/dw-15-wheel-spotlight`,
branch `feature/dw-15-wheel-spotlight` from `feature/divination_web @ 416c3dd`.
`/frontend-design` loaded before step 8 (first UI code). Plan steps 1–11 ticked.

## Baseline (before any change, after `npm install canvaskit-wasm`)
`npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1072 passed`;
vitest `Test Files 30 passed (30)` / `Tests 308 passed (308)`.

## Steps and commits
| Step | Commit | Evidence |
|---|---|---|
| 1 dependency | d8538c6 | `npm ls canvaskit-wasm`: `app-native … canvaskit-wasm@0.41.0 deduped`, `web-divination └── canvaskit-wasm@0.41.0` (one copy); lock diff = 1 line |
| 2 core additions | e5485e5 | core-spotlight.test.ts 6/6. SKSL sha256 at 416c3dd = `846f7dc7df93240b9304aedc0aba9c7a6a2e1d6f48b166359c70a0fe1406d694` (computed from `git show 416c3dd:…/spotlight.ts` under node 25 strip-types, 3199 chars). `git diff 416c3dd -- spotlight.ts` hunks: `@@ -11,7 +11,16 @@` (header comment + imports) and `@@ -142,3 +151,55 @@` (appended functions) — none inside the SkSL template |
| 3 native delegates | 57871d5 | `npx jest src/chart/spotlight.test.tsx src/screens/spotlight-polish.test.tsx src/screens/factor-highlight.test.tsx` → 3 suites, 29 tests passed, unchanged; `grep -c "lonA + lonB" app-native/src/chart/Spotlight.tsx` → 0; app-native tsc clean |
| 4 theme leaves | 8c2d078 | rgb.test.ts + motion.test.tsx pass; architecture + color-guard 44/44 |
| 5 focus + beams | 813d6e2 | focus.test.ts + beams.test.ts 11/11; G4 green |
| 6 engine (K1/K2) | 5b836b4 | canvaskit.node.test.ts 3/3 (real CanvasKit-WASM in node); web tsc clean after deviation D-1 below |
| 7 guards + CLAUDE.md | 785cdc4 | architecture + color-guard 47/47. Planted `web-divination/src/chart/tmp-second.ts` (`import type { CanvasKit } from 'canvaskit-wasm'`) → `✕ … (G15)` with `+ "web-divination/src/chart/tmp-second.ts"`; planted `tmp-shader.ts` (`'precision mediump float;'`) → `✕ … (G14)`; both reverted |
| 8 SpotlightLayer | 846286d | SpotlightLayer.test.tsx 5/5 (L1–L3 + frame counter + surface failure) |
| 9 wheel focus + CSS | 309935c | ChartWheel.test.tsx 6/6 unchanged; wheel-focus.test.tsx 8/8 (F6 + additive-markup check: `focus={null}` innerHTML === no-prop innerHTML) |
| 10 stage/toggle/App | 7bee835 | ChartStage.focus.test.tsx 6/6 (F1, F2 en, F2 zh, F3, F4, F5); i18n.test.ts + ChartStage.test.tsx green |
| 11 full gate | (no change) | `npm test` exit 0: jest 90 suites / 1075 tests; vitest 39 files / 351 tests. `npm run typecheck` exit 0. `npm run build --workspace web-divination` exit 0: `dist/assets/canvaskit-DmFMth8j.wasm 7,155.82 kB │ gzip: 2,942.06 kB` bundled via `?url`; `canvaskit-BuG3NqSa.js 118.53 kB` split lazily |

## Deviations (for the coordinator to journal)
- **D-1 `skipLibCheck: true` in `web-divination/tsconfig.json`.** canvaskit-wasm's
  `types/index.d.ts` has `/// <reference types="@webgpu/types" />`, and
  `@webgpu/types@0.1.21` redeclares ~60 WebGPU names that TS 6's `lib.dom.d.ts`
  now ships (TS6200/TS2717/TS2403 inside `node_modules` and `lib.dom.d.ts`).
  The plan forbade a cast; skipLibCheck (which app-native already has through
  `expo/tsconfig.base.json`) is the standard fix and changes no checking of
  `src/`.
- **D-2 `src/test-setup.ts` guard is `typeof globalThis.localStorage?.clear === 'function'`**,
  not `typeof localStorage !== 'undefined'`: node 25 defines a methodless
  `localStorage` stub (warns "`--localstorage-file` was provided without a
  valid path"), so the plan's one-liner still threw `localStorage.clear is not a function`.
- **D-3 Host probe checks `typeof WebGLRenderingContext` first** (engine.ts
  `canHostCanvasKit`): jsdom lacks it, so the probe never calls jsdom's
  unimplemented `getContext` (which printed a "Not implemented" stack in L1).
  Every real browser defines it; the 2d-context probe still follows.
- **D-4 `RuntimeEffect.Make` runs lazily at the first `start()` and is memoised per
  engine** (as the contract says); a compile failure makes `start` return null → one
  `console.warn` from the layer → `data-spotlight="static"`.
- **D-5 Focus → full-chart crossfade uses `.wheel--full`.** CSS transitions take
  the DESTINATION state's duration, so "480 ms both ways" needs a class on the
  full-chart side: the stage adds `wheel--full` in full-chart mode, which sets
  480 ms on planets/chords/dots/nodes there. Side effect: in full-chart mode
  dw-4's return-to-neutral fade after a pill clears is 480 ms instead of 900 ms
  (entry stays 600 ms).
- **D-6 G15 matches any bare `canvaskit-wasm` specifier STRING on comment-stripped
  code** (covers `from`, `import()`, `require()`, `vi.mock()`, subpaths, `?url`),
  and walks the guard file too with no exemption: its self-check builds the
  package name at runtime (`['canvaskit','wasm'].join('-')`). G14 skips the
  guard file, per spec.
- **D-7 Screen blending on the beam canvas** (`mix-blend-mode: screen`, frontend-design
  choice): the glow adds light over the chords rather than painting over them.
- **D-8 F5 drives the character switch through core's `setActivePersona`**
  (the store `useRoster` reads), not by clicking through the roster picker.
- **Choice: `inkOf(persona)` lives in `chart/spotlight/beams.ts`** so
  `ChartStage` does not import `theme/tokens` (the spec's new edges name
  `chart/spotlight/* → theme` only).
- **Choice: jsdom has no ResizeObserver → disc size 0 → no beams**, so stage tests
  read `data-spotlight="static"` and never reach the engine.

Status transition: implementing → validating.
