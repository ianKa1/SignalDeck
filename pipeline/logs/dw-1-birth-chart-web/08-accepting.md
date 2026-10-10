# 08 — Acceptance check: dw-1-birth-chart-web

Date: 2026-09-28. Branch `feature/dw-1-birth-chart-web` @ 779cd3d. The checker had
fresh context and graded only against spec §8 (Acceptance Criteria) and Revision 1.

## Environment deviations (instructed by orchestrator)

- Port 8000 is held by an unrelated process (pid 34607, left alone). The backend ran on
  **8001**:
  `CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`.
  Vite ran with `VITE_API_BASE=http://localhost:8001 npx vite` (port 5173, strictPort).
  So A3's `POST http://localhost:8000/api/chart` was observed as `…:8001/api/chart`.
  The default base `http://localhost:8000` is pinned by T5 instead.
- Browser: claude-in-chrome, which had an existing profile. localStorage was cleared,
  then the page reloaded. A8 ran in system Chrome headless over CDP
  (`scratchpad/a8.mjs`), with a fresh `--user-data-dir` and
  `Emulation.setDeviceMetricsOverride` for exact 375/1280 viewports.

## Tests and build

| ID | Verdict | Evidence |
|---|---|---|
| T1 | PASS | `npm test` (root) exit 0. app-native: 90 suites / 1067 tests passed. web-divination vitest: 9 files / 25 tests passed. `npm run typecheck` (root) exit 0 for both workspaces. |
| T2 | PASS | `src/chart/ChartWheel.test.tsx` renders from `server/tests/fixtures/beijing-1990-known-time.json` (via `chart/fixtures.ts` JSON import). It asserts Sun Gemini/H11, 12 `[data-house-number]`, and `path[data-aspect]` count = non-conjunction aspects. The time-unknown test asserts 0 house numbers and no `[data-angle]`. Both pass. |
| T3 | PASS | `src/chart/chart-view-additions.test.ts` asserts midLongitude(350,10)=0, (10,350)=0, (0,30)=15, SIGN_SECTORS.length 12, Pisces {330,360}. It passes. |
| T4 | PASS | Runtime: `src/i18n.test.ts` passes (leaf parity, no empties, BODIES/SIGN_SECTORS iteration). Typecheck: deleting zh.ts line 35 (`'date-required'`), line 71 (`Gemini`) or line 83 (`Sun`), one at a time, gives TS2741 and `npm run typecheck --workspace web-divination` exit 2 each time. Restored with `git checkout`, then typecheck exit 0. |
| T5 | PASS | `src/app/App.test.tsx` "T5" test: seeded localStorage and stubbed fetch. It asserts `toHaveBeenCalledWith('http://localhost:8000/api/chart', objectContaining({method:'POST'}))` and Sun `data-sign="Gemini"`. It passes. |
| T6 | PASS | `npm run build --workspace web-divination` → BUILD_EXIT=0. Only a chunk-size warning, for cities.generated. |
| T7 | PASS | `npm ls react --all` shows exactly one non-deduped `react@19.2.3` (root). Every other entry is `react@19.2.3 deduped`, including web-divination's react, react-dom and @testing-library/react. No second version. |
| T8 | PASS | `git merge-base HEAD feature/divination_web` = e157aed132ec…. `git diff e157aed -- server/ \| wc -c` = 0. |

## Guards (planted, `cd app-native && npx jest src/architecture.test.ts src/color-guard.test.ts`)

Script: `scratchpad/guards.sh`. Each line was appended, jest run, then reverted with
`git checkout`. Clean run afterwards: 2 suites, 39/39 passed, exit 0.

| ID | Planted | Result |
|---|---|---|
| G-a | `const c = '#d3a94f'` in app/App.tsx | FAIL as expected. "web-divination has exactly one colour home (theme/tokens.ts)" names `web-divination/src/app/App.tsx: #d3a94f`. |
| G-a | `.x { color: #e39a4a; }` in app/app.css | FAIL as expected. Same test names `web-divination/src/app/app.css: #e39a4a`. |
| G-b | `fetch('/api/chart')` in chart/ChartStage.tsx | FAIL as expected. "names no network API outside src/platform (G3)" names the file. |
| G-b | same line in platform/boot.ts | Passes, 39/39, as the spec requires. |
| G-c | deep `@astrace/core/chart-view/geometry` import in chart/format.ts | FAIL as expected. "imports core modules only through their barrels" names format.ts. |
| G-d | `export function midLongitude…` in chart/format.ts | FAIL as expected. The one-definition test names format.ts. |
| G-e | `const m = (lonA + lonB) / 2` in chart/ChartWheel.tsx | FAIL as expected. "no angular, cusp, orb or longitude arithmetic (G4)" names ChartWheel.tsx. |
| G-f | `import { getKV } from '@astrace/core/platform'` in i18n/index.ts | FAIL as expected. "(G6)" names `i18n/index.ts → @astrace/core/platform`. |
| G-g | `import { subscribeChart } …` in chart/Placements.tsx | FAIL as expected. "only chart value-importer is chart/useChart.ts (G5)" names Placements.tsx. |
| G-h | `import x from '../../../app-native/src/session'` in chart/format.ts | FAIL as expected. "workspace isolation (G9)" names format.ts. |
| G-i | `const k = 'ANTHROPIC_API_KEY'` in chart/format.ts | FAIL as expected. The anthropic/key test names format.ts. |

## Running app

| ID | Verdict | Evidence |
|---|---|---|
| A1 | PASS | After clearing storage and reloading: `svg [data-sign]` = 12, `[data-planet]` = 0, the form is present (Date, Time, time-unknown checkbox, Country select, City search, "Cast the chart"). |
| A2 | PASS | Empty submit shows: date-error "Enter your birth date." · time-error "Enter a time (HH:MM), or tick “time unknown”." (time-format) · place-error "Choose your birth city.". Network (read_network_requests, `/api/`) shows no requests. |
| A3 | PASS | After date 1990-06-15, time 08:30, China, "Beijing" → pick "Beijing · Beijing", the timezone readout showed `Asia/Shanghai` before submit. On submit, the network shows one `POST http://localhost:8001/api/chart` 200. performance entries for the document list one `/api/chart` fetch. The wheel has 10 planets. Sun is Gemini/H11, Moon is Pisces. There are 12 house numbers, `[data-angle]` AC and MC (text "AC"/"MC"), and 20 `[data-aspect-key]`. The Sun row reads "Sun 23°38′ ♊︎ Gemini H11". The big three read "☉ Gemini · ☽ Pisces · ↑ Cancer". (The backend log's earlier POST came from the page's first load with the extension profile's pre-existing storage, before the clear.) |
| A4 | PASS | The stored JSON contains `"date":"1990-06-15"`, `"time":"08:30"`, `"timezone":"Asia/Shanghai"` and `"name":"Beijing"` (flags 1111). After a reload: 10 planets, Sun Gemini, `[data-birth-summary]` present, an **Edit** button, and no form. |
| A5 | PASS | Edit → tick time-unknown → submit: 10 planets, 0 house numbers, 0 `[data-angle]`, no "AC"/"MC" svg text, 0 planets with `data-house`, and no Ascendant placement row. The note reads "Birth time unknown — houses and rising sign are omitted." The stored JSON contains `"time":null`. |
| A6 | PASS | Toggle 中: html lang zh-CN. The Sun row reads "☉ 太阳 23°46′ ♊︎ 双子座". Form labels: 日期\|时间\|我不知道出生时间\|国家或地区\|城市. The summary shows "时间未知", 修改, 三要素, 星体位置. After a reload it is still zh-CN, with 中 aria-pressed=true. The browser default was en: the first visit had lang=en. |
| A7 | PASS | Backend stopped, then reload: the stage shows "天空暂时无法抵达" + 重试. Switched to EN: "The sky is out of reach" + Retry. Backend restarted, a window marker set, then Retry clicked: 10 planets, Sun Gemini, and the marker survived (no page reload). |
| A8 | PASS | Headless CDP, ready state (Beijing record seeded). At 375: scrollWidth 375 ≤ 375, and stage.bottom 540.5 ≤ side.top 572.5. At 1280: stage.right 718.5 ≤ side.left 816.5. |
| A9 | PASS | `getComputedStyle(document.body).backgroundColor` = `rgb(8, 9, 14)` in both the extension and headless. web `theme/tokens.ts` has `ground: '#08090e'`. |

## Cleanup

- Backend (8001) and Vite (5173) processes were killed. Both ports are down afterwards.
  pid 34607 on 8000 was untouched.
- The headless Chrome exited. The extension tab was closed.
- All planted edits were reverted. `git status --short` was empty before this log was
  written.

## Verdict

ACCEPTANCE: PASS — all A1–A9, T1–T8 and G-a…G-i pass.
