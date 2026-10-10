# dw-15-wheel-spotlight — acceptance (fresh-context checker)

Code under test: worktree `/Users/kaimao/Projects/astrology-wt/dw-15-wheel-spotlight`,
branch `feature/dw-15-wheel-spotlight`, HEAD 2178965 (11 dw-15 commits over 416c3dd).
Checked 2026-09-29.

## Suite totals (worktree root)

- `npm test`: app-native jest 90/90 suites, 1075/1075 tests; web-divination vitest 39/39 files, 351/351 tests. Exit 0. (Jest printed its usual "worker failed to exit gracefully" notice; no test failed.)
- `npm run typecheck`: app-native and web-divination `tsc --noEmit` clean, exit 0.
- `cd server && DATABASE_URL= conda run -n astrology pytest -q`: 1380 passed, 55 skipped, 1 warning, exit 0.
- Verbose vitest run of the dw-15 files: 9 files, 43/43 tests, K1/K2 included (the node test really ran, 615 ms for K2).

## Verdicts

| ID | Verdict | Evidence | Kind |
|----|---------|----------|------|
| C1 | PASS | `core-spotlight.test.ts` pins sha256 `846f7dc7…` of SPOTLIGHT_SKSL. Independent check: the SKSL template source is byte-identical at 416c3dd and HEAD (same source hash `8ed529e0…`). The spotlight.ts diff only adds a header comment and appends code. `ONE_DEFINITION_SYMBOLS` enumerates all four symbols, each mapped to `packages/core/src/chart-view/spotlight.ts`. A planted `export function spotlightChord` in web code turned the one-definition test red; reverting turned it green. | test + plant |
| C2 | PASS | C2 test: `[7.5,1,2,3,4,5,6,0.1,0.2,0.3,0.6]`, 11 numbers in declaration order. | test |
| C3 | PASS | 4 C3 tests (trine a/b/c to 1e-9 against wheelPoint/quadControl/BUNDLE_K; F conjunction at midLongitude; 359°/1° conjunction at 0°, not 180°; lacking a body returns null) pass. | test |
| C4 | PASS | `app-native/src/chart/spotlight.test.tsx`, `screens/spotlight-polish.test.tsx`, `screens/factor-highlight.test.tsx` have no diff vs the branch point, and all PASS. `grep -c "lonA + lonB" Spotlight.tsx` returns 0. | test + grep |
| G1 | PASS | G14 test walks the 3 trees on raw text, skipping only itself. A planted comment `// uniform float u_time;` in a web test file went red. G15 on comment-stripped code: a planted `import('canvaskit-wasm')` appended to `canvaskit.node.test.ts` went red. Both have synthetic self-checks. `canvaskit.node.test.ts` has no specifier: it gets CanvasKit only via `initCanvasKit`, and its wasm path is a plain `new URL('…/node_modules/canvaskit-wasm/bin/')` string. Reverted, then green. | plant + test |
| G2 | PASS | Planted in web-divination/src/chart: `fetch(` gave G3 red; `lonA + 1`, `x % 360` and `p.longitude * 2` each gave G4 red; a value import of `subscribeChart` from `@astrace/core/chart` gave G5 red; `'#ff0000'` gave the colour guard red ("web-divination has exactly one colour home"). After reverting, architecture + color-guard are 47/47 green. | plant + test |
| K1 | PASS | `// @vitest-environment node`. `initCanvasKit(locate)` locates the wasm in `node_modules/canvaskit-wasm/bin/`. `Make` returns non-null with no error; uniform count 6, float count 11 === `spotlightUniformArray(...).length`; the names are `u_time,u_a,u_b,u_c,u_color,u_glow`. | test (real wasm) |
| K2 | PASS | 300×300 CPU surface, beam (40,150)→(260,150) with c=(150,200), glow 1, `u_time = π/4.8` (named breathing peak). Alpha at (150,175) is > 0.3 and at (150,20) is < 0.02, through `drawBeams`. | test (real wasm) |
| B1 | PASS | 5 Venus-family keys, glow 0.6, colour = `rgb01(webTokens.aspect[type])`. | test |
| B2 | PASS | `[Venus|trine|Saturn]` gives exactly `[['Venus|trine|Saturn', 1]]`. | test |
| B3 | PASS | `planet:Mars` gives one bloom at Mars's hub node (a=b=c to 1e-9), glow 1, Venus ink, with Venus in focus. | test |
| B4 | PASS | Saturn gives 2 keys; time-unknown F gives `['Venus|trine|Saturn']`. | test |
| B5 | PASS | Full chart with no activation gives `[]`. | test |
| F1 | PASS | App mount, F, Venus: `data-focus="Venus"`; out planets exactly Mars/Mercury/Sun/Uranus; 15 out aspects incl. `Uranus|conjunction|Neptune`; no family chord out. | test |
| F2 | PASS | Toggle "Show full chart"/`aria-pressed=false`; click removes data-focus and all data-focus-out, then shows "Focus on Venus"/`true`; clicking again gives F1; zh shows 显示完整星盘 / 聚焦金星. | test |
| F3 | PASS | No character: no toggle, no data-focus. Chart not ready (no birth data): no toggle, no data-focus. | test |
| F4 | PASS | `showRefs(Mars|square|Jupiter)` clears out on Mars, Jupiter and the chord; Mars and the chord are `data-lit`; `clearActivation` gives F1 exactly. | test |
| F5 | PASS | Full chart, then pick Saturn: `data-focus="Saturn"`. Re-picking Saturn in full mode keeps full. | test |
| F6 | PASS | wheel.css: `.wheel[data-focus] .wheel__chord/.wheel__conjunction[data-focus-out]` → opacity 0; planets/nodes → 0.16; `[data-spotlight='live']` lit chord/conjunction → `filter: none`; the reduced-motion block sets `transition: none !important` on the focus rules. No hex/rgb literal (test + diff read). | test + read |
| L1 | PASS | Layer test: jsdom, real `loadEngine` gives loading→static, no canvas, no unhandled rejection. Extra temporary stage-level probe (ResizeObserver stubbed so beams are due, App mounted with F+Venus): `.chart-stage[data-spotlight="static"]`, no canvas, no rejection. Deleted afterwards. | test + probe |
| L2 | PASS | Reduced motion: loader spy not called, status static, no canvas. Flipping the stub + change mounts the canvas with the fake engine (live). | test |
| L3 | PASS | Canvas `data-beam-keys`, `aria-hidden="true"`, `pointer-events:none`; 0 beams unmounts and dispose is called once. The layer test uses synthetic keys, so a temporary stage-level probe was added: the fake engine reads the 5 B1 keys, then `Venus|trine|Saturn` after showRefs (B2); the full-chart toggle unmounts and dispose is called once. Deleted afterwards. | test + probe |
| R1 | PASS | Stage `live` 220 ms after reload. 1 canvas; rect [138.5,152.1,640,640] equals the svg rect exactly. keys = the 5 Venus-family keys. `data-frames` went 761 → 915 (+154) over 2.6 s. After the reveal settled: 5 family chords at 0.78 opacity, 15 at 0; Sun/Mercury/Mars/Uranus at 0.16. Screenshot `accept-shots/r1-venus-focus.png`: glow on exactly Venus's 5 chords. | real app |
| R2 | PASS | Pressing the toggle: 20/20 aspects visible, 0 canvas, `static`, no data-focus-out, "Focus on Venus" pressed=true. Pressing again: identical to R1 (live, same 5 keys, 24 out elements). Shots `r2-full-chart.png`, `r2-back-to-focus.png`. | real app |
| R3 | PASS | Real claude-cli turn to Venus; the reply carried pills `Venus trine Saturn`, `Venus in Taurus`, `Mars square Jupiter`. Pressing Mars□Jupiter (outside Venus's web): keys=`Mars|square|Jupiter` alone; Mars, Jupiter and the chord at opacity 1 and lit. Pressing again: the 5 focus keys. The same pass held for Venus△Saturn. Shots `r3-Mars-square-Jupiter.png`, `r3-Venus-trine-Saturn.png`. | real app |
| R4 | PASS | CDP `setEmulatedMedia` prefers-reduced-motion: reduce, then reload: matchMedia true, 0 canvases, `static`, focus Venus (24 out), no canvaskit resource fetched. Pressing Mars□Jupiter lit the chord statically (opacity 1, `drop-shadow(...)` filter = dw-4 rendering), still 0 canvas. Shot `r4-reduced-motion-pill.png`. | real app |
| R5 | PASS | With a character picked, the wheel shows only that planet's web with the flowing glow (R1). One tap shows the whole chart (R2). CDP captured console `error`, `Runtime.exceptionThrown` and Log errors over R1–R4: 0 (and 0 warnings in R1). | real app |

## Setup / cleanup

- Postgres: conda `initdb`/`pg_ctl` in the scratchpad, `-p 54351 -k '' -h 127.0.0.1`, db `astrace`.
- Backend: worktree, `uvicorn app.main:app --app-dir server --port 8021 --host 127.0.0.1`, no `--env-file`. `ps eww` of the uvicorn pid shows `DATABASE_URL=postgresql://postgres@127.0.0.1:54351/astrace`, `CORS_ALLOW_ORIGINS=http://localhost:5191`, `ANALYSIS_LLM=claude-cli`. The server loads no dotenv. `/api/health` returned `db: ok`.
- Vite: `VITE_API_BASE=http://localhost:8021 npx vite --port 5191` in web-divination.
- Auth: bearer pair minted with `_upsert_user` + `_mint_bearer` for `accept-dw15@example.invalid` in the throwaway DB. `astrace.auth.*`, birth data F (`astrology.birthData.v1.traveler`) and active persona `venus` were written to localStorage, then the page reloaded.
- Browser: headless Chrome 154 (`--headless=new`, CDP :9231, fresh `--user-data-dir`), a single foreground page, 1400×1000 at DPR 1. R1–R3 ran here rather than in Claude-in-Chrome, per the caller's instruction.
- Guard plants: 7 synthetic offender files/edits plus 2 G4 variants, and 2 temporary vitest probe files. All removed or restored; `git status --short` is empty.
- Cleanup: Chrome, Vite and uvicorn (8021) stopped; pg_ctl stop; cluster dir, chrome profile and token file deleted. Ports 54351/8021/5191/9231 are no longer listening. Screenshots are in `pipeline/logs/dw-15-wheel-spotlight/accept-shots/` (gitignored).

ACCEPTANCE: PASS
