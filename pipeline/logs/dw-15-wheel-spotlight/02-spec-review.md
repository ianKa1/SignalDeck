# dw-15-wheel-spotlight — auto spec review (fresh context, 2026-09-29)

Inputs: QUEUE.md `## dw-15-wheel-spotlight`, specs/dw-15-wheel-spotlight.md,
epics/divination-web.md, CLAUDE.md, PIPELINE.md (Spec requirements,
pipeline-mode overrides, decision precedence), plus targeted code reads.

Claims verified directly:
- `node_modules/canvaskit-wasm` is 0.41.0 and has `bin/canvaskit.wasm` (7.16 MB).
- Reviewer re-ran the compile in node: `RuntimeEffect.Make(SPOTLIGHT_SKSL)` with
  the `${SPOTLIGHT_BEZIER_SAMPLES}` interpolation resolved. It returned non-null,
  with 6 uniforms and 11 floats, named `u_time,u_a,u_b,u_c,u_color,u_glow`.
  This confirms D1 and K1.
- `spotlight.ts` line numbers :26, :100, :119 and :131 are correct.
- `frame.ts` line numbers :29 and :69 are correct.
- `geometry.ts` line numbers :56, :80 and :88 are correct.
- `aspect-set.ts:26`, `roster.ts:26` and `FactorBeams.tsx:50` are correct.
- `Spotlight.tsx:108–143` is correct, and the `(lonA + lonB) / 2` is at :127–132.
- `DiceCard.tsx:31–35` is correct.
- The precedent `d0e36b1:.../skia.ts` does the host probe, lazy
  `import('canvaskit-wasm')` + `?url`, and `WebGL ?? SW`. Its flattener lacks
  `u_glow`, as the spec says.
- Fixture F has 20 aspects. The Venus family has 5 aspects over {Venus, Moon,
  Jupiter, Saturn, Neptune, Pluto}. The out planets are Sun, Mercury, Mars and
  Uranus, and the only conjunction is Uranus–Neptune.
- The Saturn family is {Venus|trine|Saturn, Saturn|opposition|Ascendant}. The
  time-unknown fixture has no Ascendant and only the Venus–Saturn trine for
  Saturn. So B1, B4 and F1 hold.
- The K2 curve midpoint (150,175) is the correct t=0.5 point.
- `button button--quiet` exists (birth-input.css:279).
- Pills and chips toggle through `pressed ? clearActivation() : showRefs(...)`,
  so R3's "press again" works.
- Core tests run under no runner (jest `roots: src`, and vitest includes
  `src/**` of web only), so hosting C1–K2 in web-divination is correct.
- Native's conjunction test at spotlight.test.tsx:285–300 uses a non-wrapping
  pair with `toBeCloseTo(…, 6)`, so C4 "unchanged" is plausible under the
  core helper.
- The reduced-motion real-app check has precedent: dw-4 A5 and dw-5 A8 used
  CDP emulation in headless Chrome.

## 1. Serves the user's notes, right-sized — PASS

The spec covers every clause of the notes:
- Same `SPOTLIGHT_SKSL` via CanvasKit-WASM, with no GLSL twin (D1, non-goals).
- The glow replaces dw-4's SVG glow for pills, chips and focus (D3/D4/D11).
- The shader stays single-definition (C1, G1).
- `prefers-reduced-motion` gets a static fallback (D10).
- Colours come from web tokens (D3, `rgb01`).
- Focus shows only the character's web, dimming or hiding the rest (D6).
- A visible full-chart control (D8).
- Pills outside the focus still work (D7/F4).
- The loop-closed check (R5).

The one scope item beyond the notes is D13: moving the chord helper to core,
which also fixes native's 0°-Aries conjunction midpoint. It follows directly
from "one definition" and is small. It is stated in the non-goals with a
reason, so it is not invented scope.

## 2. Acceptance criteria concretely checkable — FAIL (one flaky criterion)

C1–C4, G1–G2, K1–K2, B1–B5, F1–F6, L1–L3 and R2–R5 are concrete and checkable.
Each names a selector, a count, a value or a test environment.

R1 is not reliably checkable. It says `data-frames` is "written … at most once
per second" (Contracts, SpotlightLayer), and it requires growth of at least 30
"between two reads 1 s apart". Suppose the writes land every ≥1 s (for example
every 1.02 s). Then two reads 1.0 s apart can both fall inside one write
interval and show 0 growth on a healthy loop. The sampling window has to be
longer than the write period.

## 3. Architecture Contract and epic consistency — FAIL (one internal contradiction, one naming collision)

These parts are sound:
- Rule 1: `spotlightChord`/`spotlightUniformArray` are pure. There is no
  CanvasKit, DOM or rAF in core. SkSL stays single-definition, and colour
  values stay app-side.
- Rule 2: barrels only. The `chart → @astrace/core/divination` value edge
  (`PERSONA_BODIES`) goes through the barrel. `chart/` still imports neither
  `chat/` nor `roster/`, because the persona arrives as a prop. `theme/rgb.ts`
  and `theme/motion.ts` import only `react` and siblings (G7). No
  cross-workspace import, since `FACTOR_BEAM_GLOW` becomes a web constant (G9).
- Rule 5: no fetch or XHR is added. The wasm is loaded by the library's own
  loader. `toBoxPx` is linear px scaling. The only longitude operand is
  passed straight into `wheelPoint`, which the G4 self-check at
  architecture.test.ts:692 already allows. Conjunction midpoints come from
  core `midLongitude`. `useChart.ts` stays the only chart value-importer.
- Rule 13: only `webTokens.aspect`/`persona` hex values, parsed by
  `rgb01(…)`. That name does not match the colour guard's `rgba?\(`.
- Guard amendments strengthen rather than weaken:
  - four new ONE_DEFINITION symbols;
  - a new shader-text guard;
  - a new single-importer guard;
  - the CLAUDE.md rule-1 wording restores a real two-client claim.
- The D14 supersedes list follows decision precedence (tier 3 revised, with
  file:line citations).

**Contradiction: G11b vs K1/K2.** G11b says the `canvaskit-wasm` import
specifier (static or dynamic) appears ONLY in
`web-divination/src/chart/spotlight/engine.ts`. It is stated for the three
trees with no test-file exemption, and G1 says it walks "comments and strings
included". But K1 is `src/chart/spotlight/canvaskit.node.test.ts`, and it
"loads `canvaskit-wasm` from `node_modules`". K2 calls
`drawBeams(ck, canvas, effect, …)` with a `ck` the test must obtain and type.
As written, either the guard fails on the test file, or the implementer has to
invent an exemption at build time. That is exactly the "weaken a rule to make
code compile" move the contract forbids. The spec must choose one of these:
- the guard exempts test files, or this one named file;
- engine.ts exports a node-usable initialiser (e.g.
  `initCanvasKit(locateFile)`) and a type re-export, so the test never names
  the specifier.

**Naming collision.** `architecture.test.ts` already has a **G11**, "the web
tree was really walked" (lines 27 and 861). The spec's "New G11, one shader
text" and "G11b" would give two different guards the same label in one file.

Epic consistency: the spec cites the epic's "Built so far" (dw-1/4/8/10) and
its dependency rules, and adds only this feature's delta. It is consistent
with "the web tree keeps dw-1's guards". Deferring the epic and ARCHITECTURE.md
updates to docs-sync matches PIPELINE.md.

## 4. Non-goals stated; every open point decided — PASS (shape nit below)

The non-goals are explicit (8 bullets). D1–D14 settle everything, including:
- the reset-on-different-character behaviour and the reload default;
- WebGL-then-SW fallback;
- the Vite `optimizeDeps` contingency;
- the beam cap and ordering;
- the dpr clamp.

There is no "open questions" section.

Shape:
- Sections are Goal / Non-goals / Decided defaults / Architecture / Acceptance
  Criteria, in the required order.
- Word budgets are about 1,270 before Architecture and about 1,625 for
  Architecture (≈1,500 target; acceptable).
- The **Goal is 7 lines**, but the override caps it at three lines, and it
  does not cite the QUEUE entry inside the Goal itself (the citation sits
  above it).

## Required changes

1. **Resolve G11b vs K1/K2.** State how the node test gets CanvasKit without
   breaking the single-importer guard. Pick one:
   - (a) G11b skips `*.test.ts(x)`, or exactly
     `web-divination/src/chart/spotlight/canvaskit.node.test.ts`, with that
     exemption written into the guard and its self-check;
   - (b) `engine.ts` exports a node-capable initialiser
     (`initCanvasKit(locateFile?)`) plus the CanvasKit types K2 needs, and
     the test imports only `engine.ts`.

   Update the G1 criterion text to match. Also say whether G11b walks raw
   text, as G11 does, or comment-stripped code, so a doc comment naming the
   package is not an offence.
2. **Rename the new guards** so they do not collide with the existing G11
   (walked-the-tree floor) in `app-native/src/architecture.test.ts`. For
   example, use G12 "one shader text" and G13 "one canvaskit importer", and
   update every reference in the Architecture section and the acceptance
   criteria (G1).
3. **Make R1's frame check non-flaky.** Take the two `data-frames` reads at
   least 2.5 s apart and require growth of at least 60, or else make the
   layer write `data-frames` about every 250 ms and keep "≥30 over 1 s".
   Either way the sampling window must exceed the write period.
4. **Trim the Goal to at most three lines** that cite the QUEUE entry, per the
   pipeline-mode override. The detail already lives in D1/D3/D6/D8.

## Optional notes

- `spotlightChord(aspect, chart, view: {cx, cy, rHub})`: core `wheelPoint`
  always uses `WHEEL_VIEW.cx/cy`, so `view.cx/cy` only matter to
  `quadControl`. Say that `view` must share WHEEL_VIEW's centre (all three
  views do), or narrow the parameter so a caller cannot pass a centre that
  disagrees with the endpoints.
- The contract writes `quadControl(a, b, centre, BUNDLE_K)` in point
  notation, but the real signature is `(ax, ay, bx, by, cx, cy, k) → {qx, qy}`.
  This is harmless, but the plan should not read it as an API change.
- F1 counts "among `[data-aspect-key]`". Scope it to the wheel svg, so a
  future list surface carrying the same hook cannot change the count.
- R1 relies on rAF running. Keep the Claude-in-Chrome tab foregrounded, since
  a background tab throttles rAF to 0–1 fps. Run R4 through CDP emulation in
  headless Chrome, as in dw-4 A5 and dw-5 A8, because claude-in-chrome has no
  media emulation.
- Sorting beams "tightest orb first" is a comparison of server values, and
  `a.orb - b.orb` does not match COMPUTATION_RE (`orb\s*=[^=]`). That is fine
  under G4, but avoid writing it as `orb =` assignments.

VERDICT: FAIL
