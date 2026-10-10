# dw-15-wheel-spotlight — 01 designing (2026-09-29)

Stage: backlog → (spec written; coordinator sets `spec-review`). Branch:
feature/divination_web, untouched (no code edits, no commits). Output:
`pipeline/specs/dw-15-wheel-spotlight.md`.

## Read

- CLAUDE.md (in full); pipeline/PIPELINE.md (in full); QUEUE.md dw-15 entry and
  neighbours (dw-12, dw-13, dw-14); pipeline/epics/divination-web.md (in full).
- Targeted code reads:
  - core: `chart-view/spotlight.ts`, `aspect-set.ts`, the `index.ts` exports,
    and `geometry.ts`/`frame.ts` symbol lines. `divination/roster.ts`
    `PERSONA_BODIES`.
  - native: `chart/Spotlight.tsx` (whole file), `chart/FactorBeams.tsx`,
    `chart/frame.ts` (head), `chart/wheel-view.ts`, `jest.config.js` (real
    CanvasKit env).
  - web: `chart/ChartWheel.tsx`, `ChartStage.tsx`, `wheel-activation.ts`,
    `wheel-layout.ts`, `wheel.css` (activation + reduced-motion blocks),
    `app/App.tsx`, `theme/tokens.ts`, `roster/roster.css` (`--char` scope),
    `package.json`, `vite.config.ts`, `chart/fixtures.ts`, and the DiceCard
    matchMedia precedent.
  - guards: `app-native/src/architecture.test.ts` (ONE_DEFINITION :245–319,
    web G3–G9 :568–690, COMPUTATION_RE :497) and the colour-guard hex regex.
  - history: `git show d0e36b1:frontend/src/features/chart-display/skia.ts`
    (the deleted web CanvasKit loader and draw loop).
  - pipeline: the dw-10 spec's AC style; the dw-10 validating log (Claude-in-
    Chrome is the real-app driver); DECISIONS grep for canvaskit/spotlight.

## Feasibility probe (scratchpad, not the repo)

`canvaskit-wasm@0.41.0` is present at the root `node_modules`, resolved through
app-native's `@shopify/react-native-skia@2.6.2`. The package is 24 MB on disk,
and `bin/canvaskit.wasm` is 7,155,822 B (2,895,604 B gzip). The `types`
declare `RuntimeEffect.Make`.

A node script loaded `bin/canvaskit.js`, pulled `SPOTLIGHT_SKSL` out of
core's source (sample count 28 interpolated), and compiled it:

```
rt_effect true has RuntimeEffect
compiled true null
lit px 10062 uniforms 6 11
```

So the default build compiles the shader byte-for-byte with no error. It
reports 6 uniforms / 11 floats, which makes the old web flattener (10 floats,
no `u_glow`) stale. It also draws a beam on a CPU surface in node. The
spec's K1/K2 criteria rest on this.

## Key decisions (all in the spec's Decided defaults / Architecture)

1. **The SkSL runs in the browser through CanvasKit-WASM, compiled from the
   one core string** (D1). There is no GLSL twin and no second copy, so no
   DECISIONS entry for a copy is needed. A new guard G11 makes "no second
   shader text" test-enforced, and G11b pins `canvaskit-wasm` to one
   importer, `web-divination/src/chart/spotlight/engine.ts`.
2. **One canvas over the SVG** (D2). The SVG stays the addressable,
   accessible wheel. The canvas is `pointer-events: none` and `aria-hidden`.
3. **Voice beams vs focus beams.**
   - A pill or reply activation lights its aspects at glow 1.0.
   - A lit planet with no lit aspect gets a point bloom in the character's
     ink.
   - Focus lights the character planet's family at glow 0.6 (native's
     `FACTOR_BEAM_GLOW`).
   - One voice at a time, as with native's pin over its tour.
   - At most 12 beams, tightest orb first. The full chart at rest has no
     beams.
4. **Focus** = `planetFamily(chart.aspects, PERSONA_BODIES[active])`.
   Out-of-focus chords are hidden and out-of-focus planets are ghosted
   (0.16). While an activation stands, the visible set is focus ∪ lit ∪ echo.
5. **Control**: one `button[data-focus-toggle]`, "Show full chart" / "Focus on
   {name}" (zh 显示完整星盘 / 聚焦{name}). The state is page-session in
   ChartStage and resets on a character change.
6. **Reduced motion and failure** both fall back to dw-4's static lit
   chords. No canvas is mounted and CanvasKit is never loaded under reduced
   motion. `data-spotlight` = static | loading | live. Live drops the SVG
   drop-shadow on lit chords only.
7. **Pixels**: uniforms are in CSS px, with a dpr ≤ 2 canvas scale, beams
   clipped to bbox + 64 px, a ResizeObserver, and a loop that runs only
   while beams exist.
8. **Core additions**:
   - `spotlightUniformArray`: the positional order, written once.
   - `spotlightChord(aspect, chart, view)`: the wheel-unit chord, using
     `wheelPoint`/`quadControl`/`midLongitude`.

   Native's `spotlightLineFor` delegates to it. This removes native's
   `(lonA + lonB) / 2` conjunction midpoint, which is wrong across 0° Aries.
   The enumeration gains `SPOTLIGHT_SKSL`, `spotlightUniformValues`,
   `spotlightUniformArray` and `spotlightChord`.
9. **Test placement**: core tests run under no runner (jest `roots` = src,
   vitest `include` = src). So core-level checks live in web-divination, in
   a jsdom file and a `@vitest-environment node` file for the real
   CanvasKit compile.
10. **CLAUDE.md rule 1** gets its chart-view "weakened claim" note replaced:
    both clients now compile one shader string.

## Open points decided (no questions asked, pipeline mode)

- **Placement of the CanvasKit loader.** It goes in `chart/spotlight/`, not
  `platform/`. It loads a bundled static asset through the library, not a
  backend call, so G3 is unaffected and no new chart→platform edge is
  needed.
- **Colour.**
  - Aspect beams use `webTokens.aspect[type]`.
  - Blooms use `webTokens.persona[id]` (Venus without a character).
  - These are parsed by a hex-only `theme/rgb.ts`, which is safe under the
    colour guard's `#[0-9a-fA-F]{3,8}\b` regex.
- **Persona reaches the chart** as a `persona` prop from App, so `chart/`
  still never imports `roster/`.
- **The G11 markers** exclude `half4 main(`: `app-native/src/chart/skia-surface.test.tsx:130`
  compiles a deliberately broken `half4 main(…)` one-liner. The markers are
  `uniform float u_time`, `uniform float2 u_a`, `gl_FragColor` and
  `precision mediump`. A repo grep shows they occur today only in core
  `spotlight.ts`.
- **Animation proof in the real app.** A WebGL canvas cannot be read back,
  so the layer writes `data-frames` about once a second, and R1 checks that
  it grows by at least 30 per second, plus a screenshot.
- **dw-12 / dw-14 overlap.** App.tsx gets one prop (`persona={active}` on
  ChartStage). The spec does not design around the conflict; it is resolved
  at landing, as the user instructed.

## Superseded loop decisions (for the coordinator's journal)

- dw-1's spec stripped spotlight/CanvasKit from the adapted wheel
  (`specs/dw-1-birth-chart-web.md:243`, non-goal :480).
- dw-4's SVG drop-shadow glow on lit aspects is now only the static and
  reduced-motion fallback.

Neither is a tier-1 user ruling, so no block.

## Status

The spec is written with Goal, Non-goals, Decided defaults (D1–D14),
Architecture and Acceptance Criteria (C1–C4, G1–G2, K1–K2, B1–B5, F1–F6,
L1–L3, R1–R5). The WHAT sections are about 1,270 words and the Architecture
section about 1,600. Ready for `spec-review`. QUEUE.md and DECISIONS.md
were not edited; the coordinator owns both.
