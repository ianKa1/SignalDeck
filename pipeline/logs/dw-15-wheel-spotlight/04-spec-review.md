# dw-15-wheel-spotlight — auto spec review, round 2 (fresh context, 2026-09-29)

Inputs: QUEUE.md `## dw-15-wheel-spotlight`, specs/dw-15-wheel-spotlight.md,
epics/divination-web.md, CLAUDE.md, PIPELINE.md (Spec requirements,
pipeline-mode overrides, decision precedence), round-1 review
02-spec-review.md, plus targeted code reads.

Claims verified at HEAD 8da99b2:
- `architecture.test.ts` uses G11 (walked-tree floor, :861), G12 (Google
  Identity single module, :1008) and G13 (GOOGLE_CLIENT_ID, :1033). G14 and
  G15 are free.
- The G14 markers: `uniform float u_time` and `uniform float2 u_a` occur only
  in `packages/core/src/chart-view/spotlight.ts:27–28`. `gl_FragColor` and
  `precision mediump` occur nowhere. `skia-surface.test.tsx:130` is the broken
  `half4 main(` one-liner, as the spec says.
- `canvaskit-wasm` in the three walked trees appears only in a doc comment at
  `app-native/src/chart/skia-surface.test.tsx:27`. G15 is comment-stripped, so
  that comment does not trip it.
- Root `node_modules/canvaskit-wasm` is 0.41.0. `web-divination/package.json`
  does not declare it yet.
- `App.tsx:76` is `<ChartStage />`, and `active` comes from `useRoster()` at
  :42. `PERSONA_BODIES` is exported from the divination barrel (index.ts:73).
- `Tier` is exported at `wheel-activation.ts:63`.
- `planetFamily` (aspect-set.ts:26) matches D6 and B1/B4.
- Fixture F has 20 aspects, the 5 Venus-family keys, 4 out planets (Sun,
  Mercury, Mars, Uranus), and one conjunction (Uranus–Neptune).
  `Mars|square|Jupiter` exists (F4). The Ascendant node uses
  `data-aspect-node`, not `data-planet`, so F1's count of 4 among
  `[data-planet]` holds.
- K2 is deterministic. At md = 0 on the t = 0.5 sample, alpha ≥
  1·0.4·0.8 = 0.32 for any `u_time`, which clears 0.3 but with a small margin.
  (150,20) lies outside the padded bbox, so its alpha is 0.
- Round-1 verifications (line refs, compile in node, precedent) are not redone.

Round-1 required changes:
1. G11b vs K1/K2 — RESOLVED by option (b). `engine.ts` exports
   `initCanvasKit(locateFile?)` and re-exports the types. The test imports only
   `./engine`. G15 is on comment-stripped code. See new finding 1 below for a
   wording residue.
2. Guard naming collision — RESOLVED. The new guards are G14/G15, and G11–G13
   are cited as taken.
3. R1 flakiness — RESOLVED. Writes happen about every 250 ms, and R1 needs ≥60
   growth over ≥2.5 s reads, so the window is well above the write period. The
   foreground-tab note was added.
4. Goal length — RESOLVED. The Goal is 3 lines and cites the QUEUE entry.

Round-1 optional notes were also taken up:
- `spotlightChord` now takes `rHub` only.
- The real `quadControl` signature is written out.
- F1 is scoped to the wheel svg.
- R4 uses CDP in headless Chrome.
- The orb sort is written as a comparator.

## 1. Serves the user's notes, right-sized — PASS

Every clause of the notes maps to a decision and a criterion:
- The same SkSL via CanvasKit-WASM with no twin (D1, non-goals, C1, G1, K1).
- It replaces dw-4's glow for pills, chips and focus (D3/D4/D11/D14).
- Reduced motion falls back to the static lit chords (D10, L2, R4).
- Colours come from web tokens (D3, `rgb01`).
- Focus shows the planet, its aspects and their partners, with the rest
  hidden or dimmed (D6, F1).
- A visible full-chart control (D8, F2, R2).
- Pills outside the focus still work (D7, F4, R3).
- The loop is closed (R5).

D13 (the core chord helper and native's 0°-Aries fix) is the only extra. It is
a direct consequence of one-definition, small, and declared. Nothing else is
invented.

## 2. Acceptance criteria concretely checkable — PASS (one wording defect, see §3)

C1–C4, G2, K1–K2, B1–B5, F1–F6, L1–L3 and R1–R5 each name a selector, count,
value or environment, and none depends on timing luck. R1 is now robust. K2's
thresholds hold for every `t`.

G1's last sentence contradicts the spec's own Risks section. Details are under
§3 finding 1.

## 3. Architecture Contract and epic consistency — FAIL (two factual defects in normative text)

These parts are sound:
- Rule 1: the core additions are pure TS, and SkSL stays single-definition.
- Rule 2: barrel-only edges, and `chart/` still imports neither `chat/` nor
  `roster/`. The persona arrives as a prop, theme leaves stay leaves, and
  nothing crosses workspaces.
- Rule 5 / G4: there is no longitude arithmetic on the web. `toBoxPx` is linear
  px scaling, and midpoints come from core `midLongitude`. The wasm goes
  through the library loader, not `fetch`.
- Rule 13: hex values come only from `webTokens`.
- Every guard amendment tightens: four new one-definition symbols, G14 and G15.
- D14 follows decision precedence.
- The epic file has nothing that conflicts.

**Finding 1: the "sole importer" claim is false as written.**
`app-native/jest/skia-env.js:27` does
`require('canvaskit-wasm/bin/full/canvaskit')`. That is native's jest
environment, outside `app-native/src`. G15 walks only the three `src` trees,
so it will pass. But two sentences overstate what G15 proves:
- The Dependency-rules line "No module other than `…/engine.ts` imports
  `canvaskit-wasm`, **in either client** (G15)".
- The CLAUDE.md rule-1 amendment "`…/engine.ts`, **the sole `canvaskit-wasm`
  importer**".

The second one would write a false normative sentence into CLAUDE.md.

**Finding 2: G1 contradicts the Risks section.** The G1 criterion says the
K1/K2 test "imports `engine.ts` and **never names the package**". The Risks
section tells the same test to locate the wasm with
`new URL('…/node_modules/canvaskit-wasm/bin/', import.meta.url)`, which names
it. G15 matches only import specifiers, so the guard is fine. The acceptance
sentence, though, is literally unsatisfiable alongside the prescribed code,
and the acceptance stage checks the criteria verbatim.

## 4. Non-goals stated; every open point decided; shape — PASS

- There are 8 explicit non-goals.
- D1–D14 settle every open point:
  - reset on a different character, and reload into focus;
  - WebGL then SW;
  - the dpr clamp;
  - the beam cap and order;
  - the Vite contingency;
  - the status attribute states.
- There is no open-questions section.
- The sections are in the required order, and the Goal is ≤3 lines citing the
  queue entry.
- Pre-Architecture prose is about 1,300 words and Architecture about 1,600,
  roughly within budget.

## Required changes

1. **Scope the canvaskit single-importer claim to what G15 walks.** In the
   Dependency-rules bullet and the CLAUDE.md rule-1 amendment text, say
   "`web-divination/src/chart/spotlight/engine.ts` is the only
   `canvaskit-wasm` importer in the three walked source trees". Also
   acknowledge that native's jest environment
   (`app-native/jest/skia-env.js`, outside `app-native/src`) loads
   `canvaskit-wasm/bin/full` as a test harness. Alternatively, widen G15 to
   also walk `app-native/jest/` with that one file named as the only other
   importer. Either choice is fine; the normative sentence just has to be
   true.
2. **Fix G1's last sentence** to "The K1/K2 test imports CanvasKit only
   through `engine.ts` (no `canvaskit-wasm` import specifier); its
   `locateFile` path string is not an import". Or equivalent wording that
   agrees with the Risks bullet.

## Optional notes

- K1 `locateFile`: in node, emscripten reads the wasm with `fs`, which does not
  accept a `file://` URL string. Return `new URL(…).pathname + file` (still no
  node types needed), not the URL's `href`.
- K2 should pin the beam's `glow` (1.0) and a `t`. The midpoint alpha floor is
  0.32 at breathe's minimum, only 0.02 above the 0.3 threshold. That is fine
  because it is deterministic, but a fixed `t` (e.g. `t = 0.65`, near the
  breathe peak) removes any doubt.
- F4: Jupiter is already in Venus's family, so it never carried
  `data-focus-out`. The assertion "Mars, Jupiter and that chord lack
  `data-focus-out`" is still correct. Only the phrase "removes … from
  Jupiter" is loose.

VERDICT: FAIL
