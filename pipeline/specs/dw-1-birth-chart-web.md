# Feature Specification: dw-1-birth-chart-web

DIVINATION WEB EPIC, entry 1 of 6 (`dw-1 → dw-2 → dw-3 → {dw-4, dw-5, dw-6}`).
Status at writing: `designing`. Queue notes are the source of intent; this
spec decides everything the notes leave open (see **Decided defaults**).

## 1. Overview

Create the browser workspace `web-divination/` (Vite + React + TypeScript).
In it, a visitor enters their birth data and sees their natal chart wheel.
The data is kept in the browser and survives a reload. The server is not
changed: the chart comes from the existing `POST /api/chart` via
`@astrace/core/chart`. The epic's later entries attach the planet-character
chat to this page (dw-2), so dw-1 builds the foundation they need: the
workspace, boot wiring, theme, i18n, guard coverage, and a wheel whose
elements can be addressed by name.

## 2. Problem Statement

- The only client today is the phone app (`app-native/`). The web frontend
  was deleted on 2026-08-15. The divination epic is a browser product and
  has nowhere to live.
- The shared core (`packages/core`) is already browser-ready: raw-TS
  `exports` map, DOM libs in its tsconfig, `platform/web-kv.ts` as the
  default KV. Nothing in the repo consumes it from a browser.
- The architecture guards (`app-native/src/architecture.test.ts`,
  `app-native/src/color-guard.test.ts`) walk only `packages/core/src` and
  `app-native/src`. Without an extension, a new client tree would sit
  outside every boundary rule.
- Target user: the repo owner running the app locally (LOCAL ONLY ruling,
  2026-09-28). Anonymous, with no account.

## 3. Proposed Solution

User flow, closing the dw-1 loop:

1. `npm run web:server` (local backend with CORS for `:5173`) and
   `npm run web` (Vite on `http://localhost:5173`).
2. First visit: the page shows the header (wordmark and an EN/中 toggle),
   an empty wheel (the zodiac ring only, with 0° Aries at the left), and the
   birth form.
3. The user enters a date, a time (or ticks "time unknown"), a country, and
   a city from the offline GeoNames index, then submits.
4. `validateBirthData` judges the input. Errors show inline, translated.
   Valid data is saved through `saveBirthData`, which writes it to
   localStorage under the local profile.
5. Core's chart seam notices the change, POSTs `/api/chart`, and the wheel
   renders with a short staged reveal. The placements list and the "big
   three" line render beside it.
6. Reload: the saved data restores, the chart refetches, and the same wheel
   renders with no input. The form collapses to a one-line summary with an
   **Edit** button.

### Visual / UX bar (frontend-design pass)

Direction: **the candlelit observatory**. This is the web sibling of the
native 墨 *ink* ground, so the product reads as one brand. It should feel
like reading an almanac at night: dark and quiet, with warm gold as the
single accent.

- **Palette**: the native INK values copied into the web tokens: ground
  `#08090e`, wheel ramp core → mid → rim, gold voice `#d3a94f`, gold
  hairlines, parchment text, the five aspect colours, and the four element
  tints. Gold is the only chrome accent. Aspect and element colours are
  used only for data.
- **Atmosphere**: an `aura` radial wash in the top-left corner of the page.
  A very faint star-grain field made with CSS radial-gradient dots (no image
  assets). The wheel disc sits on its own `wheelCore → wheelRim` radial
  gradient.
- **Type**: Fraunces for display (wordmark, section headings, big-three
  line) and Source Serif 4 for body. These are the same families as native,
  self-hosted from `@fontsource` packages, with no CDN. Chinese falls back
  to the system serif (`"Songti SC", "Noto Serif SC", serif`). Field labels
  and eyebrows use small caps with letter-spacing. Inter, Roboto, Arial and
  a bare system-ui stack are not allowed.
- **Layout**: at ≥ 960 px, a two-column grid. The **stage** holds the wheel
  (the hero, up to 640 px square). The **side column** holds the birth card
  and the placements. Below 960 px the columns stack with the wheel first.
  At 375 px wide there is no horizontal scroll, with a 16 px side gutter.
  The side column is the region dw-2 fills with the chat panel, so it must
  be a named layout slot.
- **Form as an almanac entry**: underline-only inputs on the panel ground
  with gold hairline borders. The submit button is gold-outlined and fills
  gold on hover and focus. A visible focus ring appears on every control.
  The GeoNames attribution line ("Places: GeoNames, CC-BY 4.0") sits in
  small type under the city picker. This is required by the dataset's
  license (see `city-index.ts` header).
- **Motion**: one orchestrated reveal when a chart becomes ready. The zodiac
  ring fades in, the planets stagger in (CSS `animation-delay` by index,
  about 40 ms apart), and the aspect chords draw in through
  `stroke-dashoffset`. Loading state: the empty ring breathes slowly, as an
  opacity pulse. All of this is CSS-only and is disabled under
  `prefers-reduced-motion: reduce`.
- **States**: *empty* (ring only, with a one-line invitation), *loading*
  (breathing ring), *ready* (full wheel), *error* ("The sky is out of reach"
  plus a **Retry** that calls `retryChart()`). All state text is
  translated.
- **Accessibility**: the wheel `<svg role="img">` carries a translated
  `aria-label`, and each planet group has a `<title>` ("Sun 23°38′ Gemini,
  house 11"). The placements list is the screen-reader-complete twin of the
  wheel. Every input has a `<label>`. Errors are linked with
  `aria-describedby`.

## 4. Technical Design

### 4.1 Workspace layout

```
web-divination/
  package.json          name "web-divination", private, type module
  index.html            #root only; no inline colour
  vite.config.ts        react plugin; @astrace/core alias; server.port 5173 strictPort; vitest block
  tsconfig.json         DOM libs, moduleResolution bundler, resolveJsonModule, strict, noEmit
  .env.example          VITE_API_BASE=http://localhost:8000 (the real .env stays gitignored)
  src/
    main.tsx            imports ./platform/boot, then ./session, then renders <App/>
    platform/boot.ts    THE composition root (see 4.3); the only folder allowed to name network APIs
    session.ts          ensureLocalProfile() — pins local profile 'traveler' (native session.ts pattern)
    app/App.tsx         shell: Header + grid(stage | side)
    app/Header.tsx      wordmark + LanguageToggle
    app/app.css
    birth-input/BirthForm.tsx     date, time, time-unknown, CityPicker, submit, inline errors
    birth-input/CityPicker.tsx    country <select> + city search list over the lazy city index
    birth-input/BirthSummary.tsx  saved one-liner + Edit
    birth-input/useBirthData.ts   useSyncExternalStore over core/birth-data subscribe/getBirthData
    birth-input/birth-input.css
    chart/useChart.ts             the ONE value-importer of @astrace/core/chart (subscribeChart,
                                  subscribeChartStatus, retryChart)
    chart/ChartStage.tsx          status → empty | loading | ready | error
    chart/ChartWheel.tsx          pure SVG wheel: props { chart | null, ariaLabel, labels }
    chart/Placements.tsx          big-three line + planet/angle rows
    chart/format.ts               degree text from degreeInSign/minuteInSign (formatting only)
    chart/wheel-layout.ts         web-only RADIAL layout constants (e.g. sign-glyph radius)
    chart/wheel.css
    i18n/en.ts, zh.ts             dictionaries (Dict type from en)
    i18n/lang-store.ts            imports NOTHING; persistence port filled by boot
    i18n/index.ts                 useDict(), useLang(), setLanguage()
    theme/tokens.ts               SOLE chromatic-literal home for web-divination
    theme/apply.ts                writes tokens onto :root as CSS custom properties
    theme/global.css              fonts, base, atmosphere — var(--…) only
    test-setup.ts
```

### 4.2 Workspace wiring

- Root `package.json`: `workspaces` gains `"web-divination"`. New and
  changed root scripts:
  - `web`: `npm run dev --workspace web-divination`
  - `web:server`: runs the existing `server` script with
    `CORS_ALLOW_ORIGINS=http://localhost:5173` in the environment. uvicorn's
    `--env-file` does not override variables already set in the shell, and
    `.env` does not set this key.
  - `test`: the app-native suite, then the web-divination suite. Both must
    pass.
  - `typecheck`: both workspaces.
- Dependencies: `react` and `react-dom` pinned **exactly** to `19.2.3`, the
  version already hoisted at the root by app-native. This keeps one React
  copy under npm dedupe. The deleted frontend's two-React split caused
  invalid-hook-call failures (see `app-native/jest.config.js` header). Also
  `@astrace/core: "*"`, `@fontsource-variable/fraunces`,
  `@fontsource/source-serif-4`. Dev dependencies: current stable `vite`
  with `@vitejs/plugin-react`, `vitest` on the matching major, `jsdom`,
  `@testing-library/react` (React 19 capable), `@testing-library/user-event`,
  `@types/react` / `@types/react-dom` 19.2, and the same `typescript` range
  as app-native.
- `vite.config.ts`: alias `^@astrace/core/(.*)$` →
  `../packages/core/src/$1/index.ts`. This is the deleted frontend's proven
  resolution, and it makes Vite transform core's TS as source. The dev
  server runs on port 5173 with `strictPort: true`, because the CORS origin
  names that port. There is **no** `/api` proxy (4.3). Vitest runs in
  jsdom, includes `src/**/*.test.{ts,tsx}` only, and uses
  `src/test-setup.ts`. It does **not** run core's or app-native's tests.
- Workspace scripts: `dev`, `build` (`tsc --noEmit && vite build`),
  `preview`, `test` (`vitest run`), `typecheck`.

### 4.3 Boot (composition root) — `src/platform/boot.ts`

Order is load-bearing, matching the native boot's reasoning:

1. `configureApiBase(import.meta.env.VITE_API_BASE || 'http://localhost:8000')`.
   The API base is absolute and the server answers under CORS. This is the
   notes' `CORS_ALLOW_ORIGINS=http://localhost:5173` model and the same
   shape native uses (`EXPO_PUBLIC_API_BASE`). The fallback constant is the
   local backend, so the base is never left unconfigured.
2. The KV port is **not** reconfigured. Core's default `webLocalStorageKV`
   is already the right adapter for a browser.
3. `configureLangPersistence({ read, write })` over `getKV()`. This keeps
   `i18n/` import-free, as in native. The seed language is the persisted
   value, else `zh` when `navigator.language` starts with `zh`, else `en`.
4. `applyTheme()` writes every token onto `document.documentElement` as
   `--<role>` custom properties before the first render. It runs before the
   first render so there is no unstyled flash.

`session.ts` then calls `login('traveler')` when no profile is active. This
is required because `getBirthData()` returns null and `saveBirthData()`
throws while `getActiveNickname()` is null
(`packages/core/src/birth-data/store.ts`). The saved record therefore lives
at localStorage key `astrology.birthData.v1.traveler`. This is a local
namespace, not identity: the server never sees it.

### 4.4 Birth form over `core/birth-data`

- Inputs: `<input type="date">` (yields `YYYY-MM-DD`), `<input type="time">`
  (yields `HH:mm`), and a "I don't know my birth time" checkbox, which
  disables the time input and sends `time: null`.
- CityPicker:
  - `loadCityIndex()` runs on mount (lazy chunk, with a "Loading places…"
    state). The country `<select>` lists `countryCodes(index)`, labelled
    with `Intl.DisplayNames([lang], {type:'region'})` and collated with
    `localeCompare` in the current language. It has no preselected country.
  - A search input queries `searchCities(index, country, query)` and shows up
    to `SEARCH_CAP` results as a listbox of buttons. Each result reads
    `name · admin1Name`.
  - Picking a result sets `location {name, latitude, longitude}` and
    `timezone` from the `CityEntry`. The resolved timezone shows read-only
    (e.g. "Asia/Shanghai").
- An empty time with "time unknown" unticked is sent as `time: ''` (not
  null). `validateTime('')` returns `'time-format'`, and that code's text
  renders under the time field. A missing time is never silently treated
  as unknown.
- Submit builds a `BirthData` (`schemaVersion: 1`) and calls
  `validateBirthData`. Each returned `ValidationErrorCode` renders the
  dictionary's text next to its field (location codes go under the
  picker). An empty object means `saveBirthData(candidate)`.
- Edit: a saved record opens the form pre-filled with date, time or unknown,
  and the saved city as the current pick ("Beijing — saved"), with no
  country chosen. Submitting without re-picking keeps the saved location.
- The app does **no** date, timezone or coordinate maths of its own. All
  judging happens in `validateBirthData`.

### 4.5 Chart seam

`chart/useChart.ts` is the **only** web module that value-imports
`@astrace/core/chart`. It exposes `useChart()` (a `useSyncExternalStore`
over `subscribeChart`/`getChart`), `useChartStatus()`, and re-exports
`retryChart`. Everything else reads `BirthChart` as a type (rule 4). Core
performs the fetch. The web app names no network API in dw-1.

### 4.6 The wheel — adapting the deleted frontend wheel

Start from `git show d0e36b1:frontend/src/features/chart-display/ChartWheel.tsx`.
Keep its layer order and SVG idioms. Strip everything dw-1 does not need:
lore binds, spotlight and halo context, aspect filter chips, and the
CanvasKit fallback. Adapt it to today's `@astrace/core/chart-view` barrel:

| Old wheel used | Status today | dw-1 handling |
|---|---|---|
| `./geometry` (local `polarToXy`, `toScreenAngle`, `declusterAngles`, `bowedChordPath`, `BUNDLE_K`) | in core | import from `@astrace/core/chart-view` barrel |
| `WHEEL_VIEW`, `sectorPath`, `wheelPoint` | in core | same; `viewBox` = `${minX} ${minY} ${size} ${size}` read from `WHEEL_VIEW` |
| `SIGN_GLYPHS`, `PLANET_GLYPHS`, `SIGN_ELEMENTS` | in core | barrel |
| `ASPECT_COLORS`, `ELEMENT_TINTS` (CSS var strings) | deleted with web | web `theme/tokens.ts` → CSS vars `--aspect-<type>`, `--element-<el>` |
| `SIGNS` from `@astrace/core/chart` + `i * 30`, `from + 15` | `SIGNS` not in barrel; the maths is app-side longitude arithmetic | **new core table `SIGN_SECTORS`** (below) |
| `houseMidLongitude(cusp, next)` | **deleted 2026-08-25 (P17)** | **new core `midLongitude(a, b)`** (below); not restored |
| conjunction dot at `(lonA + lonB) / 2` | app-side arithmetic, wrong across 0° | `wheelPoint(rHub, midLongitude(lonA, lonB), asc)` |
| `aspectKey` | in core | barrel; stamped on each chord as `data-aspect-key` (dw-4 seam) |

**Core additions (`packages/core/src/chart-view/`, exported from the
barrel).** Each is added to `ONE_DEFINITION_SYMBOLS` in the same commit:

- `midLongitude(a: number, b: number): number` in `geometry.ts` returns the
  midpoint of the **shorter** arc from `a` to `b`, normalized to [0, 360).
  It is defined as `normalize360(a + angularDelta(a, b) / 2)` over the two
  existing helpers. The shorter arc is right for all three call sites:
  house spans (always < 180°, since opposite houses are equal and six
  consecutive houses sum to 180°), 30° signs, and conjunctions (within orb).
  One general helper replaces the house-specific pair deleted in P17,
  instead of resurrecting `houseSpan`/`houseMidLongitude`. It also fixes
  the old conjunction midpoint's wrap bug.
- `SIGN_SECTORS: readonly { sign: ZodiacSign; from: number; to: number }[]`
  in `frame.ts`: 12 rows Aries 0–30 … Pisces 330–360, built from core's
  `SIGNS`. It sits beside `sectorPath` because it is the zodiac ring's
  frame.

Both new exports have a consumer (web-divination), which the
declared-public-API guard must see (4.8).

**Wheel content** (all positions come from core helpers; `asc` =
`chart.ascendant?.longitude ?? null`):

- **Ground**: a disc at `rOuter` filled by the radial gradient, a rim
  stroke, and hairline circles at `rZodiacIn` and `rHub`.
- **Zodiac ring**: for each `SIGN_SECTORS` row, a
  `<path d=sectorPath(from, to, asc)>` filled with that sign's element tint,
  and a sign glyph at `wheelPoint(SIGN_GLYPH_R, midLongitude(from, to), asc)`.
  Each group carries `data-sign`. This ring also renders when `chart` is
  null, which is the empty and loading ring.
- **Houses** (only when `chart.houses`):
  - 12 cusp lines from `wheelPoint(rHub, cusp, asc)` to `wheelPoint(rZodiacIn, cusp, asc)`.
    AC (index 0) and MC (index 9) run to `rOuter` and are bolder.
  - "AC"/"MC" labels at `wheelPoint(rOuter + 4, cusps[0 | 9], asc)`.
    The Ascendant hub node sits at `wheelPoint(rHub, asc, asc)`.
  - House numbers at `wheelPoint(rHouseNum, midLongitude(cusps[i], cusps[(i+1)%12]), asc)`,
    with `data-house-number`. `(i+1)%12` is index wrap, not longitude
    arithmetic.
- **Planets**:
  - Glyph angles come from
    `declusterAngles(planets.map(p => toScreenAngle(p.longitude, asc)))`.
  - Each glyph sits at `polarToXy(WHEEL_VIEW.cx, WHEEL_VIEW.cy, rPlanet, angle)`.
  - A tick runs from `wheelPoint(rTick, trueLon, asc)` to `wheelPoint(rHub, trueLon, asc)`.
  - A hub node dot marks each planet, and there is an Ascendant node when
    one exists.
  - A small "℞" follows a retrograde glyph.
  - Each planet `<g>` carries `data-planet`, `data-sign`,
    `data-house` (omitted when null), and a translated `<title>`.
- **Aspects**:
  - Non-conjunctions are drawn as
    `<path d=bowedChordPath(a.x,a.y,b.x,b.y,cx,cy,BUNDLE_K)>` between hub
    points. They are stroked `var(--aspect-<type>)`, dashed for sextile and
    square, and thicker when `orb < 2`. Hub points are
    `a = wheelPoint(rHub, lonA, asc)` and `b = wheelPoint(rHub, lonB, asc)`. That is a threshold read of a
    server field, not orb computation.
  - A conjunction is a dot (see the table above).
  - Each aspect carries `data-aspect` (its type) and `data-aspect-key`
    (`aspectKey`).
- **Time unknown** (`chart.timeUnknown`, `houses`/`ascendant` null): no
  cusps, house numbers, AC/MC, or Ascendant node. The wheel is anchored at
  0° Aries left (core's `toScreenAngle` null-anchor). The placements show a
  translated note: "Birth time unknown — houses and rising sign are
  omitted."

`chart/wheel-layout.ts` holds radial *layout* constants only, such as
`SIGN_GLYPH_R` = the midpoint of `WHEEL_VIEW.rOuter` and
`WHEEL_VIEW.rZodiacIn`. That is radius arithmetic. It involves no
longitude, angle, cusp or orb, so it is outside rule 5's ban, the same
ruling native's `chart/frame.ts` relies on.

The wheel is a **pure component**: `(chart, labels) → SVG`, with no
subscriptions inside. dw-4 adds a highlight prop and targets
`data-planet` / `data-aspect-key`. dw-1 adds no highlight, hover, or
lore.

### 4.7 Placements

- **Big-three line**: `☉ <Sun sign> · ☽ <Moon sign> · ↑ <Asc sign>`
  (`ASCENDANT_GLYPH`). The Asc part is omitted when the time is unknown.
- **Rows**, in `chart.planets` order: glyph, translated body name, degree
  text, sign glyph and translated sign, "H<n>" when the house is present,
  and ℞ when retrograde. Ascendant and Midheaven rows follow when present.
- Degree text is `${degreeInSign}°${minuteInSign padded to 2}′`, which is
  pure formatting of server fields.
- Each row has `data-placement="<Body|Ascendant|Midheaven>"`.

### 4.8 Guards — extended in the SAME commit that creates the workspace

**Decision: the guards stay in one home.** They are app-native's jest
suites, which gain a third walked tree, `WEB_DIR = <repo>/web-divination/src`.
They run under the existing `npm test` in `app-native/` (and the root
`npm test`). The rules that already walk core + app-native must cover web
too, above all the one-definition guard and the barrel-export consumption
guard. A second guard suite inside web-divination would split those rules
and let them drift. The guards only *read files*, so the jest runner never
executes web code.

`app-native/src/architecture.test.ts`:

| # | Rule | Change |
|---|---|---|
| G1 | barrel-only core imports | walk `WEB_DIR` too |
| G2 | one definition per chart-view symbol | sources include `WEB_DIR`; add `midLongitude` (geometry.ts) and `SIGN_SECTORS` (frame.ts) to the enumerated table |
| G3 | no network outside `platform/` | new twin: in `WEB_DIR` minus tests, `NETWORK_RE` extended to `fetch(`, `apiUrl(`, `XMLHttpRequest`, `EventSource`, `WebSocket` bites outside `web-divination/src/platform/` |
| G4 | no astrological arithmetic | new twin over `WEB_DIR`: native `COMPUTATION_RE` **plus** `LONGITUDE_ARITH_RE`, i.e. an arithmetic operator (`+ - * / %`) directly after `longitude`, `lonA`, `lonB`, `cusp`, `cusps` or `ascendant` (catches `lonA + lonB`, `cusp - asc`; not `cusps[i]`, `?.longitude ?? null`), with synthetic self-checks both ways |
| G5 | chart state enters only via core/chart subscription | twin: value-importers of `@astrace/core/chart` in `WEB_DIR` minus test files = exactly `['web-divination/src/chart/useChart.ts']` |
| G6 | i18n leaf | twin: non-test files under `web-divination/src/i18n/**` import nothing but `react` and `./` siblings; self-check that `@astrace/core/x`, `../chart` bite. No test file lives inside `i18n/` (see the parity test below) |
| G7 | theme leaf | twin: non-test files under `web-divination/src/theme/**` import only `react`, `@astrace/core/chart-view` / `@astrace/core/chart` (types for token keys), and `./` siblings |
| G8 | astronomy-engine / anthropic / API-key strings | walk `WEB_DIR` too |
| G9 | workspace isolation (new) | no file in `WEB_DIR` imports from `app-native`, and no file in `app-native/src` imports from `web-divination` |
| G10 | declared-public-API guard | `appFiles` includes `WEB_DIR`, so web consumers count |
| G11 | walked-the-tree self-check | `WEB_DIR` source count > 15 |

**Which web files each guard skips.** Test and fixture files are defined by
`WEB_TEST_FILE_RE = /(\.test\.tsx?$|__fixtures__|\/fixtures\.ts$)/`, mirroring
native's `APP_NATIVE_TEST_FILE_RE`, plus `web-divination/src/test-setup.ts`.
- **G3, G4, G5, G6, G7** skip those files. Tests may stub `fetch`, import
  `vitest`, value-import `BODIES` from `@astrace/core/chart`, and so on.
- **G1, G2, G8, G9** walk **every** `.ts`/`.tsx` file in `WEB_DIR`, tests
  included, because a deep import, a duplicate definition, a key string or
  a cross-workspace import is a breach in a test too.
- **G10** counts all web files as consumers, as native's does.
- The colour walk skips test files, as native's does.

`app-native/src/color-guard.test.ts` gains a second walk, **web-divination
has exactly one colour home**. Over `WEB_DIR`, the `.ts`, `.tsx` and `.css`
files (minus tests), plus `web-divination/index.html`, excluding
`web-divination/src/theme/tokens.ts`: no chromatic literal. It reuses
`findColorLiterals`/`isChromatic`, and the walk count must be > 15. CSS
consumes colour only as `var(--…)`. Web CSS uses **class selectors only, no
id selectors**: an id made only of hex letters (`#add`, `#face`) would be
collected as a colour literal by `findColorLiterals`. `index.html`'s mount
node is `id="root"`, which is not all hex letters and is referenced only
from `main.tsx`, never from CSS.

Rules deliberately **not** applied to web: the Web-global ban (web code
*is* the browser; the ban is core-only, and core's own guard is unchanged)
and the native text-variant, paint and type guards (RN-specific).

Web-side tests (vitest, `web-divination/src/**`):

- i18n en↔zh parity lives in **`web-divination/src/i18n.test.ts`**, beside
  `i18n/` and not inside it, so the leaf directory holds no test file. It
  has two halves:
  - **Compile time.** `i18n/` itself stays import-pure: rule 8 means even a
    type import from core is barred there. The typed binding therefore
    lives in the test file. `i18n.test.ts` declares, for each of `en` and
    `zh`:
    - `satisfies`-style annotations
      `const _e: Record<ValidationErrorCode, string> = en.errors`
    - the same for `signs: Record<ZodiacSign, string>` and
      `bodies: Record<Body, string>`

    It uses `import type` from `@astrace/core/birth-data` and
    `@astrace/core/chart`. The web `tsconfig.json` includes test files, so
    a missing code, sign or body fails `npm run typecheck`. These are types
    with no runtime list; typecheck is what enumerates them. The
    dictionaries key those maps by the canonical English strings.
  - **Runtime.** The test asserts identical leaf-path sets for `en` and
    `zh` and no empty strings. It iterates `BODIES` (value import, allowed
    in a test file) and `SIGN_SECTORS.map(s => s.sign)`, asserting a
    non-empty entry in both dictionaries.
- Wheel rendered from the server golden fixtures, `beijing-1990-known-time`
  and `-time-unknown`. They are read from `server/tests/fixtures/` as
  native's `chart/fixtures.ts` does.
- `midLongitude` / `SIGN_SECTORS` behaviour through the barrel.
- Form validation messages, and the save → localStorage path.
- An App integration with a stubbed `fetch`.

Core has no test runner of its own (known gap, see Non-goals), so the new
core helpers are pinned from here.

### 4.9 Contract text (CLAUDE.md) amended in the same commit

- The "web frontend was deleted" paragraph gains a note: `web-divination/`
  is the explicitly asked-for new browser workspace (divination epic,
  2026-09-28), local-only, and not a re-creation of `frontend/`.
- **Rule 13**: two token homes, one per workspace,
  `app-native/src/theme/tokens.ts` and `web-divination/src/theme/tokens.ts`.
  Each is the sole chromatic-literal home in its tree, and web CSS reads
  `var(--…)` only. There is no parity test between them (values are copied
  from native INK and may diverge by design).
- **Rule 8**: rewrite the clauses "the native dictionary is the ONLY lore
  dictionary in the repo" and "`app-native/src/i18n/i18n.test.ts` pins full
  en↔zh leaf-path parity". The new text says there are two dictionaries,
  one per workspace: `app-native/src/i18n` (the lore dictionary) and
  `web-divination/src/i18n` (the web UI dictionary, with no lore in dw-1).
  Each is a leaf importing nothing but `react`, and each has its own parity
  test (`app-native/src/i18n/i18n.test.ts`, `web-divination/src/i18n.test.ts`).
  The two workspaces' dictionaries are not checked against each other.
- **Rules 1, 2, 5**: name `web-divination/src` beside `app-native/src`
  where the rule speaks of "the app". The guard list mentions the third
  tree and the new `midLongitude`/`SIGN_SECTORS` symbols.
- **Commands**: add `npm run web`, `npm run web:server`, and the workspace's
  `test`, `typecheck` and `build`.

### 4.10 Seams left for dw-2..dw-6 (built now, used later)

- `src/platform/` is the only folder that may name network APIs. dw-2's web
  stream-reader adapter lands there (or in core/platform per the dw-2 notes)
  without a guard change.
- The side-column slot in `App.tsx` is where dw-2 mounts the chat panel.
- The dictionary is namespaced (`app`, `form`, `errors`, `chart`, `signs`,
  `bodies`, `status`), so dw-2 adds `chat` without touching others.
- The wheel is pure and elements are addressable by `data-planet` and
  `data-aspect-key`, which dw-4 needs.
- Language persistence and the KV stay on core's ports, so dw-2's transcript
  and dw-6's session log use the same KV.

## 5. Security / privacy

- No identity leaves the browser. `POST /api/chart` carries birth data only,
  exactly as native does.
- No keys or SDKs in the bundle (G8). The server is unchanged, and CORS is
  opened only by the local `web:server` script's environment.

## 6. Non-Goals

- Any server change: new route, CORS default, or migration.
- Any deploy: hosting, Render CORS, static build publishing, Vercel. This
  follows the LOCAL ONLY ruling.
- Chat, personas, streaming, chart refs, wheel activation, dice, session
  log (dw-2..dw-6).
- Wheel interactivity: hover, lore cards, aspect filters, spotlight,
  Skia/SkSL.
- Accounts, sign-in, sync, multiple people, a profile switcher. There is
  one pinned local profile.
- Manual latitude/longitude entry, geolocation, a transit or synastry view,
  and a light theme or ground switcher.
- Colour parity between web and native tokens.
- Running `packages/core/src/**/*.test.ts` under any runner (pre-existing
  gap). The web suite tests only what dw-1 adds or consumes.

## 7. Decided defaults (autonomous mode — no open questions)

1. **API reach**: an absolute base plus CORS, per the notes. `VITE_API_BASE`
   defaults to `http://localhost:8000`, and there is no Vite `/api` proxy.
2. **Guards' home**: app-native's jest suites walk `web-divination/src` as a
   third tree. There is no separate guard suite in web-divination.
3. **House and sign maths**: `houseSpan`/`houseMidLongitude` are **not**
   restored. They are replaced by one general `midLongitude` plus a
   `SIGN_SECTORS` table in core/chart-view, both one-definition-guarded.
4. **Local profile**: `session.ts` pins `'traveler'`, the same name native
   uses. The key is `astrology.birthData.v1.traveler`.
5. **Colours**: native INK values are copied into `web-divination/src/theme/tokens.ts`
   and exposed as CSS custom properties by `theme/apply.ts`. This is a
   second token home, which amends rule 13.
6. **Fonts**: Fraunces and Source Serif 4 from `@fontsource`, self-hosted,
   with no CDN.
7. **React**: `19.2.3` exact, deduped with the root hoist.
8. **Test runner**: vitest + jsdom inside web-divination. The root
   `npm test`/`typecheck` run both workspaces.
9. **Language**: en and zh. The initial value comes from persisted →
   `navigator.language` → en, and it persists through the KV port.
10. **City entry**: a country `<select>` plus city search, with no default
    country and no manual coordinates.
11. **Port**: Vite on 5173 with `strictPort`. The CORS origin depends on it.
12. **Scope of the wheel**: static in dw-1, with no hover or lore.
    Addressable data attributes are the dw-4 seam.

## 8. Acceptance Criteria

Setup for running-app criteria (A-series): the repo root has had
`npm install` run. Terminal 1 runs `npm run web:server` (local FastAPI on
:8000 with `CORS_ALLOW_ORIGINS=http://localhost:5173`). Terminal 2 runs
`npm run web`. A browser (Chrome, driven manually or scripted) opens
`http://localhost:5173` with localStorage cleared for that origin.

**Running app**

- **A1**: A first visit with empty storage shows the birth form and a wheel
  with 12 sign sectors (`svg [data-sign]` count = 12). The page has no
  `[data-planet]` element.
- **A2**: Submitting the empty form shows at least the translated "date
  required", "time format" and "location required" messages next to their
  fields. Time-unknown is unticked, so the empty time yields `time-format`
  (§4.4). No request to
  `/api/chart` is made, as seen in DevTools Network.
- **A3**: Entering date `1990-06-15` and time `08:30`, choosing country
  China, searching "Beijing", picking **Beijing**, and submitting sends one
  `POST http://localhost:8000/api/chart`, answered 200. The wheel then
  shows:
  - 10 `[data-planet]` groups.
  - `[data-planet="Sun"]` has `data-sign="Gemini"` and `data-house="11"`.
  - `[data-planet="Moon"]` has `data-sign="Pisces"`.
  - 12 `[data-house-number]` elements and both AC and MC labels.
  - At least one `[data-aspect-key]` element.

  The placements list shows the Sun row as `23°38′` Gemini, H11. The
  big-three line reads Sun Gemini, Moon Pisces, Rising Cancer. The timezone
  readout showed `Asia/Shanghai` before submit.
- **A4**: After A3, localStorage key `astrology.birthData.v1.traveler` holds
  JSON with `"date":"1990-06-15"`, `"time":"08:30"`,
  `"timezone":"Asia/Shanghai"`, and `"name":"Beijing"`. A hard reload
  (no input) re-renders the same wheel: Sun `data-sign="Gemini"` and 10
  planets. The form shows the collapsed summary with an **Edit** button.
- **A5**: Edit, tick "I don't know my birth time", and submit. The wheel then
  has 10 planets, 0 `[data-house-number]`, no AC/MC labels, and no
  `data-house` attributes on the planets. The placements show the
  time-unknown note and no Ascendant row. The stored JSON has
  `"time":null`.
- **A6**: Switching the toggle to 中 renders the form labels, sign names
  (the Sun row shows 双子座) and status text in Chinese. After a reload the
  language is still 中.
- **A7**: With the backend stopped, reload. The error state shows "The sky is
  out of reach" (or its zh text) and a Retry button. Start the backend
  again and click Retry: the wheel renders without a page reload.
- **A8**: Let `stage` and `side` be the `getBoundingClientRect()` of the
  stage and side-column elements.
  - At a 375 px viewport the page has no horizontal scroll
    (`document.documentElement.scrollWidth <= 375`) and
    `stage.bottom <= side.top`.
  - At a 1280 px viewport, `stage.right <= side.left`.
- **A9**: Rendered colours come from tokens. The computed `background-color`
  of `body` equals the web `tokens.ts` ground value (rgb(8, 9, 14)).

**Tests and build**

- **T1**: `npm test` at the repo root runs and passes both the app-native
  jest suite and the web-divination vitest suite. `npm run typecheck` at
  the root passes for both workspaces.
- **T2**: web-divination vitest includes a test that renders `ChartWheel`
  from `server/tests/fixtures/beijing-1990-known-time.json`, asserting Sun
  `data-sign="Gemini"`, 12 house numbers, and chord count = aspects that
  are not conjunctions. A second test renders it from
  `beijing-1990-time-unknown.json`, asserting 0 house numbers and no AC/MC.
  Both pass.
- **T3**: a web test asserts `midLongitude(350, 10) === 0`,
  `midLongitude(10, 350) === 0`, `midLongitude(0, 30) === 15`, and
  `SIGN_SECTORS.length === 12` with Pisces `{from: 330, to: 360}`. It
  passes.
- **T4**: `web-divination/src/i18n.test.ts` (outside `i18n/`) passes at
  runtime and at typecheck:
  - Runtime: en↔zh leaf-path parity with no empty strings, plus iteration
    over `BODIES` and `SIGN_SECTORS` signs showing both dictionaries have
    each.
  - Typecheck: its `Record<ValidationErrorCode | ZodiacSign | Body, string>`
    bindings mean that deleting any one key from `zh.ts` makes
    `npm run typecheck --workspace web-divination` fail.
- **T5**: a web App test with `localStorage` pre-seeded with the Beijing
  record and `fetch` stubbed to return the golden chart asserts that fetch
  was called with `http://localhost:8000/api/chart` and `POST`, and that
  the wheel renders Sun `data-sign="Gemini"`.
- **T6**: `npm run build --workspace web-divination` exits 0.
- **T7**: `npm ls react --all` resolves a single React version (19.2.3) for
  both app-native and web-divination, with no nested second copy.
- **T8**: `git diff $(git merge-base HEAD feature/divination_web) -- server/`
  is empty; the base is currently `e157aed`. The server is untouched by
  this feature. (`main` is not the base: the working branch is many
  commits ahead of it.)

**Guards (planted-violation checks)**

For each item: plant the line, run `cd app-native && npx jest
src/architecture.test.ts src/color-guard.test.ts`, confirm that it FAILS
and names the planted file, then revert and confirm that it passes.

- **G-a**: `const c = '#d3a94f'` in `web-divination/src/app/App.tsx` →
  colour guard fails. `color: #e39a4a;` in `web-divination/src/app/app.css`
  → colour guard fails.
- **G-b**: `fetch('/api/chart')` in `web-divination/src/chart/ChartStage.tsx`
  → network guard fails. The same line in
  `web-divination/src/platform/boot.ts` → it does **not** fail.
- **G-c**: `import { polarToXy } from '@astrace/core/chart-view/geometry'`
  in any web file → barrel guard fails.
- **G-d**: `export function midLongitude(a: number, b: number) { return a }`
  in a web file → one-definition guard fails.
- **G-e**: `const m = (lonA + lonB) / 2` in `ChartWheel.tsx` → the
  arithmetic guard fails.
- **G-f**: `import { getKV } from '@astrace/core/platform'` in
  `web-divination/src/i18n/index.ts` → i18n leaf guard fails.
- **G-g**: `import { subscribeChart } from '@astrace/core/chart'` in
  `web-divination/src/chart/Placements.tsx` → chart-source guard fails.
- **G-h**: `import x from '../../../app-native/src/session'` in a web file
  → workspace isolation guard fails.
- **G-i**: `const k = 'ANTHROPIC_API_KEY'` in a web file → key-leak guard
  fails.

## Revision 1 (post-review)

- **T8**: `server/` is now diffed against the feature's real base,
  `git merge-base HEAD feature/divination_web` (currently `e157aed`), not
  `main`.
- **Guard exclusions stated (§4.8)**:
  - New `WEB_TEST_FILE_RE`, mirroring native's, with `test-setup.ts`.
  - G3–G7 skip test and fixture files.
  - G1, G2, G8 and G9 walk all files.
  - G5, G6 and G7 rows say "non-test files".
- **Parity test placement**: the parity test lives at
  `web-divination/src/i18n.test.ts`, outside the `i18n/` leaf.
- **Parity enumeration (§4.8, T4)**: `ValidationErrorCode` and `ZodiacSign`
  are types with no runtime list, so they are enumerated at typecheck. The
  test binds `Record<…, string>` to both dictionaries via `import type`.
  `BODIES` and `SIGN_SECTORS` give the runtime iteration. `i18n/` stays
  import-pure (no core type imports there).
- **Rule 8 amendment (§4.9)**: names both dictionaries and both parity
  tests.
- **§4.6**: every `wheelPoint` call passes `asc`. The AC/MC labels,
  Ascendant node and chord endpoints are spelled out.
- **§4.4**: an empty time with time-unknown unticked is sent as `''` and
  shows `time-format` under the time field.
- **§4.8**: web CSS uses class selectors only, because a hex-letter-only id
  selector false-positives in `findColorLiterals`.
- **A2**: "at least" the date, time and location messages.
- **A8**: defined through `getBoundingClientRect` comparisons.
