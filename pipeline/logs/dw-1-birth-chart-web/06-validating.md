# 06 — validating (worker, 2026-09-28)

Branch `feature/dw-1-birth-chart-web` at 889d75d. Result: **PASS** on every criterion
(A1–A9, T1–T8, G-a…G-i). Cycles used: 0 (no validating→implementing trip).

## Automated suites
- `npm test` (root): app-native jest `Test Suites: 90 passed, 90 total / Tests: 1067 passed`;
  web-divination vitest `Test Files 9 passed (9) / Tests 25 passed (25)`.  → T1
- `npm run typecheck` (root): both workspaces clean (0 errors).  → T1
- `npm run server:test`: `959 passed, 50 skipped, 1 warning in 99.68s` (sanity; server untouched).
- T2 ChartWheel.test.tsx, T3 chart-view-additions.test.ts, T5 App.test.tsx — pass inside the 25.
- T4 runtime: i18n.test.ts pass. T4 typecheck drill: deleted `'tz-invalid'` from zh.ts →
  `npm run typecheck --workspace web-divination` → `src/i18n/zh.ts(34,3): error TS2741: Property
  ''tz-invalid'' is missing …`; reverted → exit 0.
- T6 `npm run build --workspace web-divination` → exit 0 (only the >500 kB advisory for core's
  lazy city-index chunk).
- T7 `npm ls react react-dom --all` → 32× react@19.2.3 (deduped), 4× react-dom@19.2.3, nothing else.
- T8 `git diff $(git merge-base HEAD feature/divination_web) -- server/ | wc -l` → 0 (base e157aed).

## Planted-violation drills (verbatim, `cd app-native && npx jest src/architecture.test.ts src/color-guard.test.ts`)
G-a1 planted 'const c = '#d3a94f'' in web-divination/src/app/App.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/app/App.tsx: #d3a94f", ; failing: ● web-divination has exactly one colour home (theme/tokens.ts)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-a2 planted '.x { color: #e39a4a; }' in web-divination/src/app/app.css → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/app/app.css: #e39a4a", ; failing: ● web-divination has exactly one colour home (theme/tokens.ts)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-b1 planted 'fetch('/api/chart')' in web-divination/src/chart/ChartStage.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/chart/ChartStage.tsx", ; failing: ● web-divination names no network API outside src/platform (G3)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-b2 planted 'fetch('/api/chart')' in web-divination/src/platform/boot.ts → result: Tests:       39 passed, 39 total; offender lines: ; failing:  ; after revert: Tests:       39 passed, 39 total (expected pass)
G-c planted 'import { polarToXy } from '@astrace/core/chart-view/geometry'' in web-divination/src/chart/Placements.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/chart/Placements.tsx", ; failing: ● app code imports core modules only through their barrels| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-d planted 'export function midLongitude(a: number, b: number) { return a }' in web-divination/src/chart/format.ts → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +     "web-divination/src/chart/format.ts", ; failing: ● the shared chart-view symbols have exactly one definition in the repo| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-e planted 'const m = (lonA + lonB) / 2' in web-divination/src/chart/ChartWheel.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/chart/ChartWheel.tsx", ; failing: ● web-divination does no angular, cusp, orb or longitude arithmetic (G4)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-f planted 'import { getKV } from '@astrace/core/platform'' in web-divination/src/i18n/index.ts → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/i18n/index.ts → @astrace/core/platform", ; failing: ● web-divination/src/i18n imports nothing but react and its siblings (G6)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-g planted 'import { subscribeChart } from '@astrace/core/chart'' in web-divination/src/chart/Placements.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/chart/Placements.tsx", ; failing: ● web-divination: the only chart value-importer is chart/useChart.ts (G5)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-h planted 'import x from '../../../app-native/src/session'' in web-divination/src/app/Header.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/app/Header.tsx → ../../../app-native/src/session", ; failing: ● workspace isolation: web-divination and app-native never import each other (G9)| ; after revert: Tests:       39 passed, 39 total (expected fail)
G-i planted 'const k = 'ANTHROPIC_API_KEY'' in web-divination/src/app/Header.tsx → result: Tests:       1 failed, 38 passed, 39 total; offender lines: +   "web-divination/src/app/Header.tsx", ; failing: ● anthropic SDK / API key strings appear nowhere in core or the app| ; after revert: Tests:       39 passed, 39 total (expected fail)

## Running app
ENVIRONMENT DEVIATION: the claude-in-chrome extension was NOT connected ("Browser extension is not
connected"). Instead the REAL app was driven in the system Google Chrome, headless (`--headless=new`,
fresh `--user-data-dir` → empty localStorage), over the DevTools protocol from a Node script
(scratchpad `cdp.mjs` + `acceptance.mjs`; no new packages). DOM reads, clicks and input events run
in the page; network observed via `Network.requestWillBeSent/responseReceived`; viewports via
`Emulation.setDeviceMetricsOverride`; reloads via `Page.reload`.

PORT DEVIATION: :8000 was already held by a uvicorn from ANOTHER checkout
(`/Users/kaimao/Projects/astrology2`, pid 34607, up 70 min, not started by this worker) — it was
left running. The backend under test ran on **:8001**:
`CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`
and Vite on :5173 with `VITE_API_BASE=http://localhost:8001 npx vite` (the documented override;
the default base remains :8000). Health: `{"status":"ok","db":"ok","ephemeris":"ok"}`; CORS
preflight OPTIONS /api/chart from Origin http://localhost:5173 → 200,
`access-control-allow-origin: http://localhost:5173`.

A7 stopped THIS backend (kill of the :8001 listener), reloaded, then restarted it from the script
and clicked Retry in the same document.

Verbatim final run (`node acceptance.mjs`):
{"id":"A1","pass":true,"observed":{"signs":12,"planets":0,"form":true}}
{"id":"A2","pass":true,"observed":{"errors":["date-required: Enter your birth date.","time-format: Enter a time (HH:MM), or tick “time unknown”.","location-required: Choose your birth city."],"nearFields":{"date":"Enter your birth date.","time":"Enter a time (HH:MM), or tick “time unknown”."},"chartRequestsDuringA2":0}}
{"id":"A3","pass":true,"observed":{"countryLabel":"China","tzBefore":"Asia/Shanghai","posts":[{"id":"54962.302","url":"http://localhost:8001/api/chart","method":"POST","status":200}],"corsPreflights":[{"id":"893F303EFAC3EA51C9729A6214B1C136","url":"http://localhost:8001/api/chart","method":"OPTIONS","status":200}],"wheel":{"planets":10,"sun":{"sign":"Gemini","house":"11","title":"Sun 23°38′ Gemini, house 11"},"moonSign":"Pisces","houseNumbers":12,"ac":true,"mc":true,"aspectKeys":20,"sunRow":"☉Sun23°38′♊︎ GeminiH11","bigThree":"☉ Gemini · ☽ Pisces · ↑ Cancer"}}}
{"id":"A4","pass":true,"observed":{"stored":"{\"date\":\"1990-06-15\",\"time\":\"08:30\",\"location\":{\"name\":\"Beijing\",\"latitude\":39.9075,\"longitude\":116.3972},\"timezone\":\"Asia/Shanghai\",\"schemaVersion\":1}","has":[["\"date\":\"1990-06-15\"",true],["\"time\":\"08:30\"",true],["\"timezone\":\"Asia/Shanghai\"",true],["\"name\":\"Beijing\"",true]],"afterReload":{"sun":"Gemini","planets":10,"summary":"Your birth1990-06-15 · 08:30 · Beijing (Asia/Shanghai)Edit","edit":true,"form":false},"refetch":[{"id":"54962.415","url":"http://localhost:8001/api/chart","method":"POST","status":200}]}}
{"id":"A5","pass":true,"observed":{"savedLabel":"✦ Beijing — saved","planets":10,"houseNumbers":0,"angles":0,"planetsWithHouse":0,"note":"Birth time unknown — houses and rising sign are omitted.","ascRow":false,"stored":"{\"date\":\"1990-06-15\",\"time\":null,\"location\":{\"name\":\"Beijing\",\"latitude\":39.9075,\"longitude\":116.3972},\"timezone\":\"Asia/Shanghai\",\"schemaVersion\":1}"}}
{"id":"A6","pass":true,"observed":{"zh":{"sunRow":"☉太阳23°46′♊︎ 双子座","summaryTitle":"你的出生","edit":true,"htmlLang":"zh-CN"},"labels":["日期","时间","我不知道出生时间","国家或地区","城市"],"afterReload":{"stored":"zh","sunRow":"☉太阳23°46′♊︎ 双子座","toggle":["EN=false","中=true"]}}}
{"id":"A7","pass":true,"observed":{"backendDown":true,"errorText":"The sky is out of reach","planetsDuringError":0,"backendBackUp":true,"navBefore":1,"after":{"marker":"same-document","nav":1,"sun":"Gemini"}}}
{"id":"A8","pass":true,"observed":{"m375":{"scrollWidth":375,"stageBottom":540.5,"sideTop":572.5,"stageLeft":16,"stageRight":359},"m1280":{"stageRight":718.5,"sideLeft":816.5}}}
{"id":"A9","pass":true,"observed":{"bodyBackground":"rgb(8, 9, 14)"}}
{"id":"CONSOLE","observed":["warning: chart service: /api/chart unreachable TypeError: Failed to fetch\n    at recompute (http://localhost:5173/@fs/Users/kaimao/Projects/astrology/packages/core/src/chart/service.ts:46:26)\n    at s"]}
{"id":"SUMMARY","pass":true,"observed":["A1:PASS","A2:PASS","A3:PASS","A4:PASS","A5:PASS","A6:PASS","A7:PASS","A8:PASS","A9:PASS"]}

Notes on the run:
- A3: the network shows one CORS preflight OPTIONS plus exactly ONE POST to
  http://localhost:8001/api/chart (200). The first script run counted the OPTIONS as a second
  request and crashed at A4 waiting on the pre-reload document — both were SCRIPT bugs, fixed in the
  script (POST filter, reload marker); the app was unchanged between runs.
- A6 Sun row reads 23°46′ because A5 left the time-unknown record (noon chart) — expected.
- CONSOLE: the only warning is core's `chart service: /api/chart unreachable` during A7's
  deliberate outage. No page exceptions.
- Screenshots reviewed (scratchpad A1-empty-1280, A2-errors, A3-chart-1280, A5-time-unknown,
  A6-zh, A7-error, A8-375): two-column at 1280, stacked with 16px gutter at 375, gold-only chrome.

## Cleanup
Stopped: :8001 uvicorn, :5173 vite, headless Chrome (:9333). `lsof -i :8001 -i :5173 -i :9333`
→ empty. :8000 (other checkout) untouched.

## Transition
validating → docs-sync.
