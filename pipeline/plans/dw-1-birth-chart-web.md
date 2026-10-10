# Implementation Plan: dw-1-birth-chart-web

Spec: `pipeline/specs/dw-1-birth-chart-web.md` (approved, review log
`logs/dw-1-birth-chart-web/03-spec-review.md`). Stage: planning, 2026-09-28.
Branch: `feature/dw-1-birth-chart-web` (base for T8 =
`git merge-base HEAD feature/divination_web`, currently `e157aed`).

Resumability rule: tick a step's box only after its **Proof** command
passed and its commit landed (via `/git-commit`, message
`(<type>): dw-1-birth-chart-web — <summary>`). Steps 1–7 are the
`implementing` stage; 8 is `validating`; 9 is `docs-sync`. Load
`/frontend-design` before writing any UI code (steps 2, 4–7).

---

## Part A — Architecture analysis (architecture-designer)

### A.1 What exists (read, not assumed)

| Thing | Where | Fact that shapes this plan |
|---|---|---|
| Root workspaces | `package.json` | `["packages/*", "app-native"]`; `test`/`typecheck` delegate to app-native only. |
| Hoisted React | `node_modules/react` | 19.2.3. **`react-dom` is not installed anywhere** (native uses RN). Web adds it pinned to exactly 19.2.3. |
| Core package | `packages/core/package.json` | raw-TS `exports` map per domain barrel; `tsconfig.json` = ES2020 + DOM, bundler resolution, `resolveJsonModule`, `allowImportingTsExtensions`, strict, `noUnused*`. Web tsconfig copies these options so core source typechecks identically under web. |
| Chart seam | `packages/core/src/chart/service.ts` | lazily `start()`s on first `getChart`/`subscribe*`; subscribes to birth-data; POSTs `fetch(apiUrl('/api/chart'))`; status channel `empty/loading/ready/error`; `retryChart()` re-runs `recompute(getBirthData())` in place — so Retry needs no reload (A7). Module singleton → one vitest file per scenario, or `vi.resetModules()`. |
| Birth-data store | `packages/core/src/birth-data/store.ts` | profile-namespaced; `getBirthData()` caches by raw string (safe for `useSyncExternalStore`); `saveBirthData` throws with no active nickname or invalid data. Key = `astrology.birthData.v1.<nickname>`. |
| Birth-data barrel | `packages/core/src/birth-data/index.ts` | exports types `BirthData, BirthLocation, ValidationErrors` — **not** `ValidationErrorCode` (review suggestion 1). City index: `loadCityIndex` (dynamic JSON import → a lazy Vite chunk), `countryCodes`, `searchCities`, `SEARCH_CAP`, `CityEntry`. |
| Chart barrel | `packages/core/src/chart/index.ts` | `BODIES` value + types (`Body`, `ZodiacSign`, `AspectType`, `BirthChart`, …). `SIGNS` is **not** exported (lives in `chart/types.ts`). |
| chart-view barrel | `packages/core/src/chart-view/index.ts` | has `normalize360, toScreenAngle, polarToXy, BUNDLE_K, bowedChordPath, declusterAngles, angularDelta, WHEEL_VIEW, wheelPoint, sectorPath, SIGN_GLYPHS, PLANET_GLYPHS, ASCENDANT_GLYPH, SIGN_ELEMENTS, Element, aspectKey`. `houseSpan/houseMidLongitude` deleted (P17). `angularDelta` is signed (−180, 180]. |
| Platform | `packages/core/src/platform/{api,web-kv,storage}.ts` | `configureApiBase` trims trailing slash; default KV is `webLocalStorageKV` — correct for the browser as-is. |
| Native precedents to mirror | `app-native/src/{session.ts, platform/boot.ts, i18n/lang-store.ts, birth-input/useBirthData.ts, chart/useChart.ts, chart/fixtures.ts}` | pinned `'traveler'` profile; import-free lang-store with an injected persistence port; void-adapter `useSyncExternalStore` hooks; fixture loader over `server/tests/fixtures/`. |
| Architecture guard | `app-native/src/architecture.test.ts` (781 lines) | walks `CORE_DIR` + `APP_NATIVE_DIR` only. Relevant pieces: `BARREL_DEEP_IMPORT_RE` (l.143), `ONE_DEFINITION_SYMBOLS` + expected-definitions table (l.196–260), `importSpecifiers` scanner (l.322), `APP_NATIVE_TEST_FILE_RE`/`appNativeSources` (l.406), `NETWORK_RE`/`COMPUTATION_RE`/`CHART_IMPORT_RE` (l.425–435), theme leaf (l.508), astronomy-engine (l.595), `KEY_LEAK_RE` (l.614), walked-trees check (l.641), public-API guard `appFiles`/`appProd` (l.719, l.751). |
| Colour guard | `app-native/src/color-guard.test.ts` | `findColorLiterals` collects hex / `0x` / `rgb[a]()`/`hsl[a]()` with numeric channels, and skips relative-colour `rgb(from …)`. `isChromatic` treats channel-less matches as achromatic, but that is an accident, not a contract. |
| Native INK palette | `app-native/src/theme/tokens.ts` l.156–200 | Translucent colours are **already named tokens holding full `rgba()` values**: `aura`, `themeGhost`, `line`, `lineSoft`, `accentGhost`, `dangerGhost`, `element.*`. |
| Deleted wheel | `git show d0e36b1:frontend/src/features/chart-display/ChartWheel.tsx` | layer order ground → zodiac ring → house ring → aspect nodes → aspect lines → (halos/hits: dropped) → planet ring. App-side longitude arithmetic at l.132 (`i * 30`), l.207 (`houseMidLongitude`), l.265/330/387 (`(lonA + lonB) / 2`) — all replaced by core helpers. Old `vite.config.ts` alias `^@astrace/core/(.*)$ → ../packages/core/src/$1/index.ts` is reused. |
| Server CORS | `server/app/main.py` l.77–101 | env `CORS_ALLOW_ORIGINS`; unset → no middleware. Server stays untouched (T8). |
| Registry versions (2026-09-28) | `npm view` | vite 8.3.1, vitest 5.0.2 (peer vite ^6‖^7‖^8), @vitejs/plugin-react 6.1.1, jsdom 30.1.1, @testing-library/react 16.3.3 (**peer `@testing-library/dom` ^10 must be added explicitly**). |

No structural problem in the existing code blocks this feature. The one real
gap is the guards' two-tree walk, which step 2 closes.

### A.2 Module boundaries for `web-divination/src`

Layering, arrows point at what may be imported:

```
main.tsx ─► platform/boot ─► @astrace/core/platform, i18n/lang-store, theme/apply
   │      ─► session       ─► @astrace/core/profile
   └────► app/App ─► app/Header ─► i18n
                  ─► birth-input/* ─► @astrace/core/birth-data, i18n
                  ─► chart/ChartStage ─► chart/useChart (ONLY value-importer of @astrace/core/chart)
                                      ─► chart/ChartWheel, chart/Placements ─► @astrace/core/chart-view,
                                                                             chart/format, chart/wheel-layout, i18n
   leaves:  i18n/   imports nothing but `react` and `./` siblings        (G6)
            theme/  imports only react, @astrace/core/chart-view, @astrace/core/chart (types), `./`  (G7)
   network: names fetch/XHR/EventSource/WebSocket only under platform/   (G3), and dw-1 has none
```

| Module | Owns | Must NOT |
|---|---|---|
| `platform/` | Composition root: API base, lang persistence port, theme application. The only home for network APIs (dw-2's stream reader lands here). | Render anything. |
| `session.ts` | Pinning local profile `'traveler'` (idempotent, run on import). | Know about birth data. |
| `i18n/` | The dictionaries (`en` is the `Dict` shape, `zh: Dict`), current language, `useDict/useLang/setLanguage`. | Import core, even types (rule 8). The typed binding to core vocabularies lives in `src/i18n.test.ts`. |
| `theme/` | `tokens.ts` = the sole chromatic-literal home; `apply.ts` flattens it to `--kebab` CSS vars on `:root`; `global.css` = fonts, base, atmosphere via `var(--…)`. | Reach sideways into feature folders. |
| `birth-input/` | The form, city picker, saved summary, and `useBirthData`. It builds a `BirthData` candidate and hands it to `validateBirthData`, then `saveBirthData`. | Do date, timezone or coordinate maths. Import `@astrace/core/chart`. |
| `chart/` | `useChart` (subscription seam), `ChartStage` (status → view), the pure `ChartWheel`, `Placements`, `format` (string formatting of server fields), and `wheel-layout` (radii only). | Do longitude/cusp/orb arithmetic (G4). Hold chart state outside `useChart`. |
| `app/` | Shell, header, layout grid with the named `stage`/`side` slots. | Feature logic. |

### A.3 Decisions (resolving the review's optional suggestions and the open seams)

- **D1: `ValidationErrorCode` becomes a TYPE export of the `@astrace/core/birth-data` barrel.** We do not derive `NonNullable<ValidationErrors[keyof ValidationErrors]>` in the test. Reasons: the code union is core's declared, stable, language-agnostic vocabulary (its own doc comment says translation happens in the UI layer), so the UI layer is its intended consumer. `BirthForm` needs the name too, to type the error lookup. Deriving it would restate the type's identity in a second place. The public-API guard polices value exports only, so a type export carries no guard cost. *Deviation from spec §4.8 wording (which assumed it was already exported); journal it.*
- **D2: translucent chromatic colours are named rgba tokens in `tokens.ts`.** Examples: `aura`, `line`, `lineSoft`, `themeGhost`, `star` (grain dots), `goldWash` (button hover fill), and the `element.*` tints, whose native values are already rgba. `apply.ts` writes each one as a CSS custom property, and CSS only ever writes `var(--line)`. **Rejected:** channel-triplet tokens (`rgb(var(--gold-rgb) / .1)`). They pass `findColorLiterals` only because `isChromatic` happens to treat a channel-less match as achromatic, which is an accident of the classifier, and they would put a partial rgb() in CSS that a future guard tightening could misread. Also rejected: `color-mix()`, which works but splits the alpha value from the palette file. This mirrors native INK exactly, where every alpha is already a named token. The colour guard gets a self-check that `var(--line)` in CSS yields no literal. *Resolves review suggestion 2; no spec deviation (§3 names tokens only).*
- **D3: A7 Retry works in place.** `ChartStage`'s error view calls `retryChart()`. Core's `recompute` sets `loading`, then `ready`, then delivers, and `useChart`/`useChartStatus` re-render. There is no `location.reload`. A vitest case pins it: the first fetch rejects, then Retry is clicked, the second fetch resolves, the wheel renders, and the same `window.location` / document instance holds with no reload spy fired. Step 8 re-checks this in the browser. *Resolves review suggestion 3.*
- **D4: `SIGN_SECTORS` value-imports `SIGNS` from `'../chart/types'`.** It does not use the `'../chart'` barrel. That keeps `SIGNS` non-public (P17 barrel discipline) and keeps chart-view's runtime graph free of `chart/service.ts`. The type-only `'../chart'` imports elsewhere in chart-view are unchanged.
- **D5: build order puts the core additions first as their own commit.** They carry temporary `@public-intent midLongitude:` / `@public-intent SIGN_SECTORS:` markers so the public-API guard stays green. Step 2 (workspace birth) removes both markers in the same commit that adds their web consumers. The core commit is small and revertable, and the workspace commit stays the single "born guarded" commit.
- **D6: the walked-tree floors are staged.** At workspace birth (step 2) the tree holds about 11 non-test `.ts/.tsx` files and about 14 colour-walk files, so the G11 and colour-walk floors start at `> 8` and `> 10`. Step 6 raises them to the spec's `> 15`, once the tree has that many. *Intermediate-only deviation from spec G11; the final state matches the spec. Journal it.*
- **D7: web fixtures are loaded by JSON import, not `node:fs`.** `web-divination/src/chart/fixtures.ts` statically imports `../../../server/tests/fixtures/beijing-1990-{known-time,time-unknown}.json` (`resolveJsonModule`). This needs no `@types/node` in a DOM tsconfig. It is test-only, matched by `WEB_TEST_FILE_RE` (`/fixtures\.ts$`), and imported only by `*.test.tsx`, which review enforces as native does.
- **D8: `vite.config.ts` stays outside the tsconfig `include` (`src` only).** Vite transpiles it itself. This avoids `@types/node` just for `node:path`. Vitest globals stay off: tests import `describe/it/expect/vi` from `vitest` explicitly. `types: ["vite/client"]` covers `import.meta.env` and `*.css` imports. `@testing-library/jest-dom` is not added; assertions are plain DOM reads.
- **D9: domain-orphan guard (`appProd`) also counts web production files.** This matches G10's `appFiles` widening, since a core domain consumed only by the web is not orphaned.
- **D10: G9 isolation reads specifiers with the existing `importSpecifiers` scanner, extended to also capture `import('…')` and `require('…')`.** It flags any web specifier containing `app-native` and any app-native specifier containing `web-divination`. `architecture.test.ts` itself names `web-divination` only in `path.join` strings, which are not specifiers.
- **D11: `document.documentElement.lang` is synced from `App`.** A `useEffect` on `useLang()` does it, not code in `i18n/`. The Web-global ban is core-only, but keeping i18n free of DOM writes keeps it a pure store.

---

## Part B — Implementation plan (imple-plan)

### Overview

Add a Vite + React 19 + TS workspace `web-divination/`. It pins the local
profile, renders a birth form over `@astrace/core/birth-data`, and renders a
pure SVG wheel over `@astrace/core/chart-view` from core's chart
subscription. Two small helpers are added to core (`midLongitude`,
`SIGN_SECTORS`) and one type is exported (`ValidationErrorCode`). The
app-native guards are extended to walk the third tree in the same commit
that creates it. The server is not touched.

### File manifest

**New:**
```
web-divination/
  package.json  index.html  vite.config.ts  tsconfig.json  .env.example
  src/main.tsx  src/session.ts  src/test-setup.ts  src/i18n.test.ts
  src/platform/boot.ts  src/platform/boot.test.ts
  src/app/App.tsx  src/app/Header.tsx  src/app/app.css  src/app/App.test.tsx
  src/i18n/en.ts  src/i18n/zh.ts  src/i18n/lang-store.ts  src/i18n/index.ts
  src/theme/tokens.ts  src/theme/apply.ts  src/theme/global.css  src/theme/apply.test.ts
  src/birth-input/{useBirthData.ts, CityPicker.tsx, BirthForm.tsx, BirthSummary.tsx, birth-input.css, BirthForm.test.tsx}
  src/chart/{useChart.ts, format.ts, wheel-layout.ts, Placements.tsx, ChartWheel.tsx, ChartStage.tsx,
             wheel.css, fixtures.ts, chart-view-additions.test.ts, ChartWheel.test.tsx,
             Placements.test.tsx, ChartStage.test.tsx}
```
**Modified:**
```
package.json                                   workspaces + web/web:server/test/typecheck scripts
package-lock.json                              npm install
packages/core/src/chart-view/geometry.ts       + midLongitude
packages/core/src/chart-view/frame.ts          + SIGN_SECTORS
packages/core/src/chart-view/index.ts          export both
packages/core/src/birth-data/index.ts          + type ValidationErrorCode
app-native/src/architecture.test.ts            G1–G11
app-native/src/color-guard.test.ts             web walk
CLAUDE.md                                      §4.9 amendments
```
**Deleted:** none. **Server:** none (T8).

### Steps

#### - [x] Step 1: Core additions (chart-view helpers + type export)

- Files: `packages/core/src/chart-view/geometry.ts`,
  `packages/core/src/chart-view/frame.ts`,
  `packages/core/src/chart-view/index.ts`,
  `packages/core/src/birth-data/index.ts`,
  `app-native/src/architecture.test.ts`.
- `midLongitude(a, b)` in geometry.ts. It returns `normalize360(a + angularDelta(a, b) / 2)`, the midpoint of the shorter arc. The doc comment names its three call sites (house spans < 180°, 30° signs, conjunctions within orb) and says it replaces the P17-deleted `houseMidLongitude`.
- `SIGN_SECTORS` in frame.ts. It is a readonly array of `{ sign: ZodiacSign; from: number; to: number }`, built by mapping `SIGNS` (value import from `'../chart/types'`, D4) to `from = index·30`, `to = from + 30`. Pisces is `{330, 360}`. This is core-side, so it is allowed there.
- Barrel: add both to the existing `geometry`/`frame` export lines. Beside each, place a temporary `// @public-intent <name>: consumed by web-divination (dw-1 step 2 removes this marker)`.
- birth-data barrel: `export type { BirthData, BirthLocation, ValidationErrorCode, ValidationErrors }` (D1).
- architecture.test.ts: add `'midLongitude'` and `'SIGN_SECTORS'` to `ONE_DEFINITION_SYMBOLS`. The expected table gains `midLongitude: geometry` and `SIGN_SECTORS: ['packages/core/src/chart-view/frame.ts']`.
- **Proof:** `cd app-native && npx jest src/architecture.test.ts` green, and `npm run typecheck` (root) green.
- Commit type: `feat`.

#### - [x] Step 2: Workspace birth, carrying the guard extension, CLAUDE.md amendment and first web tests (ONE commit)

This is the commit that creates `web-divination/`. By the spec (§4.8, §4.9)
it must also extend both guards and amend CLAUDE.md. Load `/frontend-design`
first, because the shell, tokens and global.css are UI.

*2a. Scaffolding and wiring*
- `web-divination/package.json`:
  - Name `web-divination`, private, `type: module`.
  - Scripts: `dev` (vite), `build` (`tsc --noEmit && vite build`), `preview`, `test` (`vitest run`), `typecheck` (`tsc --noEmit`).
  - deps: `react` and `react-dom` exactly `19.2.3`, `@astrace/core: "*"`, `@fontsource-variable/fraunces`, `@fontsource/source-serif-4`.
  - devDeps: `vite` ^8.3, `@vitejs/plugin-react` ^6.1, `vitest` ^5.0, `jsdom` ^30, `@testing-library/react` ^16.3, `@testing-library/dom` ^10, `@testing-library/user-event` ^14, `@types/react` ~19.2.2 (the same range as app-native, so it dedupes), `@types/react-dom` ~19.2, and `typescript` ~6.0.3.
  - Re-check `npm view` at install time and take current stable if it moved.
- `vite.config.ts`:
  - react plugin, and the alias `^@astrace/core/(.*)$` → `../packages/core/src/$1/index.ts` (resolved from the config's directory via `new URL(…, import.meta.url)` + `fileURLToPath`; D8).
  - `server: { port: 5173, strictPort: true }`, with no proxy.
  - `test: { environment: 'jsdom', include: ['src/**/*.test.{ts,tsx}'], setupFiles: ['./src/test-setup.ts'] }`.
- `tsconfig.json`: core's compiler options (A.1) plus `jsx: react-jsx`, `lib` += `DOM.Iterable`, `types: ["vite/client"]`, `include: ["src"]`.
- `index.html`: `<div id="root">`, `<script type="module" src="/src/main.tsx">`, and no colour or theme-color meta. `.env.example`: `VITE_API_BASE=http://localhost:8000`.
- Root `package.json`:
  - `workspaces` += `"web-divination"`.
  - `test`: `npm test --workspace app-native && npm test --workspace web-divination`.
  - `typecheck`: both workspaces, chained with `&&`.
  - `web`: `npm run dev --workspace web-divination`.
  - `web:server`: `CORS_ALLOW_ORIGINS=http://localhost:5173 npm run server` (POSIX-only, which is fine under the local-only ruling).
- Run `npm install` at the repo root. Check with `npm ls react --all` that only 19.2.3 appears (T7) and that `react-dom` resolves to 19.2.3.

*2b. Boot, session, theme, i18n, shell*
- `src/theme/tokens.ts`:
  - `webTokens`, typed `WebTokens`, with values copied from native INK: `ground #08090e`, `wheelCore`, `wheelMid`, `wheelRim`, `aura`, `voice` (gold `#d3a94f`), `line`, `lineSoft`, `themeGhost`, text ladder (parchment primary/secondary/tertiary), `danger`, plus the web-only translucent tokens `star` and `goldWash` (D2).
  - `aspect: Record<AspectType, string>` and `element: Record<Element, string>` (type imports from `@astrace/core/chart` and `@astrace/core/chart-view`).
  - Header comment: sole chromatic home for this tree (rule 13 amended), and no parity with native (a non-goal).
- `src/theme/apply.ts`: `applyTheme(root = document.documentElement)`. It flattens tokens to `--kebab-case` (`wheelCore` → `--wheel-core`, `aspect.trine` → `--aspect-trine`, `element.fire` → `--element-fire`) and calls `root.style.setProperty` for each. It also exports `cssVarName(path)` for the test.
- `src/theme/global.css`:
  - `@font-face` comes via the fontsource imports in main.tsx.
  - `body { background: var(--ground); color: var(--text) }`, and the font stacks (Fraunces display / Source Serif 4 body / zh fallback `"Songti SC","Noto Serif SC",serif`).
  - The `aura` corner wash and the star-grain radial-gradient dots in `var(--star)`.
  - A focus-visible ring in `var(--voice)`, and a `prefers-reduced-motion` block.
  - Class selectors only.
- `src/i18n/lang-store.ts`: `Lang`, `LANG_STORAGE_KEY = 'astrology.lang.v1'`, `configureLangPersistence(port, fallback)`, `getLanguage`, `setLanguage`, `subscribeLanguage`. It mirrors native, and the seed order is persisted → `fallback`. It imports nothing.
- `src/i18n/en.ts`: `en` + `export type Dict = typeof en`. Widen string literals: declare the dictionary shape as a `Dict` interface of `string` leaves, so zh isn't forced to match English text.
  - Namespaces: `app` (wordmark, toggle labels), `form` (labels, placeholders, time-unknown, submit, edit, attribution, loadingPlaces, savedSuffix, timezone), `errors` keyed by every `ValidationErrorCode` string, `chart` (aria label, planet title template parts, AC/MC, timeUnknownNote, bigThree labels), `status` (empty invitation, loading, error "The sky is out of reach", retry), `signs` keyed by the 12 canonical English sign names, `bodies` keyed by the 10 `BODIES` plus `Ascendant` and `Midheaven`.
  - `zh.ts: Dict` has the same shape, e.g. `signs.Gemini = '双子座'`.
- `src/i18n/index.ts`: `useLang()` (`useSyncExternalStore` over the void adapter), `useDict()` (returns `en` or `zh`), and re-exports `setLanguage`, `Lang`, `Dict`. It imports only `react` and `./` siblings.
- `src/platform/boot.ts`, in this order:
  1. `configureApiBase(import.meta.env.VITE_API_BASE || 'http://localhost:8000')`
  2. No KV reconfigure (comment says why).
  3. `configureLangPersistence({read: k => getKV().getItem(k), write: (k,v) => getKV().setItem(k,v)}, navigator.language.startsWith('zh') ? 'zh' : 'en')`
  4. `applyTheme()`

  Export `apiBase` for the test.
- `src/session.ts`: `LOCAL_PROFILE = 'traveler'`, `ensureLocalProfile()` (same as native), called on import.
- `src/main.tsx`: import `./platform/boot`, then `./session`, then the fontsource CSS and `./theme/global.css`, then `createRoot(#root).render(<StrictMode><App/></StrictMode>)`.
- `src/app/App.tsx`: renders `<Header/>` and `<main className="layout">` with `<section className="stage" data-slot="stage">` and `<aside className="side" data-slot="side">`. The slots stay empty in this step apart from a placeholder comment for the dw-2 chat mount, and they are filled in steps 3/6. The `lang` sync effect lives here (D11).
- `src/app/Header.tsx`: wordmark (Fraunces), and an EN/中 toggle as two `aria-pressed` buttons calling `setLanguage`.
- `src/app/app.css`:
  - A grid that stacks by default; at `min-width: 960px` it uses `grid-template-columns: minmax(0, 1fr) minmax(320px, 420px)`.
  - The stage is capped at 640 px square.
  - `padding-inline: 16px`, and `min-width: 0` on children so there is no 375 px overflow.
- `src/test-setup.ts`: the RTL `cleanup` afterEach and `localStorage.clear()`.

*2c. Guard extension (architecture.test.ts, per spec §4.8)*

Add `WEB_DIR = path.join(REPO_ROOT, 'web-divination', 'src')`, plus
`WEB_TEST_FILE_RE = /(\.test\.tsx?$|__fixtures__|\/fixtures\.ts$)/`, plus the
`test-setup.ts` exclusion, plus a `webSources()` twin of
`appNativeSources()` (returning file / code / text).
- G1: the barrel test walks `APP_NATIVE_DIR` and `WEB_DIR`.
- G2: the one-definition `sources` gain `WEB_DIR`.
- G3: a new test, "web-divination names no network API outside src/platform". It uses `WEB_NETWORK_RE = /\b(fetch|apiUrl)\s*\(|\bXMLHttpRequest\b|\bEventSource\b|\bWebSocket\b/` over `webSources()` minus `web-divination/src/platform/`. Self-checks: `new EventSource(u)` and `fetch(x)` bite, a comment does not.
- G4: a new test using `COMPUTATION_RE` **plus** `LONGITUDE_ARITH_RE = /\b(longitude|lonA|lonB|cusp|cusps|ascendant)\s*[-+*/%]/` over `webSources()` code (comments and strings stripped). Self-checks:
  - bites: `lonA + lonB`, `cusp - asc`, `longitude*2`, `(x - y) % 360`
  - does not bite: `cusps[(i + 1) % 12]`, `chart.ascendant?.longitude ?? null`, `longitude: entry.longitude,`, `toScreenAngle(p.longitude, asc)`
- G5: web value-importers of `@astrace/core/chart`, non-test, equal exactly `['web-divination/src/chart/useChart.ts']`. **This test is born pending**: `useChart.ts` lands in step 4, so in step 2 the expectation is `[]` and step 4 flips it. Say so in the step 4 commit message.
- G6: every non-test file under `WEB_DIR/i18n` has only the specifiers `react` and `./…`. Self-check: `@astrace/core/platform`, `../chart` and `react-dom` bite.
- G7: every non-test file under `WEB_DIR/theme` has only the specifiers `react`, `@astrace/core/chart-view`, `@astrace/core/chart` and `./…`. Self-check: `../chart/useChart` and `@astrace/core/platform` bite.
- G8: the astronomy-engine and key-leak walks gain `WEB_DIR`.
- G9: new "workspace isolation" (D10), with a self-check.
- G10: the public-API `appFiles` includes the `WEB_DIR` `.ts/.tsx` files. The domain-orphan `appProd` includes web production files (D9). Remove the two `@public-intent` markers from step 1, because `chart-view-additions.test.ts` (below) consumes both and ChartWheel will too.
- G11: the walked-trees test adds `expect(webSources().length).toBeGreaterThan(8)` (D6, raised in step 6).
- Update the file header comment to "three trees".

*2d. Colour guard (color-guard.test.ts)*
- A new test, "web-divination has exactly one colour home". It walks `WEB_DIR` `.ts/.tsx/.css` minus tests and fixtures, plus `web-divination/index.html`, minus `web-divination/src/theme/tokens.ts`, and asserts no chromatic literal. It also asserts `files.length > 10` (D6).
- Classifier self-checks added: `findColorLiterals('color: var(--line);')` gives `[]`; `findColorLiterals('color: #e39a4a;')` gives `['#e39a4a']`; and `findColorLiterals('.x { }')` is clean when the selector is a class.

*2e. CLAUDE.md (spec §4.9), same commit*
- The "web frontend was deleted" paragraph gains the `web-divination/` note: explicitly asked for (divination epic, 2026-09-28), local-only, and not a re-creation of `frontend/`.
- Commands block: `npm run web`, `npm run web:server`, and the workspace's `test`/`typecheck`/`build`. The root `test`/`typecheck` now run both.
- Rules 1, 2, 5: name `web-divination/src` beside `app-native/src`. The guard lists mention the third tree and the `midLongitude`/`SIGN_SECTORS` one-definition symbols.
- Rule 8 rewrite: two dictionaries, one per workspace, each with its own parity test. They are not checked against each other.
- Rule 13: two token homes, one per workspace. Web CSS reads `var(--…)` only, and translucent colours are named tokens (D2). There is no parity test between the homes.

*2f. First web tests (so the tree is exercised at birth)*
- `src/chart/chart-view-additions.test.ts` (T3): `midLongitude(350,10)===0`, `midLongitude(10,350)===0`, `midLongitude(0,30)===15`, `SIGN_SECTORS.length===12`, Pisces `{from:330,to:360}`, all through the `@astrace/core/chart-view` barrel. Note: `toBe(0)` must not pick up `-0`; use `Object.is`-safe `toBe(0)` after normalize360 and check this.
- `src/i18n.test.ts` (T4):
  - Typed bindings `const _eErr: Record<ValidationErrorCode, string> = en.errors` (and zh), plus `Record<ZodiacSign, string>` for `signs` and `Record<Body, string>` for `bodies`. These use `import type` from the birth-data and chart barrels (D1).
  - Runtime: leaf-path set equality en↔zh, no empty strings, and every `BODIES` entry plus every `SIGN_SECTORS[i].sign` has a non-empty string in both.
- `src/theme/apply.test.ts`: `applyTheme` on a fresh element sets `--ground` = `#08090e` and one `--aspect-*` / `--element-*` per key.
- `src/platform/boot.test.ts`:
  - After importing boot, `apiUrl('/api/chart')` = `http://localhost:8000/api/chart`.
  - With `localStorage['astrology.lang.v1']='zh'` pre-seeded (`vi.resetModules`), `getLanguage()==='zh'`.
  - `document.documentElement.style.getPropertyValue('--ground')` is set.
- `src/app/App.test.tsx` (shell only): renders the header and both `[data-slot]` regions, and the toggle switches `useLang`.

- **Proof (all must pass):**
  - `npm install` clean.
  - `npm run typecheck` (root, both workspaces).
  - `npm test` (root, both suites).
  - `cd app-native && npx jest src/architecture.test.ts src/color-guard.test.ts`.
  - `npm ls react --all` shows only 19.2.3.
  - Planted-violation smoke for G-a, G-c, G-f, G-h, G-i against the files that exist now (plant → red naming the file → revert → green). G-b, G-d, G-e and G-g are re-run in step 8 once their target files exist.
- Commit type: `feat` (one commit; it also touches CLAUDE.md and both guards).

#### - [x] Step 3: Birth input (form, city picker, summary, persistence)

Load `/frontend-design`.
- `src/birth-input/useBirthData.ts`: the void-adapter `useSyncExternalStore(subscribe, getBirthData)` (native twin).
- `src/birth-input/CityPicker.tsx`:
  - Props `{ value: CityPick | null, onPick(pick), savedLabel?: string, errorId?: string }`, where `CityPick` is `{ location: BirthLocation; timezone: string }`.
  - `loadCityIndex()` runs in an effect, showing "Loading places…" until it resolves.
  - Country `<select>`: `countryCodes(index)`, labelled via `new Intl.DisplayNames([lang], {type:'region'})`, sorted with `localeCompare(…, lang)`, with an empty first option and no preselection.
  - A search `<input>` → `searchCities(index, country, query)`, rendered as a `role="listbox"` list of `<button role="option">` "name · admin1Name", capped by `SEARCH_CAP`.
  - Picking a city sets `{name, latitude, longitude}` + `timezone`.
  - A read-only timezone readout.
  - The attribution line "Places: GeoNames, CC-BY 4.0".
- `src/birth-input/BirthForm.tsx`:
  - Controlled date, time and time-unknown (which disables time), plus CityPicker.
  - Submit builds `BirthData{date, time: unknown ? null : time /* '' stays '' */, location, timezone, schemaVersion: 1}`. With no pick, it uses `location {name:'', latitude:NaN, longitude:NaN}` and `timezone ''` so core returns `location-required` (check that `validateBirthData` returns that code for an empty name; if lat NaN also yields `lat-not-number`, render the location-group codes under the picker in order).
  - `validateBirthData`: render `dict.errors[code]` next to each field with `aria-describedby` / `aria-invalid`. The field→slot map is date→date, time→time, and locationName/latitude/longitude/timezone→picker. When the result is empty, call `saveBirthData`, then `onSaved()`.
  - Edit mode: the prop `initial: BirthData`. It pre-fills everything; the picker shows "Beijing — saved" as the current pick with no country selected, and submitting without re-picking keeps the saved location.
- `src/birth-input/BirthSummary.tsx`: a one-liner "1990-06-15 · 08:30 · Beijing (Asia/Shanghai)", showing the time-unknown text when time is null, plus an **Edit** button.
- `src/birth-input/birth-input.css`:
  - Underline-only inputs with `var(--line)` borders.
  - A gold-outlined submit that fills `var(--voice)` on hover/focus.
  - Small-caps field labels, and the attribution in small type.
- App wiring: the `side` slot renders `BirthSummary` when `useBirthData()` is non-null and not editing, else `BirthForm`.
- `src/birth-input/BirthForm.test.tsx`:
  - Empty submit shows the translated date-required, time-format and location-required messages, and neither `fetch` nor save is called (A2 in unit form).
  - Pick a Beijing entry: stub `loadCityIndex` data by using the real lazy index (Vitest resolves the JSON import). If it is slow, keep it and raise the test timeout rather than mocking core.
  - Submit writes `astrology.birthData.v1.traveler` with date, time, `"timezone":"Asia/Shanghai"` and `"name":"Beijing"` (A4 in unit form).
  - Time-unknown stores `"time":null`.
  - The zh toggle renders zh labels.
- **Proof:** `npm test --workspace web-divination`, `npm run typecheck`, and `cd app-native && npx jest src/architecture.test.ts src/color-guard.test.ts`.
- Commit type: `feat`.

#### - [x] Step 4: Chart seam, formatting, placements

- `src/chart/useChart.ts`: `useChart()`, `useChartStatus()`, and re-exported `retryChart`, as a native twin. It is the only value-importer of `@astrace/core/chart`. Flip G5's expectation from `[]` to `['web-divination/src/chart/useChart.ts']` in architecture.test.ts (same commit).
- `src/chart/format.ts`: `degreeText(pos)`, which returns `${degreeInSign}°${String(minuteInSign).padStart(2,'0')}′`. This is formatting only.
- `src/chart/fixtures.ts`: test-only JSON imports of the two goldens (D7). Its header says "never import from shipped code".
- `src/chart/Placements.tsx`:
  - Props `{ chart: BirthChart }`, with the dictionary taken from `useDict`.
  - Big-three line `☉ sign · ☽ sign · ASCENDANT_GLYPH sign`, where the Asc part is omitted if `chart.ascendant` is null.
  - Rows in `chart.planets` order carry `data-placement`, glyph, body name, degree text, sign glyph + name, `H<n>` when present, and ℞.
  - Ascendant/Midheaven rows follow when present.
  - The timeUnknown note shows when `chart.timeUnknown`.
- `src/chart/Placements.test.tsx`:
  - Known-time golden: the Sun row reads `23°38′`, Gemini, H11, and the big three reads Gemini/Pisces/Cancer.
  - Unknown golden: the note shows, with no Ascendant row.
  - In zh the Sun row shows 双子座.
- **Proof:** web tests, typecheck, and the arch guard (G5 now expects useChart.ts).
- Commit type: `feat`.

#### - [x] Step 5: The pure SVG wheel

Load `/frontend-design`. Adapt the layer order and idioms from
`git show d0e36b1:frontend/src/features/chart-display/ChartWheel.tsx`.
- `src/chart/wheel-layout.ts`: `SIGN_GLYPH_R` (the midpoint of `rOuter` and `rZodiacIn`) plus any label radii, e.g. `ANGLE_LABEL_R = rOuter + 4`, as radial constants derived from `WHEEL_VIEW`. It has no longitude terms.
- `src/chart/ChartWheel.tsx`:
  - Props `{ chart: BirthChart | null; ariaLabel: string; labels: { planetTitle(p): string; ac: string; mc: string } }`. It is pure, with no hooks subscribing to stores.
  - `viewBox` comes from `WHEEL_VIEW`.
  - `asc = chart?.ascendant?.longitude ?? null`.
  - Layers:
    1. `<defs>` with the radialGradient in `var(--wheel-core)` → `var(--wheel-mid)` → `var(--wheel-rim)` (stop-color via CSS classes or `style={{stopColor: 'var(--…)'}}`, never a literal).
    2. Ground, then the rim, then hairlines at `rZodiacIn` and `rHub`.
    3. The zodiac ring from `SIGN_SECTORS`: `sectorPath(from,to,asc)` filled `var(--element-<SIGN_ELEMENTS[sign]>)`, with the glyph at `wheelPoint(SIGN_GLYPH_R, midLongitude(from,to), asc)` and `data-sign`. This ring always renders.
    4. When `chart?.houses` is set:
       - 12 cusp lines from `rHub` to `rZodiacIn`, with AC (0) and MC (9) running to `rOuter` in the bold class.
       - `data-angle="AC"|"MC"` labels at `ANGLE_LABEL_R`.
       - House numbers with `data-house-number` at `wheelPoint(rHouseNum, midLongitude(cusps[i], cusps[(i+1)%12]), asc)`.
    5. Aspects:
       - Hub points come from `wheelPoint(rHub, lon, asc)`.
       - Non-conjunctions are `<path d=bowedChordPath(a.x,a.y,b.x,b.y,cx,cy,BUNDLE_K)>`, stroked `var(--aspect-<type>)`, with a dashed class for sextile/square and a strong class when `orb < 2`.
       - Conjunctions are a `<circle>` at `wheelPoint(rHub, midLongitude(lonA, lonB), asc)`.
       - All carry `data-aspect`, `data-aspect-key={aspectKey(a)}`, and the CSS var `--i` for the draw-in delay.
       - How to read each aspect endpoint's longitude comes from the `AspectPoint` shape; check `aspect-set.ts`/`types.ts` for field names.
    6. Hub nodes: one per planet, plus Ascendant when `asc !== null`.
    7. Planets: `angles = declusterAngles(planets.map(p => toScreenAngle(p.longitude, asc)))`.
       - Each `<g data-planet data-sign data-house?>` holds a `<title>`, a tick from `wheelPoint(rTick, p.longitude, asc)` to `wheelPoint(rHub, …)`, a glyph at `polarToXy(cx, cy, rPlanet, angles[i])`, and "℞" when retrograde.
       - Each group sets `style={{'--i': i}}` for the stagger.
  - Every coordinate comes from a core helper. There is no `+ - * / %` after a longitude/cusp/ascendant identifier (G4).
- `src/chart/wheel.css`:
  - Classes for rim, hairline, cusp and cusp-angle, glyph fonts, and dash patterns.
  - The reveal: the ring fades, planets use `animation-delay: calc(var(--i) * 40ms)`, and chords draw via `stroke-dasharray`/`stroke-dashoffset` keyframes.
  - A `.wheel--loading` breathing opacity pulse.
  - All of it off under `prefers-reduced-motion: reduce`.
  - Colours via `var(--…)` only.
- `src/chart/ChartWheel.test.tsx` (T2):
  - Known golden:
    - 12 `[data-sign]` in the ring group
    - Sun `data-sign="Gemini"` and `data-house="11"`
    - 10 `[data-planet]`
    - 12 `[data-house-number]`
    - AC and MC present
    - chord `path[data-aspect]` count = aspects whose type ≠ conjunction
    - ≥1 `[data-aspect-key]`
  - Unknown golden: 0 house numbers, no AC/MC, and no planet has `data-house`.
  - `chart=null`: 12 sign sectors and 0 planets.
- **Proof:**
  - `npm test --workspace web-divination` and `npm run typecheck`.
  - The arch and colour guards.
  - Plant G-e (`(lonA + lonB) / 2` in ChartWheel.tsx) → red → revert → green.
  - Plant G-d (a second `export function midLongitude` in a web file) → red → revert.
- Commit type: `feat`.

#### - [x] Step 6: Chart stage, states, retry, App integration

- `src/chart/ChartStage.tsx`:
  - It uses `useChart()` and `useChartStatus()`.
  - `empty` shows the ring plus a one-line invitation; `loading` shows the ring with `.wheel--loading`; `ready` shows the full wheel with `.wheel--reveal` (keyed on the birthDataKey or chart identity so the reveal replays on a new chart).
  - `error` shows the ring, the "The sky is out of reach" text, and a **Retry** `<button>` → `retryChart()` (D3).
  - It passes the translated `ariaLabel` and the `planetTitle` builder ("Sun 23°38′ Gemini, house 11").
  - `Placements` renders under the stage in the side column, or under the birth card. Put it in the `side` slot below the birth card, so the stage stays wheel-only.
- App wiring: the `stage` slot renders `<ChartStage/>`, and the `side` slot shows the birth card, then Placements when the chart is ready.
- Raise the floors (D6): the G11 web floor goes to `> 15` and the colour walk to `> 15`. Confirm the tree now exceeds them.
- `src/chart/ChartStage.test.tsx` (D3):
  - `fetch` is stubbed to reject once, then resolve with the golden chart.
  - Pre-seed the Beijing record and render `<App/>`, which shows the error text and Retry.
  - Click Retry: Sun `data-sign="Gemini"` appears. `fetch` was called twice, and a `vi.spyOn(window.location, 'reload')`-equivalent guard (or document identity) shows no reload.
- `src/app/App.test.tsx` gains T5:
  - `localStorage` is pre-seeded with the Beijing record, and `fetch` is stubbed to the known golden.
  - `fetch` was called with `'http://localhost:8000/api/chart'` and `method: 'POST'`.
  - The wheel shows Sun Gemini, and the side shows the summary + Edit.
  - Uses `vi.resetModules()` and a dynamic import of boot, session and App per test, so core's singleton seam starts clean.
- **Proof:** `npm test` (root) and `npm run typecheck` (root), the arch and colour guards, and planting G-g (`subscribeChart` import in Placements.tsx) → red → revert.
- Commit type: `feat`.

#### - [x] Step 7: Visual pass, build, responsive, dedupe

Load `/frontend-design`. This is a polish-only commit; skip it if nothing
changes.
- Atmosphere finish: the aura corner, the star grain, and the gold hairlines on the birth card panel.
- Check the two-column split at ≥960 px and stacking below it.
- 375 px: no overflow (`min-width: 0`, the SVG `width: 100%`, a long country `<select>` capped at `max-width: 100%`).
- Focus rings on every control.
- **Proof:**
  - `npm run build --workspace web-divination` exits 0 (T6).
  - `npm ls react --all` resolves a single 19.2.3 (T7).
  - `git diff $(git merge-base HEAD feature/divination_web) -- server/` is empty (T8).
  - Root `npm test` and `npm run typecheck` green.
- Commit type: `style` or `feat`.

#### - [x] Step 8: Validation (stage `validating`, recorded here for resumability)

Log results in `logs/dw-1-birth-chart-web/NN-validation.md`.
1. Automated: root `npm test`, root `npm run typecheck`, T6, T7, T8, `npm run server:test` (sanity; the server is unchanged).
2. Guards: run every planted-violation check G-a through G-i from the spec against the named files, using `cd app-native && npx jest src/architecture.test.ts src/color-guard.test.ts`. Each must go red and name the file. Revert and confirm green. For G-b, the `fetch` in `platform/boot.ts` must stay green.
3. Running app:
   - Start the backend in the background: `CORS_ALLOW_ORIGINS=http://localhost:5173 npm run server`, which is `web:server`, i.e. conda env `astrology`, :8000.
   - Start `npm run web` in the background on :5173.
   - Wait for both: `curl -s localhost:8000/api/health` and `curl -s -o /dev/null -w '%{http_code}' localhost:5173`.
4. Drive Chrome through the claude-in-chrome tools (`navigate`, `javascript_tool`, `read_network_requests`, `resize_window`, `form_input`, `computer`). Clear that origin's localStorage first.
   - A1: `svg [data-sign]` = 12, and no `[data-planet]`.
   - A2: submit empty. The messages are visible, and there is no `/api/chart` request in network.
   - A3: 1990-06-15, 08:30, China, "Beijing", pick, submit.
     - The timezone readout shows `Asia/Shanghai` before submit.
     - One POST returns 200.
     - The wheel: 10 planets, Sun Gemini/H11, Moon Pisces, 12 house numbers, AC/MC, ≥1 aspect key.
     - Placements: `23°38′` and the big three.
   - A4: the localStorage JSON is as specified. After a hard reload the same wheel shows, with the summary + Edit.
   - A5: Edit → time unknown → submit gives 10 planets, 0 house numbers, no AC/MC, no `data-house`, the note, no Ascendant row, and stored `"time":null`.
   - A6: toggle 中 gives zh labels and 双子座; it persists after reload.
   - A7: stop the backend and reload, which shows the error text and Retry. Restart the backend and click Retry in the same tab; the wheel renders. Assert with `performance.getEntriesByType('navigation').length` and a `window.__marker` set before the click and still present after.
   - A8: at 375 px `scrollWidth <= 375` and `stage.bottom <= side.top`; at 1280 px `stage.right <= side.left`.
   - A9: `getComputedStyle(document.body).backgroundColor === 'rgb(8, 9, 14)'`.
5. Stop both background servers (TaskStop / kill the uvicorn and vite PIDs). Confirm that `lsof -i :8000 -i :5173` is empty.
6. Pass → `docs-sync`. Fail → fix under `implementing` (cycle budget).

#### - [x] Step 9: Docs sync (stage `docs-sync`, recorded here for resumability)

- Run `/update-architecture-doc` on `docs/ARCHITECTURE.md`, diff-driven since the doc's last touch. It must cover:
  - the third workspace
  - the web composition root
  - the guards now walking three trees
  - `midLongitude`/`SIGN_SECTORS`/`ValidationErrorCode` in the core barrels
  - the second token home and second dictionary
- Write `docs/features/dw-1-birth-chart-web.md` directly (gitignored, a frozen snapshot of what was actually built, including the D1–D11 deviations).
- Commit `docs/ARCHITECTURE.md` (`docs` type).

### Data flow (runtime)

```
main.tsx
 ├─ platform/boot: configureApiBase(VITE_API_BASE‖:8000) → configureLangPersistence(getKV, navigator seed) → applyTheme()
 ├─ session: login('traveler') if none active
 └─ render <App/>
      side:  useBirthData() ─null→ BirthForm ─submit→ validateBirthData ─{}→ saveBirthData ─KV set + notify─┐
                            └data→ BirthSummary (+Edit → BirthForm initial=data)                           │
      stage: ChartStage ← useChart/useChartStatus ← core chart service ← birth-data subscribe ◄────────────┘
                                                       └ fetch POST {base}/api/chart → BirthChart → ready
             status error → Retry → retryChart() → recompute (no reload)
             ChartWheel(chart) → SVG from core chart-view helpers;  Placements(chart) in side
```

### Test plan summary

| Spec item | Where proven |
|---|---|
| T1 | root `npm test` / `npm run typecheck` (steps 2–7) |
| T2 | `chart/ChartWheel.test.tsx` (step 5) |
| T3 | `chart/chart-view-additions.test.ts` (step 2) |
| T4 | `src/i18n.test.ts` runtime and typecheck (step 2); sanity-check by deleting a key from zh.ts → typecheck red → revert |
| T5 | `app/App.test.tsx` (step 6) |
| T6, T7, T8 | step 7, re-run in step 8 |
| G-a…G-i | partial in steps 2/5/6, full in step 8 |
| A1–A9 | step 8 (browser), with unit mirrors in steps 3/5/6 |

### Risks and checks for the implementer

- **Two React copies.** If `npm install` nests `react` under `web-divination/node_modules`, fix the pin and dedupe (`npm dedupe`) before going further. An invalid-hook-call is the symptom.
- **jest-expo picking up web files.** app-native jest `roots` is `src`, so it will not. The guards only `fs.readFileSync` web files.
- **Core typecheck under web options.** If core source trips a web-only option, align the web tsconfig to core's options. Never edit core to satisfy the web.
- **City index size in vitest.** The generated JSON is large. The first import may be slow; raise the per-test timeout rather than mock core.
- **`-0` from `midLongitude`.** If `normalize360` can return `-0`, `toBe(0)` fails, so normalize with `+ 0` inside core only if needed.

### Decisions to journal (pipeline/DECISIONS.md at accept time)

D1 (type export instead of derivation; spec §4.8 said it was already
exported), D2 (rgba tokens, not triplets), D6 (staged walk floors), D7
(JSON-import fixtures), D10 (G9 also reads `import()`/`require()`). The
rest follow directly from the spec.
