# dw-15-wheel-spotlight — the web wheel glows with native's shader, and focuses on the picked character

Epic: `pipeline/epics/divination-web.md` (cited, not restated). Queue entry:
`pipeline/QUEUE.md` → `## dw-15-wheel-spotlight` (user-requested 2026-09-29).

## Goal

Per QUEUE.md `## dw-15-wheel-spotlight`: the web wheel lights aspects with native's own `SPOTLIGHT_SKSL`,
compiled by CanvasKit-WASM, in place of dw-4's SVG glow; with a character picked it shows only that
planet's aspect web, and one control shows the full chart.

## Non-goals

- No hand-ported GLSL/WebGL twin of the shader. No second copy of the SkSL
  text anywhere, so no DECISIONS entry for a copy is needed.
- No change to the shader source, its uniforms or its look. `SPOTLIGHT_SKSL`
  is byte-identical before and after.
- No wheel interactivity beyond the focus control: no hover, no tap-to-pin a
  chord, no lore sheets, no aspect captions (native's tour and pin captions
  stay native-only).
- No change to how pills, chips or replies choose what is lit. dw-4's
  `showRefs`/`activationFor` and dw-10's pills are reused as they are.
- No server change, no wire change, no new endpoint, no KV key.
- No change to native's look or behaviour, apart from the one conjunction
  wrap fix that comes from sharing the chord helper (Decided default D13).
- No routing, and nothing that avoids dw-12's sign-in gate or dw-14's router.
  Both are on other branches and edit `App.tsx`. This feature adds one prop
  there, and the overlap is resolved at landing like any other conflict.
- No production bundle budget work. The app is local only; the ~7 MB wasm
  (2.9 MB gzip) loads lazily and is accepted.

## Decided defaults

**D1. The shader runs as CanvasKit, not as a GLSL port.** `canvaskit-wasm`
0.41.0 is already in the repo's root `node_modules` (as a dependency of
native's `@shopify/react-native-skia`). Its default `bin/` build has
`RuntimeEffect`. Measured on 2026-09-29: in node, it compiled
`SPOTLIGHT_SKSL` unchanged with no error, reported 6 uniforms / 11 floats,
and drew a beam with 10,062 lit pixels on a 200×200 CPU surface.
`web-divination` declares `canvaskit-wasm` `0.41.0` itself, the same version
native resolves, so npm dedupes it. The deleted web wheel did the same thing
(`git show d0e36b1:frontend/src/features/chart-display/skia.ts`), and
core's `spotlight.ts` comments already expect it.

**D2. Layering.** One `<canvas>` sits exactly over the SVG wheel's box. It
has `pointer-events: none` and is `aria-hidden`. The SVG stays the
accessible, addressable wheel: every `data-*` hook from dw-1, dw-4 and dw-10
is kept. The canvas draws only glow and adds no marks.

**D3. What glows, with a pill lit ("voice" beams).** While a dw-4 activation
matches the shown chart:
- every LIT aspect gets one beam: glow scale 1.0, coloured with the aspect
  type's web token `webTokens.aspect[type]`;
- every lit planet that is not an endpoint of a lit aspect gets a point bloom
  at its hub node (a collapsed chord A=B=C, the shader's own conjunction
  path), coloured with the active character's ink (`webTokens.persona[id]`,
  or Venus's with no character);
- echo aspects get no beam.

While an activation stands, the focus beams (D4) stop. There is one voice at
a time, as with native's pin over its tour.

**D4. What glows in focus, with nothing lit ("focus" beams).** Every aspect
in the focus planet's family (core `planetFamily`) gets a beam with glow
scale 0.6 (native's `FACTOR_BEAM_GLOW`), coloured by aspect type. A focus
planet with no aspects gets one point bloom at scale 0.6. At most 12 beams
are drawn, tightest orb first.

**D5. Full chart at rest has no beams.** It is dw-1's static wheel. A pill
lit in full-chart mode still gets its voice beams.

**D6. Focus.** Focus is on when a character is active, the chart is
`ready`, and the user has not chosen the full chart. The focus set is
`planetFamily(chart.aspects, PERSONA_BODIES[active])`: the planet, its
aspects, and the bodies at their other ends (Ascendant included when it is
a partner).
- Aspect chords and conjunction dots outside the focus set are HIDDEN.
- Planets (glyph and tick) and hub nodes outside the set are DIMMED to a
  ghost (opacity 0.16).
- The zodiac ring and houses are unchanged.
- The svg carries `data-focus="<Body>"`. Every out-of-focus planet, chord,
  conjunction dot and hub node carries `data-focus-out`.

**D7. Pills outside the focus still work.** While an activation stands, the
visible set is focus ∪ lit ∪ echo. Every lit or echo element loses
`data-focus-out`, and dw-4's tiers then apply inside that set as they do
today. When the activation clears, the wheel returns to plain focus.

**D8. The control.** One `button[data-focus-toggle]` sits between the wheel
and the stage caption. It is rendered only when focus is possible (a
character is active and the chart is ready).
- In focus it reads "Show full chart" / "显示完整星盘", with
  `aria-pressed="false"`.
- In full chart it reads "Focus on {name}" / "聚焦{name}", with the
  character's display name from the i18n bodies, and `aria-pressed="true"`.
- It uses the existing quiet-button look (`button button--quiet`), with the
  character glyph in `--char` before the label.

The choice is page-session React state held in `ChartStage`. It is not
stored in KV. Picking a DIFFERENT character resets it to focus. A reload
opens in focus.

**D9. Motion.** Focus ↔ full chart crossfades the hidden and dimmed
elements over 480 ms (opacity only). The canvas fades in over 400 ms when it
mounts. `u_time` is seconds since the layer mounted, taken from
`performance.now()`, the same time base as native. All beams share one
clock.

**D10. Reduced motion.** Under `prefers-reduced-motion: reduce`, no canvas
is mounted and CanvasKit is never loaded. The lit aspects render as dw-4's
static lit chords, drop-shadow included. Focus still applies, with no
crossfade (instant). The hook follows the media query live: toggling it
mounts or unmounts the canvas without a reload.

**D11. Fallback.** Any of these fails: CanvasKit load, surface creation
(WebGL first, then the software surface), or `RuntimeEffect.Make`. The
layer then logs one `console.warn`, draws nothing, and the stage reads
`data-spotlight="static"`, which is the same rendering as D10. While
CanvasKit loads, the stage reads `data-spotlight="loading"` and the static
lit chords show. While beams run, it reads `data-spotlight="live"`, and
wheel.css then drops the SVG drop-shadow on lit chords and conjunction dots
(the stroke stays lit). Lit planet glyphs keep their glow.

**D12. Pixels.**
- Uniforms are in CSS px of the wheel box. The backing store is
  box × min(devicePixelRatio, 2), with a canvas scale, so glow widths match
  native's point-based tuning.
- Each beam fills only its chord's bounding box padded by 64 CSS px.
- The layer follows the box size through a ResizeObserver.
- The loop runs only while there is at least one beam. The canvas unmounts
  when there are none.

**D13. One chord helper.** The wheel-unit geometry of a beam (endpoints, bow
control point, conjunction collapse) moves into core as
`spotlightChord(aspect, chart, view)`. It uses `wheelPoint`, `quadControl`
+ `BUNDLE_K` and `midLongitude`. Both clients use it. Native's
`spotlightLineFor` keeps its px mapping and colour and calls it.

This also fixes native's `(lonA + lonB) / 2` conjunction midpoint for a
pair that straddles 0° Aries: 359° and 1° now meet at 0°, not 180°. This
supersedes nothing in DECISIONS.md. It retires an app-side derivation
that the one-definition guard did not enumerate.

**D14. Superseded loop decisions (tier 3, revised here).**
- dw-1's spec stripped "spotlight … CanvasKit" from the adapted wheel
  (`specs/dw-1-birth-chart-web.md:243`, non-goal at :480).
- dw-4's decision to express lit aspects as an SVG drop-shadow glow
  (`wheel.css` `.wheel[data-active] .wheel__chord[data-lit]` filters) now
  applies only as the static/reduced-motion fallback.

The coordinator journals both under **Supersedes**.

## Architecture

This is the delta to `pipeline/epics/divination-web.md` ("Built so far" for
dw-1, dw-4, dw-8 and dw-10; "Dependency rules for this epic"). The epic's
reuse map is not repeated here. What follows was confirmed by targeted reads
on 2026-09-29.

### Reuse (verified file:line)

| Need | Existing | Use |
|---|---|---|
| Shader source + named uniforms | `packages/core/src/chart-view/spotlight.ts:26` `SPOTLIGHT_SKSL`, `:100` `SpotlightLine`, `:119` `SpotlightUniformValues`, `:131` `spotlightUniformValues` | Unchanged. Gains two siblings (below). |
| Chord geometry | `chart-view/frame.ts:69` `wheelPoint`, `:29` `WHEEL_VIEW`; `geometry.ts:80` `BUNDLE_K`, `:88` `quadControl`, `:56` `midLongitude` | Composed once by the new `spotlightChord`. |
| Native line builder | `app-native/src/chart/Spotlight.tsx:108–143` `spotlightLineFor` (conjunction collapse at `:127–132` does `(lonA + lonB) / 2`) | Calls `spotlightChord(aspect, chart, ACTIVE_WHEEL_VIEW.rHub)`, then its own `frame.toPx` and colour. |
| Beam glow scale | `app-native/src/chart/FactorBeams.tsx:50` `FACTOR_BEAM_GLOW = 0.6` | The same number is a web constant (no cross-workspace import, G9). |
| Planet family | `chart-view/aspect-set.ts:26` `planetFamily` | Feeds the focus set and the focus beams. |
| Activation | `web-divination/src/chart/wheel-activation.ts:66` `activationFor`, `:57` `useActivation` | Read-only. |
| Persona → body | `packages/core/src/divination/roster.ts:26` `PERSONA_BODIES` (divination barrel) | Maps the active character to its focus body. |
| CanvasKit bootstrap precedent | `git show d0e36b1:frontend/src/features/chart-display/skia.ts` (host probe, lazy `import('canvaskit-wasm')` + `?url` wasm, own rAF loop that is cancelled before `surface.dispose()`) | Re-authored in the new engine module. Its uniform flattener lacked `u_glow`, and core's `spotlightUniformArray` replaces it. |
| Reduced-motion query precedent | `web-divination/src/chat/DiceCard.tsx:31–35` | Same query string, in a hook. |
| Colours | `web-divination/src/theme/tokens.ts` `webTokens.aspect`, `webTokens.persona` (all `#rrggbb`) | Parsed to 0..1 by a theme helper. |

### Module map (created or changed only)

```
packages/core/src/chart-view/
├── spotlight.ts        CHANGED  + spotlightUniformArray, + spotlightChord, + type SpotlightChord
└── index.ts            CHANGED  barrel exports the three
app-native/src/chart/
└── Spotlight.tsx       CHANGED  spotlightLineFor delegates the wheel-unit chord to core
app-native/src/architecture.test.ts   CHANGED  enumeration + G14 shader text + G15 canvaskit importer (+ self-checks)
web-divination/
├── package.json        CHANGED  + "canvaskit-wasm": "0.41.0"
├── vite.config.ts      CHANGED  only if needed: optimizeDeps.exclude ['canvaskit-wasm'] (see Risks)
└── src/
    ├── theme/rgb.ts            NEW  rgb01(hex) → [r,g,b] in 0..1 (hex only; throws otherwise)
    ├── theme/motion.ts         NEW  useReducedMotion(): boolean (live matchMedia subscription)
    ├── chart/focus.ts          NEW  pure focusFor(chart, body, activation) → FocusView | null
    ├── chart/spotlight/
    │   ├── beams.ts            NEW  pure beamsFor(…) → Beam[]  (+ toBoxPx)
    │   ├── engine.ts           NEW  loadEngine() + startSpotlight(); the ONLY canvaskit-wasm importer
    │   └── SpotlightLayer.tsx  NEW  the canvas: status, reduced motion, lifecycle, data-* hooks
    ├── chart/ChartWheel.tsx    CHANGED  optional `focus` prop → data-focus / data-focus-out
    ├── chart/ChartStage.tsx    CHANGED  prop persona; disc wrapper; focus state; toggle; layer
    ├── chart/wheel.css         CHANGED  focus rules, [data-spotlight='live'] rules, RM block
    ├── app/App.tsx             CHANGED  <ChartStage persona={active} /> at :76 (HEAD 8da99b2; dw-12's AuthGate wraps App elsewhere, dw-14 overlap)
    └── i18n/en.ts, zh.ts       CHANGED  chart.focusShowAll, chart.focusOn ({name})
```

### Contracts

**core `spotlight.ts`** (still platform-free: no DOM, no CanvasKit, rule 1)
- `spotlightUniformArray(u: SpotlightUniformValues): number[]` flattens the
  named record in SkSL declaration order:
  `[u_time, …u_a, …u_b, …u_c, …u_color, u_glow]` (11 floats). CanvasKit binds
  by position, and this is the one place the order is written.
- `type SpotlightChord = { a: {x,y}; b: {x,y}; c: {x,y} }`, in the
  coordinates of `view`.
- `spotlightChord(aspect: Aspect, chart: BirthChart, rHub: number): SpotlightChord | null`
  takes only the hub radius. `wheelPoint` always centres on
  `WHEEL_VIEW.cx/cy`, and every view (`WHEEL_VIEW`, `ONE_CIRCLE_VIEW`,
  `HUB_FORWARD_VIEW`) shares that centre. So the bow's centre is
  `WHEEL_VIEW`'s too, and no caller can pass a centre that disagrees with
  the endpoints.
  - It looks up both longitudes (planets, or `chart.ascendant` for
    `Ascendant`) and returns null on a miss.
  - For a conjunction it collapses to `wheelPoint(rHub, midLongitude(lonA, lonB), asc)`,
    with a = b = c.
  - Otherwise `a`/`b` = `wheelPoint(rHub, lon, asc)` and `c` =
    `{x: qx, y: qy}` of the existing
    `quadControl(a.x, a.y, b.x, b.y, WHEEL_VIEW.cx, WHEEL_VIEW.cy, BUNDLE_K)`,
    whose signature is unchanged.

  It is pure and has no colour. A client maps the three points to its own
  pixels, which is valid because `quadControl` is affine (see the comment
  at `Spotlight.tsx:101–104`).

**web `chart/focus.ts`**
- `type FocusView = { body: Body; out: Tier }` (`Tier` from wheel-activation).
- `focusFor(chart | null, body | null, activation: WheelActivation | null): FocusView | null`
  - It returns null when there is no chart or no body.
  - `out` = every chart planet and aspect key MINUS
    (`planetFamily(chart.aspects, body)` ∪ `activation.lit` ∪ `activation.echo`).
    `Ascendant` is in `out.bodies` unless it is in that union.
  - It is set membership only (G4).

**web `chart/spotlight/beams.ts`**
- `type Beam = { key: string; line: SpotlightLine; glow: number }`. `key` is
  an `aspectKey` or `planet:<Body>`.
- `beamsFor({ chart, focusBody, full, activation, size, ink }): Beam[]`
  implements D3, D4 and D5 over `spotlightChord` (aspects) and
  `wheelPoint(WHEEL_VIEW.rHub, planet.longitude, asc)` (blooms: a lookup,
  no arithmetic).
  - Points go through `toBoxPx(p, size) = ((p.x − WHEEL_VIEW.minX)·s, (p.y − WHEEL_VIEW.minY)·s)`,
    with `s = size / WHEEL_VIEW.size`. This is linear px scaling, like
    native's `frame.ts`, with no longitude term.
  - Colour: `rgb01(webTokens.aspect[type])` for aspects, and `ink` (the
    caller's `rgb01(webTokens.persona[id])`) for blooms.
  - The cap is 12, sorted by orb.
  - Constants: `VOICE_GLOW = 1`, `FOCUS_GLOW = 0.6`.
- It holds no React state and touches no DOM.

**web `chart/spotlight/engine.ts`**
- `interface SpotlightEngine { start(canvas: HTMLCanvasElement, onFrame: (n: number) => void): SpotlightRun | null }`
- `interface SpotlightRun { setBeams(beams: Beam[], cssSize: number, dpr: number): void; dispose(): void }`
- `initCanvasKit(locateFile?: (file: string) => string): Promise<CanvasKit>`
  is the one place the package is imported, as a dynamic `import('canvaskit-wasm')`.
  In the browser it defaults to the Vite `?url` wasm; a node test passes its
  own `locateFile`. `engine.ts` re-exports the `CanvasKit`, `RuntimeEffect`
  and `Surface` types, so tests need nothing else.
- `loadEngine(): Promise<SpotlightEngine | null>` is memoised.
  - The host probe runs first (jsdom has no 2d context, so it resolves null
    before any wasm bootstrap; this is the precedent's fix for floating
    rejections).
  - Then `initCanvasKit()`; any failure →
    null + one `console.warn`.
- `start` does the following:
  - it creates the surface with `MakeWebGLCanvasSurface ?? MakeSWCanvasSurface`
    and runs `RuntimeEffect.Make(SPOTLIGHT_SKSL)` once per engine;
  - it owns the rAF loop. Each frame it clears, applies `scale(dpr)`, and
    for each beam calls
    `makeShader(spotlightUniformArray(spotlightUniformValues(line, t, glow)))`,
    then `drawRect` over the beam's padded bbox (D12), then `shader.delete()`;
  - `dispose` cancels the frame before disposing the surface.
- It is also exported for K2: `drawBeams(ck, canvas, effect, beams, t)`, a
  single frame on a caller's surface. It needs no rAF, so a node test can
  draw on `MakeSurface`.

**web `chart/spotlight/SpotlightLayer.tsx`**
- Props: `{ beams: Beam[]; size: number; onStatus(s: 'static'|'loading'|'live') }`.
- Reduced motion or `beams.length === 0` → it renders nothing (status
  `static` when reduced, and nothing to report when empty) and never calls
  `loadEngine`.
- Otherwise it loads the engine. While it loads the status is `loading`;
  null → `static`. On success it renders
  `<canvas class="chart-stage__beams" aria-hidden="true" data-beam-keys="…" data-frames="n">`
  and the status is `live`.
- `data-frames` is written from `onFrame` about every 250 ms, as a plain
  attribute set on the element ref, so there is no React commit per frame.

**web `ChartStage.tsx`**
- New prop `persona: PersonaId | null`.
- It owns `{persona, full}` state, which resets when `persona` changes (D8).
- It derives `focusBody = PERSONA_BODIES[persona]`,
  `focus = full ? null : focusFor(shown, focusBody, activation)`,
  `beams = beamsFor(…)` and `ink`.
- It wraps the svg in `.chart-stage__disc` (position: relative; a
  ResizeObserver gives `size`) with the layer inside, and renders the toggle
  after the disc.
- `data-spotlight` sits on `.chart-stage`.

**web `ChartWheel.tsx`**
- Optional `focus?: FocusView | null`: `data-focus={focus.body}` on the
  svg, and `data-focus-out` on planet groups, chords, conjunction dots, hub
  nodes and the Ascendant node whose body or key is in `focus.out`.
- Without the prop, the markup is byte-identical to today's.

### Dependency rules and forbidden edges

- New edges: `chart/ChartStage → @astrace/core/divination` (barrel:
  `PERSONA_BODIES`, `PersonaId`), `chart/spotlight/* → theme` (tokens, rgb,
  motion), and `chart/spotlight/engine → canvaskit-wasm`. `app → chart`
  already exists.
- ❌ `chart/` imports neither `chat/` nor `roster/` (unchanged). The
  persona arrives as a prop.
- ❌ Within the three walked source trees (`packages/core/src`,
  `app-native/src`, `web-divination/src`, tests included) no module other
  than `web-divination/src/chart/spotlight/engine.ts` imports
  `canvaskit-wasm` (G15). Outside them, native's jest environment
  (`app-native/jest/skia-env.js:27`, which requires
  `canvaskit-wasm/bin/full/canvaskit` so Skia renders under jest) is the one
  pre-existing test-harness importer; it is out of G15's walk and unchanged.
  Native app code keeps reaching Skia only through `@shopify/react-native-skia`.
- ❌ `packages/core/src` names no CanvasKit, rAF, canvas or DOM (the existing
  Web-global guard). `spotlightChord` and `spotlightUniformArray` are pure
  TS.
- ❌ No web file does longitude arithmetic (G4). Conjunction midpoints come
  from core `midLongitude` inside `spotlightChord`. Web code never names
  `lonA`/`lonB` in an expression.
- ❌ `theme/` keeps G7: `rgb.ts` and `motion.ts` import only `react` and
  their siblings.
- `engine.ts` loads a bundled static asset (the wasm) through the library's
  own loader, not a backend call. G3 (`fetch(`/`XMLHttpRequest` in app
  source) is unaffected, and the file does not move under `platform/`.

### Guard and CLAUDE.md amendments (same commit as the code)

- `app-native/src/architecture.test.ts`:
  - `ONE_DEFINITION_SYMBOLS` gains `SPOTLIGHT_SKSL`,
    `spotlightUniformValues`, `spotlightUniformArray` and `spotlightChord`,
    each expected in `packages/core/src/chart-view/spotlight.ts` (C1).
  - New **G14**, "one shader text" (G11–G13 are taken at HEAD 8da99b2:
    the walked-tree floor and dw-12's Google guards). Over the three trees
    on RAW text, the
    markers `uniform float u_time`, `uniform float2 u_a`, `gl_FragColor` and
    `precision mediump` occur only in core `spotlight.ts` (G1). The guard
    file itself is skipped, as the one-definition walk skips it. `half4 main(`
    is NOT a marker, because `app-native/src/chart/skia-surface.test.tsx:130`
    compiles a deliberately broken one-liner.
  - New **G15**, "one canvaskit importer". On comment-stripped code, so a
    doc comment naming the package is no offence, the `canvaskit-wasm`
    import specifier (static or dynamic, including `canvaskit-wasm/…`
    subpaths such as the `?url` wasm) appears only in
    `web-divination/src/chart/spotlight/engine.ts`. The walk covers all three
    trees, tests included, and has no exemption.
  - Both get synthetic self-checks.
- Core tests run under NO runner (`packages/core/src/**/*.test.ts` is outside
  both jest `roots` and vitest `include`). So C1–C3 and K1 live in
  web-divination, as `src/chart/spotlight/core-spotlight.test.ts` (C1–C3)
  and `src/chart/spotlight/canvaskit.node.test.ts` (K1, K2, node
  environment, importing only `./engine`), following `chart/chart-view-additions.test.ts`.
- CLAUDE.md rule 1, chart-view paragraph: replace "NOTE the weakened claim
  … it still proves one DEFINITION, not identical rendered output" with the
  following. The spotlight SkSL is compiled from the one core string on both
  clients (react-native-skia on native, CanvasKit-WASM in
  `web-divination/src/chart/spotlight/engine.ts`, the sole `canvaskit-wasm`
  importer in the walked source trees — native's jest environment
  `app-native/jest/skia-env.js` loads it for tests only). The enumeration includes `SPOTLIGHT_SKSL`, the uniform
  record/array and `spotlightChord`. G14 forbids a second shader text.
- `docs/ARCHITECTURE.md` and the epic file are updated at docs-sync, not
  here.

### Risks for the implementer (non-obvious only)

- Vite 8 may pre-bundle `canvaskit-wasm` and break its `locateFile`. If the
  dev server 404s the wasm, exclude it from `optimizeDeps`.
- In jsdom, never let emscripten start (the host probe comes first). The
  deleted frontend's suite went red from floating rejections.
- The K1/K2 node test must not need node types (the web tsconfig is DOM):
  - locate the wasm with `new URL('…/node_modules/canvaskit-wasm/bin/', import.meta.url)`
    and pass `locateFile` the URL's `.pathname` + file name, never its `href`
    (node's loader reads it with `fs`, which rejects a `file://` string);
    this path string is not an import specifier, so G15 is unaffected;
  - hash C1 with `crypto.subtle`;
  - sort beams with `(x, y) => x.orb - y.orb`, never an `orb =` assignment
    (G4's COMPUTATION_RE matches `orb\s*=[^=]`).
- A WebGL canvas is not readable after compositing (no
  `preserveDrawingBuffer`). That is why R1 uses `data-frames` and a
  screenshot, not a pixel read.

## Acceptance Criteria

Fixture chart F = `server/tests/fixtures/beijing-1990-known-time.json`
(1990-06-15 08:30 Asia/Shanghai). Its Venus family is
`Moon|sextile|Venus`, `Venus|sextile|Jupiter`, `Venus|trine|Saturn`,
`Venus|trine|Neptune`, `Venus|opposition|Pluto`, with bodies {Venus, Moon,
Jupiter, Saturn, Neptune, Pluto}. Its Saturn family is `Venus|trine|Saturn`,
`Saturn|opposition|Ascendant`. F has 20 aspects, and its one conjunction is
Uranus–Neptune. Client checks run under `npm test` (app-native jest, then
web-divination vitest), plus `npm run typecheck`.

**Core**

- C1. `SPOTLIGHT_SKSL` is byte-identical to its value at the branch point: a
  test pins its sha256. The one-definition guard
  (`app-native/src/architecture.test.ts`) enumerates `SPOTLIGHT_SKSL`,
  `spotlightUniformValues`, `spotlightUniformArray` and `spotlightChord`,
  each defined only in `packages/core/src/chart-view/spotlight.ts`.
- C2. `spotlightUniformArray(spotlightUniformValues(line, t, g))` returns 11
  numbers in SkSL declaration order:
  `[t, ax, ay, bx, by, cx, cy, r, g, b, glow]`.
- C3. `spotlightChord` on F with `WHEEL_VIEW.rHub`:
  - `Venus|trine|Saturn` gives `a = wheelPoint(rHub, Venus.lon, asc)`,
    `b = wheelPoint(rHub, Saturn.lon, asc)`, and `c` equal to
    `quadControl(a.x, a.y, b.x, b.y, WHEEL_VIEW.cx, WHEEL_VIEW.cy, BUNDLE_K)`,
    all to 1e-9;
  - a conjunction gives a = b = c at `wheelPoint(rHub, midLongitude(lonA, lonB), asc)`;
  - a synthetic conjunction at 359° and 1° gives the point at longitude 0,
    not at 180;
  - an aspect naming a body the chart lacks gives `null`.
- C4. Native's existing spotlight suites (`app-native/src/chart/spotlight.test.tsx`,
  `screens/spotlight-polish.test.tsx`, `screens/factor-highlight.test.tsx`)
  pass unchanged. `app-native/src/chart/Spotlight.tsx` contains no
  `lonA + lonB`.

**No second shader**

- G1. A guard walks `packages/core/src`, `app-native/src` and
  `web-divination/src`, comments and strings included, skipping the guard
  file itself. `uniform float u_time`, `uniform float2 u_a`, `gl_FragColor`
  and `precision mediump` each appear only in
  `packages/core/src/chart-view/spotlight.ts`, or nowhere. A synthetic
  self-check shows the guard bites (G14). The `canvaskit-wasm` import
  specifier, static or dynamic, is matched on comment-stripped code and
  appears in only one file across the three trees, tests included:
  `web-divination/src/chart/spotlight/engine.ts` (G15). The K1/K2 test
  obtains CanvasKit only through `engine.ts`'s `initCanvasKit`: it contains
  no `canvaskit-wasm` import specifier (its wasm locate path is a plain
  string, not an import).
- G2. The existing guards pass: one-definition, G3 network (no `fetch(` or
  `XMLHttpRequest` outside `web-divination/src/platform/`), G4 arithmetic (no
  `lonA +`, no `longitude *`, no `% 360` in web code), G5 (`chart/useChart.ts`
  stays the only chart value-importer), and the colour guard (no hex or
  `rgb(` literal outside `web-divination/src/theme/tokens.ts`).

**Compile in the real engine (vitest, node environment)**

- K1. A vitest file with `// @vitest-environment node` gets CanvasKit through
  `engine.ts`'s `initCanvasKit(locateFile)`, with the wasm located in
  `node_modules/canvaskit-wasm/bin/`. It compiles `SPOTLIGHT_SKSL`:
  - `RuntimeEffect.Make` returns non-null with no error callback;
  - `getUniformCount() === 6` and `getUniformFloatCount() === 11`, and the
    latter equals `spotlightUniformArray(...).length`;
  - `getUniformName(i)` for i = 0…5 reads `u_time, u_a, u_b, u_c, u_color, u_glow`.
- K2. The web beam drawer, given a CPU surface of 300×300 and one beam from
  (40,150) to (260,150) with control point (150,200), glow fixed at 1.0 and
  `u_time` fixed at a value the test names (chosen near the breathing peak),
  draws these alphas:
  - > 0.3 at the curve's t = 0.5 point, (150,175);
  - < 0.02 at (150,20).

**Web — beams (pure, jsdom)**

- B1. `beamsFor` on F, with Venus in focus and no activation, gives 5 beams.
  Their keys equal the 5 Venus-family aspect keys, each has glow 0.6, and
  each is coloured with `webTokens.aspect[type]` parsed to 0..1.
- B2. With the activation `[Venus|trine|Saturn]` (a pressed pill), it gives
  exactly 1 beam, key `Venus|trine|Saturn` with glow 1.0. No focus beams.
- B3. With the activation `[planet:Mars]` and Venus in focus, it gives one
  point bloom keyed `planet:Mars`, with a = b = c at Mars's hub node, glow
  1.0 and the Venus ink colour.
- B4. With Saturn in focus it gives 2 beams, `Venus|trine|Saturn` and
  `Saturn|opposition|Ascendant`. With the time-unknown F (no Ascendant) it
  gives 1 beam.
- B5. With full chart chosen and no activation it gives 0 beams.

**Web — focus (jsdom)**

- F1. Mount the app with F ready and Venus active:
  - the svg has `data-focus="Venus"`;
  - within the wheel `svg`, exactly Sun, Mercury, Mars and Uranus carry
    `data-focus-out` among `[data-planet]`;
  - within the wheel `svg`, exactly the 15 non-family aspects carry
    `data-focus-out` among `[data-aspect-key]` (the Uranus–Neptune conjunction dot is one of them);
  - no Venus-family chord carries it.
- F2. `button[data-focus-toggle]` reads "Show full chart" with
  `aria-pressed="false"`. Clicking it removes `data-focus` and every
  `data-focus-out`, and the button then reads "Focus on Venus" with
  `aria-pressed="true"`. Clicking again restores F1. In zh the labels are
  "显示完整星盘" and "聚焦金星".
- F3. With no character active, or the chart not ready, there is no
  `[data-focus-toggle]` and no `data-focus`.
- F4. In focus, `showRefs([aspect Mars|square|Jupiter])` (outside Venus's
  web) removes `data-focus-out` from Mars, Jupiter and that chord. Mars and
  the chord carry `data-lit`. Clearing the activation restores F1 exactly.
- F5. Choose the full chart, pick Saturn: the wheel is back in focus with
  `data-focus="Saturn"`. Re-picking Saturn keeps the current mode.
- F6. `wheel.css` has rules for `.wheel[data-focus] …[data-focus-out]` that
  hide chords and conjunction dots and dim planets and hub nodes. It
  contains `[data-spotlight='live']` rules that remove the lit-chord
  `filter`. Its `prefers-reduced-motion` block removes the focus crossfade.
  All colour is read as `var(--…)`.

**Web — layer lifecycle (jsdom, CanvasKit stubbed or absent)**

- L1. In jsdom (no CanvasKit host), with beams due: the stage carries
  `data-spotlight="static"` after the load settles, no `<canvas>` is in the
  stage, and no unhandled rejection is reported.
- L2. With `matchMedia('(prefers-reduced-motion: reduce)')` matching, the
  loader is never called (spy) and the stage reads `data-spotlight="static"`.
  Flip the stub to not-matching and fire change: with a stubbed loader
  resolving a fake engine, the canvas mounts.
- L3. With a fake engine, the canvas carries `data-beam-keys`, the
  space-separated beam keys matching B1/B2. `pointer-events` is `none` and
  `aria-hidden="true"`. With 0 beams the canvas unmounts and the fake
  engine's dispose is called once.

**Real app (Claude-in-Chrome, `npm run web` + `npm run web:server`, birth
data F entered through the form)**

- R1. Pick Venus. Within 5 s the stage reads `data-spotlight="live"`, one
  `canvas` overlays the wheel (its bounding rect equals the svg's to ±1 px),
  and `data-beam-keys` lists the 5 Venus-family keys. The Claude-in-Chrome tab
  stays in the foreground, because a background tab throttles rAF.
  `data-frames` is a frame counter the layer writes about every 250 ms. Two
  reads taken at least 2.5 s apart show growth of at least 60. A screenshot shows the glow on Venus's 5
  chords and none elsewhere. Only Venus's web and the dimmed planets are
  visible.
- R2. Press "Show full chart": all 20 aspects are visible and no canvas is
  present. Press it again: back to R1's state.
- R3. Send Venus a message whose reply carries an aspect pill. Press that
  pill: `data-beam-keys` equals that aspect's key alone. If the pill's
  aspect is outside Venus's web, its chord and planets are visible. Pressing
  the pill again returns to the 5 focus beams.
- R4. In headless Chrome with CDP
  `Emulation.setEmulatedMedia({features:[{name:'prefers-reduced-motion',value:'reduce'}]})`
  (the dw-4 A5 / dw-5 A8 precedent; Claude-in-Chrome has no media
  emulation), load the app with F and Venus stored:
  no canvas, `data-spotlight="static"`, focus still applied, and a pressed
  pill shows its chord lit statically (dw-4's rendering).
- R5. Loop closed: with a character picked, the wheel shows just that
  planet's web of aspects with the flowing glow. One tap on the control
  shows the whole chart. The browser console has no error during R1–R4.
  Screenshots for R1, R2 and R3 go in the validating log.
