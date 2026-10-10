# 05 — implementing (worker, 2026-09-28)

Branch `feature/dw-1-birth-chart-web`, primary checkout.

## Step 1 — core additions
- `midLongitude(a,b)` in chart-view/geometry.ts = `normalize360(a + angularDelta(a,b)/2)`.
- `SIGN_SECTORS` in chart-view/frame.ts, built from `SIGNS` imported from `../chart/types` (D4).
- chart-view barrel exports both, with temporary `@public-intent` markers placed ABOVE the
  export blocks (a marker comment INSIDE an `export {…}` block would be parsed by
  `barrelExports` as part of the symbol name — deviation in placement only).
- birth-data barrel: `export type ValidationErrorCode` (D1).
- architecture.test.ts: ONE_DEFINITION_SYMBOLS += midLongitude, SIGN_SECTORS.
- Proof: `npx jest src/architecture.test.ts` → 29 passed; root `npm run typecheck` → clean.

## Step 2 — workspace birth + guards + CLAUDE.md (one commit)
- Installed: vite 8.3.1, vitest 5.0.2, @vitejs/plugin-react 6.1.1, jsdom 30.1.1, RTL 16.3.3
  (+ @testing-library/dom 10), react/react-dom 19.2.3 exact.
- DEVIATION: `@types/react-dom` pinned `~19.2.3` (plan said `~19.2`; `^19.2.0` resolved 19.3.0,
  whose peer `@types/react ^19.3` conflicts with the repo's `~19.2.2` → ERESOLVE).
- DEVIATION (core, trivial): removed the pre-existing UNUSED `normalize360` import from
  `packages/core/src/chart-view/frame.ts` — web tsconfig carries core's own `noUnusedLocals`
  and tripped on it (TS6133). Core's own tsconfig forbids it too; the web tsconfig was NOT relaxed.
- `Dict = typeof en` (exact keys, string leaves) instead of a hand-written interface, so a
  missing zh key fails typecheck (T4) — a `Record<string,string>` shape would have let it pass.
- importSpecifiers gained `{dynamic:true}` (import()/require()/bare imports) used by web G6/G7/G9
  only — native theme/typography.ts `require`s font assets via `../../`, so the native leaf
  guards keep the static read.
- G5 born pending (`[]`), flipped in step 4. G11 floor >8, colour walk >10 (D6).
- @public-intent markers for midLongitude / SIGN_SECTORS removed (consumed by
  chart-view-additions.test.ts).
- Proof: root `npm run typecheck` clean (both workspaces); root `npm test` → app-native
  90 suites / 1067 tests passed, web 5 files / 13 tests passed; arch+colour 39 passed.
- Drills (plant → red naming file → revert → green, 39/39):
  G-a1 App.tsx `#d3a94f` → colour-home test, "web-divination/src/app/App.tsx: #d3a94f"
  G-a2 app.css `#e39a4a` → colour-home test, "web-divination/src/app/app.css: #e39a4a"
  G-c deep chart-view/geometry import in Header.tsx → barrel test names Header.tsx
  G-f `@astrace/core/platform` in i18n/index.ts → G6 "i18n/index.ts → @astrace/core/platform"
  G-h app-native import in Header.tsx → G9 "Header.tsx → ../../../app-native/src/session"
  G-i 'ANTHROPIC_API_KEY' in Header.tsx → key-leak test names Header.tsx

## Step 3 — birth input
- useBirthData, CityPicker (lazy index, Intl.DisplayNames country select, search listbox,
  timezone readout, GeoNames attribution), BirthForm, BirthSummary, birth-input.css; App side slot
  shows summary when saved and not editing, else the form (edit pre-fills, saved pick labelled
  "Beijing — saved", Cancel returns to summary).
- DECISION: with no city picked, core returns location-required + lat-not-number +
  lon-not-number + tz-required; only `location-required` is shown (they are one fact). When a
  name exists, all location-group codes show in field order.
- Proof: web vitest 6 files / 17 tests passed (BirthForm.test.tsx: empty submit → 3 messages,
  no fetch, nothing saved, aria-describedby links; Beijing pick → Asia/Shanghai readout, saved
  JSON has date/time/timezone/name; time-unknown → "time":null; zh labels). Root typecheck
  clean; arch+colour 39 passed.

## Step 4 — chart seam, format, placements
- chart/useChart.ts (only value-importer of @astrace/core/chart; useChart, useChartStatus,
  re-exported retryChart), format.ts (degreeText), fixtures.ts (JSON imports, test-only),
  Placements.tsx (+ wheel.css placement styles). G5 flipped to ['web-divination/src/chart/useChart.ts'].
- Proof: web 7 files / 20 tests passed (Placements: Sun row 23°38′ Gemini H11, big three
  Gemini·Pisces·Cancer, 12 rows; unknown golden → note, no Ascendant row; zh 双子座);
  web tsc clean; arch+colour 39 passed.

## Step 5 — the pure SVG wheel
- wheel-layout.ts (radial constants + VIEW_BOX from WHEEL_VIEW), ChartWheel.tsx (layers: defs
  gradient via CSS stop classes → ground → zodiac ring from SIGN_SECTORS → houses (cusps, AC/MC
  at ANGLE_LABEL_R, house numbers at midLongitude) → aspects (bowed chords / conjunction dot at
  midLongitude) → hub nodes → planets (declustered glyphs, ticks, ℞)), wheel.css (colours by
  var(--…), reveal/breathe keyframes, reduced-motion off).
- DEVIATION (detail): `pathLength=1` + dash draw-in only on SOLID chords (trine/opposition);
  dashed chords (sextile/square) fade in, because pathLength rescales their `5 4` dash units.
- Proof: web 8 files / 23 tests (T2 known: 12 sectors, 10 planets, Sun Gemini H11, Moon Pisces,
  12 house numbers, AC+MC, path[data-aspect] = non-conjunction count; unknown: 0 house numbers,
  no angles, no data-house; null chart: ring only). arch+colour 39 passed.
- Drills: G-e `(lonA + lonB) / 2` in ChartWheel.tsx → G4 red naming ChartWheel.tsx → revert green;
  G-d second `export function midLongitude` in chart/format.ts → one-definition red naming
  format.ts → revert green (39/39).

## Step 6 — chart stage, states, retry, App integration
- ChartStage.tsx: status → empty (ring + invitation) / loading (ring, .wheel--loading breathe) /
  ready (wheel keyed on computedAtUtc|timeUnknown, .wheel--reveal) / error (ring, "The sky is out
  of reach", Retry → retryChart()). Wheel shows a chart only when status === 'ready'.
  Planet <title> via dict template ("Sun 23°38′ Gemini, house 11").
- App: stage slot = ChartStage; side = birth card, then Placements when ready.
- Floors raised to spec: G11 webSources > 15, colour walk > 15.
- Proof: root `npm test` → app-native 90 suites / 1067 passed; web 9 files / 25 passed
  (ChartStage.test: reject → error text → Retry → Sun Gemini, fetch ×2, same document;
  App.test T5: fetch called with 'http://localhost:8000/api/chart' + POST, Sun Gemini, summary +
  Edit, Sun row 23°38′). Root typecheck clean.
- Drill G-g: `subscribeChart` value import in Placements.tsx → G5 red naming Placements.tsx →
  revert green (39/39).

## Step 7 — visual pass, build, responsive, dedupe
- Looked at real-app screenshots (headless Chrome, see 06-validating.md): 1280 two-column,
  375 stacked with 16px gutter, error/zh/time-unknown states. One polish change: the location
  error group now renders INSIDE CityPicker directly under the city field (via `children`), not
  below the attribution line.
- T6 `npm run build --workspace web-divination` exit 0 (only the expected >500 kB warning for
  core's LAZY city-index chunk, 1.84 MB / 581 kB gz, never in the entry bundle; entry JS 221 kB).
- T7 `npm ls react react-dom --all`: 32× react@19.2.3 (all deduped), 4× react-dom@19.2.3; no
  second version.
- T8 `git diff $(git merge-base HEAD feature/divination_web) -- server/` → 0 lines (base e157aed).
- Root typecheck clean; root npm test: app-native 90/1067 passed, web 9 files/25 passed.
